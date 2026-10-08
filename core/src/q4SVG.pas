Unit q4svg;

{$mode objfpc}{$H+}

{
q4SVG
version du 2026/04/18-17:58

Mapping 4D → q4SVG -> statut
Command Number 4D,    4D Command,                      q4 API,                           Statut
------------------------------------------------------------------------------------------------
1017,                SVG EXPORT TO PICTURE,            exportToPicture,                  OK,
1054,                SVG Find element ID by coordinates, findElementIDByCoordinates,    Partial,
1109,                SVG Find element IDs by rect,     findElementIDsByRect,             Partial,
1056,                SVG GET ATTRIBUTE,                getAttribute,                     OK,
1055,                SVG SET ATTRIBUTE,                setAttribute,                     OK,
1108,                SVG SHOW ELEMENT,                 showElement,                      Partial,

Doc: https://developer.4d.com/docs/21/commands/theme/SVG

Notes q4 v1:
- Implémentation centrée sur le SVG source contenu dans TBytes.
- Sans runtime UI, les surcharges « object name » existent mais retournent OK=0.
- Les commandes géométriques utilisent une approximation cohérente par bounding boxes.
- Les transformations SVG complexes ne sont pas entièrement supportées en v1.
}

Interface

Uses
  Classes,
  SysUtils,
  Math,
  DOM,
  XMLRead,
  XMLWrite,
  q4coreLanguage;

Const
  GET_XML_DATA_SOURCE = 0;
  COPY_XML_DATA_SOURCE = 1;
  OWN_XML_DATA_SOURCE = 2;

  ERROR_NONE = 0;
  ERROR_INVALID_SVG = 1;
  ERROR_OBJECT_CONTEXT_UNSUPPORTED = 2;
  ERROR_ELEMENT_NOT_FOUND = 3;

Type
  TTq4SVGStringArray = Array Of string;

  Tq4SVGAttributePair = Record
    t_name: string;
    t_value: string;
  End;

  TTq4SVGAttributePairs = Array Of Tq4SVGAttributePair;
  TTq4SVGTextArray = Array Of string;

Function makeAttributePair( Const _1_t_name: string; Const _2_t_value: string): Tq4SVGAttributePair;

Procedure exportToPicture( Const _1_t_elementRef: string; out _2_by_pictVar: TBytes; Const _3_e_exportType: int64 = COPY_XML_DATA_SOURCE);

Function findElementIDByCoordinates( Const _1_by_pictureObject: TBytes; Const _2_e_x: int64; Const _3_e_y: int64): string; overload;
Function findElementIDByCoordinates( Const _1_t_star: string; Const _2_t_pictureObject: string; Const _3_e_x: int64; Const _4_e_y: int64): string; overload;

Function findElementIDsByRect( Const _1_by_pictureObject: TBytes; Const _2_e_x: int64; Const _3_e_y: int64; Const _4_e_width: int64; Const _5_e_height: int64;
  out _6_tt_arrIDs: TTq4SVGTextArray): boolean; overload;
Function findElementIDsByRect( Const _1_t_star: string; Const _2_t_pictureObject: string; Const _3_e_x: int64; Const _4_e_y: int64; Const _5_e_width: int64;
  Const _6_e_height: int64; out _7_tt_arrIDs: TTq4SVGTextArray): boolean; overload;

Function getAttribute( Const _1_by_pictureObject: TBytes; Const _2_t_elementID: string; Const _3_t_attribName: string): string; overload;
Function getAttribute( Const _1_t_star: string; Const _2_t_pictureObject: string; Const _3_t_elementID: string; Const _4_t_attribName: string): string; overload;

Procedure setAttribute( Var _1_by_pictureObject: TBytes; Const _2_t_elementID: string; Const _3_ty_attributes: TTq4SVGAttributePairs; Const _4_t_modifyPictureItself: string = ''); overload;
Procedure setAttribute( Const _1_t_star: string; Const _2_t_pictureObject: string; Const _3_t_elementID: string; Const _4_ty_attributes: TTq4SVGAttributePairs;
  Const _5_t_modifyPictureItself: string = ''); overload;

Procedure showElement( Var _1_by_pictureObject: TBytes; Const _2_t_id: string; Const _3_e_margin: int64 = 4); overload;
Procedure showElement( Const _1_t_star: string; Const _2_t_pictureObject: string; Const _3_t_id: string; Const _4_e_margin: int64 = 4); overload;

Implementation

Type
  Tq4SVGBox = Record
    b_valid: boolean;
    r_left: double;
    r_top: double;
    r_right: double;
    r_bottom: double;
  End;

  Tq4SVGRenderItem = Record
    t_id: string;
    t_tagName: string;
    y_box: Tq4SVGBox;
    o_element: TDOMElement;
  End;

  TTq4SVGRenderItems = Array Of Tq4SVGRenderItem;

Function newBox( Const _1_r_left: double; Const _2_r_top: double; Const _3_r_right: double; Const _4_r_bottom: double): Tq4SVGBox;
  Begin
    Result.b_valid := True;
    Result.r_left := Math.Min( _1_r_left, _3_r_right);
    Result.r_top := Math.Min( _2_r_top, _4_r_bottom);
    Result.r_right := Math.Max( _1_r_left, _3_r_right);
    Result.r_bottom := Math.Max( _2_r_top, _4_r_bottom);
  End;

Function invalidBox: Tq4SVGBox;
  Begin
    Result.b_valid := False;
    Result.r_left := 0;
    Result.r_top := 0;
    Result.r_right := 0;
    Result.r_bottom := 0;
  End;

Function unionBoxes( Const _1_y_first: Tq4SVGBox; Const _2_y_second: Tq4SVGBox): Tq4SVGBox;
  Begin
    If ( not _1_y_first.b_valid) Then Exit( _2_y_second);
    If ( not _2_y_second.b_valid) Then Exit( _1_y_first);

    Result.b_valid := True;
    Result.r_left := Math.Min( _1_y_first.r_left, _2_y_second.r_left);
    Result.r_top := Math.Min( _1_y_first.r_top, _2_y_second.r_top);
    Result.r_right := Math.Max( _1_y_first.r_right, _2_y_second.r_right);
    Result.r_bottom := Math.Max( _1_y_first.r_bottom, _2_y_second.r_bottom);
  End;

