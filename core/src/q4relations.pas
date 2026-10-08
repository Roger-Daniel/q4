unit q4relations;

{$mode objfpc}{$H+}

{
q4relations
version du 2026/04/26-13

Mapping 4D → q4relations -> statut
Command Number 4D,    4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
65,                   CREATE RELATED ONE,                createRelatedOne,                  OK spécifique
899,                  GET AUTOMATIC RELATIONS,           getAutomaticRelations,             OK spécifique
920,                  GET FIELD RELATION,                getFieldRelation,                  OK spécifique
263,                  OLD RELATED MANY,                  oldRelatedMany,                    OK
44,                   OLD RELATED ONE,                   oldRelatedOne,                     OK
262,                  RELATE MANY,                       relateMany,                        OK
340,                  RELATE MANY SELECTION,             relateManySelection,               OK
42,                   RELATE ONE,                        relateOne,                         OK
349,                  RELATE ONE SELECTION,              relateOneSelection,                OK
43,                   SAVE RELATED ONE,                  saveRelatedOne,                    OK spécifique
310,                  SET AUTOMATIC RELATIONS,           setAutomaticRelations,             OK spécifique
919,                  SET FIELD RELATION,                setFieldRelation,                  OK spécifique

Doc: https://developer.4d.com/docs/21/commands/theme/Relations

Notes q4 v1
-----------
- Les relations structurelles sont portées par q4DBschemaBase via
  TableJoinRanges / JoinLinks.

- q4coreRelations porte la résolution structurelle des liens :
  liens directs, chemins relationnels utiles aux autres thèmes, sans état
  process, sans OK/Error, sans sélection courante.

- q4relations porte la sémantique 4D du thème Relations :
  état process des relations, navigation relationnelle, sélection courante,
  et OK/Error quand la commande le documente.

- Au démarrage du process, q4relations crée une copie process des liens
  définis dans q4DBschemaBase. SET FIELD RELATION modifie cette copie process,
  sans modifier q4DBschemaBase.

- SET AUTOMATIC RELATIONS / GET AUTOMATIC RELATIONS utilisent deux indicateurs
  process indépendants des états lien par lien. Ces indicateurs ont priorité
  pour calculer l'état effectif des relations automatiques.

- Les statuts SET FIELD RELATION / SET AUTOMATIC RELATIONS sont pris en compte
  par les commandes Relations automatiques, notamment :
    RELATE ONE(table)
    RELATE MANY(table)

- Les commandes explicites :
    RELATE ONE(field)
    RELATE MANY(field)
  utilisent le lien demandé, même manuel.

- Les commandes :
    QUERY
    ORDER BY
  ne consultent pas l'état process de q4relations. Elles utilisent les liens
  structurels disponibles dans q4DBschemaBase.

- RELATE ONE avec discriminant / choiceField n'est pas supporté en q4 v1.

- q4 v1 ne stocke pas encore les indicateurs 4D Auto Relate One /
  Auto One to Many séparément dans q4DBschemaBase. L'état structurel initial
  copié dans le process est donc défini par convention q4 :
    Many-to-One : Automatic
    One-to-Many : Manual

- Les commandes marquées "OK spécifique" sont implémentées selon la sémantique
  q4 v1, avec les conventions ci-dessus, sans prétendre reproduire des
  métadonnées 4D qui ne sont pas encore portées par le schéma q4.
}

interface

uses
  SysUtils,
  Variants,
  SQLDB;

const
  DO_NOT_MODIFY = int64(0);
  NO_RELATION = int64(0);
  STRUCTURE_CONFIGURATION = int64(1);
  MANUAL = int64(2);
  AUTOMATIC = int64(3);

type
  Tq4Int64Array = array of int64;

procedure createRelatedOne(const _1_p_manyField: Pointer);

procedure getAutomaticRelations(out _1_b_one: boolean; out _2_b_many: boolean);

procedure getFieldRelation(const _1_p_manyField: Pointer; out _2_e_one: int64; out _3_e_many: int64; const _4_t_operator: string = '');

procedure oldRelatedMany(const _1_p_oneField: Pointer);
procedure oldRelatedOne(const _1_p_manyField: Pointer);

procedure relateMany(const _1_p_oneFieldOrTable: Pointer);
procedure relateManySelection(const _1_p_manyField: Pointer);
procedure relateOne(const _1_p_manyField: Pointer);
procedure relateOneSelection(const _1_p_manyTable: Pointer; const _2_p_oneTable: Pointer);

procedure saveRelatedOne(const _1_p_manyField: Pointer);

procedure setAutomaticRelations(_1_b_one: boolean; _2_b_many: boolean = False);

procedure setFieldRelation(const _1_p_manyFieldOrTable: Pointer; _2_e_one: int64; _3_e_many: int64);

function InternalInt64ArrayContains(const _1_te_values: Tq4Int64Array; const _2_e_value: int64): boolean;

procedure InternalAddInt64ToArray(var _1_te_values: Tq4Int64Array; const _2_e_value: int64);

procedure q4relationsInitForThread;
procedure q4relationsDoneForThread;

implementation

uses
  metier_q4DBschemaBase,
  q4coreLanguage,
  q4coreRelations,
  q4DBmanager,
  q4DBschemaUse,
  q4dataEntry,
  q4RecordLocking,
  q4record,
  q4selection;

type
  Tq4ProcessRelation = record
    e_sourceTableId: int64;
    e_sourceFieldId: int64;
    e_targetTableId: int64;
    e_targetFieldId: int64;

    e_structureManyToOne: int64;
    e_structureOneToMany: int64;

    e_currentManyToOne: int64;
    e_currentOneToMany: int64;
  end;

  Tq4ProcessRelationArray = array of Tq4ProcessRelation;

