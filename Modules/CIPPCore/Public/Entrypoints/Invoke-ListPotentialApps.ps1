using namespace System.Net

Function Invoke-ListPotentialApps {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Endpoint.Application.Read
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    $Headers = $Request.Headers
    Write-LogMessage -headers $Headers -API $APIName -message 'Accessed this API' -Sev 'Debug'

    if ($request.body.type -eq 'WinGet') {
        $body = @"
{"MaximumResults":50,"Filters":[{"PackageMatchField":"Market","RequestMatch":{"KeyWord":"US","MatchType":"CaseInsensitive"}}],"Query":{"KeyWord":"$($Request.Body.SearchString)","MatchType":"Substring"}}
"@
        $DataRequest = (Invoke-RestMethod -Uri 'https://storeedgefd.dsx.mp.microsoft.com/v9.0/manifestSearch' -Method POST -Body $body -ContentType 'Application/json').data | Select-Object @{l = 'applicationName'; e = { $_.packagename } }, @{l = 'packagename'; e = { $_.packageIdentifier } } | Sort-Object -Property applicationName
    }

    if ($Request.Body.type -eq 'Choco') {
        $DataRequest = Invoke-RestMethod -Uri "https://community.chocolatey.org/api/v2/Search()?`$filter=IsLatestVersion&`$skip=0&`$top=999&searchTerm=%27$($Request.Body.SearchString)%27&targetFramework=%27%27&includePrerelease=false" -ContentType 'application/json' | Select-Object @{l = 'applicationName'; e = { $_.properties.Title } }, @{l = 'packagename'; e = { $_.title.'#text' } } | Sort-Object -Property applicationName
    }


    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = @($DataRequest)
        })

}
