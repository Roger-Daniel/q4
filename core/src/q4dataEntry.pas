Unit q4dataEntry;

{$mode objfpc}{$H+}

{
q4dataEntry
version du 2026/04/19-18:57

Mapping 4D
Command Number 4D,    4D Command,                       q4 API,                           Statut
  ------------------------------------------------------------------------------------------------
269,                 ACCEPT,                           accept,                           TODO,
56,                  ADD RECORD,                       addRecord,                        TODO,
270,                 CANCEL,                           cancel,                           TODO,
40,                  DIALOG,                           dialog,                           TODO,
32,                  Modified,                         modified,                         OK,
57,                  MODIFY RECORD,                    modifyRecord,                     TODO,
35,                  Old,                              oldText/...,                      OK,
38,                  REJECT,                           reject,                           TODO,

Doc: https://developer.4d.com/docs/21/commands/theme/Data-Entry


  Portée actuelle :
  - old... et modified sont implémentées sur le runtime record q4.
  - La recherche d'un champ se fait par pointeur.
  - Recherche en 2 passes :
      1) records avec _ReadWrite = True
      2) fallback sur toutes les tables
  - Date/Time passent par oldText.
  - Blob/Photo passent par oldBlob (TBytes).

  Notes :
  - Cette unité suppose que les records table générés embarquent un
    runtime compatible Tq4recordRuntime en tête de record.
  - Le parcours des records de tables doit être branché sur
    l'infrastructure générée du schéma.
  ----------------------------------------------------------------------
}

Interface

Uses
  SysUtils,
  Variants,
  metier_q4DBschemaBase,
  metier_q4DBschemaProcess,
  q4DBschemaUse,
  q4structureAccess;

Type
  PBytes = ^TBytes;

Function modified( Const _1_p_field: Pointer): boolean;

Function oldVariant( Const _1_p_field: Pointer): variant;
Function oldText( Const _1_p_field: Pointer): string;
Function oldInteger( Const _1_p_field: Pointer): int64;
Function oldInt64( Const _1_p_field: Pointer): int64;
Function oldDouble( Const _1_p_field: Pointer): double;
Function oldBoolean( Const _1_p_field: Pointer): boolean;
Function oldBlob( Const _1_p_field: Pointer): TBytes;

Implementation

Uses
  q4Record,
  q4coreLanguage;

Type
  Pq4recordRuntime = ^Tq4recordRuntime;

Function runtimeOf( Var _1_p_table: Pointer): Pq4recordRuntime; Inline;
  Begin
    Result := Pq4recordRuntime( _1_p_table);
  End;

Function InternalResolveField( Const _1_p_field: Pointer; out _2_p_runtime: Pq4recordRuntime; out _3_e_index: int64): boolean;
  Var
    _e_ownerTableId: int64;
    _y_field: TFieldMeta;
    _p_table: Pointer;
  Begin
    _2_p_runtime := nil;
    _3_e_index := -1;

    If ( _1_p_field = nil) Then Exit( False);

    If ( not resolveFieldPointerGlobalReadWriteFirst( _1_p_field, _e_ownerTableId, _y_field)) Then Exit( False);

    If ( not resolveTablePointerBySourceTableId( _e_ownerTableId, _p_table)) Then Exit( False);

    _2_p_runtime := runtimeOf( _p_table);
    If ( _2_p_runtime = nil) Then Exit( False);

    _3_e_index := findLocalBindingIndex( _p_table, _1_p_field);
    Result := _3_e_index >= 0;
  End;

Function modified( Const _1_p_field: Pointer): boolean;
  Var
    _p_runtime: Pq4recordRuntime;
    idx: int64;
    _v_current, _v_old: variant;
  Begin
    If ( not InternalResolveField( _1_p_field, _p_runtime, idx)) Then Exit( False);

    _v_current := q4record.ReadBindingValue( _p_runtime^._Bindings[idx]);

    If ( ( idx < 0) or ( idx >= Length( _p_runtime^._ArraySQL))) Then Exit( False);

    _v_old := _p_runtime^._ArraySQL[idx];

    Result := not q4coreLanguage.sameValue( _v_current, _v_old);
  End;


Function InternalOldVariant( Const _1_p_field: Pointer): variant;
  Var
    _p_runtime: Pq4recordRuntime;
    idx: int64;
  Begin
    If ( not InternalResolveField( _1_p_field, _p_runtime, idx)) Then Exit( Null);

    If ( ( idx < 0) or ( idx >= Length( _p_runtime^._ArraySQL))) Then Exit( Null);

    Result := _p_runtime^._ArraySQL[idx];
  End;

Function oldVariant( Const _1_p_field: Pointer): variant;
  Var
    _p_runtime: Pq4recordRuntime;
    idx: int64;
  Begin
    If ( not InternalResolveField( _1_p_field, _p_runtime, idx)) Then Exit( Null);

    If ( ( idx < 0) or ( idx >= Length( _p_runtime^._ArraySQL))) Then Exit( Null);

  { TODO:
    Pour fkBlob, la valeur retournée est actuellement la représentation
    technique q4 (Variant array of Byte). }
    Result := _p_runtime^._ArraySQL[idx];
  End;

Function oldText( Const _1_p_field: Pointer): string;
  Var
    v: variant;
  Begin
    v := oldVariant( _1_p_field);

    If ( VarIsNull( v) or VarIsEmpty( v)) Then Exit( '');

    Result := VarToStr( v);
  End;

Function oldInteger( Const _1_p_field: Pointer): int64;
  Var
    v: variant;
  Begin
    v := oldVariant( _1_p_field);

    If ( VarIsNull( v) or VarIsEmpty( v)) Then Exit( 0);

    Result := Variants.VarAsType( v, varInteger);
  End;

Function oldInt64( Const _1_p_field: Pointer): int64;
  Var
    _v_old: variant;
  Begin
    _v_old := InternalOldVariant( _1_p_field);

    If ( VarIsNull( _v_old) or VarIsEmpty( _v_old)) Then Exit( 0);

    Result := Variants.VarAsType( _v_old, varInt64);
  End;

Function oldDouble( Const _1_p_field: Pointer): double;
  Var
    _v_old: variant;
  Begin
    _v_old := InternalOldVariant( _1_p_field);

    If ( VarIsNull( _v_old) or VarIsEmpty( _v_old)) Then Exit( 0);

    Result := Variants.VarAsType( _v_old, varDouble);
  End;

Function oldBoolean( Const _1_p_field: Pointer): boolean;
  Var
    _v_old: variant;
  Begin
    _v_old := InternalOldVariant( _1_p_field);

    If ( VarIsNull( _v_old) or VarIsEmpty( _v_old)) Then Exit( False);

    Result := Variants.VarAsType( _v_old, varBoolean);
  End;

Function oldBlob( Const _1_p_field: Pointer): TBytes;
  Var
    v: variant;
  Begin
    v := oldVariant( _1_p_field);
    Result := q4coreLanguage.VariantToBytes( v);
  End;

End.
