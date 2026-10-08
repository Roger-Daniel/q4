Unit q4windows;

{$mode objfpc}{$H+}

{
q4windows
version du 2026/04/18-17:58

Mapping 4D
Command Number 4D,   4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
154,                 CLOSE WINDOW,                     closeWindow,                      OK,
1365,                CONVERT COORDINATES,              convertCoordinates,               Partial,
827,                 Current form window,              currentFormWindow,                Partial,
452,                 DRAG WINDOW,                      dragWindow,                       TODO,
160,                 ERASE WINDOW,                     eraseWindow,                      Partial,
449,                 Find window,                      findWindow,                       OK,
447,                 Frontmost window,                 frontmostWindow,                  OK,
443,                 GET WINDOW RECT,                  getWindowRect,                    OK,
450,                 Get window title,                 getWindowTitle,                   OK,
434,                 HIDE TOOL BAR,                    hideToolBar,                      TODO,
436,                 HIDE WINDOW,                      hideWindow,                       OK,
1830,                Is window maximized,              isWindowMaximized,                OK,
1831,                Is window reduced,                isWindowReduced,                  OK,
453,                 MAXIMIZE WINDOW,                  maximizeWindow,                   OK,
454,                 MINIMIZE WINDOW,                  minimizeWindow,                   Partial,
448,                 Next window,                      nextWindow,                       OK,
675,                 Open form window,                 openFormWindow,                   TODO,
153,                 Open window,                      openWindow,                       OK,
456,                 REDRAW WINDOW,                    redrawWindow,                     OK,
1829,                REDUCE RESTORE WINDOW,            reduceRestoreWindow,              OK,
890,                 RESIZE FORM WINDOW,               resizeFormWindow,                 Partial,
?,                   SET WINDOW DOCUMENT ICON,         setWindowDocumentIcon,            TODO,
444,                 SET WINDOW RECT,                  setWindowRect,                    OK,
213,                 SET WINDOW TITLE,                 setWindowTitle,                   OK,
433,                 SHOW TOOL BAR,                    showToolBar,                      TODO,
435,                 SHOW WINDOW,                      showWindow,                       OK,
1016,                Tool bar height,                  toolBarHeight,                    TODO,
445,                 Window kind,                      windowKind,                       OK,
442,                 WINDOW LIST,                      windowList,                       OK,
446,                 Window process,                   windowProcess,                    OK,

Doc: https://developer.4d.com/docs/21/commands/theme/Windows

Note TODO openFormWindow:
En attente de décision sur l'usage des forms HTML convertis comme source
réelle d'affichage. Ne pas figer l'implémentation avant validation de la
chaîne form 4D logique -> HTML converti -> webarea.

}


Interface

Uses
  Classes,
  SysUtils,
  Forms,
  Controls,
  Graphics,
  Types,
  Contnrs,
  LazUTF8;

Const
  // Windows theme - coordinate systems
  XY_CURRENT_FORM = 1;
  XY_CURRENT_WINDOW = 2;
  XY_SCREEN = 3;
  XY_MAIN_WINDOW = 4;

  // Open form window theme - window types
  MODAL_FORM_DIALOG_BOX = 1;
  MOVABLE_FORM_DIALOG_BOX = 5;
  PLAIN_FORM_WINDOW = 8;
  POP_UP_FORM_WINDOW = 32;
  SHEET_FORM_WINDOW = 33;
  TOOLBAR_FORM_WINDOW = 35;
  PALETTE_FORM_WINDOW = 1984;
  FORM_HAS_NO_MENU_BAR = 2048;
  CONTROLLER_FORM_WINDOW = 133056;
  FORM_HAS_FULL_SCREEN_MODE_MAC = 65536;
  MOVABLE_FORM_DIALOG_BOX_NO_TITLE = 524293;
  PLAIN_FORM_WINDOW_NO_TITLE = 524296;

  // Open form window theme - positions
  HORIZONTALLY_CENTERED = 65536;
  ON_THE_LEFT = 131072;
  ON_THE_RIGHT = 196608;
  VERTICALLY_CENTERED = 262144;
  AT_THE_TOP = 327680;
  AT_THE_BOTTOM = 393216;

  // Window kind theme
  EXTERNAL_WINDOW = 5;
  REGULAR_WINDOW = 8;
  MODAL_DIALOG = 9;
  FLOATING_WINDOW = 14;

