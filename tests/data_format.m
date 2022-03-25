

% each input event
% x and y in px relative to origin
% we expect ~200 events/sec, so preallocate for some ludicrous amount
% and subset when copying into "real" data
tic;
MAX_INPUT_EVENTS_FRAME = 10;

% for i = MAX_INPUT_EVENTS_FRAME:-1:1
%     input_evts(i) = struct('time', 0, 'x', 0, 'y', 0);
% end
z = zeros(MAX_INPUT_EVENTS_FRAME, 1);
input_evts = struct('time', z, ...
                    'x', z, ...
                    'y', z);

% each frame
MAX_FRAMES_PER_TRIAL = 240 * 20; % 20 seconds

% for i = MAX_FRAMES_PER_TRIAL:-1:1
%     frames(i) = struct('frame_count', 0, 'vbl_time', 0, 'disp_time', 0, 'start_state', 0, 'end_state', 0, ...
%                        'input_events', input_evts, 'missed_frame_deadline', 0);
% end
z = zeros(MAX_FRAMES_PER_TRIAL, 1);
frames = struct('frame_count', z, ...
                'vbl_time', z, ...
                'disp_time', z, ...
                'start_state', z, ...
                'end_state', z, ...
                'missed_frame_deadline', z);
frames.input_events(1:MAX_FRAMES_PER_TRIAL) = input_evts;

% each trial has an array of str

MAX_TRIALS = 100; % set based on trial table size
% for i = MAX_TRIALS:-1:1
%     trials(i) = struct('target', struct('x', 0, 'y', 0), 'delay', 0, 'manipulation_angle', 0, ...
%                        'frames', frames);
% end
z = zeros(MAX_TRIALS, 1);
trials = struct('delay', z, ...
                'manipulation_angle', z);
trials.target(1:MAX_TRIALS) = struct('x', 0, 'y', 0);
trials.frames(1:MAX_TRIALS) = frames;

block_level = struct();
block_level.id = 0;
block_level.git_hash = 0;
block_level.exp_info = '';
block_level.cursor_size = 0;
block_level.center_size = 0;
block_level.target_size = 0;
block_level.target_distance = 0;
block_level.rot_or_clamp = '';

block_data = struct('block', block_level, 'trials', trials);
toc;

bytes_to_mb = @ (x) (x * 0.00000095367432);
mb = bytes_to_mb(sizeof(block_data));
disp(mb);

% example of whittling down the data on-the-fly
% block_data.trials(5).frames = block_data.trials(5).frames(1:100);

% try json.gz (11.8 sec, 736 KB with mex files)
tic;
%to_json('foo.json', block_data, 1);
boo = json_encode(block_data);
fid = fopen('foo.json', 'w');
fputs(fid, boo);
fclose(fid);
% opts = struct('FloatFormat', '%.6g', 'ArrayIndent', 0, 'NestArray', 1);
% savejson('', block_data, 'foo.json', opts);
toc;

%try octave-rapidjson (generated significantly larger files, not sure what was going on?)
tic;
bar = save_json(block_data);
fid = fopen('bar.json', 'w');
fputs(fid, bar);
fclose(fid);
toc;
% try mat (22.9 sec, 5.4MB)
tic;
save("-mat7-binary", "-z", "foo.mat", "-struct", "block_data");
toc;
