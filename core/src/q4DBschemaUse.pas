Unit q4DBschemaUse;

{$mode objfpc}{$H+}

{
q4DBschemaUse
version du 2026/05/15-00:00

Mapping 4D -> q4DBschemaUse -> statut

4D Command            q4 API                        Statut
------------------------------------------------------
n/a infrastructure    getSourceTableId              OK
n/a infrastructure    getSourceTableName            OK
n/a infrastructure    findLocalBindingIndex         OK
n/a infrastructure    findLocalBindingIndexByName   OK
n/a infrastructure    findFieldMetaByName           OK
n/a infrastructure    findFieldMetaByFieldNo        OK
n/a infrastructure    getTableCount                 OK
n/a infrastructure    getTableMetaAtIndex           OK
n/a infrastructure    tableIsVisibleInUserInterface OK spécifique
n/a infrastructure    fieldIsVisibleInUserInterface OK
n/a infrastructure    resolveLocalFieldMeta         OK
n/a infrastructure    resolveLocalFieldMetaByName   OK
n/a infrastructure    resolveLocalFieldPointerByName OK
n/a infrastructure    resolveLocalFieldSQLName      OK
n/a infrastructure    findDirectLink                OK
n/a infrastructure    findTableJoinRange            OK
n/a infrastructure    resolveFieldPointerGlobal     OK
n/a infrastructure    resolveFieldPointer           OK

Notes:
- Cette unité consomme metier_q4DBschemaBase et metier_q4DBschemaProcess.
- Elle évite de mettre de la logique dans les unités générées.
- La résolution locale par pointeur est implémentée.
- La résolution globale par pointeur s'appuie sur les contextes threadvar
  générés dans metier_q4DBschemaProcess.
- Les helpers User Interface centralisent les choix liés à l'affichage de la
  structure virtuelle q4, afin que q4userInterface ne dépende pas directement
  des tableaux générés Tables / Fields.

----------------------------------------------------------------------
}

Interface

Uses
  SysUtils,
  variants,
  metier_q4DBschemaBase,
  metier_q4DBschemaProcess;

Type
  Tq4recordRuntime = Record
    _noTable: int64;
    _ReadWrite: boolean;
    _Loaded: boolean;
    _Modified: boolean;
    _RowId: int64;
    _ArraySQL: TVariantArray;
    _Bindings: TFieldBindingArray;
  End;

  Pq4recordRuntime = ^Tq4recordRuntime;


Type
  Tq4FieldValidationSource = (
    q4fvsSQLite,
    q4fvsUserInput,
    q4fvsRecord
    );

  Tq4FieldValidationPolicy = (
    q4fvpStrict,
    q4fvpNormalizeSafe,
    q4fvpRepairForSave
    );


Function getSourceTableId( Var _1_p_recordTable): int64; overload;
Function getSourceTableId( Var _1_p_table: Pointer): int64; overload;

Function getSourceTableName( Var _1_p_recordTable): string; overload;
Function getSourceTableName( Var _1_p_table: Pointer): string; overload;

Function getTableCount: int64;
Function getTableMetaAtIndex( Const _1_e_tableIndex: int64; out _2_y_table: TTableMeta): boolean;
Function findTableMeta( Const _1_e_sourceTableId: int64; out _2_y_table: TTableMeta): boolean;
Function findFieldMetaAtTableOffset( Const _1_e_sourceTableId: int64; Const _2_e_fieldOffset: int64; out _3_y_field: TFieldMeta): boolean;
Function findFieldMetaByName( Const _1_e_sourceTableId: int64; Const _2_t_fieldName: string; out _3_y_field: TFieldMeta): boolean;
Function findFieldMetaByFieldNo( Const _1_e_sourceTableId: int64; Const _2_e_fieldNo: int64; out _3_y_field: TFieldMeta): boolean;
Function tableIsVisibleInUserInterface( Const _1_e_sourceTableId: int64): boolean;
Function fieldIsVisibleInUserInterface( Const _1_y_field: TFieldMeta): boolean;

Function findLocalBindingIndex( Var _1_p_recordTable; Const _2_p_field: Pointer): int64; overload;
Function findLocalBindingIndex( Var _1_p_table: Pointer; Const _2_p_field: Pointer): int64; overload;
Function findLocalBindingIndexByName( Var _1_p_recordTable; Const _2_t_fieldName: string): int64; overload;
Function findLocalBindingIndexByName( Var _1_p_table: Pointer; Const _2_t_fieldName: string): int64; overload;

Function isLocalFieldPointer( Var _1_p_recordTable; Const _2_p_field: Pointer): boolean; overload;
Function isLocalFieldPointer( Var _1_p_table: Pointer; Const _2_p_field: Pointer): boolean; overload;

Function resolveLocalFieldMeta( Var _1_p_recordTable; Const _2_p_field: Pointer; out _3_y_field: TFieldMeta): boolean; overload;
Function resolveLocalFieldMeta( Var _1_p_table: Pointer; Const _2_p_field: Pointer; out _3_y_field: TFieldMeta): boolean; overload;
Function resolveLocalFieldMetaByName( Var _1_p_recordTable; Const _2_t_fieldName: string; out _3_y_field: TFieldMeta): boolean; overload;
Function resolveLocalFieldMetaByName( Var _1_p_table: Pointer; Const _2_t_fieldName: string; out _3_y_field: TFieldMeta): boolean; overload;
Function resolveLocalFieldPointerByName( Var _1_p_recordTable; Const _2_t_fieldName: string; out _3_p_field: Pointer): boolean; overload;
Function resolveLocalFieldPointerByName( Var _1_p_table: Pointer; Const _2_t_fieldName: string; out _3_p_field: Pointer): boolean; overload;

Function resolveLocalFieldSQLName( Var _1_p_recordTable; Const _2_p_field: Pointer; out _3_t_sqlFieldName: string): boolean; overload;
Function resolveLocalFieldSQLName( Var _1_p_table: Pointer; Const _2_p_field: Pointer; out _3_t_sqlFieldName: string): boolean; overload;

