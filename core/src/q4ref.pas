Unit q4ref;

{$mode objfpc}
{$H+}
{$T+}
{$inline on}

{
  q4ref
  version du 2026/04/26

  Rôle
  ----
  Unité socle pour transporter une référence typée q4.

  Un TQ4Ref n'est pas un pointeur Pascal brut : c'est un petit descripteur
  qui associe :
    - Ptr        : l'adresse réelle ;
    - TargetKind : nature de la cible : valeur, tableau, élément, etc. ;
    - ValueKind  : type logique q4 : text, date, int64, blob, picture, etc. ;
    - Info/Size  : informations optionnelles utiles au runtime.

  Convention importante pour les tableaux
  ----------------------------------------
  Pour un tableau, Ptr pointe toujours vers la variable tableau complète :

      Ptr := @MyArray

  et jamais vers le premier élément :

      Ptr <> @MyArray[0]

  Cela permet aux commandes comme appendToArray, insertInArray ou SetLength
  de modifier réellement la variable tableau.

  Picture
  -------
  Picture reste un type logique q4, mais son stockage interne est binaire.
  Dans q4coreLanguage, il doit donc rester compatible TBytes :

      Tq4PictureArray = array of TBytes

  ou, si un alias est souhaité plus tard :

      Tq4Picture = TBytes;          // alias simple, pas TBitmap
      Tq4PictureArray = array of Tq4Picture;

  q4ref ne dépend donc pas de TBitmap et ne fait aucune conversion image.
  Une future unité q4pictures pourra charger/convertir des images si besoin.

  Exemples
  --------

      appendToArray(q4ref.hpa(MyTextArray), 'abc');
      appendToArray(q4ref.hpa(MyInt64Array), Int64(53));
      appendToArray(q4ref.hpa(MyPictureArray), PictureBytes);

      SomeProc(q4ref.hpt(@MyInt64));
      SomeProc(q4ref.hptDate(@MyDate));
      SomeProc(q4ref.hptPicture(@MyPictureBytes));

  Si le transpileur n'a déjà plus qu'un Pointer brut, il doit fournir le type :

      SomeProc(q4ref.hpaRaw(P, q4ref.q4vkText));
      SomeProc(q4ref.raw(P, q4ref.q4tkArray, q4ref.q4vkInt64));

  Limite
  ------
  TQ4Ref transporte le type, mais ne garantit pas la durée de vie de la cible.
  Un pointeur vers une variable locale expirée reste dangereux.
}

Interface

Uses
  SysUtils,
  TypInfo,
  Variants,
  q4coreLanguage;

