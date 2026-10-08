Unit q4queries;

{$mode objfpc}{$H+}

{
q4queries
version du 2026/04/19-17:20

Mapping 4D
Command Number 4D,   4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
277,                 QUERY,                            query,                            Partial,
341,                 QUERY SELECTION,                  querySelection,                   Partial,
49,                  ORDER BY,                         orderBy,                          Partial,
395,                 SET QUERY LIMIT,                  setQueryLimit,                    OK,
1156,                GET QUERY LIMIT,                  getQueryLimit,                    OK,
396,                 SET QUERY DESTINATION,            setQueryDestination,              Partial,
1155,                GET QUERY DESTINATION,            getQueryDestination,              Partial,
661,                 SET QUERY AND LOCK,               queryAndLock,                     TODO,
1044,                DESCRIBE QUERY EXECUTION,         describeQueryExecution,           Partial,
1046,                Last query plan,                  lastQueryPlan,                    Partial,
1045,                Last query path,                  lastQueryPath,                    Partial,

Doc: https://developer.4d.com/docs/21/commands/theme/QueriesAndSorts

Notes
- Cette version compile la logique de recherche en ensembles de PK:
  & -> INTERSECT
  | -> UNION
  # -> EXCEPT
- Les champs sont passés comme pointeurs.
- Les champs liés sont résolus par q4DBschemaUse ; seuls les liens directs sont
  effectivement pris en charge ici.
- Les destinations Set / NamedSelection restent en attente d'un vrai registre
  d'alias de résultats.
}

Interface

Uses
  SysUtils,
  Variants,
  LazUTF8,
  SQLDB,
  q4DBschemaUse,
  q4selection,
  Dialogs;

Type
  TQ4QueryDestinationKind = q4selection.Tq4QueryDestinationKind;

  TQ4QueryDestination = Record
    e_kind: TQ4QueryDestinationKind;
    s_name: string;
  End;

Threadvar
  gb_queryProcessInitialized: boolean;
  gi_queryLimit:    int64;
  gy_queryDestination: TQ4QueryDestination;
  gs_lastQueryPlan: string;
  gs_lastQueryPath: string;
  gi_lastQueryResultCount: int64;

Procedure query( Var _1_p_recordTable); overload;
Procedure query( Var _1_p_recordTable; Const _2_t_s_conjunction: string; Const _3_p_field: Pointer; Const _4_t_s_operator: string; Const _5_v_value: variant;
  Const _6_t_s_flag: string = ''); overload;

Procedure querySelection( Var _1_p_recordTable); overload;
Procedure querySelection( Var _1_p_recordTable; Const _2_t_s_conjunction: string; Const _3_p_field: Pointer; Const _4_t_s_operator: string; Const _5_v_value: variant;
  Const _6_t_s_flag: string = ''); overload;

Procedure orderBy( Var _1_p_recordTable); overload;
Procedure orderBy( Var _1_p_recordTable; Const _2_p_field: Pointer; Const _3_t_s_direction: string; Const _4_t_s_flag: string = ''); overload;

Procedure queryAndLock( Var _1_p_recordTable; Const _2_t_s_conjunction: string; Const _3_p_field: Pointer; Const _4_t_s_operator: string; Const _5_v_value: variant; Const _6_t_s_flag: string = '');

Procedure setQueryLimit( Const _1_e_i_limit: int64);
Function getQueryLimit: int64;

Procedure resetQueryDestination;
Procedure setQueryDestination( Const _1_e_kind: TQ4QueryDestinationKind; Const _2_t_s_name: string = '');
Function getQueryDestination: TQ4QueryDestination;

Function describeQueryExecution: string;
Function lastQueryPlan: string;
Function lastQueryPath: string;

Implementation

Uses
  q4coreLanguage,
  q4DBmanager,
  metier_q4DBschemaBase,
  q4selectionTablesCore,
  q4setsAndNamedSelectionsCore,
  q4interruptions,
  q4RecordLocking;

Type
  TQ4FieldResolution = Record
    b_isLocal: boolean;
    i_ownerTableId: int64;
    y_field: TFieldMeta;
    s_exprSql: string;
    s_joinSql: string;
  End;

Type
  TQ4TextSearchKind = (
    tskExact,
    tskLeadingWildcard,
    tskTrailingWildcard,
    tskInternalWildcard
    );

Function runtimeOf( Var _1_p_table: Pointer): Pq4recordRuntime; Inline;
  Begin
    Result := Pq4recordRuntime( _1_p_table);
  End;

Function InternalIsTextField( Const _1_y_fieldRef: TQ4FieldResolution): boolean;
  Begin
    Result := _1_y_fieldRef.y_field.FieldKind = fkText;
  End;

Function InternalIsTextSqlTypeSupported( Const _1_y_fieldRef: TQ4FieldResolution): boolean;
  Var
    _s_typeSql: string;
  Begin
    _s_typeSql := SysUtils.Trim( _1_y_fieldRef.y_field.TypeSQL);
    Result := SameText( _s_typeSql, 'TEXT') or SameText( _s_typeSql, 'TEXT_ICU');
  End;

Procedure InternalEnsureProcessState;
  Begin
    If ( gb_queryProcessInitialized) Then Exit;

    gb_queryProcessInitialized := True;
    gi_queryLimit := 0;
    gy_queryDestination.e_kind := qdkCurrentSelection;
    gy_queryDestination.s_name := '';
    gs_lastQueryPlan := '';
    gs_lastQueryPath := '';
    gi_lastQueryResultCount := 0;
  End;

Function InternalFindSelectionTableStateIndex( Const _1_e_i_sourceTableId: int64): int64;
  Var
    _i_i: int64;
  Begin
    Result := -1;

    For _i_i := 0 To System.High( q4selection.ty_selectionTables) Do If ( q4selection.ty_selectionTables[_i_i].e_sourceTableId = _1_e_i_sourceTableId) Then Begin
        Result := _i_i;
        Exit;
      End;
  End;

Function InternalFindTableMetaIndexBySourceTableId( Const _1_e_i_sourceTableId: int64): int64;
  Var
    _i_i: int64;
  Begin
    Result := -1;

    For _i_i := 0 To System.High( Tables) Do If ( Tables[_i_i].SourceTableId = _1_e_i_sourceTableId) Then Begin
        Result := _i_i;
        Exit;
      End;
  End;

Function InternalFindFieldMetaByTableAndFieldNo( Const _1_e_i_sourceTableId: int64; Const _2_e_i_fieldNo: int64; out _3_y_field: TFieldMeta): boolean;
  Var
    _i_tableIdx: int64;
    _i_first: int64;
    _i_last: int64;
    _i_i: int64;
  Begin
    Result := False;

    _i_tableIdx := InternalFindTableMetaIndexBySourceTableId( _1_e_i_sourceTableId);
    If ( _i_tableIdx < 0) Then Exit;

    _i_first := Tables[_i_tableIdx].FieldIndex;
    _i_last := _i_first + Tables[_i_tableIdx].FieldCount - 1;

    For _i_i := _i_first To _i_last Do If ( Fields[_i_i].FieldNo = _2_e_i_fieldNo) Then Begin
        _3_y_field := Fields[_i_i];
        Result := True;
        Exit;
      End;
  End;

