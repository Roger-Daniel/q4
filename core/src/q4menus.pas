unit q4menus;

{$mode objfpc}{$H+}

{
q4menus
version du 2026/04/19-18:57

Mapping 4D
Command Number 4D,    4D Command,                      q4 API,                           Statut
------------------------------------------------------------------------------------------------
411,                 APPEND MENU ITEM,                 appendMenuItem,                   OK,
405,                 Count menu items,                 countMenuItems,                   OK,
404,                 Count menus,                      countMenus,                       OK,
408,                 Create menu,                      createMenu,                       OK,
413,                 DELETE MENU ITEM,                 deleteMenuItem,                   OK,
150,                 DISABLE MENU ITEM,                disableMenuItem,                  OK,
1006,                Dynamic pop up menu,              dynamicPopUpMenu,                 Partial,
149,                 ENABLE MENU ITEM,                 enableMenuItem,                   OK,
979,                 Get menu bar reference,           getMenuBarReference,              OK,
422,                 Get menu item,                    getMenuItem,                      OK,
983,                 GET MENU ITEM ICON,               getMenuItemIcon,                  Partial,
424,                 Get menu item key,                getMenuItemKey,                   OK,
428,                 Get menu item mark,               getMenuItemMark,                  OK,
981,                 Get menu item method,             getMenuItemMethod,                OK,
980,                 Get menu item modifiers,          getMenuItemModifiers,             OK,
1003,                Get menu item parameter,          getMenuItemParameter,             OK,
972,                 GET MENU ITEM PROPERTY,           getMenuItemProperty,              OK,
426,                 Get menu item style,              getMenuItemStyle,                 OK,
977,                 GET MENU ITEMS,                   getMenuItems,                     OK,
430,                 Get menu title,                   getMenuTitle,                     OK,
1005,                Get selected menu item parameter, getSelectedMenuItemParameter,     Partial,
412,                 INSERT MENU ITEM,                 insertMenuItem,                   OK,
152,                 Menu selected,                    menuSelected,                     Partial,
978,                 RELEASE MENU,                     releaseMenu,                      OK,
1801,                SET HELP MENU,                    setHelpMenu,                      Partial,
67,                  SET MENU BAR,                     setMenuBar,                       OK,
348,                 SET MENU ITEM,                    setMenuItem,                      OK,
984,                 SET MENU ITEM ICON,               setMenuItemIcon,                  Partial,
208,                 SET MENU ITEM MARK,               setMenuItemMark,                  OK,
982,                 SET MENU ITEM METHOD,             setMenuItemMethod,                OK,
1004,                SET MENU ITEM PARAMETER,          setMenuItemParameter,             OK,
973,                 SET MENU ITEM PROPERTY,           setMenuItemProperty,              OK,
423,                 SET MENU ITEM SHORTCUT,           setMenuItemShortcut,              OK,
425,                 SET MENU ITEM STYLE,              setMenuItemStyle,                 OK,

Doc: https://developer.4d.com/docs/21/commands/theme/Menus
}


interface

uses
  SysUtils,
  Variants,
  Classes,
  fgl;

type
  TQ4TextArray = array of string;

const
  MENU_STATUS_OK = 'OK';
  MENU_STATUS_PARTIAL = 'Partial';
  MENU_STATUS_NOT_SUPPORTED = 'Not supported';

procedure registerMenuBar(_1_e_menuBar: int64; const _2_t_menuBarName: string; const _3_t_menuRef: string);
procedure unregisterMenuBar(_1_e_menuBar: int64);
function isMenuRef(const _1_t_value: string): boolean;

function packMenuSelected(_1_e_menu: int64; _2_e_menuItem: int64): int64;
procedure unpackMenuSelected(_1_e_menuSelected: int64; out _2_e_menu: int64; out _3_e_menuItem: int64);

function createMenu: string; overload;
function createMenu(_1_e_menu: int64): string; overload;
function createMenu(const _1_t_menu: string): string; overload;

procedure releaseMenu(const _1_t_menu: string);

function countMenus: int64; overload;
function countMenus(_1_e_process: int64): int64; overload;

function countMenuItems(_1_e_menu: int64; _2_e_process: int64): int64; overload;
function countMenuItems(const _1_t_menu: string): int64; overload;

function getMenuBarReference: string; overload;
function getMenuBarReference(_1_e_process: int64): string; overload;

function getMenuTitle(_1_e_menu: int64; _2_e_process: int64): string; overload;
function getMenuTitle(const _1_t_menu: string): string; overload;

procedure getMenuItems(_1_e_menu: int64; out _2_tt_menuTitlesArray: TQ4TextArray; out _3_tt_menuRefsArray: TQ4TextArray); overload;
procedure getMenuItems(const _1_t_menu: string; out _2_tt_menuTitlesArray: TQ4TextArray; out _3_tt_menuRefsArray: TQ4TextArray); overload;

procedure setMenuBar(_1_e_menuBar: int64); overload;
procedure setMenuBar(_1_e_menuBar: int64; const _2_t_star: string); overload;
procedure setMenuBar(_1_e_menuBar: int64; _2_e_process: int64); overload;
procedure setMenuBar(_1_e_menuBar: int64; _2_e_process: int64; const _3_t_star: string); overload;

procedure setMenuBar(const _1_t_menuBar: string); overload;
procedure setMenuBar(const _1_t_menuBar: string; const _2_t_star: string); overload;

procedure appendMenuItem(const _1_t_menu: string; const _2_t_itemText: string; const _3_t_subMenu: string = ''; const _4_t_star: string = ''); overload;
procedure appendMenuItem(_1_e_menu: int64; const _2_t_itemText: string; const _3_t_subMenu: string; _4_e_process: int64; const _5_t_star: string = ''); overload;

procedure insertMenuItem(const _1_t_menu: string; _2_e_afterItem: int64; const _3_t_itemText: string; const _4_t_subMenu: string = '';
  const _5_t_star: string = ''); overload;
procedure insertMenuItem(_1_e_menu: int64; _2_e_afterItem: int64; const _3_t_itemText: string; const _4_t_subMenu: string;
  _5_e_process: int64; const _6_t_star: string = ''); overload;

procedure setMenuItem(const _1_t_menu: string; _2_e_menuItem: int64; const _3_t_itemText: string; const _4_t_star: string = ''); overload;
procedure setMenuItem(_1_e_menu: int64; _2_e_menuItem: int64; const _3_t_itemText: string; _4_e_process: int64; const _5_t_star: string = ''); overload;

procedure deleteMenuItem(const _1_t_menu: string; _2_e_menuItem: int64); overload;
procedure deleteMenuItem(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64); overload;

procedure disableMenuItem(const _1_t_menu: string; _2_e_menuItem: int64); overload;
procedure disableMenuItem(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64); overload;

procedure enableMenuItem(const _1_t_menu: string; _2_e_menuItem: int64); overload;
procedure enableMenuItem(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64); overload;

function getMenuItem(const _1_t_menu: string; _2_e_menuItem: int64): string; overload;
function getMenuItem(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64): string; overload;

function getMenuItemKey(const _1_t_menu: string; _2_e_menuItem: int64): int64; overload;
function getMenuItemKey(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64): int64; overload;

function getMenuItemMark(const _1_t_menu: string; _2_e_menuItem: int64): string; overload;
function getMenuItemMark(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64): string; overload;

function getMenuItemMethod(const _1_t_menu: string; _2_e_menuItem: int64): string; overload;
function getMenuItemMethod(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64): string; overload;

function getMenuItemModifiers(const _1_t_menu: string; _2_e_menuItem: int64): int64; overload;
function getMenuItemModifiers(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64): int64; overload;

