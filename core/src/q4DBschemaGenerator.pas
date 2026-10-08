Unit q4DBschemaGenerator;

{$mode objfpc}{$H+}

{
  ----------------------------------------------------------------------
  AUTO-GENERATED HELPER SOURCE
  ----------------------------------------------------------------------

  Purpose           : Generate 'metier_q4DBschemaBase.pas', 'q4DschemaProcess.pas' and 'metier_q4DBschemaUse_records.inc' from structureBD.csv and structureLiens.csv
  Compatible with   : Lazarus / FreePascal
  Notes             : First practical version, designed to be readable
                      and easy to adapt.

  Main entry point  : Generatemetier_q4DBschemaBase(...)
  ----------------------------------------------------------------------
}

Interface

Uses
  Classes, SysUtils, q4interruptions;

Type
  Tmetier_q4DBschemaBaseGenerateOptions = Record
    InputCsvFile: string;
    InputLinksCsvFile: string;
    OutputPasDir: string;
    OutputPasFile: string;
    UnitName: string;
    GeneratorName: string;
    CsvSeparator: char;
  End;

Procedure Initmetier_q4DBschemaBaseGenerateOptions;
Procedure Generatemetier_q4DBschemaBase;
Procedure Generatemetier_q4DBschemaBaseDefault;

Implementation

Type
  TFieldKind = (
    fkText,
    fkDate,
    fkTime,
    fkInteger,
    fkLongint,
    fkInt64,
    fkReal,
    fkBlob,
    fkBoolean
    );

  TFieldRow = Record
    TableId: int64;
    TableName: string;
    FieldId: int64;
    FieldName: string;
    TypeMetier: string;
    TypeSQLite: string;
    TypeLazarus: string;
    Longueur: int64;
    PrimaryKey: boolean;
    Indexed: boolean;
    UniqueKey: boolean;
    Obligatoire: boolean;
    InvisibleUI: boolean;
    EditableUI: boolean;
    Modifiable: boolean;
    ListeDeChoix: string;
  End;

  TFieldMetaDef = Record
    TableRef: int64;
    FieldNo: int64;
    Name: string;
    TypeSQL: string;
    TypePascal: string;
    FieldKind: TFieldKind;
    Longueur: int64;
    Indexed: boolean;
    UniqueKey: boolean;
    Mandatory: boolean;
    InvisibleUI: boolean;
    EditableUI: boolean;
    Modifiable: boolean;
    ChoiceList: string;
  End;

  TTableMetaDef = Record
    SourceTableId: int64;
    Name: string;
    FieldIndex: int64;
    FieldCount: int64;
    PrimaryKey: string;
    Comment: string;
  End;

  TLinkRow = Record
    SourceTableId: int64;
    SourceTableName: string;
    SourceFieldId: int64;
    SourceFieldName: string;
    TypeLien: string;
    TargetTableId: int64;
    TargetTableName: string;
    TargetFieldId: int64;
    TargetFieldName: string;
  End;

  TLinkMetaDef = Record
    SourceTableId: int64;
    SourceFieldId: int64;
    TargetTableId: int64;
    TargetFieldId: int64;
  End;

  TTableLinkRangeDef = Record
    SourceTableId: int64;
    LinkIndex: int64;
    LinkCount: int64;
  End;

  TFieldRowArray = Array Of TFieldRow;
  TFieldMetaArray = Array Of TFieldMetaDef;
  TTableMetaArray = Array Of TTableMetaDef;
  TLinkRowArray = Array Of TLinkRow;
  TLinkMetaArray = Array Of TLinkMetaDef;
  TTableLinkRangeArray = Array Of TTableLinkRangeDef;


Var
  e_lengthTableDefs: int64;
  e_lengthFieldDefs: int64;
  e_lengthLinkDefs: int64;
  AOptions: Tmetier_q4DBschemaBaseGenerateOptions;

Function GetExecutableDir: string;
  Begin
    Result := ExpandFileName( ExtractFileDir( ParamStr( 0)));
  End;

Function GetProjectRootDir: string;
  Begin
    Result := ExpandFileName( GetExecutableDir + '\..\..');
  End;

Function GetQ4infosDir: string;
  Begin
    Result := IncludeTrailingPathDelimiter( GetProjectRootDir) + 'q4\metier_q4';
  End;

Function BoolToPascal( Const _1_b_value: boolean): string;
  Begin
    If ( _1_b_value) Then Result := 'True'
    Else
      Result := 'False';
  End;

Function SameTextTrim( Const _1_t_a, _2_t_b: string): boolean;
  Begin
    Result := SameText( Trim( _1_t_a), Trim( _2_t_b));
  End;

Function StrToBoolLoose( Const _1_t_s: string): boolean;
  Var
    V: string;
  Begin
    V := Trim( LowerCase( _1_t_s));

    // Accepte :
    // - les booléens classiques : 1 / true / vrai / yes / oui
    // - les marqueurs visuels du dictionnaire : $PrimaryKey, $indexed, $visible, etc.
    // - plus généralement toute valeur non vide sauf les formes explicitement fausses
    Result :=
      ( V <> '') and not ( ( V = '0') or ( V = 'false') or ( V = 'faux') or ( V = 'no') or ( V = 'n') or ( V = 'non'));
  End;

Function StrToIntDefLoose( Const _1_t_s: string; Const _2_e_default: int64): int64;
  Begin
    Result := StrToIntDef( Trim( _1_t_s), _2_e_default);
  End;

