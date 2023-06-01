Clear-Host
$SourceSiteURL = "https://t6syv.sharepoint.com/sites/EsraaTeamSite"
$SiteTitle = "EsraaTeamSite"
$SourceConn = Connect-PnPOnline -Url $SourceSiteURL -Interactive -ReturnConnection
$SourceLists = Get-PnPList -Connection $SourceConn | Where { $_.BaseType -eq "GenericList" -and $_.Hidden -eq $False } | Select Title, Description, ItemCount
       
        
        ForEach ($SourceList in $SourceLists) {
        $ListName = $SourceList.Title
        If($ListName -eq "العواصم"){
        $CSVPath = "c:\Temp\internalnameof$ListName.csv"
        $ListDataCollection= @()
        $Counter = 0
        $ListItems = Get-PnPListItem -List $ListName -PageSize 2000
        
        $ListRow = New-Object PSObject
        $Counter++
        $fields = Get-PnPField -List $ListName| Where {(-Not ($_.Hidden)) -and ($_.InternalName -ne  "ContentType") }
                
        ForEach($field in $fields) {
        $ListRow | Add-Member -MemberType NoteProperty -name $field.InternalName -Value $field.Title
        
            }
        Write-Progress -PercentComplete ($Counter / $($ListItems.Count)  * 100) -Activity "Exporting $ListName Items..." -Status  "Exporting Item $Counter of $($ListItems.Count)"
        $ListDataCollection += $ListRow
        
        
        
        
        #Export the result Array to CSV file
        $ListDataCollection | Export-CSV $CSVPath -NoTypeInformation -Encoding UTF8
        }        
        }