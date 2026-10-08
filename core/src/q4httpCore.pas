unit q4httpCore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, q4mimeCore;

const
  Q4_HTTP_METHOD_GET     = 'GET';
  Q4_HTTP_METHOD_POST    = 'POST';
  Q4_HTTP_METHOD_PUT     = 'PUT';
  Q4_HTTP_METHOD_PATCH   = 'PATCH';
  Q4_HTTP_METHOD_DELETE  = 'DELETE';
  Q4_HTTP_METHOD_HEAD    = 'HEAD';
  Q4_HTTP_METHOD_OPTIONS = 'OPTIONS';

type
  Tq4HttpMessageKind = (hmkUnknown, hmkRequest, hmkResponse);
  Tq4HttpBodyKind = (hbkNone, hbkRaw, hbkJSON, hbkXML, hbkFormUrlEncoded, hbkMultipart);

  Tq4HttpQueryParam = record
    t_name: string;
    t_value: string;
  end;
  Tq4HttpQueryParamArray = array of Tq4HttpQueryParam;

  Tq4HttpMessage = record
    e_kind: Tq4HttpMessageKind;
    t_startLine: string;
    t_method: string;
    t_target: string;
    t_path: string;
    t_queryString: string;
    t_version: string;
    e_statusCode: Int64;
    t_reasonPhrase: string;
    ty_headers: Tq4MimeHeaderArray;
    y_body: TBytes;
    t_bodyText: string;
    e_bodyKind: Tq4HttpBodyKind;
    ty_queryParams: Tq4HttpQueryParamArray;
  end;

function httpCoreNewMessage: Tq4HttpMessage;
function httpCoreNewQueryParam(const _1_t_name, _2_t_value: string): Tq4HttpQueryParam;
function httpCoreDetectMessageKind(const _1_t_startLine: string): Tq4HttpMessageKind;
function httpCoreParseRequestLine(const _1_t_startLine: string; var _2_y_message: Tq4HttpMessage): Boolean;
function httpCoreParseStatusLine(const _1_t_startLine: string; var _2_y_message: Tq4HttpMessage): Boolean;
function httpCoreSplitHeadersAndBody(const _1_t_rawMessage: string; out _2_t_headersText: string; out _3_t_bodyText: string): Boolean;
function httpCoreParseHeaders(const _1_t_headersText: string): Tq4MimeHeaderArray;
function httpCoreGetHeaderValue(const _1_ty_headers: Tq4MimeHeaderArray; const _2_t_name: string): string;
function httpCoreSetHeaderValue(var _1_ty_headers: Tq4MimeHeaderArray; const _2_t_name, _3_t_value: string): Boolean;
function httpCoreHeaderExists(const _1_ty_headers: Tq4MimeHeaderArray; const _2_t_name: string): Boolean;
function httpCoreDetectBodyKind(const _1_t_contentType: string): Tq4HttpBodyKind;
function httpCoreExtractBoundary(const _1_t_contentType: string): string;
function httpCoreParseQueryString(const _1_t_queryString: string): Tq4HttpQueryParamArray;
function httpCoreGetQueryParamValue(const _1_ty_params: Tq4HttpQueryParamArray; const _2_t_name: string): string;
function httpCoreSplitTarget(const _1_t_target: string; out _2_t_path: string; out _3_t_queryString: string): Boolean;

implementation

function httpCoreNewMessage: Tq4HttpMessage;
begin
  Result.e_kind := hmkUnknown;
  Result.t_startLine := '';
  Result.t_method := '';
  Result.t_target := '';
  Result.t_path := '';
  Result.t_queryString := '';
  Result.t_version := '';
  Result.e_statusCode := 0;
  Result.t_reasonPhrase := '';
  SetLength(Result.ty_headers, 0);
  SetLength(Result.y_body, 0);
  Result.t_bodyText := '';
  Result.e_bodyKind := hbkNone;
  SetLength(Result.ty_queryParams, 0);
end;

function httpCoreNewQueryParam(const _1_t_name, _2_t_value: string): Tq4HttpQueryParam;
begin
  Result.t_name := _1_t_name;
  Result.t_value := _2_t_value;
end;

