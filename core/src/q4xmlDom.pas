unit q4xmlDom;

{
q4xmlDom
version du 2026/04/18-17:58

Mapping 4D
Command Number 4D,   4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
1080,                DOM Append XML child node,        DOMAppendXMLChildNode,           OK,
1082,                DOM Append XML element,           DOMAppendXMLElement,             OK,
722,                 DOM CLOSE XML,                    DOMCloseXML,                     OK,
727,                 DOM Count XML attributes,         DOMCountXMLAttributes,           OK,
726,                 DOM Count XML elements,           DOMCountXMLElements,             OK,
865,                 DOM Create XML element,           DOMCreateXMLElement,             Partial,
1097,                DOM Create XML element arrays,    DOMCreateXMLElementArrays,       Partial,
861,                 DOM Create XML Ref,               DOMCreateXMLRef,                 Partial,
862,                 DOM EXPORT TO FILE,               DOMExportToFile,                 OK,
863,                 DOM EXPORT TO VAR,                DOMExportToVar,                  OK,
864,                 DOM Find XML element,             DOMFindXMLElement,               Partial,
1010,                DOM Find XML element by ID,       DOMFindXMLElementByID,           OK,
723,                 DOM Get first child XML element,  DOMGetFirstChildXMLElement,      OK,
925,                 DOM Get last child XML element,   DOMGetLastChildXMLElement,       OK,
724,                 DOM Get next sibling XML element, DOMGetNextSiblingXMLElement,     OK,
923,                 DOM Get parent XML element,       DOMGetParentXMLElement,          OK,
924,                 DOM Get previous sibling XML element, DOMGetPreviousSiblingXMLElement, OK,
1053,                DOM Get root XML element,         DOMGetRootXMLElement,            OK,
729,                 DOM GET XML ATTRIBUTE BY INDEX,   DOMGetXMLAttributeByIndex,       OK,
728,                 DOM GET XML ATTRIBUTE BY NAME,    DOMGetXMLAttributeByName,        OK,
1081,                DOM GET XML CHILD NODES,          DOMGetXMLChildNodes,             Partial,
1088,                DOM Get XML document ref,         DOMGetXMLDocumentRef,            Partial,
725,                 DOM Get XML element,              DOMGetXMLElement,                Partial,
730,                 DOM GET XML ELEMENT NAME,         DOMGetXMLElementName,            OK,
731,                 DOM GET XML ELEMENT VALUE,        DOMGetXMLElementValue,           OK,
721,                 DOM Get XML information,          DOMGetXMLInformation,            Partial,
1083,                DOM Insert XML element,           DOMInsertXMLElement,             OK,
719,                 DOM Parse XML source,             DOMParseXMLSource,               Partial,
720,                 DOM Parse XML variable,           DOMParseXMLVariable,             Partial,
1084,                DOM REMOVE XML ATTRIBUTE,         DOMRemoveXMLAttribute,           OK,
869,                 DOM REMOVE XML ELEMENT,           DOMRemoveXMLElement,             OK,
866,                 DOM SET XML ATTRIBUTE,            DOMSetXMLAttribute,              Partial,
859,                 DOM SET XML DECLARATION,          DOMSetXMLDeclaration,            Partial,
867,                 DOM SET XML ELEMENT NAME,         DOMSetXMLElementName,            OK,
868,                 DOM SET XML ELEMENT VALUE,        DOMSetXMLElementValue,           Partial,

Doc: https://developer.4d.com/docs/21/commands/theme/XML-DOM

  Dépendances : XMLRead, XMLWrite, DOM, XPath (package XML standard FPC)
  uses XMLRead, XMLWrite, DOM, XPath dans l'interface.

  Conventions :
    - Les noms 4D "DOM Xxx Yyy Zzz" deviennent "DOMXxxYyyZzz" (camelCase).
    - Les paramètres alternatifs Text|Blob sont exposés via overload.
    - Les paramètres de type Variable 4D sont exposés en Variant.
    - Les références d'éléments (elementRef) sont des String opaques (handle
      hexadécimal) pointant vers des TDOMNode stockés dans une table de hachage
      interne (GNodeMap).

  Variable publique :
    OK : Integer  (1 = succès, 0 = erreur) — positionné par les méthodes
                       qui positionnent OK selon la doc 4D.

  Gestion des erreurs :
    Quand la doc 4D indique qu'une erreur est levée, une exception EQ4XMLError
    est levée.

  Notes d'implémentation :
    - Les variantes "répétables" de la doc 4D (attributs/namespaces multiples)
      sont ici couvertes partiellement par quelques overloads dédiés.
    - Les sorties en tableaux dépendent de la taille des tableaux fournis par
      l'appelant ; elles ne sont pas redimensionnées automatiquement.
    - Le parsing avec DTD/XSD externe n'est pas implémenté au niveau FPC standard.
    - DOMSetXMLDeclaration mémorise certains choix d'export dans des tables
      internes, ce qui rend plusieurs commandes partiellement équivalentes à 4D.

  Constantes XML (équivalents des constantes 4D dans le thème "XML") :
    XML_DATA, XML_CDATA, XML_COMMENT, XML_PROCESSING_INSTRUCTION,
    XML_DOCTYPE, XML_ELEMENT
    XML_INFO_PUBLIC_ID, XML_INFO_SYSTEM_ID, XML_INFO_DOCTYPE_NAME,
    XML_INFO_ENCODING, XML_INFO_VERSION, XML_INFO_DOCUMENT_URI
}

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Variants, FGL, base64,
  XMLRead, XMLWrite, DOM, XPath, q4coreLanguage;

{ ============================================================
  Constantes publiques
  ============================================================ }

const
  { Types de nœuds enfants (childType dans DOMAppendXMLChildNode) }
  XML_COMMENT = 2;
  XML_PROCESSING_INSTRUCTION = 3;
  XML_DATA = 6;
  XML_CDATA = 7;
  XML_DOCTYPE = 10;
  XML_ELEMENT = 11;

  { Codes pour DOMGetXMLInformation }
  XML_INFO_PUBLIC_ID = 1;
  XML_INFO_SYSTEM_ID = 2;
  XML_INFO_DOCTYPE_NAME = 3;
  XML_INFO_ENCODING = 4;
  XML_INFO_VERSION = 5;
  XML_INFO_DOCUMENT_URI = 6;

{ ============================================================
  Variable publique d'état
  ============================================================ }

var
  OK: Int64;

{ ============================================================
  Exception
  ============================================================ }

type
  EQ4XMLError = class(Exception);

{ ============================================================
  Déclarations des fonctions/procédures
  ============================================================ }

{ --- DOM Append XML child node --- }
function DOMAppendXMLChildNode(const _1_t_elementRef: string; _2_e_childType: Int64; const _3_t_childValue: string): string; overload;
function DOMAppendXMLChildNode(const _1_t_elementRef: string; _2_e_childType: Int64; const _3_by_childValue: TBytes): string; overload;

{ --- DOM Append XML element --- }
function DOMAppendXMLElement(const _1_t_targetElementRef: string; const _2_t_sourceElementRef: string): string;

{ --- DOM CLOSE XML --- }
procedure DOMCloseXML(const _1_t_elementRef: string);

{ --- DOM Count XML attributes --- }
function DOMCountXMLAttributes(const _1_t_elementRef: string): Int64;

{ --- DOM Count XML elements --- }
function DOMCountXMLElements(const _1_t_elementRef: string; const _2_t_elementName: string): Int64;

{ --- DOM Create XML element (avec ou sans attribut) --- }
function DOMCreateXMLElement(const _1_t_elementRef: string; const _2_t_xPath: string): string; overload;
function DOMCreateXMLElement(const _1_t_elementRef: string; const _2_t_xPath: string; const _3_t_attribName: string;
  const _4_y_attrValue: variant): string; overload;

{ --- DOM Create XML element arrays --- }
function DOMCreateXMLElementArrays(const _1_t_elementRef: string; const _2_t_xPath: string;
  const _3_tt_attribNamesArray: array of string; const _4_tt_attribValuesArray: array of string): string;

{ --- DOM Create XML Ref (sans ou avec namespace) --- }
function DOMCreateXMLRef(const _1_t_root: string): string; overload;
function DOMCreateXMLRef(const _1_t_root: string; const _2_t_nameSpace: string): string; overload;
function DOMCreateXMLRef(const _1_t_root: string; const _2_t_nameSpaceName: string; const _3_t_nameSpaceValue: string): string; overload;

{ --- DOM EXPORT TO FILE --- }
procedure DOMExportToFile(const _1_t_elementRef: string; const _2_t_filePath: string);

{ --- DOM EXPORT TO VAR (résultat texte ou blob) --- }
procedure DOMExportToVar(const _1_t_elementRef: string; out _2_t_vXmlVar: string); overload;
procedure DOMExportToVar(const _1_t_elementRef: string; out _2_by_vXmlVar: TBytes); overload;

