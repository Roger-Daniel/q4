Unit q4coreRelations;

{$mode objfpc}{$H+}

{
q4coreRelations
version du 2026/04/26-07

Unité core technique pour la résolution structurelle des relations q4.

Périmètre
---------
- Résoudre les liens directs.
- Résoudre, lorsque nécessaire, le premier chemin Many -> One multi-niveaux.
- Ne jamais suivre automatiquement les chemins One -> Many dans resolveManyToOnePath,
  afin de préserver la règle 1 record source = 1 résultat logique.
- Respecter l'ordre de définition des liens : le premier lien / chemin trouvé
  est prioritaire.
- Protéger la résolution de chemin contre les cycles.
- Ne pas modifier q4coreLanguage.OK / q4coreLanguage.Error.
- Ne pas déclencher d'erreur 4D cachée en cas d'échec de résolution.
- Ne pas gérer les sélections courantes.
- Ne pas lire les valeurs courantes ou anciennes des records.

Cette unité n'est pas une façade de commandes 4D.
}

Interface

Uses
  SysUtils,
  metier_q4DBschemaBase,
  q4DBschemaUse;

Const
  Q4_MAX_RELATION_PATH_DEPTH = int64( 16);

Type
  Tq4RelationPathLink = Record
    e_sourceTableId: int64;
    e_targetTableId: int64;
    e_sourceFieldNo: int64;
    e_targetFieldNo: int64;
  End;

  Tq4RelationPath = Array Of Tq4RelationPathLink;

  {
Contrats principaux
-------------------
resolveManyToOnePath :
- retourne True avec un chemin vide si source = target ;
- retourne True avec N liens si target est atteignable par une chaîne Many -> One ;
- retourne False avec un chemin vide si aucun chemin sûr n'existe.

resolveLinkedFieldPathForSourceTable* :
- retourne le champ demandé dans p4_y_requestedField ;
- retourne la table propriétaire du champ dans p6_y_targetTable dès que Result = True ;
- retourne p5_ty_path vide si le champ est local ;
- retourne p5_ty_path non vide si le champ est lié via Many -> One.
}

Function resolveManyToOnePath( Const _1_e_sourceTableId: int64; Const _2_e_targetTableId: int64; out _3_ty_path: Tq4RelationPath): boolean;

Function resolveLinkedFieldPathForSourceTable( Var _1_p_recordTable; Const _2_p_requestedField: Pointer; out _3_b_isLocalField: boolean;
  out _4_y_requestedField: TFieldMeta; out _5_ty_path: Tq4RelationPath; out _6_y_targetTable: TTableMeta): boolean;

Function resolveLinkedFieldPathForSourceTableId( Const _1_e_sourceTableId: int64; Const _2_p_requestedField: Pointer; out _3_b_isLocalField: boolean;
  out _4_y_requestedField: TFieldMeta; out _5_ty_path: Tq4RelationPath; out _6_y_targetTable: TTableMeta): boolean;

Function resolveLinkedFieldForSourceTable( Var _1_p_recordTable; Const _2_p_requestedField: Pointer; out _3_b_isLocalField: boolean; out _4_y_requestedField: TFieldMeta;
  out _5_y_sourceLinkField: TFieldMeta; out _6_y_targetLinkField: TFieldMeta; out _7_y_targetTable: TTableMeta): boolean;

Function resolveLinkedFieldForSourceTableId( Const _1_e_sourceTableId: int64; Const _2_p_requestedField: Pointer; out _3_b_isLocalField: boolean;
  out _4_y_requestedField: TFieldMeta; out _5_y_sourceLinkField: TFieldMeta; out _6_y_targetLinkField: TFieldMeta; out _7_y_targetTable: TTableMeta): boolean;

Function resolveDirectManyToOneFields( Const _1_p_manyField: Pointer; out _2_p_manyField: Pointer; out _3_p_oneField: Pointer): boolean;

Function resolveDirectManyTableToOneTableFields( Const _1_p_manyTable: Pointer; Const _2_p_oneTable: Pointer; out _3_p_manyField: Pointer; out _4_p_oneField: Pointer): boolean;

