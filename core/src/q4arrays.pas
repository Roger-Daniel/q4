Unit q4arrays;

{$mode objfpc}{$H+}

{
q4arrays
version du 2026/04/26-08

Mapping 4D
Command Number 4D,   4D Command,                       q4 cible,                           Statut
--------------------------------------------------------------------------------------------------
1222,                ARRAY BLOB,                       arrayBlob,                          OK
223,                 ARRAY BOOLEAN,                    arrayBoolean,                       OK
224,                 ARRAY DATE,                       arrayDate,                          OK
220,                 ARRAY INTEGER,                    arrayInteger,                       OK
221,                 ARRAY LONGINT,                    arrayLongint,                       OK
1221,                ARRAY OBJECT,                     arrayObject,                        OK
279,                 ARRAY PICTURE,                    arrayPicture,                       OK
280,                 ARRAY POINTER,                    arrayPointer,                       OK
219,                 ARRAY REAL,                       arrayReal,                          OK
222,                 ARRAY TEXT,                       arrayText,                          OK
1223,                ARRAY TIME,                       arrayTime,                          OK

911,                 APPEND TO ARRAY,                  appendToArray,                      OK
226,                 COPY ARRAY,                       copyArray,                          OK
907,                 Count in array,                   countInArray,                       OK
228,                 DELETE FROM ARRAY,                deleteFromArray,                    OK
230,                 Find in array,                    findInArray,                        OK
227,                 INSERT IN ARRAY,                  insertInArray,                      OK
274,                 Size of array,                    sizeOfArray,                        OK

229,                 SORT ARRAY,                       transpileur -> SortArrays,          OK
718,                 MULTI SORT ARRAY,                 transpileur -> SortArrays,          OK
1333,                Find in sorted array,             findInSortedArray,                  TODO

260,                 SELECTION TO ARRAY,               selectionToArray,                   OK
368,                 SELECTION RANGE TO ARRAY,         selectionRangeToArray,              OK
647,                 LONGINT ARRAY FROM SELECTION,     longintArrayFromSelection,          Partial
261,                 ARRAY TO SELECTION,               arrayToSelection,                   TODO

287,                 ARRAY TO LIST,                    arrayToList,                        TODO
288,                 LIST TO ARRAY,                    listToArray,                        TODO

646,                 BOOLEAN ARRAY FROM SET,           booleanArrayFromSet,                Unsupported
1395,                DISTINCT ATTRIBUTE PATHS,         distinctAttributePaths,             TODO
1397,                DISTINCT ATTRIBUTE VALUES,        distinctAttributeValues,            TODO
339,                 DISTINCT VALUES,                  distinctValues,                     TODO
1149,                TEXT TO ARRAY,                    textToArray,                        TODO

0,                   affectation variable tableau,     transpileur -> arrayAssociatedValue, OK

Doc: https://developer.4d.com/docs/21/commands/theme/Arrays

Périmètre q4
------------
- Les unités q4 suivent les thèmes 4D comme façade publique.
- Les implémentations internes peuvent déléguer à des services plus transverses.
- Les tableaux Date et Heure sont physiquement portés en string, avec formats
  canoniques déjà fixés :
      Date  = YYYY-MM-DD
      Heure = HH:NN:SS
- Les énumérations / named lists ne modifient pas la structure à runtime.
  Le schéma ne garde que les noms ; les valeurs sont chargées au démarrage
  dans un registry runtime.
- ARRAY TO LIST / LIST TO ARRAY travailleront donc sur ce registry runtime.
- BOOLEAN ARRAY FROM SET est explicitement hors cible q4.

Compatibilité 4D retenue
------------------------
- SELECTION TO ARRAY : décharge le record courant en sortie.
- LONGINT ARRAY FROM SELECTION : laisse le record courant chargé.
- ARRAY TO SELECTION : met à jour la sélection courante mais ne charge aucun
  record en sortie ; ignore l'état readonly de table ; respecte les locks.

Sémantique 4D des tableaux
--------------------------
- Un tableau 4D est une variable du langage.
- Il est créé et redimensionné par les commandes du thème Arrays.
- Les éléments logiques d'un tableau sont numérotés de 1 à N.
- Un tableau possède toujours un élément spécial d'indice 0.
- L'élément 0 existe même quand la taille logique du tableau est 0.
- L'élément 0 n'est pas affiché dans les objets de formulaire alimentés par
  tableau, mais il reste utilisable dans le langage.
- Exception connue : dans les list boxes basées sur tableaux, l'élément 0 est
  utilisé en interne pendant l'édition.

Convention d'implémentation q4
------------------------------
Pour reproduire cette sémantique au-dessus des tableaux dynamiques FreePascal :

- la taille logique 4D vaut N
- la taille physique FreePascal vaut N + 1
- l'indice 0 est toujours présent en mémoire
- sizeOfArray(A) retourne la taille logique 4D, donc Length(A) - 1

En pratique :
- ArrayText(A, 0) -> SetLength(A, 1)
- ArrayText(A, 5) -> SetLength(A, 6)
- les indices logiques usuels sont 1..sizeOfArray(A)
- l'indice 0 reste valide et accessible

Conséquences pour les commandes q4
----------------------------------
- les commandes de déclaration/redimensionnement travaillent sur la taille
  logique 4D
- appendToArray ajoute après le dernier élément logique
- insertInArray insère dans la zone logique 1..N+1
- deleteFromArray supprime dans la zone logique 1..N
- aucune de ces commandes ne supprime l'existence de l'élément 0

Remarque
--------
Cette unité cherche à préserver la sémantique 4D, pas à mimer naïvement un
simple "array of ..." Pascal. Le tableau FreePascal sous-jacent sert seulement
de support de stockage.

Valeur associée à la variable tableau
-------------------------------------
En 4D, une variable tableau peut porter une valeur entière propre, distincte
de son contenu indexé.

q4 stocke cette valeur dans un registre thread-local géré par q4arrays.
Ce mécanisme ne s'applique qu'aux tableaux de durée de vie stable
(var/thread/process). Les tableaux locaux ne sont pas pris en charge pour
cette sémantique.

}

Interface

Uses
  SysUtils,
  Classes,
  DB,
  SQLDB,
  q4coreLanguage,
  q4ref,
  q4interruptions,
  q4objectsLanguage,
  metier_q4DBschemaBase,
  q4DBschemaUse,
  q4DBmanager,
  q4selection,
  q4selectionTablesCore,
  q4setsAndNamedSelectionsCore,
  q4RecordLocking,
  q4relations;

Const
  { Convention publique q4 pour exprimer les sens de tri dans le code généré.
    Le moteur interne normalise ensuite ces valeurs en -1 / 0 / 1. }
  q4SortAscending = '>';
  q4SortDescending = '<';
  q4SortSynchronized = '0';

Type
  { Types de tableaux q4 minimaux utilisés dans ce thème. }
  TIntArray = Array Of integer;

  Tq4ArrayKind = (
    akText,
    akDate,
    akTime,
    akObject,
    // akLongint,
    akInt64,
    akReal,
    akBoolean,
    akBlob,
    akPointer,
    akPicture
    );

  { Référence générique vers une variable tableau q4.
    Data pointe vers la variable tableau complète, pas vers son premier élément. }
  Tq4ArrayRef = Record
    Kind: Tq4ArrayKind;
    Data: Pointer;
  End;

  { Descripteur de tri synchronisé.
    Order est une valeur interne normalisée :
      1  = ascendant
     -1  = descendant
      0  = synchronisé, non critère }
  Tq4SortArrayRef = Record
    Ref: Tq4ArrayRef;
    Order: shortint;
  End;

  { Requêtes pour SELECTION TO ARRAY / SELECTION RANGE TO ARRAY.
    - FieldPtr = nil  : numéro de record / rowid de la table source.
    - FieldPtr <> nil : pointeur 4D/q4 vers un champ.
      Les champs locaux et les chemins many-to-one, directs ou multi-niveaux,
      sont gérés via q4coreRelations. }
  Tq4selectionArrayRequest = Record
    FieldPtr: Pointer;
    Target: Tq4ArrayRef;
  End;

  { Bindings pour ARRAY TO SELECTION.
    FieldPtr doit pointer vers un champ local de la table source. }
  Tq4ArrayToSelectionBinding = Record
    FieldPtr: Pointer;
    Source: Tq4ArrayRef;
  End;

Type
  Tq4ArrayAssociatedValues = Record
    ArrayRefs: Array Of Pointer;
    Values: Array Of integer;
  End;

{ Helpers de référence typée }
Function TextArray( Var _1_tt_a: Tq4TextArray): Tq4ArrayRef; Inline;
Function DateArray( Var _1_te_a: Tq4DateArray): Tq4ArrayRef; Inline;
Function TimeArray( Var _1_te_a: Tq4TimeArray): Tq4ArrayRef; Inline;
Function ObjectArray( Var _1_to_a: Tq4ObjectArray): Tq4ArrayRef; Inline;
//function LongintArray(var A: Tq4Int64Array): Tq4ArrayRef; inline;
Function Int64Array( Var _1_te_a: Tq4Int64Array): Tq4ArrayRef; Inline;
Function RealArray( Var _1_tr_a: Tq4RealArray): Tq4ArrayRef; Inline;
Function BooleanArray( Var _1_tb_a: Tq4BooleanArray): Tq4ArrayRef; Inline;
Function BlobArray( Var _1_ty_a: Tq4BlobArray): Tq4ArrayRef; Inline;
Function PointerArray( Var _1_tp_a: Tq4PointerArray): Tq4ArrayRef; Inline;
Function PictureArray( Var _1_ty_a: Tq4PictureArray): Tq4ArrayRef; Inline;

{ Pont q4ref -> q4arrays.
  TQ4Ref est la référence q4 générale. Tq4ArrayRef reste le record interne
  historique de q4arrays, utilisé notamment pour tri/sélections. }
Function q4RefToArrayRef( Const _1_y_ref: q4ref.TQ4Ref; Const _2_t_where: string = 'q4arrays'): Tq4ArrayRef;
Function SortArrayRef( Const _1_y_ref: q4ref.TQ4Ref; Const _2_t_order: string = q4SortSynchronized): Tq4SortArrayRef; Inline;
Function selectionArrayRequest( Const _1_p_fieldPtr: Pointer; Const _2_y_target: q4ref.TQ4Ref): Tq4selectionArrayRequest; Inline;
Function arrayToSelectionBinding( Const _1_p_fieldPtr: Pointer; Const _2_y_source: q4ref.TQ4Ref): Tq4ArrayToSelectionBinding; Inline;

{ Déclarations / redimensionnements 4D de base.
  Convention q4 :
  - la taille passée est la taille logique 4D
  - le stockage FPC garde toujours l'élément 0
  - donc SetLength(..., eSize + 1) }
Procedure arrayText( Var _1_tt_a: Tq4TextArray; Const _2_e_eSize: int64); overload;
Procedure arrayDate( Var _1_te_a: Tq4DateArray; Const _2_e_eSize: int64); overload;
Procedure arrayTime( Var _1_te_a: Tq4TimeArray; Const _2_e_eSize: int64); overload;
Procedure arrayObject( Var _1_to_a: Tq4ObjectArray; Const _2_e_eSize: int64); overload;
Procedure arrayLongint( Var _1_te_a: Tq4Int64Array; Const _2_e_eSize: int64); overload;
Procedure arrayInteger( Var _1_te_a: Tq4Int64Array; Const _2_e_eSize: int64); overload;
Procedure arrayReal( Var _1_tr_a: Tq4RealArray; Const _2_e_eSize: int64); overload;
Procedure arrayBoolean( Var _1_tb_a: Tq4BooleanArray; Const _2_e_eSize: int64); overload;
Procedure arrayBlob( Var _1_ty_a: Tq4BlobArray; Const _2_e_eSize: int64); overload;
Procedure arrayPointer( Var _1_tp_a: Tq4PointerArray; Const _2_e_eSize: int64); overload;
Procedure arrayPicture( Var _1_ty_a: Tq4PictureArray; Const _2_e_eSize: int64); overload;

Procedure arrayText( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64); overload;
Procedure arrayDate( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64); overload;
Procedure arrayTime( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64); overload;
Procedure arrayObject( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64); overload;
Procedure arrayLongint( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64); overload;
Procedure arrayInteger( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64); overload;
Procedure arrayReal( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64); overload;
Procedure arrayBoolean( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64); overload;
Procedure arrayBlob( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64); overload;
Procedure arrayPointer( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64); overload;
Procedure arrayPicture( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64); overload;

Function sizeOfArray( Const _1_tt_a: Tq4TextArray): int64; overload;
Function sizeOfArray( Const _1_te_a: Tq4DateArray): int64; overload;
Function sizeOfArray( Const _1_te_a: Tq4TimeArray): int64; overload;
Function sizeOfArray( Const _1_to_a: Tq4ObjectArray): int64; overload;
Function sizeOfArray( Const _1_te_a: Tq4Int64Array): int64; overload;
Function sizeOfArray( Const _1_tr_a: Tq4RealArray): int64; overload;
Function sizeOfArray( Const _1_tb_a: Tq4BooleanArray): int64; overload;
Function sizeOfArray( Const _1_ty_a: Tq4BlobArray): int64; overload;
Function sizeOfArray( Const _1_tp_a: Tq4PointerArray): int64; overload;
Function sizeOfArray( Const _1_ty_a: Tq4PictureArray): int64; overload;
Function sizeOfArray( Const _1_y_ref: q4ref.TQ4Ref): int64; overload;
Function sizeOfArray( Const _1_y_ref: Tq4ArrayRef): int64; overload;

{ Helpers génériques prévus pour q4collections.
  Les indices sont les indices logiques 4D des tableaux, donc 1..N.
  La conversion Null/Undefined vers tableau typé produit la valeur vide du type
  cible via les méthodes AsText/AsInteger/AsReal/AsBoolean/AsDate/AsTime de
  Tq4Value. }
Procedure arraySetSize( Const _1_y_ref: Tq4ArrayRef; Const _2_e_eSize: int64); overload;
Procedure arraySetSize( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64); overload;
Function arrayItemToValue( Const _1_y_ref: Tq4ArrayRef; Const _2_e_eIndex4D: int64): q4objectsLanguage.Tq4Value; overload;
Function arrayItemToValue( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eIndex4D: int64): q4objectsLanguage.Tq4Value; overload;
Procedure arraySetItemFromValue( Const _1_y_ref: Tq4ArrayRef; Const _2_e_eIndex4D: int64; Const _3_y_vValue: q4objectsLanguage.Tq4Value); overload;
Procedure arraySetItemFromValue( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eIndex4D: int64; Const _3_y_vValue: q4objectsLanguage.Tq4Value); overload;

Procedure appendToArray( Var _1_tt_a: Tq4TextArray; Const _2_t_eValue: string); overload;
Procedure appendToArray( Var _1_te_a: Tq4Int64Array; Const _2_e_eValue: int64); overload;
Procedure appendToArray( Var _1_tr_a: Tq4RealArray; Const _2_r_eValue: double); overload;
Procedure appendToArray( Var _1_tb_a: Tq4BooleanArray; Const _2_b_eValue: boolean); overload;
Procedure appendToArray( Var _1_te_a: Tq4DateArray; Const _2_t_eValue: string); overload;
Procedure appendToArray( Var _1_te_a: Tq4TimeArray; Const _2_t_eValue: string); overload;
Procedure appendToArray( Var _1_to_a: Tq4ObjectArray; Const _2_o_eValue: Tq4JSONObject); overload;
Procedure appendToArray( Var _1_ty_a: Tq4BlobArray; Const _2_by_eValue: TBytes); overload;
Procedure appendToArray( Var _1_tp_a: Tq4PointerArray; Const _2_p_eValue: Pointer); overload;
Procedure appendToArray( Var _1_ty_a: Tq4PictureArray; Const _2_o_eValue: Tq4Picture); overload;
Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_t_eValue: string); overload;
Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_y_eValue: Tq4Date); overload;
Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_y_eValue: Tq4Time); overload;
Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_o_eValue: Tq4JSONObject); overload;
Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eValue: int64); overload;
Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_r_eValue: double); overload;
Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_b_eValue: boolean); overload;
Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_by_eValue: TBytes); overload;
Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_p_eValue: Pointer); overload;

Procedure deleteFromArray( Var _1_tt_a: Tq4TextArray; Const _2_e_eIndex4D: int64); overload;
//procedure deleteFromArray(var A: Tq4LongintArray; const eIndex4D: Int64); overload;
Procedure deleteFromArray( Var _1_te_a: Tq4Int64Array; Const _2_e_eIndex4D: int64); overload;
Procedure deleteFromArray( Var _1_tr_a: Tq4RealArray; Const _2_e_eIndex4D: int64); overload;
Procedure deleteFromArray( Var _1_tb_a: Tq4BooleanArray; Const _2_e_eIndex4D: int64); overload;
Procedure deleteFromArray( Var _1_te_a: Tq4DateArray; Const _2_e_eIndex4D: int64); overload;
Procedure deleteFromArray( Var _1_te_a: Tq4TimeArray; Const _2_e_eIndex4D: int64); overload;
Procedure deleteFromArray( Var _1_to_a: Tq4ObjectArray; Const _2_e_eIndex4D: int64); overload;
Procedure deleteFromArray( Var _1_ty_a: Tq4BlobArray; Const _2_e_eIndex4D: int64); overload;
Procedure deleteFromArray( Var _1_tp_a: Tq4PointerArray; Const _2_e_eIndex4D: int64); overload;
Procedure deleteFromArray( Var _1_ty_a: Tq4PictureArray; Const _2_e_eIndex4D: int64); overload;
Procedure deleteFromArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eIndex4D: int64); overload;

Procedure insertInArray( Var _1_tt_a: Tq4TextArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64 = 1); overload;
//procedure insertInArray(var A: Tq4LongintArray; const eIndex4D: Int64; const eHowMany: int64 = 1); overload;
Procedure insertInArray( Var _1_te_a: Tq4Int64Array; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64 = 1); overload;
Procedure insertInArray( Var _1_tr_a: Tq4RealArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64 = 1); overload;
Procedure insertInArray( Var _1_tb_a: Tq4BooleanArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64 = 1); overload;
Procedure insertInArray( Var _1_te_a: Tq4DateArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64 = 1); overload;
Procedure insertInArray( Var _1_te_a: Tq4TimeArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64 = 1); overload;
Procedure insertInArray( Var _1_to_a: Tq4ObjectArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64 = 1); overload;
Procedure insertInArray( Var _1_ty_a: Tq4BlobArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64 = 1); overload;
Procedure insertInArray( Var _1_tp_a: Tq4PointerArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64 = 1); overload;
Procedure insertInArray( Var _1_ty_a: Tq4PictureArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64 = 1); overload;
Procedure insertInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64 = 1); overload;

Procedure copyArray( Const _1_tt_source: Tq4TextArray; Var _2_tt_dest: Tq4TextArray); overload;
Procedure copyArray( Const _1_te_source: Tq4DateArray; Var _2_te_dest: Tq4DateArray); overload;
Procedure copyArray( Const _1_te_source: Tq4TimeArray; Var _2_te_dest: Tq4TimeArray); overload;
Procedure copyArray( Const _1_to_source: Tq4ObjectArray; Var _2_to_dest: Tq4ObjectArray); overload;
//procedure copyArray(const ASource: Tq4LongintArray; var ADest: Tq4LongintArray); overload;
Procedure copyArray( Const _1_te_source: Tq4Int64Array; Var _2_te_dest: Tq4Int64Array); overload;
Procedure copyArray( Const _1_tr_source: Tq4RealArray; Var _2_tr_dest: Tq4RealArray); overload;
Procedure copyArray( Const _1_tb_source: Tq4BooleanArray; Var _2_tb_dest: Tq4BooleanArray); overload;
Procedure copyArray( Const _1_ty_source: Tq4BlobArray; Var _2_ty_dest: Tq4BlobArray); overload;
Procedure copyArray( Const _1_tp_source: Tq4PointerArray; Var _2_tp_dest: Tq4PointerArray); overload;
Procedure copyArray( Const _1_ty_source: Tq4PictureArray; Var _2_ty_dest: Tq4PictureArray); overload;
Procedure copyArray( Const _1_y_sourceRef: q4ref.TQ4Ref; Const _2_y_destRef: q4ref.TQ4Ref); overload;

