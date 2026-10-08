unit q4language;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Variants,
  q4coreLanguage;

{
q4language
version du 2026/05/14

Mapping 4D → q4language -> statut
Command Number 4D,    4D Command,                       q4 API,                           Statut
---------------------------------------------------------------------------------------------------------------
1709,                 4D,                                fourD,                            TODO
1442,                 Action info,                       actionInfo,                       Not supported UI
1662,                 Call chain,                        callChain,                        OK spécifique / debug sensible
538,                  Command name,                      commandName,                      Not supported 4D tokenizer
1790,                 Copy parameters,                   copyParameters,                   TODO
259,                  Count parameters,                  countParameters,                  OK spécifique / compatibilité transpileur
1710,                 cs,                                cs,                               TODO
684,                  Current method name,               currentMethodName,                Transpiler
1007,                 EXECUTE METHOD,                    executeMethod,                    TODO
304,                  Get pointer,                       getPointer,                       TODO
1439,                 INVOKE ACTION,                     invokeAction,                     Not supported UI
294,                  Is a variable,                     isAVariable,                      TODO
315,                  Is nil pointer,                    isNilPointer,                     TODO
1517,                 Null,                              nullValue,                        TODO
394,                  RESOLVE POINTER,                   resolvePointer,                   TODO
308,                  Self,                              selfPointer,                      Not supported UI
1706,                 Super,                             superObject,                      TODO
1470,                 This,                              this,                             TODO
157,                  TRACE,                             trace,                            OK spécifique / debug breakpoint
295,                  Type,                              typeOf,                           OK spécifique / Transpiler + TQ4Ref
82,                   Undefined,                         undefined,                        TODO PascalScript
1509,                 Value type,                        valueType,                        TODO

Doc: https://developer.4d.com/docs/21/commands/theme/Language
}

const
  { Constantes 4D du thème Field and Variable Types, utiles pour Type / Value type.
    Les valeurs ci-dessous proviennent de la documentation 4D de la commande Type. }
  IS_ALPHA_FIELD       = 0;
  IS_REAL              = 1;
  IS_TEXT              = 2;
  IS_PICTURE           = 3;
  IS_DATE              = 4;
  IS_UNDEFINED         = 5;
  IS_BOOLEAN           = 6;
  IS_SUBTABLE          = 7;
  IS_INTEGER           = 8;
  IS_LONGINT           = 9;
  IS_TIME              = 11;
  IS_VARIANT           = 12;
  ARRAY_2D             = 13;
  REAL_ARRAY           = 14;
  INTEGER_ARRAY        = 15;
  LONGINT_ARRAY        = 16;
  DATE_ARRAY           = 17;
  TEXT_ARRAY           = 18;
  PICTURE_ARRAY        = 19;
  POINTER_ARRAY        = 20;
  STRING_ARRAY         = 21;
  BOOLEAN_ARRAY        = 22;
  IS_POINTER           = 23;
  IS_STRING_VAR        = 24;
  IS_INTEGER_64_BITS   = 25;
  IS_BLOB              = 30;
  BLOB_ARRAY           = 31;
  TIME_ARRAY           = 32;
  IS_OBJECT            = 38;
  OBJECT_ARRAY         = 39;
  IS_COLLECTION        = 42;
  IS_NULL              = 255;

