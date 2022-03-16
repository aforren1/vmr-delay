VMR delays

Remember to select the right XConf*

endpoint and/or online feedback

Demo with mouse, real thing with tablet
Use KbQueue* for timing

Single draw to FillOval for all targets + "mouse", use `CenterRectOnPoint` to center and keep track of x/y/w/h in objects

Wacom device info with `lsusb -d 056a:0358 -v`

# data format

Right now, I'm thinking of doing one `.json.gz` per subject (and people are only coming in once?).

## "raw" data
1 row per frame (because we might go faster than input events come in) (what if target changes state, but we don't have mouse data for that time?)
array of structs for input events that frame (time, "raw" position)
trial counter
trial state

## "easy" data

...


## data directory layout

data/
  subject/
    session1/
    session2/
    ...


Use `cvt -r 1920 1080 240` to get modeline settings to update the xorg.conf (check xrandr for exact refresh rate/dims)
don't flip in xrandr, let PTB do it?

e.g.

```
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'UseDisplayRotation', 180);
[theWindow,theRect] = PsychImaging('OpenWindow', whichScreen, 0);
```

We need to fiddle with `xsetwacom` to put the tablet in the right spot,

https://wiki.archlinux.org/title/wacom_tablet#Adjusting_aspect_ratios

## Notes

https://psychtoolbox.discourse.group/t/120-240-hz-lcd-display-for-neurophysiology/3525/6 for some other experiences with consumer high-refresh-rate monitors

https://psychtoolbox.discourse.group/t/wacom-tablet-valuators/3393/5

https://softsolder.com/2020/01/14/huion-h610pro-v2-tablet-vs-xsetwacom/

https://bugs.launchpad.net/ubuntu/+source/mutter/+bug/1900908

https://digimend.github.io/support/howto/drivers/evdev/

Asus says doing ELMB @ 120Hz should show 120 images/sec interleaved with black frames, so we should
consider turning that on?
https://blurbusters.com/faq/advanced-strobe-crosstalk-faq
