unit q4xliff;

{
q4xliff
version du 2026/05/15

Objectif:
  Support XLIFF minimal pour q4String.localizedString.

Périmètre:
  - XLIFF XML uniquement.
  - Ressources STR# non supportées.
  - PO/MO GetText non utilisé.
  - Chargement de fichiers .xlf depuis un fichier, un dossier, ou le schéma 4D:
      <projectPath>/Resources/<languageCode>.lproj/<languageCode>.xlf
  - Résolution par trans-unit/@resname.
  - Fallback sur trans-unit/@id uniquement si @resname est absent.
  - Si <target> existe et contient un texte non vide, il est prioritaire.
  - Sinon, fallback sur <source>.
  - Si aucune traduction n'est trouvée, retour de la clé demandée.

Notes:
  Les plages historiques 16000, 16100, 16101... sont des conventions applicatives
  dérivées de STR#, mais q4xliff ne les interprète pas.
  q4xliff indexe uniquement les clés XLIFF, principalement trans-unit/@resname.
}

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, DOM, XMLRead;

procedure clear;
procedure loadFile(const _1_t_filePath: string);
procedure loadFolder(const _1_t_folderPath: string);
procedure loadLanguageFolder(const _1_t_resourcesPath: string; const _2_t_languageCode: string);
procedure loadLanguage(const _1_t_projectPath: string; const _2_t_languageCode: string);
function localizedString(const _1_t_resName: string): string;
function isLoaded: Boolean;
function loadedCount: Int64;

implementation

var
  _o_translations: TStringList = nil;

procedure InternalEnsureStore;
begin
  if (_o_translations <> nil) then
    Exit;

  _o_translations := TStringList.Create;
  _o_translations.Sorted := True;
  _o_translations.Duplicates := dupIgnore;
  _o_translations.CaseSensitive := True;
end;

function InternalNodeText(const _1_o_node: TDOMNode): string;
var
  _o_child: TDOMNode;
begin
  Result := '';

  if (_1_o_node = nil) then
    Exit;

  _o_child := _1_o_node.FirstChild;
  while (_o_child <> nil) do begin
    if ((_o_child.NodeType = TEXT_NODE) or (_o_child.NodeType = CDATA_SECTION_NODE)) then
      Result := Result + _o_child.NodeValue
    else
      Result := Result + InternalNodeText(_o_child);

    _o_child := _o_child.NextSibling;
  end;
end;

function InternalFirstChildElementByName(const _1_o_node: TDOMNode; const _2_t_name: string): TDOMNode;
var
  _o_child: TDOMNode;
begin
  Result := nil;

  if (_1_o_node = nil) then
    Exit;

  _o_child := _1_o_node.FirstChild;
  while (_o_child <> nil) do begin
    if ((_o_child.NodeType = ELEMENT_NODE) and (String(_o_child.NodeName) = _2_t_name)) then
      Exit(_o_child);

    _o_child := _o_child.NextSibling;
  end;
end;

function InternalAttributeValue(const _1_o_node: TDOMNode; const _2_t_name: string): string;
var
  _o_namedNodeMap: TDOMNamedNodeMap;
  _o_attr: TDOMNode;
begin
  Result := '';

  if (_1_o_node = nil) then
    Exit;

  _o_namedNodeMap := _1_o_node.Attributes;
  if (_o_namedNodeMap = nil) then
    Exit;

  _o_attr := _o_namedNodeMap.GetNamedItem(_2_t_name);
  if (_o_attr = nil) then
    Exit;

  Result := _o_attr.NodeValue;
end;

procedure InternalAddTranslation(const _1_t_key: string; const _2_t_value: string);
begin
  if (_1_t_key = '') then
    Exit;

  InternalEnsureStore;

  // 4D charge les fichiers XLIFF dans un ordre déterminé.
  // q4xliff conserve la première valeur rencontrée pour éviter qu'un doublon
  // accidentel dans un fichier chargé plus tard ne change silencieusement le sens.
  if (_o_translations.IndexOfName(_1_t_key) >= 0) then
    Exit;

  _o_translations.Values[_1_t_key] := _2_t_value;
end;

procedure InternalScanNode(const _1_o_node: TDOMNode);
var
  _t_key: string;
  _t_targetValue: string;
  _t_sourceValue: string;
  _t_value: string;
  _o_source: TDOMNode;
  _o_target: TDOMNode;
  _o_child: TDOMNode;
begin
  if (_1_o_node = nil) then
    Exit;

  if ((_1_o_node.NodeType = ELEMENT_NODE) and (String(_1_o_node.NodeName) = 'trans-unit')) then begin
    // Les fichiers 4D réels utilisent trans-unit/@resname comme clé stable
    // ex: resname="str16000-1". L'attribut id est seulement numérique dans
    // ces fichiers et ne suffit pas à retrouver :xliff:str16000-1.
    _t_key := InternalAttributeValue(_1_o_node, 'resname');
    if (_t_key = '') then
      _t_key := InternalAttributeValue(_1_o_node, 'id');

    _o_target := InternalFirstChildElementByName(_1_o_node, 'target');
    _t_targetValue := InternalNodeText(_o_target);

    _o_source := InternalFirstChildElementByName(_1_o_node, 'source');
    _t_sourceValue := InternalNodeText(_o_source);

    // Dans les fichiers 4D observés, <target/> est souvent vide lorsque
    // source-language = target-language. Dans ce cas, la valeur utile est <source>.
    if (SysUtils.Trim(_t_targetValue) <> '') then
      _t_value := _t_targetValue
    else
      _t_value := _t_sourceValue;

    InternalAddTranslation(_t_key, _t_value);
  end;

  _o_child := _1_o_node.FirstChild;
  while (_o_child <> nil) do begin
    InternalScanNode(_o_child);
    _o_child := _o_child.NextSibling;
  end;
