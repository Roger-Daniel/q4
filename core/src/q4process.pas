Unit q4process;

{$mode objfpc}{$H+}

{
q4process
version du 2026/05/14-01

Mapping 4D → q4process -> statut
Command Number 4D,   4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
1634,                ABORT PROCESS BY ID,              abortProcessByID,                 Partial,
335,                 Count tasks,                      countTasks,                       OK,
343,                 Count user processes,             countUserProcesses,               OK,
342,                 Count users,                      countUsers,                       OK,
322,                 Current process,                  currentProcess,                   OK,
1392,                Current process name,             currentProcessName,               OK,
323,                 DELAY PROCESS,                    delayProcess,                     Partial,
651,                 EXECUTE ON CLIENT,                executeOnClient,                  Not supported,
373,                 Execute on server,                executeOnServer,                  Not supported,
650,                 GET REGISTERED CLIENTS,           getRegisteredClients,             Partial,
317,                 New process,                      newProcess,                       Partial,
319,                 PAUSE PROCESS,                    pauseProcess,                     Not supported,
672,                 Process aborted,                  processAborted,                   Partial,
1495,                Process activity,                 processActivity,                  Partial,
?,                   Process info,                     processInfo,                      Partial,
372,                 Process number,                   processNumber,                    Partial,
330,                 Process state,                    processState,                     Partial,
648,                 REGISTER CLIENT,                  registerClient,                   Not supported,
320,                 RESUME PROCESS,                   resumeProcess,                    Not supported,
1714,                Session,                          session,                          Partial,
1844,                Session info,                     sessionInfo,                      Partial,
1839,                Session storage,                  sessionStorage,                   Partial,
649,                 UNREGISTER CLIENT,                unregisterClient,                 Not supported,

Doc: https://developer.4d.com/docs/21/commands/theme/Processes


Responsabilités :
- gérer le ProcessState par thread
- exposer les variables process q4 (OK, Error, etc.)
- gérer le cycle initProcess/doneProcess
- fournir un premier socle pour les commandes 4D du thème Processes

Notes de portage :
- StartQ4 exécute une procédure sur le thread courant avec ouverture/fermeture q4.
- NewProcess crée un thread secondaire, initialise q4, exécute la procédure, puis ferme q4.
- poNoDatabaseConnection permet de ne pas ouvrir SQLite pour un process.
- Les commandes dangereuses ou non fidèles au modèle Lazarus/FPC (PAUSE/RESUME/ABORT)
  doivent échouer explicitement tant qu'elles ne sont pas vraiment supportées.
}

Interface

Uses
  Classes,
  SysUtils,
  fpjson,
  q4coreLanguage,
  q4arrays;

Type

  Tq4ProcessOption = (
    poNoDatabaseConnection
    );

  Tq4ProcessOptions = Set Of Tq4ProcessOption;

  TProcessState = Record
    processID: int64;
    processName: string;
    sessionUser: string;
    userName4D: string;
    options: Tq4ProcessOptions;
    lastError: int64;
    lastErrorMessage: string;
    currentTableNumber: int64;
    formTableNumber: int64;
    databaseConnected: boolean;
    abortedRequested: boolean;
  End;

  Tq4ProcessProc = Procedure;

Const
  // 4D Process state constants
  psDoesNotExist = -100;
  psAborted = -1;
  psExecuting = 0;
  psDelayed = 1;
  psWaitUserEvent = 2;
  psWaitIO = 3;
  psWaitInternal = 4;
  psPaused = 5;

Threadvar
  ProcessState: TProcessState;

Procedure initProcess( _1_e_ordreProcess: int64; Const _2_t_processName: string; Const _3_t_sessionUser: string; Const _4_t_userName4D: string); overload;
Procedure initProcess( _1_e_ordreProcess: int64; Const _2_t_processName: string; Const _3_t_sessionUser: string; Const _4_t_userName4D: string; Const _5_y_options: Tq4ProcessOptions); overload;
Procedure doneProcess( _1_e_ordreProcess: int64);

Procedure StartQ4( _1_y_proc: Tq4ProcessProc);

Function NewProcess( _1_y_proc: Tq4ProcessProc; _2_y_stackSize: SizeUInt = 0; Const _3_y_options: Tq4ProcessOptions = []; Const _4_t_processName: string = '';
  Const _5_t_sessionUser: string = ''; Const _6_t_userName4D: string = ''): int64;

