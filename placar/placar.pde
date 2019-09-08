String  CFG_PORTA   = "/dev/ttyUSB0";
//String  CFG_PORTA   = "COM6";
boolean CFG_MAXIMAS = true;

///opt/processing-3.5.3/processing-java --sketch=/data/frescogo/placar/placar --run

import processing.serial.*;

Serial   SERIAL;

PImage   IMG;

int      DIGITANDO    = 255;  // 0=digitando ESQ, 1=digitando DIR, 2=digitando JUIZ

int      GRAVANDO     = 0;    // 0=nao, 1=screenshot, 2=serial
String   GRAVANDO_TS;

boolean  IS_FIM;
int      TEMPO_TOTAL;
int      TEMPO_JOGADO;
int      TEMPO_EXIBIDO;
int      PONTOS_TOTAL;
int      QUEDAS;
int      GOLPES_TOT;
int      GOLPES_AVG;
int      IS_DESEQ;

int      GOLPE_IDX;
int      GOLPE_CLR;

String[] NOMES        = new String[3];
int[]    PONTOS       = new int[2];
int[]    ULTIMAS      = new int[2];
int[]    MAXIMAS      = new int[2];
int[]    FORES_TOT    = new int[2];
int[]    FORES_AVG    = new int[2];
int[]    BACKS_TOT    = new int[2];
int[]    BACKS_AVG    = new int[2];

float dy; // 0.001 height

float W;
float H;

void setup () {
  serial_liga();
  //delay(50);
  //SERIAL.bufferUntil('\n');
  //SERIAL.clear();
  //SERIAL = new Serial(this, Serial.list()[0], 9600);

  surface.setTitle("FrescoGO! v1.12.1");
  size(640, 480);
  //fullScreen();
  IMG = loadImage("data/fresco.png");

  dy = 0.001 * height;

  W = 0.20   * width;
  H = 0.1666 * height;

  zera();

  textFont(createFont("LiberationSans-Bold.ttf", 18));
}

void zera () {
  IS_FIM       = false;
  TEMPO_JOGADO = 0;
  TEMPO_EXIBIDO = 0;
  PONTOS_TOTAL = 0;
  QUEDAS       = 0;
  GOLPES_TOT   = 0;
  GOLPES_AVG   = 0;
  IS_DESEQ     = 255;

  GOLPE_IDX    = 255;

  NOMES[0]     = "";
  NOMES[1]     = "";
  NOMES[2]     = "";
  PONTOS[0]    = 0;
  PONTOS[1]    = 0;
  ULTIMAS[0]   = 0;
  ULTIMAS[1]   = 0;
  MAXIMAS[0]   = 0;
  MAXIMAS[1]   = 0;
  FORES_TOT[0] = 0;
  FORES_TOT[1] = 0;
  FORES_AVG[0] = 0;
  FORES_AVG[1] = 0;
  BACKS_TOT[0] = 0;
  BACKS_TOT[1] = 0;
  BACKS_AVG[0] = 0;
  BACKS_AVG[1] = 0;
}

///////////////////////////////////////////////////////////////////////////////
// SERIAL
///////////////////////////////////////////////////////////////////////////////

void serial_liga () {
  SERIAL = new Serial(this, CFG_PORTA, 9600);

  ellipseMode(CENTER);
  fill(0);
  stroke(15, 56, 164);
  ellipse(3.5*W, 5*H, 60*dy, 60*dy);
}

void serial_desliga () {
  SERIAL.stop();
  SERIAL = null;

  ellipseMode(CENTER);
  fill(255,0,0);
  stroke(15, 56, 164);
  ellipse(3.5*W, 5*H, 60*dy, 60*dy);
}

///////////////////////////////////////////////////////////////////////////////
// KEYBOARD
///////////////////////////////////////////////////////////////////////////////

int ctrl (char key) {
  return char(int(key) - int('a') + 1);
}

