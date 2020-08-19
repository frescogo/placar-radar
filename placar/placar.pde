///opt/processing-3.5.3/processing-java --sketch=/data/frescogo/placar/placar --run

// - params
// - RADAR

import processing.serial.*;
import processing.sound.*;

SoundFile[] SNDS = new SoundFile[7];
SoundFile[] HITS = new SoundFile[4];

Serial   SERIAL;

JSONObject CONF;

int      CONF_DISTANCIA;
int      CONF_TEMPO;
boolean  CONF_EQUILIBRIO;
int      CONF_RECORDE;
String[] CONF_NOMES = new String[3];

PImage   IMG1;
PImage   IMG2;
PImage   IMG_SPEED;
PImage   IMG_RAQUETE;
PImage   IMG_BAND;
PImage   IMG_APITO;
PImage   IMG_TROFEU;
PImage   IMG_DESCANSO;

String   VERSAO = "FrescoGO! 3.1.0";

String   ESTADO = "ocioso";         // ocioso, digitando, jogando, terminando, terminado
int      ESTADO_DIGITANDO = 255;    // 0=esq, 1=dir, 2=arbitro
String   ESTADO_JOGANDO;            // sacando, jogando

ArrayList<ArrayList> JOGO = new ArrayList<ArrayList>();

boolean  INV = false;
int      ZER = 0;
int      ONE = 1;

int TEMPO_DESCANSO, TEMPO_DESCANSO_INICIO;
int OLD_TEMPO_RESTANTE;

float dy; // 0.001 height
float dx; // 0.001 width

float W;
float H;

String ns (String str, int n) {
    int len = str.length();
    for (int i=0; i<n-len; i++) {
        str += " ";
    }
    return str;
}

int conf_limite () {
    return max(1, CONF_TEMPO * 20 / 60);
}

String conf_pars () {
    return "(?)";
}

int conf_quedas () {
    return 800 * 60 / CONF_TEMPO;   // 8% / 60s
}

int tempo_jogado () {
    int ret = 0;
    for (int i=0; i<JOGO.size(); i++) {
        ArrayList<int[]> seq = JOGO.get(i);
        if (seq.size() >= 2) {
            ret += (seq.get(seq.size()-1)[0] - seq.get(0)[0]);
        }
    }
    //if (ESTADO.equals("jogando") && ESTADO_JOGANDO.equals("jogando")) {
    //    ArrayList<int[]> seq = JOGO.get(JOGO.size()-1);
    //    ret += millis() - seq.get(seq.size()-1)[0];
    //}
    return ret / 1000 / 5 * 5;
}

int quedas () {
    return JOGO.size() + (ESTADO.equals("jogando") ? -1 : 0);
}

int KMH (ArrayList<int[]> seq, int i) {
    int[] cur = seq.get(i);
    int kmh = cur[2];
    if (kmh != 0) {
        return kmh;
    } else {
        if (seq.size() < i+2) {
            return 0;
        } else {
            int[] nxt = seq.get(i+1);
            return 36 * CONF_DISTANCIA / (nxt[0] - cur[0]);
        }
    }
}

int[] jogador (int idx) {
    IntList kmhs = new IntList();
    for (int i=0; i<JOGO.size(); i++) {
        ArrayList<int[]> seq = JOGO.get(i);
        for (int j=0; j<seq.size()-1; j++) {    // -1: ignora ultimo golpe
            int[] golpe = seq.get(j);
            if (golpe[1] == idx) {
                int kmh = KMH(seq,j);
                if (kmh >= 50) {
                    kmhs.append(KMH(seq,j));
                }
            }
        }
    }
    kmhs.sortReverse();
    int N = min(conf_limite(),kmhs.size());
    int sum = 0;
    for (int i=0; i<N; i++) {
        sum += kmhs.get(i);
    }
    int[] ret = { sum, kmhs.size(), sum*100/max(1,N) };
    return ret;
}