{ --- DOM Find XML element --- }
function DOMFindXMLElement(const _1_t_elementRef: string; const _2_t_xPath: string): string; overload;
function DOMFindXMLElement(const _1_t_elementRef: string; const _2_t_xPath: string; out _3_tt_arrElementRefs: array of string): string;
  overload;

{ --- DOM Find XML element by ID --- }
function DOMFindXMLElementByID(const _1_t_elementRef: string; const _2_t_id: string): string;

{ --- DOM Get first child XML element (formes avec ou sans paramètres optionnels) --- }
function DOMGetFirstChildXMLElement(const _1_t_elementRef: string): string; overload;
function DOMGetFirstChildXMLElement(const _1_t_elementRef: string; out _2_t_childElemName: string): string; overload;
function DOMGetFirstChildXMLElement(const _1_t_elementRef: string; out _2_t_childElemName: string; out _3_t_childElemValue: string): string;
  overload;

{ --- DOM Get last child XML element --- }
function DOMGetLastChildXMLElement(const _1_t_elementRef: string): string; overload;
function DOMGetLastChildXMLElement(const _1_t_elementRef: string; out _2_t_childElemName: string): string; overload;
function DOMGetLastChildXMLElement(const _1_t_elementRef: string; out _2_t_childElemName: string; out _3_t_childElemValue: string): string;
  overload;

{ --- DOM Get next sibling XML element --- }
function DOMGetNextSiblingXMLElement(const _1_t_elementRef: string): string; overload;
function DOMGetNextSiblingXMLElement(const _1_t_elementRef: string; out _2_t_siblingElemName: string): string; overload;
function DOMGetNextSiblingXMLElement(const _1_t_elementRef: string; out _2_t_siblingElemName: string;
  out _3_t_siblingElemValue: string): string; overload;

{ --- DOM Get parent XML element --- }
function DOMGetParentXMLElement(const _1_t_elementRef: string): string; overload;
function DOMGetParentXMLElement(const _1_t_elementRef: string; out _2_t_parentElemName: string): string; overload;
function DOMGetParentXMLElement(const _1_t_elementRef: string; out _2_t_parentElemName: string; out _3_t_parentElemValue: string): string;
  overload;

{ --- DOM Get previous sibling XML element --- }
function DOMGetPreviousSiblingXMLElement(const _1_t_elementRef: string): string; overload;
function DOMGetPreviousSiblingXMLElement(const _1_t_elementRef: string; out _2_t_siblingElemName: string): string; overload;
function DOMGetPreviousSiblingXMLElement(const _1_t_elementRef: string; out _2_t_siblingElemName: string;
  out _3_t_siblingElemValue: string): string; overload;

{ --- DOM Get root XML element --- }
function DOMGetRootXMLElement(const _1_t_elementRef: string): string;

{ --- DOM GET XML ATTRIBUTE BY INDEX --- }
procedure DOMGetXMLAttributeByIndex(const _1_t_elementRef: string; _2_e_attribIndex: Int64; out _3_y_attribName: variant;
  out _4_y_attribValue: variant);

{ --- DOM GET XML ATTRIBUTE BY NAME --- }
procedure DOMGetXMLAttributeByName(const _1_t_elementRef: string; const _2_t_attribName: string; out _3_y_attribValue: variant);

{ --- DOM GET XML CHILD NODES --- }
procedure DOMGetXMLChildNodes(const _1_t_elementRef: string; out _2_te_childTypesArr: array of integer; out _3_tt_nodeRefsArr: array of string);

{ --- DOM Get XML document ref --- }
function DOMGetXMLDocumentRef(const _1_t_elementRef: string): string;

{ --- DOM Get XML element --- }
function DOMGetXMLElement(const _1_t_elementRef: string; const _2_t_elementName: string; _3_e_index: Int64): string; overload;
function DOMGetXMLElement(const _1_t_elementRef: string; const _2_t_elementName: string; _3_e_index: Int64;
  out _4_y_elementValue: variant): string; overload;
function DOMGetXMLElement(const _1_t_elementRef: string; const _2_t_elementName: string; _3_e_index: Int64;
  out _4_y_elementValue: variant; out _5_tt_attrNames: array of string; out _6_tt_attrValues: array of string): string; overload;

{ --- DOM GET XML ELEMENT NAME --- }
procedure DOMGetXMLElementName(const _1_t_elementRef: string; out _2_y_elementName: variant);

{ --- DOM GET XML ELEMENT VALUE --- }
procedure DOMGetXMLElementValue(const _1_t_elementRef: string; out _2_y_elementValue: variant); overload;
procedure DOMGetXMLElementValue(const _1_t_elementRef: string; out _2_y_elementValue: variant; out _3_y_cDATA: variant); overload;

{ --- DOM Get XML information --- }
function DOMGetXMLInformation(const _1_t_elementRef: string; _2_e_xmlInfo: Int64): string;

{ --- DOM Insert XML element --- }
function DOMInsertXMLElement(const _1_t_targetElementRef: string; const _2_t_sourceElementRef: string; _3_e_childIndex: Int64): string;

{ --- DOM Parse XML source --- }
function DOMParseXMLSource(const _1_t_document: string): string; overload;
function DOMParseXMLSource(const _1_t_document: string; _2_b_validation: boolean): string; overload;
function DOMParseXMLSource(const _1_t_document: string; _2_b_validation: boolean; const _3_t_dtdOrSchema: string): string; overload;

{ --- DOM Parse XML variable (depuis String ou TBytes) --- }
function DOMParseXMLVariable(const _1_t_variable: string): string; overload;
function DOMParseXMLVariable(const _1_t_variable: string; _2_b_validation: boolean): string; overload;
function DOMParseXMLVariable(const _1_t_variable: string; _2_b_validation: boolean; const _3_t_dtdOrSchema: string): string; overload;
function DOMParseXMLVariable(const _1_by_variable: TBytes): string; overload;
function DOMParseXMLVariable(const _1_by_variable: TBytes; _2_b_validation: boolean): string; overload;
function DOMParseXMLVariable(const _1_by_variable: TBytes; _2_b_validation: boolean; const _3_t_dtdOrSchema: string): string; overload;

{ --- DOM REMOVE XML ATTRIBUTE --- }
procedure DOMRemoveXMLAttribute(const _1_t_elementRef: string; const _2_t_attribName: string);

{ --- DOM REMOVE XML ELEMENT --- }
procedure DOMRemoveXMLElement(const _1_t_elementRef: string);

{ --- DOM SET XML ATTRIBUTE --- }
procedure DOMSetXMLAttribute(const _1_t_elementRef: string; const _2_t_attribName: string; const _3_y_attrValue: variant);

{ --- DOM SET XML DECLARATION --- }
procedure DOMSetXMLDeclaration(const _1_t_elementRef: string; const _2_t_encoding: string); overload;
procedure DOMSetXMLDeclaration(const _1_t_elementRef: string; const _2_t_encoding: string; _3_b_standalone: boolean); overload;
procedure DOMSetXMLDeclaration(const _1_t_elementRef: string; const _2_t_encoding: string; _3_b_standalone: boolean;
  _4_b_indentation: boolean); overload;

{ --- DOM SET XML ELEMENT NAME --- }
procedure DOMSetXMLElementName(const _1_t_elementRef: string; const _2_t_elementName: string);

{ --- DOM SET XML ELEMENT VALUE --- }
procedure DOMSetXMLElementValue(const _1_t_elementRef: string; const _2_y_elementValue: variant); overload;
procedure DOMSetXMLElementValue(const _1_t_elementRef: string; const _2_t_xPath: string; const _3_y_elementValue: variant); overload;
{ Variante avec * (écriture en CDATA) }
procedure DOMSetXMLElementValueCDATA(const _1_t_elementRef: string; const _2_y_elementValue: variant); overload;
procedure DOMSetXMLElementValueCDATA(const _1_t_elementRef: string; const _2_t_xPath: string; const _3_y_elementValue: variant); overload;

implementation

