# get-wifi.ps1 — Extrai SSID e senha WiFi do Datacom DM986-204 via HTTP puro
# Uso: .\get-wifi.ps1 [-IP 192.168.0.1] [-User user] [-Pass suasenha]

param(
    [string]$IP   = "192.168.0.1",
    [string]$User = "user",
    [string]$Pass = "user"
)

$ProgressPreference = 'SilentlyContinue'
$base = "http://$IP"

# ---------------------------------------------------------------------------
# Calcula o postSecurityFlag (checksum 16-bit one's complement) que o
# firmware Realtek exige no corpo de todo POST autenticado.
# Replica exatamente o algoritmo de php-crypt-md5.js / postTableEncrypt().
# ---------------------------------------------------------------------------
function Get-PostSecurityFlag {
    param([string]$InputVal)

    [long]$csum = 0
    $i = 0
    $len = $InputVal.Length

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
    $csum = (-bnot $csum) -band 0xffff
    return [int]$csum
}

# Replica encodeURIComponent + substituições do JS
function Encode-Field { param([string]$v)
    $e = [Uri]::EscapeDataString($v)   # equivalente a encodeURIComponent
    $e = $e -replace '%21','%21'       # já está certo; listado por clareza
    $e = $e -replace '\+','%2B'        # EscapeDataString codifica + mas JS não — ajuste
    $e = $e -replace '%20','+'         # JS converte %20 → +
    return $e
}

# Monta o inputVal exatamente como o browser faria (sem postSecurityFlag/csrftoken)
function Build-LoginInputVal {
    param([string]$User, [string]$Pass)
    $fields = @(
        @{ n='challenge';  v='' },
        @{ n='username';   v=$User },
        @{ n='password';   v=$Pass },
        @{ n='save';       v='Login' },
        @{ n='submit-url'; v='/admin/login.asp' }
    )
    $parts = foreach ($f in $fields) { "$($f.n)=$(Encode-Field $f.v)" }
    return ($parts -join '&') + '&'
}

# ---------------------------------------------------------------------------
# 1. LOGIN
# ---------------------------------------------------------------------------
Write-Host "`n[*] Conectando a $base ..." -ForegroundColor Cyan

$inputVal = Build-LoginInputVal -User $User -Pass $Pass
$flag     = Get-PostSecurityFlag -InputVal $inputVal
$body     = $inputVal + "postSecurityFlag=$flag"

try {
    $r = Invoke-WebRequest "$base/boaform/admin/formLogin" `
         -Method POST `
         -Body $body `
         -ContentType 'application/x-www-form-urlencoded' `
         -SessionVariable sess `
         -UseBasicParsing
} catch {
    Write-Error "Login falhou: $_"
    exit 1
}

# Verifica se caiu na página principal (não na de login)
if ($r.BaseResponse.ResponseUri.AbsoluteUri -match "login\.asp" -or
    $r.Content -match "Invalid Password") {
    Write-Error "Login falhou. Verifique usuario e senha."
    exit 1
}

Write-Host "[+] Login OK (postSecurityFlag=$flag)" -ForegroundColor Green

# ---------------------------------------------------------------------------
# 2. EXTRAÇÃO DE DADOS WIFI
# ---------------------------------------------------------------------------
function Get-BandInfo {
    param([int]$Idx, [string]$Band)

    $redirect = "$base/boaform/formWlanRedirect?redirect-url="

    # --- SSID ---
    $html = (Invoke-WebRequest "${redirect}/wlbasic.asp&wlan_idx=$Idx" `
             -WebSession $sess -UseBasicParsing).Content

    $ssid = if ($html -match 'name="ssid"[^>]*value="([^"]*)"') {
                $Matches[1]
            } elseif ($html -match '<input[^>]+value="([^"]+)"[^>]+name="ssid"') {
                $Matches[1]
            } elseif ($html -match 'textbox[^>]*>\s*([^\s<]{2,32})') {
                $Matches[1]
            } else { "N/D" }

    # Fallback: primeiro input text com valor parecido com SSID
    if ($ssid -eq "N/D" -and $html -match 'type=.?text.?[^>]+value="([^"]{2,32})"') {
        $ssid = $Matches[1]
    }

    # --- SENHA ---
    $sec = (Invoke-WebRequest "${redirect}/wlwpa.asp&wlan_idx=$Idx" `
            -WebSession $sess -UseBasicParsing).Content

    # Senha armazenada em Base64 no array JS: _wpaPSK[0]='VXNlci1XTEFOLTI2'
    $psk = if ($sec -match "_wpaPSK\[0\]='([^']+)'") {
               [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Matches[1]))
           } elseif ($sec -match '_wpaPSK\[\d+\]="([^"]+)"') {
               [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Matches[1]))
           } else { "N/D" }

    # --- CRIPTOGRAFIA ---
    # Busca a opção selecionada no dropdown de criptografia (NONE, WEP, WPA2, etc.)
    $enc = if ($sec -match 'selected[^>]*>\s*(NONE|WEP|WPA\d?(?:\s*Mixed)?)\s*<') {
               $Matches[1].Trim()
           } elseif ($sec -match '<option value="\d+"[^>]+selected>(NONE|WEP|WPA\d?)') {
               $Matches[1].Trim()
           } else { "WPA2" }

    [PSCustomObject]@{
        Banda     = $Band
        SSID      = $ssid
        Senha     = $psk
        Seguranca = $enc
    }
}

Write-Host "[*] Buscando configuracoes WiFi..." -ForegroundColor Cyan

$results = @(
    (Get-BandInfo -Idx 0 -Band "5 GHz"),
    (Get-BandInfo -Idx 1 -Band "2.4 GHz")
)

Write-Host "`n===== WiFi - Datacom DM986-204 ($IP) =====`n" -ForegroundColor Yellow
$results | Format-Table -AutoSize