end;

function InternalNormalizeKey(const _1_t_resName: string): string;
const
  XLIFF_PREFIX = ':xliff:';
begin
  Result := _1_t_resName;

  if (System.Copy(Result, 1, System.Length(XLIFF_PREFIX)) = XLIFF_PREFIX) then
    System.Delete(Result, 1, System.Length(XLIFF_PREFIX));
end;

function InternalLanguageFolderPath(const _1_t_resourcesPath: string; const _2_t_languageCode: string): string;
begin
  Result := SysUtils.IncludeTrailingPathDelimiter(_1_t_resourcesPath) +
    _2_t_languageCode + '.lproj';
end;

function InternalLanguageFilePath(const _1_t_resourcesPath: string; const _2_t_languageCode: string): string;
begin
  Result := SysUtils.IncludeTrailingPathDelimiter(InternalLanguageFolderPath(_1_t_resourcesPath, _2_t_languageCode)) +
    _2_t_languageCode + '.xlf';
end;

procedure clear;
begin
  SysUtils.FreeAndNil(_o_translations);
end;

procedure loadFile(const _1_t_filePath: string);
var
  _o_document: TXMLDocument;
begin
  InternalEnsureStore;

  if (not SysUtils.FileExists(_1_t_filePath)) then
    Exit;

  _o_document := nil;
  try
    XMLRead.ReadXMLFile(_o_document, _1_t_filePath);
    InternalScanNode(_o_document.DocumentElement);
  finally
    _o_document.Free;
  end;
end;

procedure loadFolder(const _1_t_folderPath: string);
var
  _t_searchPath: string;
  _y_searchRec: TSearchRec;
  _tt_files: TStringList;
  _e_i: Int64;
begin
  InternalEnsureStore;

  _tt_files := TStringList.Create;
  try
    _tt_files.Sorted := True;
    _tt_files.CaseSensitive := True;

    _t_searchPath := SysUtils.IncludeTrailingPathDelimiter(_1_t_folderPath) + '*.xlf';

    if (SysUtils.FindFirst(_t_searchPath, SysUtils.faAnyFile, _y_searchRec) = 0) then begin
      try
        repeat
          if ((_y_searchRec.Attr and SysUtils.faDirectory) = 0) then
            _tt_files.Add(SysUtils.IncludeTrailingPathDelimiter(_1_t_folderPath) + _y_searchRec.Name);
        until (SysUtils.FindNext(_y_searchRec) <> 0);
      finally
        SysUtils.FindClose(_y_searchRec);
      end;
    end;

    for _e_i := 0 to _tt_files.Count - 1 do
      loadFile(_tt_files[_e_i]);
  finally
    _tt_files.Free;
  end;
end;

procedure loadLanguageFolder(const _1_t_resourcesPath: string; const _2_t_languageCode: string);
begin
  // Charge tous les .xlf du dossier Resources/<lang>.lproj, dans l'ordre alphabétique.
  loadFolder(InternalLanguageFolderPath(_1_t_resourcesPath, _2_t_languageCode));
end;

procedure loadLanguage(const _1_t_projectPath: string; const _2_t_languageCode: string);
var
  _t_resourcesPath: string;
  _t_languageFilePath: string;
begin
  // Schéma 4D standard observé:
  // <projectPath>/Resources/<lang>.lproj/<lang>.xlf
  _t_resourcesPath := SysUtils.IncludeTrailingPathDelimiter(_1_t_projectPath) + 'Resources';
  _t_languageFilePath := InternalLanguageFilePath(_t_resourcesPath, _2_t_languageCode);

  if (SysUtils.FileExists(_t_languageFilePath)) then
    loadFile(_t_languageFilePath)
  else
    loadLanguageFolder(_t_resourcesPath, _2_t_languageCode);
end;

function localizedString(const _1_t_resName: string): string;
var
  _t_key: string;
  _e_index: Int64;
begin
  InternalEnsureStore;

  _t_key := InternalNormalizeKey(_1_t_resName);
  _e_index := _o_translations.IndexOfName(_t_key);

  if (_e_index < 0) then
    Exit(_1_t_resName);

  Result := _o_translations.ValueFromIndex[_e_index];
end;

function isLoaded: Boolean;
begin
  Result := (_o_translations <> nil) and (_o_translations.Count > 0);
end;

function loadedCount: Int64;
begin
  if (_o_translations = nil) then
    Exit(0);

  Result := _o_translations.Count;
end;

initialization
  InternalEnsureStore;

finalization
  clear;

end.
