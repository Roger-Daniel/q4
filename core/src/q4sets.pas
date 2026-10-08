Unit q4sets;

{$mode objfpc}{$H+}

{
q4sets
version du 2026/04/18-14:10

Mapping 4D
Command Number 4D,    4D Command,                       q4 API,                           Statut
  ------------------------------------------------------------------------------------------------
119,                 ADD TO SET,                       addToSet,                         Partial,
117,                 CLEAR SET,                        clearSet,                         Partial,
600,                 COPY SET,                         copySet,                          Partial,
140,                 CREATE EMPTY SET,                 createEmptySet,                   Partial,
116,                 CREATE SET,                       createSet,                        Partial,
641,                 CREATE SET FROM ARRAY,            createSetFromArray,               Partial,
122,                 DIFFERENCE,                       differenceSet,                    Partial,
121,                 INTERSECTION,                     intersectionSet,                  Partial,
195,                 RECORDS IN SET,                   recordsInSet,                     Partial,
561,                 REMOVE FROM SET,                  removeFromSet,                    Partial,
120,                 UNION,                            unionSet,                         Partial,
118,                 USE SET,                          useSet,                           Partial,

Doc: https://developer.4d.com/docs/21/commands/theme/Sets
}

Interface

Uses
  q4setsAndNamedSelectionsCore,
  q4selection;

Type
  Tq4SetUseMode = q4setsAndNamedSelectionsCore.Tq4selectionUseMode;

Procedure clearSet( Var _1_p_recordTable; Const _2_t_name: string);
Procedure createEmptySet( Var _1_p_recordTable; Const _2_t_name: string);
Procedure createSet( Var _1_p_recordTable; Const _2_t_name: string);
Procedure copySet( Var _1_p_recordTable; Const _2_t_sourceName: string; Const _3_t_destName: string);
Procedure useSet( Var _1_p_recordTable; Const _2_t_name: string; Const _3_e_mode: Tq4SetUseMode);
Function recordsInSet( Var _1_p_recordTable; Const _2_t_name: string): int64;
Procedure unionSet( Var _1_p_recordTable; Const _2_t_leftName: string; Const _3_t_rightName: string; Const _4_t_destName: string);
Procedure intersectionSet( Var _1_p_recordTable; Const _2_t_leftName: string; Const _3_t_rightName: string; Const _4_t_destName: string);
Procedure differenceSet( Var _1_p_recordTable; Const _2_t_leftName: string; Const _3_t_rightName: string; Const _4_t_destName: string);
Procedure addToSet( Var _1_p_recordTable; Const _2_t_name: string);
Procedure removeFromSet( Var _1_p_recordTable; Const _2_t_name: string);

//procedure createSetFromArray(var ARecordTable; const ARecordNumbers: q4selection.Tq4LongintArray); overload;
//procedure createSetFromArray(var ARecordTable; const ARecordNumbers: q4selection.Tq4LongintArray; const t_name: string); overload;
Procedure createSetFromArray( Var _1_p_recordTable; Const _2_y_recordNumbers: q4selection.Tq4Int64Array); overload;
Procedure createSetFromArray( Var _1_p_recordTable; Const _2_y_recordNumbers: q4selection.Tq4Int64Array; Const _3_t_name: string); overload;

Function hasLiveSets: boolean;

Implementation

Uses
  SysUtils,
  LazUTF8,
  SQLDB,
  //q4selection,
  q4DBmanager,
  metier_q4DBschemaBase,
  q4DBschemaUse,
  q4selectionTablesCore,
  q4interruptions;

Function hasLiveSets: boolean;
  Var
    _e_i: int64;
  Begin
    Result := False;

    For _e_i := 0 To High( q4setsAndNamedSelectionsCore.ty_localSelectionAliases) Do If ( q4setsAndNamedSelectionsCore.ty_localSelectionAliases[_e_i].e_kind = qsakSet) Then Exit( True);
  End;