Function findTableJoinRange( Const _1_e_sourceTableId: int64; out _2_y_range: TTableJoinRange): boolean;
Function findDirectLink( Const _1_e_sourceTableId: int64; Const _2_e_targetTableId: int64; out _3_y_link: TJoinLinkMeta): boolean;

Function resolveFieldPointerGlobal( Const _1_p_field: Pointer; out _2_e_ownerTableId: int64; out _3_y_field: TFieldMeta): boolean;
Function resolveFieldPointerGlobalLoadFirst( Const _1_p_field: Pointer; out _2_e_ownerTableId: int64; out _3_y_field: TFieldMeta): boolean;
Function resolveFieldPointerGlobalReadWriteFirst( Const _1_p_field: Pointer; out _2_e_ownerTableId: int64; out _3_y_field: TFieldMeta): boolean;

Function resolveFieldPointer( Var _1_p_recordTable; Const _2_p_field: Pointer; out _3_e_ownerTableId: int64; out _4_y_field: TFieldMeta; out _5_b_isLocalField: boolean): boolean; overload;
Function resolveFieldPointer( Var _1_p_table: Pointer; Const _2_p_field: Pointer; out _3_e_ownerTableId: int64; out _4_y_field: TFieldMeta; out _5_b_isLocalField: boolean): boolean; overload;

Function findTableNumByName( Const _1_t_tableName: string): int64;

Function resolveTablePointerBySourceTableId( Const _1_e_sourceTableId: int64; out _2_p_table: Pointer): boolean;
Function findBindingIndexByFieldNo( Const _1_e_sourceTableId: int64; Const _2_e_fieldNo: int64): int64;
Function findBindingIndexByFieldName( Const _1_e_sourceTableId: int64; Const _2_t_fieldName: string): int64;
Function resolveFieldPointerByIds( Const _1_e_sourceTableId: int64; Const _2_e_fieldNo: int64; out _3_p_field: Pointer): boolean;
Function resolveTablePointerToSourceTableId( Const _1_p_table: Pointer; out _2_e_sourceTableId: int64): boolean;

Function q4FieldFullName( Const _1_y_field: TFieldMeta): string;

Function q4ValidateFieldValue( Const _1_y_field: TFieldMeta; Const _2_y_rawValue: variant; Const _3_e_source: Tq4FieldValidationSource;
  Const _4_e_policy: Tq4FieldValidationPolicy; out _5_y_normalizedValue: variant; out _6_t_error: string): boolean;

Function q4ValidateFieldByTableAndNo( Const _1_e_sourceTableId: int64; Const _2_e_fieldNo: int64; Const _3_y_rawValue: variant; Const _4_e_source: Tq4FieldValidationSource;
  Const _5_e_policy: Tq4FieldValidationPolicy; out _6_y_normalizedValue: variant; out _7_t_error: string): boolean;

Function q4ValidateFieldByName( Const _1_e_sourceTableId: int64; Const _2_t_fieldName: string; Const _3_y_rawValue: variant; Const _4_e_source: Tq4FieldValidationSource;
  Const _5_e_policy: Tq4FieldValidationPolicy; out _6_y_normalizedValue: variant; out _7_t_error: string): boolean;

Function sqlIdentifier( Const _1_t_name: string): string;
Function sqlQualifiedIdentifier( Const _1_t_alias: string; Const _2_t_name: string): string;

Implementation


Uses
  q4interruptions,
  q4dateAndTime;

Function runtimeOf( Var _1_p_table: Pointer): Pq4recordRuntime; Inline;
  Begin
    Result := Pq4recordRuntime( _1_p_table);
  End;

Const
  Q4_EMPTY_DATE = '0000-00-00';
  Q4_EMPTY_TIME = '00:00:00';

Function sqlIdentifier( Const _1_t_name: string): string;
  Begin
    Result := '"' + SysUtils.StringReplace( _1_t_name, '"', '""', [rfReplaceAll]) + '"';
  End;

Function sqlQualifiedIdentifier( Const _1_t_alias: string; Const _2_t_name: string): string;
  Begin
    Result := q4DBschemaUse.sqlIdentifier( _1_t_alias) + '.' + q4DBschemaUse.sqlIdentifier( _2_t_name);
  End;

Function q4FieldFullName( Const _1_y_field: TFieldMeta): string;
  Begin
    Result :=
      'TableRef=' + IntToStr( _1_y_field.TableRef) + ', FieldNo=' + IntToStr( _1_y_field.FieldNo) + ', Name="' + _1_y_field.Name + '"';
  End;

Function q4ValueToString( Const _1_y_value: variant): string;
  Begin
    If ( VarIsNull( _1_y_value) or VarIsEmpty( _1_y_value)) Then Result := ''
    Else
      Result := VarToStr( _1_y_value);
  End;

Function q4HasTextMaxLength( Const _1_y_field: TFieldMeta): boolean;
  Begin
    // Longueur = nombre maximal de caractères UTF-8 saisissables.
    // Longueur = 999 signifie pas de limite métier q4.
    Result := ( _1_y_field.Longueur > 0) and ( _1_y_field.Longueur <> 999);
  End;

Function q4UTF8CharLenAt( Const _1_t_value: string; Const _2_e_index: int64): int64;
  Var
    _e_byte: byte;
  Begin
    Result := 1;

    If ( ( _2_e_index < 1) or ( _2_e_index > Length( _1_t_value))) Then Exit;

    _e_byte := Ord( _1_t_value[_2_e_index]);

    If ( _e_byte < $80) Then Result := 1
    Else If ( ( _e_byte and $E0) = $C0) Then Result := 2
    Else If ( ( _e_byte and $F0) = $E0) Then Result := 3
    Else If ( ( _e_byte and $F8) = $F0) Then Result := 4
    Else
      Result := 1;

    If ( _2_e_index + Result - 1 > Length( _1_t_value)) Then Result := 1;
  End;

