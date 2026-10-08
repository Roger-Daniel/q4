unit q4messages;

{
q4messages
version du 2026/04/19-18:57

Mapping 4D → q4messages -> statut
Command Number 4D,    4D Command,                      q4 API,                           Statut
------------------------------------------------------------------------------------------------
41,                  ALERT,                            alert,                            OK,
162,                 CONFIRM,                          confirm,                          OK,
910,                 DISPLAY NOTIFICATION,             displayNotification,              OK,
161,                 GOTO XY,                          gotoXY,                           OK,
88,                  MESSAGE,                          message,                          OK,
175,                 MESSAGES OFF,                     messagesOff,                      OK,
181,                 MESSAGES ON,                      messagesOn,                       OK,
163,                 Request,                          request,                          OK,

Doc: https://developer.4d.com/docs/21/commands/theme/Messages
}

{$mode objfpc}{$H+}

interface

threadvar
  OK: Int64;

procedure alert(const _1_t_message: string);
function confirm(const _1_t_message: string): Boolean;
procedure displayNotification(const _1_t_title: string; const _2_t_message: string);
procedure gotoXY(const _1_e_x: Int64; const _2_e_y: Int64);
procedure message(const _1_t_message: string);
procedure messagesOff;
procedure messagesOn;
function request(const _1_t_prompt: string; var _2_t_value: string): Boolean;

implementation

uses
  SysUtils;

threadvar
  b_messagesEnabled: Boolean;
  e_cursorX: Int64;
  e_cursorY: Int64;

procedure InternalAlert(const _1_t_message: string);
begin
  System.WriteLn('[ALERT] ', _1_t_message);
end;

function InternalConfirm(const _1_t_message: string): Boolean;
begin
  System.WriteLn('[CONFIRM] ', _1_t_message);
  OK := 1;
  Result := True;
end;

procedure InternalDisplayNotification(const _1_t_title: string; const _2_t_message: string);
begin
  System.WriteLn('[NOTIFICATION] ', _1_t_title, ' - ', _2_t_message);
end;

procedure InternalGotoXY(const _1_e_x: Int64; const _2_e_y: Int64);
begin
  e_cursorX := _1_e_x;
  e_cursorY := _2_e_y;
end;

procedure InternalMessage(const _1_t_message: string);
begin
  if (not b_messagesEnabled) then
  begin
    Exit;
  end;

  System.WriteLn('[MESSAGE ', e_cursorX, ',', e_cursorY, '] ', _1_t_message);
end;

procedure InternalMessagesOff;
begin
  b_messagesEnabled := False;
end;

procedure InternalMessagesOn;
begin
  b_messagesEnabled := True;
end;

function InternalRequest(const _1_t_prompt: string; var _2_t_value: string): Boolean;
begin
  System.WriteLn('[REQUEST] ', _1_t_prompt);
  _2_t_value := '';
  OK := 1;
  Result := True;
end;

procedure alert(const _1_t_message: string);
begin
  //https://developer.4d.com/docs/21/commands/alert
  q4messages.InternalAlert(_1_t_message);
end;

function confirm(const _1_t_message: string): Boolean;
begin
  //https://developer.4d.com/docs/21/commands/confirm
  Result := q4messages.InternalConfirm(_1_t_message);
end;

procedure displayNotification(const _1_t_title: string; const _2_t_message: string);
begin
  //https://developer.4d.com/docs/21/commands/display-notification
  q4messages.InternalDisplayNotification(_1_t_title, _2_t_message);
end;

procedure gotoXY(const _1_e_x: Int64; const _2_e_y: Int64);
begin
  //https://developer.4d.com/docs/21/commands/goto-xy
  q4messages.InternalGotoXY(_1_e_x, _2_e_y);
end;

procedure message(const _1_t_message: string);
begin
  //https://developer.4d.com/docs/21/commands/message
  q4messages.InternalMessage(_1_t_message);
end;

procedure messagesOff;
begin
  //https://developer.4d.com/docs/21/commands/messages-off
  q4messages.InternalMessagesOff;
end;

procedure messagesOn;
begin
  //https://developer.4d.com/docs/21/commands/messages-on
  q4messages.InternalMessagesOn;
end;

function request(const _1_t_prompt: string; var _2_t_value: string): Boolean;
begin
  //https://developer.4d.com/docs/21/commands/request
  Result := q4messages.InternalRequest(_1_t_prompt, _2_t_value);
end;

initialization
  b_messagesEnabled := True;
  e_cursorX := 0;
  e_cursorY := 0;
  OK := 0;

end.

