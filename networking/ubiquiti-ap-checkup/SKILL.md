---
name: Ubiquiti AP Checkup
description: Acessa painéis AirOS de antenas Ubiquiti (Rocket M5) e realiza checkup completo de saúde, extraindo métricas de desempenho, sinal, estações e interfaces para análise de qualidade do serviço.
version: 1.1.0
author: Yan Marcos
category: networking
tags: [ubiquiti, airmax, rocket-m5, airos, antenna, checkup, monitoring, wireless-isp]
---

# Ubiquiti AP Checkup Skill

Esta skill permite acessar a interface web AirOS de antenas Ubiquiti (como Rocket M5) para realizar um **checkup completo de saúde** do equipamento. O objetivo é coletar e analisar métricas de desempenho, sinal, estações conectadas e tráfego de interfaces, garantindo a qualidade do serviço de internet sem fio para residências.

## Quando Usar

Use esta skill quando o usuário solicitar:
- Checkup/diagnóstico de uma antena Ubiquiti
- Verificar a saúde de um AP (Access Point)
- Analisar qualidade do sinal wireless
- Verificar estações (clientes) conectadas
- Monitorar uso de CPU/memória da antena
- Analisar tráfego de rede na antena
- Verificar logs de eventos do equipamento

## Equipamento Compatível

| Propriedade        | Valor                              |
|--------------------|-------------------------------------|
| **Fabricante**     | Ubiquiti Networks                  |
| **Modelo**         | Rocket M5                          |
| **Firmware**       | AirOS v6.x (testado com v6.1.7)   |
| **Frequência**     | 5 GHz                             |
| **Modo**           | Access Point WDS (Bridge)          |
| **Interface**      | Web (HTTP) via porta customizada   |

## Pré-requisitos

1. **Credenciais** — Usar a skill `Secure Credential Access` para obter usuário/senha do vault Obsidian (`Passwords/[NOME_DO_SERVICO].md`).
2. **Conectividade** — O computador deve ter acesso à rede de gerência do equipamento.
3. **Playwright MCP** — Deve estar instalado e configurado.

## Informações Necessárias

Antes de executar, você precisa:
1. **Nome do serviço no vault** (ex: `G5-NNC1-AP04`) — para buscar credenciais
2. As credenciais no vault contêm: `url`, `username`, `password`

## Estrutura da Interface AirOS

A interface AirOS possui a seguinte navegação:

### Abas Principais (Menu Superior)
| Aba          | URL           | Conteúdo                                        |
|--------------|---------------|--------------------------------------------------|
| **MAIN**     | `index.cgi`   | Estado geral, métricas de desempenho, gráficos  |
| **WIRELESS** | `link.cgi`    | Configurações de rádio e segurança               |
| **NETWORK**  | `network.cgi` | Configurações de rede (IP, Bridge, MTU)          |
| **ADVANCED** | `advanced.cgi`| Configurações avançadas                          |
| **SERVICES** | `services.cgi`| Serviços do sistema                              |
| **SYSTEM**   | `system.cgi`  | Firmware, manutenção, backup                     |

### Links de Monitoramento (Dentro da aba MAIN)
| Link              | URL             | Conteúdo                                    |
|-------------------|-----------------|----------------------------------------------|
| **Débito**        | `throughput.cgi`| Gráficos de throughput WLAN0 e LAN0          |
| **Estações**      | `stalist.cgi`  | Lista de clientes conectados com métricas    |
| **Interfaces**    | `ifaces.cgi`   | Tráfego por interface (bytes TX/RX, erros)   |
| **Tabela ARP**    | `arp.cgi`      | Tabela ARP do equipamento                    |
| **Tabela Bridge** | `brmacs.cgi`   | MACs na bridge                               |
| **Rotas**         | `sroutes.cgi`  | Tabela de rotas                              |
| **Registo**       | `log.cgi`      | Logs do sistema                              |

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

A página de login possui:
- **Campo de usuário**: `textbox "Nome de utilizador:"`
- **Campo de senha**: `textbox "Palavra-passe:"`
- **Botão de login**: `button "Iniciar sessão"`

```javascript
// Preencher formulário de login
// Usar browser_fill_form com os refs corretos
// Campo usuário: textbox "Nome de utilizador:"
// Campo senha: textbox "Palavra-passe:"
// Botão login: button "Iniciar sessão"
```

**IMPORTANTE**: Nunca exibir credenciais no chat. Usar browser_fill_form passando os valores diretamente.

