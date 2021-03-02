$QSS3BucketName = 'tcat-0eab2dca75865eb1b038a256aa258635-us-east-1'
$QSS3BucketRegion = 'us-east-1'
$QSS3KeyPrefix = 'quickstart-slalom-sitecore/' 
$DeploymentName = 'xcuzfvkntmxcncyqmlim-tb-test-pars' 
$DeploymentPrefix = 'tb-test-pars' 
$DeploymentS3BucketName = 'tbulding-ci-media'
$DeploymentS3KeyPrefix = 'sitecore/eks/'
$DeploymentS3BucketRegion = 'us-east-1'
$localPath = "c:\$DeploymentPrefix\resources"
$qsLocalPath = "c:\$DeploymentPrefix\quickstart"
# Install packages and modules
Add-Type -AssemblyName System.IO.Compression.FileSystem
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module AWS.Tools.S3, AWS.Tools.CloudWatchLogs, AWS.Tools.SimpleSystemsManagement, AWS.Tools.SecretsManager -Confirm:$false -Force -Scope AllUsers
Import-Module AWS.Tools.S3, AWS.Tools.CloudwatchLogs, AWS.Tools.SimpleSystemsManagement, AWS.Tools.SecretsManager
Read-S3Object -BucketName $QSS3BucketName -Region $QSS3BucketRegion -KeyPrefix ("/" + $QSS3KeyPrefix + "submodules/quickstart-microsoft-utilities/modules/AWSQuickStart/") -Folder "$qslocalpath"
Import-Module "$qslocalpath\AWSQuickStart.psm1"
# Configure CloudWatch Logging
$logGroupName = "$QSS3KeyPrefix-kb8-job"
$logStreamName = "PrepPod-" + (Get-Date (Get-Date).ToUniversalTime() -Format "MM-dd-yyyy" )
#
$logString = "****************** Begin Logging *************************"
Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $LogString
$logString = 'Installing Chocolatey'
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) | Tee-Object -Variable Output
    $logString = $logString, $Output -join "`r`n" 
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString   
}
catch {
    $logString = ($logString + " *** Error *** " + $_.Exception.Message)
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
$logString = 'Installing Kubernetes CLI'
try {
    choco install kubernetes-cli -y | Tee-Object -Variable Output
    $logString = $logString, $Output -join "`r`n" 
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString
}
catch {
    $logString = ($logString + " *** Error *** " + $_.Exception.Message)
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
$logString = 'Installing mkcert'
try {
    choco install mkcert -y | Tee-Object -Variable Output
    $logString = $logString, $Output -join "`r`n" 
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString
}
catch {
    $logString = ($logString + " *** Error *** " + $_.Exception.Message)
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
$logString = 'Downloading S3 Objects'
try {
    Read-S3Object -BucketName $QSS3BucketName -Region $QSS3BucketRegion -KeyPrefix ("/" + $QSS3KeyPrefix + "scripts/install/") -Folder $qslocalpath
    Read-S3Object -BucketName $DeploymentS3BucketName -Region $DeploymentS3BucketRegion -KeyPrefix ("/" + $DeploymentS3KeyPrefix + "resources/") -Folder $localpath
    Read-S3Object -BucketName $DeploymentS3BucketName -Region $DeploymentS3BucketRegion -KeyPrefix ("/" + $DeploymentS3KeyPrefix + "license/") -Folder $localpath
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $LogString
}
catch {
    $logString = ($logString + " *** Error *** " + $_.Exception.Message)
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
$logString = 'Extracting Product Installer'
try {
    foreach ($sourceFile in (Get-ChildItem -Path $localpath -filter "*.zip")) {
        $entries = [IO.Compression.ZipFile]::OpenRead($sourceFile.FullName).Entries | Where-Object { $PSItem.FullName -like 'k8s\*\xp1*' }
        foreach ($entry in $entries) {
            $fname = $entry.FullName
            $idx = $fname.IndexOf('xp1')
            $folder = ($fname -replace '\\', '/').Substring($idx, $fname.length - $idx) | Split-Path
            New-Item -Path $localpath -Name $folder -ItemType Directory -Force | Out-Null
            $file = "$localpath\$folder\$($entry.Name)"
            if ($entry.Name -ne '') { [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $file, $true) }
        }
    }
    $logString = $logString, ((Get-Childitem -Path "$localpath\xp1" -Name -Recurse) -join "`r`n" ) -join "`r`n" 
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString
}
catch {
    $logString = ($logString + " *** Error *** " + $_.Exception.Message)
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
$logString = 'Uploading Kb8 Config Files to S3'
try {
    $parms = @{
        BucketName = $DeploymentS3BucketName
        KeyPrefix  = ($DeploymentS3KeyPrefix + "xp1/")
        Folder     = "$localPath\xp1"
    }
    $parms
    Write-S3Object @parms -Recurse
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString
}
catch {
    $logString = ($logString + " *** Error *** " + $_.Exception.Message)
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
$logString = 'Running mkcert to generate the local certificate'
try {
    mkcert | Tee-Object -Variable Output
    $logString = $logString, $Output -join "`r`n" 
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString
}
catch {
    $logString = ($logString + " *** Error *** " + $_.Exception.Message)
    Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
$logString = 'Invoking Custom Install Package cfg-environment.ps1'
Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString
& $qslocalpath\cfg-environment.ps1 -DeploymentName $DeploymentName -QSS3KeyPrefix $QSS3KeyPrefix -localPath $localpath
$logString = '****************** End Logging - Kb8 Job Execution Complete *********************'
Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString




# EKS Cluster name 
# Write-Output "About to update kubeconfig with region $EKSClusterRegion and Cluster Name $EKSClusterName"
# aws eks --region $EKSClusterRegion update-kubeconfig --name $EKSClusterName | Tee-Object -Variable logString
# Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $LogString


# Add helm repos
# helm repo add stable https://charts.helm.sh/stable
# helm repo add bitnami https://charts.bitnami.com/bitnami

# Install Helm
# helm install $EKSDeploymentName bitnami/nginx-ingress-controller `
#   --set replicaCount=1 `
#   --set nodeSelector."beta\.kubernetes\.io/os"=linux `
#   --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux `
#   --set-string controller.config.proxy-body-size=10m `
#   --set service.externalTrafficPolicy=Local

# Get external hostname for the deployment
# $hostname = kubectl -n default get svc ($EKSDeploymentName + "-nginx-ingress-controller") --output jsonpath='{.status.loadBalancer.ingress[0].hostname}'
# $hostname

# Deploy Secrets

# Deploy SQl Redis Solr
# kubectl apply -f "$localpath/xp1/external/"

# kubectl apply -f "$localpath/xp1/init/"

# kubectl apply -f "$localpath/xp1/" -f "$localpath/xp1/ingress-nginx/ingress.yaml"


Read-S3Object -BucketName ${QSS3BucketName} -Region ${QSS3BucketRegion} -KeyPrefix ("/${QSS3KeyPrefix}submodules/quickstart-microsoft-utilities/modules/AWSQuickStart/") -Folder "${qslocalpath}";
Read-S3Object -BucketName ${QSS3BucketName} -Region ${QSS3BucketRegion} -KeyPrefix ("/${QSS3KeyPrefix}scripts/install/") -Folder ${qslocalpath};
Read-S3Object -BucketName ${DeploymentS3BucketName} -Region ${DeploymentS3BucketRegion} -KeyPrefix ("/${DeploymentS3KeyPrefix}resources/") -Folder ${localpath};
Read-S3Object -BucketName ${DeploymentS3BucketName} -Region ${DeploymentS3BucketRegion} -KeyPrefix ("/${DeploymentS3KeyPrefix}license/") -Folder ${localpath};
Import-Module "${qslocalpath}\AWSQuickStart.psm1";
& $qslocalpath\install-product.ps1 -QSS3BucketName ${QSS3BucketName} -QSS3BucketRegion ${QSS3BucketRegion} -QSS3KeyPrefix ${QSS3KeyPrefix} -DeploymentName ${DeploymentName} -DeploymentPrefix ${DeploymentPrefix} -DeploymentS3BucketName ${DeploymentS3BucketName} -DeploymentS3KeyPrefix ${DeploymentS3KeyPrefix} -DeploymentS3BucketRegion ${DeploymentS3BucketRegion};



Add-WindowsFeature Web-Server; Invoke-WebRequest -UseBasicParsing -Uri 'https://dotnetbinaries.blob.core.windows.net/servicemonitor/2.0.1.6/ServiceMonitor.exe' -OutFile 'C:\\ServiceMonitor.exe'; echo '<html><body><br/><br/><marquee><H1>Hello EKS!!!<H1><marquee></body><html>' > C:\\inetpub\\wwwroot\\default.html; C:\\ServiceMonitor.exe 'w3svc';




# Install packages and modules;
Add-Type -AssemblyName System.IO.Compression.FileSystem;Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;Install-Module AWS.Tools.S3, AWS.Tools.CloudWatchLogs, AWS.Tools.SimpleSystemsManagement, AWS.Tools.SecretsManager -Confirm:$false -Force -Scope AllUsers;Import-Module AWS.Tools.S3, AWS.Tools.CloudwatchLogs, AWS.Tools.SimpleSystemsManagement, AWS.Tools.SecretsManager;Read-S3Object -BucketName ${QSS3BucketName} -Region ${QSS3BucketRegion} -KeyPrefix ("/${QSS3KeyPrefix}submodules/quickstart-microsoft-utilities/modules/AWSQuickStart/") -Folder ${qslocalpath};Read-S3Object -BucketName ${QSS3BucketName} -Region ${QSS3BucketRegion} -KeyPrefix ("/${QSS3KeyPrefix}scripts/install/") -Folder ${qslocalpath};Read-S3Object -BucketName ${DeploymentS3BucketName} -Region ${DeploymentS3BucketRegion} -KeyPrefix ("/${DeploymentS3KeyPrefix}resources/") -Folder ${localpath};Read-S3Object -BucketName ${DeploymentS3BucketName} -Region ${DeploymentS3BucketRegion} -KeyPrefix ("/${DeploymentS3KeyPrefix}license/") -Folder ${localpath};Import-Module "${qslocalpath}\AWSQuickStart.psm1";& ${qslocalpath}\install-product.ps1 -QSS3BucketName ${QSS3BucketName} -QSS3BucketRegion ${QSS3BucketRegion} -QSS3KeyPrefix ${QSS3KeyPrefix} -DeploymentName ${DeploymentName} -DeploymentPrefix ${DeploymentPrefix} -DeploymentS3BucketName ${DeploymentS3BucketName} -DeploymentS3KeyPrefix ${DeploymentS3KeyPrefix} -DeploymentS3BucketRegion ${DeploymentS3BucketRegion};
Add-Type -AssemblyName System.IO.Compression.FileSystem;Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;Install-Module AWS.Tools.S3, AWS.Tools.CloudWatchLogs, AWS.Tools.SimpleSystemsManagement, AWS.Tools.SecretsManager -Confirm:$false -Force -Scope AllUsers;Import-Module AWS.Tools.S3, AWS.Tools.CloudwatchLogs, AWS.Tools.SimpleSystemsManagement, AWS.Tools.SecretsManager;Read-S3Object -BucketName ${QSS3BucketName} -Region ${QSS3BucketRegion} -KeyPrefix ('/${QSS3KeyPrefix}submodules/quickstart-microsoft-utilities/modules/AWSQuickStart/') -Folder ${qslocalpath};Read-S3Object -BucketName ${QSS3BucketName} -Region ${QSS3BucketRegion} -KeyPrefix ('/${QSS3KeyPrefix}scripts/install/') -Folder ${qslocalpath};Read-S3Object -BucketName ${DeploymentS3BucketName} -Region ${DeploymentS3BucketRegion} -KeyPrefix ('/${DeploymentS3KeyPrefix}resources/') -Folder ${localpath};Read-S3Object -BucketName ${DeploymentS3BucketName} -Region ${DeploymentS3BucketRegion} -KeyPrefix ('/${DeploymentS3KeyPrefix}license/') -Folder ${localpath};Import-Module '${qslocalpath}\AWSQuickStart.psm1';& ${qslocalpath}\install-product.ps1 -QSS3BucketName ${QSS3BucketName} -QSS3BucketRegion ${QSS3BucketRegion} -QSS3KeyPrefix ${QSS3KeyPrefix} -DeploymentName ${DeploymentName} -DeploymentPrefix ${DeploymentPrefix} -DeploymentS3BucketName ${DeploymentS3BucketName} -DeploymentS3KeyPrefix ${DeploymentS3KeyPrefix} -DeploymentS3BucketRegion ${DeploymentS3BucketRegion};

command: ["powershell.exe"]
                  args: 
                    - >
                      # Install packages and modules;
                      Add-Type -AssemblyName System.IO.Compression.FileSystem;
                      Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;
                      Install-Module AWS.Tools.S3, AWS.Tools.CloudWatchLogs, AWS.Tools.SimpleSystemsManagement, AWS.Tools.SecretsManager -Confirm:$false -Force -Scope AllUsers;
                      Import-Module AWS.Tools.S3, AWS.Tools.CloudwatchLogs, AWS.Tools.SimpleSystemsManagement, AWS.Tools.SecretsManager;
                      Read-S3Object -BucketName ${QSS3BucketName} -Region ${QSS3BucketRegion} -KeyPrefix ("/${QSS3KeyPrefix}submodules/quickstart-microsoft-utilities/modules/AWSQuickStart/") -Folder ${qslocalpath};
                      Read-S3Object -BucketName ${QSS3BucketName} -Region ${QSS3BucketRegion} -KeyPrefix ("/${QSS3KeyPrefix}scripts/install/") -Folder ${qslocalpath};
                      Read-S3Object -BucketName ${DeploymentS3BucketName} -Region ${DeploymentS3BucketRegion} -KeyPrefix ("/${DeploymentS3KeyPrefix}resources/") -Folder ${localpath};
                      Read-S3Object -BucketName ${DeploymentS3BucketName} -Region ${DeploymentS3BucketRegion} -KeyPrefix ("/${DeploymentS3KeyPrefix}license/") -Folder ${localpath};
                      Import-Module "${qslocalpath}\AWSQuickStart.psm1";
                      & ${qslocalpath}\install-product.ps1 -QSS3BucketName ${QSS3BucketName} -QSS3BucketRegion ${QSS3BucketRegion} -QSS3KeyPrefix ${QSS3KeyPrefix} -DeploymentName ${DeploymentName} -DeploymentPrefix ${DeploymentPrefix} -DeploymentS3BucketName ${DeploymentS3BucketName} -DeploymentS3KeyPrefix ${DeploymentS3KeyPrefix} -DeploymentS3BucketRegion ${DeploymentS3BucketRegion};
                  imagePullPolicy: IfNotPresent