function httpCoreDetectMessageKind(const _1_t_startLine: string): Tq4HttpMessageKind;
var t_trimmed: string;
begin
  t_trimmed := Trim(_1_t_startLine);
  if (t_trimmed = '') then Exit(hmkUnknown);
  if (AnsiStartsText('HTTP/', t_trimmed)) then Exit(hmkResponse);
  if (Pos(' ', t_trimmed) > 0) then Exit(hmkRequest);
  Result := hmkUnknown;
end;

function httpCoreParseRequestLine(const _1_t_startLine: string; var _2_y_message: Tq4HttpMessage): Boolean;
var e_p1,e_p2: Int64; t_method,t_target,t_version: string;
begin
  Result := False;
  e_p1 := Pos(' ', _1_t_startLine); if (e_p1<=0) then Exit;
  e_p2 := PosEx(' ', _1_t_startLine, e_p1+1); if (e_p2<=0) then Exit;
  t_method := Trim(Copy(_1_t_startLine,1,e_p1-1));
  t_target := Trim(Copy(_1_t_startLine,e_p1+1,e_p2-e_p1-1));
  t_version := Trim(Copy(_1_t_startLine,e_p2+1,MaxInt));
  if ((t_method='') or (t_target='') or (t_version='')) then Exit;
  _2_y_message.e_kind := hmkRequest;
  _2_y_message.t_startLine := _1_t_startLine;
  _2_y_message.t_method := t_method;
  _2_y_message.t_target := t_target;
  _2_y_message.t_version := t_version;
  httpCoreSplitTarget(t_target, _2_y_message.t_path, _2_y_message.t_queryString);
  _2_y_message.ty_queryParams := httpCoreParseQueryString(_2_y_message.t_queryString);
  Result := True;
end;

function httpCoreParseStatusLine(const _1_t_startLine: string; var _2_y_message: Tq4HttpMessage): Boolean;
var e_p1,e_p2: Int64; t_version,t_statusCode: string;
begin
  Result := False;
  e_p1 := Pos(' ', _1_t_startLine); if (e_p1<=0) then Exit;
  e_p2 := PosEx(' ', _1_t_startLine, e_p1+1);
  t_version := Trim(Copy(_1_t_startLine,1,e_p1-1));
  if (e_p2>0) then
  begin
    t_statusCode := Trim(Copy(_1_t_startLine,e_p1+1,e_p2-e_p1-1));
    _2_y_message.t_reasonPhrase := Trim(Copy(_1_t_startLine,e_p2+1,MaxInt));
  end else begin
    t_statusCode := Trim(Copy(_1_t_startLine,e_p1+1,MaxInt));
    _2_y_message.t_reasonPhrase := '';
  end;
  _2_y_message.e_kind := hmkResponse;
  _2_y_message.t_startLine := _1_t_startLine;
  _2_y_message.t_version := t_version;
  _2_y_message.e_statusCode := StrToIntDef(t_statusCode,0);
  Result := _2_y_message.e_statusCode>0;
end;

