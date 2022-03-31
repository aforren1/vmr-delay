
function val = y_or_n(prompt)
    while true
        tmp = input(prompt, "s");
        if tmp == "y"
            val = true;
            return;
        else if tmp == "n"
            val = false;
            return;
        else
            fprintf("Please respond {y}es or {n}o.\n");
        end
    end
end