function getMenuItemParameter(const _1_t_menu: string; _2_e_menuItem: int64): string; overload;
function getMenuItemParameter(_1_e_menu: int64; _2_e_menuItem: int64): string; overload;

function getMenuItemStyle(const _1_t_menu: string; _2_e_menuItem: int64): int64; overload;
function getMenuItemStyle(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64): int64; overload;

procedure getMenuItemIcon(const _1_t_menu: string; _2_e_menuItem: int64; out _3_v_iconRef: variant); overload;
procedure getMenuItemIcon(_1_e_menu: int64; _2_e_menuItem: int64; out _3_v_iconRef: variant; _4_e_process: int64); overload;

procedure getMenuItemProperty(const _1_t_menu: string; _2_e_menuItem: int64; const _3_t_property: string; out _4_v_value: variant); overload;
procedure getMenuItemProperty(_1_e_menu: int64; _2_e_menuItem: int64; const _3_t_property: string; out _4_v_value: variant; _5_e_process: int64); overload;

procedure setMenuItemMark(const _1_t_menu: string; _2_e_menuItem: int64; const _3_t_mark: string); overload;
procedure setMenuItemMark(_1_e_menu: int64; _2_e_menuItem: int64; const _3_t_mark: string; _4_e_process: int64); overload;

procedure setMenuItemMethod(const _1_t_menu: string; _2_e_menuItem: int64; const _3_t_methodName: string); overload;
procedure setMenuItemMethod(_1_e_menu: int64; _2_e_menuItem: int64; const _3_t_methodName: string; _4_e_process: int64); overload;

procedure setMenuItemParameter(const _1_t_menu: string; _2_e_menuItem: int64; const _3_t_param: string); overload;
procedure setMenuItemParameter(_1_e_menu: int64; _2_e_menuItem: int64; const _3_t_param: string); overload;

procedure setMenuItemStyle(const _1_t_menu: string; _2_e_menuItem: int64; _3_e_itemStyle: int64); overload;
procedure setMenuItemStyle(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_itemStyle: int64; _4_e_process: int64); overload;

procedure setMenuItemShortcut(const _1_t_menu: string; _2_e_menuItem: int64; const _3_v_itemKey: variant; _4_e_modifiers: int64); overload;
procedure setMenuItemShortcut(_1_e_menu: int64; _2_e_menuItem: int64; const _3_v_itemKey: variant; _4_e_modifiers: int64; _5_e_process: int64); overload;

procedure setMenuItemIcon(const _1_t_menu: string; _2_e_menuItem: int64; const _3_v_iconRef: variant); overload;
procedure setMenuItemIcon(_1_e_menu: int64; _2_e_menuItem: int64; const _3_v_iconRef: variant; _4_e_process: int64); overload;

procedure setMenuItemProperty(const _1_t_menu: string; _2_e_menuItem: int64; const _3_t_property: string; const _4_v_value: variant); overload;
procedure setMenuItemProperty(_1_e_menu: int64; _2_e_menuItem: int64; const _3_t_property: string; const _4_v_value: variant; _5_e_process: int64); overload;

function dynamicPopUpMenu(const _1_t_menu: string): string; overload;
function dynamicPopUpMenu(const _1_t_menu: string; const _2_t_default: string): string; overload;
function dynamicPopUpMenu(const _1_t_menu: string; const _2_t_default: string; _3_e_xCoord: int64; _4_e_yCoord: int64): string; overload;

function menuSelected: int64; overload;
function menuSelected(out _1_t_subMenu: string): int64; overload;

function getSelectedMenuItemParameter: string;

procedure setHelpMenu(const _1_t_menuColJson: string);

{ Helpers used by q4userInterface.
  These routines expose q4 menu state without duplicating menu parsing or storage. }
function popUpMenuEmulation(const _1_t_contents: string): int64; overload;
function popUpMenuEmulation(const _1_t_contents: string; _2_e_default: int64): int64; overload;
function popUpMenuEmulation(const _1_t_contents: string; _2_e_default: int64; _3_e_xCoord: int64; _4_e_yCoord: int64): int64; overload;

function isMenuBarVisible: boolean;
procedure setMenuBarVisible(_1_b_visible: boolean);

procedure setAboutMenuItem(const _1_t_itemText: string; const _2_t_method: string);
function getAboutMenuItemText: string;
function getAboutMenuItemMethod: string;

implementation

type
  TQ4MenuPropertyDef = class
  public
    t_name: string;
    v_value: variant;

    function clone: TQ4MenuPropertyDef;
  end;

  TQ4MenuPropertyList = specialize TFPGObjectList<TQ4MenuPropertyDef>;

  TQ4MenuItemDef = class
  public
    t_rawText: string;
    t_displayText: string;
    t_subMenuRef: string;
    t_mark: string;
    t_methodName: string;
    t_parameter: string;
    e_style: int64;
    e_shortcutKey: int64;
    e_modifiers: int64;
    v_iconRef: variant;
    b_enabled: boolean;
    b_isSeparator: boolean;
    b_literalText: boolean;
    o_properties: TQ4MenuPropertyList;

    constructor Create;
    destructor Destroy; override;
    function clone: TQ4MenuItemDef;
  end;

  TQ4MenuItemList = specialize TFPGObjectList<TQ4MenuItemDef>;

  TQ4MenuDef = class
  public
    t_ref: string;
    t_title: string;
    b_released: boolean;
    o_items: TQ4MenuItemList;

    constructor Create;
    destructor Destroy; override;
    function clone: TQ4MenuDef;
  end;

  TQ4MenuDefList = specialize TFPGObjectList<TQ4MenuDef>;

var
  go_menuDefs: TQ4MenuDefList = nil;
  gt_menuBarsByNumber: TStringList = nil;
  gt_menuBarsByName: TStringList = nil;

threadvar
  gt_currentMenuBarRef: string;
  gt_currentMenuBarKey: string;
  gt_lastSelectedSubMenuRef: string;
  gt_lastSelectedParameter: string;
  gt_helpMenuJson: string;
  gt_aboutMenuItemText: string;
  gt_aboutMenuItemMethod: string;
  ge_lastSelectedMenuCode: int64;
  gb_menuBarVisible: boolean;
  gb_menuBarVisibilityInitialized: boolean;
  go_savedMenuBars: TStringList;

function newMenuRef: string; forward;
function findMenuDefByRef(const _1_t_ref: string): TQ4MenuDef; forward;
function getTextForItem(_1_o_item: TQ4MenuItemDef): string; forward;

procedure ensureStores;
var
  _o_list: TStringList;
begin
  if (go_menuDefs = nil) then go_menuDefs := TQ4MenuDefList.Create(True);

  if (gt_menuBarsByNumber = nil) then begin
    _o_list := TStringList.Create;
    _o_list.CaseSensitive := False;
    _o_list.NameValueSeparator := '=';
    gt_menuBarsByNumber := _o_list;
  end;

  if (gt_menuBarsByName = nil) then begin
    _o_list := TStringList.Create;
    _o_list.CaseSensitive := False;
    _o_list.NameValueSeparator := '=';
    gt_menuBarsByName := _o_list;
  end;
end;

procedure ensureThreadStores;
var
  _o_list: TStringList;
begin
  if (go_savedMenuBars <> nil) then Exit;

  _o_list := TStringList.Create;
  _o_list.CaseSensitive := False;
  _o_list.NameValueSeparator := '=';
  go_savedMenuBars := _o_list;
end;

procedure ensureMenuBarVisibilityInitialized;
begin
  if (gb_menuBarVisibilityInitialized) then Exit;

  // q4 keeps a logical menu-bar visibility flag for commands implemented in q4userInterface.
  // Without a UI backend, this flag records the 4D state but does not affect an LCL form.
  gb_menuBarVisible := True;
  gb_menuBarVisibilityInitialized := True;
