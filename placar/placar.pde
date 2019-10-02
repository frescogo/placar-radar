String  CFG_PORTA   = "/dev/ttyUSB0";
//String  CFG_PORTA   = "/dev/ttyACM0";
//String  CFG_PORTA   = "COM6";
int     CFG_RECORDE = 0;

///opt/processing-3.5.3/processing-java --sketch=/data/frescogo/placar/placar --run

import processing.serial.*;

Serial   SERIAL;

PImage   IMG;

int      DIGITANDO    = 255;  // 0=digitando ESQ, 1=digitando DIR, 2=digitando JUIZ

int      GRAVANDO     = 0;    // 0=nao, 1=screenshot, 2=serial
String   GRAVANDO_TS;

boolean  IS_FIM;
boolean  EQUILIBRIO;
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

String[] NOMES   = new String[3];
int[]    PONTOS  = new int[2];
int[]    ULTIMAS = new int[2];
int[]    VOL_AVG = new int[2];
int[]    NRM_AVG = new int[2];
int[]    REV_AVG = new int[2];
//int[]    MAXIMAS = new int[2];
//int[]    FORES_TOT    = new int[2];
//int[]    BACKS_TOT    = new int[2];

float dy; // 0.001 height

float W;
float H;

void setup () {
  serial_liga();
  //delay(50);
  //SERIAL.bufferUntil('\n');
  //SERIAL.clear();
  //SERIAL = new Serial(this, Serial.list()[0], 9600);

  surface.setTitle("FrescoGO! v2.0");
  //size(1024, 768);
  fullScreen();
  IMG = loadImage("data/fresco.png");

  dy = 0.001 * height;

  W = 0.10   * width;
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
  VOL_AVG[0]   = 0;
  VOL_AVG[1]   = 0;
  NRM_AVG[0]   = 0;
  NRM_AVG[1]   = 0;
  REV_AVG[0]   = 0;
  REV_AVG[1]   = 0;
  //MAXIMAS[0]   = 0;
  //MAXIMAS[1]   = 0;
  //FORES_TOT[0] = 0;
  //FORES_TOT[1] = 0;
  //BACKS_TOT[0] = 0;
  //BACKS_TOT[1] = 0;
}

///////////////////////////////////////////////////////////////////////////////
// SERIAL
///////////////////////////////////////////////////////////////////////////////

void serial_liga () {
  SERIAL = new Serial(this, CFG_PORTA, 9600);

  ellipseMode(CENTER);
  fill(0);
  stroke(15, 56, 164);
  ellipse(0.5*W, 0.5*H, 60*dy, 60*dy);
}

void serial_desliga () {
  SERIAL.stop();
  SERIAL = null;

  ellipseMode(CENTER);
  fill(255,0,0);
  stroke(15, 56, 164);
  ellipse(0.5*W, 0.5*H, 60*dy, 60*dy);
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
      trata_nome(6*W, 1, "direita");
      break;
    case 2: // DIGITANDO JUIZ
      trata_nome(4*W, 2, "juiz");
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
    saveFrame("relatorios/frescogo-"+GRAVANDO_TS+"-"+NOMES[0]+"-"+NOMES[1]+"-placar.png");
    draw_tudo(true);
    GRAVANDO = 2;
    return;
  } else if (GRAVANDO == 2) {
    delay(1000);
    SERIAL.write("relatorio\n");
    delay(35000);
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
      EQUILIBRIO   = int(campos[2]) == 1;
      NOMES[0]     = campos[3];
      NOMES[1]     = campos[4];
      NOMES[2]     = campos[5];
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
      player(campos, 0, 2);
      player(campos, 1, 7);
      TEMPO_EXIBIDO = TEMPO_JOGADO;
      GOLPE_IDX     = 255;
      ULTIMAS[0]    = 0;
      ULTIMAS[1]    = 0;
      break;
    }

    // END
    case 5: {
      player(campos, 0, 1);
      player(campos, 1, 6);
      GRAVANDO  = 1;    // salva o jogo no frame seguinte
      IS_FIM    = true;
      TEMPO_EXIBIDO = TEMPO_JOGADO;
      GOLPE_IDX = 255;
      if (PONTOS_TOTAL > CFG_RECORDE) {
        CFG_RECORDE = PONTOS_TOTAL;
      }
    }
  }
}

