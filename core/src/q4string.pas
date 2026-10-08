Unit q4string;

{$mode objfpc}{$H+}

Interface

Uses
  SysUtils, Classes, LazUTF8,
  q4coreLanguage, q4xliff;

{
q4string
version du 2026/05/15-04

Mapping 4D
Command Number 4D,    4D Command,                       q4 API,                           Statut
  ------------------------------------------------------------------------------------------------
234,                 Change string,                    changeString,                     OK,
90,                  Char,                             char,                             OK,
91,                  Character code,                   characterCode,                    OK,
1756,                Compare strings,                  compareStrings,                   Partial,
1011,                CONVERT FROM TEXT,                convertFromText,                  Partial,
1012,                Convert to text,                  convertToText,                    Partial,
232,                 Delete string,                    deleteString,                     OK,
1141,                GET TEXT KEYWORDS,                getTextKeywords,                  Partial,
231,                 Insert string,                    insertString,                     OK,
16,                  Length,                           lengthQ4,                         OK,
991,                 Localized string,                 localizedString,                  Partial,
14,                  Lowercase,                        lowerCase,                        Partial,
1019,                Match regex,                      matchRegex,                       Partial,
11,                  Num,                              num,                              Partial,
15,                  Position,                         position,                         Partial,
233,                 Replace string,                   replaceString,                    Partial,
1554,                Split string,                     splitString,                      Partial,
10,                  String,                           stringOf,                         Partial,
12,                  Substring,                        substring,                        OK,
1853,                Trim,                             trim,                             OK,
1855,                Trim end,                         trimEnd,                          OK,
1854,                Trim start,                       trimStart,                        OK,
13,                  Uppercase,                        upperCase,                        Partial,

Doc: https://developer.4d.com/docs/21/commands/theme/String
}

Const
  // Interprétation minimale d'options (4D est plus riche).
  // compareStrings: 0 = sensible à la casse, 1 = insensible à la casse
  Q4_COMPARE_CASE_INSENSITIVE = 1;

  // position: 0 = sensible à la casse, 1 = insensible à la casse (minimal)
  Q4_POSITION_CASE_INSENSITIVE = 1;

Type
  // "Blob" minimal (Picture/Blob en q4 v1.x → TBytes)
  Tq4Blob = TBytes;

  // Tableau de textes (convention q4 : tt_...)
  Tq4TextArray = Array Of string;

// https://developer.4d.com/docs/21/commands/change-string
Function changeString( Const _1_t_source: string; Const _2_t_newChars: string; Const _3_e_where: int64): string;

// https://developer.4d.com/docs/21/commands/char
Function char( Const _1_e_charCode: int64): string;

// https://developer.4d.com/docs/21/commands/character-code
Function characterCode( Const _1_t_character: string): int64;

// https://developer.4d.com/docs/21/commands/compare-strings
Function compareStrings( Const _1_t_aString: string; Const _2_t_bString: string; Const _3_e_options: int64 = 0): int64;

// https://developer.4d.com/docs/21/commands/convert-from-text
Procedure convertFromText( Const _1_t_4Dtext: string; Const _2_t_charSet: string; out _3_y_convertedBLOB: Tq4Blob);

// https://developer.4d.com/docs/21/commands/convert-to-text
Function convertToText( Const _1_y_blob: Tq4Blob; Const _2_t_charSet: string): string;

// https://developer.4d.com/docs/21/commands/delete-string
Function deleteString( Const _1_t_source: string; Const _2_e_where: int64; Const _3_e_numChars: int64): string;

// https://developer.4d.com/docs/21/commands/get-text-keywords
Procedure getTextKeywords( Const _1_t_text: string; out _2_tt_arrKeywords: Tq4TextArray; Const _3_t_star: string = '');

// https://developer.4d.com/docs/21/commands/insert-string
Function insertString( Const _1_t_source: string; Const _2_t_what: string; Const _3_e_where: int64): string;

