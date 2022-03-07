# see https://linux.die.net/man/1/xsetwacom for details
# should be Option "Area" "0 0 62200 43200"
xsetwacom --set "Wacom Intuos Pro L Pen stylus" ResetArea
# no suppression
xsetwacom --set "Wacom Intuos Pro L Pen stylus" Suppress 0
# no sliding window
xsetwacom --set "Wacom Intuos Pro L Pen stylus" RawSample 1
# TODO: MapToOutput, which will be an offset relative to the operator monitor
xsetwacom --set "Wacom Intuos Pro L Pen stylus" MapToOutput 1920x1080+2560+0