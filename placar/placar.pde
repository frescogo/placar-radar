String PORTA = "/dev/ttyUSB0";

import processing.serial.*;

Serial SERIAL;
PImage IMG;
int    TEMPO_TOTAL;
int    TEMPO_JOGADO;

void setup () {
  SERIAL = new Serial(this, PORTA, 9600);
  //SERIAL.buffer(1024);
  SERIAL.bufferUntil('\n');

  surface.setTitle("FrescoGO! V.1.11");
  size(1280, 720);
  IMG = loadImage("fresco.png");
  textFont(createFont("Arial Black", 18));

  draw_zera();
}

void draw() {

  if (SERIAL.available() == 0) {
    return;
  }

  String linha = SERIAL.readStringUntil('\n');
  if (linha == null) {
    return;
  }
  //print(linha);

  String[] campos = split(linha, ";");
  int      codigo = int(campos[0]);

  switch (codigo)
  {
    case 0: {
      TEMPO_TOTAL  = int(campos[1]);
      TEMPO_JOGADO = 0;

      String esq = campos[2];
      String dir = campos[3];

      draw_zera();
      draw_tempo(TEMPO_TOTAL);
      draw_nome(  0, esq);
      draw_nome(754, dir);
      break;
    }

    case 1: {
      boolean is_esq     = int(campos[1]) == 0;
      boolean is_back    = int(campos[2]) == 1;
      int     velocidade = int(campos[3]);
      int     pontos     = int(campos[4]);

      color c = (is_back ? color(164,56,15) : color(15,56,164));

      if (is_esq)
      {
          draw_pontos(0, pontos);
          draw_ultima(262, velocidade);

          // desehna circulo da direita
          fill(c);
          stroke(15, 56, 164);
          ellipse(492, 435, 35, 35);

          // apaga circulo da esquerda
          fill(255);
          stroke(255);
          ellipse(789, 435, 38, 38);
      }
      else
      {
          draw_pontos(754, pontos);
          draw_ultima(754, velocidade);

          // desehna circulo da esquerda
          fill(c);
          stroke(15, 56, 164);
          ellipse(789, 435, 35, 35);

          // apaga circulo da direita
          fill(255);
          stroke(255);
          ellipse(492, 435, 38, 38);
      }
      break;
    }

    case 2: {
      int tempo  = int(campos[1]);
      int total  = int(campos[2]);
      int golpes = int(campos[3]);

      if (tempo >= TEMPO_JOGADO+5) {
        TEMPO_JOGADO = tempo;
        draw_tempo(TEMPO_TOTAL-TEMPO_JOGADO);
      }
      draw_total(total);
      draw_golpes(golpes);
      break;
    }

    case 3: { // Queda de bola, zerar o placar
      int quedas = int(campos[1]);
      draw_quedas(quedas);
      draw_ultima(262, 0);
      draw_ultima(754, 0);
      break;
    }

    case 4: {
      /*println("Case 4");
      println(campos[0]);
      print("Vazio: ");
      println(campos[1]);
      print("Vazio: ");
      println(campos[2]);
      print("Vazio: ");
      println(campos[3]);*/
      break;
    }
  }
}

void draw_zera () {
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

void draw_logos () {
  image(IMG,    0, 0);
  image(IMG, 1000, 0);
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
  rect(525, 110, 230, 125);

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

  if (media != 0) {
    textSize(75);
    text(media, width/2, 360+30+5);
  }
}

void draw_maxima (int x, int max) {
  stroke(0);
  fill(255);
  rect(x, 360, 262, 120);

  textAlign(CENTER, TOP);
  fill(0);

  textSize(30);
  text("Máxima", x+262/2, 360+5);

  if (max != 0) {
    textSize(75);
    text(max, x+262/2, 360+30+5);
  }
}

void draw_ultima (int x, int ultima) {
  stroke(0);
  fill(255);
  rect(x, 360, 262, 120);

  textAlign(CENTER, TOP);
  fill(0);

  textSize(30);
  text("Última", x+262/2, 360+5);

  if (ultima != 0) {
    textSize(75);
    text(ultima, x+262/2, 360+30+5);
  }
}

void draw_total (int total) {
  fill(0);
  rect(0, 480, 1280, 240);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(200);
  text(total, width/2, 480+240/2-20);
}
