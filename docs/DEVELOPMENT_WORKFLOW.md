# Fluxo de Desenvolvimento Local

## Objetivo
Usar um modelo local, como Qwen, para executar tarefas repetitivas e bem delimitadas, reduzindo intervenção manual.

O modelo local deve ser tratado como executor técnico, não como responsável autônomo por arquitetura ou escopo.

## Ciclo recomendado

```text
1. Ler AGENTS.md
2. Ler docs/CURRENT_STATE.md
3. Ler docs/CURRENT_TASK.md
4. Inspecionar os arquivos envolvidos
5. Implementar somente a tarefa atual
6. Rodar validações
7. Inspecionar git diff
8. Corrigir falhas da tarefa
9. Entregar resumo
10. Fazer validação manual no Godot
```

## Prompt padrão para Qwen

```text
Leia AGENTS.md, docs/CURRENT_STATE.md e docs/CURRENT_TASK.md.

Implemente apenas a tarefa definida em CURRENT_TASK.md.

Antes de editar:
- identifique os arquivos envolvidos;
- confirme que a implementação existente é compatível com o plano.

Durante:
- preserve a arquitetura;
- faça alterações mínimas;
- não faça refactors fora do escopo;
- não faça commit.

Depois:
- rode as validações disponíveis;
- execute git diff;
- informe arquivos alterados;
- informe testes executados;
- informe qualquer ponto que ainda exija validação manual.

Se encontrar uma decisão arquitetural não coberta pela tarefa, não improvise. Pare e descreva a decisão necessária.
```

## Uso ocasional do Codex
Priorizar para:
- revisão arquitetural;
- auditoria do estado atual;
- análise de dívida técnica;
- criação de planos precisos;
- revisão de diffs maiores;
- investigação de bugs difíceis.

Evitar gastar Codex em:
- criação mecânica de JSON;
- renomeações simples;
- refactors repetitivos;
- implementação trivial já bem especificada;
- tarefas que o Qwen pode validar localmente.

## Validação Godot
Quando possível, tentar localizar o executável do Godot e executar validação headless compatível com o ambiente.

Exemplos:

```bash
godot --headless --path . --editor --quit
```

ou:

```bash
godot4 --headless --path . --editor --quit
```

Não assumir que o binário existe. Se não estiver disponível, apenas relatar.

## Git
Antes da tarefa:

```bash
git status
```

Depois da tarefa:

```bash
git status
git diff
```

Não fazer commit automaticamente.

## Atualização de contexto
Quando uma tarefa alterar arquitetura ou adicionar sistema relevante, atualizar `docs/CURRENT_STATE.md`.

Não atualizar o documento para mudanças cosméticas pequenas.

## Quando parar
O agente deve parar e pedir decisão quando:
- a tarefa exige alterar arquitetura além do especificado;
- existem duas implementações incompatíveis sem critério definido;
- uma migração pode quebrar saves/dados existentes;
- o comportamento esperado não pode ser inferido dos arquivos e da tarefa;
- a solução exigiria remover funcionalidade existente.
