
function to_json(filename, val)
    if IsOctave()
        txt = toJSON(val);
    else
        error('to_json not implemented for MATLAB.');
        % probably txt = jsonencode(cache); ?
    end

    fid = fopen(filename, 'w');
    fputs(fid, txt);
    fclose(fid);
end