Unit q4pictures;

{$mode objfpc}{$H+}

{
q4pictures
version du 2026/04/19-18:57

Mapping 4D → q4pictures
Command Number 4D,   4D Command,                       q4 API
--------------------------------------------------------------------------------
682,                 BLOB TO PICTURE,                  blobToPicture
987,                 COMBINE PICTURES,                 combinePictures
1002,                CONVERT PICTURE,                  convertPicture
679,                 CREATE THUMBNAIL,                 createThumbnail
1196,                Equal pictures,                   equalPictures
1171,                Get picture file name,            getPictureFileName
1406,                GET PICTURE FORMATS,              getPictureFormats
565,                 GET PICTURE FROM LIBRARY,         getPictureFromLibraryByRef/Name
1142,                GET PICTURE KEYWORDS,             getPictureKeywords
1122,                GET PICTURE METADATA,             getPictureMetadata
1113,                Is picture file,                  isPictureFile
992,                 PICTURE CODEC LIST,               pictureCodecList
564,                 PICTURE LIBRARY LIST,             pictureLibraryList
457,                 PICTURE PROPERTIES,               pictureProperties
356,                 Picture size,                     pictureSize
692,                 PICTURE TO BLOB,                  pictureToBlob
678,                 READ PICTURE FILE,                readPictureFile
567,                 REMOVE PICTURE FROM LIBRARY,      removePictureFromLibrary
1172,                SET PICTURE FILE NAME,            setPictureFileName
1121,                SET PICTURE METADATA,             setPictureMetadata
566,                 SET PICTURE TO LIBRARY,           setPictureToLibrary
988,                 TRANSFORM PICTURE,                transformPicture
680,                 WRITE PICTURE FILE,               writePictureFile

Doc: https://developer.4d.com/docs/21/commands/theme/Pictures
}

Interface

Uses
  Classes,
  SysUtils;

Type
  TPicture = TBytes;
  TTextArray = Array Of string;
  TInt64Array = Array Of int64;

  TPictureLibraryItem = Record
    e_ref: int64;
    t_name: string;
    y_picture: TPicture;
  End;

Const
  PICTURE_TRANSFORM_RESET = 0;
  PICTURE_TRANSFORM_SCALE = 1;
  PICTURE_TRANSFORM_TRANSLATE = 2;
  PICTURE_TRANSFORM_FLIP_HORIZONTAL = 3;
  PICTURE_TRANSFORM_FLIP_VERTICAL = 4;
  PICTURE_TRANSFORM_CROP = 100;
  PICTURE_TRANSFORM_FADE_TO_GREY_SCALE = 101;
  PICTURE_TRANSFORM_TRANSPARENCY = 102;

  THUMBNAIL_MODE_SCALED_TO_FIT_PROP_CENTERED = 6;

Procedure blobToPicture( Const _1_y_pictureBlob: TBytes; out _2_y_picture: TPicture; Const _3_t_codec: string);
Procedure combinePictures( out _1_y_resultingPict: TPicture; Const _2_y_pict1: TPicture; Const _3_e_operator: int64; Const _4_y_pict2: TPicture;
  Const _5_e_horOffset: int64; Const _6_e_vertOffset: int64);
Function convertPicture( Const _1_y_picture: TPicture; Const _2_t_codec: string; Const _3_r_compression: double): TPicture;
Procedure createThumbnail( Const _1_y_source: TPicture; out _2_y_dest: TPicture; Const _3_e_width: int64; Const _4_e_height: int64; Const _5_e_mode: int64; Const _6_e_depth: int64);
Function equalPictures( Const _1_y_picture1: TPicture; Const _2_y_picture2: TPicture; out _3_y_mask: TPicture): boolean;
Function getPictureFileName( Const _1_y_picture: TPicture): string;
Procedure getPictureFormats( Const _1_y_picture: TPicture; out _2_tt_codecIDs: TTextArray);
Procedure getPictureFromLibraryByRef( Const _1_e_picRef: int64; out _2_y_picture: TPicture);
Procedure getPictureFromLibraryByName( Const _1_t_picName: string; out _2_y_picture: TPicture);
Procedure getPictureKeywords( Const _1_y_picture: TPicture; out _2_tt_arrKeywords: TTextArray; Const _3_t_distinctOperator: string);
Function getPictureMetadata( Const _1_y_picture: TPicture; Const _2_t_metaName: string): string;
Function isPictureFile( Const _1_t_filePath: string; Const _2_t_validateOperator: string): boolean;
Procedure pictureCodecList( out _1_tt_codecArray: TTextArray; out _2_tt_namesArray: TTextArray; Const _3_t_readOperator: string);
Procedure pictureLibraryList( out _1_te_picRefs: TInt64Array; out _2_tt_picNames: TTextArray);
Procedure pictureProperties( Const _1_y_picture: TPicture; out _2_r_width: double; out _3_r_height: double; out _4_e_hOffset: int64; out _5_e_vOffset: int64; out _6_e_mode: int64);
Function pictureSize( Const _1_y_picture: TPicture): int64;
Procedure pictureToBlob( Const _1_y_picture: TPicture; out _2_y_pictureBlob: TBytes; Const _3_t_codec: string);
Procedure readPictureFile( Const _1_t_fileName: string; out _2_y_picture: TPicture; Const _3_t_anyTypeOperator: string);
Procedure removePictureFromLibraryByRef( Const _1_e_picRef: int64);
Procedure removePictureFromLibraryByName( Const _1_t_picName: string);
Procedure setPictureFileName( Const _1_y_picture: TPicture; Const _2_t_fileName: string);
Procedure setPictureMetadata( Const _1_y_picture: TPicture; Const _2_t_metaName: string; Const _3_t_metaContents: string);
Procedure setPictureToLibrary( Const _1_y_picture: TPicture; Const _2_e_picRef: int64; Const _3_t_picName: string);
Function transformPicture( Const _1_y_picture: TPicture; Const _2_e_operator: int64; Const _3_r_param1: double; Const _4_r_param2: double; Const _5_r_param3: double;
  Const _6_r_param4: double): TPicture;