Function InternalFindSelectionTableStateIndex( Const _1_e_sourceTableId: int64): int64;
  Var
    _e_i: int64;
  Begin
    Result := -1;
    For _e_i := 0 To System.High( q4selection.ty_selectionTables) Do If ( q4selection.ty_selectionTables[_e_i].e_sourceTableId = _1_e_sourceTableId) Then Begin
        Result := _e_i;
        Exit;
      End;
  End;

Function InternalFindTableMetaIndexBySourceTableId( Const _1_e_sourceTableId: int64): int64;
  Var
    _e_i: int64;
  Begin
    Result := -1;
    For _e_i := 0 To System.High( Tables) Do If ( Tables[_e_i].SourceTableId = _1_e_sourceTableId) Then Begin
        Result := _e_i;
        Exit;
      End;
  End;

Procedure InternalResolveSelectionTableMeta( Var _1_y_state: q4selection.Ty_selectionTableState);
  Var
    _e_tableIdx: int64;
    _e_first: int64;
    _e_last: int64;
    _e_i: int64;
  Begin
    _e_tableIdx := InternalFindTableMetaIndexBySourceTableId( _1_y_state.e_sourceTableId);
    q4interruptions.assertRaise( _e_tableIdx >= 0,
      'q4sets : table source introuvable');

    _1_y_state.t_sourceTableName := Tables[_e_tableIdx].Name;
    _1_y_state.t_tempTableName := q4selectionTablesCore.buildSelectionTableName( qstsThread, _1_y_state.t_sourceTableName);

    _e_first := Tables[_e_tableIdx].FieldIndex;
    _e_last := _e_first + Tables[_e_tableIdx].FieldCount - 1;
    _1_y_state.t_pkFieldName := '';
    _1_y_state.t_pkTypeSQL := '';

    For _e_i := _e_first To _e_last Do If ( SysUtils.CompareText( Fields[_e_i].Name, Tables[_e_tableIdx].PrimaryKey) = 0) Then Begin
        _1_y_state.t_pkFieldName := Fields[_e_i].Name;
        _1_y_state.t_pkTypeSQL := Fields[_e_i].TypeSQL;
        Break;
      End;

    q4interruptions.assertRaise( _1_y_state.t_pkFieldName <> '',
      'q4sets : champ PK introuvable');
    q4interruptions.assertRaise( _1_y_state.t_pkTypeSQL <> '',
      'q4sets : type SQL PK introuvable');
  End;

