Unit q4record;

{$mode objfpc}{$H+}

{
q4record
version du 2026/04/18-14:10

Mapping 4D
Command Number 4D,   4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
68,                  CREATE RECORD,                    createRecord,                     Partial,
58,                  DELETE RECORD,                    deleteRecord,                     OK,
105,                 DISPLAY RECORD,                   displayRecord,                    Partial,
225,                 DUPLICATE RECORD,                 duplicateRecord,                  OK,
242,                 GOTO RECORD,                      gotoRecord,                       OK,
668,                 Is new record,                    isNewRecord,                      OK,
669,                 Is record loaded,                 isRecordLoaded,                   OK,
314,                 Modified record,                  modifiedRecord,                   OK,
177,                 POP RECORD,                       popRecord,                        TODO,
176,                 PUSH RECORD,                      pushRecord,                       TODO,
243,                 Record number,                    recordNumber,                     OK,
83,                  Records in table,                 recordsInTable,                   OK,
53,                  SAVE RECORD,                      saveRecord,                       Partial,
389,                 Sequence number,                  sequenceNumber,                   Partial,

Doc: https://developer.4d.com/docs/21/commands/theme/Records

  Notes d'implémentation :
    - metier_q4DBschemaProcess initialise déjà le contexte (_ArraySQL, _Bindings, flags runtime)
    - _Bindings contient des ValuePtr vers les champs métier du record
    - metier_q4DBschemaBase reste la source de vérité pour les métadonnées de table/champs
    - INSERT  : seulement les champs remplis (comparaison aux valeurs par défaut métier)
    - UPDATE  : seulement les champs réellement différents vs _ArraySQL
    - _ReadWrite est capturé au chargement via q4RecordLocking
}

Interface

Uses
  Classes,
  SysUtils,
  Variants,
  DB,
  SQLDB,
  q4coreLanguage,
  q4DBmanager,
  metier_q4DBschemaBase,
  metier_q4DBschemaProcess,
  q4DBschemaUse;

Const
  Q4_NO_CURRENT_RECORD = -1;
  Q4_NEW_RECORD = -3;

Type

  //2026/04/03 : contenu desormais dans q4DBschemaUse
  //// Le schéma du record doit commencer de la même manière que celui de q4schemaProcess.
  //Tq4recordRuntime = record
  //  _noTable: Int64;
  //  _ReadWrite: boolean;
  //  _Loaded: boolean;
  //  _Modified: boolean;
  //  _RowId: int64;
  //  _ArraySQL: TVariantArray;
  //  _Bindings: TFieldBindingArray;
  //end;

  //Pq4recordRuntime = ^Tq4recordRuntime;

  PBytes = ^TBytes;
  TChangedFieldArray = Array Of integer;
  TQ4RowIdArray = Array Of int64;

  TQ4PushedRecordState = Record
    e_tableNo: int64;
    e_rowId: int64;
    b_loaded: boolean;
    b_modified: boolean;
    b_readWriteReserved: boolean;
    y_arraySQL: TVariantArray;
    y_currentValues: TVariantArray;
  End;

  TQ4PushedRecordStack = Array Of TQ4PushedRecordState;

Procedure createRecord( Var _1_p_recordTable); overload;
Procedure createRecord( Var _1_p_table: Pointer); overload;

Procedure deleteRecord( Var _1_p_recordTable); overload;
Procedure deleteRecord( Var _1_p_table: Pointer); overload;

Procedure displayRecord( Var _1_p_recordTable); overload;
Procedure displayRecord( Var _1_p_table: Pointer); overload;

Procedure duplicateRecord( Var _1_p_recordTable); overload;
Procedure duplicateRecord( Var _1_p_table: Pointer); overload;

Procedure gotoRecord( Var _1_p_recordTable; Const _2_e_rowId: int64); overload;
Procedure gotoRecord( Var _1_p_table: Pointer; Const _2_e_rowId: int64); overload;

Function isNewRecord( Var _1_p_recordTable): boolean; overload;
Function isNewRecord( Var _1_p_table: Pointer): boolean; overload;

Function isRecordLoaded( Var _1_p_recordTable): boolean; overload;
Function isRecordLoaded( Var _1_p_table: Pointer): boolean; overload;

Function modifiedRecord( Var _1_p_recordTable): boolean; overload;
Function modifiedRecord( Var _1_p_table: Pointer): boolean; overload;

Procedure popRecord( Var _1_p_recordTable); overload;
Procedure popRecord( Var _1_p_table: Pointer); overload;

Procedure pushRecord( Var _1_p_recordTable); overload;
Procedure pushRecord( Var _1_p_table: Pointer); overload;

Function recordNumber( Var _1_p_recordTable): int64; overload;
Function recordNumber( Var _1_p_table: Pointer): int64; overload;

Function recordsInTable( Var _1_p_recordTable): int64; overload;
Function recordsInTable( Var _1_p_table: Pointer): int64; overload;

Procedure saveRecord( Var _1_p_recordTable); overload;
Procedure saveRecord( Var _1_p_table: Pointer); overload;

Function sequenceNumber( Var _1_p_recordTable): int64; overload;
Function sequenceNumber( Var _1_p_table: Pointer): int64; overload;

Function lastSaveRecordError: string;
Procedure clearLastSaveRecordError;

Procedure copyArraySQLToBindings( Const _1_ty_bindings: TFieldBindingArray; Const _2_y_arraySQL: TVariantArray);
Function selectRecordToArraySQL( Const _1_e_tableNo: int64; Const _2_e_rowId: int64; Var _3_y_arraySQL: TVariantArray): boolean;
Procedure clearArraySQL( Var _1_y_arraySQL: TVariantArray);
Function readBindingValue( Const _1_y_binding: TFieldBinding): variant;
Procedure writeBindingValue( Const _1_y_binding: TFieldBinding; Const _2_y_value: variant);

Function hasPushedRecords: boolean;
Function isRowIdPushedRW( Const _1_e_tableNo: int64; Const _2_e_rowId: int64): boolean;

Procedure syncLoadedRecordAfterRollback( Var _1_p_recordTable); overload;
Procedure syncLoadedRecordAfterRollback( Var _1_p_table: Pointer); overload;

Procedure syncLoadedRecordsAfterRollbackForLockedTables;

Implementation

Uses
  q4dateAndTime,
  q4interruptions,
  q4RecordLocking,
  q4transaction,
  q4process,
  q4selection,
  md5,
  q4triggerRuntime;

