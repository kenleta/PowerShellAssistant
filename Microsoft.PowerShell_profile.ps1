# ================================
# UNIVERSAL POWERSHELL ASSISTANT
# ================================

$Global:ErrorMonitoringLogic = {
    $lastError = $error[0]
    if (!$lastError) { return }

    # CASE 1: Command Not Found (Module Installer)
    if ($lastError.Exception -is [System.Management.Automation.CommandNotFoundException]) {
        $cmdName = $lastError.TargetObject
        $originalCommandLine = $lastError.InvocationInfo.Line
        
        # Prevention: Ignore internal dependency checks
        if ($cmdName -eq 'Disable-FeedbackProvider' -or $cmdName -eq 'Get-FeedbackProvider') { return }
        
        try {
            Write-Host "
[!] Intelligence: Command '$cmdName' is missing." -ForegroundColor Yellow
            $confirm = (Read-Host "Search PowerShell Gallery? (Y/n)").ToLower()
            if ([string]::IsNullOrWhiteSpace($confirm) -or $confirm -eq 'y') {
                Write-Host "Searching..." -ForegroundColor Cyan
                $found = Find-Command -Name $cmdName -ErrorAction Stop
                
                if ($null -ne $found -and ![string]::IsNullOrWhiteSpace($found.ModuleName)) {
                    $modName = $found.ModuleName
                    Write-Host "[+] Found in Module: $modName" -ForegroundColor Green
                    $install = (Read-Host "Install and Auto-Retry? (Y/n)").ToLower()
                    
                    if ([string]::IsNullOrWhiteSpace($install) -or $install -eq 'y') {
                        Write-Host "Installing module..." -ForegroundColor Yellow
                        Install-Module -Name $modName -Scope CurrentUser -Force -AllowClobber
                        Import-Module $modName
                        
                        Write-Host "Ready! Preparing to re-run..." -ForegroundColor Green
                        Start-Sleep -Seconds 1
                        Clear-Host
                        Write-Host "[Auto-Retry] Executing: $originalCommandLine" -ForegroundColor Cyan
                        Write-Host "--------------------------------------------------------" -ForegroundColor Gray
                        Invoke-Expression $originalCommandLine
                    }
                } else {
                    Write-Warning "[-] No module found for '$cmdName'."
                }
            }
        }
        catch {
            if ($_.Exception -is [System.Management.Automation.PipelineStoppedException]) {
                Write-Host "
[!] Interrupted by user." -ForegroundColor Gray
            } else {
                Write-Warning "[-] Search failed or interrupted."
            }
        }
        finally {
            if ($lastError -and !$lastError.PSObject.Properties['ErrorChecked']) {
                $lastError | Add-Member -MemberType NoteProperty -Name "ErrorChecked" -Value $true -Force
            }
        }
    }

    # CASE 2: CD Path with Spaces (The "Positional Parameter" Fix)
    elseif ($lastError.CategoryInfo.Activity -eq "Set-Location" -or 
            $lastError.FullyQualifiedErrorId -like "*PositionalParameter*" -or
            $lastError.Exception.Message -like "*positional parameter*") {
        
        $failedLine = $lastError.InvocationInfo.Line
        if ($failedLine -match "^\s*(cd|sl|Set-Location)\s+(.*)") {
            $potentialPath = $matches[2].Trim().Trim('"').Trim("'")
            
            if (Test-Path $potentialPath) {
                Set-Location $potentialPath
                Write-Host "
[🚀 Auto-Fix] Jumped to: $potentialPath" -ForegroundColor Cyan
                $lastError | Add-Member -MemberType NoteProperty -Name "ErrorChecked" -Value $true -Force
            }
        }
    }
}

# Environment Adaptation (Silent Detection)
$hasFeedbackCmd = Get-Command Disable-FeedbackProvider -ErrorAction SilentlyContinue
if ($hasFeedbackCmd) {
    Disable-FeedbackProvider -Name 'General' -ErrorAction SilentlyContinue
}

# Prompt Hook
function prompt {
    $lastError = $error[0]
    if ($lastError -and !$lastError.ErrorChecked) {
        $isCommandError = $lastError.Exception -is [System.Management.Automation.CommandNotFoundException]
        $isCdError = ($lastError.CategoryInfo.Activity -eq "Set-Location") -or ($lastError.FullyQualifiedErrorId -like "*PositionalParameter*")
        
        if ($isCommandError -or $isCdError) {
            & $Global:ErrorMonitoringLogic
            if ($lastError -and !$lastError.PSObject.Properties['ErrorChecked']) {
                $lastError | Add-Member -MemberType NoteProperty -Name "ErrorChecked" -Value $true -Force
            }
        }
    }
    "PS $($executionContext.SessionState.Path.CurrentLocation)> "
}

Write-Host ">>> Universal Assistant v1.0 Loaded" -ForegroundColor Gray