Function boxIntersects( Const _1_y_first: Tq4SVGBox; Const _2_y_second: Tq4SVGBox): boolean;
  Begin
    Result := _1_y_first.b_valid and _2_y_second.b_valid and ( _1_y_first.r_left <= _2_y_second.r_right) and ( _1_y_first.r_right >=
      _2_y_second.r_left) and ( _1_y_first.r_top <= _2_y_second.r_bottom) and ( _1_y_first.r_bottom >= _2_y_second.r_top);
  End;

Function boxContainsPoint( Const _1_y_box: Tq4SVGBox; Const _2_r_x: double; Const _3_r_y: double): boolean;
  Begin
    Result := _1_y_box.b_valid and ( _2_r_x >= _1_y_box.r_left) and ( _2_r_x <= _1_y_box.r_right) and ( _3_r_y >= _1_y_box.r_top) and ( _3_r_y <= _1_y_box.r_bottom);
  End;

Function bytesToString( Const _1_by_data: TBytes): string;
  Var
    _e_length: SizeInt;
  Begin
    _e_length := System.Length( _1_by_data);
    System.SetLength( Result, _e_length);
    If ( _e_length > 0) Then System.Move( _1_by_data[0], Result[1], _e_length);
  End;

Function stringToBytes( Const _1_t_value: string): TBytes;
  Var
    _e_length: SizeInt;
  Begin
    _e_length := System.Length( _1_t_value);
    System.SetLength( Result, _e_length);
    If ( _e_length > 0) Then System.Move( _1_t_value[1], Result[0], _e_length);
  End;

Function makeAttributePair( Const _1_t_name: string; Const _2_t_value: string): Tq4SVGAttributePair;
  Begin
    Result.t_name := _1_t_name;
    Result.t_value := _2_t_value;
  End;

Function newFormatSettings: TFormatSettings;
  Begin
    Result := SysUtils.DefaultFormatSettings;
    Result.DecimalSeparator := '.';
  End;

Function trimUnitNumber( Const _1_t_value: string): string;
  Var
    _e_index:   int64;
    _t_trimmed: string;
    _c_char:    char;
  Begin
    _t_trimmed := SysUtils.Trim( _1_t_value);
    Result := '';
    For _e_index := 1 To System.Length( _t_trimmed) Do Begin
      _c_char := _t_trimmed[_e_index];
      If ( _c_char in ['0'..'9', '-', '+', '.', 'e', 'E']) Then Result := Result + _c_char
      Else If ( Result <> '') Then Break;
    End;
  End;

Function parseSVGNumber( Const _1_t_value: string; Const _2_r_default: double = 0): double;
  Var
    _t_number: string;
    _y_formatSettings: TFormatSettings;
  Begin
    _t_number := trimUnitNumber( _1_t_value);
    _y_formatSettings := newFormatSettings;
    If ( ( _t_number = '') or ( not SysUtils.TryStrToFloat( _t_number, Result, _y_formatSettings))) Then Result := _2_r_default;
  End;

