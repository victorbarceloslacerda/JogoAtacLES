unit PrincipalUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Imaging.pngimage,
  Vcl.StdCtrls, Vcl.MPlayer,
  ConstantesUnit, XMLManipUnit, ArquivosUnit, FaseUnit, AlienUnit, JanelinhaUnit, RegPontuacaoUnit, HistoricoUnit;

// Formul�rio Principal do Jogo
type
  TForm1 = class(TForm)
    nuttyvision: TImage;
    painel: TPanel;
    nave: TImage;
    processamento: TTimer;
    tiro: TPanel;
    pontuacao: TLabel;
    energia: TLabel;
    fundo1: TImage;
    fundo2: TImage;
    icone_vida: TImage;
    visor_vidas: TLabel;
    tocador: TMediaPlayer;
    sons: TMediaPlayer;
    ctrl_tocador: TTimer;
    hitbox: TPanel;
    barreira: TPanel;
    cronometro: TTimer;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure processamentoTimer(Sender: TObject);
    procedure ctrl_tocadorTimer(Sender: TObject);
    procedure cronometroTimer(Sender: TObject);
  private
    function criar_alien: Alien;
    procedure atirar;
    procedure tratar_tiro_jogador;
    procedure tratar_colisoes;
    function deu_colisao(a, b: TComponent): Boolean;
    function testar_colisao(a, b: TControl): Boolean;
    procedure mover_fundo;
    procedure mover_inimigos;
    procedure atualizar_pontos;
    procedure atualizar_energia;
    procedure atualizar_vidas;
    function icone_alien_por_fase: String;
    procedure morrer;
    procedure limpar_inimigos;
    procedure preparar_fase;
    procedure definir_posicoes_do_alien(var alvo: Alien);
    procedure configurar_fases_pre_programadas;
    procedure configurar_variaveis_de_controle;
    procedure avancar_fase;
    procedure tocar_musica(arquivo: String);
    procedure tocar_som(arquivo: String);
    procedure tratar_tiros_inimigos;
    function escolher_alien_aleatorio(quant_aliens: Integer): Integer;
    function contar_tiros_inimigos: Integer;
    procedure mover_tiros_inimigos;
    procedure mover_nave(x, y: Integer);
    procedure inicializar_jogo;
    procedure registrar_historico;
    procedure inicializar_historico;
    procedure salvar_estado;
    function precisa_restaurar: Boolean;
    procedure restaurar_sessao;
    procedure fechar_jogo;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  // Formul�rio
  Form1: TForm1;
  // Vari�veis de controle
  pausa: Boolean;
  movimento_fundo: Integer;
  movimento: Integer;
  tiro_lancado: Boolean;
  limite_tiros_inimigos: Integer;
  n_fase: Integer;
  cont_aliens: Integer;
  pontos: Integer;
  energia_max: Integer;
  cont_energia: Integer;
  vidas: Integer;
  invencivel: Boolean;
  tempo_de_jogo: Integer;
  // Hist�rico do jogador
  hist: Historico;
  // Fases pr�-programadas
  fase01: Fase;
  fase02: Fase;
  fase03: Fase;
  // Fase sendo executada
  fase_atual: Fase;
  // Indicador de restaura��o de sess�o
  restaurar: Boolean;
  completar_energia: Boolean;

implementation

{$R *.dfm}

// Utilidade para teste de pontos de checagem
procedure depurar(ponto: Integer);
begin
  ShowMessage('Ponto: ' + IntToStr(ponto));
end;

// Evento que dispara a inicializa��o do jogo
procedure TForm1.FormCreate(Sender: TObject);
begin
  restaurar := False;
  completar_energia := True;
  inicializar_jogo();
end;

// Inicializa��o do jogo, suas vari�veis, fases e etc.
procedure TForm1.inicializar_jogo();
begin
  // Previnindo a piscagem das imagens
  DoubleBuffered := True;
  // Configurando o intervalo de processamento do jogo
  processamento.Interval := INTERVALO_PROCESSAMENTO_MS;
  // Inicializando hist�rico de jogo
  inicializar_historico();
  // Inicializando vari�veis de controle
  configurar_variaveis_de_controle();
  // Configura��o de fases pr�-programadas
  configurar_fases_pre_programadas();
  // Verifique se � preciso restaurar o jogo anterior
  if(precisa_restaurar() = True) then
  begin
    // Antes de restaurar, indique que a energia n�o deve ser reposta
    completar_energia := False;
    // Restaura sess�o de acordo com o estado salvo
    restaurar_sessao();
  end;
  // Inicializar visores
  atualizar_pontos();
  atualizar_vidas();
  atualizar_energia();
  // Ativar temporizador de processamento do jogo
  processamento.Enabled := True;
end;

// Utilidade que inicializa os dados do hist�rico de jogo
procedure TForm1.inicializar_historico();
begin
  hist := Historico.Create();
  hist.data := '';
  hist.tempo := 0;
  hist.pont_pre := 0;
  hist.pont_pos := 0;
end;

