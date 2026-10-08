Unit q4tools;

{$mode objfpc}{$H+}

{
q4tools
version du 2026/05/16-06

Mapping 4D → q4tools -> statut
Command Number 4D,    4D Command,                        q4 API,                           Statut,                        Thread
--------------------------------------------------------------------------------------------------------------------------------
1277,                 ACTIVITY SNAPSHOT,                 activitySnapshot,                 TODO monitoring,                yes,
896,                  BASE64 DECODE,                     base64Decode,                     OK simple,                     yes,
895,                  BASE64 ENCODE,                     base64Encode,                     OK simple,                     yes,
955,                  Choose (Boolean syntax),           chooseBoolean,                    OK simple,                      yes,
955,                  Choose (Integer syntax),           chooseInteger,                    OK simple,                      yes,
1147,                 Generate digest,                   generateDigest,                   TODO stub explicite,            yes,
1533,                 Generate password hash,            generatePasswordHash,             TODO Argon2id/bcrypt à décider, yes,
1066,                 Generate UUID,                     generateUUID,                     OK v4 / TODO v7,              yes,
997,                  GET MACRO PARAMETER,               getMacroParameter,                Not supported / IDE 4D,         no,
811,                  LAUNCH EXTERNAL PROCESS,           launchExternalProcess,            TODO OS-specific,               yes,
1528,                 Load 4D View document,             loadQ4ViewDocument,               Not supported / legacy 4D View, yes,
1596,                 MOBILE APP REFRESH SESSIONS,       mobileAppRefreshSessions,         Not supported / 4D Mobile,      yes,
1713,                 Monitored activity,                monitoredActivity,                TODO monitoring,                yes,
673,                  OPEN URL,                          openURL,                          OK simple / TODO URL encoding, yes,
816,                  PROCESS 4D TAGS,                   processQ4Tags,                    Not supported / moteur tags 4D, yes,
812,                  SET ENVIRONMENT VARIABLE,          setEnvironmentVariable,           TODO contexte launchExternalProcess, yes,
998,                  SET MACRO PARAMETER,               setMacroParameter,                Not supported / IDE 4D,         no,
1712,                 START MONITORING ACTIVITY,         startMonitoringActivity,          TODO monitoring,                yes,
1721,                 STOP MONITORING ACTIVITY,          stopMonitoringActivity,           TODO monitoring,                yes,
1534,                 Verify password hash,              verifyPasswordHash,               TODO Argon2id/bcrypt à décider, yes,

Notes de conception validées
----------------------------------------------------------------------------------------------
- Les commandes non réellement implémentées doivent échouer explicitement avec message et arrêt ;
  aucun comportement silencieux.
- Choose est volontairement scindé en chooseBoolean et chooseInteger pour tenir compte des
  contraintes FreePascal.
- SET ENVIRONMENT VARIABLE remplit un contexte thread-local consommé par le prochain
  launchExternalProcess puis vidé.
- Le monitoring est spécifié maintenant mais ne sera branché que plus tard.
- BASE64URL est implémenté sans padding final, avec décodage tolérant sur padding absent.
- generatePasswordHash / verifyPasswordHash restent en TODO ; préférence future pour Argon2id
  si une dépendance externe acceptable est retenue. 4D 21 documente bcrypt uniquement.
- Les noms Pascal évitent "4D" dans l'API q4 quand le nom 4D contient "4D" : processQ4Tags,
  loadQ4ViewDocument.

Doc: https://developer.4d.com/docs/21/commands/theme/Tools
}

Interface

Uses
  Classes,
  SysUtils
  {$IFDEF MSWINDOWS},
  Windows
  {$ELSE},
  Process
  {$ENDIF};

Type
  Tq4TextArray = Array Of string;
  Tq4Int64Array = Array Of int64;
  Tq4BooleanArray = Array Of boolean;
  Tq4RealArray = Array Of double;
  Tq4ObjectArray = Array Of string; // objets JSON pour l'instant
  Tq4Bytes = TBytes;