Procedure InternalEnsureSelectionState( Var _1_p_recordTable; out _2_e_idx: int64);
  Var
    _e_sourceTableId: int64;
  Begin
    _e_sourceTableId := q4DBschemaUse.getSourceTableId( _1_p_recordTable);
    q4interruptions.assertRaise( _e_sourceTableId >= 0,
      'q4sets : _noTable invalide');

    _2_e_idx := InternalFindSelectionTableStateIndex( _e_sourceTableId);
    If ( _2_e_idx < 0) Then Begin
      SetLength( q4selection.ty_selectionTables, System.Length( q4selection.ty_selectionTables) + 1);
      _2_e_idx := System.High( q4selection.ty_selectionTables);

      q4selection.ty_selectionTables[_2_e_idx].e_sourceTableId := _e_sourceTableId;
      q4selection.ty_selectionTables[_2_e_idx].t_sourceTableName := '';
      q4selection.ty_selectionTables[_2_e_idx].t_tempTableName := '';
      q4selection.ty_selectionTables[_2_e_idx].t_pkFieldName := '';
      q4selection.ty_selectionTables[_2_e_idx].t_pkTypeSQL := '';
      q4selection.ty_selectionTables[_2_e_idx].b_isCreated := False;
      q4selection.ty_selectionTables[_2_e_idx].e_currentResultNo := 0;
      q4selection.ty_selectionTables[_2_e_idx].e_nextResultNo := 1;
      q4selection.ty_selectionTables[_2_e_idx].e_currentPos := 0;
      q4selection.ty_selectionTables[_2_e_idx].e_recordCount := 0;
      q4selection.ty_selectionTables[_2_e_idx].b_isEmpty := True;
      q4selection.ty_selectionTables[_2_e_idx].e_buildState := sbsNone;
      q4selection.ty_selectionTables[_2_e_idx].t_pendingWhereSQL := '';
      q4selection.ty_selectionTables[_2_e_idx].t_pendingOrderBySQL := '';
      q4selection.ty_selectionTables[_2_e_idx].e_pendingDestinationKind := qdkCurrentSelection;
      q4selection.ty_selectionTables[_2_e_idx].t_pendingDestinationName := '';
      q4selection.ty_selectionTables[_2_e_idx].e_pendingQueryLimit := 0;
      q4selection.ty_selectionTables[_2_e_idx].e_pendingReduceCount := 0;
    End;

    If ( q4selection.ty_selectionTables[_2_e_idx].t_sourceTableName = '') Then InternalResolveSelectionTableMeta( q4selection.ty_selectionTables[_2_e_idx]);

    q4selectionTablesCore.ensureSelectionTable(
      qstsThread,
      q4selection.ty_selectionTables[_2_e_idx].t_tempTableName,
      q4selection.ty_selectionTables[_2_e_idx].t_pkFieldName,
      q4selection.ty_selectionTables[_2_e_idx].t_pkTypeSQL
      );
    q4selection.ty_selectionTables[_2_e_idx].b_isCreated := True;
  End;

Function InternalCurrentSelectedPkValue( Const _1_y_state: q4selection.Ty_selectionTableState; out _2_v_pk: variant): boolean;
  Var
    _o_query: TSQLQuery;
  Begin
    Result := False;
    If ( ( _1_y_state.e_currentResultNo <= 0) or ( _1_y_state.e_currentPos <= 0)) Then Exit;

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;
      _o_query.SQL.Text :=
        'SELECT ' + _1_y_state.t_pkFieldName + ' ' + 'FROM ' + _1_y_state.t_tempTableName + ' ' + 'WHERE noResultat = :noResultat AND pos = :pos';
      _o_query.ParamByName( 'noResultat').AsLargeInt := _1_y_state.e_currentResultNo;
      _o_query.ParamByName( 'pos').AsLargeInt := _1_y_state.e_currentPos;
      _o_query.Open;

      If ( _o_query.EOF) Then Exit;

      _2_v_pk := _o_query.Fields[0].Value;
      Result := True;
    Finally
      _o_query.Free;
    End;
  End;

Function InternalSetTableName( Const _1_t_sourceTableName: string; Const _2_t_name: string): string;
  Begin
    Result := q4selectionTablesCore.buildSelectionTableName( q4setsAndNamedSelectionsCore.aliasScope( _2_t_name), _1_t_sourceTableName);
  End;

Function InternalSetContainsPk( Const _1_t_tableName: string; Const _2_t_pkFieldName: string; Const _3_e_resultNo: int64; Const _4_v_pk: variant): boolean;
  Var
    _o_query: TSQLQuery;
  Begin
    Result := False;
    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;
      _o_query.SQL.Text :=
        'SELECT COUNT(*) FROM ' + _1_t_tableName + ' ' + 'WHERE noResultat = :noResultat AND ' + _2_t_pkFieldName + ' = :pk';
      _o_query.ParamByName( 'noResultat').AsLargeInt := _3_e_resultNo;
      _o_query.ParamByName( 'pk').Value := _4_v_pk;
      _o_query.Open;
      Result := _o_query.Fields[0].AsLargeInt > 0;
    Finally
      _o_query.Free;
    End;
  End;