Threadvar
  ty_pushedRecordsStack: TQ4PushedRecordStack;
  t_lastSaveRecordError: string;

Function runtimeOf( Var _1_p_table: Pointer): Pq4recordRuntime; Inline;
  Begin
    Result := Pq4recordRuntime( _1_p_table);
  End;

Function VariantToBooleanSafe( Const _1_y_value: variant): boolean;
  Var
    _s_value: string;
  Begin
    If ( VarIsNull( _1_y_value) or VarIsEmpty( _1_y_value)) Then Exit( False);

    Case VarType( _1_y_value) Of
      varBoolean: Exit( _1_y_value);

      varByte, varSmallint, varInteger, varShortInt, varWord, varLongWord, varInt64: Exit( _1_y_value <> 0);

      varSingle, varDouble, varCurrency: Exit( _1_y_value <> 0);
    End;

    _s_value := Trim( VarToStr( _1_y_value));

    If ( SameText( _s_value, 'TRUE') or SameText( _s_value, 'T') or SameText( _s_value, 'YES') or SameText( _s_value, 'Y') or SameText( _s_value, 'OUI') or SameText( _s_value, 'VRAI') or ( _s_value = '1'))
    Then Exit( True);

    If ( SameText( _s_value, 'FALSE') or SameText( _s_value, 'F') or SameText( _s_value, 'NO') or SameText( _s_value, 'N') or SameText( _s_value, 'NON') or ( _s_value = '0') or ( _s_value = '')) Then
      Exit( False);

    q4interruptions.assertRaise( False,
      'q4record.VariantToBooleanSafe : valeur booléenne invalide : "' + _s_value + '"');
    Result := False;
  End;

Procedure InternalCloneVariantArray( Const _1_y_source: TVariantArray; Var _2_y_dest: TVariantArray);
  Var
    _e_i: int64;
  Begin
    SetLength( _2_y_dest, Length( _1_y_source));

    For _e_i := 0 To High( _1_y_source) Do _2_y_dest[_e_i] := _1_y_source[_e_i];
  End;

Function hasPushedRecords: boolean;
  Begin
    Result := Length( ty_pushedRecordsStack) > 0;
  End;

Function isRowIdPushedRW( Const _1_e_tableNo: int64; Const _2_e_rowId: int64): boolean;
  Var
    _e_i: int64;
  Begin
    Result := False;

    For _e_i := High( ty_pushedRecordsStack) Downto 0 Do If ( ( ty_pushedRecordsStack[_e_i].e_tableNo = _1_e_tableNo) and ( ty_pushedRecordsStack[_e_i].e_rowId = _2_e_rowId) and
        ty_pushedRecordsStack[_e_i].b_readWriteReserved) Then Begin
        Result := True;
        Exit;
      End;
  End;

Procedure createRecord( Var _1_p_table: Pointer); overload;
  Begin
    createRecord( runtimeOf( _1_p_table)^);
  End;

Procedure deleteRecord( Var _1_p_table: Pointer); overload;
  Begin
    deleteRecord( runtimeOf( _1_p_table)^);
  End;

Procedure displayRecord( Var _1_p_table: Pointer); overload;
  Begin
    displayRecord( runtimeOf( _1_p_table)^);
  End;

Procedure duplicateRecord( Var _1_p_table: Pointer); overload;
  Begin
    duplicateRecord( runtimeOf( _1_p_table)^);
  End;

Procedure gotoRecord( Var _1_p_table: Pointer; Const _2_e_rowId: int64); overload;
  Begin
    gotoRecord( runtimeOf( _1_p_table)^, _2_e_rowId);
  End;

Function isNewRecord( Var _1_p_table: Pointer): boolean; overload;
  Begin
    Result := isNewRecord( runtimeOf( _1_p_table)^);
  End;

Function isRecordLoaded( Var _1_p_table: Pointer): boolean; overload;
  Begin
    Result := isRecordLoaded( runtimeOf( _1_p_table)^);
  End;

Function modifiedRecord( Var _1_p_table: Pointer): boolean; overload;
  Begin
    Result := modifiedRecord( runtimeOf( _1_p_table)^);
  End;

Procedure popRecord( Var _1_p_table: Pointer); overload;
  Begin
    popRecord( runtimeOf( _1_p_table)^);
  End;

Procedure pushRecord( Var _1_p_table: Pointer); overload;
  Begin
    pushRecord( runtimeOf( _1_p_table)^);
  End;

Function recordNumber( Var _1_p_table: Pointer): int64; overload;
  Begin
    Result := recordNumber( runtimeOf( _1_p_table)^);
  End;

Function recordsInTable( Var _1_p_table: Pointer): int64; overload;
  Begin
    Result := recordsInTable( runtimeOf( _1_p_table)^);
  End;

Procedure saveRecord( Var _1_p_table: Pointer); overload;
  Begin
    saveRecord( runtimeOf( _1_p_table)^);
  End;

Function sequenceNumber( Var _1_p_table: Pointer): int64; overload;
  Begin
    Result := sequenceNumber( runtimeOf( _1_p_table)^);
  End;

Function getFieldName( Const _1_e_tableNo: int64; Const _2_e_bindingIndex: int64): string;
  Var
    _e_fieldNo: int64;
  Begin
    _e_fieldNo := Tables[_1_e_tableNo].FieldIndex + _2_e_bindingIndex;
    Result := Fields[_e_fieldNo].Name;
  End;

Procedure clearArraySQL( Var _1_y_arraySQL: TVariantArray);
  Var
    _e_index: int64;
  Begin
    For _e_index := 0 To High( _1_y_arraySQL) Do _1_y_arraySQL[_e_index] := Null;
  End;

Procedure InternalResetCurrentRecord( Const _1_p_runtime: Pq4recordRuntime);
  Begin
    _1_p_runtime^._Loaded := False;
    _1_p_runtime^._Modified := False;
    _1_p_runtime^._ReadWrite := False;
    _1_p_runtime^._RowId := Q4_NO_CURRENT_RECORD;
    clearArraySQL( _1_p_runtime^._ArraySQL);
  End;

