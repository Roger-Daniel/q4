unit q4userInterface;

{$mode objfpc}{$H+}

{
q4userInterface
version du 2026/05/15-00:00

Mapping 4D -> q4userInterface -> statut
Command Number 4D,    4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
151,                  BEEP,                              beep,                             OK spécifique
547,                  Caps lock down,                    capsLockDown,                     TODO explicite
278,                  Focus object,                      focusObject,                      TODO explicite
1763,                 Get Application color scheme,      getApplicationColorScheme,        OK spécifique
804,                  GET FIELD TITLES,                  getFieldTitles,                   OK spécifique
803,                  GET TABLE TITLES,                  getTableTitles,                   OK spécifique
432,                  HIDE MENU BAR,                     hideMenuBar,                      Partial
546,                  Macintosh command down,            macintoshCommandDown,             TODO explicite
544,                  Macintosh control down,            macintoshControlDown,             TODO explicite
545,                  Macintosh option down,             macintoshOptionDown,              TODO explicite
468,                  MOUSE POSITION,                    mousePosition,                    TODO explicite
290,                  PLAY,                              play,                             TODO explicite
542,                  Pop up menu,                       popUpMenu,                        Partial
466,                  POST CLICK,                        postClick,                        TODO explicite
467,                  POST EVENT,                        postEvent,                        TODO explicite
465,                  POST KEY,                          postKey,                          TODO explicite
174,                  REDRAW,                            redraw,                           TODO explicite
316,                  SET ABOUT,                         setAbout,                         OK spécifique
1762,                 SET APPLICATION COLOR SCHEME,      setApplicationColorScheme,        OK spécifique
469,                  SET CURSOR,                        setCursor,                        TODO explicite
602,                  SET FIELD TITLES,                  setFieldTitles,                   OK spécifique
601,                  SET TABLE TITLES,                  setTableTitles,                   OK spécifique
543,                  Shift down,                        shiftDown,                        TODO explicite
431,                  SHOW MENU BAR,                     showMenuBar,                      Partial
563,                  Windows Alt down,                  windowsAltDown,                   TODO explicite
562,                  Windows Ctrl down,                 windowsCtrlDown,                  TODO explicite

Doc: https://developer.4d.com/docs/21/commands/theme/User-Interface

Notes q4:
- Les commandes nécessitant un vrai backend UI / boucle événementielle Lazarus échouent explicitement.
- Les titres de tables/champs sont stockés par thread, conformément au modèle process q4.
- SET TABLE TITLES sans paramètre réinitialise aussi les titres virtuels des champs.
- La visibilité réelle des tables est déléguée à q4DBschemaUse.tableIsVisibleInUserInterface.
  Tant que TTableMeta.InvisibleUI n'existe pas, q4DBschemaUse centralise l'approximation.
}

interface

uses
  SysUtils;

type
  TQ4TextArray = array of string;
  TQ4IntegerArray = array of Int64;

const
  Q4_APPLICATION_COLOR_SCHEME_LIGHT = 'light';
  Q4_APPLICATION_COLOR_SCHEME_DARK = 'dark';
  Q4_APPLICATION_COLOR_SCHEME_INHERITED = 'inherited';

  Q4_MOUSE_DOWN_EVENT = 1;
  Q4_MOUSE_UP_EVENT = 2;
  Q4_KEY_DOWN_EVENT = 3;
  Q4_KEY_UP_EVENT = 4;
  Q4_AUTO_KEY_EVENT = 5;

  Q4_ACTIVATE_WINDOW_BIT = 0;
  Q4_ACTIVATE_WINDOW_MASK = 1;
  Q4_MOUSE_BUTTON_BIT = 7;
  Q4_MOUSE_BUTTON_MASK = 128;
  Q4_COMMAND_KEY_BIT = 8;
  Q4_COMMAND_KEY_MASK = 256;
  Q4_SHIFT_KEY_BIT = 9;
  Q4_SHIFT_KEY_MASK = 512;
  Q4_CAPS_LOCK_KEY_BIT = 10;
  Q4_CAPS_LOCK_KEY_MASK = 1024;
  Q4_OPTION_KEY_BIT = 11;
  Q4_OPTION_KEY_MASK = 2048;
  Q4_CONTROL_KEY_BIT = 12;
  Q4_CONTROL_KEY_MASK = 4096;
  Q4_RIGHT_SHIFT_KEY_BIT = 13;
  Q4_RIGHT_SHIFT_KEY_MASK = 8192;
  Q4_RIGHT_OPTION_KEY_BIT = 14;
  Q4_RIGHT_OPTION_KEY_MASK = 16384;
  Q4_RIGHT_CONTROL_KEY_BIT = 15;
  Q4_RIGHT_CONTROL_KEY_MASK = 32768;