Function PascalEscape( Const _1_t_s: string): string;
  Begin
    Result := StringReplace( _1_t_s, '''', '''''', [rfReplaceAll]);
  End;

Function MakeTimestamp: string;
  Begin
    Result := FormatDateTime( 'yyyy-mm-dd hh:nn:ss', Now);
  End;

Function ParseCsvLine( Const _1_t_line: string; Const _2_t_sep: char): TStringArray;
  Var
    I: int64;
    C: char;
    InQuotes: boolean;
    Current: string;

  Procedure PushCurrent;
    Begin
      SetLength( Result, Length( Result) + 1);
      Result[High( Result)] := Current;
      Current := '';
    End;

  Begin
    SetLength( Result, 0);
    Current := '';
    InQuotes := False;
    I := 1;
    While ( I <= Length( _1_t_line)) Do Begin
      C := _1_t_line[I];
      If ( C = '"') Then Begin
        If ( InQuotes and ( I < Length( _1_t_line)) and ( _1_t_line[I + 1] = '"')) Then Begin
          Current := Current + '"';
          Inc( I);
        End Else
          InQuotes := not InQuotes;
      End Else If ( ( C = _2_t_sep) and ( not InQuotes)) Then PushCurrent
      Else
        Current := Current + C;
      Inc( I);
    End;
    PushCurrent;
  End;

Function DetectCsvSeparator( Const _1_t_header: string): char;
  Begin
    If ( Pos( ';', _1_t_header) > 0) Then Result := ';'
    Else If ( Pos( #9, _1_t_header) > 0) Then Result := #9
    Else
      Result := ',';
  End;

Function FindColumnIndex( Const _1_tt_header: TStringArray; Const _2_t_name: string): int64;
  Var
    I: int64;
  Begin
    Result := -1;
    For I := 0 To High( _1_tt_header) Do If ( SameTextTrim( _1_tt_header[I], _2_t_name)) Then Exit( I);
  End;

Function GetCell( Const _1_tt_values: TStringArray; Const _2_e_index: int64): string;
  Begin
    If ( ( _2_e_index >= 0) and ( _2_e_index <= High( _1_tt_values))) Then Result := Trim( _1_tt_values[_2_e_index])
    Else
      Result := '';
  End;

Function CompareRows( constref _1_y_a, _2_y_b: TFieldRow): int64;
  Begin
    If ( _1_y_a.TableId < _2_y_b.TableId) Then Exit( -1);
    If ( _1_y_a.TableId > _2_y_b.TableId) Then Exit( 1);
    If ( _1_y_a.FieldId < _2_y_b.FieldId) Then Exit( -1);
    If ( _1_y_a.FieldId > _2_y_b.FieldId) Then Exit( 1);
    Result := CompareText( _1_y_a.FieldName, _2_y_b.FieldName);
  End;

Procedure QuickSortRows( Var _1_y_items: TFieldRowArray; _2_e_l, _3_e_r: int64);
  Var
    I, J, K: int64;
    P, T:    TFieldRow;
  Begin
    I := _2_e_l;
    J := _3_e_r;
    P := _1_y_items[( _2_e_l + _3_e_r) div 2];
    Repeat
      While ( CompareRows( _1_y_items[I], P) < 0) Do Inc( I);
      While ( CompareRows( _1_y_items[J], P) > 0) Do Dec( J);
      If ( I <= J) Then Begin
        T := _1_y_items[I];
        _1_y_items[I] := _1_y_items[J];
        _1_y_items[J] := T;
        Inc( I);
        Dec( J);
      End;
    Until ( I > J);
    If ( _2_e_l < J) Then QuickSortRows( _1_y_items, _2_e_l, J);
    If ( I < _3_e_r) Then QuickSortRows( _1_y_items, I, _3_e_r);
  End;

Procedure SortRows( Var _1_y_rows: TFieldRowArray);
  Begin
    If ( Length( _1_y_rows) > 1) Then QuickSortRows( _1_y_rows, 0, High( _1_y_rows));
  End;

Function CompareLinks( constref _1_y_a, _2_y_b: TLinkRow): int64;
  Begin
    If ( _1_y_a.SourceTableId < _2_y_b.SourceTableId) Then Exit( -1);
    If ( _1_y_a.SourceTableId > _2_y_b.SourceTableId) Then Exit( 1);
    If ( _1_y_a.TargetTableId < _2_y_b.TargetTableId) Then Exit( -1);
    If ( _1_y_a.TargetTableId > _2_y_b.TargetTableId) Then Exit( 1);
    If ( _1_y_a.SourceFieldId < _2_y_b.SourceFieldId) Then Exit( -1);
    If ( _1_y_a.SourceFieldId > _2_y_b.SourceFieldId) Then Exit( 1);
    If ( _1_y_a.TargetFieldId < _2_y_b.TargetFieldId) Then Exit( -1);
    If ( _1_y_a.TargetFieldId > _2_y_b.TargetFieldId) Then Exit( 1);
    Result := 0;
  End;

Procedure QuickSortLinks( Var _1_y_items: TLinkRowArray; _2_e_l, _3_e_r: int64);
  Var
    I, J: int64;
    P, T: TLinkRow;
  Begin
    I := _2_e_l;
    J := _3_e_r;
    P := _1_y_items[( _2_e_l + _3_e_r) div 2];
    Repeat
      While ( CompareLinks( _1_y_items[I], P) < 0) Do Inc( I);
      While ( CompareLinks( _1_y_items[J], P) > 0) Do Dec( J);
      If ( I <= J) Then Begin
        T := _1_y_items[I];
        _1_y_items[I] := _1_y_items[J];
        _1_y_items[J] := T;
        Inc( I);
        Dec( J);
      End;
    Until ( I > J);
    If ( _2_e_l < J) Then QuickSortLinks( _1_y_items, _2_e_l, J);
    If ( I < _3_e_r) Then QuickSortLinks( _1_y_items, I, _3_e_r);
  End;

Procedure SortLinks( Var _1_y_links: TLinkRowArray);
  Begin
    If ( Length( _1_y_links) > 1) Then QuickSortLinks( _1_y_links, 0, High( _1_y_links));
  End;


Function FindTableRowIndexByTableId( Const _1_y_rows: TFieldRowArray; Const _2_e_tableId: int64): int64;
  Var
    I: int64;
  Begin
    Result := -1;
    For I := 0 To High( _1_y_rows) Do If ( _1_y_rows[I].TableId = _2_e_tableId) Then Exit( I);
  End;

Function FindFieldRowIndex( Const _1_y_rows: TFieldRowArray; Const _2_e_tableId, _3_e_fieldId: int64): int64;
  Var
    I: int64;
  Begin
    Result := -1;
    For I := 0 To High( _1_y_rows) Do If ( ( _1_y_rows[I].TableId = _2_e_tableId) and ( _1_y_rows[I].FieldId = _3_e_fieldId)) Then Exit( I);
  End;

Function NormalizeSqlType( Const _1_t_s: string): string;
  Begin
    Result := UpperCase( Trim( _1_t_s));
  End;

Function IsSupportedSqlType( Const _1_t_s: string): boolean;
  Var
    V: string;
  Begin
    V := NormalizeSqlType( _1_t_s);
    Result :=
      ( V = '') or ( V = 'INTEGER') or ( V = 'INT') or ( V = 'SMALLINT') or ( V = 'BIGINT') or ( V = 'REAL') or ( V = 'DOUBLE') or ( V = 'NUMERIC') or
      ( V = 'BOOLEAN') or ( V = 'BLOB') or ( V = 'TEXT') or ( V = 'TEXT_ICU');
  End;

Procedure ValidateRows( Const _1_y_rows: TFieldRowArray);
  Var
    I: int64;
    CurrentTableId: int64;
    ExpectedFieldId: int64;
    CurrentTableName: string;
  Begin
    If ( Length( _1_y_rows) = 0) Then Raise Exception.Create( 'Le dictionnaire est vide.');

    CurrentTableId := -1;
    CurrentTableName := '';
    ExpectedFieldId := 0;

    For I := 0 To High( _1_y_rows) Do Begin
      If ( Trim( _1_y_rows[I].TableName) = '') Then Raise Exception.CreateFmt( 'table_name vide à la ligne logique %d.', [I + 2]);

      If ( Trim( _1_y_rows[I].FieldName) = '') Then Raise Exception.CreateFmt( 'field_name vide à la ligne logique %d.', [I + 2]);

      If ( Trim( _1_y_rows[I].TypeLazarus) = '') Then Raise Exception.CreateFmt( 'type_lazarus vide pour %s.%s.', [_1_y_rows[I].TableName, _1_y_rows[I].FieldName]);

      If ( not IsSupportedSqlType( _1_y_rows[I].TypeSQLite)) Then Raise Exception.CreateFmt( 'type_sqlite non géré pour %s.%s : %s.',
          [_1_y_rows[I].TableName, _1_y_rows[I].FieldName, _1_y_rows[I].TypeSQLite]);

      If ( _1_y_rows[I].TableId <> CurrentTableId) Then Begin
        If ( ( CurrentTableId >= 0) and ( _1_y_rows[I].TableId <= CurrentTableId)) Then Raise Exception.CreateFmt( 'table_id non croissant entre %d et %d.', [CurrentTableId, _1_y_rows[I].TableId]);

        CurrentTableId := _1_y_rows[I].TableId;
        CurrentTableName := _1_y_rows[I].TableName;
        ExpectedFieldId := 1;
      End;

      If ( _1_y_rows[I].FieldId <> ExpectedFieldId) Then Raise Exception.CreateFmt( 'field_id invalide pour la table %s : attendu %d, trouvé %d.',
          [CurrentTableName, ExpectedFieldId, _1_y_rows[I].FieldId]);

      Inc( ExpectedFieldId);
    End;
  End;

Function LoadRowsFromCsv( Const _1_t_fileName: string; Const _2_t_preferredSep: char): TFieldRowArray;
  Var
    Lines: TStringList;
    Header, Cells: TStringArray;
    Sep:   char;
    I:     int64;
    CTableId, CTableName, CFieldId, CFieldName: int64;
    CTypeMetier, CTypeSQLite, CTypeLazarus, CLongueur: int64;
    CPrimaryKey, CIndexed, CUnique, CObligatoire: int64;
    CInvisibleUI, CEditableUI, CModifiable, CListeDeChoix: int64;
    Row:   TFieldRow;
  Begin
    Lines := TStringList.Create;
    Try
      Lines.LoadFromFile( _1_t_fileName);

      If ( Lines.Count = 0) Then Raise Exception.CreateFmt( 'Fichier CSV vide : %s', [_1_t_fileName]);

      If ( _2_t_preferredSep <> #0) Then Sep := _2_t_preferredSep
      Else
        Sep := DetectCsvSeparator( Lines[0]);

      Header := ParseCsvLine( Lines[0], Sep);

      CTableId := FindColumnIndex( Header, 'table_id');
      CTableName := FindColumnIndex( Header, 'table_name');
      CFieldId := FindColumnIndex( Header, 'field_id');
      CFieldName := FindColumnIndex( Header, 'field_name');
      CTypeMetier := FindColumnIndex( Header, 'type_metier');
      CTypeSQLite := FindColumnIndex( Header, 'type_sqlite');
      CTypeLazarus := FindColumnIndex( Header, 'type_lazarus');
      CLongueur := FindColumnIndex( Header, 'longueur');
      CPrimaryKey := FindColumnIndex( Header, 'PrimaryKey');
      CIndexed := FindColumnIndex( Header, 'indexed');
      CUnique := FindColumnIndex( Header, 'unique');
      CObligatoire := FindColumnIndex( Header, 'Obligatoire');
      CInvisibleUI := FindColumnIndex( Header, 'invisible_ui');
      CEditableUI := FindColumnIndex( Header, 'editable_ui');
      CModifiable := FindColumnIndex( Header, 'Modifiable');
      CListeDeChoix := FindColumnIndex( Header, 'ListeDeChoix');

      If ( ( CTableId < 0) or ( CTableName < 0) or ( CFieldId < 0) or ( CFieldName < 0) or ( CTypeLazarus < 0)) Then Raise Exception.Create( 'Colonnes obligatoires absentes dans le CSV.');

      SetLength( Result, 0);
      For I := 1 To Lines.Count - 1 Do Begin
        If ( Trim( Lines[I]) = '') Then Continue;

        Cells := ParseCsvLine( Lines[I], Sep);

        Row := Default( TFieldRow);
        Row.TableId := StrToIntDefLoose( GetCell( Cells, CTableId), -1);
        Row.TableName := GetCell( Cells, CTableName);
        Row.FieldId := StrToIntDefLoose( GetCell( Cells, CFieldId), -1);
        Row.FieldName := GetCell( Cells, CFieldName);
        Row.TypeMetier := GetCell( Cells, CTypeMetier);
        Row.TypeSQLite := GetCell( Cells, CTypeSQLite);
        Row.TypeLazarus := GetCell( Cells, CTypeLazarus);
        Row.Longueur := StrToIntDefLoose( GetCell( Cells, CLongueur), 0);
        Row.PrimaryKey := StrToBoolLoose( GetCell( Cells, CPrimaryKey));
        Row.Indexed := StrToBoolLoose( GetCell( Cells, CIndexed));
        Row.UniqueKey := StrToBoolLoose( GetCell( Cells, CUnique));
        Row.Obligatoire := StrToBoolLoose( GetCell( Cells, CObligatoire));
        Row.InvisibleUI := StrToBoolLoose( GetCell( Cells, CInvisibleUI));
        Row.EditableUI := StrToBoolLoose( GetCell( Cells, CEditableUI));
        Row.Modifiable := StrToBoolLoose( GetCell( Cells, CModifiable));
        Row.ListeDeChoix := GetCell( Cells, CListeDeChoix);

        SetLength( Result, Length( Result) + 1);
        Result[High( Result)] := Row;
      End;
    Finally
      Lines.Free;
    End;
  End;


Function LoadLinksFromCsv( Const _1_t_fileName: string; Const _2_t_preferredSep: char): TLinkRowArray;
  Var
    Lines: TStringList;
    Header, Cells: TStringArray;
    Sep:   char;
    I:     int64;
    CSourceTableId, CSourceTableName, CSourceFieldId, CSourceFieldName: int64;
    CTypeLien, CTargetTableId, CTargetTableName, CTargetFieldId, CTargetFieldName: int64;
    Row:   TLinkRow;
  Begin
    If ( Trim( _1_t_fileName) = '') Then Exit( nil);

    Lines := TStringList.Create;
    Try
      Lines.LoadFromFile( _1_t_fileName);

      If ( Lines.Count = 0) Then Raise Exception.CreateFmt( 'Fichier CSV des liens vide : %s', [_1_t_fileName]);

      If ( _2_t_preferredSep <> #0) Then Sep := _2_t_preferredSep
      Else
        Sep := DetectCsvSeparator( Lines[0]);

      Header := ParseCsvLine( Lines[0], Sep);

      CSourceTableId := FindColumnIndex( Header, 'source_table_id');
      CSourceTableName := FindColumnIndex( Header, 'source_table_name');
      CSourceFieldId := FindColumnIndex( Header, 'source_field_id');
      CSourceFieldName := FindColumnIndex( Header, 'source_field_name');
      CTypeLien := FindColumnIndex( Header, 'type_lien');
      CTargetTableId := FindColumnIndex( Header, 'target_table_id');
      CTargetTableName := FindColumnIndex( Header, 'target_table_name');
      CTargetFieldId := FindColumnIndex( Header, 'target_field_id');
      CTargetFieldName := FindColumnIndex( Header, 'target_field_name');

      If ( ( CSourceTableId < 0) or ( CSourceTableName < 0) or ( CSourceFieldId < 0) or ( CSourceFieldName < 0) or ( CTypeLien < 0) or ( CTargetTableId < 0) or
        ( CTargetTableName < 0) or ( CTargetFieldId < 0) or ( CTargetFieldName < 0)) Then Raise Exception.Create( 'Colonnes obligatoires absentes dans le CSV des liens.');

      SetLength( Result, 0);
      For I := 1 To Lines.Count - 1 Do Begin
        If ( Trim( Lines[I]) = '') Then Continue;

        Cells := ParseCsvLine( Lines[I], Sep);
        Row := Default( TLinkRow);
        Row.SourceTableId := StrToIntDefLoose( GetCell( Cells, CSourceTableId), -1);
        Row.SourceTableName := GetCell( Cells, CSourceTableName);
        Row.SourceFieldId := StrToIntDefLoose( GetCell( Cells, CSourceFieldId), -1);
        Row.SourceFieldName := GetCell( Cells, CSourceFieldName);
        Row.TypeLien := GetCell( Cells, CTypeLien);
        Row.TargetTableId := StrToIntDefLoose( GetCell( Cells, CTargetTableId), -1);
        Row.TargetTableName := GetCell( Cells, CTargetTableName);
        Row.TargetFieldId := StrToIntDefLoose( GetCell( Cells, CTargetFieldId), -1);
        Row.TargetFieldName := GetCell( Cells, CTargetFieldName);

        SetLength( Result, Length( Result) + 1);
        Result[High( Result)] := Row;
      End;
    Finally
      Lines.Free;
    End;
  End;

Procedure ValidateLinks( Const _1_y_links: TLinkRowArray; Const _2_y_rows: TFieldRowArray);
  Var
    I, J, SrcFieldIdx, DstFieldIdx, SrcTableIdx, DstTableIdx: int64;
  Begin
    q4interruptions.assertRaise( Length( _1_y_links) > 0,
      'q4DBschemaGenerator.ValidateLinks : aucun lien defini dans structureLiens.csv');

    For I := 0 To High( _1_y_links) Do Begin
      q4interruptions.assertRaise( Trim( _1_y_links[I].SourceTableName) <> '',
        Format( 'q4DBschemaGenerator.ValidateLinks : source_table_name vide a la ligne logique %d', [I + 2]));
      q4interruptions.assertRaise( Trim( _1_y_links[I].SourceFieldName) <> '',
        Format( 'q4DBschemaGenerator.ValidateLinks : source_field_name vide a la ligne logique %d', [I + 2]));
      q4interruptions.assertRaise( Trim( _1_y_links[I].TargetTableName) <> '',
        Format( 'q4DBschemaGenerator.ValidateLinks : target_table_name vide a la ligne logique %d', [I + 2]));
      q4interruptions.assertRaise( Trim( _1_y_links[I].TargetFieldName) <> '',
        Format( 'q4DBschemaGenerator.ValidateLinks : target_field_name vide a la ligne logique %d', [I + 2]));
      q4interruptions.assertRaise( Trim( _1_y_links[I].TypeLien) = '',
        Format( 'q4DBschemaGenerator.ValidateLinks : type_lien doit etre vide pour %s.%s -> %s.%s', [_1_y_links[I].SourceTableName, _1_y_links[I].SourceFieldName,
        _1_y_links[I].TargetTableName, _1_y_links[I].TargetFieldName]));

      SrcTableIdx := FindTableRowIndexByTableId( _2_y_rows, _1_y_links[I].SourceTableId);
      DstTableIdx := FindTableRowIndexByTableId( _2_y_rows, _1_y_links[I].TargetTableId);
      q4interruptions.assertRaise( SrcTableIdx >= 0,
        Format( 'q4DBschemaGenerator.ValidateLinks : table source id %d introuvable', [_1_y_links[I].SourceTableId]));
      q4interruptions.assertRaise( DstTableIdx >= 0,
        Format( 'q4DBschemaGenerator.ValidateLinks : table cible id %d introuvable', [_1_y_links[I].TargetTableId]));

      q4interruptions.assertRaise( SameTextTrim( _2_y_rows[SrcTableIdx].TableName, _1_y_links[I].SourceTableName),
        Format( 'q4DBschemaGenerator.ValidateLinks : incoherence source_table_name pour table id %d', [_1_y_links[I].SourceTableId]));
      q4interruptions.assertRaise( SameTextTrim( _2_y_rows[DstTableIdx].TableName, _1_y_links[I].TargetTableName),
        Format( 'q4DBschemaGenerator.ValidateLinks : incoherence target_table_name pour table id %d', [_1_y_links[I].TargetTableId]));

      SrcFieldIdx := FindFieldRowIndex( _2_y_rows, _1_y_links[I].SourceTableId, _1_y_links[I].SourceFieldId);
      DstFieldIdx := FindFieldRowIndex( _2_y_rows, _1_y_links[I].TargetTableId, _1_y_links[I].TargetFieldId);
      q4interruptions.assertRaise( SrcFieldIdx >= 0,
        Format( 'q4DBschemaGenerator.ValidateLinks : champ source (%d,%d) introuvable', [_1_y_links[I].SourceTableId, _1_y_links[I].SourceFieldId]));
      q4interruptions.assertRaise( DstFieldIdx >= 0,
        Format( 'q4DBschemaGenerator.ValidateLinks : champ cible (%d,%d) introuvable', [_1_y_links[I].TargetTableId, _1_y_links[I].TargetFieldId]));

      q4interruptions.assertRaise( SameTextTrim( _2_y_rows[SrcFieldIdx].FieldName, _1_y_links[I].SourceFieldName),
        Format( 'q4DBschemaGenerator.ValidateLinks : incoherence source_field_name pour (%d,%d)', [_1_y_links[I].SourceTableId, _1_y_links[I].SourceFieldId]));
      q4interruptions.assertRaise( SameTextTrim( _2_y_rows[DstFieldIdx].FieldName, _1_y_links[I].TargetFieldName),
        Format( 'q4DBschemaGenerator.ValidateLinks : incoherence target_field_name pour (%d,%d)', [_1_y_links[I].TargetTableId, _1_y_links[I].TargetFieldId]));

      For J := 0 To I - 1 Do Begin
        q4interruptions.assertRaise( not ( ( _1_y_links[I].SourceTableId = _1_y_links[J].SourceTableId) and ( _1_y_links[I].SourceFieldId = _1_y_links[J].SourceFieldId)),
          Format( 'q4DBschemaGenerator.ValidateLinks : duplicate outgoing link for source table %d field %d', [_1_y_links[I].SourceTableId, _1_y_links[I].SourceFieldId]));
        q4interruptions.assertRaise( not ( ( _1_y_links[I].SourceTableId = _1_y_links[J].SourceTableId) and ( _1_y_links[I].TargetTableId = _1_y_links[J].TargetTableId)),
          Format( 'q4DBschemaGenerator.ValidateLinks : duplicate direct link for source table %d to target table %d', [_1_y_links[I].SourceTableId, _1_y_links[I].TargetTableId]));
      End;
    End;
  End;

Procedure BuildLinkMetadata( Const _1_y_links: TLinkRowArray; out _2_y_linkDefs: TLinkMetaArray; out _3_y_tableRanges: TTableLinkRangeArray);
  Var
    I, StartIdx, Count:   int64;
    CurrentSourceTableId: int64;
  Begin
    SetLength( _2_y_linkDefs, Length( _1_y_links));
    For I := 0 To High( _1_y_links) Do Begin
      _2_y_linkDefs[I].SourceTableId := _1_y_links[I].SourceTableId;
      _2_y_linkDefs[I].SourceFieldId := _1_y_links[I].SourceFieldId;
      _2_y_linkDefs[I].TargetTableId := _1_y_links[I].TargetTableId;
      _2_y_linkDefs[I].TargetFieldId := _1_y_links[I].TargetFieldId;
    End;

    SetLength( _3_y_tableRanges, 0);
    I := 0;
    While ( I <= High( _1_y_links)) Do Begin
      CurrentSourceTableId := _1_y_links[I].SourceTableId;
      StartIdx := I;
      Count := 0;
      While ( ( I <= High( _1_y_links)) and ( _1_y_links[I].SourceTableId = CurrentSourceTableId)) Do Begin
        Inc( Count);
        Inc( I);
      End;

      SetLength( _3_y_tableRanges, Length( _3_y_tableRanges) + 1);
      _3_y_tableRanges[High( _3_y_tableRanges)].SourceTableId := CurrentSourceTableId;
      _3_y_tableRanges[High( _3_y_tableRanges)].LinkIndex := StartIdx;
      _3_y_tableRanges[High( _3_y_tableRanges)].LinkCount := Count;
    End;
  End;

Function GetFieldKind( Const _1_y_row: TFieldRow): TFieldKind;
  Var
    LTypeSQLite: string;
  Begin
    LTypeSQLite := NormalizeSqlType( _1_y_row.TypeSQLite);

    If ( SameText( _1_y_row.TypeLazarus, 'Int64')) Then Result := fkInt64
    Else If ( SameText( _1_y_row.TypeMetier, 'date')) Then Result := fkDate
    Else If ( SameText( _1_y_row.TypeMetier, 'heure')) Then Result := fkTime
    Else If ( SameText( _1_y_row.TypeMetier, 'booleen')) Then Result := fkBoolean
    Else If ( SameText( _1_y_row.TypeMetier, 'entier')) Then Result := fkInteger
    Else If ( SameText( _1_y_row.TypeMetier, 'entierLong')) Then Result := fkLongint
    Else If ( SameText( _1_y_row.TypeMetier, 'image')) Then Result := fkBlob
    Else If ( SameText( _1_y_row.TypeLazarus, 'Boolean')) Then Result := fkBoolean
    Else If ( SameText( _1_y_row.TypeLazarus, 'SmallInt')) Then Result := fkInteger
    Else If ( SameText( _1_y_row.TypeLazarus, 'Integer') or SameText( _1_y_row.TypeLazarus, 'LongInt')) Then Result := fkLongint
    Else If ( SameText( _1_y_row.TypeLazarus, 'Double') or SameText( _1_y_row.TypeLazarus, 'Real')) Then Result := fkReal
    Else If ( SameText( _1_y_row.TypeLazarus, 'String')) Then Result := fkText
    Else If ( SameText( LTypeSQLite, 'BLOB')) Then Result := fkBlob
    Else If ( SameText( LTypeSQLite, 'TEXT') or SameText( LTypeSQLite, 'TEXT_ICU')) Then Result := fkText
    Else Begin
      q4interruptions.assertRaise( False,
        'GetFieldKind: type non géré pour ' + _1_y_row.TableName + '.' + _1_y_row.FieldName + ' (TypeMetier=' + _1_y_row.TypeMetier + ', TypeLazarus=' +
        _1_y_row.TypeLazarus + ', TypeSQLite=' + _1_y_row.TypeSQLite + ')');
      Result := fkText;
    End;
  End;


Function BuildFieldMeta( Const _1_y_row: TFieldRow; Const _2_e_tableRef: int64; Const _3_e_fieldNo: int64; Const _4_y_fieldKind: TFieldKind): TFieldMetaDef;
  Begin
    Result.TableRef := _2_e_tableRef;
    Result.FieldNo := _3_e_fieldNo;
    Result.Name := _1_y_row.FieldName;
    Result.TypeSQL := NormalizeSqlType( _1_y_row.TypeSQLite);
    Result.TypePascal := _1_y_row.TypeLazarus;
    Result.FieldKind := _4_y_fieldKind;
    Result.Longueur := _1_y_row.Longueur;
    Result.Indexed := _1_y_row.Indexed;
    Result.UniqueKey := _1_y_row.UniqueKey;
    Result.Mandatory := _1_y_row.Obligatoire;
    Result.InvisibleUI := _1_y_row.InvisibleUI;
    Result.EditableUI := _1_y_row.EditableUI;
    Result.Modifiable := _1_y_row.Modifiable;
    Result.ChoiceList := _1_y_row.ListeDeChoix;
  End;

Procedure BuildMetadata( Const _1_y_rows: TFieldRowArray; out _2_y_fields: TFieldMetaArray; out _3_y_tables: TTableMetaArray);
  Var
    I, J, TableStart, TableCount: int64;
    CurrentTable: string;
    LPrimaryKey:  string;
    TableRef:     int64;
    LPrimaryKeyCount: int64;
  Begin
    SetLength( _2_y_fields, Length( _1_y_rows));
    SetLength( _3_y_tables, 0);

    I := 0;
    While ( I <= High( _1_y_rows)) Do Begin
      CurrentTable := _1_y_rows[I].TableName;
      TableStart := I;
      TableCount := 0;
      LPrimaryKey := '';
      LPrimaryKeyCount := 0;

      While ( ( I <= High( _1_y_rows)) and SameText( _1_y_rows[I].TableName, CurrentTable)) Do Begin
        If ( _1_y_rows[I].PrimaryKey) Then Begin
          Inc( LPrimaryKeyCount);
          If ( LPrimaryKeyCount = 1) Then LPrimaryKey := _1_y_rows[I].FieldName;
        End;

        Inc( TableCount);
        Inc( I);
      End;

      If ( LPrimaryKeyCount = 0) Then Raise Exception.CreateFmt( 'Aucune clé primaire définie pour la table %s (table_id=%d, ligne logique %d) dans structureBD.csv.',
          [CurrentTable, _1_y_rows[TableStart].TableId, TableStart + 2]);

      If ( LPrimaryKeyCount > 1) Then Raise Exception.CreateFmt( 'Plusieurs champs PrimaryKey définis pour la table %s (table_id=%d, ligne logique %d) dans structureBD.csv. ' +
          'Le générateur q4 attend une clé primaire mono-champ.', [CurrentTable, _1_y_rows[TableStart].TableId, TableStart + 2]);

      TableRef := Length( _3_y_tables);
      SetLength( _3_y_tables, TableRef + 1);
      _3_y_tables[TableRef].SourceTableId := _1_y_rows[TableStart].TableId;
      _3_y_tables[TableRef].Name := CurrentTable;
      _3_y_tables[TableRef].FieldIndex := TableStart;
      _3_y_tables[TableRef].FieldCount := TableCount;
      _3_y_tables[TableRef].PrimaryKey := LPrimaryKey;
      _3_y_tables[TableRef].Comment := '';

      For J := 0 To TableCount - 1 Do _2_y_fields[TableStart + J] :=
          BuildFieldMeta( _1_y_rows[TableStart + J], TableRef, _1_y_rows[TableStart + J].FieldId, GetFieldKind( _1_y_rows[TableStart + J]));
    End;
  End;

Procedure AppendLine( _1_o_lines: TStrings; Const _2_t_s: string = '');
  Begin
    _1_o_lines.Add( _2_t_s);
  End;

Procedure GenerateHeaderBase( _1_o_lines: TStrings; Const _2_e_tableCount, _3_e_fieldCount, _4_e_linkCount: int64);
  Begin
    AppendLine( _1_o_lines, 'unit ' + AOptions.UnitName + ';');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '{$mode objfpc}{$H+}{$J-}  //Constante pour tableau');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '{');
    AppendLine( _1_o_lines, '  ----------------------------------------------------------------------');
    AppendLine( _1_o_lines, '  AUTO-GENERATED FILE - DO NOT MODIFY MANUALLY');
    AppendLine( _1_o_lines, '  ----------------------------------------------------------------------');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  Source dictionary : ' + ExtractFileName( AOptions.InputCsvFile));
    If ( Trim( AOptions.InputLinksCsvFile) <> '') Then AppendLine( _1_o_lines, '  Source links      : ' + ExtractFileName( AOptions.InputLinksCsvFile));
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  Tables count      : ' + IntToStr( _2_e_tableCount));
    AppendLine( _1_o_lines, '  Fields count      : ' + IntToStr( _3_e_fieldCount));
    AppendLine( _1_o_lines, '  Links count       : ' + IntToStr( _4_e_linkCount));
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  Generated         : ' + MakeTimestamp);
    AppendLine( _1_o_lines, '  Generated by      : ' + AOptions.GeneratorName);
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  This unit contains:');
    AppendLine( _1_o_lines, '  - Records representing database tables');
    AppendLine( _1_o_lines, '  - Metadata describing tables and fields');
    AppendLine( _1_o_lines, '  - Structures used for SQL generation and schema introspection');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  ----------------------------------------------------------------------');
    AppendLine( _1_o_lines, '}');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, 'interface');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, 'uses');
    AppendLine( _1_o_lines, '  Classes, SysUtils;');
    AppendLine( _1_o_lines, '');
  End;

Procedure GenerateTypes( _1_o_lines: TStrings);
  Begin
    AppendLine( _1_o_lines, 'type');
    AppendLine( _1_o_lines, '  TTableRef = Integer;');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  TFieldKind = (fkText, fkDate, fkTime, fkInteger, fkInt64, fkLongint, fkReal, fkBlob, fkBoolean);');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  TFieldMeta = record');
    AppendLine( _1_o_lines, '    TableRef    : Int64;');
    AppendLine( _1_o_lines, '    FieldNo     : Int64;');
    AppendLine( _1_o_lines, '    Name        : string;');
    AppendLine( _1_o_lines, '    TypeSQL     : string;');
    AppendLine( _1_o_lines, '    TypePascal  : string;');
    AppendLine( _1_o_lines, '    FieldKind   : TFieldKind;');
    AppendLine( _1_o_lines, '    Longueur    : Int64;');
    AppendLine( _1_o_lines, '    Indexed     : Boolean;');
    AppendLine( _1_o_lines, '    UniqueKey   : Boolean;');
    AppendLine( _1_o_lines, '    Mandatory   : Boolean;');
    AppendLine( _1_o_lines, '    InvisibleUI   : Boolean;');
    AppendLine( _1_o_lines, '    EditableUI  : Boolean;');
    AppendLine( _1_o_lines, '    Modifiable  : Boolean;');
    AppendLine( _1_o_lines, '    ChoiceList  : string;');
    AppendLine( _1_o_lines, '  end;');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  TTableMeta = record');
    AppendLine( _1_o_lines, '    SourceTableId : Int64;');
    AppendLine( _1_o_lines, '    Name          : string;');
    AppendLine( _1_o_lines, '    FieldIndex    : Int64;');
    AppendLine( _1_o_lines, '    FieldCount    : Int64;');
    AppendLine( _1_o_lines, '    PrimaryKey    : string;');
    AppendLine( _1_o_lines, '    Comment       : string;');
    AppendLine( _1_o_lines, '  end;');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  TJoinLinkMeta = record');
    AppendLine( _1_o_lines, '    SourceTableId : Int64;');
    AppendLine( _1_o_lines, '    SourceFieldId : Int64;');
    AppendLine( _1_o_lines, '    TargetTableId : Int64;');
    AppendLine( _1_o_lines, '    TargetFieldId : Int64;');
    AppendLine( _1_o_lines, '  end;');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  TTableJoinRange = record');
    AppendLine( _1_o_lines, '    SourceTableId : Int64;');
    AppendLine( _1_o_lines, '    LinkIndex     : Int64;');
    AppendLine( _1_o_lines, '    LinkCount     : Int64;');
    AppendLine( _1_o_lines, '  end;');
    AppendLine( _1_o_lines, '');
  End;

Function FieldKindToPascal( Const _1_y_kind: TFieldKind): string;
  Begin
    Case _1_y_kind Of
      fkText: Result := 'fkText';
      fkDate: Result := 'fkDate';
      fkTime: Result := 'fkTime';
      fkInteger: Result := 'fkInteger';
      fkLongint: Result := 'fkLongint';
      fkInt64: Result := 'fkInt64';
      fkReal: Result := 'fkReal';
      fkBlob: Result := 'fkBlob';
      fkBoolean: Result := 'fkBoolean';
      Else Begin
        q4interruptions.assertRaise( False, 'FieldKindToPascal: FieldKind non géré');
        Result := 'fkText'; // uniquement pour satisfaire le compilateur
      End;
    End;
  End;

Procedure GenerateFieldsConst( _1_o_lines: TStrings; Const _2_y_fields: TFieldMetaArray);
  Var
    I: int64;
  Begin
    AppendLine( _1_o_lines, 'const');
    AppendLine( _1_o_lines,
      Format( '  Fields: array[0..%d] of TFieldMeta = (', [High( _2_y_fields)]));
    For I := 0 To High( _2_y_fields) Do Begin
      AppendLine( _1_o_lines, '    (');
      AppendLine( _1_o_lines, Format( '      TableRef   : %d;', [_2_y_fields[I].TableRef]));
      AppendLine( _1_o_lines, Format( '      FieldNo    : %d;', [_2_y_fields[I].FieldNo]));
      AppendLine( _1_o_lines, Format( '      Name       : ''%s'';', [PascalEscape( _2_y_fields[I].Name)]));
      AppendLine( _1_o_lines, Format( '      TypeSQL    : ''%s'';', [PascalEscape( _2_y_fields[I].TypeSQL)]));
      AppendLine( _1_o_lines, Format( '      TypePascal : ''%s'';', [PascalEscape( _2_y_fields[I].TypePascal)]));
      AppendLine( _1_o_lines, Format( '      FieldKind  : %s;', [FieldKindToPascal( _2_y_fields[I].FieldKind)]));
      AppendLine( _1_o_lines, Format( '      Longueur   : %d;', [_2_y_fields[I].Longueur]));
      AppendLine( _1_o_lines, Format( '      Indexed    : %s;', [BoolToPascal( _2_y_fields[I].Indexed)]));
      AppendLine( _1_o_lines, Format( '      UniqueKey  : %s;', [BoolToPascal( _2_y_fields[I].UniqueKey)]));
      AppendLine( _1_o_lines, Format( '      Mandatory  : %s;', [BoolToPascal( _2_y_fields[I].Mandatory)]));
      AppendLine( _1_o_lines, Format( '      InvisibleUI  : %s;', [BoolToPascal( _2_y_fields[I].InvisibleUI)]));
      AppendLine( _1_o_lines, Format( '      EditableUI : %s;', [BoolToPascal( _2_y_fields[I].EditableUI)]));
      AppendLine( _1_o_lines, Format( '      Modifiable : %s;', [BoolToPascal( _2_y_fields[I].Modifiable)]));
      AppendLine( _1_o_lines, Format( '      ChoiceList : ''%s''', [PascalEscape( _2_y_fields[I].ChoiceList)]));
      If ( I < High( _2_y_fields)) Then AppendLine( _1_o_lines, '    ),')
      Else
        AppendLine( _1_o_lines, '    )');
    End;
    AppendLine( _1_o_lines, '  );');
    AppendLine( _1_o_lines, '');
  End;

