---
name: Router WiFi Configurator
description: Altera configurações de redes WiFi em roteadores (SSID, senha, segurança) de forma automatizada
---

# Router WiFi Configurator Skill

Esta skill permite modificar configurações de redes WiFi em roteadores através do painel de administração web, incluindo alteração de SSID (nome da rede) e senha.

## Quando Usar

Use esta skill quando o usuário solicitar:
- Alterar nome (SSID) de rede WiFi
- Alterar senha de rede WiFi
- Modificar configurações de segurança WiFi
- Configurar redes 2.4GHz ou 5GHz

## Informações Necessárias

Antes de executar, você precisa obter do usuário:
1. **IP do roteador** (ex: 192.168.1.1, 192.168.0.1)
2. **Usuário de administração**
3. **Senha de administração**
4. **Banda a ser configurada** (2.4GHz ou 5GHz)
5. **Novo SSID** (nome da rede)
6. **Nova senha WiFi**

## Processo de Execução Completo

### Passo 1: Acessar o Roteador

Use o Playwright MCP para navegar até o roteador:

```javascript
await page.goto('http://[IP_ROTEADOR]');
```

### Passo 2: Fazer Login (se necessário)

Se o roteador não estiver logado, use JavaScript para fazer login:

```javascript
await page.evaluate(() => {
  document.getElementById('username').value = '[USUARIO]';
  document.getElementById('password').value = '[SENHA]';
  document.querySelector('.loginBtn').click();
});
await page.waitForTimeout(5000);
```

### Passo 3: Navegar até Configurações WiFi

#### Para Roteadores Datacom (DM986-204):

1. **Clicar no menu Network:**
```javascript
await page.locator('link[text="Network"]').click();
```

#### Roteadores Datacom (DM986-204) — MÉTODO RECOMENDADO (PowerShell):

Para este modelo, utilize o script PowerShell que permite alterar SSID e senha de ambas as bandas simultaneamente ou individualmente, de forma muito mais confiável:

1. **Localizar o script:** `scripts\set-wifi.ps1`
2. **Executar via run_command:**
```powershell
# Alterar SSID e senha de ambas as bandas
powershell.exe -ExecutionPolicy Bypass -File "scripts\set-wifi.ps1" -IP [IP] -User [USER] -Pass [PASSWORD] -SSID24 "[NOVO_SSID_24]" -SSID5 "[NOVO_SSID_5]" -Senha24 "[NOVA_SENHA_24]" -Senha5 "[NOVA_SENHA_5]"

# Alterar apenas o que for necessário (parâmetros omitidos mantêm o valor atual)
powershell.exe -ExecutionPolicy Bypass -File "scripts\set-wifi.ps1" -IP [IP] -User [USER] -Pass [PASSWORD] -SSID24 "MinhaRede" -Senha24 "NovaSenha123"
```

#### Outros Modelos (Navegação Manual):

2. **Selecionar a banda WiFi:**
   - Para 2.4GHz: Clicar em "WLAN_2.4G"
   - Para 5GHz: Clicar em "WLAN_5G"

```javascript
// Para 2.4GHz
await page.locator('#side').getByRole('link', { name: 'WLAN_2.4G' }).click();

// Para 5GHz
await page.locator('#side').getByRole('link', { name: 'WLAN_5G' }).click();
```

### Passo 4: Alterar o SSID (Nome da Rede)

1. **Clicar em "Basic Settings":**
```javascript
await page.locator('#side').getByRole('link', { name: 'Basic Settings' }).click();
await page.waitForTimeout(2000);
```

2. **Alterar o SSID usando JavaScript:**
```javascript
const frame = page.frame({ name: 'contentIframe' });
await frame.locator('input[name="ssid"]').fill('[NOVO_SSID]');
```

3. **Aplicar as mudanças:**
```javascript
await frame.getByRole('button', { name: 'Apply Changes' }).click();
await page.waitForTimeout(3000);
```

### Passo 5: Alterar a Senha WiFi

1. **Clicar em "Security":**
```javascript
await page.locator('#side').getByRole('link', { name: 'Security' }).click();
await page.waitForTimeout(2000);
```

