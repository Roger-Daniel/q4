Unit q4selectionTablesCore;

{$mode objfpc}{$H+}

{
q4selectionTablesCore
version du 2026/04/18-17:58

Mapping q4 → q4selectionTablesCore -> statut
q4 service                              API                                   Statut
------------------------------------------------------------------------------------
thread selection table name             buildSelectionTableName                OK
shared selection table name             buildSelectionTableName                OK
ensure selection table                  ensureSelectionTable                   OK
clear full selection table              clearSelectionTable                    OK
clear one resultNo                      clearSelectionResultNo                 OK
trim one resultNo                       trimSelectionResultAfterPos            OK
materialize all records                 materializeAllRecordsToSelectionTable  OK
materialize custom PK select            materializePkSelectToSelectionTable    OK
cleanup shared tables at open           clearSharedSelectionTablesAtOpen       OK

Notes
- Unité technique ciblée sur les tables de sélection.
- Aucune logique de navigation ni d'état de sélection ici.
- Les tables thread sont créées en q4temp_.
- Les tables shared sont créées en base normale, avec préfixe q4shared_.
}

Interface

Uses
  SysUtils,
  SQLDB,
  q4DBmanager,
  q4interruptions;

Type
  Tq4selectionTableScope = (
    qstsThread,
    qstsShared
    );

Function buildSelectionTableName( Const _1_e_scope: Tq4selectionTableScope; Const _2_t_sourceTableName: string): string;
Function isSharedSelectionTableName( Const _1_t_tableName: string): boolean;
Function isThreadSelectionTableName( Const _1_t_tableName: string): boolean;

Procedure ensureSelectionTable( Const _1_e_scope: Tq4selectionTableScope; Const _2_t_tableName: string; Const _3_t_pkFieldName: string; Const _4_t_pkTypeSQL: string);

Procedure clearSelectionTable( Const _1_t_tableName: string);
Procedure clearSelectionResultNo( Const _1_t_tableName: string; Const _2_e_resultNo: int64);
Procedure trimSelectionResultAfterPos( Const _1_t_tableName: string; Const _2_e_resultNo: int64; Const _3_e_maxPos: int64);

Function materializeAllRecordsToSelectionTable( Const _1_t_sourceTableName: string; Const _2_t_targetTableName: string; Const _3_t_pkFieldName: string; Const _4_e_resultNo: int64): int64;

Function materializePkSelectToSelectionTable( Const _1_t_selectPkSql: string; Const _2_t_targetTableName: string; Const _3_t_pkFieldName: string; Const _4_e_resultNo: int64): int64;

Procedure clearSharedSelectionTablesAtOpen;

Implementation

Function buildSelectionTableName( Const _1_e_scope: Tq4selectionTableScope; Const _2_t_sourceTableName: string): string;
  Begin
    q4interruptions.assertRaise( SysUtils.Trim( _2_t_sourceTableName) <> '',
      'q4selectionTablesCore.buildSelectionTableName : nom metier vide');

    Case _1_e_scope Of
      qstsThread: Result := 'q4temp_' + _2_t_sourceTableName;
      qstsShared: Result := 'q4shared_' + _2_t_sourceTableName;
      Else q4interruptions.assertRaise( False,
          'q4selectionTablesCore.buildSelectionTableName : scope invalide');
        Result := '';
    End;
  End;

Function isSharedSelectionTableName( Const _1_t_tableName: string): boolean;
  Begin
    Result := Copy( _1_t_tableName, 1, 9) = 'q4shared_';
  End;

Function isThreadSelectionTableName( Const _1_t_tableName: string): boolean;
  Begin
    Result := Copy( _1_t_tableName, 1, 7) = 'q4temp_';
  End;

Procedure ensureSelectionTable( Const _1_e_scope: Tq4selectionTableScope; Const _2_t_tableName: string; Const _3_t_pkFieldName: string; Const _4_t_pkTypeSQL: string);
  Var
    _o_query: TSQLQuery;
    _t_sql:   string;
    _t_createKeyword: string;
  Begin
    q4interruptions.assertRaise( SysUtils.Trim( _2_t_tableName) <> '',
      'q4selectionTablesCore.ensureSelectionTable : nom table vide');
    q4interruptions.assertRaise( SysUtils.Trim( _3_t_pkFieldName) <> '',
      'q4selectionTablesCore.ensureSelectionTable : nom champ PK vide');
    q4interruptions.assertRaise( SysUtils.Trim( _4_t_pkTypeSQL) <> '',
      'q4selectionTablesCore.ensureSelectionTable : type SQL PK vide');

    Case _1_e_scope Of
      qstsThread: _t_createKeyword := 'CREATE TEMP TABLE IF NOT EXISTS ';
      qstsShared: _t_createKeyword := 'CREATE TABLE IF NOT EXISTS ';
      Else q4interruptions.assertRaise( False,
          'q4selectionTablesCore.ensureSelectionTable : scope invalide');
        Exit;
    End;

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;

      _t_sql :=
        _t_createKeyword + _2_t_tableName + ' (' + _3_t_pkFieldName + ' ' + _4_t_pkTypeSQL + ', ' + 'pos INTEGER NOT NULL, ' + 'noResultat INTEGER NOT NULL' + ')';
      _o_query.SQL.Text := _t_sql;
      _o_query.ExecSQL;

      _t_sql :=
        'CREATE INDEX IF NOT EXISTS idx_' + _2_t_tableName + '_res_pos ' + 'ON ' + _2_t_tableName + ' (noResultat, pos)';
      _o_query.SQL.Text := _t_sql;
      _o_query.ExecSQL;

      _t_sql :=
        'CREATE INDEX IF NOT EXISTS idx_' + _2_t_tableName + '_res_pk ' + 'ON ' + _2_t_tableName + ' (noResultat, ' + _3_t_pkFieldName + ')';
      _o_query.SQL.Text := _t_sql;
      _o_query.ExecSQL;
    Finally
      _o_query.Free;
    End;
  End;

