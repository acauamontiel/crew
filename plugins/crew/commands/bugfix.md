---
description: Bug — diagnóstico → worktrees → teste de regressão falhando → correção → suíte verde → reviews → PRs
---
Bug (ticket, stack trace ou link do monitor de erros): $ARGUMENTS

Antes de começar, leia o perfil do workspace (`.claude/crew.md`, se existir); as regras dele prevalecem sobre as deste comando.

Registre o andamento seguindo o skill crew:state: crie o estado logo depois do planner e atualize-o a cada passo, gravando os artefatos (plano, testes, reviews, PRs). Grave antes de PARAR para me perguntar e de novo quando eu responder.

1. Use o subagent planner com TIPO = bug.
   Se a confiança for alta e a correção tiver menos de ~30 linhas, siga sem me perguntar.
   Caso contrário, me mostre o diagnóstico e PARE até eu confirmar.
2. Prepare as worktrees dos repos afetados seguindo o skill crew:worktrees (branch de fix).
3. Use o subagent tester para escrever SÓ o teste de regressão e confirmar que ele falha. Se não falhar, o diagnóstico está errado: volte ao passo 1 e me avise.
4. Use o subagent implementer com a correção mínima, um por repo afetado. Nada além do escopo do bug.
5. Use o subagent tester: teste de regressão passando e suíte inteira verde em cada repo.
6. Rode em paralelo, ambos com a tabela de worktrees:
   - subagent reviewer, com a pergunta explícita "isso corrige a causa ou o sintoma?"
   - subagent security-reviewer, incluindo a pergunta extra de bugfix
   Se qualquer um apontar bloqueador, retome o implementer. Máximo 2 ciclos; depois PARE e me mostre o que restou.
   Se o security-reviewer indicar possível incidente de segurança ou vazamento de dado pessoal, PARE e me avise antes de abrir o PR.
7. Abra um PR por repo seguindo a seção "Pull requests" do skill crew:worktrees, incluindo causa raiz, o teste de regressão, links para os PRs dos outros repos e "Riscos aceitos" se houver. Não faça merge.