Const
  // Generate digest algorithms.
  Q4_MD5_DIGEST = 0;
  Q4_SHA1_DIGEST = 1;
  Q4_4D_REST_DIGEST = 2; // obsolete côté 4D ; non recommandé
  Q4_SHA256_DIGEST = 3;
  Q4_SHA512_DIGEST = 4;

  // Monitoring sources.
  Q4_ACTIVITY_ALL = -1;
  Q4_ACTIVITY_LANGUAGE = 1;
  Q4_ACTIVITY_NETWORK = 2;
  Q4_ACTIVITY_OPERATIONS = 4;

  // Macro selectors (thème 4D Environment en 4D, gardés ici à titre pratique).
  Q4_FULL_METHOD_TEXT = 1;
  Q4_HIGHLIGHTED_METHOD_TEXT = 2;

  // Special environment variables for launchExternalProcess.
  Q4_OPTION_CURRENT_DIRECTORY = '_4D_OPTION_CURRENT_DIRECTORY';
  Q4_OPTION_HIDE_CONSOLE = '_4D_OPTION_HIDE_CONSOLE';
  Q4_OPTION_BLOCKING_EXTERNAL_PROCESS = '_4D_OPTION_BLOCKING_EXTERNAL_PROCESS';

Function chooseBoolean( _1_b_criterion: boolean; Const _2_t_trueValue: string; Const _3_t_falseValue: string): string; overload;
Function chooseBoolean( _1_b_criterion: boolean; _2_e_trueValue: int64; _3_e_falseValue: int64): int64; overload;
Function chooseBoolean( _1_b_criterion: boolean; _2_r_trueValue: double; _3_r_falseValue: double): double; overload;
Function chooseBoolean( _1_b_criterion: boolean; _2_b_trueValue: boolean; _3_b_falseValue: boolean): boolean; overload;

Function chooseInteger( _1_e_criterion: int64; Const _2_at_values: Array Of string): string; overload;
Function chooseInteger( _1_e_criterion: int64; Const _2_ae_values: Array Of int64): int64; overload;
Function chooseInteger( _1_e_criterion: int64; Const _2_ar_values: Array Of double): double; overload;
Function chooseInteger( _1_e_criterion: int64; Const _2_ab_values: Array Of boolean): boolean; overload;

Function base64Encode( Const _1_t_toEncode: string; Const _2_t_operator: string = ''): string; overload;
Function base64Encode( Const _1_y_toEncode: TBytes; Const _2_t_operator: string = ''): string; overload;
Function base64Decode( Const _1_t_toDecode: string; Const _2_t_operator: string = ''): string; overload;
Function base64DecodeToBytes( Const _1_t_toDecode: string; Const _2_t_operator: string = ''): TBytes;

Function generateDigest( Const _1_t_param: string; _2_e_algorithm: int64; Const _3_t_operator: string = ''): string; overload;
Function generateDigest( Const _1_y_param: TBytes; _2_e_algorithm: int64; Const _3_t_operator: string = ''): string; overload;

Function generateUUID: string; overload;
Function generateUUID( _1_e_version: int64): string; overload;

Procedure setEnvironmentVariable( Const _1_t_varName: string; Const _2_t_varValue: string);
Procedure launchExternalProcess( Const _1_t_fileName: string; Const _2_t_inputStream: string; out _3_t_outputStream: string; out _4_t_errorStream: string; out _5_e_pid: int64); overload;
Procedure launchExternalProcess( Const _1_t_fileName: string; Const _2_y_inputStream: TBytes; out _3_y_outputStream: TBytes; out _4_y_errorStream: TBytes; out _5_e_pid: int64); overload;
Procedure openURL( Const _1_t_path: string; Const _2_t_appName: string = ''; Const _3_t_operator: string = '');

