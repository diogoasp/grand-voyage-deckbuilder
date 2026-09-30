# Tarefa Atual
 
## Nome
Exibição da Tripulação na Barra Superior em Combate (Representação de Relíquias Estilo Slay the Spire com Ícone, Borda por Raridade e Tooltip Detalhado).

## Objetivo
Implementar a exibição da tripulação atual do navio integrada à barra superior entre a vida do jogador e os contadores de recursos:
- **Posicionamento no TopBar (`CrewContainer`):**
  - Posicionado entre o `PlayerHUD` (Vida do jogador) e o `Separator` de Ouro/Bounty.
- **Identidade Visual por Membro:**
  - Miniatura estilizada (30x30) com cantos arredondados e fundo escuro.
  - Borda colorida de acordo com a raridade do tripulante (`Comum`, `Incomum`, `Raro`, `Lendário`).
  - Face do personagem em retrato (`face_path`), com fallback para ícone temático de profissão (`💉` Médico, `🍖` Cozinheiro, `🧭` Navegador, `⚔` Combatente, etc.).
- **Inspeção / Tooltip ao Sobrepor:**
  - Exibe o nome do tripulante, profissão, raridade e descrição da habilidade passiva.
  - Para combatente, exibe especificamente *"Adiciona 5 cartas ao baralho"*.

## Critérios de aceite
1. `CrewContainer` posicionado entre a vida e o ouro no `TopBar`.
2. Borda reativa à raridade do tripulante.
3. Hover exibe nome, profissão, raridade e habilidade passiva do membro da tripulação.
4. Combatente exibe *"Adiciona 5 cartas ao baralho"*.
5. Validação Godot headless sem erros.




