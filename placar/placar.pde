///opt/processing-3.5.3/processing-java --sketch=/data/frescogo/placar/placar --run
// - EXE: mock/auto/timeout=false/false/5000, fullscreen

// - testar em outras máquinas
// - cores vm,am,az porporcional ata/tot
// - configurar lado do radar e do pivo da trinca
// - mostrar todos os parametros na configuracao: quedas/aborta
// - pontuacao media

import processing.serial.*;
import processing.sound.*;

int         MAJOR    = 3;
int         MINOR    = 1;
int         REVISION = 1;
String      VERSAO   = MAJOR + "." + MINOR + "." + REVISION;

JSONObject  CONF;
int         NOW;

Serial      RADAR;
boolean     RADAR_MOCK = false;
boolean     RADAR_AUTO = true;
int         RADAR_AUTO_TIMEOUT = 99999; //3500;
int         RADAR_AUTO_INICIO;
PrintWriter RADAR_OUT;
int         RADAR_REPS = 10;
int         RADAR_IGUAL = 700;

SoundFile[] SNDS = new SoundFile[6];
SoundFile[] HITS = new SoundFile[4];

int         CONF_TEMPO;
int         CONF_DISTANCIA;
int         CONF_ATAQUES;
int         CONF_MINIMA;
int         CONF_MAXIMA;
boolean     CONF_TRINCA;
int         CONF_QUEDAS;
int         CONF_ABORTA;

int         CONF_RECORDE;
String[]    CONF_NOMES = new String[3];
String      CONF_PARS;

PImage      IMG1, IMG2;
PImage      IMG_SPEED;
PImage      IMG_RAQUETE;
PImage      IMG_BAND;
PImage      IMG_APITO;
PImage      IMG_TROFEU;
PImage      IMG_DESCANSO;

int         GOLPE_DELAY = 1500; //99999; //1500;

String      ESTADO = "ocioso";         // ocioso, digitando, jogando, terminado
int         ESTADO_DIGITANDO = 255;    // 0=esq, 1=dir, 2=arbitro
String      ESTADO_JOGANDO;            // sacando, jogando

boolean     INV = false;
int         ZER = 0;
int         ONE = 1;

int         JOGO_DESCANSO_TOTAL, JOGO_DESCANSO_INICIO;
int         JOGO_TOTAL, JOGO_QUEDAS, JOGO_QUEDAS_MANUAL;
int         JOGO_TEMPO_INICIO, JOGO_TEMPO_PASSADO, JOGO_TEMPO_RESTANTE, JOGO_TEMPO_RESTANTE_OLD;
int[][]     JOGO_JOGS = new int[2][3];

float       dy; // 0.001 height
float       dx; // 0.001 width
float       W;
float       H;

ArrayList<ArrayList> JOGO = new ArrayList<ArrayList>();

String ns (String str, int n) {
    int len = str.length();
    for (int i=0; i<n-len; i++) {
        str += " ";
    }
    return str;
}

///////////////////////////////////////////////////////////////////////////////

int conf_ataques (int jog) {
    if (CONF_TRINCA) {
        if (jog == 0) {
            return 0;
        } else {
            return max(1, CONF_TEMPO * CONF_ATAQUES / 60);
        }
    } else {
        return max(1, CONF_TEMPO * CONF_ATAQUES / 60 / 2);
    }
}

int conf_quedas () {
    return CONF_QUEDAS * 60 / CONF_TEMPO;   // 8% / 60s
}

int conf_aborta () {
    return CONF_TEMPO / CONF_ABORTA;         // 1 queda / 15s
}

boolean conf_radar () {
    return (RADAR!=null || RADAR_MOCK);
}

///////////////////////////////////////////////////////////////////////////////

void go_reinicio () {
    ESTADO = "ocioso";
    JOGO = new ArrayList<ArrayList>();
    JOGO_DESCANSO_TOTAL     = 0;
    JOGO_TEMPO_RESTANTE_OLD = CONF_TEMPO;
    JOGO_QUEDAS             = 0;
    JOGO_QUEDAS_MANUAL      = 0;
    JOGO_TEMPO_INICIO       = millis();
    SNDS[1].play();
}

