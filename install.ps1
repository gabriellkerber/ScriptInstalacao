# ==============================================================================
# SCRIPT DE INSTALAÇÃO MULTI-APLICATIVOS
# Este script utiliza funções para baixar e instalar programas silenciosamente.
# Requer execução com permissões de Administrador.
# ==============================================================================

# --- 1. Variáveis Iniciais ---
# Diretório temporário para baixar e armazenar os instaladores
$InstallDir = "C:\Temp\InstallerScripts"

# Cria o diretório se não existir
if (-not (Test-Path $InstallDir)) {
    Write-Host "- Criando diretório temporário: $InstallDir" -ForegroundColor Cyan
    New-Item -Path $InstallDir -ItemType Directory | Out-Null
}

# --- 2. Função de Download e Instalação (Core) ---

function Download-And-Install {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DirectURL, # Link de download direto (ex: Google Drive, Servidor Web, etc.)

        [Parameter(Mandatory=$true)]
        [string]$FileName, # Nome do arquivo para salvar (ex: 7z.exe)

        [Parameter(Mandatory=$true)]
        [string]$Arguments, # Argumento de instalação silenciosa (ex: /S, /quiet)

        [string]$DisplayName
    )

    $FilePath = "$InstallDir\$FileName"

    Write-Host "`n- Iniciando a instalação de $($DisplayName)..." -ForegroundColor Yellow

    # 1. Download do Arquivo
    Write-Host "  -> Baixando $FileName..."
    try {
        # Usa Invoke-WebRequest para baixar o arquivo
        Invoke-WebRequest -Uri $DirectURL -OutFile $FilePath -UseBasicParsing -ErrorAction Stop
        Write-Host "  -> Download concluído." -ForegroundColor Green
    } catch {
        Write-Host "  -> ERRO no download de $($DisplayName): $($_.Exception.Message)" -ForegroundColor Red
        return # Sai da função em caso de falha
    }

    # 2. Instalação Silenciosa
    Write-Host "  -> Instalando silenciosamente..."
    try {
        # Executa o instalador com os argumentos silenciosos
        # -Wait garante que o script espera o fim da instalação
        Start-Process -FilePath $FilePath -ArgumentList $Arguments -Wait -NoNewWindow -ErrorAction Stop
        Write-Host "  -> Instalação de $($DisplayName) CONCLUÍDA com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "  -> ERRO na instalação silenciosa de $($DisplayName): $($_.Exception.Message)" -ForegroundColor Red
    }

    # 3. Limpeza (Removendo o instalador para liberar espaço)
    Remove-Item $FilePath -ErrorAction SilentlyContinue
}

# --- 3. Funções de Instalação de Aplicativos (Modular) ---

function Install-7Zip {
    # LINK DO 7-ZIP (Transformado do seu Google Drive)
    # ID: 1p3Fz3taGBc8ZFMQWbPA4tvkVyThy6QpM
    $DirectURL = "https://drive.google.com/uc?export=download&id=1p3Fz3taGBc8ZFMQWbPA4tvkVyThy6QpM"

    # 7-Zip (64 bits - Exemplo)
    Download-And-Install -DirectURL $DirectURL `
                         -FileName "7z.exe" `
                         -Arguments "/S" ` # Parâmetro silencioso do 7-Zip
                         -DisplayName "7-Zip"
}

function Install-GoogleChrome {
    # ATENÇÃO: Link de download direto oficial (MSI - Melhor para empresas/silenciosa)
    $DirectURL = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"

    # Google Chrome (MSI)
    Download-And-Install -DirectURL $DirectURL `
                         -FileName "ChromeSetup.msi" `
                         -Arguments "/i ChromeSetup.msi /qn /norestart" ` # Parâmetro silencioso do MSI (quiet, no restart)
                         -DisplayName "Google Chrome"
}

function Install-VSCode {
    # Link de download direto oficial
    $DirectURL = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
    
    # VS Code (User Installer - 64 bits)
    Download-And-Install -DirectURL $DirectURL `
                         -FileName "VSCodeSetup.exe" `
                         -Arguments "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" ` # Parâmetros silenciosos do VS Code
                         -DisplayName "Visual Studio Code"
}

# --- 4. Função do Menu Principal ---

function Show-Menu {
    Write-Host "==============================================" -ForegroundColor Blue
    Write-Host "        ASSISTENTE DE INSTALAÇÃO RÁPIDA       " -ForegroundColor Blue
    Write-Host "==============================================" -ForegroundColor Blue
    Write-Host "Selecione as opções desejadas:"
    Write-Host " [A] Instalar TUDO (7-Zip, Chrome, VS Code)"
    Write-Host " [1] Instalar 7-Zip (Compactador)"
    Write-Host " [2] Instalar Google Chrome (Navegador)"
    Write-Host " [3] Instalar Visual Studio Code (Editor)"
    Write-Host "----------------------------------------------"
    Write-Host " [0] Sair"
    Write-Host "==============================================" -ForegroundColor Blue

    $Selection = Read-Host "Digite a letra/número da sua opção"
    return $Selection
}

# --- 5. Execução do Programa ---

do {
    $Choice = Show-Menu
    
    switch ($Choice.ToUpper()) {
        "A" {
            Write-Host "`n-- Executando Instalação COMPLETA --" -ForegroundColor Magenta
            Install-7Zip
            Install-GoogleChrome
            Install-VSCode
            Write-Host "`n-- Instalação COMPLETA Encerrada --" -ForegroundColor Magenta
            break # Volta para o menu após concluir tudo
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
        "0" {
            Write-Host "`nSaindo do Assistente. Até mais!" -ForegroundColor Red
            break # Sai do loop
        }
        default {
            Write-Host "`nOpção inválida. Tente novamente." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
    
    # Pausa antes de mostrar o menu novamente, a menos que seja a opção '0'
    if ($Choice -ne "0") {
        Read-Host "Pressione Enter para voltar ao menu principal" | Out-Null
        Clear-Host
    }

} while ($Choice -ne "0")

# --- 6. Limpeza Final (Opcional, mas recomendado) ---
Write-Host "`nLimpando arquivos temporários..." -ForegroundColor DarkGray
Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
