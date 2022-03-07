function data = from_json(filename)
    if IsOctave()
        cache = fileread(filename);
        data = fromJSON(cache);
    else
        % https://www.mathworks.com/matlabcentral/answers/474980-extract-info-from-json-file-by-matlab
        error('load_cache not implemented for MATLAB.');
    end
end
