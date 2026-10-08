Unit q4_environnement;

{$mode objfpc}{$H+}

{
q4_environnement
version du 2026/05/08-01

Mapping 4D → q4_environnement -> statut
Command Number 4D,    4D Command,                         q4 API,                            Statut
-----------------------------------------------------------------------------------------------------------
491,                  Application file,                    applicationFile,                   OK spécifique
1599,                 Application info,                    applicationInfo,                   OK spécifique
494,                  Application type,                    applicationType,                   OK spécifique
493,                  Application version,                 applicationVersion,                OK spécifique
871,                  BUILD APPLICATION,                   buildApplication,                  Not supported
937,                  Compact data file,                   compactDataFile,                   Partial
1001,                 COMPONENT LIST,                      componentList,                     OK spécifique
313,                  CREATE DATA FILE,                    createDataFile,                    Partial
490,                  Data file,                           dataFile,                          OK spécifique
1314,                 Database measures,                   databaseMeasures,                  Partial
1633,                 DROP REMOTE USER,                    dropRemoteUser,                    Not supported
1482,                 ds,                                  ds,                                Not supported
1565,                 Export structure file,               exportStructureFile,               Not supported
1418,                 Get 4D file,                         getQ4File,                         OK spécifique
485,                  Get 4D folder,                       getQ4Folder,                       OK spécifique
1009,                 Get database localization,           getDatabaseLocalization,           OK spécifique
643,                  Get database parameter,              getDatabaseParameter,              Partial
1301,                 Last update log path,                lastUpdateLogPath,                 OK spécifique
492,                  Is compiled mode,                    isCompiledMode,                    OK spécifique
716,                  Is data file locked,                 isDataFileLocked,                  OK spécifique
1052,                 NOTIFY RESOURCES FOLDER MODIFICATION,notifyResourcesFolderModification, Not supported
1047,                 OPEN ADMINISTRATION WINDOW,          openAdministrationWindow,          Not supported
312,                  OPEN DATA FILE,                      openDataFile,                      Partial
1321,                 OPEN DATABASE,                       openDatabase,                      Not supported
1452,                 Open datastore,                      openDatastore,                     Not supported
1781,                 OPEN RUNTIME EXPLORER,               openRuntimeExplorer,               Not supported
1018,                 OPEN SECURITY CENTER,                openSecurityCenter,                Not supported
903,                  OPEN SETTINGS WINDOW,                openSettingsWindow,                Not supported
847,                  PLUGIN LIST,                         pluginList,                        OK spécifique
291,                  QUIT 4D,                             quitQ4,                            Partial
1635,                 REJECT NEW REMOTE CONNECTIONS,       rejectNewRemoteConnections,        Partial
1739,                 RELOAD PROJECT,                      reloadProject,                     Not supported
1292,                 RESTART 4D,                          restartQ4,                         Partial
1632,                 SEND MESSAGE TO REMOTE USER,         sendMessageToRemoteUser,           Not supported
1104,                 SET DATABASE LOCALIZATION,           setDatabaseLocalization,           OK spécifique
642,                  SET DATABASE PARAMETER,              setDatabaseParameter,              Partial
1291,                 SET UPDATE FOLDER,                   setUpdateFolder,                   Partial
489,                  Structure file,                      structureFile,                     OK spécifique
1127,                 Table fragmentation,                 tableFragmentation,                Partial
1008,                 VERIFY CURRENT DATA FILE,            verifyCurrentDataFile,             Partial
939,                  VERIFY DATA FILE,                    verifyDataFile,                    Partial
495,                  Version type,                        versionType,                       OK spécifique

Doc: https://developer.4d.com/docs/21/commands/theme/4D-Environment
}

Interface

Uses
  SysUtils,
  Classes,
  q4coreLanguage;

Const
  Q4_LOCAL_MODE = 0;
  Q4_VOLUME_DESKTOP = 1;
  Q4_DESKTOP = 3;
  Q4_REMOTE_MODE = 4;
  Q4_SERVER = 5;
  Q4_TOOL = 6;

  Q4_DEMO_VERSION = 0;
  Q4_64_BIT_VERSION = 1;
  Q4_MERGED_APPLICATION = 2;

  Q4_EXECUTION_MODE_AUTO = 0;
  Q4_EXECUTION_MODE_COMPILED = 1;
  Q4_EXECUTION_MODE_PASCAL_SCRIPT = 2;

  Q4_TABLE_FRAGMENTATION_AUTO = 0;
  Q4_TABLE_FRAGMENTATION_BASIC = 1;
  Q4_TABLE_FRAGMENTATION_DBSTAT = 2;

  Q4_ERROR_NONE = 0;
  Q4_ERROR_UNSUPPORTED = 1;
  Q4_ERROR_SQLITE = 2;
  Q4_ERROR_INVALID_PARAMETER = 3;
  Q4_ERROR_NOT_FOUND = 4;

Threadvar
  e_applicationType: int64;
  e_versionType:     int64;
  e_executionMode:   int64;
  e_tableFragmentationMode: int64;

  t_applicationFilePath:  string;
  t_applicationName:      string;
  t_applicationVersion:   string;
  t_structureFilePath:    string;
  t_databaseLocalization: string;
  t_updateFolderPath:     string;
  t_lastUpdateLogPath:    string;

  b_quitRequested:    boolean;
  e_quitDelaySeconds: int64;

  b_restartRequested:    boolean;
  e_restartDelaySeconds: int64;
  t_restartMessage:      string;

  b_rejectNewRemoteConnections: boolean;

Procedure initializeQ4Environment;
Procedure setQ4ExecutionMode( _1_e_executionMode: int64);

Function applicationFile: string;
Function applicationInfo: string;
Function applicationType: int64;

Function applicationVersion: string; overload;
Function applicationVersion( out _1_e_buildNum: int64): string; overload;
Function applicationVersion( out _1_e_buildNum: int64; Const _2_t_operator: string): string; overload;

Procedure buildApplication; overload;
Procedure buildApplication( Const _1_o_buildAppSettings: string); overload;

Function compactDataFile( Const _1_t_structurePath: string; Const _2_t_dataPath: string): string; overload;
Function compactDataFile( Const _1_t_structurePath: string; Const _2_t_dataPath: string; Const _3_t_archiveFolder: string; _4_e_option: int64; Const _5_t_method: string): string; overload;

Procedure componentList( Var _1_tt_componentsArray: q4coreLanguage.Tq4TextArray);
Procedure createDataFile( Const _1_t_accessPath: string);

Function dataFile: string; overload;
Function dataFile( _1_e_segment: int64): string; overload;

Function databaseMeasures: string; overload;
Function databaseMeasures( Const _1_o_options: string): string; overload;

Procedure dropRemoteUser( Const _1_t_userSession: string);

Function ds: string; overload;
Function ds( Const _1_t_localID: string): string; overload;

Function exportStructureFile( Const _1_t_folderPath: string): string; overload;
Function exportStructureFile( Const _1_t_folderPath: string; Const _2_o_options: string): string; overload;

Function getQ4File( _1_e_file: int64): string; overload;
Function getQ4File( _1_e_file: int64; Const _2_t_operator: string): string; overload;

Function getQ4Folder: string; overload;
Function getQ4Folder( _1_e_folder: int64): string; overload;
Function getQ4Folder( _1_e_folder: int64; Const _2_o_options: string): string; overload;
Function getQ4Folder( _1_e_folder: int64; Const _2_o_options: string; Const _3_t_operator: string): string; overload;

Function getDatabaseLocalization: string; overload;
Function getDatabaseLocalization( _1_e_languageType: int64): string; overload;
Function getDatabaseLocalization( Const _1_t_operator: string): string; overload;
Function getDatabaseLocalization( _1_e_languageType: int64; Const _2_t_operator: string): string; overload;

