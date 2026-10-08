Unit q4http;

{$mode objfpc}{$H+}

{
q4http
version du 2026/04/23-06:05

Mapping 4D → q4http -> statut
Command Number 4D,    4D Command,                      q4 API,                           Statut
------------------------------------------------------------------------------------------------
1161,                 HTTP AUTHENTICATE,               httpAuthenticate,                 OK spécifique,
1157,                 HTTP Get,                        httpGet,                          OK spécifique,
1307,                 HTTP Get certificates folder,    httpGetCertificatesFolder,        OK spécifique,
1159,                 HTTP GET OPTION,                 httpGetOption,                    OK spécifique,
1824,                HTTP Parse message,               httpParseMessage,                 Partial,
1158,                 HTTP Request,                    httpRequest,                      OK spécifique,
1306,                 HTTP SET CERTIFICATES FOLDER,    httpSetCertificatesFolder,        OK spécifique,
1160,                 HTTP SET OPTION,                 httpSetOption,                    OK spécifique,

Doc: https://developer.4d.com/docs/21/commands/theme/HTTP

Notes d'implémentation
- Cette unité fournit l'API publique q4 du thème 4D HTTP.
- Elle s'appuie sur q4httpCore, q4mimeCore et q4netCore pour mutualiser la logique HTTP/MIME/réseau.
- Le parsing multipart complet de HTTP Parse message reste à finaliser.
}

Interface

Uses
  Classes,
  SysUtils,
  Variants,
  fphttpclient,
  opensslsockets,
  URIParser,
  q4coreLanguage,
  q4mimeCore,
  q4httpCore,
  q4netCore;

Const
  HTTP_OPTION_HTTPLOG = 'HTTPLOG';
  HTTP_AUTH_BASIC = 'BASIC';
  HTTP_AUTH_DIGEST = 'DIGEST';
  HTTP_STAR = '*';

Type
  Tq4HTTPHeaders = Class( TStringList)
  public
    Constructor Create;
  End;

Function httpAuthenticate( Const _1_t_host: string; Const _2_t_username: string; Const _3_t_password: string; Const _4_t_authType: string): boolean;

Function httpGet( Const _1_t_url: string; Var _2_t_response: string; _3_o_requestHeaders: Tq4HTTPHeaders = nil; _4_o_responseHeaders: Tq4HTTPHeaders = nil): int64;

Function httpGetCertificatesFolder: string;

Function httpGetOption( Const _1_t_optionName: string): variant;

Function httpParseMessage( Const _1_t_rawMessage: string): string;

Function httpRequest( Const _1_t_method: string; Const _2_t_url: string; Const _3_t_body: string; Var _4_t_response: string; _5_o_requestHeaders: Tq4HTTPHeaders = nil;
  _6_o_responseHeaders: Tq4HTTPHeaders = nil): int64;

Procedure httpSetCertificatesFolder( Const _1_t_folder: string);

Procedure httpSetOption( Const _1_t_optionName: string; Const _2_v_value: variant);

Implementation

Var
  g_tAuthHost:     string = '';
  g_tAuthUser:     string = '';
  g_tAuthPassword: string = '';
  g_tAuthType:     string = '';

  g_tCertificatesFolder: string = '';
  g_bHTTPLog: boolean = False;

Constructor Tq4HTTPHeaders.Create;
  Begin
    Inherited Create;
    NameValueSeparator := ':';
    StrictDelimiter := False;
  End;

Procedure internalSetSuccess;
  Begin
    q4coreLanguage.OK := 1;
    q4coreLanguage.Error := 0;
  End;

Procedure internalSetFailure( Const _1_e_error: int64);
  Begin
    q4coreLanguage.OK := 0;
    q4coreLanguage.Error := _1_e_error;
  End;