Type
  { Alias de compatibilité : les enums sont propriétaires de q4coreLanguage.
    Les alias conservent les signatures existantes de q4ref tout en évitant
    que q4ref devienne l'unité de référence des types fondamentaux q4. }
  TQ4TargetKind = q4coreLanguage.TQ4TargetKind;
  TQ4ValueKind = q4coreLanguage.TQ4ValueKind;

  TQ4Ref = Record
    Ptr: Pointer;
    TargetKind: TQ4TargetKind;
    ValueKind: TQ4ValueKind;
    Info: PTypeInfo;
    Size: SizeUInt;
  End;

Const
  { Alias de compatibilité pour le code existant qui qualifie encore les
    constantes par q4ref, par exemple q4ref.q4vkText.
    Les constantes canoniques sont maintenant dans q4coreLanguage. }
  q4tkUnknown = q4coreLanguage.q4tkUnknown;
  q4tkValue = q4coreLanguage.q4tkValue;
  q4tkArray = q4coreLanguage.q4tkArray;
  q4tkArrayElement = q4coreLanguage.q4tkArrayElement;
  q4tkField = q4coreLanguage.q4tkField;
  q4tkCustom = q4coreLanguage.q4tkCustom;

  q4vkUnknown = q4coreLanguage.q4vkUnknown;
  q4vkInteger = q4coreLanguage.q4vkInteger;
  q4vkInt64 = q4coreLanguage.q4vkInt64;
  q4vkReal = q4coreLanguage.q4vkReal;
  q4vkBoolean = q4coreLanguage.q4vkBoolean;
  q4vkText = q4coreLanguage.q4vkText;
  q4vkDate = q4coreLanguage.q4vkDate;
  q4vkTime = q4coreLanguage.q4vkTime;
  q4vkObject = q4coreLanguage.q4vkObject;
  q4vkCollection = q4coreLanguage.q4vkCollection;
  q4vkBlob = q4coreLanguage.q4vkBlob;
  q4vkPicture = q4coreLanguage.q4vkPicture;
  q4vkPointer = q4coreLanguage.q4vkPointer;
  q4vkVariant = q4coreLanguage.q4vkVariant;
  q4vkNativeObject = q4coreLanguage.q4vkNativeObject;
  q4vkCustom = q4coreLanguage.q4vkCustom;

  q4RefNull: TQ4Ref = ( Ptr: nil; TargetKind: q4tkUnknown; ValueKind: q4vkUnknown; Info: nil; Size: 0);

Type
  { Pointeurs vers valeurs scalaires q4. }
  Pq4Integer = ^integer;
  Pq4Int64 = ^int64;
  Pq4Real = ^double;
  Pq4Boolean = ^boolean;

  Pq4Text = ^string;
  Pq4Date = ^Tq4Date;
  Pq4Time = ^Tq4Time;
  Pq4JSONObject = ^Tq4JSONObject;
  Pq4JSONCollection = ^Tq4JSONCollection;

  Pq4Bytes = ^TBytes;
  Pq4Pointer = ^Pointer;
  Pq4Variant = ^variant;
  Pq4NativeObject = ^TObject;

  { Pointeurs vers variables tableaux q4. }
  Pq4TextArray = ^Tq4TextArray;
  Pq4DateArray = ^Tq4DateArray;
  Pq4TimeArray = ^Tq4TimeArray;
  Pq4ObjectArray = ^Tq4ObjectArray;
  Pq4CollectionArray = ^Tq4CollectionArray;
  Pq4Int64Array = ^Tq4Int64Array;
  Pq4RealArray = ^Tq4RealArray;
  Pq4BooleanArray = ^Tq4BooleanArray;
  Pq4BlobArray = ^Tq4BlobArray;
  Pq4PointerArray = ^Tq4PointerArray;
  Pq4PictureArray = ^Tq4PictureArray;

Function nullRef: TQ4Ref; Inline;

Function valueKindName( _1_y_kind: TQ4ValueKind): string;
Function targetKindName( _1_y_kind: TQ4TargetKind): string;
Function defaultValueSize( _1_y_kind: TQ4ValueKind): SizeUInt;
Function defaultValueTypeInfo( _1_y_kind: TQ4ValueKind): PTypeInfo;

{ hpt = handle pointer typed : pointeur typé vers une valeur. }
Function hpt( _1_p_p: Pq4Integer): TQ4Ref; overload; Inline;
Function hpt( _1_p_p: Pq4Int64): TQ4Ref; overload; Inline;
Function hpt( _1_p_p: Pq4Real): TQ4Ref; overload; Inline;
Function hpt( _1_p_p: Pq4Boolean): TQ4Ref; overload; Inline;
Function hpt( _1_p_p: Pq4Text): TQ4Ref; overload; Inline;
Function hpt( _1_p_p: Pq4Date): TQ4Ref; overload; Inline;
Function hpt( _1_p_p: Pq4Time): TQ4Ref; overload; Inline;
Function hpt( _1_p_p: Pq4JSONObject): TQ4Ref; overload; Inline;
Function hpt( _1_p_p: Pq4JSONCollection): TQ4Ref; overload; Inline;
Function hpt( _1_p_p: Pq4Pointer): TQ4Ref; overload; Inline;
Function hpt( _1_p_p: Pq4Variant): TQ4Ref; overload; Inline;
Function hpt( _1_p_p: Pq4NativeObject): TQ4Ref; overload; Inline;

{ Blob et Picture sont tous les deux stockés en TBytes, mais restent deux
  types logiques q4 différents. }
Function hptBlob( _1_p_p: Pq4Bytes): TQ4Ref; Inline;
Function hptPicture( _1_p_p: Pq4Bytes): TQ4Ref; Inline;

{ hpa = handle pointer array : référence vers une variable tableau q4. }
Function hpa( Var _1_tt_a: Tq4TextArray): TQ4Ref; overload; Inline;
Function hpa( Var _1_te_a: Tq4DateArray): TQ4Ref; overload; Inline;
Function hpa( Var _1_te_a: Tq4TimeArray): TQ4Ref; overload; Inline;
Function hpa( Var _1_to_a: Tq4ObjectArray): TQ4Ref; overload; Inline;
Function hpa( Var _1_y_a: Tq4CollectionArray): TQ4Ref; overload; Inline;
Function hpa( Var _1_te_a: Tq4Int64Array): TQ4Ref; overload; Inline;
Function hpa( Var _1_tr_a: Tq4RealArray): TQ4Ref; overload; Inline;
Function hpa( Var _1_tb_a: Tq4BooleanArray): TQ4Ref; overload; Inline;
Function hpa( Var _1_ty_a: Tq4BlobArray): TQ4Ref; overload; Inline;
Function hpa( Var _1_tp_a: Tq4PointerArray): TQ4Ref; overload; Inline;
Function hpa( Var _1_ty_a: Tq4PictureArray): TQ4Ref; overload; Inline;

Function hptRaw( _1_p_p: Pointer; _2_y_valueKind: TQ4ValueKind): TQ4Ref; overload; Inline;
Function hptRaw( _1_p_p: Pointer; _2_y_valueKind: TQ4ValueKind; _3_y_size: SizeUInt; _4_p_info: PTypeInfo = nil): TQ4Ref; overload; Inline;

Function hpaRaw( _1_p_p: Pointer; _2_y_valueKind: TQ4ValueKind): TQ4Ref; overload; Inline;
Function hpaRaw( _1_p_p: Pointer; _2_y_valueKind: TQ4ValueKind; _3_y_elementSize: SizeUInt; _4_p_info: PTypeInfo = nil): TQ4Ref; overload; Inline;

Function raw( _1_p_p: Pointer; _2_y_targetKind: TQ4TargetKind; _3_y_valueKind: TQ4ValueKind): TQ4Ref; overload; Inline;
Function raw( _1_p_p: Pointer; _2_y_targetKind: TQ4TargetKind; _3_y_valueKind: TQ4ValueKind; _4_y_size: SizeUInt; _5_p_info: PTypeInfo = nil): TQ4Ref; overload; Inline;

Function elementRaw( _1_p_p: Pointer; _2_y_valueKind: TQ4ValueKind): TQ4Ref; overload; Inline;
Function elementRaw( _1_p_p: Pointer; _2_y_valueKind: TQ4ValueKind; _3_y_size: SizeUInt; _4_p_info: PTypeInfo = nil): TQ4Ref; overload; Inline;

{%Region ClaudePointer}
Type
  PQ4Ref = ^TQ4Ref;
  Tq4RefArray = Array Of TQ4Ref;
  Pq4RefArray = ^Tq4RefArray;

{ Dépointage scalaire }
Function asTBytes( Const _1_y_r: TQ4Ref): TBytes;
Function AsBoolean( Const _1_y_r: TQ4Ref): boolean;
Function AsString( Const _1_y_r: TQ4Ref): string;
Function asInt64( Const _1_y_r: TQ4Ref): int64;
Function asDouble( Const _1_y_r: TQ4Ref): double;
Function AsVariant( Const _1_y_r: TQ4Ref): variant;
Function asTQ4Ref( Const _1_y_r: TQ4Ref): TQ4Ref;

{ Dépointage d'élément de tableau }
Function asTBytesAt( Const _1_y_r: TQ4Ref; _2_e_indice: int64): TBytes;
Function asBooleanAt( Const _1_y_r: TQ4Ref; _2_e_indice: int64): boolean;
Function asStringAt( Const _1_y_r: TQ4Ref; _2_e_indice: int64): string;
Function asInt64At( Const _1_y_r: TQ4Ref; _2_e_indice: int64): int64;
Function asDoubleAt( Const _1_y_r: TQ4Ref; _2_e_indice: int64): double;
Function asVariantAt( Const _1_y_r: TQ4Ref; _2_e_indice: int64): variant;

{ Affectation via pointeur scalaire }
Procedure setPointedValue( Const _1_y_p: TQ4Ref; Const _2_by_value: TBytes); overload;
Procedure setPointedValue( Const _1_y_p: TQ4Ref; _2_b_value: boolean); overload;
Procedure setPointedValue( Const _1_y_p: TQ4Ref; Const _2_t_value: string); overload;
Procedure setPointedValue( Const _1_y_p: TQ4Ref; _2_e_value: int64); overload;
Procedure setPointedValue( Const _1_y_p: TQ4Ref; _2_r_value: double); overload;
Procedure setPointedValue( Const _1_y_p: TQ4Ref; Const _2_y_value: TQ4Ref); overload;

{ Affectation d'élément de tableau via pointeur }
Procedure setPointedValueAt( Const _1_y_p: TQ4Ref; _2_e_indice: int64; Const _3_by_value: TBytes); overload;
Procedure setPointedValueAt( Const _1_y_p: TQ4Ref; _2_e_indice: int64; _3_b_value: boolean); overload;
Procedure setPointedValueAt( Const _1_y_p: TQ4Ref; _2_e_indice: int64; Const _3_t_value: string); overload;
Procedure setPointedValueAt( Const _1_y_p: TQ4Ref; _2_e_indice: int64; _3_e_value: int64); overload;
Procedure setPointedValueAt( Const _1_y_p: TQ4Ref; _2_e_indice: int64; _3_r_value: double); overload;
Procedure setPointedValueAt( Const _1_y_p: TQ4Ref; _2_e_indice: int64; Const _3_y_value: TQ4Ref); overload;
{%EndRegion ClaudePointer}

Procedure requireAssigned( Const _1_y_r: TQ4Ref; Const _2_t_where: string);
Procedure requireTarget( Const _1_y_r: TQ4Ref; _2_y_expected: TQ4TargetKind; Const _3_t_where: string);
Procedure requireValue( Const _1_y_r: TQ4Ref; _2_y_expected: TQ4ValueKind; Const _3_t_where: string);
Procedure requireArray( Const _1_y_r: TQ4Ref; Const _2_t_where: string);
Procedure requireArrayValue( Const _1_y_r: TQ4Ref; _2_y_expected: TQ4ValueKind; Const _3_t_where: string);
Procedure requireValueTarget( Const _1_y_r: TQ4Ref; Const _2_t_where: string);

Implementation

{%Region ClaudePointer}
Procedure refTypeMismatch( Const _1_y_r: TQ4Ref; _2_y_expected: TQ4ValueKind; Const _3_t_where: string);
  Begin
    Raise Exception.Create( _3_t_where + ': type ' + valueKindName( _2_y_expected) + ' attendu, reçu ' + valueKindName( _1_y_r.ValueKind));
  End;

Function asTBytes( Const _1_y_r: TQ4Ref): TBytes;
  Begin
    SetLength( Result, 0);
    If ( ( _1_y_r.Ptr = nil) or not ( _1_y_r.ValueKind in [q4vkBlob, q4vkPicture])) Then Begin
      refTypeMismatch( _1_y_r, q4vkBlob, 'asTBytes');
      Exit;
    End;
    Result := Pq4Bytes( _1_y_r.Ptr)^;
  End;

Function AsBoolean( Const _1_y_r: TQ4Ref): boolean;
  Begin
    Result := False;
    If ( ( _1_y_r.Ptr = nil) or ( _1_y_r.ValueKind <> q4vkBoolean)) Then Begin
      refTypeMismatch( _1_y_r, q4vkBoolean, 'asBoolean');
      Exit;
    End;
    Result := Pq4Boolean( _1_y_r.Ptr)^;
  End;

Function AsString( Const _1_y_r: TQ4Ref): string;
  Begin
    Result := '';
    If ( ( _1_y_r.Ptr = nil) or ( _1_y_r.ValueKind <> q4vkText)) Then Begin
      refTypeMismatch( _1_y_r, q4vkText, 'asString');
      Exit;
    End;
    Result := Pq4Text( _1_y_r.Ptr)^;
  End;

Function asInt64( Const _1_y_r: TQ4Ref): int64;
  Begin
    Result := 0;
    If ( ( _1_y_r.Ptr = nil) or ( _1_y_r.ValueKind <> q4vkInt64)) Then Begin
      refTypeMismatch( _1_y_r, q4vkInt64, 'asInt64');
      Exit;
    End;
    Result := Pq4Int64( _1_y_r.Ptr)^;
  End;

Function asDouble( Const _1_y_r: TQ4Ref): double;
  Begin
    Result := 0.0;
    If ( ( _1_y_r.Ptr = nil) or ( _1_y_r.ValueKind <> q4vkReal)) Then Begin
      refTypeMismatch( _1_y_r, q4vkReal, 'asDouble');
      Exit;
    End;
    Result := Pq4Real( _1_y_r.Ptr)^;
  End;

Procedure setPointedValue( Const _1_y_p: TQ4Ref; Const _2_by_value: TBytes);
  Begin
    requireValueTarget( _1_y_p, 'setPointedValue(TBytes)');
    If ( not ( _1_y_p.ValueKind in [q4vkBlob, q4vkPicture])) Then Begin
      refTypeMismatch( _1_y_p, q4vkBlob, 'setPointedValue(TBytes)');
      Exit;
    End;
    Pq4Bytes( _1_y_p.Ptr)^ := _2_by_value;
  End;

Procedure setPointedValue( Const _1_y_p: TQ4Ref; _2_b_value: boolean);
  Begin
    requireValueTarget( _1_y_p, 'setPointedValue(Boolean)');
    If ( _1_y_p.ValueKind <> q4vkBoolean) Then Begin
      refTypeMismatch( _1_y_p, q4vkBoolean, 'setPointedValue(Boolean)');
      Exit;
    End;
    Pq4Boolean( _1_y_p.Ptr)^ := _2_b_value;
  End;

Procedure setPointedValue( Const _1_y_p: TQ4Ref; Const _2_t_value: string);
  Begin
    requireValueTarget( _1_y_p, 'setPointedValue(string)');
    If ( _1_y_p.ValueKind <> q4vkText) Then Begin
      refTypeMismatch( _1_y_p, q4vkText, 'setPointedValue(string)');
      Exit;
    End;
    Pq4Text( _1_y_p.Ptr)^ := _2_t_value;
  End;

Procedure setPointedValue( Const _1_y_p: TQ4Ref; _2_e_value: int64);
  Begin
    requireValueTarget( _1_y_p, 'setPointedValue(Int64)');
    If ( _1_y_p.ValueKind <> q4vkInt64) Then Begin
      refTypeMismatch( _1_y_p, q4vkInt64, 'setPointedValue(Int64)');
      Exit;
    End;
    Pq4Int64( _1_y_p.Ptr)^ := _2_e_value;
  End;

Procedure setPointedValue( Const _1_y_p: TQ4Ref; _2_r_value: double);
  Begin
    requireValueTarget( _1_y_p, 'setPointedValue(Double)');
    If ( _1_y_p.ValueKind <> q4vkReal) Then Begin
      refTypeMismatch( _1_y_p, q4vkReal, 'setPointedValue(Double)');
      Exit;
    End;
    Pq4Real( _1_y_p.Ptr)^ := _2_r_value;
  End;

Procedure setPointedValueAt( Const _1_y_p: TQ4Ref; _2_e_indice: int64; Const _3_by_value: TBytes);
  Begin
    requireArray( _1_y_p, 'setPointedValueAt(TBytes)');
    If ( not ( _1_y_p.ValueKind in [q4vkBlob, q4vkPicture])) Then Begin
      refTypeMismatch( _1_y_p, q4vkBlob, 'setPointedValueAt(TBytes)');
      Exit;
    End;
    Pq4BlobArray( _1_y_p.Ptr)^[_2_e_indice] := _3_by_value;
  End;

Procedure setPointedValueAt( Const _1_y_p: TQ4Ref; _2_e_indice: int64; _3_b_value: boolean);
  Begin
    requireArray( _1_y_p, 'setPointedValueAt(Boolean)');
    If ( _1_y_p.ValueKind <> q4vkBoolean) Then Begin
      refTypeMismatch( _1_y_p, q4vkBoolean, 'setPointedValueAt(Boolean)');
      Exit;
    End;
    Pq4BooleanArray( _1_y_p.Ptr)^[_2_e_indice] := _3_b_value;
  End;

Procedure setPointedValueAt( Const _1_y_p: TQ4Ref; _2_e_indice: int64; Const _3_t_value: string);
  Begin
    requireArray( _1_y_p, 'setPointedValueAt(string)');
    If ( _1_y_p.ValueKind <> q4vkText) Then Begin
      refTypeMismatch( _1_y_p, q4vkText, 'setPointedValueAt(string)');
      Exit;
    End;
    Pq4TextArray( _1_y_p.Ptr)^[_2_e_indice] := _3_t_value;
  End;

Procedure setPointedValueAt( Const _1_y_p: TQ4Ref; _2_e_indice: int64; _3_e_value: int64);
  Begin
    requireArray( _1_y_p, 'setPointedValueAt(Int64)');
    If ( _1_y_p.ValueKind <> q4vkInt64) Then Begin
      refTypeMismatch( _1_y_p, q4vkInt64, 'setPointedValueAt(Int64)');
      Exit;
    End;
    Pq4Int64Array( _1_y_p.Ptr)^[_2_e_indice] := _3_e_value;
  End;

Procedure setPointedValueAt( Const _1_y_p: TQ4Ref; _2_e_indice: int64; _3_r_value: double);
  Begin
    requireArray( _1_y_p, 'setPointedValueAt(Double)');
    If ( _1_y_p.ValueKind <> q4vkReal) Then Begin
      refTypeMismatch( _1_y_p, q4vkReal, 'setPointedValueAt(Double)');
      Exit;
    End;
    Pq4RealArray( _1_y_p.Ptr)^[_2_e_indice] := _3_r_value;
  End;

Function AsVariant( Const _1_y_r: TQ4Ref): variant;
  Begin
    Result := Null;
    requireAssigned( _1_y_r, 'asVariant');
    Case _1_y_r.ValueKind Of
      q4vkBoolean: Result := Pq4Boolean( _1_y_r.Ptr)^;
      q4vkInteger: Result := Pq4Integer( _1_y_r.Ptr)^;
      q4vkInt64: Result := Pq4Int64( _1_y_r.Ptr)^;
      q4vkReal: Result := Pq4Real( _1_y_r.Ptr)^;
      q4vkText: Result := Pq4Text( _1_y_r.Ptr)^;
      q4vkDate: Result := Pq4Date( _1_y_r.Ptr)^;
      q4vkTime: Result := Pq4Time( _1_y_r.Ptr)^;
      q4vkVariant: Result := Pq4Variant( _1_y_r.Ptr)^;
      Else Raise Exception.Create( 'asVariant: type non géré : ' + valueKindName( _1_y_r.ValueKind));
    End;
  End;

Function asTQ4Ref( Const _1_y_r: TQ4Ref): TQ4Ref;
  Begin
    Result := nullRef;
    If ( ( _1_y_r.Ptr = nil) or ( _1_y_r.ValueKind <> q4vkPointer)) Then Begin
      refTypeMismatch( _1_y_r, q4vkPointer, 'asTQ4Ref');
      Exit;
    End;
    Result := PQ4Ref( _1_y_r.Ptr)^;
  End;

Function asTBytesAt( Const _1_y_r: TQ4Ref; _2_e_indice: int64): TBytes;
  Begin
    SetLength( Result, 0);
    requireArray( _1_y_r, 'asTBytesAt');
    If ( not ( _1_y_r.ValueKind in [q4vkBlob, q4vkPicture])) Then Begin
      refTypeMismatch( _1_y_r, q4vkBlob, 'asTBytesAt');
      Exit;
    End;
    Result := Pq4BlobArray( _1_y_r.Ptr)^[_2_e_indice];
  End;

Function asBooleanAt( Const _1_y_r: TQ4Ref; _2_e_indice: int64): boolean;
  Begin
    Result := False;
    requireArray( _1_y_r, 'asBooleanAt');
    If ( _1_y_r.ValueKind <> q4vkBoolean) Then Begin
      refTypeMismatch( _1_y_r, q4vkBoolean, 'asBooleanAt');
      Exit;
    End;
    Result := Pq4BooleanArray( _1_y_r.Ptr)^[_2_e_indice];
  End;

Function asStringAt( Const _1_y_r: TQ4Ref; _2_e_indice: int64): string;
  Begin
    Result := '';
    requireArray( _1_y_r, 'asStringAt');
    If ( _1_y_r.ValueKind <> q4vkText) Then Begin
      refTypeMismatch( _1_y_r, q4vkText, 'asStringAt');
      Exit;
    End;
    Result := Pq4TextArray( _1_y_r.Ptr)^[_2_e_indice];
  End;

Function asInt64At( Const _1_y_r: TQ4Ref; _2_e_indice: int64): int64;
  Begin
    Result := 0;
    requireArray( _1_y_r, 'asInt64At');
    If ( _1_y_r.ValueKind <> q4vkInt64) Then Begin
      refTypeMismatch( _1_y_r, q4vkInt64, 'asInt64At');
      Exit;
    End;
    Result := Pq4Int64Array( _1_y_r.Ptr)^[_2_e_indice];
  End;

Function asDoubleAt( Const _1_y_r: TQ4Ref; _2_e_indice: int64): double;
  Begin
    Result := 0.0;
    requireArray( _1_y_r, 'asDoubleAt');
    If ( _1_y_r.ValueKind <> q4vkReal) Then Begin
      refTypeMismatch( _1_y_r, q4vkReal, 'asDoubleAt');
      Exit;
    End;
    Result := Pq4RealArray( _1_y_r.Ptr)^[_2_e_indice];
  End;

Function asVariantAt( Const _1_y_r: TQ4Ref; _2_e_indice: int64): variant;
  Begin
    Result := Null;
    requireArray( _1_y_r, 'asVariantAt');
    Case _1_y_r.ValueKind Of
      q4vkBoolean: Result := Pq4BooleanArray( _1_y_r.Ptr)^[_2_e_indice];
      q4vkInt64: Result := Pq4Int64Array( _1_y_r.Ptr)^[_2_e_indice];
      q4vkReal: Result := Pq4RealArray( _1_y_r.Ptr)^[_2_e_indice];
      q4vkText: Result := Pq4TextArray( _1_y_r.Ptr)^[_2_e_indice];
      q4vkDate: Result := Pq4DateArray( _1_y_r.Ptr)^[_2_e_indice];
      q4vkTime: Result := Pq4TimeArray( _1_y_r.Ptr)^[_2_e_indice];
      Else Raise Exception.Create( 'asVariantAt: type non géré : ' + valueKindName( _1_y_r.ValueKind));
    End;
  End;

Procedure setPointedValue( Const _1_y_p: TQ4Ref; Const _2_y_value: TQ4Ref);
  Begin
    requireValueTarget( _1_y_p, 'setPointedValue(TQ4Ref)');
    If ( _1_y_p.ValueKind <> q4vkPointer) Then Begin
      refTypeMismatch( _1_y_p, q4vkPointer, 'setPointedValue(TQ4Ref)');
      Exit;
    End;
    PQ4Ref( _1_y_p.Ptr)^ := _2_y_value;
  End;

Procedure setPointedValueAt( Const _1_y_p: TQ4Ref; _2_e_indice: int64; Const _3_y_value: TQ4Ref);
  Begin
    requireArray( _1_y_p, 'setPointedValueAt(TQ4Ref)');
    If ( _1_y_p.ValueKind <> q4vkPointer) Then Begin
      refTypeMismatch( _1_y_p, q4vkPointer, 'setPointedValueAt(TQ4Ref)');
      Exit;
    End;
    Pq4RefArray( _1_y_p.Ptr)^[_2_e_indice] := _3_y_value;
  End;
{%EndRegion ClaudePointer}

Function makeRef( _1_p_p: Pointer; _2_y_targetKind: TQ4TargetKind; _3_y_valueKind: TQ4ValueKind; _4_y_size: SizeUInt; _5_p_info: PTypeInfo): TQ4Ref; Inline;
  Begin
    Result.Ptr := _1_p_p;
    Result.TargetKind := _2_y_targetKind;
    Result.ValueKind := _3_y_valueKind;
    Result.Info := _5_p_info;
    Result.Size := _4_y_size;
  End;

Function nullRef: TQ4Ref; Inline;
  Begin
    Result := makeRef( nil, q4tkUnknown, q4vkUnknown, 0, nil);
  End;

Function targetKindName( _1_y_kind: TQ4TargetKind): string;
  Begin
    Case _1_y_kind Of
      q4tkUnknown: Result := 'unknown';
      q4tkValue: Result := 'value';
      q4tkArray: Result := 'array';
      q4tkArrayElement: Result := 'arrayElement';
      q4tkField: Result := 'field';
      q4tkCustom: Result := 'custom';
      Else Result := 'invalidTargetKind';
    End;
  End;

Function valueKindName( _1_y_kind: TQ4ValueKind): string;
  Begin
    Case _1_y_kind Of
      q4vkUnknown: Result := 'unknown';
      q4vkInteger: Result := 'integer';
      q4vkInt64: Result := 'int64';
      q4vkReal: Result := 'real';
      q4vkBoolean: Result := 'boolean';
      q4vkText: Result := 'text';
      q4vkDate: Result := 'date';
      q4vkTime: Result := 'time';
      q4vkObject: Result := 'object';
      q4vkCollection: Result := 'collection';
      q4vkBlob: Result := 'blob';
      q4vkPicture: Result := 'picture';
      q4vkPointer: Result := 'pointer';
      q4vkVariant: Result := 'variant';
      q4vkNativeObject: Result := 'nativeObject';
      q4vkCustom: Result := 'custom';
      Else Result := 'invalidValueKind';
    End;
  End;

Function defaultValueSize( _1_y_kind: TQ4ValueKind): SizeUInt;
  Begin
    Case _1_y_kind Of
      q4vkInteger: Result := SizeOf( integer);
      q4vkInt64: Result := SizeOf( int64);
      q4vkReal: Result := SizeOf( double);
      q4vkBoolean: Result := SizeOf( boolean);
      q4vkText: Result := SizeOf( string);
      q4vkDate: Result := SizeOf( Tq4Date);
      q4vkTime: Result := SizeOf( Tq4Time);
      q4vkObject: Result := SizeOf( Tq4JSONObject);
      q4vkCollection: Result := SizeOf( Tq4JSONCollection);
      q4vkBlob: Result := SizeOf( TBytes);
      q4vkPicture: Result := SizeOf( TBytes);
      q4vkPointer: Result := SizeOf( Pointer);
      q4vkVariant: Result := SizeOf( variant);
      q4vkNativeObject: Result := SizeOf( Pointer);
      Else Result := 0;
    End;
  End;

Function defaultValueTypeInfo( _1_y_kind: TQ4ValueKind): PTypeInfo;
  Begin
    Case _1_y_kind Of
      q4vkInteger: Result := TypeInfo( integer);
      q4vkInt64: Result := TypeInfo( int64);
      q4vkReal: Result := TypeInfo( double);
      q4vkBoolean: Result := TypeInfo( boolean);
      q4vkText: Result := TypeInfo( string);
      q4vkDate: Result := TypeInfo( Tq4Date);
      q4vkTime: Result := TypeInfo( Tq4Time);
      q4vkPointer: Result := TypeInfo( Pointer);
      q4vkVariant: Result := TypeInfo( variant);
      q4vkNativeObject: Result := TypeInfo( TObject);
      Else { Blob/Picture/Object/Collection peuvent être portés par des types
      qui évolueront. ValueKind suffit pour le dispatch. }
        Result := nil;
    End;
  End;

Function hpt( _1_p_p: Pq4Integer): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkInteger, SizeOf( integer), TypeInfo( integer));
  End;

Function hpt( _1_p_p: Pq4Int64): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkInt64, SizeOf( int64), TypeInfo( int64));
  End;

Function hpt( _1_p_p: Pq4Real): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkReal, SizeOf( double), TypeInfo( double));
  End;