Type
  Tq4Int64Array = Array Of int64;



Function currentFormWindow: int64;
Function findWindow( _1_e_left: int64; _2_e_top: int64; out _3_e_windowPart: int64): int64;
Function frontmostWindow( Const _1_t_star: string = ''): int64;
Function getWindowTitle( _1_e_window: int64 = 0): string;
Function isWindowMaximized( _1_e_window: int64): boolean;
Function isWindowReduced( _1_e_window: int64): boolean;
Function nextWindow( _1_e_window: int64): int64;
Function openFormWindow( Const _1_t_formName: string; _2_e_type: int64 = PLAIN_FORM_WINDOW; _3_e_hPos: int64 = 0; _4_e_vPos: int64 = 0; Const _5_t_star: string = ''): int64; overload;
Function openFormWindow( _1_e_aTable: int64; Const _2_t_formName: string; _3_e_type: int64 = PLAIN_FORM_WINDOW; _4_e_hPos: int64 = 0; _5_e_vPos: int64 = 0;
  Const _6_t_star: string = ''): int64; overload;
Function openWindow( _1_e_left: int64; _2_e_top: int64; _3_e_right: int64; _4_e_bottom: int64; _5_e_type: int64 = 1; Const _6_t_title: string = ''; Const _7_t_controlMenuBox: string = ''): int64;
Function toolBarHeight: int64;
Function windowKind( _1_e_window: int64 = 0): int64;
Function windowProcess( _1_e_window: int64 = 0): int64;

Procedure closeWindow( _1_e_window: int64 = 0);
Procedure convertCoordinates( Var _1_e_xCoord: int64; Var _2_e_yCoord: int64; _3_e_from: int64; _4_e_to: int64);
Procedure dragWindow;
Procedure eraseWindow( _1_e_window: int64 = 0);
Procedure getWindowRect( Var _1_e_left: int64; Var _2_e_top: int64; Var _3_e_right: int64; Var _4_e_bottom: int64; _5_e_window: int64 = 0);
Procedure hideToolBar;
Procedure hideWindow( _1_e_window: int64 = 0);
Procedure maximizeWindow( _1_e_window: int64 = 0);
Procedure minimizeWindow( _1_e_window: int64 = 0);
Procedure redrawWindow( _1_e_window: int64 = 0);
Procedure reduceRestoreWindow( _1_e_window: int64);
Procedure resizeFormWindow( _1_e_width: int64; _2_e_height: int64);
Procedure setWindowDocumentIcon( _1_e_winRef: int64); overload;
Procedure setWindowDocumentIcon( _1_e_winRef: int64; Const _2_y_image: TBytes); overload;
Procedure setWindowDocumentIcon( _1_e_winRef: int64; Const _2_t_file: string); overload;
Procedure setWindowDocumentIcon( _1_e_winRef: int64; Const _2_y_image: TBytes; Const _3_t_file: string); overload;
Procedure setWindowRect( _1_e_left: int64; _2_e_top: int64; _3_e_right: int64; _4_e_bottom: int64; _5_e_window: int64 = 0; Const _6_t_star: string = '');
Procedure setWindowTitle( Const _1_t_title: string; _2_e_window: int64 = 0);
Procedure showToolBar;
Procedure showWindow( _1_e_window: int64 = 0);
Procedure windowList( out _1_te_windows: Tq4Int64Array; Const _2_t_star: string = '');

Implementation

Type
  TQ4WindowEntry = Class
  public
    e_windowRef: int64;
    o_form: Forms.TForm;
    e_windowKind: int64;
    e_processRef: int64;
    e_zOrder: int64;
    b_hidden: boolean;
    b_isFormWindow: boolean;
    b_isToolBar: boolean;
    t_formName: string;
    t_htmlNote: string;
  End;

