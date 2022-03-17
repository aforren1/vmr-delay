function _cleanup()
    Priority(0);
    sca;
    PsychPortAudio('Close');
    PsychHID('KbQueueRelease'); % TODO: do we need to specify the device index? Probably not
end
