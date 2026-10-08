Unit q4recordLocking;

{$mode objfpc}{$H+}

{
q4recordLocking
version du 2026/04/19-18:57

Mapping 4D → q4recordLocking -> statut
Command Number 4D,    4D Command,                      q4 API,                           Statut
------------------------------------------------------------------------------------------------
145,                 READ ONLY,                        readOnly,                         OK,
362,                 Read only state,                  readOnlyState,                    OK,
146,                 READ WRITE,                       readWrite,                        OK,
212,                 UNLOAD RECORD,                    unloadRecord,                     OK,
52,                  LOAD RECORD,                      loadRecord,                       OK,
353,                 LOCKED BY,                        lockedBy,                         Partial,
1316,                Locked records info,              lockedRecordsInfo,                Partial,
147,                 Locked,                           locked,                           Partial,

Doc: https://developer.4d.com/docs/21/commands/theme/Record-Locking

Notes:
- LOCKED BY est implémenté via un record de retour (Tq4LockedByInfo), alors que 4D remplit plusieurs paramètres de sortie.
- Locked records info retourne ici une String, alors que 4D retourne un Object.
- Locked dépend du moteur de verrouillage logiciel q4 et reste donc une correspondance partielle avec 4D.
}

Interface

Uses
  q4interruptions,
  metier_q4DBschemaBase,
  metier_q4DBschemaProcess,
  q4DBschemaUse;

Const
  ALL_TABLES = '*';


Type
  Tq4AccessMode = (
    amReadWrite,
    amReadOnly
    );

  Tq4LockedByInfo = Record
    e_process: int64;
    t_4DUser: string;
    t_sessionUser: string;
    t_processName: string;
  End;

  ty_recordLock = Record
    e_rowId: int64;
    e_processId: int64;
  End;

  ty_recordLockArray = Array Of ty_recordLock;
  ty_lockMutexArray = Array Of TRTLCriticalSection;

Var
  ty_tableLocks:   Array Of ty_recordLockArray;
  ty_tableMutexes: ty_lockMutexArray;

Procedure Initialize( Const _1_e_tablesCount: int64);
Procedure DoneLockRecord;

Procedure initializeLockRecord;
Procedure finalizeLockRecord;

Procedure ReadOnly( Var _1_p_recordTable); overload;
Procedure ReadOnly( Var _1_p_table: Pointer); overload;
Procedure ReadOnly( Const _1_t_tableSelector: string); overload;

Function readOnlyState( Var _1_p_recordTable): boolean; overload;
Function readOnlyState( Var _1_p_table: Pointer): boolean; overload;

Procedure readWrite( Var _1_p_recordTable); overload;
Procedure readWrite( Var _1_p_table: Pointer); overload;
Procedure readWrite( Const _1_t_tableSelector: string); overload;

Procedure unloadRecord( Var _1_p_recordTable); overload;
Procedure unloadRecord( Var _1_p_table: Pointer); overload;

Procedure loadRecord( Var _1_p_recordTable); overload;
Procedure loadRecord( Var _1_p_table: Pointer); overload;

Function locked( Var _1_p_recordTable): boolean; overload;
Function locked( Var _1_p_table: Pointer): boolean; overload;

Function lockedBy( Var _1_p_recordTable): Tq4LockedByInfo; overload;
Function lockedBy( Var _1_p_table: Pointer): Tq4LockedByInfo; overload;

Function lockedRecordsInfo( Var _1_p_recordTable): string; overload;
Function lockedRecordsInfo( Var _1_p_table: Pointer): string; overload;

Function beginTruncateTable( Var _1_p_recordTable): boolean; overload;
Function beginTruncateTable( Var _1_p_table: Pointer): boolean; overload;
Procedure endTruncateTable( Var _1_p_recordTable); overload;
Procedure endTruncateTable( Var _1_p_table: Pointer); overload;

