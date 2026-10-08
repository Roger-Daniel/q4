Unit q4communications;

{$mode objfpc}{$H+}

{
q4communications
version du 2026/05/16-01

Mapping 4D -> q4communications -> statut
Command Number 4D,    4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
909,                  GET SERIAL PORT MAPPING,          getSerialPortMapping,             OK simple,
172,                  RECEIVE BUFFER,                   receiveBuffer,                    OK simple,
104,                  RECEIVE PACKET,                   receivePacket,                    OK spécifique,
79,                   RECEIVE RECORD,                   receiveRecordExterne,             OK structurel,
81,                   RECEIVE VARIABLE,                 receiveVariable,                  OK structurel,
103,                  SEND PACKET,                      sendPacket,                       OK spécifique,
78,                   SEND RECORD,                      sendRecordExterne,                OK structurel,
80,                   SEND VARIABLE,                    sendVariable,                     OK structurel,
77,                   SET CHANNEL,                      setChannel,                       OK spécifique,
268,                  SET TIMEOUT,                      setTimeout,                       OK spécifique,
205,                  USE CHARACTER SET,                useCharacterSet,                  OK spécifique,

Notes q4 :
- fichier canonique unique destiné à remplacer les versions intermédiaires
- protocole record compatible avec data_recordExterneSend (typeCode optimisé, pas Type() 4D brut)
- SEND/RECEIVE VARIABLE utilisent les mêmes familles de codes avec un offset +1000
- backend document opérationnel ; backend série maison conservé comme couche native à finaliser/valider compilation selon OS ; backend Synapse à rebrancher ensuite si souhaité
}

Interface

Uses
  SysUtils,
  Classes,
  Variants,
  q4coreLanguage,
  metier_q4DBschemaBase,
  metier_q4DBschemaProcess,
  q4DBschemaUse,
  q4record;

Const
  Q4COMM_CHANNEL_CLOSED = 0;
  Q4COMM_CHANNEL_DOCUMENT_READ = 1;
  Q4COMM_CHANNEL_DOCUMENT_WRITE = 2;
  Q4COMM_CHANNEL_DOCUMENT_READWRITE = 3;
  Q4COMM_CHANNEL_SERIAL = 10;

  Q4COMM_CHARSET_UTF8 = 1;

  Q4COMM_ERROR_UNSUPPORTED = -105200;
  Q4COMM_ERROR_CHANNEL = -105201;
  Q4COMM_ERROR_TIMEOUT = -105202;
  Q4COMM_ERROR_IO = -105203;
  Q4COMM_ERROR_BAD_PARAMETER = -105204;

  Q4X_VARIABLE_TYPE_OFFSET = 1000;

  Q4X_FIELD_DELETED = 1;
  Q4X_NULL = 2;
  Q4X_ALPHA_EMPTY = 4;
  Q4X_ALPHA_UTF8_U16 = 5;
  Q4X_BOOLEAN = 6;
  Q4X_DATE_EMPTY = 8;
  Q4X_DATE_UTF8_U16 = 9;
  Q4X_INTEGER_ZERO = 10;
  Q4X_INTEGER_VALUE = 11;
  Q4X_INT64_ZERO = 12;
  Q4X_INT64_UTF8_U16 = 13;
  Q4X_LONGINT_ZERO = 14;
  Q4X_LONGINT_VALUE = 15;
  Q4X_REAL_ZERO = 16;
  Q4X_REAL_UTF8_U16 = 17;
  Q4X_TIME_EMPTY = 18;
  Q4X_TIME_UTF8_U16 = 19;
  Q4X_TEXT_EMPTY = 20;
  Q4X_TEXT_UTF8_U16 = 21;
  Q4X_TEXT_UTF8_U32 = 22;
  Q4X_OBJECT_EMPTY = 30;
  Q4X_OBJECT_JSON_U16 = 31;
  Q4X_OBJECT_JSON_U32 = 32;
  Q4X_BLOB_EMPTY = 40;
  Q4X_BLOB_U16 = 41;
  Q4X_BLOB_U32 = 42;
  Q4X_PICTURE_EMPTY = 50;
  Q4X_PICTURE_PNG_U16 = 51;
  Q4X_PICTURE_PNG_U32 = 52;

Procedure sendRecordExterne( Const _1_o_stream: TStream; _2_p_table: Pointer);
Procedure receiveRecordExterne( Const _1_o_stream: TStream; _2_p_table: Pointer);
Function xportReadI32( Const _1_o_stream: TStream): int64;

Function setChannel( _1_e_operation: int64; Const _2_t_document: string = ''): int64;
Function setSerialChannel( Const _1_t_port: string; _2_e_baudRate: int64 = 9600; _3_e_dataBits: int64 = 8; _4_t_parity: string = 'N'; _5_e_stopBits: int64 = 1): int64;
Procedure closeChannel;
Procedure setTimeout( _1_e_timeoutMs: int64);
Procedure useCharacterSet( Const _1_t_importCharset: string = 'UTF-8'; Const _2_t_exportCharset: string = 'UTF-8');
Procedure sendPacket( Const _1_v_data: variant; _2_e_docRef: int64 = Q4COMM_CHANNEL_CLOSED);
Function receivePacket( _1_e_numBytes: int64; _2_e_docRef: int64 = Q4COMM_CHANNEL_CLOSED): variant;

Function getSerialPortMapping: string;
Function receiveBuffer: variant;
Procedure sendVariable( Const _1_v_value: variant);
Function receiveVariable: variant;
Procedure sendField( Const _1_p_field: Pointer);
Procedure receiveField( Const _1_p_field: Pointer);
Procedure sendPictureVariable( Const _1_v_picture: variant);

Implementation

Uses
  q4interruptions,
  q4dateAndTime{$IFDEF UNIX},
  BaseUnix, Unix{$ENDIF};

Type
  Tq4CommunicationChannel = Class
  public
    e_ref: int64;
    e_mode: int64;
    t_document: string;
    o_stream: TFileStream;
    b_isSerial: boolean;
    e_serialHandle: PtrInt;
    t_serialPort: string;
    Constructor Create;
    Destructor Destroy; override;
  End;

Threadvar
  ge_currentChannelRef: int64;
  ge_timeoutMs:     int64;
  ge_importCharset: int64;
  ge_exportCharset: int64;

Var
  go_channels: TList;
  ge_nextChannelRef: int64 = 1;

Constructor Tq4CommunicationChannel.Create;
  Begin
    Inherited Create;
    e_ref := Q4COMM_CHANNEL_CLOSED;
    e_mode := Q4COMM_CHANNEL_CLOSED;
    t_document := '';
    o_stream := nil;
    b_isSerial := False;
    e_serialHandle := -1;
    t_serialPort := '';
  End;

Destructor Tq4CommunicationChannel.Destroy;
  Begin
    FreeAndNil( o_stream);
    {$IFDEF UNIX}
  if (e_serialHandle <> -1) then begin
    FpClose(e_serialHandle);
    e_serialHandle := -1;
  end;
{$ENDIF}
    Inherited Destroy;
  End;

Function runtimeOf( Var _1_p_table: Pointer): Pq4recordRuntime; Inline;
  Begin
    Result := q4DBschemaUse.Pq4recordRuntime( _1_p_table);
  End;

Procedure resetRuntimeStatus;
  Begin
    q4coreLanguage.OK := 1;
    q4coreLanguage.Error := 0;
  End;

Procedure failRuntimeStatus( _1_e_error: int64);
  Begin
    q4coreLanguage.OK := 0;
    q4coreLanguage.Error := _1_e_error;
  End;

Function requireUTF8Charset( Const _1_t_value: string): int64;
  Var
    _t_value: string;
  Begin
    _t_value := SysUtils.UpperCase( SysUtils.Trim( _1_t_value));
    If ( ( _t_value = '') or ( _t_value = 'UTF-8') or ( _t_value = 'UTF8')) Then Exit( Q4COMM_CHARSET_UTF8);

    failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
    q4interruptions.assertRaise( 'q4communications: charset non support en v1 document-first: ' + _1_t_value,
      {$I %CURRENTROUTINE%}, {$I %LINENUM%});
  End;

Function findChannelByRef( _1_e_ref: int64): Tq4CommunicationChannel;
  Var
    _e_index:   int64;
    _o_channel: Tq4CommunicationChannel;
  Begin
    Result := nil;
    If ( go_channels = nil) Then Exit;

    For _e_index := 0 To go_channels.Count - 1 Do Begin
      _o_channel := Tq4CommunicationChannel( go_channels[_e_index]);
      If ( _o_channel.e_ref = _1_e_ref) Then Exit( _o_channel);
    End;
  End;