Function resolveDirectManyTableToOneTableFieldsByIds( Const _1_e_manyTableId: int64; Const _2_e_oneTableId: int64; out _3_p_manyField: Pointer; out _4_p_oneField: Pointer): boolean;

Function resolveDirectOneToManyFields( Const _1_p_oneTable: Pointer; out _2_p_oneField: Pointer; out _3_p_manyField: Pointer): boolean;

Function resolveDirectOneFieldToManyFields( Const _1_p_oneField: Pointer; out _2_p_oneField: Pointer; out _3_p_manyField: Pointer): boolean;

Implementation

Type
  TInt64DynArray = Array Of int64;

Procedure InternalClearFieldMeta( out _1_y_field: TFieldMeta);
  Begin
    System.FillChar( _1_y_field, SizeOf( _1_y_field), 0);
  End;

Procedure InternalClearTableMeta( out _1_y_table: TTableMeta);
  Begin
    System.FillChar( _1_y_table, SizeOf( _1_y_table), 0);
  End;

Procedure InternalClearRelationPath( out _1_ty_path: Tq4RelationPath);
  Begin
    System.SetLength( _1_ty_path, 0);
  End;

Function InternalFindFieldMetaByTableAndFieldNo( Const _1_e_tableId: int64; Const _2_e_fieldNo: int64; out _3_y_field: TFieldMeta): boolean;
  Var
    _e_i: int64;
  Begin
    Result := False;
    InternalClearFieldMeta( _3_y_field);

    For _e_i := 0 To System.High( Fields) Do If ( ( Fields[_e_i].TableRef = _1_e_tableId) and ( Fields[_e_i].FieldNo = _2_e_fieldNo)) Then Begin
        _3_y_field := Fields[_e_i];
        Exit( True);
      End;
  End;

Function InternalResolveRelationFields( Const _1_e_sourceTableId: int64; Const _2_e_targetTableId: int64; Const _3_e_sourceFieldNo: int64;
  Const _4_e_targetFieldNo: int64; out _5_y_sourceLinkField: TFieldMeta; out _6_y_targetLinkField: TFieldMeta; out _7_y_targetTable: TTableMeta): boolean;
  Begin
    Result := False;
    InternalClearFieldMeta( _5_y_sourceLinkField);
    InternalClearFieldMeta( _6_y_targetLinkField);
    InternalClearTableMeta( _7_y_targetTable);

    If ( not InternalFindFieldMetaByTableAndFieldNo( _1_e_sourceTableId, _3_e_sourceFieldNo, _5_y_sourceLinkField)) Then Exit;
    If ( not InternalFindFieldMetaByTableAndFieldNo( _2_e_targetTableId, _4_e_targetFieldNo, _6_y_targetLinkField)) Then Exit;
    If ( not q4DBschemaUse.findTableMeta( _2_e_targetTableId, _7_y_targetTable)) Then Exit;

    Result := True;
  End;

Function InternalTableVisited( Const _1_te_visited: TInt64DynArray; Const _2_e_tableId: int64): boolean;
  Var
    _e_i: int64;
  Begin
    Result := False;

    For _e_i := 0 To System.High( _1_te_visited) Do If ( _1_te_visited[_e_i] = _2_e_tableId) Then Exit( True);
  End;

Procedure InternalAppendVisited( Var _1_te_visited: TInt64DynArray; Const _2_e_tableId: int64);
  Begin
    System.SetLength( _1_te_visited, System.Length( _1_te_visited) + 1);
    _1_te_visited[System.High( _1_te_visited)] := _2_e_tableId;
  End;

Procedure InternalPopVisited( Var _1_te_visited: TInt64DynArray);
  Begin
    If ( System.Length( _1_te_visited) > 0) Then System.SetLength( _1_te_visited, System.Length( _1_te_visited) - 1);
  End;

Procedure InternalAppendPathLink( Var _1_ty_path: Tq4RelationPath; Const _2_y_link: TJoinLinkMeta; Const _3_e_sourceTableId: int64);
  Var
    _e_index: int64;
  Begin
    System.SetLength( _1_ty_path, System.Length( _1_ty_path) + 1);
    _e_index := System.High( _1_ty_path);
    _1_ty_path[_e_index].e_sourceTableId := _3_e_sourceTableId;
    _1_ty_path[_e_index].e_targetTableId := _2_y_link.TargetTableId;
    _1_ty_path[_e_index].e_sourceFieldNo := _2_y_link.SourceFieldId;
    _1_ty_path[_e_index].e_targetFieldNo := _2_y_link.TargetFieldId;
  End;