Function internalJSONEscape( Const _1_t_value: string): string;
  Var
    _e_index: int64;
    _t_char:  char;
  Begin
    Result := '';
    For _e_index := 1 To System.Length( _1_t_value) Do Begin
      _t_char := _1_t_value[_e_index];
      Case _t_char Of
        '\': Result := Result + '\\';
        '"': Result := Result + '\"';
        #8: Result := Result + '\b';
        #9: Result := Result + '\t';
        #10: Result := Result + '\n';
        #13: Result := Result + '\r';
        #12: Result := Result + '\f';
        Else Result := Result + _t_char;
      End;
    End;
  End;

Procedure internalLog( Const _1_t_message: string);
  Begin
    If ( not g_bHTTPLog) Then Exit;

    System.WriteLn( '[q4http] ' + _1_t_message);
  End;

Function internalNormalizeAuthType( Const _1_t_authType: string): string;
  Var
    _t_upper: string;
  Begin
    _t_upper := SysUtils.UpperCase( SysUtils.Trim( _1_t_authType));

    If ( _t_upper = '') Then Exit( HTTP_AUTH_BASIC);

    If ( ( _t_upper <> HTTP_AUTH_BASIC) and ( _t_upper <> HTTP_AUTH_DIGEST)) Then Exit( HTTP_AUTH_BASIC);

    Result := _t_upper;
  End;

Function internalURLMatchesAuthHost( Const _1_t_url: string): boolean;
  Var
    _y_uri: TURI;
  Begin
    If ( g_tAuthHost = '') Then Exit( False);

    _y_uri := URIParser.ParseURI( _1_t_url);
    Result := SysUtils.SameText( _y_uri.Host, g_tAuthHost);
  End;

Function internalCreateClient( Const _1_t_url: string): TFPHTTPClient;
  Begin
    Result := TFPHTTPClient.Create( nil);
    Result.AllowRedirect := True;

    If ( internalURLMatchesAuthHost( _1_t_url)) Then Begin
      Result.UserName := g_tAuthUser;
      Result.Password := g_tAuthPassword;
    End;
  End;

Procedure internalApplyRequestHeaders( _1_o_client: TFPHTTPClient; _2_o_headers: Tq4HTTPHeaders);
  Var
    _e_index: int64;
    _t_name:  string;
    _t_value: string;
  Begin
    If ( _2_o_headers = nil) Then Exit;

    For _e_index := 0 To _2_o_headers.Count - 1 Do Begin
      _t_name := SysUtils.Trim( _2_o_headers.Names[_e_index]);
      _t_value := SysUtils.Trim( _2_o_headers.ValueFromIndex[_e_index]);

      If ( _t_name <> '') Then _1_o_client.AddHeader( _t_name, _t_value);
    End;
  End;

Procedure internalCollectResponseHeaders( _1_o_client: TFPHTTPClient; _2_o_headers: Tq4HTTPHeaders);
  Var
    _e_index: int64;
  Begin
    If ( _2_o_headers = nil) Then Exit;

    _2_o_headers.Clear;
    For _e_index := 0 To _1_o_client.ResponseHeaders.Count - 1 Do _2_o_headers.Add( _1_o_client.ResponseHeaders[_e_index]);
  End;

Function internalBuildRawHeadersJSON( Const _1_ty_headers: Tq4MimeHeaderArray): string;
  Var
    _e_index: int64;
  Begin
    Result := '[';
    For _e_index := 0 To High( _1_ty_headers) Do Begin
      If ( _e_index > 0) Then Result := Result + ',';

      Result := Result + '{"name":"' + internalJSONEscape( _1_ty_headers[_e_index].t_name) + '","value":"' + internalJSONEscape( _1_ty_headers[_e_index].t_value) + '"}';
    End;
    Result := Result + ']';
  End;

Function internalBuildQueryParamsJSON( Const _1_ty_params: Tq4HttpQueryParamArray): string;
  Var
    _e_index: int64;
  Begin
    Result := '[';
    For _e_index := 0 To High( _1_ty_params) Do Begin
      If ( _e_index > 0) Then Result := Result + ',';

      Result := Result + '{"name":"' + internalJSONEscape( _1_ty_params[_e_index].t_name) + '","value":"' + internalJSONEscape( _1_ty_params[_e_index].t_value) + '"}';
    End;
    Result := Result + ']';
  End;

