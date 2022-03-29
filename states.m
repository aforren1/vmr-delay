classdef states
    properties(Constant)
        % No "real" enums in Octave yet, so fake it
        % do we want strings or numbers?
        END = 0
        RETURN_TO_CENTER = 1 % veridical feedback after 2 sec
        REACH = 2 % target appears, move!
        DIST_EXCEEDED = 3 % passed target distance, hide cursor and show endpoint feedback (at lag?)
        BAD_MOVEMENT = 4
        FEEDBACK = 5
    end
end
