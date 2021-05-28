[CmdletBinding()]
<#
.SYNOPSIS
This example connects to Power BI and lists out the workspaces available to the credentialed user.

.DESCRIPTION
This example connects to Power BI and lists out the workspaces available to the credentialed user.
If the user and password parameters are ommitted, you will be prompted to provide credentials.

.PARAMETER LoginUser
OPTIONAL: User account to login to Power BI

.PARAMETER LoginPassword
OPTIONAL: Password to login to Power BI

#>
param(    
    [Parameter(Mandatory=$false)]
    [string]$LoginUser,
    
    [Parameter(Mandatory=$false)]
    [securestring]$LoginPassword
)

$ErrorActionPreference = "Stop"

# Install Power BI PowerShell Cmdlets Modules
if (-not(Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
    Write-Host "Installing module MicrosoftPowerBIMgmt ..."    
    Install-Module -Name MicrosoftPowerBIMgmt -Force
}

# Import Required Modules
Import-Module MicrosoftPowerBIMgmt
Import-Module MicrosoftPowerBIMgmt.Profile

try {        

    if ($null -eq $powerbiProfile)
    {
        if ($null -ne $LoginUser -and $null -ne $LoginPassword)
        {
            $credential = (New-Object System.Management.Automation.PSCredential($LoginUser, $LoginPassword))
            Write-Output "Authenticating to Power BI using supplied credentials ..."
            $powerbiProfile = Login-PowerBI -Credential $credential # alias for Connect-PowerBIServiceAccount
        } 
        else {
            Write-Output "Prompting user for Power BI credentials  ..."
            $powerbiProfile = Login-PowerBI
        }
    } 
    else {
        Write-Output "Using cached credentials ..."
    }

    Write-Output ""
}
catch {
    Write-Error "Power BI Authentication Error: $($_)"
    throw $_
}

try {
    # Loop through and present list of workspaces
    $workspaces = Get-PowerBIWorkspace

    foreach ($workspace in $workspaces)
    {
        Write-Output "Workspace: $($workspace.Name)"
        Write-Output "       Id: $($workspace.Id)"
        Write-Output ""
    }

    Write-Output "Done!"
}
catch {
    Write-Error "Error occurred while enumerating list of workspaces: $($_)"
    throw $_
}