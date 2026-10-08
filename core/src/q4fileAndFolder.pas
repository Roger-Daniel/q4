Unit q4fileAndFolder;

{$mode objfpc}{$H+}

{
q4fileAndFolder
version du 2026/04/19-18:57

Mapping 4D → q4fileAndFolder -> statut
Command Number 4D,    4D Command,                      q4 API,                           Statut
------------------------------------------------------------------------------------------------
1566,                File,                             fileFromPath,                     OK,
1566,                File,                             fileFromConstant,                 OK,
1567,                Folder,                           folderFromPath,                   OK,
1567,                Folder,                           folderFromConstant,               OK,
1640,                ZIP Create archive,               zipCreateArchiveFromFile,         Partial,
1640,                ZIP Create archive,               zipCreateArchiveFromFolder,       Partial,
1640,                ZIP Create archive,               zipCreateArchiveFromJSON,         Partial,
1637,                ZIP Read archive,                 zipReadArchive,                   Partial,

Doc: https://developer.4d.com/docs/21/commands/theme/File-and-Folder
}

Interface

Uses
  Classes, SysUtils;

Const
  FK_POSIX_PATH = 0;
  FK_PLATFORM_PATH = 1;

  FK_USER_PREFERENCES_FOLDER = 0;
  FK_LICENSES_FOLDER = 1;
  FK_REMOTE_DATABASE_FOLDER = 3;
  FK_DATABASE_FOLDER = 4;
  FK_RESOURCES_FOLDER = 6;
  FK_LOGS_FOLDER = 7;
  FK_WEB_ROOT_FOLDER = 8;
  FK_DATA_FOLDER = 9;
  FK_MOBILE_APPS_FOLDER = 10;
  FK_SYSTEM_FOLDER = 100;
  FK_APPLICATIONS_FOLDER = 116;
  FK_DOCUMENTS_FOLDER = 117;
  FK_HOME_FOLDER = 118;

  BACKUP_SETTINGS_FILE = 1;
  LAST_BACKUP_FILE = 2;
  USER_SETTINGS_FILE = 3;
  USER_SETTINGS_FILE_FOR_DATA = 4;
  VERIFICATION_LOG_FILE = 5;
  COMPACTING_LOG_FILE = 6;
  REPAIR_LOG_FILE = 7;
  HTTP_LOG_FILE = 8;
  HTTP_DEBUG_LOG_FILE = 9;
  REQUEST_LOG_FILE = 10;
  DIAGNOSTIC_LOG_FILE = 11;
  DEBUG_LOG_FILE = 12;
  BACKUP_LOG_FILE = 13;
  BUILD_APPLICATION_LOG_FILE = 14;
  SMTP_LOG_FILE = 15;
  DIRECTORY_FILE = 16;
  BACKUP_SETTINGS_FILE_FOR_DATA = 17;
  CURRENT_BACKUP_SETTINGS_FILE = 18;
  BACKUP_HISTORY_FILE = 19;
  BUILD_APPLICATION_SETTINGS_FILE = 20;
  LAST_JOURNAL_INTEGRATION_LOG_FILE = 22;
  IMAP_LOG_FILE = 23;
  HTTP_CLIENT_LOG_FILE = 24;

  ZIP_WITHOUT_ENCLOSING_FOLDER = 1;
  ZIP_IGNORE_INVISIBLE_FILES = 2;

  ZIP_COMPRESSION_STANDARD = 0;
  ZIP_COMPRESSION_LZMA = 1;
  ZIP_COMPRESSION_XZ = 2;
  ZIP_COMPRESSION_NONE = 3;

  ZIP_ENCRYPTION_NONE = 0;
  ZIP_ENCRYPTION_AES128 = 1;
  ZIP_ENCRYPTION_AES192 = 2;
  ZIP_ENCRYPTION_AES256 = 3;

