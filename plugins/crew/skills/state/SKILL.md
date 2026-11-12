---
name: state
description: Procedimento do crew para gravar o estado de uma task em disco ($CREW_WORKTREES/<task>/.crew/) com o comando crew-state, lido pelo dashboard e pelo /crew:status. Use em todos os comandos do crew, do plano ao PR.
user-invocable: false
allowed-tools: Bash(crew-state *)
---
# Estado da task

Cada task guarda o próprio andamento em `$CREW_WORKTREES/<task>/.crew/`, onde `<task>` é a mesma pasta definida no skill crew:worktrees (`<id ou slug>`). O dashboard (`bin/dashboard`) e o `/crew:status` leem dali.

- **Único escritor:** só a sessão principal grava o estado, e o `task.json` só muda pelo comando `crew-state` (vem no plugin e está no PATH). Nunca escreva nem edite o `task.json` com Write ou Edit. Subagents nunca escrevem em `.crew/`.
- **Quando:** logo depois do planner (`init`) e a cada passo do comando. Grave **antes** de PARAR para me perguntar (`wait`), e de novo quando eu responder (`resume`).
- **Artefatos** (Markdown) você escreve com a ferramenta Write em `.crew/<caminho>` e depois registra com `crew-state <task> artifact`.
- **Nunca grave** segredos, conteúdo de `.env`, tokens, nem exemplos de dado pessoal (nome, e-mail, CPF etc. de pessoas reais) em nenhum arquivo de `.crew/`. Nos achados, descreva o problema sem copiar o dado.
- Se um `crew-state` falhar, leia o erro e corrija a chamada; não contorne escrevendo o JSON à mão.

## Comandos

`<task>` é o nome da pasta da task (ID ou slug). Rode `crew-state --help` se precisar.

| Momento | Comando |
| --- | --- |
| Planner terminou | `crew-state <task> init <feature\|bugfix\|refactor\|ui> "<título>" [--id <ID>] [--slug <slug>] --workspace <workspace>` |
| Risco do plano | `crew-state <task> set risk <baixo\|medio\|alto>` (o planner classifica; use o que ele disser) |
| Repos afetados, worktrees | `crew-state <task> repo <nome> [--kind front\|back\|front+back] [--branch B] [--base B] [--worktree DIR]` (pode repetir; completa o que faltar) |
| Mudança de etapa | `crew-state <task> stage <etapa> "<nota curta>"` (limpa `waiting`) |
| PARAR para me perguntar | `crew-state <task> wait "<o que precisa de mim, uma linha>"` |
| Eu respondi | `crew-state <task> resume "<o que decidi, uma linha>"` |
| Resultado do tester | `crew-state <task> test <ciclo> <verde\|falhas> [nº de falhas]` |
| Veredito de um revisor | `crew-state <task> review <ciclo> <reviewer\|security> <ok\|sugestoes\|bloqueadores>` |
| Artefato escrito | `crew-state <task> artifact <caminho relativo a .crew/> "<rótulo>" [--cycle N]` |
| Caminho do próximo feedback | `crew-state <task> feedback-path` |
| PR aberto ou mudou de estado | `crew-state <task> pr <repo> <open\|merged\|closed> [--url URL] [--number N]` |
| Subagent terminou | `crew-state <task> usage <agente> <modelo> <tokens> [duração_ms]` |
| Qualquer outro marco | `crew-state <task> note "<texto>"` |
| Ler o estado | `crew-state <task> show` |

`sugestoes` = só sugestões ou notas. `stage`, `wait`, `resume`, `pr` e `note` já registram no histórico; o histórico serve para cada mudança de etapa, parada e resposta minha que mude o rumo.

## Uso de tokens

Depois de **cada** subagent, registre o uso com `usage`: o nome do agente (`planner`, `implementer`, `tester`, `reviewer`, `security-reviewer`, `ui-implementer`), o modelo do frontmatter dele (`fable`, `opus`, `sonnet`) e os números do bloco `<usage>` que volta no resultado do subagent (`subagent_tokens` e `duration_ms`). Um subagent por chamada; implementers em paralelo são várias chamadas. Se o resultado não trouxer o bloco, não registre.