function fourD: string;
function actionInfo(const _1_t_action: string = ''): string;
function callChain: string;
function commandName(_1_e_command: Int64): string; overload;
function commandName(_1_e_command: Int64; out _2_e_info: Int64; out _3_t_theme: string): string; overload;
function copyParameters: string;
function countParameters(_1_e_countParameters: Int64): Int64;
function cs: string;
function currentMethodName: string;
procedure executeMethod(const _1_t_methodName: string; var _2_v_result: Variant; const _3_t_parametersJson: string = '[]');
function getPointer(const _1_t_name: string): Pointer;
procedure invokeAction(const _1_t_action: string = '');
function isAVariable(const _1_t_expression: string): Boolean;
function isNilPointer(_1_p_value: Pointer): Boolean;
function nullValue: Variant;
procedure resolvePointer(_1_p_pointer: Pointer; out _2_t_variableName: string; out _3_e_tableNum: Int64; out _4_e_fieldNum: Int64);
function selfPointer: Pointer;
function superObject: string;
function this: string;
procedure trace;
function typeOf(_1_y_valueKind: q4coreLanguage.TQ4ValueKind): Int64; overload;
function typeOfDeclared(_1_e_typeConstant: Int64): Int64;
function undefined: Boolean;
function valueType(const _1_v_value: Variant): Int64;

implementation

uses
  q4interruptions
  {$IFDEF Q4_DEBUG_TRACE}
    {$IFDEF MSWINDOWS}, Windows{$ENDIF}
    {$IFDEF UNIX}, BaseUnix{$ENDIF}
  {$ENDIF}
  ;

const
  Q4_LANGUAGE_MAX_CALLCHAIN_DEPTH = 32;

