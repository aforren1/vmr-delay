
function to_json(filename, val, compress)
    if IsOctave()
        %txt = toJSON(val, 6, true);
        txt = json_encode(val);
    else
        error('to_json not implemented for MATLAB.');
        % probably txt = jsonencode(cache); ?
    end

    fid = fopen(filename, 'w');
    fputs(fid, txt);
    fclose(fid);
    if compress
        gzip(filename);
        delete(filename);
    end
end
