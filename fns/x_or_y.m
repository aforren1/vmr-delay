
function val = x_or_y(prompt, vals)
    cvals = num2cell(vals);
    svals = cellfun('num2str', cvals, 'UniformOutput', false);
    while true
        tmp = input(prompt, "s");
        for i = 1:length(svals)
            if strcmp(svals{i}, tmp)
                val = vals(i);
                return;
            end
        end
        disp(sprintf("Please respond with answers {%s}.\n", strjoin(svals, ', ')));
    end
end