{ ============================================================
  Table de hachage interne : String (handle hex) <-> TDOMNode
  Chaque handle est une représentation hexadécimale du pointeur
  vers le TDOMNode correspondant.
  Les documents (TXMLDocument) sont référencés via leur nœud racine.
  TXMLDocument.XMLEncoding est en lecture seule dans le DOM FPC
  (elle reflète l'encodage du document parsé). L'encodage cible
  pour l'export est mémorisé dans GDocEncoding.
  ============================================================ }

type
  TNodeHandleMap = specialize TFPGMap<string, TDOMNode>;
  TDocHandleMap = specialize TFPGMap<string, TXMLDocument>;
  TStringHandleMap = specialize TFPGMap<string, string>;

var
  GNodeMap: TNodeHandleMap;
  GDocMap: TDocHandleMap;
  GDocEncoding: TStringHandleMap;  { handle -> encodage cible pour l'export }
  GDocIndent: TStringHandleMap;  { handle -> 'yes' si indentation demandée }

{ ============================================================
  Fonctions internes de gestion des handles
  ============================================================ }

function NodeToHandle(_1_o_node: TDOMNode): string;
begin
  Result := IntToHex(PtrUInt(_1_o_node), 16);
end;

function HandleToNode(const _1_t_handle: string): TDOMNode;
var
  idx: Int64;
begin
  idx := GNodeMap.IndexOf(_1_t_handle);
  if (idx < 0) then raise EQ4XMLError.CreateFmt('Handle XML invalide : %s', [_1_t_handle]);
  Result := GNodeMap.Data[idx];
end;

function HandleToElement(const _1_t_handle: string): TDOMElement;
var
  node: TDOMNode;
begin
  node := HandleToNode(_1_t_handle);
  if (not (node is TDOMElement)) then raise EQ4XMLError.CreateFmt('Le handle %s ne désigne pas un élément XML', [_1_t_handle]);
  Result := TDOMElement(node);
end;

function RegisterNode(_1_o_node: TDOMNode; _2_o_doc: TXMLDocument): string;
var
  handle: string;
  idx: Int64;
begin
  handle := NodeToHandle(_1_o_node);
  { Enregistre le nœud s'il n'est pas déjà connu }
  if (GNodeMap.IndexOf(handle) < 0) then GNodeMap.Add(handle, _1_o_node);
  { Enregistre le document associé au handle du nœud }
  idx := GDocMap.IndexOf(handle);
  if (idx < 0) then GDocMap.Add(handle, _2_o_doc)
  else
    GDocMap.Data[idx] := _2_o_doc;
  Result := handle;
end;

function GetDocForHandle(const _1_t_handle: string): TXMLDocument;
var
  idx: Int64;
begin
  idx := GDocMap.IndexOf(_1_t_handle);
  if (idx < 0) then raise EQ4XMLError.CreateFmt('Aucun document XML associé au handle %s', [_1_t_handle]);
  Result := GDocMap.Data[idx];
end;

{ Retrouve le document racine depuis n'importe quel nœud }
function GetOwnerDoc(_1_o_node: TDOMNode): TXMLDocument;
begin
  if (_1_o_node is TXMLDocument) then Result := TXMLDocument(_1_o_node)
  else
    Result := TXMLDocument(_1_o_node.OwnerDocument);
end;

{ Résout un XPath relatif à un nœud de référence.
  Retourne le premier nœud trouvé, ou nil si aucun. }
function ResolveXPath(_1_o_baseNode: TDOMNode; const _2_t_xPathExpr: string): TDOMNode;
var
  xpResult: TXPathVariable;
  nodeSet: TNodeSet;
begin
  Result := nil;
  xpResult := EvaluateXPathExpression(DOMString(_2_t_xPathExpr), _1_o_baseNode);
  try
    if (xpResult.AsNodeSet.Count > 0) then begin
      nodeSet := xpResult.AsNodeSet;
      Result := TDOMNode(nodeSet[0]);
    end;
  finally
    xpResult.Free;
  end;
end;

{ Convertit une valeur Variant en String selon les règles 4D.
  Le séparateur décimal est toujours "." conformément à la spec XML/4D,
  indépendamment de la locale système. }
function VariantToXMLString(const _1_y_v: variant): string;
var
  fs: TFormatSettings;
begin
  case VarType(_1_y_v) of
    varBoolean: if (boolean(_1_y_v)) then Result := 'true'
      else
        Result := 'false';
    varSmallInt,
    varInteger,
    varShortInt,
    varByte,
    varWord,
    varLongWord,
    // varInt64    : Result := IntToStr(Integer(v));
    varInt64: Result := IntToStr(int64(_1_y_v));
    varSingle,
    varDouble,
    varCurrency: begin
      fs := DefaultFormatSettings;
      fs.DecimalSeparator := '.';
      fs.ThousandSeparator := #0;
      Result := FloatToStrF(double(_1_y_v), ffGeneral, 15, 0, fs);
    end;
    else Result := VarToStr(_1_y_v);
  end;
end;

{ Encode des données binaires en base64 }
function BytesToBase64(const _1_by_data: TBytes): string;
var
  enc: TBase64EncodingStream;
  ms: TStringStream;
  src: TBytesStream;
begin
  ms := TStringStream.Create('');
  enc := TBase64EncodingStream.Create(ms);
  src := TBytesStream.Create(_1_by_data);
  try
    enc.CopyFrom(src, Length(_1_by_data));
    enc.Flush;
    Result := ms.DataString;
  finally
    src.Free;
    enc.Free;
    ms.Free;
  end;
end;

{ Décode une chaîne base64 en TBytes }
function Base64ToBytes(const _1_t_s: string): TBytes;
var
  Dec: TBase64DecodingStream;
  src: TStringStream;
  dst: TBytesStream;
begin
  src := TStringStream.Create(_1_t_s);
  dst := TBytesStream.Create;
  Dec := TBase64DecodingStream.Create(src);
  try
    dst.CopyFrom(Dec, 0);
    Result := dst.Bytes;
    SetLength(Result, dst.Size);
  finally
    Dec.Free;
    src.Free;
    dst.Free;
  end;
end;

{ Sérialise un document XML en String }
function DocToString(_1_o_doc: TXMLDocument): string;
var
  ss: TStringStream;
begin
  ss := TStringStream.Create('');
  try
    WriteXML(_1_o_doc, ss);
    Result := ss.DataString;
  finally
    ss.Free;
  end;
end;

{ Sérialise un document XML en TBytes }
function DocToBytes(_1_o_doc: TXMLDocument): TBytes;
var
  ms: TMemoryStream;
begin
  Result := nil;
  ms := TMemoryStream.Create;
  try
    WriteXML(_1_o_doc, ms);
    SetLength(Result, ms.Size);
    if (ms.Size > 0) then begin
      ms.Position := 0;
      ms.Read(Result[0], ms.Size);
    end;
  finally
    ms.Free;
  end;
end;

{ Libère toutes les entrées de la table qui appartiennent au document donné }
procedure UnregisterDoc(_1_o_doc: TXMLDocument);
var
  i: Int64;
  handle: string;
begin
  i := GDocMap.Count - 1;
  while (i >= 0) do begin
    if (GDocMap.Data[i] = _1_o_doc) then begin
      handle := GDocMap.Keys[i];
      GDocMap.Delete(i);
      GNodeMap.Remove(handle);
      GDocEncoding.Remove(handle);
      GDocIndent.Remove(handle);
    end;
    Dec(i);
  end;
end;

{ ============================================================
  Implémentation des méthodes publiques
  ============================================================ }

{ --- DOMAppendXMLChildNode (String) --- }
function DOMAppendXMLChildNode(const _1_t_elementRef: string; _2_e_childType: Int64;
  const _3_t_childValue: string): string;
var
  node: TDOMNode;
  doc: TXMLDocument;
  newNode: TDOMNode;
  textN: TDOMText;
  pi: TDOMProcessingInstruction;
  piName: string;
  piData: string;
  spacePos: Int64;
  comment: TDOMComment;
  cdata: TDOMCDATASection;
  elem: TDOMElement;
  fragDoc: TXMLDocument;
  fragStr: string;
  tmpNode: TDOMNode;
  importN: TDOMNode;
  fragSS: TStringStream;
begin
  Result := '';
  node := HandleToNode(_1_t_elementRef);
  doc := GetDocForHandle(_1_t_elementRef);
  newNode := nil;
  try
    case _2_e_childType of
      XML_DATA: begin
        textN := doc.CreateTextNode(DOMString(_3_t_childValue));
        newNode := node.AppendChild(textN);
      end;
      XML_CDATA: begin
        cdata := doc.CreateCDATASection(DOMString(_3_t_childValue));
        newNode := node.AppendChild(cdata);
      end;
      XML_COMMENT: begin
        comment := doc.CreateComment(DOMString(_3_t_childValue));
        newNode := node.AppendChild(comment);
      end;
      XML_PROCESSING_INSTRUCTION: begin
        spacePos := Pos(' ', _3_t_childValue);
        if (spacePos > 0) then begin
          piName := Copy(_3_t_childValue, 1, spacePos - 1);
          piData := Copy(_3_t_childValue, spacePos + 1, MaxInt);
        end else begin
          piName := _3_t_childValue;
          piData := '';
        end;
        pi := doc.CreateProcessingInstruction(DOMString(piName), DOMString(piData));
        newNode := doc.InsertBefore(pi, doc.DocumentElement);
      end;
      XML_DOCTYPE: begin
          { 4D insère un DOCTYPE avant le premier élément.
            Le DOM FPC ne permet pas de créer un nœud DOCTYPE dynamiquement,
            on stocke l'info sous forme de commentaire marqué pour post-traitement. }
        comment := doc.CreateComment(DOMString('DOCTYPE ' + _3_t_childValue));
        newNode := doc.InsertBefore(comment, doc.DocumentElement);
      end;
      XML_ELEMENT: begin
        { Si childValue est un fragment XML valide, on l'insère comme enfants }
        fragStr := '<_root_>' + _3_t_childValue + '</_root_>';
        fragSS := TStringStream.Create(fragStr);
        try
          fragDoc := nil;
          try
            ReadXMLFile(fragDoc, fragSS);
            tmpNode := fragDoc.DocumentElement.FirstChild;
            while (tmpNode <> nil) do begin
              importN := doc.ImportNode(tmpNode, True);
              node.AppendChild(importN);
              tmpNode := tmpNode.NextSibling;
            end;
            { retourne le dernier nœud importé }
            newNode := node.LastChild;
          except
            { childValue n'est pas du XML valide : on crée un élément vide }
            elem := doc.CreateElement(DOMString(_3_t_childValue));
            newNode := node.AppendChild(elem);
          end;
        finally
          fragSS.Free;
          if (fragDoc <> nil) then fragDoc.Free;
        end;
      end;
      else raise EQ4XMLError.CreateFmt('Type de nœud inconnu : %d', [_2_e_childType]);
    end;
    if (newNode <> nil) then Result := RegisterNode(newNode, doc);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMAppendXMLChildNode (TBytes) --- }
function DOMAppendXMLChildNode(const _1_t_elementRef: string; _2_e_childType: Int64;
  const _3_by_childValue: TBytes): string;
var
  s: string;
begin
  SetString(s, pansichar(_3_by_childValue), Length(_3_by_childValue));
  Result := DOMAppendXMLChildNode(_1_t_elementRef, _2_e_childType, s);
end;

{ --- DOMAppendXMLElement --- }
function DOMAppendXMLElement(const _1_t_targetElementRef: string; const _2_t_sourceElementRef: string): string;
var
  targetNode: TDOMNode;
  sourceNode: TDOMNode;
  doc: TXMLDocument;
  importedN: TDOMNode;
  appendedN: TDOMNode;
begin
  Result := '';
  targetNode := HandleToNode(_1_t_targetElementRef);
  sourceNode := HandleToNode(_2_t_sourceElementRef);
  doc := GetDocForHandle(_1_t_targetElementRef);
  try
    importedN := doc.ImportNode(sourceNode, True);
    appendedN := targetNode.AppendChild(importedN);
    Result := RegisterNode(appendedN, doc);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMCloseXML --- }
procedure DOMCloseXML(const _1_t_elementRef: string);
var
  doc: TXMLDocument;
begin
  try
    doc := GetDocForHandle(_1_t_elementRef);
    UnregisterDoc(doc);
    doc.Free;
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMCountXMLAttributes --- }
function DOMCountXMLAttributes(const _1_t_elementRef: string): Int64;
var
  elem: TDOMElement;
  attrMap: TDOMNamedNodeMap;
begin
  Result := 0;
  try
    elem := HandleToElement(_1_t_elementRef);
    attrMap := elem.Attributes;
    if (attrMap <> nil) then Result := attrMap.Length;
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMCountXMLElements --- }
function DOMCountXMLElements(const _1_t_elementRef: string; const _2_t_elementName: string): Int64;
var
  node: TDOMNode;
  child: TDOMNode;
begin
  Result := 0;
  try
    node := HandleToNode(_1_t_elementRef);
    child := node.FirstChild;
    while (child <> nil) do begin
      if ((child.NodeType = ELEMENT_NODE) and (child.NodeName = DOMString(_2_t_elementName))) then Inc(Result);
      child := child.NextSibling;
    end;
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMCreateXMLElement (sans attribut) --- }
function DOMCreateXMLElement(const _1_t_elementRef: string; const _2_t_xPath: string): string;
var
  baseNode: TDOMNode;
  doc: TXMLDocument;
  newElem: TDOMElement;
  resolved: TDOMNode;
  parentN: TDOMNode;
  elemName: string;
begin
  Result := '';
  baseNode := HandleToNode(_1_t_elementRef);
  doc := GetDocForHandle(_1_t_elementRef);
  try
    { Si xPath ne commence pas par '/', on crée un enfant direct }
    if ((Length(_2_t_xPath) > 0) and (_2_t_xPath[1] <> '/') and (Pos('/', _2_t_xPath) = 0) and (Pos('[', _2_t_xPath) = 0)) then begin
      newElem := doc.CreateElement(DOMString(_2_t_xPath));
      baseNode.AppendChild(newElem);
      Result := RegisterNode(newElem, doc);
    end else begin
      { Tente de résoudre le chemin XPath }
      resolved := ResolveXPath(baseNode, _2_t_xPath);
      if (resolved <> nil) then Result := RegisterNode(resolved, doc)
      else begin
        { Crée le dernier segment }
        elemName := _2_t_xPath;
        if (Pos('/', elemName) > 0) then elemName := Copy(elemName, LastDelimiter('/', elemName) + 1, MaxInt);
        { Supprime éventuel prédicat [n] }
        if (Pos('[', elemName) > 0) then elemName := Copy(elemName, 1, Pos('[', elemName) - 1);
        parentN := baseNode;
        newElem := doc.CreateElement(DOMString(elemName));
        parentN.AppendChild(newElem);
        Result := RegisterNode(newElem, doc);
      end;
    end;
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMCreateXMLElement (avec un attribut) --- }
function DOMCreateXMLElement(const _1_t_elementRef: string; const _2_t_xPath: string;
  const _3_t_attribName: string; const _4_y_attrValue: variant): string;