Procedure InternalResolveSelectionTableMeta( Var _1_y_state: q4selection.Ty_selectionTableState);
  Var
    _i_tableIdx: int64;
    _i_first: int64;
    _i_last: int64;
    _i_i: int64;
  Begin
    _i_tableIdx := InternalFindTableMetaIndexBySourceTableId( _1_y_state.e_sourceTableId);
    q4interruptions.assertRaise( _i_tableIdx >= 0,
      'q4queries : table source introuvable');

    _1_y_state.t_sourceTableName := Tables[_i_tableIdx].Name;
    _1_y_state.t_tempTableName := q4selectionTablesCore.buildSelectionTableName( qstsThread, _1_y_state.t_sourceTableName);

    _i_first := Tables[_i_tableIdx].FieldIndex;
    _i_last := _i_first + Tables[_i_tableIdx].FieldCount - 1;

    _1_y_state.t_pkFieldName := '';
    _1_y_state.t_pkTypeSQL := '';

    For _i_i := _i_first To _i_last Do If ( SysUtils.CompareText( Fields[_i_i].Name, Tables[_i_tableIdx].PrimaryKey) = 0) Then Begin
        _1_y_state.t_pkFieldName := Fields[_i_i].Name;
        _1_y_state.t_pkTypeSQL := Fields[_i_i].TypeSQL;
        Break;
      End;

    q4interruptions.assertRaise( _1_y_state.t_pkFieldName <> '',
      'q4queries : champ PK introuvable');
    q4interruptions.assertRaise( _1_y_state.t_pkTypeSQL <> '',
      'q4queries : type SQL PK introuvable');
  End;

Function InternalCountPkSelect( Const _1_t_s_selectPkSql: string): int64;
  Var
    _o_query: TSQLQuery;
  Begin
    q4interruptions.assertRaise( SysUtils.Trim( _1_t_s_selectPkSql) <> '',
      'q4queries.InternalCountPkSelect : select PK vide');

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;
      _o_query.SQL.Text := 'SELECT COUNT(*) FROM (' + _1_t_s_selectPkSql + ') q4count';
      _o_query.Open;
      Result := _o_query.Fields[0].AsInteger;
    Finally
      _o_query.Free;
    End;
  End;

Procedure InternalShowExplainQueryPlan( Const _1_t_s_sql: unicodestring);
  Var
    _o_query: TSQLQuery;
    _s_msg:   unicodestring;
  Begin
    q4interruptions.assertRaise( SysUtils.Trim( _1_t_s_sql) <> '',
      'q4queries.InternalShowExplainQueryPlan : SQL vide');

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;
      _o_query.SQL.Text := 'EXPLAIN QUERY PLAN ' + _1_t_s_sql;
      _o_query.Open;

      _s_msg :=
        'SQL :' + sLineBreak + _1_t_s_sql + sLineBreak + sLineBreak + 'EXPLAIN QUERY PLAN :' + sLineBreak + sLineBreak;

      While ( not _o_query.EOF) Do Begin
        _s_msg := _s_msg + _o_query.Fields[0].AsString + #9 + _o_query.Fields[1].AsString + #9 + _o_query.Fields[2].AsString + #9 + _o_query.Fields[3].AsString + sLineBreak;
        _o_query.Next;
      End;

      ShowMessage( _s_msg);
    Finally
      _o_query.Free;
    End;
  End;

Procedure InternalEnsureTempTable( Var _1_y_state: q4selection.Ty_selectionTableState);
  Begin
    If ( _1_y_state.b_isCreated) Then Exit;

    q4selectionTablesCore.ensureSelectionTable(
      qstsThread,
      _1_y_state.t_tempTableName,
      _1_y_state.t_pkFieldName,
      _1_y_state.t_pkTypeSQL
      );
    _1_y_state.b_isCreated := True;
  End;

Function InternalGetOrCreateSelectionTableStateIndex( Var _1_p_recordTable): int64;
  Var
    _i_sourceTableId: int64;
  Begin
    _i_sourceTableId := q4DBschemaUse.getSourceTableId( _1_p_recordTable);
    q4interruptions.assertRaise( _i_sourceTableId >= 0,
      'q4queries : _noTable invalide');

    Result := InternalFindSelectionTableStateIndex( _i_sourceTableId);
    If ( Result >= 0) Then Begin
      If ( q4selection.ty_selectionTables[Result].t_sourceTableName = '') Then InternalResolveSelectionTableMeta( q4selection.ty_selectionTables[Result]);
      InternalEnsureTempTable( q4selection.ty_selectionTables[Result]);
      Exit;
    End;

    SetLength( q4selection.ty_selectionTables, Length( q4selection.ty_selectionTables) + 1);
    q4interruptions.assertRaise( Length( q4selection.ty_selectionTables) > 0,
      'SetLength sur q4selection.ty_selectionTables n''a pas marché');

    Result := System.High( q4selection.ty_selectionTables);

    q4selection.ty_selectionTables[Result].e_sourceTableId := _i_sourceTableId;

    q4selection.ty_selectionTables[Result].t_sourceTableName := '';
    q4selection.ty_selectionTables[Result].t_tempTableName := '';
    q4selection.ty_selectionTables[Result].t_pkFieldName := '';
    q4selection.ty_selectionTables[Result].t_pkTypeSQL := '';
    q4selection.ty_selectionTables[Result].b_isCreated := False;
    q4selection.ty_selectionTables[Result].e_currentResultNo := 0;
    q4selection.ty_selectionTables[Result].e_nextResultNo := 1;
    q4selection.ty_selectionTables[Result].e_currentPos := 0;
    q4selection.ty_selectionTables[Result].e_recordCount := 0;
    q4selection.ty_selectionTables[Result].b_isEmpty := True;
    q4selection.ty_selectionTables[Result].e_buildState := sbsNone;
    q4selection.ty_selectionTables[Result].t_pendingWhereSQL := '';
    q4selection.ty_selectionTables[Result].t_pendingOrderBySQL := '';
    q4selection.ty_selectionTables[Result].e_pendingDestinationKind := qdkCurrentSelection;
    q4selection.ty_selectionTables[Result].t_pendingDestinationName := '';
    q4selection.ty_selectionTables[Result].e_pendingQueryLimit := 0;
    q4selection.ty_selectionTables[Result].e_pendingReduceCount := 0;

    InternalResolveSelectionTableMeta( q4selection.ty_selectionTables[Result]);
    InternalEnsureTempTable( q4selection.ty_selectionTables[Result]);
  End;

Function InternalNormalizeContinuationFlag( Const _1_t_s_flag: string): string;
  Begin
    Result := LazUTF8.UTF8Trim( _1_t_s_flag);

    If ( Result = '') Then Exit;

    If ( Result = '*') Then Exit;

    If ( SameText( Result, 'EQP')) Then Begin
      Result := 'EQP';
      Exit;
    End;

    q4interruptions.assertRaise( False,
      'q4queries : flag de continuation invalide');
  End;

Function InternalIsEQPFlag( Const _1_t_s_flag: string): boolean;
  Begin
    Result := SameText( LazUTF8.UTF8Trim( _1_t_s_flag), 'EQP');
  End;

Function InternalNormalizeConjunction( Const _1_t_s_conjunction: string): string;
  Begin
    Result := LazUTF8.UTF8Trim( _1_t_s_conjunction);

    If ( ( Result = '') or ( Result = '&') or ( Result = '|') or ( Result = '#')) Then Exit;

    q4interruptions.assertRaise( False,
      'q4queries : conjonction invalide');
  End;

Function InternalNormalizeOrderDirection( Const _1_t_s_direction: string): string;
  Begin
    Result := LazUTF8.UTF8Trim( _1_t_s_direction);
    q4interruptions.assertRaise( ( Result = '<') or ( Result = '>'),
      'q4queries.orderBy : direction invalide');
  End;

Function InternalNormalizeQueryOperator( Const _1_t_s_operator: string): string;
  Begin
    Result := LazUTF8.UTF8Trim( _1_t_s_operator);

    If ( Result = '=') Then Exit;
    If ( Result = '#') Then Begin
      Result := '<>';
      Exit;
    End;
    If ( Result = '<') Then Exit;
    If ( Result = '>') Then Exit;
    If ( Result = '<=') Then Exit;
    If ( Result = '>=') Then Exit;

    q4interruptions.assertRaise( Result <> '%',
      'q4queries : operateur 4D % non implemente');

    q4interruptions.assertRaise( False,
      'q4queries : operateur de comparaison invalide');
  End;

