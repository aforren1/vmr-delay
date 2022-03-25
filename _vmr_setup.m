% top-level boilerplate-- "real" experiment in _vmr_exp.m
% Note this assumes only octave. Some things don't exist in MATLAB (e.g. yes_or_no), and
% I don't want to take the time to fix/standardize at this point
function _vmr_setup(debug)
    delete('latest.log');
    diary 'latest.log'; % write warnings/errs to logfile
    diary on;
    if ~(IsOctave() && IsLinux())
        warning([sprintf('This experiment was written to specifically target linux + Octave.\n'), ...
                 'Things will probably fail if you have not adapted to other systems.']);
    end
    try
        vmr_inner(debug);
    catch err
        % clean up PTB here
        % Do we need anything else? Audio/input/..
        _cleanup();
        rethrow(err);
    end
end

function vmr_inner(is_debug)
    if IsOctave()
        ignore_function_time_stamp("all");
    end
    ref_path = fileparts(mfilename('fullpath'));
    addpath(fullfile(ref_path, 'fns')); % add misc things to search path
    cache_path = fullfile(ref_path, 'cache.json');
    test_tgt = fullfile(ref_path, 'tgt', 'test.tgt.json');
    default_settings = struct('id', 'test', 'tgt_path', test_tgt, 'data_path', fullfile(ref_path, 'data'));
    % load cache file, otherwise fill in default
    try
        cache = from_json(cache_path);
        f1 = fieldnames(cache);
        f2 = fieldnames(default_settings);
        lf1 = length(f1);
        lf2 = length(f2);
        lfb = length(intersect(f1, f2));
        if lf1 != lf2 || lfb != lf2 || lfb != lf1
            error('Fieldnames have changed, reverting to default.');
        end
    catch err
        % no cache, fill in default
        cache = default_settings;
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

    if found_tablet && IsLinux()
        % set up tablet for linux
        system('bash setup_wacom.sh');
    end
    
    if ~is_debug
        id = input(sprintf('Enter the participant ID, or leave blank to use the previous value (%s): ', num2str(cache.id)), "s");
        if ~isempty(id)
            cache.id = id;
        end
    end

    % pick the file to dictate the experiment flow
    if ~is_debug
        [fname, fpath, ~] = uigetfile('*.tgt.json', 'Pick a tgt.json', cache.tgt_path);
        if ~fname
            error('No tgt selected.');
        end
        tgt_path = fullfile(fpath, fname);
    else
        tgt_path = test_tgt;
    end

    cache.tgt_path = tgt_path;
    to_json(cache_path, cache, 0); % save cache for next time
    _vmr_exp(is_debug, cache);
end