Procedure GenerateTablesConst( _1_o_lines: TStrings; Const _2_y_tables: TTableMetaArray);
  Var
    i: int64;
  Begin
    AppendLine( _1_o_lines, Format( 'const'#13#10'  Tables: array[0..%d] of TTableMeta = (', [High( _2_y_tables)]));
    For i := 0 To High( _2_y_tables) Do Begin
      AppendLine( _1_o_lines, '    (');
      AppendLine( _1_o_lines, Format( '      SourceTableId : %d;', [_2_y_tables[i].SourceTableId]));
      AppendLine( _1_o_lines, Format( '      Name       : %s;', [QuotedStr( _2_y_tables[i].Name)]));
      AppendLine( _1_o_lines, Format( '      FieldIndex : %d;', [_2_y_tables[i].FieldIndex]));
      AppendLine( _1_o_lines, Format( '      FieldCount : %d;', [_2_y_tables[i].FieldCount]));
      AppendLine( _1_o_lines, Format( '      PrimaryKey : %s;', [QuotedStr( _2_y_tables[i].PrimaryKey)]));
      AppendLine( _1_o_lines, Format( '      Comment    : %s', [QuotedStr( _2_y_tables[i].Comment)]));
      If ( i = High( _2_y_tables)) Then AppendLine( _1_o_lines, '    )')
      Else
        AppendLine( _1_o_lines, '    ),');
    End;
    AppendLine( _1_o_lines, '  );');
    AppendLine( _1_o_lines, '');
  End;

Function PascalTypeToBindingPtrType( Const _1_t_pascalType: string): string;
  Begin
    If ( SameText( _1_t_pascalType, 'String')) Then Result := 'PString'
    Else If ( SameText( _1_t_pascalType, 'Integer')) Then Result := 'PInteger'
    Else If ( SameText( _1_t_pascalType, 'Int64')) Then Result := 'PInt64'
    Else If ( SameText( _1_t_pascalType, 'Double') or SameText( _1_t_pascalType, 'Real')) Then Result := 'PDouble'
    Else If ( SameText( _1_t_pascalType, 'Boolean')) Then Result := 'PBoolean'
    Else
      Result := 'PVariant';
  End;

Function PascalTypeToReadExpr( Const _1_t_pascalType, _2_t_expr: string): string;
  Begin
    If ( SameText( _1_t_pascalType, 'String')) Then Result := Format( 'VarToStr(%s)', [_2_t_expr])
    Else If ( SameText( _1_t_pascalType, 'Integer')) Then Result := Format( 'VarAsType(%s, varInteger)', [_2_t_expr])
    Else If ( SameText( _1_t_pascalType, 'Int64')) Then Result := Format( 'VarAsType(%s, varInt64)', [_2_t_expr])
    Else If ( SameText( _1_t_pascalType, 'Double') or SameText( _1_t_pascalType, 'Real')) Then Result := Format( 'VarAsType(%s, varDouble)', [_2_t_expr])
    Else If ( SameText( _1_t_pascalType, 'Boolean')) Then Result := Format( 'VarAsType(%s, varBoolean)', [_2_t_expr])
    Else
      Result := _2_t_expr;
  End;

Procedure GenerateHeaderProcess( _1_o_lines: TStrings; Const _2_e_tableCount, _3_e_fieldCount, _4_e_linkCount: int64);
  Begin
    AppendLine( _1_o_lines, 'unit ' + AOptions.UnitName + ';');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '{$mode objfpc}{$H+}');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '{');
    AppendLine( _1_o_lines, '  ----------------------------------------------------------------------');
    AppendLine( _1_o_lines, '  AUTO-GENERATED FILE - DO NOT MODIFY MANUALLY');
    AppendLine( _1_o_lines, '  ----------------------------------------------------------------------');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  Source dictionary : ' + ExtractFileName( AOptions.InputCsvFile));
    If ( Trim( AOptions.InputLinksCsvFile) <> '') Then AppendLine( _1_o_lines, '  Source links      : ' + ExtractFileName( AOptions.InputLinksCsvFile));
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  Tables count      : ' + IntToStr( _2_e_tableCount));
    AppendLine( _1_o_lines, '  Fields count      : ' + IntToStr( _3_e_fieldCount));
    AppendLine( _1_o_lines, '  Links count       : ' + IntToStr( _4_e_linkCount));
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  Generated         : ' + MakeTimestamp);
    AppendLine( _1_o_lines, '  Generated by      : ' + AOptions.GeneratorName);
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  This unit contains:');
    AppendLine( _1_o_lines, '  - Process-level record structures for each table');
    AppendLine( _1_o_lines, '  - Runtime contexts used to manipulate current records');
    AppendLine( _1_o_lines, '  - Internal bindings and SQL value arrays used by the q4 process runtime');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  ----------------------------------------------------------------------');
    AppendLine( _1_o_lines, '}');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, 'interface');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, 'uses');
    AppendLine( _1_o_lines, '  SysUtils, Variants, metier_q4DBschemaBase;');
    AppendLine( _1_o_lines, '');
  End;

