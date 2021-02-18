#https://docs.microsoft.com/en-us/azure/synapse-analytics/sql-data-warehouse/sql-data-warehouse-restore-points
#Get-Module Az* -List | Select-Object Name, Version, Path

$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -EnvironmentName AzureChinaCloud -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint

# ��ñ���
$ResourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
$ServerName = Get-AutomationVariable -Name 'SynapaseServerName'
$DatabaseName = Get-AutomationVariable -Name 'DatabaseName'

#ÿ�α���ʱ�䶼�ǵ���China Time Zoneʱ��
$ChinaTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneByID("China Standard Time")
$currentTime = [System.TimeZoneInfo]::ConvertTimefromUTC((get-date).ToUniversalTime(),$ChinaTimeZone)
$Label = $currentTime.ToString("yyyy-MM-dd HH:mm:ss.ffffzzz")

Write-Output $Label

#��õ�ǰSynapse״̬
$synapsestatus = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName

if ($synapsestatus.Status -ne "Online")
{
    Write-Output "Synapse�����������Ϊ����״̬"
    exit
}

#��ʼ����Synapse
New-AzSqlDatabaseRestorePoint -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -RestorePointLabel $Label

Write-Output "���ݳɹ�"