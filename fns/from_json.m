function data = from_json(filename)
    if IsOctave()
        cache = fileread(filename);
        %data = fromJSON(cache);
        data = json_decode(cache);
    else
        % https://www.mathworks.com/matlabcentral/answers/474980-extract-info-from-json-file-by-matlab
        error('from_json not implemented for MATLAB.');
    end
end