Procedure InternalPopPathLink( Var _1_ty_path: Tq4RelationPath);
  Begin
    If ( System.Length( _1_ty_path) > 0) Then System.SetLength( _1_ty_path, System.Length( _1_ty_path) - 1);
  End;

Function InternalResolveManyToOnePathRecursive( Const _1_e_currentTableId: int64; Const _2_e_targetTableId: int64; Const _3_e_depth: int64;
  Var _4_te_visited: TInt64DynArray; Var _5_ty_path: Tq4RelationPath): boolean;
  Var
    _y_range: TTableJoinRange;
    _e_i:     int64;
    _e_last:  int64;
    _y_link:  TJoinLinkMeta;
  Begin
    Result := False;

    If ( _1_e_currentTableId = _2_e_targetTableId) Then Exit( True);
    If ( _3_e_depth >= Q4_MAX_RELATION_PATH_DEPTH) Then Exit( False);
    If ( not q4DBschemaUse.findTableJoinRange( _1_e_currentTableId, _y_range)) Then Exit( False);

    _e_last := _y_range.LinkIndex + _y_range.LinkCount - 1;

    For _e_i := _y_range.LinkIndex To _e_last Do Begin
      If ( ( _e_i < 0) or ( _e_i > System.High( JoinLinks))) Then Exit( False);

      _y_link := JoinLinks[_e_i];
      If ( InternalTableVisited( _4_te_visited, _y_link.TargetTableId)) Then Continue;

      InternalAppendPathLink( _5_ty_path, _y_link, _1_e_currentTableId);
      InternalAppendVisited( _4_te_visited, _y_link.TargetTableId);

      If ( InternalResolveManyToOnePathRecursive( _y_link.TargetTableId, _2_e_targetTableId, _3_e_depth + 1, _4_te_visited, _5_ty_path)) Then Exit( True);

      InternalPopVisited( _4_te_visited);
      InternalPopPathLink( _5_ty_path);
    End;
  End;

Function resolveManyToOnePath( Const _1_e_sourceTableId: int64; Const _2_e_targetTableId: int64; out _3_ty_path: Tq4RelationPath): boolean;
  Var
    _te_visited: TInt64DynArray;
  Begin
    Result := False;
    InternalClearRelationPath( _3_ty_path);
    System.SetLength( _te_visited, 0);

    If ( ( _1_e_sourceTableId <= 0) or ( _2_e_targetTableId <= 0)) Then Exit;

    If ( _1_e_sourceTableId = _2_e_targetTableId) Then Exit( True);

    System.SetLength( _te_visited, 1);
    _te_visited[0] := _1_e_sourceTableId;

    Result := InternalResolveManyToOnePathRecursive( _1_e_sourceTableId, _2_e_targetTableId, 0, _te_visited, _3_ty_path);

    If ( not Result) Then InternalClearRelationPath( _3_ty_path);
  End;

Function resolveLinkedFieldPathForSourceTable( Var _1_p_recordTable; Const _2_p_requestedField: Pointer; out _3_b_isLocalField: boolean;
  out _4_y_requestedField: TFieldMeta; out _5_ty_path: Tq4RelationPath; out _6_y_targetTable: TTableMeta): boolean;
  Var
    _e_sourceTableId: int64;
    _e_ownerTableId:  int64;
  Begin
    Result := False;
    _3_b_isLocalField := False;
    InternalClearFieldMeta( _4_y_requestedField);
    InternalClearRelationPath( _5_ty_path);
    InternalClearTableMeta( _6_y_targetTable);

    If ( _2_p_requestedField = nil) Then Exit;

    If ( not q4DBschemaUse.resolveFieldPointer( _1_p_recordTable, _2_p_requestedField, _e_ownerTableId, _4_y_requestedField, _3_b_isLocalField)) Then Exit;
    If ( not q4DBschemaUse.findTableMeta( _e_ownerTableId, _6_y_targetTable)) Then Exit;

    If ( _3_b_isLocalField) Then Exit( True);

    _e_sourceTableId := q4DBschemaUse.getSourceTableId( _1_p_recordTable);

    If ( not resolveManyToOnePath( _e_sourceTableId, _e_ownerTableId, _5_ty_path)) Then Exit;
    If ( System.Length( _5_ty_path) = 0) Then Exit;

    Result := True;
  End;

