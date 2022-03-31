
array = nan(10, 1);


for i = 1:30
    % add value
    array(1:end-1) = array(2:end);
    array(end) = i;
    if isnan(array(1))
        disp('nan');
    else
        disp(array(1));
    end
end
