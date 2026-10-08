Unit q4setsAndNamedSelectionsCore;

{$mode objfpc}{$H+}

{
Mapping q4 → q4setsAndNamedSelectionsCore -> statut
q4 service                                  API                               Statut
-------------------------------------------------------------------------------------
set/shared name scope                       isSharedAliasName                 OK
alias scope                                 aliasScope                        OK
alias kind                                  Tq4selectionAliasKind            OK
use mode                                    Tq4selectionUseMode              OK
allocate local resultNo                     allocateLocalResultNo             OK
allocate shared resultNo                    allocateSharedResultNo            OK
save alias                                  saveSelectionAlias               OK
resolve alias                               resolveSelectionAlias            OK
clear alias storage                         clearSelectionAlias              OK
check alias existence                       selectionAliasExists             OK
clear alias + content                       clearAlias                       OK
create empty alias                          createEmptyAlias                 OK
copy current selection -> alias             copyCurrentSelectionToAlias      OK
cut current selection -> alias              cutCurrentSelectionToAlias       OK
copy alias -> alias                         copyAliasToAlias                 OK
use alias -> current selection              useAlias                         OK
count alias rows                            countAlias                       OK
combine aliases                             combineAliases                   OK

Notes
- Le nom est conservé tel quel, y compris le préfixe <>.
- Le préfixe <> détermine uniquement le backend local/shared.
- Un nom (pour un kind donné) ne peut appartenir qu'à une seule table.
- Overwrite systématique d'un alias existant de même table.
}

Interface

Uses
  SysUtils,
  q4selection,
  q4selectionTablesCore;

Type
  Tq4selectionAliasKind = (
    qsakSet,
    qsakNamedSelection
    );

  Tq4selectionUseMode = (
    qsumCopy,
    qsumMove
    );

  Ty_selectionAlias = Record
    e_sourceTableId: int64;
    t_sourceTableName: string;
    t_tableName: string;
    e_kind: Tq4selectionAliasKind;
    t_name: string;
    e_resultNo: int64;
  End;

  Tty_selectionAlias = Array Of Ty_selectionAlias;

Threadvar
  ty_localSelectionAliases: Tty_selectionAlias;

Var
  ty_sharedSelectionAliases: Tty_selectionAlias;
  e_nextSharedResultNo:      int64;

Function isSharedAliasName( Const _1_t_name: string): boolean;
Function aliasScope( Const _1_t_name: string): Tq4selectionTableScope;

Function allocateLocalResultNo( Var _1_e_nextResultNo: int64): int64;
Function allocateSharedResultNo: int64;

Function selectionAliasExists( Const _1_e_sourceTableId: int64; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string): boolean;

Function resolveSelectionAlias( Const _1_e_sourceTableId: int64; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string; out _4_e_resultNo: int64): boolean;

Procedure saveSelectionAlias( Const _1_e_sourceTableId: int64; Const _2_t_sourceTableName: string; Const _3_e_kind: Tq4selectionAliasKind; Const _4_t_name: string; Const _5_e_resultNo: int64);

Procedure clearSelectionAlias( Const _1_e_sourceTableId: int64; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string);

Procedure clearAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string);
Procedure createEmptyAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string);
Procedure copyCurrentSelectionToAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string);
Procedure cutCurrentSelectionToAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string);
Procedure copyAliasToAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_sourceName: string; Const _4_t_destName: string);
Procedure useAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string; Const _4_e_mode: Tq4selectionUseMode);
Function countAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string): int64;
Procedure combineAliases( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_leftName: string; Const _4_t_rightName: string;
  Const _5_t_destName: string; Const _6_t_sqlOperator: string; Const _7_t_errorPrefix: string);

Procedure clearAllAliasesForTable( Const _1_e_sourceTableId: int64);
Procedure clearSharedSelectionAliases;
Procedure clearLocalSelectionAliases;

Implementation

Uses
  LazUTF8,
  SQLDB,
  q4DBmanager,
  metier_q4DBschemaBase,
  q4DBschemaUse,
  q4interruptions,
  q4RecordLocking;

Function isSharedAliasName( Const _1_t_name: string): boolean;
  Begin
    Result := LazUTF8.UTF8Copy( _1_t_name, 1, 2) = '<>';
  End;