function httpCoreSplitHeadersAndBody(const _1_t_rawMessage: string; out _2_t_headersText: string; out _3_t_bodyText: string): Boolean;
var e_pos: Int64;
begin
  _2_t_headersText := ''; _3_t_bodyText := '';
  e_pos := Pos(#13#10#13#10,_1_t_rawMessage);
  if (e_pos>0) then begin _2_t_headersText:=Copy(_1_t_rawMessage,1,e_pos-1); _3_t_bodyText:=Copy(_1_t_rawMessage,e_pos+4,MaxInt); Exit(True); end;
  e_pos := Pos(#10#10,_1_t_rawMessage);
  if (e_pos>0) then begin _2_t_headersText:=Copy(_1_t_rawMessage,1,e_pos-1); _3_t_bodyText:=Copy(_1_t_rawMessage,e_pos+2,MaxInt); Exit(True); end;
  Result := False;
end;

function httpCoreParseHeaders(const _1_t_headersText: string): Tq4MimeHeaderArray;
var o_lines: TStringList; e_i,e_sep: Int64; t_line,t_name,t_value: string;
begin
  SetLength(Result,0);
  o_lines := TStringList.Create;
  try
    o_lines.Text := StringReplace(_1_t_headersText,#13#10,#10,[rfReplaceAll]);
    for e_i := 0 to o_lines.Count-1 do
    begin
      t_line := o_lines[e_i];
      if (Trim(t_line)='') then Continue;
      if ((e_i=0) and (httpCoreDetectMessageKind(t_line)<>hmkUnknown)) then Continue;
      e_sep := Pos(':',t_line); if (e_sep<=0) then Continue;
      t_name := Trim(Copy(t_line,1,e_sep-1));
      t_value := Trim(Copy(t_line,e_sep+1,MaxInt));
      q4mimeCore.mimeAddHeader(Result, q4mimeCore.mimeNewHeader(t_name,t_value));
    end;
  finally
    o_lines.Free;
  end;
end;

function httpCoreGetHeaderValue(const _1_ty_headers: Tq4MimeHeaderArray; const _2_t_name: string): string;
begin Result := q4mimeCore.mimeGetHeaderValue(_1_ty_headers,_2_t_name); end;
function httpCoreSetHeaderValue(var _1_ty_headers: Tq4MimeHeaderArray; const _2_t_name, _3_t_value: string): Boolean;
begin Result := q4mimeCore.mimeSetHeaderValue(_1_ty_headers,_2_t_name,_3_t_value); end;
function httpCoreHeaderExists(const _1_ty_headers: Tq4MimeHeaderArray; const _2_t_name: string): Boolean;
begin Result := q4mimeCore.mimeHeaderExists(_1_ty_headers,_2_t_name); end;

function httpCoreDetectBodyKind(const _1_t_contentType: string): Tq4HttpBodyKind;
var t_lower: string;
begin
  t_lower := LowerCase(Trim(_1_t_contentType));
  if (t_lower='') then Exit(hbkNone);
  if (Pos('multipart/', t_lower)=1) then Exit(hbkMultipart);
  if (Pos('application/json', t_lower)=1) then Exit(hbkJSON);
  if ((Pos('application/xml', t_lower)=1) or (Pos('text/xml', t_lower)=1)) then Exit(hbkXML);
  if (Pos('application/x-www-form-urlencoded', t_lower)=1) then Exit(hbkFormUrlEncoded);
  Result := hbkRaw;
end;

function httpCoreExtractBoundary(const _1_t_contentType: string): string;
begin Result := q4mimeCore.mimeExtractBoundaryFromContentType(_1_t_contentType); end;

function httpCoreParseQueryString(const _1_t_queryString: string): Tq4HttpQueryParamArray;
var o_pairs: TStringList; e_i,e_sep: Int64; t_item,t_name,t_value: string;
begin
  SetLength(Result,0);
  if (Trim(_1_t_queryString)='') then Exit;
  o_pairs := TStringList.Create;
  try
    o_pairs.StrictDelimiter := True; o_pairs.Delimiter := '&'; o_pairs.DelimitedText := _1_t_queryString;
    for e_i := 0 to o_pairs.Count-1 do
    begin
      t_item := o_pairs[e_i]; e_sep := Pos('=',t_item);
      if (e_sep>0) then begin t_name:=Copy(t_item,1,e_sep-1); t_value:=Copy(t_item,e_sep+1,MaxInt); end
      else begin t_name:=t_item; t_value:=''; end;
      SetLength(Result,Length(Result)+1); Result[High(Result)] := httpCoreNewQueryParam(t_name,t_value);
    end;
  finally
    o_pairs.Free;
  end;
end;

function httpCoreGetQueryParamValue(const _1_ty_params: Tq4HttpQueryParamArray; const _2_t_name: string): string;
var e_i: Int64;
begin
  for e_i := 0 to High(_1_ty_params) do
    if (SameText(_1_ty_params[e_i].t_name, _2_t_name)) then Exit(_1_ty_params[e_i].t_value);
  Result := '';
end;

function httpCoreSplitTarget(const _1_t_target: string; out _2_t_path: string; out _3_t_queryString: string): Boolean;
var e_pos: Int64;
begin
  _2_t_path := _1_t_target; _3_t_queryString := '';
  e_pos := Pos('?',_1_t_target);
  if (e_pos>0) then begin _2_t_path:=Copy(_1_t_target,1,e_pos-1); _3_t_queryString:=Copy(_1_t_target,e_pos+1,MaxInt); end;
  Result := True;
end;

end.
