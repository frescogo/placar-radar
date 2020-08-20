///opt/processing-3.5.3/processing-java --sketch=/data/frescogo/placar/placar --run

// - RADAR

import processing.serial.*;
import processing.sound.*;
import java.io.*;

JSONObject  CONF;
boolean     MOCK = false;
Serial      RADAR;
PrintWriter RADAR_OUT;

SoundFile[] SNDS = new SoundFile[7];
SoundFile[] HITS = new SoundFile[4];

int      CONF_TEMPO;
int      CONF_DISTANCIA;
int      CONF_ATAQUES;
int      CONF_MINIMA;
int      CONF_MAXIMA;
boolean  CONF_EQUILIBRIO;
int      CONF_RECORDE;
String[] CONF_NOMES = new String[3];
String   CONF_PARS;

PImage   IMG1;
PImage   IMG2;
PImage   IMG_SPEED;
PImage   IMG_RAQUETE;
PImage   IMG_BAND;
PImage   IMG_APITO;
PImage   IMG_TROFEU;
PImage   IMG_DESCANSO;

int      MAJOR    = 3;
int      MINOR    = 1;
int      REVISION = 0;
String   VERSAO   = MAJOR + "." + MINOR + "." + REVISION;

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

int conf_ataques () {
    return max(1, CONF_TEMPO * CONF_ATAQUES / 60 / 2);
}

int conf_quedas () {
    return 800 * 60 / CONF_TEMPO;   // 8% / 60s
}

int conf_abort () {
    return CONF_TEMPO / 15;         // 1 queda / 15s
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
    if (ESTADO.equals("jogando")) {
        return JOGO.size() - 1;
    } else {
        return JOGO.size();
    }
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
            return min(CONF_MAXIMA, 36 * CONF_DISTANCIA / (nxt[0] - cur[0]));
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
                if (kmh >= CONF_MINIMA) {
                    kmhs.append(KMH(seq,j));
                }
            }
        }
    }
    kmhs.sortReverse();
    int N = min(conf_ataques(),kmhs.size());
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

void exit () {
    RADAR_OUT.close();
    super.exit();
}

