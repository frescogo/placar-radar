String  CFG_PORTA   = "COM6";
int     CFG_RECORDE = 0;
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
PImage   IMG_SPEED;
PImage   IMG_RAQUETE;
PImage   IMG_BAND;
PImage   IMG_APITO;
PImage   IMG_TROFEU;
PImage   IMG_DESCANSO;

String   VERSAO       = "FrescoGO! r3.1.0";
String   PARS         = "(?)";
String   PARSS[]      = {};

String[] PORTAS = { "/dev/ttyACM", "/dev/ttyUSB", "COM" };

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
int      TEMPO_DESC;
int      PONTOS_TOTAL;
int      QUEDAS;
int      GOLPES_TOT;
int      IS_DESEQ;

int      GOLPE_IDX;
int      GOLPE_CLR;
int      GOLPE_TMR = 0;

String[]  NOMES   = new String[3];
int[]     ULTIMAS = new int[2];
int[][]   JOGS    = new int[2][3];

int REF_TIMEOUT = 240;
int REF_BESTS   = 20;
//int REF_REVES   = 3/5;
int REF_CONT    = 15;
int HITS_NRM    = 0;  //(S.timeout*REF_BESTS/REF_TIMEOUT/1000)
int HITS_REV    = 0;  //HITS_NRM*REF_REVES

float dy; // 0.001 height
float dx; // 0.001 width

float W;
float H;

void setup () {
    serial_liga();

    while (SERIAL.available() == 0) {
        // wait
        println("Reinicie o Arduino...");
        delay(1000);
    }
    char c = SERIAL.readChar();
    if (c != 1) {
        println("Arduino nao encontrado, tente novamente...");
        return;
    }
    SERIAL.write(1);      // envia MOD_PC
    println("OK");

    surface.setTitle(VERSAO);
    //size(640, 480);
    size(1024, 768);
    //fullScreen();

    dy = 0.001 * height;
    dx = 0.001 * width;

    W = width  / 11.0;
    H = height /  8.0;

    IMG1         = loadImage(CFG_IMG1);
    IMG2         = loadImage(CFG_IMG2);
    IMG_SPEED    = loadImage("speed-03.png");
    IMG_RAQUETE  = loadImage("raq-03.png");
    IMG_BAND     = loadImage("flag.png");
    IMG_APITO    = loadImage("apito-04.png");
    IMG_TROFEU   = loadImage("trophy-02.png");
    IMG_DESCANSO = loadImage("timeout-03.png");

    IMG1.resize(0,height/8);
    IMG2.resize(0,height/8);
    IMG_SPEED.resize(0,(int)(45*dy));
    IMG_RAQUETE.resize(0,(int)(50*dy));
    IMG_BAND.resize(0,(int)(40*dy));
    IMG_APITO.resize(0,(int)(30*dy));
    IMG_TROFEU.resize(0,(int)(30*dy));
    IMG_DESCANSO.resize(0,(int)(25*dy));

    imageMode(CENTER);
    tint(255, 128);

    zera();

    textFont(createFont("LiberationSans-Bold.ttf", 18));
}

void zera () {
    IS_FIM       = false;
    TEMPO_JOGADO = 0;
    TEMPO_EXIBIDO = 0;
    TEMPO_DESC   = 0;
    PONTOS_TOTAL = 0;
    QUEDAS       = 0;
    GOLPES_TOT   = 0;
    IS_DESEQ     = 255;

    GOLPE_IDX    = 255;

    NOMES[0]     = "Esquerda";
    NOMES[1]     = "Direita";
    NOMES[2]     = "Árbitro";
}

///////////////////////////////////////////////////////////////////////////////
// SERIAL
///////////////////////////////////////////////////////////////////////////////

