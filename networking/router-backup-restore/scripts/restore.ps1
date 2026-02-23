# restore.ps1 — Restaura configuracoes do Datacom DM986-204 a partir de um arquivo XML
# Equivalente a Administration > System Management > Backup/Restore > Restore Settings from File
# Uso: .\restore.ps1 -InputFile backup.xml [-Wait $true]
#
# Nota tecnica: o form de restore usa multipart/form-data sem postSecurityFlag.
# Usa TCP raw com HTTP/1.0 para contornar a status line nao-padrao do Boa server.

param(
    [string]$IP        = "192.168.0.1",
    [string]$User      = "user",
    [string]$Pass      = "VPwEU7%j",
    [string]$InputFile = "",     # caminho do arquivo XML de backup (obrigatorio)
    [bool]$Wait        = $true   # aguarda o equipamento reiniciar e voltar online
)

$ProgressPreference = 'SilentlyContinue'
$base = "http://$IP"

# ---------------------------------------------------------------------------
# VALIDACAO DO ARQUIVO DE ENTRADA
# ---------------------------------------------------------------------------
if (-not $InputFile) {
    Write-Host "Uso: .\restore.ps1 -InputFile backup.xml [-Wait `$false]" -ForegroundColor Yellow
    Write-Host "Exemplo: .\restore.ps1 -InputFile backup-2026-02-20_17-27-01.xml"
    exit 1
}

$inputPath = if ([System.IO.Path]::IsPathRooted($InputFile)) {
    $InputFile
} else {
    Join-Path (Get-Location) $InputFile
}

if (-not (Test-Path $inputPath)) {
    Write-Error "Arquivo nao encontrado: $inputPath"; exit 1
}

$fileBytes = [System.IO.File]::ReadAllBytes($inputPath)
$xmlPreview = [System.Text.Encoding]::UTF8.GetString($fileBytes[0..[Math]::Min(63, $fileBytes.Length-1)])
if ($xmlPreview -notmatch '<Config_Information_File') {
    Write-Error "Arquivo invalido. O backup do DM986-204 deve comecar com <Config_Information_File>."
    exit 1
}

$fileName = [System.IO.Path]::GetFileName($inputPath)
Write-Host "`n[*] Arquivo   : $inputPath"
Write-Host "    Tamanho   : $($fileBytes.Length) bytes"

# ---------------------------------------------------------------------------
# Checksum 16-bit one's complement (usado apenas no login)
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
# 1. LOGIN  (Invoke-WebRequest funciona normalmente para paginas HTML)
# ---------------------------------------------------------------------------
Write-Host "[*] Conectando a $base ..." -ForegroundColor Cyan

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
# 2. MONTAR CORPO MULTIPART/FORM-DATA
#
# Formulario saveConfig em saveconf.asp (multipart, SEM postSecurityFlag):
#   1. binary    -> arquivo XML de backup
#   2. load      -> "Restore" (botao submit)
#   3. submit-url -> "/saveconf.asp" (campo hidden)
# ---------------------------------------------------------------------------
$boundary = "----WebKitFormBoundary" + [System.Guid]::NewGuid().ToString("N").Substring(0, 16)
$CRLF     = "`r`n"

$ms = New-Object System.IO.MemoryStream

function Append-Bytes([System.IO.MemoryStream]$s, [byte[]]$b) {
    $s.Write($b, 0, $b.Length)
}
function Append-Text([System.IO.MemoryStream]$s, [string]$t) {
    Append-Bytes $s ([System.Text.Encoding]::UTF8.GetBytes($t))
}

