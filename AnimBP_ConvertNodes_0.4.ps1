param (
    [string]$InputJsonPath = "T:\Modding\Unreal Engine\_Scripts\Assets\Post_1050001_Physics.json",
    [string]$OutputTxtPath = "T:\Modding\Unreal Engine\_Scripts\AnimBP_Output.txt",
    [string]$AnimBPClass = "Post_1050001_Physics_C"
)

[System.Threading.Thread]::CurrentThread.CurrentCulture = 'en-US'
$jsonContent = Get-Content -Raw -Path $InputJsonPath | ConvertFrom-Json
$target = $jsonContent | Where-Object { $_.Type -eq $AnimBPClass }

if (-not $target) {
    Write-Host "Could not find $AnimBPClass object in JSON."
    exit 1
}

$props = $target.Properties
$output = @()

function Format-Float($val) {
    return "{0:F6}" -f $val
}

function Format-CurveKeys {
    param ($curve)
    if ($curve.EditorCurveData.Keys.Count -gt 0) {
        $keyStrings = $curve.EditorCurveData.Keys | ForEach-Object {
            "(Time={0},Value={1})" -f (Format-Float $_.Time), (Format-Float $_.Value)
        }
        return "EditorCurveData=(Keys=({0}))" -f ($keyStrings -join ",")
    }
    return $null
}

