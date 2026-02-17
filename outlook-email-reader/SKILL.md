---
name: Outlook Email Reader
description: Acessa e lê a caixa de entrada do Microsoft Outlook de forma automatizada e segura, retornando um resumo dos últimos e-mails importantes.
version: 1.0.0
author: Yan Marcos
category: communication
tags: [email, outlook, automation, productivity, security]
---

# Outlook Email Reader Skill

Esta skill automatiza o processo de login e leitura de e-mails no Microsoft Outlook (versão web), utilizando credenciais armazenadas de forma segura no cofre do Obsidian.

## 🚀 Quando Usar
- Verificar se chegaram e-mails importantes.
- Monitorar respostas de processos seletivos ou contatos específicos.
- Obter um resumo rápido da caixa de entrada sem abrir o navegador manualmente.

## 🔒 Segurança
- **NUNCA** solicite a senha ao usuário no chat.
- As credenciais DEVEM ser lidas do arquivo `Passwords/Email.md` no cofre do Obsidian.
- O login deve ser realizado em modo "headless" ou visual, mas sempre de forma segura.
- A skill deve optar por "Não manter conectado" para evitar persistência de sessão indesejada.

## 📋 Pré-requisitos
1.  **MCP Obsidian configurado**: O arquivo `Passwords/Email.md` deve existir e conter:
    ```yaml
    username: seu_email@outlook.com
    password: "sua_senha"
    ```
2.  **MCP Playwright instalado**: Para automação do navegador.

## 🛠️ Processo de Execução

### 1. Obter Credenciais
Primeiro, leia a nota de senha no Obsidian para obter o usuário e senha.
```javascript
// Exemplo de chamada
const credentials = await client.callTool("obsidian", "read_note", { path: "Passwords/Email.md" });
const { username, password } = credentials.fm;
```

### 2. Acessar e Logar no Outlook
Acesse a URL direta de login para agilizar o processo: `https://outlook.live.com/owa/?nlp=1`

**Fluxo de Login Típico:**
1.  **Preencher Email**: Digitar o `username` e clicar em "Avançar" (`Next`).
2.  **Aguardar**: Esperar o campo de senha aparecer.
3.  **Preencher Senha**: Digitar o `password` e clicar em "Entrar" (`Sign in`).
4.  **Prompt "Manter Conectado?"**: Clicar em "Não" (`idBtn_Back` ou similar).
5.  **Ignorar Segurança**: Se aparecer sugestão de segurança/app authenticator, clicar em "Ignorar por enquanto" ou "Cancelar".

### 3. Ler e Resumir E-mails
Após o login, aguarde o carregamento da caixa de entrada (`Destaques` / `Focused`).

**Seletores Úteis:**
-   Lista de E-mails: `div[role="listbox"]` ou elementos com `aria-label="Lista de Mensagens"`.
-   Item de E-mail: Geralmente `div` com `role="option"`.
-   Assunto: Buscar texto dentro do item com classes de título ou negrito.
-   Remetente: Buscar texto próximo ao ícone de contato.

**Lógica de Extração:**
-   Iterar sobre os primeiros 5-10 e-mails.
-   Identificar: Remetente, Assunto, Data (se visível) e Status (Lido/Não Lido).
-   Identificar e-mails fixados ou marcados como importantes.

### 4. Retorno
Retorne um resumo estruturado para o usuário:
-   **Importantes/Fixados**: [Lista]
-   **Recentes**: [Lista]
-   **Ação Sugerida**: (Ex: "Há um e-mail urgente de X").

## ⚠️ Tratamento de Erros
-   **Login Falhou**: Verificar se a senha mudou ou se há bloqueio de segurança.
-   **2FA**: Se o login exigir 2FA, a skill deve notificar o usuário e solicitar intervenção ou o código (se possível integrar).
-   **Mudança de Layout**: O Outlook muda classes frequentemente; prefira seletores por texto (`text=Entrar`) ou atributos estáveis (`role`, `aria-label`).

## Exemplo de Código (Browser Subagent Task)
```text
Navigate to https://outlook.live.com/owa/?nlp=1.
Log in using the provided credentials.
Handle the 'Run this time' or 'Stay signed in' prompts by selecting 'No'.
Wait for the inbox to load.
Scrape the subjects and senders of the top 5 emails in the 'Focused' tab.
Take a screenshot of the inbox.
Return a summary of the emails found.
```