void trata_nome (float x, int idx, String lado) {
  if (key==ENTER || key==RETURN) {
    //println(lado + " " + NOMES[idx] + "\n");
    SERIAL.write(lado + " " + NOMES[idx] + "\n");
    delay(500);
    String linha = SERIAL.readStringUntil('\n');
    //println("<<<",linha);
    //assert(linha == "ok");/
    DIGITANDO = 255;
  } else if (key==BACKSPACE) {
    if (NOMES[idx].length() > 0) {
      NOMES[idx] = NOMES[idx].substring(0, NOMES[idx].length()-1);
    }
  } else if (int(key)>=int('a') && int(key)<='z' || int(key)>=int('A') && int(key)<=int('Z') || key=='_'){
    NOMES[idx] = NOMES[idx] + key;
    //println(">>>", key);
  }
}

void keyPressed () {
  switch (DIGITANDO) {
    case 255: // OCIOSO
      if (key == ctrl('e')) {           // CTRL-E
        DIGITANDO = 0;
        NOMES[0] = "";
      } else if (key == ctrl('d')) {    // CTRL-D
        DIGITANDO = 1;
        NOMES[1] = "";
      } else if (key == ctrl('j')) {    // CTRL-J
        DIGITANDO = 2;
        NOMES[2] = "";
      } else if (key == ctrl('s')) {    // CTRL-S
        if (SERIAL == null) {
          serial_liga();
        } else {
          serial_desliga();
        }
      }
      break;

    case 0: // DIGITANDO ESQ
      trata_nome(0, 0, "esquerda");
      break;
    case 1: // DIGITANDO DIR
      trata_nome(3*W, 1, "direita");
      break;
    case 2: // DIGITANDO JUIZ
      trata_nome(2*W, 2, "juiz");
      break;
  }
}

///////////////////////////////////////////////////////////////////////////////
// LOOP
///////////////////////////////////////////////////////////////////////////////

void draw () {
  draw_tudo(false);

  // grava em 2 passos: primeiro tira foto e redesenha "Aguarde...", depois grava o relatorio
  if (GRAVANDO == 1) {
    GRAVANDO_TS = "" + year() + nf(month(),2) + nf(day(),2) + nf(hour(),2) + nf(minute(),2) + nf(second(),2);
    saveFrame("relatorios/frescogo-"+GRAVANDO_TS+"-"+NOMES[0]+"-"+NOMES[1]+".png");
    draw_tudo(true);
    GRAVANDO = 2;
    return;
  } else if (GRAVANDO == 2) {
    delay(1000);
    SERIAL.write("relatorio\n");
    delay(40000);
    byte[] LOG = new byte[32768];
    LOG = SERIAL.readBytes();
    saveBytes("relatorios/frescogo-"+GRAVANDO_TS+"-"+NOMES[0]+"-"+NOMES[1]+".txt", LOG);
    GRAVANDO = 0;
  }

  if (SERIAL==null || SERIAL.available()==0) {
    return;
  }

  String linha = SERIAL.readStringUntil('\n');
  if (linha == null) {
    return;
  }
  //print(">>>",linha);

  String[] campos = split(linha, ";");
  int      codigo = int(campos[0]);

  switch (codigo)
  {
    // RESTART
    case 0: {
      zera();
      TEMPO_TOTAL  = int(campos[1]);
      NOMES[0]     = campos[2];
      NOMES[1]     = campos[3];
      NOMES[2]     = campos[4];
      break;
    }

    // SEQ
    case 1: {
      TEMPO_JOGADO = int(campos[1]);
      QUEDAS       = int(campos[2]);
      NOMES[0]     = campos[3];
      NOMES[1]     = campos[4];
      NOMES[2]     = campos[5];
      TEMPO_EXIBIDO = TEMPO_JOGADO;
      break;
    }

    // HIT
    case 2: {
      int idx         = int(campos[1]);
      boolean is_back = int(campos[2]) == 1;
      ULTIMAS[idx]    = int(campos[3]);
      player(campos, idx, 4);

      GOLPE_IDX = idx;
      GOLPE_CLR = (is_back ? color(255,0,0) : color(0,0,255));
      break;
    }

    // TICK
    case 3: {
      TEMPO_JOGADO = int(campos[1]);
      PONTOS_TOTAL = int(campos[2]);
      GOLPES_TOT   = int(campos[3]);
      GOLPES_AVG   = int(campos[4]);

      if (TEMPO_JOGADO >= (TEMPO_EXIBIDO-TEMPO_EXIBIDO%5)+5) {
        TEMPO_EXIBIDO = TEMPO_JOGADO;
      }
      break;
    }

    // FALL
    case 4: {
      QUEDAS = int(campos[1]);
      player(campos, 0,  2);
      player(campos, 1, 10);
      TEMPO_EXIBIDO = TEMPO_JOGADO;
      GOLPE_IDX     = 255;
      ULTIMAS[0]    = 0;
      ULTIMAS[1]    = 0;
      break;
    }

    // END
    case 5: {
      player(campos, 0, 1);
      player(campos, 1, 9);
      GRAVANDO  = 1;    // salva o jogo no frame seguinte
      IS_FIM    = true;
      TEMPO_EXIBIDO = TEMPO_JOGADO;
      GOLPE_IDX = 255;
    }
  }
}