Function SanitizeIdent( Const _1_t_s: string): string;
  Var
    i: int64;
  Begin
    Result := Trim( _1_t_s);
    If ( Result = '') Then Exit( 'Unnamed');

    For i := 1 To Length( Result) Do If ( not ( Result[i] in ['A'..'Z', 'a'..'z', '0'..'9', '_'])) Then Result[i] := '_';

    If ( ( Result <> '') and ( Result[1] in ['0'..'9'])) Then Result := '_' + Result;
  End;



Procedure Generatemetier_q4DBschemaProcessTypes( _1_o_lines: TStrings; Const _2_y_fields: TFieldMetaArray; Const _3_y_tables: TTableMetaArray);
  Var
    T, I, FirstIdx, LastIdx: int64;
    TableName, FieldName, PascalType: string;
  Begin
    AppendLine( _1_o_lines, 'type');
    AppendLine( _1_o_lines, '  TVariantArray = array of Variant;');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  PString  = ^string;');
    AppendLine( _1_o_lines, '  PInteger = ^Integer;');
    AppendLine( _1_o_lines, '  PInt64   = ^Int64;');
    AppendLine( _1_o_lines, '  PDouble  = ^Double;');
    AppendLine( _1_o_lines, '  PBoolean = ^Boolean;');
    AppendLine( _1_o_lines, '  PVariant = ^Variant;');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  TFieldBinding = record');
    AppendLine( _1_o_lines, '    FieldKind : TFieldKind;');
    AppendLine( _1_o_lines, '    ValuePtr  : Pointer;');
    AppendLine( _1_o_lines, '  end;');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '  TFieldBindingArray = array of TFieldBinding;');
    AppendLine( _1_o_lines, '');

    For T := 0 To High( _3_y_tables) Do Begin
      TableName := SanitizeIdent( _3_y_tables[T].Name);

      AppendLine( _1_o_lines, Format( '  T%sContext = record', [TableName]));
      AppendLine( _1_o_lines, '    _noTable: Int64;');
      AppendLine( _1_o_lines, '    _ReadWrite: Boolean;');
      AppendLine( _1_o_lines, '    _Loaded: Boolean;');
      AppendLine( _1_o_lines, '    _Modified: Boolean;');
      AppendLine( _1_o_lines, '    _RowId: Int64;');
      AppendLine( _1_o_lines, '    _ArraySQL: TVariantArray;');
      AppendLine( _1_o_lines, '    _Bindings: TFieldBindingArray;');

      FirstIdx := _3_y_tables[T].FieldIndex;
      LastIdx := FirstIdx + _3_y_tables[T].FieldCount - 1;
      For I := FirstIdx To LastIdx Do Begin
        FieldName := SanitizeIdent( _2_y_fields[I].Name);
        PascalType := _2_y_fields[I].TypePascal;
        AppendLine( _1_o_lines, Format( '    %s: %s;', [FieldName, PascalType]));
      End;

      AppendLine( _1_o_lines, '  end;');
      AppendLine( _1_o_lines, '');
    End;

    AppendLine( _1_o_lines, '{$REGION threadVar}');
    AppendLine( _1_o_lines, 'threadvar');
    For T := 0 To High( _3_y_tables) Do Begin
      TableName := SanitizeIdent( _3_y_tables[T].Name);
      AppendLine( _1_o_lines, Format( '  %s: T%sContext;', [TableName, TableName]));
    End;
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, '{$ENDREGION threadVar}');
  End;

