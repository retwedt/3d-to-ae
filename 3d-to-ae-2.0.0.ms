/*
 * =============================
 * 3D to AE
 * Description: Copy transform information from a 3d object in 3ds Max, for use in Adobe After Effects.
 * Author: Rex Twedt III
 * Version: 2.0.0
 * Tested in 3ds Max 2019 and AE CC 2017
 * Current Limitations: TODO
 * =============================
 */

global threeDeeToAEDialog

(

  /* Declare Local Variables */

  -- Vars
  local VERSION = "v2.0.0"
  /*
   * Log Levels:
   * - 0 - Silent
   * - 1 - Info
   * - 2 - Verbose
   */
  local LOG_LEVEL = 2

  local selectedFrameRateOpt
  local selectedFrameRate

  local selectedFrameRangeOpt
  local selectedFrameRangeStart
  local selectedFrameRangeEnd
  local selectedPickupFrames
  local selectedFrameSteps

  local selectedObj

  local includePositionInfo
  local includeRotationInfo
  local includeScaleInfo

  local isSelectedObjACamera
  local includeFovInfo
  local includeTargetInfo

  local shouldUseCustomOrigin
  local selectedCustomOriginOpt
  local customOriginX
  local customOriginY
  local customOriginZ

  local outputWidthPx
  local outputHeightPx
  local shouldLockOutputAspectRatio
  local outputPxAspectRatio
  local compPxAspectRatio

  local shouldSaveToDisk
  local outputFilePath

  -- Functions
  local logger
  local formatLineForOutputString
  local buildOutputString
  local getFrameRange
  local validateData
  local progressUI

  -- Rollouts
  local howToUseRollout
  local timeConfigRollout
  local paramsRollout
  local advancedOptRollout
  local saveOptsRollout
  local creditsRollout

  -- UI Elements
  local saveProgressLabel
  local saveProgressBar



  /* Functions */

  /*
   * Logger.
   * TODO(rex): Make it work...
   */
  fn logger logLevel msg args = (
    local SILENT = 0
    local INFO = 1
    local VERBOSE = 2

    if (logLevel >= LOG_LEVEL) then (
      return format
    ) else (
      return nil
    )
  )

  /*
   * Set the global frame range variables based on the current
   * Time Output Frame Range setting.
   */
   fn getFrameRange = (
    local outputFrames = #()

    if (selectedFrameRangeOpt == 1) then ( -- Single frame
      selectedFrameRangeStart = sliderTime
      selectedFrameRangeEnd = sliderTime
      append outputFrames selectedFrameRangeStart

    ) else if (selectedFrameRangeOpt == 2) then ( -- Active time segment
      selectedFrameRangeStart = animationRange.start
      selectedFrameRangeEnd = animationRange.end

      for i = selectedFrameRangeStart to selectedFrameRangeEnd do (
        append outputFrames i
      )

    ) else if (selectedFrameRangeOpt == 3) then ( -- User specified Range
      for i = selectedFrameRangeStart to selectedFrameRangeEnd do (
        append outputFrames i
      )

    ) else if (selectedFrameRangeOpt == 4) then ( -- Custom Frame Range
      -- print selectedPickupFrames
      local parts = filterString selectedPickupFrames ","

      -- TODO(rex): Make this better...
      for i = 1 to parts.count do (
        local part = parts[i]
        -- print part
        if (matchPattern part pattern:"*-*") then (
          -- print "Substring"
          local subparts = filterString (part as string) "-"
          -- print subparts as string
          local subpartStart = subparts[1] as integer
          local subpartEnd = subparts[2] as integer
          -- print subpartStart as string
          -- print subpartEnd as string
          for j = subpartStart to subpartEnd do (
            -- print j as string
            append outputFrames j
          )
        ) else if (matchPattern part pattern:"? ?") then (
          throw "Invalid Frame Range"

        ) else (
          append outputFrames (part as integer)
        )
      )

      -- print parts
    ) else (
      print "Invalid Frame Range Option"
    )

    -- TODO(rex): Remove this.
    format "Output frames %\n" (outputFrames as string)
    return outputFrames
  )

  /*
   * Construct a string based on an input array and return it.
   * By default, each value gets a tab between it, and a new line at the end.
   */
  fn formatLineForOutputString &output keyframeArr endWithNewline:true = (
    local tab = "\t"
    local newLine = "\n"
    for i = 1 to keyframeArr.count do (
      local key = keyframeArr[i]
      output += key
      if i < keyframeArr.count do (
        output += tab
      )
    )
    if endWithNewline==true do (
      output += newLine
    )
  )

  /*
   * Based on current settings, grab the transform data for the selected object,
   * and construct the output text as a giant string.
   */
  fn buildOutputString = (
    -- Go to the create panel to avoid potentially slow updates to the modifier panel.
    setCommandPanelTaskMode #create -- Optimization
    undo off ( -- Optimization.

      print "Building Header"

      -- We're gonna need this while constructing strings.
      local newLine = "\n"
      local tab = "" -- NOTE(rex): Faking a tab here, it will be handled by formatLineForOutputString

      -- Start building our output.  It's gonna be one massive string...
      local outputText=""
      formatLineForOutputString &outputText #("Adobe After Effects 8.0 Keyframe Data")
      formatLineForOutputString &outputText #() -- new line

      formatLineForOutputString &outputText #(tab, "Units Per Second", selectedFrameRate as string)
      formatLineForOutputString &outputText #(tab, "Source Width", outputWidthPx as string)
      formatLineForOutputString &outputText #(tab, "Source Height", outputHeightPx as string)
      formatLineForOutputString &outputText #(tab, "Source Pixel Aspect Ratio", outputPxAspectRatio as string)
      formatLineForOutputString &outputText #(tab, "Comp Pixel Aspect Ratio", compPxAspectRatio as string)
      formatLineForOutputString &outputText #() -- new line

      -- Temp variables used for transform info.
      local scaleInfo = ""
      local rotationXInfo = ""
      local rotationYInfo = ""
      local positionInfo = ""
      local rotationZInfo = ""
      local fovInfo = ""
      local targetInfo = ""
      local rotationEuler = undefined

      print "Collecting Transform Information"

      -- Get an array of frames to output keyframe data.
      local frames = getFrameRange()

      -- Loop through the frame range and grab the required data.
      with redraw off -- More optimization.
      for i = 1 to frames.count do (
        -- Set the current frame time.
        sliderTime = frames[i]

        local frame = currentTime.frame as integer

        if (isSelectedObjACamera == true) do (
          if (includeFovInfo == true) do (
            -- TODO(rex): Support FOV info on cameras.

            -- local hyp = sqrt ((pow outputWidthPx 2) + (pow outputHeightPx 2))
            local aov = selectedObj.fov -- angle of view in degrees
            local zoom = outputWidthPx / ( 2 * tan (aov / 2) ) -- math functions also use degrees.
            -- local zoom = hyp / tan aov -- math functions also use degrees.
            formatLineForOutputString &fovInfo #(tab, frame as string, zoom as string)
          )

          if (includeTargetInfo == true and selectedObj.targeted) do (
            formatLineForOutputString &targetInfo #(
              tab,
              frame as string,
              (selectedObj.Target.position.x) as string,
              (-selectedObj.Target.position.z) as string,
              (selectedObj.Target.position.y) as string
            )
          )
        )

        if (includeScaleInfo == true) do (
          formatLineForOutputString &scaleInfo #(
            tab,
            frame as string,
            (selectedObj.scale.x*100) as string,
            (selectedObj.scale.y*100) as string,
            (selectedObj.scale.z*100) as string
          )
        )

        if (includeRotationInfo == true) do (
          -- Convert the current rotation to Euler Angles.
          rotationEuler = quatToEuler2 (inverse selectedObj.transform.rotationPart)

          /*
           * 3ds max and AE have different coordinate systems, so we
           * will need to do a bit of work to make sure our values are correct.
           * Increase x rotation by 90 degrees.
           * TODO(rex): Find a reference for this.
           */
          formatLineForOutputString &rotationXInfo #(tab, frame as string, (rotationEuler.x - 180) as string)
          formatLineForOutputString &rotationYInfo #(tab, frame as string, (rotationEuler.y) as string)
        )

        /*
         * This is another place we need to deal with the coordinate systems.
         * The coordinate system is inverted, so this gets fancier.
         * 3ds Max Y = AE -Z
         * 3ds Max Z = AE Y
         * TODO(rex): Find a reference for this.
         */
        if (includePositionInfo == true) do (
          formatLineForOutputString &positionInfo #(
            tab,
            frame as string,
            selectedObj.position.x as string,
            (-selectedObj.position.z) as string,
            selectedObj.position.y as string
          )
        )

        if (includeRotationInfo == true) do (
          formatLineForOutputString &rotationZInfo #(tab, frame as string, rotationEuler.z as string)
        )
      )

      print "Building Transform Output"

      -- Start adding camera/transform info to the final output object, based on the selected options.
      if (isSelectedObjACamera == true) do (
        if (includeFovInfo == true) do (
          -- TODO(rex): Support FOV info on cameras.
          formatLineForOutputString &outputText #("Camera Options", "Zoom")
          formatLineForOutputString &outputText #(tab, "Frame", "pixels")
          outputText+=fovInfo
          formatLineForOutputString &outputText #() -- new line
        )

        if (includeTargetInfo == true and selectedObj.targeted) do (
          -- TODO(rex): Support Target info on cameras.
          formatLineForOutputString &outputText #("Transform", "Point of Interest")
          formatLineForOutputString &outputText #(tab, "Frame", "X pixels", "Y pixels", "Z pixels")
          outputText+=targetInfo
          formatLineForOutputString &outputText #() -- new line
        )
      )

      if (includeScaleInfo == true) do (
        formatLineForOutputString &outputText #("Transform", "Scale")
        formatLineForOutputString &outputText #(tab, "Frame", "X percent", "Y percent", "Z percent")
        outputText+=scaleInfo
        formatLineForOutputString &outputText #() -- new line
      )

      if (includeRotationInfo == true) do (
        formatLineForOutputString &outputText #("Transform", "X Rotation")
        formatLineForOutputString &outputText #(tab, "Frame", "degrees")
        outputText+=rotationXInfo
        formatLineForOutputString &outputText #() -- new line

        formatLineForOutputString &outputText #("Transform", "Y Rotation")
        formatLineForOutputString &outputText #(tab, "Frame", "degrees")
        outputText+=rotationYInfo
        formatLineForOutputString &outputText #() -- new line
      )

      if (includePositionInfo == true) do (
        formatLineForOutputString &outputText #("Transform", "Position")
        formatLineForOutputString &outputText #(tab, "Frame", "X pixels", "Y pixels", "Z pixels")
        outputText+=positionInfo
        formatLineForOutputString &outputText #() -- new line
      )

      if (includeRotationInfo == true) do (
        formatLineForOutputString &outputText #("Transform", "Rotation")
        formatLineForOutputString &outputText #(tab, "Frame", "degrees")
        outputText+=rotationZInfo
        formatLineForOutputString &outputText #() -- new line
      )

      print "Building Footer"

      formatLineForOutputString &outputText #()
      formatLineForOutputString &outputText #("End of Keyframe Data") endWithNewline:false

      print "Building Output Text was a success!"

      return outputText
    )
  )

  /*
   * Useful while setting values for custom Radio Button functionality.
   */
  fn getCustomRadioValue oldValue newValue = (
      if (oldValue == newValue) then (
        return 1
      ) else (
        return 0
      )
  )

  /*
   * Make sure there is an object and a valid frame range chosen.
   * If not throw an error.
   */
  fn validateData = (
    if (selectedObj == undefined) do (
      throw "Select an object to track."
    )
    if (selectedFrameRangeStart > selectedFrameRangeEnd) do (
      throw "Invalid frame range."
    )
    -- TODO(rex): Check this.
    -- if (selectedFrameRangeStart > animationRange.start or
    --     selectedFrameRangeEnd < animationRange.end) do (
    --   throw "Custom range outside of scene range."
    -- )
    if (includePositionInfo == false and
        includeRotationInfo == false and
        includeScaleInfo == false and
        includeFovInfo == false) do (
      throw "Select parameter(s) to copy."
    )
  )


  /*
   * =============================
   *     Let's get started!
   * =============================
   */

  -- Attempt to close any previous rollout that may exist.
  try (closeRolloutFloater threeDeeToAEDialog) catch()

  -- Setup some initial values for our menu.
  -- LOG_LEVEL = logger.VERBOSE
  LOG_LEVEL = 2

  -- Initial frame rate value.
  selectedFrameRate = frameRate as integer
  if selectedFrameRate == 30 then (
    selectedFrameRateOpt = 1

  ) else if selectedFrameRate == 24 then (
    selectedFrameRateOpt = 2

  ) else if selectedFrameRate == 25 then (
    selectedFrameRateOpt = 3

  ) else (
    selectedFrameRateOpt = 4
  )

  -- Initial frame range value.
  selectedFrameRangeOpt = rendTimeType
  if selectedFrameRangeOpt == 1 then ( -- Single frame
    selectedFrameRangeStart = sliderTime
    selectedFrameRangeEnd = sliderTime

  ) else if selectedFrameRangeOpt == 2 then ( -- Active time segment
    selectedFrameRangeStart = animationRange.start
    selectedFrameRangeEnd = animationRange.end

  ) else if selectedFrameRangeOpt == 3 then ( -- User specified Range
    selectedFrameRangeStart = rendStart
    selectedFrameRangeEnd = rendEnd

  )
  selectedFrameSteps = rendNThFrame
  selectedPickupFrames = rendPickupFrames

  selectedObj = undefined

  includePositionInfo = true
  includeRotationInfo = true
  includeScaleInfo = true

  isSelectedObjACamera = false
  includeTargetInfo = false
  includeFovInfo = true

  shouldUseCustomOrigin = false
  selectedCustomOriginOpt = 1
  customOriginX = 0.0
  customOriginY = 0.0
  customOriginZ = 0.0

  outputWidthPx = renderWidth
  outputHeightPx = renderHeight
  shouldLockOutputAspectRatio = rendLockImageAspectRatio
  outputPxAspectRatio = renderPixelAspect
  compPxAspectRatio = 1.0

  shouldSaveToDisk = false
  outputFilePath = (sysInfo.currentdir as string) + "\3d-to-ae-output.txt"


  -- Next, let's create the user interface.


  /* Description / How to Use this script. */

  rollout howToUseRollout "How to Use" (
    label howToUseTitle "Get transform info for any 3d object!" align:#center
    group "Instructions" (
      label instructionsLabel1 "1. Set frame rate and range." align:#left
      label instructionsLabel2 "2. Choose an object." align:#left
      label instructionsLabel3 "3. Copy/save transform info." align:#left
      label instructionsLabel4 "4. Profit!" align:#left
    )
    group "Notes" (
      label notesLabel1 "Data will always be copied to the clipboard." align:#left
      label notesLabel2 "Scene props are cloned on run." align:#left
      label notesLabel3 "Changing props in the script/scene won't affect each other." align:#left
      label notesLabel4 "TODO(rex): Write something useful here..." align:#left
    )
  )


  /* Time Configuration rollout */

  rollout timeConfigRollout "Time Configuration" (
    -- Configure Frame Rate
    group "Frame Rate" (
      radiobuttons frameRateOptions labels:#("NTSC", "Film", "PAL", "Custom") align:#left default:selectedFrameRateOpt toolTip:"TODO(rex): This is a useful label."
      spinner customFrameRateSelector "FPS:" range:[ 1, 100, selectedFrameRate ] type:#integer scale:1 enabled:(selectedFrameRateOpt == 4) align:#right width:76 toolTip:"TODO(rex): This is a useful label."

      -- Frame Rate Selection change listener
      on frameRateOptions changed state do (
        selectedFrameRateOpt = state

        if selectedFrameRateOpt == 1 then ( -- NTSC
          customFrameRateSelector.enabled = false
          selectedFrameRate = 30

        ) else if selectedFrameRateOpt == 2 then ( -- Film
          customFrameRateSelector.enabled = false
          selectedFrameRate = 24

        ) else if selectedFrameRateOpt == 3 then ( -- Pal
          customFrameRateSelector.enabled = false
          selectedFrameRate = 25

        ) else if selectedFrameRateOpt == 4 then ( -- Custom
          customFrameRateSelector.enabled = true
          selectedFrameRate = customFrameRateSelector.value
        )

        format "Frame Rate: %fps\n" (selectedFrameRate as string)
      )

      -- Custom Frame Rate Listener
      on customFrameRateSelector changed val do (
        selectedFrameRate = val
        format "Frame Rate: %fps\n" (selectedFrameRate as string)
      )
    )

    -- Set Frame Range.
    group "Frame Range" (

      -- Custom Radio Button functionality.
      radiobuttons singleFrameOptions labels:#("Single") align:#left default:(getCustomRadioValue selectedFrameRangeOpt 1) columns:1 across:2 toolTip:"TODO(rex): This is a useful label."
      spinner frameStepSelector "Every Nth Frame:" range:[ 1, 1000, 1 ] type:#integer scale:1 enabled:(selectedFrameRangeOpt == 2 or selectedFrameRangeOpt == 3) align:#right width:102 toolTip:"TODO(rex): This is a useful label."

      radiobuttons activeTimeSegmentOptions labels:#("Active Time Segment:") align:#left default:(getCustomRadioValue selectedFrameRangeOpt 2) columns:1 across:2 toolTip:"TODO(rex): This is a useful label."
      label activeTimeSegmentLabel "0 To 47" align:#right enabled:(selectedFrameRangeOpt == 2)

      radiobuttons frameRangeOptions labels:#("Range:") align:#left default:(getCustomRadioValue selectedFrameRangeOpt 3) columns:1 across:3 toolTip:"TODO(rex): This is a useful label."
      spinner frameRangeStartSelector "" range:[ -1000, 1000, rendStart ] type:#integer scale:1 enabled:(selectedFrameRangeOpt == 3) align:#right width:56 toolTip:"TODO(rex): This is a useful label."
      spinner frameRangeEndSelector "To " range:[ -1000, 1000, rendEnd ] type:#integer scale:1 enabled:(selectedFrameRangeOpt == 3) align:#right width:72 toolTip:"TODO(rex): This is a useful label."

      radiobuttons pickupFramesOptions labels:#("Frames:") align:#left default:(getCustomRadioValue selectedFrameRangeOpt 4) columns:1 across:2 toolTip:"TODO(rex): This is a useful label."
      edittext pickupFramesInput "" text:selectedPickupFrames fieldWidth:150 enabled:(selectedFrameRangeOpt == 4) align:#right toolTip:"TODO(rex): This is a useful label."

      on singleFrameOptions changed val do (
        selectedFrameRangeOpt = 1

        selectedFrameRangeStart = sliderTime
        selectedFrameRangeEnd = sliderTime

        singleFrameOptions.state = 1
        activeTimeSegmentOptions.state = 0
        frameRangeOptions.state = 0
        pickupFramesOptions.state = 0

        activeTimeSegmentLabel.enabled = false
        frameStepSelector.enabled = false
        frameRangeStartSelector.enabled = false
        frameRangeEndSelector.enabled = false
        pickupFramesInput.enabled = false

        format "Frame Range: Single %\n" (selectedFrameRangeStart as string)
      )

      -- Every nth frame change listener
      on frameStepSelector changed step do (
        format "Every nth frame: %\n" step
      )

      on activeTimeSegmentOptions changed val do (
        selectedFrameRangeOpt = 2

        selectedFrameRangeStart = animationRange.start
        selectedFrameRangeEnd = animationRange.end

        singleFrameOptions.state = 0
        activeTimeSegmentOptions.state = 1
        frameRangeOptions.state = 0
        pickupFramesOptions.state = 0

        activeTimeSegmentLabel.enabled = true
        frameStepSelector.enabled = true
        frameRangeStartSelector.enabled = false
        frameRangeEndSelector.enabled = false
        pickupFramesInput.enabled = false

        format "Frame Range: Active Time Segment % to %\n" (selectedFrameRangeStart as string) (selectedFrameRangeEnd as string)
      )
      on frameRangeOptions changed val do (
        selectedFrameRangeOpt = 3

        selectedFrameRangeStart = frameRangeStartSelector.value
        selectedFrameRangeEnd = frameRangeEndSelector.value

        singleFrameOptions.state = 0
        activeTimeSegmentOptions.state = 0
        frameRangeOptions.state = 1
        pickupFramesOptions.state = 0

        activeTimeSegmentLabel.enabled = false
        frameStepSelector.enabled = true
        frameRangeStartSelector.enabled = true
        frameRangeEndSelector.enabled = true
        pickupFramesInput.enabled = false

        format "Frame Range: Custom Range % to %\n" (selectedFrameRangeStart as string) (selectedFrameRangeEnd as string)
      )

      -- Start Frame change listener
      on frameRangeStartSelector changed val do (
        selectedFrameRangeStart = val
        format "Start Frame: %\n" (selectedFrameRangeStart as string)
      )

      -- End frame change listener
      on frameRangeEndSelector changed val do (
        selectedFrameRangeEnd = val
        format "End Frame: %\n" (selectedFrameRangeEnd as string)
      )

      on pickupFramesOptions changed val do (
        selectedFrameRangeOpt = 4

        singleFrameOptions.state = 0
        activeTimeSegmentOptions.state = 0
        frameRangeOptions.state = 0
        pickupFramesOptions.state = 1

        activeTimeSegmentLabel.enabled = false
        frameStepSelector.enabled = false
        frameRangeStartSelector.enabled = false
        frameRangeEndSelector.enabled = false
        pickupFramesInput.enabled = true

        -- TODO(rex): Remove me.
        local frames = getFrameRange()

        format "Pickup Frames: %\n" (selectedPickupFrames as string)
      )

      -- Pickup Frame text change listener
      on pickupFramesInput changed val do (
        selectedPickupFrames = val
        format "Pickup Frames: %\n" (selectedPickupFrames as string)
      )
    )
  )


  /* Object and Parameter Selection rollout */

  rollout paramsRollout "Object and Parameters" (
    -- Object select rollout.
    group "Object to Track" (
      pickbutton objectPicker "Select an Object" width:156 height:24 autoDisplay:true toolTip:"TODO(rex): This is a useful label."

      on objectPicker picked obj do (
        selectedObj = obj
        objectPicker.object = obj
        format "Object Selected: %\n" selectedObj.name
        -- showProperties obj
      )
      on objectPicker rightclick do (
        print "TODO(rex): Right click context menu for pick button."
      )
    )

    -- Select Transform Parameters to Copy.
    group "Transform Parameters" (
      checkbox includePositionChk "Position" checked:includePositionInfo align:#center across:3 toolTip:"TODO(rex): This is a useful label."
      checkbox includeRotationChk "Rotation" checked:includeRotationInfo align:#center toolTip:"TODO(rex): This is a useful label."
      checkbox includeScaleChk "Scale" checked:includeScaleInfo align:#center toolTip:"TODO(rex): This is a useful label."

      on includePositionChk changed state do (
        includePositionInfo = state
        format "Include Position Info: %\n" (includePositionInfo as string)
      )

      on includeRotationChk changed state do (
        includeRotationInfo = state
        format "Include Rotation Info: %\n" (includeRotationInfo as string)
      )

      on includeScaleChk changed state do (
        includeScaleInfo = state
        format "Include Scale Info: %\n" (includeScaleInfo as string)
      )
    )

    -- Special Paramters if you are copying a camera.
    group "Camera Options" (
      checkbox isCameraChk "Is Camera" checked:isSelectedObjACamera align:#left across:3 toolTip:"TODO(rex): This is a useful label."
      checkbox includeTargetInfoChk "Targeted" checked:includeTargetInfo enabled:isSelectedObjACamera align:#right toolTip:"TODO(rex): This is a useful label."
      checkbox includeFovInfoChk "FOV" checked:includeFovInfo enabled:isSelectedObjACamera align:#right toolTip:"TODO(rex): This is a useful label."

      on isCameraChk changed state do (
        isSelectedObjACamera = state
        includeTargetInfoChk.enabled = state
        includeFovInfoChk.enabled = state
        format "Is Selected Obj a Camera: %\n" (isSelectedObjACamera as string)
      )

      on includeTargetInfoChk changed state do (
        includeTargetInfo = state
        format "Include Target Info: %\n" (includeTargetInfo as string)
      )

      on includeFovInfoChk changed state do (
        includeFovInfo = state
        format "Include FOV Info: %\n" (includeFovInfo as string)
      )
    )
  )


  /* Advanced Options */

  rollout advancedOptRollout "Advanced Options" (

    group "Adjust Origin Point" (
      checkbox shouldSetCustomOriginChk "Set Custom Origin" width:112 checked:shouldUseCustomOrigin align:#left toolTip:"TODO(rex): This is a useful label."

      radiobuttons autoAdjustOriginOptions labels:#("Auto Center") align:#left enabled:(shouldUseCustomOrigin == true) default:(getCustomRadioValue selectedCustomOriginOpt 1) columns:1 toolTip:"TODO(rex): This is a useful label."
      label autoAdjustOriginXLabel "X: 0.0" align:#center enabled:(shouldUseCustomOrigin == true and selectedCustomOriginOpt == 1) across:3
      label autoAdjustOriginYLabel "Y: 0.0" align:#center enabled:(shouldUseCustomOrigin == true and selectedCustomOriginOpt == 1)
      label autoAdjustOriginZLabel "Z: 0.0" align:#center enabled:(shouldUseCustomOrigin == true and selectedCustomOriginOpt == 1)

      radiobuttons customOriginOptions labels:#("Custom") align:#left default:(getCustomRadioValue selectedCustomOriginOpt 2) columns:1 enabled:(shouldUseCustomOrigin == true) toolTip:"TODO(rex): This is a useful label."
      spinner customOriginXSelector "X:" range:[ -1000.0, 1000.0, customOriginX ] type:#float scale:0.01 enabled:(shouldUseCustomOrigin == true and selectedCustomOriginOpt == 2) align:#center width:72 toolTip:"TODO(rex): This is a useful label." across:3
      spinner customOriginYSelector "Y:" range:[ -1000.0, 1000.0, customOriginY ] type:#float scale:0.01 enabled:(shouldUseCustomOrigin == true and selectedCustomOriginOpt == 2) align:#center width:72 toolTip:"TODO(rex): This is a useful label."
      spinner customOriginZSelector "Z:" range:[ -1000.0, 1000.0, customOriginZ ] type:#float scale:0.01 enabled:(shouldUseCustomOrigin == true and selectedCustomOriginOpt == 2) align:#center width:72 toolTip:"TODO(rex): This is a useful label."

      on shouldSetCustomOriginChk changed state do (
        shouldUseCustomOrigin = state
        autoAdjustOriginOptions.enabled = shouldUseCustomOrigin
        customOriginOptions.enabled = shouldUseCustomOrigin

        if (customOriginOptions.state == 1) do (
          customOriginYSelector.enabled = shouldUseCustomOrigin
          customOriginXSelector.enabled = shouldUseCustomOrigin
          customOriginZSelector.enabled = shouldUseCustomOrigin
        )

        if (autoAdjustOriginOptions.state == 1) do (
          autoAdjustOriginXLabel.enabled = shouldUseCustomOrigin
          autoAdjustOriginYLabel.enabled = shouldUseCustomOrigin
          autoAdjustOriginZLabel.enabled = shouldUseCustomOrigin
        )

        format "Should Set a Custom Origin: %\n" (shouldUseCustomOrigin as string)
      )

      on autoAdjustOriginOptions changed val do (
        selectedCustomOriginOpt = 1
        autoAdjustOriginOptions.state = 1
        autoAdjustOriginXLabel.enabled = true
        autoAdjustOriginYLabel.enabled = true
        autoAdjustOriginZLabel.enabled = true
        customOriginOptions.state = 0
        customOriginYSelector.enabled = false
        customOriginXSelector.enabled = false
        customOriginZSelector.enabled = false

        print "Auto calculate custom origin"
      )
      on customOriginOptions changed val do (
        selectedCustomOriginOpt = 2
        autoAdjustOriginOptions.state = 0
        autoAdjustOriginXLabel.enabled = 0
        autoAdjustOriginYLabel.enabled = 0
        autoAdjustOriginZLabel.enabled = 0
        customOriginOptions.state = 1
        customOriginYSelector.enabled = true
        customOriginXSelector.enabled = true
        customOriginZSelector.enabled = true

        print "Set custom origin"
      )

      on customOriginXSelector changed val do (
        customOriginX = val
        format "New Origin X: %\n" (customOriginX as string)
      )
      on customOriginYSelector changed val do (
        customOriginY = val
        format "New Origin Y: %\n" (customOriginY as string)
      )
      on customOriginZSelector changed val do (
        customOriginZ = val
        format "New Origin Z: %\n" (customOriginZ as string)
      )
    )

    group "Output size" (
      spinner outputSizeWidthSelector "Width (px):  " range:[ -1000, 1000, outputWidthPx ] type:#integer scale:1 align:#left width:124 across:2 toolTip:"TODO(rex): This is a useful label."
      checkbutton lockAspectRatioChk "Lock" checked:shouldLockOutputAspectRatio align:#center
      spinner outputSizeHeightSelector "Height (px):" range:[ -1000, 1000, outputHeightPx ] type:#integer scale:1 align:#left width:124 toolTip:"TODO(rex): This is a useful label."
      label outputSizeAspectRatioLabel "Image Aspect Ratio: 1.00" align:#left

      on outputSizeWidthSelector changed val do (
        outputWidthPx = val
        format "Output Width (px): %\n" (outputWidthPx as string)
      )
      on outputSizeHeightSelector changed val do (
        outputHeightPx = val
        format "Output Height (px): %\n" (outputHeightPx as string)
      )
      on lockAspectRatioChk changed state do (
        shouldLockOutputAspectRatio = state
        format "Lock Aspect Ratio: %\n" (shouldLockOutputAspectRatio as string)
      )
    )

    group "Pixel Aspect Ratio Configuration" (
      spinner setSourcePxAspectRatioSelector "Output Px Aspect Ratio:" range:[ -10.0, 10.0, outputPxAspectRatio ] type:#float scale:0.01 align:#left width:96 toolTip:"TODO(rex): This is a useful label."
      spinner setCompPxAspectRatioSelector "Comp Px Aspect Ratio:" range:[ -10.0, 10.0, compPxAspectRatio ] type:#float scale:0.01 align:#left width:96 toolTip:"TODO(rex): This is a useful label."

      on setSourcePxAspectRatioSelector changed val do (
        outputPxAspectRatio = val
        format "New Source Aspect Ratio: %\n" (outputPxAspectRatio as string)
      )
      on setCompPxAspectRatioSelector changed val do (
        compPxAspectRatio = val
        format "New Comp Aspect Ratio: %\n" (compPxAspectRatio as string)
      )
    )
  )


  /* Output Configuration */

  rollout saveOptsRollout "Output Configuration" (
    -- Save button
    checkbox shouldSaveToDiskSelector "Save File" align:#left checked:shouldSaveToDisk across:2 toolTip:"TODO(rex): This is a useful label."
    button selectFilePathBtn "Files..." width:72 height:18 align:#right enabled:shouldSaveToDisk toolTip:"TODO(rex): This is a useful label."
    label saveFilePathLabel outputFilePath style_sunkenedge:true width:212 height:16 align:#center enabled:shouldSaveToDisk toolTip:"TODO(rex): This is a useful label."

    -- Copy button, progress bar and text.
    label saveProgressLabel "Ready" align:#center width:96 height:32 offset:[0,2] across:2 style_sunkenedge:true
    button copyToClipboardBtn "Generate Data!" width:102 height:36 align:#center toolTip:"TODO(rex): This is a useful label."
    progressBar saveProgressBar value:0 width:212 height:6 color:[ 255,255,255 ] align:#center

    /*
     * Update the progress bar and status message with something useful.
     * Also print it to the console.
     */
    fn progressUI msg progress:0 = (
      saveProgressLabel.text = msg
      saveProgressBar.value = (progress as integer)
      print msg
    )

    on shouldSaveToDiskSelector changed state do (
      shouldSaveToDisk = state
      selectFilePathBtn.enabled = shouldSaveToDisk
      saveFilePathLabel.enabled = shouldSaveToDisk
      format "Should save to disk: %\n" (shouldSaveToDisk as string)
    )

    on selectFilePathBtn pressed do (
      local fileName = getSaveFileName filename:"3d-to-ae-output.txt" caption:"3D to AE Output" types:"Text (*.txt)|All Files (*.*)|*.*|"
      outputFilePath = fileName as string
      saveFilePathLabel.text = outputFilePath
      format "Save File to: %\n" outputFilePath
    )

    on copyToClipboardBtn pressed do (
      -- Log progress updates
      progressUI "Checking Configuration" progress:15

      -- Is any data missing/invalid?
      try (
        validateData()
      ) catch (
        progressUI (getCurrentException()) progress:0
        messageBox (getCurrentException())
        return false
      )

      -- Log progress updates
      progressUI "Building Output String" progress:40

      -- Build the output text
      local outputText = buildOutputString()
      print outputText

      -- Log progress updates
      progressUI "Copying Output to Clipboard" progress:60

      -- Attempt the copy!
      try (
        local wasCopySuccess = setclipboardText outputText
        format "Copy to Clipboard: %\n" wasCopySuccess
      ) catch (
        progressUI (getCurrentException()) progress:0
        messageBox (getCurrentException())
        return false
      )

      -- Attempt to Save to disk (if selected)!
      if (shouldSaveToDisk) do (
        progressUI "Saving Output to Disk" progress:80

        try (
          if outputFilePath != undefined then (
            outputFile = createfile outputFilePath
            format outputText to:outputFile
            close outputFile
            edit outputFilePath
            format "Save to Disk: %\n" true
          )
        ) catch (
          progressUI (getCurrentException()) progress:0
          messageBox (getCurrentException())
          return false
        )
      )

      -- Log progress updates
      progressUI "Success!" progress:100
    )
  )


  /* Credits rollout */

  rollout creditsRollout "About" (
    label authorLabel "Created By: " align:#right width:60 across:2
    hyperLink websiteUrl " Rex Twedt" address:"http://www.rextwedt.com" align:#left width:60
    label copyrightLabel "Copyright \xa9 2018" align:#center
    label versionLabel VERSION align:#center
  )

  -- Create the floating rollout.
  threeDeeToAEDialog = newRolloutFloater "3D to AE" 264 578 300 200

  -- Add the subrollouts to create the final menu.
  addrollout howToUseRollout threeDeeToAEDialog rolledUp:true
  addrollout timeConfigRollout threeDeeToAEDialog
  addrollout paramsRollout threeDeeToAEDialog
  addrollout advancedOptRollout threeDeeToAEDialog rolledUp:true
  addrollout saveOptsRollout threeDeeToAEDialog
  addrollout creditsRollout threeDeeToAEDialog rolledUp:true

)