Function readBindingValue( Const _1_y_binding: TFieldBinding): variant;
  Begin
    Case _1_y_binding.FieldKind Of
      fkInteger: Result := PSmallInt( _1_y_binding.ValuePtr)^;
      fkLongint: Result := PLongInt( _1_y_binding.ValuePtr)^;
      fkInt64: Result := PInt64( _1_y_binding.ValuePtr)^;
      fkText: Result := PString( _1_y_binding.ValuePtr)^;
      fkBoolean: Result := PBoolean( _1_y_binding.ValuePtr)^;
      fkReal: Result := PDouble( _1_y_binding.ValuePtr)^;
      fkDate: Result := PString( _1_y_binding.ValuePtr)^;
      fkTime: Result := PString( _1_y_binding.ValuePtr)^;
      //  fkBlob: Result := InternalBytesToVariant(PBytes(y_binding.ValuePtr)^);
      fkBlob: Result := q4coreLanguage.bytesToVariant( PBytes( _1_y_binding.ValuePtr)^);
      Else Begin
        q4interruptions.assertRaise( False, 'q4record.readBindingValue: FieldKind non géré');
        Result := Null;
      End;
    End;
  End;


Procedure writeBindingValue( Const _1_y_binding: TFieldBinding; Const _2_y_value: variant);
  Begin
    If ( VarIsNull( _2_y_value) or VarIsEmpty( _2_y_value)) Then Begin
      Case _1_y_binding.FieldKind Of
        fkInteger: PSmallInt( _1_y_binding.ValuePtr)^ := 0;
        fkLongint: PLongInt( _1_y_binding.ValuePtr)^ := 0;
        fkInt64: PInt64( _1_y_binding.ValuePtr)^ := 0;
        fkText: PString( _1_y_binding.ValuePtr)^ := '';
        fkBoolean: PBoolean( _1_y_binding.ValuePtr)^ := False;
        fkReal: PDouble( _1_y_binding.ValuePtr)^ := q4coreLanguage.VariantToRealInvariant( _2_y_value);
        fkDate: PString( _1_y_binding.ValuePtr)^ := '';
        fkTime: PString( _1_y_binding.ValuePtr)^ := '';
        fkBlob: SetLength( PBytes( _1_y_binding.ValuePtr)^, 0);
        Else q4interruptions.assertRaise( False, 'q4record.writeBindingValue: FieldKind non géré');
      End;
      Exit;
    End;

    Case _1_y_binding.FieldKind Of
      fkInteger: PSmallInt( _1_y_binding.ValuePtr)^ := smallint( _2_y_value);
      fkLongint: PLongInt( _1_y_binding.ValuePtr)^ := longint( _2_y_value);
      fkInt64: PInt64( _1_y_binding.ValuePtr)^ := StrToInt64Def( Trim( VarToStr( _2_y_value)), 0);
      fkText: PString( _1_y_binding.ValuePtr)^ := VarToStr( _2_y_value);
      //   fkBoolean: PBoolean(y_binding.ValuePtr)^ := VarToBool(y_value);
      fkBoolean: PBoolean( _1_y_binding.ValuePtr)^ := VariantToBooleanSafe( _2_y_value);
      fkReal: PDouble( _1_y_binding.ValuePtr)^ := double( _2_y_value);
      fkDate: PString( _1_y_binding.ValuePtr)^ := q4dateAndTime.normalizeDate( VarToStr( _2_y_value));
      fkTime: PString( _1_y_binding.ValuePtr)^ := q4dateAndTime.normalizeTime( VarToStr( _2_y_value));
      fkBlob: PBytes( _1_y_binding.ValuePtr)^ := q4coreLanguage.variantToBytes( _2_y_value);
      Else q4interruptions.assertRaise( False, 'q4record.writeBindingValue: FieldKind non géré');
    End;
  End;

Function lastSaveRecordError: string;
  Begin
    Result := t_lastSaveRecordError;
  End;

Procedure clearLastSaveRecordError;
  Begin
    t_lastSaveRecordError := '';
  End;

Procedure setLastSaveRecordError( Const _1_t_error: string);
  Begin
    t_lastSaveRecordError := _1_t_error;
  End;

Function repairBindingForSave( Const _1_e_tableNo: int64; Const _2_e_bindingIndex: int64; Const _3_ty_bindings: TFieldBindingArray; out _4_t_error: string): boolean;
  Var
    _e_fieldIndex: int64;
    _y_field:      TFieldMeta;
    _y_value:      variant;
    _y_normalized: variant;
  Begin
    Result := False;
    _4_t_error := '';

    If ( ( _2_e_bindingIndex < 0) or ( _2_e_bindingIndex > High( _3_ty_bindings))) Then Begin
      _4_t_error := 'q4record.repairBindingForSave: binding index invalide: ' + IntToStr( _2_e_bindingIndex);
      Exit;
    End;

    _e_fieldIndex := Tables[_1_e_tableNo].FieldIndex + _2_e_bindingIndex;
    _y_field := Fields[_e_fieldIndex];

    _y_value := readBindingValue( _3_ty_bindings[_2_e_bindingIndex]);

    If ( not q4ValidateFieldValue( _y_field, _y_value, q4fvsRecord, q4fvpRepairForSave, _y_normalized, _4_t_error)) Then Exit;

    writeBindingValue( _3_ty_bindings[_2_e_bindingIndex], _y_normalized);

    Result := True;
  End;

Function repairAllBindingsForSave( Const _1_e_tableNo: int64; Const _2_ty_bindings: TFieldBindingArray; out _3_t_error: string): boolean;
  Var
    _e_bindingIndex: int64;
  Begin
    Result := False;
    _3_t_error := '';

    For _e_bindingIndex := 0 To High( _2_ty_bindings) Do If ( not repairBindingForSave( _1_e_tableNo, _e_bindingIndex, _2_ty_bindings, _3_t_error)) Then Exit;

    Result := True;
  End;

Function repairChangedBindingsForSave( Const _1_e_tableNo: int64; Const _2_ty_bindings: TFieldBindingArray; Const _3_ty_fields: TChangedFieldArray; out _4_t_error: string): boolean;
  Var
    _e_position:     int64;
    _e_bindingIndex: int64;
  Begin
    Result := False;
    _4_t_error := '';

    For _e_position := 0 To High( _3_ty_fields) Do Begin
      _e_bindingIndex := _3_ty_fields[_e_position];

      If ( not repairBindingForSave( _1_e_tableNo, _e_bindingIndex, _2_ty_bindings, _4_t_error)) Then Exit;
    End;

    Result := True;
  End;

//function isFilledForInsert(const y_binding: TFieldBinding): boolean;
//var
//  y_value: variant;
//begin
//  y_value := readBindingValue(y_binding);

