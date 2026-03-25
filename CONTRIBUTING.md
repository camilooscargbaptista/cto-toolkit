# Contributing to CTO Toolkit

Obrigado pelo interesse em contribuir! Este guia explica como adicionar ou melhorar skills no toolkit.

## Estrutura de uma Skill

```
skill-name/
├── SKILL.md                    # Obrigatório — arquivo principal
└── references/                 # Opcional — profundidade extra
    ├── pattern-guide.md
    ├── checklist.md
    └── examples.md
```

## SKILL.md — Template

```markdown
---
name: skill-name
description: "One-line description of what this skill does"
---

# Skill Title

## When to Use
- [Situações em que esta skill é ativada]

## [Main Content]
[Checklists, patterns, frameworks, exemplos]

## Output Format
[Formato esperado da saída quando a skill é usada]

## Quality Gates
- [ ] [Critérios de qualidade que o output deve atender]
```

### Seções Obrigatórias
1. **When to Use** — triggers claros
2. **Checklists/Framework** — conteúdo acionável
3. **Output Format** — formato esperado do resultado
4. **Quality Gates** — critérios de qualidade

### Seções Recomendadas
- Anti-patterns (o que NÃO fazer)
- Exemplos de código (com ✅ e ❌)
- References (links para material aprofundado)

## Guidelines

### Escrita
- Seja **acionável**, não teórico
- Use **checklists** (checkbox format: `- [ ]`)
- Inclua **exemplos de código** com bom e ruim
- Mantenha SKILL.md **< 300 linhas** (profundidade vai em references/)
- Use **tabelas** para comparações
- Use **diagramas ASCII** para arquitetura

### Código
- TypeScript/Node.js como stack principal de exemplos
- Adicionar exemplos para outras stacks quando relevante
- Manter exemplos autocontidos (não depender de context externo)

### Scripts (hooks/scripts/)
- Bash puro (sem dependências externas)
- `set -euo pipefail` no início
- Mensagens com emojis para feedback visual
- Exit code 0 para sucesso, 1 para falha
- Testar em macOS e Linux

## Pull Request

1. Fork o repositório
2. Crie branch: `feat/add-[skill-name]`
3. Adicione skill seguindo o template
4. Teste: verifique que `SKILL.md` é detectado pelo Claude
5. Abra PR com descrição detalhada

## Review Criteria

- [ ] Segue o template de SKILL.md
- [ ] Tem "When to Use" claro
- [ ] Conteúdo é acionável (não apenas teórico)
- [ ] Exemplos de código testados
- [ ] Quality Gates definidos
- [ ] Não duplica skill existente
