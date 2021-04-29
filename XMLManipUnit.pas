unit XMLManipUnit;

interface

uses
  SysUtils, StrUtils, Dialogs;

function formar_tag(nome: String; fechamento: Boolean): String;
function envelopar_tag_unica(nome: String): String;
function envelopar_tag(nome, valor: String): String;
function buscar_tag(xml, nome: String): String;
function extrair_valor_tag(xml, nome: String): String;

implementation

// Forma uma tag a partir de seu nome, seja ela de abertura ou fechamento
function formar_tag(nome: String; fechamento: Boolean): String;
begin
  if(fechamento = False) then
    Result := '<' + nome + '>'
  else
    Result := '</' + nome + '>';
end;

// Envelopa uma tag de autofechamento a partir de seu nome
function envelopar_tag_unica(nome: String): String;
begin
  Result := '<' + nome + ' />';
end;

// Envelopa um valor com tags de abertura e fechamento
function envelopar_tag(nome, valor: String): String;
begin
  Result := formar_tag(nome, False) + valor + formar_tag(nome, True);
end;

// Busca uma tag bruta no XML (tag + valor interno)
function buscar_tag(xml, nome: String): String;
var
  pos_ini: Integer;
  pos_fim: Integer;
begin
  pos_ini := Pos(formar_tag(nome, False), xml);
  pos_fim := Pos(formar_tag(nome, True), xml);
  if((pos_ini > 0) and (pos_fim > 0)) then
  begin
    pos_fim := (pos_fim + Length(formar_tag(nome, True))) - pos_ini;
    Result := Copy(xml, pos_ini, pos_fim);
  end
  else
    Result := '';
end;

// Extrai o valor de uma tag (desenvelopa)
function extrair_valor_tag(xml, nome: String): String;
var
  pos_ini: Integer;
  pos_fim: Integer;
  base: String;
begin
  pos_ini := Length(formar_tag(nome, False)) + 1;
  base := buscar_tag(xml, nome);
  pos_fim := Pos(formar_tag(nome, True), base) - pos_ini;
  if(Length(base) > 0) then
  begin
    Result := Copy(base, pos_ini, pos_fim);
  end
  else
    Result := '';
end;

end.
