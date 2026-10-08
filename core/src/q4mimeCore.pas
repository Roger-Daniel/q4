unit q4mimeCore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, base64;

const
  Q4_MIME_DISPOSITION_ATTACHMENT = 'attachment';
  Q4_MIME_DISPOSITION_INLINE     = 'inline';
  Q4_MIME_TEXT_PLAIN             = 'text/plain';
  Q4_MIME_TEXT_HTML              = 'text/html';
  Q4_MIME_APPLICATION_OCTET      = 'application/octet-stream';

type
  Tq4MimeHeader = record
    t_name: string;
    t_value: string;
  end;
  Tq4MimeHeaderArray = array of Tq4MimeHeader;

  Tq4MimeAttachment = record
    t_name: string;
    t_mimeType: string;
    t_contentID: string;
    t_disposition: string;
    y_data: TBytes;
  end;
  Tq4MimeAttachmentArray = array of Tq4MimeAttachment;

  Tq4MimePart = record
    t_contentType: string;
    t_charset: string;
    t_contentDisposition: string;
    t_name: string;
    t_fileName: string;
    t_contentID: string;
    t_textBody: string;
    y_rawBody: TBytes;
    ty_headers: Tq4MimeHeaderArray;
  end;
  Tq4MimePartArray = array of Tq4MimePart;

  Tq4MimeMessage = record
    ty_headers: Tq4MimeHeaderArray;
    t_from: string;
    t_to: string;
    t_cc: string;
    t_bcc: string;
    t_subject: string;
    t_date: string;
    t_mimeVersion: string;
    t_contentType: string;
    t_plainText: string;
    t_htmlText: string;
    ty_attachments: Tq4MimeAttachmentArray;
    ty_parts: Tq4MimePartArray;
  end;

function mimeNewHeader(const _1_t_name, _2_t_value: string): Tq4MimeHeader;
function mimeNewAttachment(
  const _1_t_name: string;
  const _2_y_data: TBytes;
  const _3_t_mimeType: string = Q4_MIME_APPLICATION_OCTET;
  const _4_t_contentID: string = '';
  const _5_t_disposition: string = Q4_MIME_DISPOSITION_ATTACHMENT
): Tq4MimeAttachment;
function mimeNewPart: Tq4MimePart;
function mimeNewMessage: Tq4MimeMessage;

procedure mimeAddHeader(var _1_ty_headers: Tq4MimeHeaderArray; const _2_y_header: Tq4MimeHeader);
procedure mimeAddPart(var _1_ty_parts: Tq4MimePartArray; const _2_y_part: Tq4MimePart);
procedure mimeAddAttachment(var _1_ty_attachments: Tq4MimeAttachmentArray; const _2_y_attachment: Tq4MimeAttachment);

function mimeGetHeaderValue(const _1_ty_headers: Tq4MimeHeaderArray; const _2_t_name: string): string;
function mimeSetHeaderValue(var _1_ty_headers: Tq4MimeHeaderArray; const _2_t_name, _3_t_value: string): Boolean;
function mimeHeaderExists(const _1_ty_headers: Tq4MimeHeaderArray; const _2_t_name: string): Boolean;
function mimeGuessContentTypeFromFileName(const _1_t_fileName: string): string;
function mimeEncodeBase64(const _1_y_data: TBytes): string;
function mimeDecodeBase64(const _1_t_base64: string): TBytes;
function mimeBytesToStringUTF8(const _1_y_data: TBytes): string;
function mimeStringToBytesUTF8(const _1_t_value: string): TBytes;
function mimeExtractBoundaryFromContentType(const _1_t_contentType: string): string;
function mimeExtractParameter(const _1_t_source, _2_t_parameterName: string): string;

implementation

function q4mimeSameHeaderName(const _1_t_left, _2_t_right: string): Boolean;
begin
  Result := SysUtils.SameText(SysUtils.Trim(_1_t_left), SysUtils.Trim(_2_t_right));
end;

function mimeNewHeader(const _1_t_name, _2_t_value: string): Tq4MimeHeader;
begin
  Result.t_name := SysUtils.Trim(_1_t_name);
  Result.t_value := _2_t_value;
end;

function mimeNewAttachment(const _1_t_name: string; const _2_y_data: TBytes; const _3_t_mimeType: string; const _4_t_contentID: string; const _5_t_disposition: string): Tq4MimeAttachment;
begin
  Result.t_name := _1_t_name;
  Result.y_data := Copy(_2_y_data);
  Result.t_mimeType := _3_t_mimeType;
  Result.t_contentID := _4_t_contentID;
  Result.t_disposition := _5_t_disposition;
end;

function mimeNewPart: Tq4MimePart;
begin
  Result.t_contentType := '';
  Result.t_charset := '';
  Result.t_contentDisposition := '';
  Result.t_name := '';
  Result.t_fileName := '';
  Result.t_contentID := '';
  Result.t_textBody := '';
  SetLength(Result.y_rawBody, 0);
  SetLength(Result.ty_headers, 0);
end;

function mimeNewMessage: Tq4MimeMessage;
begin
  SetLength(Result.ty_headers, 0);
  Result.t_from := '';
  Result.t_to := '';
  Result.t_cc := '';
  Result.t_bcc := '';
  Result.t_subject := '';
  Result.t_date := '';
  Result.t_mimeVersion := '1.0';
  Result.t_contentType := '';
  Result.t_plainText := '';
  Result.t_htmlText := '';
  SetLength(Result.ty_attachments, 0);
  SetLength(Result.ty_parts, 0);
end;

procedure mimeAddHeader(var _1_ty_headers: Tq4MimeHeaderArray; const _2_y_header: Tq4MimeHeader);
begin
  SetLength(_1_ty_headers, Length(_1_ty_headers)+1);
  _1_ty_headers[High(_1_ty_headers)] := _2_y_header;
