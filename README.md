# crew

Pipeline interativo de subagents do Claude Code para **feature**, **bugfix**, **refactor** e **UI**, pensado para trabalho que atravessa vários repositórios ao mesmo tempo, com gates humanos em cada etapa importante.

Este repositório é um marketplace de plugins do Claude Code com um plugin, `crew`:

- **Agentes:** `planner`, `implementer`, `tester`, `reviewer`, `security-reviewer`, `ui-implementer`
- **Comandos:** `/crew:feature`, `/crew:bugfix`, `/crew:refactor`, `/crew:ui`, `/crew:status`
- **Skills internos:** `crew:worktrees` (perfil do workspace, repositórios, branch base e worktrees) e `crew:state` (estado da task em disco), usados pelos comandos
- **Dashboard:** painel local das tasks, servido por `bin/dashboard`
- **MCP:** Playwright via Docker, para os screenshots de UI

O plugin é genérico. O que é próprio de um time ou projeto (de onde vem o ID da task, formato de commit, como rodar, riscos de segurança do domínio) fica num **perfil do workspace**, fora do plugin. Veja [Perfil do workspace](#perfil-do-workspace).

## Como funciona

Você abre o Claude Code num **workspace**: uma pasta com vários repositórios (ex.: `~/code/acme`, com `api/`, `web/`, `admin/`…) ou um repositório sozinho.

1. O **planner** lê o perfil do workspace, mapeia os repositórios e devolve a tabela dos que o ticket toca: tipo (front-end ou back-end, detectado pelo `package.json` e pelos arquivos de tela), branch base, como rodar, o que muda e se há mudança de UI.
2. Depois da sua aprovação, a sessão cria **uma worktree por repositório afetado** em `$CREW_WORKTREES/<task>/<repo>`, a partir de `origin/develop` (ou da branch padrão, quando o repo não tem `develop`), com link para o `.env` do repo original. O código original e o que estiver rodando no workspace não são tocados.
3. Um **implementer por repositório** trabalha em paralelo, cada um na sua worktree. Em repos com docker compose, comandos e testes rodam com `docker compose run --rm <serviço>` a partir da worktree; o `run` não usa `container_name` fixo nem publica portas, então não conflita com um stack já rodando.
4. **Tester**, depois **reviewer** e **security-reviewer** em paralelo, olhando o diff de cada repo contra a sua base e a coerência entre os repos.
5. **Um PR por repositório**, na branch base e com links entre os PRs da task. A forja é detectada pelo remote: com a CLI dela instalada (`gh`, `glab` ou `tea`), o PR é aberto direto; sem CLI, a branch é publicada e você recebe o link para abrir o PR. Nenhum comando faz merge.

A cada etapa, a sessão grava o estado da task em `$CREW_WORKTREES/<task>/.crew/`, que alimenta o [dashboard](#dashboard).

Se o planner marcar mudança de UI num repo de front-end, o `/crew:feature` pergunta, junto da aprovação do plano, se você quer 3 variantes de design para ele. Não é preciso escolher o comando certo de antemão.

## Pré-requisitos

- Claude Code
- Docker com o plugin `compose` (o Playwright MCP roda em container; os seus projetos podem ou não usar compose)
- Opcional: a CLI da sua forja, autenticada, para o crew abrir os PRs sozinho: [`gh`](https://cli.github.com) (GitHub), [`glab`](https://gitlab.com/gitlab-org/cli) (GitLab) ou [`tea`](https://gitea.com/gitea/tea) (Forgejo e Gitea). Sem ela, o crew publica a branch e te dá o link do PR.
- `git` e `jq`

## Instalação na máquina (uma vez)

```bash
git clone <url-deste-repo> ~/code/crew
~/code/crew/bin/setup
```

O `bin/setup` é idempotente; rode de novo a qualquer momento. Ele:

1. confere as dependências;
2. mescla `CLAUDE_CODE_FORK_SUBAGENT=0` em `~/.claude/settings.json`, com backup em `settings.json.bak` e sem apagar o que já existir;
3. registra esta pasta como marketplace `crew` e instala o plugin `crew` no escopo usuário;
4. instala o plugin [impeccable](https://impeccable.style) (`pbakaus/impeccable`), usado nas variantes de UI; se já estiver instalado, não faz nada;
5. baixa as imagens do Playwright MCP e do dashboard (`nginx:alpine`).

Depois, **reinicie as sessões abertas do Claude Code**.

## Preparar um workspace (uma vez por workspace)

```bash
~/code/crew/bin/init-workspace ~/code/acme
```

Ele lista os repositórios encontrados e:

- mescla em `<workspace>/.claude/settings.json`:
  - `CREW_WORKTREES`: onde ficam as worktrees das tasks. O padrão é a pasta `worktrees` ao lado do workspace (para `~/code/acme`, `~/code/worktrees`); troque com `--worktrees <dir>`;
  - `additionalDirectories` com essa pasta, para o Claude Code poder editar as worktrees;
  - permissões: libera `docker compose`, `git` e os comandos de PR de `gh`, `glab` e `tea`; nega `git push --force` e a leitura de qualquer `.env`;
- cria `<workspace>/.claude/crew.md`, o perfil do workspace, a partir do modelo, se ainda não existir.

Nos repositórios com front-end, rode uma vez dentro do Claude Code, a partir do repo, para o impeccable aprender o design do projeto antes das primeiras variantes:

```
/impeccable teach
```

## Perfil do workspace

O perfil é um Markdown em `<workspace>/.claude/crew.md`. Todo agente e comando do crew o lê antes de começar, e **o que estiver nele prevalece sobre os padrões do plugin**. Escreva em linguagem natural, como instruções para um colega. O `init-workspace` cria o arquivo a partir de [templates/crew.md](templates/crew.md), com uma seção para cada ponto de extensão:

| Seção | Quem usa | Padrão do plugin quando a seção falta |
| --- | --- | --- |
| **Tarefas** | todos | usa o ID que aparecer no ticket; sem ID, segue sem nenhum (nunca inventa) |
| **Branches e commits** | worktrees, implementer, tester, ui-implementer | branch `<feature\|fix\|refactor>/<id>-<slug>`; base `develop`, senão a padrão do repo; commits pequenos, mensagem curta no imperativo |
| **Pull requests** | worktrees, /crew:status | detecta a forja pelo `origin` e usa `gh`, `glab` ou `tea` se instalado e autenticado; senão publica a branch e entrega o link do PR |
| **Execução** | worktrees, implementer, tester, ui-implementer, /crew:ui | docker compose do repo quando existir (`docker compose run --rm`); senão, o README do repo |
| **Revisão** | reviewer | bugs de correção, sobras de debug, duplicação, escopo; achados como bloqueador, sugestão ou nota |
| **Segurança e privacidade** | security-reviewer | checklist genérico (autorização e IDOR, injeção, exposição de API, segredos, sessão, uploads e SSRF, dependências, cache, dados pessoais) |

Seção vazia ou ausente = padrão do plugin. Você pode acrescentar seções próprias; os agentes leem o arquivo inteiro.

O perfil pertence ao workspace, não ao plugin: em geral ele não é versionado (a pasta do workspace costuma não ser um repo). Para compartilhar com o time, guarde-o num repositório interno e copie ou crie um link para `<workspace>/.claude/crew.md`.

Exemplo de perfil para uma plataforma SaaS multi-tenant:

```markdown
# Perfil do crew neste workspace

## Tarefas
- Tickets vêm do Jira; o ID tem o formato ACME-123. Se o ticket não trouxer o ID, pergunte.

## Branches e commits
- Branch `<tipo>/ACME-123-<slug>`; base sempre `main`.
- Conventional Commits; o ID vai no fim da primeira linha como `#ACME-123`.

## Execução
- Nunca rode node no host; tudo via docker compose.
- O stack inteiro sobe com `docker compose up -d` na raiz do workspace.

## Revisão
- Toda query nova em coleção grande precisa de índice: bloqueador.

## Segurança e privacidade
SaaS multi-tenant; legislação: LGPD e GDPR.
- Toda query filtra por `accountId`, não só pelo id.
- Banco PostgreSQL; cache Redis com chaves prefixadas por `accountId`.
- Erros vão para o Sentry: nenhum dado pessoal em mensagens ou contexto.
- Papéis: owner, admin, member. Member não vê dados de cobrança.
```

## Uso

Os comandos são sempre chamados com o prefixo `/crew:`:

| Comando | Fluxo |
| --- | --- |
| `/crew:feature <ticket>` | plano multi-repo → **aprovação** (e, se houver UI, a pergunta sobre variantes) → worktrees → implementação → testes → reviews → PRs |
| `/crew:bugfix <ticket, stack trace ou link do monitor de erros>` | diagnóstico → worktrees → teste de regressão falhando → correção → suíte verde → reviews → PRs |
| `/crew:refactor <descrição>` | invariantes → **aprovação** → worktrees → baseline → passos pequenos → suíte idêntica → reviews → PRs |
| `/crew:ui <tela/componente>` | brief → **aprovação** → 3 variantes em paralelo → screenshots na conversa → **você escolhe** → testes → reviews → PR |
| `/crew:status [filtro]` | lista as tasks, atualiza o estado dos PRs pela CLI da forja ou pelo git (merge → concluída) e oferece remover as worktrees das concluídas |

**Primeiro teste:** um `/crew:bugfix` pequeno e conhecido, para ver os gates e os dois revisores funcionando antes de usar em algo real.

**Limpeza:** as worktrees ficam em `$CREW_WORKTREES/<task>/` até o merge, para correções pedidas no review. Depois do merge, rode `/crew:status`: ele marca a task como concluída e oferece remover as worktrees (a pasta `.crew/` fica, para o histórico).

## Dashboard

```bash
~/code/crew/bin/dashboard ~/code/acme
```

Abre em http://localhost:7420 o painel com todas as tasks do workspace, atualizado a cada poucos segundos e legível do celular ao monitor grande. As tasks ficam em seções: **Precisa de você** no topo (paradas esperando sua resposta: aprovar o plano, escolher a variante, bloqueadores depois de 2 ciclos, possível incidente de segurança), depois **Em andamento**, e **Concluídas** e **Canceladas** recolhidas. Cada task mostra uma barra de etapas (Plano, Código, Testes, Revisão, PR, Merge), os repositórios, o último ciclo de testes e os vereditos dos dois revisores. O clique abre os detalhes: branches, PRs, todos os ciclos, o histórico e os artefatos (plano, resultados de teste e reviews de cada ciclo, descrição dos PRs).

Opções: `--port N` (padrão 7420), `--worktrees <dir>` (em vez de ler `CREW_WORKTREES` do `settings.json` do workspace) e `--stop` para derrubar.

O dashboard só lê. Ele roda num container `nginx:alpine` publicado só em `127.0.0.1`, com `$CREW_WORKTREES` montado como somente leitura, e serve apenas a lista de tasks e os arquivos `.json`/`.md` de `<task>/.crew/`; código das worktrees e links simbólicos (como o `.env`) não são servidos. A sessão principal é a única que grava o estado; os subagents nunca escrevem nele. O formato está no skill [`crew:state`](plugins/crew/skills/state/SKILL.md).

Se a sessão de uma task fechar no meio, o estado continua no disco: rode o mesmo comando de novo com o mesmo ticket e ele oferece continuar da etapa em que parou.

## Screenshots de UI

As variantes são fotografadas pela sessão principal, uma por vez: ela para o serviço do front que estiver rodando, sobe a variante a partir da worktree (com docker compose, `docker compose run --service-ports`), tira os prints em 1440px e 390px com o Playwright, derruba e passa para a próxima. No final, religa o serviço original. O resto do sistema (APIs, banco) continua o que já estava rodando.

## Decisões de projeto

- **Interativo.** Cada trabalho começa com um comando numa sessão aberta; sem execução headless, CI ou cron.
- **Gates humanos.** O planner devolve plano ou diagnóstico e o comando para até sua aprovação. A exceção é bugfix de alta confiança com correção pequena (menos de ~30 linhas). Nenhum comando faz merge.
- **Multi-repo.** O plugin detecta quais repos a task toca e quais são front-end; nada é configurado por repo.
- **Plugin genérico, perfil local.** Regras de time e de domínio ficam no perfil do workspace, nunca no plugin.
- **Worktree por repositório**, criada pela sessão principal, e não pelo `isolation: worktree` do Claude Code, que não funciona quando o workspace não é um repo git.
- **`CLAUDE_CODE_FORK_SUBAGENT=0` é obrigatório.** Com fork mode ligado a sessão não espera os subagents, e os pipelines são sequenciais.
- **Screenshots pela sessão principal**, não por subagent: subagents devolvem só texto, e o app desktop do Claude Code mostra as imagens direto na conversa. Nada de salvar prints em disco.
- **Fotografia de variantes é serial**, porque todas disputam a porta do serviço de front.
- **Dois revisores em paralelo** em todo pipeline: `reviewer` (qualidade, escopo) e `security-reviewer` (segurança e dados pessoais). Bloqueador de qualquer um volta para o implementer, no máximo 2 ciclos.
- **Estado em arquivo, fora dos repositórios**, em `$CREW_WORKTREES/<task>/.crew/`: funciona com vários repos por task e não precisa de `.gitignore`. Os prints de UI continuam fora do disco.
- **Playwright MCP via Docker** (`--network host`, para alcançar o app em `localhost`), sem exigir Node no host.

## Estrutura

```
.claude-plugin/marketplace.json     marketplace "crew"
plugins/crew/                       plugin (agents/, commands/, skills/worktrees/, skills/state/, .mcp.json)
dashboard/                          index.html do dashboard e nginx.conf
templates/crew.md                   modelo do perfil do workspace
templates/user-settings.json        env mesclado em ~/.claude/settings.json
templates/workspace-settings.json   env e permissões mesclados em <workspace>/.claude/settings.json
bin/setup                           instalação na máquina
bin/init-workspace                  preparação de um workspace
bin/dashboard                       sobe o dashboard local
```

Para conferir os manifestos depois de editar:

```bash
claude plugin validate . && claude plugin validate plugins/crew
```

## Para depois

- Hook de lint após edições (`PostToolUse` com matcher `Edit|Write`), com o comando de lint vindo do perfil do workspace.
- Publicar o marketplace no GitHub, para instalar com `claude plugin marketplace add <owner>/crew` sem clonar.