Procedure startMonitoringActivity( _1_r_duration: double; _2_e_source: int64 = Q4_ACTIVITY_ALL);
Procedure stopMonitoringActivity;
Function monitoredActivity: string;
Procedure activitySnapshot( Var _1_at_uuid: Tq4TextArray; Var _2_at_start: Tq4TextArray; Var _3_ae_duration: Tq4Int64Array; Var _4_at_info: Tq4TextArray; Var _5_ao_details: Tq4ObjectArray); overload;
Function activitySnapshot: string; overload;

Function generatePasswordHash( Const _1_t_password: string; Const _2_t_optionsJson: string = ''): string;
Function verifyPasswordHash( Const _1_t_password: string; Const _2_t_hash: string): boolean;

Procedure getMacroParameter( _1_e_selector: int64; out _2_t_textParam: string);
Procedure setMacroParameter( _1_e_selector: int64; Const _2_t_textParam: string);
Function processQ4Tags( Const _1_t_inputTemplate: string; Const _2_at_params: Array Of string): string;
Function loadQ4ViewDocument( Const _1_y_q4ViewDocument: TBytes): string;
Procedure mobileAppRefreshSessions;

Implementation

Procedure failNotSupported( Const _1_t_featureName: string);
  Begin
    // TODO: brancher q4interruptions.asserted quand l'unité sera reliée.
    Raise Exception.Create( _1_t_featureName + ' is not supported in q4tools yet');
  End;

Function q4IsStarOperator( Const _1_t_operator: string): boolean;
  Begin
    Result := ( _1_t_operator = '*');
  End;

Function q4StringToBytes( Const _1_t_value: string): TBytes;
  Begin
    SetLength( Result, Length( _1_t_value));
    If ( Length( _1_t_value) > 0) Then Move( _1_t_value[1], Result[0], Length( _1_t_value));
  End;

Function q4BytesToString( Const _1_y_value: TBytes): string;
  Begin
    If ( Length( _1_y_value) = 0) Then Exit( '');
    SetString( Result, PChar( @_1_y_value[0]), Length( _1_y_value));
  End;

Function q4Base64EncodeBytes( Const _1_y_value: TBytes; _2_b_urlVariant: boolean): string;
  Const
    Q4_BASE64_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    Q4_BASE64URL_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  Var
    _t_alphabet: string;
    _e_i:     SizeInt;
    _e_b0:    byte;
    _e_b1:    byte;
    _e_b2:    byte;
    _b_hasB1: boolean;
    _b_hasB2: boolean;
  Begin
    If ( _2_b_urlVariant) Then _t_alphabet := Q4_BASE64URL_ALPHABET
    Else
      _t_alphabet := Q4_BASE64_ALPHABET;

    Result := '';
    _e_i := 0;
    While ( _e_i < Length( _1_y_value)) Do Begin
      _e_b0 := _1_y_value[_e_i];
      Inc( _e_i);

      _b_hasB1 := ( _e_i < Length( _1_y_value));
      If ( _b_hasB1) Then Begin
        _e_b1 := _1_y_value[_e_i];
        Inc( _e_i);
      End Else
        _e_b1 := 0;

      _b_hasB2 := ( _e_i < Length( _1_y_value));
      If ( _b_hasB2) Then Begin
        _e_b2 := _1_y_value[_e_i];
        Inc( _e_i);
      End Else
        _e_b2 := 0;

      Result := Result + _t_alphabet[( _e_b0 shr 2) + 1];
      Result := Result + _t_alphabet[( ( ( _e_b0 and $03) shl 4) or ( _e_b1 shr 4)) + 1];

      If ( _b_hasB1) Then Result := Result + _t_alphabet[( ( ( _e_b1 and $0F) shl 2) or ( _e_b2 shr 6)) + 1]
      Else If ( not _2_b_urlVariant) Then Result := Result + '=';

      If ( _b_hasB2) Then Result := Result + _t_alphabet[( _e_b2 and $3F) + 1]
      Else If ( not _2_b_urlVariant) Then Result := Result + '=';
    End;
  End;

