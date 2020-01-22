String  CFG_PORTA   = "/dev/ttyUSB0";
//String  CFG_PORTA   = "/dev/ttyACM0";
//String  CFG_PORTA   = "COM6";
int     CFG_RECORDE = 0;
boolean CFG_ACUM    = true;

boolean CFG_IMGS    = true;
String  CFG_IMG1    = "data/fresco-alpha.png";
String  CFG_IMG2    = "data/fresco-alpha.png";

///////////////////////////////////////////////////////////////////////////////
// NAO EDITAR NADA ABAIXO DAQUI
///////////////////////////////////////////////////////////////////////////////

///opt/processing-3.5.3/processing-java --sketch=/data/frescogo/placar/placar --run

import processing.serial.*;

Serial   SERIAL;

PImage   IMG1;
PImage   IMG2;

String   VERSAO       = "FrescoGO! v2.3.0";
String   PARS         = "(?)";
String   PARSS[];

int      DIGITANDO    = 255;  // 0=digitando ESQ, 1=digitando DIR, 2=digitando JUIZ

int      GRAVANDO     = 0;    // 0=nao, 1=screenshot, 2=serial
String   GRAVANDO_TS;

String   DIST         = "?";

boolean  IS_INVERTIDO = false;
int      ZER          = 0;
int      ONE          = 1;

boolean  IS_FIM;
boolean  EQUILIBRIO;
int      TEMPO_TOTAL;
int      TEMPO_JOGADO;
int      TEMPO_EXIBIDO;
int      PONTOS_TOTAL;
int      PONTOS_ACUM;
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
  size(1024, 768);
  //fullScreen();

  IMG1 = loadImage(CFG_IMG1);
  IMG1.resize(0,height/8);
  IMG2 = loadImage(CFG_IMG2);
  IMG2.resize(0,height/8);
  imageMode(CENTER);
  tint(255, 128);

  dy = 0.001 * height;

  W = width  / 9.0;
  H = height / 6.0;

  zera();

  textFont(createFont("LiberationSans-Bold.ttf", 18));
}

void zera () {
  IS_FIM       = false;
  TEMPO_JOGADO = 0;
  TEMPO_EXIBIDO = 0;
  PONTOS_TOTAL = 0;
  PONTOS_ACUM  = 0;
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
}

void serial_desliga () {
  SERIAL.stop();
  SERIAL = null;
}

///////////////////////////////////////////////////////////////////////////////
// KEYBOARD
///////////////////////////////////////////////////////////////////////////////

int ctrl (char key) {
  return char(int(key) - int('a') + 1);
}

