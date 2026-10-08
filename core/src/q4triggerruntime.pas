Unit q4triggerRuntime;

{$mode objfpc}{$H+}

Interface

Uses
  SysUtils,
  q4coreLanguage,
  q4interruptions;

Type
  TQ4TriggerEvent = (
    q4teOnSavingNewRecord,
    q4teOnSavingExistingRecord,
    q4teOnDeletingRecord
    );

  TQ4TriggerProc = Procedure( Var _1_p_recordTable; Const _2_e_event: TQ4TriggerEvent);

  TQ4TriggerTableAccessProc = Function( Const _1_e_sourceTableNo, _2_e_targetTableNo: int64): boolean;

Const
  Q4ErrorTriggerForbiddenCommand = -32001;
  Q4ErrorTriggerForbiddenSelection = -32002;
  Q4ErrorTriggerForbiddenSinkWrite = -32003;

Threadvar
  ge_triggerDisableLevel: int64;

Procedure disableTriggers;
Procedure enableTriggers;
Function triggersEnabled: boolean;

Function q4InTrigger: boolean;
Procedure q4BeginTrigger( Const _1_e_tableNo: int64; Const _2_e_event: TQ4TriggerEvent);
Procedure q4EndTrigger;

Function q4CurrentTriggerEvent: TQ4TriggerEvent;
Function q4CurrentTriggerTableNo: int64;

Function q4TriggerTableAccessAllowed( Const _1_e_targetTableNo: int64): boolean;
Procedure q4ExecuteTrigger( Var _1_p_recordTable; Const _2_e_event: TQ4TriggerEvent);

Procedure q4RaiseTriggerError( Const _1_e_code: int64; Const _2_t_message: string);

Var
  q4OnTrigger: TQ4TriggerProc = nil;
  q4OnTriggerTableAccess: TQ4TriggerTableAccessProc = nil;

Implementation

Type
  TQ4TriggerRuntimeState = Record
    Active: boolean;
    SourceTableNo: int64;
    Event: TQ4TriggerEvent;
    Depth: int64;
  End;

Threadvar
  g_q4TriggerRuntime: TQ4TriggerRuntimeState;

Procedure disableTriggers;
  Begin
    {//Inc(ge_triggerDisableLevel)}

    If ( ge_triggerDisableLevel > 0) Then q4interruptions.assertTrace( False, 'disableTrigger déjà effectué.')
    Else
      ge_triggerDisableLevel := 1;
  End;

Procedure enableTriggers;
  Begin
    //Dec(ge_triggerDisableLevel)
    If ( ge_triggerDisableLevel = 0) Then q4interruptions.assertTrace( False, 'enableTriggers déjà effectué.')
    Else
      ge_triggerDisableLevel := 0;
  End;

Function triggersEnabled: boolean;
  Begin
    Result := ge_triggerDisableLevel = 0;
  End;

Function q4InTrigger: boolean;
  Begin
    Result := g_q4TriggerRuntime.Active;
  End;

Procedure q4BeginTrigger( Const _1_e_tableNo: int64; Const _2_e_event: TQ4TriggerEvent);
  Begin
    Inc( g_q4TriggerRuntime.Depth);
    g_q4TriggerRuntime.Active := True;
    g_q4TriggerRuntime.SourceTableNo := _1_e_tableNo;
    g_q4TriggerRuntime.Event := _2_e_event;
  End;

Procedure q4EndTrigger;
  Begin
    Dec( g_q4TriggerRuntime.Depth);

    If ( g_q4TriggerRuntime.Depth <= 0) Then Begin
      g_q4TriggerRuntime.Active := False;
      g_q4TriggerRuntime.SourceTableNo := 0;
      g_q4TriggerRuntime.Depth := 0;
    End;
  End;

Function q4CurrentTriggerEvent: TQ4TriggerEvent;
  Begin
    Result := g_q4TriggerRuntime.Event;
  End;

Function q4CurrentTriggerTableNo: int64;
  Begin
    Result := g_q4TriggerRuntime.SourceTableNo;
  End;

Function q4TriggerTableAccessAllowed( Const _1_e_targetTableNo: int64): boolean;
  Begin
    If ( not q4InTrigger) Then Exit( True);

    If ( not Assigned( q4OnTriggerTableAccess)) Then Exit( False);

    Result := q4OnTriggerTableAccess( g_q4TriggerRuntime.SourceTableNo, _1_e_targetTableNo);
  End;

Procedure q4ExecuteTrigger( Var _1_p_recordTable; Const _2_e_event: TQ4TriggerEvent);
  Begin
    If ( Assigned( q4OnTrigger)) Then q4OnTrigger( _1_p_recordTable, _2_e_event);
  End;

Procedure q4RaiseTriggerError( Const _1_e_code: int64; Const _2_t_message: string);
  Begin
    error := _1_e_code;
    Raise Exception.Create( _2_t_message);
  End;

End.
