%{
TODO: how should groups be assigned? Just alternate

Between-subjects design

all physical units in mm/deg/sec

group 1: single delay of 300ms
group 2: [100 200 300 400 500]ms delays

5 targets (-60, -30, 0, 30, 60) (0 = top of screen)
+/- 7.5 deg clamp


# practice
2 repeats to each target (10 trials)
online feedback

# practice clamp
2 repeats to each target (10 trials)
online feedback, 0 deg clamp
# real deal

No breaks

1. baseline 1
  - 50 trials total (so 10 reps per target)
  - No feedback
2. baseline 2
  - 50 trials total (10 reps per target)
  - 0 deg clamp
  - online feedback
3. Clamp
  - 300 trials total (60 reps per target)
  - clamp applied
  - online feedback
4. Washout
  - 50 trials total (10 reps per target)
  - no feedback

%}

function tgt = make_tgt(id, group, block_type, is_debug, is_short)

exp_version = 'v1'
desc = {
    exp_version
    'two groups'
    'group 1 has fixed 300ms delay (+ 200ms extra time between trials to match average ITI with group 2)'
    'group 2 has 100-500ms delay (with no additional time)'
    'clamp=+/- 7.5 during manip phase'
    '5 targets (-60, -30, 0, 30, 60) (0 = top of screen)'
    'two practice blocks. Veridical feedback & 0 deg clamp'
    'for manipulation,'
    'baseline 1: no feedback'
    'baseline 2: 0 deg clamp, online feedback'
    'clamp: clamp applied, online feedback'
    'washout: no feedback'
};

disp('Generating tgt, this may take ~ 30 seconds...');
GREEN = [0 255 0];
RED = [255 0 0];
WHITE = [255 255 255];
BLACK = [0 0 0];
GRAY30 = [77 77 77];
GRAY50 = [127 127 127];
GRAY70 = [179 179 179];
ONLINE_FEEDBACK = true;
ENDPOINT_FEEDBACK = false;
% number of "cycles" (all targets seen once)
if is_debug || is_short
    N_PRACTICE_REPS = 1;
    N_BASELINE1_REPS = 1;
    N_BASELINE2_REPS = 1;
    N_MANIP_TRIALS = 25; % kept separated out b/c we want to evenly distribute delay values too
    N_WASHOUT_REPS = 1;
else
    N_PRACTICE_REPS = 2;
    N_BASELINE1_REPS = 10;
    N_BASELINE2_REPS = 10;
    N_MANIP_TRIALS = 300; % kept separated out b/c we want to evenly distribute delay values too
    N_WASHOUT_REPS = 10;
end

ABS_MANIP_ANGLE = 7.5;

