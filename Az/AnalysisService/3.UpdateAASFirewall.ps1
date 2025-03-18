#Created by Lei Zhang 2021-09-27
#Please import following Modules in advanced
#Az.Accounts
#Az.AnalysisServices


#AAS Firewall Rule Name
#should created in advanced
$ExistingFirewallRuleName = "AzureAutomationIP"
#3rd party IP
$PubIPSource = http://icanhazip.com/
#Azure Analysis Service Address
$Environmenturl = "asazure://chinaeast2.asazure.chinacloudapi.cn/leiaas"

#Connecting to Azure
$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -EnvironmentName AzureChinaCloud -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint

#Get parameter
#$ResourceGroupName = "AAS-RG"
#$ASServerName = "leiaas"
$ResourceGroupName = Get-AutomationVariable -Name 'AASResourceGroupName'
$ASServerName = Get-AutomationVariable -Name 'ASServerName'

$AServiceServer = Get-AzAnalysisServicesServer -ResourceGroupName $ResourceGroupName -Name $ASServerName
$FirewallRules = ($AServiceServer).FirewallConfig.FirewallRules
$FirewallRuleNameList = $FirewallRules.FirewallRuleName
$powerBi = ($AServiceServer).FirewallConfig.EnablePowerBIService

#Getting previous IP from firewall rule, and new public IP
$PreviousRuleIndex = [Array]::IndexOf($FirewallRuleNameList, $ExistingFirewallRuleName)

#Get Client IP from 3rd party
$currentIP = (Invoke-WebRequest -uri $PubIPSource -UseBasicParsing).content.TrimEnd()
#$currentIP = "202.96.255.228"

$previousIP = ($FirewallRules).RangeStart[$PreviousRuleIndex]

#Updating rules if request is coming from new IP address.
if (!($currentIP -eq $previousIP)) 
{
    Write-Output "Updating Analysis Service firewall config"
    $ruleNumberIndex = 1
    $Rules = @() -as [System.Collections.Generic.List[Microsoft.Azure.Commands.AnalysisServices.Models.PsAzureAnalysisServicesFirewallRule]]

    #Storing Analysis Service firewall rules
    $FirewallRules | ForEach-Object {
        $ruleNumberVar = "rule" + "$ruleNumberIndex"
        #Exception of storage of firewall rule is made for the rule to be updated
        if (!($_.FirewallRuleName -match "$ExistingFirewallRuleName")) {
            $start = $_.RangeStart
            $end = $_.RangeEnd
            $tempRule = New-AzAnalysisServicesFirewallRule `
                -FirewallRuleName $_.FirewallRuleName `
                -RangeStart $start `
                -RangeEnd $end

            Set-Variable -Name "$ruleNumberVar" -Value $tempRule
            $Rules.Add((Get-Variable $ruleNumberVar -ValueOnly))
            $ruleNumberIndex = $ruleNumberIndex + 1
        }
    }
    #Add rule for new IP
    $updatedRule = New-AzAnalysisServicesFirewallRule `
        -FirewallRuleName "$ExistingFirewallRuleName" `
        -RangeStart $currentIP `
        -RangeEnd $currentIP
    
    $ruleNumberVar = "rule" + "$ruleNumberIndex"
    Set-Variable -Name "$ruleNumberVar" -Value $updatedRule
    $Rules.Add((Get-Variable $ruleNumberVar -ValueOnly))

    #Creating Firewall config object
    if ($powerBi) {
        $conf = New-AzAnalysisServicesFirewallConfig -EnablePowerBIService -FirewallRule $Rules
    }
    else {
        $conf = New-AzAnalysisServicesFirewallConfig -FirewallRule $Rules
    }    
    
    Set-AzAnalysisServicesServer -ResourceGroupName $ResourceGroupName -Name $ASServerName -FirewallConfig $conf
    Write-Output "Updated firewall rule to include current IP: $currentIP"
}