Function getDatabaseParameter( _1_e_selector: int64): double; overload;
Function getDatabaseParameter( _1_e_selector: int64; out _2_t_stringValue: string): double; overload;
Function getDatabaseParameter( Const _1_t_tableName: string; _2_e_selector: int64): double; overload;
Function getDatabaseParameter( Const _1_t_tableName: string; _2_e_selector: int64; out _3_t_stringValue: string): double; overload;

Function lastUpdateLogPath: string;

Function isCompiledMode: boolean; overload;
Function isCompiledMode( Const _1_t_operator: string): boolean; overload;

Function isDataFileLocked: boolean;

Procedure notifyResourcesFolderModification;
Procedure openAdministrationWindow;
Procedure openDataFile( Const _1_t_accessPath: string);
Procedure openDatabase( Const _1_t_filePath: string);

Function openDatastore( Const _1_o_connectionInfo: string; Const _2_t_localID: string): string;

Procedure openRuntimeExplorer;
Procedure openSecurityCenter;

Procedure openSettingsWindow( Const _1_t_selector: string); overload;
Procedure openSettingsWindow( Const _1_t_selector: string; _2_b_access: boolean); overload;
Procedure openSettingsWindow( Const _1_t_selector: string; _2_b_access: boolean; _3_e_settingsType: int64); overload;

Procedure pluginList( Var _1_te_numbersArray: q4coreLanguage.Tq4Int64Array; Var _2_tt_namesArray: q4coreLanguage.Tq4TextArray);

Procedure quitQ4; overload;
Procedure quitQ4( _1_e_time: int64); overload;

Procedure rejectNewRemoteConnections( _1_b_rejectStatus: boolean);
Procedure reloadProject;

Procedure restartQ4; overload;
Procedure restartQ4( _1_e_time: int64); overload;
Procedure restartQ4( _1_e_time: int64; Const _2_t_message: string); overload;

Procedure sendMessageToRemoteUser( Const _1_t_message: string); overload;
Procedure sendMessageToRemoteUser( Const _1_t_message: string; Const _2_t_userSession: string); overload;

Procedure setDatabaseLocalization( Const _1_t_languageCode: string); overload;
Procedure setDatabaseLocalization( Const _1_t_languageCode: string; Const _2_t_operator: string); overload;

Procedure setDatabaseParameter( _1_e_selector: int64; _2_r_value: double); overload;
Procedure setDatabaseParameter( _1_e_selector: int64; Const _2_t_value: string); overload;
Procedure setDatabaseParameter( Const _1_t_tableName: string; _2_e_selector: int64; _3_r_value: double); overload;
Procedure setDatabaseParameter( Const _1_t_tableName: string; _2_e_selector: int64; Const _3_t_value: string); overload;

Procedure setUpdateFolder( Const _1_t_folderPath: string); overload;
Procedure setUpdateFolder( Const _1_t_folderPath: string; _2_b_silentErrors: boolean); overload;

Function structureFile: string; overload;
Function structureFile( Const _1_t_operator: string): string; overload;

Function tableFragmentation( Const _1_t_tableName: string): double;

Procedure verifyCurrentDataFile; overload;
Procedure verifyCurrentDataFile( _1_e_objects: int64; _2_e_options: int64; Const _3_t_method: string); overload;
Procedure verifyCurrentDataFile( _1_e_objects: int64; _2_e_options: int64; Const _3_t_method: string; Const _4_te_tablesArray: q4coreLanguage.Tq4Int64Array;
  Const _5_te_fieldsArray: q4coreLanguage.Tq4Int64Array); overload;

Procedure verifyDataFile( Const _1_t_structurePath: string; Const _2_t_dataPath: string; _3_e_objects: int64; _4_e_options: int64; Const _5_t_method: string); overload;
Procedure verifyDataFile( Const _1_t_structurePath: string; Const _2_t_dataPath: string; _3_e_objects: int64; _4_e_options: int64; Const _5_t_method: string;
  Const _6_te_tablesArray: q4coreLanguage.Tq4Int64Array; Const _7_te_fieldsArray: q4coreLanguage.Tq4Int64Array); overload;

Function versionType: int64;

Implementation

Uses
  DB,
  SQLDB,
  SQLite3Conn,
  q4DBmanager,
  q4fileAndFolder,
  q4interruptions;

Threadvar
  o_databaseParameterReal: TStringList;
  o_databaseParameterText: TStringList;

Function InternalFormatSettings: TFormatSettings;
  Begin
    Result := SysUtils.DefaultFormatSettings;
    Result.DecimalSeparator := '.';
  End;

Function InternalFloatToText( _1_r_value: double): string;
  Var
    _y_formatSettings: TFormatSettings;
  Begin
    _y_formatSettings := InternalFormatSettings;
    Result := SysUtils.FloatToStr( _1_r_value, _y_formatSettings);
  End;

Function InternalTextToFloat( Const _1_t_value: string): double;
  Var
    _y_formatSettings: TFormatSettings;
  Begin
    _y_formatSettings := InternalFormatSettings;
    Result := SysUtils.StrToFloatDef( _1_t_value, 0, _y_formatSettings);
  End;

Function InternalJSONEscape( Const _1_t_value: string): string;
  Var
    _e_i:    int64;
    _e_code: int64;
    _t_char: string;
  Begin
    Result := '';

    For _e_i := 1 To System.Length( _1_t_value) Do Begin
      _t_char := _1_t_value[_e_i];
      _e_code := Ord( _1_t_value[_e_i]);

      Case _1_t_value[_e_i] Of
        '"': Result := Result + '\"';
        '\': Result := Result + '\\';
        #8: Result := Result + '\b';
        #9: Result := Result + '\t';
        #10: Result := Result + '\n';
        #12: Result := Result + '\f';
        #13: Result := Result + '\r';
        Else If ( _e_code < 32) Then Result := Result + '\u' + SysUtils.IntToHex( _e_code, 4)
          Else
            Result := Result + _t_char;
      End;
    End;
  End;

Function InternalJSONString( Const _1_t_value: string): string;
  Begin
    Result := '"' + InternalJSONEscape( _1_t_value) + '"';
  End;

Function InternalJSONBoolean( _1_b_value: boolean): string;
  Begin
    If ( _1_b_value) Then Result := 'true'
    Else
      Result := 'false';
  End;

Function InternalJSONNumberOrNull( Const _1_t_value: string): string;
  Var
    _e_i:      int64;
    _t_value:  string;
    _b_number: boolean;
  Begin
    _t_value := SysUtils.Trim( _1_t_value);

    If ( _t_value = '') Then Exit( 'null');

    _b_number := True;
    For _e_i := 1 To System.Length( _t_value) Do If ( not ( _t_value[_e_i] in ['0'..'9', '-', '+', '.', 'e', 'E'])) Then Begin
        _b_number := False;
        Break;
      End;

    If ( _b_number) Then Result := _t_value
    Else
      Result := InternalJSONString( _t_value);
  End;

Function InternalDefaultApplicationFilePath: string;
  Begin
    Result := SysUtils.ExpandFileName( System.ParamStr( 0));
  End;

Function InternalDefaultStructureFilePath: string;
  Begin
    If ( t_structureFilePath <> '') Then Exit( t_structureFilePath);

    { q4 note:
    4D Structure file returns the opened 4D structure/project path.
    q4 has no direct 4D structure file; by default we expose the native
    executable path, unless the host runtime explicitly sets t_structureFilePath. }
    Result := InternalDefaultApplicationFilePath;
  End;

