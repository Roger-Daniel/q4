Unit q4interruptions;

{$mode objfpc}{$H+}

{
q4interruptions
version du 2026/05/14-02

Mapping 4D → q4interruptions -> statut
Command Number 4D,    4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
156,                  ABORT,                             abort,                            OK spécifique
1129,                 ASSERT,                            assert,                           OK spécifique
1132,                 Asserted,                          asserted,                         OK spécifique
321,                  FILTER EVENT,                      filterEvent,                      Partial
1130,                 Get assert enabled,                getAssertEnabled,                 OK
1799,                 Last errors,                       lastErrors,                       Partial
704,                  Method called on error,            methodCalledOnError,              Partial
705,                  Method called on event,            methodCalledOnEvent,              Partial
155,                  ON ERR CALL,                       onErrCall,                        Partial
190,                  ON EVENT CALL,                     onEventCall,                      Partial
1131,                 SET ASSERT ENABLED,                setAssertEnabled,                 OK spécifique
1805,                 throw,                             throw,                            Partial

Doc: https://developer.4d.com/docs/21/commands/theme/Interruptions

Commentaires q4 importants :

- Cette unité est le point central d'interruption du runtime q4.
- Les autres unités q4 ne doivent pas utiliser directement Assert, raise Exception,
  MessageDlg, Form ou une autre dépendance UI pour signaler un invariant interne.
- Les commandes 4D du thème Interruptions sont exposées avec leur nom q4 camelCase.
- Les helpers assertRaise/assertTrace/raiseTodo/raiseUnsupported restent disponibles
  pour le code interne q4 ; ils ne sont pas des commandes 4D.

Forme compacte autorisée :
  q4interruptions.assertRaise(_b_condition, _t_message, {$I %CURRENTROUTINE%}, {$I %LINENUM%});

Forme recommandée dans q4 pour les chemins sensibles :
  if _b_conditionErreur then
    q4interruptions.assertRaise(_t_message, {$I %CURRENTROUTINE%}, {$I %LINENUM%});

Le nom de la routine (fonction ou procédure) peut être injecté au point d'appel via :
  {$I %CURRENTROUTINE%}

Le numéro de la ligne peut être injecté au point d'appel via :
  {$I %LINENUM%}
}

Interface

Uses
  SysUtils, q4coreLanguage;

Const
  EK_LOCAL = 0;
  EK_GLOBAL = 1;
  EK_ERRORS_FROM_COMPONENTS = 2;

  Q4_ASSERT_ERROR_CODE = -10518;
  Q4_THROW_DEFAULT_ERROR_CODE = -1;
  Q4_ABORT_ERROR_CODE = 1006;
  Q4_TODO_ERROR_CODE = -90001;
  Q4_UNSUPPORTED_ERROR_CODE = -90002;

Type
  TQ4AssertHandler = Procedure( Const _1_t_message: string; Const _2_t_routine: string; _3_e_line: int64);
  TQ4InterruptionHandler = Procedure( _1_e_errorCode: int64; Const _2_t_message: string; Const _3_t_componentSignature: string);
  TQ4OnErrorHandler = Procedure( Const _1_t_errorMethod: string; Const _2_t_errorsJson: string);

  EQ4Interruption = Class( SysUtils.Exception)
  private
    _e_errorCode: int64;
    _t_componentSignature: string;
    _t_routine: string;
    _e_line: int64;
  public
    Constructor createQ4( _1_e_errorCode: int64; Const _2_t_message: string; Const _3_t_componentSignature: string; Const _4_t_routine: string; _5_e_line: int64);
    Property errorCode: int64 read _e_errorCode;
    Property componentSignature: string read _t_componentSignature;
    Property routine: string read _t_routine;
    Property line: int64 read _e_line;
  End;

  EQ4Abort = Class( EQ4Interruption);
  EQ4Assertion = Class( EQ4Interruption);
  EQ4Todo = Class( EQ4Interruption);
  EQ4Unsupported = Class( EQ4Interruption);
  EQ4RuntimeError = Class( EQ4Interruption);

