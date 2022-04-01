
function val = x_or_y(prompt, vals)
    while true
        tmp = input(prompt, "s");
        if strcmp(tmp, vals(1))
            val = vals(1);
            return;
        else if strcmp(tmp, vals(2))
            val = vals(2);
            return;
        else
            disp(sprintf("Please respond {%s} or {%s}.\n", vals(1), vals(2)));
        end
    end
end