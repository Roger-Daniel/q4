unit q4file;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, fgl, Graphics;

// Alias pour lever l'ambiguïté avec d'éventuels conflits de noms
type
  Tq4Bitmap = Graphics.TBitmap;

{$IFDEF WINDOWS}
// CreateSymbolicLinkW n'est pas toujours exposé par l'unit Windows de FPC
function CreateSymbolicLinkW(_1_p_lpSymlinkFileName, _2_p_lpTargetFileName: PWideChar;
                             _3_e_dwFlags: LongWord): LongBool;
  stdcall; external 'kernel32' name 'CreateSymbolicLinkW';

// MoveFileExW pour déplacer/renommer des dossiers non vides
function MoveFileExW(_1_p_lpExistingFileName, _2_p_lpNewFileName: PWideChar;
                     _3_e_dwFlags: LongWord): LongBool;
  stdcall; external 'kernel32' name 'MoveFileExW';
{$ENDIF}

// ============================================================
//  TYPES DE BASE
// ============================================================

type
  TProgressCallback = procedure(_1_e_progress: Int64);

  T4DObject = specialize TFPGMap<String, Variant>;

// Forward declarations
  Tq4File       = class;
  Tq4Folder     = class;
  Tq4FileHandle = class;
  Tq4ZipFile    = class;
  Tq4ZipFolder  = class;
  Tq4ZipArchive = class;

  Tq4FileList   = specialize TFPGObjectList<Tq4File>;
  Tq4FolderList = specialize TFPGObjectList<Tq4Folder>;

  Tq4ZipFileList   = specialize TFPGObjectList<Tq4ZipFile>;
  Tq4ZipFolderList = specialize TFPGObjectList<Tq4ZipFolder>;

// ============================================================
//  CONSTANTES — PATH TYPE
// ============================================================

const
  fkPosixPath    = 0;
  fkPlatformPath = 1;

// ============================================================
//  CONSTANTES — FILE CONSTANTS (File(fileConstant))
// ============================================================

const
  BackupSettingsFile            = 1;
  LastBackupFile                = 2;
  UserSettingsFile              = 3;
  UserSettingsFileForData       = 4;
  VerificationLogFile           = 5;
  CompactingLogFile             = 6;
  RepairLogFile                 = 7;
  HTTPLogFile                   = 8;
  HTTPDebugLogFile              = 9;
  RequestLogFile                = 10;
  DiagnosticLogFile             = 11;
  DebugLogFile                  = 12;
  BackupLogFile                 = 13;
  BuildApplicationLogFile       = 14;
  SMTPLogFile                   = 15;
  DirectoryFile                 = 16;
  BackupSettingsFileForData     = 17;
  CurrentBackupSettingsFile     = 18;
  BackupHistoryFile             = 19;
  BuildApplicationSettingsFile  = 20;
  LastJournalIntegrationLogFile = 22;
  IMAPLogFile                   = 23;
  HTTPClientLogFile             = 24;

// ============================================================
//  CONSTANTES — FOLDER CONSTANTS (Folder(folderConstant))
// ============================================================

const
  fkUserPreferencesFolder = 0;
  fkLicensesFolder        = 1;
  fkRemoteDatabaseFolder  = 3;
  fkDatabaseFolder        = 4;
  fkResourcesFolder       = 6;
  fkLogsFolder            = 7;
  fkWebRootFolder         = 8;
  fkDataFolder            = 9;
  fkMobileAppsFolder      = 10;
  fkSystemFolder          = 100;
  fkDesktopFolder         = 115;
  fkApplicationsFolder    = 116;
  fkDocumentsFolder       = 117;
  fkHomeFolder            = 118;

// ============================================================
//  CONSTANTES — OPÉRATIONS FICHIERS/DOSSIERS
// ============================================================

const
  fkOverwrite    = 4;
  fkAliasLink    = 0;
  fkSymbolicLink = 1;

// ============================================================
//  CONSTANTES — OPTIONS DOSSIERS (files() / folders())
// ============================================================

const
  fkIgnoreInvisibles = 8;
  fkRecursive        = 32;

// ============================================================
//  CONSTANTES — ZIP
// ============================================================

const
  ZIPCompressionStandard     = 0;
  ZIPCompressionLZMA         = 1;
  ZIPCompressionXZ           = 2;
  ZIPCompressionNone         = 3;
  ZIPEncryptionNone          = 0;
  ZIPEncryptionAES128        = 1;
  ZIPEncryptionAES192        = 2;
  ZIPEncryptionAES256        = 3;
  ZIPWithoutEnclosingFolder  = 1;
  ZIPIgnoreInvisibleFiles    = 2;

// ============================================================
//  CONSTANTES — BREAK MODE (getText / setText)
// ============================================================

const
  DocumentWithNativeLineEndings = 1;
  DocumentWithCRLineEndings     = 2;
  DocumentWithLFLineEndings     = 3;
  DocumentWithCRLFLineEndings   = 4;

// ============================================================
//  Tq4ZipStructure
// ============================================================

type
  Tq4ZipStructureFileItem = class
  public
    source      : TObject;   // Tq4File ou Tq4Folder
    destination : string;    // chemin relatif optionnel dans l'archive
    option      : Int64;   // 0 ou ZIPIgnoreInvisibleFiles
    constructor Create;
  end;

  Tq4ZipStructureFileItemList = specialize TFPGObjectList<Tq4ZipStructureFileItem>;

  Tq4ZipStructure = class
  private
    FFiles      : Tq4ZipStructureFileItemList;
    FCompression: longInt;
    FLevel      : longInt;
    FEncryption : longInt;
    FPassword   : string;
    FCallback   : TProgressCallback;
  public
    constructor Create;
    destructor  Destroy; override;

    property files      : Tq4ZipStructureFileItemList read FFiles;
    property compression: integer  read FCompression write FCompression;
    property level      : integer  read FLevel       write FLevel;
    property encryption : integer  read FEncryption  write FEncryption;
    property password   : string   read FPassword    write FPassword;
    property callback   : TProgressCallback read FCallback write FCallback;
  end;

// ============================================================
//  Tq4FileHandle
// ============================================================

  Tq4FileHandle = class
  private
    FMode           : string;
    FOffset         : longInt;
    FCharSet        : string;
    FBreakModeRead  : longInt;
    FBreakModeWrite : longInt;
    FFile           : Tq4File;
    FStream         : TFileStream;
  public
    constructor Create(_1_y_aFile: Tq4File; const _2_t_aMode: string);
    destructor  Destroy; override;

    // Propriétés
    property mode           : string  read FMode;
    property offset         : integer read FOffset         write FOffset;
    property charSet        : string  read FCharSet        write FCharSet;
    property breakModeRead  : integer read FBreakModeRead  write FBreakModeRead;
    property breakModeWrite : integer read FBreakModeWrite write FBreakModeWrite;

    // Méthodes
    function  getSize: Int64;
    procedure setSize(_1_e_newSize: Int64);
    function  readLine: string;
    function  readText(const _1_t_stopChar: string = ''): string;
    procedure writeLine(const _1_t_lineOfText: string);
    procedure writeText(const _1_t_text: string);
    procedure writeBlob(const _1_by_blob: TBytes);
  end;