// Commandes 4D du thème Interruptions
Procedure abort;
Procedure assert( _1_b_boolExpression: boolean; Const _2_t_messageText: string = '');
Function asserted( _1_b_boolExpression: boolean; Const _2_t_messageText: string = ''): boolean;
Procedure filterEvent;
Function getAssertEnabled: boolean;
Function lastErrors: string;
Function methodCalledOnError( _1_e_scope: int64 = EK_LOCAL): string;
Function methodCalledOnEvent: string;
Procedure onErrCall( Const _1_t_errorMethod: string; _2_e_scope: int64 = EK_LOCAL);
Procedure onEventCall( Const _1_t_eventMethod: string; Const _2_t_processName: string = '');
Procedure setAssertEnabled( _1_b_assertions: boolean; Const _2_t_star: string = '');
Procedure throw; overload;
Procedure throw( _1_e_errorCode: int64; Const _2_t_description: string = ''); overload;
Procedure throw( Const _1_t_errorObj: string); overload;

{ Helpers runtime q4 publics.
  Ces routines ne correspondent pas directement à des commandes 4D,
  mais elles sont l’API officielle utilisée par les autres unités q4
  pour centraliser les interruptions, assertions internes et erreurs TODO. }
Procedure assertRaise( Const _1_t_message: string; Const _2_t_routine: string = ''; _3_e_line: int64 = 0); overload;
Procedure assertRaise( _1_b_condition: boolean; Const _2_t_message: string; Const _3_t_routine: string = ''; _4_e_line: int64 = 0); overload;
Procedure assertTrace( Const _1_t_message: string; Const _2_t_routine: string = ''; _3_e_line: int64 = 0); overload;
Procedure assertTrace( _1_b_condition: boolean; Const _2_t_message: string; Const _3_t_routine: string = ''; _4_e_line: int64 = 0); overload;
Procedure raiseTodo( Const _1_t_message: string; Const _2_t_routine: string = '');
Procedure raiseUnsupported( Const _1_t_message: string; Const _2_t_routine: string = '');

Procedure setAssertHandler( _1_p_handler: TQ4AssertHandler);
Procedure clearAssertHandler;
Function getAssertHandler: TQ4AssertHandler;
Procedure q4SetAssertHandler( _1_p_handler: TQ4AssertHandler);

Procedure setInterruptionHandler( _1_p_handler: TQ4InterruptionHandler);
Procedure clearInterruptionHandler;
Function getInterruptionHandler: TQ4InterruptionHandler;

Procedure setOnErrorHandler( _1_p_handler: TQ4OnErrorHandler);
Procedure clearOnErrorHandler;
Function getOnErrorHandler: TQ4OnErrorHandler;

Function isCurrentEventFiltered: boolean;
Procedure clearCurrentEventFilter;
Procedure clearLastErrors;

Implementation

Var
  _p_assertHandler: TQ4AssertHandler = nil;
  _p_interruptionHandler: TQ4InterruptionHandler = nil;
  _p_onErrorHandler: TQ4OnErrorHandler = nil;
  _b_globalAssertEnabled: boolean = True;
  _t_globalErrorMethod: string = '';
  _t_componentErrorMethod: string = '';
  _y_errorLock: TRTLCriticalSection;

Threadvar
  _b_localAssertEnabledDefined: boolean;
  _b_localAssertEnabled: boolean;
  _t_localErrorMethod: string;
  _t_eventMethod:      string;
  _t_eventProcessName: string;
  _b_currentEventFiltered: boolean;
  _t_errorEntriesJson: string;

Constructor EQ4Interruption.createQ4( _1_e_errorCode: int64; Const _2_t_message: string; Const _3_t_componentSignature: string; Const _4_t_routine: string; _5_e_line: int64);
  Begin
    Inherited Create( _2_t_message);
    _e_errorCode := _1_e_errorCode;
    _t_componentSignature := _3_t_componentSignature;
    _t_routine := _4_t_routine;
    _e_line := _5_e_line;
  End;

