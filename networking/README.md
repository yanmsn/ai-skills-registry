# Networking Skills

Skills relacionadas a redes, roteadores, WiFi, configuração de rede e troubleshooting.

## Skills Disponíveis

### Router WiFi Extractor
- **Versão:** 1.0.0
- **Descrição:** Acessa painéis de administração de roteadores e extrai informações de WiFi (SSID e senhas)
- **Autor:** Yan Marcos
- **Compatibilidade:** Datacom DM986-204, TP-Link, D-Link, Intelbras

[📁 Ver Skill](./router-wifi-extractor/)

### Router WiFi Configurator
- **Versão:** 1.0.0
- **Descrição:** Altera configurações de redes WiFi em roteadores (SSID, senha, segurança)
- **Autor:** Yan Marcos
- **Compatibilidade:** Datacom DM986-204, TP-Link, D-Link

[📁 Ver Skill](./router-wifi-configurator/)

### Router Reboot
- **Versão:** 1.0.0
- **Descrição:** Reinicia roteadores através do painel de administração web de forma automatizada
- **Autor:** Yan Marcos
- **Compatibilidade:** Datacom DM986-204, TP-Link, D-Link, Intelbras

[📁 Ver Skill](./router-reboot/)

### Router WAN Configurator
- **Versão:** 1.0.0
- **Descrição:** Configura a conexão WAN do roteador (PPPoE, IPoE, Bridge, VLAN) de forma automatizada
- **Autor:** Yan Marcos
- **Compatibilidade:** Datacom DM986-204 (FTTH)

[📁 Ver Skill](./router-wan-configurator/)

## Como Usar

1. Navegue até a pasta da skill desejada
2. Leia o arquivo `SKILL.md` para instruções detalhadas
3. Instale usando o script de gerenciamento:
   ```powershell
   ..\scripts\manage-skills.ps1 -Action Install -Source ".\nome-da-skill"
   ```

## Contribuindo

Tem uma skill de networking para compartilhar? Veja o [guia de contribuição](../README.md#contribuindo).
