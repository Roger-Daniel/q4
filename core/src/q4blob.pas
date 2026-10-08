Unit q4blob;

{$mode objfpc}{$H+}

{
q4blob
version du 2026/05/08-08

Mapping 4D → q4blob -> statut
Command Number 4D,    4D Command,                       q4 API,                           Statut
  ------------------------------------------------------------------------------------------------
536,                 BLOB PROPERTIES,                  BLOBProperties,                   OK spécifique,
605,                 BLOB size,                        BLOBSize,                         OK,
526,                 BLOB TO DOCUMENT,                 BLOBToDocument,                   OK,
549,                 BLOB to integer,                  BLOBToInteger,                    OK,
557,                 BLOB to list,                     BLOBToList,                       Partial,
551,                 BLOB to longint,                  BLOBToLongint,                    OK,
553,                 BLOB to real,                     BLOBToReal,                       Partial,
555,                 BLOB to text,                     BLOBToText,                       OK,
533,                 BLOB TO VARIABLE,                 BLOBToVariable,                   OK spécifique,
534,                 COMPRESS BLOB,                    compressBLOB,                     OK spécifique,
558,                 COPY BLOB,                        copyBLOB,                         OK,
690,                 DECRYPT BLOB,                     decryptBLOB,                      TODO,
560,                 DELETE FROM BLOB,                 deleteFromBLOB,                   OK,
525,                 DOCUMENT TO BLOB,                 documentToBLOB,                   OK,
689,                 ENCRYPT BLOB,                     encryptBLOB,                      TODO,
535,                 EXPAND BLOB,                      expandBLOB,                       OK spécifique,
559,                 INSERT IN BLOB,                   insertInBLOB,                     OK,
548,                 INTEGER TO BLOB,                  integerToBLOB,                    OK,
556,                 LIST TO BLOB,                     listToBLOB,                       Partial,
550,                 LONGINT TO BLOB,                  longintToBLOB,                    OK,
552,                 REAL TO BLOB,                     realToBLOB,                       Partial,
606,                 SET BLOB SIZE,                    setBLOBSize,                      OK,
554,                 TEXT TO BLOB,                     textToBLOB,                       OK,
532,                 VARIABLE TO BLOB,                 variableToBLOB,                   OK spécifique,

Doc: https://developer.4d.com/docs/21/commands/theme/BLOB

  Conventions :
    - Les noms de méthodes sont en camelCase sans espaces.
    - Le type BLOB 4D est représenté par TBytes.
    - Les paramètres "offset : Variable" sont des Integer passés par référence.
    - Le paramètre star : string = '' simule le paramètre * de 4D :
        ''  = écriture au début du BLOB ou à l'offset donné
        '*' = ajout en fin de BLOB

  Dépendances :
    - zlib (FPC natif) pour compressBLOB / expandBLOB
    - Graphics (TBitmap) pour les surcharges TBitmapArray
    - Variants pour les surcharges Variant / TVariantArray

  Notes :
    - encryptBLOB / decryptBLOB passent par q4interruptions.assertRaise (algorithme RSA 4D propriétaire)
      (algorithme RSA propriétaire 4D, non documenté publiquement)
    - compressBLOB modes 1/2  : zlib deflate (clMax / clFastest)
    - compressBLOB modes -1/-2 : gzip via zlib (clMax / clFastest)
    - Un en-tête interne de 12 octets (magic + taille originale + taille
      compressée) est préfixé aux données ; il est lu par BLOBProperties
      et retiré par expandBLOB.

vsChatGt
    - encryptBLOB / decryptBLOB passent par q4interruptions.assertRaise : RSA 4D propriétaire non implémenté.
    - compressBLOB / expandBLOB utilisent un en-tête interne q4 de 12 octets.
    - BLOBProperties reflète cet en-tête interne ; la correspondance 4D est donc partielle.
    - BLOBToVariable / variableToBLOB et BLOBToList / listToBLOB utilisent une
      sérialisation interne q4, pas un format binaire 4D universel.
      
  Formats texte (conformes à la documentation 4D) :
    MacCString           (0) : C-string Mac Roman terminée par NUL
    MacPascalString      (1) : longueur 1 octet + données Mac Roman
    MacTextWithLength    (2) : longueur 2 octets big-endian + données Mac Roman
    MacTextWithoutLength (3) : données Mac Roman brutes (longueur via textLength)
    UTF8CString          (4) : C-string UTF-8 terminée par NUL
    UTF8TextWithLength   (5) : longueur 4 octets little-endian + données UTF-8
    UTF8TextWithoutLength (6) : données UTF-8 brutes (longueur via textLength)
}



Interface

Uses
  SysUtils, Classes, zstream, Graphics, Variants, q4coreLanguage, q4interruptions;

  // ---------------------------------------------------------------------------
  // Constantes de byte ordering (byteOrder)
  // ---------------------------------------------------------------------------
Const
  NativeByteOrdering = 0;
  MacintoshByteOrdering = 1;
  PCByteOrdering = 2;

  // ---------------------------------------------------------------------------
  // Constantes de format réel (realFormat)
  // ---------------------------------------------------------------------------
Const
  NativeRealFormat = 0;
  ExtendedRealFormat = 1;
  MacintoshDoubleRealFormat = 2;
  PCDoubleRealFormat = 3;

  // ---------------------------------------------------------------------------
  // Constantes de format texte (textFormat)
  // ---------------------------------------------------------------------------
Const
  MacCString = 0;
  MacPascalString = 1;
  MacTextWithLength = 2;
  MacTextWithoutLength = 3;
  UTF8CString = 4;
  UTF8TextWithLength = 5;
  UTF8TextWithoutLength = 6;

  // ---------------------------------------------------------------------------
  // Constantes de compression (compression)
  // ---------------------------------------------------------------------------
Const
  CompactCompressionMode = 1;
  FastCompressionMode = 2;
  GZIPBestCompressionMode = -1;
  GZIPFastCompressionMode = -2;
  IsNotCompressed = 0;

  // ---------------------------------------------------------------------------
  // Magic bytes de l'en-tête interne de compression
  // ---------------------------------------------------------------------------
Const
  Q4BLOB_MAGIC_ZLIB = $517A4C42; // 'QzLB'
  Q4BLOB_MAGIC_GZIP = $51475A42; // 'QGZB'

  // ---------------------------------------------------------------------------
  // Types de tableaux pour les surcharges BLOB TO VARIABLE / VARIABLE TO BLOB
  // ---------------------------------------------------------------------------
Type
  TBitmapArray = Array Of TBitmap;
  TVariantArray = Array Of variant;

  // ---------------------------------------------------------------------------
  // Déclarations
  // ---------------------------------------------------------------------------

{ BLOB PROPERTIES }
Procedure BLOBProperties( Const _1_by_blob: TBytes; out _2_e_compressed: int64; out _3_e_expandedSize: int64; out _4_e_currentSize: int64);

{ BLOB size }
Function BLOBSize( Const _1_by_blob: TBytes): int64;

{ BLOB TO DOCUMENT }
Procedure BLOBToDocument( Const _1_t_document: string; Const _2_by_blob: TBytes);

{ BLOB to integer }
Function BLOBToInteger( Const _1_by_blob: TBytes; _2_e_byteOrder: int64): smallint; overload;
Function BLOBToInteger( Const _1_by_blob: TBytes; _2_e_byteOrder: int64; Var _3_e_offset: int64): smallint; overload;

{ BLOB to list }
Function BLOBToList( Const _1_by_blob: TBytes): int64; overload;
Function BLOBToList( Const _1_by_blob: TBytes; Var _2_e_offset: int64): int64; overload;

{ BLOB to longint }
Function BLOBToLongint( Const _1_by_blob: TBytes; _2_e_byteOrder: int64): longint; overload;
Function BLOBToLongint( Const _1_by_blob: TBytes; _2_e_byteOrder: int64; Var _3_e_offset: int64): longint; overload;

{ BLOB to real }
Function BLOBToReal( Const _1_by_blob: TBytes; _2_e_realFormat: int64): double; overload;
Function BLOBToReal( Const _1_by_blob: TBytes; _2_e_realFormat: int64; Var _3_e_offset: int64): double; overload;

{ BLOB to text }
Function BLOBToText( Const _1_by_blob: TBytes; _2_e_textFormat: int64): string; overload;
Function BLOBToText( Const _1_by_blob: TBytes; _2_e_textFormat: int64; Var _3_e_offset: int64): string; overload;
Function BLOBToText( Const _1_by_blob: TBytes; _2_e_textFormat: int64; Var _3_e_offset: int64; _4_e_textLength: int64): string; overload;

