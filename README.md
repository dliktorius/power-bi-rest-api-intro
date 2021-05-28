# power-bi-rest-api-intro
Presentation - Intro to Power BI REST API

## Running the Demos
Note: The included demos have the following requirements to run successfully.

### Demos 1 through 5
1. The Azure AD / Power BI user account you intend to use to run the demos MUST have a Power BI Pro license assigned.

2. The user account must be granted Admin rights to a workspace.

3. If you intend to supply credentials programmatically, this account must have MFA disabled or bypassed.

4. You may supply an explicit set of LoginUser and LoginPassword parameter values for each script OR omit them to be prompted interactively to login.

### Demo 5
Demo5-ExportReport.ps1 requires a Power BI Premium (Dedicated) Capacity to be provisioned and the Workspace hosting the Report you wish to export, must be assigned to the Premium Capacity.

## Resources

### Power BI Developer Landing Page
https://powerbi.microsoft.com/en-us/developers/

### Power BI REST API
https://docs.microsoft.com/en-us/rest/api/power-bi/

### PowerShell Cmdlets
https://docs.microsoft.com/en-us/powershell/power-bi/overview

### Power BI .NET C# SDK
https://github.com/microsoft/PowerBI-CSharp

### Power BI .NET NuGet Package
https://www.nuget.org/packages/Microsoft.PowerBI.Api/