Function setRecordLock( Const _1_e_tableNo: int64; Const _2_e_rowId: int64; Const _3_e_processId: int64; Const _4_b_locked: boolean): boolean;

Function currentProcessHasLocksOnTable( Const _1_e_tableNo: int64): boolean;

Procedure clearProcessLocks;

Implementation

Uses
  q4record,
  q4transaction,
  q4process,
  SyncObjs,
  SysUtils,
  q4triggerRuntime;

Var
  ty_tableAccessMode: Array Of Tq4AccessMode;
  b_initialized: boolean = False;
  mutexLocks: TCriticalSection;

Procedure initializeLockRecord;
  Begin
    mutexLocks := TCriticalSection.Create;
  End;

Function runtimeOf( Var _1_p_table: Pointer): Pq4recordRuntime; Inline;
  Begin
    Result := Pq4recordRuntime( _1_p_table);
  End;

Procedure ReadOnly( Var _1_p_table: Pointer); overload;
  Begin
    ReadOnly( runtimeOf( _1_p_table)^);
  End;

Function readOnlyState( Var _1_p_table: Pointer): boolean; overload;
  Begin
    Result := readOnlyState( runtimeOf( _1_p_table)^);
  End;

Procedure readWrite( Var _1_p_table: Pointer); overload;
  Begin
    readWrite( runtimeOf( _1_p_table)^);
  End;

Procedure unloadRecord( Var _1_p_table: Pointer); overload;
  Begin
    unloadRecord( runtimeOf( _1_p_table)^);
  End;

Procedure loadRecord( Var _1_p_table: Pointer); overload;
  Begin
    loadRecord( runtimeOf( _1_p_table)^);
  End;

Function locked( Var _1_p_table: Pointer): boolean; overload;
  Begin
    Result := locked( runtimeOf( _1_p_table)^);
  End;

Function lockedBy( Var _1_p_table: Pointer): Tq4LockedByInfo; overload;
  Begin
    Result := lockedBy( runtimeOf( _1_p_table)^);
  End;

Function lockedRecordsInfo( Var _1_p_table: Pointer): string; overload;
  Begin
    Result := lockedRecordsInfo( runtimeOf( _1_p_table)^);
  End;

Function beginTruncateTable( Var _1_p_table: Pointer): boolean; overload;
  Begin
    Result := beginTruncateTable( runtimeOf( _1_p_table)^);
  End;

Procedure endTruncateTable( Var _1_p_table: Pointer); overload;
  Begin
    endTruncateTable( runtimeOf( _1_p_table)^);
  End;

Function currentProcessHasLocksOnTable( Const _1_e_tableNo: int64): boolean;
  Var
    i: int64;
    _e_processId: int64;
  Begin
    Result := False;
    _e_processId := q4process.ProcessState.processID;

    If ( ( _1_e_tableNo < Low( ty_tableLocks)) or ( _1_e_tableNo > High( ty_tableLocks))) Then Exit;

    EnterCriticalSection( ty_tableMutexes[_1_e_tableNo]);
    Try
      For i := 0 To High( ty_tableLocks[_1_e_tableNo]) Do If ( ty_tableLocks[_1_e_tableNo][i].e_processId = _e_processId) Then Exit( True);
    Finally
      LeaveCriticalSection( ty_tableMutexes[_1_e_tableNo]);
    End;
  End;

Procedure finalizeLockRecord;
  Begin
    FreeAndNil( mutexLocks);
  End;