Function countInArray( Const _1_tt_arrayValue: Tq4TextArray; Const _2_t_value: string): int64; overload;
Function countInArray( Const _1_te_arrayValue: Tq4DateArray; Const _2_y_value: Tq4Date): int64; overload;
Function countInArray( Const _1_te_arrayValue: Tq4TimeArray; Const _2_y_value: Tq4Time): int64; overload;
Function countInArray( Const _1_to_arrayValue: Tq4ObjectArray; Const _2_o_value: Tq4JSONObject): int64; overload;
//function countInArray(const AArray: Tq4LongintArray; const AValue: longint): Int64; overload;
Function countInArray( Const _1_te_arrayValue: Tq4Int64Array; Const _2_e_value: int64): int64; overload;
Function countInArray( Const _1_tr_arrayValue: Tq4RealArray; Const _2_r_value: double): int64; overload;
Function countInArray( Const _1_tb_arrayValue: Tq4BooleanArray; Const _2_b_value: boolean): int64; overload;
Function countInArray( Const _1_ty_arrayValue: Tq4BlobArray; Const _2_by_value: TBytes): int64; overload;
Function countInArray( Const _1_tp_arrayValue: Tq4PointerArray; Const _2_p_value: Pointer): int64; overload;
Function countInArray( Const _1_ty_arrayValue: Tq4PictureArray; Const _2_o_value: Tq4Picture): int64; overload;
Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_t_value: string): int64; overload;
Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_y_value: Tq4Date): int64; overload;
Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_y_value: Tq4Time): int64; overload;
Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_o_value: Tq4JSONObject): int64; overload;
Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_value: int64): int64; overload;
Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_r_value: double): int64; overload;
Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_b_value: boolean): int64; overload;
Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_by_value: TBytes): int64; overload;
Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_p_value: Pointer): int64; overload;

Function findInArray( Const _1_tt_arrayValue: Tq4TextArray; Const _2_t_value: string): int64; overload;
Function findInArray( Const _1_te_arrayValue: Tq4DateArray; Const _2_y_value: Tq4Date): int64; overload;
Function findInArray( Const _1_te_arrayValue: Tq4TimeArray; Const _2_y_value: Tq4Time): int64; overload;
Function findInArray( Const _1_to_arrayValue: Tq4ObjectArray; Const _2_o_value: Tq4JSONObject): int64; overload;
//function findInArray(const AArray: Tq4LongintArray; const AValue: longint): Int64; overload;
Function findInArray( Const _1_te_arrayValue: Tq4Int64Array; Const _2_e_value: int64): int64; overload;
Function findInArray( Const _1_tr_arrayValue: Tq4RealArray; Const _2_r_value: double): int64; overload;
Function findInArray( Const _1_tb_arrayValue: Tq4BooleanArray; Const _2_b_value: boolean): int64; overload;
Function findInArray( Const _1_ty_arrayValue: Tq4BlobArray; Const _2_by_value: TBytes): int64; overload;
Function findInArray( Const _1_tp_arrayValue: Tq4PointerArray; Const _2_p_value: Pointer): int64; overload;
Function findInArray( Const _1_ty_arrayValue: Tq4PictureArray; Const _2_o_value: Tq4Picture): int64; overload;
Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_t_value: string): int64; overload;
Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_y_value: Tq4Date): int64; overload;
Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_y_value: Tq4Time): int64; overload;
Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_o_value: Tq4JSONObject): int64; overload;
Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_value: int64): int64; overload;
Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_r_value: double): int64; overload;
Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_b_value: boolean): int64; overload;
Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_by_value: TBytes): int64; overload;
Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_p_value: Pointer): int64; overload;

{ Helpers de tri : acceptent aussi bien une variable tableau directe qu'un tableau
  dépointé (ex: pMyArray^), tant que le type est correct. }
Function TextArrayRef( Var _1_tt_a: Tq4TextArray; Const _2_t_order: string = q4SortSynchronized): Tq4SortArrayRef; Inline;
Function DateArrayRef( Var _1_te_a: Tq4DateArray; Const _2_t_order: string = q4SortSynchronized): Tq4SortArrayRef; Inline;
Function TimeArrayRef( Var _1_te_a: Tq4TimeArray; Const _2_t_order: string = q4SortSynchronized): Tq4SortArrayRef; Inline;
Function ObjectArrayRef( Var _1_to_a: Tq4ObjectArray; Const _2_t_order: string = q4SortSynchronized): Tq4SortArrayRef; Inline;
//function LongintArrayRef(var A: Tq4LongintArray; const Order: string = q4SortSynchronized): Tq4SortArrayRef; inline;
Function Int64ArrayRef( Var _1_te_a: Tq4Int64Array; Const _2_t_order: string = q4SortSynchronized): Tq4SortArrayRef; Inline;
Function RealArrayRef( Var _1_tr_a: Tq4RealArray; Const _2_t_order: string = q4SortSynchronized): Tq4SortArrayRef; Inline;
Function BooleanArrayRef( Var _1_tb_a: Tq4BooleanArray; Const _2_t_order: string = q4SortSynchronized): Tq4SortArrayRef; Inline;
Function BlobArrayRef( Var _1_ty_a: Tq4BlobArray; Const _2_t_order: string = q4SortSynchronized): Tq4SortArrayRef; Inline;
Function PictureArrayRef( Var _1_ty_a: Tq4PictureArray; Const _2_t_order: string = q4SortSynchronized): Tq4SortArrayRef; Inline;
Function PointerArrayRef( Var _1_tp_a: Tq4PointerArray; Const _2_t_order: string = q4SortSynchronized): Tq4SortArrayRef; Inline;

{ Noyau q4 pour SORT ARRAY et MULTI SORT ARRAY.
  Le transpileur normalise les deux syntaxes 4D vers cette forme unique. }
Procedure SortArrays( Const _1_ty_refs: Array Of Tq4SortArrayRef);

{ Sélections }
Procedure selectionToArray( Var _1_p_recordTable; Const _2_ty_requests: Array Of Tq4selectionArrayRequest);
Procedure selectionRangeToArray( Var _1_p_recordTable; Const _2_e_eStartPos, _3_e_eEndPos: int64; Const _4_ty_requests: Array Of Tq4selectionArrayRequest);
//procedure longintArrayFromSelection(var ARecordTable; var ARecordNumbers: Tq4LongintArray); overload;
//procedure longintArrayFromSelection(var ARecordTable; const tNamedSelection: string; var ARecordNumbers: Tq4LongintArray); overload;
Procedure Int64ArrayFromSelection( Var _1_p_recordTable; Var _2_te_recordNumbers: Tq4Int64Array); overload;
Procedure Int64ArrayFromSelection( Var _1_p_recordTable; Const _2_t_tNamedSelection: string; Var _3_te_recordNumbers: Tq4Int64Array); overload;
Procedure Int64ArrayFromSelection( Var _1_p_recordTable; Const _2_y_recordNumbersRef: q4ref.TQ4Ref); overload;
Procedure Int64ArrayFromSelection( Var _1_p_recordTable; Const _2_t_tNamedSelection: string; Const _3_y_recordNumbersRef: q4ref.TQ4Ref); overload;

{ TODO runtime }
Procedure arrayToSelection( Var _1_p_recordTable; Const _2_ty_bindings: Array Of Tq4ArrayToSelectionBinding; Const _3_t_tStar: string = '');
Procedure flushDeferredArrayToSelection;

Procedure arrayToList( Const _1_t_tListName: string; Const _2_tt_labels: Tq4TextArray); overload;
Procedure arrayToList( Const _1_t_tListName: string; Const _2_tt_labels: Tq4TextArray; Const _3_te_refs: Tq4Int64Array); overload;
Procedure arrayToList( Const _1_e_eListRef: longint; Const _2_tt_labels: Tq4TextArray); overload;
Procedure arrayToList( Const _1_e_eListRef: longint; Const _2_tt_labels: Tq4TextArray; Const _3_te_refs: Tq4Int64Array); overload;
Procedure listToArray( Const _1_t_tListName: string; Var _2_tt_labels: Tq4TextArray); overload;
Procedure listToArray( Const _1_t_tListName: string; Var _2_tt_labels: Tq4TextArray; Var _3_te_refs: Tq4Int64Array); overload;
Procedure listToArray( Const _1_e_eListRef: longint; Var _2_tt_labels: Tq4TextArray); overload;
Procedure listToArray( Const _1_e_eListRef: longint; Var _2_tt_labels: Tq4TextArray; Var _3_te_refs: Tq4Int64Array); overload;
Procedure arrayToList( Const _1_t_tListName: string; Const _2_y_labelsRef: q4ref.TQ4Ref); overload;
Procedure arrayToList( Const _1_t_tListName: string; Const _2_y_labelsRef, _3_y_refsRef: q4ref.TQ4Ref); overload;
Procedure arrayToList( Const _1_e_eListRef: longint; Const _2_y_labelsRef: q4ref.TQ4Ref); overload;
Procedure arrayToList( Const _1_e_eListRef: longint; Const _2_y_labelsRef, _3_y_refsRef: q4ref.TQ4Ref); overload;
Procedure listToArray( Const _1_t_tListName: string; Const _2_y_labelsRef: q4ref.TQ4Ref); overload;
Procedure listToArray( Const _1_t_tListName: string; Const _2_y_labelsRef, _3_y_refsRef: q4ref.TQ4Ref); overload;
Procedure listToArray( Const _1_e_eListRef: longint; Const _2_y_labelsRef: q4ref.TQ4Ref); overload;
Procedure listToArray( Const _1_e_eListRef: longint; Const _2_y_labelsRef, _3_y_refsRef: q4ref.TQ4Ref); overload;

Procedure booleanArrayFromSet;
Procedure distinctAttributePaths;
Procedure distinctAttributeValues;
Procedure distinctValues;
Procedure textToArray;

Function arrayAssociatedValue( Const _1_p_tableau: Pointer): int64; overload;
Function arrayAssociatedValue( Const _1_y_ref: q4ref.TQ4Ref): int64; overload;
Procedure arrayAssociatedValue( Const _1_p_tableau: Pointer; Const _2_e_value: int64); overload;
Procedure arrayAssociatedValue( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_value: int64); overload;

Procedure q4arraysInitForThread;
Procedure q4arraysDoneForThread;

Implementation

Uses
  q4record,
  q4sets,
  q4triggerRuntime,
  q4coreRelations;

Type
  Pq4TextArray = ^Tq4TextArray;
  Pq4DateArray = ^Tq4DateArray;
  Pq4TimeArray = ^Tq4TimeArray;
  Pq4ObjectArray = ^Tq4ObjectArray;
  //Pq4LongintArray = ^Tq4LongintArray;
  Pq4Int64Array = ^Tq4Int64Array;
  Pq4RealArray = ^Tq4RealArray;
  Pq4BooleanArray = ^Tq4BooleanArray;
  Pq4BlobArray = ^Tq4BlobArray;
  Pq4PictureArray = ^Tq4PictureArray;

Const
  cq4SortAscendingValue = shortint( 1);
  cq4SortDescendingValue = shortint( -1);
  cq4SortSynchronizedValue = shortint( 0);

Type
  Tq4ResolvedSelectionSource = Record
    SourceTableName: string;
    TempTableName: string;
    PkFieldName: string;
    PkTypeSQL: string;
    ResultNo: int64;
    RecordCount: int64;
  End;

Threadvar
  gQ4ArrayAssociatedValues: Tq4ArrayAssociatedValues;

Procedure q4arraysInitForThread;
  Begin
    SetLength( gQ4ArrayAssociatedValues.ArrayRefs, 0);
    SetLength( gQ4ArrayAssociatedValues.Values, 0);
  End;

Function q4FindArrayAssociatedValueIndex( Const _1_p_tableau: Pointer): int64;
  Var
    i: int64;
  Begin
    For i := 0 To Length( gQ4ArrayAssociatedValues.ArrayRefs) - 1 Do If ( gQ4ArrayAssociatedValues.ArrayRefs[i] = _1_p_tableau) Then Exit( i);

    Result := -1;
  End;

Function q4FindOrAddArrayAssociatedValueIndex( Const _1_p_tableau: Pointer): int64;
  Begin
    Result := q4FindArrayAssociatedValueIndex( _1_p_tableau);
    If ( Result >= 0) Then Exit;

    Result := Length( gQ4ArrayAssociatedValues.ArrayRefs);

    SetLength( gQ4ArrayAssociatedValues.ArrayRefs, Result + 1);
    SetLength( gQ4ArrayAssociatedValues.Values, Result + 1);

    gQ4ArrayAssociatedValues.ArrayRefs[Result] := _1_p_tableau;
    gQ4ArrayAssociatedValues.Values[Result] := 0;
  End;

Procedure q4arraysDoneForThread;
  Begin
    SetLength( gQ4ArrayAssociatedValues.ArrayRefs, 0);
    SetLength( gQ4ArrayAssociatedValues.Values, 0);
  End;

Function q4DateFromString( Const _1_t_s: string): Tq4Date; Inline;
  Begin
    Result := _1_t_s;
  End;

Function q4TimeFromString( Const _1_t_s: string): Tq4Time; Inline;
  Begin
    Result := _1_t_s;
  End;

Function q4ArrayPhysicalLength( Const _1_e_eLogicalSize: int64): int64; Inline;
  Begin
    If ( _1_e_eLogicalSize < 0) Then Raise Exception.Create( 'q4arrays: taille de tableau négative interdite');

    Result := _1_e_eLogicalSize + 1;
  End;

Function q4ArrayLogicalLengthFromPhysical( Const _1_e_ePhysicalSize: int64): int64; Inline;
  Begin
    If ( _1_e_ePhysicalSize <= 0) Then Exit( 0);

    Result := _1_e_ePhysicalSize - 1;
  End;

Function q4Check4DIndex( Const _1_e_eIndex, _2_e_eLogicalSize: int64): int64; Inline;
  Begin
    If ( ( _1_e_eIndex < 1) or ( _1_e_eIndex > _2_e_eLogicalSize)) Then Raise Exception.CreateFmt( 'q4arrays: index 4D invalide (%d), taille logique=%d', [_1_e_eIndex, _2_e_eLogicalSize]);

    Result := _1_e_eIndex;
  End;

Function q4Check4DInsertIndex( Const _1_e_eIndex, _2_e_eLogicalSize: int64): int64; Inline;
  Begin
    If ( ( _1_e_eIndex < 1) or ( _1_e_eIndex > _2_e_eLogicalSize + 1)) Then Raise Exception.CreateFmt( 'q4arrays: index d''insertion 4D invalide (%d), taille logique=%d', [_1_e_eIndex, _2_e_eLogicalSize]);

    Result := _1_e_eIndex;
  End;

Function NormalizeSortOrder( Const _1_t_tOrder: string): shortint;
  Begin
    If ( _1_t_tOrder = q4SortAscending) Then Exit( cq4SortAscendingValue);
    If ( _1_t_tOrder = q4SortDescending) Then Exit( cq4SortDescendingValue);
    If ( _1_t_tOrder = q4SortSynchronized) Then Exit( cq4SortSynchronizedValue);

    Raise Exception.Create( 'q4arrays.NormalizeSortOrder: ordre invalide (attendu: ">", "<" ou "0")');
  End;

Function MakeArrayRef( Const _1_y_kind: Tq4ArrayKind; Const _2_p_data: Pointer): Tq4ArrayRef; Inline;
  Begin
    Result.Kind := _1_y_kind;
    Result.Data := _2_p_data;
  End;

Function MakeSortArrayRef( Const _1_y_ref: Tq4ArrayRef; Const _2_t_tOrder: string): Tq4SortArrayRef; Inline;
  Begin
    Result.Ref := _1_y_ref;
    Result.Order := NormalizeSortOrder( _2_t_tOrder);
  End;

Function q4RefToArrayRef( Const _1_y_ref: q4ref.TQ4Ref; Const _2_t_where: string): Tq4ArrayRef;
  Begin
    q4ref.requireTarget( _1_y_ref, q4ref.q4tkArray, _2_t_where);

    Case _1_y_ref.ValueKind Of
      q4ref.q4vkText: Result := MakeArrayRef( akText, _1_y_ref.Ptr);
      q4ref.q4vkDate: Result := MakeArrayRef( akDate, _1_y_ref.Ptr);
      q4ref.q4vkTime: Result := MakeArrayRef( akTime, _1_y_ref.Ptr);
      q4ref.q4vkObject: Result := MakeArrayRef( akObject, _1_y_ref.Ptr);
      q4ref.q4vkInteger, q4ref.q4vkInt64: Result := MakeArrayRef( akInt64, _1_y_ref.Ptr);
      q4ref.q4vkReal: Result := MakeArrayRef( akReal, _1_y_ref.Ptr);
      q4ref.q4vkBoolean: Result := MakeArrayRef( akBoolean, _1_y_ref.Ptr);
      q4ref.q4vkBlob: Result := MakeArrayRef( akBlob, _1_y_ref.Ptr);
      q4ref.q4vkPointer: Result := MakeArrayRef( akPointer, _1_y_ref.Ptr);
      q4ref.q4vkPicture: Result := MakeArrayRef( akPicture, _1_y_ref.Ptr);
      Else Raise Exception.Create( _2_t_where + ': type de tableau non supporté : ' + q4ref.valueKindName( _1_y_ref.ValueKind));
    End;
  End;

Procedure q4RequireArrayKind( Const _1_y_ref: q4ref.TQ4Ref; Const _2_y_kind: Tq4ArrayKind; Const _3_t_where: string); Inline;
  Var
    R: Tq4ArrayRef;
  Begin
    R := q4RefToArrayRef( _1_y_ref, _3_t_where);
    If ( R.Kind <> _2_y_kind) Then Raise Exception.Create( _3_t_where + ': type de tableau incompatible');
  End;

Function SortArrayRef( Const _1_y_ref: q4ref.TQ4Ref; Const _2_t_order: string): Tq4SortArrayRef; Inline;
  Begin
    Result := MakeSortArrayRef( q4RefToArrayRef( _1_y_ref, 'SortArrayRef'), _2_t_order);
  End;

Function selectionArrayRequest( Const _1_p_fieldPtr: Pointer; Const _2_y_target: q4ref.TQ4Ref): Tq4selectionArrayRequest; Inline;
  Begin
    Result.FieldPtr := _1_p_fieldPtr;
    Result.Target := q4RefToArrayRef( _2_y_target, 'selectionArrayRequest');
  End;

Function arrayToSelectionBinding( Const _1_p_fieldPtr: Pointer; Const _2_y_source: q4ref.TQ4Ref): Tq4ArrayToSelectionBinding; Inline;
  Begin
    Result.FieldPtr := _1_p_fieldPtr;
    Result.Source := q4RefToArrayRef( _2_y_source, 'arrayToSelectionBinding');
  End;

Function InternalFieldToBytes( Const _1_y_field: TField): TBytes;
  Var
    eStream: TMemoryStream;
  Begin
    SetLength( Result, 0);

    If ( _1_y_field.IsNull) Then Exit;

    q4interruptions.assertRaise(
      _1_y_field is TBlobField,
      'q4arrays.InternalFieldToBytes : champ non Blob'
      );

    eStream := TMemoryStream.Create;
    Try
      TBlobField( _1_y_field).SaveToStream( eStream);
      SetLength( Result, eStream.Size);
      If ( eStream.Size > 0) Then Begin
        eStream.Position := 0;
        eStream.ReadBuffer( Result[0], eStream.Size);
      End;
    Finally
      eStream.Free;
    End;
  End;

Function TextArray( Var _1_tt_a: Tq4TextArray): Tq4ArrayRef; Inline;
  Begin
    Result := MakeArrayRef( akText, @_1_tt_a);
  End;

Function DateArray( Var _1_te_a: Tq4DateArray): Tq4ArrayRef; Inline;
  Begin
    Result := MakeArrayRef( akDate, @_1_te_a);
  End;

Function TimeArray( Var _1_te_a: Tq4TimeArray): Tq4ArrayRef; Inline;
  Begin
    Result := MakeArrayRef( akTime, @_1_te_a);
  End;

Function ObjectArray( Var _1_to_a: Tq4ObjectArray): Tq4ArrayRef; Inline;
  Begin
    Result := MakeArrayRef( akObject, @_1_to_a);
  End;

//function LongintArray(var A: Tq4LongintArray): Tq4ArrayRef; inline;
//begin
//  Result := MakeArrayRef(akLongint, @A);
//end;

Function Int64Array( Var _1_te_a: Tq4Int64Array): Tq4ArrayRef; Inline;
  Begin
    Result := MakeArrayRef( akInt64, @_1_te_a);
  End;

Function RealArray( Var _1_tr_a: Tq4RealArray): Tq4ArrayRef; Inline;
  Begin
    Result := MakeArrayRef( akReal, @_1_tr_a);
  End;

Function BooleanArray( Var _1_tb_a: Tq4BooleanArray): Tq4ArrayRef; Inline;
  Begin
    Result := MakeArrayRef( akBoolean, @_1_tb_a);
  End;

Function BlobArray( Var _1_ty_a: Tq4BlobArray): Tq4ArrayRef; Inline;
  Begin
    Result := MakeArrayRef( akBlob, @_1_ty_a);
  End;

Function PointerArray( Var _1_tp_a: Tq4PointerArray): Tq4ArrayRef; Inline;
  Begin
    Result := MakeArrayRef( akPointer, @_1_tp_a);
  End;

Function PictureArray( Var _1_ty_a: Tq4PictureArray): Tq4ArrayRef; Inline;
  Begin
    Result := MakeArrayRef( akPicture, @_1_ty_a);
  End;

Function TextArrayRef( Var _1_tt_a: Tq4TextArray; Const _2_t_order: string): Tq4SortArrayRef; Inline;
  Begin
    Result := MakeSortArrayRef( TextArray( _1_tt_a), _2_t_order);
  End;