Function resolveLinkedFieldPathForSourceTableId( Const _1_e_sourceTableId: int64; Const _2_p_requestedField: Pointer; out _3_b_isLocalField: boolean;
  out _4_y_requestedField: TFieldMeta; out _5_ty_path: Tq4RelationPath; out _6_y_targetTable: TTableMeta): boolean;
  Var
    _e_ownerTableId: int64;
  Begin
    Result := False;
    _3_b_isLocalField := False;
    InternalClearFieldMeta( _4_y_requestedField);
    InternalClearRelationPath( _5_ty_path);
    InternalClearTableMeta( _6_y_targetTable);

    If ( _2_p_requestedField = nil) Then Exit;
    If ( not q4DBschemaUse.resolveFieldPointerGlobal( _2_p_requestedField, _e_ownerTableId, _4_y_requestedField)) Then Exit;

    If ( not q4DBschemaUse.findTableMeta( _e_ownerTableId, _6_y_targetTable)) Then Exit;

    _3_b_isLocalField := _e_ownerTableId = _1_e_sourceTableId;
    If ( _3_b_isLocalField) Then Exit( True);

    If ( not resolveManyToOnePath( _1_e_sourceTableId, _e_ownerTableId, _5_ty_path)) Then Exit;
    If ( System.Length( _5_ty_path) = 0) Then Exit;

    Result := True;
  End;

Function resolveLinkedFieldForSourceTable( Var _1_p_recordTable; Const _2_p_requestedField: Pointer; out _3_b_isLocalField: boolean; out _4_y_requestedField: TFieldMeta;
  out _5_y_sourceLinkField: TFieldMeta; out _6_y_targetLinkField: TFieldMeta; out _7_y_targetTable: TTableMeta): boolean;
  Var
    _ty_path: Tq4RelationPath;
  Begin
    Result := False;
    InternalClearFieldMeta( _5_y_sourceLinkField);
    InternalClearFieldMeta( _6_y_targetLinkField);
    InternalClearTableMeta( _7_y_targetTable);

    If ( not resolveLinkedFieldPathForSourceTable( _1_p_recordTable, _2_p_requestedField, _3_b_isLocalField, _4_y_requestedField, _ty_path, _7_y_targetTable)) Then Exit;

    If ( _3_b_isLocalField) Then Exit( True);
    If ( System.Length( _ty_path) <> 1) Then Exit( False);

    Result := InternalResolveRelationFields( _ty_path[0].e_sourceTableId, _ty_path[0].e_targetTableId, _ty_path[0].e_sourceFieldNo, _ty_path[0].e_targetFieldNo,
      _5_y_sourceLinkField, _6_y_targetLinkField, _7_y_targetTable);
  End;

Function resolveLinkedFieldForSourceTableId( Const _1_e_sourceTableId: int64; Const _2_p_requestedField: Pointer; out _3_b_isLocalField: boolean;
  out _4_y_requestedField: TFieldMeta; out _5_y_sourceLinkField: TFieldMeta; out _6_y_targetLinkField: TFieldMeta; out _7_y_targetTable: TTableMeta): boolean;
  Var
    _ty_path: Tq4RelationPath;
  Begin
    Result := False;
    InternalClearFieldMeta( _5_y_sourceLinkField);
    InternalClearFieldMeta( _6_y_targetLinkField);
    InternalClearTableMeta( _7_y_targetTable);

    If ( not resolveLinkedFieldPathForSourceTableId( _1_e_sourceTableId, _2_p_requestedField, _3_b_isLocalField, _4_y_requestedField, _ty_path, _7_y_targetTable)) Then Exit;

    If ( _3_b_isLocalField) Then Exit( True);
    If ( System.Length( _ty_path) <> 1) Then Exit( False);

    Result := InternalResolveRelationFields( _ty_path[0].e_sourceTableId, _ty_path[0].e_targetTableId, _ty_path[0].e_sourceFieldNo, _ty_path[0].e_targetFieldNo,
      _5_y_sourceLinkField, _6_y_targetLinkField, _7_y_targetTable);
  End;

