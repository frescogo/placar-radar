import processing.serial.*;
Serial porta;
String codigo;
String jog_esq;
String jog_dir;
String min_tot;
String seg_tot;
String vel_esq;
String vel_dir;
String pos_vel;
String pts_esq;
String pts_total;
String pts_dir;
String quedas;
String tr_min;
String tr_seg;
int coord_x;
int tamanho; // Numero de dígitos de um valor lido na serial
int coordenada_inicial; 
int largura_quadro;
int largura_letra;
PImage img; // Função para trabalhar com imagens


void setup(){
 porta = new Serial(this, "COM12", 9600);
 porta.bufferUntil('\n');
 
// Código que veio do painel
  //---------------------------------------------------------------------------------------- 
    //Desenhando os placar
    surface.setTitle("FrescoGO! V.1.11"); // Título da janela
    size(1280, 720); // Desenha retângulo total do placar
    img = loadImage("fresco.png"); // Atribui imagem à variável "img"
    textFont(createFont("Arial Black", 18));  

    // Retângulo dos minutos
    fill(0);
    rect(280, 0, 340, 110); 
    fill(255);
    textSize(100);
    text("00", 485, 90); // Zerando minutos
    
    // Retângulo Dois Pontos
    fill(0);
    rect(620, 0, 40, 110); 
    fill(255);
    textSize(100);
    text(":", 623, 90); // Fixa os dois pontos

    // Retângulo dos segundos 
    fill(0);
    rect(660, 0, 340, 110);  
    fill(255);
    textSize(100);
    text("00", 660, 90); // Zerando segundos
    

    
  // fim testes
  //Logos
  image(img, 0, 0); // Logo esquerda
  image(img, 1000, 0); // Logo direita
  noFill();  // Comando para deixar transparentes os objetos abaixo dele
  rect(0, 0, 280, 110);  // Retângulo Logo Direita
  rect(999, 0, 280, 110);  // Retângulo Logo Direita

  // Nomes e Quedas
  // Jogador à esquerda
  fill(255);
  rect(0, 110, 525, 55);  // Retângulo Nome Jogador à Esquerda
  fill(255, 0, 0);
  textSize(55);
  text("?", 245, 159);
  
  // Quedas
  fill(255);
  rect(525, 110, 230, 250); // Retângulo Quedas
  fill(0);
  textSize(25);
  text("QUEDAS", 585, 139);
  fill(37, 21, 183);
  textSize(90);
  text("0", 612, 220); 

  // Quantidade de golpes
  fill(255);
  rect(525, 235, 229, 125); // Retângulo golpes
  fill(0);
  textSize(25);
  text("GOLPES", 585, 262);
  fill(37, 21, 183);
  textSize(90);
  text("0", 612, 345);     

  
  // Jogador à direita
  fill(255);
  rect(754, 110, 525, 55);  // Retângulo Nome Jogador à Direita
  fill(255, 0, 0);
  textSize(55);
  text("?", 895, 159);  
  // Jogadores

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
    String[] posicao = split (linha, ";");
    codigo = posicao[0];    
//=========================== INICIA SWITCH CASE ===================================
switch (codigo){

case "0": 
    min_tot = posicao[1]; // Define posição desse dado na serial
    seg_tot = posicao[2]; // Define posição desse dado na serial    
    jog_esq = posicao[3]; // Define posição desse dado na serial
    jog_dir = posicao[4]; // Define posição desse dado na serial

    //========== MOSTRA TEMPO DE DURAÇÃO DO JOGO ==========
    fill(0);
    rect(280, 0, 340, 110); 
    fill(255);
    textSize(100);
    text("", 485, 90); // Zerando minutos
    textSize(100);
    text(min_tot, 485, 90); // Zerando minutos
    //textSize(100);
    //text(seg_tot, 660, 90); // Zerando segundos
    
    //============= MOSTRA JOGADOR À ESQUERDA =============
    fill(255);
    rect(0, 110, 525, 55);  // Retângulo Nome Jogador à Esquerda
    textSize(55);
    tamanho = jog_esq.length(); // Número de caracteres no nome da esquerda
    coordenada_inicial = 0; // Coordenada inicial do nome da esquerda
    largura_quadro = 525; // Largura do retângulo do nome da esquerda
    largura_letra = 40; // Espaçamento da fonte do nome
    coord_x = int((coordenada_inicial +(largura_quadro / 2)-(tamanho * (largura_letra / 2))));
    fill(255, 0, 0);  // Seta a cor do texto
    text(jog_esq, coord_x, 159); // Mostra valor
    print(coord_x);
    
    //============= MOSTRA JOGADOR À DIREITA =============
    fill(255);
    rect(754, 110, 525, 55);  // Retângulo Nome Jogador à Esquerda
    textSize(55);    
    tamanho = jog_dir.length(); // Número de caracteres no nome da esquerda
    coordenada_inicial = 754; // Coordenada inicial do nome da esquerda
    largura_quadro = 525; // Largura do retângulo do nome da esquerda
    largura_letra = 40; // Espaçamento da fonte do nome
    coord_x = int((coordenada_inicial +(largura_quadro / 2)-(tamanho * (largura_letra / 2))));
    fill(255, 0, 0);  // Seta a cor do texto
    text(jog_dir, coord_x, 159); // Mostra valor
    print(coord_x);
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

    tr_min = posicao[1];
    tr_seg = posicao[2];
    pts_total = posicao[3];
    
//=========== CRONÔMETRO ===========    
    // ============== MOSTRA MINUTOS ==============          
    text(" ", 485, 90); // Zerando minutos
    fill(0);
    stroke(0);
    rect(280, 0, 340, 110);
    fill(255);  // Preenche com a cor branca
    textSize(100);
    tamanho = tr_min.length(); // Número de caracteres no nome da esquerda
    if (tamanho == 1){
    fill(255);  // Seta a cor do texto
    text("0"+ tr_min, 485, 90); // Mostra valorr
    }
    else if (tamanho == 2){
    fill(255);  // Seta a cor do texto
    text(tr_min, 485, 90); // Mostra valor      
    }
    
    // ============== MOSTRA SEGUNDOS ==============          
    text("00", 660, 90); // Zerando segundos
    fill(0);
    stroke(0);
    rect(660, 0, 340, 110);
    fill(255);  // Preenche com a cor branca
    textSize(100);
    tamanho = tr_seg.length(); // Número de caracteres no nome da esquerda
    if (tamanho == 1){
    fill(255);  // Seta a cor do texto
    text("0"+ tr_min, 660, 90); // Mostra valorr
    }
    else if (tamanho == 2){
    fill(255);  // Seta a cor do texto
    text(tr_seg, 660, 90); // Mostra valor      
    }

//=========== FIM CRONÔMETRO ===========       
    
    text("0", 575, 670); // Mostra valor
    fill(0); // Preenche com a cor preta
    rect(0, 480, 1280, 240);  // Desenha o retângulo
    fill(255);
    textSize(200);      
    tamanho = pts_total.length(); // Número de caracteres no nome da esquerda
    coordenada_inicial = 0; // Coordenada inicial do nome da esquerda
    largura_quadro = 1280; // Largura do retângulo do nome da esquerda
    largura_letra = 130; // Espaçamento da fonte do nome
    coord_x = int((coordenada_inicial +(largura_quadro / 2)-(tamanho * (largura_letra / 2))));
    fill(255);  // Seta a cor do texto
    text(pts_total, coord_x, 670); // Mostra valor        
    break;

case "3": // Queda de bola, zerar o placar
    quedas = posicao[1];
    
    // ============== QUEDAS DE BOLA ==============          
    textSize(90);
    text("", 612, 289); 
    fill(0); // Preenche com a cor preta
    fill(255);
    rect(525, 110, 229, 125); // Retângulo Quedas
    fill(0);
    textSize(25);
    text("QUEDAS", 585, 139);
    textSize(90);      
    tamanho = quedas.length(); // Número de caracteres no nome da esquerda
    coordenada_inicial = 0; // Coordenada inicial do nome da esquerda
    largura_quadro = 1280; // Largura do retângulo do nome da esquerda
    largura_letra = 60; // Espaçamento da fonte do nome
    coord_x = int((coordenada_inicial +(largura_quadro / 2)-(tamanho * (largura_letra / 2))));
    fill(37, 21, 183);  // Seta a cor do texto
    text(quedas, coord_x, 220); // Mostra valor 
    
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