Function DateArrayRef( Var _1_te_a: Tq4DateArray; Const _2_t_order: string): Tq4SortArrayRef; Inline;
  Begin
    Result := MakeSortArrayRef( DateArray( _1_te_a), _2_t_order);
  End;

Function TimeArrayRef( Var _1_te_a: Tq4TimeArray; Const _2_t_order: string): Tq4SortArrayRef; Inline;
  Begin
    Result := MakeSortArrayRef( TimeArray( _1_te_a), _2_t_order);
  End;

Function ObjectArrayRef( Var _1_to_a: Tq4ObjectArray; Const _2_t_order: string): Tq4SortArrayRef; Inline;
  Begin
    Result := MakeSortArrayRef( ObjectArray( _1_to_a), _2_t_order);
  End;

//function LongintArrayRef(var A: Tq4LongintArray; const Order: string): Tq4SortArrayRef; inline;
//begin
//  Result := MakeSortArrayRef(LongintArray(A), Order);
//end;

Function int64ArrayRef( Var _1_te_a: Tq4Int64Array; Const _2_t_order: string): Tq4SortArrayRef; Inline;
  Begin
    Result := MakeSortArrayRef( Int64Array( _1_te_a), _2_t_order);
  End;

Function realArrayRef( Var _1_tr_a: Tq4RealArray; Const _2_t_order: string): Tq4SortArrayRef; Inline;
  Begin
    Result := MakeSortArrayRef( RealArray( _1_tr_a), _2_t_order);
  End;

Function booleanArrayRef( Var _1_tb_a: Tq4BooleanArray; Const _2_t_order: string): Tq4SortArrayRef; Inline;
  Begin
    Result := MakeSortArrayRef( BooleanArray( _1_tb_a), _2_t_order);
  End;

Function BlobArrayRef( Var _1_ty_a: Tq4BlobArray; Const _2_t_order: string): Tq4SortArrayRef; Inline;
  Begin
    Result := MakeSortArrayRef( BlobArray( _1_ty_a), _2_t_order);
  End;

Function PictureArrayRef( Var _1_ty_a: Tq4PictureArray; Const _2_t_order: string): Tq4SortArrayRef; Inline;
  Begin
    Result := MakeSortArrayRef( PictureArray( _1_ty_a), _2_t_order);
  End;

Function PointerArrayRef( Var _1_tp_a: Tq4PointerArray; Const _2_t_order: string): Tq4SortArrayRef; Inline;
  Begin
    Result := MakeSortArrayRef( PointerArray( _1_tp_a), _2_t_order);
  End;

Function getArrayLength( Const _1_y_ref: Tq4ArrayRef): int64;
  Begin
    Case _1_y_ref.Kind Of
      akText: Result := Length( Pq4TextArray( _1_y_ref.Data)^);
      akDate: Result := Length( Pq4DateArray( _1_y_ref.Data)^);
      akTime: Result := Length( Pq4TimeArray( _1_y_ref.Data)^);
      akObject: Result := Length( Pq4ObjectArray( _1_y_ref.Data)^);
      //akLongint: Result := Length(Pq4LongintArray(Ref.Data)^);
      akInt64: Result := Length( Pq4Int64Array( _1_y_ref.Data)^);
      akReal: Result := Length( Pq4RealArray( _1_y_ref.Data)^);
      akBoolean: Result := Length( Pq4BooleanArray( _1_y_ref.Data)^);
      akBlob: Result := Length( Pq4BlobArray( _1_y_ref.Data)^);
      akPicture: Result := Length( Pq4PictureArray( _1_y_ref.Data)^);
      akPointer: Raise Exception.Create( 'q4arrays.GetArrayLength: tableaux Pointer non triables');
      Else Raise Exception.Create( 'q4arrays.GetArrayLength: type de tableau non supporté');
    End;
  End;

Procedure arrayText( Var _1_tt_a: Tq4TextArray; Const _2_e_eSize: int64);
  Begin
    SetLength( _1_tt_a, q4ArrayPhysicalLength( _2_e_eSize));
  End;

Procedure arrayDate( Var _1_te_a: Tq4DateArray; Const _2_e_eSize: int64);
  Begin
    SetLength( _1_te_a, q4ArrayPhysicalLength( _2_e_eSize));
  End;

Procedure arrayTime( Var _1_te_a: Tq4TimeArray; Const _2_e_eSize: int64);
  Begin
    SetLength( _1_te_a, q4ArrayPhysicalLength( _2_e_eSize));
  End;

Procedure arrayObject( Var _1_to_a: Tq4ObjectArray; Const _2_e_eSize: int64);
  Begin
    SetLength( _1_to_a, q4ArrayPhysicalLength( _2_e_eSize));
  End;

Procedure arrayLongint( Var _1_te_a: Tq4Int64Array; Const _2_e_eSize: int64);
  Begin
    SetLength( _1_te_a, q4ArrayPhysicalLength( _2_e_eSize));
  End;

Procedure arrayInteger( Var _1_te_a: Tq4Int64Array; Const _2_e_eSize: int64);
  Begin
    SetLength( _1_te_a, q4ArrayPhysicalLength( _2_e_eSize));
  End;

Procedure arrayReal( Var _1_tr_a: Tq4RealArray; Const _2_e_eSize: int64);
  Begin
    SetLength( _1_tr_a, q4ArrayPhysicalLength( _2_e_eSize));
  End;

Procedure arrayBoolean( Var _1_tb_a: Tq4BooleanArray; Const _2_e_eSize: int64);
  Begin
    SetLength( _1_tb_a, q4ArrayPhysicalLength( _2_e_eSize));
  End;

Procedure arrayBlob( Var _1_ty_a: Tq4BlobArray; Const _2_e_eSize: int64);
  Begin
    SetLength( _1_ty_a, q4ArrayPhysicalLength( _2_e_eSize));
  End;

Procedure arrayPointer( Var _1_tp_a: Tq4PointerArray; Const _2_e_eSize: int64);
  Begin
    SetLength( _1_tp_a, q4ArrayPhysicalLength( _2_e_eSize));
  End;

Procedure arrayPicture( Var _1_ty_a: Tq4PictureArray; Const _2_e_eSize: int64);
  Begin
    SetLength( _1_ty_a, q4ArrayPhysicalLength( _2_e_eSize));
  End;

Procedure arrayText( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64);
  Begin
    q4RequireArrayKind( _1_y_ref, akText, 'arrayText');
    arrayText( q4ref.Pq4TextArray( _1_y_ref.Ptr)^, _2_e_eSize);
  End;

Procedure arrayDate( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64);
  Begin
    q4RequireArrayKind( _1_y_ref, akDate, 'arrayDate');
    arrayDate( q4ref.Pq4DateArray( _1_y_ref.Ptr)^, _2_e_eSize);
  End;

Procedure arrayTime( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64);
  Begin
    q4RequireArrayKind( _1_y_ref, akTime, 'arrayTime');
    arrayTime( q4ref.Pq4TimeArray( _1_y_ref.Ptr)^, _2_e_eSize);
  End;

Procedure arrayObject( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64);
  Begin
    q4RequireArrayKind( _1_y_ref, akObject, 'arrayObject');
    arrayObject( q4ref.Pq4ObjectArray( _1_y_ref.Ptr)^, _2_e_eSize);
  End;

Procedure arrayLongint( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64);
  Begin
    q4RequireArrayKind( _1_y_ref, akInt64, 'arrayLongint');
    arrayLongint( q4ref.Pq4Int64Array( _1_y_ref.Ptr)^, _2_e_eSize);
  End;

Procedure arrayInteger( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64);
  Begin
    q4RequireArrayKind( _1_y_ref, akInt64, 'arrayInteger');
    arrayInteger( q4ref.Pq4Int64Array( _1_y_ref.Ptr)^, _2_e_eSize);
  End;

Procedure arrayReal( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64);
  Begin
    q4RequireArrayKind( _1_y_ref, akReal, 'arrayReal');
    arrayReal( q4ref.Pq4RealArray( _1_y_ref.Ptr)^, _2_e_eSize);
  End;

Procedure arrayBoolean( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64);
  Begin
    q4RequireArrayKind( _1_y_ref, akBoolean, 'arrayBoolean');
    arrayBoolean( q4ref.Pq4BooleanArray( _1_y_ref.Ptr)^, _2_e_eSize);
  End;

Procedure arrayBlob( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64);
  Begin
    q4RequireArrayKind( _1_y_ref, akBlob, 'arrayBlob');
    arrayBlob( q4ref.Pq4BlobArray( _1_y_ref.Ptr)^, _2_e_eSize);
  End;

Procedure arrayPointer( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64);
  Begin
    q4RequireArrayKind( _1_y_ref, akPointer, 'arrayPointer');
    arrayPointer( q4ref.Pq4PointerArray( _1_y_ref.Ptr)^, _2_e_eSize);
  End;

Procedure arrayPicture( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64);
  Begin
    q4RequireArrayKind( _1_y_ref, akPicture, 'arrayPicture');
    arrayPicture( q4ref.Pq4PictureArray( _1_y_ref.Ptr)^, _2_e_eSize);
  End;

Function sizeOfArray( Const _1_tt_a: Tq4TextArray): int64;
  Begin
    Result := q4ArrayLogicalLengthFromPhysical( Length( _1_tt_a));
  End;

Function sizeOfArray( Const _1_te_a: Tq4DateArray): int64;
  Begin
    Result := q4ArrayLogicalLengthFromPhysical( Length( _1_te_a));
  End;

Function sizeOfArray( Const _1_te_a: Tq4TimeArray): int64;
  Begin
    Result := q4ArrayLogicalLengthFromPhysical( Length( _1_te_a));
  End;

Function sizeOfArray( Const _1_to_a: Tq4ObjectArray): int64;
  Begin
    Result := q4ArrayLogicalLengthFromPhysical( Length( _1_to_a));
  End;

//function sizeOfArray(const A: Tq4LongintArray): Int64;
//begin
//  Result := q4ArrayLogicalLengthFromPhysical(Length(A));
//end;

Function sizeOfArray( Const _1_te_a: Tq4Int64Array): int64;
  Begin
    Result := q4ArrayLogicalLengthFromPhysical( Length( _1_te_a));
  End;

Function sizeOfArray( Const _1_tr_a: Tq4RealArray): int64;
  Begin
    Result := q4ArrayLogicalLengthFromPhysical( Length( _1_tr_a));
  End;

Function sizeOfArray( Const _1_tb_a: Tq4BooleanArray): int64;
  Begin
    Result := q4ArrayLogicalLengthFromPhysical( Length( _1_tb_a));
  End;

Function sizeOfArray( Const _1_ty_a: Tq4BlobArray): int64;
  Begin
    Result := q4ArrayLogicalLengthFromPhysical( Length( _1_ty_a));
  End;

Function sizeOfArray( Const _1_tp_a: Tq4PointerArray): int64;
  Begin
    Result := q4ArrayLogicalLengthFromPhysical( Length( _1_tp_a));
  End;

Function sizeOfArray( Const _1_ty_a: Tq4PictureArray): int64;
  Begin
    Result := q4ArrayLogicalLengthFromPhysical( Length( _1_ty_a));
  End;

Function sizeOfArray( Const _1_y_ref: q4ref.TQ4Ref): int64;
  Begin
    Case q4RefToArrayRef( _1_y_ref, 'sizeOfArray').Kind Of
      akText: Result := sizeOfArray( q4ref.Pq4TextArray( _1_y_ref.Ptr)^);
      akDate: Result := sizeOfArray( q4ref.Pq4DateArray( _1_y_ref.Ptr)^);
      akTime: Result := sizeOfArray( q4ref.Pq4TimeArray( _1_y_ref.Ptr)^);
      akObject: Result := sizeOfArray( q4ref.Pq4ObjectArray( _1_y_ref.Ptr)^);
      akInt64: Result := sizeOfArray( q4ref.Pq4Int64Array( _1_y_ref.Ptr)^);
      akReal: Result := sizeOfArray( q4ref.Pq4RealArray( _1_y_ref.Ptr)^);
      akBoolean: Result := sizeOfArray( q4ref.Pq4BooleanArray( _1_y_ref.Ptr)^);
      akBlob: Result := sizeOfArray( q4ref.Pq4BlobArray( _1_y_ref.Ptr)^);
      akPointer: Result := sizeOfArray( q4ref.Pq4PointerArray( _1_y_ref.Ptr)^);
      akPicture: Result := sizeOfArray( q4ref.Pq4PictureArray( _1_y_ref.Ptr)^);
      Else Raise Exception.Create( 'sizeOfArray: type de tableau non supporté');
    End;
  End;

Function sizeOfArray( Const _1_y_ref: Tq4ArrayRef): int64;
  Begin
    Case _1_y_ref.Kind Of
      akText: Result := sizeOfArray( Pq4TextArray( _1_y_ref.Data)^);
      akDate: Result := sizeOfArray( Pq4DateArray( _1_y_ref.Data)^);
      akTime: Result := sizeOfArray( Pq4TimeArray( _1_y_ref.Data)^);
      akObject: Result := sizeOfArray( Pq4ObjectArray( _1_y_ref.Data)^);
      akInt64: Result := sizeOfArray( Pq4Int64Array( _1_y_ref.Data)^);
      akReal: Result := sizeOfArray( Pq4RealArray( _1_y_ref.Data)^);
      akBoolean: Result := sizeOfArray( Pq4BooleanArray( _1_y_ref.Data)^);
      akBlob: Result := sizeOfArray( Pq4BlobArray( _1_y_ref.Data)^);
      akPointer: Result := sizeOfArray( Pq4PointerArray( _1_y_ref.Data)^);
      akPicture: Result := sizeOfArray( Pq4PictureArray( _1_y_ref.Data)^);
      Else q4interruptions.assertRaise(
          'sizeOfArray(Tq4ArrayRef): unsupported array kind.',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
        Result := 0;
    End;
  End;

Procedure arraySetSize( Const _1_y_ref: Tq4ArrayRef; Const _2_e_eSize: int64);
  Begin
    Case _1_y_ref.Kind Of
      akText: arrayText( Pq4TextArray( _1_y_ref.Data)^, _2_e_eSize);
      akDate: arrayDate( Pq4DateArray( _1_y_ref.Data)^, _2_e_eSize);
      akTime: arrayTime( Pq4TimeArray( _1_y_ref.Data)^, _2_e_eSize);
      akObject: arrayObject( Pq4ObjectArray( _1_y_ref.Data)^, _2_e_eSize);
      akInt64: arrayLongint( Pq4Int64Array( _1_y_ref.Data)^, _2_e_eSize);
      akReal: arrayReal( Pq4RealArray( _1_y_ref.Data)^, _2_e_eSize);
      akBoolean: arrayBoolean( Pq4BooleanArray( _1_y_ref.Data)^, _2_e_eSize);
      akBlob: arrayBlob( Pq4BlobArray( _1_y_ref.Data)^, _2_e_eSize);
      akPointer: arrayPointer( Pq4PointerArray( _1_y_ref.Data)^, _2_e_eSize);
      akPicture: arrayPicture( Pq4PictureArray( _1_y_ref.Data)^, _2_e_eSize);
      Else q4interruptions.assertRaise(
          'arraySetSize: unsupported array kind.',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
    End;
  End;

Procedure arraySetSize( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eSize: int64);
  Begin
    q4arrays.arraySetSize( q4arrays.q4RefToArrayRef( _1_y_ref, 'arraySetSize'), _2_e_eSize);
  End;

Function arrayItemToValue( Const _1_y_ref: Tq4ArrayRef; Const _2_e_eIndex4D: int64): q4objectsLanguage.Tq4Value;
  Var
    _e_index: int64;
  Begin
    Result := q4objectsLanguage.q4Undefined;

    _e_index := q4Check4DIndex( _2_e_eIndex4D, q4arrays.sizeOfArray( _1_y_ref));

    Case _1_y_ref.Kind Of
      akText: Result := Pq4TextArray( _1_y_ref.Data)^[_e_index];
      akDate: Result := q4objectsLanguage.q4DateValue( Pq4DateArray( _1_y_ref.Data)^[_e_index]);
      akTime: Result := q4objectsLanguage.q4TimeValue( Pq4TimeArray( _1_y_ref.Data)^[_e_index]);
      akInt64: Result := Pq4Int64Array( _1_y_ref.Data)^[_e_index];
      akReal: Result := Pq4RealArray( _1_y_ref.Data)^[_e_index];
      akBoolean: Result := Pq4BooleanArray( _1_y_ref.Data)^[_e_index];
      Else q4interruptions.assertRaise(
          'arrayItemToValue: this array kind is TODO for q4collections.',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
    End;
  End;

Function arrayItemToValue( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eIndex4D: int64): q4objectsLanguage.Tq4Value;
  Begin
    Result := q4arrays.arrayItemToValue( q4arrays.q4RefToArrayRef( _1_y_ref, 'arrayItemToValue'), _2_e_eIndex4D);
  End;

Procedure arraySetItemFromValue( Const _1_y_ref: Tq4ArrayRef; Const _2_e_eIndex4D: int64; Const _3_y_vValue: q4objectsLanguage.Tq4Value);
  Var
    _e_index: int64;
  Begin
    _e_index := q4Check4DIndex( _2_e_eIndex4D, q4arrays.sizeOfArray( _1_y_ref));

    Case _1_y_ref.Kind Of
      akText: Pq4TextArray( _1_y_ref.Data)^[_e_index] := _3_y_vValue.asText;
      akDate: Pq4DateArray( _1_y_ref.Data)^[_e_index] := q4coreLanguage.Tq4Date( _3_y_vValue.asDate);
      akTime: Pq4TimeArray( _1_y_ref.Data)^[_e_index] := q4coreLanguage.Tq4Time( _3_y_vValue.asTime);
      akInt64: Pq4Int64Array( _1_y_ref.Data)^[_e_index] := _3_y_vValue.AsInteger;
      akReal: Pq4RealArray( _1_y_ref.Data)^[_e_index] := _3_y_vValue.asReal;
      akBoolean: Pq4BooleanArray( _1_y_ref.Data)^[_e_index] := _3_y_vValue.AsBoolean;
      Else q4interruptions.assertRaise(
          'arraySetItemFromValue: this array kind is TODO for q4collections.',
          {$I %CURRENTROUTINE%},
          {$I %LINENUM%}
          );
    End;
  End;

Procedure arraySetItemFromValue( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eIndex4D: int64; Const _3_y_vValue: q4objectsLanguage.Tq4Value);
  Begin
    q4arrays.arraySetItemFromValue( q4arrays.q4RefToArrayRef( _1_y_ref, 'arraySetItemFromValue'), _2_e_eIndex4D, _3_y_vValue);
  End;

Procedure appendToArray( Var _1_tt_a: Tq4TextArray; Const _2_t_eValue: string);
  Var
    ePos: int64;
  Begin
    ePos := Length( _1_tt_a);
    SetLength( _1_tt_a, ePos + 1);
    _1_tt_a[ePos] := _2_t_eValue;
  End;

//procedure appendToArray(var A: Tq4LongintArray; const eValue: longint);
//var
//  ePos: Int64;
//begin
//  ePos := Length(A);
//  SetLength(A, ePos + 1);
//  A[ePos] := eValue;
//end;

Procedure appendToArray( Var _1_te_a: Tq4Int64Array; Const _2_e_eValue: int64);
  Var
    ePos: int64;
  Begin
    ePos := Length( _1_te_a);
    SetLength( _1_te_a, ePos + 1);
    _1_te_a[ePos] := _2_e_eValue;
  End;

Procedure appendToArray( Var _1_tr_a: Tq4RealArray; Const _2_r_eValue: double);
  Var
    ePos: int64;
  Begin
    ePos := Length( _1_tr_a);
    SetLength( _1_tr_a, ePos + 1);
    _1_tr_a[ePos] := _2_r_eValue;
  End;

Procedure appendToArray( Var _1_tb_a: Tq4BooleanArray; Const _2_b_eValue: boolean);
  Var
    ePos: int64;
  Begin
    ePos := Length( _1_tb_a);
    SetLength( _1_tb_a, ePos + 1);
    _1_tb_a[ePos] := _2_b_eValue;
  End;

Procedure appendToArray( Var _1_te_a: Tq4DateArray; Const _2_t_eValue: string);
  Var
    ePos: int64;
  Begin
    ePos := Length( _1_te_a);
    SetLength( _1_te_a, ePos + 1);
    _1_te_a[ePos] := _2_t_eValue;
  End;

Procedure appendToArray( Var _1_te_a: Tq4TimeArray; Const _2_t_eValue: string);
  Var
    ePos: int64;
  Begin
    ePos := Length( _1_te_a);
    SetLength( _1_te_a, ePos + 1);
    _1_te_a[ePos] := _2_t_eValue;
  End;

Procedure appendToArray( Var _1_to_a: Tq4ObjectArray; Const _2_o_eValue: Tq4JSONObject);
  Var
    ePos: int64;
  Begin
    ePos := Length( _1_to_a);
    SetLength( _1_to_a, ePos + 1);
    _1_to_a[ePos] := _2_o_eValue;
  End;

Procedure appendToArray( Var _1_ty_a: Tq4BlobArray; Const _2_by_eValue: TBytes);
  Var
    ePos: int64;
  Begin
    ePos := Length( _1_ty_a);
    SetLength( _1_ty_a, ePos + 1);
    _1_ty_a[ePos] := Copy( _2_by_eValue);
  End;

Procedure appendToArray( Var _1_tp_a: Tq4PointerArray; Const _2_p_eValue: Pointer);
  Var
    ePos: int64;
  Begin
    ePos := Length( _1_tp_a);
    SetLength( _1_tp_a, ePos + 1);
    _1_tp_a[ePos] := _2_p_eValue;
  End;

Procedure appendToArray( Var _1_ty_a: Tq4PictureArray; Const _2_o_eValue: Tq4Picture);
  Var
    ePos: int64;
  Begin
    ePos := Length( _1_ty_a);
    SetLength( _1_ty_a, ePos + 1);
    _1_ty_a[ePos] := _2_o_eValue;
  End;

Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_t_eValue: string);
  Begin
    Case q4RefToArrayRef( _1_y_ref, 'appendToArray').Kind Of
      akText: appendToArray( q4ref.Pq4TextArray( _1_y_ref.Ptr)^, _2_t_eValue);
      akDate: appendToArray( q4ref.Pq4DateArray( _1_y_ref.Ptr)^, Tq4Date( _2_t_eValue));
      akTime: appendToArray( q4ref.Pq4TimeArray( _1_y_ref.Ptr)^, Tq4Time( _2_t_eValue));
      Else Raise Exception.Create( 'appendToArray: tableau texte/date/time attendu');
    End;
  End;

Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_y_eValue: Tq4Date);
  Begin
    q4RequireArrayKind( _1_y_ref, akDate, 'appendToArray');
    appendToArray( q4ref.Pq4DateArray( _1_y_ref.Ptr)^, _2_y_eValue);
  End;

Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_y_eValue: Tq4Time);
  Begin
    q4RequireArrayKind( _1_y_ref, akTime, 'appendToArray');
    appendToArray( q4ref.Pq4TimeArray( _1_y_ref.Ptr)^, _2_y_eValue);
  End;

Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_o_eValue: Tq4JSONObject);
  Begin
    q4RequireArrayKind( _1_y_ref, akObject, 'appendToArray');
    appendToArray( q4ref.Pq4ObjectArray( _1_y_ref.Ptr)^, _2_o_eValue);
  End;

Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eValue: int64);
  Begin
    q4RequireArrayKind( _1_y_ref, akInt64, 'appendToArray');
    appendToArray( q4ref.Pq4Int64Array( _1_y_ref.Ptr)^, _2_e_eValue);
  End;

Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_r_eValue: double);
  Begin
    q4RequireArrayKind( _1_y_ref, akReal, 'appendToArray');
    appendToArray( q4ref.Pq4RealArray( _1_y_ref.Ptr)^, _2_r_eValue);
  End;

Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_b_eValue: boolean);
  Begin
    q4RequireArrayKind( _1_y_ref, akBoolean, 'appendToArray');
    appendToArray( q4ref.Pq4BooleanArray( _1_y_ref.Ptr)^, _2_b_eValue);
  End;

Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_by_eValue: TBytes);
  Var
    ePos: int64;
    pPictureArray: q4ref.Pq4PictureArray;
  Begin
    Case q4RefToArrayRef( _1_y_ref, 'appendToArray').Kind Of
      akBlob: appendToArray( q4ref.Pq4BlobArray( _1_y_ref.Ptr)^, _2_by_eValue);

      akPicture: Begin
        pPictureArray := q4ref.Pq4PictureArray( _1_y_ref.Ptr);
        ePos := Length( pPictureArray^);
        SetLength( pPictureArray^, ePos + 1);
        pPictureArray^[ePos] := Copy( _2_by_eValue);
      End;
      Else Raise Exception.Create( 'appendToArray: tableau Blob ou Picture attendu');
    End;
  End;

