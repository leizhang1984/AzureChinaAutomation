######StopAllVM#####
#
.DESCRIPTION 
   Stop All VM under one subscription   
#
workflow StopAllVM
{
    param(
                #设置Org ID
                [parameter(Mandatory=$true)]
                [String]$AzureOrgId="[YourOrgID]",
          
                #设置Org ID的密码
                [Parameter(Mandatory = $true)] 
                [String]$Password="[YourPassword]",
                
                #设置订阅名称
                [Parameter(Mandatory = $true)] 
                [String]$AzureSubscriptionName="[YourSubscriptionName]"
    )
    
    $ChinaTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneByID("China Standard Time")
    $Start = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)

    $day = $Start.DayOfWeek 
    if ($day -eq 'Saturday' -or $day -eq 'Sunday')
    { 
	 "Exit due to weekends"
         exit 
    }  
    
    "Starting Operation at UTC+8 Time: "  + $Start.ToString("HHmmss.ffffzzz")

    $AzurePassword = $Password  ConvertTo-SecureString -AsPlainText -Force
    $AzureOrgIdCredential = New-Object System.Management.Automation.PSCredential($AzureOrgId,$AzurePassword)

    Add-AzureAccount -Credential $AzureOrgIdCredential -environment AzureChinaCloud  Write-Verbose
    
    Select-AzureSubscription -SubscriptionName $AzureSubscriptionName
    $VMS = Get-AzureVM 

    foreach($VM in $VMS)
        {    
            if($VMS.Status -eq ReadyRole)
            {
                $VMName = $VM.Name 
                Stop-AzureVM -ServiceName $VM.ServiceName -Name $VM.Name -Force
                Write-Output "Shutting down VM :" +  $VMName
            }
        }

    $Finish = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)
    "Finished Operation at UTC+8 Time: " + $Finish.ToString("HH:mm:ss.ffffzzz")
} 