int[] TOTAL (int[] jog0, int[] jog1) {
    int p0   = jog0[0];
    int p1   = jog1[0];

    int avg  = (p0 + p1) / 2;
    int min_ = min(avg, min(p0,p1)*110/100);

    int beh = 255;
    if (avg != min_) {
        beh = (p0 > p1) ? 1 : 0;
    }

    int pct  = quedas() * conf_quedas();
    int pts  = (CONF_EQUILIBRIO ? min_ : avg);
    int tot  = pts * (10000-pct) / 10000;

    int[] ret = { tot, beh };
    return ret;
}

void setup () {
    surface.setTitle(VERSAO);
    size(600, 300);
    //size(1024, 768);
    //fullScreen();

    dy = 0.001 * height;
    dx = 0.001 * width;

    W = width  / 11.0;
    H = height /  8.0;

    CONF = loadJSONObject("conf.json");
    CONF_DISTANCIA  = CONF.getInt("distancia");
    CONF_TEMPO      = CONF.getInt("tempo");
    CONF_EQUILIBRIO = CONF.getBoolean("equilibrio");
    CONF_RECORDE    = CONF.getInt("recorde");
    CONF_NOMES[0]   = CONF.getString("atleta1");
    CONF_NOMES[1]   = CONF.getString("atleta2");
    CONF_NOMES[2]   = CONF.getString("arbitro");

    SNDS[0] = new SoundFile(this,"fall.wav");
    SNDS[1] = new SoundFile(this,"restart.wav");
    SNDS[2] = new SoundFile(this,"30s.wav");
    SNDS[3] = new SoundFile(this,"finish.wav");
    SNDS[4] = new SoundFile(this,"undo.wav");
    SNDS[5] = new SoundFile(this,"start.wav");
    SNDS[6] = new SoundFile(this,"behind.wav");

    HITS[0] = new SoundFile(this,"hit-00.mp3");
    HITS[1] = new SoundFile(this,"hit-01.wav");
    HITS[2] = new SoundFile(this,"hit-02.mp3");
    HITS[3] = new SoundFile(this,"hit-03.wav");

    IMG1         = loadImage(CONF.getString("imagem1"));
    IMG2         = loadImage(CONF.getString("imagem2"));
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
    textFont(createFont("LiberationSans-Bold.ttf", 18));

    try {
        SERIAL = new Serial(this, Serial.list()[0], 9600);
    } catch (RuntimeException e) {
        println("Erro na comunicação com o radar...");
        //exit();
    }

    reinicio();
}

void sound (int kmh) {
    if (kmh < 50) {
        HITS[0].play();
    } else if (kmh < 65) {
        HITS[1].play();
    } else if (kmh < 80) {
        HITS[2].play();
    } else {
        HITS[3].play();
    }
}

void reinicio () {
    ESTADO = "ocioso";
    JOGO = new ArrayList<ArrayList>();
    TEMPO_DESCANSO = 0;
    OLD_TEMPO_RESTANTE = CONF_TEMPO;
    SNDS[1].play();
}

///////////////////////////////////////////////////////////////////////////////
// KEYBOARD
///////////////////////////////////////////////////////////////////////////////

int ctrl (char key) {
    return char(int(key) - int('a') + 1);
}

void trata_nome (int idx, String json) {
    if (key==ENTER || key==RETURN) {
        CONF.setString(json, CONF_NOMES[idx]);
        ESTADO_DIGITANDO = 255;
        ESTADO = "ocioso";
    } else if (key==BACKSPACE) {
        if (CONF_NOMES[idx].length() > 0) {
            CONF_NOMES[idx] = CONF_NOMES[idx].substring(0, CONF_NOMES[idx].length()-1);
        }
    } else if (int(key)>=int('a') && int(key)<=int('z') || int(key)>=int('A') && int(key)<=int('Z') || key=='_'){
        CONF_NOMES[idx] = CONF_NOMES[idx] + key;
        //println(">>>", key);
    }
}

