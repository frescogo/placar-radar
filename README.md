# FrescoGO! - Placar para o Radar

## Fluxo da Apresentação

- Um sino com 5 sons curtos indica que a uma nova apresentação irá começar.
- Um som agudo longo indica que o atleta pode sacar. Após 5 segundos, o tempo
  de descanso começa a acumular até que o atleta saque.
- Após o saque, dependendo do modo de aferição escolhido, o radar (automático)
  ou árbitro (manual) aferem as velocidades até a queda da bolinha.
- Um som identifica a faixa de velocidade de cada golpe aferido:
    - `até 50 kmh`: som grave
    - `até 65 kmh`: som agudo
    - `até 80 kmh`: som de explosão
    - `acima de 80 kmh`: som de laser
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

```
CTRL-R           reinicia a apresentação
CTRL-E           reinicia no modo "esquenta" com tempo corrido e sem quedas
CTRL-↑           inicia uma sequência
CTRL-↓           marca uma queda de bola
← | →            marca um golpe do atleta à esquerda ou à direita (modo teclado)

CTRL_- | CTRL_+  remove ou adiciona uma queda manualmente
CTRL-BACKSPACE   volta atrás e descarta inteiramente a última sequência

CTRL-0           edita o nome do árbitro
CTRL-1           edita o nome do atleta à esquerda
CTRL-2           edita o nome do atleta à direita
CTRL-I           inverte a posição dos atletas

CTRL-S           grava (salva) novamente o placar e relatório
CTRL-A           liga ou desliga o modo autônomo de detecção de quedas
CTRL-Q           fecha o programa
```

## Arquivo de Configuração

O arquivo `data\conf.json` possui algumas configurações do software que podem
ser ajustadas, conforme descrito a seguir:

```
{
    "tempo":      240,      ; tempo total de jogo (240s)
    "distancia":  750,      ; distância considerada no modo manual (750cm)
    "ataques":    50,       ; quantidade de ataques por minuto (50 ataques)
    "minima":     50,       ; velocidade mínima de um ataque (50km/h)
    "maxima":     85,       ; velocidade máxima no modo manual (85km/h)
    "saque":      45,       ; velocidade mínima para considerar um saque (45km/h)
    "trinca":     false,    ; modo de trinca ou dupla (dupla)
    "quedas":     800,      ; desconto de queda para cada minuto (8%)
    "aborta":     15,       ; limite de quedas por jogo (15s por queda)
    "esquenta":   60,       ; tempo total de "esquenta" (60s)

    "lado_radar": 1,        ; lado em que o radar está posicionado (esquerdo)
    "lado_pivo":  1,        ; lado em que o pivô da trinca está posicionado (esquerdo)

    "recorde": 0,           ; recorde ao ligar o software
    "imagem1": "data/fresco-alpha.png",     ; imagem à esquerda da tela
    "imagem2": "data/fresco-alpha.png",     ; imagem à direita da tela
    "atleta1": "Atleta 1",  ; nome do atleta à esquerda
    "atleta2": "Atleta 2",  ; nome do atleta à direita
    "arbitro": "Árbitro",   ; nome do árbitro
    "serial":  ""           ; porta serial do radar ("" = maior detectada)
}
```

## Relatório da Apresentação

Ao final da apresentação é gerado um relatório com o seguinte formato:

```
Data:          2020-08-26_19_43_52                      <-- data/hora da apresentação
Versão:        v3.1.2 / dupla / radar / 240s / 40ata / 50kmh
                  \-- versão do software
                         \-- dupla ou trinca
                                  \-- radar ou distância entre os atletas em cm
                                         \-- tempo máximo de apresentação
                                                 \-- máximo de ataques por minuto
                                                         \-- velocidade mínima considerada


Maria:         5689 pontos = 80 atas X 71.11 km/h       <-- atleta à esquerda
Joao:          4189 pontos = 62 atas X 67.56 km/h       <-- atleta à direita

Descanso:      12                                       <-- tempo total de descanso em segundos
Quedas:        3                                        <-- total de quedas
Total:         9626 pontos                              <-- PONTUAÇÃO FINAL

SEQUÊNCIA 01                                            <-- sequências 01, 02, ...
============

TEMPO   DIR   KMH
-----   ---   ---
008308   ->   078           <-- golpes aferidos
009338   ->   034           -- TEMPO = momento do golpe desde o início da
011389   ->   069           --         apresentação em milésimos de segundo
012415   ->   077           -- DIR   = direção do golpe
012926   ->   043           -- KMH   = velocidade do golpe
...


SEQUÊNCIA 02
============

...
```


