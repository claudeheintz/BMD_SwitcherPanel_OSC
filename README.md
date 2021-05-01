# Switcher Panel with OSC

This project allows you to control a Blackmagic Design ATEM switcher using OSC from an app like TouchOSC or QLab.  The SwitcherPanel app runs on a Mac that is connected to the ATEM.  It listens for OSC messages on a specified network port and controls the ATEM accordingly.

[Click here](https://github.com/claudeheintz/BMD_SwitcherPanel_OSC/raw/master/bin/SwitcherPanel.zip) to download just the pre-build app in a zip file.  (The pre-built app is also found in the `/bin` folder)

This project starts with the **SwitcherPanel** sample from Blackmagic_ATEM_Switchers_SDK_8.4 and adds media selection capability from the SDK's **SwitcherMediaPool** example. Most importantly, it also adds the ability to control the app (and through the app an ATEM) using OSC.

To use the app, you'll need to download and install the ATEM software from **https://www.blackmagicdesign.com/support/** along with the contents of this repository.

To use the source code, you'll want to download the SDK from **https://www.blackmagicdesign.com/developer/**  Either clone or unzip the BMD_SwitcherPanel_OSC-master folder into Blackmagic_ATEM_Switchers_SDK_8.4/Samples
  
The `/extras` folder contains a layout for TouchOSC and a workspace for QLab that illustrate controlling the SwitcherPanel from these applications.

The OSC address patterns that the switcherPanel app responds to are listed below.  Brackets eg. [1.0] list arguments contained in the OSC message with the given address pattern.  Float arguments of 1.0 are required to trigger some actions in order to be compatible with an OSC application that sends a message with 1.0 when a button is pressed and 0.0 when the button is released.

BMD SwitcherPanel OSC Messages:

`/bmd/switcher/transition/auto [float 1.0]`  
   Triggers an auto transition as if the the Auto button on the ATEM was pressed.  
   
`/bmd/switcher/transition/cut [float 1.0]`  
   Triggers a cut transition as if the the Cut button on the ATEM was pressed.  

`/bmd/switcher/transition/ftb [float 1.0]`  
   Triggers a cut transition as if the the FTB button on the ATEM was pressed.  

`/bmd/switcher/transition/position [float P = 0.0-1.0]`  
   Sets the progress of the transition slider from 0 to 100%  
   as determined by the float argument.  


`/bmd/switcher/preview/N [float 1.0]`  
   Selects input N as the preview source.  
   The number refers to the row in the popup list,
   starting with the first (black) as row zero. 
   
`/bmd/switcher/preview  [integer N]`  
   Selects input N as the preview source.  
   The number refers to the row in the popup list,
   starting with the first (black) as row zero. 
   
`/bmd/switcher/program/N [float 1.0]`  
   Selects input N as the program source.  
   The number refers to the row in the popup list,
   starting with the first (black) as row zero. 
   
`/bmd/switcher/program  [integer N]`  
   Selects input N as the program source.  
   The number refers to the row in the popup list,
   starting with the first (black) as row zero. 

  
`/bmd/switcher/stream/start  [float 1.0]`  
   Starts streaming. 
   
`/bmd/switcher/stream/stop  [float 1.0]`  
   Stops streaming. 

`/bmd/switcher/record/start  [float 1.0]`  
   Starts recording. 
   
`/bmd/switcher/record/stop  [float 1.0]`  
   Stops recording. 
 
 
`/bmd/switcher/streamkey/set [string key]`  
   Sets the stream key to the string included as an argument.   

`/bmd/switcher/streamurl/set [string url] [string serviceName]`  
   Sets the stream url and optionally the service name. 

`/bmd/switcher/media/select N [float 1.0]`  
   Selects slot N from the media pool.  
   The number refers to the row in the popup list,
   starting with the first (black) as row zero.