// Prov� os valores iniciais para as vari�veis de controle
procedure TForm1.configurar_variaveis_de_controle();
begin
  pausa := True;
  movimento_fundo := 1;
  movimento := 8;
  tiro_lancado := False;
  limite_tiros_inimigos := 0;
  n_fase := 0;
  cont_aliens := 0;
  pontos := 0;
  energia_max := 100;
  cont_energia := energia_max;
  vidas := 3;
  invencivel := False;
  tempo_de_jogo := 0;
end;

// Configura fases pr�-programas com dificuldade crescente
procedure TForm1.configurar_fases_pre_programadas();
begin
  { A configura��o de uma fase compreende a especifica��o
    das zonas de origem dos aliens, da especifica��o da
    m�sica da fase e de sua hist�ria }

  // Configurando a Fase 01
  fase01 := Fase.Create;
  fase01.origem_cima := True;
  fase01.origem_baixo := False;
  fase01.origem_esquerda := False;
  fase01.origem_direita := False;
  fase01.caminho_musica := 'Waterflame - Electroman Adventures.mp3';
  fase01.historia := 'COMUNICADO: TU PILOTO DEFESA PLANETA NADAVER ESQUADRAO ABATIDO VOCE ULTIMA ESPERANCA BATALHA';

  // Configurando a Fase 02
  fase02 := Fase.Create;
  fase02.origem_cima := False;
  fase02.origem_baixo := False;
  fase02.origem_esquerda := True;
  fase02.origem_direita := True;
  fase02.caminho_musica := 'Kitsune2 - Never Want to Be a Hero.mp3';
  fase02.historia := 'COMUNICADO: ALIENS PASSARAM ONDA + FORTE CUIDADO DEFESAS SE VIRAM AQUI FOCO FOCO FOCO';

  // Configurando a Fase 03
  fase03 := Fase.Create;
  fase03.origem_cima := True;
  fase03.origem_baixo := False;
  fase03.origem_esquerda := True;
  fase03.origem_direita := True;
  fase03.caminho_musica := 'TomboFry - Grayscale.mp3';
  fase03.historia := 'COMUNICADO: NADAVER VENCER BATALHA MUITAS PERDAS NAO DEIXAR ULTIMA ONDA PASSAR!';

  // Inicializando dados de fase atual
  fase_atual := Fase.Create;
  fase_atual.origem_cima := False;
  fase_atual.origem_baixo := False;
  fase_atual.origem_esquerda := False;
  fase_atual.origem_direita := False;
  fase_atual.caminho_musica := '';
  fase_atual.historia := '';
end;

// Salva o estado do jogo em um formato XML
procedure TForm1.salvar_estado();
var
  xml: String;
begin
  xml := '';
  // Salvando vari�veis de controle
  xml := xml + envelopar_tag(TAG_CONTROLE_PAUSA, BoolToStr(pausa));
  xml := xml + envelopar_tag(TAG_CONTROLE_MOVIMENTO_FUNDO, IntToStr(movimento_fundo));
  xml := xml + envelopar_tag(TAG_CONTROLE_MOVIMENTO, IntToStr(movimento));
  xml := xml + envelopar_tag(TAG_CONTROLE_TIRO_LANCADO, BoolToStr(tiro_lancado));
  xml := xml + envelopar_tag(TAG_CONTROLE_LIMITE_TIROS_INIMIGOS, IntToStr(limite_tiros_inimigos));
  xml := xml + envelopar_tag(TAG_CONTROLE_N_FASE, IntToStr(n_fase));
  xml := xml + envelopar_tag(TAG_CONTROLE_CONT_ALIENS, IntToStr(cont_aliens));
  xml := xml + envelopar_tag(TAG_CONTROLE_PONTOS, IntToStr(pontos));
  xml := xml + envelopar_tag(TAG_CONTROLE_ENERGIA_MAX, IntToStr(energia_max));
  xml := xml + envelopar_tag(TAG_CONTROLE_CONT_ENERGIA, IntToStr(cont_energia));
  xml := xml + envelopar_tag(TAG_CONTROLE_VIDAS, IntToStr(vidas));
  xml := xml + envelopar_tag(TAG_CONTROLE_INVENCIVEL, BoolToStr(invencivel));
  xml := xml + envelopar_tag(TAG_CONTROLE_TEMPO_DE_JOGO, IntToStr(tempo_de_jogo));
  // Salvando hist�rico de jogo
  xml := xml + envelopar_tag(TAG_HISTORICO_DATA, hist.data);
  xml := xml + envelopar_tag(TAG_HISTORICO_TEMPO, IntToStr(hist.tempo));
  xml := xml + envelopar_tag(TAG_HISTORICO_PONT_PRE, IntToStr(hist.pont_pre));
  xml := xml + envelopar_tag(TAG_HISTORICO_PONT_POS, IntToStr(hist.pont_pos));
  // Salvando a fase atual
  xml := xml + envelopar_tag(TAG_FASE_ATUAL_CAMINHO_MUSICA, fase_atual.caminho_musica);
  xml := xml + envelopar_tag(TAG_FASE_ATUAL_HISTORIA, fase_atual.historia);
  xml := xml + envelopar_tag(TAG_FASE_ATUAL_ORIGEM_CIMA, BoolToStr(fase_atual.origem_cima));
  xml := xml + envelopar_tag(TAG_FASE_ATUAL_ORIGEM_BAIXO, BoolToStr(fase_atual.origem_baixo));
  xml := xml + envelopar_tag(TAG_FASE_ATUAL_ORIGEM_ESQUERDA, BoolToStr(fase_atual.origem_esquerda));
  xml := xml + envelopar_tag(TAG_FASE_ATUAL_ORIGEM_DIREITA, BoolToStr(fase_atual.origem_direita));
  // Envelopando todo o estado em um recipiente
  xml := envelopar_tag(TAG_SESSAO_ESTADO, xml);
  // Salvando o indicador de restaura��o
  xml := envelopar_tag(TAG_SESSAO_RESTAURAR, BoolToStr(restaurar)) + xml;
  // Atualize o arquivo no sistema de arquivos
  escrever_no_arquivo(ARQ_DADOS_XML, xml, False);
