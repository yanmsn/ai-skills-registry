# set-wan.ps1 — Configura VLAN e PPPoE WAN do Datacom DM986-204 via HTTP puro
# Uso: .\set-wan.ps1 [-VlanID 2603] [-PPPoEUser usuario@isp] [-PPPoEPass NovaSenha]

param(
    [string]$IP        = "192.168.28.1",
    [string]$User      = "user",
    [string]$Pass      = "user-GW-24",
    [int]$VlanID       = -1,   # -1 = manter VLAN ID atual
    [string]$PPPoEUser = "",   # "" = manter usuario PPPoE atual
    [string]$PPPoEPass = ""    # "" = manter senha PPPoE atual (firmware recebe **** e preserva)
)

if ($VlanID -eq -1 -and -not $PPPoEUser -and -not $PPPoEPass) {
    Write-Host "Uso: .\set-wan.ps1 [-VlanID 2603] [-PPPoEUser usuario@isp] [-PPPoEPass NovaSenha]" -ForegroundColor Yellow
    Write-Host "Exemplo: .\set-wan.ps1 -VlanID 100 -PPPoEUser usuario@isp -PPPoEPass MinhaSenha"
    exit 1
}

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

function To-Base64([string]$s) {
    return [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($s))
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
} catch {
    Write-Error "Login falhou: $_"; exit 1
}

if ($r.BaseResponse.ResponseUri.AbsoluteUri -match "login\.asp" -or $r.Content -match "Invalid Password") {
    Write-Error "Login falhou. Verifique usuario e senha."; exit 1
}

Write-Host "[+] Login OK" -ForegroundColor Green

# ---------------------------------------------------------------------------
# 2. LER CONFIGURACAO WAN ATUAL
# Os valores sao injetados por JS a partir do array "links" na pagina;
# os campos <input> nao tem atributo value no HTML bruto.
# pppUsername e armazenado em Base64 (mesmo padrao das senhas WiFi).
# ---------------------------------------------------------------------------
Write-Host "[*] Lendo configuracao WAN atual..." -ForegroundColor Cyan

$wanHtml = (Invoke-WebRequest "$base/multi_wan_generic.asp" -WebSession $sess -UseBasicParsing).Content

# VLAN ID: extraido do array JS — new it("vid", 2603)
$curVid = if ($wanHtml -match 'new it\("vid",\s*(\d+)\)') { [int]$Matches[1] } else { 0 }

# Usuario PPPoE: armazenado como Base64 — new it("pppUsername", "eWFu...")
$curPPPoEUser = if ($wanHtml -match 'new it\("pppUsername",\s*"([^"]+)"\)') {
                    [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Matches[1]))
                } else { "" }

# Nome do link WAN: primeiro argumento de it_nr — new it_nr("ppp0_nas0_0", ...)
$curLst = if ($wanHtml -match 'new it_nr\("([^"]+)"') { $Matches[1] } else { "ppp0_nas0_0" }

Write-Host "  VLAN ID atual : $curVid"
Write-Host "  PPPoE User    : $curPPPoEUser"
Write-Host "  Link name     : $curLst"

# ---------------------------------------------------------------------------
# 3. APLICAR OVERRIDES
# ---------------------------------------------------------------------------
$finalVid  = if ($VlanID -ne -1) { $VlanID } else { $curVid }
$finalUser = if ($PPPoEUser)     { $PPPoEUser } else { $curPPPoEUser }

# encodePppUserName: sempre enviado com Base64 do usuario (campo pppUserName nunca e enviado)
# encodePppPassword: Base64 da nova senha, ou vazio se senha nao muda
$encUser = To-Base64 $finalUser
$encPass = if ($PPPoEPass) { To-Base64 $PPPoEPass } else { "" }

# ---------------------------------------------------------------------------
# 4. POST /boaform/admin/formWanEth
#
# Regras do firmware (replicando disableUsernamePassword() do JS):
#  - pppUserName: SEMPRE ausente do body (o firmware sempre o desabilita antes do submit)
#  - pppPassword: incluido APENAS quando a senha nao muda (valor "**********")
#                 se uma nova senha for fornecida, pppPassword e desabilitado e
#                 apenas encodePppPassword (Base64) e enviado
# ---------------------------------------------------------------------------
Write-Host "[*] Aplicando configuracoes WAN..." -ForegroundColor Cyan

# Campo pppPassword: presente com stars (senha inalterada) ou ausente (senha nova)
$pppPassSegment = if ($PPPoEPass) { "" } else { "&pppPassword=**********" }

$iv = "lkname=0&vlan=ON&vid=$finalVid&vprio=0&multicast_vid=&adslConnectionMode=2" +
      "&naptEnabled=ON&chEnable=1&ctype=2&mtu=1492&droute=1&IpProtocolType=3" +
      "$pppPassSegment&pppConnectType=0&auth=0" +
      "&acName=&serviceName=&dnsMode=0&dns1=&dns2=&gwStr=&gwStr=&wanIf=undefined" +
      "&SixrdBRv4IP=&SixrdIPv4MaskLen=&SixrdPrefix=&SixrdPrefixLen=" +
      "&AddrMode=1&Ipv6Addr=&Ipv6PrefixLen=&Ipv6Gateway=&iapd=ON&dnsV6Mode=1" +
      "&dslite_aftr_hostname=&submit-url=%2Fadmin%2Fmulti_wan_generic.asp" +
      "&lst=$(Encode-Field $curLst)&encodePppUserName=$(Encode-Field $encUser)&encodePppPassword=$(Encode-Field $encPass)&apply=Apply+Changes&itfGroup=0&"

$body = $iv + "postSecurityFlag=$(Get-PostSecurityFlag $iv)"

try {
    $r = Invoke-WebRequest "$base/boaform/admin/formWanEth" `
         -Method POST -Body $body `
         -ContentType 'application/x-www-form-urlencoded' `
         -WebSession $sess -UseBasicParsing
    Write-Host "[+] Configuracao WAN aplicada com sucesso" -ForegroundColor Green
    if ($VlanID -ne -1) { Write-Host "  VLAN ID    : $finalVid" }
    if ($PPPoEUser)     { Write-Host "  PPPoE User : $finalUser" }
    if ($PPPoEPass)     { Write-Host "  PPPoE Pass : alterada" }
} catch {
    Write-Error "Erro ao aplicar configuracao WAN: $_"; exit 1
}

# ---------------------------------------------------------------------------
# 5. VERIFICACAO FINAL
# ---------------------------------------------------------------------------
Write-Host "`n[*] Verificando resultado..." -ForegroundColor Cyan

$wanHtml2 = (Invoke-WebRequest "$base/multi_wan_generic.asp" -WebSession $sess -UseBasicParsing).Content

$newVid  = if ($wanHtml2 -match 'new it\("vid",\s*(\d+)\)') { $Matches[1] } else { "N/D" }
$newUser = if ($wanHtml2 -match 'new it\("pppUsername",\s*"([^"]+)"\)') {
               [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Matches[1]))
           } else { "N/D" }

Write-Host "`n===== Estado atual WAN - Datacom DM986-204 ($IP) =====`n" -ForegroundColor Yellow
[PSCustomObject]@{
    'Modo'      = 'PPPoE'
    'VLAN ID'   = $newVid
    'PPPoE User'= $newUser
    'MTU'       = '1492'
    'Link'      = $curLst
} | Format-List
