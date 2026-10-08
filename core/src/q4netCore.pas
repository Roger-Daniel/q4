unit q4netCore;

{$mode objfpc}{$H+}

{
Unité interne q4
- Cette unité n’émule pas directement un thème 4D.
- Elle fournit des briques réseau communes pour q4mail, q4http, q4webServer et q4webServicesClient.
- L’API publique des thèmes 4D doit rester dans leurs unités respectives.

Notes d’implémentation
- Cette unité centralise la description des connexions, options réseau et authentifications.
- Elle reste indépendante de Synapse dans son interface publique.
- Les moteurs réseau concrets seront branchés plus tard dans les unités thème ou dans une couche d’adaptation dédiée.
}

interface

uses
  Classes, SysUtils;

const
  Q4_NET_DEFAULT_TIMEOUT_MS = 30000;

  Q4_NET_AUTH_NONE   = 0;
  Q4_NET_AUTH_BASIC  = 1;
  Q4_NET_AUTH_LOGIN  = 2;
  Q4_NET_AUTH_BEARER = 3;

type
  Tq4NetAuthKind = (
    nakNone,
    nakBasic,
    nakLogin,
    nakBearer
  );

  Tq4NetSecurityMode = (
    nsmNone,
    nsmSSL,
    nsmTLS,
    nsmStartTLS
  );

  Tq4NetEndpoint = record
    t_host: string;
    e_port: Int64;
    t_path: string;
    b_enabled: Boolean;
  end;

  Tq4NetCredentials = record
    e_authKind: Int64;
    t_userName: string;
    t_password: string;
    t_token: string;
  end;

  Tq4NetProxySettings = record
    b_enabled: Boolean;
    t_host: string;
    e_port: Int64;
    t_userName: string;
    t_password: string;
  end;

  Tq4NetConnectionOptions = record
    e_timeoutMs: Int64;
    e_securityMode: Int64;
    b_keepAlive: Boolean;
    b_verifyCertificate: Boolean;
    b_followRedirects: Boolean;
    b_compress: Boolean;
  end;

  Tq4NetTransportState = record
    e_id: Int64;
    t_name: string;
    y_endpoint: Tq4NetEndpoint;
    y_credentials: Tq4NetCredentials;
    y_proxy: Tq4NetProxySettings;
    y_options: Tq4NetConnectionOptions;
    b_isConfigured: Boolean;
    b_isConnected: Boolean;
    t_lastError: string;
    e_lastErrorCode: Int64;
  end;

function netCoreNewEndpoint(
  const _1_t_host: string;
  _2_e_port: Int64;
  const _3_t_path: string = ''
): Tq4NetEndpoint;

function netCoreNewCredentials: Tq4NetCredentials;
function netCoreNewProxySettings: Tq4NetProxySettings;
function netCoreNewConnectionOptions: Tq4NetConnectionOptions;
function netCoreNewTransportState: Tq4NetTransportState;

function netCoreNormalizeHost(
  const _1_t_host: string
): string;

function netCoreNormalizePath(
  const _1_t_path: string
): string;

function netCoreIsValidPort(
  _1_e_port: Integer
): Boolean;

function netCoreDetectDefaultPort(
  const _1_t_scheme: string;
  _2_b_ssl: Boolean = False
): Int64;

function netCoreAuthKindFromInteger(
  _1_e_authKind: Integer
): Tq4NetAuthKind;

function netCoreAuthKindToInteger(
  _1_e_authKind: Tq4NetAuthKind
): Int64;

function netCoreSecurityModeFromSSLFlag(
  _1_b_ssl: Boolean
): Int64;

function netCoreSetCredentialsBasic(
  var _1_y_credentials: Tq4NetCredentials;
  const _2_t_userName: string;
  const _3_t_password: string
): Boolean;

function netCoreSetCredentialsBearer(
  var _1_y_credentials: Tq4NetCredentials;
  const _2_t_token: string
): Boolean;

function netCoreClearCredentials(
  var _1_y_credentials: Tq4NetCredentials
): Boolean;

function netCoreApplyProxy(
  var _1_y_transport: Tq4NetTransportState;
  const _2_t_host: string;
  _3_e_port: Int64;
  const _4_t_userName: string = '';
  const _5_t_password: string = ''
): Boolean;

function netCoreClearProxy(
  var _1_y_transport: Tq4NetTransportState
): Boolean;

function netCoreConfigureEndpoint(
  var _1_y_transport: Tq4NetTransportState;
  const _2_t_host: string;
  _3_e_port: Int64;
  const _4_t_path: string = ''
): Boolean;