procedure beep;

function capsLockDown: Boolean;
function focusObject: Pointer;

function getApplicationColorScheme: string; overload;
function getApplicationColorScheme(const _1_t_star: string): string; overload;

procedure getFieldTitles(
  _1_p_table: Pointer;
  out _2_tt_fieldTitles: TQ4TextArray;
  out _3_te_fieldNumbers: TQ4IntegerArray
);

procedure getTableTitles(
  out _1_tt_tableTitles: TQ4TextArray;
  out _2_te_tableNumbers: TQ4IntegerArray
);

procedure hideMenuBar;

function macintoshCommandDown: Boolean;
function macintoshControlDown: Boolean;
function macintoshOptionDown: Boolean;

procedure mousePosition(
  out _1_r_mouseX: Double;
  out _2_r_mouseY: Double;
  out _3_e_mouseButton: Int64
); overload;

procedure mousePosition(
  out _1_r_mouseX: Double;
  out _2_r_mouseY: Double;
  out _3_e_mouseButton: Int64;
  const _4_t_star: string
); overload;

procedure play(const _1_t_objectName: string); overload;
procedure play(const _1_t_objectName: string; _2_e_async: Int64); overload;

function popUpMenu(const _1_t_contents: string): Int64; overload;
function popUpMenu(const _1_t_contents: string; _2_e_default: Int64): Int64; overload;
function popUpMenu(
  const _1_t_contents: string;
  _2_e_default: Int64;
  _3_e_xCoord: Int64;
  _4_e_yCoord: Int64
): Int64; overload;

procedure postClick(_1_e_mouseX: Int64; _2_e_mouseY: Int64); overload;
procedure postClick(_1_e_mouseX: Int64; _2_e_mouseY: Int64; const _3_t_star: string); overload;
procedure postClick(_1_e_mouseX: Int64; _2_e_mouseY: Int64; _3_e_process: Int64); overload;
procedure postClick(_1_e_mouseX: Int64; _2_e_mouseY: Int64; _3_e_process: Int64; const _4_t_star: string); overload;

procedure postEvent(
  _1_e_what: Int64;
  _2_e_message: Int64;
  _3_e_when: Int64;
  _4_e_mouseX: Int64;
  _5_e_mouseY: Int64;
  _6_e_modifiers: Int64
); overload;

procedure postEvent(
  _1_e_what: Int64;
  _2_e_message: Int64;
  _3_e_when: Int64;
  _4_e_mouseX: Int64;
  _5_e_mouseY: Int64;
  _6_e_modifiers: Int64;
  _7_e_process: Int64
); overload;

procedure postKey(_1_e_code: Int64); overload;
procedure postKey(_1_e_code: Int64; _2_e_modifiers: Int64); overload;
procedure postKey(_1_e_code: Int64; _2_e_modifiers: Int64; _3_e_process: Int64); overload;

procedure redraw(_1_p_object: Pointer);

procedure setAbout(const _1_t_itemText: string; const _2_t_method: string);
procedure setApplicationColorScheme(const _1_t_colorScheme: string);

procedure setCursor; overload;
procedure setCursor(_1_e_cursor: Int64); overload;

procedure setFieldTitles(
  _1_p_table: Pointer;
  const _2_tt_fieldTitles: TQ4TextArray;
  const _3_te_fieldNumbers: TQ4IntegerArray;
  const _4_t_star: string = ''
);

procedure setTableTitles; overload;
procedure setTableTitles(
  const _1_tt_tableTitles: TQ4TextArray;
  const _2_te_tableNumbers: TQ4IntegerArray;
  const _3_t_star: string = ''
); overload;

function shiftDown: Boolean;
procedure showMenuBar;
function windowsAltDown: Boolean;
function windowsCtrlDown: Boolean;

implementation

uses
  metier_q4DBschemaBase,
  q4DBschemaUse,
  q4interruptions,
  q4menus;