Var
  go_windows: Contnrs.TObjectList = nil;
  ge_nextWindowRef: int64 = 1;
  ge_zOrderCounter: int64 = 0;

Threadvar
  ge_currentFormWindowRef: int64;
  ge_lastOpenedWindowRef:  int64;
  ge_toolBarWindowRef:     int64;

Procedure ensureRegistry;
  Begin
    If ( go_windows = nil) Then go_windows := Contnrs.TObjectList.Create( True);
  End;

Function currentProcessRef: int64;
  Begin
    Result := int64( System.GetCurrentThreadId);
  End;

Function nextManagedWindowRef: int64;
  Begin
    Result := ge_nextWindowRef;
    ge_nextWindowRef := ge_nextWindowRef + 1;
  End;

Function nextZOrder: int64;
  Begin
    ge_zOrderCounter := ge_zOrderCounter + 1;
    Result := ge_zOrderCounter;
  End;

Function clipWindowTitle( Const _1_t_title: string): string;
  Begin
    Result := _1_t_title;
    If ( LazUTF8.UTF8Length( Result) > 80) Then Result := LazUTF8.UTF8Copy( Result, 1, 80);
  End;

Function windowEntryByRef( _1_e_windowRef: int64): TQ4WindowEntry;
  Var
    _e_index: int64;
    _o_entry: TQ4WindowEntry;
  Begin
    Result := nil;
    If ( go_windows = nil) Then Exit;

    For _e_index := 0 To go_windows.Count - 1 Do Begin
      _o_entry := TQ4WindowEntry( go_windows[_e_index]);
      If ( _o_entry.e_windowRef = _1_e_windowRef) Then Begin
        Result := _o_entry;
        Exit;
      End;
    End;
  End;

Function frontmostCurrentProcessEntry( Const _1_t_star: string = ''): TQ4WindowEntry;
  Var
    _e_index:      int64;
    _o_entry:      TQ4WindowEntry;
    _e_processRef: int64;
  Begin
    Result := nil;
    If ( go_windows = nil) Then Exit;

    _e_processRef := currentProcessRef;
    For _e_index := 0 To go_windows.Count - 1 Do Begin
      _o_entry := TQ4WindowEntry( go_windows[_e_index]);
      If ( _o_entry.e_processRef <> _e_processRef) Then Continue;
      If ( _o_entry.b_hidden) Then Continue;
      If ( ( _1_t_star <> '*') and ( _o_entry.e_windowKind = FLOATING_WINDOW)) Then Continue;
      If ( ( Result = nil) or ( _o_entry.e_zOrder > Result.e_zOrder)) Then Result := _o_entry;
    End;
  End;

Function frontmostGlobalEntry( Const _1_t_star: string = ''): TQ4WindowEntry;
  Var
    _e_index: int64;
    _o_entry: TQ4WindowEntry;
  Begin
    Result := nil;
    If ( go_windows = nil) Then Exit;

    For _e_index := 0 To go_windows.Count - 1 Do Begin
      _o_entry := TQ4WindowEntry( go_windows[_e_index]);
      If ( _o_entry.b_hidden) Then Continue;
      If ( ( _1_t_star <> '*') and ( _o_entry.e_windowKind = FLOATING_WINDOW)) Then Continue;
      If ( ( Result = nil) or ( _o_entry.e_zOrder > Result.e_zOrder)) Then Result := _o_entry;
    End;
  End;

Function resolveWindowEntry( _1_e_window: int64): TQ4WindowEntry;
  Begin
    Result := nil;
    If ( _1_e_window <> 0) Then Result := windowEntryByRef( _1_e_window)
    Else
      Result := frontmostCurrentProcessEntry( '*');
  End;

Procedure touchWindowEntry( _1_o_entry: TQ4WindowEntry);
  Begin
    If ( _1_o_entry = nil) Then Exit;
    _1_o_entry.e_zOrder := nextZOrder;
  End;

