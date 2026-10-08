Unit q4systemEnvironment;

{$mode objfpc}{$H+}

{
  q4systemEnvironment
  version du 2026/05/15-03

  Mapping 4D → q4systemEnvironment -> statut
  Command Number 4D,    4D Command,                       q4 API,                           Statut
  ------------------------------------------------------------------------------------------------
  437,                  Count screens,                    countScreens,                     Partial - Windows/macOS natif, Linux via bridge
  1355,                 Current client authentication,    currentClientAuthentication,      Partial - SSO Windows réel via bridge
  483,                  Current machine,                  currentMachine,                   OK spécifique - nom machine OS
  484,                  Current system user,              currentSystemUser,                OK spécifique - utilisateur OS
  1700,                 Font file,                        fontFile,                         Partial - lookup police dépendant OS
  460,                  FONT LIST,                        fontList,                         Partial - favoris/récents q4, liste système selon OS
  1362,                 FONT STYLE LIST,                  fontStyleList,                    Partial - styles dépendants OS
  994,                  GET SYSTEM FORMAT,                getSystemFormat,                  OK spécifique - formats FPC/OS approchés
  1572,                 Is macOS,                         isMacOS,                          OK
  1573,                 Is Windows,                       isWindows,                        OK
  667,                  LOG EVENT,                        logEvent,                         Partial - cibles 4D via bridge
  440,                  Menu bar height,                  menuBarHeight,                    Partial - Windows/macOS natif, Linux via bridge
  441,                  Menu bar screen,                  menuBarScreen,                    OK spécifique - Windows/Linux = 1 par défaut
  1304,                 OPEN COLOR PICKER,                openColorPicker,                  Partial - UI native Windows/macOS, Linux via bridge
  1303,                 OPEN FONT PICKER,                 openFontPicker,                   Partial - UI native Windows/macOS, Linux via bridge
  438,                  SCREEN COORDINATES,               screenCoordinates,                Partial - multi-écran Windows/macOS, Linux via bridge
  439,                  SCREEN DEPTH,                     screenDepth,                      Partial - Windows/macOS natif, Linux via bridge
  188,                  Screen height,                    screenHeight,                     Partial - Windows/macOS natif, Linux via bridge
  187,                  Screen width,                     screenWidth,                      Partial - Windows/macOS natif, Linux via bridge
  956,                  Select RGB color,                 selectRGBColor,                   Partial - Windows natif, macOS/Linux via bridge; modifie OK
  1305,                 SET RECENT FONTS,                 setRecentFonts,                   OK spécifique - état runtime q4 local
  487,                  System folder,                    systemFolder,                     OK spécifique - chemins OS approchés
  1571,                 System info,                      systemInfo,                       Partial - JSON sans volumes/interfaces détaillés
  486,                  Temporary folder,                 temporaryFolder,                  OK

  Doc: https://developer.4d.com/docs/21/commands/theme/System-Environment
}

Interface

Uses
  Classes, SysUtils,
  {$IFDEF UNIX}
  clocale,
{$ENDIF}
  {$IFDEF WINDOWS}
  Windows, Registry, ShlObj, CommDlg,
{$ENDIF}
  {$IFDEF DARWIN}
  MacOSAll, CocoaAll,
{$ENDIF}
  q4coreLanguage, q4interruptions;

Type
  Tq4TextArray = Array Of string;
  Tq4StringArray = Tq4TextArray;

Const
  // Font Styles
  PLAIN = 0;
  BOLD = 1;
  ITALIC = 2;

  // FONT LIST
  SYSTEM_FONTS = 0;
  FAVORITE_FONTS = 1;
  RECENT_FONTS = 2;

  // SCREEN COORDINATES
  SCREEN_SIZE = 0;
  SCREEN_WORK_AREA = 1;

  // GET SYSTEM FORMAT
  DECIMAL_SEPARATOR = 0;
  THOUSAND_SEPARATOR = 1;
  CURRENCY_SYMBOL = 2;
  SYSTEM_TIME_SHORT_PATTERN = 3;
  SYSTEM_TIME_MEDIUM_PATTERN = 4;
  SYSTEM_TIME_LONG_PATTERN = 5;
  SYSTEM_DATE_SHORT_PATTERN = 6;
  SYSTEM_DATE_MEDIUM_PATTERN = 7;
  SYSTEM_DATE_LONG_PATTERN = 8;
  DATE_SEPARATOR = 13;
  TIME_SEPARATOR = 14;
  SHORT_DATE_DAY_POSITION = 15;
  SHORT_DATE_MONTH_POSITION = 16;
  SHORT_DATE_YEAR_POSITION = 17;
  SYSTEM_TIME_AM_LABEL = 18;
  SYSTEM_TIME_PM_LABEL = 19;

  // System folder
  SYSTEM_FOLDER_SYSTEM = 0;
  SYSTEM_FOLDER_FONTS = 1;
  SYSTEM_FOLDER_USER_PREFS_ALL = 2;
  SYSTEM_FOLDER_USER_PREFS_USER = 3;
  SYSTEM_FOLDER_STARTUP_WIN_ALL = 4;
  SYSTEM_FOLDER_STARTUP_WIN_USER = 5;
  SYSTEM_FOLDER_START_MENU_WIN_ALL = 8;
  SYSTEM_FOLDER_START_MENU_WIN_USER = 9;
  SYSTEM_FOLDER_SYSTEM_WIN = 12;
  SYSTEM_FOLDER_SYSTEM32_WIN = 13;
  SYSTEM_FOLDER_FAVORITES_WIN = 14;
  SYSTEM_FOLDER_DESKTOP = 15;
  SYSTEM_FOLDER_APPLICATIONS = 16;
  SYSTEM_FOLDER_DOCUMENTS = 17;
  SYSTEM_FOLDER_HOME = 18;

  // LOG EVENT
  INTO_WINDOWS_LOG_EVENTS = 0;
  INTO_4D_DEBUG_MESSAGE = 1;
  INTO_4D_REQUEST_LOG = 2;
  INTO_4D_COMMANDS_LOG = 3;
  INTO_4D_DIAGNOSTIC_LOG = 5;
  INTO_SYSTEM_STD_OUTPUTS = 6;

  INFORMATION_MESSAGE = 0;
  WARNING_MESSAGE = 1;
  ERROR_MESSAGE = 2;

  // SCREEN DEPTH
  BLACK_AND_WHITE = 0;
  FOUR_COLORS = 2;
  SIXTEEN_COLORS = 4;
  TWO_FIFTY_SIX_COLORS = 8;
  THOUSANDS_OF_COLORS = 16;
  MILLIONS_OF_COLORS_24 = 24;
  MILLIONS_OF_COLORS_32 = 32;
  IS_GRAY_SCALE = 0;
  IS_COLOR = 1;

  // OPEN COLOR PICKER
  COLOR_PICKER_TEXT = 0;
  COLOR_PICKER_BACKGROUND = 1;

Type
  Tq4CurrentClientAuthenticationProvider = Function( out _1_t_domain: string; out _2_t_protocol: string): string;
  Tq4OpenColorPickerHandler = Procedure( _1_e_textOrBackground: int64);
  Tq4OpenFontPickerHandler = Procedure;
  Tq4SelectRGBColorHandler = Function( _1_e_defaultColor: int64; Const _2_t_message: string): int64;
  Tq4CountScreensHandler = Function: int64;
  Tq4MenuBarIntHandler = Function: int64;
  Tq4ScreenCoordinatesHandler = Procedure( out _1_e_left: int64; out _2_e_top: int64; out _3_e_right: int64; out _4_e_bottom: int64; _5_e_screenID: int64; _6_e_screenArea: int64);
  Tq4ScreenDepthHandler = Procedure( out _1_e_depth: int64; out _2_e_color: int64; _3_e_screen: int64);
  Tq4ScreenSizeHandler = Function( Const _1_t_star: string): int64;
  Tq4FontFileHandler = Function( Const _1_t_fontFamily: string; _2_e_fontStyle: int64): string;
  Tq4FontListHandler = Procedure( out _1_tt_fonts: Tq4TextArray; Const _2_t_mode: string);
  Tq4FontStyleListHandler = Procedure( Const _1_t_fontFamily: string; out _2_tt_fontStyleList: Tq4TextArray; out _3_tt_fontNameList: Tq4TextArray);
  Tq4SetRecentFontsHandler = Procedure( Const _1_tt_fontsArray: Tq4TextArray);
  Tq4LogEventHandler = Procedure( _1_e_outputType: int64; Const _2_t_message: string; _3_e_importance: int64);
  Tq4SystemInfoHandler = Function: string;

  Tq4SystemEnvironmentBridge = Record
    currentClientAuthentication: Tq4CurrentClientAuthenticationProvider;
    openColorPicker: Tq4OpenColorPickerHandler;
    openFontPicker: Tq4OpenFontPickerHandler;
    selectRGBColor: Tq4SelectRGBColorHandler;
    countScreens: Tq4CountScreensHandler;
    menuBarHeight: Tq4MenuBarIntHandler;
    menuBarScreen: Tq4MenuBarIntHandler;
    screenCoordinates: Tq4ScreenCoordinatesHandler;
    screenDepth: Tq4ScreenDepthHandler;
    screenHeight: Tq4ScreenSizeHandler;
    screenWidth: Tq4ScreenSizeHandler;
    fontFile: Tq4FontFileHandler;
    fontList: Tq4FontListHandler;
    fontStyleList: Tq4FontStyleListHandler;
    setRecentFonts: Tq4SetRecentFontsHandler;
    logEvent: Tq4LogEventHandler;
    systemInfo: Tq4SystemInfoHandler;
  End;

Function countScreens: int64;

Function currentClientAuthentication: string; overload;
Function currentClientAuthentication( out _1_t_domain: string; out _2_t_protocol: string): string; overload;

Function currentMachine: string;
Function currentSystemUser: string;

