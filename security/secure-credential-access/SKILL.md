---
name: Secure Credential Access
description: Recupera credenciais de serviços (senhas / tokens) de forma segura do cofre Obsidian (Passwords Vault).
version: 1.0.0
author: Yan Marcos
category: security
tags: [security, credentials, secrets, obsidian, password-manager]
---

# Secure Credential Access Skill

Esta skill permite acessar credenciais sensíveis armazenadas no cofre do Obsidian sem hardcodar senhas no código ou chat.
O objetivo é obter o `usuário` e `senha` (ou `token`) para autenticação em serviços externos.

## Pré-requisitos
- MCP do Obsidian (`mcp-obsidian`) deve estar instalado e configurado no cliente.
- O Vault deve conter a pasta `Passwords/` com as notas de cada serviço.

## Estrutura do Vault
As notas de senha devem seguir o template:
```markdown
---
service: GitHub
username: user-github
password: "MINHA_SENHA_SECRETA"
token: "ghp_TOKEN_SECRETO"
url: "https://github.com"
---
```

## Como Usar
Ao precisar de uma senha em uma tarefa ou outra skill:

1. Identifique o serviço necessário (ex: `GitHub`, `Email`, `Router`).
2. Utilize a ferramenta `obsidian.read_note` com o caminho `Passwords/[NomeDoServiço].md`.
3. Extraia as informações do frontmatter (`fm`).
4. **IMPORTANTE**: Use as credenciais DIRETAMENTE na ferramenta de destino (ex: `playwright.fill_form`, `run_command`).
5. **NUNCA** exiba a senha no chat ou output final.

## Exemplo de Uso (Pseudo-código)

### Passo 1: Ler credenciais
```javascript
// Solicitar leitura da nota
// Ferramenta: obsidian.read_note({ path: "Passwords/GitHub.md" })
// Retorno: { fm: { username: "yan", password: "123" }, content: "..." }
```

### Passo 2: Usar credenciais
```javascript
// Usar em um login web
// Ferramenta: custom_browser_action.fill_form({
//   fields: [
//     { selector: "#login_field", value: credential.fm.username },
//     { selector: "#password", value: credential.fm.password }
//   ]
// })
```

## Serviços Comuns

- **GitHub**: `Passwords/GitHub.md`
- **Email**: `Passwords/Email.md`
- **Roteador**: `Passwords/Router.md`
- **Twitter**: `Passwords/Twitter.md`
