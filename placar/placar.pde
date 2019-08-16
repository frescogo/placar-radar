String PORTA = "/dev/ttyUSB0";

import processing.serial.*;

Serial SERIAL;
PImage IMG;

int      TEMPO_TOTAL;
int      TEMPO_JOGADO;
int      MAXIMA;
String[] NOMES = new String[2];

float dy; // 0.001 height

float W;
float H;
float T;

void setup () {
  SERIAL = new Serial(this, PORTA, 9600);
  //delay(50);
  //SERIAL.bufferUntil('\n');
  //SERIAL.clear();
  //SERIAL = new Serial(this, Serial.list()[0], 9600);

  surface.setTitle("FrescoGO! V.1.11");
  size(800, 600);
  //fullScreen();
  IMG = loadImage("fresco.png");

  dy = 0.001 * height;

  W = 0.20 * width;
  H = 0.15 * height;
  T = 0.25 * height;

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
    // RESTART
    case 0: {
      TEMPO_TOTAL  = int(campos[1]);
      TEMPO_JOGADO = 0;
      MAXIMA       = 0;

      String esq = campos[2];
      String dir = campos[3];
      NOMES[0] = esq;
      NOMES[1] = dir;

      draw_zera();
      draw_tempo(TEMPO_TOTAL, false);
      draw_nome(0, esq);
      draw_nome(3*W, dir);
      break;
    }

    // SEQ
    case 1: {
      int tempo  = int(campos[1]);
      int quedas = int(campos[2]);
      String esq = campos[3];
      String dir = campos[4];
      NOMES[0] = esq;
      NOMES[1] = dir;

      TEMPO_JOGADO = tempo;
      draw_tempo(TEMPO_TOTAL-TEMPO_JOGADO, false);

      draw_quedas(quedas);

      draw_nome(0, esq);
      draw_nome(3*W, dir);
      break;
    }

    // HIT
    case 2: {
      boolean is_esq     = int(campos[1]) == 0;
      boolean is_back    = int(campos[2]) == 1;
      int     velocidade = int(campos[3]);
      int     pontos     = int(campos[4]);
      boolean is_behind  = (int(campos[5]) == 1) && (TEMPO_JOGADO >= 30);
      int     backs      = int(campos[6]);      // TODO
      int     back_avg   = int(campos[7]);
      int     back_max   = int(campos[8]);
      int     fores      = int(campos[9]);      // TODO
      int     fore_avg   = int(campos[10]);
      int     fore_max   = int(campos[11]);

      color c = (is_back ? color(164,56,15) : color(15,56,164));
      float h = 3*H+10*dy;
      ellipseMode(CENTER);

      MAXIMA = max(MAXIMA, max(back_max,fore_max));
      draw_maxima(MAXIMA);

      if (is_esq)
      {
          draw_pontos(0, pontos, is_behind);
          draw_ultima(0, velocidade);
          //draw_maxima(0, max(back_max,fore_max));
          draw_lado(0*W, "Normal", fores, fore_avg);
          draw_lado(1*W, "Revés",  backs, back_avg);

          // desenha circulo da esquerda
          fill(c);
          stroke(15, 56, 164);
          ellipse(2*W-80*dy, h, 60*dy, 60*dy);

          // apaga circulo da direita
          fill(255);
          stroke(255);
          ellipse(3*W+80*dy, h, 70*dy, 70*dy);
      }
      else
      {
          draw_pontos(4*W, pontos, is_behind);
          draw_ultima(3*W, velocidade);
          //draw_maxima(4*W, max(back_max,fore_max));
          draw_lado(3*W, "Revés",  backs, back_avg);
          draw_lado(4*W, "Normal", fores, fore_avg);

          // desenha circulo da direita
          fill(c);
          stroke(15, 56, 164);
          ellipse(3*W+80*dy, h, 60*dy, 60*dy);

          // apaga circulo da esquerda
          fill(255);
          stroke(255);
          ellipse(2*W-80*dy, h, 70*dy, 70*dy);
      }
      break;
    }

    // TICK
    case 3: {
      int tempo  = int(campos[1]);
      int total  = int(campos[2]);
      int golpes = int(campos[3]);
      int media  = int(campos[4]);

      if (tempo >= (TEMPO_JOGADO-TEMPO_JOGADO%5)+5) {
        TEMPO_JOGADO = tempo;
        draw_tempo(TEMPO_TOTAL-TEMPO_JOGADO, false);
      }
      draw_total(total);
      draw_golpes(golpes);
      if (TEMPO_JOGADO >= 5) {
          draw_media(media);
      }
      break;
    }

    // FALL
    case 4: {
      int quedas = int(campos[1]);
      draw_quedas(quedas);
      draw_ultima(0, 0);
      draw_ultima(3*W, 0);
      break;
    }

    // END
    case 5: {
      draw_tempo(TEMPO_TOTAL-TEMPO_JOGADO, true);
      draw_ultima(0, 0);
      draw_ultima(3*W, 0);
      String ts = "" + year() + nf(month(),2) + nf(day(),2) + nf(hour(),2) + nf(minute(),2) + nf(second(),2);
      saveFrame("frescogo-"+ts+"-"+NOMES[0]+"-"+NOMES[1]+".png");
    }
  }
}