Type
  Tq4PathKind = ( pkFile, pkFolder, pkArchive);

  Tq4File = Record
    t_path: string;
    t_platformPath: string;
    b_exists: boolean;
    b_isNull: boolean;
  End;

  Tq4Folder = Record
    t_path: string;
    t_platformPath: string;
    b_exists: boolean;
    b_isNull: boolean;
  End;

  Tq4ZipArchive = Record
    t_zipPath: string;
    t_password: string;
    b_exists: boolean;
    b_isNull: boolean;
    t_rootPath: string;
  End;

  Tq4ZipStatus = Record
    b_success: boolean;
    e_status: int64;
    t_statusText: string;
    t_destinationPath: string;
  End;

Function fileFromPath( Const _1_t_path: string; Const _2_e_pathType: int64 = FK_POSIX_PATH; Const _3_t_componentScope: string = ''): Tq4File; overload;
Function fileFromConstant( Const _1_e_fileConstant: int64; Const _2_t_componentScope: string = ''): Tq4File; overload;

Function folderFromPath( Const _1_t_path: string; Const _2_e_pathType: int64 = FK_POSIX_PATH; Const _3_t_componentScope: string = ''): Tq4Folder; overload;
Function folderFromConstant( Const _1_e_folderConstant: int64; Const _2_t_componentScope: string = ''): Tq4Folder; overload;

Function zipCreateArchiveFromFile( Const _1_y_fileToZip: Tq4File; Const _2_y_destinationFile: Tq4File): Tq4ZipStatus;
Function zipCreateArchiveFromFolder( Const _1_y_folderToZip: Tq4Folder; Const _2_y_destinationFile: Tq4File; Const _3_e_options: int64 = 0): Tq4ZipStatus;
Function zipCreateArchiveFromJSON( Const _1_t_zipStructureJSON: string; Const _2_y_destinationFile: Tq4File): Tq4ZipStatus;
Function zipReadArchive( Const _1_y_zipFile: Tq4File; Const _2_t_password: string = ''): Tq4ZipArchive;

Implementation

Function InternalNormalizePath( Const _1_t_path: string; Const _2_e_pathType: int64; Const _3_b_expectFolder: boolean): string;
  Var
    _t_result: string;
  Begin
    _t_result := _1_t_path;

    If ( _2_e_pathType = FK_PLATFORM_PATH) Then Begin
      _t_result := SysUtils.StringReplace( _t_result, '\\', SysUtils.PathDelim, [SysUtils.rfReplaceAll]);
      _t_result := SysUtils.StringReplace( _t_result, '/', SysUtils.PathDelim, [SysUtils.rfReplaceAll]);
    End Else
      _t_result := SysUtils.StringReplace( _t_result, '/', SysUtils.PathDelim, [SysUtils.rfReplaceAll]);

    If ( _3_b_expectFolder) Then If ( ( _t_result <> '') and ( _t_result[System.Length( _t_result)] <> SysUtils.PathDelim)) Then _t_result := _t_result + SysUtils.PathDelim;

    Result := _t_result;
  End;

Function InternalPathToPosix( Const _1_t_path: string): string;
  Var
    _t_result: string;
  Begin
    _t_result := SysUtils.StringReplace( _1_t_path, '\\', '/', [SysUtils.rfReplaceAll]);
    Result := _t_result;
  End;

Function InternalNullFile: Tq4File;
  Begin
    Result.t_path := '';
    Result.t_platformPath := '';
    Result.b_exists := False;
    Result.b_isNull := True;
  End;

Function InternalNullFolder: Tq4Folder;
  Begin
    Result.t_path := '';
    Result.t_platformPath := '';
    Result.b_exists := False;
    Result.b_isNull := True;
  End;

Function InternalNullArchive: Tq4ZipArchive;
  Begin
    Result.t_zipPath := '';
    Result.t_password := '';
    Result.b_exists := False;
    Result.b_isNull := True;
    Result.t_rootPath := '';
  End;