Function setRecordLock( Const _1_e_tableNo: int64; Const _2_e_rowId: int64; Const _3_e_processId: int64; Const _4_b_locked: boolean): boolean;
  Var
    _e_i: int64;
    _e_foundIndex: int64;
  Begin
    Result := False;

    EnterCriticalSection( ty_tableMutexes[_1_e_tableNo]);
    Try
      _e_foundIndex := -1;

      For _e_i := 0 To High( ty_tableLocks[_1_e_tableNo]) Do If ( ty_tableLocks[_1_e_tableNo][_e_i].e_rowId = _2_e_rowId) Then Begin
          _e_foundIndex := _e_i;
          Break;
        End;

      If ( _4_b_locked) Then Begin
        // Aucun verrou sur ce record : on l'ajoute
        If ( _e_foundIndex = -1) Then Begin
          SetLength( ty_tableLocks[_1_e_tableNo], Length( ty_tableLocks[_1_e_tableNo]) + 1);
          ty_tableLocks[_1_e_tableNo][High( ty_tableLocks[_1_e_tableNo])].e_rowId := _2_e_rowId;
          ty_tableLocks[_1_e_tableNo][High( ty_tableLocks[_1_e_tableNo])].e_processId := _3_e_processId;
          Result := True;
          Exit;
        End;

        // Déjà verrouillé par ce process : OK
        If ( ty_tableLocks[_1_e_tableNo][_e_foundIndex].e_processId = _3_e_processId) Then Begin
          Result := True;
          Exit;
        End;

        // Déjà verrouillé par un autre process
        Result := False;
        Exit;
      End;

      // Déverrouillage
      // Si pas trouvé, on considère que c'est déjà déverrouillé
      If ( _e_foundIndex = -1) Then Begin
        Result := True;
        Exit;
      End;

      // On ne supprime que son propre verrou
      If ( ty_tableLocks[_1_e_tableNo][_e_foundIndex].e_processId <> _3_e_processId) Then Begin
        Result := False;
        Exit;
      End;

      For _e_i := _e_foundIndex To High( ty_tableLocks[_1_e_tableNo]) - 1 Do ty_tableLocks[_1_e_tableNo][_e_i] := ty_tableLocks[_1_e_tableNo][_e_i + 1];

      SetLength( ty_tableLocks[_1_e_tableNo], Length( ty_tableLocks[_1_e_tableNo]) - 1);
      Result := True;
    Finally
      LeaveCriticalSection( ty_tableMutexes[_1_e_tableNo]);
    End;
  End;

Procedure unlockLastRecordLock( Const _1_e_tableNo: int64); overload;
  Var
    i: int64;
    y: int64;
    _e_processId: int64;
  Begin
    _e_processId := q4process.ProcessState.processID;

    EnterCriticalSection( ty_tableMutexes[_1_e_tableNo]);
    Try
      For i := High( ty_tableLocks[_1_e_tableNo]) Downto 0 Do If ( ty_tableLocks[_1_e_tableNo][i].e_processId = _e_processId) Then Begin
          If ( q4record.isRowIdPushedRW( _1_e_tableNo, ty_tableLocks[_1_e_tableNo][i].e_rowId)) Then Continue;

          For y := i To High( ty_tableLocks[_1_e_tableNo]) - 1 Do ty_tableLocks[_1_e_tableNo][y] := ty_tableLocks[_1_e_tableNo][y + 1];

          SetLength( ty_tableLocks[_1_e_tableNo], Length( ty_tableLocks[_1_e_tableNo]) - 1);
          Exit;
        End;
    Finally
      LeaveCriticalSection( ty_tableMutexes[_1_e_tableNo]);
    End;
  End;

Procedure unlockLastRecordLock( Const _1_e_tableNo: int64; Const _2_e_nextRowId: int64); overload;
  Var
    i: int64;
    y: int64;
    _e_processId: int64;
  Begin
    _e_processId := q4process.ProcessState.processID;

    EnterCriticalSection( ty_tableMutexes[_1_e_tableNo]);
    Try
      For i := High( ty_tableLocks[_1_e_tableNo]) Downto 0 Do If ( ty_tableLocks[_1_e_tableNo][i].e_processId = _e_processId) Then Begin
          If ( ty_tableLocks[_1_e_tableNo][i].e_rowId = _2_e_nextRowId) Then Exit;
          If ( q4record.isRowIdPushedRW( _1_e_tableNo, ty_tableLocks[_1_e_tableNo][i].e_rowId)) Then Continue;

          For y := i To High( ty_tableLocks[_1_e_tableNo]) - 1 Do ty_tableLocks[_1_e_tableNo][y] := ty_tableLocks[_1_e_tableNo][y + 1];

          SetLength( ty_tableLocks[_1_e_tableNo], Length( ty_tableLocks[_1_e_tableNo]) - 1);
          Exit;
        End;
    Finally
      LeaveCriticalSection( ty_tableMutexes[_1_e_tableNo]);
    End;
  End;

