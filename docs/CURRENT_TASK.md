# Tarefa Atual

## Nome
Redesign Visual das Cartas em Combate (Proporções, Cristal de Custo, Área de Arte e Descrição Formatada).

## Objetivo
Implementar a nova estrutura visual das cartas no combate:
- **Novas Dimensões e Proporção:** Aumento do tamanho das cartas de `120x180` para `150x215` (slot: `154x220`), garantindo legibilidade e presença visual de card game de qualidade.
- **Cristal de Energia (Custo):** Indicador circular/cristalino no canto superior esquerdo com brilho azul celeste (`#66ccff`) e valor numérico contrastante.
- **Cabeçalho:** Nome da carta alinhado ao topo ao lado do cristal com corte limpo de texto.
- **Espaço Dedicado para Arte:** Moldura central (altura 72px) pronta para receber texturas (`art_path` em `cards.json`), contendo fallback com ícone representativo por tipo (`⚔` Ataque, `🛡` Habilidade, `⚡` Poder).
- **Badge de Tipo e Bordas por Raridade:**
  - Borda e contorno da carta reativos à raridade (`Comum`, `Incomum`, `Rara`, `Lendária`).
  - Badge indicando o arquétipo (`• ATAQUE •`, `• HABILIDADE •`, `• PODER •`).
- **Caixa de Descrição (RichText):** Área inferior destacada com texto claro, auto-quebra de linha e suporte a bbcode.
- **Ajustes de Layout na Cena de Combate:** `HandArea`, painel de fundo da mão e botão de "Finalizar turno" reposicionados para acomodar o novo formato sem sobreposição.

## Critérios de aceite
1. `CardView.tscn` reflete a nova hierarquia (Cristal de Custo + Nome + Moldura de Arte + Badge de Tipo + Descrição).
2. `card_view.gd` aplica o setup com dimensões `150x215` e coloração de borda por raridade.
3. Arrastar e soltar cartas funciona normalmente com as novas proporções e detecção de alvo.
4. Botões de recompensa de vitória exibem formato harmonizado com o cristal e tamanho ampliado.
5. Validação do Godot headless sem erros de parser/script.




