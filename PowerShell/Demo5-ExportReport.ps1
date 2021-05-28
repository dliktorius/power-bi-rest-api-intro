[CmdletBinding()]
<#
.SYNOPSIS
This script exports the specified Power BI Report from the specified Workspace to a .PDF at the file path provided.

.DESCRIPTION
This script exports the specified Power BI Report from the specified Workspace to a .PDF at the file path provided.

.PARAMETER LoginUser
User account to login to Power BI

.PARAMETER LoginPassword
Password to login to Power BI

.PARAMETER WorkspaceId
Guid ID of the Power BI Workspace to export from.

.PARAMETER ReportId
Guid ID of the Power BI Report to export.

.PARAMETER ExportPath
Folder/Directoy path to export to. DO NOT include file name or extension. Defaults to local path executing script from.

#>
param(    
    [Parameter(Mandatory=$false)]
    [string]$LoginUser,

    [Parameter(Mandatory=$false)]
    [securestring]$LoginPassword,

    [Parameter(Mandatory=$true)]
    [string]$WorkspaceId,

    [Parameter(Mandatory=$true)]
    [string]$ReportId,

    [Parameter(Mandatory=$false)]
    [string]$ExportPath = ".\"
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

# Get handle to Power BI API Endpoint for later use
$powerBiEndpoint = "$($powerbiProfile.Environment.GlobalServiceEndpoint)/v1.0/myorg/"

# Get Power BI session access token for lower-level Invoke-RestMethod and Invoke-WebRequest calls
$accessTokenHeaders = Get-PowerBIAccessToken

# This will be set to try only if we fully export and download successfully
$exportSuccess = $false

try {

    # First get a reference to the workspace by id
    Write-Output "Getting workspace [$($WorkspaceId)] ..."
    $workspace = Get-PowerBIWorkspace -Id $WorkspaceId

    if ($null -eq $workspace)
    {
        Throw "Unable to get workspace id: $($WorkspaceId)"
    }

    # Next, get a reference to the report by id
    Write-Output "Getting report [$($ReportId)] ..."
    $report = Get-PowerBIReport -Id $ReportId -WorkspaceId $workspace.Id

    if ($null -eq $report)
    {
        Throw "Unable to get report id: $($ReportId)"
    }

    # build request body to POST to ExportTo
    $objBody = @{
        format = "PDF"
    }

    # convert request body objec to JSON string
    $jsonBody = ConvertTo-Json $objBody -Depth 15

    Write-Output "Calling ExportTo ..."

    try {
        # POST to /groups/{groupId}/reports/{reportId}/ExportTo
        $url = "$($powerBiEndpoint)groups/$($workspace.Id)/reports/$($report.Id)/ExportTo"
        $response = Invoke-RestMethod -Headers $accessTokenHeaders -Uri $url -Method Post -ContentType "application/json" -Body $jsonBody
    }
    catch {
        # most likely warning that report is not hosted on dedicated (premium) capacity
        Write-Warning "Error received trying to queue export: $_"
        Write-Output "Exiting..."
        Exit
    }
    
    $objResponse = ConvertFrom-Json $response  

    $exportId = $objResponse.Id

    Write-Output "Export Id Queued: $($exportId)"

    $url = "groups/$($workspace.Id)/reports/$($report.Id)/exports/$($exportId)"

    for ($i=0; $i -lt 12; $i++)
    {
        Write-Output "Getting export status ..."

        # GET from /groups/{groupId}/reports/{reportId}/exports/{exportId}
        $response = Invoke-PowerBIRestMethod -Url $url -Method Get
        $objResponse = ConvertFrom-Json $response

        $status = $objResponse.status

        Write-Output "Status: $($status)"

        if ($objResponse.status -eq "Succeeded")
        {
            Write-Output "Downloading Report ..."

            $reportFileName = $report.Name.Replace(" ", "")
            $outFilePath = [System.IO.Path]::Combine($ExportPath, $reportFileName, ".pdf")

            # GET from export file resource location
            Invoke-WebRequest $objResponse.resourceLocation -Headers $accessTokenHeaders -OutFile $outFilePath
            
            Write-Output "Report downloaded successfully to: $($outFilePath)"

            $exportSuccess = $true

            break
        }
        
        Write-Output "Waiting 5 seconds to re-check ..."
        Start-Sleep -Seconds 5
    }

    if ($exportSuccess -eq $false)
    {
        Write-Warning "Checks timed out waiting for export to complete. Report was not downloaded."
    }
}
catch {
    Write-Error "Error while exporting report: $($_)"
    throw $_
}