Function fontFile( Const _1_t_fontFamily: string; _2_e_fontStyle: int64 = PLAIN): string;
Procedure fontList( out _1_tt_fonts: Tq4TextArray); overload;
Procedure fontList( out _1_tt_fonts: Tq4TextArray; _2_e_listType: int64); overload;
Procedure fontList( out _1_tt_fonts: Tq4TextArray; Const _2_t_star: string); overload;
Procedure fontStyleList( Const _1_t_fontFamily: string; out _2_tt_fontStyleList: Tq4TextArray; out _3_tt_fontNameList: Tq4TextArray);

Procedure getSystemFormat( _1_e_format: int64; out _2_t_value: string);

Function isMacOS: boolean;
Function isWindows: boolean;

Procedure logEvent( Const _1_t_message: string); overload;
Procedure logEvent( _1_e_outputType: int64; Const _2_t_message: string; _3_e_importance: int64 = INFORMATION_MESSAGE); overload;

Function menuBarHeight: int64;
Function menuBarScreen: int64;

Procedure openColorPicker( _1_e_textOrBackground: int64 = COLOR_PICKER_TEXT);
Procedure openFontPicker;

Procedure screenCoordinates( out _1_e_left: int64; out _2_e_top: int64; out _3_e_right: int64; out _4_e_bottom: int64); overload;
Procedure screenCoordinates( out _1_e_left: int64; out _2_e_top: int64; out _3_e_right: int64; out _4_e_bottom: int64; _5_e_screenID: int64; _6_e_screenArea: int64 = SCREEN_SIZE); overload;

Procedure screenDepth( out _1_e_depth: int64; out _2_e_color: int64); overload;
Procedure screenDepth( out _1_e_depth: int64; out _2_e_color: int64; _3_e_screen: int64); overload;

Function screenHeight( Const _1_t_star: string = ''): int64;
Function screenWidth( Const _1_t_star: string = ''): int64;

Function selectRGBColor( _1_e_defaultColor: int64 = 0; Const _2_t_message: string = ''): int64;

Procedure setRecentFonts( Const _1_tt_fontsArray: Tq4TextArray);

Function systemFolder: string; overload;
Function systemFolder( _1_e_type: int64): string; overload;
Function systemInfo: string;
Function temporaryFolder: string;

Procedure registerBridge( Const _1_y_bridgeValue: Tq4SystemEnvironmentBridge);
Procedure resetBridge;

Implementation

Var
  y_bridge: Tq4SystemEnvironmentBridge;
  tt_recentFonts: Tq4TextArray;

{$IFDEF WINDOWS}
type
  Tq4MemoryStatusEx = packed record
    dwLength: DWORD;
    dwMemoryLoad: DWORD;
    ullTotalPhys: QWord;
    ullAvailPhys: QWord;
    ullTotalPageFile: QWord;
    ullAvailPageFile: QWord;
    ullTotalVirtual: QWord;
    ullAvailVirtual: QWord;
    ullAvailExtendedVirtual: QWord;
  end;

  Tq4GlobalMemoryStatusExFunc = function(var _1_y_buffer: Tq4MemoryStatusEx): BOOL; stdcall;

  // FPC 3.2.x sous Win64 n'expose pas toujours les noms Delphi/WinAPI simples
  // MONITORINFO / CHOOSECOLOR / CHOOSEFONT. On garde donc des records locaux
  // compatibles avec les structures C et on appelle les API par import explicite.
  Tq4WinMonitorInfo = record
    cbSize: DWORD;
    rcMonitor: RECT;
    rcWork: RECT;
    dwFlags: DWORD;
  end;
  Pq4WinMonitorInfo = ^Tq4WinMonitorInfo;

  Tq4WinMonitorEnumProc = function(_1_h_monitor: HMONITOR; _2_h_dc: HDC; _3_p_rect: LPRECT; _4_e_lParam: LPARAM): BOOL; stdcall;

  Tq4WinChooseColor = record
    lStructSize: DWORD;
    hwndOwner: HWND;
    hInstance: HWND;
    rgbResult: COLORREF;
    lpCustColors: ^COLORREF;
    Flags: DWORD;
    lCustData: LPARAM;
    lpfnHook: Pointer;
    lpTemplateName: PChar;
  end;
  Pq4WinChooseColor = ^Tq4WinChooseColor;

  Tq4WinChooseFont = record
    lStructSize: DWORD;
    hwndOwner: HWND;
    hDC: HDC;
    lpLogFont: Pointer;
    iPointSize: LongInt;
    Flags: DWORD;
    rgbColors: COLORREF;
    lCustData: LPARAM;
    lpfnHook: Pointer;
    lpTemplateName: PChar;
    hInstance: THandle;
    lpszStyle: PChar;
    nFontType: Word;
    wReserved: Word;
    nSizeMin: LongInt;
    nSizeMax: LongInt;
  end;
  Pq4WinChooseFont = ^Tq4WinChooseFont;

var
  o_fontListTarget: TStringList;
  o_styleList: TStringList;
  o_nameList: TStringList;
  e_monitorTargetIndex: Int64;
  e_monitorCurrentIndex: Int64;
  b_monitorFound: Boolean;
  y_monitorResult: Tq4WinMonitorInfo;

function q4WinGetMonitorInfo(_1_h_monitor: HMONITOR; _2_p_monitorInfo: Pq4WinMonitorInfo): BOOL; stdcall; external 'user32.dll' name 'GetMonitorInfoA';
function q4WinEnumDisplayMonitors(_1_h_dc: HDC; _2_p_clipRect: LPRECT; _3_p_enumProc: Tq4WinMonitorEnumProc; _4_e_data: LPARAM): BOOL; stdcall; external 'user32.dll' name 'EnumDisplayMonitors';
function q4WinChooseColor(_1_p_chooseColor: Pq4WinChooseColor): BOOL; stdcall; external 'comdlg32.dll' name 'ChooseColorA';
function q4WinChooseFont(_1_p_chooseFont: Pq4WinChooseFont): BOOL; stdcall; external 'comdlg32.dll' name 'ChooseFontA';

function q4WinCharArrayToString(const _1_y_buffer: array of Char): string;
begin
  if System.Length(_1_y_buffer) = 0 then
    Exit('');
  Result := SysUtils.StrPas(PChar(@_1_y_buffer[0]));
end;

function q4WinGetEnv(const _1_t_name: string): string;
var
  y_buffer: array[0..MAX_PATH] of Char;
  e_length: DWORD;
begin
  e_length := Windows.GetEnvironmentVariable(PChar(_1_t_name), y_buffer, System.High(y_buffer) + 1);
  if e_length > 0 then
    Exit(q4WinCharArrayToString(y_buffer));
  Result := '';
end;

function q4WinEnumFontsCallback(var _1_y_elf: ENUMLOGFONTEX; var _2_y_ntm: NEWTEXTMETRICEX; _3_e_fontType: LongInt; _4_e_lParam: LPARAM): LongInt; stdcall;
var
  t_faceName: string;
begin
  t_faceName := q4WinCharArrayToString(_1_y_elf.elfLogFont.lfFaceName);
  if Assigned(o_fontListTarget) and (t_faceName <> '') and (o_fontListTarget.IndexOf(t_faceName) < 0) then
    o_fontListTarget.Add(t_faceName);
  Result := 1;
end;

function q4WinEnumStylesCallback(var _1_y_elf: ENUMLOGFONTEX; var _2_y_ntm: NEWTEXTMETRICEX; _3_e_fontType: LongInt; _4_e_lParam: LPARAM): LongInt; stdcall;
var
  t_styleName: string;
  t_fullName: string;
begin
  t_styleName := q4WinCharArrayToString(_1_y_elf.elfStyle);
  t_fullName := q4WinCharArrayToString(_1_y_elf.elfFullName);
  if Assigned(o_styleList) and Assigned(o_nameList) and (t_styleName <> '') and (o_styleList.IndexOf(t_styleName) < 0) then
  begin
    o_styleList.Add(t_styleName);
    o_nameList.Add(t_fullName);
  end;
  Result := 1;
end;

function q4WinEnumMonitorCallback(_1_h_monitor: HMONITOR; _2_h_dc: HDC; _3_p_rect: LPRECT; _4_e_lParam: LPARAM): BOOL; stdcall;
var
  y_monitorInfo: Tq4WinMonitorInfo;
begin
  System.Inc(e_monitorCurrentIndex);
  Result := True;

  if e_monitorCurrentIndex <> e_monitorTargetIndex then
    Exit;

  System.FillChar(y_monitorInfo, System.SizeOf(y_monitorInfo), 0);
  y_monitorInfo.cbSize := System.SizeOf(Tq4WinMonitorInfo);
  if q4WinGetMonitorInfo(_1_h_monitor, @y_monitorInfo) then
  begin
    y_monitorResult := y_monitorInfo;
    b_monitorFound := True;
    Result := False;
  end;
end;
{$ENDIF}

Procedure q4RaiseNotImplemented( Const _1_t_command: string; Const _2_t_reason: string = '');
  Var
    t_message: string;
  Begin
    t_message := 'q4systemEnvironment.' + _1_t_command + ' is not implemented for this platform/context';
    If ( _2_t_reason <> '') Then t_message := t_message + ': ' + _2_t_reason;
    q4interruptions.assertRaise( t_message, {$I %CURRENTROUTINE%}, {$I %LINENUM%});
  End;

Function q4JsonEscape( Const _1_t_value: string): string;
  Var
    e_index: SizeInt;
    c_char:  char;
  Begin
    Result := '';
    For e_index := 1 To System.Length( _1_t_value) Do Begin
      c_char := _1_t_value[e_index];
      Case c_char Of
        '"': Result := Result + '\"';
        '\': Result := Result + '\\';
        '/': Result := Result + '\/';
        #8: Result := Result + '\b';
        #9: Result := Result + '\t';
        #10: Result := Result + '\n';
        #12: Result := Result + '\f';
        #13: Result := Result + '\r';
        Else If ( System.Ord( c_char) < 32) Then Result := Result + '\u' + SysUtils.IntToHex( System.Ord( c_char), 4)
          Else
            Result := Result + c_char;
      End;
    End;
  End;