var
  newRef: string;
  elem: TDOMElement;
begin
  newRef := DOMCreateXMLElement(_1_t_elementRef, _2_t_xPath);
  elem := HandleToElement(newRef);
  elem.SetAttribute(DOMString(_3_t_attribName),
    DOMString(VariantToXMLString(_4_y_attrValue)));
  Result := newRef;
end;

{ --- DOMCreateXMLElementArrays --- }
function DOMCreateXMLElementArrays(const _1_t_elementRef: string; const _2_t_xPath: string;
  const _3_tt_attribNamesArray: array of string;
  const _4_tt_attribValuesArray: array of string): string;
var
  newRef: string;
  elem: TDOMElement;
  i: Int64;
  Count: Int64;
begin
  newRef := DOMCreateXMLElement(_1_t_elementRef, _2_t_xPath);
  elem := HandleToElement(newRef);
  Count := Length(_3_tt_attribNamesArray);
  if (Length(_4_tt_attribValuesArray) < Count) then Count := Length(_4_tt_attribValuesArray);
  for i := 0 to Count - 1 do elem.SetAttribute(DOMString(_3_tt_attribNamesArray[i]),
      DOMString(_4_tt_attribValuesArray[i]));
  Result := newRef;
end;

{ --- DOMCreateXMLRef (sans namespace) --- }
function DOMCreateXMLRef(const _1_t_root: string): string;
var
  doc: TXMLDocument;
  rootElem: TDOMElement;
begin
  doc := TXMLDocument.Create;
  rootElem := doc.CreateElement(DOMString(_1_t_root));
  doc.AppendChild(rootElem);
  Result := RegisterNode(rootElem, doc);
  OK := 1;
end;

{ --- DOMCreateXMLRef (avec namespace URI) --- }
function DOMCreateXMLRef(const _1_t_root: string; const _2_t_nameSpace: string): string;
var
  doc: TXMLDocument;
  rootElem: TDOMElement;
begin
  doc := TXMLDocument.Create;
  rootElem := doc.CreateElementNS(DOMString(_2_t_nameSpace), DOMString(_1_t_root));
  doc.AppendChild(rootElem);
  Result := RegisterNode(rootElem, doc);
  OK := 1;
end;

{ --- DOMCreateXMLRef (avec namespace name + value) --- }
function DOMCreateXMLRef(const _1_t_root: string; const _2_t_nameSpaceName: string;
  const _3_t_nameSpaceValue: string): string;
var
  doc: TXMLDocument;
  rootElem: TDOMElement;
begin
  doc := TXMLDocument.Create;
  rootElem := doc.CreateElement(DOMString(_1_t_root));
  rootElem.SetAttribute(DOMString('xmlns:' + _2_t_nameSpaceName),
    DOMString(_3_t_nameSpaceValue));
  doc.AppendChild(rootElem);
  Result := RegisterNode(rootElem, doc);
  OK := 1;
end;

{ --- DOMExportToFile --- }
procedure DOMExportToFile(const _1_t_elementRef: string; const _2_t_filePath: string);
var
  doc: TXMLDocument;
  handle: string;
  encIdx: Int64;
  encoding: string;
begin
  try
    doc := GetDocForHandle(_1_t_elementRef);
    handle := NodeToHandle(doc.DocumentElement);
    encIdx := GDocEncoding.IndexOf(handle);
    if (encIdx >= 0) then encoding := GDocEncoding.Data[encIdx]
    else
      encoding := 'UTF-8';
    WriteXMLFile(doc, _2_t_filePath);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMExportToVar (String) --- }
