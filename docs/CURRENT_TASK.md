# Tarefa Atual

## Nome
Polimento audiovisual e feedback de combate (Juice, SFX, transições e animação básica de acerto).

## Objetivo
Elevar a sensação de impacto ("game feel / juice") do combate e da navegação náutica após a consolidação do Vertical Slice:
- efeitos visuais ao causar/receber dano (shake leve na câmera ou flash de dano no alvo);
- feedback numérico de dano/bloqueio flutuante (floating combat text);
- transições visuais suaves entre as telas da run (Fade In / Fade Out);
- integração de áudio básico (efeitos sonoros para jogar carta, golpe e clique).

## Escopo
Implementar:
- feedback visual de impacto no `Combatant` ou `CombatScene` (flash ao levar dano);
- tela de vitória polida e transição limpa entre telas;
- sons de ação se houver arquivos de áudio disponíveis ou estrutura pronta para áudio.

Não implementar:
- sistemas pesados de shader complexo 3D;
- trilhas orquestradas completas sem assets definidos.

## Critérios de aceite
1. O combate transmite sensação clara de impacto nos golpes.
2. Transições suaves entre Mapa, Eventos, Cidades e Combate.
3. Sem erros ou warnings no depurador do Godot.



