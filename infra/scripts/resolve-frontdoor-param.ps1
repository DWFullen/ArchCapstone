<#!
.SYNOPSIS
  Determines whether the Front Door profile already exists and emits a parameters file setting deployFrontDoor accordingly.
.DESCRIPTION
  Computes expected Front Door profile name based on naming convention used in frontdoor.bicep, checks Azure for existence.
  Writes (or overwrites) a deployment parameters file containing:
    {
      "parameters": { "deployFrontDoor": { "value": true|false } }
    }
.PARAMETER ResourceGroupName
  Resource group where Front Door would reside.
.PARAMETER ZLocation
  Short regional code (e.g. zus1).
.PARAMETER AzureSubscriptionCode
  Short subscription code used in naming.
.PARAMETER ApplicationName
  Application name used in naming.
.PARAMETER DevEnvironmentName
  Environment name (dev, uat, prod, etc.).
.PARAMETER ApplicationVersion
  Version token (e.g. v1).
.PARAMETER ParamFile
  Output parameter file path. Defaults to ./frontdoor.auto.parameters.json under script directory.
.EXAMPLE
  ./resolve-frontdoor-param.ps1 -ResourceGroupName zus1-rc-rcwebsite-dev-v1-rg -ZLocation zus1 -AzureSubscriptionCode rc -ApplicationName rcwebsite -DevEnvironmentName dev -ApplicationVersion v1
.NOTES
  Requires: Azure CLI logged in (az login) & appropriate subscription selected.
!#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$ZLocation,
    [Parameter(Mandatory)][string]$AzureSubscriptionCode,
    [Parameter(Mandatory)][string]$ApplicationName,
    [Parameter(Mandatory)][string]$DevEnvironmentName,
    [Parameter(Mandatory)][string]$ApplicationVersion,
    [string]$ParamFile = $(Join-Path $PSScriptRoot 'frontdoor.auto.parameters.json')
)

$ErrorActionPreference = 'Stop'

$profileName = ("{0}{1}{2}{3}{4}fd" -f $ZLocation, $AzureSubscriptionCode, $ApplicationName, $DevEnvironmentName, $ApplicationVersion).ToLower()
Write-Host "[FrontDoor-Detect] Expected profile name: $profileName" -ForegroundColor Cyan

# Attempt to query existing profile
try {
    $json = az afd profile show -g $ResourceGroupName -n $profileName -o json --only-show-errors 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($json)) {
        $existing = $null
    }
    else {
        $existing = $json | ConvertFrom-Json
    }
}
catch {
    $existing = $null
}

$deployFrontDoor = $null -eq $existing
if ($deployFrontDoor) {
    Write-Host "[FrontDoor-Detect] Profile not found. Will deploy (deployFrontDoor=true)." -ForegroundColor Green
}
else {
    Write-Host "[FrontDoor-Detect] Profile already exists. Skipping deployment (deployFrontDoor=false)." -ForegroundColor Yellow
}

$paramObject = [ordered]@{
    '$schema'      = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters     = @{ deployFrontDoor = @{ value = $deployFrontDoor } }
}

$paramJson = $paramObject | ConvertTo-Json -Depth 5
Set-Content -Path $ParamFile -Value $paramJson -Encoding UTF8

Write-Host "[FrontDoor-Detect] Wrote parameter file: $ParamFile" -ForegroundColor Cyan
Write-Host "[FrontDoor-Detect] Done." -ForegroundColor Cyan