Function aliasScope( Const _1_t_name: string): Tq4selectionTableScope;
  Begin
    If ( isSharedAliasName( _1_t_name)) Then Result := qstsShared
    Else
      Result := qstsThread;
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
      'q4setsAndNamedSelectionsCore : table source introuvable');

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
      'q4setsAndNamedSelectionsCore : champ PK introuvable');
    q4interruptions.assertRaise( _1_y_state.t_pkTypeSQL <> '',
      'q4setsAndNamedSelectionsCore : type SQL PK introuvable');
  End;

Procedure InternalEnsureSelectionState( Var _1_p_recordTable; out _2_e_idx: int64);
  Var
    _e_sourceTableId: int64;
  Begin
    _e_sourceTableId := q4DBschemaUse.getSourceTableId( _1_p_recordTable);
    q4interruptions.assertRaise( _e_sourceTableId >= 0,
      'q4setsAndNamedSelectionsCore : _noTable invalide');

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

Function InternalFindAliasIndexInArray( Const _1_ty_aliases: Tty_selectionAlias; Const _2_e_sourceTableId: int64; Const _3_e_kind: Tq4selectionAliasKind; Const _4_t_name: string): int64;
  Var
    _e_i: int64;
  Begin
    Result := -1;
    For _e_i := 0 To System.High( _1_ty_aliases) Do If ( ( _1_ty_aliases[_e_i].e_sourceTableId = _2_e_sourceTableId) and ( _1_ty_aliases[_e_i].e_kind = _3_e_kind) and
        ( _1_ty_aliases[_e_i].t_name = _4_t_name)) Then Begin
        Result := _e_i;
        Exit;
      End;
  End;

Function InternalFindForeignAliasIndexInArray( Const _1_ty_aliases: Tty_selectionAlias; Const _2_e_sourceTableId: int64; Const _3_e_kind: Tq4selectionAliasKind; Const _4_t_name: string): int64;
  Var
    _e_i: int64;
  Begin
    Result := -1;
    For _e_i := 0 To System.High( _1_ty_aliases) Do If ( ( _1_ty_aliases[_e_i].e_kind = _3_e_kind) and ( _1_ty_aliases[_e_i].t_name = _4_t_name) and
        ( _1_ty_aliases[_e_i].e_sourceTableId <> _2_e_sourceTableId)) Then Begin
        Result := _e_i;
        Exit;
      End;
  End;

Procedure InternalDeleteAliasIndex( Var _1_ty_aliases: Tty_selectionAlias; Const _2_e_idx: int64);
  Var
    _e_i: int64;
  Begin
    q4interruptions.assertRaise( ( _2_e_idx >= 0) and ( _2_e_idx <= System.High( _1_ty_aliases)),
      'q4setsAndNamedSelectionsCore.InternalDeleteAliasIndex : index hors limites');
    For _e_i := _2_e_idx To System.High( _1_ty_aliases) - 1 Do _1_ty_aliases[_e_i] := _1_ty_aliases[_e_i + 1];
    SetLength( _1_ty_aliases, System.Length( _1_ty_aliases) - 1);
  End;

Function InternalFindAliasIndex( Const _1_e_sourceTableId: int64; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string): int64;
  Begin
    If ( isSharedAliasName( _3_t_name)) Then Result := InternalFindAliasIndexInArray( ty_sharedSelectionAliases, _1_e_sourceTableId, _2_e_kind, _3_t_name)
    Else
      Result := InternalFindAliasIndexInArray( ty_localSelectionAliases, _1_e_sourceTableId, _2_e_kind, _3_t_name);
  End;

Procedure InternalAssertAliasNameMatchesTable( Const _1_e_sourceTableId: int64; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string);
  Var
    _e_foreignIdx: int64;
  Begin
    If ( isSharedAliasName( _3_t_name)) Then _e_foreignIdx := InternalFindForeignAliasIndexInArray( ty_sharedSelectionAliases, _1_e_sourceTableId, _2_e_kind, _3_t_name)
    Else
      _e_foreignIdx := InternalFindForeignAliasIndexInArray( ty_localSelectionAliases, _1_e_sourceTableId, _2_e_kind, _3_t_name);
    q4interruptions.assertRaise( _e_foreignIdx < 0,
      'q4setsAndNamedSelectionsCore : alias "' + _3_t_name + '" deja associe a une autre table');
  End;

