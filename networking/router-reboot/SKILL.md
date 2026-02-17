---
name: Router Reboot
description: Reinicia roteadores através do painel de administração web de forma automatizada
version: 1.0.0
author: Yan Marcos
category: networking
tags: [router, reboot, restart, system-management, automation]
---

# Router Reboot Skill

Esta skill permite reiniciar roteadores através do painel de administração web, salvando as configurações e executando um reboot completo do sistema.

## Quando Usar

Use esta skill quando o usuário solicitar:
- Reiniciar o roteador
- Fazer reboot do sistema
- Aplicar configurações que requerem reinicialização
- Resolver problemas que necessitam de restart
- Limpar cache e reconectar serviços

## Informações Necessárias

Antes de executar, você precisa obter do usuário:
1. **IP do roteador** (ex: 192.168.1.1, 192.168.28.1)
2. **Usuário de administração**
3. **Senha de administração**
4. **Confirmação do usuário** - SEMPRE confirme antes de reiniciar!

## ⚠️ Avisos Importantes

1. **Desconexão Temporária**: O roteador ficará offline durante o reboot (geralmente 1-3 minutos)
2. **Perda de Conexão**: Todos os dispositivos conectados perderão conexão temporariamente
3. **Salvar Configurações**: Certifique-se de que todas as configurações foram salvas antes
4. **Confirmação Obrigatória**: SEMPRE confirme com o usuário antes de executar o reboot
5. **Horário Adequado**: Evite reiniciar em horários críticos ou durante transferências importantes

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

### Passo 3: Navegar até Commit/Reboot

#### Para Roteadores Datacom (DM986-204):

1. **Clicar no menu Administration:**
```javascript
await page.locator('text=Administration').click();
await page.waitForTimeout(2000);
```

2. **Clicar em System Management:**
```javascript
await page.locator('#side').getByRole('link', { name: 'System Management' }).click();
await page.waitForTimeout(2000);
```

3. **Clicar em Commit/Reboot:**
```javascript
await page.locator('#side').getByRole('link', { name: 'Commit/Reboot' }).click();
await page.waitForTimeout(2000);
```

### Passo 4: Executar o Reboot

1. **Tirar screenshot antes do reboot (documentação):**
```javascript
await page.screenshot({ path: 'before_reboot.png' });
```

2. **Clicar no botão "Commit and Reboot":**
```javascript
// Método 1: Usando locator
const frame = page.frame({ name: 'contentIframe' });
await frame.getByRole('button', { name: 'Commit and Reboot' }).click();

// Método 2: Usando JavaScript (mais confiável)
await frame.evaluate(() => {
  document.querySelector('input[value="Commit and Reboot"]').click();
});
```

3. **Confirmar o diálogo de confirmação:**
```javascript
// O navegador mostrará um alert/confirm
// Aguardar e aceitar
await page.waitForTimeout(1000);

// Se houver diálogo do navegador, aceitar
page.on('dialog', async dialog => {
  console.log('Dialog message:', dialog.message());
  await dialog.accept();
});
```

### Passo 5: Aguardar o Reboot

1. **Aguardar o roteador reiniciar:**
```javascript
// Aguardar 60-120 segundos para o reboot completo
await page.waitForTimeout(90000); // 90 segundos
```

2. **Verificar se o roteador voltou online:**
```javascript
// Tentar acessar novamente
try {
  await page.goto('http://[IP_ROTEADOR]', { timeout: 30000 });
  console.log('Roteador voltou online!');
} catch (error) {
  console.log('Roteador ainda reiniciando, aguardando mais...');
  await page.waitForTimeout(30000);
  await page.goto('http://[IP_ROTEADOR]');
}
```

## Template de Código Completo

