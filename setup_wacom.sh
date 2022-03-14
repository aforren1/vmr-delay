# see https://linux.die.net/man/1/xsetwacom for details
# should be Option "Area" "0 0 62200 43200"
echo "Setting tablet settings..."
STYLUS="Wacom Intuos Pro L Pen stylus"
xsetwacom --set "$STYLUS" ResetArea
# no suppression
xsetwacom --set "$STYLUS" Suppress 0
# no sliding window
xsetwacom --set "$STYLUS" RawSample 1
# don't use pressure, so ??
xsetwacom --set "$STYLUS" PressureRecalibration off
# (effectively) disable button functionality of stylus
xsetwacom --set "$STYLUS" Threshold 2047
# TODO: MapToOutput, which will be an offset relative to the operator monitor
# or can we just hide the cursor and draw the circle in the proper spot?

# physical active area is 311 x 216 mm
# resolution is 5080 lines/inch (200 lines/mm)

# xsetwacom --set "Wacom Intuos Pro L Pen stylus" MapToOutput 1920x1080+2560+0
# xsetwacom --get "Wacom Intuos Pro L Pen stylus" all

# part 2: turn off other pen functionality
# I bet this doesn't really have an impact on performance,
# because it's probably only affecting what X sees (i.e. the intrinsic state of the
# tablet is unchanged, and /dev/input still gets it all)

PAD="Wacom Intuos Pro L Pad pad"
TOUCH="Wacom Intuos Pro L Finger touch"
ERASER="Wacom Intuos Pro L Pen eraser"

xsetwacom --set "$PAD" Suppress 100
xsetwacom --set "$PAD" RawSample 20
xsetwacom --set "$PAD" Threshold 2047

xsetwacom --set "$TOUCH" Touch off
xsetwacom --set "$TOUCH" Gesture off
xsetwacom --set "$TOUCH" Suppress 100
xsetwacom --set "$TOUCH" RawSample 20

xsetwacom --set "$ERASER" Suppress 100
xsetwacom --set "$ERASER" RawSample 20
xsetwacom --set "$ERASER" CursorProximity 1
echo "Done setting tablet settings..."