Procedure appendToArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_p_eValue: Pointer);
  Begin
    q4RequireArrayKind( _1_y_ref, akPointer, 'appendToArray');
    appendToArray( q4ref.Pq4PointerArray( _1_y_ref.Ptr)^, _2_p_eValue);
  End;

Procedure deleteFromArray( Var _1_tt_a: Tq4TextArray; Const _2_e_eIndex4D: int64);
  Var
    i, eLogicalSize: int64;
  Begin
    eLogicalSize := sizeOfArray( _1_tt_a);
    q4Check4DIndex( _2_e_eIndex4D, eLogicalSize);

    For i := _2_e_eIndex4D To eLogicalSize - 1 Do _1_tt_a[i] := _1_tt_a[i + 1];

    SetLength( _1_tt_a, Length( _1_tt_a) - 1);
  End;

//procedure deleteFromArray(var A: Tq4LongintArray; const eIndex4D: Int64);
//var
//  i, eLogicalSize: Int64;
//begin
//  eLogicalSize := sizeOfArray(A);
//  q4Check4DIndex(eIndex4D, eLogicalSize);

//  for i := eIndex4D to eLogicalSize - 1 do A[i] := A[i + 1];

//  SetLength(A, Length(A) - 1);
//end;

Procedure deleteFromArray( Var _1_te_a: Tq4Int64Array; Const _2_e_eIndex4D: int64);
  Var
    i, eLogicalSize: int64;
  Begin
    eLogicalSize := sizeOfArray( _1_te_a);
    q4Check4DIndex( _2_e_eIndex4D, eLogicalSize);

    For i := _2_e_eIndex4D To eLogicalSize - 1 Do _1_te_a[i] := _1_te_a[i + 1];

    SetLength( _1_te_a, Length( _1_te_a) - 1);
  End;

Procedure deleteFromArray( Var _1_tr_a: Tq4RealArray; Const _2_e_eIndex4D: int64);
  Var
    i, eLogicalSize: int64;
  Begin
    eLogicalSize := sizeOfArray( _1_tr_a);
    q4Check4DIndex( _2_e_eIndex4D, eLogicalSize);

    For i := _2_e_eIndex4D To eLogicalSize - 1 Do _1_tr_a[i] := _1_tr_a[i + 1];

    SetLength( _1_tr_a, Length( _1_tr_a) - 1);
  End;

Procedure deleteFromArray( Var _1_tb_a: Tq4BooleanArray; Const _2_e_eIndex4D: int64);
  Var
    i, eLogicalSize: int64;
  Begin
    eLogicalSize := sizeOfArray( _1_tb_a);
    q4Check4DIndex( _2_e_eIndex4D, eLogicalSize);

    For i := _2_e_eIndex4D To eLogicalSize - 1 Do _1_tb_a[i] := _1_tb_a[i + 1];

    SetLength( _1_tb_a, Length( _1_tb_a) - 1);
  End;

Procedure deleteFromArray( Var _1_te_a: Tq4DateArray; Const _2_e_eIndex4D: int64);
  Var
    i, eLogicalSize: int64;
  Begin
    eLogicalSize := sizeOfArray( _1_te_a);
    q4Check4DIndex( _2_e_eIndex4D, eLogicalSize);

    For i := _2_e_eIndex4D To eLogicalSize - 1 Do _1_te_a[i] := _1_te_a[i + 1];

    SetLength( _1_te_a, Length( _1_te_a) - 1);
  End;

Procedure deleteFromArray( Var _1_te_a: Tq4TimeArray; Const _2_e_eIndex4D: int64);
  Var
    i, eLogicalSize: int64;
  Begin
    eLogicalSize := sizeOfArray( _1_te_a);
    q4Check4DIndex( _2_e_eIndex4D, eLogicalSize);

    For i := _2_e_eIndex4D To eLogicalSize - 1 Do _1_te_a[i] := _1_te_a[i + 1];

    SetLength( _1_te_a, Length( _1_te_a) - 1);
  End;

Procedure deleteFromArray( Var _1_to_a: Tq4ObjectArray; Const _2_e_eIndex4D: int64);
  Var
    i, eLogicalSize: int64;
  Begin
    eLogicalSize := sizeOfArray( _1_to_a);
    q4Check4DIndex( _2_e_eIndex4D, eLogicalSize);

    For i := _2_e_eIndex4D To eLogicalSize - 1 Do _1_to_a[i] := _1_to_a[i + 1];

    SetLength( _1_to_a, Length( _1_to_a) - 1);
  End;

Procedure deleteFromArray( Var _1_ty_a: Tq4BlobArray; Const _2_e_eIndex4D: int64);
  Var
    i, eLogicalSize: int64;
  Begin
    eLogicalSize := sizeOfArray( _1_ty_a);
    q4Check4DIndex( _2_e_eIndex4D, eLogicalSize);

    For i := _2_e_eIndex4D To eLogicalSize - 1 Do _1_ty_a[i] := Copy( _1_ty_a[i + 1]);

    SetLength( _1_ty_a, Length( _1_ty_a) - 1);
  End;

Procedure deleteFromArray( Var _1_tp_a: Tq4PointerArray; Const _2_e_eIndex4D: int64);
  Var
    i, eLogicalSize: int64;
  Begin
    eLogicalSize := sizeOfArray( _1_tp_a);
    q4Check4DIndex( _2_e_eIndex4D, eLogicalSize);

    For i := _2_e_eIndex4D To eLogicalSize - 1 Do _1_tp_a[i] := _1_tp_a[i + 1];

    SetLength( _1_tp_a, Length( _1_tp_a) - 1);
  End;

Procedure deleteFromArray( Var _1_ty_a: Tq4PictureArray; Const _2_e_eIndex4D: int64);
  Var
    i, eLogicalSize: int64;
  Begin
    eLogicalSize := sizeOfArray( _1_ty_a);
    q4Check4DIndex( _2_e_eIndex4D, eLogicalSize);

    For i := _2_e_eIndex4D To eLogicalSize - 1 Do _1_ty_a[i] := _1_ty_a[i + 1];

    SetLength( _1_ty_a, Length( _1_ty_a) - 1);
  End;

Procedure deleteFromArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eIndex4D: int64);
  Begin
    Case q4RefToArrayRef( _1_y_ref, 'deleteFromArray').Kind Of
      akText: deleteFromArray( q4ref.Pq4TextArray( _1_y_ref.Ptr)^, _2_e_eIndex4D);
      akDate: deleteFromArray( q4ref.Pq4DateArray( _1_y_ref.Ptr)^, _2_e_eIndex4D);
      akTime: deleteFromArray( q4ref.Pq4TimeArray( _1_y_ref.Ptr)^, _2_e_eIndex4D);
      akObject: deleteFromArray( q4ref.Pq4ObjectArray( _1_y_ref.Ptr)^, _2_e_eIndex4D);
      akInt64: deleteFromArray( q4ref.Pq4Int64Array( _1_y_ref.Ptr)^, _2_e_eIndex4D);
      akReal: deleteFromArray( q4ref.Pq4RealArray( _1_y_ref.Ptr)^, _2_e_eIndex4D);
      akBoolean: deleteFromArray( q4ref.Pq4BooleanArray( _1_y_ref.Ptr)^, _2_e_eIndex4D);
      akBlob: deleteFromArray( q4ref.Pq4BlobArray( _1_y_ref.Ptr)^, _2_e_eIndex4D);
      akPointer: deleteFromArray( q4ref.Pq4PointerArray( _1_y_ref.Ptr)^, _2_e_eIndex4D);
      akPicture: deleteFromArray( q4ref.Pq4PictureArray( _1_y_ref.Ptr)^, _2_e_eIndex4D);
      Else Raise Exception.Create( 'deleteFromArray: type de tableau non supporté');
    End;
  End;

Procedure insertInArray( Var _1_tt_a: Tq4TextArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64);
  Var
    i, eLogicalSize: int64;
    eEmpty: Tq4TextArray;
  Begin
    If ( _3_e_eHowMany < 0) Then Raise Exception.Create( 'insertInArray: nombre d''éléments négatif interdit');
    If ( _3_e_eHowMany = 0) Then Exit;

    eLogicalSize := sizeOfArray( _1_tt_a);
    q4Check4DInsertIndex( _2_e_eIndex4D, eLogicalSize);

    SetLength( eEmpty, _3_e_eHowMany);
    SetLength( _1_tt_a, Length( _1_tt_a) + _3_e_eHowMany);

    For i := eLogicalSize + _3_e_eHowMany Downto _2_e_eIndex4D + _3_e_eHowMany Do _1_tt_a[i] := _1_tt_a[i - _3_e_eHowMany];

    For i := 0 To _3_e_eHowMany - 1 Do _1_tt_a[_2_e_eIndex4D + i] := eEmpty[i];
  End;

//procedure insertInArray(var A: Tq4LongintArray; const eIndex4D: Int64; const eHowMany: int64);
//var
//  i, eLogicalSize: Int64;
//  eEmpty: Tq4LongintArray;
//begin
//  if eHowMany < 0 then
//    raise Exception.Create('insertInArray: nombre d''éléments négatif interdit');
//  if eHowMany = 0 then
//    Exit;

//  eLogicalSize := sizeOfArray(A);
//  q4Check4DInsertIndex(eIndex4D, eLogicalSize);

//  SetLength(eEmpty, eHowMany);
//  SetLength(A, Length(A) + eHowMany);

//  for i := eLogicalSize + eHowMany downto eIndex4D + eHowMany do
//    A[i] := A[i - eHowMany];

//  for i := 0 to eHowMany - 1 do
//    A[eIndex4D + i] := eEmpty[i];
//end;

Procedure insertInArray( Var _1_te_a: Tq4Int64Array; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64);
  Var
    i, eLogicalSize: int64;
    eEmpty: Tq4Int64Array;
  Begin
    If ( _3_e_eHowMany < 0) Then Raise Exception.Create( 'insertInArray: nombre d''éléments négatif interdit');
    If ( _3_e_eHowMany = 0) Then Exit;

    eLogicalSize := sizeOfArray( _1_te_a);
    q4Check4DInsertIndex( _2_e_eIndex4D, eLogicalSize);

    SetLength( eEmpty, _3_e_eHowMany);
    SetLength( _1_te_a, Length( _1_te_a) + _3_e_eHowMany);

    For i := eLogicalSize + _3_e_eHowMany Downto _2_e_eIndex4D + _3_e_eHowMany Do _1_te_a[i] := _1_te_a[i - _3_e_eHowMany];

    For i := 0 To _3_e_eHowMany - 1 Do _1_te_a[_2_e_eIndex4D + i] := eEmpty[i];
  End;

Procedure insertInArray( Var _1_tr_a: Tq4RealArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64);
  Var
    i, eLogicalSize: int64;
    eEmpty: Tq4RealArray;
  Begin
    If ( _3_e_eHowMany < 0) Then Raise Exception.Create( 'insertInArray: nombre d''éléments négatif interdit');
    If ( _3_e_eHowMany = 0) Then Exit;

    eLogicalSize := sizeOfArray( _1_tr_a);
    q4Check4DInsertIndex( _2_e_eIndex4D, eLogicalSize);

    SetLength( eEmpty, _3_e_eHowMany);
    SetLength( _1_tr_a, Length( _1_tr_a) + _3_e_eHowMany);

    For i := eLogicalSize + _3_e_eHowMany Downto _2_e_eIndex4D + _3_e_eHowMany Do _1_tr_a[i] := _1_tr_a[i - _3_e_eHowMany];

    For i := 0 To _3_e_eHowMany - 1 Do _1_tr_a[_2_e_eIndex4D + i] := eEmpty[i];
  End;

Procedure insertInArray( Var _1_tb_a: Tq4BooleanArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64);
  Var
    i, eLogicalSize: int64;
    eEmpty: Tq4BooleanArray;
  Begin
    If ( _3_e_eHowMany < 0) Then Raise Exception.Create( 'insertInArray: nombre d''éléments négatif interdit');
    If ( _3_e_eHowMany = 0) Then Exit;

    eLogicalSize := sizeOfArray( _1_tb_a);
    q4Check4DInsertIndex( _2_e_eIndex4D, eLogicalSize);

    SetLength( eEmpty, _3_e_eHowMany);
    SetLength( _1_tb_a, Length( _1_tb_a) + _3_e_eHowMany);

    For i := eLogicalSize + _3_e_eHowMany Downto _2_e_eIndex4D + _3_e_eHowMany Do _1_tb_a[i] := _1_tb_a[i - _3_e_eHowMany];

    For i := 0 To _3_e_eHowMany - 1 Do _1_tb_a[_2_e_eIndex4D + i] := eEmpty[i];
  End;

Procedure insertInArray( Var _1_te_a: Tq4DateArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64);
  Var
    i, eLogicalSize: int64;
    eEmpty: Tq4DateArray;
  Begin
    If ( _3_e_eHowMany < 0) Then Raise Exception.Create( 'insertInArray: nombre d''éléments négatif interdit');
    If ( _3_e_eHowMany = 0) Then Exit;

    eLogicalSize := sizeOfArray( _1_te_a);
    q4Check4DInsertIndex( _2_e_eIndex4D, eLogicalSize);

    SetLength( eEmpty, _3_e_eHowMany);
    SetLength( _1_te_a, Length( _1_te_a) + _3_e_eHowMany);

    For i := eLogicalSize + _3_e_eHowMany Downto _2_e_eIndex4D + _3_e_eHowMany Do _1_te_a[i] := _1_te_a[i - _3_e_eHowMany];

    For i := 0 To _3_e_eHowMany - 1 Do _1_te_a[_2_e_eIndex4D + i] := eEmpty[i];
  End;

Procedure insertInArray( Var _1_te_a: Tq4TimeArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64);
  Var
    i, eLogicalSize: int64;
    eEmpty: Tq4TimeArray;
  Begin
    If ( _3_e_eHowMany < 0) Then Raise Exception.Create( 'insertInArray: nombre d''éléments négatif interdit');
    If ( _3_e_eHowMany = 0) Then Exit;

    eLogicalSize := sizeOfArray( _1_te_a);
    q4Check4DInsertIndex( _2_e_eIndex4D, eLogicalSize);

    SetLength( eEmpty, _3_e_eHowMany);
    SetLength( _1_te_a, Length( _1_te_a) + _3_e_eHowMany);

    For i := eLogicalSize + _3_e_eHowMany Downto _2_e_eIndex4D + _3_e_eHowMany Do _1_te_a[i] := _1_te_a[i - _3_e_eHowMany];

    For i := 0 To _3_e_eHowMany - 1 Do _1_te_a[_2_e_eIndex4D + i] := eEmpty[i];
  End;

Procedure insertInArray( Var _1_to_a: Tq4ObjectArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64);
  Var
    i, eLogicalSize: int64;
    eEmpty: Tq4ObjectArray;
  Begin
    If ( _3_e_eHowMany < 0) Then Raise Exception.Create( 'insertInArray: nombre d''éléments négatif interdit');
    If ( _3_e_eHowMany = 0) Then Exit;

    eLogicalSize := sizeOfArray( _1_to_a);
    q4Check4DInsertIndex( _2_e_eIndex4D, eLogicalSize);

    SetLength( eEmpty, _3_e_eHowMany);
    SetLength( _1_to_a, Length( _1_to_a) + _3_e_eHowMany);

    For i := eLogicalSize + _3_e_eHowMany Downto _2_e_eIndex4D + _3_e_eHowMany Do _1_to_a[i] := _1_to_a[i - _3_e_eHowMany];

    For i := 0 To _3_e_eHowMany - 1 Do _1_to_a[_2_e_eIndex4D + i] := eEmpty[i];
  End;

Procedure insertInArray( Var _1_ty_a: Tq4BlobArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64);
  Var
    i, eLogicalSize: int64;
    eEmpty: Tq4BlobArray;
  Begin
    If ( _3_e_eHowMany < 0) Then Raise Exception.Create( 'insertInArray: nombre d''éléments négatif interdit');
    If ( _3_e_eHowMany = 0) Then Exit;

    eLogicalSize := sizeOfArray( _1_ty_a);
    q4Check4DInsertIndex( _2_e_eIndex4D, eLogicalSize);

    SetLength( eEmpty, _3_e_eHowMany);
    SetLength( _1_ty_a, Length( _1_ty_a) + _3_e_eHowMany);

    For i := eLogicalSize + _3_e_eHowMany Downto _2_e_eIndex4D + _3_e_eHowMany Do _1_ty_a[i] := Copy( _1_ty_a[i - _3_e_eHowMany]);

    For i := 0 To _3_e_eHowMany - 1 Do _1_ty_a[_2_e_eIndex4D + i] := Copy( eEmpty[i]);
  End;

Procedure insertInArray( Var _1_tp_a: Tq4PointerArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64);
  Var
    i, eLogicalSize: int64;
    eEmpty: Tq4PointerArray;
  Begin
    If ( _3_e_eHowMany < 0) Then Raise Exception.Create( 'insertInArray: nombre d''éléments négatif interdit');
    If ( _3_e_eHowMany = 0) Then Exit;

    eLogicalSize := sizeOfArray( _1_tp_a);
    q4Check4DInsertIndex( _2_e_eIndex4D, eLogicalSize);

    SetLength( eEmpty, _3_e_eHowMany);
    SetLength( _1_tp_a, Length( _1_tp_a) + _3_e_eHowMany);

    For i := eLogicalSize + _3_e_eHowMany Downto _2_e_eIndex4D + _3_e_eHowMany Do _1_tp_a[i] := _1_tp_a[i - _3_e_eHowMany];

    For i := 0 To _3_e_eHowMany - 1 Do _1_tp_a[_2_e_eIndex4D + i] := eEmpty[i];
  End;

