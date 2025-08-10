# Various UE Animation Blueprint Scripts

A collection of scripts to ease the process of working with animation blueprints, such as converting FModel JSON exports into UE format.

---

## Quick start
1. Export desired assets from the game as **JSON** (with FModel).  
2. Adjust paths in script(s) and run them.  
3. **CTRL+V** inside Unreal to paste nodes / limits.  
4. Done.

## Documentation
Each available script is described below.

### AnimBP Converter — `AnimBP_ConvertNodes.ps1`

#### What it does
- Reads an exported **Animation Blueprint JSON**.
- Finds supported AnimGraph nodes and converts them to UE’s **Copy/Paste** format.
- Auto-positions nodes so they don’t paste on top of each other.
- Copies output to your clipboard and saves it to a `.txt`.

#### Currently supported nodes
- **KawaiiPhysics** (physics settings, curves, limits, ExcludeBones, LimitsDataAsset refs)
- **ModifyBone**
- **Constraint**
- **LayeredBoneBlend** (BranchFilters, weights, flags)

#### Parameters
- `-InputJsonPath` → Path to the exported input JSON (from FModel)
- `-OutputTxtPath` → Where to save the UE paste text
- `-AnimBPClass` → The `AnimBlueprintGeneratedClass` name (e.g., `Post_1024303_Physics_C`)

#### Usage
Change the following params at the top of the scripts and then run the script. See above for parameter specifics.
```powershell
param (
    [string]$InputJsonPath = "T:\Modding\Unreal Engine\_Scripts\Assets\Example.json",
    [string]$OutputTxtPath = "T:\Modding\Unreal Engine\_Scripts\AnimBP_Output.txt",
    [string]$AnimBPClass = "Example_C"
)
```

#### Pasting into UE
1. Open your target Animation Blueprint.
2. Press **CTRL+V** — nodes appear with the same settings as the JSON.
3. The same text is also saved to the file specified in `-OutputTxtPath`.

---

### Kawaii Limits Data Asset Converter — `LimitsDataAsset_ConvertLimits.ps1`

#### What it does
- Reads a **KawaiiPhysics Limits Data Asset** exported as JSON.
- Finds supported Capsule Limits and converts them to UE’s **Copy/Paste** format.
- Copies output to your clipboard and saves it to a `.txt`.

#### Parameters
- `-InputJsonPath` → Path to the exported JSON
- `-OutputTxtPath` → Where to save the UE paste text

#### Usage
Change the following params at the top of the scripts and then run the script. See above for parameter specifics.
```powershell
param (
    [string]$InputJsonPath = "T:\Modding\Unreal Engine\_Scripts\Assets\Example.json",
    [string]$OutputTxtPath = "T:\Modding\Unreal Engine\_Scripts\PA_Output.txt",
)
```

#### Pasting into UE
- Open or create the Limits Data Asset, then **CTRL+V** to apply.

---

## To-do
**AnimBP**
- PoseDriver support

**Assets**
- BoneConstraintAsset: create script

## If you'd like to support me

My Patreon is [here](https://www.patreon.com/amMatt).

---
