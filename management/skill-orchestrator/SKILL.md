---
name: Skill Orchestrator
description: Orquestrador mestre projetado para identificar a necessidade do usuário e selecionar a skill mais adequada entre as disponíveis no repositório.
version: 1.0.0
author: Yan Marcos
category: management
tags: [orchestration, routing, dispatcher, management, skills]
---

# Skill Orchestrator

Esta skill atua como a "Cérebro" do sistema, servindo de guia para o Antigravity (ou qualquer usuário) identificar qual habilidade deve ser utilizada para uma tarefa específica, baseando-se no contexto, equipamentos envolvidos e objetivos.

## Matriz de Decisão (Skill Mapping)

Baseado na intenção do usuário, utilize o mapeamento abaixo para selecionar a skill correta.

### 🌐 Networking & Wireless ISP

| Se o usuário quer... | E o equipamento é... | Use esta Skill |
|----------------------|----------------------|----------------|
| Extrair senhas de WiFi | Datacom (PS), TP-Link, D-Link, Intelbras | `router-wifi-extractor` |
| Alterar nome/senha WiFi | Datacom (PS), TP-Link, D-Link | `router-wifi-configurator` |
| Reiniciar ou Resetar | Datacom (PS), Genérico | `router-reboot` |
| Configurar WAN/PPPoE/VLAN | Datacom DM986 (PS) | `router-wan-configurator` |
| **Backup ou Restore** | **Datacom DM986 (PS)** | `router-backup-restore` |
| **Acesso Remoto (ACL)**| **Datacom DM986 (PS)** | `router-acl-configurator` |
| Consultar IP/Cadastro | Sistema SGP | `sgp-ip-lookup` |
| **Checkup de Saúde PTP** | **Ubiquiti (AirOS 6/M5)** | `ubiquiti-ap-checkup` |
| **Checkup de Saúde PTP** | **Ubiquiti (AirOS 7/AC)** | `ubiquiti-airos7-checkup` |
| **Checkup de Saúde PTP** | **Mimosa C5c** | `mimosa-c5c-checkup` |

### 🤖 Automação & Utilidades

| Se o usuário quer... | Contexto | Use esta Skill |
|----------------------|----------|----------------|
| Ler e-mails recentes | Microsoft Outlook | `outlook-email-reader` |
| Recuperar senhas/URLs | Cofre Obsidian | `secure-credential-access` |

---

## Fluxo de Trabalho do Orquestrador

Sempre que uma nova tarefa for solicitada, o Orquestrador segue estes passos:

1. **Identificação do Alvo:**
   - Qual é o equipamento? (Ex: Rocket M5, Rocket 5AC, Mimosa, Roteador Doméstico)
   - Qual o serviço? (Ex: Outlook, SGP)

2. **Consulta ao Vault (se necessário):**
   - Utilizar `secure-credential-access` para buscar URL e credenciais se não fornecidas explicitamente.
   - Analisar o campo `url` ou `notes` no vault para confirmar a tecnologia (Ex: porta 8044 costuma ser AirOS ou Mimosa).

3. **Diferenciação Visual/Tecnológica:**
   - **AirOS 6:** Interface azul/cinza clássica, menus superiores.
   - **AirOS 7:** Interface moderna, menu lateral, tons escuros, suporte AC.
   - **Mimosa:** Interface "Mimosa by Airspan", login apenas com senha, dashboard com Signal Meter tipo arco.

4. **Seleção e Execução:**
   - Carregar a skill correspondente e seguir o procedimento documentado nela.

---

## Como Atualizar este Orquestrador

Sempre que uma nova skill for adicionada ao diretório `~/.gemini/antigravity/skills/`:

1. Identifique a **Intenção** e os **Keywords** da nova skill.
2. Adicione uma linha na **Matriz de Decisão** acima.
3. Se for uma nova categoria (Ex: Cloud, Security), crie uma nova tabela.
4. Mantenha as skills de suporte como `secure-credential-access` sempre visíveis para as outras.

## Exemplo de Orquestração Proativa

**Usuário:** "Verifica como está o link VS50."

**Orquestrador:**
1. Busca `VS50` no vault via `secure-credential-access`.
2. O vault retorna `URL: http://172.10.10.50:8044` e `Service: G5-PTP-VS50`.
3. O orquestrador acessa a URL.
4. Ao carregar a página:
   - Se ver título "C5c" -> Executa `mimosa-c5c-checkup`.
   - Se ver título "Rocket 5AC" -> Executa `ubiquiti-airos7-checkup`.
   - Se ver título "Rocket M5" -> Executa `ubiquiti-ap-checkup`.