Procedure InternalAssertInitialized;
  Begin
    q4interruptions.assertRaise(
      b_initialized,
      'q4RecordLocking.initialize must be called before using q4RecordLocking'
      );
  End;

Procedure clearProcessLocks;
  Var
    _e_tableNo: int64;
    i: int64;
    y: int64;
    _e_processId: int64;
  Begin
    _e_processId := q4process.ProcessState.processID;

    For _e_tableNo := 1 To High( ty_tableLocks) Do Begin
      EnterCriticalSection( ty_tableMutexes[_e_tableNo]);
      Try
        For i := High( ty_tableLocks[_e_tableNo]) Downto 0 Do If ( ty_tableLocks[_e_tableNo][i].e_processId = _e_processId) Then Begin
            For y := i To High( ty_tableLocks[_e_tableNo]) - 1 Do ty_tableLocks[_e_tableNo][y] := ty_tableLocks[_e_tableNo][y + 1];

            SetLength( ty_tableLocks[_e_tableNo], Length( ty_tableLocks[_e_tableNo]) - 1);
          End;
      Finally
        LeaveCriticalSection( ty_tableMutexes[_e_tableNo]);
      End;
    End;
  End;

Function InternalFindLockOwner( Const _1_e_tableNo: int64; Const _2_e_rowId: int64; out _3_e_processId: int64): boolean;
  Var
    _e_i: int64;
  Begin
    Result := False;
    _3_e_processId := 0;

    EnterCriticalSection( ty_tableMutexes[_1_e_tableNo]);
    Try
      For _e_i := 0 To High( ty_tableLocks[_1_e_tableNo]) Do If ( ty_tableLocks[_1_e_tableNo][_e_i].e_rowId = _2_e_rowId) Then Begin
          _3_e_processId := ty_tableLocks[_1_e_tableNo][_e_i].e_processId;
          Result := True;
          Exit;
        End;
    Finally
      LeaveCriticalSection( ty_tableMutexes[_1_e_tableNo]);
    End;
  End;

Procedure InternalAssertValidTableNo( Const _1_e_tableNo: int64);
  Begin
    q4interruptions.assertRaise(
      _1_e_tableNo > 0,
      'q4RecordLocking invalid table number: system table 0 is not supported'
      );

    q4interruptions.assertRaise(
      _1_e_tableNo <= System.High( ty_tableAccessMode),
      'q4RecordLocking invalid table number: exceeds metadata bounds'
      );
  End;

Procedure InternalSetTableAccessMode( Const _1_e_tableNo: int64; Const _2_y_accessMode: Tq4AccessMode);
  Begin

    InternalAssertInitialized;
    InternalAssertValidTableNo( _1_e_tableNo);

    ty_tableAccessMode[_1_e_tableNo] := _2_y_accessMode;
  End;


Function InternalReadOnlyState( Const _1_e_tableNo: int64): boolean;
  Begin

    InternalAssertInitialized;
    InternalAssertValidTableNo( _1_e_tableNo);

    Result := False;
    Result := ty_tableAccessMode[_1_e_tableNo] = amReadOnly;
  End;

