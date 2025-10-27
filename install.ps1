# ==============================================================================
# SCRIPT DE INSTALACAO MULTI-APLICATIVOS
# Este script utiliza funcoes para baixar e instalar programas silenciosamente.
# Requer execucao com permissoes de Administrador.
# ==============================================================================

# --- 1. Variaveis Iniciais ---
# Diretorio temporario para baixar e armazenar os instaladores
$InstallDir = "C:\Temp\InstallerScripts"

# Cria o diretorio se nao existir
if (-not (Test-Path $InstallDir)) {
    Write-Host "- Criando diretorio temporario: $InstallDir" -ForegroundColor Cyan
    New-Item -Path $InstallDir -ItemType Directory | Out-Null
}

# --- 2. Funcao de Download e Instalacao (Core) ---

function Download-And-Install {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DirectURL, # Link de download direto (ex: Google Drive, Servidor Web, etc.)

        [Parameter(Mandatory=$true)]
        [string]$FileName, # Nome do arquivo para salvar (ex: 7z.exe)

        [Parameter(Mandatory=$false)]
        [string]$Arguments = "", # Argumento de instalacao silenciosa (ex: /S, /quiet). Tornada opcional para permitir string vazia.

        [string]$DisplayName
    )

    $FilePath = "$InstallDir\$FileName"

    Write-Host "`n- Iniciando a instalacao de $($DisplayName)..." -ForegroundColor Yellow

    # 1. Download do Arquivo
    Write-Host "  -> Baixando $FileName..."
    try {
        # Usa Invoke-WebRequest para baixar o arquivo
        Invoke-WebRequest -Uri $DirectURL -OutFile $FilePath -UseBasicParsing -ErrorAction Stop
        Write-Host "  -> Download concluido." -ForegroundColor Green
    } catch {
        Write-Host "  -> ERRO no download de $($DisplayName): $($_.Exception.Message)" -ForegroundColor Red
        return # Sai da funcao em caso de falha
    }

    # 2. Instalação Silenciosa/Interativa
    Write-Host "  -> Iniciando instalacao (sera interativa se nao houver argumentos silenciosos)..."
    try {
        # Executa o instalador
        # -Verb RunAs: Garante a elevacao (UAC)
        # -Wait: Garante que o script espere o instalador terminar
        Start-Process -FilePath $FilePath -ArgumentList $Arguments -Wait -Verb RunAs -ErrorAction Stop
        Write-Host "  -> Instalação de $($DisplayName) CONCLUIDA com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "  -> ERRO na instalacao de $($DisplayName): $($_.Exception.Message)" -ForegroundColor Red
    }

    # 3. Limpeza (Removendo o instalador para liberar espaco)
    Remove-Item $FilePath -ErrorAction SilentlyContinue
}

# --- 3. Funcoes de Instalacao de Aplicativos (Modular) ---

function Install-7Zip {
    # Link oficial e estavel do 7-Zip (64-bit)
    $DirectURL = "https://www.7-zip.org/a/7z2301-x64.exe"

    # 7-Zip (64 bits - Instalacao Silenciosa)
    Download-And-Install -DirectURL $DirectURL -FileName "7z-x64.exe" -Arguments "/S" -DisplayName "7-Zip"
}

function Install-GoogleChrome {
    # Link de download direto oficial (MSI - Melhor para empresas/silenciosa)
    $DirectURL = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"

    # Google Chrome (MSI - Instalacao Silenciosa)
    Download-And-Install -DirectURL $DirectURL -FileName "ChromeSetup.msi" -Arguments "/i ChromeSetup.msi /qn /norestart" -DisplayName "Google Chrome"
}

function Install-VSCode {
    # Link de download direto oficial
    $DirectURL = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
    
    # VS Code (User Installer - 64 bits - Instalacao Silenciosa)
    Download-And-Install -DirectURL $DirectURL -FileName "VSCodeSetup.exe" -Arguments "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -DisplayName "Visual Studio Code"
}

