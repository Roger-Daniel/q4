Unit q4json;

{$mode ObjFPC}{$H+}

{
q4JSON
version du 2026/04/26-02

Mapping 4D → q4JSON -> statut
Command Number 4D,    4D Command,                      q4 API,                           Statut
------------------------------------------------------------------------------------------------
1218,                JSON Parse,                       jsonParse,                        Partial,
1219,                JSON PARSE ARRAY,                 jsonParseArray,                   Partial,
1478,                JSON Resolve pointers,            *,                                Not supported,
1217,                JSON Stringify,                   jsonStringify,                    OK,
1228,                JSON Stringify array,             jsonStringifyArray,               Partial,
1235,                JSON TO SELECTION,                jsonToSelection,                  OK,
1456,                JSON Validate,                    jsonValidate,                     Partial,
1234,                Selection to JSON,                selectionToJSON,                  Partial,

Doc: https://developer.4d.com/docs/21/commands/theme/JSON

  Notes
  -----
  - Les types JSON transverses sont portés par q4coreLanguage.
  - La résolution nom JSON -> champ est assurée via q4DBschemaUse.
  - jsonResolvePointers n'est pas supporté en q4.
  - Le support exact du paramètre * pour JSON Parse (__symbols) reste à faire.
  - jsonParseArray / jsonStringifyArray couvrent actuellement les tableaux
    texte, réel, booléen et objet.
  - jsonToSelection fonctionne sur la sélection courante en s'appuyant sur
    la même logique générale que q4arrays.
  - selectionToJSON exporte la sélection courante ; les champs explicites
    peuvent être locaux ou liés via un chemin Many -> One résolu par
    q4coreRelations. Le support reste partiel tant que le template 4D
    complet et certains raffinements ne sont pas entièrement couverts.
}

Interface

Uses
  SysUtils,
  Variants,
  //fpjson,
  //jsonparser,
  q4coreLanguage;

Const
  Q4JSONTypeAuto = 0;
  Q4JSONTypeReal = 1;
  Q4JSONTypeText = 2;
  Q4JSONTypeDate = 4;
  Q4JSONTypeBoolean = 6;
  Q4JSONTypeLongint = 9;
  Q4JSONTypeTime = 11;
  Q4JSONTypeObject = 38;
  Q4JSONTypeCollection = 42;

Type
  { Sélection de champs pour Selection to JSON.
    LabelName vide = utiliser le nom natif du champ. }
  Tq4JSONSelectionField = Record
    LabelName: string;
    FieldPtr: Pointer;
  End;

Function jsonParse( Const _1_t_jsonString: string; Const _2_e_type: int64 = Q4JSONTypeAuto; Const _3_t_star: string = ''): variant;

Function jsonParseObject( Const _1_t_jsonString: string; Const _2_t_star: string = ''): Tq4JSONObject;

Function jsonParseCollection( Const _1_t_jsonString: string): Tq4JSONCollection;

Procedure jsonParseArray( Const _1_t_jsonString: string; Var _2_tt_values: Tq4TextArray); overload;
Procedure jsonParseArray( Const _1_t_jsonString: string; Var _2_tr_values: Tq4RealArray); overload;
Procedure jsonParseArray( Const _1_t_jsonString: string; Var _2_tb_values: Tq4BooleanArray); overload;
Procedure jsonParseArray( Const _1_t_jsonString: string; Var _2_to_values: Tq4ObjectArray); overload;

Function jsonStringify( Const _1_v_value: variant; Const _2_t_star: string = ''): string; overload;

Function jsonStringifyObject( Const _1_o_value: Tq4JSONObject; Const _2_t_star: string = ''): string;

Function jsonStringifyCollection( Const _1_o_c_value: Tq4JSONCollection; Const _2_t_star: string = ''): string;

Function jsonStringifyArray( Const _1_tt_values: Tq4TextArray; Const _2_t_star: string = ''): string; overload;

Function jsonStringifyArray( Const _1_tr_values: Tq4RealArray; Const _2_t_star: string = ''): string; overload;

Function jsonStringifyArray( Const _1_tb_values: Tq4BooleanArray; Const _2_t_star: string = ''): string; overload;

Function jsonStringifyArray( Const _1_to_values: Tq4ObjectArray; Const _2_t_star: string = ''): string; overload;

Function jsonResolvePointers( Const _1_o_object: Tq4JSONObject; Const _2_o_options: Tq4JSONObject = ''): Tq4JSONObject;

Function jsonValidate( Const _1_o_json: Tq4JSONObject; Const _2_o_schema: Tq4JSONSchema): Tq4JSONObject;

Procedure jsonToSelection( Var _1_p_recordTable; Const _2_o_c_jsonArray: Tq4JSONCollection);

Function selectionToJSON( Var _1_p_recordTable): Tq4JSONCollection; overload;
Function selectionToJSON( Var _1_p_recordTable; Const _2_ty_fields: Array Of Tq4JSONSelectionField): Tq4JSONCollection; overload;

Implementation

Uses
  Classes,
  DB,
  SQLDB,
  fpjson,
  jsonparser,
  q4interruptions,
  fpjson.schema.schema,
  fpjson.schema.loader,
  fpjson.schema.validator,
  metier_q4DBschemaBase,
  q4DBschemaUse,
  q4DBmanager,
  q4coreRelations,
  q4selection,
  q4selectionTablesCore,
  q4triggerRuntime,
  q4sets,
  q4RecordLocking,
  q4record;

Procedure RaiseTodo( Const _1_t_where, _2_t_note: string);
  Begin
    q4interruptions.assertRaise( False, _1_t_where + ': TODO q4JSON (' + _2_t_note + ')');
  End;

Function ParseJSONData( Const _1_t_jsonString: string): TJSONData;
  Begin
    q4interruptions.assertRaise(
      Trim( _1_t_jsonString) <> '',
      'q4JSON.ParseJSONData : JSON vide'
      );

    Result := GetJSON( _1_t_jsonString, True);
  End;