Function CountTasks: int64;
Function CountUserProcesses: int64;
Function CountUsers: int64;
Function CurrentProcess: int64;
Function CurrentProcessName: string;
Procedure DelayProcess( _1_e_process: int64; _2_r_durationTicks: double);
Function ProcessAborted: boolean;
Function ProcessNumber( Const _1_t_nameOrID: string): int64;
Function q4ProcessState( _1_e_process: int64): int64;
Function ProcessInfo( _1_e_process: int64): TJSONObject;
Function ProcessActivity: TJSONObject;

Procedure AbortProcessByID( _1_e_processID: int64);
Procedure PauseProcess( _1_e_process: int64);
Procedure ResumeProcess( _1_e_process: int64);

Implementation

Uses
  DateUtils,
  q4DBmanager,
  metier_q4DBschemaBase,
  metier_q4DBschemaProcess,
  q4record,
  q4RecordLocking,
  q4transaction,
  q4Interruptions,
  q4Sets,
  q4namedSelections,
  q4dateAndTime,
  q4relations;

Threadvar
  ProcessDatabaseOpened: boolean;
  ProcessLockRecordInitialized: boolean;

Type
  TRegisteredProcess = Record
    ProcessID: int64;
    ProcessName: string;
    SessionUser: string;
    UserName4D: string;
    ThreadID: TThreadID;
    Options: Tq4ProcessOptions;
    DatabaseConnected: boolean;
    CreationDateTime: TDateTime;
    State: int64;
    IsAlive: boolean;
    AbortedRequested: boolean;
  End;

  Tq4ProcessThread = Class( TThread)
  private
    FProc: Tq4ProcessProc;
    FReservedProcessID: int64;
    FStackSizeQ4: SizeUInt;
    FOptions: Tq4ProcessOptions;
    FProcessName: string;
    FSessionUser: string;
    FUserName4D: string;
  protected
    Procedure Execute; override;
  public
    Constructor Create( _1_y_proc: Tq4ProcessProc; _2_y_stackSize: SizeUInt; Const _3_y_options: Tq4ProcessOptions; Const _4_t_processName: string;
      Const _5_t_sessionUser: string; Const _6_t_userName4D: string);
  End;

Var
  GlobalProcessCounter: int64 = 0;
  GProcessRegistryCS:   TRTLCriticalSection;
  GProcessRegistry:     Array Of TRegisteredProcess;

Function InternalNextProcessID: int64;
  Begin
    Result := integer( InterlockedIncrement64( GlobalProcessCounter));
  End;

Function InternalCurrentThreadID: TThreadID;
  Begin
    Result := TThreadID( GetCurrentThreadID);
  End;

Function InternalFindProcessIndexByID( _1_e_processID: int64): int64;
  Var
    i: int64;
  Begin
    For i := 0 To High( GProcessRegistry) Do If GProcessRegistry[i].ProcessID = _1_e_processID Then Exit( i);
    Result := -1;
  End;

Function InternalFindAliveProcessIndexByNameOrID( Const _1_t_nameOrID: string): int64;
  Var
    i: int64;
  Begin
    For i := 0 To High( GProcessRegistry) Do If GProcessRegistry[i].IsAlive Then If ( GProcessRegistry[i].ProcessName = _1_t_nameOrID) or ( IntToStr( GProcessRegistry[i].ProcessID) = _1_t_nameOrID) Then
          Exit( i);
    Result := -1;
  End;

Procedure InternalRegisterProcess( _1_e_processID: int64; Const _2_t_processName: string; Const _3_t_sessionUser: string; Const _4_t_userName4D: string;
  _5_y_threadID: TThreadID; Const _6_y_options: Tq4ProcessOptions; _7_b_databaseConnected: boolean; _8_e_state: int64);
  Var
    idx: int64;
  Begin
    EnterCriticalSection( GProcessRegistryCS);
    Try
      idx := InternalFindProcessIndexByID( _1_e_processID);
      If idx < 0 Then Begin
        idx := Length( GProcessRegistry);
        SetLength( GProcessRegistry, idx + 1);
      End;

      GProcessRegistry[idx].ProcessID := _1_e_processID;
      GProcessRegistry[idx].ProcessName := _2_t_processName;
      GProcessRegistry[idx].SessionUser := _3_t_sessionUser;
      GProcessRegistry[idx].UserName4D := _4_t_userName4D;
      GProcessRegistry[idx].ThreadID := _5_y_threadID;
      GProcessRegistry[idx].Options := _6_y_options;
      GProcessRegistry[idx].DatabaseConnected := _7_b_databaseConnected;
      GProcessRegistry[idx].CreationDateTime := Now;
      GProcessRegistry[idx].State := _8_e_state;
      GProcessRegistry[idx].IsAlive := True;
      GProcessRegistry[idx].AbortedRequested := False;
    Finally
      LeaveCriticalSection( GProcessRegistryCS);
    End;
  End;

