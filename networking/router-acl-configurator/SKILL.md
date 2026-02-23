---
name: Router ACL Configurator
description: Configura o acesso remoto via WAN (IPv4 ACL) no roteador Datacom DM986-204
version: 1.0.0
author: Yan Marcos
category: networking
tags: [router, acl, remote-access, security, datacom, powershell]
---

# Router ACL Configurator Skill

Esta skill permite configurar rapidamente as permissões de acesso remoto (IPv4 ACL) no roteador Datacom DM986-204, habilitando o gerenciamento via WAN para serviços como HTTP, HTTPS e PING.

## Quando Usar

Use esta skill quando precisar:
- Habilitar acesso remoto para suporte técnico.
- Liberar o PING na WAN para monitoramento do link.
- Alterar as portas de gerenciamento remoto (ex: mudar HTTP de 80 para 8080).
- Garantir que qualquer IP de origem possa acessar o roteador via WAN (útil para suporte externo).

## Informações Necessárias

Antes de executar, obtenha:
1. **IP do roteador** (acesso local atual)
2. **Credenciais de administração**
3. **Portas desejadas** (opcional, padrão: HTTP=8080, HTTPS=443)
4. **Habilitação de PING** (opcional, padrão: $true)

## ⚠️ Avisos Importantes

1. **Segurança**: Abrir a ACL para a WAN ("Any IP") expõe o painel de login do roteador à internet. Certifique-se de usar senhas fortes.
2. **Acúmulo de Regras**: O script adiciona novas entradas. Se a lista de ACL estiver cheia, pode haver erro. Limpe a ACL manualmente se necessário em `http://[IP]/acl.asp`.
3. **Aplicação Imediata**: As regras são aplicadas imediatamente sem necessidade de reboot.

## Processo de Execução

### Utilizando o Script PowerShell (MÉTODO RECOMENDADO)

1. **Script:** `scripts\set-acl.ps1`
2. **Executar via run_command:**
```powershell
# Usando portas padrão (HTTP=8080, HTTPS=443) com PING habilitado
powershell.exe -ExecutionPolicy Bypass -File "scripts\set-acl.ps1" -IP [IP] -User [USER] -Pass [PASSWORD]

# Configurar portas customizadas e desabilitar PING
powershell.exe -ExecutionPolicy Bypass -File "scripts\set-acl.ps1" -IP [IP] -User [USER] -Pass [PASSWORD] -HttpPort 8888 -HttpsPort 8443 -Ping $false
```

### O que o script faz:
- Faz login no roteador.
- Lê o IP LAN atual (necessário para o cálculo do checksum de segurança).
- Adiciona uma regra para HTTP (Porta especificada).
- Adiciona uma regra para HTTPS (Porta especificada).
- Adiciona uma regra para PING (ICMP).
- Executa o comando de "Apply" para ativar as novas regras.

## Checklist de Execução

- [ ] Confirmar quais serviços o usuário deseja liberar na WAN.
- [ ] Definir as portas HTTP/HTTPS (usar padrão 8080/443 se não informado).
- [ ] Executar o comando PowerShell.
- [ ] Verificar o resumo final exibido pelo script para confirmar as regras ativas.
- [ ] Tentar acessar o roteador externamente (se possível) para validar.

## Troubleshooting

### Problema: IPv4 ACL Rule List está cheia
**Solução:** O DM986-204 tem um limite de entradas na ACL. Se o script falhar ao adicionar, acesse manualmente no navegador em Netowrk > ACL e remova entradas antigas ou duplicadas.

### Problema: Não consigo acessar mesmo após "Sucesso"
**Solução:** Verifique se há algum firewall ou NAT no roteador de borda do provedor que esteja bloqueando as portas antes de chegarem ao Datacom.
