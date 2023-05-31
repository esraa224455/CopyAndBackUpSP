Clear-Host
#Define Variables
$AdminCenterURL = "https://t6syv-admin.sharepoint.com/"
$DestinationSiteURL = "https://t6syv.sharepoint.com/sites/New5544"
$SiteTitle = "New5544"
$SiteOwner = "DiegoS@t6syv.onmicrosoft.com"
$Template = "STS#3"
$Timezone = 4
  
Try {
    Connect-PnPOnline -URL $AdminCenterURL -Interactive
        #Check if site exists already
        $Site = Get-PnPTenantSite | Where { $_.Url -eq $DestinationSiteURL }
        If ($Site -eq $null) {
            #sharepoint online pnp powershell create a new team site collection
            New-PnPTenantSite -Owner $SiteOwner -Url $DestinationSiteURL -Title $SiteTitle -Template $Template -RemoveDeletedSite -TimeZone 4
            Start-Process $DestinationSiteURL
            write-host "Site Collection $($DestinationSiteURL) Created Successfully!" -foregroundcolor Green
            Start-Sleep -Seconds 20
            $Site = Get-PnPTenantSite -Identity $DestinationSiteURL
            while ($Site.Status -ne "Active") {
                Write-Host "Site collection is being provisioned. Waiting for 10 seconds..."
                $Site = Get-PnPTenantSite -Identity $DestinationSiteURL
            }
            Start-Process $DestinationSiteURL
        }
        else {
            write-host "Site $($DestinationSiteURL) exists already!" -foregroundcolor Yellow
        }
}
catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
   
}
