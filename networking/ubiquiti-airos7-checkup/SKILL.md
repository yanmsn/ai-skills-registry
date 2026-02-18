---
name: Ubiquiti AirOS 7 PTP Checkup
description: Acessa painéis AirOS 7 de antenas Ubiquiti (Rocket 5AC Lite) em modo PTP e realiza checkup completo de saúde, extraindo métricas de desempenho, sinal, capacidade, diagrama de constelação e informações do link remoto.
version: 1.0.0
author: Yan Marcos
category: networking
tags: [ubiquiti, airos7, rocket-5ac, ptp, antenna, checkup, monitoring, wireless-isp, airmax-ac]
---

# Ubiquiti AirOS 7 PTP Checkup Skill

Esta skill permite acessar a interface web AirOS 7 de antenas Ubiquiti (como Rocket 5AC Lite) configuradas em modo **Ponto a Ponto (PTP)** para realizar um **checkup completo de saúde** do enlace. O objetivo é coletar e analisar métricas de desempenho, qualidade do sinal, capacidade isolada, diagramas de constelação, informações do link remoto e logs do sistema.

## Quando Usar

Use esta skill quando o usuário solicitar:
- Checkup/diagnóstico de um enlace PTP Ubiquiti
- Verificar a saúde de um AP (Access Point) com AirOS 7
- Analisar qualidade do sinal e capacidade do link PTP
- Verificar informações do dispositivo remoto (estação PTP)
- Monitorar uso de CPU/memória da antena
- Analisar diagramas de constelação e CINR
- Verificar logs de eventos do equipamento

## Diferenças do AirOS 6 vs AirOS 7

