function _cleanup()
    Priority(0);
    sca;
    PsychPortAudio('Close');
    PsychHID('KbQueueRelease');
    diary off;
end
