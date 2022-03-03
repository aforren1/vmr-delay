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
        cache = load_cache(cache_path);
    catch err
        % no cache, fill in default
        cache = struct('id', 'test', 'tgt', 'test.tgt');
    end

    devs = PsychHID('Devices');
    found_tablet = false;
    for i = 1:length(devs)
        % Wacom PTH 860
        if devs(i).vendorID == 0x056a && devs(i).productID == 0x0358
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

    id = input(sprintf('Enter the participant ID, or leave blank to use the previous value (%s): ', num2str(cache.id)), "s");
    if ~isempty(id)
        cache.id = id;
    end

    save_cache(cache_path, cache);
    _vmr_exp(is_debug, cache);
end

function data = load_cache(filename)
    if IsOctave()
        cache = fileread(filename);
        data = fromJSON(cache);
    else
        % https://www.mathworks.com/matlabcentral/answers/474980-extract-info-from-json-file-by-matlab
        error('load_cache not implemented for MATLAB.');
    end
end

function save_cache(filename, cache)
    if IsOctave()
        txt = toJSON(cache);
    else
        error('save_cache not implemented for MATLAB.');
        % probably txt = jsonencode(cache); ?
    end

    fid = fopen(filename, 'w');
    fputs(fid, txt);
    fclose(fid);
end