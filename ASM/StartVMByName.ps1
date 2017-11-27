workflow StartVMByName
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
                [String]$AzureSubscriptionName="[YourSubscriptionName]",
                
                #设置虚拟机名称，用分号分隔。虚拟机会按照先后顺序启动
                [Parameter(Mandatory = $true)] 
                [String]$VMNamesArray="aaa;sghazuios01;sghazuios02;sghazuios03",
                
                #设置每次启动的间隔时间，必须为数值型，单位为秒
                [Parameter(Mandatory = $true)] 
                [Int]$IntervalSeconds=50
    )

    $ChinaTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneByID("China Standard Time")
    $Start = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)

    "Starting Operation at UTC+8 Time: " + $Start.ToString("HH:mm:ss.ffffzzz")

    $AzurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
    $AzureOrgIdCredential = New-Object System.Management.Automation.PSCredential($AzureOrgId,$AzurePassword)

    Add-AzureAccount -Credential $AzureOrgIdCredential -environment "AzureChinaCloud" | Write-Verbose
    
    Select-AzureSubscription -SubscriptionName $AzureSubscriptionName
    
    $VMNames = $VMNamesArray -split ";"
    
    foreach ($VMName in $VMNames) 
    {
        #"Get VMNamesArray Configuration String " + $VMName
        
        $VMS = Get-AzureVM | Where-Object -FilterScript { $_.InstanceName -eq $VMName }
        if($VMS)
        {
            "VM Name " + $VMName + " is Existing"
            
            if($VMS.Status -eq "StoppedDeallocated" -or $VMS.Status -eq "Stopped")
            {
                  Start-AzureVM -ServiceName $VMS.ServiceName -Name $VMS.Name 
                  
                  #输出StartVM的UTC+8时间
                  $Start = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)   
                  $Start.ToString("HH:mm:ss.ffffzzz") + " Start VM : Service Name " +  $VMS.ServiceName + " VM Name " + $VMS.Name 
                  
                  "Sleep for " + $IntervalSeconds + " Seconds"
                  Start-Sleep -s $IntervalSeconds  
            }
        }
        else
        {
            "!!!!!!!!Warning : VM Name " + $VMName + " is NOT Existing, please check your configuration"
        }
    }
    
    $Finish = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)
    "Finished Operation at UTC+8 Time: " + $Finish.ToString("HH:mm:ss.ffffzzz")
    
} 

