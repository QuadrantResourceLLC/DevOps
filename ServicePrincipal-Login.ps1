[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string] $certName,
    [Parameter(Mandatory=$true)]
    [string] $subscription,
    [Parameter(Mandatory=$true)]
    [string] $azureAdAppName
    )

###################################################################################################
#
# PowerShell configurations
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
$ErrorActionPreference = "Stop"

# Ensure we set the working directory to that of the script.
pushd $PSScriptRoot

# Configure strict debugging.
Set-PSDebug -Strict

###################################################################################################


#
# Functions used in this script.
#

function Handle-LastError
{
    [CmdletBinding()]
    param(
    )

    $message = $error[0].Exception.Message
    if ($message)
    {
        Write-Host -Object "ERROR: $message" -ForegroundColor Red
    }
    
    # IMPORTANT NOTE: Throwing a terminating error (using $ErrorActionPreference = "Stop") still
    # returns exit code zero from the PowerShell script when using -File. The workaround is to
    # NOT use -File when calling this script and leverage the try-catch-finally block and return
    # a non-zero exit code from the catch block.
    exit -1
}

##################################################################################################

# Function to create a self sined certificate and ,

# Create an Azure AD Service Principal using the Self-signed cert.

##################################################################################################
function Create-Cert{
    param(
    [Parameter(Mandatory=$true)]
    [string] $subject,
     [Parameter(Mandatory=$true)]
    [string] $certLocation,
     [Parameter(Mandatory=$true)]
    [string] $azureAdAppName
    )
    

    Write-Host "Create a new self signed certificate"
    $cert = New-SelfSignedCertificate -CertStoreLocation $certLocation  -Subject $subject -KeySpec KeyExchange
    $keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())

    Write-Host "Create a Azure AD Application using the Self-signed cert"
    $sp = New-AzureRMADServicePrincipal -DisplayName $azureAdAppName -CertValue $keyValue -EndDate $cert.NotAfter -StartDate $cert.NotBefore 
    Sleep 20
    New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $sp.ApplicationId

}

################################################################################################################

####################### Function to connect to the azure subscription.#########################################

################################################################################################################

function Login-subscription{
param(
    [Parameter(Mandatory=$true)]
    [string] $certLocation,
     [Parameter(Mandatory=$true)]
    [string] $azureAdAppName,
    [Parameter(Mandatory=$true)]
    [string] $subscription
    )
    Write-Host "Get the Tenant Id and Application Id of the subscription"
    $TenantId = (Get-AzureRmSubscription -SubscriptionName $subscription).TenantId
    $ApplicationId = (Get-AzureRmADApplication -DisplayNameStartWith $azureAdAppName).ApplicationId

    Write-Host "Get the Thumbprint of the cert from the cert store"
    $Thumbprint = (Get-ChildItem $certLocation | Where-Object {$_.Subject -match $subject }).Thumbprint.ToString()

    Write-Host "Connect to the azure account"
    Connect-AzureRmAccount -ServicePrincipal -CertificateThumbprint $Thumbprint -ApplicationId $ApplicationId -TenantId $TenantId
}

###################################################################################################

#
# Handle all errors in this script.
#

trap
{
    # NOTE: This trap will handle all errors. There should be no need to use a catch below in this
    #       script, unless you want to ignore a specific error.
    Handle-LastError
}

###################################################################################################

#
# Main execution block.
#
try
{
   # Login-AzureRMAccount
    $subject = "CN=$certName"
    $certLocation = "cert:\CurrentUser\My"

    Create-Cert -subject $subject -certLocation $certLocation -azureAdAppName $azureAdAppName

    Login-subscription -certLocation $certLocation -azureAdAppName $azureAdAppName -subscription $subscription

}
finally
{
    popd
}