Procedure clearSelectionTable( Const _1_t_tableName: string);
  Var
    _o_query: TSQLQuery;
    _t_sql:   string;
  Begin
    q4interruptions.assertRaise( SysUtils.Trim( _1_t_tableName) <> '',
      'q4selectionTablesCore.clearSelectionTable : nom table vide');

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;

      _t_sql := 'DELETE FROM ' + _1_t_tableName;
      _o_query.SQL.Text := _t_sql;
      _o_query.ExecSQL;
    Finally
      _o_query.Free;
    End;
  End;

Procedure clearSelectionResultNo( Const _1_t_tableName: string; Const _2_e_resultNo: int64);
  Var
    _o_query: TSQLQuery;
    _t_sql:   string;
  Begin
    q4interruptions.assertRaise( SysUtils.Trim( _1_t_tableName) <> '',
      'q4selectionTablesCore.clearSelectionResultNo : nom table vide');
    q4interruptions.assertRaise( _2_e_resultNo >= 0,
      'q4selectionTablesCore.clearSelectionResultNo : resultNo invalide');

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;

      _t_sql :=
        'DELETE FROM ' + _1_t_tableName + ' ' + 'WHERE noResultat = :noResultat';
      _o_query.SQL.Text := _t_sql;
      _o_query.ParamByName( 'noResultat').AsInteger := _2_e_resultNo;
      _o_query.ExecSQL;
    Finally
      _o_query.Free;
    End;
  End;

Procedure trimSelectionResultAfterPos( Const _1_t_tableName: string; Const _2_e_resultNo: int64; Const _3_e_maxPos: int64);
  Var
    _o_query: TSQLQuery;
    _t_sql:   string;
  Begin
    q4interruptions.assertRaise( SysUtils.Trim( _1_t_tableName) <> '',
      'q4selectionTablesCore.trimSelectionResultAfterPos : nom table vide');
    q4interruptions.assertRaise( _2_e_resultNo >= 0,
      'q4selectionTablesCore.trimSelectionResultAfterPos : resultNo invalide');
    q4interruptions.assertRaise( _3_e_maxPos >= 0,
      'q4selectionTablesCore.trimSelectionResultAfterPos : maxPos invalide');

    _o_query := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;

      _t_sql :=
        'DELETE FROM ' + _1_t_tableName + ' ' + 'WHERE noResultat = :noResultat ' + 'AND pos > :maxPos';
      _o_query.SQL.Text := _t_sql;
      _o_query.ParamByName( 'noResultat').AsInteger := _2_e_resultNo;
      _o_query.ParamByName( 'maxPos').AsInteger := _3_e_maxPos;
      _o_query.ExecSQL;
    Finally
      _o_query.Free;
    End;
  End;

Function materializeAllRecordsToSelectionTable( Const _1_t_sourceTableName: string; Const _2_t_targetTableName: string; Const _3_t_pkFieldName: string; Const _4_e_resultNo: int64): int64;
  Var
    _o_readQuery: TSQLQuery;
    _o_writeQuery: TSQLQuery;
    _t_sql: string;
    _e_pos: int64;
  Begin
    q4interruptions.assertRaise( SysUtils.Trim( _1_t_sourceTableName) <> '',
      'q4selectionTablesCore.materializeAllRecordsToSelectionTable : nom table source vide');
    q4interruptions.assertRaise( SysUtils.Trim( _2_t_targetTableName) <> '',
      'q4selectionTablesCore.materializeAllRecordsToSelectionTable : nom table cible vide');
    q4interruptions.assertRaise( SysUtils.Trim( _3_t_pkFieldName) <> '',
      'q4selectionTablesCore.materializeAllRecordsToSelectionTable : nom champ PK vide');
    q4interruptions.assertRaise( _4_e_resultNo >= 0,
      'q4selectionTablesCore.materializeAllRecordsToSelectionTable : resultNo invalide');

    _e_pos := 0;

    _o_readQuery := TSQLQuery.Create( nil);
    _o_writeQuery := TSQLQuery.Create( nil);
    Try
      _o_readQuery.DataBase := InternalConnection;
      _o_readQuery.Transaction := InternalTransaction;

      _o_writeQuery.DataBase := InternalConnection;
      _o_writeQuery.Transaction := InternalTransaction;

      _t_sql := 'SELECT ' + _3_t_pkFieldName + ' FROM ' + _1_t_sourceTableName;
      _o_readQuery.SQL.Text := _t_sql;
      _o_readQuery.Open;

      _t_sql :=
        'INSERT INTO ' + _2_t_targetTableName + ' (' + _3_t_pkFieldName + ', pos, noResultat) ' + 'VALUES (:pk, :pos, :noResultat)';
      _o_writeQuery.SQL.Text := _t_sql;
      _o_writeQuery.Prepare;

      While ( not _o_readQuery.EOF) Do Begin
        Inc( _e_pos);

        _o_writeQuery.ParamByName( 'pk').Value := _o_readQuery.FieldByName( _3_t_pkFieldName).Value;
        _o_writeQuery.ParamByName( 'pos').AsInteger := _e_pos;
        _o_writeQuery.ParamByName( 'noResultat').AsInteger := _4_e_resultNo;
        _o_writeQuery.ExecSQL;

        _o_readQuery.Next;
      End;
    Finally
      _o_writeQuery.Free;
      _o_readQuery.Free;
    End;

    Result := _e_pos;
  End;

