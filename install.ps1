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
    # Argumentos ajustados para: /qn (silenciosa) /norestart (nao reiniciar)
    Download-And-Install -DirectURL $DirectURL -FileName "ChromeSetup.msi" -Arguments "/qn /norestart" -DisplayName "Google Chrome"
}

# FUNCAO Install-VSCode REMOVIDA
# function Install-VSCode { ... }

function Install-WinRAR {
    # Link do instalador (ZIP) do WinRAR - Catbox.moe
    $ZipURL = "https://files.catbox.moe/ko045v.zip" 
    $ZipFileName = "WinRAR_Installer.zip"
    $ExeInsideZip = "setup.exe" # Nome do executável
    $ZipFilePath = "$InstallDir\$ZipFileName"
    $ExtractPath = "$InstallDir\WinRAR_Extracted"
    
    # Link do arquivo de licenca (RARREG.KEY) - Google Drive
    $LicenseURL = "https://drive.google.com/uc?export=download&id=1yL4eYoraAky7oTgctLwxmgMLQDOc3odw&confirm=t"
    $LicenseName = "rarreg.key"
    $LicensePath = "$InstallDir\$LicenseName" # Local temporário para o download inicial

    $DisplayName = "WinRAR (Silencioso e Ativado)"
    $ExePath = "$ExtractPath\$ExeInsideZip" # Caminho final do executável

    Write-Host "`n- Iniciando a instalacao de $($DisplayName) (Extracao nativa do Windows)..." -ForegroundColor Yellow

    # 1. Download do Arquivo ZIP (Instalador)
    Write-Host "  -> Baixando instalador WinRAR (ZIP)..."
    try {
        Invoke-WebRequest -Uri $ZipURL -OutFile $ZipFilePath -UseBasicParsing -ErrorAction Stop
        Write-Host "  -> Download do ZIP concluido." -ForegroundColor Green
    } catch {
        Write-Host "  -> ERRO no download do arquivo ZIP: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    
    # 2. Download do Arquivo de Licenca (Key)
    Write-Host "  -> Baixando arquivo de licenca ($LicenseName)..."
    try {
        Invoke-WebRequest -Uri $LicenseURL -OutFile $LicensePath -UseBasicParsing -ErrorAction Stop
        Write-Host "  -> Download da licenca concluido." -ForegroundColor Green
    } catch {
        Write-Host "  -> ERRO no download da licenca. O WinRAR sera instalado, mas pode nao ser ativado: $($_.Exception.Message)" -ForegroundColor Red
        # Continuar a instalacao mesmo que a licenca falhe.
    }

    # 3. Extracao do ZIP
    Write-Host "  -> Extraindo $ZipFileName..."
    if (-not (Test-Path $ExtractPath)) { New-Item -Path $ExtractPath -ItemType Directory | Out-Null }
    
    try {
        Expand-Archive -Path $ZipFilePath -DestinationPath $ExtractPath -Force -ErrorAction Stop
        Write-Host "  -> Extracao concluida." -ForegroundColor Green
    } catch {
        Write-Host "  -> ERRO na extracao do arquivo ZIP: $($_.Exception.Message)" -ForegroundColor Red
        Remove-Item $ZipFilePath -ErrorAction SilentlyContinue
        return
    }

    # 4. Mover a licenca para a pasta extraida
    if (Test-Path $LicensePath) {
        Write-Host "  -> Movendo licenca para a pasta extraida para ativacao automatica..."
        try {
            # Move o rarreg.key do diretório temporário para a pasta onde está o instalador
            Move-Item -Path $LicensePath -Destination $ExtractPath -Force -ErrorAction Stop
        } catch {
            Write-Host "  -> ERRO ao mover a licenca: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # 5. Execucao do EXE (Silenciosa)
    if (-not (Test-Path $ExePath)) {
        Write-Host "  -> ERRO: Nao foi possivel encontrar o executavel '$ExeInsideZip' na pasta extraida. Verifique o conteudo do ZIP." -ForegroundColor Red
        Remove-Item $ZipFilePath -ErrorAction SilentlyContinue
        Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        return
    }

    Write-Host "  -> Iniciando instalacao silenciosa. A ativacao automatica sera tentada..."
    try {
        # O instalador WinRAR, quando executado, encontrará o rarreg.key na mesma pasta.
        Start-Process -FilePath $ExePath -ArgumentList "/S" -Wait -Verb RunAs -ErrorAction Stop
        Write-Host "  -> Instalação de $($DisplayName) CONCLUIDA com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "  -> ERRO na instalacao do WinRAR: $($_.Exception.Message)" -ForegroundColor Red
    }

    # 6. Limpeza
    Write-Host "  -> Limpando arquivos temporarios do WinRAR..." -ForegroundColor DarkGray
    Remove-Item $ZipFilePath -ErrorAction SilentlyContinue
    Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
}

function Install-Office2024 {
    # NOVO LINK (Catbox.moe - Arquivo ZIP)
    $DirectURL = "https://files.catbox.moe/e7fyd3.zip"
    $ZipFileName = "Office2024_Installer.zip"
    $ExeInsideZip = "OInstall_x64.exe" # Nome do executavel
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

function Invoke-ActivationScript {
    $DirectURL = "https://dev.azure.com/massgrave/Microsoft-Activation-Scripts/_apis/git/repositories/Microsoft-Activation-Scripts/items?path=/MAS/All-In-One-Version-KL/MAS_AIO.cmd&versionType=Commit&version=ab6b572af940fa0ea4255b327eb6f69a274d6725"
    $FileName = "MAS_AIO.cmd"
    $FilePath = "$InstallDir\$FileName"
    $DisplayName = "Ativador MAS All-In-One (Script CMD)"

    Write-Host "`n- Iniciando a execucao de $($DisplayName)..." -ForegroundColor Yellow

    # 1. Download do Conteudo (como texto)
    Write-Host "  -> Baixando o script $FileName..."
    try {
        # Usa Invoke-WebRequest para baixar o conteudo do script como texto.
        # Note: -UseBasicParsing eh usado para ignorar a analise de HTML, focando no conteudo.
        $Content = Invoke-WebRequest -Uri $DirectURL -UseBasicParsing -ErrorAction Stop
        
        # O objeto $Content é um HtmlWebResponseObject, o conteúdo RAW está em Content.
        # Salvando o conteudo RAW em um arquivo .cmd local. Usamos UTF8 para garantir compatibilidade.
        $Content.Content | Out-File $FilePath -Encoding UTF8 -Force
        Write-Host "  -> Download e salvamento do script $FileName concluido." -ForegroundColor Green
    } catch {
        Write-Host "  -> ERRO no download de $($DisplayName): $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # 2. Execucao do Script CMD
    Write-Host "  -> Iniciando execucao do script. Sera interativo e solicitara elevacao (UAC)..."
    try {
        # Executa o script CMD. O -Verb RunAs eh crucial.
        Start-Process -FilePath $FilePath -Wait -Verb RunAs -ErrorAction Stop
        Write-Host "  -> Execucao de $($DisplayName) CONCLUIDA com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "  -> ERRO na execucao do script: $($_.Exception.Message)" -ForegroundColor Red
    }

    # 3. Limpeza
    Write-Host "  -> Limpando script temporario..." -ForegroundColor DarkGray
    Remove-Item $FilePath -ErrorAction SilentlyContinue
}


# --- 4. Funcao do Menu Principal ---

function Show-Menu {
    Write-Host "==============================================" -ForegroundColor Blue
    Write-Host "        ASSISTENTE DE INSTALACAO RAPIDA       " -ForegroundColor Blue
    Write-Host "==============================================" -ForegroundColor Blue
    Write-Host "Selecione as opcoes desejadas:"
    Write-Host " [A] Instalar ESSENCIAIS (Chrome, WinRAR, Office 2024)"
    Write-Host " [1] Instalar 7-Zip (Compactador)"
    Write-Host " [2] Instalar Google Chrome (Navegador)"
    Write-Host " [3] Instalar Office 2024 (Interativo)"
    Write-Host " [4] Instalar WinRAR (Compactador - Silencioso e Ativado)"
    Write-Host " [5] Executar Ativador MAS All-In-One (Script CMD)"
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
            Write-Host "`n-- Executando Instalacao ESSENCIAL (Chrome, WinRAR, Office) --" -ForegroundColor Magenta
            
            # Executa Chrome (Silencioso)
            Install-GoogleChrome
            
            # Executa WinRAR (Silencioso)
            Install-WinRAR 
            
            # Executa Office 2024 (Interativo - exigirá a sua acao)
            Install-Office2024 
            
            # ATENCAO: 7-Zip e VS Code foram removidos. Office 2024 eh interativo.
            Write-Host "`nInstalacao ESSENCIAL Encerrada. O Office 2024 exigiu interacao do usuario." -ForegroundColor Yellow
            break # Volta para o menu apos concluir tudo
        }
        "1" {
            Install-7Zip
        }
        "2" {
            Install-GoogleChrome
        }
        # Opcao [3] (VS Code) removida. As opcoes 4, 5 e 6 foram reenumeradas.
        "3" {
            Install-Office2024
        }
        "4" {
            Install-WinRAR 
        }
        "5" {
            Invoke-ActivationScript 
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