Procedure coordinateOrigin( _1_e_system: int64; out _2_e_originX: int64; out _3_e_originY: int64);
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    _2_e_originX := 0;
    _3_e_originY := 0;

    Case _1_e_system Of
      XY_CURRENT_FORM,
      XY_CURRENT_WINDOW: Begin
        _o_entry := resolveWindowEntry( 0);
        If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Begin
          _2_e_originX := _o_entry.o_form.Left;
          _3_e_originY := _o_entry.o_form.Top;
        End;
      End;
      XY_MAIN_WINDOW: If ( Forms.Application.MainForm <> nil) Then Begin
          _2_e_originX := Forms.Application.MainForm.Left;
          _3_e_originY := Forms.Application.MainForm.Top;
        End;
      XY_SCREEN: Begin
        _2_e_originX := 0;
        _3_e_originY := 0;
      End;
    End;
  End;

Function currentFormWindow: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/current-form-window
    Result := ge_currentFormWindowRef;
  End;

Function findWindow( _1_e_left: int64; _2_e_top: int64; out _3_e_windowPart: int64): int64;
  Var
    _e_index: int64;
    _o_entry: TQ4WindowEntry;
    _o_rect:  Types.TRect;
    _o_best:  TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/find-window
    Result := 0;
    _3_e_windowPart := 0;
    _o_best := nil;

    If ( go_windows = nil) Then Exit;

    For _e_index := 0 To go_windows.Count - 1 Do Begin
      _o_entry := TQ4WindowEntry( go_windows[_e_index]);
      If ( _o_entry.b_hidden) Then Continue;
      If ( _o_entry.o_form = nil) Then Continue;

      _o_rect := Types.Rect( _o_entry.o_form.Left, _o_entry.o_form.Top, _o_entry.o_form.Left + _o_entry.o_form.Width, _o_entry.o_form.Top + _o_entry.o_form.Height);
      If ( Types.PtInRect( _o_rect, Types.Point( _1_e_left, _2_e_top))) Then If ( ( _o_best = nil) or ( _o_entry.e_zOrder > _o_best.e_zOrder)) Then _o_best := _o_entry;
    End;

    If ( _o_best <> nil) Then Begin
      Result := _o_best.e_windowRef;
      _3_e_windowPart := 3;
    End;
  End;

Function frontmostWindow( Const _1_t_star: string = ''): int64;
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/frontmost-window
    Result := 0;
    _o_entry := frontmostGlobalEntry( _1_t_star);
    If ( _o_entry <> nil) Then Result := _o_entry.e_windowRef;
  End;

Function getWindowTitle( _1_e_window: int64 = 0): string;
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/get-window-title
    Result := '';
    _o_entry := resolveWindowEntry( _1_e_window);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Result := _o_entry.o_form.Caption;
  End;

Function isWindowMaximized( _1_e_window: int64): boolean;
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/is-window-maximized
    Result := False;
    _o_entry := windowEntryByRef( _1_e_window);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Result := _o_entry.o_form.WindowState = Forms.wsMaximized;
  End;

Function isWindowReduced( _1_e_window: int64): boolean;
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/is-window-reduced
    Result := False;
    _o_entry := windowEntryByRef( _1_e_window);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Result := _o_entry.o_form.WindowState = Forms.wsMinimized;
  End;

Function nextWindow( _1_e_window: int64): int64;
  Var
    _o_current: TQ4WindowEntry;
    _o_entry:   TQ4WindowEntry;
    _o_next:    TQ4WindowEntry;
    _e_index:   int64;
  Begin
    //https://developer.4d.com/docs/21/commands/next-window
    Result := 0;
    _o_current := windowEntryByRef( _1_e_window);
    If ( _o_current = nil) Then Exit;

    _o_next := nil;
    If ( go_windows = nil) Then Exit;

    For _e_index := 0 To go_windows.Count - 1 Do Begin
      _o_entry := TQ4WindowEntry( go_windows[_e_index]);
      If ( _o_entry.b_hidden) Then Continue;
      If ( _o_entry.e_zOrder >= _o_current.e_zOrder) Then Continue;
      If ( ( _o_next = nil) or ( _o_entry.e_zOrder > _o_next.e_zOrder)) Then _o_next := _o_entry;
    End;

    If ( _o_next <> nil) Then Result := _o_next.e_windowRef;
  End;

