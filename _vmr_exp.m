% the "real" part of the experiment
function _vmr_exp(is_debug, is_short, block_type, settings)
    % profile on;
    start_unix = floor(time());
    start_dt = datestr(clock(), 31); %Y-M-D H:M:S
    % constants
    X_PITCH = 0.2832; % pixel pitch, specific to "real" monitor
    Y_PITCH = 0.2802; % note the non-squareness (though for sizes/distances < ~45mm)
    unit = Unitizer(X_PITCH, Y_PITCH);

    tgt = make_tgt(settings.id, settings.group, settings.sign, block_type, is_debug, is_short);
    % allocate data before running anything
    data = _alloc_data(length(tgt.trial));

    % turn off splash
    KbName('UnifyKeyNames');
    ESC = KbName('ESCAPE');
    Screen('Preference', 'VisualDebugLevel', 3);
    screens = Screen('Screens');
    max_scr = max(screens);

    w = struct(); % container for window-related things

    if is_debug % tiny window, skip all the warnings
        Screen('Preference', 'SkipSyncTests', 2); 
        Screen('Preference', 'VisualDebugLevel', 0);
        [w.w, w.rect] = Screen('OpenWindow', max_scr, 50, [0, 0, 800, 800], [], [], [], []);
    else
        % real deal, make sure sync tests work
        % for the display (which is rotated 180 deg), we need
        % to do this. Can't use OS rotation, otherwise PTB gets mad
        PsychImaging('PrepareConfiguration');
        PsychImaging('AddTask', 'General', 'UseDisplayRotation', 180);
        [w.w, w.rect] = PsychImaging('OpenWindow', max_scr, 0);
    end
    %Screen('BlendFunction', w.w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    [w.center(1), w.center(2)] = RectCenter(w.rect);
    % assume color is 8 bit, so don't fuss with WhiteIndex/BlackIndex
    Screen('BlendFunction', w.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    Screen('TextSize', w.w, floor(0.03 * w.rect(4)));
    Screen('Flip', w.w); % flip once to warm up
    KbCheck(-1); % force mex load

    w.fps = Screen('FrameRate', w.w);
    w.ifi = Screen('GetFlipInterval', w.w);
    Priority(MaxPriority(w.w));
    % X11 apparently gets it really wrong with extended screen, but even gets height wrong??
    % actually gets it wrong with single screen too, so...
    % randr seems to nail it though
    % and for this round, we've just gotten the size from the manual (see *_PITCH above)
    % [w.disp.width, w.disp.height] = Screen('DisplaySize', max_scr);

    sm = StateMachine(settings.base_path, tgt, w, unit);

    dev = _find_device(); % get the pen (or mouse, if testing)
    % hide the cursor
    % more for the sake of the operator mouse rather than tablet, which is probably
    % floating at this point
    if ~is_debug
        HideCursor(w.w);
    end

    % alloc temporary data for input events
    evts(1:20) = struct('t', 0, 'x', 0, 'y', 0);

    ListenChar(-1); % disable keys landing in console
    KbQueueCreate(dev.index, [], 2);
    KbQueueStart(dev.index);

    % flip once more to get a reference time
    % we're assuming linux computers with OpenML support
    % vbl_time helps with scheduling flips, and ref_time helps with relating
    % to input events (b/c it *should* be when the stimulus changes on the screen)
    [vbl_time, disp_time] = Screen('Flip', w.w);
    ref_time = disp_time;
    was_restarted = false;

    frame_count = 1;
    KbQueueFlush(dev.index, 2); % only flush KbEventGet
    [trial_count, within_trial_frame_count] = sm.get_counters();

    while (beginning_state = sm.get_state())
        % break if esc pressed
        [~, ~, keys] = KbCheck(-1); % query all keyboards
        if keys(ESC)
            error('Escape was pressed.');
        end

        % pause, and restart trial when unpaused
        % if they just started the trial, this will re-pause if they delayed more than
        % 20 seconds. I'll fix it eventually, but doesn't really impact things (just jam the "C" key until caught up)
        if (vbl_time - sm.trial_start_time) > 10
            was_restarted = true;
            warning(sprintf('Paused on trial %i', trial_count));
            DrawFormattedText(w.w, 'Paused, press "C" to restart trial', 'center', 'center', 255);
            Screen('Flip', w.w);
            C = KbName('C');
            while true
                [~, keys, ~] = KbWait(-1, 2);
                if keys(C)
                    % restart the trial
                    sm.restart_trial();
                    KbQueueFlush(dev.index, 2);
                    break
                end

                if keys(ESC)
                    error('Escape was pressed.');
                end
            end
            continue % restart this frame
        end

        % sleep part of the frame to reduce lag
        % TODO: tweak this if we end up doing the 120hz + strobing
        % we probably only need 1-2ms to do state updates
        % for 240hz, this cuts off up to 2ms or so?
        WaitSecs('UntilTime', vbl_time + 0.5 * w.ifi);
        t0 = GetSecs();
        % process all pending input events
        % check number of pending events once, which should be robust
        % to higher-frequency devices
        n_evts = KbEventAvail(dev.index);
        % TODO: does MATLAB do non-copy slices?? This sucks
        % is it faster to make this each frame, or to copy from some preallocated chunk?
        % won't execute if event queue is empty
        for i = 1:n_evts
            % events are in the same coordinates as psychtoolbox (px)
            % eventually, we would figure out mapping so that we get to use
            % the full range of valuators, but I haven't been able to get
            % it right yet. So for now, we're stuck with slightly truncated resolution
            % (but still probably plenty)
            [evt, ~] = PsychHID('KbQueueGetEvent', dev.index, 0);
            evts(i).t = evt.Time;
            evts(i).x = evt.X;
            evts(i).y = evt.Y;
        end

        % when we increment a trial, we can reset within_trial_frame_count to 1
        % for the state machine, implement fallthrough by consecutive `if ...`
        % grab counters before they're updated for this frame
        [trial_count, within_trial_frame_count] = sm.get_counters();
        if n_evts < 1
            sm.update([], vbl_time);
        else
            % pass all input events so we can get a decent RT if need be
            sm.update(evts(1:n_evts), vbl_time);
        end
        sm.draw(); % instantiate visuals
        t1 = GetSecs();
        Screen('DrawingFinished', w.w);
        % do other work in our free time
        center = sm.get_raw_center_state(); % still in px
        for i = 1:n_evts % skips if n_evts == 0
            data.trials.frames(trial_count).input_events(within_trial_frame_count).t(i) = evts(i).t;
            data.trials.frames(trial_count).input_events(within_trial_frame_count).x(i) = unit.x_px2mm(evts(i).x - center.x);
            data.trials.frames(trial_count).input_events(within_trial_frame_count).y(i) = unit.y_px2mm(evts(i).y - center.y);
            % TODO: should we store (redundant) position in physical units, or leave for post-processing?
        end
        ending_state = sm.get_state();
        % take subset to reduce storage size (& because anything else is junk)
        % again, I *really* wish I could just take an equivalent to a numpy view...
        data.trials.frames(trial_count).input_events(within_trial_frame_count).t = data.trials.frames(trial_count).input_events(within_trial_frame_count).t(1:n_evts);
        data.trials.frames(trial_count).input_events(within_trial_frame_count).x = data.trials.frames(trial_count).input_events(within_trial_frame_count).x(1:n_evts);
        data.trials.frames(trial_count).input_events(within_trial_frame_count).y = data.trials.frames(trial_count).input_events(within_trial_frame_count).y(1:n_evts);

        % swap buffers
        % use vbl_time to schedule subsequent flips, and disp_time for actual
        % stimulus onset time
        [vbl_time, disp_time, ~, missed, ~] = Screen('Flip', w.w, vbl_time + 0.95 * w.ifi);
        % done the frame, we'll write frame data now?
        data.trials.frames(trial_count).frame_count(within_trial_frame_count) = frame_count;
        data.trials.frames(trial_count).vbl_time(within_trial_frame_count) = vbl_time;
        data.trials.frames(trial_count).disp_time(within_trial_frame_count) = disp_time;
        data.trials.frames(trial_count).missed_frame_deadline(within_trial_frame_count) = missed >= 0;
        data.trials.frames(trial_count).start_state(within_trial_frame_count) = beginning_state;
        data.trials.frames(trial_count).end_state(within_trial_frame_count) = ending_state;
        data.trials.frames(trial_count).frame_comp_dur(within_trial_frame_count) = t1 - t0;
        % these are in mm and relative to center point
        data.trials.frames(trial_count).cursor(within_trial_frame_count) = sm.get_cursor_state();
        data.trials.frames(trial_count).target(within_trial_frame_count) = sm.get_target_state();
        data.trials.frames(trial_count).ep_feedback(within_trial_frame_count) = sm.get_ep_state();


        if sm.will_be_new_trial()
            % prune our giant dataset, this is the last frame of the trial
            % TODO: should we let saving trial-level data be handled by the state machine,
            % or let it leak here?
            % we don't need to keep in sync if we use dynamic names:
            for fn = fieldnames(tgt.trial(trial_count))'
                data.trials.(fn{1})(trial_count) = tgt.trial(trial_count).(fn{1});
            end
            data.trials.was_restarted(trial_count) = was_restarted;
            data.trials.too_slow(trial_count) = sm.was_too_slow();
            was_restarted = false;
            % alternatively, we just save these without context
            for fn = fieldnames(data.trials.frames(trial_count))'
                data.trials.frames(trial_count).(fn{1}) = data.trials.frames(trial_count).(fn{1})(1:within_trial_frame_count);
            end
        end

        frame_count = frame_count + 1; % grows forever/applies across entire experiment
    end

    KbQueueStop(dev.index);
    KbQueueRelease(dev.index);
    DrawFormattedText(w.w, 'Finished, saving data...', 'center', 'center', 255);
    last_flip_time = Screen('Flip', w.w);

    % write data
    data.block.id = settings.id;
    data.block.is_debug = is_debug;
    [status, data.block.git_hash] = system("git log --pretty=format:'%H' -1 2>/dev/null");
    if status
        warning('git hash failed, is git installed?');
    end
    [status, data.block.git_branch] = system("git rev-parse --abbrev-ref HEAD | tr -d '\n' 2>/dev/null");
    if status
        warning('git branch failed, is git installed?');
    end
    [status, data.block.git_tag] = system("git describe --tags | tr -d '\n' 2>/dev/null");
    if status
        warning('git tag failed, has a release been tagged?');
    end
    data.block.sysinfo = uname();
    data.block.oct_ver = version();
    [~, data.block.ptb_ver] = PsychtoolboxVersion();
    info = Screen('GetWindowInfo', w.w); % grab renderer info before cleaning up
    data.block.gpu_vendor = info.GLVendor;
    data.block.gpu_renderer = info.GLRenderer;
    data.block.gl_version = info.GLVersion;
    data.block.missed_deadlines = info.MissedDeadlines;
    data.block.n_flips = info.FlipCount;
    data.block.pixel_pitch = [X_PITCH Y_PITCH];
    data.block.start_unix = start_unix; % whole seconds since unix epoch
    data.block.start_dt = start_dt;
    % mapping from numbers to strings for state
    % these should be in order, so indexing directly (after +1, depending on lang) with `start_state`/`end_state` should work (I hope)
    warning('off', 'Octave:classdef-to-struct');
    fnames = fieldnames(states);
    lfn = length(fnames);
    fout = cell(lfn, 1);
    for i = 1:lfn
        name = fnames{i};
        fout{states.(name)+1} = name;
    end
    data.block.state_names = fout;

    % same with trial labels
    fnames = fieldnames(trial_labels);
    lfn = length(fnames);
    fout = cell(lfn, 1);
    for i = 1:lfn
        name = fnames{i};
        fout{trial_labels.(name)+1} = name;
    end
    data.block.trial_labels = fout;

    % same with manipulation labels (should have done cell arrays instead??)
    fnames = fieldnames(manip_labels);
    lfn = length(fnames);
    fout = cell(lfn, 1);
    for i = 1:lfn
        name = fnames{i};
        fout{manip_labels.(name)+1} = name;
    end
    data.block.manip_labels = fout;
    
    % copy common things over
    for fn = fieldnames(tgt.block)'
        data.block.(fn{1}) = tgt.block.(fn{1});
    end

    % data.summary = sm.get_summary(); % get the summary array stored by the state machine. Should only be non-tgt stuff (computed reach angle, RT, ...)
    % write data
    mkdir(settings.data_path); % might already exist, but it doesn't error if so
    to_json(fullfile(settings.data_path, strcat(settings.id, '_', num2str(data.block.start_unix), '.json')), data, 1);
    WaitSecs('UntilTime', last_flip_time + 2); % show last msg for at least 2 sec
    DrawFormattedText(w.w, 'Done!', 'center', 'center', 255);
    last_flip_time = Screen('Flip', w.w);
    WaitSecs('UntilTime', last_flip_time + 1);
    _cleanup(); % clean up
    % profile off;
    % profshow;
end
