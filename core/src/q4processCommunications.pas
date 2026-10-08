Unit q4processCommunications;

{$mode objfpc}{$H+}

{
q4processCommunications
version du 2026/05/15-01

Mapping 4D → q4processCommunications -> statut
Command Number 4D,    4D Command,              q4 API,                Statut
-----------------------------------------------------------------------------------------
1389,                 CALL WORKER,             callWorker,            TODO explicite
144,                  CLEAR SEMAPHORE,         clearSemaphore,        OK partiel q4
371,                  GET PROCESS VARIABLE,    getProcessVariable,    Non supporté q4
1390,                 KILL WORKER,             killWorker,            TODO explicite
1641,                 New signal,              newSignal,             OK q4
143,                  Semaphore,               semaphore,             OK partiel q4
370,                  SET PROCESS VARIABLE,    setProcessVariable,    Non supporté q4
652,                  Test semaphore,          testSemaphore,         OK partiel q4
635,                  VARIABLE TO VARIABLE,    variableToVariable,    Non supporté q4

Doc 4D:
https://developer.4d.com/docs/21/commands/theme/Process-Communications

Responsabilités :
- fournir les primitives q4 de communication et synchronisation entre process q4 ;
- s'appuyer sur q4process pour l'identité du process courant ;
- s'appuyer sur q4interruptions pour les erreurs runtime q4 ;
- rester compatible avec le modèle multithread q4 ;
- orienter les anciens échanges inter-processus 4D vers Storage lorsque le portage est possible.

Choix de portage importants :

1. Sémaphores
---------------
Les sémaphores q4 sont des verrous nommés runtime, protégés par une critical section,
sur le même modèle général que q4recordLocking :
- ressource nommée ;
- process propriétaire ;
- liste protégée par mutex.

Le résultat respecte la sémantique 4D :
- semaphore(...) retourne False si le sémaphore a pu être posé ;
- semaphore(...) retourne True s'il est déjà pris par un autre process ;
- si le même process possède déjà le sémaphore, semaphore(...) retourne False ;
- clearSemaphore(...) ne libère le sémaphore que si le process courant en est propriétaire ;
- testSemaphore(...) indique seulement si le sémaphore existe.

Le préfixe 4D "$" n'est pas portable automatiquement en q4.
Dans 4D, il limite le sémaphore au poste client.
Dans q4, cette notion dépend de l'architecture applicative et doit être traitée
au moment du portage.
Donc tout nom de sémaphore commençant par "$" déclenche assertRaise.

2. New signal
--------------
newSignal retourne un objet de synchronisation q4.
Le signal n'est pas stocké dans Storage : son rôle principal est de réveiller
efficacement un ou plusieurs threads en attente, ce que Storage ne fournit pas seul.

3. Storage
-----------
Storage est le mécanisme q4 recommandé pour remplacer les anciens échanges de données
entre process coopératifs 4D.

Cette unité ne doit pas réintroduire les anciennes variables process 4D comme moyen
de communication inter-thread.
Les échanges de données doivent passer par :
- Storage ;
- objets/collections partagés ;
- workers q4 ;
- signaux ;
- verrous explicites si nécessaire.

4. Commandes non portées
-------------------------
GET PROCESS VARIABLE, SET PROCESS VARIABLE et VARIABLE TO VARIABLE ne sont pas
portées en q4 multithread.

Ces commandes appartiennent au modèle historique des process coopératifs 4D et sont
marquées non thread-safe côté 4D.
Elles échouent explicitement avec q4interruptions.assertRaise.

5. Workers
-----------
CALL WORKER et KILL WORKER sont prévus, mais nécessitent une file de messages worker
et un registre de méthodes/formules appelables.

Première version :
- déclaration minimale ;
- comportement non implémenté ;
- échec explicite via assertRaise.

Version future :
- file de messages dans Storage ;
- worker identifié par q4process ;
- arrêt demandé par flag, pas interruption brutale du thread.
}

