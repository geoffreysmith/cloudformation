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
  $gzipStream = New-Object System.IO.Compression.GzipStream $memoryStream,([IO.Compression.CompressionMode]::Compress)
  $gzipStream.Write($fileBytes, 0, $fileBytes.Length)
  $gzipStream.Close()
  $memoryStream.Close()
  $compressedFileBytes = $memoryStream.ToArray()
  $encodedCompressedFileData = [Convert]::ToBase64String($compressedFileBytes)
  $gzipStream.Dispose()
  $memoryStream.Dispose()
  return $encodedCompressedFileData
}
# ConvertTo-CompressedBase64String -Path 'c:\resourcefiles\license.xml' | Out-File -Encoding ascii -NoNewline -Confirm -FilePath 'c:\resourcefiles\sitecore-license.txt'

function New-IDTokenSigningCertificate {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [Security.securestring]
    $certificatePassword,

    [Parameter(Mandatory)]
    [ValidateScript({
      if(-Not ($_ | Test-Path) ){
          throw "File or folder does not exist" 
      }
      if(-Not ($_ | Test-Path -PathType Container) ){
          throw "The Path argument must be a folder. File paths are not allowed."
      }
      return $true
    })]
    [System.IO.FileInfo]$outputPath,
    
    [Parameter(Mandatory)]
    [String]
    $certificateFriendlyName
)
  #$certificatePassword = "Test123!"
  #$ceftificateFriendlyName = "Sitecore Identity Token Signing"
  #$outPutPath = c:\resourcefiles\
  $newCert = New-SelfSignedCertificate -DnsName "localhost" -FriendlyName $certificateFriendlyName -NotAfter (Get-Date).AddYears(5)
  Export-PfxCertificate -Cert $newCert -FilePath "$outputPath\$certificateFriendlyName.pfx" -Password $certificatePassword #(ConvertTo-SecureString -String $certificatePassword -Force -AsPlainText)
  [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Get-Item "$outputPath\$certificateFriendlyName.pfx"))) | Out-File -Encoding ascii -NoNewline -Confirm -FilePath "$outputPath\sitecore-identitycertificate.txt"
}

function New-TLS_HTTPSCertificates {
  param (
    [Parameter(Mandatory)]
    [String]
    $certificateFriendlyName
  )
  
  IF NOT EXIST mkcert.exe powershell Invoke-WebRequest 
    https://github.com/FiloSottile/mkcert/releases/download/v1.4.1/mkcert-v1.4.1- windows-amd64.exe -UseBasicParsing -OutFile mkcert.exe
mkcert -install
del /Q /S *.crt
del /Q /S *.key
mkcert -cert-file secrets\tls\global-cm\tls.crt -key-file secrets\tls\global-
cm\tls.key "cm.globalhost"
mkcert -cert-file secrets\tls\global-cd\tls.crt -key-file secrets\tls\global-
cd\tls.key "cd.globalhost"
mkcert -cert-file secrets\tls\global-id\tls.crt -key-file secrets\tls\global-
    id\tls.key "id.globalhost"
}