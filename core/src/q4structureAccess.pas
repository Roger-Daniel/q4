Unit q4structureAccess;

{$mode objfpc}{$H+}

{
q4structureAccess
version du 2026/04/18-17:58

Mapping 4D
Command Number 4D,    4D Command,                       q4 API,                           Statut
  ------------------------------------------------------------------------------------------------
252,                 Table,                            table,                            OK,
255,                 Table name,                       tableName,                        OK,
253,                 Field,                            field,                            OK,
257,                 Field name,                       fieldName,                        OK,
256,                 Last field number,                lastFieldNumber,                  OK,
254,                 Last table number,                lastTableNumber,                  OK,
966,                 CREATE INDEX,                     createIndex,                      Not supported,
967,                 DELETE INDEX,                     deleteIndex,                      Not supported,
1293,                PAUSE INDEXES,                    pauseIndexes,                     OK,
1294,                RESUME INDEXES,                   resumeIndexes,                    OK,
344,                 SET INDEX,                        setIndex,                         OK,

Doc: https://developer.4d.com/docs/21/commands/theme/Structure-Access

  Notes:
  - Les commandes par pointeur s'appuient sur q4DBschemaUse.
  - Le dictionnaire reste metier_q4DBschemaBase.
  - Les commandes d'indexation utilisent SQLite via q4DBmanager.
  - SQLite ne gère ici qu’un index de type B-tree ; le type d’index demandé est donc sans effet.
  - Le paramètre * asynchrone 4D n'est pas géré.
  - PAUSE INDEXES / RESUME INDEXES excluent les PrimaryKey et les UniqueKey.
  ----------------------------------------------------------------------
}

Interface

Uses
  SysUtils,
  metier_q4DBschemaBase,
  q4DBschemaUse;

Function table( Const _1_e_tableNum: int64): pointer; overload;
Function table( Const _1_p_fieldPtr: Pointer): int64; overload;

Function tableName( Const _1_e_tableNum: int64): string; overload;
Function tableName( Var _1_p_tablePtr: Pointer): string; overload;

Function field( Const _1_e_tableNum: int64; Const _2_e_fieldNum: int64): Pointer; overload;
Function field( Const _1_p_fieldPtr: Pointer): int64; overload;

Function fieldName( Const _1_e_tableNum: int64; Const _2_e_fieldNum: int64): string; overload;
Function fieldName( Const _1_p_fieldPtr: Pointer): string; overload;

Function lastFieldNumber( Const _1_e_tableNum: int64): int64; overload;
Function lastFieldNumber( Var _1_p_tablePtr: Pointer): int64; overload;
Function lastTableNumber: int64;

Procedure pauseIndexes( Const _1_e_tableNum: int64); overload;
Procedure pauseIndexes( Var _1_p_tablePtr: Pointer); overload;

Procedure resumeIndexes( Const _1_e_tableNum: int64); overload;
Procedure resumeIndexes( Var _1_p_tablePtr: Pointer); overload;

Procedure setIndex( Const _1_e_tableNum: int64; Const _2_e_fieldNum: int64; Const _3_b_indexed: boolean); overload;
Procedure setIndex( Const _1_p_fieldPtr: Pointer; Const _2_b_indexed: boolean); overload;

Implementation

Uses
  SQLDB,
  q4DBmanager,
  q4interruptions;

Procedure InternalRequireTableMeta( Const _1_e_tableNum: int64; out _2_y_table: TTableMeta);
  Begin
    q4interruptions.assertRaise(
      findTableMeta( _1_e_tableNum, _2_y_table),
      'q4structureAccess: table inconnue, tableNum=' + IntToStr( _1_e_tableNum)
      );
  End;

Procedure InternalRequireResolvedFieldPointer( Const _1_p_fieldPtr: Pointer; out _2_e_ownerTableId: int64; out _3_y_field: TFieldMeta);
  Begin
    q4interruptions.assertRaise(
      resolveFieldPointerGlobal( _1_p_fieldPtr, _2_e_ownerTableId, _3_y_field),
      'q4structureAccess: pointeur de champ non résolu'
      );
  End;