{ BLOB TO VARIABLE - surcharges }
Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_y_variable: variant); overload;
Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_y_variable: variant; Var _3_e_offset: int64); overload;
Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_ty_variable: Tq4BlobArray); overload;
Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_ty_variable: Tq4BlobArray; Var _3_e_offset: int64); overload;
Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_o_variable: TBitmapArray); overload;
Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_o_variable: TBitmapArray; Var _3_e_offset: int64); overload;
Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_y_variable: TVariantArray); overload;
Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_y_variable: TVariantArray; Var _3_e_offset: int64); overload;

{ COMPRESS BLOB }
Procedure compressBLOB( Var _1_by_blob: TBytes; _2_e_compression: int64 = CompactCompressionMode);

{ COPY BLOB }
Procedure copyBLOB( Const _1_by_srcBLOB: TBytes; Var _2_by_dstBLOB: TBytes; _3_e_srcOffset: int64; _4_e_dstOffset: int64; _5_e_len: int64);

{ DECRYPT BLOB }
Procedure decryptBLOB( Var _1_by_toDecrypt: TBytes; Const _2_by_sendPubKey: TBytes); overload;
Procedure decryptBLOB( Var _1_by_toDecrypt: TBytes; Const _2_by_sendPubKey: TBytes; Const _3_by_recipPrivKey: TBytes); overload;

{ DELETE FROM BLOB }
Procedure deleteFromBLOB( Var _1_by_blob: TBytes; _2_e_offset: int64; _3_e_len: int64);

{ DOCUMENT TO BLOB }
Procedure documentToBLOB( Const _1_t_document: string; Var _2_by_blob: TBytes);

{ ENCRYPT BLOB }
Procedure encryptBLOB( Var _1_by_toEncrypt: TBytes; Const _2_by_sendPrivKey: TBytes); overload;
Procedure encryptBLOB( Var _1_by_toEncrypt: TBytes; Const _2_by_sendPrivKey: TBytes; Const _3_by_recipPubKey: TBytes); overload;

{ EXPAND BLOB }
Procedure expandBLOB( Var _1_by_blob: TBytes);

{ INSERT IN BLOB }
Procedure insertInBLOB( Var _1_by_blob: TBytes; _2_e_offset: int64; _3_e_len: int64; _4_e_filler: int64 = 0);

{ INTEGER TO BLOB }
Procedure integerToBLOB( _1_e_value: smallint; Var _2_by_blob: TBytes; _3_e_byteOrder: int64; _4_t_star: string = ''); overload;
Procedure integerToBLOB( _1_e_value: smallint; Var _2_by_blob: TBytes; _3_e_byteOrder: int64; Var _4_e_offset: int64); overload;

{ LIST TO BLOB }
Procedure listToBLOB( _1_e_list: int64; Var _2_by_blob: TBytes; _3_t_star: string = '');

{ LONGINT TO BLOB }
Procedure longintToBLOB( _1_e_value: longint; Var _2_by_blob: TBytes; _3_e_byteOrder: int64; _4_t_star: string = ''); overload;
Procedure longintToBLOB( _1_e_value: longint; Var _2_by_blob: TBytes; _3_e_byteOrder: int64; Var _4_e_offset: int64); overload;

{ REAL TO BLOB }
Procedure realToBLOB( _1_r_value: double; Var _2_by_blob: TBytes; _3_e_realFormat: int64; _4_t_star: string = ''); overload;
Procedure realToBLOB( _1_r_value: double; Var _2_by_blob: TBytes; _3_e_realFormat: int64; Var _4_e_offset: int64); overload;

{ SET BLOB SIZE }
Procedure setBLOBSize( Var _1_by_blob: TBytes; _2_e_size: int64; _3_e_filler: int64 = 0);

{ TEXT TO BLOB - défaut 4D : MacCString (0) }
Procedure textToBLOB( Const _1_t_text: string; Var _2_by_blob: TBytes; _3_e_textFormat: int64 = MacCString; _4_t_star: string = ''); overload;
Procedure textToBLOB( Const _1_t_text: string; Var _2_by_blob: TBytes; _3_e_textFormat: int64; Var _4_e_offset: int64); overload;

{ VARIABLE TO BLOB - surcharges }
Procedure variableToBLOB( Const _1_y_variable: variant; Var _2_by_blob: TBytes; _3_t_star: string = ''); overload;
Procedure variableToBLOB( Const _1_y_variable: variant; Var _2_by_blob: TBytes; Var _3_e_offset: int64); overload;
Procedure variableToBLOB( Const _1_ty_variable: Tq4BlobArray; Var _2_by_blob: TBytes; _3_t_star: string = ''); overload;
Procedure variableToBLOB( Const _1_ty_variable: Tq4BlobArray; Var _2_by_blob: TBytes; Var _3_e_offset: int64); overload;
Procedure variableToBLOB( Const _1_o_variable: TBitmapArray; Var _2_by_blob: TBytes; _3_t_star: string = ''); overload;
Procedure variableToBLOB( Const _1_o_variable: TBitmapArray; Var _2_by_blob: TBytes; Var _3_e_offset: int64); overload;
Procedure variableToBLOB( Const _1_y_variable: TVariantArray; Var _2_by_blob: TBytes; _3_t_star: string = ''); overload;
Procedure variableToBLOB( Const _1_y_variable: TVariantArray; Var _2_by_blob: TBytes; Var _3_e_offset: int64); overload;

Implementation

// ===========================================================================
// Utilitaires internes
// ===========================================================================

Function SwapWord( _1_e_w: word): word; Inline;
  Begin
    Result := ( ( _1_e_w and $FF) shl 8) or ( ( _1_e_w shr 8) and $FF);
  End;

Function SwapDWord( _1_e_dw: longword): longword; Inline;
  Var
    b: Array[0..3] Of byte absolute _1_e_dw;
    r: Array[0..3] Of byte;
  Begin
    r[0] := b[3];
    r[1] := b[2];
    r[2] := b[1];
    r[3] := b[0];
    Move( r, Result, 4);
  End;

Function IsLittleEndian: boolean; Inline;
  Var
    w: word;
    b: Array[0..1] Of byte absolute w;
  Begin
    w := $0102;
    Result := b[0] = $02;
  End;

Function ApplyByteOrderWord( _1_e_w: word; _2_e_byteOrder: int64): word; Inline;
  Begin
    Case _2_e_byteOrder Of
      PCByteOrdering: If ( not IsLittleEndian) Then Result := SwapWord( _1_e_w)
        Else
          Result := _1_e_w;
      MacintoshByteOrdering: If ( IsLittleEndian) Then Result := SwapWord( _1_e_w)
        Else
          Result := _1_e_w;
      Else Result := _1_e_w;
    End;
  End;

Function ApplyByteOrderDWord( _1_e_dw: longword; _2_e_byteOrder: int64): longword; Inline;
  Begin
    Case _2_e_byteOrder Of
      PCByteOrdering: If ( not IsLittleEndian) Then Result := SwapDWord( _1_e_dw)
        Else
          Result := _1_e_dw;
      MacintoshByteOrdering: If ( IsLittleEndian) Then Result := SwapDWord( _1_e_dw)
        Else
          Result := _1_e_dw;
      Else Result := _1_e_dw;
    End;
  End;

Function RealByteSize( _1_e_realFormat: int64): int64; Inline;
  Begin
    If ( _1_e_realFormat = ExtendedRealFormat) Then Result := 10
    Else
      Result := 8;
  End;


Procedure q4BlobBeginOK; Inline;
  Begin
    q4coreLanguage.OK := 0;
  End;

Procedure q4BlobSetOKSuccess; Inline;
  Begin
    q4coreLanguage.OK := 1;
  End;

Procedure q4BlobSetOKFailure; Inline;
  Begin
    q4coreLanguage.OK := 0;
  End;

Procedure q4BlobBeginOKError; Inline;
  Begin
    q4coreLanguage.OK := 0;
    q4coreLanguage.Error := 0;
  End;

Procedure q4BlobSetOKErrorSuccess; Inline;
  Begin
    q4coreLanguage.OK := 1;
    q4coreLanguage.Error := 0;
  End;

Procedure q4BlobSetOKErrorFailure( _1_e_errorCode: integer); Inline;
  Begin
    q4coreLanguage.OK := 0;
    q4coreLanguage.Error := _1_e_errorCode;
  End;

Function q4BlobExceptionErrorCode( Const _1_y_e: Exception): integer;
  Begin
    If ( _1_y_e is EInOutError) Then Result := EInOutError( _1_y_e).ErrorCode
    Else If ( GetLastOSError <> 0) Then Result := GetLastOSError
    Else
      Result := -1;
  End;