Function InternalQuoteSqlString( Const _1_t_s_value: string): string;
  Begin
    Result := '''' + SysUtils.StringReplace( _1_t_s_value, '''', '''''', [SysUtils.rfReplaceAll]) + '''';
  End;

Function InternalVariantToSqlLiteral( Const _1_v_value: variant): string;
  Begin
    If ( Variants.VarIsNull( _1_v_value)) Then Begin
      Result := 'NULL';
      Exit;
    End;

    Case Variants.VarType( _1_v_value) Of
      varSmallint, varInteger, varShortInt, varByte, varWord, varLongWord, varInt64: Result := Variants.VarToStr( _1_v_value);
      varSingle, varDouble, varCurrency: Result := SysUtils.StringReplace( Variants.VarToStr( _1_v_value), ',', '.', [SysUtils.rfReplaceAll]);
      varBoolean: If ( _1_v_value) Then Result := '1'
        Else
          Result := '0';
      Else Result := InternalQuoteSqlString( Variants.VarToStr( _1_v_value));
    End;
  End;

Function InternalContains4DWildcard( Const _1_v_value: variant): boolean;
  Var
    _s_value: string;
  Begin
    If ( Variants.VarIsNull( _1_v_value)) Then Begin
      Result := False;
      Exit;
    End;

    _s_value := Variants.VarToStr( _1_v_value);
    Result := LazUTF8.UTF8Pos( '@', _s_value) > 0;
  End;

