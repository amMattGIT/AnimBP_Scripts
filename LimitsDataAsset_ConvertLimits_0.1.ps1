param (
    [string]$InputJsonPath = "T:\Modding\Unreal Engine\_Scripts\Assets\SK_1038_1038500_PA.json",
    [string]$OutputTxtPath = "T:\Modding\Unreal Engine\_Scripts\PA_Output.txt",
    [string]$AssetClass = "KawaiiPhysicsLimitsDataAsset"
)

[System.Threading.Thread]::CurrentThread.CurrentCulture = 'en-US'
$jsonContent = Get-Content -Raw -Path $InputJsonPath | ConvertFrom-Json
$target = $jsonContent | Where-Object { $_.Type -like "*$AssetClass*" }

if (-not $target) {
    Write-Host "Could not find $AssetClass object in JSON."
    exit 1
}

$props = $target.Properties
$capsules = $props.CapsuleLimits

function Format-Float($val) {
    $f = [float]$val
    if ([math]::Abs($f) -lt 1e-6) {
        return "0.000000"
    }
    return "{0:F6}" -f $f
}

function New-RandomGuid32() {
    $bytes = New-Object byte[] 16
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return ($bytes | ForEach-Object { $_.ToString("X2") }) -join ''
}

$output = @()

foreach ($c in $capsules) {
    $r = Format-Float $c.Radius
    $l = Format-Float $c.Length
    $bone = $c.DrivingBone.BoneName
    $ol = $c.OffsetLocation
    $or = $c.OffsetRotation
    $sourceType = $c.SourceType -replace "ECollisionSourceType::", ""
    $guid = New-RandomGuid32

    $hasOffsetRot = ($or.Pitch -ne 0 -or $or.Yaw -ne 0 -or $or.Roll -ne 0)
    $offsetLocStr = "OffsetLocation=(X={0},Y={1},Z={2})" -f (Format-Float $ol.X), (Format-Float $ol.Y), (Format-Float $ol.Z)
    $offsetRotStr = if ($hasOffsetRot) { ",OffsetRotation=(Pitch={0},Yaw={1},Roll={2})" -f (Format-Float $or.Pitch), (Format-Float $or.Yaw), (Format-Float $or.Roll) } else { "" }

    $entry = "(Radius=$r,Length=$l,DrivingBone=(BoneName=""$bone""),$offsetLocStr$offsetRotStr,SourceType=$sourceType,Guid=$guid)"
    $output += $entry
}

$final = "(" + ($output -join ",") + ")"
Set-Content -Path $OutputTxtPath -Value $final -Encoding UTF8
Set-Clipboard -Value $final
Write-Host "Conversion complete. Output copied to clipboard & saved to $OutputTxtPath"