end;

// Utilidade que indica a imagem usada pelos aliens de acordo com a fase a ser jogada
function TForm1.icone_alien_por_fase(): String;
begin
  if(n_fase = 1) then
    Result := 'alien1.png';
  if(n_fase = 2) then
    Result := 'alien2.png';
  if(n_fase > 2) then
    Result := 'alien3.png';
end;

// Utilidade para criar/alocar, configurar e disponibilizar um alien para uso
function TForm1.criar_alien(): Alien;
var
  temp_alien: Alien;
begin
  // Alien criado/alocado
  temp_alien := Alien.Create(Form1);
  // Alien disponibilizado na tela
  temp_alien.Parent := Form1;
  // Configurando alien
  temp_alien.Width := TAMANHO_SPRITE;
  temp_alien.Height := TAMANHO_SPRITE;
  temp_alien.Left := Form1.Width - temp_alien.Width;
  temp_alien.Top := 0;
  temp_alien.Tag := ID_INIMIGO;
  temp_alien.Picture.LoadFromFile(CAMINHO_RECURSOS + icone_alien_por_fase());
  temp_alien.espera_pre_entrada := (1000 Div INTERVALO_PROCESSAMENTO_MS) * (Random(10) + 1);
  temp_alien.espera_pre_entrada_mod := temp_alien.espera_pre_entrada;
  temp_alien.ja_atirou := True;
  // Disponibilizando alien para uso
  Result := temp_alien;
end;

// Utilidade que contabiliza o tempo de jogo do jogador
procedure TForm1.cronometroTimer(Sender: TObject);
begin
  // Contabilize o tempo apenas se o jogo estiver correndo
  if(pausa = False) then
    Inc(tempo_de_jogo);
end;

// Utilidade para replay autom�tico de m�sica
procedure TForm1.ctrl_tocadorTimer(Sender: TObject);
begin
  tocador.Play();
end;

// Utilidade para tocar um efeito sonoro
procedure TForm1.tocar_som(arquivo: String);
begin
  sons.FileName := arquivo;
  sons.Open();
  sons.Play();
end;

// Evento que dispara o processamento de teclas pressionadas e suas a��es
procedure TForm1.FormKeyPress(Sender: TObject; var Key: Char);
begin
  // (Des)Pausar
  if(Key = 'p') then
  begin
    pausa := not pausa;
  end;
  // Controles permitidos apenas em jogo despausado
  if(pausa = False) then
  begin
    // Controles permitidos apenas em modo avan�ado (ap�s a terceira fase)
    if(n_fase > 3) then
    begin
      // Mover para cima
      if(Key = 'w') then
      begin
        if((nave.Top - movimento) > (0 + 48)) then mover_nave(nave.Left, nave.Top - movimento);
      end;
      // Mover para baixo
      if(Key = 's') then
      begin
        if((nave.Top + movimento) < (335 - nave.Height)) then mover_nave(nave.Left, nave.Top + movimento);
      end;
    end;
    // Mover para esquerda
    if(Key = 'a') then
    begin
      if(nave.Left > 0) then mover_nave(nave.Left - movimento, nave.Top);
    end;
    // Mover para direita
    if(Key = 'd') then
    begin
      if(nave.Left < (640 - nave.Width)) then mover_nave(nave.Left + movimento, nave.Top);
    end;
    // Atirar
    if(Key = ' ') then
    begin
      atirar();
    end;
    // Incrementar o n�mero indicador da fase
    if(Key = 'm') then
    begin
      Inc(n_fase);
    end;
    // (Des)Ativar trapa�a da barreira
    if(Key = 'n') then
    begin
      barreira.Visible := not barreira.Visible;
    end;
    // (Des)Ativar invencibilidade
    if(Key = 'b') then
    begin
      invencivel := not invencivel;
    end;
    // Alternar visibilidade da hitbox da nave
    if(Key = 'v') then
    begin
      hitbox.Visible := not hitbox.Visible;
    end;
  end;
end;

// Utilidade que aciona o processamento de um tiro
procedure TForm1.atirar();
begin
  // Se um tiro j� tiver sido lan�ado e seu processamento n�o tiver acabado, n�o permita um novo lan�amento
  if(tiro_lancado = False) then
  begin
    // Se o tiro n�o tiver sido lan�ado, marque-o como lan�ado
    tiro_lancado := True;
    // Toque o efeito sonoro caracter�stico do tiro
    tocar_som(CAMINHO_RECURSOS + 'Tiro.mp3');
    // Configure seu posicionamento de acordo com a nave
    tiro.Left := (nave.Left + (nave.Width div 2));
    tiro.Top := nave.Top;
    // Habilite a visibilidade do tiro (habilitando-o para colis�es)
    tiro.Visible := True;
    // O processamento do tiro � cuidado por outra utilidade
  end;