```javascript
async (page) => {
  // 1. Navegar até o roteador
  await page.goto('http://192.168.28.1');
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
  
  // 3. Navegar para Administration > System Management > Commit/Reboot
  await page.locator('text=Administration').click();
  await page.waitForTimeout(2000);
  
  await page.locator('#side').getByRole('link', { name: 'System Management' }).click();
  await page.waitForTimeout(2000);
  
  await page.locator('#side').getByRole('link', { name: 'Commit/Reboot' }).click();
  await page.waitForTimeout(2000);
  
  // 4. Screenshot antes do reboot
  await page.screenshot({ path: 'before_reboot.png' });
  
  // 5. Executar reboot
  const frame = page.frame({ name: 'contentIframe' });
  
  // Configurar handler para diálogo de confirmação
  page.on('dialog', async dialog => {
    console.log('Confirmando reboot:', dialog.message());
    await dialog.accept();
  });
  
  // Clicar no botão de reboot
  await frame.evaluate(() => {
    document.querySelector('input[value="Commit and Reboot"]').click();
  });
  
  // 6. Aguardar reboot (90 segundos)
  console.log('Aguardando reboot do roteador...');
  await page.waitForTimeout(90000);
  
  // 7. Verificar se voltou online
  try {
    await page.goto('http://192.168.28.1', { timeout: 30000 });
    console.log('Roteador reiniciado com sucesso!');
    return { 
      success: true, 
      message: 'Roteador reiniciado e voltou online'
    };
  } catch (error) {
    console.log('Aguardando mais tempo...');
    await page.waitForTimeout(30000);
    await page.goto('http://192.168.28.1');
    return { 
      success: true, 
      message: 'Roteador reiniciado (tempo estendido)'
    };
  }
}
```

## Navegação por Modelo de Roteador

### Datacom (DM986-204)
- **Caminho:** Administration > System Management > Commit/Reboot
- **Menu Administration:** `text=Administration`
- **System Management:** `#side >> link[text="System Management"]`
- **Commit/Reboot:** `#side >> link[text="Commit/Reboot"]`
- **Botão Reboot:** `input[value="Commit and Reboot"]` (dentro do iframe `contentIframe`)
- **Tempo de Reboot:** ~60-90 segundos

### TP-Link
- **Caminho:** System Tools > Reboot
- **Menu System Tools:** `#menu >> link[text="System Tools"]`
- **Reboot:** `link[text="Reboot"]`
- **Botão Reboot:** `button[text="Reboot"]` ou `input[value="Reboot"]`
- **Tempo de Reboot:** ~30-60 segundos

### D-Link
- **Caminho:** Tools > System > Reboot
- **Menu Tools:** `link[text="Tools"]`
- **System:** `link[text="System"]`
- **Botão Reboot:** `button[text="Reboot"]`
- **Tempo de Reboot:** ~45-90 segundos

### Intelbras
- **Caminho:** Manutenção > Reiniciar
- **Menu Manutenção:** `link[text="Manutenção"]`
- **Reiniciar:** `link[text="Reiniciar"]`
- **Botão Reiniciar:** `button[text="Reiniciar"]`
- **Tempo de Reboot:** ~60 segundos

## Dicas Importantes

### 1. Trabalhar com iframes
Muitos roteadores usam iframes para o conteúdo principal:
```javascript
const frame = page.frame({ name: 'contentIframe' });
// ou
const frame = page.frameLocator('iframe[name="contentIframe"]');
```

### 2. Lidar com diálogos de confirmação
```javascript
// Configurar antes de clicar no botão
page.on('dialog', async dialog => {
  console.log('Dialog:', dialog.message());
  await dialog.accept(); // ou dialog.dismiss() para cancelar
});
```

### 3. Tempo de espera adequado
```javascript
// Aguardar tempo suficiente para reboot completo
await page.waitForTimeout(90000); // 90 segundos é seguro

// Para roteadores mais rápidos
await page.waitForTimeout(60000); // 60 segundos
```

### 4. Verificar se voltou online
```javascript
// Tentar múltiplas vezes
let online = false;
for (let i = 0; i < 5; i++) {
  try {
    await page.goto('http://192.168.28.1', { timeout: 10000 });
    online = true;
    break;
  } catch (error) {
    console.log(`Tentativa ${i+1}/5 falhou, aguardando...`);
    await page.waitForTimeout(15000);
  }
}
```