void serial_liga () {
    try {
        SERIAL = new Serial(this, CFG_PORTA, 9600);
        return;
    } catch (RuntimeException e) {
        // error, try PORTAS
    }
    for (int i=0; i<PORTAS.length; i++) {
        for (int j=0; j<10; j++) {
            try {
                SERIAL = new Serial(this, PORTAS[i]+j, 9600);
                println(PORTAS[i]+j);
                return;
            } catch (RuntimeException e) {
                // error, try next
            }
        }
    }
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

void trata_nome (int idx, String lado) {
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
            trata_nome(0, "esquerda");
            break;
        case 1: // DIGITANDO DIR
            trata_nome(1, "direita");
            break;
        case 2: // DIGITANDO JUIZ
            trata_nome(2, "juiz");
            break;
    }
}

///////////////////////////////////////////////////////////////////////////////
// LOOP
///////////////////////////////////////////////////////////////////////////////

void draw () {
    if (PARSS.length > 0) {
        draw_tudo(false);
    }

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
    print(">>>", linha);
    if (linha.equals("ok\r\n")) {
        return;
    }

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
            PARSS        = match(PARS, "r(\\d+)/(\\d+)s/ata(\\d+)/equ\\d/cont\\d+/fim\\d+");

            HITS_NRM = TEMPO_TOTAL * REF_BESTS / REF_TIMEOUT;
            HITS_REV = HITS_NRM * 3 / 5; //REF_REVES;
            break;
        }

        // SEQ
        case 1: {
            IS_FIM       = false; // por causa do UNDO
            TEMPO_JOGADO = int(campos[1]);
            TEMPO_DESC   = int(campos[2]);
            QUEDAS       = int(campos[3]);
            NOMES[0]     = campos[4];
            NOMES[1]     = campos[5];
            NOMES[2]     = campos[6];
            TEMPO_EXIBIDO = TEMPO_JOGADO;
            break;
        }

        // HIT
        case 2: {
            int idx         = int(campos[1]);
            boolean is_back = int(campos[2]) == 1;
            ULTIMAS[idx]    = int(campos[3]);

            GOLPE_IDX = 1-idx;  // is_out=1 becomes 0 to be in the left
            GOLPE_CLR = (is_back ? color(255,0,0) : color(0,0,255));
            GOLPE_TMR = millis();
            break;
        }

        // TICK
        case 3: {
            TEMPO_JOGADO = int(campos[1]);
            PONTOS_TOTAL = int(campos[2]);
            GOLPES_TOT   = int(campos[3]);
            player(campos, 0, 4);
            player(campos, 1, 4+4);

            if (TEMPO_JOGADO >= (TEMPO_EXIBIDO-TEMPO_EXIBIDO%5)+5) {
                TEMPO_EXIBIDO = TEMPO_JOGADO;
            }
            break;
        }

        // FALL
        case 4: {
            QUEDAS = int(campos[1]);
            player(campos, 0, 2);
            player(campos, 1, 2+4);
            TEMPO_EXIBIDO = TEMPO_JOGADO;
            GOLPE_IDX     = 255;
            ULTIMAS[0]    = 0;
            ULTIMAS[1]    = 0;
            break;
        }

        // END
        case 5: {
            player(campos, 0, 1);
            player(campos, 1, 1+4);
            GRAVANDO  = 1;    // salva o jogo no frame seguinte
            IS_FIM    = true;
            TEMPO_EXIBIDO = TEMPO_JOGADO;
            GOLPE_IDX = 255;
            if (PONTOS_TOTAL > CFG_RECORDE) {
                CFG_RECORDE = PONTOS_TOTAL;
            }
            break;
        }

        // DESC
        case 6: {
            TEMPO_DESC = int(campos[1]);
            break;
        }
    }
}