function jsonString(const _1_t_value: string): string;
begin
  Result := _1_t_value;
  Result := SysUtils.StringReplace(Result, '\', '\\', [SysUtils.rfReplaceAll]);
  Result := SysUtils.StringReplace(Result, '"', '\"', [SysUtils.rfReplaceAll]);
  Result := SysUtils.StringReplace(Result, #13, '\r', [SysUtils.rfReplaceAll]);
  Result := SysUtils.StringReplace(Result, #10, '\n', [SysUtils.rfReplaceAll]);
  Result := SysUtils.StringReplace(Result, #9, '\t', [SysUtils.rfReplaceAll]);
  Result := '"' + Result + '"';
end;

{$IFDEF Q4_DEBUG_CALLCHAIN}
function nativeCallChainJSON: string;
type
  TQ4BacktraceArray = array[0..Q4_LANGUAGE_MAX_CALLCHAIN_DEPTH - 1] of CodePointer;
var
  _ty_frames: TQ4BacktraceArray;
  _e_count: LongInt;
  _e_i: LongInt;
  _t_frame: string;
begin
  _e_count := System.CaptureBacktrace(1, Q4_LANGUAGE_MAX_CALLCHAIN_DEPTH, @_ty_frames[0]);

  Result := '[';
  for _e_i := 0 to _e_count - 1 do
  begin
    if (_e_i > 0) then
      Result := Result + ',';

    if (System.Assigned(System.BackTraceStrFunc)) then
      _t_frame := System.BackTraceStrFunc(_ty_frames[_e_i])
    else
      _t_frame := '$' + SysUtils.IntToHex(PtrUInt(_ty_frames[_e_i]), System.SizeOf(Pointer) * 2);

    Result := Result
      + '{'
      + '"type":"native",'
      + '"name":' + jsonString(_t_frame) + ','
      + '"line":0,'
      + '"database":"q4"'
      + '}';
  end;
  Result := Result + ']';
end;
{$ENDIF}

procedure raiseTodo(const _1_t_command: string; const _2_t_details: string = '');
var
  _t_message: string;
begin
  _t_message := _1_t_command + ' is TODO in q4language.';
  if (_2_t_details <> '') then
    _t_message := _t_message + ' ' + _2_t_details;

  q4interruptions.assertRaise(_t_message, {$I %CURRENTROUTINE%}, {$I %LINENUM%});
end;

procedure raiseUnsupported(const _1_t_command: string; const _2_t_reason: string);
begin
  q4interruptions.assertRaise(
    _1_t_command + ' is not supported in q4language. ' + _2_t_reason,
    {$I %CURRENTROUTINE%},
    {$I %LINENUM%}
  );
end;

function fourD: string;
begin
  //https://developer.4d.com/docs/21/commands/4d
  // q4 TODO : 4D est traité comme mot-clé du modèle de classes 4D.
  // q4 doit d'abord stabiliser son modèle classes/objets avant de figer
  // l'équivalent de 4D dans q4language.
  raiseTodo('4D', 'Class keyword not implemented yet.');
  Result := '{}';
end;

function actionInfo(const _1_t_action: string = ''): string;
begin
  //https://developer.4d.com/docs/21/commands/action-info
  // q4 : commande liée au runtime UI/formulaire 4D.
  // Non supportée tant que q4 ne porte pas le modèle UI 4D dans Lazarus.
  raiseUnsupported('Action info', '4D UI/form runtime is not implemented.');
  Result := '{}';
end;

function callChain: string;
begin
  //https://developer.4d.com/docs/21/commands/call-chain
  // Sécurité q4 : cette commande peut exposer des informations internes utiles
  // à un attaquant : noms d'unités, noms de routines, chemins de fichiers,
  // numéros de lignes, structure interne de l'application.
  //
  // En 4D, Call chain dépend déjà d'informations runtime/compiler disponibles
  // uniquement sous certaines conditions, notamment le Range checking en mode
  // compilé. En q4, l'implémentation détaillée s'appuie sur la pile native
  // FPC/Lazarus. Pour obtenir des noms de routines et des lignes exploitables,
  // compiler avec les informations debug/backtrace appropriées, notamment
  // -gl / lineinfo.
  //
  // Recommandation :
  // - développement : Q4_DEBUG_CALLCHAIN peut être défini ;
  // - production interne : limiter l'accès ou réserver aux logs protégés ;
  // - production publique : désactiver ou filtrer fortement le résultat, et
  //   éviter les symboles debug embarqués dans le binaire distribué.
  {$IFDEF Q4_DEBUG_CALLCHAIN}
  Result := nativeCallChainJSON;
  {$ELSE}
  Result := '[]';
  {$ENDIF}
end;

function commandName(_1_e_command: Int64): string;
var
  _e_info: Int64;
  _t_theme: string;
begin
  //https://developer.4d.com/docs/21/commands/command-name
  Result := commandName(_1_e_command, _e_info, _t_theme);
end;

function commandName(_1_e_command: Int64; out _2_e_info: Int64; out _3_t_theme: string): string;
begin
  //https://developer.4d.com/docs/21/commands/command-name
  // q4 : commande non supportée.
  // 4D dispose d'un catalogue interne de commandes numérotées/tokenisées.
  // Lazarus/FPC ne fournit pas d'équivalent runtime pour les commandes q4.
  // q4 ne maintient donc pas de table globale exhaustive des commandes 4D.
  q4coreLanguage.OK := 0;
  _2_e_info := 0;
  _3_t_theme := '';
  Result := '';
end;

function copyParameters: string;
begin
  //https://developer.4d.com/docs/21/commands/copy-parameters
  // q4 TODO : commande surtout utile au style dynamique 4D pour transférer
  // une liste variable de paramètres. En q4/FPC maintenu manuellement,
  // préférer des signatures explicites ou des records typés.
  raiseTodo('Copy parameters', 'Requires a dedicated parameter passing strategy.');
  Result := '[]';
end;

function countParameters(_1_e_countParameters: Int64): Int64;
begin
  //https://developer.4d.com/docs/21/commands/count-parameters
  // q4 : dans le code maintenu manuellement, préférer des signatures
  // explicites et éviter Count parameters.
  //
  // Pour compatibilité avec du code 4D non réécrit, le transpileur peut ajouter
  // un dernier paramètre technique p0_e_countParameters indiquant le nombre réel
  // de paramètres 4D passés à la méthode.
  Result := _1_e_countParameters;
end;

function cs: string;
begin
  //https://developer.4d.com/docs/21/commands/cs
  // q4 TODO : cs est traité comme mot-clé du modèle de classes 4D.
  // q4 doit d'abord stabiliser son modèle classes/objets avant de figer
  // l'équivalent de cs dans q4language.
  raiseTodo('cs', 'Class keyword not implemented yet.');
  Result := '{}';
end;

function currentMethodName: string;
begin
  //https://developer.4d.com/docs/21/commands/current-method-name
  // q4 : cette commande est une instruction de transpilation.
  // Elle doit être remplacée au point d'appel par :
  //
  //   {$I %CURRENTROUTINE%}
  //
  // Une fonction runtime retournerait seulement le nom de
  // q4language.currentMethodName, ce qui serait trompeur.
  q4interruptions.assertRaise(
    'Current method name must be replaced by the transpiler using {$I %CURRENTROUTINE%}.',
    {$I %CURRENTROUTINE%},
    {$I %LINENUM%}
  );
  Result := '';
end;

procedure executeMethod(const _1_t_methodName: string; var _2_v_result: Variant; const _3_t_parametersJson: string = '[]');
begin
  //https://developer.4d.com/docs/21/commands/execute-method
  // q4 TODO : EXECUTE METHOD demande une stratégie dédiée.
  // La commande 4D permet d'appeler dynamiquement une méthode projet par son nom.
  // Avec de nombreux usages, une unité générée de type q4methodRegistry pourrait
  // être envisagée, mais cela touche au modèle global d'appel, aux paramètres,
  // aux retours et aux dépendances entre unités.
  _2_v_result := Variants.Unassigned;
  raiseTodo('EXECUTE METHOD', 'Dynamic method registry strategy not defined yet.');
end;

function getPointer(const _1_t_name: string): Pointer;
begin
  //https://developer.4d.com/docs/21/commands/get-pointer
  // q4 TODO : Get pointer demande une analyse dédiée.
  // 4D retourne un pointeur à partir d'un nom de variable, tableau, champ,
  // table ou expression d'élément de tableau.
  //
  // En q4/FPC, il faut distinguer :
  // - les pointeurs Pascal réels (@variable, PString, PInteger, etc.) ;
  // - les références typées TQ4Ref ;
  // - les cas qui n'ont pas d'équivalent direct en Pascal compilé, notamment
  //   la résolution dynamique d'une variable par son nom.
  raiseTodo('Get pointer', 'Pointer/reference model not stabilized yet.');
  Result := nil;
end;

procedure invokeAction(const _1_t_action: string = '');
begin
  //https://developer.4d.com/docs/21/commands/invoke-action
  // q4 : commande liée au runtime UI/formulaire 4D.
  // Non supportée tant que q4 ne porte pas le modèle UI 4D dans Lazarus.
  raiseUnsupported('INVOKE ACTION', '4D UI/form runtime is not implemented.');
end;

function isAVariable(const _1_t_expression: string): Boolean;
begin
  //https://developer.4d.com/docs/21/commands/is-a-variable
  // q4 TODO : Is a variable demande une analyse dédiée.
  // 4D peut tester dynamiquement si une expression est une variable.
  // En Pascal/FPC compilé, une variable inconnue provoque une erreur de
  // compilation et ne peut pas être testée à l'exécution.
  //
  // Une compatibilité future pourrait passer par PascalScript, un registre
  // explicite de symboles, ou une intégration avec TQ4Ref selon les cas.
  raiseTodo('Is a variable', 'Runtime symbol lookup is not available in compiled q4.');
  Result := False;
end;

function isNilPointer(_1_p_value: Pointer): Boolean;
begin
  //https://developer.4d.com/docs/21/commands/is-nil-pointer
  // q4 TODO : Is nil pointer demande une analyse détaillée.
  // 4D distingue les pointeurs nil, les pointeurs valides, les références vers
  // objets/formulaires/champs/tableaux, etc.
  // q4 utilise actuellement des pointeurs Pascal et des références TQ4Ref.
  // Le comportement doit être précisé pour Pointer, PString/PInteger/etc.,
  // TQ4Ref, et éventuellement les cas UI non supportés.
  raiseTodo('Is nil pointer', 'Null/nil/reference semantics not stabilized yet.');
  Result := _1_p_value = nil;
end;

function nullValue: Variant;
begin
  //https://developer.4d.com/docs/21/commands/null
  // q4 TODO : Null demande une analyse détaillée.
  // 4D utilise Null comme valeur affectable et comparable, notamment avec
  // objets, collections, variants, pointeurs et pictures.
  // En q4/FPC, plusieurs notions proches existent mais ne sont pas équivalentes :
  // - Variants.Null pour les Variant ;
  // - nil pour les pointeurs/classes/interfaces ;
  // - 'null' pour les valeurs JSON ;
  // - TQ4Ref.ValueKind = q4vkNull si un tel état est ajouté aux références.
  raiseTodo('Null', 'Null semantics not stabilized yet.');
  Result := Variants.Null;
end;

procedure resolvePointer(_1_p_pointer: Pointer; out _2_t_variableName: string; out _3_e_tableNum: Int64; out _4_e_fieldNum: Int64);
begin
  //https://developer.4d.com/docs/21/commands/resolve-pointer
  // q4 TODO : q4language.resolvePointer est le point d'entrée générique.
  // Il doit être utilisé quand le transpileur ne sait pas statiquement si la
  // référence reçue désigne une variable, un tableau, une table, un champ ou
  // un autre type de cible.
  //
  // Un Pointer Pascal brut ne suffit pas à résoudre cette information.
  // La fonction devra donc probablement travailler sur un record q4 enrichi
  // portant Ptr, TargetKind, ValueKind et les métadonnées de résolution utiles.
  _2_t_variableName := '';
  _3_e_tableNum := 0;
  _4_e_fieldNum := 0;
  raiseTodo('RESOLVE POINTER', 'Generic pointer/reference resolution not stabilized yet.');
end;

function selfPointer: Pointer;
begin
  //https://developer.4d.com/docs/21/commands/self
  // q4 : commande liée au runtime UI/formulaire 4D.
  // Self retourne en 4D un pointeur vers l'objet de formulaire courant.
  // q4 ne porte pas actuellement le modèle UI 4D dans Lazarus ; l'interface q4
  // passe pour l'instant par HTML/JS.
  raiseUnsupported('Self', '4D UI/form runtime is not implemented.');
  Result := nil;
end;

function superObject: string;
begin
  //https://developer.4d.com/docs/21/commands/super
  // q4 TODO : Super demande une analyse dédiée.
  // En 4D, Super dépend du modèle de classes et permet soit d'appeler le
  // constructeur de la superclasse, soit d'accéder au prototype de la
  // superclasse dans une fonction de classe.
  raiseTodo('Super', 'Class/object model not stabilized yet.');
  Result := '{}';
end;

function this: string;
begin
  //https://developer.4d.com/docs/21/commands/this
  // q4 TODO : This demande une analyse dédiée.
  // En 4D, This dépend du contexte courant : fonction de classe, formula object,
  // list box, événement ou autre contexte objet. q4 doit d'abord stabiliser son
  // modèle objets/classes/collections avant de figer cette commande.
  raiseTodo('This', 'Object/class context model not stabilized yet.');
  Result := '{}';
end;

procedure trace;
begin
  //https://developer.4d.com/docs/21/commands/trace
  // q4 : équivalent de développement de la commande 4D TRACE.
  // En 4D compilé, TRACE ne fait rien. En q4, l'équivalent naturel est de
  // provoquer un arrêt debugger lorsque l'application est lancée en mode debug
  // sous Lazarus/FPC.
  //
  // Attention :
  // - cette commande doit rester réservée au debug ;
  // - si aucun debugger n'est attaché, un breakpoint système peut interrompre
  //   ou terminer l'application selon l'OS ;
  // - en production, Q4_DEBUG_TRACE ne doit pas être défini.
  {$IFDEF Q4_DEBUG_TRACE}
    {$IFDEF MSWINDOWS}
    Windows.DebugBreak;
    {$ENDIF}
    {$IFDEF UNIX}
    BaseUnix.fpKill(BaseUnix.fpGetpid, BaseUnix.SIGTRAP);
    {$ENDIF}
  {$ENDIF}
end;

function typeOf(_1_y_valueKind: q4coreLanguage.TQ4ValueKind): Int64;
begin
  //https://developer.4d.com/docs/21/commands/type
  // q4 : Type est résolu selon deux chemins.
  //
  // 1) Variable connue au point d'appel : le transpileur remplace Type(...)
  //    par la constante q4 correspondant au type déclaré connu.
  //
  // 2) Référence/pointeur transmis en paramètre : le type est lu dans
  //    TQ4Ref.ValueKind, puis converti vers la constante Type compatible par
  //    cette fonction. q4language ne dépend pas de q4ref afin d'éviter les
  //    dépendances circulaires.
  case _1_y_valueKind of
    q4coreLanguage.q4vkInteger:    Result := IS_INTEGER;
    q4coreLanguage.q4vkInt64:      Result := IS_INTEGER_64_BITS;
    q4coreLanguage.q4vkReal:       Result := IS_REAL;
    q4coreLanguage.q4vkBoolean:    Result := IS_BOOLEAN;
    q4coreLanguage.q4vkText:       Result := IS_TEXT;
    q4coreLanguage.q4vkDate:       Result := IS_DATE;
    q4coreLanguage.q4vkTime:       Result := IS_TIME;
    q4coreLanguage.q4vkObject:     Result := IS_OBJECT;
    q4coreLanguage.q4vkCollection: Result := IS_COLLECTION;
    q4coreLanguage.q4vkBlob:       Result := IS_BLOB;
    q4coreLanguage.q4vkPicture:    Result := IS_PICTURE;
    q4coreLanguage.q4vkPointer:    Result := IS_POINTER;
    q4coreLanguage.q4vkVariant:    Result := IS_VARIANT;
  else
    Result := IS_UNDEFINED;
  end;
end;

function typeOfDeclared(_1_e_typeConstant: Int64): Int64;
begin
  //https://developer.4d.com/docs/21/commands/type
  // q4 : helper simple pour les cas où le transpileur connaît déjà la constante
  // Type 4D/q4 à utiliser au point d'appel.
  Result := _1_e_typeConstant;
end;

function undefined: Boolean;
begin
  //https://developer.4d.com/docs/21/commands/undefined
  // q4 compilé FPC/Lazarus : non implémentable comme test général de variable
  // à l'exécution. En Pascal compilé, une variable inexistante provoque une
  // erreur de compilation : elle ne peut donc pas être testée par une fonction
  // runtime.
  //
  // TODO PascalScript : si q4 ajoute un mode d'exécution PascalScript,
  // Undefined pourra être simulé en testant l'existence d'un symbole dans le
  // moteur de script, à condition que le transpileur transmette le nom de la
  // variable sous forme de chaîne.
  raiseTodo('Undefined', 'TODO PascalScript runtime symbol lookup.');
  Result := False;
end;

function valueType(const _1_v_value: Variant): Int64;
begin
  //https://developer.4d.com/docs/21/commands/value-type
  // q4 TODO : Value type doit être repris après stabilisation du modèle
  // objets/collections q4.
  // 4D distingue Type, qui décrit le type déclaré d'une variable/champ, et
  // Value type, qui décrit le type de la valeur évaluée, notamment pour les
  // propriétés d'objets et les éléments de collections.
  raiseTodo('Value type', 'Object/collection runtime model not stabilized yet.');
  Result := IS_UNDEFINED;
end;

end.
