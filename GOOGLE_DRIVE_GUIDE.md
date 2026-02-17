# Guia de Compartilhamento de Skills via Google Drive

Este guia explica como compartilhar e instalar skills do Antigravity usando o Google Drive.

## 📤 Como Compartilhar uma Skill no Google Drive

### Passo 1: Preparar a Skill para Compartilhamento

1. **Validar a skill:**
   ```powershell
   .\scripts\manage-skills.ps1 -Action Validate -SkillName "nome-da-skill"
   ```

2. **Exportar a skill como ZIP:**
   ```powershell
   .\scripts\manage-skills.ps1 -Action Export -SkillName "nome-da-skill" -Destination "C:\Temp"
   ```
   
   Isso criará um arquivo `nome-da-skill.zip`

### Passo 2: Fazer Upload para o Google Drive

1. Acesse [Google Drive](https://drive.google.com)
2. Clique em **"Novo"** → **"Upload de arquivo"**
3. Selecione o arquivo ZIP da skill
4. Aguarde o upload completar

### Passo 3: Configurar Permissões de Compartilhamento

1. Clique com o botão direito no arquivo ZIP no Google Drive
2. Selecione **"Compartilhar"**
3. Clique em **"Alterar para qualquer pessoa com o link"**
4. Certifique-se que está configurado como **"Leitor"** (não precisa ser editor)
5. Clique em **"Copiar link"**

### Passo 4: Compartilhar o Link

Você receberá um link como:
```
https://drive.google.com/file/d/XXXXXXXXXXXXX/view?usp=sharing
```

**Para facilitar o download direto**, converta o link para formato de download:

**Link original:**
```
https://drive.google.com/file/d/1ABC123XYZ/view?usp=sharing
```

**Link de download direto:**
```
https://drive.google.com/uc?export=download&id=1ABC123XYZ
```

Basta pegar o ID (parte entre `/d/` e `/view`) e usar no formato acima.

### Passo 5: Criar Documentação de Compartilhamento

Crie um arquivo `INSTALL.md` com instruções:

```markdown
# Instalação da Skill [Nome da Skill]

## Download

Baixe a skill aqui: [Link do Google Drive]

## Instalação Manual

1. Baixe o arquivo ZIP
2. Extraia o conteúdo
3. Copie a pasta para: `C:\Users\[SEU_USUARIO]\.gemini\antigravity\skills\`
4. Reinicie o Antigravity (se necessário)

## Instalação via Script

```powershell
.\scripts\manage-skills.ps1 -Action Install -Source "C:\Downloads\nome-da-skill.zip"
```

## Requisitos

- Antigravity AI instalado
- [Listar dependências, ex: Playwright MCP]

## Uso

[Instruções básicas de como usar a skill]
```

## 📥 Como Instalar uma Skill do Google Drive

### Método 1: Download Manual

1. **Baixar o arquivo:**
   - Clique no link compartilhado
   - Clique em **"Fazer download"** (ícone de seta para baixo)
   - Salve o arquivo ZIP

2. **Instalar usando o script:**
   ```powershell
   cd C:\Users\[SEU_USUARIO]\.gemini\antigravity\skills
   .\scripts\manage-skills.ps1 -Action Install -Source "C:\Downloads\nome-da-skill.zip"
   ```

3. **Verificar instalação:**
   ```powershell
   .\scripts\manage-skills.ps1 -Action List
   ```

### Método 2: Instalação Manual Completa

1. **Baixar e extrair:**
   - Baixe o arquivo ZIP do Google Drive
   - Clique com botão direito → **"Extrair tudo..."**
   - Escolha um local temporário

2. **Copiar para diretório de skills:**
   ```powershell
   # Exemplo
   Copy-Item -Path "C:\Temp\nome-da-skill" -Destination "$env:USERPROFILE\.gemini\antigravity\skills\" -Recurse
   ```

3. **Validar a skill:**
   ```powershell
   cd $env:USERPROFILE\.gemini\antigravity\skills
   .\scripts\manage-skills.ps1 -Action Validate -SkillName "nome-da-skill"
   ```

## 🗂️ Organizando um Repositório de Skills no Google Drive

### Estrutura Recomendada

```
Antigravity Skills/
├── networking/
│   ├── router-wifi-extractor.zip
│   ├── router-wifi-configurator.zip
│   └── README.md
├── web-development/
│   └── README.md
├── automation/
│   └── README.md
└── INDEX.md (lista de todas as skills)
```

### Criar um INDEX.md

```markdown
# Repositório de Skills do Antigravity

## Networking

### Router WiFi Extractor
- **Versão:** 1.0.0
- **Descrição:** Extrai informações de WiFi de roteadores
- **Download:** [Link do Google Drive]
- **Autor:** Yan Marcos
- **Compatibilidade:** Datacom, TP-Link, D-Link

### Router WiFi Configurator
- **Versão:** 1.0.0
- **Descrição:** Altera configurações de WiFi em roteadores
- **Download:** [Link do Google Drive]
- **Autor:** Yan Marcos
- **Compatibilidade:** Datacom, TP-Link, D-Link

## Web Development

[Suas skills de web development]

## Como Usar

1. Navegue até a categoria desejada
2. Clique no link de download
3. Siga as instruções de instalação
```

## 🔄 Atualizando Skills Compartilhadas

### Para o Autor da Skill:

1. **Atualizar a versão:**
   - Edite `metadata.json` e incremente a versão
   - Adicione entrada no changelog

2. **Exportar nova versão:**
   ```powershell
   .\scripts\manage-skills.ps1 -Action Export -SkillName "nome-da-skill"
   ```

3. **Substituir no Google Drive:**
   - Faça upload do novo ZIP
   - Mantenha o mesmo nome de arquivo
   - O link de compartilhamento permanecerá o mesmo

4. **Notificar usuários:**
   - Atualize o INDEX.md com a nova versão
   - Informe nos canais de comunicação

### Para Usuários:

1. **Verificar atualizações:**
   - Consulte o INDEX.md do repositório
   - Compare com sua versão instalada

2. **Atualizar:**
   ```powershell
   # Remover versão antiga
   .\scripts\manage-skills.ps1 -Action Remove -SkillName "nome-da-skill"
   
   # Instalar nova versão
   .\scripts\manage-skills.ps1 -Action Install -Source "C:\Downloads\nome-da-skill.zip"
   ```

## 📊 Exemplo de Repositório Completo

### Estrutura no Google Drive:

```
📁 Antigravity Skills Repository
│
├── 📄 INDEX.md (lista principal)
├── 📄 CONTRIBUTING.md (guia de contribuição)
│
├── 📁 networking
│   ├── 📄 README.md
│   ├── 📦 router-wifi-extractor-v1.0.0.zip
│   ├── 📦 router-wifi-configurator-v1.0.0.zip
│   └── 📦 network-scanner-v1.0.0.zip
│
├── 📁 web-development
│   ├── 📄 README.md
│   └── 📦 react-component-generator-v1.0.0.zip
│
└── 📁 automation
    ├── 📄 README.md
    └── 📦 task-scheduler-v1.0.0.zip
```

### INDEX.md Exemplo:

```markdown
# Antigravity Skills Repository

Repositório comunitário de skills para Antigravity AI.

## 📋 Índice

- [Networking](#networking)
- [Web Development](#web-development)
- [Automation](#automation)
- [Como Instalar](#como-instalar)
- [Como Contribuir](#como-contribuir)

## Networking

| Skill | Versão | Descrição | Download |
|-------|--------|-----------|----------|
| Router WiFi Extractor | 1.0.0 | Extrai informações de WiFi | [Download](link) |
| Router WiFi Configurator | 1.0.0 | Configura redes WiFi | [Download](link) |

## Web Development

| Skill | Versão | Descrição | Download |
|-------|--------|-----------|----------|
| React Component Generator | 1.0.0 | Gera componentes React | [Download](link) |

## Como Instalar

1. Clique no link de download da skill desejada
2. Baixe o arquivo ZIP
3. Execute:
   ```powershell
   .\scripts\manage-skills.ps1 -Action Install -Source "caminho\do\arquivo.zip"
   ```

## Como Contribuir

Quer compartilhar sua skill? Veja [CONTRIBUTING.md](link)
```

## 🔐 Segurança e Boas Práticas

### Para Autores:

1. **Nunca inclua credenciais** nos arquivos da skill
2. **Valide a skill** antes de compartilhar
3. **Documente dependências** claramente
4. **Teste em ambiente limpo** antes de publicar
5. **Mantenha um changelog** atualizado

### Para Usuários:

1. **Valide skills** antes de instalar:
   ```powershell
   .\scripts\manage-skills.ps1 -Action Validate -SkillName "nome-da-skill"
   ```

2. **Verifique a fonte** - baixe apenas de fontes confiáveis
3. **Leia a documentação** antes de usar
4. **Faça backup** de suas skills personalizadas
5. **Reporte problemas** ao autor

## 📞 Suporte

Para problemas com:
- **Instalação:** Consulte este guia
- **Uso da skill:** Consulte o SKILL.md da skill específica
- **Bugs:** Reporte ao autor da skill

## 🔗 Links Úteis

- [Documentação do Antigravity](link)
- [Guia de Criação de Skills](../README.md)
- [Comunidade no Discord](link)
- [GitHub do Projeto](link)

---

**Última atualização:** 2026-02-16
**Versão do guia:** 1.0.0