// https://developer.4d.com/docs/21/commands/length
Function lengthQ4( Const _1_t_string: string): int64;

// https://developer.4d.com/docs/21/commands/localized-string
Function localizedString( Const _1_t_resName: string): string;

// https://developer.4d.com/docs/21/commands/lowercase
Function lowerCase( Const _1_t_aString: string; Const _2_t_star: string = ''): string;

// https://developer.4d.com/docs/21/commands/match-regex
Function matchRegex( Const _1_t_pattern: string; Const _2_t_aString: string; Const _3_e_start: int64; out _4_e_posFound: int64; out _5_e_lengthFound: int64; Const _6_t_star: string = ''): boolean;
Function matchRegex( Const _1_t_pattern: string; Const _2_t_aString: string): boolean;

// https://developer.4d.com/docs/21/commands/num
Function num( Const _1_t_expression: string; Const _2_t_separator: string = ''): double;
Function num( Const _1_t_expression: string; Const _2_e_base: int64): double;

// https://developer.4d.com/docs/21/commands/position
Function position( Const _1_t_find: string; Const _2_t_aString: string; Const _3_e_start: int64 = 1; Const _4_t_star: string = ''): int64;
Function position( Const _1_t_find: string; Const _2_t_aString: string; Const _3_e_start: int64; Const _4_e_options: int64): int64;
// https://developer.4d.com/docs/21/commands/replace-string
Function replaceString( Const _1_t_source: string; Const _2_t_oldString: string; Const _3_t_newString: string; Const _4_e_howMany: int64 = 0; Const _5_t_star: string = ''): string;

// https://developer.4d.com/docs/21/commands/split-string
Function splitString( Const _1_t_stringToSplit: string; Const _2_t_separator: string; Const _3_e_options: int64 = 0): string;

// https://developer.4d.com/docs/21/commands/string
Function stringOf( Const _1_t_value: string): string;
Function stringOf( Const _1_e_value: int64): string;
Function stringOf( Const _1_r_value: double): string;
Function stringOf( Const _1_b_value: boolean): string;

// https://developer.4d.com/docs/21/commands/substring
Function substring( Const _1_t_source: string; Const _2_e_firstChar: int64; Const _3_e_numChars: int64 = -1): string;

// https://developer.4d.com/docs/21/commands/trim
Function trim( Const _1_t_aString: string): string;

// https://developer.4d.com/docs/21/commands/trim-end
Function trimEnd( Const _1_t_aString: string): string;

// https://developer.4d.com/docs/21/commands/trim-start
Function trimStart( Const _1_t_aString: string): string;

// https://developer.4d.com/docs/21/commands/uppercase
Function upperCase( Const _1_t_aString: string; Const _2_t_star: string = ''): string;

Implementation

Uses
  RegExpr, q4interruptions;

Function InternalClampIndex1Based( Const _1_e_index: int64; Const _2_e_min: int64; Const _3_e_max: int64): int64;
  Begin
    Result := _1_e_index;
    If ( Result < _2_e_min) Then Result := _2_e_min;
    If ( Result > _3_e_max) Then Result := _3_e_max;
  End;

Function InternalChangeString( Const _1_t_source: string; Const _2_t_newChars: string; Const _3_e_where: int64): string;
  Var
    _e_lenSource: int64;
    _t_prefix:    string;
    _t_suffix:    string;
  Begin
    _e_lenSource := LazUTF8.UTF8Length( _1_t_source);
    If ( ( _3_e_where < 1) or ( _3_e_where > _e_lenSource + 1)) Then Exit( _1_t_source);

    _t_prefix := LazUTF8.UTF8Copy( _1_t_source, 1, _3_e_where - 1);
    _t_suffix := LazUTF8.UTF8Copy( _1_t_source, _3_e_where + LazUTF8.UTF8Length( _2_t_newChars), _e_lenSource);
    Result := _t_prefix + _2_t_newChars + _t_suffix;
  End;

