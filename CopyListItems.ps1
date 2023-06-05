 Clear-Host
#Set Parameters
$SourceSiteURL = "https://t6syv.sharepoint.com/sites/EsraaTeamSite"

$DestinationSiteURL = "https://t6syv.sharepoint.com/sites/NewCopyList"

$LocalFolder = "$PSScriptRoot\Temp"
#Function to copy list items from one list to another

Function Copy-SPOListItems()
{
    param
    (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$SourceSiteURL,
        [parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$DestinationSiteURL
    )
    Try {
        
        #Get All Items from the Source List in batches
       
        $SourceConn = Connect-PnPOnline -Url $SourceSiteURL -Interactive -ReturnConnection
        $SourceLists = Get-PnPList -Connection $SourceConn | Where { $_.BaseType -eq "GenericList" -and $_.Hidden -eq $False }
        $DestinationConn = Connect-PnPOnline -Url $DestinationSiteURL -Interactive -ReturnConnection
        $DestinationLists = Get-PnPList -Connection $DestinationConn
        
            ForEach ($SourceList in $SourceLists) {
            $ListName = $SourceList.Title 
            
            $TemplateFile = "$PSScriptRoot\Temp\Template$ListName.xml"
            Get-PnPSiteTemplate -Out $TemplateFile -ListsToExtract $ListName -Handlers Lists -Connection $SourceConn
          
            If (($DestinationLists.Title -contains $SourceList.Title)) {
                Remove-PnPList -Identity $ListName -Force -Connection $DestinationConn
                Write-host "Previous List '$($ListName)'removed successfully!" -f Green
            }       
 
            #Apply the Template
            Invoke-PnPSiteTemplate -Path $TemplateFile -Connection $DestinationConn
            Write-Host $TemplateFile
            Write-Progress -Activity "Reading Source..." -Status "Getting Items from Source List. Please wait..."
            $SourceListItems = Get-PnPListItem -List $ListName -Connection $SourceConn
            $Batch = New-PnPBatch -Connection $DestinationConn
            $SourceListItemsCount= $SourceListItems.count
            Write-host $ListName "Total Number of Items Found:"$SourceListItemsCount     
   
            #Get fields to Update from the Source List - Skip Read only, hidden fields, content type and attachments
            $SourceListFields = Get-PnPField -List $ListName -Connection $SourceConn | Where { (-Not ($_.ReadOnlyField)) -and (-Not ($_.Hidden)) -and ($_.InternalName -ne  "ContentType") -and ($_.InternalName -ne  "Attachments") }
        
            #Loop through each item in the source and Get column values, add them to Destination
            [int]$Counter = 1
            ForEach($SourceItem in $SourceListItems)
            { 
                $ItemValue = @{}
                #Map each field from source list to Destination list
                Foreach($SourceField in $SourceListFields)
                {
                    #Check if the Field value is not Null
                    If($SourceItem[$SourceField.InternalName] -ne $Null)
                    {
                        #Handle Special Fields
                        $FieldType  = $SourceField.TypeAsString                   
   
                        If($FieldType -eq "User" -or $FieldType -eq "UserMulti") #People Picker Field
                        {
                            $PeoplePickerValues = $SourceItem[$SourceField.InternalName] | ForEach-Object { $_.Email}
                            $ItemValue.add($SourceField.InternalName,$PeoplePickerValues) 
                        }
                        ElseIf($FieldType -eq "Lookup" -or $FieldType -eq "LookupMulti") # Lookup Field
                        {
                            $LookupIDs = $SourceItem[$SourceField.InternalName] | ForEach-Object { $_.LookupID.ToString()}
                            $ItemValue.add($SourceField.InternalName,$LookupIDs)
                        }
                        ElseIf($FieldType -eq "URL") #Hyperlink
                        {
                            $URL = $SourceItem[$SourceField.InternalName].URL
                            $Description  = $SourceItem[$SourceField.InternalName].Description
                            $ItemValue.add($SourceField.InternalName,"$URL, $Description")
                        }
                        ElseIf($FieldType -eq "TaxonomyFieldType" -or $FieldType -eq "TaxonomyFieldTypeMulti") #MMS
                        {
                            $TermGUIDs = $SourceItem[$SourceField.InternalName] | ForEach-Object { $_.TermGuid.ToString()}                   
                            $ItemValue.add($SourceField.InternalName,$TermGUIDs)
                        }
                        Else
                        {
                            #Get Source Field Value and add to Hashtable                       
                            $ItemValue.add($SourceField.InternalName,$SourceItem[$SourceField.InternalName])
                        }
                    }
                }
 
                Write-Progress -Activity "Copying List Items:" -Status "Copying Item ID '$($SourceItem.Id)' from Source List ($($Counter) of $($SourceListItemsCount))" -PercentComplete (($Counter / $SourceListItemsCount) * 100)
                
                
                Add-PnPListItem -List $ListName -Values $ItemValue -Connection $DestinationConn -Batch $Batch 
                 #Foreach($SourceField in $SourceListFields)
                 #{
                 #if($SourceField.InternalName -eq "LinkTitle"){
                     #     $FieldName = $SourceField.Title
                      #    $FieldInternalName = "Title"
                      #    Set-PnPField -List $ListName -Identity $FieldInternalName -Values  @{Title=$FieldName} -Connection $DestinationConn -ErrorAction Stop
                       #   Write-host -f Green "Title and Description Updated for Field '$FieldName'"
                  #} 
                  #}
                Write-Host $Counter
                Write-Host "Copied Item ID from Source to Destination List:$($SourceItem.Id) ($($Counter) of $($SourceListItemsCount))"
                $Counter++
            }
            

            Invoke-PnPBatch -Batch $Batch -Connection $DestinationConn
            Write-Host $ListName "Copied" -f Magenta
     
   
   
   
  
   }
   }
    Catch {
        Write-host -f Red "Error:" $_.Exception.Message
    }
} 
#Call the Function to Copy List Items between Lists
Copy-SPOListItems -SourceSiteURL $SourceSiteURL -DestinationSiteURL $DestinationSiteURL