## Minhas respostas

Quando eu responder a uma parada com mais do que um "sim" ou "não" (correção de rumo, informação nova, escolha com condições), guarde a resposta antes de seguir:

1. `crew-state <task> feedback-path` devolve o caminho do próximo `feedback-N.md`;
2. escreva nele, com Write, a pergunta que você fez (uma linha) e a minha resposta, sem resumir;
3. registre com `crew-state <task> artifact feedback-N.md "Sua resposta N"` e depois `resume`.

Repasse o conteúdo aos subagents seguintes junto do plano.

## Artefatos

Grave o texto que o subagent devolveu, sem resumir:

| Momento | Arquivo |
| --- | --- |
| Plano, diagnóstico ou plano de refactor do planner | `plano.md` |
| Brief visual (UI) | `brief-visual.md` |
| Crítica das variantes e a escolhida (UI) | `variantes.md` |
| Minha resposta numa parada | `feedback-<N>.md` |
| Resultado do tester, por ciclo | `testes/ciclo-<N>.md` (com `--cycle N`) |
| Baseline do refactor | `testes/baseline.md` |
| Review do reviewer e do security-reviewer, por ciclo | `revisao/ciclo-<N>/reviewer.md`, `revisao/ciclo-<N>/security.md` (com `--cycle N`) |
| Descrição de cada PR | `pr/<repo>.md` |

Os prints de UI não vão para o disco, nem aqui.

## Etapas

| Momento do comando | `stage` | `wait` |
| --- | --- | --- |
| Planner terminou e você vai me mostrar o plano | `plano` | "aprovar o plano" (se o comando mandar parar) |
| Eu recusei o plano ou desisti da task | `cancelada` | — |
| Preparando worktrees | `worktrees` | — |
| Variantes de UI: implementação, prints e escolha | `variantes` | "escolher a variante" ao me apresentar |
| Implementers rodando | `implementacao` | — |
| Tester rodando ou retomando o implementer por falhas | `testes` | — |
| Reviewer e security-reviewer, e correções de bloqueadores | `revisao` | — |
| Ciclos esgotados, possível incidente ou qualquer outra parada | a etapa atual | o motivo |
| PRs abertos | `pr` | — |
| Todos os PRs com merge (detectado pelo /crew:status) | `concluida` | — |

Registre os repos assim que souber quais são afetados (no plano), e complete `--branch`, `--base` e `--worktree` ao preparar as worktrees. Variantes de UI não entram em `repos`; só a worktree de trabalho do repo escolhido.

## task.json

Formato gerado pelo `crew-state`, para referência (o dashboard lê estes campos):

```json
{
  "version": 1,
  "id": "86a1b2c3",
  "slug": "exportar-relatorio-csv",
  "title": "Exportar relatório em CSV",
  "type": "feature",
  "workspace": "/caminho/absoluto/do/workspace",
  "stage": "revisao",
  "risk": "medio",
  "waiting": null,
  "created": "2026-11-05T10:12:00-03:00",
  "updated": "2026-11-05T11:40:00-03:00",
  "repos": [
    { "name": "api", "kind": "back", "branch": "feature/86a1b2c3-exportar-relatorio-csv", "base": "develop",
      "worktree": "/caminho/worktrees/86a1b2c3/api", "pr": { "state": "open", "url": "...", "number": 123 } }
  ],
  "tests": [{ "cycle": 1, "result": "falhas", "failures": 2 }],
  "reviews": [{ "cycle": 1, "reviewer": "bloqueadores", "security": "ok" }],
  "artifacts": [{ "label": "Plano", "path": "plano.md", "stage": "plano", "at": "..." }],
  "usage": [{ "agent": "planner", "model": "fable", "tokens": 180000, "duration_ms": 95000, "stage": "plano", "at": "..." }],
  "history": [{ "at": "...", "stage": "plano", "note": "task criada" }]
}
```

## Retomada

Se a pasta da task já tiver `.crew/task.json` quando um comando começar, rode `crew-state <task> show`, leia os artefatos, me diga em que etapa a task parou e pergunte se devo continuar dali.