Procedure Generateq4DBschemaUseRecordsInc( Const _1_y_tables: TTableMetaArray);
  Var
    ALines: TStringList;
    T:      int64;
    _t_fileName: string;
  Begin
    ALines := TStringList.Create;
    Try
      For T := 0 To High( _1_y_tables) Do AppendLine( ALines, Format( 'if InternalTryRecord(%s) then Exit(True);', [SanitizeIdent( _1_y_tables[T].Name)]));

      ALines.LineBreak := LineEnding;

      _t_fileName := AOptions.OutputPasDir + '\' + 'metier_q4DBschemaUse_records.inc';
      ALines.SaveToFile( _t_fileName, TEncoding.UTF8);
    Finally
      ALines.Free;
    End;
  End;

Function TableVarPrefix( Const _1_t_tableName: string): string;
  Begin
    Result := SanitizeIdent( _1_t_tableName);
  End;

Procedure Generatemetier_q4DBschemaProcessBindingsDecl( _1_o_lines: TStrings; Const _2_y_fields: TFieldMetaArray; Const _3_y_tables: TTableMetaArray);
  Var
    T: int64;
    TableName: string;
  Begin
    AppendLine( _1_o_lines, '{$REGION procedure}');
    AppendLine( _1_o_lines, 'procedure ClearArraySQL(var AArraySQL: TVariantArray);');
    AppendLine( _1_o_lines, 'procedure VariablesVersTab(var AArraySQL: TVariantArray; const ABindings: TFieldBindingArray);');
    AppendLine( _1_o_lines, 'procedure TabVersVariables(const AArraySQL: TVariantArray; const ABindings: TFieldBindingArray);');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, 'procedure InitAllContexts;');
    AppendLine( _1_o_lines, 'procedure RebindAllContexts;');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, 'function findTableNumByName(const t_tableName: string): Int64;');
    AppendLine( _1_o_lines, 'function tablePointer(const e_tableNum: Int64): Pointer;');
    AppendLine( _1_o_lines, '');

    For T := 0 To High( _3_y_tables) Do Begin
      TableName := SanitizeIdent( _3_y_tables[T].Name);
      AppendLine( _1_o_lines, Format( 'procedure InitBindings%s(var Ctx: T%sContext);', [TableName, TableName]));
      AppendLine( _1_o_lines, Format( 'procedure Init%sContext(var Ctx: T%sContext);', [TableName, TableName]));
      AppendLine( _1_o_lines, Format( 'procedure Rebind%sContext(var Ctx: T%sContext);', [TableName, TableName]));
    End;
    AppendLine( _1_o_lines, '{$ENDREGION procedure}');
    AppendLine( _1_o_lines, '');
  End;

