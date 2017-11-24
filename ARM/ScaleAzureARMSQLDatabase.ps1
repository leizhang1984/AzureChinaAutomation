//Thanks MSFT GuoRong Feng
//Modified by MSFT Lei Zhang

workflow UpdateAzureSQLDatabase
{
    
    param(
				#设置订阅ID
                [Parameter(Mandatory = $true)] 
                [String] $SubscriptionId="YourSubscriptionID",	
				
				#设置资源组名称
                [Parameter(Mandatory = $true)] 
                [String] $ResourceGroupName="YourResourceGroup",
				
				#设置升级的服务名称
                [Parameter(Mandatory = $true)] 
                [String] $ServerName="servername",
				
                #设置升级的数据库名称
                [Parameter(Mandatory = $true)] 
                [String] $DatabaseName="dbname",
				
				#设置升级的版本
                [Parameter(Mandatory = $true)] 
                [String] $Edition="Standard",
				
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $Level="S0",		
				
                #设置升级的版本
                #[Parameter(Mandatory = $true)] 
                #[String] $SecondDBEdition="Standard",	
				
				#设置升级的级别
                #[Parameter(Mandatory = $true)] 
                #[String] $SecondDBLevel="S1",
				
				#设置升级的级别
                #[Parameter(Mandatory = $true)] 
                #[String] $SecondDBServerName="bmvr2aby7g",
               
				#设置重试次数
                [Parameter(Mandatory = $true)] 
                [Int32] $MaxTimes=3
    )
    Write-Verbose("开始调整Azure SQL Database DTU")
    $VerbosePreference="continue"
	
    $CredSScrpt = Get-AutomationPSCredential -Name 'AzureCredential'
         
    Add-AzureRMAccount -EnvironmentName 'AzureChinaCloud' -Credential $CredSScrpt

    #设定默认SubID
    Select-AzureRMSubscription -SubscriptionId $SubscriptionId
    
    #处理数据库1
    $msg= GetChinaTime + " 正在处理" + $ServerName + "的数据库" + $DatabaseName + " 升级为" + $Level
    Write-Verbose $msg
	
    TryScale -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -Edition $Edition -Level $Level  -MaxTimes $MaxTimes
	
	$msg = GetChinaTime + "升级完毕"
    Write-Verbose $msg
    
	
	Function GetChinaTime
	{
	  $ChinaTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneByID("China Standard Time")
      $Time = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)
      return $Time
	}
	
	
    Function TryScale{ 
    param(
				#设置资源组名称
                [Parameter(Mandatory = $true)] 
                [String] $ResourceGroupName,
				
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $ServerName,
				
                #设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $DatabaseName,
				
				#设置升级的版本
                [Parameter(Mandatory = $true)] 
                [String] $Edition,	
				
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $Level,

                #设置重试次数
                [Parameter(Mandatory = $true)] 
                [Int32] $MaxTimes   				
 )     
 Function ScaleDB
{
    param(
				#设置资源组名称
                [Parameter(Mandatory = $true)] 
                [String] $ResourceGroupName,
				
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $ServerName,
				
                #设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $DatabaseName,
				
				#设置升级的版本
                [Parameter(Mandatory = $true)] 
                [String] $Edition,	
				
				#设置升级的级别
                [Parameter(Mandatory = $true)] 
                [String] $Level        					
 )
  
            try{
                    $ErrorActionPreference = "Stop"
                    $msg="Trying Update database to Edition:" + $Edition + " Level:" + $Level  
                    Write-Verbose $msg     
                                                                   
                    Set-AzureRmSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName  -Edition $Edition -RequestedServiceObjectiveName $Level
					Write-Output "0"
            }
        catch 
        {
            $msg="Catched Error:"+  $_
            Write-Warning $msg 
           
            Write-Output -1
        }
}  
   
    $times=0
    $result=-1  
	
	do{
			$msg="Trying to scale "+$ServerName+" database "+$DatabaseName+" to "+$Level+" times:"+$times
		
			$result = ScaleDB -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName  -Edition $Edition -Level $Level
			Write-output $result
			Write-output $msg
			
			if($result -eq "0")
			{
				$msg="升级数据库成功！"
				Write-Output $msg
			}
			else
			{
				$msg="升级数据库失败，第"+$times+"次重试中!"
				Write-Output $msg
			}
			#do sleep here
			#start-sleep -s 300
			 $times=$times+1   
	}
	while(($result -eq -1) -and ($times -lt $MaxTimes))
    #当出现错误，超过指定次数时，发送Email到指定邮箱
    if($result -ne "0")
    {
        #$cred=Get-AutomationPSCredential -Name "mailaccount"
        #Write-output "Scale Failed"
        #Send-MailMessage -To "wifeng@microsoft.com"  -Subject "HelloWorld" -Body "Hello World!" -SMTPServer "smtp.163.com" -Credential $cred  -From "wingfeng@163.com" -BodyAsHtml
    }
   
  
	}
}