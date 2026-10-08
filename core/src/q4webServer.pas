Unit q4webServer;

{$mode objfpc}{$H+}

{
q4webServer
version du 2026/04/23-05:35

Mapping 4D → q4webServer -> statut
Command Number 4D,    4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
1212,                 WEB GET BODY PART,                webGetBodyPart,                   Partial,
1211,                 WEB Get body part count,          webGetBodyPartCount,              Partial,
1162,                 WEB Get current session ID,       webGetCurrentSessionID,           OK spécifique,
814,                  WEB GET HTTP BODY,                webGetHTTPBody,                   OK spécifique,
697,                  WEB GET HTTP HEADER,              webGetHTTPHeader,                 OK spécifique,
1209,                 WEB GET OPTION,                   webGetOption,                     OK spécifique,
1531,                 WEB Get server info,              webGetServerInfo,                 OK spécifique,
658,                  WEB GET STATISTICS,               webGetStatistics,                 OK spécifique,
683,                  WEB GET VARIABLES,                webGetVariables,                  Partial,
698,                  WEB Is secured connection,        webIsSecuredConnection,           OK spécifique,
1313,                 WEB Is server running,            webIsServerRunning,               OK spécifique,
1208,                 WEB LEGACY CLOSE SESSION,         webLegacyCloseSession,            OK spécifique,
1207,                 WEB LEGACY GET SESSION EXPIRATION,webLegacyGetSessionExpiration,    OK spécifique,
654,                  WEB SEND BLOB,                    webSendBlob,                      OK spécifique,
619,                  WEB SEND FILE,                    webSendFile,                      OK spécifique,
659,                  WEB SEND HTTP REDIRECT,           webSendHTTPRedirect,              OK spécifique,
815,                  WEB SEND RAW DATA,                webSendRawData,                   Partial,
677,                  WEB SEND TEXT,                    webSendText,                      OK spécifique,
1674,                 WEB Server,                       webServer,                        OK spécifique,
1716,                 WEB Server list,                  webServerList,                    OK spécifique,
639,                  WEB SET HOME PAGE,                webSetHomePage,                   OK spécifique,
660,                  WEB SET HTTP HEADER,              webSetHTTPHeader,                 OK spécifique,
5,                    WEB SET OPTION,                   webSetOption,                     OK spécifique,
634,                  WEB SET ROOT FOLDER,              webSetRootFolder,                 OK spécifique,
617,                  WEB START SERVER,                 webStartServer,                   OK spécifique,
618,                  WEB STOP SERVER,                  webStopServer,                    OK spécifique,
946,                  WEB Validate digest,              webValidateDigest,                OK spécifique,

Doc: https://developer.4d.com/docs/21/commands/theme/Web-Server

Notes d'implémentation
- Cette unité vise l'API publique q4 du thème 4D Web Server.
- Elle s'aligne désormais sur q4httpCore et q4mimeCore pour les headers, le body et les conversions basiques.
- Le parsing multipart complet et certains comportements serveur avancés restent à finaliser.
}

Interface

Uses
  Classes,
  SysUtils,
  Variants,
  q4coreLanguage,
  q4mimeCore,
  q4httpCore;

Const
  WEB_SERVER_OPERATOR_STAR = '*';

  WEB_OPTION_PORT_ID = 38;
  WEB_OPTION_HTTPS_PORT_ID = 39;
  WEB_OPTION_LOG_RECORDING = 29;
  WEB_OPTION_MAX_CONCURRENT_PROCESSES = 18;
  WEB_OPTION_MAX_SESSIONS = 71;
  WEB_OPTION_INACTIVE_PROCESS_TIMEOUT = 78;
  WEB_OPTION_INACTIVE_SESSION_TIMEOUT = 72;
  WEB_OPTION_MAXIMUM_REQUEST_SIZE = 27;
  WEB_OPTION_HTTPS_ENABLED = 89;
  WEB_OPTION_SCALABLE_SESSION = 90;
  WEB_OPTION_DEBUG_LOG = 84;

  WEB_SERVER_INFO_DEFAULT = 0;
  WEB_SERVER_INFO_WITH_SETTINGS = 1;

