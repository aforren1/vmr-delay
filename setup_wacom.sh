# see https://linux.die.net/man/1/xsetwacom for details
echo "Setting tablet settings..."
STYLUS="Wacom Intuos Pro L Pen stylus"
#STYLUS="Wacom Intuos Pro L Pen Pen (0x1680a989)" # only if we used evdev driver, which we don't now
# should be Option "Area" "0 0 62200 43200"
xsetwacom --set "$STYLUS" ResetArea
# no suppression
xsetwacom --set "$STYLUS" Suppress 0
# no sliding window
xsetwacom --set "$STYLUS" RawSample 1
# don't use pressure, so ??
xsetwacom --set "$STYLUS" PressureRecalibration off
# (effectively) disable button functionality of stylus
xsetwacom --set "$STYLUS" Threshold 2047

# disconnect from mouse system
# look for floating devices (5) in PsychHID('Devices')
#to reattach (e.g. for testing), something like `xinput reattach (dev #) (master #)`
xinput float "$STYLUS"

# failed mapping attempts, multi-x-windows are hard
#DISPLAY=:0.1 xinput map-to-output "$STYLUS" DisplayPort-2
# DISPLAY=:0.1 xsetwacom --set "Wacom Intuos Pro L Pen stylus" MapToOutput DisplayPort-2

# physical active area is 311 x 216 mm
# resolution is 5080 lines/inch (200 lines/mm)
# mapping explanation (I don't really get it either)
# 549 is 1098 (the number of px the tablet *should* cover)/2 (b/c it counts the operator display too??)
# 711 is the number of px the tablet should cover height-wise
# 1166 is 960 (i.e. 1920/2, because horizontal counts for double) + 411/2 (where 411 should be the proper remainder...)
# 155 is vertical offset, which is consistent with experience
# if the operator display ever changes, you would need to work this out again
xsetwacom --set "Wacom Intuos Pro L Pen stylus" MapToOutput 549x771+1166+155
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
xinput float "$PAD"

xsetwacom --set "$TOUCH" Touch off
xsetwacom --set "$TOUCH" Gesture off
xsetwacom --set "$TOUCH" Suppress 100
xsetwacom --set "$TOUCH" RawSample 20
xinput float "$TOUCH"

xsetwacom --set "$ERASER" Suppress 100
xsetwacom --set "$ERASER" RawSample 20
xsetwacom --set "$ERASER" CursorProximity 1
xinput float "$ERASER"
echo "Done setting tablet settings..."
