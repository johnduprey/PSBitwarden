function Start-RestServer {
    <#
    .SYNOPSIS
    Starts Bitwarden REST server
    
    .DESCRIPTION
    Uses `bw serve` to run local REST server
    
    .PARAMETER Port
    Port to run server on, default 8087
    
    .PARAMETER Hostname
    Hostname to run server on, default localhost

    .LINK
    https://bitwarden.com/help/cli/#serve
    
    #>
    [cmdletbinding()]
    Param(
        $Port = 8087,
        $Hostname = 'localhost'
    )

    $RunningCli = Get-Process bw -ErrorAction SilentlyContinue
    if ($RunningCli -and -not $script:BwRestServer) {
        $RunningCli | Stop-Process
    }

    $Arguments = @(
        'serve'
        "--port $Port"
        "--hostname $Hostname"    
    )

    try {
        $bw = Get-Command bw
        if (!$bw) {
            Write-Error 'Bitwarden CLI is not installed'
            return $false
        }
        $Proc = Start-Process -FilePath $bw.Path -ArgumentList $Arguments -NoNewWindow -PassThru -ErrorAction Stop
        
        $OldProgPref = $global:ProgressPreference
        $global:ProgressPreference = 'SilentlyContinue'
        
        do {
            $VaultRest = Test-NetConnection -ComputerName $Hostname -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
            Start-Sleep -Seconds 1
        } while (-not $VaultRest)

        $global:ProgressPreference = $OldProgPref

        $script:BwRestServer = [PSCustomObject]@{
            PID      = $Proc.Id
            Port     = $Port
            Hostname = $Hostname
        }
        $script:BwRestServer
    }
    catch {
        Write-Error 'Could not start REST server'
    }
}