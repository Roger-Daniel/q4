Unit q4selection;

{$mode objfpc}{$H+}

{
q4selection
version du 2026/04/26-06

Mapping 4D
Command Number 4D,   4D Command,                      q4 API,                           Statut
------------------------------------------------------------------------------------------------
47,                  ALL RECORDS,                     allRecords,                       Partial,
245,                 GOTO SELECTED RECORD,            gotoSelectedRecord,               Partial,
189,                 ONE RECORD SELECT,               oneRecordSelect,                  Partial,
640,                 CREATE SELECTION FROM ARRAY,     createSelectionFromArray,         Partial,
50,                  FIRST RECORD,                    firstRecord,                      Partial,
200,                 LAST RECORD,                     lastRecord,                       Partial,
51,                  NEXT RECORD,                     nextRecord,                       Partial,
110,                 PREVIOUS RECORD,                 previousRecord,                   Partial,
351,                 REDUCE SELECTION,                reduceSelection,                  Partial,
76,                  Records in selection,            recordsInSelection,               OK,
246,                 Selected record number,          selectedRecordNumber,             OK,
198,                 Before selection,                beforeSelection,                  OK,
36,                  End selection,                   endSelection,                     OK,
1051,                TRUNCATE TABLE,                  truncateTable,                    Partial,

Doc: https://developer.4d.com/docs/21/commands/theme/Selection
}

Interface

Uses
  SysUtils,
  Dialogs,
  SQLDB,
  q4coreLanguage,
  q4interruptions,
  metier_q4DBschemaBase,
  metier_q4DBschemaProcess,
  q4DBschemaUse,
  q4DBmanager,
  q4selectionTablesCore,
  q4RecordLocking,
  q4transaction;

Type
  Tq4selectionBuildState = (
    sbsNone,
    sbsPendingAllRecordsOrder,
    sbsPendingQuery,
    sbsPendingQuerySelection,
    sbsPendingQueryOrder,
    sbsPendingQuerySelectionOrder,
    sbsMaterialized
    );

  Tq4QueryDestinationKind = (
    qdkCurrentSelection,
    qdkSet,
    qdkNamedSelection,
    qdkVariable
    );

  Ty_selectionTableState = Record
    e_sourceTableId: int64;
    t_sourceTableName: string;
    t_tempTableName: string;
    t_pkFieldName: string;
    t_pkTypeSQL: string;
    b_isCreated: boolean;

    e_currentResultNo: int64;
    e_nextResultNo: int64;
    e_currentPos: int64;
    e_recordCount: int64;
    b_isEmpty: boolean;

    e_buildState: Tq4selectionBuildState;

    t_pendingWhereSQL: string;
    t_pendingOrderBySQL: string;

    e_pendingDestinationKind: Tq4QueryDestinationKind;
    t_pendingDestinationName: string;

    e_pendingQueryLimit: int64;
    e_pendingReduceCount: int64;
  End;

  Tty_selectionTableState = Array Of Ty_selectionTableState;

  //Tq4LongintArray = array of longint;
  Tq4Int64Array = Array Of int64;

  Ty_sharedSelectionStore = Record
    b_isInitialized: boolean;
    t_registryTableName: string;
    t_itemsTableName: string;
  End;

Threadvar
  ty_selectionTables: Tty_selectionTableState;

Var
  y_sharedSelectionStore: Ty_sharedSelectionStore;

Procedure allRecords( Var _1_p_recordTable); overload;
Procedure allRecords( Var _1_p_recordTable; Const _2_t_flag: string); overload;

Procedure oneRecordSelect( Var _1_p_recordTable); overload;
Procedure oneRecordSelect( Var _1_p_table: Pointer); overload;

Procedure gotoSelectedRecord( Var _1_p_recordTable; Const _2_e_selectedRecordNo: int64); overload;
Procedure gotoSelectedRecord( Var _1_p_table: Pointer; Const _2_e_selectedRecordNo: int64); overload;

Procedure nextRecord( Var _1_p_recordTable); overload;
Procedure nextRecord( Var _1_p_table: Pointer); overload;

Procedure previousRecord( Var _1_p_recordTable); overload;
Procedure previousRecord( Var _1_p_table: Pointer); overload;

Function recordsInSelection( Var _1_p_recordTable): int64; overload;
Function recordsInSelection( Var _1_p_table: Pointer): int64; overload;

Function beforeSelection( Var _1_p_recordTable): boolean; overload;
Function beforeSelection( Var _1_p_table: Pointer): boolean; overload;

Function endSelection( Var _1_p_recordTable): boolean; overload;
Function endSelection( Var _1_p_table: Pointer): boolean; overload;

Function selectedRecordNumber( Var _1_p_recordTable): int64; overload;
Function selectedRecordNumber( Var _1_p_table: Pointer): int64; overload;

Function selectedRecordNumberOrZero( Var _1_p_recordTable): int64; overload;
Function selectedRecordNumberOrZero( Var _1_p_table: Pointer): int64; overload;

Procedure firstRecord( Var _1_p_recordTable); overload;
Procedure firstRecord( Var _1_p_table: Pointer); overload;

Procedure reduceSelection( Var _1_p_recordTable; Const _2_e_number: int64); overload;
Procedure reduceSelection( Var _1_p_table: Pointer; Const _2_e_number: int64); overload;

Procedure deleteSelection( Var _1_p_recordTable); overload;
Procedure deleteSelection( Var _1_p_table: Pointer); overload;

Procedure truncateTable( Var _1_p_recordTable); overload;
Procedure truncateTable( Var _1_p_table: Pointer); overload;

//procedure createSelectionFromArray(var ARecordTable; const ARecordNumbers: Tq4LongintArray); overload;
//procedure createSelectionFromArray(var ARecordTable; const ARecordNumbers: Tq4LongintArray; const t_selectionName: string); overload;
Procedure createSelectionFromArray( Var _1_p_recordTable; Const _2_te_recordNumbers: Tq4Int64Array); overload;
Procedure createSelectionFromArray( Var _1_p_recordTable; Const _2_te_recordNumbers: Tq4Int64Array; Const _3_t_selectionName: string); overload;

//procedure createSelectionFromArray(var p_table: Pointer; const ARecordNumbers: Tq4LongintArray); overload;
//procedure createSelectionFromArray(var p_table: Pointer; const ARecordNumbers: Tq4LongintArray; const t_selectionName: string); overload;
Procedure createSelectionFromArray( Var _1_p_table: Pointer; Const _2_te_recordNumbers: Tq4Int64Array); overload;
Procedure createSelectionFromArray( Var _1_p_table: Pointer; Const _2_te_recordNumbers: Tq4Int64Array; Const _3_t_selectionName: string); overload;