Procedure Generatemetier_q4DBschemaProcessCoreImpl( _1_o_lines: TStrings);
  Begin
    AppendLine( _1_o_lines, 'implementation');
    AppendLine( _1_o_lines, '');

    AppendLine( _1_o_lines, 'procedure ClearArraySQL(var AArraySQL: TVariantArray);');
    AppendLine( _1_o_lines, 'var');
    AppendLine( _1_o_lines, '  I: Int64;');
    AppendLine( _1_o_lines, 'begin');
    AppendLine( _1_o_lines, '  for I := 0 to High(AArraySQL) do');
    AppendLine( _1_o_lines, '    AArraySQL[I] := Null;');
    AppendLine( _1_o_lines, 'end;');
    AppendLine( _1_o_lines, '');

    AppendLine( _1_o_lines, 'procedure VariablesVersTab(var AArraySQL: TVariantArray; const ABindings: TFieldBindingArray);');
    AppendLine( _1_o_lines, 'var');
    AppendLine( _1_o_lines, '  I: Int64;');
    AppendLine( _1_o_lines, 'begin');
    AppendLine( _1_o_lines, '  for I := 0 to High(ABindings) do');
    AppendLine( _1_o_lines, '    case ABindings[I].FieldKind of');
    AppendLine( _1_o_lines, '      fkText:    AArraySQL[I] := PString(ABindings[I].ValuePtr)^;');
    AppendLine( _1_o_lines, '      fkDate:    AArraySQL[I] := PString(ABindings[I].ValuePtr)^;');
    AppendLine( _1_o_lines, '      fkTime:    AArraySQL[I] := PString(ABindings[I].ValuePtr)^;');
    AppendLine( _1_o_lines, '      fkInteger: AArraySQL[I] := PSmallInt(ABindings[I].ValuePtr)^;');
    AppendLine( _1_o_lines, '      fkLongint: AArraySQL[I] := PLongInt(ABindings[I].ValuePtr)^;');
    AppendLine( _1_o_lines, '      fkInt64:   AArraySQL[I] := PInt64(ABindings[I].ValuePtr)^;');
    AppendLine( _1_o_lines, '      fkReal:    AArraySQL[I] := PDouble(ABindings[I].ValuePtr)^;');
    AppendLine( _1_o_lines, '      fkBlob:    AArraySQL[I] := PVariant(ABindings[I].ValuePtr)^;');
    AppendLine( _1_o_lines, '      fkBoolean: AArraySQL[I] := PBoolean(ABindings[I].ValuePtr)^;');
    AppendLine( _1_o_lines, '    end;');
    AppendLine( _1_o_lines, 'end;');
    AppendLine( _1_o_lines, '');

    AppendLine( _1_o_lines, 'procedure TabVersVariables(const AArraySQL: TVariantArray; const ABindings: TFieldBindingArray);');
    AppendLine( _1_o_lines, 'var');
    AppendLine( _1_o_lines, '  I: Int64;');
    AppendLine( _1_o_lines, 'begin');
    AppendLine( _1_o_lines, '  for I := 0 to High(ABindings) do');
    AppendLine( _1_o_lines, '    case ABindings[I].FieldKind of');
    AppendLine( _1_o_lines, '      fkText:    PString(ABindings[I].ValuePtr)^ := VarToStr(AArraySQL[I]);');
    AppendLine( _1_o_lines, '      fkDate:    PString(ABindings[I].ValuePtr)^ := VarToStr(AArraySQL[I]);');
    AppendLine( _1_o_lines, '      fkTime:    PString(ABindings[I].ValuePtr)^ := VarToStr(AArraySQL[I]);');
    AppendLine( _1_o_lines, '      fkInteger: PSmallInt(ABindings[I].ValuePtr)^ := SmallInt(AArraySQL[I]);');
    AppendLine( _1_o_lines, '      fkLongint: PLongInt(ABindings[I].ValuePtr)^ := LongInt(AArraySQL[I]);');
    AppendLine( _1_o_lines, '      fkInt64:   PInt64(ABindings[I].ValuePtr)^ := StrToInt64Def(VarToStr(AArraySQL[I]), 0);');
    AppendLine( _1_o_lines, '      fkReal:    PDouble(ABindings[I].ValuePtr)^ := Double(AArraySQL[I]);');
    AppendLine( _1_o_lines, '      fkBlob:    PVariant(ABindings[I].ValuePtr)^ := AArraySQL[I];');
    AppendLine( _1_o_lines, '      fkBoolean: PBoolean(ABindings[I].ValuePtr)^ := Boolean(AArraySQL[I]);');
    AppendLine( _1_o_lines, '    end;');
    AppendLine( _1_o_lines, 'end;');
    AppendLine( _1_o_lines, '');
  End;

