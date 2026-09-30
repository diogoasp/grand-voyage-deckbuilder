# Tarefa Atual

## Nome
Sistema de Metaprogressão, Mercado de Infâmia & Desbloqueio de Marcos de Cartas.

## Objetivo
Implementar o loop de metaprogressão roguelite:
- Conversão de Bounty em Pontos de Infâmia ao concluir a run (vitória sobre Morgan ou derrota);
- Loja do Mercado Notório: troca de Pontos de Infâmia para desbloquear Tripulantes (`chef_tora`) e Akuma no Mi (`goro_goro_no_mi`);
- Desbloqueio passivo de cartas por Marcos de Notoriedade (`tactical_feint` e `axe_breaker`);
- Tela de Registros & Desbloqueios acessível pelo Menu Principal.

## Critérios de aceite
1. Autoload `MetaProgression` salva e carrega dados persistentes (`infamy_points`, itens desbloqueados e marcos).
2. Fim de combate (derrota) e vitória de setor convertem Bounty em Infâmia com persistência.
3. Tela de Registros & Desbloqueios permite comprar tripulantes e frutas se houver saldo suficiente.
4. Marcos de Notoriedade liberam novas cartas para a pool de draft pós-combate quando preenchidos.
5. Filtro dinâmico de eventos no `DataLoader` respeita os tripulantes e frutas desbloqueados.
6. Validação completa sem erros de parser/script no Godot headless.




