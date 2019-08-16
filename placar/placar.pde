String PORTA = "/dev/ttyUSB0";

import processing.serial.*;
Serial porta;
String codigo;
String vel_esq;
String vel_dir;
String pos_vel;
String pts_esq;
String pts_total;
String pts_dir;
int coord_x;
int tamanho; // Numero de dígitos de um valor lido na serial
int coordenada_inicial; 
int largura_quadro;
int largura_letra;
PImage img; // Função para trabalhar com imagens

int TEMPO_TOTAL;
int TEMPO_JOGADO;

void draw_logos () {
  image(img,    0, 0);
  image(img, 1000, 0);
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
  fill(255);
  rect(525, 110, 230, 250);

  textAlign(CENTER, TOP);

  fill(0);
  textSize(25);
  text("QUEDAS", width/2, 110);
  
  fill(37, 21, 183);
  textSize(90);
  text(quedas, width/2, 110+25); 
}

void draw_golpes (int golpes) {
  fill(255);
  rect(525, 235, 229, 125);
  
  textAlign(CENTER, TOP);

  fill(0);
  textSize(25);
  text("GOLPES", width/2, 235);
  
  fill(37, 21, 183);
  textSize(90);
  text(golpes, width/2, 235+25);     
}
  
void draw_nome (int x, String nome) {
  fill(255);
  rect(x, 110, 525, 55);
  fill(255, 0, 0);
  textSize(55);
  textAlign(CENTER, CENTER);
  text(nome, x+525/2, 110+55/2-5);
}

void setup () {
  porta = new Serial(this, PORTA, 9600);
  porta.bufferUntil('\n');
 
  surface.setTitle("FrescoGO! V.1.11");
  size(1280, 720);
  img = loadImage("fresco.png");
  textFont(createFont("Arial Black", 18));

  draw_logos();
  draw_tempo(0);
  draw_quedas(0);
  draw_golpes(0);
  draw_nome(  0, "?");
  draw_nome(754, "?");
  
  // Pontuação Jogador da Esquerda
  fill(255);
  rect(0, 165, 525, 195);
  fill(0);  // Preenche com a cor branca
  textSize(140);
  text("0", 216, 315); // Zerando a pontuação inicial
  
  // Pontuação Jogador da Direita  
  fill(255);
  rect(754, 165, 525, 195);
  fill(0);
  textSize(140);
  text("0", 970, 315);  // Zerando a pontuação inicial 
  
  // Velocidade máxima jogador à esquerda
  fill(255);
  rect(0, 360, 262, 120);
  fill(0);
  textSize(30);
  text("Máxima", 75, 395);
  
  // Última velocidade jogador à esquerda
  fill(255);
  rect(262, 360, 263, 120);
  fill(0);
  textSize(30);
  text("Última", 340, 395);
  textSize(75);
  text("", 340, 463);  
  
  // Velocidade média da dupla
  fill(255);
  rect(525, 360, 230, 120);
  fill(0);
  textSize(30);
  text("Média", 595, 395);
  
  // Última velocidade jogador à direita
  fill(255);
  rect(754, 360, 262, 120);
  fill(0);
  textSize(30);
  text("Última", 834, 395);
  textSize(75);
  text("", 834, 463);  
  
  // Velocidade máxima jogador à direita  
  fill(255);
  rect(1016, 360, 263, 120);
  fill(0);
  textSize(30);
  text("Máxima", 1096, 395);

  // Pontuação total
  fill(0); // Preenche com a cor preta
  rect(0, 480, 1280, 240);  // Desenha o retângulo
  fill(255);
  textSize(200);      
  text("0", 575, 670); // Mostra valor


// Fim do código que veio do painel
}