threadvar
  gb_relationsProcessInitialized: boolean;

  { Indicateurs propres à GET/SET AUTOMATIC RELATIONS.
    Ils ne remplacent pas l'état par lien. }
  gb_automaticOne: boolean;
  gb_automaticMany: boolean;

  { Copie process des JoinLinks globaux. }
  ty_processRelations: Tq4ProcessRelationArray;

function InternalStructureManyToOneStatus: int64;
begin
  Result := AUTOMATIC;
end;

function InternalStructureOneToManyStatus: int64;
begin
  Result := MANUAL;
end;

function InternalEffectiveManyToOneStatus(const _1_e_processRelationIndex: int64): int64;
begin
  Result := MANUAL;

  if ((_1_e_processRelationIndex < 0) or (_1_e_processRelationIndex > System.High(ty_processRelations))) then Exit;

  Result := ty_processRelations[_1_e_processRelationIndex].e_currentManyToOne;

  if (gb_automaticOne) then Result := AUTOMATIC;
end;

procedure InternalCopyStructureRelationsToProcess;
var
  _e_i: int64;
begin
  System.SetLength(ty_processRelations, System.Length(JoinLinks));

  for _e_i := 0 to System.High(JoinLinks) do begin
    ty_processRelations[_e_i].e_sourceTableId := JoinLinks[_e_i].SourceTableId;
    ty_processRelations[_e_i].e_sourceFieldId := JoinLinks[_e_i].SourceFieldId;
    ty_processRelations[_e_i].e_targetTableId := JoinLinks[_e_i].TargetTableId;
    ty_processRelations[_e_i].e_targetFieldId := JoinLinks[_e_i].TargetFieldId;

    ty_processRelations[_e_i].e_structureManyToOne := InternalStructureManyToOneStatus;
    ty_processRelations[_e_i].e_structureOneToMany := InternalStructureOneToManyStatus;

    ty_processRelations[_e_i].e_currentManyToOne :=
      ty_processRelations[_e_i].e_structureManyToOne;
    ty_processRelations[_e_i].e_currentOneToMany :=
      ty_processRelations[_e_i].e_structureOneToMany;
  end;
end;

procedure InternalInitializeProcessState;
begin
  if (gb_relationsProcessInitialized) then Exit;

  gb_automaticOne := False;
  gb_automaticMany := False;

  InternalCopyStructureRelationsToProcess;

  gb_relationsProcessInitialized := True;
end;

procedure InternalClearError;
begin
  q4coreLanguage.Error := 0;
end;

procedure InternalSetNoRelation;
begin
  q4coreLanguage.Error := 16;
end;

procedure q4relationsInitForThread;
begin
  gb_relationsProcessInitialized := False;
  InternalInitializeProcessState;
end;

procedure q4relationsDoneForThread;
begin
  gb_relationsProcessInitialized := False;
  gb_automaticOne := False;
  gb_automaticMany := False;
  System.SetLength(ty_processRelations, 0);
end;

function InternalSqlQuote(const _1_t_value: string): string;
begin
  Result := '''' + SysUtils.StringReplace(_1_t_value, '''', '''''', [rfReplaceAll]) + '''';
end;


function InternalEffectiveOneToManyStatus(const _1_e_processRelationIndex: int64): int64;
begin
  Result := MANUAL;

  if ((_1_e_processRelationIndex < 0) or (_1_e_processRelationIndex > System.High(ty_processRelations))) then Exit;

  Result := ty_processRelations[_1_e_processRelationIndex].e_currentOneToMany;

  if (gb_automaticMany) then Result := AUTOMATIC;
end;

function InternalInt64ArrayContains(const _1_te_values: Tq4Int64Array; const _2_e_value: int64): boolean;
var
  _e_i: int64;
begin
  Result := False;

  for _e_i := 0 to System.High(_1_te_values) do if (_1_te_values[_e_i] = _2_e_value) then Exit(True);
end;

procedure InternalAddInt64ToArray(var _1_te_values: Tq4Int64Array; const _2_e_value: int64);
var
  _e_len: int64;
begin
  _e_len := System.Length(_1_te_values);
  System.SetLength(_1_te_values, _e_len + 1);
  _1_te_values[_e_len] := _2_e_value;
end;

function InternalReadCurrentFieldValue(const _1_p_field: Pointer; out _2_v_value: variant): boolean; forward;

function InternalRelateManyUsingFields(const _1_p_oneField: Pointer; const _2_p_manyField: Pointer; const _3_v_value: variant): boolean; forward;

function InternalVariantToSqlLiteral(const _1_v_value: variant): string;
begin
  if (Variants.VarIsNull(_1_v_value) or Variants.VarIsEmpty(_1_v_value)) then Exit('NULL');

  case Variants.VarType(_1_v_value) and VarTypeMask of
    varSmallint, varInteger, varShortInt, varByte, varWord, varLongWord, varInt64, varQWord: Result := Variants.VarToStr(_1_v_value);
    varSingle, varDouble, varCurrency: Result := SysUtils.StringReplace(Variants.VarToStr(_1_v_value), ',', '.', [rfReplaceAll]);
    //varBoolean: if boolean(p1_v_value) then Result := '1'
    //  else
    //    Result := '0';
    varBoolean: if (Variants.VarAsType(_1_v_value, varBoolean)) then Result := '1'
      else
        Result := '0';
    else Result := InternalSqlQuote(Variants.VarToStr(_1_v_value));
  end;
end;

function InternalWhereFieldMatchesValue(const _1_t_alias: string; const _2_t_fieldName: string; const _3_v_value: variant): string;
begin
  if (Variants.VarIsNull(_3_v_value) or Variants.VarIsEmpty(_3_v_value)) then
    Result := q4DBschemaUse.sqlQualifiedIdentifier(_1_t_alias, _2_t_fieldName) + ' IS NULL'
  else
    Result :=
      q4DBschemaUse.sqlQualifiedIdentifier(_1_t_alias, _2_t_fieldName) + ' = ' + InternalVariantToSqlLiteral(_3_v_value);
end;

function InternalResolveTableMetaAndPK(const _1_e_tableId: int64; out _2_y_table: TTableMeta; out _3_y_pkField: TFieldMeta): boolean;
begin
  Result := False;

  if (not q4DBschemaUse.findTableMeta(_1_e_tableId, _2_y_table)) then Exit;
  if (SysUtils.Trim(_2_y_table.PrimaryKey) = '') then Exit;
  if (not q4DBschemaUse.findFieldMetaByName(_1_e_tableId, _2_y_table.PrimaryKey, _3_y_pkField)) then Exit;

  Result := True;
end;

function InternalIsRelationStatus(const _1_e_status: int64): boolean;
begin
  Result :=
    (_1_e_status = DO_NOT_MODIFY) or (_1_e_status = STRUCTURE_CONFIGURATION) or (_1_e_status = MANUAL) or (_1_e_status = AUTOMATIC);
end;

function InternalNormalizeSetStatus(const _1_e_status: int64): int64;
begin
  if (not InternalIsRelationStatus(_1_e_status)) then Exit(DO_NOT_MODIFY);
  Result := _1_e_status;
end;

function InternalStructureEffectiveOneStatus: int64;
begin
  Result := AUTOMATIC;
end;

function InternalStructureEffectiveManyStatus: int64;
begin
  Result := MANUAL;
end;

function InternalEffectiveStatus(const _1_e_status: int64; const _2_e_structureStatus: int64; const _3_b_forceAutomatic: boolean): int64;
begin
  if (_3_b_forceAutomatic) then Exit(AUTOMATIC);
  if (_1_e_status = STRUCTURE_CONFIGURATION) then Exit(_2_e_structureStatus);
  if (_1_e_status = DO_NOT_MODIFY) then Exit(_2_e_structureStatus);

  Result := _1_e_status;
end;

function InternalFindProcessRelationIndex(const _1_e_sourceTableId: int64; const _2_e_sourceFieldId: int64): int64;
var
  _e_i: int64;
begin
  Result := -1;

  for _e_i := 0 to System.High(ty_processRelations) do
    if ((ty_processRelations[_e_i].e_sourceTableId = _1_e_sourceTableId) and (ty_processRelations[_e_i].e_sourceFieldId = _2_e_sourceFieldId)) then
      Exit(_e_i);
end;

function InternalResolveManyFieldRelation(const _1_p_manyField: Pointer; out _2_e_manyTableId: int64;
  out _3_e_manyFieldNo: int64; out _4_p_resolvedManyField: Pointer; out _5_p_oneField: Pointer): boolean;
var
  _y_manyField: TFieldMeta;
begin
  Result := False;
  _2_e_manyTableId := 0;
  _3_e_manyFieldNo := 0;
  _4_p_resolvedManyField := nil;
  _5_p_oneField := nil;

  if (_1_p_manyField = nil) then Exit;
  if (not q4DBschemaUse.resolveFieldPointerGlobal(_1_p_manyField, _2_e_manyTableId, _y_manyField)) then Exit;
  if (not q4coreRelations.resolveDirectManyToOneFields(_1_p_manyField, _4_p_resolvedManyField, _5_p_oneField)) then Exit;

  _3_e_manyFieldNo := _y_manyField.FieldNo;
  Result := True;
end;

function InternalRelateManyUsingOneTable(const _1_p_oneTable: Pointer): boolean;
var
  _e_oneTableId: int64;
  _e_manyTableId: int64;
  _e_linkIndex: int64;
  _e_relationIndex: int64;
  _te_doneManyTableIds: Tq4Int64Array;
  _p_oneField: Pointer;
  _p_manyField: Pointer;
  _v_value: variant;
begin
  Result := False;
  System.SetLength(_te_doneManyTableIds, 0);

  if (not q4DBschemaUse.resolveTablePointerToSourceTableId(_1_p_oneTable, _e_oneTableId)) then Exit;

  for _e_linkIndex := 0 to System.High(JoinLinks) do begin
    if (JoinLinks[_e_linkIndex].TargetTableId <> _e_oneTableId) then Continue;

    _e_manyTableId := JoinLinks[_e_linkIndex].SourceTableId;

    if (InternalInt64ArrayContains(_te_doneManyTableIds, _e_manyTableId)) then Continue;

    _e_relationIndex := InternalFindProcessRelationIndex(JoinLinks[_e_linkIndex].SourceTableId, JoinLinks[_e_linkIndex].SourceFieldId);

    if (InternalEffectiveOneToManyStatus(_e_relationIndex) <> AUTOMATIC) then Continue;

    _p_manyField := nil;
    _p_oneField := nil;

    if (not q4DBschemaUse.resolveFieldPointerByIds(JoinLinks[_e_linkIndex].SourceTableId, JoinLinks[_e_linkIndex].SourceFieldId,
      _p_manyField)) then Continue;

    if (not q4DBschemaUse.resolveFieldPointerByIds(JoinLinks[_e_linkIndex].TargetTableId, JoinLinks[_e_linkIndex].TargetFieldId,
      _p_oneField)) then Continue;

    if (not InternalReadCurrentFieldValue(_p_oneField, _v_value)) then Continue;

    if (InternalRelateManyUsingFields(_p_oneField, _p_manyField, _v_value)) then begin
      InternalAddInt64ToArray(_te_doneManyTableIds, _e_manyTableId);
      Result := True;
    end;
  end;
end;

function InternalReadCurrentFieldValue(const _1_p_field: Pointer; out _2_v_value: variant): boolean;
var
  _e_ownerTableId: int64;
  _e_bindingIndex: int64;
  _y_field: TFieldMeta;
  _p_table: Pointer;
begin
  Result := False;
  _2_v_value := Null;

  if (_1_p_field = nil) then Exit;
  if (not q4DBschemaUse.resolveFieldPointerGlobalReadWriteFirst(_1_p_field, _e_ownerTableId, _y_field)) then Exit;
  if (not q4DBschemaUse.resolveTablePointerBySourceTableId(_e_ownerTableId, _p_table)) then Exit;
  if (not q4record.isRecordLoaded(_p_table)) then Exit;

  _e_bindingIndex := q4DBschemaUse.findLocalBindingIndex(_p_table, _1_p_field);
  if (_e_bindingIndex < 0) then Exit;

  _2_v_value := q4record.readBindingValue(Pq4recordRuntime(_p_table)^._Bindings[_e_bindingIndex]);
  Result := True;
end;

function InternalWriteCurrentFieldValue(const _1_p_field: Pointer; const _2_v_value: variant): boolean;
var
  _e_ownerTableId: int64;
  _e_bindingIndex: int64;
  _y_field: TFieldMeta;
  _p_table: Pointer;
begin
  Result := False;

  if (_1_p_field = nil) then Exit;
  if (not q4DBschemaUse.resolveFieldPointerGlobalReadWriteFirst(_1_p_field, _e_ownerTableId, _y_field)) then Exit;
  if (not q4DBschemaUse.resolveTablePointerBySourceTableId(_e_ownerTableId, _p_table)) then Exit;
  if (not q4record.isRecordLoaded(_p_table)) then Exit;

  _e_bindingIndex := q4DBschemaUse.findLocalBindingIndex(_p_table, _1_p_field);
  if (_e_bindingIndex < 0) then Exit;

  q4record.writeBindingValue(Pq4recordRuntime(_p_table)^._Bindings[_e_bindingIndex], _2_v_value);
  Pq4recordRuntime(_p_table)^._Modified := True;
  Result := True;
end;

function InternalFindFirstRowIdByFieldValue(const _1_e_tableId: int64; const _2_t_fieldName: string; const _3_v_value: variant;
  out _4_e_rowId: int64): boolean;
var
  _o_query: TSQLQuery;
  _t_sql: string;
begin
  Result := False;
  _4_e_rowId := 0;

  if ((_1_e_tableId < 0) or (_1_e_tableId > System.High(Tables))) then Exit;
  if (SysUtils.Trim(_2_t_fieldName) = '') then Exit;

  _o_query := TSQLQuery.Create(nil);
  try
    _o_query.DataBase := q4DBmanager.InternalConnection;
    _o_query.Transaction := q4DBmanager.InternalTransaction;

    if (Variants.VarIsNull(_3_v_value) or Variants.VarIsEmpty(_3_v_value)) then _t_sql :=
        'SELECT t.rowid FROM ' + q4DBschemaUse.sqlIdentifier(Tables[_1_e_tableId].Name) + ' t ' + 'WHERE ' +
        q4DBschemaUse.sqlQualifiedIdentifier('t', _2_t_fieldName) + ' IS NULL ' + 'ORDER BY t.rowid LIMIT 1'
    else
      _t_sql :=
        'SELECT t.rowid FROM ' + q4DBschemaUse.sqlIdentifier(Tables[_1_e_tableId].Name) + ' t ' + 'WHERE ' +
        q4DBschemaUse.sqlQualifiedIdentifier('t', _2_t_fieldName) + ' = :q4value ' + 'ORDER BY t.rowid LIMIT 1';

    _o_query.SQL.Text := _t_sql;
    if (not (Variants.VarIsNull(_3_v_value) or Variants.VarIsEmpty(_3_v_value))) then _o_query.ParamByName('q4value').Value := _3_v_value;

    _o_query.Open;
    if (_o_query.EOF) then Exit;

    _4_e_rowId := _o_query.Fields[0].AsLargeInt;
    Result := _4_e_rowId > 0;
  finally
    _o_query.Free;
  end;
end;

function InternalRelateOneUsingValue(const _1_p_manyField: Pointer; const _2_v_value: variant): boolean;
var
  _e_manyTableId: int64;
  _e_manyFieldNo: int64;
  _e_oneTableId: int64;
  _e_rowId: int64;
  _y_oneField: TFieldMeta;
  _p_manyField: Pointer;
  _p_oneField: Pointer;
  _p_oneTable: Pointer;
begin
  Result := False;

  if (not InternalResolveManyFieldRelation(_1_p_manyField, _e_manyTableId, _e_manyFieldNo, _p_manyField, _p_oneField)) then Exit;
  if (not q4DBschemaUse.resolveFieldPointerGlobal(_p_oneField, _e_oneTableId, _y_oneField)) then Exit;
  if (not q4DBschemaUse.resolveTablePointerBySourceTableId(_e_oneTableId, _p_oneTable)) then Exit;
  if (not InternalFindFirstRowIdByFieldValue(_e_oneTableId, _y_oneField.Name, _2_v_value, _e_rowId)) then Exit;

  q4record.gotoRecord(_p_oneTable, _e_rowId);
  Result := True;
end;

function InternalRelateOneUsingField(const _1_p_manyField: Pointer): boolean;
var
  _v_value: variant;
begin
  Result := False;

  if (not InternalReadCurrentFieldValue(_1_p_manyField, _v_value)) then Exit;

  Result := InternalRelateOneUsingValue(_1_p_manyField, _v_value);
end;

function InternalRelateOneUsingTable(const _1_p_manyTable: Pointer): boolean;
var
  _e_manyTableId: int64;
  _y_range: TTableJoinRange;
  _e_linkIndex: int64;
  _e_last: int64;
  _e_relationIndex: int64;
  _p_manyField: Pointer;
begin
  Result := False;

  if (not q4DBschemaUse.resolveTablePointerToSourceTableId(_1_p_manyTable, _e_manyTableId)) then Exit;
  if (not q4DBschemaUse.findTableJoinRange(_e_manyTableId, _y_range)) then Exit;

  _e_last := _y_range.LinkIndex + _y_range.LinkCount - 1;

  for _e_linkIndex := _y_range.LinkIndex to _e_last do begin
    if ((_e_linkIndex < 0) or (_e_linkIndex > System.High(JoinLinks))) then Exit(False);

    _e_relationIndex := InternalFindProcessRelationIndex(_e_manyTableId, JoinLinks[_e_linkIndex].SourceFieldId);

    if (InternalEffectiveManyToOneStatus(_e_relationIndex) <> AUTOMATIC) then Continue;

    _p_manyField := nil;

    if (not q4DBschemaUse.resolveFieldPointerByIds(_e_manyTableId, JoinLinks[_e_linkIndex].SourceFieldId, _p_manyField)) then
      Continue;

    if (InternalRelateOneUsingField(_p_manyField)) then Result := True;
  end;
end;

function InternalBuildSingleFieldSelectionSql(const _1_p_targetField: Pointer; const _2_v_value: variant;
  out _3_p_targetTable: Pointer; out _4_t_sql: string): boolean;
var
  _e_targetTableId: int64;
  _y_targetTable: TTableMeta;
  _y_pkField: TFieldMeta;
  _y_targetField: TFieldMeta;
begin
  Result := False;
  _3_p_targetTable := nil;
  _4_t_sql := '';

  if (not q4DBschemaUse.resolveFieldPointerGlobal(_1_p_targetField, _e_targetTableId, _y_targetField)) then Exit;
  if (not q4DBschemaUse.resolveTablePointerBySourceTableId(_e_targetTableId, _3_p_targetTable)) then Exit;
  if (not InternalResolveTableMetaAndPK(_e_targetTableId, _y_targetTable, _y_pkField)) then Exit;

  _4_t_sql :=
    'SELECT ' + q4DBschemaUse.sqlQualifiedIdentifier('t', _y_pkField.Name) + ' ' + 'FROM ' +
    q4DBschemaUse.sqlIdentifier(_y_targetTable.Name) + ' t ' + 'WHERE ' + InternalWhereFieldMatchesValue('t', _y_targetField.Name, _2_v_value) +
    ' ' + 'ORDER BY ' + q4DBschemaUse.sqlQualifiedIdentifier('t', _y_pkField.Name);

  Result := True;
end;

function InternalRelateManyUsingFields(const _1_p_oneField: Pointer; const _2_p_manyField: Pointer; const _3_v_value: variant): boolean;
var
  _p_manyTable: Pointer;
  _t_sql: string;
begin
  Result := False;

  if (not InternalBuildSingleFieldSelectionSql(_2_p_manyField, _3_v_value, _p_manyTable, _t_sql)) then Exit;

  q4selection.createSelectionFromPkSelect(_p_manyTable, _t_sql);
  if (q4selection.recordsInSelection(_p_manyTable) > 0) then q4selection.firstRecord(_p_manyTable);

  Result := True;
end;

function InternalBuildRelateOneSelectionSql(const _1_p_manyTable: Pointer; const _2_p_oneTable: Pointer; out _3_t_sql: string): boolean;
var
  _e_manyTableId: int64;
  _e_oneTableId: int64;
  _y_manyTable: TTableMeta;
  _y_oneTable: TTableMeta;
  _y_manyPKField: TFieldMeta;
  _y_onePKField: TFieldMeta;
  _y_manyField: TFieldMeta;
  _y_oneField: TFieldMeta;
  _p_manyField: Pointer;
  _p_oneField: Pointer;
  _p_manyTable: Pointer;
  _t_manySelectionSql: string;
begin
  Result := False;
  _3_t_sql := '';
  _p_manyTable := _1_p_manyTable;

  if (not q4DBschemaUse.resolveTablePointerToSourceTableId(_1_p_manyTable, _e_manyTableId)) then Exit;
  if (not q4DBschemaUse.resolveTablePointerToSourceTableId(_2_p_oneTable, _e_oneTableId)) then Exit;
  if (not InternalResolveTableMetaAndPK(_e_manyTableId, _y_manyTable, _y_manyPKField)) then Exit;
  if (not InternalResolveTableMetaAndPK(_e_oneTableId, _y_oneTable, _y_onePKField)) then Exit;

  if (not q4coreRelations.resolveDirectManyTableToOneTableFields(_1_p_manyTable, _2_p_oneTable, _p_manyField, _p_oneField)) then Exit;
  if (not q4DBschemaUse.resolveFieldPointerGlobal(_p_manyField, _e_manyTableId, _y_manyField)) then Exit;
  if (not q4DBschemaUse.resolveFieldPointerGlobal(_p_oneField, _e_oneTableId, _y_oneField)) then Exit;
  if (not q4selection.currentSelectionPkSelect(_p_manyTable, _t_manySelectionSql)) then Exit;

  _3_t_sql :=
    'SELECT ' + q4DBschemaUse.sqlQualifiedIdentifier('o', _y_onePKField.Name) + ' ' + 'FROM ' +
    q4DBschemaUse.sqlIdentifier(_y_manyTable.Name) + ' m ' + 'JOIN ' + q4DBschemaUse.sqlIdentifier(_y_oneTable.Name) +
    ' o ' + 'ON ' + q4DBschemaUse.sqlQualifiedIdentifier('o', _y_oneField.Name) + ' = ' +
    q4DBschemaUse.sqlQualifiedIdentifier('m', _y_manyField.Name) + ' ' + 'WHERE ' + q4DBschemaUse.sqlQualifiedIdentifier('m', _y_manyPKField.Name) +
    ' IN (' + _t_manySelectionSql + ') ' + 'ORDER BY ' + q4DBschemaUse.sqlQualifiedIdentifier('o', _y_onePKField.Name);

  Result := True;
end;

function InternalBuildRelateManySelectionSql(const _1_p_manyField: Pointer; out _2_p_manyTable: Pointer; out _3_t_sql: string): boolean;
var
  _e_manyTableId: int64;
  _e_oneTableId: int64;
  _y_manyTable: TTableMeta;
  _y_oneTable: TTableMeta;
  _y_manyPKField: TFieldMeta;
  _y_onePKField: TFieldMeta;
  _y_manyField: TFieldMeta;
  _y_oneField: TFieldMeta;
  _p_manyField: Pointer;
  _p_oneField: Pointer;
  _p_oneTable: Pointer;
  _t_oneSelectionSql: string;
begin
  Result := False;
  _2_p_manyTable := nil;
  _3_t_sql := '';

  if (not q4coreRelations.resolveDirectManyToOneFields(_1_p_manyField, _p_manyField, _p_oneField)) then Exit;
  if (not q4DBschemaUse.resolveFieldPointerGlobal(_p_manyField, _e_manyTableId, _y_manyField)) then Exit;
  if (not q4DBschemaUse.resolveFieldPointerGlobal(_p_oneField, _e_oneTableId, _y_oneField)) then Exit;
  if (not q4DBschemaUse.resolveTablePointerBySourceTableId(_e_manyTableId, _2_p_manyTable)) then Exit;
  if (not q4DBschemaUse.resolveTablePointerBySourceTableId(_e_oneTableId, _p_oneTable)) then Exit;
  if (not InternalResolveTableMetaAndPK(_e_manyTableId, _y_manyTable, _y_manyPKField)) then Exit;
  if (not InternalResolveTableMetaAndPK(_e_oneTableId, _y_oneTable, _y_onePKField)) then Exit;
  if (not q4selection.currentSelectionPkSelect(_p_oneTable, _t_oneSelectionSql)) then Exit;

  _3_t_sql :=
    'SELECT ' + q4DBschemaUse.sqlQualifiedIdentifier('m', _y_manyPKField.Name) + ' ' + 'FROM ' +
    q4DBschemaUse.sqlIdentifier(_y_oneTable.Name) + ' o ' + 'JOIN ' + q4DBschemaUse.sqlIdentifier(_y_manyTable.Name) +
    ' m ' + 'ON ' + q4DBschemaUse.sqlQualifiedIdentifier('m', _y_manyField.Name) + ' = ' +
    q4DBschemaUse.sqlQualifiedIdentifier('o', _y_oneField.Name) + ' ' + 'WHERE ' + q4DBschemaUse.sqlQualifiedIdentifier('o', _y_onePKField.Name) +
    ' IN (' + _t_oneSelectionSql + ') ' + 'ORDER BY ' + q4DBschemaUse.sqlQualifiedIdentifier('m', _y_manyPKField.Name);

  Result := True;
end;

procedure InternalApplyRelationStatus(var _1_y_relation: Tq4ProcessRelation; const _2_e_one: int64; const _3_e_many: int64);
var
  _e_one: int64;
  _e_many: int64;
begin
  _e_one := InternalNormalizeSetStatus(_2_e_one);
  _e_many := InternalNormalizeSetStatus(_3_e_many);

  if (_e_one <> DO_NOT_MODIFY) then if (_e_one = STRUCTURE_CONFIGURATION) then _1_y_relation.e_currentManyToOne := _1_y_relation.e_structureManyToOne
    else
      _1_y_relation.e_currentManyToOne := _e_one;

  if (_e_many <> DO_NOT_MODIFY) then if (_e_many = STRUCTURE_CONFIGURATION) then _1_y_relation.e_currentOneToMany := _1_y_relation.e_structureOneToMany
    else
      _1_y_relation.e_currentOneToMany := _e_many;
end;

procedure InternalSetRelationOverride(const _1_e_manyTableId: int64; const _2_e_manyFieldNo: int64; const _3_e_one: int64; const _4_e_many: int64);
var
  _e_idx: int64;
begin
  _e_idx := InternalFindProcessRelationIndex(_1_e_manyTableId, _2_e_manyFieldNo);
  if (_e_idx < 0) then Exit;

  InternalApplyRelationStatus(ty_processRelations[_e_idx], _3_e_one, _4_e_many);
end;

function InternalApplyTableOverrides(const _1_e_manyTableId: int64; const _2_e_one: int64; const _3_e_many: int64): boolean;
var
  _y_range: TTableJoinRange;
  _e_linkIndex: int64;
  _e_last: int64;
begin
  Result := False;

  if (not q4DBschemaUse.findTableJoinRange(_1_e_manyTableId, _y_range)) then Exit;

  _e_last := _y_range.LinkIndex + _y_range.LinkCount - 1;

  for _e_linkIndex := _y_range.LinkIndex to _e_last do begin
    if ((_e_linkIndex < 0) or (_e_linkIndex > System.High(JoinLinks))) then Exit(False);
    InternalSetRelationOverride(_1_e_manyTableId, JoinLinks[_e_linkIndex].SourceFieldId, _2_e_one, _3_e_many);
    Result := True;
  end;
end;

function InternalTrySetFieldOverride(const _1_p_manyField: Pointer; const _2_e_one: int64; const _3_e_many: int64): boolean;
var
  _e_manyTableId: int64;
  _e_manyFieldNo: int64;
  _p_manyField: Pointer;
  _p_oneField: Pointer;
begin
  Result := False;

  if (not InternalResolveManyFieldRelation(_1_p_manyField, _e_manyTableId, _e_manyFieldNo, _p_manyField, _p_oneField)) then Exit;

  InternalSetRelationOverride(_e_manyTableId, _e_manyFieldNo, _2_e_one, _3_e_many);
  Result := True;
end;

function InternalTrySetTableOverride(const _1_p_manyTable: Pointer; const _2_e_one: int64; const _3_e_many: int64): boolean;
var
  _e_manyTableId: int64;
begin
  Result := False;

  if (not q4DBschemaUse.resolveTablePointerToSourceTableId(_1_p_manyTable, _e_manyTableId)) then Exit;

  Result := InternalApplyTableOverrides(_e_manyTableId, _2_e_one, _3_e_many);
end;

procedure createRelatedOne(const _1_p_manyField: Pointer);
var
  _v_value: variant;
  _e_manyTableId: int64;
  _e_manyFieldNo: int64;
  _e_oneTableId: int64;
  _y_oneField: TFieldMeta;
  _p_manyField: Pointer;
  _p_oneField: Pointer;
  _p_oneTable: Pointer;
begin
  //https://developer.4d.com/docs/21/commands/create-related-one
  InternalClearError;
  InternalInitializeProcessState;

  if (not InternalReadCurrentFieldValue(_1_p_manyField, _v_value)) then Exit;
  if (InternalRelateOneUsingValue(_1_p_manyField, _v_value)) then Exit;

  if (not InternalResolveManyFieldRelation(_1_p_manyField, _e_manyTableId, _e_manyFieldNo, _p_manyField, _p_oneField)) then Exit;
  if (not q4DBschemaUse.resolveFieldPointerGlobal(_p_oneField, _e_oneTableId, _y_oneField)) then Exit;
  if (not q4DBschemaUse.resolveTablePointerBySourceTableId(_e_oneTableId, _p_oneTable)) then Exit;

  q4record.createRecord(_p_oneTable);
  if (not InternalWriteCurrentFieldValue(_p_oneField, _v_value)) then Exit;

  InternalWriteCurrentFieldValue(_p_oneField, _v_value);
end;

procedure getAutomaticRelations(out _1_b_one: boolean; out _2_b_many: boolean);
begin
  //https://developer.4d.com/docs/21/commands/get-automatic-relations
  InternalInitializeProcessState;

  _1_b_one := gb_automaticOne;
  _2_b_many := gb_automaticMany;
end;

procedure getFieldRelation(const _1_p_manyField: Pointer; out _2_e_one: int64; out _3_e_many: int64; const _4_t_operator: string = '');
var
  _e_manyTableId: int64;
  _e_manyFieldNo: int64;
  _e_idx: int64;
  _p_manyField: Pointer;
  _p_oneField: Pointer;
  _b_forceCurrent: boolean;
begin
  //https://developer.4d.com/docs/21/commands/get-field-relation

  q4coreLanguage.OK := 0;
  InternalClearError;
  InternalInitializeProcessState;

  _2_e_one := NO_RELATION;
  _3_e_many := NO_RELATION;

  if (not InternalResolveManyFieldRelation(_1_p_manyField, _e_manyTableId, _e_manyFieldNo, _p_manyField, _p_oneField)) then begin
    InternalSetNoRelation;
    Exit;
  end;

  q4coreLanguage.OK := 1;

  _e_idx := InternalFindProcessRelationIndex(_e_manyTableId, _e_manyFieldNo);
  if (_e_idx < 0) then begin
    InternalSetNoRelation;
    Exit;
  end;

  _b_forceCurrent := _4_t_operator = '*';

  if (_b_forceCurrent) then begin
    _2_e_one := ty_processRelations[_e_idx].e_currentManyToOne;
    _3_e_many := ty_processRelations[_e_idx].e_currentOneToMany;

    if (gb_automaticOne) then _2_e_one := AUTOMATIC;

    if (gb_automaticMany) then _3_e_many := AUTOMATIC;
  end else begin
    if (ty_processRelations[_e_idx].e_currentManyToOne = ty_processRelations[_e_idx].e_structureManyToOne) then _2_e_one := STRUCTURE_CONFIGURATION
    else
      _2_e_one := ty_processRelations[_e_idx].e_currentManyToOne;

    if (ty_processRelations[_e_idx].e_currentOneToMany = ty_processRelations[_e_idx].e_structureOneToMany) then _3_e_many := STRUCTURE_CONFIGURATION
    else
      _3_e_many := ty_processRelations[_e_idx].e_currentOneToMany;
  end;

end;

procedure oldRelatedMany(const _1_p_oneField: Pointer);
var
  _v_oldValue: variant;
  _p_oneField: Pointer;
  _p_manyField: Pointer;
begin
  //https://developer.4d.com/docs/21/commands/old-related-many
  InternalClearError;
  InternalInitializeProcessState;

  if (not q4coreRelations.resolveDirectOneFieldToManyFields(_1_p_oneField, _p_oneField, _p_manyField)) then Exit;
  _v_oldValue := q4dataEntry.oldVariant(_p_oneField);
  InternalRelateManyUsingFields(_p_oneField, _p_manyField, _v_oldValue);
end;

procedure oldRelatedOne(const _1_p_manyField: Pointer);
var
  _v_oldValue: variant;
begin
  //https://developer.4d.com/docs/21/commands/old-related-one

  q4coreLanguage.OK := 0;
  InternalClearError;
  InternalInitializeProcessState;

  _v_oldValue := q4dataEntry.oldVariant(_1_p_manyField);
  if (InternalRelateOneUsingValue(_1_p_manyField, _v_oldValue)) then q4coreLanguage.OK := 1;
end;


procedure relateMany(const _1_p_oneFieldOrTable: Pointer);
var
  _v_value: variant;
  _p_oneField: Pointer;
  _p_manyField: Pointer;
begin
  //https://developer.4d.com/docs/21/commands/relate-many

{
RELATE MANY(champ One)
→ cherche le lien direct reçu par ce champ One
→ une seule sélection Many est recalculée

RELATE MANY(table One)
→ cherche tous les liens directs reçus par cette table One
→ pour chaque table Many liée, recalcule sa sélection
→ si plusieurs liens viennent de la même table Many vers cette table One,
  on prend le premier selon l’ordre de définition
}

  InternalClearError;
  InternalInitializeProcessState;

  if (q4coreRelations.resolveDirectOneFieldToManyFields(_1_p_oneFieldOrTable, _p_oneField, _p_manyField)) then begin
    if (not InternalReadCurrentFieldValue(_p_oneField, _v_value)) then Exit;
    InternalRelateManyUsingFields(_p_oneField, _p_manyField, _v_value);
    Exit;
  end;

  InternalRelateManyUsingOneTable(_1_p_oneFieldOrTable);
end;

procedure relateManySelection(const _1_p_manyField: Pointer);
var
  _p_manyTable: Pointer;
  _t_sql: string;
begin
  //https://developer.4d.com/docs/21/commands/relate-many-selection
  InternalClearError;
  InternalInitializeProcessState;

  if (not InternalBuildRelateManySelectionSql(_1_p_manyField, _p_manyTable, _t_sql)) then Exit;
  q4selection.createSelectionFromPkSelect(_p_manyTable, _t_sql);
  if (q4selection.recordsInSelection(_p_manyTable) > 0) then q4selection.firstRecord(_p_manyTable);
end;

procedure relateOne(const _1_p_manyField: Pointer);
begin
  //https://developer.4d.com/docs/21/commands/relate-one

  q4coreLanguage.OK := 0;
  InternalClearError;
  InternalInitializeProcessState;

  if (InternalRelateOneUsingField(_1_p_manyField)) then begin
    q4coreLanguage.OK := 1;
    Exit;
  end;

  if (InternalRelateOneUsingTable(_1_p_manyField)) then q4coreLanguage.OK := 1;
end;

procedure relateOneSelection(const _1_p_manyTable: Pointer; const _2_p_oneTable: Pointer);
var
  _p_oneTable: Pointer;
  _t_sql: string;
begin
  //https://developer.4d.com/docs/21/commands/relate-one-selection
  InternalClearError;
  InternalInitializeProcessState;

  _p_oneTable := _2_p_oneTable;
  if (not InternalBuildRelateOneSelectionSql(_1_p_manyTable, _2_p_oneTable, _t_sql)) then Exit;

  q4selection.createSelectionFromPkSelect(_p_oneTable, _t_sql);
  if (q4selection.recordsInSelection(_p_oneTable) > 0) then q4selection.firstRecord(_p_oneTable);
end;

procedure saveRelatedOne(const _1_p_manyField: Pointer);
var
  _v_value: variant;
  _e_manyTableId: int64;
  _e_manyFieldNo: int64;
  _e_oneTableId: int64;
  _y_oneField: TFieldMeta;
  _p_manyField: Pointer;
  _p_oneField: Pointer;
  _p_oneTable: Pointer;
begin
  //https://developer.4d.com/docs/21/commands/save-related-one
  InternalClearError;
  InternalInitializeProcessState;

  if (not InternalResolveManyFieldRelation(_1_p_manyField, _e_manyTableId, _e_manyFieldNo, _p_manyField, _p_oneField)) then Exit;
  if (not q4DBschemaUse.resolveFieldPointerGlobal(_p_oneField, _e_oneTableId, _y_oneField)) then Exit;
  if (not q4DBschemaUse.resolveTablePointerBySourceTableId(_e_oneTableId, _p_oneTable)) then Exit;

  if (not q4record.isRecordLoaded(_p_oneTable)) then begin
    if (not InternalReadCurrentFieldValue(_1_p_manyField, _v_value)) then Exit;
    if (not InternalRelateOneUsingValue(_1_p_manyField, _v_value)) then Exit;
  end;

  if (q4RecordLocking.locked(_p_oneTable)) then Exit;
  q4record.saveRecord(_p_oneTable);
end;

procedure setAutomaticRelations(_1_b_one: boolean; _2_b_many: boolean = False);
begin
  //https://developer.4d.com/docs/21/commands/set-automatic-relations
  InternalInitializeProcessState;

  gb_automaticOne := _1_b_one;
  gb_automaticMany := _2_b_many;
end;

procedure setFieldRelation(const _1_p_manyFieldOrTable: Pointer; _2_e_one: int64; _3_e_many: int64);
begin
  //https://developer.4d.com/docs/21/commands/set-field-relation

  q4coreLanguage.OK := 0;
  InternalClearError;
  InternalInitializeProcessState;

  if (gb_automaticOne or gb_automaticMany) then begin
    q4coreLanguage.OK := 1;
    Exit;
  end;

  if (InternalTrySetFieldOverride(_1_p_manyFieldOrTable, _2_e_one, _3_e_many)) then begin
    q4coreLanguage.OK := 1;
    Exit;
  end;

  if (InternalTrySetTableOverride(_1_p_manyFieldOrTable, _2_e_one, _3_e_many)) then begin
    q4coreLanguage.OK := 1;
    Exit;
  end;

  InternalSetNoRelation;
end;

end.
