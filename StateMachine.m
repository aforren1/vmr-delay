
% any reason to use handle? we're never passing this anywhere...
classdef StateMachine < handle

    properties (Access = private)
        state = states.RETURN_TO_CENTER
        is_transitioning = true
        w % window struct (read-only)
        tgt % target table
        trial_count = 1
        frame_count = 1
        within_trial_count = 1
        % we can shuffle "local" data here
        cursor_vis = true
    end

    methods

        function sm = StateMachine(tgt, win_handle)
            sm.w = win_handle;
            sm.tgt = tgt;
        end

        function update(sm, frame_data)
            % one thing to think about-- should we allow this sort of "fall through", or
            % should each state exist for at least one frame? If we have drawing tied to
            % state, it suggests the latter (as we can't undo draw calls)
            % the other thing to keep in mind is that drawing is more "immediate" than what I tend to do
            if sm.state == states.RETURN_TO_CENTER
                if sm.entering()
                end
                % stuff that runs every frame

            end

            if sm.state == states.REACH
                if sm.entering()

                end
                % stuff that runs every frame
            end

            % drawing
            if sm.cursor_vis

            end
        end

    end

    methods (Access = private)
        function ret = entering(sm)
            ret = sm.is_transitioning;
            sm.is_transitioning = false;
        end

        % Octave buglet? can set state here even though method access is private
        % but fixed by restricting property access, so not an issue for me
        function state = set.state(sm, value)
            sm.is_transitioning = true; % assume we always mean to call transition stuff when calling this
            sm.state = value;
        end
    end
end