Procedure createSelectionFromPkSelect( Var _1_p_recordTable; Const _2_t_selectPkSql: string); overload;
Procedure createSelectionFromPkSelect( Var _1_p_table: Pointer; Const _2_t_selectPkSql: string); overload;

Function currentSelectionPkSelect( Var _1_p_recordTable; out _2_t_selectPkSql: string): boolean; overload;
Function currentSelectionPkSelect( Var _1_p_table: Pointer; out _2_t_selectPkSql: string): boolean; overload;

Implementation

Uses
  q4record,
  q4setsAndNamedSelectionsCore,
  q4triggerRuntime;

Function runtimeOf( Var _1_p_table: Pointer): Pq4recordRuntime; Inline;
  Begin
    Result := Pq4recordRuntime( _1_p_table);
  End;

Procedure oneRecordSelect( Var _1_p_table: Pointer); overload;
  Begin
    oneRecordSelect( runtimeOf( _1_p_table)^);
  End;

Procedure gotoSelectedRecord( Var _1_p_table: Pointer; Const _2_e_selectedRecordNo: int64); overload;
  Begin
    gotoSelectedRecord( runtimeOf( _1_p_table)^, _2_e_selectedRecordNo);
  End;

Procedure nextRecord( Var _1_p_table: Pointer); overload;
  Begin
    nextRecord( runtimeOf( _1_p_table)^);
  End;

Procedure previousRecord( Var _1_p_table: Pointer); overload;
  Begin
    previousRecord( runtimeOf( _1_p_table)^);
  End;

Function recordsInSelection( Var _1_p_table: Pointer): int64; overload;
  Begin
    Result := recordsInSelection( runtimeOf( _1_p_table)^);
  End;

Function beforeSelection( Var _1_p_table: Pointer): boolean; overload;
  Begin
    Result := beforeSelection( runtimeOf( _1_p_table)^);
  End;

Function endSelection( Var _1_p_table: Pointer): boolean; overload;
  Begin
    Result := endSelection( runtimeOf( _1_p_table)^);
  End;

Procedure firstRecord( Var _1_p_table: Pointer); overload;
  Begin
    firstRecord( runtimeOf( _1_p_table)^);
  End;

Function selectedRecordNumber( Var _1_p_table: Pointer): int64; overload;
  Begin
    Result := selectedRecordNumber( runtimeOf( _1_p_table)^);
  End;

Function selectedRecordNumberOrZero( Var _1_p_table: Pointer): int64; overload;
  Begin
    Result := selectedRecordNumberOrZero( runtimeOf( _1_p_table)^);
  End;

Procedure reduceSelection( Var _1_p_table: Pointer; Const _2_e_number: int64); overload;
  Begin
    reduceSelection( runtimeOf( _1_p_table)^, _2_e_number);
  End;

Procedure deleteSelection( Var _1_p_table: Pointer); overload;
  Begin
    deleteSelection( runtimeOf( _1_p_table)^);
  End;

Procedure truncateTable( Var _1_p_table: Pointer); overload;
  Begin
    truncateTable( runtimeOf( _1_p_table)^);
  End;

//procedure createSelectionFromArray(var p_table: Pointer; const ARecordNumbers: Tq4LongintArray); overload;
//begin
//  createSelectionFromArray(runtimeOf(p_table)^, ARecordNumbers);
//end;

//procedure createSelectionFromArray(var p_table: Pointer; const ARecordNumbers: Tq4LongintArray; const t_selectionName: string); overload;
//begin
//  createSelectionFromArray(runtimeOf(p_table)^, ARecordNumbers, t_selectionName);
//end;

Procedure createSelectionFromArray( Var _1_p_table: Pointer; Const _2_te_recordNumbers: Tq4Int64Array); overload;
  Begin
    createSelectionFromArray( runtimeOf( _1_p_table)^, _2_te_recordNumbers);
  End;

Procedure createSelectionFromArray( Var _1_p_table: Pointer; Const _2_te_recordNumbers: Tq4Int64Array; Const _3_t_selectionName: string); overload;
  Begin
    createSelectionFromArray( runtimeOf( _1_p_table)^, _2_te_recordNumbers, _3_t_selectionName);
  End;

Procedure createSelectionFromPkSelect( Var _1_p_table: Pointer; Const _2_t_selectPkSql: string); overload;
  Begin
    createSelectionFromPkSelect( runtimeOf( _1_p_table)^, _2_t_selectPkSql);
  End;

Function currentSelectionPkSelect( Var _1_p_table: Pointer; out _2_t_selectPkSql: string): boolean; overload;
  Begin
    Result := currentSelectionPkSelect( runtimeOf( _1_p_table)^, _2_t_selectPkSql);
  End;

Function findSelectionTableStateIndex( Const _1_e_sourceTableId: int64): int64;
  Var
    _e_i: int64;
  Begin
    Result := -1;

    For _e_i := 0 To High( ty_selectionTables) Do If ( ty_selectionTables[_e_i].e_sourceTableId = _1_e_sourceTableId) Then Begin
        Result := _e_i;
        Exit;
      End;
  End;

Function recordsInSelection( Var _1_p_recordTable): int64; overload;
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
  Begin
    // https://developer.4d.com/docs/commands/records-in-selection

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.recordsInSelection : _noTable invalide');

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    q4interruptions.assertRaise( _e_idx >= 0,
      'q4selection.recordsInSelection : etat de selection introuvable');

    Result := ty_selectionTables[_e_idx].e_recordCount;
  End;

Function inSelection( Var _1_p_recordTable): boolean;
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.inSelection : _noTable invalide');

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    q4interruptions.assertRaise( _e_idx >= 0,
      'q4selection.inSelection : etat de selection introuvable');

    Result :=
      ( ty_selectionTables[_e_idx].e_recordCount > 0) and ( ty_selectionTables[_e_idx].e_currentPos >= 1) and ( ty_selectionTables[_e_idx].e_currentPos <= ty_selectionTables[_e_idx].e_recordCount);
  End;

Function beforeSelection( Var _1_p_recordTable): boolean;
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.beforeSelection : _noTable invalide');

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    q4interruptions.assertRaise( _e_idx >= 0,
      'q4selection.beforeSelection : etat de selection introuvable');

    Result := ty_selectionTables[_e_idx].e_currentPos = 0;
  End;