Function openFormWindow( Const _1_t_formName: string; _2_e_type: int64 = PLAIN_FORM_WINDOW; _3_e_hPos: int64 = 0; _4_e_vPos: int64 = 0; Const _5_t_star: string = ''): int64;
  Begin
    //https://developer.4d.com/docs/21/commands/open-form-window
    Result := 0;
    // TODO
    // Implémentation différée.
    // Le comportement final dépend du choix d'intégration entre :
    // - le form 4D logique,
    // - sa version HTML convertie,
    // - et son hébergement dans une webarea.
    // Ne pas figer l'implémentation avant validation de cette chaîne.
    If ( _1_t_formName <> '') Then // Paramètre volontairement lu pour documenter l'intention.
    ;
    If ( _2_e_type <> 0) Then;
    If ( _3_e_hPos <> 0) Then;
    If ( _4_e_vPos <> 0) Then;
    If ( _5_t_star <> '') Then;
  End;

Function openFormWindow( _1_e_aTable: int64; Const _2_t_formName: string; _3_e_type: int64 = PLAIN_FORM_WINDOW; _4_e_hPos: int64 = 0; _5_e_vPos: int64 = 0; Const _6_t_star: string = ''): int64;
  Begin
    //https://developer.4d.com/docs/21/commands/open-form-window
    Result := 0;
    If ( _1_e_aTable <> 0) Then;
    Result := q4windows.openFormWindow( _2_t_formName, _3_e_type, _4_e_hPos, _5_e_vPos, _6_t_star);
  End;

Function openWindow( _1_e_left: int64; _2_e_top: int64; _3_e_right: int64; _4_e_bottom: int64; _5_e_type: int64 = 1; Const _6_t_title: string = ''; Const _7_t_controlMenuBox: string = ''): int64;
  Var
    _o_entry:  TQ4WindowEntry;
    _o_form:   Forms.TForm;
    _e_width:  int64;
    _e_height: int64;
    _t_windowTitle: string;
    _b_isFloating: boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/open-window
    ensureRegistry;

    _o_form := Forms.TForm.CreateNew( Forms.Application);
    _o_entry := TQ4WindowEntry.Create;

    Result := nextManagedWindowRef;
    _o_entry.e_windowRef := Result;
    _o_entry.o_form := _o_form;
    _o_entry.e_processRef := currentProcessRef;
    _o_entry.e_zOrder := nextZOrder;
    _o_entry.b_hidden := False;
    _o_entry.b_isFormWindow := False;
    _o_entry.b_isToolBar := False;
    _o_entry.t_formName := '';
    _o_entry.t_htmlNote := '';

    _b_isFloating := _5_e_type < 0;
    If ( _b_isFloating) Then _o_entry.e_windowKind := FLOATING_WINDOW
    Else
      _o_entry.e_windowKind := REGULAR_WINDOW;

    _e_width := _3_e_right - _1_e_left;
    _e_height := _4_e_bottom - _2_e_top;
    If ( ( _3_e_right = -1) and ( _4_e_bottom = -1)) Then Begin
      _e_width := 800;
      _e_height := 600;
    End;
    If ( _e_width <= 0) Then _e_width := 800;
    If ( _e_height <= 0) Then _e_height := 600;

    _t_windowTitle := clipWindowTitle( _6_t_title);
    If ( _t_windowTitle = '') Then _t_windowTitle := 'q4 window ' + SysUtils.IntToStr( Result);

    _o_form.Position := Forms.poDesigned;
    _o_form.Caption := _t_windowTitle;
    _o_form.SetBounds( _1_e_left, _2_e_top, _e_width, _e_height);

    If ( _5_e_type = MODAL_FORM_DIALOG_BOX) Then Begin
      _o_form.BorderStyle := bsDialog;
      _o_entry.e_windowKind := MODAL_DIALOG;
    End Else If ( ( _5_e_type = MOVABLE_FORM_DIALOG_BOX_NO_TITLE) or ( _5_e_type = PLAIN_FORM_WINDOW_NO_TITLE)) Then _o_form.BorderStyle := bsNone
    Else
      _o_form.BorderStyle := bsSizeable;

    If ( _b_isFloating) Then _o_form.FormStyle := fsStayOnTop
    Else
      _o_form.FormStyle := fsNormal;

    go_windows.Add( _o_entry);
    ge_lastOpenedWindowRef := Result;
    If ( _7_t_controlMenuBox <> '') Then // TODO: callback controlMenuBox non géré dans cette première version.
    ;

    _o_form.Show;
    touchWindowEntry( _o_entry);
  End;