Function InternalAliasTableName( Const _1_t_sourceTableName: string; Const _2_t_name: string): string;
  Begin
    Result := q4selectionTablesCore.buildSelectionTableName( aliasScope( _2_t_name), _1_t_sourceTableName);
  End;

Function InternalCountResultRows( Const _1_t_tableName: string; Const _2_e_resultNo: int64): int64;
  Var
    _o_query: TSQLQuery;
  Begin
    Result := 0;
    If ( _2_e_resultNo <= 0) Then Exit;

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;
      _o_query.SQL.Text := 'SELECT COUNT(*) FROM ' + _1_t_tableName + ' WHERE noResultat = :noResultat';
      _o_query.ParamByName( 'noResultat').AsInteger := _2_e_resultNo;
      _o_query.Open;
      Result := _o_query.Fields[0].AsInteger;
    Finally
      _o_query.Free;
    End;
  End;

Function InternalBuildCurrentSelectionPkSql( Const _1_y_state: q4selection.Ty_selectionTableState): string;
  Begin
    Result :=
      'SELECT ' + _1_y_state.t_pkFieldName + ' AS q4pk ' + 'FROM ' + _1_y_state.t_tempTableName + ' ' + 'WHERE noResultat = ' + SysUtils.IntToStr( _1_y_state.e_currentResultNo) +
      ' ' + 'ORDER BY pos';
  End;

Function InternalBuildAliasPkSql( Const _1_t_tableName: string; Const _2_t_pkFieldName: string; Const _3_e_resultNo: int64): string;
  Begin
    Result :=
      'SELECT ' + _2_t_pkFieldName + ' AS q4pk ' + 'FROM ' + _1_t_tableName + ' ' + 'WHERE noResultat = ' + SysUtils.IntToStr( _3_e_resultNo) + ' ' + 'ORDER BY pos';
  End;

Procedure InternalPositionOnCurrentSelection( Var _1_p_recordTable; Const _2_e_idx: int64);
  Begin
    q4RecordLocking.unloadRecord( _1_p_recordTable);
    If ( q4selection.ty_selectionTables[_2_e_idx].e_recordCount > 0) Then q4selection.gotoSelectedRecord( _1_p_recordTable, 1)
    Else
      q4selection.ty_selectionTables[_2_e_idx].e_currentPos := 0;
  End;

Procedure InternalReplaceCurrentSelectionFromSelect( Var _1_p_recordTable; Const _2_e_idx: int64; Const _3_t_selectPkSql: string);
  Var
    _e_oldResultNo: int64;
    _e_newResultNo: int64;
    _e_count: int64;
  Begin
    _e_oldResultNo := q4selection.ty_selectionTables[_2_e_idx].e_currentResultNo;
    _e_newResultNo := q4selection.ty_selectionTables[_2_e_idx].e_nextResultNo;

    q4selectionTablesCore.materializePkSelectToSelectionTable(
      _3_t_selectPkSql,
      q4selection.ty_selectionTables[_2_e_idx].t_tempTableName,
      q4selection.ty_selectionTables[_2_e_idx].t_pkFieldName,
      _e_newResultNo
      );

    If ( _e_oldResultNo > 0) Then q4selectionTablesCore.clearSelectionResultNo(
        q4selection.ty_selectionTables[_2_e_idx].t_tempTableName,
        _e_oldResultNo
        );

    _e_count := InternalCountResultRows( q4selection.ty_selectionTables[_2_e_idx].t_tempTableName, _e_newResultNo);

    q4selection.ty_selectionTables[_2_e_idx].e_currentResultNo := _e_newResultNo;
    Inc( q4selection.ty_selectionTables[_2_e_idx].e_nextResultNo);
    q4selection.ty_selectionTables[_2_e_idx].e_recordCount := _e_count;
    q4selection.ty_selectionTables[_2_e_idx].b_isEmpty := ( _e_count = 0);
    q4selection.ty_selectionTables[_2_e_idx].e_currentPos := 0;

    InternalPositionOnCurrentSelection( _1_p_recordTable, _2_e_idx);
  End;

