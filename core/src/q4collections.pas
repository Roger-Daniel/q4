unit q4collections;

{$mode objfpc}{$H+}

{
q4collections
version du 2026/05/06

Mapping 4D → q4collections -> statut
Command Number 4D,    4D Command,                       q4 API,                           Statut
---------------------------------------------------------------------------------------------------------------
1563,                 ARRAY TO COLLECTION,               arrayToCollection,                OK spécifique / appels groupés avec *,
1562,                 COLLECTION TO ARRAY,               collectionToArray,                OK spécifique / appels groupés avec *,
1472,                 New collection,                    newCollection,                    OK spécifique / façade q4objectsLanguage,
1527,                 New shared collection,             newSharedCollection,              OK spécifique / shared simplifié,

Doc: https://developer.4d.com/docs/21/commands/theme/Collections

Notes q4
--------
Cette unité est la façade du thème 4D Collections.
Le moteur réel des objets et collections est porté par q4objectsLanguage :
Tq4Collection, Tq4Value, Tq4ColCell, handles internes, accès par index, etc.

Sémantique d'indexation retenue
-------------------------------
- les collections 4D/q4 sont indexées à partir de 0 ;
- les arrays 4D/q4arrays ont un élément 0 spécial et des éléments utiles 1..N ;
- ARRAY TO COLLECTION mappe donc array[1] vers collection[0] ;
- COLLECTION TO ARRAY mappe collection[0] vers array[1].

Appels éclatés et paramètre *
----------------------------
4D accepte plusieurs couples array/propertyName dans une seule commande.
q4 autorise le transpileur à éclater cet appel en plusieurs appels simples.
Le paramètre spécial 4D * est traduit par la chaîne "*" et sert à chaîner
les appels : les étapes sont mémorisées, puis le dernier appel sans * exécute
l'opération groupée en une seule passe.

Exemple 4D :
  ARRAY TO COLLECTION($c; $t1; "t1"; $t2; "t2")

Transpilation q4 :
  q4collections.arrayToCollection(c_c, q4ref.hpaRaw(@tt_t1, q4ref.q4vkText), 't1', '*');
  q4collections.arrayToCollection(c_c, q4ref.hpaRaw(@tt_t2, q4ref.q4vkText), 't2');

Comportement 4D testé
---------------------
ARRAY TO COLLECTION avec plusieurs tableaux et propertyName produit une
collection de longueur égale au plus grand tableau. Si un tableau est plus
court, la propriété correspondante est simplement absente des objets au-delà
de sa taille.

COLLECTION TO ARRAY avec une valeur Null vers ARRAY TEXT ne lève pas d'erreur
en 4D interprété : le tableau cible est redimensionné et l'élément texte reçoit
la valeur vide ''. q4 généralise ce comportement aux autres types scalaires via
les conversions AsText/AsInteger/AsReal/AsBoolean/AsDate/AsTime de Tq4Value.
}

interface

uses
  q4objectsLanguage,
  q4ref;

function newCollection: q4objectsLanguage.Tq4Collection;
function newSharedCollection: q4objectsLanguage.Tq4Collection;

procedure arrayToCollection(
  var _1_c_collection: q4objectsLanguage.Tq4Collection;
  const _2_y_arrayRef: q4ref.TQ4Ref;
  const _3_t_propertyName: string = '';
  const _4_t_flag: string = ''
  );

procedure collectionToArray(
  const _1_c_collection: q4objectsLanguage.Tq4Collection;
  const _2_y_arrayRef: q4ref.TQ4Ref;
  const _3_t_propertyName: string = '';
  const _4_t_flag: string = ''
  );

implementation

uses
  SysUtils,
  q4arrays,
  q4interruptions;

type
  Tq4ArrayToCollectionStep = record
    y_arrayRef: q4ref.TQ4Ref;
    t_propertyName: string;
  end;

  Tq4CollectionToArrayStep = record
    y_arrayRef: q4ref.TQ4Ref;
    t_propertyName: string;
  end;

  Tq4ArrayToCollectionStepArray = array of Tq4ArrayToCollectionStep;
  Tq4CollectionToArrayStepArray = array of Tq4CollectionToArrayStep;
  Tq4ArrayRefArray = array of q4arrays.Tq4ArrayRef;
  Tq4SizeArray = array of Int64;

  Pq4ArrayToCollectionState = ^Tq4ArrayToCollectionState;
  Tq4ArrayToCollectionState = record
    ty_steps: Tq4ArrayToCollectionStepArray;
  end;

  Pq4CollectionToArrayState = ^Tq4CollectionToArrayState;
  Tq4CollectionToArrayState = record
    ty_steps: Tq4CollectionToArrayStepArray;
  end;

