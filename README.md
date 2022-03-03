VMR delays

Remember to select the right XConf*

endpoint and/or online feedback

Demo with mouse, real thing with tablet
Use KbQueue* for timing

Single draw to FillOval for all targets + "mouse", use `CenterRectOnPoint` to center and keep track of x/y/w/h in objects

Wacom device info with `lsusb -d 056a:0358 -v`

# data format

## "raw" data
1 row per frame (because we might go faster than input events come in) (what if target changes state, but we don't have mouse data for that time?)
array of structs for input events that frame (time, "raw" position)
trial counter
trial state

## "easy" data



data directory layout

data/
  subject/
    session1/
    session2/
    ...


Use `cvt 1920 1080 240 -r` to get modeline settings to update the xorg.conf (check xrandr for exact refresh rate/dims)
don't flip in xrandr, let PTB do it?

e.g.

```
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'UseDisplayRotation', 180);
[theWindow,theRect] = PsychImaging('OpenWindow', whichScreen, 0);
```