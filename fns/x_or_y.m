
function val = x_or_y(prompt, vals)
    str1 = num2str(vals(1));
    str2 = num2str(vals(2));
    while true
        tmp = input(prompt, "s");
        if strcmp(tmp, str1)
            val = vals(1);
            return;
        else if strcmp(tmp, str2)
            val = vals(2);
            return;
        else
            disp(sprintf("Please respond {%s} or {%s}.\n", str1, str2));
        end
    end
end