Unit q4systemDocument;

{$mode objfpc}{$H+}

{
q4systemDocument
version du 2026/05/16-01

Mapping 4D → q4systemDocument -> statut
Command Number 4D,   4D Command,                         q4 API,                            Statut
--------------------------------------------------------------------------------------------------
265,                 Append document,                    appendDocument,                    Partial,
267,                 CLOSE DOCUMENT,                     closeDocument,                     Partial,
1107,                Convert path POSIX to system,       convertPathPosixToSystem,          Partial,
1106,                Convert path system to POSIX,       convertPathSystemToPosix,          Partial,
541,                 COPY DOCUMENT,                      copyDocument,                      Partial,
694,                 CREATE ALIAS,                       createAlias,                       Partial,
266,                 Create document,                    createDocument,                    Partial,
475,                 CREATE FOLDER,                      createFolder,                      Partial,
159,                 DELETE DOCUMENT,                    deleteDocument,                    Partial,
693,                 DELETE FOLDER,                      deleteFolder,                      Partial,
474,                 DOCUMENT LIST,                      documentList,                      Partial,
1236,                Document to text,                   documentToText,                    Partial,
473,                 FOLDER LIST,                        folderList,                        Partial,
700,                 GET DOCUMENT ICON,                  getDocumentIcon,                   Not supported,
481,                 Get document position,              getDocumentPosition,               Partial,
477,                 GET DOCUMENT PROPERTIES,            getDocumentProperties,             Partial,
479,                 Get document size,                  getDocumentSize,                   Partial,
1105,                Localized document path,            localizedDocumentPath,             Partial,
540,                 MOVE DOCUMENT,                      moveDocument,                      Partial,
1548,                Object to path,                     objectToPath,                      Partial,
264,                 Open document,                      openDocument,                      Partial,
1547,                Path to object,                     pathToObject,                      Partial,
695,                 RESOLVE ALIAS,                      resolveAlias,                      Partial,
905,                 Select document,                    selectDocument,                    Partial,
670,                 Select folder,                      selectFolder,                      Partial,
482,                 SET DOCUMENT POSITION,              setDocumentPosition,               Partial,
478,                 SET DOCUMENT PROPERTIES,            setDocumentProperties,             Partial,
480,                 SET DOCUMENT SIZE,                  setDocumentSize,                   Partial,
922,                 SHOW ON DISK,                       showOnDisk,                        Partial,
476,                 Test path name,                     testPathName,                      Partial,
1237,                TEXT TO DOCUMENT,                   textToDocument,                    Partial,
472,                 VOLUME ATTRIBUTES,                  volumeAttributes,                  Partial,
471,                 VOLUME LIST,                        volumeList,                        Partial,

Doc: https://developer.4d.com/docs/21/commands/theme/System-Documents

Responsabilités :
- implémenter un premier socle FreePascal/Lazarus pour les commandes 4D du thème System Documents
- gérer les références de documents ouverts utilisées par Open document, Create document et Append document
- utiliser les variables runtime partagées q4coreLanguage.OK et q4coreLanguage.Document
- ne pas redéclarer OK/Document dans cette unité
- fournir les helpers de conversion de chemins et de lecture/écriture de documents texte

Conventions :
- Tq4Time = string au format "hh:mm:ss" pour l'heure réelle ou la référence de document ouvert
- Tq4Date = string au format "yyyy-mm-dd"
- TPathObject = record décrivant les composantes d'un chemin

Notes de portage :
- Les fonctions openDocument, createDocument et appendDocument renvoient une Tq4Time sous la forme
  "00:00:01", "00:00:02", ... mappée en interne sur un TFileStream.
- closeDocument libère le slot ; la prochaine ouverture réutilise le plus petit slot libre.
- Les corrections fonctionnelles 4D strictes sont volontairement reportées à une étape suivante.
- Plateformes actuellement prévues par cette unité : Windows et macOS (Darwin).
}

Interface

Uses
  SysUtils, Classes, FileUtil, LazFileUtils, LCLIntf, Graphics, Dialogs,
  q4coreLanguage
  {$IFDEF WINDOWS}, Windows{$ENDIF}
  {$IFDEF DARWIN}, BaseUnix, Unix{$ENDIF};

  // ---------------------------------------------------------------------------
  // Types publics
  // ---------------------------------------------------------------------------

Type
  Tq4Time = string;   // "hh:mm:ss"
  Tq4Date = string;   // "yyyy-mm-dd"

  TPathObject = Record
    parentFolder: string;  // répertoire parent (se termine par séparateur)
    Name: string;  // nom sans extension
    extension: string;  // extension avec le "." (ex : ".txt") ou ""
    isFolder: boolean; // True si le chemin désigne un dossier
  End;

  // ---------------------------------------------------------------------------
  // Variables runtime / globales publiques
  // ---------------------------------------------------------------------------

  // 4D: OK et Document sont portés par q4coreLanguage
  //      sous forme de variables runtime partagées par thread.

  // ---------------------------------------------------------------------------
  // Constantes publiques
  // ---------------------------------------------------------------------------

Const
  // Open document mode
  q4ReadAndWrite = 0;
  q4WriteMode = 1;
  q4ReadMode = 2;
  q4GetPathname = 3;

  // Test path name
  q4IsADocument = 1;
  q4IsAFolder = 0;

  // Delete folder
  q4DeleteOnlyIfEmpty = 0;
  q4DeleteWithContents = 1;

  // Document list options
  q4RecursiveParsing = 1;
  q4AbsolutePath = 2;
  q4PosixPath = 4;
  q4IgnoreInvisible = 8;

  // Document to text / Text to document break modes
  q4DocumentUnchanged = 0;
  q4DocumentNativeFormat = 1;
  q4DocumentWithCRLF = 2;
  q4DocumentWithCR = 3;
  q4DocumentWithLF = 4;

  // Path to object / Object to path path types
  q4PathIsSystem = 0;
  q4PathIsPOSIX = 1;

  // Set document position anchors
  q4AnchorBeginning = 1;
  q4AnchorEnd = 2;
  q4AnchorCurrent = 3;

  // Select document options
  q4MultipleFiles = 1;
  q4PackageOpen = 2;
  q4PackageSelection = 4;
  q4AllowAliasFiles = 8;
  q4UseSheetWindow = 16;
  q4FileNameEntry = 32;

  // ---------------------------------------------------------------------------
  // Déclarations publiques
  // ---------------------------------------------------------------------------

Function appendDocument( Const _1_t_document: string; Const _2_t_fileType: string = ''): Tq4Time;

Procedure closeDocument( Const _1_t_docRef: Tq4Time);

Function convertPathPosixToSystem( Const _1_t_posixPath: string; Const _2_t_star: string = ''): string;

Function convertPathSystemToPosix( Const _1_t_systemPath: string; Const _2_t_star: string = ''): string;

Procedure copyDocument( Const _1_t_sourceName: string; Const _2_t_destinationName: string; Const _3_t_newName: string = ''; Const _4_t_star: string = '');

Procedure createAlias( Const _1_t_targetPath: string; Const _2_t_aliasPath: string);

Function createDocument( Const _1_t_document: string; Const _2_t_fileType: string = ''): Tq4Time;

Procedure createFolder( Const _1_t_folderPath: string; Const _2_t_star: string = '');

Procedure deleteDocument( Const _1_t_document: string);

Procedure deleteFolder( Const _1_t_folder: string; Const _2_e_deleteOption: int64 = q4DeleteOnlyIfEmpty);

Procedure documentList( Const _1_t_pathname: string; Var _2_tt_documents: Array Of string; Var _3_e_count: int64; Const _4_e_options: int64 = 0);

Function documentToText( Const _1_t_fileName: string; Const _2_t_charSet: string = ''; Const _3_e_breakMode: int64 = q4DocumentNativeFormat): string;