### Passo 3: Coletar Dados da Página Principal (MAIN)

Após o login, a página principal (`index.cgi`) exibe o painel "Estado" com as seguintes métricas:

#### Informações do Dispositivo (lado esquerdo):
| Campo                        | Exemplo de Valor                |
|------------------------------|----------------------------------|
| Modelo do dispositivo        | Rocket M5                       |
| Nome do dispositivo          | G5_NNC1-ap4                     |
| Modo de rede                 | Bridge                          |
| Modo Sem Fios                | Ponto de acesso WDS             |
| SSID                         | G5_NNC1-ap4                     |
| Segurança                    | WPA2-AES                        |
| Versão                       | v6.1.7-licensed.32555 (XM)      |
| Tempo de atividade           | 3 dias 23:51:10                 |
| Data                         | 2018-05-27 04:31:03             |
| Canal/frequência             | 140 / 5700 MHz                  |
| Amplitude de canal           | 20 MHz                          |
| Banda de frequências         | 5690 - 5710 MHz                 |
| Distância                    | 0.7 milhas (1.1 km)             |
| Cadeias transmissão/receção  | 2X2                             |
| Energia de transmissão       | 27 dBm                          |
| Antena                       | AM-5G19-120 - 19 dBi            |
| WLAN0 MAC                    | 24:A4:3C:44:DE:95               |
| LAN0 MAC                     | 24:A4:3C:45:DE:95               |
| LAN0                         | 100Mbps-Completo                |

#### Métricas de Desempenho (lado direito):
| Campo                  | Exemplo de Valor      |
|------------------------|-----------------------|
| CPU                    | 6 %                   |
| Memory                 | 33 %                  |
| AP MAC                 | 24:A4:3C:44:DE:95     |
| Ligações               | 1                     |
| Ruído de fundo         | -91 dBm               |
| CCQ de transmissão     | 99.1 %                |
| airMAX                 | Ativado               |
| Qualidade do airMAX    | 62 %                  |
| Capacidade do airMAX   | 23 %                  |
| airSelect              | Desativado            |
| UNMS                   | Desativado            |

#### Gráficos de Throughput (parte inferior):
- **WLAN0**: RX e TX em kbps/Mbps (tráfego wireless)
- **LAN0**: RX e TX em kbps/Mbps (tráfego cabeado)

### Passo 4: Coletar Lista de Estações

Clicar no link **"Estações"** na seção Monitorizar para ver os clientes conectados.

A tabela de estações possui as seguintes colunas:
| Coluna                    | Descrição                                      |
|---------------------------|-------------------------------------------------|
| MAC da estação            | Endereço MAC do cliente                         |
| Nome do dispositivo       | Nome configurado no CPE do cliente               |
| Sinal de transmissão, dBm | Sinal TX combinado (do AP para o cliente)       |
| Sinal de receção, dBm    | Sinal RX combinado (do cliente para o AP)        |
| Ruído, dBm               | Nível de ruído                                   |
| Latência, ms             | Latência do link                                 |
| Distância, milhas        | Distância estimada do cliente                    |
| Transmissão/receção, Mbps| Taxa de TX/RX em Mbps                            |
| CCQ, %                   | Client Connection Quality                        |
| Ligação Hora             | Tempo de conexão ininterrupta                    |
| Último IP                | Último IP conhecido do cliente                   |
| Ação                     | Link para desligar o cliente                     |

### Passo 5: Coletar Dados de Interfaces

Clicar no link **"Interfaces"** na seção Monitorizar.

A tabela de interfaces mostra:
| Interface | Endereço MAC        | MTU  | Endereço IP    | Bytes RX | Erros RX | Bytes TX | Erros TX |
|-----------|---------------------|------|----------------|----------|----------|----------|----------|
| BRIDGE0   | 24:A4:3C:44:DE:95  | 1500 | 172.100.10.60  | 0.15G    | 0        | 10.5M    | 0        |
| LAN0      | 24:A4:3C:45:DE:95  | 1500 | 0.0.0.0        | 1.91G    | 0        | 0.34G    | 0        |
| WLAN0     | 24:A4:3C:44:DE:95  | 1500 | 0.0.0.0        | 0.37G    | 0        | 1.95G    | 0        |

### Passo 6: Verificar Logs do Sistema

Clicar no link **"Registo"** na seção Monitorizar para ver eventos recentes.