Function q4Base64CharValue( _1_c_value: char; _2_b_urlVariant: boolean): integer;
  Begin
    Case _1_c_value Of
      'A'..'Z': Result := Ord( _1_c_value) - Ord( 'A');
      'a'..'z': Result := Ord( _1_c_value) - Ord( 'a') + 26;
      '0'..'9': Result := Ord( _1_c_value) - Ord( '0') + 52;
      '+': If ( not _2_b_urlVariant) Then Result := 62
        Else
          Result := -1;
      '/': If ( not _2_b_urlVariant) Then Result := 63
        Else
          Result := -1;
      '-': If ( _2_b_urlVariant) Then Result := 62
        Else
          Result := -1;
      '_': If ( _2_b_urlVariant) Then Result := 63
        Else
          Result := -1;
      Else Result := -1;
    End;
  End;

Function q4Base64DecodeBytes( Const _1_t_value: string; _2_b_urlVariant: boolean): TBytes;
  Var
    _t_normalized: string;
    _e_remainder: SizeInt;
    _e_i:  SizeInt;
    _e_outIndex: SizeInt;
    _e_v0: integer;
    _e_v1: integer;
    _e_v2: integer;
    _e_v3: integer;
    _c_c2: char;
    _c_c3: char;

  Procedure failInvalid;
    Begin
      SetLength( Result, 0);
      _e_outIndex := -1;
    End;

  Begin
    Result := nil;
    _t_normalized := _1_t_value;

    If ( _t_normalized = '') Then Exit;

    _e_remainder := Length( _t_normalized) mod 4;
    If ( _2_b_urlVariant) Then Case _e_remainder Of
        0: ;
        2: _t_normalized := _t_normalized + '==';
        3: _t_normalized := _t_normalized + '=';
        Else Begin
          SetLength( Result, 0);
          Exit;
        End;
      End Else If ( _e_remainder <> 0) Then Begin
      SetLength( Result, 0);
      Exit;
    End;

    SetLength( Result, ( Length( _t_normalized) div 4) * 3);
    _e_outIndex := 0;
    _e_i := 1;

    While ( ( _e_i <= Length( _t_normalized)) and ( _e_outIndex >= 0)) Do Begin
      _c_c2 := _t_normalized[_e_i + 2];
      _c_c3 := _t_normalized[_e_i + 3];

      _e_v0 := q4Base64CharValue( _t_normalized[_e_i], _2_b_urlVariant);
      _e_v1 := q4Base64CharValue( _t_normalized[_e_i + 1], _2_b_urlVariant);
      If ( ( _e_v0 < 0) or ( _e_v1 < 0)) Then Begin
        failInvalid;
        Break;
      End;

      If ( _c_c2 = '=') Then Begin
        If ( ( _c_c3 <> '=') or ( _e_i + 3 <> Length( _t_normalized))) Then Begin
          failInvalid;
          Break;
        End;
        _e_v2 := 0;
        _e_v3 := 0;
      End Else Begin
        _e_v2 := q4Base64CharValue( _c_c2, _2_b_urlVariant);
        If ( _e_v2 < 0) Then Begin
          failInvalid;
          Break;
        End;

        If ( _c_c3 = '=') Then Begin
          If ( _e_i + 3 <> Length( _t_normalized)) Then Begin
            failInvalid;
            Break;
          End;
          _e_v3 := 0;
        End Else Begin
          _e_v3 := q4Base64CharValue( _c_c3, _2_b_urlVariant);
          If ( _e_v3 < 0) Then Begin
            failInvalid;
            Break;
          End;
        End;
      End;

      Result[_e_outIndex] := byte( ( _e_v0 shl 2) or ( _e_v1 shr 4));
      Inc( _e_outIndex);

      If ( _c_c2 <> '=') Then Begin
        Result[_e_outIndex] := byte( ( ( _e_v1 and $0F) shl 4) or ( _e_v2 shr 2));
        Inc( _e_outIndex);
      End;

      If ( _c_c3 <> '=') Then Begin
        Result[_e_outIndex] := byte( ( ( _e_v2 and $03) shl 6) or _e_v3);
        Inc( _e_outIndex);
      End;

      Inc( _e_i, 4);
    End;

    If ( _e_outIndex >= 0) Then SetLength( Result, _e_outIndex);
  End;