Function endSelection( Var _1_p_recordTable): boolean;
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.endSelection : _noTable invalide');

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    q4interruptions.assertRaise( _e_idx >= 0,
      'q4selection.endSelection : etat de selection introuvable');

    If ( ty_selectionTables[_e_idx].e_recordCount = 0) Then Exit( True);

    Result := ty_selectionTables[_e_idx].e_currentPos = ty_selectionTables[_e_idx].e_recordCount + 1;
  End;

Function selectedRecordNumber( Var _1_p_recordTable): int64;
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
  Begin
    // https://developer.4d.com/docs/commands/selected-record-number

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.selectedRecordNumber : _noTable invalide');

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    q4interruptions.assertRaise( _e_idx >= 0,
      'q4selection.selectedRecordNumber : etat de selection introuvable');

    If ( inSelection( ty_selectionTables[_e_idx])) Then Result := ty_selectionTables[_e_idx].e_currentPos
    Else
      Result := 0;
  End;

Procedure nextRecord( Var _1_p_recordTable);
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
    _e_nextPos: int64;
  Begin
    // https://developer.4d.com/docs/21/commands/next-record

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.nextRecord : _noTable invalide');

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenSelection,
          'q4selection.nextRecord interdit pendant un trigger'
          );

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    q4interruptions.assertRaise( _e_idx >= 0,
      'q4selection.nextRecord : etat de selection introuvable');

    // sélection vide : aucun effet
    If ( ty_selectionTables[_e_idx].e_recordCount = 0) Then Exit;

    // before selection : aucun effet
    If ( ty_selectionTables[_e_idx].e_currentPos = 0) Then Exit;

    // end selection : aucun effet
    If ( ty_selectionTables[_e_idx].e_currentPos = ty_selectionTables[_e_idx].e_recordCount + 1) Then Exit;

    _e_nextPos := ty_selectionTables[_e_idx].e_currentPos + 1;

    // on dépasse la sélection : end selection
    If ( _e_nextPos > ty_selectionTables[_e_idx].e_recordCount) Then Begin
      q4RecordLocking.unloadRecord( _1_p_recordTable);
      ty_selectionTables[_e_idx].e_currentPos := ty_selectionTables[_e_idx].e_recordCount + 1;
      Exit;
    End;

    // sinon, on passe au suivant dans la sélection
    gotoSelectedRecord( _1_p_recordTable, _e_nextPos);
  End;

Procedure firstRecord( Var _1_p_recordTable);
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
  Begin
    // https://developer.4d.com/docs/commands/first-record

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.firstRecord : _noTable invalide');

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenSelection,
          'q4selection.firstRecord interdit pendant un trigger'
          );

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    q4interruptions.assertRaise( _e_idx >= 0,
      'q4selection.firstRecord : etat de selection introuvable');

    If ( ty_selectionTables[_e_idx].e_recordCount = 0) Then Exit;

    If ( ty_selectionTables[_e_idx].e_currentPos = 1) Then Exit;

    gotoSelectedRecord( _1_p_recordTable, 1);
  End;

Procedure lastRecord( Var _1_p_recordTable);
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
    _e_lastPos: int64;
  Begin
    // https://developer.4d.com/docs/commands/last-record

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.lastRecord : _noTable invalide');

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenSelection,
          'q4selection.lastRecord interdit pendant un trigger'
          );

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    q4interruptions.assertRaise( _e_idx >= 0,
      'q4selection.lastRecord : etat de selection introuvable');

    If ( ty_selectionTables[_e_idx].e_recordCount = 0) Then Exit;

    _e_lastPos := ty_selectionTables[_e_idx].e_recordCount;

    If ( ty_selectionTables[_e_idx].e_currentPos = _e_lastPos) Then Exit;

    gotoSelectedRecord( _1_p_recordTable, _e_lastPos);
  End;

Procedure previousRecord( Var _1_p_recordTable);
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
    _e_prevPos: int64;
  Begin
    // https://developer.4d.com/docs/commands/previous-record

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.previousRecord : _noTable invalide');

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenSelection,
          'q4selection.previousRecord interdit pendant un trigger'
          );

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    q4interruptions.assertRaise( _e_idx >= 0,
      'q4selection.previousRecord : etat de selection introuvable');

    // sélection vide : aucun effet
    If ( ty_selectionTables[_e_idx].e_recordCount = 0) Then Exit;

    // before selection : aucun effet
    If ( ty_selectionTables[_e_idx].e_currentPos = 0) Then Exit;

    // end selection : aucun effet
    If ( ty_selectionTables[_e_idx].e_currentPos = ty_selectionTables[_e_idx].e_recordCount + 1) Then Exit;

    _e_prevPos := ty_selectionTables[_e_idx].e_currentPos - 1;

    // on passe avant la sélection
    If ( _e_prevPos < 1) Then Begin
      q4RecordLocking.unloadRecord( _1_p_recordTable);
      ty_selectionTables[_e_idx].e_currentPos := 0;
      Exit;
    End;

    // sinon, on passe au précédent dans la sélection
    gotoSelectedRecord( _1_p_recordTable, _e_prevPos);
  End;

Function selectedRecordNumberOrZero( Var _1_p_recordTable): int64;
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( _p_runtime^._noTable < 0) Then Exit( 0);

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    If ( _e_idx < 0) Then Exit( 0);

    If ( ( ty_selectionTables[_e_idx].e_recordCount > 0) and ( ty_selectionTables[_e_idx].e_currentPos >= 1) and ( ty_selectionTables[_e_idx].e_currentPos <= ty_selectionTables[_e_idx].e_recordCount))
    Then Result := ty_selectionTables[_e_idx].e_currentPos
    Else
      Result := 0;
  End;

Procedure InternalSetCurrentRecordState( Const _1_p_runtime: Pq4recordRuntime; Const _2_e_rowId: int64);
  Begin
    clearArraySQL( _1_p_runtime^._ArraySQL);
    q4record.copyArraySQLToBindings( _1_p_runtime^._Bindings, _1_p_runtime^._ArraySQL);

    _1_p_runtime^._Loaded := False;
    _1_p_runtime^._Modified := False;
    _1_p_runtime^._ReadWrite := False;
    _1_p_runtime^._RowId := _2_e_rowId;
  End;