Procurar nos logs por:
- **Eventos de desconexão/reconexão** de estações (`deauthenticated`, `disassociated`)
- **Erros de handshake** (`handshake completed` vs erros)
- **Received deauth** — indica desconexões involuntárias
- **Logins administrativos** (`Password with succeeded`)
- **Eventos de sistema** (`system: Start`, `syslogd started`)

### Passo 7: Salvar Relatório em Arquivo Markdown

Após coletar todos os dados e gerar a análise, **SEMPRE** salvar o relatório como arquivo `.md` na área de trabalho do usuário.

**Padrão de nome do arquivo:**
```
[NOME_DO_DISPOSITIVO]_checkup_[YYYY-MM-DD].md
```

**Exemplo:**
```
C:\Users\Yan\Desktop\G5_NNC1-ap4_checkup_2026-02-18.md
```

**Regras:**
1. O arquivo DEVE ser salvo automaticamente — **não perguntar** ao usuário se deseja salvar.
2. Usar a data atual (real) do checkup, não a data do equipamento.
3. Seguir o template da seção "Template do Relatório de Checkup" com todos os dados coletados preenchidos.
4. Incluir no rodapé: `*Relatório gerado automaticamente pela skill Ubiquiti AP Checkup v1.1.0*`
5. Informar ao usuário o caminho do arquivo salvo após a geração.

### Passo 8: Encerrar Sessão

```javascript
// Clicar em "Terminar sessão"
// button "Terminar sessão"
```

## Extração de Dados via JavaScript

Para extração programática dos dados da página principal, use `browser_run_code` ou `browser_evaluate`:

```javascript
async (page) => {
  // Extrair todos os pares chave-valor do painel Estado
  const data = await page.evaluate(() => {
    const result = {};
    // Os dados estão em divs com pares de label/valor
    const rows = document.querySelectorAll('#sta_basic .row, .sta-data .row');
    // Fallback: extrair do texto geral
    const statusText = document.body.innerText;
    
    // Campos específicos usando regex no texto
    const patterns = {
      'modelo': /Modelo do dispositivo:\s*(.+)/,
      'nome': /Nome do dispositivo:\s*(.+)/,
      'uptime': /Tempo de atividade:\s*(.+)/,
      'cpu': /CPU:\s*(\d+)\s*%/,
      'memory': /Memory:\s*(\d+)\s*%/,
      'ligacoes': /Ligações:\s*(\d+)/,
      'ruido': /Ruído de fundo:\s*(-?\d+)\s*dBm/,
      'ccq': /CCQ de transmissão:\s*([\d.]+)\s*%/,
      'airmax_quality': /Qualidade do airMAX:\s*(\d+)\s*%/,
      'airmax_capacity': /Capacidade do airMAX:\s*(\d+)\s*%/,
      'canal': /Canal\/frequência:\s*(\d+)\s*\/\s*(\d+)\s*MHz/,
      'tx_power': /Energia de transmissão:\s*(\d+)\s*dBm/,
      'lan_speed': /LAN0:\s*(.+)/,
    };
    
    for (const [key, regex] of Object.entries(patterns)) {
      const match = statusText.match(regex);
      if (match) result[key] = match.slice(1).join('/');
    }
    
    return result;
  });
  
  return data;
}
```

## Critérios de Análise e Limiares

Use os seguintes limiares para avaliar a saúde do equipamento:

### 🟢 Normal (OK)
| Métrica            | Faixa Aceitável         |
|--------------------|--------------------------|
| CPU                | 0 - 40%                 |
| Memória            | 0 - 60%                 |
| CCQ Transmissão    | > 80%                   |
| Qualidade airMAX   | > 50%                   |
| Capacidade airMAX  | > 15%                   |
| Ruído de fundo     | < -85 dBm (mais negativo = melhor) |
| Latência estação   | < 5 ms                  |
| Erros de interface | 0                        |
| LAN0 Speed         | 100Mbps-Completo         |

### 🟡 Atenção
| Métrica            | Faixa de Atenção         |
|--------------------|--------------------------|
| CPU                | 40 - 70%                |
| Memória            | 60 - 80%                |
| CCQ Transmissão    | 60 - 80%                |
| Qualidade airMAX   | 30 - 50%                |
| Capacidade airMAX  | 10 - 15%                |
| Ruído de fundo     | -85 a -75 dBm           |
| Latência estação   | 5 - 15 ms               |

