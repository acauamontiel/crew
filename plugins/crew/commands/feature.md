---
description: Feature — plano multi-repo → aprovação → worktrees → implementação → testes → reviews → PRs
---
Ticket: $ARGUMENTS

Antes de começar, leia o perfil do workspace (`.claude/crew.md`, se existir); as regras dele prevalecem sobre as deste comando.

Registre o andamento seguindo o skill crew:state: crie o estado logo depois do planner e atualize-o a cada passo, gravando os artefatos (plano, testes, reviews, PRs). Grave antes de PARAR para me perguntar e de novo quando eu responder.

1. Use o subagent planner com TIPO = feature. Me mostre o plano, com a tabela de repositórios afetados, e PARE: aguarde minha aprovação antes de continuar.
   Se algum repo de front-end tiver UI = sim, pergunte junto da aprovação se quero 3 variantes de design para ele. Se sim, peça ao planner o brief visual (3 direções nomeadas e rotas a fotografar) e, para esse repo, siga os passos 2 a 5 de /crew:ui no lugar do passo 3 abaixo.
2. Prepare as worktrees de todos os repos afetados seguindo o skill crew:worktrees e me mostre a tabela.
3. Use um subagent implementer por repo, em paralelo, cada um com o plano aprovado e a linha do seu repo na tabela.
4. Use o subagent tester com a tabela. Se houver falhas, retome o implementer do repo com as falhas. Máximo 3 ciclos.
5. Rode em paralelo o subagent reviewer e o subagent security-reviewer, ambos com a tabela.
   Se qualquer um apontar bloqueador, retome o implementer do repo com os bloqueadores dos dois. Máximo 2 ciclos; depois disso PARE e me mostre o que restou.
   Achados alta/média de segurança não corrigidos entram numa seção "Riscos aceitos" na descrição do PR.
6. Abra um PR por repo com `gh pr create --base <base>` a partir da worktree: plano na descrição, links para os PRs dos outros repos da task, e os reviews daquele repo como comentários. Não faça merge.