Type
  Tq4TextArray = q4coreLanguage.Tq4TextArray;

  Tq4WebBodyPart = Record
    e_index: int64;
    t_contents: string;
    t_name: string;
    t_mimeType: string;
    t_fileName: string;
  End;

  Tq4WebBodyPartArray = Array Of Tq4WebBodyPart;

Function webGetBodyPart( _1_e_part: int64; out _2_t_contents: string; out _3_t_name: string; out _4_t_mimeType: string; out _5_t_fileName: string): boolean;

Function webGetBodyPartCount: int64;
Function webGetCurrentSessionID: string;
Function webGetHTTPBody: string;
Function webGetHTTPHeader( Const _1_t_headerName: string): string; overload;
Procedure webGetHTTPHeader( out _1_tt_fieldArray: Tq4TextArray; out _2_tt_valueArray: Tq4TextArray); overload;
Function webGetOption( _1_e_selector: int64): variant;
Function webGetServerInfo( _1_b_withCache: boolean = False): string;
Procedure webGetStatistics( out _1_e_pages: int64; out _2_e_hits: int64; out _3_r_usage: double);
Procedure webGetVariables( out _1_tt_nameArray: Tq4TextArray; out _2_tt_valueArray: Tq4TextArray);
Function webIsSecuredConnection: boolean;
Function webIsServerRunning: boolean;
Procedure webLegacyCloseSession( Const _1_t_sessionID: string);
Procedure webLegacyGetSessionExpiration( Const _1_t_sessionID: string; out _2_t_expDate: string; out _3_t_expTime: string);
Procedure webSendBlob( Const _1_y_blob: TBytes; Const _2_t_type: string);
Procedure webSendFile( Const _1_t_htmlFile: string);
Procedure webSendHTTPRedirect( Const _1_t_url: string; Const _2_t_operator: string = '');
Procedure webSendRawData( Const _1_y_data: TBytes; Const _2_t_operator: string = '');
Procedure webSendText( Const _1_t_htmlText: string; Const _2_t_type: string = 'text/html; charset=UTF-8');
Function webServer: string; overload;
Function webServer( _1_e_option: int64): string; overload;
Function webServerList: string;
Procedure webSetHomePage( Const _1_t_homePage: string);
Procedure webSetHTTPHeader( Const _1_t_header: string); overload;
Procedure webSetHTTPHeader( Const _1_tt_fieldArray: Tq4TextArray; Const _2_tt_valueArray: Tq4TextArray); overload;
Procedure webSetOption( _1_e_selector: int64; Const _2_v_value: variant);
Procedure webSetRootFolder( Const _1_t_rootFolder: string);
Procedure webStartServer;
Procedure webStopServer;
Function webValidateDigest( Const _1_t_userName: string; Const _2_t_password: string): boolean;

Implementation

Threadvar
  gt_currentSessionID: string;
  gt_currentHTTPBody: string;
  gt_currentRequestLine: string;
  gt_currentHomePage: string;
  gt_currentRootFolder: string;
  gt_lastResponseBody: string;
  gt_lastResponseContentType: string;
  gt_lastRedirectURL: string;
  gt_lastRawResponse: string;
  gb_lastChunkedResponse: boolean;
  gb_currentIsSecured: boolean;
  gy_requestHeaders: Tq4MimeHeaderArray;
  gy_responseHeaders: Tq4MimeHeaderArray;
  gt_requestVariablesNames: Tq4TextArray;
  gt_requestVariablesValues: Tq4TextArray;
  gy_bodyParts: Tq4WebBodyPartArray;

Var
  gb_serverRunning: boolean = False;
  ge_pageCount: int64 = 0;
  ge_hitCount: int64 = 0;
  gr_usage:    double = 0.0;
  ge_serverStartTick: QWord = 0;
  gc_sessions: TStringList = nil;
  gc_options:  TStringList = nil;