Function q4UTF8CharCount( Const _1_t_value: string): int64;
  Var
    _e_index: int64;
  Begin
    Result := 0;
    _e_index := 1;

    While ( _e_index <= Length( _1_t_value)) Do Begin
      Inc( _e_index, q4UTF8CharLenAt( _1_t_value, _e_index));
      Inc( Result);
    End;
  End;

Function q4UTF8CopyChars( Const _1_t_value: string; Const _2_e_maxChars: int64): string;
  Var
    _e_index:   int64;
    _e_count:   int64;
    _e_charLen: int64;
  Begin
    Result := '';

    If ( _2_e_maxChars <= 0) Then Exit;

    _e_index := 1;
    _e_count := 0;

    While ( ( _e_index <= Length( _1_t_value)) and ( _e_count < _2_e_maxChars)) Do Begin
      _e_charLen := q4UTF8CharLenAt( _1_t_value, _e_index);
      Result := Result + Copy( _1_t_value, _e_index, _e_charLen);
      Inc( _e_index, _e_charLen);
      Inc( _e_count);
    End;
  End;

Function q4ValidateTextValue( Const _1_y_field: TFieldMeta; Const _2_y_rawValue: variant; Const _3_e_policy: Tq4FieldValidationPolicy;
  out _4_y_normalizedValue: variant; out _5_t_error: string): boolean;
  Var
    _t_value: string;
    _e_len:   int64;
  Begin
    Result := False;
    _5_t_error := '';

    _t_value := q4ValueToString( _2_y_rawValue);
    _4_y_normalizedValue := _t_value;

    If ( q4HasTextMaxLength( _1_y_field)) Then Begin
      _e_len := q4UTF8CharCount( _t_value);

      If ( _e_len > _1_y_field.Longueur) Then Begin
        If ( _3_e_policy = q4fvpRepairForSave) Then Begin
          _4_y_normalizedValue := q4UTF8CopyChars( _t_value, _1_y_field.Longueur);
          Exit( True);
        End;

        _5_t_error :=
          'Valeur trop longue pour ' + q4FieldFullName( _1_y_field) + ': maximum=' + IntToStr( _1_y_field.Longueur) + ' caractères, obtenu=' + IntToStr( _e_len);
        Exit;
      End;
    End;

    Result := True;
  End;

Function q4ValidateDateValue( Const _1_y_field: TFieldMeta; Const _2_y_rawValue: variant; Const _3_e_policy: Tq4FieldValidationPolicy;
  out _4_y_normalizedValue: variant; out _5_t_error: string): boolean;
  Var
    _t_value:      string;
    _t_normalized: string;
  Begin
    Result := False;
    _5_t_error := '';

    _t_value := Trim( q4ValueToString( _2_y_rawValue));

    If ( _t_value = '') Then Begin
      If ( _3_e_policy = q4fvpRepairForSave) Then Begin
        _4_y_normalizedValue := Q4_EMPTY_DATE;
        Exit( True);
      End;

      _4_y_normalizedValue := '';
      Exit( True);
    End;

    _t_normalized := q4dateAndTime.normalizeDate( _t_value);

    If ( _t_normalized <> '') Then Begin
      If ( ( _3_e_policy = q4fvpStrict) and ( _t_normalized <> _t_value)) Then Begin
        _5_t_error :=
          'Date non canonique pour ' + q4FieldFullName( _1_y_field) + ': attendu="' + _t_normalized + '", reçu="' + _t_value + '"';
        Exit;
      End;

      _4_y_normalizedValue := _t_normalized;
      Exit( True);
    End;

    If ( _3_e_policy = q4fvpRepairForSave) Then Begin
      _4_y_normalizedValue := Q4_EMPTY_DATE;
      Exit( True);
    End;

    _5_t_error :=
      'Date invalide pour ' + q4FieldFullName( _1_y_field) + ': "' + _t_value + '"';
  End;

Function q4TryNormalizeExtendedTime( Const _1_t_value: string; out _2_t_normalized: string): boolean;
  Var
    _t_s:   string;
    _e_p1:  SizeInt;
    _e_p2Local: SizeInt;
    _e_p2:  SizeInt;
    _t_h:   string;
    _t_m:   string;
    _t_sec: string;
    _e_h:   int64;
    _e_m:   int64;
    _e_sec: int64;
  Begin
    Result := False;
    _2_t_normalized := '';
    _t_s := Trim( _1_t_value);

    _e_p1 := Pos( ':', _t_s);
    If ( _e_p1 <= 0) Then Exit;

    _e_p2Local := Pos( ':', Copy( _t_s, _e_p1 + 1, MaxInt));
    If ( _e_p2Local <= 0) Then Exit;

    _e_p2 := _e_p1 + _e_p2Local;

    If ( Pos( ':', Copy( _t_s, _e_p2 + 1, MaxInt)) > 0) Then Exit;

    _t_h := Copy( _t_s, 1, _e_p1 - 1);
    _t_m := Copy( _t_s, _e_p1 + 1, _e_p2 - _e_p1 - 1);
    _t_sec := Copy( _t_s, _e_p2 + 1, MaxInt);

    If ( ( _t_h = '') or ( _t_m = '') or ( _t_sec = '')) Then Exit;

    If ( not TryStrToInt64( _t_h, _e_h)) Then Exit;
    If ( not TryStrToInt64( _t_m, _e_m)) Then Exit;
    If ( not TryStrToInt64( _t_sec, _e_sec)) Then Exit;

    If ( _e_h < 0) Then Exit;
    If ( ( _e_m < 0) or ( _e_m > 59)) Then Exit;
    If ( ( _e_sec < 0) or ( _e_sec > 59)) Then Exit;

    _2_t_normalized :=
      IntToStr( _e_h) + ':' + Format( '%.2d', [_e_m]) + ':' + Format( '%.2d', [_e_sec]);
    Result := True;
  End;

