Unit q4coreLanguage;

{$mode ObjFPC}{$H+}

{
  q4coreLanguage
  version du 2026/05/08-01
  
  Types transverses partagés par les unités q4.

  Principes retenus à ce stade :
  - Date et Time restent portés en string avec formats canoniques q4.
  - Object et Collection JSON sont portés en texte sérialisé afin de rester
    simples à transporter entre unités et cohérents avec l'approche q4 v1.x.
  - Tq4ObjectSimple reste disponible comme utilitaire provisoire pour certains
    besoins simples, mais il n'est pas le type canonique du thème JSON.
    
  blob : à convertir en TBytes;
  boolean : tel quel
  Collection : TODO. Utiliser un TJSONArray ? En la dérivant pour gérer les méthodes 4D propres aux collections ?
  TODO: Autres objects : Variant ne prend pas nativement en compte d'autres OBJECTS ou COLLECTION
  TODO: Picture : probablement à coder dans une classe pour gérer les images SVG (qui ne sont pas prises en compte par TBitmap)

  Variant : non utilisé (mais probablement tel quel si besoin)
    
  TODO: Null (ne pas confondre avec Nil : Null correspond à une propriété de OBJECT non définie)
  undefined : ? (on ne l'utilise pas)
  integer : int64
  real : à convertir en double

  la comparaison de chaine avec le joker@ est faite ainsi : var = jo('a@bcde@')
  le test de différence est fait en niant le test d'égalité, donc inutile de le coder
  jo() intègre une comparaison case-insensitive et, désormais, diacritic-insensitive.
  https://www.freepascal.org/docs-html/ref/refse106.html?utm_source=chatgpt.com
  operator <>(const A: string; const B: TPatternString): boolean;

  Règle q4 retenue :
  - les comparaisons textuelles "q4" passent par une normalisation commune
    (lowercase Unicode + suppression simple des diacritiques latin/western)
  - cette règle sert notamment à jo(), aux tris texte, et à d'autres besoins
    de comparaison textuelle cohérente avec 4D.
}


Interface

Uses
  Classes,
  SysUtils,
  Dialogs,
  fgl,
  Variants,
  Character,
  fpjson,
  Graphics;

Type
  { Scalaires q4 portés explicitement }
  // Blob -> TBytes
  // Boolean -> boolean
  // Collection traité plus bas
  Tq4Date = Type string;
  // Integer -> int64
  // Longint -> int64
  // Object traité plus bas
  Tq4Picture = Type Tbytes;
  // Pointer -> Pointer
  // Real -> double
  // Text -> string
  Tq4Time = Type string;

  { Types logiques fondamentaux du runtime q4.

    Ces enums restent volontairement dans q4coreLanguage, unité socle, car ils
    sont utilisés par plusieurs thèmes : Language, références/pointeurs, objets,
    collections, Type / Value type, Null / Undefined, etc.

    q4ref transporte ces informations dans TQ4Ref, mais ne doit pas en être
    l'unité propriétaire afin d'éviter les dépendances circulaires. }
  TQ4TargetKind = (
    q4tkUnknown,
    q4tkValue,
    q4tkArray,
    q4tkArrayElement,
    q4tkField,
    q4tkCustom
    );

  TQ4ValueKind = (
    q4vkUnknown,

    q4vkInteger,
    q4vkInt64,
    q4vkReal,
    q4vkBoolean,

    q4vkText,
    q4vkDate,
    q4vkTime,
    q4vkObject,
    q4vkCollection,

    q4vkBlob,
    q4vkPicture,
    q4vkPointer,
    q4vkVariant,

    q4vkNativeObject,
    q4vkCustom
    );

  //Pour surcharge opérateur simulation comparaison avec joker
  TPatternString = Record
    Value: unicodestring; // stocké normalisé pour comparaison q4
  End;

  { JSON q4 canonique pour v1.x : texte JSON sérialisé }
  //Tq4JSONObject = type string; redéfini plus bas
  //Tq4JSONCollection = type string;
  //Tq4JSONSchema = type Tq4JSONObject;

  { Utilitaire provisoire pour objets simples clé -> valeur.
    Ne pas utiliser comme type canonique du thème q4JSON. }
  // Rappel: Tq4Object défini dans l'unité q4objectsLanguage
  Tq4ObjectSimple = Specialize TFPGMap<string, variant>;
  Tq4JSONObject = Tq4ObjectSimple; // Provisoire
  Tq4JSONCollection = TJSONArray; // Provisoire
  Tq4JSONSchema = Tq4ObjectSimple; // Provisoire

  { Tableaux transverses }
  Tq4BlobArray = Array Of TBytes;
  Tq4BooleanArray = Array Of boolean;
  Tq4DateArray = Array Of Tq4Date;
  Tq4Int64Array = Array Of int64;
  Tq4ObjectArray = Array Of Tq4JSONObject;
  Tq4PictureArray = Array Of Tq4Picture;
  Tq4PointerArray = Array Of pointer;
  Tq4RealArray = Array Of double;
  Tq4TextArray = Array Of string;
  Tq4TimeArray = Array Of Tq4Time;
  Tq4CollectionArray = Tq4JSONCollection;
  Tq4VariantArray = Array Of variant; // pour q4arrayClaude

  { pointeurs }
  {
  ne passait pas au JEDI
  PBytes = type ^TBytes;
  PBoolean = type ^boolean;
  PString = type ^string;
  PInteger = type ^int64;
  Pq4Picture = type ^Tq4Picture;
  PPointer = type ^Pointer;
  PDouble = type ^double;
  Pq4ObjectSimple = type ^Tq4ObjectSimple;
  Pq4BlobArray = type ^Tq4BlobArray;
  Pq4BooleanArray = type ^Tq4BooleanArray;
  Pq4Int64Array = type ^Tq4Int64Array;
  Pq4PictureArray = type ^Tq4PictureArray;
  Pq4PointerArray = type ^Tq4PointerArray;
  Pq4RealArray = type ^Tq4RealArray;
  Pq4TextArray = type ^Tq4TextArray;
}
  PBytes = ^TBytes;
  PBoolean = ^boolean;
  PString = ^string;
  PInteger = ^int64;
  Pq4Picture = ^Tq4Picture;
  PPointer = ^Pointer;
  PDouble = ^double;
  Pq4ObjectSimple = ^Tq4ObjectSimple;
  Pq4BlobArray = ^Tq4BlobArray;
  Pq4BooleanArray = ^Tq4BooleanArray;
  Pq4Int64Array = ^Tq4Int64Array;
  Pq4PictureArray = ^Tq4PictureArray;
  Pq4PointerArray = ^Tq4PointerArray;
  Pq4RealArray = ^Tq4RealArray;
  Pq4TextArray = ^Tq4TextArray;


  { TODO futurs possibles
    - Null / undefined q4 si l'on doit distinguer explicitement
      propriété absente, propriété Null et valeur vide.
    - Picture q4 si un vrai type transverse devient nécessaire.
    - Objet / collection enrichis si les alias string deviennent insuffisants. }

Const
  Q4ErrorRecordDeleted = -10503;

Threadvar
  { Variables runtime portées par thread }
  OK:    int64;
  Error: int64;
  Document: string;

  { Gestion d'erreur }
  ErrorMethod:  string;
  ErrorLine:    int64;
  ErrorFormula: string;

Function BuildGlobPatternQ4( Const _1_t_s: string): unicodestring;

Function NormalizeCompareUTF8( Const _1_t_s: string): unicodestring;
Function CompareTextQ4( Const _1_t_a, _2_t_b: string): int64;
Function SameTextQ4( Const _1_t_a, _2_t_b: string): boolean;

Function jo( Const _1_t_s: string): TPatternString;

Operator =( Const A: string; Const B: TPatternString): boolean;
Operator <( Const A: string; Const B: TPatternString): boolean;
Operator >( Const A: string; Const B: TPatternString): boolean;
Operator <=( Const A: string; Const B: TPatternString): boolean;
Operator >=( Const A: string; Const B: TPatternString): boolean;
Operator *( Const A: string; Const B: int64): string; // "A" * 2 -> "AA"
Operator *( Const A: int64; Const B: string): string; // 2 * "A" -> "AA"

Function BytesToVariant( Const _1_y_bytes: TBytes): variant;
Function VariantToBytes( Const _1_v_value: variant): TBytes;
Function VariantToRealInvariant( Const _1_y_value: variant): double;
Function VariantArraySameValue( Const _1_v_left, _2_v_right: variant): boolean;
Function sameValue( Const _1_v_left, _2_v_right: variant): boolean;

Implementation

Function NormalizeUTF8( Const _1_t_s: string): unicodestring;
  Begin
    // UTF-8 -> UnicodeString UTF-16, puis minuscule Unicode
    Result := TCharacter.ToLower( UTF8ToString( _1_t_s));
  End;

Function FoldDiacriticsU( Const _1_t_s: unicodestring): unicodestring;
  Var
    _e_i: SizeInt;
    ch:   widechar;
  Begin
    Result := '';

    For _e_i := 1 To Length( _1_t_s) Do Begin
      ch := _1_t_s[_e_i];
      Case Ord( ch) Of
        $00E0, $00E1, $00E2, $00E3, $00E4, $00E5, $0101, $0103, $0105: // -> a : à á â ã ä å ā ă ą
          Result := Result + 'a';
        $00E6: Result := Result + 'ae';
        $00E7, $0107, $0109, $010B, $010D: // -> c : ç ć ĉ ċ č
          Result := Result + 'c';
        $010F, $0111: // -> d : ď đ
          Result := Result + 'd';
        $00E8, $00E9, $00EA, $00EB, $0113, $0115, $0117, $0119, $011B: // -> e : è é ê ë ē ĕ ė ę ě
          Result := Result + 'e';
        $0192: // ƒ
          Result := Result + 'f';
        $011D, $011F, $0121, $0123: // -> g : ĝ ğ ġ ģ
          Result := Result + 'g';
        $0125, $0127: // -> h : ĥ ħ
          Result := Result + 'h';
        $00EC, $00ED, $00EE, $00EF, $0129, $012B, $012D, $012F, $0131: // -> i : ì í î ï ĩ ī ĭ į ı
          Result := Result + 'i';
        $0135: // ĵ
          Result := Result + 'j';
        $0137: // ķ
          Result := Result + 'k';
        $013A, $013C, $013E, $0140, $0142: // -> l : ĺ ļ ľ ŀ ł
          Result := Result + 'l';
        $00F1, $0144, $0146, $0148, $0149: // -> n : ñ ń ņ ň ŉ
          Result := Result + 'n';
        $00F2, $00F3, $00F4, $00F5, $00F6, $00F8, $014D, $014F, $0151: // -> o : ò ó ô õ ö ø ō ŏ ő
          Result := Result + 'o';
        $0153: // œ
          Result := Result + 'oe';
        $0155, $0157, $0159: // -> r : ŕ ŗ ř
          Result := Result + 'r';
        $015B, $015D, $015F, $0161: // -> s : ś ŝ ş š
          Result := Result + 's';
        $00DF: // ß
          Result := Result + 'ss';
        $0163, $0165, $0167: // -> t : ţ ť ŧ
          Result := Result + 't';
        $00F9, $00FA, $00FB, $00FC, $0169, $016B, $016D, $016F, $0171, $0173: // -> u : ù ú û ü ũ ū ŭ ů ű ų
          Result := Result + 'u';
        $0175: // ŵ
          Result := Result + 'w';
        $00FD, $00FF, $0177: // -> y : ý ÿ ŷ
          Result := Result + 'y';
        $017A, $017C, $017E: // -> z : ź ż ž
          Result := Result + 'z';
        Else Result := Result + ch;
      End;
    End;
  End;

Function DumpUnicodeCodes( Const _1_t_s: unicodestring): string;
  Var
    i: int64;
  Begin
    Result := '';
    For i := 1 To Length( _1_t_s) Do Begin
      If ( Result <> '') Then Result := Result + ' ';
      Result := Result + IntToHex( Ord( _1_t_s[i]), 4);
    End;
  End;

Function ExpandBaseCharToGlobClass( Const _1_t_ch: widechar): unicodestring;
  Begin
    //Il faudrait peut être si limiter à la langue en cours d'utilisation
    //Cela réduirait la longueur des paterns

    Case _1_t_ch Of
      //'a': Result := '[aàáâãäåāăąAÀÁÂÃÄÅĀĂĄ]';
      'a': Result := '[a' + #$00E0 + #$00E1 + #$00E2 + #$00E3 + #$00E4 + #$00E5 + #$0101 + #$0103 + #$0105 + 'A' + #$00C0 + #$00C1 + #$00C2 + #$00C3 +
          #$00C4 + #$00C5 + #$0100 + #$0102 + #$0104 + ']';

      'b': Result := '[bB]';

      //'c': Result := '[cçćĉċčCÇĆĈĊČ]';
      'c': Result := '[c' + #$00E7 + #$0107 + #$0109 + #$010B + #$010D + 'C' + #$00C7 + #$0106 + #$0108 + #$010A + #$010C + ']';

      //'d': Result := '[dďđDĎĐ]';
      'd': Result := '[d' + #$010F + #$0111 + 'D' + #$010E + #$0110 + ']';

      //'e': Result := '[eèéêëēĕėęěEÈÉÊËĒĔĖĘĚ]';
      'e': Result := '[e' + #$00E8 + #$00E9 + #$00EA + #$00EB + #$0113 + #$0115 + #$0117 + #$0119 + #$011B + 'E' + #$00C8 + #$00C9 + #$00CA + #$00CB +
          #$0112 + #$0114 + #$0116 + #$0118 + #$011A + ']';

      //'g': Result := '[gĝğġģGĜĞĠĢ]';
      'g': Result := '[g' + #$011D + #$011F + #$0121 + #$0123 + 'G' + #$011C + #$011E + #$0120 + #$0122 + ']';

      //'h': Result := '[hĥħHĤĦ]';
      'h': Result := '[h' + #$0125 + #$0127 + 'H' + #$0124 + #$0126 + ']';

      //'i': Result := '[iìíîïĩīĭįıIÌÍÎÏĨĪĬĮİ]';
      'i': Result := '[i' + #$00EC + #$00ED + #$00EE + #$00EF + #$0129 + #$012B + #$012D + #$012F + #$0131 + 'I' + #$00CC + #$00CD + #$00CE + #$00CF +
          #$0128 + #$012A + #$012C + #$012E + #$0130 + ']';

      //'j': Result := '[jĵJĴ]';
      'j': Result := '[j' + #$0135 + 'J' + #$0134 + ']';

      //'k': Result := '[kķKĶ]';
      'k': Result := '[k' + #$0137 + 'K' + #$0136 + ']';

      //'l': Result := '[lĺļľŀłLĹĻĽĿŁ]';
      'l': Result := '[l' + #$013A + #$013C + #$013E + #$0140 + #$0142 + 'L' + #$0139 + #$013B + #$013D + #$013F + #$0141 + ']';

      'm': Result := '[mM]';

      //'n': Result := '[nñńņňŉNÑŃŅŇ]';
      'n': Result := '[n' + #$00F1 + #$0144 + #$0146 + #$0148 + #$0149 + 'N' + #$00D1 + #$0143 + #$0145 + #$0147 + ']';

      //'o': Result := '[oòóôõöøōŏőOÒÓÔÕÖØŌŎŐ]';
      'o': Result := '[o' + #$00F2 + #$00F3 + #$00F4 + #$00F5 + #$00F6 + #$00F8 + #$014D + #$014F + #$0151 + 'O' + #$00D2 + #$00D3 + #$00D4 + #$00D5 +
          #$00D6 + #$00D8 + #$014C + #$014E + #$0150 + ']';

      'p': Result := '[pP]';

      'q': Result := '[qQ]';

      //'r': Result := '[rŕŗřRŔŖŘ]';
      'r': Result := '[r' + #$0155 + #$0157 + #$0159 + 'R' + #$0154 + #$0156 + #$0158 + ']';

      //'s': Result := '[sS]';//'[sśŝşšSŚŜŞŠ]';
      's': Result := '[s' + #$015B + #$015D + #$015F + #$0161 + 'S' + #$015A + #$015C + #$015E + #$0160 + ']';

      //'t': Result := '[tţťŧTŢŤŦ]';
      't': Result := '[t' + #$0163 + #$0165 + #$0167 + 'T' + #$0162 + #$0164 + #$0166 + ']';

      //'u': Result := '[uùúûüũūŭůűųUÙÚÛÜŨŪŬŮŰŲ]';
      'u': Result := '[u' + #$00F9 + #$00FA + #$00FB + #$00FC + #$0169 + #$016B + #$016D + #$016F + #$0171 + #$0173 + 'U' + #$00D9 + #$00DA + #$00DB +
          #$00DC + #$0168 + #$016A + #$016C + #$016E + #$0170 + #$0172 + ']';

      'v': Result := '[vV]';

      //'w': Result := '[wŵWŴ]';
      'w': Result := '[w' + #$0175 + 'W' + #$0174 + ']';

      'x': Result := '[xX]';

      //'y': Result := '[yýÿŷYÝŸŶ]';
      'y': Result := '[y' + #$00FD + #$00FF + #$0177 + 'Y' + #$00DD + #$0178 + #$0176 + ']';

      //'z': Result := '[zźżžZŹŻŽ]';
      'z': Result := '[z' + #$017A + #$017C + #$017E + 'Z' + #$0179 + #$017B + #$017D + ']';

      //' ': Result := '[  ]';

      // cas particuliers déjà présents dans votre table de fold
      //'f': Result := '[fƒF]';
      'f': Result := '[f' + #$0192 + 'F]';
      // æ et œ sont rabattus sur ae / oe par NormalizeCompareUTF8,
      // donc ils seront traités comme deux lettres.

      // métacaractères GLOB : on les neutralise
      '*': Result := '[*]';
      '?': Result := '[?]';
      '[': Result := '[[]';
      ']': Result := '[]]';

      // Wildcard 4D -> SQL
      '@': Result := '*';

      Else Result := _1_t_ch;
    End;
  End;

Function NormalizeCompareUTF8( Const _1_t_s: string): unicodestring;
  Begin
    Result := NormalizeUTF8( _1_t_s);
    Result := FoldDiacriticsU( Result);
  End;

Function BuildGlobPatternQ4( Const _1_t_s: string): unicodestring;
  Var
    _t_norm: unicodestring;
    _t_pattern: unicodestring;
    _e_i: SizeInt;
  Begin
    _t_norm := NormalizeCompareUTF8( _1_t_s);

    _t_pattern := '';

    For _e_i := 1 To Length( _t_norm) Do _t_pattern := _t_pattern + ExpandBaseCharToGlobClass( _t_norm[_e_i]);

    //ShowMessage(DumpUnicodeCodes(t_pattern));

    //Result := UTF8Encode(t_pattern);
    Result := _t_pattern;
  End;

Function CompareUnicodeTextQ4( Const _1_t_a, _2_t_b: unicodestring): int64;
  Begin
    If ( _1_t_a < _2_t_b) Then Exit( -1);
    If ( _1_t_a > _2_t_b) Then Exit( 1);
    Result := 0;
  End;

Function CompareTextQ4( Const _1_t_a, _2_t_b: string): int64;
  Begin
    Result := CompareUnicodeTextQ4( NormalizeCompareUTF8( _1_t_a), NormalizeCompareUTF8( _2_t_b));
  End;

Function SameTextQ4( Const _1_t_a, _2_t_b: string): boolean;
  Begin
    Result := CompareTextQ4( _1_t_a, _2_t_b) = 0;
  End;

Function jo( Const _1_t_s: string): TPatternString;
  Begin
    Result.Value := NormalizeCompareUTF8( _1_t_s);
  End;

Function MatchPatternU( Const _1_t_text, _2_t_pattern: unicodestring): boolean;
  Var
    t, p: SizeInt;
    wildIdx, match: SizeInt;
  Begin
    // en 4D, @@ ne match jamais
    If ( Pos( '@@', _2_t_pattern) > 0) Then Exit( False);

    t := 1;
    p := 1;
    wildIdx := 0;
    match := 0;

    While ( t <= Length( _1_t_text)) Do If ( ( p <= Length( _2_t_pattern)) and ( _2_t_pattern[p] = _1_t_text[t])) Then Begin
        Inc( t);
        Inc( p);
      End Else If ( ( p <= Length( _2_t_pattern)) and ( _2_t_pattern[p] = '@')) Then Begin
        // @ = zéro, un ou plusieurs caractères
        wildIdx := p;
        match := t;
        Inc( p);
      End Else If ( wildIdx <> 0) Then Begin
        p := wildIdx + 1;
        Inc( match);
        t := match;
      End Else
        Exit( False);

    While ( ( p <= Length( _2_t_pattern)) and ( _2_t_pattern[p] = '@')) Do Inc( p);

    Result := p > Length( _2_t_pattern);
  End;

Function IsSupportedRangePatternU( Const _1_t_pattern: unicodestring): boolean;
  Var
    p: SizeInt;
  Begin
    p := Pos( '@', _1_t_pattern);
    Result :=
      ( p > 0) and ( p = Length( _1_t_pattern)) and ( Pos( '@', Copy( _1_t_pattern, 1, Length( _1_t_pattern) - 1)) = 0);
  End;

Function ComparePrefixRangeU( Const _1_t_text, _2_t_pattern: unicodestring): int64;
  Var
    Prefix:   unicodestring;
    LeftPart: unicodestring;
  Begin
    If ( not IsSupportedRangePatternU( _2_t_pattern)) Then Raise Exception.CreateFmt( 'Motif non supporté pour <, >, <=, >= : "%s" (seul le suffixe @ est accepté).', [UTF8Encode( _2_t_pattern)]);

    Prefix := Copy( _2_t_pattern, 1, Length( _2_t_pattern) - 1);
    LeftPart := Copy( _1_t_text, 1, Length( Prefix));
    Result := CompareUnicodeTextQ4( LeftPart, Prefix);
  End;

Operator =( Const A: string; Const B: TPatternString): boolean;
  Begin
    Result := MatchPatternU( NormalizeCompareUTF8( A), B.Value);
  End;

Operator <( Const A: string; Const B: TPatternString): boolean;
  Begin
    Result := ComparePrefixRangeU( NormalizeCompareUTF8( A), B.Value) < 0;
  End;

Operator >( Const A: string; Const B: TPatternString): boolean;
  Begin
    Result := ComparePrefixRangeU( NormalizeCompareUTF8( A), B.Value) > 0;
  End;

Operator <=( Const A: string; Const B: TPatternString): boolean;
  Begin
    Result := ComparePrefixRangeU( NormalizeCompareUTF8( A), B.Value) <= 0;
  End;

Operator >=( Const A: string; Const B: TPatternString): boolean;
  Begin
    Result := ComparePrefixRangeU( NormalizeCompareUTF8( A), B.Value) >= 0;
  End;

Operator *( Const A: string; Const B: int64): string;
  Var
    i: int64;
  Begin
    Result := '';
    For i := 1 To B Do Result := Result + A;
  End;

Operator *( Const A: int64; Const B: string): string;
  Var
    i: int64;
  Begin
    Result := '';
    For i := 1 To A Do Result := Result + B;
  End;


Function BytesToVariant( Const _1_y_bytes: TBytes): variant;
  Var
    _e_index: int64;
  Begin
    Result := Variants.VarArrayCreate( [0, System.Length( _1_y_bytes) - 1], varByte);

    For _e_index := 0 To High( _1_y_bytes) Do Result[_e_index] := _1_y_bytes[_e_index];
  End;

Function VariantToBytes( Const _1_v_value: variant): TBytes;
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

Function VariantToRealInvariant( Const _1_y_value: variant): double;
  Var
    _t_value: string;
    fs: TFormatSettings;
  Begin
    If ( VarIsNull( _1_y_value) or VarIsEmpty( _1_y_value)) Then Exit( 0);

    _t_value := Trim( VarToStr( _1_y_value));
    If ( _t_value = '') Then Exit( 0);

    _t_value := StringReplace( _t_value, ',', '.', [rfReplaceAll]);

    fs := DefaultFormatSettings;
    fs.DecimalSeparator := '.';

    Result := StrToFloatDef( _t_value, 0, fs);
  End;

Function VariantArraySameValue( Const _1_v_left, _2_v_right: variant): boolean;
  Var
    _e_dim:      int64;
    _e_lowLeft:  int64;
    _e_highLeft: int64;
    _e_lowRight: int64;
    _e_highRight: int64;
    _e_index:    int64;
  Begin
    Result := False;

    If ( not Variants.VarIsArray( _1_v_left)) Then Exit;

    If ( not Variants.VarIsArray( _2_v_right)) Then Exit;

    _e_dim := 1;

    _e_lowLeft := Variants.VarArrayLowBound( _1_v_left, _e_dim);
    _e_highLeft := Variants.VarArrayHighBound( _1_v_left, _e_dim);
    _e_lowRight := Variants.VarArrayLowBound( _2_v_right, _e_dim);
    _e_highRight := Variants.VarArrayHighBound( _2_v_right, _e_dim);

    If ( _e_lowLeft <> _e_lowRight) Then Exit;
    If ( _e_highLeft <> _e_highRight) Then Exit;

    For _e_index := _e_lowLeft To _e_highLeft Do If ( Variants.VarAsType( _1_v_left[_e_index], varByte) <> Variants.VarAsType( _2_v_right[_e_index], varByte)) Then Exit;

    Result := True;
  End;

Function sameValue( Const _1_v_left, _2_v_right: variant): boolean;
  Begin
    If ( Variants.VarIsNull( _1_v_left) and Variants.VarIsNull( _2_v_right)) Then Exit( True);

    If ( Variants.VarIsEmpty( _1_v_left) and Variants.VarIsEmpty( _2_v_right)) Then Exit( True);

    If ( Variants.VarIsNull( _1_v_left) or Variants.VarIsNull( _2_v_right)) Then Exit( False);

    If ( Variants.VarIsEmpty( _1_v_left) or Variants.VarIsEmpty( _2_v_right)) Then Exit( False);

    If ( Variants.VarIsArray( _1_v_left) or Variants.VarIsArray( _2_v_right)) Then Exit( VariantArraySameValue( _1_v_left, _2_v_right));

    If ( VarIsStr( _1_v_left) and VarIsStr( _2_v_right)) Then Exit( SameTextQ4( VarToStr( _1_v_left), VarToStr( _2_v_right)));

    Try
      Result := _1_v_left = _2_v_right;
    Except
      Result := False;
    End;
  End;

End.