Function jsonEscape( Const _1_t_value: string): string;
  Var
    _t_char: char;
  Begin
    Result := '';
    For _t_char in _1_t_value Do Case _t_char Of
        '"': Result := Result + '\"';
        '\': Result := Result + '\\';
        '/': Result := Result + '\/';
        #8: Result := Result + '\b';
        #9: Result := Result + '\t';
        #10: Result := Result + '\n';
        #12: Result := Result + '\f';
        #13: Result := Result + '\r';
        #0..#7, #11, #14..#31: Result := Result + '\u' + SysUtils.IntToHex( Ord( _t_char), 4);
        Else Result := Result + _t_char;
      End;
  End;

Function buildErrorJson( _1_e_errorCode: int64; Const _2_t_message: string; Const _3_t_componentSignature: string): string;
  Begin
    Result := '{"errCode":' + SysUtils.IntToStr( _1_e_errorCode) + ',"message":"' + jsonEscape( _2_t_message) + '"' + ',"componentSignature":"' + jsonEscape( _3_t_componentSignature) + '"}';
  End;

Function currentErrorsJson: string;
  Begin
    If _t_errorEntriesJson = '' Then Exit( 'null');

    Result := '[' + _t_errorEntriesJson + ']';
  End;

Function buildMessageWithLocation( Const _1_t_message: string; Const _2_t_routine: string; _3_e_line: int64): string;
  Begin
    If _2_t_routine <> '' Then Result := SysUtils.Format( '%s (%s:%d)', [_1_t_message, _2_t_routine, _3_e_line])
    Else
      Result := _1_t_message;
  End;

Procedure appendLastError( _1_e_errorCode: int64; Const _2_t_message: string; Const _3_t_componentSignature: string);
  Var
    _t_errorJson: string;
  Begin
    _t_errorJson := buildErrorJson( _1_e_errorCode, _2_t_message, _3_t_componentSignature);

    If _t_errorEntriesJson <> '' Then _t_errorEntriesJson := _t_errorEntriesJson + ',';

    _t_errorEntriesJson := _t_errorEntriesJson + _t_errorJson;
    q4coreLanguage.Error := _1_e_errorCode;
  End;

Function getErrorMethodNoLock( _1_e_scope: int64): string;
  Begin
    Case _1_e_scope Of
      EK_GLOBAL: Result := _t_globalErrorMethod;
      EK_ERRORS_FROM_COMPONENTS: Result := _t_componentErrorMethod;
      Else Result := _t_localErrorMethod;
    End;
  End;

Procedure notifyHandlers( _1_e_errorCode: int64; Const _2_t_message: string; Const _3_t_componentSignature: string);
  Var
    _t_errorMethod: string;
    _t_errorsJson:  string;
  Begin
    If Assigned( _p_interruptionHandler) Then _p_interruptionHandler( _1_e_errorCode, _2_t_message, _3_t_componentSignature);

    System.EnterCriticalSection( _y_errorLock);
    Try
      _t_errorMethod := getErrorMethodNoLock( EK_LOCAL);
      If _t_errorMethod = '' Then _t_errorMethod := getErrorMethodNoLock( EK_GLOBAL);
    Finally
      System.LeaveCriticalSection( _y_errorLock);
    End;

    If ( _t_errorMethod <> '') and Assigned( _p_onErrorHandler) Then Begin
      _t_errorsJson := currentErrorsJson;
      _p_onErrorHandler( _t_errorMethod, _t_errorsJson);
    End;
  End;

Procedure registerError( _1_e_errorCode: int64; Const _2_t_message: string; Const _3_t_componentSignature: string);
  Begin
    appendLastError( _1_e_errorCode, _2_t_message, _3_t_componentSignature);
    notifyHandlers( _1_e_errorCode, _2_t_message, _3_t_componentSignature);
  End;