Function q4ValidateTimeValue( Const _1_y_field: TFieldMeta; Const _2_y_rawValue: variant; Const _3_e_policy: Tq4FieldValidationPolicy;
  out _4_y_normalizedValue: variant; out _5_t_error: string): boolean;
  Var
    _t_value:      string;
    _t_normalized: string;
  Begin
    Result := False;
    _5_t_error := '';

    _t_value := Trim( q4ValueToString( _2_y_rawValue));

    If ( _t_value = '') Then Begin
      If ( _3_e_policy = q4fvpRepairForSave) Then _4_y_normalizedValue := Q4_EMPTY_TIME
      Else
        _4_y_normalizedValue := '';
      Exit( True);
    End;

    If ( q4TryNormalizeExtendedTime( _t_value, _t_normalized)) Then Begin
      _4_y_normalizedValue := _t_normalized;
      Exit( True);
    End;

    If ( _3_e_policy = q4fvpRepairForSave) Then Begin
      _4_y_normalizedValue := Q4_EMPTY_TIME;
      Exit( True);
    End;

    _5_t_error :=
      'Heure invalide pour ' + q4FieldFullName( _1_y_field) + ': "' + _t_value + '"';
  End;

Function q4ValidateScalarNotEmpty( Const _1_y_field: TFieldMeta; Const _2_y_rawValue: variant; out _3_y_normalizedValue: variant; out _4_t_error: string): boolean;
  Begin
    Result := False;
    _4_t_error := '';
    _3_y_normalizedValue := _2_y_rawValue;

    If ( _1_y_field.Mandatory and ( VarIsNull( _2_y_rawValue) or VarIsEmpty( _2_y_rawValue) or ( Trim( VarToStr( _2_y_rawValue)) = ''))) Then Begin
      _4_t_error := 'Champ obligatoire vide: ' + q4FieldFullName( _1_y_field);
      Exit;
    End;

    Result := True;
  End;

Function q4ValidateFieldValue( Const _1_y_field: TFieldMeta; Const _2_y_rawValue: variant; Const _3_e_source: Tq4FieldValidationSource;
  Const _4_e_policy: Tq4FieldValidationPolicy; out _5_y_normalizedValue: variant; out _6_t_error: string): boolean;
  Begin
    Result := False;
    _6_t_error := '';
    _5_y_normalizedValue := _2_y_rawValue;

    Case _1_y_field.FieldKind Of
      fkText: Exit( q4ValidateTextValue( _1_y_field, _2_y_rawValue, _4_e_policy, _5_y_normalizedValue, _6_t_error));

      fkDate: Exit( q4ValidateDateValue( _1_y_field, _2_y_rawValue, _4_e_policy, _5_y_normalizedValue, _6_t_error));

      fkTime: Exit( q4ValidateTimeValue( _1_y_field, _2_y_rawValue, _4_e_policy, _5_y_normalizedValue, _6_t_error));

      fkInteger,
      fkLongint,
      fkInt64,
      fkReal,
      fkBoolean: Exit( q4ValidateScalarNotEmpty( _1_y_field, _2_y_rawValue, _5_y_normalizedValue, _6_t_error));

      fkBlob: Begin
        _5_y_normalizedValue := _2_y_rawValue;
        Exit( True);
      End;
    End;

    _6_t_error := 'Type de champ non géré: ' + q4FieldFullName( _1_y_field);
  End;

Function q4ValidateFieldByTableAndNo( Const _1_e_sourceTableId: int64; Const _2_e_fieldNo: int64; Const _3_y_rawValue: variant; Const _4_e_source: Tq4FieldValidationSource;
  Const _5_e_policy: Tq4FieldValidationPolicy; out _6_y_normalizedValue: variant; out _7_t_error: string): boolean;
  Var
    _e_bindingIndex: int64;
    _y_field: TFieldMeta;
  Begin
    Result := False;
    _7_t_error := '';

    _e_bindingIndex := findBindingIndexByFieldNo( _1_e_sourceTableId, _2_e_fieldNo);

    If ( _e_bindingIndex < 0) Then Begin
      _7_t_error :=
        'Champ introuvable: table=' + IntToStr( _1_e_sourceTableId) + ', fieldNo=' + IntToStr( _2_e_fieldNo);
      Exit;
    End;

    If ( not findFieldMetaAtTableOffset( _1_e_sourceTableId, _e_bindingIndex, _y_field)) Then Begin
      _7_t_error :=
        'Métadonnées de champ introuvables: table=' + IntToStr( _1_e_sourceTableId) + ', fieldNo=' + IntToStr( _2_e_fieldNo);
      Exit;
    End;

    Result := q4ValidateFieldValue( _y_field, _3_y_rawValue, _4_e_source, _5_e_policy, _6_y_normalizedValue, _7_t_error);
  End;

Function q4ValidateFieldByName( Const _1_e_sourceTableId: int64; Const _2_t_fieldName: string; Const _3_y_rawValue: variant; Const _4_e_source: Tq4FieldValidationSource;
  Const _5_e_policy: Tq4FieldValidationPolicy; out _6_y_normalizedValue: variant; out _7_t_error: string): boolean;
  Var
    _y_field: TFieldMeta;
  Begin
    Result := False;
    _7_t_error := '';

    If ( not findFieldMetaByName( _1_e_sourceTableId, _2_t_fieldName, _y_field)) Then Begin
      _7_t_error :=
        'Champ introuvable: table=' + IntToStr( _1_e_sourceTableId) + ', champ="' + _2_t_fieldName + '"';
      Exit;
    End;

    Result := q4ValidateFieldValue( _y_field, _3_y_rawValue, _4_e_source, _5_e_policy, _6_y_normalizedValue, _7_t_error);
  End;

Function getSourceTableId( Var _1_p_table: Pointer): int64; overload;
  Begin
    Result := getSourceTableId( runtimeOf( _1_p_table)^);
  End;

