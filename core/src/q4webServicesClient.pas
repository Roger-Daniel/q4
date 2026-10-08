Unit q4webServicesClient;

{$mode objfpc}{$H+}

{
Mapping 4D → q4webServicesClient -> statut
Command Number 4D,    4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
786,                  WEB SERVICE AUTHENTICATE,         webServiceAuthenticate,           OK spécifique,
778,                  WEB SERVICE CALL,                 webServiceCall,                   OK spécifique,
780,                  WEB SERVICE Get info,             webServiceGetInfo,                OK spécifique,
779,                  WEB SERVICE GET RESULT,           webServiceGetResult,              OK spécifique,
901,                  WEB SERVICE SET OPTION,           webServiceSetOption,              OK spécifique,
777,                  WEB SERVICE SET PARAMETER,        webServiceSetParameter,           OK spécifique,

Doc: https://developer.4d.com/docs/21/commands/theme/Web-Services-Client
Notes d'implémentation
- Cette unité fournit une façade q4 pour le thème 4D Web Services (Client).
- Elle s'appuie sur q4netCore et q4httpCore, mais reste volontairement pragmatique.
- L'appel SOAP est réalisé via HTTP POST avec une enveloppe SOAP 1.1 simple.
- L'extraction du résultat XML reste volontairement légère mais exploitable pour les cas simples.
}

Interface

Uses
  Classes, SysUtils, Variants, q4coreLanguage, q4netCore, q4httpCore;

Const
  WEB_SERVICE_AUTH_NOT_SPECIFIED = 0;
  WEB_SERVICE_AUTH_BASIC = 1;
  WEB_SERVICE_AUTH_DIGEST = 2;

  WEB_SERVICE_INFO_DETAILED_MESSAGE = 1;
  WEB_SERVICE_INFO_HTTP_STATUS_CODE = 2;
  WEB_SERVICE_INFO_FAULT_ACTOR = 3;
  WEB_SERVICE_INFO_ERROR_CODE = 4;

  WEB_SERVICE_OPTION_TIMEOUT = 8;
  WEB_SERVICE_OPERATOR_STAR = '*';

  WEB_SERVICE_ERROR_NONE = 0;
  WEB_SERVICE_ERROR_INTERNAL_FAULT = 9914;

Type
  Tq4WebServiceParameter = Record
    t_name: string;
    v_value: variant;
    t_soapType: string;
  End;
  Tq4WebServiceParameterArray = Array Of Tq4WebServiceParameter;

  Tq4WebServiceOption = Record
    e_option: int64;
    v_value: variant;
  End;
  Tq4WebServiceOptionArray = Array Of Tq4WebServiceOption;

  Tq4WebServiceAuthentication = Record
    t_name: string;
    t_password: string;
    e_authMethod: int64;
    b_forProxy: boolean;
  End;

  Tq4WebServiceLastError = Record
    e_code: int64;
    t_detailedMessage: string;
    e_httpStatusCode: int64;
    t_faultActor: string;
  End;

Procedure webServiceAuthenticate( Const _1_t_name: string; Const _2_t_password: string; _3_e_authMethod: int64; Const _4_t_operator: string = '');
Procedure webServiceCall( Const _1_t_accessURL: string; Const _2_t_soapAction: string; Const _3_t_methodName: string; Const _4_t_nameSpace: string;
  _5_e_complexType: int64; Const _6_t_operator: string = '');
Function webServiceGetInfo( _1_e_infoType: int64): string;
Procedure webServiceGetResult( out _1_v_returnValue: variant; Const _2_t_returnName: string = ''; Const _3_t_operator: string = '');
Procedure webServiceSetOption( _1_e_option: int64; Const _2_v_value: variant);
Procedure webServiceSetParameter( Const _1_t_name: string; Const _2_v_value: variant; Const _3_t_soapType: string = '');

Implementation

Uses
  fphttpclient, opensslsockets, URIParser, q4mimeCore, q4interruptions;