//  if Variants.VarIsNull(y_value) or Variants.VarIsEmpty(y_value) then Exit(False);

//  case y_binding.FieldKind of
//    fkBoolean: Result := Variants.VarAsType(y_value, varBoolean) = True;

//    fkInteger: Result := Variants.VarAsType(y_value, varSmallint) <> 0;

//    fkLongint: Result := Variants.VarAsType(y_value, varInteger) <> 0;

//    fkInt64: Result := Variants.VarAsType(y_value, varInt64) <> 0;

//    fkReal: Result := Variants.VarAsType(y_value, varDouble) <> 0;

//    fkText,
//    fkDate,
//    fkTime: Result := Variants.VarToStr(y_value) <> '';

//    fkBlob: Result := not (Variants.VarIsNull(y_value) or Variants.VarIsEmpty(y_value));

//    else Result := Variants.VarToStr(y_value) <> '';
//  end;
//end;
Function isFilledForInsert( Const _1_y_binding: TFieldBinding): boolean;
  Var
    _y_value: variant;
  Begin
    _y_value := readBindingValue( _1_y_binding);

    If ( VarIsNull( _y_value) or VarIsEmpty( _y_value)) Then Exit( False);

    Case _1_y_binding.FieldKind Of
      fkBoolean: Result := boolean( _y_value);

      fkInteger: Result := smallint( _y_value) <> 0;

      fkLongint: Result := longint( _y_value) <> 0;

      fkInt64: Result := PInt64( _1_y_binding.ValuePtr)^ <> 0;

      fkReal: Result := double( _y_value) <> 0;

      fkText, fkDate, fkTime: Result := VarToStr( _y_value) <> '';

      fkBlob: Result := True;

      Else Result := VarToStr( _y_value) <> '';
    End;
  End;


Procedure addChangedField( Var _1_ty_fields: TChangedFieldArray; Const _2_e_bindingIndex: int64);
  Var
    _e_length: int64;
  Begin
    _e_length := System.Length( _1_ty_fields);
    SetLength( _1_ty_fields, _e_length + 1);
    _1_ty_fields[_e_length] := _2_e_bindingIndex;
  End;

Function getChangedFields( Const _1_ty_bindings: TFieldBindingArray; Const _2_y_arraySQL: TVariantArray): TChangedFieldArray;
  Var
    _e_bindingIndex: int64;
    _y_newValue:     variant;
    _y_oldValue:     variant;
  Begin
    SetLength( Result, 0);

    For _e_bindingIndex := 0 To High( _1_ty_bindings) Do Begin
      _y_newValue := readBindingValue( _1_ty_bindings[_e_bindingIndex]);
      _y_oldValue := _2_y_arraySQL[_e_bindingIndex];

      If ( not q4coreLanguage.sameValue( _y_newValue, _y_oldValue)) Then addChangedField( Result, _e_bindingIndex);
    End;
  End;

Procedure copyAllBindingsToArraySQL( Const _1_ty_bindings: TFieldBindingArray; Var _2_y_arraySQL: TVariantArray);
  Var
    _e_bindingIndex: int64;
  Begin
    For _e_bindingIndex := 0 To High( _1_ty_bindings) Do _2_y_arraySQL[_e_bindingIndex] := readBindingValue( _1_ty_bindings[_e_bindingIndex]);
  End;

Procedure copyChangedBindingsToArraySQL( Const _1_ty_bindings: TFieldBindingArray; Const _2_ty_changedFields: TChangedFieldArray; Var _3_y_arraySQL: TVariantArray);
  Var
    _e_position:     int64;
    _e_bindingIndex: int64;
  Begin
    For _e_position := 0 To High( _2_ty_changedFields) Do Begin
      _e_bindingIndex := _2_ty_changedFields[_e_position];
      _3_y_arraySQL[_e_bindingIndex] := readBindingValue( _1_ty_bindings[_e_bindingIndex]);
    End;
  End;

Procedure copyArraySQLToBindings( Const _1_ty_bindings: TFieldBindingArray; Const _2_y_arraySQL: TVariantArray);
  Var
    _e_bindingIndex: int64;
  Begin
    For _e_bindingIndex := 0 To High( _1_ty_bindings) Do writeBindingValue( _1_ty_bindings[_e_bindingIndex], _2_y_arraySQL[_e_bindingIndex]);
  End;

Function buildInsertSQL( Const _1_e_tableNo: int64; Const _2_ty_changedFields: TChangedFieldArray): string;
  Var
    _e_position:  int64;
    _t_fields:    string;
    _t_params:    string;
    _t_fieldName: string;
  Begin
    _t_fields := '';
    _t_params := '';

    If ( System.Length( _2_ty_changedFields) = 0) Then Begin
      Result := 'INSERT INTO ' + Tables[_1_e_tableNo].Name + ' DEFAULT VALUES';
      Exit;
    End;

    For _e_position := 0 To High( _2_ty_changedFields) Do Begin
      _t_fieldName := getFieldName( _1_e_tableNo, _2_ty_changedFields[_e_position]);

      If ( _t_fields <> '') Then Begin
        _t_fields := _t_fields + ', ';
        _t_params := _t_params + ', ';
      End;

      _t_fields := _t_fields + _t_fieldName;
      _t_params := _t_params + ':' + _t_fieldName;
    End;

    Result := 'INSERT INTO ' + Tables[_1_e_tableNo].Name + ' (' + _t_fields + ') VALUES (' + _t_params + ')';
  End;

Function buildUpdateSQL( Const _1_e_tableNo: int64; Const _2_ty_changedFields: TChangedFieldArray): string;
  Var
    _e_position:  int64;
    _t_sets:      string;
    _t_fieldName: string;
  Begin
    _t_sets := '';

    For _e_position := 0 To High( _2_ty_changedFields) Do Begin
      _t_fieldName := getFieldName( _1_e_tableNo, _2_ty_changedFields[_e_position]);

      If ( _t_sets <> '') Then _t_sets := _t_sets + ', ';

      _t_sets := _t_sets + _t_fieldName + ' = :' + _t_fieldName;
    End;

    Result := 'UPDATE ' + Tables[_1_e_tableNo].Name + ' SET ' + _t_sets + ' WHERE rowid = :rowid';
  End;

