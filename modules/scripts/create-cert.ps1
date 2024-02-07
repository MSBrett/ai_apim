
[string]$certificatename = $env:certificatename
[string]$dnsname = $env:dnsname
[string]$vaultname = $env:vaultname

if ([string]::IsNullOrEmpty($certificatename) ){
    Write-Output "Certificate name is not provided"
    throw "Certificate name is not provided"
}

if ([string]::IsNullOrEmpty($dnsname)){
    Write-Output "DNS name is not provided"
    throw "DNS name is not provided"
}

if ([string]::IsNullOrEmpty($vaultname)){
    Write-Output "Vault name is not provided"
    throw "Vault name is not provided"
}

Write-Output "Creating certificate $certificatename in vault $vaultname with DNS name $dnsname"
$subjectName = "CN=$certificatename"
try {
    $Policy = New-AzKeyVaultCertificatePolicy -SecretContentType "application/x-pkcs12" -SubjectName $subjectName -dnsname $dnsname -IssuerName "Self" -ValidityInMonths 6 -ReuseKeyOnRenewal
    Add-AzKeyVaultCertificate -vaultname $vaultname -Name $certificatename -CertificatePolicy $Policy
    Write-Output "Successfully created certificate $certificatename in vault $vaultname with DNS name $dnsname"
}
catch {
    Write-Output "Failed to create certificate $certificatename in vault $vaultname with DNS name $dnsname"
    Write-Output $_.Exception.Message
    Write-Output $_.Exception
    throw $_.Exception.Message
}
