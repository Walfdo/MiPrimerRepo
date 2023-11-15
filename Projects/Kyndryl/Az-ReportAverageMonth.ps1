#----------------------------------------------------------[Parameters]-----------------------------------------------------------
param (

    [Parameter(Mandatory=$true)] [String]  $TenantID = "4389fecf-09b9-4e58-a8a1-60be4e33bcce",
    [Parameter(Mandatory=$false)] [String]  $subfijo = 'co'
)

$VerbosePreference='Continue'
#-----------------------------------------------------------[Authentication]------------------------------------------------------------

#Connect to Azure
#Connect-AzAccount -TenantId $TenantID 
#Connect-AzAccount -TenantId 00193bc8-dddd-41dd-8c93-264763bc0348


#----------------------------------------------------------[Declarations]-----------------------------------------------------------
$ClientID = "c1e8b4fe-7eb7-4cfc-b994-d2e95696d06a"
$TaskName = 'Average-Month'
$date = (Get-Date -UFormat "%Y-%m-%d-%H-%M-%S").ToString()
$dateColumn = (Get-Date -UFormat "%Y/%m/%d").ToString()

#$LogPath = $(get-location).Path;
$FilePath = $(get-location).Path;

#$LogName = $date + $TaskName + '.log';
$Filename = $date + $TaskName + $subfijo + '.csv';

#$FullLogName = Join-Path -Path $LogPath -ChildPath $LogName;
$FullFileName = Join-Path -Path $FilePath -ChildPath $FileName;
<#
[System.Collections.ArrayList]$Result = @()
$StorageAccountRG = 'arsgrinfeu1p01'
$StorageAccount = 'staccyecinfeu1prd01'
$StorageAccountContainer = 'reportes'
#>

$month_1 = (Get-Date).AddMonths(-1).ToString('MMMM',[CultureInfo]::CreateSpecificCulture("es-es"))
$month_2 = (Get-Date).AddMonths(-2).ToString('MMMM',[CultureInfo]::CreateSpecificCulture("es-es"))
$month_3 = (Get-Date).AddMonths(-3).ToString('MMMM',[CultureInfo]::CreateSpecificCulture("es-es"))

if ($TenantID -eq "4389fecf-09b9-4e58-a8a1-60be4e33bcce"){
  #Conexion a la subcripcion donde estan los recursos
  Switch ($subfijo){
      "pe" {
          Set-AzContext -Subscription "d0f9fb74-c43d-4d87-8167-c90bb965680b" | Out-null;
          $subscriptions = Get-AzSubscription | Where-Object { ($_.SubscriptionId -like 'd0f9fb74-c43d-4d87-8167-c90bb965680b') }
          Break
      }
      "co" {
          Set-AzContext -Subscription "a2515646-bf96-4315-9654-0d87faefcfad" | Out-null;
          $subscriptions = Get-AzSubscription | Where-Object { ($_.SubscriptionId -like 'a2515646-bf96-4315-9654-0d87faefcfad') }
          Break
      }
      "bol" {
          Set-AzContext -Subscription "2e2ccba2-3075-4acc-b7a4-8c7ee9441977" | Out-null;
          $subscriptions = Get-AzSubscription | Where-Object { ($_.SubscriptionId -like '2e2ccba2-3075-4acc-b7a4-8c7ee9441977') }
          Break
      }
      "ec" {
          Set-AzContext -Subscription "a6bcbf53-3951-40a7-afcd-2911a4a2e5eb" | Out-null;
          $subscriptions = Get-AzSubscription | Where-Object { ($_.SubscriptionId -like 'a6bcbf53-3951-40a7-afcd-2911a4a2e5eb') }
          Break
      }
  }
  
}

## Log Analytics Declarations
##Get the last three months
$today = Get-Date -Format "MM/dd/yyyy"#"yyyy-MM-ddT00:00:00Z"

#start date
$st1=(Get-Date (Get-Date $today).AddMonths(-3) -Day 1)
$st2=(Get-Date (Get-Date $today).AddMonths(-2) -Day 1)
$st3=(Get-Date (Get-Date $today).AddMonths(-1) -Day 1)

#end date
$et1=(Get-Date (Get-Date $today).AddMonths(-2) -Day 1).AddSeconds(-1)
$et2=(Get-Date (Get-Date $today).AddMonths(-1) -Day 1).AddSeconds(-1)
$et3=(Get-Date (Get-Date $today) -Day 1).AddSeconds(-1)

