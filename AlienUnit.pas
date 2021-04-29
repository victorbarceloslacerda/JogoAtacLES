unit AlienUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Imaging.pngimage,
  Vcl.StdCtrls, Vcl.MPlayer, ConstantesUnit;

type
  Alien = Class(TImage)
  private
  public
    movimento_x: Integer;
    movimento_y: Integer;
    origem_x: Integer;
    origem_y: Integer;
    espera_pre_entrada: Integer;
    espera_pre_entrada_mod: Integer;
    ja_atirou: Boolean;
    detentor: TForm;
    procedure mover();
    procedure atualizar_coordenadas(o_x, o_y, m_x, m_y: Integer);
    function esta_fora: Boolean;
    procedure voltar_pra_origem();
    procedure atirar();
    constructor Create(AOwner: TForm);
  end;

implementation

// Constrói o objeto do Alien
constructor Alien.Create(AOwner: TForm);
begin
  inherited Create(AOwner);
  detentor := AOwner;
end;

// Move o alien de acordo com suas coordenadas
procedure Alien.mover();
begin
  // Se o tempo antes da entrada tiver acabado, mova o alien
  if(espera_pre_entrada_mod = 0) then
  begin
    Top := Top + movimento_y;
    Left := Left + movimento_x;
    // Se o alien estiver na zona morta da tela, volte para a posição inicial
    if(esta_fora() = True) then
      voltar_pra_origem();
  end
  else
  begin
    // Se o tempo antes da entrada não tiver acabado, decremente-o
    Dec(espera_pre_entrada_mod);
  end;
end;

// Verifica se um alien está na zona morta da tela
function Alien.esta_fora(): Boolean;
var
  f_cima, f_baixo, f_esquerda, f_direita: Boolean;
begin
  Result := False;
  f_cima := False;
  f_baixo := False;
  f_esquerda := False;
  f_direita := False;
  if(Top < (-Height * 2)) then
    f_cima := True;
  if(Top > (Parent.Height + Height)) then
    f_baixo := True;
  if(Left < (-Width * 2)) then
    f_esquerda := True;
  if(Left > (Parent.Width + Width)) then
    f_direita := True;
  Result := (f_cima or f_baixo or f_esquerda or f_direita);
end;

// Faz com que o alien volte para sua posição original
procedure Alien.voltar_pra_origem();
begin
  Top := origem_y;
  Left := origem_x;
  ja_atirou := False;
end;

// Atualiza as coordenadas de movimento e posição dentro do alien
procedure Alien.atualizar_coordenadas(o_x, o_y, m_x, m_y: Integer);
begin
  origem_x := o_x;
  origem_y := o_y;
  movimento_x := m_x;
  movimento_y := m_y;
end;

// Cria um objeto de tiro disparado pelo alien
procedure Alien.atirar();
var
  temp_tiro: TImage;
begin
  if((movimento_x <> 0) and (ja_atirou = False) and (Top > 0) and (Top < 120) and (Left > 0) and (Left < 640)) then
  begin
    temp_tiro := TImage.Create(detentor);
    temp_tiro.Width := 5;
    temp_tiro.Height := 10;
    temp_tiro.Picture.LoadFromFile(CAMINHO_RECURSOS + 'tiroinimigo.png');
    temp_tiro.Parent := detentor;
    temp_tiro.Tag := ID_TIRO_INIMIGO;
    temp_tiro.Top := Top + (Height Div 2);
    temp_tiro.Left := Left + (Width Div 2);
    ja_atirou := True;
  end;
end;

end.