end;

function buildNumberMenuBarKey(_1_e_menuBar: int64): string;
begin
  Result := 'NUMBER:' + IntToStr(_1_e_menuBar);
end;

function buildNameMenuBarKey(const _1_t_menuBarName: string): string;
begin
  Result := 'NAME:' + _1_t_menuBarName;
end;

function getSavedMenuBarRef(const _1_t_key: string): string;
begin
  ensureThreadStores;
  Result := go_savedMenuBars.Values[_1_t_key];
end;

procedure setSavedMenuBarRef(const _1_t_key: string; const _2_t_menuRef: string);
begin
  ensureThreadStores;
  go_savedMenuBars.Values[_1_t_key] := _2_t_menuRef;
end;

procedure syncSubMenuTitle(const _1_t_subMenuRef: string; const _2_t_title: string);
var
  _o_subMenu: TQ4MenuDef;
begin
  if (_1_t_subMenuRef = '') then Exit;

  _o_subMenu := findMenuDefByRef(_1_t_subMenuRef);
  if (_o_subMenu = nil) then Exit;

  if ((_o_subMenu.t_title = '') or SameText(_o_subMenu.t_title, _1_t_subMenuRef)) then _o_subMenu.t_title := _2_t_title;
end;

function cloneMenuTreeInternal(_1_o_source: TQ4MenuDef; _2_o_refMap: TStringList): TQ4MenuDef;
var
  _o_clone: TQ4MenuDef;
  _o_sourceItem: TQ4MenuItemDef;
  _o_cloneItem: TQ4MenuItemDef;
  _o_subMenu: TQ4MenuDef;
  _e_index: int64;
  _t_existingRef: string;
begin
  if (_1_o_source = nil) then Exit(nil);

  _t_existingRef := _2_o_refMap.Values[_1_o_source.t_ref];
  if (_t_existingRef <> '') then begin
    Result := findMenuDefByRef(_t_existingRef);
    Exit;
  end;

  _o_clone := TQ4MenuDef.Create;
  _o_clone.t_ref := newMenuRef;
  _o_clone.t_title := _1_o_source.t_title;
  _o_clone.b_released := False;
  go_menuDefs.Add(_o_clone);
  _2_o_refMap.Values[_1_o_source.t_ref] := _o_clone.t_ref;

  for _e_index := 0 to _1_o_source.o_items.Count - 1 do begin
    _o_sourceItem := _1_o_source.o_items[_e_index];
    _o_cloneItem := _o_sourceItem.clone;
    if (_o_sourceItem.t_subMenuRef <> '') then begin
      _o_subMenu := cloneMenuTreeInternal(findMenuDefByRef(_o_sourceItem.t_subMenuRef), _2_o_refMap);
      if (_o_subMenu <> nil) then _o_cloneItem.t_subMenuRef := _o_subMenu.t_ref
      else
        _o_cloneItem.t_subMenuRef := '';
    end;
    _o_clone.o_items.Add(_o_cloneItem);
  end;

  Result := _o_clone;
end;

function cloneMenuTree(_1_o_source: TQ4MenuDef): TQ4MenuDef;
var
  _o_refMap: TStringList;
begin
  if (_1_o_source = nil) then Exit(nil);

  _o_refMap := TStringList.Create;
  try
    _o_refMap.CaseSensitive := False;
    _o_refMap.NameValueSeparator := '=';
    Result := cloneMenuTreeInternal(_1_o_source, _o_refMap);
  finally
    _o_refMap.Free;
  end;
end;

procedure applyRegisteredMenuBar(const _1_t_key: string; const _2_t_baseMenuRef: string; _3_b_saveState: boolean);
var
  _o_clone: TQ4MenuDef;
  _t_savedRef: string;
begin
  if (_2_t_baseMenuRef = '') then begin
    gt_currentMenuBarRef := '';
    gt_currentMenuBarKey := '';
    Exit;
  end;

  if (not _3_b_saveState) then begin
    _o_clone := cloneMenuTree(findMenuDefByRef(_2_t_baseMenuRef));
    if (_o_clone = nil) then begin
      gt_currentMenuBarRef := '';
      gt_currentMenuBarKey := '';
      Exit;
    end;

    gt_currentMenuBarRef := _o_clone.t_ref;
    gt_currentMenuBarKey := '';
    Exit;
  end;

  _t_savedRef := getSavedMenuBarRef(_1_t_key);
  if ((_t_savedRef <> '') and (findMenuDefByRef(_t_savedRef) <> nil)) then begin
    gt_currentMenuBarRef := _t_savedRef;
    gt_currentMenuBarKey := _1_t_key;
    Exit;
  end;

  _o_clone := cloneMenuTree(findMenuDefByRef(_2_t_baseMenuRef));
  if (_o_clone = nil) then begin
    gt_currentMenuBarRef := '';
    gt_currentMenuBarKey := '';
    Exit;
  end;

  gt_currentMenuBarRef := _o_clone.t_ref;
  gt_currentMenuBarKey := _1_t_key;
  setSavedMenuBarRef(_1_t_key, _o_clone.t_ref);
end;

function findSelectableItemIndex(_1_o_menu: TQ4MenuDef; const _2_t_default: string): int64;
var
  _o_item: TQ4MenuItemDef;
  _e_index: int64;
  _t_candidate: string;
begin
  if (_1_o_menu = nil) then Exit(-1);

  if (_2_t_default <> '') then for _e_index := 0 to _1_o_menu.o_items.Count - 1 do begin
      _o_item := _1_o_menu.o_items[_e_index];
      if (_o_item.b_isSeparator or (not _o_item.b_enabled)) then Continue;

      if (_o_item.t_parameter <> '') then _t_candidate := _o_item.t_parameter
      else
        _t_candidate := getTextForItem(_o_item);

      if (SameText(_t_candidate, _2_t_default)) then Exit(_e_index);
    end;

  for _e_index := 0 to _1_o_menu.o_items.Count - 1 do begin
    _o_item := _1_o_menu.o_items[_e_index];
    if (_o_item.b_isSeparator or (not _o_item.b_enabled)) then Continue;
    Exit(_e_index);
  end;

  Result := -1;
end;

function newMenuRef: string;
var
  _g_guid: TGUID;
  _t_guid: string;
  _t_value: string;
begin
  SysUtils.CreateGUID(_g_guid);
  _t_guid := SysUtils.GUIDToString(_g_guid);
  _t_value := SysUtils.StringReplace(_t_guid, '{', '', [rfReplaceAll]);
  _t_value := SysUtils.StringReplace(_t_value, '}', '', [rfReplaceAll]);
  _t_value := SysUtils.StringReplace(_t_value, '-', '', [rfReplaceAll]);
  Result := Copy(_t_value, 1, 16);
end;

function findMenuDefByRef(const _1_t_ref: string): TQ4MenuDef;
var
  _e_index: int64;
begin
  ensureStores;
  Result := nil;

  for _e_index := 0 to go_menuDefs.Count - 1 do if (SameText(go_menuDefs[_e_index].t_ref, _1_t_ref)) then begin
      Result := go_menuDefs[_e_index];
      Exit;
    end;

end;

function findPropertyByName(_1_o_properties: TQ4MenuPropertyList; const _2_t_name: string): TQ4MenuPropertyDef;
var
  _e_index: int64;
begin
  Result := nil;
  if (_1_o_properties = nil) then Exit;

  for _e_index := 0 to _1_o_properties.Count - 1 do if (SameText(_1_o_properties[_e_index].t_name, _2_t_name)) then begin
      Result := _1_o_properties[_e_index];
      Exit;
    end;

end;

function lookupRegisteredMenuRefByNumber(_1_e_menuBar: int64): string;
var
  _t_key: string;
