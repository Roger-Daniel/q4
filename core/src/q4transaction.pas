Unit q4transaction;

{$mode ObjFPC}{$H+}

{
q4transaction
version du 2026/04/18-17:58

Mapping 4D ? q4transaction -> statut
Command Number 4D,    4D Command,                      q4 API,                           Statut
------------------------------------------------------------------------------------------------
1387,                Active transaction,               activeTransaction,                Partial,
241,                 CANCEL TRANSACTION,               cancelTransaction,                Partial,
397,                 In transaction,                   inTransaction,                    OK,
1386,                RESUME TRANSACTION,               resumeTransaction,                TODO,
239,                 START TRANSACTION,                startTransaction,                 Partial,
1385,                SUSPEND TRANSACTION,              suspendTransaction,               TODO,
961,                 Transaction level,                transactionLevel,                 Partial,
240,                 VALIDATE TRANSACTION,             validateTransaction,              Partial,

Doc: https://developer.4d.com/docs/21/commands/theme/Transactions

  Notes d'implémentation :
    - Le design q4 v1 choisit volontairement de ne pas imbriquer les transactions,
      alors que 4D autorise les sous-transactions.
    - transactionLevel reflète uniquement l'état suivi par q4transaction.
    - SUSPEND TRANSACTION / RESUME TRANSACTION ne sont pas encore implémentées.
    - Active transaction reste partiel tant que la suspension n'est pas gérée.
}

Interface

Threadvar
  b_inTransactionQ4: boolean;

Procedure Initialize;

Procedure startTransaction;
// https://developer.4d.com/docs/21/commands/start-transaction

Procedure validateTransaction;
// https://developer.4d.com/docs/21/commands/validate-transaction

Procedure cancelTransaction;
// https://developer.4d.com/docs/21/commands/cancel-transaction

Function inTransaction: boolean;
// https://developer.4d.com/docs/21/commands/in-transaction

Function activeTransaction: boolean;
// https://developer.4d.com/docs/21/commands/active-transaction

Function transactionLevel: int64;
// https://developer.4d.com/docs/21/commands/transaction-level

Procedure suspendTransaction;
// https://developer.4d.com/docs/21/commands/suspend-transaction

Procedure resumeTransaction;
// https://developer.4d.com/docs/21/commands/resume-transaction

Implementation

Uses
  SysUtils,
  SQLDB,
  q4DBmanager,
  q4interruptions,
  q4RecordLocking,
  q4process,
  q4record,
  q4coreLanguage;

Type
  ty_transactionContext = Record
    s_savePointName: string;
  End;

Threadvar
  e_transactionLevel: int64;
  ty_transactionStack: Array Of ty_transactionContext;
  b_initialized: boolean;

Function buildSavePointName( Const _1_e_level: int64): string;
  Begin
    Result := 'q4_tx_' + IntToStr( _1_e_level);
  End;

Procedure Initialize;
  Begin
    SetLength( ty_transactionStack, 0);
    b_inTransactionQ4 := False;
    e_transactionLevel := 0;
    b_initialized := True;
  End;

Procedure startTransaction;
  Var
    Q: TSQLQuery;
    _s_savePointName: string;
  Begin
    If ( b_inTransactionQ4) Then Begin
      // Décision de design q4 v1 : on n'imbrique pas les transactions,
      // même si 4D autorise les sous-transactions.
      q4interruptions.assertRaise( False, 'q4transaction.startTransaction: nested transactions are intentionally not supported in q4 v1');
      Exit;
    End;

    If ( not b_initialized) Then Begin
      q4interruptions.assertRaise( False, 'q4transaction.Initialize must be called before using q4transaction');
      Exit;
    End;

    q4interruptions.assertRaise( not q4record.hasPushedRecords,
      'q4transaction.startTransaction interdit avec des PUSH RECORD en cours');

    Q := TSQLQuery.Create( nil);
    Try
      Q.DataBase := InternalConnection;
      Q.Transaction := InternalTransaction;

      If ( e_transactionLevel = 0) Then Begin
        InternalTransaction.StartTransaction;

        Inc( e_transactionLevel);
        SetLength( ty_transactionStack, e_transactionLevel);
        ty_transactionStack[e_transactionLevel - 1].s_savePointName := '';
        b_inTransactionQ4 := True;
        Exit;
      End;

      Inc( e_transactionLevel);
      SetLength( ty_transactionStack, e_transactionLevel);

      _s_savePointName := buildSavePointName( e_transactionLevel);
      ty_transactionStack[e_transactionLevel - 1].s_savePointName := _s_savePointName;

      Q.SQL.Text := 'SAVEPOINT ' + _s_savePointName;
      Q.ExecSQL;

      b_inTransactionQ4 := True;
    Finally
      Q.Free;
    End;
  End;