Procedure insertInArray( Var _1_ty_a: Tq4PictureArray; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64);
  Var
    i, eLogicalSize: int64;
    eEmpty: Tq4PictureArray;
  Begin
    If ( _3_e_eHowMany < 0) Then Raise Exception.Create( 'insertInArray: nombre d''éléments négatif interdit');
    If ( _3_e_eHowMany = 0) Then Exit;

    eLogicalSize := sizeOfArray( _1_ty_a);
    q4Check4DInsertIndex( _2_e_eIndex4D, eLogicalSize);

    SetLength( eEmpty, _3_e_eHowMany);
    SetLength( _1_ty_a, Length( _1_ty_a) + _3_e_eHowMany);

    For i := eLogicalSize + _3_e_eHowMany Downto _2_e_eIndex4D + _3_e_eHowMany Do _1_ty_a[i] := Copy( _1_ty_a[i - _3_e_eHowMany]);

    For i := 0 To _3_e_eHowMany - 1 Do _1_ty_a[_2_e_eIndex4D + i] := Copy( eEmpty[i]);
  End;

Procedure insertInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_eIndex4D: int64; Const _3_e_eHowMany: int64);
  Begin
    Case q4RefToArrayRef( _1_y_ref, 'insertInArray').Kind Of
      akText: insertInArray( q4ref.Pq4TextArray( _1_y_ref.Ptr)^, _2_e_eIndex4D, _3_e_eHowMany);
      akDate: insertInArray( q4ref.Pq4DateArray( _1_y_ref.Ptr)^, _2_e_eIndex4D, _3_e_eHowMany);
      akTime: insertInArray( q4ref.Pq4TimeArray( _1_y_ref.Ptr)^, _2_e_eIndex4D, _3_e_eHowMany);
      akObject: insertInArray( q4ref.Pq4ObjectArray( _1_y_ref.Ptr)^, _2_e_eIndex4D, _3_e_eHowMany);
      akInt64: insertInArray( q4ref.Pq4Int64Array( _1_y_ref.Ptr)^, _2_e_eIndex4D, _3_e_eHowMany);
      akReal: insertInArray( q4ref.Pq4RealArray( _1_y_ref.Ptr)^, _2_e_eIndex4D, _3_e_eHowMany);
      akBoolean: insertInArray( q4ref.Pq4BooleanArray( _1_y_ref.Ptr)^, _2_e_eIndex4D, _3_e_eHowMany);
      akBlob: insertInArray( q4ref.Pq4BlobArray( _1_y_ref.Ptr)^, _2_e_eIndex4D, _3_e_eHowMany);
      akPointer: insertInArray( q4ref.Pq4PointerArray( _1_y_ref.Ptr)^, _2_e_eIndex4D, _3_e_eHowMany);
      akPicture: insertInArray( q4ref.Pq4PictureArray( _1_y_ref.Ptr)^, _2_e_eIndex4D, _3_e_eHowMany);
      Else Raise Exception.Create( 'insertInArray: type de tableau non supporté');
    End;
  End;

Function arrayAssociatedValue( Const _1_p_tableau: Pointer): int64;
  Var
    eIndex: int64;
  Begin
    eIndex := q4FindArrayAssociatedValueIndex( _1_p_tableau);
    If ( eIndex < 0) Then Exit( 0);

    Result := gQ4ArrayAssociatedValues.Values[eIndex];
  End;

Function arrayAssociatedValue( Const _1_y_ref: q4ref.TQ4Ref): int64;
  Begin
    q4ref.requireTarget( _1_y_ref, q4ref.q4tkArray, 'arrayAssociatedValue');
    Result := arrayAssociatedValue( _1_y_ref.Ptr);
  End;

Procedure copyArray( Const _1_tt_source: Tq4TextArray; Var _2_tt_dest: Tq4TextArray);
  Begin
    _2_tt_dest := Copy( _1_tt_source);
    arrayAssociatedValue( @_2_tt_dest, arrayAssociatedValue( @_1_tt_source));
  End;

Procedure copyArray( Const _1_te_source: Tq4DateArray; Var _2_te_dest: Tq4DateArray);
  Begin
    _2_te_dest := Copy( _1_te_source);
    arrayAssociatedValue( @_2_te_dest, arrayAssociatedValue( @_1_te_source));
  End;

Procedure copyArray( Const _1_te_source: Tq4TimeArray; Var _2_te_dest: Tq4TimeArray);
  Begin
    _2_te_dest := Copy( _1_te_source);
    arrayAssociatedValue( @_2_te_dest, arrayAssociatedValue( @_1_te_source));
  End;

Procedure copyArray( Const _1_to_source: Tq4ObjectArray; Var _2_to_dest: Tq4ObjectArray);
  Begin
    _2_to_dest := Copy( _1_to_source);
    arrayAssociatedValue( @_2_to_dest, arrayAssociatedValue( @_1_to_source));
  End;

//procedure copyArray(const ASource: Tq4LongintArray; var ADest: Tq4LongintArray);
//begin
//  ADest := Copy(ASource);
//  arrayAssociatedValue(@ADest, arrayAssociatedValue(@ASource));
//end;

Procedure copyArray( Const _1_te_source: Tq4Int64Array; Var _2_te_dest: Tq4Int64Array);
  Begin
    _2_te_dest := Copy( _1_te_source);
    arrayAssociatedValue( @_2_te_dest, arrayAssociatedValue( @_1_te_source));
  End;

Procedure copyArray( Const _1_tr_source: Tq4RealArray; Var _2_tr_dest: Tq4RealArray);
  Begin
    _2_tr_dest := Copy( _1_tr_source);
    arrayAssociatedValue( @_2_tr_dest, arrayAssociatedValue( @_1_tr_source));
  End;

Procedure copyArray( Const _1_tb_source: Tq4BooleanArray; Var _2_tb_dest: Tq4BooleanArray);
  Begin
    _2_tb_dest := Copy( _1_tb_source);
    arrayAssociatedValue( @_2_tb_dest, arrayAssociatedValue( @_1_tb_source));
  End;

Procedure copyArray( Const _1_ty_source: Tq4BlobArray; Var _2_ty_dest: Tq4BlobArray);
  Begin
    _2_ty_dest := Copy( _1_ty_source);
    arrayAssociatedValue( @_2_ty_dest, arrayAssociatedValue( @_1_ty_source));
  End;

Procedure copyArray( Const _1_ty_source: Tq4PictureArray; Var _2_ty_dest: Tq4PictureArray);
  Begin
    _2_ty_dest := Copy( _1_ty_source);
    arrayAssociatedValue( @_2_ty_dest, arrayAssociatedValue( @_1_ty_source));
  End;

Procedure copyArray( Const _1_tp_source: Tq4PointerArray; Var _2_tp_dest: Tq4PointerArray);
  Begin
    _2_tp_dest := Copy( _1_tp_source);
    arrayAssociatedValue( @_2_tp_dest, arrayAssociatedValue( @_1_tp_source));
  End;

Procedure copyArray( Const _1_y_sourceRef: q4ref.TQ4Ref; Const _2_y_destRef: q4ref.TQ4Ref);
  Var
    SourceArrayRef, DestArrayRef: Tq4ArrayRef;
  Begin
    SourceArrayRef := q4RefToArrayRef( _1_y_sourceRef, 'copyArray');
    DestArrayRef := q4RefToArrayRef( _2_y_destRef, 'copyArray');

    If ( SourceArrayRef.Kind <> DestArrayRef.Kind) Then Raise Exception.Create( 'copyArray: types source/destination incompatibles');

    Case SourceArrayRef.Kind Of
      akText: copyArray( q4ref.Pq4TextArray( _1_y_sourceRef.Ptr)^, q4ref.Pq4TextArray( _2_y_destRef.Ptr)^);
      akDate: copyArray( q4ref.Pq4DateArray( _1_y_sourceRef.Ptr)^, q4ref.Pq4DateArray( _2_y_destRef.Ptr)^);
      akTime: copyArray( q4ref.Pq4TimeArray( _1_y_sourceRef.Ptr)^, q4ref.Pq4TimeArray( _2_y_destRef.Ptr)^);
      akObject: copyArray( q4ref.Pq4ObjectArray( _1_y_sourceRef.Ptr)^, q4ref.Pq4ObjectArray( _2_y_destRef.Ptr)^);
      akInt64: copyArray( q4ref.Pq4Int64Array( _1_y_sourceRef.Ptr)^, q4ref.Pq4Int64Array( _2_y_destRef.Ptr)^);
      akReal: copyArray( q4ref.Pq4RealArray( _1_y_sourceRef.Ptr)^, q4ref.Pq4RealArray( _2_y_destRef.Ptr)^);
      akBoolean: copyArray( q4ref.Pq4BooleanArray( _1_y_sourceRef.Ptr)^, q4ref.Pq4BooleanArray( _2_y_destRef.Ptr)^);
      akBlob: copyArray( q4ref.Pq4BlobArray( _1_y_sourceRef.Ptr)^, q4ref.Pq4BlobArray( _2_y_destRef.Ptr)^);
      akPointer: copyArray( q4ref.Pq4PointerArray( _1_y_sourceRef.Ptr)^, q4ref.Pq4PointerArray( _2_y_destRef.Ptr)^);
      akPicture: copyArray( q4ref.Pq4PictureArray( _1_y_sourceRef.Ptr)^, q4ref.Pq4PictureArray( _2_y_destRef.Ptr)^);
      Else Raise Exception.Create( 'copyArray: type de tableau non supporté');
    End;
  End;

Function countInArray( Const _1_tt_arrayValue: Tq4TextArray; Const _2_t_value: string): int64;
  Var
    i: int64;
  Begin
    Result := 0;
    For i := 1 To sizeOfArray( _1_tt_arrayValue) Do If ( _1_tt_arrayValue[i] = _2_t_value) Then Inc( Result);
  End;

Function countInArray( Const _1_te_arrayValue: Tq4DateArray; Const _2_y_value: Tq4Date): int64;
  Var
    i: int64;
  Begin
    Result := 0;
    For i := 1 To sizeOfArray( _1_te_arrayValue) Do If ( _1_te_arrayValue[i] = _2_y_value) Then Inc( Result);
  End;

Function countInArray( Const _1_te_arrayValue: Tq4TimeArray; Const _2_y_value: Tq4Time): int64;
  Var
    i: int64;
  Begin
    Result := 0;
    For i := 1 To sizeOfArray( _1_te_arrayValue) Do If ( _1_te_arrayValue[i] = _2_y_value) Then Inc( Result);
  End;

Function countInArray( Const _1_to_arrayValue: Tq4ObjectArray; Const _2_o_value: Tq4JSONObject): int64;
  Var
    i: int64;
  Begin
    Result := 0;
    For i := 1 To sizeOfArray( _1_to_arrayValue) Do If ( _1_to_arrayValue[i] = _2_o_value) Then Inc( Result);
  End;

//function countInArray(const AArray: Tq4LongintArray; const AValue: longint): Int64;
//var
//  i: Int64;
//begin
//  Result := 0;
//  for i := 1 to sizeOfArray(AArray) do if AArray[i] = AValue then Inc(Result);
//end;

Function countInArray( Const _1_te_arrayValue: Tq4Int64Array; Const _2_e_value: int64): int64;
  Var
    i: int64;
  Begin
    Result := 0;
    For i := 1 To sizeOfArray( _1_te_arrayValue) Do If ( _1_te_arrayValue[i] = _2_e_value) Then Inc( Result);
  End;

Function countInArray( Const _1_tr_arrayValue: Tq4RealArray; Const _2_r_value: double): int64;
  Var
    i: int64;
  Begin
    Result := 0;
    For i := 1 To sizeOfArray( _1_tr_arrayValue) Do If ( _1_tr_arrayValue[i] = _2_r_value) Then Inc( Result);
  End;

Function countInArray( Const _1_tb_arrayValue: Tq4BooleanArray; Const _2_b_value: boolean): int64;
  Var
    i: int64;
  Begin
    Result := 0;
    For i := 1 To sizeOfArray( _1_tb_arrayValue) Do If ( _1_tb_arrayValue[i] = _2_b_value) Then Inc( Result);
  End;

Function countInArray( Const _1_ty_arrayValue: Tq4BlobArray; Const _2_by_value: TBytes): int64;
  Var
    i: int64;
  Begin
    Result := 0;
    For i := 1 To sizeOfArray( _1_ty_arrayValue) Do If ( Length( _1_ty_arrayValue[i]) = Length( _2_by_value)) Then
        If ( ( Length( _2_by_value) = 0) or ( CompareByte( _1_ty_arrayValue[i][0], _2_by_value[0], Length( _2_by_value)) = 0)) Then Inc( Result);
  End;

Function countInArray( Const _1_tp_arrayValue: Tq4PointerArray; Const _2_p_value: Pointer): int64;
  Var
    i: int64;
  Begin
    Result := 0;
    For i := 1 To sizeOfArray( _1_tp_arrayValue) Do If ( _1_tp_arrayValue[i] = _2_p_value) Then Inc( Result);
  End;

Function countInArray( Const _1_ty_arrayValue: Tq4PictureArray; Const _2_o_value: Tq4Picture): int64;
  Var
    i: int64;
  Begin
    Result := 0;
    For i := 1 To sizeOfArray( _1_ty_arrayValue) Do If ( Length( _1_ty_arrayValue[i]) = Length( _2_o_value)) Then
        If ( ( Length( _2_o_value) = 0) or ( CompareByte( _1_ty_arrayValue[i][0], _2_o_value[0], Length( _2_o_value)) = 0)) Then Inc( Result);
  End;

Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_t_value: string): int64;
  Begin
    Case q4RefToArrayRef( _1_y_ref, 'countInArray').Kind Of
      akText: Result := countInArray( q4ref.Pq4TextArray( _1_y_ref.Ptr)^, _2_t_value);
      akDate: Result := countInArray( q4ref.Pq4DateArray( _1_y_ref.Ptr)^, Tq4Date( _2_t_value));
      akTime: Result := countInArray( q4ref.Pq4TimeArray( _1_y_ref.Ptr)^, Tq4Time( _2_t_value));
      Else Raise Exception.Create( 'countInArray: tableau texte/date/time attendu');
    End;
  End;

Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_y_value: Tq4Date): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akDate, 'countInArray');
    Result := countInArray( q4ref.Pq4DateArray( _1_y_ref.Ptr)^, _2_y_value);
  End;

Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_y_value: Tq4Time): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akTime, 'countInArray');
    Result := countInArray( q4ref.Pq4TimeArray( _1_y_ref.Ptr)^, _2_y_value);
  End;

Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_o_value: Tq4JSONObject): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akObject, 'countInArray');
    Result := countInArray( q4ref.Pq4ObjectArray( _1_y_ref.Ptr)^, _2_o_value);
  End;

Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_value: int64): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akInt64, 'countInArray');
    Result := countInArray( q4ref.Pq4Int64Array( _1_y_ref.Ptr)^, _2_e_value);
  End;

Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_r_value: double): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akReal, 'countInArray');
    Result := countInArray( q4ref.Pq4RealArray( _1_y_ref.Ptr)^, _2_r_value);
  End;

Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_b_value: boolean): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akBoolean, 'countInArray');
    Result := countInArray( q4ref.Pq4BooleanArray( _1_y_ref.Ptr)^, _2_b_value);
  End;

Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_by_value: TBytes): int64;
  Var
    i: int64;
    pPictureArray: q4ref.Pq4PictureArray;
  Begin
    Case q4RefToArrayRef( _1_y_ref, 'countInArray').Kind Of
      akBlob: Result := countInArray( q4ref.Pq4BlobArray( _1_y_ref.Ptr)^, _2_by_value);

      akPicture: Begin
        Result := 0;
        pPictureArray := q4ref.Pq4PictureArray( _1_y_ref.Ptr);
        For i := 1 To Length( pPictureArray^) - 1 Do If ( Length( pPictureArray^[i]) = Length( _2_by_value)) Then
            If ( ( Length( _2_by_value) = 0) or ( CompareByte( pPictureArray^[i][0], _2_by_value[0], Length( _2_by_value)) = 0)) Then Inc( Result);
      End;
      Else Raise Exception.Create( 'countInArray: tableau Blob ou Picture attendu');
    End;
  End;

Function countInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_p_value: Pointer): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akPointer, 'countInArray');
    Result := countInArray( q4ref.Pq4PointerArray( _1_y_ref.Ptr)^, _2_p_value);
  End;

Function findInArray( Const _1_tt_arrayValue: Tq4TextArray; Const _2_t_value: string): int64;
  Var
    i: int64;
  Begin
    For i := 1 To sizeOfArray( _1_tt_arrayValue) Do If ( _1_tt_arrayValue[i] = _2_t_value) Then Exit( i);
    Result := -1;
  End;

Function findInArray( Const _1_te_arrayValue: Tq4DateArray; Const _2_y_value: Tq4Date): int64;
  Var
    i: int64;
  Begin
    For i := 1 To sizeOfArray( _1_te_arrayValue) Do If ( _1_te_arrayValue[i] = _2_y_value) Then Exit( i);
    Result := -1;
  End;

Function findInArray( Const _1_te_arrayValue: Tq4TimeArray; Const _2_y_value: Tq4Time): int64;
  Var
    i: int64;
  Begin
    For i := 1 To sizeOfArray( _1_te_arrayValue) Do If ( _1_te_arrayValue[i] = _2_y_value) Then Exit( i);
    Result := -1;
  End;

Function findInArray( Const _1_to_arrayValue: Tq4ObjectArray; Const _2_o_value: Tq4JSONObject): int64;
  Var
    i: int64;
  Begin
    For i := 1 To sizeOfArray( _1_to_arrayValue) Do If ( _1_to_arrayValue[i] = _2_o_value) Then Exit( i);
    Result := -1;
  End;

//function findInArray(const AArray: Tq4LongintArray; const AValue: longint): Int64;
//var
//  i: Int64;
//begin
//  for i := 1 to sizeOfArray(AArray) do if AArray[i] = AValue then Exit(i);
//  Result := -1;
//end;

Function findInArray( Const _1_te_arrayValue: Tq4Int64Array; Const _2_e_value: int64): int64;
  Var
    i: int64;
  Begin
    For i := 1 To sizeOfArray( _1_te_arrayValue) Do If ( _1_te_arrayValue[i] = _2_e_value) Then Exit( i);
    Result := -1;
  End;

Function findInArray( Const _1_tr_arrayValue: Tq4RealArray; Const _2_r_value: double): int64;
  Var
    i: int64;
  Begin
    For i := 1 To sizeOfArray( _1_tr_arrayValue) Do If ( _1_tr_arrayValue[i] = _2_r_value) Then Exit( i);
    Result := -1;
  End;

Function findInArray( Const _1_tb_arrayValue: Tq4BooleanArray; Const _2_b_value: boolean): int64;
  Var
    i: int64;
  Begin
    For i := 1 To sizeOfArray( _1_tb_arrayValue) Do If ( _1_tb_arrayValue[i] = _2_b_value) Then Exit( i);
    Result := -1;
  End;

Function findInArray( Const _1_ty_arrayValue: Tq4BlobArray; Const _2_by_value: TBytes): int64;
  Var
    i: int64;
  Begin
    For i := 1 To sizeOfArray( _1_ty_arrayValue) Do If ( Length( _1_ty_arrayValue[i]) = Length( _2_by_value)) Then
        If ( ( Length( _2_by_value) = 0) or ( CompareByte( _1_ty_arrayValue[i][0], _2_by_value[0], Length( _2_by_value)) = 0)) Then Exit( i);
    Result := -1;
  End;

Function findInArray( Const _1_tp_arrayValue: Tq4PointerArray; Const _2_p_value: Pointer): int64;
  Var
    i: int64;
  Begin
    For i := 1 To sizeOfArray( _1_tp_arrayValue) Do If ( _1_tp_arrayValue[i] = _2_p_value) Then Exit( i);
    Result := -1;
  End;