Procedure reduceSelection( Var _1_p_recordTable; Const _2_e_number: int64);
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
    _o_query:   TSQLQuery;
    _t_sql:     string;
  Begin
    // https://developer.4d.com/docs/commands/reduce-selection

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.reduceSelection : _noTable invalide');

    q4interruptions.assertRaise( _2_e_number >= 0,
      'q4selection.reduceSelection : nombre negatif');

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenSelection,
          'q4selection.reduceSelection interdit pendant un trigger'
          );

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    q4interruptions.assertRaise( _e_idx >= 0,
      'q4selection.reduceSelection : etat de selection introuvable');

    If ( ty_selectionTables[_e_idx].e_buildState <> sbsMaterialized) Then Exit;

    // REDUCE SELECTION(...;0) : vide explicitement la sélection
    If ( _2_e_number = 0) Then Begin
      q4RecordLocking.unloadRecord( _1_p_recordTable);

      _o_query := TSQLQuery.Create( nil);
      Try
        _o_query.DataBase := InternalConnection;
        _o_query.Transaction := InternalTransaction;

        _t_sql :=
          'DELETE FROM ' + ty_selectionTables[_e_idx].t_tempTableName + ' ' + 'WHERE noResultat = :noResultat';

        _o_query.SQL.Text := _t_sql;
        _o_query.ParamByName( 'noResultat').AsLargeInt :=
          ty_selectionTables[_e_idx].e_currentResultNo;
        _o_query.ExecSQL;
      Finally
        _o_query.Free;
      End;

      ty_selectionTables[_e_idx].e_recordCount := 0;
      ty_selectionTables[_e_idx].e_currentPos := 0;
      ty_selectionTables[_e_idx].b_isEmpty := True;
      ty_selectionTables[_e_idx].e_buildState := sbsMaterialized;
      Exit;
    End;

    // si déjà vide, rien à faire
    If ( ty_selectionTables[_e_idx].e_recordCount = 0) Then Exit;

    // si on demande plus ou autant que la taille courante, rien à faire
    If ( _2_e_number >= ty_selectionTables[_e_idx].e_recordCount) Then Exit;

    // réduction en place : on garde seulement les e_number premiers
    q4selectionTablesCore.trimSelectionResultAfterPos(
      ty_selectionTables[_e_idx].t_tempTableName,
      ty_selectionTables[_e_idx].e_currentResultNo,
      _2_e_number
      );

    ty_selectionTables[_e_idx].e_recordCount := _2_e_number;
    ty_selectionTables[_e_idx].b_isEmpty := False;
    ty_selectionTables[_e_idx].e_buildState := sbsMaterialized;

    // le premier record de la nouvelle sélection devient record courant
    // on force le repositionnement même si l'ancienne position valait déjà 1
    ty_selectionTables[_e_idx].e_currentPos := 0;
    gotoSelectedRecord( _1_p_recordTable, 1);
  End;

Function addSelectionTableState( Const _1_e_sourceTableId: int64): int64;
  Var
    _e_idx: int64;
  Begin
    _e_idx := 0;
    _e_idx := Length( ty_selectionTables);
    _e_idx := _e_idx + 1;

    SetLength( ty_selectionTables, Length( ty_selectionTables) + 1);
    //ty_selectionTables[High(ty_selectionTables)].e_sourceTableId := 12345;
    //ShowMessage(IntToStr(Length(ty_selectionTables)));
    //ShowMessage(IntToStr(ty_selectionTables[0].e_sourceTableId));

    ////SetLength(ty_selectionTables, Length(ty_selectionTables) + 1);
    // // SetLength(ty_selectionTables, e_idx);

    _e_idx := High( ty_selectionTables);

    ty_selectionTables[_e_idx].e_sourceTableId := _1_e_sourceTableId;
    ty_selectionTables[_e_idx].t_sourceTableName := '';
    ty_selectionTables[_e_idx].t_tempTableName := '';
    ty_selectionTables[_e_idx].t_pkFieldName := '';
    ty_selectionTables[_e_idx].t_pkTypeSQL := '';
    ty_selectionTables[_e_idx].b_isCreated := False;
    ty_selectionTables[_e_idx].e_currentResultNo := 0;
    ty_selectionTables[_e_idx].e_nextResultNo := 1;
    ty_selectionTables[_e_idx].e_currentPos := 0;
    ty_selectionTables[_e_idx].e_recordCount := 0;
    ty_selectionTables[_e_idx].b_isEmpty := True;
    ty_selectionTables[_e_idx].e_buildState := sbsNone;

    Result := _e_idx;
  End;

Function getOrCreateSelectionTableStateIndex( Const _1_e_sourceTableId: int64): int64;
  Begin
    Result := findSelectionTableStateIndex( _1_e_sourceTableId);

    If ( Result < 0) Then Result := addSelectionTableState( _1_e_sourceTableId);
  End;

Function findTableMetaIndexBySourceTableId( Const _1_e_sourceTableId: int64): int64;
  Var
    _e_i: int64;
  Begin
    Result := -1;

    For _e_i := Low( Tables) To High( Tables) Do If ( Tables[_e_i].SourceTableId = _1_e_sourceTableId) Then Begin
        Result := _e_i;
        Exit;
      End;
  End;

Function findPrimaryKeyFieldMetaIndex( Const _1_e_tableIndex: int64): int64;
  Var
    _e_i:     int64;
    _e_first: int64;
    _e_last:  int64;
    _t_primaryKey: string;
  Begin
    Result := -1;

    q4interruptions.assertRaise( ( _1_e_tableIndex >= Low( Tables)) and ( _1_e_tableIndex <= High( Tables)),
      'findPrimaryKeyFieldMetaIndex : index table invalide');

    _t_primaryKey := Tables[_1_e_tableIndex].PrimaryKey;
    q4interruptions.assertRaise( _t_primaryKey <> '',
      'findPrimaryKeyFieldMetaIndex : PrimaryKey vide');

    _e_first := Tables[_1_e_tableIndex].FieldIndex;
    _e_last := _e_first + Tables[_1_e_tableIndex].FieldCount - 1;

    For _e_i := _e_first To _e_last Do If ( CompareText( Fields[_e_i].Name, _t_primaryKey) = 0) Then Begin
        Result := _e_i;
        Exit;
      End;
  End;

Procedure resolveSelectionTableMeta( Var _1_y_state: Ty_selectionTableState);
  Var
    _e_tableIdx:   int64;
    _e_pkFieldIdx: int64;
  Begin
    _e_tableIdx := findTableMetaIndexBySourceTableId( _1_y_state.e_sourceTableId);
    q4interruptions.assertRaise( _e_tableIdx >= 0,
      'resolveSelectionTableMeta : table introuvable');

    _1_y_state.t_sourceTableName := Tables[_e_tableIdx].Name;
    q4interruptions.assertRaise( _1_y_state.t_sourceTableName <> '',
      'resolveSelectionTableMeta : nom de table vide');

    _1_y_state.t_tempTableName := q4selectionTablesCore.buildSelectionTableName( qstsThread, _1_y_state.t_sourceTableName);

    _e_pkFieldIdx := findPrimaryKeyFieldMetaIndex( _e_tableIdx);
    q4interruptions.assertRaise( _e_pkFieldIdx >= 0,
      'resolveSelectionTableMeta : champ PrimaryKey introuvable');

    _1_y_state.t_pkFieldName := Fields[_e_pkFieldIdx].Name;
    _1_y_state.t_pkTypeSQL := Fields[_e_pkFieldIdx].TypeSQL;

    q4interruptions.assertRaise( _1_y_state.t_pkFieldName <> '',
      'resolveSelectionTableMeta : nom du champ PK vide');

    q4interruptions.assertRaise( _1_y_state.t_pkTypeSQL <> '',
      'resolveSelectionTableMeta : type SQL du champ PK vide');
  End;