Function changeString( Const _1_t_source: string; Const _2_t_newChars: string; Const _3_e_where: int64): string;
  Begin
    Result := InternalChangeString( _1_t_source, _2_t_newChars, _3_e_where);
  End;

Function InternalChar( Const _1_e_charCode: int64): string;
  Var
    _e_codePoint: int64;
  Begin
    _e_codePoint := _1_e_charCode;

    If ( ( _e_codePoint < 0) or ( _e_codePoint > $10FFFF) or ( ( _e_codePoint >= $D800) and ( _e_codePoint <= $DFFF))) Then q4interruptions.assertRaise(
        'q4string.char: invalid Unicode code point',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );

    If ( _e_codePoint <= $7F) Then Result := System.Chr( _e_codePoint)
    Else If ( _e_codePoint <= $7FF) Then Result := System.Chr( $C0 or ( _e_codePoint shr 6)) + System.Chr( $80 or ( _e_codePoint and $3F))
    Else If ( _e_codePoint <= $FFFF) Then Result := System.Chr( $E0 or ( _e_codePoint shr 12)) + System.Chr( $80 or ( ( _e_codePoint shr 6) and $3F)) + System.Chr( $80 or ( _e_codePoint and $3F))
    Else
      Result := System.Chr( $F0 or ( _e_codePoint shr 18)) + System.Chr( $80 or ( ( _e_codePoint shr 12) and $3F)) + System.Chr( $80 or ( ( _e_codePoint shr 6) and $3F)) +
        System.Chr( $80 or ( _e_codePoint and $3F));
  End;

Function char( Const _1_e_charCode: int64): string;
  Begin
    Result := InternalChar( _1_e_charCode);
  End;

Function InternalCharacterCode( Const _1_t_character: string): int64;
  Var
    _e_cp:   cardinal;
    _e_leng: longint;
  Begin
    If ( LazUTF8.UTF8Length( _1_t_character) < 1) Then Exit( 0);

    _e_cp := LazUTF8.UTF8CodepointToUnicode( PChar( _1_t_character), _e_leng);
    Result := int64( _e_cp);
  End;

Function characterCode( Const _1_t_character: string): int64;
  Begin
    Result := InternalCharacterCode( _1_t_character);
  End;

Function InternalCompareStrings( Const _1_t_aString: string; Const _2_t_bString: string; Const _3_e_options: int64): int64;
  Begin
    If ( ( _3_e_options and Q4_COMPARE_CASE_INSENSITIVE) <> 0) Then Result := LazUTF8.UTF8CompareText( _1_t_aString, _2_t_bString)
    Else
      Result := LazUTF8.UTF8CompareStr( _1_t_aString, _2_t_bString);
  End;

Function compareStrings( Const _1_t_aString: string; Const _2_t_bString: string; Const _3_e_options: int64): int64;
  Begin
    Result := InternalCompareStrings( _1_t_aString, _2_t_bString, _3_e_options);
  End;

Procedure InternalConvertFromText( Const _1_t_4Dtext: string; Const _2_t_charSet: string; out _3_y_convertedBLOB: Tq4Blob);
  Var
    _t_cs: string;
  Begin
    // Analyse:
    // q4 v1.x stocke les textes en UTF-8. Les autres charsets 4D ne sont pas
    // encore convertis afin d'éviter un comportement silencieusement faux.
    _t_cs := SysUtils.LowerCase( SysUtils.Trim( _2_t_charSet));

    If ( not ( ( _t_cs = '') or ( _t_cs = 'utf-8') or ( _t_cs = 'utf8'))) Then q4interruptions.assertRaise(
        'q4string.convertFromText: charset not supported yet (' + _t_cs + ')',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );

    _3_y_convertedBLOB := BytesOf( _1_t_4Dtext);
  End;

Procedure convertFromText( Const _1_t_4Dtext: string; Const _2_t_charSet: string; out _3_y_convertedBLOB: Tq4Blob);
  Begin
    InternalConvertFromText( _1_t_4Dtext, _2_t_charSet, _3_y_convertedBLOB);
  End;

