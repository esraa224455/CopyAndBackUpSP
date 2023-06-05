Clear-Host
#Set Parameters
$DestinationSiteURL = "https://t6syv.sharepoint.com/sites/TestCSVImport"
$FolderTempPath = "$PSScriptRoot\Temp"

#Function to copy list items from one list to another

Function Copy-SPOListItems()
{
    param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$DestinationSiteURL
    )
    Try {
        
        $DestinationConn = Connect-PnPOnline -Url $DestinationSiteURL -Interactive -ReturnConnection
        $DestinationLists = Get-PnPList -Connection $DestinationConn
        
        
        $Folders = Get-ChildItem -Path $FolderTempPath -File
        foreach ($Folder in $Folders){
        
        #Get the folder name
        $ListName = $Folder.Name
        Write-Host $ListName
        
        # Template Path
        $TemplateFile = "$FolderTempPath\$ListName"  
            
        #Apply the Template
        Invoke-PnPSiteTemplate -Path $TemplateFile -Connection $DestinationConn
}
   }
    Catch {
        Write-host -f Red "Error:" $_.Exception.Message
    }
} 
#Call the Function to Copy List Items between Lists
Copy-SPOListItems -DestinationSiteURL $DestinationSiteURL