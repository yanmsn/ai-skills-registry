<#
.SYNOPSIS
    Gerenciador de Skills do Antigravity AI

.DESCRIPTION
    Script para gerenciar skills: instalar, listar, atualizar, remover e validar.
    Suporta instalação de skills do Google Drive, GitHub, ou arquivos locais.

.PARAMETER Action
    Ação a ser executada: Install, List, Update, Remove, Validate, Export

.PARAMETER Source
    Fonte da skill (URL do Google Drive, GitHub, ou caminho local)

.PARAMETER SkillName
    Nome da skill para operações de update, remove ou validate

.PARAMETER Destination
    Destino para exportação de skills

.EXAMPLE
    .\manage-skills.ps1 -Action List
    Lista todas as skills instaladas

.EXAMPLE
    .\manage-skills.ps1 -Action Install -Source "C:\Downloads\my-skill.zip"
    Instala uma skill de um arquivo ZIP local

.EXAMPLE
    .\manage-skills.ps1 -Action Validate -SkillName "router-wifi-extractor"
    Valida a estrutura de uma skill instalada

.EXAMPLE
    .\manage-skills.ps1 -Action Export -SkillName "router-wifi-extractor" -Destination "C:\Backup"
    Exporta uma skill para um diretório

.NOTES
    Author: Yan Marcos
    Version: 1.0.0
    Created: 2026-02-16
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Install", "List", "Update", "Remove", "Validate", "Export", "Info")]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [string]$Source,

    [Parameter(Mandatory=$false)]
    [string]$SkillName,

    [Parameter(Mandatory=$false)]
    [string]$Destination
)

# Configurações
$SkillsPath = "$env:USERPROFILE\.gemini\antigravity\skills"

# Cores para output
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ $Message" -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }

# Função para validar estrutura de skill
function Test-SkillStructure {
    param([string]$SkillPath)
    
    $isValid = $true
    $issues = @()

    # Verificar se SKILL.md existe
    if (-not (Test-Path "$SkillPath\SKILL.md")) {
        $issues += "SKILL.md não encontrado (obrigatório)"
        $isValid = $false
    } else {
        # Verificar frontmatter YAML
        $content = Get-Content "$SkillPath\SKILL.md" -Raw
        if ($content -notmatch '(?s)^---\s*\n.*?\n---') {
            $issues += "SKILL.md não contém frontmatter YAML válido"
            $isValid = $false
        }
    }

    # Verificar metadata.json (recomendado)
    if (-not (Test-Path "$SkillPath\metadata.json")) {
        $issues += "metadata.json não encontrado (recomendado)"
    } else {
        try {
            $metadata = Get-Content "$SkillPath\metadata.json" -Raw | ConvertFrom-Json
            
            # Validar campos obrigatórios
            $requiredFields = @('name', 'version', 'description', 'category')
            foreach ($field in $requiredFields) {
                if (-not $metadata.$field) {
                    $issues += "metadata.json: campo '$field' ausente"
                    $isValid = $false
                }
            }
        } catch {
            $issues += "metadata.json: formato JSON inválido"
            $isValid = $false
        }
    }

    return @{
        IsValid = $isValid
        Issues = $issues
    }
}

# Função para listar skills
function Get-InstalledSkills {
    Write-Info "Skills instaladas em: $SkillsPath"
    Write-Host ""

    if (-not (Test-Path $SkillsPath)) {
        Write-Warning "Diretório de skills não encontrado: $SkillsPath"
        return
    }

    $skillDirs = Get-ChildItem -Path $SkillsPath -Directory | Where-Object { 
        $_.Name -ne "scripts" -and (Test-Path "$($_.FullName)\SKILL.md")
    }

    if ($skillDirs.Count -eq 0) {
        Write-Warning "Nenhuma skill instalada"
        return
    }

    foreach ($skillDir in $skillDirs) {
        $skillPath = $skillDir.FullName
        $skillName = $skillDir.Name
        
        Write-Host "📦 $skillName" -ForegroundColor Yellow
        
        # Ler metadata se existir
        if (Test-Path "$skillPath\metadata.json") {
            try {
                $metadata = Get-Content "$skillPath\metadata.json" -Raw | ConvertFrom-Json
                Write-Host "   Versão: $($metadata.version)" -ForegroundColor Gray
                Write-Host "   Descrição: $($metadata.description)" -ForegroundColor Gray
                Write-Host "   Categoria: $($metadata.category)" -ForegroundColor Gray
                if ($metadata.author) {
                    Write-Host "   Autor: $($metadata.author)" -ForegroundColor Gray
                }
            } catch {
                Write-Host "   (metadata.json inválido)" -ForegroundColor Red
            }
        } else {
            Write-Host "   (sem metadata.json)" -ForegroundColor Gray
        }
        
        Write-Host ""
    }

    Write-Info "Total: $($skillDirs.Count) skill(s) instalada(s)"
}