Function hpt( _1_p_p: Pq4Boolean): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkBoolean, SizeOf( boolean), TypeInfo( boolean));
  End;

Function hpt( _1_p_p: Pq4Text): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkText, SizeOf( string), TypeInfo( string));
  End;

Function hpt( _1_p_p: Pq4Date): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkDate, SizeOf( Tq4Date), TypeInfo( Tq4Date));
  End;

Function hpt( _1_p_p: Pq4Time): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkTime, SizeOf( Tq4Time), TypeInfo( Tq4Time));
  End;

Function hpt( _1_p_p: Pq4JSONObject): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkObject, SizeOf( Tq4JSONObject), nil);
  End;

Function hpt( _1_p_p: Pq4JSONCollection): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkCollection, SizeOf( Tq4JSONCollection), nil);
  End;

Function hpt( _1_p_p: Pq4Pointer): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkPointer, SizeOf( Pointer), TypeInfo( Pointer));
  End;

Function hpt( _1_p_p: Pq4Variant): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkVariant, SizeOf( variant), TypeInfo( variant));
  End;

Function hpt( _1_p_p: Pq4NativeObject): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkNativeObject, SizeOf( Pointer), TypeInfo( TObject));
  End;

Function hptBlob( _1_p_p: Pq4Bytes): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkBlob, SizeOf( TBytes), nil);
  End;