Function toolBarHeight: int64;
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/tool-bar-height
    Result := 0;
    If ( ge_toolBarWindowRef = 0) Then Exit;

    _o_entry := windowEntryByRef( ge_toolBarWindowRef);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil) and ( not _o_entry.b_hidden)) Then Result := _o_entry.o_form.Height;
  End;

Function windowKind( _1_e_window: int64 = 0): int64;
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/window-kind
    Result := 0;
    _o_entry := resolveWindowEntry( _1_e_window);
    If ( _o_entry <> nil) Then Result := _o_entry.e_windowKind;
  End;

Function windowProcess( _1_e_window: int64 = 0): int64;
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/window-process
    Result := 0;
    _o_entry := resolveWindowEntry( _1_e_window);
    If ( _o_entry <> nil) Then Result := _o_entry.e_processRef;
  End;

Procedure closeWindow( _1_e_window: int64 = 0);
  Var
    _o_entry: TQ4WindowEntry;
    _e_lastOpenedWindowRef: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/close-window
    _o_entry := nil;
    _e_lastOpenedWindowRef := ge_lastOpenedWindowRef;

    If ( _e_lastOpenedWindowRef <> 0) Then Begin
      _o_entry := windowEntryByRef( _e_lastOpenedWindowRef);
      If ( ( _o_entry <> nil) and ( _o_entry.e_processRef <> currentProcessRef)) Then _o_entry := nil;
    End;

    If ( ( _o_entry = nil) and ( _1_e_window <> 0)) Then _o_entry := windowEntryByRef( _1_e_window);

    If ( _o_entry = nil) Then Exit;

    If ( _o_entry.e_windowRef = ge_toolBarWindowRef) Then ge_toolBarWindowRef := 0;
    If ( _o_entry.e_windowRef = ge_currentFormWindowRef) Then ge_currentFormWindowRef := 0;
    If ( _o_entry.e_windowRef = ge_lastOpenedWindowRef) Then ge_lastOpenedWindowRef := 0;

    If ( _o_entry.o_form <> nil) Then Begin
      _o_entry.o_form.Close;
      _o_entry.o_form.Free;
      _o_entry.o_form := nil;
    End;
    If ( go_windows <> nil) Then go_windows.Remove( _o_entry);
  End;

Procedure convertCoordinates( Var _1_e_xCoord: int64; Var _2_e_yCoord: int64; _3_e_from: int64; _4_e_to: int64);
  Var
    _e_fromOriginX: int64;
    _e_fromOriginY: int64;
    _e_toOriginX:   int64;
    _e_toOriginY:   int64;
  Begin
    //https://developer.4d.com/docs/21/commands/convert-coordinates
    coordinateOrigin( _3_e_from, _e_fromOriginX, _e_fromOriginY);
    coordinateOrigin( _4_e_to, _e_toOriginX, _e_toOriginY);

    _1_e_xCoord := _1_e_xCoord + _e_fromOriginX - _e_toOriginX;
    _2_e_yCoord := _2_e_yCoord + _e_fromOriginY - _e_toOriginY;
  End;

