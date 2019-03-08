/*
 * =============================
 * 3D to AE
 * Description: Copy transform information from a 3d object in 3ds Max, for use in Adobe After Effects.  Keeping it simple!
 * Author: Rex Twedt III
 * Version: 0.1.0
 * Tested in 3ds Max 2019
 * =============================
 */


/* Global Variables */

global version="v0.1.0"

global selectedFrameRate
global selectedFrameRangeStart
global selectedFrameRangeEnd
global selectedObj


/* Functions */

/*
 * Based on current settings, grab the transform data for the selected object,
 * and construct the output text as a giant string.
 */
fn buildOutputText = (

  -- Grab some scene info needed for the header.
  local sourceWidthPx=renderWidth
  local sourceHeightPx=renderHeight
  local sourceAspectRatioPx=renderPixelAspect
  local compAspectRatioPx=1.0 -- NOTE(rex): This must be configured in AE.

  -- Start building our output.  It's gonna be one massive string...
  local outputText = "Adobe After Effects 8.0 Keyframe Data\n"

  outputText+="\n\tUnits Per Second\t" + selectedFrameRate as string

  outputText+="\n\tSource Width\t" + sourceWidthPx as string
  outputText+="\n\tSource Height\t" + sourceHeightPx as string

  outputText+="\n\tSource Pixel Aspect Ratio\t" + sourceAspectRatioPx as string
  outputText+="\n\tComp Pixel Aspect Ratio\t" + compAspectRatioPx as string
  outputText+="\n"

  local scaleInfo=nil
  scaleInfo="\nTransform\tScale\n"
  scaleInfo+="\tFrame\tX percent\tY percent\tZ percent\n"

  local rotationXInfo=nil
  local rotationYInfo=nil
  rotationXInfo="\nTransform\tX Rotation\n"
  rotationXInfo+="\tFrame\tdegrees\n"

  rotationYInfo="\nTransform\tY Rotation\n"
  rotationYInfo+="\tFrame\tdegrees\n"

  local positionInfo=nil
  positionInfo="\nTransform\tPosition\n"
  positionInfo+="\tFrame\tX pixels\tY pixels\tZ pixels\n"

  local rotationZInfo=nil
  rotationZInfo="\nTransform\tRotation\n"
  rotationZInfo+="\tFrame\tdegrees\n"

  -- Temp variable used for rotation conversions (if necessary).
  local rotationEuler

  -- Loop through the frame range and grab the required data.
  with redraw off -- More optimization.
  for i = selectedFrameRangeStart to selectedFrameRangeEnd do (
    -- Set the current frame time.
    sliderTime=i

    local frame = currentTime.frame as integer
    scaleInfo+="\t" + frame as string
    scaleInfo+="\t" + (selectedObj.scale.x*100) as string
    scaleInfo+="\t" + (selectedObj.scale.y*100) as string
    scaleInfo+="\t" + (selectedObj.scale.z*100) as string + "\n"
  
    -- Convert the current rotation to Euler Angles.
    rotationEuler = quatToEuler2 (inverse selectedObj.rotation)

    /*
    * 3ds max and AE have different coordinate systems, so we
    * will need to do a bit of work to make sure our values are correct.
    * Increase x rotation by 90 degrees.
    * TODO(rex): Find a reference for this.
    */
    rotationXInfo+="\t" + frame as string
    rotationXInfo+="\t" + (rotationEuler.x+90) as string + "\n"

    rotationYInfo+="\t" + frame as string
    rotationYInfo+="\t" + rotationEuler.y as string + "\n"

    /*
      * This is another place we need to deal with the coordinate systems.
      * The coordinate system is inverted, so this gets fancier.
      * 3ds Max Y = AE -Z
      * 3ds Max Z = AE Y
      * TODO(rex): Find a reference for this.
      */
    positionInfo+="\t" + frame as string
    positionInfo+="\t" + selectedObj.position.x as string
    positionInfo+="\t" + (-selectedObj.position.z) as string
    positionInfo+="\t" + selectedObj.position.y as string + "\n"
 
    rotationZInfo+="\t" + frame as string
    rotationZInfo+="\t" + rotationEuler.z as string + "\n"
  )

  outputText+=scaleInfo

  outputText+=rotationXInfo
  outputText+=rotationYInfo

  outputText+=positionInfo

  outputText+=rotationZInfo

  outputText+="\n\nEnd of Keyframe Data"
)


/*
 * =============================
 *     Let's get started!
 * =============================
 */

-- Setup some initial values for our menu.
selectedFrameRate=30
selectedFrameRangeStart=0
selectedFrameRangeEnd=100
selectedObj=undefined

-- Next, let's create the user interface.

-- Description / How to Use this script.
rollout howToUsePanel "How to Use" (
  label line1 "Get transform info for any 3d object!" align:#center
  group "Instructions" (
    label line2 "1. Set frame rate and range." align:#left
    label line3 "2. Choose an object." align:#left
    label line4 "3. Copy transform info." align:#left
    label line5 "4. Profit!" align:#left
  )
)

-- Configure framerate group
rollout configPanel "Configure" (
  group "Frame Rate" (
    spinner customFrameRate "FPS: " range:[1,100,selectedFrameRate] type:#integer scale:1 align:#center width:102

    -- Custom Frame Rate change Listener
    on customFrameRate changed val do (
      selectedFrameRate=val
      print "Frame Rate: " + selectedFrameRate as string
    )
  )

  -- Set frame range to copy group
  group "Frame Range" (
    spinner customFrameRangeStart "Start: " range:[-1000, 1000, selectedFrameRangeStart] type:#integer scale:1 align:#center width:102
    spinner customFrameRangeEnd "End: " range:[-1000, 1000, selectedFrameRangeEnd] type:#integer scale:1 align:#center width:102

    -- Start value change listener
    on customFrameRangeStart changed val do (
      selectedFrameRangeStart=val
      print "Start Frame: " + (selectedFrameRangeStart as string)
    )

    -- End value change listener
    on customFrameRangeEnd changed val do (
      selectedFrameRangeEnd=val
      print "End Frame: " + (selectedFrameRangeEnd as string)
    )
  )

  -- Object select group
  group "Object to Track" (
    pickbutton objectToTrack "Select an Object" width:148 height:24
    -- Object to track pick button change listener
    on objectToTrack picked obj do (
      selectedObj = obj
      objectToTrack.object = obj
      objectToTrack.text = obj.name
    )
  )

  -- Copy button
  group "Output" (
    button copyToClipboard "Copy to Clipboard" width:148 height:24 align:#center
    on copyToClipboard pressed do (

      -- Build the output text
      local outputText = buildOutputText()
      print outputText

      -- Attempt the copy!
      local success = setclipboardText outputText
      print "Copy to Clipboard: " + success as string
    )
  )
)

-- Credits rollout.
rollout creditsPanel "About" (
  label author "Created By" align:#center
  hyperLink websiteUrl "Rex Twedt" address:"http://www.rextwedt.com" align:#center
  label copyrightInfo "Copyright 2018"
  label versionInfo version
)

-- Create the floating rollout.
floatingRollout = newRolloutFloater "3D to AE" 240 504 300 200

-- Add the subrollouts to create the final menu.
addrollout howToUsePanel floatingRollout
addrollout configPanel floatingRollout
addrollout creditsPanel floatingRollout