end;

procedure mimeAddPart(var _1_ty_parts: Tq4MimePartArray; const _2_y_part: Tq4MimePart);
begin
  SetLength(_1_ty_parts, Length(_1_ty_parts)+1);
  _1_ty_parts[High(_1_ty_parts)] := _2_y_part;
end;

procedure mimeAddAttachment(var _1_ty_attachments: Tq4MimeAttachmentArray; const _2_y_attachment: Tq4MimeAttachment);
begin
  SetLength(_1_ty_attachments, Length(_1_ty_attachments)+1);
  _1_ty_attachments[High(_1_ty_attachments)] := _2_y_attachment;
end;

function mimeGetHeaderValue(const _1_ty_headers: Tq4MimeHeaderArray; const _2_t_name: string): string;
var e_i: Int64;
begin
  for e_i := 0 to High(_1_ty_headers) do
    if (q4mimeSameHeaderName(_1_ty_headers[e_i].t_name, _2_t_name)) then Exit(_1_ty_headers[e_i].t_value);
  Result := '';
end;

function mimeSetHeaderValue(var _1_ty_headers: Tq4MimeHeaderArray; const _2_t_name, _3_t_value: string): Boolean;
var e_i: Int64;
begin
  for e_i := 0 to High(_1_ty_headers) do
    if (q4mimeSameHeaderName(_1_ty_headers[e_i].t_name, _2_t_name)) then
    begin
      _1_ty_headers[e_i].t_value := _3_t_value;
      Exit(True);
    end;
  mimeAddHeader(_1_ty_headers, mimeNewHeader(_2_t_name, _3_t_value));
  Result := True;
end;

function mimeHeaderExists(const _1_ty_headers: Tq4MimeHeaderArray; const _2_t_name: string): Boolean;
begin
  Result := mimeGetHeaderValue(_1_ty_headers, _2_t_name) <> '';
end;

function mimeGuessContentTypeFromFileName(const _1_t_fileName: string): string;
var t_ext: string;
begin
  t_ext := LowerCase(ExtractFileExt(_1_t_fileName));
  if (t_ext = '.txt') then Exit(Q4_MIME_TEXT_PLAIN);
  if ((t_ext = '.htm') or (t_ext = '.html')) then Exit(Q4_MIME_TEXT_HTML);
  if (t_ext = '.json') then Exit('application/json');
  if (t_ext = '.xml') then Exit('application/xml');
  if (t_ext = '.csv') then Exit('text/csv');
  if (t_ext = '.pdf') then Exit('application/pdf');
  if ((t_ext = '.jpg') or (t_ext = '.jpeg')) then Exit('image/jpeg');
  if (t_ext = '.png') then Exit('image/png');
  if (t_ext = '.gif') then Exit('image/gif');
  if (t_ext = '.zip') then Exit('application/zip');
  Result := Q4_MIME_APPLICATION_OCTET;
end;

function mimeEncodeBase64(const _1_y_data: TBytes): string;
var t_raw: RawByteString; e_i: Int64;
begin
  SetLength(t_raw, Length(_1_y_data));
  for e_i := 0 to High(_1_y_data) do t_raw[e_i+1] := AnsiChar(_1_y_data[e_i]);
  Result := EncodeStringBase64(t_raw);
end;

function mimeDecodeBase64(const _1_t_base64: string): TBytes;
var t_raw: RawByteString; e_i: Int64;
begin
  t_raw := DecodeStringBase64(_1_t_base64);
  SetLength(Result, Length(t_raw));
  for e_i := 1 to Length(t_raw) do Result[e_i-1] := Byte(t_raw[e_i]);
end;

function mimeBytesToStringUTF8(const _1_y_data: TBytes): string;
begin
  if (Length(_1_y_data) = 0) then Exit('');
  SetString(Result, PChar(@_1_y_data[0]), Length(_1_y_data));
end;

function mimeStringToBytesUTF8(const _1_t_value: string): TBytes;
var e_i: Int64;
begin
  SetLength(Result, Length(_1_t_value));
  for e_i := 1 to Length(_1_t_value) do Result[e_i-1] := Byte(_1_t_value[e_i]);
end;

function mimeExtractBoundaryFromContentType(const _1_t_contentType: string): string;
begin
  Result := mimeExtractParameter(_1_t_contentType, 'boundary');
end;

function mimeExtractParameter(const _1_t_source, _2_t_parameterName: string): string;
var t_work,t_lower,t_search: string; e_posStart,e_posEnd: Int64;
begin
  Result := '';
  t_work := _1_t_source;
  t_lower := LowerCase(t_work);
  t_search := LowerCase(_2_t_parameterName) + '=';
  e_posStart := Pos(t_search, t_lower);
  if (e_posStart <= 0) then Exit;
  e_posStart := e_posStart + Length(t_search);
  while ((e_posStart <= Length(t_work)) and (t_work[e_posStart] = ' ')) do Inc(e_posStart);
  if ((e_posStart <= Length(t_work)) and (t_work[e_posStart] = '"')) then
  begin
    Inc(e_posStart); e_posEnd := e_posStart;
    while ((e_posEnd <= Length(t_work)) and (t_work[e_posEnd] <> '"')) do Inc(e_posEnd);
    Exit(Copy(t_work, e_posStart, e_posEnd - e_posStart));
  end;
  e_posEnd := e_posStart;
  while ((e_posEnd <= Length(t_work)) and (t_work[e_posEnd] <> ';')) do Inc(e_posEnd);
  Result := Trim(Copy(t_work, e_posStart, e_posEnd - e_posStart));
end;

end.