Procedure dragWindow;
  Begin
    //https://developer.4d.com/docs/21/commands/drag-window
    // TODO: non implémenté dans cette première version.
  End;

Procedure eraseWindow( _1_e_window: int64 = 0);
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/erase-window
    _o_entry := resolveWindowEntry( _1_e_window);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Begin
      _o_entry.o_form.Invalidate;
      _o_entry.o_form.Update;
    End;
  End;

Procedure getWindowRect( Var _1_e_left: int64; Var _2_e_top: int64; Var _3_e_right: int64; Var _4_e_bottom: int64; _5_e_window: int64 = 0);
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/get-window-rect
    _o_entry := resolveWindowEntry( _5_e_window);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Begin
      _1_e_left := _o_entry.o_form.Left;
      _2_e_top := _o_entry.o_form.Top;
      _3_e_right := _o_entry.o_form.Left + _o_entry.o_form.Width;
      _4_e_bottom := _o_entry.o_form.Top + _o_entry.o_form.Height;
    End;
  End;

Procedure hideToolBar;
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/hide-tool-bar
    _o_entry := windowEntryByRef( ge_toolBarWindowRef);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Begin
      _o_entry.o_form.Hide;
      _o_entry.b_hidden := True;
    End;
  End;

Procedure hideWindow( _1_e_window: int64 = 0);
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/hide-window
    _o_entry := resolveWindowEntry( _1_e_window);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Begin
      _o_entry.o_form.Hide;
      _o_entry.b_hidden := True;
    End;
  End;

Procedure maximizeWindow( _1_e_window: int64 = 0);
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/maximize-window
    _o_entry := resolveWindowEntry( _1_e_window);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Begin
      _o_entry.o_form.WindowState := Forms.wsMaximized;
      touchWindowEntry( _o_entry);
    End;
  End;

Procedure minimizeWindow( _1_e_window: int64 = 0);
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/minimize-window
    _o_entry := resolveWindowEntry( _1_e_window);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then If ( _o_entry.o_form.WindowState = Forms.wsMaximized) Then _o_entry.o_form.WindowState := Forms.wsNormal;
  End;

Procedure redrawWindow( _1_e_window: int64 = 0);
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/redraw-window
    _o_entry := resolveWindowEntry( _1_e_window);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Begin
      _o_entry.o_form.Invalidate;
      _o_entry.o_form.Update;
    End;
  End;

Procedure reduceRestoreWindow( _1_e_window: int64);
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/reduce-restore-window
    _o_entry := windowEntryByRef( _1_e_window);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Begin
      If ( _o_entry.o_form.WindowState = Forms.wsMinimized) Then Begin
        _o_entry.o_form.WindowState := Forms.wsNormal;
        _o_entry.b_hidden := False;
      End Else
        _o_entry.o_form.WindowState := Forms.wsMinimized;
      touchWindowEntry( _o_entry);
    End;
  End;

Procedure resizeFormWindow( _1_e_width: int64; _2_e_height: int64);
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/resize-form-window
    _o_entry := windowEntryByRef( ge_currentFormWindowRef);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Begin
      _o_entry.o_form.Width := _o_entry.o_form.Width + _1_e_width;
      _o_entry.o_form.Height := _o_entry.o_form.Height + _2_e_height;
    End;
  End;

Procedure setWindowDocumentIcon( _1_e_winRef: int64);
  Begin
    //https://developer.4d.com/docs/21/commands/set-window-document-icon
    If ( _1_e_winRef <> 0) Then // TODO: non implémenté dans cette première version.
    ;
  End;

Procedure setWindowDocumentIcon( _1_e_winRef: int64; Const _2_y_image: TBytes);
  Begin
    //https://developer.4d.com/docs/21/commands/set-window-document-icon
    If ( _1_e_winRef <> 0) Then;
    If ( System.Length( _2_y_image) >= 0) Then // TODO: non implémenté dans cette première version.
    ;
  End;