Function InternalNextPosInResult( Const _1_t_tableName: string; Const _2_e_resultNo: int64): int64;
  Var
    _o_query: TSQLQuery;
  Begin
    Result := 1;
    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;
      _o_query.SQL.Text :=
        'SELECT COALESCE(MAX(pos), 0) + 1 FROM ' + _1_t_tableName + ' WHERE noResultat = :noResultat';
      _o_query.ParamByName( 'noResultat').AsLargeInt := _2_e_resultNo;
      _o_query.Open;
      Result := _o_query.Fields[0].AsLargeInt;
    Finally
      _o_query.Free;
    End;
  End;

Procedure InternalInsertPkIntoResult( Const _1_t_tableName: string; Const _2_t_pkFieldName: string; Const _3_e_resultNo: int64; Const _4_e_pos: int64; Const _5_v_pk: variant);
  Var
    _o_query: TSQLQuery;
  Begin
    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;
      _o_query.SQL.Text :=
        'INSERT INTO ' + _1_t_tableName + ' (' + _2_t_pkFieldName + ', pos, noResultat) ' + 'VALUES (:pk, :pos, :noResultat)';
      _o_query.ParamByName( 'pk').Value := _5_v_pk;
      _o_query.ParamByName( 'pos').AsLargeInt := _4_e_pos;
      _o_query.ParamByName( 'noResultat').AsLargeInt := _3_e_resultNo;
      _o_query.ExecSQL;
    Finally
      _o_query.Free;
    End;
  End;

Procedure InternalDeletePkFromResult( Const _1_t_tableName: string; Const _2_t_pkFieldName: string; Const _3_e_resultNo: int64; Const _4_v_pk: variant);
  Var
    _o_query: TSQLQuery;
  Begin
    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;
      _o_query.SQL.Text :=
        'DELETE FROM ' + _1_t_tableName + ' ' + 'WHERE noResultat = :noResultat AND ' + _2_t_pkFieldName + ' = :pk';
      _o_query.ParamByName( 'noResultat').AsLargeInt := _3_e_resultNo;
      _o_query.ParamByName( 'pk').Value := _4_v_pk;
      _o_query.ExecSQL;
    Finally
      _o_query.Free;
    End;
  End;

Function InternalInsertSetFromRowIds( Const _1_t_sourceTableName: string; Const _2_t_pkFieldName: string; Const _3_t_targetTableName: string;
  Const _4_e_resultNo: int64; Const _5_y_recordNumbers: q4selection.Tq4Int64Array): int64;
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
      For _e_i := Low( _5_y_recordNumbers) To High( _5_y_recordNumbers) Do Begin
        _e_rowId := _5_y_recordNumbers[_e_i];
        If ( _e_rowId <= 0) Then Continue;

        _o_readQuery.Close;
        _o_readQuery.ParamByName( 'rowid').AsLargeInt := _e_rowId;
        _o_readQuery.Open;

        q4interruptions.assertRaise( not _o_readQuery.EOF,
          'q4sets.createSetFromArray : rowid invalide');

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

