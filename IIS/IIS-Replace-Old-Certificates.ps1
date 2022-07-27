#Replaces old SSL certificates on all bindings with new ones instantly on IIS

Import-Module WebAdministration

# Bind the certificates ##

$CertDapresy=Get-ChildItem -Path Cert:\LocalMachine\My | where-Object {$_.FriendlyName -like "*dapresy.com_2021"} | Select-Object -ExpandProperty Thumbprint

## Get the web binding of the site and set the ssl certificate ##

Get-WebBinding | Where-Object {$_.bindinginformation -match ".dapresy.com"} | Where-Object {$_.protocol -match "https"} |

    % {

        Write-Host $_

        $_.AddSslCertificate($CertDapresy, 'My')

    }