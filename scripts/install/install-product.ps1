[CmdletBinding()]
param (
    [string]$QSS3BucketName,
    [string]$QSS3BucketRegion,
    [string]$QSS3KeyPrefix,
    [string]$DeploymentName,
    [string]$DeploymentPrefix,
    [string]$DeploymentS3BucketName,
    [string]$DeploymentS3KeyPrefix,
    [string]$DeploymentS3BucketRegion
)
$localPath = "c:\$DeploymentPrefix\resources"
$qsLocalPath = "c:\$DeploymentPrefix\quickstart"
$secretsPath = "$localPath\xp1\secrets"
#Convert to Compressed Base 64 String Function
function ConvertTo-CompressedBase64String {
    [CmdletBinding()]
    Param (
      [Parameter(Mandatory)]
      [ValidateScript( {
          if (-Not ($_ | Test-Path) ) {
            throw "The file or folder $_ does not exist"
          }
          if (-Not ($_ | Test-Path -PathType Leaf) ) {
            throw "The Path argument must be a file. Folder paths are not allowed."
          }
          return $true
        })] 
      [string] $Path
    )
    $fileBytes = [System.IO.File]::ReadAllBytes($Path) 
    [System.IO.MemoryStream] $memoryStream = New-Object System.IO.MemoryStream 
    $gzipStream = New-Object System.IO.Compression.GzipStream $memoryStream, ([IO.Compression.CompressionMode]::Compress)
    $gzipStream.Write($fileBytes, 0, $fileBytes.Length)
    $gzipStream.Close()
    $memoryStream.Close()
    $compressedFileBytes = $memoryStream.ToArray()
    $encodedCompressedFileData = [Convert]::ToBase64String($compressedFileBytes)
    $gzipStream.Dispose()
    $memoryStream.Dispose()
    return $encodedCompressedFileData
  }
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
#
$logString = 'Getting SSM Parameters'
try {
  $EKSClusterName = (Get-SSMParameter -Name "/$DeploymentName/eks/cluster/name").Value
  $EKSClusterRegion = (Get-SSMParameter -Name "/$DeploymentName/eks/cluster/region").Value
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString 
}
catch {
  $logString = ($logString + " *** Error *** " + $_.Exception.Message)
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
#
$logString = 'Importing MKCert Certificate'
try {
  Import-Certificate -FilePath ("C:\Users\" + $env:USERNAME + "\AppData\Local\mkcert\rootCA.pem") -CertStoreLocation Cert:\LocalMachine\Root
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
catch {
  $logString = ($logString + " *** Error *** " + $_.Exception.Message)
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
#
$logString = 'Generating Certificates'
try {
  $servers = 'cm', 'cd', 'id'
  foreach ($server in $servers) {
    $certfile = ($secretsPath + '\tls\global-' + $server + '\tls.crt')
    $keyfile = ($secretsPath + '\tls\global-' + $server + '\tls.key')
    & mkcert -cert-file $certfile -key-file $keyfile 'cm.globalhost' | Tee-Object -Variable logString
  }
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
catch {
  $logString = ($logString + " *** Error *** " + $_.Exception.Message)
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
#
$logString = "Generating Identity Server Token Signing Certificate"
try {
  $certificatePassword = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-identitycertificate").SecretString).password
  $newCert = New-SelfSignedCertificate -DnsName "localhost" -FriendlyName "Sitecore Identity Token Signing" -NotAfter (Get-Date).AddYears(5)
  Export-PfxCertificate -Cert $newCert -FilePath "$localpath\SitecoreIdentityTokenSigning.pfx" -Password (ConvertTo-SecureString -String $certificatePassword -Force -AsPlainText)
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $LogString
  $logString = "Compressing Identity Server Token Signing Certificate"
  [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Get-Item "$localpath\SitecoreIdentityTokenSigning.pfx"))) | Out-File -Encoding ascii -NoNewline -FilePath "$secretsPath\sitecore-identitycertificate.txt"
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $LogString
}
catch {
  $logString = ($logString + " *** Error *** " + $_.Exception.Message)
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
#
$logString = "Uploading Identity Server Token Signing Certificate to Secrets Manager"
try {
  $certificateBody = (Get-Content -Path "$secretsPath\sitecore-identitycertificate.txt").ToString()
  $SecretString = @{password = $certificatePassword; string = $certificateBody } | ConvertTo-Json -Compress
  Update-SECSecret -SecretId "sc-$DeploymentName-sitecore-identitycertificate" -SecretString $SecretString
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $LogString
}
catch {
  $logString = ($logString + " *** Error *** " + $_.Exception.Message)
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
#
$logString = 'Compress and Encode the License File'
try {
  ConvertTo-CompressedBase64String -Path "$localPath\license.xml" | Out-File -Encoding ascii -NoNewline -FilePath "$secretsPath\sitecore-license.txt"
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $LogString
}
catch {
  $logString = ($logString + " *** Error *** " + $_.Exception.Message)
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
#
$logString = "Uploading license to Secrets Manager"
try {
  $licenseBody = (Get-Content -Path "$secretsPath\sitecore-license.txt").ToString()
  $SecretString = @{license = $licenseBody } | ConvertTo-Json -Compress
  Update-SECSecret -SecretId "sc-$DeploymentName-sitecore-license" -SecretString $SecretString
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $LogString
}
catch {
  $logString = ($logString + " *** Error *** " + $_.Exception.Message)
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
#
$logString = "Populate deployment Secret Values"
try {
  $secrets = @{
    "sitecore-adminpassword"                                = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-admin").SecretString).password
    "sitecore-collection-shardmapmanager-database-password" = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-collection-shardmapmanager-database").SecretString).password
    "sitecore-collection-shardmapmanager-database-username" = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-collection-shardmapmanager-database").SecretString).username
    "sitecore-core-database-password"                       = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-core-database").SecretString).password
    "sitecore-core-database-username"                       = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-core-database").SecretString).username
    "sitecore-database-elastic-pool-name"                   = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-database-elastic-pool").SecretString).name
    "sitecore-databasepassword"                             = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-database").SecretString).password
    "sitecore-databaseservername"                           = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-database").SecretString).servername
    "sitecore-databaseusername"                             = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-database").SecretString).username
    "sitecore-exm-master-database-password"                 = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-exm-master-database").SecretString).password
    "sitecore-exm-master-database-username"                 = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-exm-master-database").SecretString).username
    "sitecore-forms-database-password"                      = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-forms-database").SecretString).password
    "sitecore-forms-database-username"                      = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-forms-database").SecretString).username
    "sitecore-identitycertificate"                          = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-identitycertificate").SecretString).string
    "sitecore-identitycertificatepassword"                  = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-identitycertificate").SecretString).password
    "sitecore-identitysecret"                               = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-identity").SecretString).secret
    "sitecore-license"                                      = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-license").SecretString).string
    "sitecore-marketing-automation-database-password"       = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-marketing-automation-database").SecretString).password
    "sitecore-marketing-automation-database-username"       = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-marketing-automation-database").SecretString).username
    "sitecore-master-database-password"                     = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-master-database").SecretString).password
    "sitecore-master-database-username"                     = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-master-database").SecretString).username
    "sitecore-messaging-database-password"                  = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-messaging-database").SecretString).password
    "sitecore-messaging-database-username"                  = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-messaging-database").SecretString).username
    "sitecore-processing-engine-storage-database-password"  = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-processing-engine-storage-database").SecretString).password
    "sitecore-processing-engine-storage-database-username"  = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-processing-engine-storage-database").SecretString).username
    "sitecore-processing-engine-tasks-database-password"    = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-processing-engine-tasks-database").SecretString).password
    "sitecore-processing-engine-tasks-database-username"    = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-processing-engine-tasks-database").SecretString).username
    "sitecore-processing-pools-database-password"           = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-processing-pools-database").SecretString).password
    "sitecore-processing-pools-database-username"           = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-processing-pools-database").SecretString).username
    "sitecore-processing-tasks-database-password"           = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-processing-tasks-database").SecretString).password
    "sitecore-processing-tasks-database-username"           = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-processing-tasks-database").SecretString).username
    "sitecore-reference-data-database-password"             = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-reference-data-database").SecretString).password
    "sitecore-reference-data-database-username"             = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-reference-data-database").SecretString).username
    "sitecore-reporting-database-password"                  = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-reporting-database").SecretString).password
    "sitecore-reporting-database-username"                  = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-reporting-database").SecretString).username
    "sitecore-reportingapikey"                              = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-reportingapi").SecretString).key
    "sitecore-solr-connection-string"                       = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-solr-connection").SecretString).string
    "sitecore-solr-connection-string-xdb"                   = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-solr-connection-xdb").SecretString).string
    "sitecore-telerikencryptionkey"                         = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-telerikencryption").SecretString).key
    "sitecore-web-database-password"                        = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-web-database").SecretString).password
    "sitecore-web-database-username"                        = (ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId "sc-$DeploymentName-sitecore-web-database").SecretString).username
  }
  foreach ($key in $secrets.keys) {
    $secrets[$key] | Out-File -FilePath ($secretspath + "\" + $key + ".txt")
  }
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $LogString
}
catch {
  $logString = ($logString + " *** Error *** " + $_.Exception.Message)
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString  
}
#
$logString = "Uploading Secrets to Cluster"
try {
  kubectl apply -k "$secretsPath"
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $LogString
}
catch {
  $logString = ($logString + " *** Error *** " + $_.Exception.Message)
  Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString    
}
#
$logString = '****************** End Logging - Kb8 Job Execution Complete *********************'
Write-AWSQuickStartCWLogsEntry -logGroupName $logGroupName -LogStreamName $logStreamName -LogString $logString
#