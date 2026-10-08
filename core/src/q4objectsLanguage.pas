Unit q4objectsLanguage;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

{
q4objectsLanguage
version du 2026/05/06-q4collections-helpers

Mapping 4D → q4objectsLanguage -> statut
Command Number 4D,    4D Command,                      q4 cible,                         Statut
------------------------------------------------------------------------------------------------
1471,                New object,                       newObject,                        OK,
1526,                New shared object,                newSharedObject,                  OK,
1472,                New collection,                   newCollection,                    OK,
1527,                New shared collection,            newSharedCollection,              OK,

1224,                OB Get,                           obGet,                            OK,
1225,                OB SET,                           obSet,                            OK,
1231,                OB Is defined,                    obIsDefined,                      OK,
1233,                OB SET NULL,                      obSetNull,                        OK,
1230,                OB Get type,                      obGetType,                        OK,
1297,                OB Is empty,                      obIsEmpty,                        OK,
1226,                OB REMOVE,                        obRemove,                         OK,
1232,                OB GET PROPERTY NAMES,            obGetPropertyNames,               OK,

1719,                OB Keys,                          *,                                Not supported,
1718,                OB Values,                        *,                                Not supported,
1720,                OB Entries,                       *,                                Not supported,

1227,                OB Copy,                          *,                                TODO,
1730,                OB Class,                         *,                                Not supported,
1731,                OB Instance of,                   *,                                Not supported,
1759,                OB Is shared,                     *,                                Not supported,
1229,                OB GET ARRAY,                     *,                                Not supported,
1228,                OB SET ARRAY,                     *,                                Not supported,

Extensions q4 :
?,                   ob,                               ob(root, 'path', line),           OK,
?,                   col,                              col(root, 'path', line),          OK,
?,                   obByName,                         obByName,                         OK,
?,                   obIsDefinedByName,                obIsDefinedByName,                OK,
?,                   obTryGetTextByName,               obTryGetTextByName,               OK,
?,                   obSetByName,                      obSetByName,                      OK,
1525,                Storage,                          storage,                          OK,

Doc: https://developer.4d.com/docs/21/commands/theme/Objects-Language

}

Interface

Uses
  SysUtils,
  Classes,
  q4interruptions;

Type
  Tq4ValueKind = (
    qvkUndefined,
    qvkNull,
    qvkBoolean,
    qvkInteger,
    qvkReal,
    qvkText,
    qvkDate,
    qvkTime,
    qvkObject,
    qvkCollection
    );

  Tq4CellSourceKind = (
    qckNone,
    qckObjectPropertyByName,
    qckObjectPath,
    qckCollectionItem
    );

  Tq4Object = Record
  private
    p_ref: Pointer;
  public
    Class Operator =( Const o1_left, o2_right: Tq4Object): boolean;
    Class Operator <>( Const o1_left, o2_right: Tq4Object): boolean;
    Function isAssigned: boolean;
  End;

  Tq4Collection = Record
  private
    p_ref: Pointer;
  public
    Class Operator =( Const c1_left, c2_right: Tq4Collection): boolean;
    Class Operator <>( Const c1_left, c2_right: Tq4Collection): boolean;
    Function isAssigned: boolean;
  End;

  Tq4Value = Record
  private
    e_kind: Tq4ValueKind;
    e_integer: int64;
    r_real: double;
    t_text: string;
    o_object: Tq4Object;
    c_collection: Tq4Collection;
  public
    Function kind: Tq4ValueKind;
    Function isDefined: boolean;
    Function isNull: boolean;

    Function AsBoolean: boolean;
    Function AsInteger: int64;
    Function asReal: double;
    Function asText: string;
    Function asDate: string;
    Function asTime: string;
    Function asObject: Tq4Object;
    Function asCollection: Tq4Collection;

    Class Operator := ( b1_value: boolean): Tq4Value;
    Class Operator := ( e1_value: int64): Tq4Value;
    Class Operator := ( r1_value: double): Tq4Value;
    Class Operator := ( Const t1_value: string): Tq4Value;
    Class Operator := ( Const o1_value: Tq4Object): Tq4Value;
    Class Operator := ( Const c1_value: Tq4Collection): Tq4Value;
  End;

  Tq4ValueArray = Array Of Tq4Value;
  Tq4StringArray = Array Of string;

  Tq4Cell = Record
  private
    e_sourceKind: Tq4CellSourceKind;
    p_ref: Pointer;
    e_index: int64;
    t_name: string;
    tt_segments: Tq4StringArray;
    t_zoneName: string;
    e_line: int64;
    t_path: string;

    Function getValue: Tq4Value;
    Procedure setValue( Const _1_y_v1_value: Tq4Value);
  public
    Function isDefined: boolean;
    Function isNull: boolean;

    Function AsBoolean: boolean;
    Function AsInteger: int64;
    Function asReal: double;
    Function asText: string;
    Function asDate: string;
    Function asTime: string;
    Function asObject: Tq4Object;
    Function asCollection: Tq4Collection;

    Procedure setNull;
    Procedure setUndefined;

    Property Value: Tq4Value read getValue write setValue;
  End;

  Tq4ColCell = Record
  private
    p_ref: Pointer;
    t_zoneName: string;
    Function getItem( _1_e_e1_index: int64): Tq4Cell;
  public
    Function length: int64;
    Procedure push( Const _1_y_v1_value: Tq4Value);

    Property values[e1_index: int64]: Tq4Cell read getItem; default;
  End;

Function q4Null: Tq4Value;
Function q4Undefined: Tq4Value;
Function q4DateValue( Const _1_d_value: string): Tq4Value;
Function q4TimeValue( Const _1_h_value: string): Tq4Value;

