% the "real" part of the experiment
function _vmr_exp(is_debug, settings)
    start_unix = floor(time());
    start_dt = datestr(clock(), 31); %Y-M-D H:M:S
    % constants
    GREEN = [0 255 0];
    RED = [255 0 0];
    WHITE = [255 255 255];
    BLACK = [0 0 0];
    GRAY30 = [77 77 77];
    GRAY50 = [127 127 127];
    GRAY70 = [179 179 179];
    X_MM2PX = 0.2832; % pixel pitch, specific to "real" monitor
    Y_MM2PX = 0.2802;
    X_MM2PX_INV = 1 / X_MM2PX;
    Y_MM2PX_INV = 1 / Y_MM2PX;

    x_mm2px = @(mm) (mm * X_MM2PX_INV);
    y_mm2px = @(mm) (mm * Y_MM2PX_INV);
    mm2px = @(mm) (mm .* [X_MM2PX_INV Y_MM2PX_INV]);
    % ORIGIN (offset from center of screen)

    % read the .tgt.json
    tgt = from_json(settings.tgt_path);
    % allocate data before running anything
    data = _alloc_data(length(tgt.trial));

    % turn off splash
    KbName('UnifyKeyNames');
    Screen('Preference', 'VisualDebugLevel', 3);
    screens = Screen('Screens');
    max_scr = max(screens);

    w = struct(); % container for window-related things
    if is_debug % tiny window, skip all the warnings
        Screen('Preference', 'SkipSyncTests', 2); 
        Screen('Preference', 'VisualDebugLevel', 0);
        [w.w, w.rect] = Screen('OpenWindow', max_scr, 0, [0, 0, 800, 800]);
    else
        % real deal, make sure sync tests work
        % for the display (which is rotated 180 deg), we need
        % to do this. Can't use OS rotation, otherwise PTB gets mad
        PsychImaging('PrepareConfiguration');
        PsychImaging('AddTask', 'General', 'UseDisplayRotation', 180);
        [w.w, w.rect] = Screen('OpenWindow', max_scr, 0);
    end

    [w.center(1), w.center(2)] = RectCenter(w.rect);
    % assume color is 8 bit, so don't fuss with WhiteIndex/BlackIndex

    Screen('Flip', w.w); % flip once to warm up

    w.fps = Screen('FrameRate', w.w);
    w.ifi = Screen('GetFlipInterval', w.w);
    Priority(MaxPriority(w.w));
    % X11 apparently gets it really wrong with extended screen, but
    % even gets height wrong??
    % actually gets it wrong with single screen too, so...
    % randr seems to nail it though
    % and for this round, we've just gotten the size from the manual (see mm2px* above)
    % [w.disp.width, w.disp.height] = Screen('DisplaySize', max_scr);

    state = states.RETURN_TO_CENTER;

    dev = _find_device(); % get the pen (or mouse, if testing)
    % hide the cursor
    % more for the sake of the operator mouse rather than tablet, which is probably
    % floating at this point
    HideCursor(w.w);

    KbQueueCreate(dev.index, [], 2);
    KbQueueStart(dev.index);

    % flip once more to get a reference time
    % we're assuming linux computers with OpenML support
    % vbl_time helps with scheduling flips, and ref_time helps with relating
    % to input events (b/c it *should* be when the stimulus changes on the screen)
    [vbl_time, ref_time] = Screen('Flip', w.w);
    disp_time = ref_time;

    KbQueueFlush(dev.index, 2); % only flush KbEventGet
    %t = 0;
    trial_count = 1;
    frame_count = 1;
    within_trial_count = 1;
    evt = struct('X', w.center(1), 'Y', w.center(2)); % dummy struct, until first input event is generated
    while state
        % break if esc pressed
        [~, ~, keys] = KbCheck(-1); % query all keyboards
        if keys(10) % hopefully right-- we unified key positions before?
            error('Escape was pressed.');
        end

        % sleep part of the frame to reduce lag
        % TODO: tweak this if we end up doing the 120hz + strobing
        % we probably only need a 1-2ms to do state updates
        % for 240hz, this cuts off up to 2.5ms or so?
        WaitSecs('UntilTime', vbl_time + 0.6 * w.ifi);

        % process all pending input events
        % check number of pending events once, which should be robust
        % to higher-frequency devices
        n_evts = KbEventAvail(dev.index);
        for i = 1:n_evts
            % events are in the same coordinates as psychtoolbox (px)
            % eventually, we would figure out mapping so that we get to use
            % the full range of valuators, but I haven't been able to get
            % it right yet. So for now, we're stuck with slightly truncated resolution
            % (but still probably plenty)
            [evt, ~] = PsychHID('KbQueueGetEvent', dev.index, 0);
            %disp([(evt.Time - t) evt.X evt.Y]);
            %t = evt.Time;
            % TODO: does MATLAB do non-copy slices?? This sucks
            data.trials.frames(trial_count).input_events(within_trial_count).time(i) = evt.Time;
            data.trials.frames(trial_count).input_events(within_trial_count).x(i) = evt.X;
            data.trials.frames(trial_count).input_events(within_trial_count).y(i) = evt.Y;
        end
        % take subset to reduce storage size (& because anything else is junk)
        % again, I *really* wish I could just take an equivalent to a numpy view...
        data.trials.frames(trial_count).input_events(within_trial_count).time = data.trials.frames(trial_count).input_events(within_trial_count).time(1:n_evts);
        data.trials.frames(trial_count).input_events(within_trial_count).x = data.trials.frames(trial_count).input_events(within_trial_count).x(1:n_evts);
        data.trials.frames(trial_count).input_events(within_trial_count).y = data.trials.frames(trial_count).input_events(within_trial_count).y(1:n_evts);
        % for the state machine, implement fallthrough by consecutive `if ...`
        beginning_state = state; % store initial state for data
        if state == states.RETURN_TO_CENTER
            if disp_time > (ref_time + 5)
                state = states.END;
            end
        end
        % draw things based on state
        % we'll do it inline with state changes for now-- we should *probably* collate if we were
        % drawing more things, but I expect it'll only be a few circles and some text
        Screen('FillOval', w.w, [255 255 255], CenterRectOnPoint([0 0 mm2px(tgt.block.cursor_size)], evt.X, evt.Y));
        Screen('DrawingFinished', w.w);
        % do we have any useful work to do here? Probably not, if we slept half the frame away
        % swap buffers
        % use vbl_time to schedule subsequent flips, and disp_time for actual
        % stimulus onset time
        [vbl_time, disp_time, ~, missed, ~] = Screen('Flip', w.w, vbl_time + 0.95 * w.ifi);
        % done the frame, we'll write data now?
        missed_deadline = missed >= 0;
        data.trials.frames(trial_count).frame_count(within_trial_count) = frame_count;
        data.trials.frames(trial_count).vbl_time(within_trial_count) = vbl_time;
        data.trials.frames(trial_count).disp_time(within_trial_count) = disp_time;
        data.trials.frames(trial_count).missed_frame_deadline(within_trial_count) = missed_deadline;
        data.trials.frames(trial_count).start_state(within_trial_count) = beginning_state;
        data.trials.frames(trial_count).end_state(within_trial_count) = state;

        frame_count = frame_count + 1; % grows forever/applies across entire experiment
        within_trial_count = within_trial_count + 1; % remember to reset when moving to new trial
    end

    KbQueueStop(dev.index);
    KbQueueRelease(dev.index);
    Screen('TextSize', w.w, floor(0.05 * w.rect(4)));
    DrawFormattedText(w.w, 'Finished, saving data...', 'center', 'center', 255);
    Screen('Flip', w.w);

    % write data
    data.block.id = settings.id;
    data.block.is_debug = is_debug;
    data.block.tgt_path = settings.tgt_path;
    [status, data.block.git_hash] = system("git log --pretty=format:'%H' -1 2>/dev/null");
    if status
        warning('git hash failed, is git installed?');
    end
    [status, data.block.git_branch] = system("git rev-parse --abbrev-ref HEAD | tr -d '\n' 2>/dev/null");
    if status
        warning('git branch failed, is git installed?');
    end
    [status, data.block.git_tag] = system("git describe --tags 2>/dev/null");
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
    data.block.pixel_pitch = [X_MM2PX Y_MM2PX];
    data.block.start_unix = start_unix; % whole seconds since unix epoch
    data.block.start_dt = start_dt;
    
    % copy common things over
    for fn = fieldnames(tgt.block)'
        data.block.(fn{1}) = tgt.block.(fn{1});
    end

    % write data
    mkdir(settings.data_path);
    to_json(fullfile(settings.data_path, strcat(settings.id, '_', num2str(data.block.start_unix), '.json')), data, 1);
    _cleanup(); % clean up
end
