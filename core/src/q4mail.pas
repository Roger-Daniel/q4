unit q4mail;

{$mode objfpc}{$H+}

{
q4mail
version du 2026/05/14

Mapping 4D → q4mail -> statut
Command Number 4D,    4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
1723,                 IMAP New transporter,             imapNewTransporter,               OK spécifique,
1681,                 MAIL Convert from MIME,           mailConvertFromMIME,              OK spécifique,
1604,                 MAIL Convert to MIME,             mailConvertToMIME,                OK spécifique,
1644,                 MAIL New attachment,              mailNewAttachment,                OK,
1697,                 POP3 New transporter,             pop3NewTransporter,               OK spécifique,
1608,                 SMTP New transporter,             smtpNewTransporter,               OK spécifique,

Doc: https://developer.4d.com/docs/21/commands/theme/Mail
Notes d'implémentation
- Cette unité expose une façade q4 stable pour le thème 4D Mail.
- Elle s'appuie sur q4mimeCore et q4netCore.
- Le parsing MIME reste volontairement pragmatique : text/plain, text/html, multipart/* et pièces jointes de base sont gérés.
}

interface

uses
  Classes, SysUtils, q4coreLanguage, q4mimeCore, q4netCore;

const
  MAIL_DISPOSITION_ATTACHMENT = 'attachment';

type
  Tq4File = record
    t_path: string;
  end;

  Tq4ZipFile = record
    t_path: string;
  end;

  Tq4MailTransporterKind = (mtikSMTP, mtikPOP3, mtikIMAP);

  Tq4MailAttachment = q4mimeCore.Tq4MimeAttachment;

  Tq4MailTransporter = record
    e_id: Int64;
    e_kind: Tq4MailTransporterKind;
    t_serverJson: string;
    y_transport: Tq4NetTransportState;
    t_authenticationMode: string;
    t_accessTokenOAuth2: string;
    t_logFile: string;
    t_headerCharset: string;
    t_bodyCharset: string;
    e_sendTimeOut: Int64;
    e_checkConnectionDelay: Int64;
    b_acceptUnsecureConnection: Boolean;
    b_keepAlive: Boolean;
    b_isValid: Boolean;
  end;

function imapNewTransporter(const _1_t_serverJson: string): Tq4MailTransporter;
function pop3NewTransporter(const _1_t_serverJson: string): Tq4MailTransporter;
function smtpNewTransporter(const _1_t_serverJson: string): Tq4MailTransporter;

function mailConvertFromMIME(const _1_y_mimeSource: TBytes): string; overload;
function mailConvertFromMIME(const _1_t_mimeSource: string): string; overload;
function mailConvertToMIME(const _1_t_mailObjectJson: string; const _2_t_optionsJson: string = ''): string;

function mailNewAttachment(
  const _1_y_blob: TBytes;
  const _2_t_name: string = '';
  const _3_t_cid: string = '';
  const _4_t_type: string = '';
  const _5_t_disposition: string = ''
): Tq4MailAttachment; overload;

function mailNewAttachment(
  const _1_t_path: string;
  const _2_t_name: string = '';
  const _3_t_cid: string = '';
  const _4_t_type: string = '';
  const _5_t_disposition: string = ''
): Tq4MailAttachment; overload;

function mailNewAttachment(
  const _1_y_file: Tq4File;
  const _2_t_name: string = '';
  const _3_t_cid: string = '';
  const _4_t_type: string = '';
  const _5_t_disposition: string = ''
): Tq4MailAttachment; overload;

function mailNewAttachment(
  const _1_y_zipFile: Tq4ZipFile;
  const _2_t_name: string = '';
  const _3_t_cid: string = '';
  const _4_t_type: string = '';
  const _5_t_disposition: string = ''
): Tq4MailAttachment; overload;

implementation

type
  Tq4JSONObjectRange = record
    e_startPos: Int64;
    e_endPos: Int64;
  end;

var
  ge_nextTransporterID: Int64 = 0;

procedure internalSetSuccess;
begin
  q4coreLanguage.OK := 1;
  q4coreLanguage.Error := 0;
end;

procedure internalSetFailure(const _1_e_error: Int64);
begin
  q4coreLanguage.OK := 0;
  q4coreLanguage.Error := _1_e_error;
end;

function internalJSONEscape(const _1_t_value: string): string;
var
  _e_i: Int64;
  _t_char: Char;
begin
  Result := '';
  for _e_i := 1 to Length(_1_t_value) do
  begin
    _t_char := _1_t_value[_e_i];
    case _t_char of
      '\': Result += '\\';
      '"': Result += '\"';
      #8: Result += '\b';
      #9: Result += '\t';
      #10: Result += '\n';
      #13: Result += '\r';
      #12: Result += '\f';
    else
      Result += _t_char;
    end;
  end;
end;

function internalJSONUnescape(const _1_t_value: string): string;
var
  _e_i: Int64;
begin
  Result := '';
  _e_i := 1;
  while (_e_i <= Length(_1_t_value)) do
  begin
    if ((_1_t_value[_e_i] = '\') and (_e_i < Length(_1_t_value))) then
    begin
      Inc(_e_i);
      case _1_t_value[_e_i] of
        'n': Result += #10;
        'r': Result += #13;
        't': Result += #9;
        'b': Result += #8;
        'f': Result += #12;
        '"': Result += '"';
        '\': Result += '\';
        '/': Result += '/';
      else
        Result += _1_t_value[_e_i];
    end;
    end
    else
      Result += _1_t_value[_e_i];
    Inc(_e_i);
  end;
end;

function internalExtractJSONValue(const _1_t_json, _2_t_name: string): string;
var
  _t_search: string;
  _e_p, _e_colon, _e_q1, _e_q2, _e_n: Int64;
  _t_work: string;
begin
  Result := '';
  _t_search := '"' + _2_t_name + '"';
  _e_p := Pos(_t_search, _1_t_json);
  if (_e_p <= 0) then Exit;
  _t_work := Copy(_1_t_json, _e_p + Length(_t_search), MaxInt);
  _e_colon := Pos(':', _t_work);
  if (_e_colon <= 0) then Exit;
  _t_work := Trim(Copy(_t_work, _e_colon + 1, MaxInt));

  if ((_t_work <> '') and (_t_work[1] = '"')) then
  begin
    _e_q1 := 1;
    _e_q2 := 2;
    while (_e_q2 <= Length(_t_work)) do
    begin
      if ((_t_work[_e_q2] = '"') and (_t_work[_e_q2 - 1] <> '\')) then
        Break;
      Inc(_e_q2);
    end;
    Exit(internalJSONUnescape(Copy(_t_work, _e_q1 + 1, _e_q2 - _e_q1 - 1)));
  end;

  _e_n := 1;
  while ((_e_n <= Length(_t_work)) and not (_t_work[_e_n] in [',', '}', ']'])) do
    Inc(_e_n);
  Result := Trim(Copy(_t_work, 1, _e_n - 1));
end;

function internalExtractJSONBlock(const _1_t_json, _2_t_name: string; _3_c_open, _4_c_close: Char): string;
var
  _t_search: string;
  _e_p, _e_colon, _e_i, _e_level: Int64;
begin
  Result := '';
  _t_search := '"' + _2_t_name + '"';
  _e_p := Pos(_t_search, _1_t_json);
  if (_e_p <= 0) then Exit;
  _e_colon := Pos(':', Copy(_1_t_json, _e_p + Length(_t_search), MaxInt));
  if (_e_colon <= 0) then Exit;
  _e_colon := _e_p + Length(_t_search) + _e_colon - 1;
  _e_i := _e_colon + 1;
  while ((_e_i <= Length(_1_t_json)) and (_1_t_json[_e_i] <= ' ')) do Inc(_e_i);
  if ((_e_i > Length(_1_t_json)) or (_1_t_json[_e_i] <> _3_c_open)) then Exit;

  _e_level := 0;
  repeat
    if (_1_t_json[_e_i] = _3_c_open) then Inc(_e_level)
    else if (_1_t_json[_e_i] = _4_c_close) then Dec(_e_level);
    Inc(_e_i);
  until ((_e_i > Length(_1_t_json)) or (_e_level = 0));

  if (_e_level = 0) then
    Result := Copy(_1_t_json, _e_colon + 1, _e_i - _e_colon - 1);
end;

function internalFindNextJSONObject(const _1_t_json: string; _2_e_fromPos: Int64): Tq4JSONObjectRange;
var
  _e_i, _e_level: Int64;
begin
  Result.e_startPos := 0;
  Result.e_endPos := 0;

  _e_i := _2_e_fromPos;
  while ((_e_i <= Length(_1_t_json)) and (_1_t_json[_e_i] <> '{')) do Inc(_e_i);
  if (_e_i > Length(_1_t_json)) then Exit;

  Result.e_startPos := _e_i;
  _e_level := 0;
  while (_e_i <= Length(_1_t_json)) do
  begin
    if (_1_t_json[_e_i] = '{') then Inc(_e_level)
    else if (_1_t_json[_e_i] = '}') then
    begin
      Dec(_e_level);
      if (_e_level = 0) then
      begin
        Result.e_endPos := _e_i;
        Exit;
      end;
    end;
    Inc(_e_i);
  end;

  Result.e_startPos := 0;
end;

function internalCreateTransporter(const _1_t_serverJson: string; _2_e_kind: Tq4MailTransporterKind): Tq4MailTransporter;
var
  _t_host, _t_user, _t_password, _t_ssl: string;
  _e_port: Int64;
begin
  Inc(ge_nextTransporterID);
  Result.e_id := ge_nextTransporterID;
  Result.e_kind := _2_e_kind;
  Result.t_serverJson := _1_t_serverJson;
  Result.y_transport := q4netCore.netCoreNewTransportState;
  Result.y_transport.e_id := ge_nextTransporterID;
  Result.y_transport.t_name := 'mail';
  Result.t_authenticationMode := '';
  Result.t_accessTokenOAuth2 := '';
  Result.t_logFile := '';
  Result.t_headerCharset := 'UTF-8';
  Result.t_bodyCharset := 'UTF-8';
  Result.e_sendTimeOut := 30000;
  Result.e_checkConnectionDelay := 0;
  Result.b_acceptUnsecureConnection := False;
  Result.b_keepAlive := True;

  _t_host := internalExtractJSONValue(_1_t_serverJson, 'host');
  _t_user := internalExtractJSONValue(_1_t_serverJson, 'user');
  _t_password := internalExtractJSONValue(_1_t_serverJson, 'password');
  _t_ssl := LowerCase(internalExtractJSONValue(_1_t_serverJson, 'ssl'));
  _e_port := StrToIntDef(internalExtractJSONValue(_1_t_serverJson, 'port'), 0);

  if (_e_port = 0) then
  begin
    case _2_e_kind of
      mtikIMAP: _e_port := q4netCore.netCoreDetectDefaultPort('imap', _t_ssl = 'true');
      mtikPOP3: _e_port := q4netCore.netCoreDetectDefaultPort('pop3', _t_ssl = 'true');
    else
      _e_port := q4netCore.netCoreDetectDefaultPort('smtp', _t_ssl = 'true');
    end;
  end;

  Result.y_transport.y_options.e_securityMode := q4netCore.netCoreSecurityModeFromSSLFlag(_t_ssl = 'true');
  Result.y_transport.y_options.e_timeoutMs := 30000;
  Result.y_transport.y_options.b_keepAlive := True;
  Result.b_keepAlive := True;
  Result.b_isValid := q4netCore.netCoreConfigureEndpoint(Result.y_transport, _t_host, _e_port, '');
  if (_t_user <> '') then
    q4netCore.netCoreSetCredentialsBasic(Result.y_transport.y_credentials, _t_user, _t_password);
end;

function imapNewTransporter(const _1_t_serverJson: string): Tq4MailTransporter;
begin
  //https://developer.4d.com/docs/21/commands/imap-new-transporter
  Result := internalCreateTransporter(_1_t_serverJson, mtikIMAP);
  if (Result.b_isValid) then internalSetSuccess else internalSetFailure(1723);
end;

function pop3NewTransporter(const _1_t_serverJson: string): Tq4MailTransporter;
begin
  //https://developer.4d.com/docs/21/commands/pop3-new-transporter
  Result := internalCreateTransporter(_1_t_serverJson, mtikPOP3);
  if (Result.b_isValid) then internalSetSuccess else internalSetFailure(1697);
end;

function smtpNewTransporter(const _1_t_serverJson: string): Tq4MailTransporter;
begin
  //https://developer.4d.com/docs/21/commands/smtp-new-transporter
  Result := internalCreateTransporter(_1_t_serverJson, mtikSMTP);
  if (Result.b_isValid) then internalSetSuccess else internalSetFailure(1608);
end;

function internalNormalizeLineBreaks(const _1_t_value: string): string;
begin
  Result := StringReplace(_1_t_value, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
end;

function internalSplitHeadersAndBody(const _1_t_source: string; out _2_t_headers, _3_t_body: string): Boolean;
var
  _e_pos: Int64;
begin
  _2_t_headers := '';
  _3_t_body := '';

  _e_pos := Pos(#13#10#13#10, _1_t_source);
  if (_e_pos > 0) then
  begin
    _2_t_headers := Copy(_1_t_source, 1, _e_pos - 1);
    _3_t_body := Copy(_1_t_source, _e_pos + 4, MaxInt);
    Exit(True);
  end;

  _e_pos := Pos(#10#10, internalNormalizeLineBreaks(_1_t_source));
  if (_e_pos > 0) then
  begin
    _2_t_headers := Copy(internalNormalizeLineBreaks(_1_t_source), 1, _e_pos - 1);
    _3_t_body := Copy(internalNormalizeLineBreaks(_1_t_source), _e_pos + 2, MaxInt);
    Exit(True);
  end;

  _3_t_body := _1_t_source;
  Result := False;
end;

function internalParseHeaders(const _1_t_headersText: string): Tq4MimeHeaderArray;
var
  _o_lines: TStringList;
  _e_i, _e_sep: Int64;
  _t_line, _t_name, _t_value: string;
begin
  SetLength(Result, 0);
  _o_lines := TStringList.Create;
  try
    _o_lines.Text := StringReplace(internalNormalizeLineBreaks(_1_t_headersText), #10, sLineBreak, [rfReplaceAll]);
    for _e_i := 0 to _o_lines.Count - 1 do
    begin
      _t_line := _o_lines[_e_i];
      if (Trim(_t_line) = '') then
        Continue;
      _e_sep := Pos(':', _t_line);
      if (_e_sep <= 0) then
        Continue;
      _t_name := Trim(Copy(_t_line, 1, _e_sep - 1));
      _t_value := Trim(Copy(_t_line, _e_sep + 1, MaxInt));
      q4mimeCore.mimeAddHeader(Result, q4mimeCore.mimeNewHeader(_t_name, _t_value));
    end;
  finally
    _o_lines.Free;
  end;
end;

function internalSplitMultipart(const _1_t_body, _2_t_boundary: string): Tq4TextArray;
var
  _t_work, _t_marker, _t_finalMarker: string;
  _e_posStart, _e_posEnd: Int64;
  _t_chunk: string;
begin
  SetLength(Result, 0);
  if (_2_t_boundary = '') then Exit;

  _t_work := internalNormalizeLineBreaks(_1_t_body);
  _t_marker := '--' + _2_t_boundary;
  _t_finalMarker := _t_marker + '--';

  _e_posStart := Pos(_t_marker, _t_work);
  while (_e_posStart > 0) do
  begin
    Delete(_t_work, 1, _e_posStart + Length(_t_marker) - 1);
    if (Copy(_t_work, 1, 2) = '--') then Break;
    if (Copy(_t_work, 1, 1) = #10) then Delete(_t_work, 1, 1);

    _e_posEnd := Pos(#10 + _t_marker, _t_work);
    if (_e_posEnd <= 0) then
      _e_posEnd := Pos(_t_finalMarker, _t_work);

    if (_e_posEnd > 0) then
      _t_chunk := Trim(Copy(_t_work, 1, _e_posEnd - 1))
    else
      _t_chunk := Trim(_t_work);

    if (_t_chunk <> '') then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := _t_chunk;
    end;

    if (_e_posEnd <= 0) then Break;
    Delete(_t_work, 1, _e_posEnd);
    _e_posStart := Pos(_t_marker, _t_work);
  end;
end;

function internalHeaderValue(const _1_ty_headers: Tq4MimeHeaderArray; const _2_t_name: string): string;
begin
  Result := q4mimeCore.mimeGetHeaderValue(_1_ty_headers, _2_t_name);
end;

function internalDecodeBody(const _1_t_body, _2_t_transferEncoding: string): TBytes;
begin
  if (SameText(Trim(_2_t_transferEncoding), 'base64')) then
    Exit(q4mimeCore.mimeDecodeBase64(StringReplace(Trim(_1_t_body), #10, '', [rfReplaceAll])));

  Result := q4mimeCore.mimeStringToBytesUTF8(_1_t_body);
end;

procedure internalParseMimePart(const _1_t_rawPart: string; var _2_y_message: Tq4MimeMessage);
var
  _t_headersText, _t_body, _t_contentType, _t_disposition, _t_transferEncoding: string;
  _y_part: Tq4MimePart;
  _y_attachment: Tq4MimeAttachment;
  _y_decoded: TBytes;
begin
  internalSplitHeadersAndBody(_1_t_rawPart, _t_headersText, _t_body);
  _y_part := q4mimeCore.mimeNewPart;
  _y_part.ty_headers := internalParseHeaders(_t_headersText);
  _y_part.t_contentType := internalHeaderValue(_y_part.ty_headers, 'Content-Type');
  _y_part.t_contentDisposition := internalHeaderValue(_y_part.ty_headers, 'Content-Disposition');
  _y_part.t_name := q4mimeCore.mimeExtractParameter(_y_part.t_contentDisposition, 'name');
  _y_part.t_fileName := q4mimeCore.mimeExtractParameter(_y_part.t_contentDisposition, 'filename');
  _y_part.t_contentID := internalHeaderValue(_y_part.ty_headers, 'Content-ID');
  _y_part.t_charset := q4mimeCore.mimeExtractParameter(_y_part.t_contentType, 'charset');

  _t_contentType := LowerCase(Trim(_y_part.t_contentType));
  _t_disposition := LowerCase(Trim(_y_part.t_contentDisposition));
  _t_transferEncoding := internalHeaderValue(_y_part.ty_headers, 'Content-Transfer-Encoding');
  _y_decoded := internalDecodeBody(_t_body, _t_transferEncoding);
  _y_part.y_rawBody := _y_decoded;
  _y_part.t_textBody := q4mimeCore.mimeBytesToStringUTF8(_y_decoded);

  q4mimeCore.mimeAddPart(_2_y_message.ty_parts, _y_part);

  if (Pos('text/plain', _t_contentType) = 1) then
  begin
    if (_2_y_message.t_plainText = '') then
      _2_y_message.t_plainText := _y_part.t_textBody;
    Exit;
  end;

  if (Pos('text/html', _t_contentType) = 1) then
  begin
    if (_2_y_message.t_htmlText = '') then
      _2_y_message.t_htmlText := _y_part.t_textBody;
    Exit;
  end;

  if ((Pos('attachment', _t_disposition) = 1) or (_y_part.t_fileName <> '')) then
  begin
    _y_attachment := q4mimeCore.mimeNewAttachment(
      _y_part.t_fileName,
      _y_decoded,
      _y_part.t_contentType,
      _y_part.t_contentID,
      _y_part.t_contentDisposition
    );
    q4mimeCore.mimeAddAttachment(_2_y_message.ty_attachments, _y_attachment);
  end;
end;

function internalMessageToJSON(const _1_y_message: Tq4MimeMessage): string;
var
  _e_i: Int64;
begin
  Result := '{'
    + '"headers":{'
    + '"from":"' + internalJSONEscape(_1_y_message.t_from) + '",'
    + '"to":"' + internalJSONEscape(_1_y_message.t_to) + '",'
    + '"cc":"' + internalJSONEscape(_1_y_message.t_cc) + '",'
    + '"bcc":"' + internalJSONEscape(_1_y_message.t_bcc) + '",'
    + '"subject":"' + internalJSONEscape(_1_y_message.t_subject) + '",'
    + '"date":"' + internalJSONEscape(_1_y_message.t_date) + '",'
    + '"mimeVersion":"' + internalJSONEscape(_1_y_message.t_mimeVersion) + '",'
    + '"contentType":"' + internalJSONEscape(_1_y_message.t_contentType) + '"'
    + '},'
    + '"text":{'
    + '"plain":"' + internalJSONEscape(_1_y_message.t_plainText) + '",'
    + '"html":"' + internalJSONEscape(_1_y_message.t_htmlText) + '"'
    + '},'
    + '"attachments":[';

  for _e_i := 0 to High(_1_y_message.ty_attachments) do
  begin
    if (_e_i > 0) then
      Result += ',';
    Result += '{'
      + '"name":"' + internalJSONEscape(_1_y_message.ty_attachments[_e_i].t_name) + '",'
      + '"mimeType":"' + internalJSONEscape(_1_y_message.ty_attachments[_e_i].t_mimeType) + '",'
      + '"contentID":"' + internalJSONEscape(_1_y_message.ty_attachments[_e_i].t_contentID) + '",'
      + '"disposition":"' + internalJSONEscape(_1_y_message.ty_attachments[_e_i].t_disposition) + '",'
      + '"dataBase64":"' + internalJSONEscape(q4mimeCore.mimeEncodeBase64(_1_y_message.ty_attachments[_e_i].y_data)) + '"'
      + '}';
  end;

  Result += ']}';
end;

function mailConvertFromMIME(const _1_y_mimeSource: TBytes): string;
var
  _t_source, _t_headersText, _t_body, _t_contentType, _t_boundary: string;
  _y_message: Tq4MimeMessage;
  _y_headers: Tq4MimeHeaderArray;
  _tt_parts: Tq4TextArray;
  _e_i: Int64;
begin
  //https://developer.4d.com/docs/21/commands/mail-convert-from-mime
  _t_source := q4mimeCore.mimeBytesToStringUTF8(_1_y_mimeSource);
  _y_message := q4mimeCore.mimeNewMessage;
  internalSplitHeadersAndBody(_t_source, _t_headersText, _t_body);

  _y_headers := internalParseHeaders(_t_headersText);
  _y_message.ty_headers := _y_headers;
  _y_message.t_from := internalHeaderValue(_y_headers, 'From');
  _y_message.t_to := internalHeaderValue(_y_headers, 'To');
  _y_message.t_cc := internalHeaderValue(_y_headers, 'Cc');
  _y_message.t_bcc := internalHeaderValue(_y_headers, 'Bcc');
  _y_message.t_subject := internalHeaderValue(_y_headers, 'Subject');
  _y_message.t_date := internalHeaderValue(_y_headers, 'Date');
  _y_message.t_mimeVersion := internalHeaderValue(_y_headers, 'MIME-Version');
  if (_y_message.t_mimeVersion = '') then
    _y_message.t_mimeVersion := '1.0';
  _y_message.t_contentType := internalHeaderValue(_y_headers, 'Content-Type');

  _t_contentType := LowerCase(Trim(_y_message.t_contentType));

  if (Pos('multipart/', _t_contentType) = 1) then
  begin
    _t_boundary := q4mimeCore.mimeExtractBoundaryFromContentType(_y_message.t_contentType);
    _tt_parts := internalSplitMultipart(_t_body, _t_boundary);
    for _e_i := 0 to High(_tt_parts) do
      internalParseMimePart(_tt_parts[_e_i], _y_message);
  end
  else if (Pos('text/html', _t_contentType) = 1) then
    _y_message.t_htmlText := _t_body
  else
    _y_message.t_plainText := _t_body;

  Result := internalMessageToJSON(_y_message);
  internalSetSuccess;
end;

function mailConvertFromMIME(const _1_t_mimeSource: string): string;
begin
  //https://developer.4d.com/docs/21/commands/mail-convert-from-mime
  Result := q4mail.mailConvertFromMIME(q4mimeCore.mimeStringToBytesUTF8(_1_t_mimeSource));
end;

function internalBuildHeadersFromJSON(const _1_t_mailObjectJson: string): string;
var
  _t_headersBlock: string;
  _t_from, _t_to, _t_cc, _t_bcc, _t_subject, _t_date: string;
begin
  _t_headersBlock := internalExtractJSONBlock(_1_t_mailObjectJson, 'headers', '{', '}');
  _t_from := internalExtractJSONValue(_t_headersBlock, 'from');
  _t_to := internalExtractJSONValue(_t_headersBlock, 'to');
  _t_cc := internalExtractJSONValue(_t_headersBlock, 'cc');
  _t_bcc := internalExtractJSONValue(_t_headersBlock, 'bcc');
  _t_subject := internalExtractJSONValue(_t_headersBlock, 'subject');
  _t_date := internalExtractJSONValue(_t_headersBlock, 'date');

  Result := '';
  if (_t_from <> '') then Result += 'From: ' + _t_from + #13#10;
  if (_t_to <> '') then Result += 'To: ' + _t_to + #13#10;
  if (_t_cc <> '') then Result += 'Cc: ' + _t_cc + #13#10;
  if (_t_bcc <> '') then Result += 'Bcc: ' + _t_bcc + #13#10;
  if (_t_subject <> '') then Result += 'Subject: ' + _t_subject + #13#10;
  if (_t_date <> '') then Result += 'Date: ' + _t_date + #13#10;
end;

function internalBuildTextPart(const _1_t_contentType, _2_t_body: string): string;
begin
  Result :=
    'Content-Type: ' + _1_t_contentType + '; charset=UTF-8'#13#10
    + 'Content-Transfer-Encoding: 8bit'#13#10#13#10
    + _2_t_body + #13#10;
end;

function internalBuildAttachmentPart(const _1_y_attachment: Tq4MimeAttachment): string;
var
  _t_name: string;
begin
  _t_name := _1_y_attachment.t_name;
  if (_t_name = '') then
    _t_name := 'attachment.bin';

  Result :=
    'Content-Type: ' + _1_y_attachment.t_mimeType + '; name="' + _t_name + '"'#13#10
    + 'Content-Disposition: ' + _1_y_attachment.t_disposition + '; filename="' + _t_name + '"'#13#10;

  if (_1_y_attachment.t_contentID <> '') then
    Result += 'Content-ID: ' + _1_y_attachment.t_contentID + #13#10;

  Result += 'Content-Transfer-Encoding: base64'#13#10#13#10
    + q4mimeCore.mimeEncodeBase64(_1_y_attachment.y_data) + #13#10;
end;

function internalParseAttachmentsFromJSON(const _1_t_mailObjectJson: string): Tq4MimeAttachmentArray;
var
  _t_arrayBlock, _t_item, _t_name, _t_mimeType, _t_contentID, _t_disposition, _t_dataBase64: string;
  _y_range: Tq4JSONObjectRange;
  _e_pos: Int64;
  _y_attachment: Tq4MimeAttachment;
begin
  SetLength(Result, 0);
  _t_arrayBlock := internalExtractJSONBlock(_1_t_mailObjectJson, 'attachments', '[', ']');
  if (Trim(_t_arrayBlock) = '') then
    Exit;

  _e_pos := 1;
  repeat
    _y_range := internalFindNextJSONObject(_t_arrayBlock, _e_pos);
    if (_y_range.e_startPos <= 0) then
      Break;

    _t_item := Copy(_t_arrayBlock, _y_range.e_startPos, _y_range.e_endPos - _y_range.e_startPos + 1);
    _t_name := internalExtractJSONValue(_t_item, 'name');
    _t_mimeType := internalExtractJSONValue(_t_item, 'mimeType');
    _t_contentID := internalExtractJSONValue(_t_item, 'contentID');
    _t_disposition := internalExtractJSONValue(_t_item, 'disposition');
    _t_dataBase64 := internalExtractJSONValue(_t_item, 'dataBase64');

    if (_t_mimeType = '') then
      _t_mimeType := q4mimeCore.mimeGuessContentTypeFromFileName(_t_name);
    if (_t_disposition = '') then
      _t_disposition := MAIL_DISPOSITION_ATTACHMENT;

    _y_attachment := q4mimeCore.mimeNewAttachment(
      _t_name,
      q4mimeCore.mimeDecodeBase64(_t_dataBase64),
      _t_mimeType,
      _t_contentID,
      _t_disposition
    );
    q4mimeCore.mimeAddAttachment(Result, _y_attachment);
    _e_pos := _y_range.e_endPos + 1;
  until (False);
end;

function mailConvertToMIME(const _1_t_mailObjectJson: string; const _2_t_optionsJson: string): string;
var
  _t_textBlock, _t_plain, _t_html, _t_headers, _t_boundaryMixed, _t_boundaryAlt: string;
  _ty_attachments: Tq4MimeAttachmentArray;
  _e_i: Int64;
begin
  //https://developer.4d.com/docs/21/commands/mail-convert-to-mime
  _t_headers := internalBuildHeadersFromJSON(_1_t_mailObjectJson);
  _t_textBlock := internalExtractJSONBlock(_1_t_mailObjectJson, 'text', '{', '}');
  _t_plain := internalExtractJSONValue(_t_textBlock, 'plain');
  _t_html := internalExtractJSONValue(_t_textBlock, 'html');
  _ty_attachments := internalParseAttachmentsFromJSON(_1_t_mailObjectJson);

  Result := _t_headers + 'MIME-Version: 1.0'#13#10;

  if (Length(_ty_attachments) > 0) then
  begin
    _t_boundaryMixed := 'q4mixed-' + IntToStr(SysUtils.GetTickCount64);
    Result += 'Content-Type: multipart/mixed; boundary="' + _t_boundaryMixed + '"'#13#10#13#10;

    if ((_t_plain <> '') and (_t_html <> '')) then
    begin
      _t_boundaryAlt := 'q4alt-' + IntToStr(SysUtils.GetTickCount64 + 1);
      Result += '--' + _t_boundaryMixed + #13#10;
      Result += 'Content-Type: multipart/alternative; boundary="' + _t_boundaryAlt + '"'#13#10#13#10;
      Result += '--' + _t_boundaryAlt + #13#10 + internalBuildTextPart('text/plain', _t_plain);
      Result += '--' + _t_boundaryAlt + #13#10 + internalBuildTextPart('text/html', _t_html);
      Result += '--' + _t_boundaryAlt + '--'#13#10;
    end
    else if (_t_html <> '') then
    begin
      Result += '--' + _t_boundaryMixed + #13#10 + internalBuildTextPart('text/html', _t_html);
    end
    else
    begin
      Result += '--' + _t_boundaryMixed + #13#10 + internalBuildTextPart('text/plain', _t_plain);
    end;

    for _e_i := 0 to High(_ty_attachments) do
    begin
      Result += '--' + _t_boundaryMixed + #13#10;
      Result += internalBuildAttachmentPart(_ty_attachments[_e_i]);
    end;

    Result += '--' + _t_boundaryMixed + '--'#13#10;
  end
  else if ((_t_plain <> '') and (_t_html <> '')) then
  begin
    _t_boundaryAlt := 'q4alt-' + IntToStr(SysUtils.GetTickCount64);
    Result += 'Content-Type: multipart/alternative; boundary="' + _t_boundaryAlt + '"'#13#10#13#10;
    Result += '--' + _t_boundaryAlt + #13#10 + internalBuildTextPart('text/plain', _t_plain);
    Result += '--' + _t_boundaryAlt + #13#10 + internalBuildTextPart('text/html', _t_html);
    Result += '--' + _t_boundaryAlt + '--'#13#10;
  end
  else if (_t_html <> '') then
  begin
    Result += 'Content-Type: text/html; charset=UTF-8'#13#10
      + 'Content-Transfer-Encoding: 8bit'#13#10#13#10
      + _t_html;
  end
  else
  begin
    Result += 'Content-Type: text/plain; charset=UTF-8'#13#10
      + 'Content-Transfer-Encoding: 8bit'#13#10#13#10
      + _t_plain;
  end;

  internalSetSuccess;
end;

function mailNewAttachment(const _1_y_blob: TBytes; const _2_t_name: string; const _3_t_cid: string; const _4_t_type: string; const _5_t_disposition: string): Tq4MailAttachment;
var
  _t_name, _t_type, _t_disposition: string;
begin
  //https://developer.4d.com/docs/21/commands/mail-new-attachment
  _t_name := _2_t_name;
  if (_t_name = '') then
    _t_name := 'attachment.bin';

  _t_type := _4_t_type;
  if (_t_type = '') then
    _t_type := q4mimeCore.mimeGuessContentTypeFromFileName(_t_name);

  _t_disposition := _5_t_disposition;
  if (_t_disposition = '') then
    _t_disposition := MAIL_DISPOSITION_ATTACHMENT;

  Result := q4mimeCore.mimeNewAttachment(_t_name, _1_y_blob, _t_type, _3_t_cid, _t_disposition);
  internalSetSuccess;
end;

function mailNewAttachment(const _1_t_path: string; const _2_t_name: string; const _3_t_cid: string; const _4_t_type: string; const _5_t_disposition: string): Tq4MailAttachment;
var
  _y_blob: TBytes;
  _o_stream: TFileStream;
  _t_name: string;
begin
  //https://developer.4d.com/docs/21/commands/mail-new-attachment
  SetLength(_y_blob, 0);
  if (FileExists(_1_t_path)) then
  begin
    _o_stream := TFileStream.Create(_1_t_path, fmOpenRead or fmShareDenyNone);
    try
      SetLength(_y_blob, _o_stream.Size);
      if (_o_stream.Size > 0) then
        _o_stream.ReadBuffer(_y_blob[0], _o_stream.Size);
    finally
      _o_stream.Free;
    end;
  end;

  _t_name := _2_t_name;
  if (_t_name = '') then
    _t_name := ExtractFileName(_1_t_path);

  Result := q4mail.mailNewAttachment(_y_blob, _t_name, _3_t_cid, _4_t_type, _5_t_disposition);
end;

function mailNewAttachment(const _1_y_file: Tq4File; const _2_t_name: string; const _3_t_cid: string; const _4_t_type: string; const _5_t_disposition: string): Tq4MailAttachment;
begin
  Result := q4mail.mailNewAttachment(_1_y_file.t_path, _2_t_name, _3_t_cid, _4_t_type, _5_t_disposition);
end;

function mailNewAttachment(const _1_y_zipFile: Tq4ZipFile; const _2_t_name: string; const _3_t_cid: string; const _4_t_type: string; const _5_t_disposition: string): Tq4MailAttachment;
begin
  Result := q4mail.mailNewAttachment(_1_y_zipFile.t_path, _2_t_name, _3_t_cid, _4_t_type, _5_t_disposition);
end;

end.