type
  TQ4VirtualTableTitle = record
    _e_sourceTableId: Int64;
    _t_title: string;
    _b_useInFormulaEditor: Boolean;
  end;

  TQ4VirtualTableTitleArray = array of TQ4VirtualTableTitle;

  TQ4VirtualFieldTitle = record
    _e_fieldNo: Int64;
    _t_title: string;
    _b_useInFormulaEditor: Boolean;
  end;

  TQ4VirtualFieldTitleArray = array of TQ4VirtualFieldTitle;

  TQ4VirtualFieldTitleSet = record
    _e_sourceTableId: Int64;
    _ty_fields: TQ4VirtualFieldTitleArray;
  end;

  TQ4VirtualFieldTitleSetArray = array of TQ4VirtualFieldTitleSet;

threadvar
  gt_applicationColorScheme: string;
  gb_hasVirtualTableTitles: Boolean;
  gy_virtualTableTitles: TQ4VirtualTableTitleArray;
  gy_virtualFieldTitleSets: TQ4VirtualFieldTitleSetArray;

function q4HasStarParameter(const _1_t_star: string): Boolean;
begin
  if (_1_t_star = '') then
    Exit(False);

  if (_1_t_star = '*') then
    Exit(True);

  q4interruptions.assertRaise(
    'Invalid * parameter for q4userInterface command',
    {$I %CURRENTROUTINE%},
    {$I %LINENUM%}
  );
  Result := False;
end;

procedure q4Unsupported(const _1_t_apiName: string);
begin
  q4interruptions.assertRaise(
    'q4userInterface.' + _1_t_apiName + ' is not implemented without a UI backend',
    {$I %CURRENTROUTINE%},
    {$I %LINENUM%}
  );
end;

procedure q4AppendTableTitle(
  var _1_tt_tableTitles: TQ4TextArray;
  var _2_te_tableNumbers: TQ4IntegerArray;
  const _3_t_title: string;
  _4_e_tableNumber: Int64
);
var
  _e_index: Int64;
begin
  _e_index := System.Length(_1_tt_tableTitles);
  System.SetLength(_1_tt_tableTitles, _e_index + 1);
  System.SetLength(_2_te_tableNumbers, _e_index + 1);
  _1_tt_tableTitles[_e_index] := _3_t_title;
  _2_te_tableNumbers[_e_index] := _4_e_tableNumber;
end;

procedure q4AppendFieldTitle(
  var _1_tt_fieldTitles: TQ4TextArray;
  var _2_te_fieldNumbers: TQ4IntegerArray;
  const _3_t_title: string;
  _4_e_fieldNumber: Int64
);
var
  _e_index: Int64;
begin
  _e_index := System.Length(_1_tt_fieldTitles);
  System.SetLength(_1_tt_fieldTitles, _e_index + 1);
  System.SetLength(_2_te_fieldNumbers, _e_index + 1);
  _1_tt_fieldTitles[_e_index] := _3_t_title;
  _2_te_fieldNumbers[_e_index] := _4_e_fieldNumber;
end;

function q4FindVirtualFieldTitleSetIndex(_1_e_sourceTableId: Int64): Int64;
var
  _e_i: Int64;
begin
  Result := -1;

  for _e_i := 0 to System.High(gy_virtualFieldTitleSets) do
    if (gy_virtualFieldTitleSets[_e_i]._e_sourceTableId = _1_e_sourceTableId) then
      Exit(_e_i);
end;

function q4ValidColorScheme(const _1_t_colorScheme: string): Boolean;
begin
  Result :=
    SysUtils.SameText(_1_t_colorScheme, Q4_APPLICATION_COLOR_SCHEME_LIGHT) or
    SysUtils.SameText(_1_t_colorScheme, Q4_APPLICATION_COLOR_SCHEME_DARK) or
    SysUtils.SameText(_1_t_colorScheme, Q4_APPLICATION_COLOR_SCHEME_INHERITED);
end;