// ============================================================
//  Tq4File
// ============================================================

  Tq4File = class
  protected
    FPath     : string;
    FPathType : Int64;
  protected
    function  GetExists: boolean; virtual;
    function  GetExtension: string; virtual;
    function  GetFullName: string; virtual;
    function  GetName: string; virtual;
    function  GetPlatformPath: string; virtual;
    function  GetCreationDate: string; virtual;
    function  GetCreationTime: string; virtual;
    function  GetModificationDate: string; virtual;
    function  GetModificationTime: string; virtual;
    function  GetHidden: boolean; virtual;
    function  GetIsAlias: boolean; virtual;
    function  GetIsFile: boolean; virtual;
    function  GetIsFolder: boolean; virtual;
    function  GetIsWritable: boolean; virtual;
    function  GetSize: double; virtual;
    function  GetParent: Tq4Folder; virtual;
    function  GetOriginalFile: Tq4File; virtual;
  public
    constructor Create(const _1_t_aPath: string; _2_e_aPathType: Int64 = fkPosixPath);
    destructor  Destroy; override;

    // Propriétés read-only
    property path             : string  read FPath;
    property platformPath     : string  read GetPlatformPath;
    property exists           : boolean read GetExists;
    property extension        : string  read GetExtension;
    property fullName         : string  read GetFullName;
    property name             : string  read GetName;
    property creationDate     : string  read GetCreationDate;
    property creationTime     : string  read GetCreationTime;
    property modificationDate : string  read GetModificationDate;
    property modificationTime : string  read GetModificationTime;
    property hidden           : boolean read GetHidden;
    property isAlias          : boolean read GetIsAlias;
    property isFile           : boolean read GetIsFile;
    property isFolder         : boolean read GetIsFolder;
    property isWritable       : boolean read GetIsWritable;
    property size             : double  read GetSize;
    property parent           : Tq4Folder read GetParent;
    property original         : Tq4File   read GetOriginalFile;

    // Méthodes
    function  create_: boolean;
    procedure delete;
    function  copyTo(_1_y_destinationFolder: Tq4Folder;
                     const _2_t_newName: string = '';
                     _3_e_overwrite: Int64 = 0): Tq4File;
    function  moveTo(_1_y_destinationFolder: Tq4Folder;
                     const _2_t_newName: string = ''): Tq4File;
    function  rename(const _1_t_newName: string): Tq4File;
    function  createAlias(_1_y_destinationFolder: Tq4Folder;
                          const _2_t_aliasName: string;
                          _3_e_aliasType: Int64 = fkAliasLink): Tq4File;
    function  getContent: TBytes;
    procedure setContent(const _1_by_content: TBytes);
    function  getText(const _1_t_charSetName: string = '';
                      _2_e_breakMode: Int64 = DocumentWithNativeLineEndings): string;
    procedure setText(const _1_t_text: string;
                      const _2_t_charSetName: string = '';
                      _3_e_breakMode: Int64 = DocumentWithNativeLineEndings);
    function  getIcon(_1_e_iconSize: Int64 = 0): Tq4Bitmap;
    function  getAppInfo: T4DObject;
    procedure setAppInfo(_1_o_info: T4DObject);
    function  open(const _1_t_mode: string = 'read'): Tq4FileHandle; overload;
    function  open(_1_o_options: T4DObject): Tq4FileHandle; overload;
  end;

// ============================================================
//  Tq4Folder
// ============================================================

  Tq4Folder = class
  protected
    FPath     : string;
    FPathType : Int64;
  protected
    function  GetExists: boolean; virtual;
    function  GetExtension: string; virtual;
    function  GetFullName: string; virtual;
    function  GetName: string; virtual;
    function  GetPlatformPath: string; virtual;
    function  GetCreationDate: string; virtual;
    function  GetCreationTime: string; virtual;
    function  GetModificationDate: string; virtual;
    function  GetModificationTime: string; virtual;
    function  GetHidden: boolean; virtual;
    function  GetIsAlias: boolean; virtual;
    function  GetIsFile: boolean; virtual;
    function  GetIsFolder: boolean; virtual;
    function  GetParent: Tq4Folder; virtual;
    function  GetOriginal: Tq4Folder; virtual;
    function  GetIsPackage: boolean; virtual;
  public
    constructor Create(const _1_t_aPath: string; _2_e_aPathType: Int64 = fkPosixPath);
    destructor  Destroy; override;

    // Propriétés read-only
    property path             : string    read FPath;
    property platformPath     : string    read GetPlatformPath;
    property exists           : boolean   read GetExists;
    property extension        : string    read GetExtension;
    property fullName         : string    read GetFullName;
    property name             : string    read GetName;
    property creationDate     : string    read GetCreationDate;
    property creationTime     : string    read GetCreationTime;
    property modificationDate : string    read GetModificationDate;
    property modificationTime : string    read GetModificationTime;
    property hidden           : boolean   read GetHidden;
    property isAlias          : boolean   read GetIsAlias;
    property isFile           : boolean   read GetIsFile;
    property isFolder         : boolean   read GetIsFolder;
    property isPackage        : boolean   read GetIsPackage;
    property parent           : Tq4Folder read GetParent;
    property original         : Tq4Folder read GetOriginal;

    // Navigation enfants
    function  file_(const _1_t_relativePath: string): Tq4File;
    function  folder_(const _1_t_relativePath: string): Tq4Folder;
    function  files(_1_e_options: Int64 = 0): Tq4FileList;
    function  folders(_1_e_options: Int64 = 0): Tq4FolderList;

    // Méthodes
    function  create_: boolean;
    procedure delete(_1_e_option: Int64 = 0);
    function  copyTo(_1_y_destinationFolder: Tq4Folder;
                     const _2_t_newName: string = '';
                     _3_e_overwrite: Int64 = 0): Tq4Folder;
    function  moveTo(_1_y_destinationFolder: Tq4Folder;
                     const _2_t_newName: string = ''): Tq4Folder;
    function  rename(const _1_t_newName: string): Tq4Folder;
    function  createAlias(_1_y_destinationFolder: Tq4Folder;
                          const _2_t_aliasName: string;
                          _3_e_aliasType: Int64 = fkAliasLink): Tq4File;
    function  getIcon(_1_e_iconSize: Int64 = 0): Tq4Bitmap;
  end;

// ============================================================
//  Tq4ZipFile  (sous-ensemble read-only de Tq4File)
// ============================================================

  Tq4ZipFile = class(Tq4File)
  protected
    function GetIsWritable: boolean; override;
  public
    constructor Create(const _1_t_aRelativePath: string);
    function  getContent: TBytes;
    function  getText(const _1_t_charSetName: string = '';
                      _2_e_breakMode: Int64 = DocumentWithNativeLineEndings): string;
    function  copyTo(_1_y_destinationFolder: Tq4Folder;
                     const _2_t_newName: string = '';
                     _3_e_overwrite: Int64 = 0): Tq4File;
  end;

// ============================================================
//  Tq4ZipFolder  (sous-ensemble read-only de Tq4Folder)
// ============================================================

  Tq4ZipFolder = class(Tq4Folder)
  public
    constructor Create(const _1_t_aRelativePath: string);
    function  files(_1_e_options: Int64 = 0): Tq4ZipFileList;
    function  folders(_1_e_options: Int64 = 0): Tq4ZipFolderList;
    function  file_(const _1_t_relativePath: string): Tq4ZipFile;
    function  folder_(const _1_t_relativePath: string): Tq4ZipFolder;
    function  copyTo(_1_y_destinationFolder: Tq4Folder;
                     const _2_t_newName: string = '';
                     _3_e_overwrite: Int64 = 0): Tq4Folder;
  end;

