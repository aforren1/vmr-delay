# see https://linux.die.net/man/1/xsetwacom for details
# should be Option "Area" "0 0 62200 43200"
xsetwacom --set "Wacom Intuos Pro L Pen stylus" ResetArea
# no suppression
xsetwacom --set "Wacom Intuos Pro L Pen stylus" Suppress 0
# no sliding window
xsetwacom --set "Wacom Intuos Pro L Pen stylus" RawSample 1
# don't use pressure, so ??
xsetwacom --set "Wacom Intuos Pro L Pen stylus" PressureRecalibration off
# TODO: MapToOutput, which will be an offset relative to the operator monitor
# or can we just hide the cursor and draw the circle in the proper spot?

# physical active area is 311 x 216 mm
# resolution is 5080 lines/inch (200 lines/mm)

# xsetwacom --set "Wacom Intuos Pro L Pen stylus" MapToOutput 1920x1080+2560+0
# xsetwacom --get "Wacom Intuos Pro L Pen stylus" all