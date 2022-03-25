

% keeping the notes below, but we're starting with endpoint feedback only and clamp,
% so should be trivial to instantiate lag just with timekeeping

% given a struct-of-arrays of (x, y, t), compute the position
% N milliseconds in the past

%{
ideas:
 - pick nearest observation to requested time (wrong and would look weird)
 - lerp position (assumes constant velocity?)
 - lerp velocity (assumes constant accel?)/(are errors worse?)
 - 
%}

function new_pos = calc_lag_pos(new_poses, n_ms_back)


end