end;

// Utilidade que processa o tiro do jogador assim que ele � marcado como lan�ado
procedure TForm1.tratar_tiro_jogador();
begin
  // Se o tiro estiver marcado como lan�ado
  if(tiro_lancado = True) then
  begin
    // Movimente o tiro para cima constantemente
    tiro.Top := tiro.Top - movimento;
    // Mova o tiro horizontalmente de acordo com a nave (caracteristica do Megamania/Atack original)
    Tiro.Left := (nave.Left + (nave.Width div 2));
    // Verifique se o tiro chegou � zona morta designada
    if(tiro.Top < -(tiro.Height)) then
    begin
      // Desative a vari�vel de controle de tiro lan�ado e torne-o invis�vel (desabilita colis�es)
      tiro_lancado := False;
      tiro.Visible := False;
    end;
  end;
end;

// Utilidade que escolhe um alien aleat�rio dentre os alocados para a fase
function TForm1.escolher_alien_aleatorio(quant_aliens: Integer): Integer;
var
  indice: Integer;
  cont: Integer;
begin
  // Parta do princ�pio que o alien pode n�o ser encontrado
  Result := -1;
  // Indique um alien aleat�rio dentre a quantidade de aliens dispon�veis
  indice := Random(quant_aliens) + 1;
  // Prepare-se para percorrer os aliens dispon�veis
  cont := 0;
  // Se tiver algum alien dispon�vel
  if(quant_aliens > 0) then
  begin
    // Enquanto n�o chegarmos no �ndice indicado
    while(indice > 0) do
    begin
      // Percorra todos os componentes do formul�rio
      while(cont < ComponentCount) do
      begin
        // Se o componente considerado for um alien (com ID de inimigo), decremente o �ndice
        if(components[cont].Tag = ID_INIMIGO) then
          Dec(indice);
        // Se o �ndice chegou a zero, este � o alien aleat�rio que buscamos
        if(indice = 0) then
        begin
          // Indique este �ndice de componente do formul�rio como o alien aleat�rio que queremos
          Result := cont;
          // Quebre o la�o
          break;
        end;
        // Se ainda n�o encontramos o alien, passe para o pr�ximo componente do formul�rio
        Inc(cont);
      end;
      // Redefina o contador de componentes (para percorrer os componentes do formul�rio novamente)
      cont := 0;
    end;
  end;
  // Se, pra in�cio de conversa, n�o t�nhamos um alien, o �ndice de componente j� est� como -1
end;

// Conta quantos tiros inimigos foram lan�ados pelos aliens
function TForm1.contar_tiros_inimigos(): Integer;
var
  cont: Integer;
begin
  // Inicialize o contador para percorrer os componentes do formul�rio
  cont := 0;
  // Parta do princ�pio que nenhum tiro inimigo foi disparado
  Result := 0;
  // Percorra os componentes do formul�rio
  while(cont < ComponentCount) do
  begin
    // Se encontrarmos um tiro, incremente o contador de tiros
    if(components[cont].Tag = ID_TIRO_INIMIGO) then
      Inc(Result);
    // Avance para o pr�ximo componente
    Inc(cont);
  end;
end;

// Utilidade que move os tiros de inimigos lan�ados
procedure TForm1.mover_tiros_inimigos();
var
  cont: Integer;
  temp_tiro: TControl;
begin
  // Contador para percorrer os componentes do formul�rio
  cont := 0;
  // Percorra os componentes do formul�rio
  while(cont < ComponentCount) do
  begin
    // Se o componente considerado for um tiro
    if(components[cont].Tag = ID_TIRO_INIMIGO) then
    begin
      // Converta-o para o tipo de componente adequado
      temp_tiro := components[cont] As TControl;
      // Mova o tiro pela tela
      temp_tiro.Top := temp_tiro.Top + movimento + (movimento Div 3);
      // Se o tiro chegar na zona morta designada, desaloque-o
      if(temp_tiro.Top > temp_tiro.Parent.Height) then
        temp_tiro.Free();
    end;
    // Avance para o pr�ximo componente
    Inc(cont);
  end;
end;

// Utilidade que cria, move e deleta tiros inimigos
procedure TForm1.tratar_tiros_inimigos();
var
  temp_alien: Alien;
  indice: Integer;
begin
  // Escolha um alien aleat�rio
  indice := escolher_alien_aleatorio(cont_aliens);
  // Se um alien tiver sido escolhido com sucesso
  if(indice >= 0) then
  begin
    // Consiga o componente do �ndice indicado e converta-o para o tipo apropriado
    temp_alien := components[indice] As Alien;
    // Se o n�mero de tiros inimigos em vig�ncia for menor do que o total permitido para a fase
    if(contar_tiros_inimigos() < limite_tiros_inimigos) then
    begin
      // Fa�a com que o alien aleat�rio atire
      temp_alien.atirar();
    end;
  end;
  // Independente de ter feito um alien atirar ou n�o, procure por tiros em vig�ncia e mova-os
  mover_tiros_inimigos();