begin
  ensureStores;
  _t_key := IntToStr(_1_e_menuBar);
  Result := gt_menuBarsByNumber.Values[_t_key];
end;

function lookupRegisteredMenuRefByName(const _1_t_menuBarName: string): string;
begin
  ensureStores;
  Result := gt_menuBarsByName.Values[_1_t_menuBarName];
end;

function resolveMenuRefFromString(const _1_t_menu: string): string;
begin
  if (findMenuDefByRef(_1_t_menu) <> nil) then begin
    Result := _1_t_menu;
    Exit;
  end;

  Result := lookupRegisteredMenuRefByName(_1_t_menu);
end;

function resolveMenuDefFromString(const _1_t_menu: string): TQ4MenuDef;
var
  _t_menuRef: string;
begin
  _t_menuRef := resolveMenuRefFromString(_1_t_menu);
  Result := findMenuDefByRef(_t_menuRef);
end;

function resolveCurrentMenuBar: TQ4MenuDef;
begin
  Result := findMenuDefByRef(gt_currentMenuBarRef);
end;

function resolveNumericMenu(_1_e_menu: int64): TQ4MenuDef;
var
  _o_bar: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  Result := nil;
  _o_bar := resolveCurrentMenuBar;
  if (_o_bar = nil) then Exit;

  if ((_1_e_menu < 1) or (_1_e_menu > _o_bar.o_items.Count)) then Exit;

  _o_item := _o_bar.o_items[_1_e_menu - 1];
  if (_o_item = nil) then Exit;

  if (_o_item.t_subMenuRef <> '') then begin
    Result := findMenuDefByRef(_o_item.t_subMenuRef);
    Exit;
  end;

  Result := nil;
end;

function getItemByIndex(_1_o_menu: TQ4MenuDef; _2_e_menuItem: int64): TQ4MenuItemDef;
var
  _e_index: int64;
begin
  Result := nil;
  if (_1_o_menu = nil) then Exit;

  _e_index := _2_e_menuItem;
  if (_e_index = -1) then _e_index := _1_o_menu.o_items.Count;

  if ((_e_index < 1) or (_e_index > _1_o_menu.o_items.Count)) then Exit;

  Result := _1_o_menu.o_items[_e_index - 1];
end;

function resolveShortcutKey(const _1_v_itemKey: variant): int64;
var
  _t_text: string;
begin
  if (VarIsNumeric(_1_v_itemKey)) then Exit(int64(_1_v_itemKey));

  _t_text := VarToStr(_1_v_itemKey);
  if (_t_text = '') then Exit(0);

  Result := Ord(_t_text[1]);
end;

procedure parseItemText(const _1_t_itemText: string; const _2_t_star: string; _3_o_item: TQ4MenuItemDef);
var
  _t_work: string;
  _e_pos: int64;
begin
  _t_work := _1_t_itemText;

  _3_o_item.t_rawText := _1_t_itemText;
  _3_o_item.t_displayText := _1_t_itemText;
  _3_o_item.b_enabled := True;
  _3_o_item.b_isSeparator := False;
  _3_o_item.b_literalText := (_2_t_star = '*');
  _3_o_item.t_mark := '';
  _3_o_item.e_style := 0;
  _3_o_item.e_shortcutKey := 0;

  if (_3_o_item.b_literalText) then Exit;

  if ((_t_work = '-') or (_t_work = '(-')) then begin
    _3_o_item.b_isSeparator := True;
    _3_o_item.b_enabled := False;
    _3_o_item.t_displayText := '-';
    Exit;
  end;

  if ((_t_work <> '') and (_t_work[1] = '(')) then begin
    _3_o_item.b_enabled := False;
    Delete(_t_work, 1, 1);
  end;

  while ((Length(_t_work) >= 2) and (_t_work[1] = '<')) do begin
    case UpCase(_t_work[2]) of
      'B': _3_o_item.e_style := _3_o_item.e_style or 1;
      'I': _3_o_item.e_style := _3_o_item.e_style or 2;
      'U': _3_o_item.e_style := _3_o_item.e_style or 4;
    end;
    Delete(_t_work, 1, 2);
  end;

  _e_pos := Pos('!', _t_work);
  if ((_e_pos > 0) and (_e_pos < Length(_t_work))) then begin
    _3_o_item.t_mark := _t_work[_e_pos + 1];
    Delete(_t_work, _e_pos, 2);
  end;

  _e_pos := Pos('/', _t_work);
  if ((_e_pos > 0) and (_e_pos < Length(_t_work))) then begin
    _3_o_item.e_shortcutKey := Ord(_t_work[_e_pos + 1]);
    Delete(_t_work, _e_pos, 2);
  end;

  _3_o_item.t_displayText := _t_work;
  Exit;
end;

procedure appendParsedItems(_1_o_menu: TQ4MenuDef; const _2_t_itemText: string; const _3_t_subMenu: string; const _4_t_star: string);
var
  _o_list: TStringList;
  _e_index: int64;
  _o_item: TQ4MenuItemDef;
begin
  if (_1_o_menu = nil) then Exit;

  if (_4_t_star = '*') then begin
    _o_item := TQ4MenuItemDef.Create;
    parseItemText(_2_t_itemText, _4_t_star, _o_item);
    _o_item.t_subMenuRef := _3_t_subMenu;
    _1_o_menu.o_items.Add(_o_item);
    Exit;
  end;

  _o_list := TStringList.Create;
  try
    _o_list.StrictDelimiter := True;
    _o_list.Delimiter := ';';
    _o_list.DelimitedText := _2_t_itemText;

    for _e_index := 0 to _o_list.Count - 1 do begin
      _o_item := TQ4MenuItemDef.Create;
      parseItemText(_o_list[_e_index], '', _o_item);
      if ((_e_index = 0) and (_3_t_subMenu <> '')) then begin
        _o_item.t_subMenuRef := _3_t_subMenu;
        syncSubMenuTitle(_3_t_subMenu, _o_item.t_displayText);
      end;
      _1_o_menu.o_items.Add(_o_item);
    end;
  finally
    _o_list.Free;
  end;
end;

procedure setPropertyValue(_1_o_item: TQ4MenuItemDef; const _2_t_property: string; const _3_v_value: variant);
var
  _o_property: TQ4MenuPropertyDef;
begin
  if (_1_o_item = nil) then Exit;

  _o_property := findPropertyByName(_1_o_item.o_properties, _2_t_property);
  if (_o_property = nil) then begin
    _o_property := TQ4MenuPropertyDef.Create;
    _o_property.t_name := _2_t_property;
    _1_o_item.o_properties.Add(_o_property);
  end;

  _o_property.v_value := _3_v_value;
end;

procedure enableRecursive(_1_o_menu: TQ4MenuDef; _2_b_enabled: boolean);
var
  _e_index: int64;
  _o_item: TQ4MenuItemDef;
  _o_subMenu: TQ4MenuDef;
begin
  if (_1_o_menu = nil) then Exit;

  for _e_index := 0 to _1_o_menu.o_items.Count - 1 do begin
    _o_item := _1_o_menu.o_items[_e_index];
    _o_item.b_enabled := _2_b_enabled;

    if (_o_item.t_subMenuRef <> '') then begin
      _o_subMenu := findMenuDefByRef(_o_item.t_subMenuRef);
      enableRecursive(_o_subMenu, _2_b_enabled);
    end;
  end;
end;

function getTextForItem(_1_o_item: TQ4MenuItemDef): string;
begin
  if (_1_o_item = nil) then Exit('');

  if (_1_o_item.b_literalText) then begin
    Result := _1_o_item.t_rawText;
    Exit;
  end;

  Result := _1_o_item.t_displayText;
end;

{ TQ4MenuPropertyDef }

