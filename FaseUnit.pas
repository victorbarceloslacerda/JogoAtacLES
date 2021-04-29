unit FaseUnit;

interface

// Classe que concentra os dados de uma fase
type
  Fase = class
  private
  public
    // Zonas de poss�vel origem dos aliens
    origem_cima: Boolean;
    origem_baixo: Boolean;
    origem_esquerda: Boolean;
    origem_direita: Boolean;
    // Nome da m�sica da fase
    caminho_musica: String;
    // Historia curta da fase
    historia: String;
  end;

implementation

end.