Function newObject: Tq4Object;
Function newSharedObject: Tq4Object;

Function newCollection: Tq4Collection;
Function newSharedCollection: Tq4Collection;

Function ob( Const _1_o_o1_root: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64): Tq4Cell;

Function col( Const _1_o_o1_root: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64): Tq4ColCell; overload;
Function col( Const _1_y_c1_root: Tq4Collection): Tq4ColCell; overload;

{ Helpers publics utilisés par q4collections.
  Les collections 4D/q4 sont indexées à partir de 0. }
Procedure collectionClear( Var _1_c_collection: Tq4Collection);
Procedure collectionSetLength( Var _1_c_collection: Tq4Collection; _2_e_length: int64);
Function collectionItem( Const _1_c_collection: Tq4Collection; _2_e_index: int64): Tq4Value;
Procedure collectionSetItem( Var _1_c_collection: Tq4Collection; _2_e_index: int64; Const _3_v_value: Tq4Value);
Function collectionEnsureObjectAt( Var _1_c_collection: Tq4Collection; _2_e_index: int64): Tq4Object;
Procedure collectionSetObjectPropertyAt( Var _1_c_collection: Tq4Collection; _2_e_index: int64; Const _3_t_propertyName: string; Const _4_v_value: Tq4Value);
Function collectionGetObjectPropertyAt( Const _1_c_collection: Tq4Collection; _2_e_index: int64; Const _3_t_propertyName: string): Tq4Value;

Function storage: Tq4Object;

Function obByName( Const _1_o_o1_root: Tq4Object; Const _2_t_t2_name: string): Tq4Cell;
Function obIsDefinedByName( Const _1_o_o1_root: Tq4Object; Const _2_t_t2_name: string): boolean;
Function obTryGetTextByName( Const _1_o_o1_root: Tq4Object; Const _2_t_t2_name: string; Const _3_t_t3_default: string): string;
Procedure obSetByName( Var _1_o_o1_root: Tq4Object; Const _2_t_t2_name: string; Const _3_y_v3_value: Tq4Value);

Function obGet( Const _1_o_o1_object: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64): Tq4Value;
Procedure obSet( Var _1_o_o1_object: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64; Const _4_y_v4_value: Tq4Value);
Function obIsDefined( Const _1_o_o1_object: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64): boolean;
Procedure obSetNull( Var _1_o_o1_object: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64);
Function obGetType( Const _1_o_o1_object: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64): Tq4ValueKind;
Function obIsEmpty( Const _1_o_o1_object: Tq4Object): boolean;
Procedure obRemove( Var _1_o_o1_object: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64);
Function obGetPropertyNames( Const _1_o_o1_object: Tq4Object): Tq4Collection;

Implementation

Const
  DYNAMIC_PATH_CACHE_SIZE = 256;

Type
  Pq4ObjectData = ^Tq4ObjectData;

  Tq4ObjectData = Record
    c_names: TStringList;
    tv_values: Tq4ValueArray;
  End;

  Tq4ZoneLock = Record
    t_zoneName: string;
    y_lock: TRTLCriticalSection;
    b_initialized: boolean;
  End;

  Tq4PathCacheEntry = Record
    b_valid: boolean;
    e_line: int64;
    t_path: string;
    tt_segments: Tq4StringArray;
  End;

Var
  go_storageRoot: Tq4Object;
  ge_nextHandleId: PtrUInt = 0;
  gv_collectionValues: Array Of Tq4ValueArray;
  gv_objectData:  Array Of Pq4ObjectData;
  gy_zoneLocks:   Array Of Tq4ZoneLock;
  gy_pathCache:   Array[0..DYNAMIC_PATH_CACHE_SIZE - 1] Of Tq4PathCacheEntry;
  gy_zoneMapLock: TRTLCriticalSection;
  gb_zoneMapLockInitialized: boolean = False;

Function nextHandlePointer: Pointer;
  Begin
    Inc( ge_nextHandleId);
    Result := Pointer( ge_nextHandleId);
  End;

Function objectIdFromHandle( Const _1_o_o1_object: Tq4Object): int64;
  Begin
    Result := PtrUInt( _1_o_o1_object.p_ref);
  End;

Function collectionIdFromHandle( Const _1_y_c1_collection: Tq4Collection): int64;
  Begin
    Result := PtrUInt( _1_y_c1_collection.p_ref);
  End;

Procedure ensureObjectIndex( _1_e_e1_id: int64);
  Begin
    If ( _1_e_e1_id >= System.Length( gv_objectData)) Then System.SetLength( gv_objectData, _1_e_e1_id + 1);
  End;

Procedure ensureCollectionIndex( _1_e_e1_id: int64);
  Begin
    If ( _1_e_e1_id >= System.Length( gv_collectionValues)) Then System.SetLength( gv_collectionValues, _1_e_e1_id + 1);
  End;

Procedure initObjectData( _1_e_e1_id: int64);
  Begin
    If ( gv_objectData[_1_e_e1_id] <> nil) Then Exit;

    New( gv_objectData[_1_e_e1_id]);
    gv_objectData[_1_e_e1_id]^.c_names := TStringList.Create;
    gv_objectData[_1_e_e1_id]^.c_names.CaseSensitive := True;//afin de conserver la compatibilité JSON
    gv_objectData[_1_e_e1_id]^.c_names.Sorted := False;
    System.SetLength( gv_objectData[_1_e_e1_id]^.tv_values, 0);
  End;

Function findObjectPropertyIndex( _1_data: Pq4ObjectData; Const _2_t_t2_name: string): int64;
  Begin
    If ( _1_data = nil) Then Exit( -1);

    Result := _1_data^.c_names.IndexOf( _2_t_t2_name);
  End;