# -- Campo 1: binary (arquivo) --
Append-Text $ms ("--$boundary$CRLF")
Append-Text $ms ("Content-Disposition: form-data; name=`"binary`"; filename=`"$fileName`"$CRLF")
Append-Text $ms ("Content-Type: application/octet-stream$CRLF")
Append-Text $ms $CRLF
Append-Bytes $ms $fileBytes
Append-Text $ms $CRLF

# -- Campo 2: load (botao Restore) --
Append-Text $ms ("--$boundary$CRLF")
Append-Text $ms ("Content-Disposition: form-data; name=`"load`"$CRLF")
Append-Text $ms $CRLF
Append-Text $ms "Restore"
Append-Text $ms $CRLF

# -- Campo 3: submit-url (hidden) --
Append-Text $ms ("--$boundary$CRLF")
Append-Text $ms ("Content-Disposition: form-data; name=`"submit-url`"$CRLF")
Append-Text $ms $CRLF
Append-Text $ms "/saveconf.asp"
Append-Text $ms $CRLF

# -- Boundary final --
Append-Text $ms ("--$boundary--$CRLF")

$bodyBytes = $ms.ToArray()

# ---------------------------------------------------------------------------
# 3. ENVIAR VIA TCP RAW (HTTP/1.0)
#
# Mesmo motivo do backup.ps1: o Boa server retorna status line nao-padrao
# que causa "protocol violation" no HttpWebRequest do .NET.
# ---------------------------------------------------------------------------
$cookieStr = ($sess.Cookies.GetCookies("http://$IP/") |
              ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "; "

$httpReq = "POST /boaform/formSaveConfig HTTP/1.0$CRLF" +
           "Host: $IP$CRLF" +
           "Content-Type: multipart/form-data; boundary=$boundary$CRLF" +
           "Content-Length: $($bodyBytes.Length)$CRLF" +
           "Cookie: $cookieStr$CRLF" +
           "Connection: close$CRLF" +
           $CRLF

Write-Host "[*] Enviando arquivo de restore..." -ForegroundColor Cyan

try {
    $tcp = New-Object System.Net.Sockets.TcpClient($IP, 80)
    $tcp.ReceiveTimeout = 15000
    $stream = $tcp.GetStream()

    $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($httpReq)
    $stream.Write($headerBytes, 0, $headerBytes.Length)
    $stream.Write($bodyBytes,   0, $bodyBytes.Length)
    $stream.Flush()

    # Le resposta
    $respMs  = New-Object System.IO.MemoryStream
    $buf     = New-Object byte[] 8192
    while ($true) {
        $n = $stream.Read($buf, 0, $buf.Length)
        if ($n -le 0) { break }
        $respMs.Write($buf, 0, $n)
    }
    $tcp.Close()
} catch {
    # Boa pode fechar a conexao antes de responder — nao e erro
    Write-Host "[+] Arquivo enviado (conexao encerrada pelo equipamento)" -ForegroundColor Green
}

# Analisa resposta se disponivel
$raw = $respMs.ToArray()
if ($raw.Length -gt 0) {
    # Separa headers do corpo (Boa usa LF puro \n, padrao e \r\n)
    $bodyStart = 0
    for ($i = 0; $i -lt ($raw.Length - 1); $i++) {
        if ($i + 3 -lt $raw.Length -and
            $raw[$i] -eq 13 -and $raw[$i+1] -eq 10 -and
            $raw[$i+2] -eq 13 -and $raw[$i+3] -eq 10) {
            $bodyStart = $i + 4; break
        }
        if ($raw[$i] -eq 10 -and $raw[$i+1] -eq 10) {
            $bodyStart = $i + 2; break
        }
    }
    $respBody = if ($bodyStart -gt 0) {
        [System.Text.Encoding]::UTF8.GetString($raw[$bodyStart..($raw.Length - 1)])
    } else { "" }

    if ($raw[0..11] -join ',' -match '^72,84,84,80') {   # começa com "HTTP"
        $statusLine = [System.Text.Encoding]::ASCII.GetString($raw[0..50]).Split("`n")[0].Trim()
        if ($statusLine -match '200') {
            Write-Host "[+] Restore enviado com sucesso" -ForegroundColor Green
        } elseif ($statusLine -match '3[0-9][0-9]') {
            Write-Host "[+] Restore aceito (redirecionamento: $statusLine)" -ForegroundColor Green
        } else {
            Write-Warning "Resposta inesperada: $statusLine"
        }
    } else {
        Write-Host "[+] Restore enviado" -ForegroundColor Green
    }
} else {
    Write-Host "[+] Restore enviado com sucesso" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 4. AGUARDAR RETORNO (opcional)
# O equipamento reinicia automaticamente apos aplicar o backup.
# ---------------------------------------------------------------------------
if (-not $Wait) {
    Write-Host "[~] Aguardo desativado. O equipamento deve reiniciar em instantes." -ForegroundColor Yellow
    exit 0
}

Write-Host "[*] Aguardando equipamento reiniciar..." -ForegroundColor Cyan

# Espera ficar offline (ate 30s)
for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep -Seconds 2
    try {
        Invoke-WebRequest "$base/admin/login.asp" -UseBasicParsing -TimeoutSec 2 | Out-Null
    } catch {
        Write-Host "  [.] Equipamento offline, aguardando retorno..." -ForegroundColor DarkGray
        break
    }
}

# Espera voltar online (ate 120s)
$online = $false
for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Seconds 2
    try {
        $check = Invoke-WebRequest "$base/admin/login.asp" -UseBasicParsing -TimeoutSec 3
        if ($check.StatusCode -eq 200) { $online = $true; break }
    } catch { }
    if ($i % 5 -eq 4) { Write-Host "  [.] Ainda aguardando..." -ForegroundColor DarkGray }
}

if ($online) {
    Write-Host "[+] Equipamento online novamente em $base" -ForegroundColor Green
} else {
    Write-Host "[!] Equipamento nao respondeu em 120s. Verifique manualmente." -ForegroundColor Yellow
}