Threadvar
  gy_transport:  Tq4NetTransportState;
  gc_parameters: Tq4WebServiceParameterArray;
  gc_options:    Tq4WebServiceOptionArray;
  gy_authentication: Tq4WebServiceAuthentication;
  gy_lastError:  Tq4WebServiceLastError;
  gv_lastResult: variant;
  gt_lastResultName: string;
  gt_lastResponseXML: string;
  ge_lastHTTPStatusCode: int64;

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

Procedure internalResetLastError;
  Begin
    gy_lastError.e_code := WEB_SERVICE_ERROR_NONE;
    gy_lastError.t_detailedMessage := '';
    gy_lastError.e_httpStatusCode := 0;
    gy_lastError.t_faultActor := '';
    ge_lastHTTPStatusCode := 0;
  End;

Procedure internalAppendParameter( Const _1_y_parameter: Tq4WebServiceParameter);
  Begin
    SetLength( gc_parameters, Length( gc_parameters) + 1);
    gc_parameters[High( gc_parameters)] := _1_y_parameter;
  End;

Procedure internalAppendOption( Const _1_y_option: Tq4WebServiceOption);
  Begin
    SetLength( gc_options, Length( gc_options) + 1);
    gc_options[High( gc_options)] := _1_y_option;
  End;

Function internalIsStar( Const _1_t_operator: string): boolean;
  Begin
    Result := Trim( _1_t_operator) = WEB_SERVICE_OPERATOR_STAR;
  End;

