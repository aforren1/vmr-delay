% top-level boilerplate-- "real" experiment in _vmr_exp.m
% Note this assumes only octave. Some things don't exist in MATLAB (e.g. yes_or_no), and
% I don't want to take the time to fix/standardize at this point
function _vmr_setup(debug)
    if IsOctave()
        pkg load io
    end
    try
        vmr_inner(debug == 'd');
    catch err
        % clean up PTB here
        % Do we need anything else? Audio/input/..
        _cleanup();
        rethrow(err);
    end
end

function vmr_inner(is_debug)
    ref_path = fileparts(mfilename('fullpath'));
    cache_path = fullfile(ref_path, 'cache.json');    
    % load cache file, otherwise fill in default
    try
        cache = from_json(cache_path);
    catch err
        % no cache, fill in default
        cache = struct('id', 'test', 'tgt', 'test.tgt');
    end

    % buglet: device info not filled when deviceClass unspecified?
    devs = PsychHID('Devices');
    found_tablet = false;
    for dev = devs
        % Wacom PTH 860
        if dev.vendorID == 0x056a && dev.productID == 0x0358
            found_tablet = true;
            break
        end
    end

    if ~found_tablet && ~is_debug
        if yes_or_no('I could not find the Wacom tablet, should we stop now? ')
            error('Did not find the tablet (Wacom PTH 860).');
        else
            fprintf('Continuing with mouse...\n\n');
        end
    end
    
    if ~is_debug
        id = input(sprintf('Enter the participant ID, or leave blank to use the previous value (%s): ', num2str(cache.id)), "s");
        if ~isempty(id)
            cache.id = id;
        end
    end

    to_json(cache_path, cache);
    _vmr_exp(is_debug, cache);
end