Function InternalEscapeSqlLikePattern( Const _1_t_s_value: string): string;
  Begin
    Result := _1_t_s_value;
    Result := SysUtils.StringReplace( Result, '\', '\\', [SysUtils.rfReplaceAll]);
    Result := SysUtils.StringReplace( Result, '%', '\%', [SysUtils.rfReplaceAll]);
    Result := SysUtils.StringReplace( Result, '_', '\_', [SysUtils.rfReplaceAll]);
    Result := SysUtils.StringReplace( Result, '@', '%', [SysUtils.rfReplaceAll]);
  End;

Function InternalIsAsciiDigit( Const _1_t_c_ch: char): boolean;
  Begin
    Result := ( _1_t_c_ch >= '0') and ( _1_t_c_ch <= '9');
  End;

Function InternalOnlyTrailing4DWildcards( Const _1_t_s_value: string; Const _2_e_i_firstWildcard: int64): boolean;
  Var
    _i_i: int64;
  Begin
    Result := _2_e_i_firstWildcard > 0;
    If ( not Result) Then Exit;

    For _i_i := _2_e_i_firstWildcard To Length( _1_t_s_value) Do If ( _1_t_s_value[_i_i] <> '@') Then Begin
        Result := False;
        Exit;
      End;
  End;

Function InternalIsAsciiAlphaNum( Const _1_t_c_ch: char): boolean;
  Begin
    Result :=
      ( ( _1_t_c_ch >= '0') and ( _1_t_c_ch <= '9')) or ( ( _1_t_c_ch >= 'A') and ( _1_t_c_ch <= 'Z')) or ( ( _1_t_c_ch >= 'a') and ( _1_t_c_ch <= 'z'));
  End;

Function InternalContainsOnlyAsciiAlphaNum( Const _1_t_s_value: string): boolean;
  Var
    _i_i: int64;
  Begin
    Result := _1_t_s_value <> '';
    If ( not Result) Then Exit;

    For _i_i := 1 To Length( _1_t_s_value) Do If ( not InternalIsAsciiAlphaNum( _1_t_s_value[_i_i])) Then Begin
        Result := False;
        Exit;
      End;
  End;

Function InternalContainsOnlyAsciiAlphaNumAnd4DWildcards( Const _1_t_s_value: string): boolean;
  Var
    _i_i:  int64;
    _c_ch: char;
  Begin
    Result := _1_t_s_value <> '';
    If ( not Result) Then Exit;

    For _i_i := 1 To Length( _1_t_s_value) Do Begin
      _c_ch := _1_t_s_value[_i_i];
      If ( not ( InternalIsAsciiAlphaNum( _c_ch) or ( _c_ch = '@'))) Then Begin
        Result := False;
        Exit;
      End;
    End;
  End;

Function InternalConvert4DWildcardToLikePattern( Const _1_t_s_value: string): string;
  Begin
    Result := SysUtils.StringReplace( _1_t_s_value, '@', '%', [SysUtils.rfReplaceAll]);
  End;

Function InternalFirst4DWildcardPos( Const _1_t_s_value: string): int64;
  Begin
    Result := Pos( '@', _1_t_s_value);
  End;

Function InternalBuildLexicalUpperBoundForPrefix( Const _1_t_s_prefix: string): string;
  Begin
    q4interruptions.assertRaise( _1_t_s_prefix <> '',
      'q4queries : prefixe vide pour borne haute');

    Result := _1_t_s_prefix;
    Result[Length( Result)] := Chr( Ord( Result[Length( Result)]) + 1);
  End;

Function InternalConvert4DWildcardToGlobPattern( Const _1_t_s_value: string): string;
  Begin
    Result := SysUtils.StringReplace( _1_t_s_value, '@', '*', [SysUtils.rfReplaceAll]);
  End;

Function InternalCanUsePrefixRangeOptimization( Const _1_y_fieldRef: TQ4FieldResolution; Const _2_t_s_prefix: string): boolean;
  Begin
    { Version prudente :
    - champ texte
    - champ indexé
    - type SQL texte supporté
    - préfixe non vide
    - préfixe ASCII alphanumérique uniquement

    On reste volontairement prudent sur les bornes lexicales :
    InternalBuildLexicalUpperBoundForPrefix() n'est sûre que dans ce cas.
  }
    Result :=
      InternalIsTextField( _1_y_fieldRef) and _1_y_fieldRef.y_field.Indexed and InternalIsTextSqlTypeSupported( _1_y_fieldRef) and ( _2_t_s_prefix <> '') and
      InternalContainsOnlyAsciiAlphaNum( _2_t_s_prefix);
  End;

Procedure InternalAnalyze4DTextPattern( Const _1_t_s_value: string; out _2_e_kind: TQ4TextSearchKind; out _3_e_i_firstWildcard: int64; out _4_t_s_prefix: string);
  Begin
    _3_e_i_firstWildcard := InternalFirst4DWildcardPos( _1_t_s_value);
    _4_t_s_prefix := '';

    If ( _3_e_i_firstWildcard = 0) Then Begin
      _2_e_kind := tskExact;
      Exit;
    End;

    If ( _3_e_i_firstWildcard = 1) Then Begin
      _2_e_kind := tskLeadingWildcard;
      Exit;
    End;

    _4_t_s_prefix := Copy( _1_t_s_value, 1, _3_e_i_firstWildcard - 1);

    If ( InternalOnlyTrailing4DWildcards( _1_t_s_value, _3_e_i_firstWildcard)) Then _2_e_kind := tskTrailingWildcard
    Else
      _2_e_kind := tskInternalWildcard;
  End;

Function InternalDirectionToSql( Const _1_t_s_direction: string): string;
  Begin
    If ( _1_t_s_direction = '>') Then Begin
      Result := 'ASC';
      Exit;
    End;
    If ( _1_t_s_direction = '<') Then Begin
      Result := 'DESC';
      Exit;
    End;

    q4interruptions.assertRaise( False,
      'q4queries.orderBy : direction SQL invalide');
  End;

Function InternalBuildCurrentSelectionJoin( Const _1_y_state: q4selection.Ty_selectionTableState): string;
  Begin
    Result :=
      ' JOIN ' + _1_y_state.t_tempTableName + ' cur' + ' ON cur.' + _1_y_state.t_pkFieldName + ' = src.' + _1_y_state.t_pkFieldName + ' AND cur.noResultat = ' +
      SysUtils.IntToStr( _1_y_state.e_currentResultNo);
  End;

Function InternalResolveField( Const _1_e_i_sourceTableId: int64; Var _2_p_recordTable; Const _3_p_field: Pointer; Const _4_t_s_context: string): TQ4FieldResolution;
  Var
    _b_isLocal: boolean;
    _i_ownerTableId: int64;
    _y_field: TFieldMeta;
    _y_link:  TJoinLinkMeta;
    _y_sourceJoinField: TFieldMeta;
    _y_targetJoinField: TFieldMeta;
    _y_targetTable: TTableMeta;
  Begin
    System.FillChar( Result, SizeOf( Result), 0);

    q4interruptions.assertRaise(
      q4DBschemaUse.resolveFieldPointer( _2_p_recordTable, _3_p_field, _i_ownerTableId, _y_field, _b_isLocal),
      _4_t_s_context + ' : pointeur de champ non resolu'
      );

    Result.b_isLocal := _b_isLocal;
    Result.i_ownerTableId := _i_ownerTableId;
    Result.y_field := _y_field;
    Result.s_joinSql := '';

    If ( _b_isLocal) Then Begin
      Result.s_exprSql := 'src.' + _y_field.Name;
      Exit;
    End;

    q4interruptions.assertRaise(
      q4DBschemaUse.findDirectLink( _1_e_i_sourceTableId, _i_ownerTableId, _y_link),
      _4_t_s_context + ' : aucun lien direct vers la table du champ'
      );

    q4interruptions.assertRaise(
      InternalFindFieldMetaByTableAndFieldNo( _1_e_i_sourceTableId, _y_link.SourceFieldId, _y_sourceJoinField),
      _4_t_s_context + ' : champ source du lien introuvable'
      );
    q4interruptions.assertRaise(
      InternalFindFieldMetaByTableAndFieldNo( _i_ownerTableId, _y_link.TargetFieldId, _y_targetJoinField),
      _4_t_s_context + ' : champ cible du lien introuvable'
      );
    q4interruptions.assertRaise(
      q4DBschemaUse.findTableMeta( _i_ownerTableId, _y_targetTable),
      _4_t_s_context + ' : table cible du champ introuvable'
      );

    Result.s_joinSql :=
      ' JOIN ' + _y_targetTable.Name + ' tgt' + ' ON src.' + _y_sourceJoinField.Name + ' = tgt.' + _y_targetJoinField.Name;
    Result.s_exprSql := 'tgt.' + _y_field.Name;
  End;

{ Regles de recherche
  RAS pour les INTEGER, DOUBLE.

  Pour les champs TEXT
  (les dates et heures sont stockees en TEXT ; on peut donc vouloir
  des recherches du type 2026-@ ou 10:@) :

  NOCASE
  - sans joker        -> =
  - joker final       -> fourchette
  - joker interne     -> fourchette + GLOB
  - joker a gauche    -> GLOB  (si champ indexe : pas de prefixe exploitable pour optimisation)

  ICU
  - sans joker        -> =
  - joker final       -> fourchette
  - joker interne     -> fourchette + GLOB
  - joker a gauche    -> GLOB  (si champ indexe : pas de prefixe exploitable pour optimisation)
}

Function InternalTryBuildTextPredicate( Const _1_y_fieldRef: TQ4FieldResolution; Const _2_t_s_operatorSql: string; Const _3_v_value: variant; out _4_t_s_sql: string): boolean;
  Var
    _s_value:  string;
    _e_kind:   TQ4TextSearchKind;
    _i_firstWildcard: int64;
    _s_prefix: string;
    _s_upper:  string;
    _s_glob:   string;
    _s_expr:   string;
  Begin
    Result := False;
    _4_t_s_sql := '';

    If ( not InternalIsTextField( _1_y_fieldRef)) Then Exit;

    If ( Variants.VarIsNull( _3_v_value)) Then Exit;

    _s_value := Variants.VarToStr( _3_v_value);
    _s_expr := _1_y_fieldRef.s_exprSql;

    { Cas sans joker }
    If ( not InternalContains4DWildcard( _s_value)) Then Begin
      If ( _2_t_s_operatorSql = '=') Then Begin
        _4_t_s_sql := _s_expr + ' = ' + InternalQuoteSqlString( _s_value);
        Result := True;
        Exit;
      End;

      If ( _2_t_s_operatorSql = '<>') Then Begin
        _4_t_s_sql := _s_expr + ' <> ' + InternalQuoteSqlString( _s_value);
        Result := True;
        Exit;
      End;

      Exit;
    End;

    { Avec joker : uniquement = et <> }
    If ( ( _2_t_s_operatorSql <> '=') and ( _2_t_s_operatorSql <> '<>')) Then Exit;

    InternalAnalyze4DTextPattern( _s_value, _e_kind, _i_firstWildcard, _s_prefix);
    _s_glob := q4coreLanguage.BuildGlobPatternQ4( _s_value);

    Case _e_kind Of
      tskExact: Begin
        If ( _2_t_s_operatorSql = '=') Then _4_t_s_sql := _s_expr + ' = ' + InternalQuoteSqlString( _s_value)
        Else
          _4_t_s_sql := _s_expr + ' <> ' + InternalQuoteSqlString( _s_value);
        Result := True;
        Exit;
      End;

      tskLeadingWildcard: Begin
        If ( _2_t_s_operatorSql = '=') Then _4_t_s_sql := _s_expr + ' GLOB ' + InternalQuoteSqlString( _s_glob)
        Else
          _4_t_s_sql := _s_expr + ' NOT GLOB ' + InternalQuoteSqlString( _s_glob);
        Result := True;
        Exit;
      End;

      tskTrailingWildcard: Begin
        If ( InternalCanUsePrefixRangeOptimization( _1_y_fieldRef, _s_prefix)) Then Begin
          _s_upper := InternalBuildLexicalUpperBoundForPrefix( _s_prefix);

          If ( _2_t_s_operatorSql = '=') Then _4_t_s_sql :=
              '(' + _s_expr + ' >= ' + InternalQuoteSqlString( _s_prefix) + ' AND ' + _s_expr + ' < ' + InternalQuoteSqlString( _s_upper) + ')'
          Else
            _4_t_s_sql :=
              '(' + _s_expr + ' < ' + InternalQuoteSqlString( _s_prefix) + ' OR ' + _s_expr + ' >= ' + InternalQuoteSqlString( _s_upper) +
              ')'{ Négation de "préfixe" : plus sûr que NOT GLOB si on veut
              conserver la logique inverse exacte du cas optimisé. };

          Result := True;
          Exit;
        End;

        { Pas de préfixe exploitable sûr -> GLOB }
        If ( _2_t_s_operatorSql = '=') Then _4_t_s_sql := _s_expr + ' GLOB ' + InternalQuoteSqlString( _s_glob)
        Else
          _4_t_s_sql := _s_expr + ' NOT GLOB ' + InternalQuoteSqlString( _s_glob);

        Result := True;
        Exit;
      End;

      tskInternalWildcard: Begin
        If ( InternalCanUsePrefixRangeOptimization( _1_y_fieldRef, _s_prefix)) Then Begin
          _s_upper := InternalBuildLexicalUpperBoundForPrefix( _s_prefix);

          If ( _2_t_s_operatorSql = '=') Then _4_t_s_sql :=
              '(' + _s_expr + ' >= ' + InternalQuoteSqlString( _s_prefix) + ' AND ' + _s_expr + ' < ' + InternalQuoteSqlString( _s_upper) + ' AND ' +
              _s_expr + ' GLOB ' + InternalQuoteSqlString( _s_glob) + ')'
          Else
            _4_t_s_sql := _s_expr + ' NOT GLOB ' + InternalQuoteSqlString(
              _s_glob){ Pour <> avec joker interne, rester simple et sûr :
              on repasse à NOT GLOB au lieu d’essayer de nier
              proprement "fourchette + glob". };

          Result := True;
          Exit;
        End;

        { Pas de préfixe exploitable sûr -> GLOB }
        If ( _2_t_s_operatorSql = '=') Then _4_t_s_sql := _s_expr + ' GLOB ' + InternalQuoteSqlString( _s_glob)
        Else
          _4_t_s_sql := _s_expr + ' NOT GLOB ' + InternalQuoteSqlString( _s_glob);

        Result := True;
        Exit;
      End;
    End;
  End;

Function InternalBuildPredicateSql( Const _1_y_fieldRef: TQ4FieldResolution; Const _2_t_s_operator: string; Const _3_v_value: variant; Const _4_t_s_context: string): string;
  Var
    _s_operatorSql: unicodestring;
  Begin
    _s_operatorSql := InternalNormalizeQueryOperator( _2_t_s_operator);

    If ( Variants.VarIsNull( _3_v_value)) Then Begin
      If ( _s_operatorSql = '=') Then Begin
        Result := _1_y_fieldRef.s_exprSql + ' IS NULL';
        Exit;
      End;

      If ( _s_operatorSql = '<>') Then Begin
        Result := _1_y_fieldRef.s_exprSql + ' IS NOT NULL';
        Exit;
      End;

      q4interruptions.assertRaise( False,
        _4_t_s_context + ' : comparaison NULL invalide avec cet operateur');
    End;

    { Nouvelle logique unifiée pour les champs TEXT }
    If ( InternalTryBuildTextPredicate( _1_y_fieldRef, _s_operatorSql, _3_v_value, Result)) Then Exit;

    { Cas général : INTEGER / DOUBLE / autres comparaisons directes }
    Result := _1_y_fieldRef.s_exprSql + ' ' + _s_operatorSql + ' ' + InternalVariantToSqlLiteral( _3_v_value);
  End;

Function InternalBuildPkSelect( Var _1_p_recordTable; Const _2_y_state: q4selection.Ty_selectionTableState; Const _3_p_field: Pointer; Const _4_t_s_operator: string;
  Const _5_v_value: variant; Const _6_b_fromSelection: boolean; Const _7_t_s_context: string): string;
  Var
    _y_fieldRef:      TQ4FieldResolution;
    _s_predicate:     string;
    _i_sourceTableId: int64;
  Begin
    _i_sourceTableId := q4DBschemaUse.getSourceTableId( _1_p_recordTable);
    _y_fieldRef := InternalResolveField( _i_sourceTableId, _1_p_recordTable, _3_p_field, _7_t_s_context);
    _s_predicate := InternalBuildPredicateSql( _y_fieldRef, _4_t_s_operator, _5_v_value, _7_t_s_context);

    Result :=
      'SELECT src.' + _2_y_state.t_pkFieldName + ' AS q4pk' + ' FROM ' + _2_y_state.t_sourceTableName + ' src';

    If ( _6_b_fromSelection) Then Result := Result + InternalBuildCurrentSelectionJoin( _2_y_state);

    If ( _y_fieldRef.s_joinSql <> '') Then Result := Result + _y_fieldRef.s_joinSql;

    Result := Result + ' WHERE ' + _s_predicate;
  End;

Procedure InternalAppendQuerySet( Var _1_p_recordTable; Const _2_e_i_idx: int64; Const _3_t_s_context: string; Const _4_t_s_conjunction: string;
  Const _5_p_field: Pointer; Const _6_t_s_operator: string; Const _7_v_value: variant; Const _8_b_fromSelection: boolean);
  Var
    _s_piece:    string;
    _s_compound: string;
  Begin
    _s_piece := InternalBuildPkSelect( _1_p_recordTable, q4selection.ty_selectionTables[_2_e_i_idx], _5_p_field, _6_t_s_operator, _7_v_value, _8_b_fromSelection, _3_t_s_context);
    _s_compound := q4selection.ty_selectionTables[_2_e_i_idx].t_pendingWhereSQL;

    If ( _s_compound = '') Then Begin
      q4interruptions.assertRaise( ( _4_t_s_conjunction = '') or ( _4_t_s_conjunction = '&'),
        _3_t_s_context + ' : premiere conjonction invalide');
      q4selection.ty_selectionTables[_2_e_i_idx].t_pendingWhereSQL := _s_piece;
      Exit;
    End;

    q4interruptions.assertRaise( _4_t_s_conjunction <> '',
      _3_t_s_context + ' : conjonction obligatoire sur une clause suivante');

    If ( _4_t_s_conjunction = '&') Then Begin
      q4selection.ty_selectionTables[_2_e_i_idx].t_pendingWhereSQL :=
        _s_compound + ' INTERSECT ' + _s_piece;
      Exit;
    End;

    If ( _4_t_s_conjunction = '|') Then Begin
      q4selection.ty_selectionTables[_2_e_i_idx].t_pendingWhereSQL :=
        _s_compound + ' UNION ' + _s_piece;
      Exit;
    End;

    If ( _4_t_s_conjunction = '#') Then Begin
      q4selection.ty_selectionTables[_2_e_i_idx].t_pendingWhereSQL :=
        _s_compound + ' EXCEPT ' + _s_piece;
      Exit;
    End;

    q4interruptions.assertRaise( False,
      _3_t_s_context + ' : conjonction non geree');
  End;

Procedure InternalPrepareFreshBuild( Const _1_e_i_idx: int64);
  Begin
    q4selection.ty_selectionTables[_1_e_i_idx].t_pendingWhereSQL := '';
    q4selection.ty_selectionTables[_1_e_i_idx].t_pendingOrderBySQL := '';
    q4selection.ty_selectionTables[_1_e_i_idx].e_pendingDestinationKind := gy_queryDestination.e_kind;
    q4selection.ty_selectionTables[_1_e_i_idx].t_pendingDestinationName := gy_queryDestination.s_name;
    q4selection.ty_selectionTables[_1_e_i_idx].e_pendingQueryLimit := gi_queryLimit;
    q4selection.ty_selectionTables[_1_e_i_idx].e_pendingReduceCount := 0;
  End;

Procedure InternalResetBuildState( Const _1_e_i_idx: int64; Const _2_e_newState: q4selection.Tq4selectionBuildState);
  Begin
    q4selection.ty_selectionTables[_1_e_i_idx].e_buildState := _2_e_newState;
    q4selection.ty_selectionTables[_1_e_i_idx].t_pendingWhereSQL := '';
    q4selection.ty_selectionTables[_1_e_i_idx].t_pendingOrderBySQL := '';
    q4selection.ty_selectionTables[_1_e_i_idx].e_pendingDestinationKind := qdkCurrentSelection;
    q4selection.ty_selectionTables[_1_e_i_idx].t_pendingDestinationName := '';
    q4selection.ty_selectionTables[_1_e_i_idx].e_pendingQueryLimit := 0;
    q4selection.ty_selectionTables[_1_e_i_idx].e_pendingReduceCount := 0;
  End;

Procedure InternalAssertCanStartQuery( Const _1_e_i_idx: int64; Const _2_t_s_context: string; Const _3_b_fromSelection: boolean);
  Var
    _s_currentKind: string;
    _s_otherKind:   string;
  Begin
    If ( _3_b_fromSelection) Then Begin
      _s_currentKind := 'QUERY SELECTION';
      _s_otherKind := 'QUERY';
    End Else Begin
      _s_currentKind := 'QUERY';
      _s_otherKind := 'QUERY SELECTION';
    End;

    Case q4selection.ty_selectionTables[_1_e_i_idx].e_buildState Of
      sbsNone, sbsMaterialized: Begin
        InternalPrepareFreshBuild( _1_e_i_idx);
        If ( _3_b_fromSelection) Then q4selection.ty_selectionTables[_1_e_i_idx].e_buildState := sbsPendingQuerySelection
        Else
          q4selection.ty_selectionTables[_1_e_i_idx].e_buildState := sbsPendingQuery;
      End;

      sbsPendingQuery: q4interruptions.assertRaise( not _3_b_fromSelection,
          _2_t_s_context + ' : QUERY deja en cours ; ' + _s_otherKind + ' interdit');

      sbsPendingQuerySelection: q4interruptions.assertRaise( _3_b_fromSelection,
          _2_t_s_context + ' : QUERY SELECTION deja en cours ; ' + _s_otherKind + ' interdit');

      sbsPendingQueryOrder: q4interruptions.assertRaise( False,
          _2_t_s_context + ' : ORDER BY(*) deja en cours apres QUERY ; ' + _s_currentKind + ' interdit');

      sbsPendingQuerySelectionOrder: q4interruptions.assertRaise( False,
          _2_t_s_context + ' : ORDER BY(*) deja en cours apres QUERY SELECTION ; ' + _s_currentKind + ' interdit');

      sbsPendingAllRecordsOrder: q4interruptions.assertRaise( False,
          _2_t_s_context + ' : ALL RECORDS(*) ne peut etre suivi que par ORDER BY');
      Else q4interruptions.assertRaise( False,
          _2_t_s_context + ' : build state invalide');
    End;
  End;

Procedure InternalAssertCanFinalizeQuery( Const _1_e_i_idx: int64; Const _2_t_s_context: string; Const _3_b_fromSelection: boolean);
  Begin
    Case q4selection.ty_selectionTables[_1_e_i_idx].e_buildState Of
      sbsPendingQuery: q4interruptions.assertRaise( not _3_b_fromSelection,
          _2_t_s_context + ' : build QUERY attendu');

      sbsPendingQuerySelection: q4interruptions.assertRaise( _3_b_fromSelection,
          _2_t_s_context + ' : build QUERY SELECTION attendu');
      Else q4interruptions.assertRaise( False,
          _2_t_s_context + ' : aucun build QUERY compatible en cours');
    End;
  End;

Procedure InternalAssertCanAppendOrder( Const _1_e_i_idx: int64; Const _2_t_s_context: string);
  Begin
    Case q4selection.ty_selectionTables[_1_e_i_idx].e_buildState Of
      sbsPendingAllRecordsOrder: ;

      sbsPendingQuery: q4selection.ty_selectionTables[_1_e_i_idx].e_buildState := sbsPendingQueryOrder;

      sbsPendingQuerySelection: q4selection.ty_selectionTables[_1_e_i_idx].e_buildState := sbsPendingQuerySelectionOrder;

      sbsPendingQueryOrder, sbsPendingQuerySelectionOrder: ;

      sbsNone, sbsMaterialized: q4interruptions.assertRaise( False,
          _2_t_s_context + ' : aucun build en cours');
      Else q4interruptions.assertRaise( False,
          _2_t_s_context + ' : build state invalide');
    End;
  End;

Procedure InternalAppendOrderClause( Var _1_p_recordTable; Const _2_e_i_idx: int64; Const _3_p_field: Pointer; Const _4_t_s_direction: string);
  Var
    _y_fieldRef: TQ4FieldResolution;
    _s_piece:    string;
    _i_sourceTableId: int64;
  Begin
    _i_sourceTableId := q4DBschemaUse.getSourceTableId( _1_p_recordTable);
    _y_fieldRef := InternalResolveField( _i_sourceTableId, _1_p_recordTable, _3_p_field, 'q4queries.orderBy');

    q4interruptions.assertRaise( _y_fieldRef.b_isLocal,
      'q4queries.orderBy : tri sur champ lie non implemente dans cette version');

    _s_piece := _y_fieldRef.s_exprSql + ' ' + InternalDirectionToSql( _4_t_s_direction);

    If ( q4selection.ty_selectionTables[_2_e_i_idx].t_pendingOrderBySQL = '') Then Begin
      q4selection.ty_selectionTables[_2_e_i_idx].t_pendingOrderBySQL := _s_piece;
      Exit;
    End;

    q4selection.ty_selectionTables[_2_e_i_idx].t_pendingOrderBySQL :=
      q4selection.ty_selectionTables[_2_e_i_idx].t_pendingOrderBySQL + ', ' + _s_piece;
  End;

Function InternalComputeEffectiveLimit( Const _1_e_i_queryLimit, _2_e_i_reduceCount: int64): int64;
  Begin
    Result := 0;

    If ( ( _1_e_i_queryLimit > 0) and ( _2_e_i_reduceCount > 0)) Then Begin
      If ( _1_e_i_queryLimit < _2_e_i_reduceCount) Then Result := _1_e_i_queryLimit
      Else
        Result := _2_e_i_reduceCount;
      Exit;
    End;

    If ( _1_e_i_queryLimit > 0) Then Begin
      Result := _1_e_i_queryLimit;
      Exit;
    End;

    If ( _2_e_i_reduceCount > 0) Then Begin
      Result := _2_e_i_reduceCount;
      Exit;
    End;
  End;

Function InternalBuildFinalPkSql( Var _1_p_recordTable; Const _2_e_i_idx: int64; Const _3_t_s_context: string): string;
  Var
    _s_setSql:   string;
    _s_finalSql: string;
    _i_effectiveLimit: int64;
  Begin
    _s_setSql := q4selection.ty_selectionTables[_2_e_i_idx].t_pendingWhereSQL;

    If ( q4selection.ty_selectionTables[_2_e_i_idx].e_buildState = sbsPendingAllRecordsOrder) Then _s_setSql :=
        'SELECT src.' + q4selection.ty_selectionTables[_2_e_i_idx].t_pkFieldName + ' AS q4pk' + ' FROM ' + q4selection.ty_selectionTables[_2_e_i_idx].t_sourceTableName + ' src';

    q4interruptions.assertRaise( _s_setSql <> '',
      _3_t_s_context + ' : expression de set vide');

    _s_finalSql :=
      'SELECT src.' + q4selection.ty_selectionTables[_2_e_i_idx].t_pkFieldName + ' AS q4pk' + ' FROM ' + q4selection.ty_selectionTables[_2_e_i_idx].t_sourceTableName +
      ' src' + ' JOIN (' + _s_setSql + ') q4set' + ' ON q4set.q4pk = src.' + q4selection.ty_selectionTables[_2_e_i_idx].t_pkFieldName;

    If ( q4selection.ty_selectionTables[_2_e_i_idx].t_pendingOrderBySQL <> '') Then _s_finalSql := _s_finalSql + ' ORDER BY ' + q4selection.ty_selectionTables[_2_e_i_idx].t_pendingOrderBySQL;

    _i_effectiveLimit := InternalComputeEffectiveLimit( q4selection.ty_selectionTables[_2_e_i_idx].e_pendingQueryLimit, q4selection.ty_selectionTables[_2_e_i_idx].e_pendingReduceCount);

    If ( _i_effectiveLimit > 0) Then _s_finalSql := _s_finalSql + ' LIMIT ' + SysUtils.IntToStr( _i_effectiveLimit);

    Result := _s_finalSql;
  End;

Procedure InternalDeleteResultNo( Const _1_e_i_idx: int64; Const _2_e_i_resultNo: int64);
  Begin
    If ( _2_e_i_resultNo <= 0) Then Exit;

    q4selectionTablesCore.clearSelectionResultNo(
      q4selection.ty_selectionTables[_1_e_i_idx].t_tempTableName,
      _2_e_i_resultNo
      );
  End;

Procedure InternalMaterializeIntoCurrentSelection( Var _1_p_recordTable; Const _2_e_i_idx: int64; Const _3_t_s_selectPkSql: string);
  Var
    _i_newResultNo: int64;
    _i_oldCurrentResultNo: int64;
    _i_pos: int64;
  Begin
    _i_newResultNo := q4selection.ty_selectionTables[_2_e_i_idx].e_nextResultNo;
    _i_oldCurrentResultNo := q4selection.ty_selectionTables[_2_e_i_idx].e_currentResultNo;

    _i_pos := q4selectionTablesCore.materializePkSelectToSelectionTable( _3_t_s_selectPkSql, q4selection.ty_selectionTables[_2_e_i_idx].t_tempTableName,
      q4selection.ty_selectionTables[_2_e_i_idx].t_pkFieldName, _i_newResultNo);

    If ( _i_oldCurrentResultNo > 0) Then q4selectionTablesCore.clearSelectionResultNo(
        q4selection.ty_selectionTables[_2_e_i_idx].t_tempTableName,
        _i_oldCurrentResultNo
        );

    q4selection.ty_selectionTables[_2_e_i_idx].e_currentResultNo := _i_newResultNo;
    Inc( q4selection.ty_selectionTables[_2_e_i_idx].e_nextResultNo);
    q4selection.ty_selectionTables[_2_e_i_idx].e_recordCount := _i_pos;
    q4selection.ty_selectionTables[_2_e_i_idx].b_isEmpty := ( _i_pos = 0);
    q4selection.ty_selectionTables[_2_e_i_idx].e_currentPos := 0;
    q4selection.ty_selectionTables[_2_e_i_idx].e_buildState := sbsMaterialized;

    q4RecordLocking.unloadRecord( _1_p_recordTable);
    If ( _i_pos > 0) Then q4selection.gotoSelectedRecord( _1_p_recordTable, 1);
  End;

Procedure InternalMaterializeIntoAlias( Const _1_e_i_idx: int64; Const _2_t_s_selectPkSql: string);
  Var
    _e_aliasKind: Tq4selectionAliasKind;
    _e_scope:     Tq4selectionTableScope;
    _t_targetTableName: string;
    _e_resultNo:  int64;
  Begin
    q4interruptions.assertRaise(
      SysUtils.Trim( q4selection.ty_selectionTables[_1_e_i_idx].t_pendingDestinationName) <> '',
      'q4queries : nom de destination vide'
      );

    If ( q4selection.ty_selectionTables[_1_e_i_idx].e_pendingDestinationKind = qdkSet) Then _e_aliasKind := qsakSet
    Else
      _e_aliasKind := qsakNamedSelection;

    _e_scope := q4setsAndNamedSelectionsCore.AliasScope( q4selection.ty_selectionTables[_1_e_i_idx].t_pendingDestinationName);

    _t_targetTableName := q4selectionTablesCore.buildSelectionTableName( _e_scope, q4selection.ty_selectionTables[_1_e_i_idx].t_sourceTableName);

    q4selectionTablesCore.ensureSelectionTable(
      _e_scope,
      _t_targetTableName,
      q4selection.ty_selectionTables[_1_e_i_idx].t_pkFieldName,
      q4selection.ty_selectionTables[_1_e_i_idx].t_pkTypeSQL
      );

    If ( _e_scope = qstsShared) Then _e_resultNo := q4setsAndNamedSelectionsCore.allocateSharedResultNo
    Else
      _e_resultNo := q4setsAndNamedSelectionsCore.allocateLocalResultNo( q4selection.ty_selectionTables[_1_e_i_idx].e_nextResultNo);

    q4selectionTablesCore.materializePkSelectToSelectionTable(
      _2_t_s_selectPkSql,
      _t_targetTableName,
      q4selection.ty_selectionTables[_1_e_i_idx].t_pkFieldName,
      _e_resultNo
      );

    q4setsAndNamedSelectionsCore.saveSelectionAlias(
      q4selection.ty_selectionTables[_1_e_i_idx].e_sourceTableId,
      q4selection.ty_selectionTables[_1_e_i_idx].t_sourceTableName,
      _e_aliasKind,
      q4selection.ty_selectionTables[_1_e_i_idx].t_pendingDestinationName,
      _e_resultNo
      );
  End;

Procedure InternalStoreIntoFixedVariable( Const _1_t_s_selectPkSql: string);
  Begin
    gi_lastQueryResultCount := InternalCountPkSelect( _1_t_s_selectPkSql);
  End;

Procedure InternalFinalizeDestination( Var _1_p_recordTable; Const _2_e_i_idx: int64; Const _3_t_s_selectPkSql: string; Const _4_t_s_context: string);
  Begin
    Case q4selection.ty_selectionTables[_2_e_i_idx].e_pendingDestinationKind Of
      qdkCurrentSelection: InternalMaterializeIntoCurrentSelection( _1_p_recordTable, _2_e_i_idx, _3_t_s_selectPkSql);

      qdkSet, qdkNamedSelection: InternalMaterializeIntoAlias( _2_e_i_idx, _3_t_s_selectPkSql);

      qdkVariable: InternalStoreIntoFixedVariable( _3_t_s_selectPkSql);
      Else q4interruptions.assertRaise( False,
          _4_t_s_context + ' : destination de requete invalide');
    End;
  End;

Procedure InternalFinalizeBuild( Var _1_p_recordTable; Const _2_e_i_idx: int64; Const _3_t_s_context: string; Const _4_b_showEQP: boolean = False);
  Var
    _s_sql: string;
  Begin
    q4interruptions.assertRaise(
      q4selection.ty_selectionTables[_2_e_i_idx].e_buildState in [sbsPendingQuery, sbsPendingQuerySelection, sbsPendingQueryOrder, sbsPendingQuerySelectionOrder, sbsPendingAllRecordsOrder],
      _3_t_s_context + ' : aucun build en cours');

    _s_sql := InternalBuildFinalPkSql( _1_p_recordTable, _2_e_i_idx, _3_t_s_context);

    gs_lastQueryPlan := _s_sql;
    gs_lastQueryPath := q4selection.ty_selectionTables[_2_e_i_idx].t_sourceTableName;

    If ( _4_b_showEQP) Then InternalShowExplainQueryPlan( _s_sql);

    InternalFinalizeDestination( _1_p_recordTable, _2_e_i_idx, _s_sql, _3_t_s_context);
    InternalResetBuildState( _2_e_i_idx, sbsMaterialized);
  End;

Procedure InternalQuery( Var _1_p_recordTable; Const _2_t_s_conjunction: string; Const _3_p_field: Pointer; Const _4_t_s_operator: string; Const _5_v_value: variant;
  Const _6_t_s_flag: string; Const _7_b_fromSelection: boolean; Const _8_t_s_context: string);
  Var
    _i_idx:      int64;
    _s_normConjunction: string;
    _s_normFlag: string;
  Begin
    _i_idx := InternalGetOrCreateSelectionTableStateIndex( _1_p_recordTable);
    _s_normConjunction := InternalNormalizeConjunction( _2_t_s_conjunction);
    _s_normFlag := InternalNormalizeContinuationFlag( _6_t_s_flag);

    InternalAssertCanStartQuery( _i_idx, _8_t_s_context, _7_b_fromSelection);
    InternalAppendQuerySet( _1_p_recordTable, _i_idx, _8_t_s_context, _s_normConjunction, _3_p_field, _4_t_s_operator, _5_v_value, _7_b_fromSelection);

    If ( _s_normFlag = '*') Then Exit;

    InternalAssertCanFinalizeQuery( _i_idx, _8_t_s_context, _7_b_fromSelection);
    InternalFinalizeBuild( _1_p_recordTable, _i_idx, _8_t_s_context, InternalIsEQPFlag( _s_normFlag));
  End;

Procedure InternalFinalizeQueryOnly( Var _1_p_recordTable; Const _2_b_fromSelection: boolean; Const _3_t_s_context: string);
  Var
    _i_idx: int64;
  Begin
    _i_idx := InternalGetOrCreateSelectionTableStateIndex( _1_p_recordTable);
    InternalAssertCanFinalizeQuery( _i_idx, _3_t_s_context, _2_b_fromSelection);
    InternalFinalizeBuild( _1_p_recordTable, _i_idx, _3_t_s_context);
  End;

Procedure InternalOrderBy( Var _1_p_recordTable; Const _2_p_field: Pointer; Const _3_t_s_direction: string; Const _4_t_s_flag: string);
  Var
    _i_idx:      int64;
    _s_normDirection: string;
    _s_normFlag: string;
  Begin
    _i_idx := InternalGetOrCreateSelectionTableStateIndex( _1_p_recordTable);
    _s_normDirection := InternalNormalizeOrderDirection( _3_t_s_direction);
    _s_normFlag := InternalNormalizeContinuationFlag( _4_t_s_flag);

    InternalAssertCanAppendOrder( _i_idx, 'q4queries.orderBy');
    InternalAppendOrderClause( _1_p_recordTable, _i_idx, _2_p_field, _s_normDirection);

    If ( _s_normFlag = '*') Then Exit;

    InternalFinalizeBuild( _1_p_recordTable, _i_idx, 'q4queries.orderBy', InternalIsEQPFlag( _s_normFlag));
  End;

Procedure InternalFinalizeOrderOnly( Var _1_p_recordTable);
  Var
    _i_idx: int64;
  Begin
    _i_idx := InternalGetOrCreateSelectionTableStateIndex( _1_p_recordTable);

    q4interruptions.assertRaise(
      q4selection.ty_selectionTables[_i_idx].e_buildState in [sbsPendingAllRecordsOrder, sbsPendingQueryOrder, sbsPendingQuerySelectionOrder],
      'q4queries.orderBy : aucun build ORDER compatible en cours');

    q4interruptions.assertRaise(
      q4selection.ty_selectionTables[_i_idx].t_pendingOrderBySQL <> '',
      'q4queries.orderBy : aucun champ de tri fourni'
      );

    InternalFinalizeBuild( _1_p_recordTable, _i_idx, 'q4queries.orderBy');
  End;

Procedure InternalSetQueryLimit( Const _1_e_i_limit: int64);
  Begin
    q4interruptions.assertRaise( _1_e_i_limit >= 0,
      'q4queries.setQueryLimit : limite negative');
    gi_queryLimit := _1_e_i_limit;
  End;

Function InternalGetQueryLimit: int64;
  Begin
    Result := gi_queryLimit;
  End;

Procedure InternalSetQueryDestination( Const _1_e_kind: TQ4QueryDestinationKind; Const _2_t_s_name: string);
  Begin
    Case _1_e_kind Of
      qdkCurrentSelection: q4interruptions.assertRaise( LazUTF8.UTF8Trim( _2_t_s_name) = '',
          'q4queries.setQueryDestination : nom interdit pour CurrentSelection');

      qdkSet, qdkNamedSelection: q4interruptions.assertRaise( LazUTF8.UTF8Trim( _2_t_s_name) <> '',
          'q4queries.setQueryDestination : nom obligatoire');

      qdkVariable: q4interruptions.assertRaise( LazUTF8.UTF8Trim( _2_t_s_name) = '',
          'q4queries.setQueryDestination : nom interdit pour Variable ; utilisation de gi_lastQueryResultCount uniquement');
      Else q4interruptions.assertRaise( False,
          'q4queries.setQueryDestination : destination invalide');
    End;

    gy_queryDestination.e_kind := _1_e_kind;
    gy_queryDestination.s_name := LazUTF8.UTF8Trim( _2_t_s_name);
  End;

Procedure InternalResetQueryDestination;
  Begin
    gy_queryDestination.e_kind := qdkCurrentSelection;
    gy_queryDestination.s_name := '';
  End;

Function InternalGetQueryDestination: TQ4QueryDestination;
  Begin
    Result := gy_queryDestination;
  End;

Procedure query( Var _1_p_recordTable); overload;
  Begin
    InternalEnsureProcessState;
    InternalFinalizeQueryOnly( _1_p_recordTable, False, 'q4queries.query');
  End;

Procedure query( Var _1_p_recordTable; Const _2_t_s_conjunction: string; Const _3_p_field: Pointer; Const _4_t_s_operator: string; Const _5_v_value: variant;
  Const _6_t_s_flag: string = ''); overload;
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);
    InternalEnsureProcessState;
    InternalQuery( _1_p_recordTable, _2_t_s_conjunction, _3_p_field, _4_t_s_operator, _5_v_value, _6_t_s_flag, False, 'q4queries.query');
  End;