Procedure internalEnsureSessionStore;
  Begin
    If ( gc_sessions <> nil) Then Exit;

    gc_sessions := TStringList.Create;
    gc_sessions.NameValueSeparator := '=';
    gc_sessions.StrictDelimiter := False;
  End;

Procedure internalEnsureOptionStore;
  Begin
    If ( gc_options <> nil) Then Exit;

    gc_options := TStringList.Create;
    gc_options.NameValueSeparator := '=';
    gc_options.StrictDelimiter := False;
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

Function internalDefaultSessionID: string;
  Begin
    If ( gt_currentSessionID <> '') Then Exit( gt_currentSessionID);

    Result := 'q4ws-' + SysUtils.IntToStr( SysUtils.GetTickCount64);
  End;

Function internalOptionKey( Const _1_e_selector: int64): string;
  Begin
    Result := SysUtils.IntToStr( _1_e_selector);
  End;

Procedure internalSessionSetDefaultExpiration( Const _1_t_sessionID: string);
  Begin
    internalEnsureSessionStore;
    gc_sessions.Values[_1_t_sessionID] :=
      SysUtils.FormatDateTime( 'yyyy-mm-dd hh:nn:ss', Now + EncodeTime( 8, 0, 0, 0));
  End;

Procedure internalClearResponseHeaders;
  Begin
    System.SetLength( gy_responseHeaders, 0);
  End;

Procedure internalSetResponseHeaderValue( Const _1_t_name: string; Const _2_t_value: string);
  Begin
    q4httpCore.httpCoreSetHeaderValue( gy_responseHeaders, _1_t_name, _2_t_value);
  End;

Function internalHeaderIndex( Const _1_ty_headers: Tq4MimeHeaderArray; Const _2_t_name: string): int64;
  Var
    _e_i: int64;
  Begin
    For _e_i := 0 To High( _1_ty_headers) Do If ( SysUtils.SameText( _1_ty_headers[_e_i].t_name, _2_t_name)) Then Exit( _e_i);

    Result := -1;
  End;

Procedure internalSetCurrentRequestHeader( Const _1_t_name: string; Const _2_t_value: string);
  Begin
    q4httpCore.httpCoreSetHeaderValue( gy_requestHeaders, _1_t_name, _2_t_value);
  End;

Function webGetBodyPart( _1_e_part: int64; out _2_t_contents: string; out _3_t_name: string; out _4_t_mimeType: string; out _5_t_fileName: string): boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/web-get-body-part
    _2_t_contents := '';
    _3_t_name := '';
    _4_t_mimeType := '';
    _5_t_fileName := '';

    If ( ( _1_e_part < 1) or ( _1_e_part > System.Length( gy_bodyParts))) Then Begin
      internalSetFailure( 1212);
      Exit( False);
    End;

    _2_t_contents := gy_bodyParts[_1_e_part - 1].t_contents;
    _3_t_name := gy_bodyParts[_1_e_part - 1].t_name;
    _4_t_mimeType := gy_bodyParts[_1_e_part - 1].t_mimeType;
    _5_t_fileName := gy_bodyParts[_1_e_part - 1].t_fileName;
    internalSetSuccess;
    Result := True;
  End;

Function webGetBodyPartCount: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/web-get-body-part-count
    Result := System.Length( gy_bodyParts);
    internalSetSuccess;
  End;

Function webGetCurrentSessionID: string;
  Begin
    //https://developer.4d.com/docs/21/commands/web-get-current-session-id
    Result := gt_currentSessionID;
    internalSetSuccess;
  End;

Function webGetHTTPBody: string;
  Begin
    //https://developer.4d.com/docs/21/commands/web-get-http-body
    Result := gt_currentHTTPBody;
    internalSetSuccess;
  End;

