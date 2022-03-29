am = AudioManager();

am.add('media/speed_up.wav', 'speed_up');

am.play('speed_up');
disp('playing...');
WaitSecs(3);

PsychPortAudio('Close');