Procedure querySelection( Var _1_p_recordTable); overload;
  Begin
    InternalEnsureProcessState;
    InternalFinalizeQueryOnly( _1_p_recordTable, True, 'q4queries.querySelection');
  End;

Procedure querySelection( Var _1_p_recordTable; Const _2_t_s_conjunction: string; Const _3_p_field: Pointer; Const _4_t_s_operator: string; Const _5_v_value: variant;
  Const _6_t_s_flag: string = ''); overload;
  Begin
    InternalEnsureProcessState;
    InternalQuery( _1_p_recordTable, _2_t_s_conjunction, _3_p_field, _4_t_s_operator, _5_v_value, _6_t_s_flag, True, 'q4queries.querySelection');
  End;

Procedure orderBy( Var _1_p_recordTable); overload;
  Begin
    InternalEnsureProcessState;
    InternalFinalizeOrderOnly( _1_p_recordTable);
  End;

Procedure orderBy( Var _1_p_recordTable; Const _2_p_field: Pointer; Const _3_t_s_direction: string; Const _4_t_s_flag: string = ''); overload;
  Begin
    InternalEnsureProcessState;
    InternalOrderBy( _1_p_recordTable, _2_p_field, _3_t_s_direction, _4_t_s_flag);
  End;

Procedure queryAndLock( Var _1_p_recordTable; Const _2_t_s_conjunction: string; Const _3_p_field: Pointer; Const _4_t_s_operator: string; Const _5_v_value: variant; Const _6_t_s_flag: string = '');
  Begin
    InternalEnsureProcessState;
    q4interruptions.assertRaise( False,
      'q4queries.queryAndLock : TODO: non implemente');
  End;

