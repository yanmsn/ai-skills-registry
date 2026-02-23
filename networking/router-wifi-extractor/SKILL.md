---
name: Router WiFi Extractor
description: Acessa painéis de administração de roteadores e extrai informações de WiFi (SSID e senhas) de forma automatizada
---

# Router WiFi Extractor Skill

Esta skill permite acessar roteadores via navegador e extrair informações de redes WiFi de forma rápida e eficiente.

## Quando Usar

Use esta skill quando o usuário solicitar:
- Verificar nome e senha de redes WiFi em um roteador
- Acessar painel de administração de roteadores
- Extrair configurações de redes wireless

## Informações Necessárias

Antes de executar, você precisa obter do usuário:
1. **IP do roteador** (ex: 192.168.1.1, 192.168.0.1, 192.168.0.1)
2. **Usuário de administração** (ex: admin, user)
3. **Senha de administração**

## Processo de Execução

### Passo 1: Preparar o Ambiente

Se houver erro relacionado à variável `$HOME` no Playwright:
```powershell
[System.Environment]::SetEnvironmentVariable('HOME', $env:USERPROFILE, 'User')
```

### Passo 2: Acessar o Roteador

Use o browser_subagent com a seguinte estrutura de task:

```
Navigate to the router admin panel at [IP], login, and extract WiFi information.

Steps:
1. Navigate to http://[IP]
2. Wait 3 seconds for page load
3. Use JavaScript to fill login form and submit:
   - document.getElementById('username').value = '[USER]'
   - document.getElementById('password').value = '[PASSWORD]'
   - Click login button or use .submit()
4. Wait 5 seconds for dashboard to load
5. Navigate to WiFi/WLAN settings (look for menu items: "Network", "WiFi", "WLAN", "Wireless")
6. Access both 2.4GHz and 5GHz settings if available
7. For each network, go to Security settings
8. Use JavaScript to extract password directly from input field value

Return:
- Network Name (SSID) for each band
- Password for each band
- Security type
```

### Passo 2-B: Roteadores Datacom (DM986-204) — MÉTODO RECOMENDADO (PowerShell)

Para este modelo específico, utilize o script PowerShell para uma extração instantânea e sem necessidade de navegador:

1. **Localizar o script:** `scripts\get-wifi.ps1`
2. **Executar via run_command:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File "scripts\get-wifi.ps1" -IP [IP] -User [USER] -Pass [PASSWORD]
```

### Passo 3: Extrair Senhas com JavaScript (Outros Modelos)

**Técnica Importante:** Senhas geralmente aparecem ocultas (como pontos) na interface, mas o valor real está no campo de input. Use JavaScript para extrair:

```javascript
// Buscar em documento principal
const findInDocument = (doc) => {
  const el = doc.getElementById('wpapsk') || 
             doc.querySelector('input[id*="psk"]') || 
             doc.querySelector('input[name*="psk"]') ||
             doc.querySelector('input[type="password"]');
  return el ? el.value : null;
};

// Buscar também em iframes se necessário
let value = findInDocument(document);
if (!value) {
  const iframes = Array.from(document.querySelectorAll('iframe'));
  for (let iframe of iframes) {
    try {
      value = findInDocument(iframe.contentDocument);
      if (value) break;
    } catch (e) {}
  }
}
return value;
```

### Passo 4: Verificar Resultados

Sempre verifique a saída do JavaScript executado pelo subagent. Os valores extraídos aparecerão nos steps de `execute_browser_javascript` com status `DONE`.

## Modelos de Roteadores Comuns

### Datacom (DM986-204)
- **Estrutura de Menu:** Network > WLAN_2.4G / WLAN_5G > Security
- **Campo de Senha:** ID `wpapsk` ou similar
- **Login:** Geralmente via JavaScript no formulário

### TP-Link
- **Estrutura de Menu:** Wireless > Wireless Security
- **Campo de Senha:** Nome `psk` ou `wireless_psk`

### D-Link
- **Estrutura de Menu:** Setup > Wireless Settings
- **Campo de Senha:** ID `wpa_pass_phrase`

### Intelbras
- **Estrutura de Menu:** Rede sem fio > Segurança
- **Campo de Senha:** Nome `wpa_key`

## Dicas de Troubleshooting

1. **Erro de $HOME não definido:**
   - Configure a variável de ambiente antes de usar o Playwright
   - Use: `[System.Environment]::SetEnvironmentVariable('HOME', $env:USERPROFILE, 'User')`

2. **Login não funciona com clicks:**
   - Use JavaScript para preencher e submeter o formulário
   - Mais confiável que simular clicks de mouse

3. **Senha não aparece revelada:**
   - NUNCA confie em screenshots para senhas
   - SEMPRE use JavaScript para extrair o valor do input field
   - O valor real está em `element.value`, não no que é exibido

4. **Estrutura de página desconhecida:**
   - Use `browser_get_dom` para explorar a estrutura
   - Procure por termos: "wifi", "wlan", "wireless", "rede sem fio"
   - Senhas geralmente estão em: "security", "segurança", "senha"

## Template Rápido

Para uso rápido, use este template com browser_subagent:

**TaskName:** "Extracting Router WiFi Credentials"

**Task:**
```
Access router at http://[IP], login with user=[USER] and password=[PASSWORD].
Navigate to WiFi settings, extract SSID and passwords for all networks using JavaScript.
Return: Network names and passwords clearly listed.
```

**RecordingName:** "router_wifi_extraction"

## Exemplo de Saída Esperada

```
Rede 2.4GHz:
- Nome (SSID): MinhaRede
- Senha: SenhaSegura123
- Segurança: WPA2

Rede 5GHz:
- Nome (SSID): MinhaRede-5G
- Senha: SenhaSegura5G
- Segurança: WPA2
```

## Notas de Segurança

- Sempre confirme que o usuário tem autorização para acessar o roteador
- Não armazene credenciais de administração
- Lembre o usuário de manter senhas WiFi seguras