// ===========================================================================
// BLOB PROPERTIES
// ===========================================================================
Procedure BLOBProperties( Const _1_by_blob: TBytes; out _2_e_compressed: int64; out _3_e_expandedSize: int64; out _4_e_currentSize: int64);
  Var
    magic:  longword;
    stored: longword;
  Begin
    _4_e_currentSize := Length( _1_by_blob);
    If ( _4_e_currentSize >= 12) Then Begin
      Move( _1_by_blob[0], magic, 4);
      If ( magic = Q4BLOB_MAGIC_ZLIB) Then Begin
        _2_e_compressed := CompactCompressionMode;
        Move( _1_by_blob[4], stored, 4);
        _3_e_expandedSize := integer( stored);
        Exit;
      End Else If ( magic = Q4BLOB_MAGIC_GZIP) Then Begin
        _2_e_compressed := GZIPBestCompressionMode;
        Move( _1_by_blob[4], stored, 4);
        _3_e_expandedSize := integer( stored);
        Exit;
      End;
    End;
    _2_e_compressed := IsNotCompressed;
    _3_e_expandedSize := _4_e_currentSize;
  End;

// ===========================================================================
// BLOB size
// ===========================================================================
Function BLOBSize( Const _1_by_blob: TBytes): int64;
  Begin
    Result := Length( _1_by_blob);
  End;

// ===========================================================================
// BLOB TO DOCUMENT
// ===========================================================================
Procedure BLOBToDocument( Const _1_t_document: string; Const _2_by_blob: TBytes);
  Var
    fs: TFileStream;
  Begin
    q4BlobBeginOKError;
    Try
      fs := TFileStream.Create( _1_t_document, fmCreate);
      Try
        If ( Length( _2_by_blob) > 0) Then fs.WriteBuffer( _2_by_blob[0], Length( _2_by_blob));
      Finally
        fs.Free;
      End;
      q4BlobSetOKErrorSuccess;
    Except
      on e: Exception Do q4BlobSetOKErrorFailure( q4BlobExceptionErrorCode( e));
    End;
  End;

