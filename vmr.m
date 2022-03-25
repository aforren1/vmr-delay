#!/usr/bin/env -S octave --no-gui
# (set as executable via "chmod +x vmr.m")
args = argv();
if length(args) > 0
    _vmr_setup(true);
else
    _vmr_setup(false);
end