Function hptPicture( _1_p_p: Pq4Bytes): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, q4vkPicture, SizeOf( TBytes), nil);
  End;

Function hpa( Var _1_tt_a: Tq4TextArray): TQ4Ref; Inline;
  Begin
    Result := makeRef( @_1_tt_a, q4tkArray, q4vkText, SizeOf( string), TypeInfo( string));
  End;

Function hpa( Var _1_te_a: Tq4DateArray): TQ4Ref; Inline;
  Begin
    Result := makeRef( @_1_te_a, q4tkArray, q4vkDate, SizeOf( Tq4Date), TypeInfo( Tq4Date));
  End;

Function hpa( Var _1_te_a: Tq4TimeArray): TQ4Ref; Inline;
  Begin
    Result := makeRef( @_1_te_a, q4tkArray, q4vkTime, SizeOf( Tq4Time), TypeInfo( Tq4Time));
  End;

Function hpa( Var _1_to_a: Tq4ObjectArray): TQ4Ref; Inline;
  Begin
    Result := makeRef( @_1_to_a, q4tkArray, q4vkObject, SizeOf( Tq4JSONObject), nil);
  End;

Function hpa( Var _1_y_a: Tq4CollectionArray): TQ4Ref; Inline;
  Begin
    Result := makeRef( @_1_y_a, q4tkArray, q4vkCollection, SizeOf( Tq4JSONCollection), nil);
  End;

