
% any reason to use handle? we're never passing this anywhere...
classdef StateMachine < handle

    properties (Access = private)
        state = states.RETURN_TO_CENTER
        is_transitioning = true
        w % window struct (read-only)
        tgt % target table
        mm2px % handle to mm2px lambda fn
        x_mm2px
        y_mm2px
        trial_summary_data % summary data per-trial (e.g. RT, est reach angle,...)
        trial_count = 1
        within_trial_frame_count = 1
        % we can shuffle "local" data here
        % targets and the like have sizes set by tgt file
        % x, y are expected to be in px
        cursor = struct('x', 0, 'y', 0, 'vis', false);
        target = struct('x', 0, 'y', 0, 'vis', false);
        ep_feedback = struct('x', 0, 'y', 0, 'vis', false);
        center = struct('x', 0, 'y', 0, 'vis', false);
        hold_time = 0
        vis_time = 0
        targ_dist_px = 0
        feedback_dur = 0
    end

    methods

        function sm = StateMachine(tgt, win_info, mm2px, x_mm2px, y_mm2px)
            sm.w = win_info;
            sm.tgt = tgt;
            sm.mm2px = mm2px;
            sm.x_mm2px = x_mm2px;
            sm.y_mm2px = y_mm2px;
            % keep track of trial summary data here, and write out later
        end

        function update(sm, evt, last_vbl)
            % NB: evt might be empty
            % This function only runs once a frame on the latest input event

            % one thing to think about-- should we allow this sort of "fall through", or
            % should each state exist for at least one frame? If we have drawing tied to
            % state, it suggests the latter (as we can't undo draw calls)
            % the other thing to keep in mind is that drawing is more "immediate" than what I tend to do
            sm.within_trial_frame_count = sm.within_trial_frame_count + 1;
            w = sm.w;
            tgt = sm.tgt;
            x_mm2px = sm.x_mm2px;
            y_mm2px = sm.y_mm2px;
            if ~isempty(evt) % non-empty event
                sm.cursor.x = evt.x;
                sm.cursor.y = evt.y;
            end

            est_next_vbl = last_vbl + w.ifi;
            if sm.state == states.RETURN_TO_CENTER
                if sm.entering()
                    % set the state you want, not the one you expect
                    sm.cursor.vis = false;
                    sm.center.vis = true;
                    sm.ep_feedback.vis = false;
                    sm.target.vis = false;
                    sm.center.x = w.center(1);
                    sm.center.y = w.center(2);
                    sm.hold_time = est_next_vbl + 0.2;
                    sm.vis_time = est_next_vbl + 0.5;
                end
                % stuff that runs every frame
                if est_next_vbl >= sm.vis_time
                    sm.cursor.vis = true;
                end
                % transition conditions
                % hold in center for 200 ms
                % TODO: are the visuals the right sizes? collision doesn't look right in debug...
                if point_in_circle([sm.cursor.x sm.cursor.y], [sm.center.x sm.center.y], ...
                    tgt.block.center.size * 0.5)
                    if est_next_vbl >= sm.hold_time
                        sm.state = states.REACH;
                    end
                else
                    sm.hold_time = est_next_vbl + 0.2; % 200 ms in the future
                end
            end

            if sm.state == states.REACH
                if sm.entering()
                    sm.target.vis = true;
                    t = tgt.trial(sm.trial_count).target;
                    tx = x_mm2px(t.x);
                    ty = y_mm2px(t.y);
                    sm.target.x = tx + w.center(1);
                    sm.target.y = ty + w.center(2);
                    sm.targ_dist_px = distance(tx, 0, ty, 0);
                    if tgt.trial(sm.trial_count).is_endpoint
                        sm.cursor.vis = false;
                    end
                end
                % stuff that runs every frame
                dist_cur = distance(sm.cursor.x, sm.center.x, sm.cursor.y, sm.center.y);
                if dist_cur >= sm.targ_dist_px
                    sm.state = states.DIST_EXCEEDED;
                end
            end

            if sm.state == states.DIST_EXCEEDED
                if sm.entering()
                    sm.cursor.vis = false;
                    sm.feedback_dur = tgt.block.feedback_duration + est_next_vbl;
                    trial = tgt.trial(sm.trial_count);
                    if trial.is_endpoint
                        sm.ep_feedback.vis = true;
                        % TODO: position endpoint feedback based on condition
                        if trial.is_manipulated
                            %TODO: implement rotation
                            % get angle of target in deg, add clamp offset, then to rad
                            target_angle = atan2d(sm.target.y - w.center(2), sm.target.x - w.center(1));
                            theta = deg2rad(target_angle + trial.manipulation_angle);
                        else
                            theta = atan2(sm.cursor.y - w.center(2), sm.cursor.x - w.center(1));
                        end
                        % use earlier sm.targ_dist_px for extent
                        sm.ep_feedback.x = sm.targ_dist_px * cos(theta) + w.center(1);
                        sm.ep_feedback.y = sm.targ_dist_px * sin(theta) + w.center(2);
                    end
                end
                % transition?
                if est_next_vbl >= sm.feedback_dur
                    sm.target.vis = false;
                    % end of the trial, are we done?
                    if (sm.trial_count + 1) > length(tgt.trial)
                        sm.state = states.END;
                    else
                        sm.state = states.RETURN_TO_CENTER;
                        sm.trial_count = sm.trial_count + 1;
                        sm.within_trial_frame_count = 1;
                    end
                end
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
            % TODO: stick with integer versions?
            if sm.target.vis
                rects(:, counter) = CenterRectOnPointd([0 0 mm2px(blk.target.size)], sm.target.x, sm.target.y);
                if sm.state == states.DIST_EXCEEDED
                    colors(:, counter) = 127; %TODO: don't do this
                else
                    colors(:, counter) = blk.target.color;
                end
                counter = counter + 1;
            end

            if sm.center.vis
                rects(:, counter) = CenterRectOnPointd([0 0 mm2px(blk.center.size)], sm.center.x, sm.center.y);
                colors(:, counter) = blk.center.color;
                counter = counter + 1;
            end

            if sm.ep_feedback.vis
                rects(:, counter) = CenterRectOnPointd([0 0 mm2px(blk.cursor.size)], sm.ep_feedback.x, sm.ep_feedback.y);
                colors(:, counter) = blk.cursor.color;
                counter = counter + 1;
            end

            if sm.cursor.vis
                rects(:, counter) = CenterRectOnPointd([0 0 mm2px(blk.cursor.size)], sm.cursor.x, sm.cursor.y);
                colors(:, counter) = blk.cursor.color;
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

        function val = will_be_new_trial(sm)
            % should we subset?
            val = sm.is_transitioning && (sm.state == states.RETURN_TO_CENTER || sm.state == states.END);
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