Function q4GuidToNonCanonicalText( Const _1_g_guid: TGUID): string;
  Var
    _t_canonical: string;
    _e_i:     SizeInt;
    _c_value: char;
  Begin
    _t_canonical := GUIDToString( _1_g_guid);
    Result := '';
    For _e_i := 1 To Length( _t_canonical) Do Begin
      _c_value := _t_canonical[_e_i];
      If ( _c_value in ['0'..'9', 'A'..'F', 'a'..'f']) Then Result := Result + _c_value;
    End;
    Result := LowerCase( Result);
  End;


Procedure q4RunDetachedProcess( Const _1_t_executable: string; Const _2_at_parameters: Array Of string);
{$IFDEF MSWINDOWS}
  Begin
    // Sur Windows, openURL utilise ShellExecute plus bas.
    failNotSupported( 'q4tools.q4RunDetachedProcess is not used on Windows');
  End;
{$ELSE}
var
  _o_process: TProcess;
  _e_i: SizeInt;
begin
  _o_process := TProcess.Create(nil);
  try
    _o_process.Executable := _1_t_executable;
    for _e_i := Low(_2_at_parameters) to High(_2_at_parameters) do
      _o_process.Parameters.Add(_2_at_parameters[_e_i]);
    _o_process.Options := [];
    _o_process.Execute;
  finally
    _o_process.Free;
  end;
end;
{$ENDIF}

Procedure q4OpenURLSystem( Const _1_t_path: string; Const _2_t_appName: string);
{$IFDEF MSWINDOWS}
  Var
    _e_result: PtrUInt;
  Begin
    If ( _2_t_appName <> '') Then Begin
      _e_result := PtrUInt( ShellExecute( 0, 'open', PChar( _2_t_appName), PChar( _1_t_path), nil, SW_SHOWNORMAL));
      If ( _e_result > 32) Then Exit;
    End;

    // 4D ne signale pas d'erreur si l'application demandée est introuvable ; il réessaie
    // comme si appName n'avait pas été passé. On reproduit cette logique.
    ShellExecute( 0, 'open', PChar( _1_t_path), nil, nil, SW_SHOWNORMAL);
  End;
{$ELSE}
begin
  {$IFDEF DARWIN}
  if ( _2_t_appName <> '') then
    q4RunDetachedProcess('/usr/bin/open', ['-a', _2_t_appName, _1_t_path])
  else
    q4RunDetachedProcess('/usr/bin/open', [_1_t_path]);
  {$ELSE}
  if ( _2_t_appName <> '') then
    q4RunDetachedProcess(_2_t_appName, [_1_t_path])
  else
    q4RunDetachedProcess('xdg-open', [_1_t_path]);
  {$ENDIF}
end;
{$ENDIF}

Function q4PrepareOpenURLPath( Const _1_t_path: string; _2_b_noTranslation: boolean): string;
  Begin
    // 4D encode automatiquement certains caractères spéciaux d'URL quand l'opérateur * est omis.
    // Pour cette première implémentation q4, on conserve la chaîne telle quelle afin de ne pas
    // dégrader les URL déjà composées (requêtes http, mailto, file://, chemins locaux).
    // TODO: décider si q4 doit émuler strictement cette traduction 4D ou rester pass-through.
    Result := _1_t_path;
  End;

Function chooseBoolean( _1_b_criterion: boolean; Const _2_t_trueValue: string; Const _3_t_falseValue: string): string;
  Begin
    If ( _1_b_criterion) Then Exit( _2_t_trueValue);
    Result := _3_t_falseValue;
  End;

