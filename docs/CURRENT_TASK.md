# Tarefa Atual

## Nome
Tela Inicial (Menu Principal) & Base de Metaprogressão.

## Objetivo
Implementar a porta de entrada do jogo para orquestrar o início e continuação de campanhas, além de preparar o espaço para metaprogressão:
- Apresentar o título do jogo e opções de navegação:
  - Continuar Campanha (com resumo dos dados do save atual: setor, HP, ouro, comida, bounty, tamanho do deck, tripulantes e Akuma no Mi);
  - Nova Campanha (inicia expedição limpa do zero);
  - Diário de Bordo (bloqueado para versões futuras);
  - Registros & Conquistas (bloqueado para versões futuras);
  - Configurações (bloqueado para versões futuras);
  - Sair (fecha a aplicação via `get_tree().quit()`);
- Permitir salvar e retornar ao menu principal durante uma expedição em andamento pelo menu de opções (`⚙`).

## Critérios de aceite
1. Tela inicial carrega na inicialização do jogo.
2. Botão "Continuar Campanha" é habilitado apenas quando existe save válido, exibindo o resumo em painel formatado.
3. Botão "Nova Campanha" gera uma nova run limpa e transiciona para o mapa.
4. Botões bloqueados exibem feedback visual amigável temporário.
5. Botão "Sair" encerra a aplicação.
6. Menu de configurações in-game possui a opção de "Salvar e Voltar ao Menu".
7. Sem erros de script ou parser no Godot.




