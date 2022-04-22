% top-level boilerplate-- "real" experiment in _vmr_exp.m
% Note this assumes only octave. Some things don't exist in MATLAB, and
% I don't want to take the time to fix/standardize at this point
function _vmr_setup(is_debug, is_short)
    delete('latest.log');
    diary 'latest.log'; % write warnings/errs to logfile
    diary on;
    if ~(IsOctave() && IsLinux())
        warning([sprintf('This experiment was written to specifically target linux + Octave.\n'), ...
                 'Things will probably fail if you have not adapted to other systems.']);
    end
    try
        vmr_inner(is_debug, is_short);
    catch err
        % clean up PTB here
        % Do we need anything else? Audio/input/..
        _cleanup();
        rethrow(err);
    end
end

function vmr_inner(is_debug, is_short)
    if IsOctave()
        ignore_function_time_stamp("all");
    end
    ref_path = fileparts(mfilename('fullpath'));
    addpath(fullfile(ref_path, 'fns')); % add misc things to search path
    addpath(fullfile(ref_path, 'tgt'));
    settings = struct('id', 'test', 'group', 2, 'sign', 1, ...
                      'base_path', ref_path, 'data_path', fullfile(ref_path, 'data'));

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
        if strcmp("y", x_or_y('I could not find the Wacom tablet, should we stop now (y or n)? ', ["y", "n"]))
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
        id = input(sprintf('Enter the participant ID, or leave blank to use the default value (%s): ', num2str(settings.id)), "s");
        if ~isempty(id)
            settings.id = id;
        end
    end

    if ~is_debug
        settings.group = x_or_y('What group are they in, 1, 2, 3, or 4? ', [1, 2, 3, 4]);
    end

    if ~is_debug
        if strcmp("n", x_or_y('What sign, (n)egative or (p)ositive? ', ["n", "p"]))
            sign = -1;
        else
            sign = 1;
        end
        settings.sign = sign;
    end

    block_type = x_or_y('Is this the veridical practice (p), clamp practice (c) or real thing (r)? ', ["p", "c", "r"]);

    _vmr_exp(is_debug, is_short, block_type, settings);
end