Function getSourceTableName( Var _1_p_table: Pointer): string; overload;
  Begin
    Result := getSourceTableName( runtimeOf( _1_p_table)^);
  End;

Function findLocalBindingIndex( Var _1_p_table: Pointer; Const _2_p_field: Pointer): int64; overload;
  Begin
    Result := findLocalBindingIndex( runtimeOf( _1_p_table)^, _2_p_field);
  End;

Function findLocalBindingIndexByName( Var _1_p_table: Pointer; Const _2_t_fieldName: string): int64; overload;
  Begin
    Result := findLocalBindingIndexByName( runtimeOf( _1_p_table)^, _2_t_fieldName);
  End;

Function isLocalFieldPointer( Var _1_p_table: Pointer; Const _2_p_field: Pointer): boolean; overload;
  Begin
    Result := isLocalFieldPointer( runtimeOf( _1_p_table)^, _2_p_field);
  End;

Function resolveLocalFieldMeta( Var _1_p_table: Pointer; Const _2_p_field: Pointer; out _3_y_field: TFieldMeta): boolean; overload;
  Begin
    Result := resolveLocalFieldMeta( runtimeOf( _1_p_table)^, _2_p_field, _3_y_field);
  End;

Function resolveLocalFieldMetaByName( Var _1_p_table: Pointer; Const _2_t_fieldName: string; out _3_y_field: TFieldMeta): boolean; overload;
  Begin
    Result := resolveLocalFieldMetaByName( runtimeOf( _1_p_table)^, _2_t_fieldName, _3_y_field);
  End;

Function resolveLocalFieldPointerByName( Var _1_p_table: Pointer; Const _2_t_fieldName: string; out _3_p_field: Pointer): boolean; overload;
  Begin
    Result := resolveLocalFieldPointerByName( runtimeOf( _1_p_table)^, _2_t_fieldName, _3_p_field);
  End;

Function resolveLocalFieldSQLName( Var _1_p_table: Pointer; Const _2_p_field: Pointer; out _3_t_sqlFieldName: string): boolean; overload;
  Begin
    Result := resolveLocalFieldSQLName( runtimeOf( _1_p_table)^, _2_p_field, _3_t_sqlFieldName);
  End;

Function resolveFieldPointer( Var _1_p_table: Pointer; Const _2_p_field: Pointer; out _3_e_ownerTableId: int64; out _4_y_field: TFieldMeta; out _5_b_isLocalField: boolean): boolean; overload;
  Begin
    Result := resolveFieldPointer( runtimeOf( _1_p_table)^, _2_p_field, _3_e_ownerTableId, _4_y_field, _5_b_isLocalField);
  End;

Function InternalTableArrayIndexFromSourceId( Const _1_e_sourceTableId: int64): int64;
  Var
    _e_i: int64;
  Begin
    Result := -1;

    For _e_i := 0 To System.High( Tables) Do If ( Tables[_e_i].SourceTableId = _1_e_sourceTableId) Then Begin
        Result := _e_i;
        Exit;
      End;
  End;

Function InternalFieldArrayIndexFromTableOffset( Const _1_y_table: TTableMeta; Const _2_e_fieldOffset: int64): int64;
  Begin
    Result := _1_y_table.FieldIndex + _2_e_fieldOffset;
  End;

Function InternalResolveInRuntime( Const _1_p_runtime: Pq4recordRuntime; Const _2_p_field: Pointer; out _3_e_ownerTableId: int64; out _4_y_field: TFieldMeta): boolean;
  Var
    _e_i: int64;
  Begin
    Result := False;
    _3_e_ownerTableId := 0;

    If ( _1_p_runtime = nil) Then Exit;
    If ( _2_p_field = nil) Then Exit;

    For _e_i := 0 To System.High( _1_p_runtime^._Bindings) Do If ( _1_p_runtime^._Bindings[_e_i].ValuePtr = _2_p_field) Then Begin
        _3_e_ownerTableId := _1_p_runtime^._noTable;
        Result := findFieldMetaAtTableOffset( _3_e_ownerTableId, _e_i, _4_y_field);
        Exit;
      End;
  End;

Function InternalTryResolveInRecord( Var _1_p_recordTable; Const _2_p_field: Pointer; out _3_e_ownerTableId: int64; out _4_y_field: TFieldMeta): boolean;
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);
    Result := InternalResolveInRuntime( _p_runtime, _2_p_field, _3_e_ownerTableId, _4_y_field);
  End;

Function InternalTryResolveTablePointer( Var _1_p_recordTable; Const _2_e_sourceTableId: int64; out _3_p_table: Pointer): boolean;
  Begin
    _3_p_table := nil;

    If ( getSourceTableId( _1_p_recordTable) <> _2_e_sourceTableId) Then Exit( False);

    _3_p_table := @_1_p_recordTable;
    Exit( True);
  End;

Function getSourceTableId( Var _1_p_recordTable): int64; overload;
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);
    Result := _p_runtime^._noTable;
  End;

Function getSourceTableName( Var _1_p_recordTable): string; overload;
  Var
    _y_table: TTableMeta;
  Begin
    Result := '';

    If ( findTableMeta( getSourceTableId( _1_p_recordTable), _y_table)) Then Begin
      Result := _y_table.Name;
      Exit;
    End;
  End;

Function getTableCount: int64;
  Begin
    Result := System.High( Tables) - System.Low( Tables) + 1;
  End;

Function getTableMetaAtIndex( Const _1_e_tableIndex: int64; out _2_y_table: TTableMeta): boolean;
  Begin
    Result := False;

    If ( ( _1_e_tableIndex < System.Low( Tables)) or ( _1_e_tableIndex > System.High( Tables))) Then Exit;

    _2_y_table := Tables[_1_e_tableIndex];
    Result := True;
  End;