void go_saque () {
    ESTADO = "jogando";
    ESTADO_JOGANDO = "sacando";
    JOGO_DESCANSO_INICIO = millis();
    JOGO.add(new ArrayList<int[]>());
    SNDS[5].play();
    if (RADAR != null) {
        RADAR.clear();
    }
}

void go_queda () {
    ESTADO = "ocioso";
    JOGO_QUEDAS++;
    if (jogo_quedas() >= conf_aborta()) {
        delay(1000);
        go_termino();
    } else {
        SNDS[0].play();
        if (RADAR_AUTO) {
            delay(1000);
            go_saque();
        }
    }
}

void go_termino () {
    ESTADO = "terminado";
    SNDS[3].play();
    if (JOGO_TOTAL > CONF_RECORDE) {
        CONF_RECORDE = JOGO_TOTAL;
    }

    draw();

    String ts = "" + year() + "-" + nf(month(),2) + "-" + nf(day(),2) + "_"
                   + nf(hour(),2) + "_" + nf(minute(),2) + "_" + nf(second(),2);
    saveFrame("relatorios/frescogo-"+ts+"-"+CONF_NOMES[0]+"-"+CONF_NOMES[1]+"-placar.png");

    String manual = "";
    if (JOGO_QUEDAS_MANUAL != 0) {
        String plus = (JOGO_QUEDAS_MANUAL > 0 ? "+" : "");
        manual = " (" + JOGO_QUEDAS + plus + JOGO_QUEDAS_MANUAL + ")";
    }

    String[] jogs = new String[2];
    for (int i=0; i<2; i++) {
        jogs[i] = ns(CONF_NOMES[i]+":",15) + JOGO_JOGS[i][0] + " pontos = " +
                  min(conf_ataques(i),JOGO_JOGS[i][1]) + " atas X " +
                  nf(JOGO_JOGS[i][2]/100,2) + "." + nf(JOGO_JOGS[i][2]%100,2) + " km/h" + "\n";
    }

    String out = ns("Data:",     15) + ts + "\n"
               + ns("Versão:",   15) + CONF_PARS + "\n"
               //+ ns("Atletas:", 15) + CONF_NOMES[0] + " e " + CONF_NOMES[1] + "\n"
               + "\n" + jogs[0] + jogs[1] + "\n"
               + ns("Descanso:", 15) + (JOGO_DESCANSO_TOTAL/1000) + "\n"
               + ns("Quedas:",   15) + jogo_quedas() + manual + "\n"
               + ns("Total:",    15) + JOGO_TOTAL + " pontos\n"
               + "\n";
    for (int i=0; i<JOGO.size(); i++) {
        ArrayList<int[]> seq = JOGO.get(i);
        out += "SEQUÊNCIA " + nf(i+1,2) + "\n============\n\nTEMPO   DIR   KMH\n-----   ---   ---\n";
        for (int j=0; j<seq.size(); j++) {
            int[] golpe = seq.get(j);
            int ms = golpe[0] - JOGO_TEMPO_INICIO;
            out += nf(ms,6) + "   " + (golpe[1]==0 ? "->" : "<-") + "   " + nf(jogo_kmh(seq,j),3) + "\n";
        }
        out += "\n\n";
    }
    String[] outs = { out };
    String name = "relatorios/frescogo-"+ts+"-"+CONF_NOMES[0]+"-"+CONF_NOMES[1]+".txt";
    saveStrings(name, outs);
}

///////////////////////////////////////////////////////////////////////////////

void _jogo_tempo () {
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
    JOGO_TEMPO_PASSADO = ret / 1000 / 5 * 5;
    JOGO_TEMPO_RESTANTE = max(0, CONF_TEMPO-JOGO_TEMPO_PASSADO);
}