function netCoreSetTimeout(
  var _1_y_transport: Tq4NetTransportState;
  _2_e_timeoutMs: Integer
): Boolean;

function netCoreMarkConnected(
  var _1_y_transport: Tq4NetTransportState
): Boolean;

function netCoreMarkDisconnected(
  var _1_y_transport: Tq4NetTransportState
): Boolean;

function netCoreSetLastError(
  var _1_y_transport: Tq4NetTransportState;
  _2_e_errorCode: Int64;
  const _3_t_errorMessage: string
): Boolean;

function netCoreClearLastError(
  var _1_y_transport: Tq4NetTransportState
): Boolean;

implementation

function netCoreNewEndpoint(
  const _1_t_host: string;
  _2_e_port: Int64;
  const _3_t_path: string
): Tq4NetEndpoint;
begin
  Result.t_host := netCoreNormalizeHost(_1_t_host);
  Result.e_port := _2_e_port;
  Result.t_path := netCoreNormalizePath(_3_t_path);
  Result.b_enabled := Result.t_host <> '';
end;

function netCoreNewCredentials: Tq4NetCredentials;
begin
  Result.e_authKind := Q4_NET_AUTH_NONE;
  Result.t_userName := '';
  Result.t_password := '';
  Result.t_token := '';
end;

function netCoreNewProxySettings: Tq4NetProxySettings;
begin
  Result.b_enabled := False;
  Result.t_host := '';
  Result.e_port := 0;
  Result.t_userName := '';
  Result.t_password := '';
end;

function netCoreNewConnectionOptions: Tq4NetConnectionOptions;
begin
  Result.e_timeoutMs := Q4_NET_DEFAULT_TIMEOUT_MS;
  Result.e_securityMode := Integer(nsmNone);
  Result.b_keepAlive := True;
  Result.b_verifyCertificate := True;
  Result.b_followRedirects := True;
  Result.b_compress := True;
end;

function netCoreNewTransportState: Tq4NetTransportState;
begin
  Result.e_id := 0;
  Result.t_name := '';
  Result.y_endpoint := netCoreNewEndpoint('', 0, '');
  Result.y_credentials := netCoreNewCredentials;
  Result.y_proxy := netCoreNewProxySettings;
  Result.y_options := netCoreNewConnectionOptions;
  Result.b_isConfigured := False;
  Result.b_isConnected := False;
  Result.t_lastError := '';
  Result.e_lastErrorCode := 0;
end;

function netCoreNormalizeHost(
  const _1_t_host: string
): string;
begin
  Result := SysUtils.Trim(_1_t_host);
end;

function netCoreNormalizePath(
  const _1_t_path: string
): string;
begin
  Result := SysUtils.Trim(_1_t_path);

  if (Result = '') then
    Exit('');

  if (Result[1] <> '/') then
    Result := '/' + Result;
end;

function netCoreIsValidPort(
  _1_e_port: Integer
): Boolean;
begin
  Result := (_1_e_port >= 1) and (_1_e_port <= 65535);
end;

function netCoreDetectDefaultPort(
  const _1_t_scheme: string;
  _2_b_ssl: Boolean
): Int64;
var
  _t_scheme: string;
begin
  _t_scheme := SysUtils.LowerCase(SysUtils.Trim(_1_t_scheme));

  if (_t_scheme = 'http') then
  begin
    if (_2_b_ssl) then Exit(443);
    Exit(80);
  end;

  if (_t_scheme = 'https') then Exit(443);
  if (_t_scheme = 'smtp') then
  begin
    if (_2_b_ssl) then Exit(465);
    Exit(587);
  end;
  if (_t_scheme = 'pop3') then
  begin
    if (_2_b_ssl) then Exit(995);
    Exit(110);
  end;
  if (_t_scheme = 'imap') then
  begin
    if (_2_b_ssl) then Exit(993);
    Exit(143);
  end;

  Result := 0;
end;

function netCoreAuthKindFromInteger(
  _1_e_authKind: Integer
): Tq4NetAuthKind;
begin
  case _1_e_authKind of
    Q4_NET_AUTH_BASIC:  Result := nakBasic;
    Q4_NET_AUTH_LOGIN:  Result := nakLogin;
    Q4_NET_AUTH_BEARER: Result := nakBearer;
  else
    Result := nakNone;
  end;
end;

