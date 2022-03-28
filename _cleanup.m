function _cleanup()
    Priority(0);
    sca;
    PsychPortAudio('Close');
    PsychHID('KbQueueRelease');
    diary off;
    ListenChar(0);
end