Function materializePkSelectToSelectionTable( Const _1_t_selectPkSql: string; Const _2_t_targetTableName: string; Const _3_t_pkFieldName: string; Const _4_e_resultNo: int64): int64;
  Var
    _o_readQuery: TSQLQuery;
    _o_writeQuery: TSQLQuery;
    _t_sql: string;
    _e_pos: int64;
  Begin
    q4interruptions.assertRaise( SysUtils.Trim( _1_t_selectPkSql) <> '',
      'q4selectionTablesCore.materializePkSelectToSelectionTable : select PK vide');
    q4interruptions.assertRaise( SysUtils.Trim( _2_t_targetTableName) <> '',
      'q4selectionTablesCore.materializePkSelectToSelectionTable : nom table cible vide');
    q4interruptions.assertRaise( SysUtils.Trim( _3_t_pkFieldName) <> '',
      'q4selectionTablesCore.materializePkSelectToSelectionTable : nom champ PK vide');
    q4interruptions.assertRaise( _4_e_resultNo >= 0,
      'q4selectionTablesCore.materializePkSelectToSelectionTable : resultNo invalide');

    _e_pos := 0;

    _o_readQuery := TSQLQuery.Create( nil);
    _o_writeQuery := TSQLQuery.Create( nil);
    Try
      _o_readQuery.DataBase := InternalConnection;
      _o_readQuery.Transaction := InternalTransaction;
      _o_readQuery.SQL.Text := _1_t_selectPkSql;
      _o_readQuery.Open;

      _o_writeQuery.DataBase := InternalConnection;
      _o_writeQuery.Transaction := InternalTransaction;
      _t_sql :=
        'INSERT INTO ' + _2_t_targetTableName + ' (' + _3_t_pkFieldName + ', pos, noResultat) ' + 'VALUES (:pk, :pos, :noResultat)';
      _o_writeQuery.SQL.Text := _t_sql;
      _o_writeQuery.Prepare;

      While ( not _o_readQuery.EOF) Do Begin
        Inc( _e_pos);

        _o_writeQuery.ParamByName( 'pk').Value := _o_readQuery.Fields[0].Value;
        _o_writeQuery.ParamByName( 'pos').AsInteger := _e_pos;
        _o_writeQuery.ParamByName( 'noResultat').AsInteger := _4_e_resultNo;
        _o_writeQuery.ExecSQL;

        _o_readQuery.Next;
      End;
    Finally
      _o_writeQuery.Free;
      _o_readQuery.Free;
    End;

    Result := _e_pos;
  End;

Procedure clearSharedSelectionTablesAtOpen;
  Var
    _o_query:     TSQLQuery;
    _o_drop:      TSQLQuery;
    _t_tableName: string;
  Begin
    _o_query := TSQLQuery.Create( nil);
    _o_drop := TSQLQuery.Create( nil);
    Try
      _o_query.DataBase := InternalConnection;
      _o_query.Transaction := InternalTransaction;
      _o_query.SQL.Text :=
        'SELECT name FROM sqlite_master ' + 'WHERE type = ''table'' AND name LIKE ''q4shared_%''';
      _o_query.Open;

      _o_drop.DataBase := InternalConnection;
      _o_drop.Transaction := InternalTransaction;

      While ( not _o_query.EOF) Do Begin
        _t_tableName := _o_query.Fields[0].AsString;
        If ( isSharedSelectionTableName( _t_tableName)) Then Begin
          _o_drop.SQL.Text := 'DROP TABLE IF EXISTS ' + _t_tableName;
          _o_drop.ExecSQL;
        End;
        _o_query.Next;
      End;
    Finally
      _o_drop.Free;
      _o_query.Free;
    End;
  End;

End.