//=========================== INICIA VOID DRAW =====================================
void draw(){
  if (porta.available()>0){  
    String linha = porta.readStringUntil('\n'); // Ler a String recebida
    print(linha);
    String[] posicao = split (linha, ";");
    codigo = posicao[0];    
//=========================== INICIA SWITCH CASE ===================================
switch (codigo){

case "0": 
    TEMPO_TOTAL = int(posicao[1]);
    String esq = posicao[2];
    String dir = posicao[3];

    draw_tempo(TEMPO_TOTAL);
    draw_nome(  0, esq);
    draw_nome(754, dir);
    break;

case "1":
    pos_vel = posicao[1];
    vel_esq = posicao[3];
    vel_dir = posicao[3];
    pts_esq = posicao[4];
    pts_dir = posicao[4];    
          switch (pos_vel){
          case "0":
          fill(255);
          stroke(0);          
          rect(754, 360, 262, 120); // última velocidade da direita
          fill(0);
          textSize(30);
          text("Última", 834, 395);
          
          // Circulo indicando de quem foi o velocidade medida
          fill(15, 56, 164);
          stroke(15, 56, 164);
          ellipse(789, 435, 35, 35); 
          
          // Apaga sinalização do outro jogador
          fill(255); 
          stroke(255);
          ellipse(492, 435, 38, 38);           
          
          fill(0);
          textSize(80);
          text(vel_dir, 834, 463);
          
          // ============== Pontuação do jogador da ESQUERDA ==============          
          text("0", 216, 315);
          fill(255);
          stroke(0);
          rect(0, 165, 525, 195);
          fill(0);  // Preenche com a cor branca
          textSize(140);
          tamanho = pts_esq.length(); // Número de caracteres no nome da esquerda
          coordenada_inicial = 0; // Coordenada inicial do nome da esquerda
          largura_quadro = 525; // Largura do retângulo do nome da esquerda
          largura_letra = 90; // Espaçamento da fonte do nome
          coord_x = int((coordenada_inicial +(largura_quadro / 2)-(tamanho * (largura_letra / 2))));
          fill(0);  // Seta a cor do texto
          text(pts_esq, coord_x, 315); // Mostra valor
          break;
    
          case "1":
          fill(255);
          stroke(0);              
          rect(262, 360, 263, 120);
          fill(0);
          textSize(30);
          text("Última", 340, 395);
          
          // Circulo indicando de quem foi o velocidade medida          
          fill(15, 56, 164);
          stroke(15, 56, 164);
          ellipse(492, 435, 35, 35);
          
          // Apaga sinalização do outro jogador
          fill(255); 
          stroke(255);
          ellipse(789, 435, 38, 38); 
          
          fill(0);
          textSize(75);
          text(vel_esq, 340, 463); 
          
          // ============== Pontuação do jogador da DIREITA ==============          
          text("0", 970, 315);
          fill(255);
          stroke(0);
          rect(754, 165, 525, 195);
          fill(0);  // Preenche com a cor branca
          textSize(140);
          tamanho = pts_dir.length(); // Número de caracteres no nome da esquerda
          coordenada_inicial = 754; // Coordenada inicial do nome da esquerda
          largura_quadro = 525; // Largura do retângulo do nome da esquerda
          largura_letra = 90; // Espaçamento da fonte do nome
          coord_x = int((coordenada_inicial +(largura_quadro / 2)-(tamanho * (largura_letra / 2))));
          fill(0);  // Seta a cor do texto
          text(pts_dir, coord_x, 315); // Mostra valor           
          break;
          }

case "2": 

    TEMPO_JOGADO = int(posicao[1]);
    pts_total = posicao[2];

    draw_tempo(TEMPO_TOTAL-TEMPO_JOGADO);
    
    textAlign(LEFT, BOTTOM);
    textSize(100);
    text("0", 575, 670); // Mostra valor
    fill(0); // Preenche com a cor preta
    rect(0, 480, 1280, 240);  // Desenha o retângulo
    fill(255);
    textSize(200);      
    tamanho = pts_total.length(); // Número de caracteres no nome da esquerda
    println(pts_total + " " + tamanho);
    coordenada_inicial = 0; // Coordenada inicial do nome da esquerda
    largura_quadro = 1280; // Largura do retângulo do nome da esquerda
    largura_letra = 130; // Espaçamento da fonte do nome
    coord_x = int((coordenada_inicial +(largura_quadro / 2)-(tamanho * (largura_letra / 2))));
    fill(255);  // Seta a cor do texto
    text(pts_total, coord_x, 670); // Mostra valor        
    break;

case "3": // Queda de bola, zerar o placar
    int quedas = int(posicao[1]);
    draw_quedas(quedas);
    
    //Apaga ultimas velocidade esquerda
          fill(255);
          stroke(0);              
          rect(262, 360, 263, 120);
          fill(0);
          textSize(30);
          text("Última", 340, 395);
    //Apaga ultimas velocidade direita       
          fill(255);
          stroke(0);          
          rect(754, 360, 262, 120);
          fill(0);
          textSize(30);
          text("Última", 834, 395);
    break;

case "4": 
/*println("Case 4");
println(posicao[0]);
print("Vazio: ");
println(posicao[1]);
print("Vazio: ");
println(posicao[2]);
print("Vazio: ");
println(posicao[3]);*/
break;
}
    
    
    
    

    }

}