Function selectRecordToArraySQL( Const _1_e_tableNo: int64; Const _2_e_rowId: int64; Var _3_y_arraySQL: TVariantArray): boolean;
  Var
    _tt_fieldNames: Array Of string;
    _e_index:      int64;
    _e_fieldIndex: int64;
    _t_tableName:  string;
  Begin
    _t_tableName := Tables[_1_e_tableNo].Name;

    SetLength( _tt_fieldNames, Tables[_1_e_tableNo].FieldCount);

    For _e_index := 0 To Tables[_1_e_tableNo].FieldCount - 1 Do Begin
      _e_fieldIndex := Tables[_1_e_tableNo].FieldIndex + _e_index;
      _tt_fieldNames[_e_index] := Fields[_e_fieldIndex].Name;
    End;

    Result := q4DBmanager.selectRowToArraySQL( _t_tableName, _tt_fieldNames, _2_e_rowId, _3_y_arraySQL);
  End;

Function getFilledInsertFields( Const _1_ty_bindings: TFieldBindingArray): TChangedFieldArray;
  Var
    _e_bindingIndex: int64;
  Begin
    SetLength( Result, 0);

    For _e_bindingIndex := 0 To High( _1_ty_bindings) Do If ( isFilledForInsert( _1_ty_bindings[_e_bindingIndex])) Then addChangedField( Result, _e_bindingIndex);
  End;

Function InternalExecScalarInt64( Const _1_t_sql: string): int64;
  Var
    _o_query: TSQLQuery;
    _b_startedTransaction: boolean;
  Begin
    Result := 0;
    _b_startedTransaction := False;

    _o_query := TSQLQuery.Create( nil);
    Try
      Try
        _o_query.DataBase := InternalConnection;
        _o_query.Transaction := InternalTransaction;
        _o_query.SQL.Text := _1_t_sql;

        If ( not InternalTransaction.Active) Then Begin
          InternalTransaction.StartTransaction;
          _b_startedTransaction := True;
        End;

        _o_query.Open;

        If ( not _o_query.EOF) Then Result := _o_query.Fields[0].AsLargeInt;

        If ( _b_startedTransaction) Then InternalTransaction.Commit;
      Except
        If ( _b_startedTransaction) Then InternalTransaction.Rollback;
        Raise;
      End;
    Finally
      _o_query.Free;
    End;
  End;

Function InternalRecordsInTableSQL( Const _1_e_tableNo: int64): int64;
  Var
    _t_sql: string;
  Begin
    _t_sql := 'SELECT COUNT(*) FROM ' + Tables[_1_e_tableNo].Name;
    Result := InternalExecScalarInt64( _t_sql);
  End;

Function InternalSequenceNumberSQL( Const _1_e_tableNo: int64): int64;
  Var
    _o_query:     TSQLQuery;
    _t_tableName: string;
    _b_startedTransaction: boolean;
  Begin
    _t_tableName := Tables[_1_e_tableNo].Name;
    Result := 0;
    _b_startedTransaction := False;

    _o_query := TSQLQuery.Create( nil);
    Try
      Try
        _o_query.DataBase := InternalConnection;
        _o_query.Transaction := InternalTransaction;
        _o_query.SQL.Text := 'SELECT seq + 1 FROM sqlite_sequence WHERE name = :tableName';
        _o_query.ParamByName( 'tableName').AsString := _t_tableName;

        If ( not InternalTransaction.Active) Then Begin
          InternalTransaction.StartTransaction;
          _b_startedTransaction := True;
        End;

        _o_query.Open;

        If ( not _o_query.EOF) Then Begin
          Result := _o_query.Fields[0].AsLargeInt;

          If ( _b_startedTransaction) Then InternalTransaction.Commit;
          Exit;
        End;

        If ( _b_startedTransaction) Then InternalTransaction.Commit;
      Except
        If ( _b_startedTransaction) Then InternalTransaction.Rollback;
        Raise;
      End;
    Finally
      _o_query.Free;
    End;

    Result := InternalExecScalarInt64( 'SELECT COALESCE(MAX(rowid), 0) + 1 FROM ' + _t_tableName);
  End;

Function internalInsertRecordSQL( Const _1_e_tableNo: int64; Const _2_ty_bindings: TFieldBindingArray; Const _3_ty_changedFields: TChangedFieldArray): int64;
  Var
    _o_query: TSQLQuery;
    _t_sql:   string;
    _e_listIndex: int64;
    _e_bindingIndex: int64;
    _y_value: variant;
  Begin
    _t_sql := buildInsertSQL( _1_e_tableNo, _3_ty_changedFields);

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;
      _o_query.SQL.Text := _t_sql;

      For _e_listIndex := 0 To High( _3_ty_changedFields) Do Begin
        _e_bindingIndex := _3_ty_changedFields[_e_listIndex];
        _y_value := readBindingValue( _2_ty_bindings[_e_bindingIndex]);
        _o_query.ParamByName( getFieldName( _1_e_tableNo, _e_bindingIndex)).Value := _y_value;
      End;

      If ( not b_inTransactionQ4) Then If ( not InternalTransaction.Active) Then InternalTransaction.StartTransaction;

      Try
        _o_query.ExecSQL;
        Result := InternalConnection.GetInsertID;

        If ( inTransaction) Then q4RecordLocking.setRecordLock( _1_e_tableNo, Result, ProcessState.processID, True);

        If ( not b_inTransactionQ4) Then InternalTransaction.Commit;
      Except
        If ( not b_inTransactionQ4) Then InternalTransaction.Rollback;
        Raise;
      End;
    Finally
      _o_query.Free;
    End;
  End;

Procedure internalUpdateRecordSQL( Const _1_e_tableNo: int64; Const _2_ty_bindings: TFieldBindingArray; Const _3_ty_fields: TChangedFieldArray; Const _4_e_rowId: int64);
  Var
    _o_query: TSQLQuery;
    _t_sql:   string;
    _e_listIndex: int64;
    _e_bindingIndex: int64;
    _y_value: variant;
  Begin
    If ( System.Length( _3_ty_fields) = 0) Then Exit;

    _t_sql := buildUpdateSQL( _1_e_tableNo, _3_ty_fields);
    q4interruptions.assertRaise( _t_sql <> '', 'q4record.internalUpdateRecordSQL: SQL vide');

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;
      _o_query.SQL.Text := _t_sql;

      For _e_listIndex := 0 To High( _3_ty_fields) Do Begin
        _e_bindingIndex := _3_ty_fields[_e_listIndex];
        _y_value := readBindingValue( _2_ty_bindings[_e_bindingIndex]);
        _o_query.ParamByName( getFieldName( _1_e_tableNo, _e_bindingIndex)).Value := _y_value;
      End;

      _o_query.ParamByName( 'rowid').AsLargeInt := _4_e_rowId;

      If ( not b_inTransactionQ4) Then If ( not InternalTransaction.Active) Then InternalTransaction.StartTransaction;

      Try
        _o_query.ExecSQL;
        If ( not b_inTransactionQ4) Then InternalTransaction.Commit;
      Except
        If ( not b_inTransactionQ4) Then InternalTransaction.Rollback;
        Raise;
      End;
    Finally
      _o_query.Free;
    End;
  End;

