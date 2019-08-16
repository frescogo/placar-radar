/*
- bug da ultima maxima
- exibir maximas
*/

String PORTA = "/dev/ttyUSB0";

import processing.serial.*;

Serial SERIAL;
PImage IMG;
int    TEMPO_TOTAL;
int    TEMPO_JOGADO;

float dy; // 0.001 height

float W_LOGO;
float W_TEMPO;
float W_JOG;
float W_MEIO;
float W_MAXULT;

float H_TOPO;
float H_NOMES;
float H_QUEDAS;
float H_PONTOS;
float H_MEIO;
float H_TOTAL;

float X_LOGO1;
float X_TEMPO;
float X_LOGO2;
float X_ESQ;
float X_MEIO;
float X_DIR;

float Y_GOLPES;
float Y_PONTOS;
float Y_MEIO;
float Y_TOTAL;

void setup () {
  SERIAL = new Serial(this, PORTA, 9600);
  //SERIAL.buffer(1024);
  SERIAL.bufferUntil('\n');

  surface.setTitle("FrescoGO! V.1.11");
  //size(1280, 720);
  fullScreen();
  IMG = loadImage("fresco.png");

  dy = 0.001 * height;

  W_LOGO   = 0.25 * width;
  W_TEMPO  = width - 2*W_LOGO;
  W_JOG    = 0.40 * width;
  W_MEIO   = 0.20 * width;
  W_MAXULT = 0.20 * width;

  H_TOPO   = 0.15 * height;
  H_NOMES  = 0.10 * height;
  H_PONTOS = 0.25 * height;
  H_MEIO   = 0.17 * height;
  H_TOTAL  = 0.33 * height;
  H_QUEDAS = (height - H_TOPO - H_MEIO - H_TOTAL) / 2;

  X_LOGO1 = 0;
  X_TEMPO = W_LOGO;
  X_LOGO2 = W_LOGO + W_TEMPO;
  X_ESQ   = 0;
  X_MEIO  = W_JOG;
  X_DIR   = W_JOG + W_MEIO;

  Y_GOLPES = H_TOPO + H_QUEDAS;
  Y_PONTOS = H_TOPO + H_NOMES;
  Y_MEIO   = Y_PONTOS + H_PONTOS;
  Y_TOTAL  = height - H_TOTAL;

  textFont(createFont("Arial Black", 18));

  draw_zera();
}

void draw () {

  if (SERIAL.available() == 0) {
    return;
  }

  String linha = SERIAL.readStringUntil('\n');
  if (linha == null) {
    return;
  }
  print(linha);

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
      draw_nome(X_ESQ, esq);
      draw_nome(X_DIR, dir);
      break;
    }

    case 1: {
      boolean is_esq     = int(campos[1]) == 0;
      boolean is_back    = int(campos[2]) == 1;
      int     velocidade = int(campos[3]);
      int     pontos     = int(campos[4]);
      boolean is_behind  = (int(campos[5]) == 1) && (TEMPO_JOGADO >= 30);
      int     backs      = int(campos[6]);      // TODO
      int     back_max   = int(campos[7]);
      int     fores      = int(campos[8]);      // TODO
      int     fore_max   = int(campos[9]);

      color c = (is_back ? color(164,56,15) : color(15,56,164));

      if (is_esq)
      {
          draw_pontos(X_ESQ, pontos, is_behind);
          draw_ultima(X_ESQ+W_MAXULT, velocidade);
          draw_maxima(0, max(back_max,fore_max));

          ellipseMode(CENTER);

          // desehna circulo da direita
          fill(c);
          stroke(15, 56, 164);
          ellipse(X_MEIO-45*dy, Y_MEIO+H_MEIO/2+10*dy, 40*dy, 40*dy);

          // apaga circulo da esquerda
          fill(255);
          stroke(255);
          ellipse(X_DIR+45*dy, Y_MEIO+H_MEIO/2+10*dy, 50*dy, 50*dy);
      }
      else
      {
          draw_pontos(X_DIR, pontos, is_behind);
          draw_ultima(X_DIR, velocidade);
          draw_maxima(X_DIR+W_MAXULT, max(back_max,fore_max));

          ellipseMode(CENTER);

          // desehna circulo da esquerda
          fill(c);
          stroke(15, 56, 164);
          ellipse(X_DIR+45*dy, Y_MEIO+H_MEIO/2+10*dy, 40*dy, 40*dy);

          // apaga circulo da direita
          fill(255);
          stroke(255);
          ellipse(X_MEIO-45*dy, Y_MEIO+H_MEIO/2+10*dy, 50*dy, 50*dy);
      }
      break;
    }

    case 2: {
      int tempo  = int(campos[1]);
      int total  = int(campos[2]);
      int golpes = int(campos[3]);
      int media  = int(campos[4]);

      if (tempo >= TEMPO_JOGADO+5) {
        TEMPO_JOGADO = tempo;
        draw_tempo(TEMPO_TOTAL-TEMPO_JOGADO);
      }
      draw_total(total);
      draw_golpes(golpes);
      if (TEMPO_JOGADO >= 5) {
          draw_media(media);
      }
      break;
    }

    case 3: { // Queda de bola, zerar o placar
      int quedas = int(campos[1]);
      draw_quedas(quedas);
      draw_ultima(X_ESQ+W_MAXULT, 0);
      draw_ultima(X_ESQ, 0);
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

  draw_nome  (X_ESQ, "?");
  draw_nome  (X_DIR, "?");
  draw_pontos(X_ESQ, 0, false);
  draw_pontos(X_DIR, 0, false);

  draw_maxima(0, 0);
  draw_maxima(X_DIR+W_MAXULT, 0);
  draw_media(0);
  draw_ultima(W_MAXULT, 0);
  draw_ultima(X_DIR, 0);

  draw_total(0);
}