Function InternalResolveFolderConstant( Const _1_e_folderConstant: int64): string;
  Var
    _t_home: string;
  Begin
    _t_home := SysUtils.GetEnvironmentVariable( 'HOME');
    If ( _t_home = '') Then _t_home := SysUtils.GetUserDir;

    Case _1_e_folderConstant Of
      FK_USER_PREFERENCES_FOLDER: Result := SysUtils.IncludeTrailingPathDelimiter( _t_home) + '.config' + SysUtils.PathDelim;
      FK_LICENSES_FOLDER: Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetCurrentDir) + 'Licenses' + SysUtils.PathDelim;
      FK_REMOTE_DATABASE_FOLDER: Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetCurrentDir) + 'RemoteDatabase' + SysUtils.PathDelim;
      FK_DATABASE_FOLDER: Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetCurrentDir);
      FK_RESOURCES_FOLDER: Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetCurrentDir) + 'Resources' + SysUtils.PathDelim;
      FK_LOGS_FOLDER: Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetCurrentDir) + 'Logs' + SysUtils.PathDelim;
      FK_WEB_ROOT_FOLDER: Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetCurrentDir) + 'WebRoot' + SysUtils.PathDelim;
      FK_DATA_FOLDER: Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetCurrentDir) + 'Data' + SysUtils.PathDelim;
      FK_MOBILE_APPS_FOLDER: Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetCurrentDir) + 'MobileApps' + SysUtils.PathDelim;
      FK_SYSTEM_FOLDER: Result := '/';
      {$IFDEF Windows}
      {$ELSE}
      {$ENDIF}
      FK_APPLICATIONS_FOLDER: Result := '/Applications/';
      {$IFDEF Windows}
      {$ELSE}
      {$ENDIF}
      FK_DOCUMENTS_FOLDER: Result := SysUtils.IncludeTrailingPathDelimiter( _t_home) + 'Documents' + SysUtils.PathDelim;
      FK_HOME_FOLDER: Result := SysUtils.IncludeTrailingPathDelimiter( _t_home);
      Else Result := '';
    End;
  End;

Function InternalResolveFileConstant( Const _1_e_fileConstant: int64): string;
  Var
    _t_logsFolder: string;
    _t_dataFolder: string;
  Begin
    _t_logsFolder := InternalResolveFolderConstant( FK_LOGS_FOLDER);
    _t_dataFolder := InternalResolveFolderConstant( FK_DATA_FOLDER);

    Case _1_e_fileConstant Of
      BACKUP_SETTINGS_FILE: Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetCurrentDir) + 'Settings' + SysUtils.PathDelim + 'backup.4DSettings';
      LAST_BACKUP_FILE: Result := _t_dataFolder + 'LastBackup.4BK';
      USER_SETTINGS_FILE: Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetUserDir) + 'settings.4DSettings';
      USER_SETTINGS_FILE_FOR_DATA: Result := _t_dataFolder + 'settings.4DSettings';
      VERIFICATION_LOG_FILE: Result := _t_logsFolder + 'verification.log';
      COMPACTING_LOG_FILE: Result := _t_logsFolder + 'compacting.log';
      REPAIR_LOG_FILE: Result := _t_logsFolder + 'repair.log';
      HTTP_LOG_FILE: Result := _t_logsFolder + 'http.log';
      HTTP_DEBUG_LOG_FILE: Result := _t_logsFolder + 'http_debug.log';
      REQUEST_LOG_FILE: Result := _t_logsFolder + 'request.log';
      DIAGNOSTIC_LOG_FILE: Result := _t_logsFolder + 'diagnostic.log';
      DEBUG_LOG_FILE: Result := _t_logsFolder + 'debug.log';
      BACKUP_LOG_FILE: Result := _t_logsFolder + 'backup.log';
      BUILD_APPLICATION_LOG_FILE: Result := _t_logsFolder + 'build_application.xml';
      SMTP_LOG_FILE: Result := _t_logsFolder + 'smtp.log';
      DIRECTORY_FILE: Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetCurrentDir) + 'directory.json';
      BACKUP_SETTINGS_FILE_FOR_DATA: Result := _t_dataFolder + 'Settings' + SysUtils.PathDelim + 'backup.4DSettings';
      CURRENT_BACKUP_SETTINGS_FILE: Result := _t_dataFolder + 'Settings' + SysUtils.PathDelim + 'backup_current.4DSettings';
      BACKUP_HISTORY_FILE: Result := _t_logsFolder + 'backup_history.log';
      BUILD_APPLICATION_SETTINGS_FILE: Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetCurrentDir) + 'Settings' + SysUtils.PathDelim + 'buildApp.4DSettings';
      LAST_JOURNAL_INTEGRATION_LOG_FILE: Result := _t_logsFolder + 'journal_integration.log';
      IMAP_LOG_FILE: Result := _t_logsFolder + 'imap.log';
      HTTP_CLIENT_LOG_FILE: Result := _t_logsFolder + 'http_client.log';
      Else Result := '';
    End;
  End;