// ===========================================================================
// BLOB to integer
// ===========================================================================
Function BLOBToInteger( Const _1_by_blob: TBytes; _2_e_byteOrder: int64): smallint;
  Var
    w: word;
  Begin
    If ( Length( _1_by_blob) < 2) Then q4interruptions.assertRaise(
        'BLOBToInteger : BLOB trop petit (-111)',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
    Move( _1_by_blob[0], w, 2);
    Result := smallint( ApplyByteOrderWord( w, _2_e_byteOrder));
  End;

Function BLOBToInteger( Const _1_by_blob: TBytes; _2_e_byteOrder: int64; Var _3_e_offset: int64): smallint;
  Var
    w: word;
  Begin
    If ( _3_e_offset + 2 > Length( _1_by_blob)) Then q4interruptions.assertRaise(
        'BLOBToInteger : offset hors limites (-111)',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
    Move( _1_by_blob[_3_e_offset], w, 2);
    Result := smallint( ApplyByteOrderWord( w, _2_e_byteOrder));
    Inc( _3_e_offset, 2);
  End;

// ===========================================================================
// BLOB to list
// Format interne q4blob : LongWord(4) = longueur payload + LongWord(4) = handle
// ===========================================================================
Function BLOBToList( Const _1_by_blob: TBytes): int64;
  Var
    dummy: int64;
  Begin
    dummy := 0;
    Result := BLOBToList( _1_by_blob, dummy);
  End;

Function BLOBToList( Const _1_by_blob: TBytes; Var _2_e_offset: int64): int64;
  Var
    dataLen:     longword;
    listVal:     longword;
    startOffset: int64;
  Begin
    q4BlobBeginOK;
    Result := 0;
    startOffset := _2_e_offset;
    Try
      If ( _2_e_offset + 8 > Length( _1_by_blob)) Then q4interruptions.assertRaise(
          'BLOBToList : BLOB trop petit',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
      Move( _1_by_blob[_2_e_offset], dataLen, 4);
      Inc( _2_e_offset, 4);
      If ( dataLen <> 4) Then q4interruptions.assertRaise(
          'BLOBToList : format de liste inattendu',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
      Move( _1_by_blob[_2_e_offset], listVal, 4);
      Inc( _2_e_offset, 4);
      Result := integer( listVal);
      q4BlobSetOKSuccess;
    Except
      _2_e_offset := startOffset;
      Result := 0;
      q4BlobSetOKFailure;
    End;
  End;

// ===========================================================================
// BLOB to longint
// ===========================================================================
Function BLOBToLongint( Const _1_by_blob: TBytes; _2_e_byteOrder: int64): longint;
  Var
    dw: longword;
  Begin
    If ( Length( _1_by_blob) < 4) Then q4interruptions.assertRaise(
        'BLOBToLongint : BLOB trop petit (-111)',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
    Move( _1_by_blob[0], dw, 4);
    Result := longint( ApplyByteOrderDWord( dw, _2_e_byteOrder));
  End;

Function BLOBToLongint( Const _1_by_blob: TBytes; _2_e_byteOrder: int64; Var _3_e_offset: int64): longint;
  Var
    dw: longword;
  Begin
    If ( _3_e_offset + 4 > Length( _1_by_blob)) Then q4interruptions.assertRaise(
        'BLOBToLongint : offset hors limites (-111)',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
    Move( _1_by_blob[_3_e_offset], dw, 4);
    Result := longint( ApplyByteOrderDWord( dw, _2_e_byteOrder));
    Inc( _3_e_offset, 4);
  End;

// ===========================================================================
// BLOB to real
// ===========================================================================
Function ReadRealAt( Const _1_by_blob: TBytes; _2_e_realFormat: int64; _3_e_offset: int64): double;
  Var
    d:   double;
    dw1, dw2: longword;
    ext: Array[0..9] Of byte;
    i:   integer;
  Begin
    Case _2_e_realFormat Of

      NativeRealFormat: Begin
        Move( _1_by_blob[_3_e_offset], d, 8);
        Result := d;
      End;

      ExtendedRealFormat: Begin
        Move( _1_by_blob[_3_e_offset], ext[0], 10);
        If ( IsLittleEndian) Then For i := 0 To 4 Do Begin
            ext[i] := ext[i] xor ext[9 - i];
            ext[9 - i] := ext[i] xor ext[9 - i];
            ext[i] := ext[i] xor ext[9 - i];
          End;
        Move( ext[0], Result, SizeOf( extended));
      End;

      MacintoshDoubleRealFormat: Begin
        Move( _1_by_blob[_3_e_offset], dw1, 4);
        Move( _1_by_blob[_3_e_offset + 4], dw2, 4);
        If ( IsLittleEndian) Then Begin
          dw1 := SwapDWord( dw1);
          dw2 := SwapDWord( dw2);
          Move( dw2, d, 4);
          Move( dw1, ( pbyte( @d) + 4)^, 4);
        End Else
          Move( _1_by_blob[_3_e_offset], d, 8);
        Result := d;
      End;

      PCDoubleRealFormat: Begin
        Move( _1_by_blob[_3_e_offset], dw1, 4);
        Move( _1_by_blob[_3_e_offset + 4], dw2, 4);
        If ( not IsLittleEndian) Then Begin
          dw1 := SwapDWord( dw1);
          dw2 := SwapDWord( dw2);
          Move( dw2, d, 4);
          Move( dw1, ( pbyte( @d) + 4)^, 4);
        End Else
          Move( _1_by_blob[_3_e_offset], d, 8);
        Result := d;
      End;

      Else q4interruptions.assertRaise(
          'BLOBToReal : realFormat inconnu',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
    End;
  End;

Function BLOBToReal( Const _1_by_blob: TBytes; _2_e_realFormat: int64): double;
  Begin
    If ( Length( _1_by_blob) < RealByteSize( _2_e_realFormat)) Then q4interruptions.assertRaise(
        'BLOBToReal : BLOB trop petit (-111)',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
    Result := ReadRealAt( _1_by_blob, _2_e_realFormat, 0);
  End;

Function BLOBToReal( Const _1_by_blob: TBytes; _2_e_realFormat: int64; Var _3_e_offset: int64): double;
  Var
    sz: int64;
  Begin
    sz := RealByteSize( _2_e_realFormat);
    If ( _3_e_offset + sz > Length( _1_by_blob)) Then q4interruptions.assertRaise(
        'BLOBToReal : offset hors limites (-111)',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
    Result := ReadRealAt( _1_by_blob, _2_e_realFormat, _3_e_offset);
    Inc( _3_e_offset, sz);
  End;

// ===========================================================================
// BLOB to text
// ===========================================================================
Function BLOBToText( Const _1_by_blob: TBytes; _2_e_textFormat: int64): string;
  Var
    dummy: int64;
  Begin
    dummy := 0;
    Result := BLOBToText( _1_by_blob, _2_e_textFormat, dummy, 0);
  End;

Function BLOBToText( Const _1_by_blob: TBytes; _2_e_textFormat: int64; Var _3_e_offset: int64): string;
  Begin
    Result := BLOBToText( _1_by_blob, _2_e_textFormat, _3_e_offset, 0);
  End;

Function BLOBToText( Const _1_by_blob: TBytes; _2_e_textFormat: int64; Var _3_e_offset: int64; _4_e_textLength: int64): string;
  Var
    dataLen: int64;
    lenW: word;
    lenDW: longword;
    raw: TBytes;
    i: integer;
  Begin
    Case _2_e_textFormat Of

      MacCString: Begin
        dataLen := 0;
        i := _3_e_offset;
        While ( ( i < Length( _1_by_blob)) and ( _1_by_blob[i] <> 0)) Do Begin
          Inc( dataLen);
          Inc( i);
        End;
        SetLength( raw, dataLen);
        If ( dataLen > 0) Then Move( _1_by_blob[_3_e_offset], raw[0], dataLen);
        Result := TEncoding.GetEncoding( 10000).GetString( raw);
        Inc( _3_e_offset, dataLen + 1);
      End;

      MacPascalString: Begin
        If ( _3_e_offset >= Length( _1_by_blob)) Then q4interruptions.assertRaise(
            'BLOBToText : BLOB trop petit (MacPascalString)',
            {$I %CURRENTROUTINE%},
            {$I %LINENUM%}
            );
        dataLen := _1_by_blob[_3_e_offset];
        Inc( _3_e_offset);
        SetLength( raw, dataLen);
        If ( dataLen > 0) Then Move( _1_by_blob[_3_e_offset], raw[0], dataLen);
        Result := TEncoding.GetEncoding( 10000).GetString( raw);
        Inc( _3_e_offset, dataLen);
      End;

      MacTextWithLength: Begin
        // 2 octets big-endian (Word Mac) — conforme à la doc 4D
        If ( _3_e_offset + 2 > Length( _1_by_blob)) Then q4interruptions.assertRaise(
            'BLOBToText : BLOB trop petit (MacTextWithLength)',
            {$I %CURRENTROUTINE%},
            {$I %LINENUM%}
            );
        Move( _1_by_blob[_3_e_offset], lenW, 2);
        If ( IsLittleEndian) Then lenW := SwapWord( lenW);
        Inc( _3_e_offset, 2);
        dataLen := integer( lenW);
        SetLength( raw, dataLen);
        If ( dataLen > 0) Then Move( _1_by_blob[_3_e_offset], raw[0], dataLen);
        Result := TEncoding.GetEncoding( 10000).GetString( raw);
        Inc( _3_e_offset, dataLen);
      End;

      MacTextWithoutLength: Begin
        dataLen := _4_e_textLength;
        If ( _3_e_offset + dataLen > Length( _1_by_blob)) Then q4interruptions.assertRaise(
            'BLOBToText : BLOB trop petit (MacTextWithoutLength)',
            {$I %CURRENTROUTINE%},
            {$I %LINENUM%}
            );
        SetLength( raw, dataLen);
        If ( dataLen > 0) Then Move( _1_by_blob[_3_e_offset], raw[0], dataLen);
        Result := TEncoding.GetEncoding( 10000).GetString( raw);
        Inc( _3_e_offset, dataLen);
      End;

      UTF8CString: Begin
        dataLen := 0;
        i := _3_e_offset;
        While ( ( i < Length( _1_by_blob)) and ( _1_by_blob[i] <> 0)) Do Begin
          Inc( dataLen);
          Inc( i);
        End;
        SetLength( raw, dataLen);
        If ( dataLen > 0) Then Move( _1_by_blob[_3_e_offset], raw[0], dataLen);
        Result := TEncoding.UTF8.GetString( raw);
        Inc( _3_e_offset, dataLen + 1);
      End;

      UTF8TextWithLength: Begin
        // 4 octets little-endian (LongWord PC)
        If ( _3_e_offset + 4 > Length( _1_by_blob)) Then q4interruptions.assertRaise(
            'BLOBToText : BLOB trop petit (UTF8TextWithLength)',
            {$I %CURRENTROUTINE%},
            {$I %LINENUM%}
            );
        Move( _1_by_blob[_3_e_offset], lenDW, 4);
        If ( not IsLittleEndian) Then lenDW := SwapDWord( lenDW);
        Inc( _3_e_offset, 4);
        dataLen := integer( lenDW);
        SetLength( raw, dataLen);
        If ( dataLen > 0) Then Move( _1_by_blob[_3_e_offset], raw[0], dataLen);
        Result := TEncoding.UTF8.GetString( raw);
        Inc( _3_e_offset, dataLen);
      End;

      UTF8TextWithoutLength: Begin
        dataLen := _4_e_textLength;
        If ( _3_e_offset + dataLen > Length( _1_by_blob)) Then q4interruptions.assertRaise(
            'BLOBToText : BLOB trop petit (UTF8TextWithoutLength)',
            {$I %CURRENTROUTINE%},
            {$I %LINENUM%}
            );
        SetLength( raw, dataLen);
        If ( dataLen > 0) Then Move( _1_by_blob[_3_e_offset], raw[0], dataLen);
        Result := TEncoding.UTF8.GetString( raw);
        Inc( _3_e_offset, dataLen);
      End;

      Else q4interruptions.assertRaise(
          'BLOBToText : textFormat inconnu',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
    End;
  End;

// ===========================================================================
// BLOB TO VARIABLE
// Sérialisation interne : LongWord(longueur) + données UTF-8 de VarToStr
// ===========================================================================
Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_y_variable: variant);
  Var
    dummy: int64;
  Begin
    dummy := 0;
    BLOBToVariable( _1_by_blob, _2_y_variable, dummy);
  End;

Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_y_variable: variant; Var _3_e_offset: int64);
  Var
    dataLen: longword;
    raw:     TBytes;
    startOffset: int64;
  Begin
    q4BlobBeginOK;
    startOffset := _3_e_offset;
    Try
      If ( _3_e_offset + 4 > Length( _1_by_blob)) Then q4interruptions.assertRaise(
          'BLOBToVariable (Variant) : BLOB trop petit',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
      Move( _1_by_blob[_3_e_offset], dataLen, 4);
      Inc( _3_e_offset, 4);
      If ( _3_e_offset + integer( dataLen) > Length( _1_by_blob)) Then q4interruptions.assertRaise(
          'BLOBToVariable (Variant) : BLOB tronqué',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
      SetLength( raw, dataLen);
      If ( dataLen > 0) Then Move( _1_by_blob[_3_e_offset], raw[0], dataLen);
      Inc( _3_e_offset, integer( dataLen));
      _2_y_variable := TEncoding.UTF8.GetString( raw);
      q4BlobSetOKSuccess;
    Except
      _3_e_offset := startOffset;
      q4BlobSetOKFailure;
    End;
  End;

Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_ty_variable: Tq4BlobArray);
  Var
    dummy: int64;
  Begin
    dummy := 0;
    BLOBToVariable( _1_by_blob, _2_ty_variable, dummy);
  End;

Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_ty_variable: Tq4BlobArray; Var _3_e_offset: int64);
  Var
    Count: longword;
    itemLen: longword;
    i: integer;
    startOffset: int64;
  Begin
    q4BlobBeginOK;
    startOffset := _3_e_offset;
    Try
      If ( _3_e_offset + 4 > Length( _1_by_blob)) Then q4interruptions.assertRaise(
          'BLOBToVariable (Tq4BlobArray) : BLOB trop petit',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
      Move( _1_by_blob[_3_e_offset], Count, 4);
      Inc( _3_e_offset, 4);
      SetLength( _2_ty_variable, Count);
      For i := 0 To integer( Count) - 1 Do Begin
        If ( _3_e_offset + 4 > Length( _1_by_blob)) Then q4interruptions.assertRaise(
            'BLOBToVariable (Tq4BlobArray) : BLOB tronqué',
            {$I %CURRENTROUTINE%},
            {$I %LINENUM%}
            );
        Move( _1_by_blob[_3_e_offset], itemLen, 4);
        Inc( _3_e_offset, 4);
        If ( _3_e_offset + integer( itemLen) > Length( _1_by_blob)) Then q4interruptions.assertRaise(
            'BLOBToVariable (Tq4BlobArray) : élément tronqué',
            {$I %CURRENTROUTINE%},
            {$I %LINENUM%}
            );
        SetLength( _2_ty_variable[i], itemLen);
        If ( itemLen > 0) Then Move( _1_by_blob[_3_e_offset], _2_ty_variable[i][0], itemLen);
        Inc( _3_e_offset, integer( itemLen));
      End;
      q4BlobSetOKSuccess;
    Except
      _3_e_offset := startOffset;
      q4BlobSetOKFailure;
    End;
  End;

Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_o_variable: TBitmapArray);
  Var
    dummy: int64;
  Begin
    dummy := 0;
    BLOBToVariable( _1_by_blob, _2_o_variable, dummy);
  End;

Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_o_variable: TBitmapArray; Var _3_e_offset: int64);
  Var
    Count: longword;
    itemLen: longword;
    i:  integer;
    ms: TMemoryStream;
    startOffset: int64;
  Begin
    q4BlobBeginOK;
    startOffset := _3_e_offset;
    Try
      If ( _3_e_offset + 4 > Length( _1_by_blob)) Then q4interruptions.assertRaise(
          'BLOBToVariable (TBitmapArray) : BLOB trop petit',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
      Move( _1_by_blob[_3_e_offset], Count, 4);
      Inc( _3_e_offset, 4);
      For i := 0 To High( _2_o_variable) Do If ( Assigned( _2_o_variable[i])) Then _2_o_variable[i].Free;
      SetLength( _2_o_variable, Count);
      For i := 0 To integer( Count) - 1 Do Begin
        If ( _3_e_offset + 4 > Length( _1_by_blob)) Then q4interruptions.assertRaise(
            'BLOBToVariable (TBitmapArray) : BLOB tronqué',
            {$I %CURRENTROUTINE%},
            {$I %LINENUM%}
            );
        Move( _1_by_blob[_3_e_offset], itemLen, 4);
        Inc( _3_e_offset, 4);
        If ( _3_e_offset + integer( itemLen) > Length( _1_by_blob)) Then q4interruptions.assertRaise(
            'BLOBToVariable (TBitmapArray) : élément tronqué',
            {$I %CURRENTROUTINE%},
            {$I %LINENUM%}
            );
        _2_o_variable[i] := TBitmap.Create;
        ms := TMemoryStream.Create;
        Try
          If ( itemLen > 0) Then ms.WriteBuffer( _1_by_blob[_3_e_offset], itemLen);
          ms.Position := 0;
          _2_o_variable[i].LoadFromStream( ms);
        Finally
          ms.Free;
        End;
        Inc( _3_e_offset, integer( itemLen));
      End;
      q4BlobSetOKSuccess;
    Except
      _3_e_offset := startOffset;
      q4BlobSetOKFailure;
    End;
  End;

Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_y_variable: TVariantArray);
  Var
    dummy: int64;
  Begin
    dummy := 0;
    BLOBToVariable( _1_by_blob, _2_y_variable, dummy);
  End;

Procedure BLOBToVariable( Const _1_by_blob: TBytes; Var _2_y_variable: TVariantArray; Var _3_e_offset: int64);
  Var
    Count: longword;
    itemLen: longword;
    i:   integer;
    raw: TBytes;
    startOffset: int64;
  Begin
    q4BlobBeginOK;
    startOffset := _3_e_offset;
    Try
      If ( _3_e_offset + 4 > Length( _1_by_blob)) Then q4interruptions.assertRaise(
          'BLOBToVariable (TVariantArray) : BLOB trop petit',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
      Move( _1_by_blob[_3_e_offset], Count, 4);
      Inc( _3_e_offset, 4);
      SetLength( _2_y_variable, Count);
      For i := 0 To integer( Count) - 1 Do Begin
        If ( _3_e_offset + 4 > Length( _1_by_blob)) Then q4interruptions.assertRaise(
            'BLOBToVariable (TVariantArray) : BLOB tronqué',
            {$I %CURRENTROUTINE%},
            {$I %LINENUM%}
            );
        Move( _1_by_blob[_3_e_offset], itemLen, 4);
        Inc( _3_e_offset, 4);
        If ( _3_e_offset + integer( itemLen) > Length( _1_by_blob)) Then q4interruptions.assertRaise(
            'BLOBToVariable (TVariantArray) : élément tronqué',
            {$I %CURRENTROUTINE%},
            {$I %LINENUM%}
            );
        SetLength( raw, itemLen);
        If ( itemLen > 0) Then Move( _1_by_blob[_3_e_offset], raw[0], itemLen);
        Inc( _3_e_offset, integer( itemLen));
        _2_y_variable[i] := TEncoding.UTF8.GetString( raw);
      End;
      q4BlobSetOKSuccess;
    Except
      _3_e_offset := startOffset;
      q4BlobSetOKFailure;
    End;
  End;

// ===========================================================================
// COMPRESS BLOB
// En-tête interne (12 octets) :
//   [0..3]  magic     LongWord
//   [4..7]  origSize  LongWord little-endian
//   [8..11] compSize  LongWord little-endian
//   [12..]  données compressées (deflate zlib)
// Note : les modes GZIP utilisent deflate avec le magic GZIP pour
// distinguer le niveau ; FPC zstream ne supporte pas le format gzip
// natif sans dépendances supplémentaires.
// ===========================================================================
Procedure compressBLOB( Var _1_by_blob: TBytes; _2_e_compression: int64 = CompactCompressionMode);
  Var
    origSize: longword;
    compSize: longword;
    headerMagic: longword;
    checkMagic: longword;
    ms:    TMemoryStream;
    cs:    TCompressionStream;
    level: TCompressionLevel;
    result_blob: TBytes;
  Begin
    q4BlobBeginOKError;
    Try
      origSize := longword( Length( _1_by_blob));
      If ( origSize < 255) Then Exit;

      If ( origSize >= 12) Then Begin
        Move( _1_by_blob[0], checkMagic, 4);
        If ( ( checkMagic = Q4BLOB_MAGIC_ZLIB) or ( checkMagic = Q4BLOB_MAGIC_GZIP)) Then Exit; // déjà compressé
      End;

      Case _2_e_compression Of
        FastCompressionMode: Begin
          headerMagic := Q4BLOB_MAGIC_ZLIB;
          level := clFastest;
        End;
        GZIPBestCompressionMode: Begin
          headerMagic := Q4BLOB_MAGIC_GZIP;
          level := clMax;
        End;
        GZIPFastCompressionMode: Begin
          headerMagic := Q4BLOB_MAGIC_GZIP;
          level := clFastest;
        End;
        Else // CompactCompressionMode et toute valeur inconnue → zlib max
          headerMagic := Q4BLOB_MAGIC_ZLIB;
          level := clMax;
      End;

      ms := TMemoryStream.Create;
      Try
        cs := TCompressionStream.Create( level, ms);
        Try
          If ( origSize > 0) Then cs.WriteBuffer( _1_by_blob[0], origSize);
        Finally
          cs.Free;
        End;

        compSize := longword( ms.Size);
        SetLength( result_blob, 12 + integer( compSize));
        Move( headerMagic, result_blob[0], 4);
        Move( origSize, result_blob[4], 4);
        Move( compSize, result_blob[8], 4);
        If ( compSize > 0) Then Begin
          ms.Position := 0;
          ms.ReadBuffer( result_blob[12], compSize);
        End;
        _1_by_blob := result_blob;
      Finally
        ms.Free;
      End;
      q4BlobSetOKErrorSuccess;
    Except
      on EOutOfMemory Do q4BlobSetOKErrorFailure( 0)
      Else
        q4BlobSetOKErrorFailure( -10600);
    End;
  End;

// ===========================================================================
// COPY BLOB
// ===========================================================================
Procedure copyBLOB( Const _1_by_srcBLOB: TBytes; Var _2_by_dstBLOB: TBytes; _3_e_srcOffset: int64; _4_e_dstOffset: int64; _5_e_len: int64);
  Var
    needed: int64;
  Begin
    If ( _5_e_len <= 0) Then Exit;
    If ( _3_e_srcOffset + _5_e_len > Length( _1_by_srcBLOB)) Then q4interruptions.assertRaise(
        'copyBLOB : srcOffset + len dépasse la source',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
    needed := _4_e_dstOffset + _5_e_len;
    If ( needed > Length( _2_by_dstBLOB)) Then SetLength( _2_by_dstBLOB, needed);
    Move( _1_by_srcBLOB[_3_e_srcOffset], _2_by_dstBLOB[_4_e_dstOffset], _5_e_len);
  End;

// ===========================================================================
// DECRYPT BLOB  (non implémenté)
// ===========================================================================
Procedure decryptBLOB( Var _1_by_toDecrypt: TBytes; Const _2_by_sendPubKey: TBytes);
  Begin
    q4interruptions.assertRaise(
      'decryptBLOB : algorithme RSA 4D non implémenté. Utilisez une bibliothèque externe (DCPcrypt, OpenSSL…).',
      {$I %CURRENTROUTINE%},
      {$I %LINENUM%}
      );
  End;

Procedure decryptBLOB( Var _1_by_toDecrypt: TBytes; Const _2_by_sendPubKey: TBytes; Const _3_by_recipPrivKey: TBytes);
  Begin
    q4interruptions.assertRaise(
      'decryptBLOB : algorithme RSA 4D non implémenté. Utilisez une bibliothèque externe (DCPcrypt, OpenSSL…).',
      {$I %CURRENTROUTINE%},
      {$I %LINENUM%}
      );
  End;

// ===========================================================================
// DELETE FROM BLOB
// ===========================================================================
Procedure deleteFromBLOB( Var _1_by_blob: TBytes; _2_e_offset: int64; _3_e_len: int64);
  Var
    blobLen:   integer;
    remaining: int64;
  Begin
    blobLen := Length( _1_by_blob);
    If ( ( _2_e_offset < 0) or ( _2_e_offset >= blobLen)) Then Exit;
    If ( _2_e_offset + _3_e_len > blobLen) Then _3_e_len := blobLen - _2_e_offset;
    remaining := blobLen - _2_e_offset - _3_e_len;
    If ( remaining > 0) Then Move( _1_by_blob[_2_e_offset + _3_e_len], _1_by_blob[_2_e_offset], remaining);
    SetLength( _1_by_blob, blobLen - _3_e_len);
  End;

// ===========================================================================
// DOCUMENT TO BLOB
// ===========================================================================
Procedure documentToBLOB( Const _1_t_document: string; Var _2_by_blob: TBytes);
  Var
    fs:      TFileStream;
    newBlob: TBytes;
  Begin
    q4BlobBeginOK;
    Try
      fs := TFileStream.Create( _1_t_document, fmOpenRead or fmShareDenyWrite);
      Try
        SetLength( newBlob, fs.Size);
        If ( fs.Size > 0) Then fs.ReadBuffer( newBlob[0], fs.Size);
        _2_by_blob := newBlob;
      Finally
        fs.Free;
      End;
      q4BlobSetOKSuccess;
    Except
      q4BlobSetOKFailure;
    End;
  End;

// ===========================================================================
// ENCRYPT BLOB  (non implémenté)
// ===========================================================================
Procedure encryptBLOB( Var _1_by_toEncrypt: TBytes; Const _2_by_sendPrivKey: TBytes);
  Begin
    q4interruptions.assertRaise(
      'encryptBLOB : algorithme RSA 4D non implémenté. Utilisez une bibliothèque externe (DCPcrypt, OpenSSL…).',
      {$I %CURRENTROUTINE%},
      {$I %LINENUM%}
      );
  End;

Procedure encryptBLOB( Var _1_by_toEncrypt: TBytes; Const _2_by_sendPrivKey: TBytes; Const _3_by_recipPubKey: TBytes);
  Begin
    q4interruptions.assertRaise(
      'encryptBLOB : algorithme RSA 4D non implémenté. Utilisez une bibliothèque externe (DCPcrypt, OpenSSL…).',
      {$I %CURRENTROUTINE%},
      {$I %LINENUM%}
      );
  End;

// ===========================================================================
// EXPAND BLOB
// ===========================================================================
Procedure expandBLOB( Var _1_by_blob: TBytes);
  Var
    magic: longword;
    origSize: longword;
    compSize: longword;
    ms: TMemoryStream;
    ds: TDecompressionStream;
    expanded: TBytes;
  Begin
    q4BlobBeginOK;
    Try
      If ( Length( _1_by_blob) < 12) Then Exit;
      Move( _1_by_blob[0], magic, 4);
      If ( ( magic <> Q4BLOB_MAGIC_ZLIB) and ( magic <> Q4BLOB_MAGIC_GZIP)) Then Exit;
      Move( _1_by_blob[4], origSize, 4);
      Move( _1_by_blob[8], compSize, 4);
      If ( integer( compSize) > Length( _1_by_blob) - 12) Then Exit;
      ms := TMemoryStream.Create;
      Try
        If ( compSize > 0) Then ms.WriteBuffer( _1_by_blob[12], compSize);
        ms.Position := 0;
        SetLength( expanded, origSize);
        ds := TDecompressionStream.Create( ms);
        Try
          If ( origSize > 0) Then ds.ReadBuffer( expanded[0], origSize);
        Finally
          ds.Free;
        End;
      Finally
        ms.Free;
      End;
      _1_by_blob := expanded;
      q4BlobSetOKSuccess;
    Except
      q4BlobSetOKFailure;
    End;
  End;

// ===========================================================================
// INSERT IN BLOB
// ===========================================================================
Procedure insertInBLOB( Var _1_by_blob: TBytes; _2_e_offset: int64; _3_e_len: int64; _4_e_filler: int64 = 0);
  Var
    blobLen:  integer;
    fillByte: byte;
  Begin
    If ( _3_e_len <= 0) Then Exit;
    blobLen := Length( _1_by_blob);
    If ( _2_e_offset > blobLen) Then q4interruptions.assertRaise(
        'insertInBLOB : offset dépasse la taille du BLOB',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
    fillByte := byte( _4_e_filler mod 256);
    SetLength( _1_by_blob, blobLen + _3_e_len);
    If ( blobLen - _2_e_offset > 0) Then Move( _1_by_blob[_2_e_offset], _1_by_blob[_2_e_offset + _3_e_len], blobLen - _2_e_offset);
    If ( _3_e_len > 0) Then FillChar( _1_by_blob[_2_e_offset], _3_e_len, fillByte);
  End;

// ===========================================================================
// INTEGER TO BLOB
// ===========================================================================
Procedure integerToBLOB( _1_e_value: smallint; Var _2_by_blob: TBytes; _3_e_byteOrder: int64; _4_t_star: string = '');
  Var
    w:   word;
    pos: int64;
  Begin
    w := ApplyByteOrderWord( word( _1_e_value), _3_e_byteOrder);
    If ( _4_t_star = '*') Then Begin
      pos := Length( _2_by_blob);
      SetLength( _2_by_blob, pos + 2);
      Move( w, _2_by_blob[pos], 2);
    End Else Begin
      SetLength( _2_by_blob, 2);
      Move( w, _2_by_blob[0], 2);
    End;
  End;

Procedure integerToBLOB( _1_e_value: smallint; Var _2_by_blob: TBytes; _3_e_byteOrder: int64; Var _4_e_offset: int64);
  Var
    w: word;
  Begin
    w := ApplyByteOrderWord( word( _1_e_value), _3_e_byteOrder);
    If ( _4_e_offset + 2 > Length( _2_by_blob)) Then SetLength( _2_by_blob, _4_e_offset + 2);
    Move( w, _2_by_blob[_4_e_offset], 2);
    Inc( _4_e_offset, 2);
  End;

// ===========================================================================
// LIST TO BLOB
// ===========================================================================
Procedure listToBLOB( _1_e_list: int64; Var _2_by_blob: TBytes; _3_t_star: string = '');
  Var
    dataLen: longword;
    listVal: longword;
    pos:     integer;
  Begin
    q4BlobBeginOK;
    Try
      dataLen := 4;
      listVal := longword( _1_e_list);
      If ( _3_t_star = '*') Then Begin
        pos := Length( _2_by_blob);
        SetLength( _2_by_blob, pos + 8);
      End Else Begin
        pos := 0;
        SetLength( _2_by_blob, 8);
      End;
      Move( dataLen, _2_by_blob[pos], 4);
      Move( listVal, _2_by_blob[pos + 4], 4);
      q4BlobSetOKSuccess;
    Except
      q4BlobSetOKFailure;
    End;
  End;

// ===========================================================================
// LONGINT TO BLOB
// ===========================================================================
Procedure longintToBLOB( _1_e_value: longint; Var _2_by_blob: TBytes; _3_e_byteOrder: int64; _4_t_star: string = '');
  Var
    dw:  longword;
    pos: int64;
  Begin
    dw := ApplyByteOrderDWord( longword( _1_e_value), _3_e_byteOrder);
    If ( _4_t_star = '*') Then Begin
      pos := Length( _2_by_blob);
      SetLength( _2_by_blob, pos + 4);
      Move( dw, _2_by_blob[pos], 4);
    End Else Begin
      SetLength( _2_by_blob, 4);
      Move( dw, _2_by_blob[0], 4);
    End;
  End;

Procedure longintToBLOB( _1_e_value: longint; Var _2_by_blob: TBytes; _3_e_byteOrder: int64; Var _4_e_offset: int64);
  Var
    dw: longword;
  Begin
    dw := ApplyByteOrderDWord( longword( _1_e_value), _3_e_byteOrder);
    If ( _4_e_offset + 4 > Length( _2_by_blob)) Then SetLength( _2_by_blob, _4_e_offset + 4);
    Move( dw, _2_by_blob[_4_e_offset], 4);
    Inc( _4_e_offset, 4);
  End;

// ===========================================================================
// REAL TO BLOB
// ===========================================================================
Procedure WriteRealAt( _1_r_value: double; Var _2_by_blob: TBytes; _3_e_realFormat: int64; Var _4_e_pos: int64);
  Var
    d:   double;
    dw1, dw2: longword;
    ext: Array[0..9] Of byte;
    i:   integer;
    sz:  integer;
  Begin
    sz := RealByteSize( _3_e_realFormat);
    If ( _4_e_pos + sz > Length( _2_by_blob)) Then SetLength( _2_by_blob, _4_e_pos + sz);

    Case _3_e_realFormat Of

      NativeRealFormat: Move( _1_r_value, _2_by_blob[_4_e_pos], 8);

      ExtendedRealFormat: Begin
        Move( _1_r_value, ext[0], 10);
        If ( IsLittleEndian) Then For i := 0 To 4 Do Begin
            ext[i] := ext[i] xor ext[9 - i];
            ext[9 - i] := ext[i] xor ext[9 - i];
            ext[i] := ext[i] xor ext[9 - i];
          End;
        Move( ext[0], _2_by_blob[_4_e_pos], 10);
      End;

      MacintoshDoubleRealFormat: Begin
        d := _1_r_value;
        If ( IsLittleEndian) Then Begin
          Move( d, dw1, 4);
          Move( ( pbyte( @d) + 4)^, dw2, 4);
          dw1 := SwapDWord( dw1);
          dw2 := SwapDWord( dw2);
          // Stocké big-endian Mac : MSW en premier
          Move( dw2, _2_by_blob[_4_e_pos], 4);
          Move( dw1, _2_by_blob[_4_e_pos + 4], 4);
        End Else
          Move( d, _2_by_blob[_4_e_pos], 8);
      End;

      PCDoubleRealFormat: Begin
        d := _1_r_value;
        If ( not IsLittleEndian) Then Begin
          Move( d, dw1, 4);
          Move( ( pbyte( @d) + 4)^, dw2, 4);
          dw1 := SwapDWord( dw1);
          dw2 := SwapDWord( dw2);
          Move( dw2, _2_by_blob[_4_e_pos], 4);
          Move( dw1, _2_by_blob[_4_e_pos + 4], 4);
        End Else
          Move( d, _2_by_blob[_4_e_pos], 8);
      End;

      Else q4interruptions.assertRaise(
          'realToBLOB : realFormat inconnu',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
    End;

    Inc( _4_e_pos, sz);
  End;

Procedure realToBLOB( _1_r_value: double; Var _2_by_blob: TBytes; _3_e_realFormat: int64; _4_t_star: string = '');
  Var
    pos: int64;
    sz:  integer;
  Begin
    sz := RealByteSize( _3_e_realFormat);
    If ( _4_t_star = '*') Then Begin
      pos := Length( _2_by_blob);
      SetLength( _2_by_blob, pos + sz);
    End Else Begin
      pos := 0;
      SetLength( _2_by_blob, sz);
    End;
    WriteRealAt( _1_r_value, _2_by_blob, _3_e_realFormat, pos);
  End;

Procedure realToBLOB( _1_r_value: double; Var _2_by_blob: TBytes; _3_e_realFormat: int64; Var _4_e_offset: int64);
  Begin
    // WriteRealAt étend le blob si nécessaire et incrémente offset
    WriteRealAt( _1_r_value, _2_by_blob, _3_e_realFormat, _4_e_offset);
  End;

// ===========================================================================
// SET BLOB SIZE
// ===========================================================================
Procedure setBLOBSize( Var _1_by_blob: TBytes; _2_e_size: int64; _3_e_filler: int64 = 0);
  Var
    oldSize:  integer;
    fillByte: byte;
  Begin
    oldSize := Length( _1_by_blob);
    SetLength( _1_by_blob, _2_e_size);
    If ( _2_e_size > oldSize) Then Begin
      fillByte := byte( _3_e_filler mod 256);
      FillChar( _1_by_blob[oldSize], _2_e_size - oldSize, fillByte);
    End;
  End;

// ===========================================================================
// TEXT TO BLOB
// ===========================================================================
Procedure WriteTextAt( Const _1_t_text: string; _2_e_textFormat: int64; Var _3_by_blob: TBytes; Var _4_e_pos: int64);
  Var
    raw:     TBytes;
    dataLen: int64;
    lenW:    word;
    lenDW:   longword;
  Begin
    Case _2_e_textFormat Of

      MacCString: Begin
        raw := TEncoding.GetEncoding( 10000).GetBytes( _1_t_text);
        dataLen := Length( raw);
        If ( _4_e_pos + dataLen + 1 > Length( _3_by_blob)) Then SetLength( _3_by_blob, _4_e_pos + dataLen + 1);
        If ( dataLen > 0) Then Move( raw[0], _3_by_blob[_4_e_pos], dataLen);
        _3_by_blob[_4_e_pos + dataLen] := 0;
        Inc( _4_e_pos, dataLen + 1);
      End;

      MacPascalString: Begin
        raw := TEncoding.GetEncoding( 10000).GetBytes( _1_t_text);
        dataLen := Length( raw);
        If ( dataLen > 255) Then dataLen := 255;
        If ( _4_e_pos + 1 + dataLen > Length( _3_by_blob)) Then SetLength( _3_by_blob, _4_e_pos + 1 + dataLen);
        _3_by_blob[_4_e_pos] := byte( dataLen);
        Inc( _4_e_pos);
        If ( dataLen > 0) Then Move( raw[0], _3_by_blob[_4_e_pos], dataLen);
        Inc( _4_e_pos, dataLen);
      End;

      MacTextWithLength: Begin
        // 2 octets big-endian (Word Mac) — conforme à la doc 4D
        raw := TEncoding.GetEncoding( 10000).GetBytes( _1_t_text);
        dataLen := Length( raw);
        lenW := word( dataLen);
        If ( IsLittleEndian) Then lenW := SwapWord( lenW);
        If ( _4_e_pos + 2 + dataLen > Length( _3_by_blob)) Then SetLength( _3_by_blob, _4_e_pos + 2 + dataLen);
        Move( lenW, _3_by_blob[_4_e_pos], 2);
        Inc( _4_e_pos, 2);
        If ( dataLen > 0) Then Move( raw[0], _3_by_blob[_4_e_pos], dataLen);
        Inc( _4_e_pos, dataLen);
      End;

      MacTextWithoutLength: Begin
        raw := TEncoding.GetEncoding( 10000).GetBytes( _1_t_text);
        dataLen := Length( raw);
        If ( _4_e_pos + dataLen > Length( _3_by_blob)) Then SetLength( _3_by_blob, _4_e_pos + dataLen);
        If ( dataLen > 0) Then Move( raw[0], _3_by_blob[_4_e_pos], dataLen);
        Inc( _4_e_pos, dataLen);
      End;

      UTF8CString: Begin
        raw := TEncoding.UTF8.GetBytes( _1_t_text);
        dataLen := Length( raw);
        If ( _4_e_pos + dataLen + 1 > Length( _3_by_blob)) Then SetLength( _3_by_blob, _4_e_pos + dataLen + 1);
        If ( dataLen > 0) Then Move( raw[0], _3_by_blob[_4_e_pos], dataLen);
        _3_by_blob[_4_e_pos + dataLen] := 0;
        Inc( _4_e_pos, dataLen + 1);
      End;

      UTF8TextWithLength: Begin
        // 4 octets little-endian (LongWord PC)
        raw := TEncoding.UTF8.GetBytes( _1_t_text);
        dataLen := Length( raw);
        lenDW := longword( dataLen);
        If ( not IsLittleEndian) Then lenDW := SwapDWord( lenDW);
        If ( _4_e_pos + 4 + dataLen > Length( _3_by_blob)) Then SetLength( _3_by_blob, _4_e_pos + 4 + dataLen);
        Move( lenDW, _3_by_blob[_4_e_pos], 4);
        Inc( _4_e_pos, 4);
        If ( dataLen > 0) Then Move( raw[0], _3_by_blob[_4_e_pos], dataLen);
        Inc( _4_e_pos, dataLen);
      End;

      UTF8TextWithoutLength: Begin
        raw := TEncoding.UTF8.GetBytes( _1_t_text);
        dataLen := Length( raw);
        If ( _4_e_pos + dataLen > Length( _3_by_blob)) Then SetLength( _3_by_blob, _4_e_pos + dataLen);
        If ( dataLen > 0) Then Move( raw[0], _3_by_blob[_4_e_pos], dataLen);
        Inc( _4_e_pos, dataLen);
      End;

      Else q4interruptions.assertRaise(
          'textToBLOB : textFormat inconnu',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
    End;
  End;

Procedure textToBLOB( Const _1_t_text: string; Var _2_by_blob: TBytes; _3_e_textFormat: int64 = MacCString; _4_t_star: string = '');
  Var
    pos: int64;
  Begin
    If ( _4_t_star = '*') Then pos := Length( _2_by_blob)
    Else Begin
      pos := 0;
      SetLength( _2_by_blob, 0);
    End;
    WriteTextAt( _1_t_text, _3_e_textFormat, _2_by_blob, pos);
  End;

Procedure textToBLOB( Const _1_t_text: string; Var _2_by_blob: TBytes; _3_e_textFormat: int64; Var _4_e_offset: int64);
  Begin
    WriteTextAt( _1_t_text, _3_e_textFormat, _2_by_blob, _4_e_offset);
  End;

// ===========================================================================
// VARIABLE TO BLOB
// ===========================================================================
Procedure variableToBLOB( Const _1_y_variable: variant; Var _2_by_blob: TBytes; _3_t_star: string = '');
  Var
    pos: int64;
  Begin
    q4BlobBeginOK;
    Try
      If ( _3_t_star = '*') Then pos := Length( _2_by_blob)
      Else Begin
        pos := 0;
        SetLength( _2_by_blob, 0);
      End;
      variableToBLOB( _1_y_variable, _2_by_blob, pos);
    Except
      q4BlobSetOKFailure;
    End;
  End;

Procedure variableToBLOB( Const _1_y_variable: variant; Var _2_by_blob: TBytes; Var _3_e_offset: int64);
  Var
    raw:     TBytes;
    dataLen: longword;
    startOffset: int64;
  Begin
    q4BlobBeginOK;
    startOffset := _3_e_offset;
    Try
      raw := TEncoding.UTF8.GetBytes( VarToStr( _1_y_variable));
      dataLen := longword( Length( raw));
      If ( _3_e_offset + 4 + integer( dataLen) > Length( _2_by_blob)) Then SetLength( _2_by_blob, _3_e_offset + 4 + integer( dataLen));
      Move( dataLen, _2_by_blob[_3_e_offset], 4);
      Inc( _3_e_offset, 4);
      If ( dataLen > 0) Then Move( raw[0], _2_by_blob[_3_e_offset], dataLen);
      Inc( _3_e_offset, integer( dataLen));
      q4BlobSetOKSuccess;
    Except
      _3_e_offset := startOffset;
      q4BlobSetOKFailure;
    End;
  End;

Procedure variableToBLOB( Const _1_ty_variable: Tq4BlobArray; Var _2_by_blob: TBytes; _3_t_star: string = '');
  Var
    pos: int64;
  Begin
    q4BlobBeginOK;
    Try
      If ( _3_t_star = '*') Then pos := Length( _2_by_blob)
      Else Begin
        pos := 0;
        SetLength( _2_by_blob, 0);
      End;
      variableToBLOB( _1_ty_variable, _2_by_blob, pos);
    Except
      q4BlobSetOKFailure;
    End;
  End;

Procedure variableToBLOB( Const _1_ty_variable: Tq4BlobArray; Var _2_by_blob: TBytes; Var _3_e_offset: int64);
  Var
    Count: longword;
    itemLen: longword;
    i: integer;
    startOffset: int64;
  Begin
    q4BlobBeginOK;
    startOffset := _3_e_offset;
    Try
      Count := longword( Length( _1_ty_variable));
      If ( _3_e_offset + 4 > Length( _2_by_blob)) Then SetLength( _2_by_blob, _3_e_offset + 4);
      Move( Count, _2_by_blob[_3_e_offset], 4);
      Inc( _3_e_offset, 4);
      For i := 0 To integer( Count) - 1 Do Begin
        itemLen := longword( Length( _1_ty_variable[i]));
        If ( _3_e_offset + 4 + integer( itemLen) > Length( _2_by_blob)) Then SetLength( _2_by_blob, _3_e_offset + 4 + integer( itemLen));
        Move( itemLen, _2_by_blob[_3_e_offset], 4);
        Inc( _3_e_offset, 4);
        If ( itemLen > 0) Then Move( _1_ty_variable[i][0], _2_by_blob[_3_e_offset], itemLen);
        Inc( _3_e_offset, integer( itemLen));
      End;
      q4BlobSetOKSuccess;
    Except
      _3_e_offset := startOffset;
      q4BlobSetOKFailure;
    End;
  End;

Procedure variableToBLOB( Const _1_o_variable: TBitmapArray; Var _2_by_blob: TBytes; _3_t_star: string = '');
  Var
    pos: int64;
  Begin
    q4BlobBeginOK;
    Try
      If ( _3_t_star = '*') Then pos := Length( _2_by_blob)
      Else Begin
        pos := 0;
        SetLength( _2_by_blob, 0);
      End;
      variableToBLOB( _1_o_variable, _2_by_blob, pos);
    Except
      q4BlobSetOKFailure;
    End;
  End;

Procedure variableToBLOB( Const _1_o_variable: TBitmapArray; Var _2_by_blob: TBytes; Var _3_e_offset: int64);
  Var
    Count:  longword;
    itemLen: longword;
    i:      integer;
    ms:     TMemoryStream;
    bmpRaw: TBytes;
    startOffset: int64;
  Begin
    q4BlobBeginOK;
    startOffset := _3_e_offset;
    Try
      Count := longword( Length( _1_o_variable));
      If ( _3_e_offset + 4 > Length( _2_by_blob)) Then SetLength( _2_by_blob, _3_e_offset + 4);
      Move( Count, _2_by_blob[_3_e_offset], 4);
      Inc( _3_e_offset, 4);
      For i := 0 To integer( Count) - 1 Do Begin
        ms := TMemoryStream.Create;
        Try
          If ( Assigned( _1_o_variable[i])) Then _1_o_variable[i].SaveToStream( ms);
          itemLen := longword( ms.Size);
          SetLength( bmpRaw, itemLen);
          If ( itemLen > 0) Then Begin
            ms.Position := 0;
            ms.ReadBuffer( bmpRaw[0], itemLen);
          End;
        Finally
          ms.Free;
        End;
        If ( _3_e_offset + 4 + integer( itemLen) > Length( _2_by_blob)) Then SetLength( _2_by_blob, _3_e_offset + 4 + integer( itemLen));
        Move( itemLen, _2_by_blob[_3_e_offset], 4);
        Inc( _3_e_offset, 4);
        If ( itemLen > 0) Then Move( bmpRaw[0], _2_by_blob[_3_e_offset], itemLen);
        Inc( _3_e_offset, integer( itemLen));
      End;
      q4BlobSetOKSuccess;
    Except
      _3_e_offset := startOffset;
      q4BlobSetOKFailure;
    End;
  End;

Procedure variableToBLOB( Const _1_y_variable: TVariantArray; Var _2_by_blob: TBytes; _3_t_star: string = '');
  Var
    pos: int64;
  Begin
    q4BlobBeginOK;
    Try
      If ( _3_t_star = '*') Then pos := Length( _2_by_blob)
      Else Begin
        pos := 0;
        SetLength( _2_by_blob, 0);
      End;
      variableToBLOB( _1_y_variable, _2_by_blob, pos);
    Except
      q4BlobSetOKFailure;
    End;
  End;

Procedure variableToBLOB( Const _1_y_variable: TVariantArray; Var _2_by_blob: TBytes; Var _3_e_offset: int64);
  Var
    Count: longword;
    itemLen: longword;
    i:   integer;
    raw: TBytes;
    startOffset: int64;
  Begin
    q4BlobBeginOK;
    startOffset := _3_e_offset;
    Try
      Count := longword( Length( _1_y_variable));
      If ( _3_e_offset + 4 > Length( _2_by_blob)) Then SetLength( _2_by_blob, _3_e_offset + 4);
      Move( Count, _2_by_blob[_3_e_offset], 4);
      Inc( _3_e_offset, 4);
      For i := 0 To integer( Count) - 1 Do Begin
        raw := TEncoding.UTF8.GetBytes( VarToStr( _1_y_variable[i]));
        itemLen := longword( Length( raw));
        If ( _3_e_offset + 4 + integer( itemLen) > Length( _2_by_blob)) Then SetLength( _2_by_blob, _3_e_offset + 4 + integer( itemLen));
        Move( itemLen, _2_by_blob[_3_e_offset], 4);
        Inc( _3_e_offset, 4);
        If ( itemLen > 0) Then Move( raw[0], _2_by_blob[_3_e_offset], itemLen);
        Inc( _3_e_offset, integer( itemLen));
      End;
      q4BlobSetOKSuccess;
    Except
      _3_e_offset := startOffset;
      q4BlobSetOKFailure;
    End;
  End;

End.