Function findTableMeta( Const _1_e_sourceTableId: int64; out _2_y_table: TTableMeta): boolean;
  Var
    _e_idx: int64;
  Begin
    Result := False;
    _e_idx := InternalTableArrayIndexFromSourceId( _1_e_sourceTableId);

    If ( _e_idx < 0) Then Exit;

    _2_y_table := Tables[_e_idx];
    Result := True;
  End;

Function findTableNumByName( Const _1_t_tableName: string): int64;
  Var
    i: int64;
  Begin
    Result := -1;

    For i := Low( Tables) To High( Tables) Do If ( SameText( Tables[i].Name, _1_t_tableName)) Then Exit( Tables[i].SourceTableId);
  End;

Function findFieldMetaAtTableOffset( Const _1_e_sourceTableId: int64; Const _2_e_fieldOffset: int64; out _3_y_field: TFieldMeta): boolean;
  Var
    _y_table: TTableMeta;
    _e_fieldArrayIndex: int64;
  Begin
    Result := False;

    If ( not findTableMeta( _1_e_sourceTableId, _y_table)) Then Exit;

    If ( ( _2_e_fieldOffset < 0) or ( _2_e_fieldOffset >= _y_table.FieldCount)) Then Exit;

    _e_fieldArrayIndex := InternalFieldArrayIndexFromTableOffset( _y_table, _2_e_fieldOffset);

    If ( ( _e_fieldArrayIndex < 0) or ( _e_fieldArrayIndex > System.High( Fields))) Then Exit;

    _3_y_field := Fields[_e_fieldArrayIndex];
    Result := True;
  End;

Function findFieldMetaByName( Const _1_e_sourceTableId: int64; Const _2_t_fieldName: string; out _3_y_field: TFieldMeta): boolean;
  Var
    _y_table: TTableMeta;
    _e_fieldOffset: int64;
    _e_fieldArrayIndex: int64;
  Begin
    Result := False;

    If ( _2_t_fieldName = '') Then Exit;
    If ( not findTableMeta( _1_e_sourceTableId, _y_table)) Then Exit;

    For _e_fieldOffset := 0 To _y_table.FieldCount - 1 Do Begin
      _e_fieldArrayIndex := InternalFieldArrayIndexFromTableOffset( _y_table, _e_fieldOffset);

      q4interruptions.assertRaise(
        ( _e_fieldArrayIndex >= 0) and ( _e_fieldArrayIndex <= System.High( Fields)),
        'q4DBschemaUse.findFieldMetaByName: index de champ hors limites'
        );

      If ( SameText( Fields[_e_fieldArrayIndex].Name, _2_t_fieldName)) Then Begin
        _3_y_field := Fields[_e_fieldArrayIndex];
        Exit( True);
      End;
    End;
  End;

Function findFieldMetaByFieldNo( Const _1_e_sourceTableId: int64; Const _2_e_fieldNo: int64; out _3_y_field: TFieldMeta): boolean;
  Var
    _y_table: TTableMeta;
    _e_fieldOffset: int64;
    _e_fieldArrayIndex: int64;
  Begin
    Result := False;

    If ( not findTableMeta( _1_e_sourceTableId, _y_table)) Then Exit;

    For _e_fieldOffset := 0 To _y_table.FieldCount - 1 Do Begin
      _e_fieldArrayIndex := InternalFieldArrayIndexFromTableOffset( _y_table, _e_fieldOffset);

      q4interruptions.assertRaise(
        ( _e_fieldArrayIndex >= 0) and ( _e_fieldArrayIndex <= System.High( Fields)),
        'q4DBschemaUse.findFieldMetaByFieldNo: index de champ hors limites'
        );

      If ( Fields[_e_fieldArrayIndex].FieldNo = _2_e_fieldNo) Then Begin
        _3_y_field := Fields[_e_fieldArrayIndex];
        Exit( True);
      End;
    End;
  End;

Function tableIsVisibleInUserInterface( Const _1_e_sourceTableId: int64): boolean;
  Var
    _y_table: TTableMeta;
  Begin
    Result := False;

    If ( not findTableMeta( _1_e_sourceTableId, _y_table)) Then Exit;

    // La table 0 est une table système q4 ajoutée au schéma généré.
    // Elle n'existe pas comme table utilisateur 4D et ne doit pas être exposée
    // par GET TABLE TITLES.
    If ( _y_table.SourceTableId <= 0) Then Exit;

    // Limitation actuelle : TTableMeta ne porte pas encore InvisibleUI.
    // Quand le générateur ajoutera cette propriété, ce test devra être enrichi
    // ici, afin de ne pas disperser cette règle dans q4userInterface.
    Result := True;
  End;

Function fieldIsVisibleInUserInterface( Const _1_y_field: TFieldMeta): boolean;
  Begin
    Result := not _1_y_field.InvisibleUI;
  End;

Function findLocalBindingIndex( Var _1_p_recordTable; Const _2_p_field: Pointer): int64; overload;
  Var
    _p_runtime: Pq4recordRuntime;
    _e_i: int64;
  Begin
    Result := -1;

    If ( _2_p_field = nil) Then Exit;

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    For _e_i := 0 To System.High( _p_runtime^._Bindings) Do If ( _p_runtime^._Bindings[_e_i].ValuePtr = _2_p_field) Then Begin
        Result := _e_i;
        Exit;
      End;
  End;

Function findLocalBindingIndexByName( Var _1_p_recordTable; Const _2_t_fieldName: string): int64; overload;
  Var
    _y_field: TFieldMeta;
  Begin
    Result := -1;

    If ( not resolveLocalFieldMetaByName( _1_p_recordTable, _2_t_fieldName, _y_field)) Then Exit;

    Result := findBindingIndexByFieldNo( getSourceTableId( _1_p_recordTable), _y_field.FieldNo);
  End;

Function isLocalFieldPointer( Var _1_p_recordTable; Const _2_p_field: Pointer): boolean;
  Begin
    Result := findLocalBindingIndex( _1_p_recordTable, _2_p_field) >= 0;
  End;