Function findInArray( Const _1_ty_arrayValue: Tq4PictureArray; Const _2_o_value: Tq4Picture): int64;
  Var
    i: int64;
  Begin
    For i := 1 To sizeOfArray( _1_ty_arrayValue) Do If ( Length( _1_ty_arrayValue[i]) = Length( _2_o_value)) Then
        If ( ( Length( _2_o_value) = 0) or ( CompareByte( _1_ty_arrayValue[i][0], _2_o_value[0], Length( _2_o_value)) = 0)) Then Exit( i);
    Result := -1;
  End;

Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_t_value: string): int64;
  Begin
    Case q4RefToArrayRef( _1_y_ref, 'findInArray').Kind Of
      akText: Result := findInArray( q4ref.Pq4TextArray( _1_y_ref.Ptr)^, _2_t_value);
      akDate: Result := findInArray( q4ref.Pq4DateArray( _1_y_ref.Ptr)^, Tq4Date( _2_t_value));
      akTime: Result := findInArray( q4ref.Pq4TimeArray( _1_y_ref.Ptr)^, Tq4Time( _2_t_value));
      Else Raise Exception.Create( 'findInArray: tableau texte/date/time attendu');
    End;
  End;

Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_y_value: Tq4Date): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akDate, 'findInArray');
    Result := findInArray( q4ref.Pq4DateArray( _1_y_ref.Ptr)^, _2_y_value);
  End;

Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_y_value: Tq4Time): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akTime, 'findInArray');
    Result := findInArray( q4ref.Pq4TimeArray( _1_y_ref.Ptr)^, _2_y_value);
  End;

Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_o_value: Tq4JSONObject): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akObject, 'findInArray');
    Result := findInArray( q4ref.Pq4ObjectArray( _1_y_ref.Ptr)^, _2_o_value);
  End;

Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_value: int64): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akInt64, 'findInArray');
    Result := findInArray( q4ref.Pq4Int64Array( _1_y_ref.Ptr)^, _2_e_value);
  End;

Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_r_value: double): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akReal, 'findInArray');
    Result := findInArray( q4ref.Pq4RealArray( _1_y_ref.Ptr)^, _2_r_value);
  End;

Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_b_value: boolean): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akBoolean, 'findInArray');
    Result := findInArray( q4ref.Pq4BooleanArray( _1_y_ref.Ptr)^, _2_b_value);
  End;

Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_by_value: TBytes): int64;
  Var
    i: int64;
    pPictureArray: q4ref.Pq4PictureArray;
  Begin
    Case q4RefToArrayRef( _1_y_ref, 'findInArray').Kind Of
      akBlob: Result := findInArray( q4ref.Pq4BlobArray( _1_y_ref.Ptr)^, _2_by_value);

      akPicture: Begin
        pPictureArray := q4ref.Pq4PictureArray( _1_y_ref.Ptr);
        For i := 1 To Length( pPictureArray^) - 1 Do If ( Length( pPictureArray^[i]) = Length( _2_by_value)) Then
            If ( ( Length( _2_by_value) = 0) or ( CompareByte( pPictureArray^[i][0], _2_by_value[0], Length( _2_by_value)) = 0)) Then Exit( i);
        Result := -1;
      End;
      Else Raise Exception.Create( 'findInArray: tableau Blob ou Picture attendu');
    End;
  End;

Function findInArray( Const _1_y_ref: q4ref.TQ4Ref; Const _2_p_value: Pointer): int64;
  Begin
    q4RequireArrayKind( _1_y_ref, akPointer, 'findInArray');
    Result := findInArray( q4ref.Pq4PointerArray( _1_y_ref.Ptr)^, _2_p_value);
  End;

Procedure arrayAssociatedValue( Const _1_p_tableau: Pointer; Const _2_e_value: int64);
  Var
    eIndex: int64;
  Begin
    eIndex := q4FindOrAddArrayAssociatedValueIndex( _1_p_tableau);
    gQ4ArrayAssociatedValues.Values[eIndex] := _2_e_value;
  End;

Procedure arrayAssociatedValue( Const _1_y_ref: q4ref.TQ4Ref; Const _2_e_value: int64);
  Begin
    q4ref.requireTarget( _1_y_ref, q4ref.q4tkArray, 'arrayAssociatedValue');
    arrayAssociatedValue( _1_y_ref.Ptr, _2_e_value);
  End;

Function compareOne( Const _1_y_ref: Tq4SortArrayRef; Const _2_e_i, _3_e_j: int64): int64;
  Var
    S1, S2: string;
    I32_1, I32_2: longint;
    I64_1, I64_2: int64;
    R1, R2: double;
    B1, B2: boolean;
  Begin
    Case _1_y_ref.Ref.Kind Of
      akText: Begin
        S1 := Pq4TextArray( _1_y_ref.Ref.Data)^[_2_e_i];
        S2 := Pq4TextArray( _1_y_ref.Ref.Data)^[_3_e_j];
        { q4 rule:
        texte trié comme 4D autant que possible :
        - insensible à la casse
        - insensible aux diacritiques
        La normalisation centrale est portée par q4coreLanguage. }
        Result := CompareTextQ4( S1, S2);
      End;

      akDate: Begin
        S1 := Pq4DateArray( _1_y_ref.Ref.Data)^[_2_e_i];
        S2 := Pq4DateArray( _1_y_ref.Ref.Data)^[_3_e_j];
        { Formats canoniques q4 : YYYY-MM-DD }
        Result := CompareStr( S1, S2);
      End;

      akTime: Begin
        S1 := Pq4TimeArray( _1_y_ref.Ref.Data)^[_2_e_i];
        S2 := Pq4TimeArray( _1_y_ref.Ref.Data)^[_3_e_j];
        { Formats canoniques q4 : HH:NN:SS }
        Result := CompareStr( S1, S2);
      End;

      akObject: Begin
        Raise Exception.Create( 'q4arrays.SortArrays : tri des tableaux objet non implémenté');
        Result := 0;
      End;

      //akLongint: begin
      //  I32_1 := Pq4LongintArray(Ref.Ref.Data)^[I];
      //  I32_2 := Pq4LongintArray(Ref.Ref.Data)^[J];
      //  if I32_1 < I32_2 then Result := -1
      //  else if I32_1 > I32_2 then Result := 1
      //  else
      //    Result := 0;
      //end;

      akInt64: Begin
        I64_1 := Pq4Int64Array( _1_y_ref.Ref.Data)^[_2_e_i];
        I64_2 := Pq4Int64Array( _1_y_ref.Ref.Data)^[_3_e_j];
        If ( I64_1 < I64_2) Then Result := -1
        Else If ( I64_1 > I64_2) Then Result := 1
        Else
          Result := 0;
      End;

      akReal: Begin
        R1 := Pq4RealArray( _1_y_ref.Ref.Data)^[_2_e_i];
        R2 := Pq4RealArray( _1_y_ref.Ref.Data)^[_3_e_j];
        If ( R1 < R2) Then Result := -1
        Else If ( R1 > R2) Then Result := 1
        Else
          Result := 0;
      End;

      akBoolean: Begin
        B1 := Pq4BooleanArray( _1_y_ref.Ref.Data)^[_2_e_i];
        B2 := Pq4BooleanArray( _1_y_ref.Ref.Data)^[_3_e_j];
        If ( B1 = B2) Then Result := 0
        Else If ( ( not B1) and B2) Then Result := -1
        Else
          Result := 1;
      End;

      akBlob, akPicture: Raise Exception.Create( 'q4arrays.CompareOne: tri Blob/Picture non implémenté');

      akPointer: Raise Exception.Create( 'q4arrays.CompareOne: tableaux Pointer non triables');

      Else Raise Exception.Create( 'q4arrays.CompareOne: type de comparaison non supporté');
    End;

    If ( _1_y_ref.Order = cq4SortDescendingValue) Then Result := -Result;
  End;

Function CompareIndexes( Const _1_ty_refs: Array Of Tq4SortArrayRef; Const _2_e_leftIdx, _3_e_rightIdx: int64): int64;
  Var
    K: int64;
  Begin
    For K := 0 To High( _1_ty_refs) Do If ( _1_ty_refs[K].Order <> cq4SortSynchronizedValue) Then Begin
        Result := CompareOne( _1_ty_refs[K], _2_e_leftIdx, _3_e_rightIdx);
        If ( Result <> 0) Then Exit;
      End;

    If ( _2_e_leftIdx < _3_e_rightIdx) Then Result := -1
    Else If ( _2_e_leftIdx > _3_e_rightIdx) Then Result := 1
    Else
      Result := 0;
  End;

Procedure MergeSortIndexes( Var _1_y_idx: TIntArray; Var _2_y_tmp: TIntArray; Const _3_ty_refs: Array Of Tq4SortArrayRef; Const _4_e_l, _5_e_r: int64);
  Var
    M, I, J, P: int64;
  Begin
    If ( _4_e_l >= _5_e_r) Then Exit;

    M := ( _4_e_l + _5_e_r) div 2;
    MergeSortIndexes( _1_y_idx, _2_y_tmp, _3_ty_refs, _4_e_l, M);
    MergeSortIndexes( _1_y_idx, _2_y_tmp, _3_ty_refs, M + 1, _5_e_r);

    I := _4_e_l;
    J := M + 1;
    P := _4_e_l;

    While ( ( I <= M) and ( J <= _5_e_r)) Do Begin
      If ( CompareIndexes( _3_ty_refs, _1_y_idx[I], _1_y_idx[J]) <= 0) Then Begin
        _2_y_tmp[P] := _1_y_idx[I];
        Inc( I);
      End Else Begin
        _2_y_tmp[P] := _1_y_idx[J];
        Inc( J);
      End;
      Inc( P);
    End;

    While ( I <= M) Do Begin
      _2_y_tmp[P] := _1_y_idx[I];
      Inc( I);
      Inc( P);
    End;

    While ( J <= _5_e_r) Do Begin
      _2_y_tmp[P] := _1_y_idx[J];
      Inc( J);
      Inc( P);
    End;

    For P := _4_e_l To _5_e_r Do _1_y_idx[P] := _2_y_tmp[P];
  End;

Procedure ApplyPermutationText( Var _1_tt_a: Tq4TextArray; Const _2_y_idx: TIntArray);
  Var
    B: Tq4TextArray;
    K: int64;
  Begin
    SetLength( B, Length( _1_tt_a));
    For K := 0 To High( _1_tt_a) Do B[K] := _1_tt_a[_2_y_idx[K]];
    _1_tt_a := B;
  End;

Procedure ApplyPermutationDate( Var _1_te_a: Tq4DateArray; Const _2_y_idx: TIntArray);
  Var
    B: Tq4DateArray;
    K: int64;
  Begin
    SetLength( B, Length( _1_te_a));
    For K := 0 To High( _1_te_a) Do B[K] := _1_te_a[_2_y_idx[K]];
    _1_te_a := B;
  End;

Procedure ApplyPermutationTime( Var _1_te_a: Tq4TimeArray; Const _2_y_idx: TIntArray);
  Var
    B: Tq4TimeArray;
    K: int64;
  Begin
    SetLength( B, Length( _1_te_a));
    For K := 0 To High( _1_te_a) Do B[K] := _1_te_a[_2_y_idx[K]];
    _1_te_a := B;
  End;

Procedure ApplyPermutationObject( Var _1_to_a: Tq4ObjectArray; Const _2_y_idx: TIntArray);
  Var
    B: Tq4ObjectArray;
    K: int64;
  Begin
    SetLength( B, Length( _1_to_a));
    For K := 0 To High( _1_to_a) Do B[K] := _1_to_a[_2_y_idx[K]];
    _1_to_a := B;
  End;

//procedure ApplyPermutationLongint(var A: Tq4LongintArray; const Idx: TIntArray);
//var
//  B: Tq4LongintArray;
//  K: Int64;
//begin
//  SetLength(B, Length(A));
//  for K := 0 to High(A) do B[K] := A[Idx[K]];
//  A := B;
//end;

Procedure ApplyPermutationInteger( Var _1_te_a: Tq4Int64Array; Const _2_y_idx: TIntArray);
  Var
    B: Tq4Int64Array;
    K: int64;
  Begin
    SetLength( B, Length( _1_te_a));
    For K := 0 To High( _1_te_a) Do B[K] := _1_te_a[_2_y_idx[K]];
    _1_te_a := B;
  End;

Procedure ApplyPermutationReal( Var _1_tr_a: Tq4RealArray; Const _2_y_idx: TIntArray);
  Var
    B: Tq4RealArray;
    K: int64;
  Begin
    SetLength( B, Length( _1_tr_a));
    For K := 0 To High( _1_tr_a) Do B[K] := _1_tr_a[_2_y_idx[K]];
    _1_tr_a := B;
  End;

Procedure ApplyPermutationBoolean( Var _1_tb_a: Tq4BooleanArray; Const _2_y_idx: TIntArray);
  Var
    B: Tq4BooleanArray;
    K: int64;
  Begin
    SetLength( B, Length( _1_tb_a));
    For K := 0 To High( _1_tb_a) Do B[K] := _1_tb_a[_2_y_idx[K]];
    _1_tb_a := B;
  End;

Procedure ApplyPermutationBlob( Var _1_ty_a: Tq4BlobArray; Const _2_y_idx: TIntArray);
  Var
    B: Tq4BlobArray;
    K: int64;
  Begin
    SetLength( B, Length( _1_ty_a));
    For K := 0 To High( _1_ty_a) Do B[K] := _1_ty_a[_2_y_idx[K]];
    _1_ty_a := B;
  End;

Procedure ApplyPermutationPicture( Var _1_ty_a: Tq4PictureArray; Const _2_y_idx: TIntArray);
  Var
    B: Tq4PictureArray;
    K: int64;
  Begin
    SetLength( B, Length( _1_ty_a));
    For K := 0 To High( _1_ty_a) Do B[K] := _1_ty_a[_2_y_idx[K]];
    _1_ty_a := B;
  End;

Procedure ApplyPermutation( Const _1_y_ref: Tq4ArrayRef; Const _2_y_idx: TIntArray);
  Begin
    Case _1_y_ref.Kind Of
      akText: ApplyPermutationText( Pq4TextArray( _1_y_ref.Data)^, _2_y_idx);
      akDate: ApplyPermutationDate( Pq4DateArray( _1_y_ref.Data)^, _2_y_idx);
      akTime: ApplyPermutationTime( Pq4TimeArray( _1_y_ref.Data)^, _2_y_idx);
      akObject: ApplyPermutationObject( Pq4ObjectArray( _1_y_ref.Data)^, _2_y_idx);
      //akLongint: ApplyPermutationLongint(Pq4LongintArray(Ref.Data)^, Idx);
      akInt64: ApplyPermutationInteger( Pq4Int64Array( _1_y_ref.Data)^, _2_y_idx);
      akReal: ApplyPermutationReal( Pq4RealArray( _1_y_ref.Data)^, _2_y_idx);
      akBoolean: ApplyPermutationBoolean( Pq4BooleanArray( _1_y_ref.Data)^, _2_y_idx);
      akBlob: ApplyPermutationBlob( Pq4BlobArray( _1_y_ref.Data)^, _2_y_idx);
      akPicture: ApplyPermutationPicture( Pq4PictureArray( _1_y_ref.Data)^, _2_y_idx);
      akPointer: Raise Exception.Create( 'q4arrays.ApplyPermutation: tableaux Pointer non triables');
      Else Raise Exception.Create( 'q4arrays.ApplyPermutation: type non supporté');
    End;
  End;

Procedure SortArrays( Const _1_ty_refs: Array Of Tq4SortArrayRef);
  Var
    N, K, L:      int64;
    HasCriterion: boolean;
    Idx, Tmp:     TIntArray;
  Begin
    If ( Length( _1_ty_refs) = 0) Then Raise Exception.Create( 'q4arrays.SortArrays: aucun tableau fourni');

    HasCriterion := False;
    For K := 0 To High( _1_ty_refs) Do Begin
      If ( not ( _1_ty_refs[K].Order in [cq4SortDescendingValue, cq4SortSynchronizedValue, cq4SortAscendingValue])) Then Raise Exception.Create( 'q4arrays.SortArrays: ordre invalide');

      If ( _1_ty_refs[K].Order <> cq4SortSynchronizedValue) Then HasCriterion := True;
    End;

    If ( not HasCriterion) Then Raise Exception.Create( 'q4arrays.SortArrays: au moins un critère de tri est requis');

    N := GetArrayLength( _1_ty_refs[0].Ref);
    For K := 1 To High( _1_ty_refs) Do Begin
      L := GetArrayLength( _1_ty_refs[K].Ref);
      If ( L <> N) Then Raise Exception.Create( 'q4arrays.SortArrays: tous les tableaux doivent avoir la même taille');
    End;

    { N = longueur physique, donc inclut l'élément 0.
    Le tri 4D ne doit porter que sur les éléments logiques 1..N-1. }
    If ( N <= 2) Then Exit;

    SetLength( Idx, N);
    SetLength( Tmp, N);

    Idx[0] := 0;
    For K := 1 To N - 1 Do Idx[K] := K;

    MergeSortIndexes( Idx, Tmp, _1_ty_refs, 1, N - 1);

    For K := 0 To High( _1_ty_refs) Do ApplyPermutation( _1_ty_refs[K].Ref, Idx);
  End;

Function InternalFindSelectionTableStateIndex( Const _1_e_eSourceTableId: int64): int64;
  Var
    _e_i: int64;
  Begin
    Result := -1;
    For _e_i := 0 To System.High( q4selection.ty_selectionTables) Do If ( q4selection.ty_selectionTables[_e_i].e_sourceTableId = _1_e_eSourceTableId) Then Begin
        Result := _e_i;
        Exit;
      End;
  End;

Function InternalFindTableMetaIndexBySourceTableId( Const _1_e_eSourceTableId: int64): int64;
  Var
    _e_i: int64;
  Begin
    Result := -1;
    For _e_i := 0 To System.High( Tables) Do If ( Tables[_e_i].SourceTableId = _1_e_eSourceTableId) Then Begin
        Result := _e_i;
        Exit;
      End;
  End;

Procedure InternalResolveSelectionTableMeta( Var _1_y_state: q4selection.Ty_selectionTableState);
  Var
    _e_tableIdx: int64;
    _e_first: int64;
    _e_last: int64;
    _e_i: int64;
  Begin
    _e_tableIdx := InternalFindTableMetaIndexBySourceTableId( _1_y_state.e_sourceTableId);
    q4interruptions.assertRaise( _e_tableIdx >= 0,
      'q4arrays.InternalResolveSelectionTableMeta : table source introuvable');

    _1_y_state.t_sourceTableName := Tables[_e_tableIdx].Name;
    _1_y_state.t_tempTableName := q4selectionTablesCore.buildSelectionTableName( qstsThread, _1_y_state.t_sourceTableName);

    _e_first := Tables[_e_tableIdx].FieldIndex;
    _e_last := _e_first + Tables[_e_tableIdx].FieldCount - 1;
    _1_y_state.t_pkFieldName := '';
    _1_y_state.t_pkTypeSQL := '';

    For _e_i := _e_first To _e_last Do If ( SysUtils.CompareText( Fields[_e_i].Name, Tables[_e_tableIdx].PrimaryKey) = 0) Then Begin
        _1_y_state.t_pkFieldName := Fields[_e_i].Name;
        _1_y_state.t_pkTypeSQL := Fields[_e_i].TypeSQL;
        Break;
      End;

    q4interruptions.assertRaise( _1_y_state.t_pkFieldName <> '',
      'q4arrays.InternalResolveSelectionTableMeta : champ PK introuvable');
    q4interruptions.assertRaise( _1_y_state.t_pkTypeSQL <> '',
      'q4arrays.InternalResolveSelectionTableMeta : type SQL PK introuvable');
  End;

Procedure InternalEnsureSelectionState( Var _1_p_recordTable; out _2_e_idx: int64);
  Var
    _e_sourceTableId: int64;
  Begin
    _e_sourceTableId := q4DBschemaUse.getSourceTableId( _1_p_recordTable);
    q4interruptions.assertRaise( _e_sourceTableId >= 0,
      'q4arrays.InternalEnsureSelectionState : _noTable invalide');

    _2_e_idx := InternalFindSelectionTableStateIndex( _e_sourceTableId);
    If ( _2_e_idx < 0) Then Begin
      SetLength( q4selection.ty_selectionTables, System.Length( q4selection.ty_selectionTables) + 1);
      _2_e_idx := System.High( q4selection.ty_selectionTables);

      q4selection.ty_selectionTables[_2_e_idx].e_sourceTableId := _e_sourceTableId;
      q4selection.ty_selectionTables[_2_e_idx].t_sourceTableName := '';
      q4selection.ty_selectionTables[_2_e_idx].t_tempTableName := '';
      q4selection.ty_selectionTables[_2_e_idx].t_pkFieldName := '';
      q4selection.ty_selectionTables[_2_e_idx].t_pkTypeSQL := '';
      q4selection.ty_selectionTables[_2_e_idx].b_isCreated := False;
      q4selection.ty_selectionTables[_2_e_idx].e_currentResultNo := 0;
      q4selection.ty_selectionTables[_2_e_idx].e_nextResultNo := 1;
      q4selection.ty_selectionTables[_2_e_idx].e_currentPos := 0;
      q4selection.ty_selectionTables[_2_e_idx].e_recordCount := 0;
      q4selection.ty_selectionTables[_2_e_idx].b_isEmpty := True;
      q4selection.ty_selectionTables[_2_e_idx].e_buildState := sbsNone;
      q4selection.ty_selectionTables[_2_e_idx].t_pendingWhereSQL := '';
      q4selection.ty_selectionTables[_2_e_idx].t_pendingOrderBySQL := '';
      q4selection.ty_selectionTables[_2_e_idx].e_pendingDestinationKind := qdkCurrentSelection;
      q4selection.ty_selectionTables[_2_e_idx].t_pendingDestinationName := '';
      q4selection.ty_selectionTables[_2_e_idx].e_pendingQueryLimit := 0;
      q4selection.ty_selectionTables[_2_e_idx].e_pendingReduceCount := 0;
    End;

    If ( q4selection.ty_selectionTables[_2_e_idx].t_sourceTableName = '') Then InternalResolveSelectionTableMeta( q4selection.ty_selectionTables[_2_e_idx]);

    q4selectionTablesCore.ensureSelectionTable(
      qstsThread,
      q4selection.ty_selectionTables[_2_e_idx].t_tempTableName,
      q4selection.ty_selectionTables[_2_e_idx].t_pkFieldName,
      q4selection.ty_selectionTables[_2_e_idx].t_pkTypeSQL
      );
    q4selection.ty_selectionTables[_2_e_idx].b_isCreated := True;
  End;