Procedure InternalResetCurrentSelectionToEmpty( Var _1_y_state: q4selection.Ty_selectionTableState);
  Var
    _e_newResultNo: int64;
  Begin
    _e_newResultNo := _1_y_state.e_nextResultNo;
    _1_y_state.e_currentResultNo := _e_newResultNo;
    Inc( _1_y_state.e_nextResultNo);
    _1_y_state.e_currentPos := 0;
    _1_y_state.e_recordCount := 0;
    _1_y_state.b_isEmpty := True;
  End;

Procedure InternalMaterializeAliasFromSql( Const _1_e_idx: int64; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_destName: string; Const _4_t_selectPkSql: string);
  Var
    _e_scope:    Tq4selectionTableScope;
    _t_targetTableName: string;
    _e_resultNo: int64;
  Begin
    _e_scope := aliasScope( _3_t_destName);
    _t_targetTableName := InternalAliasTableName( q4selection.ty_selectionTables[_1_e_idx].t_sourceTableName, _3_t_destName);

    q4selectionTablesCore.ensureSelectionTable(
      _e_scope,
      _t_targetTableName,
      q4selection.ty_selectionTables[_1_e_idx].t_pkFieldName,
      q4selection.ty_selectionTables[_1_e_idx].t_pkTypeSQL
      );

    If ( _e_scope = qstsShared) Then _e_resultNo := allocateSharedResultNo
    Else
      _e_resultNo := allocateLocalResultNo( q4selection.ty_selectionTables[_1_e_idx].e_nextResultNo);

    q4selectionTablesCore.materializePkSelectToSelectionTable(
      _4_t_selectPkSql,
      _t_targetTableName,
      q4selection.ty_selectionTables[_1_e_idx].t_pkFieldName,
      _e_resultNo
      );

    saveSelectionAlias(
      q4selection.ty_selectionTables[_1_e_idx].e_sourceTableId,
      q4selection.ty_selectionTables[_1_e_idx].t_sourceTableName,
      _2_e_kind,
      _3_t_destName,
      _e_resultNo
      );
  End;

Function allocateLocalResultNo( Var _1_e_nextResultNo: int64): int64;
  Begin
    q4interruptions.assertRaise( _1_e_nextResultNo > 0,
      'q4setsAndNamedSelectionsCore.allocateLocalResultNo : e_nextResultNo invalide');
    Result := _1_e_nextResultNo;
    Inc( _1_e_nextResultNo);
  End;

Function allocateSharedResultNo: int64;
  Begin
    If ( e_nextSharedResultNo <= 0) Then e_nextSharedResultNo := 1;
    Result := e_nextSharedResultNo;
    Inc( e_nextSharedResultNo);
  End;

Function selectionAliasExists( Const _1_e_sourceTableId: int64; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string): boolean;
  Var
    _e_idx: int64;
  Begin
    InternalAssertAliasNameMatchesTable( _1_e_sourceTableId, _2_e_kind, _3_t_name);
    _e_idx := InternalFindAliasIndex( _1_e_sourceTableId, _2_e_kind, _3_t_name);
    Result := _e_idx >= 0;
  End;

Function resolveSelectionAlias( Const _1_e_sourceTableId: int64; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string; out _4_e_resultNo: int64): boolean;
  Var
    _e_idx: int64;
  Begin
    _4_e_resultNo := 0;
    InternalAssertAliasNameMatchesTable( _1_e_sourceTableId, _2_e_kind, _3_t_name);
    _e_idx := InternalFindAliasIndex( _1_e_sourceTableId, _2_e_kind, _3_t_name);

    If ( _e_idx < 0) Then Begin
      Result := False;
      Exit;
    End;

    If ( isSharedAliasName( _3_t_name)) Then _4_e_resultNo := ty_sharedSelectionAliases[_e_idx].e_resultNo
    Else
      _4_e_resultNo := ty_localSelectionAliases[_e_idx].e_resultNo;
    Result := True;
  End;