Function chooseBoolean( _1_b_criterion: boolean; _2_e_trueValue: int64; _3_e_falseValue: int64): int64;
  Begin
    If ( _1_b_criterion) Then Exit( _2_e_trueValue);
    Result := _3_e_falseValue;
  End;

Function chooseBoolean( _1_b_criterion: boolean; _2_r_trueValue: double; _3_r_falseValue: double): double;
  Begin
    If ( _1_b_criterion) Then Exit( _2_r_trueValue);
    Result := _3_r_falseValue;
  End;

Function chooseBoolean( _1_b_criterion: boolean; _2_b_trueValue: boolean; _3_b_falseValue: boolean): boolean;
  Begin
    If ( _1_b_criterion) Then Exit( _2_b_trueValue);
    Result := _3_b_falseValue;
  End;

Function chooseInteger( _1_e_criterion: int64; Const _2_at_values: Array Of string): string;
  Begin
    If ( ( _1_e_criterion < Low( _2_at_values)) or ( _1_e_criterion > High( _2_at_values))) Then Exit( '');
    Result := _2_at_values[SizeInt( _1_e_criterion)];
  End;

Function chooseInteger( _1_e_criterion: int64; Const _2_ae_values: Array Of int64): int64;
  Begin
    If ( ( _1_e_criterion < Low( _2_ae_values)) or ( _1_e_criterion > High( _2_ae_values))) Then Exit( 0);
    Result := _2_ae_values[SizeInt( _1_e_criterion)];
  End;

Function chooseInteger( _1_e_criterion: int64; Const _2_ar_values: Array Of double): double;
  Begin
    If ( ( _1_e_criterion < Low( _2_ar_values)) or ( _1_e_criterion > High( _2_ar_values))) Then Exit( 0.0);
    Result := _2_ar_values[SizeInt( _1_e_criterion)];
  End;

Function chooseInteger( _1_e_criterion: int64; Const _2_ab_values: Array Of boolean): boolean;
  Begin
    If ( ( _1_e_criterion < Low( _2_ab_values)) or ( _1_e_criterion > High( _2_ab_values))) Then Exit( False);
    Result := _2_ab_values[SizeInt( _1_e_criterion)];
  End;

Function base64Encode( Const _1_t_toEncode: string; Const _2_t_operator: string): string;
  Begin
    // 4D command 895 - BASE64 ENCODE
    // https://developer.4d.com/docs/21/commands/base64-encode
    // Le texte q4 est supposé déjà stocké en UTF-8 ; on encode donc ses octets.
    Result := q4Base64EncodeBytes( q4StringToBytes( _1_t_toEncode), q4IsStarOperator( _2_t_operator));
  End;

Function base64Encode( Const _1_y_toEncode: TBytes; Const _2_t_operator: string): string;
  Begin
    // 4D command 895 - BASE64 ENCODE
    // https://developer.4d.com/docs/21/commands/base64-encode
    Result := q4Base64EncodeBytes( _1_y_toEncode, q4IsStarOperator( _2_t_operator));
  End;

Function base64Decode( Const _1_t_toDecode: string; Const _2_t_operator: string): string;
  Begin
    // 4D command 896 - BASE64 DECODE
    // https://developer.4d.com/docs/21/commands/base64-decode
    // En cas de contenu Base64 invalide, 4D retourne une valeur texte/blob vide.
    Result := q4BytesToString( base64DecodeToBytes( _1_t_toDecode, _2_t_operator));
  End;

Function base64DecodeToBytes( Const _1_t_toDecode: string; Const _2_t_operator: string): TBytes;
  Begin
    // 4D command 896 - BASE64 DECODE
    // https://developer.4d.com/docs/21/commands/base64-decode
    Result := q4Base64DecodeBytes( _1_t_toDecode, q4IsStarOperator( _2_t_operator));
  End;

Function generateDigest( Const _1_t_param: string; _2_e_algorithm: int64; Const _3_t_operator: string): string;
  Begin
    // 4D command 1147 - Generate digest
    // https://developer.4d.com/docs/21/commands/generate-digest
    // TODO: texte traité en représentation UTF-8 ; sortie hexadécimale par défaut, Base64URL si opérateur *.
    failNotSupported( 'q4tools.generateDigest(string)');
  End;