Function resolveDirectManyToOneFields( Const _1_p_manyField: Pointer; out _2_p_manyField: Pointer; out _3_p_oneField: Pointer): boolean;
  Var
    _e_manyTableId: int64;
    _y_manyField: TFieldMeta;
    _y_range: TTableJoinRange;
    _e_i:     int64;
    _e_last:  int64;
  Begin
    Result := False;
    _2_p_manyField := nil;
    _3_p_oneField := nil;

    If ( _1_p_manyField = nil) Then Exit;
    If ( not q4DBschemaUse.resolveFieldPointerGlobal( _1_p_manyField, _e_manyTableId, _y_manyField)) Then Exit;
    If ( not q4DBschemaUse.findTableJoinRange( _e_manyTableId, _y_range)) Then Exit;

    _e_last := _y_range.LinkIndex + _y_range.LinkCount - 1;

    For _e_i := _y_range.LinkIndex To _e_last Do Begin
      If ( ( _e_i < 0) or ( _e_i > System.High( JoinLinks))) Then Exit( False);

      If ( JoinLinks[_e_i].SourceFieldId = _y_manyField.FieldNo) Then Begin
        If ( not q4DBschemaUse.resolveFieldPointerByIds( _e_manyTableId, JoinLinks[_e_i].SourceFieldId, _2_p_manyField)) Then Exit;
        If ( not q4DBschemaUse.resolveFieldPointerByIds( JoinLinks[_e_i].TargetTableId, JoinLinks[_e_i].TargetFieldId, _3_p_oneField)) Then Exit;
        Exit( ( _2_p_manyField <> nil) and ( _3_p_oneField <> nil));
      End;
    End;
  End;

Function resolveDirectManyTableToOneTableFieldsByIds( Const _1_e_manyTableId: int64; Const _2_e_oneTableId: int64; out _3_p_manyField: Pointer; out _4_p_oneField: Pointer): boolean;
  Var
    _y_range:     TTableJoinRange;
    _e_linkIndex: int64;
    _e_last:      int64;
  Begin
    Result := False;
    _3_p_manyField := nil;
    _4_p_oneField := nil;

    If ( ( _1_e_manyTableId <= 0) or ( _2_e_oneTableId <= 0)) Then Exit;
    If ( not q4DBschemaUse.findTableJoinRange( _1_e_manyTableId, _y_range)) Then Exit;

    _e_last := _y_range.LinkIndex + _y_range.LinkCount - 1;

    For _e_linkIndex := _y_range.LinkIndex To _e_last Do Begin
      If ( ( _e_linkIndex < 0) or ( _e_linkIndex > System.High( JoinLinks))) Then Exit( False);

      If ( JoinLinks[_e_linkIndex].TargetTableId = _2_e_oneTableId) Then Begin
        If ( not q4DBschemaUse.resolveFieldPointerByIds( _1_e_manyTableId, JoinLinks[_e_linkIndex].SourceFieldId, _3_p_manyField)) Then Exit;

        If ( not q4DBschemaUse.resolveFieldPointerByIds( _2_e_oneTableId, JoinLinks[_e_linkIndex].TargetFieldId, _4_p_oneField)) Then Exit;

        Exit( ( _3_p_manyField <> nil) and ( _4_p_oneField <> nil));
      End;
    End;
  End;