Procedure saveSelectionAlias( Const _1_e_sourceTableId: int64; Const _2_t_sourceTableName: string; Const _3_e_kind: Tq4selectionAliasKind; Const _4_t_name: string; Const _5_e_resultNo: int64);
  Var
    _e_idx:   int64;
    _y_alias: Ty_selectionAlias;
  Begin
    q4interruptions.assertRaise( _1_e_sourceTableId >= 0,
      'q4setsAndNamedSelectionsCore.saveSelectionAlias : sourceTableId invalide');
    q4interruptions.assertRaise( SysUtils.Trim( _2_t_sourceTableName) <> '',
      'q4setsAndNamedSelectionsCore.saveSelectionAlias : nom table source vide');
    q4interruptions.assertRaise( SysUtils.Trim( _4_t_name) <> '',
      'q4setsAndNamedSelectionsCore.saveSelectionAlias : nom alias vide');
    q4interruptions.assertRaise( _5_e_resultNo > 0,
      'q4setsAndNamedSelectionsCore.saveSelectionAlias : resultNo invalide');

    InternalAssertAliasNameMatchesTable( _1_e_sourceTableId, _3_e_kind, _4_t_name);
    _e_idx := InternalFindAliasIndex( _1_e_sourceTableId, _3_e_kind, _4_t_name);

    _y_alias.e_sourceTableId := _1_e_sourceTableId;
    _y_alias.t_sourceTableName := _2_t_sourceTableName;
    _y_alias.t_tableName := InternalAliasTableName( _2_t_sourceTableName, _4_t_name);
    _y_alias.e_kind := _3_e_kind;
    _y_alias.t_name := _4_t_name;
    _y_alias.e_resultNo := _5_e_resultNo;

    If ( _e_idx >= 0) Then Begin
      If ( isSharedAliasName( _4_t_name)) Then Begin
        If ( ty_sharedSelectionAliases[_e_idx].e_resultNo <> _5_e_resultNo) Then q4selectionTablesCore.clearSelectionResultNo(
            ty_sharedSelectionAliases[_e_idx].t_tableName,
            ty_sharedSelectionAliases[_e_idx].e_resultNo
            );
        ty_sharedSelectionAliases[_e_idx] := _y_alias;
      End Else Begin
        If ( ty_localSelectionAliases[_e_idx].e_resultNo <> _5_e_resultNo) Then q4selectionTablesCore.clearSelectionResultNo(
            ty_localSelectionAliases[_e_idx].t_tableName,
            ty_localSelectionAliases[_e_idx].e_resultNo
            );
        ty_localSelectionAliases[_e_idx] := _y_alias;
      End;
      Exit;
    End;

    If ( isSharedAliasName( _4_t_name)) Then Begin
      SetLength( ty_sharedSelectionAliases, System.Length( ty_sharedSelectionAliases) + 1);
      ty_sharedSelectionAliases[System.High( ty_sharedSelectionAliases)] := _y_alias;
    End Else Begin
      SetLength( ty_localSelectionAliases, System.Length( ty_localSelectionAliases) + 1);
      ty_localSelectionAliases[System.High( ty_localSelectionAliases)] := _y_alias;
    End;
  End;

Procedure clearSelectionAlias( Const _1_e_sourceTableId: int64; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string);
  Var
    _e_idx: int64;
  Begin
    InternalAssertAliasNameMatchesTable( _1_e_sourceTableId, _2_e_kind, _3_t_name);
    _e_idx := InternalFindAliasIndex( _1_e_sourceTableId, _2_e_kind, _3_t_name);

    If ( _e_idx < 0) Then Exit;

    If ( isSharedAliasName( _3_t_name)) Then Begin
      q4selectionTablesCore.clearSelectionResultNo(
        ty_sharedSelectionAliases[_e_idx].t_tableName,
        ty_sharedSelectionAliases[_e_idx].e_resultNo
        );
      InternalDeleteAliasIndex( ty_sharedSelectionAliases, _e_idx);
    End Else Begin
      q4selectionTablesCore.clearSelectionResultNo(
        ty_localSelectionAliases[_e_idx].t_tableName,
        ty_localSelectionAliases[_e_idx].e_resultNo
        );
      InternalDeleteAliasIndex( ty_localSelectionAliases, _e_idx);
    End;
  End;

Procedure clearAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string);
  Var
    _e_idx: int64;
  Begin
    q4interruptions.assertRaise( LazUTF8.UTF8Trim( _3_t_name) <> '',
      'q4setsAndNamedSelectionsCore.clearAlias : nom vide');
    InternalEnsureSelectionState( _1_p_recordTable, _e_idx);
    clearSelectionAlias( q4selection.ty_selectionTables[_e_idx].e_sourceTableId, _2_e_kind, _3_t_name);
  End;

