Clear-Host
#Config Variables
$SiteURL = "https://t6syv.sharepoint.com/sites/AnotherTest"
$FolderPath = "$PSScriptRoot\CsvFiles\"
$Batch = New-PnPBatch

$Files = Get-ChildItem -Path $FolderPath -File
foreach ($File in $Files){
        
#Get the folder name
$ListName = $File.BaseName
Write-Host $ListName

#Config Variable
$CSVFilePath = "$FolderPath$ListName.csv"

#Function to get Lookup ID from Lookup Value
Function Get-LookupID($ListName, $LookupFieldName, $LookupValue)
{
    #Get Parent Lookup List and Field from Child Lookup Field's Schema XML
    $LookupField =  Get-PnPField -List $ListName -Identity $LookupFieldName
    [Xml]$Schema = $LookupField.SchemaXml
    $ParentListID = $Schema.Field.Attributes["List"].'#text'
    $ParentField  = $Schema.field.Attributes["ShowField"].'#text'
    $ParentLookupItem  = Get-PnPListItem -List $ParentListID -Fields $ParentField | Where {$_[$ParentField] -eq $LookupValue} | Select -First 1 
    If($ParentLookupItem -ne $Null)  { Return $ParentLookupItem["ID"] }  Else  { Return $Null }
}
 
Try {
    #Connect to the Site
    Connect-PnPOnline -URL $SiteURL -Interactive
    
    #Get the data from CSV file
    $CSVData = Import-CSV $CSVFilePath
 
    #Get the List to Add Items
    $List = Get-PnPList -Identity $ListName
     
    #Get fields to Update from the List - Skip Read only, hidden fields, content type and attachments
    $ListFields = Get-PnPField -List $ListName | Where { (-Not ($_.ReadOnlyField)) -and (-Not ($_.Hidden)) -and ($_.InternalName -ne  "ContentType") -and ($_.InternalName -ne  "Attachments") }
      
    #Loop through each Row in the CSV file and update the matching list item ID
    ForEach($Row in $CSVData)
    {
        #Frame the List Item to update
        $ItemValue = @{}            
        $CSVFields = $Row | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name
        #Map each field from CSV to target list
        Foreach($CSVField in $CSVFields)
        {
           
            $MappedField = $ListFields | Where {$_.InternalName -eq $CSVField}
            
            If($MappedField -ne $Null)
            {
                $FieldName = $MappedField.InternalName
                #Check if the Field value is not Null
                If($Row.$CSVField -ne $Null)
                {
                    #Handle Special Fields
                    $FieldType  = $MappedField.TypeAsString 
                    
                    If($FieldType -eq "User" -or $FieldType -eq "UserMulti") #People Picker Field
                    {
                        $PeoplePickerValues = $Row.$FieldName.Split(",")
                        $ItemValue.add($FieldName,$PeoplePickerValues)
                    }
                    ElseIf($FieldType -eq "Lookup" -or $FieldType -eq "LookupMulti") #Lookup Field
                    {
                        $LookupIDs = $Row.$FieldName.Split(",") | ForEach-Object { Get-LookupID -ListName $ListName -LookupFieldName $FieldName -LookupValue $_ }                
                        $ItemValue.Add($FieldName,$LookupIDs)
                    }
                    ElseIf($FieldType -eq "DateTime")
                    {
                        $ItemValue.Add($FieldName,[DateTime]$Row.$FieldName)
                    }
                    Else
                    {
                        #Get Source Field Value and add to Hashtable
                        $ItemValue.Add($MappedField.InternalName,$Row.$CSVField)
                        Write-host $Row.$CSVField
                        }
                }
            }
            
            }
        
        Write-host "Adding List item with values: $ListName"
        $ItemValue | Format-Table
        Write-host $ItemValue.Values
        
         
        #Add New List Item
        Add-PnPListItem -List $ListName -Values $ItemValue -Batch $Batch | Out-Null 
    }
    Invoke-PnPBatch -Batch $Batch
}
Catch {
    write-host "Error: $($_.Exception.Message)"  -foregroundcolor Red
}


}