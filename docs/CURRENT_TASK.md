# Tarefa Atual

## Nome
Estilos de Combate Iniciais, Profissões do Capitão e Seleção de Personagem.

## Objetivo
Implementar o sistema de customização, arquétipos iniciais e progressão de maestria da expedição:
- **Estilos de Combate (`data/combat_styles/combat_styles.json`)**:
  - `swordsman` (Espadachim), `brawler` (Lutador), `sniper` (Atirador Estrategista).
  - Níveis de Maestria (1 a 4) com desbloqueio permanente de novas cartas de combate (Incomum, Rara e Lendária) com base na Infâmia acumulada no estilo.
- **Profissões do Capitão (`data/professions/professions.json`)**:
  - `combatant` (Combatente), `navigator` (Navegador), `doctor` (Médico).
  - Evolução dinâmica de Raridade da Profissão (`Comum` ➔ `Incomum` 300 pts ➔ `Raro` 900 pts ➔ `Lendário` 2.000 pts de Infâmia na profissão).
  - Escalabilidade da passiva do Médico e do arsenal de cartas iniciais conforme a raridade alcançada.
- **Metaprogressão e Notificação de Fim de Run (`MetaProgression` & `run_scene.gd`)**:
  - Ao fim de cada run (derrota ou vitória), a Infâmia é creditada globalmente e individualmente para o Estilo e a Profissão jogados.
- **Telas de Apresentação e Registros**:
  - `CharacterSelectScene`: Exibe nível de maestria, raridade atual e progresso de Infâmia para o próximo tier nos botões e no painel de resumo.
  - `RecordsScene`: Nova aba **"Maestria & Carreiras"** detalhando o progresso histórico de cada profissão e estilo de combate.

## Critérios de aceite
1. `DataLoader` carrega estilos, níveis de maestria e profissões a partir de JSONs.
2. `CharacterSelectScene` conecta seleção com `GameState.setup_custom_run()` na maior raridade desbloqueada.
3. Passiva do Navegador controla visualização de rotas em `MapScene`.
4. Passiva do Médico cura o jogador na transição entre setores escalando com a raridade.
5. Fim de run credita Infâmia em `MetaProgression` para a profissão e estilo jogados, promovendo raridades e desbloqueando cartas.
6. Aba "Maestria & Carreiras" em `RecordsScene` reflete o status de evolução em tempo real.
7. Validação do Godot headless sem erros de parser/script.




