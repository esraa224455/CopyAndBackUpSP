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
$ExportFile ="c:\Temp\List$ListName.csv"

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
    $fieldsToExport = $fields | Where-Object { (-Not $_.ReadOnlyField) -and (-Not $_.Hidden) -and ($_.InternalName -ne "ContentType") } 
    foreach($Field in $fieldsToExport) {
     
    $ExportItem | Add-Member -MemberType NoteProperty -name $Field.Title -Value $ListItem[$Field.InternalName]
    }
    $Counter++ 
    write-host $Counter
    write-host $ExportItem
    #Add the object with the above properties to the Array
    $ListItemCollection += $ExportItem
 }
 write-host $ListItemCollection
#Export the result Array to CSV file
$ListItemCollection | Export-CSV $ExportFile -NoTypeInformation -Encoding UTF8
 
Write-host "List data Exported to CSV file successfully!"
}