function TQ4MenuPropertyDef.clone: TQ4MenuPropertyDef;
begin
  Result := TQ4MenuPropertyDef.Create;
  Result.t_name := t_name;
  Result.v_value := v_value;
end;

{ TQ4MenuItemDef }

constructor TQ4MenuItemDef.Create;
begin
  inherited Create;
  o_properties := TQ4MenuPropertyList.Create(True);
  b_enabled := True;
  Exit;
end;

destructor TQ4MenuItemDef.Destroy;
begin
  o_properties.Free;
  inherited Destroy;
end;

function TQ4MenuItemDef.clone: TQ4MenuItemDef;
var
  _e_index: int64;
begin
  Result := TQ4MenuItemDef.Create;
  Result.t_rawText := t_rawText;
  Result.t_displayText := t_displayText;
  Result.t_subMenuRef := t_subMenuRef;
  Result.t_mark := t_mark;
  Result.t_methodName := t_methodName;
  Result.t_parameter := t_parameter;
  Result.e_style := e_style;
  Result.e_shortcutKey := e_shortcutKey;
  Result.e_modifiers := e_modifiers;
  Result.v_iconRef := v_iconRef;
  Result.b_enabled := b_enabled;
  Result.b_isSeparator := b_isSeparator;
  Result.b_literalText := b_literalText;

  for _e_index := 0 to o_properties.Count - 1 do Result.o_properties.Add(o_properties[_e_index].clone);

end;

{ TQ4MenuDef }

constructor TQ4MenuDef.Create;
begin
  inherited Create;
  o_items := TQ4MenuItemList.Create(True);
  Exit;
end;

destructor TQ4MenuDef.Destroy;
begin
  o_items.Free;
  inherited Destroy;
end;

function TQ4MenuDef.clone: TQ4MenuDef;
var
  _e_index: int64;
  _o_itemClone: TQ4MenuItemDef;
begin
  Result := TQ4MenuDef.Create;
  Result.t_ref := newMenuRef;
  Result.t_title := t_title;
  Result.b_released := False;

  for _e_index := 0 to o_items.Count - 1 do begin
    _o_itemClone := o_items[_e_index].clone;
    Result.o_items.Add(_o_itemClone);
  end;

end;

procedure registerMenuBar(_1_e_menuBar: int64; const _2_t_menuBarName: string; const _3_t_menuRef: string);
begin
  ensureStores;
  gt_menuBarsByNumber.Values[IntToStr(_1_e_menuBar)] := _3_t_menuRef;
  if (_2_t_menuBarName <> '') then gt_menuBarsByName.Values[_2_t_menuBarName] := _3_t_menuRef;
end;

procedure unregisterMenuBar(_1_e_menuBar: int64);
var
  _e_index: int64;
  _t_ref: string;
begin
  ensureStores;
  _t_ref := gt_menuBarsByNumber.Values[IntToStr(_1_e_menuBar)];
  gt_menuBarsByNumber.Values[IntToStr(_1_e_menuBar)] := '';

  for _e_index := gt_menuBarsByName.Count - 1 downto 0 do if (SameText(gt_menuBarsByName.ValueFromIndex[_e_index], _t_ref)) then
      gt_menuBarsByName.Delete(_e_index);

end;

function isMenuRef(const _1_t_value: string): boolean;
begin
  Result := findMenuDefByRef(_1_t_value) <> nil;
end;

function packMenuSelected(_1_e_menu: int64; _2_e_menuItem: int64): int64;
begin
  Result := ((_1_e_menu and $FFFF) shl 16) or (_2_e_menuItem and $FFFF);
end;

procedure unpackMenuSelected(_1_e_menuSelected: int64; out _2_e_menu: int64; out _3_e_menuItem: int64);
begin
  _2_e_menu := (_1_e_menuSelected shr 16) and $FFFF;
  _3_e_menuItem := _1_e_menuSelected and $FFFF;
end;

function createMenu: string;
var
  _o_menu: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/create-menu
  ensureStores;
  _o_menu := TQ4MenuDef.Create;
  _o_menu.t_ref := newMenuRef;
  go_menuDefs.Add(_o_menu);
  Result := _o_menu.t_ref;
end;

function createMenu(_1_e_menu: int64): string;
var
  _t_menuRef: string;
  _o_source: TQ4MenuDef;
  _o_clone: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/create-menu
  _t_menuRef := lookupRegisteredMenuRefByNumber(_1_e_menu);
  _o_source := findMenuDefByRef(_t_menuRef);

  if (_o_source = nil) then Exit(createMenu);

  _o_clone := cloneMenuTree(_o_source);
  if (_o_clone = nil) then Exit(createMenu);

  Result := _o_clone.t_ref;
end;

function createMenu(const _1_t_menu: string): string;
var
  _o_source: TQ4MenuDef;
  _o_clone: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/create-menu
  _o_source := resolveMenuDefFromString(_1_t_menu);
  if (_o_source = nil) then Exit(createMenu);

  _o_clone := cloneMenuTree(_o_source);
  if (_o_clone = nil) then Exit(createMenu);

  Result := _o_clone.t_ref;
end;

procedure releaseMenu(const _1_t_menu: string);
var
  _o_menu: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/release-menu
  _o_menu := findMenuDefByRef(_1_t_menu);
  if (_o_menu <> nil) then _o_menu.b_released := True;
end;

function countMenus: int64;
var
  _o_bar: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/count-menus
  _o_bar := resolveCurrentMenuBar;
  if (_o_bar = nil) then Exit(0);

  Result := _o_bar.o_items.Count;
end;

function countMenus(_1_e_process: int64): int64;
begin
  //https://developer.4d.com/docs/21/commands/count-menus
  Result := countMenus;
end;

function countMenuItems(_1_e_menu: int64; _2_e_process: int64): int64;
var
  _o_menu: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/count-menu-items
  _o_menu := resolveNumericMenu(_1_e_menu);
  if (_o_menu = nil) then Exit(0);

  Result := _o_menu.o_items.Count;
end;

function countMenuItems(const _1_t_menu: string): int64;
var
  _o_menu: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/count-menu-items
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  if (_o_menu = nil) then Exit(0);

  Result := _o_menu.o_items.Count;
end;

function getMenuBarReference: string;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-bar-reference
  Result := gt_currentMenuBarRef;
end;

function getMenuBarReference(_1_e_process: int64): string;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-bar-reference
  Result := gt_currentMenuBarRef;
end;

function getMenuTitle(_1_e_menu: int64; _2_e_process: int64): string;
var
  _o_bar: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-title
  _o_bar := resolveCurrentMenuBar;
  if (_o_bar = nil) then begin
    Result := '';
    Exit;
  end;

  _o_item := getItemByIndex(_o_bar, _1_e_menu);
  Result := getTextForItem(_o_item);
end;

function getMenuTitle(const _1_t_menu: string): string;
var
  _o_menu: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-title
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  if (_o_menu = nil) then Exit('');

  Result := _o_menu.t_title;
end;

procedure getMenuItems(_1_e_menu: int64; out _2_tt_menuTitlesArray: TQ4TextArray; out _3_tt_menuRefsArray: TQ4TextArray);
var
  _o_menu: TQ4MenuDef;
  _e_index: int64;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-items
  _o_menu := resolveNumericMenu(_1_e_menu);
  SetLength(_2_tt_menuTitlesArray, 0);
  SetLength(_3_tt_menuRefsArray, 0);

  if (_o_menu = nil) then Exit;

  SetLength(_2_tt_menuTitlesArray, _o_menu.o_items.Count);
  SetLength(_3_tt_menuRefsArray, _o_menu.o_items.Count);

  for _e_index := 0 to _o_menu.o_items.Count - 1 do begin
    _2_tt_menuTitlesArray[_e_index] := getTextForItem(_o_menu.o_items[_e_index]);
    _3_tt_menuRefsArray[_e_index] := _o_menu.o_items[_e_index].t_subMenuRef;
  end;