Function getObjectPropertyValue( _1_ref: Pointer; Const _2_t_t2_name: string): Tq4Value;
  Var
    _e_id:    int64;
    _e_index: int64;
    _p_data:  Pq4ObjectData;
  Begin
    Result := q4objectsLanguage.q4Undefined;

    If ( _1_ref = nil) Then Exit;

    _e_id := PtrUInt( _1_ref);
    If ( _e_id >= System.Length( gv_objectData)) Then Exit;

    _p_data := gv_objectData[_e_id];
    If ( _p_data = nil) Then Exit;

    _e_index := findObjectPropertyIndex( _p_data, _2_t_t2_name);
    If ( _e_index < 0) Then Exit;

    Result := _p_data^.tv_values[_e_index];
  End;

Procedure setObjectPropertyValue( _1_ref: Pointer; Const _2_t_t2_name: string; Const _3_y_v3_value: Tq4Value);
  Var
    _e_id:    int64;
    _e_index: int64;
    _p_data:  Pq4ObjectData;
  Begin
    If ( _1_ref = nil) Then Exit;

    _e_id := PtrUInt( _1_ref);
    ensureObjectIndex( _e_id);
    initObjectData( _e_id);
    _p_data := gv_objectData[_e_id];

    _e_index := findObjectPropertyIndex( _p_data, _2_t_t2_name);
    If ( _e_index < 0) Then Begin
      _p_data^.c_names.Add( _2_t_t2_name);
      _e_index := System.Length( _p_data^.tv_values);
      System.SetLength( _p_data^.tv_values, _e_index + 1);
    End;

    _p_data^.tv_values[_e_index] := _3_y_v3_value;
  End;

Procedure removeObjectPropertyValue( _1_ref: Pointer; Const _2_t_t2_name: string);
  Var
    _e_id:    int64;
    _e_index: int64;
    _e_i:     int64;
    _p_data:  Pq4ObjectData;
  Begin
    If ( _1_ref = nil) Then Exit;

    _e_id := PtrUInt( _1_ref);
    If ( _e_id >= System.Length( gv_objectData)) Then Exit;

    _p_data := gv_objectData[_e_id];
    If ( _p_data = nil) Then Exit;

    _e_index := findObjectPropertyIndex( _p_data, _2_t_t2_name);
    If ( _e_index < 0) Then Exit;

    _p_data^.c_names.Delete( _e_index);
    For _e_i := _e_index To System.Length( _p_data^.tv_values) - 2 Do _p_data^.tv_values[_e_i] := _p_data^.tv_values[_e_i + 1];
    System.SetLength( _p_data^.tv_values, System.Length( _p_data^.tv_values) - 1);
  End;

Function buildPropertyNamesCollection( Const _1_o_o1_object: Tq4Object): Tq4Collection;
  Var
    _e_id:   int64;
    _e_i:    int64;
    _p_data: Pq4ObjectData;
  Begin
    Result := q4objectsLanguage.newCollection;

    If ( not _1_o_o1_object.isAssigned) Then Exit;

    _e_id := objectIdFromHandle( _1_o_o1_object);
    If ( _e_id >= System.Length( gv_objectData)) Then Exit;

    _p_data := gv_objectData[_e_id];
    If ( _p_data = nil) Then Exit;

    For _e_i := 0 To _p_data^.c_names.Count - 1 Do col( Result).push( _p_data^.c_names[_e_i]);
  End;

Function splitDynamicPath( Const _1_t_t1_path: string): Tq4StringArray;
  Var
    _e_i:     int64;
    _e_start: int64;
    _e_count: int64;
    _t_part:  string;
  Begin
    System.SetLength( Result, 0);

    If ( _1_t_t1_path = '') Then Exit;

    _e_start := 1;
    _e_count := 0;
    For _e_i := 1 To System.Length( _1_t_t1_path) + 1 Do If ( ( _e_i > System.Length( _1_t_t1_path)) or ( _1_t_t1_path[_e_i] = '.')) Then Begin
        _t_part := System.Copy( _1_t_t1_path, _e_start, _e_i - _e_start);
        If ( _t_part <> '') Then Begin
          System.SetLength( Result, _e_count + 1);
          Result[_e_count] := _t_part;
          Inc( _e_count);
        End;
        _e_start := _e_i + 1;
      End;
  End;

Function cachedPathSegments( _1_e_e1_line: int64; Const _2_t_t2_path: string): Tq4StringArray;
  Var
    _e_slot: int64;
  Begin
    _e_slot := Abs( _1_e_e1_line) mod DYNAMIC_PATH_CACHE_SIZE;

    If ( gy_pathCache[_e_slot].b_valid and ( gy_pathCache[_e_slot].e_line = _1_e_e1_line) and ( gy_pathCache[_e_slot].t_path = _2_t_t2_path)) Then Exit( gy_pathCache[_e_slot].tt_segments);

    Result := splitDynamicPath( _2_t_t2_path);

    gy_pathCache[_e_slot].b_valid := True;
    gy_pathCache[_e_slot].e_line := _1_e_e1_line;
    gy_pathCache[_e_slot].t_path := _2_t_t2_path;
    gy_pathCache[_e_slot].tt_segments := Result;
  End;

Function zoneNameForPath( Const _1_o_o1_root: Tq4Object; Const _2_y_tt2_segments: Tq4StringArray): string;
  Begin
    If ( ( _1_o_o1_root = go_storageRoot) and ( System.Length( _2_y_tt2_segments) > 0)) Then Exit( _2_y_tt2_segments[0]);

    Result := '';
  End;

