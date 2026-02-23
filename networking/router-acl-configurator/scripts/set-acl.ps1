# set-acl.ps1 — Configura IPv4 ACL (acesso remoto WAN) no Datacom DM986-204
# Adiciona uma entrada separada por servico: HTTP, HTTPS e opcionalmente PING.
# Uso: .\set-acl.ps1 [-HttpPort 8080] [-HttpsPort 443] [-Ping $true]

param(
    [string]$IP         = "192.168.28.1",
    [string]$User       = "user",
    [string]$Pass       = "user-GW-24",
    [int]$HttpPort      = 8080,
    [int]$HttpsPort     = 443,
    [bool]$Ping         = $true
)

$ProgressPreference = 'SilentlyContinue'
$base = "http://$IP"

# ---------------------------------------------------------------------------
# Checksum 16-bit one's complement (replica postTableEncrypt do firmware)
# ---------------------------------------------------------------------------
function Get-PostSecurityFlag([string]$InputVal) {
    [long]$csum = 0; $i = 0; $len = $InputVal.Length
    while ($i -lt $len) {
        if (($i + 4) -gt $len) {
            if ($i       -lt $len) { $csum += [long]([int][char]$InputVal[$i]   -shl 24) }
            if (($i + 1) -lt $len) { $csum += [long]([int][char]$InputVal[$i+1] -shl 16) }
            if (($i + 2) -lt $len) { $csum += [long]([int][char]$InputVal[$i+2] -shl  8) }
            break
        } else {
            $csum += [long]([int][char]$InputVal[$i]   -shl 24) +
                     [long]([int][char]$InputVal[$i+1] -shl 16) +
                     [long]([int][char]$InputVal[$i+2] -shl  8) +
                     [long]([int][char]$InputVal[$i+3])
            $i += 4
        }
    }
    $csum = ($csum -band 0xffff) + ($csum -shr 16)
    $csum = $csum -band 0xffff
    return [int]((-bnot $csum) -band 0xffff)
}

function Encode-Field([string]$v) {
    $e = [Uri]::EscapeDataString($v)
    $e = $e -replace '%20', '+'
    return $e
}

# ---------------------------------------------------------------------------
# 1. LOGIN
# ---------------------------------------------------------------------------
Write-Host "`n[*] Conectando a $base ..." -ForegroundColor Cyan

$iv   = "challenge=&username=$(Encode-Field $User)&password=$(Encode-Field $Pass)&save=Login&submit-url=%2Fadmin%2Flogin.asp&"
$body = $iv + "postSecurityFlag=$(Get-PostSecurityFlag $iv)"

try {
    $r = Invoke-WebRequest "$base/boaform/admin/formLogin" `
         -Method POST -Body $body `
         -ContentType 'application/x-www-form-urlencoded' `
         -SessionVariable sess -UseBasicParsing
} catch { Write-Error "Login falhou: $_"; exit 1 }

if ($r.BaseResponse.ResponseUri.AbsoluteUri -match "login\.asp" -or $r.Content -match "Invalid Password") {
    Write-Error "Login falhou. Verifique usuario e senha."; exit 1
}
Write-Host "[+] Login OK" -ForegroundColor Green

# ---------------------------------------------------------------------------
# 2. LER LAN IP E MASCARA DA PAGINA ACL
# Campos hidden que participam do checksum — lidos dinamicamente da pagina.
# ---------------------------------------------------------------------------
Write-Host "[*] Lendo configuracao ACL..." -ForegroundColor Cyan

$aclHtml = (Invoke-WebRequest "$base/acl.asp" -WebSession $sess -UseBasicParsing).Content

$lanIp   = if ($aclHtml -match 'name="lan_ip"[^>]*value="([^"]+)"')   { $Matches[1] }
            elseif ($aclHtml -match 'value="([^"]+)"[^>]*name="lan_ip"') { $Matches[1] }
            else { $IP }

$lanMask = if ($aclHtml -match 'name="lan_mask"[^>]*value="([^"]+)"')   { $Matches[1] }
            elseif ($aclHtml -match 'value="([^"]+)"[^>]*name="lan_mask"') { $Matches[1] }
            else { "255.255.255.0" }

Write-Host "  LAN IP   : $lanIp"
Write-Host "  LAN Mask : $lanMask"

# ---------------------------------------------------------------------------
# 3. HELPER — ADD de um unico servico via POST /boaform/admin/formACL
#
# Estrutura do inputVal (capturada do browser via postTableEncrypt):
#   - Campos de texto (port) sao SEMPRE incluidos, mesmo sem checkbox marcado
#   - Checkboxes so aparecem quando marcados
#   - Botao clicado: addIP=Add (isclick=1)
#   - Ordem dos campos segue a ordem dos elementos no formulario HTML
#
# Por servico:
#   HTTP  -> w_web=1  + w_web_port={HttpPort}  + w_https_port={HttpsPort} (sem w_https/w_icmp)
#   HTTPS -> w_https=1 + w_https_port={HttpsPort} + w_web_port={HttpPort}  (sem w_web/w_icmp)
#   PING  -> w_icmp=1 + w_web_port={HttpPort}  + w_https_port={HttpsPort} (sem w_web/w_https)
# ---------------------------------------------------------------------------
function Add-AclEntry {
    param([string]$Label, [string]$ServiceSegment)

    $iv = "lan_ip=$lanIp&lan_mask=$lanMask&aclcap=1&enable=1&interface=1&aclAllowAnyIP=1" +
          "&aclstartIP=&aclendIP=" +
          "&w_telnet_port=23&w_ftp_port=21&w_tftp_port=69" +
          $ServiceSegment +
          "&addIP=Add&submit-url=%2Fadmin%2Facl.asp&"

    $body = $iv + "postSecurityFlag=$(Get-PostSecurityFlag $iv)"

    try {
        Invoke-WebRequest "$base/boaform/admin/formACL" `
            -Method POST -Body $body `
            -ContentType 'application/x-www-form-urlencoded' `
            -WebSession $sess -UseBasicParsing | Out-Null
        Write-Host "[+] Entrada adicionada: $Label" -ForegroundColor Green
    } catch {
        Write-Error "Erro ao adicionar $Label : $_"
    }
}

