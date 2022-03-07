
function save_cache(filename, val)
    if IsOctave()
        txt = toJSON(val);
    else
        error('save_cache not implemented for MATLAB.');
        % probably txt = jsonencode(cache); ?
    end

    fid = fopen(filename, 'w');
    fputs(fid, txt);
    fclose(fid);
end