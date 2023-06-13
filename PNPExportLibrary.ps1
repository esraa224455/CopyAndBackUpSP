#Parameters
$SourceSiteURL = "https://t6syv.sharepoint.com/sites/EsraaTeamSite"
$SiteName = "EsraaTeamSite"
$DownloadPath ="$PSScriptRoot\$SiteName"

$SourceConn = Connect-PnPOnline -Url $SourceSiteURL -Interactive -ReturnConnection

$Web = Get-PnPWeb -Connection $SourceConn
$ExcludedLibrary = @("Site Pages")
    #Get all document libraries
$SourceLibraries = Get-PnPList -Includes RootFolder -Connection $SourceConn | Where { $_.BaseType -eq "DocumentLibrary" -and $_.Hidden -eq $False -and $_.Title -notin $ExcludedLibrary}
    Foreach($SourceLibrary in $SourceLibraries){ 
        $LibraryUrl = $SourceLibrary.RootFolder.ServerRelativeUrl
        $LibraryName = Split-Path -Path $LibraryUrl -Leaf
        Write-Host $LibraryName      

#Get the list
$Library = Get-PnPList -Identity $LibraryName -Connection $SourceConn
If($Library.ItemCount -eq 0){
    $LocalFolder = $DownloadPath + "\$LibraryName" -replace "/","\"
    #Create Local Folder, if it doesn't exist
    If (!(Test-Path -Path $LocalFolder)) {
            New-Item -ItemType Directory -Path $LocalFolder | Out-Null
    }
    Write-host -f Yellow "Ensured Folder '$LocalFolder'"
}
else{
#Get all Items from the Library - with progress bar
$global:counter = 0
$LibraryItems = Get-PnPListItem -List $LibraryName -Connection $SourceConn -PageSize 500 -Fields ID -ScriptBlock { Param($items) $global:counter += $items.Count; Write-Progress -PercentComplete `
            ($global:Counter / ($Library.ItemCount) * 100) -Activity "Getting Items from Library:" -Status "Processing Items $global:Counter to $($Library.ItemCount)";} 
Write-Progress -Activity "Completed Retrieving Folders from Library $LibraryName" -Completed

#Get all Subfolders of the library
$SubFolders = $LibraryItems | Where {$_.FileSystemObjectType -eq "Folder" -and $_.FieldValues.FileLeafRef -ne "Forms"}
$SubFolders | ForEach-Object {
    #Ensure All Folders in the Local Path
    $LocalFolder = $DownloadPath + ($_.FieldValues.FileRef.Substring($Web.ServerRelativeUrl.Length)) -replace "/","\"
    #Create Local Folder, if it doesn't exist
    If (!(Test-Path -Path $LocalFolder)) {
            New-Item -ItemType Directory -Path $LocalFolder | Out-Null
    }
    Write-host -f Yellow "Ensured Folder '$LocalFolder'"
}
 
#Get all Files from the folder
$FilesColl =  $LibraryItems | Where {$_.FileSystemObjectType -eq "File"}
 
#Iterate through each file and download
$FilesColl | ForEach-Object {
    $FileDownloadPath = ($DownloadPath + ($_.FieldValues.FileRef.Substring($Web.ServerRelativeUrl.Length)) -replace "/","\").Replace($_.FieldValues.FileLeafRef,'')
    Get-PnPFile -ServerRelativeUrl $_.FieldValues.FileRef -Path $FileDownloadPath -FileName $_.FieldValues.FileLeafRef -Connection $SourceConn -AsFile -force 
    Write-host -f Green "Downloaded File from '$($_.FieldValues.FileRef)'"
    }
}
}