procedure DOMExportToVar(const _1_t_elementRef: string; out _2_t_vXmlVar: string);
var
  doc: TXMLDocument;
  handle: string;
  encIdx: Int64;
  encoding: string;
begin
  try
    doc := GetDocForHandle(_1_t_elementRef);
    handle := NodeToHandle(doc.DocumentElement);
    encIdx := GDocEncoding.IndexOf(handle);
    if (encIdx >= 0) then encoding := GDocEncoding.Data[encIdx]
    else
      encoding := 'UTF-8';
    _2_t_vXmlVar := DocToString(doc);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMExportToVar (TBytes) --- }
procedure DOMExportToVar(const _1_t_elementRef: string; out _2_by_vXmlVar: TBytes);
var
  doc: TXMLDocument;
  handle: string;
  encIdx: Int64;
  encoding: string;
begin
  try
    doc := GetDocForHandle(_1_t_elementRef);
    handle := NodeToHandle(doc.DocumentElement);
    encIdx := GDocEncoding.IndexOf(handle);
    if (encIdx >= 0) then encoding := GDocEncoding.Data[encIdx]
    else
      encoding := 'UTF-8';
    _2_by_vXmlVar := DocToBytes(doc);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMFindXMLElement (sans tableau) --- }
function DOMFindXMLElement(const _1_t_elementRef: string; const _2_t_xPath: string): string;
var
  baseNode: TDOMNode;
  doc: TXMLDocument;
  found: TDOMNode;
begin
  Result := '';
  baseNode := HandleToNode(_1_t_elementRef);
  doc := GetDocForHandle(_1_t_elementRef);
  try
    found := ResolveXPath(baseNode, _2_t_xPath);
    if (found <> nil) then Result := RegisterNode(found, doc)
    else
      Result := '';
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMFindXMLElement (avec tableau de références) --- }
function DOMFindXMLElement(const _1_t_elementRef: string; const _2_t_xPath: string;
  out _3_tt_arrElementRefs: array of string): string;
var
  baseNode: TDOMNode;
  doc: TXMLDocument;
  xpResult: TXPathVariable;
  nodeSet: TNodeSet;
  i: Int64;
  maxLen: Int64;
begin
  Result := '';
  baseNode := HandleToNode(_1_t_elementRef);
  doc := GetDocForHandle(_1_t_elementRef);
  try
    xpResult := EvaluateXPathExpression(DOMString(_2_t_xPath), baseNode);
    try
      nodeSet := xpResult.AsNodeSet;
      maxLen := Length(_3_tt_arrElementRefs);
      for i := 0 to nodeSet.Count - 1 do begin
        if (i < maxLen) then _3_tt_arrElementRefs[i] := RegisterNode(TDOMNode(nodeSet[i]), doc);
        if (i = 0) then Result := _3_tt_arrElementRefs[0];
      end;
    finally
      xpResult.Free;
    end;
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMFindXMLElementByID --- }
function DOMFindXMLElementByID(const _1_t_elementRef: string; const _2_t_id: string): string;
var
  doc: TXMLDocument;
  found: TDOMElement;
begin
  Result := '';
  try
    doc := GetDocForHandle(_1_t_elementRef);
    found := doc.GetElementById(DOMString(_2_t_id));
    if (found <> nil) then Result := RegisterNode(found, doc);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ Fonction interne commune aux Get*ChildXMLElement }
function InternalGetChildElement(_1_o_parentNode: TDOMNode; _2_b_getLast: boolean;
  _3_o_doc: TXMLDocument; out _4_t_childElemName: string;
  out _5_t_childElemValue: string): string;
var
  child: TDOMNode;
begin
  Result := '';
  _4_t_childElemName := '';
  _5_t_childElemValue := '';
  if (_2_b_getLast) then child := _1_o_parentNode.LastChild
  else
    child := _1_o_parentNode.FirstChild;
  while ((child <> nil) and (child.NodeType <> ELEMENT_NODE)) do if (_2_b_getLast) then child := child.PreviousSibling
    else
      child := child.NextSibling;
  if (child <> nil) then begin
    _4_t_childElemName := string(child.NodeName);
    _5_t_childElemValue := string(child.TextContent);
    Result := RegisterNode(child, _3_o_doc);
  end;
end;

{ --- DOMGetFirstChildXMLElement --- }
function DOMGetFirstChildXMLElement(const _1_t_elementRef: string): string;
var
  dummy1, dummy2: string;
begin
  Result := InternalGetChildElement(HandleToNode(_1_t_elementRef), False, GetDocForHandle(_1_t_elementRef), dummy1, dummy2);
  OK := 1;
end;

function DOMGetFirstChildXMLElement(const _1_t_elementRef: string; out _2_t_childElemName: string): string;
var
  dummy: string;
begin
  Result := InternalGetChildElement(HandleToNode(_1_t_elementRef), False, GetDocForHandle(_1_t_elementRef), _2_t_childElemName, dummy);
  OK := 1;
end;

function DOMGetFirstChildXMLElement(const _1_t_elementRef: string; out _2_t_childElemName: string;
  out _3_t_childElemValue: string): string;
begin
  Result := InternalGetChildElement(HandleToNode(_1_t_elementRef), False, GetDocForHandle(_1_t_elementRef), _2_t_childElemName, _3_t_childElemValue);
  OK := 1;
end;

{ --- DOMGetLastChildXMLElement --- }
function DOMGetLastChildXMLElement(const _1_t_elementRef: string): string;
var
  dummy1, dummy2: string;
begin
  Result := InternalGetChildElement(HandleToNode(_1_t_elementRef), True, GetDocForHandle(_1_t_elementRef), dummy1, dummy2);
  OK := 1;
end;

function DOMGetLastChildXMLElement(const _1_t_elementRef: string; out _2_t_childElemName: string): string;
var
  dummy: string;
begin
  Result := InternalGetChildElement(HandleToNode(_1_t_elementRef), True, GetDocForHandle(_1_t_elementRef), _2_t_childElemName, dummy);
  OK := 1;
end;

function DOMGetLastChildXMLElement(const _1_t_elementRef: string; out _2_t_childElemName: string;
  out _3_t_childElemValue: string): string;
begin
  Result := InternalGetChildElement(HandleToNode(_1_t_elementRef), True, GetDocForHandle(_1_t_elementRef), _2_t_childElemName, _3_t_childElemValue);
  OK := 1;
end;

{ Fonction interne pour les siblings }
function InternalGetSiblingElement(_1_o_currentNode: TDOMNode; _2_b_getNext: boolean;
  _3_o_doc: TXMLDocument; out _4_t_siblingElemName: string;
  out _5_t_siblingElemValue: string): string;
var
  sibling: TDOMNode;
begin
  Result := '';
  _4_t_siblingElemName := '';
  _5_t_siblingElemValue := '';
  if (_2_b_getNext) then sibling := _1_o_currentNode.NextSibling
  else
    sibling := _1_o_currentNode.PreviousSibling;
  while ((sibling <> nil) and (sibling.NodeType <> ELEMENT_NODE)) do if (_2_b_getNext) then sibling := sibling.NextSibling
    else
      sibling := sibling.PreviousSibling;
  if (sibling <> nil) then begin
    _4_t_siblingElemName := string(sibling.NodeName);
    _5_t_siblingElemValue := string(sibling.TextContent);
    Result := RegisterNode(sibling, _3_o_doc);
  end;
end;

{ --- DOMGetNextSiblingXMLElement --- }
function DOMGetNextSiblingXMLElement(const _1_t_elementRef: string): string;
var
  dummy1, dummy2: string;
begin
  Result := InternalGetSiblingElement(HandleToNode(_1_t_elementRef), True, GetDocForHandle(_1_t_elementRef), dummy1, dummy2);
  OK := 1;
end;

function DOMGetNextSiblingXMLElement(const _1_t_elementRef: string; out _2_t_siblingElemName: string): string;
var
  dummy: string;
begin
  Result := InternalGetSiblingElement(HandleToNode(_1_t_elementRef), True, GetDocForHandle(_1_t_elementRef), _2_t_siblingElemName, dummy);
  OK := 1;
end;

function DOMGetNextSiblingXMLElement(const _1_t_elementRef: string; out _2_t_siblingElemName: string;
  out _3_t_siblingElemValue: string): string;
begin
  Result := InternalGetSiblingElement(HandleToNode(_1_t_elementRef), True, GetDocForHandle(_1_t_elementRef), _2_t_siblingElemName, _3_t_siblingElemValue);
  OK := 1;
end;

{ --- DOMGetPreviousSiblingXMLElement --- }
function DOMGetPreviousSiblingXMLElement(const _1_t_elementRef: string): string;
var
  dummy1, dummy2: string;
begin
  Result := InternalGetSiblingElement(HandleToNode(_1_t_elementRef), False, GetDocForHandle(_1_t_elementRef), dummy1, dummy2);
  OK := 1;
end;

function DOMGetPreviousSiblingXMLElement(const _1_t_elementRef: string; out _2_t_siblingElemName: string): string;
var
  dummy: string;
