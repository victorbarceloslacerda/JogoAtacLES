unit JanelinhaUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.pngimage,
  Vcl.ExtCtrls,
  ConstantesUnit, FaseUnit, ArquivosUnit;

type
  TForm2 = class(TForm)
    bot_manual: TButton;
    bot_historia: TButton;
    bot_pontos: TButton;
    dados: TMemo;
    nuttyvision: TImage;
    txt_apresenta: TLabel;
    procedure FormShow(Sender: TObject);
    procedure bot_manualClick(Sender: TObject);
    procedure bot_historiaClick(Sender: TObject);
    procedure bot_pontosClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    estado: Integer;
    dados_fase: Fase;
    pode_historiar: Boolean;
    procedure tratar_historia(dados_fase: Fase);
    procedure mudar_quadro;
    { Private declarations }
  public
    procedure informar_fase(dados: Fase);
    { Public declarations }
  end;

const
  // Estados da janela de visualiza��o de dados
  ESTADO_MANUAL = 1;
  ESTADO_HISTORIA = 2;
  ESTADO_PONTUACOES = 3;

var
  Form2: TForm2;

implementation

{$R *.dfm}

// Utilidade que recebe os dados da fase passados da janela principal
procedure TForm2.informar_fase(dados: Fase);
begin
  // Receba os dados da fase
  dados_fase := dados;
  // Se o modo da janela for o de hist�ria
  if(estado = ESTADO_HISTORIA) then
  begin
    // Mostre as informa��es
    pode_historiar := True;
    mudar_quadro();
  end;
end;

// Fun��o que muda os dados apresentados de acordo com o estado assumido pela janela
procedure TForm2.mudar_quadro();
begin
  dados.Clear();
  case estado of
    ESTADO_MANUAL    : dados.Lines.LoadFromFile(CAMINHO_RECURSOS + ARQ_MANUAL);
    ESTADO_HISTORIA  : if(pode_historiar = True) then tratar_historia(dados_fase);
    ESTADO_PONTUACOES: if(FileExists(ARQ_PONTUACOES) = True) then dados.Lines.LoadFromFile(ARQ_PONTUACOES) else escrever_no_arquivo(ARQ_PONTUACOES, CABECALHO_ARQ_PONT, False);
  end;
end;

// Muda os dados para mostrar a hist�ria da fase
procedure TForm2.bot_historiaClick(Sender: TObject);
begin
  estado := ESTADO_HISTORIA;
  mudar_quadro();
end;

// Muda os dados para mostrar o manual do jogo
procedure TForm2.bot_manualClick(Sender: TObject);
begin
  estado := ESTADO_MANUAL;
  mudar_quadro();
end;

// Muda os dados para mostrar as pontua��es do jogo
procedure TForm2.bot_pontosClick(Sender: TObject);
begin
  estado := ESTADO_PONTUACOES;
  mudar_quadro();
end;

// Utilidade que prepara a janela quando � aberta
procedure TForm2.FormShow(Sender: TObject);
begin
  mudar_quadro();
end;

// Compila os dados da fase para que sejam mostrados na tela de hist�ria
procedure TForm2.tratar_historia(dados_fase: Fase);
begin
  dados.Lines.Add('HIST�RIA');
  dados.Lines.Add('============================');
  dados.Lines.Add(dados_fase.historia);
  dados.Lines.Add('============================');
  dados.Lines.Add('ORIENTA��ES');
  if(dados_fase.origem_cima = True) then
    dados.Lines.Add('>> Os inimigos podem vir pela frente.');
  if(dados_fase.origem_baixo = True) then
    dados.Lines.Add('>> Os inimigos podem vir por tr�s.');
  if(dados_fase.origem_esquerda = True) then
    dados.Lines.Add('>> Os inimigos podem vir pela esquerda.');
  if(dados_fase.origem_direita = True) then
    dados.Lines.Add('>> Os inimigos podem vir pela direita.');
  if((dados_fase.origem_esquerda = True) or (dados_fase.origem_direita = True)) then
    dados.Lines.Add('>> Inimigos que v�m da direita ou esquerda podem atirar!');
  dados.Lines.Add('============================');
  dados.Lines.Add('M�sica da fase: ' + dados_fase.caminho_musica);
end;

// Configura a janela quando a mesma � criada
procedure TForm2.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  pode_historiar := False;
  estado := ESTADO_HISTORIA;
  mudar_quadro();
end;

end.
