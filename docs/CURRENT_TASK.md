# Tarefa Atual

## Nome
Estilos de Combate Iniciais, Profissões do Capitão e Seleção de Personagem.

## Objetivo
Implementar o sistema de customização e arquétipos iniciais da expedição:
- **Estilos de Combate (`data/combat_styles/combat_styles.json`)**:
  - `swordsman` (Espadachim - Caminho da Lâmina): deck focado em corte, 72 HP, 10 ouro.
  - `brawler` (Lutador - Punhos de Aço): deck focado em impacto e defesa pesada, 80 HP, 5 ouro.
  - `sniper` (Atirador Estrategista - Olho de Rapina): deck focado em compra e rotação, 65 HP, 15 ouro.
- **Profissões do Capitão (`data/professions/professions.json`)**:
  - Raridade fixa do capitão como `"common"`.
  - `combatant` (Combatente): Sem passiva náutica, compensado por receber 5 cartas comuns sorteadas de combate.
  - `navigator` (Navegador): Passiva de revelar as rotas de todo o mapa náutico (sem navegador, rotas além do estágio atual ficam ocultas); concede 1 carta comum temática.
  - `doctor` (Médico): Passiva de cura automática entre ilhas (5 HP no grau comum); concede 1 carta comum medicinal.
- **Tela de Preparação da Expedição (`CharacterSelectScene`)**:
  - Permite escolher estilo e profissão com resumo em tempo real do baralho e atributos.
- **Persistência**:
  - Estilo, profissão e raridade salvos e carregados em `GameState` e exibidos no menu principal e no mapa.

## Critérios de aceite
1. `DataLoader` carrega estilos e profissões a partir de JSONs externos.
2. `CharacterSelectScene` conecta seleção com `GameState.setup_custom_run()`.
3. Passiva do Navegador controla visualização de rotas em `MapScene`.
4. Passiva do Médico cura o jogador na transição entre setores.
5. Baralho inicial é montado unindo cartas do estilo + cartas da profissão por raridade.
6. Validação do Godot headless sem erros de parser/script.