Procedure InternalRequireResolvedTablePointer( Const _1_e_tableNum: int64; out _2_p_table: Pointer);
  Begin
    q4interruptions.assertRaise(
      resolveTablePointerBySourceTableId( _1_e_tableNum, _2_p_table),
      'q4structureAccess: pointeur de table non résolu, tableNum=' + IntToStr( _1_e_tableNum)
      );
  End;

Function InternalQuoteIdent( Const _1_t_ident: string): string;
  Begin
    Result := '"' + StringReplace( _1_t_ident, '"', '""', [rfReplaceAll]) + '"';
  End;

Procedure InternalExecSQL( Const _1_t_sql: string);
  Var
    Query: TSQLQuery;
  Begin
    q4interruptions.assertRaise( Assigned( InternalConnection),
      'q4structureAccess.InternalExecSQL: connexion SQLite absente');
    q4interruptions.assertRaise( Assigned( InternalTransaction),
      'q4structureAccess.InternalExecSQL: transaction SQLite absente');

    Query := TSQLQuery.Create( nil);
    Try
      Query.DataBase := InternalConnection;
      Query.Transaction := InternalTransaction;
      Query.SQL.Text := _1_t_sql;
      Query.ExecSQL;
    Finally
      Query.Free;
    End;
  End;

Function InternalFindFieldMetaByFieldNo( Const _1_e_tableNum: int64; Const _2_e_fieldNum: int64; out _3_y_table: TTableMeta; out _4_y_field: TFieldMeta): boolean;
  Var
    _e_fieldOffset:     int64;
    _e_fieldArrayIndex: int64;
  Begin
    Result := False;

    If ( not findTableMeta( _1_e_tableNum, _3_y_table)) Then Exit;

    For _e_fieldOffset := 0 To _3_y_table.FieldCount - 1 Do Begin
      _e_fieldArrayIndex := _3_y_table.FieldIndex + _e_fieldOffset;

      q4interruptions.assertRaise(
        ( _e_fieldArrayIndex >= 0) and ( _e_fieldArrayIndex <= System.High( Fields)),
        'q4structureAccess.InternalFindFieldMetaByFieldNo: index de champ hors limites'
        );

      If ( Fields[_e_fieldArrayIndex].FieldNo = _2_e_fieldNum) Then Begin
        _4_y_field := Fields[_e_fieldArrayIndex];
        Exit( True);
      End;
    End;
  End;

Procedure InternalRequireFieldMetaByFieldNo( Const _1_e_tableNum: int64; Const _2_e_fieldNum: int64; out _3_y_table: TTableMeta; out _4_y_field: TFieldMeta);
  Begin
    q4interruptions.assertRaise(
      InternalFindFieldMetaByFieldNo( _1_e_tableNum, _2_e_fieldNum, _3_y_table, _4_y_field),
      'q4structureAccess: champ inconnu, tableNum=' + IntToStr( _1_e_tableNum) + ', fieldNum=' + IntToStr( _2_e_fieldNum)
      );
  End;

Function InternalIsPauseableIndex( Const _1_y_table: TTableMeta; Const _2_y_field: TFieldMeta): boolean;
  Begin
    Result :=
      _2_y_field.Indexed and ( not SameText( _2_y_field.Name, _1_y_table.PrimaryKey)) and ( not _2_y_field.UniqueKey);
  End;

Procedure InternalCreateIndexForField( Const _1_y_table: TTableMeta; Const _2_y_field: TFieldMeta);
  Var
    _t_sql: string;
    _t_indexName: string;
  Begin
    _t_indexName := BuildIndexName( _1_y_table.SourceTableId, [_2_y_field.FieldNo]);

    _t_sql :=
      'CREATE INDEX IF NOT EXISTS ' + InternalQuoteIdent( _t_indexName) + ' ON ' + InternalQuoteIdent( _1_y_table.Name) + '(' + InternalQuoteIdent( _2_y_field.Name) + ')';

    InternalExecSQL( _t_sql);
  End;

