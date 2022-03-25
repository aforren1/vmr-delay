
% any reason to use handle? we're never passing this anywhere...
classdef StateMachine < handle

    properties (Access = private)
        state = states.RETURN_TO_CENTER
        is_transitioning = true
        w % window struct (read-only)
        tgt % target table
        mm2px % handle to mm2px lambda fn
        trial_summary_data % summary data per-trial (e.g. RT, est reach angle,...)
        trial_count = 1
        within_trial_frame_count = 1
        % we can shuffle "local" data here
        cursor = struct('x', 0, 'y', 0, 'vis', false);
        target = struct('x', 0, 'y', 0, 'vis', false);
        ep_feedback = struct('x', 0, 'y', 0, 'vis', false);
        center = struct('x', 0, 'y', 0, 'vis', false);
    end

    methods

        function sm = StateMachine(tgt, win_info, mm2px)
            sm.w = win_info;
            sm.tgt = tgt;
            sm.mm2px = mm2px;
            % keep track of trial summary data here, and write out later
        end

        function update(sm, evt)
            % NB: evt might be empty (check with `evt.t > 0`?)

            % one thing to think about-- should we allow this sort of "fall through", or
            % should each state exist for at least one frame? If we have drawing tied to
            % state, it suggests the latter (as we can't undo draw calls)
            % the other thing to keep in mind is that drawing is more "immediate" than what I tend to do
            if evt.t > 0 % non-empty event
                sm.cursor.x = evt.x;
                sm.cursor.y = evt.y;
            end

            if sm.state == states.RETURN_TO_CENTER
                if sm.entering()
                    sm.cursor.vis = true;
                    sm.center.vis = true;
                    sm.center.x = sm.w.center(1);
                    sm.center.y = sm.w.center(2);
                end
                % stuff that runs every frame

                % transition conditions

            end

            if sm.state == states.REACH
                if sm.entering()

                end
                % stuff that runs every frame

                % transition conditions

            end

            if sm.state == states.DIST_EXCEEDED
                if sm.entering()

                end
                % every frame

                % transition conditions

            end

            % process delayed events
        end

        function draw(sm)
            % drawing; keep order in mind?
            MAX_NUM_CIRCLES = 4; % max 4 circles ever
            rects = zeros(4, MAX_NUM_CIRCLES);
            colors = zeros(3, MAX_NUM_CIRCLES, 'uint8'); % rgb
            counter = 1;
            blk = sm.tgt.block;
            mm2px = sm.mm2px;
            w = sm.w;
            if sm.target.vis
                rects(:, counter) = CenterRectOnPointd([0 0 mm2px(blk.target.size)], sm.target.x, sm.target.y);
                colors(:, counter) = blk.target.color; % white by default? should encode...
                counter = counter + 1;
            end

            if sm.center.vis
                rects(:, counter) = CenterRectOnPointd([0 0 mm2px(blk.center.size)], sm.center.x, sm.center.y);
                colors(:, counter) = blk.center.color; % white by default? should encode...
                counter = counter + 1;
            end

            if sm.ep_feedback.vis
                rects(:, counter) = CenterRectOnPointd([0 0 mm2px(blk.cursor.size)], sm.ep_feedback.x, sm.ep_feedback.y);
                colors(:, counter) = blk.cursor.color; % white by default? should encode...
                counter = counter + 1;
            end

            if sm.cursor.vis
                rects(:, counter) = CenterRectOnPointd([0 0 mm2px(blk.cursor.size)], sm.cursor.x, sm.cursor.y);
                colors(:, counter) = blk.cursor.color; % white by default? should encode...
                counter = counter + 1;
            end
            % draw all circles together; never any huge circles, so we only need nice-looking up to a point
            Screen('FillOval', w.w, colors, rects, floor(w.rect(4) * 0.25));
        end

        function state = get_state(sm)
            state = sm.state;
        end

        function [tc, wtc] = get_counters(sm)
            tc = sm.trial_count;
            wtc = sm.within_trial_frame_count;
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