Procedure InternalDeleteRecordSQL( Const _1_e_tableNo: int64; Const _2_e_rowId: int64);
  Var
    _o_query: TSQLQuery;
    _t_sql:   string;
  Begin
    _t_sql := 'DELETE FROM ' + Tables[_1_e_tableNo].Name + ' WHERE rowid = :rowid';

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;
      _o_query.SQL.Text := _t_sql;
      _o_query.ParamByName( 'rowid').AsLargeInt := _2_e_rowId;

      If ( not b_inTransactionQ4) Then If ( not InternalTransaction.Active) Then InternalTransaction.StartTransaction;

      Try
        _o_query.ExecSQL;
        If ( not b_inTransactionQ4) Then InternalTransaction.Commit;
      Except
        If ( not b_inTransactionQ4) Then InternalTransaction.Rollback;
        Raise;
      End;
    Finally
      _o_query.Free;
    End;
  End;

Procedure createRecord( Var _1_p_recordTable); overload;
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    //https://developer.4d.com/docs/21/commands/create-record

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenCommand,
          'q4record.createRecord interdit pendant un trigger'
          );

    q4RecordLocking.unloadRecord( _1_p_recordTable);

    _p_runtime^._Loaded := True;
    _p_runtime^._Modified := True;
    _p_runtime^._ReadWrite := True;
    _p_runtime^._RowId := Q4_NEW_RECORD;
  End;

Procedure InternalSetCurrentRecordState( Const _1_p_runtime: Pq4recordRuntime; Const _2_e_rowId: int64);
  Begin
    clearArraySQL( _1_p_runtime^._ArraySQL);
    copyArraySQLToBindings( _1_p_runtime^._Bindings, _1_p_runtime^._ArraySQL);

    _1_p_runtime^._Loaded := False;
    _1_p_runtime^._Modified := False;
    _1_p_runtime^._ReadWrite := False;
    _1_p_runtime^._RowId := _2_e_rowId;
  End;

Procedure deleteRecord( Var _1_p_recordTable);
  Var
    _p_runtime: Pq4recordRuntime;
    _e_rowId:   int64;
    _e_selectedPos: int64;
  Begin
    // https://developer.4d.com/docs/21/commands/delete-record
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenCommand,
          'q4record.deleteRecord interdit pendant un trigger'
          );

    If ( not _p_runtime^._Loaded) Then Exit;

    // Nouveau record non sauvé : on annule simplement le courant
    // => pas de trigger de suppression
    If ( _p_runtime^._RowId = Q4_NEW_RECORD) Then Begin
      InternalSetCurrentRecordState( _p_runtime, Q4_NO_CURRENT_RECORD);
      Exit;
    End;

    If ( not _p_runtime^._ReadWrite) Then Exit;
    If ( _p_runtime^._RowId <= 0) Then Exit;

    _e_rowId := _p_runtime^._RowId;

    // lecture interne, sans effet de bord
    _e_selectedPos := q4selection.selectedRecordNumberOrZero( _1_p_recordTable);

    // Trigger de suppression avant suppression réelle
    If ( q4triggerRuntime.triggersEnabled) Then Begin
      q4triggerRuntime.q4BeginTrigger( _p_runtime^._noTable, q4teOnDeletingRecord);
      Try
        q4triggerRuntime.q4ExecuteTrigger( _1_p_recordTable, q4teOnDeletingRecord);
      Finally
        q4triggerRuntime.q4EndTrigger;
      End;
    End;

    InternalDeleteRecordSQL( _p_runtime^._noTable, _e_rowId);

    // Le verrou est logiciel : on ne le supprime qu'hors transaction.
    // En transaction, la libération est gérée à la fin
    // (validateTransaction / cancelTransaction -> clearProcessLocks).
    If ( not q4transaction.inTransaction) Then q4RecordLocking.setRecordLock(
        _p_runtime^._noTable,
        _e_rowId,
        ProcessState.processID,
        False
        );

    // Si le record supprimé faisait partie de la sélection courante,
    // on reste sur la même position logique, mais sur un record supprimé.
    If ( _e_selectedPos > 0) Then InternalSetCurrentRecordState( _p_runtime, -2)
    Else
      InternalSetCurrentRecordState( _p_runtime, Q4_NO_CURRENT_RECORD);
  End;

Procedure displayRecord( Var _1_p_recordTable);
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    //https://developer.4d.com/docs/21/commands/display-record

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( not _p_runtime^._Loaded) Then Exit;

    { Runtime q4 actuel sans couche UI 4D :
    la commande existe et reste volontairement sans effet ici. }
  End;

Procedure duplicateRecord( Var _1_p_recordTable);
  Var
    _p_runtime: Pq4recordRuntime;
    _y_values:  TVariantArray;
  Begin
    //https://developer.4d.com/docs/21/commands/duplicate-record

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenCommand,
          'q4record.duplicateRecord interdit pendant un trigger'
          );

    If ( not _p_runtime^._Loaded) Then Exit;

    SetLength( _y_values, System.Length( _p_runtime^._Bindings));
    copyAllBindingsToArraySQL( _p_runtime^._Bindings, _y_values);

    createRecord( _1_p_recordTable);
    copyArraySQLToBindings( _p_runtime^._Bindings, _y_values);
    _p_runtime^._Modified := True;
  End;

Procedure gotoRecord( Var _1_p_recordTable; Const _2_e_rowId: int64);
  // travail sur la table principale et réduit la sélection à ce record
  Var
    _p_runtime:  Pq4recordRuntime;
    _y_arraySQL: TVariantArray;
  Begin
    //https://developer.4d.com/docs/21/commands/goto-record

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenCommand,
          'q4record.gotoRecord interdit pendant un trigger'
          );

    SetLength( _y_arraySQL, Length( _p_runtime^._ArraySQL));

    If ( not selectRecordToArraySQL( _p_runtime^._noTable, _2_e_rowId, _y_arraySQL)) Then Begin
      q4selection.reduceSelection( _p_runtime^, 0);
      error := Q4ErrorRecordDeleted;
      Raise Exception.Create( 'Record deleted or no longer exists');
    End;

    _p_runtime^._ArraySQL := _y_arraySQL;
    _p_runtime^._RowId := _2_e_rowId;
    loadRecord( _1_p_recordTable);
    q4selection.oneRecordSelect( _1_p_recordTable);
  End;