end;

procedure getMenuItems(const _1_t_menu: string; out _2_tt_menuTitlesArray: TQ4TextArray; out _3_tt_menuRefsArray: TQ4TextArray);
var
  _o_menu: TQ4MenuDef;
  _e_index: int64;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-items
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  SetLength(_2_tt_menuTitlesArray, 0);
  SetLength(_3_tt_menuRefsArray, 0);

  if (_o_menu = nil) then Exit;

  SetLength(_2_tt_menuTitlesArray, _o_menu.o_items.Count);
  SetLength(_3_tt_menuRefsArray, _o_menu.o_items.Count);

  for _e_index := 0 to _o_menu.o_items.Count - 1 do begin
    _2_tt_menuTitlesArray[_e_index] := getTextForItem(_o_menu.o_items[_e_index]);
    _3_tt_menuRefsArray[_e_index] := _o_menu.o_items[_e_index].t_subMenuRef;
  end;
end;

procedure setMenuBar(_1_e_menuBar: int64);
var
  _t_key: string;
  _t_ref: string;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-bar
  _t_key := buildNumberMenuBarKey(_1_e_menuBar);
  _t_ref := lookupRegisteredMenuRefByNumber(_1_e_menuBar);
  applyRegisteredMenuBar(_t_key, _t_ref, False);
end;

procedure setMenuBar(_1_e_menuBar: int64; const _2_t_star: string);
var
  _t_key: string;
  _t_ref: string;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-bar
  if (_2_t_star <> '*') then begin
    setMenuBar(_1_e_menuBar);
    Exit;
  end;

  _t_key := buildNumberMenuBarKey(_1_e_menuBar);
  _t_ref := lookupRegisteredMenuRefByNumber(_1_e_menuBar);
  applyRegisteredMenuBar(_t_key, _t_ref, True);
end;

procedure setMenuBar(_1_e_menuBar: int64; _2_e_process: int64);
begin
  //https://developer.4d.com/docs/21/commands/set-menu-bar
  setMenuBar(_1_e_menuBar);
end;

procedure setMenuBar(_1_e_menuBar: int64; _2_e_process: int64; const _3_t_star: string);
begin
  //https://developer.4d.com/docs/21/commands/set-menu-bar
  setMenuBar(_1_e_menuBar, _3_t_star);
end;

procedure setMenuBar(const _1_t_menuBar: string);
var
  _t_ref: string;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-bar
  if (findMenuDefByRef(_1_t_menuBar) <> nil) then begin
    gt_currentMenuBarRef := _1_t_menuBar;
    gt_currentMenuBarKey := '';
    Exit;
  end;

  _t_ref := lookupRegisteredMenuRefByName(_1_t_menuBar);
  if (_t_ref <> '') then begin
    applyRegisteredMenuBar(buildNameMenuBarKey(_1_t_menuBar), _t_ref, False);
    Exit;
  end;

  gt_currentMenuBarRef := resolveMenuRefFromString(_1_t_menuBar);
  gt_currentMenuBarKey := '';
end;

procedure setMenuBar(const _1_t_menuBar: string; const _2_t_star: string);
var
  _t_ref: string;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-bar
  if (findMenuDefByRef(_1_t_menuBar) <> nil) then begin
    gt_currentMenuBarRef := _1_t_menuBar;
    gt_currentMenuBarKey := '';
    Exit;
  end;

  _t_ref := lookupRegisteredMenuRefByName(_1_t_menuBar);
  if ((_2_t_star = '*') and (_t_ref <> '')) then begin
    applyRegisteredMenuBar(buildNameMenuBarKey(_1_t_menuBar), _t_ref, True);
    Exit;
  end;

  setMenuBar(_1_t_menuBar);
end;

procedure appendMenuItem(const _1_t_menu: string; const _2_t_itemText: string; const _3_t_subMenu: string; const _4_t_star: string);
var
  _o_menu: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/append-menu-item
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  appendParsedItems(_o_menu, _2_t_itemText, _3_t_subMenu, _4_t_star);
end;

procedure appendMenuItem(_1_e_menu: int64; const _2_t_itemText: string; const _3_t_subMenu: string; _4_e_process: int64; const _5_t_star: string);
var
  _o_menu: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/append-menu-item
  _o_menu := resolveNumericMenu(_1_e_menu);
  appendParsedItems(_o_menu, _2_t_itemText, _3_t_subMenu, _5_t_star);
end;

procedure insertMenuItem(const _1_t_menu: string; _2_e_afterItem: int64; const _3_t_itemText: string; const _4_t_subMenu: string; const _5_t_star: string);
var
  _o_menu: TQ4MenuDef;
  _o_temp: TQ4MenuDef;
  _e_index: int64;
begin
  //https://developer.4d.com/docs/21/commands/insert-menu-item
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  if (_o_menu = nil) then Exit;

  _o_temp := TQ4MenuDef.Create;
  try
    appendParsedItems(_o_temp, _3_t_itemText, _4_t_subMenu, _5_t_star);

    if (_2_e_afterItem < 0) then _2_e_afterItem := 0;

    if (_2_e_afterItem > _o_menu.o_items.Count) then _2_e_afterItem := _o_menu.o_items.Count;

    for _e_index := 0 to _o_temp.o_items.Count - 1 do _o_menu.o_items.Insert(_2_e_afterItem + _e_index, _o_temp.o_items[_e_index].clone);
  finally
    _o_temp.Free;
  end;

  Exit;
end;

procedure insertMenuItem(_1_e_menu: int64; _2_e_afterItem: int64; const _3_t_itemText: string; const _4_t_subMenu: string;
  _5_e_process: int64; const _6_t_star: string);
var
  _o_menu: TQ4MenuDef;
  _o_temp: TQ4MenuDef;
  _e_index: int64;
begin
  //https://developer.4d.com/docs/21/commands/insert-menu-item
  _o_menu := resolveNumericMenu(_1_e_menu);
  if (_o_menu = nil) then Exit;

  _o_temp := TQ4MenuDef.Create;
  try
    appendParsedItems(_o_temp, _3_t_itemText, _4_t_subMenu, _6_t_star);

    if (_2_e_afterItem < 0) then _2_e_afterItem := 0;

    if (_2_e_afterItem > _o_menu.o_items.Count) then _2_e_afterItem := _o_menu.o_items.Count;

    for _e_index := 0 to _o_temp.o_items.Count - 1 do _o_menu.o_items.Insert(_2_e_afterItem + _e_index, _o_temp.o_items[_e_index].clone);
  finally
    _o_temp.Free;
  end;

  Exit;
end;

procedure setMenuItem(const _1_t_menu: string; _2_e_menuItem: int64; const _3_t_itemText: string; const _4_t_star: string);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then parseItemText(_3_t_itemText, _4_t_star, _o_item);
end;

procedure setMenuItem(_1_e_menu: int64; _2_e_menuItem: int64; const _3_t_itemText: string; _4_e_process: int64; const _5_t_star: string);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then parseItemText(_3_t_itemText, _5_t_star, _o_item);
end;

procedure deleteMenuItem(const _1_t_menu: string; _2_e_menuItem: int64);
var
  _o_menu: TQ4MenuDef;
  _e_index: int64;
begin
  //https://developer.4d.com/docs/21/commands/delete-menu-item
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  if (_o_menu = nil) then Exit;

  _e_index := _2_e_menuItem;
  if (_e_index = -1) then _e_index := _o_menu.o_items.Count;

  if ((_e_index >= 1) and (_e_index <= _o_menu.o_items.Count)) then _o_menu.o_items.Delete(_e_index - 1);