void trata_nome (float x, int idx, String lado) {
  if (key==ENTER || key==RETURN) {
    SERIAL.write(lado + " " + NOMES[idx] + "\n");
    DIGITANDO = 255;
  } else if (key==BACKSPACE) {
    if (NOMES[idx].length() > 0) {
      NOMES[idx] = NOMES[idx].substring(0, NOMES[idx].length()-1);
    }
  } else if (int(key)>=int('a') && int(key)<=int('z') || int(key)>=int('A') && int(key)<=int('Z') || key=='_'){
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
      } else if (key == ctrl('a')) {    // CTRL-A
        DIGITANDO = 2;
        NOMES[2] = "";
      } else if (key == ctrl('i')) {    // CTRL-I
        IS_INVERTIDO = !IS_INVERTIDO;
        ZER = 1 - ZER;
        ONE = 1 - ONE;
      } else if (key == ctrl('s')) {    // CTRL-S
        if (SERIAL == null) {
          serial_liga();
        } else {
          serial_desliga();
        }
      } else if (key == '1') {          // 1
        DIST = "700 cm";
        SERIAL.write("distancia 700\n");
      } else if (key == '2') {          // 2
        DIST = "750 cm";
        SERIAL.write("distancia 750\n");
      } else if (key == '3') {          // 3
        DIST = "800 cm";
        SERIAL.write("distancia 800\n");
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
  if (linha.equals("ok\r\n")) {
    return;
  }
  //print(">>>", linha);

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
      PARS         = campos[6];
      PARSS        = match(PARS, "v(\\d+)/(\\d+)cm/(\\d+)s/maxs\\(\\d+,(\\d+)\\)/equ\\d/cont\\d+/fim\\d+");
      //println(PARSS);
      break;
    }

    // SEQ
    case 1: {
      IS_FIM       = false; // por causa do UNDO
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
      PONTOS_ACUM  = int(campos[3]);
      GOLPES_TOT   = int(campos[4]);
      GOLPES_AVG   = int(campos[5]);

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

  if (CFG_IMGS) {
    draw_img(0*W, IMG1);
    draw_img(6*W, IMG2);
  }
  draw_nome(0,   NOMES[ZER], DIGITANDO!=ZER);
  draw_nome(6*W, NOMES[ONE], DIGITANDO!=ONE);

  draw_tempo(TEMPO_TOTAL-TEMPO_EXIBIDO);

  fill(75,75,75);
  textSize(15*dy);
  textAlign(CENTER, TOP);
  fill(75,75,75);
  textSize(15*dy);
  textAlign(CENTER, TOP);
  text(VERSAO, width/2, 0);

  if (IS_INVERTIDO) {
    text("inv", width/2, 30*dy);
  }

  draw_quedas(QUEDAS);

  draw_media(GOLPES_AVG, TEMPO_EXIBIDO>=5);
  draw_golpes(GOLPES_TOT);

  if (GOLPE_IDX != 255) {
    draw_ultima(0,     1.5*W, ULTIMAS[ZER]);
    draw_ultima(5.5*W, 7.5*W, ULTIMAS[ONE]);

    ellipseMode(CENTER);
    fill(GOLPE_CLR);
    noStroke();
    if (GOLPE_IDX == ZER) {
      ellipse(6*W, 3*H, 60*dy, 60*dy);
    } else {
      ellipse(3*W, 3*H, 60*dy, 60*dy);
    }
  } else {
    if (PARSS!=null && !PARSS[4].equals("0")) {
      draw_lado(0.0*W, 1.0*W, color(200,200,250), "Volume", 60, VOL_AVG[ZER]/100);
      draw_lado(1.0*W, 1.0*W, color(200,250,200), "Normal", 25, NRM_AVG[ZER]/100);
      draw_lado(2.0*W, 1.0*W, color(250,200,200), "Revés",  15, REV_AVG[ZER]/100);
      draw_lado(6.0*W, 1.0*W, color(200,200,250), "Volume", 60, VOL_AVG[ONE]/100);
      draw_lado(7.0*W, 1.0*W, color(200,250,200), "Normal", 25, NRM_AVG[ONE]/100);
      draw_lado(8.0*W, 1.0*W, color(250,200,200), "Revés",  15, REV_AVG[ONE]/100);
    } else {
      draw_lado(0.0*W, 1.5*W, color(200,200,250), "Volume",  75, VOL_AVG[ZER]/100);
      draw_lado(1.5*W, 1.5*W, color(200,250,200), "Máximas", 25, NRM_AVG[ZER]/100);
      draw_lado(6.0*W, 1.5*W, color(200,200,250), "Volume",  75, VOL_AVG[ONE]/100);
      draw_lado(7.5*W, 1.5*W, color(200,250,200), "Máximas", 25, NRM_AVG[ONE]/100);
    }

    textAlign(CENTER, CENTER);
    fill(0);
    textSize(25*dy);
    if (PARSS != null && !PARSS[4].equals("0")) {
      text("Máximas", 2*W, 3*H-110*dy);
      text("Máximas", 8*W, 3*H-110*dy);
    } else {
      //text("Máximas", 2.25*W, 3*H-110*dy);
      //text("Máximas", 8.25*W, 3*H-110*dy);
    }

/*
    strokeWeight(1);
    stroke(0);
    noFill();
    rect(1.125*W, 2.5*H, 1.75*W, 1*H);
    rect(7.125*W, 2.5*H, 1.75*W, 1*H);
*/
  }

  draw_pontos(0*W, PONTOS[ZER], IS_DESEQ==ZER && EQUILIBRIO);
  draw_pontos(7*W, PONTOS[ONE], IS_DESEQ==ONE && EQUILIBRIO);
  draw_total(PONTOS_TOTAL, PONTOS_ACUM);

  {
    fill(75,75,75);
    textSize(15*dy);
    textAlign(CENTER, TOP);
    text(PARS, width/2, 4*H);
  }

  draw_recorde(3*W, CFG_RECORDE, PONTOS_TOTAL>CFG_RECORDE);
  //draw_dist(4.5*W, DIST);
  draw_juiz(6*W, NOMES[2], DIGITANDO!=2);

  strokeWeight(2);
  stroke(0);
  noFill();
  rect(0, 2*H, 9*W, 2*H);
  if (GOLPE_IDX != 255) {
    rect(3.5*W, 2*H, 2*W, 2*H);
  } else {
    rect(3.0*W, 2*H, 3*W, 2*H);
  }

  if (is_end) {
    fill(255);
    textSize(50*dy);
    textAlign(CENTER, CENTER);
    text("Aguarde...", width/2, 1.60*H);
  }

  if (SERIAL == null) {
    ellipseMode(CENTER);
    fill(255,0,0);
    noStroke();
    ellipse(width-50*dy, height-50*dy, 20*dy, 20*dy);
  }
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
  rect(3*W, 0, 3*W, 2*H);

  fill(255);
  textSize(120*dy);
  textAlign(CENTER, CENTER);
  text(mins+":"+segs, width/2, H-10*dy);
}

void draw_img (float x, PImage img) {
  noStroke();
  fill(255);
  rect(x, 0, 3*W, H);
  image(img, x+1.5*W, 0.5*H);
}

void draw_nome (float x, String nome, boolean ok) {
  float y = (CFG_IMGS ? H : 0);
  float h = (CFG_IMGS ? H : 2*H);
  int SZ  = (CFG_IMGS ? 70 : 85);

  stroke(0);
  fill(255);
  rect(x, y, 3*W, h);
  //image(IMG1, x+1.5*W, 1*H);
  if (ok) {
    fill(0, 0, 255);
  } else {
    nome = nome + "_";
    fill(255, 0, 0);
  }
  textSize(SZ*dy);
  textAlign(CENTER, CENTER);
  text(nome, x+1.5*W, h+H/2-10*dy);
}

void draw_recorde (float x, float v, boolean batido) {
  if (batido) {
    fill(255,100,100);
  } else {
    fill(255);
  }
  textSize(35*dy);
  textAlign(CENTER, BOTTOM);
  text("Máx: " + nf(v/100,2,2), x, height);
}

/*
void draw_dist (float x, String dist) {
  fill(100,100,100);
  textSize(25*dy);
  textAlign(CENTER, BOTTOM);
  text(dist, x, height);
}
*/

void draw_juiz (float x, String nome, boolean ok) {
  if (ok) {
    fill(100,100,100);
  } else {
    fill(255,0,0);
    nome = nome + "_";
  }
  textSize(25*dy);
  textAlign(CENTER, BOTTOM);
  text("Árbitro: " + nome, x, height);
}

void draw_ultima (float x1, float x2, int ultima) {
  noStroke();
  fill(255);
  rect(x1, 2*H, 3.5*W, 2*H);

  fill(0);
  textAlign(CENTER, CENTER);

  if (ultima != 0) {
    textSize(160*dy);
    text(ultima, x2, 3*H-50*dy);
    textSize(40*dy);
    text("km/h", x2, 3*H+70*dy);
  }
}

void draw_quedas (int quedas) {
  noStroke();
  fill(255);
  rect(4*W, 2*H, W, H);


/*
  fill(0);
  textSize(30*dy);
  text("Quedas", width/2, H+5*dy);
*/

  fill(255, 0, 0);
  ellipseMode(CENTER);
  ellipse(4.5*W, 2.5*H+20*dy, H-10*dy, H-10*dy);

  fill(255);
  textAlign(CENTER, CENTER);
  textSize(100*dy);
  text(quedas, width/2, 2.5*H+10*dy);
}

void draw_golpes (int golpes) {
  noStroke();
  fill(255);
  rect(3.5*W, 3*H+20*dy, W, H-20*dy);

  fill(0);
  textAlign(CENTER, CENTER);

  textSize(60*dy);
  text(golpes, 4*W, 3.5*H-20*dy);

  textSize(20*dy);
  text("Golpes", 4*W, 3.5*H+30*dy);
}

void draw_media (int media, boolean apply) {
  noStroke();
  fill(255);
  rect(4.5*W, 3*H+20*dy, W, H-20*dy);

  fill(0);
  textAlign(CENTER, CENTER);

  textSize(60*dy);
  if (apply) {
    text(media, 5*W, 3.5*H-20*dy);
  } else {
    text("-",   5*W, 3.5*H-20*dy);
  }

  textSize(20*dy);
  text("km/h", 5*W, 3.5*H+30*dy);
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

void draw_lado (float x, float w, int cor, String lado, int pct, int avg) {
  noStroke();
  fill(cor);
  rect(x, 2*H, w, 2*H);

  textAlign(CENTER, CENTER);
  fill(0);

  textSize(20*dy);
  text(lado,   x+w/2, 3*H-65*dy);

  textSize(80*dy);
  text(avg,    x+w/2, 3*H-10*dy);

  textSize(20*dy);
  text("km/h", x+w/2, 3*H+60*dy);

  textAlign(CENTER, BOTTOM);
  fill(100,100,100);
  textSize(20*dy);
  text("("+pct+"%)", x+w/2, 4*H-20*dy);
}

void draw_pontos (float x, float pontos, boolean is_behind) {
  noStroke();
  if (is_behind) {
      fill(255,0,0);
  } else {
      fill(255);
  }
  rect(x, 4*H, 2*W, 2*H);

  if (is_behind) {
      fill(255);
  } else {
      fill(0);
  }
  textSize(70*dy);
  textAlign(CENTER, CENTER);
  text(nf(pontos/100,2,2), x+1*W, 5*H-10*dy);
}

void draw_total (float total, int acum) {
  noStroke();
  fill(0);
  rect(2*W, 4*H, 5*W, 2*H);
  fill(255);
  textAlign(CENTER, CENTER);

  if (CFG_ACUM) {
    textSize(110*dy);
    text(acum, width/2, 4.75*H-15*dy);
    textSize(55*dy);
    text("("+nf(total/100,2,2)+")", width/2, 5.5*H-15*dy);
  } else {
    textSize(140*dy);
    text(nf(total/100,2,2), width/2, 5*H-15*dy);
  }
}