Function InternalConvertToText( Const _1_y_blob: Tq4Blob; Const _2_t_charSet: string): string;
  Var
    _t_cs: string;
  Begin
    // Analyse:
    // q4 v1.x ne gère actuellement que les blobs texte UTF-8.
    // Les autres charsets 4D déclenchent une interruption q4 afin d'éviter
    // un comportement silencieusement faux.
    _t_cs := SysUtils.LowerCase( SysUtils.Trim( _2_t_charSet));

    If ( not ( ( _t_cs = '') or ( _t_cs = 'utf-8') or ( _t_cs = 'utf8'))) Then q4interruptions.assertRaise(
        'q4string.convertToText: charset not supported yet (' + _t_cs + ')',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );

    If ( System.Length( _1_y_blob) = 0) Then Exit( '');

    SetString( Result, pansichar( @_1_y_blob[0]), System.Length( _1_y_blob));
  End;

Function convertToText( Const _1_y_blob: Tq4Blob; Const _2_t_charSet: string): string;
  Begin
    Result := InternalConvertToText( _1_y_blob, _2_t_charSet);
  End;

Function InternalDeleteString( Const _1_t_source: string; Const _2_e_where: int64; Const _3_e_numChars: int64): string;
  Var
    _t_result: string;
    _e_lenSource: int64;
    _e_w: int64;
    _e_n: int64;
  Begin
    _t_result := _1_t_source;
    _e_lenSource := LazUTF8.UTF8Length( _t_result);

    If ( ( _e_lenSource = 0) or ( _3_e_numChars <= 0)) Then Exit( _t_result);

    _e_w := _2_e_where;
    If ( ( _e_w < 1) or ( _e_w > _e_lenSource)) Then Exit( _t_result);

    _e_n := _3_e_numChars;
    If ( _e_w + _e_n - 1 > _e_lenSource) Then _e_n := _e_lenSource - _e_w + 1;

    LazUTF8.UTF8Delete( _t_result, _e_w, _e_n);
    Result := _t_result;
  End;

Function deleteString( Const _1_t_source: string; Const _2_e_where: int64; Const _3_e_numChars: int64): string;
  Begin
    Result := InternalDeleteString( _1_t_source, _2_e_where, _3_e_numChars);
  End;

Procedure InternalGetTextKeywords( Const _1_t_text: string; out _2_tt_arrKeywords: Tq4TextArray; Const _3_t_star: string);
  Var
    _o_re:    TRegExpr;
    _t_work:  string;
    _e_count: int64;
    _e_i:     int64;
    _t_kw:    string;
  Begin
    // Minimal : extrait des "mots" (lettres+chiffres+_) en UTF-8.
    // TODO: règles 4D exactes + gestion du *.
    System.SetLength( _2_tt_arrKeywords, 0);

    _o_re := TRegExpr.Create;
    Try
      _o_re.Expression := '([[:word:]]+)';
      _t_work := _1_t_text;

      _e_count := 0;
      If ( _o_re.Exec( _t_work)) Then Repeat
          _t_kw := _o_re.Match[1];
          System.Inc( _e_count);
          System.SetLength( _2_tt_arrKeywords, _e_count);
          _2_tt_arrKeywords[_e_count - 1] := _t_kw;
        Until ( not _o_re.ExecNext);

      // Déduplication simple (O(n²), OK minimal)
      For _e_i := System.High( _2_tt_arrKeywords) Downto 0 Do // rien: laissé minimal
      ;
    Finally
      _o_re.Free;
    End;
  End;

Procedure getTextKeywords( Const _1_t_text: string; out _2_tt_arrKeywords: Tq4TextArray; Const _3_t_star: string);
  Begin
    InternalGetTextKeywords( _1_t_text, _2_tt_arrKeywords, _3_t_star);
  End;

