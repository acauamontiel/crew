---
description: Refactor — invariantes → worktrees → baseline de testes → passos pequenos → zero mudança de comportamento → reviews → PRs
---
Refactor: $ARGUMENTS

Antes de começar, leia o perfil do workspace (`.claude/crew.md`, se existir); as regras dele prevalecem sobre as deste comando.

1. Use o subagent planner com TIPO = refactor. Me mostre a tabela de repos, invariantes, cobertura e sequência e PARE até eu aprovar.
2. Prepare as worktrees dos repos afetados seguindo o skill crew:worktrees (branch de refactor).
3. Se o plano pedir testes de caracterização, use o subagent tester para escrevê-los e rodar a suíte ANTES de qualquer mudança. Guarde o resultado como baseline, por repo.
4. Use o subagent implementer passo a passo do plano, um commit por passo, rodando a suíte a cada commit. Repos diferentes podem ir em paralelo; no mesmo repo, um passo por vez. Se um passo quebrar a suíte, reverta o passo e me avise em vez de "consertar".
5. Use o subagent tester: suíte idêntica ao baseline em cada repo (mesmos testes passando, nenhum novo comportamento).
6. Rode em paralelo, ambos com a tabela de worktrees:
   - subagent reviewer, com a pergunta "há alguma mudança de comportamento ou feature creep no diff?"
   - subagent security-reviewer
   Se qualquer um apontar bloqueador, retome o implementer. Máximo 2 ciclos; depois PARE e me mostre o que restou.
7. Abra um PR por repo com `gh pr create --base <base>` a partir da worktree, listando os invariantes preservados, links para os PRs dos outros repos e "Riscos aceitos" se houver. Não faça merge.