2. **Alterar a senha usando JavaScript:**
```javascript
const frame = page.frame({ name: 'contentIframe' });

// Encontrar o campo de senha (pode variar por modelo)
const passwordField = await frame.locator('input[name*="psk"]').first();
// ou
const passwordField = await frame.locator('#wpapsk');

await passwordField.fill('[NOVA_SENHA]');
```

3. **Aplicar as mudanças:**
```javascript
await frame.getByRole('button', { name: 'Apply Changes' }).click();
await page.waitForTimeout(3000);
```

### Passo 6: Verificar as Alterações

1. **Verificar SSID:**
```javascript
const frame = page.frame({ name: 'contentIframe' });
const ssidValue = await frame.locator('input[name="ssid"]').inputValue();
console.log('SSID atual:', ssidValue);
```

2. **Verificar senha (revelando o campo):**
```javascript
const frame = page.frame({ name: 'contentIframe' });

// Marcar checkbox "Show Password" se disponível
await frame.getByRole('checkbox', { name: /show password/i }).click();

// Ler o valor
const passwordValue = await frame.locator('input[name*="psk"]').inputValue();
console.log('Senha atual:', passwordValue);
```

3. **Tirar screenshots para documentação:**
```javascript
await page.screenshot({ path: 'wifi_ssid_configured.png' });
```

## Template de Código Completo

```javascript
async (page) => {
  // 1. Navegar até o roteador
  await page.goto('http://192.168.0.1');
  await page.waitForTimeout(3000);
  
  // 2. Login (se necessário)
  const needsLogin = await page.locator('#username').count() > 0;
  if (needsLogin) {
    await page.evaluate(() => {
      document.getElementById('username').value = 'user';
      document.getElementById('password').value = 'senha';
      document.querySelector('.loginBtn').click();
    });
    await page.waitForTimeout(5000);
  }
  
  // 3. Navegar para Network > WLAN_2.4G
  await page.locator('link[text="Network"]').click();
  await page.waitForTimeout(2000);
  await page.locator('#side').getByRole('link', { name: 'WLAN_2.4G' }).click();
  await page.waitForTimeout(2000);
  
  // 4. Alterar SSID
  await page.locator('#side').getByRole('link', { name: 'Basic Settings' }).click();
  await page.waitForTimeout(2000);
  
  const frame = page.frame({ name: 'contentIframe' });
  await frame.locator('input[name="ssid"]').fill('NOVO-SSID');
  await frame.getByRole('button', { name: 'Apply Changes' }).click();
  await page.waitForTimeout(3000);
  
  // 5. Alterar Senha
  await page.locator('#side').getByRole('link', { name: 'Security' }).click();
  await page.waitForTimeout(2000);
  
  await frame.locator('input[name*="psk"]').first().fill('NovaSenha123');
  await frame.getByRole('button', { name: 'Apply Changes' }).click();
  await page.waitForTimeout(3000);
  
  // 6. Verificar
  const ssid = await frame.locator('input[name="ssid"]').inputValue();
  
  return { 
    success: true, 
    ssid: ssid,
    message: 'Configurações WiFi alteradas com sucesso'
  };
}
```

## Seletores Comuns por Modelo de Roteador

### Datacom (DM986-204)
- **Menu Network:** `link[text="Network"]`
- **WLAN 2.4G:** `#side >> link[text="WLAN_2.4G"]`
- **WLAN 5G:** `#side >> link[text="WLAN_5G"]`
- **Basic Settings:** `#side >> link[text="Basic Settings"]`
- **Security:** `#side >> link[text="Security"]`
- **SSID Input:** `input[name="ssid"]` (dentro do iframe `contentIframe`)
- **Password Input:** `input[name*="psk"]` ou `#wpapsk` (dentro do iframe)
- **Apply Button:** `button[text="Apply Changes"]`
- **Show Password:** `checkbox` com label "Show Password"

### TP-Link
- **Menu Wireless:** `#menu >> link[text="Wireless"]`
- **Wireless Settings:** `link[text="Wireless Settings"]`
- **Wireless Security:** `link[text="Wireless Security"]`
- **SSID Input:** `input[name="ssid"]`
- **Password Input:** `input[name="psk"]`
- **Save Button:** `button[type="submit"]` ou `input[value="Save"]`