Function InternalInsertString( Const _1_t_source: string; Const _2_t_what: string; Const _3_e_where: int64): string;
  Var
    _e_lenSource: int64;
    _e_w:      int64;
    _t_prefix: string;
    _t_suffix: string;
  Begin
    _e_lenSource := LazUTF8.UTF8Length( _1_t_source);
    _e_w := _3_e_where;

    If ( _e_w < 1) Then _e_w := 1;
    If ( _e_w > _e_lenSource + 1) Then _e_w := _e_lenSource + 1;

    _t_prefix := LazUTF8.UTF8Copy( _1_t_source, 1, _e_w - 1);
    _t_suffix := LazUTF8.UTF8Copy( _1_t_source, _e_w, _e_lenSource);
    Result := _t_prefix + _2_t_what + _t_suffix;
  End;

Function insertString( Const _1_t_source: string; Const _2_t_what: string; Const _3_e_where: int64): string;
  Begin
    Result := InternalInsertString( _1_t_source, _2_t_what, _3_e_where);
  End;

Function InternalLength( Const _1_t_string: string): int64;
  Begin
    Result := LazUTF8.UTF8Length( _1_t_string);
  End;

Function lengthQ4( Const _1_t_string: string): int64;
  Begin
    Result := InternalLength( _1_t_string);
  End;

Function InternalLocalizedString( Const _1_t_resName: string): string;
  Begin
    // Analyse:
    // 4D résout resName via l’architecture XLIFF de la langue courante.
    // q4 ne supporte pas STR# et ne convertit pas vers PO/MO.
    // La résolution réelle est déléguée à q4xliff.

    Result := q4xliff.localizedString( _1_t_resName);

    If ( Result = '') Then q4coreLanguage.OK := 0
    Else
      q4coreLanguage.OK := 1;
  End;

//https://developer.4d.com/docs/21/commands/localized-string
Function localizedString( Const _1_t_resName: string): string;
  Begin
    Result := InternalLocalizedString( _1_t_resName);
  End;

Function InternalLowerCase( Const _1_t_aString: string; Const _2_t_star: string): string;
  Begin
    // TODO: gérer le * (locale 4D). Minimal UTF8LowerCase.
    Result := LazUTF8.UTF8LowerCase( _1_t_aString);
  End;

Function lowerCase( Const _1_t_aString: string; Const _2_t_star: string): string;
  Begin
    Result := InternalLowerCase( _1_t_aString, _2_t_star);
  End;

Function InternalMatchRegex( Const _1_t_pattern: string; Const _2_t_aString: string; Const _3_e_start: int64; out _4_e_posFound: int64; out _5_e_lengthFound: int64; Const _6_t_star: string): boolean;
  Var
    _o_re:     TRegExpr;
    _e_start0: int64;
    _t_sub:    string;
    _e_posInSub: int64;
  Begin
    // Minimal : RegExpr FPC (pas strictement identique à 4D).
    _4_e_posFound := 0;
    _5_e_lengthFound := 0;

    _e_start0 := _3_e_start;
    If ( _e_start0 < 1) Then _e_start0 := 1;

    _t_sub := LazUTF8.UTF8Copy( _2_t_aString, _e_start0, LazUTF8.UTF8Length( _2_t_aString));

    _o_re := TRegExpr.Create;
    Try
      _o_re.Expression := _1_t_pattern;
      Result := _o_re.Exec( _t_sub);
      If ( Result) Then Begin
        // Positions RegExpr : 1-based en octets/AnsiString, donc approximation.
        // On reste "cohérent minimal" : renvoyer position 1-based à partir de _3_e_start.
        _e_posInSub := _o_re.MatchPos[0];
        If ( _e_posInSub < 1) Then _e_posInSub := 1;

        _4_e_posFound := _e_start0 + ( _e_posInSub - 1);
        _5_e_lengthFound := _o_re.MatchLen[0];
      End;
    Finally
      _o_re.Free;
    End;
  End;

