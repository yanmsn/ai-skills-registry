# set-wifi.ps1 — Altera SSID e/ou senha WiFi do Datacom DM986-204 via HTTP puro
# Uso: .\set-wifi.ps1 [-SSID24 NovoNome] [-SSID5 NovoNome5G] [-Senha24 NovaSenha] [-Senha5 NovaSenha5G]

param(
    [string]$IP        = "192.168.0.1",
    [string]$User      = "user",
    [string]$Pass      = "user",
    [string]$SSID24  = "",   # Novo SSID 2.4GHz  (omitir = manter atual)
    [string]$SSID5   = "",   # Novo SSID 5GHz    (omitir = manter atual)
    [string]$Senha24 = "",   # Nova senha 2.4GHz (omitir = manter atual)
    [string]$Senha5  = ""    # Nova senha 5GHz   (omitir = manter atual)
)

if (-not $SSID24 -and -not $SSID5 -and -not $Senha24 -and -not $Senha5) {
    Write-Host "Uso: .\set-wifi.ps1 [-SSID24 Nome] [-SSID5 Nome5G] [-Senha24 Senha] [-Senha5 Senha5G]" -ForegroundColor Yellow
    Write-Host "Exemplo: .\set-wifi.ps1 -SSID24 MinhaRede -SSID5 MinhaRede-5G -Senha24 SenhaSegura123 -Senha5 SenhaSegura123"
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

# Replica encodeURIComponent do JS
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
} catch {
    Write-Error "Login falhou: $_"; exit 1
}

if ($r.BaseResponse.ResponseUri.AbsoluteUri -match "login\.asp" -or $r.Content -match "Invalid Password") {
    Write-Error "Login falhou. Verifique usuario e senha."; exit 1
}

Write-Host "[+] Login OK" -ForegroundColor Green

# ---------------------------------------------------------------------------
# 2. ALTERAR SSID  →  POST /boaform/formWlanSetup
#
# Campos do inputVal (descobertos via inspeção do formulário wlbasic.asp):
#   - band:             75 (5GHz A+N+AC) | 10 (2.4GHz B+G+N)
#   - chanwid:          2  (80MHz, 5G)   |  1 (40MHz, 2.4G)
#   - Band2G5GSupport:  2  (5GHz)        |  1 (2.4GHz)
# ---------------------------------------------------------------------------
function Set-WlanSSID {
    param([int]$Idx, [string]$NewSSID, [string]$BandLabel)

    # Parâmetros que diferem por banda
    $band            = if ($Idx -eq 0) { "75" } else { "10" }
    $chanwid         = if ($Idx -eq 0) { "2"  } else { "1"  }
    $band2g5gsupport = if ($Idx -eq 0) { "2"  } else { "1"  }

    $ssidEnc = Encode-Field $NewSSID

    $iv = "band=$band&mode=0&ssid=$ssidEnc&chanwid=$chanwid&chan=0&txpower=0" +
          "&wl_limitstanum=0&wl_stanum=&regdomain_demo=1" +
          "&submit-url=%2Fadmin%2Fwlbasic.asp&save=Apply+Changes" +
          "&basicrates=0&operrates=0&wlan_idx=$Idx" +
          "&Band2G5GSupport=$band2g5gsupport&wlanBand2G5GSelect=0&dfs_enable=0&"

    $body = $iv + "postSecurityFlag=$(Get-PostSecurityFlag $iv)"

    try {
        $r = Invoke-WebRequest "$base/boaform/formWlanSetup" `
             -Method POST -Body $body `
             -ContentType 'application/x-www-form-urlencoded' `
             -WebSession $sess -UseBasicParsing
        Write-Host "[+] SSID $BandLabel alterado para '$NewSSID'" -ForegroundColor Green
    } catch {
        Write-Error "Erro ao alterar SSID $BandLabel : $_"
    }
}

# ---------------------------------------------------------------------------
# 3. ALTERAR SENHA  →  POST /boaform/admin/formWlEncrypt
#
# Campos do inputVal (descobertos via inspeção do formulário wlwpa.asp):
#   - pskValue:      senha em texto claro (URL-encoded)
#   - encodepskValue: btoa(senha) — Base64 (URL-encoded)
# Os demais campos são estáticos para configuração WPA2-PSK.
# ---------------------------------------------------------------------------
function Set-WlanPassword {
    param([int]$Idx, [string]$NewPass, [string]$BandLabel)

    if ($NewPass.Length -lt 8 -or $NewPass.Length -gt 63) {
        Write-Error "Senha deve ter entre 8 e 63 caracteres."; return
    }

    $pskEnc    = Encode-Field $NewPass
    $b64       = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($NewPass))
    $b64Enc    = Encode-Field $b64

    $iv = "wlanDisabled=OFF&isNmode=1&wpaSSID=0&security_method=4" +
          "&auth_type=both&wepEnabled=ON&length0=1&format0=1&key0=" +
          "&wpaAuth=psk&dotIEEE80211W=0&sha256=0&gk_rekey=86400" +
          "&pskFormat=0&pskValue=$pskEnc" +
          "&wapiPskFormat=0&wapiPskValue=&wepKeyLen=wep64" +
          "&radiusIP=0.0.0.0&radiusPort=1812&radiusPass=" +
          "&radius2IP=0.0.0.0&radius2Port=1812&radius2Pass=" +
          "&wapiASIP=0.0.0.0&wlan_idx=$Idx" +
          "&submit-url=%2Fadmin%2Fwlwpa.asp" +
          "&encodekey0=&encodepskValue=$b64Enc" +
          "&encoderadiusPass=&encoderadius2Pass=" +
          "&save=Apply+Changes&"

    $body = $iv + "postSecurityFlag=$(Get-PostSecurityFlag $iv)"

    try {
        $r = Invoke-WebRequest "$base/boaform/admin/formWlEncrypt" `
             -Method POST -Body $body `
             -ContentType 'application/x-www-form-urlencoded' `
             -WebSession $sess -UseBasicParsing
        Write-Host "[+] Senha $BandLabel alterada" -ForegroundColor Green
    } catch {
        Write-Error "Erro ao alterar senha $BandLabel : $_"
    }
}