Function internalSplitMultipartParts( Const _1_t_body: string; Const _2_t_boundary: string): Tq4TextArray;
  Var
    _t_marker: string;
    _t_work:   string;
    _e_pos:    int64;
    _t_chunk:  string;
  Begin
    System.SetLength( Result, 0);

    If ( _2_t_boundary = '') Then Exit;

    _t_marker := '--' + _2_t_boundary;
    _t_work := _1_t_body;

    While ( True) Do Begin
      _e_pos := System.Pos( _t_marker, _t_work);
      If ( _e_pos <= 0) Then Break;

      Delete( _t_work, 1, _e_pos + Length( _t_marker) - 1);
      If ( ( _t_work <> '') and ( Copy( _t_work, 1, 2) = '--')) Then Break;

      _e_pos := System.Pos( _t_marker, _t_work);
      If ( _e_pos > 0) Then _t_chunk := SysUtils.Trim( Copy( _t_work, 1, _e_pos - 1))
      Else
        _t_chunk := SysUtils.Trim( _t_work);

      If ( _t_chunk <> '') Then Begin
        SetLength( Result, Length( Result) + 1);
        Result[High( Result)] := _t_chunk;
      End;

      If ( _e_pos <= 0) Then Break;
    End;
  End;

Function internalBuildPartsJSON( Const _1_tt_parts: Tq4TextArray): string;
  Var
    _e_index: int64;
  Begin
    Result := '[';
    For _e_index := 0 To High( _1_tt_parts) Do Begin
      If ( _e_index > 0) Then Result := Result + ',';

      Result := Result + '{"raw":"' + internalJSONEscape( _1_tt_parts[_e_index]) + '"}';
    End;
    Result := Result + ']';
  End;

Function internalHTTPGet( Const _1_t_url: string; Var _2_t_response: string; _3_o_requestHeaders: Tq4HTTPHeaders; _4_o_responseHeaders: Tq4HTTPHeaders): int64;
  Var
    _o_client: TFPHTTPClient;
    _o_responseStream: TStringStream;
  Begin
    _2_t_response := '';
    Result := 0;

    internalLog( 'GET ' + _1_t_url);
    _o_client := internalCreateClient( _1_t_url);
    _o_responseStream := TStringStream.Create( '');

    Try
      internalApplyRequestHeaders( _o_client, _3_o_requestHeaders);
      _o_client.Get( _1_t_url, _o_responseStream);
      _2_t_response := _o_responseStream.DataString;
      internalCollectResponseHeaders( _o_client, _4_o_responseHeaders);

      Result := _o_client.ResponseStatusCode;
      internalSetSuccess;
    Except
      on o_error: Exception Do Begin
        _2_t_response := o_error.Message;
        Result := -1;
        internalSetFailure( 1157);
      End;
    End;

    _o_responseStream.Free;
    _o_client.Free;
  End;

Function internalHTTPRequest( Const _1_t_method: string; Const _2_t_url: string; Const _3_t_body: string; Var _4_t_response: string;
  _5_o_requestHeaders: Tq4HTTPHeaders; _6_o_responseHeaders: Tq4HTTPHeaders): int64;
  Var
    _o_client: TFPHTTPClient;
    _o_requestStream: TStringStream;
    _o_responseStream: TStringStream;
    _t_effectiveMethod: string;
  Begin
    _4_t_response := '';
    Result := 0;

    _t_effectiveMethod := SysUtils.UpperCase( SysUtils.Trim( _1_t_method));
    If ( _t_effectiveMethod = '') Then _t_effectiveMethod := 'GET';

    internalLog( _t_effectiveMethod + ' ' + _2_t_url);

    _o_client := internalCreateClient( _2_t_url);
    _o_requestStream := TStringStream.Create( _3_t_body);
    _o_responseStream := TStringStream.Create( '');

    Try
      internalApplyRequestHeaders( _o_client, _5_o_requestHeaders);
      _o_client.RequestBody := _o_requestStream;
      _o_client.HTTPMethod( _t_effectiveMethod, _2_t_url, _o_responseStream, []);
      _4_t_response := _o_responseStream.DataString;
      internalCollectResponseHeaders( _o_client, _6_o_responseHeaders);

      Result := _o_client.ResponseStatusCode;
      internalSetSuccess;
    Except
      on o_error: Exception Do Begin
        _4_t_response := o_error.Message;
        Result := -1;
        internalSetFailure( 1158);
      End;
    End;

    _o_responseStream.Free;
    _o_requestStream.Free;
    _o_client.Free;
  End;