Procedure setQueryLimit( Const _1_e_i_limit: int64);
  Begin
    InternalEnsureProcessState;
    InternalSetQueryLimit( _1_e_i_limit);
  End;

Function getQueryLimit: int64;
  Begin
    InternalEnsureProcessState;
    Result := InternalGetQueryLimit;
  End;

Procedure resetQueryDestination;
  Begin
    InternalEnsureProcessState;
    InternalResetQueryDestination;
  End;

Procedure setQueryDestination( Const _1_e_kind: TQ4QueryDestinationKind; Const _2_t_s_name: string = '');
  Begin
    InternalEnsureProcessState;
    InternalSetQueryDestination( _1_e_kind, _2_t_s_name);
  End;

Function getQueryDestination: TQ4QueryDestination;
  Begin
    InternalEnsureProcessState;
    Result := InternalGetQueryDestination;
  End;

Function describeQueryExecution: string;
  Begin
    InternalEnsureProcessState;
    Result := gs_lastQueryPlan;
  End;

Function lastQueryPlan: string;
  Begin
    InternalEnsureProcessState;
    Result := gs_lastQueryPlan;
  End;

Function lastQueryPath: string;
  Begin
    InternalEnsureProcessState;
    Result := gs_lastQueryPath;
  End;

Initialization

End.
