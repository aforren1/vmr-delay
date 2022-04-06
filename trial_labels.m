classdef trial_labels
    properties(Constant)
        % No "real" enums in Octave yet, so fake it
        PRACTICE = 0 % veridical feedback
        PRACTICE_CLAMP = 1 % 0 clamp (move wherever)
        BASELINE_1 = 2 % no feedback
        BASELINE_2 = 3 % 0 clamp
        PERTURBATION = 4 % 7.5 clamp
        WASHOUT = 5 % no feedback
    end
end
