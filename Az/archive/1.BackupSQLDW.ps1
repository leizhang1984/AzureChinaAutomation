#https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-restore-points
#Get-Module Az* -List | Select-Object Name, Version, Path

$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -EnvironmentName AzureChinaCloud -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint

# 获得变量
$ResourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
$ServerName = Get-AutomationVariable -Name 'SynapaseServerName'
$DatabaseName = Get-AutomationVariable -Name 'DatabaseName'

#每次变量时间都是当天China Time Zone时间
$ChinaTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneByID("China Standard Time")
$currentTime = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)
$Label = $currentTime.ToString("yyyy-MM-dd HH:mm:ss.ffffzzz")

Write-Output $Label

#获得当前Synapse状态
$synapsestatus = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName

if ($synapsestatus.Status -ne "Online")
{
    Write-Output "Synapse服务必须设置为启动状态"
    exit
}

#开始备份Synapse
New-AzSqlDatabaseRestorePoint -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -RestorePointLabel $Label

Write-Output "备份成功"