begin
  Result := InternalGetSiblingElement(HandleToNode(_1_t_elementRef), False, GetDocForHandle(_1_t_elementRef), _2_t_siblingElemName, dummy);
  OK := 1;
end;

function DOMGetPreviousSiblingXMLElement(const _1_t_elementRef: string; out _2_t_siblingElemName: string;
  out _3_t_siblingElemValue: string): string;
begin
  Result := InternalGetSiblingElement(HandleToNode(_1_t_elementRef), False, GetDocForHandle(_1_t_elementRef), _2_t_siblingElemName, _3_t_siblingElemValue);
  OK := 1;
end;

{ --- DOMGetParentXMLElement --- }
function DOMGetParentXMLElement(const _1_t_elementRef: string): string;
var
  dummy1, dummy2: string;
begin
  Result := DOMGetParentXMLElement(_1_t_elementRef, dummy1, dummy2);
end;

function DOMGetParentXMLElement(const _1_t_elementRef: string; out _2_t_parentElemName: string): string;
var
  dummy: string;
begin
  Result := DOMGetParentXMLElement(_1_t_elementRef, _2_t_parentElemName, dummy);
end;

function DOMGetParentXMLElement(const _1_t_elementRef: string; out _2_t_parentElemName: string;
  out _3_t_parentElemValue: string): string;
var
  node: TDOMNode;
  parent: TDOMNode;
  doc: TXMLDocument;
begin
  Result := '';
  _2_t_parentElemName := '';
  _3_t_parentElemValue := '';
  try
    node := HandleToNode(_1_t_elementRef);
    doc := GetDocForHandle(_1_t_elementRef);
    parent := node.ParentNode;
    if ((parent <> nil) and (parent.NodeType = ELEMENT_NODE)) then begin
      _2_t_parentElemName := string(parent.NodeName);
      _3_t_parentElemValue := string(parent.TextContent);
      Result := RegisterNode(parent, doc);
    end;
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMGetRootXMLElement --- }
function DOMGetRootXMLElement(const _1_t_elementRef: string): string;
var
  doc: TXMLDocument;
begin
  try
    doc := GetDocForHandle(_1_t_elementRef);
    Result := RegisterNode(doc.DocumentElement, doc);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMGetXMLAttributeByIndex --- }
procedure DOMGetXMLAttributeByIndex(const _1_t_elementRef: string; _2_e_attribIndex: Int64;
  out _3_y_attribName: variant; out _4_y_attribValue: variant);
var
  elem: TDOMElement;
  attrMap: TDOMNamedNodeMap;
  attr: TDOMNode;
begin
  _3_y_attribName := Unassigned;
  _4_y_attribValue := Unassigned;
  try
    elem := HandleToElement(_1_t_elementRef);
    attrMap := elem.Attributes;
    { 4D utilise un index base 1 }
    if ((attrMap <> nil) and (_2_e_attribIndex >= 1) and (_2_e_attribIndex <= integer(attrMap.Length))) then begin
      attr := attrMap.Item[_2_e_attribIndex - 1];
      _3_y_attribName := string(attr.NodeName);
      _4_y_attribValue := string(attr.NodeValue);
    end;
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMGetXMLAttributeByName --- }
procedure DOMGetXMLAttributeByName(const _1_t_elementRef: string; const _2_t_attribName: string;
  out _3_y_attribValue: variant);
var
  elem: TDOMElement;
begin
  _3_y_attribValue := Unassigned;
  try
    elem := HandleToElement(_1_t_elementRef);
    _3_y_attribValue := string(elem.GetAttribute(DOMString(_2_t_attribName)));
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMGetXMLChildNodes --- }
procedure DOMGetXMLChildNodes(const _1_t_elementRef: string; out _2_te_childTypesArr: array of integer;
  out _3_tt_nodeRefsArr: array of string);
var
  node: TDOMNode;
  doc: TXMLDocument;
  child: TDOMNode;
  idx: Int64;
  maxLen: Int64;
  nodeType: Int64;
begin
  try
    node := HandleToNode(_1_t_elementRef);
    doc := GetDocForHandle(_1_t_elementRef);
    child := node.FirstChild;
    idx := 0;
    maxLen := Length(_2_te_childTypesArr);
    if (Length(_3_tt_nodeRefsArr) < maxLen) then maxLen := Length(_3_tt_nodeRefsArr);
    while ((child <> nil) and (idx < maxLen)) do begin
      { Conversion du type DOM vers les constantes 4D }
      case child.NodeType of
        TEXT_NODE: nodeType := XML_DATA;
        CDATA_SECTION_NODE: nodeType := XML_CDATA;
        COMMENT_NODE: nodeType := XML_COMMENT;
        PROCESSING_INSTRUCTION_NODE: nodeType := XML_PROCESSING_INSTRUCTION;
        ELEMENT_NODE: nodeType := XML_ELEMENT;
        else nodeType := child.NodeType;
      end;
      _2_te_childTypesArr[idx] := nodeType;
      _3_tt_nodeRefsArr[idx] := RegisterNode(child, doc);
      Inc(idx);
      child := child.NextSibling;
    end;
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMGetXMLDocumentRef --- }
function DOMGetXMLDocumentRef(const _1_t_elementRef: string): string;
var
  doc: TXMLDocument;
begin
  try
    doc := GetDocForHandle(_1_t_elementRef);
    Result := RegisterNode(doc.DocumentElement, doc);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMGetXMLElement (sans paramètres optionnels) --- }
function DOMGetXMLElement(const _1_t_elementRef: string; const _2_t_elementName: string;
  _3_e_index: Int64): string;
var
  dummy1: variant;
  dummyArr1: array[0..0] of string;
  dummyArr2: array[0..0] of string;
begin
  Result := DOMGetXMLElement(_1_t_elementRef, _2_t_elementName, _3_e_index, dummy1, dummyArr1, dummyArr2);
end;

{ --- DOMGetXMLElement (avec elementValue) --- }
function DOMGetXMLElement(const _1_t_elementRef: string; const _2_t_elementName: string;
  _3_e_index: Int64; out _4_y_elementValue: variant): string;
var
  dummyArr1: array[0..0] of string;
  dummyArr2: array[0..0] of string;
begin
  Result := DOMGetXMLElement(_1_t_elementRef, _2_t_elementName, _3_e_index, _4_y_elementValue, dummyArr1, dummyArr2);
end;

{ --- DOMGetXMLElement (complet) --- }
function DOMGetXMLElement(const _1_t_elementRef: string; const _2_t_elementName: string;
  _3_e_index: Int64; out _4_y_elementValue: variant;
  out _5_tt_attrNames: array of string; out _6_tt_attrValues: array of string): string;
var
  node: TDOMNode;
  doc: TXMLDocument;
  child: TDOMNode;
  Count: Int64;
  elem: TDOMElement;
  attrMap: TDOMNamedNodeMap;
  i: Int64;
  maxAttr: Int64;
begin
  Result := '';
  _4_y_elementValue := Unassigned;
  try
    node := HandleToNode(_1_t_elementRef);
    doc := GetDocForHandle(_1_t_elementRef);
    child := node.FirstChild;
    Count := 0;
    while (child <> nil) do begin
      if ((child.NodeType = ELEMENT_NODE) and (child.NodeName = DOMString(_2_t_elementName))) then begin
        Inc(Count);
        if (Count = _3_e_index) then begin
          _4_y_elementValue := string(child.TextContent);
          Result := RegisterNode(child, doc);
          elem := TDOMElement(child);
          attrMap := elem.Attributes;
          if (attrMap <> nil) then begin
            maxAttr := Length(_5_tt_attrNames);
            if (Length(_6_tt_attrValues) < maxAttr) then maxAttr := Length(_6_tt_attrValues);
            for i := 0 to integer(attrMap.Length) - 1 do begin
              if (i >= maxAttr) then Break;
              _5_tt_attrNames[i] := string(attrMap.Item[i].NodeName);
              _6_tt_attrValues[i] := string(attrMap.Item[i].NodeValue);
            end;
          end;
          Break;
        end;
      end;
      child := child.NextSibling;
    end;
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMGetXMLElementName --- }
procedure DOMGetXMLElementName(const _1_t_elementRef: string; out _2_y_elementName: variant);
var
  node: TDOMNode;
begin
  try
    node := HandleToNode(_1_t_elementRef);
    _2_y_elementName := string(node.NodeName);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMGetXMLElementValue (sans CDATA) --- }
procedure DOMGetXMLElementValue(const _1_t_elementRef: string; out _2_y_elementValue: variant);
var
  dummy: variant;
begin
  DOMGetXMLElementValue(_1_t_elementRef, _2_y_elementValue, dummy);
end;

{ --- DOMGetXMLElementValue (avec CDATA) --- }
procedure DOMGetXMLElementValue(const _1_t_elementRef: string; out _2_y_elementValue: variant;
  out _3_y_cDATA: variant);
