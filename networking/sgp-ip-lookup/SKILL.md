---
name: SGP IP Lookup
description: Consulta o cadastro de um cliente no sistema SGP e identifica o endereço IP do roteador.
version: 1.0.0
author: Yan Marcos
category: networking
tags: [sgp, ip, lookup, router, customer]
---

# SGP IP Lookup Skill

Esta skill permite localizar o endereço IP do roteador de um cliente no sistema SGP.

## Pré-requisitos

- Acesso ao sistema SGP (Credenciais em `Passwords/SGP TSMX.md`).
- MCP `obsidian` para ler credenciais.
- MCP `browser` para acessar o sistema.

## Procedimento

1.  **Obter Credenciais**:
    - Utilize a skill `Secure Credential Access` ou leia diretamente a nota `Passwords/SGP TSMX.md` usando `obsidian.read_note`.
    - Extraia `url`, `username` e `password`.

2.  **Acessar o SGP**:
    - Abra o browser na URL do SGP.
    - Faça login com as credenciais obtidas.

3.  **Buscar Cliente**:
    - Localize o campo de pesquisa (topo da página ou menu lateral).
    - Digite o nome do cliente fornecido.
    - Aguarde os resultados e clique no cliente correto.

4.  **Localizar IP do Roteador**:
    - No painel do cliente, navegue para a aba **Contratos**.
    - Selecione o contrato **Ativo** (geralmente destacado).
    - Vá para a aba ou seção **Informações técnicas**.
    - Localize o campo **IP** ou **Endereço IP**.

5.  **Salvar Credencial**:
    - Crie uma nova nota em `Passwords/` com o nome `Router - <Nome do Cliente>.md`.
    - Use o seguinte template para o frontmatter:
      ```yaml
      ---
      service: Router - <Nome do Cliente>
      username: user
      password: "admin-password"
      url: http://<IP_ENCONTRADO>:8080
      ---
      ```
    - Utilize a ferramenta `obsidian.write_note` (se disponível) ou `write_to_file` no caminho `Documents/ObsidianVault/Passwords/`.

6.  **Retornar Resultado**:
    - O endereço IP encontrado e a confirmação de que a credencial foi salva.

## Exemplo de Uso (Pseudo-código do Agente)

```javascript
// 1. Ler credenciais
const credentials = obsidian.read_note({ path: "Passwords/SGP TSMX.md" });
const { username, password, url } = credentials.fm;

// 2. Login
browser.open({ url: url });
browser.type({ selector: "#login-user", value: username });
browser.type({ selector: "#login-pass", value: password });
browser.click({ selector: "#btn-login" });

// 3. Buscar
browser.type({ selector: ".search-bar", value: "Nome do Cliente" });
browser.click({ selector: ".search-result-item:first-child" });

// 4. Navegar
browser.click({ text: "Contratos" });
browser.click({ text: "Ativo" }); // Selecionar contrato ativo
browser.click({ text: "Informações técnicas" });

// 5. Extrair IP
const ip = browser.get_text({ selector: ".ip-address-field" });

// 6. Salvar Credencial
const clientName = "Nome do Cliente"; // Obtido anteriormente
const noteContent = `---
service: Router - ${clientName}
username: user
password: "admin-password"
url: http://${ip}:8080
---
# Router Credentials for ${clientName}
`;

// Opção A: Usando obsidian tool (se existir)
// obsidian.write_note({ path: `Passwords/Router - ${clientName}.md`, content: noteContent });

// Opção B: Escrevendo diretamente no sistema de arquivos (caminho padrão do vault)
const vaultPath = "C:/Users/Yan Marcos/Documents/ObsidianVault/Passwords";
write_to_file({
  TargetFile: `${vaultPath}/Router - ${clientName}.md`,
  CodeContent: noteContent,
  Overwrite: true
});

return ip;
```

> [!NOTE]
> Os seletores CSS acima são ilustrativos. O agente deve inspecionar a página para determinar os seletores corretos durante a execução.