procedure beep;
begin
  //https://developer.4d.com/docs/21/commands/beep
  // q4: émission simple du caractère BEL. L'effet réel dépend de l'environnement d'exécution.
  System.Write(#7);
end;

function capsLockDown: Boolean;
begin
  //https://developer.4d.com/docs/21/commands/caps-lock-down
  q4Unsupported('capsLockDown');
  Result := False;
end;

function focusObject: Pointer;
begin
  //https://developer.4d.com/docs/21/commands/focus-object
  q4Unsupported('focusObject');
  Result := nil;
end;

function getApplicationColorScheme: string;
begin
  //https://developer.4d.com/docs/21/commands/get-application-color-scheme
  Result := q4userInterface.getApplicationColorScheme('');
end;

function getApplicationColorScheme(const _1_t_star: string): string;
begin
  //https://developer.4d.com/docs/21/commands/get-application-color-scheme
  q4HasStarParameter(_1_t_star);

  {$IFDEF WINDOWS}
  // 4D retourne toujours "light" sous Windows.
  Result := Q4_APPLICATION_COLOR_SCHEME_LIGHT;
  {$ELSE}
  if ((gt_applicationColorScheme = '') or
     SysUtils.SameText(gt_applicationColorScheme, Q4_APPLICATION_COLOR_SCHEME_INHERITED)) then
    Result := Q4_APPLICATION_COLOR_SCHEME_LIGHT
  else
    Result := gt_applicationColorScheme;
  {$ENDIF}
end;

procedure getFieldTitles(
  _1_p_table: Pointer;
  out _2_tt_fieldTitles: TQ4TextArray;
  out _3_te_fieldNumbers: TQ4IntegerArray
);
var
  _e_sourceTableId: Int64;
  _e_fieldSetIndex: Int64;
  _e_i: Int64;
  _y_table: TTableMeta;
  _y_field: TFieldMeta;
begin
  //https://developer.4d.com/docs/21/commands/get-field-titles
  System.SetLength(_2_tt_fieldTitles, 0);
  System.SetLength(_3_te_fieldNumbers, 0);

  if (not q4DBschemaUse.resolveTablePointerToSourceTableId(_1_p_table, _e_sourceTableId)) then
    q4interruptions.assertRaise(
      'Invalid table pointer in q4userInterface.getFieldTitles',
      {$I %CURRENTROUTINE%},
      {$I %LINENUM%}
    );

  _e_fieldSetIndex := q4FindVirtualFieldTitleSetIndex(_e_sourceTableId);

  if (_e_fieldSetIndex >= 0) then
  begin
    for _e_i := 0 to System.High(gy_virtualFieldTitleSets[_e_fieldSetIndex]._ty_fields) do
      if (q4DBschemaUse.findFieldMetaByFieldNo(
        _e_sourceTableId,
        gy_virtualFieldTitleSets[_e_fieldSetIndex]._ty_fields[_e_i]._e_fieldNo,
        _y_field
      ) and q4DBschemaUse.fieldIsVisibleInUserInterface(_y_field)) then
        q4AppendFieldTitle(
          _2_tt_fieldTitles,
          _3_te_fieldNumbers,
          gy_virtualFieldTitleSets[_e_fieldSetIndex]._ty_fields[_e_i]._t_title,
          gy_virtualFieldTitleSets[_e_fieldSetIndex]._ty_fields[_e_i]._e_fieldNo
        );
    Exit;
  end;

  if (not q4DBschemaUse.findTableMeta(_e_sourceTableId, _y_table)) then
    q4interruptions.assertRaise(
      'Unknown table in q4userInterface.getFieldTitles',
      {$I %CURRENTROUTINE%},
      {$I %LINENUM%}
    );

  for _e_i := 0 to _y_table.FieldCount - 1 do
    if (q4DBschemaUse.findFieldMetaAtTableOffset(_e_sourceTableId, _e_i, _y_field) and
       q4DBschemaUse.fieldIsVisibleInUserInterface(_y_field)) then
      q4AppendFieldTitle(_2_tt_fieldTitles, _3_te_fieldNumbers, _y_field.Name, _y_field.FieldNo);
end;

procedure getTableTitles(
  out _1_tt_tableTitles: TQ4TextArray;
  out _2_te_tableNumbers: TQ4IntegerArray
);
var
  _e_i: Int64;
  _e_count: Int64;
  _y_table: TTableMeta;
begin
  //https://developer.4d.com/docs/21/commands/get-table-titles
  System.SetLength(_1_tt_tableTitles, 0);
  System.SetLength(_2_te_tableNumbers, 0);

  if (gb_hasVirtualTableTitles) then
  begin
    for _e_i := 0 to System.High(gy_virtualTableTitles) do
      if (q4DBschemaUse.tableIsVisibleInUserInterface(gy_virtualTableTitles[_e_i]._e_sourceTableId)) then
        q4AppendTableTitle(
          _1_tt_tableTitles,
          _2_te_tableNumbers,
          gy_virtualTableTitles[_e_i]._t_title,
          gy_virtualTableTitles[_e_i]._e_sourceTableId
        );
    Exit;
  end;

  _e_count := q4DBschemaUse.getTableCount;
  for _e_i := 0 to _e_count - 1 do
    if (q4DBschemaUse.getTableMetaAtIndex(_e_i, _y_table) and
       q4DBschemaUse.tableIsVisibleInUserInterface(_y_table.SourceTableId)) then
      q4AppendTableTitle(_1_tt_tableTitles, _2_te_tableNumbers, _y_table.Name, _y_table.SourceTableId);
end;

procedure hideMenuBar;
begin
  //https://developer.4d.com/docs/21/commands/hide-menu-bar
  q4menus.setMenuBarVisible(False);
end;

function macintoshCommandDown: Boolean;
begin
  //https://developer.4d.com/docs/21/commands/macintosh-command-down
  q4Unsupported('macintoshCommandDown');
  Result := False;
end;

function macintoshControlDown: Boolean;
begin
  //https://developer.4d.com/docs/21/commands/macintosh-control-down
  q4Unsupported('macintoshControlDown');
  Result := False;
end;

function macintoshOptionDown: Boolean;
begin
  //https://developer.4d.com/docs/21/commands/macintosh-option-down
  q4Unsupported('macintoshOptionDown');
  Result := False;
end;

procedure mousePosition(
  out _1_r_mouseX: Double;
  out _2_r_mouseY: Double;
  out _3_e_mouseButton: Int64
);
begin
  //https://developer.4d.com/docs/21/commands/mouse-position
  q4userInterface.mousePosition(_1_r_mouseX, _2_r_mouseY, _3_e_mouseButton, '');
end;

procedure mousePosition(
  out _1_r_mouseX: Double;
  out _2_r_mouseY: Double;
  out _3_e_mouseButton: Int64;
  const _4_t_star: string
);
begin
  //https://developer.4d.com/docs/21/commands/mouse-position
  q4HasStarParameter(_4_t_star);
  q4Unsupported('mousePosition');
  _1_r_mouseX := 0;
  _2_r_mouseY := 0;
  _3_e_mouseButton := 0;
end;

procedure play(const _1_t_objectName: string);
begin
  //https://developer.4d.com/docs/21/commands/play
  q4userInterface.play(_1_t_objectName, 0);
end;

procedure play(const _1_t_objectName: string; _2_e_async: Int64);
begin
  //https://developer.4d.com/docs/21/commands/play
  q4Unsupported('play');
end;

function popUpMenu(const _1_t_contents: string): Int64;
begin
  //https://developer.4d.com/docs/21/commands/pop-up-menu
  Result := q4menus.popUpMenuEmulation(_1_t_contents);
end;

function popUpMenu(const _1_t_contents: string; _2_e_default: Int64): Int64;
begin
  //https://developer.4d.com/docs/21/commands/pop-up-menu
  Result := q4menus.popUpMenuEmulation(_1_t_contents, _2_e_default);
end;

function popUpMenu(
  const _1_t_contents: string;
  _2_e_default: Int64;
  _3_e_xCoord: Int64;
  _4_e_yCoord: Int64
): Int64;
begin
  //https://developer.4d.com/docs/21/commands/pop-up-menu
  Result := q4menus.popUpMenuEmulation(_1_t_contents, _2_e_default, _3_e_xCoord, _4_e_yCoord);
end;

procedure postClick(_1_e_mouseX: Int64; _2_e_mouseY: Int64);
begin
  //https://developer.4d.com/docs/21/commands/post-click
  q4userInterface.postClick(_1_e_mouseX, _2_e_mouseY, 0, '');
end;

procedure postClick(_1_e_mouseX: Int64; _2_e_mouseY: Int64; const _3_t_star: string);
begin
  //https://developer.4d.com/docs/21/commands/post-click
  q4userInterface.postClick(_1_e_mouseX, _2_e_mouseY, 0, _3_t_star);
end;

procedure postClick(_1_e_mouseX: Int64; _2_e_mouseY: Int64; _3_e_process: Int64);
begin
  //https://developer.4d.com/docs/21/commands/post-click
  q4userInterface.postClick(_1_e_mouseX, _2_e_mouseY, _3_e_process, '');
end;

procedure postClick(_1_e_mouseX: Int64; _2_e_mouseY: Int64; _3_e_process: Int64; const _4_t_star: string);
begin
  //https://developer.4d.com/docs/21/commands/post-click
  q4HasStarParameter(_4_t_star);
  q4Unsupported('postClick');
end;

procedure postEvent(
  _1_e_what: Int64;
  _2_e_message: Int64;
  _3_e_when: Int64;
  _4_e_mouseX: Int64;
  _5_e_mouseY: Int64;
  _6_e_modifiers: Int64
);
begin
  //https://developer.4d.com/docs/21/commands/post-event
  q4userInterface.postEvent(
    _1_e_what,
    _2_e_message,
    _3_e_when,
    _4_e_mouseX,
    _5_e_mouseY,
    _6_e_modifiers,
    0
  );
end;

procedure postEvent(
  _1_e_what: Int64;
  _2_e_message: Int64;
  _3_e_when: Int64;
  _4_e_mouseX: Int64;
  _5_e_mouseY: Int64;
  _6_e_modifiers: Int64;
  _7_e_process: Int64
);
begin
  //https://developer.4d.com/docs/21/commands/post-event
  q4Unsupported('postEvent');
end;

procedure postKey(_1_e_code: Int64);
begin
  //https://developer.4d.com/docs/21/commands/post-key
  q4userInterface.postKey(_1_e_code, 0, 0);
end;

procedure postKey(_1_e_code: Int64; _2_e_modifiers: Int64);
begin
  //https://developer.4d.com/docs/21/commands/post-key
  q4userInterface.postKey(_1_e_code, _2_e_modifiers, 0);
end;

procedure postKey(_1_e_code: Int64; _2_e_modifiers: Int64; _3_e_process: Int64);
begin
  //https://developer.4d.com/docs/21/commands/post-key
  q4Unsupported('postKey');
end;

procedure redraw(_1_p_object: Pointer);
begin
  //https://developer.4d.com/docs/21/commands/redraw
  q4Unsupported('redraw');
end;

procedure setAbout(const _1_t_itemText: string; const _2_t_method: string);
begin
  //https://developer.4d.com/docs/21/commands/set-about
  q4menus.setAboutMenuItem(_1_t_itemText, _2_t_method);
end;

procedure setApplicationColorScheme(const _1_t_colorScheme: string);
begin
  //https://developer.4d.com/docs/21/commands/set-application-color-scheme
  if (not q4ValidColorScheme(_1_t_colorScheme)) then
    q4interruptions.assertRaise(
      'Invalid color scheme in q4userInterface.setApplicationColorScheme: ' + _1_t_colorScheme,
      {$I %CURRENTROUTINE%},
      {$I %LINENUM%}
    );

  gt_applicationColorScheme := SysUtils.LowerCase(_1_t_colorScheme);
end;

procedure setCursor;
begin
  //https://developer.4d.com/docs/21/commands/set-cursor
  q4Unsupported('setCursor');
end;

procedure setCursor(_1_e_cursor: Int64);
begin
  //https://developer.4d.com/docs/21/commands/set-cursor
  q4Unsupported('setCursor');
end;

procedure setFieldTitles(
  _1_p_table: Pointer;
  const _2_tt_fieldTitles: TQ4TextArray;
  const _3_te_fieldNumbers: TQ4IntegerArray;
  const _4_t_star: string
);
var
  _e_sourceTableId: Int64;
  _e_fieldSetIndex: Int64;
  _e_i: Int64;
  _b_useInFormulaEditor: Boolean;
  _y_field: TFieldMeta;
begin
  //https://developer.4d.com/docs/21/commands/set-field-titles
  if (System.Length(_2_tt_fieldTitles) <> System.Length(_3_te_fieldNumbers)) then
    q4interruptions.assertRaise(
      'SET FIELD TITLES arrays must have the same length',
      {$I %CURRENTROUTINE%},
      {$I %LINENUM%}
    );

  if (not q4DBschemaUse.resolveTablePointerToSourceTableId(_1_p_table, _e_sourceTableId)) then
    q4interruptions.assertRaise(
      'Invalid table pointer in q4userInterface.setFieldTitles',
      {$I %CURRENTROUTINE%},
      {$I %LINENUM%}
    );

  _b_useInFormulaEditor := q4HasStarParameter(_4_t_star);

  for _e_i := 0 to System.High(_3_te_fieldNumbers) do
    if (not q4DBschemaUse.findFieldMetaByFieldNo(_e_sourceTableId, _3_te_fieldNumbers[_e_i], _y_field)) then
      q4interruptions.assertRaise(
        'Unknown field number in q4userInterface.setFieldTitles: ' + SysUtils.IntToStr(_3_te_fieldNumbers[_e_i]),
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
      );

  _e_fieldSetIndex := q4FindVirtualFieldTitleSetIndex(_e_sourceTableId);
  if (_e_fieldSetIndex < 0) then
  begin
    _e_fieldSetIndex := System.Length(gy_virtualFieldTitleSets);
    System.SetLength(gy_virtualFieldTitleSets, _e_fieldSetIndex + 1);
    gy_virtualFieldTitleSets[_e_fieldSetIndex]._e_sourceTableId := _e_sourceTableId;
  end;

  System.SetLength(gy_virtualFieldTitleSets[_e_fieldSetIndex]._ty_fields, System.Length(_2_tt_fieldTitles));

  for _e_i := 0 to System.High(_2_tt_fieldTitles) do
  begin
    gy_virtualFieldTitleSets[_e_fieldSetIndex]._ty_fields[_e_i]._e_fieldNo := _3_te_fieldNumbers[_e_i];
    gy_virtualFieldTitleSets[_e_fieldSetIndex]._ty_fields[_e_i]._t_title := _2_tt_fieldTitles[_e_i];
    gy_virtualFieldTitleSets[_e_fieldSetIndex]._ty_fields[_e_i]._b_useInFormulaEditor := _b_useInFormulaEditor;
  end;
end;

procedure setTableTitles;
begin
  //https://developer.4d.com/docs/21/commands/set-table-titles
  gb_hasVirtualTableTitles := False;
  System.SetLength(gy_virtualTableTitles, 0);
  System.SetLength(gy_virtualFieldTitleSets, 0);
end;

procedure setTableTitles(
  const _1_tt_tableTitles: TQ4TextArray;
  const _2_te_tableNumbers: TQ4IntegerArray;
  const _3_t_star: string
);
var
  _e_i: Int64;
  _b_useInFormulaEditor: Boolean;
  _y_table: TTableMeta;
begin
  //https://developer.4d.com/docs/21/commands/set-table-titles
  if (System.Length(_1_tt_tableTitles) <> System.Length(_2_te_tableNumbers)) then
    q4interruptions.assertRaise(
      'SET TABLE TITLES arrays must have the same length',
      {$I %CURRENTROUTINE%},
      {$I %LINENUM%}
    );

  _b_useInFormulaEditor := q4HasStarParameter(_3_t_star);

  for _e_i := 0 to System.High(_2_te_tableNumbers) do
    if (not q4DBschemaUse.findTableMeta(_2_te_tableNumbers[_e_i], _y_table)) then
      q4interruptions.assertRaise(
        'Unknown table number in q4userInterface.setTableTitles: ' + SysUtils.IntToStr(_2_te_tableNumbers[_e_i]),
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
      );

  System.SetLength(gy_virtualTableTitles, System.Length(_1_tt_tableTitles));
  gb_hasVirtualTableTitles := True;

  for _e_i := 0 to System.High(_1_tt_tableTitles) do
  begin
    gy_virtualTableTitles[_e_i]._e_sourceTableId := _2_te_tableNumbers[_e_i];
    gy_virtualTableTitles[_e_i]._t_title := _1_tt_tableTitles[_e_i];
    gy_virtualTableTitles[_e_i]._b_useInFormulaEditor := _b_useInFormulaEditor;
  end;
end;

function shiftDown: Boolean;
begin
  //https://developer.4d.com/docs/21/commands/shift-down
  q4Unsupported('shiftDown');
  Result := False;
end;

procedure showMenuBar;
begin
  //https://developer.4d.com/docs/21/commands/show-menu-bar
  q4menus.setMenuBarVisible(True);
end;

function windowsAltDown: Boolean;
begin
  //https://developer.4d.com/docs/21/commands/windows-alt-down
  q4Unsupported('windowsAltDown');
  Result := False;
end;

function windowsCtrlDown: Boolean;
begin
  //https://developer.4d.com/docs/21/commands/windows-ctrl-down
  q4Unsupported('windowsCtrlDown');
  Result := False;
end;

end.