Function InternalFindAliasInArray( Const _1_ty_aliases: q4setsAndNamedSelectionsCore.Tty_selectionAlias; Const _2_e_sourceTableId: int64; Const _3_t_name: string;
  out _4_t_tableName: string; out _5_e_resultNo: int64): boolean;
  Var
    _e_i: int64;
  Begin
    Result := False;
    _4_t_tableName := '';
    _5_e_resultNo := 0;

    For _e_i := 0 To System.High( _1_ty_aliases) Do If ( ( _1_ty_aliases[_e_i].e_sourceTableId = _2_e_sourceTableId) and ( _1_ty_aliases[_e_i].e_kind =
        qsakNamedSelection) and ( _1_ty_aliases[_e_i].t_name = _3_t_name)) Then Begin
        _4_t_tableName := _1_ty_aliases[_e_i].t_tableName;
        _5_e_resultNo := _1_ty_aliases[_e_i].e_resultNo;
        Result := True;
        Exit;
      End;
  End;

Function InternalResolveSelectionSource( Var _1_p_recordTable; Const _2_t_tNamedSelection: string; out _3_y_source: Tq4ResolvedSelectionSource): boolean;
  Var
    _e_idx: int64;
    _e_sourceTableId: int64;
    _t_aliasTableName: string;
    _e_aliasResultNo: int64;
  Begin
    Result := False;

    _3_y_source.SourceTableName := '';
    _3_y_source.TempTableName := '';
    _3_y_source.PkFieldName := '';
    _3_y_source.PkTypeSQL := '';
    _3_y_source.ResultNo := 0;
    _3_y_source.RecordCount := 0;

    InternalEnsureSelectionState( _1_p_recordTable, _e_idx);

    _3_y_source.SourceTableName := q4selection.ty_selectionTables[_e_idx].t_sourceTableName;
    _3_y_source.PkFieldName := q4selection.ty_selectionTables[_e_idx].t_pkFieldName;
    _3_y_source.PkTypeSQL := q4selection.ty_selectionTables[_e_idx].t_pkTypeSQL;

    If ( SysUtils.Trim( _2_t_tNamedSelection) = '') Then Begin
      q4interruptions.assertRaise(
        q4selection.ty_selectionTables[_e_idx].e_buildState in [sbsNone, sbsMaterialized],
        'q4arrays.InternalResolveSelectionSource : sélection pending non matérialisée'
        );

      _3_y_source.TempTableName := q4selection.ty_selectionTables[_e_idx].t_tempTableName;
      _3_y_source.ResultNo := q4selection.ty_selectionTables[_e_idx].e_currentResultNo;
      _3_y_source.RecordCount := q4selection.ty_selectionTables[_e_idx].e_recordCount;
      Result := True;
      Exit;
    End;

    _e_sourceTableId := q4selection.ty_selectionTables[_e_idx].e_sourceTableId;

    If ( q4setsAndNamedSelectionsCore.isSharedAliasName( _2_t_tNamedSelection)) Then
      Result := InternalFindAliasInArray( q4setsAndNamedSelectionsCore.ty_sharedSelectionAliases, _e_sourceTableId, _2_t_tNamedSelection, _t_aliasTableName, _e_aliasResultNo)
    Else
      Result := InternalFindAliasInArray( q4setsAndNamedSelectionsCore.ty_localSelectionAliases, _e_sourceTableId, _2_t_tNamedSelection, _t_aliasTableName, _e_aliasResultNo);

    If ( not Result) Then Exit;

    _3_y_source.TempTableName := _t_aliasTableName;
    _3_y_source.ResultNo := _e_aliasResultNo;
  End;

Procedure InternalResizeTargetArray( Const _1_y_target: Tq4ArrayRef; Const _2_e_eCount: int64);
  Begin
    //dimensionne les tableaux de receptions des colonnes et vide l'élément 0 des tableaux (qui ne sera pas rempli, car cela démarre à 1)
    Case _1_y_target.Kind Of
      akText: Begin
        SetLength( Pq4TextArray( _1_y_target.Data)^, _2_e_eCount + 1);
        Pq4TextArray( _1_y_target.Data)^[0] := '';
      End;

      akDate: Begin
        SetLength( Pq4DateArray( _1_y_target.Data)^, _2_e_eCount + 1);
        Pq4DateArray( _1_y_target.Data)^[0] := '';
      End;

      akTime: Begin
        SetLength( Pq4TimeArray( _1_y_target.Data)^, _2_e_eCount + 1);
        Pq4TimeArray( _1_y_target.Data)^[0] := '';
      End;

      akObject: SetLength( Pq4ObjectArray( _1_y_target.Data)^, _2_e_eCount + 1);

      //akLongint: begin
      //  SetLength(Pq4LongintArray(ATarget.Data)^, eCount + 1);
      //  Pq4LongintArray(ATarget.Data)^[0] := 0;
      //end;

      akInt64: Begin
        SetLength( Pq4Int64Array( _1_y_target.Data)^, _2_e_eCount + 1);
        Pq4Int64Array( _1_y_target.Data)^[0] := 0;
      End;

      akReal: Begin
        SetLength( Pq4RealArray( _1_y_target.Data)^, _2_e_eCount + 1);
        Pq4RealArray( _1_y_target.Data)^[0] := 0;
      End;

      akBoolean: Begin
        SetLength( Pq4BooleanArray( _1_y_target.Data)^, _2_e_eCount + 1);
        Pq4BooleanArray( _1_y_target.Data)^[0] := False;
      End;

      akBlob: Begin
        SetLength( Pq4BlobArray( _1_y_target.Data)^, _2_e_eCount + 1);
        SetLength( Pq4BlobArray( _1_y_target.Data)^[0], 0);
      End;

      akPicture: Begin
        SetLength( Pq4PictureArray( _1_y_target.Data)^, _2_e_eCount + 1);
        SetLength( Pq4PictureArray( _1_y_target.Data)^[0], 0);
      End;

      Else q4interruptions.assertRaise( 'q4arrays.InternalResizeTargetArray : type de tableau cible non supporté');
    End;
  End;

Procedure internalAssignQueryValueToTarget( Const _1_y_target: Tq4ArrayRef; Const _2_e_eIndex: int64; Const _3_y_field: TField);
  Begin
    Case _1_y_target.Kind Of
      akText: Pq4TextArray( _1_y_target.Data)^[_2_e_eIndex] := _3_y_field.AsString;
      akDate: Pq4DateArray( _1_y_target.Data)^[_2_e_eIndex] := _3_y_field.AsString;
      akTime: Pq4TimeArray( _1_y_target.Data)^[_2_e_eIndex] := _3_y_field.AsString;
      akObject: Raise Exception.Create( 'q4arrays.InternalAssignQueryValueToTarget : conversion SQL -> Object non implémentée');

      //akLongint: begin
      //  q4interruptions.assertRaise(
      //    (AField.AsLargeInt >= Low(longint)) and (AField.AsLargeInt <= High(longint)),
      //    'q4arrays.InternalAssignQueryValueToTarget : valeur hors plage LongInt'
      //    );
      //  Pq4LongintArray(ATarget.Data)^[eIndex] := longint(AField.AsLargeInt);
      //end;

      akInt64: Pq4Int64Array( _1_y_target.Data)^[_2_e_eIndex] := _3_y_field.AsLargeInt;
      akReal: Pq4RealArray( _1_y_target.Data)^[_2_e_eIndex] := _3_y_field.AsFloat;
      akBoolean: Pq4BooleanArray( _1_y_target.Data)^[_2_e_eIndex] := _3_y_field.AsBoolean;
      akBlob: Pq4BlobArray( _1_y_target.Data)^[_2_e_eIndex] := InternalFieldToBytes( _3_y_field);
      akPicture: Pq4PictureArray( _1_y_target.Data)^[_2_e_eIndex] := InternalFieldToBytes( _3_y_field);

      Else q4interruptions.assertRaise( False,
          'q4arrays.InternalAssignQueryValueToTarget : type cible non supporté');
    End;
  End;

Procedure internalNormalizeRange( Const _1_e_eRecordCount: int64; Var _2_e_eStartPos: int64; Var _3_e_eEndPos: int64; out _4_b_bEmpty: boolean);
  Begin
    _4_b_bEmpty := False;

    If ( _1_e_eRecordCount <= 0) Then Begin
      _4_b_bEmpty := True;
      Exit;
    End;

    If ( ( _2_e_eStartPos < 1) and ( _3_e_eEndPos < 1)) Then Begin
      _4_b_bEmpty := True;
      Exit;
    End;

    If ( _2_e_eStartPos > _1_e_eRecordCount) Then Begin
      _4_b_bEmpty := True;
      Exit;
    End;

    If ( _3_e_eEndPos > _1_e_eRecordCount) Then _3_e_eEndPos := _1_e_eRecordCount;

    If ( _2_e_eStartPos < 1) Then _2_e_eStartPos := 1;

    If ( _2_e_eStartPos > _3_e_eEndPos) Then _3_e_eEndPos := _2_e_eStartPos;
  End;

Function InternalFindFieldMetaByTableAndFieldNo( Const _1_e_eTableId, _2_e_eFieldNo: int64; out _3_y_yField: TFieldMeta): boolean;
  Var
    _e_i: int64;
  Begin
    Result := False;
    For _e_i := 0 To System.High( Fields) Do If ( ( Fields[_e_i].TableRef = _1_e_eTableId) and ( Fields[_e_i].FieldNo = _2_e_eFieldNo)) Then Begin
        _3_y_yField := Fields[_e_i];
        Result := True;
        Exit;
      End;
  End;

Function InternalFindTableNameBySourceTableId( Const _1_e_eTableId: int64; out _2_t_tTableName: string): boolean;
  Var
    _e_i: int64;
  Begin
    Result := False;
    _2_t_tTableName := '';
    For _e_i := 0 To System.High( Tables) Do If ( Tables[_e_i].SourceTableId = _1_e_eTableId) Then Begin
        _2_t_tTableName := Tables[_e_i].Name;
        Result := True;
        Exit;
      End;
  End;

Function InternalResolveSelectionSqlSpec( Var _1_p_recordTable; Const _2_y_request: Tq4selectionArrayRequest; out _3_t_tSelectExpr: string; out _4_t_tJoinSql: string): boolean;
  Var
    eSourceTableId: int64;
    yField: TFieldMeta;
    yTargetTable: TTableMeta;
    tyPath: q4coreRelations.Tq4RelationPath;
    bIsLocalField: boolean;
    _e_i:   int64;
    ySourceLinkField: TFieldMeta;
    yTargetLinkField: TFieldMeta;
    tTargetTableName: string;
    tSourceAlias: string;
    tTargetAlias: string;
  Begin
    Result := False;
    _3_t_tSelectExpr := '';
    _4_t_tJoinSql := '';

    If ( _2_y_request.FieldPtr = nil) Then Begin
      _3_t_tSelectExpr := 's.rowid';
      Result := True;
      Exit;
    End;

    eSourceTableId := q4DBschemaUse.getSourceTableId( _1_p_recordTable);

    If ( not q4coreRelations.resolveLinkedFieldPathForSourceTableId( eSourceTableId, _2_y_request.FieldPtr, bIsLocalField, yField, tyPath, yTargetTable)) Then Exit;

    If ( bIsLocalField) Then Begin
      _3_t_tSelectExpr := 's.' + yField.Name;
      Result := True;
      Exit;
    End;

    q4interruptions.assertRaise(
      System.Length( tyPath) > 0,
      'q4arrays.InternalResolveSelectionSqlSpec : chemin many-to-one introuvable'
      );

    For _e_i := 0 To System.High( tyPath) Do Begin
      q4interruptions.assertRaise(
        InternalFindFieldMetaByTableAndFieldNo( tyPath[_e_i].e_sourceTableId, tyPath[_e_i].e_sourceFieldNo, ySourceLinkField),
        'q4arrays.InternalResolveSelectionSqlSpec : champ source de lien introuvable'
        );
      q4interruptions.assertRaise(
        InternalFindFieldMetaByTableAndFieldNo( tyPath[_e_i].e_targetTableId, tyPath[_e_i].e_targetFieldNo, yTargetLinkField),
        'q4arrays.InternalResolveSelectionSqlSpec : champ cible de lien introuvable'
        );
      q4interruptions.assertRaise(
        InternalFindTableNameBySourceTableId( tyPath[_e_i].e_targetTableId, tTargetTableName),
        'q4arrays.InternalResolveSelectionSqlSpec : table cible de lien introuvable'
        );

      If ( _e_i = 0) Then tSourceAlias := 's'
      Else
        tSourceAlias := 'j' + IntToStr( _e_i);

      tTargetAlias := 'j' + IntToStr( _e_i + 1);

      _4_t_tJoinSql := _4_t_tJoinSql + ' LEFT JOIN ' + tTargetTableName + ' ' + tTargetAlias + ' ON ' + tSourceAlias + '.' + ySourceLinkField.Name +
        ' = ' + tTargetAlias + '.' + yTargetLinkField.Name + ' ';
    End;

    _3_t_tSelectExpr := 'j' + IntToStr( System.Length( tyPath)) + '.' + yField.Name;
    Result := True;
  End;

Function InternalBuildSelectionArraySql( Const _1_y_source: Tq4ResolvedSelectionSource; Const _2_t_tSelectExpr: string; Const _3_t_tJoinSql: string; Const _4_b_bRange: boolean): string;
  Begin
    Result :=
      'SELECT ' + _2_t_tSelectExpr + ' AS q4value ' + 'FROM ' + _1_y_source.SourceTableName + ' s ' + 'INNER JOIN ' + _1_y_source.TempTableName + ' t ' +
      'ON s.' + _1_y_source.PkFieldName + ' = t.' + _1_y_source.PkFieldName + ' ' + _3_t_tJoinSql + 'WHERE t.noResultat = :noResultat ';

    If ( _4_b_bRange) Then Result := Result + 'AND t.pos BETWEEN :startPos AND :endPos ';

    Result := Result + 'ORDER BY t.pos';
  End;

Procedure InternalFillOneArrayFromSelectionSql( Var _1_p_recordTable; Const _2_y_source: Tq4ResolvedSelectionSource; Const _3_y_request: Tq4selectionArrayRequest;
  Const _4_b_bRange: boolean; Const _5_e_eStartPos, _6_e_eEndPos: int64; Const _7_e_eExpectedCount: int64);
  Var
    _o_query: TSQLQuery;
    _t_sql: string;
    _t_selectExpr: string;
    _t_joinSql: string;
    _e_i: int64;
  Begin
    InternalResizeTargetArray( _3_y_request.Target, _7_e_eExpectedCount);

    If ( _7_e_eExpectedCount = 0) Then Exit;

    q4interruptions.assertRaise(
      InternalResolveSelectionSqlSpec( _1_p_recordTable, _3_y_request, _t_selectExpr, _t_joinSql),
      'q4arrays.InternalFillOneArrayFromSelectionSql : champ introuvable'
      );

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;

      _t_sql := InternalBuildSelectionArraySql( _2_y_source, _t_selectExpr, _t_joinSql, _4_b_bRange);

      _o_query.SQL.Text := _t_sql;
      _o_query.ParamByName( 'noResultat').AsInteger := _2_y_source.ResultNo;

      If ( _4_b_bRange) Then Begin
        _o_query.ParamByName( 'startPos').AsInteger := _5_e_eStartPos;
        _o_query.ParamByName( 'endPos').AsInteger := _6_e_eEndPos;
      End;

      _o_query.Open;

      _e_i := 1;
      While ( ( not _o_query.EOF) and ( _e_i <= _7_e_eExpectedCount)) Do Begin
        InternalAssignQueryValueToTarget( _3_y_request.Target, _e_i, _o_query.FieldByName( 'q4value'));
        Inc( _e_i);
        _o_query.Next;
      End;
    Finally
      _o_query.Free;
    End;
  End;

Procedure InternalLoadRecordNumbersInt64( Const _1_y_source: Tq4ResolvedSelectionSource; Var _2_te_recordNumbers: Tq4Int64Array);
  Var
    _o_query:    TSQLQuery;
    _t_sql:      string;
    _e_rowIndex: int64;
  Begin
    SetLength( _2_te_recordNumbers, 1);
    _2_te_recordNumbers[0] := -1;

    If ( _1_y_source.ResultNo <= 0) Then Exit;

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;

      _t_sql :=
        'SELECT s.rowid AS q4rowid ' + 'FROM ' + _1_y_source.SourceTableName + ' s ' + 'INNER JOIN ' + _1_y_source.TempTableName + ' t ' + 'ON s.' +
        _1_y_source.PkFieldName + ' = t.' + _1_y_source.PkFieldName + ' ' + 'WHERE t.noResultat = :noResultat ' + 'ORDER BY t.pos';

      _o_query.SQL.Text := _t_sql;
      _o_query.ParamByName( 'noResultat').AsInteger := _1_y_source.ResultNo;
      _o_query.Open;

      _e_rowIndex := 1;
      While ( not _o_query.EOF) Do Begin
        SetLength( _2_te_recordNumbers, _e_rowIndex + 1);
        _2_te_recordNumbers[_e_rowIndex] := _o_query.FieldByName( 'q4rowid').AsLargeInt;
        Inc( _e_rowIndex);
        _o_query.Next;
      End;
    Finally
      _o_query.Free;
    End;
  End;

//procedure InternalLoadRecordNumbersInt32(const y_source: Tq4ResolvedSelectionSource; var ARecordNumbers: Tq4LongintArray);
//var
//  te_rowIds: Tq4Int64Array;
//  e_i: Int64;
//begin
//  InternalLoadRecordNumbersInt64(y_source, te_rowIds);

//  SetLength(ARecordNumbers, Length(te_rowIds));
//  if Length(ARecordNumbers) > 0 then ARecordNumbers[0] := -1;

//  for e_i := 1 to High(te_rowIds) do begin
//    q4interruptions.assertRaise(
//      (te_rowIds[e_i] >= Low(longint)) and (te_rowIds[e_i] <= High(longint)),
//      'q4arrays.longintArrayFromSelection : rowid hors plage LongInt'
//      );
//    ARecordNumbers[e_i] := longint(te_rowIds[e_i]);
//  end;
//end;

Procedure selectionToArray( Var _1_p_recordTable; Const _2_ty_requests: Array Of Tq4selectionArrayRequest);
  Var
    _y_source: Tq4ResolvedSelectionSource;
    _e_i:      int64;
  Begin

    {
  Pour SELECTION TO ARRAY et SELECTION RANGE TO ARRAY, l’élément 0 est conservé mais explicitement vidé ; les valeurs issues de la sélection commencent à l’index 1.

  Pour selectionToArray et selectionRangeToArray :
  taille physique = eCount + 1
  index 0 toujours présent
  index 0 vidé / valeur par défaut
  remplissage SQL à partir de 1
  }

    q4RecordLocking.unloadRecord( _1_p_recordTable);

    If ( Length( _2_ty_requests) = 0) Then Exit;

    q4interruptions.assertRaise(
      InternalResolveSelectionSource( _1_p_recordTable, '', _y_source),
      'q4arrays.selectionToArray : source de sélection introuvable'
      );

    For _e_i := 0 To High( _2_ty_requests) Do InternalFillOneArrayFromSelectionSql(
        _1_p_recordTable,
        _y_source,
        _2_ty_requests[_e_i],
        False,
        0,
        0,
        _y_source.RecordCount
        );

  End;

Procedure selectionRangeToArray( Var _1_p_recordTable; Const _2_e_eStartPos, _3_e_eEndPos: int64; Const _4_ty_requests: Array Of Tq4selectionArrayRequest);
  Var
    _y_source: Tq4ResolvedSelectionSource;
    eStartNorm: int64;
    eEndNorm: int64;
    eCount: int64;
    bEmpty: boolean;
    _e_i: int64;
  Begin

    q4RecordLocking.unloadRecord( _1_p_recordTable);

    If ( Length( _4_ty_requests) = 0) Then Exit;

    q4interruptions.assertRaise(
      InternalResolveSelectionSource( _1_p_recordTable, '', _y_source),
      'q4arrays.selectionRangeToArray : source de sélection introuvable'
      );

    eStartNorm := _2_e_eStartPos;
    eEndNorm := _3_e_eEndPos;
    InternalNormalizeRange( _y_source.RecordCount, eStartNorm, eEndNorm, bEmpty);

    If ( bEmpty) Then Begin
      For _e_i := 0 To High( _4_ty_requests) Do InternalResizeTargetArray( _4_ty_requests[_e_i].Target, 0);

      Exit;
    End;

    eCount := eEndNorm - eStartNorm + 1;

    For _e_i := 0 To High( _4_ty_requests) Do InternalFillOneArrayFromSelectionSql(
        _1_p_recordTable,
        _y_source,
        _4_ty_requests[_e_i],
        True,
        eStartNorm,
        eEndNorm,
        eCount
        );

  End;