Function internalHTTPParseMessage( Const _1_t_rawMessage: string): string;
  Var
    _y_message:     Tq4HttpMessage;
    _t_headersText: string;
    _t_bodyText:    string;
    _t_contentType: string;
    _t_boundary:    string;
    _tt_parts:      Tq4TextArray;
  Begin
    _y_message := q4httpCore.httpCoreNewMessage;
    q4httpCore.httpCoreSplitHeadersAndBody( _1_t_rawMessage, _t_headersText, _t_bodyText);

    If ( _t_headersText <> '') Then Begin
      _y_message.ty_headers := q4httpCore.httpCoreParseHeaders( _t_headersText);
      If ( Pos( #13#10, _t_headersText) > 0) Then _y_message.t_startLine := Copy( _t_headersText, 1, Pos( #13#10, _t_headersText) - 1)
      Else If ( Pos( #10, _t_headersText) > 0) Then _y_message.t_startLine := Copy( _t_headersText, 1, Pos( #10, _t_headersText) - 1)
      Else
        _y_message.t_startLine := _t_headersText;

      Case q4httpCore.httpCoreDetectMessageKind( _y_message.t_startLine) Of
        hmkRequest: q4httpCore.httpCoreParseRequestLine( _y_message.t_startLine, _y_message);
        hmkResponse: q4httpCore.httpCoreParseStatusLine( _y_message.t_startLine, _y_message);
      End;
    End;

    _y_message.t_bodyText := _t_bodyText;
    _y_message.y_body := q4mimeCore.mimeStringToBytesUTF8( _t_bodyText);
    _t_contentType := q4httpCore.httpCoreGetHeaderValue( _y_message.ty_headers, 'Content-Type');
    _y_message.e_bodyKind := q4httpCore.httpCoreDetectBodyKind( _t_contentType);
    _t_boundary := q4httpCore.httpCoreExtractBoundary( _t_contentType);

    If ( _y_message.e_kind = hmkRequest) Then _y_message.ty_queryParams := q4httpCore.httpCoreParseQueryString( _y_message.t_queryString);

    If ( _y_message.e_bodyKind = hbkMultipart) Then _tt_parts := internalSplitMultipartParts( _t_bodyText, _t_boundary)
    Else
      SetLength( _tt_parts, 0);

    Result := '{' + '"kind":"' + internalJSONEscape( IntToStr( Ord( _y_message.e_kind))) + '",' + '"startLine":"' + internalJSONEscape( _y_message.t_startLine) +
      '",' + '"method":"' + internalJSONEscape( _y_message.t_method) + '",' + '"target":"' + internalJSONEscape( _y_message.t_target) + '",' + '"path":"' +
      internalJSONEscape( _y_message.t_path) + '",' + '"queryString":"' + internalJSONEscape( _y_message.t_queryString) + '",' + '"version":"' +
      internalJSONEscape( _y_message.t_version) + '",' + '"statusCode":' + IntToStr( _y_message.e_statusCode) + ',' + '"reasonPhrase":"' +
      internalJSONEscape( _y_message.t_reasonPhrase) + '",' + '"headers":' + internalBuildRawHeadersJSON( _y_message.ty_headers) + ',' + '"queryParams":' +
      internalBuildQueryParamsJSON( _y_message.ty_queryParams) + ',' + '"body":"' + internalJSONEscape( _y_message.t_bodyText) + '",' + '"contentType":"' +
      internalJSONEscape( _t_contentType) + '",' + '"boundary":"' + internalJSONEscape( _t_boundary) + '",' + '"bodyKind":' + IntToStr( Ord( _y_message.e_bodyKind)) +
      ',' + '"parts":' + internalBuildPartsJSON( _tt_parts) + ',' + '"rawLength":' + IntToStr( Length( _1_t_rawMessage)) + '}';

    internalSetSuccess;
  End;

Function httpAuthenticate( Const _1_t_host: string; Const _2_t_username: string; Const _3_t_password: string; Const _4_t_authType: string): boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/http-authenticate
    g_tAuthHost := SysUtils.Trim( _1_t_host);
    g_tAuthUser := _2_t_username;
    g_tAuthPassword := _3_t_password;
    g_tAuthType := internalNormalizeAuthType( _4_t_authType);

    internalLog( 'AUTH host=' + g_tAuthHost + ' user=' + g_tAuthUser + ' type=' + g_tAuthType);
    internalSetSuccess;
    Result := True;
  End;

Function httpGet( Const _1_t_url: string; Var _2_t_response: string; _3_o_requestHeaders: Tq4HTTPHeaders; _4_o_responseHeaders: Tq4HTTPHeaders): int64;
  Begin
    //https://developer.4d.com/docs/21/commands/http-get
    Result := internalHTTPGet( _1_t_url, _2_t_response, _3_o_requestHeaders, _4_o_responseHeaders);
  End;

Function httpGetCertificatesFolder: string;
  Begin
    //https://developer.4d.com/docs/21/commands/http-get-certificates-folder
    Result := g_tCertificatesFolder;
    internalSetSuccess;
  End;

Function httpGetOption( Const _1_t_optionName: string): variant;
  Var
    _t_upperOption: string;
  Begin
    //https://developer.4d.com/docs/21/commands/http-get-option
    _t_upperOption := SysUtils.UpperCase( SysUtils.Trim( _1_t_optionName));

    If ( _t_upperOption = HTTP_OPTION_HTTPLOG) Then Result := g_bHTTPLog
    Else
      Result := Null;

    internalSetSuccess;
  End;

Function httpParseMessage( Const _1_t_rawMessage: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/http-parse-message
    Result := internalHTTPParseMessage( _1_t_rawMessage);
  End;

Function httpRequest( Const _1_t_method: string; Const _2_t_url: string; Const _3_t_body: string; Var _4_t_response: string; _5_o_requestHeaders: Tq4HTTPHeaders;
  _6_o_responseHeaders: Tq4HTTPHeaders): int64;
  Begin
    //https://developer.4d.com/docs/21/commands/http-request
    Result := internalHTTPRequest( _1_t_method, _2_t_url, _3_t_body, _4_t_response, _5_o_requestHeaders, _6_o_responseHeaders);
  End;

Procedure httpSetCertificatesFolder( Const _1_t_folder: string);
  Begin
    //https://developer.4d.com/docs/21/commands/http-set-certificates-folder
    g_tCertificatesFolder := SysUtils.Trim( _1_t_folder);
    internalLog( 'CERTIFICATES=' + g_tCertificatesFolder);
    internalSetSuccess;
  End;

Procedure httpSetOption( Const _1_t_optionName: string; Const _2_v_value: variant);
  Var
    _t_upperOption: string;
  Begin
    //https://developer.4d.com/docs/21/commands/http-set-option
    _t_upperOption := SysUtils.UpperCase( SysUtils.Trim( _1_t_optionName));

    If ( _t_upperOption = HTTP_OPTION_HTTPLOG) Then Begin
      g_bHTTPLog := boolean( _2_v_value);
      internalSetSuccess;
      Exit;
    End;

    internalSetFailure( 1160);
  End;

End.
