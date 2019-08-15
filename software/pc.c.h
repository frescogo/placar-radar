enum {
    PC_RESTART = 0,
    PC_HIT     = 1,
    PC_TICK    = 2,
    PC_FALL    = 3,
    PC_END     = 4
};

void PC_Restart (void) {
    Serial.print(PC_RESTART);         // pos 0. codigo de reinicio
    Serial.print(F(";"));
    Serial.print(F("0")); // Para mostrar tempo em min:seg
    Serial.print(S.timeout/1000/60);     // pos 1. tempo total de jogo
    Serial.print(F(";"));
    Serial.print(F("00")); // Para mostrar tempo em min:seg
    Serial.print(F(";"));    
    Serial.print(S.names[0]);         // pos 2. atleta a esquerda
    Serial.print(F(";"));
    Serial.print(S.names[1]);         // pos 3. atleta a direita
    Serial.println(F(";"));
}

void PC_Player (int I) {
    Serial.print(G.ps[I]/100);        // pontuacao
    Serial.print(F(";"));
    Serial.print(PT_Behind() == I ? 1 : 0);   // 1=atras | 0=ok
    int n, min_, max_;
    n = PT_Bests(G.bests[I][0], &min_, &max_);
    //Serial.print(F(";"));
    //Serial.print(n);                  // total de revezes
    //Serial.print(F(";"));
    //Serial.print(max_);               // maxima de revez
    //Serial.print(F(";"));
    //n = PT_Bests(G.bests[I][1], &min_, &max_);
    //Serial.print(n);                  // total normais
    //Serial.print(F(";"));
    //Serial.print(max_);               // maxima normal
    Serial.println(F(";"));
}

void PC_Hit (int player, int is_back, int kmh) {
    Serial.print(PC_HIT);             // // pos 0. codigo de golpe
    Serial.print(F(";"));
    Serial.print(player);             //  pos 2. 0=esquerda | 1=direita
    Serial.print(F(";"));
    Serial.print(is_back);            //  pos 3. 0=normal   | 1=revés
    Serial.print(F(";"));
    Serial.print(kmh);                //  pos 4. velocidade
    Serial.print(F(";"));
    PC_Player(player);
}

void PC_Tick (void) {
    float tempo_restante = (S.timeout/1000)-(G.time/1000);
    float fracao_segundo_restante = ((tempo_restante/60)-(int(tempo_restante/60)));
    float tempo_jogo = G.time/1000;
    float fracao_segundo_jogo = ((tempo_jogo/60)-(int(tempo_jogo/60))); 

    Serial.print(PC_TICK);            //  pos 0. codigo de tick
    Serial.print(F(";"));
    
    // ======= MOSTRAR TEMPO DECORRIDO ========
     if (G.time > S.timeout) {
        Serial.print(F("00")); // preenche minutos
        Serial.print(F(";"));
        Serial.print(F("00")); // preenche segundos
        Serial.print(F(";"));
    }
    else if (((S.timeout-G.time)/1000) > 59) { //condição 1
        Serial.print(int((S.timeout/1000)-(G.time/1000))/60);  // preenche minutos
        Serial.print(F(";"));       
        if ((int(((S.timeout/1000)-(G.time/1000))/60)*60) == S.timeout/1000) { //condição 2
            Serial.print(F("00")); // preenche segundos
            Serial.print(F(";"));
        }        
        else if ((fracao_segundo_restante*60)-(int(fracao_segundo_restante*60)) >= 0,5) { //condição 3
            Serial.print(int(fracao_segundo_restante*60)+1);
            Serial.print(F(";"));
        } 
        else {
            Serial.print(int(fracao_segundo_restante*60)); // preenche segundos //condição 4
            Serial.print(F(";"));
        }
    } else {
        Serial.print((S.timeout/1000)-(G.time/1000)); // preenche segundos //condição 5
        Serial.print(F(";"));
    }

// ========================

    Serial.print(G.total);            //  pos 2. total da dupla
    Serial.println(F(";"));
}

void PC_Fall (void) {
    Serial.print(PC_FALL);            //  pos 0. codigo de queda
    Serial.print(F(";"));
    Serial.print(Falls());          //  pos 1. total de quedas
    Serial.println(F(";"));
}

void PC_End (void) {
    Serial.print(PC_END);             //  pos 0. codigo de fim
    Serial.println(F(";"));
}

void PC_Nop (void) {
}