Function hpa( Var _1_te_a: Tq4Int64Array): TQ4Ref; Inline;
  Begin
    Result := makeRef( @_1_te_a, q4tkArray, q4vkInt64, SizeOf( int64), TypeInfo( int64));
  End;

Function hpa( Var _1_tr_a: Tq4RealArray): TQ4Ref; Inline;
  Begin
    Result := makeRef( @_1_tr_a, q4tkArray, q4vkReal, SizeOf( double), TypeInfo( double));
  End;

Function hpa( Var _1_tb_a: Tq4BooleanArray): TQ4Ref; Inline;
  Begin
    Result := makeRef( @_1_tb_a, q4tkArray, q4vkBoolean, SizeOf( boolean), TypeInfo( boolean));
  End;

Function hpa( Var _1_ty_a: Tq4BlobArray): TQ4Ref; Inline;
  Begin
    Result := makeRef( @_1_ty_a, q4tkArray, q4vkBlob, SizeOf( TBytes), nil);
  End;

Function hpa( Var _1_tp_a: Tq4PointerArray): TQ4Ref; Inline;
  Begin
    Result := makeRef( @_1_tp_a, q4tkArray, q4vkPointer, SizeOf( Pointer), TypeInfo( Pointer));
  End;

Function hpa( Var _1_ty_a: Tq4PictureArray): TQ4Ref; Inline;
  Begin
    Result := makeRef( @_1_ty_a, q4tkArray, q4vkPicture, SizeOf( TBytes), nil);
  End;