Function q4JsonString( Const _1_t_value: string): string;
  Begin
    Result := '"' + q4JsonEscape( _1_t_value) + '"';
  End;

Function q4FirstEnvironmentValue( Const _1_tt_names: Array Of string): string;
  Var
    e_index: int64;
    t_value: string;
  Begin
    Result := '';
    For e_index := 0 To System.Length( _1_tt_names) - 1 Do Begin
      t_value := SysUtils.Trim( SysUtils.GetEnvironmentVariable( _1_tt_names[e_index]));
      If t_value <> '' Then Exit( t_value);
    End;
  End;

Function q4UserHomeFolder: string;
  Var
    t_home: string;
  Begin
    t_home := q4FirstEnvironmentValue( ['USERPROFILE', 'HOME']);
    If t_home = '' Then t_home := SysUtils.GetUserDir;
    If t_home = '' Then t_home := '.';
    Result := SysUtils.IncludeTrailingPathDelimiter( t_home);
  End;

Function q4JoinFolder( Const _1_t_base: string; Const _2_t_child: string): string;
  Begin
    If _1_t_base = '' Then Exit( '');
    Result := SysUtils.IncludeTrailingPathDelimiter( _1_t_base) + _2_t_child;
    Result := SysUtils.IncludeTrailingPathDelimiter( Result);
  End;

