# POST LINKEDIN — PORTUGUÊS

---

A OpenAI publicou um experimento onde 1 milhão de linhas de código foram escritas 100% por IA em 5 meses.

O insight mais importante não foi a velocidade.

Foi que AGENTS.md gigante não funciona. Os agentes ignoram. É caro em contexto. Impossível de manter.

O ponto de virada veio quando trataram o repositório inteiro como sistema de registro para agentes: docs distribuídos, specs versionadas, arquitetura codificada, regras de qualidade como linters.

A "fonte da verdade" deixou de ser o código e virou o ecossistema em volta dele.

Eu cheguei na mesma conclusão por outro caminho.

Passei meses construindo skills pro Claude Code — não prompts, skills. Arquivos especializados que o modelo carrega automaticamente conforme o contexto.

Comecei com um SKILL.md grande. Mesmo problema da OpenAI: caro, ignorado, genérico demais.

Aí refatorei com progressive disclosure: skill principal com ~100 linhas + 21 arquivos de referência que carregam sob demanda. O modelo lê o mínimo necessário e mergulha fundo só quando precisa.

Resultado: 24 skills cobrindo code review, clean architecture, SOLID, TDD, pentest, Terraform, observability, sprint planning, postmortems.

10.000 linhas de conhecimento técnico que o Claude aplica sozinho. Sem eu escrever um prompt.

Empacotei como plugin open source e submeti pro marketplace oficial da Anthropic.

A lição é a mesma que a OpenAI aprendeu: o futuro não é escrever prompts melhores. É construir o ecossistema que faz o agente pensar melhor.

Quem ainda tá escrevendo prompt manual pra cada tarefa tá resolvendo o problema errado.

Link nos comentários.

#ClaudeCode #Anthropic #AI #OpenSource #AgenticAI

---

# PRIMEIRO COMENTÁRIO

CTO Toolkit — 24 skills para Claude Code

github.com/camilooscargbaptista/cto-toolkit

Para instalar:
git clone https://github.com/camilooscargbaptista/cto-toolkit.git
claude --plugin-dir ./cto-toolkit

Todas as skills detalhadas: girardellitecnologia.com/plugins/cto-toolkit.html

O experimento da OpenAI (Harness Engineering): openai.com/index/harness-engineering