Function isNewRecord( Var _1_p_recordTable): boolean;
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    //https://developer.4d.com/docs/21/commands/is-new-record
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);
    Result := _p_runtime^._Loaded and ( _p_runtime^._RowId = Q4_NEW_RECORD);
  End;

Function isRecordLoaded( Var _1_p_recordTable): boolean;
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    //https://developer.4d.com/docs/21/commands/is-record-loaded
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);
    Result := _p_runtime^._Loaded;
  End;

Function modifiedRecord( Var _1_p_recordTable): boolean;
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    //https://developer.4d.com/docs/21/commands/modified-record
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);
    Result := _p_runtime^._Loaded and ( _p_runtime^._Modified or ( _p_runtime^._RowId = Q4_NEW_RECORD));
  End;

Procedure popRecord( Var _1_p_recordTable);
  Var
    _p_runtime: Pq4recordRuntime;
    _y_saved:   TQ4PushedRecordState;
    _e_top:     int64;
  Begin
    //https://developer.4d.com/docs/21/commands/pop-record
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( Length( ty_pushedRecordsStack) = 0) Then Exit;

    _e_top := High( ty_pushedRecordsStack);
    _y_saved := ty_pushedRecordsStack[_e_top];

    q4interruptions.assertRaise(
      _y_saved.e_tableNo = _p_runtime^._noTable,
      'q4record.popRecord: top pushed record belongs to another table'
      );

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenCommand,
          'q4record.popRecord interdit pendant un trigger'
          );

    If ( ( _p_runtime^._ReadWrite) and ( not q4transaction.inTransaction) and ( _p_runtime^._RowId > 0) and ( _p_runtime^._RowId <> _y_saved.e_rowId)) Then
      q4RecordLocking.setRecordLock( _p_runtime^._noTable, _p_runtime^._RowId, ProcessState.processID, False);

    SetLength( ty_pushedRecordsStack, _e_top);

    _p_runtime^._RowId := _y_saved.e_rowId;
    _p_runtime^._Loaded := _y_saved.b_loaded;
    _p_runtime^._Modified := _y_saved.b_modified;
    _p_runtime^._ReadWrite := False;
    InternalCloneVariantArray( _y_saved.y_arraySQL, _p_runtime^._ArraySQL);
    copyArraySQLToBindings( _p_runtime^._Bindings, _y_saved.y_currentValues);

    If ( _y_saved.b_readWriteReserved and ( _p_runtime^._RowId > 0) and ( not q4RecordLocking.readOnlyState( _1_p_recordTable))) Then _p_runtime^._ReadWrite :=
        q4RecordLocking.setRecordLock( _p_runtime^._noTable, _p_runtime^._RowId, ProcessState.processID, True);
  End;

Procedure pushRecord( Var _1_p_recordTable);
  Var
    _p_runtime: Pq4recordRuntime;
    _e_len:     int64;
  Begin
    //https://developer.4d.com/docs/21/commands/push-record
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( not _p_runtime^._Loaded) Then Exit;

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenCommand,
          'q4record.pushRecord interdit pendant un trigger'
          );

    _e_len := Length( ty_pushedRecordsStack);
    SetLength( ty_pushedRecordsStack, _e_len + 1);

    ty_pushedRecordsStack[_e_len].e_tableNo := _p_runtime^._noTable;
    ty_pushedRecordsStack[_e_len].e_rowId := _p_runtime^._RowId;
    ty_pushedRecordsStack[_e_len].b_loaded := _p_runtime^._Loaded;
    ty_pushedRecordsStack[_e_len].b_modified := _p_runtime^._Modified;
    ty_pushedRecordsStack[_e_len].b_readWriteReserved := _p_runtime^._ReadWrite and ( _p_runtime^._RowId > 0);
    InternalCloneVariantArray( _p_runtime^._ArraySQL, ty_pushedRecordsStack[_e_len].y_arraySQL);
    SetLength( ty_pushedRecordsStack[_e_len].y_currentValues, Length( _p_runtime^._Bindings));
    copyAllBindingsToArraySQL( _p_runtime^._Bindings, ty_pushedRecordsStack[_e_len].y_currentValues);
  End;

Function recordNumber( Var _1_p_recordTable): int64;
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    //https://developer.4d.com/docs/21/commands/record-number
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( not _p_runtime^._Loaded) Then Begin
      Result := Q4_NO_CURRENT_RECORD;
      Exit;
    End;

    Result := _p_runtime^._RowId;
  End;

Function recordsInTable( Var _1_p_recordTable): int64;
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    //https://developer.4d.com/docs/21/commands/records-in-table
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);
    Result := InternalRecordsInTableSQL( _p_runtime^._noTable);
  End;