Function findZoneLockIndex( Const _1_t_t1_zoneName: string): int64;
  Var
    _e_i: int64;
  Begin
    For _e_i := 0 To System.Length( gy_zoneLocks) - 1 Do If ( SameText( gy_zoneLocks[_e_i].t_zoneName, _1_t_t1_zoneName)) Then Exit( _e_i);

    Result := -1;
  End;

Function ensureZoneLock( Const _1_t_t1_zoneName: string): int64;
  Var
    _e_index: int64;
  Begin
    If ( _1_t_t1_zoneName = '') Then Exit( -1);

    If ( gb_zoneMapLockInitialized) Then EnterCriticalSection( gy_zoneMapLock);
    Try
      _e_index := findZoneLockIndex( _1_t_t1_zoneName);
      If ( _e_index >= 0) Then Exit( _e_index);

      _e_index := System.Length( gy_zoneLocks);
      System.SetLength( gy_zoneLocks, _e_index + 1);

      gy_zoneLocks[_e_index].t_zoneName := _1_t_t1_zoneName;
      InitCriticalSection( gy_zoneLocks[_e_index].y_lock);
      gy_zoneLocks[_e_index].b_initialized := True;
      Result := _e_index;
    Finally
      If ( gb_zoneMapLockInitialized) Then LeaveCriticalSection( gy_zoneMapLock);
    End;
  End;

Procedure lockZoneIfNeeded( Const _1_t_t1_zoneName: string);
  Var
    _e_index: int64;
  Begin
    _e_index := ensureZoneLock( _1_t_t1_zoneName);
    If ( _e_index >= 0) Then EnterCriticalSection( gy_zoneLocks[_e_index].y_lock);
  End;

Procedure unlockZoneIfNeeded( Const _1_t_t1_zoneName: string);
  Var
    _e_index: int64;
  Begin
    _e_index := findZoneLockIndex( _1_t_t1_zoneName);
    If ( _e_index >= 0) Then LeaveCriticalSection( gy_zoneLocks[_e_index].y_lock);
  End;

Function resolvePathValueFromObject( _1_root: Pointer; Const _2_y_tt2_segments: Tq4StringArray): Tq4Value;
  Var
    _e_i:     int64;
    _y_value: Tq4Value;
    _o_current: Tq4Object;
  Begin
    Result := q4objectsLanguage.q4Undefined;

    If ( _1_root = nil) Then Exit;
    If ( System.Length( _2_y_tt2_segments) = 0) Then Exit;

    _o_current := Default( Tq4Object);
    _o_current.p_ref := _1_root;

    For _e_i := 0 To System.Length( _2_y_tt2_segments) - 1 Do Begin
      _y_value := getObjectPropertyValue( _o_current.p_ref, _2_y_tt2_segments[_e_i]);

      If ( _e_i = System.Length( _2_y_tt2_segments) - 1) Then Exit( _y_value);

      If ( ( not _y_value.isDefined) or _y_value.isNull or ( _y_value.kind <> qvkObject)) Then Exit( q4objectsLanguage.q4Undefined);

      _o_current := _y_value.asObject;
    End;
  End;

Procedure setPathValueOnObject( _1_root: Pointer; Const _2_y_tt2_segments: Tq4StringArray; Const _3_t_t3_path: string; _4_e_e4_line: int64; Const _5_y_v5_value: Tq4Value);
  Var
    _e_i:     int64;
    _y_value: Tq4Value;
    _o_current: Tq4Object;
    _o_next:  Tq4Object;
  Begin
    If ( _1_root = nil) Then Exit;
    If ( System.Length( _2_y_tt2_segments) = 0) Then Exit;

    _o_current := Default( Tq4Object);
    _o_current.p_ref := _1_root;

    For _e_i := 0 To System.Length( _2_y_tt2_segments) - 2 Do Begin
      _y_value := getObjectPropertyValue( _o_current.p_ref, _2_y_tt2_segments[_e_i]);

      If ( ( not _y_value.isDefined) or _y_value.isNull) Then Begin
        _o_next := q4objectsLanguage.newObject;
        setObjectPropertyValue( _o_current.p_ref, _2_y_tt2_segments[_e_i], _o_next);
        _o_current := _o_next;
        Continue;
      End;

      If ( _y_value.kind <> qvkObject) Then Begin
        q4interruptions.assertRaise(
          'Object path assignment conflict on "' + _3_t_t3_path + '" at segment "' + _2_y_tt2_segments[_e_i] + '": existing value is not an object',
          {$I %CURRENTROUTINE%},
          _4_e_e4_line
          );
        Exit;
      End;

      _o_current := _y_value.asObject;
    End;

    setObjectPropertyValue( _o_current.p_ref, _2_y_tt2_segments[System.Length( _2_y_tt2_segments) - 1], _5_y_v5_value);
  End;

Procedure removePathValueFromObject( _1_root: Pointer; Const _2_y_tt2_segments: Tq4StringArray);
  Var
    _e_i:     int64;
    _y_value: Tq4Value;
    _o_current: Tq4Object;
  Begin
    If ( _1_root = nil) Then Exit;
    If ( System.Length( _2_y_tt2_segments) = 0) Then Exit;

    _o_current := Default( Tq4Object);
    _o_current.p_ref := _1_root;

    For _e_i := 0 To System.Length( _2_y_tt2_segments) - 2 Do Begin
      _y_value := getObjectPropertyValue( _o_current.p_ref, _2_y_tt2_segments[_e_i]);

      If ( ( not _y_value.isDefined) or _y_value.isNull or ( _y_value.kind <> qvkObject)) Then Exit;

      _o_current := _y_value.asObject;
    End;

    removeObjectPropertyValue( _o_current.p_ref, _2_y_tt2_segments[System.Length( _2_y_tt2_segments) - 1]);
  End;