// ============================================================
//  Tq4ZipArchive
// ============================================================

  Tq4ZipArchive = class
  private
    FRoot : Tq4ZipFolder;
  public
    constructor Create;
    destructor  Destroy; override;
    property root : Tq4ZipFolder read FRoot;
  end;

// ============================================================
//  FONCTIONS GLOBALES
// ============================================================

// --- File ---
function File_(const _1_t_path: string;
               _2_e_pathType: Int64 = fkPosixPath;
               const _3_t_star: string = ''): Tq4File; overload;
function File_(_1_e_fileConstant: Int64;
               const _2_t_star: string = ''): Tq4File; overload;

// --- Folder ---
function Folder_(const _1_t_path: string;
                 _2_e_pathType: Int64 = fkPosixPath;
                 const _3_t_star: string = ''): Tq4Folder; overload;
function Folder_(_1_e_folderConstant: Int64;
                 const _2_t_star: string = ''): Tq4Folder; overload;

// --- ZIP Create archive ---
function ZIPCreateArchive(_1_y_fileToZip: Tq4File;
                          _2_y_destinationFile: Tq4File): T4DObject; overload;
function ZIPCreateArchive(_1_y_folderToZip: Tq4Folder;
                          _2_y_destinationFile: Tq4File;
                          _3_e_options: Int64 = 0): T4DObject; overload;
function ZIPCreateArchive(_1_y_zipStructure: Tq4ZipStructure;
                          _2_y_destinationFile: Tq4File): T4DObject; overload;

// --- ZIP Read archive ---
function ZIPReadArchive(_1_y_zipFile: Tq4File;
                        const _2_t_password: string = ''): Tq4ZipArchive;

// ============================================================
implementation
// ============================================================

uses
  DateUtils, FileUtil, LazFileUtils, Zipper
  {$IFDEF WINDOWS}, Windows{$ENDIF}
  {$IFNDEF WINDOWS}, BaseUnix{$ENDIF}
  ;

// -------------------------------------------------------------------
//  Helpers internes
// -------------------------------------------------------------------

function InternalNativePath(const _1_t_posixPath: string): string;
var
  s : string;