# Função para instalar skill
function Install-Skill {
    param([string]$SourcePath)

    if (-not $SourcePath) {
        Write-Error "Fonte não especificada. Use -Source para indicar o caminho ou URL"
        return
    }

    Write-Info "Instalando skill de: $SourcePath"

    # Verificar se é URL ou caminho local
    if ($SourcePath -match '^https?://') {
        Write-Error "Instalação via URL ainda não implementada"
        Write-Info "Por favor, baixe manualmente e use o caminho local"
        return
    }

    # Verificar se é arquivo ZIP
    if ($SourcePath -match '\.zip$' -and (Test-Path $SourcePath)) {
        Write-Info "Extraindo arquivo ZIP..."
        
        $tempDir = "$env:TEMP\antigravity-skill-temp"
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
        
        Expand-Archive -Path $SourcePath -DestinationPath $tempDir -Force
        
        # Encontrar a pasta da skill (primeira pasta com SKILL.md)
        $skillFolder = Get-ChildItem -Path $tempDir -Recurse -Filter "SKILL.md" | Select-Object -First 1
        
        if ($skillFolder) {
            $skillSourcePath = $skillFolder.Directory.FullName
            $skillName = $skillFolder.Directory.Name
            
            # Validar estrutura
            $validation = Test-SkillStructure -SkillPath $skillSourcePath
            if (-not $validation.IsValid) {
                Write-Error "Skill inválida:"
                foreach ($issue in $validation.Issues) {
                    Write-Host "  - $issue" -ForegroundColor Red
                }
                return
            }
            
            # Copiar para diretório de skills
            $destPath = "$SkillsPath\$skillName"
            if (Test-Path $destPath) {
                Write-Warning "Skill '$skillName' já existe. Sobrescrever? (S/N)"
                $response = Read-Host
                if ($response -ne 'S' -and $response -ne 's') {
                    Write-Info "Instalação cancelada"
                    return
                }
                Remove-Item $destPath -Recurse -Force
            }
            
            Copy-Item -Path $skillSourcePath -Destination $destPath -Recurse -Force
            Write-Success "Skill '$skillName' instalada com sucesso!"
            
            # Limpar temp
            Remove-Item $tempDir -Recurse -Force
        } else {
            Write-Error "SKILL.md não encontrado no arquivo ZIP"
        }
        
    } elseif (Test-Path $SourcePath -PathType Container) {
        # É um diretório
        Write-Info "Instalando de diretório local..."
        
        # Validar estrutura
        $validation = Test-SkillStructure -SkillPath $SourcePath
        if (-not $validation.IsValid) {
            Write-Error "Skill inválida:"
            foreach ($issue in $validation.Issues) {
                Write-Host "  - $issue" -ForegroundColor Red
            }
            return
        }
        
        $skillName = Split-Path $SourcePath -Leaf
        $destPath = "$SkillsPath\$skillName"
        
        if (Test-Path $destPath) {
            Write-Warning "Skill '$skillName' já existe. Sobrescrever? (S/N)"
            $response = Read-Host
            if ($response -ne 'S' -and $response -ne 's') {
                Write-Info "Instalação cancelada"
                return
            }
            Remove-Item $destPath -Recurse -Force
        }
        
        Copy-Item -Path $SourcePath -Destination $destPath -Recurse -Force
        Write-Success "Skill '$skillName' instalada com sucesso!"
        
    } else {
        Write-Error "Fonte inválida: $SourcePath"
    }
}

# Função para remover skill
function Remove-Skill {
    param([string]$Name)

    if (-not $Name) {
        Write-Error "Nome da skill não especificado. Use -SkillName"
        return
    }

    $skillPath = "$SkillsPath\$Name"
    
    if (-not (Test-Path $skillPath)) {
        Write-Error "Skill '$Name' não encontrada"
        return
    }

    Write-Warning "Tem certeza que deseja remover a skill '$Name'? (S/N)"
    $response = Read-Host
    
    if ($response -eq 'S' -or $response -eq 's') {
        Remove-Item $skillPath -Recurse -Force
        Write-Success "Skill '$Name' removida com sucesso!"
    } else {
        Write-Info "Remoção cancelada"
    }
}

# Função para validar skill
function Validate-Skill {
    param([string]$Name)

    if (-not $Name) {
        Write-Error "Nome da skill não especificado. Use -SkillName"
        return
    }

    $skillPath = "$SkillsPath\$Name"
    
    if (-not (Test-Path $skillPath)) {
        Write-Error "Skill '$Name' não encontrada"
        return
    }

    Write-Info "Validando skill '$Name'..."
    
    $validation = Test-SkillStructure -SkillPath $skillPath
    
    if ($validation.IsValid) {
        Write-Success "Skill '$Name' é válida!"
    } else {
        Write-Error "Skill '$Name' possui problemas:"
        foreach ($issue in $validation.Issues) {
            Write-Host "  - $issue" -ForegroundColor Red
        }
    }

    if ($validation.Issues.Count -gt 0 -and $validation.IsValid) {
        Write-Warning "Avisos:"
        foreach ($issue in $validation.Issues) {
            Write-Host "  - $issue" -ForegroundColor Yellow
        }
    }
}

