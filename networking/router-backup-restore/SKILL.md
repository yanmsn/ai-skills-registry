---
name: Router Backup/Restore
description: Realiza backup e restauração de configurações em roteadores Datacom DM986-204 de forma determinística via PowerShell
version: 1.0.0
author: Yan Marcos
category: networking
tags: [router, backup, restore, config, datacom, powershell]
---

# Router Backup/Restore Skill

Esta skill permite realizar o backup das configurações de um roteador Datacom DM986-204 para um arquivo XML local e restaurar essas configurações posteriormente.

## Quando Usar

Use esta skill quando precisar:
- Salvar o estado atual de um roteador antes de mudanças críticas.
- Clonar a configuração de um roteador para outro.
- Restaurar um roteador após um erro de configuração ou reset de fábrica.
- Manter um histórico de configurações dos equipamentos.

## Informações Necessárias

Antes de executar, você precisa:
1. **IP do roteador** (ex: 192.168.28.1)
2. **Usuário de administração** (padrão: user)
3. **Senha de administração** (padrão: user-GW-24)
4. **Caminho do arquivo** (para restore) ou **Nome do arquivo** (para backup opcional)

## ⚠️ Avisos Importantes

1. **Reboot Automático**: Após o **Restore**, o roteador irá reiniciar automaticamente para aplicar as configurações.
2. **Downtime**: O equipamento ficará offline por cerca de 60-90 segundos durante o restore.
3. **Compatibilidade**: Estes scripts são específicos para o modelo **Datacom DM986-204**.

## Processo de Execução

### Passo 1: Realizar Backup (Download)

Utilize o script PowerShell para baixar o arquivo de configuração XML:

1. **Script:** `C:\Users\Yan\Desktop\dm986\backup.ps1`
2. **Executar via run_command:**
```powershell
# Backup com nome automático (backup-YYYY-MM-DD_HH-mm-ss.xml)
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\Yan\Desktop\dm986\backup.ps1" -IP [IP] -User [USER] -Pass [PASSWORD]

# Backup salvando em caminho específico
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\Yan\Desktop\dm986\backup.ps1" -IP [IP] -User [USER] -Pass [PASSWORD] -OutputFile "C:\backups\config_cliente_X.xml"
```

### Passo 2: Restaurar Backup (Upload)

Utilize o script PowerShell para enviar um arquivo XML de configuração ao roteador:

1. **Script:** `C:\Users\Yan\Desktop\dm986\restore.ps1`
2. **Executar via run_command:**
```powershell
# Restore e aguardar o retorno online (padrão)
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\Yan\Desktop\dm986\restore.ps1" -IP [IP] -User [USER] -Pass [PASSWORD] -InputFile "C:\caminho\para\backup.xml"

# Restore sem aguardar (mais rápido para o bot)
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\Yan\Desktop\dm986\restore.ps1" -IP [IP] -User [USER] -Pass [PASSWORD] -InputFile "C:\caminho\para\backup.xml" -Wait $false
```

## Checklist de Execução

- [ ] Confirmar IP e credenciais do roteador.
- [ ] Para **Backup**: Verificar se o diretório de destino existe.
- [ ] Para **Restore**: **AVISAR O USUÁRIO** sobre a reinicialização.
- [ ] Executar o comando PowerShell correspondente.
- [ ] Verificar a saída para confirmar o sucesso da operação.
- [ ] Se for Restore com `-Wait $true`, confirmar que o equipamento voltou a responder ping/HTTP.

## Troubleshooting

### Problema: Erro de "protocol violation" no download
**Explicação:** O servidor web do roteador (Boa) envia headers não-padrão.
**Solução:** O script `backup.ps1` já trata isso usando TCP raw. Certifique-se de estar usando a versão mais recente do script.

### Problema: Restore falha com "File Not Found"
**Solução:** Use o caminho absoluto para o arquivo `-InputFile`.

### Problema: Equipamento não volta online após 120s
**Solução:** Pode ser que os dados de IP/VLAN no backup sejam diferentes do estado anterior. Verifique se as novas configurações são compatíveis com o acesso à rede.
