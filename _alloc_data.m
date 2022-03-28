
% prellocate data
% magic constants (IN_CAPS) are guesstimates
% and should be more than enough for this specific task,
% but may not work for other experiments
% we went with struct-of-arrays instead of array-of-structs
% for allocation/serialization speed, even though array-of-structs
% is more intuitive for indexing, e.g.
% data.trials(3).frames(2).input_events(5).t is more natural to me than
% data.trials.frames(3).input_events(2).t(5)

% but ¯\_(ツ)_/¯

function data = _alloc_data(n_trials)
    MAX_INPUT_EVENTS_FRAME = 10;
    z =  zeros(MAX_INPUT_EVENTS_FRAME, 1);
    input_evts = struct('t', z, ...
                        'x', z, ...
                        'y', z);
    
    % each frame
    MAX_FRAMES_PER_TRIAL = 240 * 30; % 30 seconds
    z = zeros(MAX_FRAMES_PER_TRIAL, 1);
    frames = struct('frame_count', z, ...
                    'vbl_time', z, ...
                    'disp_time', z, ...
                    'start_state', z, ...
                    'end_state', z, ...
                    'cursor', struct('x', z, 'y', z, 'vis', z), ... % transformed position ("raw" position in `input_events`)
                    'target', struct('x', z, 'y', z, 'vis', z), ...
                    'missed_frame_deadline', z);
    frames.input_events(1:MAX_FRAMES_PER_TRIAL) = input_evts;
    
    MAX_TRIALS = n_trials; % set based on trial table size

    % NB: This is where non-boilerplate (for reaching tasks) data starts
    % For better(?) performance, preallocate in sync with gen_tgt
    z = zeros(MAX_TRIALS, 1);
    trials = struct('delay', z, ...
                    'is_manipulated', z, ...
                    'manipulation_angle', z, ...
                    'is_endpoint', z, ...
                    'was_restarted', z);
    trials.target(1:MAX_TRIALS) = struct('x', 0, 'y', 0);
    trials.frames(1:MAX_TRIALS) = frames;
    
    block_level = struct();
    % we don't fuss with block level, because it's not big
    % and then we have less to keep track of when updating
    
    data = struct('block', block_level, 'trials', trials);
end