end;

// Utilidade para mover a nave do jogador de forma padronizada
procedure TForm1.mover_nave(x, y: Integer);
begin
  // Mova a nave para as coordenadas especificadas
  nave.Left := x;
  nave.Top := y;
  // Da mesma forma, mova a hitbox da nave junto a ela
  hitbox.Left := nave.Left + ((nave.Width Div 2) - (hitbox.Width) Div 2);
  hitbox.Top := nave.Top;
end;

// Utilidade que cuida das tarefas a serem realizadas quando a nave do jogador colide
procedure TForm1.morrer();
begin
  // Ative a invencibilidade para evitar eventuais colis�es
  invencivel := True;
  // Penalize uma vida do jogador
  Dec(vidas);
  // Toque o som da explos�o caracter�stico
  tocar_som(CAMINHO_RECURSOS + 'Explosao.mp3');
  // Redefina o contador de energia para o m�ximo
  cont_energia := energia_max;
  // Mova a nave para a posi��o inicial
  mover_nave(296, 290);
  // Atualize os visores de vida e energia
  atualizar_vidas();
  atualizar_energia();
  // Limpe os inimigos da tela para dar tempo de rea��o ao jogador
  limpar_inimigos();
  // Desabilite a invencibilidade porque o cen�rio j� est� seguro
  invencivel := False;
end;

// Remove os inimigos da parte vis�vel da tela de forma a dar tempo de rea��o ao jogador
procedure TForm1.limpar_inimigos();
var
  cont: Integer;
  temp_alien: Alien;
begin
  // Contador gen�rico
  cont := 0;
  // Percorra os componentes do formul�rio
  while(cont < ComponentCount) do
  begin
    // Se o componente considerado for um tiro dos inimigos
    if(components[cont].Tag = ID_TIRO_INIMIGO) then
    begin
      // Simplesmente remova-os
      components[cont].Free;
      // O vetor de componentes foi atualizado, recomece
      cont := 0;
    end;
    // Se o componente considerado for um inimigo
    if(components[cont].Tag = ID_INIMIGO) then
    begin
      // Inteprete o componente como um alien
      temp_alien := components[cont] as Alien;
      // Retorne o alien para a origem na devida zona de origem
      temp_alien.voltar_pra_origem();
      // Redefina o tempo de espera pr� entrada em tela
      temp_alien.espera_pre_entrada_mod := temp_alien.espera_pre_entrada;
    end;
    // Avance para o pr�ximo componente
    Inc(cont);
  end;
end;

// Utilidade que trata colis�es caso elas tenham acontecido
procedure TForm1.tratar_colisoes();
var
  cont1: Integer;
  cont2: Integer;
begin
  // Contadores gen�ricos para percorrer o vetor de componentes do formul�rio
  cont1 := 0;
  cont2 := 0;
  // Percorrer componentes (achar jogador ou tiro)
  while(cont1 < ComponentCount) do
  begin
    // Achar jogador ou tiro
    if((components[cont1].Tag = ID_JOGADOR) or (components[cont1].Tag = ID_TIRO_JOGADOR)) then
    begin
      // Percorrer componentes (achar inimigos ou seus tiros)
      while(cont2 < ComponentCount) do
      begin
        // Achar inimigos ou seus tiros
        if((components[cont2].Tag = ID_INIMIGO) or (components[cont2].Tag = ID_TIRO_INIMIGO)) then
        begin
          // Verifica colis�o
          if(deu_colisao(components[cont1], components[cont2]) = True) then
          begin
            // Jogador envolvido
            if((components[cont1].Tag = ID_JOGADOR) and (invencivel = False)) then
            begin
              // Execute as rotinas da morte do jogador
              morrer();
            end;
            // Tiro do jogador envolvido
            if((components[cont1].Tag = ID_TIRO_JOGADOR) and ((components[cont1] As TControl).Visible = True)) then
            begin
              // Incremente os pontos do acerto do tiro do jogador
              Inc(pontos, 100);
              // Atualize o visor de pontos
              atualizar_pontos();
              // Toque o som de explos�o devido � colis�o
              tocar_som(CAMINHO_RECURSOS + 'Explosao.mp3');
              // Se o componente atingido for um alien, decremente o contador de aliens
              if(components[cont2].Tag = ID_INIMIGO) then
                Dec(cont_aliens);
              // Desaloque o componente independente de ser alien ou tiro de alien
              components[cont2].Free();
              // Se o componente com ID de tiro for mesmo o tiro (e n�o a barreira de trapa�a)
              if(components[cont1].Name = 'tiro') then
              begin
                // Desabilite as colis�es deste tiro e coloque ele pr�ximo � zona morta
                tiro.Visible := False;
                tiro.Top := 0;
              end;
            end;
          end;
        end;
        // Avance para o pr�ximo componente (inimigos e seus tiros)
        Inc(cont2);
      end;
    end;
    // Avance para o pr�ximo componente (jogador e seu tiro)
    Inc(cont1);
    // Recomece a busca por inimigos e seus tiros
    cont2 := 0;
  end;
end;

// Utilidade que testa de v�rias formas se houve uma colis�o entre dois componentes
function TForm1.deu_colisao(a, b: TComponent): Boolean;
var
  ac, bc: TControl;