end;

procedure deleteMenuItem(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64);
var
  _o_menu: TQ4MenuDef;
  _e_index: int64;
begin
  //https://developer.4d.com/docs/21/commands/delete-menu-item
  _o_menu := resolveNumericMenu(_1_e_menu);
  if (_o_menu = nil) then Exit;

  _e_index := _2_e_menuItem;
  if (_e_index = -1) then _e_index := _o_menu.o_items.Count;

  if ((_e_index >= 1) and (_e_index <= _o_menu.o_items.Count)) then _o_menu.o_items.Delete(_e_index - 1);

end;

procedure disableMenuItem(const _1_t_menu: string; _2_e_menuItem: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
  _o_subMenu: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/disable-menu-item
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then begin
    _o_item.b_enabled := False;
    if (_o_item.t_subMenuRef <> '') then begin
      _o_subMenu := findMenuDefByRef(_o_item.t_subMenuRef);
      enableRecursive(_o_subMenu, False);
    end;
  end;
end;

procedure disableMenuItem(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
  _o_subMenu: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/disable-menu-item
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then begin
    _o_item.b_enabled := False;
    if (_o_item.t_subMenuRef <> '') then begin
      _o_subMenu := findMenuDefByRef(_o_item.t_subMenuRef);
      enableRecursive(_o_subMenu, False);
    end;
  end;
end;

procedure enableMenuItem(const _1_t_menu: string; _2_e_menuItem: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
  _o_subMenu: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/enable-menu-item
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then begin
    _o_item.b_enabled := True;
    if (_o_item.t_subMenuRef <> '') then begin
      _o_subMenu := findMenuDefByRef(_o_item.t_subMenuRef);
      enableRecursive(_o_subMenu, True);
    end;
  end;
end;

procedure enableMenuItem(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
  _o_subMenu: TQ4MenuDef;
begin
  //https://developer.4d.com/docs/21/commands/enable-menu-item
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then begin
    _o_item.b_enabled := True;
    if (_o_item.t_subMenuRef <> '') then begin
      _o_subMenu := findMenuDefByRef(_o_item.t_subMenuRef);
      enableRecursive(_o_subMenu, True);
    end;
  end;
end;

function getMenuItem(const _1_t_menu: string; _2_e_menuItem: int64): string;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  Result := getTextForItem(_o_item);
end;

function getMenuItem(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64): string;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  Result := getTextForItem(_o_item);
end;

function getMenuItemKey(const _1_t_menu: string; _2_e_menuItem: int64): int64;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-key
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item = nil) then Exit(0);

  Result := _o_item.e_shortcutKey;
end;

function getMenuItemKey(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64): int64;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-key
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item = nil) then Exit(0);

  Result := _o_item.e_shortcutKey;
end;

function getMenuItemMark(const _1_t_menu: string; _2_e_menuItem: int64): string;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-mark
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if ((_o_item = nil) or (_o_item.t_subMenuRef <> '')) then Exit('');

  Result := _o_item.t_mark;
end;

function getMenuItemMark(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64): string;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-mark
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if ((_o_item = nil) or (_o_item.t_subMenuRef <> '')) then Exit('');

  Result := _o_item.t_mark;
end;

function getMenuItemMethod(const _1_t_menu: string; _2_e_menuItem: int64): string;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-method
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item = nil) then Exit('');

  Result := _o_item.t_methodName;
end;

function getMenuItemMethod(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64): string;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-method
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item = nil) then Exit('');

  Result := _o_item.t_methodName;
end;

function getMenuItemModifiers(const _1_t_menu: string; _2_e_menuItem: int64): int64;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-modifiers
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item = nil) then Exit(0);

  Result := _o_item.e_modifiers;
end;

function getMenuItemModifiers(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64): int64;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-modifiers
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item = nil) then Exit(0);

  Result := _o_item.e_modifiers;
end;

function getMenuItemParameter(const _1_t_menu: string; _2_e_menuItem: int64): string;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-parameter
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item = nil) then Exit('');

  Result := _o_item.t_parameter;
end;

function getMenuItemParameter(_1_e_menu: int64; _2_e_menuItem: int64): string;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-parameter
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item = nil) then Exit('');

  Result := _o_item.t_parameter;
end;

function getMenuItemStyle(const _1_t_menu: string; _2_e_menuItem: int64): int64;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-style
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item = nil) then Exit(0);

  Result := _o_item.e_style;
end;

function getMenuItemStyle(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_process: int64): int64;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-style
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item = nil) then Exit(0);

  Result := _o_item.e_style;
end;

procedure getMenuItemIcon(const _1_t_menu: string; _2_e_menuItem: int64; out _3_v_iconRef: variant);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-icon
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item = nil) then begin
    _3_v_iconRef := Null;
    Exit;
  end;

  _3_v_iconRef := _o_item.v_iconRef;
end;

procedure getMenuItemIcon(_1_e_menu: int64; _2_e_menuItem: int64; out _3_v_iconRef: variant; _4_e_process: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-icon
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item = nil) then begin
    _3_v_iconRef := Null;
    Exit;
  end;

  _3_v_iconRef := _o_item.v_iconRef;
end;

procedure getMenuItemProperty(const _1_t_menu: string; _2_e_menuItem: int64; const _3_t_property: string; out _4_v_value: variant);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
  _o_property: TQ4MenuPropertyDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-property
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  _o_property := nil;

  if (_o_item <> nil) then _o_property := findPropertyByName(_o_item.o_properties, _3_t_property);

  if (_o_property = nil) then begin
    _4_v_value := Null;
    Exit;
  end;

  _4_v_value := _o_property.v_value;
end;