void player (String[] campos, int p, int i) {
  PONTOS[p]      = int(campos[i+0]);
  boolean is_beh = (int(campos[i+1]) == 1) && (TEMPO_JOGADO >= 30);
  VOL_AVG[p]     = int(campos[i+2]);
  NRM_AVG[p]     = int(campos[i+3]);
  REV_AVG[p]     = int(campos[i+4]);
  //MAXIMAS[p]     = int(campos[i+2]);
  //FORES_TOT[p]   = int(campos[i+?]);      // TODO
  //int fore_max   = int(campos[i+3]);
  //BACKS_TOT[p]   = int(campos[i+?]);      // TODO
  //int back_max   = int(campos[i+5]);


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
  draw_nome(6*W, NOMES[1], DIGITANDO!=1);

  draw_tempo(TEMPO_TOTAL-TEMPO_EXIBIDO);
  draw_quedas(QUEDAS);

  if (GOLPE_IDX != 255) {
    draw_ultima(0,   ULTIMAS[0]);
    draw_ultima(6*W, ULTIMAS[1]);

    ellipseMode(CENTER);
    fill(GOLPE_CLR);
    stroke(15, 56, 164);
    if (GOLPE_IDX == 0) {
      ellipse(6*W+80*dy, 3*H+10*dy, 60*dy, 60*dy);
    } else {
      ellipse(4*W-80*dy, 3*H+10*dy, 60*dy, 60*dy);
    }
  }

  draw_golpes(GOLPES_TOT);
  draw_media(GOLPES_AVG, TEMPO_EXIBIDO>=5);

  //fill(255);
  //rect(4*W, 3*H, 2*W, H);
  //draw_maxima(4*W, MAXIMAS[0]);
  //draw_maxima(5*W, MAXIMAS[1]);

  draw_lado(0*W, color(200,200,250), "Volume", VOL_AVG[0]/100);
  draw_lado(1*W, color(200,250,200), "Normal", NRM_AVG[0]/100);
  draw_lado(2*W, color(250,200,200), "Revés",  REV_AVG[0]/100);
  draw_lado(7*W, color(200,200,250), "Volume", VOL_AVG[1]/100);
  draw_lado(8*W, color(200,250,200), "Normal", NRM_AVG[1]/100);
  draw_lado(9*W, color(250,200,200), "Revés",  REV_AVG[1]/100);

  draw_pontos(0*W, PONTOS[0], IS_DESEQ==0 && EQUILIBRIO);
  draw_pontos(7*W, PONTOS[1], IS_DESEQ==1 && EQUILIBRIO);
  draw_total(PONTOS_TOTAL);
  draw_recorde(CFG_RECORDE, PONTOS_TOTAL>CFG_RECORDE);
  draw_juiz(NOMES[2], DIGITANDO!=2);

  if (is_end) {
    fill(255,0,0);
    rect(W, 2.25*H, 8*W, 1.5*H);
    fill(255);
    textSize(120*dy);
    textAlign(CENTER, CENTER);
    text("Aguarde...", width/2, height/2);
  }
}

void draw_logos () {
  fill(255);
  float w  = 3*W;
  float x2 = 7*W;
  rect(0,   0, w, H);
  rect(7*W, 0, w, H);
  imageMode(CENTER);
  image(IMG, w/2,    H/2);
  image(IMG, x2+w/2, H/2);
}

void draw_tempo (int tempo) {
  if (tempo < 0) {
    tempo = 0;
  }
  String mins = nf(tempo / 60, 2);
  String segs = nf(tempo % 60, 2);

  if (IS_FIM) {
    fill(255,0,0);
  } else {
    fill(0);
  }
  rect(3*W, 0, 4*W, H);

  fill(255);
  textSize(120*dy);
  textAlign(CENTER, CENTER);
  text(mins+":"+segs, width/2, H/2-10*dy);
}

void draw_nome (float x, String nome, boolean ok) {
  stroke(0);
  fill(255);
  rect(x, H, 4*W, H);
  if (ok) {
    fill(0, 0, 255);
  } else {
    nome = nome + "_";
    fill(255, 0, 0);
  }
  textSize(85*dy);
  textAlign(CENTER, CENTER);
  text(nome, x+2*W, H+H/2-5*dy);
}