### 5. Salvar configurações antes do reboot
```javascript
// Alguns roteadores têm botão "Commit" separado
// Sempre salvar antes de reiniciar
await frame.getByRole('button', { name: 'Save' }).click();
await page.waitForTimeout(2000);
```

## Troubleshooting

### Problema: Diálogo de confirmação não aparece
**Solução:** Use JavaScript diretamente para clicar no botão:
```javascript
await frame.evaluate(() => {
  const rebootBtn = document.querySelector('input[value="Commit and Reboot"]');
  if (rebootBtn) rebootBtn.click();
});
```

### Problema: Roteador não volta online
**Solução:** Aguarde mais tempo e tente novamente:
```javascript
// Aguardar até 3 minutos
await page.waitForTimeout(180000);
```

### Problema: Conexão perdida durante reboot
**Solução:** Isso é esperado! Aguarde e reconecte:
```javascript
try {
  await page.goto('http://192.168.28.1');
} catch (error) {
  // Esperado durante reboot
  await page.waitForTimeout(60000);
  await page.goto('http://192.168.28.1');
}
```

### Problema: Precisa fazer login novamente
**Solução:** Implemente login automático após reboot:
```javascript
// Após roteador voltar online
await page.waitForTimeout(3000);
const needsLogin = await page.locator('#username').count() > 0;
if (needsLogin) {
  // Fazer login novamente
}
```

## Notas de Segurança

1. **Sempre confirme com o usuário** antes de executar o reboot
2. **Avise sobre desconexão** - todos os dispositivos perderão conexão
3. **Horário adequado** - evite horários de pico ou trabalho crítico
4. **Salve configurações** - certifique-se de que tudo foi salvo
5. **Backup** - considere fazer backup antes de reiniciar
6. **Documentação** - tire screenshots antes e depois
7. **Tempo de espera** - não tente reconectar muito cedo

## Exemplo de Uso Completo

```javascript
// Reiniciar roteador Datacom
const result = await page.evaluate(async () => {
  const config = {
    ip: '192.168.28.1',
    user: 'user',
    password: 'admin123',
    rebootWaitTime: 90000 // 90 segundos
  };
  
  // Implementar lógica aqui
  // ...
  
  return {
    success: true,
    message: 'Roteador reiniciado com sucesso',
    downtime: '90 segundos'
  };
});
```

## Checklist de Execução

- [ ] Obter credenciais de administração do roteador
- [ ] Obter IP do roteador
- [ ] **CONFIRMAR COM O USUÁRIO** que pode reiniciar
- [ ] Verificar se não há processos críticos em andamento
- [ ] Avisar usuário sobre desconexão temporária
- [ ] Acessar roteador via navegador
- [ ] Fazer login
- [ ] Navegar até página de reboot
- [ ] Tirar screenshot de documentação
- [ ] Executar reboot
- [ ] Confirmar diálogo de confirmação
- [ ] Aguardar tempo adequado (60-120 segundos)
- [ ] Verificar se roteador voltou online
- [ ] Fazer login novamente (se necessário)
- [ ] Confirmar que serviços estão funcionando
- [ ] Informar usuário sobre sucesso
- [ ] Documentar tempo de downtime

## Tempo Estimado de Execução

- **Navegação até página de reboot:** 10-15 segundos
- **Execução do reboot:** 1-2 segundos
- **Downtime do roteador:** 60-120 segundos
- **Verificação de retorno:** 10-30 segundos
- **Total:** ~2-3 minutos

## Compatibilidade

- ✅ Datacom DM986-204
- ✅ TP-Link (modelos genéricos)
- ✅ D-Link (modelos genéricos)
- ✅ Intelbras (modelos genéricos)
- ⚠️ Outros modelos podem ter caminhos diferentes

---

**Criado:** 2026-02-16  
**Versão:** 1.0.0  
**Autor:** Yan Marcos  
**Licença:** MIT
