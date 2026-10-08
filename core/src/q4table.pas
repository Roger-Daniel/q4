Unit q4table;

{$mode objfpc}{$H+}

{
q4table
version du 2026/05/14-01

Mapping 4D → q4table -> statut
Command Number 4D,    4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
363,                  Current default table,             currentDefaultTable,              OK spécifique,
627,                  Current form table,                currentFormTable,                 Partial,
46,                   DEFAULT TABLE,                     defaultTable,                     OK spécifique,
993,                  NO DEFAULT TABLE,                  noDefaultTable,                   OK spécifique,

Doc: https://developer.4d.com/docs/21/commands/theme/Table
}

Interface

Function currentDefaultTable: int64;
Function currentFormTable: int64;
Procedure defaultTable( _1_e_tableNumber: int64);
Procedure noDefaultTable;

Implementation

Uses
  q4process,
  q4Interruptions;

Function currentDefaultTable: int64;
  Begin
    // https://developer.4d.com/docs/21/commands/current-default-table

    // 4D retourne un Pointer vers la table par défaut.
    // q4 v1.x représente ce pointeur de table par son numéro de table Int64.
    // La valeur 0 représente l'équivalent q4 d'un pointeur nil / aucune table.
    Result := q4process.ProcessState.currentTableNumber;
  End;

Function currentFormTable: int64;
  Begin
    // https://developer.4d.com/docs/21/commands/current-form-table

    // Implémentation partielle :
    // 4D retourne la table du formulaire affiché ou imprimé dans le process courant.
    // q4 ne dispose pas encore d'un runtime formulaire complet.
    // La valeur est donc lue depuis q4process.ProcessState.formTableNumber,
    // qui devra être alimentée plus tard par les unités liées aux formulaires.
    // 0 signifie : aucun formulaire table courant, project form, ou contexte non géré.
    Result := q4process.ProcessState.formTableNumber;
  End;

Procedure defaultTable( _1_e_tableNumber: int64);
  Begin
    // https://developer.4d.com/docs/21/commands/default-table

    // 4D reçoit ici une table, pas un numéro.
    // q4 v1.x représente la table par son numéro Int64.
    // DEFAULT TABLE ne doit pas ouvrir la table, préparer SQLite,
    // modifier une sélection ou charger un enregistrement :
    // c'est uniquement un contexte process.
    If ( _1_e_tableNumber <= 0) Then q4Interruptions.assertRaise(
        'DEFAULT TABLE: numéro de table invalide',
        {$I %CURRENTROUTINE%},
        {$I %LINENUM%}
        );

    q4process.ProcessState.currentTableNumber := _1_e_tableNumber;
  End;

Procedure noDefaultTable;
  Begin
    // https://developer.4d.com/docs/21/commands/no-default-table

    // 4D précise que cette commande annule DEFAULT TABLE
    // et ne fait rien si aucune table par défaut n'était définie.
    q4process.ProcessState.currentTableNumber := 0;
  End;

End.