Function generateDigest( Const _1_y_param: TBytes; _2_e_algorithm: int64; Const _3_t_operator: string): string;
  Begin
    // 4D command 1147 - Generate digest
    // https://developer.4d.com/docs/21/commands/generate-digest
    failNotSupported( 'q4tools.generateDigest(TBytes)');
  End;

Function generateUUID: string;
  Begin
    // 4D command 1066 - Generate UUID
    // https://developer.4d.com/docs/21/commands/generate-uuid
    Result := generateUUID( 4);
  End;

Function generateUUID( _1_e_version: int64): string;
  Var
    _g_guid: TGUID;
  Begin
    // 4D command 1066 - Generate UUID
    // https://developer.4d.com/docs/21/commands/generate-uuid
    If ( _1_e_version = 7) Then failNotSupported( 'q4tools.generateUUID(version 7)');

    If ( _1_e_version <> 4) Then Raise Exception.Create( 'q4tools.generateUUID: unsupported UUID version ' + IntToStr( _1_e_version));

    If ( CreateGUID( _g_guid) <> 0) Then Raise Exception.Create( 'q4tools.generateUUID: CreateGUID failed');

    Result := q4GuidToNonCanonicalText( _g_guid);
    If ( Length( Result) <> 32) Then Raise Exception.Create( 'q4tools.generateUUID: invalid GUID conversion');
  End;

Procedure setEnvironmentVariable( Const _1_t_varName: string; Const _2_t_varValue: string);
  Begin
    // 4D command 812 - SET ENVIRONMENT VARIABLE
    // https://developer.4d.com/docs/21/commands/set-environment-variable
    // TODO: stocker dans un contexte thread-local consommé par le prochain launchExternalProcess.
    failNotSupported( 'q4tools.setEnvironmentVariable');
  End;

Procedure launchExternalProcess( Const _1_t_fileName: string; Const _2_t_inputStream: string; out _3_t_outputStream: string; out _4_t_errorStream: string; out _5_e_pid: int64);
  Begin
    // 4D command 811 - LAUNCH EXTERNAL PROCESS
    // https://developer.4d.com/docs/21/commands/launch-external-process
    // TODO: gérer OK, pid, stdin/stdout/stderr, current directory, hide console, blocking/non-blocking.
    failNotSupported( 'q4tools.launchExternalProcess(string)');
  End;

Procedure launchExternalProcess( Const _1_t_fileName: string; Const _2_y_inputStream: TBytes; out _3_y_outputStream: TBytes; out _4_y_errorStream: TBytes; out _5_e_pid: int64);
  Begin
    // 4D command 811 - LAUNCH EXTERNAL PROCESS
    // https://developer.4d.com/docs/21/commands/launch-external-process
    failNotSupported( 'q4tools.launchExternalProcess(TBytes)');
  End;

Procedure openURL( Const _1_t_path: string; Const _2_t_appName: string; Const _3_t_operator: string);
  Var
    _t_path: string;
  Begin
    // 4D command 673 - OPEN URL
    // https://developer.4d.com/docs/21/commands/open-url
    // Ouvre un document, une URL http/mailto/file:// ou un chemin local via le système.
    // L'opérateur * est accepté mais la traduction automatique 4D des caractères spéciaux
    // reste à préciser/tester avant une émulation stricte.
    _t_path := q4PrepareOpenURLPath( _1_t_path, q4IsStarOperator( _3_t_operator));
    q4OpenURLSystem( _t_path, _2_t_appName);
  End;

Procedure startMonitoringActivity( _1_r_duration: double; _2_e_source: int64);
  Begin
    // 4D command 1712 - START MONITORING ACTIVITY
    // https://developer.4d.com/docs/21/commands/start-monitoring-activity
    // TODO: ne pas brancher le monitoring tout de suite ; préparer seulement le socle.
    failNotSupported( 'q4tools.startMonitoringActivity');
  End;