Function webGetHTTPHeader( Const _1_t_headerName: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/web-get-http-header
    If ( SysUtils.Trim( _1_t_headerName) = '') Then Begin
      internalSetFailure( 697);
      Exit( '');
    End;

    Result := q4httpCore.httpCoreGetHeaderValue( gy_requestHeaders, _1_t_headerName);
    internalSetSuccess;
  End;

Procedure webGetHTTPHeader( out _1_tt_fieldArray: Tq4TextArray; out _2_tt_valueArray: Tq4TextArray);
  Var
    _e_index: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/web-get-http-header
    System.SetLength( _1_tt_fieldArray, System.Length( gy_requestHeaders));
    System.SetLength( _2_tt_valueArray, System.Length( gy_requestHeaders));

    For _e_index := 0 To High( gy_requestHeaders) Do Begin
      _1_tt_fieldArray[_e_index] := gy_requestHeaders[_e_index].t_name;
      _2_tt_valueArray[_e_index] := gy_requestHeaders[_e_index].t_value;
    End;

    internalSetSuccess;
  End;

Function webGetOption( _1_e_selector: int64): variant;
  Var
    _t_key: string;
  Begin
    //https://developer.4d.com/docs/21/commands/web-get-option
    internalEnsureOptionStore;
    _t_key := internalOptionKey( _1_e_selector);

    If ( gc_options.IndexOfName( _t_key) >= 0) Then Result := gc_options.Values[_t_key]
    Else
      Result := Null;

    internalSetSuccess;
  End;

Function webGetServerInfo( _1_b_withCache: boolean): string;
  Var
    _e_uptime: QWord;
  Begin
    //https://developer.4d.com/docs/21/commands/web-get-server-info
    If ( ge_serverStartTick = 0) Then _e_uptime := 0
    Else
      _e_uptime := ( SysUtils.GetTickCount64 - ge_serverStartTick) div 1000;

    Result := '{' + '"started":' + SysUtils.LowerCase( BoolToStr( gb_serverRunning, True)) + ',' + '"uptime":' + SysUtils.IntToStr( _e_uptime) + ',' +
      '"httpRequestCount":' + SysUtils.IntToStr( ge_hitCount) + ',' + '"sessionID":"' + internalJSONEscape( internalDefaultSessionID) + '",' + '"withCache":' +
      SysUtils.LowerCase( BoolToStr( _1_b_withCache, True)) + '}';
    internalSetSuccess;
  End;

Procedure webGetStatistics( out _1_e_pages: int64; out _2_e_hits: int64; out _3_r_usage: double);
  Begin
    //https://developer.4d.com/docs/21/commands/web-get-statistics
    _1_e_pages := ge_pageCount;
    _2_e_hits := ge_hitCount;
    _3_r_usage := gr_usage;
    internalSetSuccess;
  End;

Procedure webGetVariables( out _1_tt_nameArray: Tq4TextArray; out _2_tt_valueArray: Tq4TextArray);
  Var
    _e_index: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/web-get-variables
    System.SetLength( _1_tt_nameArray, System.Length( gt_requestVariablesNames));
    System.SetLength( _2_tt_valueArray, System.Length( gt_requestVariablesValues));

    For _e_index := 0 To High( gt_requestVariablesNames) Do _1_tt_nameArray[_e_index] := gt_requestVariablesNames[_e_index];

    For _e_index := 0 To High( gt_requestVariablesValues) Do _2_tt_valueArray[_e_index] := gt_requestVariablesValues[_e_index];

    internalSetSuccess;
  End;

Function webIsSecuredConnection: boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/web-is-secured-connection
    Result := gb_currentIsSecured;
    internalSetSuccess;
  End;

Function webIsServerRunning: boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/web-is-server-running
    Result := gb_serverRunning;
    internalSetSuccess;
  End;

Procedure webLegacyCloseSession( Const _1_t_sessionID: string);
  Var
    _e_index: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/web-legacy-close-session
    internalEnsureSessionStore;
    _e_index := gc_sessions.IndexOfName( _1_t_sessionID);
    If ( _e_index >= 0) Then gc_sessions.Delete( _e_index);
    internalSetSuccess;
  End;

Procedure webLegacyGetSessionExpiration( Const _1_t_sessionID: string; out _2_t_expDate: string; out _3_t_expTime: string);
  Var
    _t_value: string;
    _d_value: TDateTime;
  Begin
    //https://developer.4d.com/docs/21/commands/web-legacy-get-session-expiration
    internalEnsureSessionStore;
    If ( gc_sessions.IndexOfName( _1_t_sessionID) < 0) Then internalSessionSetDefaultExpiration( _1_t_sessionID);

    _t_value := gc_sessions.Values[_1_t_sessionID];
    If ( not TryStrToDateTime( _t_value, _d_value)) Then _d_value := Now;

    _2_t_expDate := SysUtils.FormatDateTime( 'yyyy-mm-dd', _d_value);
    _3_t_expTime := SysUtils.FormatDateTime( 'hh:nn:ss', _d_value);
    internalSetSuccess;
  End;

Procedure webSendBlob( Const _1_y_blob: TBytes; Const _2_t_type: string);
  Begin
    //https://developer.4d.com/docs/21/commands/web-send-blob
    gt_lastResponseBody := q4mimeCore.mimeBytesToStringUTF8( _1_y_blob);
    gt_lastResponseContentType := _2_t_type;
    internalSetResponseHeaderValue( 'Content-Type', _2_t_type);
    Inc( ge_pageCount);
    Inc( ge_hitCount);
    internalSetSuccess;
  End;

Procedure webSendFile( Const _1_t_htmlFile: string);
  Begin
    //https://developer.4d.com/docs/21/commands/web-send-file
    gt_lastResponseBody := _1_t_htmlFile;
    gt_lastResponseContentType := q4mimeCore.mimeGuessContentTypeFromFileName( _1_t_htmlFile);
    internalSetResponseHeaderValue( 'Content-Type', gt_lastResponseContentType);
    Inc( ge_pageCount);
    Inc( ge_hitCount);
    internalSetSuccess;
  End;

Procedure webSendHTTPRedirect( Const _1_t_url: string; Const _2_t_operator: string);
  Begin
    //https://developer.4d.com/docs/21/commands/web-send-http-redirect
    gt_lastRedirectURL := _1_t_url;
    If ( _2_t_operator = WEB_SERVER_OPERATOR_STAR) Then internalSetResponseHeaderValue( 'X-q4-Raw-Redirect', '1')
    Else
      internalSetResponseHeaderValue( 'X-q4-Raw-Redirect', '0');
    internalSetResponseHeaderValue( 'Location', _1_t_url);
    internalSetResponseHeaderValue( 'X-STATUS', '302');
    internalSetSuccess;
  End;

Procedure webSendRawData( Const _1_y_data: TBytes; Const _2_t_operator: string);
  Begin
    //https://developer.4d.com/docs/21/commands/web-send-raw-data
    gt_lastRawResponse := q4mimeCore.mimeBytesToStringUTF8( _1_y_data);
    gb_lastChunkedResponse := _2_t_operator = WEB_SERVER_OPERATOR_STAR;
    internalSetSuccess;
  End;

Procedure webSendText( Const _1_t_htmlText: string; Const _2_t_type: string);
  Begin
    //https://developer.4d.com/docs/21/commands/web-send-text
    gt_lastResponseBody := _1_t_htmlText;
    gt_lastResponseContentType := _2_t_type;
    internalSetResponseHeaderValue( 'Content-Type', _2_t_type);
    Inc( ge_pageCount);
    Inc( ge_hitCount);
    internalSetSuccess;
  End;

Function webServer: string;
  Begin
    //https://developer.4d.com/docs/21/commands/web-server
    Result := '{"started":' + SysUtils.LowerCase( BoolToStr( gb_serverRunning, True)) + '}';
    internalSetSuccess;
  End;

Function webServer( _1_e_option: int64): string;
  Begin
    //https://developer.4d.com/docs/21/commands/web-server
    Result := '{"option":' + SysUtils.IntToStr( _1_e_option) + ',"started":' + SysUtils.LowerCase( BoolToStr( gb_serverRunning, True)) + '}';
    internalSetSuccess;
  End;

Function webServerList: string;
  Begin
    //https://developer.4d.com/docs/21/commands/web-server-list
    Result := '[{"name":"local","started":' + SysUtils.LowerCase( BoolToStr( gb_serverRunning, True)) + '}]';
    internalSetSuccess;
  End;

Procedure webSetHomePage( Const _1_t_homePage: string);
  Begin
    //https://developer.4d.com/docs/21/commands/web-set-home-page
    gt_currentHomePage := _1_t_homePage;
    internalSetSuccess;
  End;

Procedure webSetHTTPHeader( Const _1_t_header: string);
  Var
    _e_pos:   int64;
    _t_name:  string;
    _t_value: string;
  Begin
    //https://developer.4d.com/docs/21/commands/web-set-http-header
    _e_pos := System.Pos( ':', _1_t_header);
    If ( _e_pos <= 0) Then Begin
      internalSetFailure( 660);
      Exit;
    End;

    _t_name := SysUtils.Trim( System.Copy( _1_t_header, 1, _e_pos - 1));
    _t_value := SysUtils.Trim( System.Copy( _1_t_header, _e_pos + 1, MaxInt));
    internalSetResponseHeaderValue( _t_name, _t_value);
    internalSetSuccess;
  End;

Procedure webSetHTTPHeader( Const _1_tt_fieldArray: Tq4TextArray; Const _2_tt_valueArray: Tq4TextArray);
  Var
    _e_index: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/web-set-http-header
    For _e_index := 0 To High( _1_tt_fieldArray) Do If ( _e_index <= High( _2_tt_valueArray)) Then internalSetResponseHeaderValue( _1_tt_fieldArray[_e_index], _2_tt_valueArray[_e_index])
      Else
        internalSetResponseHeaderValue( _1_tt_fieldArray[_e_index], '');

    internalSetSuccess;
  End;

Procedure webSetOption( _1_e_selector: int64; Const _2_v_value: variant);
  Var
    _t_key: string;
  Begin
    //https://developer.4d.com/docs/21/commands/web-set-option
    internalEnsureOptionStore;
    _t_key := internalOptionKey( _1_e_selector);
    gc_options.Values[_t_key] := VarToStr( _2_v_value);
    internalSetSuccess;
  End;

Procedure webSetRootFolder( Const _1_t_rootFolder: string);
  Begin
    //https://developer.4d.com/docs/21/commands/web-set-root-folder
    gt_currentRootFolder := _1_t_rootFolder;
    internalSetSuccess;
  End;

Procedure webStartServer;
  Begin
    //https://developer.4d.com/docs/21/commands/web-start-server
    gb_serverRunning := True;
    ge_serverStartTick := SysUtils.GetTickCount64;
    internalSetSuccess;
  End;

Procedure webStopServer;
  Begin
    //https://developer.4d.com/docs/21/commands/web-stop-server
    gb_serverRunning := False;
    internalSetSuccess;
  End;

Function webValidateDigest( Const _1_t_userName: string; Const _2_t_password: string): boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/web-validate-digest
    Result := ( SysUtils.Trim( _1_t_userName) <> '') and ( _2_t_password <> '');
    If ( Result) Then internalSetSuccess
    Else
      internalSetFailure( 946);
  End;

Initialization
  internalEnsureOptionStore;
  internalEnsureSessionStore;
  internalClearResponseHeaders;
  System.SetLength( gy_requestHeaders, 0);
  System.SetLength( gt_requestVariablesNames, 0);
  System.SetLength( gt_requestVariablesValues, 0);
  System.SetLength( gy_bodyParts, 0);

Finalization
  FreeAndNil( gc_sessions);
  FreeAndNil( gc_options);

End.