void draw_recorde (float v, boolean batido) {
  if (batido) {
    fill(255,100,100);
  } else {
      fill(100,100,100);
  }
  textSize(25*dy);
  textAlign(LEFT, BOTTOM);
  text("Recorde: " + nf(v/100,2,2), 3*W+5*dy, height);
}

void draw_juiz (String nome, boolean ok) {
  if (ok) {
    fill(100,100,100);
  } else {
    fill(255,0,0);
    nome = nome + "_";
  }
  textSize(25*dy);
  textAlign(RIGHT, BOTTOM);
  text("Juiz: " + nome, 7*W-5*dy, height);
}

void draw_quedas (int quedas) {
  stroke(0);
  fill(255);
  rect(4*W, H, 2*W, H);

  textAlign(CENTER, TOP);

/*
  fill(0);
  textSize(30*dy);
  text("Quedas", width/2, H+5*dy);
*/

  fill(255, 0, 0);
  ellipseMode(CENTER);
  ellipse(5*W, H+H/2, 0.9*H, 0.9*H);

  fill(255);
  textSize(90*dy);
  text(quedas, width/2, H+30*dy);
}

void draw_ultima (float x, int ultima) {
  stroke(0);
  fill(255);
  rect(x, 2*H, 4*W, 2*H);

  textAlign(CENTER, CENTER);
  fill(0);

  if (ultima != 0) {
    textSize(160*dy);
    text(ultima, x+2*W, 3*H-50*dy);
    textSize(40*dy);
    text("km/h", x+2*W, 3*H+70*dy);
  }
}

void draw_golpes (int golpes) {
  stroke(0);
  fill(255);
  rect(4*W, 2*H, 2*W, H);

  fill(0);
  textAlign(CENTER, CENTER);

  textSize(60*dy);
  text(golpes, 5*W, 2.5*H-25*dy);

  textSize(30*dy);
  text("Golpes", 5*W, 2.5*H+50*dy);
}

void draw_media (int media, boolean apply) {
  stroke(0);
  fill(255);
  rect(4*W, 3*H, 2*W, H);

  fill(0);
  textAlign(CENTER, CENTER);

  textSize(60*dy);
  if (apply) {
    text(media, 5*W, 3.5*H-25*dy);
  } else {
    text("-", 5*W, 3.5*H-25*dy);
  }

  textSize(30*dy);
  text("km/h", 5*W, 3.5*H+50*dy);
}

/*
void draw_maxima (float x, int maxima) {
  fill(255);
  noStroke();
  rect(x+2, 3*H+2, W-4, H-4);

  fill(0);
  textAlign(CENTER, CENTER);
  textSize(60*dy);
  text(maxima, x+W/2, 3*H+H/2-20*dy);
  textSize(25*dy);
  text("<--    máx    -->", width/2, 3*H+H/2+50*dy);
}
*/

void draw_lado (float x, int cor, String lado, int avg) {
  stroke(0);
  fill(cor);
  rect(x, 4*H, W, H);

  fill(0);
  textAlign(CENTER, TOP);
  textSize(25*dy);
  text(lado, x+W/2, 4*H+5*dy);

  textAlign(CENTER, CENTER);
  textSize(50*dy);
  text(avg, x+W/2, 4.5*H-2*dy);

  textAlign(CENTER, BOTTOM);
  textSize(25*dy);
  text("km/h", x+W/2, 5*H-5*dy);
}

void draw_pontos (float x, float pontos, boolean is_behind) {
  stroke(0);
  if (is_behind) {
      fill(255,0,0);
  } else {
      fill(255);
  }
  rect(x, 5*H, 3*W, H);
  fill(0);
  textSize(70*dy);
  textAlign(CENTER, CENTER);
  text(nf(pontos/100,2,2), x+1.5*W, 5.5*H-5*dy);
}

void draw_total (float total) {
  fill(0);
  rect(3*W, 4*H, 4*W, 2*H);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(150*dy);
  text(nf(total/100,2,2), width/2, 5*H-20*dy);
}
