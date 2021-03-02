[CmdletBinding()]
param (
    [string]$DeploymentName
)

$EKSClusterName = (Get-SSMParameter -Name "/$DeploymentName/eks/cluster/name").Value
$EKSDeploymentName = (Get-SSMParameter -Name "/$DeploymentName/eks/deployment/name").Value

# Load chocolatey module to refresh environment viriables in session
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."   
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

# Delete deployment items
kubectl delete ("deployment.apps/" + $EKSDeploymentName + "-nginx-ingress-controller")
kubectl delete ("service/" + $EKSDeploymentName + "-nginx-ingress-controller")
kubectl delete ("deployment.apps/" + $EKSDeploymentName + "-nginx-ingress-controller-default-backend")
kubectl delete ("service/" + $EKSDeploymentName + "-nginx-ingress-controller-default-backend")

# Uninstall helm deploymenbt
helm uninstall $EKSDeploymentName

# Set KUBECONFIG environment variable to 'Nothing'
[Environment]::SetEnvironmentVariable("KUBECONFIG", "NOTHING", [System.EnvironmentVariableTarget]::Machine)

# Refresh environment
refreshenv