### 🔴 Crítico
| Métrica            | Faixa Crítica            |
|--------------------|--------------------------|
| CPU                | > 70%                   |
| Memória            | > 80%                   |
| CCQ Transmissão    | < 60%                   |
| Qualidade airMAX   | < 30%                   |
| Capacidade airMAX  | < 10%                   |
| Ruído de fundo     | > -75 dBm               |
| Latência estação   | > 15 ms                 |
| Erros de interface | > 0                      |
| LAN0 Speed         | 10Mbps ou Half-Duplex   |

### Sinal das Estações (CPEs)
| Faixa de Sinal     | Qualidade   | Cor   |
|--------------------|-------------|-------|
| -50 a -60 dBm     | Excelente   | 🟢    |
| -60 a -70 dBm     | Bom         | 🟢    |
| -70 a -75 dBm     | Aceitável   | 🟡    |
| -75 a -80 dBm     | Fraco       | 🟡    |
| -80 a -85 dBm     | Muito Fraco | 🔴    |
| Pior que -85 dBm  | Crítico     | 🔴    |

## Template do Relatório de Checkup

Após coletar todos os dados, apresente o relatório no seguinte formato:

```markdown
# 📡 Relatório de Checkup — [NOME_DO_DISPOSITIVO]

**Data do Checkup:** [DATA_ATUAL]
**Equipamento:** [MODELO] — [NOME]
**Firmware:** [VERSÃO]
**Uptime:** [TEMPO_DE_ATIVIDADE]

---

## 📊 Saúde Geral

| Métrica            | Valor     | Status |
|--------------------|-----------|--------|
| CPU                | X%        | 🟢/🟡/🔴 |
| Memória            | X%        | 🟢/🟡/🔴 |
| CCQ Transmissão    | X%        | 🟢/🟡/🔴 |
| Qualidade airMAX   | X%        | 🟢/🟡/🔴 |
| Capacidade airMAX  | X%        | 🟢/🟡/🔴 |
| Ruído de fundo     | -XX dBm   | 🟢/🟡/🔴 |
| Link LAN           | XXMbps    | 🟢/🟡/🔴 |

## 📻 Configuração de Rádio

| Parâmetro          | Valor                  |
|--------------------|-------------------------|
| Canal/Frequência   | XXX / XXXX MHz         |
| Amplitude de canal | XX MHz                 |
| Banda              | XXXX - XXXX MHz        |
| Potência TX        | XX dBm                 |
| Antena             | MODELO - XX dBi        |
| Segurança          | WPA2-AES               |
| airMAX             | Ativado/Desativado     |

## 👥 Estações Conectadas (X total)

| Nome               | MAC              | Sinal TX | Sinal RX | Ruído  | Latência | Dist.  | TX/RX Mbps | CCQ  | Uptime       | Status |
|--------------------|------------------|----------|----------|--------|----------|--------|------------|------|--------------|--------|
| [NOME]             | XX:XX:XX:XX:XX:XX| -XX dBm  | -XX dBm  | -XX dBm| X ms     | X.X mi | XX / XX    | XX%  | X dias XX:XX | 🟢/🟡/🔴 |

## 🔌 Interfaces de Rede

| Interface | MAC               | IP             | RX      | Erros RX | TX      | Erros TX | Status |
|-----------|-------------------|----------------|---------|----------|---------|----------|--------|
| BRIDGE0   | XX:XX:XX:XX:XX:XX | XXX.XXX.XXX.XX | X.XXG   | 0        | X.XXG   | 0        | 🟢/🔴  |
| LAN0      | XX:XX:XX:XX:XX:XX | 0.0.0.0        | X.XXG   | 0        | X.XXG   | 0        | 🟢/🔴  |
| WLAN0     | XX:XX:XX:XX:XX:XX | 0.0.0.0        | X.XXG   | 0        | X.XXG   | 0        | 🟢/🔴  |

## 📋 Análise de Logs

- **Desconexões recentes:** X eventos nos últimos Y horas
- **Handshakes:** OK / Falhas detectadas
- **Logins administrativos:** X acessos recentes
- **Eventos críticos:** [DETALHES]

## 🏁 Diagnóstico Final

**Status Geral:** 🟢 SAUDÁVEL / 🟡 ATENÇÃO NECESSÁRIA / 🔴 AÇÃO URGENTE

### Observações:
- [OBSERVAÇÃO 1]
- [OBSERVAÇÃO 2]

### Recomendações:
- [RECOMENDAÇÃO 1]
- [RECOMENDAÇÃO 2]
```