Function resolveLocalFieldMeta( Var _1_p_recordTable; Const _2_p_field: Pointer; out _3_y_field: TFieldMeta): boolean; overload;
  Var
    _e_bindingIndex:  int64;
    _e_sourceTableId: int64;
  Begin
    Result := False;
    _e_bindingIndex := findLocalBindingIndex( _1_p_recordTable, _2_p_field);

    If ( _e_bindingIndex < 0) Then Exit;

    _e_sourceTableId := getSourceTableId( _1_p_recordTable);
    Result := findFieldMetaAtTableOffset( _e_sourceTableId, _e_bindingIndex, _3_y_field);
  End;

Function resolveLocalFieldMetaByName( Var _1_p_recordTable; Const _2_t_fieldName: string; out _3_y_field: TFieldMeta): boolean; overload;
  Var
    _e_sourceTableId: int64;
  Begin
    Result := False;

    _e_sourceTableId := getSourceTableId( _1_p_recordTable);
    Result := findFieldMetaByName( _e_sourceTableId, _2_t_fieldName, _3_y_field);
  End;

Function resolveLocalFieldPointerByName( Var _1_p_recordTable; Const _2_t_fieldName: string; out _3_p_field: Pointer): boolean; overload;
  Var
    _p_runtime:      Pq4recordRuntime;
    _e_bindingIndex: int64;
  Begin
    Result := False;
    _3_p_field := nil;

    _e_bindingIndex := findLocalBindingIndexByName( _1_p_recordTable, _2_t_fieldName);
    If ( _e_bindingIndex < 0) Then Exit;

    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( ( _e_bindingIndex < 0) or ( _e_bindingIndex > System.High( _p_runtime^._Bindings))) Then Exit;

    _3_p_field := _p_runtime^._Bindings[_e_bindingIndex].ValuePtr;
    Result := _3_p_field <> nil;
  End;

Function resolveLocalFieldSQLName( Var _1_p_recordTable; Const _2_p_field: Pointer; out _3_t_sqlFieldName: string): boolean; overload;
  Var
    _y_field: TFieldMeta;
  Begin
    Result := False;
    _3_t_sqlFieldName := '';

    If ( not resolveLocalFieldMeta( _1_p_recordTable, _2_p_field, _y_field)) Then Exit;

    _3_t_sqlFieldName := _y_field.Name;
    Result := True;
  End;

Function findTableJoinRange( Const _1_e_sourceTableId: int64; out _2_y_range: TTableJoinRange): boolean;
  Var
    _e_i: int64;
  Begin
    Result := False;

    For _e_i := 0 To System.High( TableJoinRanges) Do If ( TableJoinRanges[_e_i].SourceTableId = _1_e_sourceTableId) Then Begin
        _2_y_range := TableJoinRanges[_e_i];
        Result := True;
        Exit;
      End;
  End;

Function findDirectLink( Const _1_e_sourceTableId: int64; Const _2_e_targetTableId: int64; out _3_y_link: TJoinLinkMeta): boolean;
  Var
    _y_range: TTableJoinRange;
    _e_i:     int64;
    _e_last:  int64;
  Begin
    Result := False;

    If ( not findTableJoinRange( _1_e_sourceTableId, _y_range)) Then Exit;

    _e_last := _y_range.LinkIndex + _y_range.LinkCount - 1;

    For _e_i := _y_range.LinkIndex To _e_last Do Begin
      q4interruptions.assertRaise(
        ( _e_i >= 0) and ( _e_i <= System.High( JoinLinks)),
        'q4DBschemaUse.findDirectLink: index de lien hors limites'
        );

      If ( JoinLinks[_e_i].TargetTableId = _2_e_targetTableId) Then Begin
        _3_y_link := JoinLinks[_e_i];
        Result := True;
        Exit;
      End;
    End;
  End;

Function findBindingIndexByFieldNo( Const _1_e_sourceTableId: int64; Const _2_e_fieldNo: int64): int64;
  Var
    _y_table: TTableMeta;
    _e_fieldOffset: int64;
    _e_fieldArrayIndex: int64;
  Begin
    Result := -1;

    If ( not findTableMeta( _1_e_sourceTableId, _y_table)) Then Exit;

    For _e_fieldOffset := 0 To _y_table.FieldCount - 1 Do Begin
      _e_fieldArrayIndex := InternalFieldArrayIndexFromTableOffset( _y_table, _e_fieldOffset);

      q4interruptions.assertRaise(
        ( _e_fieldArrayIndex >= 0) and ( _e_fieldArrayIndex <= System.High( Fields)),
        'q4DBschemaUse.findBindingIndexByFieldNo: index de champ hors limites'
        );

      If ( Fields[_e_fieldArrayIndex].FieldNo = _2_e_fieldNo) Then Exit( _e_fieldOffset);
    End;
  End;

Function findBindingIndexByFieldName( Const _1_e_sourceTableId: int64; Const _2_t_fieldName: string): int64;
  Var
    _y_field: TFieldMeta;
  Begin
    Result := -1;

    If ( not findFieldMetaByName( _1_e_sourceTableId, _2_t_fieldName, _y_field)) Then Exit;

    Result := findBindingIndexByFieldNo( _1_e_sourceTableId, _y_field.FieldNo);
  End;

Function InternalTryResolveInRecordLoad( Var _1_p_recordTable; Const _2_p_field: Pointer; out _3_e_ownerTableId: int64; out _4_y_field: TFieldMeta): boolean;
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( not _p_runtime^._Loaded) Then Exit( False);

    Result := InternalResolveInRuntime( _p_runtime, _2_p_field, _3_e_ownerTableId, _4_y_field);
  End;

Function InternalTryResolveInRecordReadWriteOnly( Var _1_p_recordTable; Const _2_p_field: Pointer; out _3_e_ownerTableId: int64; out _4_y_field: TFieldMeta): boolean;
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( not _p_runtime^._ReadWrite) Then Exit( False);

    Result := InternalResolveInRuntime( _p_runtime, _2_p_field, _3_e_ownerTableId, _4_y_field);
  End;

