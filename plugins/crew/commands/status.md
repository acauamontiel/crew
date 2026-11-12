---
description: Status — lista as tasks do crew, atualiza o estado dos PRs e oferece limpar as concluídas
---
Filtro (opcional: ID, slug ou parte do título): $ARGUMENTS

Leia o perfil do workspace (`.claude/crew.md`, se existir). Siga o skill crew:state; aqui você é o único escritor do estado.

1. Se `$CREW_WORKTREES` não estiver definida, PARE e peça para rodar `bin/init-workspace` do crew neste workspace.
2. Liste as pastas de `$CREW_WORKTREES` que tenham `.crew/task.json` (aplique o filtro, se houver). Ignore as `cancelada`, a menos que o filtro aponte para uma.
3. Para cada task com PR aberto, consulte o estado conforme a seção "Pull requests" do skill crew:worktrees (com a CLI da forja ou, sem ela, pelo git) e, se mudou, grave com `crew-state <task> pr <repo> <merged|closed>`. Se todos os PRs da task estiverem `merged` ou `closed` (pelo menos um `merged`), rode `crew-state <task> stage concluida "PRs com merge"`.
4. Me mostre uma tabela: task | tipo | etapa | precisa de você? | risco | PRs (repo, número, estado) | tokens | atualizado. Use `crew-state <task> show` para ler cada task.
5. Se houver tasks `concluida` com worktrees ainda no disco, pergunte se devo removê-las. Com o meu sim, remova as worktrees e branches locais seguindo o skill crew:worktrees (nunca com mudanças não commitadas sem me perguntar), mas mantenha a pasta `.crew/` da task para o histórico.
6. Lembre que o dashboard sobe com `bin/dashboard <workspace>` no repositório do crew.