Procedure Generatemetier_q4DBschemaProcessBindingsImpl( _1_o_lines: TStrings; Const _2_y_fields: TFieldMetaArray; Const _3_y_tables: TTableMetaArray);
  Var
    T, I, FirstIdx, LastIdx, LocalIdx: int64;
    TableName, FieldName: string;
  Begin
    For T := 0 To High( _3_y_tables) Do Begin
      TableName := SanitizeIdent( _3_y_tables[T].Name);
      FirstIdx := _3_y_tables[T].FieldIndex;
      LastIdx := FirstIdx + _3_y_tables[T].FieldCount - 1;

      AppendLine( _1_o_lines, Format( 'procedure InitBindings%s(var Ctx: T%sContext);', [TableName, TableName]));
      AppendLine( _1_o_lines, 'begin');
      AppendLine( _1_o_lines, Format( '  SetLength(Ctx._Bindings, %d);', [_3_y_tables[T].FieldCount]));

      LocalIdx := 0;
      For I := FirstIdx To LastIdx Do Begin
        FieldName := SanitizeIdent( _2_y_fields[I].Name);
        AppendLine( _1_o_lines, Format( '  Ctx._Bindings[%d].FieldKind := %s;', [LocalIdx, FieldKindToPascal( _2_y_fields[I].FieldKind)]));
        AppendLine( _1_o_lines, Format( '  Ctx._Bindings[%d].ValuePtr := @Ctx.%s;', [LocalIdx, FieldName]));
        Inc( LocalIdx);
      End;

      AppendLine( _1_o_lines, 'end;');
      AppendLine( _1_o_lines, '');

      AppendLine( _1_o_lines, Format( 'procedure Init%sContext(var Ctx: T%sContext);', [TableName, TableName]));
      AppendLine( _1_o_lines, 'begin');
      AppendLine( _1_o_lines, Format( '  Ctx._noTable:= %d;', [_3_y_tables[T].SourceTableId]));
      AppendLine( _1_o_lines, '  Ctx._ReadWrite := False;');
      AppendLine( _1_o_lines, '  Ctx._Loaded := False;');
      AppendLine( _1_o_lines, '  Ctx._Modified := False;');
      AppendLine( _1_o_lines, '  Ctx._RowId := -1;');
      AppendLine( _1_o_lines, Format( '  SetLength(Ctx._ArraySQL, %d);', [_3_y_tables[T].FieldCount]));
      AppendLine( _1_o_lines, '  ClearArraySQL(Ctx._ArraySQL);');
      AppendLine( _1_o_lines, Format( '  InitBindings%s(Ctx);', [TableName]));
      AppendLine( _1_o_lines, 'end;');
      AppendLine( _1_o_lines, '');

      AppendLine( _1_o_lines, Format( 'procedure Rebind%sContext(var Ctx: T%sContext);', [TableName, TableName]));
      AppendLine( _1_o_lines, 'begin');
      AppendLine( _1_o_lines, Format( '  InitBindings%s(Ctx);', [TableName]));
      AppendLine( _1_o_lines, 'end;');
      AppendLine( _1_o_lines, '');
    End;

    AppendLine( _1_o_lines, 'procedure InitAllContexts;');
    AppendLine( _1_o_lines, 'begin');
    For T := 0 To High( _3_y_tables) Do Begin
      TableName := SanitizeIdent( _3_y_tables[T].Name);
      AppendLine( _1_o_lines, Format( '  Init%sContext(%s);', [TableName, TableName]));
    End;
    AppendLine( _1_o_lines, 'end;');
    AppendLine( _1_o_lines, '');

    AppendLine( _1_o_lines, 'procedure RebindAllContexts;');
    AppendLine( _1_o_lines, 'begin');
    For T := 0 To High( _3_y_tables) Do Begin
      TableName := SanitizeIdent( _3_y_tables[T].Name);
      AppendLine( _1_o_lines, Format( '  Rebind%sContext(%s);', [TableName, TableName]));
    End;
    AppendLine( _1_o_lines, 'end;');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, 'function findTableNumByName(const t_tableName: string): Int64;');
    AppendLine( _1_o_lines, 'begin');
    AppendLine( _1_o_lines, '  Result := -1;');
    For T := 0 To High( _3_y_tables) Do AppendLine( _1_o_lines, Format( '  if SameText(t_tableName, ''%s'') then Exit(%d);', [_3_y_tables[T].Name, _3_y_tables[T].SourceTableId]));
    AppendLine( _1_o_lines, 'end;');
    AppendLine( _1_o_lines, '');

    AppendLine( _1_o_lines, 'function tablePointer(const e_tableNum: Int64): Pointer;');
    AppendLine( _1_o_lines, 'begin');
    AppendLine( _1_o_lines, '  case e_tableNum of');
    For T := 0 To High( _3_y_tables) Do Begin
      TableName := SanitizeIdent( _3_y_tables[T].Name);
      AppendLine( _1_o_lines, Format( '    %d: Result := @%s;', [_3_y_tables[T].SourceTableId, TableName]));
    End;
    AppendLine( _1_o_lines, '  else');
    AppendLine( _1_o_lines, '    Result := nil;');
    AppendLine( _1_o_lines, '  end;');
    AppendLine( _1_o_lines, 'end;');
    AppendLine( _1_o_lines, '');
  End;


