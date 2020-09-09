# FrescoGO! (versão 3.1)

<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>

<!--
$ pandoc README.md -H deeplists.tex -o frescogo.pdf
$ pandoc README.md -H deeplists.tex -o frescogo.html
-->

O *FrescoGO!* é um software para avaliação de apresentações de Frescobol
competitivo.
A avaliação é baseada na velocidade que a bolinha atinge a cada golpe dos
atletas.
O *FrescoGO!* oferece dois modos de aferição das velocidades:
- Automático com um radar Doppler que mede as velocidades de pico da bolinha
  continuamente.
- Manual com teclas que medem o intervalo de tempo entre dois golpes
  consecutivos para inferir as velocidades considerando uma distância
  predeterminada entre os atletas.

Links do projeto:
- Site: <https://github.com/frescogo/frescogo>
- E-mail: <go.frescobol@gmail.com>
- Licença: <https://creativecommons.org/publicdomain/mark/1.0/deed.pt_BR>

<!--- Vídeos: <https://www.youtube.com/channel/UCrc_Ds56Bh77CFKXldIU-9g>-->

**O software e a regra do FrescoGO! são de domínio público, podendo ser usados,
  copiados e modificados livremente.**

## Regra - 4 minutos

- Cada atleta é avaliado em separado com uma pontuação:
    - `ATL = Ata x Vel`
        - `ATL` é a pontuação do atleta a ser calculada.
        - `Ata` é a quantidade de ataques.
        - `Vel` é a média de velocidade dos golpes.
    - São validados somente os `80` ataques mais fortes acima de `50` km/h.
- Cada queda desconta `2%` da pontuação da dupla:
    - `TOTAL = (ATL1 + ATL2) - (2% por queda)`
    - A apresentação é encerrada sumariamente ao atingir `16` quedas.
- Em caso de empate entre duplas, os seguintes quesitos serão usados para
  desempate:
    (1) maior quantidade de golpes,
    (2) menor quantidade de quedas,
    (3) sorteio.
- Resumo:
```
    ATL1  = Ata x Vel
    ATL2  = Ata x Vel
    TOTAL = (ATL1 + ATL2) - (2% por queda)
```

<!--
- Revés
    - Somente os golpes mais potentes de cada atleta são contabilizados:
        - até `108` golpes do lado     preferencial do atleta ("golpes normais")
        - até  `12` golpes do lado não preferencial do atleta ("golpes revés")
        - Opcionalmente, os golpes revés podem ser desabilitados e então serão
          contabilizados até `120` golpes normais.
-->

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
    - No modo autônomo, as quedas são sinalizadas após 5 segundos sem nenhuma
      aferição detectada, sem a interferência do árbitro.
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
    "ataques":    40,       ; quantidade de ataques por minuto (40 ataques)
    "minima":     50,       ; velocidade mínima de um ataque (50km/h)
    "maxima":     85,       ; velocidade máxima no modo manual (85km/h)
    "trinca":     false,    ; modo de trinca ou dupla (dupla)
    "quedas":     800,      ; desconto de queda para cada minuto (8%)
    "aborta":     15,       ; limite de quedas por jogo (15s por queda)

    "lado_radar": 1,        ; lado em que o radar está posicionado (esquerdo)
    "lado_pivo":  1,        ; lado em que o pivô da trinca está posicionado (esquerdo)

    "recorde": 0,           ; recorde ao ligar o software
    "imagem1": "data/fresco-alpha.png",     ; imagem à esquerda da tela
    "imagem2": "data/fresco-alpha.png",     ; imagem à direita da tela
    "atleta1": "Atleta 1",  ; nome do atleta à esquerda
    "atleta2": "Atleta 2",  ; nome do atleta à direita
    "arbitro": "Árbitro"    ; nome do árbitro
}
```

## Relatório da Apresentação

Ao final da apresentação é gerado um relatório com o seguinte formato:

```
Data:          2020-08-26_19_43_52                      <-- data/hora da apresentação
Versão:        v3.1.0 / dupla / radar / 240s / 40ata / 50kmh
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
Total:         4330 pontos                              <-- PONTUAÇÃO FINAL

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

<!--
-------------------------------------------------------------------------------

## Perguntas e Respostas

- Qual é o objetivo desse projeto?
    - Oferecer uma maneira objetiva, simples e barata de avaliar apresentações
      de frescobol.
    - Estar disponível no maior número de arenas de frescobol que for possível.
    - Auxiliar no desenvolvimento técnico de atletas, estimular a formação de
      novos atletas e contribuir para o crescimento do Frescobol de competição.

- Como eu consigo um aparelho desses?
    - Entre em contato conosco por e-mail:
        - <go.frescobol@gmail.com>

- Esse aparelho é um radar? Como o aparelho mede a velocidade da bolinha?
    - O aparelho não é um radar e mede a velocidade de maneira aproximada:
        - Os atletas devem estar a uma distância fixa predeterminada.
        - O juiz deve pressionar o botão no momento exato dos golpes (ou o mais
          próximo possível).
        - O aparelho divide a distância pelo tempo entre dois golpes
          consecutivos para calcular a velocidade.
        - Exemplo: se os atletas estão a 8 metros de distância e em um momento
          a bolinha leva 1 segundo para se deslocar entre os dois, então a
          velocidade foi de 8m/s (29 kmh).