Procedure writePictureFile( Const _1_t_fileName: string; Const _2_y_picture: TPicture; Const _3_t_codec: string);

Implementation

Var
  ty_library: Array Of TPictureLibraryItem;

Procedure blobToPicture( Const _1_y_pictureBlob: TBytes; out _2_y_picture: TPicture; Const _3_t_codec: string);
  Begin
    //https://developer.4d.com/docs/21/commands/blob-to-picture
    _2_y_picture := Copy( _1_y_pictureBlob);
  End;

Procedure combinePictures( out _1_y_resultingPict: TPicture; Const _2_y_pict1: TPicture; Const _3_e_operator: int64; Const _4_y_pict2: TPicture;
  Const _5_e_horOffset: int64; Const _6_e_vertOffset: int64);
  Begin
    //https://developer.4d.com/docs/21/commands/combine-pictures
    If ( Length( _2_y_pict1) > 0) Then _1_y_resultingPict := Copy( _2_y_pict1)
    Else
      _1_y_resultingPict := Copy( _4_y_pict2);
  End;

Function convertPicture( Const _1_y_picture: TPicture; Const _2_t_codec: string; Const _3_r_compression: double): TPicture;
  Begin
    //https://developer.4d.com/docs/21/commands/convert-picture
    Result := Copy( _1_y_picture);
  End;

Procedure createThumbnail( Const _1_y_source: TPicture; out _2_y_dest: TPicture; Const _3_e_width: int64; Const _4_e_height: int64; Const _5_e_mode: int64; Const _6_e_depth: int64);
  Begin
    //https://developer.4d.com/docs/21/commands/create-thumbnail
    _2_y_dest := Copy( _1_y_source);
  End;

Function equalPictures( Const _1_y_picture1: TPicture; Const _2_y_picture2: TPicture; out _3_y_mask: TPicture): boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/equal-pictures
    _3_y_mask := nil;

    If ( Length( _1_y_picture1) <> Length( _2_y_picture2)) Then Exit( False);

    If ( Length( _1_y_picture1) = 0) Then Exit( True);

    Result := ( CompareByte( _1_y_picture1[0], _2_y_picture2[0], Length( _1_y_picture1)) = 0);
  End;

Function getPictureFileName( Const _1_y_picture: TPicture): string;
  Begin
    //https://developer.4d.com/docs/21/commands/get-picture-file-name
    Result := '';
  End;

Procedure getPictureFormats( Const _1_y_picture: TPicture; out _2_tt_codecIDs: TTextArray);
  Begin
    //https://developer.4d.com/docs/21/commands/get-picture-formats
    SetLength( _2_tt_codecIDs, 1);
    _2_tt_codecIDs[0] := '.png';
  End;

Procedure getPictureFromLibraryByRef( Const _1_e_picRef: int64; out _2_y_picture: TPicture);
  Var
    i: integer;
  Begin
    For i := 0 To High( ty_library) Do If ( ty_library[i].e_ref = _1_e_picRef) Then _2_y_picture := Copy( ty_library[i].y_picture);
  End;

Procedure getPictureFromLibraryByName( Const _1_t_picName: string; out _2_y_picture: TPicture);
  Var
    i: integer;
  Begin
    For i := 0 To High( ty_library) Do If ( ty_library[i].t_name = _1_t_picName) Then _2_y_picture := Copy( ty_library[i].y_picture);
  End;

Procedure getPictureKeywords( Const _1_y_picture: TPicture; out _2_tt_arrKeywords: TTextArray; Const _3_t_distinctOperator: string);
  Begin
    //https://developer.4d.com/docs/21/commands/get-picture-keywords
    SetLength( _2_tt_arrKeywords, 0);
  End;

