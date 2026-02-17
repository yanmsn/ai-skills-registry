# Guia de Contribuição

Obrigado por considerar contribuir para o AI Skills Registry! Este documento fornece diretrizes para contribuir com novas skills ou melhorias.

## Como Contribuir

### 1. Fork e Clone

1. Faça um fork deste repositório
2. Clone seu fork:
   ```bash
   git clone https://github.com/SEU-USUARIO/ai-skills-registry.git
   cd ai-skills-registry
   ```

### 2. Crie uma Nova Skill

1. **Escolha a categoria apropriada:**
   - `networking/` - Redes, roteadores, WiFi
   - `web-development/` - Desenvolvimento web
   - `automation/` - Automação de tarefas
   - `data-processing/` - Processamento de dados
   - `system-admin/` - Administração de sistemas
   - `security/` - Segurança e pentesting
   - `cloud/` - Serviços em nuvem
   - `database/` - Banco de dados
   - `devops/` - DevOps e CI/CD
   - `other/` - Outras categorias

2. **Crie a estrutura da skill:**
   ```
   categoria/
   └── nome-da-skill/
       ├── SKILL.md          # Obrigatório
       ├── metadata.json     # Recomendado
       ├── examples/         # Opcional
       ├── scripts/          # Opcional
       └── resources/        # Opcional
   ```

3. **Preencha o SKILL.md:**
   ```markdown
   ---
   name: Nome da Skill
   description: Breve descrição
   version: 1.0.0
   author: Seu Nome
   category: categoria
   tags: [tag1, tag2, tag3]
   ---

   # Nome da Skill

   ## Quando Usar
   [Descreva quando usar esta skill]

   ## Informações Necessárias
   [Liste informações necessárias]

   ## Processo de Execução
   [Passo a passo detalhado]

   ## Exemplos
   [Exemplos práticos]

   ## Troubleshooting
   [Problemas comuns e soluções]
   ```

4. **Crie o metadata.json:**
   ```json
   {
     "name": "Nome da Skill",
     "version": "1.0.0",
     "description": "Descrição detalhada",
     "author": "Seu Nome",
     "email": "seu@email.com",
     "category": "categoria",
     "tags": ["tag1", "tag2"],
     "dependencies": [],
     "compatibility": {},
     "created": "2026-02-16",
     "updated": "2026-02-16",
     "license": "MIT"
   }
   ```

### 3. Teste Sua Skill

1. **Valide a estrutura:**
   ```powershell
   .\scripts\manage-skills.ps1 -Action Validate -SkillName "nome-da-skill"
   ```

2. **Teste em ambiente real:**
   - Instale a skill localmente
   - Execute os exemplos
   - Verifique se funciona conforme esperado

### 4. Atualize a Documentação

1. **Atualize o README da categoria:**
   ```markdown
   ### Nome da Skill
   - **Versão:** 1.0.0
   - **Descrição:** Breve descrição
   - **Autor:** Seu Nome
   - **Compatibilidade:** [Lista de compatibilidade]

   [📁 Ver Skill](./nome-da-skill/)
   ```

### 5. Commit e Push

1. **Crie um branch:**
   ```bash
   git checkout -b add-nome-da-skill
   ```

2. **Adicione os arquivos:**
   ```bash
   git add categoria/nome-da-skill/
   git add categoria/README.md
   ```

3. **Commit com mensagem descritiva:**
   ```bash
   git commit -m "feat: adiciona skill Nome da Skill para categoria"
   ```

4. **Push para seu fork:**
   ```bash
   git push origin add-nome-da-skill
   ```

### 6. Crie um Pull Request

1. Vá para o repositório original no GitHub
2. Clique em "New Pull Request"
3. Selecione seu branch
4. Preencha o template do PR:
   - Descrição da skill
   - Categoria
   - Casos de uso
   - Testes realizados

## Diretrizes de Qualidade

### Obrigatório

- [ ] SKILL.md com frontmatter YAML completo
- [ ] Instruções claras e detalhadas
- [ ] Exemplos práticos funcionais
- [ ] Testado em ambiente real
- [ ] Sem credenciais ou informações sensíveis
- [ ] Licença compatível (MIT recomendada)

### Recomendado

- [ ] metadata.json completo
- [ ] Seção de troubleshooting
- [ ] Exemplos de código
- [ ] Screenshots ou GIFs (quando aplicável)
- [ ] Documentação de dependências
- [ ] Changelog para atualizações

### Boas Práticas

1. **Nomenclatura:**
   - Use kebab-case: `nome-da-skill`
   - Seja descritivo mas conciso
   - Evite abreviações obscuras

2. **Documentação:**
   - Escreva em português claro
   - Use exemplos práticos
   - Documente todos os parâmetros
   - Inclua casos de erro

3. **Código:**
   - Comente código complexo
   - Use nomes de variáveis descritivos
   - Siga convenções da linguagem
   - Evite hardcoding de valores

4. **Segurança:**
   - NUNCA inclua credenciais
   - Documente requisitos de permissão
   - Avise sobre operações destrutivas
   - Valide inputs do usuário

## Tipos de Contribuição

### Nova Skill

Adicione uma skill completamente nova seguindo o processo acima.

### Melhoria de Skill Existente

1. Fork e clone o repositório
2. Faça as melhorias
3. Atualize a versão no metadata.json
4. Adicione entrada no changelog
5. Crie PR descrevendo as melhorias

### Correção de Bug

1. Identifique o bug
2. Crie issue descrevendo o problema
3. Fork e corrija
4. Referencie a issue no PR

### Documentação

1. Identifique área que precisa de melhoria
2. Faça as alterações
3. Crie PR com descrição clara

## Processo de Revisão

1. **Revisão Automática:**
   - Validação de estrutura
   - Verificação de licença
   - Scan de segurança

2. **Revisão Manual:**
   - Qualidade da documentação
   - Funcionalidade da skill
   - Aderência às diretrizes

3. **Feedback:**
   - Comentários no PR
   - Solicitações de mudança
   - Aprovação ou rejeição

## Versionamento

Usamos [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Mudanças incompatíveis
- **MINOR** (0.1.0): Novas funcionalidades compatíveis
- **PATCH** (0.0.1): Correções de bugs

## Código de Conduta

- Seja respeitoso e profissional
- Aceite feedback construtivo
- Foque no mérito técnico
- Ajude outros contribuidores

## Dúvidas?

- Abra uma issue com a tag `question`
- Entre em contato via email
- Consulte a documentação existente

## Agradecimentos

Obrigado por contribuir para o AI Skills Registry! Sua contribuição ajuda toda a comunidade Antigravity AI.

---

**Última atualização:** 2026-02-16
