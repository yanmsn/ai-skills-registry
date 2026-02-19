---
name: Mimosa C5c PTP Checkup
description: Acessa painéis de administração de rádios Mimosa C5c e realiza checkup completo de saúde, extraindo métricas de sinal, modulação, ethernet e logs.
version: 1.0.0
author: Yan Marcos
category: networking
tags: [mimosa, c5c, backhaul, ptp, checkup, networking, playwright]
---

# Mimosa C5c PTP Checkup

Esta skill automatiza o processo de acesso e coleta de informações de diagnóstico em rádios Mimosa C5c configurados em modo PTP.

## Quando Usar
- Para verificações rotineiras de saúde do enlace.
- Diagnóstico de quedas de sinal ou instabilidade.
- Verificação de modulação e ruído (CINR).
- Auditoria de versão de firmware e tempo de atividade.

## Pré-requisitos
- Acesso à rede onde o rádio está instalado.
- Credenciais armazenadas no vault (apenas senha é necessária para Mimosa).
- Playwright MCP configurado.

## Procedimento de Coleta

### 1. Acesso ao Equipamento
A skill acessa a URL fornecida e realiza o login utilizando apenas a senha.

### 2. Extração de Métricas (Dashboard)
A skill coleta os seguintes dados da página principal:
- **Status do Link:** (Connected / Disconnected)
- **SSID:** Identificação da rede sem fio.
- **Uptime & Disponibilidade:** Tempo que o link está ativo.
- **Parâmetros de Rádio:** Frequência central e largura de canal.
- **Performance de MIMO:** Power (dBm), Noise (dBm) e CINR (dB) para as duas cadeias (Chain 1 e 2).
- **Detalhes do Dispositivo:** Modelo, Serial, Versão de Firmware e Status da Ethernet (ex: 1000Mb/s Full Duplex).

### 3. Verificação de Logs
A skill navega até **Diagnostics -> Logs** para verificar os eventos mais recentes, como reinicializações por energia (Power on Reset) ou flutuações de link ethernet.

## Guia de Interpretação (Checkup)

| Métrica | Valor Ideal | Atenção | Crítico |
|---------|-------------|---------|---------|
| **RX Power** | -45 a -60 dBm | > -70 dBm | > -80 dBm |
| **CINR** | > 25 dB | 15 - 25 dB | < 15 dB |
| **Noise Floor** | < -95 dBm | -90 a -85 dBm | > -85 dBm |
| **Ethernet** | 1000Mb/s Full | 100Mb/s | 10Mb/s ou Half |
| **CPU/Mem** | < 50% | 50% - 80% | > 80% |

## Exemplo de Relatório Gerado

```markdown
# Relatório de Checkup Mimosa — [Nome do Dispositivo]

**Status Geral:** [SAUDÁVEL / ATENÇÃO / URGENTE]

### Saúde do Wireless
- **Status:** Connected
- **SSID:** G5-BACKHAUL-PTP
- **Frequência:** 5800 MHz (40 MHz)
- **Sinal (Chain 1/2):** -58 / -59 dBm
- **CINR (Chain 1/2):** 32 / 31 dB
- **Ruído:** -98 dBm

### Detalhes do Sistema
- **Ethernet:** 1000Mb/s Full Duplex
- **Firmware:** 2.8.1
- **Uptime:** 15d 04:22:10

### Análise de Logs
- [DATA] Power on Reset detectado.
- [DATA] Ethernet link up (1000/Full).
```

## Troubleshooting Comum
1. **Disconnected:** Verificar se o rádio remoto está ligado e alinhado. Verifique logs para "Radar detection" (DFS).
2. **Ethernet 100Mb/s:** Sugere problema no cabo, conector ou fonte PoE (Mimosa requer PoE Giga).
3. **CINR Baixo:** Pode indicar interferência no canal ou desalinhamento. Experimente mudar a frequência em "Wireless -> Channel & Power".