Procedure InternalDropIndexForField( Const _1_y_table: TTableMeta; Const _2_y_field: TFieldMeta);
  Var
    _t_sql: string;
    _t_indexName: string;
  Begin
    _t_indexName := BuildIndexName( _1_y_table.SourceTableId, [_2_y_field.FieldNo]);
    _t_sql := 'DROP INDEX IF EXISTS ' + InternalQuoteIdent( _t_indexName);
    InternalExecSQL( _t_sql);
  End;

Function table( Const _1_e_tableNum: int64): Pointer; overload;
  Begin
    Result := nil;
    InternalRequireResolvedTablePointer( _1_e_tableNum, Result);
  End;

Function table( Const _1_p_fieldPtr: Pointer): int64; overload;
  Var
    _y_field: TFieldMeta;
  Begin
    Result := 0;

    If ( resolveFieldPointerGlobal( _1_p_fieldPtr, Result, _y_field)) Then Exit;

    q4interruptions.assertRaise(
      resolveTablePointerToSourceTableId( _1_p_fieldPtr, Result),
      'q4structureAccess.table: pointeur non résolu'
      );
  End;

Function tableName( Const _1_e_tableNum: int64): string; overload;
  Var
    _y_table: TTableMeta;
  Begin
    Result := '';
    InternalRequireTableMeta( _1_e_tableNum, _y_table);
    Result := _y_table.Name;
  End;

Function tableName( Var _1_p_tablePtr: Pointer): string; overload;
  Begin
    If ( _1_p_tablePtr = nil) Then Exit( '');
    Result := getSourceTableName( _1_p_tablePtr);
  End;

Function field( Const _1_e_tableNum: int64; Const _2_e_fieldNum: int64): Pointer; overload;
  Begin
    If ( not resolveFieldPointerByIds( _1_e_tableNum, _2_e_fieldNum, Result)) Then Result := nil;
  End;

Function field( Const _1_p_fieldPtr: Pointer): int64; overload;
  Var
    _e_ownerTableId: int64;
    _y_field: TFieldMeta;
  Begin
    Result := 0;
    InternalRequireResolvedFieldPointer( _1_p_fieldPtr, _e_ownerTableId, _y_field);
    Result := _y_field.FieldNo;
  End;

Function fieldName( Const _1_p_fieldPtr: Pointer): string; overload;
  Var
    _e_ownerTableId: int64;
    _y_field: TFieldMeta;
  Begin
    Result := '';
    InternalRequireResolvedFieldPointer( _1_p_fieldPtr, _e_ownerTableId, _y_field);
    Result := _y_field.Name;
  End;

Function fieldName( Const _1_e_tableNum: int64; Const _2_e_fieldNum: int64): string; overload;
  Var
    _e_bindingIndex: int64;
    _y_field: TFieldMeta;
  Begin
    Result := '';

    _e_bindingIndex := findBindingIndexByFieldNo( _1_e_tableNum, _2_e_fieldNum);

    q4interruptions.assertRaise(
      ( _e_bindingIndex >= 0) and findFieldMetaAtTableOffset( _1_e_tableNum, _e_bindingIndex, _y_field),
      'q4structureAccess.fieldName: table/champ introuvable'
      );

    Result := _y_field.Name;
  End;

Function lastFieldNumber( Const _1_e_tableNum: int64): int64; overload;
  Var
    _y_table: TTableMeta;
    _e_fieldOffset: int64;
    _e_fieldArrayIndex: int64;
  Begin
    Result := 0;
    InternalRequireTableMeta( _1_e_tableNum, _y_table);

    For _e_fieldOffset := 0 To _y_table.FieldCount - 1 Do Begin
      _e_fieldArrayIndex := _y_table.FieldIndex + _e_fieldOffset;

      q4interruptions.assertRaise(
        ( _e_fieldArrayIndex >= 0) and ( _e_fieldArrayIndex <= System.High( Fields)),
        'q4structureAccess.lastFieldNumber: index de champ hors limites'
        );

      If ( Fields[_e_fieldArrayIndex].FieldNo > Result) Then Result := Fields[_e_fieldArrayIndex].FieldNo;
    End;
  End;