threadvar
  gp_arrayToCollectionState: Pq4ArrayToCollectionState;
  gp_collectionToArrayState: Pq4CollectionToArrayState;

function arrayToCollectionState: Pq4ArrayToCollectionState;
begin
  if (gp_arrayToCollectionState = nil) then begin
    New(gp_arrayToCollectionState);
    System.SetLength(gp_arrayToCollectionState^.ty_steps, 0);
  end;

  Result := gp_arrayToCollectionState;
end;

function collectionToArrayState: Pq4CollectionToArrayState;
begin
  if (gp_collectionToArrayState = nil) then begin
    New(gp_collectionToArrayState);
    System.SetLength(gp_collectionToArrayState^.ty_steps, 0);
  end;

  Result := gp_collectionToArrayState;
end;

procedure clearArrayToCollectionState;
begin
  if (gp_arrayToCollectionState <> nil) then
    System.SetLength(gp_arrayToCollectionState^.ty_steps, 0);
end;

procedure clearCollectionToArrayState;
begin
  if (gp_collectionToArrayState <> nil) then
    System.SetLength(gp_collectionToArrayState^.ty_steps, 0);
end;

function arrayToCollectionPending: Boolean;
begin
  Result := (gp_arrayToCollectionState <> nil) and
    (System.Length(gp_arrayToCollectionState^.ty_steps) > 0);
end;

function collectionToArrayPending: Boolean;
begin
  Result := (gp_collectionToArrayState <> nil) and
    (System.Length(gp_collectionToArrayState^.ty_steps) > 0);
end;

procedure validateFlag(const _1_t_flag: string; const _2_t_context: string);
begin
  if ((_1_t_flag <> '') and (_1_t_flag <> '*')) then
    q4interruptions.assertRaise(
      _2_t_context + ': invalid flag. Expected empty string or "*".',
      {$I %CURRENTROUTINE%},
      {$I %LINENUM%}
      );
end;

procedure addArrayToCollectionStep(const _1_y_arrayRef: q4ref.TQ4Ref; const _2_t_propertyName: string);
var
  _p_state: Pq4ArrayToCollectionState;
  _e_index: Int64;
begin
  _p_state := arrayToCollectionState;
  _e_index := System.Length(_p_state^.ty_steps);
  System.SetLength(_p_state^.ty_steps, _e_index + 1);
  _p_state^.ty_steps[_e_index].y_arrayRef := _1_y_arrayRef;
  _p_state^.ty_steps[_e_index].t_propertyName := _2_t_propertyName;
end;

procedure addCollectionToArrayStep(const _1_y_arrayRef: q4ref.TQ4Ref; const _2_t_propertyName: string);
var
  _p_state: Pq4CollectionToArrayState;
  _e_index: Int64;
begin
  _p_state := collectionToArrayState;
  _e_index := System.Length(_p_state^.ty_steps);
  System.SetLength(_p_state^.ty_steps, _e_index + 1);
  _p_state^.ty_steps[_e_index].y_arrayRef := _1_y_arrayRef;
  _p_state^.ty_steps[_e_index].t_propertyName := _2_t_propertyName;
end;

procedure executeArrayToCollectionPropertyGroup(var _1_c_collection: q4objectsLanguage.Tq4Collection);
var
  _p_state: Pq4ArrayToCollectionState;
  _ty_arrayRefs: Tq4ArrayRefArray;
  _te_sizes: Tq4SizeArray;
  _e_stepCount: Int64;
  _e_step: Int64;
  _e_row: Int64;
  _e_maxSize: Int64;
  _v_value: q4objectsLanguage.Tq4Value;
