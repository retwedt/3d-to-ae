
/* Variables */
local VERSION = "v2.0.0"

local LOG_LEVEL = 2

local selectedFrameRateOpt

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
local compAspectRatio
local sourceAspectRatio

local shouldSaveToDisk
local outputFilePath


/* Functions */
local logger
local formatLineForOutputString
local buildOutputString
local setFrameRange
local validateData


/* Rollouts */
local threeDeeToAEDialog

local howToUseRollout
local timeConfigRollout
local paramsRollout
local advancedOptRollout
local saveOptsRollout
local creditsRollout


/* UI Elements */
local saveProgressTxt
local saveProgressBar















rollout howToUse "How to Use" (
  label howToTitle "Get transform info for any 3d object!" align:#center
  group "Instructions" (
    label instructionsLine2 "1. Set frame rate and range." align:#left
    label instructionsLine3 "2. Choose an object." align:#left
    label instructionsLine4 "3. Copy/save transform info." align:#left
    label instructionsLine5 "4. Profit!" align:#left
  )
  group "Notes" (
    label notesLine6 "TODO(rex): Write something useful here..." align:#left
  )
)


/* Time Configuration rollout */

rollout timeConfig "Time Configuration" (
  -- Configure Frame Rate
  group "Frame Rate" (
    radiobuttons frameRate
    spinner customFrameRate
  )

  -- Set Frame Range.
  group "Frame Range" (
    -- Custom Radio Button functionality.
    radiobuttons singleFrameOpt
    spinner frameStepSelector
    
    radiobuttons activeTimeSegmentOpt
    label activeTimeSegmentLabel

    radiobuttons frameRangeOpt
    spinner frameRangeStartSelector
    spinner frameRangeEndSelector

    radiobuttons customFramesOpt
    edittext customFramesText
  )
)


/* Object and Parameter Selection rollout */

rollout paramSelect "Object and Parameters" (
  -- Object select rollout.
  group "Object to Track" (
    pickbutton objectToTrack
    rcmenu objectToTrackContextMenu (
      menuItem mi_cs "Cast Shadows" checked:false
      menuItem mi_rs "Receive Shadows" checked:false
    )
  )

  -- Select Transform Parameters to Copy.
  group "Transform Parameters" (
    checkbox positionParam
    checkbox scaleParam
    checkbox rotationParam
  )


/* Advanced Options */

rollout advancedOptions "Advanced Options" (
  -- Special Paramters if you are copying a camera.
  group "Camera Options" (
    checkbox isCameraSelector
    checkbox targetParam
    checkbox fovParam
  )

  group "Adjust Origin Point" (
    checkbox shouldSetCustomOriginOpt

    radiobuttons autoAdjustOriginOpt
    label autoAdjustOriginXLabel
    label autoAdjustOriginYLabel
    label autoAdjustOriginZLabel
    
    radiobuttons customOriginOpt
    spinner customOriginXSelector
    spinner customOriginYSelector
    spinner customOriginZSelector
  )


  group "Output size" (
    spinner outputSizeWidthPx
    checkbutton lockAspectRatioFlag
    spinner outputSizeHeightPx
    label outputSizeAspectRatio
  )

  group "Aspect Ratio Configuration" (
    spinner setSourcePixelAspectRatioSelector
    spinner setCompPixelAspectRatioSelector
  )
)


/* Output Configuration */

rollout saveOpts "Output Configuration" (
  -- Save button
  local output_name = undefined

  checkbox shouldSaveToDiskSelector
  button selectFilePathBtn
  label saveFilePathLabel

  -- Copy button, progress bar and text.
  label saveProgressText
  button copyToClipboardBtn
  progressBar saveProgressBar
)


/* Credits rollout */

rollout credits "About" (
  label author
  hyperLink websiteUrl
  label copyrightInfo
  label versionInfo
)