void _jogo_lado (int jog) {
    IntList kmhs = new IntList();
    for (int i=0; i<JOGO.size(); i++) {
        ArrayList<int[]> seq = JOGO.get(i);
        for (int j=0; j<seq.size()-1; j++) {    // -1: ignora ultimo golpe
            int[] golpe = seq.get(j);
            if (golpe[1] == jog) {
                int kmh = jogo_kmh(seq,j);
                if (kmh >= CONF_MINIMA) {
                    kmhs.append(jogo_kmh(seq,j));
                }
            }
        }
    }
    kmhs.sortReverse();
    int N = min(conf_ataques(jog),kmhs.size());
    int sum = 0;
    for (int i=0; i<N; i++) {
        sum += kmhs.get(i);
    }
    JOGO_JOGS[jog][0] = sum;
    JOGO_JOGS[jog][1] = kmhs.size();
    JOGO_JOGS[jog][2] = sum * 100 / max(1,N);
}

int jogo_kmh (ArrayList<int[]> seq, int i) {
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

int jogo_quedas () {
    return JOGO_QUEDAS + JOGO_QUEDAS_MANUAL;
}

void jogo_calc () {
    _jogo_tempo();
    _jogo_lado(0);
    _jogo_lado(1);

    int p0  = JOGO_JOGS[0][0];
    int p1  = JOGO_JOGS[1][0];
    int pts = p0 + p1;
    int pct = jogo_quedas() * conf_quedas();

    JOGO_TOTAL = pts * (10000-pct) / 10000;
}

///////////////////////////////////////////////////////////////////////////////

int old = millis();
int radar_mock () {
    int dt  = NOW - old;
    if (dt > 500) {
        old = NOW;
        if (random(0,4) <= 2) {
            int vel = int(random(30,CONF_MAXIMA));
            return (int(random(0,2))==0) ? vel : -vel;
        }
    }
    return 0;
}

int     BUF_I = 0;
int[][] BUF   = { {0,0},{0,0},{0,0},{0,0},{0,0},    // RADAR_REPS_MAX = 10
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
int _NOW = 2;

/*
75 km/h = 20.8 m/s
20.8 m - 1000 ms
15.0 m -  721 ms
700ms sem repeticao é seguro
*/
int[] LAST = { 0,0,0 }; // vel, dir, ms

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

// -1: erro ou duvida
// =0: nada detectado
// >0: velocidade se distanciando
// <0: velocidade se aproximando

int radar_radar () {
    // aproximadamente 40/50 reads/sec (20/25 ms/read)
    while (true) {
        int n = RADAR.read();
        if (n == 0x83) {
            break;              // espera o primeiro byte do pacote
        }
    }
    while (true) {
        delay(0);               // sem isso, o programa trava
        int n = RADAR.available();
        if (n >= _SIZE) {
            break;              // espera ter o tamanho do pacote
        }
    }

    byte[] s = RADAR.readBytes(_SIZE);
    if (!radar_check(s)) {
        return -1;              // erro no pacote
    }

    RADAR_OUT.println(char(s[_peak_dir]) + "=" + nf(four(s,_peak_val),3) + " | " +
                      char(s[_live_dir]) + "=" + nf(four(s,_live_val),3));
    RADAR_OUT.flush();

    byte dir = s[_live_dir];
    int  vel = four(s,_live_val);

    BUF[BUF_I][_VEL] = vel;
    BUF[BUF_I][_DIR] = dir;
    BUF_I = (BUF_I + 1) % RADAR_REPS;

    // aceito somente 10 picos de velocidades iguais e na mesma direcao
    for (int i=1; i<RADAR_REPS; i++) {
        vel = max(vel, BUF[i][_VEL]);
        if (BUF[i][_DIR] != BUF[0][_DIR]) {
            return -1;      // falhou na direcao
        }
    }

    // duvida se mesma vel/dir em menos de 700ms
    int now = millis();
    if (dir==LAST[_DIR] && now-RADAR_IGUAL<LAST[_NOW]) {
        return -1;
    }

    if (vel!=0 || LAST[_VEL]!=0) {
        String msg = "[" + (millis()/100) + "] " + char(dir) + " / " + vel;
        RADAR_OUT.println(msg);
        RADAR_OUT.flush();
        println(msg);
    }
    LAST[_VEL] = vel;
    LAST[_DIR] = dir;
    LAST[_NOW] = now;
    vel = (vel + 5) / 10;  // round
    return (dir == 'A') ? vel : -vel;
}

int radar () {
    if (RADAR_MOCK) {
        return radar_mock();
    } else {
        return radar_radar();
    }
}

///////////////////////////////////////////////////////////////////////////////

void exit () {
    if (RADAR_OUT != null) {
        RADAR_OUT.close();
    }
    super.exit();
}

void setup () {
    surface.setTitle("FrescoGO! " + VERSAO);
    //size(600, 300);
    size(1300, 900);
    //fullScreen();

    dy = 0.001 * height;
    dx = 0.001 * width;

    W = width  / 11.0;
    H = height /  8.0;

    CONF           = loadJSONObject("data/conf.json");
    CONF_TEMPO     = CONF.getInt("tempo");
    CONF_DISTANCIA = CONF.getInt("distancia");
    CONF_ATAQUES   = CONF.getInt("ataques");
    CONF_MINIMA    = CONF.getInt("minima");
    CONF_MAXIMA    = CONF.getInt("maxima");
    CONF_TRINCA    = CONF.getBoolean("trinca");
    CONF_QUEDAS    = CONF.getInt("quedas");
    CONF_ABORTA    = CONF.getInt("aborta");

    CONF_RECORDE   = CONF.getInt("recorde");
    CONF_NOMES[0]  = CONF.getString("atleta1");
    CONF_NOMES[1]  = CONF.getString("atleta2");
    CONF_NOMES[2]  = CONF.getString("arbitro");
    CONF_PARS      = "v" + VERSAO + " / " +
                     (CONF_TRINCA ? "trinca" : "dupla") + " / " +
                     (conf_radar() ? "radar" : CONF_DISTANCIA + "cm") + " / " +
                     CONF_TEMPO   + "s / " +
                     CONF_ATAQUES + "ata / " +
                     CONF_MINIMA  + (conf_radar() ? "" : "-" + CONF_MAXIMA) + "kmh";

    SNDS[0] = new SoundFile(this,"fall.wav");
    SNDS[1] = new SoundFile(this,"restart.wav");
    SNDS[2] = new SoundFile(this,"30s.wav");
    SNDS[3] = new SoundFile(this,"finish.wav");
    SNDS[4] = new SoundFile(this,"undo.wav");
    SNDS[5] = new SoundFile(this,"start.wav");
    //SNDS[6] = new SoundFile(this,"behind.wav");

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
        //RADAR = new Serial(this, "/dev/ttyUSB0", 9600);
        String[] list = Serial.list();
        RADAR = new Serial(this, list[list.length-1], 9600);
        RADAR_OUT = createWriter("radar.txt");
    } catch (RuntimeException e) {
        println("Erro na comunicação com o radar...");
        //exit();
    }

    go_reinicio();
}

void sound (int kmh) {
    if (kmh > 0) {
        HITS[1].play();
    } else {
        HITS[0].play();
    }
}

void _sound_ (int kmh) {
    int kmh_ = abs(kmh);
    if (kmh_ < 50) {
        HITS[0].play();
    } else if (kmh_ < 65) {
        HITS[1].play();
    } else if (kmh_ < 80) {
        HITS[2].play();
    } else {
        HITS[3].play();
    }
}

///////////////////////////////////////////////////////////////////////////////
// KEYBOARD
///////////////////////////////////////////////////////////////////////////////

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

    if (e.isControlDown()) {
        if (keyCode == 'Q') {                   // CTRL-Q
            key = ESC;
        } else if (keyCode == 'A') {            // CTRL-A
            RADAR_AUTO = !RADAR_AUTO;
            RADAR_AUTO_INICIO = millis();
        } else if (keyCode == '-') {
            JOGO_QUEDAS_MANUAL--;
        } else if (keyCode == '=') {
            JOGO_QUEDAS_MANUAL++;
        } else if (keyCode == 'R') {            // CTRL-R
            go_reinicio();
        } else if (keyCode == 'S') {            // CTRL-S
            go_termino();
        } else if (keyCode == 'I') {            // CTRL-I
            INV = !INV;
            ZER = 1 - ZER;
            ONE = 1 - ONE;
        }
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

            } else if (keyCode == 38) {         // CTRL-UP
                go_saque();
            } else if (keyCode == 8) {          // CTRL-BACKSPACE
                if (JOGO.size() > 0) {
                    JOGO.remove(JOGO.size()-1);
                    SNDS[4].play();
                }
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
    } else if (ESTADO.equals("jogando")) {
//println(keyCode);
        if (e.isControlDown() && keyCode==40) { // CTRL-DOWN
            go_queda();
        } else if (keyCode==37 || keyCode==39) { // CTRL-LEFT/RIGHT
            if (ESTADO_JOGANDO.equals("sacando")) {
                ESTADO_JOGANDO = "jogando";
                JOGO_DESCANSO_TOTAL += max(0, NOW-JOGO_DESCANSO_INICIO-5000);
            }
            int jog = (keyCode == 37) ? ZER : ONE;
            int[] golpe = { NOW, jog, 0 };
            ArrayList<int[]> seq = JOGO.get(JOGO.size()-1);
            seq.add(golpe);
            int kmh = 0;
            if (seq.size() >= 2) {
                kmh = jogo_kmh(seq, seq.size()-2);
            }
            sound(kmh);
        }
    }
    jogo_calc();
}