Procedure folderList( Const _1_t_pathname: string; Var _2_tt_directories: Array Of string; Var _3_e_count: int64);

Procedure getDocumentIcon( Const _1_t_docPath: string; Var _2_o_icon: Graphics.TBitmap; Const _3_e_size: int64 = 0);

Function getDocumentPosition( Const _1_t_docRef: Tq4Time): double;

Procedure getDocumentProperties( Const _1_t_document: string; Var _2_b_locked: boolean; Var _3_b_invisible: boolean; Var _4_d_createdOn: Tq4Date;
  Var _5_t_createdAt: Tq4Time; Var _6_d_modifiedOn: Tq4Date; Var _7_t_modifiedAt: Tq4Time);

// Si document est de la forme "hh:mm:ss" => handle ouvert, sinon chemin d'accès
Function getDocumentSize( Const _1_t_document: string; Const _2_t_star: string = ''): double;

Function localizedDocumentPath( Const _1_t_relativePath: string): string;

Procedure moveDocument( Const _1_t_srcPathname: string; Const _2_t_dstPathname: string);

Function objectToPath( Const _1_o_pathObject: TPathObject): string;

Function openDocument( Const _1_t_document: string; Const _2_t_fileType: string = ''; Const _3_e_mode: int64 = q4ReadAndWrite): Tq4Time;

Function pathToObject( Const _1_t_path: string; Const _2_e_pathType: int64 = q4PathIsSystem): TPathObject;

Procedure resolveAlias( Const _1_t_aliasPath: string; Var _2_t_targetPath: string);

Function selectDocument( Const _1_t_directory: string; Const _2_t_fileTypes: string; Const _3_t_title: string; Const _4_e_options: int64;
  Var _5_tt_selected: Array Of string; Var _6_e_selectedCount: int64): string;

Function selectFolder( Const _1_t_message: string = ''; Const _2_t_defaultPath: string = ''; Const _3_e_options: int64 = 0): string;

Procedure setDocumentPosition( Const _1_t_docRef: Tq4Time; Const _2_r_offset: double; Const _3_e_anchor: int64 = q4AnchorBeginning);

Procedure setDocumentProperties( Const _1_t_document: string; Const _2_b_locked: boolean; Const _3_b_invisible: boolean; Const _4_d_createdOn: Tq4Date;
  Const _5_t_createdAt: Tq4Time; Const _6_d_modifiedOn: Tq4Date; Const _7_t_modifiedAt: Tq4Time);

Procedure setDocumentSize( Const _1_t_docRef: Tq4Time; Const _2_r_size: double);

Procedure showOnDisk( Const _1_t_pathname: string; Const _2_t_star: string = '');

Function testPathName( Const _1_t_pathname: string): int64;

Procedure textToDocument( Const _1_t_fileName: string; Const _2_t_text: string; Const _3_t_charSet: string = 'UTF-8'; Const _4_e_breakMode: int64 = q4DocumentNativeFormat);

Procedure volumeAttributes( Const _1_t_volume: string; Var _2_r_size: double; Var _3_r_used: double; Var _4_r_free: double);

Procedure volumeList( Var _1_tt_volumes: Array Of string; Var _2_e_count: int64);

Implementation

// ===========================================================================
// Gestion interne des références de documents ouverts
// ===========================================================================

Const
  MAX_OPEN_DOCS = 86400;

Type
  TDocEntry = Record
    stream: TFileStream;
    filePath: string;
    inUse: boolean;
  End;

Var
  gDocTable: Array[1..MAX_OPEN_DOCS] Of TDocEntry;
  gDocInit:  boolean = False;

Procedure initDocTable;
  Var
    _e_index: int64;
  Begin
    If ( gDocInit) Then Exit;
    For _e_index := 1 To MAX_OPEN_DOCS Do Begin
      gDocTable[_e_index].stream := nil;
      gDocTable[_e_index].filePath := '';
      gDocTable[_e_index].inUse := False;
    End;
    gDocInit := True;
  End;

Function slotToRef( _1_e_slot: int64): Tq4Time;
  Var
    _e_hour, _e_minute, _e_second: int64;
  Begin
    Dec( _1_e_slot);
    _e_hour := _1_e_slot div 3600;
    _e_minute := ( _1_e_slot mod 3600) div 60;
    _e_second := _1_e_slot mod 60;
    Result := Format( '%.2d:%.2d:%.2d', [_e_hour, _e_minute, _e_second]);
  End;

Function refToSlot( Const _1_t_ref: Tq4Time): int64;
  Var
    _e_hour, _e_minute, _e_second: int64;
  Begin
    If ( Length( _1_t_ref) < 8) Then Begin
      Result := 0;
      Exit;
    End;
    _e_hour := StrToIntDef( Copy( _1_t_ref, 1, 2), 0);
    _e_minute := StrToIntDef( Copy( _1_t_ref, 4, 2), 0);
    _e_second := StrToIntDef( Copy( _1_t_ref, 7, 2), 0);
    Result := _e_hour * 3600 + _e_minute * 60 + _e_second + 1;
  End;

{ Retourne True si la chaîne est de la forme "hh:mm:ss" (référence document) }
Function isDocRef( Const _1_t_value: string): boolean;
  Begin
    Result := ( Length( _1_t_value) = 8) and ( _1_t_value[3] = ':') and ( _1_t_value[6] = ':') and ( _1_t_value[1] in ['0'..'9']) and ( _1_t_value[2] in ['0'..'9']) and
      ( _1_t_value[4] in ['0'..'9']) and ( _1_t_value[5] in ['0'..'9']) and ( _1_t_value[7] in ['0'..'9']) and ( _1_t_value[8] in ['0'..'9']);
  End;

Function allocSlot: int64;
  Var
    _e_index: int64;
  Begin
    initDocTable;
    Result := 0;
    For _e_index := 1 To MAX_OPEN_DOCS Do If ( not gDocTable[_e_index].inUse) Then Begin
        Result := _e_index;
        Exit;
      End;
  End;

Function streamFromRef( Const _1_t_ref: Tq4Time): TFileStream;
  Var
    _e_slot: int64;
  Begin
    _e_slot := refToSlot( _1_t_ref);
    Result := nil;
    If ( ( _e_slot < 1) or ( _e_slot > MAX_OPEN_DOCS)) Then Exit;
    If ( not gDocTable[_e_slot].inUse) Then Exit;
    Result := gDocTable[_e_slot].stream;
  End;

// ===========================================================================
// Helpers internes
// ===========================================================================