Procedure EnsureJSONType( Const _1_o_data: TJSONData; Const _2_e_expected: TJSONType; Const _3_t_where: string);
  Begin
    q4interruptions.assertRaise(
      Assigned( _1_o_data),
      _3_t_where + ' : donnée JSON non assignée'
      );

    q4interruptions.assertRaise(
      _1_o_data.JSONType = _2_e_expected,
      _3_t_where + ' : type JSON inattendu'
      );
  End;

Function CompactOrPretty( Const _1_o_data: TJSONData; Const _2_t_star: string): string;
  Begin
    If ( _2_t_star = '*') Then Result := _1_o_data.FormatJSON
    Else
      Result := _1_o_data.AsJSON;
  End;

Function JSONNumberToVariant( Const _1_o_data: TJSONData): variant;
  Var
    _t_value: string;
    _e_i64:   int64;
    _r_value: double;
  Begin
    _t_value := _1_o_data.AsJSON;

    If ( TryStrToInt64( _t_value, _e_i64)) Then Begin
      Result := _e_i64;
      Exit;
    End;

    If ( TryStrToFloat( _t_value, _r_value)) Then Begin
      Result := _r_value;
      Exit;
    End;

    Result := _t_value;
  End;

Function JSONDataToVariant( Const _1_o_data: TJSONData): variant;
  Begin
    Case _1_o_data.JSONType Of
      jtNumber: Result := JSONNumberToVariant( _1_o_data);

      jtString: Result := _1_o_data.AsString;

      jtBoolean: Result := _1_o_data.AsBoolean;

      jtNull: Result := Null;

      jtObject: Result := _1_o_data.AsJSON;

      jtArray: Result := _1_o_data.AsJSON;
      Else Result := _1_o_data.AsJSON;
    End;
  End;

Function CoerceParsedValue( Const _1_v_value: variant; Const _2_e_type: int64): variant;
  Begin
    Case _2_e_type Of
      Q4JSONTypeAuto: Result := _1_v_value;

      Q4JSONTypeReal: Result := VarAsType( _1_v_value, varDouble);

      Q4JSONTypeText: Result := VarToStr( _1_v_value);

      Q4JSONTypeDate: Result := VarToStr( _1_v_value);

      Q4JSONTypeBoolean: Result := VarAsType( _1_v_value, varBoolean);

      Q4JSONTypeLongint: Result := VarAsType( _1_v_value, varInt64);

      Q4JSONTypeTime: Result := VarToStr( _1_v_value);

      Q4JSONTypeObject: Result := VarToStr( _1_v_value);

      Q4JSONTypeCollection: Result := VarToStr( _1_v_value);
      Else Result := _1_v_value;
    End;
  End;

Function VariantToJSONText( Const _1_v_value: variant): string;
  Var
    _o_json: TJSONData;
    _e_type: int64;
  Begin
    If ( VarIsNull( _1_v_value)) Then Exit( 'null');

    _e_type := VarType( _1_v_value);

    Case _e_type Of
      varBoolean: Begin
        _o_json := TJSONBoolean.Create( _1_v_value);
        Try
          Result := _o_json.AsJSON;
        Finally
          _o_json.Free;
        End;
      End;

      varByte, varSmallint, varInteger, varShortInt, varWord, varLongWord, varInt64: Begin
        _o_json := TJSONIntegerNumber.Create( int64( _1_v_value));
        Try
          Result := _o_json.AsJSON;
        Finally
          _o_json.Free;
        End;
      End;

      varSingle, varDouble, varCurrency: Begin
        _o_json := TJSONFloatNumber.Create( double( _1_v_value));
        Try
          Result := _o_json.AsJSON;
        Finally
          _o_json.Free;
        End;
      End;
      Else Begin
        _o_json := TJSONString.Create( VarToStr( _1_v_value));
        Try
          Result := _o_json.AsJSON;
        Finally
          _o_json.Free;
        End;
      End;
    End;
  End;

