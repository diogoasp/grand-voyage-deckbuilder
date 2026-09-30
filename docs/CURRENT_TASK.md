# Tarefa Atual
 
## Nome
Reposicionamento e Estilização do HUD de Combate (Jogador no Topo Esquerdo com Barra de HP Dinâmica, Botão de Configurações no Topo Direito, Energia e Deck à Esquerda, Descarte e Botão de Turno à Direita).

## Objetivo
Implementar o novo layout e ergonomia da tela de combate:
- **Barra Superior Integrada (`TopBar`):**
  - **Nome e HP do Jogador no Canto Superior Esquerdo:**
    - `PlayerHUD` alinhado à esquerda no topo com nome dourado e estilizado.
    - Barra de HP dinâmica (`ProgressBar` com visual estilizado em tons verdes e fundo escuro) exibindo `HP: atual/máx` em texto centralizado contrastante.
    - Badge de bloqueio (`🛡`) ao lado da barra de vida.
  - **Informações Centrais:** Indicadores de Ouro e Bounty da run.
  - **Canto Superior Direito:** Botão de Configurações (`⚙`) integrado à barra superior, conectado para abrir o painel de opções e pausa da expedição.
- **Energia Atual à Esquerda das Cartas:**
  - `EnergyContainer` com visual destacado de orbe/cristal (`⚡`), exibindo claramente o valor atual/máximo (`X/Y`).
- **Deck (Draw Pile) Abaixo da Energia:**
  - `DeckContainer` posicionado logo abaixo da energia e visualmente menor (`🎴 Deck: X`).
- **Pilha de Descarte à Direita:**
  - `DiscardContainer` posicionado acima do botão de "Finalizar turno" (`🗑 Descarte: X`).
- **Área Central da Mão (`HandArea`):**
  - Posicionada confortavelmente entre a coluna esquerda e direita sem sobreposição.
- **Preservação de Lógica:**
  - Todas as referências de drop target, arraste de cartas e atualização de estado continuam 100% funcionais.

## Critérios de aceite
1. Nome do jogador e barra de vida alinhados à esquerda na barra superior.
2. Botão de configurações (`⚙`) integrado no canto direito da barra superior.
3. Barra de vida dinâmica atualizada em tempo real conforme dano e cura.
4. Elemento visual de energia posicionado à esquerda das cartas.
5. Deck posicionado abaixo da energia e em formato menor.
6. Pilha de descarte localizada à direita acima do botão de finalizar turno.
7. Validação do Godot headless sem erros de script/parser.