///////////////////////////////////////////////////////////////////////////////
// DRAW
///////////////////////////////////////////////////////////////////////////////

void draw () {
    NOW = millis();

    if (ESTADO.equals("jogando")) {
        if (conf_radar()) {
            int kmh = radar();
            int kmh_ = abs(kmh);
            if (kmh_ > 1) {
                if (ESTADO_JOGANDO.equals("sacando")) {
                    ESTADO_JOGANDO = "jogando";
                    JOGO_DESCANSO_TOTAL += max(0, NOW-JOGO_DESCANSO_INICIO-5000);
                }
                int[] golpe = { NOW, (kmh>0 ? 0 : 1), kmh_ };
                ArrayList<int[]> seq = JOGO.get(JOGO.size()-1);
                seq.add(golpe);
                sound(kmh);
            }
            if (RADAR_AUTO && kmh!=0) {
                // zera o timeout com qq bola que não seja 0
                RADAR_AUTO_INICIO = NOW;
            }
        }
        if (ESTADO_JOGANDO.equals("jogando") &&
            RADAR_AUTO && NOW>=RADAR_AUTO_INICIO+RADAR_AUTO_TIMEOUT) {
            go_queda();
        }
        if (JOGO_TEMPO_RESTANTE_OLD>30 && JOGO_TEMPO_RESTANTE<=30) {
            SNDS[2].play();
        }
        JOGO_TEMPO_RESTANTE_OLD = JOGO_TEMPO_RESTANTE;
        if (JOGO_TEMPO_RESTANTE <= 0) {
            go_termino();
        }
    }

    jogo_calc();
    draw_draw();
}