Procedure validateTransaction;
  Var
    Q: TSQLQuery;
    _s_savePointName: string;
  Begin
    If ( not b_initialized) Then Begin
      q4interruptions.assertRaise( False, 'q4transaction.initialize must be called before using q4transaction');
      Exit;
    End;

    If ( e_transactionLevel < 1) Then Begin
      q4interruptions.assertRaise( False, 'q4transaction.validateTransaction requires an active transaction');
      Exit;
    End;

    q4interruptions.assertRaise( not q4record.hasPushedRecords,
      'q4transaction.validateTransaction interdit avec des PUSH RECORD en cours'
      );

    q4coreLanguage.OK := 1;

    Q := TSQLQuery.Create( nil);
    Try
      Q.DataBase := InternalConnection;
      Q.Transaction := InternalTransaction;

      Try
        If ( e_transactionLevel = 1) Then InternalTransaction.Commit
        Else Begin
          _s_savePointName := ty_transactionStack[e_transactionLevel - 1].s_savePointName;
          Q.SQL.Text := 'RELEASE SAVEPOINT ' + _s_savePointName;
          Q.ExecSQL;
        End;

        SetLength( ty_transactionStack, e_transactionLevel - 1);
        Dec( e_transactionLevel);
        b_inTransactionQ4 := ( e_transactionLevel > 0);
      Except
        OK := 0;

        If ( e_transactionLevel = 1) Then Begin
          If ( InternalTransaction.Active) Then InternalTransaction.Rollback;
        End Else Begin
          _s_savePointName := ty_transactionStack[e_transactionLevel - 1].s_savePointName;
          Q.SQL.Text := 'ROLLBACK TO SAVEPOINT ' + _s_savePointName;
          Q.ExecSQL;

          Q.SQL.Text := 'RELEASE SAVEPOINT ' + _s_savePointName;
          Q.ExecSQL;
        End;

        SetLength( ty_transactionStack, e_transactionLevel - 1);
        Dec( e_transactionLevel);
        b_inTransactionQ4 := ( e_transactionLevel > 0);

        Raise;
      End;
    Finally
      Q.Free;
    End;

    q4RecordLocking.clearProcessLocks;

  End;

Procedure cancelTransaction;
  Var
    Q: TSQLQuery;
    _s_savePointName: string;
  Begin

    //Les records créés pendant la transaction et qui sont toujours chargés à l'annulation
    //(le stockage fait pendant la transaction devient inopérant)
    //ils doivent donc avoir leurs status remis en mode record en création
    //je suppose que c'est utile pour un record entete de saisie, avec un debut de transaction pour les lignes,
    //puis une décision d'annulation de la saisie de l'utilisateur (un ancien schéma de 4d, peut être encore utilisé par des devs)

    If ( not b_initialized) Then Begin
      q4interruptions.assertRaise( False, 'q4transaction.initialize must be called before using q4transaction');
      Exit;
    End;

    If ( e_transactionLevel < 1) Then Begin
      q4interruptions.assertRaise( False, 'q4transaction.cancelTransaction requires an active transaction');
      Exit;
    End;

    q4interruptions.assertRaise( not q4record.hasPushedRecords,
      'q4transaction.cancelTransaction interdit avec des PUSH RECORD en cours'
      );

    Q := TSQLQuery.Create( nil);
    Try
      Q.DataBase := InternalConnection;
      Q.Transaction := InternalTransaction;

      If ( e_transactionLevel = 1) Then Begin
        If ( InternalTransaction.Active) Then InternalTransaction.Rollback;
      End Else Begin
        _s_savePointName := ty_transactionStack[e_transactionLevel - 1].s_savePointName;

        Q.SQL.Text := 'ROLLBACK TO SAVEPOINT ' + _s_savePointName;
        Q.ExecSQL;

        Q.SQL.Text := 'RELEASE SAVEPOINT ' + _s_savePointName;
        Q.ExecSQL;
      End;

      SetLength( ty_transactionStack, e_transactionLevel - 1);
      Dec( e_transactionLevel);
      b_inTransactionQ4 := ( e_transactionLevel > 0);
    Finally
      Q.Free;
    End;

    q4record.syncLoadedRecordsAfterRollbackForLockedTables;
    q4RecordLocking.clearProcessLocks;
  End;

Function inTransaction: boolean;
  Begin
    Result := b_inTransactionQ4;
  End;

Function activeTransaction: boolean;
  Begin
    Result := b_inTransactionQ4;
  End;

Function transactionLevel: int64;
  Begin
    Result := e_transactionLevel;
  End;

Procedure suspendTransaction;
  Begin
    q4interruptions.assertRaise( False, 'q4transaction.suspendTransaction not supported in q4 v1');
  End;

Procedure resumeTransaction;
  Begin
    q4interruptions.assertRaise( False, 'q4transaction.resumeTransaction not supported in q4 v1');
  End;

End.