Class Operator Tq4Object.=( Const o1_left, o2_right: Tq4Object): boolean;
  Begin
    Result := o1_left.p_ref = o2_right.p_ref;
  End;

Class Operator Tq4Object.<>( Const o1_left, o2_right: Tq4Object): boolean;
  Begin
    Result := o1_left.p_ref <> o2_right.p_ref;
  End;

Function Tq4Object.isAssigned: boolean;
  Begin
    Result := p_ref <> nil;
  End;

Class Operator Tq4Collection.=( Const c1_left, c2_right: Tq4Collection): boolean;
  Begin
    Result := c1_left.p_ref = c2_right.p_ref;
  End;

Class Operator Tq4Collection.<>( Const c1_left, c2_right: Tq4Collection): boolean;
  Begin
    Result := c1_left.p_ref <> c2_right.p_ref;
  End;

Function Tq4Collection.isAssigned: boolean;
  Begin
    Result := p_ref <> nil;
  End;

Function Tq4Value.kind: Tq4ValueKind;
  Begin
    Result := e_kind;
  End;

Function Tq4Value.isDefined: boolean;
  Begin
    Result := e_kind <> qvkUndefined;
  End;

Function Tq4Value.isNull: boolean;
  Begin
    Result := e_kind = qvkNull;
  End;

Function Tq4Value.AsBoolean: boolean;
  Begin
    Case e_kind Of
      qvkBoolean: Result := e_integer <> 0;
      qvkInteger: Result := e_integer <> 0;
      Else Result := False;
    End;
  End;

Function Tq4Value.AsInteger: int64;
  Begin
    Case e_kind Of
      qvkBoolean,
      qvkInteger: Result := e_integer;
      Else Result := 0;
    End;
  End;

Function Tq4Value.asReal: double;
  Begin
    Case e_kind Of
      qvkReal: Result := r_real;
      qvkInteger: Result := e_integer;
      Else Result := 0.0;
    End;
  End;

Function Tq4Value.asText: string;
  Begin
    Case e_kind Of
      qvkText,
      qvkDate,
      qvkTime: Result := t_text;
      Else Result := '';
    End;
  End;

Function Tq4Value.asDate: string;
  Begin
    If ( e_kind = qvkDate) Then Exit( t_text);
    Result := '';
  End;

Function Tq4Value.asTime: string;
  Begin
    If ( e_kind = qvkTime) Then Exit( t_text);
    Result := '';
  End;

Function Tq4Value.asObject: Tq4Object;
  Begin
    If ( e_kind = qvkObject) Then Exit( o_object);
    Result := Default( Tq4Object);
  End;

Function Tq4Value.asCollection: Tq4Collection;
  Begin
    If ( e_kind = qvkCollection) Then Exit( c_collection);
    Result := Default( Tq4Collection);
  End;

Class Operator Tq4Value.:=( b1_value: boolean): Tq4Value;
  Begin
    Result := Default( Tq4Value);
    Result.e_kind := qvkBoolean;
    Result.e_integer := Ord( b1_value);
  End;

Class Operator Tq4Value.:=( e1_value: int64): Tq4Value;
  Begin
    Result := Default( Tq4Value);
    Result.e_kind := qvkInteger;
    Result.e_integer := e1_value;
  End;

Class Operator Tq4Value.:=( r1_value: double): Tq4Value;
  Begin
    Result := Default( Tq4Value);
    Result.e_kind := qvkReal;
    Result.r_real := r1_value;
  End;

Class Operator Tq4Value.:=( Const t1_value: string): Tq4Value;
  Begin
    Result := Default( Tq4Value);
    Result.e_kind := qvkText;
    Result.t_text := t1_value;
  End;

Class Operator Tq4Value.:=( Const o1_value: Tq4Object): Tq4Value;
  Begin
    Result := Default( Tq4Value);
    Result.e_kind := qvkObject;
    Result.o_object := o1_value;
  End;

Class Operator Tq4Value.:=( Const c1_value: Tq4Collection): Tq4Value;
  Begin
    Result := Default( Tq4Value);
    Result.e_kind := qvkCollection;
    Result.c_collection := c1_value;
  End;

Function Tq4Cell.getValue: Tq4Value;
  Var
    _e_id: int64;
  Begin
    Result := q4objectsLanguage.q4Undefined;

    Case e_sourceKind Of
      qckObjectPropertyByName: Result := getObjectPropertyValue( p_ref, t_name);

      qckObjectPath: Begin
        lockZoneIfNeeded( t_zoneName);
        Try
          Result := resolvePathValueFromObject( p_ref, tt_segments);
        Finally
          unlockZoneIfNeeded( t_zoneName);
        End;
      End;

      qckCollectionItem: Begin
        If ( p_ref = nil) Then Exit;

        lockZoneIfNeeded( t_zoneName);
        Try
          _e_id := PtrUInt( p_ref);
          If ( ( _e_id < System.Length( gv_collectionValues)) and ( e_index >= 0) and ( e_index < System.Length( gv_collectionValues[_e_id]))) Then Result := gv_collectionValues[_e_id][e_index];
        Finally
          unlockZoneIfNeeded( t_zoneName);
        End;
      End;
    End;
  End;