##Query Log Analytics##
#INSIGHTS
$queryMemoryWindows1 = '
let lastmonth = getmonth(datetime(now)) -3;
let year = getyear(datetime(now)); 
let monthEnd = endofmonth(datetime(now),-3); 

InsightsMetrics
| where TimeGenerated >= make_datetime(year,lastmonth,01) and TimeGenerated <= monthEnd
| where Namespace == "Memory"
| where Name == "AvailableMB"
| summarize avg(Val), min(Val), max(Val) by bin(TimeGenerated, 1h), Computer'

$queryMemoryWindows2 = '
let lastmonth = getmonth(datetime(now)) -2;
let year = getyear(datetime(now)); 
let monthEnd = endofmonth(datetime(now),-2); 

InsightsMetrics
| where TimeGenerated >= make_datetime(year,lastmonth,01) and TimeGenerated <= monthEnd
| where Namespace == "Memory"
| where Name == "AvailableMB"
| summarize avg(Val), min(Val), max(Val) by bin(TimeGenerated, 1h), Computer'

$queryMemoryWindows3 = '
let lastmonth = getmonth(datetime(now)) -1;
let year = getyear(datetime(now)); 
let monthEnd = endofmonth(datetime(now),-1); 

InsightsMetrics
| where TimeGenerated >= make_datetime(year,lastmonth,01) and TimeGenerated <= monthEnd
| where Namespace == "Memory"
| where Name == "AvailableMB"
| summarize avg(Val), min(Val), max(Val) by bin(TimeGenerated, 1h), Computer'

#PERF MEMORY

$queryMemoryComittedWindows1 = '
let lastmonth = getmonth(datetime(now)) -3;
let year = getyear(datetime(now)); 
let monthEnd = endofmonth(datetime(now),-3); 

Perf
| where TimeGenerated >= make_datetime(year,lastmonth,01) and TimeGenerated <= monthEnd
| where CounterName == "% Committed Bytes In Use"
| project TimeGenerated, CounterName, CounterValue,Computer 
| summarize avg(CounterValue) by CounterName, bin(TimeGenerated, 1h), Computer'

$queryMemoryComittedWindows2 = '
let lastmonth = getmonth(datetime(now)) -2;
let year = getyear(datetime(now)); 
let monthEnd = endofmonth(datetime(now),-2); 

Perf
| where TimeGenerated >= make_datetime(year,lastmonth,01) and TimeGenerated <= monthEnd
| where CounterName == "% Committed Bytes In Use"
| project TimeGenerated, CounterName, CounterValue,Computer 
| summarize avg(CounterValue) by CounterName, bin(TimeGenerated, 1h), Computer'

$queryMemoryComittedWindows3 = '

let lastmonth = getmonth(datetime(now)) -1;
let year = getyear(datetime(now)); 
let monthEnd = endofmonth(datetime(now),-1); 

Perf
| where TimeGenerated >= make_datetime(year,lastmonth,01) and TimeGenerated <= monthEnd
| where CounterName == "% Committed Bytes In Use"
| project TimeGenerated, CounterName, CounterValue,Computer 
| summarize avg(CounterValue) by CounterName, bin(TimeGenerated, 1h), Computer'


#PERF DISK
<##
$queryDiskWindows1 = '
let lastmonth = getmonth(datetime(now)) -3;
let year = getyear(datetime(now)); 
let monthEnd = endofmonth(datetime(now),-3); 


Perf
 | where TimeGenerated >= make_datetime(year,lastmonth,01) and TimeGenerated <= monthEnd
 | where ObjectName == "LogicalDisk"
 | where InstanceName == "_Total" and InstanceName !contains "HarddiskVolume"
 | where CounterName == "% Used Space" or CounterName contains "Free"
 | project  Computer, ObjectName, CounterName, InstanceName, CounterValue
 | summarize  by  Computer, ObjectName, CounterName, InstanceName, CounterValue
 | evaluate pivot(CounterName, avg(CounterValue))'

$queryDiskWindows2 = '
let lastmonth = getmonth(datetime(now)) -2;
let year = getyear(datetime(now)); 
let monthEnd = endofmonth(datetime(now),-2); 


