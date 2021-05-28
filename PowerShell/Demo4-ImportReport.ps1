[CmdletBinding()]
<#
.SYNOPSIS
This example imports a .PBIX report (and dataset) into the specified workspace.

.DESCRIPTION
Imports a .PBIX report (and dataset) into the specified workspace.
If the user and password parameters are ommitted, you will be prompted to provide credentials.

.PARAMETER LoginUser
OPTIONAL: User account to login to Power BI

.PARAMETER LoginPassword
OPTIONAL: Password to login to Power BI

.PARAMETER PBIX
REQUIRED: Full path to the .pbix file to import.

.PARAMETER ReportName
REQUIRED: Name of the Power BI Report to import.

.PARAMETER WorkspaceName
REQUIRED: Name of the Power BI Workspace to import into.

#>
param(    
    [Parameter(Mandatory=$false)]
    [string]$LoginUser,

    [Parameter(Mandatory=$false)]
    [securestring]$LoginPassword,

    [Parameter(Mandatory=$true)]
    [string]$PBIX,

    [Parameter(Mandatory=$true)]
    [string]$ReportName,

    [Parameter(Mandatory=$true)]
    [string]$WorkspaceName
)

$ErrorActionPreference = "Stop"

# Power BI PowerShell Cmdlets Modules
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
        else 
        {
            Write-Output "Prompting user for Power BI credentials  ..."
            $powerbiProfile = Login-PowerBI
        }
    } 
    else 
    {
        Write-Output "Using cached credentials ..."
    }

    Write-Output ""
}
catch {
    Write-Error "Power BI Authentication Error: $($_)"
    throw $_
}

try {

    # First get a reference to the workspace by name
    Write-Output "Getting workspace '$($WorkspaceName)' ..."
    $workspace = Get-PowerBIWorkspace -Name $WorkspaceName

    if ($null -eq $workspace)
    {
        Throw "Unable to get workspace named: $($WorkspaceName)"
    }

    # Now import the .pbix file with the provided name into the workspace
    Write-Output "Importing report '$($ReportName)' into '$($WorkspaceName)' from: $($PBIX)"
    New-PowerBIReport -Path $PBIX -Name $ReportName -WorkspaceId $workspace.Id -ConflictAction CreateOrOverwrite

}
catch {
    Write-Error "Error while importing report: $($_)"
    throw $_
}