Procedure ensureTempTable( Var _1_y_state: Ty_selectionTableState);
  Begin
    q4selectionTablesCore.ensureSelectionTable(
      qstsThread,
      _1_y_state.t_tempTableName,
      _1_y_state.t_pkFieldName,
      _1_y_state.t_pkTypeSQL
      );
    _1_y_state.b_isCreated := True;
  End;

Procedure clearCurrentSelectionResult( Var _1_y_state: Ty_selectionTableState);
  Begin
    q4interruptions.assertRaise( _1_y_state.t_tempTableName <> '',
      'q4selection.clearCurrentSelectionResult : nom table temp vide');

    q4selectionTablesCore.clearSelectionTable( _1_y_state.t_tempTableName);

    _1_y_state.e_currentResultNo := 0;
    _1_y_state.e_currentPos := 0;
    _1_y_state.e_recordCount := 0;
    _1_y_state.b_isEmpty := True;
    _1_y_state.e_buildState := sbsNone;
  End;

Procedure deleteSelection( Var _1_p_recordTable);
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
  Begin
    // https://developer.4d.com/docs/21/commands/delete-selection

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( q4RecordLocking.readOnlyState( _1_p_recordTable)) Then Exit;

    If ( _p_runtime^._noTable < 0) Then Exit;

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenSelection,
          'q4selection.deleteSelection interdit pendant un trigger'
          );

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    If ( _e_idx < 0) Then Exit;

    If ( ty_selectionTables[_e_idx].e_recordCount = 0) Then Exit;

    firstRecord( _1_p_recordTable);

    While ( not endSelection( _1_p_recordTable)) Do Begin
      q4record.deleteRecord( _1_p_recordTable);
      nextRecord( _1_p_recordTable);
    End;

    clearCurrentSelectionResult( ty_selectionTables[_e_idx]);
    ty_selectionTables[_e_idx].e_currentPos := 0;
    ty_selectionTables[_e_idx].e_recordCount := 0;
    ty_selectionTables[_e_idx].b_isEmpty := True;
    ty_selectionTables[_e_idx].e_buildState := sbsMaterialized;
  End;

Procedure truncateTable( Var _1_p_recordTable);
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
    _o_query:   TSQLQuery;
    _t_sql:     string;
  Begin
    // https://developer.4d.com/docs/21/commands/truncate-table

    //doit renvoyer une erreur si on est en transaction

    OK := 0;

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( _p_runtime^._noTable < 0) Then Exit;

    If ( q4transaction.b_inTransactionQ4) Then q4interruptions.assertRaise( 'truncate is not functionnal in transactions');

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenSelection,
          'q4selection.truncateTable interdit pendant un trigger'
          );

    If ( q4RecordLocking.readOnlyState( _1_p_recordTable)) Then Exit;

    _e_idx := getOrCreateSelectionTableStateIndex( _p_runtime^._noTable);

    If ( ty_selectionTables[_e_idx].t_sourceTableName = '') Then resolveSelectionTableMeta( ty_selectionTables[_e_idx]);

    // Libère un éventuel verrou local avant de tenter la sérialisation TRUNCATE.
    q4RecordLocking.unloadRecord( _1_p_recordTable);

    If ( not q4RecordLocking.beginTruncateTable( _1_p_recordTable)) Then Exit;
    Try
      _o_query := TSQLQuery.Create( nil);
      Try
        _o_query.DataBase := InternalConnection;
        _o_query.Transaction := InternalTransaction;

        _t_sql := 'DELETE FROM ' + ty_selectionTables[_e_idx].t_sourceTableName;
        _o_query.SQL.Text := _t_sql;
        _o_query.ExecSQL;
      Finally
        _o_query.Free;
      End;

      // La sélection courante de la table devient vide après TRUNCATE.
      If ( ty_selectionTables[_e_idx].b_isCreated) Then clearCurrentSelectionResult( ty_selectionTables[_e_idx])
      Else Begin
        ty_selectionTables[_e_idx].e_currentResultNo := 0;
        ty_selectionTables[_e_idx].e_currentPos := 0;
        ty_selectionTables[_e_idx].e_recordCount := 0;
        ty_selectionTables[_e_idx].b_isEmpty := True;
        ty_selectionTables[_e_idx].e_buildState := sbsNone;
      End;

      q4setsAndNamedSelectionsCore.clearAllAliasesForTable(
        ty_selectionTables[_e_idx].e_sourceTableId
        );

      q4coreLanguage.OK := 1;
    Finally
      q4RecordLocking.endTruncateTable( _1_p_recordTable);
    End;
  End;

Procedure materializeAllRecords( Var _1_y_state: Ty_selectionTableState);
  Var
    _e_resultNo: int64;
    _e_pos:      int64;
  Begin
    q4interruptions.assertRaise( _1_y_state.t_sourceTableName <> '',
      'q4selection.materializeAllRecords : nom table source vide');

    q4interruptions.assertRaise( _1_y_state.t_tempTableName <> '',
      'q4selection.materializeAllRecords : nom table temp vide');

    q4interruptions.assertRaise( _1_y_state.t_pkFieldName <> '',
      'q4selection.materializeAllRecords : nom champ PK vide');

    q4interruptions.assertRaise( _1_y_state.b_isCreated,
      'q4selection.materializeAllRecords : table temp non creee');

    _e_resultNo := _1_y_state.e_nextResultNo;
    _e_pos := q4selectionTablesCore.materializeAllRecordsToSelectionTable( _1_y_state.t_sourceTableName, _1_y_state.t_tempTableName, _1_y_state.t_pkFieldName, _e_resultNo);

    _1_y_state.e_currentResultNo := _e_resultNo;
    Inc( _1_y_state.e_nextResultNo);

    _1_y_state.e_recordCount := _e_pos;
    _1_y_state.b_isEmpty := ( _e_pos = 0);
    _1_y_state.e_currentPos := 0;
    _1_y_state.e_buildState := sbsMaterialized;
  End;

