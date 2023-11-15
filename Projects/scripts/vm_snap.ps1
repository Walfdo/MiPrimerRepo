

#-----------------------------------------------------------[Authentication]------------------------------------------------------------

#Log into Azure
Connect-AzAccount

#Select the correct subscription

Get-AzContext
Get-AzSubscription
Get-AzSubscription -SubscriptionName "P8-Real Hands-On Labs" | Select-AzSubscription


#----------------------------------------------------------[Declarations]-----------------------------------------------------------

$TimeStamp = (Get-Date)
$DateTime  = ([DateTime]$timestamp).ToUniversalTime()
$PeruTime = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($datetime, 'SA Pacific Standard Time')
$date = (Get-Date $PeruTime -UFormat "%Y%m%d-%H%M%S").ToString()
$FilePath = $(get-location).Path;

$SnapshotRGName ='1-e2fad92a-playground-sandbox'
$VMNames = @('vm-test-01','linux-test')
$SubscriptionId = '9734ed68-621d-47ed-babd-269110dbacb1'
$VMResourceGroup = '1-e2fad92a-playground-sandbox'
$SnapshotRGName ='1-e2fad92a-playground-sandbox'
$TaskName = 'CH2595843_';



#-----------------------------------------------------------[Functions]------------------------------------------------------------
function New-AZSnapshotArray {
    param(
        $SnapshotRGName,
        $vm,
        $VMResourceGroup
    )
        
        write-output $SnapshotRGName
        # Start OSDisk Snapshot
        $OSSnapshotname = $TaskName + $vm.Name+'_OSDisk'
        $OSSnapshot = New-AzSnapshotConfig -SourceUri  $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $vm.Location -CreateOption copy
        New-AzSnapshot  -Snapshot $ossnapshot -SnapshotName $OSSnapshotname  -ResourceGroupName $SnapshotRGName #| Out-File -FilePath $FullLogPath -Append 
        # Get all disk luns
        #$luns = $vm.StorageProfile.DataDisks.lun
        # Makes a table with snapshot information
        $lunsforsnapshots = $vm.StorageProfile.DataDisks | Select-Object Lun, Name, DiskSizeGB, @{N='Id'; E={$_.ManagedDisk.Id}} #| Where-Object { $luns -contains $_.Lun }
    
        # Genera el snapshot para cad|  a lun obtenida en $lunsforsnapshots
        foreach ($lun in $lunsforsnapshots){
            $snapshotname = $TaskName + $vm.Name+'_DataDisk_'+$lun.Lun
            $snapshot =  New-AzSnapshotConfig -SourceUri $lun.id -Location $vm.Location -CreateOption copy
            New-AzSnapshot  -Snapshot $snapshot -SnapshotName $snapshotname  -ResourceGroupName $SnapshotRGName #| Out-File -FilePath $FullLogPath -Append 
        }
    }
    #-----------------------------------------------------------[Execution]-------------------------------------------------------------

    if ($SubscriptionId){
        #Select-AzSubscription -SubscriptionId $SubscriptionId
        $subscription = get-AzSubscription -SubscriptionId $SubscriptionId | Select-AzSubscription
        foreach ($VMName in $VMNames){
            $vm = Get-AzVM -Name $VMName -ResourceGroupName $VMResourceGroup # -Status | Where-Object {$_.PowerState -like "VM Running"}
            New-AZSnapshotArray -SnapshotRGName $SnapshotRGName -vm $vm -VMResourceGroup $vm.ResourceGroup 
        }
    }

    else {
        # Run on all supported subscriptions
        $subscriptions = Get-AzSubscription  | Where-Object {($_.State -ne 'Disabled') -and ($_.Name -notin $SubscriptionsUnmanaged)} | select Name, Id, State
        write-output = ($subscriptions).Count

        foreach ($subscription in $subscriptions) {
            if ($subscription.State -ne "Disabled") {
                Select-AzSubscription -SubscriptionId $subscription.Id

                foreach ($VMName in $VMNames){
                    $vm = Get-AzVM -Name $VMName -ResourceGroupName $VMResourceGroup # -Status | Where-Object {$_.PowerState -like "VM Running"}
                    New-AZSnapshotArray -vm $vm -VMResourceGroup $vm.ResourceGroup
                }
            }
        }
    }