### D-Link
- **Menu Setup:** `link[text="Setup"]`
- **Wireless Settings:** `link[text="Wireless Settings"]`
- **SSID Input:** `input[name="ssid"]`
- **Password Input:** `input[name="wpa_pass_phrase"]`
- **Save Button:** `button[text="Save Settings"]`

## Dicas Importantes

### 1. Trabalhar com iframes
Muitos roteadores usam iframes para o conteúdo principal:
```javascript
const frame = page.frame({ name: 'contentIframe' });
// ou
const frame = page.frameLocator('iframe[name="contentIframe"]');
```

### 2. Aguardar carregamento
Sempre aguarde após navegação e após clicar em "Apply Changes":
```javascript
await page.waitForTimeout(2000-3000);
```

### 3. Verificar se mudanças foram aplicadas
Sempre leia os valores dos campos após aplicar mudanças para confirmar:
```javascript
const currentValue = await input.inputValue();
```

### 4. Screenshots para documentação
Tire screenshots antes e depois das mudanças:
```javascript
await page.screenshot({ path: 'before_change.png' });
// ... fazer mudanças ...
await page.screenshot({ path: 'after_change.png' });
```

### 5. Revelar senhas ocultas
Use JavaScript ou checkbox "Show Password" para revelar senhas:
```javascript
// Método 1: Checkbox
await frame.getByRole('checkbox', { name: /show password/i }).click();

// Método 2: Alterar tipo do input
await frame.evaluate(() => {
  document.querySelector('input[type="password"]').type = 'text';
});
```

## Troubleshooting

### Problema: Mudanças não são salvas
**Solução:** Certifique-se de clicar em "Apply Changes" e aguardar o tempo suficiente para o roteador processar.

### Problema: Não encontra o campo de senha
**Solução:** Use seletores mais genéricos:
```javascript
// Tentar múltiplos seletores
const passwordField = await frame.locator('input[type="password"]').first()
  || await frame.locator('input[name*="psk"]').first()
  || await frame.locator('input[name*="key"]').first()
  || await frame.locator('#wpapsk');
```

### Problema: Iframe não carrega
**Solução:** Aguarde o iframe estar pronto:
```javascript
await page.waitForSelector('iframe[name="contentIframe"]');
const frame = page.frame({ name: 'contentIframe' });
await frame.waitForLoadState('load');
```

### Problema: Roteador requer reboot
**Solução:** Alguns roteadores exigem reinicialização. Procure por mensagem ou botão de reboot:
```javascript
const rebootNeeded = await page.locator('text=/reboot|reiniciar/i').count() > 0;
if (rebootNeeded) {
  console.log('Atenção: Roteador pode precisar de reinicialização');
}
```

## Notas de Segurança

1. **Sempre confirme com o usuário** antes de aplicar mudanças
2. **Documente as configurações antigas** antes de alterar
3. **Avise sobre possível desconexão** - alterar WiFi pode desconectar dispositivos
4. **Senhas fortes** - Recomende senhas com pelo menos 12 caracteres
5. **Backup** - Sugira fazer backup das configurações do roteador antes de mudanças significativas

## Exemplo de Uso Completo

```javascript
// Configurar WiFi 2.4GHz no roteador Datacom
const result = await page.evaluate(async () => {
  const config = {
    ip: '192.168.0.1',
    user: 'user',
    password: 'admin123',
    band: '2.4G',
    newSSID: 'GEMINI-2G',
    newPassword: 'Gemini-WLAN-26'
  };
  
  // Implementar lógica aqui
  // ...
  
  return {
    success: true,
    ssid: config.newSSID,
    message: 'WiFi configurado com sucesso'
  };
});
```

## Checklist de Execução

- [ ] Obter credenciais de administração do roteador
- [ ] Obter IP do roteador
- [ ] Confirmar banda a ser configurada (2.4GHz ou 5GHz)
- [ ] Obter novo SSID desejado
- [ ] Obter nova senha desejada
- [ ] Acessar roteador via navegador
- [ ] Fazer login
- [ ] Navegar até configurações WiFi
- [ ] Alterar SSID
- [ ] Aplicar mudanças de SSID
- [ ] Alterar senha
- [ ] Aplicar mudanças de senha
- [ ] Verificar configurações aplicadas
- [ ] Tirar screenshots de confirmação
- [ ] Informar usuário sobre sucesso
- [ ] Avisar sobre possível necessidade de reconexão de dispositivos