Function InternalBuildFile( Const _1_t_path: string): Tq4File;
  Begin
    If ( _1_t_path = '') Then Begin
      Result := InternalNullFile;
      Exit;
    End;

    Result.t_platformPath := _1_t_path;
    Result.t_path := InternalPathToPosix( _1_t_path);
    Result.b_exists := SysUtils.FileExists( _1_t_path);
    Result.b_isNull := False;
  End;

Function InternalBuildFolder( Const _1_t_path: string): Tq4Folder;
  Begin
    If ( _1_t_path = '') Then Begin
      Result := InternalNullFolder;
      Exit;
    End;

    Result.t_platformPath := SysUtils.IncludeTrailingPathDelimiter( _1_t_path);
    Result.t_path := InternalPathToPosix( Result.t_platformPath);
    Result.b_exists := SysUtils.DirectoryExists( Result.t_platformPath);
    Result.b_isNull := False;
  End;

Function InternalEnsureParentFolder( Const _1_t_filePath: string): boolean;
  Var
    _t_folderPath: string;
  Begin
    _t_folderPath := SysUtils.ExtractFileDir( _1_t_filePath);
    If ( _t_folderPath = '') Then Begin
      Result := True;
      Exit;
    End;

    If ( SysUtils.DirectoryExists( _t_folderPath)) Then Begin
      Result := True;
      Exit;
    End;

    Result := SysUtils.ForceDirectories( _t_folderPath);
  End;

Function InternalWriteStubArchive( Const _1_t_sourceDescription: string; Const _2_t_destinationFile: string): boolean;
  Var
    _o_fileStream: TFileStream;
    _t_content:    ansistring;
  Begin
    If ( not InternalEnsureParentFolder( _2_t_destinationFile)) Then Begin
      Result := False;
      Exit;
    End;

    _o_fileStream := TFileStream.Create( _2_t_destinationFile, fmCreate);
    Try
      _t_content := 'q4 ZIP STUB' + LineEnding + _1_t_sourceDescription + LineEnding;
      If ( System.Length( _t_content) > 0) Then _o_fileStream.WriteBuffer( _t_content[1], System.Length( _t_content));
      Result := True;
    Finally
      _o_fileStream.Free;
    End;
  End;

Function InternalFileFromPath( Const _1_t_path: string; Const _2_e_pathType: int64; Const _3_t_componentScope: string): Tq4File;
  Var
    _t_normalizedPath: string;
  Begin
    _t_normalizedPath := InternalNormalizePath( _1_t_path, _2_e_pathType, False);
    Result := InternalBuildFile( _t_normalizedPath);
  End;

Function InternalFileFromConstant( Const _1_e_fileConstant: int64; Const _2_t_componentScope: string): Tq4File;
  Var
    _t_resolvedPath: string;
  Begin
    _t_resolvedPath := InternalResolveFileConstant( _1_e_fileConstant);
    If ( ( _2_t_componentScope <> '') and ( _2_t_componentScope <> '*')) Then Begin
      Result := InternalNullFile;
      Exit;
    End;

    If ( _t_resolvedPath = '') Then Begin
      Result := InternalNullFile;
      Exit;
    End;

    Result := InternalBuildFile( _t_resolvedPath);
    If ( not Result.b_exists) Then Result := InternalNullFile;
  End;