void draw_draw () {
    background(255,255,255);

    draw_logo(0*W, IMG1);
    draw_logo(7*W, IMG2);

    draw_nome(0*W, ZER, ESTADO_DIGITANDO==ZER);
    draw_nome(7*W, ONE, ESTADO_DIGITANDO==ONE);

    // TEMPO
    {
        String mins = nf(JOGO_TEMPO_RESTANTE / 60, 2);
        String segs = nf(JOGO_TEMPO_RESTANTE % 60, 2);

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

        int descanso = JOGO_DESCANSO_TOTAL;
        if (ESTADO.equals("jogando") && ESTADO_JOGANDO.equals("sacando")) {
            descanso += max(0, NOW-JOGO_DESCANSO_INICIO-5000);
        }
        descanso /= 1000;

        if (ESTADO.equals("terminado")) {
            fill(255);
        } else {
            fill(150,150,150);
        }
        textSize(25*dy);
        textAlign(CENTER, CENTER);
        text(descanso+" s", width/2, 2.50*H);
        float w = textWidth(descanso+" s");
        image(IMG_DESCANSO, width/2-w-15*dx, 2.50*H);
    }

    // PARS / INVERTIDO?
    if (ESTADO.equals("terminado")) {
        fill(255);
    } else {
        fill(150,150,150);
    }
    textSize(12*dy);
    textAlign(CENTER, TOP);
    text("("+CONF_PARS+")", width/2, 0);
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
        text(jogo_quedas(), width/2, height/2-15*dy);
    }

    if (ESTADO.equals("jogando")) {
        ArrayList<int[]> seq = JOGO.get(JOGO.size()-1);
        int jog = 255;
        for (int i=1; i<=2; i++) {
            if (seq.size() < i) {
                continue;
            }

            int[] golpe = seq.get(seq.size()-i); // millis/jog/kmh
            if (golpe[1] == jog) {
                // mesmo jogador deu os ultimos dois golpes
            } else {
                jog = golpe[1];
                if (NOW <= golpe[0]+GOLPE_DELAY) {
                    int kmh = golpe[2];
                    if (kmh == 0) {
                        int xxx = seq.size() - i - 1;
                        if (xxx >= 0) {
                            kmh = jogo_kmh(seq, seq.size()-i-1);
                            if (jog == ONE) {
                                draw_ultima(1.5*W, kmh);
                            } else {
                                draw_ultima(9.5*W, kmh);
                            }
                        }
                    } else {
                        if (jog == ZER) {
                            draw_ultima(1.5*W, kmh);
                        } else {
                            draw_ultima(9.5*W, kmh);
                        }
                    }
                }
                if (NOW <= golpe[0]+500) {
                    stroke(color(0,0,255));
                    strokeWeight(10*dy);
                    if (jog == ZER) {
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

    draw_lado(1.5*W, ZER);
    draw_lado(7.5*W, ONE);

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

        // auto
        if (RADAR_AUTO) {
            fill(0, 150, 0);
            ellipseMode(CENTER);
            ellipse(6.5*W, 5.2*H, 20*dy, 20*dy);
        }

        // recorde
        if (JOGO_TOTAL >= CONF_RECORDE) {
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
        text(JOGO_TOTAL, width/2, 7*H);
    }
}

void draw_logo (float x, PImage img) {
    noStroke();
    fill(255);
    rect(x, 0, 4*W, 2*H);
    image(img, x+2*W, H);
}

void draw_nome (float x, int jog, boolean digitando) {
    String nome = CONF_NOMES[jog];
    stroke(0);
    fill(255);
    rect(x, 2*H, 4*W, H);
    //image(IMG1, x+1.5*W, 1*H);
    if (digitando) {
        nome = nome + "_";
        fill(255, 0, 0);
    } else {
        noStroke();
        fill(0);
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

void draw_lado (float x, int jog) {
    int[] JOG = JOGO_JOGS[jog];
    noStroke();
    fill(color(255,255,255));
    rect(x, 5*H, 2*W, 3*H);
    fill(0);
    textAlign(CENTER, CENTER);

    textSize(15*dy);
    text("." + nf(JOG[2]%100,2), x+W+30*dx, 6.5*H+15*dy);   // media1

    textSize(50*dy);
    text(JOG[2]/100, x+W, 6.5*H);         // media1
    text(JOG[0], x+W, 7.5*H);             // pontos

    int atas = conf_ataques(jog);
    if (atas>0 && JOG[1]>=atas) {         // golpes vs limite
        fill(255,0,0);
    }
    text(JOG[1], x+W, 5.5*H);             // golpes
    fill(150,150,150);
    textSize(20*dy);
    float w1 = textWidth(str(JOG[1]));    // golpes
    textAlign(TOP, LEFT);
    text("/"+conf_ataques(jog), x+W+w1+10*dx, 5.5*H+30*dy);  // limite

    textSize(15*dy);
    textAlign(CENTER, CENTER);
    text("(x)", x+W, 6*H);
    text("(=)", x+W, 7*H);
}