begin
  // Converta os componentes para o tipo apropriado
  ac := a As TControl;
  bc := b As TControl;
  // Teste colis�es tendo como base os dois componentes, um a cada vez
  Result := (testar_colisao(ac, bc) or testar_colisao(bc, ac));
end;

// Utilidade que detecta uma colis�o
function TForm1.testar_colisao(a, b: TControl): Boolean;
begin
  // Teste se houve uma colis�o ou n�o e retorne o resultado l�gico
  if((a.Left < (b.Left + b.Width)) and ((a.Left + a.Width) > b.Left) and (a.Top < (b.Top + b.Height)) and ((a.Top + a.Height) > b.Top)) then
    Result := True
  else
    Result := False;
end;

// Utilidade que move o fundo da fase continuamente
procedure TForm1.mover_fundo();
begin
  // Mova o fundo com velocidade de acordo com a fase
  fundo1.Top := fundo1.Top + ((movimento Div 2) * (n_fase + 1));
  fundo2.Top := fundo2.Top + ((movimento Div 2) * (n_fase + 1));
  // Se os fundos chegarem � zona morta inferior, mova-os para a zona morta superior
  if(fundo1.Top > fundo1.Height) then
    fundo1.Top := -fundo1.Height;
  if(fundo2.Top > fundo2.Height) then
    fundo2.Top := -fundo2.Height;
end;

// Utilidade que move os inimigos pela tela
procedure TForm1.mover_inimigos();
var
  cont: Integer;
  temp_alien: Alien;
begin
  // Contador gen�rico
  cont := 0;
  // Percorra o vetor de componentes do formul�rio
  while(cont < ComponentCount) do
  begin
    // Caso o componente seja um alien
    if(components[cont].Tag = ID_INIMIGO) then
    begin
      // Trate-o como alien e mova-o de acordo com suas especifica��es
      temp_alien := (components[cont] As Alien);
      temp_alien.mover();
    end;
    // Avance para o pr�ximo componente
    Inc(cont);
  end;
end;

// Utilidade que atualiza o visor de pontos
procedure TForm1.atualizar_pontos();
begin
  pontuacao.Caption := 'Pontos: ' + IntToStr(pontos);
end;

// Utilidade que atualiza o visor de energia
procedure TForm1.atualizar_energia();
var
  cont: Integer;
  caracteres: Integer;
  limite: Integer;
begin
  // Extraia uma os limites de contadores para cria��o da barra a partir do contador de energia
  cont := 0;
  caracteres := (cont_energia * 100) Div energia_max;
  limite := 100 Div 3;
  caracteres := caracteres Div 3;
  energia.Caption := 'Energia: ';
  // Preencha a barra de acordo com a energia dispon�vel
  while(cont < caracteres) do
  begin
    energia.Caption := energia.Caption + '#';
    Inc(cont);
  end;
  while(cont < limite) do
  begin
    energia.Caption := energia.Caption + '-';
    Inc(cont);
  end;
  // Se a energia do jogador acabar, execute as rotinas de morte
  if(cont_energia <= 0) then
    morrer();
end;

// Utilidade para atualiza o visor de vidas do jogador
procedure TForm1.atualizar_vidas();
begin
  visor_vidas.Caption := 'x' + IntToStr(vidas);
end;

// Definir as posi��es de origem e movimenta��o de um alien de acordo com as zonas de origem da fase atual
procedure TForm1.definir_posicoes_do_alien(var alvo: Alien);
var
  zona: Integer;
  achado: Boolean;
begin
  zona := 0;
  // Parta do pressuposto que n�o achamos a zona ainda
  achado := False;
  // Enquanto n�o tivermos achado
  while(achado = False) do
  begin
    // Tente uma zona aleat�ria
    zona := Random(4) + 1;
    // Teste se cada zona est� disposta a ser usada, se estiver, achamos nossa zona de origem
    case zona of
      ZONA_CIMA    : achado := fase_atual.origem_cima;
      ZONA_BAIXO   : achado := fase_atual.origem_baixo;
      ZONA_ESQUERDA: achado := fase_atual.origem_esquerda;
      ZONA_DIREITA : achado := fase_atual.origem_direita;
    end;
  end;
  // Dependendo da zona escolhida, atualize a posi��o de origem e coordenadas de movimento do alien
  case zona of
    ZONA_CIMA    : alvo.atualizar_coordenadas((Random(576) + TAMANHO_SPRITE), -(TAMANHO_SPRITE), 0, (movimento Div 2));
    ZONA_BAIXO   : alvo.atualizar_coordenadas((Random(576) + TAMANHO_SPRITE), (480 + TAMANHO_SPRITE), 0, -(movimento Div 2));
    ZONA_ESQUERDA: alvo.atualizar_coordenadas(-(TAMANHO_SPRITE), (Random(216) + TAMANHO_SPRITE), (movimento Div 2), 0);
    ZONA_DIREITA : alvo.atualizar_coordenadas((640 + TAMANHO_SPRITE), (Random(216) + TAMANHO_SPRITE), -(movimento Div 2), 0);
  end;
end;