Procedure Tq4Cell.setValue( Const _1_y_v1_value: Tq4Value);
  Var
    _e_id: int64;
  Begin
    Case e_sourceKind Of
      qckObjectPropertyByName: setObjectPropertyValue( p_ref, t_name, _1_y_v1_value);

      qckObjectPath: Begin
        lockZoneIfNeeded( t_zoneName);
        Try
          setPathValueOnObject(
            p_ref,
            tt_segments,
            t_path,
            e_line,
            _1_y_v1_value);
        Finally
          unlockZoneIfNeeded( t_zoneName);
        End;
      End;

      qckCollectionItem: Begin
        If ( p_ref = nil) Then Exit;

        lockZoneIfNeeded( t_zoneName);
        Try
          _e_id := PtrUInt( p_ref);
          ensureCollectionIndex( _e_id);
          If ( ( e_index >= 0) and ( e_index < System.Length( gv_collectionValues[_e_id]))) Then gv_collectionValues[_e_id][e_index] := _1_y_v1_value;
        Finally
          unlockZoneIfNeeded( t_zoneName);
        End;
      End;
    End;
  End;

Function Tq4Cell.isDefined: boolean;
  Begin
    Result := getValue.isDefined;
  End;

Function Tq4Cell.isNull: boolean;
  Begin
    Result := getValue.isNull;
  End;

Function Tq4Cell.AsBoolean: boolean;
  Begin
    Result := getValue.AsBoolean;
  End;

Function Tq4Cell.AsInteger: int64;
  Begin
    Result := getValue.AsInteger;
  End;

Function Tq4Cell.asReal: double;
  Begin
    Result := getValue.asReal;
  End;

Function Tq4Cell.asText: string;
  Begin
    Result := getValue.asText;
  End;

Function Tq4Cell.asDate: string;
  Begin
    Result := getValue.asDate;
  End;

Function Tq4Cell.asTime: string;
  Begin
    Result := getValue.asTime;
  End;

Function Tq4Cell.asObject: Tq4Object;
  Begin
    Result := getValue.asObject;
  End;

Function Tq4Cell.asCollection: Tq4Collection;
  Begin
    Result := getValue.asCollection;
  End;

Procedure Tq4Cell.setNull;
  Begin
    setValue( q4objectsLanguage.q4Null);
  End;

Procedure Tq4Cell.setUndefined;
  Begin
    setValue( q4objectsLanguage.q4Undefined);
  End;

Function Tq4ColCell.getItem( _1_e_e1_index: int64): Tq4Cell;
  Begin
    Result := Default( Tq4Cell);

    If ( p_ref = nil) Then Exit;

    Result.e_sourceKind := qckCollectionItem;
    Result.p_ref := p_ref;
    Result.e_index := _1_e_e1_index;
    Result.t_zoneName := t_zoneName;
  End;

Function Tq4ColCell.length: int64;
  Var
    _e_id: int64;
  Begin
    If ( p_ref = nil) Then Exit( 0);

    lockZoneIfNeeded( t_zoneName);
    Try
      _e_id := PtrUInt( p_ref);
      If ( _e_id < System.Length( gv_collectionValues)) Then Exit( System.Length( gv_collectionValues[_e_id]));
      Result := 0;
    Finally
      unlockZoneIfNeeded( t_zoneName);
    End;
  End;

Procedure Tq4ColCell.push( Const _1_y_v1_value: Tq4Value);
  Var
    _e_id:  int64;
    _e_len: int64;
  Begin
    If ( p_ref = nil) Then Exit;

    lockZoneIfNeeded( t_zoneName);
    Try
      _e_id := PtrUInt( p_ref);
      ensureCollectionIndex( _e_id);
      _e_len := System.Length( gv_collectionValues[_e_id]);
      System.SetLength( gv_collectionValues[_e_id], _e_len + 1);
      gv_collectionValues[_e_id][_e_len] := _1_y_v1_value;
    Finally
      unlockZoneIfNeeded( t_zoneName);
    End;
  End;

Function q4Null: Tq4Value;
  Begin
    Result := Default( Tq4Value);
    Result.e_kind := qvkNull;
  End;

Function q4Undefined: Tq4Value;
  Begin
    Result := Default( Tq4Value);
    Result.e_kind := qvkUndefined;
  End;

Function q4DateValue( Const _1_d_value: string): Tq4Value;
  Begin
    Result := Default( Tq4Value);
    Result.e_kind := qvkDate;
    Result.t_text := _1_d_value;
  End;

Function q4TimeValue( Const _1_h_value: string): Tq4Value;
  Begin
    Result := Default( Tq4Value);
    Result.e_kind := qvkTime;
    Result.t_text := _1_h_value;
  End;

Function newObject: Tq4Object;
  Var
    _e_id: int64;
  Begin
    Result := Default( Tq4Object);
    Result.p_ref := nextHandlePointer;

    _e_id := objectIdFromHandle( Result);
    ensureObjectIndex( _e_id);
    initObjectData( _e_id);
  End;

Function newSharedObject: Tq4Object;
  Begin
    Result := q4objectsLanguage.newObject;
  End;

Function newCollection: Tq4Collection;
  Var
    _e_id: int64;
  Begin
    Result := Default( Tq4Collection);
    Result.p_ref := nextHandlePointer;

    _e_id := collectionIdFromHandle( Result);
    ensureCollectionIndex( _e_id);
    System.SetLength( gv_collectionValues[_e_id], 0);
  End;

Function newSharedCollection: Tq4Collection;
  Begin
    Result := q4objectsLanguage.newCollection;
  End;

Function ob( Const _1_o_o1_root: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64): Tq4Cell;
  Begin
    Result := Default( Tq4Cell);

    If ( not _1_o_o1_root.isAssigned) Then Exit;

    Result.e_sourceKind := qckObjectPath;
    Result.p_ref := _1_o_o1_root.p_ref;
    Result.e_index := -1;
    Result.tt_segments := cachedPathSegments( _3_e_e3_line, _2_t_t2_path);
    Result.t_zoneName := zoneNameForPath( _1_o_o1_root, Result.tt_segments);
    Result.e_line := _3_e_e3_line;
    Result.t_path := _2_t_t2_path;
  End;