Function hptRaw( _1_p_p: Pointer; _2_y_valueKind: TQ4ValueKind): TQ4Ref; Inline;
  Begin
    Result := hptRaw( _1_p_p, _2_y_valueKind, defaultValueSize( _2_y_valueKind), defaultValueTypeInfo( _2_y_valueKind));
  End;

Function hptRaw( _1_p_p: Pointer; _2_y_valueKind: TQ4ValueKind; _3_y_size: SizeUInt; _4_p_info: PTypeInfo): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkValue, _2_y_valueKind, _3_y_size, _4_p_info);
  End;

Function hpaRaw( _1_p_p: Pointer; _2_y_valueKind: TQ4ValueKind): TQ4Ref; Inline;
  Begin
    Result := hpaRaw( _1_p_p, _2_y_valueKind, defaultValueSize( _2_y_valueKind), defaultValueTypeInfo( _2_y_valueKind));
  End;

Function hpaRaw( _1_p_p: Pointer; _2_y_valueKind: TQ4ValueKind; _3_y_elementSize: SizeUInt; _4_p_info: PTypeInfo): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkArray, _2_y_valueKind, _3_y_elementSize, _4_p_info);
  End;

Function raw( _1_p_p: Pointer; _2_y_targetKind: TQ4TargetKind; _3_y_valueKind: TQ4ValueKind): TQ4Ref; Inline;
  Begin
    Result := raw( _1_p_p, _2_y_targetKind, _3_y_valueKind, defaultValueSize( _3_y_valueKind), defaultValueTypeInfo( _3_y_valueKind));
  End;