Function matchRegex( Const _1_t_pattern: string; Const _2_t_aString: string; Const _3_e_start: int64; out _4_e_posFound: int64; out _5_e_lengthFound: int64; Const _6_t_star: string): boolean;
  Begin
    Result := InternalMatchRegex( _1_t_pattern, _2_t_aString, _3_e_start, _4_e_posFound, _5_e_lengthFound, _6_t_star);
  End;

Function matchRegex( Const _1_t_pattern: string; Const _2_t_aString: string): boolean;
  Var
    _e_posFound:    int64;
    _e_lengthFound: int64;
  Begin
    Result := InternalMatchRegex( _1_t_pattern, _2_t_aString, 1, _e_posFound, _e_lengthFound, '');
  End;

Function InternalNum( Const _1_t_expression: string; Const _2_t_separator: string): double;
  Var
    _y_fs:   TFormatSettings;
    _t_work: string;
  Begin
    _y_fs := SysUtils.DefaultFormatSettings;
    _t_work := SysUtils.Trim( _1_t_expression);

    If ( _2_t_separator <> '') Then _y_fs.DecimalSeparator := _2_t_separator[1];

    If ( not SysUtils.TryStrToFloat( _t_work, Result, _y_fs)) Then Result := 0.0;
  End;

Function num( Const _1_t_expression: string; Const _2_t_separator: string): double;
  Begin
    Result := InternalNum( _1_t_expression, _2_t_separator);
  End;

Function InternalNumBase( Const _1_t_expression: string; Const _2_e_base: int64): double;
  Var
    _e_val: int64;
  Begin
    // Minimal : parse entier base N
    _e_val := SysUtils.StrToInt64Def( '$0', 0);
    Try
      _e_val := SysUtils.StrToInt64( '$' + _1_t_expression); // fallback hex-like (minimal)
    Except
      _e_val := 0;
    End;

    // TODO: vraie base _2_e_base (2..36)
    Result := double( _e_val);
  End;

Function num( Const _1_t_expression: string; Const _2_e_base: int64): double;
  Begin
    Result := InternalNumBase( _1_t_expression, _2_e_base);
  End;

Function InternalPosition( Const _1_t_find: string; Const _2_t_aString: string; Const _3_e_start: int64; Const _4_e_options: int64): int64;
  Var
    _t_hay:    string;
    _t_need:   string;
    _e_posSub: int64;
    _e_start0: int64;
    _t_sub:    string;
  Begin
    //e_lengthFound := 0;
    If ( _1_t_find = '') Then Exit( 0);

    _e_start0 := _3_e_start;
    If ( _e_start0 < 1) Then _e_start0 := 1;

    _t_sub := LazUTF8.UTF8Copy( _2_t_aString, _e_start0, LazUTF8.UTF8Length( _2_t_aString));

    If ( ( _4_e_options and Q4_POSITION_CASE_INSENSITIVE) <> 0) Then Begin
      _t_hay := LazUTF8.UTF8LowerCase( _t_sub);
      _t_need := LazUTF8.UTF8LowerCase( _1_t_find);
    End Else Begin
      _t_hay := _t_sub;
      _t_need := _1_t_find;
    End;

    _e_posSub := LazUTF8.UTF8Pos( _t_need, _t_hay); // 1-based, 0 si absent
    If ( _e_posSub = 0) Then Exit( 0);

    //e_lengthFound := LazUTF8.UTF8Length(_1_t_find);
    Result := _e_start0 + ( _e_posSub - 1);
  End;

Function position( Const _1_t_find: string; Const _2_t_aString: string; Const _3_e_start: int64; Const _4_t_star: string): int64;
  Begin
    // TODO: interpréter * (options 4D). Minimal : case-sensitive.
    Result := InternalPosition( _1_t_find, _2_t_aString, _3_e_start, 0);
  End;

Function position( Const _1_t_find: string; Const _2_t_aString: string; Const _3_e_start: int64; Const _4_e_options: int64): int64;
  Begin
    Result := InternalPosition( _1_t_find, _2_t_aString, _3_e_start, _4_e_options);
  End;