begin
  _p_state := arrayToCollectionState;
  _e_stepCount := System.Length(_p_state^.ty_steps);
  if (_e_stepCount = 0) then Exit;

  System.SetLength(_ty_arrayRefs, _e_stepCount);
  System.SetLength(_te_sizes, _e_stepCount);
  _e_maxSize := 0;

  for _e_step := 0 to _e_stepCount - 1 do begin
    _ty_arrayRefs[_e_step] := q4arrays.q4RefToArrayRef(
      _p_state^.ty_steps[_e_step].y_arrayRef,
      'q4collections.arrayToCollection'
      );
    _te_sizes[_e_step] := q4arrays.sizeOfArray(_ty_arrayRefs[_e_step]);
    if (_te_sizes[_e_step] > _e_maxSize) then _e_maxSize := _te_sizes[_e_step];
  end;

  q4objectsLanguage.collectionClear(_1_c_collection);
  q4objectsLanguage.collectionSetLength(_1_c_collection, _e_maxSize);

  for _e_row := 0 to _e_maxSize - 1 do
    for _e_step := 0 to _e_stepCount - 1 do
      if (_e_row < _te_sizes[_e_step]) then begin
        _v_value := q4arrays.arrayItemToValue(_ty_arrayRefs[_e_step], _e_row + 1);
        q4objectsLanguage.collectionSetObjectPropertyAt(
          _1_c_collection,
          _e_row,
          _p_state^.ty_steps[_e_step].t_propertyName,
          _v_value
          );
      end;

  clearArrayToCollectionState;
end;

procedure executeCollectionToArrayPropertyGroup(const _1_c_collection: q4objectsLanguage.Tq4Collection);
var
  _p_state: Pq4CollectionToArrayState;
  _ty_arrayRefs: Tq4ArrayRefArray;
  _e_stepCount: Int64;
  _e_step: Int64;
  _e_row: Int64;
  _e_collectionSize: Int64;
  _v_value: q4objectsLanguage.Tq4Value;
begin
  _p_state := collectionToArrayState;
  _e_stepCount := System.Length(_p_state^.ty_steps);
  if (_e_stepCount = 0) then Exit;

  _e_collectionSize := q4objectsLanguage.col(_1_c_collection).length;

  System.SetLength(_ty_arrayRefs, _e_stepCount);
  for _e_step := 0 to _e_stepCount - 1 do begin
    _ty_arrayRefs[_e_step] := q4arrays.q4RefToArrayRef(
      _p_state^.ty_steps[_e_step].y_arrayRef,
      'q4collections.collectionToArray'
      );
    q4arrays.arraySetSize(_ty_arrayRefs[_e_step], _e_collectionSize);
  end;

  for _e_row := 0 to _e_collectionSize - 1 do
    for _e_step := 0 to _e_stepCount - 1 do begin
      _v_value := q4objectsLanguage.collectionGetObjectPropertyAt(
        _1_c_collection,
        _e_row,
        _p_state^.ty_steps[_e_step].t_propertyName
        );
      q4arrays.arraySetItemFromValue(_ty_arrayRefs[_e_step], _e_row + 1, _v_value);
    end;

  clearCollectionToArrayState;
end;

function newCollection: q4objectsLanguage.Tq4Collection;
begin
  //https://developer.4d.com/docs/21/commands/new-collection
  Result := q4objectsLanguage.newCollection;
end;

function newSharedCollection: q4objectsLanguage.Tq4Collection;
begin
  //https://developer.4d.com/docs/21/commands/new-shared-collection

  // q4 : façade vers q4objectsLanguage.
  // Le runtime shared 4D complet n'est pas reproduit ici : q4objectsLanguage
  // fournit actuellement une collection utilisable, avec une sémantique
  // partagée simplifiée.
  Result := q4objectsLanguage.newSharedCollection;
end;

procedure arrayToCollection(
  var _1_c_collection: q4objectsLanguage.Tq4Collection;
  const _2_y_arrayRef: q4ref.TQ4Ref;
  const _3_t_propertyName: string;
  const _4_t_flag: string
  );
var
  _y_arrayRef: q4arrays.Tq4ArrayRef;
  _e_size: Int64;
  _e_index: Int64;
  _v_value: q4objectsLanguage.Tq4Value;