Procedure stopMonitoringActivity;
  Begin
    // 4D command 1721 - STOP MONITORING ACTIVITY
    // https://developer.4d.com/docs/21/commands/stop-monitoring-activity
    failNotSupported( 'q4tools.stopMonitoringActivity');
  End;

Function monitoredActivity: string;
  Begin
    // 4D command 1713 - Monitored activity
    // https://developer.4d.com/docs/21/commands/monitored-activity
    failNotSupported( 'q4tools.monitoredActivity');
  End;

Procedure activitySnapshot( Var _1_at_uuid: Tq4TextArray; Var _2_at_start: Tq4TextArray; Var _3_ae_duration: Tq4Int64Array; Var _4_at_info: Tq4TextArray; Var _5_ao_details: Tq4ObjectArray);
  Begin
    // 4D command 1277 - ACTIVITY SNAPSHOT
    // https://developer.4d.com/docs/21/commands/activity-snapshot
    failNotSupported( 'q4tools.activitySnapshot(arrays)');
  End;

Function activitySnapshot: string;
  Begin
    // 4D command 1277 - ACTIVITY SNAPSHOT
    // https://developer.4d.com/docs/21/commands/activity-snapshot
    // TODO: représenter la syntaxe object array sous forme JSON tant que les objets q4 ne sont pas branchés ici.
    failNotSupported( 'q4tools.activitySnapshot');
  End;

Function generatePasswordHash( Const _1_t_password: string; Const _2_t_optionsJson: string): string;
  Begin
    // 4D command 1533 - Generate password hash
    // https://developer.4d.com/docs/21/commands/generate-password-hash
    // TODO: 4D 21 documente bcrypt ; préférence q4 future à discuter : compatibilité bcrypt ou Argon2id.
    failNotSupported( 'q4tools.generatePasswordHash TODO');
  End;

Function verifyPasswordHash( Const _1_t_password: string; Const _2_t_hash: string): boolean;
  Begin
    // 4D command 1534 - Verify password hash
    // https://developer.4d.com/docs/21/commands/verify-password-hash
    // TODO: cohérent avec generatePasswordHash ; retourner False ou erreur selon type de hash invalide à décider.
    failNotSupported( 'q4tools.verifyPasswordHash TODO');
  End;

Procedure getMacroParameter( _1_e_selector: int64; out _2_t_textParam: string);
  Begin
    // 4D command 997 - GET MACRO PARAMETER
    // https://developer.4d.com/docs/21/commands/get-macro-parameter
    failNotSupported( 'q4tools.getMacroParameter');
  End;

Procedure setMacroParameter( _1_e_selector: int64; Const _2_t_textParam: string);
  Begin
    // 4D command 998 - SET MACRO PARAMETER
    // https://developer.4d.com/docs/21/commands/set-macro-parameter
    failNotSupported( 'q4tools.setMacroParameter');
  End;

Function processQ4Tags( Const _1_t_inputTemplate: string; Const _2_at_params: Array Of string): string;
  Begin
    // 4D command 816 - PROCESS 4D TAGS
    // https://developer.4d.com/docs/21/commands/process-4d-tags
    failNotSupported( 'q4tools.processQ4Tags');
  End;

Function loadQ4ViewDocument( Const _1_y_q4ViewDocument: TBytes): string;
  Begin
    // 4D command 1528 - Load 4D View document
    // https://developer.4d.com/docs/21/commands/load-4d-view-document
    failNotSupported( 'q4tools.loadQ4ViewDocument');
  End;

Procedure mobileAppRefreshSessions;
  Begin
    // 4D command 1596 - MOBILE APP REFRESH SESSIONS
    // https://developer.4d.com/docs/21/commands/mobile-app-refresh-sessions
    failNotSupported( 'q4tools.mobileAppRefreshSessions');
  End;

End.