Function InternalReplaceString( Const _1_t_source: string; Const _2_t_oldString: string; Const _3_t_newString: string; Const _4_e_howMany: int64; Const _5_t_star: string): string;
  Var
    _t_work:   string;
    _e_count:  int64;
    _e_pos:    int64;
    _e_lenOld: int64;
    _t_left:   string;
    _t_right:  string;
  Begin
    // Minimal : remplacements successifs en UTF-8 (case-sensitive).
    // _4_e_howMany : 0 = tous (convention minimale).
    If ( _2_t_oldString = '') Then Exit( _1_t_source);

    _t_work := _1_t_source;
    _e_count := 0;
    _e_lenOld := LazUTF8.UTF8Length( _2_t_oldString);

    While ( True) Do Begin
      _e_pos := LazUTF8.UTF8Pos( _2_t_oldString, _t_work);
      If ( _e_pos = 0) Then Break;

      _t_left := LazUTF8.UTF8Copy( _t_work, 1, _e_pos - 1);
      _t_right := LazUTF8.UTF8Copy( _t_work, _e_pos + _e_lenOld, LazUTF8.UTF8Length( _t_work));

      _t_work := _t_left + _3_t_newString + _t_right;

      System.Inc( _e_count);
      If ( ( _4_e_howMany > 0) and ( _e_count >= _4_e_howMany)) Then Break;
    End;

    Result := _t_work;
  End;

Function replaceString( Const _1_t_source: string; Const _2_t_oldString: string; Const _3_t_newString: string; Const _4_e_howMany: int64; Const _5_t_star: string): string;
  Begin
    Result := InternalReplaceString( _1_t_source, _2_t_oldString, _3_t_newString, _4_e_howMany, _5_t_star);
  End;

Function InternalJSONEscape( Const _1_t_s: string): string;
  Var
    _e_i: int64;
    _t_c: string;
  Begin
    Result := '';
    For _e_i := 1 To System.Length( _1_t_s) Do Begin
      _t_c := _1_t_s[_e_i];
      Case _t_c Of
        '"': Result := Result + '\"';
        '\': Result := Result + '\\';
        #8: Result := Result + '\b';
        #9: Result := Result + '\t';
        #10: Result := Result + '\n';
        #13: Result := Result + '\r';
        Else Result := Result + _t_c;
      End;
    End;
  End;

Function InternalSplitString( Const _1_t_stringToSplit: string; Const _2_t_separator: string; Const _3_e_options: int64): string;
  Var
    _tt_parts: Array Of string;
    _e_count:  int64;
    _t_work:   string;
    _e_posSep: int64;
    _e_lenSep: int64;
    _t_part:   string;
    _e_i:      int64;
  Begin
    // Retour q4 v1.x : "Collection" → string JSON array (spec)
    // Minimal : split strict, pas d’options 4D avancées.
    _e_lenSep := LazUTF8.UTF8Length( _2_t_separator);
    If ( _e_lenSep = 0) Then Exit( '[]');

    System.SetLength( _tt_parts, 0);
    _e_count := 0;
    _t_work := _1_t_stringToSplit;

    While ( True) Do Begin
      _e_posSep := LazUTF8.UTF8Pos( _2_t_separator, _t_work);
      If ( _e_posSep = 0) Then Begin
        _t_part := _t_work;
        System.Inc( _e_count);
        System.SetLength( _tt_parts, _e_count);
        _tt_parts[_e_count - 1] := _t_part;
        Break;
      End;

      _t_part := LazUTF8.UTF8Copy( _t_work, 1, _e_posSep - 1);
      System.Inc( _e_count);
      System.SetLength( _tt_parts, _e_count);
      _tt_parts[_e_count - 1] := _t_part;

      _t_work := LazUTF8.UTF8Copy( _t_work, _e_posSep + _e_lenSep, LazUTF8.UTF8Length( _t_work));
    End;

    Result := '[';
    For _e_i := 0 To System.High( _tt_parts) Do Begin
      If ( _e_i > 0) Then Result := Result + ',';
      Result := Result + '"' + InternalJSONEscape( _tt_parts[_e_i]) + '"';
    End;
    Result := Result + ']';
  End;

