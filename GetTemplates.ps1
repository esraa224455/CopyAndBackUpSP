Clear-Host
#Set Parameters
$SourceSiteURL = "https://t6syv.sharepoint.com/sites/EsraaTeamSite"
$LocalFolder= "$PSScriptRoot\Temp"

#Function to copy list items from one list to another

Function Copy-SPOListItems()
{
    param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$SourceSiteURL
    )
    Try {
        #Path To Store Templates In
        
        Connect-PnPOnline -Url $SourceSiteURL -Interactive 
        $SourceLists = Get-PnPList | Where { $_.BaseType -eq "GenericList" -and $_.Hidden -eq $False }   
        ForEach ($SourceList in $SourceLists) {
        $ListName = $SourceList.Title 
        $TemplateFile = "$LocalFolder\Template$ListName.xml"
        Get-PnPSiteTemplate -Out $TemplateFile -ListsToExtract $ListName -Handlers Lists -Connection $SourceConn

        Write-Host $ListName "Copied" -f Magenta
        }
       }
    Catch {
        Write-host -f Red "Error:" $_.Exception.Message
          }
} 
#Call the Function to Copy List Items between Lists
Copy-SPOListItems -SourceSiteURL $SourceSiteURL 