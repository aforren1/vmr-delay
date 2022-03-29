% TODO: this is mostly filler; replace when we have a proper idea

% script to generate .tgt.json files
%
% assume one block per .tgt.json file
% task-level settings (e.g. origin, target locations/ids, rotation/clamp, target sizes, cursor size)
% trial-level settings (target id, rotation/clamp angle, delay, ...)
% when in doubt, use trial-level settings
% all physical units in mm/deg/sec
GREEN = [0 255 0];
RED = [255 0 0];
WHITE = [255 255 255];
BLACK = [0 0 0];
GRAY30 = [77 77 77];
GRAY50 = [127 127 127];
GRAY70 = [179 179 179];
N_TRIALS = 10;
filename = 'test.tgt.json';
filepath = fileparts(mfilename('fullpath')); % path to this script (where we also save the tgt.json files)
filename = fullfile(filepath, filename);

block_level = struct();
% sizes taken from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5505262/
% but honestly not picky
block_level.cursor = struct('size', 4, 'color', WHITE); % mm, white cursor
block_level.center = struct('size', 12, 'color', WHITE);
block_level.target = struct('size', 16, 'color', GREEN, 'distance', 80);
block_level.rot_or_clamp = 'clamp';
block_level.feedback_duration = 0.5; % 500 ms
block_level.max_mt = 0.3; % maximum movement time before warning
block_level.max_rt = 2; % max reaction time before warning
block_level.exp_info = 'Experiment info here (version, dates, text description...)'; % TODO: fill

target_angles = linspace(0, 360 - 45, 4);
manip_angles = [zeros(5, 1); (30 * ones(3, 1)); zeros(2, 1)];
is_manip = [zeros(5, 1); ones(3, 1); zeros(2, 1)];
delays = [0, 500];
is_endpoints = [zeros(3, 1); ones(7, 1)];

for i = 1:N_TRIALS
    ang = target_angles(randi([1, 4]));
    % keep in mind, these are in mm
    trial_level(i).target.x = block_level.target.distance * cosd(ang);
    trial_level(i).target.y = block_level.target.distance * sind(ang);
    trial_level(i).delay = 0.5; % 500 milliseconds; these are mapped into # of frames, so be aware of divisibility
    trial_level(i).is_manipulated = is_manip(i);
    trial_level(i).manipulation_angle = manip_angles(i);
    trial_level(i).is_endpoint = is_endpoints(i);
end

exp_data = struct('block', block_level, 'trial', trial_level);

if IsOctave()
    pkg load io
    txt = toJSON(exp_data);
else
    error('Serialization not implemented for MATLAB.');
    % probably txt = jsonencode(exp_data); ?
end

fid = fopen(filename, 'w');
fputs(fid, txt);
fclose(fid);