Function InternalDefaultApplicationName: string;
  Begin
    If ( t_applicationName <> '') Then Exit( t_applicationName);

    Result := SysUtils.ExtractFileName( InternalDefaultApplicationFilePath);
  End;

Function InternalDefaultApplicationVersion: string;
  Begin
    If ( t_applicationVersion <> '') Then Exit( t_applicationVersion);

    Result := '0.0.0-q4';
  End;

Function InternalCurrentDataFile: string;
  Begin
    If ( q4DBmanager.mt_globalDatabaseFileName <> '') Then Exit( q4DBmanager.mt_globalDatabaseFileName);

    Result := '';
  End;

Function InternalConnectedToSQLite: boolean;
  Begin
    Result := Assigned( q4DBmanager.InternalConnection) and q4DBmanager.InternalConnection.Connected;
  End;

Procedure InternalSetOK;
  Begin
    q4coreLanguage.OK := 1;
    q4coreLanguage.Error := Q4_ERROR_NONE;
  End;

Procedure InternalSetFailure( _1_e_error: int64);
  Begin
    q4coreLanguage.OK := 0;
    q4coreLanguage.Error := _1_e_error;
  End;

Procedure InternalFail( Const _1_t_message: string; _2_e_error: int64);
  Begin
    InternalSetFailure( _2_e_error);
    q4interruptions.assertRaise( _1_t_message, 'q44environnement');
  End;

Procedure InternalUnsupported( Const _1_t_commandName: string; Const _2_t_reason: string = 'no Lazarus/SQLite equivalent');
  Begin
    q4coreLanguage.Document := '';
    InternalSetFailure( Q4_ERROR_UNSUPPORTED);
    q4interruptions.assertRaise( _1_t_commandName + ' is not supported in q4: ' + _2_t_reason, 'q44environnement');
  End;

Function InternalLogsFolder: string;
  Begin
    Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetCurrentDir) + 'Logs' + SysUtils.PathDelim;
    SysUtils.ForceDirectories( Result);
  End;

Function InternalWriteLog( Const _1_t_prefix: string; Const _2_t_content: string): string;
  Var
    _o_list:     TStringList;
    _t_fileName: string;
  Begin
    _t_fileName := _1_t_prefix + '_' + SysUtils.FormatDateTime( 'yyyymmdd_hhnnss_zzz', SysUtils.Now) + '.log';
    Result := InternalLogsFolder + _t_fileName;

    _o_list := TStringList.Create;
    Try
      _o_list.Text := _2_t_content;
      _o_list.SaveToFile( Result);
    Finally
      _o_list.Free;
    End;
  End;

Function InternalFileSize( Const _1_t_filePath: string): int64;
  Var
    _o_stream: TFileStream;
  Begin
    Result := -1;

    If ( not SysUtils.FileExists( _1_t_filePath)) Then Exit;

    _o_stream := TFileStream.Create( _1_t_filePath, fmOpenRead or fmShareDenyNone);
    Try
      Result := _o_stream.Size;
    Finally
      _o_stream.Free;
    End;
  End;

Function InternalSQLiteScalarCurrent( Const _1_t_sql: string): string;
  Var
    _o_query: TSQLQuery;
  Begin
    Result := '';

    If ( not InternalConnectedToSQLite) Then InternalFail( 'SQLite database is not open', Q4_ERROR_SQLITE);

    If ( Assigned( q4DBmanager.InternalTransaction) and ( not q4DBmanager.InternalTransaction.Active)) Then q4DBmanager.InternalTransaction.StartTransaction;

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.Database := q4DBmanager.InternalConnection;
      _o_query.Transaction := q4DBmanager.InternalTransaction;
      _o_query.SQL.Text := _1_t_sql;
      _o_query.Open;

      If ( ( not _o_query.EOF) and ( _o_query.Fields.Count > 0)) Then Result := _o_query.Fields[0].AsString;
    Finally
      _o_query.Free;
    End;
  End;

Function InternalSQLiteScalarFile( Const _1_t_databaseFile: string; Const _2_t_sql: string): string;
  Var
    _o_connection: TSQLite3Connection;
    _o_transaction: TSQLTransaction;
    _o_query: TSQLQuery;
  Begin
    Result := '';

    If ( not SysUtils.FileExists( _1_t_databaseFile)) Then InternalFail( 'SQLite data file not found: ' + _1_t_databaseFile, Q4_ERROR_NOT_FOUND);

    _o_connection := TSQLite3Connection.Create( nil);
    _o_transaction := TSQLTransaction.Create( nil);
    _o_query := TSQLQuery.Create( nil);
    Try
      _o_connection.DatabaseName := _1_t_databaseFile;
      _o_connection.Transaction := _o_transaction;
      _o_connection.Open;

      _o_transaction.StartTransaction;

      _o_query.Database := _o_connection;
      _o_query.Transaction := _o_transaction;
      _o_query.SQL.Text := _2_t_sql;
      _o_query.Open;

      If ( ( not _o_query.EOF) and ( _o_query.Fields.Count > 0)) Then Result := _o_query.Fields[0].AsString;

      _o_query.Close;
      _o_transaction.Commit;
    Finally
      _o_query.Free;
      If ( _o_transaction.Active) Then _o_transaction.Rollback;
      _o_connection.Close;
      _o_transaction.Free;
      _o_connection.Free;
    End;
  End;

Function InternalIntegrityCheckCurrent: string;
  Begin
    Result := InternalSQLiteScalarCurrent( 'PRAGMA integrity_check;');
  End;

Function InternalIntegrityCheckFile( Const _1_t_databaseFile: string): string;
  Begin
    Result := InternalSQLiteScalarFile( _1_t_databaseFile, 'PRAGMA integrity_check;');
  End;

Procedure InternalVacuumCurrent;
  Begin
    If ( not InternalConnectedToSQLite) Then InternalFail( 'SQLite database is not open', Q4_ERROR_SQLITE);

    If ( Assigned( q4DBmanager.InternalTransaction) and q4DBmanager.InternalTransaction.Active) Then q4DBmanager.InternalTransaction.Commit;

    q4DBmanager.InternalConnection.ExecuteDirect( 'VACUUM;');
    q4DBmanager.InternalConnection.ExecuteDirect( 'PRAGMA optimize;');
  End;

Procedure InternalVacuumFile( Const _1_t_databaseFile: string);
  Var
    _o_connection: TSQLite3Connection;
  Begin
    If ( not SysUtils.FileExists( _1_t_databaseFile)) Then InternalFail( 'SQLite data file not found: ' + _1_t_databaseFile, Q4_ERROR_NOT_FOUND);

    _o_connection := TSQLite3Connection.Create( nil);
    Try
      _o_connection.DatabaseName := _1_t_databaseFile;
      _o_connection.Open;
      _o_connection.ExecuteDirect( 'VACUUM;');
      _o_connection.ExecuteDirect( 'PRAGMA optimize;');
    Finally
      _o_connection.Close;
      _o_connection.Free;
    End;
  End;

Function InternalSameFileName( Const _1_t_left: string; Const _2_t_right: string): boolean;
  Begin
    If ( ( _1_t_left = '') or ( _2_t_right = '')) Then Exit( False);

    Result := SysUtils.SameFileName( SysUtils.ExpandFileName( _1_t_left), SysUtils.ExpandFileName( _2_t_right));
  End;

Function InternalDBStatAvailable: boolean;
  Var
    _t_value: string;
  Begin
    Result := False;

    If ( not InternalConnectedToSQLite) Then Exit;

    Try
      _t_value := InternalSQLiteScalarCurrent( 'SELECT sqlite_compileoption_used(''ENABLE_DBSTAT_VTAB'');');
      If ( _t_value = '1') Then Begin
        _t_value := InternalSQLiteScalarCurrent( 'SELECT count(*) FROM dbstat;');
        Result := _t_value <> '';
      End;
    Except
      Result := False;
    End;
  End;