Function q4LowerNoSpaces( Const _1_t_value: string): string;
  Var
    e_index: SizeInt;
    c_char:  char;
  Begin
    Result := '';
    For e_index := 1 To System.Length( _1_t_value) Do Begin
      c_char := _1_t_value[e_index];
      If not ( c_char in [' ', #9, '-', '_']) Then Result := Result + SysUtils.LowerCase( c_char);
    End;
  End;

{$IFDEF WINDOWS}
function q4RGBToColorRef(_1_e_rgbColor: Int64): COLORREF;
var
  e_red: Int64;
  e_green: Int64;
  e_blue: Int64;
begin
  e_red := (_1_e_rgbColor shr 16) and $FF;
  e_green := (_1_e_rgbColor shr 8) and $FF;
  e_blue := _1_e_rgbColor and $FF;
  Result := COLORREF(e_red or (e_green shl 8) or (e_blue shl 16));
end;

function q4ColorRefToRGB(_1_e_colorRef: COLORREF): Int64;
var
  e_red: Int64;
  e_green: Int64;
  e_blue: Int64;
begin
  e_red := _1_e_colorRef and $FF;
  e_green := (_1_e_colorRef shr 8) and $FF;
  e_blue := (_1_e_colorRef shr 16) and $FF;
  Result := (e_red shl 16) or (e_green shl 8) or e_blue;
end;

function q4WinPhysicalMemoryKB: Int64;
var
  p_module: HMODULE;
  p_globalMemoryStatusEx: Tq4GlobalMemoryStatusExFunc;
  y_memStatusEx: Tq4MemoryStatusEx;
  y_memStatus: MEMORYSTATUS;
begin
  Result := 0;
  p_globalMemoryStatusEx := nil;
  p_module := Windows.GetModuleHandle(PChar('kernel32.dll'));
  if p_module <> 0 then
    Pointer(p_globalMemoryStatusEx) := Windows.GetProcAddress(p_module, PChar('GlobalMemoryStatusEx'));

  if Assigned(p_globalMemoryStatusEx) then
  begin
    System.FillChar(y_memStatusEx, System.SizeOf(y_memStatusEx), 0);
    y_memStatusEx.dwLength := System.SizeOf(Tq4MemoryStatusEx);
    if p_globalMemoryStatusEx(y_memStatusEx) then
      Exit(Int64(y_memStatusEx.ullTotalPhys div 1024));
  end;

  System.FillChar(y_memStatus, System.SizeOf(y_memStatus), 0);
  Windows.GlobalMemoryStatus(y_memStatus);
  Result := Int64(y_memStatus.dwTotalPhys) div 1024;
end;
{$ENDIF}

Procedure q4CopyTextArray( Const _1_tt_source: Tq4TextArray; out _2_tt_target: Tq4TextArray);
  Var
    e_index: int64;
  Begin
    System.SetLength( _2_tt_target, System.Length( _1_tt_source));
    For e_index := 0 To System.Length( _1_tt_source) - 1 Do _2_tt_target[e_index] := _1_tt_source[e_index];
  End;

Function q4NormalizeImportance( _1_e_importance: int64): int64;
  Begin
    Case _1_e_importance Of
      INFORMATION_MESSAGE, WARNING_MESSAGE, ERROR_MESSAGE: Result := _1_e_importance;
      Else Result := INFORMATION_MESSAGE;
    End;
  End;

Function q4OSName: string;
  Begin
    Result := 'Unknown';
    {$IFDEF WINDOWS}
  Result := 'Windows';
{$ENDIF}
    {$IFDEF DARWIN}
  Result := 'macOS';
{$ENDIF}
    {$IFDEF LINUX}
  Result := 'Linux';
{$ENDIF}
  End;

Function q4OSLanguage: string;
  Var
    t_value:     string;
    e_separator: int64;
  Begin
    t_value := q4FirstEnvironmentValue( ['LC_ALL', 'LANG', 'LANGUAGE']);
    If t_value = '' Then Exit( '');

    e_separator := System.Pos( '.', t_value);
    If e_separator > 0 Then t_value := System.Copy( t_value, 1, e_separator - 1);

    e_separator := System.Pos( '_', t_value);
    If e_separator > 0 Then t_value := System.Copy( t_value, 1, e_separator - 1);

    Result := SysUtils.LowerCase( t_value);
  End;

Function q4DateTokenPosition( Const _1_t_pattern: string; Const _2_t_token: string): string;
  Var
    t_lowerPattern: string;
    e_dayPos:   int64;
    e_monthPos: int64;
    e_yearPos:  int64;
    e_rank:     int64;
  Begin
    t_lowerPattern := SysUtils.LowerCase( _1_t_pattern);
    e_dayPos := System.Pos( 'd', t_lowerPattern);
    e_monthPos := System.Pos( 'm', t_lowerPattern);
    e_yearPos := System.Pos( 'y', t_lowerPattern);
    e_rank := 1;

    If _2_t_token = 'd' Then Begin
      If e_dayPos = 0 Then Exit( '');
      If ( e_monthPos > 0) and ( e_monthPos < e_dayPos) Then System.Inc( e_rank);
      If ( e_yearPos > 0) and ( e_yearPos < e_dayPos) Then System.Inc( e_rank);
      Exit( SysUtils.IntToStr( e_rank));
    End;

    If _2_t_token = 'm' Then Begin
      If e_monthPos = 0 Then Exit( '');
      If ( e_dayPos > 0) and ( e_dayPos < e_monthPos) Then System.Inc( e_rank);
      If ( e_yearPos > 0) and ( e_yearPos < e_monthPos) Then System.Inc( e_rank);
      Exit( SysUtils.IntToStr( e_rank));
    End;

    If _2_t_token = 'y' Then Begin
      If e_yearPos = 0 Then Exit( '');
      If ( e_dayPos > 0) and ( e_dayPos < e_yearPos) Then System.Inc( e_rank);
      If ( e_monthPos > 0) and ( e_monthPos < e_yearPos) Then System.Inc( e_rank);
      Exit( SysUtils.IntToStr( e_rank));
    End;

    Result := '';
  End;

Function q4ReadFirstLine( Const _1_t_fileName: string): string;
  Var
    o_lines: TStringList;
  Begin
    Result := '';
    If not SysUtils.FileExists( _1_t_fileName) Then Exit;

    o_lines := TStringList.Create;
    Try
      Try
        o_lines.LoadFromFile( _1_t_fileName);
        If o_lines.Count > 0 Then Result := o_lines[0];
      Except
        Result := '';
      End;
    Finally
      o_lines.Free;
    End;
  End;

Function q4ReadLinuxCPUModel: string;
  Var
    o_lines: TStringList;
    e_index: int64;
    e_pos:   int64;
    t_line:  string;
  Begin
    Result := '';
    If not SysUtils.FileExists( '/proc/cpuinfo') Then Exit;

    o_lines := TStringList.Create;
    Try
      Try
        o_lines.LoadFromFile( '/proc/cpuinfo');
        For e_index := 0 To o_lines.Count - 1 Do Begin
          t_line := o_lines[e_index];
          If System.Pos( 'model name', SysUtils.LowerCase( t_line)) = 1 Then Begin
            e_pos := System.Pos( ':', t_line);
            If e_pos > 0 Then Exit( SysUtils.Trim( System.Copy( t_line, e_pos + 1, MaxInt)));
          End;
        End;
      Except
        Result := '';
      End;
    Finally
      o_lines.Free;
    End;
  End;

Function q4ReadLinuxCPUThreadCount: int64;
  Var
    o_lines: TStringList;
    e_index: int64;
    t_line:  string;
  Begin
    Result := 0;
    If not SysUtils.FileExists( '/proc/cpuinfo') Then Exit;

    o_lines := TStringList.Create;
    Try
      Try
        o_lines.LoadFromFile( '/proc/cpuinfo');
        For e_index := 0 To o_lines.Count - 1 Do Begin
          t_line := SysUtils.LowerCase( SysUtils.Trim( o_lines[e_index]));
          If System.Pos( 'processor', t_line) = 1 Then System.Inc( Result);
        End;
      Except
        Result := 0;
      End;
    Finally
      o_lines.Free;
    End;
  End;

Function q4ReadLinuxMemTotalKB: int64;
  Var
    o_lines:  TStringList;
    e_index:  int64;
    t_line:   string;
    t_number: string;
    e_pos:    int64;
  Begin
    Result := 0;
    If not SysUtils.FileExists( '/proc/meminfo') Then Exit;

    o_lines := TStringList.Create;
    Try
      Try
        o_lines.LoadFromFile( '/proc/meminfo');
        For e_index := 0 To o_lines.Count - 1 Do Begin
          t_line := SysUtils.Trim( o_lines[e_index]);
          If System.Pos( 'MemTotal:', t_line) = 1 Then Begin
            t_number := SysUtils.Trim( System.Copy( t_line, System.Length( 'MemTotal:') + 1, MaxInt));
            e_pos := System.Pos( ' ', t_number);
            If e_pos > 0 Then t_number := System.Copy( t_number, 1, e_pos - 1);
            Exit( SysUtils.StrToInt64Def( t_number, 0));
          End;
        End;
      Except
        Result := 0;
      End;
    Finally
      o_lines.Free;
    End;
  End;

Function q4ReadLinuxUptimeSeconds: int64;
  Var
    t_line: string;
    e_pos:  int64;
  Begin
    Result := 0;
    t_line := q4ReadFirstLine( '/proc/uptime');
    If t_line = '' Then Exit;
    e_pos := System.Pos( ' ', t_line);
    If e_pos > 0 Then t_line := System.Copy( t_line, 1, e_pos - 1);
    e_pos := System.Pos( '.', t_line);
    If e_pos > 0 Then t_line := System.Copy( t_line, 1, e_pos - 1);
    Result := SysUtils.StrToInt64Def( t_line, 0);
  End;

Function q4CPUThreadsPortable: int64;
  Var
    t_value: string;
  Begin
    t_value := q4FirstEnvironmentValue( ['NUMBER_OF_PROCESSORS']);
    Result := SysUtils.StrToInt64Def( t_value, 0);
  End;

{$IFDEF WINDOWS}
procedure q4NativeFontList(out _1_tt_fonts: Tq4TextArray; const _2_t_mode: string);
var
  y_logFont: LOGFONT;
  p_devCtx: HDC;
  o_list: TStringList;
  e_index: Int64;
begin
  if SysUtils.SameText(_2_t_mode, SysUtils.IntToStr(RECENT_FONTS)) then
  begin
    q4CopyTextArray(tt_recentFonts, _1_tt_fonts);
    Exit;
  end;

  o_list := TStringList.Create;
  o_fontListTarget := o_list;
  try
    p_devCtx := Windows.GetDC(0);
    try
      System.FillChar(y_logFont, System.SizeOf(y_logFont), 0);
      y_logFont.lfCharSet := DEFAULT_CHARSET;
      Windows.EnumFontFamiliesEx(p_devCtx, @y_logFont, @q4WinEnumFontsCallback, 0, 0);
    finally
      Windows.ReleaseDC(0, p_devCtx);
    end;

    o_list.Sort;
    System.SetLength(_1_tt_fonts, o_list.Count);
    for e_index := 0 to o_list.Count - 1 do
      _1_tt_fonts[e_index] := o_list[e_index];
  finally
    o_fontListTarget := nil;
    o_list.Free;
  end;
end;

procedure q4NativeFontStyleList(const _1_t_fontFamily: string; out _2_tt_fontStyleList: Tq4TextArray; out _3_tt_fontNameList: Tq4TextArray);
var
  p_devCtx: HDC;
  y_logFont: LOGFONT;
  o_styles: TStringList;
  o_names: TStringList;
  e_index: Int64;
begin
  o_styles := TStringList.Create;
  o_names := TStringList.Create;
  o_styleList := o_styles;
  o_nameList := o_names;
  try
    p_devCtx := Windows.GetDC(0);
    try
      System.FillChar(y_logFont, System.SizeOf(y_logFont), 0);
      y_logFont.lfCharSet := DEFAULT_CHARSET;
      SysUtils.StrPLCopy(y_logFont.lfFaceName, _1_t_fontFamily, LF_FACESIZE - 1);
      Windows.EnumFontFamiliesEx(p_devCtx, @y_logFont, @q4WinEnumStylesCallback, 0, 0);
    finally
      Windows.ReleaseDC(0, p_devCtx);
    end;

    System.SetLength(_2_tt_fontStyleList, o_styles.Count);
    System.SetLength(_3_tt_fontNameList, o_names.Count);
    for e_index := 0 to o_styles.Count - 1 do
    begin
      _2_tt_fontStyleList[e_index] := o_styles[e_index];
      _3_tt_fontNameList[e_index] := o_names[e_index];
    end;
  finally
    o_styleList := nil;
    o_nameList := nil;
    o_styles.Free;
    o_names.Free;
  end;
end;

function q4NativeFontFile(const _1_t_fontFamily: string; _2_e_fontStyle: Int64): string;
var
  o_reg: TRegistry;
  o_keys: TStringList;
  t_fontFileName: string;
  t_windowsFolder: string;
  e_index: Int64;
begin
  Result := 'null';
  o_reg := TRegistry.Create(KEY_READ);
  try
    o_reg.RootKey := HKEY_LOCAL_MACHINE;
    if o_reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts') then
    begin
      o_keys := TStringList.Create;
      try
        o_reg.GetValueNames(o_keys);
        t_windowsFolder := q4WinGetEnv('WINDIR');
        for e_index := 0 to o_keys.Count - 1 do
        begin
          if System.Pos(SysUtils.LowerCase(_1_t_fontFamily), SysUtils.LowerCase(o_keys[e_index])) = 1 then
          begin
            t_fontFileName := o_reg.ReadString(o_keys[e_index]);
            if SysUtils.ExtractFilePath(t_fontFileName) = '' then
              t_fontFileName := SysUtils.IncludeTrailingPathDelimiter(t_windowsFolder) + 'Fonts\' + t_fontFileName;

            if SysUtils.FileExists(t_fontFileName) then
              Exit('{"path":' + q4JsonString(t_fontFileName) + ',"fontFamily":' + q4JsonString(_1_t_fontFamily) + ',"fontStyle":' + SysUtils.IntToStr(_2_e_fontStyle) + '}');
          end;
        end;
      finally
        o_keys.Free;
      end;
      o_reg.CloseKey;
    end;
  finally
    o_reg.Free;
  end;
end;
{$ENDIF}

Function q4IsFontFileName( Const _1_t_fileName: string): boolean;
  Var
    t_ext: string;
  Begin
    t_ext := SysUtils.LowerCase( SysUtils.ExtractFileExt( _1_t_fileName));
    Result := ( t_ext = '.ttf') or ( t_ext = '.otf') or ( t_ext = '.ttc');
  End;

Procedure q4CollectFileSystemFonts( Const _1_t_dir: string; _2_o_list: TStringList; _3_e_depth: int64);
  Var
    o_search: TSearchRec;
    t_path:   string;
    t_name:   string;
  Begin
    If ( _1_t_dir = '') or ( _3_e_depth < 0) or ( not SysUtils.DirectoryExists( _1_t_dir)) Then Exit;

    If SysUtils.FindFirst( SysUtils.IncludeTrailingPathDelimiter( _1_t_dir) + '*', faAnyFile, o_search) = 0 Then Try
      Repeat
        If ( o_search.Name <> '.') and ( o_search.Name <> '..') Then Begin
          t_path := SysUtils.IncludeTrailingPathDelimiter( _1_t_dir) + o_search.Name;
          If ( ( o_search.Attr and faDirectory) <> 0) Then q4CollectFileSystemFonts( t_path, _2_o_list, _3_e_depth - 1)
          Else If q4IsFontFileName( o_search.Name) Then Begin
            t_name := SysUtils.ChangeFileExt( o_search.Name, '');
            If _2_o_list.IndexOf( t_name) < 0 Then _2_o_list.Add( t_name);
          End;
        End;
      Until SysUtils.FindNext( o_search) <> 0;
    Finally
      SysUtils.FindClose( o_search);
    End;
  End;

Procedure q4FileSystemFontList( out _1_tt_fonts: Tq4TextArray; Const _2_t_dir: string);
  Var
    o_list:  TStringList;
    e_index: int64;
  Begin
    o_list := TStringList.Create;
    Try
      q4CollectFileSystemFonts( _2_t_dir, o_list, 6);
      o_list.Sort;
      System.SetLength( _1_tt_fonts, o_list.Count);
      For e_index := 0 To o_list.Count - 1 Do _1_tt_fonts[e_index] := o_list[e_index];
    Finally
      o_list.Free;
    End;
  End;

Function q4FindFontFileInDir( Const _1_t_dir: string; Const _2_t_normalizedFontFamily: string; _3_e_depth: int64): string;
  Var
    o_search: TSearchRec;
    t_path:   string;
    t_name:   string;
  Begin
    Result := '';
    If ( _1_t_dir = '') or ( _3_e_depth < 0) or ( not SysUtils.DirectoryExists( _1_t_dir)) Then Exit;

    If SysUtils.FindFirst( SysUtils.IncludeTrailingPathDelimiter( _1_t_dir) + '*', faAnyFile, o_search) = 0 Then Try
      Repeat
        If ( o_search.Name <> '.') and ( o_search.Name <> '..') Then Begin
          t_path := SysUtils.IncludeTrailingPathDelimiter( _1_t_dir) + o_search.Name;
          If ( ( o_search.Attr and faDirectory) <> 0) Then Begin
            Result := q4FindFontFileInDir( t_path, _2_t_normalizedFontFamily, _3_e_depth - 1);
            If Result <> '' Then Exit;
          End Else If q4IsFontFileName( o_search.Name) Then Begin
            t_name := q4LowerNoSpaces( SysUtils.ChangeFileExt( o_search.Name, ''));
            If System.Pos( _2_t_normalizedFontFamily, t_name) = 1 Then Exit( t_path);
          End;
        End;
      Until SysUtils.FindNext( o_search) <> 0;
    Finally
      SysUtils.FindClose( o_search);
    End;
  End;

Function q4FileSystemFontFile( Const _1_t_fontFamily: string; _2_e_fontStyle: int64): string;
  Var
    tt_dirs:     Array[0..4] Of string;
    e_dirIndex:  int64;
    t_candidate: string;
    t_normalizedFamily: string;
  Begin
    Result := 'null';
    tt_dirs[0] := '/System/Library/Fonts/';
    tt_dirs[1] := '/Library/Fonts/';
    tt_dirs[2] := q4JoinFolder( q4UserHomeFolder, 'Library/Fonts');
    tt_dirs[3] := '/usr/share/fonts/truetype/';
    tt_dirs[4] := '/usr/share/fonts/';
    t_normalizedFamily := q4LowerNoSpaces( _1_t_fontFamily);
    If t_normalizedFamily = '' Then Exit;

    For e_dirIndex := 0 To 4 Do Begin
      t_candidate := q4FindFontFileInDir( tt_dirs[e_dirIndex], t_normalizedFamily, 6);
      If t_candidate <> '' Then Exit( '{"path":' + q4JsonString( t_candidate) + ',"fontFamily":' + q4JsonString( _1_t_fontFamily) + ',"fontStyle":' + SysUtils.IntToStr( _2_e_fontStyle) + '}');
    End;
  End;

Function countScreens: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/count-screens
    If Assigned( y_bridge.countScreens) Then Exit( y_bridge.countScreens( ));

    {$IFDEF WINDOWS}
  Exit(Windows.GetSystemMetrics(SM_CMONITORS));
{$ENDIF}

    {$IFDEF DARWIN}
  Exit(NSScreen.screens.count);
{$ENDIF}

    q4RaiseNotImplemented( 'countScreens', 'no native screen enumeration is available; register a bridge');
    Result := 0;
  End;

Function currentClientAuthentication: string;
  Var
    t_domain:   string;
    t_protocol: string;
  Begin
    //https://developer.4d.com/docs/21/commands/current-client-authentication
    Result := q4systemEnvironment.currentClientAuthentication( t_domain, t_protocol);
  End;

Function currentClientAuthentication( out _1_t_domain: string; out _2_t_protocol: string): string;
    {$IFDEF WINDOWS}
var
  y_buffer: array[0..255] of Char;
  e_size: DWORD;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/current-client-authentication
    _1_t_domain := '';
    _2_t_protocol := '';

    If Assigned( y_bridge.currentClientAuthentication) Then Exit( y_bridge.currentClientAuthentication( _1_t_domain, _2_t_protocol));

    {$IFDEF WINDOWS}
  // Analyse q4 : sans serveur 4D ni SSO, le fallback natif ne peut pas garantir l'authentification AD.
  // Il expose seulement l'utilisateur local Windows ; un bridge doit fournir le vrai comportement SSO.
  e_size := System.High(y_buffer) + 1;
  if Windows.GetUserName(y_buffer, e_size) then
  begin
    _1_t_domain := q4WinGetEnv('USERDOMAIN');
    Exit(q4WinCharArrayToString(y_buffer));
  end;
{$ENDIF}

    Result := '';
  End;

Function currentMachine: string;
    {$IFDEF WINDOWS}
var
  y_buffer: array[0..255] of Char;
  e_size: DWORD;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/current-machine
    {$IFDEF WINDOWS}
  e_size := System.High(y_buffer) + 1;
  if Windows.GetComputerName(y_buffer, e_size) then
    Exit(q4WinCharArrayToString(y_buffer));
{$ENDIF}

    Result := q4FirstEnvironmentValue( ['HOSTNAME', 'COMPUTERNAME', 'HOST']);
    If Result = '' Then Result := SysUtils.Trim( q4ReadFirstLine( '/etc/hostname'));
  End;

Function currentSystemUser: string;
    {$IFDEF WINDOWS}
var
  y_buffer: array[0..255] of Char;
  e_size: DWORD;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/current-system-user
    {$IFDEF WINDOWS}
  e_size := System.High(y_buffer) + 1;
  if Windows.GetUserName(y_buffer, e_size) then
    Exit(q4WinCharArrayToString(y_buffer));
{$ENDIF}

    {$IFDEF DARWIN}
  Exit(NSStringToString(NSUserName()));
{$ENDIF}

    Result := q4FirstEnvironmentValue( ['USERNAME', 'USER', 'LOGNAME']);
  End;

Function fontFile( Const _1_t_fontFamily: string; _2_e_fontStyle: int64): string;
  Begin
    //https://developer.4d.com/docs/21/commands/font-file
    If Assigned( y_bridge.fontFile) Then Exit( y_bridge.fontFile( _1_t_fontFamily, _2_e_fontStyle));

    {$IFDEF WINDOWS}
  Exit(q4NativeFontFile(_1_t_fontFamily, _2_e_fontStyle));
{$ENDIF}

    Result := q4FileSystemFontFile( _1_t_fontFamily, _2_e_fontStyle);
  End;

Procedure fontList( out _1_tt_fonts: Tq4TextArray);
  Begin
    //https://developer.4d.com/docs/21/commands/font-list
    q4systemEnvironment.fontList( _1_tt_fonts, SYSTEM_FONTS);
  End;

Procedure fontList( out _1_tt_fonts: Tq4TextArray; _2_e_listType: int64);
  Begin
    //https://developer.4d.com/docs/21/commands/font-list
    If _2_e_listType = RECENT_FONTS Then Begin
      q4CopyTextArray( tt_recentFonts, _1_tt_fonts);
      Exit;
    End;

    If Assigned( y_bridge.fontList) Then Begin
      y_bridge.fontList( _1_tt_fonts, SysUtils.IntToStr( _2_e_listType));
      Exit;
    End;

    {$IFDEF WINDOWS}
  q4NativeFontList(_1_tt_fonts, SysUtils.IntToStr(_2_e_listType));
  Exit;
{$ENDIF}

    {$IFDEF DARWIN}
  q4FileSystemFontList(_1_tt_fonts, '/System/Library/Fonts/');
  Exit;
{$ENDIF}

    {$IFDEF LINUX}
  q4FileSystemFontList(_1_tt_fonts, '/usr/share/fonts/');
  Exit;
{$ENDIF}

    q4RaiseNotImplemented( 'fontList', 'font enumeration is not implemented; register a bridge');
  End;

Procedure fontList( out _1_tt_fonts: Tq4TextArray; Const _2_t_star: string);
  Begin
    //https://developer.4d.com/docs/21/commands/font-list
    If Assigned( y_bridge.fontList) Then Begin
      y_bridge.fontList( _1_tt_fonts, _2_t_star);
      Exit;
    End;
    q4systemEnvironment.fontList( _1_tt_fonts, SYSTEM_FONTS);
  End;

Procedure fontStyleList( Const _1_t_fontFamily: string; out _2_tt_fontStyleList: Tq4TextArray; out _3_tt_fontNameList: Tq4TextArray);
  Begin
    //https://developer.4d.com/docs/21/commands/font-style-list
    If Assigned( y_bridge.fontStyleList) Then Begin
      y_bridge.fontStyleList( _1_t_fontFamily, _2_tt_fontStyleList, _3_tt_fontNameList);
      Exit;
    End;

    {$IFDEF WINDOWS}
  q4NativeFontStyleList(_1_t_fontFamily, _2_tt_fontStyleList, _3_tt_fontNameList);
  Exit;
{$ENDIF}

    // Analyse q4 : l'extraction fiable des styles réels dépend des APIs de police de l'OS.
    // Sans bridge spécialisé, q4 renvoie au moins le style normal pour conserver une sortie cohérente.
    System.SetLength( _2_tt_fontStyleList, 1);
    System.SetLength( _3_tt_fontNameList, 1);
    _2_tt_fontStyleList[0] := 'Normal';
    _3_tt_fontNameList[0] := _1_t_fontFamily;
  End;

Procedure getSystemFormat( _1_e_format: int64; out _2_t_value: string);
  Var
    y_formatSettings: TFormatSettings;
    {$IFDEF WINDOWS}
  y_buffer: array[0..255] of Char;
  e_localeType: LCTYPE;
  t_shortDate: string;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/get-system-format
    _2_t_value := '';

    {$IFDEF WINDOWS}
  e_localeType := 0;
  case _1_e_format of
    DECIMAL_SEPARATOR:          e_localeType := LOCALE_SDECIMAL;
    THOUSAND_SEPARATOR:         e_localeType := LOCALE_STHOUSAND;
    CURRENCY_SYMBOL:            e_localeType := LOCALE_SCURRENCY;
    SYSTEM_TIME_SHORT_PATTERN:  e_localeType := LOCALE_STIMEFORMAT;
    SYSTEM_TIME_MEDIUM_PATTERN: e_localeType := LOCALE_STIMEFORMAT;
    SYSTEM_TIME_LONG_PATTERN:   e_localeType := LOCALE_STIMEFORMAT;
    SYSTEM_DATE_SHORT_PATTERN:  e_localeType := LOCALE_SSHORTDATE;
    SYSTEM_DATE_MEDIUM_PATTERN: e_localeType := LOCALE_SLONGDATE;
    SYSTEM_DATE_LONG_PATTERN:   e_localeType := LOCALE_SLONGDATE;
    DATE_SEPARATOR:             e_localeType := LOCALE_SDATE;
    TIME_SEPARATOR:             e_localeType := LOCALE_STIME;
    SYSTEM_TIME_AM_LABEL:       e_localeType := LOCALE_S1159;
    SYSTEM_TIME_PM_LABEL:       e_localeType := LOCALE_S2359;
    SHORT_DATE_DAY_POSITION,
    SHORT_DATE_MONTH_POSITION,
    SHORT_DATE_YEAR_POSITION:
      begin
        if Windows.GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SSHORTDATE, y_buffer, System.High(y_buffer) + 1) > 0 then
          t_shortDate := q4WinCharArrayToString(y_buffer)
        else
          t_shortDate := SysUtils.DefaultFormatSettings.ShortDateFormat;
        case _1_e_format of
          SHORT_DATE_DAY_POSITION:   _2_t_value := q4DateTokenPosition(t_shortDate, 'd');
          SHORT_DATE_MONTH_POSITION: _2_t_value := q4DateTokenPosition(t_shortDate, 'm');
          SHORT_DATE_YEAR_POSITION:  _2_t_value := q4DateTokenPosition(t_shortDate, 'y');
        end;
        Exit;
      end;
  end;

  if e_localeType <> 0 then
  begin
    if Windows.GetLocaleInfo(LOCALE_USER_DEFAULT, e_localeType, y_buffer, System.High(y_buffer) + 1) > 0 then
      _2_t_value := q4WinCharArrayToString(y_buffer);
    Exit;
  end;
{$ENDIF}

    y_formatSettings := SysUtils.DefaultFormatSettings;
    Case _1_e_format Of
      DECIMAL_SEPARATOR: _2_t_value := y_formatSettings.DecimalSeparator;
      THOUSAND_SEPARATOR: _2_t_value := y_formatSettings.ThousandSeparator;
      CURRENCY_SYMBOL: _2_t_value := y_formatSettings.CurrencyString;
      SYSTEM_TIME_SHORT_PATTERN: _2_t_value := y_formatSettings.ShortTimeFormat;
      SYSTEM_TIME_MEDIUM_PATTERN: _2_t_value := y_formatSettings.LongTimeFormat;
      SYSTEM_TIME_LONG_PATTERN: _2_t_value := y_formatSettings.LongTimeFormat;
      SYSTEM_DATE_SHORT_PATTERN: _2_t_value := y_formatSettings.ShortDateFormat;
      SYSTEM_DATE_MEDIUM_PATTERN: _2_t_value := y_formatSettings.LongDateFormat;
      SYSTEM_DATE_LONG_PATTERN: _2_t_value := y_formatSettings.LongDateFormat;
      DATE_SEPARATOR: _2_t_value := y_formatSettings.DateSeparator;
      TIME_SEPARATOR: _2_t_value := y_formatSettings.TimeSeparator;
      SHORT_DATE_DAY_POSITION: _2_t_value := q4DateTokenPosition( y_formatSettings.ShortDateFormat, 'd');
      SHORT_DATE_MONTH_POSITION: _2_t_value := q4DateTokenPosition( y_formatSettings.ShortDateFormat, 'm');
      SHORT_DATE_YEAR_POSITION: _2_t_value := q4DateTokenPosition( y_formatSettings.ShortDateFormat, 'y');
      SYSTEM_TIME_AM_LABEL: _2_t_value := y_formatSettings.TimeAMString;
      SYSTEM_TIME_PM_LABEL: _2_t_value := y_formatSettings.TimePMString;
    End;
  End;

Function isMacOS: boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/is-macos
    {$IFDEF DARWIN}
  Result := True;
{$ELSE}
    Result := False;
    {$ENDIF}
  End;

Function isWindows: boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/is-windows
    {$IFDEF WINDOWS}
  Result := True;
{$ELSE}
    Result := False;
    {$ENDIF}
  End;

Procedure logEvent( Const _1_t_message: string);
  Begin
    //https://developer.4d.com/docs/21/commands/log-event
    q4systemEnvironment.logEvent( INTO_WINDOWS_LOG_EVENTS, _1_t_message, INFORMATION_MESSAGE);
  End;

Procedure logEvent( _1_e_outputType: int64; Const _2_t_message: string; _3_e_importance: int64);
  {$IFDEF WINDOWS}
var
  p_eventLog: THandle;
  p_message: PChar;
  e_windowsType: Word;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/log-event
    _3_e_importance := q4NormalizeImportance( _3_e_importance);

    If Assigned( y_bridge.logEvent) Then Begin
      y_bridge.logEvent( _1_e_outputType, _2_t_message, _3_e_importance);
      Exit;
    End;

    Case _1_e_outputType Of
      INTO_WINDOWS_LOG_EVENTS: q4RaiseNotImplemented( 'logEvent', 'Windows event log is only available on Windows; register a bridge for this target');
        {$IFDEF WINDOWS}
        {$ELSE}
        {$ENDIF}

      INTO_4D_DEBUG_MESSAGE: WriteLn( StdErr, _2_t_message);
        {$IFDEF WINDOWS}
        {$ELSE}
        {$ENDIF}

      INTO_SYSTEM_STD_OUTPUTS: If _3_e_importance = ERROR_MESSAGE Then WriteLn( StdErr, _2_t_message)
        Else
          WriteLn( StdOut, _2_t_message);

      INTO_4D_REQUEST_LOG,
      INTO_4D_COMMANDS_LOG,
      INTO_4D_DIAGNOSTIC_LOG: q4RaiseNotImplemented( 'logEvent', '4D log targets require a bridge/runtime log subsystem');
      Else q4RaiseNotImplemented( 'logEvent', 'unknown outputType=' + SysUtils.IntToStr( _1_e_outputType));
    End;
  End;

Function menuBarHeight: int64;
    {$IFDEF DARWIN}
var
  y_mainScreen: NSScreen;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/menu-bar-height
    If Assigned( y_bridge.menuBarHeight) Then Exit( y_bridge.menuBarHeight( ));

    {$IFDEF WINDOWS}
  Exit(Windows.GetSystemMetrics(SM_CYMENU));
{$ENDIF}

    {$IFDEF DARWIN}
  y_mainScreen := NSScreen.mainScreen;
  if y_mainScreen <> nil then
    Exit(Round(y_mainScreen.frame.size.height - y_mainScreen.visibleFrame.size.height - y_mainScreen.visibleFrame.origin.y));
  Exit(0);
{$ENDIF}

    q4RaiseNotImplemented( 'menuBarHeight', 'no native menu bar API is available; register a bridge');
    Result := 0;
  End;

Function menuBarScreen: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/menu-bar-screen
    If Assigned( y_bridge.menuBarScreen) Then Exit( y_bridge.menuBarScreen( ));

    // Analyse q4 : 4D documente que Windows retourne toujours 1 ; q4 applique aussi 1 par défaut
    // sur les environnements sans API de barre de menus exposée.
    Result := 1;
  End;

Procedure openColorPicker( _1_e_textOrBackground: int64);
  {$IFDEF WINDOWS}
var
  y_chooseColor: Tq4WinChooseColor;
  te_customColors: array[0..15] of COLORREF;
{$ENDIF}
  {$IFDEF DARWIN}
var
  y_colorPanel: NSColorPanel;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/open-color-picker
    If Assigned( y_bridge.openColorPicker) Then Begin
      y_bridge.openColorPicker( _1_e_textOrBackground);
      Exit;
    End;

    {$IFDEF WINDOWS}
  System.FillChar(y_chooseColor, System.SizeOf(y_chooseColor), 0);
  System.FillChar(te_customColors, System.SizeOf(te_customColors), 0);
  y_chooseColor.lStructSize := System.SizeOf(Tq4WinChooseColor);
  y_chooseColor.lpCustColors := @te_customColors[0];
  y_chooseColor.Flags := CC_FULLOPEN or CC_RGBINIT;
  q4WinChooseColor(@y_chooseColor);
  Exit;
{$ENDIF}

    {$IFDEF DARWIN}
  y_colorPanel := NSColorPanel.sharedColorPanel;
  y_colorPanel.orderFront(nil);
  Exit;
{$ENDIF}

    q4RaiseNotImplemented( 'openColorPicker', 'no native color picker is available; register a bridge');
  End;

Procedure openFontPicker;
  {$IFDEF WINDOWS}
var
  y_chooseFont: Tq4WinChooseFont;
  y_logFont: LOGFONT;
{$ENDIF}
  {$IFDEF DARWIN}
var
  y_fontManager: NSFontManager;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/open-font-picker
    If Assigned( y_bridge.openFontPicker) Then Begin
      y_bridge.openFontPicker( );
      Exit;
    End;

    {$IFDEF WINDOWS}
  System.FillChar(y_chooseFont, System.SizeOf(y_chooseFont), 0);
  System.FillChar(y_logFont, System.SizeOf(y_logFont), 0);
  y_chooseFont.lStructSize := System.SizeOf(Tq4WinChooseFont);
  y_chooseFont.lpLogFont := @y_logFont;
  y_chooseFont.Flags := CF_SCREENFONTS or CF_INITTOLOGFONTSTRUCT;
  q4WinChooseFont(@y_chooseFont);
  Exit;
{$ENDIF}

    {$IFDEF DARWIN}
  y_fontManager := NSFontManager.sharedFontManager;
  y_fontManager.orderFrontFontPanel(nil);
  Exit;
{$ENDIF}

    q4RaiseNotImplemented( 'openFontPicker', 'no native font picker is available; register a bridge');
  End;

Procedure screenCoordinates( out _1_e_left: int64; out _2_e_top: int64; out _3_e_right: int64; out _4_e_bottom: int64);
  Begin
    //https://developer.4d.com/docs/21/commands/screen-coordinates
    q4systemEnvironment.screenCoordinates( _1_e_left, _2_e_top, _3_e_right, _4_e_bottom, 1, SCREEN_SIZE);
  End;

Procedure screenCoordinates( out _1_e_left: int64; out _2_e_top: int64; out _3_e_right: int64; out _4_e_bottom: int64; _5_e_screenID: int64; _6_e_screenArea: int64);
  {$IFDEF WINDOWS}
var
  y_monitorInfo: Tq4WinMonitorInfo;
{$ENDIF}
  {$IFDEF DARWIN}
var
  y_screens: NSArray;
  y_screen: NSScreen;
  e_index: Int64;
  y_frame: NSRect;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/screen-coordinates
    If Assigned( y_bridge.screenCoordinates) Then Begin
      y_bridge.screenCoordinates( _1_e_left, _2_e_top, _3_e_right, _4_e_bottom, _5_e_screenID, _6_e_screenArea);
      Exit;
    End;

    _1_e_left := 0;
    _2_e_top := 0;
    _3_e_right := 0;
    _4_e_bottom := 0;

    {$IFDEF WINDOWS}
  if _5_e_screenID < 1 then
    Exit;

  System.FillChar(y_monitorResult, System.SizeOf(y_monitorResult), 0);
  e_monitorTargetIndex := _5_e_screenID;
  e_monitorCurrentIndex := 0;
  b_monitorFound := False;
  q4WinEnumDisplayMonitors(0, nil, @q4WinEnumMonitorCallback, 0);

  if not b_monitorFound then
    Exit;

  y_monitorInfo := y_monitorResult;
    if _6_e_screenArea = SCREEN_WORK_AREA then
    begin
      _1_e_left := y_monitorInfo.rcWork.Left;
      _2_e_top := y_monitorInfo.rcWork.Top;
      _3_e_right := y_monitorInfo.rcWork.Right;
      _4_e_bottom := y_monitorInfo.rcWork.Bottom;
    end
    else
    begin
      _1_e_left := y_monitorInfo.rcMonitor.Left;
      _2_e_top := y_monitorInfo.rcMonitor.Top;
      _3_e_right := y_monitorInfo.rcMonitor.Right;
      _4_e_bottom := y_monitorInfo.rcMonitor.Bottom;
    end;
  Exit;
{$ENDIF}

    {$IFDEF DARWIN}
  y_screens := NSScreen.screens;
  e_index := _5_e_screenID - 1;
  if (e_index < 0) or (e_index >= Int64(y_screens.count)) then
    Exit;
  y_screen := NSScreen(y_screens.objectAtIndex(e_index));
  if _6_e_screenArea = SCREEN_WORK_AREA then
    y_frame := y_screen.visibleFrame
  else
    y_frame := y_screen.frame;
  _1_e_left := Round(y_frame.origin.x);
  _4_e_bottom := Round(y_frame.origin.y);
  _3_e_right := Round(y_frame.origin.x + y_frame.size.width);
  _2_e_top := Round(y_frame.origin.y + y_frame.size.height);
  Exit;
{$ENDIF}

    q4RaiseNotImplemented( 'screenCoordinates', 'no native screen coordinates API is available; register a bridge');
  End;

Procedure screenDepth( out _1_e_depth: int64; out _2_e_color: int64);
  Begin
    //https://developer.4d.com/docs/21/commands/screen-depth
    q4systemEnvironment.screenDepth( _1_e_depth, _2_e_color, 1);
  End;

Procedure screenDepth( out _1_e_depth: int64; out _2_e_color: int64; _3_e_screen: int64);
  {$IFDEF WINDOWS}
var
  p_devCtx: HDC;
{$ENDIF}
  {$IFDEF DARWIN}
var
  y_screens: NSArray;
  y_screen: NSScreen;
  e_index: Int64;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/screen-depth
    If Assigned( y_bridge.screenDepth) Then Begin
      y_bridge.screenDepth( _1_e_depth, _2_e_color, _3_e_screen);
      Exit;
    End;

    {$IFDEF WINDOWS}
  p_devCtx := Windows.GetDC(0);
  try
    _1_e_depth := Windows.GetDeviceCaps(p_devCtx, BITSPIXEL) * Windows.GetDeviceCaps(p_devCtx, PLANES);
    if _1_e_depth <= 1 then
      _2_e_color := IS_GRAY_SCALE
    else
      _2_e_color := IS_COLOR;
  finally
    Windows.ReleaseDC(0, p_devCtx);
  end;
  Exit;
{$ENDIF}

    {$IFDEF DARWIN}
  y_screens := NSScreen.screens;
  e_index := _3_e_screen - 1;
  if (e_index < 0) or (e_index >= Int64(y_screens.count)) then
  begin
    _1_e_depth := 0;
    _2_e_color := 0;
    Exit;
  end;
  y_screen := NSScreen(y_screens.objectAtIndex(e_index));
  _1_e_depth := y_screen.depth;
  if _1_e_depth <= 1 then
    _2_e_color := IS_GRAY_SCALE
  else
    _2_e_color := IS_COLOR;
  Exit;
{$ENDIF}

    q4RaiseNotImplemented( 'screenDepth', 'no native screen depth API is available; register a bridge');
  End;

Function screenHeight( Const _1_t_star: string): int64;
    {$IFDEF DARWIN}
var
  y_screen: NSScreen;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/screen-height
    If Assigned( y_bridge.screenHeight) Then Exit( y_bridge.screenHeight( _1_t_star));

    {$IFDEF WINDOWS}
  if _1_t_star = '*' then
    Exit(Windows.GetSystemMetrics(SM_CYSCREEN));
  Exit(Windows.GetSystemMetrics(SM_CYFULLSCREEN));
{$ENDIF}

    {$IFDEF DARWIN}
  y_screen := NSScreen.mainScreen;
  if y_screen <> nil then
    Exit(Round(y_screen.frame.size.height));
  Exit(0);
{$ENDIF}

    q4RaiseNotImplemented( 'screenHeight', 'no native screen size API is available; register a bridge');
    Result := 0;
  End;

Function screenWidth( Const _1_t_star: string): int64;
    {$IFDEF DARWIN}
var
  y_screen: NSScreen;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/screen-width
    If Assigned( y_bridge.screenWidth) Then Exit( y_bridge.screenWidth( _1_t_star));

    {$IFDEF WINDOWS}
  if _1_t_star = '*' then
    Exit(Windows.GetSystemMetrics(SM_CXSCREEN));
  Exit(Windows.GetSystemMetrics(SM_CXFULLSCREEN));
{$ENDIF}

    {$IFDEF DARWIN}
  y_screen := NSScreen.mainScreen;
  if y_screen <> nil then
    Exit(Round(y_screen.frame.size.width));
  Exit(0);
{$ENDIF}

    q4RaiseNotImplemented( 'screenWidth', 'no native screen size API is available; register a bridge');
    Result := 0;
  End;

Function selectRGBColor( _1_e_defaultColor: int64; Const _2_t_message: string): int64;
    {$IFDEF WINDOWS}
var
  y_chooseColor: Tq4WinChooseColor;
  te_customColors: array[0..15] of COLORREF;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/select-rgb-color
    If Assigned( y_bridge.selectRGBColor) Then Begin
      Result := y_bridge.selectRGBColor( _1_e_defaultColor, _2_t_message);
      q4coreLanguage.OK := 1;
      Exit;
    End;

    {$IFDEF WINDOWS}
  System.FillChar(y_chooseColor, System.SizeOf(y_chooseColor), 0);
  System.FillChar(te_customColors, System.SizeOf(te_customColors), 0);
  y_chooseColor.lStructSize := System.SizeOf(Tq4WinChooseColor);
  y_chooseColor.rgbResult := q4RGBToColorRef(_1_e_defaultColor);
  y_chooseColor.lpCustColors := @te_customColors[0];
  y_chooseColor.Flags := CC_FULLOPEN or CC_RGBINIT;
  if q4WinChooseColor(@y_chooseColor) then
  begin
    q4coreLanguage.OK := 1;
    Exit(q4ColorRefToRGB(y_chooseColor.rgbResult));
  end;
  q4coreLanguage.OK := 0;
  Exit(-1);
{$ENDIF}

    q4RaiseNotImplemented( 'selectRGBColor', 'native modal color selection is not implemented; register a bridge');
    q4coreLanguage.OK := 0;
    Result := -1;
  End;

Procedure setRecentFonts( Const _1_tt_fontsArray: Tq4TextArray);
  Begin
    //https://developer.4d.com/docs/21/commands/set-recent-fonts
    If Assigned( y_bridge.setRecentFonts) Then Begin
      y_bridge.setRecentFonts( _1_tt_fontsArray);
      Exit;
    End;
    q4CopyTextArray( _1_tt_fontsArray, tt_recentFonts);
  End;

Function systemFolder: string;
  Begin
    //https://developer.4d.com/docs/21/commands/system-folder
    Result := q4systemEnvironment.systemFolder( SYSTEM_FOLDER_SYSTEM);
  End;

Function systemFolder( _1_e_type: int64): string;
  Var
    {$IFDEF WINDOWS}
  y_buffer: array[0..MAX_PATH] of Char;
{$ENDIF}
    t_home:    string;
    t_appData: string;
    t_programData: string;
    t_windows: string;
  Begin
    //https://developer.4d.com/docs/21/commands/system-folder
    Result := '';
    t_home := q4UserHomeFolder;
    t_appData := q4FirstEnvironmentValue( ['APPDATA']);
    t_programData := q4FirstEnvironmentValue( ['PROGRAMDATA']);
    t_windows := q4FirstEnvironmentValue( ['WINDIR', 'SystemRoot']);

    {$IFDEF WINDOWS}
  case _1_e_type of
    SYSTEM_FOLDER_SYSTEM:
      if Windows.GetWindowsDirectory(y_buffer, MAX_PATH) > 0 then
        Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)));
    SYSTEM_FOLDER_FONTS:
      if Windows.GetWindowsDirectory(y_buffer, MAX_PATH) > 0 then
        Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)) + 'Fonts\');
    SYSTEM_FOLDER_SYSTEM_WIN,
    SYSTEM_FOLDER_SYSTEM32_WIN:
      if Windows.GetSystemDirectory(y_buffer, MAX_PATH) > 0 then
        Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)));
    SYSTEM_FOLDER_DESKTOP:
      if ShlObj.SHGetSpecialFolderPath(0, y_buffer, CSIDL_DESKTOP, False) then
        Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)));
    SYSTEM_FOLDER_DOCUMENTS:
      if ShlObj.SHGetSpecialFolderPath(0, y_buffer, CSIDL_PERSONAL, False) then
        Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)));
    SYSTEM_FOLDER_APPLICATIONS:
      if ShlObj.SHGetSpecialFolderPath(0, y_buffer, CSIDL_PROGRAM_FILES, False) then
        Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)));
    SYSTEM_FOLDER_HOME:
      Exit(t_home);
    SYSTEM_FOLDER_USER_PREFS_ALL:
      if ShlObj.SHGetSpecialFolderPath(0, y_buffer, CSIDL_COMMON_APPDATA, False) then
        Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)));
    SYSTEM_FOLDER_USER_PREFS_USER:
      if ShlObj.SHGetSpecialFolderPath(0, y_buffer, CSIDL_APPDATA, False) then
        Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)));
    SYSTEM_FOLDER_STARTUP_WIN_ALL:
      if ShlObj.SHGetSpecialFolderPath(0, y_buffer, CSIDL_COMMON_STARTUP, False) then
        Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)));
    SYSTEM_FOLDER_STARTUP_WIN_USER:
      if ShlObj.SHGetSpecialFolderPath(0, y_buffer, CSIDL_STARTUP, False) then
        Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)));
    SYSTEM_FOLDER_START_MENU_WIN_ALL:
      if ShlObj.SHGetSpecialFolderPath(0, y_buffer, CSIDL_COMMON_PROGRAMS, False) then
        Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)));
    SYSTEM_FOLDER_START_MENU_WIN_USER:
      if ShlObj.SHGetSpecialFolderPath(0, y_buffer, CSIDL_PROGRAMS, False) then
        Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)));
    SYSTEM_FOLDER_FAVORITES_WIN:
      if ShlObj.SHGetSpecialFolderPath(0, y_buffer, CSIDL_FAVORITES, False) then
        Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)));
  end;
{$ENDIF}

    Case _1_e_type Of
      SYSTEM_FOLDER_SYSTEM: Result := '/';
        {$IFDEF DARWIN}
        {$ELSE}
        {$IFDEF WINDOWS}
        {$ELSE}
        {$ENDIF}
        {$ENDIF}
      SYSTEM_FOLDER_FONTS: Result := '/usr/share/fonts/';
        {$IFDEF DARWIN}
        {$ELSE}
        {$IFDEF WINDOWS}
        {$ELSE}
        {$ENDIF}
        {$ENDIF}
      SYSTEM_FOLDER_USER_PREFS_ALL: Result := '/etc/';
        {$IFDEF DARWIN}
        {$ELSE}
        {$IFDEF WINDOWS}
        {$ELSE}
        {$ENDIF}
        {$ENDIF}
      SYSTEM_FOLDER_USER_PREFS_USER: Result := q4JoinFolder( t_home, '.config');
        {$IFDEF DARWIN}
        {$ELSE}
        {$IFDEF WINDOWS}
        {$ELSE}
        {$ENDIF}
        {$ENDIF}
      SYSTEM_FOLDER_STARTUP_WIN_ALL,
      SYSTEM_FOLDER_STARTUP_WIN_USER,
      SYSTEM_FOLDER_START_MENU_WIN_ALL,
      SYSTEM_FOLDER_START_MENU_WIN_USER,
      SYSTEM_FOLDER_SYSTEM_WIN,
      SYSTEM_FOLDER_SYSTEM32_WIN,
      SYSTEM_FOLDER_FAVORITES_WIN: Result := '';
      SYSTEM_FOLDER_DESKTOP: Result := q4JoinFolder( t_home, 'Desktop');
      SYSTEM_FOLDER_APPLICATIONS: Result := '/usr/share/applications/';
        {$IFDEF DARWIN}
        {$ELSE}
        {$IFDEF WINDOWS}
        {$ELSE}
        {$ENDIF}
        {$ENDIF}
      SYSTEM_FOLDER_DOCUMENTS: Result := q4JoinFolder( t_home, 'Documents');
      SYSTEM_FOLDER_HOME: Result := t_home;
      Else q4RaiseNotImplemented( 'systemFolder', 'unknown folder type=' + SysUtils.IntToStr( _1_e_type));
    End;
  End;

