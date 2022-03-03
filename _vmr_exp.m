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
    % TODO: map mm to pixels
    % X11 apparently gets it really wrong with extended screen, but
    % even gets height wrong??
    % actually gets it wrong with single screen too, so...
    % randr seems to nail it though
    % [w.disp.width, w.disp.height] = Screen('DisplaySize', max_scr);

    state = states.RETURN_TO_CENTER;

    % TODO: shuffle this with settings rather than repeating
    devs = PsychHID('Devices');
    found_tablet = false;
    for dev = devs
        if dev.vendorID == 0x056a && dev.productID == 0x0358
            found_tablet = true;
            break
        end
    end

    
    if found_tablet
        % hmm, 
        devs = PsychHID('Devices', 3); % get all slave pointers
        for dev = devs
            % not sure if interfaceID is stable, so parse the product name...
            % and vendor/product not filled??
            if index(dev.product, 'Wacom') && index(dev.product, 'stylus')
                break % we have our man
            end
        end

    else % get the master mouse pointer or something
        dev = PsychHID('Devices', 1);
    end

    dev = dev(1); % make sure we're down to one device
    disp(dev);

    KbQueueCreate(dev.index, [], 2);
    KbQueueStart(dev.index);

    % flip once more to get a reference time
    % we're assuming linux computers with OpenML support
    [vbltime, ref_time] = Screen('Flip', w.w);
    disp_time = ref_time;

    KbQueueFlush(dev.index, 2); % only flush KbEventGet
    while state
        % break if esc pressed
        [~, ~, keys] = KbCheck(-1); % query all keyboards
        if keys(10) % hopefully right-- we unified key positions before?
            error('Escape was pressed.');
        end

        % process all pending input events
        while KbEventAvail(dev.index)
            [evt, n_evts] = KbEventGet(dev.index);
            disp(evt);
        end

        % for the state machine, implement fallthrough by consecutive `if ...`
        if state == states.RETURN_TO_CENTER
            if disp_time > (ref_time + 10)
                state = states.END;
            end
        end
        % draw things based on state

        Screen('DrawingFinished', w.w);
        % swap buffers
        [~, disp_time] = Screen('Flip', w.w);
    end

    KbQueueStop(dev.index);
    KbQueueRelease(dev.index);
    sca; % clean up
end