Function InternalTableNameIsSafe( Const _1_t_tableName: string): boolean;
  Var
    _e_i: int64;
  Begin
    Result := False;

    If ( _1_t_tableName = '') Then Exit;

    For _e_i := 1 To System.Length( _1_t_tableName) Do If ( not ( _1_t_tableName[_e_i] in ['A'..'Z', 'a'..'z', '0'..'9', '_'])) Then Exit;

    Result := True;
  End;

Function InternalTableFragmentationDBStat( Const _1_t_tableName: string): double;
  Var
    _o_query:  TSQLQuery;
    _r_bytes:  double;
    _r_unused: double;
  Begin
    Result := 0;

    If ( not InternalConnectedToSQLite) Then InternalFail( 'SQLite database is not open', Q4_ERROR_SQLITE);

    If ( not InternalTableNameIsSafe( _1_t_tableName)) Then InternalFail( 'Invalid SQLite table name: ' + _1_t_tableName, Q4_ERROR_INVALID_PARAMETER);

    If ( Assigned( q4DBmanager.InternalTransaction) and ( not q4DBmanager.InternalTransaction.Active)) Then q4DBmanager.InternalTransaction.StartTransaction;

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.Database := q4DBmanager.InternalConnection;
      _o_query.Transaction := q4DBmanager.InternalTransaction;
      _o_query.SQL.Text := 'SELECT sum(pgsize) AS bytes, sum(unused) AS unused FROM dbstat WHERE name = :name';
      _o_query.ParamByName( 'name').AsString := _1_t_tableName;
      _o_query.Open;

      If ( ( not _o_query.EOF) and ( not _o_query.FieldByName( 'bytes').IsNull)) Then Begin
        _r_bytes := _o_query.FieldByName( 'bytes').AsFloat;
        _r_unused := _o_query.FieldByName( 'unused').AsFloat;
        If ( _r_bytes > 0) Then Result := ( _r_unused / _r_bytes) * 100;
      End;
    Finally
      _o_query.Free;
    End;
  End;

Function InternalTableFragmentationBasic: double;
  Var
    _r_pageCount:     double;
    _r_freeListCount: double;
  Begin
    { q4 note:
    Fallback grossier sans DBSTAT : SQLite ne fournit ici qu'une information
    globale base, pas la fragmentation logique par table de 4D. }
    _r_pageCount := InternalTextToFloat( InternalSQLiteScalarCurrent( 'PRAGMA page_count;'));
    _r_freeListCount := InternalTextToFloat( InternalSQLiteScalarCurrent( 'PRAGMA freelist_count;'));

    If ( _r_pageCount <= 0) Then Exit( 0);

    Result := ( _r_freeListCount / _r_pageCount) * 100;
  End;

Function InternalParameterKey( Const _1_t_tableName: string; _2_e_selector: int64): string;
  Begin
    If ( _1_t_tableName = '') Then Result := 'global:' + SysUtils.IntToStr( _2_e_selector)
    Else
      Result := 'table:' + _1_t_tableName + ':' + SysUtils.IntToStr( _2_e_selector);
  End;

Function InternalRealParameters: TStringList;
  Begin
    If ( o_databaseParameterReal = nil) Then Begin
      o_databaseParameterReal := TStringList.Create;
      o_databaseParameterReal.NameValueSeparator := '=';
    End;

    Result := o_databaseParameterReal;
  End;

Function InternalTextParameters: TStringList;
  Begin
    If ( o_databaseParameterText = nil) Then Begin
      o_databaseParameterText := TStringList.Create;
      o_databaseParameterText.NameValueSeparator := '=';
    End;

    Result := o_databaseParameterText;
  End;

Procedure InternalSetDatabaseParameterReal( Const _1_t_tableName: string; _2_e_selector: int64; _3_r_value: double);
  Var
    _t_key: string;
  Begin
    _t_key := InternalParameterKey( _1_t_tableName, _2_e_selector);
    InternalRealParameters.Values[_t_key] := InternalFloatToText( _3_r_value);
  End;

Procedure InternalSetDatabaseParameterText( Const _1_t_tableName: string; _2_e_selector: int64; Const _3_t_value: string);
  Var
    _t_key: string;
  Begin
    _t_key := InternalParameterKey( _1_t_tableName, _2_e_selector);
    InternalTextParameters.Values[_t_key] := _3_t_value;
  End;

Function InternalTryGetDatabaseParameterReal( Const _1_t_tableName: string; _2_e_selector: int64; out _3_r_value: double): boolean;
  Var
    _t_key:   string;
    _t_value: string;
  Begin
    _t_key := InternalParameterKey( _1_t_tableName, _2_e_selector);
    _t_value := InternalRealParameters.Values[_t_key];
    Result := _t_value <> '';

    If ( Result) Then _3_r_value := InternalTextToFloat( _t_value)
    Else
      _3_r_value := 0;
  End;

Function InternalTryGetDatabaseParameterText( Const _1_t_tableName: string; _2_e_selector: int64; out _3_t_value: string): boolean;
  Var
    _t_key: string;
  Begin
    _t_key := InternalParameterKey( _1_t_tableName, _2_e_selector);
    _3_t_value := InternalTextParameters.Values[_t_key];
    Result := _3_t_value <> '';
  End;

Procedure initializeQ4Environment;
  Begin
    e_applicationType := Q4_LOCAL_MODE;
    e_versionType := Q4_DEMO_VERSION;
    e_executionMode := Q4_EXECUTION_MODE_COMPILED;
    e_tableFragmentationMode := Q4_TABLE_FRAGMENTATION_AUTO;

    t_applicationFilePath := '';
    t_applicationName := '';
    t_applicationVersion := '';
    t_structureFilePath := '';
    t_databaseLocalization := '';
    t_updateFolderPath := '';
    t_lastUpdateLogPath := '';

    b_quitRequested := False;
    e_quitDelaySeconds := 0;

    b_restartRequested := False;
    e_restartDelaySeconds := 0;
    t_restartMessage := '';

    b_rejectNewRemoteConnections := False;
  End;

Procedure setQ4ExecutionMode( _1_e_executionMode: int64);
  Begin
    If ( ( _1_e_executionMode <> Q4_EXECUTION_MODE_COMPILED) and ( _1_e_executionMode <> Q4_EXECUTION_MODE_PASCAL_SCRIPT) and ( _1_e_executionMode <> Q4_EXECUTION_MODE_AUTO)) Then
      InternalFail( 'Invalid q4 execution mode: ' + SysUtils.IntToStr( _1_e_executionMode), Q4_ERROR_INVALID_PARAMETER);

    e_executionMode := _1_e_executionMode;
  End;

Function applicationFile: string;
  Begin
    //https://developer.4d.com/docs/21/commands/application-file
    If ( t_applicationFilePath <> '') Then Result := t_applicationFilePath
    Else
      Result := InternalDefaultApplicationFilePath;
  End;

Function applicationInfo: string;
  Begin
    //https://developer.4d.com/docs/21/commands/application-info
    Result :=
      '{' + '"name":' + InternalJSONString( InternalDefaultApplicationName) + ',' + '"version":' + InternalJSONString( InternalDefaultApplicationVersion) +
      ',' + '"applicationFile":' + InternalJSONString( applicationFile) + ',' + '"structureFile":' + InternalJSONString( InternalDefaultStructureFilePath) +
      ',' + '"dataFile":' + InternalJSONString( InternalCurrentDataFile) + ',' + '"applicationType":' + SysUtils.IntToStr( applicationType) + ',' +
      '"versionType":' + SysUtils.IntToStr( versionType) + ',' + '"compiledMode":' + InternalJSONBoolean( isCompiledMode) + '}';
  End;

