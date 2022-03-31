#!/usr/bin/env -S octave --no-gui
# (set as executable via "chmod +x vmr.m")
args = argv();
if length(args) > 0
    arg2 = [args{:, 1}];
    is_debug = ~isempty(strfind(arg2, 'd'));
    is_short = ~isempty(strfind(arg2, 's'));
    disp(sprintf('debug: %i, short: %i', is_debug, is_short));
    _vmr_setup(is_debug, is_short);
else
    _vmr_setup(false, false);
end