Function col( Const _1_o_o1_root: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64): Tq4ColCell;
  Var
    _c_value:     Tq4Collection;
    _tt_segments: Tq4StringArray;
  Begin
    Result := Default( Tq4ColCell);

    _c_value := q4objectsLanguage.ob( _1_o_o1_root, _2_t_t2_path, _3_e_e3_line).asCollection;
    Result.p_ref := _c_value.p_ref;

    _tt_segments := cachedPathSegments( _3_e_e3_line, _2_t_t2_path);
    Result.t_zoneName := zoneNameForPath( _1_o_o1_root, _tt_segments);
  End;

Function col( Const _1_y_c1_root: Tq4Collection): Tq4ColCell;
  Begin
    Result := Default( Tq4ColCell);
    Result.p_ref := _1_y_c1_root.p_ref;
    Result.t_zoneName := '';
  End;

Procedure collectionClear( Var _1_c_collection: Tq4Collection);
  Var
    _e_id: int64;
  Begin
    If ( not _1_c_collection.isAssigned) Then Begin
      _1_c_collection := q4objectsLanguage.newCollection;
      Exit;
    End;

    _e_id := collectionIdFromHandle( _1_c_collection);
    ensureCollectionIndex( _e_id);
    System.SetLength( gv_collectionValues[_e_id], 0);
  End;