Function InternalFolderFromPath( Const _1_t_path: string; Const _2_e_pathType: int64; Const _3_t_componentScope: string): Tq4Folder;
  Var
    _t_normalizedPath: string;
  Begin
    _t_normalizedPath := InternalNormalizePath( _1_t_path, _2_e_pathType, True);
    Result := InternalBuildFolder( _t_normalizedPath);
  End;

Function InternalFolderFromConstant( Const _1_e_folderConstant: int64; Const _2_t_componentScope: string): Tq4Folder;
  Var
    _t_resolvedPath: string;
  Begin
    _t_resolvedPath := InternalResolveFolderConstant( _1_e_folderConstant);
    If ( ( _2_t_componentScope <> '') and ( _2_t_componentScope <> '*')) Then Begin
      Result := InternalNullFolder;
      Exit;
    End;

    If ( _t_resolvedPath = '') Then Begin
      Result := InternalNullFolder;
      Exit;
    End;

    Result := InternalBuildFolder( _t_resolvedPath);
  End;

Function InternalZipCreateArchiveFromFile( Const _1_y_fileToZip: Tq4File; Const _2_y_destinationFile: Tq4File): Tq4ZipStatus;
  Var
    _b_written: boolean;
  Begin
    Result.b_success := False;
    Result.e_status := -1;
    Result.t_statusText := 'Cannot create ZIP archive';
    Result.t_destinationPath := _2_y_destinationFile.t_path;

    If ( _1_y_fileToZip.b_isNull or _2_y_destinationFile.b_isNull) Then Exit;

    If ( not _1_y_fileToZip.b_exists) Then Begin
      Result.e_status := -2;
      Result.t_statusText := 'Source file does not exist';
      Exit;
    End;

    _b_written := InternalWriteStubArchive( 'FILE=' + _1_y_fileToZip.t_path, _2_y_destinationFile.t_platformPath);
    If ( not _b_written) Then Begin
      Result.e_status := -3;
      Result.t_statusText := 'Cannot create ZIP archive';
      Exit;
    End;

    Result.b_success := True;
    Result.e_status := 0;
    Result.t_statusText := '';
  End;

Function InternalZipCreateArchiveFromFolder( Const _1_y_folderToZip: Tq4Folder; Const _2_y_destinationFile: Tq4File; Const _3_e_options: int64): Tq4ZipStatus;
  Var
    _t_sourceDescription: string;
    _b_written: boolean;
  Begin
    Result.b_success := False;
    Result.e_status := -1;
    Result.t_statusText := 'Cannot create ZIP archive';
    Result.t_destinationPath := _2_y_destinationFile.t_path;

    If ( _1_y_folderToZip.b_isNull or _2_y_destinationFile.b_isNull) Then Exit;

    If ( not _1_y_folderToZip.b_exists) Then Begin
      Result.e_status := -2;
      Result.t_statusText := 'Source folder does not exist';
      Exit;
    End;

    _t_sourceDescription := 'FOLDER=' + _1_y_folderToZip.t_path + ';OPTIONS=' + SysUtils.IntToStr( _3_e_options);
    _b_written := InternalWriteStubArchive( _t_sourceDescription, _2_y_destinationFile.t_platformPath);
    If ( not _b_written) Then Begin
      Result.e_status := -3;
      Result.t_statusText := 'Cannot create ZIP archive';
      Exit;
    End;

    Result.b_success := True;
    Result.e_status := 0;
    Result.t_statusText := '';
  End;