Procedure setWindowDocumentIcon( _1_e_winRef: int64; Const _2_t_file: string);
  Begin
    //https://developer.4d.com/docs/21/commands/set-window-document-icon
    If ( _1_e_winRef <> 0) Then;
    If ( _2_t_file <> '') Then // TODO: non implémenté dans cette première version.
    ;
  End;

Procedure setWindowDocumentIcon( _1_e_winRef: int64; Const _2_y_image: TBytes; Const _3_t_file: string);
  Begin
    //https://developer.4d.com/docs/21/commands/set-window-document-icon
    If ( _1_e_winRef <> 0) Then;
    If ( System.Length( _2_y_image) >= 0) Then;
    If ( _3_t_file <> '') Then // TODO: non implémenté dans cette première version.
    ;
  End;

Procedure setWindowRect( _1_e_left: int64; _2_e_top: int64; _3_e_right: int64; _4_e_bottom: int64; _5_e_window: int64 = 0; Const _6_t_star: string = '');
  Var
    _o_entry:  TQ4WindowEntry;
    _e_width:  int64;
    _e_height: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/set-window-rect
    _o_entry := resolveWindowEntry( _5_e_window);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Begin
      _e_width := _3_e_right - _1_e_left;
      _e_height := _4_e_bottom - _2_e_top;
      If ( _e_width < 1) Then _e_width := _o_entry.o_form.Width;
      If ( _e_height < 1) Then _e_height := _o_entry.o_form.Height;
      _o_entry.o_form.SetBounds( _1_e_left, _2_e_top, _e_width, _e_height);
      If ( _6_t_star <> '*') Then Begin
        _o_entry.o_form.BringToFront;
        touchWindowEntry( _o_entry);
      End;
    End;
  End;

Procedure setWindowTitle( Const _1_t_title: string; _2_e_window: int64 = 0);
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/set-window-title
    _o_entry := resolveWindowEntry( _2_e_window);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then _o_entry.o_form.Caption := clipWindowTitle( _1_t_title);
  End;

Procedure showToolBar;
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/show-tool-bar
    _o_entry := windowEntryByRef( ge_toolBarWindowRef);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Begin
      _o_entry.o_form.Show;
      _o_entry.b_hidden := False;
      touchWindowEntry( _o_entry);
    End;
  End;

Procedure showWindow( _1_e_window: int64 = 0);
  Var
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/show-window
    _o_entry := resolveWindowEntry( _1_e_window);
    If ( ( _o_entry <> nil) and ( _o_entry.o_form <> nil)) Then Begin
      _o_entry.o_form.Show;
      _o_entry.b_hidden := False;
      touchWindowEntry( _o_entry);
    End;
  End;

Procedure windowList( out _1_te_windows: Tq4Int64Array; Const _2_t_star: string = '');
  Var
    _e_index: int64;
    _e_count: int64;
    _o_entry: TQ4WindowEntry;
  Begin
    //https://developer.4d.com/docs/21/commands/window-list
    System.SetLength( _1_te_windows, 0);
    If ( go_windows = nil) Then Exit;

    _e_count := 0;
    For _e_index := 0 To go_windows.Count - 1 Do Begin
      _o_entry := TQ4WindowEntry( go_windows[_e_index]);
      If ( _o_entry.b_hidden) Then Continue;
      If ( ( _2_t_star <> '*') and ( _o_entry.e_windowKind = FLOATING_WINDOW)) Then Continue;
      _e_count := _e_count + 1;
    End;

    System.SetLength( _1_te_windows, _e_count);
    _e_count := 0;
    For _e_index := 0 To go_windows.Count - 1 Do Begin
      _o_entry := TQ4WindowEntry( go_windows[_e_index]);
      If ( _o_entry.b_hidden) Then Continue;
      If ( ( _2_t_star <> '*') and ( _o_entry.e_windowKind = FLOATING_WINDOW)) Then Continue;
      _1_te_windows[_e_count] := _o_entry.e_windowRef;
      _e_count := _e_count + 1;
    End;
  End;

Finalization
  If ( go_windows <> nil) Then Begin
    go_windows.Free;
    go_windows := nil;
  End;

End.