Function InternalLockedBy( Const _1_e_tableNo: int64; Const _2_e_rowId: int64): Tq4LockedByInfo;
  Var
    _e_processId: int64;
  Begin
    InternalAssertInitialized;
    InternalAssertValidTableNo( _1_e_tableNo);

    Result.e_process := 0;
    Result.t_4DUser := '';
    Result.t_sessionUser := '';
    Result.t_processName := '';

    // -2 = record supprimé / introuvable mais position valide dans la sélection
    // On s'aligne sur 4D LOCKED BY : process = -1, chaînes vides.
    If ( _2_e_rowId = -2) Then Begin
      Result.e_process := -1;
      Exit;
    End;

    // -1 pas de record, -3 création : pas de lock exploitable
    If ( _2_e_rowId < 0) Then Exit;

    If ( InternalFindLockOwner( _1_e_tableNo, _2_e_rowId, _e_processId)) Then Begin
      Result.e_process := _e_processId;

      // À compléter plus tard si q4process expose vraiment ces infos
      // pour un autre process de manière centralisée.
      If ( _e_processId = q4process.ProcessState.processID) Then Begin
        Result.t_processName := q4process.ProcessState.processName;
        Result.t_sessionUser := q4process.ProcessState.sessionUser;
        Result.t_4DUser := q4process.ProcessState.userName4D;
      End;
    End;
  End;

Function InternalLockedRecordsInfo( Const _1_e_tableNo: int64): string;
  Var
    _e_i:    int64;
    _t_json: string;
  Begin
    InternalAssertInitialized;
    InternalAssertValidTableNo( _1_e_tableNo);

    _t_json := '{"records":[';

    EnterCriticalSection( ty_tableMutexes[_1_e_tableNo]);
    Try
      For _e_i := 0 To High( ty_tableLocks[_1_e_tableNo]) Do Begin
        If ( _e_i > 0) Then _t_json := _t_json + ',';

        _t_json := _t_json + '{"rowId":' + IntToStr( ty_tableLocks[_1_e_tableNo][_e_i].e_rowId) + ',"process":' + IntToStr( ty_tableLocks[_1_e_tableNo][_e_i].e_processId) + '}';
      End;
    Finally
      LeaveCriticalSection( ty_tableMutexes[_1_e_tableNo]);
    End;

    _t_json := _t_json + ']}';
    Result := _t_json;
  End;

Function InternalBeginTruncateTable( Const _1_e_tableNo: int64): boolean;
  Var
    _e_i: int64;
  Begin
    InternalAssertInitialized;
    InternalAssertValidTableNo( _1_e_tableNo);

    EnterCriticalSection( ty_tableMutexes[_1_e_tableNo]);
    Try
      // TRUNCATE TABLE est volontairement sérialisé par le mutex de table.
      // La commande échoue si un verrou record existe encore sur cette table
      // ou si une transaction est en cours dans ce process.
      If ( q4transaction.inTransaction) Then Begin
        LeaveCriticalSection( ty_tableMutexes[_1_e_tableNo]);
        Exit( False);
      End;

      If ( Length( ty_tableLocks[_1_e_tableNo]) <> 0) Then Begin
        LeaveCriticalSection( ty_tableMutexes[_1_e_tableNo]);
        Exit( False);
      End;

      Result := True;
    Except
      LeaveCriticalSection( ty_tableMutexes[_1_e_tableNo]);
      Raise;
    End;
  End;

Procedure InternalEndTruncateTable( Const _1_e_tableNo: int64);
  Begin
    InternalAssertInitialized;
    InternalAssertValidTableNo( _1_e_tableNo);

    LeaveCriticalSection( ty_tableMutexes[_1_e_tableNo]);
  End;

