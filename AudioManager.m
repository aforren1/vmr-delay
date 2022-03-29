classdef AudioManager < handle

    properties
        master
        freq
        sounds = containers.Map
    end

    methods
        function au = AudioManager()
            % mostly based off BasicAMAndMixScheduleDemo and BasicSoundOutputDemo
            % we'll go for low latency
            % clean up assumed to happen on close by other machinery (_cleanup.m), but if we were
            % being cleaner it would live here instead?
            InitializePsychSound(1);
            % open master + playback only, clobber other audio apps, stereo
            au.master = PsychPortAudio('Open', [], 1+8, 2, 44100, 2, []);
            s = PsychPortAudio('GetStatus', au.master);
            au.freq = s.SampleRate;
            PsychPortAudio('Start', au.master, 0, 0, 1);
            PsychPortAudio('Volume', au.master, 0.5); % turn down by default
        end

        function add(au, sound, key)
            % add a wav file to map
            [data, freq] = psychwavread(sound);
            if freq ~= au.freq
                error(sprintf('Non-matching audio frequency. File had %i, but expected %i.', freq, au.freq));
            end
            data = data.';
            n_chan = size(data, 1);
            if n_chan < 2
                data = [data; data];
            end
            % for simplicity, one slave per sound
            au.sounds(key) = PsychPortAudio('OpenSlave', au.master, 1);
            PsychPortAudio('FillBuffer', au.sounds(key), data);
        end

        function play(au, key)
            % no reps, immediately, don't wait for playback to start
            PsychPortAudio('Start', au.sounds(key), 1, 0, 0);
        end
        % https://www.mathworks.com/help/matlab/matlab_oop/handle-class-destructors.html
    end
end