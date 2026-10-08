Unit q4DBmanager;

{$mode objfpc}{$H+}

{
q4DBmanager
version du 2026/04/18-17:58

Responsabilités :

- gérer la création ou l'ouverture de la base Sqlite
- conserver le contexte courant indépendant de la base
  (ex. table courante)

Règle d’usage :
- q4process.initProcess doit être appelé au démarrage de l'application avant l'utilisation de q4DBmanager

- si la structureDB.csv a été modifiée ou si il s'agit d'un nouveau projet :
    q4DBschemaGenerator doit être lancée afin de mettre à jour 2 l'unités générés automatiquement :
       metier_q4DBschemaBase : qui contient le dictionnaire des tables et champs
            Indispensable pour q4DBmanager
       metier_q4DBschemaProcess : qui elle sert à l'utilisation des commandes des Api 4d
            N'est pas utilisé par q4DBmanager (sa mise en place est ultérieur (à définir sous peu)
     Et le projet recompilé afin que le code soit mise à jour
}

Interface

Uses
  SysUtils,
  Dialogs,
  DB,
  Classes,
  SQLite3Conn,
  SQLDB,
  metier_q4DBschemaBase;
  //variants;

Type
  TVariantArray = Array Of variant;

Type
  Tq4SQLiteCollationConfig = Record
    Provider: string; // 'icu' | 'internal'
    Locale: string;   // 'fr_FR'
    Name: string;      // collation principale : ex. 'fr_FR'
    SearchName: string; // collation de recherche : ex. 'fr_FR_nodiac'
  End;

Var
  mt_globalDatabaseFileName: string = '';

Threadvar
  InternalConnection:  TSQLite3Connection;
  InternalTransaction: TSQLTransaction;
  mt_CollationConfig:  Tq4SQLiteCollationConfig;

Procedure SetCollationConfig( Const _1_t_provider, _2_t_locale, _3_t_name, _4_t_searchName: string);
Function GetCollationConfig: Tq4SQLiteCollationConfig;

Procedure StoreCollationConfigToSystem;
Function LoadCollationConfigFromSystem: Tq4SQLiteCollationConfig;
Function CollationConfigEquals( Const _1_y_left, _2_y_right: Tq4SQLiteCollationConfig): boolean;

Function CreateDatabase( Const _1_t_fileName: string = ''): boolean;
Function OpenDatabase( Const _1_t_fileName: string = ''): boolean;
Function GetSQLitePragmasReport: string;
Function selectRowToArraySQL( Const _1_t_tableName: string; Const _2_tt_fieldNames: Array Of string; Const _3_e_rowId: int64; Var _4_ty_arraySQL: TVariantArray): boolean;
Procedure CloseDatabase;
Procedure connect( Const _1_t_databaseFile: string);
Procedure disconnect;
Procedure startTransaction;
Procedure commit;
Procedure rollback;
Procedure VacuumDatabase;
Function StatistiquesDatabase: string;
Function BuildIndexName( Const _1_e_tableId: int64; Const _2_te_fieldIds: Array Of integer): string;

Implementation

Uses
  q4selectionTablesCore;

Const
  c_q4SystemKeyCollationProvider = 'q4.sqlite.collation.provider';
  c_q4SystemKeyCollationLocale = 'q4.sqlite.collation.locale';
  c_q4SystemKeyCollationName = 'q4.sqlite.collation.name';
  c_q4SystemKeyCollationSearchName = 'q4.sqlite.collation.search_name';

Function InternalIsConnected: boolean;
  Begin
    Result := Assigned( InternalConnection) and InternalConnection.Connected;
  End;