void player (String[] campos, int p, int i) {
  PONTOS[p]      = int(campos[i+0]);
  boolean is_beh = (int(campos[i+1]) == 1) && (TEMPO_JOGADO >= 30);
  BACKS_TOT[p]   = int(campos[i+2]);      // TODO
  BACKS_AVG[p]   = int(campos[i+3]);
  int back_max   = int(campos[i+4]);
  FORES_TOT[p]   = int(campos[i+5]);      // TODO
  FORES_AVG[p]   = int(campos[i+6]);
  int fore_max   = int(campos[i+7]);

  MAXIMAS[p] = max(MAXIMAS[p], max(back_max,fore_max));

  if (is_beh) {
    IS_DESEQ = p;
  } else if (IS_DESEQ == p) {
    IS_DESEQ = 255;
  }
}

///////////////////////////////////////////////////////////////////////////////
// DRAW
///////////////////////////////////////////////////////////////////////////////

void draw_tudo (boolean is_end) {
  background(255,255,255);

  draw_logos();
  draw_nome(0,   NOMES[0], DIGITANDO!=0);
  draw_nome(3*W, NOMES[1], DIGITANDO!=1);

  draw_tempo(TEMPO_TOTAL-TEMPO_EXIBIDO);
  draw_quedas(QUEDAS);

  if (GOLPE_IDX != 255) {
    draw_ultima(0,   ULTIMAS[0]);
    draw_ultima(3*W, ULTIMAS[1]);

    ellipseMode(CENTER);
    fill(GOLPE_CLR);
    stroke(15, 56, 164);
    if (GOLPE_IDX == 0) {
      ellipse(3*W+80*dy, 3*H+10*dy, 60*dy, 60*dy);
    } else {
      ellipse(2*W-80*dy, 3*H+10*dy, 60*dy, 60*dy);
    }
  }

  draw_golpes(GOLPES_TOT, GOLPES_AVG, TEMPO_EXIBIDO>=5);

  fill(255);
  rect(2*W, 3*H, W, H);
  draw_maxima(2.0*W, MAXIMAS[0]);
  draw_maxima(2.5*W, MAXIMAS[1]);

  draw_lado(0,      "Normal", FORES_TOT[0], FORES_AVG[0]);
  draw_lado(W/2,    "Revés",  BACKS_TOT[0], BACKS_AVG[0]);
  draw_lado(4*W,    "Revés",  BACKS_TOT[1], BACKS_AVG[1]);
  draw_lado(4*W+W/2,"Normal", FORES_TOT[1], FORES_AVG[1]);

  draw_pontos(0*W, PONTOS[0], IS_DESEQ==0);
  draw_pontos(4*W, PONTOS[1], IS_DESEQ==1);
  draw_total(PONTOS_TOTAL);
  draw_juiz(NOMES[2], DIGITANDO!=2);

  if (is_end) {
    fill(255,0,0);
    rect(W/2, 2.25*H, 4*W, 1.5*H);
    fill(255);
    textSize(120*dy);
    textAlign(CENTER, CENTER);
    text("Aguarde...", width/2, height/2);
  }
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

void draw_tempo (int tempo) {
  String mins = nf(tempo / 60, 2);
  String segs = nf(tempo % 60, 2);

  if (IS_FIM) {
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

void draw_nome (float x, String nome, boolean ok) {
  stroke(0);
  fill(255);
  rect(x, H, 2*W, H);
  if (ok) {
    fill(0, 0, 255);
  } else {
    nome = nome + "_";
    fill(255, 0, 0);
  }
  textSize(85*dy);
  textAlign(CENTER, CENTER);
  text(nome, x+W, H+H/2-5*dy);
}

void draw_juiz (String nome, boolean ok) {
  if (ok) {
    fill(100,100,100);
  } else {
    fill(255,0,0);
    nome = nome + "_";
  }
  textSize(30*dy);
  textAlign(RIGHT, BOTTOM);
  text("Juiz: " + nome, 4*W-5*dy, height);
}

void draw_quedas (int quedas) {
  stroke(0);
  fill(255);
  rect(2*W, H, W, H);

  textAlign(CENTER, TOP);

/*
  fill(0);
  textSize(30*dy);
  text("Quedas", width/2, H+5*dy);
*/

  fill(255, 0, 0);
  ellipseMode(CENTER);
  ellipse(2*W+W/2, H+H/2, 0.9*H, 0.9*H);

  fill(255);
  textSize(90*dy);
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

void draw_golpes (int golpes, int media, boolean apply) {
  stroke(0);
  fill(255);
  rect(2*W, 2*H, W, H);

  fill(0);
  textAlign(CENTER, CENTER);
  textSize(60*dy);

  text(golpes, 2.25*W, 2*H+H/2-25*dy);

  if (apply) {
    text(media, 2.75*W, 2*H+H/2-25*dy);
  } else {
    text("-", 2.75*W, 2*H+H/2-25*dy);
  }

  textSize(25*dy);
  text("golpes", 2.25*W, 2*H+H/2+50*dy);
  text("km/h",   2.75*W, 2*H+H/2+50*dy);
}

void draw_maxima (float x, int maxima) {
  fill(255);
  noStroke();
  rect(x+2, 3*H+2, W/2-4, H-4);

  fill(0);
  textAlign(CENTER, CENTER);
  textSize(60*dy);
  text(maxima, x+W/4, 3*H+H/2-20*dy);
  textSize(25*dy);
  text("<--    máx    -->", width/2, 3*H+H/2+50*dy);
}

void draw_lado (float x, String lado, int n, int avg) {
  if (!CFG_MAXIMAS) {
    return;
  }

  stroke(0);
  fill(255);
  rect(x, 4*H, W/2, H);

  fill(0);
  textAlign(CENTER, TOP);
  textSize(30*dy);
  text(lado, x+W/4, 4*H+5*dy);

  textAlign(CENTER, CENTER);
  textSize(50*dy);
  text(n,   x+W/4-10*dy, 4*H+H/2+0*dy);
  textSize(25*dy);
  text(avg, x+W/4+40*dy, 4*H+H/2+40*dy);
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
  float  h = (CFG_MAXIMAS ? 5*H : 4*H);
  float dh = (CFG_MAXIMAS ? 1*H : 2*H);

  stroke(0);
  if (is_behind) {
      fill(255,0,0);
  } else {
      fill(255);
  }
  rect(x, h, W, dh);
  fill(0);
  textSize(70*dy);
  textAlign(CENTER, CENTER);
  text(pontos, x+W/2, h+dh/2-10*dy);
}

void draw_total (int total) {
  fill(0);
  rect(W, 4*H, 3*W, 2*H);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(200*dy);
  text(total, width/2, 5*H-20*dy);
}