Function systemInfo: string;
  Var
    {$IFDEF WINDOWS}
  y_osVersionInfo: OSVERSIONINFO;
  o_reg: TRegistry;
  y_systemInfo: SYSTEM_INFO;
  y_buffer: array[0..255] of Char;
  e_lcid: LCID;
{$ENDIF}
    {$IFDEF DARWIN}
  y_processInfo: NSProcessInfo;
  y_version: NSOperatingSystemVersion;
  y_locale: NSLocale;
  y_langCode: NSString;
{$ENDIF}
    t_machineName: string;
    t_userName:   string;
    t_accountName: string;
    t_model:      string;
    t_osVersion:  string;
    t_osLanguage: string;
    t_processor:  string;
    e_cores:      int64;
    e_cpuThreads: int64;
    e_physicalMemory: int64;
    e_uptime:     int64;
    b_macRosetta: boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/system-info
    If Assigned( y_bridge.systemInfo) Then Exit( y_bridge.systemInfo( ));

    t_machineName := q4systemEnvironment.currentMachine;
    t_userName := q4systemEnvironment.currentSystemUser;
    t_accountName := t_userName;
    t_model := '';
    t_osVersion := q4OSName;
    t_osLanguage := q4OSLanguage;
    t_processor := '';
    e_cores := q4CPUThreadsPortable;
    e_cpuThreads := e_cores;
    e_physicalMemory := 0;
    e_uptime := 0;
    b_macRosetta := False;

    {$IFDEF WINDOWS}
  System.FillChar(y_osVersionInfo, System.SizeOf(y_osVersionInfo), 0);
  y_osVersionInfo.dwOSVersionInfoSize := System.SizeOf(OSVERSIONINFO);
  if Windows.GetVersionEx(y_osVersionInfo) then
    t_osVersion := SysUtils.Format('Windows %d.%d (Build %d)', [y_osVersionInfo.dwMajorVersion, y_osVersionInfo.dwMinorVersion, y_osVersionInfo.dwBuildNumber]);

  o_reg := TRegistry.Create(KEY_READ);
  try
    o_reg.RootKey := HKEY_LOCAL_MACHINE;
    if o_reg.OpenKeyReadOnly('HARDWARE\DESCRIPTION\System\CentralProcessor\0') then
    begin
      t_processor := o_reg.ReadString('ProcessorNameString');
      o_reg.CloseKey;
    end;
  finally
    o_reg.Free;
  end;

  Windows.GetSystemInfo(y_systemInfo);
  e_cores := y_systemInfo.dwNumberOfProcessors;
  e_cpuThreads := y_systemInfo.dwNumberOfProcessors;

  e_physicalMemory := q4WinPhysicalMemoryKB;
  e_uptime := Windows.GetTickCount64 div 1000;

  e_lcid := Windows.GetUserDefaultLCID;
  if Windows.GetLocaleInfo(e_lcid, LOCALE_SISO639LANGNAME, y_buffer, System.High(y_buffer) + 1) > 0 then
    t_osLanguage := q4WinCharArrayToString(y_buffer);
{$ENDIF}

    {$IFDEF DARWIN}
  y_processInfo := NSProcessInfo.processInfo;
  y_version := y_processInfo.operatingSystemVersion;
  t_osVersion := SysUtils.Format('macOS %d.%d.%d', [Int64(y_version.majorVersion), Int64(y_version.minorVersion), Int64(y_version.patchVersion)]);
  e_cores := y_processInfo.processorCount;
  e_cpuThreads := y_processInfo.activeProcessorCount;
  e_physicalMemory := y_processInfo.physicalMemory div 1024;
  e_uptime := Round(y_processInfo.systemUptime);

  y_locale := NSLocale.currentLocale;
  y_langCode := NSString(y_locale.objectForKey(NSLocaleLanguageCode));
  t_osLanguage := NSStringToString(y_langCode);
{$ENDIF}

    {$IFDEF LINUX}
  t_processor := q4ReadLinuxCPUModel;
  e_cpuThreads := q4ReadLinuxCPUThreadCount;
  e_cores := e_cpuThreads;
  e_physicalMemory := q4ReadLinuxMemTotalKB;
  e_uptime := q4ReadLinuxUptimeSeconds;
{$ENDIF}

    // Analyse q4 : la spec q4 v1.x mappe Object vers string JSON. Les collections détaillées
    // networkInterfaces et volumes sont gardées vides tant que le runtime OS n'est pas branché.
    Result := '{' + '"machineName":' + q4JsonString( t_machineName) + ',' + '"userName":' + q4JsonString( t_userName) + ',' + '"accountName":' +
      q4JsonString( t_accountName) + ',' + '"macRosetta":' + SysUtils.LowerCase( SysUtils.BoolToStr( b_macRosetta, True)) + ',' + '"model":' +
      q4JsonString( t_model) + ',' + '"osVersion":' + q4JsonString( t_osVersion) + ',' + '"osLanguage":' + q4JsonString( t_osLanguage) + ',' + '"processor":' +
      q4JsonString( t_processor) + ',' + '"cores":' + SysUtils.IntToStr( e_cores) + ',' + '"cpuThreads":' + SysUtils.IntToStr( e_cpuThreads) + ',' +
      '"physicalMemory":' + SysUtils.IntToStr( e_physicalMemory) + ',' + '"uptime":' + SysUtils.IntToStr( e_uptime) + ',' + '"networkInterfaces":[],' + '"volumes":[]' + '}';
  End;

Function temporaryFolder: string;
    {$IFDEF WINDOWS}
var
  y_buffer: array[0..MAX_PATH] of Char;
{$ENDIF}
  Begin
    //https://developer.4d.com/docs/21/commands/temporary-folder
    {$IFDEF WINDOWS}
  if Windows.GetTempPath(MAX_PATH, y_buffer) > 0 then
    Exit(SysUtils.IncludeTrailingPathDelimiter(q4WinCharArrayToString(y_buffer)));
{$ENDIF}
    Result := SysUtils.IncludeTrailingPathDelimiter( SysUtils.GetTempDir);
  End;

Procedure registerBridge( Const _1_y_bridgeValue: Tq4SystemEnvironmentBridge);
  Begin
    y_bridge := _1_y_bridgeValue;
  End;

Procedure resetBridge;
  Begin
    System.FillChar( y_bridge, System.SizeOf( y_bridge), 0);
  End;

Initialization
  System.SetLength( tt_recentFonts, 0);
  q4systemEnvironment.resetBridge;
  {$IFDEF WINDOWS}
  o_fontListTarget := nil;
  o_styleList := nil;
  o_nameList := nil;
{$ENDIF}

End.