Function NormalizeSQLDefinition( Const _1_t_sql: string): string;
  Begin
    Result := UpperCase( Trim( _1_t_sql));

    Result := StringReplace( Result, #13, ' ', [rfReplaceAll]);
    Result := StringReplace( Result, #10, ' ', [rfReplaceAll]);
    Result := StringReplace( Result, #9, ' ', [rfReplaceAll]);

    While ( Pos( '  ', Result) > 0) Do Result := StringReplace( Result, '  ', ' ', [rfReplaceAll]);

    Result := StringReplace( Result, ' (', '(', [rfReplaceAll]);
    Result := StringReplace( Result, '( ', '(', [rfReplaceAll]);
    Result := StringReplace( Result, ' )', ')', [rfReplaceAll]);
    Result := StringReplace( Result, ' ,', ',', [rfReplaceAll]);
    Result := StringReplace( Result, ', ', ',', [rfReplaceAll]);
  End;

Procedure SetCollationConfig( Const _1_t_provider, _2_t_locale, _3_t_name, _4_t_searchName: string);
  Begin
    mt_CollationConfig.Provider := Trim( LowerCase( _1_t_provider));
    mt_CollationConfig.Locale := Trim( _2_t_locale);
    mt_CollationConfig.Name := Trim( _3_t_name);
    mt_CollationConfig.SearchName := Trim( _4_t_searchName);

    If ( mt_CollationConfig.Provider = '') Then Raise Exception.Create( 'SetCollationConfig : Provider vide');

    If ( ( mt_CollationConfig.Provider <> 'icu') and ( mt_CollationConfig.Provider <> 'internal')) Then Raise Exception.Create( 'SetCollationConfig : Provider inconnu "' + _1_t_provider + '"');

    If ( mt_CollationConfig.Name = '') Then If ( mt_CollationConfig.Provider = 'icu') Then Begin
        If ( mt_CollationConfig.Locale = '') Then Raise Exception.Create( 'SetCollationConfig : Locale vide pour provider=icu');

        mt_CollationConfig.Name := mt_CollationConfig.Locale;
      End Else
        mt_CollationConfig.Name := 'internal';

    If ( mt_CollationConfig.SearchName = '') Then mt_CollationConfig.SearchName := mt_CollationConfig.Name;

    If ( ( mt_CollationConfig.Provider = 'internal') and ( mt_CollationConfig.Locale = '')) Then mt_CollationConfig.Locale := mt_CollationConfig.Name;
  End;

Function GetCollationConfig: Tq4SQLiteCollationConfig;
  Begin
    Result := mt_CollationConfig;
  End;

Procedure SetSystemValue( Const _1_t_key, _2_t_value: string);
  Var
    Query: TSQLQuery;
  Begin
    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;

      Query.SQL.Text :=
        'INSERT OR REPLACE INTO a0q4_system(key,value) VALUES(:k,:v)';

      Query.ParamByName( 'k').AsString := _1_t_key;
      Query.ParamByName( 'v').AsString := _2_t_value;

      Query.ExecSQL;

    Finally
      Query.Free;
    End;
  End;

Function GetSystemValue( Const _1_t_key: string): string;
  Var
    Query: TSQLQuery;
  Begin
    Result := '';

    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;

      Query.SQL.Text :=
        'SELECT value FROM a0q4_system WHERE key = :k';

      Query.ParamByName( 'k').AsString := _1_t_key;

      Query.Open;

      If ( not Query.EOF) Then Result := Query.FieldByName( 'value').AsString;

    Finally
      Query.Free;
    End;
  End;


Procedure StoreCollationConfigToSystem;
  Var
    _t_config: Tq4SQLiteCollationConfig;
  Begin
    _t_config := GetCollationConfig;

    If ( _t_config.Provider = '') Then Raise Exception.Create( 'StoreCollationConfigToSystem : collation non configurée');

    SetSystemValue( c_q4SystemKeyCollationProvider, _t_config.Provider);
    SetSystemValue( c_q4SystemKeyCollationLocale, _t_config.Locale);
    SetSystemValue( c_q4SystemKeyCollationName, _t_config.Name);
    SetSystemValue( c_q4SystemKeyCollationSearchName, _t_config.SearchName);
  End;

Function LoadCollationConfigFromSystem: Tq4SQLiteCollationConfig;
  Begin
    Result.Provider := Trim( LowerCase( GetSystemValue( c_q4SystemKeyCollationProvider)));
    Result.Locale := Trim( GetSystemValue( c_q4SystemKeyCollationLocale));
    Result.Name := Trim( GetSystemValue( c_q4SystemKeyCollationName));
    Result.SearchName := Trim( GetSystemValue( c_q4SystemKeyCollationSearchName));
    If ( Result.SearchName = '') Then Result.SearchName := Result.Name;

    If ( Result.Provider = '') Then Raise Exception.Create( 'LoadCollationConfigFromSystem : ' + c_q4SystemKeyCollationProvider + ' absent');

    If ( ( Result.Provider <> 'icu') and ( Result.Provider <> 'internal')) Then Raise Exception.Create( 'LoadCollationConfigFromSystem : Provider inconnu "' + Result.Provider + '"');

    If ( Result.Name = '') Then If ( Result.Provider = 'icu') Then Begin
        If ( Result.Locale = '') Then Raise Exception.Create( 'LoadCollationConfigFromSystem : Name et Locale vides pour provider=icu');

        Result.Name := Result.Locale;
      End Else
        Result.Name := 'internal';

    If ( ( Result.Provider = 'internal') and ( Result.Locale = '')) Then Result.Locale := Result.Name;
  End;

Function CollationConfigEquals( Const _1_y_left, _2_y_right: Tq4SQLiteCollationConfig): boolean;
  Begin
    Result :=
      SameText( Trim( _1_y_left.Provider), Trim( _2_y_right.Provider)) and SameText( Trim( _1_y_left.Locale), Trim( _2_y_right.Locale)) and SameText(
      Trim( _1_y_left.Name), Trim( _2_y_right.Name)) and SameText( Trim( _1_y_left.SearchName), Trim( _2_y_right.SearchName));
  End;

Function BuildDeclaredFieldTypeSQL( Const _1_y_field: TFieldMeta): string;
  Var
    _t_config: Tq4SQLiteCollationConfig;
  Begin
    If ( SameText( Trim( _1_y_field.TypeSQL), 'TEXT_ICU')) Then Begin
      _t_config := GetCollationConfig;

      If ( _t_config.Provider = '') Then Raise Exception.Create( 'BuildDeclaredFieldTypeSQL : collation non configurée pour le champ "' + _1_y_field.Name + '"');

      If ( _t_config.Provider = 'icu') Then Begin
        If ( _t_config.Name = '') Then Raise Exception.Create( 'BuildDeclaredFieldTypeSQL : nom de collation vide pour le champ "' + _1_y_field.Name + '"');

        Result := 'TEXT COLLATE ' + _t_config.Name;
        Exit;
      End;

      If ( _t_config.Provider = 'internal') Then Begin
        Result := 'TEXT';
        Exit;
      End;

      Raise Exception.Create( 'BuildDeclaredFieldTypeSQL : provider inconnu "' + _t_config.Provider + '"');
    End;

    If ( SameText( Trim( _1_y_field.TypeSQL), 'TEXT') and ( _1_y_field.FieldKind = fkText) and _1_y_field.Indexed) Then Begin
      Result := 'TEXT COLLATE NOCASE';
      Exit;
    End;

    Result := Trim( _1_y_field.TypeSQL);
  End;

Function GetSQLiteCreateTableSQL( Const _1_t_tableName: string): string;
  Var
    Query: TSQLQuery;
  Begin
    Result := '';

    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;

      Query.SQL.Text :=
        'SELECT sql FROM sqlite_master ' + 'WHERE type=''table'' AND name=:t';

      Query.ParamByName( 't').AsString := _1_t_tableName;
      Query.Open;

      If ( not Query.EOF) Then Result := Query.Fields[0].AsString;

    Finally
      Query.Free;
    End;
  End;

Function GetDefaultSQL( Const _1_t_typeValue: string): string;
  Var
    T: string;
  Begin
    T := UpperCase( _1_t_typeValue);

    If ( Pos( 'INT', T) > 0) Then Exit( '0');

    If ( Pos( 'REAL', T) > 0) Then Exit( '0');

    If ( Pos( 'TEXT', T) > 0) Then Exit( '''''');   // ''

    // BLOB ou autre → pas de DEFAULT
    Result := '';
  End;

Function BuildIndexName( Const _1_e_tableId: int64; Const _2_te_fieldIds: Array Of integer): string;
  Var
    _e_i: int64;
  Begin
    Result := 'idx_t' + IntToStr( _1_e_tableId);

    For _e_i := Low( _2_te_fieldIds) To High( _2_te_fieldIds) Do Result := Result + '_f' + IntToStr( _2_te_fieldIds[_e_i]);
  End;


Procedure ConfigureSQLite( Const _1_t_debutBaseOrLanceBase: string);
  Var
    Query: TSQLQuery;
  Begin
    Query := TSQLQuery.Create( nil);
    Try
      Query.DataBase := InternalConnection;
      Query.Transaction := InternalTransaction;

      { aucune transaction active }
      If ( InternalTransaction.Active) Then InternalTransaction.Commit;

      //Bidouille documentée pour faire croire à TSQL qu'on en transaction
      //et fermer la transaction de sqlite qui lui n'en veut pas pour les pragma
      //https://wiki.freepascal.org/SQLite#Zeos

      Query.SQL.Text := 'End Transaction;';
      Query.ExecSQL;

      //En premier, et uniquement en création de base
      If ( _1_t_debutBaseOrLanceBase = 'DebutBase') Then Begin

        //Cela permet d'appliquer un nouvreau page size
        Query.SQL.Text := 'PRAGMA journal_mode = DELETE;';
        Query.ExecSQL;

        Query.SQL.Text := 'PRAGMA page_size = 8192;'; //8 Kb
        Query.ExecSQL;

      End Else Begin

        Query.SQL.Text := 'PRAGMA journal_mode = WAL;';
        Query.ExecSQL;

        Query.SQL.Text := 'PRAGMA foreign_keys = ON;';
        Query.ExecSQL;

        Query.SQL.Text := 'PRAGMA synchronous = NORMAL;';
        Query.ExecSQL;
      {                 Mode de restauration    Mode WAL
      SUPPLÉMENTAIRE    ACIDE                     ACIDE
      COMPLET          Peut-être pas durable    ACIDE
      NORMALE          Peut-être pas cohérent    Peut-être pas durable
      DÉSACTIVÉ          Incohérent                 Incohérent
      }

        Query.SQL.Text := 'PRAGMA wal_autocheckpoint = 5000;';
        Query.ExecSQL;
      {
      -- WAL checkpoint après 5000 pages.
      -- Avec page_size = 8192 → 5000 × 8 KB ≈ 40 MB de WAL.
      -- Réduit la fréquence des checkpoints (moins d'I/O disque) sur serveur multi-utilisateurs.
      PRAGMA wal_autocheckpoint = 5000;
      }

        //Query.SQL.Text := 'PRAGMA busy_timeout = 5000;'; //5 secondes
        //Query.ExecSQL;
        InternalConnection.ExecuteDirect( 'PRAGMA busy_timeout = 5000;');

        Query.SQL.Text := 'PRAGMA cache_size = -20000;';  //-=KB   20Mb (consommation par process)  memoire caches des fichiers temporaires uniquement
        Query.ExecSQL;

        Query.SQL.Text := 'PRAGMA temp_store = MEMORY;';  // tables temporaires en mémoire vive
        Query.ExecSQL;

        Query.SQL.Text := 'PRAGMA mmap_size = 268435456;';  // 268435456 bytes ≈ 256 MB virtual memory mapping  du systeme d'exploitation
     { a desactiver si :
     NAS
     NFS
     cluster filesystem
     disques USB
     stockage incertain
     }

        Query.ExecSQL;

     { Grosse base avec beaucoup d'utilisateur
      PRAGMA page_size = 8192;
      PRAGMA journal_mode = WAL;
      PRAGMA synchronous = NORMAL;
      PRAGMA busy_timeout = 5000;
      PRAGMA cache_size = -20000;
      PRAGMA mmap_size = 1073741824; // 1073741824 bytes ≈ 1 To virtual memory mapping  du systeme d'exploitation
     }

      End;

      //Voir plus haut : 'End Transaction'
      Query.SQL.Text := 'Begin Transaction;';
      Query.ExecSQL;

    Finally
      Query.Free;
    End;

  End;

Function BuildCreateTableSQL( Const _1_t_tableName: string; Const _2_y_table: TTableMeta): string;
  Var
    i, fld: int64;
    Def:    string;
    _t_declaredType: string;
  Begin
    Result := 'CREATE TABLE ' + _1_t_tableName + ' (';

    For i := 0 To _2_y_table.FieldCount - 1 Do Begin
      fld := _2_y_table.FieldIndex + i;

      _t_declaredType := BuildDeclaredFieldTypeSQL( Fields[fld]);

      Result := Result + Fields[fld].Name + ' ' + _t_declaredType;

      Def := GetDefaultSQL( _t_declaredType);
      If ( Def <> '') Then Result := Result + ' DEFAULT ' + Def;

      If ( SameText( Fields[fld].Name, _2_y_table.PrimaryKey)) Then Result := Result + ' PRIMARY KEY';

      If ( i < _2_y_table.FieldCount - 1) Then Result := Result + ',';
    End;

    //NB 2026-04-20
    //Result := Result + ')';
    Result := Result + ') STRICT';
  End;

Function BuildExpectedCreateTableSQL( Const _1_t_tableName: string; Const _2_y_table: TTableMeta): string;
  Begin
    Result := NormalizeSQLDefinition( BuildCreateTableSQL( _1_t_tableName, _2_y_table));
  End;

Function TableDeclarationChanged( Const _1_t_tableName: string; Const _2_y_table: TTableMeta): boolean;
  Var
    _t_expected: string;
    _t_actual:   string;
  Begin
    _t_expected := BuildExpectedCreateTableSQL( _1_t_tableName, _2_y_table);
    _t_actual := NormalizeSQLDefinition( GetSQLiteCreateTableSQL( _1_t_tableName));

    If ( _t_actual = '') Then Raise Exception.Create( 'TableDeclarationChanged : SQL introuvable pour la table "' + _1_t_tableName + '"');
    //if t_expected <> t_actual then ShowMessage(t_expected + '   ' + t_actual);
    Result := _t_expected <> _t_actual;

    Result := False;
  End;

Function BuildCreateIndexSQL( Const _1_y_table: TTableMeta; Const _2_y_field: TFieldMeta): string;
  Var
    _t_config:    Tq4SQLiteCollationConfig;
    _t_indexName: string;
  Begin
    _t_config := GetCollationConfig;
    _t_indexName := BuildIndexName( _1_y_table.SourceTableId, [_2_y_field.FieldNo]);

    If ( SameText( Trim( _2_y_field.TypeSQL), 'TEXT_ICU') and ( _2_y_field.FieldKind = fkText) and ( _t_config.SearchName <> '') and ( _t_config.Provider <> 'internal')) Then
      Result := 'CREATE INDEX IF NOT EXISTS ' + _t_indexName + ' ON ' + _1_y_table.Name + '(' + _2_y_field.Name + ' COLLATE ' + _t_config.SearchName + ')'

    Else If ( SameText( Trim( _2_y_field.TypeSQL), 'TEXT') and ( _2_y_field.FieldKind = fkText)) Then
      Result := 'CREATE INDEX IF NOT EXISTS ' + _t_indexName + ' ON ' + _1_y_table.Name + '(' + _2_y_field.Name + ')'    //' COLLATE NOCASE)'

    Else
      Result := 'CREATE INDEX IF NOT EXISTS ' + _t_indexName + ' ON ' + _1_y_table.Name + '(' + _2_y_field.Name + ')';
  End;

//function BuildExpectedCreateIndexSQL(const ATable: TTableMeta; const AField: TFieldMeta): string;
//begin
//  Result := NormalizeSQLDefinition(BuildCreateIndexSQL(ATable, AField));
//end;

Function GetSQLiteCreateIndexSQL( Const _1_t_indexName: string): string;
  Var
    Query: TSQLQuery;
  Begin
    Result := '';

    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;
      Query.SQL.Text :=
        'SELECT sql FROM sqlite_master ' + 'WHERE type=''index'' AND UPPER(name)=UPPER(:i)';
      Query.ParamByName( 'i').AsString := _1_t_indexName;
      Query.Open;

      If ( not Query.EOF) Then Result := Query.Fields[0].AsString;
    Finally
      Query.Free;
    End;
  End;

Function ExpectedManagedIndexName( Const _1_y_table: TTableMeta; Const _2_y_field: TFieldMeta): string;
  Begin
    Result := BuildIndexName( _1_y_table.SourceTableId, [_2_y_field.FieldNo]);
  End;

//function ExpectedManagedIndexSQL(const ATable: TTableMeta; const AField: TFieldMeta): string;
//var
//  t_config: Tq4SQLiteCollationConfig;
//  t_indexName: string;
//begin
//  t_config := GetCollationConfig;
//  t_indexName := ExpectedManagedIndexName(ATable, AField);

//  if SameText(Trim(AField.TypeSQL), 'TEXT_ICU')
//     and (t_config.SearchName <> '')
//     and (t_config.Provider <> 'internal') then
//    Result := 'CREATE INDEX IF NOT EXISTS ' + t_indexName +
//      ' ON ' + ATable.Name + '(' + AField.Name + ' COLLATE ' + t_config.SearchName + ')'
//  else
//    Result := 'CREATE INDEX IF NOT EXISTS ' + t_indexName +
//      ' ON ' + ATable.Name + '(' + AField.Name + ')';

//  Result := NormalizeSQLDefinition(Result);
//end;
Function ExpectedManagedIndexSQL( Const _1_y_table: TTableMeta; Const _2_y_field: TFieldMeta): string;
  Begin
    Result := NormalizeSQLDefinition( BuildCreateIndexSQL( _1_y_table, _2_y_field));
  End;

Function ActualManagedIndexSQL( Const _1_y_table: TTableMeta; Const _2_y_field: TFieldMeta): string;
  Begin

    Result := NormalizeSQLDefinition( GetSQLiteCreateIndexSQL( ExpectedManagedIndexName( _1_y_table, _2_y_field)));
  End;

Function ManagedIndexChanged( Const _1_y_table: TTableMeta; Const _2_y_field: TFieldMeta): boolean;
  Var
    _t_expected: string;
    _t_actual:   string;
  Begin
    _t_expected := ExpectedManagedIndexSQL( _1_y_table, _2_y_field);
    _t_expected := StringReplace( _t_expected, 'CREATE INDEX IF NOT EXISTS ', 'CREATE INDEX ', []);
    _t_actual := ActualManagedIndexSQL( _1_y_table, _2_y_field);

    If ( _t_actual = '') Then Exit( True);
    Result := _t_expected <> _t_actual;
  End;

Function ManagedIndexesChanged: boolean;
  Var
    t, f, fld: int64;
    Query:     TSQLQuery;
    Found:     boolean;
  Begin
    Result := False;

    For t := 1 To High( Tables) Do For f := 0 To Tables[t].FieldCount - 1 Do Begin
        fld := Tables[t].FieldIndex + f;

        If ( Fields[fld].Indexed and ManagedIndexChanged( Tables[t], Fields[fld])) Then Exit( True);
      End;

    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;
      Query.SQL.Text :=
        'SELECT name FROM sqlite_master ' + 'WHERE type=''index'' AND name LIKE ''idx_t%'' AND name NOT LIKE ''sqlite_%''';
      Query.Open;

      While ( not Query.EOF) Do Begin
        Found := False;

        For t := 0 To High( Tables) Do Begin
          For f := 0 To Tables[t].FieldCount - 1 Do Begin
            fld := Tables[t].FieldIndex + f;

            If ( Fields[fld].Indexed and SameText( Query.Fields[0].AsString, ExpectedManagedIndexName( Tables[t], Fields[fld]))) Then Begin
              Found := True;
              Break;
            End;
          End;

          If ( Found) Then Break;
        End;

        If ( not Found) Then Exit( True);

        Query.Next;
      End;
    Finally
      Query.Free;
    End;
  End;

Procedure DropAllManagedIndexes;
  Var
    Query: TSQLQuery;
    Names: TStringList;
    i:     int64;
  Begin
    Query := TSQLQuery.Create( nil);
    Names := TStringList.Create;
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;
      Query.SQL.Text :=
        'SELECT name FROM sqlite_master ' + 'WHERE type=''index'' AND name LIKE ''idx_t%'' AND name NOT LIKE ''sqlite_%''';
      Query.Open;

      While ( not Query.EOF) Do Begin
        Names.Add( Query.Fields[0].AsString);
        Query.Next;
      End;
      Query.Close;

      For i := 0 To Names.Count - 1 Do Begin
        Query.SQL.Text := 'DROP INDEX IF EXISTS ' + Names[i];
        Query.ExecSQL;
      End;
    Finally
      Names.Free;
      Query.Free;
    End;
  End;

Procedure CreateTable( Const _1_y_table: TTableMeta);
  Var
    Query: TSQLQuery;
    _t_commandeSQL: string;
  Begin
    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;

      _t_commandeSQL := BuildCreateTableSQL( _1_y_table.Name, _1_y_table);

      Query.SQL.Text := _t_commandeSQL;
      Query.ExecSQL;

    Finally
      Query.Free;
    End;
  End;

Procedure CreateTables;
  Var
    t: int64;
  Begin
    For t := 0 To High( Tables) Do CreateTable( Tables[t]);
  End;

Procedure RebuildTable( Const _1_t_tableName: string; Const _2_y_table: TTableMeta);
  Var
    Query:  TSQLQuery;
    _t_insertSQL: string;
    i, fld: int64;
  Begin
    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;

      { CREATE NEW TABLE }

      Query.SQL.Text := BuildCreateTableSQL( _1_t_tableName + '_new', _2_y_table);
      Query.ExecSQL;

      { COPY DATA }

      _t_insertSQL := 'INSERT INTO ' + _1_t_tableName + '_new SELECT ';

      For i := 0 To _2_y_table.FieldCount - 1 Do Begin
        fld := _2_y_table.FieldIndex + i;

        _t_insertSQL := _t_insertSQL + Fields[fld].Name;

        If ( i < _2_y_table.FieldCount - 1) Then _t_insertSQL := _t_insertSQL + ',';
      End;

      _t_insertSQL := _t_insertSQL + ' FROM ' + _1_t_tableName;

      Query.SQL.Text := _t_insertSQL;
      Query.ExecSQL;

      { REPLACE TABLE }

      Query.SQL.Text := 'DROP TABLE ' + _1_t_tableName;
      Query.ExecSQL;

      Query.SQL.Text :=
        'ALTER TABLE ' + _1_t_tableName + '_new RENAME TO ' + _1_t_tableName;

      Query.ExecSQL;

    Finally
      Query.Free;
    End;
  End;

Procedure CreateIndexes;
  Var
    t, f, fld: int64;
    Query:     TSQLQuery;
  Begin
    Query := TSQLQuery.Create( nil);
    Try
      Query.DataBase := InternalConnection;
      Query.Transaction := InternalTransaction;

      For t := 0 To High( Tables) Do For f := 0 To Tables[t].FieldCount - 1 Do Begin
          fld := Tables[t].FieldIndex + f;

          If ( Fields[fld].Indexed) Then Begin
            Query.SQL.Text := BuildCreateIndexSQL( Tables[t], Fields[fld]);
            Query.ExecSQL;
          End;
        End;
    Finally
      Query.Free;
    End;
  End;

Procedure RecreateManagedIndexes;
  Begin
    DropAllManagedIndexes;
    CreateIndexes;
  End;

Procedure CreateSystemTables;
  Var
    Query: TSQLQuery;
  Begin
    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;

    Finally
      Query.Free;
    End;
  End;

Function TableExists( Const _1_t_tableName: string): boolean;
  Var
    Query: TSQLQuery;
  Begin
    Result := False;

    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;

      Query.SQL.Text :=
        'SELECT name FROM sqlite_master ' + 'WHERE type=''table'' AND name=:t';

      Query.ParamByName( 't').AsString := _1_t_tableName;
      Query.Open;

      Result := not Query.EOF;

    Finally
      Query.Free;
    End;
  End;

Procedure RenameTable( Const _1_t_oldName, _2_t_newName: string);
  Var
    Query: TSQLQuery;
  Begin
    If ( TableExists( _2_t_newName)) Then Raise Exception.Create( 'Impossible de renommer ' + _1_t_oldName + ' → ' + _2_t_newName + ' : la table cible existe déjà');

    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;

      Query.SQL.Text :=
        'ALTER TABLE ' + _1_t_oldName + ' RENAME TO ' + _2_t_newName;

      Query.ExecSQL;

    Finally
      Query.Free;
    End;
  End;


Function GetTablesOrder: TStringArray;
  Var
    _t_ordre: string;
  Begin
    _t_ordre := GetSystemValue( 'ordreTables');

    If ( _t_ordre = '') Then Raise Exception.Create( 'ordreTables absent dans a0q4_system');

    Result := _t_ordre.Split( ';');
  End;

Function BuildTablesOrder: string;
  Var
    t: int64;
  Begin
    Result := '';

    For t := 0 To High( Tables) Do Begin
      If ( Result <> '') Then Result := Result + ';';
      Result := Result + Tables[t].Name;
    End;
  End;

Procedure StoreTablesOrder;
  Begin
    SetSystemValue( 'ordreTables', BuildTablesOrder);
  End;

Function CheckTables( Var _1_b_schemaChanged: boolean): boolean;
  Var
    OldTables: TStringArray;
    t: int64;
  Begin
    Result := False;

    OldTables := GetTablesOrder;

    For t := 0 To High( Tables) Do Begin
      If ( t > High( OldTables)) Then Begin
        CreateTable( Tables[t]);
        _1_b_schemaChanged := True;
        Continue;
      End;

      If ( Tables[t].Name <> OldTables[t]) Then Begin
        RenameTable( OldTables[t], Tables[t].Name);
        _1_b_schemaChanged := True;
      End;
    End;

    If ( Length( OldTables) > Length( Tables)) Then Exit( False);  // table supprimée détectée

    Result := True;
  End;

Function GetSQLiteColumns( Const _1_t_tableName: string): TStringArray;
  Var
    Query: TSQLQuery;
    List:  TStringList;
    i:     int64;
  Begin
    Result := nil;

    Query := TSQLQuery.Create( nil);
    List := TStringList.Create;

    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;

      Query.SQL.Text := 'PRAGMA table_info(' + _1_t_tableName + ')';
      Query.Open;

      While ( not Query.EOF) Do Begin
        List.Add( Query.FieldByName( 'name').AsString);
        Query.Next;
      End;

      SetLength( Result, List.Count);

      For i := 0 To List.Count - 1 Do Result[i] := List[i];

    Finally
      Query.Free;
      List.Free;
    End;
  End;

Function GetSQLiteColumnType( Const _1_t_tableName, _2_t_columnName: string): string;
  Var
    Query: TSQLQuery;
  Begin
    Result := '';

    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;

      Query.SQL.Text := 'PRAGMA table_info(' + _1_t_tableName + ')';
      Query.Open;

      While ( not Query.EOF) Do Begin
        If ( SameText( Query.FieldByName( 'name').AsString, _2_t_columnName)) Then Begin
          Result := Query.FieldByName( 'type').AsString;
          Exit;
        End;

        Query.Next;
      End;

    Finally
      Query.Free;
    End;
  End;

Procedure AddColumn( Const _1_t_tableName: string; Const _2_y_field: TFieldMeta);
  Var
    Query: TSQLQuery;
    SQL:   string;
    Def:   string;
    _t_declaredType: string;
  Begin
    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;

      _t_declaredType := BuildDeclaredFieldTypeSQL( _2_y_field);

      SQL := 'ALTER TABLE ' + _1_t_tableName + ' ADD COLUMN ' + _2_y_field.Name + ' ' + _t_declaredType;

      Def := GetDefaultSQL( _t_declaredType);
      If ( Def <> '') Then SQL := SQL + ' DEFAULT ' + Def;

      Query.SQL.Text := SQL;
      Query.ExecSQL;

    Finally
      Query.Free;
    End;
  End;

Procedure RenameColumn( Const _1_t_tableName, _2_t_oldName, _3_t_newName: string);
  Var
    Query: TSQLQuery;
  Begin
    If ( SameText( _2_t_oldName, _3_t_newName)) Then Exit;

    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;

      Query.SQL.Text :=
        'ALTER TABLE ' + _1_t_tableName + ' RENAME COLUMN ' + _2_t_oldName + ' TO ' + _3_t_newName;

      Query.ExecSQL;

    Finally
      Query.Free;
    End;
  End;

Function CheckColumnsForTable( Const _1_t_tableName: string; _2_e_tableIndex: int64; Var _3_b_schemaChanged: boolean): boolean;
  Var
    SQLiteColumns: TStringArray;
    f, fld: int64;
  Begin
    Result := False;

    SQLiteColumns := GetSQLiteColumns( _1_t_tableName);

    { colonne supprimée interdite }

    If ( Length( SQLiteColumns) > Tables[_2_e_tableIndex].FieldCount) Then Exit( False);

    { 1. Rename }

    For f := 0 To High( SQLiteColumns) Do Begin
      fld := Tables[_2_e_tableIndex].FieldIndex + f;

      If ( not SameText( SQLiteColumns[f], Fields[fld].Name)) Then Begin
        RenameColumn( _1_t_tableName, SQLiteColumns[f], Fields[fld].Name);
        _3_b_schemaChanged := True;
        SQLiteColumns[f] := Fields[fld].Name;
      End;
    End;

    { 2. Add columns }

    For f := Length( SQLiteColumns) To Tables[_2_e_tableIndex].FieldCount - 1 Do Begin
      fld := Tables[_2_e_tableIndex].FieldIndex + f;

      AddColumn( _1_t_tableName, Fields[fld]);
      _3_b_schemaChanged := True;
    End;

    { 3. Check full table declaration }

    If ( TableDeclarationChanged( _1_t_tableName, Tables[_2_e_tableIndex])) Then Begin
      RebuildTable( _1_t_tableName, Tables[_2_e_tableIndex]);
      _3_b_schemaChanged := True;
    End;

    Result := True;
  End;

Function CheckColumns( Var _1_b_schemaChanged: boolean): boolean;
  Var
    t: int64;
  Begin
    Result := False;

    For t := 0 To High( Tables) Do If ( not CheckColumnsForTable( Tables[t].Name, t, _1_b_schemaChanged)) Then Exit;

    Result := True;
  End;

Procedure VacuumDatabase;
  Var
    Query: TSQLQuery;
  Begin
    InternalTransaction.Commit;

    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;

      //Bidouille documentée pour faire croire à TSQL qu'on en transaction
      //et fermer la transaction de sqlite qui lui n'en veut pas pour les pragma
      //https://wiki.freepascal.org/SQLite#Zeos

      ConfigureSQLite( 'DebutBase');

      Query.SQL.Text := 'End Transaction;';
      Query.ExecSQL;

      Query.SQL.Text := 'VACUUM';
      Query.ExecSQL;

      Query.SQL.Text := 'Begin Transaction;';
      Query.ExecSQL;

      ConfigureSQLite( 'LanceBase');

      Query.SQL.Text := 'End Transaction;';
      Query.ExecSQL;

      Query.SQL.Text := 'PRAGMA optimize';
      Query.ExecSQL;

      Query.SQL.Text := 'Begin Transaction;';
      Query.ExecSQL;

    Finally
      Query.Free;
    End;

  End;

Function q4SQLiteHasModule( _1_o_connection: TSQLite3Connection; _2_o_transaction: TSQLTransaction; Const _3_t_module: string): string;
  Var
    Q: TSQLQuery;
  Begin
    Result := '0';

    Q := TSQLQuery.Create( nil);
    Try
      Q.Database := _1_o_connection;
      Q.Transaction := _2_o_transaction;
      Q.SQL.Text := 'PRAGMA module_list;';

      Try
        Q.Open;
        Try
          While ( not Q.EOF) Do Begin
            If ( SameText( Q.Fields[0].AsString, _3_t_module)) Then Begin
              Result := '1';
              Break;
            End;
            Q.Next;
          End;
        Finally
          Q.Close;
        End;
      Except
        on E: Exception Do Result := '<error: ' + E.Message + '>';
      End;
    Finally
      Q.Free;
    End;
  End;

Function StatistiquesDatabase: string;
  Var
    Q:  TSQLQuery;
    SL: TStringList;

  Function ReadScalar( Const _1_t_sql: string): string;
    Begin
      Q.Close;
      Q.SQL.Text := _1_t_sql;
      Try
        Q.Open;
        Try
          If ( ( not Q.EOF) and ( Q.Fields.Count > 0)) Then Result := Q.Fields[0].AsString
          Else
            Result := '';
        Finally
          Q.Close;
        End;
      Except
        on E: Exception Do Result := '<error: ' + E.Message + '>';
      End;
    End;

  Procedure AddDbStatSummary;
    Begin
      Q.Close;
      Q.SQL.Text :=
        'SELECT name, ' + '       count(*)    AS pages, ' + '       sum(pgsize) AS bytes, ' + '       sum(payload) AS payload, ' + '       sum(unused)  AS unused ' +
        'FROM dbstat ' + 'GROUP BY name ' + 'ORDER BY sum(pgsize) DESC, name';

      Try
        Q.Open;
        Try
          If ( Q.EOF) Then SL.Add( 'dbstat = <no rows>')
          Else
            While ( not Q.EOF) Do Begin
              SL.Add(
                'dbstat: name=' + Q.FieldByName( 'name').AsString + ', pages=' + Q.FieldByName( 'pages').AsString + ', bytes=' + Q.FieldByName(
                'bytes').AsString + ', payload=' + Q.FieldByName( 'payload').AsString + ', unused=' + Q.FieldByName( 'unused').AsString
                );
              Q.Next;
            End;
        Finally
          Q.Close;
        End;
      Except
        on E: Exception Do SL.Add( 'dbstat = <error: ' + E.Message + '>');
      End;
    End;

  Begin
    SL := TStringList.Create;
    Q := TSQLQuery.Create( nil);
    Try
      Q.Database := InternalConnection;
      Q.Transaction := InternalTransaction;

      SL.Add( 'ENABLE_DBSTAT_VTAB = ' + ReadScalar( 'SELECT sqlite_compileoption_used(''ENABLE_DBSTAT_VTAB'');'));

      SL.Add( 'module dbstat = ' + q4SQLiteHasModule( InternalConnection, InternalTransaction, 'dbstat'));

      SL.Add( 'dbstat count = ' + ReadScalar( 'SELECT count(*) FROM dbstat;'));

      SL.Add( '');
      AddDbStatSummary;

      Result := SysUtils.TrimRight( SL.Text);
    Finally
      Q.Free;
      SL.Free;
    End;
  End;

Procedure FinalizeMigration;
  Begin
    CreateIndexes;
    StoreCollationConfigToSystem;
    StoreTablesOrder;

    InternalTransaction.Commit;
    VacuumDatabase;
  End;

Procedure ReindexDatabase;
  Var
    Query: TSQLQuery;
  Begin
    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;
      Query.SQL.Text := 'REINDEX';
      Query.ExecSQL;
    Finally
      Query.Free;
    End;
  End;

Function StoredCollationConfigDiffers: boolean;
  Var
    _t_stored:  Tq4SQLiteCollationConfig;
    _t_current: Tq4SQLiteCollationConfig;
  Begin
    _t_current := GetCollationConfig;
    _t_stored := LoadCollationConfigFromSystem;
    Result := not CollationConfigEquals( _t_current, _t_stored);
  End;

Procedure CheckRemovedTables;
  Var
    Query: TSQLQuery;
    TableName: string;
    t:     int64;
    Found: boolean;
  Begin
    Query := TSQLQuery.Create( nil);
    Try
      Query.Database := InternalConnection;
      Query.Transaction := InternalTransaction;

      Query.SQL.Text :=
        'SELECT name FROM sqlite_master ' + 'WHERE type=''table'' ' + 'AND name NOT LIKE ''sqlite_%'' ' + 'AND name <> ''a0q4_system''';

      Query.Open;

      While ( not Query.EOF) Do Begin
        TableName := Query.FieldByName( 'name').AsString;

        Found := False;

        For t := 0 To High( Tables) Do If ( SameText( TableName, Tables[t].Name)) Then Begin
            Found := True;
            Break;
          End;

        If ( not Found) Then Raise Exception.Create( 'Table supprimée détectée : ' + TableName);

        Query.Next;
      End;

    Finally
      Query.Free;
    End;
  End;

Function VerifySchema: boolean;
  Var
    SchemaChanged:  boolean;
    IndexesChanged: boolean;
    ReindexNeeded:  boolean;
  Begin
    Result := False;
    SchemaChanged := False;
    IndexesChanged := False;
    ReindexNeeded := False;

    If ( not CheckTables( SchemaChanged)) Then Exit;
    If ( not CheckColumns( SchemaChanged)) Then Exit;

    CheckRemovedTables;

    If ( not SchemaChanged) Then IndexesChanged := ManagedIndexesChanged;

    If ( ( not SchemaChanged) and ( not IndexesChanged)) Then ReindexNeeded := StoredCollationConfigDiffers;

    If ( SchemaChanged) Then FinalizeMigration
    Else If ( IndexesChanged) Then Begin
      RecreateManagedIndexes;
      StoreCollationConfigToSystem;
      StoreTablesOrder;
      InternalTransaction.Commit;
      InternalTransaction.StartTransaction;
    End Else If ( ReindexNeeded) Then Begin
      ReindexDatabase;
      StoreCollationConfigToSystem;
      InternalTransaction.Commit;
      InternalTransaction.StartTransaction;
    End;

    Result := True;
  End;

Procedure RegisterConfiguredCollations;
  Var
    _t_config: Tq4SQLiteCollationConfig;
    Q: TSQLQuery;

  Procedure LoadOne( Const _1_t_locale, _2_t_name: string);
    Begin
      Q.Close;
      Q.SQL.Text := 'SELECT icu_load_collation(:locale, :name);';
      Q.ParamByName( 'locale').AsString := _1_t_locale;
      Q.ParamByName( 'name').AsString := _2_t_name;
      Q.Open;
      Q.Close;
    End;

  Begin
    _t_config := GetCollationConfig;

    If ( _t_config.Provider = '') Then Raise Exception.Create( 'RegisterConfiguredCollations : collation non configurée');

    If ( _t_config.Provider = 'internal') Then Exit;

    If ( _t_config.Provider <> 'icu') Then Raise Exception.Create( 'RegisterConfiguredCollations : provider inconnu "' + _t_config.Provider + '"');

    If ( _t_config.Locale = '') Then Raise Exception.Create( 'RegisterConfiguredCollations : Locale vide pour provider=icu');

    If ( _t_config.Name = '') Then Raise Exception.Create( 'RegisterConfiguredCollations : Name vide pour provider=icu');

    Q := TSQLQuery.Create( nil);
    Try
      Q.Database := InternalConnection;
      Q.Transaction := InternalTransaction;

      LoadOne( _t_config.Locale, _t_config.Name);

      If ( ( _t_config.SearchName <> '') and ( not SameText( _t_config.SearchName, _t_config.Name))) Then LoadOne( _t_config.Locale, _t_config.SearchName);

    Finally
      Q.Free;
    End;
  End;

Function CreateDatabase( Const _1_t_fileName: string = ''): boolean;
  Var
    _t_fullName: string;
    SaveDlg:     TSaveDialog;
  Begin

    //q4DBmanager.SetCollationConfig('icu', 'fr_FR', 'fr_FR', 'fr_FR_nodiac');
    q4DBmanager.SetCollationConfig( 'icu', 'fr_FR', 'fr_FR', '');

    Result := False;
    _t_fullName := _1_t_fileName;

    If ( _t_fullName = '') Then Begin
      SaveDlg := TSaveDialog.Create( nil);
      Try
        SaveDlg.Filter := 'SQLite database|*.db';
        SaveDlg.DefaultExt := 'db';
        SaveDlg.Options := [ofOverwritePrompt];

        If ( not SaveDlg.Execute) Then Exit;   // utilisateur a annulé

        _t_fullName := SaveDlg.FileName;
      Finally
        SaveDlg.Free;
      End;
    End;

    mt_globalDatabaseFileName := _t_fullName;

    ForceDirectories( ExtractFilePath( _t_fullName));

    InternalConnection := TSQLite3Connection.Create( nil);
    InternalTransaction := TSQLTransaction.Create( nil);

    InternalConnection.DatabaseName := _t_fullName;
    InternalConnection.Transaction := InternalTransaction;

    InternalConnection.Open;

    ConfigureSQLite( 'DebutBase');
    ConfigureSQLite( 'LanceBase');
    RegisterConfiguredCollations;

    //CreateSystemTables;      //La table systeme est desormais dans le schéma
    CreateTables;
    StoreCollationConfigToSystem;
    CreateIndexes;
    StoreTablesOrder;

    InternalTransaction.Commit;

    //q4RecordLocking.initialize(System.Length(Tables));
    //q4record.initialize;

    Result := True;
  End;

Function OpenDatabase( Const _1_t_fileName: string = ''): boolean;
  Var
    _t_fullName: string;
    OpenDlg:     TOpenDialog;
  Begin

    //t_new := q4dateAndTime.addToDate('2024-06-21', 5, 3, 3);
    //Base.LogMemo.Lines.Add('Attendu 2029-09-24, reçu : ' + t_new);

    Result := False;

    _t_fullName := '';

    //if (t_fullName = '') then t_fullName := mt_globalDatabaseFileName;

    //q4DBmanager.SetCollationConfig('icu', 'fr_FR', 'fr_FR', 'fr_FR_nodiac');
    q4DBmanager.SetCollationConfig( 'icu', 'fr_FR', 'fr_FR', '');

    { aucun nom fourni → dialogue }
    If ( _t_fullName = '') Then Begin
      OpenDlg := TOpenDialog.Create( nil);
      Try
        OpenDlg.Filter := 'SQLite database|*.db';

        If ( not OpenDlg.Execute) Then Exit;

        _t_fullName := OpenDlg.FileName;

        //Il n'y a pas de protection sur l'écritures des variables multithreads
        If ( mt_globalDatabaseFileName <> _t_fullName) Then  mt_globalDatabaseFileName := _t_fullName;

      Finally
        OpenDlg.Free;
      End;
    End Else If ( ExtractFilePath( _t_fullName) = '') Then _t_fullName := _t_fullName{ si pas de chemin → rechercher dans Data };

    InternalConnection := TSQLite3Connection.Create( nil);
    InternalTransaction := TSQLTransaction.Create( nil);

    InternalConnection.DatabaseName := _t_fullName;
    InternalConnection.Transaction := InternalTransaction;

    InternalConnection.Open;

    ConfigureSQLite( 'LanceBase');
    RegisterConfiguredCollations;

    //Supprime les tables de selections partagées (au cas ou il en resterait)
    //Devrait on mettre un assert, car si ce n'est pas suite à un plantage, cela pose problème ?
    //Il faudra vérifier qu'il ne reste pas des connexions ouvertes
    q4selectionTablesCore.clearSharedSelectionTablesAtOpen;

    If ( not VerifySchema) Then Begin
      InternalTransaction.Rollback;

      InternalConnection.Close;

      InternalTransaction.Free;
      InternalTransaction := nil;

      InternalConnection.Free;
      InternalConnection := nil;

      Exit( False);
    End;

    InternalTransaction.Commit;

    Result := True;
  End;

//function GetSQLitePragmasReport: string;
//var
//  Q: TSQLQuery;

//  function ReadPragma(const AName: string): string;
//  begin
//    Q.Close;
//    Q.SQL.Text := 'PRAGMA ' + AName + ';';
//    Q.Open;
//    Result := AName + ' = ' + Q.Fields[0].AsString;
//    Q.Close;
//  end;

//begin
//  if (InternalConnection = nil) or (not InternalConnection.Connected) then Exit('Base non ouverte');

//  Q := TSQLQuery.Create(nil);
//  try
//    Q.DataBase := InternalConnection;
//    Q.Transaction := InternalTransaction;

//    Result :=
//      ReadPragma('journal_mode') + LineEnding + ReadPragma('foreign_keys') + LineEnding + ReadPragma('synchronous') +
//      LineEnding + ReadPragma('wal_autocheckpoint') + LineEnding + ReadPragma('busy_timeout') + LineEnding +
//      ReadPragma('cache_size') + LineEnding + ReadPragma('temp_store') + LineEnding + ReadPragma('mmap_size') +
//      LineEnding + ReadPragma('page_size');
//  finally
//    Q.Free;
//  end;
//end;

Function GetSQLitePragmasReport: string;
  Var
    Q:  TSQLQuery;
    SL: TStringList;

  Function ReadScalar( Const _1_t_sql: string): string;
    Begin
      Q.Close;
      Q.SQL.Text := _1_t_sql;
      Try
        Q.Open;
        Try
          If ( ( not Q.EOF) and ( Q.Fields.Count > 0)) Then Result := Q.Fields[0].AsString
          Else
            Result := '';
        Finally
          Q.Close;
        End;
      Except
        on E: Exception Do Result := '<error: ' + E.Message + '>';
      End;
    End;

  Function ReadPragma( Const _1_t_name: string): string;
    Begin
      Result := _1_t_name + ' = ' + ReadScalar( 'PRAGMA ' + _1_t_name + ';');
    End;

  Procedure AddCompileOptions;
    Begin
      Q.Close;
      Q.SQL.Text := 'PRAGMA compile_options;';
      Try
        Q.Open;
        Try
          While ( not Q.EOF) Do Begin
            SL.Add( 'compile_option = ' + Q.Fields[0].AsString);
            Q.Next;
          End;
        Finally
          Q.Close;
        End;
      Except
        on E: Exception Do SL.Add( 'compile_options = <error: ' + E.Message + '>');
      End;
    End;

  Begin
    SL := TStringList.Create;
    Q := TSQLQuery.Create( nil);
    Try
      Q.DataBase := InternalConnection;
      Q.Transaction := InternalTransaction;

      SL.Add( ReadPragma( 'journal_mode'));
      SL.Add( ReadPragma( 'synchronous'));
      SL.Add( ReadPragma( 'foreign_keys'));
      SL.Add( ReadPragma( 'encoding'));

      SL.Add( '');

      { Test direct de la build }
      SL.Add( 'ENABLE_ICU = ' + ReadScalar( 'SELECT sqlite_compileoption_used(''ENABLE_ICU'');'));

      { Test comportemental runtime }
      SL.Add( 'lower(''É'') = ' + ReadScalar( 'SELECT lower(''É'');'));
      SL.Add( 'upper(''é'') = ' + ReadScalar( 'SELECT upper(''é'');'));
      SL.Add( '''æ'' LIKE ''Æ'' = ' + ReadScalar( 'SELECT ''æ'' LIKE ''Æ'';'));

      SL.Add( '');
      AddCompileOptions;

      Result := TrimRight( SL.Text);
    Finally
      Q.Free;
      SL.Free;
    End;
  End;

Procedure CloseDatabase;
  Begin
    {$IFDEF DEBUG}
  if (Assigned(InternalTransaction)) then
    Assert(not InternalTransaction.Active,
      'Transaction active lors de CloseDatabase');
    {$ENDIF}

    If ( Assigned( InternalTransaction)) Then If ( InternalTransaction.Active) Then InternalTransaction.Rollback;

    If ( Assigned( InternalConnection)) Then If ( InternalConnection.Connected) Then InternalConnection.Close;

    FreeAndNil( InternalTransaction);
    FreeAndNil( InternalConnection);
  End;

Function selectRowToArraySQL( Const _1_t_tableName: string; Const _2_tt_fieldNames: Array Of string; Const _3_e_rowId: int64; Var _4_ty_arraySQL: TVariantArray): boolean;
  Var
    Q:      TSQLQuery;
    I:      int64;
    _t_sql: string;
    _t_fields: string;
  Begin
    Result := False;
    _t_fields := '';

    For I := 0 To High( _2_tt_fieldNames) Do Begin
      If ( _t_fields <> '') Then _t_fields := _t_fields + ', ';

      _t_fields := _t_fields + _2_tt_fieldNames[I];
    End;

    _t_sql := 'SELECT ' + _t_fields + ' FROM ' + _1_t_tableName + ' WHERE rowid = :rowid';

    Q := TSQLQuery.Create( nil);
    Try
      Q.DataBase := InternalConnection;
      Q.Transaction := InternalTransaction;
      Q.SQL.Text := _t_sql;
      Q.ParamByName( 'rowid').AsLargeInt := _3_e_rowId;
      Q.Open;

      If ( Q.EOF) Then Exit;

      If ( Length( _4_ty_arraySQL) <> Q.Fields.Count) Then SetLength( _4_ty_arraySQL, Q.Fields.Count);

      For I := 0 To Q.Fields.Count - 1 Do _4_ty_arraySQL[I] := Q.Fields[I].Value;

      Result := True;
    Finally
      Q.Free;
    End;
  End;

Procedure InternalConnect( Const _1_t_databaseFile: string);
  Begin
    If ( InternalIsConnected) Then Exit;

    InternalConnection := TSQLite3Connection.Create( nil);
    InternalTransaction := TSQLTransaction.Create( nil);

    InternalConnection.DatabaseName := _1_t_databaseFile;
    InternalConnection.Transaction := InternalTransaction;

    InternalConnection.Open;
  End;

Procedure InternalDisconnect;
  Begin
    If ( not Assigned( InternalConnection)) Then Exit;

    If ( InternalConnection.Connected) Then InternalConnection.Close;

    FreeAndNil( InternalTransaction);
    FreeAndNil( InternalConnection);
  End;

Procedure InternalStartTransaction;
  Begin
    If ( not InternalIsConnected) Then Raise Exception.Create( 'q4DBmanager: not connected');

    If ( not InternalTransaction.Active) Then InternalTransaction.StartTransaction;
  End;

Procedure InternalCommit;
  Begin
    If ( Assigned( InternalTransaction) and InternalTransaction.Active) Then InternalTransaction.Commit;
  End;

Procedure InternalRollback;
  Begin
    If ( Assigned( InternalTransaction) and InternalTransaction.Active) Then InternalTransaction.Rollback;
  End;

Procedure connect( Const _1_t_databaseFile: string);
  Begin
    InternalConnect( _1_t_databaseFile);
  End;

Procedure disconnect;
  Begin
    InternalDisconnect;
  End;

Procedure startTransaction;
  Begin
    InternalStartTransaction;
  End;

Procedure commit;
  Begin
    InternalCommit;
  End;

Procedure rollback;
  Begin
    InternalRollback;
  End;

End.