Function requireCurrentChannelRef( _1_e_docRef: int64): int64;
  Begin
    If ( _1_e_docRef <> Q4COMM_CHANNEL_CLOSED) Then Exit( _1_e_docRef);
    If ( ge_currentChannelRef <> Q4COMM_CHANNEL_CLOSED) Then Exit( ge_currentChannelRef);

    failRuntimeStatus( Q4COMM_ERROR_CHANNEL);
    q4interruptions.assertRaise( 'q4communications: aucun canal courant ouvert', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
  End;

Function requireChannel( _1_e_docRef: int64): Tq4CommunicationChannel;
  Var
    _e_ref: int64;
  Begin
    _e_ref := requireCurrentChannelRef( _1_e_docRef);
    Result := findChannelByRef( _e_ref);
    If ( Result <> nil) Then Exit;

    failRuntimeStatus( Q4COMM_ERROR_CHANNEL);
    q4interruptions.assertRaise( 'q4communications: docRef/canal introuvable', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
  End;

Procedure ensureReadable( Const _1_o_channel: Tq4CommunicationChannel);
  Begin
    If ( _1_o_channel.e_mode in [Q4COMM_CHANNEL_DOCUMENT_READ, Q4COMM_CHANNEL_DOCUMENT_READWRITE, Q4COMM_CHANNEL_SERIAL]) Then Exit;

    failRuntimeStatus( Q4COMM_ERROR_CHANNEL);
    q4interruptions.assertRaise( 'q4communications: canal non ouvert en lecture', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
  End;

Procedure ensureWritable( Const _1_o_channel: Tq4CommunicationChannel);
  Begin
    If ( _1_o_channel.e_mode in [Q4COMM_CHANNEL_DOCUMENT_WRITE, Q4COMM_CHANNEL_DOCUMENT_READWRITE, Q4COMM_CHANNEL_SERIAL]) Then Exit;

    failRuntimeStatus( Q4COMM_ERROR_CHANNEL);
    q4interruptions.assertRaise( 'q4communications: canal non ouvert en criture', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
  End;


Function channelIsSerial( Const _1_o_channel: Tq4CommunicationChannel): boolean; Inline;
  Begin
    Result := ( _1_o_channel <> nil) and _1_o_channel.b_isSerial;
  End;

Function channelIsDocument( Const _1_o_channel: Tq4CommunicationChannel): boolean; Inline;
  Begin
    Result := ( _1_o_channel <> nil) and ( not _1_o_channel.b_isSerial);
  End;

{$IFDEF UNIX}
function nativeSerialOpen(const _1_t_port: string): PtrInt;
begin
  Result := fpOpen(_1_t_port, O_RDWR or O_NOCTTY);
end;

function nativeSerialWaitReadable(const _1_e_handle: PtrInt; const _2_e_timeoutMs: Int64): boolean;
var
  _y_set: TFDSet;
  _y_tv: TTimeVal;
  _p_tv: PTimeVal;
  _e_status: cint;
begin
  fpFD_ZERO(_y_set);
  fpFD_SET(_1_e_handle, _y_set);
  if (_2_e_timeoutMs < 0) then begin
    _p_tv := nil;
  end else begin
    _y_tv.tv_sec := _2_e_timeoutMs div 1000;
    _y_tv.tv_usec := (_2_e_timeoutMs mod 1000) * 1000;
    _p_tv := @_y_tv;
  end;
  _e_status := fpSelect(_1_e_handle + 1, @_y_set, nil, nil, _p_tv);
  Result := _e_status > 0;
end;
{$ENDIF}


Function VariantToBooleanSafe( Const _1_v_value: variant): boolean;
  Var
    _s: string;
  Begin
    If ( VarIsNull( _1_v_value) or VarIsEmpty( _1_v_value)) Then Exit( False);

    Case VarType( _1_v_value) and varTypeMask Of
      varBoolean: Exit( boolean( _1_v_value));
      varByte, varSmallint, varInteger, varShortInt, varWord, varLongWord, varInt64, varQWord: Exit( _1_v_value <> 0);
      varSingle, varDouble, varCurrency: Exit( _1_v_value <> 0);
      varString, varUString, varOleStr: Begin
        _s := Trim( LowerCase( string( _1_v_value)));
        If ( ( _s = '') or ( _s = '0') or ( _s = 'false') or ( _s = 'faux') or ( _s = 'no') or ( _s = 'non')) Then Exit( False);
        Exit( True);
      End;
    End;

    Try
      Result := _1_v_value <> 0;
    Except
      Result := True;
    End;
  End;

Function streamRemainingBytes( _1_o_stream: TStream): int64; forward;
Function readExactBytes( _1_o_stream: TStream; Const _2_e_len: int64): TBytes; forward;
Procedure writeRawBytes( _1_o_stream: TStream; Const _2_y_bytes: TBytes); forward;

Function channelReadExactBytes( Const _1_o_channel: Tq4CommunicationChannel; Const _2_e_count: int64): TBytes;
    {$IFDEF UNIX}
var
  _e_total, _e_chunk, _e_waitMs: Int64;
  _y_startedAt: TDateTime;
  _y_part: TBytes;
{$ENDIF}
  Begin
    If ( _2_e_count <= 0) Then Begin
      SetLength( Result, 0);
      Exit;
    End;
    If ( channelIsDocument( _1_o_channel)) Then Exit( readExactBytes( _1_o_channel.o_stream, _2_e_count));
    {$IFDEF UNIX}
  SetLength(Result, _2_e_count);
  _e_total := 0;
  _y_startedAt := Now;
  while (_e_total < _2_e_count) do begin
    if (ge_timeoutMs > 0) then begin
      _e_waitMs := ge_timeoutMs - Round((Now - _y_startedAt) * 24 * 60 * 60 * 1000);
      if (_e_waitMs <= 0) then begin
        failRuntimeStatus(Q4COMM_ERROR_TIMEOUT);
        q4interruptions.assertRaise('q4communications: timeout lecture série', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
      end;
      if (not nativeSerialWaitReadable(_1_o_channel.e_serialHandle, _e_waitMs)) then begin
        failRuntimeStatus(Q4COMM_ERROR_TIMEOUT);
        q4interruptions.assertRaise('q4communications: timeout lecture série', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
      end;
    end;
    SetLength(_y_part, _2_e_count - _e_total);
    _e_chunk := fpRead(_1_o_channel.e_serialHandle, _y_part[0], Length(_y_part));
    if (_e_chunk <= 0) then begin
      failRuntimeStatus(Q4COMM_ERROR_IO);
      q4interruptions.assertRaise('q4communications: erreur lecture série', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    end;
    Move(_y_part[0], Result[_e_total], _e_chunk);
    Inc(_e_total, _e_chunk);
  end;
{$ELSE}
    failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
    q4interruptions.assertRaise( 'q4communications: backend série maison indisponible sur cet OS', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    {$ENDIF}
  End;

Function channelReadAvailableBytes( Const _1_o_channel: Tq4CommunicationChannel): TBytes;
{$IFDEF UNIX}
var
  _e_chunk: Int64;
begin
  if (channelIsDocument(_1_o_channel)) then Exit(readExactBytes(_1_o_channel.o_stream, streamRemainingBytes(_1_o_channel.o_stream)));
  if (ge_timeoutMs > 0) then begin
    if (not nativeSerialWaitReadable(_1_o_channel.e_serialHandle, ge_timeoutMs)) then begin
      SetLength(Result, 0);
      Exit;
    end;
  end;
  SetLength(Result, 4096);
  _e_chunk := fpRead(_1_o_channel.e_serialHandle, Result[0], Length(Result));
  if (_e_chunk < 0) then begin
    failRuntimeStatus(Q4COMM_ERROR_IO);
    q4interruptions.assertRaise('q4communications: erreur lecture série', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
  end;
  SetLength(Result, _e_chunk);
end;
{$ELSE}
  Begin
    If ( channelIsDocument( _1_o_channel)) Then Exit( readExactBytes( _1_o_channel.o_stream, streamRemainingBytes( _1_o_channel.o_stream)));
    failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
    q4interruptions.assertRaise( 'q4communications: backend série maison indisponible sur cet OS', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
  End;
{$ENDIF}

Procedure channelWriteBytes( Const _1_o_channel: Tq4CommunicationChannel; Const _2_y_bytes: TBytes);
{$IFDEF UNIX}
var
  _e_total, _e_written: Int64;
begin
  if (channelIsDocument(_1_o_channel)) then begin
    writeRawBytes(_1_o_channel.o_stream, _2_y_bytes);
    Exit;
  end;
  _e_total := 0;
  while (_e_total < Length(_2_y_bytes)) do begin
    _e_written := fpWrite(_1_o_channel.e_serialHandle, _2_y_bytes[_e_total], Length(_2_y_bytes) - _e_total);
    if (_e_written <= 0) then begin
      failRuntimeStatus(Q4COMM_ERROR_IO);
      q4interruptions.assertRaise('q4communications: erreur écriture série', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    end;
    Inc(_e_total, _e_written);
  end;
end;
{$ELSE}
  Begin
    If ( channelIsDocument( _1_o_channel)) Then Begin
      writeRawBytes( _1_o_channel.o_stream, _2_y_bytes);
      Exit;
    End;
    failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
    q4interruptions.assertRaise( 'q4communications: backend série maison indisponible sur cet OS', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
  End;
{$ENDIF}

Function openFileModeForChannel( _1_e_operation: int64): word;
  Begin
    Case _1_e_operation Of
      Q4COMM_CHANNEL_DOCUMENT_READ: Result := fmOpenRead or fmShareDenyNone;
      Q4COMM_CHANNEL_DOCUMENT_WRITE: Result := fmCreate;
      Q4COMM_CHANNEL_DOCUMENT_READWRITE: Result := fmOpenReadWrite or fmShareDenyNone;
      Else Result := 0;
    End;
  End;

Procedure xportWriteU16( Const _1_o_stream: TStream; Const _2_e_value: word);
  Var
    _y_buffer: Array[0..1] Of byte;
  Begin
    _y_buffer[0] := byte( _2_e_value and $FF);
    _y_buffer[1] := byte( ( _2_e_value shr 8) and $FF);
    _1_o_stream.WriteBuffer( _y_buffer, SizeOf( _y_buffer));
  End;

Procedure xportWriteU32( Const _1_o_stream: TStream; Const _2_e_value: longword);
  Var
    _y_buffer: Array[0..3] Of byte;
  Begin
    _y_buffer[0] := byte( _2_e_value and $FF);
    _y_buffer[1] := byte( ( _2_e_value shr 8) and $FF);
    _y_buffer[2] := byte( ( _2_e_value shr 16) and $FF);
    _y_buffer[3] := byte( ( _2_e_value shr 24) and $FF);
    _1_o_stream.WriteBuffer( _y_buffer, SizeOf( _y_buffer));
  End;

Function xportReadI32( Const _1_o_stream: TStream): int64;
  Begin
    _1_o_stream.ReadBuffer( Result, SizeOf( Result));
  End;

Procedure xportWriteI32( Const _1_o_stream: TStream; Const _2_e_value: int64);
  Begin
    _1_o_stream.WriteBuffer( _2_e_value, SizeOf( _2_e_value));
  End;

Function xportReadU16( Const _1_o_stream: TStream): word;
  Var
    _y_buffer: Array[0..1] Of byte;
  Begin
    _1_o_stream.ReadBuffer( _y_buffer, SizeOf( _y_buffer));
    Result := word( _y_buffer[0]) or ( word( _y_buffer[1]) shl 8);
  End;

Function xportReadU32( Const _1_o_stream: TStream): longword;
  Var
    _y_buffer: Array[0..3] Of byte;
  Begin
    _1_o_stream.ReadBuffer( _y_buffer, SizeOf( _y_buffer));
    Result := longword( _y_buffer[0]) or ( longword( _y_buffer[1]) shl 8) or ( longword( _y_buffer[2]) shl 16) or ( longword( _y_buffer[3]) shl 24);
  End;

Function internalVariantToBytes( Const _1_v_value: variant): TBytes;
  Var
    _e_low:   int64;
    _e_high:  int64;
    _e_index: int64;
  Begin
    SetLength( Result, 0);

    If ( Variants.VarIsNull( _1_v_value) or Variants.VarIsEmpty( _1_v_value)) Then Exit;
    If ( not Variants.VarIsArray( _1_v_value)) Then Exit;

    _e_low := Variants.VarArrayLowBound( _1_v_value, 1);
    _e_high := Variants.VarArrayHighBound( _1_v_value, 1);
    If ( _e_high < _e_low) Then Exit;

    SetLength( Result, _e_high - _e_low + 1);
    For _e_index := _e_low To _e_high Do Result[_e_index - _e_low] := Variants.VarAsType( _1_v_value[_e_index], varByte);
  End;

Function stringToUTF8Bytes( Const _1_t_value: string): TBytes;
  Var
    _t_utf8: utf8string;
  Begin
    _t_utf8 := UTF8Encode( _1_t_value);
    SetLength( Result, Length( _t_utf8));
    If ( Length( _t_utf8) > 0) Then Move( _t_utf8[1], Result[0], Length( _t_utf8));
  End;

Function UTF8BytesToString( Const _1_y_bytes: TBytes): string;
  Var
    _t_utf8: utf8string;
  Begin
    If ( Length( _1_y_bytes) = 0) Then Exit( '');
    SetString( _t_utf8, pansichar( @_1_y_bytes[0]), Length( _1_y_bytes));
    Result := UTF8Decode( _t_utf8);
  End;

Procedure writeRawBytes( _1_o_stream: TStream; Const _2_y_bytes: TBytes);
  Begin
    If ( Length( _2_y_bytes) > 0) Then _1_o_stream.WriteBuffer( _2_y_bytes[0], Length( _2_y_bytes));
  End;

Function readExactBytes( _1_o_stream: TStream; Const _2_e_len: int64): TBytes;
  Begin
    SetLength( Result, _2_e_len);
    If ( _2_e_len > 0) Then _1_o_stream.ReadBuffer( Result[0], _2_e_len);
  End;

Function isEmptyDateValue( Const _1_v_value: variant): boolean;
  Var
    _t_value: string;
  Begin
    _t_value := SysUtils.Trim( Variants.VarToStr( _1_v_value));
    Result := ( _t_value = '') or ( _t_value = '00-00-00') or ( _t_value = '0000-00-00');
  End;

Function isEmptyTimeValue( Const _1_v_value: variant): boolean;
  Var
    _t_value: string;
  Begin
    _t_value := SysUtils.Trim( Variants.VarToStr( _1_v_value));
    Result := ( _t_value = '') or ( _t_value = '00:00:00');
  End;

Function realToExternalText( Const _1_v_value: variant): string;
  Var
    _y_format: TFormatSettings;
    _r_value:  double;
  Begin
    _y_format := DefaultFormatSettings;
    _y_format.DecimalSeparator := '.';
    _r_value := double( _1_v_value);
    Result := SysUtils.FloatToStr( _r_value, _y_format);
    If ( Result = '0') Then Result := '';
  End;

Function packetVariantToBytes( Const _1_v_data: variant): TBytes;
  Begin
    If ( Variants.VarIsNull( _1_v_data) or Variants.VarIsEmpty( _1_v_data)) Then Exit( nil);

    If ( Variants.VarIsArray( _1_v_data)) Then Exit( internalVariantToBytes( _1_v_data));
    Exit( stringToUTF8Bytes( Variants.VarToStr( _1_v_data)));
  End;

Function packetBytesToVariant( Const _1_y_bytes: TBytes): variant;
  Begin
    If ( Length( _1_y_bytes) = 0) Then Exit( '');

    If ( ge_importCharset <> Q4COMM_CHARSET_UTF8) Then Begin
      failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
      q4interruptions.assertRaise( 'q4communications.receivePacket: charset import non support',
        {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;

    Result := UTF8BytesToString( _1_y_bytes);
  End;


Function streamRemainingBytes( _1_o_stream: TStream): int64;
  Var
    _e_available: int64;
  Begin
    _e_available := _1_o_stream.Size - _1_o_stream.Position;
    If ( _e_available < 0) Then _e_available := 0;
    If ( _e_available > High( integer)) Then _e_available := High( integer);
    Result := integer( _e_available);
  End;

Function externalTypeCodeName( _1_e_typeCode: word): string;
  Begin
    Case _1_e_typeCode Of
      Q4X_FIELD_DELETED: Result := 'field deleted';
      Q4X_NULL: Result := 'null';
      Q4X_ALPHA_EMPTY: Result := 'alpha empty';
      Q4X_ALPHA_UTF8_U16: Result := 'alpha utf8 u16';
      Q4X_BOOLEAN: Result := 'boolean';
      Q4X_DATE_EMPTY: Result := 'date empty';
      Q4X_DATE_UTF8_U16: Result := 'date utf8 u16';
      Q4X_INTEGER_ZERO: Result := 'integer zero';
      Q4X_INTEGER_VALUE: Result := 'integer value';
      Q4X_INT64_ZERO: Result := 'int64 zero';
      Q4X_INT64_UTF8_U16: Result := 'int64 utf8 u16';
      Q4X_LONGINT_ZERO: Result := 'longint zero';
      Q4X_LONGINT_VALUE: Result := 'longint value';
      Q4X_REAL_ZERO: Result := 'real zero';
      Q4X_REAL_UTF8_U16: Result := 'real utf8 u16';
      Q4X_TIME_EMPTY: Result := 'time empty';
      Q4X_TIME_UTF8_U16: Result := 'time utf8 u16';
      Q4X_TEXT_EMPTY: Result := 'text empty';
      Q4X_TEXT_UTF8_U16: Result := 'text utf8 u16';
      Q4X_TEXT_UTF8_U32: Result := 'text utf8 u32';
      Q4X_OBJECT_EMPTY: Result := 'object empty';
      Q4X_OBJECT_JSON_U16: Result := 'object json u16';
      Q4X_OBJECT_JSON_U32: Result := 'object json u32';
      Q4X_BLOB_EMPTY: Result := 'blob empty';
      Q4X_BLOB_U16: Result := 'blob u16';
      Q4X_BLOB_U32: Result := 'blob u32';
      Q4X_PICTURE_EMPTY: Result := 'picture empty';
      Q4X_PICTURE_PNG_U16: Result := 'picture png u16';
      Q4X_PICTURE_PNG_U32: Result := 'picture png u32';
      Else Result := 'unknown';
    End;
  End;

Function isVariableTypeCode( Const _1_e_typeCode: word): boolean; Inline;
  Begin
    Result := _1_e_typeCode >= Q4X_VARIABLE_TYPE_OFFSET;
  End;

Function fieldTypeCodeToVariableTypeCode( Const _1_e_typeCode: word): word; Inline;
  Begin
    Result := _1_e_typeCode + Q4X_VARIABLE_TYPE_OFFSET;
  End;

Function variableTypeCodeToFieldTypeCode( Const _1_e_typeCode: word): word; Inline;
  Begin
    If ( _1_e_typeCode < Q4X_VARIABLE_TYPE_OFFSET) Then Exit( _1_e_typeCode);
    Result := _1_e_typeCode - Q4X_VARIABLE_TYPE_OFFSET;
  End;

Procedure writeRawTextU16( Const _1_o_stream: TStream; Const _2_e_typeCode: word; Const _3_t_value: string);
  Var
    y_bytes: TBytes;
  Begin
    y_bytes := stringToUTF8Bytes( _3_t_value);
    xportWriteU16( _1_o_stream, _2_e_typeCode);
    xportWriteU16( _1_o_stream, Length( y_bytes));
    writeRawBytes( _1_o_stream, y_bytes);
  End;

Procedure writeRawTextU32( Const _1_o_stream: TStream; Const _2_e_typeCode: word; Const _3_t_value: string);
  Var
    y_bytes: TBytes;
  Begin
    y_bytes := stringToUTF8Bytes( _3_t_value);
    xportWriteU16( _1_o_stream, _2_e_typeCode);
    xportWriteU32( _1_o_stream, Length( y_bytes));
    writeRawBytes( _1_o_stream, y_bytes);
  End;

Procedure writeRawBytesU16( Const _1_o_stream: TStream; Const _2_e_typeCode: word; Const _3_y_bytes: TBytes);
  Begin
    xportWriteU16( _1_o_stream, _2_e_typeCode);
    xportWriteU16( _1_o_stream, Length( _3_y_bytes));
    writeRawBytes( _1_o_stream, _3_y_bytes);
  End;

Procedure writeRawBytesU32( Const _1_o_stream: TStream; Const _2_e_typeCode: word; Const _3_y_bytes: TBytes);
  Begin
    xportWriteU16( _1_o_stream, _2_e_typeCode);
    xportWriteU32( _1_o_stream, Length( _3_y_bytes));
    writeRawBytes( _1_o_stream, _3_y_bytes);
  End;

Procedure writeExternalFieldValue( Const _1_o_stream: TStream; Const _2_y_binding: TFieldBinding; Const _3_v_value: variant);
  Var
    _y_bytes: TBytes;
    _t_value: string;
    _e_size:  int64;
  Begin
    Case _2_y_binding.FieldKind Of
      fkInteger: If ( VarIsNull( _3_v_value) or VarIsEmpty( _3_v_value) or ( smallint( _3_v_value) = 0)) Then xportWriteU16( _1_o_stream, Q4X_INTEGER_ZERO)
        Else Begin
          xportWriteU16( _1_o_stream, Q4X_INTEGER_VALUE);
          xportWriteU16( _1_o_stream, word( smallint( _3_v_value)));
        End;

      fkLongint: If ( VarIsNull( _3_v_value) or VarIsEmpty( _3_v_value) or ( longint( _3_v_value) = 0)) Then xportWriteU16( _1_o_stream, Q4X_LONGINT_ZERO)
        Else Begin
          xportWriteU16( _1_o_stream, Q4X_LONGINT_VALUE);
          xportWriteI32( _1_o_stream, longint( _3_v_value));
        End;

      fkInt64: Begin
        _t_value := Trim( VarToStr( _3_v_value));
        If ( ( _t_value = '') or ( _t_value = '0')) Then xportWriteU16( _1_o_stream, Q4X_INT64_ZERO)
        Else
          writeRawTextU16( _1_o_stream, Q4X_INT64_UTF8_U16, _t_value);
      End;

      fkReal: Begin
        _t_value := realToExternalText( _3_v_value);
        If ( _t_value = '') Then xportWriteU16( _1_o_stream, Q4X_REAL_ZERO)
        Else
          writeRawTextU16( _1_o_stream, Q4X_REAL_UTF8_U16, _t_value);
      End;

      fkBoolean: Begin
        xportWriteU16( _1_o_stream, Q4X_BOOLEAN);
        If ( VariantToBooleanSafe( _3_v_value)) Then xportWriteU16( _1_o_stream, 1)
        Else
          xportWriteU16( _1_o_stream, 0);
      End;

      fkDate: If ( isEmptyDateValue( _3_v_value)) Then xportWriteU16( _1_o_stream, Q4X_DATE_EMPTY)
        Else
          writeRawTextU16( _1_o_stream, Q4X_DATE_UTF8_U16, q4dateAndTime.normalizeDate( VarToStr( _3_v_value)));

      fkTime: If ( isEmptyTimeValue( _3_v_value)) Then xportWriteU16( _1_o_stream, Q4X_TIME_EMPTY)
        Else
          writeRawTextU16( _1_o_stream, Q4X_TIME_UTF8_U16, q4dateAndTime.normalizeTime( VarToStr( _3_v_value)));

      fkText: Begin
        _t_value := VarToStr( _3_v_value);
        _y_bytes := stringToUTF8Bytes( _t_value);
        _e_size := Length( _y_bytes);
        If ( _e_size = 0) Then xportWriteU16( _1_o_stream, Q4X_TEXT_EMPTY)
        Else If ( _e_size < 32000) Then writeRawTextU16( _1_o_stream, Q4X_TEXT_UTF8_U16, _t_value)
        Else
          writeRawTextU32( _1_o_stream, Q4X_TEXT_UTF8_U32, _t_value);
      End;

      fkBlob: Begin
        _y_bytes := internalVariantToBytes( _3_v_value);
        _e_size := Length( _y_bytes);
        If ( _e_size = 0) Then xportWriteU16( _1_o_stream, Q4X_BLOB_EMPTY)
        Else If ( _e_size < 32000) Then writeRawBytesU16( _1_o_stream, Q4X_BLOB_U16, _y_bytes)
        Else
          writeRawBytesU32( _1_o_stream, Q4X_BLOB_U32, _y_bytes);
      End;

      Else failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
        q4interruptions.assertRaise( 'q4communications.writeExternalFieldValue: FieldKind non géré', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
  End;

Function readExternalFieldValue( Const _1_o_stream: TStream; Const _2_y_binding: TFieldBinding): variant;
  Var
    _e_typeCode: word;
    _e_size16:   word;
    _e_size32:   longword;
    _y_bytes:    TBytes;
  Begin
    _e_typeCode := xportReadU16( _1_o_stream);
    Case _e_typeCode Of
      Q4X_FIELD_DELETED: Result := q4record.readBindingValue( _2_y_binding);
      Q4X_NULL: Result := Null;
      Q4X_ALPHA_EMPTY, Q4X_DATE_EMPTY, Q4X_TIME_EMPTY, Q4X_TEXT_EMPTY: Result := '';
      Q4X_ALPHA_UTF8_U16, Q4X_DATE_UTF8_U16, Q4X_INT64_UTF8_U16, Q4X_REAL_UTF8_U16, Q4X_TIME_UTF8_U16, Q4X_TEXT_UTF8_U16, Q4X_OBJECT_JSON_U16: Begin
        _e_size16 := xportReadU16( _1_o_stream);
        _y_bytes := readExactBytes( _1_o_stream, _e_size16);
        Result := UTF8BytesToString( _y_bytes);
      End;
      Q4X_TEXT_UTF8_U32, Q4X_OBJECT_JSON_U32: Begin
        _e_size32 := xportReadU32( _1_o_stream);
        _y_bytes := readExactBytes( _1_o_stream, _e_size32);
        Result := UTF8BytesToString( _y_bytes);
      End;
      Q4X_BOOLEAN: Result := ( xportReadU16( _1_o_stream) <> 0);
      Q4X_INTEGER_ZERO: Result := 0;
      Q4X_INTEGER_VALUE: Result := smallint( xportReadU16( _1_o_stream));
      Q4X_INT64_ZERO: Result := '0';
      Q4X_LONGINT_ZERO: Result := 0;
      Q4X_LONGINT_VALUE: Result := xportReadI32( _1_o_stream);
      Q4X_REAL_ZERO: Result := 0;
      Q4X_OBJECT_EMPTY: If ( _2_y_binding.FieldKind = fkText) Then Result := ''
        Else
          Result := Null;
      Q4X_BLOB_EMPTY, Q4X_PICTURE_EMPTY: Result := q4coreLanguage.BytesToVariant( nil);
      Q4X_BLOB_U16, Q4X_PICTURE_PNG_U16: Begin
        _e_size16 := xportReadU16( _1_o_stream);
        _y_bytes := readExactBytes( _1_o_stream, _e_size16);
        Result := q4coreLanguage.BytesToVariant( _y_bytes);
      End;
      Q4X_BLOB_U32, Q4X_PICTURE_PNG_U32: Begin
        _e_size32 := xportReadU32( _1_o_stream);
        _y_bytes := readExactBytes( _1_o_stream, _e_size32);
        Result := q4coreLanguage.BytesToVariant( _y_bytes);
      End;
      Else failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
        q4interruptions.assertRaise( 'q4communications.readExternalFieldValue: typeCode inconnu: ' + IntToStr( _e_typeCode) + ' (' + externalTypeCodeName( _e_typeCode) +
          ')', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
  End;

Procedure writeExternalVariableToStream( Const _1_o_stream: TStream; Const _2_v_value: variant; Const _3_b_picture: boolean = False);
  Var
    _e_varType:  int64;
    _y_bytes:    TBytes;
    _t_value:    string;
    _e_i64:      int64;
    _e_i32:      longint;
    _d_value:    TDateTime;
    _e_typeCode: word;
  Begin
    If ( VarIsNull( _2_v_value) or VarIsEmpty( _2_v_value)) Then Begin
      xportWriteU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_NULL));
      Exit;
    End;

    If ( VarIsArray( _2_v_value)) Then Begin
      _y_bytes := internalVariantToBytes( _2_v_value);
      If ( _3_b_picture) Then Begin
        If ( Length( _y_bytes) = 0) Then _e_typeCode := Q4X_PICTURE_EMPTY
        Else If ( Length( _y_bytes) < 32000) Then _e_typeCode := Q4X_PICTURE_PNG_U16
        Else
          _e_typeCode := Q4X_PICTURE_PNG_U32;
      End Else If ( Length( _y_bytes) = 0) Then _e_typeCode := Q4X_BLOB_EMPTY
      Else If ( Length( _y_bytes) < 32000) Then _e_typeCode := Q4X_BLOB_U16
      Else
        _e_typeCode := Q4X_BLOB_U32;
      Case _e_typeCode Of
        Q4X_PICTURE_EMPTY, Q4X_BLOB_EMPTY: xportWriteU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( _e_typeCode));
        Q4X_PICTURE_PNG_U16, Q4X_BLOB_U16: writeRawBytesU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( _e_typeCode), _y_bytes);
        Else writeRawBytesU32( _1_o_stream, fieldTypeCodeToVariableTypeCode( _e_typeCode), _y_bytes);
      End;
      Exit;
    End;

    _e_varType := VarType( _2_v_value) and varTypeMask;
    Case _e_varType Of
      varBoolean: Begin
        xportWriteU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_BOOLEAN));
        If ( boolean( _2_v_value)) Then xportWriteU16( _1_o_stream, 1)
        Else
          xportWriteU16( _1_o_stream, 0);
      End;
      varByte, varSmallint, varShortInt, varWord: If ( longint( _2_v_value) = 0) Then xportWriteU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_INTEGER_ZERO))
        Else Begin
          xportWriteU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_INTEGER_VALUE));
          xportWriteU16( _1_o_stream, word( smallint( _2_v_value)));
        End;
      varInteger, varLongWord: Begin
        _e_i64 := int64( _2_v_value);
        If ( _e_i64 = 0) Then xportWriteU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_LONGINT_ZERO))
        Else If ( ( _e_i64 >= Low( longint)) and ( _e_i64 <= High( longint))) Then Begin
          xportWriteU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_LONGINT_VALUE));
          xportWriteI32( _1_o_stream, longint( _e_i64));
        End Else
          writeRawTextU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_INT64_UTF8_U16), IntToStr( _e_i64));
      End;
      varInt64, varQWord: Begin
        _e_i64 := int64( _2_v_value);
        If ( _e_i64 = 0) Then xportWriteU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_INT64_ZERO))
        Else
          writeRawTextU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_INT64_UTF8_U16), IntToStr( _e_i64));
      End;
      varSingle, varDouble, varCurrency: Begin
        _t_value := realToExternalText( _2_v_value);
        If ( _t_value = '') Then xportWriteU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_REAL_ZERO))
        Else
          writeRawTextU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_REAL_UTF8_U16), _t_value);
      End;
      varDate: Begin
        _d_value := VarToDateTime( _2_v_value);
        If ( Frac( _d_value) = 0) Then Begin
          _t_value := FormatDateTime( 'yyyy-mm-dd', _d_value);
          If ( isEmptyDateValue( _t_value)) Then xportWriteU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_DATE_EMPTY))
          Else
            writeRawTextU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_DATE_UTF8_U16), _t_value);
        End Else If ( Trunc( _d_value) = 0) Then Begin
          _t_value := FormatDateTime( 'hh":"nn":"ss', _d_value);
          If ( isEmptyTimeValue( _t_value)) Then xportWriteU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_TIME_EMPTY))
          Else
            writeRawTextU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_TIME_UTF8_U16), _t_value);
        End Else Begin
          failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
          q4interruptions.assertRaise( 'q4communications.sendVariable: datetime complet non supporté', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
        End;
      End;
      varOleStr, varString, varUString: Begin
        _y_bytes := stringToUTF8Bytes( VarToStr( _2_v_value));
        If ( Length( _y_bytes) = 0) Then xportWriteU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_TEXT_EMPTY))
        Else If ( Length( _y_bytes) < 32000) Then writeRawTextU16( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_TEXT_UTF8_U16), VarToStr( _2_v_value))
        Else
          writeRawTextU32( _1_o_stream, fieldTypeCodeToVariableTypeCode( Q4X_TEXT_UTF8_U32), VarToStr( _2_v_value));
      End;
      Else failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
        q4interruptions.assertRaise( 'q4communications.sendVariable: type Variant non supporté (VarType=' + IntToStr( _e_varType) + ')', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
  End;

Function readExternalVariableFromStream( Const _1_o_stream: TStream): variant;
  Var
    _e_typeCode: word;
    _e_baseType: word;
    _e_size16:   word;
    _e_size32:   longword;
    _y_bytes:    TBytes;
    _y_format:   TFormatSettings;
  Begin
    _e_typeCode := xportReadU16( _1_o_stream);
    If ( not isVariableTypeCode( _e_typeCode)) Then Begin
      failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
      q4interruptions.assertRaise( 'q4communications.receiveVariable: code champ reçu là où une variable était attendue: ' + IntToStr( _e_typeCode), {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
    _e_baseType := variableTypeCodeToFieldTypeCode( _e_typeCode);
    Case _e_baseType Of
      Q4X_NULL: Result := Null;
      Q4X_ALPHA_EMPTY, Q4X_DATE_EMPTY, Q4X_TIME_EMPTY, Q4X_TEXT_EMPTY: Result := '';
      Q4X_ALPHA_UTF8_U16, Q4X_DATE_UTF8_U16, Q4X_TIME_UTF8_U16, Q4X_TEXT_UTF8_U16, Q4X_OBJECT_JSON_U16: Begin
        _e_size16 := xportReadU16( _1_o_stream);
        _y_bytes := readExactBytes( _1_o_stream, _e_size16);
        Result := UTF8BytesToString( _y_bytes);
      End;
      Q4X_TEXT_UTF8_U32, Q4X_OBJECT_JSON_U32: Begin
        _e_size32 := xportReadU32( _1_o_stream);
        _y_bytes := readExactBytes( _1_o_stream, _e_size32);
        Result := UTF8BytesToString( _y_bytes);
      End;
      Q4X_BOOLEAN: Result := ( xportReadU16( _1_o_stream) <> 0);
      Q4X_INTEGER_ZERO: Result := 0;
      Q4X_INTEGER_VALUE: Result := smallint( xportReadU16( _1_o_stream));
      Q4X_INT64_ZERO: Result := int64( 0);
      Q4X_INT64_UTF8_U16: Begin
        _e_size16 := xportReadU16( _1_o_stream);
        _y_bytes := readExactBytes( _1_o_stream, _e_size16);
        Result := StrToInt64( UTF8BytesToString( _y_bytes));
      End;
      Q4X_LONGINT_ZERO: Result := longint( 0);
      Q4X_LONGINT_VALUE: Result := xportReadI32( _1_o_stream);
      Q4X_REAL_ZERO: Result := 0.0;
      Q4X_REAL_UTF8_U16: Begin
        _e_size16 := xportReadU16( _1_o_stream);
        _y_bytes := readExactBytes( _1_o_stream, _e_size16);
        _y_format := DefaultFormatSettings;
        _y_format.DecimalSeparator := '.';
        Result := StrToFloat( UTF8BytesToString( _y_bytes), _y_format);
      End;
      Q4X_OBJECT_EMPTY: Result := Null;
      Q4X_BLOB_EMPTY, Q4X_PICTURE_EMPTY: Result := q4coreLanguage.BytesToVariant( nil);
      Q4X_BLOB_U16, Q4X_PICTURE_PNG_U16: Begin
        _e_size16 := xportReadU16( _1_o_stream);
        _y_bytes := readExactBytes( _1_o_stream, _e_size16);
        Result := q4coreLanguage.BytesToVariant( _y_bytes);
      End;
      Q4X_BLOB_U32, Q4X_PICTURE_PNG_U32: Begin
        _e_size32 := xportReadU32( _1_o_stream);
        _y_bytes := readExactBytes( _1_o_stream, _e_size32);
        Result := q4coreLanguage.BytesToVariant( _y_bytes);
      End;
      Else failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
        q4interruptions.assertRaise( 'q4communications.receiveVariable: typeCode non supporté: ' + IntToStr( _e_typeCode) + ' (' + externalTypeCodeName( _e_baseType) +
          ')', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
  End;


Function readEncodedValueFromChannel( Const _1_o_channel: Tq4CommunicationChannel; Const _2_b_variable: boolean): TMemoryStream;
  Var
    _y_header, _y_more: TBytes;
    _e_typeCode, _e_baseType: word;
    _e_size16: word;
    _e_size32: longword;
  Begin
    Result := TMemoryStream.Create;
    _y_header := channelReadExactBytes( _1_o_channel, 2);
    Result.WriteBuffer( _y_header[0], 2);
    _e_typeCode := word( _y_header[0]) or ( word( _y_header[1]) shl 8);
    If ( _2_b_variable) Then _e_baseType := variableTypeCodeToFieldTypeCode( _e_typeCode)
    Else
      _e_baseType := _e_typeCode;
    Case _e_baseType Of
      Q4X_NULL, Q4X_ALPHA_EMPTY, Q4X_DATE_EMPTY, Q4X_INTEGER_ZERO, Q4X_INT64_ZERO,
      Q4X_LONGINT_ZERO, Q4X_REAL_ZERO, Q4X_TIME_EMPTY, Q4X_TEXT_EMPTY, Q4X_OBJECT_EMPTY,
      Q4X_BLOB_EMPTY, Q4X_PICTURE_EMPTY: ;
      Q4X_BOOLEAN, Q4X_INTEGER_VALUE: Begin
        _y_more := channelReadExactBytes( _1_o_channel, 2);
        Result.WriteBuffer( _y_more[0], Length( _y_more));
      End;
      Q4X_LONGINT_VALUE: Begin
        _y_more := channelReadExactBytes( _1_o_channel, 4);
        Result.WriteBuffer( _y_more[0], Length( _y_more));
      End;
      Q4X_ALPHA_UTF8_U16, Q4X_DATE_UTF8_U16, Q4X_INT64_UTF8_U16, Q4X_REAL_UTF8_U16, Q4X_TIME_UTF8_U16,
      Q4X_TEXT_UTF8_U16, Q4X_OBJECT_JSON_U16, Q4X_BLOB_U16, Q4X_PICTURE_PNG_U16: Begin
        _y_more := channelReadExactBytes( _1_o_channel, 2);
        Result.WriteBuffer( _y_more[0], 2);
        _e_size16 := word( _y_more[0]) or ( word( _y_more[1]) shl 8);
        If ( _e_size16 > 0) Then Begin
          _y_more := channelReadExactBytes( _1_o_channel, _e_size16);
          Result.WriteBuffer( _y_more[0], Length( _y_more));
        End;
      End;
      Q4X_TEXT_UTF8_U32, Q4X_OBJECT_JSON_U32, Q4X_BLOB_U32, Q4X_PICTURE_PNG_U32: Begin
        _y_more := channelReadExactBytes( _1_o_channel, 4);
        Result.WriteBuffer( _y_more[0], 4);
        _e_size32 := longword( _y_more[0]) or ( longword( _y_more[1]) shl 8) or ( longword( _y_more[2]) shl 16) or ( longword( _y_more[3]) shl 24);
        If ( _e_size32 > 0) Then Begin
          _y_more := channelReadExactBytes( _1_o_channel, _e_size32);
          Result.WriteBuffer( _y_more[0], Length( _y_more));
        End;
      End;
      Else failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
        q4interruptions.assertRaise( 'q4communications: typeCode canal non supporté: ' + IntToStr( _e_typeCode), {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
    Result.Position := 0;
  End;

Procedure writeMemoryStreamToChannel( Const _1_o_channel: Tq4CommunicationChannel; Const _2_o_stream: TMemoryStream);
  Var
    _y_bytes: TBytes;
  Begin
    SetLength( _y_bytes, _2_o_stream.Size);
    _2_o_stream.Position := 0;
    If ( _2_o_stream.Size > 0) Then _2_o_stream.ReadBuffer( _y_bytes[0], _2_o_stream.Size);
    channelWriteBytes( _1_o_channel, _y_bytes);
  End;

Function nativeListSerialPorts: TStringList;

  Procedure addMatches( Const _1_t_mask: string; Const _2_o_values: TStringList);
    Var
      _r_search: TSearchRec;
      _e_status: int64;
    Begin
      _e_status := FindFirst( _1_t_mask, faAnyFile, _r_search);
      Try
        While ( _e_status = 0) Do Begin
          If ( ( _r_search.Name <> '.') and ( _r_search.Name <> '..')) Then _2_o_values.Add( ExtractFilePath( _1_t_mask) + _r_search.Name);
          _e_status := FindNext( _r_search);
        End;
      Finally
        FindClose( _r_search);
      End;
    End;

  Var
    e_index: integer;
  Begin
    Result := TStringList.Create;
    Result.Sorted := True;
    Result.Duplicates := dupIgnore;
    {$IFDEF Windows}
 for e_index := 1 to 256 do Result.Add('COM' + IntToStr(e_index)); 
    {$ENDIF}
    {$IFDEF Linux}
 addMatches('/dev/ttyS*', Result); addMatches('/dev/ttyUSB*', Result); addMatches('/dev/ttyACM*', Result); addMatches('/dev/ttyAMA*', Result); addMatches('/dev/rfcomm*', Result); 
    {$ENDIF}
    {$IFDEF Darwin}
 addMatches('/dev/tty.*', Result); addMatches('/dev/cu.*', Result); 
    {$ENDIF}
  End;

Procedure sendRecordExterne( Const _1_o_stream: TStream; _2_p_table: Pointer);
  Var
    _p_runtime: Pq4recordRuntime;
    _o_payload: TMemoryStream;
    _e_bindingIndex: int64;
    _y_binding: TFieldBinding;
    _v_value: variant;
  Begin
    resetRuntimeStatus;
    _p_runtime := runtimeOf( _2_p_table);
    _o_payload := TMemoryStream.Create;
    Try
      Try
        For _e_bindingIndex := 0 To High( _p_runtime^._Bindings) Do Begin
          _y_binding := _p_runtime^._Bindings[_e_bindingIndex];
          _v_value := q4record.readBindingValue( _y_binding);
          writeExternalFieldValue( _o_payload, _y_binding, _v_value);
        End;
        xportWriteU32( _1_o_stream, _o_payload.Size);
        _o_payload.Position := 0;
        _1_o_stream.CopyFrom( _o_payload, _o_payload.Size);
        q4coreLanguage.OK := 1;
      Except
        on E: Exception Do Begin
          If ( q4coreLanguage.Error = 0) Then failRuntimeStatus( Q4COMM_ERROR_IO);
          Raise;
        End;
      End;
    Finally
      _o_payload.Free;
    End;
  End;

Procedure receiveRecordExterne( Const _1_o_stream: TStream; _2_p_table: Pointer);
  Var
    _p_runtime: Pq4recordRuntime;
    _o_payload: TMemoryStream;
    _e_payloadSize: longword;
    _e_bindingIndex: int64;
    _y_binding: TFieldBinding;
    _v_value: variant;
  Begin
    resetRuntimeStatus;
    _p_runtime := runtimeOf( _2_p_table);
    _e_payloadSize := xportReadU32( _1_o_stream);
    _o_payload := TMemoryStream.Create;
    Try
      Try
        If ( _e_payloadSize > 0) Then Begin
          _o_payload.CopyFrom( _1_o_stream, _e_payloadSize);
          _o_payload.Position := 0;
        End;
        For _e_bindingIndex := 0 To High( _p_runtime^._Bindings) Do Begin
          _y_binding := _p_runtime^._Bindings[_e_bindingIndex];
          _v_value := readExternalFieldValue( _o_payload, _y_binding);
          q4record.writeBindingValue( _y_binding, _v_value);
        End;
        q4coreLanguage.OK := 1;
      Except
        on E: Exception Do Begin
          If ( q4coreLanguage.Error = 0) Then failRuntimeStatus( Q4COMM_ERROR_IO);
          Raise;
        End;
      End;
    Finally
      _o_payload.Free;
    End;
  End;

Function setChannel( _1_e_operation: int64; Const _2_t_document: string = ''): int64;
  Var
    _o_channel: Tq4CommunicationChannel;
    _e_mode:    word;
  Begin
    resetRuntimeStatus;

    If ( _1_e_operation = Q4COMM_CHANNEL_CLOSED) Then Begin
      closeChannel;
      Exit( Q4COMM_CHANNEL_CLOSED);
    End;

    If ( not ( _1_e_operation in [Q4COMM_CHANNEL_DOCUMENT_READ, Q4COMM_CHANNEL_DOCUMENT_WRITE, Q4COMM_CHANNEL_DOCUMENT_READWRITE])) Then Begin
      failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
      q4interruptions.assertRaise( 'q4communications.setChannel: mode non support ; v1 document-first uniquement',
        {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;

    If ( SysUtils.Trim( _2_t_document) = '') Then Begin
      failRuntimeStatus( Q4COMM_ERROR_BAD_PARAMETER);
      q4interruptions.assertRaise( 'q4communications.setChannel: document vide', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;

    closeChannel;
    _e_mode := openFileModeForChannel( _1_e_operation);

    _o_channel := Tq4CommunicationChannel.Create;
    Try
      _o_channel.e_ref := ge_nextChannelRef;
      Inc( ge_nextChannelRef);
      _o_channel.e_mode := _1_e_operation;
      _o_channel.t_document := _2_t_document;
      _o_channel.o_stream := TFileStream.Create( _2_t_document, _e_mode);
      go_channels.Add( _o_channel);
      ge_currentChannelRef := _o_channel.e_ref;
      Result := _o_channel.e_ref;
      q4coreLanguage.OK := 1;
    Except
      on E: Exception Do Begin
        _o_channel.Free;
        failRuntimeStatus( Q4COMM_ERROR_IO);
        Raise;
      End;
    End;
  End;


Function setSerialChannel( Const _1_t_port: string; _2_e_baudRate: int64 = 9600; _3_e_dataBits: int64 = 8; _4_t_parity: string = 'N'; _5_e_stopBits: int64 = 1): int64;
  Var
    _o_channel: Tq4CommunicationChannel;
  Begin
    resetRuntimeStatus;
    If ( SysUtils.Trim( _1_t_port) = '') Then Begin
      failRuntimeStatus( Q4COMM_ERROR_BAD_PARAMETER);
      q4interruptions.assertRaise( 'q4communications.setSerialChannel: port vide', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
    If ( ( _2_e_baudRate <= 0) or not ( _3_e_dataBits in [5..8]) or not ( _5_e_stopBits in [1, 2])) Then Begin
      failRuntimeStatus( Q4COMM_ERROR_BAD_PARAMETER);
      q4interruptions.assertRaise( 'q4communications.setSerialChannel: paramètres série invalides', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
    closeChannel;
    _o_channel := Tq4CommunicationChannel.Create;
    Try
      _o_channel.e_ref := ge_nextChannelRef;
      Inc( ge_nextChannelRef);
      _o_channel.e_mode := Q4COMM_CHANNEL_SERIAL;
      _o_channel.b_isSerial := True;
      _o_channel.t_serialPort := _1_t_port;
      {$IFDEF UNIX}
    _o_channel.e_serialHandle := nativeSerialOpen(_1_t_port);
    if (_o_channel.e_serialHandle = -1) then begin
      failRuntimeStatus(Q4COMM_ERROR_IO);
      q4interruptions.assertRaise('q4communications.setSerialChannel: ouverture impossible: ' + _1_t_port, {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    end;
{$ELSE}
      failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
      q4interruptions.assertRaise( 'q4communications.setSerialChannel: backend série maison indisponible sur cet OS', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
      {$ENDIF}
      go_channels.Add( _o_channel);
      ge_currentChannelRef := _o_channel.e_ref;
      Result := _o_channel.e_ref;
      q4coreLanguage.OK := 1;
    Except
      on E: Exception Do Begin
        _o_channel.Free;
        Raise;
      End;
    End;
  End;

Procedure closeChannel;
  Var
    _e_index:   int64;
    _o_channel: Tq4CommunicationChannel;
  Begin
    If ( go_channels = nil) Then Begin
      ge_currentChannelRef := Q4COMM_CHANNEL_CLOSED;
      Exit;
    End;

    For _e_index := go_channels.Count - 1 Downto 0 Do Begin
      _o_channel := Tq4CommunicationChannel( go_channels[_e_index]);
      If ( _o_channel.e_ref = ge_currentChannelRef) Then Begin
        go_channels.Delete( _e_index);
        _o_channel.Free;
        Break;
      End;
    End;

    ge_currentChannelRef := Q4COMM_CHANNEL_CLOSED;
    q4coreLanguage.OK := 1;
    q4coreLanguage.Error := 0;
  End;

Procedure setTimeout( _1_e_timeoutMs: int64);
  Begin
    resetRuntimeStatus;
    If ( _1_e_timeoutMs < 0) Then Begin
      failRuntimeStatus( Q4COMM_ERROR_BAD_PARAMETER);
      q4interruptions.assertRaise( 'q4communications.setTimeout: timeout ngatif', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;

    ge_timeoutMs := _1_e_timeoutMs;
  End;

Procedure useCharacterSet( Const _1_t_importCharset: string = 'UTF-8'; Const _2_t_exportCharset: string = 'UTF-8');
  Begin
    resetRuntimeStatus;
    ge_importCharset := requireUTF8Charset( _1_t_importCharset);
    ge_exportCharset := requireUTF8Charset( _2_t_exportCharset);
  End;

Procedure sendPacket( Const _1_v_data: variant; _2_e_docRef: int64 = Q4COMM_CHANNEL_CLOSED);
  Var
    _o_channel: Tq4CommunicationChannel;
    _y_bytes:   TBytes;
  Begin
    resetRuntimeStatus;
    _o_channel := requireChannel( _2_e_docRef);
    ensureWritable( _o_channel);

    If ( ge_exportCharset <> Q4COMM_CHARSET_UTF8) Then Begin
      failRuntimeStatus( Q4COMM_ERROR_UNSUPPORTED);
      q4interruptions.assertRaise( 'q4communications.sendPacket: charset export non support',
        {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;

    _y_bytes := packetVariantToBytes( _1_v_data);
    Try
      channelWriteBytes( _o_channel, _y_bytes);
      q4coreLanguage.OK := 1;
    Except
      on E: Exception Do Begin
        failRuntimeStatus( Q4COMM_ERROR_IO);
        Raise;
      End;
    End;
  End;

Function receivePacket( _1_e_numBytes: int64; _2_e_docRef: int64 = Q4COMM_CHANNEL_CLOSED): variant;
  Var
    _o_channel:   Tq4CommunicationChannel;
    _y_bytes:     TBytes;
    _e_available: int64;
    _e_toRead:    int64;
  Begin
    resetRuntimeStatus;
    _o_channel := requireChannel( _2_e_docRef);
    ensureReadable( _o_channel);

    If ( _1_e_numBytes < 0) Then Begin
      failRuntimeStatus( Q4COMM_ERROR_BAD_PARAMETER);
      q4interruptions.assertRaise( 'q4communications.receivePacket: taille ngative', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;

    If ( channelIsDocument( _o_channel)) Then Begin
      _e_available := _o_channel.o_stream.Size - _o_channel.o_stream.Position;
      If ( _e_available < 0) Then _e_available := 0;
      _e_toRead := _1_e_numBytes;
      If ( _e_toRead > _e_available) Then _e_toRead := _e_available;
    End Else
      _e_toRead := _1_e_numBytes;

    Try
      _y_bytes := channelReadExactBytes( _o_channel, _e_toRead);
      Result := packetBytesToVariant( _y_bytes);
      q4coreLanguage.OK := 1;
    Except
      on E: Exception Do Begin
        failRuntimeStatus( Q4COMM_ERROR_IO);
        Raise;
      End;
    End;
  End;

Function getSerialPortMapping: string;
  Var
    o_ports: TStringList;
  Begin
    resetRuntimeStatus;
    o_ports := nativeListSerialPorts;
    Try
      Result := o_ports.CommaText;
      q4coreLanguage.OK := 1;
    Finally
      o_ports.Free;
    End;
  End;

Function receiveBuffer: variant;
  Var
    o_channel:   Tq4CommunicationChannel;
    y_bytes:     TBytes;
    e_available: integer;
  Begin
    resetRuntimeStatus;
    o_channel := requireChannel( Q4COMM_CHANNEL_CLOSED);
    ensureReadable( o_channel);
    y_bytes := channelReadAvailableBytes( o_channel);
    Result := packetBytesToVariant( y_bytes);
    q4coreLanguage.OK := 1;
  End;

Procedure sendVariable( Const _1_v_value: variant);
  Var
    o_channel: Tq4CommunicationChannel;
    o_mem:     TMemoryStream;
  Begin
    resetRuntimeStatus;
    o_channel := requireChannel( Q4COMM_CHANNEL_CLOSED);
    ensureWritable( o_channel);
    If ( channelIsDocument( o_channel)) Then writeExternalVariableToStream( o_channel.o_stream, _1_v_value, False)
    Else Begin
      o_mem := TMemoryStream.Create;
      Try
        writeExternalVariableToStream( o_mem, _1_v_value, False);
        writeMemoryStreamToChannel( o_channel, o_mem);
      Finally
        o_mem.Free;
      End;
    End;
    q4coreLanguage.OK := 1;
  End;

Procedure sendPictureVariable( Const _1_v_picture: variant);
  Var
    o_channel: Tq4CommunicationChannel;
    o_mem:     TMemoryStream;
  Begin
    resetRuntimeStatus;
    o_channel := requireChannel( Q4COMM_CHANNEL_CLOSED);
    ensureWritable( o_channel);
    If ( channelIsDocument( o_channel)) Then writeExternalVariableToStream( o_channel.o_stream, _1_v_picture, True)
    Else Begin
      o_mem := TMemoryStream.Create;
      Try
        writeExternalVariableToStream( o_mem, _1_v_picture, True);
        writeMemoryStreamToChannel( o_channel, o_mem);
      Finally
        o_mem.Free;
      End;
    End;
    q4coreLanguage.OK := 1;
  End;

Function receiveVariable: variant;
  Var
    o_channel: Tq4CommunicationChannel;
    o_mem:     TMemoryStream;
  Begin
    resetRuntimeStatus;
    o_channel := requireChannel( Q4COMM_CHANNEL_CLOSED);
    ensureReadable( o_channel);
    If ( channelIsDocument( o_channel)) Then Result := readExternalVariableFromStream( o_channel.o_stream)
    Else Begin
      o_mem := readEncodedValueFromChannel( o_channel, True);
      Try
        Result := readExternalVariableFromStream( o_mem);
      Finally
        o_mem.Free;
      End;
    End;
    q4coreLanguage.OK := 1;
  End;

Procedure sendField( Const _1_p_field: Pointer);
  Var
    e_ownerTableId, e_bindingIndex: int64;
    y_field:   TFieldMeta;
    p_table:   Pointer;
    y_binding: TFieldBinding;
    o_channel: Tq4CommunicationChannel;
    o_mem:     TMemoryStream;
  Begin
    resetRuntimeStatus;
    o_channel := requireChannel( Q4COMM_CHANNEL_CLOSED);
    ensureWritable( o_channel);
    If ( not resolveFieldPointerGlobalLoadFirst( _1_p_field, e_ownerTableId, y_field)) Then Begin
      failRuntimeStatus( Q4COMM_ERROR_BAD_PARAMETER);
      q4interruptions.assertRaise( 'q4communications.sendField: champ introuvable', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
    If ( not resolveTablePointerBySourceTableId( e_ownerTableId, p_table)) Then Begin
      failRuntimeStatus( Q4COMM_ERROR_BAD_PARAMETER);
      q4interruptions.assertRaise( 'q4communications.sendField: table introuvable', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
    e_bindingIndex := findLocalBindingIndex( p_table, _1_p_field);
    If ( e_bindingIndex < 0) Then Begin
      failRuntimeStatus( Q4COMM_ERROR_BAD_PARAMETER);
      q4interruptions.assertRaise( 'q4communications.sendField: binding local introuvable', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
    y_binding := runtimeOf( p_table)^._Bindings[e_bindingIndex];
    If ( channelIsDocument( o_channel)) Then writeExternalFieldValue( o_channel.o_stream, y_binding, q4record.readBindingValue( y_binding))
    Else Begin
      o_mem := TMemoryStream.Create;
      Try
        writeExternalFieldValue( o_mem, y_binding, q4record.readBindingValue( y_binding));
        writeMemoryStreamToChannel( o_channel, o_mem);
      Finally
        o_mem.Free;
      End;
    End;
    q4coreLanguage.OK := 1;
  End;

Procedure receiveField( Const _1_p_field: Pointer);
  Var
    e_ownerTableId, e_bindingIndex: int64;
    y_field:   TFieldMeta;
    p_table:   Pointer;
    y_binding: TFieldBinding;
    o_channel: Tq4CommunicationChannel;
    v_value:   variant;
    o_mem:     TMemoryStream;
  Begin
    resetRuntimeStatus;
    o_channel := requireChannel( Q4COMM_CHANNEL_CLOSED);
    ensureReadable( o_channel);
    If ( not resolveFieldPointerGlobalLoadFirst( _1_p_field, e_ownerTableId, y_field)) Then Begin
      failRuntimeStatus( Q4COMM_ERROR_BAD_PARAMETER);
      q4interruptions.assertRaise( 'q4communications.receiveField: champ introuvable', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
    If ( not resolveTablePointerBySourceTableId( e_ownerTableId, p_table)) Then Begin
      failRuntimeStatus( Q4COMM_ERROR_BAD_PARAMETER);
      q4interruptions.assertRaise( 'q4communications.receiveField: table introuvable', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
    e_bindingIndex := findLocalBindingIndex( p_table, _1_p_field);
    If ( e_bindingIndex < 0) Then Begin
      failRuntimeStatus( Q4COMM_ERROR_BAD_PARAMETER);
      q4interruptions.assertRaise( 'q4communications.receiveField: binding local introuvable', {$I %CURRENTROUTINE%}, {$I %LINENUM%});
    End;
    y_binding := runtimeOf( p_table)^._Bindings[e_bindingIndex];
    If ( channelIsDocument( o_channel)) Then v_value := readExternalFieldValue( o_channel.o_stream, y_binding)
    Else Begin
      o_mem := readEncodedValueFromChannel( o_channel, False);
      Try
        v_value := readExternalFieldValue( o_mem, y_binding);
      Finally
        o_mem.Free;
      End;
    End;
    q4record.writeBindingValue( y_binding, v_value);
    q4coreLanguage.OK := 1;
  End;

Initialization
  go_channels := TList.Create;
  ge_timeoutMs := 0;
  ge_importCharset := Q4COMM_CHARSET_UTF8;
  ge_exportCharset := Q4COMM_CHARSET_UTF8;
  ge_currentChannelRef := Q4COMM_CHANNEL_CLOSED;

Finalization
  While ( ( go_channels <> nil) and ( go_channels.Count > 0)) Do Begin
    TObject( go_channels[go_channels.Count - 1]).Free;
    go_channels.Delete( go_channels.Count - 1);
  End;
  FreeAndNil( go_channels);

End.