var
  node: TDOMNode;
  child: TDOMNode;
  textVal: string;
  cdataVal: string;
begin
  _2_y_elementValue := Unassigned;
  _3_y_cDATA := Unassigned;
  try
    node := HandleToNode(_1_t_elementRef);
    textVal := '';
    cdataVal := '';
    child := node.FirstChild;
    while (child <> nil) do begin
      case child.NodeType of
        TEXT_NODE: textVal := textVal + string(child.NodeValue);
        CDATA_SECTION_NODE: cdataVal := cdataVal + string(child.NodeValue);
      end;
      child := child.NextSibling;
    end;
    { Vérifie si la valeur texte est du base64 (cas BLOB stocké) }
    if ((node.NodeType = ELEMENT_NODE) and (TDOMElement(node).GetAttribute('type') = 'BLOB')) then _2_y_elementValue := Base64ToBytes(textVal)
    else
      _2_y_elementValue := textVal;
    _3_y_cDATA := cdataVal;
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMGetXMLInformation --- }
function DOMGetXMLInformation(const _1_t_elementRef: string; _2_e_xmlInfo: Int64): string;
var
  doc: TXMLDocument;
  doctype: TDOMDocumentType;
begin
  Result := '';
  try
    doc := GetDocForHandle(_1_t_elementRef);
    doctype := doc.DocType;
    case _2_e_xmlInfo of
      XML_INFO_PUBLIC_ID: if (doctype <> nil) then Result := string(doctype.PublicID);
      XML_INFO_SYSTEM_ID: if (doctype <> nil) then Result := string(doctype.SystemID);
      XML_INFO_DOCTYPE_NAME: if (doctype <> nil) then Result := string(doctype.Name);
      XML_INFO_ENCODING: Result := string(doc.XMLEncoding);
      XML_INFO_VERSION: Result := string(doc.XMLVersion);
      XML_INFO_DOCUMENT_URI: Result := string(doc.DocumentURI);
    end;
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMInsertXMLElement --- }
function DOMInsertXMLElement(const _1_t_targetElementRef: string; const _2_t_sourceElementRef: string;
  _3_e_childIndex: Int64): string;
var
  targetNode: TDOMNode;
  sourceNode: TDOMNode;
  doc: TXMLDocument;
  importedN: TDOMNode;
  refChild: TDOMNode;
  child: TDOMNode;
  idx: Int64;
  insertedN: TDOMNode;
begin
  Result := '';
  targetNode := HandleToNode(_1_t_targetElementRef);
  sourceNode := HandleToNode(_2_t_sourceElementRef);
  doc := GetDocForHandle(_1_t_targetElementRef);
  try
    importedN := doc.ImportNode(sourceNode, True);
    { Trouve le nœud de référence à l'index childIndex }
    refChild := nil;
    if (_3_e_childIndex > 0) then begin
      child := targetNode.FirstChild;
      idx := 1;
      while ((child <> nil) and (idx < _3_e_childIndex)) do begin
        child := child.NextSibling;
        Inc(idx);
      end;
      refChild := child;
    end;
    insertedN := targetNode.InsertBefore(importedN, refChild);
    Result := RegisterNode(insertedN, doc);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ Fonction interne de parsing }
function InternalParseXMLStream(_1_o_stream: TStream; _2_b_validation: boolean;
  const _3_t_dtdOrSchema: string): string;
var
  doc: TXMLDocument;
  rootElem: TDOMElement;
begin
  Result := '';
  doc := nil;
  try
    if (_3_t_dtdOrSchema <> '') then ReadXMLFile(doc, _1_o_stream){ Parsing avec DTD/XSD externe non implémenté ici au niveau FPC standard.
        On parse sans validation et on informe l'appelant. }
    else if (_2_b_validation) then ReadXMLFile(doc, _1_o_stream)
    else
      ReadXMLFile(doc, _1_o_stream);

    if (doc <> nil) then begin
      rootElem := doc.DocumentElement;
      if (rootElem <> nil) then Result := RegisterNode(rootElem, doc)
      else begin
        doc.Free;
        raise EQ4XMLError.Create('Document XML sans élément racine');
      end;
    end;
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      if (doc <> nil) then doc.Free;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMParseXMLSource --- }
function DOMParseXMLSource(const _1_t_document: string): string;
begin
  Result := DOMParseXMLSource(_1_t_document, False, '');
end;

function DOMParseXMLSource(const _1_t_document: string; _2_b_validation: boolean): string;
begin
  Result := DOMParseXMLSource(_1_t_document, _2_b_validation, '');
end;

function DOMParseXMLSource(const _1_t_document: string; _2_b_validation: boolean;
  const _3_t_dtdOrSchema: string): string;
var
  fs: TFileStream;
begin
  Result := '';
  try
    fs := TFileStream.Create(_1_t_document, fmOpenRead or fmShareDenyWrite);
    try
      Result := InternalParseXMLStream(fs, _2_b_validation, _3_t_dtdOrSchema);
    finally
      fs.Free;
    end;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMParseXMLVariable (String) --- }
function DOMParseXMLVariable(const _1_t_variable: string): string;
begin
  Result := DOMParseXMLVariable(_1_t_variable, False, '');
end;

function DOMParseXMLVariable(const _1_t_variable: string; _2_b_validation: boolean): string;
begin
  Result := DOMParseXMLVariable(_1_t_variable, _2_b_validation, '');
end;

function DOMParseXMLVariable(const _1_t_variable: string; _2_b_validation: boolean;
  const _3_t_dtdOrSchema: string): string;
var
  ss: TStringStream;
begin
  ss := TStringStream.Create(_1_t_variable);
  try
    Result := InternalParseXMLStream(ss, _2_b_validation, _3_t_dtdOrSchema);
  finally
    ss.Free;
  end;
end;

{ --- DOMParseXMLVariable (TBytes) --- }
function DOMParseXMLVariable(const _1_by_variable: TBytes): string;
begin
  Result := DOMParseXMLVariable(_1_by_variable, False, '');
end;

function DOMParseXMLVariable(const _1_by_variable: TBytes; _2_b_validation: boolean): string;
begin
  Result := DOMParseXMLVariable(_1_by_variable, _2_b_validation, '');
end;

function DOMParseXMLVariable(const _1_by_variable: TBytes; _2_b_validation: boolean;
  const _3_t_dtdOrSchema: string): string;
var
  ms: TMemoryStream;
begin
  ms := TMemoryStream.Create;
  try
    if (Length(_1_by_variable) > 0) then ms.Write(_1_by_variable[0], Length(_1_by_variable));
    ms.Position := 0;
    Result := InternalParseXMLStream(ms, _2_b_validation, _3_t_dtdOrSchema);
  finally
    ms.Free;
  end;
end;

{ --- DOMRemoveXMLAttribute --- }
procedure DOMRemoveXMLAttribute(const _1_t_elementRef: string; const _2_t_attribName: string);
var
  elem: TDOMElement;
begin
  try
    elem := HandleToElement(_1_t_elementRef);
    elem.RemoveAttribute(DOMString(_2_t_attribName));
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMRemoveXMLElement --- }
procedure DOMRemoveXMLElement(const _1_t_elementRef: string);
var
  node: TDOMNode;
  parent: TDOMNode;
  handle: string;
begin
  try
    node := HandleToNode(_1_t_elementRef);
    parent := node.ParentNode;
    if (parent = nil) then raise EQ4XMLError.Create('Impossible de supprimer l''élément racine ou un nœud sans parent');
    parent.RemoveChild(node);
    { Retire le handle de la table }
    handle := NodeToHandle(node);
    GNodeMap.Remove(handle);
    GDocMap.Remove(handle);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMSetXMLAttribute --- }
procedure DOMSetXMLAttribute(const _1_t_elementRef: string; const _2_t_attribName: string;
  const _3_y_attrValue: variant);
var
  elem: TDOMElement;
begin
  try
    elem := HandleToElement(_1_t_elementRef);
    elem.SetAttribute(DOMString(_2_t_attribName),
      DOMString(VariantToXMLString(_3_y_attrValue)));
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMSetXMLDeclaration --- }
procedure DOMSetXMLDeclaration(const _1_t_elementRef: string; const _2_t_encoding: string);
begin
  DOMSetXMLDeclaration(_1_t_elementRef, _2_t_encoding, False, False);
end;

procedure DOMSetXMLDeclaration(const _1_t_elementRef: string; const _2_t_encoding: string;
  _3_b_standalone: boolean);
begin
  DOMSetXMLDeclaration(_1_t_elementRef, _2_t_encoding, _3_b_standalone, False);
end;

procedure DOMSetXMLDeclaration(const _1_t_elementRef: string; const _2_t_encoding: string;
  _3_b_standalone: boolean; _4_b_indentation: boolean);
var
  doc: TXMLDocument;
  handle: string;
  idxE: Int64;
  idxI: Int64;