// Utilidade que prepara a fase para ser jogada
procedure TForm1.preparar_fase();
var
  cont: Integer;
  temp_alien: Alien;
begin
  // Contador gen�rico
  cont := 0;
  // Crie todos os aliens necess�rios ao funcionamento da fase
  while(cont < cont_aliens) do
  begin
    // Crie um alein, defina suas posi��es e coloque-o na origem
    temp_alien := criar_alien();
    definir_posicoes_do_alien(temp_alien);
    temp_alien.voltar_pra_origem();
    // Parta para o pr�ximo alien
    Inc(cont);
  end;
  // Restaurar energia apenas se o jogo n�o estiver sendo restaurado
  if(completar_energia = True) then
  begin
    // Defina uma quantidade de energia m�ximo da acordo com a fase
    energia_max := (1000 Div INTERVALO_PROCESSAMENTO_MS) * 60 * (n_fase + 1);
    // Redefina o contador de energia para o m�ximo
    cont_energia := energia_max;
  end;
  completar_energia := True;
  // Especifique o limite do n�mero de tiros inimigos permitidos de acordo com a fase
  limite_tiros_inimigos := (FATOR_N_ALIENS * n_fase) Div 5;
  // Toque a m�sica da fase
  tocar_musica(CAMINHO_RECURSOS + fase_atual.caminho_musica);
end;

// Utilidade para tocar a m�sica de uma fase
procedure TForm1.tocar_musica(arquivo: String);
begin
  // Especifique o nome do arquivo a ser tocado e abra-o
  tocador.FileName := arquivo;
  tocador.Open();
  // Especifique o formato de tempo do tocador como sendo milissegundos
  tocador.TimeFormat := tfMilliseconds;
  // Defina o intervalo do temporizador como a dura��o da m�sica mais 100 milissegundos
  ctrl_tocador.Interval := tocador.Length + 100;
  // Toque a m�sica
  tocador.Play();
  // Ative o temporizador (para garantir o replay infinito)
  ctrl_tocador.Enabled := True;
end;

// Utilidade que cuida das rotinas do avan�o de fases
procedure TForm1.avancar_fase();
begin
  // Contabilize a fase avan�ada
  Inc(n_fase);
  // Estabele�a o n�mero de aliens a ser alocados para esta fase de acordo com seu n�mero e o fator de aliens
  cont_aliens := (n_fase * FATOR_N_ALIENS);
  // Caso o n�mero da fase seja um n�mero de um a tr�s, carregue as fases pr�-programadas
  case n_fase of
    1: fase_atual := fase01;
    2: fase_atual := fase02;
    3: fase_atual := fase03;
  // Caso o n�mero da fase seja um n�mero maior que tr�s, crie uma fase com o n�vel m�ximo de dificuldade, hist�ria e m�sica pr�prias
  else
    fase_atual.origem_cima := True;
    fase_atual.origem_baixo := True;
    fase_atual.origem_esquerda := True;
    fase_atual.origem_direita := True;
    fase_atual.caminho_musica := 'Triac - Eat Your Bricks.mp3';
    fase_atual.historia := 'COMUNICADO: Voc� venceu a guerra, agora retorne para casa s�o e salvo.';
  end;
  // Prepare a fase para ser jogada
  preparar_fase();
  // Pause o programa inteiro por um segundo
  Sleep(1000);
end;

// Utilidade que registra os dados do hist�rico da sess�o de jogo
procedure TForm1.registrar_historico();
begin
  if((n_fase < 4) and (n_fase > 0)) then
    hist.pont_pre := pontos
  else
    hist.pont_pos := pontos - hist.pont_pre;
  hist.tempo := tempo_de_jogo;
  hist.data := DateToStr(Date);
end;

// Verifica se o jogo foi abortado na sess�o anterior
function TForm1.precisa_restaurar(): Boolean;
var
  xml: String;
begin
  xml := ler_do_arquivo(ARQ_DADOS_XML);
  if(Length(xml) > 0) then
    Result := StrToBool(extrair_valor_tag(xml, TAG_SESSAO_RESTAURAR))
  else
  begin
    salvar_estado();
    Result := False;
  end;
end;

// Restaura a sess�o do jogo de acordo com o estado salvo
procedure TForm1.restaurar_sessao();
var
  xml: String;