Procedure InternalUpdateRegisteredState( _1_e_processID: int64; _2_e_state: int64);
  Var
    idx: int64;
  Begin
    EnterCriticalSection( GProcessRegistryCS);
    Try
      idx := InternalFindProcessIndexByID( _1_e_processID);
      If idx >= 0 Then GProcessRegistry[idx].State := _2_e_state;
    Finally
      LeaveCriticalSection( GProcessRegistryCS);
    End;
  End;

Procedure InternalMarkProcessDone( _1_e_processID: int64);
  Var
    idx: int64;
  Begin
    EnterCriticalSection( GProcessRegistryCS);
    Try
      idx := InternalFindProcessIndexByID( _1_e_processID);
      If idx >= 0 Then Begin
        GProcessRegistry[idx].IsAlive := False;
        GProcessRegistry[idx].State := psDoesNotExist;
      End;
    Finally
      LeaveCriticalSection( GProcessRegistryCS);
    End;
  End;

Procedure initProcess( _1_e_ordreProcess: int64; Const _2_t_processName: string; Const _3_t_sessionUser: string; Const _4_t_userName4D: string);
  Begin
    initProcess( _1_e_ordreProcess, _2_t_processName, _3_t_sessionUser, _4_t_userName4D, []);
  End;

Procedure initProcess( _1_e_ordreProcess: int64; Const _2_t_processName: string; Const _3_t_sessionUser: string; Const _4_t_userName4D: string; Const _5_y_options: Tq4ProcessOptions);
  Begin

    q4coreLanguage.OK := 1;      // 4D OK convention
    q4coreLanguage.Error := 0;

    If _1_e_ordreProcess > 0 Then ProcessState.processID := _1_e_ordreProcess
    Else
      ProcessState.processID := InternalNextProcessID;

    ProcessState.processName := _2_t_processName;
    ProcessState.sessionUser := _3_t_sessionUser;
    ProcessState.userName4D := _4_t_userName4D;
    ProcessState.options := _5_y_options;

    ProcessState.lastError := 0;
    ProcessState.lastErrorMessage := '';
    ProcessState.currentTableNumber := 0;
    ProcessState.formTableNumber := 0;
    ProcessState.databaseConnected := False;
    ProcessState.abortedRequested := False;

    q4arrays.q4arraysInitForThread;
    q4relations.q4relationsInitForThread;
    q4transaction.Initialize;

    If not ( poNoDatabaseConnection in _5_y_options) Then If not q4DBmanager.OpenDatabase( mt_globalDatabaseFileName) Then Begin
        q4coreLanguage.OK := 0;
        q4coreLanguage.Error := 1;
        ProcessState.lastError := 1;
        ProcessState.lastErrorMessage := 'OpenDatabase failed';
      End Else Begin
        ProcessState.databaseConnected := True;
        metier_q4DBschemaProcess.InitAllContexts;
        q4RecordLocking.Initialize( High( Tables));
      End;

    InternalRegisterProcess(
      integer( ProcessState.processID),
      _2_t_processName,
      _3_t_sessionUser,
      _4_t_userName4D,
      InternalCurrentThreadID,
      _5_y_options,
      ProcessState.databaseConnected,
      psExecuting
      );
  End;

Procedure assertProcessTemporaryStateClean;
  Begin

    q4Interruptions.assertTrace( not q4Record.hasPushedRecords,
      'Fin de process avec des PUSH RECORD non dépilés'
      );

    q4Interruptions.assertTrace( not q4Sets.hasLiveSets,
      'Fin de process avec des sets encore actifs'
      );

    q4Interruptions.assertTrace( not q4NamedSelections.hasLiveNamedSelections,
      'Fin de process avec des named selections encore actives'
      );
  End;