Function raw( _1_p_p: Pointer; _2_y_targetKind: TQ4TargetKind; _3_y_valueKind: TQ4ValueKind; _4_y_size: SizeUInt; _5_p_info: PTypeInfo): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, _2_y_targetKind, _3_y_valueKind, _4_y_size, _5_p_info);
  End;

Function elementRaw( _1_p_p: Pointer; _2_y_valueKind: TQ4ValueKind): TQ4Ref; Inline;
  Begin
    Result := elementRaw( _1_p_p, _2_y_valueKind, defaultValueSize( _2_y_valueKind), defaultValueTypeInfo( _2_y_valueKind));
  End;

Function elementRaw( _1_p_p: Pointer; _2_y_valueKind: TQ4ValueKind; _3_y_size: SizeUInt; _4_p_info: PTypeInfo): TQ4Ref; Inline;
  Begin
    Result := makeRef( _1_p_p, q4tkArrayElement, _2_y_valueKind, _3_y_size, _4_p_info);
  End;

Procedure requireAssigned( Const _1_y_r: TQ4Ref; Const _2_t_where: string);
  Begin
    If ( _1_y_r.Ptr = nil) Then Raise Exception.Create( _2_t_where + ': référence nil');
  End;

Procedure requireTarget( Const _1_y_r: TQ4Ref; _2_y_expected: TQ4TargetKind; Const _3_t_where: string);
  Begin
    requireAssigned( _1_y_r, _3_t_where);
    If ( _1_y_r.TargetKind <> _2_y_expected) Then Raise Exception.Create( _3_t_where + ': cible ' + targetKindName( _2_y_expected) + ' attendue, reçu ' + targetKindName( _1_y_r.TargetKind));
  End;