Function splitString( Const _1_t_stringToSplit: string; Const _2_t_separator: string; Const _3_e_options: int64): string;
  Begin
    Result := InternalSplitString( _1_t_stringToSplit, _2_t_separator, _3_e_options);
  End;

Function InternalStringOfText( Const _1_t_value: string): string;
  Begin
    Result := _1_t_value;
  End;

Function stringOf( Const _1_t_value: string): string;
  Begin
    Result := InternalStringOfText( _1_t_value);
  End;

Function InternalStringOfInt( Const _1_e_value: int64): string;
  Begin
    Result := SysUtils.IntToStr( _1_e_value);
  End;

Function stringOf( Const _1_e_value: int64): string;
  Begin
    Result := InternalStringOfInt( _1_e_value);
  End;

Function InternalStringOfReal( Const _1_r_value: double): string;
  Begin
    Result := SysUtils.FloatToStr( _1_r_value, SysUtils.DefaultFormatSettings);
  End;

Function stringOf( Const _1_r_value: double): string;
  Begin
    Result := InternalStringOfReal( _1_r_value);
  End;

Function InternalStringOfBool( Const _1_b_value: boolean): string;
  Begin
    If ( _1_b_value) Then Result := 'True'
    Else
      Result := 'False';
  End;

Function stringOf( Const _1_b_value: boolean): string;
  Begin
    Result := InternalStringOfBool( _1_b_value);
  End;

Function InternalSubstring( Const _1_t_source: string; Const _2_e_firstChar: int64; Const _3_e_numChars: int64): string;
  Var
    _e_lenSource: int64;
    _e_first: int64;
    _e_n: int64;
  Begin
    _e_lenSource := LazUTF8.UTF8Length( _1_t_source);
    If ( _e_lenSource = 0) Then Exit( '');

    _e_first := _2_e_firstChar;
    If ( _e_first < 1) Then _e_first := 1;
    If ( _e_first > _e_lenSource) Then Exit( '');

    If ( _3_e_numChars < 0) Then _e_n := _e_lenSource - _e_first + 1
    Else
      _e_n := _3_e_numChars;

    Result := LazUTF8.UTF8Copy( _1_t_source, _e_first, _e_n);
  End;

Function substring( Const _1_t_source: string; Const _2_e_firstChar: int64; Const _3_e_numChars: int64): string;
  Begin
    Result := InternalSubstring( _1_t_source, _2_e_firstChar, _3_e_numChars);
  End;

Function InternalTrim( Const _1_t_aString: string): string;
  Begin
    Result := LazUTF8.UTF8Trim( _1_t_aString);
  End;

Function trim( Const _1_t_aString: string): string;
  Begin
    Result := InternalTrim( _1_t_aString);
  End;

Function InternalTrimEnd( Const _1_t_aString: string): string;
  Begin
    Result := SysUtils.TrimRight( _1_t_aString);
  End;

Function trimEnd( Const _1_t_aString: string): string;
  Begin
    Result := InternalTrimEnd( _1_t_aString);
  End;

Function InternalTrimStart( Const _1_t_aString: string): string;
  Begin
    Result := SysUtils.TrimLeft( _1_t_aString);
  End;

Function trimStart( Const _1_t_aString: string): string;
  Begin
    Result := InternalTrimStart( _1_t_aString);
  End;

Function InternalUpperCase( Const _1_t_aString: string; Const _2_t_star: string): string;
  Begin
    // TODO: gérer le * (locale 4D). Minimal UTF8UpperCase.
    Result := LazUTF8.UTF8UpperCase( _1_t_aString);
  End;

Function upperCase( Const _1_t_aString: string; Const _2_t_star: string): string;
  Begin
    Result := InternalUpperCase( _1_t_aString, _2_t_star);
  End;

End.