Function InternalResolveCreateSelectionTarget( Var _1_y_state: Ty_selectionTableState; Const _2_t_selectionName: string; out _3_t_targetTableName: string; out _4_e_resultNo: int64): boolean;
  Var
    _e_scope: Tq4selectionTableScope;
  Begin
    Result := False;
    _3_t_targetTableName := '';
    _4_e_resultNo := 0;

    If ( SysUtils.Trim( _2_t_selectionName) = '') Then Begin
      _3_t_targetTableName := _1_y_state.t_tempTableName;
      _4_e_resultNo := _1_y_state.e_nextResultNo;
      Inc( _1_y_state.e_nextResultNo);
      Result := True;
      Exit;
    End;

    _e_scope := q4setsAndNamedSelectionsCore.aliasScope( _2_t_selectionName);
    _3_t_targetTableName := q4selectionTablesCore.buildSelectionTableName( _e_scope, _1_y_state.t_sourceTableName);
    q4selectionTablesCore.ensureSelectionTable(
      _e_scope,
      _3_t_targetTableName,
      _1_y_state.t_pkFieldName,
      _1_y_state.t_pkTypeSQL
      );

    If ( _e_scope = qstsShared) Then _4_e_resultNo := q4setsAndNamedSelectionsCore.allocateSharedResultNo
    Else
      _4_e_resultNo := q4setsAndNamedSelectionsCore.allocateLocalResultNo( _1_y_state.e_nextResultNo);

    Result := True;
  End;

Function InternalInsertSelectionFromRowIds( Const _1_t_sourceTableName: string; Const _2_t_pkFieldName: string; Const _3_t_targetTableName: string;
  Const _4_e_resultNo: int64; Const _5_te_recordNumbers: Tq4Int64Array): int64;
  Var
    _o_readQuery: TSQLQuery;
    _o_writeQuery: TSQLQuery;
    _t_readSql: string;
    _t_writeSql: string;
    _e_i:     int64;
    _e_pos:   int64;
    _e_rowId: int64;
  Begin
    Result := 0;

    _o_readQuery := TSQLQuery.Create( nil);
    _o_writeQuery := TSQLQuery.Create( nil);
    Try
      _o_readQuery.DataBase := InternalConnection;
      _o_readQuery.Transaction := InternalTransaction;
      _t_readSql :=
        'SELECT ' + _2_t_pkFieldName + ' ' + 'FROM ' + _1_t_sourceTableName + ' ' + 'WHERE rowid = :rowid';
      _o_readQuery.SQL.Text := _t_readSql;
      _o_readQuery.Prepare;

      _o_writeQuery.DataBase := InternalConnection;
      _o_writeQuery.Transaction := InternalTransaction;
      _t_writeSql :=
        'INSERT INTO ' + _3_t_targetTableName + ' (' + _2_t_pkFieldName + ', pos, noResultat) ' + 'VALUES (:pk, :pos, :noResultat)';
      _o_writeQuery.SQL.Text := _t_writeSql;
      _o_writeQuery.Prepare;

      _e_pos := 0;
      For _e_i := Low( _5_te_recordNumbers) To High( _5_te_recordNumbers) Do Begin
        _e_rowId := _5_te_recordNumbers[_e_i];
        If ( _e_rowId <= 0) Then Continue;

        _o_readQuery.Close;
        _o_readQuery.ParamByName( 'rowid').AsLargeInt := _e_rowId;
        _o_readQuery.Open;

        q4interruptions.assertRaise( not _o_readQuery.EOF,
          'q4selection.createSelectionFromArray : rowid invalide');

        Inc( _e_pos);
        _o_writeQuery.ParamByName( 'pk').Value := _o_readQuery.Fields[0].Value;
        _o_writeQuery.ParamByName( 'pos').AsLargeInt := _e_pos;
        _o_writeQuery.ParamByName( 'noResultat').AsLargeInt := _4_e_resultNo;
        _o_writeQuery.ExecSQL;
      End;

      Result := _e_pos;
    Finally
      _o_writeQuery.Free;
      _o_readQuery.Free;
    End;
  End;

Procedure InternalFinalizeCurrentSelectionFromCreatedResult( Var _1_p_recordTable; Var _2_y_state: Ty_selectionTableState; Const _3_e_oldResultNo: int64;
  Const _4_e_newResultNo: int64; Const _5_e_count: int64);
  Begin
    If ( _3_e_oldResultNo > 0) Then q4selectionTablesCore.clearSelectionResultNo(
        _2_y_state.t_tempTableName,
        _3_e_oldResultNo
        );

    _2_y_state.e_currentResultNo := _4_e_newResultNo;
    _2_y_state.e_recordCount := _5_e_count;
    _2_y_state.b_isEmpty := ( _5_e_count = 0);
    _2_y_state.e_currentPos := 0;
    _2_y_state.e_buildState := sbsMaterialized;

    q4RecordLocking.unloadRecord( _1_p_recordTable);
  End;

Procedure createSelectionFromArray( Var _1_p_recordTable; Const _2_te_recordNumbers: Tq4Int64Array; Const _3_t_selectionName: string); overload;
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
    _e_oldResultNo: int64;
    _e_newResultNo: int64;
    _t_targetTableName: string;
    _e_count:   int64;
  Begin
    // https://developer.4d.com/docs/21/commands/create-selection-from-array
    // q4 specific: only integer rowid arrays are supported. Boolean arrays are intentionally unsupported.

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( _p_runtime^._noTable < 0) Then Exit;

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenSelection,
          'q4selection.createSelectionFromArray interdit pendant un trigger'
          );

    _e_idx := getOrCreateSelectionTableStateIndex( _p_runtime^._noTable);
    If ( ty_selectionTables[_e_idx].t_sourceTableName = '') Then resolveSelectionTableMeta( ty_selectionTables[_e_idx]);
    ensureTempTable( ty_selectionTables[_e_idx]);

    q4interruptions.assertRaise(
      InternalResolveCreateSelectionTarget( ty_selectionTables[_e_idx], _3_t_selectionName, _t_targetTableName, _e_newResultNo),
      'q4selection.createSelectionFromArray : destination introuvable'
      );

    _e_count := InternalInsertSelectionFromRowIds( ty_selectionTables[_e_idx].t_sourceTableName, ty_selectionTables[_e_idx].t_pkFieldName, _t_targetTableName, _e_newResultNo, _2_te_recordNumbers);

    If ( SysUtils.Trim( _3_t_selectionName) = '') Then Begin
      _e_oldResultNo := ty_selectionTables[_e_idx].e_currentResultNo;
      InternalFinalizeCurrentSelectionFromCreatedResult( _1_p_recordTable, ty_selectionTables[_e_idx], _e_oldResultNo, _e_newResultNo, _e_count);
    End Else
      q4setsAndNamedSelectionsCore.saveSelectionAlias(
        ty_selectionTables[_e_idx].e_sourceTableId,
        ty_selectionTables[_e_idx].t_sourceTableName,
        q4setsAndNamedSelectionsCore.qsakNamedSelection,
        _3_t_selectionName,
        _e_newResultNo
        );
  End;