| Aspecto              | AirOS 6                         | AirOS 7                                  |
|----------------------|----------------------------------|-------------------------------------------|
| **Interface**        | Clássica, tabular               | Moderna, responsiva, menu lateral          |
| **Navegação**        | Abas superiores + links monitor | Menu lateral (Principal, Wireless, Rede, Serviços, Sistema) + botões inferiores (Ferramentas, Info, Log) |
| **URLs**             | Páginas separadas (.cgi)        | SPA com hash routing (#dashboard, #wireless, etc.) |
| **Info**             | Não existe                      | Dialog modal com resumo completo + dados remotos |
| **Log**              | Página separada (log.cgi)       | Dialog modal                              |
| **Estações**         | Tabela dedicada (stalist.cgi)   | Dados do remoto integrados na página principal e Info |
| **Gráficos**         | Throughput básico                | Capacity/Throughput + Constellation + Signal/Noise/Interference |
| **Login**            | Formulário simples              | Formulário moderno com heading do modelo   |
| **Logout**           | Botão no topo                   | Link "Logout" no canto superior direito    |
| **airMAX AC**        | Não suportado                   | Suporta airMAX AC com 64QAM e modulação avançada |

## Equipamento Compatível

| Propriedade        | Valor                                  |
|--------------------|----------------------------------------|
| **Fabricante**     | Ubiquiti Networks                      |
| **Modelo**         | Rocket 5AC Lite (R5AC-Lite)            |
| **Firmware**       | AirOS v7.x (testado com v7.2.4 XC)    |
| **Frequência**     | 5 GHz                                 |
| **Modo**           | Access Point PTP (Ponto a Ponto)       |
| **Modo de rede**   | Ponte (Bridge)                         |
| **Interface**      | Web (HTTP) via porta customizada       |
| **Antena**         | RD-5G-30 — 30 dBi (dish)              |

## Pré-requisitos

1. **Credenciais** — Usar a skill `Secure Credential Access` para obter usuário/senha do vault Obsidian (`Passwords/[NOME_DO_SERVICO].md`).
2. **Conectividade** — O computador deve ter acesso à rede de gerência do equipamento.
3. **Playwright MCP** — Deve estar instalado e configurado.

## Informações Necessárias

Antes de executar, você precisa:
1. **Nome do serviço no vault** (ex: `G5-PTP-UNIAO-ENV`) — para buscar credenciais
2. As credenciais no vault contêm: `url`, `username`, `password`

## Estrutura da Interface AirOS 7

A interface AirOS 7 usa Single Page Application (SPA) com hash routing.

### Menu Lateral Principal
| Item          | Hash Route    | Conteúdo                                              |
|---------------|---------------|-------------------------------------------------------|
| **Principal** | `#dashboard`  | Status geral, métricas de desempenho, gráficos, link  |
| **Wireless**  | `#wireless`   | Configurações de rádio (modo, SSID, frequência, potência) |
| **Rede**      | `#network`    | Configurações de rede (modo, IP, MTU, STP)            |
| **Serviços**  | `#services`   | Watchdog, SNMP, Web Server, SSH, NTP, DDNS, Syslog    |
| **Sistema**   | `#system`     | Firmware, device name, contas, manutenção, backup     |

### Botões Inferiores (Menu Secundário)
| Item            | Tipo          | Conteúdo                                              |
|-----------------|---------------|-------------------------------------------------------|
| **Ferramentas** | Submenu       | Alinhamento, Site Survey, Discovery, Ping, Traceroute, Speed Test, airView |
| **Info**        | Dialog modal  | Resumo completo do dispositivo + detalhes do remoto PTP |
| **Log**         | Dialog modal  | Logs do sistema com botões Atualizar e Clear          |

### Abas Laterais Direitas (Página Principal)
| Aba               | Conteúdo                                               |
|--------------------|--------------------------------------------------------|
| **Device**         | Informações do dispositivo (modelo, nome, versão, rede, CPU, memória, LAN, uptime) |
| **Link**           | Informações do link wireless (modo, SSID, MAC, sinal, frequência, taxas) |
| **RF Performance** | Diagramas de constelação (local e remoto), gráfico de sinal/ruído/interferência |

## Processo de Execução Completo

### Passo 1: Obter Credenciais

Usar a skill `Secure Credential Access`:
```
Ler nota: Passwords/[NOME_DO_SERVICO].md
Extrair: url, username, password
```

### Passo 2: Acessar o Equipamento e Fazer Login

```javascript
// Navegar até o equipamento
await page.goto('[URL_DO_EQUIPAMENTO]');
// Aguardar a página de login carregar
await page.waitForTimeout(3000);
```

A página de login do AirOS 7 possui:
- **Heading**: Nome do modelo (ex: "Rocket 5AC Lite")
- **Campo de usuário**: `textbox "Nome de usuário"`
- **Campo de senha**: `textbox "Senha"`
- **Botão de login**: `button "Login"`

```javascript
// Preencher formulário de login
// Usar browser_fill_form com os refs corretos
// Campo usuário: textbox "Nome de usuário"
// Campo senha: textbox "Senha"
// Botão login: button "Login"
```

**IMPORTANTE**: Nunca exibir credenciais no chat. Usar browser_fill_form passando os valores diretamente.

### Passo 3: Coletar Dados da Página Principal (Dashboard)

Após o login, a página principal (`#dashboard`) é organizada em painéis:

#### Painel Device (lado esquerdo superior):
| Campo                      | Exemplo de Valor              |
|----------------------------|-------------------------------|
| DEVICE MODEL               | Rocket 5AC Lite               |
| DEVICE NAME                | G5-PTP-UNIAO-ENV              |
| VERSION                    | v7.2.4 (XC)                   |
| MODO DE REDE               | Ponte                         |
| AIRTIME                    | 4.1%                          |
| LAN SPEED                  | 100Mbps-Full                  |
| MEMORY                     | 31%                           |
| CPU                        | 26%                           |
| CABLE LENGTH               | < 20 m                        |
| CABLE SNR                  | +30 dB                        |
| DATA                       | 18/07/2016, 22:08:31          |
| TEMPO DE DISPONIBILIDADE   | 4 days 04:53:36               |

#### Painel Link (lado esquerdo inferior):
| Campo                      | Exemplo de Valor              |
|----------------------------|-------------------------------|
| MODO SEM FIO               | Ponto de acesso PTP           |
| SSID                       | G5-PTP-UNIAO                  |
| WLAN0 MAC                  | 04:18:D6:AE:EF:1C             |
| STA MAC                    | 04:18:D6:E8:C3:66             |
| SEGURANÇA                  | WPA2                          |
| TX/RX BYTES                | 2.18G / 3.95G                 |
| DISTÂNCIA                  | 2.5 miles (4.1 km)            |
| FREQUÊNCIA                 | 5700 [5660 - 5720] MHz        |
| CHANNEL WIDTH              | 60 MHz                        |
| RX SIGNAL                  | -64 dBm                       |
| RX CHAIN 0 / 1             | -69 dBm / -65 dBm             |
| TX RATE                    | 6x (64QAM 2x2)               |
| RX RATE                    | 6x (64QAM 2x2)               |
| TX POWER                   | 2 dBm                         |

#### Gráficos (centro):
- **Isolated Capacity / Throughput**: TX/RX em Mbps + Latência
- **Local Constellation Diagram**: POWER e CINR local
- **Remote Constellation Diagram**: POWER e CINR remoto

#### Gráfico Signal, Noise and Interference (inferior):
| Métrica                    | Exemplo de Valor              |
|----------------------------|-------------------------------|
| Average Signal             | -65 dBm                       |
| Interference + Noise       | -81 dBm                       |
| Noise Floor                | -91 dBm                       |

### Passo 4: Coletar Dados do Info (Detalhes do Remoto PTP)

Clicar no botão **"Info"** no menu secundário inferior para abrir o dialog modal "Device Information".

Este dialog contém um textarea com informações completas do dispositivo **E do dispositivo remoto PTP**:

#### Seção WIRELESS REMOTE DETAILS:
| Campo                      | Exemplo de Valor              |
|----------------------------|-------------------------------|
| Device Model (remoto)      | Rocket 5AC Lite               |
| Device Name (remoto)       | G5-PTP-UNIAO-REC              |
| Version (remoto)           | v7.2.4                        |
| Endereço MAC               | 04:18:D6:E8:C3:66             |
| Last IP                    | 172.100.10.11                 |
| RX Signal (remoto)         | -66 dBm                       |
| RX Chain 0 / 1 (remoto)    | -69 dBm / -69 dBm             |
| Noise Floor (remoto)       | -93 dBm                       |
| Latency                    | 0 ms                          |
| TX Power (remoto)          | 2 dBm                         |
| Connection Time             | 4 days 04:55:07              |
| Isolated Capacity TX / RX  | 186 Mbps / 263 Mbps           |
| airTime TX/RX               | 7.1 / 1.0                    |

**IMPORTANTE**: Para extrair esses dados, usar `browser_evaluate` com o conteúdo do textarea do dialog Info.

### Passo 5: Verificar Logs do Sistema

Clicar no botão **"Log"** no menu secundário inferior para abrir o dialog modal "System Log".

O log aparece em um textarea dentro do dialog. Procurar por:
- **`system: Start`** — indica boot/reboot
- **`Authenticated Station`** — conexão do dispositivo remoto
- **`Registered node`** — registro do dispositivo remoto
- **`handshake completed`** — autenticação WPA bem-sucedida
- **`link=UP`** — interface LAN ativada
- Ausência de erros, desconexões ou reboots frequentes

### Passo 6: Salvar Relatório em Arquivo Markdown

Após coletar todos os dados e gerar a análise, **SEMPRE** salvar o relatório como arquivo `.md` na área de trabalho do usuário.

**Padrão de nome do arquivo:**
```
[NOME_DO_DISPOSITIVO]_checkup_[YYYY-MM-DD].md
```

**Exemplo:**
```
C:\Users\Yan\Desktop\G5-PTP-UNIAO-ENV_checkup_2026-02-18.md
```

**Regras:**
1. O arquivo DEVE ser salvo automaticamente — **não perguntar** ao usuário se deseja salvar.
2. Usar a data atual (real) do checkup, não a data do equipamento.
3. Seguir o template da seção "Template do Relatório de Checkup" com todos os dados coletados preenchidos.
4. Incluir no rodapé: `*Relatório gerado automaticamente pela skill Ubiquiti AirOS 7 PTP Checkup v1.0.0*`
5. Informar ao usuário o caminho do arquivo salvo após a geração.

### Passo 7: Encerrar Sessão

```javascript
// Clicar no link "Logout" no canto superior direito
// link " Logout" → url: /logout.cgi
```

## Extração de Dados via JavaScript

### Dados da Página Principal (Dashboard)

```javascript
() => {
  const text = document.body.innerText;
  const result = {};
  
  const patterns = {
    'device_model': /DEVICE MODEL\s+(.+)/,
    'device_name': /DEVICE NAME\s+(.+)/,
    'version': /VERSION\s+(.+)/,
    'modo_rede': /MODO DE REDE\s+(.+)/,
    'airtime': /AIRTIME\s+([\d.]+%)/,
    'lan_speed': /LAN SPEED\s+(.+)/,
    'memory': /MEMORY\s+(\d+%)/,
    'cpu': /CPU\s+(\d+%)/,
    'cable_length': /CABLE LENGTH\s+(.+)/,
    'cable_snr': /CABLE SNR\s+(.+)/,
    'data': /DATA\s+(.+)/,
    'uptime': /TEMPO DE DISPONIBILIDADE\s+(.+)/,
    'modo_wireless': /MODO SEM FIO\s+(.+)/,
    'ssid': /SSID\s+(.+)/,
    'wlan_mac': /WLAN0 MAC\s+(.+)/,
    'sta_mac': /STA MAC\s+(.+)/,
    'seguranca': /SEGURANÇA\s+(.+)/,
    'tx_rx_bytes': /TX\/RX BYTES\s+(.+)/,
    'distancia': /DISTÂNCIA\s+(.+)/,
    'frequencia': /FREQUÊNCIA\s+(.+)/,
    'channel_width': /CHANNEL WIDTH\s+(.+)/,
    'rx_signal': /RX SIGNAL\s+(.+)/,
    'rx_chain': /RX CHAIN 0 \/ 1\s+(.+)/,
    'tx_rate': /TX RATE\s+(.+)/,
    'rx_rate': /RX RATE\s+(.+)/,
    'tx_power': /TX POWER\s+(.+)/,
    'avg_signal': /Average Signal\s+(.+)/,
    'interference_noise': /Interference \+ Noise\s+(.+)/,
    'noise_floor': /Noise Floor\s+(.+)/,
    'local_power': /Local Constellation[\s\S]*?POWER\s+(-?\d+\s*dBm)/,
    'local_cinr': /Local Constellation[\s\S]*?CINR\s+(\d+\s*dB)/,
    'remote_power': /Remote Constellation[\s\S]*?POWER\s+(-?\d+\s*dBm)/,
    'remote_cinr': /Remote Constellation[\s\S]*?CINR\s+(\d+\s*dB)/,
  };
  
  for (const [key, regex] of Object.entries(patterns)) {
    const match = text.match(regex);
    if (match) result[key] = match[1].trim();
  }
  
  return result;
}
```

### Dados do Info (incluindo Remoto PTP)

Após abrir o dialog Info, extrair dados do textarea:

```javascript
() => {
  const textarea = document.querySelector('dialog textarea, [role="dialog"] textarea');
  if (!textarea) return { error: 'Info dialog not found' };
  const text = textarea.value || textarea.textContent;
  
  const result = { local: {}, remote: {} };
  
  // Dados locais
  const localPatterns = {
    'model': /Device Model:\s*(.+)/,
    'name': /Device Name:\s*(.+)/,
    'version': /Version:\s*(.+)/,
    'memory': /Memory:\s*(\d+%)/,
    'cpu': /CPU:\s*(\d+%)/,
    'lan_speed': /LAN Speed:\s*(.+)/,
    'uptime': /Tempo de disponibilidade:\s*(.+)/,
    'tx_rx_bytes': /TX\/RX Bytes:\s*(.+)/,
    'rx_signal': /RX Signal:\s*(.+)/,
    'noise_floor': /Noise Floor:\s*(.+)/,
    'channel_width': /Channel Width:\s*(.+)/,
    'frequency': /Freqüência:\s*(.+)/,
    'capacity_tx_rx': /Isolated Capacity TX \/ RX:\s*(.+)/,
    'airtime': /airTime:\s*(.+)/,
  };
  
  // Dados remotos (após "WIRELESS REMOTE DETAILS")
  const remoteSection = text.split('WIRELESS REMOTE DETAILS')[1] || '';
  const remotePatterns = {
    'model': /Device Model:\s*(.+)/,
    'name': /Device Name:\s*(.+)/,
    'version': /Version:\s*(.+)/,
    'mac': /Endereço MAC::\s*(.+)/,
    'last_ip': /Last IP:\s*(.+)/,
    'rx_signal': /RX Signal:\s*(.+)/,
    'rx_chain': /RX Chain 0 \/ 1:\s*(.+)/,
    'noise_floor': /Noise Floor:\s*(.+)/,
    'latency': /Latency:\s*(.+)/,
    'tx_power': /TX Power:\s*(.+)/,
    'connection_time': /Connection Time:\s*(.+)/,
    'capacity_tx_rx': /Isolated Capacity TX \/ RX:\s*(.+)/,
    'airtime_tx_rx': /airTime TX\/RX:\s*(.+)/,
  };
  
  for (const [key, regex] of Object.entries(localPatterns)) {
    const match = text.match(regex);
    if (match) result.local[key] = match[1].trim();
  }
  
  for (const [key, regex] of Object.entries(remotePatterns)) {
    const match = remoteSection.match(regex);
    if (match) result.remote[key] = match[1].trim();
  }
  
  return result;
}
```

### Dados do Log

Após abrir o dialog Log, extrair dados do textarea:

```javascript
() => {
  const textarea = document.querySelector('dialog textarea, [role="dialog"] textarea');
  if (!textarea) return { error: 'Log dialog not found' };
  const text = textarea.value || textarea.textContent;
  
  const lines = text.split('\n').filter(l => l.trim());
  const systemStarts = lines.filter(l => l.includes('system: Start'));
  const authentications = lines.filter(l => l.includes('Authenticated Station'));
  const handshakes = lines.filter(l => l.includes('handshake completed'));
  const errors = lines.filter(l => l.includes('error') || l.includes('Error'));
  const linkUp = lines.filter(l => l.includes('link=UP'));
  
  return {
    total_lines: lines.length,
    system_starts: systemStarts.length,
    authentications: authentications.length,
    handshakes: handshakes.length,
    errors: errors.length,
    link_up_events: linkUp.length,
    first_line: lines[0] || '',
    last_line: lines[lines.length - 1] || '',
    sample_errors: errors.slice(-5),
  };
}
```

## Critérios de Análise e Limiares

### 🟢 Normal (OK)
| Métrica                | Faixa Aceitável                      |
|------------------------|---------------------------------------|
| CPU                    | 0 - 40%                              |
| Memória                | 0 - 60%                              |
| RX Signal              | -50 a -70 dBm                        |
| CINR Local/Remoto      | > 20 dB                              |
| Noise Floor             | < -85 dBm (mais negativo = melhor)   |
| Latência               | < 2 ms                               |
| airTime                | < 30%                                |
| Isolated Capacity      | > 100 Mbps (cada direção)            |
| Cable SNR              | > +20 dB                             |
| TX/RX Rate             | 6x (64QAM) ou superior               |
| LAN Speed              | 100Mbps-Full                          |
| Erros de interface     | 0                                     |

### 🟡 Atenção
| Métrica                | Faixa de Atenção                      |
|------------------------|---------------------------------------|
| CPU                    | 40 - 70%                              |
| Memória                | 60 - 80%                              |
| RX Signal              | -70 a -75 dBm                         |
| CINR Local/Remoto      | 15 - 20 dB                            |
| Noise Floor             | -85 a -75 dBm                         |
| Latência               | 2 - 10 ms                             |
| airTime                | 30 - 60%                              |
| Isolated Capacity      | 50 - 100 Mbps                         |
| Cable SNR              | +10 a +20 dB                          |
| TX/RX Rate             | 4x (16QAM) ou inferior                |

### 🔴 Crítico
| Métrica                | Faixa Crítica                         |
|------------------------|---------------------------------------|
| CPU                    | > 70%                                 |
| Memória                | > 80%                                 |
| RX Signal              | Pior que -75 dBm                      |
| CINR Local/Remoto      | < 15 dB                               |
| Noise Floor             | > -75 dBm                             |
| Latência               | > 10 ms                               |
| airTime                | > 60%                                 |
| Isolated Capacity      | < 50 Mbps                             |
| Cable SNR              | < +10 dB                              |
| TX/RX Rate             | 1-2x (QPSK)                           |
| LAN Speed              | 10Mbps ou Half-Duplex                 |

### Sinal do Link PTP
| Faixa de Sinal        | Qualidade    | Cor   |
|------------------------|--------------|-------|
| -45 a -55 dBm         | Excelente    | 🟢    |
| -55 a -65 dBm         | Bom          | 🟢    |
| -65 a -70 dBm         | Aceitável    | 🟡    |
| -70 a -75 dBm         | Fraco        | 🟡    |
| -75 a -80 dBm         | Muito Fraco  | 🔴    |
| Pior que -80 dBm      | Crítico      | 🔴    |

### Modulação (TX/RX Rate)
| Modulação              | Qualidade    | Cor   |
|------------------------|--------------|-------|
| 8x (256QAM)            | Excepcional  | 🟢    |
| 6x (64QAM 2x2)        | Excelente    | 🟢    |
| 4x (16QAM 2x2)        | Aceitável    | 🟡    |
| 2x (QPSK 2x2)         | Fraco        | 🔴    |
| 1x (BPSK/QPSK)        | Crítico      | 🔴    |

## Template do Relatório de Checkup

Após coletar todos os dados, gerar o relatório no seguinte formato:

```markdown
# 📡 Relatório de Checkup PTP — [NOME_DO_DISPOSITIVO]

**Data do Checkup:** [DATA_ATUAL]
**Equipamento Local:** [MODELO] — [NOME_LOCAL]
**Equipamento Remoto:** [MODELO] — [NOME_REMOTO]
**Firmware:** AirOS [VERSÃO]
**Uptime:** [TEMPO_DE_ATIVIDADE]
**Endereço de Gerência:** [IP]

---

## 📊 Saúde Geral

| Métrica            | Valor     | Limiar        | Status |
|--------------------|-----------|---------------|--------|
| CPU                | X%        | < 40% = OK    | 🟢/🟡/🔴 |
| Memória            | X%        | < 60% = OK    | 🟢/🟡/🔴 |
| airTime            | X%        | < 30% = OK    | 🟢/🟡/🔴 |
| Link LAN           | XXMbps    | 100Mbps = OK  | 🟢/🟡/🔴 |
| Cable SNR          | +XX dB    | > +20 dB = OK | 🟢/🟡/🔴 |

---

## 📻 Link PTP — Sinal e Capacidade

| Métrica            | Local         | Remoto        | Status |
|--------------------|---------------|---------------|--------|
| RX Signal          | -XX dBm       | -XX dBm       | 🟢/🟡/🔴 |
| RX Chain 0 / 1     | -XX / -XX dBm | -XX / -XX dBm | 🟢/🟡/🔴 |
| CINR               | XX dB         | XX dB         | 🟢/🟡/🔴 |
| Noise Floor        | -XX dBm       | -XX dBm       | 🟢/🟡/🔴 |
| TX Power           | X dBm         | X dBm         | 🟢/🟡/🔴 |
| TX Rate            | Xx (XXX)      | Xx (XXX)      | 🟢/🟡/🔴 |
| RX Rate            | Xx (XXX)      | Xx (XXX)      | 🟢/🟡/🔴 |
| Latência           | X ms          | —             | 🟢/🟡/🔴 |

---

## ⚡ Capacidade do Enlace

| Direção           | Capacidade    | Status |
|-------------------|---------------|--------|
| TX (Upload)       | XXX Mbps      | 🟢/🟡/🔴 |
| RX (Download)     | XXX Mbps      | 🟢/🟡/🔴 |

---

## 📻 Configuração de Rádio

| Parâmetro          | Valor                   |
|--------------------|--------------------------|
| Modo sem fio       | Access Point PTP         |
| SSID               | XXXXXXXX                 |
| Frequência         | XXXX [XXXX - XXXX] MHz   |
| Channel Width      | XX MHz                   |
| TX Power           | XX dBm                   |
| Antena             | MODELO - XX dBi          |
| Distância          | X.X miles (X.X km)       |
| Segurança          | WPA2-AES                 |

---

## 🔗 Dispositivos do Enlace

### Local
| Campo              | Valor                    |
|--------------------|--------------------------|
| Modelo             | XXXXXXXX                 |
| Nome               | XXXXXXXX                 |
| MAC                | XX:XX:XX:XX:XX:XX        |
| Firmware           | vX.X.X                   |

### Remoto
| Campo              | Valor                    |
|--------------------|--------------------------|
| Modelo             | XXXXXXXX                 |
| Nome               | XXXXXXXX                 |
| MAC                | XX:XX:XX:XX:XX:XX        |
| Last IP            | XXX.XXX.XXX.XX           |
| Firmware           | vX.X.X                   |
| Connection Time    | X days XX:XX:XX          |

---

## 📋 Análise de Logs

| Tipo de Evento                | Quantidade | Avaliação     |
|-------------------------------|------------|---------------|
| Total de linhas de log        | XX         | X dias        |
| System starts (boots)         | X          | Normal/Atenção|
| Autenticações                 | X          | ✅ Normal     |
| Handshakes completados        | X          | ✅ Normal     |
| Erros                         | X          | ✅/🔴        |
| Link UP events                | X          | Normal        |

---

## 🏁 Diagnóstico Final

**Status Geral:** 🟢 SAUDÁVEL / 🟡 ATENÇÃO NECESSÁRIA / 🔴 AÇÃO URGENTE

### Observações:
- [OBSERVAÇÃO 1]
- [OBSERVAÇÃO 2]

### Recomendações:
- [RECOMENDAÇÃO 1]
- [RECOMENDAÇÃO 2]

---

*Relatório gerado automaticamente pela skill Ubiquiti AirOS 7 PTP Checkup v1.0.0*
*Autor: Yan Marcos*
```

## Navegação Detalhada — Seletores e Referências

### Página de Login (`login.cgi`)
```yaml
Heading modelo: heading "Rocket 5AC Lite" [level=1]
Campo usuário:  textbox "Nome de usuário"
Campo senha:    textbox "Senha"
Botão login:    button "Login"
```

### Menu Principal (lateral esquerdo)
```yaml
Principal:   link " Principal"  → url: #dashboard
Wireless:    link " Wireless"   → url: #wireless
Rede:        link " Rede"       → url: #network
Serviços:    link " Serviços"   → url: #services
Sistema:     link " Sistema"    → url: #system
```

### Menu Secundário (inferior esquerdo)
```yaml
Ferramentas: generic (cursor=pointer) → submenu expansível
Info:        generic (cursor=pointer) → abre dialog "Device Information"
Log:         generic (cursor=pointer) → abre dialog "System Log"
```

### Botões do Login/Logout
```yaml
Logout:      link " Logout"     → url: /logout.cgi
```

### Dialogs Modais
```yaml
Info dialog:
  Título:     "Device Information"
  Conteúdo:   textbox (readonly) com texto completo
  Fechar:     button "" (ícone X)

Log dialog:
  Título:     "System Log"
  Conteúdo:   textbox (readonly) com texto completo
  Atualizar:  button "Atualizar"
  Limpar:     button "Clear"
  Fechar:     button "" (ícone X)
```

## Dicas Importantes

### 1. Interface em Português Brasileiro (parcial)
A interface AirOS 7 mistura inglês e português brasileiro. Diferente do AirOS 6 (português de Portugal):
- "Nome de usuário" (não "Nome de utilizador")
- "Senha" (não "Palavra-passe")
- "MODO DE REDE" e "MODO SEM FIO" em caixa alta
- "TEMPO DE DISPONIBILIDADE" (não "Tempo de atividade")
- "DISTÂNCIA" (não "Distância")

### 2. Data do Sistema pode estar incorreta
O relógio do equipamento pode não estar sincronizado (ex: mostrando 2016). O uptime é confiável.

### 3. SPA com Hash Routing
Diferente do AirOS 6, o AirOS 7 usa SPA. Todas as páginas são carregadas via JavaScript sem recarregar a página. A URL muda apenas o hash (ex: `#dashboard`, `#wireless`).

### 4. Dialogs Modais
Info e Log abrem como dialogs sobrepostos. É necessário fechar o dialog (botão X) antes de interagir com outros elementos da página.

### 5. PTP → Apenas 1 Estação
No modo PTP (Ponto a Ponto), há apenas UM dispositivo remoto conectado. Os dados dele aparecem diretamente na página principal e no Info, sem necessidade de navegar para uma lista de estações separada.

### 6. Diagrama de Constelação
O AirOS 7 exibe diagramas de constelação (local e remoto) que mostram a distribuição dos símbolos de modulação. Quanto mais concentrados os pontos, melhor a qualidade do sinal. CINR (Carrier to Interference + Noise Ratio) > 25 dB indica link excelente.

### 7. Isolated Capacity vs Throughput
- **Isolated Capacity**: capacidade máxima teórica do link (sem tráfego concorrente)
- **Throughput**: tráfego real passando pelo link no momento

### 8. airTime
Porcentagem de tempo que o rádio está ocupado transmitindo/recebendo. Valores baixos indicam folga de capacidade; valores altos indicam congestionamento.

## Checklist de Execução

- [ ] Obter credenciais do vault (Secure Credential Access)
- [ ] Acessar URL do equipamento
- [ ] Fazer login (Nome de usuário + Senha)
- [ ] **Coletar dados do Dashboard** (Device + Link + gráficos)
- [ ] **Abrir Info e extrair detalhes do remoto PTP**
- [ ] **Abrir Log e analisar eventos**
- [ ] Tirar screenshots de documentação
- [ ] **Salvar relatório .md na Desktop** (automático, não perguntar)
- [ ] Encerrar sessão (Logout)
- [ ] Apresentar diagnóstico final ao usuário e informar caminho do arquivo

## Tempo Estimado de Execução

- **Login e coleta de dados:** 30-60 segundos
- **Análise e geração de relatório:** 15-30 segundos
- **Total:** ~1-2 minutos

## Troubleshooting

### Problema: Página não carrega
**Possíveis causas:**
- Equipamento offline ou sem conectividade de gerência
- Porta incorreta na URL (verificar vault)
- Firewall bloqueando acesso

**Solução:** Verificar se o IP+porta respondem via ping ou telnet antes de tentar acessar.

### Problema: Login falha
**Possíveis causas:**
- Credenciais incorretas no vault
- Sessão anterior não encerrada (limite de sessões)

**Solução:** Tentar novamente após alguns segundos. Verificar se as credenciais no vault estão atualizadas.

### Problema: Sinal baixo (-75 dBm ou pior)
**Possíveis causas:**
- Desalinhamento de antena
- Obstrução no caminho do sinal (árvores, construções)
- Interferência na frequência

**Solução:** Verificar alinhamento da antena. Usar ferramenta de alinhamento (Ferramentas > Alinhar antena). Considerar mudança de frequência.

### Problema: CINR baixo (< 15 dB)
**Possíveis causas:**
- Interferência de outros equipamentos na mesma frequência
- Ruído ambiental elevado

**Solução:** Usar Site Survey para verificar interferência. Considerar mudar para frequência mais limpa.

### Problema: Capacidade isolada baixa (< 50 Mbps)
**Possíveis causas:**
- Modulação baixa (sinal fraco)
- Channel Width estreito
- Interferência elevada

**Solução:** Primeiro resolver problemas de sinal e interferência. Se necessário, aumentar channel width (verificar regulamentação).

---

**Criado:** 2026-02-18
**Versão:** 1.0.0
**Autor:** Yan Marcos
**Licença:** MIT
