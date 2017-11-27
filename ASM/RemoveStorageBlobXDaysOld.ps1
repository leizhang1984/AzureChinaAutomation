######RemoveStorageBlobXDaysOld#####
<#
.SYNOPSIS
   Remove all blob contents from one storage account that are X days old.
.DESCRIPTION 
   This script will run through a single Azure storage account and delete all blob contents in 
   all containers, which are X days old.

   
#>
workflow RemoveStorageBlobXDaysOld
{
    param(
                #设置Org ID
                [parameter(Mandatory=$true)]
                [String]$AzureOrgId="[YourAzureOrgID]",
          
                #设置Org ID的密码
                [Parameter(Mandatory = $true)] 
                [String]$Password="[YourAzureOrgIDPassword]",
                
                #设置订阅名称
                [Parameter(Mandatory = $true)] 
                [String]$AzureSubscriptionName="[YourSubscriptionName]",
                
                #设置存储账号
                [Parameter(Mandatory = $true)]
                [String]$StorageAccountName="[YourStorageAccount]",
                
                #设置Container Name
                [Parameter(Mandatory = $true)]
                [String]$ContainerName="[YourStorageAccountContainerName]",
            
                #设置过期时间
                [Parameter(Mandatory = $true)] 
                [Int32]$DaysOld=[XDaysOld]
    )

    $ChinaTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneByID("China Standard Time")
    $Start = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)
    "Starting: " + $Start.ToString("HH:mm:ss.ffffzzz")


    $AzurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
    $AzureOrgIdCredential = New-Object System.Management.Automation.PSCredential($AzureOrgId,$AzurePassword)

    Add-AzureAccount -Credential $AzureOrgIdCredential -environment "AzureChinaCloud" | Write-Verbose
    
    Set-AzureSubscription -SubscriptionName $AzureSubscriptionName -CurrentStorageAccountName $StorageAccountName
    Select-AzureSubscription -SubscriptionName $AzureSubscriptionName

    

    
    # loop through each container and get list of blobs for each container and delete
    $blobsremoved = 0
    $containers = Get-AzureStorageContainer -Name $ContainerName -ErrorAction SilentlyContinue
    
    foreach($container in $containers) 
    { 
        $blobsremovedincontainer = 0       
        Write-Output ("Searching Container: {0}" -f $container.Name)   
        $blobs = Get-AzureStorageBlob -Container $container.Name 

        if ($blobs -ne $null)
        {    
            foreach ($blob in $blobs)
            {
               $lastModified = $blob.LastModified
               if ($lastModified -ne $null)
               {
                   $blobDays = ([DateTime]::Now - [DateTime]$lastModified)
                   Write-Output ("Blob {0} in storage for {1} days" -f $blob.Name, $blobDays) 
               
                   if ($blobDays.Days -ge $DaysOld)
                   {
                        Write-Output ("Removing Blob: {0}" -f $blob.Name)
                        Remove-AzureStorageBlob -Blob $blob.Name -Container $container.Name 
                        $blobsremoved += 1
                        $blobsremovedincontainer += 1
                   }
                }
            }
        }
        
        Write-Output ("{0} blobs removed from container {1}." -f $blobsremovedincontainer, $container.Name)       
    }
    
    $ChinaTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneByID("China Standard Time")
    $Finish = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)
     
    $TotalUsed = $Finish.Subtract($Start).TotalSeconds
   
    Write-Output ("Removed {0} blobs in {1} containers in storage account {2} of subscription {3} in {4} seconds." -f $blobsRemoved, $containersremoved, $StorageAccountName, $AzureConnectionName, $TotalUsed)
    "Finished " + $Finish.ToString("HH:mm:ss.ffffzzz")
} 