Function applyBreakMode( Const _1_t_text: string; _2_e_breakMode: int64): string;
  Var
    _t_normalizedText: string;
  Begin
    _t_normalizedText := StringReplace( _1_t_text, #13#10, #10, [rfReplaceAll]);
    _t_normalizedText := StringReplace( _t_normalizedText, #13, #10, [rfReplaceAll]);
    Case _2_e_breakMode Of
      q4DocumentUnchanged: Result := _1_t_text;
      q4DocumentNativeFormat:{$IFDEF WINDOWS}
      Result := StringReplace(_t_normalizedText, #10, #13#10, [rfReplaceAll]);
{$ELSE}
        Result := _t_normalizedText;
    {$ENDIF}
      q4DocumentWithCRLF: Result := StringReplace( _t_normalizedText, #10, #13#10, [rfReplaceAll]);
      q4DocumentWithCR: Result := StringReplace( _t_normalizedText, #10, #13, [rfReplaceAll]);
      q4DocumentWithLF: Result := _t_normalizedText;
      Else Result := _t_normalizedText;
    End;
  End;

{ Percent-encoding (pour ConvertPathSystemToPosix avec *) }
Function percentEncode( Const _1_t_value: string): string;
  Var
    _e_index: int64;
    _c_char:  char;
  Begin
    Result := '';
    For _e_index := 1 To Length( _1_t_value) Do Begin
      _c_char := _1_t_value[_e_index];
      If ( _c_char in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~', '/']) Then Result := Result + _c_char
      Else
        Result := Result + '%' + IntToHex( Ord( _c_char), 2);
    End;
  End;

{ Percent-decoding (pour ConvertPathPosixToSystem avec *) }
Function percentDecode( Const _1_t_value: string): string;
  Var
    _e_index: int64;
    _c_char:  char;
    _t_hex:   string;
  Begin
    Result := '';
    _e_index := 1;
    While ( _e_index <= Length( _1_t_value)) Do Begin
      _c_char := _1_t_value[_e_index];
      If ( ( _c_char = '%') and ( _e_index + 2 <= Length( _1_t_value))) Then Begin
        _t_hex := Copy( _1_t_value, _e_index + 1, 2);
        Result := Result + Chr( StrToIntDef( '$' + _t_hex, Ord( _c_char)));
        Inc( _e_index, 3);
      End Else Begin
        Result := Result + _c_char;
        Inc( _e_index);
      End;
    End;
  End;

Procedure collectFiles( Const _1_t_baseDir, _2_t_currentDir: string; _3_e_options: int64; Var _4_o_list: TStringList);
  Var
    _rec_searchRec:  TSearchRec;
    _t_fullPath:     string;
    _t_relativePath: string;
    _b_useAbsolutePath: boolean;
    _b_usePosixPath: boolean;
  Begin
    _b_useAbsolutePath := ( _3_e_options and q4AbsolutePath) <> 0;
    _b_usePosixPath := ( _3_e_options and q4PosixPath) <> 0;
    If ( SysUtils.FindFirst( IncludeTrailingPathDelimiter( _2_t_currentDir) + '*', faAnyFile, _rec_searchRec) = 0) Then Try
      Repeat
        If ( ( _rec_searchRec.Name = '.') or ( _rec_searchRec.Name = '..')) Then Continue;
        _t_fullPath := IncludeTrailingPathDelimiter( _2_t_currentDir) + _rec_searchRec.Name;
        If ( ( _rec_searchRec.Attr and faDirectory) <> 0) Then Begin
          If ( ( _3_e_options and q4RecursiveParsing) <> 0) Then collectFiles( _1_t_baseDir, _t_fullPath, _3_e_options, _4_o_list);
        End Else Begin
          If ( ( _3_e_options and q4IgnoreInvisible) <> 0) Then{$IFDEF DARWIN}
    {$ENDIF}
            {$IFDEF WINDOWS}
    {$ENDIF}
          ;
          If ( _b_useAbsolutePath) Then _t_relativePath := _t_fullPath
          Else
            _t_relativePath := Copy( _t_fullPath, Length( _1_t_baseDir) + 1, MaxInt);
          If ( _b_usePosixPath) Then _t_relativePath := StringReplace( _t_relativePath, PathDelim, '/', [rfReplaceAll]);
          _4_o_list.Add( _t_relativePath);
        End;
      Until ( SysUtils.FindNext( _rec_searchRec) <> 0);
    Finally
      SysUtils.FindClose( _rec_searchRec);
    End;
  End;

Procedure collectFolders( Const _1_t_dir: string; Var _2_o_list: TStringList);
  Var
    _rec_searchRec: TSearchRec;
  Begin
    If ( SysUtils.FindFirst( IncludeTrailingPathDelimiter( _1_t_dir) + '*', faDirectory, _rec_searchRec) = 0) Then Try
      Repeat
        If ( ( _rec_searchRec.Name = '.') or ( _rec_searchRec.Name = '..')) Then Continue;
        If ( ( _rec_searchRec.Attr and faDirectory) <> 0) Then _2_o_list.Add( _rec_searchRec.Name);
      Until ( SysUtils.FindNext( _rec_searchRec) <> 0);
    Finally
      SysUtils.FindClose( _rec_searchRec);
    End;
  End;

{ Retourne la date de création d'un fichier.
  Windows : utilise SR.FindData.ftCreationTime
  macOS   : utilise st_birthtimespec (inspiré de nouveau_2.txt)  }
Function getFileCreationDate( Const _1_t_fileName: string): TDateTime;
  Var
    _e_fileAge: longint;
    {$IFDEF WINDOWS}
  _rec_searchRec : TSearchRec;
  _rec_systemTime : TSystemTime;
{$ENDIF}
    {$IFDEF DARWIN}
  _rec_info : Stat;
{$ENDIF}
  Begin
    Result := 0;
    _e_fileAge := -1;

    {$IFDEF WINDOWS}
  if (SysUtils.FindFirst(_1_t_fileName, faAnyFile, _rec_searchRec) = 0) then
  try
    FileTimeToSystemTime(_rec_searchRec.FindData.ftCreationTime, _rec_systemTime);
    Result := SystemTimeToDateTime(_rec_systemTime);
  finally
    SysUtils.FindClose(_rec_searchRec);
  end;
  Exit;
{$ENDIF}

    {$IFDEF DARWIN}
  if (fpStat(PChar(_1_t_fileName), _rec_info) = 0) then
    Result := UnixToDateTime(_rec_info.st_birthtimespec.tv_sec)
            + (_rec_info.st_birthtimespec.tv_nsec / 1e9) / SecsPerDay;
  Exit;
{$ENDIF}

    {$IFNDEF WINDOWS}
    {$IFNDEF DARWIN}
    _e_fileAge := FileAge( _1_t_fileName);
    If ( _e_fileAge <> -1) Then Result := FileDateToDateTime( _e_fileAge);
    {$ENDIF}
    {$ENDIF}
  End;

// ===========================================================================
// Implémentations
// ===========================================================================

Function openDocument( Const _1_t_document: string; Const _2_t_fileType: string; Const _3_e_mode: int64): Tq4Time;
  Var
    _e_slot:     int64;
    _t_filePath: string;
    _w_fileMode: word;
    _o_fileStream: TFileStream;
  Begin
    initDocTable;
    Result := '00:00:00';
    q4coreLanguage.OK := 0;

    If ( _3_e_mode = q4GetPathname) Then Begin
      q4coreLanguage.Document := ExpandFileName( _1_t_document);
      q4coreLanguage.OK := 1;
      Exit;
    End;

    _t_filePath := ExpandFileName( _1_t_document);
    q4coreLanguage.Document := _t_filePath;
    If ( not FileExists( _t_filePath)) Then Exit;

    Case _3_e_mode Of
      q4ReadAndWrite: _w_fileMode := fmOpenReadWrite or fmShareDenyNone;
      q4WriteMode: _w_fileMode := fmOpenWrite or fmShareDenyWrite;
      q4ReadMode: _w_fileMode := fmOpenRead or fmShareDenyNone;
      Else _w_fileMode := fmOpenReadWrite or fmShareDenyNone;
    End;

    Try
      _o_fileStream := TFileStream.Create( _t_filePath, _w_fileMode);
    Except
      q4coreLanguage.OK := 0;
      Exit;
    End;
    _o_fileStream.Position := 0;

    _e_slot := allocSlot;
    If ( _e_slot = 0) Then Begin
      _o_fileStream.Free;
      q4coreLanguage.OK := 0;
      Exit;
    End;

    gDocTable[_e_slot].stream := _o_fileStream;
    gDocTable[_e_slot].filePath := _t_filePath;
    gDocTable[_e_slot].inUse := True;
    q4coreLanguage.OK := 1;
    Result := slotToRef( _e_slot);
  End;

Function createDocument( Const _1_t_document: string; Const _2_t_fileType: string): Tq4Time;
  Var
    _e_slot:     int64;
    _t_filePath: string;
    _o_fileStream: TFileStream;
  Begin
    initDocTable;
    Result := '00:00:00';
    q4coreLanguage.OK := 0;
    _t_filePath := ExpandFileName( _1_t_document);
    q4coreLanguage.Document := _t_filePath;
    Try
      _o_fileStream := TFileStream.Create( _t_filePath, fmCreate);
    Except
      q4coreLanguage.OK := 0;
      Exit;
    End;
    _e_slot := allocSlot;
    If ( _e_slot = 0) Then Begin
      _o_fileStream.Free;
      q4coreLanguage.OK := 0;
      Exit;
    End;
    gDocTable[_e_slot].stream := _o_fileStream;
    gDocTable[_e_slot].filePath := _t_filePath;
    gDocTable[_e_slot].inUse := True;
    q4coreLanguage.OK := 1;
    Result := slotToRef( _e_slot);
  End;

Function appendDocument( Const _1_t_document: string; Const _2_t_fileType: string): Tq4Time;
  Var
    _e_slot:     int64;
    _t_filePath: string;
    _o_fileStream: TFileStream;
  Begin
    initDocTable;
    Result := '00:00:00';
    q4coreLanguage.OK := 0;
    _t_filePath := ExpandFileName( _1_t_document);
    q4coreLanguage.Document := _t_filePath;

    If ( not FileExists( _t_filePath)) Then Try
      _o_fileStream := TFileStream.Create( _t_filePath, fmCreate);
      _o_fileStream.Free;
    Except
      q4coreLanguage.OK := 0;
      Exit;
    End;

    Try
      _o_fileStream := TFileStream.Create( _t_filePath, fmOpenReadWrite or fmShareDenyNone);
    Except
      q4coreLanguage.OK := 0;
      Exit;
    End;
    _o_fileStream.Seek( 0, soFromEnd);

    _e_slot := allocSlot;
    If ( _e_slot = 0) Then Begin
      _o_fileStream.Free;
      q4coreLanguage.OK := 0;
      Exit;
    End;
    gDocTable[_e_slot].stream := _o_fileStream;
    gDocTable[_e_slot].filePath := _t_filePath;
    gDocTable[_e_slot].inUse := True;
    q4coreLanguage.OK := 1;
    Result := slotToRef( _e_slot);
  End;

Procedure closeDocument( Const _1_t_docRef: Tq4Time);
  Var
    _e_slot: int64;
  Begin
    _e_slot := refToSlot( _1_t_docRef);
    If ( ( _e_slot < 1) or ( _e_slot > MAX_OPEN_DOCS)) Then Exit;
    If ( not gDocTable[_e_slot].inUse) Then Exit;
    FreeAndNil( gDocTable[_e_slot].stream);
    gDocTable[_e_slot].filePath := '';
    gDocTable[_e_slot].inUse := False;
  End;

Function convertPathPosixToSystem( Const _1_t_posixPath: string; Const _2_t_star: string): string;
  Var
    _t_path: string;
  Begin
    _t_path := _1_t_posixPath;
    If ( _2_t_star = '*') Then _t_path := percentDecode( _t_path);
    {$IFDEF WINDOWS}
  if ((Length(_t_path) >= 3) and (_t_path[1] = '/') and (_t_path[3] = '/')) then
    Result := UpperCase(_t_path[2]) + ':' + StringReplace(Copy(_t_path, 3, MaxInt), '/', '\', [rfReplaceAll])
  else
    Result := StringReplace(_t_path, '/', '\', [rfReplaceAll]);
{$ELSE}
    Result := _t_path;
    {$ENDIF}
  End;

Function convertPathSystemToPosix( Const _1_t_systemPath: string; Const _2_t_star: string): string;
  Begin
    {$IFDEF WINDOWS}
  Result := StringReplace(_1_t_systemPath, '\', '/', [rfReplaceAll]);
{$ELSE}
    Result := _1_t_systemPath;
    {$ENDIF}
    If ( _2_t_star = '*') Then Result := percentEncode( Result);
  End;

Procedure copyDocument( Const _1_t_sourceName: string; Const _2_t_destinationName: string; Const _3_t_newName: string; Const _4_t_star: string);
  Var
    _t_sourcePath: string;
    _t_destinationPath: string;
    _t_finalName: string;
  Begin
    q4coreLanguage.OK := 0;
    _t_sourcePath := ExpandFileName( _1_t_sourceName);

    If ( ( Length( _2_t_destinationName) > 0) and ( _2_t_destinationName[Length( _2_t_destinationName)] = PathDelim)) Then Begin
      If ( _3_t_newName <> '') Then _t_finalName := _3_t_newName
      Else
        _t_finalName := ExtractFileName( _t_sourcePath);
      _t_destinationPath := IncludeTrailingPathDelimiter( ExpandFileName( _2_t_destinationName)) + _t_finalName;
    End Else Begin
      _t_destinationPath := ExpandFileName( _2_t_destinationName);
      If ( _3_t_newName <> '') Then _t_destinationPath := IncludeTrailingPathDelimiter( ExtractFilePath( _t_destinationPath)) + _3_t_newName;
    End;

    If ( FileExists( _t_destinationPath) or DirectoryExists( _t_destinationPath)) Then Begin
      If ( _4_t_star <> '*') Then Exit;
      If ( FileExists( _t_destinationPath)) Then SysUtils.DeleteFile( _t_destinationPath);
    End;

    If ( DirectoryExists( _t_sourcePath)) Then Try
      CopyDirTree( _t_sourcePath, _t_destinationPath, [cffOverwriteFile]);
      q4coreLanguage.OK := 1;
    Except
      q4coreLanguage.OK := 0;
    End Else
    Try
      If ( FileUtil.CopyFile( _t_sourcePath, _t_destinationPath)) Then q4coreLanguage.OK := 1
      Else
        q4coreLanguage.OK := 0;
    Except
      q4coreLanguage.OK := 0;
    End;
  End;

// Type local pour CreateAlias (Windows) — déclaré au niveau implementation
{$IFDEF WINDOWS}
type
  TCreateSymbolicLinkW = function(_1_y_lpSymlinkFileName, _2_y_lpTargetFileName: LPCWSTR;
                                  _3_e_dwFlags: DWORD): BOOL; stdcall;
  TGetFinalPathNameByHandleW = function(_1_y_hFile: THandle; _2_y_lpszFilePath: LPWSTR;
                                        _3_e_cchFilePath, _4_e_dwFlags: DWORD): DWORD; stdcall;
{$ENDIF}

Procedure createAlias( Const _1_t_targetPath: string; Const _2_t_aliasPath: string);
  Var
    _t_targetPath: string;
    _t_aliasPath:  string;
    {$IFDEF WINDOWS}
  _h_kernel : THandle;
  _f_createSymbolicLink    : TCreateSymbolicLinkW;
{$ENDIF}
  Begin
    q4coreLanguage.OK := 0;
    _t_targetPath := ExpandFileName( _1_t_targetPath);
    _t_aliasPath := ExpandFileName( _2_t_aliasPath);
    {$IFDEF WINDOWS}
  _h_kernel := GetModuleHandle('kernel32.dll');
  if (_h_kernel <> 0) then
  begin
    _f_createSymbolicLink := TCreateSymbolicLinkW(GetProcAddress(_h_kernel, 'CreateSymbolicLinkW'));
    if (Assigned(_f_createSymbolicLink)) then
    begin
      try
        if (_f_createSymbolicLink(LPCWSTR(WideString(_t_aliasPath)), LPCWSTR(WideString(_t_targetPath)), 0)) then
          q4coreLanguage.OK := 1;
      except
        q4coreLanguage.OK := 0;
      end;
    end;
  end;
{$ENDIF}
    {$IFDEF DARWIN}
  try
    if (fpSymLink(PChar(_t_targetPath), PChar(_t_aliasPath)) = 0) then
      q4coreLanguage.OK := 1;
  except
    q4coreLanguage.OK := 0;
  end;
{$ENDIF}
  End;

Procedure createFolder( Const _1_t_folderPath: string; Const _2_t_star: string);
  Var
    _t_path: string;
  Begin
    q4coreLanguage.OK := 0;
    _t_path := ExcludeTrailingPathDelimiter( ExpandFileName( _1_t_folderPath));
    If ( _2_t_star = '*') Then Begin
      Try
        If ( ForceDirectories( _t_path)) Then q4coreLanguage.OK := 1;
      Except
        q4coreLanguage.OK := 0;
      End;
    End Else
    Try
      If ( CreateDir( _t_path)) Then q4coreLanguage.OK := 1;
    Except
      q4coreLanguage.OK := 0;
    End;
  End;

Procedure deleteDocument( Const _1_t_document: string);
  Begin
    q4coreLanguage.OK := 0;
    If ( _1_t_document = '') Then Exit;
    Try
      If ( SysUtils.DeleteFile( ExpandFileName( _1_t_document))) Then q4coreLanguage.OK := 1;
    Except
      q4coreLanguage.OK := 0;
    End;
  End;

Procedure deleteFolder( Const _1_t_folder: string; Const _2_e_deleteOption: int64);
  Var
    _t_path: string;
  Begin
    q4coreLanguage.OK := 0;
    _t_path := ExcludeTrailingPathDelimiter( ExpandFileName( _1_t_folder));
    If ( not DirectoryExists( _t_path)) Then Begin
      If ( _2_e_deleteOption = q4DeleteWithContents) Then q4coreLanguage.OK := 1;
      Exit;
    End;
    Try
      If ( _2_e_deleteOption = q4DeleteWithContents) Then Begin
        If ( DeleteDirectory( _t_path, True)) Then q4coreLanguage.OK := 1;
      End Else If ( RemoveDir( _t_path)) Then q4coreLanguage.OK := 1;
    Except
      q4coreLanguage.OK := 0;
    End;
  End;

Procedure documentList( Const _1_t_pathname: string; Var _2_tt_documents: Array Of string; Var _3_e_count: int64; Const _4_e_options: int64);
  Var
    _o_list:    TStringList;
    _t_baseDir: string;
    _e_index:   int64;
  Begin
    _3_e_count := 0;
    _o_list := TStringList.Create;
    Try
      _t_baseDir := IncludeTrailingPathDelimiter( ExpandFileName( _1_t_pathname));
      collectFiles( _t_baseDir, ExcludeTrailingPathDelimiter( _t_baseDir), _4_e_options, _o_list);
      _3_e_count := _o_list.Count;
      If ( _3_e_count > Length( _2_tt_documents)) Then _3_e_count := Length( _2_tt_documents);
      For _e_index := 0 To _3_e_count - 1 Do _2_tt_documents[_e_index] := _o_list[_e_index];
    Finally
      _o_list.Free;
    End;
  End;

Function documentToText( Const _1_t_fileName: string; Const _2_t_charSet: string; Const _3_e_breakMode: int64): string;
  Var
    _o_fileStream: TFileStream;
    _bytes_raw:    TBytes;
    _t_encoding:   string;
    _t_content:    string;
  Begin
    Result := '';
    q4coreLanguage.OK := 0;
    If ( not FileExists( ExpandFileName( _1_t_fileName))) Then Exit;
    Try
      _o_fileStream := TFileStream.Create( ExpandFileName( _1_t_fileName), fmOpenRead or fmShareDenyNone);
      Try
        SetLength( _bytes_raw, _o_fileStream.Size);
        If ( _o_fileStream.Size > 0) Then _o_fileStream.ReadBuffer( _bytes_raw[0], _o_fileStream.Size);
      Finally
        _o_fileStream.Free;
      End;
      _t_encoding := UpperCase( _2_t_charSet);
      // Conversion bytes -> string
      // FPC : SetString copie les octets bruts ; on décode ensuite selon l'encodage
      If ( ( _t_encoding = '') or ( _t_encoding = 'UTF-8') or ( _t_encoding = 'UTF8')) Then Begin
        // UTF-8 : les chaînes FPC sont UTF-8 en mode {$H+}, SetString suffit
        If ( Length( _bytes_raw) > 0) Then SetString( _t_content, pansichar( @_bytes_raw[0]), Length( _bytes_raw))
        Else
          _t_content := '';
      End Else If ( ( _t_encoding = 'ISO-8859-1') or ( _t_encoding = 'LATIN-1')) Then Begin
        // Latin-1 : conversion via WinCP ou directement (1 octet = 1 caractère)
        If ( Length( _bytes_raw) > 0) Then SetString( _t_content, pansichar( @_bytes_raw[0]), Length( _bytes_raw))
        Else
          _t_content := '';
      End Else If ( Length( _bytes_raw) > 0) Then SetString( _t_content, pansichar( @_bytes_raw[0]), Length( _bytes_raw))
      Else
        _t_content := '';
      Result := applyBreakMode( _t_content, _3_e_breakMode);
      q4coreLanguage.OK := 1;
    Except
      q4coreLanguage.OK := 0;
    End;
  End;

Procedure folderList( Const _1_t_pathname: string; Var _2_tt_directories: Array Of string; Var _3_e_count: int64);
  Var
    _o_list:  TStringList;
    _e_index: int64;
  Begin
    _3_e_count := 0;
    _o_list := TStringList.Create;
    Try
      collectFolders( IncludeTrailingPathDelimiter( ExpandFileName( _1_t_pathname)), _o_list);
      _3_e_count := _o_list.Count;
      If ( _3_e_count > Length( _2_tt_directories)) Then _3_e_count := Length( _2_tt_directories);
      For _e_index := 0 To _3_e_count - 1 Do _2_tt_directories[_e_index] := _o_list[_e_index];
    Finally
      _o_list.Free;
    End;
  End;

Procedure getDocumentIcon( Const _1_t_docPath: string; Var _2_o_icon: Graphics.TBitmap; Const _3_e_size: int64);
  Begin
    Raise Exception.Create( 'GetDocumentIcon: not implemented yet. ' + 'See https://developer.4d.com/docs/commands/get-document-icon');
  End;

Function getDocumentPosition( Const _1_t_docRef: Tq4Time): double;
  Var
    _o_fileStream: TFileStream;
  Begin
    Result := 0;
    _o_fileStream := streamFromRef( _1_t_docRef);
    If ( _o_fileStream = nil) Then Exit;
    Result := _o_fileStream.Position;
  End;

Procedure getDocumentProperties( Const _1_t_document: string; Var _2_b_locked: boolean; Var _3_b_invisible: boolean; Var _4_d_createdOn: Tq4Date;
  Var _5_t_createdAt: Tq4Time; Var _6_d_modifiedOn: Tq4Date; Var _7_t_modifiedAt: Tq4Time);
  Var
    _t_path:      string;
    _rec_info:    TSearchRec;
    _dt_modified: TDateTime;
    _dt_created:  TDateTime;
    _e_year, _e_month, _e_day, _e_hour, _e_minute, _e_second, _e_millisecond: word;
    {$IFDEF WINDOWS}
  _dw_attributes     : DWORD;
{$ENDIF}
    {$IFDEF DARWIN}
  _rec_statInfo : Stat;

{$ENDIF}
  Begin
    q4coreLanguage.OK := 0;
    _t_path := ExpandFileName( _1_t_document);

    _2_b_locked := False;
    _3_b_invisible := False;
    _4_d_createdOn := '0000-00-00';
    _5_t_createdAt := '00:00:00';
    _6_d_modifiedOn := '0000-00-00';
    _7_t_modifiedAt := '00:00:00';

    If ( SysUtils.FindFirst( _t_path, faAnyFile, _rec_info) <> 0) Then Begin
      SysUtils.FindClose( _rec_info);
      Exit;
    End;
    SysUtils.FindClose( _rec_info);

    // --- Attributs locked / invisible ---
    {$IFDEF WINDOWS}
  _dw_attributes      := GetFileAttributes(PChar(_t_path));
  _2_b_locked    := (_dw_attributes and FILE_ATTRIBUTE_READONLY) <> 0;
  _3_b_invisible := (_dw_attributes and FILE_ATTRIBUTE_HIDDEN)   <> 0;
{$ENDIF}
    {$IFDEF DARWIN}
  _3_b_invisible := (Length(ExtractFileName(_t_path)) > 0) and (ExtractFileName(_t_path)[1] = '.');
  if (fpStat(PChar(_t_path), _rec_statInfo) = 0) then
    _2_b_locked := (_rec_statInfo.st_mode and S_IWUSR) = 0
  else
    _2_b_locked := False;
{$ENDIF}

    // --- Date/heure de modification ---
    _dt_modified := FileDateToDateTime( FileAge( _t_path));
    DecodeDate( _dt_modified, _e_year, _e_month, _e_day);
    DecodeTime( _dt_modified, _e_hour, _e_minute, _e_second, _e_millisecond);
    _6_d_modifiedOn := Format( '%.4d-%.2d-%.2d', [_e_year, _e_month, _e_day]);
    _7_t_modifiedAt := Format( '%.2d:%.2d:%.2d', [_e_hour, _e_minute, _e_second]);

    // --- Date/heure de création ---
    // Windows : FILETIME via FindData.ftCreationTime
    // macOS   : st_birthtimespec via fpStat
    _dt_created := getFileCreationDate( _t_path);
    If ( _dt_created > 0) Then Begin
      DecodeDate( _dt_created, _e_year, _e_month, _e_day);
      DecodeTime( _dt_created, _e_hour, _e_minute, _e_second, _e_millisecond);
      _4_d_createdOn := Format( '%.4d-%.2d-%.2d', [_e_year, _e_month, _e_day]);
      _5_t_createdAt := Format( '%.2d:%.2d:%.2d', [_e_hour, _e_minute, _e_second]);
    End Else Begin
      _4_d_createdOn := _6_d_modifiedOn;
      _5_t_createdAt := _7_t_modifiedAt;
    End;

    q4coreLanguage.OK := 1;
  End;

// Si document est de la forme "hh:mm:ss" => handle ouvert, sinon chemin d'accès
Function getDocumentSize( Const _1_t_document: string; Const _2_t_star: string): double;
  Var
    _o_fileStream:  TFileStream;
    _o_fileStream2: TFileStream;
  Begin
    Result := -1;
    If ( isDocRef( _1_t_document)) Then Begin
      _o_fileStream := streamFromRef( _1_t_document);
      If ( _o_fileStream = nil) Then Begin
        q4coreLanguage.OK := 0;
        Exit;
      End;
      Result := _o_fileStream.Size;
      q4coreLanguage.OK := 1;
    End Else
    Try
      _o_fileStream2 := TFileStream.Create( ExpandFileName( _1_t_document), fmOpenRead or fmShareDenyNone);
      Try
        Result := _o_fileStream2.Size;
        q4coreLanguage.OK := 1;
      Finally
        _o_fileStream2.Free;
      End;
    Except
      q4coreLanguage.OK := 0;
    End;
  End;

Function localizedDocumentPath( Const _1_t_relativePath: string): string;
  Var
    _t_resourcesDir: string;
    _t_langCode:     string;
    _t_candidate:    string;
  Begin
    Result := '';
    _t_resourcesDir := IncludeTrailingPathDelimiter( ExtractFilePath( ParamStr( 0))) + 'Resources' + PathDelim;
    If ( not DirectoryExists( _t_resourcesDir)) Then Exit;

    _t_langCode := SysUtils.GetEnvironmentVariable( 'LANG');
    If ( _t_langCode = '') Then _t_langCode := 'en'
    Else
      _t_langCode := LowerCase( Copy( _t_langCode, 1, 2));

    _t_candidate := _t_resourcesDir + _t_langCode + '.lproj' + PathDelim + StringReplace( _1_t_relativePath, '/', PathDelim, [rfReplaceAll]);
    If ( FileExists( _t_candidate) or DirectoryExists( _t_candidate)) Then Begin
      Result := _t_candidate;
      Exit;
    End;
    Result := '';
  End;

Procedure moveDocument( Const _1_t_srcPathname: string; Const _2_t_dstPathname: string);
  Begin
    q4coreLanguage.OK := 0;
    Try
      If ( RenameFile( ExpandFileName( _1_t_srcPathname), ExpandFileName( _2_t_dstPathname))) Then q4coreLanguage.OK := 1;
    Except
      q4coreLanguage.OK := 0;
    End;
  End;

Function objectToPath( Const _1_o_pathObject: TPathObject): string;
  Var
    _c_separator: char;
  Begin
    If ( ( Length( _1_o_pathObject.parentFolder) > 0) and ( _1_o_pathObject.parentFolder[Length( _1_o_pathObject.parentFolder)] = '/')) Then _c_separator := '/'
    Else
      _c_separator := PathDelim;

    If ( _1_o_pathObject.isFolder) Then Result := _1_o_pathObject.parentFolder + _1_o_pathObject.Name + _1_o_pathObject.extension + _c_separator
    Else
      Result := _1_o_pathObject.parentFolder + _1_o_pathObject.Name + _1_o_pathObject.extension;
  End;

Function pathToObject( Const _1_t_path: string; Const _2_e_pathType: int64): TPathObject;
  Var
    _t_pathWork:  string;
    _c_separator: char;
    _b_isFolder:  boolean;
    _t_nameExt:   string;
    _e_lastSeparator: int64;
    _e_dotPos:    int64;
    _e_index:     int64;
  Begin
    _t_pathWork := _1_t_path;
    If ( _2_e_pathType = q4PathIsPOSIX) Then _c_separator := '/'
    Else
      _c_separator := PathDelim;

    _b_isFolder := ( Length( _t_pathWork) > 0) and ( _t_pathWork[Length( _t_pathWork)] = _c_separator);
    If ( _b_isFolder) Then _t_pathWork := Copy( _t_pathWork, 1, Length( _t_pathWork) - 1);

    Result.isFolder := _b_isFolder;
    Result.parentFolder := '';
    Result.Name := '';
    Result.extension := '';

    _e_lastSeparator := 0;
    For _e_index := Length( _t_pathWork) Downto 1 Do If ( _t_pathWork[_e_index] = _c_separator) Then Begin
        _e_lastSeparator := _e_index;
        Break;
      End;

    If ( _e_lastSeparator > 0) Then Begin
      Result.parentFolder := Copy( _t_pathWork, 1, _e_lastSeparator);
      _t_nameExt := Copy( _t_pathWork, _e_lastSeparator + 1, MaxInt);
    End Else Begin
      Result.parentFolder := '';
      _t_nameExt := _t_pathWork;
    End;

    // Fichier caché ".nom" sans autre point => pas d'extension
    If ( ( Length( _t_nameExt) > 1) and ( _t_nameExt[1] = '.')) Then Begin
      _e_dotPos := Pos( '.', Copy( _t_nameExt, 2, MaxInt));
      If ( _e_dotPos = 0) Then Begin
        Result.Name := _t_nameExt;
        Result.extension := '';
        Exit;
      End;
      Inc( _e_dotPos);
    End Else Begin
      _e_dotPos := 0;
      For _e_index := Length( _t_nameExt) Downto 1 Do If ( _t_nameExt[_e_index] = '.') Then Begin
          _e_dotPos := _e_index;
          Break;
        End;
    End;

    If ( _e_dotPos > 0) Then Begin
      Result.Name := Copy( _t_nameExt, 1, _e_dotPos - 1);
      Result.extension := Copy( _t_nameExt, _e_dotPos, MaxInt);
    End Else Begin
      Result.Name := _t_nameExt;
      Result.extension := '';
    End;
  End;

Procedure resolveAlias( Const _1_t_aliasPath: string; Var _2_t_targetPath: string);
  Var
    _t_path:    string;
    _ca_buffer: Array[0..2047] Of char;
    _e_length:  int64;
    {$IFDEF WINDOWS}
  _h_kernel : THandle;
  _f_getFinalPathName    : TGetFinalPathNameByHandleW;
  _h_file   : THandle;
  _wca_buffer    : array[0..2047] of WideChar;
  _dw_length    : DWORD;
{$ENDIF}
  Begin
    q4coreLanguage.OK := 0;
    _t_path := ExpandFileName( _1_t_aliasPath);
    _2_t_targetPath := _t_path;

    {$IFDEF WINDOWS}
  _h_kernel := GetModuleHandle('kernel32.dll');
  if (_h_kernel <> 0) then
  begin
    _f_getFinalPathName := TGetFinalPathNameByHandleW(GetProcAddress(_h_kernel, 'GetFinalPathNameByHandleW'));
    if (Assigned(_f_getFinalPathName)) then
    begin
      _h_file := CreateFile(PChar(_t_path), 0,
                          FILE_SHARE_READ or FILE_SHARE_WRITE,
                          nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);
      if (_h_file <> INVALID_HANDLE_VALUE) then
      try
        _dw_length := _f_getFinalPathName(_h_file, _wca_buffer, Length(_wca_buffer), 0);
        if (_dw_length > 0) then
        begin
          _2_t_targetPath := WideString(_wca_buffer);
          q4coreLanguage.OK       := 1;
        end;
      finally
        CloseHandle(_h_file);
      end;
    end;
  end;
{$ENDIF}
    {$IFDEF DARWIN}
  _e_length := fpReadLink(PChar(_t_path), _ca_buffer, SizeOf(_ca_buffer));
  if (_e_length > 0) then
  begin
    SetString(_2_t_targetPath, _ca_buffer, _e_length);
    q4coreLanguage.OK := 1;
  end
  else
    q4coreLanguage.OK := 0;
{$ENDIF}
  End;

Function selectDocument( Const _1_t_directory: string; Const _2_t_fileTypes: string; Const _3_t_title: string; Const _4_e_options: int64;
  Var _5_tt_selected: Array Of string; Var _6_e_selectedCount: int64): string;
  Var
    _o_dialog:    TOpenDialog;
    _t_filter:    string;
    _e_index:     int64;
    _e_position, _e_separatorPosition: int64;
    _t_fileType:  string;
    _t_fileTypes: string;
  Begin
    Result := '';
    _6_e_selectedCount := 0;
    q4coreLanguage.OK := 0;

    _o_dialog := TOpenDialog.Create( nil);
    Try
      If ( _1_t_directory <> '') Then _o_dialog.InitialDir := ExpandFileName( _1_t_directory);
      If ( _3_t_title <> '') Then _o_dialog.Title := _3_t_title;

      If ( ( _2_t_fileTypes = '') or ( _2_t_fileTypes = '*') or ( _2_t_fileTypes = '.*')) Then _t_filter := 'All files (*.*)|*.*'
      Else Begin
        _t_filter := '';
        _t_fileTypes := _2_t_fileTypes + ';';
        _e_position := 1;
        While ( _e_position <= Length( _t_fileTypes)) Do Begin
          _e_separatorPosition := Pos( ';', _t_fileTypes, _e_position);
          If ( _e_separatorPosition = 0) Then Break;
          _t_fileType := Trim( Copy( _t_fileTypes, _e_position, _e_separatorPosition - _e_position));
          If ( _t_fileType <> '') Then Begin
            If ( _t_filter <> '') Then _t_filter := _t_filter + '|';
            _t_filter := _t_filter + _t_fileType + ' files (*.' + _t_fileType + ')|*.' + _t_fileType;
          End;
          _e_position := _e_separatorPosition + 1;
        End;
      End;
      _o_dialog.Filter := _t_filter;

      If ( ( _4_e_options and q4MultipleFiles) <> 0) Then _o_dialog.Options := _o_dialog.Options + [ofAllowMultiSelect];

      If ( _o_dialog.Execute) Then Begin
        q4coreLanguage.OK := 1;
        q4coreLanguage.Document := _o_dialog.FileName;
        Result := _o_dialog.FileName;
        _6_e_selectedCount := _o_dialog.Files.Count;
        If ( _6_e_selectedCount > Length( _5_tt_selected)) Then _6_e_selectedCount := Length( _5_tt_selected);
        For _e_index := 0 To _6_e_selectedCount - 1 Do _5_tt_selected[_e_index] := _o_dialog.Files[_e_index];
      End;
    Finally
      _o_dialog.Free;
    End;
  End;

Function selectFolder( Const _1_t_message: string; Const _2_t_defaultPath: string; Const _3_e_options: int64): string;
  Var
    _o_dialog: TSelectDirectoryDialog;
  Begin
    Result := '';
    q4coreLanguage.OK := 0;
    _o_dialog := TSelectDirectoryDialog.Create( nil);
    Try
      If ( _1_t_message <> '') Then _o_dialog.Title := _1_t_message;
      If ( _2_t_defaultPath <> '') Then _o_dialog.FileName := ExpandFileName( _2_t_defaultPath);
      If ( _o_dialog.Execute) Then Begin
        Result := IncludeTrailingPathDelimiter( _o_dialog.FileName);
        q4coreLanguage.OK := 1;
      End;
    Finally
      _o_dialog.Free;
    End;
  End;

Procedure setDocumentPosition( Const _1_t_docRef: Tq4Time; Const _2_r_offset: double; Const _3_e_anchor: int64);
  Var
    _o_fileStream: TFileStream;
    _enum_origin:  TSeekOrigin;
  Begin
    _o_fileStream := streamFromRef( _1_t_docRef);
    If ( _o_fileStream = nil) Then Exit;
    Case _3_e_anchor Of
      q4AnchorBeginning: _enum_origin := soBeginning;
      q4AnchorEnd: _enum_origin := soEnd;
      q4AnchorCurrent: _enum_origin := soCurrent;
      Else _enum_origin := soBeginning;
    End;
    _o_fileStream.Seek( Trunc( _2_r_offset), _enum_origin);
  End;

Procedure setDocumentProperties( Const _1_t_document: string; Const _2_b_locked: boolean; Const _3_b_invisible: boolean; Const _4_d_createdOn: Tq4Date;
  Const _5_t_createdAt: Tq4Time; Const _6_d_modifiedOn: Tq4Date; Const _7_t_modifiedAt: Tq4Time);
  Var
    _t_path:      string;
    _e_year, _e_month, _e_day, _e_hour, _e_minute, _e_second: int64;
    _dt_modified: TDateTime;
    {$IFDEF WINDOWS}
  _dw_attributes : DWORD;
{$ENDIF}
    {$IFDEF DARWIN}
  _rec_statInfo : Stat;
  _mode_new  : mode_t;
{$ENDIF}
  Begin
    q4coreLanguage.OK := 0;
    _t_path := ExpandFileName( _1_t_document);
    If ( not FileExists( _t_path)) Then Exit;

    {$IFDEF WINDOWS}
  _dw_attributes := GetFileAttributes(PChar(_t_path));
  if (_2_b_locked)    then _dw_attributes := _dw_attributes or  FILE_ATTRIBUTE_READONLY
               else _dw_attributes := _dw_attributes and (not FILE_ATTRIBUTE_READONLY);
  if (_3_b_invisible) then _dw_attributes := _dw_attributes or  FILE_ATTRIBUTE_HIDDEN
               else _dw_attributes := _dw_attributes and (not FILE_ATTRIBUTE_HIDDEN);
  SetFileAttributes(PChar(_t_path), _dw_attributes);
{$ENDIF}
    {$IFDEF DARWIN}
  if (fpStat(PChar(_t_path), _rec_statInfo) = 0) then
  begin
    _mode_new := _rec_statInfo.st_mode;
    if (_2_b_locked) then
      _mode_new := _mode_new and (not (S_IWUSR or S_IWGRP or S_IWOTH))
    else
      _mode_new := _mode_new or S_IWUSR;
    fpChmod(PChar(_t_path), _mode_new);
  end;
{$ENDIF}

    // Mise à jour de la date/heure de modification
    Try
      _e_year := StrToIntDef( Copy( _6_d_modifiedOn, 1, 4), 0);
      _e_month := StrToIntDef( Copy( _6_d_modifiedOn, 6, 2), 0);
      _e_day := StrToIntDef( Copy( _6_d_modifiedOn, 9, 2), 0);
      _e_hour := StrToIntDef( Copy( _7_t_modifiedAt, 1, 2), 0);
      _e_minute := StrToIntDef( Copy( _7_t_modifiedAt, 4, 2), 0);
      _e_second := StrToIntDef( Copy( _7_t_modifiedAt, 7, 2), 0);
      _dt_modified := EncodeDate( _e_year, _e_month, _e_day) + EncodeTime( _e_hour, _e_minute, _e_second, 0);
      FileSetDate( _t_path, DateTimeToFileDate( _dt_modified));
      q4coreLanguage.OK := 1;
    Except
      q4coreLanguage.OK := 0;
    End;
  End;

Procedure setDocumentSize( Const _1_t_docRef: Tq4Time; Const _2_r_size: double);
  Var
    _o_fileStream: TFileStream;
  Begin
    _o_fileStream := streamFromRef( _1_t_docRef);
    If ( _o_fileStream = nil) Then Begin
      q4coreLanguage.OK := 0;
      Exit;
    End;
    Try
      _o_fileStream.Size := Trunc( _2_r_size);
      q4coreLanguage.OK := 1;
    Except
      q4coreLanguage.OK := 0;
    End;
  End;

Procedure showOnDisk( Const _1_t_pathname: string; Const _2_t_star: string);
  Var
    _t_path: string;
  Begin
    q4coreLanguage.OK := 0;
    _t_path := ExpandFileName( _1_t_pathname);
    If ( DirectoryExists( _t_path)) Then Begin
      If ( _2_t_star = '*') Then LCLIntf.openDocument( _t_path)
      Else
        LCLIntf.openDocument( ExtractFilePath( ExcludeTrailingPathDelimiter( _t_path)));
    End Else If ( FileExists( _t_path)) Then LCLIntf.openDocument( ExtractFilePath( _t_path))
    Else
      Exit;
    q4coreLanguage.OK := 1;
  End;

Function testPathName( Const _1_t_pathname: string): int64;
  Var
    _t_path: string;
  Begin
    _t_path := ExpandFileName( _1_t_pathname);
    If ( FileExists( _t_path)) Then Result := q4IsADocument
    Else If ( DirectoryExists( _t_path)) Then Result := q4IsAFolder
    Else
      Result := -43;
  End;

Procedure textToDocument( Const _1_t_fileName: string; Const _2_t_text: string; Const _3_t_charSet: string; Const _4_e_breakMode: int64);
  Var
    _t_path:    string;
    _o_fileStream: TFileStream;
    _t_content: string;
    _bytes_raw: TBytes;
    _e_index:   int64;
  Begin
    q4coreLanguage.OK := 0;
    _t_path := ExpandFileName( _1_t_fileName);
    Try
      _t_content := applyBreakMode( _2_t_text, _4_e_breakMode);
      // Conversion string -> bytes (copie directe des octets — FPC {$H+} = UTF-8/Ansi)
      SetLength( _bytes_raw, Length( _t_content));
      For _e_index := 1 To Length( _t_content) Do _bytes_raw[_e_index - 1] := byte( _t_content[_e_index]);
      _o_fileStream := TFileStream.Create( _t_path, fmCreate);
      Try
        If ( Length( _bytes_raw) > 0) Then _o_fileStream.WriteBuffer( _bytes_raw[0], Length( _bytes_raw));
      Finally
        _o_fileStream.Free;
      End;
      q4coreLanguage.OK := 1;
    Except
      q4coreLanguage.OK := 0;
    End;
  End;

Procedure volumeAttributes( Const _1_t_volume: string; Var _2_r_size: double; Var _3_r_used: double; Var _4_r_free: double);
  Var
    {$IFDEF WINDOWS}
  _dw_sectorsPerCluster : DWORD;
  _dw_bytesPerSector    : DWORD;
  _dw_freeClusters      : DWORD;
  _dw_totalClusters     : DWORD;
  _e_bytesPerCluster   : Int64;
{$ENDIF}
    {$IFDEF DARWIN}
  _rec_fsStat : TStatFS;
{$ENDIF}
  Begin
    _2_r_size := -1;
    _3_r_used := -1;
    _4_r_free := -1;
    q4coreLanguage.OK := 0;

    {$IFDEF WINDOWS}
  if (not GetDiskFreeSpace(PChar(_1_t_volume), _dw_sectorsPerCluster, _dw_bytesPerSector,
                          _dw_freeClusters, _dw_totalClusters)) then Exit;
  _e_bytesPerCluster := Int64(_dw_sectorsPerCluster) * _dw_bytesPerSector;
  _2_r_size := _dw_totalClusters * _e_bytesPerCluster;
  _4_r_free := _dw_freeClusters  * _e_bytesPerCluster;
  _3_r_used := _2_r_size - _4_r_free;
  q4coreLanguage.OK := 1;
  Exit;
{$ENDIF}

    {$IFDEF DARWIN}
  if (fpStatFS(PChar(_1_t_volume), @_rec_fsStat) <> 0) then Exit;
  _2_r_size := Double(_rec_fsStat.f_blocks) * _rec_fsStat.f_bsize;
  _4_r_free := Double(_rec_fsStat.f_bavail) * _rec_fsStat.f_bsize;
  _3_r_used := _2_r_size - Double(_rec_fsStat.f_bfree) * _rec_fsStat.f_bsize;
  q4coreLanguage.OK := 1;
  Exit;
{$ENDIF}
  End;

Procedure volumeList( Var _1_tt_volumes: Array Of string; Var _2_e_count: int64);
  Var
    _o_list:  TStringList;
    _e_index: int64;
    {$IFDEF WINDOWS}
  _ca_buffer : array[0..255] of Char;
  _p_char   : PChar;
{$ENDIF}
    {$IFDEF DARWIN}
  _rec_searchRec  : TSearchRec;
{$ENDIF}
  Begin
    _2_e_count := 0;
    _o_list := TStringList.Create;
    Try
      {$IFDEF WINDOWS}
    GetLogicalDriveStrings(SizeOf(_ca_buffer) div SizeOf(Char), _ca_buffer);
    _p_char := _ca_buffer;
    while (_p_char^ <> #0) do
    begin
      _o_list.Add(_p_char);
      Inc(_p_char, StrLen(_p_char) + 1);
    end;
{$ENDIF}
      {$IFDEF DARWIN}
    // Liste les volumes montés sous /Volumes
    if (SysUtils.FindFirst('/Volumes/*', faDirectory, _rec_searchRec) = 0) then
    try
      repeat
        if ((_rec_searchRec.Name <> '.') and (_rec_searchRec.Name <> '..') and
           ((_rec_searchRec.Attr and faDirectory) <> 0)) then
          _o_list.Add(_rec_searchRec.Name);
      until (SysUtils.FindNext(_rec_searchRec) <> 0);
    finally
      SysUtils.FindClose(_rec_searchRec);
    end;
{$ENDIF}
      _2_e_count := _o_list.Count;
      If ( _2_e_count > Length( _1_tt_volumes)) Then _2_e_count := Length( _1_tt_volumes);
      For _e_index := 0 To _2_e_count - 1 Do _1_tt_volumes[_e_index] := _o_list[_e_index];
    Finally
      _o_list.Free;
    End;
  End;

End.