Procedure saveRecord( Var _1_p_recordTable);
  Var
    _p_runtime: Pq4recordRuntime;
    _ty_fields: TChangedFieldArray;
    _t_error:   string;
  Begin
    //https://developer.4d.com/docs/21/commands/save-record

    clearLastSaveRecordError;
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenCommand,
          'q4record.saveRecord interdit pendant un trigger'
          );

    If ( not _p_runtime^._Loaded) Then Exit;

    // --------------------------------------------------------------------------
    // Nouveau record
    // --------------------------------------------------------------------------
    If ( _p_runtime^._RowId = Q4_NEW_RECORD) Then Begin

      // Réparation avant trigger : le trigger doit recevoir un record cohérent.
      If ( not repairAllBindingsForSave( _p_runtime^._noTable, _p_runtime^._Bindings, _t_error)) Then Begin
        setLastSaveRecordError( _t_error);
        Exit;
      End;

      If ( q4triggerRuntime.triggersEnabled) Then Begin
        q4triggerRuntime.q4BeginTrigger( _p_runtime^._noTable, q4teOnSavingNewRecord);
        Try
          q4triggerRuntime.q4ExecuteTrigger( _1_p_recordTable, q4teOnSavingNewRecord);
        Finally
          q4triggerRuntime.q4EndTrigger;
        End;
      End;

      // Réparation finale : le trigger a pu modifier les valeurs.
      If ( not repairAllBindingsForSave( _p_runtime^._noTable, _p_runtime^._Bindings, _t_error)) Then Begin
        setLastSaveRecordError( _t_error);
        Exit;
      End;

      _ty_fields := getFilledInsertFields( _p_runtime^._Bindings);

      _p_runtime^._RowId := internalInsertRecordSQL( _p_runtime^._noTable, _p_runtime^._Bindings, _ty_fields);

      copyAllBindingsToArraySQL( _p_runtime^._Bindings, _p_runtime^._ArraySQL);
      _p_runtime^._Modified := False;
      Exit;
    End;

    // --------------------------------------------------------------------------
    // Record existant
    // --------------------------------------------------------------------------
    If ( not _p_runtime^._ReadWrite) Then Exit;

    _ty_fields := getChangedFields( _p_runtime^._Bindings, _p_runtime^._ArraySQL);

    If ( Length( _ty_fields) = 0) Then Begin
      _p_runtime^._Modified := False;
      Exit;
    End;

    // Réparation avant trigger sur les champs modifiés.
    If ( not repairChangedBindingsForSave( _p_runtime^._noTable, _p_runtime^._Bindings, _ty_fields, _t_error)) Then Begin
      setLastSaveRecordError( _t_error);
      Exit;
    End;

    // La réparation peut avoir changé les valeurs et donc la liste réelle des champs modifiés.
    _ty_fields := getChangedFields( _p_runtime^._Bindings, _p_runtime^._ArraySQL);

    If ( Length( _ty_fields) = 0) Then Begin
      _p_runtime^._Modified := False;
      Exit;
    End;

    If ( q4triggerRuntime.triggersEnabled) Then Begin
      q4triggerRuntime.q4BeginTrigger( _p_runtime^._noTable, q4teOnSavingExistingRecord);
      Try
        q4triggerRuntime.q4ExecuteTrigger( _1_p_recordTable, q4teOnSavingExistingRecord);
      Finally
        q4triggerRuntime.q4EndTrigger;
      End;
    End;

    // Le trigger peut avoir modifié d'autres champs.
    _ty_fields := getChangedFields( _p_runtime^._Bindings, _p_runtime^._ArraySQL);

    If ( Length( _ty_fields) = 0) Then Begin
      _p_runtime^._Modified := False;
      Exit;
    End;

    // Réparation finale juste avant SQL et avant bascule vers _ArraySQL.
    If ( not repairChangedBindingsForSave( _p_runtime^._noTable, _p_runtime^._Bindings, _ty_fields, _t_error)) Then Begin
      setLastSaveRecordError( _t_error);
      Exit;
    End;

    // La réparation finale peut encore réduire ou modifier la liste des champs à écrire.
    _ty_fields := getChangedFields( _p_runtime^._Bindings, _p_runtime^._ArraySQL);

    If ( Length( _ty_fields) = 0) Then Begin
      _p_runtime^._Modified := False;
      Exit;
    End;

    internalUpdateRecordSQL(
      _p_runtime^._noTable,
      _p_runtime^._Bindings,
      _ty_fields,
      _p_runtime^._RowId
      );

    copyChangedBindingsToArraySQL(
      _p_runtime^._Bindings,
      _ty_fields,
      _p_runtime^._ArraySQL
      );

    _p_runtime^._Modified := False;
  End;

Function sequenceNumber( Var _1_p_recordTable): int64;
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    //https://developer.4d.com/docs/21/commands/sequence-number
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);
    Result := InternalSequenceNumberSQL( _p_runtime^._noTable);
  End;

Procedure syncLoadedRecordAfterRollback( Var _1_p_recordTable);
  Var
    _p_runtime:  Pq4recordRuntime;
    _y_arraySQL: TVariantArray;
    _ty_fields:  TChangedFieldArray;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( not _p_runtime^._Loaded) Then Exit;

    // Nouveau record jamais enregistré ou redevenu nouveau après rollback
    If ( _p_runtime^._RowId = Q4_NEW_RECORD) Then Begin
      _p_runtime^._Loaded := True;
      _p_runtime^._Modified := True;
      //p_runtime^._ReadWrite := True;  inutile
      Exit;
    End;

    // Pas de record courant exploitable
    If ( _p_runtime^._RowId <= 0) Then Exit;

    SetLength( _y_arraySQL, Length( _p_runtime^._ArraySQL));

    // La ligne n'existe plus après rollback :
    // on garde les valeurs mémoire, mais le runtime redevient "new record"
    If ( not selectRecordToArraySQL( _p_runtime^._noTable, _p_runtime^._RowId, _y_arraySQL)) Then Begin
      _p_runtime^._Loaded := True;
      _p_runtime^._Modified := True;
      //p_runtime^._ReadWrite := True;  théoriquement, doit être ok
      _p_runtime^._RowId := Q4_NEW_RECORD;
      Exit;
    End;

    // La ligne existe encore : on garde les valeurs mémoire
    // et on marque simplement le record comme modifié si elles diffèrent
    _ty_fields := getChangedFields( _p_runtime^._Bindings, _y_arraySQL);
    _p_runtime^._Loaded := True;
    _p_runtime^._Modified := Length( _ty_fields) > 0;
  End;

Procedure syncLoadedRecordsAfterRollbackForLockedTables;
  Var
    _e_tableIndex: int64;
    _e_tableNo:    int64;
    _p_table:      Pointer;
    _p_runtime:    Pq4recordRuntime;
  Begin
    For _e_tableIndex := Low( Tables) To High( Tables) Do Begin
      _e_tableNo := Tables[_e_tableIndex].SourceTableId;
      If ( _e_tableNo <= 0) Then Continue;

      If ( not q4RecordLocking.currentProcessHasLocksOnTable( _e_tableNo)) Then Continue;
      If ( not resolveTablePointerBySourceTableId( _e_tableNo, _p_table)) Then Continue;
      If ( _p_table = nil) Then Continue;

      _p_runtime := Pq4recordRuntime( _p_table);
      If ( _p_runtime = nil) Then Continue;
      If ( not _p_runtime^._Loaded) Then Continue;

      syncLoadedRecordAfterRollback( _p_table);
    End;
  End;

Procedure syncLoadedRecordAfterRollback( Var _1_p_table: Pointer); overload;
  Begin
    syncLoadedRecordAfterRollback( runtimeOf( _1_p_table)^);
  End;

End.