void draw_zera () {
  draw_logos();
  draw_tempo(0, false);

  draw_quedas(0);
  draw_golpes(0);

  draw_nome  (0, "?");
  draw_nome  (3*W, "?");

  //draw_maxima(0, 0);
  draw_ultima(0, 0);
  draw_media(0);
  draw_maxima(0);
  draw_ultima(3*W, 0);
  //draw_maxima(4*W, 0);

  draw_lado(0*W, "Normal", 0, 0);
  draw_lado(1*W, "Revés",  0, 0);
  draw_lado(3*W, "Revés",  0, 0);
  draw_lado(4*W, "Normal", 0, 0);

  draw_pontos(0, 0, false);
  draw_pontos(4*W, 0, false);
  draw_total(0);
}

void draw_logos () {
  fill(255);
  float w  = W+W/2;
  float x2 = 3*W+W/2;
  rect(0,       0, w, H);
  rect(3*W+W/2, 0, w, H);
  imageMode(CENTER);
  image(IMG, w/2,    H/2);
  image(IMG, x2+w/2, H/2);
}

void draw_tempo (int tempo, boolean ended) {
  String mins = nf(tempo / 60, 2);
  String segs = nf(tempo % 60, 2);

  if (ended) {
    fill(255,0,0);
  } else {
    fill(0);
  }
  rect(W+W/2, 0, 2*W, H);

  fill(255);
  textSize(120*dy);
  textAlign(CENTER, CENTER);
  text(mins+":"+segs, width/2, H/2-10*dy);
}

void draw_nome (float x, String nome) {
  stroke(0);
  fill(255);
  rect(x, H, 2*W, H);
  fill(0, 0, 255);
  textSize(66*dy);
  textAlign(CENTER, CENTER);
  text(nome, x+W, H+H/2-5*dy);
}

void draw_quedas (int quedas) {
  stroke(0);
  fill(255);
  rect(2*W, H, W, H);

  textAlign(CENTER, TOP);

  fill(0);
  textSize(30*dy);
  text("Quedas", width/2, H+5*dy);

  fill(250, 0, 0);
  textSize(105*dy);
  text(quedas, width/2, H+30*dy);
}

void draw_ultima (float x, int ultima) {
  stroke(0);
  fill(255);
  rect(x, 2*H, 2*W, 2*H);

  textAlign(CENTER, CENTER);
  fill(0);

  if (ultima != 0) {
    textSize(160*dy);
    text(ultima, x+W, 3*H-50*dy);
    textSize(40*dy);
    text("km/h", x+W, 3*H+70*dy);
  }
}

void draw_media (int media) {
  stroke(0);
  fill(255);
  rect(2*W, 2*H, W, H);

  textAlign(CENTER, TOP);
  fill(0);

  if (media != 0) {
    textAlign(CENTER, CENTER);
    textSize(90*dy);
    text(media, width/2, 2*H+H/2-25*dy);
    textSize(25*dy);
    text("média", width/2, 2*H+H/2+50*dy);
  }
}

void draw_maxima (int maxima) {
  stroke(0);
  fill(255);
  rect(2*W, 3*H, W, H);

  textAlign(CENTER, TOP);
  fill(0);

  textAlign(CENTER, CENTER);
  textSize(90*dy);
  text(maxima, width/2, 3*H+H/2-25*dy);
  textSize(25*dy);
  text("máx", width/2, 3*H+H/2+50*dy);
}

void draw_golpes (int golpes) {
  stroke(0);
  fill(255);
  rect(2*W, 4*H, W, H);

  textAlign(CENTER, CENTER);

  //textSize(25*dy);
  //text("Golpes", width/2, 4*H+5*dy);

  fill(0);
  textSize(90*dy);
  text(golpes, width/2, 4*H+H/2-5*dy);
}

void draw_lado (float x, String lado, int n, int avg) {
  stroke(0);
  fill(255);
  rect(x, 4*H, W, H);

  fill(0);
  textAlign(CENTER, TOP);
  textSize(30*dy);
  text(lado, x+W/2, 4*H+5*dy);

  textAlign(CENTER, CENTER);
  textSize(50*dy);
  text(avg, x+W/2-10*dy, 4*H+H/2+0*dy);
  textSize(25*dy);
  text(n,   x+W/2+40*dy, 4*H+H/2+40*dy);
}

/*
void draw_maxima (float x, int max) {
  stroke(0);
  fill(255);
  rect(x, 4*H, W, H);

  textAlign(CENTER, TOP);
  fill(0);

  textSize(25*dy);
  text("Máxima", x+W/2, 4*H+5*dy);

  //if (max != 0)
  {
    textSize(90*dy);
    text(max, x+W/2, 4*H+36*dy+5*dy);
  }
}
*/

void draw_pontos (float x, int pontos, boolean is_behind) {
  stroke(0);
  if (is_behind) {
      fill(255,0,0);
  } else {
      fill(255);
  }
  rect(x, 5*H, W, T);
  fill(0);
  textSize(50*dy);
  textAlign(CENTER, CENTER);
  text(pontos, x+W/2, 5*H+T/2-10*dy);
}

void draw_total (int total) {
  fill(0);
  rect(W, 5*H, 3*W, T);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(200*dy);
  text(total, width/2, 5*H+T/2-20*dy);
}
