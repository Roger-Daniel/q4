Unit q4dataSecurity;

{$mode objfpc}{$H+}

{
q4dataSecurity
version du 2026/05/17

Mapping 4D
Command Number 4D,    4D Command,                      q4 API,                           Statut
------------------------------------------------------------------------------------------------
1609,                Data file encryption status,      *,                                Not supported,
1774,                Decrypt data BLOB,                decryptDataBLOB,                  OK q4 avec paramètre de sélection,
1639,                Discover data key,                *,                                Not supported,
1773,                Encrypt data BLOB,                encryptDataBLOB,                  OK q4 avec paramètre de sélection,
1610,                Encrypt data file,                *,                                Not supported,
1611,                New data key,                     newDataKey,                       OK,
1638,                Register data key,                registerDataKey,                  OK q4 avec paramètre de sélection,

Doc: https://developer.4d.com/docs/21/commands/theme/Data-Security

Notes q4
- Cette unité n'expose volontairement que les commandes marquées OK.
- Les commandes marquées Not supported n'ont pas d'API Pascal et ne doivent
  pas être appelées par le convertisseur.
- Object est mappé en JSON UTF-8 (string).
- BLOB est mappé sur TBytes.
- Les variantes 4D distinguant Text et Object se retrouvent toutes deux en
  string côté q4. Les surcharges Pascal correspondantes ne sont donc pas
  distinguables par FreePascal. Cette unité ajoute un paramètre Int64 de
  sélection pour préciser si la chaîne fournie est une phrase de passe ou un
  objet clé JSON.
- Implémentation crypto q4 pragmatique :
    * clé = SHA-256 UTF-8(passPhrase) encodé en hexadécimal
    * IV = premiers 16 octets de SHA-256(IntToStr(salt))
    * chiffrement = AES-256-CBC sans padding OpenSSL, avec padding zéro géré
      par q4 pour retrouver le comportement documenté de 4D sur la taille
      multiple de 16.
- Cette implémentation est cohérente et réversible dans q4, mais elle ne
  prétend pas reproduire bit à bit le format binaire natif 4D.
- Cette unité suppose que l'exécutable OpenSSL est disponible sur le PATH.
}

Interface

Const
  Q4DATASECURITY_OPENSSL_EXECUTABLE = 'openssl';

  Q4DATASECURITY_ERROR_NONE = 0;
  Q4DATASECURITY_ERROR_EMPTY_PASSPHRASE = 18001;
  Q4DATASECURITY_ERROR_INVALID_KEY_OBJECT = 18002;
  Q4DATASECURITY_ERROR_OPENSSL_UNAVAILABLE = 18003;
  Q4DATASECURITY_ERROR_OPENSSL_FAILURE = 18004;
  Q4DATASECURITY_ERROR_IO = 18005;
  Q4DATASECURITY_ERROR_INVALID_KEY_SOURCE = 18006;

  Q4DATASECURITY_KEY_SOURCE_PASSPHRASE = 1;
  Q4DATASECURITY_KEY_SOURCE_DATA_KEY = 2;
  Q4DATASECURITY_KEY_SOURCE_KEY_OBJECT = Q4DATASECURITY_KEY_SOURCE_DATA_KEY;

Type
  Tq4Bytes = Array Of byte;

Function newDataKey( Const _1_t_passPhrase: string): string;

Function registerDataKey( Const _1_t_passPhraseOrDataKey: string; _2_e_keySource: int64): boolean;

Function encryptDataBLOB( Const _1_x_blobToEncrypt: Tq4Bytes; Const _2_t_passPhraseOrDataKey: string; _3_e_keySource: int64; _4_e_salt: int64; out _5_x_encryptedBLOB: Tq4Bytes): boolean;

Function decryptDataBLOB( Const _1_x_blobToDecrypt: Tq4Bytes; Const _2_t_passPhraseOrDataKey: string; _3_e_keySource: int64; _4_e_salt: int64; out _5_x_decryptedBLOB: Tq4Bytes): boolean;

Implementation

Uses
  Classes,
  Process,
  SysUtils,
  q4coreLanguage;

