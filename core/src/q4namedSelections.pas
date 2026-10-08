Unit q4namedSelections;

{$mode objfpc}{$H+}

{
q4namedSelections
version du 2026/04/19-17:20

Mapping 4D → q4namedSelections -> statut
Command Number 4D,   4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
333,                 CLEAR NAMED SELECTION,            clearNamedSelection,              Partial,
331,                 COPY NAMED SELECTION,             copyNamedSelection,               Partial,
334,                 CUT NAMED SELECTION,              cutNamedSelection,                Partial,
332,                 USE NAMED SELECTION,              useNamedSelection,                Partial,

Doc: https://developer.4d.com/docs/21/commands/theme/Named-Selections
}

Interface

Uses
  q4setsAndNamedSelectionsCore;

Type
  Tq4NamedSelectionUseMode = q4setsAndNamedSelectionsCore.Tq4selectionUseMode;

Procedure clearNamedSelection( Var _1_p_recordTable; Const _2_t_name: string);
Procedure copyNamedSelection( Var _1_p_recordTable; Const _2_t_name: string);
Procedure cutNamedSelection( Var _1_p_recordTable; Const _2_t_name: string);
Procedure useNamedSelection( Var _1_p_recordTable; Const _2_t_name: string; Const _3_e_mode: Tq4NamedSelectionUseMode);

Function hasLiveNamedSelections: boolean;

Implementation

Function hasLiveNamedSelections: boolean;
  Var
    _e_i: int64;
  Begin
    Result := False;

    For _e_i := 0 To High( q4setsAndNamedSelectionsCore.ty_localSelectionAliases) Do If ( q4setsAndNamedSelectionsCore.ty_localSelectionAliases[_e_i].e_kind = qsakNamedSelection) Then Exit( True);
  End;

Procedure clearNamedSelection( Var _1_p_recordTable; Const _2_t_name: string);
  Begin
    q4setsAndNamedSelectionsCore.clearAlias( _1_p_recordTable, qsakNamedSelection, _2_t_name);
  End;

Procedure copyNamedSelection( Var _1_p_recordTable; Const _2_t_name: string);
  Begin
    q4setsAndNamedSelectionsCore.copyCurrentSelectionToAlias( _1_p_recordTable, qsakNamedSelection, _2_t_name);
  End;

Procedure cutNamedSelection( Var _1_p_recordTable; Const _2_t_name: string);
  Begin
    q4setsAndNamedSelectionsCore.cutCurrentSelectionToAlias( _1_p_recordTable, qsakNamedSelection, _2_t_name);
  End;

Procedure useNamedSelection( Var _1_p_recordTable; Const _2_t_name: string; Const _3_e_mode: Tq4NamedSelectionUseMode);
  Begin
    q4setsAndNamedSelectionsCore.useAlias( _1_p_recordTable, qsakNamedSelection, _2_t_name, _3_e_mode);
  End;

End.