Procedure createSetFromArray( Var _1_p_recordTable; Const _2_y_recordNumbers: q4selection.Tq4Int64Array; Const _3_t_name: string); overload;
  Var
    _e_idx:      int64;
    _t_setName:  string;
    _e_scope:    Tq4selectionTableScope;
    _t_targetTableName: string;
    _e_resultNo: int64;
  Begin
    // https://developer.4d.com/docs/21/commands/create-set-from-array
    // q4 specific: only integer rowid arrays are supported. Boolean arrays are intentionally unsupported.

    InternalEnsureSelectionState( _1_p_recordTable, _e_idx);

    _t_setName := SysUtils.Trim( _3_t_name);
    If ( _t_setName = '') Then _t_setName := 'Userset';

    _e_scope := q4setsAndNamedSelectionsCore.aliasScope( _t_setName);
    _t_targetTableName := q4selectionTablesCore.buildSelectionTableName( _e_scope, q4selection.ty_selectionTables[_e_idx].t_sourceTableName);

    q4selectionTablesCore.ensureSelectionTable(
      _e_scope,
      _t_targetTableName,
      q4selection.ty_selectionTables[_e_idx].t_pkFieldName,
      q4selection.ty_selectionTables[_e_idx].t_pkTypeSQL
      );

    If ( _e_scope = qstsShared) Then _e_resultNo := q4setsAndNamedSelectionsCore.allocateSharedResultNo
    Else
      _e_resultNo := q4setsAndNamedSelectionsCore.allocateLocalResultNo( q4selection.ty_selectionTables[_e_idx].e_nextResultNo);

    InternalInsertSetFromRowIds(
      q4selection.ty_selectionTables[_e_idx].t_sourceTableName,
      q4selection.ty_selectionTables[_e_idx].t_pkFieldName,
      _t_targetTableName,
      _e_resultNo,
      _2_y_recordNumbers
      );

    q4setsAndNamedSelectionsCore.saveSelectionAlias(
      q4selection.ty_selectionTables[_e_idx].e_sourceTableId,
      q4selection.ty_selectionTables[_e_idx].t_sourceTableName,
      qsakSet,
      _t_setName,
      _e_resultNo
      );
  End;

Procedure createSetFromArray( Var _1_p_recordTable; Const _2_y_recordNumbers: q4selection.Tq4Int64Array); overload;
  Begin
    createSetFromArray( _1_p_recordTable, _2_y_recordNumbers, '');
  End;

//procedure createSetFromArray(var ARecordTable; const ARecordNumbers: q4selection.Tq4LongintArray; const t_name: string); overload;
//var
//  te_rowIds: q4selection.Tq4Int64Array;
//  e_i: Int64;
//begin
//  SetLength(te_rowIds, Length(ARecordNumbers));
//  for e_i := Low(ARecordNumbers) to High(ARecordNumbers) do te_rowIds[e_i] := ARecordNumbers[e_i];
//  createSetFromArray(ARecordTable, te_rowIds, t_name);
//end;

//procedure createSetFromArray(var ARecordTable; const ARecordNumbers: q4selection.Tq4LongintArray); overload;
//begin
//  createSetFromArray(ARecordTable, ARecordNumbers, '');
//end;

Procedure InternalChangeSetMembership( Var _1_p_recordTable; Const _2_t_name: string; Const _3_b_add: boolean);
  Var
    _e_idx: int64;
    _e_resultNo: int64;
    _t_tableName: string;
    _v_pk:  variant;
    _e_pos: int64;
  Begin
    q4interruptions.assertRaise( LazUTF8.UTF8Trim( _2_t_name) <> '',
      'q4sets.InternalChangeSetMembership : nom vide');

    InternalEnsureSelectionState( _1_p_recordTable, _e_idx);

    If ( not InternalCurrentSelectedPkValue( q4selection.ty_selectionTables[_e_idx], _v_pk)) Then Exit;

    q4interruptions.assertRaise(
      q4setsAndNamedSelectionsCore.resolveSelectionAlias( q4selection.ty_selectionTables[_e_idx].e_sourceTableId, q4setsAndNamedSelectionsCore.qsakSet, _2_t_name, _e_resultNo),
      'q4sets.InternalChangeSetMembership : set introuvable'
      );

    _t_tableName := InternalSetTableName( q4selection.ty_selectionTables[_e_idx].t_sourceTableName, _2_t_name);

    If ( _3_b_add) Then Begin
      If ( InternalSetContainsPk( _t_tableName, q4selection.ty_selectionTables[_e_idx].t_pkFieldName, _e_resultNo, _v_pk)) Then Exit;

      _e_pos := InternalNextPosInResult( _t_tableName, _e_resultNo);
      InternalInsertPkIntoResult( _t_tableName, q4selection.ty_selectionTables[_e_idx].t_pkFieldName, _e_resultNo, _e_pos, _v_pk);
    End Else
      InternalDeletePkFromResult( _t_tableName, q4selection.ty_selectionTables[_e_idx].t_pkFieldName, _e_resultNo, _v_pk);
  End;

