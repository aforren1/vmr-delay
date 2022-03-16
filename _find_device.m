
function dev = _find_device()
    % TODO: shuffle this with settings rather than repeating
    devs = PsychHID('Devices');
    found_tablet = false;
    for dev = devs
        if dev.vendorID == 0x056a && dev.productID == 0x0358
            found_tablet = true;
            break
        end
    end

    found_pen = false;
    if found_tablet
        found_pen = false;
        devs = PsychHID('Devices', 5); % 3 = slave, 5 = floating
        for dev = devs
            % not sure if interfaceID is stable, so parse the product name...
            % and vendor/product not filled??
            if index(dev.product, 'Wacom') && index(dev.product, 'stylus')
                found_pen = true;
                break % we have our man
            end
        end

        if ~found_pen # oops, did we forget to set the stylus as floating?
            devs = PsychHID('Devices', 3); % 3 = slave, 5 = floating
            for dev = devs
                % not sure if interfaceID is stable, so parse the product name...
                % and vendor/product not filled??
                if index(dev.product, 'Wacom') && index(dev.product, 'stylus')
                    found_pen = true;
                    break % we have our man
                end
            end
        end

    else % get the master mouse pointer or something
        dev = PsychHID('Devices', 1);
        found_pen = true;
    end

    if ~found_pen
        error('The pen was not found. Try again? (Maybe wiggle on tablet once to send a few events)')
    end

    dev = dev(1); % make sure we're down to one device (should always be the case)
end
