# VMR delays

To run, type either `./vmr.m` (if file has executable permissions) or `octave vmr.m`.

## Notes

https://psychtoolbox.discourse.group/t/120-240-hz-lcd-display-for-neurophysiology/3525/6 for some other experiences with consumer high-refresh-rate monitors

https://psychtoolbox.discourse.group/t/wacom-tablet-valuators/3393/5

https://softsolder.com/2020/01/14/huion-h610pro-v2-tablet-vs-xsetwacom/

https://bugs.launchpad.net/ubuntu/+source/mutter/+bug/1900908

https://digimend.github.io/support/howto/drivers/evdev/

Asus says doing ELMB @ 120Hz should show 120 images/sec interleaved with black frames, so we should
consider turning that on?
https://blurbusters.com/faq/advanced-strobe-crosstalk-faq
https://forums.blurbusters.com/viewtopic.php?f=23&t=8235&start=10

json_encode/decode are from https://gitlab.com/leastrobino/matlab-json
The ones from the io pkg are very slow (like an order of magnitude worse than saving a mat file)
These are 2x faster than saving a mat file, and can be significantly smaller too (after gzipping)

We can have the game state machine be a class, which has an update method that takes the vbl/presentation time,
the latest input array, frame count, ...
It would need to handle drawing too?


Remember to select the right XConf*

Wacom device info with `lsusb -d 056a:0358 -v`

We need to fiddle with `xsetwacom` to put the tablet in the right spot,

https://wiki.archlinux.org/title/wacom_tablet#Adjusting_aspect_ratios