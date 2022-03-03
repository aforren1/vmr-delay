args = argv();
if length(args) > 0
    _vmr_setup('d');
else
    _vmr_setup('x');
end