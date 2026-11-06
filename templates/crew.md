# Perfil do crew neste workspace

<!--
Lido por todos os agentes e comandos do crew antes de começar. O que estiver
aqui prevalece sobre os padrões do plugin. Escreva em linguagem natural, como
instruções para um colega. Apague as seções que não usar: seção ausente = padrão
do plugin. Comentários HTML como este podem ficar; os agentes os ignoram.
-->

## Tarefas

<!--
De onde vem o ID da task e como ele aparece.
Padrão do plugin: usa o ID que aparecer no ticket; sem ID, segue sem nenhum (nunca inventa).
Exemplo: "Tickets vêm do Jira; o ID tem o formato ABC-123."
-->

## Branches e commits

<!--
Padrão do plugin: branch <feature|fix|refactor>/<id>-<slug> (ou <tipo>/<slug> sem ID);
base develop quando existir, senão a branch padrão do repo; commits pequenos, mensagem
curta no imperativo.
Exemplo: "Commits em Conventional Commits; o ID vai no fim da primeira linha como #ABC-123."
-->

## Pull requests

<!--
Onde e como abrir os PRs.
Padrão do plugin: detecta a forja pelo remote `origin` e usa a CLI dela se estiver instalada e
autenticada (gh no GitHub, glab no GitLab, tea no Forgejo/Gitea); sem CLI, publica a branch e
entrega o link para você abrir o PR. Nunca faz merge.
Exemplo: "Forgejo self-hosted em git.exemplo.com, com `tea` (login `exemplo`). PRs sempre como rascunho."
-->

## Execução

<!--
Como subir o projeto, instalar dependências e rodar testes.
Padrão do plugin: se o repo tiver docker compose, tudo roda dentro do container com
`docker compose run --rm <serviço>`; senão, segue o README do repo.
Exemplo: "Nunca rode node no host. O stack inteiro sobe com `docker compose up -d` na raiz do workspace."
-->

## Revisão

<!--
Critérios extras do reviewer: padrões do time, o que costuma dar problema, formato do comentário.
Exemplo: "Toda query nova precisa de índice; aponte como bloqueador."
-->

## Segurança e privacidade

<!--
Riscos do domínio para o security-reviewer: modelo de tenant e papéis, bancos e caches,
serviços de terceiros que recebem dados, legislação de proteção de dados aplicável.
Exemplo: "SaaS multi-tenant: toda query filtra por accountId. Papéis: admin, editor, leitor."
-->
