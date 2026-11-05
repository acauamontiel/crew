---
description: UI — brief → 3 variantes em paralelo → screenshots na conversa → eu escolho → testes → reviews → PR
---
Tela/componente: $ARGUMENTS

Antes de começar, leia o perfil do workspace (`.claude/crew.md`, se existir); as regras dele prevalecem sobre as deste comando.

1. Use o subagent planner com TIPO = feature, pedindo além do plano um brief visual com 3 direções de design distintas e nomeadas, e as rotas a fotografar. Ele identifica o repo de front-end (e os de back-end, se a tela precisar de mudança na API). Me mostre e PARE até eu aprovar.
2. Prepare, seguindo o skill crew:worktrees, uma worktree por direção no repo de front-end (branch e pasta de variante de UI). Rode 3 subagents ui-implementer em paralelo, um por direção, todos com o mesmo brief.
   Se a tela precisar de mudança em repos de back-end, prepare a worktree deles e rode o implementer em paralelo.
3. Fotografe você mesmo, nesta sessão principal, uma variante por vez (nunca duas ao mesmo tempo), usando o que já estiver rodando para o resto do sistema (APIs, banco):
   - se o front estiver rodando (stack na raiz do workspace ou no repo), pare só o serviço dele, para liberar a porta: `docker compose stop <serviço do front>` onde o stack foi subido;
   - na worktree da variante, suba o front: com docker compose, `docker compose run --rm -d --service-ports --name crew-ui-shoot <serviço do front>`; senão, como o perfil ou o README mandam. Espere responder em localhost;
   - com o Playwright, para cada rota: screenshot em 1440px e em 390px de largura;
   - derrube o front da variante (`docker rm -f crew-ui-shoot`).
   Depois da última variante, religue o serviço que você parou (`docker compose start <serviço do front>`).
   Não salve as imagens em disco; quero vê-las na conversa.
4. Me apresente as variantes lado a lado: nome da direção, os prints, e uma crítica curta de cada usando /impeccable critique. Pergunte qual escolher, oferecendo também "misturar X com Y".
5. Com a escolhida: crie a worktree de trabalho do repo de front-end (branch de feature) e use o implementer para trazer a branch vencedora para ela. Remova as worktrees e branches das variantes seguindo o skill crew:worktrees.
6. Use o subagent tester. Depois rode em paralelo reviewer e security-reviewer, com as mesmas regras do /crew:feature.
7. Abra um PR por repo com `gh pr create --base <base>`, incluindo os prints da variante escolhida. Não faça merge.