Function getPictureMetadata( Const _1_y_picture: TPicture; Const _2_t_metaName: string): string;
  Begin
    //https://developer.4d.com/docs/21/commands/get-picture-metadata
    Result := '';
  End;

Function isPictureFile( Const _1_t_filePath: string; Const _2_t_validateOperator: string): boolean;
  Begin
    //https://developer.4d.com/docs/21/commands/is-picture-file
    Result := FileExists( _1_t_filePath);
  End;

Procedure pictureCodecList( out _1_tt_codecArray: TTextArray; out _2_tt_namesArray: TTextArray; Const _3_t_readOperator: string);
  Begin
    //https://developer.4d.com/docs/21/commands/picture-codec-list
    SetLength( _1_tt_codecArray, 2);
    SetLength( _2_tt_namesArray, 2);

    _1_tt_codecArray[0] := '.png';
    _1_tt_codecArray[1] := '.jpg';

    _2_tt_namesArray[0] := 'PNG';
    _2_tt_namesArray[1] := 'JPEG';
  End;

Procedure pictureLibraryList( out _1_te_picRefs: TInt64Array; out _2_tt_picNames: TTextArray);
  Var
    i: integer;
  Begin
    SetLength( _1_te_picRefs, Length( ty_library));
    SetLength( _2_tt_picNames, Length( ty_library));

    For i := 0 To High( ty_library) Do Begin
      _1_te_picRefs[i] := ty_library[i].e_ref;
      _2_tt_picNames[i] := ty_library[i].t_name;
    End;
  End;

Procedure pictureProperties( Const _1_y_picture: TPicture; out _2_r_width: double; out _3_r_height: double; out _4_e_hOffset: int64; out _5_e_vOffset: int64; out _6_e_mode: int64);
  Begin
    //https://developer.4d.com/docs/21/commands/picture-properties
    _2_r_width := 0;
    _3_r_height := 0;
    _4_e_hOffset := 0;
    _5_e_vOffset := 0;
    _6_e_mode := 0;
  End;

Function pictureSize( Const _1_y_picture: TPicture): int64;
  Begin
    //https://developer.4d.com/docs/21/commands/picture-size
    Result := Length( _1_y_picture);
  End;

Procedure pictureToBlob( Const _1_y_picture: TPicture; out _2_y_pictureBlob: TBytes; Const _3_t_codec: string);
  Begin
    //https://developer.4d.com/docs/21/commands/picture-to-blob
    _2_y_pictureBlob := Copy( _1_y_picture);
  End;

Procedure readPictureFile( Const _1_t_fileName: string; out _2_y_picture: TPicture; Const _3_t_anyTypeOperator: string);
  Var
    fs: TFileStream;
  Begin
    //https://developer.4d.com/docs/21/commands/read-picture-file
    If ( not FileExists( _1_t_fileName)) Then exit;

    fs := TFileStream.Create( _1_t_fileName, fmOpenRead);
    Try
      SetLength( _2_y_picture, fs.Size);
      fs.ReadBuffer( _2_y_picture[0], fs.Size);
    Finally
      fs.Free;
    End;
  End;

Procedure removePictureFromLibraryByRef( Const _1_e_picRef: int64);
  Begin
  End;

Procedure removePictureFromLibraryByName( Const _1_t_picName: string);
  Begin
  End;

Procedure setPictureFileName( Const _1_y_picture: TPicture; Const _2_t_fileName: string);
  Begin
  End;

Procedure setPictureMetadata( Const _1_y_picture: TPicture; Const _2_t_metaName: string; Const _3_t_metaContents: string);
  Begin
  End;

Procedure setPictureToLibrary( Const _1_y_picture: TPicture; Const _2_e_picRef: int64; Const _3_t_picName: string);
  Var
    i: integer;
  Begin
    i := Length( ty_library);
    SetLength( ty_library, i + 1);

    ty_library[i].e_ref := _2_e_picRef;
    ty_library[i].t_name := _3_t_picName;
    ty_library[i].y_picture := Copy( _1_y_picture);
  End;

Function transformPicture( Const _1_y_picture: TPicture; Const _2_e_operator: int64; Const _3_r_param1: double; Const _4_r_param2: double; Const _5_r_param3: double;
  Const _6_r_param4: double): TPicture;
  Begin
    //https://developer.4d.com/docs/21/commands/transform-picture
    Result := Copy( _1_y_picture);
  End;

Procedure writePictureFile( Const _1_t_fileName: string; Const _2_y_picture: TPicture; Const _3_t_codec: string);
  Var
    fs: TFileStream;
  Begin
    //https://developer.4d.com/docs/21/commands/write-picture-file
    fs := TFileStream.Create( _1_t_fileName, fmCreate);
    Try
      If ( Length( _2_y_picture) > 0) Then fs.WriteBuffer( _2_y_picture[0], Length( _2_y_picture));
    Finally
      fs.Free;
    End;
  End;

End.