Procedure InternalDoneProcess( _1_e_ordreProcess: int64);
  Var
    LProcessID: int64;
  Begin
    assertProcessTemporaryStateClean;

    If ProcessState.databaseConnected Then Begin
      q4DBmanager.CloseDatabase;
      q4RecordLocking.DoneLockRecord;
    End;

    InternalMarkProcessDone( integer( ProcessState.processID));

    ProcessState.processID := 0;
    ProcessState.processName := '';
    ProcessState.sessionUser := '';
    ProcessState.userName4D := '';
    ProcessState.options := [];
    ProcessState.lastError := 0;
    ProcessState.lastErrorMessage := '';
    ProcessState.currentTableNumber := 0;
    ProcessState.formTableNumber := 0;
    ProcessState.databaseConnected := False;
    ProcessState.abortedRequested := False;

    q4arrays.q4arraysDoneForThread;
    q4relations.q4relationsDoneForThread;

    q4coreLanguage.OK := 0;
    q4coreLanguage.Error := 0;
  End;

Procedure doneProcess( _1_e_ordreProcess: int64);
  Begin
    InternalDoneProcess( _1_e_ordreProcess);
  End;

Procedure StartQ4( _1_y_proc: Tq4ProcessProc);
  Begin
    If not Assigned( _1_y_proc) Then Raise Exception.Create( 'StartQ4: procédure non assignée');

    // AStackSize n'a pas d'effet sur le thread courant ; paramètre gardé pour homogénéité d'API.
    initProcess( 0, 'StartQ4', '', '', []);
    Try
      _1_y_proc;
    Finally
      doneProcess( 0);
    End;
  End;

Constructor Tq4ProcessThread.Create( _1_y_proc: Tq4ProcessProc; _2_y_stackSize: SizeUInt; Const _3_y_options: Tq4ProcessOptions; Const _4_t_processName: string;
  Const _5_t_sessionUser: string; Const _6_t_userName4D: string);
  Begin
    Inherited Create( True, _2_y_stackSize);
    FreeOnTerminate := True;
    FProc := _1_y_proc;
    FReservedProcessID := InternalNextProcessID;
    FStackSizeQ4 := _2_y_stackSize;
    FOptions := _3_y_options;
    FProcessName := _4_t_processName;
    FSessionUser := _5_t_sessionUser;
    FUserName4D := _6_t_userName4D;
    Start;
  End;

Procedure Tq4ProcessThread.Execute;
  Begin
    If not Assigned( FProc) Then Raise Exception.Create( 'NewProcess: procédure non assignée');

    initProcess( FReservedProcessID, FProcessName, FSessionUser, FUserName4D, FOptions);
    Try
      FProc;
    Finally
      doneProcess( FReservedProcessID);
    End;
  End;

Function NewProcess( _1_y_proc: Tq4ProcessProc; _2_y_stackSize: SizeUInt; Const _3_y_options: Tq4ProcessOptions; Const _4_t_processName: string;
  Const _5_t_sessionUser: string; Const _6_t_userName4D: string): int64;
  Var
    LThread: Tq4ProcessThread;
  Begin
    If not Assigned( _1_y_proc) Then Raise Exception.Create( 'NewProcess: procédure non assignée');

    LThread := Tq4ProcessThread.Create( _1_y_proc, _2_y_stackSize, _3_y_options, _4_t_processName, _5_t_sessionUser, _6_t_userName4D);
    Result := LThread.FReservedProcessID;
  End;

Function CountTasks: int64;
  Var
    i: int64;
  Begin
    Result := 0;
    EnterCriticalSection( GProcessRegistryCS);
    Try
      For i := 0 To High( GProcessRegistry) Do If GProcessRegistry[i].IsAlive and ( GProcessRegistry[i].ProcessID > Result) Then Result := GProcessRegistry[i].ProcessID;
    Finally
      LeaveCriticalSection( GProcessRegistryCS);
    End;
  End;

Function CountUserProcesses: int64;
  Var
    i: int64;
  Begin
    Result := 0;
    EnterCriticalSection( GProcessRegistryCS);
    Try
      For i := 0 To High( GProcessRegistry) Do If GProcessRegistry[i].IsAlive Then Inc( Result);
    Finally
      LeaveCriticalSection( GProcessRegistryCS);
    End;
  End;

Function CountUsers: int64;
  Begin
    // Portage actuel : mode local / mono-utilisateur.
    Result := 1;
  End;

Function CurrentProcess: int64;
  Begin
    Result := integer( ProcessState.processID);
  End;

Function CurrentProcessName: string;
  Begin
    Result := ProcessState.processName;
  End;

Procedure DelayProcess( _1_e_process: int64; _2_r_durationTicks: double);
  Var
    LMs: cardinal;
  Begin
    If _1_e_process <> CurrentProcess Then Raise Exception.Create( 'DELAY PROCESS: seul le process courant est supporté pour le moment');

    InternalUpdateRegisteredState( _1_e_process, psDelayed);
    Try
      LMs := q4dateAndTime.ticksToMilliseconds( _2_r_durationTicks);
      Sleep( LMs);
    Finally
      InternalUpdateRegisteredState( _1_e_process, psExecuting);
    End;
  End;

