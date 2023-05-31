#Function to Download All Files from a SharePoint Online Folder - Recursively  
Function Download-SPOFolder([Microsoft.SharePoint.Client.Folder]$Folder, $DestinationFolder)
{   
    #Get the Folder's Site Relative URL
    $FolderURL = $Folder.ServerRelativeUrl.Substring($Folder.Context.Web.ServerRelativeUrl.Length)
    $LocalFolder = $DestinationFolder + ($FolderURL -replace "/","\")
    #Create Local Folder, if it doesn't exist
    If (!(Test-Path -Path $LocalFolder)) {
            New-Item -ItemType Directory -Path $LocalFolder | Out-Null
            Write-host -f Yellow "Created a New Folder '$LocalFolder'"
    }
           
    #Get all Files from the folder
    $FilesColl = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderURL -ItemType File 
    #Iterate through each file and download
    Foreach($File in $FilesColl)
    {
        Get-PnPFile -ServerRelativeUrl $File.ServerRelativeUrl -Path $LocalFolder -FileName $File.Name -AsFile -force
        Write-host -f Green "`tDownloaded File from '$($File.ServerRelativeUrl)'"
    }
    #Get Subfolders of the Folder and call the function recursively
    $SubFolders = Get-PnPFolderItem -FolderSiteRelativeUrl $FolderURL -ItemType Folder
    Foreach ($Folder in $SubFolders | Where {$_.Name -ne "Forms"})
    {
        Download-SPOFolder $Folder $DestinationFolder
    }
} 

$SourceSiteURL = "https://t6syv.sharepoint.com/sites/EsraaTeamSite"
$SourceConn = Connect-PnPOnline -Url $SourceSiteURL -Interactive -ReturnConnection
$ExcludedLibrary = @("Site Pages")
    #Get all document libraries
$SourceLibraries = Get-PnPList -Includes RootFolder -Connection $SourceConn | Where { $_.BaseType -eq "DocumentLibrary" -and $_.Hidden -eq $False -and $_.Title -notin $ExcludedLibrary}
    Foreach($SourceLibrary in $SourceLibraries){
        Write-Host $SourceLibrary.RootFolder.ServerRelativeUrl
        $LibraryName = $SourceLibrary.RootFolder.ServerRelativeUrl
        Write-Host $LibraryName
        <#if($LibraryName -eq "Documents"){
        $LibraryURL = "/Shared $LibraryName"
        }
        else{
        $LibraryURL = "/$LibraryName" #Site Relative URL
        }#>
        $DownloadPath ="C:\Temp\"
        $Folder = Get-PnPFolder -Url $LibraryName

    #Call the function to download the document library
    Download-SPOFolder $Folder $DownloadPath
    }
