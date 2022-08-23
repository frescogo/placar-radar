# FrescoGO! - Placar para o Radar

## Fluxo da Apresentação

- Um sino com 5 sons curtos indica que a uma nova apresentação irá começar.
- Um som agudo longo indica que o atleta pode sacar. Após 5 segundos, o tempo
  de descanso começa a acumular até que o atleta saque.
- Após o saque, dependendo do modo de aferição escolhido, o radar (automático)
  ou árbitro (manual) aferem as velocidades até a queda da bolinha.
- Um som identifica a faixa de velocidade de cada golpe aferido:
    - `50--59`: grave
    - `60--69`: agudo
    - `70--79`: laser
    - `80--89`: explosão 1
    - `90--99`: explosão 2
    - `100--+`: ambulância
- Golpes não preferenciais (tipicamente backhands à esquerda) são aferidos pelo
  árbitro e acompanhados de um som de palmas.
<!--
- Quando a apresentação está desequilibrada, os ataques do atleta que mais
  pontuou acompanham um som grave.
-->
- Quando a bolinha cai, o árbitro marca a queda e um som característico é
  emitido.
    - No modo autônomo, as quedas são sinalizadas após 3.5 segundos sem nenhuma
      aferição detectada. Não há necessidade de interferência do árbitro.
    - O último golpe detectado antes de cada queda é ignorado e o tempo volta
      até o momento em que ele ocorreu.
- O árbitro então pressiona o botão que habilita o próximo saque e o fluxo
  reinicia. No modo autônomo, o reinício é instantâneo, sem a interferência do
  árbitro.
- Um som agudo triplo é emitido quando faltam 30 segundos para a apresentação
  terminar.
- A apresentação termina após o tempo total cronometrado ou após o limite de
  quedas.
  Um som característico indica que a apresentação terminou.
- Ao fim da apresentação, é gerado um relatório com o placar e todas as
  aferições de golpes.

No modo de aferição com o radar e detecção autônoma de quedas, o árbitro só
é necessário para iniciar a partida.

## Instruções de Operação

Segurar as teclas por 3 segundos (exceto ←/→/Z/M):

```
CTRL-R           reinicia a apresentação
CTRL-E           reinicia no modo "esquenta" com tempo corrido e sem quedas
CTRL-↑           inicia uma sequência
CTRL-↓           marca uma queda de bola
← | →            marca um golpe do atleta à esquerda ou à direita (modo teclado)
Z                marca revés do atleta à esquerda
M                marca revés do atleta à direita

CTRL_- | CTRL_+  remove ou adiciona uma queda manualmente
CTRL-BACKSPACE   volta atrás e descarta inteiramente a última sequência

CTRL-0           edita o nome do árbitro
CTRL-1           edita o nome do atleta à esquerda
CTRL-2           edita o nome do atleta à direita
CTRL-I           inverte a posição dos atletas

CTRL-S           grava (salva) novamente o placar e relatório
CTRL-A           liga ou desliga o modo autônomo de detecção de quedas
CTRL-M           alterna entre modo de jogo e depuração
CTRL-Q           fecha o programa
```

## Arquivo de Configuração

O arquivo `data\conf.json` possui algumas configurações do software que podem
ser ajustadas, conforme descrito a seguir:

```
{
    "tempo":      300,            ; tempo total de jogo (300s)
    "distancia":  750,            ; distância considerada no modo manual (750cm)
    "golpes":     60,             ; quantidade de golpes por minuto (60 golpes da dupla)
    "ataques":    10,             ; ataques de cada lado por minuto (10 ataques da dupla)
    "equilibrio": 130,            ; limite da maior pontuação relativa à menor (0=desligado, 130=130%)
    "minima":     50,             ; velocidade mínima de um golpe pontuável (50km/h)
    "maxima":     85,             ; velocidade máxima no modo manual (85km/h)
    "trinca":     false,          ; modo de trinca ou dupla (dupla)
    "tregua":     1,              ; trégua de quedas por minuto (1 queda por minuto)
    "quedas":     1500,           ; desconto de queda para cada minuto (15%)
    "aborta":     15,             ; limite de quedas por jogo (15s por queda)
    "saque":      45,             ; velocidade mínima para considerar um saque (45km/h)
    "esquenta":   60,             ; tempo total de "esquenta" (60s)
    "descanso":   90,             ; tempo máximo de descanso (90s)
    "lado_radar": 1,              ; lado em que o radar está posicionado (1=esq, 2=dir)
    "lado_pivo":  1,              ; lado em que o pivô da trinca está posicionado (1=esq, 2=dir)
    "radar_reps": 3,              ; mínimo de medidas na mesma direção para golpe válido (3 medidas)
    "radar_igual":  700,          ; tempo mínimo para aceitar golpes na mesma direção (700ms)
    "radar_oposi":  300,          ; tempo mínimo para aceitar golpes em direções opostas (300ms)
    "recorde":    0,              ; recorde ao ligar o software
    "imagem1":    "data/esq.png", ; imagem à esquerda da tela
    "imagem2":    "data/dir.png", ; imagem à direita da tela
    "arbitro":    "Árbitro",      ; nome do árbitro
    "serial":     ""              ; porta serial do radar ("" = maior detectada)
}
```

## Relatório da Apresentação

Ao final da apresentação é gerado um relatório com o seguinte formato:

```
Data:          2021-06-09_19_08_00                      <-- data/hora da apresentação
Versão:        v4.0.0 / dupla / 750cm / 300s
                  \-- versão do software
                         \-- dupla ou trinca
                                  \-- radar ou distância entre os atletas em cm
                                         \-- tempo máximo de apresentação

SEQUÊNCIA 01                                            <-- sequências 01, 02, ...
============

TEMPO   DIR   KMH *
-----   ---   --- -
008308   ->   078           <-- golpes aferidos
009338   <-   034           -- TEMPO = momento do golpe desde o início da
011389   ->   069 *         --         apresentação em milésimos de segundo
012415   ->   077           -- DIR   = direção do golpe
012926   <-   043           -- KMH   = velocidade do golpe
013320   <-   055 *         --  *    = golpe não preferencial (backhand)
...


SEQUÊNCIA 02
============

...
```


