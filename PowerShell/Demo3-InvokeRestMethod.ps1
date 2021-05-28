[CmdletBinding()]
<#
.SYNOPSIS
This demo uses the Invoke-PowerBIRestMethod Cmdlet to get the datasets in the workspace.

.DESCRIPTION
Uses the Invoke-PowerBIRestMethod Cmdlet to get the datasets in the workspace and outputs the results verbosely using Format-List.
If the user and password parameters are ommitted, you will be prompted to provide credentials.

.PARAMETER LoginUser
OPTIONAL: User account to login to Power BI

.PARAMETER LoginPassword
OPTIONAL: Password to login to Power BI

.PARAMETER WorkspaceName
REQUIRED: Name of the Power BI Workspace to list contents of

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

    # GET https://api.powerbi.com/v1.0/myorg/groups/{groupId}/datasets
    $response = Invoke-PowerBIRestMethod -Url "groups/$($workspace.Id)/datasets" -Method Get

    # Write-Output $response

    $obj = ConvertFrom-Json $response

    foreach ($dataset in $obj.value)
    {
        $dataset | Format-List
    }

    Write-Output "Done!"
}
catch {
    Write-Error "Error occurred while enumerating workspace contents: $($_)"
    throw $_
}