Function InternalLocked( Const _1_e_tableNo: int64; Const _2_e_rowId: int64; Const _3_b_readWrite: boolean): boolean;
  Var
    _e_processId: int64;
  Begin
    InternalAssertInitialized;
    InternalAssertValidTableNo( _1_e_tableNo);

    Result := False;

    // record supprimé => on considère l'état comme "locked/non modifiable"
    If ( _2_e_rowId = -2) Then Begin
      Result := True;
      Exit;
    End;

    // pas de record / création => pas "locked" au sens record existant verrouillé
    If ( _2_e_rowId < 0) Then Exit;

    // en READ ONLY, 4D considère le record comme non modifiable => Locked = True
    If ( ty_tableAccessMode[_1_e_tableNo] = amReadOnly) Then Begin
      Result := True;
      Exit;
    End;

    // si le record est verrouillé par quelqu'un d'autre, Locked = True
    If ( InternalFindLockOwner( _1_e_tableNo, _2_e_rowId, _e_processId)) Then Begin
      Result := ( _e_processId <> q4process.ProcessState.processID);
      Exit;
    End;

    // si on n'a pas le lock local RW, le record n'est pas verrouillé
    // par définition de votre moteur logiciel
    Result := False;
  End;

Function locked( Var _1_p_recordTable): boolean;
    //https://developer.4d.com/docs/21/commands/locked
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);
    Result := InternalLocked( _p_runtime^._noTable, _p_runtime^._RowId, _p_runtime^._ReadWrite);
  End;

Function beginTruncateTable( Var _1_p_recordTable): boolean;
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);
    Result := InternalBeginTruncateTable( _p_runtime^._noTable);
  End;

Procedure endTruncateTable( Var _1_p_recordTable);
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);
    InternalEndTruncateTable( _p_runtime^._noTable);
  End;

Procedure Initialize( Const _1_e_tablesCount: int64);
  Var
    _e_tableNo: int64;
  Begin
    q4interruptions.assertRaise(
      _1_e_tablesCount > 0,
      'q4RecordLocking.initialize requires q4DBmanager.Tables metadata'
      );

    SetLength( ty_tableAccessMode, _1_e_tablesCount + 1);
    SetLength( ty_tableLocks, _1_e_tablesCount + 1);
    SetLength( ty_tableMutexes, _1_e_tablesCount + 1);

    //for e_tableNo := 1 to System.High(ty_tableAccessMode) do begin
    //  ty_tableAccessMode[e_tableNo] := amReadWrite;
    //end;

    For _e_tableNo := 1 To _1_e_tablesCount Do Begin
      ty_tableAccessMode[_e_tableNo] := amReadWrite;
      SetLength( ty_tableLocks[_e_tableNo], 0);
      InitCriticalSection( ty_tableMutexes[_e_tableNo]);
    End;

    b_initialized := True;
  End;

Procedure DoneLockRecord;
  Begin
    SetLength( ty_tableAccessMode, 0);
    SetLength( ty_tableLocks, 0);
    SetLength( ty_tableMutexes, 0);

    b_initialized := False;
  End;

Procedure ReadOnly( Var _1_p_recordTable);
  //https://developer.4d.com/docs/21/commands/read-only
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    InternalSetTableAccessMode( _p_runtime^._noTable, amReadOnly);
  End;

Procedure ReadOnly( Const _1_t_tableSelector: string);//"*"
  //https://developer.4d.com/docs/21/commands/read-only
  Var
    _e_tableNo: int64;
  Begin

    q4interruptions.assertRaise(
      _1_t_tableSelector = ALL_TABLES,
      'q4RecordLocking.readOnly(string) only supports "*"'
      );

    For _e_tableNo := 1 To System.High( ty_tableAccessMode) Do InternalSetTableAccessMode( _e_tableNo, amReadOnly);
  End;

Function readOnlyState( Var _1_p_recordTable): boolean;
    //https://developer.4d.com/docs/21/commands/read-only-state
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    Result := False;
    Result := InternalReadOnlyState( _p_runtime^._noTable);
  End;

Procedure readWrite( Const _1_t_tableSelector: string);//"*"
  //https://developer.4d.com/docs/21/commands/read-write
  Var
    _e_tableNo: int64;
  Begin

    q4interruptions.assertRaise(
      _1_t_tableSelector = ALL_TABLES,
      'q4RecordLocking.readWrite(string) only supports "*"'
      );

    For _e_tableNo := 1 To System.High( ty_tableAccessMode) Do InternalSetTableAccessMode( _e_tableNo, amReadWrite);
  End;