void player (String[] campos, int p, int i) {
    boolean is_beh = (int(campos[i++]) == 1) && (TEMPO_JOGADO >= 30);
    JOGS[p][0] = int(campos[i++]);  // pontos
    JOGS[p][1] = int(campos[i++]);  // golpes
    JOGS[p][2] = int(campos[i++]);  // media1

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
        draw_logo(0*W, IMG1);
        draw_logo(7*W, IMG2);
    }
    draw_nome(0*W, ZER, DIGITANDO!=ZER);
    draw_nome(7*W, ONE, DIGITANDO!=ONE);

    // TEMPO
    {
        int tempo = TEMPO_TOTAL-TEMPO_EXIBIDO;
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
        rect(4*W, 0, 3*W, 3*H);

        fill(255);
        textSize(120*dy);
        textAlign(CENTER, CENTER);
        text(mins+":"+segs, width/2, 1.25*H-10*dy);

        fill(150,150,150);
        textSize(25*dy);
        textAlign(CENTER, CENTER);
        text(TEMPO_DESC+" s", width/2, 2.25*H);
        float w = textWidth(TEMPO_DESC+" s");
        image(IMG_DESCANSO, width/2-w-15*dx, 2.25*H);

        // params
        fill(150,150,150);
        textSize(12*dy);
        textAlign(CENTER, BOTTOM);
        text(PARS, width/2, 3*H+10*dy);
    }

    // VERSAO
    fill(150,150,150);
    textSize(15*dy);
    textAlign(CENTER, TOP);
    textAlign(CENTER, TOP);
    text(VERSAO, width/2, 0);

    // INVERTIDO?
    if (IS_INVERTIDO) {
        text("inv", width/2, 30*dy);
    }

    // MEIO
    stroke(0);
    fill(255);
    rect(0, 3*H, 11*W, 2*H-1);

    // QUEDAS
    {
        fill(255, 0, 0);
        ellipseMode(CENTER);
        ellipse(width/2, height/2, 1.5*H, 1.5*H);

        fill(255);
        textAlign(CENTER, CENTER);
        textSize(90*dy);
        text(QUEDAS, width/2, height/2-15*dy);
    }

    if (GOLPE_IDX != 255) {
        draw_ultima(1.5*W, ULTIMAS[ZER]);
        draw_ultima(9.5*W, ULTIMAS[ONE]);

        if (millis() <= GOLPE_TMR+500) {
            //ellipseMode(CENTER);
            //fill(GOLPE_CLR);
            //noStroke();
            stroke(GOLPE_CLR);
            strokeWeight(10*dy);
            if (GOLPE_IDX == ZER) {
                //ellipse(3*W, 4*H, 60*dy, 60*dy);
                line(2.5*W, 4*H, 2.5*W+60*dy, 4*H);
                line(2.5*W+60*dy, 4*H, 2.5*W+45*dy, 4*H+20*dy);
                line(2.5*W+60*dy, 4*H, 2.5*W+45*dy, 4*H-20*dy);
            } else {
                //ellipse(8*W, 4*H, 60*dy, 60*dy);
                line(8.5*W, 4*H, 8.5*W-60*dy, 4*H);
                line(8.5*W-60*dy, 4*H, 8.5*W-45*dy, 4*H-20*dy);
                line(8.5*W-60*dy, 4*H, 8.5*W-45*dy, 4*H+20*dy);
            }
            strokeWeight(1);
        }
    } else {
        // TODO: propaganda?
    }

    draw_lado(1.5*W, color(255,255,255), JOGS[ZER], false);
    draw_lado(7.5*W, color(255,255,255), JOGS[ONE], false);

    textSize(15*dy);
    fill(150,150,150);
    for (int i=0; i<2; i++) {
        float off = (i==0) ? 1*W : 10*W;
        noStroke();
        noFill();

        image(IMG_RAQUETE, off, 5.5*H+5*dy);

        image(IMG_SPEED, off, 6.5*H+5*dy);
        textAlign(CENTER, CENTER);
        fill(100,100,100);
        textSize(10*dy);
        text("km/h", off, 6.5*H+25*dy);

        image(IMG_BAND, off, 7.5*H+10*dy);
    }

    {
        noStroke();
        fill(0);
        rect(4*W, 5*H, 3*W, 3*H);

        // juiz
        String nome = NOMES[2];
        if (DIGITANDO != 2) {
            fill(150,150,150);
        } else {
            fill(255,0,0);
            nome = nome + "_";
        }
        textSize(20*dy);
        textAlign(CENTER, TOP);
        text(nome, width/2, 5*H+12*dy);
        float w1 = textWidth(nome);
        image(IMG_APITO, width/2-w1/2-15*dx, 5*H+20*dy);

        // recorde
        if (PONTOS_TOTAL > CFG_RECORDE) {
            fill(150,150,150);
        } else {
            fill(200,100,100);
        }
        textSize(35*dy);
        textAlign(CENTER, CENTER);
        text(CFG_RECORDE, width/2, 6*H-5*dy);
        float w2 = textWidth(str(CFG_RECORDE));
        image(IMG_TROFEU, width/2-w2/2-25*dx, 6*H);

        // TOTAL
        fill(255);
        textSize(120*dy);
        textAlign(CENTER, CENTER);
        text(PONTOS_TOTAL, width/2, 7*H);
    }

    //draw_dist(4.5*W, DIST);

    if (is_end) {
        fill(255);
        textSize(50*dy);
        textAlign(CENTER, CENTER);
        text("Aguarde...", width/2, 0.35*H);
    }

    if (SERIAL == null) {
        ellipseMode(CENTER);
        fill(255,0,0);
        noStroke();
        ellipse(width-50*dy, height-50*dy, 20*dy, 20*dy);
    }
}