Function internalXMLEscape( Const _1_t_value: string): string;
  Var
    _e_i: int64;
    _t_c: char;
  Begin
    Result := '';
    For _e_i := 1 To Length( _1_t_value) Do Begin
      _t_c := _1_t_value[_e_i];
      Case _t_c Of
        '&': Result += '&amp;';
        '<': Result += '&lt;';
        '>': Result += '&gt;';
        '"': Result += '&quot;';
        '''': Result += '&apos;';
        Else Result += _t_c;
      End;
    End;
  End;

Function internalVariantToXMLText( Const _1_v_value: variant): string;
  Begin
    If ( VarIsNull( _1_v_value)) Then Exit( '');

    Case VarType( _1_v_value) Of
      varSmallint, varInteger, varShortInt, varByte, varWord, varLongWord, varInt64: Result := VarToStr( _1_v_value);
      varSingle, varDouble, varCurrency: Result := StringReplace( VarToStr( _1_v_value), ',', '.', [rfReplaceAll]);
      varBoolean: Result := LowerCase( BoolToStr( _1_v_value, True));
      Else Result := internalXMLEscape( VarToStr( _1_v_value));
    End;
  End;

Function internalStripNamespacePrefix( Const _1_t_tagName: string): string;
  Var
    _e_pos: int64;
  Begin
    _e_pos := Pos( ':', _1_t_tagName);
    If ( _e_pos > 0) Then Exit( Copy( _1_t_tagName, _e_pos + 1, MaxInt));
    Result := _1_t_tagName;
  End;

Function internalExtractTagContent( Const _1_t_xml, _2_t_tagName: string): string;
  Var
    _e_lt, _e_gt, _e_close, _e_scan: int64;
    _t_tag, _t_name: string;
  Begin
    Result := '';
    _e_scan := 1;
    While ( _e_scan <= Length( _1_t_xml)) Do Begin
      _e_lt := Pos( '<', Copy( _1_t_xml, _e_scan, MaxInt));
      If ( _e_lt <= 0) Then Exit;
      _e_lt := _e_lt + _e_scan - 1;

      If ( ( _e_lt < Length( _1_t_xml)) and ( _1_t_xml[_e_lt + 1] in ['/', '?', '!'])) Then Begin
        _e_scan := _e_lt + 1;
        Continue;
      End;

      _e_gt := Pos( '>', Copy( _1_t_xml, _e_lt + 1, MaxInt));
      If ( _e_gt <= 0) Then Exit;
      _e_gt := _e_gt + _e_lt;

      _t_tag := Trim( Copy( _1_t_xml, _e_lt + 1, _e_gt - _e_lt - 1));
      _t_name := _t_tag;
      If ( Pos( ' ', _t_name) > 0) Then _t_name := Copy( _t_name, 1, Pos( ' ', _t_name) - 1);
      _t_name := internalStripNamespacePrefix( _t_name);

      If ( SameText( _t_name, _2_t_tagName)) Then Begin
        _e_close := Pos( '</', Copy( _1_t_xml, _e_gt + 1, MaxInt));
        If ( _e_close <= 0) Then Exit;
        _e_close := _e_close + _e_gt;
        Exit( Copy( _1_t_xml, _e_gt + 1, _e_close - _e_gt - 1));
      End;

      _e_scan := _e_gt + 1;
    End;
  End;

Function internalExtractSOAPBody( Const _1_t_xml: string): string;
  Begin
    Result := internalExtractTagContent( _1_t_xml, 'Body');
  End;

Function internalExtractSOAPFaultText( Const _1_t_xml: string): string;
  Begin
    Result := internalExtractTagContent( _1_t_xml, 'faultstring');
    If ( Result = '') Then Result := internalExtractTagContent( _1_t_xml, 'Reason');
  End;

Function internalExtractSOAPFaultActor( Const _1_t_xml: string): string;
  Begin
    Result := internalExtractTagContent( _1_t_xml, 'faultactor');
    If ( Result = '') Then Result := internalExtractTagContent( _1_t_xml, 'Role');
  End;

Function internalExtractSOAPResult( Const _1_t_xml, _2_t_returnName: string): string;
  Var
    _t_body: string;
  Begin
    _t_body := internalExtractSOAPBody( _1_t_xml);
    If ( _t_body = '') Then Exit( '');

    If ( Trim( _2_t_returnName) <> '') Then Exit( internalExtractTagContent( _t_body, _2_t_returnName));

    Result := internalExtractTagContent( _t_body, 'return');
    If ( Result <> '') Then Exit;

    Result := internalExtractTagContent( _t_body, 'Result');
    If ( Result <> '') Then Exit;

    Result := Trim( _t_body);
  End;

Function internalBuildSOAPEnvelope( Const _1_t_methodName: string; Const _2_t_nameSpace: string): string;
  Var
    _e_i:    int64;
    _t_body: string;
    _t_soapTypeAttr: string;
  Begin
    _t_body := '<' + _1_t_methodName;
    If ( Trim( _2_t_nameSpace) <> '') Then _t_body += ' xmlns="' + internalXMLEscape( _2_t_nameSpace) + '"';
    _t_body += '>';

    For _e_i := 0 To High( gc_parameters) Do Begin
      _t_soapTypeAttr := '';
      If ( Trim( gc_parameters[_e_i].t_soapType) <> '') Then _t_soapTypeAttr := ' xsi:type="' + internalXMLEscape( gc_parameters[_e_i].t_soapType) + '"';

      _t_body += '<' + gc_parameters[_e_i].t_name + _t_soapTypeAttr + '>' + internalVariantToXMLText( gc_parameters[_e_i].v_value) + '</' + gc_parameters[_e_i].t_name + '>';
    End;

    _t_body += '</' + _1_t_methodName + '>';

    Result :=
      '<?xml version="1.0" encoding="UTF-8"?>' + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"' + ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
      '<soap:Body>' + _t_body + '</soap:Body></soap:Envelope>';
  End;

Function internalCreateClient( Const _1_t_accessURL: string): TFPHTTPClient;
  Var
    _y_uri:  TURI;
    _e_port: int64;
  Begin
    Result := TFPHTTPClient.Create( nil);
    Result.AllowRedirect := True;
    Result.RequestHeaders.Clear;
    Result.AddHeader( 'Content-Type', 'text/xml; charset=utf-8');

    If ( gy_transport.y_options.e_timeoutMs > 0) Then Result.IOTimeout := gy_transport.y_options.e_timeoutMs;

    If ( gy_authentication.e_authMethod = WEB_SERVICE_AUTH_BASIC) Then Begin
      Result.UserName := gy_authentication.t_name;
      Result.Password := gy_authentication.t_password;
    End;

    If ( gy_transport.y_proxy.b_enabled) Then Begin
      Result.Proxy.Host := gy_transport.y_proxy.t_host;

      //Result.Proxy.Port := IntToStr(gy_transport.y_proxy.e_port);
      If ( ( gy_transport.y_proxy.e_port < 0) or ( gy_transport.y_proxy.e_port > 65535)) Then q4interruptions.assertRaise(
          'q4webServicesClient.internalCreateClient',
          'Proxy port out of range'
          );

      Result.Proxy.Port := word( gy_transport.y_proxy.e_port);

      Result.Proxy.UserName := gy_transport.y_proxy.t_userName;
      Result.Proxy.Password := gy_transport.y_proxy.t_password;
    End;

    _y_uri := URIParser.ParseURI( _1_t_accessURL);
    _e_port := int64( _y_uri.Port);
    If ( _e_port = 0) Then _e_port := q4netCore.netCoreDetectDefaultPort( _y_uri.Protocol, SysUtils.SameText( _y_uri.Protocol, 'https'));

    If ( ( gy_transport.y_endpoint.t_host = '') and ( _y_uri.Host <> '')) Then q4netCore.netCoreConfigureEndpoint( gy_transport, _y_uri.Host, _e_port, _y_uri.Path);
  End;

Procedure webServiceAuthenticate( Const _1_t_name: string; Const _2_t_password: string; _3_e_authMethod: int64; Const _4_t_operator: string);
  Begin
    //https://developer.4d.com/docs/21/commands/web-service-authenticate
    gy_authentication.t_name := _1_t_name;
    gy_authentication.t_password := _2_t_password;
    gy_authentication.e_authMethod := _3_e_authMethod;
    gy_authentication.b_forProxy := internalIsStar( _4_t_operator);

    If ( _3_e_authMethod = WEB_SERVICE_AUTH_BASIC) Then q4netCore.netCoreSetCredentialsBasic( gy_transport.y_credentials, _1_t_name, _2_t_password);

    internalSetSuccess;
  End;

Procedure webServiceSetParameter( Const _1_t_name: string; Const _2_v_value: variant; Const _3_t_soapType: string);
  Var
    _y_parameter: Tq4WebServiceParameter;
  Begin
    //https://developer.4d.com/docs/21/commands/web-service-set-parameter
    _y_parameter.t_name := _1_t_name;
    _y_parameter.v_value := _2_v_value;
    _y_parameter.t_soapType := _3_t_soapType;
    internalAppendParameter( _y_parameter);
    internalSetSuccess;
  End;

Procedure webServiceSetOption( _1_e_option: int64; Const _2_v_value: variant);
  Var
    _y_option: Tq4WebServiceOption;
  Begin
    //https://developer.4d.com/docs/21/commands/web-service-set-option
    _y_option.e_option := _1_e_option;
    _y_option.v_value := _2_v_value;
    internalAppendOption( _y_option);

    If ( _1_e_option = WEB_SERVICE_OPTION_TIMEOUT) Then q4netCore.netCoreSetTimeout( gy_transport, integer( _2_v_value));

    internalSetSuccess;
  End;

Procedure webServiceCall( Const _1_t_accessURL: string; Const _2_t_soapAction: string; Const _3_t_methodName: string; Const _4_t_nameSpace: string;
  _5_e_complexType: int64; Const _6_t_operator: string);
  Var
    _o_client:     TFPHTTPClient;
    _o_request:    TStringStream;
    _o_response:   TStringStream;
    _t_envelope:   string;
    _t_bodyResult: string;
  Begin
    //https://developer.4d.com/docs/21/commands/web-service-call
    internalResetLastError;
    gv_lastResult := Null;
    gt_lastResultName := _3_t_methodName;
    gt_lastResponseXML := '';

    _t_envelope := internalBuildSOAPEnvelope( _3_t_methodName, _4_t_nameSpace);
    _o_client := internalCreateClient( _1_t_accessURL);
    _o_request := TStringStream.Create( _t_envelope);
    _o_response := TStringStream.Create( '');

    Try
      If ( Trim( _2_t_soapAction) <> '') Then _o_client.AddHeader( 'SOAPAction', '"' + _2_t_soapAction + '"');

      If ( internalIsStar( _6_t_operator)) Then _o_client.AddHeader( 'Connection', 'keep-alive')
      Else
        _o_client.AddHeader( 'Connection', 'close');

      _o_client.RequestBody := _o_request;
      _o_client.Post( _1_t_accessURL, _o_response);

      ge_lastHTTPStatusCode := _o_client.ResponseStatusCode;
      gy_lastError.e_httpStatusCode := ge_lastHTTPStatusCode;
      gt_lastResponseXML := _o_response.DataString;
      _t_bodyResult := internalExtractSOAPResult( gt_lastResponseXML, '');

      If ( ge_lastHTTPStatusCode >= 400) Then Begin
        gy_lastError.e_code := WEB_SERVICE_ERROR_INTERNAL_FAULT;
        gy_lastError.t_detailedMessage := internalExtractSOAPFaultText( gt_lastResponseXML);
        If ( gy_lastError.t_detailedMessage = '') Then gy_lastError.t_detailedMessage := 'HTTP error during SOAP call';
        gy_lastError.t_faultActor := internalExtractSOAPFaultActor( gt_lastResponseXML);
        internalSetFailure( gy_lastError.e_code);
        Exit;
      End;

      gv_lastResult := _t_bodyResult;
      gy_lastError.e_code := WEB_SERVICE_ERROR_NONE;
      gy_lastError.t_detailedMessage := '';
      gy_lastError.t_faultActor := '';
      internalSetSuccess;
    Except
      on o_error: Exception Do Begin
        ge_lastHTTPStatusCode := 0;
        gy_lastError.e_code := WEB_SERVICE_ERROR_INTERNAL_FAULT;
        gy_lastError.e_httpStatusCode := 0;
        gy_lastError.t_detailedMessage := o_error.Message;
        gy_lastError.t_faultActor := '';
        gt_lastResponseXML := '';
        gv_lastResult := Null;
        internalSetFailure( gy_lastError.e_code);
      End;
    End;

    _o_response.Free;
    _o_request.Free;
    _o_client.Free;
  End;

Function webServiceGetInfo( _1_e_infoType: int64): string;
  Begin
    //https://developer.4d.com/docs/21/commands/web-service-get-info
    Case _1_e_infoType Of
      WEB_SERVICE_INFO_DETAILED_MESSAGE: Result := gy_lastError.t_detailedMessage;
      WEB_SERVICE_INFO_HTTP_STATUS_CODE: Result := SysUtils.IntToStr( gy_lastError.e_httpStatusCode);
      WEB_SERVICE_INFO_FAULT_ACTOR: Result := gy_lastError.t_faultActor;
      WEB_SERVICE_INFO_ERROR_CODE: Result := SysUtils.IntToStr( gy_lastError.e_code);
      Else Result := '';
    End;
    internalSetSuccess;
  End;

Procedure webServiceGetResult( out _1_v_returnValue: variant; Const _2_t_returnName: string; Const _3_t_operator: string);
  Var
    _t_result: string;
  Begin
    //https://developer.4d.com/docs/21/commands/web-service-get-result
    If ( Trim( _2_t_returnName) <> '') Then _t_result := internalExtractSOAPResult( gt_lastResponseXML, _2_t_returnName)
    Else If ( not VarIsNull( gv_lastResult)) Then _t_result := VarToStr( gv_lastResult)
    Else
      _t_result := internalExtractSOAPResult( gt_lastResponseXML, '');

    _1_v_returnValue := _t_result;

    If ( internalIsStar( _3_t_operator)) Then Begin
      gv_lastResult := Null;
      gt_lastResultName := '';
      gt_lastResponseXML := '';
    End;

    internalSetSuccess;
  End;

Initialization
  gy_transport := q4netCore.netCoreNewTransportState;
  SetLength( gc_parameters, 0);
  SetLength( gc_options, 0);
  internalResetLastError;
  gv_lastResult := Null;
  gt_lastResultName := '';
  gt_lastResponseXML := '';

End.
