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

function vmr_inner(is_debug, is_short)
    if IsOctave()
        ignore_function_time_stamp("all");
    end
    ref_path = fileparts(mfilename('fullpath'));
    addpath(fullfile(ref_path, 'fns')); % add misc things to search path
    addpath(fullfile(ref_path, 'tgt'));
    settings = struct('id', 'test', 'group', 2, ...
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
        if y_or_n('I could not find the Wacom tablet, should we stop now? ')
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
        while true
            group = input('What group are they in, 1 or 2? ');
            if group == 1 || group == 2
                settings.group = group;
                break
            end
            fprintf('Please pick 1 or 2.\n\n');
        end
    end

    is_demo = ~y_or_n('Is this the real thing (y) or a practice block (n)? ');

    _vmr_exp(is_debug, is_short, is_demo, settings);
end