Procedure abort;
  Begin
    //https://developer.4d.com/docs/21/commands/abort
    registerError( Q4_ABORT_ERROR_CODE, 'ABORT', 'q4rt');
    Raise EQ4Abort.createQ4( Q4_ABORT_ERROR_CODE, 'Q4 ABORT', 'q4rt', '', 0);
  End;

Procedure assert( _1_b_boolExpression: boolean; Const _2_t_messageText: string);
  Begin
    //https://developer.4d.com/docs/21/commands/assert
    If not getAssertEnabled Then Exit;

    If _1_b_boolExpression Then Exit;

    If _2_t_messageText <> '' Then registerError( Q4_ASSERT_ERROR_CODE, 'Assert failed: ' + _2_t_messageText, 'q4rt')
    Else
      registerError( Q4_ASSERT_ERROR_CODE, 'Assert failed', 'q4rt');

    Raise EQ4Assertion.createQ4( Q4_ASSERT_ERROR_CODE, 'Q4 ASSERT: ' + _2_t_messageText, 'q4rt', '', 0);
  End;

Function asserted( _1_b_boolExpression: boolean; Const _2_t_messageText: string): boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/asserted
    Result := _1_b_boolExpression;

    If not getAssertEnabled Then Exit;

    If Result Then Exit;

    If _2_t_messageText <> '' Then registerError( Q4_ASSERT_ERROR_CODE, 'Assert failed: ' + _2_t_messageText, 'q4rt')
    Else
      registerError( Q4_ASSERT_ERROR_CODE, 'Assert failed', 'q4rt');

    Raise EQ4Assertion.createQ4( Q4_ASSERT_ERROR_CODE, 'Q4 ASSERTED: ' + _2_t_messageText, 'q4rt', '', 0);
  End;

Procedure filterEvent;
  Begin
    //https://developer.4d.com/docs/21/commands/filter-event
    // q4 n'a pas de file d'événements 4D globale. On mémorise donc seulement
    // que l'événement courant a été filtré ; l'intégration UI Lazarus pourra
    // consommer ce flag dans la boucle d'événements applicative.
    _b_currentEventFiltered := True;
  End;

Function getAssertEnabled: boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/get-assert-enabled
    If _b_localAssertEnabledDefined Then Exit( _b_localAssertEnabled);

    Result := _b_globalAssertEnabled;
  End;

Function lastErrors: string;
  Begin
    //https://developer.4d.com/docs/21/commands/last-errors
    Result := currentErrorsJson;
  End;

Function methodCalledOnError( _1_e_scope: int64): string;
  Begin
    //https://developer.4d.com/docs/21/commands/method-called-on-error
    System.EnterCriticalSection( _y_errorLock);
    Try
      Result := getErrorMethodNoLock( _1_e_scope);
    Finally
      System.LeaveCriticalSection( _y_errorLock);
    End;
  End;

Function methodCalledOnEvent: string;
  Begin
    //https://developer.4d.com/docs/21/commands/method-called-on-event
    Result := _t_eventMethod;
  End;

Procedure onErrCall( Const _1_t_errorMethod: string; _2_e_scope: int64);
  Begin
    //https://developer.4d.com/docs/21/commands/on-err-call
    System.EnterCriticalSection( _y_errorLock);
    Try
      Case _2_e_scope Of
        EK_GLOBAL: _t_globalErrorMethod := _1_t_errorMethod;
        EK_ERRORS_FROM_COMPONENTS: _t_componentErrorMethod := _1_t_errorMethod;
        Else _t_localErrorMethod := _1_t_errorMethod;
      End;
    Finally
      System.LeaveCriticalSection( _y_errorLock);
    End;
  End;