begin
  s := _1_t_posixPath;
  {$IFDEF WINDOWS}
  s := StringReplace(s, '/', '\', [rfReplaceAll]);
  {$ENDIF}
  Result := s;
end;

function InternalDateToStr(const _1_y_dt: TDateTime): string;
begin
  try
    Result := FormatDateTime('yyyy-mm-dd', _1_y_dt);
  except
    Result := '0000-00-00';
  end;
end;

function InternalTimeToStr(const _1_y_dt: TDateTime): string;
begin
  try
    Result := FormatDateTime('hh:nn:ss', Frac(Abs(_1_y_dt)));
  except
    Result := '00:00:00';
  end;
end;

function InternalIsHidden(const _1_t_name: string; _2_e_attr: Int64): boolean;
begin
  {$IFDEF WINDOWS}
  Result := (_2_e_attr and $00000002) <> 0;
  {$ELSE}
  // Sur macOS/Linux, les fichiers cachés commencent par '.'
  Result := (Length(_1_t_name) > 0) and (_1_t_name[1] = '.');
  {$ENDIF}
end;

// Supprime récursivement le contenu d'un dossier (sans supprimer le dossier lui-même).
procedure InternalClearDir(const _1_t_path: string);
var
  info    : TSearchRec;
  baseDir : string;
begin
  baseDir := IncludeTrailingPathDelimiter(_1_t_path);
  if (FindFirst(baseDir + '*', faAnyFile, info) = 0) then
  begin
    repeat
      if ((info.Name = '.') or (info.Name = '..')) then Continue;
      if ((info.Attr and faDirectory) <> 0) then
      begin
        InternalClearDir(baseDir + info.Name);
        RemoveDir(baseDir + info.Name);
      end
      else
        SysUtils.DeleteFile(baseDir + info.Name);
    until (FindNext(info) <> 0);
    SysUtils.FindClose(info);
  end;
end;

// Ajoute récursivement tous les fichiers d'un dossier dans un TZipper.
// prefixInZip : chemin relatif à utiliser dans l'archive (peut être vide).
procedure InternalAddDirToZip(_1_y_zipper: TZipper;
                              const _2_t_diskDir: string;
                              const _3_t_prefixInZip: string);
var
  info    : TSearchRec;
  baseDir : string;
  entryName : string;
begin
  baseDir := IncludeTrailingPathDelimiter(_2_t_diskDir);
  if (FindFirst(baseDir + '*', faAnyFile, info) = 0) then
  begin
    repeat
      if ((info.Name = '.') or (info.Name = '..')) then Continue;
      if ((info.Attr and faDirectory) <> 0) then
      begin
        // Récursion dans le sous-dossier
        if (_3_t_prefixInZip <> '') then
          entryName := _3_t_prefixInZip + info.Name + '/'
        else
          entryName := info.Name + '/';
        InternalAddDirToZip(_1_y_zipper, baseDir + info.Name, entryName);
      end
      else
      begin
        if (_3_t_prefixInZip <> '') then
          entryName := _3_t_prefixInZip + info.Name
        else
          entryName := info.Name;
        _1_y_zipper.Entries.AddFileEntry(baseDir + info.Name, entryName);
      end;
    until (FindNext(info) <> 0);
    SysUtils.FindClose(info);
  end;
end;

// -------------------------------------------------------------------
//  Tq4ZipStructureFileItem
// -------------------------------------------------------------------

constructor Tq4ZipStructureFileItem.Create;
begin
  inherited Create;
  source      := nil;
  destination := '';
  option      := 0;
end;

// -------------------------------------------------------------------
//  Tq4ZipStructure
// -------------------------------------------------------------------

constructor Tq4ZipStructure.Create;
begin
  inherited Create;
  FFiles       := Tq4ZipStructureFileItemList.Create(True);
  FCompression := ZIPCompressionStandard;
  FLevel       := 0;
  FEncryption  := ZIPEncryptionNone;
  FPassword    := '';
  FCallback    := nil;
end;

destructor Tq4ZipStructure.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

// -------------------------------------------------------------------
//  Tq4FileHandle
// -------------------------------------------------------------------

constructor Tq4FileHandle.Create(_1_y_aFile: Tq4File; const _2_t_aMode: string);
var
  accessMode : word;
begin
  inherited Create;
  FFile           := _1_y_aFile;
  FMode           := _2_t_aMode;
  FOffset         := 0;
  FCharSet        := 'UTF-8';
  FBreakModeRead  := DocumentWithNativeLineEndings;
  FBreakModeWrite := DocumentWithNativeLineEndings;

  if (_2_t_aMode = 'write') then
    accessMode := fmCreate
  else if (_2_t_aMode = 'append') then
    accessMode := fmOpenReadWrite or fmShareDenyWrite
  else
    accessMode := fmOpenRead or fmShareDenyNone;

  FStream := TFileStream.Create(
               InternalNativePath(_1_y_aFile.path), accessMode);

  if (_2_t_aMode = 'append') then
    FStream.Seek(0, soEnd);
end;

destructor Tq4FileHandle.Destroy;
begin
  FStream.Free;
  inherited Destroy;
end;

function Tq4FileHandle.getSize: Int64;
begin
  Result := FStream.Size;
end;

procedure Tq4FileHandle.setSize(_1_e_newSize: Int64);
begin
  FStream.Size := _1_e_newSize;
end;

function Tq4FileHandle.readLine: string;
var
  c      : AnsiChar;
  buf    : string;
  nRead  : Int64;
begin
  buf := '';
  FStream.Position := FOffset;
  repeat
    nRead := FStream.Read(c, 1);
    if (nRead = 0) then Break;
    if (c = #10) then Break;
    if (c <> #13) then
      buf := buf + c;
  until (False);
  FOffset := FStream.Position;
  Result := buf;
end;

function Tq4FileHandle.readText(const _1_t_stopChar: string = ''): string;
var
  remaining : Int64;
  rawBytes  : TBytes;
  stopPos   : Int64;
  fullText  : string;
begin
  FStream.Position := FOffset;
  remaining := FStream.Size - FOffset;
  if (remaining <= 0) then
  begin
    Result := '';
    Exit;
  end;
  SetLength(rawBytes, remaining);
  FStream.Read(rawBytes[0], remaining);
  fullText := TEncoding.UTF8.GetString(rawBytes);

  if (_1_t_stopChar <> '') then
  begin
    stopPos := Pos(_1_t_stopChar, fullText);
    if (stopPos > 0) then
    begin
      Result   := Copy(fullText, 1, stopPos - 1);
      FOffset  := FOffset + Length(TEncoding.UTF8.GetBytes(
                    Copy(fullText, 1, stopPos + Length(_1_t_stopChar) - 1)));
      Exit;
    end;
  end;

  FOffset := FStream.Size;
  Result  := fullText;
end;

procedure Tq4FileHandle.writeLine(const _1_t_lineOfText: string);
var
  encoded : TBytes;
  eol     : string;
begin
  FStream.Position := FOffset;
  {$IFDEF WINDOWS}
  eol := #13#10;
  {$ELSE}
  eol := #10;
  {$ENDIF}
  encoded := TEncoding.UTF8.GetBytes(_1_t_lineOfText + eol);
  FStream.Write(encoded[0], Length(encoded));
  FOffset := FStream.Position;
end;

procedure Tq4FileHandle.writeText(const _1_t_text: string);
var
  encoded : TBytes;
begin
  FStream.Position := FOffset;
  encoded := TEncoding.UTF8.GetBytes(_1_t_text);
  FStream.Write(encoded[0], Length(encoded));
  FOffset := FStream.Position;
end;

procedure Tq4FileHandle.writeBlob(const _1_by_blob: TBytes);
begin
  FStream.Position := FOffset;
  if (Length(_1_by_blob) > 0) then
    FStream.Write(_1_by_blob[0], Length(_1_by_blob));
  FOffset := FStream.Position;
end;

// -------------------------------------------------------------------
//  Tq4File
// -------------------------------------------------------------------

constructor Tq4File.Create(const _1_t_aPath: string; _2_e_aPathType: Int64 = fkPosixPath);
begin
  inherited Create;
  FPath     := _1_t_aPath;
  FPathType := _2_e_aPathType;
end;

destructor Tq4File.Destroy;
begin
  inherited Destroy;
end;

function Tq4File.GetExists: boolean;
begin
  Result := FileExists(InternalNativePath(FPath));
end;

function Tq4File.GetExtension: string;
begin
  Result := ExtractFileExt(FPath);
end;

function Tq4File.GetFullName: string;
begin
  Result := ExtractFileName(FPath);
end;

function Tq4File.GetName: string;
var
  fn : string;
begin
  fn     := ExtractFileName(FPath);
  Result := ChangeFileExt(fn, '');
end;

function Tq4File.GetPlatformPath: string;
begin
  Result := InternalNativePath(FPath);
end;

function Tq4File.GetCreationDate: string;
var
  dt : TDateTime;
begin
  Result := '';
  if (FileAge(InternalNativePath(FPath), dt)) then
    Result := InternalDateToStr(dt);
end;

function Tq4File.GetCreationTime: string;
var
  dt : TDateTime;
begin
  Result := '';
  if (FileAge(InternalNativePath(FPath), dt)) then
    Result := InternalTimeToStr(dt);
end;

function Tq4File.GetModificationDate: string;
var
  dt : TDateTime;
begin
  Result := '';
  if (FileAge(InternalNativePath(FPath), dt)) then
    Result := InternalDateToStr(dt);
end;

function Tq4File.GetModificationTime: string;
var
  dt : TDateTime;
begin
  Result := '';
  if (FileAge(InternalNativePath(FPath), dt)) then
    Result := InternalTimeToStr(dt);
end;

function Tq4File.GetHidden: boolean;
var
  attrs : Int64;
begin
  attrs := FileGetAttr(InternalNativePath(FPath));
  {$IFDEF WINDOWS}
  Result := (attrs and $00000002) <> 0; // FILE_ATTRIBUTE_HIDDEN
  {$ELSE}
  Result := (Length(GetName) > 0) and (GetName[1] = '.');
  {$ENDIF}
end;

function Tq4File.GetIsAlias: boolean;
begin
  {$IFDEF WINDOWS}
  Result := (FileGetAttr(InternalNativePath(FPath)) and $00000400) <> 0;
  // FILE_ATTRIBUTE_REPARSE_POINT = $400 (couvre symlinks et junctions)
  {$ELSE}
  Result := fpReadLink(PChar(InternalNativePath(FPath))) <> '';
  {$ENDIF}
end;

function Tq4File.GetIsWritable: boolean;
var
  attrs : Int64;
begin
  if (not FileExists(InternalNativePath(FPath))) then
  begin
    Result := False;
    Exit;
  end;
  attrs  := FileGetAttr(InternalNativePath(FPath));
  Result := (attrs and faReadOnly) = 0;
end;

function Tq4File.GetSize: double;
var
  fs : Int64;
begin
  fs     := FileSize(InternalNativePath(FPath));
  Result := fs;
end;

function Tq4File.GetParent: Tq4Folder;
var
  parentPath : string;
begin
  parentPath := ExtractFilePath(
                  ExcludeTrailingPathDelimiter(InternalNativePath(FPath)));
  Result     := Tq4Folder.Create(parentPath, fkPlatformPath);
end;

function Tq4File.GetOriginalFile: Tq4File;
begin
  // Sur les plateformes sans résolution de lien symbolique facile,
  // on retourne une référence à soi-même si pas un alias.
  Result := Tq4File.Create(FPath, FPathType);
end;

function Tq4File.GetIsFile: boolean;
begin
  Result := True;
end;

function Tq4File.GetIsFolder: boolean;
begin
  Result := False;
end;

function Tq4File.create_: boolean;
var
  dir : string;
  fs  : TFileStream;
begin
  Result := False;
  if (FileExists(InternalNativePath(FPath))) then
    Exit;
  dir := ExtractFilePath(InternalNativePath(FPath));
  if (dir <> '') then
    ForceDirectories(dir);
  try
    fs     := TFileStream.Create(InternalNativePath(FPath), fmCreate);
    fs.Free;
    Result := True;
  except
    Result := False;
  end;
end;

procedure Tq4File.delete;
begin
  if (FileExists(InternalNativePath(FPath))) then
    SysUtils.DeleteFile(InternalNativePath(FPath));
end;

function Tq4File.copyTo(_1_y_destinationFolder: Tq4Folder;
                        const _2_t_newName: string = '';
                        _3_e_overwrite: Int64 = 0): Tq4File;
var
  destName : string;
  destPath : string;
begin
  if (_2_t_newName <> '') then
    destName := _2_t_newName
  else
    destName := GetFullName;

  destPath := IncludeTrailingPathDelimiter(
                InternalNativePath(_1_y_destinationFolder.path)) + destName;

  if ((_3_e_overwrite = fkOverwrite) and FileExists(destPath)) then
    SysUtils.DeleteFile(destPath);

  FileUtil.CopyFile(InternalNativePath(FPath), destPath, False);
  Result := Tq4File.Create(destPath, fkPlatformPath);
end;

function Tq4File.moveTo(_1_y_destinationFolder: Tq4Folder;
                        const _2_t_newName: string = ''): Tq4File;
var
  destName : string;
  destPath : string;
begin
  if (_2_t_newName <> '') then
    destName := _2_t_newName
  else
    destName := GetFullName;

  destPath := IncludeTrailingPathDelimiter(
                InternalNativePath(_1_y_destinationFolder.path)) + destName;

  RenameFile(InternalNativePath(FPath), destPath);
  FPath  := destPath;
  Result := Self;
end;

function Tq4File.rename(const _1_t_newName: string): Tq4File;
var
  dir      : string;
  newPath  : string;
begin
  dir     := ExtractFilePath(InternalNativePath(FPath));
  newPath := dir + _1_t_newName;
  RenameFile(InternalNativePath(FPath), newPath);
  FPath  := newPath;
  Result := Self;
end;

function Tq4File.createAlias(_1_y_destinationFolder: Tq4Folder;
                             const _2_t_aliasName: string;
                             _3_e_aliasType: Int64 = fkAliasLink): Tq4File;
var
  aliasPath : string;
begin
  aliasPath := IncludeTrailingPathDelimiter(
                 InternalNativePath(_1_y_destinationFolder.path)) + _2_t_aliasName;
  {$IFDEF WINDOWS}
  // SYMBOLIC_LINK_FLAG_FILE = 0
  if (not CreateSymbolicLinkW(PWideChar(WideString(aliasPath)),
                             PWideChar(WideString(InternalNativePath(FPath))),
                             0)) then
    raise Exception.CreateFmt('Cannot create symbolic link: %s', [SysErrorMessage(GetLastError)]);
  {$ELSE}
  fpSymlink(PChar(InternalNativePath(FPath)), PChar(aliasPath));
  {$ENDIF}
  Result := Tq4File.Create(aliasPath, fkPlatformPath);
end;

function Tq4File.getContent: TBytes;
var
  fs  : TFileStream;
  buf : TBytes;
begin
  buf := nil;
  if (not FileExists(InternalNativePath(FPath))) then
  begin
    Result := buf;
    Exit;
  end;
  fs := TFileStream.Create(InternalNativePath(FPath), fmOpenRead or fmShareDenyNone);
  try
    SetLength(buf, fs.Size);
    if (fs.Size > 0) then
      fs.Read(buf[0], fs.Size);
  finally
    fs.Free;
  end;
  Result := buf;
end;

procedure Tq4File.setContent(const _1_by_content: TBytes);
var
  fs : TFileStream;
begin
  fs := TFileStream.Create(InternalNativePath(FPath), fmCreate);
  try
    if (Length(_1_by_content) > 0) then
      fs.Write(_1_by_content[0], Length(_1_by_content));
  finally
    fs.Free;
  end;
end;

function Tq4File.getText(const _1_t_charSetName: string = '';
                         _2_e_breakMode: Int64 = DocumentWithNativeLineEndings): string;
var
  sl     : TStringList;
  raw    : TBytes;
  enc    : TEncoding;
  cs     : string;
begin
  Result := '';
  if (not FileExists(InternalNativePath(FPath))) then
    Exit;

  cs := _1_t_charSetName;
  if (cs = '') then cs := 'UTF-8';

  // On utilise TStringList pour gérer les fins de ligne
  sl := TStringList.Create;
  try
    sl.LoadFromFile(InternalNativePath(FPath));
    Result := sl.Text;
  finally
    sl.Free;
  end;
end;

procedure Tq4File.setText(const _1_t_text: string;
                          const _2_t_charSetName: string = '';
                          _3_e_breakMode: Int64 = DocumentWithNativeLineEndings);
var
  sl : TStringList;
begin
  sl := TStringList.Create;
  try
    sl.Text := _1_t_text;
    sl.SaveToFile(InternalNativePath(FPath));
  finally
    sl.Free;
  end;
end;

function Tq4File.getIcon(_1_e_iconSize: Int64 = 0): Tq4Bitmap;
begin
  // Retourne un TBitmap vide — l'extraction d'icône est
  // platform-specific et sort du cadre de cette unité.
  Result := Tq4Bitmap.Create;
end;

function Tq4File.getAppInfo: T4DObject;
begin
  // Retourne un T4DObject vide — l'analyse des ressources
  // (.plist, .exe, macOS exec.) dépasse le cadre de cette unité.
  Result := T4DObject.Create;
end;

procedure Tq4File.setAppInfo(_1_o_info: T4DObject);
begin
  // Non implémenté dans ce wrapper — nécessite des API natives.
end;

function Tq4File.open(const _1_t_mode: string = 'read'): Tq4FileHandle;
begin
  Result := Tq4FileHandle.Create(Self, _1_t_mode);
end;

function Tq4File.open(_1_o_options: T4DObject): Tq4FileHandle;
var
  mode  : string;
  idx   : Int64;
begin
  mode := 'read';
  idx  := _1_o_options.IndexOf('mode');
  if (idx >= 0) then
    mode := VarToStr(_1_o_options.Data[idx]);
  Result := Tq4FileHandle.Create(Self, mode);
end;

// -------------------------------------------------------------------
//  Tq4Folder
// -------------------------------------------------------------------

constructor Tq4Folder.Create(const _1_t_aPath: string; _2_e_aPathType: Int64 = fkPosixPath);
begin
  inherited Create;
  FPath     := _1_t_aPath;
  FPathType := _2_e_aPathType;
end;

destructor Tq4Folder.Destroy;
begin
  inherited Destroy;
end;

function Tq4Folder.GetExists: boolean;
begin
  Result := DirectoryExists(InternalNativePath(FPath));
end;

function Tq4Folder.GetExtension: string;
begin
  // Les dossiers peuvent avoir une extension (ex: .app sur macOS)
  Result := ExtractFileExt(
              ExcludeTrailingPathDelimiter(FPath));
end;

function Tq4Folder.GetFullName: string;
begin
  Result := ExtractFileName(
              ExcludeTrailingPathDelimiter(FPath));
end;

function Tq4Folder.GetName: string;
var
  fn : string;
begin
  fn     := GetFullName;
  Result := ChangeFileExt(fn, '');
end;

function Tq4Folder.GetPlatformPath: string;
begin
  Result := InternalNativePath(FPath);
end;

function Tq4Folder.GetCreationDate: string;
var
  dt : TDateTime;
begin
  Result := '';
  if (FileAge(ExcludeTrailingPathDelimiter(InternalNativePath(FPath)), dt)) then
    Result := InternalDateToStr(dt);
end;

function Tq4Folder.GetCreationTime: string;
var
  dt : TDateTime;
begin
  Result := '';
  if (FileAge(ExcludeTrailingPathDelimiter(InternalNativePath(FPath)), dt)) then
    Result := InternalTimeToStr(dt);
end;

function Tq4Folder.GetModificationDate: string;
var
  dt : TDateTime;
begin
  Result := '';
  if (FileAge(ExcludeTrailingPathDelimiter(InternalNativePath(FPath)), dt)) then
    Result := InternalDateToStr(dt);
end;

function Tq4Folder.GetModificationTime: string;
var
  dt : TDateTime;
begin
  Result := '';
  if (FileAge(ExcludeTrailingPathDelimiter(InternalNativePath(FPath)), dt)) then
    Result := InternalTimeToStr(dt);
end;

function Tq4Folder.GetHidden: boolean;
begin
  {$IFDEF WINDOWS}
  Result := (FileGetAttr(InternalNativePath(FPath)) and $00000002) <> 0;
  {$ELSE}
  Result := (Length(GetName) > 0) and (GetName[1] = '.');
  {$ENDIF}
end;

function Tq4Folder.GetIsAlias: boolean;
begin
  {$IFDEF WINDOWS}
  Result := (FileGetAttr(InternalNativePath(FPath)) and $00000400) <> 0;
  {$ELSE}
  Result := fpReadLink(PChar(InternalNativePath(FPath))) <> '';
  {$ENDIF}
end;

function Tq4Folder.GetIsFile: boolean;
begin
  Result := False;
end;

function Tq4Folder.GetIsFolder: boolean;
begin
  Result := True;
end;

function Tq4Folder.GetIsPackage: boolean;
begin
  {$IFDEF DARWIN}
  // Sur macOS un dossier est un package s'il a l'extension .app, .bundle, etc.
  Result := DirectoryExists(InternalNativePath(FPath)) and
            (ExtractFileExt(ExcludeTrailingPathDelimiter(FPath)) <> '');
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function Tq4Folder.GetParent: Tq4Folder;
var
  parentPath : string;
begin
  parentPath := ExtractFilePath(
                  ExcludeTrailingPathDelimiter(InternalNativePath(FPath)));
  Result     := Tq4Folder.Create(parentPath, fkPlatformPath);
end;

function Tq4Folder.GetOriginal: Tq4Folder;
begin
  Result := Tq4Folder.Create(FPath, FPathType);
end;

function Tq4Folder.file_(const _1_t_relativePath: string): Tq4File;
var
  fullPath : string;
begin
  fullPath := IncludeTrailingPathDelimiter(InternalNativePath(FPath))
              + StringReplace(_1_t_relativePath, '/', PathDelim, [rfReplaceAll]);
  Result   := Tq4File.Create(fullPath, fkPlatformPath);
end;

function Tq4Folder.folder_(const _1_t_relativePath: string): Tq4Folder;
var
  fullPath : string;
begin
  fullPath := IncludeTrailingPathDelimiter(InternalNativePath(FPath))
              + StringReplace(_1_t_relativePath, '/', PathDelim, [rfReplaceAll]);
  Result   := Tq4Folder.Create(fullPath, fkPlatformPath);
end;

function Tq4Folder.files(_1_e_options: Int64 = 0): Tq4FileList;
var
  info      : TSearchRec;
  baseDir   : string;
  attrs     : Int64;
  showHidden: boolean;
begin
  Result     := Tq4FileList.Create(True);
  baseDir    := IncludeTrailingPathDelimiter(InternalNativePath(FPath));
  showHidden := (_1_e_options and fkIgnoreInvisibles) = 0;
  attrs      := faAnyFile and not faDirectory;

  if (FindFirst(baseDir + '*', attrs, info) = 0) then
  begin
    repeat
      if ((info.Name = '.') or (info.Name = '..')) then Continue;
      if ((info.Attr and faDirectory) <> 0) then Continue;
      if ((not showHidden) and InternalIsHidden(info.Name, info.Attr)) then Continue;
      Result.Add(Tq4File.Create(baseDir + info.Name, fkPlatformPath));
    until (FindNext(info) <> 0);
    SysUtils.FindClose(info);
  end;
end;

function Tq4Folder.folders(_1_e_options: Int64 = 0): Tq4FolderList;
var
  info       : TSearchRec;
  baseDir    : string;
  showHidden : boolean;
begin
  Result     := Tq4FolderList.Create(True);
  baseDir    := IncludeTrailingPathDelimiter(InternalNativePath(FPath));
  showHidden := (_1_e_options and fkIgnoreInvisibles) = 0;

  if (FindFirst(baseDir + '*', faDirectory, info) = 0) then
  begin
    repeat
      if ((info.Name = '.') or (info.Name = '..')) then Continue;
      if ((info.Attr and faDirectory) = 0) then Continue;
      if ((not showHidden) and InternalIsHidden(info.Name, info.Attr)) then Continue;
      Result.Add(Tq4Folder.Create(baseDir + info.Name, fkPlatformPath));
    until (FindNext(info) <> 0);
    SysUtils.FindClose(info);
  end;
end;

function Tq4Folder.create_: boolean;
begin
  if (DirectoryExists(InternalNativePath(FPath))) then
  begin
    Result := False;
    Exit;
  end;
  Result := ForceDirectories(InternalNativePath(FPath));
end;

procedure Tq4Folder.delete(_1_e_option: Int64 = 0);
begin
  if (DirectoryExists(InternalNativePath(FPath))) then
    RemoveDir(InternalNativePath(FPath));
end;

function Tq4Folder.copyTo(_1_y_destinationFolder: Tq4Folder;
                          const _2_t_newName: string = '';
                          _3_e_overwrite: Int64 = 0): Tq4Folder;
var
  destName : string;
  destPath : string;
  srcPath  : string;
begin
  if (_2_t_newName <> '') then
    destName := _2_t_newName
  else
    destName := GetName;

  destPath := IncludeTrailingPathDelimiter(
                InternalNativePath(_1_y_destinationFolder.path)) + destName;
  srcPath  := ExcludeTrailingPathDelimiter(InternalNativePath(FPath));

  // Créer le dossier destination si nécessaire
  if (not DirectoryExists(destPath)) then
    ForceDirectories(destPath);

  CopyDirTree(srcPath, destPath,
              [cffOverwriteFile, cffCreateDestDirectory]);
  Result := Tq4Folder.Create(destPath, fkPlatformPath);
end;

function Tq4Folder.moveTo(_1_y_destinationFolder: Tq4Folder;
                          const _2_t_newName: string = ''): Tq4Folder;
var
  destName : string;
  srcPath  : string;
  destPath : string;
begin
  if (_2_t_newName <> '') then
    destName := _2_t_newName
  else
    destName := GetName;

  srcPath  := ExcludeTrailingPathDelimiter(InternalNativePath(FPath));
  destPath := ExcludeTrailingPathDelimiter(
                IncludeTrailingPathDelimiter(
                  InternalNativePath(_1_y_destinationFolder.path)) + destName);

  {$IFDEF WINDOWS}
  if (not MoveFileExW(PWideChar(WideString(srcPath)),
                     PWideChar(WideString(destPath)),
                     2 or 8)) then
    raise Exception.CreateFmt(
      'Cannot move folder "%s" to "%s" : %s',
      [srcPath, destPath, SysErrorMessage(GetLastError)]);
  {$ELSE}
  if (fpRename(PChar(srcPath), PChar(destPath)) <> 0) then
    raise Exception.CreateFmt(
      'Cannot move folder "%s" to "%s"', [srcPath, destPath]);
  {$ENDIF}

  FPath  := destPath;
  Result := Self;
end;

function Tq4Folder.rename(const _1_t_newName: string): Tq4Folder;
var
  srcPath   : string;
  parentDir : string;
  newPath   : string;
begin
  srcPath   := ExcludeTrailingPathDelimiter(InternalNativePath(FPath));
  parentDir := ExtractFilePath(srcPath);
  newPath   := ExcludeTrailingPathDelimiter(
                 IncludeTrailingPathDelimiter(parentDir) + _1_t_newName);

  {$IFDEF WINDOWS}
  // MOVEFILE_REPLACE_EXISTING=1, MOVEFILE_COPY_ALLOWED=2, MOVEFILE_WRITE_THROUGH=8
  if (not MoveFileExW(PWideChar(WideString(srcPath)),
                     PWideChar(WideString(newPath)),
                     2 or 8)) then
    raise Exception.CreateFmt(
      'Cannot rename folder "%s" to "%s" : %s',
      [srcPath, newPath, SysErrorMessage(GetLastError)]);
  {$ELSE}
  if (fpRename(PChar(srcPath), PChar(newPath)) <> 0) then
    raise Exception.CreateFmt(
      'Cannot rename folder "%s" to "%s"', [srcPath, newPath]);
  {$ENDIF}

  FPath  := newPath;
  Result := Self;
end;

function Tq4Folder.createAlias(_1_y_destinationFolder: Tq4Folder;
                               const _2_t_aliasName: string;
                               _3_e_aliasType: Int64 = fkAliasLink): Tq4File;
var
  aliasPath : string;
begin
  aliasPath := IncludeTrailingPathDelimiter(
                 InternalNativePath(_1_y_destinationFolder.path)) + _2_t_aliasName;
  {$IFDEF WINDOWS}
  // SYMBOLIC_LINK_FLAG_DIRECTORY = 1
  if (not CreateSymbolicLinkW(PWideChar(WideString(aliasPath)),
                             PWideChar(WideString(InternalNativePath(FPath))),
                             1)) then
    raise Exception.CreateFmt('Cannot create symbolic link: %s', [SysErrorMessage(GetLastError)]);
  {$ELSE}
  fpSymlink(PChar(InternalNativePath(FPath)), PChar(aliasPath));
  {$ENDIF}
  Result := Tq4File.Create(aliasPath, fkPlatformPath);
end;

function Tq4Folder.getIcon(_1_e_iconSize: Int64 = 0): Tq4Bitmap;
begin
  Result := Tq4Bitmap.Create;
end;

// -------------------------------------------------------------------
//  Tq4ZipFile
// -------------------------------------------------------------------

constructor Tq4ZipFile.Create(const _1_t_aRelativePath: string);
begin
  inherited Create(_1_t_aRelativePath, fkPosixPath);
end;

function Tq4ZipFile.GetIsWritable: boolean;
begin
  Result := False;
end;

function Tq4ZipFile.getContent: TBytes;
begin
  Result := inherited getContent;
end;

function Tq4ZipFile.getText(const _1_t_charSetName: string = '';
                            _2_e_breakMode: Int64 = DocumentWithNativeLineEndings): string;
begin
  Result := inherited getText(_1_t_charSetName, _2_e_breakMode);
end;

function Tq4ZipFile.copyTo(_1_y_destinationFolder: Tq4Folder;
                           const _2_t_newName: string = '';
                           _3_e_overwrite: Int64 = 0): Tq4File;
begin
  Result := inherited copyTo(_1_y_destinationFolder, _2_t_newName, _3_e_overwrite);
end;

// -------------------------------------------------------------------
//  Tq4ZipFolder
// -------------------------------------------------------------------

constructor Tq4ZipFolder.Create(const _1_t_aRelativePath: string);
begin
  inherited Create(_1_t_aRelativePath, fkPosixPath);
end;

function Tq4ZipFolder.files(_1_e_options: Int64 = 0): Tq4ZipFileList;
var
  baseFiles : Tq4FileList;
  i         : Int64;
  zf        : Tq4ZipFile;
begin
  Result    := Tq4ZipFileList.Create(True);
  baseFiles := inherited files(_1_e_options);
  try
    for i := 0 to baseFiles.Count - 1 do
    begin
      zf := Tq4ZipFile.Create(baseFiles[i].path);
      Result.Add(zf);
    end;
  finally
    baseFiles.Free;
  end;
end;

function Tq4ZipFolder.folders(_1_e_options: Int64 = 0): Tq4ZipFolderList;
var
  baseFolders : Tq4FolderList;
  i           : Int64;
  zfld        : Tq4ZipFolder;
begin
  Result      := Tq4ZipFolderList.Create(True);
  baseFolders := inherited folders(_1_e_options);
  try
    for i := 0 to baseFolders.Count - 1 do
    begin
      zfld := Tq4ZipFolder.Create(baseFolders[i].path);
      Result.Add(zfld);
    end;
  finally
    baseFolders.Free;
  end;
end;

function Tq4ZipFolder.file_(const _1_t_relativePath: string): Tq4ZipFile;
var
  fullPath : string;
begin
  fullPath := IncludeTrailingPathDelimiter(InternalNativePath(FPath))
              + StringReplace(_1_t_relativePath, '/', PathDelim, [rfReplaceAll]);
  Result   := Tq4ZipFile.Create(fullPath);
end;

function Tq4ZipFolder.folder_(const _1_t_relativePath: string): Tq4ZipFolder;
var
  fullPath : string;
begin
  fullPath := IncludeTrailingPathDelimiter(InternalNativePath(FPath))
              + StringReplace(_1_t_relativePath, '/', PathDelim, [rfReplaceAll]);
  Result   := Tq4ZipFolder.Create(fullPath);
end;

function Tq4ZipFolder.copyTo(_1_y_destinationFolder: Tq4Folder;
                             const _2_t_newName: string = '';
                             _3_e_overwrite: Int64 = 0): Tq4Folder;
begin
  Result := inherited copyTo(_1_y_destinationFolder, _2_t_newName, _3_e_overwrite);
end;

// -------------------------------------------------------------------
//  Tq4ZipArchive
// -------------------------------------------------------------------

constructor Tq4ZipArchive.Create;
begin
  inherited Create;
  FRoot := nil;
end;

destructor Tq4ZipArchive.Destroy;
begin
  FRoot.Free;
  inherited Destroy;
end;

// -------------------------------------------------------------------
//  Fonctions globales — File_
// -------------------------------------------------------------------

function File_(const _1_t_path: string;
               _2_e_pathType: Int64 = fkPosixPath;
               const _3_t_star: string = ''): Tq4File;
begin
  Result := Tq4File.Create(_1_t_path, _2_e_pathType);
end;

function File_(_1_e_fileConstant: Int64;
               const _2_t_star: string = ''): Tq4File;
var
  resolvedPath : string;
begin
  // La résolution du chemin réel depuis une constante 4D
  // dépend de l'environnement d'exécution 4D.
  // Ici on retourne un objet avec un path symbolique.
  resolvedPath := '<4DFileConstant:' + IntToStr(_1_e_fileConstant) + '>';
  Result       := Tq4File.Create(resolvedPath, fkPosixPath);
end;

// -------------------------------------------------------------------
//  Fonctions globales — Folder_
// -------------------------------------------------------------------

function Folder_(const _1_t_path: string;
                 _2_e_pathType: Int64 = fkPosixPath;
                 const _3_t_star: string = ''): Tq4Folder;
begin
  Result := Tq4Folder.Create(_1_t_path, _2_e_pathType);
end;

function Folder_(_1_e_folderConstant: Int64;
                 const _2_t_star: string = ''): Tq4Folder;
var
  resolvedPath : string;
begin
  case _1_e_folderConstant of
    fkDesktopFolder   :
      resolvedPath := GetUserDir + 'Desktop';
    fkDocumentsFolder :
      resolvedPath := GetUserDir + 'Documents';
    fkHomeFolder      :
      resolvedPath := GetUserDir;
    fkSystemFolder    :
      {$IFDEF WINDOWS}
      resolvedPath := SysUtils.GetEnvironmentVariable('SystemRoot');
      {$ELSE}
      resolvedPath := '/';
      {$ENDIF}
    fkApplicationsFolder :
      {$IFDEF WINDOWS}
      resolvedPath := SysUtils.GetEnvironmentVariable('ProgramFiles');
      {$ELSE}
      resolvedPath := '/Applications';
      {$ENDIF}
  else
    // Pour les constantes 4D-spécifiques (DATA, PACKAGE, LOGS…),
    // on retourne un chemin symbolique.
    resolvedPath := '<4DFolderConstant:' + IntToStr(_1_e_folderConstant) + '>';
  end;
  Result := Tq4Folder.Create(resolvedPath, fkPlatformPath);
end;

// -------------------------------------------------------------------
//  Fonctions globales — ZIPCreateArchive
// -------------------------------------------------------------------

function InternalMakeStatusObject(_1_b_success: boolean;
                                  const _2_t_statusText: string;
                                  _3_e_statusCode: Int64): T4DObject;
var
  obj : T4DObject;
begin
  obj := T4DObject.Create;
  obj.Add('success',    _1_b_success);
  obj.Add('statusText', _2_t_statusText);
  obj.Add('status',     _3_e_statusCode);
  Result := obj;
end;

function ZIPCreateArchive(_1_y_fileToZip: Tq4File;
                          _2_y_destinationFile: Tq4File): T4DObject;
var
  zipper   : TZipper;
  destPath : string;
begin
  destPath := InternalNativePath(_2_y_destinationFile.path);
  zipper   := TZipper.Create;
  try
    zipper.FileName := destPath;
    zipper.Entries.AddFileEntry(
      InternalNativePath(_1_y_fileToZip.path),
      _1_y_fileToZip.fullName);
    zipper.ZipAllFiles;
    Result := InternalMakeStatusObject(True, '', 0);
  except
    on e: Exception do
      Result := InternalMakeStatusObject(False,
                  'Cannot create ZIP archive: ' + e.Message, 1);
  end;
  zipper.Free;
end;

function ZIPCreateArchive(_1_y_folderToZip: Tq4Folder;
                          _2_y_destinationFile: Tq4File;
                          _3_e_options: Int64 = 0): T4DObject;
var
  zipper   : TZipper;
  destPath : string;
  srcPath  : string;
  prefix   : string;
begin
  destPath := InternalNativePath(_2_y_destinationFile.path);
  srcPath  := InternalNativePath(_1_y_folderToZip.path);
  zipper   := TZipper.Create;
  try
    zipper.FileName := destPath;
    if ((_3_e_options and ZIPWithoutEnclosingFolder) <> 0) then
      prefix := ''
    else
      prefix := _1_y_folderToZip.name + '/';
    InternalAddDirToZip(zipper, srcPath, prefix);
    zipper.ZipAllFiles;
    Result := InternalMakeStatusObject(True, '', 0);
  except
    on e: Exception do
      Result := InternalMakeStatusObject(False,
                  'Cannot create ZIP archive: ' + e.Message, 1);
  end;
  zipper.Free;
end;

function ZIPCreateArchive(_1_y_zipStructure: Tq4ZipStructure;
                          _2_y_destinationFile: Tq4File): T4DObject;
var
  zipper    : TZipper;
  destPath  : string;
  i         : Int64;
  item      : Tq4ZipStructureFileItem;
  srcPath   : string;
  entryName : string;
begin
  destPath := InternalNativePath(_2_y_destinationFile.path);
  zipper   := TZipper.Create;
  try
    zipper.FileName := destPath;

    for i := 0 to _1_y_zipStructure.files.Count - 1 do
    begin
      item := _1_y_zipStructure.files[i];

      if (item.source is Tq4File) then
      begin
        srcPath   := InternalNativePath(Tq4File(item.source).path);
        if (item.destination <> '') then
          entryName := item.destination
        else
          entryName := Tq4File(item.source).fullName;
        zipper.Entries.AddFileEntry(srcPath, entryName);
      end
      else if (item.source is Tq4Folder) then
      begin
        srcPath := InternalNativePath(Tq4Folder(item.source).path);
        if (item.destination <> '') then
          InternalAddDirToZip(zipper, srcPath, item.destination)
        else
          InternalAddDirToZip(zipper, srcPath,
            Tq4Folder(item.source).name + '/');
      end;
    end;

    zipper.ZipAllFiles;

    // Appel du callback de progression avec 100% si défini
    if (Assigned(_1_y_zipStructure.callback)) then
      _1_y_zipStructure.callback(100);

    Result := InternalMakeStatusObject(True, '', 0);
  except
    on e: Exception do
      Result := InternalMakeStatusObject(False,
                  'Cannot create ZIP archive: ' + e.Message, 1);
  end;
  zipper.Free;
end;

// -------------------------------------------------------------------
//  Fonctions globales — ZIPReadArchive
// -------------------------------------------------------------------

function ZIPReadArchive(_1_y_zipFile: Tq4File;
                        const _2_t_password: string = ''): Tq4ZipArchive;
var
  unzipper  : TUnZipper;
  tempDir   : string;
  archive   : Tq4ZipArchive;
begin
  archive := Tq4ZipArchive.Create;
  tempDir := GetTempDir + 'q4zip_' + IntToStr(GetTickCount64) + PathDelim;
  ForceDirectories(tempDir);

  unzipper := TUnZipper.Create;
  try
    unzipper.FileName  := InternalNativePath(_1_y_zipFile.path);
    unzipper.OutputPath := tempDir;
    unzipper.UnZipAllFiles;
    archive.FRoot := Tq4ZipFolder.Create(tempDir);
  except
    on e: Exception do
    begin
      // En cas d'erreur, FRoot reste nil
    end;
  end;
  unzipper.Free;

  Result := archive;
end;

end.
