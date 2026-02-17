---
name: TP-Link EX141 WiFi Extractor
description: Extrai informações de rede WiFi (SSID, senha) de roteadores TP-Link modelo EX141.
version: 1.0.0
author: Yan Marcos
category: networking
tags: [router, wifi, extraction, tplink, ex141]
---

# TP-Link EX141 WiFi Extractor

Esta skill permite acessar a interface web de roteadores TP-Link EX141 e extrair as configurações de rede WiFi (SSID e senha) das frequências 2.4GHz e 5GHz.

## Pré-requisitos

- Acesso à rede do roteador.
- Credenciais de acesso ao painel web (URL e Senha).

## Procedimento

1.  **Acessar o Roteador**:
    - Abra o browser na URL fornecida (Ex: `http://100.96.1.101:8080/`).
    - Se necessário, insira a senha de login.

2.  **Navegar para Configurações**:
    - No menu lateral esquerdo, clique em **Básico**.
    - Em seguida, clique em **Wireless**.

3.  **Extrair Informações**:
    - **2.4GHz**:
        - SSID: Seletor `#ssid_2g`
        - Senha: Seletor `#wpa2PersonalPwd_2g`
    - **5GHz**:
        - SSID: Seletor `#ssid_5g`
        - Senha: Seletor `#wpa2PersonalPwd_5g`

4.  **Retornar Resultado**:
    - Os dados extraídos (SSID e Senha para ambas as frequências).

## Exemplo de Uso (Pseudo-código do Agente)

```javascript
// 1. Acessar e Login
browser.open({ url: "http://100.96.1.101:8080/" });
browser.type({ selector: "#pc-login-password", value: "@!G5adminispswm!@" }); // Se necessário
browser.click({ selector: "#pc-login-btn" });

// 2. Navegar
browser.click({ text: "Básico" });
browser.click({ text: "Wireless" }); // Pode precisar ser específico se houver ambiguidade

// 3. Extrair
const ssid2g = browser.get_attribute({ selector: "#ssid_2g", attribute: "value" });
const pass2g = browser.get_attribute({ selector: "#wpa2PersonalPwd_2g", attribute: "value" });

const ssid5g = browser.get_attribute({ selector: "#ssid_5g", attribute: "value" });
const pass5g = browser.get_attribute({ selector: "#wpa2PersonalPwd_5g", attribute: "value" });

return {
  "2.4GHz": { ssid: ssid2g, password: pass2g },
  "5GHz": { ssid: ssid5g, password: pass5g }
};
```