Procedure Generatemetier_q4DBschemaProcess( Const _1_y_fields: TFieldMetaArray; Const _2_y_tables: TTableMetaArray; Const _3_e_linkCount: int64);
  Var
    ALines:    TStringList;
    FieldDefs: TFieldMetaArray;
    TableDefs: TTableMetaArray;
  Begin
    ALines := TStringList.Create;
    AOptions.UnitName := 'metier_q4DBschemaProcess';
    AOptions.OutputPasFile := AOptions.OutputPasDir + '\' + AOptions.UnitName + '.pas';

    Try
      GenerateHeaderProcess( ALines, Length( _2_y_tables), Length( _1_y_fields), _3_e_linkCount);
      //GenerateHeaderProcess(ALines, e_lengthTableDefs, e_lengthFieldDefs);
      Generatemetier_q4DBschemaProcessTypes( ALines, _1_y_fields, _2_y_tables);
      Generatemetier_q4DBschemaProcessBindingsDecl( ALines, _1_y_fields, _2_y_tables);
      Generatemetier_q4DBschemaProcessCoreImpl( ALines);
      Generatemetier_q4DBschemaProcessBindingsImpl( ALines, _1_y_fields, _2_y_tables);
      AppendLine( ALines, 'end.');

      {OutFile :=
      IncludeTrailingPathDelimiter(ExtractFileDir(AOptions.OutputPasFile)) +
      ChangeFileExt(ExtractFileName(AOptions.OutputPasFile), '') +
      'Process.pas';
     }

      //ForceDirectories(ExtractFileDir(OutFile));

      ALines.SaveToFile( AOptions.OutputPasFile, TEncoding.UTF8);
    Finally
      ALines.Free;
    End;
  End;

Procedure GenerateTableIdConsts( _1_o_lines: TStrings; Const _2_y_tables: TTableMetaArray);
  Var
    I: int64;
  Begin
    AppendLine( _1_o_lines, 'const');
    For I := 0 To High( _2_y_tables) Do Begin
      If ( Trim( _2_y_tables[I].Name) = '') Then Continue;

      AppendLine( _1_o_lines, Format( '  %sF = %d;', [SanitizeIdent( _2_y_tables[I].Name), I]));
    End;
    AppendLine( _1_o_lines, '');
  End;


Procedure GenerateLinksConst( _1_o_lines: TStrings; Const _2_y_links: TLinkMetaArray);
  Var
    I: int64;
  Begin
    AppendLine( _1_o_lines, 'const');
    AppendLine( _1_o_lines, Format( '  JoinLinks: array[0..%d] of TJoinLinkMeta = (', [High( _2_y_links)]));
    For I := 0 To High( _2_y_links) Do Begin
      AppendLine( _1_o_lines, '    (');
      AppendLine( _1_o_lines, Format( '      SourceTableId : %d;', [_2_y_links[I].SourceTableId]));
      AppendLine( _1_o_lines, Format( '      SourceFieldId : %d;', [_2_y_links[I].SourceFieldId]));
      AppendLine( _1_o_lines, Format( '      TargetTableId : %d;', [_2_y_links[I].TargetTableId]));
      AppendLine( _1_o_lines, Format( '      TargetFieldId : %d', [_2_y_links[I].TargetFieldId]));
      If ( I = High( _2_y_links)) Then AppendLine( _1_o_lines, '    )')
      Else
        AppendLine( _1_o_lines, '    ),');
    End;
    AppendLine( _1_o_lines, '  );');
    AppendLine( _1_o_lines, '');
  End;

Procedure GenerateLinkRangesConst( _1_o_lines: TStrings; Const _2_y_ranges: TTableLinkRangeArray);
  Var
    I: int64;
  Begin
    AppendLine( _1_o_lines, 'const');
    AppendLine( _1_o_lines, Format( '  TableJoinRanges: array[0..%d] of TTableJoinRange = (', [High( _2_y_ranges)]));
    For I := 0 To High( _2_y_ranges) Do Begin
      AppendLine( _1_o_lines, '    (');
      AppendLine( _1_o_lines, Format( '      SourceTableId : %d;', [_2_y_ranges[I].SourceTableId]));
      AppendLine( _1_o_lines, Format( '      LinkIndex     : %d;', [_2_y_ranges[I].LinkIndex]));
      AppendLine( _1_o_lines, Format( '      LinkCount     : %d', [_2_y_ranges[I].LinkCount]));
      If ( I = High( _2_y_ranges)) Then AppendLine( _1_o_lines, '    )')
      Else
        AppendLine( _1_o_lines, '    ),');
    End;
    AppendLine( _1_o_lines, '  );');
    AppendLine( _1_o_lines, '');
  End;

Procedure GenerateImplementation( _1_o_lines: TStrings);
  Begin
    AppendLine( _1_o_lines, 'implementation');
    AppendLine( _1_o_lines, '');
    AppendLine( _1_o_lines, 'end.');
  End;

Procedure Initmetier_q4DBschemaBaseGenerateOptions;
  Var
    _t_q4infosDir: string;
  Begin
    _t_q4infosDir := GetQ4infosDir;

    AOptions.InputCsvFile := IncludeTrailingPathDelimiter( _t_q4infosDir) + 'structureBD.csv';
    AOptions.InputLinksCsvFile := IncludeTrailingPathDelimiter( _t_q4infosDir) + 'structureLiens.csv';
    AOptions.OutputPasDir := _t_q4infosDir;
    AOptions.GeneratorName := 'q4DBschemaGenerator';
    AOptions.CsvSeparator := ',';

    AOptions.UnitName := 'metier_q4DBschemaBase';
  End;

Procedure Generatemetier_q4DBschemaBase;
  Var
    Rows:      TFieldRowArray;
    Links:     TLinkRowArray;
    FieldDefs: TFieldMetaArray;
    TableDefs: TTableMetaArray;
    LinkDefs:  TLinkMetaArray;
    LinkRanges: TTableLinkRangeArray;
    Lines:     TStringList;
  Begin

    Initmetier_q4DBschemaBaseGenerateOptions;

    Rows := LoadRowsFromCsv( AOptions.InputCsvFile, AOptions.CsvSeparator);
    SortRows( Rows);
    ValidateRows( Rows);
    BuildMetadata( Rows, FieldDefs, TableDefs);

    Links := LoadLinksFromCsv( AOptions.InputLinksCsvFile, AOptions.CsvSeparator);
    SortLinks( Links);
    ValidateLinks( Links, Rows);
    BuildLinkMetadata( Links, LinkDefs, LinkRanges);

    e_lengthTableDefs := Length( TableDefs);
    e_lengthFieldDefs := Length( FieldDefs);
    e_lengthLinkDefs := Length( LinkDefs);

    Lines := TStringList.Create;
    Try
      GenerateHeaderBase( Lines, e_lengthTableDefs, e_lengthFieldDefs, e_lengthLinkDefs);
      GenerateTypes( Lines);
      GenerateTableIdConsts( Lines, TableDefs);
      GenerateFieldsConst( Lines, FieldDefs);
      GenerateTablesConst( Lines, TableDefs);
      GenerateLinksConst( Lines, LinkDefs);
      GenerateLinkRangesConst( Lines, LinkRanges);
      GenerateImplementation( Lines);

      Lines.LineBreak := LineEnding;

      AOptions.OutputPasFile := AOptions.OutputPasDir + '\' + AOptions.UnitName + '.pas';
      Lines.SaveToFile( AOptions.OutputPasFile);

      Generatemetier_q4DBschemaProcess( FieldDefs, TableDefs, Length( LinkDefs));
      Generateq4DBschemaUseRecordsInc( TableDefs);

    Finally
      Lines.Free;
    End;
  End;

Procedure Generatemetier_q4DBschemaBaseDefault;
  Var
    LOptions: Tmetier_q4DBschemaBaseGenerateOptions;
  Begin
    //Initmetier_q4DBschemaBaseGenerateOptions(LOptions);
    //Generatemetier_q4DBschemaBase(LOptions);
    Generatemetier_q4DBschemaBase;
  End;

End.