Procedure onEventCall( Const _1_t_eventMethod: string; Const _2_t_processName: string);
  Begin
    //https://developer.4d.com/docs/21/commands/on-event-call
    // q4 ne lance pas ici de process d'événements autonome comme 4D. Le nom de
    // méthode et le nom de process sont conservés pour l'intégration applicative.
    _t_eventMethod := _1_t_eventMethod;
    _t_eventProcessName := _2_t_processName;
  End;

Procedure setAssertEnabled( _1_b_assertions: boolean; Const _2_t_star: string);
  Begin
    //https://developer.4d.com/docs/21/commands/set-assert-enabled
    If _2_t_star = '*' Then Begin
      _b_localAssertEnabledDefined := True;
      _b_localAssertEnabled := _1_b_assertions;
    End Else Begin
      // Différence q4 volontaire : un changement global ne peut pas effacer les
      // overrides threadvar déjà posés dans d'autres threads FPC. On efface au
      // moins l'override du thread courant afin que l'appel sans * s'applique ici.
      _b_globalAssertEnabled := _1_b_assertions;
      _b_localAssertEnabledDefined := False;
      _b_localAssertEnabled := False;
    End;
  End;

Procedure throw;
  Begin
    //https://developer.4d.com/docs/21/commands/throw
    If _t_errorEntriesJson = '' Then registerError( Q4_THROW_DEFAULT_ERROR_CODE, 'throw', 'q4rt');

    Raise EQ4RuntimeError.createQ4( q4coreLanguage.Error, currentErrorsJson, 'q4rt', '', 0);
  End;

Procedure throw( _1_e_errorCode: int64; Const _2_t_description: string);
  Var
    _t_description: string;
  Begin
    //https://developer.4d.com/docs/21/commands/throw
    If _2_t_description <> '' Then _t_description := _2_t_description
    Else
      _t_description := 'Error code: ' + SysUtils.IntToStr( _1_e_errorCode) + ' (host)';

    registerError( _1_e_errorCode, _t_description, 'host');
    Raise EQ4RuntimeError.createQ4( _1_e_errorCode, _t_description, 'host', '', 0);
  End;

Procedure throw( Const _1_t_errorObj: string);
  Begin
    //https://developer.4d.com/docs/21/commands/throw
    // q4 v1.x manipule les objets en JSON texte sans validation systématique.
    // Cette surcharge conserve donc l'objet fourni dans Last errors, sans parser
    // les propriétés errCode, message, componentSignature ou deferred.
    If _t_errorEntriesJson <> '' Then _t_errorEntriesJson := _t_errorEntriesJson + ',';

    If _1_t_errorObj <> '' Then _t_errorEntriesJson := _t_errorEntriesJson + _1_t_errorObj
    Else
      _t_errorEntriesJson := _t_errorEntriesJson + buildErrorJson( Q4_THROW_DEFAULT_ERROR_CODE, 'throw', 'host');

    q4coreLanguage.Error := Q4_THROW_DEFAULT_ERROR_CODE;
    notifyHandlers( Q4_THROW_DEFAULT_ERROR_CODE, _1_t_errorObj, 'host');
    Raise EQ4RuntimeError.createQ4( Q4_THROW_DEFAULT_ERROR_CODE, _1_t_errorObj, 'host', '', 0);
  End;

Procedure assertRaise( Const _1_t_message: string; Const _2_t_routine: string; _3_e_line: int64);
  Var
    _t_fullMessage: string;
  Begin
    _t_fullMessage := buildMessageWithLocation( _1_t_message, _2_t_routine, _3_e_line);

    If Assigned( _p_assertHandler) Then _p_assertHandler( _t_fullMessage, _2_t_routine, _3_e_line);

    registerError( Q4_ASSERT_ERROR_CODE, _t_fullMessage, 'q4rt');
    Raise EQ4Assertion.createQ4( Q4_ASSERT_ERROR_CODE, 'Q4 ASSERT: ' + _t_fullMessage, 'q4rt', _2_t_routine, _3_e_line);
  End;

