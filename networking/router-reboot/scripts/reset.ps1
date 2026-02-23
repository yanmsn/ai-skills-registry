# reset.ps1 — Restaura configuracoes de fabrica do Datacom DM986-204 via HTTP puro
# Equivalente a Administration > System Management > Backup/Restore > Reset Settings to Default
# Uso: .\reset.ps1 [-Wait $true]
#
# ATENCAO: Apos o reset, o equipamento volta para as configuracoes de fabrica
# (credenciais, SSID, WAN etc.). As credenciais atuais deixarao de funcionar.

param(
    [string]$IP   = "192.168.28.1",
    [string]$User = "user",
    [string]$Pass = "user-GW-24",
    [bool]$Wait   = $true   # aguarda o equipamento voltar apos o reset
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
# 2. RESET PARA CONFIGURACOES DE FABRICA
#
# Formulario resetConfig em saveconf.asp:
#   - reset=Reset        (botao submit com isclick=1)
#   - submit-url=%2Fsaveconf.asp  (campo hidden)
# inputVal = "reset=Reset&submit-url=%2Fsaveconf.asp&" -> flag = 39415
# ---------------------------------------------------------------------------
Write-Host "[*] Enviando comando de reset para configuracoes de fabrica..." -ForegroundColor Cyan
Write-Host "[!] ATENCAO: todas as configuracoes serao apagadas." -ForegroundColor Yellow

$iv   = "reset=Reset&submit-url=%2Fsaveconf.asp&"
$body = $iv + "postSecurityFlag=$(Get-PostSecurityFlag $iv)"

try {
    Invoke-WebRequest "$base/boaform/formSaveConfig" `
        -Method POST -Body $body `
        -ContentType 'application/x-www-form-urlencoded' `
        -WebSession $sess -UseBasicParsing | Out-Null
    Write-Host "[+] Comando de reset enviado com sucesso" -ForegroundColor Green
} catch {
    # O equipamento pode fechar a conexao antes de responder — nao e erro
    Write-Host "[+] Comando de reset enviado (conexao encerrada pelo equipamento)" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 3. AGUARDAR RETORNO (opcional)
# ---------------------------------------------------------------------------
if (-not $Wait) {
    Write-Host "[~] Aguardo desativado. O equipamento deve reiniciar em instantes." -ForegroundColor Yellow
    Write-Host "[!] Apos o reset, use as credenciais de fabrica para acessar o equipamento." -ForegroundColor Yellow
    exit 0
}

Write-Host "[*] Aguardando equipamento reiniciar..." -ForegroundColor Cyan

# Espera o equipamento ficar offline (ate 30s)
for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep -Seconds 2
    try {
        Invoke-WebRequest "$base/admin/login.asp" -UseBasicParsing -TimeoutSec 2 | Out-Null
    } catch {
        Write-Host "  [.] Equipamento offline, aguardando retorno..." -ForegroundColor DarkGray
        break
    }
}

# Espera o equipamento voltar online (ate 120s)
$online = $false
for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Seconds 2
    try {
        $check = Invoke-WebRequest "$base/admin/login.asp" -UseBasicParsing -TimeoutSec 3
        if ($check.StatusCode -eq 200) {
            $online = $true
            break
        }
    } catch { }
    if ($i % 5 -eq 4) { Write-Host "  [.] Ainda aguardando..." -ForegroundColor DarkGray }
}

if ($online) {
    Write-Host "[+] Equipamento online novamente em $base" -ForegroundColor Green
    Write-Host "[!] Use as credenciais de fabrica para acessar o equipamento." -ForegroundColor Yellow
} else {
    Write-Host "[!] Equipamento nao respondeu em 120s. Verifique manualmente." -ForegroundColor Yellow
}
