# Antigravity Skills Registry

[![GitHub](https://img.shields.io/badge/GitHub-ai--skills--registry-blue?logo=github)](https://github.com/yanmsn/ai-skills-registry)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Skills](https://img.shields.io/badge/Skills-4-orange.svg)](./INDEX.md)
[![Categories](https://img.shields.io/badge/Categories-10-purple.svg)](./INDEX.md)

Repositório oficial de skills (habilidades) para Antigravity AI, organizadas por categoria e prontas para uso.

## 🔗 Links Rápidos

- **[📋 Índice Completo de Skills](./INDEX.md)** - Lista todas as skills disponíveis
- **[🤝 Guia de Contribuição](./CONTRIBUTING.md)** - Como contribuir com novas skills
- **[☁️ Guia do Google Drive](./GOOGLE_DRIVE_GUIDE.md)** - Compartilhamento via Google Drive
- **[🔧 Script de Gerenciamento](./scripts/manage-skills.ps1)** - Ferramenta de gerenciamento

## 📊 Estatísticas

- **Total de Skills:** 6
- **Categorias Ativas:** 3 (Networking, Automation, Security)
- **Última Atualização:** 2026-02-17
- **Repositório:** [github.com/yanmsn/ai-skills-registry](https://github.com/yanmsn/ai-skills-registry)

## 📚 O que são Skills?

Skills são pacotes de instruções, scripts e recursos que ensinam o Antigravity a realizar tarefas especializadas de forma eficiente e consistente. Cada skill documenta:

- **Quando usar** a skill
- **Como executar** a tarefa passo a passo
- **Exemplos práticos** de código
- **Troubleshooting** para problemas comuns
- **Recursos adicionais** (scripts, templates, etc.)

## 📁 Estrutura de uma Skill

Cada skill deve estar em sua própria pasta com a seguinte estrutura:

```
skill-name/
├── SKILL.md          # Arquivo principal (obrigatório)
├── examples/         # Exemplos de uso (opcional)
├── scripts/          # Scripts auxiliares (opcional)
├── resources/        # Recursos adicionais (opcional)
└── metadata.json     # Metadados da skill (recomendado)
```

### SKILL.md (Obrigatório)

Deve conter frontmatter YAML com:
```yaml
---
name: Nome da Skill
description: Breve descrição do que a skill faz
version: 1.0.0
author: Seu Nome
category: categoria
tags: [tag1, tag2, tag3]
---
```

### metadata.json (Recomendado)

```json
{
  "name": "Nome da Skill",
  "version": "1.0.0",
  "description": "Descrição detalhada",
  "author": "Seu Nome",
  "email": "seu@email.com",
  "category": "networking",
  "tags": ["router", "wifi", "networking"],
  "dependencies": [],
  "compatibility": {
    "routers": ["Datacom DM986-204", "TP-Link", "D-Link"],
    "os": ["windows", "linux", "macos"]
  },
  "created": "2026-02-16",
  "updated": "2026-02-16",
  "license": "MIT"
}
```

## 📂 Categorias de Skills

- **networking/** - Skills relacionadas a redes (roteadores, WiFi, etc.)
- **web-development/** - Desenvolvimento web
- **automation/** - Automação de tarefas
- **data-processing/** - Processamento de dados
- **system-admin/** - Administração de sistemas
- **security/** - Segurança e pentesting
- **cloud/** - Serviços em nuvem
- **database/** - Banco de dados
- **devops/** - DevOps e CI/CD
- **other/** - Outras categorias

## 🚀 Como Usar uma Skill

1. **Localizar a skill** no diretório apropriado
2. **Ler o SKILL.md** para entender como usar
3. **Seguir as instruções** documentadas
4. O Antigravity AI lerá automaticamente a skill quando relevante

## 📤 Como Compartilhar Skills

### Opção 1: GitHub (Recomendado)

1. Crie um repositório público no GitHub
2. Organize suas skills por categoria
3. Compartilhe o link do repositório
4. Outros usuários podem clonar: `git clone [URL]`

### Opção 2: Google Drive

1. Faça upload da pasta da skill para o Google Drive
2. Configure permissão de "Qualquer pessoa com o link pode visualizar"
3. Compartilhe o link
4. Outros usuários baixam e colocam em `.gemini/antigravity/skills/`

### Opção 3: Pacote ZIP

1. Compacte a pasta da skill em um arquivo .zip
2. Compartilhe via email, cloud storage, etc.
3. Outros usuários extraem em `.gemini/antigravity/skills/`

## 📥 Como Instalar Skills de Outros Usuários

### Instalação Manual

1. Baixe a skill (ZIP, clone do Git, etc.)
2. Extraia/copie para: `C:\Users\[SEU_USUARIO]\.gemini\antigravity\skills\`
3. Mantenha a estrutura de pastas
4. Reinicie o Antigravity se necessário

### Usando o Script de Gerenciamento (veja abaixo)

```powershell
# Instalar skill do Google Drive
.\manage-skills.ps1 -Action Install -Source "https://drive.google.com/..."

# Instalar skill do GitHub
.\manage-skills.ps1 -Action Install -Source "https://github.com/user/repo"

# Listar skills instaladas
.\manage-skills.ps1 -Action List

# Atualizar skill
.\manage-skills.ps1 -Action Update -SkillName "router-wifi-extractor"
```

## 🌐 Repositório Comunitário de Skills

### Skills Oficiais (Mantidas neste repositório)

- **router-wifi-extractor** - Extrai informações de WiFi de roteadores
- **router-wifi-configurator** - Altera configurações de WiFi em roteadores

### Skills da Comunidade

Para contribuir com skills para a comunidade:

1. Fork este repositório (se usando GitHub)
2. Adicione sua skill na categoria apropriada
3. Certifique-se de incluir `metadata.json`
4. Crie um Pull Request com descrição detalhada
5. Aguarde revisão e aprovação

## 📋 Checklist para Criar uma Skill de Qualidade

- [ ] Nome descritivo e único
- [ ] SKILL.md com frontmatter YAML completo
- [ ] metadata.json com todas as informações
- [ ] Seção "Quando Usar" clara
- [ ] Instruções passo a passo detalhadas
- [ ] Exemplos de código funcionais
- [ ] Seção de troubleshooting
- [ ] Testada em ambiente real
- [ ] Documentação de dependências
- [ ] Informações de compatibilidade
- [ ] Licença definida

## 🔧 Ferramentas de Gerenciamento

### Script PowerShell: manage-skills.ps1

Um script para gerenciar skills (instalar, atualizar, listar, remover).
Veja: `scripts/manage-skills.ps1`

### Validador de Skills

Valida se uma skill está corretamente formatada.
Veja: `scripts/validate-skill.ps1`

## 📖 Exemplos de Skills

### Skill Simples (Mínima)

```
my-simple-skill/
└── SKILL.md
```

### Skill Completa

```
my-advanced-skill/
├── SKILL.md
├── metadata.json
├── examples/
│   ├── example1.js
│   └── example2.py
├── scripts/
│   └── helper.ps1
└── resources/
    ├── template.html
    └── config.json
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Para contribuir:

1. Crie uma skill seguindo as diretrizes acima
2. Teste completamente
3. Documente bem
4. Compartilhe com a comunidade

## 📞 Suporte

Para dúvidas ou problemas:
- Abra uma issue no GitHub
- Consulte a documentação do Antigravity
- Entre em contato com a comunidade

## 📜 Licença

As skills neste repositório podem ter licenças individuais. Verifique o arquivo `metadata.json` ou `LICENSE` em cada skill.

---

**Última atualização:** 2026-02-16
**Versão do documento:** 1.0.0