Perf
 | where TimeGenerated >= make_datetime(year,lastmonth,01) and TimeGenerated <= monthEnd
 | where ObjectName == "LogicalDisk"
 | where InstanceName == "_Total" and InstanceName !contains "HarddiskVolume"
 | where CounterName == "% Used Space" or CounterName contains "Free"
 | project  Computer, ObjectName, CounterName, InstanceName, CounterValue
 | summarize  by  Computer, ObjectName, CounterName, InstanceName, CounterValue
 | evaluate pivot(CounterName, avg(CounterValue))'
#>
 $queryDiskWindows3 = '
let lastmonth = getmonth(datetime(now)) -1;
let year = getyear(datetime(now)); 
let monthEnd = endofmonth(datetime(now),-1); 


InsightsMetrics
| where TimeGenerated >= make_datetime(year,lastmonth,01) and TimeGenerated <= monthEnd
| where Origin == "vm.azm.ms" and Namespace == "LogicalDisk" and Name == "FreeSpaceMB"
| extend Disk = tostring(todynamic(Tags)["vm.azm.ms/mountId"]),
Disk_Size_GB =(todynamic(Tags)["vm.azm.ms/diskSizeMB"]) / 1024
| summarize Disk_Free_Space_GB = avg(Val) / 1024 by Computer, Disk, Disk_Size_GB, _ResourceId
| extend Used_Space_GB = Disk_Size_GB - Disk_Free_Space_GB
| extend Used_Space_Percentage = round((todouble(Used_Space_GB / Disk_Size_GB) * 100) ,2)
//| where Used_Space_Percentage >= 90
| project Computer, Disk, Disk_Size_GB, Disk_Free_Space_GB, Used_Space_GB, Used_Space_Percentage'


#-----------------------------------------------------------[Authentication]------------------------------------------------------------
##
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity
$AzureContext = (Connect-AzAccount -Identity -AccountId $ClientID).context
#Connect-AzAccount -Identity -AccountId $ClientID
# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

#-----------------------------------------------------------[Functions]------------------------------------------------------------

    function Get-MetricInfo {
       $metricinfo = [pscustomobject]@{
            'Date' = $dateColumn
            'SubscriptionName' = $subscriptions.Name
            'SubscriptionID' = $subscriptions.Id
            'Resource Group' = $vm.ResourceGroupName
            'Location' = $vm.Location
            'VM Name' = $vm.Name
            'Status' = $vm.powerstate
            'VM Size' = $vm.HardwareProfile.VMSize
            'Number of Core' = $cores.NumberofCores
            'Total Memory' = $memory
            "% CPU Average $month_3" = if($vm.ResourceGroupName -like '*prd*') {$cpu_ave_value1} else {''}
            "% CPU Average $month_2" = if($vm.ResourceGroupName -like '*prd*') {$cpu_ave_value2} else {''}
            "% CPU Average $month_1" = if($vm.ResourceGroupName -like '*prd*') {$cpu_ave_value3} else {''}
            "% Memory Average $month_3" = if($vm.ResourceGroupName -like '*prd*') {($memory - $mem_ave_value1)*100/$memory} else {''}
            "% Memory Average $month_2" = if($vm.ResourceGroupName -like '*prd*') {($memory - $mem_ave_value2)*100/$memory} else {''}
            "% Memory Average $month_1" = if($vm.ResourceGroupName -like '*prd*') {($memory - $mem_ave_value3)*100/$memory} else {''}
            "% Memory Commited Average $month_3" = if($vm.ResourceGroupName -like '*prd*') {$mem_com_ave_value1} else {''}
            "% Memory Commited Average $month_2" = if($vm.ResourceGroupName -like '*prd*') {$mem_com_ave_value2} else {''}
            "% Memory Commited Average $month_1" = if($vm.ResourceGroupName -like '*prd*') {$mem_com_ave_value3 } else {''}
            "% Disk $month_1" = if($vm.ResourceGroupName -like '*prd*') {$disk_ave_value3.Disk[$i]} else {''}#$disk_ave_value3.instancename[$i]
            'Space Usage in GB' = if($vm.ResourceGroupName -like '*prd*') {$disk_ave_value3.Used_Space_GB[$i]} else {''}#$TotalSpace - ([INT]$disk_ave_value3."Free Megabytes"[$i])/1024
            'Space Available in GB' = if($vm.ResourceGroupName -like '*prd*') {$disk_ave_value3.Disk_Free_Space_GB[$i]} else {''}#([INT]$disk_ave_value3."Free Megabytes"[$i])/1024
            'Threshold in GB' = if($vm.ResourceGroupName -like '*prd*') {($TotalSpace*85)/100} else {''}
            'Space Usage in %'= if($vm.ResourceGroupName -like '*prd*') {$disk_ave_value3.Used_Space_Percentage[$i]} else {''}#100 - ([INT]$disk_ave_value3."% Free Space"[$i])
            'Threshold in %' = "85.00"  
        }
		  return $metricinfo | Export-Csv -notypeinformation -Path $FullFileName -Encoding UTF8 -Append -Force;
		  #return $metricinfo | Export-Csv -notypeinformation -Path $UploadFile -Encoding UTF8 -Append -Force;
   }