# ---------------------------------------------------------------------------
# 4. ADICIONAR CADA SERVICO SEPARADAMENTE
# ---------------------------------------------------------------------------
Write-Host "[*] Adicionando entradas ACL (WAN / Any IP)..." -ForegroundColor Cyan

# HTTP — w_web=1 + w_web_port; w_https_port presente como campo de texto
Add-AclEntry "HTTP  (porta $HttpPort)" `
    "&w_web=1&w_web_port=$HttpPort&w_https_port=$HttpsPort"

# HTTPS — w_web_port presente como campo de texto; w_https=1 + w_https_port
Add-AclEntry "HTTPS (porta $HttpsPort)" `
    "&w_web_port=$HttpPort&w_https=1&w_https_port=$HttpsPort"

# PING — ambos port texts presentes; w_icmp=1 (sem porta propria)
if ($Ping) {
    Add-AclEntry "PING" `
        "&w_web_port=$HttpPort&w_https_port=$HttpsPort&w_icmp=1"
} else {
    Write-Host "[~] PING ignorado (-Ping `$false)" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# 5. APPLY CHANGES — confirma ACL Capability = Enable
#
# Enviado com o estado padrao do formulario (interface=LAN, sem servicos):
#   - interface=0 (LAN, valor default do select)
#   - w_web_port=80, w_https_port=443 (valores padrao dos campos de texto)
#   - Sem checkboxes de servico (nenhum marcado)
#   - Botao clicado: apply=Apply+Changes
# ---------------------------------------------------------------------------
Write-Host "[*] Aplicando configuracao ACL..." -ForegroundColor Cyan

$ivApply = "lan_ip=$lanIp&lan_mask=$lanMask&aclcap=1&apply=Apply+Changes&enable=1&interface=0" +
           "&aclstartIP=&aclendIP=" +
           "&w_telnet_port=23&w_ftp_port=21&w_tftp_port=69" +
           "&w_web_port=80&w_https_port=443" +
           "&submit-url=%2Fadmin%2Facl.asp&"

$bodyApply = $ivApply + "postSecurityFlag=$(Get-PostSecurityFlag $ivApply)"

try {
    Invoke-WebRequest "$base/boaform/admin/formACL" `
        -Method POST -Body $bodyApply `
        -ContentType 'application/x-www-form-urlencoded' `
        -WebSession $sess -UseBasicParsing | Out-Null
    Write-Host "[+] ACL aplicada com sucesso" -ForegroundColor Green
} catch {
    Write-Error "Erro ao aplicar ACL: $_"; exit 1
}

# ---------------------------------------------------------------------------
# 6. VERIFICACAO FINAL
# ---------------------------------------------------------------------------
Write-Host "`n[*] Verificando resultado..." -ForegroundColor Cyan

$aclHtml2 = (Invoke-WebRequest "$base/acl.asp" -WebSession $sess -UseBasicParsing).Content

$entries = [System.Collections.Generic.List[object]]::new()
$rowPattern = '<tr[^>]*>\s*<td[^>]*>.*?</td>\s*<td[^>]*>(Enable|Disable)</td>\s*<td[^>]*>([^<]+)</td>\s*<td[^>]*>([^<]+)</td>\s*<td[^>]*>([^<]+)</td>\s*<td[^>]*>([^<]*)</td>'
$matches2 = [regex]::Matches($aclHtml2, $rowPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
foreach ($m in $matches2) {
    $entries.Add([PSCustomObject]@{
        State      = $m.Groups[1].Value.Trim()
        Interface  = $m.Groups[2].Value.Trim()
        'IP Address' = $m.Groups[3].Value.Trim()
        Services   = $m.Groups[4].Value.Trim()
        Port       = $m.Groups[5].Value.Trim()
    })
}

Write-Host "`n===== IPv4 ACL - Datacom DM986-204 ($IP) =====`n" -ForegroundColor Yellow
if ($entries.Count -gt 0) {
    $entries | Format-Table -AutoSize
} else {
    Write-Host "(Nenhuma entrada encontrada - verifique manualmente em $base/acl.asp)"
}
