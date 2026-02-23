# backup.ps1 — Faz backup das configuracoes do Datacom DM986-204 para arquivo XML
# Equivalente a Administration > System Management > Backup/Restore > Backup Settings to File
# Uso: .\backup.ps1 [-OutputFile backup.xml]
#
# Nota tecnica: o endpoint de download retorna uma status line HTTP nao-padrao que
# causa "protocol violation" no HttpWebRequest do .NET. O script usa TCP raw com
# HTTP/1.0 para contornar o problema, mantendo zero dependencias externas.

param(
    [string]$IP         = "192.168.0.1",
    [string]$User       = "user",
    [string]$Pass       = "user",
    [string]$OutputFile = ""   # caminho do arquivo de saida; padrao: backup-YYYY-MM-DD_HH-mm-ss.xml
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
# 1. LOGIN  (Invoke-WebRequest funciona normalmente para paginas HTML)
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
# 2. EXTRAIR COOKIE DE SESSAO
# ---------------------------------------------------------------------------
$cookieStr = ($sess.Cookies.GetCookies("http://$IP/") |
              ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "; "

# ---------------------------------------------------------------------------
# 3. BACKUP via TCP raw (HTTP/1.0)
#
# O endpoint /boaform/formSaveConfig retorna o config.xml com uma status line
# nao-padrao que causa "protocol violation" no HttpWebRequest do .NET.
# Usando TCP raw com HTTP/1.0 contornamos o problema sem dependencias externas.
#
# inputVal = "save_cs=Backup...&" -> postSecurityFlag = 52232 (constante)
# ---------------------------------------------------------------------------
$iv        = "save_cs=Backup...&"
$reqBody   = $iv + "postSecurityFlag=$(Get-PostSecurityFlag $iv)"
$bodyBytes = [System.Text.Encoding]::ASCII.GetBytes($reqBody)

$httpReq = "POST /boaform/formSaveConfig HTTP/1.0`r`n" +
           "Host: $IP`r`n" +
           "Content-Type: application/x-www-form-urlencoded`r`n" +
           "Content-Length: $($bodyBytes.Length)`r`n" +
           "Cookie: $cookieStr`r`n" +
           "Connection: close`r`n" +
           "`r`n"

Write-Host "[*] Baixando backup de configuracoes..." -ForegroundColor Cyan

try {
    $tcp = New-Object System.Net.Sockets.TcpClient($IP, 80)
    $tcp.ReceiveTimeout = 15000
    $stream = $tcp.GetStream()

    # Envia requisicao
    $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($httpReq)
    $stream.Write($headerBytes, 0, $headerBytes.Length)
    $stream.Write($bodyBytes,   0, $bodyBytes.Length)

    # Le resposta completa
    $ms  = New-Object System.IO.MemoryStream
    $buf = New-Object byte[] 8192
    while ($true) {
        $n = $stream.Read($buf, 0, $buf.Length)
        if ($n -le 0) { break }
        $ms.Write($buf, 0, $n)
    }
    $tcp.Close()
} catch { Write-Error "Falha ao baixar backup: $_"; exit 1 }

$raw = $ms.ToArray()

# ---------------------------------------------------------------------------
# 4. SEPARAR HEADERS DO CORPO
# O Boa server usa LF puro (\n) em vez de CRLF (\r\n).
# Testa ambos os formatos: \r\n\r\n (padrao) e \n\n (Boa).
# ---------------------------------------------------------------------------
$bodyStart = 0
for ($i = 0; $i -lt ($raw.Length - 1); $i++) {
    if ($i + 3 -lt $raw.Length -and
        $raw[$i] -eq 13 -and $raw[$i+1] -eq 10 -and
        $raw[$i+2] -eq 13 -and $raw[$i+3] -eq 10) {
        $bodyStart = $i + 4; break   # CRLF padrao
    }
    if ($raw[$i] -eq 10 -and $raw[$i+1] -eq 10) {
        $bodyStart = $i + 2; break   # LF puro (Boa server)
    }
}

if ($bodyStart -eq 0) {
    Write-Error "Resposta invalida do servidor (cabecalhos nao encontrados)."; exit 1
}

# Extrai e valida o XML
$fileBytes = $raw[$bodyStart..($raw.Length - 1)]
$xmlPreview = [System.Text.Encoding]::UTF8.GetString($fileBytes[0..63])
if ($xmlPreview -notmatch '<Config_Information_File') {
    Write-Error "Resposta inesperada do servidor. Verifique a sessao e tente novamente."; exit 1
}

# ---------------------------------------------------------------------------
# 5. SALVAR ARQUIVO
# ---------------------------------------------------------------------------
if (-not $OutputFile) {
    $timestamp  = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $OutputFile = "backup-$timestamp.xml"
}
$outPath = if ([System.IO.Path]::IsPathRooted($OutputFile)) {
    $OutputFile
} else {
    Join-Path (Get-Location) $OutputFile
}

[System.IO.File]::WriteAllBytes($outPath, $fileBytes)

$size = (Get-Item $outPath).Length
Write-Host "[+] Backup salvo com sucesso" -ForegroundColor Green
Write-Host "    Arquivo : $outPath"
Write-Host "    Tamanho : $size bytes"