begin
  try
    doc := GetDocForHandle(_1_t_elementRef);
    handle := NodeToHandle(doc.DocumentElement);

    { Mémorise l'encodage cible (XMLEncoding est read-only dans le DOM FPC ;
      l'encodage sera appliqué lors de l'export via WriteXML) }
    if (_2_t_encoding <> '') then begin
      idxE := GDocEncoding.IndexOf(handle);
      if (idxE < 0) then GDocEncoding.Add(handle, _2_t_encoding)
      else
        GDocEncoding.Data[idxE] := _2_t_encoding;
    end;

    { standalone est stocké via XMLStandalone (propriété en écriture) }
    doc.XMLStandalone := _3_b_standalone;

    { Mémorise le flag d'indentation }
    idxI := GDocIndent.IndexOf(handle);
    if (_4_b_indentation) then begin
      if (idxI < 0) then GDocIndent.Add(handle, 'yes')
      else
        GDocIndent.Data[idxI] := 'yes';
    end else if (idxI >= 0) then GDocIndent.Delete(idxI);

    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMSetXMLElementName --- }
procedure DOMSetXMLElementName(const _1_t_elementRef: string; const _2_t_elementName: string);
var
  node: TDOMNode;
  doc: TXMLDocument;
  newElem: TDOMElement;
  child: TDOMNode;
  nextChild: TDOMNode;
  parent: TDOMNode;
  attrMap: TDOMNamedNodeMap;
  i: Int64;
  newHandle: string;
begin
  { DOM FPC ne permet pas de renommer un élément directement.
    On crée un nouvel élément avec le nouveau nom, on y déplace
    tous les attributs et enfants, puis on remplace l'ancien. }
  try
    node := HandleToNode(_1_t_elementRef);
    doc := GetDocForHandle(_1_t_elementRef);
    parent := node.ParentNode;
    if (parent = nil) then raise EQ4XMLError.Create('Impossible de renommer l''élément racine');
    newElem := doc.CreateElement(DOMString(_2_t_elementName));
    { Copie les attributs }
    attrMap := TDOMElement(node).Attributes;
    if (attrMap <> nil) then for i := 0 to integer(attrMap.Length) - 1 do newElem.SetAttribute(attrMap.Item[i].NodeName,
          attrMap.Item[i].NodeValue);
    { Déplace les enfants }
    child := node.FirstChild;
    while (child <> nil) do begin
      nextChild := child.NextSibling;
      newElem.AppendChild(node.RemoveChild(child));
      child := nextChild;
    end;
    parent.ReplaceChild(newElem, node);
    { Met à jour la table de hachage }
    newHandle := NodeToHandle(node);
    GNodeMap.Remove(newHandle);
    GDocMap.Remove(newHandle);
    newHandle := RegisterNode(newElem, doc);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ Fonction interne pour retrouver un nœud via XPath depuis un elementRef }
function ResolveNodeFromRefAndXPath(const _1_t_elementRef: string; const _2_t_xPath: string): TDOMNode;
var
  baseNode: TDOMNode;
begin
  baseNode := HandleToNode(_1_t_elementRef);
  Result := ResolveXPath(baseNode, _2_t_xPath);
  if (Result = nil) then raise EQ4XMLError.CreateFmt('Élément introuvable via XPath : %s', [_2_t_xPath]);
end;

{ --- DOMSetXMLElementValue (sans xPath, sans CDATA) --- }
procedure DOMSetXMLElementValue(const _1_t_elementRef: string; const _2_y_elementValue: variant);
var
  node: TDOMNode;
  doc: TXMLDocument;
  child: TDOMNode;
  textN: TDOMText;
  strVal: string;
  b64Val: string;
begin
  try
    node := HandleToNode(_1_t_elementRef);
    doc := GetDocForHandle(_1_t_elementRef);
    { Supprime les nœuds texte existants }
    child := node.FirstChild;
    while (child <> nil) do if (child.NodeType in [TEXT_NODE, CDATA_SECTION_NODE]) then begin
        node.RemoveChild(child);
        child := node.FirstChild;
      end else
        child := child.NextSibling;
    { Si Variant est TBytes, on encode en base64 }
    if (VarType(_2_y_elementValue) = (varArray or varByte)) then begin
      b64Val := BytesToBase64(TBytes(_2_y_elementValue));
      textN := doc.CreateTextNode(DOMString(b64Val));
      { Marque l'élément comme BLOB pour la relecture }
      TDOMElement(node).SetAttribute('type', 'BLOB');
    end else begin
      strVal := VariantToXMLString(_2_y_elementValue);
      textN := doc.CreateTextNode(DOMString(strVal));
    end;
    node.AppendChild(textN);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMSetXMLElementValue (avec xPath, sans CDATA) --- }
procedure DOMSetXMLElementValue(const _1_t_elementRef: string; const _2_t_xPath: string;
  const _3_y_elementValue: variant);
var
  doc: TXMLDocument;
  target: TDOMNode;
  child: TDOMNode;
  textN: TDOMText;
  strVal: string;
begin
  try
    doc := GetDocForHandle(_1_t_elementRef);
    target := ResolveNodeFromRefAndXPath(_1_t_elementRef, _2_t_xPath);
    child := target.FirstChild;
    while (child <> nil) do if (child.NodeType in [TEXT_NODE, CDATA_SECTION_NODE]) then begin
        target.RemoveChild(child);
        child := target.FirstChild;
      end else
        child := child.NextSibling;
    strVal := VariantToXMLString(_3_y_elementValue);
    textN := doc.CreateTextNode(DOMString(strVal));
    target.AppendChild(textN);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMSetXMLElementValueCDATA (sans xPath) --- }
procedure DOMSetXMLElementValueCDATA(const _1_t_elementRef: string; const _2_y_elementValue: variant);
var
  node: TDOMNode;
  doc: TXMLDocument;
  child: TDOMNode;
  cdataS: TDOMCDATASection;
  strVal: string;
begin
  try
    node := HandleToNode(_1_t_elementRef);
    doc := GetDocForHandle(_1_t_elementRef);
    child := node.FirstChild;
    while (child <> nil) do if (child.NodeType in [TEXT_NODE, CDATA_SECTION_NODE]) then begin
        node.RemoveChild(child);
        child := node.FirstChild;
      end else
        child := child.NextSibling;
    strVal := VariantToXMLString(_2_y_elementValue);
    cdataS := doc.CreateCDATASection(DOMString(strVal));
    node.AppendChild(cdataS);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ --- DOMSetXMLElementValueCDATA (avec xPath) --- }
procedure DOMSetXMLElementValueCDATA(const _1_t_elementRef: string; const _2_t_xPath: string;
  const _3_y_elementValue: variant);
var
  doc: TXMLDocument;
  target: TDOMNode;
  child: TDOMNode;
  cdataS: TDOMCDATASection;
  strVal: string;
begin
  try
    doc := GetDocForHandle(_1_t_elementRef);
    target := ResolveNodeFromRefAndXPath(_1_t_elementRef, _2_t_xPath);
    child := target.FirstChild;
    while (child <> nil) do if (child.NodeType in [TEXT_NODE, CDATA_SECTION_NODE]) then begin
        target.RemoveChild(child);
        child := target.FirstChild;
      end else
        child := child.NextSibling;
    strVal := VariantToXMLString(_3_y_elementValue);
    cdataS := doc.CreateCDATASection(DOMString(strVal));
    target.AppendChild(cdataS);
    OK := 1;
  except
    on E: Exception do begin
      OK := 0;
      raise EQ4XMLError.Create(E.Message);
    end;
  end;
end;

{ ============================================================
  Initialisation / Finalisation
  ============================================================ }

{ Procédure de nettoyage extraite pour pouvoir déclarer ses variables
  locales hors des sections initialization/finalization }
procedure FinalizeQ4XMLDom;
var
  uniqueDocs: TList;
  i: Int64;
  doc: TXMLDocument;
begin
  { Collecte les pointeurs de documents uniques avant de libérer.
    GDocMap contient une entrée PAR NŒUD enregistré : plusieurs handles
    peuvent pointer vers le même TXMLDocument. On déduplique via une TList
    pour éviter tout double-free. }
  uniqueDocs := TList.Create;
  try
    for i := 0 to GDocMap.Count - 1 do begin
      doc := GDocMap.Data[i];
      if ((doc <> nil) and (uniqueDocs.IndexOf(doc) < 0)) then uniqueDocs.Add(doc);
    end;
    for i := 0 to uniqueDocs.Count - 1 do TXMLDocument(uniqueDocs[i]).Free;
  finally
    uniqueDocs.Free;
  end;
  GNodeMap.Free;
  GDocMap.Free;
  GDocEncoding.Free;
  GDocIndent.Free;
end;

initialization
  GNodeMap := TNodeHandleMap.Create;
  GDocMap := TDocHandleMap.Create;
  GDocEncoding := TStringHandleMap.Create;
  GDocIndent := TStringHandleMap.Create;
  OK := 1;

finalization
  FinalizeQ4XMLDom;

end.