void keyPressed (KeyEvent e) {
    if (key==ESC && !e.isControlDown()) {
        key = 0;
    }

    if (ESTADO.equals("ocioso")) {
        if (e.isControlDown()) {
            if (keyCode == '0') {               // CTRL-0
                ESTADO = "digitando";
                ESTADO_DIGITANDO = 2;
                CONF_NOMES[2] = "";
            } else if (keyCode == '1') {        // CTRL-1
                ESTADO = "digitando";
                ESTADO_DIGITANDO = 0;
                CONF_NOMES[0] = "";
            } else if (keyCode == '2') {        // CTRL-2
                ESTADO = "digitando";
                ESTADO_DIGITANDO = 1;
                CONF_NOMES[1] = "";
            } else if (keyCode == 'I') {        // CTRL-I
                INV = !INV;
                ZER = 1 - ZER;
                ONE = 1 - ONE;

            } else if (keyCode == 38) {         // CTRL-UP
                ESTADO = "jogando";
                ESTADO_JOGANDO = "sacando";
                TEMPO_DESCANSO_INICIO = millis();
                JOGO.add(new ArrayList<int[]>());
                SNDS[5].play();
            } else if (keyCode == 8) {          // CTRL-BACKSPACE
                if (JOGO.size() > 0) {
                    JOGO.remove(JOGO.size()-1);
                    SNDS[4].play();
                }
            } else if (keyCode == 'R') {        // CTRL-R
                reinicio();
            }
        }
    } else if (ESTADO.equals("digitando")) {
        switch (ESTADO_DIGITANDO) {
            case 0: // DIGITANDO ESQ
                trata_nome(0, "atleta1");
                break;
            case 1: // DIGITANDO DIR
                trata_nome(1, "atleta2");
                break;
            case 2: // DIGITANDO ARBITRO
                trata_nome(2, "arbitro");
                break;
        }
    } else if (ESTADO.equals("terminado")) {
        if (e.isControlDown() && !e.isAltDown()) {
            if (keyCode == 'R') {               // CTRL-R
                reinicio();
            }
        }
    } else if (ESTADO.equals("jogando")) {
        int now = millis();
//println(keyCode);
        if (e.isControlDown() && keyCode==40) {
            ESTADO = "ocioso";
            SNDS[0].play();
        } else if (keyCode==37 || keyCode==39) { // CTRL-LEFT/RIGHT
            if (ESTADO_JOGANDO.equals("sacando")) {
                ESTADO_JOGANDO = "jogando";
                TEMPO_DESCANSO += max(0, now-TEMPO_DESCANSO_INICIO-5000);
            }
            int idx = (keyCode == 37) ? ZER : ONE;
            int[] golpe = { now, idx, 0 };
            ArrayList<int[]> seq = JOGO.get(JOGO.size()-1);
            seq.add(golpe);
            int kmh = 0;
            if (seq.size() >= 2) {
                kmh = KMH(seq, seq.size()-2);
            }
            sound(kmh);
        }
    }
}

///////////////////////////////////////////////////////////////////////////////
// LOOP
///////////////////////////////////////////////////////////////////////////////

void draw () {
    draw_tudo(false);

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
    // TODO
}

///////////////////////////////////////////////////////////////////////////////
// DRAW
///////////////////////////////////////////////////////////////////////////////