Function ProcessAborted: boolean;
  Begin
    Result := ProcessState.abortedRequested;
  End;

Function ProcessNumber( Const _1_t_nameOrID: string): int64;
  Var
    idx: int64;
  Begin
    EnterCriticalSection( GProcessRegistryCS);
    Try
      idx := InternalFindAliveProcessIndexByNameOrID( _1_t_nameOrID);
      If idx >= 0 Then Result := GProcessRegistry[idx].ProcessID
      Else
        Result := 0;
    Finally
      LeaveCriticalSection( GProcessRegistryCS);
    End;
  End;

Function q4ProcessState( _1_e_process: int64): int64;
  Var
    idx: int64;
  Begin
    EnterCriticalSection( GProcessRegistryCS);
    Try
      idx := InternalFindProcessIndexByID( _1_e_process);
      If idx >= 0 Then Result := GProcessRegistry[idx].State
      Else
        Result := psDoesNotExist;
    Finally
      LeaveCriticalSection( GProcessRegistryCS);
    End;
  End;

Function ProcessInfo( _1_e_process: int64): TJSONObject;
  Var
    idx: int64;
  Begin
    Result := nil;
    EnterCriticalSection( GProcessRegistryCS);
    Try
      idx := InternalFindProcessIndexByID( _1_e_process);
      If idx < 0 Then Exit;

      Result := TJSONObject.Create;
      Result.Add( 'cpuTime', 0.0);
      Result.Add( 'cpuUsage', 0.0);
      Result.Add( 'creationDateTime', FormatDateTime( 'yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz', GProcessRegistry[idx].CreationDateTime));
      Result.Add( 'ID', GProcessRegistry[idx].ProcessID);
      Result.Add( 'name', GProcessRegistry[idx].ProcessName);
      Result.Add( 'number', GProcessRegistry[idx].ProcessID);
      Result.Add( 'preemptive', False);
      Result.Add( 'sessionID', '');
      Result.Add( 'state', GProcessRegistry[idx].State);
      Result.Add( 'type', 2);
    Finally
      LeaveCriticalSection( GProcessRegistryCS);
    End;
  End;

Function ProcessActivity: TJSONObject;
  Var
    i:     int64;
    LProcesses: TJSONArray;
    LInfo: TJSONObject;
  Begin
    Result := TJSONObject.Create;
    LProcesses := TJSONArray.Create;
    Result.Add( 'processes', LProcesses);
    Result.Add( 'sessions', TJSONArray.Create);

    EnterCriticalSection( GProcessRegistryCS);
    Try
      For i := 0 To High( GProcessRegistry) Do Begin
        If not GProcessRegistry[i].IsAlive Then Continue;

        LInfo := TJSONObject.Create;
        LInfo.Add( 'cpuTime', 0.0);
        LInfo.Add( 'cpuUsage', 0.0);
        LInfo.Add( 'creationDateTime', FormatDateTime( 'yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz', GProcessRegistry[i].CreationDateTime));
        LInfo.Add( 'ID', GProcessRegistry[i].ProcessID);
        LInfo.Add( 'name', GProcessRegistry[i].ProcessName);
        LInfo.Add( 'number', GProcessRegistry[i].ProcessID);
        LInfo.Add( 'preemptive', False);
        LInfo.Add( 'sessionID', '');
        LInfo.Add( 'state', GProcessRegistry[i].State);
        LInfo.Add( 'type', 2);
        LProcesses.Add( LInfo);
      End;
    Finally
      LeaveCriticalSection( GProcessRegistryCS);
    End;
  End;

Procedure AbortProcessByID( _1_e_processID: int64);
  Begin
    Raise Exception.Create( 'ABORT PROCESS BY ID: non implémenté pour le moment');
  End;

Procedure PauseProcess( _1_e_process: int64);
  Begin
    Raise Exception.Create( 'PAUSE PROCESS: non implémenté pour le moment');
  End;

Procedure ResumeProcess( _1_e_process: int64);
  Begin
    Raise Exception.Create( 'RESUME PROCESS: non implémenté pour le moment');
  End;

Initialization
  InitCriticalSection( GProcessRegistryCS);

Finalization
  DoneCriticalSection( GProcessRegistryCS);

End.