Function applicationType: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/application-type
    Result := e_applicationType;
  End;

Function applicationVersion: string;
  Var
    _e_buildNum: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/application-version
    Result := applicationVersion( _e_buildNum);
  End;

Function applicationVersion( out _1_e_buildNum: int64): string;
  Begin
    //https://developer.4d.com/docs/21/commands/application-version
    _1_e_buildNum := 0;
    Result := InternalDefaultApplicationVersion;
  End;

Function applicationVersion( out _1_e_buildNum: int64; Const _2_t_operator: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/application-version
    { q4 note:
    Le paramètre spécial 4D * est accepté pour compatibilité de signature.
    Il ne change pas le résultat dans q4 v1.x. }
    Result := applicationVersion( _1_e_buildNum);
  End;

Procedure buildApplication;
  Begin
    //https://developer.4d.com/docs/21/commands/build-application
    InternalUnsupported( 'BUILD APPLICATION', 'building a 4D application has no q4/FPC equivalent');
  End;

Procedure buildApplication( Const _1_o_buildAppSettings: string);
  Begin
    //https://developer.4d.com/docs/21/commands/build-application
    InternalUnsupported( 'BUILD APPLICATION', 'building a 4D application has no q4/FPC equivalent');
  End;

Function compactDataFile( Const _1_t_structurePath: string; Const _2_t_dataPath: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/compact-data-file
    Result := compactDataFile( _1_t_structurePath, _2_t_dataPath, '', 0, '');
  End;

Function compactDataFile( Const _1_t_structurePath: string; Const _2_t_dataPath: string; Const _3_t_archiveFolder: string; _4_e_option: int64; Const _5_t_method: string): string;
  Var
    _t_dataPath: string;
    _t_report:   string;
  Begin
    //https://developer.4d.com/docs/21/commands/compact-data-file
    { q4 note:
    4D compacts a 4D data file and may produce an archive/log.
    q4 maps this to SQLite VACUUM. The archiveFolder, option and method
    parameters are accepted for API compatibility but not reproduced. }
    _t_dataPath := _2_t_dataPath;
    If ( _t_dataPath = '') Then _t_dataPath := InternalCurrentDataFile;

    Try
      If ( _t_dataPath = '') Then InternalFail( 'Compact data file: no SQLite data file path', Q4_ERROR_INVALID_PARAMETER);

      If ( InternalSameFileName( _t_dataPath, InternalCurrentDataFile) and InternalConnectedToSQLite) Then InternalVacuumCurrent
      Else
        InternalVacuumFile( _t_dataPath);

      _t_report := 'q4 compactDataFile' + System.LineEnding + 'SQLite VACUUM completed for: ' + _t_dataPath;
      Result := InternalWriteLog( 'q4_compact_data_file', _t_report);
      q4coreLanguage.Document := Result;
      InternalSetOK;
    Except
      on o_exception: Exception Do Begin
        q4coreLanguage.Document := '';
        InternalSetFailure( Q4_ERROR_SQLITE);
        q4interruptions.assertRaise( 'Compact data file failed: ' + o_exception.Message, 'q44environnement.compactDataFile');
        Result := '';
      End;
    End;
  End;

Procedure componentList( Var _1_tt_componentsArray: q4coreLanguage.Tq4TextArray);
  Begin
    //https://developer.4d.com/docs/21/commands/component-list
    System.SetLength( _1_tt_componentsArray, 0);
  End;

Procedure createDataFile( Const _1_t_accessPath: string);
  Begin
    //https://developer.4d.com/docs/21/commands/create-data-file
    { q4 note:
    4D creates and opens a 4D data file. q4 maps this to SQLite database
    creation through q4DBmanager. }
    Try
      If ( _1_t_accessPath = '') Then InternalFail( 'CREATE DATA FILE requires an explicit SQLite file path in q4', Q4_ERROR_INVALID_PARAMETER);

      If ( q4DBmanager.CreateDatabase( _1_t_accessPath)) Then InternalSetOK
      Else
        InternalSetFailure( Q4_ERROR_SQLITE);
    Except
      on o_exception: Exception Do Begin
        InternalSetFailure( Q4_ERROR_SQLITE);
        q4interruptions.assertRaise( 'CREATE DATA FILE failed: ' + o_exception.Message, 'q44environnement.createDataFile');
      End;
    End;
  End;

Function dataFile: string;
  Begin
    //https://developer.4d.com/docs/21/commands/data-file
    Result := InternalCurrentDataFile;
  End;

Function dataFile( _1_e_segment: int64): string;
  Begin
    //https://developer.4d.com/docs/21/commands/data-file
    { q4 note:
    Le paramètre segment est conservé pour compatibilité mais 4D le considère
    déjà obsolète. q4 l'ignore et retourne le fichier SQLite courant. }
    Result := dataFile;
  End;

Function databaseMeasures: string;
  Begin
    //https://developer.4d.com/docs/21/commands/database-measures
    Result := databaseMeasures( '');
  End;

Function databaseMeasures( Const _1_o_options: string): string;
  Var
    _t_pageCount:     string;
    _t_pageSize:      string;
    _t_freeListCount: string;
    _t_journalMode:   string;
    _t_encoding:      string;
    _t_dataFile:      string;
    _e_fileBytes:     int64;
    _b_dbstatAvailable: boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/database-measures
    { q4 note:
    4D retourne un objet de mesures propre au moteur 4D. q4 retourne un JSON
    basé sur les métriques SQLite disponibles. Le paramètre options JSON est
    accepté mais non interprété en v1.x. }
    If ( not InternalConnectedToSQLite) Then Begin
      Result := '{"connected":false,"dataFile":' + InternalJSONString( InternalCurrentDataFile) + '}';
      Exit;
    End;

    _t_dataFile := InternalCurrentDataFile;
    _e_fileBytes := InternalFileSize( _t_dataFile);
    _t_pageCount := InternalSQLiteScalarCurrent( 'PRAGMA page_count;');
    _t_pageSize := InternalSQLiteScalarCurrent( 'PRAGMA page_size;');
    _t_freeListCount := InternalSQLiteScalarCurrent( 'PRAGMA freelist_count;');
    _t_journalMode := InternalSQLiteScalarCurrent( 'PRAGMA journal_mode;');
    _t_encoding := InternalSQLiteScalarCurrent( 'PRAGMA encoding;');
    _b_dbstatAvailable := InternalDBStatAvailable;

    Result :=
      '{' + '"connected":true,' + '"dataFile":' + InternalJSONString( _t_dataFile) + ',' + '"fileBytes":' + SysUtils.IntToStr( _e_fileBytes) + ',' +
      '"pageCount":' + InternalJSONNumberOrNull( _t_pageCount) + ',' + '"pageSize":' + InternalJSONNumberOrNull( _t_pageSize) + ',' + '"freeListCount":' +
      InternalJSONNumberOrNull( _t_freeListCount) + ',' + '"journalMode":' + InternalJSONString( _t_journalMode) + ',' + '"encoding":' + InternalJSONString( _t_encoding) +
      ',' + '"dbstatAvailable":' + InternalJSONBoolean( _b_dbstatAvailable) + '}';
  End;

Procedure dropRemoteUser( Const _1_t_userSession: string);
  Begin
    //https://developer.4d.com/docs/21/commands/drop-remote-user
    InternalUnsupported( 'DROP REMOTE USER', '4D client/server sessions are not implemented in q4');
  End;

Function ds: string;
  Begin
    //https://developer.4d.com/docs/21/commands/ds
    Result := ds( '');
  End;

Function ds( Const _1_t_localID: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/ds
    InternalUnsupported( 'ds', 'ORDA datastore runtime is not implemented in q4');
    Result := '';
  End;

Function exportStructureFile( Const _1_t_folderPath: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/export-structure-file
    Result := exportStructureFile( _1_t_folderPath, '');
  End;

Function exportStructureFile( Const _1_t_folderPath: string; Const _2_o_options: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/export-structure-file
    InternalUnsupported( 'Export structure file', '4D structure export has no q4 project model yet');
    Result := '';
  End;

Function getQ4File( _1_e_file: int64): string;
  Begin
    //https://developer.4d.com/docs/21/commands/get-4d-file
    Result := getQ4File( _1_e_file, '');
  End;

Function getQ4File( _1_e_file: int64; Const _2_t_operator: string): string;
  Var
    _y_file: q4fileAndFolder.Tq4File;
  Begin
    //https://developer.4d.com/docs/21/commands/get-4d-file
    { q4 note:
    Le paramètre spécial 4D * est accepté mais non différencié en q4 v1.x. }
    _y_file := q4fileAndFolder.fileFromConstant( _1_e_file);
    Result := _y_file.t_path;

    If ( Result = '') Then q4coreLanguage.OK := 0
    Else
      q4coreLanguage.OK := 1;
  End;

Function getQ4Folder: string;
  Begin
    //https://developer.4d.com/docs/21/commands/get-4d-folder
    Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetCurrentDir);
    q4coreLanguage.OK := 1;
  End;

Function getQ4Folder( _1_e_folder: int64): string;
  Begin
    //https://developer.4d.com/docs/21/commands/get-4d-folder
    Result := getQ4Folder( _1_e_folder, '', '');
  End;

Function getQ4Folder( _1_e_folder: int64; Const _2_o_options: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/get-4d-folder
    Result := getQ4Folder( _1_e_folder, _2_o_options, '');
  End;

Function getQ4Folder( _1_e_folder: int64; Const _2_o_options: string; Const _3_t_operator: string): string;
  Var
    _y_folder: q4fileAndFolder.Tq4Folder;
  Begin
    //https://developer.4d.com/docs/21/commands/get-4d-folder
    { q4 note:
    options est un objet 4D. En q4 v1.x, Object est porté en JSON texte.
    Le JSON options et le paramètre * sont acceptés mais non interprétés. }
    _y_folder := q4fileAndFolder.folderFromConstant( _1_e_folder);
    Result := _y_folder.t_path;

    If ( Result = '') Then q4coreLanguage.OK := 0
    Else
      q4coreLanguage.OK := 1;
  End;

Function getDatabaseLocalization: string;
  Begin
    //https://developer.4d.com/docs/21/commands/get-database-localization
    If ( t_databaseLocalization <> '') Then Result := t_databaseLocalization
    Else
      Result := 'en';
  End;

Function getDatabaseLocalization( _1_e_languageType: int64): string;
  Begin
    //https://developer.4d.com/docs/21/commands/get-database-localization
    Result := getDatabaseLocalization;
  End;

Function getDatabaseLocalization( Const _1_t_operator: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/get-database-localization
    Result := getDatabaseLocalization;
  End;

Function getDatabaseLocalization( _1_e_languageType: int64; Const _2_t_operator: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/get-database-localization
    Result := getDatabaseLocalization;
  End;

Function getDatabaseParameter( _1_e_selector: int64): double;
  Var
    _t_stringValue: string;
  Begin
    //https://developer.4d.com/docs/21/commands/get-database-parameter
    Result := getDatabaseParameter( '', _1_e_selector, _t_stringValue);
  End;

Function getDatabaseParameter( _1_e_selector: int64; out _2_t_stringValue: string): double;
  Begin
    //https://developer.4d.com/docs/21/commands/get-database-parameter
    Result := getDatabaseParameter( '', _1_e_selector, _2_t_stringValue);
  End;

Function getDatabaseParameter( Const _1_t_tableName: string; _2_e_selector: int64): double;
  Var
    _t_stringValue: string;
  Begin
    //https://developer.4d.com/docs/21/commands/get-database-parameter
    Result := getDatabaseParameter( _1_t_tableName, _2_e_selector, _t_stringValue);
  End;

Function getDatabaseParameter( Const _1_t_tableName: string; _2_e_selector: int64; out _3_t_stringValue: string): double;
  Var
    _r_value:   double;
    _b_hasReal: boolean;
    _b_hasText: boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/get-database-parameter
    { q4 note:
    4D possède un grand ensemble de sélecteurs internes. q4 v1.x implémente
    un stockage runtime minimal des sélecteurs explicitement positionnés par
    setDatabaseParameter. Un sélecteur non connu échoue explicitement. }
    _b_hasReal := InternalTryGetDatabaseParameterReal( _1_t_tableName, _2_e_selector, _r_value);
    _b_hasText := InternalTryGetDatabaseParameterText( _1_t_tableName, _2_e_selector, _3_t_stringValue);

    If ( not _b_hasText) Then _3_t_stringValue := '';

    If ( _b_hasReal) Then Result := _r_value
    Else If ( _b_hasText) Then Result := 0
    Else Begin
      InternalFail( 'Unsupported or unset database parameter selector in q4: ' + SysUtils.IntToStr( _2_e_selector),
        Q4_ERROR_UNSUPPORTED);
      Result := 0;
    End;
  End;

Function lastUpdateLogPath: string;
  Begin
    //https://developer.4d.com/docs/21/commands/last-update-log-path
    Result := t_lastUpdateLogPath;
  End;

Function isCompiledMode: boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/is-compiled-mode
    { q4 note:
    4D distingue le mode interprété du mode compilé. q4 transpose cette notion
    au runtime : FPC natif compilé versus Pascal Script. Par défaut, q4 est
    considéré compilé sauf si le runtime positionne explicitement Pascal Script. }
    Result := e_executionMode <> Q4_EXECUTION_MODE_PASCAL_SCRIPT;
  End;

Function isCompiledMode( Const _1_t_operator: string): boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/is-compiled-mode
    Result := isCompiledMode;
  End;

Function isDataFileLocked: boolean;
  Var
    _t_dataFile:   string;
    _e_attributes: longint;
  Begin
    //https://developer.4d.com/docs/21/commands/is-data-file-locked
    _t_dataFile := InternalCurrentDataFile;
    If ( _t_dataFile = '') Then Exit( False);

    _e_attributes := SysUtils.FileGetAttr( _t_dataFile);
    If ( _e_attributes < 0) Then Exit( False);

    Result := ( _e_attributes and SysUtils.faReadOnly) <> 0;
  End;

Procedure notifyResourcesFolderModification;
  Begin
    //https://developer.4d.com/docs/21/commands/notify-resources-folder-modification
    InternalUnsupported( 'NOTIFY RESOURCES FOLDER MODIFICATION', '4D resources hot-reload is not implemented in q4');
  End;

Procedure openAdministrationWindow;
  Begin
    //https://developer.4d.com/docs/21/commands/open-administration-window
    InternalUnsupported( 'OPEN ADMINISTRATION WINDOW', '4D Server administration UI is not implemented in q4');
  End;

Procedure openDataFile( Const _1_t_accessPath: string);
  Begin
    //https://developer.4d.com/docs/21/commands/open-data-file
    { q4 note:
    4D reopens the application with another data file. q4 maps this partially
    to closing the current q4DBmanager connection and connecting to another
    SQLite file. Full 4D restart semantics are not reproduced. }
    Try
      If ( _1_t_accessPath = '') Then InternalFail( 'OPEN DATA FILE requires an explicit SQLite file path in q4', Q4_ERROR_INVALID_PARAMETER);

      If ( not SysUtils.FileExists( _1_t_accessPath)) Then InternalFail( 'OPEN DATA FILE: SQLite file not found: ' + _1_t_accessPath, Q4_ERROR_NOT_FOUND);

      q4DBmanager.disconnect;
      q4DBmanager.mt_globalDatabaseFileName := _1_t_accessPath;
      q4DBmanager.connect( _1_t_accessPath);
      InternalSetOK;
    Except
      on o_exception: Exception Do Begin
        InternalSetFailure( Q4_ERROR_SQLITE);
        q4interruptions.assertRaise( 'OPEN DATA FILE failed: ' + o_exception.Message, 'q44environnement.openDataFile');
      End;
    End;
  End;

Procedure openDatabase( Const _1_t_filePath: string);
  Begin
    //https://developer.4d.com/docs/21/commands/open-database
    InternalUnsupported( 'OPEN DATABASE', 'opening a 4D structure/database is not implemented in q4');
  End;

Function openDatastore( Const _1_o_connectionInfo: string; Const _2_t_localID: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/open-datastore
    InternalUnsupported( 'Open datastore', 'remote ORDA datastore is not implemented in q4');
    Result := '';
  End;

Procedure openRuntimeExplorer;
  Begin
    //https://developer.4d.com/docs/21/commands/open-runtime-explorer
    InternalUnsupported( 'OPEN RUNTIME EXPLORER', '4D runtime explorer UI is not implemented in q4');
  End;

Procedure openSecurityCenter;
  Begin
    //https://developer.4d.com/docs/21/commands/open-security-center
    InternalUnsupported( 'OPEN SECURITY CENTER', '4D maintenance and security center UI is not implemented in q4');
  End;

Procedure openSettingsWindow( Const _1_t_selector: string);
  Begin
    //https://developer.4d.com/docs/21/commands/open-settings-window
    openSettingsWindow( _1_t_selector, True, 0);
  End;

Procedure openSettingsWindow( Const _1_t_selector: string; _2_b_access: boolean);
  Begin
    //https://developer.4d.com/docs/21/commands/open-settings-window
    openSettingsWindow( _1_t_selector, _2_b_access, 0);
  End;

Procedure openSettingsWindow( Const _1_t_selector: string; _2_b_access: boolean; _3_e_settingsType: int64);
  Begin
    //https://developer.4d.com/docs/21/commands/open-settings-window
    InternalUnsupported( 'OPEN SETTINGS WINDOW', '4D settings UI is not implemented in q4');
  End;

Procedure pluginList( Var _1_te_numbersArray: q4coreLanguage.Tq4Int64Array; Var _2_tt_namesArray: q4coreLanguage.Tq4TextArray);
  Begin
    //https://developer.4d.com/docs/21/commands/plugin-list
    System.SetLength( _1_te_numbersArray, 0);
    System.SetLength( _2_tt_namesArray, 0);
  End;

Procedure quitQ4;
  Begin
    //https://developer.4d.com/docs/21/commands/quit-4d
    quitQ4( 0);
  End;

Procedure quitQ4( _1_e_time: int64);
  Begin
    //https://developer.4d.com/docs/21/commands/quit-4d
    { q4 note:
    q4 ne fait pas System.Halt ici. La commande positionne une demande de
    sortie que le lanceur q4/FPC ou Pascal Script peut traiter proprement. }
    b_quitRequested := True;
    e_quitDelaySeconds := _1_e_time;
    InternalSetOK;
  End;

Procedure rejectNewRemoteConnections( _1_b_rejectStatus: boolean);
  Begin
    //https://developer.4d.com/docs/21/commands/reject-new-remote-connections
    { q4 note:
    q4 n'a pas encore de serveur remote 4D. On conserve l'état demandé pour
    le futur runtime serveur q4, sans effet réseau réel en v1.x. }
    b_rejectNewRemoteConnections := _1_b_rejectStatus;
  End;

Procedure reloadProject;
  Begin
    //https://developer.4d.com/docs/21/commands/reload-project
    InternalUnsupported( 'RELOAD PROJECT', '4D project source reload is not implemented in q4');
  End;

Procedure restartQ4;
  Begin
    //https://developer.4d.com/docs/21/commands/restart-4d
    restartQ4( 0, '');
  End;

Procedure restartQ4( _1_e_time: int64);
  Begin
    //https://developer.4d.com/docs/21/commands/restart-4d
    restartQ4( _1_e_time, '');
  End;

Procedure restartQ4( _1_e_time: int64; Const _2_t_message: string);
  Begin
    //https://developer.4d.com/docs/21/commands/restart-4d
    { q4 note:
    Comme quitQ4, q4 ne relance pas directement l'exécutable. La commande
    positionne une demande de redémarrage que l'hôte peut gérer. }
    b_restartRequested := True;
    e_restartDelaySeconds := _1_e_time;
    t_restartMessage := _2_t_message;
    InternalSetOK;
  End;

Procedure sendMessageToRemoteUser( Const _1_t_message: string);
  Begin
    //https://developer.4d.com/docs/21/commands/send-message-to-remote-user
    sendMessageToRemoteUser( _1_t_message, '');
  End;

Procedure sendMessageToRemoteUser( Const _1_t_message: string; Const _2_t_userSession: string);
  Begin
    //https://developer.4d.com/docs/21/commands/send-message-to-remote-user
    InternalUnsupported( 'SEND MESSAGE TO REMOTE USER', '4D remote user messaging is not implemented in q4');
  End;

Procedure setDatabaseLocalization( Const _1_t_languageCode: string);
  Begin
    //https://developer.4d.com/docs/21/commands/set-database-localization
    setDatabaseLocalization( _1_t_languageCode, '');
  End;

Procedure setDatabaseLocalization( Const _1_t_languageCode: string; Const _2_t_operator: string);
  Begin
    //https://developer.4d.com/docs/21/commands/set-database-localization
    t_databaseLocalization := _1_t_languageCode;
    q4coreLanguage.OK := 1;
  End;

Procedure setDatabaseParameter( _1_e_selector: int64; _2_r_value: double);
  Begin
    //https://developer.4d.com/docs/21/commands/set-database-parameter
    setDatabaseParameter( '', _1_e_selector, _2_r_value);
  End;

Procedure setDatabaseParameter( _1_e_selector: int64; Const _2_t_value: string);
  Begin
    //https://developer.4d.com/docs/21/commands/set-database-parameter
    setDatabaseParameter( '', _1_e_selector, _2_t_value);
  End;

Procedure setDatabaseParameter( Const _1_t_tableName: string; _2_e_selector: int64; _3_r_value: double);
  Begin
    //https://developer.4d.com/docs/21/commands/set-database-parameter
    { q4 note:
    Stockage runtime minimal : q4 ne reproduit pas encore tous les sélecteurs
    internes du moteur 4D, mais conserve explicitement les valeurs positionnées. }
    InternalSetDatabaseParameterReal( _1_t_tableName, _2_e_selector, _3_r_value);
  End;

Procedure setDatabaseParameter( Const _1_t_tableName: string; _2_e_selector: int64; Const _3_t_value: string);
  Begin
    //https://developer.4d.com/docs/21/commands/set-database-parameter
    InternalSetDatabaseParameterText( _1_t_tableName, _2_e_selector, _3_t_value);
  End;

Procedure setUpdateFolder( Const _1_t_folderPath: string);
  Begin
    //https://developer.4d.com/docs/21/commands/set-update-folder
    setUpdateFolder( _1_t_folderPath, False);
  End;

Procedure setUpdateFolder( Const _1_t_folderPath: string; _2_b_silentErrors: boolean);
  Begin
    //https://developer.4d.com/docs/21/commands/set-update-folder
    Try
      If ( ( _1_t_folderPath = '') or ( not SysUtils.DirectoryExists( _1_t_folderPath))) Then Begin
        InternalSetFailure( Q4_ERROR_NOT_FOUND);
        If ( _2_b_silentErrors) Then Exit;

        InternalFail( 'SET UPDATE FOLDER: folder not found: ' + _1_t_folderPath, Q4_ERROR_NOT_FOUND);
      End;

      t_updateFolderPath := SysUtils.IncludeTrailingPathDelimiter( _1_t_folderPath);
      q4coreLanguage.OK := 1;
      q4coreLanguage.Error := Q4_ERROR_NONE;
    Except
      on o_exception: Exception Do Begin
        InternalSetFailure( Q4_ERROR_NOT_FOUND);
        If ( not _2_b_silentErrors) Then q4interruptions.assertRaise( 'SET UPDATE FOLDER failed: ' + o_exception.Message, 'q44environnement.setUpdateFolder');
      End;
    End;
  End;

Function structureFile: string;
  Begin
    //https://developer.4d.com/docs/21/commands/structure-file
    Result := InternalDefaultStructureFilePath;
  End;

Function structureFile( Const _1_t_operator: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/structure-file
    Result := structureFile;
  End;

Function tableFragmentation( Const _1_t_tableName: string): double;
  Begin
    //https://developer.4d.com/docs/21/commands/table-fragmentation
    { q4 note:
    4D retourne une fragmentation logique par table. SQLite ne fournit pas
    l'équivalent exact. Si l'extension optionnelle DBSTAT est disponible, q4
    utilise une approximation par pages de la table ; sinon, fallback global
    PRAGMA freelist_count / page_count. }
    Case e_tableFragmentationMode Of
      Q4_TABLE_FRAGMENTATION_DBSTAT: Begin
        If ( not InternalDBStatAvailable) Then InternalFail( 'SQLite DBSTAT is not available. Compile SQLite with SQLITE_ENABLE_DBSTAT_VTAB to enable this mode.',
            Q4_ERROR_UNSUPPORTED);
        Result := InternalTableFragmentationDBStat( _1_t_tableName);
      End;

      Q4_TABLE_FRAGMENTATION_BASIC: Result := InternalTableFragmentationBasic;

      Else If ( InternalDBStatAvailable) Then Result := InternalTableFragmentationDBStat( _1_t_tableName)
        Else
          Result := InternalTableFragmentationBasic;
    End;
  End;

Procedure verifyCurrentDataFile;
  Begin
    //https://developer.4d.com/docs/21/commands/verify-current-data-file
    verifyCurrentDataFile( 0, 0, '');
  End;

Procedure verifyCurrentDataFile( _1_e_objects: int64; _2_e_options: int64; Const _3_t_method: string);
  Var
    _te_tablesArray: q4coreLanguage.Tq4Int64Array;
    _te_fieldsArray: q4coreLanguage.Tq4Int64Array;
  Begin
    //https://developer.4d.com/docs/21/commands/verify-current-data-file
    System.SetLength( _te_tablesArray, 0);
    System.SetLength( _te_fieldsArray, 0);
    verifyCurrentDataFile( _1_e_objects, _2_e_options, _3_t_method, _te_tablesArray, _te_fieldsArray);
  End;

Procedure verifyCurrentDataFile( _1_e_objects: int64; _2_e_options: int64; Const _3_t_method: string; Const _4_te_tablesArray: q4coreLanguage.Tq4Int64Array;
  Const _5_te_fieldsArray: q4coreLanguage.Tq4Int64Array);
  Var
    _t_report: string;
    _b_ok:     boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/verify-current-data-file
    { q4 note:
    4D vérifie plusieurs familles d'objets internes. q4 vérifie le fichier
    SQLite courant via PRAGMA integrity_check. Les filtres objects/options/
    method/tables/fields sont acceptés pour compatibilité mais non interprétés. }
    Try
      _t_report := InternalIntegrityCheckCurrent;
      _b_ok := SysUtils.Trim( SysUtils.LowerCase( _t_report)) = 'ok';

      q4coreLanguage.Document := InternalWriteLog( 'q4_verify_current_data_file', _t_report);
      If ( _b_ok) Then InternalSetOK
      Else
        InternalSetFailure( Q4_ERROR_SQLITE);
    Except
      on o_exception: Exception Do Begin
        q4coreLanguage.Document := '';
        InternalSetFailure( Q4_ERROR_SQLITE);
        q4interruptions.assertRaise( 'VERIFY CURRENT DATA FILE failed: ' + o_exception.Message,
          'q44environnement.verifyCurrentDataFile');
      End;
    End;
  End;

Procedure verifyDataFile( Const _1_t_structurePath: string; Const _2_t_dataPath: string; _3_e_objects: int64; _4_e_options: int64; Const _5_t_method: string);
  Var
    _te_tablesArray: q4coreLanguage.Tq4Int64Array;
    _te_fieldsArray: q4coreLanguage.Tq4Int64Array;
  Begin
    //https://developer.4d.com/docs/21/commands/verify-data-file
    System.SetLength( _te_tablesArray, 0);
    System.SetLength( _te_fieldsArray, 0);
    verifyDataFile( _1_t_structurePath, _2_t_dataPath, _3_e_objects, _4_e_options, _5_t_method, _te_tablesArray, _te_fieldsArray);
  End;

Procedure verifyDataFile( Const _1_t_structurePath: string; Const _2_t_dataPath: string; _3_e_objects: int64; _4_e_options: int64; Const _5_t_method: string;
  Const _6_te_tablesArray: q4coreLanguage.Tq4Int64Array; Const _7_te_fieldsArray: q4coreLanguage.Tq4Int64Array);
  Var
    _t_report: string;
    _b_ok:     boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/verify-data-file
    { q4 note:
    q4 ignore structurePath et vérifie dataPath comme fichier SQLite via
    PRAGMA integrity_check. Les filtres 4D sont acceptés mais non interprétés. }
    Try
      If ( _2_t_dataPath = '') Then InternalFail( 'VERIFY DATA FILE requires an explicit SQLite dataPath in q4', Q4_ERROR_INVALID_PARAMETER);

      If ( InternalSameFileName( _2_t_dataPath, InternalCurrentDataFile) and InternalConnectedToSQLite) Then _t_report := InternalIntegrityCheckCurrent
      Else
        _t_report := InternalIntegrityCheckFile( _2_t_dataPath);

      _b_ok := SysUtils.Trim( SysUtils.LowerCase( _t_report)) = 'ok';

      q4coreLanguage.Document := InternalWriteLog( 'q4_verify_data_file', _t_report);
      If ( _b_ok) Then InternalSetOK
      Else
        InternalSetFailure( Q4_ERROR_SQLITE);
    Except
      on o_exception: Exception Do Begin
        q4coreLanguage.Document := '';
        InternalSetFailure( Q4_ERROR_SQLITE);
        q4interruptions.assertRaise( 'VERIFY DATA FILE failed: ' + o_exception.Message, 'q44environnement.verifyDataFile');
      End;
    End;
  End;

Function versionType: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/version-type
    If ( e_versionType <> 0) Then Exit( e_versionType);

    {$IFDEF CPU64}
  Result := Q4_64_BIT_VERSION;
{$ELSE}
    Result := Q4_DEMO_VERSION;
    {$ENDIF}
  End;

Initialization
  initializeQ4Environment;

Finalization
  If ( o_databaseParameterReal <> nil) Then FreeAndNil( o_databaseParameterReal);
  If ( o_databaseParameterText <> nil) Then FreeAndNil( o_databaseParameterText);

End.