//procedure longintArrayFromSelection(var ARecordTable; var ARecordNumbers: Tq4LongintArray);
//var
//  y_source: Tq4ResolvedSelectionSource;
//begin
//  q4interruptions.assertRaise(
//    InternalResolveSelectionSource(ARecordTable, '', y_source),
//    'q4arrays.longintArrayFromSelection : source de sélection introuvable'
//    );

//  InternalLoadRecordNumbersInt32(y_source, ARecordNumbers);
//end;

//procedure longintArrayFromSelection(var ARecordTable; const tNamedSelection: string; var ARecordNumbers: Tq4LongintArray);
//var
//  y_source: Tq4ResolvedSelectionSource;
//begin
//  q4interruptions.assertRaise(
//    InternalResolveSelectionSource(ARecordTable, tNamedSelection, y_source),
//    'q4arrays.longintArrayFromSelection(named) : named selection introuvable'
//    );

//  InternalLoadRecordNumbersInt32(y_source, ARecordNumbers);
//end;

Procedure Int64ArrayFromSelection( Var _1_p_recordTable; Var _2_te_recordNumbers: Tq4Int64Array);
  Var
    _y_source: Tq4ResolvedSelectionSource;
  Begin
    q4interruptions.assertRaise(
      InternalResolveSelectionSource( _1_p_recordTable, '', _y_source),
      'q4arrays.Int64ArrayFromSelection : source de sélection introuvable'
      );

    InternalLoadRecordNumbersInt64( _y_source, _2_te_recordNumbers);
  End;

Procedure Int64ArrayFromSelection( Var _1_p_recordTable; Const _2_t_tNamedSelection: string; Var _3_te_recordNumbers: Tq4Int64Array);
  Var
    _y_source: Tq4ResolvedSelectionSource;
  Begin
    q4interruptions.assertRaise(
      InternalResolveSelectionSource( _1_p_recordTable, _2_t_tNamedSelection, _y_source),
      'q4arrays.Int64ArrayFromSelection(named) : named selection introuvable'
      );

    InternalLoadRecordNumbersInt64( _y_source, _3_te_recordNumbers);
  End;

Procedure Int64ArrayFromSelection( Var _1_p_recordTable; Const _2_y_recordNumbersRef: q4ref.TQ4Ref);
  Begin
    q4RequireArrayKind( _2_y_recordNumbersRef, akInt64, 'Int64ArrayFromSelection');
    Int64ArrayFromSelection( _1_p_recordTable, q4ref.Pq4Int64Array( _2_y_recordNumbersRef.Ptr)^);
  End;

Procedure Int64ArrayFromSelection( Var _1_p_recordTable; Const _2_t_tNamedSelection: string; Const _3_y_recordNumbersRef: q4ref.TQ4Ref);
  Begin
    q4RequireArrayKind( _3_y_recordNumbersRef, akInt64, 'Int64ArrayFromSelection');
    Int64ArrayFromSelection( _1_p_recordTable, _2_t_tNamedSelection, q4ref.Pq4Int64Array( _3_y_recordNumbersRef.Ptr)^);
  End;

Function internalReadArrayValueAt( Const _1_y_source: Tq4ArrayRef; Const _2_e_eIndex: int64): variant;
  Begin
    Case _1_y_source.Kind Of
      akText: Result := Pq4TextArray( _1_y_source.Data)^[_2_e_eIndex];
      akDate: Result := Pq4DateArray( _1_y_source.Data)^[_2_e_eIndex];
      akTime: Result := Pq4TimeArray( _1_y_source.Data)^[_2_e_eIndex];
      akObject: Begin
        Raise Exception.Create( 'q4arrays.InternalReadArrayValueAt : conversion Object -> Variant non implémentée');
        Result := Null;
      End;
      //akLongint: Result := Pq4LongintArray(ASource.Data)^[eIndex];
      akInt64: Result := Pq4Int64Array( _1_y_source.Data)^[_2_e_eIndex];
      akReal: Result := Pq4RealArray( _1_y_source.Data)^[_2_e_eIndex];
      akBoolean: Result := Pq4BooleanArray( _1_y_source.Data)^[_2_e_eIndex];
      akBlob: Result := q4coreLanguage.bytesToVariant( Pq4BlobArray( _1_y_source.Data)^[_2_e_eIndex]);
      akPicture: Result := q4coreLanguage.bytesToVariant( Pq4PictureArray( _1_y_source.Data)^[_2_e_eIndex]);
      Else q4interruptions.assertRaise( False,
          'q4arrays.InternalReadArrayValueAt : type source non supporté');
        Result := Null;
    End;
  End;

Procedure internalAddLockedRowId( Var _1_te_rowIds: Tq4Int64Array; Const _2_e_eRowId: int64);
  Var
    eLen: int64;
  Begin
    If ( _2_e_eRowId <= 0) Then Exit;

    eLen := Length( _1_te_rowIds);
    SetLength( _1_te_rowIds, eLen + 1);
    _1_te_rowIds[eLen] := _2_e_eRowId;
  End;

Procedure InternalEnsureCurrentSelectionResult( Var _1_y_state: q4selection.Ty_selectionTableState);
  Begin
    If ( _1_y_state.e_currentResultNo > 0) Then Exit;

    _1_y_state.e_currentResultNo := _1_y_state.e_nextResultNo;
    Inc( _1_y_state.e_nextResultNo);

    _1_y_state.e_currentPos := 0;
    _1_y_state.e_recordCount := 0;
    _1_y_state.b_isEmpty := True;
    _1_y_state.e_buildState := sbsMaterialized;
  End;

Function InternalReadPkFromRowId( Const _1_y_source: Tq4ResolvedSelectionSource; Const _2_e_eRowId: int64): variant;
  Var
    _o_query: TSQLQuery;
    _t_sql:   string;
  Begin
    Result := Null;

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;

      _t_sql :=
        'SELECT ' + _1_y_source.PkFieldName + ' ' + 'FROM ' + _1_y_source.SourceTableName + ' ' + 'WHERE rowid = :rowid';

      _o_query.SQL.Text := _t_sql;
      _o_query.ParamByName( 'rowid').AsLargeInt := _2_e_eRowId;
      _o_query.Open;

      If ( not _o_query.EOF) Then Result := _o_query.Fields[0].Value;
    Finally
      _o_query.Free;
    End;
  End;

Procedure InternalAppendPkToCurrentSelection( Var _1_y_state: q4selection.Ty_selectionTableState; Const _2_y_vPk: variant; Const _3_e_ePos: int64);
  Var
    _o_query: TSQLQuery;
    _t_sql:   string;
  Begin
    q4interruptions.assertRaise( _1_y_state.e_currentResultNo > 0,
      'q4arrays.InternalAppendPkToCurrentSelection : resultNo courant invalide');

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;

      _t_sql :=
        'INSERT INTO ' + _1_y_state.t_tempTableName + ' (' + _1_y_state.t_pkFieldName + ', pos, noResultat) ' + 'VALUES (:pk, :pos, :noResultat)';

      _o_query.SQL.Text := _t_sql;
      _o_query.ParamByName( 'pk').Value := _2_y_vPk;
      _o_query.ParamByName( 'pos').AsInteger := _3_e_ePos;
      _o_query.ParamByName( 'noResultat').AsInteger := _1_y_state.e_currentResultNo;
      _o_query.ExecSQL;
    Finally
      _o_query.Free;
    End;

    _1_y_state.e_recordCount := _3_e_ePos;
    _1_y_state.b_isEmpty := False;
    _1_y_state.e_buildState := sbsMaterialized;
  End;

Procedure InternalFinalizeLockedSetFromRowIds( Var _1_p_recordTable; Const _2_te_rowIds: Tq4Int64Array);
  Var
    _te_rowIds: q4selection.Tq4Int64Array;
    _e_i: int64;
  Begin
    { On reconstruit toujours LockedSet, même vide, afin d'éviter
    qu'un ancien LockedSet survive à un nouvel ARRAY TO SELECTION. }

    If ( Length( _2_te_rowIds) = 0) Then Begin
      q4sets.createEmptySet( _1_p_recordTable, 'LockedSet');
      Exit;
    End;

    SetLength( _te_rowIds, Length( _2_te_rowIds));
    For _e_i := Low( _2_te_rowIds) To High( _2_te_rowIds) Do _te_rowIds[_e_i] := _2_te_rowIds[_e_i];

    q4sets.createSetFromArray( _1_p_recordTable, _te_rowIds, 'LockedSet');
  End;


Procedure arrayToSelection( Var _1_p_recordTable; Const _2_ty_bindings: Array Of Tq4ArrayToSelectionBinding; Const _3_t_tStar: string);
  Var
    _e_idx: int64;
    _y_source: Tq4ResolvedSelectionSource;
    _p_runtime: Pq4recordRuntime;
    _te_bindingIndexes: Array Of integer;
    _te_lockedRowIds: Tq4Int64Array;
    eLockedRowId: int64;
    eArrayCount: int64;
    eExistingCount: int64;
    _e_i, _e_j, eCount, eLen: int64;
    bTableReadonly: boolean;
    _y_value: variant;
    _v_pk: variant;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenCommand,
          'q4arrays.arrayToSelection interdit pendant un trigger'
          );

    If ( _3_t_tStar = '*') Then RaiseTodo( 'q4arrays.arrayToSelection', 'mode différé *');

    If ( Length( _2_ty_bindings) = 0) Then Begin
      q4RecordLocking.unloadRecord( _1_p_recordTable);
      Exit;
    End;

    InternalEnsureSelectionState( _1_p_recordTable, _e_idx);

    q4interruptions.assertRaise(
      q4selection.ty_selectionTables[_e_idx].e_buildState in [sbsNone, sbsMaterialized],
      'q4arrays.arrayToSelection : sélection pending non matérialisée'
      );

    InternalEnsureCurrentSelectionResult( q4selection.ty_selectionTables[_e_idx]);

    q4interruptions.assertRaise(
      InternalResolveSelectionSource( _1_p_recordTable, '', _y_source),
      'q4arrays.arrayToSelection : source de sélection introuvable'
      );

    SetLength( _te_bindingIndexes, Length( _2_ty_bindings));
    eArrayCount := -1;

    For _e_i := 0 To High( _2_ty_bindings) Do Begin
      _te_bindingIndexes[_e_i] := q4DBschemaUse.findLocalBindingIndex( _1_p_recordTable, _2_ty_bindings[_e_i].FieldPtr);
      q4interruptions.assertRaise(
        _te_bindingIndexes[_e_i] >= 0,
        'q4arrays.arrayToSelection : seul un champ local de la table source est accepté'
        );

      eLen := GetArrayLength( _2_ty_bindings[_e_i].Source) - 1;
      If ( eLen < 0) Then eLen := 0;

      If ( eArrayCount < 0) Then eArrayCount := eLen
      Else
        q4interruptions.assertRaise(
          eLen = eArrayCount,
          'q4arrays.arrayToSelection : tous les tableaux doivent avoir la même taille logique'
          );
    End;

    If ( eArrayCount < 0) Then eArrayCount := 0;

    eExistingCount := _y_source.RecordCount;
    bTableReadonly := q4RecordLocking.readOnlyState( _1_p_recordTable);

    For _e_i := 1 To eArrayCount Do If ( _e_i <= eExistingCount) Then Begin
        q4selection.gotoSelectedRecord( _1_p_recordTable, _e_i);

        If ( not _p_runtime^._Loaded) Then Continue;

        { 4D ignore le readonly de table pour cette commande }
        If ( bTableReadonly) Then _p_runtime^._ReadWrite := True
        Else If ( not _p_runtime^._ReadWrite) Then Begin
          { record verrouillé / non modifiable }
          eLockedRowId := q4record.recordNumber( _1_p_recordTable);
          InternalAddLockedRowId( _te_lockedRowIds, eLockedRowId);
          Continue;
        End;

        For _e_j := 0 To High( _2_ty_bindings) Do Begin
          _y_value := InternalReadArrayValueAt( _2_ty_bindings[_e_j].Source, _e_i);
          q4record.writeBindingValue( _p_runtime^._Bindings[_te_bindingIndexes[_e_j]], _y_value);
        End;

        q4record.saveRecord( _1_p_recordTable);
      End Else Begin
        { records manquants à créer }
        q4record.createRecord( _1_p_recordTable);

        For _e_j := 0 To High( _2_ty_bindings) Do Begin
          _y_value := InternalReadArrayValueAt( _2_ty_bindings[_e_j].Source, _e_i);
          q4record.writeBindingValue( _p_runtime^._Bindings[_te_bindingIndexes[_e_j]], _y_value);
        End;

        q4record.saveRecord( _1_p_recordTable);

        _v_pk := InternalReadPkFromRowId( _y_source, _p_runtime^._RowId);
        InternalAppendPkToCurrentSelection( q4selection.ty_selectionTables[_e_idx], _v_pk, _e_i);
      End;

    If ( eExistingCount > eArrayCount) Then eCount := eExistingCount
    Else
      eCount := eArrayCount;

    q4selection.ty_selectionTables[_e_idx].e_recordCount := eCount;
    q4selection.ty_selectionTables[_e_idx].b_isEmpty := ( eCount = 0);
    q4selection.ty_selectionTables[_e_idx].e_currentPos := 0;
    q4selection.ty_selectionTables[_e_idx].e_buildState := sbsMaterialized;

    q4RecordLocking.unloadRecord( _1_p_recordTable);
    InternalFinalizeLockedSetFromRowIds( _1_p_recordTable, _te_lockedRowIds);
  End;

Procedure flushDeferredArrayToSelection;
  Begin
    q4interruptions.raiseTodo( 'q4arrays.flushDeferredArrayToSelection', 'exécution différée des ARRAY TO SELECTION empilés');
  End;

Procedure arrayToList( Const _1_t_tListName: string; Const _2_tt_labels: Tq4TextArray);
  Begin
    q4coreLanguage.Error := 0;
    q4interruptions.raiseTodo( 'q4arrays.arrayToList(name)', 'registry runtime des named lists');
  End;

Procedure arrayToList( Const _1_t_tListName: string; Const _2_tt_labels: Tq4TextArray; Const _3_te_refs: Tq4Int64Array);
  Begin
    q4coreLanguage.Error := 0;
    q4interruptions.raiseTodo( 'q4arrays.arrayToList(name,refs)', 'registry runtime des named lists');
  End;

Procedure arrayToList( Const _1_e_eListRef: longint; Const _2_tt_labels: Tq4TextArray);
  Begin
    q4coreLanguage.Error := 0;
    q4interruptions.raiseTodo( 'q4arrays.arrayToList(ref)', 'runtime lists par référence');
  End;

Procedure arrayToList( Const _1_e_eListRef: longint; Const _2_tt_labels: Tq4TextArray; Const _3_te_refs: Tq4Int64Array);
  Begin
    q4coreLanguage.Error := 0;
    q4interruptions.raiseTodo( 'q4arrays.arrayToList(ref,refs)', 'runtime lists par référence');
  End;

Procedure listToArray( Const _1_t_tListName: string; Var _2_tt_labels: Tq4TextArray);
  Begin
    q4coreLanguage.Error := 0;
    q4interruptions.raiseTodo( 'q4arrays.listToArray(name)', 'registry runtime des named lists');
  End;

Procedure listToArray( Const _1_t_tListName: string; Var _2_tt_labels: Tq4TextArray; Var _3_te_refs: Tq4Int64Array);
  Begin
    q4coreLanguage.Error := 0;
    q4interruptions.raiseTodo( 'q4arrays.listToArray(name,refs)', 'registry runtime des named lists');
  End;

Procedure listToArray( Const _1_e_eListRef: longint; Var _2_tt_labels: Tq4TextArray);
  Begin
    q4coreLanguage.Error := 0;
    q4interruptions.raiseTodo( 'q4arrays.listToArray(ref)', 'runtime lists par référence');
  End;

Procedure listToArray( Const _1_e_eListRef: longint; Var _2_tt_labels: Tq4TextArray; Var _3_te_refs: Tq4Int64Array);
  Begin
    q4interruptions.raiseTodo( 'q4arrays.listToArray(ref,refs)', 'runtime lists par référence');
  End;

Procedure arrayToList( Const _1_t_tListName: string; Const _2_y_labelsRef: q4ref.TQ4Ref);
  Begin
    q4RequireArrayKind( _2_y_labelsRef, akText, 'arrayToList');
    arrayToList( _1_t_tListName, q4ref.Pq4TextArray( _2_y_labelsRef.Ptr)^);
  End;

Procedure arrayToList( Const _1_t_tListName: string; Const _2_y_labelsRef, _3_y_refsRef: q4ref.TQ4Ref);
  Begin
    q4RequireArrayKind( _2_y_labelsRef, akText, 'arrayToList');
    q4RequireArrayKind( _3_y_refsRef, akInt64, 'arrayToList');
    arrayToList( _1_t_tListName, q4ref.Pq4TextArray( _2_y_labelsRef.Ptr)^, q4ref.Pq4Int64Array( _3_y_refsRef.Ptr)^);
  End;

Procedure arrayToList( Const _1_e_eListRef: longint; Const _2_y_labelsRef: q4ref.TQ4Ref);
  Begin
    q4RequireArrayKind( _2_y_labelsRef, akText, 'arrayToList');
    arrayToList( _1_e_eListRef, q4ref.Pq4TextArray( _2_y_labelsRef.Ptr)^);
  End;

Procedure arrayToList( Const _1_e_eListRef: longint; Const _2_y_labelsRef, _3_y_refsRef: q4ref.TQ4Ref);
  Begin
    q4RequireArrayKind( _2_y_labelsRef, akText, 'arrayToList');
    q4RequireArrayKind( _3_y_refsRef, akInt64, 'arrayToList');
    arrayToList( _1_e_eListRef, q4ref.Pq4TextArray( _2_y_labelsRef.Ptr)^, q4ref.Pq4Int64Array( _3_y_refsRef.Ptr)^);
  End;

Procedure listToArray( Const _1_t_tListName: string; Const _2_y_labelsRef: q4ref.TQ4Ref);
  Begin
    q4RequireArrayKind( _2_y_labelsRef, akText, 'listToArray');
    listToArray( _1_t_tListName, q4ref.Pq4TextArray( _2_y_labelsRef.Ptr)^);
  End;

Procedure listToArray( Const _1_t_tListName: string; Const _2_y_labelsRef, _3_y_refsRef: q4ref.TQ4Ref);
  Begin
    q4RequireArrayKind( _2_y_labelsRef, akText, 'listToArray');
    q4RequireArrayKind( _3_y_refsRef, akInt64, 'listToArray');
    listToArray( _1_t_tListName, q4ref.Pq4TextArray( _2_y_labelsRef.Ptr)^, q4ref.Pq4Int64Array( _3_y_refsRef.Ptr)^);
  End;

Procedure listToArray( Const _1_e_eListRef: longint; Const _2_y_labelsRef: q4ref.TQ4Ref);
  Begin
    q4RequireArrayKind( _2_y_labelsRef, akText, 'listToArray');
    listToArray( _1_e_eListRef, q4ref.Pq4TextArray( _2_y_labelsRef.Ptr)^);
  End;

Procedure listToArray( Const _1_e_eListRef: longint; Const _2_y_labelsRef, _3_y_refsRef: q4ref.TQ4Ref);
  Begin
    q4RequireArrayKind( _2_y_labelsRef, akText, 'listToArray');
    q4RequireArrayKind( _3_y_refsRef, akInt64, 'listToArray');
    listToArray( _1_e_eListRef, q4ref.Pq4TextArray( _2_y_labelsRef.Ptr)^, q4ref.Pq4Int64Array( _3_y_refsRef.Ptr)^);
  End;

Procedure booleanArrayFromSet;
  Begin
    q4interruptions.raiseUnsupported( 'q4arrays.booleanArrayFromSet', 'commande explicitement hors cible q4');
  End;

Procedure distinctAttributePaths;
  Begin
    q4interruptions.raiseTodo( 'q4arrays.distinctAttributePaths', 'faible priorité / jamais utilisé');
  End;

Procedure distinctAttributeValues;
  Begin
    q4interruptions.raiseTodo( 'q4arrays.distinctAttributeValues', 'faible priorité / jamais utilisé');
  End;

Procedure distinctValues;
  Begin
    q4interruptions.raiseTodo( 'q4arrays.distinctValues', 'faible priorité / jamais utilisé');
  End;

Procedure textToArray;
  Begin
    q4interruptions.raiseTodo( 'q4arrays.textToArray', 'dépend du rendu texte / mesures graphiques');
  End;

End.
