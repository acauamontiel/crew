---
name: worktrees
description: Procedimento do crew para ler o perfil do workspace, mapear os repositórios, achar a branch base, preparar, usar e remover as worktrees de uma task. Use nos comandos /crew:feature, /crew:bugfix, /crew:refactor e /crew:ui antes de qualquer implementação.
user-invocable: false
---
# Worktrees do crew

O crew trabalha em um **workspace**, com um ou vários repositórios. Cada task ganha uma worktree por repositório afetado; o código original e o que estiver rodando no workspace nunca são tocados.

## Perfil do workspace

Leia `.claude/crew.md` na raiz do workspace, se existir. As regras dele prevalecem sobre os padrões deste skill e dos agentes. Repasse a todo subagent que o perfil existe.

## Workspace e repositórios

- Workspace: o diretório onde a sessão roda.
- Repositórios: o próprio workspace, se ele for um repo git; senão, cada subdiretório imediato que tenha `.git`.
- Raiz das worktrees: `$CREW_WORKTREES`. Se a variável não estiver definida, PARE e peça para rodar `bin/init-workspace` do crew neste workspace.

## Classificar um repositório

- **Front-end**: o `package.json` depende de um framework de UI (ex.: `vue`, `nuxt`, `react`, `next`, `svelte`, `angular`, `vite`), ou o repo tem telas (`.vue`, `.tsx`, `.svelte`, templates HTML). Senão, **back-end**. Um repo pode ser os dois; diga quais partes são cada coisa.
- **Execução**: se o repo tiver `compose.yml`/`docker-compose.yml`, anote o serviço principal; senão, como o perfil ou o README mandam rodar.
- **Branch base**: a do perfil, se ele definir. Senão, rode `git -C <repo> fetch origin` e use `develop` se `git -C <repo> rev-parse --verify -q origin/develop` existir; senão a branch padrão, `git -C <repo> symbolic-ref --short refs/remotes/origin/HEAD` sem o prefixo `origin/`.

## ID da task e nome da branch

- ID: conforme o perfil. Sem perfil, o ID que aparecer no ticket; se não houver, siga sem ID. Nunca invente um ID.
- Branch: conforme o perfil. Sem perfil, `feature/<id>-<slug>`, `fix/<id>-<slug>` ou `refactor/<id>-<slug>` (sem ID: `<tipo>/<slug>`), a mesma em todos os repos da task. Variantes de UI: `ui/<id ou slug>/<direção>`.
- Pasta da task: `$CREW_WORKTREES/<id ou slug>/`.

## Preparar

Para cada repo afetado:

1. `git -C <repo> worktree add $CREW_WORKTREES/<task>/<repo> -b <branch> origin/<base>`. Variante de UI: pasta `$CREW_WORKTREES/<task>/<repo>--<direção>`. Se a worktree já existir (retomada), reutilize.
2. Arquivos de ambiente ignorados pelo git (ex.: `.env`) não vêm para a worktree: crie um link para o original, `ln -s <caminho absoluto do repo>/.env <worktree>/.env`. Nunca leia nem copie o conteúdo.
3. Instale as dependências a partir da worktree, do jeito descrito em "Rodar comandos".

Devolva uma tabela: repo | tipo | worktree | branch | base | execução. Passe essa tabela a todo subagent da task.

## Rodar comandos

Sempre a partir da worktree. Se o repo tiver docker compose: `docker compose run --rm <serviço> <comando>`. O `run` não usa `container_name` fixo nem publica portas, então não conflita com um stack que já esteja rodando. Senão, siga o perfil ou o README do repo.

## Pull requests

O crew não depende de uma forja específica. Para cada repo da task:

1. **Ferramenta.** A do perfil (seção "Pull requests"), se ele definir. Senão, olhe o host de `git -C <repo> remote get-url origin`:
   - GitHub (github.com ou GitHub Enterprise): `gh`, se estiver instalado e autenticado (`gh auth status`);
   - GitLab: `glab`, se estiver instalado e autenticado;
   - Forgejo ou Gitea: `tea`, se estiver instalado e com login para esse host (`tea login list`);
   - nenhuma dessas: **modo manual**.
2. **Publicar a branch:** `git -C <worktree> push -u origin <branch>`. Nunca com `--force`.
3. **Abrir o PR** a partir da worktree, com base `<base>` e, como descrição, o arquivo `.crew/pr/<repo>.md` do estado (skill crew:state):
   - gh: `gh pr create --base <base> --head <branch> --title "<título>" --body-file <arquivo>`
   - glab: `glab mr create --target-branch <base> --source-branch <branch> --title "<título>" --description "<texto>"`
   - tea: `tea pulls create --base <base> --head <branch> --title "<título>" --description "<texto>"`
   Se não tiver certeza da sintaxe da versão instalada, consulte o `--help` antes. Os reviews entram como comentários do PR quando a ferramenta permitir; senão, no fim da descrição.
4. **Modo manual:** não tente criar o PR por API nem por navegador. Me entregue, por repo, o link de abertura e a descrição pronta para colar:
   - GitHub: `https://<host>/<dono>/<repo>/compare/<base>...<branch>?expand=1`
   - GitLab: `https://<host>/<dono>/<repo>/-/merge_requests/new?merge_request[source_branch]=<branch>&merge_request[target_branch]=<base>`
   - Forgejo ou Gitea: `https://<host>/<dono>/<repo>/compare/<base>...<branch>`
   Converta remotes SSH (`git@host:dono/repo.git`) para o host e o caminho acima. No estado, deixe a task em `pr` com `waiting` "abrir os PRs pelos links", e registre cada PR só quando eu disser o número ou o link.
5. **Nunca faça merge**, em nenhuma ferramenta.

**Consultar o estado de um PR** (usado pelo /crew:status): com a CLI, o comando de visualização dela (`gh pr view <url> --json state`, `glab mr view <n>`, `tea pulls <n>`; veja o `--help`). Sem CLI: `git -C <repo> fetch origin` e `git -C <repo> merge-base --is-ancestor origin/<branch> origin/<base>` detecta merge comum e fast-forward, mas não squash nem rebase; se não der para saber, me pergunte.

## Remover

Ao descartar variantes de UI, ou quando eu pedir depois do merge: `git -C <repo> worktree remove <worktree>` e `git -C <repo> branch -D <branch>`. Nunca remova uma worktree com mudanças não commitadas sem me perguntar.