Procedure createEmptyAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string);
  Var
    _e_idx:      int64;
    _e_scope:    Tq4selectionTableScope;
    _t_targetTableName: string;
    _e_resultNo: int64;
  Begin
    q4interruptions.assertRaise( LazUTF8.UTF8Trim( _3_t_name) <> '',
      'q4setsAndNamedSelectionsCore.createEmptyAlias : nom vide');

    InternalEnsureSelectionState( _1_p_recordTable, _e_idx);
    _e_scope := aliasScope( _3_t_name);
    _t_targetTableName := InternalAliasTableName( q4selection.ty_selectionTables[_e_idx].t_sourceTableName, _3_t_name);

    q4selectionTablesCore.ensureSelectionTable(
      _e_scope,
      _t_targetTableName,
      q4selection.ty_selectionTables[_e_idx].t_pkFieldName,
      q4selection.ty_selectionTables[_e_idx].t_pkTypeSQL
      );

    If ( _e_scope = qstsShared) Then _e_resultNo := allocateSharedResultNo
    Else
      _e_resultNo := allocateLocalResultNo( q4selection.ty_selectionTables[_e_idx].e_nextResultNo);

    saveSelectionAlias(
      q4selection.ty_selectionTables[_e_idx].e_sourceTableId,
      q4selection.ty_selectionTables[_e_idx].t_sourceTableName,
      _2_e_kind,
      _3_t_name,
      _e_resultNo
      );
  End;

Procedure copyCurrentSelectionToAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string);
  Var
    _e_idx: int64;
  Begin
    q4interruptions.assertRaise( LazUTF8.UTF8Trim( _3_t_name) <> '',
      'q4setsAndNamedSelectionsCore.copyCurrentSelectionToAlias : nom vide');
    InternalEnsureSelectionState( _1_p_recordTable, _e_idx);
    InternalMaterializeAliasFromSql( _e_idx, _2_e_kind, _3_t_name, InternalBuildCurrentSelectionPkSql( q4selection.ty_selectionTables[_e_idx]));
  End;

Procedure cutCurrentSelectionToAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string);
  Var
    _e_idx:      int64;
    _e_scope:    Tq4selectionTableScope;
    _e_resultNo: int64;
  Begin
    q4interruptions.assertRaise( LazUTF8.UTF8Trim( _3_t_name) <> '',
      'q4setsAndNamedSelectionsCore.cutCurrentSelectionToAlias : nom vide');
    InternalEnsureSelectionState( _1_p_recordTable, _e_idx);
    _e_scope := aliasScope( _3_t_name);

    If ( _e_scope = qstsThread) Then Begin
      _e_resultNo := q4selection.ty_selectionTables[_e_idx].e_currentResultNo;
      If ( _e_resultNo = 0) Then Begin
        _e_resultNo := q4selection.ty_selectionTables[_e_idx].e_nextResultNo;
        Inc( q4selection.ty_selectionTables[_e_idx].e_nextResultNo);
      End;

      saveSelectionAlias(
        q4selection.ty_selectionTables[_e_idx].e_sourceTableId,
        q4selection.ty_selectionTables[_e_idx].t_sourceTableName,
        _2_e_kind,
        _3_t_name,
        _e_resultNo
        );

      InternalResetCurrentSelectionToEmpty( q4selection.ty_selectionTables[_e_idx]);
      q4RecordLocking.unloadRecord( _1_p_recordTable);
      Exit;
    End;

    InternalMaterializeAliasFromSql( _e_idx, _2_e_kind, _3_t_name, InternalBuildCurrentSelectionPkSql( q4selection.ty_selectionTables[_e_idx]));

    If ( q4selection.ty_selectionTables[_e_idx].e_currentResultNo > 0) Then q4selectionTablesCore.clearSelectionResultNo(
        q4selection.ty_selectionTables[_e_idx].t_tempTableName,
        q4selection.ty_selectionTables[_e_idx].e_currentResultNo
        );

    InternalResetCurrentSelectionToEmpty( q4selection.ty_selectionTables[_e_idx]);
    q4RecordLocking.unloadRecord( _1_p_recordTable);
  End;