Function jsonParse( Const _1_t_jsonString: string; Const _2_e_type: int64; Const _3_t_star: string): variant;
  Var
    _o_data: TJSONData;
  Begin
    _o_data := ParseJSONData( _1_t_jsonString);
    Try
    { Le support exact du * avec __symbols est laissé à une étape ultérieure.
      Pour l'instant, le paramètre est accepté mais non enrichi. }
      Result := CoerceParsedValue( JSONDataToVariant( _o_data), _2_e_type);
    Finally
      _o_data.Free;
    End;
  End;

Function jsonParseObject( Const _1_t_jsonString: string; Const _2_t_star: string): Tq4JSONObject;
  Var
    _o_data: TJSONData;
  Begin
    _o_data := ParseJSONData( _1_t_jsonString);
    Try
      EnsureJSONType( _o_data, jtObject, 'q4JSON.jsonParseObject');
      Result := CompactOrPretty( _o_data, _2_t_star);
    Finally
      _o_data.Free;
    End;
  End;

Function jsonParseCollection( Const _1_t_jsonString: string): Tq4JSONCollection;
  Var
    _o_data: TJSONData;
  Begin
    _o_data := ParseJSONData( _1_t_jsonString);
    Try
      EnsureJSONType( _o_data, jtArray, 'q4JSON.jsonParseCollection');
      Result := _o_data.AsJSON;
    Finally
      _o_data.Free;
    End;
  End;

Procedure jsonParseArray( Const _1_t_jsonString: string; Var _2_tt_values: Tq4TextArray);
  Var
    _o_data:  TJSONData;
    _o_array: TJSONArray;
    _e_i:     int64;
  Begin
    _o_data := ParseJSONData( _1_t_jsonString);
    Try
      EnsureJSONType( _o_data, jtArray, 'q4JSON.jsonParseArray(text)');
      _o_array := TJSONArray( _o_data);
      SetLength( _2_tt_values, _o_array.Count);

      For _e_i := 0 To _o_array.Count - 1 Do _2_tt_values[_e_i] := _o_array.Items[_e_i].AsString;
    Finally
      _o_data.Free;
    End;
  End;

Procedure jsonParseArray( Const _1_t_jsonString: string; Var _2_tr_values: Tq4RealArray);
  Var
    _o_data:  TJSONData;
    _o_array: TJSONArray;
    _e_i:     int64;
  Begin
    _o_data := ParseJSONData( _1_t_jsonString);
    Try
      EnsureJSONType( _o_data, jtArray, 'q4JSON.jsonParseArray(real)');
      _o_array := TJSONArray( _o_data);
      SetLength( _2_tr_values, _o_array.Count);

      For _e_i := 0 To _o_array.Count - 1 Do _2_tr_values[_e_i] := StrToFloat( _o_array.Items[_e_i].AsJSON);
    Finally
      _o_data.Free;
    End;
  End;

Procedure jsonParseArray( Const _1_t_jsonString: string; Var _2_tb_values: Tq4BooleanArray);
  Var
    _o_data:  TJSONData;
    _o_array: TJSONArray;
    _e_i:     int64;
  Begin
    _o_data := ParseJSONData( _1_t_jsonString);
    Try
      EnsureJSONType( _o_data, jtArray, 'q4JSON.jsonParseArray(boolean)');
      _o_array := TJSONArray( _o_data);
      SetLength( _2_tb_values, _o_array.Count);

      For _e_i := 0 To _o_array.Count - 1 Do _2_tb_values[_e_i] := _o_array.Items[_e_i].AsBoolean;
    Finally
      _o_data.Free;
    End;
  End;

Procedure jsonParseArray( Const _1_t_jsonString: string; Var _2_to_values: Tq4ObjectArray);
  Var
    _o_data:  TJSONData;
    _o_array: TJSONArray;
    _e_i:     int64;
  Begin
    _o_data := ParseJSONData( _1_t_jsonString);
    Try
      EnsureJSONType( _o_data, jtArray, 'q4JSON.jsonParseArray(object)');
      _o_array := TJSONArray( _o_data);
      SetLength( _2_to_values, _o_array.Count);

      For _e_i := 0 To _o_array.Count - 1 Do _2_to_values[_e_i] := _o_array.Items[_e_i].AsJSON;
    Finally
      _o_data.Free;
    End;
  End;

Function jsonStringify( Const _1_v_value: variant; Const _2_t_star: string): string;
  Var
    _o_data: TJSONData;
  Begin
    Result := VariantToJSONText( _1_v_value);

    If ( _2_t_star = '*') Then Begin
      _o_data := ParseJSONData( Result);
      Try
        Result := _o_data.FormatJSON;
      Finally
        _o_data.Free;
      End;
    End;
  End;

Function jsonStringifyObject( Const _1_o_value: Tq4JSONObject; Const _2_t_star: string): string;
  Var
    _o_data: TJSONData;
  Begin
    _o_data := ParseJSONData( _1_o_value);
    Try
      EnsureJSONType( _o_data, jtObject, 'q4JSON.jsonStringifyObject');
      Result := CompactOrPretty( _o_data, _2_t_star);
    Finally
      _o_data.Free;
    End;
  End;

Function jsonStringifyCollection( Const _1_o_c_value: Tq4JSONCollection; Const _2_t_star: string): string;
  Var
    _o_data: TJSONData;
  Begin
    _o_data := ParseJSONData( _1_o_c_value);
    Try
      EnsureJSONType( _o_data, jtArray, 'q4JSON.jsonStringifyCollection');
      Result := CompactOrPretty( _o_data, _2_t_star);
    Finally
      _o_data.Free;
    End;
  End;

Function jsonStringifyArray( Const _1_tt_values: Tq4TextArray; Const _2_t_star: string): string;
  Var
    _o_array: TJSONArray;
    _e_i:     int64;
  Begin
    _o_array := TJSONArray.Create;
    Try
      For _e_i := 0 To High( _1_tt_values) Do _o_array.Add( _1_tt_values[_e_i]);

      Result := CompactOrPretty( _o_array, _2_t_star);
    Finally
      _o_array.Free;
    End;
  End;

Function jsonStringifyArray( Const _1_tr_values: Tq4RealArray; Const _2_t_star: string): string;
  Var
    _o_array: TJSONArray;
    _e_i:     int64;
  Begin
    _o_array := TJSONArray.Create;
    Try
      For _e_i := 0 To High( _1_tr_values) Do _o_array.Add( _1_tr_values[_e_i]);

      Result := CompactOrPretty( _o_array, _2_t_star);
    Finally
      _o_array.Free;
    End;
  End;

Function jsonStringifyArray( Const _1_tb_values: Tq4BooleanArray; Const _2_t_star: string): string;
  Var
    _o_array: TJSONArray;
    _e_i:     int64;
  Begin
    _o_array := TJSONArray.Create;
    Try
      For _e_i := 0 To High( _1_tb_values) Do _o_array.Add( _1_tb_values[_e_i]);

      Result := CompactOrPretty( _o_array, _2_t_star);
    Finally
      _o_array.Free;
    End;
  End;

Function jsonStringifyArray( Const _1_to_values: Tq4ObjectArray; Const _2_t_star: string): string;
  Var
    _o_array: TJSONArray;
    _o_item:  TJSONData;
    _e_i:     int64;
  Begin
    _o_array := TJSONArray.Create;
    Try
      For _e_i := 0 To High( _1_to_values) Do Begin
        _o_item := ParseJSONData( _1_to_values[_e_i]);
        _o_array.Add( _o_item);
      End;

      Result := CompactOrPretty( _o_array, _2_t_star);
    Finally
      _o_array.Free;
    End;
  End;


Type
  Tq4ResolvedSelectionSource = Record
    SourceTableName: string;
    TempTableName: string;
    PkFieldName: string;
    PkTypeSQL: string;
    ResultNo: int64;
    RecordCount: int64;
  End;

  Tq4ResolvedSelectionToJSONField = Record
    LabelName: string;
    SQLExpression: string;
    JoinSQL: string;
  End;

  Tq4ResolvedSelectionToJSONFields = Array Of Tq4ResolvedSelectionToJSONField;

Procedure RaiseUnsupported( Const _1_t_where, _2_t_note: string);
  Begin
    q4interruptions.assertRaise( False, _1_t_where + ': unsupported q4JSON (' + _2_t_note + ')');
  End;

Function InternalFindSelectionTableStateIndex( Const _1_e_eSourceTableId: int64): int64;
  Var
    _e_i: int64;
  Begin
    Result := -1;
    For _e_i := 0 To System.High( q4selection.ty_selectionTables) Do If ( q4selection.ty_selectionTables[_e_i].e_sourceTableId = _1_e_eSourceTableId) Then Begin
        Result := _e_i;
        Exit;
      End;
  End;

Procedure InternalResolveSelectionTableMeta( Var _1_y_state: q4selection.Ty_selectionTableState);
  Var
    _y_table:  TTableMeta;
    _y_field:  TFieldMeta;
    _e_offset: int64;
  Begin
    q4interruptions.assertRaise(
      q4DBschemaUse.findTableMeta( _1_y_state.e_sourceTableId, _y_table),
      'q4JSON.InternalResolveSelectionTableMeta : table source introuvable'
      );

    _1_y_state.t_sourceTableName := _y_table.Name;
    _1_y_state.t_tempTableName := q4selectionTablesCore.buildSelectionTableName( qstsThread, _1_y_state.t_sourceTableName);
    _1_y_state.t_pkFieldName := '';
    _1_y_state.t_pkTypeSQL := '';

    For _e_offset := 0 To _y_table.FieldCount - 1 Do Begin
      q4interruptions.assertRaise(
        q4DBschemaUse.findFieldMetaAtTableOffset( _1_y_state.e_sourceTableId, _e_offset, _y_field),
        'q4JSON.InternalResolveSelectionTableMeta : champ introuvable'
        );

      If ( SysUtils.CompareText( _y_field.Name, _y_table.PrimaryKey) = 0) Then Begin
        _1_y_state.t_pkFieldName := _y_field.Name;
        _1_y_state.t_pkTypeSQL := _y_field.TypeSQL;
        Break;
      End;
    End;

    q4interruptions.assertRaise( _1_y_state.t_pkFieldName <> '',
      'q4JSON.InternalResolveSelectionTableMeta : champ PK introuvable');
    q4interruptions.assertRaise( _1_y_state.t_pkTypeSQL <> '',
      'q4JSON.InternalResolveSelectionTableMeta : type SQL PK introuvable');
  End;

Procedure InternalEnsureSelectionState( Var _1_p_recordTable; out _2_e_idx: int64);
  Var
    _e_sourceTableId: int64;
  Begin
    _e_sourceTableId := q4DBschemaUse.getSourceTableId( _1_p_recordTable);
    q4interruptions.assertRaise( _e_sourceTableId >= 0,
      'q4JSON.InternalEnsureSelectionState : _noTable invalide');

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

Function InternalResolveSelectionSourceCurrent( Var _1_p_recordTable; out _2_y_source: Tq4ResolvedSelectionSource): boolean;
  Var
    _e_idx: int64;
  Begin
    Result := False;

    _2_y_source.SourceTableName := '';
    _2_y_source.TempTableName := '';
    _2_y_source.PkFieldName := '';
    _2_y_source.PkTypeSQL := '';
    _2_y_source.ResultNo := 0;
    _2_y_source.RecordCount := 0;

    InternalEnsureSelectionState( _1_p_recordTable, _e_idx);

    q4interruptions.assertRaise(
      q4selection.ty_selectionTables[_e_idx].e_buildState in [sbsNone, sbsMaterialized],
      'q4JSON.InternalResolveSelectionSourceCurrent : sélection pending non matérialisée'
      );

    _2_y_source.SourceTableName := q4selection.ty_selectionTables[_e_idx].t_sourceTableName;
    _2_y_source.TempTableName := q4selection.ty_selectionTables[_e_idx].t_tempTableName;
    _2_y_source.PkFieldName := q4selection.ty_selectionTables[_e_idx].t_pkFieldName;
    _2_y_source.PkTypeSQL := q4selection.ty_selectionTables[_e_idx].t_pkTypeSQL;
    _2_y_source.ResultNo := q4selection.ty_selectionTables[_e_idx].e_currentResultNo;
    _2_y_source.RecordCount := q4selection.ty_selectionTables[_e_idx].e_recordCount;
    Result := True;
  End;

Procedure InternalEnsureCurrentSelectionResult( Var _1_y_state: q4selection.Ty_selectionTableState);
  Begin
    If ( _1_y_state.e_currentResultNo > 0) Then Exit;

    _1_y_state.e_currentResultNo := _1_y_state.e_nextResultNo;
    Inc( _1_y_state.e_nextResultNo);

    _1_y_state.e_currentPos := 0;
    _1_y_state.e_recordCount := 0;
    _1_y_state.b_isEmpty := True;
    _1_y_state.e_buildState := sbsMaterialized;
  End;

Function InternalReadPkFromRowId( Const _1_y_source: Tq4ResolvedSelectionSource; Const _2_e_eRowId: int64): variant;
  Var
    _o_query: TSQLQuery;
    _t_sql:   string;
  Begin
    Result := Null;

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := q4DBmanager.connect;
      _o_query.Transaction := q4DBmanager.connect.Transaction;

      _t_sql :=
        'SELECT ' + _1_y_source.PkFieldName + ' ' + 'FROM ' + _1_y_source.SourceTableName + ' ' + 'WHERE rowid = :rowid';

      _o_query.SQL.Text := _t_sql;
      _o_query.ParamByName( 'rowid').AsLargeInt := _2_e_eRowId;
      _o_query.Open;

      If ( not _o_query.EOF) Then Result := _o_query.Fields[0].Value;
    Finally
      _o_query.Free;
    End;
  End;

Procedure InternalAppendPkToCurrentSelection( Var _1_y_state: q4selection.Ty_selectionTableState; Const _2_y_vPk: variant; Const _3_e_ePos: integer);
  Var
    _o_query: TSQLQuery;
    _t_sql:   string;
  Begin
    q4interruptions.assertRaise( _1_y_state.e_currentResultNo > 0,
      'q4JSON.InternalAppendPkToCurrentSelection : resultNo courant invalide');

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := q4DBmanager.connect;
      _o_query.Transaction := q4DBmanager.connect.Transaction;

      _t_sql :=
        'INSERT INTO ' + _1_y_state.t_tempTableName + ' (' + _1_y_state.t_pkFieldName + ', pos, noResultat) ' + 'VALUES (:pk, :pos, :noResultat)';

      _o_query.SQL.Text := _t_sql;
      _o_query.ParamByName( 'pk').Value := _2_y_vPk;
      _o_query.ParamByName( 'pos').AsInteger := _3_e_ePos;
      _o_query.ParamByName( 'noResultat').AsInteger := _1_y_state.e_currentResultNo;
      _o_query.ExecSQL;
    Finally
      _o_query.Free;
    End;

    _1_y_state.e_recordCount := _3_e_ePos;
    _1_y_state.b_isEmpty := False;
    _1_y_state.e_buildState := sbsMaterialized;
  End;

Procedure InternalAddLockedRowId( Var _1_te_rowIds: Tq4Int64Array; Const _2_e_eRowId: int64);
  Var
    _e_len: int64;
  Begin
    If ( _2_e_eRowId <= 0) Then Exit;

    _e_len := Length( _1_te_rowIds);
    SetLength( _1_te_rowIds, _e_len + 1);
    _1_te_rowIds[_e_len] := _2_e_eRowId;
  End;

Procedure InternalFinalizeLockedSetFromRowIds( Var _1_p_recordTable; Const _2_te_rowIds: Tq4Int64Array);
  Var
    _te_rowIds: q4selection.Tq4Int64Array;
    _e_i: int64;
  Begin
    If ( Length( _2_te_rowIds) = 0) Then Begin
      q4sets.createEmptySet( _1_p_recordTable, 'LockedSet');
      Exit;
    End;

    SetLength( _te_rowIds, Length( _2_te_rowIds));
    For _e_i := Low( _2_te_rowIds) To High( _2_te_rowIds) Do _te_rowIds[_e_i] := _2_te_rowIds[_e_i];

    q4sets.createSetFromArray( _1_p_recordTable, _te_rowIds, 'LockedSet');
  End;

Function InternalJSONFieldValueToVariant( Const _1_o_item: TJSONData): variant;
  Begin
    Result := JSONDataToVariant( _1_o_item);
  End;

Function InternalFieldToJSONData( Const _1_o_field: TField): TJSONData;
  Begin
    If ( _1_o_field.IsNull) Then Exit( TJSONNull.Create);

    Case _1_o_field.DataType Of
      ftBoolean: Result := TJSONBoolean.Create( _1_o_field.AsBoolean);

      ftSmallint, ftInteger, ftWord, ftLargeint, ftAutoInc: Result := TJSONIntegerNumber.Create( _1_o_field.AsLargeInt);

      ftFloat, ftCurrency, ftBCD, ftFMTBcd, ftSingle, ftExtended: Result := TJSONFloatNumber.Create( _1_o_field.AsFloat);
      Else Result := TJSONString.Create( _1_o_field.AsString);
    End;
  End;

Function InternalFindFieldMetaByTableAndFieldNo( Const _1_e_eTableId: int64; Const _2_e_eFieldNo: int64; out _3_y_yField: TFieldMeta): boolean;
  Var
    _e_i: int64;
  Begin
    Result := False;
    System.FillChar( _3_y_yField, SizeOf( _3_y_yField), 0);

    For _e_i := 0 To System.High( Fields) Do If ( ( Fields[_e_i].TableRef = _1_e_eTableId) and ( Fields[_e_i].FieldNo = _2_e_eFieldNo)) Then Begin
        _3_y_yField := Fields[_e_i];
        Exit( True);
      End;
  End;

Function InternalFindTableNameBySourceTableId( Const _1_e_eTableId: int64; out _2_t_tTableName: string): boolean;
  Var
    _y_table: TTableMeta;
  Begin
    Result := False;
    _2_t_tTableName := '';

    If ( not q4DBschemaUse.findTableMeta( _1_e_eTableId, _y_table)) Then Exit;

    _2_t_tTableName := _y_table.Name;
    Result := True;
  End;

Procedure InternalBuildDefaultSelectionFields( Var _1_p_recordTable; out _2_o_resolved: Tq4ResolvedSelectionToJSONFields);
  Var
    _e_sourceTableId: int64;
    _y_table: TTableMeta;
    _y_field: TFieldMeta;
    _e_i:     int64;
  Begin
    _e_sourceTableId := q4DBschemaUse.getSourceTableId( _1_p_recordTable);
    q4interruptions.assertRaise(
      q4DBschemaUse.findTableMeta( _e_sourceTableId, _y_table),
      'q4JSON.InternalBuildDefaultSelectionFields : table introuvable'
      );

    SetLength( _2_o_resolved, _y_table.FieldCount);
    For _e_i := 0 To _y_table.FieldCount - 1 Do Begin
      q4interruptions.assertRaise(
        q4DBschemaUse.findFieldMetaAtTableOffset( _e_sourceTableId, _e_i, _y_field),
        'q4JSON.InternalBuildDefaultSelectionFields : champ introuvable'
        );
      _2_o_resolved[_e_i].LabelName := _y_field.Name;
      _2_o_resolved[_e_i].SQLExpression := 's.' + _y_field.Name;
      _2_o_resolved[_e_i].JoinSQL := '';
    End;
  End;

Procedure InternalResolveSelectionToJSONField( Var _1_p_recordTable; Const _1_y_request: Tq4JSONSelectionField; Const _2_e_fieldIndex: int64; out _3_y_resolved: Tq4ResolvedSelectionToJSONField);
  Var
    _e_sourceTableId: int64;
    _y_field: TFieldMeta;
    _y_targetTable: TTableMeta;
    _ty_path: q4coreRelations.Tq4RelationPath;
    _b_isLocalField: boolean;
    _e_i:     int64;
    _y_sourceLinkField: TFieldMeta;
    _y_targetLinkField: TFieldMeta;
    _t_targetTableName: string;
    _t_sourceAlias: string;
    _t_targetAlias: string;
    _t_aliasPrefix: string;
  Begin
    _3_y_resolved.LabelName := '';
    _3_y_resolved.SQLExpression := '';
    _3_y_resolved.JoinSQL := '';

    q4interruptions.assertRaise(
      _1_y_request.FieldPtr <> nil,
      'q4JSON.InternalResolveSelectionToJSONField : champ nul non supporté'
      );

    _e_sourceTableId := q4DBschemaUse.getSourceTableId( _1_p_recordTable);

    q4interruptions.assertRaise(
      q4coreRelations.resolveLinkedFieldPathForSourceTableId( _e_sourceTableId, _1_y_request.FieldPtr, _b_isLocalField, _y_field, _ty_path, _y_targetTable),
      'q4JSON.InternalResolveSelectionToJSONField : champ local ou lié many-to-one introuvable'
      );

    If ( Trim( _1_y_request.LabelName) = '') Then _3_y_resolved.LabelName := _y_field.Name
    Else
      _3_y_resolved.LabelName := _1_y_request.LabelName;

    If ( _b_isLocalField) Then Begin
      _3_y_resolved.SQLExpression := 's.' + _y_field.Name;
      Exit;
    End;

    q4interruptions.assertRaise(
      System.Length( _ty_path) > 0,
      'q4JSON.InternalResolveSelectionToJSONField : chemin many-to-one introuvable'
      );

    _t_aliasPrefix := 'f' + IntToStr( _2_e_fieldIndex) + 'j';

    For _e_i := 0 To System.High( _ty_path) Do Begin
      q4interruptions.assertRaise(
        InternalFindFieldMetaByTableAndFieldNo( _ty_path[_e_i].e_sourceTableId, _ty_path[_e_i].e_sourceFieldNo, _y_sourceLinkField),
        'q4JSON.InternalResolveSelectionToJSONField : champ source de lien introuvable'
        );
      q4interruptions.assertRaise(
        InternalFindFieldMetaByTableAndFieldNo( _ty_path[_e_i].e_targetTableId, _ty_path[_e_i].e_targetFieldNo, _y_targetLinkField),
        'q4JSON.InternalResolveSelectionToJSONField : champ cible de lien introuvable'
        );
      q4interruptions.assertRaise(
        InternalFindTableNameBySourceTableId( _ty_path[_e_i].e_targetTableId, _t_targetTableName),
        'q4JSON.InternalResolveSelectionToJSONField : table cible de lien introuvable'
        );

      If ( _e_i = 0) Then _t_sourceAlias := 's'
      Else
        _t_sourceAlias := _t_aliasPrefix + IntToStr( _e_i);

      _t_targetAlias := _t_aliasPrefix + IntToStr( _e_i + 1);

      _3_y_resolved.JoinSQL := _3_y_resolved.JoinSQL + ' LEFT JOIN ' + _t_targetTableName + ' ' + _t_targetAlias + ' ON ' + _t_sourceAlias + '.' +
        _y_sourceLinkField.Name + ' = ' + _t_targetAlias + '.' + _y_targetLinkField.Name + ' ';
    End;

    _3_y_resolved.SQLExpression := _t_aliasPrefix + IntToStr( System.Length( _ty_path)) + '.' + _y_field.Name;
  End;

Procedure InternalBuildExplicitSelectionFields( Var _1_p_recordTable; Const _2_ty_fields: Array Of Tq4JSONSelectionField; out _3_o_resolved: Tq4ResolvedSelectionToJSONFields);
  Var
    _e_i: int64;
  Begin
    SetLength( _3_o_resolved, Length( _2_ty_fields));

    For _e_i := 0 To High( _2_ty_fields) Do InternalResolveSelectionToJSONField( _1_p_recordTable, _2_ty_fields[_e_i], _e_i, _3_o_resolved[_e_i]);
  End;

Function InternalBuildSelectionToJSONSQL( Const _1_y_source: Tq4ResolvedSelectionSource; Const _2_o_resolved: Tq4ResolvedSelectionToJSONFields): string;
  Var
    _e_i: int64;
    _t_joinSQL: string;
  Begin
    Result := 'SELECT ';
    _t_joinSQL := '';

    For _e_i := 0 To High( _2_o_resolved) Do Begin
      If ( _e_i > 0) Then Result := Result + ', ';
      Result := Result + _2_o_resolved[_e_i].SQLExpression + ' AS f' + IntToStr( _e_i);
      _t_joinSQL := _t_joinSQL + _2_o_resolved[_e_i].JoinSQL;
    End;

    If ( Length( _2_o_resolved) = 0) Then Result := Result + 's.rowid AS f0';

    Result := Result + ' FROM ' + _1_y_source.SourceTableName + ' s ' + _t_joinSQL + 'INNER JOIN ' + _1_y_source.TempTableName + ' t ' + 'ON s.' +
      _1_y_source.PkFieldName + ' = t.' + _1_y_source.PkFieldName + ' ' + 'WHERE t.noResultat = :noResultat ' + 'ORDER BY t.pos';
  End;

//function jsonResolvePointers(const o_object: Tq4JSONObject;
//  const o_options: Tq4JSONObject): Tq4JSONObject;
//begin
//  RaiseUnsupported('q4JSON.jsonResolvePointers',
//    'JSON Resolve pointers n''est pas supporté en q4');
//  Result := o_object;
//end;
Function jsonResolvePointers( Const _1_o_object: Tq4JSONObject; Const _2_o_options: Tq4JSONObject): Tq4JSONObject;
  Begin
    RaiseUnsupported( 'q4JSON.jsonResolvePointers',
      'JSON Resolve pointers is not supported in q4.');
  End;

Function jsonValidate( Const _1_o_json: Tq4JSONObject; Const _2_o_schema: Tq4JSONSchema): Tq4JSONObject;
  Var
    _o_jsonData: TJSONData;
    _o_schemaData: TJSONData;
    _o_loader: TJsonSchemaLoader;
    _o_loadedSchema: TJsonSchema;
    _o_validator: TJSONSchemaValidator;
    _o_result: TJSONObject;
    _o_errors: TJSONArray;
    _o_message: TValidationMessage;
    _e_i:     int64;
    _b_valid: boolean;
  Begin
    _o_jsonData := ParseJSONData( _1_o_json);
    _o_schemaData := ParseJSONData( _2_o_schema);
    Try
      EnsureJSONType( _o_jsonData, jtObject, 'q4JSON.jsonValidate(json)');
      EnsureJSONType( _o_schemaData, jtObject, 'q4JSON.jsonValidate(schema)');

      _o_loader := TJsonSchemaLoader.Create( nil);
      _o_loadedSchema := TJsonSchema.Create;
      _o_validator := TJSONSchemaValidator.Create( nil);
      _o_result := TJSONObject.Create;
      Try
        Try
          _o_loader.ReadFromJSON( _o_loadedSchema, _o_schemaData);
        Except
          on E: Exception Do Begin
            q4interruptions.assertRaise( False,
              'q4JSON.jsonValidate : schéma JSON invalide : ' + E.Message);
            Result := '';
            Exit;
          End;
        End;

        _b_valid := _o_validator.ValidateJSON( _o_jsonData, _o_loadedSchema);

        _o_result.Add( 'success', _b_valid);

        If ( not _b_valid) Then Begin
          _o_errors := TJSONArray.Create;
          For _e_i := 0 To _o_validator.Messages.Count - 1 Do Begin
            _o_message := _o_validator.Messages[_e_i];
            If ( Assigned( _o_message)) Then _o_errors.Add( _o_message.AsJSON);
          End;
          _o_result.Add( 'errors', _o_errors);
        End;

        Result := _o_result.AsJSON;
      Finally
        _o_result.Free;
        _o_validator.Free;
        _o_loadedSchema.Free;
        _o_loader.Free;
      End;
    Finally
      _o_schemaData.Free;
      _o_jsonData.Free;
    End;
  End;

Procedure jsonToSelection( Var _1_p_recordTable; Const _2_o_c_jsonArray: Tq4JSONCollection);
  Var
    _o_data:    TJSONData;
    _o_array:   TJSONArray;
    _o_object:  TJSONObject;
    _y_source:  Tq4ResolvedSelectionSource;
    _p_runtime: Pq4recordRuntime;
    _te_lockedRowIds: Tq4Int64Array;
    _e_existingCount: int64;
    _e_count:   int64;
    _e_i, _e_j: int64;
    _e_bindingIndex: int64;
    _e_lockedRowId: int64;
    _b_tableReadonly: boolean;
    _v_pk:      variant;
    _v_value:   variant;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenCommand,
          'q4JSON.jsonToSelection interdit pendant un trigger'
          );

    _o_data := ParseJSONData( _2_o_c_jsonArray);
    Try
      EnsureJSONType( _o_data, jtArray, 'q4JSON.jsonToSelection');
      _o_array := TJSONArray( _o_data);

      InternalEnsureSelectionState( _1_p_recordTable, _e_i);
      InternalEnsureCurrentSelectionResult( q4selection.ty_selectionTables[_e_i]);

      q4interruptions.assertRaise(
        InternalResolveSelectionSourceCurrent( _1_p_recordTable, _y_source),
        'q4JSON.jsonToSelection : source de sélection introuvable'
        );

      _e_existingCount := _y_source.RecordCount;
      _b_tableReadonly := q4RecordLocking.readOnlyState( _1_p_recordTable);

      For _e_i := 0 To _o_array.Count - 1 Do Begin
        q4interruptions.assertRaise(
          _o_array.Items[_e_i].JSONType = jtObject,
          'q4JSON.jsonToSelection : chaque élément doit être un objet JSON'
          );
        _o_object := TJSONObject( _o_array.Items[_e_i]);

        If ( _e_i < _e_existingCount) Then Begin
          q4selection.gotoSelectedRecord( _1_p_recordTable, _e_i + 1);

          If ( not _p_runtime^._Loaded) Then Continue;

          If ( _b_tableReadonly) Then _p_runtime^._ReadWrite := True
          Else If ( not _p_runtime^._ReadWrite) Then Begin
            _e_lockedRowId := q4record.recordNumber( _1_p_recordTable);
            InternalAddLockedRowId( _te_lockedRowIds, _e_lockedRowId);
            Continue;
          End;
        End Else
          q4record.createRecord( _1_p_recordTable);

        For _e_j := 0 To _o_object.Count - 1 Do Begin
          _e_bindingIndex := q4DBschemaUse.findLocalBindingIndexByName( _1_p_recordTable, _o_object.Names[_e_j]);
          If ( _e_bindingIndex < 0) Then Continue;

          _v_value := InternalJSONFieldValueToVariant( _o_object.Items[_e_j]);
          q4record.writeBindingValue( _p_runtime^._Bindings[_e_bindingIndex], _v_value);
        End;

        q4record.saveRecord( _1_p_recordTable);

        If ( _e_i >= _e_existingCount) Then Begin
          _v_pk := InternalReadPkFromRowId( _y_source, _p_runtime^._RowId);
          InternalAppendPkToCurrentSelection( q4selection.ty_selectionTables[InternalFindSelectionTableStateIndex( q4DBschemaUse.getSourceTableId( _1_p_recordTable))], _v_pk, _e_i + 1);
        End;
      End;

      If ( _e_existingCount > _o_array.Count) Then _e_count := _e_existingCount
      Else
        _e_count := _o_array.Count;

      _e_i := InternalFindSelectionTableStateIndex( q4DBschemaUse.getSourceTableId( _1_p_recordTable));
      q4selection.ty_selectionTables[_e_i].e_recordCount := _e_count;
      q4selection.ty_selectionTables[_e_i].b_isEmpty := ( _e_count = 0);
      q4selection.ty_selectionTables[_e_i].e_currentPos := 0;
      q4selection.ty_selectionTables[_e_i].e_buildState := sbsMaterialized;

      q4RecordLocking.unloadRecord( _1_p_recordTable);
      InternalFinalizeLockedSetFromRowIds( _1_p_recordTable, _te_lockedRowIds);
    Finally
      _o_data.Free;
    End;
  End;