Interface

Uses
  Classes,
  SysUtils,
  SyncObjs;

Type

  { Signal q4 de synchronisation entre threads.
    Ne passe pas par Storage, car wait/trigger doivent réveiller efficacement
    les threads en attente. }
  TQ4Signal = Class
  private
    f_event: TEvent;
    f_lock: TRTLCriticalSection;
    f_signaled: boolean;
    f_description: string;

    Function getSignaled: boolean;
    Function getDescription: string;
    Procedure setDescription( Const _1_t_description: string);
  public
    Constructor Create( Const _1_t_description: string = '');
    Destructor Destroy; override;

    { Attend le déclenchement du signal.
      _1_r_timeout est exprimé en secondes, comme 4D Signal.wait().
      Une valeur négative signifie une attente sans limite. }
    Function wait( Const _1_r_timeout: double = -1): boolean;

    { Déclenche définitivement le signal et réveille les threads en attente. }
    Procedure trigger;

    Property signaled: boolean read getSignaled;
    Property description: string read getDescription write setDescription;
  End;

{ Pose un sémaphore nommé.
  Retour 4D :
  - False : sémaphore acquis ou déjà possédé par le process courant.
  - True  : sémaphore déjà possédé par un autre process.

  q4 ne supporte pas le préfixe "$" des sémaphores locaux 4D.
  Un nom commençant par "$" déclenche assertRaise. }
Function semaphore( Const _1_t_semaphore: string; Const _2_e_tickCount: integer = 0): boolean;

