/*
 * =============================
 * 3D to AE
 * Description: Copy transform information from a 3d object in 3ds Max, for use in Adobe After Effects. Work in progress but getting better.
 * Author: Rex Twedt III
 * Version: 1.0.0
 * Tested in 3ds Max 2019
 * =============================
 */


/* Global Variables */

global version="v1.0.0"

global currentFrame
global selectedFrameRate
global selectedFrameRangeStart
global selectedFrameRangeEnd
global selectedObj

global includePositionInfo
global includeRotationInfo
global includeScaleInfo

global initialFrameRate
global initialFrameRange


/* Functions */

/*
 * Based on current settings, grab the transform data for the selected object,
 * and construct the output text as a giant string.
 */
fn buildOutputText = (
  undo off ( -- Optimization.

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
    if includeScaleInfo==true do (
      scaleInfo="\nTransform\tScale\n"
      scaleInfo+="\tFrame\tX percent\tY percent\tZ percent\n"
    )

    local rotationXInfo=nil
    local rotationYInfo=nil
    if includeRotationInfo==true do (
      rotationXInfo="\nTransform\tX Rotation\n"
      rotationXInfo+="\tFrame\tdegrees\n"

      rotationYInfo="\nTransform\tY Rotation\n"
      rotationYInfo+="\tFrame\tdegrees\n"
    )

    local positionInfo=nil
    if includePositionInfo==true do (
      positionInfo="\nTransform\tPosition\n"
      positionInfo+="\tFrame\tX pixels\tY pixels\tZ pixels\n"
    )

    local rotationZInfo=nil
    if includeRotationInfo==true do (
      rotationZInfo="\nTransform\tRotation\n"
      rotationZInfo+="\tFrame\tdegrees\n"
    )
  
    -- Temp variable used for rotation conversions (if necessary).
    local rotationEuler

    -- Loop through the frame range and grab the required data.
    with redraw off -- More optimization.
    for i = selectedFrameRangeStart to selectedFrameRangeEnd do (
      -- Set the current frame time.
      sliderTime=i

      local frame = currentTime.frame as integer
      if includeScaleInfo==true do (
        scaleInfo+="\t" + frame as string
        scaleInfo+="\t" + (selectedObj.scale.x*100) as string
        scaleInfo+="\t" + (selectedObj.scale.y*100) as string
        scaleInfo+="\t" + (selectedObj.scale.z*100) as string + "\n"
      )
    
      if includeRotationInfo==true do (
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
      )

      /*
        * This is another place we need to deal with the coordinate systems.
        * The coordinate system is inverted, so this gets fancier.
        * 3ds Max Y = AE -Z
        * 3ds Max Z = AE Y
        * TODO(rex): Find a reference for this.
        */
      if includePositionInfo==true do (
        positionInfo+="\t" + frame as string
        positionInfo+="\t" + selectedObj.position.x as string
        positionInfo+="\t" + (-selectedObj.position.z) as string
        positionInfo+="\t" + selectedObj.position.y as string + "\n"
      )
    
      if includeRotationInfo==true do (
        rotationZInfo+="\t" + frame as string
        rotationZInfo+="\t" + rotationEuler.z as string + "\n"
      )
    )

    if includeScaleInfo==true do (
      outputText+=scaleInfo
    )

    if includeRotationInfo==true do (
      outputText+=rotationXInfo
      outputText+=rotationYInfo
    )

    if includePositionInfo==true do (
      outputText+=positionInfo
    )

    if includeRotationInfo==true do (
      outputText+=rotationZInfo
    )

    outputText+="\n\nEnd of Keyframe Data"
  )
)

/*
 * Set the global frame range variables based on the current
 * Time Output Frame Range setting.
 */
fn setFrameRange rangeSetting = (
  if rangeSetting==1 then ( -- Single frame
    selectedFrameRangeStart=sliderTime
    selectedFrameRangeEnd=sliderTime

  ) else if rangeSetting==2 then ( -- Active time segment
    selectedFrameRangeStart=animationRange.start
    selectedFrameRangeEnd=animationRange.end

  ) else if rangeSetting==3 then ( -- User specified Range
    selectedFrameRangeStart=rendStart
    selectedFrameRangeEnd=rendEnd

  ) else ( -- Custom
    print "Skip this option and default to Single Frame (1)."
    rangeSetting=1
  )
)

/*
 * Make sure there is an object and a valid frame range chosen.
 * If not throw an error.
 */
fn checkForMissingData = (
  if (selectedObj==nil) do (
    throw "Select an object to track."
  )
  if (selectedFrameRangeStart>selectedFrameRangeEnd) do (
    throw "Invalid frame range."
  )
  if (includePositionInfo==false and
      includeRotationInfo==false and
      includeScaleInfo==false) do (
    throw "Select parameter(s) to copy."
  )
)

/*
 * =============================
 *     Let's get started!
 * =============================
 */

-- Setup some initial values for our menu.

-- Configure the globals.
currentFrame=nil
selectedFrameRate=frameRate as integer
selectedFrameRangeStart=nil
selectedFrameRangeEnd=nil
selectedObj=nil

includePositionInfo=true
includeRotationInfo=true
includeScaleInfo=true

initialFrameRate=nil
initialFrameRange=rendTimeType

-- Initial frame rate value.
if selectedFrameRate==30.0 then (
  initialFrameRate=1

) else if selectedFrameRate==24.0 then (
  initialFrameRate=2

) else if selectedFrameRate==25.0 then (
  initialFrameRate=3

) else (
  initialFrameRate=4
)

-- Initial frame range value.
setFrameRange initialFrameRange


-- Next, let's create the user interface.

