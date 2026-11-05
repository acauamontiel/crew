---
name: state
description: Procedimento do crew para gravar o estado de uma task em disco ($CREW_WORKTREES/<task>/.crew/), lido pelo dashboard e pelo /crew:status. Use em todos os comandos do crew, do plano ao PR.
user-invocable: false
---
# Estado da task

Cada task guarda o próprio andamento em `$CREW_WORKTREES/<task>/.crew/`, onde `<task>` é a mesma pasta definida no skill crew:worktrees (`<id ou slug>`). O dashboard (`bin/dashboard`) e o `/crew:status` leem dali.

- **Único escritor:** só a sessão principal grava o estado. Subagents nunca escrevem em `.crew/`; a sessão principal grava o que eles devolvem.
- **Quando:** logo depois do planner (crie a pasta) e a cada passo do comando. Grave **antes** de PARAR para me perguntar, e de novo quando eu responder.
- **Como:** reescreva o `task.json` inteiro com a ferramenta Write, como JSON válido. Pegue a hora com `date -Is`.
- **Nunca grave** segredos, conteúdo de `.env`, tokens, nem exemplos de dado pessoal (nome, e-mail, CPF etc. de pessoas reais) em nenhum arquivo de `.crew/`. Nos achados, descreva o problema sem copiar o dado.

## task.json

```json
{
  "version": 1,
  "id": "86a1b2c3",
  "slug": "exportar-relatorio-csv",
  "title": "Exportar relatório em CSV",
  "type": "feature",
  "workspace": "/caminho/absoluto/do/workspace",
  "stage": "revisao",
  "waiting": null,
  "created": "2026-11-05T10:12:00-03:00",
  "updated": "2026-11-05T11:40:00-03:00",
  "repos": [
    {
      "name": "api",
      "kind": "back",
      "branch": "feature/86a1b2c3-exportar-relatorio-csv",
      "base": "develop",
      "worktree": "/caminho/worktrees/86a1b2c3/api",
      "pr": null
    }
  ],
  "tests": [
    { "cycle": 1, "result": "falhas", "failures": 2 },
    { "cycle": 2, "result": "verde", "failures": 0 }
  ],
  "reviews": [
    { "cycle": 1, "reviewer": "bloqueadores", "security": "ok" }
  ],
  "artifacts": [
    { "label": "Plano", "path": "plano.md", "stage": "plano" },
    { "label": "Testes, ciclo 1", "path": "testes/ciclo-1.md", "stage": "testes", "cycle": 1 }
  ],
  "history": [
    { "at": "2026-11-05T10:12:00-03:00", "stage": "plano", "note": "plano gerado; aguardando aprovação" }
  ]
}
```

| Campo | Valores |
| --- | --- |
| `id` | ID da task ou `null` (nunca invente) |
| `type` | `feature`, `bugfix`, `refactor`, `ui` |
| `stage` | `plano`, `worktrees`, `variantes`, `implementacao`, `testes`, `revisao`, `pr`, `concluida`, `cancelada` |
| `waiting` | `null`, ou `{ "reason": "<o que precisa de mim, uma linha>", "since": "<hora>" }` enquanto você estiver PARADO esperando minha resposta |
| `repos[].kind` | `front`, `back`, `front+back` |
| `repos[].pr` | `null`, ou `{ "url": "...", "number": 123, "state": "open" }` (`open`, `merged`, `closed`) |
| `tests[].result` | `verde`, `falhas` |
| `reviews[].reviewer`, `reviews[].security` | `ok`, `sugestoes` (só sugestões ou notas), `bloqueadores`, `pendente` |

Acrescente uma entrada em `history` a cada mudança de etapa, a cada parada e a cada resposta minha que mude o rumo (aprovação, recusa, escolha de variante). Uma linha curta por entrada.

## Artefatos

Markdown dentro de `.crew/`, cada um registrado em `artifacts` (o dashboard só mostra o que estiver na lista). Grave o texto que o subagent devolveu, sem resumir:

| Momento | Arquivo |
| --- | --- |
| Plano, diagnóstico ou plano de refactor do planner | `plano.md` |
| Brief visual (UI) | `brief-visual.md` |
| Crítica das variantes e a escolhida (UI) | `variantes.md` |
| Resultado do tester, por ciclo | `testes/ciclo-<N>.md` |
| Baseline do refactor | `testes/baseline.md` |
| Review do reviewer e do security-reviewer, por ciclo | `revisao/ciclo-<N>/reviewer.md`, `revisao/ciclo-<N>/security.md` |
| Descrição de cada PR | `pr/<repo>.md` |

Os prints de UI não vão para o disco, nem aqui.

## Etapas

| Momento do comando | `stage` | `waiting` |
| --- | --- | --- |
| Planner terminou e você vai me mostrar o plano | `plano` | "aprovar o plano" (se o comando mandar parar) |
| Eu recusei o plano ou desisti da task | `cancelada` | `null` |
| Preparando worktrees | `worktrees` | `null` |
| Variantes de UI: implementação, prints e escolha | `variantes` | "escolher a variante" ao me apresentar |
| Implementers rodando | `implementacao` | `null` |
| Tester rodando ou retomando o implementer por falhas | `testes` | `null` |
| Reviewer e security-reviewer, e correções de bloqueadores | `revisao` | `null` |
| Ciclos esgotados, possível incidente ou qualquer outra parada | a etapa atual | o motivo |
| PRs abertos | `pr` | `null` |
| Todos os PRs com merge (detectado pelo /crew:status) | `concluida` | `null` |

Preencha `repos` assim que souber os repositórios afetados (no plano), e complete `branch`, `base` e `worktree` ao preparar as worktrees. Variantes de UI não entram em `repos`; só a worktree de trabalho do repo escolhido.

## Retomada

Se a pasta da task já tiver `.crew/task.json` quando um comando começar, leia o arquivo e os artefatos, me diga em que etapa a task parou e pergunte se devo continuar dali.
