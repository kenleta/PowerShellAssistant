<#
.SYNOPSIS
    Universal PowerShell Assistant v1.1 (Production Ready)
    Features: Auto-Backup, Anti-Duplicate, and Built-in Local Uninstall.
#>

# --- Configuration & Paths ---
$targetProfilePath = $PROFILE
$targetProfileDir = Split-Path $targetProfilePath
$backupPath = "$targetProfilePath.bak"
$startTag = "# <PS-ASSISTANT-START>"
$endTag = "# <PS-ASSISTANT-END>"

# --- 1. Ensure Directory Exists ---
# Create the PowerShell profile directory if it doesn't exist (Handles local or OneDrive)
if (!(Test-Path $targetProfileDir)) {
    New-Item -Path $targetProfileDir -ItemType Directory -Force | Out-Null
}

# --- 2. Backup & Anti-Duplicate Logic ---
if (Test-Path $targetProfilePath) {
    $existingContent = Get-Content $targetProfilePath -Raw
    
    # Check if the assistant is already injected to avoid duplicates
    if ($existingContent -like "*$startTag*") {
        Write-Host "[!] Assistant is already installed. Reloading existing profile..." -ForegroundColor Cyan
        . $PROFILE
        return
    }
    
    # Create a .bak file only during the very first installation
    if (!(Test-Path $backupPath)) {
        Write-Host "[+] Creating initial backup: $(Split-Path $backupPath -Leaf)" -ForegroundColor Gray
        Copy-Item -Path $targetProfilePath -Destination $backupPath -Force
    }
}

# --- 3. Construct the Payload ---
# This body contains the core logic and the uninstallation function
$scriptBody = @"

$startTag
# ==============================================================================
# UNIVERSAL POWERSHELL ASSISTANT (v1.1)
# ==============================================================================

# --- [ Core Intelligence Logic ] ---
`$Global:ErrorMonitoringLogic = {
    `$lastError = `$error[0]
    if (!`$lastError) { return }

    # CASE 1: Command Not Found (Auto-Gallery Search)
    if (`$lastError.Exception -is [System.Management.Automation.CommandNotFoundException]) {
        `$cmdName = `$lastError.TargetObject
        `$originalLine = `$lastError.InvocationInfo.Line
        if (`$cmdName -match 'Disable-FeedbackProvider|Get-FeedbackProvider') { return }
        
        try {
            Write-Host "`n[!] Intelligence: Command '`$cmdName' is missing." -ForegroundColor Yellow
            `$confirm = (Read-Host "Search PowerShell Gallery? (Y/n)").ToLower()
            if ([string]::IsNullOrWhiteSpace(`$confirm) -or `$confirm -eq 'y') {
                Write-Host "Searching..." -ForegroundColor Cyan
                `$found = Find-Command -Name `$cmdName -ErrorAction Stop
                if (`$null -ne `$found -and ![string]::IsNullOrWhiteSpace(`$found.ModuleName)) {
                    `$modName = `$found.ModuleName
                    Write-Host "[+] Found in Module: `$modName" -ForegroundColor Green
                    `$install = (Read-Host "Install and Auto-Retry? (Y/n)").ToLower()
                    if ([string]::IsNullOrWhiteSpace(`$install) -or `$install -eq 'y') {
                        Install-Module -Name `$modName -Scope CurrentUser -Force -AllowClobber
                        Import-Module `$modName
                        Clear-Host
                        Write-Host "[Auto-Retry] Executing: `$originalLine" -ForegroundColor Cyan
                        Invoke-Expression `$originalLine
                    }
                } else { Write-Warning "[-] No module found." }
            }
        } catch { }
        finally { if (`$lastError -and !`$lastError.PSObject.Properties['ErrorChecked']) { `$lastError | Add-Member -MemberType NoteProperty -Name "ErrorChecked" -Value `$true -Force } }
    }

    # CASE 2: CD Space-Path Correction
    elseif (`$lastError.CategoryInfo.Activity -eq "Set-Location" -or `$lastError.FullyQualifiedErrorId -like "*PositionalParameter*") {
        `$failedLine = `$lastError.InvocationInfo.Line
        if (`$failedLine -match "^\s*(cd|sl|Set-Location)\s+(.*)") {
            `$potentialPath = `$matches[2].Trim().Trim('"').Trim("'")
            if (Test-Path `$potentialPath) {
                Set-Location `$potentialPath
                Write-Host "`n[🚀 Auto-Fix] Jumped to: `$potentialPath" -ForegroundColor Cyan
                `$lastError | Add-Member -MemberType NoteProperty -Name "ErrorChecked" -Value `$true -Force
            }
        }
    }
}

# --- [ Built-in Uninstallation Function ] ---
function Global:Uninstall-Assistant {
    Write-Host "[!] Initiating local uninstallation..." -ForegroundColor Yellow
    `$pPath = "`$PROFILE"
    `$bPath = "`$pPath.bak"
    
    if (Test-Path `$pPath) {
        `$content = Get-Content `$pPath -Raw
        `$pattern = "(?s)$startTag.*?$endTag"
        if (`$content -match `$pattern) {
            `$newContent = `$content -replace `$pattern, ""
            `$newContent.Trim() | Out-File -FilePath `$pPath -Encoding utf8 -Force
            Write-Host "[+] Assistant logic removed from profile." -ForegroundColor Green
        }
    }

    if (Test-Path `$bPath) {
        Write-Host "[+] Restoring original backup file..." -ForegroundColor Cyan
        Copy-Item -Path `$bPath -Destination `$pPath -Force
        Remove-Item `$bPath -Confirm:`$false
        Write-Host "[+] Restore complete. Please restart your PowerShell session." -ForegroundColor Green
    }
}

# --- [ Environment & Hooks ] ---
`$hasFeedback = Get-Command Disable-FeedbackProvider -ErrorAction SilentlyContinue
if (`$hasFeedback) { Disable-FeedbackProvider -Name 'General' -ErrorAction SilentlyContinue }

function prompt {
    `$lastError = `$error[0]
    if (`$lastError -and !`$lastError.ErrorChecked) {
        if ((`$lastError.Exception -is [System.Management.Automation.CommandNotFoundException]) -or 
            (`$lastError.CategoryInfo.Activity -eq "Set-Location") -or (`$lastError.FullyQualifiedErrorId -like "*PositionalParameter*")) {
            & `$Global:ErrorMonitoringLogic
            if (`$lastError -and !`$lastError.PSObject.Properties['ErrorChecked']) {
                `$lastError | Add-Member -MemberType NoteProperty -Name "ErrorChecked" -Value `$true -Force
            }
        }
    }
    "PS `$(`$executionContext.SessionState.Path.CurrentLocation)> "
}

Write-Host ">>> Universal Assistant v1.1 Loaded (Type 'Uninstall-Assistant' to remove)" -ForegroundColor Gray
$endTag
"@

# --- 4. Deployment ---
Write-Host "[+] Injecting Assistant into: $targetProfilePath" -ForegroundColor Cyan
# Append the logic to ensure we don't break existing user scripts
Add-Content -Path $targetProfilePath -Value $scriptBody -Encoding utf8

# Set Execution Policy to allow the profile script to run
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# --- 5. Activation ---
Write-Host "[!] Installation Successful. Profile activated." -ForegroundColor Green
. $PROFILE