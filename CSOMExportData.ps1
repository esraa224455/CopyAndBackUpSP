clear-host
#Load SharePoint CSOM Assemblies
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
  
##Variables for Processing
$SiteUrl = "https://t6syv.sharepoint.com/sites/EsraaTeamSite"

$UserName="DiegoS@t6syv.onmicrosoft.com"
$Password ="PASo8543"
 
#Setup Credentials to connect
$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName,(ConvertTo-SecureString $Password -AsPlainText -Force))
 
#Set up the context
$Context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl) 
$Context.Credentials = $credentials
$Lists = $Context.web.Lists 
$Context.Load($Lists)
$context.ExecuteQuery()
$SelectedLists = $Lists | Where { $_.BaseType -eq "GenericList" -and $_.Hidden -eq $False }
foreach ($List in $SelectedLists){
#Get the List
$ListName= $List.Title
write-host $ListName

# Create Folder path to save CSV file
$LocalFolder = "$PSScriptRoot\CsvFiles"
#Create Local Folder, if it doesn't exist
If (!(Test-Path -Path $LocalFolder)) {
            New-Item -ItemType Directory -Path $LocalFolder | Out-Null
    Write-host -f Yellow "Ensured Folder '$LocalFolder'"
}


# path to save CSV file
$ExportFile ="$LocalFolder\$ListName.csv"

#Get All List Items
$Query = New-Object Microsoft.SharePoint.Client.CamlQuery
$ListItems = $List.GetItems($Query)
$context.Load($ListItems)
$fields = $List.Fields
$Context.Load($fields)
$context.ExecuteQuery()
 
#Array to Hold List Items 
$ListItemCollection = @() 
$Counter = 0
#Fetch each list item value to export to excel
 foreach($ListItem in $ListItems){
    $ExportItem = New-Object PSObject
    $fieldsToExport = $fields | Where-Object {(-Not $_.Hidden) -and ($_.InternalName -ne "ContentType") } 
    foreach($Field in $fieldsToExport) {
    
            if($NULL -ne $ListItem[$Field.InternalName])
            {
                #Expand the value of Person or Lookup fields
                $FieldType = $ListItem[$Field.InternalName].GetType().name
                if (($FieldType -eq "FieldLookupValue") -or ($FieldType -eq "FieldUserValue"))
                {
                    $FieldValue = $ListItem[$Field.InternalName].LookupValue
                }
                elseif(($FieldType -eq "FieldUrlValue")){
                    $FieldValue = $ListItem[$Field.InternalName].Url
                }
                
                else
                {
                    $FieldValue = $ListItem[$Field.InternalName]  
                }
            }
            else{
                $FieldType = $field.GetType().Name
                 If($FieldType -eq "FieldUrl"){
                    $FieldValue="https://"
                        write-host $FieldValue "/" $Field.Title
                    }else{
                    $FieldValue=""
                     }
            }
            $ExportItem | Add-Member -MemberType NoteProperty -name $Field.InternalName -value $FieldValue
    }
    $Counter++ 
    write-host $Counter
    #Add the object with the above properties to the Array
    $ListItemCollection += $ExportItem
 }
#Export the result Array to CSV file
$ListItemCollection | Export-CSV $ExportFile -NoTypeInformation -Encoding UTF8
 
Write-host "$ListName data Exported to CSV file successfully!"

}