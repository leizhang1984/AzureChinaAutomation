$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -EnvironmentName AzureChinaCloud -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint

# 获得变量
$ResourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
$ASServerName = Get-AutomationVariable -Name 'ASServerName'
$MinSKU = Get-AutomationVariable -Name 'MinSKU'
"AAS最小SKU为 " + $MinSKU

$MaxSKU = Get-AutomationVariable -Name 'MaxSKU'
"AAS最大SKU为 " + $MaxSKU

#获得当前AAS状态
$srv = Get-AzAnalysisServicesServer -ResourceGroupName $ResourceGroupName -Name $ASServerName -WarningAction silentlyContinue -ErrorAction Stop
$CurrentSKU = $srv.Sku.Name 
"当前AAS SKU为 " + $CurrentSKU

$CurrentCapacity = $srv.Sku.Capacity
"当前AAS Capacity为 " + $CurrentCapacity

if ($srv.State -ne "Succeeded")
{
    Write-Output "AAS服务必须设置为启动状态"
    exit
}

#提升SKU
Set-AzAnalysisServicesServer -ResourceGroupName $ResourceGroupName -Name $ASServerName -Sku $MaxSKU -ErrorAction Stop | Out-Null
"AAS SKU已经设置为" + $MaxSKU