Procedure copyAliasToAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_sourceName: string; Const _4_t_destName: string);
  Var
    _e_idx:      int64;
    _e_resultNo: int64;
    _t_sourceAliasTableName: string;
  Begin
    q4interruptions.assertRaise( LazUTF8.UTF8Trim( _3_t_sourceName) <> '',
      'q4setsAndNamedSelectionsCore.copyAliasToAlias : source vide');
    q4interruptions.assertRaise( LazUTF8.UTF8Trim( _4_t_destName) <> '',
      'q4setsAndNamedSelectionsCore.copyAliasToAlias : destination vide');

    InternalEnsureSelectionState( _1_p_recordTable, _e_idx);
    q4interruptions.assertRaise(
      resolveSelectionAlias( q4selection.ty_selectionTables[_e_idx].e_sourceTableId, _2_e_kind, _3_t_sourceName, _e_resultNo),
      'q4setsAndNamedSelectionsCore.copyAliasToAlias : alias source introuvable'
      );

    _t_sourceAliasTableName := InternalAliasTableName( q4selection.ty_selectionTables[_e_idx].t_sourceTableName, _3_t_sourceName);
    InternalMaterializeAliasFromSql(
      _e_idx,
      _2_e_kind,
      _4_t_destName,
      InternalBuildAliasPkSql( _t_sourceAliasTableName, q4selection.ty_selectionTables[_e_idx].t_pkFieldName, _e_resultNo)
      );
  End;

Procedure useAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string; Const _4_e_mode: Tq4selectionUseMode);
  Var
    _e_idx:      int64;
    _e_resultNo: int64;
    _e_scope:    Tq4selectionTableScope;
    _t_sourceAliasTableName: string;
  Begin
    q4interruptions.assertRaise( LazUTF8.UTF8Trim( _3_t_name) <> '',
      'q4setsAndNamedSelectionsCore.useAlias : nom vide');

    InternalEnsureSelectionState( _1_p_recordTable, _e_idx);
    q4interruptions.assertRaise(
      resolveSelectionAlias( q4selection.ty_selectionTables[_e_idx].e_sourceTableId, _2_e_kind, _3_t_name, _e_resultNo),
      'q4setsAndNamedSelectionsCore.useAlias : alias introuvable'
      );

    _e_scope := aliasScope( _3_t_name);
    _t_sourceAliasTableName := InternalAliasTableName( q4selection.ty_selectionTables[_e_idx].t_sourceTableName, _3_t_name);

    Case _4_e_mode Of
      qsumCopy: InternalReplaceCurrentSelectionFromSelect(
          _1_p_recordTable,
          _e_idx,
          InternalBuildAliasPkSql( _t_sourceAliasTableName, q4selection.ty_selectionTables[_e_idx].t_pkFieldName, _e_resultNo)
          );

      qsumMove: If ( _e_scope = qstsThread) Then Begin
          If ( q4selection.ty_selectionTables[_e_idx].e_currentResultNo > 0) Then q4selectionTablesCore.clearSelectionResultNo(
              q4selection.ty_selectionTables[_e_idx].t_tempTableName,
              q4selection.ty_selectionTables[_e_idx].e_currentResultNo
              );

          q4selection.ty_selectionTables[_e_idx].e_currentResultNo := _e_resultNo;
          q4selection.ty_selectionTables[_e_idx].e_recordCount := InternalCountResultRows( q4selection.ty_selectionTables[_e_idx].t_tempTableName, _e_resultNo);
          q4selection.ty_selectionTables[_e_idx].b_isEmpty := ( q4selection.ty_selectionTables[_e_idx].e_recordCount = 0);
          q4selection.ty_selectionTables[_e_idx].e_currentPos := 0;

          clearSelectionAlias(
            q4selection.ty_selectionTables[_e_idx].e_sourceTableId,
            _2_e_kind,
            _3_t_name
            );

          InternalPositionOnCurrentSelection( _1_p_recordTable, _e_idx);
        End Else Begin
          InternalReplaceCurrentSelectionFromSelect(
            _1_p_recordTable,
            _e_idx,
            InternalBuildAliasPkSql( _t_sourceAliasTableName, q4selection.ty_selectionTables[_e_idx].t_pkFieldName, _e_resultNo)
            );

          clearSelectionAlias(
            q4selection.ty_selectionTables[_e_idx].e_sourceTableId,
            _2_e_kind,
            _3_t_name
            );
        End;
      Else q4interruptions.assertRaise( False,
          'q4setsAndNamedSelectionsCore.useAlias : mode invalide');
    End;
  End;