# ---------------------------------------------------------------------------
# 4. APLICAR ALTERACOES
# ---------------------------------------------------------------------------
Write-Host "[*] Aplicando alteracoes..." -ForegroundColor Cyan

if ($SSID24)  { Set-WlanSSID      -Idx 1 -NewSSID  $SSID24  -BandLabel "2.4GHz" }
if ($Senha24) { Set-WlanPassword  -Idx 1 -NewPass  $Senha24  -BandLabel "2.4GHz" }
if ($SSID5)   { Set-WlanSSID      -Idx 0 -NewSSID  $SSID5   -BandLabel "5GHz"   }
if ($Senha5)  { Set-WlanPassword  -Idx 0 -NewPass  $Senha5   -BandLabel "5GHz"   }

# ---------------------------------------------------------------------------
# 5. VERIFICACAO FINAL
# ---------------------------------------------------------------------------
Write-Host "`n[*] Verificando resultado..." -ForegroundColor Cyan

$redirect = "$base/boaform/formWlanRedirect?redirect-url="

function Read-BandResult([int]$Idx, [string]$Band) {
    $basic = (Invoke-WebRequest "${redirect}/wlbasic.asp&wlan_idx=$Idx" -WebSession $sess -UseBasicParsing).Content
    $sec   = (Invoke-WebRequest "${redirect}/wlwpa.asp&wlan_idx=$Idx"  -WebSession $sess -UseBasicParsing).Content

    $ssid = if ($basic -match 'name="ssid"[^>]*value="([^"]*)"') { $Matches[1] }
            elseif ($basic -match '<input[^>]+value="([^"]+)"[^>]+name="ssid"') { $Matches[1] }
            elseif ($basic -match 'type=.?text.?[^>]+value="([^"]{2,32})"') { $Matches[1] }
            else { "N/D" }
    $psk  = if ($sec   -match "_wpaPSK\[0\]='([^']+)'") {
                [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Matches[1]))
            } else { "N/D" }

    [PSCustomObject]@{ Banda = $Band; SSID = $ssid; Senha = $psk }
}

$results = @(
    (Read-BandResult -Idx 0 -Band "5 GHz"),
    (Read-BandResult -Idx 1 -Band "2.4 GHz")
)

Write-Host "`n===== Estado atual - Datacom DM986-204 ($IP) =====`n" -ForegroundColor Yellow
$results | Format-Table -AutoSize