{ Libère un sémaphore uniquement si le process courant en est propriétaire.
  Comme en 4D, l'appel depuis un autre process ne libère pas le sémaphore. }
Procedure clearSemaphore( Const _1_t_semaphore: string);

{ Retourne True si le sémaphore existe déjà, False sinon.
  Ne modifie pas l'état du sémaphore. }
Function testSemaphore( Const _1_t_semaphore: string): boolean;

Function newSignal( Const _1_t_description: string = ''): TQ4Signal;

{ TODO explicite : nécessite une file de messages worker et un registre
  de méthodes/formules appelables. }
Procedure callWorker;

{ TODO explicite : dépend du modèle worker q4 futur. }
Procedure killWorker;

{ Non porté : ancienne communication par variables de process coopératifs 4D.
  En q4, utiliser Storage ou une file de messages worker. }
Procedure getProcessVariable;

{ Non porté : ancienne écriture directe dans les variables d'un autre process 4D.
  Non compatible avec le modèle multithread q4. }
Procedure setProcessVariable;

{ Non porté : ancien transfert direct de variable à variable entre process 4D.
  Non compatible avec le modèle multithread q4. }
Procedure variableToVariable;

Implementation

Uses
  q4process,
  q4objectsLanguage,
  q4interruptions;

Const
  q4MillisecondsPerTick = 1000.0 / 60.0;
  q4InfiniteWait = High( cardinal);

Type
  Tq4SemaphoreLock = Record
    t_name: string;
    e_processID: int64;
  End;

  Tq4SemaphoreLockArray = Array Of Tq4SemaphoreLock;

Var
  q4SemaphoreLocks: Tq4SemaphoreLockArray;
  q4SemaphoreMutex: TRTLCriticalSection;

{ Vérifie les restrictions q4 sur les noms de sémaphores.

  Le préfixe "$" 4D signifie "local au poste client".
  q4 ne peut pas deviner automatiquement la notion de poste/client.
  Le renommage doit donc être fait explicitement au portage. }
Procedure assertSupportedSemaphoreName( Const _1_t_semaphore: string);
  Begin
    If ( _1_t_semaphore <> '') Then If ( _1_t_semaphore[1] = '$') Then q4interruptions.assertRaise(
          '4D local semaphore prefix "$" is not portable to q4. Rename the semaphore explicitly during porting.',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );

    If ( Length( _1_t_semaphore) > 255) Then q4interruptions.assertRaise(
        '4D semaphore names are limited to 255 characters.',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
  End;

Procedure raiseUnsupportedProcessCommunication( Const _1_t_command: string; Const _2_t_reason: string);
  Begin
    q4interruptions.assertRaise(
      _1_t_command + ' is not supported in q4processCommunications: ' + _2_t_reason,
      {$I %CURRENTROUTINE%},
      {$I %LINENUM%}
      );
  End;

Function internalFindSemaphoreIndex( Const _1_t_semaphore: string): int64;
  Var
    _e_index: int64;
  Begin
    Result := -1;

    For _e_index := 0 To High( q4SemaphoreLocks) Do If ( q4SemaphoreLocks[_e_index].t_name = _1_t_semaphore) Then Exit( _e_index);
  End;

Function internalTryAcquireSemaphore( Const _1_t_semaphore: string; Const _2_e_processID: int64): boolean;
  Var
    _e_foundIndex: int64;
    _e_newIndex:   int64;
  Begin
    Result := False;

    EnterCriticalSection( q4SemaphoreMutex);
    Try
      _e_foundIndex := internalFindSemaphoreIndex( _1_t_semaphore);

      If ( _e_foundIndex = -1) Then Begin
        _e_newIndex := Length( q4SemaphoreLocks);
        SetLength( q4SemaphoreLocks, _e_newIndex + 1);
        q4SemaphoreLocks[_e_newIndex].t_name := _1_t_semaphore;
        q4SemaphoreLocks[_e_newIndex].e_processID := _2_e_processID;
        Exit( True);
      End;

      If ( q4SemaphoreLocks[_e_foundIndex].e_processID = _2_e_processID) Then Exit( True);

      Result := False;
    Finally
      LeaveCriticalSection( q4SemaphoreMutex);
    End;
  End;

Function internalSemaphoreExists( Const _1_t_semaphore: string): boolean;
  Begin
    EnterCriticalSection( q4SemaphoreMutex);
    Try
      Result := internalFindSemaphoreIndex( _1_t_semaphore) <> -1;
    Finally
      LeaveCriticalSection( q4SemaphoreMutex);
    End;
  End;

Function internalMillisecondsFromTicks( Const _1_e_tickCount: integer): uint64;
  Begin
    If ( _1_e_tickCount <= 0) Then Exit( 0);

    Result := Round( _1_e_tickCount * q4MillisecondsPerTick);
  End;

Function TQ4Signal.getSignaled: boolean;
  Begin
    EnterCriticalSection( f_lock);
    Try
      Result := f_signaled;
    Finally
      LeaveCriticalSection( f_lock);
    End;
  End;

Function TQ4Signal.getDescription: string;
  Begin
    EnterCriticalSection( f_lock);
    Try
      Result := f_description;
    Finally
      LeaveCriticalSection( f_lock);
    End;
  End;

Procedure TQ4Signal.setDescription( Const _1_t_description: string);
  Begin
    EnterCriticalSection( f_lock);
    Try
      f_description := _1_t_description;
    Finally
      LeaveCriticalSection( f_lock);
    End;
  End;

Constructor TQ4Signal.Create( Const _1_t_description: string);
  Begin
    Inherited Create;

    InitCriticalSection( f_lock);
    f_event := TEvent.Create( nil, True, False, '');
    f_signaled := False;
    f_description := _1_t_description;
  End;

Destructor TQ4Signal.Destroy;
  Begin
    FreeAndNil( f_event);
    DoneCriticalSection( f_lock);

    Inherited Destroy;
  End;

Function TQ4Signal.wait( Const _1_r_timeout: double): boolean;
  Var
    _e_timeout:    cardinal;
    _y_waitResult: TWaitResult;
  Begin
    If ( _1_r_timeout < 0) Then _e_timeout := q4InfiniteWait
    Else
      _e_timeout := Round( _1_r_timeout * 1000);

    _y_waitResult := f_event.WaitFor( _e_timeout);
    Result := _y_waitResult = wrSignaled;
  End;

Procedure TQ4Signal.trigger;
  Begin
    EnterCriticalSection( f_lock);
    Try
      If ( f_signaled) Then Exit;

      f_signaled := True;
      f_event.SetEvent;
    Finally
      LeaveCriticalSection( f_lock);
    End;
  End;

Function semaphore( Const _1_t_semaphore: string; Const _2_e_tickCount: integer): boolean;
  Var
    _e_processID: int64;
    _e_timeoutMs: uint64;
    _e_startMs:   QWord;
    _b_acquired:  boolean;
  Begin
    assertSupportedSemaphoreName( _1_t_semaphore);

    _e_processID := q4process.ProcessState.processID;
    _e_timeoutMs := internalMillisecondsFromTicks( _2_e_tickCount);
    _e_startMs := GetTickCount64;

    Repeat
      _b_acquired := internalTryAcquireSemaphore( _1_t_semaphore, _e_processID);

      If ( _b_acquired) Then Exit( False);

      If ( _2_e_tickCount <= 0) Then Exit( True);

      If ( ( GetTickCount64 - _e_startMs) >= _e_timeoutMs) Then Exit( True);

      Sleep( 1);
    Until ( False);
  End;

Procedure clearSemaphore( Const _1_t_semaphore: string);
  Var
    _e_foundIndex: int64;
    _e_index:      int64;
    _e_processID:  int64;
  Begin
    assertSupportedSemaphoreName( _1_t_semaphore);

    _e_processID := q4process.ProcessState.processID;

    EnterCriticalSection( q4SemaphoreMutex);
    Try
      _e_foundIndex := internalFindSemaphoreIndex( _1_t_semaphore);

      If ( _e_foundIndex = -1) Then Exit;

      If ( q4SemaphoreLocks[_e_foundIndex].e_processID <> _e_processID) Then Exit;

      For _e_index := _e_foundIndex To High( q4SemaphoreLocks) - 1 Do q4SemaphoreLocks[_e_index] := q4SemaphoreLocks[_e_index + 1];

      SetLength( q4SemaphoreLocks, Length( q4SemaphoreLocks) - 1);
    Finally
      LeaveCriticalSection( q4SemaphoreMutex);
    End;
  End;

Function testSemaphore( Const _1_t_semaphore: string): boolean;
  Begin
    assertSupportedSemaphoreName( _1_t_semaphore);

    Result := internalSemaphoreExists( _1_t_semaphore);
  End;

Function newSignal( Const _1_t_description: string): TQ4Signal;
  Begin
    Result := TQ4Signal.Create( _1_t_description);
  End;

Procedure callWorker;
  Begin
    raiseUnsupportedProcessCommunication(
      'CALL WORKER',
      'worker message queues over Storage are not implemented yet'
      );
  End;

Procedure killWorker;
  Begin
    raiseUnsupportedProcessCommunication(
      'KILL WORKER',
      'q4 worker lifecycle management is not implemented yet'
      );
  End;

Procedure getProcessVariable;
  Begin
    raiseUnsupportedProcessCommunication(
      'GET PROCESS VARIABLE',
      '4D cooperative process variables are not portable to the q4 multithread model; use Storage or a worker message queue'
      );
  End;

Procedure setProcessVariable;
  Begin
    raiseUnsupportedProcessCommunication(
      'SET PROCESS VARIABLE',
      '4D cooperative process variables are not portable to the q4 multithread model; use Storage or a worker message queue'
      );
  End;

Procedure variableToVariable;
  Begin
    raiseUnsupportedProcessCommunication(
      'VARIABLE TO VARIABLE',
      '4D cooperative process variables are not portable to the q4 multithread model; use Storage or a worker message queue'
      );
  End;

Initialization
  InitCriticalSection( q4SemaphoreMutex);

Finalization
  DoneCriticalSection( q4SemaphoreMutex);
  SetLength( q4SemaphoreLocks, 0);

End.