void draw_tudo (boolean is_end) {
    int[] jog0  = jogador(ZER);
    int[] jog1  = jogador(ONE);
    int[] total = TOTAL(jog0,jog1);

    if (ESTADO == "terminando") {
        ESTADO = "terminado";
        String ts = "" + year() + "-" + nf(month(),2) + "-" + nf(day(),2) + "_"
                       + nf(hour(),2) + ":" + nf(minute(),2) + ":" + nf(second(),2);
        saveFrame("relatorios/frescogo-"+ts+"-"+CONF_NOMES[0]+"-"+CONF_NOMES[1]+"-placar.png");
        draw_tudo(true);

        String out = ns("Data:",    15) + ts + "\n"
                   //+ ns("Atletas:", 15) + CONF_NOMES[0] + " e " + CONF_NOMES[1] + "\n"
                   + "\n"
                   + ns(CONF_NOMES[0]+":",15) +
                     jog0[0] + " pontos = " +
                     min(conf_limite(),jog0[1]) + " atas X " +
                     nf(jog0[2]/100,2) + "." + nf(jog0[2]%100,2) + " km/h" + "\n"
                   + ns(CONF_NOMES[1]+":",15) +
                     jog1[0] + " pontos = " +
                     min(conf_limite(),jog1[1]) + " atas X " +
                     nf(jog1[2]/100,2) + "." + nf(jog1[2]%100,2) + " km/h" + "\n"
                   + "\n"
                   + ns("Descanso:", 15) + (TEMPO_DESCANSO/1000) + "\n"
                   + ns("Quedas:",   15) + quedas() + "\n"
                   + ns("Total:",    15) + total[0] + " pontos\n"
                   + "\n";
        for (int i=0; i<JOGO.size(); i++) {
            ArrayList<int[]> seq = JOGO.get(i);
            out += "SEQUÊNCIA " + nf(i+1,2) + "\n============\n\nTEMPO   DIR   KMH\n-----   ---   ---\n";
            for (int j=0; j<seq.size(); j++) {
                int[] golpe = seq.get(j);
                out += nf(golpe[0],6) + "   " + (golpe[1]==0 ? "->" : "<-") + "   " + nf(KMH(seq,j),3) + "\n";
            }
            out += "\n\n";
        }
        String[] outs = { out };
        String name = "relatorios/frescogo-"+ts+"-"+CONF_NOMES[0]+"-"+CONF_NOMES[1]+".txt";
        saveStrings(name, outs);
    }

    int t = tempo_jogado();

    background(255,255,255);

    draw_logo(0*W, IMG1);
    draw_logo(7*W, IMG2);

    draw_nome(0*W, ZER, (CONF_EQUILIBRIO && t>=30 && total[1]==ZER),
              ESTADO_DIGITANDO==ZER);
    draw_nome(7*W, ONE, (CONF_EQUILIBRIO && t>=30 && total[1]==ONE),
              ESTADO_DIGITANDO==ONE);

    // TEMPO
    {
        int tempo_restante = max(0, CONF_TEMPO-t);
        if (OLD_TEMPO_RESTANTE>30 && tempo_restante<=30) {
            SNDS[2].play();
        }
        OLD_TEMPO_RESTANTE = tempo_restante;
        if (tempo_restante<=0 && ESTADO=="jogando") {
            ESTADO = "terminando";
            SNDS[3].play();
            if (total[0] > CONF_RECORDE) {
                CONF_RECORDE = total[0];
            }
        }
        String mins = nf(tempo_restante / 60, 2);
        String segs = nf(tempo_restante % 60, 2);

        if (tempo_restante == 0) {
            fill(255,0,0);
        } else {
            fill(0);
        }
        rect(4*W, 0, 3*W, 3*H);

        fill(255);
        textSize(120*dy);
        textAlign(CENTER, CENTER);
        text(mins+":"+segs, width/2, 1.25*H-10*dy);

        int descanso = TEMPO_DESCANSO;
        if (ESTADO.equals("jogando") && ESTADO_JOGANDO.equals("sacando")) {
            descanso += max(0, millis()-TEMPO_DESCANSO_INICIO-5000);
        }
        descanso /= 1000;

        fill(150,150,150);
        textSize(25*dy);
        textAlign(CENTER, CENTER);
        text(descanso+" s", width/2, 2.25*H);
        float w = textWidth(descanso+" s");
        image(IMG_DESCANSO, width/2-w-15*dx, 2.25*H);

        // params
        fill(150,150,150);
        textSize(12*dy);
        textAlign(CENTER, BOTTOM);
        text(conf_pars(), width/2, 3*H+10*dy);
    }

    // VERSAO
    fill(150,150,150);
    textSize(15*dy);
    textAlign(CENTER, TOP);
    textAlign(CENTER, TOP);
    text(VERSAO, width/2, 0);

    // INVERTIDO?
    if (INV) {
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
        text(quedas(), width/2, height/2-15*dy);
    }

    if (ESTADO == "jogando") {
        ArrayList<int[]> seq = JOGO.get(JOGO.size()-1);
        int idx = 255;
        for (int i=1; i<=2; i++) {
            if (seq.size() < i) {
                continue;
            }

            int[] golpe = seq.get(seq.size()-i); // millis/idx/kmh
            if (golpe[1] == idx) {
                // mesmo jogador deu os ultimos dois golpes
            } else {
                idx = golpe[1];
                if (millis() <= golpe[0]+1000) {
                    int kmh = golpe[2];
                    if (kmh == 0) {
                        int xxx = seq.size() - i - 1;
                        if (xxx >= 0) {
                            kmh = KMH(seq, seq.size()-i-1);
                            if (idx == ONE) {
                                draw_ultima(1.5*W, kmh);
                            } else {
                                draw_ultima(9.5*W, kmh);
                            }
                        }
                    } else {
                        if (idx == ZER) {
                            draw_ultima(1.5*W, kmh);
                        } else {
                            draw_ultima(9.5*W, kmh);
                        }
                    }
                }
                if (millis() <= golpe[0]+500) {
                    stroke(color(0,0,255));
                    strokeWeight(10*dy);
                    if (idx == ZER) {
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
            }
        }
    }

    draw_lado(1.5*W, jog0);
    draw_lado(7.5*W, jog1);

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
        String nome = CONF_NOMES[2];
        if (ESTADO_DIGITANDO != 2) {
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
        if (total[0] >= CONF_RECORDE) {
            fill(150,150,150);
        } else {
            fill(200,100,100);
        }
        textSize(35*dy);
        textAlign(CENTER, CENTER);
        text(CONF_RECORDE, width/2, 6*H-5*dy);
        float w2 = textWidth(str(CONF_RECORDE));
        image(IMG_TROFEU, width/2-w2/2-25*dx, 6*H);

        // TOTAL
        fill(255);
        textSize(120*dy);
        textAlign(CENTER, CENTER);
        text(total[0], width/2, 7*H);
    }


    if (is_end) {
        fill(255);
        textSize(50*dy);
        textAlign(CENTER, CENTER);
        text("Aguarde...", width/2, 0.35*H);
    }
}

void draw_logo (float x, PImage img) {
    noStroke();
    fill(255);
    rect(x, 0, 4*W, 2*H);
    image(img, x+2*W, H);
}

void draw_nome (float x, int idx, boolean beh, boolean digitando) {
    String nome = CONF_NOMES[idx];
    stroke(0);
    fill(255);
    rect(x, 2*H, 4*W, H);
    //image(IMG1, x+1.5*W, 1*H);
    if (digitando) {
        nome = nome + "_";
        fill(255, 0, 0);
    } else {
        noStroke();
        if (beh) {
            fill(255, 0, 0);
            rect(x+3*dx, 2*H+2*dy, 4*W-6*dx, H-4*dy);
            fill(255);
        } else {
            fill(00);
        }
    }
    textSize(60*dy);
    textAlign(CENTER, CENTER);
    text(nome, x+2*W, 2.5*H-10*dy);
}

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

void draw_lado (float x, int[] jog) {
    noStroke();
    fill(color(255,255,255));
    rect(x, 5*H, 2*W, 3*H);
    fill(0);
    textAlign(CENTER, CENTER);

    textSize(15*dy);
    text("." + nf(jog[2]%100,2), x+W+30*dx, 6.5*H+15*dy);   // media1

    textSize(50*dy);
    text(jog[2]/100, x+W, 6.5*H);         // media1
    text(jog[0], x+W, 7.5*H);             // pontos

    if (jog[1] >= conf_limite()) {        // golpes vs limite
        fill(255,0,0);
    }
    text(jog[1], x+W, 5.5*H);             // golpes
    fill(150,150,150);
    textSize(20*dy);
    float w1 = textWidth(str(jog[1]));    // golpes
    textAlign(TOP, LEFT);
    text("/"+conf_limite(), x+W+w1+10*dx, 5.5*H+30*dy);  // limite

    textSize(15*dy);
    textAlign(CENTER, CENTER);
    text("(x)", x+W, 6*H);
    text("(=)", x+W, 7*H);
}
