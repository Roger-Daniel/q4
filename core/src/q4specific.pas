Unit q4specific;

{$mode objfpc}{$H+}


Interface

Uses
  SysUtils,
  Variants,
  LazUTF8,
  Dialogs,
  q4selection,
  DB,
  SQLDB,
  Classes,
  fpjson,
  q4interruptions,
  metier_q4DBschemaBase,
  metier_q4DBschemaProcess,
  q4DBschemaUse,
  q4record,
  q4communications;

Var
  t_requeteSQL: string;

Function importDatabaseExterne( Const _1_t_filePath: string): TJSONObject;

Implementation

Function runtimeOf( Var _1_p_table: Pointer): Pq4recordRuntime; Inline;
  Begin
    Result := Pq4recordRuntime( _1_p_table);
  End;

Function importDatabaseExterne( Const _1_t_filePath: string): TJSONObject;
  Var
    _o_stream: TFileStream;
    _e_localTableCount: int64;
    _e_versionRecue: longint;
    _e_nbreTableARecevoir: longint;
    _e_noTableRecue: longint;
    _e_noTableCompte: int64;
    _e_noRecordRecu: longint;
    _e_noRecordCompte: int64;
    _p_table:  Pointer;
    _t_erreur: string;
  Begin
    Result := TJSONObject.Create;
    Result.Add( 'ok', False);
    Result.Add( 'file', _1_t_filePath);

    _t_erreur := '';
    _e_localTableCount := High( Tables); // même logique que Get last table number

    _o_stream := TFileStream.Create( _1_t_filePath, fmOpenRead or fmShareDenyWrite);
    Try
      // version
      _e_versionRecue := xportReadI32( _o_stream);
      If ( _e_versionRecue <> 1) Then Begin
        Result.Add( 'error', 'version différente');
        Exit;
      End;

      // nombre de tables annoncé
      _e_nbreTableARecevoir := xportReadI32( _o_stream);
      Result.Add( 'tableCountInFile', _e_nbreTableARecevoir);

      _e_noTableCompte := 0;
      _e_noTableRecue := 0;

      While ( _e_noTableRecue <> -2) Do Begin
        Inc( _e_noTableCompte);

        // numéro de table reçu
        _e_noTableRecue := xportReadI32( _o_stream);

        Case _e_noTableRecue Of
          -2: If ( _e_noTableCompte <= _e_localTableCount) Then Begin
              // fin un peu anticipée par rapport au schéma local
              // on ne bloque pas forcément, on laisse juste une trace
              If ( _t_erreur <> '') Then _t_erreur := _t_erreur + ' | ';
              _t_erreur := _t_erreur + 'fin anticipée';
            End;// fin normale


          Else Begin
            If ( _e_noTableRecue <> _e_noTableCompte) Then Begin
              If ( _t_erreur <> '') Then _t_erreur := _t_erreur + ' | ';
              _t_erreur := _t_erreur + 'décalage des tables';
            End;

            _p_table := metier_q4DBschemaProcess.tablePointer( _e_noTableRecue);
            q4interruptions.assertRaise( _p_table <> nil, 'importDatabaseExterne: tablePointer=nil');

            // vider la table avant réimport
            q4selection.allRecords( runtimeOf( _p_table)^);
            q4selection.deleteSelection( runtimeOf( _p_table)^);

            _e_noRecordRecu := 0;
            _e_noRecordCompte := 0;

            While ( _e_noRecordRecu <> -1) Do Begin
              Inc( _e_noRecordCompte);

              // numéro de record reçu
              _e_noRecordRecu := xportReadI32( _o_stream);

              Case _e_noRecordRecu Of
                -1: ;// fin normale des records de cette table


                Else Begin
                  If ( _e_noRecordRecu <> _e_noRecordCompte) Then Begin
                    If ( _t_erreur <> '') Then _t_erreur := _t_erreur + ' | ';
                    _t_erreur := _t_erreur + 'décalage des no record';
                  End;

                  q4record.createRecord( _p_table);
                  //selon la doc de 4d, createRecord est fait pas receiveRecordExterne
                  receiveRecordExterne( _o_stream, _p_table);
                  q4record.saveRecord( _p_table);
                End;
              End;
            End;
          End;
        End;
      End;

      Result.Booleans['ok'] := ( _t_erreur = '');
      Result.Add( 'error', _t_erreur);
    Finally
      _o_stream.Free;
    End;
  End;

Function SQLReturnsRows( Const _1_t_sql: string): boolean;
  Var
    s: string;
  Begin
    s := UpperCase( Trim( _1_t_sql));

    Result :=
      ( Pos( 'SELECT ', s) = 1) or ( Pos( 'SELECT'#10, s) = 1) or ( Pos( 'SELECT'#13, s) = 1) or ( Pos( 'EXPLAIN ', s) = 1) or ( Pos( 'PRAGMA ', s) = 1) or ( Pos( 'WITH ', s) = 1);
  End;

Procedure RequeteSQL;
  Var
    s:      string;
    _t_sql: string;
    Q:      TSQLQuery;
  Begin
    If ( t_requeteSQL = '') Then t_requeteSQL := 'SELECT * FROM AQQ4_SYSTEM;';

    s := t_requeteSQL;

    If ( not InputQuery( 'SQL', 'Entrez la requête :', s)) Then Exit;

    s := Trim( s);
    If ( s = '') Then Exit;

    t_requeteSQL := s;
    _t_sql := s;

    //  Q := TSQLQuery.Create(nil);
    //  try
    //    Q.Database := InternalConnection;
    //    Q.Transaction := InternalTransaction;
    //    Q.SQL.Text := t_sql;

    //    if SQLReturnsRows(t_sql) then
    //    begin
    //      Q.Open;
    //      ShowMessage('Requête ouverte. Champs = ' + IntToStr(Q.Fields.Count));
    //    end
    //    else
    //    begin
    //      Q.ExecSQL;
    //      InternalTransaction.CommitRetaining;
    //      ShowMessage('Requête exécutée.');
    //    end;
    //  finally
    //    Q.Free;
    //  end;
  End;

End.