Function lastFieldNumber( Var _1_p_tablePtr: Pointer): int64; overload;
  Begin
    If ( _1_p_tablePtr = nil) Then Exit( 0);
    Result := lastFieldNumber( getSourceTableId( _1_p_tablePtr));
  End;

Function lastTableNumber: int64;
  Var
    _e_i: int64;
  Begin
    Result := 0;

    For _e_i := 0 To System.High( Tables) Do If ( Tables[_e_i].SourceTableId > Result) Then Result := Tables[_e_i].SourceTableId;
  End;

Procedure pauseIndexes( Const _1_e_tableNum: int64);
  Var
    _y_table: TTableMeta;
    _e_fieldOffset: int64;
    _e_fieldArrayIndex: int64;
    _y_field: TFieldMeta;
  Begin
    If ( not findTableMeta( _1_e_tableNum, _y_table)) Then Exit;

    For _e_fieldOffset := 0 To _y_table.FieldCount - 1 Do Begin
      _e_fieldArrayIndex := _y_table.FieldIndex + _e_fieldOffset;

      q4interruptions.assertRaise(
        ( _e_fieldArrayIndex >= 0) and ( _e_fieldArrayIndex <= System.High( Fields)),
        'q4structureAccess.pauseIndexes: index de champ hors limites'
        );

      _y_field := Fields[_e_fieldArrayIndex];

      If ( InternalIsPauseableIndex( _y_table, _y_field)) Then InternalDropIndexForField( _y_table, _y_field);
    End;
  End;

Procedure pauseIndexes( Var _1_p_tablePtr: Pointer);
  Begin
    If ( _1_p_tablePtr = nil) Then Exit;
    pauseIndexes( getSourceTableId( _1_p_tablePtr));
  End;

Procedure resumeIndexes( Const _1_e_tableNum: int64);
  Var
    _y_table: TTableMeta;
    _e_fieldOffset: int64;
    _e_fieldArrayIndex: int64;
    _y_field: TFieldMeta;
  Begin
    If ( not findTableMeta( _1_e_tableNum, _y_table)) Then Exit;

    For _e_fieldOffset := 0 To _y_table.FieldCount - 1 Do Begin
      _e_fieldArrayIndex := _y_table.FieldIndex + _e_fieldOffset;

      q4interruptions.assertRaise(
        ( _e_fieldArrayIndex >= 0) and ( _e_fieldArrayIndex <= System.High( Fields)),
        'q4structureAccess.resumeIndexes: index de champ hors limites'
        );

      _y_field := Fields[_e_fieldArrayIndex];

      If ( InternalIsPauseableIndex( _y_table, _y_field)) Then InternalCreateIndexForField( _y_table, _y_field);
    End;
  End;

Procedure resumeIndexes( Var _1_p_tablePtr: Pointer);
  Begin
    If ( _1_p_tablePtr = nil) Then Exit;
    resumeIndexes( getSourceTableId( _1_p_tablePtr));
  End;

Procedure setIndex( Const _1_e_tableNum: int64; Const _2_e_fieldNum: int64; Const _3_b_indexed: boolean);
  Var
    _y_table: TTableMeta;
    _y_field: TFieldMeta;
  Begin
    InternalRequireFieldMetaByFieldNo( _1_e_tableNum, _2_e_fieldNum, _y_table, _y_field);

    If ( _3_b_indexed) Then InternalCreateIndexForField( _y_table, _y_field)
    Else
      InternalDropIndexForField( _y_table, _y_field);
  End;

Procedure setIndex( Const _1_p_fieldPtr: Pointer; Const _2_b_indexed: boolean);
  Var
    _e_ownerTableId: int64;
    _y_field: TFieldMeta;
  Begin
    InternalRequireResolvedFieldPointer( _1_p_fieldPtr, _e_ownerTableId, _y_field);
    setIndex( _e_ownerTableId, _y_field.FieldNo, _2_b_indexed);
  End;

End.
