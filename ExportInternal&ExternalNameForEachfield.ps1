Clear-Host
$SourceSiteURL = "https://t6syv.sharepoint.com/sites/EsraaTeamSite"
$SiteTitle = "EsraaTeamSite"
Connect-PnPOnline -Url $SourceSiteURL -Interactive
$SourceLists = Get-PnPList | Where { $_.BaseType -eq "GenericList" -and $_.Hidden -eq $False } | Select Title, Description, ItemCount
       
$LocalFolder = "$PSScriptRoot\InternalExternalNames"
#Create Local Folder, if it doesn't exist
If (!(Test-Path -Path $LocalFolder)) {
            New-Item -ItemType Directory -Path $LocalFolder | Out-Null
    Write-host -f Yellow "Ensured Folder '$LocalFolder'"
}        
ForEach ($SourceList in $SourceLists) {
$ListName = $SourceList.Title
        
$CSVPath = "$LocalFolder\InternalExternalNamesof$ListName.csv"
$ListDataCollection= @()
        
$ListRow = New-Object PSObject
        
$fields = Get-PnPField -List $ListName| Where {(-Not ($_.Hidden)) -and ($_.InternalName -ne  "ContentType") }
                
ForEach($field in $fields) {
$ListRow | Add-Member -MemberType NoteProperty -name $field.InternalName -Value $field.Title
        
    }
$ListDataCollection += $ListRow
        
        
        
        
#Export the result Array to CSV file
$ListDataCollection | Export-CSV $CSVPath -NoTypeInformation -Encoding UTF8
Write-Host "$ListName Fields Names has Exported"
                
}