begin
  // Consiga os dados do arquivo XML
  xml := ler_do_arquivo(ARQ_DADOS_XML);
  // Verifique se o conte�do � v�lido
  if(Length(xml) > 0) then
  begin
    // Restaure as vari�veis de controle
    pausa := StrToBool(extrair_valor_tag(xml, TAG_CONTROLE_PAUSA));
    movimento_fundo := StrToInt(extrair_valor_tag(xml, TAG_CONTROLE_MOVIMENTO_FUNDO));
    movimento := StrToInt(extrair_valor_tag(xml, TAG_CONTROLE_MOVIMENTO));
    tiro_lancado := StrToBool(extrair_valor_tag(xml, TAG_CONTROLE_TIRO_LANCADO));
    limite_tiros_inimigos := StrToInt(extrair_valor_tag(xml, TAG_CONTROLE_LIMITE_TIROS_INIMIGOS));
    n_fase := StrToInt(extrair_valor_tag(xml, TAG_CONTROLE_N_FASE));
    cont_aliens := StrToInt(extrair_valor_tag(xml, TAG_CONTROLE_CONT_ALIENS));
    pontos := StrToInt(extrair_valor_tag(xml, TAG_CONTROLE_PONTOS));
    energia_max := StrToInt(extrair_valor_tag(xml, TAG_CONTROLE_ENERGIA_MAX));
    cont_energia := StrToInt(extrair_valor_tag(xml, TAG_CONTROLE_CONT_ENERGIA));
    vidas := StrToInt(extrair_valor_tag(xml, TAG_CONTROLE_VIDAS));
    invencivel := StrToBool(extrair_valor_tag(xml, TAG_CONTROLE_INVENCIVEL));
    tempo_de_jogo := StrToInt(extrair_valor_tag(xml, TAG_CONTROLE_TEMPO_DE_JOGO));
    // Restaure os dados do hist�rico
    hist.data := extrair_valor_tag(xml, TAG_HISTORICO_DATA);
    hist.tempo := StrToInt(extrair_valor_tag(xml, TAG_HISTORICO_TEMPO));
    hist.pont_pre := StrToInt(extrair_valor_tag(xml, TAG_HISTORICO_PONT_PRE));
    hist.pont_pos := StrToInt(extrair_valor_tag(xml, TAG_HISTORICO_PONT_POS));
    // Restaure os dados da fase em andamento
    fase_atual.caminho_musica := extrair_valor_tag(xml, TAG_FASE_ATUAL_CAMINHO_MUSICA);
    fase_atual.historia := extrair_valor_tag(xml, TAG_FASE_ATUAL_HISTORIA);
    fase_atual.origem_cima := StrToBool(extrair_valor_tag(xml, TAG_FASE_ATUAL_ORIGEM_CIMA));
    fase_atual.origem_baixo := StrToBool(extrair_valor_tag(xml, TAG_FASE_ATUAL_ORIGEM_BAIXO));
    fase_atual.origem_esquerda := StrToBool(extrair_valor_tag(xml, TAG_FASE_ATUAL_ORIGEM_ESQUERDA));
    fase_atual.origem_direita := StrToBool(extrair_valor_tag(xml, TAG_FASE_ATUAL_ORIGEM_DIREITA));
    // Prepare a fase para que o jogador j� entre pronto para a a��o
    preparar_fase();
  end
  else // Se o XML n�o for v�lido, informe um erro
    ShowMessage('Erro! Dados do estado inv�lidos! (XML)');
end;

// Evento que dispara todo o processamento do jogo
procedure TForm1.processamentoTimer(Sender: TObject);
begin
  // Se o jogo estiver pausado, n�o lance estas rotinas
  if(pausa = False) then
  begin
    // Se o jogo estiver correndo, indique uma pausa para bloquear essas rotinas para outras poss�veis threads
    pausa := True;
    // Realize o processamento padr�o de cada ciclo
    tratar_colisoes();
    mover_fundo();
    mover_inimigos();
    tratar_tiro_jogador();
    tratar_tiros_inimigos();
    // Desconte a energia do ciclo
    Dec(cont_energia);
    // Atualize o visor de energia
    atualizar_energia();
    // O jogo est� em pleno funcionamento, indique que restaura��o � necess�ria
    restaurar := True;
    // Indique o jogo como despausado ao fim do processamento
    pausa := False;
  end;
  // Se o contador de aliens da fase for ou chegar a zero
  if(cont_aliens <= 0) then
  begin
    // Bloqueie essas rotinas
    processamento.Enabled := False;
    // Se o jogo j� estiver no meio da sess�o
    if(n_fase > 0) then
    begin
      // Ao in�cio de cada fase, converta a energia que sobrou na anterior em pontos
      Inc(pontos, (cont_energia - ((cont_energia Mod 10) * 10)));
      // Atualize o visor de pontos
      atualizar_pontos();
    end;
    // Registre o hist�rico de jogabilidade b�sica (requisito do trabalho)
    registrar_historico();
    // Avance a fase pois o jogador destruiu todos os aliens ou nenhum alien foi alocao ainda
    avancar_fase();
    // Passe os dados da fase atual � janela de informa��es
    Form2.informar_fase(fase_atual);
    // Mostre a tela de informa��es e previna a continua��o do jogo enquanto ela n�o for fechada
    Form2.ShowModal();
    // Reabilite a execu��o do processamento do jogo
    processamento.Enabled := True;
    // Caso tenha sido pausado nas rotinas, indique o jogo como despausado
    pausa := False;
  end;
  // Caso as vidas do jogador acabem
  if(vidas <= 0) then
  begin
    // Bloqueie o processamento do jogo
    processamento.Enabled := False;
    // Registre o hist�rico do jogador
    registrar_historico();
    // Informe o hist�rico do jogador � janela de finaliza��o
    Form3.informar_historico(hist);
    // Mostre a janela de forma restritiva
    Form3.ShowModal();
    // Feche o jogo depois da finaliza��o
    fechar_jogo();
  end;
  // Salve o estado do jogo
  salvar_estado();
end;

// Fecha o jogo seguindo um procedimento padr�o
procedure TForm1.fechar_jogo();
begin
  restaurar := False;
  salvar_estado();
  Close();
end;

end.