void draw_logo (float x, PImage img) {
    noStroke();
    fill(255);
    rect(x, 0, 4*W, 2*H);
    image(img, x+2*W, H);
}

void draw_nome (float x, int idx, boolean ok) {
    String nome = NOMES[idx];
    stroke(0);
    fill(255);
    rect(x, 2*H, 4*W, H);
    //image(IMG1, x+1.5*W, 1*H);
    if (ok) {
        noStroke();
        if (IS_DESEQ==idx && EQUILIBRIO) {
            fill(255, 0, 0);
            rect(x+3*dx, 2*H+2*dy, 4*W-6*dx, H-4*dy);
            fill(255);
        } else {
            fill(00);
        }
    } else {
        nome = nome + "_";
        fill(255, 0, 0);
    }
    textSize(60*dy);
    textAlign(CENTER, CENTER);
    text(nome, x+2*W, 2.5*H-10*dy);
}

/*
void draw_dist (float x, String dist) {
    fill(100,100,100);
    textSize(25*dy);
    textAlign(CENTER, BOTTOM);
    text(dist, x, height);
}
*/

void draw_ultima (float x, int kmh) {
    if (kmh == 0) {
        return;
    }
    if (kmh >= 50) {
        fill(0);
    } else {
        fill(200,200,200);
    }
    textAlign(CENTER, BOTTOM);
    textSize(90*dy);
    text(kmh, x, 4*H+20*dy);
    textAlign(CENTER, TOP);
    textSize(40*dy);
    text("km/h", x, 4*H+20*dy);
}

void draw_lado (float x, int cor, int[] dados, boolean is_esq) {
    noStroke();
    fill(cor);
    rect(x, 5*H, 2*W, 3*H);
    fill(0);
    textAlign(CENTER, CENTER);

    int limite = int(PARSS[3]);

    textSize(15*dy);
    text("." + nf(dados[2]%100,2), x+W+30*dx, 6.5*H+15*dy);   // media1

    textSize(50*dy);
    text(dados[2]/100, x+W, 6.5*H);         // media1
    text(dados[0], x+W, 7.5*H);             // pontos

    if (dados[1] >= limite) {             // golpes vs limite
        fill(255,0,0);
    }
    text(dados[1], x+W, 5.5*H);             // golpes
    fill(150,150,150);
    textSize(20*dy);
    float w1 = textWidth(str(dados[1]));    // golpes
    textAlign(TOP, LEFT);
    text("/"+limite, x+W+w1+10*dx, 5.5*H+30*dy);  // limite

    textSize(15*dy);
    textAlign(CENTER, CENTER);
    text("(x)", x+W, 6*H);
    text("(=)", x+W, 7*H);
}