Threadvar
  _t_registeredKeyChain: string;

Function q4DataSecurity_jsonEscape( Const _1_t_value: string): string;
  Var
    _t_result: string;
  Begin
    _t_result := SysUtils.StringReplace( _1_t_value, '\', '\\', [SysUtils.rfReplaceAll]);
    _t_result := SysUtils.StringReplace( _t_result, '"', '\"', [SysUtils.rfReplaceAll]);
    _t_result := SysUtils.StringReplace( _t_result, #13, '\r', [SysUtils.rfReplaceAll]);
    _t_result := SysUtils.StringReplace( _t_result, #10, '\n', [SysUtils.rfReplaceAll]);
    Result := _t_result;
  End;

Procedure q4DataSecurity_setSuccess;
  Begin
    Error := Q4DATASECURITY_ERROR_NONE;
    OK := 1;
  End;

Procedure q4DataSecurity_setFailure( Const _1_e_errorCode: int64);
  Begin
    Error := _1_e_errorCode;
    OK := 0;
  End;

Function q4DataSecurity_findCharFrom( Const _1_t_text: string; Const _2_c_search: char; Const _3_e_startPos: SizeInt): SizeInt;
  Var
    _e_index: SizeInt;
  Begin
    Result := 0;
    _e_index := _3_e_startPos;
    While ( _e_index <= System.Length( _1_t_text)) Do Begin
      If ( _1_t_text[_e_index] = _2_c_search) Then Begin
        Result := _e_index;
        Exit;
      End;
      Inc( _e_index);
    End;
  End;

Function q4DataSecurity_extractEncodedKey( Const _1_t_keyObject: string): string;
  Var
    _e_keyPos:   SizeInt;
    _e_colonPos: SizeInt;
    _e_startPos: SizeInt;
    _e_endPos:   SizeInt;
  Begin
    Result := '';

    _e_keyPos := System.Pos( '"encodedKey"', _1_t_keyObject);
    If ( _e_keyPos <= 0) Then Exit;

    _e_colonPos := q4DataSecurity_findCharFrom( _1_t_keyObject, ':', _e_keyPos + System.Length( '"encodedKey"'));
    If ( _e_colonPos <= 0) Then Exit;

    _e_startPos := _e_colonPos + 1;
    While ( ( _e_startPos <= System.Length( _1_t_keyObject)) and ( _1_t_keyObject[_e_startPos] in [' ', #9, #10, #13])) Do Inc( _e_startPos);

    If ( ( _e_startPos > System.Length( _1_t_keyObject)) or ( _1_t_keyObject[_e_startPos] <> '"')) Then Exit;

    Inc( _e_startPos);
    _e_endPos := _e_startPos;
    While ( _e_endPos <= System.Length( _1_t_keyObject)) Do Begin
      If ( ( _1_t_keyObject[_e_endPos] = '"') and ( ( _e_endPos = _e_startPos) or ( _1_t_keyObject[_e_endPos - 1] <> '\'))) Then Break;
      Inc( _e_endPos);
    End;

    If ( _e_endPos > System.Length( _1_t_keyObject)) Then Exit;

    Result := System.Copy( _1_t_keyObject, _e_startPos, _e_endPos - _e_startPos);
  End;

Function q4DataSecurity_hasRegisteredKey( Const _1_t_encodedKey: string): boolean;
  Var
    _e_startPos: SizeInt;
    _e_endPos:   SizeInt;
    _t_line:     string;
  Begin
    Result := False;
    If ( SysUtils.Trim( _t_registeredKeyChain) = '') Then Exit;

    _e_startPos := 1;
    While ( _e_startPos <= System.Length( _t_registeredKeyChain)) Do Begin
      _e_endPos := _e_startPos;
      While ( ( _e_endPos <= System.Length( _t_registeredKeyChain)) and ( _t_registeredKeyChain[_e_endPos] <> #10)) Do Inc( _e_endPos);

      _t_line := SysUtils.Trim( System.Copy( _t_registeredKeyChain, _e_startPos, _e_endPos - _e_startPos));
      If ( _t_line = _1_t_encodedKey) Then Begin
        Result := True;
        Exit;
      End;

      _e_startPos := _e_endPos + 1;
    End;
  End;

Procedure q4DataSecurity_registerEncodedKey( Const _1_t_encodedKey: string);
  Begin
    If ( SysUtils.Trim( _t_registeredKeyChain) = '') Then _t_registeredKeyChain := _1_t_encodedKey
    Else
      _t_registeredKeyChain := _t_registeredKeyChain + #10 + _1_t_encodedKey;
  End;

Function q4DataSecurity_bytesToFile( Const _1_t_fileName: string; Const _2_x_data: Tq4Bytes): boolean;
  Var
    _o_stream: Classes.TFileStream;
  Begin
    Result := False;
    Try
      _o_stream := Classes.TFileStream.Create( _1_t_fileName, fmCreate);
      Try
        If ( System.Length( _2_x_data) > 0) Then _o_stream.WriteBuffer( _2_x_data[0], System.Length( _2_x_data));
        Result := True;
      Finally
        _o_stream.Free;
      End;
    Except
      Result := False;
    End;
  End;

Function q4DataSecurity_fileToBytes( Const _1_t_fileName: string; out _2_x_data: Tq4Bytes): boolean;
  Var
    _o_stream: Classes.TFileStream;
    _e_size:   int64;
  Begin
    Result := False;
    System.SetLength( _2_x_data, 0);

    Try
      _o_stream := Classes.TFileStream.Create( _1_t_fileName, fmOpenRead or fmShareDenyNone);
      Try
        _e_size := _o_stream.Size;
        If ( _e_size < 0) Then Exit;

        System.SetLength( _2_x_data, _e_size);
        If ( _e_size > 0) Then _o_stream.ReadBuffer( _2_x_data[0], _e_size);
        Result := True;
      Finally
        _o_stream.Free;
      End;
    Except
      Result := False;
    End;
  End;

Function q4DataSecurity_tempFileName( Const _1_t_extension: string): string;
  Begin
    Result := SysUtils.GetTempDir( False) + SysUtils.Format( 'q4ds_%s_%d%s', [SysUtils.FormatDateTime( 'yyyymmddhhnnsszzz', SysUtils.Now), System.Random( 1000000), _1_t_extension]);
  End;

Function q4DataSecurity_textToTempFile( Const _1_t_text: string; out _2_t_fileName: string): boolean;
  Var
    _o_stream: Classes.TFileStream;
  Begin
    Result := False;
    _2_t_fileName := '';
    Try
      _2_t_fileName := q4DataSecurity_tempFileName( '.txt');
      _o_stream := Classes.TFileStream.Create( _2_t_fileName, fmCreate);
      Try
        If ( _1_t_text <> '') Then _o_stream.WriteBuffer( _1_t_text[1], System.Length( _1_t_text));
        Result := True;
      Finally
        _o_stream.Free;
      End;
    Except
      Result := False;
    End;
  End;

Function q4DataSecurity_bytesToTempFile( Const _1_x_data: Tq4Bytes; Const _2_t_extension: string; out _3_t_fileName: string): boolean;
  Begin
    Result := False;
    _3_t_fileName := '';
    _3_t_fileName := q4DataSecurity_tempFileName( _2_t_extension);
    Result := q4DataSecurity_bytesToFile( _3_t_fileName, _1_x_data);
  End;

Function q4DataSecurity_runProcess( Const _1_tt_parameters: Array Of string; out _2_t_output: string): boolean;
  Var
    _o_process: Process.TProcess;
    _o_output:  Classes.TStringStream;
    _e_index:   SizeInt;
  Begin
    Result := False;
    _2_t_output := '';

    _o_process := Process.TProcess.Create( nil);
    _o_output := Classes.TStringStream.Create( '');
    Try
      _o_process.Executable := Q4DATASECURITY_OPENSSL_EXECUTABLE;
      _o_process.Options := [Process.poUsePipes, Process.poWaitOnExit, Process.poStderrToOutput];
      For _e_index := 0 To System.High( _1_tt_parameters) Do _o_process.Parameters.Add( _1_tt_parameters[_e_index]);

      Try
        _o_process.Execute;
        _o_output.CopyFrom( _o_process.Output, 0);
        _2_t_output := _o_output.DataString;
        Result := ( _o_process.ExitStatus = 0);
      Except
        _2_t_output := '';
        Result := False;
      End;
    Finally
      _o_output.Free;
      _o_process.Free;
    End;
  End;

Function q4DataSecurity_sha256HexFromText( Const _1_t_text: string): string;
  Var
    _t_inputFileName: string;
    _t_output:   string;
    _e_spacePos: SizeInt;
  Begin
    Result := '';
    If ( not q4DataSecurity_textToTempFile( _1_t_text, _t_inputFileName)) Then Exit;

    Try
      If ( not q4DataSecurity_runProcess( ['dgst', '-sha256', '-r', _t_inputFileName], _t_output)) Then Exit;

      _t_output := SysUtils.Trim( _t_output);
      _e_spacePos := System.Pos( ' ', _t_output);
      If ( _e_spacePos > 1) Then Result := SysUtils.LowerCase( SysUtils.Trim( System.Copy( _t_output, 1, _e_spacePos - 1)))
      Else
        Result := SysUtils.LowerCase( _t_output);
    Finally
      If ( SysUtils.FileExists( _t_inputFileName)) Then SysUtils.DeleteFile( _t_inputFileName);
    End;
  End;

Function q4DataSecurity_ivHexFromSalt( Const _1_e_salt: int64): string;
  Var
    _t_hash: string;
  Begin
    _t_hash := q4DataSecurity_sha256HexFromText( SysUtils.IntToStr( _1_e_salt));
    If ( System.Length( _t_hash) >= 32) Then Result := System.Copy( _t_hash, 1, 32)
    Else
      Result := '';
  End;

Function q4DataSecurity_padZero16( Const _1_x_input: Tq4Bytes): Tq4Bytes;
  Var
    _e_inputLength:  SizeInt;
    _e_paddedLength: SizeInt;
    _e_padding:      SizeInt;
  Begin
    _e_inputLength := System.Length( _1_x_input);
    _e_padding := _e_inputLength mod 16;
    If ( _e_padding = 0) Then _e_paddedLength := _e_inputLength
    Else
      _e_paddedLength := _e_inputLength + ( 16 - _e_padding);

    System.SetLength( Result, _e_paddedLength);
    If ( _e_inputLength > 0) Then System.Move( _1_x_input[0], Result[0], _e_inputLength);
    If ( _e_paddedLength > _e_inputLength) Then System.FillChar( Result[_e_inputLength], _e_paddedLength - _e_inputLength, 0);
  End;

Function q4DataSecurity_cryptoOpenSSL( Const _1_x_input: Tq4Bytes; Const _2_t_keyHex: string; Const _3_e_salt: int64; Const _4_b_decrypt: boolean; out _5_x_output: Tq4Bytes): boolean;
  Var
    _x_workData: Tq4Bytes;
    _t_inputFileName: string;
    _t_outputFileName: string;
    _t_ivHex:  string;
    _t_output: string;
  Begin
    Result := False;
    System.SetLength( _5_x_output, 0);

    _t_ivHex := q4DataSecurity_ivHexFromSalt( _3_e_salt);
    If ( ( _2_t_keyHex = '') or ( _t_ivHex = '')) Then Begin
      q4DataSecurity_setFailure( Q4DATASECURITY_ERROR_INVALID_KEY_OBJECT);
      Exit;
    End;

    If ( _4_b_decrypt) Then _x_workData := _1_x_input
    Else
      _x_workData := q4DataSecurity_padZero16( _1_x_input);

    If ( not q4DataSecurity_bytesToTempFile( _x_workData, '.bin', _t_inputFileName)) Then Begin
      q4DataSecurity_setFailure( Q4DATASECURITY_ERROR_IO);
      Exit;
    End;

    _t_outputFileName := SysUtils.ChangeFileExt( _t_inputFileName, '.out');

    Try
      If ( _4_b_decrypt) Then Begin
        If ( not q4DataSecurity_runProcess( ['enc', '-d', '-aes-256-cbc', '-nopad', '-K', _2_t_keyHex, '-iv', _t_ivHex, '-in', _t_inputFileName, '-out', _t_outputFileName], _t_output)) Then Begin
          q4DataSecurity_setFailure( Q4DATASECURITY_ERROR_OPENSSL_FAILURE);
          Exit;
        End;
      End Else If ( not q4DataSecurity_runProcess( ['enc', '-aes-256-cbc', '-nopad', '-K', _2_t_keyHex, '-iv', _t_ivHex, '-in', _t_inputFileName, '-out', _t_outputFileName], _t_output)) Then Begin
        q4DataSecurity_setFailure( Q4DATASECURITY_ERROR_OPENSSL_FAILURE);
        Exit;
      End;

      If ( not q4DataSecurity_fileToBytes( _t_outputFileName, _5_x_output)) Then Begin
        q4DataSecurity_setFailure( Q4DATASECURITY_ERROR_IO);
        Exit;
      End;

      q4DataSecurity_setSuccess;
      Result := True;
    Finally
      If ( SysUtils.FileExists( _t_inputFileName)) Then SysUtils.DeleteFile( _t_inputFileName);
      If ( SysUtils.FileExists( _t_outputFileName)) Then SysUtils.DeleteFile( _t_outputFileName);
    End;
  End;

Function q4DataSecurity_keyHexFromKeyObject( Const _1_t_keyObject: string): string;
  Begin
    Result := q4DataSecurity_extractEncodedKey( _1_t_keyObject);
  End;

Function q4DataSecurity_keyHexFromPassPhrase( Const _1_t_passPhrase: string): string;
  Var
    _t_json: string;
  Begin
    _t_json := newDataKey( _1_t_passPhrase);
    Result := q4DataSecurity_extractEncodedKey( _t_json);
  End;

Function q4DataSecurity_keyHexFromSelectedSource( Const _1_t_passPhraseOrDataKey: string; _2_e_keySource: int64; out _3_e_errorCode: int64): string;
  Begin
    Result := '';
    _3_e_errorCode := Q4DATASECURITY_ERROR_NONE;

    Case _2_e_keySource Of
      Q4DATASECURITY_KEY_SOURCE_PASSPHRASE: Begin
        If ( _1_t_passPhraseOrDataKey = '') Then Begin
          _3_e_errorCode := Q4DATASECURITY_ERROR_EMPTY_PASSPHRASE;
          Exit;
        End;

        Result := q4DataSecurity_keyHexFromPassPhrase( _1_t_passPhraseOrDataKey);
        If ( Result = '') Then If ( Error <> Q4DATASECURITY_ERROR_NONE) Then _3_e_errorCode := Error
          Else
            _3_e_errorCode := Q4DATASECURITY_ERROR_OPENSSL_UNAVAILABLE;
      End;

      Q4DATASECURITY_KEY_SOURCE_DATA_KEY: Begin
        Result := q4DataSecurity_keyHexFromKeyObject( _1_t_passPhraseOrDataKey);
        If ( Result = '') Then _3_e_errorCode := Q4DATASECURITY_ERROR_INVALID_KEY_OBJECT;
      End;

      Else _3_e_errorCode := Q4DATASECURITY_ERROR_INVALID_KEY_SOURCE;
    End;
  End;

Function newDataKey( Const _1_t_passPhrase: string): string;
  Var
    _t_encodedKey: string;
  Begin
    //https://developer.4d.com/docs/21/commands/new-data-key
    If ( _1_t_passPhrase = '') Then Begin
      q4DataSecurity_setFailure( Q4DATASECURITY_ERROR_EMPTY_PASSPHRASE);
      Result := 'null';
      Exit;
    End;

    _t_encodedKey := q4DataSecurity_sha256HexFromText( _1_t_passPhrase);
    If ( _t_encodedKey = '') Then Begin
      q4DataSecurity_setFailure( Q4DATASECURITY_ERROR_OPENSSL_UNAVAILABLE);
      Result := 'null';
      Exit;
    End;

    Result := '{"encodedKey":"' + q4DataSecurity_jsonEscape( _t_encodedKey) + '"}';
    q4DataSecurity_setSuccess;
  End;

Function registerDataKey( Const _1_t_passPhraseOrDataKey: string; _2_e_keySource: int64): boolean;
  Var
    _t_dataKey:    string;
    _t_encodedKey: string;
  Begin
    //https://developer.4d.com/docs/21/commands/register-data-key
    Result := False;
    _t_encodedKey := '';

    Case _2_e_keySource Of
      Q4DATASECURITY_KEY_SOURCE_PASSPHRASE: Begin
        _t_dataKey := newDataKey( _1_t_passPhraseOrDataKey);
        If ( _t_dataKey = 'null') Then Exit;
        _t_encodedKey := q4DataSecurity_extractEncodedKey( _t_dataKey);
      End;

      Q4DATASECURITY_KEY_SOURCE_DATA_KEY: Begin
        _t_encodedKey := q4DataSecurity_extractEncodedKey( _1_t_passPhraseOrDataKey);
        If ( _t_encodedKey = '') Then Begin
          q4DataSecurity_setFailure( Q4DATASECURITY_ERROR_INVALID_KEY_OBJECT);
          Exit;
        End;
      End;

      Else q4DataSecurity_setFailure( Q4DATASECURITY_ERROR_INVALID_KEY_SOURCE);
        Exit;
    End;

    If ( _t_encodedKey = '') Then Begin
      q4DataSecurity_setFailure( Q4DATASECURITY_ERROR_INVALID_KEY_OBJECT);
      Exit;
    End;

    If ( q4DataSecurity_hasRegisteredKey( _t_encodedKey)) Then Begin
      q4DataSecurity_setSuccess;
      Result := False;
      Exit;
    End;

    q4DataSecurity_registerEncodedKey( _t_encodedKey);
    q4DataSecurity_setSuccess;
    Result := True;
  End;

Function encryptDataBLOB( Const _1_x_blobToEncrypt: Tq4Bytes; Const _2_t_passPhraseOrDataKey: string; _3_e_keySource: int64; _4_e_salt: int64; out _5_x_encryptedBLOB: Tq4Bytes): boolean;
  Var
    _t_keyHex:    string;
    _e_errorCode: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/encrypt-data-blob
    _t_keyHex := q4DataSecurity_keyHexFromSelectedSource( _2_t_passPhraseOrDataKey, _3_e_keySource, _e_errorCode);
    If ( _t_keyHex = '') Then Begin
      q4DataSecurity_setFailure( _e_errorCode);
      System.SetLength( _5_x_encryptedBLOB, 0);
      Result := False;
      Exit;
    End;

    Result := q4DataSecurity_cryptoOpenSSL( _1_x_blobToEncrypt, _t_keyHex, _4_e_salt, False, _5_x_encryptedBLOB);
  End;

Function decryptDataBLOB( Const _1_x_blobToDecrypt: Tq4Bytes; Const _2_t_passPhraseOrDataKey: string; _3_e_keySource: int64; _4_e_salt: int64; out _5_x_decryptedBLOB: Tq4Bytes): boolean;
  Var
    _t_keyHex:    string;
    _e_errorCode: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/decrypt-data-blob
    _t_keyHex := q4DataSecurity_keyHexFromSelectedSource( _2_t_passPhraseOrDataKey, _3_e_keySource, _e_errorCode);
    If ( _t_keyHex = '') Then Begin
      q4DataSecurity_setFailure( _e_errorCode);
      System.SetLength( _5_x_decryptedBLOB, 0);
      Result := False;
      Exit;
    End;

    Result := q4DataSecurity_cryptoOpenSSL( _1_x_blobToDecrypt, _t_keyHex, _4_e_salt, True, _5_x_decryptedBLOB);
  End;

Initialization
  System.Randomize;
  Error := Q4DATASECURITY_ERROR_NONE;
  OK := 1;
  _t_registeredKeyChain := '';

End.
