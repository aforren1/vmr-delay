% the "real" part of the experiment
function _vmr_exp(is_debug, settings)

    % turn off splash
    Screen('Preference', 'VisualDebugLevel', 3);
    screens = Screen('Screens');
    max_scr = max(screens);

    w = struct();
    if is_debug % tiny window
        Screen('Preference', 'SkipSyncTests', 1); 
        [w.w, w.rect] = Screen('OpenWindow', max_scr, 0, [0, 0, 800, 800]);
    else
        % real deal, make sure sync tests work
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

    x = states.REACH_TO_CENTER;

    sca; % clean up
end