Procedure assertRaise( _1_b_condition: boolean; Const _2_t_message: string; Const _3_t_routine: string; _4_e_line: int64);
  Begin
    If _1_b_condition Then Exit;

    assertRaise( _2_t_message, _3_t_routine, _4_e_line);
  End;

Procedure assertTrace( Const _1_t_message: string; Const _2_t_routine: string; _3_e_line: int64);
  Var
    _t_fullMessage: string;
  Begin
    _t_fullMessage := buildMessageWithLocation( _1_t_message, _2_t_routine, _3_e_line);

    If Assigned( _p_assertHandler) Then _p_assertHandler( _t_fullMessage, _2_t_routine, _3_e_line);
  End;

Procedure assertTrace( _1_b_condition: boolean; Const _2_t_message: string; Const _3_t_routine: string; _4_e_line: int64);
  Begin
    If _1_b_condition Then Exit;

    assertTrace( _2_t_message, _3_t_routine, _4_e_line);
  End;

Procedure raiseTodo( Const _1_t_message: string; Const _2_t_routine: string);
  Var
    _t_fullMessage: string;
  Begin
    _t_fullMessage := buildMessageWithLocation( _1_t_message, _2_t_routine, 0);
    registerError( Q4_TODO_ERROR_CODE, _t_fullMessage, 'q4rt');
    Raise EQ4Todo.createQ4( Q4_TODO_ERROR_CODE, 'TODO q4 runtime: ' + _t_fullMessage, 'q4rt', _2_t_routine, 0);
  End;

Procedure raiseUnsupported( Const _1_t_message: string; Const _2_t_routine: string);
  Var
    _t_fullMessage: string;
  Begin
    _t_fullMessage := buildMessageWithLocation( _1_t_message, _2_t_routine, 0);
    registerError( Q4_UNSUPPORTED_ERROR_CODE, _t_fullMessage, 'q4rt');
    Raise EQ4Unsupported.createQ4( Q4_UNSUPPORTED_ERROR_CODE, 'Unsupported in q4: ' + _t_fullMessage, 'q4rt', _2_t_routine, 0);
  End;

Procedure setAssertHandler( _1_p_handler: TQ4AssertHandler);
  Begin
    _p_assertHandler := _1_p_handler;
  End;

Procedure clearAssertHandler;
  Begin
    _p_assertHandler := nil;
  End;

Function getAssertHandler: TQ4AssertHandler;
  Begin
    Result := _p_assertHandler;
  End;

Procedure q4SetAssertHandler( _1_p_handler: TQ4AssertHandler);
  Begin
    setAssertHandler( _1_p_handler);
  End;

Procedure setInterruptionHandler( _1_p_handler: TQ4InterruptionHandler);
  Begin
    _p_interruptionHandler := _1_p_handler;
  End;

Procedure clearInterruptionHandler;
  Begin
    _p_interruptionHandler := nil;
  End;

Function getInterruptionHandler: TQ4InterruptionHandler;
  Begin
    Result := _p_interruptionHandler;
  End;

Procedure setOnErrorHandler( _1_p_handler: TQ4OnErrorHandler);
  Begin
    _p_onErrorHandler := _1_p_handler;
  End;

Procedure clearOnErrorHandler;
  Begin
    _p_onErrorHandler := nil;
  End;

Function getOnErrorHandler: TQ4OnErrorHandler;
  Begin
    Result := _p_onErrorHandler;
  End;

Function isCurrentEventFiltered: boolean;
  Begin
    Result := _b_currentEventFiltered;
  End;

Procedure clearCurrentEventFilter;
  Begin
    _b_currentEventFiltered := False;
  End;

Procedure clearLastErrors;
  Begin
    _t_errorEntriesJson := '';
    q4coreLanguage.Error := 0;
  End;

Initialization
  System.InitCriticalSection( _y_errorLock);

Finalization
  System.DoneCriticalSection( _y_errorLock);

End.