function Format-Limits {
    param ($limits, $type)
    if ($limits.Count -gt 0) {
        $formatted = $limits | ForEach-Object {
            $r = Format-Float $_.Radius
            $l = Format-Float $_.Length
            $bone = $_.DrivingBone.BoneName
            $ol = $_.OffsetLocation
            $or = $_.OffsetRotation

            return "(Radius=$r,Length=$l,DrivingBone=(BoneName=""$bone""),OffsetLocation=(X={0},Y={1},Z={2}),OffsetRotation=(Pitch={3},Yaw={4},Roll={5}))" -f `
                (Format-Float $ol.X), (Format-Float $ol.Y), (Format-Float $ol.Z),
                (Format-Float $or.Pitch), (Format-Float $or.Yaw), (Format-Float $or.Roll)
        }
        return "$type=({0})" -f ($formatted -join ",")
    }
    return $null
}

function Format-LimitsDataAsset {
    param ($asset)
    if ($asset.ObjectPath) {
        $path = $asset.ObjectPath -replace "\.0$", ""
        $shortName = ($asset.ObjectName -split "'")[-2]
        return 'LimitsDataAsset="/Script/KawaiiPhysics.KawaiiPhysicsLimitsDataAsset''' + $path + '.' + $shortName + '''"'
    }
    return $null
}

function Format-ModifyBoneNode {
    param ($key, $node, $index)

    $bone = $node.BoneToModify.BoneName
    $t = $node.Translation
    $r = $node.Rotation
    $s = $node.Scale

    $tmode = $node.TranslationMode -split "::" | Select-Object -Last 1
    $rmode = $node.RotationMode -split "::" | Select-Object -Last 1
    $smode = $node.ScaleMode -split "::" | Select-Object -Last 1

    $tspace = $node.TranslationSpace -split "::" | Select-Object -Last 1
    $rspace = $node.RotationSpace -split "::" | Select-Object -Last 1
    $sspace = $node.ScaleSpace -split "::" | Select-Object -Last 1

    $row = $index % 10
    $col = [math]::Floor($index / 10)
    $posX = $col * 255
    $posY = $row * 144

    return @"
Begin Object Class=/Script/AnimGraph.AnimGraphNode_ModifyBone Name="$key"
   Node=(BoneToModify=(BoneName="$bone"),Translation=(X=$(Format-Float $t.X),Y=$(Format-Float $t.Y),Z=$(Format-Float $t.Z)),Rotation=(Pitch=$(Format-Float $r.Pitch),Yaw=$(Format-Float $r.Yaw),Roll=$(Format-Float $r.Roll)),Scale=(X=$(Format-Float $s.X),Y=$(Format-Float $s.Y),Z=$(Format-Float $s.Z)),TranslationMode=$tmode,RotationMode=$rmode,ScaleMode=$smode,TranslationSpace=$tspace,RotationSpace=$rspace,ScaleSpace=$sspace)
   ShowPinForProperties(0)=(PropertyName="ComponentPose",bShowPin=True)
   ShowPinForProperties(1)=(PropertyName="bAlphaBoolEnabled",bShowPin=True)
   ShowPinForProperties(2)=(PropertyName="Alpha",bShowPin=True)
   ShowPinForProperties(3)=(PropertyName="AlphaCurveName",bShowPin=True)
   NodePosX=$posX
   NodePosY=$posY
End Object
"@
}

function Format-ConstraintNode {
    param ($key, $node, $index)

    $bone = $node.BoneToModify.BoneName
    $setupEntries = $node.ConstraintSetup | ForEach-Object {
        $targetBone = $_.TargetBone.BoneName
        $offset = $_.OffsetOption -split "::" | Select-Object -Last 1
        $ttype = $_.TransformType -split "::" | Select-Object -Last 1
        $px = $_.PerAxis.bX.ToString().ToLower()
        $py = $_.PerAxis.bY.ToString().ToLower()
        $pz = $_.PerAxis.bZ.ToString().ToLower()

        return "(TargetBone=(BoneName=""$targetBone""),OffsetOption=$offset,TransformType=$ttype,PerAxis=(bX=$px,bY=$py,bZ=$pz))"
    }
    $weights = $node.ConstraintWeights | ForEach-Object { Format-Float $_ }

    $row = $index % 10
    $col = [math]::Floor($index / 10)
    $posX = $col * 255
    $posY = $row * 144

    return @"
Begin Object Class=/Script/AnimGraph.AnimGraphNode_Constraint Name="$key"
   Node=(BoneToModify=(BoneName="$bone"),ConstraintSetup=({$($setupEntries -join ",")}),ConstraintWeights=({$($weights -join ",")}))
   ShowPinForProperties(0)=(PropertyName="ComponentPose",bShowPin=True)
   ShowPinForProperties(1)=(PropertyName="bAlphaBoolEnabled",bShowPin=True)
   ShowPinForProperties(2)=(PropertyName="Alpha",bShowPin=True)
   ShowPinForProperties(3)=(PropertyName="AlphaCurveName",bShowPin=True)
   NodePosX=$posX
   NodePosY=$posY
End Object
"@
}

function Format-LayeredBoneBlendNode {
    param ($key, $node, $index)

    $layers = @()
    foreach ($layer in ($node.LayerSetup | Where-Object { $_ })) {
        $filters = @()
        foreach ($f in ($layer.BranchFilters | Where-Object { $_ })) {
            $filters += '(BoneName="{0}",BlendDepth={1})' -f $f.BoneName, [int]$f.BlendDepth
        }
        $layers += "(BranchFilters=({0}))" -f ($filters -join ",")
    }
    $layerSetup = "LayerSetup=({0})" -f ($layers -join ",")

    # Flags / enums
    $meshSpaceRot  = $node.bMeshSpaceRotationBlend.ToString()
    $meshSpaceScale = $node.bMeshSpaceScaleBlend.ToString()
    $curveBlend    = ($node.CurveBlendOption -split "::")[-1]   # e.g. Override
    $blendRoot     = $node.bBlendRootMotionBasedOnRootBone.ToString()

    $weightsPart = $null
    if ($node.BlendWeights -and $node.BlendWeights.Count -gt 0) {
        $w = $node.BlendWeights | ForEach-Object { "{0:F6}" -f $_ }
        $weightsPart = ",BlendWeights=({0})" -f ($w -join ",")
    }

    $row = $index % 10
    $col = [math]::Floor($index / 10)
    $posX = $col * 255
    $posY = $row * 144

    @"
Begin Object Class=/Script/AnimGraph.AnimGraphNode_LayeredBoneBlend Name="$key"
   Node=($layerSetup,bMeshSpaceRotationBlend=$meshSpaceRot,bMeshSpaceScaleBlend=$meshSpaceScale,CurveBlendOption=$curveBlend,bBlendRootMotionBasedOnRootBone=$blendRoot$weightsPart)
   NodePosX=$posX
   NodePosY=$posY
End Object
"@
}

$index = 0

foreach ($key in $props.PSObject.Properties.Name) {
    if ($key -like "AnimGraphNode_KawaiiPhysics*") {
        $node = $props.$key

        $rootBone = $node.RootBone.BoneName
        $dummyBoneLength = Format-Float $node.DummyBoneLength
        $boneAxis = ($node.BoneForwardAxis -split ":")[-1]
        $comptype = ($node.BoneConstraintGlobalComplianceType -split ":")[-1]
        $tpdist = Format-Float $node.TeleportDistanceThreshold
        $tprotate = Format-Float $node.TeleportRotationThreshold

        $ps = $node.PhysicsSettings
        $physicsString = if ($ps) {
            "Damping={0},Stiffness={1},WorldDampingLocation={2},WorldDampingRotation={3},Radius={4},LimitAngle={5}" -f `
                (Format-Float $ps.Damping), (Format-Float $ps.Stiffness), (Format-Float $ps.WorldDampingLocation), `
                (Format-Float $ps.WorldDampingRotation), (Format-Float $ps.Radius), (Format-Float $ps.LimitAngle)
        } else { "" }

        $curveParts = @()
        foreach ($curveName in @("DampingCurveData", "StiffnessCurveData", "WorldDampingLocationCurveData", "WorldDampingRotationCurveData", "RadiusCurveData", "LimitAngleCurveData", "LimitLinearCurveData", "GravityCurveData")) {
            if ($node.$curveName) {
                $c = Format-CurveKeys $node.$curveName
                if ($c) { $curveParts += "$curveName=($c)" }
            }
        }

        foreach ($limitType in @("CapsuleLimits", "BoxLimits", "PlanarLimits", "SphericalLimits")) {
            if ($node.$limitType) {
                $c = Format-Limits $node.$limitType $limitType
                if ($c) { $curveParts += $c }
            }
        }

        $excludePart = $null
            if ($node.ExcludeBones -and $node.ExcludeBones.Count -gt 0) {
                $ex = $node.ExcludeBones | ForEach-Object { '(BoneName="{0}")' -f $_.BoneName }
                $excludePart = ",ExcludeBones=({0})" -f ($ex -join ",")
            }

        if ($node.LimitsDataAsset) {
            $lda = Format-LimitsDataAsset $node.LimitsDataAsset
            if ($lda) { $curveParts += $lda }
        }

        $extra = if ($curveParts.Count -gt 0) { "," + ($curveParts -join ",") } else { "" }

        $row = $index % 10
        $col = [math]::Floor($index / 10)
        $posX = $col * 255
        $posY = $row * 144

        $output += @"
Begin Object Class=/Script/KawaiiPhysicsEd.AnimGraphNode_KawaiiPhysics Name="$key"
   Node=(RootBone=(BoneName="$rootBone")$excludePart,DummyBoneLength=$dummyBoneLength,BoneForwardAxis=$boneAxis,TeleportDistanceThreshold=$tpdist,TeleportRotationThreshold=$tprotate,BoneConstraintGlobalComplianceType=$comptype,PhysicsSettings=($physicsString)$extra)
   ShowPinForProperties(0)=(PropertyName="ComponentPose",bShowPin=True)
   ShowPinForProperties(1)=(PropertyName="bAlphaBoolEnabled",bShowPin=True)
   ShowPinForProperties(2)=(PropertyName="Alpha",bShowPin=True)
   ShowPinForProperties(3)=(PropertyName="AlphaCurveName",bShowPin=True)
   NodePosX=$posX
   NodePosY=$posY
End Object
"@
        $index++
    }
    elseif ($key -like "AnimGraphNode_ModifyBone*") {
        $node = $props.$key
        $output += Format-ModifyBoneNode $key $node $index
        $index++
    }
    elseif ($key -like "AnimGraphNode_Constraint*") {
        $node = $props.$key
        $output += Format-ConstraintNode $key $node $index
        $index++
    }
    elseif ($key -like "AnimGraphNode_LayeredBoneBlend*") {
        $node = $props.$key
        $output += Format-LayeredBoneBlendNode $key $node $index
        $index++
    }
}

$output -join "`n" | Out-File -Encoding utf8 -FilePath $OutputTxtPath
Set-Clipboard -Value $output
Write-Host "Conversion complete. Output copied to clipboard & saved to $OutputTxtPath"