## Navegação Detalhada — Seletores e Referências

### Página de Login (`login.cgi`)
```yaml
Campo usuário: textbox "Nome de utilizador:"
Campo senha:   textbox "Palavra-passe:"
Botão login:   button "Iniciar sessão"
```

### Menu Principal (superior)
```yaml
MAIN:       link "Principal"     → url: index.cgi
WIRELESS:   link "Sem Fios"      → url: link.cgi
NETWORK:    link "Rede"          → url: network.cgi
ADVANCED:   link "Avançadas"     → url: advanced.cgi
SERVICES:   link "Serviços"      → url: services.cgi
SYSTEM:     link "Sistema"       → url: system.cgi
```

### Links de Monitoramento (dentro de MAIN)
```yaml
Débito:         link "Débito"           → url: throughput.cgi
Estações:       link "Estações"         → url: stalist.cgi
Interfaces:     link "Interfaces"       → url: ifaces.cgi
Tabela ARP:     link "Tabela ARP"       → url: arp.cgi
Tabela Bridge:  link "Tabela de bridge" → url: brmacs.cgi
Rotas:          link "Rotas"            → url: sroutes.cgi
Registo:        link "Registo"          → url: log.cgi
```

### Ferramentas (dropdown superior direito)
```yaml
Alinhar antena:    option "Alinhar a antena..."
Inquérito do site: option "Inquérito do site..."
Descoberta:        option "Descoberta..."
Ping:              option "Pingue..."
Traceroute:        option "Traceroute..."
Teste velocidade:  option "Teste de velocidade..."
airView:           option "airView..."
```

### Botões de Ação
```yaml
Atualizar dados:    button "Atualizar"
Encerrar sessão:    button "Terminar sessão"
```

## Dicas Importantes

### 1. Interface em Português (Portugal)
A interface AirOS pode estar em Português de Portugal. Os termos são ligeiramente diferentes do Português do Brasil:
- "Sem Fios" = Wireless
- "Palavra-passe" = Senha
- "Iniciar sessão" = Login
- "Terminar sessão" = Logout
- "Ligações" = Conexões
- "Ruído de fundo" = Noise Floor
- "Débito" = Throughput
- "Registo" = Log
- "Amplitude de canal" = Channel Width

### 2. Data do Sistema pode estar incorreta
O relógio do equipamento pode não estar sincronizado (ex: mostrando 2018). Isso não afeta o funcionamento, mas o uptime é confiável.

### 3. Sem iframes
Diferente de roteadores Datacom, a interface AirOS **NÃO usa iframes**. Todos os elementos estão na página principal, facilitando a interação direta.

### 4. Atualização dos dados
Os dados na página principal atualizam automaticamente em intervalos. Pode-se forçar a atualização clicando no botão **"Atualizar"**.

### 5. Uma única estação conectada pode ser normal
No modelo ponto-a-ponto ou ponto-a-multiponto com poucos clientes, ter apenas 1 estação conectada é normal. Cada "estação" pode ser um CPE que serve múltiplas residências.

## Checklist de Execução

- [ ] Obter credenciais do vault (Secure Credential Access)
- [ ] Acessar URL do equipamento
- [ ] Fazer login (Nome de utilizador + Palavra-passe)
- [ ] **Coletar dados da página MAIN** (Estado geral)
- [ ] **Verificar Estações** (clientes conectados)
- [ ] **Verificar Interfaces** (tráfego e erros)
- [ ] **Verificar Logs** (eventos recentes)
- [ ] Tirar screenshots de documentação
- [ ] **Salvar relatório .md na Desktop** (automático, não perguntar)
- [ ] Encerrar sessão (Terminar sessão)
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

### Problema: Valores de throughput muito baixos
**Possíveis causas:**
- Pouco tráfego no momento da verificação (normal fora de horários de pico)
- Problemas de sinal ou interferência

**Solução:** Comparar com valores típicos para o horário. Verificar qualidade airMAX e CCQ.

### Problema: Muitas desconexões nos logs
**Possíveis causas:**
- Interferência no canal
- Sinal fraco no CPE do cliente
- Instabilidade elétrica no cliente

**Solução:** Verificar o sinal da estação na tabela. Se fraco, pode ser necessário realinhar a antena do cliente.

---

**Criado:** 2026-02-18
**Atualizado:** 2026-02-18
**Versão:** 1.1.0
**Autor:** Yan Marcos
**Licença:** MIT