Function selectionToJSON( Var _1_p_recordTable): Tq4JSONCollection;
  Var
    _y_source: Tq4ResolvedSelectionSource;
    AResolved: Tq4ResolvedSelectionToJSONFields;
    _o_query:  TSQLQuery;
    _o_result: TJSONArray;
    _o_row:    TJSONObject;
    _o_value:  TJSONData;
    _t_sql:    string;
    _e_i:      int64;
  Begin
    InternalBuildDefaultSelectionFields( _1_p_recordTable, AResolved);

    q4interruptions.assertRaise(
      InternalResolveSelectionSourceCurrent( _1_p_recordTable, _y_source),
      'q4JSON.selectionToJSON : source de sélection introuvable'
      );

    _o_query := TSQLQuery.Create( nil);
    _o_result := TJSONArray.Create;
    Try
      _o_query.DataBase := q4DBmanager.connect;
      _o_query.Transaction := q4DBmanager.connect.Transaction;
      _t_sql := InternalBuildSelectionToJSONSQL( _y_source, AResolved);
      _o_query.SQL.Text := _t_sql;
      _o_query.ParamByName( 'noResultat').AsInteger := _y_source.ResultNo;
      _o_query.Open;

      While ( not _o_query.EOF) Do Begin
        _o_row := TJSONObject.Create;
        For _e_i := 0 To High( AResolved) Do Begin
          _o_value := InternalFieldToJSONData( _o_query.FieldByName( 'f' + IntToStr( _e_i)));
          _o_row.Add( AResolved[_e_i].LabelName, _o_value);
        End;
        _o_result.Add( _o_row);
        _o_query.Next;
      End;

      Result := _o_result.AsJSON;
      q4RecordLocking.unloadRecord( _1_p_recordTable);
    Finally
      _o_result.Free;
      _o_query.Free;
    End;
  End;