#-----------------------------------------------------------[Execution]-------------------------------------------------------------

#Get VMs without Databricks, AKS y DaaS Citrix
$vms = Get-AzVM -Status | Where-Object {($_.StorageProfile.ImageReference.Offer -cnotcontains "Databricks") -and ($_.ResourceGroupName -cnotlike 'MC_*') -and ($_.StorageProfile.OsDisk.OsType -eq "Windows") } 


foreach($vm in $vms) {

    write-output "Comenzando con esta vm: $($vm.name)"
  
  $core=$memory=$cpu_ave1=$cpu_ave2=$cpu_ave3=$cpu_ave_value1=$cpu_ave_value2=$cpu_ave_value3=$lganworkspaceId=$memoryWindows1=$memoryWindows2=$memoryWindows3=$null
  $mem_ave_value1=$mem_ave_value2=$mem_ave_value3=$mem_com_ave_value1=$mem_com_ave_value2=$mem_com_ave_value3=$DiskWindows1=$DiskWindows2=$DiskWindows1=$null

        
        #Number of core
        $cores = Get-AzVMSize -location eastus2 | ?{ $_.name -eq $vm.HardwareProfile.VmSize } | Select NumberofCores

        #Usage memory
        $memory = (Get-AzVMSize -location eastus2 | ?{ $_.name -eq $vm.HardwareProfile.VmSize } | Select MemoryInMB).MemoryInMB

        #Percentage cpu usage Average
        $cpu_ave1 = Get-AzMetric -ResourceId $vm.Id -MetricName "Percentage CPU" -DetailedOutput -StartTime $st1 -EndTime $et1 -TimeGrain 01:00:00:00 -WarningAction SilentlyContinue
        $cpu_ave2 = Get-AzMetric -ResourceId $vm.Id -MetricName "Percentage CPU" -DetailedOutput -StartTime $st2 -EndTime $et2 -TimeGrain 01:00:00:00 -WarningAction SilentlyContinue
        $cpu_ave3 = Get-AzMetric -ResourceId $vm.Id -MetricName "Percentage CPU" -DetailedOutput -StartTime $st3 -EndTime $et3 -TimeGrain 01:00:00:00 -WarningAction SilentlyContinue

        #Value CPU metric
        $cpu_ave_value1=($cpu_ave1.Data.Average | measure -Average).Average
        $cpu_ave_value2=($cpu_ave2.Data.Average | measure -Average).Average
        $cpu_ave_value3=($cpu_ave3.Data.Average | measure -Average).Average
        
        ##Value memory-disk metrics
        #Get Log Analytics WorkspaceId INSIGHTS
        #Validacion de servicio activa de log analytic workspace
        #Si la subscripcion en cuestion tiene workspace habilitado            
        #$lganworkspaceId = ((Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.name -ExtensionName 'MicrosoftMonitoringAgent').PublicSettings | ConvertFrom-Json).workspaceId
        
        $lganworkspaceId = "3ff4beff-0882-4bc8-9b40-bd5d9074d019"#"d2cf8f8b-0aea-472b-ad4d-a4bcf771e896"

        #$VMInsight = Get-AZVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name | Select -ExpandProperty Extensions | Select Name, 

        if($vm.ResourceGroupName -like '*prd*') #if ( $lganworkspaceId -ne $null)
        {  
        #Data from Log Analytics to Powershell Memory Usage
        $memoryWindows1 = Invoke-AzOperationalInsightsQuery -WorkspaceId $lganworkspaceId -Query $queryMemoryWindows1
        $memoryWindows2 = Invoke-AzOperationalInsightsQuery -WorkspaceId $lganworkspaceId -Query $queryMemoryWindows2
        $memoryWindows3 = Invoke-AzOperationalInsightsQuery -WorkspaceId $lganworkspaceId -Query $queryMemoryWindows3

         #Data from Log Analytics to Powershell Memory comitted
        $memoryCommittedWindows1 = Invoke-AzOperationalInsightsQuery -WorkspaceId $lganworkspaceId -Query $queryMemoryComittedWindows1
        $memoryCommittedWindows2 = Invoke-AzOperationalInsightsQuery -WorkspaceId $lganworkspaceId -Query $queryMemoryComittedWindows2
        $memoryCommittedWindows3 = Invoke-AzOperationalInsightsQuery -WorkspaceId $lganworkspaceId -Query $queryMemoryComittedWindows3

                    
        #Value Memory metric
        $mem_ave_value1=(($memoryWindows1.Results | Where-Object {$_.Computer -like $vm.Name+'*'}).avg_Val | measure -Average).Average
        $mem_ave_value2=(($memoryWindows2.Results | Where-Object {$_.Computer -like $vm.Name+'*'}).avg_Val | measure -Average).Average
        $mem_ave_value3=(($memoryWindows3.Results | Where-Object {$_.Computer -like $vm.Name+'*'}).avg_Val | measure -Average).Average

        #Value Memory Comitted metric

        $mem_com_ave_value1=(($memoryCommittedWindows1.Results | Where-Object {$_.Computer -like $vm.Name+'*'}).avg_CounterValue | measure -Average).Average
        $mem_com_ave_value2=(($memoryCommittedWindows2.Results | Where-Object {$_.Computer -like $vm.Name+'*'}).avg_CounterValue | measure -Average).Average
        $mem_com_ave_value3=(($memoryCommittedWindows3.Results | Where-Object {$_.Computer -like $vm.Name+'*'}).avg_CounterValue | measure -Average).Average


        #Data from Log Analytics to Powershell Disk

        #$DiskWindows1 = Invoke-AzOperationalInsightsQuery -WorkspaceId $lganworkspaceId -Query $queryDiskWindows1
        #$DiskWindows2 = Invoke-AzOperationalInsightsQuery -WorkspaceId $lganworkspaceId -Query $queryDiskWindows2
        $DiskWindows3 = Invoke-AzOperationalInsightsQuery -WorkspaceId $lganworkspaceId -Query $queryDiskWindows3

        #Value Disk metric

      #  $disk_ave_value1=(($DiskWindows1.Results | Where-Object {$_.Computer -like $vm.Name+'*'}))
      #  $disk_ave_value2=(($DiskWindows2.Results | Where-Object {$_.Computer -like $vm.Name+'*'}))
        $disk_ave_value3=(($DiskWindows3.Results | Where-Object {$_.Computer -like $vm.Name+'*'}))

        
        #Se saca la informacion de capacidad libre en cada disco de la maquina virtual
        for ($i=0; $i -lt $disk_ave_value3.Count; $i++){ 
                
        $TotalSpace=[INT]$disk_ave_value3.Disk_Size_GB[$i]
        
        #$TotalSpace=(([INT]($disk_ave_value3."Free Megabytes"[$i])*100)/([INT]($disk_ave_value3."% Free Space"[$i])))/1024
         
           
        Get-MetricInfo
        Start-Sleep -Seconds 1
        
        }
        write-output "Successsful of getting the performance of the vm: $($vm.name)"
        Start-Sleep -Seconds 1
                   
                }
       #Si la vm no tiene VMInsight habilitado             
       else {

       Get-MetricInfo
       write-output "Suceesfull of getting the performance of the vm: $($vm.name)(No memory/No Disk performance)"
       Start-Sleep -Seconds 1}
  }
#-------------------------------------------------------------[Output]--------------------------------------------------------------

# Save the operation $FullFileName into a storage account staccyecinfeu1prd01/reportes.

$ctxlog = Set-AzStorageAccount -ResourceGroupName $StorageAccountRG -AccountName $StorageAccount -Type "Standard_LRS"
Set-AzStorageBlobContent -Context $ctxlog.Context -Container $StorageAccountContainer -File $FullFileName -Force -Verbose