# Função para exportar skill
function Export-Skill {
    param(
        [string]$Name,
        [string]$DestPath
    )

    if (-not $Name) {
        Write-Error "Nome da skill não especificado. Use -SkillName"
        return
    }

    if (-not $DestPath) {
        $DestPath = "$env:USERPROFILE\Desktop"
    }

    $skillPath = "$SkillsPath\$Name"
    
    if (-not (Test-Path $skillPath)) {
        Write-Error "Skill '$Name' não encontrada"
        return
    }

    $zipPath = "$DestPath\$Name.zip"
    
    Write-Info "Exportando skill '$Name' para: $zipPath"
    
    if (Test-Path $zipPath) {
        Write-Warning "Arquivo já existe. Sobrescrever? (S/N)"
        $response = Read-Host
        if ($response -ne 'S' -and $response -ne 's') {
            Write-Info "Exportação cancelada"
            return
        }
        Remove-Item $zipPath -Force
    }

    Compress-Archive -Path $skillPath -DestinationPath $zipPath -Force
    Write-Success "Skill exportada com sucesso: $zipPath"
}

# Função para mostrar informações de uma skill
function Show-SkillInfo {
    param([string]$Name)

    if (-not $Name) {
        Write-Error "Nome da skill não especificado. Use -SkillName"
        return
    }

    $skillPath = "$SkillsPath\$Name"
    
    if (-not (Test-Path $skillPath)) {
        Write-Error "Skill '$Name' não encontrada"
        return
    }

    Write-Host ""
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Informações da Skill: $Name" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    # Ler metadata
    if (Test-Path "$skillPath\metadata.json") {
        try {
            $metadata = Get-Content "$skillPath\metadata.json" -Raw | ConvertFrom-Json
            
            Write-Host "Nome: " -NoNewline -ForegroundColor Gray
            Write-Host $metadata.name -ForegroundColor White
            
            Write-Host "Versão: " -NoNewline -ForegroundColor Gray
            Write-Host $metadata.version -ForegroundColor White
            
            Write-Host "Descrição: " -NoNewline -ForegroundColor Gray
            Write-Host $metadata.description -ForegroundColor White
            
            Write-Host "Categoria: " -NoNewline -ForegroundColor Gray
            Write-Host $metadata.category -ForegroundColor White
            
            if ($metadata.author) {
                Write-Host "Autor: " -NoNewline -ForegroundColor Gray
                Write-Host $metadata.author -ForegroundColor White
            }
            
            if ($metadata.tags) {
                Write-Host "Tags: " -NoNewline -ForegroundColor Gray
                Write-Host ($metadata.tags -join ", ") -ForegroundColor White
            }
            
            if ($metadata.dependencies) {
                Write-Host "Dependências: " -NoNewline -ForegroundColor Gray
                Write-Host ($metadata.dependencies -join ", ") -ForegroundColor White
            }
            
            if ($metadata.compatibility -and $metadata.compatibility.routers) {
                Write-Host "Roteadores compatíveis: " -NoNewline -ForegroundColor Gray
                Write-Host ($metadata.compatibility.routers -join ", ") -ForegroundColor White
            }
            
            Write-Host ""
            
        } catch {
            Write-Warning "Erro ao ler metadata.json"
        }
    } else {
        Write-Warning "metadata.json não encontrado"
    }

    # Mostrar estrutura de arquivos
    Write-Host "Estrutura:" -ForegroundColor Gray
    Get-ChildItem -Path $skillPath -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Replace($skillPath, "").TrimStart('\')
        $indent = "  " * (($relativePath.Split('\').Count - 1))
        if ($_.PSIsContainer) {
            Write-Host "$indent📁 $($_.Name)" -ForegroundColor Cyan
        } else {
            Write-Host "$indent📄 $($_.Name)" -ForegroundColor Gray
        }
    }

    Write-Host ""
}

# Main
switch ($Action) {
    "List" {
        Get-InstalledSkills
    }
    "Install" {
        Install-Skill -SourcePath $Source
    }
    "Remove" {
        Remove-Skill -Name $SkillName
    }
    "Validate" {
        Validate-Skill -Name $SkillName
    }
    "Export" {
        Export-Skill -Name $SkillName -DestPath $Destination
    }
    "Info" {
        Show-SkillInfo -Name $SkillName
    }
}