seed = str2num(sprintf('%d,', id)); % seed using participant's id
% NB!! This is Octave-specific. MATLAB should use rng(), otherwise it defaults to an old RNG impl (see e.g. http://walkingrandomly.com/?p=2945)
rand('state', seed);

signs = [-1 1];
sign = signs(randi(2));
target_angles = [-60 -30 0 30 60] + 270; % should be centered at top of screen
delay_g1 = [0.5 0.5 0.5 0.5 0.5];
delay_g2 = [0.1 0.2 0.3 0.4 0.5]; % make sure these are evenly distributed
% so we'll represent each delay once per cycle
% then each target+delay combo is a total of 5*5=25 combinations (12 reps)

block_level = struct();
% sizes taken from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5505262/
% but honestly not picky
block_level.cursor = struct('size', 4, 'color', WHITE); % mm, white cursor
block_level.center = struct('size', 12, 'color', WHITE, 'offset', struct('x', 0, 'y', 80));
block_level.target = struct('size', 16, 'color', GREEN, 'distance', 80);
block_level.rot_or_clamp = 'clamp';
block_level.feedback_duration = 0.5; % 500 ms
block_level.max_mt = 0.3; % maximum movement time before warning
block_level.max_rt = 2; % max reaction time before warning
block_level.exp_info = sprintf('%s\n', desc{:});
block_level.block_type = block_type;
block_level.manipulation_angle = sign * ABS_MANIP_ANGLE;
block_level.group = group;
block_level.seed = seed;
block_level.exp_version = exp_version;

if group == 1
    check_delays = false;
    delay = delay_g1;
    extra_delay = 0;
elseif group == 2
    check_delays = false; % TODO: checking both is apparently computationally prohibitive?
    delay = delay_g2;
    extra_delay = 0.2;
else
    error('Neither the Blue Angels nor Group 2.');
end

block_level.delays = delay;
block_level.extra_delay = extra_delay;

if strcmp(block_type, "p")
    c = 1;
    for i = 1:N_PRACTICE_REPS
        tmp_angles = shuffle(target_angles);
        for j = tmp_angles
            trial_level(c).target.x = block_level.target.distance * cosd(j);
            trial_level(c).target.y = block_level.target.distance * sind(j);
            trial_level(c).delay = 0;
            trial_level(c).is_manipulated = false;
            trial_level(c).manipulation_angle = 0;
            trial_level(c).manipulation_type = manip_labels.NONE;
            trial_level(c).online_feedback = true;
            trial_level(c).endpoint_feedback = false;
            trial_level(c).label = trial_labels.PRACTICE;
            c = c + 1;
        end
    end

    tgt = struct('block', block_level, 'trial', trial_level);
    return;
    
end

if strcmp(block_type, "c")
    c = 1;
    for i = 1:N_PRACTICE_REPS
        tmp_angles = shuffle(target_angles);
        for j = tmp_angles
            trial_level(c).target.x = block_level.target.distance * cosd(j);
            trial_level(c).target.y = block_level.target.distance * sind(j);
            trial_level(c).delay = 0;
            trial_level(c).is_manipulated = true;
            trial_level(c).manipulation_angle = 0;
            trial_level(c).manipulation_type = manip_labels.CLAMP;
            trial_level(c).online_feedback = true;
            trial_level(c).endpoint_feedback = false;
            trial_level(c).label = trial_labels.PRACTICE_CLAMP;
            c = c + 1;
        end
    end

    tgt = struct('block', block_level, 'trial', trial_level);
    return;
end


combos = pairs(target_angles, delay);

angle_delay = []; % lazy, we're just going to append the array
megablock_size = size(combos);
for i = 1:(N_MANIP_TRIALS/megablock_size(1))
    failed = true;
    while true
        % generate proposal
        combos = shuffle_2d(combos);
        % first, check each target once per cycle
        lta = length(target_angles);
        lde = length(delay);
        for cycle = 0:(lta-1)
            offset = cycle * lta + 1;
            % check angles first
            if ~is_unique(combos(offset:(offset+lta-1), 1))
                failed = true;
                break;
            end
            % (optionally) check delays
            if check_delays && ~is_unique(combos(offset:(offset+lta-1), 2))
                failed = true;
                break;
            end

            % success!
            failed = false;
        end

        if failed
            continue % we've failed
        end
        break; % success
    end
    angle_delay = [angle_delay; combos];
end

c = 1; % overall counter
% generate baseline 1
for i = 1:N_BASELINE1_REPS
    tmp_angles = shuffle(target_angles);
    for j = tmp_angles
        trial_level(c).target.x = block_level.target.distance * cosd(j);
        trial_level(c).target.y = block_level.target.distance * sind(j);
        trial_level(c).delay = 0;
        trial_level(c).is_manipulated = false;
        trial_level(c).manipulation_angle = 0;
        trial_level(c).manipulation_type = manip_labels.NONE;
        trial_level(c).online_feedback = false;
        trial_level(c).endpoint_feedback = false;
        trial_level(c).label = trial_labels.BASELINE_1;
        c = c + 1;
    end
end

% baseline 2
for i = 1:N_BASELINE2_REPS
    tmp_angles = shuffle(target_angles);
    for j = tmp_angles
        trial_level(c).target.x = block_level.target.distance * cosd(j);
        trial_level(c).target.y = block_level.target.distance * sind(j);
        trial_level(c).delay = 0;
        trial_level(c).is_manipulated = true;
        trial_level(c).manipulation_angle = 0;
        trial_level(c).manipulation_type = manip_labels.CLAMP;
        trial_level(c).online_feedback = true;
        trial_level(c).endpoint_feedback = false;
        trial_level(c).label = trial_labels.BASELINE_2;
        c = c + 1;
    end
end


% angle_delay now has our trial order
for i = 1:length(angle_delay)
    ad = angle_delay(i, :);
    trial_level(c).target.x = block_level.target.distance * cosd(ad(1));
    trial_level(c).target.y = block_level.target.distance * sind(ad(1));
    trial_level(c).delay = ad(2);
    trial_level(c).is_manipulated = true;
    trial_level(c).manipulation_angle = sign * ABS_MANIP_ANGLE;
    trial_level(c).manipulation_type = manip_labels.CLAMP;
    trial_level(c).online_feedback = true;
    trial_level(c).endpoint_feedback = false;
    trial_level(c).label = trial_labels.PERTURBATION;
    c = c + 1;
end

% washout (equivalent to baseline 1)
for i = 1:N_WASHOUT_REPS
    tmp_angles = shuffle(target_angles);
    for j = tmp_angles
        trial_level(c).target.x = block_level.target.distance * cosd(j);
        trial_level(c).target.y = block_level.target.distance * sind(j);
        trial_level(c).delay = 0;
        trial_level(c).is_manipulated = false;
        trial_level(c).manipulation_angle = 0;
        trial_level(c).manipulation_type = manip_labels.NONE;
        trial_level(c).online_feedback = false;
        trial_level(c).endpoint_feedback = false;
        trial_level(c).label = trial_labels.WASHOUT;
        c = c + 1;
    end
end

tgt = struct('block', block_level, 'trial', trial_level);
disp('Done generating tgt, thanks for waiting!');

end % end function

function arr = shuffle(arr)
    arr = arr(randperm(length(arr)));
end

function arr = shuffle_2d(arr)
    arr = arr(randperm(size(arr, 1)), :);
end

function out = pairs(a1, a2)
    [p, q] = meshgrid(a1, a2);
    out = [p(:) q(:)];
end

function out = is_unique(arr)
    out = length(arr) == length(unique(arr));
end