void draw_logos () {
  fill(255);
  rect(X_LOGO1, 0, W_LOGO, H_TOPO);
  rect(X_LOGO2, 0, W_LOGO, H_TOPO);
  imageMode(CENTER);
  image(IMG, X_LOGO1+W_LOGO/2, H_TOPO/2);
  image(IMG, X_LOGO2+W_LOGO/2, H_TOPO/2);
}

void draw_tempo (int tempo) {
  String mins = nf(tempo / 60, 2);
  String segs = nf(tempo % 60, 2);

  fill(0);
  rect(X_TEMPO, 0, W_TEMPO, H_TOPO);

  fill(255);
  textSize(120*dy);
  textAlign(CENTER, CENTER);
  text(mins+":"+segs, width/2, H_TOPO/2-10*dy);
}

void draw_quedas (int quedas) {
  stroke(0);
  fill(255);
  rect(X_MEIO, H_TOPO, W_MEIO, H_QUEDAS);

  textAlign(CENTER, TOP);

  fill(0);
  textSize(30*dy);
  text("QUEDAS", width/2, H_TOPO+5*dy);

  fill(37, 21, 183);
  textSize(105*dy);
  text(quedas, width/2, H_TOPO+40*dy);
}

void draw_golpes (int golpes) {
  stroke(0);
  fill(255);
  rect(X_MEIO, Y_GOLPES, W_MEIO, H_QUEDAS);

  textAlign(CENTER, TOP);

  fill(0);
  textSize(30*dy);
  text("GOLPES", width/2, Y_GOLPES+5*dy);

  fill(37, 21, 183);
  textSize(105*dy);
  text(golpes, width/2, Y_GOLPES+40*dy);
}

void draw_nome (float x, String nome) {
  stroke(0);
  fill(255);
  rect(x, H_TOPO, W_JOG, H_NOMES);
  fill(255, 0, 0);
  textSize(66*dy);
  textAlign(CENTER, CENTER);
  text(nome, x+W_JOG/2, H_TOPO+H_NOMES/2-5*dy);
}

void draw_pontos (float x, int pontos, boolean is_behind) {
  stroke(0);
  if (is_behind) {
      fill(255,0,0);
  } else {
      fill(255);
  }
  rect(x, Y_PONTOS, W_JOG, H_PONTOS);
  fill(0);
  textSize(170*dy);
  textAlign(CENTER, CENTER);
  text(pontos, x+W_JOG/2, Y_PONTOS+H_PONTOS/2-10*dy);
}

void draw_media (int media) {
  stroke(0);
  fill(255);
  rect(X_MEIO, Y_MEIO, W_MEIO, H_MEIO);

  textAlign(CENTER, TOP);
  fill(0);

  textSize(36*dy);
  text("Média", width/2, Y_MEIO+5*dy);

  if (media != 0) {
    textSize(90*dy);
    text(media, width/2, Y_MEIO+36*dy+10*dy);
  }
}

void draw_maxima (float x, int max) {
  stroke(0);
  fill(255);
  rect(x, Y_MEIO, W_MAXULT, H_MEIO);

  textAlign(CENTER, TOP);
  fill(0);

  textSize(36*dy);
  text("Máxima", x+W_MAXULT/2, Y_MEIO+5*dy);

  if (max != 0) {
    textSize(90*dy);
    text(max, x+W_MAXULT/2, Y_MEIO+36*dy+5*dy);
  }
}

void draw_ultima (float x, int ultima) {
  stroke(0);
  fill(255);
  rect(x, Y_MEIO, W_MAXULT, H_MEIO);

  textAlign(CENTER, TOP);
  fill(0);

  textSize(36*dy);
  text("Última", x+W_MAXULT/2, Y_MEIO+5*dy);

  if (ultima != 0) {
    textSize(90*dy);
    text(ultima, x+W_MAXULT/2, Y_MEIO+36*dy+5*dy);
  }
}

void draw_total (int total) {
  fill(0);
  rect(0, Y_TOTAL, width, H_TOTAL);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(240*dy);
  text(total, width/2, Y_TOTAL+H_TOTAL/2-20*dy);
}
