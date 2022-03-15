% the "real" part of the experiment
function _vmr_exp(is_debug, settings)

    % turn off splash
    KbName('UnifyKeyNames');
    Screen('Preference', 'VisualDebugLevel', 3);
    screens = Screen('Screens');
    max_scr = max(screens);

    w = struct();
    if is_debug % tiny window
        Screen('Preference', 'SkipSyncTests', 1); 
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
    % TODO: map mm to pixels
    % X11 apparently gets it really wrong with extended screen, but
    % even gets height wrong??
    % actually gets it wrong with single screen too, so...
    % randr seems to nail it though
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
    t = 0
    evt = struct('X', 0, 'Y', 0);
    while state
        % break if esc pressed
        [~, ~, keys] = KbCheck(-1); % query all keyboards
        if keys(10) % hopefully right-- we unified key positions before?
            error('Escape was pressed.');
        end

        % process all pending input events
        while KbEventAvail(dev.index)
            [evt, n_evts] = PsychHID('KbQueueGetEvent', dev.index, 0);
            disp([(evt.Time - t) evt.X evt.Y]); % we should use x = valuators(1) and y = valuators(2), which
                       % might be independent of screen mapping?
            %disp(evt.Time - t);
            t = evt.Time;
        end

        % for the state machine, implement fallthrough by consecutive `if ...`
        if state == states.RETURN_TO_CENTER
            if disp_time > (ref_time + 20)
                state = states.END;
            end
        end
        % draw things based on state
        Screen('FillOval', w.w, [255 255 255], CenterRectOnPoint([0 0 25 25], evt.X, evt.Y));
        Screen('DrawingFinished', w.w);
        % swap buffers
        % use vbl_time to schedule subsequent flips, and disp_time for actual
        % stimulus onset time
        [vbl_time, disp_time] = Screen('Flip', w.w, vbl_time + 0.5 * w.ifi);
    end

    KbQueueStop(dev.index);
    KbQueueRelease(dev.index);
    _cleanup(); % clean up
end