void setup () {
    surface.setTitle("FrescoGO! " + VERSAO);
    //size(600, 300);
    size(1024, 768);
    //fullScreen();

    dy = 0.001 * height;
    dx = 0.001 * width;

    W = width  / 11.0;
    H = height /  8.0;

    CONF = loadJSONObject("conf.json");
    CONF_TEMPO      = CONF.getInt("tempo");
    CONF_DISTANCIA  = CONF.getInt("distancia");
    CONF_ATAQUES    = CONF.getInt("ataques");
    CONF_MINIMA     = CONF.getInt("minima");
    CONF_MAXIMA     = CONF.getInt("maxima");
    CONF_EQUILIBRIO = CONF.getBoolean("equilibrio");
    CONF_RECORDE    = CONF.getInt("recorde");
    CONF_NOMES[0]   = CONF.getString("atleta1");
    CONF_NOMES[1]   = CONF.getString("atleta2");
    CONF_NOMES[2]   = CONF.getString("arbitro");
    CONF_PARS       = "(v" + VERSAO + " / " +
                        CONF_TEMPO     + "s / " +
                        CONF_DISTANCIA + "cm / " +
                        CONF_ATAQUES   + "ata / " +
                        CONF_MINIMA    + "-" +
                        CONF_MAXIMA    + "kmh / " +
                        "equ=" + (CONF_EQUILIBRIO ? "s" : "n") +
                      ")";

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
        RADAR = new Serial(this, Serial.list()[0], 9600);
    } catch (RuntimeException e) {
        println("Erro na comunicação com o radar...");
        //exit();
    }

    try {
        RADAR_OUT = new PrintWriter(new BufferedWriter(new FileWriter("radar.txt",true)));
        RADAR_OUT.println("=== RADAR ===");
    } catch (IOException e) {
        println("Erro ao criar 'radar.txt'.");
        exit();
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

int old = millis();
int radar_mock () {
    int now = millis();
    int dt  = now - old;
    if (dt > 500) {
        old = now;
        if (random(0,5) <= 2) {
            int vel = int(random(30,100));
            return (int(random(0,2))==0) ? vel : -vel;
        }
    }
    return 0;
}

boolean BREAK = true;
int     BUF_I = 0;
int[][] BUF   = { {0,0},{0,0},{0,0},{0,0},{0,0},
                  {0,0},{0,0},{0,0},{0,0},{0,0} };

int _SIZE     = 18;
int _peak_dir = 0;
int _peak_val = 1;
int _live_dir = 5;
int _live_val = 6;
int _size     = 10;
int _ratio    = 13;
int _status   = 16;
int _cr       = 17;

int _VEL = 0;
int _DIR = 1;

int REP_10 = 10;

int four (byte[] s, int idx) {
    return
        (s[idx+0] - '0') * 1000 +
        (s[idx+1] - '0') *  100 +
        (s[idx+2] - '0') *   10 +
        (s[idx+3] - '0') *    1;
}

boolean check_num (byte c) {
    return (c>='0' && c<='9');
}

boolean radar_check (byte[] s) {
    return
        (s[_peak_dir]=='A' || s[_peak_dir]=='C') &&
        check_num(s[_peak_val+0]) &&
        check_num(s[_peak_val+1]) &&
        check_num(s[_peak_val+2]) &&
        check_num(s[_peak_val+3]) &&
        (s[_live_dir]=='A' || s[_live_dir]=='C') &&
        check_num(s[_live_val+0]) &&
        check_num(s[_live_val+1]) &&
        check_num(s[_live_val+2]) &&
        check_num(s[_live_val+3]) &&
        check_num(s[_size+0]) &&
        check_num(s[_size+1]) &&
        check_num(s[_size+2]) &&
        check_num(s[_ratio+0]) &&
        check_num(s[_ratio+1]) &&
        check_num(s[_ratio+2]) &&
        s[_status] == 0x40 &&
        s[_cr] == '\r';
}

int radar_radar () {
    // aproximadamente 40/50 reads/sec (20/25 ms/read)
    while (true) {
        int n = RADAR.read();
        if (n == 0x83) {
            break;              // espera o primeiro byte do pacote
        }
    }
    while (true) {
        int n = RADAR.available();
        if (n >= _SIZE) {
            break;              // espera ter o tamanho do pacote
        }
    }

    byte[] s = RADAR.readBytes(18);
    if (!radar_check(s)) {
        return 0;               // erro no pacote
    }

    String out = "A=";
    for (int i=0; i<s.length-1; i++) {
        out += char(s[i]);
    }
    RADAR_OUT.println(s[_peak_dir] + "=" + four(s,_peak_val) + " | " +
                      s[_live_dir] + "=" + four(s,_live_val) + " | ");

    byte dir = s[_peak_dir];
    int  vel = four(s,_peak_val);

    BUF[BUF_I][_VEL] = vel;
    BUF[BUF_I][_DIR] = dir;
    BUF_I = (BUF_I + 1) % REP_10;

    // aceito somente 10 picos de velocidades iguais e na mesma direcao
    for (int i=1; i<REP_10; i++) {
        if (BUF[i][_VEL]!=BUF[0][_VEL] || BUF[i][_DIR]!=BUF[0][_DIR]) {
            BREAK = true;   // quebra nos ultimos 10, passo a aceitar o proximo
            return 0;       // falhou na velocidade ou direcao
        }
    }

    if (BREAK) {
        BREAK = false;  // nao aceito um novo, espero uma quebra nos ultimos 10
        RADAR_OUT.println(">>> " + vel);
        return (dir == 'A') ? vel : -vel;
    } else {
        return 0;
    }
}

int radar () {
    if (MOCK) {
        return radar_mock();
    } else {
        return radar_radar();
    }
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
        if (e.isControlDown() && keyCode==40) { // CTRL-DOWN
            ESTADO = "ocioso";
            if (quedas() >= conf_abort()) {
                ESTADO = "terminando";
                //JOGO.add(new ArrayList<int[]>());
            }
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
// DRAW
///////////////////////////////////////////////////////////////////////////////

void draw () {
    int[] jog0  = jogador(ZER);
    int[] jog1  = jogador(ONE);
    int[] total = TOTAL(jog0,jog1);
    int now = millis();

    if (ESTADO.equals("jogando")) {
        if (MOCK || RADAR!=null) {
            int kmh = radar();
            int kmh_ = abs(kmh);
            if (kmh != 0) {
                if (ESTADO_JOGANDO.equals("sacando")) {
                    ESTADO_JOGANDO = "jogando";
                    TEMPO_DESCANSO += max(0, now-TEMPO_DESCANSO_INICIO-5000);
                }
                int[] golpe = { now, (kmh>0 ? 0 : 1), kmh_ };
                ArrayList<int[]> seq = JOGO.get(JOGO.size()-1);
                seq.add(golpe);
                sound(kmh_);
            }
        }
    } else if (ESTADO.equals("terminando")) {
        ESTADO = "terminado";
        SNDS[3].play();
        if (total[0] > CONF_RECORDE) {
            CONF_RECORDE = total[0];
        }
        String ts = "" + year() + "-" + nf(month(),2) + "-" + nf(day(),2) + "_"
                       + nf(hour(),2) + ":" + nf(minute(),2) + ":" + nf(second(),2);
        draw();
        saveFrame("relatorios/frescogo-"+ts+"-"+CONF_NOMES[0]+"-"+CONF_NOMES[1]+"-placar.png");

        String out = ns("Data:",    15) + ts + "\n"
                   //+ ns("Atletas:", 15) + CONF_NOMES[0] + " e " + CONF_NOMES[1] + "\n"
                   + "\n"
                   + ns(CONF_NOMES[0]+":",15) +
                     jog0[0] + " pontos = " +
                     min(conf_ataques(),jog0[1]) + " atas X " +
                     nf(jog0[2]/100,2) + "." + nf(jog0[2]%100,2) + " km/h" + "\n"
                   + ns(CONF_NOMES[1]+":",15) +
                     jog1[0] + " pontos = " +
                     min(conf_ataques(),jog1[1]) + " atas X " +
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

    draw_nome(0*W, ZER, (CONF_EQUILIBRIO && t>=30 && total[1]==ZER), ESTADO_DIGITANDO==ZER);
    draw_nome(7*W, ONE, (CONF_EQUILIBRIO && t>=30 && total[1]==ONE), ESTADO_DIGITANDO==ONE);

    // TEMPO
    {
        int tempo_restante = max(0, CONF_TEMPO-t);
        if (OLD_TEMPO_RESTANTE>30 && tempo_restante<=30) {
            SNDS[2].play();
        }
        OLD_TEMPO_RESTANTE = tempo_restante;
        if (tempo_restante<=0 && ESTADO=="jogando") {
            ESTADO = "terminando";
        }
        String mins = nf(tempo_restante / 60, 2);
        String segs = nf(tempo_restante % 60, 2);

        if (ESTADO.equals("terminado")) {
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
            descanso += max(0, now-TEMPO_DESCANSO_INICIO-5000);
        }
        descanso /= 1000;

        fill(150,150,150);
        textSize(25*dy);
        textAlign(CENTER, CENTER);
        text(descanso+" s", width/2, 2.50*H);
        float w = textWidth(descanso+" s");
        image(IMG_DESCANSO, width/2-w-15*dx, 2.50*H);
    }

    // PARS
    fill(150,150,150);
    textSize(15*dy);
    textAlign(CENTER, TOP);
    text(CONF_PARS, width/2, 0);

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

    if (ESTADO.equals("jogando")) {
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
                if (now <= golpe[0]+1000) {
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
                if (now <= golpe[0]+500) {
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
    if (kmh >= CONF_MINIMA) {
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

    if (jog[1] >= conf_ataques()) {        // golpes vs limite
        fill(255,0,0);
    }
    text(jog[1], x+W, 5.5*H);             // golpes
    fill(150,150,150);
    textSize(20*dy);
    float w1 = textWidth(str(jog[1]));    // golpes
    textAlign(TOP, LEFT);
    text("/"+conf_ataques(), x+W+w1+10*dx, 5.5*H+30*dy);  // limite

    textSize(15*dy);
    textAlign(CENTER, CENTER);
    text("(x)", x+W, 6*H);
    text("(=)", x+W, 7*H);
}
