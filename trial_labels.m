classdef trial_labels
    properties(Constant)
        % No "real" enums in Octave yet, so fake it
        PRACTICE = 0
        BASELINE_1 = 1 % veridical feedback after 2 sec
        BASELINE_2 = 2 % target appears, move!
        PERTURBATION = 3 % passed target distance, hide cursor and show endpoint feedback (at lag?)
        WASHOUT = 4
    end
end