Function resolveDirectManyTableToOneTableFields( Const _1_p_manyTable: Pointer; Const _2_p_oneTable: Pointer; out _3_p_manyField: Pointer; out _4_p_oneField: Pointer): boolean;
  Var
    _e_manyTableId: int64;
    _e_oneTableId:  int64;
  Begin
    Result := False;
    _3_p_manyField := nil;
    _4_p_oneField := nil;

    If ( _1_p_manyTable = nil) Then Exit;
    If ( _2_p_oneTable = nil) Then Exit;

    If ( not q4DBschemaUse.resolveTablePointerToSourceTableId( _1_p_manyTable, _e_manyTableId)) Then Exit;
    If ( not q4DBschemaUse.resolveTablePointerToSourceTableId( _2_p_oneTable, _e_oneTableId)) Then Exit;

    Result := resolveDirectManyTableToOneTableFieldsByIds( _e_manyTableId, _e_oneTableId, _3_p_manyField, _4_p_oneField);
  End;

Function resolveDirectOneToManyFields( Const _1_p_oneTable: Pointer; out _2_p_oneField: Pointer; out _3_p_manyField: Pointer): boolean;
  Var
    _e_oneTableId: int64;
    _e_rangeIndex: int64;
    _y_range: TTableJoinRange;
    _e_linkIndex: int64;
    _e_last: int64;
  Begin
    Result := False;
    _2_p_oneField := nil;
    _3_p_manyField := nil;

    If ( not q4DBschemaUse.resolveTablePointerToSourceTableId( _1_p_oneTable, _e_oneTableId)) Then Exit;

    For _e_rangeIndex := 0 To System.High( TableJoinRanges) Do Begin
      _y_range := TableJoinRanges[_e_rangeIndex];
      _e_last := _y_range.LinkIndex + _y_range.LinkCount - 1;

      For _e_linkIndex := _y_range.LinkIndex To _e_last Do Begin
        If ( ( _e_linkIndex < 0) or ( _e_linkIndex > System.High( JoinLinks))) Then Exit( False);

        If ( JoinLinks[_e_linkIndex].TargetTableId = _e_oneTableId) Then Begin
          If ( not q4DBschemaUse.resolveFieldPointerByIds( _e_oneTableId, JoinLinks[_e_linkIndex].TargetFieldId, _2_p_oneField)) Then Exit;
          If ( not q4DBschemaUse.resolveFieldPointerByIds( _y_range.SourceTableId, JoinLinks[_e_linkIndex].SourceFieldId, _3_p_manyField)) Then Exit;
          Exit( ( _2_p_oneField <> nil) and ( _3_p_manyField <> nil));
        End;
      End;
    End;
  End;

Function resolveDirectOneFieldToManyFields( Const _1_p_oneField: Pointer; out _2_p_oneField: Pointer; out _3_p_manyField: Pointer): boolean;
  Var
    _e_oneTableId: int64;
    _y_oneField: TFieldMeta;
    _e_rangeIndex: int64;
    _y_range: TTableJoinRange;
    _e_linkIndex: int64;
    _e_last: int64;
  Begin
    Result := False;
    _2_p_oneField := nil;
    _3_p_manyField := nil;

    If ( _1_p_oneField = nil) Then Exit;
    If ( not q4DBschemaUse.resolveFieldPointerGlobal( _1_p_oneField, _e_oneTableId, _y_oneField)) Then Exit;

    For _e_rangeIndex := 0 To System.High( TableJoinRanges) Do Begin
      _y_range := TableJoinRanges[_e_rangeIndex];
      _e_last := _y_range.LinkIndex + _y_range.LinkCount - 1;

      For _e_linkIndex := _y_range.LinkIndex To _e_last Do Begin
        If ( ( _e_linkIndex < 0) or ( _e_linkIndex > System.High( JoinLinks))) Then Exit( False);

        If ( ( JoinLinks[_e_linkIndex].TargetTableId = _e_oneTableId) and ( JoinLinks[_e_linkIndex].TargetFieldId = _y_oneField.FieldNo)) Then Begin
          If ( not q4DBschemaUse.resolveFieldPointerByIds( _e_oneTableId, JoinLinks[_e_linkIndex].TargetFieldId, _2_p_oneField)) Then Exit;
          If ( not q4DBschemaUse.resolveFieldPointerByIds( _y_range.SourceTableId, JoinLinks[_e_linkIndex].SourceFieldId, _3_p_manyField)) Then Exit;
          Exit( ( _2_p_oneField <> nil) and ( _3_p_manyField <> nil));
        End;
      End;
    End;
  End;

End.
