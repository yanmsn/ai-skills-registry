---
name: Router WAN Configurator
description: Configura a conexão WAN do roteador (PPPoE, IPoE, Bridge) de forma automatizada
version: 1.0.0
author: Yan Marcos
category: networking
tags: [router, wan, pppoe, vlan, internet, configuration]
---

# Router WAN Configurator Skill

Esta skill permite configurar a conexão WAN de roteadores, especificamente focada em conexões PPPoE com VLAN, comum em provedores de internet fibra óptica (FTTH).

## Quando Usar

Use esta skill quando precisar:
- Configurar uma nova conexão de internet
- Alterar credenciais PPPoE (usuário/senha)
- Alterar ID da VLAN
- Mudar o tipo de conexão (Bridge, IPoE, PPPoE)

## Informações Necessárias

Antes de executar, obtenha do usuário:
1. **IP do roteador** e credenciais de acesso
2. **VLAN ID** (ex: 2603)
3. **Tipo de Conexão** (ex: PPPoE)
4. **Usuário PPPoE** (ex: cliente@provedor.com.br)
5. **Senha PPPoE**
6. **Tipo de Serviço** (ex: INTERNET, TR069, INTERNET_TR069)

## ⚠️ Avisos Importantes

1. **Perda de Conexão**: Alterar configurações WAN irá desconectar a internet temporariamente.
2. **Credenciais Corretas**: Errar o usuário/senha PPPoE ou a VLAN deixará o cliente sem internet.
3. **Múltiplas Interfaces**: Roteadores podem ter múltiplas interfaces WAN. Esta skill foca na edição da interface padrão.

## Processo de Execução (Datacom DM986-204)

### Método 1: PowerShell (MÉTODO RECOMENDADO)

Para o modelo Datacom DM986-204, utilize o script PowerShell para uma configuração determinística e instantânea, que lida automaticamente com a complexidade do `postSecurityFlag` e codificação Base64.

1. **Localizar o script:** `scripts\set-wan.ps1`
2. **Executar via run_command:**
```powershell
# Alterar VLAN ID e credenciais PPPoE
powershell.exe -ExecutionPolicy Bypass -File "scripts\set-wan.ps1" -IP [IP] -User [USER] -Pass [PASSWORD] -VlanID [ID] -PPPoEUser "[USUARIO]" -PPPoEPass "[SENHA]"

# Alterar somente o que for necessário (parâmetros omitidos mantêm o valor atual no roteador)
powershell.exe -ExecutionPolicy Bypass -File "scripts\set-wan.ps1" -IP [IP] -User [USER] -Pass [PASSWORD] -VlanID 2603
```

### Método 2: Navegação Manual (Playwright)

### Passo 1: Acessar Configuração WAN

1. Navegar para `http://[IP_ROTEADOR]/multi_wan_generic.asp` (caminho direto)
   OU
   Navegar via menu: `Network` > `WAN` > `WAN Connection`

```javascript
// Método robusto via menu
await page.getByRole('link', { name: 'Network', exact: true }).click();
await page.waitForTimeout(2000);
await page.getByRole('link', { name: 'WAN Connection', exact: true }).click();
await page.waitForTimeout(2000);
```

### Passo 2: Configurar Campos no Iframe

O formulário geralmente está dentro de um iframe chamado `contentIframe`.

```javascript
const frame = page.frame({ name: 'contentIframe' });

// 1. Configurar VLAN
// Ativar checkbox de VLAN se necessário
const vlanCheckbox = frame.locator('input[name="vlan"]');
if (await vlanCheckbox.isChecked() === false) {
    await vlanCheckbox.check();
}

// Definir ID da VLAN
await frame.locator('input[name="vid"]').fill('2603');

// 2. Configurar Channel Mode (PPPoE)
// Value 2 = PPPoE
await frame.locator('select[name="adslConnectionMode"]').selectOption({ value: '2' }); // ou label: 'PPPoE'

// 3. Configurar Connection Type (INTERNET)
// Value 2 = INTERNET
await frame.locator('select[name="ctype"]').selectOption({ label: 'INTERNET' });

// 4. Configurar Credenciais PPPoE
await frame.locator('input[name="pppUserName"]').fill('yan.marcos@g5fibra');
await frame.locator('input[name="pppPassword"]').fill('yan.marcos');
```

### Passo 3: Aplicar Mudanças

```javascript
await frame.locator('input[name="apply"]').click();
```

### Passo 4: Verificar Conexão

Após aplicar, aguarde e verifique se a conexão subiu (status UP no dashboard ou ping externo).

## Template de Código Completo

```javascript
async (page) => {
  // 1. Navegar e Login
  await page.goto('http://192.168.28.1');
  if (await page.locator('#username').count() > 0) {
      await page.locator('#username').fill('user');
      await page.locator('#password').fill('user-GW-24');
      await page.getByRole('button', { name: 'Login' }).click();
      await page.waitForTimeout(5000);
  }

  // 2. Ir para WAN Connection
  await page.getByRole('link', { name: 'Network', exact: true }).click();
  await page.waitForTimeout(3000);
  await page.getByRole('link', { name: 'WAN Connection', exact: true }).click();
  
  const frame = page.frame({ name: 'contentIframe' });
  await page.waitForTimeout(2000);

  // 3. Configurar VLAN 2603
  // Verificar se VLAN está habilitada
  const vlanCheckbox = frame.locator('input[name="vlan"]');
  // Datacom às vezes usa value="ON" para checkbox ativado
  // Melhor forçar check se não estiver marcado
  if (!(await vlanCheckbox.isChecked())) {
     await vlanCheckbox.check();
  }
  await frame.locator('input[name="vid"]').fill('2603');

  // 4. Modo PPPoE
  await frame.locator('select[name="adslConnectionMode"]').selectOption({ label: 'PPPoE' });
  
  // 5. Tipo de Conexão: INTERNET
  await frame.locator('select[name="ctype"]').selectOption({ label: 'INTERNET' });
  
  // 6. Credenciais
  await frame.locator('input[name="pppUserName"]').fill('yan.marcos@g5fibra');
  await frame.locator('input[name="pppPassword"]').fill('yan.marcos');
  
  // 7. Salvar
  // CUIDADO: Isso vai derrubar a conexão se os dados estiverem errados
  await frame.locator('input[name="apply"]').click();
  
  await page.waitForTimeout(5000);
  
  return { status: 'WAN Configurada com Sucesso' };
}
```

## Compatibilidade

- **Datacom DM986-204**: Testado e Validado.
- **Outros Modelos**: A lógica de VLAN e PPPoE é similar, mas os seletores (IDs/Names) variam.

## Troubleshooting

- **Campo desabilitado**: Às vezes, para mudar o modo, é preciso excluir a interface e criar uma nova. Esta skill assume edição da interface existente.
- **Select não muda**: Em alguns frameworks legados, mudar o select requer disparar evento `onchange`. O Playwright faz isso automaticamente com `selectOption`, mas se falhar, use `dispatchEvent('change')`.