Procedure clearSet( Var _1_p_recordTable; Const _2_t_name: string);
  Begin
    q4setsAndNamedSelectionsCore.clearAlias( _1_p_recordTable, q4setsAndNamedSelectionsCore.qsakSet, _2_t_name);
  End;

Procedure createEmptySet( Var _1_p_recordTable; Const _2_t_name: string);
  Begin
    q4setsAndNamedSelectionsCore.createEmptyAlias( _1_p_recordTable, q4setsAndNamedSelectionsCore.qsakSet, _2_t_name);
  End;

Procedure createSet( Var _1_p_recordTable; Const _2_t_name: string);
  Begin
    q4setsAndNamedSelectionsCore.copyCurrentSelectionToAlias( _1_p_recordTable, q4setsAndNamedSelectionsCore.qsakSet, _2_t_name);
  End;

Procedure copySet( Var _1_p_recordTable; Const _2_t_sourceName: string; Const _3_t_destName: string);
  Begin
    q4setsAndNamedSelectionsCore.copyAliasToAlias( _1_p_recordTable, q4setsAndNamedSelectionsCore.qsakSet, _2_t_sourceName, _3_t_destName);
  End;

Procedure useSet( Var _1_p_recordTable; Const _2_t_name: string; Const _3_e_mode: Tq4SetUseMode);
  Begin
    q4setsAndNamedSelectionsCore.useAlias( _1_p_recordTable, q4setsAndNamedSelectionsCore.qsakSet, _2_t_name, _3_e_mode);
  End;

Function recordsInSet( Var _1_p_recordTable; Const _2_t_name: string): int64;
  Begin
    Result := q4setsAndNamedSelectionsCore.countAlias( _1_p_recordTable, q4setsAndNamedSelectionsCore.qsakSet, _2_t_name);
  End;

Procedure unionSet( Var _1_p_recordTable; Const _2_t_leftName: string; Const _3_t_rightName: string; Const _4_t_destName: string);
  Begin
    q4setsAndNamedSelectionsCore.combineAliases(
      _1_p_recordTable,
      q4setsAndNamedSelectionsCore.qsakSet,
      _2_t_leftName,
      _3_t_rightName,
      _4_t_destName,
      'UNION',
      'q4sets.unionSet'
      );
  End;

Procedure intersectionSet( Var _1_p_recordTable; Const _2_t_leftName: string; Const _3_t_rightName: string; Const _4_t_destName: string);
  Begin
    q4setsAndNamedSelectionsCore.combineAliases(
      _1_p_recordTable,
      q4setsAndNamedSelectionsCore.qsakSet,
      _2_t_leftName,
      _3_t_rightName,
      _4_t_destName,
      'INTERSECT',
      'q4sets.intersectionSet'
      );
  End;

Procedure differenceSet( Var _1_p_recordTable; Const _2_t_leftName: string; Const _3_t_rightName: string; Const _4_t_destName: string);
  Begin
    q4setsAndNamedSelectionsCore.combineAliases(
      _1_p_recordTable,
      q4setsAndNamedSelectionsCore.qsakSet,
      _2_t_leftName,
      _3_t_rightName,
      _4_t_destName,
      'EXCEPT',
      'q4sets.differenceSet'
      );
  End;

Procedure addToSet( Var _1_p_recordTable; Const _2_t_name: string);
  Begin
    InternalChangeSetMembership( _1_p_recordTable, _2_t_name, True);
  End;

Procedure removeFromSet( Var _1_p_recordTable; Const _2_t_name: string);
  Begin
    InternalChangeSetMembership( _1_p_recordTable, _2_t_name, False);
  End;

End.