begin
  //https://developer.4d.com/docs/21/commands/array-to-collection
  validateFlag(_4_t_flag, 'ARRAY TO COLLECTION');

  // q4 : sans propertyName, la commande remplace immédiatement la collection
  // par une liste de valeurs simples. Les tableaux q4 gardent la sémantique 4D :
  // éléments utiles 1..N et élément 0 spécial. Les collections sont 0-based.
  if (_3_t_propertyName = '') then begin
    if (arrayToCollectionPending) then begin
      clearArrayToCollectionState;
      q4interruptions.assertRaise(
        'ARRAY TO COLLECTION: simple array conversion cannot interrupt a pending property chain.',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
      Exit;
    end;

    if (_4_t_flag = '*') then begin
      q4interruptions.assertRaise(
        'ARRAY TO COLLECTION: flag "*" is only supported with propertyName in q4.',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
      Exit;
    end;

    _y_arrayRef := q4arrays.q4RefToArrayRef(_2_y_arrayRef, 'q4collections.arrayToCollection');
    _e_size := q4arrays.sizeOfArray(_y_arrayRef);

    q4objectsLanguage.collectionClear(_1_c_collection);
    q4objectsLanguage.collectionSetLength(_1_c_collection, _e_size);

    for _e_index := 1 to _e_size do begin
      _v_value := q4arrays.arrayItemToValue(_y_arrayRef, _e_index);
      q4objectsLanguage.collectionSetItem(_1_c_collection, _e_index - 1, _v_value);
    end;

    Exit;
  end;

  // q4 : avec propertyName, le transpileur peut éclater l'appel 4D en plusieurs
  // appels q4. Les appels avec "*" mémorisent les étapes ; le dernier appel
  // sans "*" construit la collection d'objets en une seule passe.
  addArrayToCollectionStep(_2_y_arrayRef, _3_t_propertyName);

  if (_4_t_flag = '*') then Exit;

  executeArrayToCollectionPropertyGroup(_1_c_collection);
end;

procedure collectionToArray(
  const _1_c_collection: q4objectsLanguage.Tq4Collection;
  const _2_y_arrayRef: q4ref.TQ4Ref;
  const _3_t_propertyName: string;
  const _4_t_flag: string
  );
var
  _y_arrayRef: q4arrays.Tq4ArrayRef;
  _e_size: Int64;
  _e_index: Int64;
  _v_value: q4objectsLanguage.Tq4Value;
begin
  //https://developer.4d.com/docs/21/commands/collection-to-array
  validateFlag(_4_t_flag, 'COLLECTION TO ARRAY');

  // q4 : sans propertyName, la commande remplit directement le tableau typé.
  // collection[0] devient array[1]. Null/Undefined deviennent les valeurs vides
  // du type cible via les conversions de Tq4Value.
  if (_3_t_propertyName = '') then begin
    if (collectionToArrayPending) then begin
      clearCollectionToArrayState;
      q4interruptions.assertRaise(
        'COLLECTION TO ARRAY: simple collection conversion cannot interrupt a pending property chain.',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
      Exit;
    end;

    if (_4_t_flag = '*') then begin
      q4interruptions.assertRaise(
        'COLLECTION TO ARRAY: flag "*" is only supported with propertyName in q4.',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );
      Exit;
    end;

    _y_arrayRef := q4arrays.q4RefToArrayRef(_2_y_arrayRef, 'q4collections.collectionToArray');
    _e_size := q4objectsLanguage.col(_1_c_collection).length;

    q4arrays.arraySetSize(_y_arrayRef, _e_size);

    for _e_index := 0 to _e_size - 1 do begin
      _v_value := q4objectsLanguage.collectionItem(_1_c_collection, _e_index);
      q4arrays.arraySetItemFromValue(_y_arrayRef, _e_index + 1, _v_value);
    end;

    Exit;
  end;

  // q4 : avec propertyName, les étapes sont regroupées comme pour
  // ARRAY TO COLLECTION afin de parcourir la collection une seule fois au
  // dernier appel sans "*".
  addCollectionToArrayStep(_2_y_arrayRef, _3_t_propertyName);

  if (_4_t_flag = '*') then Exit;

  executeCollectionToArrayPropertyGroup(_1_c_collection);
end;

finalization
  if (gp_arrayToCollectionState <> nil) then begin
    Dispose(gp_arrayToCollectionState);
    gp_arrayToCollectionState := nil;
  end;

  if (gp_collectionToArrayState <> nil) then begin
    Dispose(gp_collectionToArrayState);
    gp_collectionToArrayState := nil;
  end;

end.
