[CmdletBinding()]
<#
.SYNOPSIS
This example lists the contents (Datasets and Reports) in the specified workspace.

.DESCRIPTION
This example lists the contents (Datasets and Reports) in the specified workspace.
If the user and password parameters are ommitted, you will be prompted to provide credentials.

.PARAMETER LoginUser
OPTIONAL: User account to login to Power BI

.PARAMETER LoginPassword
OPTIONAL: Password to login to Power BI

.PARAMETER WorkspaceName
REQUIRED: Name of the Power BI Workspace to list contents of.

#>
param(    
    [Parameter(Mandatory=$false)]
    [string]$LoginUser,

    [Parameter(Mandatory=$false)]
    [securestring]$LoginPassword,
    
    [Parameter(Mandatory=$true)]
    [string]$WorkspaceName
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

    # Get all Datasets in workspace
    Write-Output ""
    Write-Output "Getting datasets ..."
    $datasets = Get-PowerBIDataset -WorkspaceId $workspace.Id

    foreach ($dataset in $datasets)
    {
        Write-Output "   $($dataset.Name)"
        Write-Output "   $($dataset.Id)"
    }

    # Get all Reports in workspace
    Write-Output ""
    Write-Output "Getting reports ..."
    $reports = Get-PowerBIReport -WorkspaceId $workspace.Id
   
    foreach ($report in $reports)
    {
        Write-Output "   $($report.Name)"
        Write-Output "   $($report.Id)"
    }

    Write-Output ""
    Write-Output "Done!"
}
catch {
    Write-Error "Error occurred while enumerating workspace contents: $($_)"
    throw $_
}