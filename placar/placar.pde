String PORTA = "/dev/ttyUSB0";

import processing.serial.*;
Serial porta;
String codigo;
String pos_vel;
int coord_x;
int tamanho; // Numero de dígitos de um valor lido na serial
int coordenada_inicial;
int largura_quadro;
int largura_letra;
PImage img; // Função para trabalhar com imagens

int TEMPO_TOTAL;
int TEMPO_JOGADO;

void draw_logos () {
  image(img,    0, 0);
  image(img, 1000, 0);
  noFill();
  rect(  0, 0, 280, 110);
  rect(999, 0, 280, 110);
}

void draw_tempo (int tempo) {
  String mins = nf(tempo / 60, 2);
  String segs = nf(tempo % 60, 2);

  fill(0);
  rect(280, 0, 720, 110);

  fill(255);
  textSize(100);
  textAlign(CENTER, CENTER);
  text(mins+":"+segs, width/2, 110/2-10);
}

void draw_quedas (int quedas) {
  stroke(0);
  fill(255);
  rect(525, 110, 230, 250);

  textAlign(CENTER, TOP);

  fill(0);
  textSize(25);
  text("QUEDAS", width/2, 110+2);

  fill(37, 21, 183);
  textSize(90);
  text(quedas, width/2, 110+25);
}

void draw_golpes (int golpes) {
  stroke(0);
  fill(255);
  rect(525, 235, 229, 125);

  textAlign(CENTER, TOP);

  fill(0);
  textSize(25);
  text("GOLPES", width/2, 235+2);

  fill(37, 21, 183);
  textSize(90);
  text(golpes, width/2, 235+25);
}

void draw_nome (int x, String nome) {
  stroke(0);
  fill(255);
  rect(x, 110, 525, 55);
  fill(255, 0, 0);
  textSize(55);
  textAlign(CENTER, CENTER);
  text(nome, x+525/2, 110+55/2-5);
}

void draw_pontos (int x, int pontos) {
  stroke(0);
  fill(255);
  rect(x, 165, 525, 195);
  fill(0);
  textSize(140);
  textAlign(CENTER, CENTER);
  text(pontos, x+525/2, 165+195/2-10);
}

void draw_media (int media) {
  stroke(0);
  fill(255);
  rect(525, 360, 230, 120);

  textAlign(CENTER, TOP);
  fill(0);

  textSize(30);
  text("Média", width/2, 360+5);

  textSize(75);
  text(media, width/2, 360+30+5);
}

void draw_maxima (int x, int max) {
  stroke(0);
  fill(255);
  rect(x, 360, 262, 120);

  textAlign(CENTER, TOP);
  fill(0);

  textSize(30);
  text("Máxima", x+262/2, 360+5);

  textSize(75);
  text(max, x+262/2, 360+30+5);
}

void draw_ultima (int x, int ultima) {
  stroke(0);
  fill(255);
  rect(x, 360, 262, 120);

  textAlign(CENTER, TOP);
  fill(0);

  textSize(30);
  text("Última", x+262/2, 360+5);

  textSize(75);
  text(ultima, x+262/2, 360+30+5);
}

void draw_total (int total) {
  fill(0);
  rect(0, 480, 1280, 240);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(200);
  text(total, width/2, 480+240/2-20);
}

void setup () {
  porta = new Serial(this, PORTA, 9600);
  porta.bufferUntil('\n');

  surface.setTitle("FrescoGO! V.1.11");
  size(1280, 720);
  img = loadImage("fresco.png");
  textFont(createFont("Arial Black", 18));

  draw_logos();
  draw_tempo(0);

  draw_quedas(0);
  draw_golpes(0);

  draw_nome  (   0, "?");
  draw_nome  ( 754, "?");
  draw_pontos(   0, 0);
  draw_pontos( 754, 0);

  draw_maxima(   0, 0);
  draw_maxima(1016, 0);
  draw_media(0);
  draw_ultima( 262, 0);
  draw_ultima( 754, 0);

  draw_total(0);
}

void draw() {

  if (porta.available() == 0) {
    return;
  }

  String linha = porta.readStringUntil('\n'); // Ler a String recebida
  print(linha);
  String[] posicao = split (linha, ";");
  codigo = posicao[0];

  switch (codigo) {

    case "0":
        TEMPO_TOTAL = int(posicao[1]);
        String esq = posicao[2];
        String dir = posicao[3];

        draw_tempo(TEMPO_TOTAL);
        draw_nome(  0, esq);
        draw_nome(754, dir);
        break;

    case "1":
        pos_vel = posicao[1];
        int vel_esq = int(posicao[3]);
        int vel_dir = int(posicao[3]);
        int pts_esq = int(posicao[4]);
        int pts_dir = int(posicao[4]);

        switch (pos_vel) {
          case "0":
            // Circulo indicando de quem foi o velocidade medida
            fill(15, 56, 164);
            stroke(15, 56, 164);
            ellipse(789, 435, 35, 35);

            // Apaga sinalização do outro jogador
            fill(255);
            stroke(255);
            ellipse(492, 435, 38, 38);

            fill(0);
            textSize(80);
            draw_ultima(754, vel_esq);
            draw_pontos(0, pts_esq);
            break;

          case "1":
            // Circulo indicando de quem foi o velocidade medida
            fill(15, 56, 164);
            stroke(15, 56, 164);
            ellipse(492, 435, 35, 35);

            // Apaga sinalização do outro jogador
            fill(255);
            stroke(255);
            ellipse(789, 435, 38, 38);

            draw_ultima(262, vel_dir);
            draw_pontos(754, pts_dir);
            break;
        }

    case "2":

      TEMPO_JOGADO = int(posicao[1]);
      int total    = int(posicao[2]);

      draw_tempo(TEMPO_TOTAL-TEMPO_JOGADO);
      draw_total(total);
      break;

    case "3": // Queda de bola, zerar o placar
      int quedas = int(posicao[1]);
      draw_quedas(quedas);

      //Apaga ultimas velocidade esquerda
      fill(255);
      stroke(0);
      rect(262, 360, 263, 120);
      fill(0);
      textSize(30);
      text("Última", 340, 395);

      //Apaga ultimas velocidade direita
      fill(255);
      stroke(0);
      rect(754, 360, 262, 120);
      fill(0);
      textSize(30);
      text("Última", 834, 395);

      break;

    case "4":
      /*println("Case 4");
      println(posicao[0]);
      print("Vazio: ");
      println(posicao[1]);
      print("Vazio: ");
      println(posicao[2]);
      print("Vazio: ");
      println(posicao[3]);*/
      break;
  }
}