function netCoreAuthKindToInteger(
  _1_e_authKind: Tq4NetAuthKind
): Int64;
begin
  case _1_e_authKind of
    nakBasic:  Result := Q4_NET_AUTH_BASIC;
    nakLogin:  Result := Q4_NET_AUTH_LOGIN;
    nakBearer: Result := Q4_NET_AUTH_BEARER;
  else
    Result := Q4_NET_AUTH_NONE;
  end;
end;

function netCoreSecurityModeFromSSLFlag(
  _1_b_ssl: Boolean
): Int64;
begin
  if (_1_b_ssl) then
    Exit(Integer(nsmSSL));

  Result := Integer(nsmNone);
end;

function netCoreSetCredentialsBasic(
  var _1_y_credentials: Tq4NetCredentials;
  const _2_t_userName: string;
  const _3_t_password: string
): Boolean;
begin
  _1_y_credentials.e_authKind := Q4_NET_AUTH_BASIC;
  _1_y_credentials.t_userName := _2_t_userName;
  _1_y_credentials.t_password := _3_t_password;
  _1_y_credentials.t_token := '';
  Result := True;
end;

function netCoreSetCredentialsBearer(
  var _1_y_credentials: Tq4NetCredentials;
  const _2_t_token: string
): Boolean;
begin
  _1_y_credentials.e_authKind := Q4_NET_AUTH_BEARER;
  _1_y_credentials.t_userName := '';
  _1_y_credentials.t_password := '';
  _1_y_credentials.t_token := _2_t_token;
  Result := True;
end;

function netCoreClearCredentials(
  var _1_y_credentials: Tq4NetCredentials
): Boolean;
begin
  _1_y_credentials := netCoreNewCredentials;
  Result := True;
end;

function netCoreApplyProxy(
  var _1_y_transport: Tq4NetTransportState;
  const _2_t_host: string;
  _3_e_port: Int64;
  const _4_t_userName: string;
  const _5_t_password: string
): Boolean;
begin
  if (not netCoreIsValidPort(_3_e_port)) then
    Exit(False);

  _1_y_transport.y_proxy.b_enabled := True;
  _1_y_transport.y_proxy.t_host := netCoreNormalizeHost(_2_t_host);
  _1_y_transport.y_proxy.e_port := _3_e_port;
  _1_y_transport.y_proxy.t_userName := _4_t_userName;
  _1_y_transport.y_proxy.t_password := _5_t_password;
  Result := _1_y_transport.y_proxy.t_host <> '';
end;

function netCoreClearProxy(
  var _1_y_transport: Tq4NetTransportState
): Boolean;
begin
  _1_y_transport.y_proxy := netCoreNewProxySettings;
  Result := True;
end;

function netCoreConfigureEndpoint(
  var _1_y_transport: Tq4NetTransportState;
  const _2_t_host: string;
  _3_e_port: Int64;
  const _4_t_path: string
): Boolean;
begin
  if (not netCoreIsValidPort(_3_e_port)) then
    Exit(False);

  _1_y_transport.y_endpoint := netCoreNewEndpoint(_2_t_host, _3_e_port, _4_t_path);
  _1_y_transport.b_isConfigured := _1_y_transport.y_endpoint.b_enabled and netCoreIsValidPort(_1_y_transport.y_endpoint.e_port);
  Result := _1_y_transport.b_isConfigured;
end;

function netCoreSetTimeout(
  var _1_y_transport: Tq4NetTransportState;
  _2_e_timeoutMs: Integer
): Boolean;
begin
  if (_2_e_timeoutMs <= 0) then
    Exit(False);

  _1_y_transport.y_options.e_timeoutMs := _2_e_timeoutMs;
  Result := True;
end;

function netCoreMarkConnected(
  var _1_y_transport: Tq4NetTransportState
): Boolean;
begin
  if (not _1_y_transport.b_isConfigured) then
    Exit(False);

  _1_y_transport.b_isConnected := True;
  Result := True;
end;

function netCoreMarkDisconnected(
  var _1_y_transport: Tq4NetTransportState
): Boolean;
begin
  _1_y_transport.b_isConnected := False;
  Result := True;
end;

function netCoreSetLastError(
  var _1_y_transport: Tq4NetTransportState;
  _2_e_errorCode: Int64;
  const _3_t_errorMessage: string
): Boolean;
begin
  _1_y_transport.e_lastErrorCode := _2_e_errorCode;
  _1_y_transport.t_lastError := _3_t_errorMessage;
  Result := True;
end;

function netCoreClearLastError(
  var _1_y_transport: Tq4NetTransportState
): Boolean;
begin
  _1_y_transport.e_lastErrorCode := 0;
  _1_y_transport.t_lastError := '';
  Result := True;
end;

end.
