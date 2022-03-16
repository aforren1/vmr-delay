% TODO: this is mostly filler; replace when we have a proper idea

% script to generate .tgt.json files
%
% assume one block per .tgt.json file
% task-level settings (e.g. origin, target locations/ids, rotation/clamp, target sizes, cursor size)
% trial-level settings (target id, rotation/clamp angle, delay, ...)
% when in doubt, use trial-level settings
% all physical units in mm/deg/ms

N_TRIALS = 10;
filename = 'test.tgt.json';
filepath = fileparts(mfilename('fullpath')); % path to this script (where we also save the tgt.json files)
filename = fullfile(filepath, filename);

block_level = struct();
% sizes taken from https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5505262/
% but honestly not picky
block_level.cursor_size = 4; % mm
block_level.center_size = 12;
block_level.target_size = 16;
block_level.target_distance = 80;
block_level.target_angles = linspace(0, 360 - 45, 8);

for i = 1:N_TRIALS
    trial_level(i).target_index = randi([1, 8]);
    trial_level(i).delay = 500; % milliseconds; these are mapped into # of frames, so be aware of divisibility
end

exp_data = struct('block_level', block_level, 'trial_level', trial_level);

if IsOctave()
    pkg load io
    txt = toJSON(exp_data);
else
    error('Serialization not implemented for MATLAB.');
    % probably txt = jsonencode(cache); ?
end

fid = fopen(filename, 'w');
fputs(fid, txt);
fclose(fid);