Procedure createSelectionFromArray( Var _1_p_recordTable; Const _2_te_recordNumbers: Tq4Int64Array); overload;
  Begin
    createSelectionFromArray( _1_p_recordTable, _2_te_recordNumbers, '');
  End;

Procedure createSelectionFromPkSelect( Var _1_p_recordTable; Const _2_t_selectPkSql: string); overload;
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
    _e_oldResultNo: int64;
    _e_newResultNo: int64;
    _e_count:   int64;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( _p_runtime^._noTable < 0) Then Exit;

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenSelection,
          'q4selection.createSelectionFromPkSelect interdit pendant un trigger'
          );

    _e_idx := getOrCreateSelectionTableStateIndex( _p_runtime^._noTable);
    If ( ty_selectionTables[_e_idx].t_sourceTableName = '') Then resolveSelectionTableMeta( ty_selectionTables[_e_idx]);
    ensureTempTable( ty_selectionTables[_e_idx]);

    _e_oldResultNo := ty_selectionTables[_e_idx].e_currentResultNo;
    _e_newResultNo := ty_selectionTables[_e_idx].e_nextResultNo;
    System.Inc( ty_selectionTables[_e_idx].e_nextResultNo);

    _e_count := q4selectionTablesCore.materializePkSelectToSelectionTable( _2_t_selectPkSql, ty_selectionTables[_e_idx].t_tempTableName, ty_selectionTables[_e_idx].t_pkFieldName, _e_newResultNo);

    InternalFinalizeCurrentSelectionFromCreatedResult(
      _1_p_recordTable,
      ty_selectionTables[_e_idx],
      _e_oldResultNo,
      _e_newResultNo,
      _e_count
      );
  End;

Function currentSelectionPkSelect( Var _1_p_recordTable; out _2_t_selectPkSql: string): boolean; overload;
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
  Begin
    Result := False;
    _2_t_selectPkSql := '';

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);
    If ( _p_runtime^._noTable < 0) Then Exit;

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    If ( _e_idx < 0) Then Exit;

    If ( ty_selectionTables[_e_idx].t_sourceTableName = '') Then resolveSelectionTableMeta( ty_selectionTables[_e_idx]);

    If ( not ty_selectionTables[_e_idx].b_isCreated) Then Exit;
    If ( ty_selectionTables[_e_idx].e_currentResultNo <= 0) Then Exit;

    _2_t_selectPkSql :=
      'SELECT ' + ty_selectionTables[_e_idx].t_pkFieldName + ' FROM ' + ty_selectionTables[_e_idx].t_tempTableName + ' WHERE noResultat = ' +
      SysUtils.IntToStr( ty_selectionTables[_e_idx].e_currentResultNo);

    Result := True;
  End;

Procedure oneRecordSelect( Var _1_p_recordTable); overload;
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
    _o_readQuery: TSQLQuery;
    _o_writeQuery: TSQLQuery;
    _t_sql:     string;
    _v_pk:      variant;
    _e_resultNo: int64;
  Begin
    // https://developer.4d.com/docs/21/commands/one-record-select

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.oneRecordSelect : _noTable invalide');

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenSelection,
          'q4selection.oneRecordSelect interdit pendant un trigger'
          );

    _e_idx := getOrCreateSelectionTableStateIndex( _p_runtime^._noTable);

    If ( ty_selectionTables[_e_idx].t_sourceTableName = '') Then resolveSelectionTableMeta( ty_selectionTables[_e_idx]);

    If ( not ty_selectionTables[_e_idx].b_isCreated) Then ensureTempTable( ty_selectionTables[_e_idx]);

    Case _p_runtime^._RowId Of
      -1: Exit; // pas de record
      -2: Exit; // record supprimé / introuvable
      -3: Begin
        // createRecord en cours :
        // la sélection devient vide, mais le createRecord reste inchangé
        clearCurrentSelectionResult( ty_selectionTables[_e_idx]);

        ty_selectionTables[_e_idx].e_currentResultNo :=
          ty_selectionTables[_e_idx].e_nextResultNo;
        Inc( ty_selectionTables[_e_idx].e_nextResultNo);

        ty_selectionTables[_e_idx].e_currentPos := 0;
        ty_selectionTables[_e_idx].e_recordCount := 0;
        ty_selectionTables[_e_idx].b_isEmpty := True;
        ty_selectionTables[_e_idx].e_buildState := sbsMaterialized;
        Exit;
      End;
    End;

    If ( not _p_runtime^._Loaded) Then Exit;

    _o_readQuery := TSQLQuery.Create( nil);
    Try
      _o_readQuery.DataBase := InternalConnection;
      _o_readQuery.Transaction := InternalTransaction;

      _t_sql :=
        'SELECT ' + ty_selectionTables[_e_idx].t_pkFieldName + ' ' + 'FROM ' + ty_selectionTables[_e_idx].t_sourceTableName + ' ' + 'WHERE rowid = :rowid';

      _o_readQuery.SQL.Text := _t_sql;
      _o_readQuery.ParamByName( 'rowid').AsLargeInt := _p_runtime^._RowId;
      _o_readQuery.Open;

      // si le record courant n'existe plus réellement, aucun effet
      If ( _o_readQuery.EOF) Then Exit;

      _v_pk := _o_readQuery.Fields[0].Value;
      _o_readQuery.Close;
    Finally
      _o_readQuery.Free;
    End;

    clearCurrentSelectionResult( ty_selectionTables[_e_idx]);

    _e_resultNo := ty_selectionTables[_e_idx].e_nextResultNo;

    _o_writeQuery := TSQLQuery.Create( nil);
    Try
      _o_writeQuery.DataBase := InternalConnection;
      _o_writeQuery.Transaction := InternalTransaction;

      _t_sql :=
        'INSERT INTO ' + ty_selectionTables[_e_idx].t_tempTableName + ' (' + ty_selectionTables[_e_idx].t_pkFieldName + ', pos, noResultat' + ') VALUES (:pk, :pos, :noResultat)';

      _o_writeQuery.SQL.Text := _t_sql;
      _o_writeQuery.Prepare;

      _o_writeQuery.ParamByName( 'pk').Value := _v_pk;
      _o_writeQuery.ParamByName( 'pos').AsLargeInt := 1;
      _o_writeQuery.ParamByName( 'noResultat').AsLargeInt := _e_resultNo;
      _o_writeQuery.ExecSQL;
    Finally
      _o_writeQuery.Free;
    End;

    ty_selectionTables[_e_idx].e_currentResultNo := _e_resultNo;
    Inc( ty_selectionTables[_e_idx].e_nextResultNo);
    ty_selectionTables[_e_idx].e_currentPos := 1;
    ty_selectionTables[_e_idx].e_recordCount := 1;
    ty_selectionTables[_e_idx].b_isEmpty := False;
    ty_selectionTables[_e_idx].e_buildState := sbsMaterialized;
  End;

