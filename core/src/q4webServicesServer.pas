unit q4webServicesServer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, q4coreLanguage;

const
  Q4_SOAP_INPUT        = 1;
  Q4_SOAP_OUTPUT       = 2;
  Q4_SOAP_METHOD_NAME  = 1;
  Q4_SOAP_SERVICE_NAME = 2;

type
  Tq4SoapDeclaration = record
    t_variableName: string;
    e_typeCode: Int64;
    e_inputOutput: Int64;
    t_alias: string;
  end;
  Tq4SoapDeclarationArray = array of Tq4SoapDeclaration;

function soapDeclaration(const _1_t_variableName: string; _2_e_typeCode: Int64; _3_e_inputOutput: Int64; const _4_t_alias: string = ''): Boolean;
function soapGetInfo(_1_e_infoNum: Int64): string;
procedure soapRejectNewRequests(_1_b_rejectStatus: Boolean);
function soapRequest: Boolean;
procedure soapSendFault(_1_e_faultType: Int64; const _2_t_description: string);

implementation

threadvar
  gb_rejectNewRequests: Boolean;
  gb_isSoapRequest: Boolean;
  gt_currentSoapMethodName: string;
  gt_currentSoapServiceName: string;
  gt_lastFaultDescription: string;
  ge_lastFaultType: Int64;
  gy_declarations: Tq4SoapDeclarationArray;

procedure q4wsMarkOK; begin q4coreLanguage.OK := 1; q4coreLanguage.Error := 0; end;
procedure q4wsMarkError; begin q4coreLanguage.OK := 0; end;

function q4wsNormalizeAlias(const _1_t_alias, _2_t_variableName: string): string;
begin
  if (Trim(_1_t_alias) <> '') then Exit(Trim(_1_t_alias));
  Result := Trim(_2_t_variableName);
end;

function q4wsIndexOfDeclaration(const _1_t_variableName, _2_t_alias: string): Int64;
var e_i: Int64;
begin
  for e_i := 0 to High(gy_declarations) do
  begin
    if (SameText(gy_declarations[e_i].t_variableName, _1_t_variableName)) then Exit(e_i);
    if ((_2_t_alias <> '') and SameText(gy_declarations[e_i].t_alias, _2_t_alias)) then Exit(e_i);
  end;
  Result := -1;
end;

function soapDeclaration(const _1_t_variableName: string; _2_e_typeCode: Int64; _3_e_inputOutput: Int64; const _4_t_alias: string): Boolean;
var e_index: Int64; y_item: Tq4SoapDeclaration;
begin
  //https://developer.4d.com/docs/21/commands/soap-declaration
  Result := False;
  if (Trim(_1_t_variableName) = '') then begin q4wsMarkError; Exit; end;
  y_item.t_variableName := Trim(_1_t_variableName);
  y_item.e_typeCode := _2_e_typeCode;
  y_item.e_inputOutput := _3_e_inputOutput;
  y_item.t_alias := q4wsNormalizeAlias(_4_t_alias, _1_t_variableName);
  e_index := q4wsIndexOfDeclaration(y_item.t_variableName, y_item.t_alias);
  if (e_index >= 0) then gy_declarations[e_index] := y_item
  else begin SetLength(gy_declarations, Length(gy_declarations)+1); gy_declarations[High(gy_declarations)] := y_item; end;
  q4wsMarkOK; Result := True;
end;

function soapGetInfo(_1_e_infoNum: Int64): string;
begin
  //https://developer.4d.com/docs/21/commands/soap-get-info
  case _1_e_infoNum of
    Q4_SOAP_METHOD_NAME: Result := gt_currentSoapMethodName;
    Q4_SOAP_SERVICE_NAME: Result := gt_currentSoapServiceName;
  else
    Result := '';
  end;
  q4wsMarkOK;
end;

procedure soapRejectNewRequests(_1_b_rejectStatus: Boolean);
begin
  //https://developer.4d.com/docs/21/commands/soap-reject-new-requests
  gb_rejectNewRequests := _1_b_rejectStatus;
  q4wsMarkOK;
end;

function soapRequest: Boolean;
begin
  //https://developer.4d.com/docs/21/commands/soap-request
  Result := gb_isSoapRequest and (not gb_rejectNewRequests);
  q4wsMarkOK;
end;

procedure soapSendFault(_1_e_faultType: Int64; const _2_t_description: string);
begin
  //https://developer.4d.com/docs/21/commands/soap-send-fault
  ge_lastFaultType := _1_e_faultType;
  gt_lastFaultDescription := _2_t_description;
  q4wsMarkOK;
end;

initialization
  gb_rejectNewRequests := False;
  gb_isSoapRequest := False;
  gt_currentSoapMethodName := '';
  gt_currentSoapServiceName := '';
  gt_lastFaultDescription := '';
  ge_lastFaultType := 0;
  SetLength(gy_declarations, 0);

end.