Procedure readWrite( Var _1_p_recordTable);
  //https://developer.4d.com/docs/21/commands/read-write
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    InternalSetTableAccessMode( _p_runtime^._noTable, amReadWrite);
  End;

Procedure unloadRecord( Var _1_p_recordTable);
  //https://developer.4d.com/docs/21/commands/unload-record
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    InternalAssertInitialized;

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenCommand,
          'q4RecordLocking.unloadRecord interdit pendant un trigger'
          );

    // Lever le verrou logiciel seulement hors transaction.
    // En transaction, le verrou doit rester porté par le process q4
    // jusqu'à validateTransaction / cancelTransaction.

    If ( _p_runtime^._RowId > -1) Then If ( not q4transaction.inTransaction) Then setRecordLock( _p_runtime^._noTable, _p_runtime^._RowId, ProcessState.processID, False)// rowid réel uniquement
    ;

    q4record.clearArraySQL( _p_runtime^._ArraySQL);
    q4record.copyArraySQLToBindings( _p_runtime^._Bindings, _p_runtime^._ArraySQL);

    _p_runtime^._Loaded := False;
    _p_runtime^._Modified := False;
    ;
    _p_runtime^._ReadWrite := False;
    _p_runtime^._RowId := -1;

  End;

Procedure loadRecord( Var _1_p_recordTable);
  //https://developer.4d.com/docs/21/commands/load-record
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    InternalAssertInitialized;

    If ( q4triggerRuntime.q4InTrigger) Then If ( not q4triggerRuntime.q4TriggerTableAccessAllowed( _p_runtime^._noTable)) Then q4triggerRuntime.q4RaiseTriggerError(
          Q4ErrorTriggerForbiddenCommand,
          'q4RecordLocking.loadRecord interdit pendant un trigger'
          );

    If ( _p_runtime^._RowId < 0) Then Exit;     // -1 pas de record, -2 supprimé, -3 création

    // Si le record était chargé en écriture hors transaction,
    // il faut libérer le verrou précédent avant reload.
    // Si la table est passée en lecture, le verrou doit être supprimé
    // même si on recharge le même record.

    If ( ( _p_runtime^._ReadWrite) and ( not q4transaction.inTransaction)) Then If ( not InternalReadOnlyState( _p_runtime^._noTable)) Then unlockLastRecordLock( _p_runtime^._noTable, _p_runtime^._RowId)
      Else
        unlockLastRecordLock( _p_runtime^._noTable);

    q4record.copyArraySQLToBindings( _p_runtime^._Bindings, _p_runtime^._ArraySQL);

    _p_runtime^._Loaded := True;
    _p_runtime^._Modified := False;
    _p_runtime^._ReadWrite := False;
    If ( not InternalReadOnlyState( _p_runtime^._noTable)) Then If ( setRecordLock( _p_runtime^._noTable, _p_runtime^._RowId, ProcessState.processID, True)) Then
        If ( not q4record.isRowIdPushedRW( _p_runtime^._noTable, _p_runtime^._RowId)) Then _p_runtime^._ReadWrite := True;
  End;

Function lockedBy( Var _1_p_recordTable): Tq4LockedByInfo;
    //https://developer.4d.com/docs/21/commands/locked-by
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);
    Result := InternalLockedBy( _p_runtime^._noTable, _p_runtime^._RowId);
  End;

Function lockedRecordsInfo( Var _1_p_recordTable): string;
    //https://developer.4d.com/docs/21/commands/locked-records-info
  Var
    _p_runtime: Pq4recordRuntime;
  Begin
    _p_runtime := Pq4recordRuntime( @_1_p_recordTable);

    Result := '';
    Result := InternalLockedRecordsInfo( _p_runtime^._noTable);
  End;

End.
