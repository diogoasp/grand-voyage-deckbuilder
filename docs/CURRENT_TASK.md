# Tarefa Atual
 
## Nome
Integração da Tripulante Sora (Meio-Mink Médica/Atiradora), Mecânica de Fraqueza (Weakness), Cartas Temáticas e Apresentação de Assistência em Combate.

## Objetivo
1. **Perfil da Sora (`crew.json`):**
   - Substituição de Dr. Lin por Sora: Médica e Atiradora, raça Meio-Mink, raridade Comum.
   - Personalidade: Ousada, inteligente e analítica.
   - Ativos de arte configurados: `face_path`, `base_path` e `combat_path`.
2. **Novas Cartas de Recrutamento (`cards.json`):**
   - `warning_shot` (*Tiro de Advertência*): Custo 2, causa 6 de dano e aplica 1 stack de Fraqueza (`weakness`).
   - `restorative_bullets` (*Balas Restauradoras*): Custo 1, restaura 4 HP do jogador.
3. **Mecânica de Fraqueza (`Combatant` e `EffectResolver`):**
   - Reduz em 25% o dano de ataques desferidos por quem possui o status (`outgoing damage * 0.75`).
   - Consome 1 stack a cada turno/rodada.
   - Suporte a badges visuais de status tanto no jogador quanto no inimigo.
4. **Evento de Recrutamento (`events.json` e `EventScene`):**
   - Atualizado o evento da médica para apresentar Sora e exibir sua ilustração (`base_path`).
5. **Apresentação de Assistência em Combate (`CombatScene`):**
   - Ao jogar uma carta associada a um membro recrutado da tripulação (como as da Sora), a ilustração de combate (`combat.png`) do aliado desliza suavemente ao lado do jogador, permanece durante a ação e sai da tela com fade/slide.

6. **Disponibilidade e Exclusividade de Profissão no Recrutamento (`DataLoader` e `GameState`):**
   - Eventos de recrutamento de tripulantes (`wandering_doctor`, `sea_chef_encounter`) expandidos para os setores `[0, 1, 2]` do South Blue.
   - Implementada regra de exclusividade de profissão: caso o bando já possua um membro daquela profissão (ou o próprio capitão seja daquela profissão), outros personagens com essa profissão deixam de ser sorteados.
   - Caso o jogador encontre e opte por não recrutar, o evento continua elegível para aparecer em ilhas/setores futuros pela geração procedural.

## Critérios de aceite
1. Dr. Lin substituído por Sora com dados de perfil, raridade comum e caminhos de arte.
2. Cartas `warning_shot` e `restorative_bullets` integradas e funcionando com efeitos de fraqueza e cura.
3. Fraqueza reduz o dano efetuado em 25% e decai a cada turno.
4. Apresentação visual de slide-in do aliado ao jogar cartas de tripulante associado.
5. Recrutamento disponível nos setores 0, 1 e 2, cessando de aparecer apenas quando a profissão já estiver presente na tripulação.
6. Validação com Godot headless limpa e sem erros.