Function countAlias( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_name: string): int64;
  Var
    _e_idx:      int64;
    _e_resultNo: int64;
    _t_tableName: string;
  Begin
    InternalEnsureSelectionState( _1_p_recordTable, _e_idx);
    q4interruptions.assertRaise(
      resolveSelectionAlias( q4selection.ty_selectionTables[_e_idx].e_sourceTableId, _2_e_kind, _3_t_name, _e_resultNo),
      'q4setsAndNamedSelectionsCore.countAlias : alias introuvable'
      );
    _t_tableName := InternalAliasTableName( q4selection.ty_selectionTables[_e_idx].t_sourceTableName, _3_t_name);
    Result := InternalCountResultRows( _t_tableName, _e_resultNo);
  End;

Procedure combineAliases( Var _1_p_recordTable; Const _2_e_kind: Tq4selectionAliasKind; Const _3_t_leftName: string; Const _4_t_rightName: string;
  Const _5_t_destName: string; Const _6_t_sqlOperator: string; Const _7_t_errorPrefix: string);
  Var
    _e_idx: int64;
    _e_leftResultNo: int64;
    _e_rightResultNo: int64;
    _t_leftTableName: string;
    _t_rightTableName: string;
    _t_sql: string;
  Begin
    InternalEnsureSelectionState( _1_p_recordTable, _e_idx);

    q4interruptions.assertRaise(
      resolveSelectionAlias( q4selection.ty_selectionTables[_e_idx].e_sourceTableId, _2_e_kind, _3_t_leftName, _e_leftResultNo),
      _7_t_errorPrefix + ' : alias gauche introuvable'
      );
    q4interruptions.assertRaise(
      resolveSelectionAlias( q4selection.ty_selectionTables[_e_idx].e_sourceTableId, _2_e_kind, _4_t_rightName, _e_rightResultNo),
      _7_t_errorPrefix + ' : alias droit introuvable'
      );

    _t_leftTableName := InternalAliasTableName( q4selection.ty_selectionTables[_e_idx].t_sourceTableName, _3_t_leftName);
    _t_rightTableName := InternalAliasTableName( q4selection.ty_selectionTables[_e_idx].t_sourceTableName, _4_t_rightName);

    _t_sql :=
      InternalBuildAliasPkSql( _t_leftTableName, q4selection.ty_selectionTables[_e_idx].t_pkFieldName, _e_leftResultNo) + ' ' + _6_t_sqlOperator + ' ' +
      InternalBuildAliasPkSql( _t_rightTableName, q4selection.ty_selectionTables[_e_idx].t_pkFieldName, _e_rightResultNo);

    InternalMaterializeAliasFromSql( _e_idx, _2_e_kind, _5_t_destName, _t_sql);
  End;

Procedure InternalClearAliasesForTableInArray( Var _1_ty_aliases: Tty_selectionAlias; Const _2_e_sourceTableId: int64);
  Var
    _e_i: int64;
  Begin
    For _e_i := System.High( _1_ty_aliases) Downto 0 Do If ( _1_ty_aliases[_e_i].e_sourceTableId = _2_e_sourceTableId) Then q4selectionTablesCore.clearSelectionResultNo(
          _1_ty_aliases[_e_i].t_tableName,
          _1_ty_aliases[_e_i].e_resultNo
          )// Sur TRUNCATE TABLE, on vide le contenu des aliases mais on conserve
        // leur nom et leur association a la table.
    ;
  End;

Procedure clearAllAliasesForTable( Const _1_e_sourceTableId: int64);
  Begin
    InternalClearAliasesForTableInArray( ty_sharedSelectionAliases, _1_e_sourceTableId);
    InternalClearAliasesForTableInArray( ty_localSelectionAliases, _1_e_sourceTableId);
  End;

Procedure clearSharedSelectionAliases;
  Begin
    SetLength( ty_sharedSelectionAliases, 0);
    e_nextSharedResultNo := 1;
  End;

Procedure clearLocalSelectionAliases;
  Begin
    SetLength( ty_localSelectionAliases, 0);
  End;

Initialization
  e_nextSharedResultNo := 1;

End.