procedure getMenuItemProperty(_1_e_menu: int64; _2_e_menuItem: int64; const _3_t_property: string; out _4_v_value: variant; _5_e_process: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
  _o_property: TQ4MenuPropertyDef;
begin
  //https://developer.4d.com/docs/21/commands/get-menu-item-property
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  _o_property := nil;

  if (_o_item <> nil) then _o_property := findPropertyByName(_o_item.o_properties, _3_t_property);

  if (_o_property = nil) then begin
    _4_v_value := Null;
    Exit;
  end;

  _4_v_value := _o_property.v_value;
end;

procedure setMenuItemMark(const _1_t_menu: string; _2_e_menuItem: int64; const _3_t_mark: string);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-mark
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then _o_item.t_mark := _3_t_mark;
end;

procedure setMenuItemMark(_1_e_menu: int64; _2_e_menuItem: int64; const _3_t_mark: string; _4_e_process: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-mark
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then _o_item.t_mark := _3_t_mark;
end;

procedure setMenuItemMethod(const _1_t_menu: string; _2_e_menuItem: int64; const _3_t_methodName: string);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-method
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then _o_item.t_methodName := _3_t_methodName;
end;

procedure setMenuItemMethod(_1_e_menu: int64; _2_e_menuItem: int64; const _3_t_methodName: string; _4_e_process: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-method
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then _o_item.t_methodName := _3_t_methodName;
end;

procedure setMenuItemParameter(const _1_t_menu: string; _2_e_menuItem: int64; const _3_t_param: string);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-parameter
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then _o_item.t_parameter := _3_t_param;
end;

procedure setMenuItemParameter(_1_e_menu: int64; _2_e_menuItem: int64; const _3_t_param: string);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-parameter
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then _o_item.t_parameter := _3_t_param;
end;

procedure setMenuItemStyle(const _1_t_menu: string; _2_e_menuItem: int64; _3_e_itemStyle: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-style
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then _o_item.e_style := _3_e_itemStyle;
end;

procedure setMenuItemStyle(_1_e_menu: int64; _2_e_menuItem: int64; _3_e_itemStyle: int64; _4_e_process: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-style
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then _o_item.e_style := _3_e_itemStyle;
end;

procedure setMenuItemShortcut(const _1_t_menu: string; _2_e_menuItem: int64; const _3_v_itemKey: variant; _4_e_modifiers: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-shortcut
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then begin
    _o_item.e_shortcutKey := resolveShortcutKey(_3_v_itemKey);
    _o_item.e_modifiers := _4_e_modifiers;
  end;
end;

procedure setMenuItemShortcut(_1_e_menu: int64; _2_e_menuItem: int64; const _3_v_itemKey: variant; _4_e_modifiers: int64; _5_e_process: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-shortcut
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then begin
    _o_item.e_shortcutKey := resolveShortcutKey(_3_v_itemKey);
    _o_item.e_modifiers := _4_e_modifiers;
  end;
end;

procedure setMenuItemIcon(const _1_t_menu: string; _2_e_menuItem: int64; const _3_v_iconRef: variant);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-icon
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then _o_item.v_iconRef := _3_v_iconRef;
end;

procedure setMenuItemIcon(_1_e_menu: int64; _2_e_menuItem: int64; const _3_v_iconRef: variant; _4_e_process: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-icon
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  if (_o_item <> nil) then _o_item.v_iconRef := _3_v_iconRef;
end;

procedure setMenuItemProperty(const _1_t_menu: string; _2_e_menuItem: int64; const _3_t_property: string; const _4_v_value: variant);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-property
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  setPropertyValue(_o_item, _3_t_property, _4_v_value);
end;

procedure setMenuItemProperty(_1_e_menu: int64; _2_e_menuItem: int64; const _3_t_property: string; const _4_v_value: variant; _5_e_process: int64);
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
begin
  //https://developer.4d.com/docs/21/commands/set-menu-item-property
  _o_menu := resolveNumericMenu(_1_e_menu);
  _o_item := getItemByIndex(_o_menu, _2_e_menuItem);
  setPropertyValue(_o_item, _3_t_property, _4_v_value);
end;

function dynamicPopUpMenu(const _1_t_menu: string): string;
begin
  //https://developer.4d.com/docs/21/commands/dynamic-pop-up-menu
  Result := dynamicPopUpMenu(_1_t_menu, '');
end;

function dynamicPopUpMenu(const _1_t_menu: string; const _2_t_default: string): string;
begin
  //https://developer.4d.com/docs/21/commands/dynamic-pop-up-menu
  Result := dynamicPopUpMenu(_1_t_menu, _2_t_default, 0, 0);
end;

function dynamicPopUpMenu(const _1_t_menu: string; const _2_t_default: string; _3_e_xCoord: int64; _4_e_yCoord: int64): string;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
  _e_selectedIndex: int64;
begin
  //https://developer.4d.com/docs/21/commands/dynamic-pop-up-menu
  _o_menu := resolveMenuDefFromString(_1_t_menu);
  if (_o_menu = nil) then Exit('');

  _e_selectedIndex := findSelectableItemIndex(_o_menu, _2_t_default);
  if (_e_selectedIndex < 0) then begin
    gt_lastSelectedSubMenuRef := '';
    gt_lastSelectedParameter := '';
    ge_lastSelectedMenuCode := 0;
    Result := '';
    Exit;
  end;

  _o_item := _o_menu.o_items[_e_selectedIndex];
  if (_o_item.t_parameter <> '') then Result := _o_item.t_parameter
  else
    Result := getTextForItem(_o_item);

  ge_lastSelectedMenuCode := packMenuSelected(1, _e_selectedIndex + 1);
  gt_lastSelectedSubMenuRef := _o_item.t_subMenuRef;
  gt_lastSelectedParameter := Result;
end;

function menuSelected: int64;
begin
  //https://developer.4d.com/docs/21/commands/menu-selected
  Result := ge_lastSelectedMenuCode;
end;

function menuSelected(out _1_t_subMenu: string): int64;
begin
  //https://developer.4d.com/docs/21/commands/menu-selected
  _1_t_subMenu := gt_lastSelectedSubMenuRef;
  Result := ge_lastSelectedMenuCode;
end;

function getSelectedMenuItemParameter: string;
begin
  //https://developer.4d.com/docs/21/commands/get-selected-menu-item-parameter
  Result := gt_lastSelectedParameter;
end;

procedure setHelpMenu(const _1_t_menuColJson: string);
begin
  //https://developer.4d.com/docs/21/commands/set-help-menu
  gt_helpMenuJson := _1_t_menuColJson;
end;

function popUpMenuEmulation(const _1_t_contents: string): int64;
begin
  Result := popUpMenuEmulation(_1_t_contents, 1, 0, 0);
end;

function popUpMenuEmulation(const _1_t_contents: string; _2_e_default: int64): int64;
begin
  Result := popUpMenuEmulation(_1_t_contents, _2_e_default, 0, 0);
end;

function popUpMenuEmulation(const _1_t_contents: string; _2_e_default: int64; _3_e_xCoord: int64; _4_e_yCoord: int64): int64;
var
  _o_menu: TQ4MenuDef;
  _o_item: TQ4MenuItemDef;
  _e_selectedIndex: int64;
  _t_default: string;
begin
  //https://developer.4d.com/docs/21/commands/pop-up-menu
  // This helper intentionally does not display a real UI. It reuses q4 menu parsing and
  // selects the requested default item, or the first selectable item when the default is invalid.
  Result := 0;
  gt_lastSelectedSubMenuRef := '';
  gt_lastSelectedParameter := '';
  ge_lastSelectedMenuCode := 0;

  _o_menu := TQ4MenuDef.Create;
  try
    appendParsedItems(_o_menu, _1_t_contents, '', '');

    if (_2_e_default > 0) then _t_default := IntToStr(_2_e_default)
    else
      _t_default := '';

    _e_selectedIndex := -1;
    if (_2_e_default > 0) then begin
      if (_2_e_default <= _o_menu.o_items.Count) then begin
        _o_item := _o_menu.o_items[_2_e_default - 1];
        if ((_o_item <> nil) and (not _o_item.b_isSeparator) and _o_item.b_enabled) then _e_selectedIndex := _2_e_default - 1;
      end;
    end;

    if (_e_selectedIndex < 0) then _e_selectedIndex := findSelectableItemIndex(_o_menu, _t_default);
    if (_e_selectedIndex < 0) then Exit;

    _o_item := _o_menu.o_items[_e_selectedIndex];
    Result := _e_selectedIndex + 1;
    ge_lastSelectedMenuCode := packMenuSelected(1, Result);
    gt_lastSelectedSubMenuRef := _o_item.t_subMenuRef;
    if (_o_item.t_parameter <> '') then gt_lastSelectedParameter := _o_item.t_parameter
    else
      gt_lastSelectedParameter := getTextForItem(_o_item);
  finally
    _o_menu.Free;
  end;
end;

function isMenuBarVisible: boolean;
begin
  ensureMenuBarVisibilityInitialized;
  Result := gb_menuBarVisible;
end;

procedure setMenuBarVisible(_1_b_visible: boolean);
begin
  // q4userInterface maps SHOW MENU BAR / HIDE MENU BAR to this logical state.
  ensureMenuBarVisibilityInitialized;
  gb_menuBarVisible := _1_b_visible;
end;

procedure setAboutMenuItem(const _1_t_itemText: string; const _2_t_method: string);
begin
  //https://developer.4d.com/docs/21/commands/set-about
  gt_aboutMenuItemText := _1_t_itemText;
  gt_aboutMenuItemMethod := _2_t_method;
end;

function getAboutMenuItemText: string;
begin
  Result := gt_aboutMenuItemText;
end;

function getAboutMenuItemMethod: string;
begin
  Result := gt_aboutMenuItemMethod;
end;

end.