Procedure collectionSetLength( Var _1_c_collection: Tq4Collection; _2_e_length: int64);
  Var
    _e_id: int64;
  Begin
    If ( _2_e_length < 0) Then Begin
      q4interruptions.assertRaise(
        'collectionSetLength: collection length cannot be negative.',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
      Exit;
    End;

    If ( not _1_c_collection.isAssigned) Then _1_c_collection := q4objectsLanguage.newCollection;

    _e_id := collectionIdFromHandle( _1_c_collection);
    ensureCollectionIndex( _e_id);
    System.SetLength( gv_collectionValues[_e_id], _2_e_length);
  End;

Function collectionItem( Const _1_c_collection: Tq4Collection; _2_e_index: int64): Tq4Value;
  Begin
    // q4 : les collections 4D sont indexées à partir de 0.
    // Cette fonction retourne Undefined si l'index est hors limites.
    Result := q4objectsLanguage.col( _1_c_collection)[_2_e_index].Value;
  End;

Procedure collectionSetItem( Var _1_c_collection: Tq4Collection; _2_e_index: int64; Const _3_v_value: Tq4Value);
  Begin
    // q4 : les collections 4D sont indexées à partir de 0.
    // Si l'index dépasse la longueur courante, la collection est étendue avec
    // des valeurs Undefined jusqu'à cet index.
    If ( _2_e_index < 0) Then Begin
      q4interruptions.assertRaise(
        'collectionSetItem: collection index cannot be negative.',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
      Exit;
    End;

    If ( q4objectsLanguage.col( _1_c_collection).length <= _2_e_index) Then q4objectsLanguage.collectionSetLength( _1_c_collection, _2_e_index + 1);

    q4objectsLanguage.col( _1_c_collection)[_2_e_index].Value := _3_v_value;
  End;

Function collectionEnsureObjectAt( Var _1_c_collection: Tq4Collection; _2_e_index: int64): Tq4Object;
  Var
    _v_value: Tq4Value;
  Begin
    Result := Default( Tq4Object);

    If ( _2_e_index < 0) Then Begin
      q4interruptions.assertRaise(
        'collectionEnsureObjectAt: collection index cannot be negative.',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
      Exit;
    End;

    If ( q4objectsLanguage.col( _1_c_collection).length <= _2_e_index) Then q4objectsLanguage.collectionSetLength( _1_c_collection, _2_e_index + 1);

    _v_value := q4objectsLanguage.collectionItem( _1_c_collection, _2_e_index);

    If ( _v_value.kind = qvkObject) Then Exit( _v_value.asObject);

    If ( _v_value.isDefined and ( not _v_value.isNull)) Then Begin
      q4interruptions.assertRaise(
        'collectionEnsureObjectAt: existing collection item is not an object.',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
      Exit;
    End;

    Result := q4objectsLanguage.newObject;
    q4objectsLanguage.collectionSetItem( _1_c_collection, _2_e_index, Result);
  End;

Procedure collectionSetObjectPropertyAt( Var _1_c_collection: Tq4Collection; _2_e_index: int64; Const _3_t_propertyName: string; Const _4_v_value: Tq4Value);
  Var
    _o_item: Tq4Object;
  Begin
    // Helper prévu pour q4collections.ARRAY TO COLLECTION avec propertyName.
    // Si l'objet n'existe pas à cet index, il est créé.
    _o_item := q4objectsLanguage.collectionEnsureObjectAt( _1_c_collection, _2_e_index);
    If ( not _o_item.isAssigned) Then Exit;
    q4objectsLanguage.obSetByName( _o_item, _3_t_propertyName, _4_v_value);
  End;

Function collectionGetObjectPropertyAt( Const _1_c_collection: Tq4Collection; _2_e_index: int64; Const _3_t_propertyName: string): Tq4Value;
  Var
    _v_item: Tq4Value;
  Begin
    // Helper prévu pour q4collections.COLLECTION TO ARRAY avec propertyName.
    // Si l'élément n'existe pas, n'est pas un objet, ou si la propriété est
    // absente, la valeur Undefined est retournée.
    _v_item := q4objectsLanguage.collectionItem( _1_c_collection, _2_e_index);
    If ( _v_item.kind <> qvkObject) Then Exit( q4objectsLanguage.q4Undefined);
    Result := q4objectsLanguage.obByName( _v_item.asObject, _3_t_propertyName).Value;
  End;

Function storage: Tq4Object;
  Begin
    Result := go_storageRoot;
  End;

Function obByName( Const _1_o_o1_root: Tq4Object; Const _2_t_t2_name: string): Tq4Cell;
  Begin
    Result := Default( Tq4Cell);

    If ( not _1_o_o1_root.isAssigned) Then Exit;

    Result.e_sourceKind := qckObjectPropertyByName;
    Result.p_ref := _1_o_o1_root.p_ref;
    Result.e_index := -1;
    Result.t_name := _2_t_t2_name;
  End;

Function obIsDefinedByName( Const _1_o_o1_root: Tq4Object; Const _2_t_t2_name: string): boolean;
  Begin
    Result := q4objectsLanguage.obByName( _1_o_o1_root, _2_t_t2_name).isDefined;
  End;

Function obTryGetTextByName( Const _1_o_o1_root: Tq4Object; Const _2_t_t2_name: string; Const _3_t_t3_default: string): string;
  Var
    _y_value: Tq4Value;
  Begin
    _y_value := q4objectsLanguage.obByName( _1_o_o1_root, _2_t_t2_name).Value;
    If ( ( not _y_value.isDefined) or _y_value.isNull) Then Exit( _3_t_t3_default);
    Result := _y_value.asText;
  End;

Procedure obSetByName( Var _1_o_o1_root: Tq4Object; Const _2_t_t2_name: string; Const _3_y_v3_value: Tq4Value);
  Begin
    q4objectsLanguage.obByName( _1_o_o1_root, _2_t_t2_name).Value := _3_y_v3_value;
  End;

Function obGet( Const _1_o_o1_object: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64): Tq4Value;
  Begin
    Result := q4objectsLanguage.ob( _1_o_o1_object, _2_t_t2_path, _3_e_e3_line).Value;
  End;

Procedure obSet( Var _1_o_o1_object: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64; Const _4_y_v4_value: Tq4Value);
  Begin
    q4objectsLanguage.ob( _1_o_o1_object, _2_t_t2_path, _3_e_e3_line).Value := _4_y_v4_value;
  End;

Function obIsDefined( Const _1_o_o1_object: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64): boolean;
  Begin
    Result := q4objectsLanguage.ob( _1_o_o1_object, _2_t_t2_path, _3_e_e3_line).isDefined;
  End;

Procedure obSetNull( Var _1_o_o1_object: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64);
  Begin
    q4objectsLanguage.ob( _1_o_o1_object, _2_t_t2_path, _3_e_e3_line).setNull;
  End;

Function obGetType( Const _1_o_o1_object: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64): Tq4ValueKind;
  Begin
    Result := q4objectsLanguage.obGet( _1_o_o1_object, _2_t_t2_path, _3_e_e3_line).kind;
  End;

Function obIsEmpty( Const _1_o_o1_object: Tq4Object): boolean;
  Var
    _e_id:   int64;
    _p_data: Pq4ObjectData;
  Begin
    If ( not _1_o_o1_object.isAssigned) Then Exit( True);

    _e_id := objectIdFromHandle( _1_o_o1_object);
    If ( _e_id >= System.Length( gv_objectData)) Then Exit( True);

    _p_data := gv_objectData[_e_id];
    If ( _p_data = nil) Then Exit( True);

    Result := _p_data^.c_names.Count = 0;
  End;

Procedure obRemove( Var _1_o_o1_object: Tq4Object; Const _2_t_t2_path: string; _3_e_e3_line: int64);
  Var
    _tt_segments: Tq4StringArray;
    _t_zoneName:  string;
  Begin
    _tt_segments := cachedPathSegments( _3_e_e3_line, _2_t_t2_path);
    _t_zoneName := zoneNameForPath( _1_o_o1_object, _tt_segments);

    lockZoneIfNeeded( _t_zoneName);
    Try
      removePathValueFromObject( _1_o_o1_object.p_ref, _tt_segments);
    Finally
      unlockZoneIfNeeded( _t_zoneName);
    End;
  End;

Function obGetPropertyNames( Const _1_o_o1_object: Tq4Object): Tq4Collection;
  Begin
    Result := buildPropertyNamesCollection( _1_o_o1_object);
  End;

Procedure finalizeZoneLocks;
  Var
    _e_i: int64;
  Begin
    For _e_i := 0 To System.Length( gy_zoneLocks) - 1 Do If ( gy_zoneLocks[_e_i].b_initialized) Then Begin
        DoneCriticalSection( gy_zoneLocks[_e_i].y_lock);
        gy_zoneLocks[_e_i].b_initialized := False;
      End;
    System.SetLength( gy_zoneLocks, 0);
  End;

Procedure finalizeObjectData;
  Var
    _e_i: int64;
  Begin
    For _e_i := 0 To System.Length( gv_objectData) - 1 Do If ( gv_objectData[_e_i] <> nil) Then Begin
        gv_objectData[_e_i]^.c_names.Free;
        System.SetLength( gv_objectData[_e_i]^.tv_values, 0);
        Dispose( gv_objectData[_e_i]);
        gv_objectData[_e_i] := nil;
      End;

    System.SetLength( gv_objectData, 0);
  End;

Initialization
  InitCriticalSection( gy_zoneMapLock);
  gb_zoneMapLockInitialized := True;
  go_storageRoot := q4objectsLanguage.newSharedObject;

Finalization
  finalizeObjectData;
  finalizeZoneLocks;
  If ( gb_zoneMapLockInitialized) Then Begin
    DoneCriticalSection( gy_zoneMapLock);
    gb_zoneMapLockInitialized := False;
  End;

End.