-- Description / How to Use this script.
rollout howToUse "How to Use" (
  label line1 "Get transform info for any 3d object!" align:#center
  group "Instructions" (
    label line2 "1. Set frame rate and range." align:#left
    label line3 "2. Choose an object." align:#left
    label line4 "3. Copy/save transform info." align:#left
    label line5 "4. Profit!" align:#left
  )
)

-- Configure framerate rollout.
rollout timeConfig "Time Configuration" (
  group "Frame Rate" (
    radiobuttons frameRate labels:#("NTSC", "Film", "PAL", "Custom") align:#left default:initialFrameRate
    spinner customFrameRate "FPS: " range:[1,100,30] type:#integer scale:1 enabled:(initialFrameRate==4) align:#right width:102

    -- Radio button change listener
    on frameRate changed state do (
      if frameRate.state==1 then ( -- NTSC
        customFrameRate.enabled=false
        selectedFrameRate=30

      ) else if frameRate.state==2 then ( -- Film
        customFrameRate.enabled=false
        selectedFrameRate=24

      ) else if frameRate.state==3 then ( -- Pal
        customFrameRate.enabled=false
        selectedFrameRate=25

      ) else if frameRate.state==4 then ( -- Custom
        customFrameRate.enabled=true
        selectedFrameRate=customFrameRate.value
      )
      print "Frame Rate: " + selectedFrameRate as string
    )

    -- Custom Frame Rate Listener
    on customFrameRate changed val do (
      selectedFrameRate=val
      print "Frame Rate: " + selectedFrameRate as string
    )
  )

  -- Set frame range to copy.
  group "Frame Range" (
    radiobuttons frameRange labels:#("Single", "Active Time Segment", "Custom") align:#left default:initialFrameRange
    -- TODO(rex): Start at the start/end for the scene.
    spinner customFrameRangeStart "Start: " range:[-1000, 1000, 0] type:#integer scale:1 enabled:(initialFrameRange==3) align:#center width:102
    spinner customFrameRangeEnd "End: " range:[-1000, 1000, 100] type:#integer scale:1 enabled:(initialFrameRange==3) align:#center width:102

    -- Radio button change listener
    on frameRange changed state do (
      if frameRange.state==3 then (
        customFrameRangeStart.enabled=true
        customFrameRangeEnd.enabled=true
        
      ) else (
        customFrameRangeStart.enabled=false
        customFrameRangeEnd.enabled=false
      )

      setFrameRange state
    )

    -- Start value listener
    on customFrameRangeStart changed val do (
      selectedFrameRangeStart=val
      print "Start Frame: " + selectedFrameRangeStart as string
    )

    -- End value listener
    on customFrameRangeEnd changed val do (
      selectedFrameRangeEnd=val
      print "End Frame: " + selectedFrameRangeEnd as string
    )
  )
)

-- Select Params to Copy.
rollout paramSelect "Object and Parameters" (
  group "Parameters" (
    checkbox positionParam "Position" checked:includePositionInfo
    on positionParam changed state do (
      print "Position: " + state as string
      includePositionInfo=state
    )
  
    checkbox rotationParam "Rotation" checked:includeRotationInfo
    on rotationParam changed state do (
      print "Rotation: " + state as string
      includeRotationInfo=state
    )
  
    checkbox scaleParam "Scale" checked:includeScaleInfo
    on scaleParam changed state do (
      print "Scale: " + state as string
      includeScaleInfo=state
    )
  )

  -- Object select rollout.
  group "Object to Track" (
    pickbutton objectToTrack "Select an Object" width:148 height:24
    on objectToTrack picked obj do (
      selectedObj = obj
      objectToTrack.object = obj
      objectToTrack.text = obj.name
      objectToTrack.tooltip = obj.name
    )
  )
)

-- Save/copy rollout.
rollout saveOpts "Output Configuration" (
  -- Save button
  button saveToDisk "Save to Disk" width:148 height:24 align:#center
  on saveToDisk pressed do (
    -- Is any data missing?
    try (
      checkForMissingData()
    ) catch (
      print (getCurrentException())
      messageBox (getCurrentException())
      return false
    )

    -- Build the output text
    local outputText = buildOutputText()
    print outputText

    -- Save to disk!
    try (
      local output_name = getSaveFileName filename:"3d-to-ae-output.txt" caption:"3D to AE Output" types:"Text (*.txt)|All Files (*.*)|*.*|"
      if output_name != undefined then (
        output_file = createfile output_name
        format outputText to:output_file
        close output_file
        edit output_name
      )
    ) catch (
      print (getCurrentException())
      messageBox (getCurrentException())
      return false
    )
  )

  -- Copy button
  button copyToClipboard "Copy to Clipboard" width:148 height:24 align:#center
  on copyToClipboard pressed do (

    -- Is any data missing?
    try (
      checkForMissingData()
    ) catch (
      print (getCurrentException())
      messageBox (getCurrentException())
      return false
    )

    -- Build the output text
    local outputText = buildOutputText()
    print outputText

    -- TODO(rex): Error check min/max.

    -- Attempt the copy!
    try (
      retCode = setclipboardText outputText
      format "Copy to Clipboard: %\n" retCode
    ) catch (
      format "*** % ***\n" (getCurrentException())
    )
  )
)

-- Credits rollout.
rollout credits "About" (
  label author "Created By" align:#center
  hyperLink websiteUrl "Rex Twedt" address:"http://www.rextwedt.com" align:#center
  label copyrightInfo "Copyright 2018"
  label versionInfo version
)

-- Create the floating rollout.
floatingRollout = newRolloutFloater "3D to AE" 240 520 300 200

-- Add the subrollouts to create the final menu.
addrollout howToUse floatingRollout rolledUp:true
addrollout timeConfig floatingRollout
addrollout paramSelect floatingRollout
addrollout saveOpts floatingRollout
addrollout credits floatingRollout rolledUp:true
