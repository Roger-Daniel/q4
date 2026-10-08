unit q4pasteboard;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

{
q4pasteboard
version du 2026/04/19-18:57

Mapping 4D → q4pasteboard -> statut
Command Number 4D,    4D Command,                      q4 API,                           Statut
------------------------------------------------------------------------------------------------
403,                 APPEND DATA TO PASTEBOARD,        appendDataToPasteboard,          OK,
402,                 CLEAR PASTEBOARD,                 clearPasteboard,                 OK,
976,                 Get file from pasteboard,         getFileFromPasteboard,           OK,
401,                 GET PASTEBOARD DATA,              getPasteboardData,               OK,
958,                 GET PASTEBOARD DATA TYPE,         getPasteboardDataType,           OK,
522,                 GET PICTURE FROM PASTEBOARD,      getPictureFromPasteboard,        OK,
524,                 Get text from pasteboard,         getTextFromPasteboard,           OK,
400,                 Pasteboard data size,             pasteboardDataSize,              OK,
975,                 SET FILE TO PASTEBOARD,           setFileToPasteboard,             OK,
521,                 SET PICTURE TO PASTEBOARD,        setPictureToPasteboard,          OK,
523,                 SET TEXT TO PASTEBOARD,           setTextToPasteboard,             OK,

Doc: https://developer.4d.com/docs/21/commands/theme/Pasteboard
}

procedure clearPasteboard;

procedure setTextToPasteboard(
   const _1_t_text : string
);

function getTextFromPasteboard : string;

procedure setPictureToPasteboard(
   const _1_y_picture : TBytes
);

function getPictureFromPasteboard : TBytes;

procedure appendDataToPasteboard(
   const _1_t_dataType : string;
   const _2_y_data : TBytes
);

function getPasteboardData(
   const _1_t_dataType : string
) : TBytes;

function getPasteboardDataType : TStringList;

function pasteboardDataSize(
   const _1_t_dataType : string
) : Int64;

procedure setFileToPasteboard(
   const _1_t_file : string;
   const _2_b_add : Boolean = False
);

function getFileFromPasteboard(
   const _1_e_index : Int64
) : string;

implementation

uses
  Clipbrd, Graphics;

var
   tt_fileList : array of string;
   ty_blobList : array of TBytes;
   tt_blobType : array of string;

{ INTERNAL HELPERS }

procedure InternalAddBlob(
   const _1_t_dataType : string;
   const _2_y_data : TBytes
);
var
   _e_len : Int64;
begin
   _e_len := Length(ty_blobList);

   SetLength(ty_blobList,_e_len+1);
   SetLength(tt_blobType,_e_len+1);

   ty_blobList[_e_len] := _2_y_data;
   tt_blobType[_e_len] := _1_t_dataType;
end;

function InternalFindBlob(
   const _1_t_dataType : string
) : Int64;
var
   _e_i : Int64;
begin
   Result := -1;

   for _e_i := 0 to High(tt_blobType) do
   begin
      if (tt_blobType[_e_i] = _1_t_dataType) then
      begin
         Result := _e_i;
         Exit;
      end;
   end;
end;

{ PUBLIC API }

procedure clearPasteboard;
begin
   //https://developer.4d.com/docs/21/commands/clear-pasteboard

   Clipboard.Clear;

   SetLength(tt_fileList,0);
   SetLength(ty_blobList,0);
   SetLength(tt_blobType,0);
end;

procedure setTextToPasteboard(
   const _1_t_text : string
);
begin
   //https://developer.4d.com/docs/21/commands/set-text-to-pasteboard

   Clipboard.AsText := _1_t_text;
end;

function getTextFromPasteboard : string;
begin
   //https://developer.4d.com/docs/21/commands/get-text-from-pasteboard

   Result := Clipboard.AsText;
end;

procedure setPictureToPasteboard(
   const _1_y_picture : TBytes
);
var
   _o_stream : TMemoryStream;
   _o_bitmap : TBitmap;
begin
   //https://developer.4d.com/docs/21/commands/set-picture-to-pasteboard

   _o_stream := TMemoryStream.Create;
   _o_bitmap := TBitmap.Create;

   try
      _o_stream.WriteBuffer(_1_y_picture[0],Length(_1_y_picture));
      _o_stream.Position := 0;

      _o_bitmap.LoadFromStream(_o_stream);

      Clipboard.Assign(_o_bitmap);
   finally
      _o_bitmap.Free;
      _o_stream.Free;
   end;
end;

function getPictureFromPasteboard : TBytes;
var
   _o_bitmap : TBitmap;
   _o_stream : TMemoryStream;
begin
   //https://developer.4d.com/docs/21/commands/get-picture-from-pasteboard

   _o_bitmap := TBitmap.Create;
   _o_stream := TMemoryStream.Create;

   try
      _o_bitmap.Assign(Clipboard);

      _o_bitmap.SaveToStream(_o_stream);

      SetLength(Result,_o_stream.Size);

      Move(_o_stream.Memory^,Result[0],_o_stream.Size);
   finally
      _o_bitmap.Free;
      _o_stream.Free;
   end;
end;

procedure appendDataToPasteboard(
   const _1_t_dataType : string;
   const _2_y_data : TBytes
);
begin
   //https://developer.4d.com/docs/21/commands/append-data-to-pasteboard

   InternalAddBlob(_1_t_dataType,_2_y_data);
end;

function getPasteboardData(
   const _1_t_dataType : string
) : TBytes;
var
   _e_index : Int64;
begin
   //https://developer.4d.com/docs/21/commands/get-pasteboard-data

   _e_index := InternalFindBlob(_1_t_dataType);

   if (_e_index >= 0) then
      Result := ty_blobList[_e_index]
   else
      SetLength(Result,0);
end;

function getPasteboardDataType : TStringList;
var
   _e_i : Int64;
begin
   //https://developer.4d.com/docs/21/commands/get-pasteboard-data-type

   Result := TStringList.Create;

   for _e_i := 0 to High(tt_blobType) do
      Result.Add(tt_blobType[_e_i]);
end;

function pasteboardDataSize(
   const _1_t_dataType : string
) : Int64;
var
   _e_index : Int64;
begin
   //https://developer.4d.com/docs/21/commands/pasteboard-data-size

   _e_index := InternalFindBlob(_1_t_dataType);

   if (_e_index >= 0) then
      Result := Length(ty_blobList[_e_index])
   else
      Result := 0;
end;

procedure setFileToPasteboard(
   const _1_t_file : string;
   const _2_b_add : Boolean
);
var
   _e_len : Int64;
begin
   //https://developer.4d.com/docs/21/commands/set-file-to-pasteboard

   if (not _2_b_add) then
      SetLength(tt_fileList,0);

   _e_len := Length(tt_fileList);

   SetLength(tt_fileList,_e_len+1);

   tt_fileList[_e_len] := _1_t_file;
end;

function getFileFromPasteboard(
   const _1_e_index : Int64
) : string;
begin
   //https://developer.4d.com/docs/21/commands/get-file-from-pasteboard

   if ((_1_e_index >= 0) and (_1_e_index <= High(tt_fileList))) then
      Result := tt_fileList[_1_e_index]
   else
      Result := '';
end;

end.

