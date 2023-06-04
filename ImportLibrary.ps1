clear-host
#Variables
$SiteURL = "https://t6syv.sharepoint.com/sites/CsomSit"
$FolderPath = "C:\Temp\Libraries"
#Connect with SharePoint Online
Connect-PnPOnline -Url $SiteURL -UseWebLogin

# Loop through the folders within the given path
$Folders = Get-ChildItem $FolderPath -Directory

foreach ($Folder in $Folders){

    # Get the folder name
    $FolderName = $Folder.Name

    # Check if a library with the same name exists in the target site
    $Library = Get-PnPList -Identity $FolderName -ErrorAction SilentlyContinue
    if ($Library -eq $null) {

        # If the library does not exist, create it
        $Library = New-PnPList -Title $FolderName -Template DocumentLibrary
    }
$LocalFolderPath = "$FolderPath\$FolderName"
write-host $LocalFolderPath
$TargetFolderURL = $FolderName #Site Relative URL
#Call the function to upload the Root Folder
Upload-PnPFolder -LocalFolderPath $LocalFolderPath -TargetFolderURL $TargetFolderURL
 
#Get all Folders from given source path 
Get-ChildItem -Path $LocalFolderPath -Recurse -Directory | ForEach-Object {
    $FolderToUpload = ($TargetFolderURL+$_.FullName.Replace($LocalFolderPath,[string]::Empty)).Replace("\","/")
    Upload-PnPFolder -LocalFolderPath $_.FullName -TargetFolderURL $FolderToUpload
}
}
 
#Function to upload all files from a local folder to SharePoint Online Folder
Function Upload-PnPFolder($LocalFolderPath, $TargetFolderURL)
{
    Write-host "Processing Folder:"$LocalFolderPath -f Yellow
    #Get All files and SubFolders from the local disk
    $Files = Get-ChildItem -Path $LocalFolderPath -File
 
    #Ensure the target folder
    Resolve-PnPFolder -SiteRelativePath $TargetFolderURL | Out-Null
 
    #Upload All files from the local folder to SharePoint Online Folder
    ForEach ($File in $Files)
    {
        Add-PnPFile -Path "$($File.Directory)\$($File.Name)" -Folder $TargetFolderURL -Values @{"Title" = $($File.Name)} | Out-Null
        Write-host "`tUploaded File:"$File.FullName -f Green
    }
}
