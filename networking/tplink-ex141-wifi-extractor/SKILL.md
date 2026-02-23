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

## Exemplo de Uso (Abordagem Otimizada - JavaScript Puro)

**Esta abordagem é MUITO mais rápida pois não usa capturas de tela.**

```javascript
// 1. Acessar e Login (usando JavaScript para máxima velocidade)
browser.open({ url: "http://100.96.1.101:8080/" });
browser.execute_javascript({
  code: `
    document.getElementById('pc-login-password').value = 'admin-password';
    document.getElementById('pc-login-btn').click();
  `
});

// 2. Aguardar login (pequeno delay)
wait(2000);

// 3. Navegar e Extrair (tudo em um único comando JavaScript)
const result = browser.execute_javascript({
  code: `
    // Navegar para Básico > Wireless
    const basicTab = Array.from(document.querySelectorAll('li, span, a'))
      .find(el => el.textContent.includes('Básico'));
    if (basicTab) basicTab.click();
    
    setTimeout(() => {
      const wirelessMenu = Array.from(document.querySelectorAll('li, span, a'))
        .find(el => el.textContent.includes('Wireless'));
      if (wirelessMenu) wirelessMenu.click();
    }, 500);
    
    // Aguardar carregamento e extrair dados
    setTimeout(() => {
      return {
        "2.4GHz": {
          ssid: document.getElementById('ssid_2g')?.value || '',
          password: document.getElementById('wpa2PersonalPwd_2g')?.value || ''
        },
        "5GHz": {
          ssid: document.getElementById('ssid_5g')?.value || '',
          password: document.getElementById('wpa2PersonalPwd_5g')?.value || ''
        }
      };
    }, 1000);
  `
});

return result;
```

## Abordagem Alternativa (Ainda Mais Simples)

Se você já estiver na página de Wireless, pode extrair tudo em uma única linha:

```javascript
browser.execute_javascript({
  code: `({
    "2.4GHz": {
      ssid: document.getElementById('ssid_2g')?.value,
      password: document.getElementById('wpa2PersonalPwd_2g')?.value
    },
    "5GHz": {
      ssid: document.getElementById('ssid_5g')?.value,
      password: document.getElementById('wpa2PersonalPwd_5g')?.value
    }
  })`
});
```

## Vantagens da Abordagem JavaScript

- ⚡ **10-20x mais rápido** que usar capturas de tela
- 🎯 **Mais confiável** - não depende de posição de elementos na tela
- 🔧 **Mais robusto** - funciona mesmo se o layout mudar ligeiramente
- 💾 **Menos recursos** - não precisa processar imagens

