I got *very* tired of manually remaking physic nodes for a mod, so I finally decided to make a few scripts to speed up the process.

I intend to expand on it and make it more user friendly but I figured its worth sharing, even in it's current state.

Basically you:
* Export an animation blueprint from the game as JSON
* Input the path to the JSON and an output path (txt file)
* Run the script (AnimBP_ConvertNodes_0.4.ps1)
* Copy/paste (CTRL V) into an Animation Blueprint in UE and all the nodes will be pasted. 
  * The output will also be saved to the path you specified.

It currently has support for Kawaii nodes, Bone modifiers, Constraints and Layered bone blends. There is also a second script for the Kawaii limit assets (LimitsDataAsset_ConvertLimits_0.1.ps1), which works pretty much the same way.

To-do:
* AnimBP Assets:
  * Support for PoseDrivers

* BoneConstraintAsset:
  * Create script for this