Function splitWhitespaceNumbers( Const _1_t_value: string): TTq4SVGStringArray;
  Var
    _e_index:   int64;
    _t_current: string;
    _c_char:    char;

  Procedure flushCurrentToken;
    Var
      _e_length: int64;
    Begin
      If ( _t_current = '') Then Exit;
      _e_length := System.Length( Result);
      System.SetLength( Result, _e_length + 1);
      Result[_e_length] := _t_current;
      _t_current := '';
    End;

  Begin
    Result := nil;
    _t_current := '';
    For _e_index := 1 To System.Length( _1_t_value) Do Begin
      _c_char := _1_t_value[_e_index];
      If ( _c_char in [' ', ',', #9, #10, #13]) Then flushCurrentToken
      Else
        _t_current := _t_current + _c_char;
    End;
    flushCurrentToken;
  End;

Function tryLoadDocumentFromString( Const _1_t_xml: string; out _2_o_document: TXMLDocument): boolean;
  Var
    _o_stream: TStringStream;
  Begin
    Result := False;
    _2_o_document := nil;
    _o_stream := TStringStream.Create( _1_t_xml);
    Try
      Try
        XMLRead.ReadXMLFile( _2_o_document, _o_stream);
        Result := Assigned( _2_o_document) and Assigned( _2_o_document.DocumentElement);
      Except
        on E: Exception Do Begin
          _2_o_document := nil;
          Result := False;
        End;
      End;
    Finally
      _o_stream.Free;
    End;
  End;

Function tryLoadDocumentFromBytes( Const _1_by_data: TBytes; out _2_o_document: TXMLDocument): boolean;
  Begin
    Result := tryLoadDocumentFromString( bytesToString( _1_by_data), _2_o_document);
  End;

Function saveDocumentToBytes( _1_o_document: TXMLDocument): TBytes;
  Var
    _o_stream: TStringStream;
  Begin
    _o_stream := TStringStream.Create( '');
    Try
      XMLWrite.WriteXMLFile( _1_o_document, _o_stream);
      Result := stringToBytes( _o_stream.DataString);
    Finally
      _o_stream.Free;
    End;
  End;

Function getTagName( _1_o_element: TDOMElement): string;
  Begin
    Result := SysUtils.LowerCase( _1_o_element.TagName);
  End;

Function getAttributeValue( _1_o_element: TDOMElement; Const _2_t_name: string): string;
  Begin
    Result := _1_o_element.GetAttribute( _2_t_name);
  End;

Function getNodeID( _1_o_element: TDOMElement): string;
  Begin
    Result := getAttributeValue( _1_o_element, 'id');
    If ( Result = '') Then Result := getAttributeValue( _1_o_element, 'xml:id');
  End;

Function hasAttribute( _1_o_element: TDOMElement; Const _2_t_name: string): boolean;
  Begin
    Result := _1_o_element.HasAttribute( _2_t_name);
  End;

Function isElementVisible( _1_o_element: TDOMElement): boolean;
  Var
    _t_display:    string;
    _t_visibility: string;
  Begin
    _t_display := SysUtils.LowerCase( getAttributeValue( _1_o_element, 'display'));
    _t_visibility := SysUtils.LowerCase( getAttributeValue( _1_o_element, 'visibility'));
    Result := ( _t_display <> 'none') and ( _t_visibility <> 'hidden') and ( _t_visibility <> 'collapse');
  End;

Function getTextContent( _1_o_node: TDOMNode): string;
  Var
    _o_child: TDOMNode;
  Begin
    Result := '';
    _o_child := _1_o_node.FirstChild;
    While ( Assigned( _o_child)) Do Begin
      If ( _o_child is TDOMText) Then Result := Result + _o_child.NodeValue
      Else
        Result := Result + getTextContent( _o_child);
      _o_child := _o_child.NextSibling;
    End;
  End;

Procedure appendRenderItem( Var _1_ty_items: TTq4SVGRenderItems; Const _2_y_item: Tq4SVGRenderItem);
  Var
    _e_length: int64;
  Begin
    _e_length := System.Length( _1_ty_items);
    System.SetLength( _1_ty_items, _e_length + 1);
    _1_ty_items[_e_length] := _2_y_item;
  End;

Function getDoubleAttribute( _1_o_element: TDOMElement; Const _2_t_name: string; Const _3_r_default: double = 0): double;
  Begin
    Result := parseSVGNumber( getAttributeValue( _1_o_element, _2_t_name), _3_r_default);
  End;

Function tryGetRootMetrics( _1_o_root: TDOMElement; out _2_r_width: double; out _3_r_height: double; out _4_r_viewBoxX: double; out _5_r_viewBoxY: double;
  out _6_r_viewBoxWidth: double; out _7_r_viewBoxHeight: double): boolean;
  Var
    ta_parts:   TTq4SVGStringArray;
    _t_viewBox: string;
  Begin
    _2_r_width := getDoubleAttribute( _1_o_root, 'width', 0);
    _3_r_height := getDoubleAttribute( _1_o_root, 'height', 0);
    _t_viewBox := getAttributeValue( _1_o_root, 'viewBox');

    If ( _t_viewBox <> '') Then Begin
      ta_parts := splitWhitespaceNumbers( _t_viewBox);
      If ( System.Length( ta_parts) >= 4) Then Begin
        _4_r_viewBoxX := parseSVGNumber( ta_parts[0], 0);
        _5_r_viewBoxY := parseSVGNumber( ta_parts[1], 0);
        _6_r_viewBoxWidth := parseSVGNumber( ta_parts[2], 0);
        _7_r_viewBoxHeight := parseSVGNumber( ta_parts[3], 0);
        If ( _2_r_width <= 0) Then _2_r_width := _6_r_viewBoxWidth;
        If ( _3_r_height <= 0) Then _3_r_height := _7_r_viewBoxHeight;
        Result := ( _2_r_width > 0) and ( _3_r_height > 0) and ( _6_r_viewBoxWidth > 0) and ( _7_r_viewBoxHeight > 0);
        Exit;
      End;
    End;

    If ( ( _2_r_width > 0) and ( _3_r_height > 0)) Then Begin
      _4_r_viewBoxX := 0;
      _5_r_viewBoxY := 0;
      _6_r_viewBoxWidth := _2_r_width;
      _7_r_viewBoxHeight := _3_r_height;
      Result := True;
      Exit;
    End;

    Result := False;
  End;

Procedure accumulateSimpleTranslation( _1_o_element: TDOMElement; out _2_r_translateX: double; out _3_r_translateY: double);
  Var
    _o_current:    TDOMNode;
    _o_domElement: TDOMElement;
    _t_transform:  string;
    _e_openPos:    SizeInt;
    _e_closePos:   SizeInt;
    _t_inside:     string;
    ta_parts:      TTq4SVGStringArray;
  Begin
    _2_r_translateX := 0;
    _3_r_translateY := 0;
    _o_current := _1_o_element;

    While ( Assigned( _o_current)) Do Begin
      If ( _o_current is TDOMElement) Then Begin
        _o_domElement := TDOMElement( _o_current);
        _t_transform := getAttributeValue( _o_domElement, 'transform');
        _e_openPos := Pos( 'translate(', _t_transform);
        If ( _e_openPos > 0) Then Begin
          _e_closePos := Pos( ')', _t_transform);
          If ( _e_closePos > _e_openPos) Then Begin
            _t_inside := System.Copy( _t_transform, _e_openPos + System.Length( 'translate('), _e_closePos - ( _e_openPos + System.Length( 'translate(')));
            ta_parts := splitWhitespaceNumbers( _t_inside);
            If ( System.Length( ta_parts) >= 1) Then _2_r_translateX := _2_r_translateX + parseSVGNumber( ta_parts[0], 0);
            If ( System.Length( ta_parts) >= 2) Then _3_r_translateY := _3_r_translateY + parseSVGNumber( ta_parts[1], 0);
          End;
        End;
      End;
      _o_current := _o_current.ParentNode;
    End;
  End;

Function translatedBox( Const _1_y_box: Tq4SVGBox; Const _2_r_translateX: double; Const _3_r_translateY: double): Tq4SVGBox;
  Begin
    If ( not _1_y_box.b_valid) Then Exit( _1_y_box);
    Result := newBox( _1_y_box.r_left + _2_r_translateX, _1_y_box.r_top + _3_r_translateY, _1_y_box.r_right + _2_r_translateX, _1_y_box.r_bottom + _3_r_translateY);
  End;

Function parsePointPairs( Const _1_t_value: string): Tq4SVGBox;
  Var
    ta_parts: TTq4SVGStringArray;
    _e_index: int64;
    _r_x:     double;
    _r_y:     double;
    _y_box:   Tq4SVGBox;
  Begin
    _y_box := invalidBox;
    ta_parts := splitWhitespaceNumbers( _1_t_value);
    _e_index := 0;
    While ( _e_index + 1 < System.Length( ta_parts)) Do Begin
      _r_x := parseSVGNumber( ta_parts[_e_index], 0);
      _r_y := parseSVGNumber( ta_parts[_e_index + 1], 0);
      If ( not _y_box.b_valid) Then _y_box := newBox( _r_x, _r_y, _r_x, _r_y)
      Else
        _y_box := unionBoxes( _y_box, newBox( _r_x, _r_y, _r_x, _r_y));
      Inc( _e_index, 2);
    End;
    Result := _y_box;
  End;

Function parsePathBoundingBox( Const _1_t_d: string): Tq4SVGBox;
  Var
    _t_numbersOnly: string;
    _e_index: int64;
    _c_char:  char;
    ta_parts: TTq4SVGStringArray;
    _r_x:     double;
    _r_y:     double;
    _y_box:   Tq4SVGBox;
  Begin
    _t_numbersOnly := '';
    For _e_index := 1 To System.Length( _1_t_d) Do Begin
      _c_char := _1_t_d[_e_index];
      If ( _c_char in ['0'..'9', '-', '+', '.', 'e', 'E', ',', ' ', #9, #10, #13]) Then _t_numbersOnly := _t_numbersOnly + _c_char
      Else
        _t_numbersOnly := _t_numbersOnly + ' ';
    End;

    ta_parts := splitWhitespaceNumbers( _t_numbersOnly);
    _y_box := invalidBox;
    _e_index := 0;
    While ( _e_index + 1 < System.Length( ta_parts)) Do Begin
      _r_x := parseSVGNumber( ta_parts[_e_index], 0);
      _r_y := parseSVGNumber( ta_parts[_e_index + 1], 0);
      If ( not _y_box.b_valid) Then _y_box := newBox( _r_x, _r_y, _r_x, _r_y)
      Else
        _y_box := unionBoxes( _y_box, newBox( _r_x, _r_y, _r_x, _r_y));
      Inc( _e_index, 2);
    End;
    Result := _y_box;
  End;

Function computeElementBox( _1_o_element: TDOMElement): Tq4SVGBox;
  Var
    _t_tagName: string;
    _r_x:      double;
    _r_y:      double;
    _r_width:  double;
    _r_height: double;
    _r_cx:     double;
    _r_cy:     double;
    _r_rx:     double;
    _r_ry:     double;
    _r_fontSize: double;
    _t_text:   string;
    _y_box:    Tq4SVGBox;
    _o_child:  TDOMNode;
    _r_translateX: double;
    _r_translateY: double;
  Begin
    _t_tagName := getTagName( _1_o_element);
    Result := invalidBox;

    If ( not isElementVisible( _1_o_element)) Then Exit;

    If ( _t_tagName = 'rect') Then Begin
      _r_x := getDoubleAttribute( _1_o_element, 'x', 0);
      _r_y := getDoubleAttribute( _1_o_element, 'y', 0);
      _r_width := getDoubleAttribute( _1_o_element, 'width', 0);
      _r_height := getDoubleAttribute( _1_o_element, 'height', 0);
      Result := newBox( _r_x, _r_y, _r_x + _r_width, _r_y + _r_height);
    End Else If ( _t_tagName = 'image') Then Begin
      _r_x := getDoubleAttribute( _1_o_element, 'x', 0);
      _r_y := getDoubleAttribute( _1_o_element, 'y', 0);
      _r_width := getDoubleAttribute( _1_o_element, 'width', 0);
      _r_height := getDoubleAttribute( _1_o_element, 'height', 0);
      Result := newBox( _r_x, _r_y, _r_x + _r_width, _r_y + _r_height);
    End Else If ( _t_tagName = 'circle') Then Begin
      _r_cx := getDoubleAttribute( _1_o_element, 'cx', 0);
      _r_cy := getDoubleAttribute( _1_o_element, 'cy', 0);
      _r_rx := getDoubleAttribute( _1_o_element, 'r', 0);
      Result := newBox( _r_cx - _r_rx, _r_cy - _r_rx, _r_cx + _r_rx, _r_cy + _r_rx);
    End Else If ( _t_tagName = 'ellipse') Then Begin
      _r_cx := getDoubleAttribute( _1_o_element, 'cx', 0);
      _r_cy := getDoubleAttribute( _1_o_element, 'cy', 0);
      _r_rx := getDoubleAttribute( _1_o_element, 'rx', 0);
      _r_ry := getDoubleAttribute( _1_o_element, 'ry', 0);
      Result := newBox( _r_cx - _r_rx, _r_cy - _r_ry, _r_cx + _r_rx, _r_cy + _r_ry);
    End Else If ( _t_tagName = 'line') Then Result := newBox( getDoubleAttribute( _1_o_element, 'x1', 0), getDoubleAttribute( _1_o_element, 'y1', 0),
        getDoubleAttribute( _1_o_element, 'x2', 0), getDoubleAttribute( _1_o_element, 'y2', 0))
    Else If ( ( _t_tagName = 'polyline') or ( _t_tagName = 'polygon')) Then Result := parsePointPairs( getAttributeValue( _1_o_element, 'points'))
    Else If ( _t_tagName = 'path') Then Result := parsePathBoundingBox( getAttributeValue( _1_o_element, 'd'))
    Else If ( ( _t_tagName = 'text') or ( _t_tagName = 'tspan') or ( _t_tagName = 'textarea')) Then Begin
      _r_x := getDoubleAttribute( _1_o_element, 'x', 0);
      _r_y := getDoubleAttribute( _1_o_element, 'y', 0);
      _r_fontSize := getDoubleAttribute( _1_o_element, 'font-size', 16);
      _t_text := getTextContent( _1_o_element);
      If ( hasAttribute( _1_o_element, '4D-text')) Then _t_text := getAttributeValue( _1_o_element, '4D-text');
      _r_width := System.Length( _t_text) * _r_fontSize * 0.6;
      _r_height := _r_fontSize;
      Result := newBox( _r_x, _r_y - _r_height, _r_x + _r_width, _r_y);
    End Else If ( _t_tagName = 'use') Then Begin
      _r_x := getDoubleAttribute( _1_o_element, 'x', 0);
      _r_y := getDoubleAttribute( _1_o_element, 'y', 0);
      _r_width := getDoubleAttribute( _1_o_element, 'width', 0);
      _r_height := getDoubleAttribute( _1_o_element, 'height', 0);
      If ( ( _r_width > 0) and ( _r_height > 0)) Then Result := newBox( _r_x, _r_y, _r_x + _r_width, _r_y + _r_height)
      Else
        Result := newBox( _r_x, _r_y, _r_x, _r_y);
    End Else If ( ( _t_tagName = 'g') or ( _t_tagName = 'svg')) Then Begin
      _y_box := invalidBox;
      _o_child := _1_o_element.FirstChild;
      While ( Assigned( _o_child)) Do Begin
        If ( _o_child is TDOMElement) Then _y_box := unionBoxes( _y_box, computeElementBox( TDOMElement( _o_child)));
        _o_child := _o_child.NextSibling;
      End;
      Result := _y_box;
    End;

    accumulateSimpleTranslation( _1_o_element, _r_translateX, _r_translateY);
    Result := translatedBox( Result, _r_translateX, _r_translateY);
  End;

Procedure collectRenderItems( _1_o_element: TDOMElement; Var _2_ty_items: TTq4SVGRenderItems);
  Var
    _o_child: TDOMNode;
    _y_item:  Tq4SVGRenderItem;
  Begin
    _y_item.t_id := getNodeID( _1_o_element);
    _y_item.t_tagName := getTagName( _1_o_element);
    _y_item.y_box := computeElementBox( _1_o_element);
    _y_item.o_element := _1_o_element;

    If ( ( _y_item.t_id <> '') and _y_item.y_box.b_valid) Then appendRenderItem( _2_ty_items, _y_item);

    _o_child := _1_o_element.FirstChild;
    While ( Assigned( _o_child)) Do Begin
      If ( _o_child is TDOMElement) Then collectRenderItems( TDOMElement( _o_child), _2_ty_items);
      _o_child := _o_child.NextSibling;
    End;
  End;

Function isClassMatch( _1_o_element: TDOMElement; Const _2_t_query: string): boolean;
  Var
    ta_needed:  TTq4SVGStringArray;
    ta_current: TTq4SVGStringArray;
    _t_classes: string;
    _e_neededIndex: int64;
    _e_currentIndex: int64;
    _b_found:   boolean;
    _t_needed:  string;
    _o_current: TDOMNode;
  Begin
    ta_needed := splitWhitespaceNumbers( SysUtils.StringReplace( _2_t_query, ',', ' ', [rfReplaceAll]));
    If ( System.Length( ta_needed) = 0) Then Exit( False);

    _t_classes := '';
    _o_current := _1_o_element;
    While ( Assigned( _o_current)) Do Begin
      If ( _o_current is TDOMElement) Then _t_classes := _t_classes + ' ' + getAttributeValue( TDOMElement( _o_current), 'class');
      _o_current := _o_current.ParentNode;
    End;

    ta_current := splitWhitespaceNumbers( _t_classes);

    Result := True;
    For _e_neededIndex := 0 To System.Length( ta_needed) - 1 Do Begin
      _t_needed := SysUtils.Trim( ta_needed[_e_neededIndex]);
      If ( _t_needed = '') Then Continue;
      _b_found := False;
      For _e_currentIndex := 0 To System.Length( ta_current) - 1 Do If ( ta_current[_e_currentIndex] = _t_needed) Then Begin
          _b_found := True;
          Break;
        End;
      If ( not _b_found) Then Begin
        Result := False;
        Exit;
      End;
    End;
  End;

Function findElementByID( _1_o_node: TDOMNode; Const _2_t_elementID: string): TDOMElement;
  Var
    _o_child: TDOMNode;
    _o_found: TDOMElement;
  Begin
    Result := nil;
    If ( _1_o_node is TDOMElement) Then If ( getNodeID( TDOMElement( _1_o_node)) = _2_t_elementID) Then Exit( TDOMElement( _1_o_node));

    _o_child := _1_o_node.FirstChild;
    While ( Assigned( _o_child)) Do Begin
      _o_found := findElementByID( _o_child, _2_t_elementID);
      If ( Assigned( _o_found)) Then Exit( _o_found);
      _o_child := _o_child.NextSibling;
    End;
  End;

Procedure bringToFront( _1_o_element: TDOMElement);
  Var
    _o_parent: TDOMNode;
  Begin
    _o_parent := _1_o_element.ParentNode;
    If ( Assigned( _o_parent)) Then Begin
      _o_parent.RemoveChild( _1_o_element);
      _o_parent.AppendChild( _1_o_element);
    End;
  End;

Function getAttributeFromElement( _1_o_element: TDOMElement; Const _2_t_attribName: string): string;
  Const
    PREFIX_IS_OF_CLASS = '4d-isofclass-';
  Var
    _t_lowerAttribName: string;
    _e_prefixLength:    int64;
  Begin
    _t_lowerAttribName := SysUtils.LowerCase( _2_t_attribName);
    If ( _t_lowerAttribName = '4d-text') Then Begin
      Result := getTextContent( _1_o_element);
      If ( Result = '') Then Result := getAttributeValue( _1_o_element, '4D-text');
    End Else If ( _t_lowerAttribName = '4d-enabled2d') Then Result := getAttributeValue( _1_o_element, '4D-enableD2D')
    Else If ( _t_lowerAttribName = '4d-bringtofront') Then Result := ''
    Else Begin
      _e_prefixLength := System.Length( PREFIX_IS_OF_CLASS);
      If ( Pos( PREFIX_IS_OF_CLASS, _t_lowerAttribName) = 1) Then Result :=
          SysUtils.LowerCase( SysUtils.BoolToStr( isClassMatch( _1_o_element, System.Copy( _2_t_attribName, _e_prefixLength + 1, MaxInt)), True))
      Else
        Result := getAttributeValue( _1_o_element, _2_t_attribName);
    End;
  End;

Procedure applyAttributeToElement( _1_o_element: TDOMElement; Const _2_t_name: string; Const _3_t_value: string);
  Var
    _t_lowerName: string;
    _o_textChild: TDOMNode;
  Begin
    _t_lowerName := SysUtils.LowerCase( _2_t_name);

    If ( _t_lowerName = '4d-text') Then Begin
      While ( Assigned( _1_o_element.FirstChild)) Do _1_o_element.RemoveChild( _1_o_element.FirstChild);
      _o_textChild := _1_o_element.OwnerDocument.CreateTextNode( _3_t_value);
      _1_o_element.AppendChild( _o_textChild);
      _1_o_element.SetAttribute( '4D-text', _3_t_value);
      Exit;
    End;

    If ( _t_lowerName = '4d-bringtofront') Then Begin
      If ( SysUtils.SameText( _3_t_value, 'true')) Then bringToFront( _1_o_element);
      Exit;
    End;

    If ( _t_lowerName = '4d-enabled2d') Then Begin
      _1_o_element.SetAttribute( '4D-enableD2D', _3_t_value);
      Exit;
    End;

    If ( SysUtils.SameText( _2_t_name, 'id') or SysUtils.SameText( _2_t_name, 'xml:id') or SysUtils.SameText( _2_t_name, 'class') or SysUtils.SameText( _2_t_name, 'xml:class') or
      SysUtils.SameText( _2_t_name, 'lang') or SysUtils.SameText( _2_t_name, 'xml:lang')) Then Exit;

    If ( ( getTagName( _1_o_element) = 'svg') and ( SysUtils.SameText( _2_t_name, 'width') or SysUtils.SameText( _2_t_name, 'height'))) Then Exit;

    If ( _1_o_element.HasAttribute( _2_t_name)) Then _1_o_element.SetAttribute( _2_t_name, _3_t_value);
  End;

Function distancePointToSegment( Const _1_r_px: double; Const _2_r_py: double; Const _3_r_x1: double; Const _4_r_y1: double; Const _5_r_x2: double; Const _6_r_y2: double): double;
  Var
    _r_dx:    double;
    _r_dy:    double;
    _r_t:     double;
    _r_projX: double;
    _r_projY: double;
  Begin
    _r_dx := _5_r_x2 - _3_r_x1;
    _r_dy := _6_r_y2 - _4_r_y1;
    If ( ( _r_dx = 0) and ( _r_dy = 0)) Then Exit( Math.Hypot( _1_r_px - _3_r_x1, _2_r_py - _4_r_y1));

    _r_t := ( ( _1_r_px - _3_r_x1) * _r_dx + ( _2_r_py - _4_r_y1) * _r_dy) / ( _r_dx * _r_dx + _r_dy * _r_dy);
    If ( _r_t < 0) Then _r_t := 0;
    If ( _r_t > 1) Then _r_t := 1;

    _r_projX := _3_r_x1 + _r_t * _r_dx;
    _r_projY := _4_r_y1 + _r_t * _r_dy;
    Result := Math.Hypot( _1_r_px - _r_projX, _2_r_py - _r_projY);
  End;

Function pointHitsElement( _1_o_element: TDOMElement; Const _2_r_x: double; Const _3_r_y: double): boolean;
  Var
    _t_tagName: string;
    _r_cx:      double;
    _r_cy:      double;
    _r_rx:      double;
    _r_ry:      double;
    _r_translateX: double;
    _r_translateY: double;
    _r_x1:      double;
    _r_y1:      double;
    _r_x2:      double;
    _r_y2:      double;
    _y_box:     Tq4SVGBox;
  Begin
    _t_tagName := getTagName( _1_o_element);
    accumulateSimpleTranslation( _1_o_element, _r_translateX, _r_translateY);

    If ( _t_tagName = 'circle') Then Begin
      _r_cx := getDoubleAttribute( _1_o_element, 'cx', 0) + _r_translateX;
      _r_cy := getDoubleAttribute( _1_o_element, 'cy', 0) + _r_translateY;
      _r_rx := getDoubleAttribute( _1_o_element, 'r', 0);
      Result := ( ( _2_r_x - _r_cx) * ( _2_r_x - _r_cx) + ( _3_r_y - _r_cy) * ( _3_r_y - _r_cy)) <= ( _r_rx * _r_rx);
      Exit;
    End;

    If ( _t_tagName = 'ellipse') Then Begin
      _r_cx := getDoubleAttribute( _1_o_element, 'cx', 0) + _r_translateX;
      _r_cy := getDoubleAttribute( _1_o_element, 'cy', 0) + _r_translateY;
      _r_rx := getDoubleAttribute( _1_o_element, 'rx', 0);
      _r_ry := getDoubleAttribute( _1_o_element, 'ry', 0);
      If ( ( _r_rx <= 0) or ( _r_ry <= 0)) Then Exit( False);
      Result := ( ( ( _2_r_x - _r_cx) * ( _2_r_x - _r_cx)) / ( _r_rx * _r_rx) + ( ( _3_r_y - _r_cy) * ( _3_r_y - _r_cy)) / ( _r_ry * _r_ry)) <= 1;
      Exit;
    End;

    If ( _t_tagName = 'line') Then Begin
      _r_x1 := getDoubleAttribute( _1_o_element, 'x1', 0) + _r_translateX;
      _r_y1 := getDoubleAttribute( _1_o_element, 'y1', 0) + _r_translateY;
      _r_x2 := getDoubleAttribute( _1_o_element, 'x2', 0) + _r_translateX;
      _r_y2 := getDoubleAttribute( _1_o_element, 'y2', 0) + _r_translateY;
      Result := distancePointToSegment( _2_r_x, _3_r_y, _r_x1, _r_y1, _r_x2, _r_y2) <= 2.0;
      Exit;
    End;

    _y_box := computeElementBox( _1_o_element);
    Result := boxContainsPoint( _y_box, _2_r_x, _3_r_y);
  End;

Function pixelToDocumentX( Const _1_e_x: int64; Const _2_r_width: double; Const _3_r_viewBoxX: double; Const _4_r_viewBoxWidth: double): double;
  Begin
    If ( _2_r_width <= 0) Then Exit( _1_e_x);
    Result := _3_r_viewBoxX + ( _1_e_x / _2_r_width) * _4_r_viewBoxWidth;
  End;

Function pixelToDocumentY( Const _1_e_y: int64; Const _2_r_height: double; Const _3_r_viewBoxY: double; Const _4_r_viewBoxHeight: double): double;
  Begin
    If ( _2_r_height <= 0) Then Exit( _1_e_y);
    Result := _3_r_viewBoxY + ( _1_e_y / _2_r_height) * _4_r_viewBoxHeight;
  End;

Function buildSelectionBox( Const _1_e_x: int64; Const _2_e_y: int64; Const _3_e_width: int64; Const _4_e_height: int64; Const _5_r_rootWidth: double;
  Const _6_r_rootHeight: double; Const _7_r_viewBoxX: double; Const _8_r_viewBoxY: double; Const _9_r_viewBoxWidth: double; Const _10_r_viewBoxHeight: double): Tq4SVGBox;
  Var
    _r_left:   double;
    _r_top:    double;
    _r_right:  double;
    _r_bottom: double;
  Begin
    _r_left := pixelToDocumentX( _1_e_x, _5_r_rootWidth, _7_r_viewBoxX, _9_r_viewBoxWidth);
    _r_top := pixelToDocumentY( _2_e_y, _6_r_rootHeight, _8_r_viewBoxY, _10_r_viewBoxHeight);
    _r_right := pixelToDocumentX( _1_e_x + _3_e_width, _5_r_rootWidth, _7_r_viewBoxX, _9_r_viewBoxWidth);
    _r_bottom := pixelToDocumentY( _2_e_y + _4_e_height, _6_r_rootHeight, _8_r_viewBoxY, _10_r_viewBoxHeight);
    Result := newBox( _r_left, _r_top, _r_right, _r_bottom);
  End;

Function findRootSVG( _1_o_document: TXMLDocument): TDOMElement;
  Begin
    If ( Assigned( _1_o_document) and Assigned( _1_o_document.DocumentElement) and ( getTagName( _1_o_document.DocumentElement) = 'svg')) Then Result := _1_o_document.DocumentElement
    Else
      Result := nil;
  End;

Procedure exportToPicture( Const _1_t_elementRef: string; out _2_by_pictVar: TBytes; Const _3_e_exportType: int64 = COPY_XML_DATA_SOURCE);
  Var
    _o_document: TXMLDocument;
  Begin
    //https://developer.4d.com/docs/21/commands/svg-export-to-picture
    OK := 0;
    Error := ERROR_NONE;
    _2_by_pictVar := nil;

    If ( not tryLoadDocumentFromString( _1_t_elementRef, _o_document)) Then Begin
      Error := ERROR_INVALID_SVG;
      Exit;
    End;

    Try
      If ( not Assigned( findRootSVG( _o_document))) Then Begin
        Error := ERROR_INVALID_SVG;
        Exit;
      End;

      Case _3_e_exportType Of
        GET_XML_DATA_SOURCE,
        COPY_XML_DATA_SOURCE,
        OWN_XML_DATA_SOURCE: _2_by_pictVar := stringToBytes( _1_t_elementRef);
        Else _2_by_pictVar := stringToBytes( _1_t_elementRef);
      End;

      OK := 1;
    Finally
      _o_document.Free;
    End;
  End;

Function findElementIDByCoordinates( Const _1_by_pictureObject: TBytes; Const _2_e_x: int64; Const _3_e_y: int64): string;
  Var
    _o_document:  TXMLDocument;
    _o_root:      TDOMElement;
    _ty_items:    TTq4SVGRenderItems;
    _e_index:     int64;
    _r_rootWidth: double;
    _r_rootHeight: double;
    _r_viewBoxX:  double;
    _r_viewBoxY:  double;
    _r_viewBoxWidth: double;
    _r_viewBoxHeight: double;
    _r_docX:      double;
    _r_docY:      double;
  Begin
    //https://developer.4d.com/docs/21/commands/svg-find-element-id-by-coordinates
    Result := '';
    OK := 0;
    Error := ERROR_NONE;

    If ( not tryLoadDocumentFromBytes( _1_by_pictureObject, _o_document)) Then Begin
      Error := ERROR_INVALID_SVG;
      Exit;
    End;

    Try
      _o_root := findRootSVG( _o_document);
      If ( not Assigned( _o_root)) Then Begin
        Error := ERROR_INVALID_SVG;
        Exit;
      End;

      If ( not tryGetRootMetrics( _o_root, _r_rootWidth, _r_rootHeight, _r_viewBoxX, _r_viewBoxY, _r_viewBoxWidth, _r_viewBoxHeight)) Then Begin
        Error := ERROR_INVALID_SVG;
        Exit;
      End;

      _ty_items := nil;
      collectRenderItems( _o_root, _ty_items);
      _r_docX := pixelToDocumentX( _2_e_x, _r_rootWidth, _r_viewBoxX, _r_viewBoxWidth);
      _r_docY := pixelToDocumentY( _3_e_y, _r_rootHeight, _r_viewBoxY, _r_viewBoxHeight);

      For _e_index := System.Length( _ty_items) - 1 Downto 0 Do If ( pointHitsElement( _ty_items[_e_index].o_element, _r_docX, _r_docY)) Then Begin
          Result := _ty_items[_e_index].t_id;
          Break;
        End;

      OK := 1;
    Finally
      _o_document.Free;
    End;
  End;

Function findElementIDByCoordinates( Const _1_t_star: string; Const _2_t_pictureObject: string; Const _3_e_x: int64; Const _4_e_y: int64): string;
  Begin
    //https://developer.4d.com/docs/21/commands/svg-find-element-id-by-coordinates
    Result := '';
    OK := 0;
    Error := ERROR_OBJECT_CONTEXT_UNSUPPORTED;
  End;

Function findElementIDsByRect( Const _1_by_pictureObject: TBytes; Const _2_e_x: int64; Const _3_e_y: int64; Const _4_e_width: int64; Const _5_e_height: int64;
  out _6_tt_arrIDs: TTq4SVGTextArray): boolean;
  Var
    _o_document:  TXMLDocument;
    _o_root:      TDOMElement;
    _ty_items:    TTq4SVGRenderItems;
    _e_index:     int64;
    _e_resultIndex: int64;
    _r_rootWidth: double;
    _r_rootHeight: double;
    _r_viewBoxX:  double;
    _r_viewBoxY:  double;
    _r_viewBoxWidth: double;
    _r_viewBoxHeight: double;
    _y_selection: Tq4SVGBox;
  Begin
    //https://developer.4d.com/docs/21/commands/svg-find-element-ids-by-rect
    Result := False;
    _6_tt_arrIDs := nil;
    OK := 0;
    Error := ERROR_NONE;

    If ( not tryLoadDocumentFromBytes( _1_by_pictureObject, _o_document)) Then Begin
      Error := ERROR_INVALID_SVG;
      Exit;
    End;

    Try
      _o_root := findRootSVG( _o_document);
      If ( not Assigned( _o_root)) Then Begin
        Error := ERROR_INVALID_SVG;
        Exit;
      End;

      If ( not tryGetRootMetrics( _o_root, _r_rootWidth, _r_rootHeight, _r_viewBoxX, _r_viewBoxY, _r_viewBoxWidth, _r_viewBoxHeight)) Then Begin
        Error := ERROR_INVALID_SVG;
        Exit;
      End;

      _y_selection := buildSelectionBox( _2_e_x, _3_e_y, _4_e_width, _5_e_height, _r_rootWidth, _r_rootHeight, _r_viewBoxX, _r_viewBoxY, _r_viewBoxWidth, _r_viewBoxHeight);
      _ty_items := nil;
      collectRenderItems( _o_root, _ty_items);

      _e_resultIndex := 0;
      For _e_index := 0 To System.Length( _ty_items) - 1 Do If ( boxIntersects( _ty_items[_e_index].y_box, _y_selection)) Then Begin
          System.SetLength( _6_tt_arrIDs, _e_resultIndex + 1);
          _6_tt_arrIDs[_e_resultIndex] := _ty_items[_e_index].t_id;
          Inc( _e_resultIndex);
        End;

      Result := System.Length( _6_tt_arrIDs) > 0;
      OK := 1;
    Finally
      _o_document.Free;
    End;
  End;

Function findElementIDsByRect( Const _1_t_star: string; Const _2_t_pictureObject: string; Const _3_e_x: int64; Const _4_e_y: int64; Const _5_e_width: int64;
  Const _6_e_height: int64; out _7_tt_arrIDs: TTq4SVGTextArray): boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/svg-find-element-ids-by-rect
    Result := False;
    _7_tt_arrIDs := nil;
    OK := 0;
    Error := ERROR_OBJECT_CONTEXT_UNSUPPORTED;
  End;

Function getAttribute( Const _1_by_pictureObject: TBytes; Const _2_t_elementID: string; Const _3_t_attribName: string): string;
  Var
    _o_document: TXMLDocument;
    _o_root:     TDOMElement;
    _o_element:  TDOMElement;
  Begin
    //https://developer.4d.com/docs/21/commands/svg-get-attribute
    Result := '';
    OK := 0;
    Error := ERROR_NONE;

    If ( not tryLoadDocumentFromBytes( _1_by_pictureObject, _o_document)) Then Begin
      Error := ERROR_INVALID_SVG;
      Exit;
    End;

    Try
      _o_root := findRootSVG( _o_document);
      If ( not Assigned( _o_root)) Then Begin
        Error := ERROR_INVALID_SVG;
        Exit;
      End;

      _o_element := findElementByID( _o_root, _2_t_elementID);
      If ( not Assigned( _o_element)) Then Begin
        Error := ERROR_ELEMENT_NOT_FOUND;
        Exit;
      End;

      Result := getAttributeFromElement( _o_element, _3_t_attribName);
      OK := 1;
    Finally
      _o_document.Free;
    End;
  End;

Function getAttribute( Const _1_t_star: string; Const _2_t_pictureObject: string; Const _3_t_elementID: string; Const _4_t_attribName: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/svg-get-attribute
    Result := '';
    OK := 0;
    Error := ERROR_OBJECT_CONTEXT_UNSUPPORTED;
  End;

Procedure setAttribute( Var _1_by_pictureObject: TBytes; Const _2_t_elementID: string; Const _3_ty_attributes: TTq4SVGAttributePairs; Const _4_t_modifyPictureItself: string = '');
  Var
    _o_document: TXMLDocument;
    _o_root:     TDOMElement;
    _o_element:  TDOMElement;
    _e_index:    int64;
  Begin
    //https://developer.4d.com/docs/21/commands/svg-set-attribute
    OK := 0;
    Error := ERROR_NONE;

    If ( not tryLoadDocumentFromBytes( _1_by_pictureObject, _o_document)) Then Begin
      Error := ERROR_INVALID_SVG;
      Exit;
    End;

    Try
      _o_root := findRootSVG( _o_document);
      If ( not Assigned( _o_root)) Then Begin
        Error := ERROR_INVALID_SVG;
        Exit;
      End;

      _o_element := findElementByID( _o_root, _2_t_elementID);
      If ( not Assigned( _o_element)) Then Begin
        Error := ERROR_ELEMENT_NOT_FOUND;
        Exit;
      End;

      For _e_index := 0 To System.Length( _3_ty_attributes) - 1 Do applyAttributeToElement( _o_element, _3_ty_attributes[_e_index].t_name, _3_ty_attributes[_e_index].t_value);

      _1_by_pictureObject := saveDocumentToBytes( _o_document);
      OK := 1;
    Finally
      _o_document.Free;
    End;
  End;

Procedure setAttribute( Const _1_t_star: string; Const _2_t_pictureObject: string; Const _3_t_elementID: string; Const _4_ty_attributes: TTq4SVGAttributePairs;
  Const _5_t_modifyPictureItself: string = '');
  Begin
    //https://developer.4d.com/docs/21/commands/svg-set-attribute
    OK := 0;
    Error := ERROR_OBJECT_CONTEXT_UNSUPPORTED;
  End;

Procedure showElement( Var _1_by_pictureObject: TBytes; Const _2_t_id: string; Const _3_e_margin: int64 = 4);
  Var
    _o_document: TXMLDocument;
    _o_root:     TDOMElement;
    _o_element:  TDOMElement;
    _y_box:      Tq4SVGBox;
    _r_width:    double;
    _r_height:   double;
    _r_viewBoxX: double;
    _r_viewBoxY: double;
    _r_viewBoxWidth: double;
    _r_viewBoxHeight: double;
    _y_formatSettings: TFormatSettings;
  Begin
    //https://developer.4d.com/docs/21/commands/svg-show-element
    OK := 0;
    Error := ERROR_NONE;

    If ( not tryLoadDocumentFromBytes( _1_by_pictureObject, _o_document)) Then Begin
      Error := ERROR_INVALID_SVG;
      Exit;
    End;

    Try
      _o_root := findRootSVG( _o_document);
      If ( not Assigned( _o_root)) Then Begin
        Error := ERROR_INVALID_SVG;
        Exit;
      End;

      _o_element := findElementByID( _o_root, _2_t_id);
      If ( not Assigned( _o_element)) Then Begin
        Error := ERROR_ELEMENT_NOT_FOUND;
        Exit;
      End;

      If ( not tryGetRootMetrics( _o_root, _r_width, _r_height, _r_viewBoxX, _r_viewBoxY, _r_viewBoxWidth, _r_viewBoxHeight)) Then Begin
        Error := ERROR_INVALID_SVG;
        Exit;
      End;

      _y_box := computeElementBox( _o_element);
      If ( not _y_box.b_valid) Then Begin
        Error := ERROR_ELEMENT_NOT_FOUND;
        Exit;
      End;

      _y_formatSettings := newFormatSettings;
      _o_root.SetAttribute( 'viewBox',
        SysUtils.FloatToStr( _y_box.r_left - _3_e_margin, _y_formatSettings) + ' ' + SysUtils.FloatToStr( _y_box.r_top - _3_e_margin, _y_formatSettings) +
        ' ' + SysUtils.FloatToStr( ( _y_box.r_right - _y_box.r_left) + ( 2 * _3_e_margin), _y_formatSettings) + ' ' + SysUtils.FloatToStr(
        ( _y_box.r_bottom - _y_box.r_top) + ( 2 * _3_e_margin), _y_formatSettings)
        );

      _1_by_pictureObject := saveDocumentToBytes( _o_document);
      OK := 1;
    Finally
      _o_document.Free;
    End;
  End;

Procedure showElement( Const _1_t_star: string; Const _2_t_pictureObject: string; Const _3_t_id: string; Const _4_e_margin: int64 = 4);
  Begin
    //https://developer.4d.com/docs/21/commands/svg-show-element
    OK := 0;
    Error := ERROR_OBJECT_CONTEXT_UNSUPPORTED;
  End;

Initialization
  OK := 1;
  Error := ERROR_NONE;

End.