- Quais as desvantagens em relação ao radar?
    - A principal desvantagem é que a medição não é tão precisa pois os atletas
      se movimentam e o juiz inevitavelmente irá atrasar ou adiantar as
      medições.
    - OBS.:
      O radar também não é perfeito, tendo erro estimado entre +1/-2 kmh.
      Além disso, qualquer angulação entre a trajetória da bolinha e a posição do
      radar afeta negativamente as medições (ex., um ângulo de 25 graus diminui
      as medições em 10%).
        - Fonte: <https://www.stalkerradar.com/stalker-speed-sensor/faq/stalker-speed-sensor-FAQ.shtml>

- Tem alguma vantagem em relação ao radar?
    - **Custo**:
        Os componentes do aparelho somados custam menos de R$50.
        O radar custa em torno de US$1000 e não inclui o software para
        frescobol.
    - **Licença de uso**:
        Além do custo ser menor, não há nenhuma restrição legal sobre o uso
        do aparelho, software ou regra por terceiros.
    - **Infraestrutura**:
        Além do aparelho, é necessário apenas um celular com um software
        gratuito (para obter o placar das apresentações) e uma caixa de som
        potente (de preferência com bateria interna).
        Não é necessário computador, ponto de luz elétrica, área protegida ou
        outros ajustes finos para a medição da apresentação.
        Essa simplicidade permite que múltiplas arenas funcionem ao mesmo
        tempo.
    - **Transparência das medições**:
        Apesar de serem menos precisas, as medições são audíveis e qualquer
        erro grosseiro pode ser notado imediatamente.
        O radar só mede bolas acima de 40 kmh e não é possível identificar se
        as medições estão sempre corretas (o posicionamento dos atletas, vento
        e outros fatores externos podem afetar as medições).
    - **Verificabilidade das medições**:
        Os atletas podem verificar/auditar se a pontuação final foi justa.
        As apresentações podem ser medidas por um aparelho igual durante as
        apresentaçõs ou podem ser gravados para medição posterior pelo vídeo.

- Eu posso usar o marcador em competições? Quanto custa? A quem devo pedir
  permissão?
    - Não há nenhuma restrição de uso.
    - Não há custos.
    - Não é necessário pedir autorização.
      Não é nem mesmo necessário mencionar o nome do sistema ou autores.

- Como eu posso contribuir?
    - Adotando o sistema no dia a dia da sua arena.
        - Principalmente com atletas iniciantes.
    - Promovendo competições.
    - Produzindo vídeos.
    - **Enviando os relatórios das apresentações para nós.**

- Como eu posso contribuir financeiramente?
    -
- Por quê as velocidades são elevadas ao quadrado no quesito de *Volume*?
    - Para incentivar os golpes mais potentes.
      Quanto maior a velocidade, maior ainda será o quadrado dela.
      Um golpe a 100 km/h é 2 vezes mais rápido que um a 50 km/h, mas o
      quadrado de 100 km/h é 4 vezes maior que o de 50 km/h (10000 vs 2500).

- Qual é o objetivo do quesito de *Máximas*?
    - Bonificando os 36 golpes mais velozes pelos dois lados do atleta (12 de
      revés e 24 normais), a regra incentiva que o atleta ataque acima do seu
      limite.
      Os 36 golpes correspondem a mais ou menos 15% dos ataques de um atleta em
      uma apresentação de 5 minutos.

    - E por quê a regra não considera todos os 7 golpes mais velozes (no lugar
      de considerar apenas o 7o)?
        - Para minimizar a imprecisão da marcação do juiz.
          É possível que o juiz acelere a marcação de alguns golpes, mas é
          pouco provável que isso afete sensivelmente a 7a bola mais veloz.

- Por quê algumas apresentações já iniciam com uma pontuação que eu não consigo
  zerar?
    - Quando a pontuação de Máximas está desligada (`potencia nao`), a regra
      assume um valor fixo de 50 kmh para todos os 7 golpes mais velozes de
      esquerda e de direita **que já são contabilizados no início da
      apresentação**.
    - Isso é feito para evitar os dois modos (ligado e desligado) fiquem com
      pontuações próximas.

- Tem como o juiz "roubar"?
    - Ao atrasar a marcação de um golpe "A", consequentemente o golpe "B"
      seguinte será adiantado.
      O golpe "A" terá a velocidade reduzida e o golpe "B" terá a velocidade
      aumentada.
      Se muitos atrasos acontecerem no ataque, a pontuação da dupla será
      prejudicada.
      Se muitos avanços acontecerem no ataque, a pontuação da dupla será
      beneficiada.
      De qualquer maneira, o som emitido pela aferição permite identificar os
      atrasos e avanços.

      Como a regra usa o quadrado das velocidades, esse atraso e adiantamento
      (se forem sistemáticos) podem afetar a pontuação final.

- Tem como o atleta "roubar" ou "tirar vantagem" da regra?
    - O atleta pode projetar o corpo para frente e adiantar ao máximo os golpes
      para aumentar a medição das velocidades.
      É recomendado um árbitro de linha para garantir que a distância mínima é
      sempre respeitada.

-->

## Agradecimentos

Agradecemos a todos os que contribuíram para o desenvolvimento do FrescoGO!:

- Adão (RJ)
- Alessandra (BA)
- Antônio (RJ)
- Clebinho (RN)
- Dão (RJ)
- Elton (RJ)
- Fátima (RJ)
- Lúcia (RJ)
- Luciano Paredão (RN)
- Luiz Negão (RJ)
- Mateus (RJ)