Procedure gotoSelectedRecord( Var _1_p_recordTable; Const _2_e_selectedRecordNo: int64); overload;
  Var
    _p_runtime:  Pq4recordRuntime;
    _e_idx:      int64;
    _o_query:    TSQLQuery;
    _t_sql:      string;
    _e_rowId:    int64;
    _a_arraySQL: TVariantArray;
  Begin
    // https://developer.4d.com/docs/21/commands/goto-selected-record

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.gotoSelectedRecord : _noTable invalide');

    If ( _2_e_selectedRecordNo = 0) Then Exit;

    _e_idx := findSelectionTableStateIndex( _p_runtime^._noTable);
    q4interruptions.assertRaise( _e_idx >= 0,
      'q4selection.gotoSelectedRecord : etat de selection introuvable');

    If ( ty_selectionTables[_e_idx].e_buildState <> sbsMaterialized) Then Exit;

    If ( ( _2_e_selectedRecordNo < 1) or ( _2_e_selectedRecordNo > ty_selectionTables[_e_idx].e_recordCount)) Then Exit;

    If ( _2_e_selectedRecordNo = ty_selectionTables[_e_idx].e_currentPos) Then Exit;

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;

      _t_sql :=
        'SELECT s.rowid ' + 'FROM ' + ty_selectionTables[_e_idx].t_tempTableName + ' t ' + 'LEFT JOIN ' + ty_selectionTables[_e_idx].t_sourceTableName +
        ' s ' + 'ON s.' + ty_selectionTables[_e_idx].t_pkFieldName + ' = t.' + ty_selectionTables[_e_idx].t_pkFieldName + ' ' + 'WHERE t.noResultat = :noResultat ' + 'AND t.pos = :pos';

      _o_query.SQL.Text := _t_sql;
      _o_query.ParamByName( 'noResultat').AsLargeInt :=
        ty_selectionTables[_e_idx].e_currentResultNo;
      _o_query.ParamByName( 'pos').AsLargeInt := _2_e_selectedRecordNo;
      _o_query.Open;

      // position introuvable dans la table temporaire : on ne fait rien
      If ( _o_query.EOF) Then Exit;

      // à partir d'ici, on change réellement de position
      q4RecordLocking.unloadRecord( _1_p_recordTable);

      // record supprimé dans la table principale, mais position valide
      If ( _o_query.Fields[0].IsNull) Then Begin
        _p_runtime^._RowId := -2;
        _p_runtime^._Loaded := False;
        _p_runtime^._Modified := False;
        SetLength( _p_runtime^._ArraySQL, 0);

        ty_selectionTables[_e_idx].e_currentPos := _2_e_selectedRecordNo;
        Exit;
      End;

      _e_rowId := _o_query.Fields[0].AsLargeInt;
      _o_query.Close;
    Finally
      _o_query.Free;
    End;

    // le record a pu être supprimé entre la lecture du rowid et le rechargement
    If ( not q4record.selectRecordToArraySQL( _p_runtime^._noTable, _e_rowId, _a_arraySQL)) Then Begin
      _p_runtime^._RowId := -2;
      _p_runtime^._Loaded := False;
      _p_runtime^._Modified := False;
      SetLength( _p_runtime^._ArraySQL, 0);

      ty_selectionTables[_e_idx].e_currentPos := _2_e_selectedRecordNo;
      Exit;
    End;

    _p_runtime^._ArraySQL := _a_arraySQL;
    _p_runtime^._RowId := _e_rowId;

    q4RecordLocking.loadRecord( _1_p_recordTable);

    ty_selectionTables[_e_idx].e_currentPos := _2_e_selectedRecordNo;
  End;

Procedure allRecords( Var _1_p_recordTable); overload;
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.allRecords : _noTable invalide');

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenSelection,
          'q4selection.allRecord interdit pendant un trigger'
          );

    q4RecordLocking.unloadRecord( _1_p_recordTable);


    //if Length(ty_selectionTables) = 0 then SetLength(ty_selectionTables, 1);

    _e_idx := getOrCreateSelectionTableStateIndex( _p_runtime^._noTable);

    If ( ty_selectionTables[_e_idx].t_sourceTableName = '') Then resolveSelectionTableMeta( ty_selectionTables[_e_idx]);

    If ( not ty_selectionTables[_e_idx].b_isCreated) Then ensureTempTable( ty_selectionTables[_e_idx]);

    clearCurrentSelectionResult( ty_selectionTables[_e_idx]);
    materializeAllRecords( ty_selectionTables[_e_idx]);

    If ( not ty_selectionTables[_e_idx].b_isEmpty) Then gotoSelectedRecord( _1_p_recordTable, 1);
  End;

Procedure allRecords( Var _1_p_recordTable; Const _2_t_flag: string); overload;
  Var
    _p_runtime: Pq4recordRuntime;
    _e_idx:     int64;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    q4interruptions.assertRaise( _2_t_flag = '*',
      'q4selection.allRecords : flag non géré');

    q4interruptions.assertRaise( _p_runtime^._noTable >= 0,
      'q4selection.allRecords(*) : _noTable invalide');

    q4RecordLocking.unloadRecord( _1_p_recordTable);

    _e_idx := getOrCreateSelectionTableStateIndex( _p_runtime^._noTable);

    If ( ty_selectionTables[_e_idx].t_sourceTableName = '') Then resolveSelectionTableMeta( ty_selectionTables[_e_idx]);

    If ( not ty_selectionTables[_e_idx].b_isCreated) Then ensureTempTable( ty_selectionTables[_e_idx]);

    ty_selectionTables[_e_idx].e_buildState := sbsPendingAllRecordsOrder;
  End;

Initialization
  y_sharedSelectionStore.b_isInitialized := False;
  y_sharedSelectionStore.t_registryTableName := '';
  y_sharedSelectionStore.t_itemsTableName := '';

End.