Procedure requireValue( Const _1_y_r: TQ4Ref; _2_y_expected: TQ4ValueKind; Const _3_t_where: string);
  Begin
    requireAssigned( _1_y_r, _3_t_where);
    If ( _1_y_r.ValueKind <> _2_y_expected) Then Raise Exception.Create( _3_t_where + ': type ' + valueKindName( _2_y_expected) + ' attendu, reçu ' + valueKindName( _1_y_r.ValueKind));
  End;

Procedure requireArray( Const _1_y_r: TQ4Ref; Const _2_t_where: string);
  Begin
    requireTarget( _1_y_r, q4tkArray, _2_t_where);
  End;

Procedure requireArrayValue( Const _1_y_r: TQ4Ref; _2_y_expected: TQ4ValueKind; Const _3_t_where: string);
  Begin
    requireArray( _1_y_r, _3_t_where);
    requireValue( _1_y_r, _2_y_expected, _3_t_where);
  End;

Procedure requireValueTarget( Const _1_y_r: TQ4Ref; Const _2_t_where: string);
  Begin
    requireAssigned( _1_y_r, _2_t_where);
    If ( not ( _1_y_r.TargetKind in [q4tkValue, q4tkArrayElement, q4tkField])) Then Raise Exception.Create( _2_t_where + ': valeur attendue, reçu ' + targetKindName( _1_y_r.TargetKind));
  End;

End.
