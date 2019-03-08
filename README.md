# 3D to AE

## Easily send 3d transform information from 3ds Max to Adobe After Effects!

### How to Use:

1. Set frame rate and range.
2. Choose an object.
3. Copy/save transform info.
4. Profit!

### Thoughts for v0.2.0:

Make sure to leave better notes about the coordinate system conversion.
3ds Max coordinate system:

- Center of screen is 0,0,0 (as long as you haven't moved camera)
- X-axis left/right
- Y-axis front/back
- Z-axis up/down
  AE coordinate system:
- Top left corner is 0,0
- X-axis left/right
- Y-axis up/down
- Z-axis front/back
  When determining the coordinates for an object, the Y/Z axis will need to be inverted.

Other Todos

- Some sort of README or Design Doc
- Check this into version control
- Coordinate origin coordinates could also be adjusted to hit the center of your AE comp (you will need to be able to input the comp size).
  - Perhaps an advanced setting like "adjust origin"?
  - NOTE(rex): This wouldn't work with rpf camera import, so camera support is a MUST.
  - Any other useful advanced settings?
- Combine the save/copy button into a single button w/ dynamic text. Include a 'Save File' checkbox with a file output path that is disabled if the box isn't checked. Should we still copy output text when saving? Might be a nice convenience.
- 1 and 2 Node Camera support
- Camera FOV support
- Useful logging
- Progress bar/progress text updates
- MacroScript for convenient binding
- Disable Modifier Panel update / switch to the Create Panel
- Further optimizations
- Tests?

### Useful Links

- [Output Object Data to File](https://help.autodesk.com/view/3DSMAX/2019/ENU/?guid=GUID-2DB3A775-776F-4D63-BDFB-D99523ECB69D)
- [System Information](https://help.autodesk.com/view/3DSMAX/2019/ENU/?guid=GUID-CAC36F27-CB51-4C9F-B265-167F636C9A4D#GUID-CAC36F27-CB51-4C9F-B265-167F636C9A4D)
- [FAQ](https://help.autodesk.com/view/3DSMAX/2019/ENU/?guid=GUID-982B0129-4277-4128-83F1-A6584D3F40E0) - Look at the optimization stuff specifically
  - Disable Redraw
  - Disable System Undo
- [Node Properties](https://help.autodesk.com/view/3DSMAX/2019/ENU/?guid=GUID-3B001F21-8FE9-4663-A972-E648682A0ACD#GUID-3B001F21-8FE9-4663-A972-E648682A0ACD)