function Install-Office2024 {
    # NOVO LINK (Catbox.moe - Arquivo ZIP)
    $DirectURL = "https://files.catbox.moe/e7fyd3.zip"
    $ZipFileName = "Office2024_Installer.zip"
    $ExeInsideZip = "OInstall_x64.exe" # ATENCAO: Nome do executavel corrigido
    $ZipFilePath = "$InstallDir\$ZipFileName"
    $ExtractPath = "$InstallDir\Office2024_Extracted"
    $DisplayName = "Office 2024"
    
    Write-Host "`n- Iniciando a instalacao de $DisplayName (Extracao nativa do Windows)..." -ForegroundColor Yellow

    # 1. Download do Arquivo ZIP
    Write-Host "  -> Baixando $ZipFileName..."
    try {
        # Usa Invoke-WebRequest para baixar o arquivo
        Invoke-WebRequest -Uri $DirectURL -OutFile $ZipFilePath -UseBasicParsing -ErrorAction Stop
        Write-Host "  -> Download concluido." -ForegroundColor Green
    } catch {
        Write-Host "  -> ERRO no download do arquivo ZIP: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # 2. Extracao do ZIP (Nativo do PowerShell - Expand-Archive)
    Write-Host "  -> Extraindo $ZipFileName..."
    if (-not (Test-Path $ExtractPath)) { New-Item -Path $ExtractPath -ItemType Directory | Out-Null }
    
    try {
        # Usa Expand-Archive, nativo do PowerShell 5.0+ (presente no Windows 10/11)
        Expand-Archive -Path $ZipFilePath -DestinationPath $ExtractPath -Force -ErrorAction Stop
        Write-Host "  -> Extracao concluida usando Expand-Archive (nativo)." -ForegroundColor Green
    } catch {
        Write-Host "  -> ERRO na extracao do arquivo ZIP: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  -> ATENCAO: A extracao nativa falhou. Verifique se a sua versao do PowerShell eh 5.0 ou superior." -ForegroundColor Red
        Remove-Item $ZipFilePath -ErrorAction SilentlyContinue
        return
    }

    # 3. Execucao do EXE (Interativo)
    $ExePath = "$ExtractPath\$ExeInsideZip"
    
    if (-not (Test-Path $ExePath)) {
        Write-Host "  -> ERRO: Nao foi possivel encontrar o executavel '$ExeInsideZip' na pasta extraida. Verifique o conteudo do ZIP." -ForegroundColor Red
        Remove-Item $ZipFilePath -ErrorAction SilentlyContinue
        Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        return
    }

    Write-Host "  -> Executando $ExeInsideZip (Interativo)... Sera solicitada elevacao (UAC)."
    try {
        Start-Process -FilePath $ExePath -Wait -Verb RunAs -ErrorAction Stop
        Write-Host "  -> Instalação de $DisplayName CONCLUIDA com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "  -> ERRO na execucao do instalador: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 4. Limpeza
    Remove-Item $ZipFilePath -ErrorAction SilentlyContinue
    Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
}

# --- 4. Funcao do Menu Principal ---

function Show-Menu {
    Write-Host "==============================================" -ForegroundColor Blue
    Write-Host "        ASSISTENTE DE INSTALACAO RAPIDA       " -ForegroundColor Blue
    Write-Host "==============================================" -ForegroundColor Blue
    Write-Host "Selecione as opcoes desejadas:"
    Write-Host " [A] Instalar TUDO (7-Zip, Chrome, VS Code, Office)"
    Write-Host " [1] Instalar 7-Zip (Compactador)"
    Write-Host " [2] Instalar Google Chrome (Navegador)"
    Write-Host " [3] Instalar Visual Studio Code (Editor)"
    Write-Host " [4] Instalar Office 2024 (Interativo)"
    Write-Host "----------------------------------------------"
    Write-Host " [0] Sair"
    Write-Host "==============================================" -ForegroundColor Blue

    $Selection = Read-Host "Digite a letra/numero da sua opcao"
    return $Selection
}

# --- 5. Execucao do Programa ---

do {
    $Choice = Show-Menu
    
    switch ($Choice.ToUpper()) {
        "A" {
            Write-Host "`n-- Executando Instalacao COMPLETA --" -ForegroundColor Magenta
            Install-7Zip
            Install-GoogleChrome
            Install-VSCode
            # ATENCAO: Office nao esta incluido na instalacao COMPLETA (A) pois eh INTERATIVO
            Write-Host "`nInstalacoes silenciosas COMPLETA Encerrada. Office 2024 nao foi incluido (requer interacao)." -ForegroundColor Yellow
            break # Volta para o menu apos concluir tudo
        }
        "1" {
            Install-7Zip
        }
        "2" {
            Install-GoogleChrome
        }
        "3" {
            Install-VSCode
        }
        "4" {
            Install-Office2024
        }
        "0" {
            Write-Host "`nSaindo do Assistente. Ate mais!" -ForegroundColor Red
            break # Sai do loop
        }
        default {
            Write-Host "`nOpcao invalida. Tente novamente." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
    
    # Pausa antes de mostrar o menu novamente, a menos que seja a opcao '0'
    if ($Choice -ne "0") {
        Read-Host "Pressione Enter para voltar ao menu principal" | Out-Null
        Clear-Host
    }

} while ($Choice -ne "0")

# --- 6. Limpeza Final (Opcional, mas recomendado) ---
Write-Host "`nLimpando arquivos temporarios..." -ForegroundColor DarkGray
Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