Function resolveFieldPointerGlobal( Const _1_p_field: Pointer; out _2_e_ownerTableId: int64; out _3_y_field: TFieldMeta): boolean;

  Function InternalTryRecord( Var _1_p_recordTable): boolean;
    Begin
      Result := InternalTryResolveInRecord( _1_p_recordTable, _1_p_field, _2_e_ownerTableId, _3_y_field);
    End;

  Begin
    _2_e_ownerTableId := 0;

    If ( _1_p_field = nil) Then Exit( False);

    {$I ..\metier_q4\metier_q4DBschemaUse_records.inc}

    Exit( False);
  End;

Function resolveFieldPointerGlobalLoadFirst( Const _1_p_field: Pointer; out _2_e_ownerTableId: int64; out _3_y_field: TFieldMeta): boolean;

  Function InternalTryRecord( Var _1_p_recordTable): boolean;
    Begin
      Result := InternalTryResolveInRecordLoad( _1_p_recordTable, _1_p_field, _2_e_ownerTableId, _3_y_field);
    End;

  Begin
    _2_e_ownerTableId := 0;

    If ( _1_p_field = nil) Then Exit( False);

    { 1er passage : uniquement _Loaded }
    {$I ..\metier_q4\metier_q4DBschemaUse_records.inc}

    { 2e passage : fallback standard }
    Result := resolveFieldPointerGlobal( _1_p_field, _2_e_ownerTableId, _3_y_field);
  End;

Function resolveFieldPointerGlobalReadWriteFirst( Const _1_p_field: Pointer; out _2_e_ownerTableId: int64; out _3_y_field: TFieldMeta): boolean;

  Function InternalTryRecord( Var _1_p_recordTable): boolean;
    Begin
      Result := InternalTryResolveInRecordReadWriteOnly( _1_p_recordTable, _1_p_field, _2_e_ownerTableId, _3_y_field);
    End;

  Begin
    _2_e_ownerTableId := 0;

    If ( _1_p_field = nil) Then Exit( False);

    { 1er passage : uniquement _ReadWrite }
    {$I ..\metier_q4\metier_q4DBschemaUse_records.inc}

    { 2e passage : fallback standard }
    Result := resolveFieldPointerGlobal( _1_p_field, _2_e_ownerTableId, _3_y_field);
  End;

Function resolveTablePointerBySourceTableId( Const _1_e_sourceTableId: int64; out _2_p_table: Pointer): boolean;

  Function InternalTryRecord( Var _1_p_recordTable): boolean;
    Begin
      Result := InternalTryResolveTablePointer( _1_p_recordTable, _1_e_sourceTableId, _2_p_table);
    End;

  Begin
    _2_p_table := nil;

    If ( _1_e_sourceTableId <= 0) Then Exit( False);

    {$I ..\metier_q4\metier_q4DBschemaUse_records.inc}

    Exit( False);
  End;

Function InternalTryResolveTablePointerToSourceTableId( Var _1_p_recordTable; Const _2_p_table: Pointer; out _3_e_sourceTableId: int64): boolean;
  Begin
    _3_e_sourceTableId := 0;

    If ( @_1_p_recordTable <> _2_p_table) Then Exit( False);

    _3_e_sourceTableId := getSourceTableId( _1_p_recordTable);
    Exit( _3_e_sourceTableId > 0);
  End;

Function resolveTablePointerToSourceTableId( Const _1_p_table: Pointer; out _2_e_sourceTableId: int64): boolean;

  Function InternalTryRecord( Var _1_p_recordTable): boolean;
    Begin
      Result := InternalTryResolveTablePointerToSourceTableId( _1_p_recordTable, _1_p_table, _2_e_sourceTableId);
    End;

  Begin
    _2_e_sourceTableId := 0;

    If ( _1_p_table = nil) Then Exit( False);

    {$I ..\metier_q4\metier_q4DBschemaUse_records.inc}

    Exit( False);
  End;

Function resolveFieldPointerByIds( Const _1_e_sourceTableId: int64; Const _2_e_fieldNo: int64; out _3_p_field: Pointer): boolean;
  Var
    _p_table:   Pointer;
    _p_runtime: Pq4recordRuntime;
    _e_bindingIndex: int64;
  Begin
    _3_p_field := nil;

    If ( not resolveTablePointerBySourceTableId( _1_e_sourceTableId, _p_table)) Then Exit( False);

    _e_bindingIndex := findBindingIndexByFieldNo( _1_e_sourceTableId, _2_e_fieldNo);
    If ( _e_bindingIndex < 0) Then Exit( False);

    _p_runtime := runtimeOf( _p_table);
    If ( _p_runtime = nil) Then Exit( False);

    If ( ( _e_bindingIndex < 0) or ( _e_bindingIndex > System.High( _p_runtime^._Bindings))) Then Exit( False);

    _3_p_field := _p_runtime^._Bindings[_e_bindingIndex].ValuePtr;
    Exit( _3_p_field <> nil);
  End;

Function resolveFieldPointer( Var _1_p_recordTable; Const _2_p_field: Pointer; out _3_e_ownerTableId: int64; out _4_y_field: TFieldMeta; out _5_b_isLocalField: boolean): boolean;
  Begin
    Result := False;
    _3_e_ownerTableId := 0;
    _5_b_isLocalField := False;

    If ( _2_p_field = nil) Then Exit;

    If ( resolveLocalFieldMeta( _1_p_recordTable, _2_p_field, _4_y_field)) Then Begin
      _3_e_ownerTableId := getSourceTableId( _1_p_recordTable);
      _5_b_isLocalField := True;
      Result := True;
      Exit;
    End;

    If ( resolveFieldPointerGlobal( _2_p_field, _3_e_ownerTableId, _4_y_field)) Then Begin
      _5_b_isLocalField := False;
      Result := True;
      Exit;
    End;
  End;

End.