Function selectionToJSON( Var _1_p_recordTable; Const _2_ty_fields: Array Of Tq4JSONSelectionField): Tq4JSONCollection;
  Var
    _y_source: Tq4ResolvedSelectionSource;
    AResolved: Tq4ResolvedSelectionToJSONFields;
    _o_query:  TSQLQuery;
    _o_result: TJSONArray;
    _o_row:    TJSONObject;
    _o_value:  TJSONData;
    _t_sql:    string;
    _e_i:      int64;
  Begin
    If ( Length( _2_ty_fields) = 0) Then InternalBuildDefaultSelectionFields( _1_p_recordTable, AResolved)
    Else
      InternalBuildExplicitSelectionFields( _1_p_recordTable, _2_ty_fields, AResolved);

    q4interruptions.assertRaise(
      InternalResolveSelectionSourceCurrent( _1_p_recordTable, _y_source),
      'q4JSON.selectionToJSON : source de sélection introuvable'
      );

    _o_query := TSQLQuery.Create( nil);
    _o_result := TJSONArray.Create;
    Try
      _o_query.DataBase := q4DBmanager.connect;
      _o_query.Transaction := q4DBmanager.connect.Transaction;
      _t_sql := InternalBuildSelectionToJSONSQL( _y_source, AResolved);
      _o_query.SQL.Text := _t_sql;
      _o_query.ParamByName( 'noResultat').AsInteger := _y_source.ResultNo;
      _o_query.Open;

      While ( not _o_query.EOF) Do Begin
        _o_row := TJSONObject.Create;
        For _e_i := 0 To High( AResolved) Do Begin
          _o_value := InternalFieldToJSONData( _o_query.FieldByName( 'f' + IntToStr( _e_i)));
          _o_row.Add( AResolved[_e_i].LabelName, _o_value);
        End;
        _o_result.Add( _o_row);
        _o_query.Next;
      End;

      Result := _o_result.AsJSON;
      q4RecordLocking.unloadRecord( _1_p_recordTable);
    Finally
      _o_result.Free;
      _o_query.Free;
    End;
  End;

End.