Function InternalZipCreateArchiveFromJSON( Const _1_t_zipStructureJSON: string; Const _2_y_destinationFile: Tq4File): Tq4ZipStatus;
  Var
    _b_written: boolean;
  Begin
    Result.b_success := False;
    Result.e_status := -1;
    Result.t_statusText := 'Cannot create ZIP archive';
    Result.t_destinationPath := _2_y_destinationFile.t_path;

    If ( _2_y_destinationFile.b_isNull) Then Exit;

    If ( _1_t_zipStructureJSON = '') Then Begin
      Result.e_status := -2;
      Result.t_statusText := 'ZIP structure is empty';
      Exit;
    End;

    _b_written := InternalWriteStubArchive( 'JSON=' + _1_t_zipStructureJSON, _2_y_destinationFile.t_platformPath);
    If ( not _b_written) Then Begin
      Result.e_status := -3;
      Result.t_statusText := 'Cannot create ZIP archive';
      Exit;
    End;

    Result.b_success := True;
    Result.e_status := 0;
    Result.t_statusText := '';
  End;

Function InternalZipReadArchive( Const _1_y_zipFile: Tq4File; Const _2_t_password: string): Tq4ZipArchive;
  Begin
    If ( _1_y_zipFile.b_isNull) Then Begin
      Result := InternalNullArchive;
      Exit;
    End;

    Result.t_zipPath := _1_y_zipFile.t_path;
    Result.t_password := _2_t_password;
    Result.b_exists := _1_y_zipFile.b_exists;
    Result.b_isNull := not _1_y_zipFile.b_exists;
    Result.t_rootPath := _1_y_zipFile.t_path;
  End;

Function fileFromPath( Const _1_t_path: string; Const _2_e_pathType: int64; Const _3_t_componentScope: string): Tq4File;
  Begin
    //https://developer.4d.com/docs/commands/file
    Result := InternalFileFromPath( _1_t_path, _2_e_pathType, _3_t_componentScope);
  End;

Function fileFromConstant( Const _1_e_fileConstant: int64; Const _2_t_componentScope: string): Tq4File;
  Begin
    //https://developer.4d.com/docs/commands/file
    Result := InternalFileFromConstant( _1_e_fileConstant, _2_t_componentScope);
  End;

Function folderFromPath( Const _1_t_path: string; Const _2_e_pathType: int64; Const _3_t_componentScope: string): Tq4Folder;
  Begin
    //https://developer.4d.com/docs/commands/folder
    Result := InternalFolderFromPath( _1_t_path, _2_e_pathType, _3_t_componentScope);
  End;

Function folderFromConstant( Const _1_e_folderConstant: int64; Const _2_t_componentScope: string): Tq4Folder;
  Begin
    //https://developer.4d.com/docs/commands/folder
    Result := InternalFolderFromConstant( _1_e_folderConstant, _2_t_componentScope);
  End;

Function zipCreateArchiveFromFile( Const _1_y_fileToZip: Tq4File; Const _2_y_destinationFile: Tq4File): Tq4ZipStatus;
  Begin
    //https://developer.4d.com/docs/commands/zip-create-archive
    Result := InternalZipCreateArchiveFromFile( _1_y_fileToZip, _2_y_destinationFile);
  End;

Function zipCreateArchiveFromFolder( Const _1_y_folderToZip: Tq4Folder; Const _2_y_destinationFile: Tq4File; Const _3_e_options: int64): Tq4ZipStatus;
  Begin
    //https://developer.4d.com/docs/commands/zip-create-archive
    Result := InternalZipCreateArchiveFromFolder( _1_y_folderToZip, _2_y_destinationFile, _3_e_options);
  End;

Function zipCreateArchiveFromJSON( Const _1_t_zipStructureJSON: string; Const _2_y_destinationFile: Tq4File): Tq4ZipStatus;
  Begin
    //https://developer.4d.com/docs/commands/zip-create-archive
    Result := InternalZipCreateArchiveFromJSON( _1_t_zipStructureJSON, _2_y_destinationFile);
  End;

Function zipReadArchive( Const _1_y_zipFile: Tq4File; Const _2_t_password: string): Tq4ZipArchive;
  Begin
    //https://developer.4d.com/docs/commands/zip-read-archive
    Result := InternalZipReadArchive( _1_y_zipFile, _2_t_password);
  End;

End.
