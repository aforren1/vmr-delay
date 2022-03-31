
% any reason to use handle? we're never passing this anywhere...
classdef StateMachine < handle

    properties
        trial_start_time = 9e99
    end

    properties (Access = private)
        state = states.RETURN_TO_CENTER
        is_transitioning = true
        w % window struct (read-only)
        tgt % target table
        un % unit handler
        audio % audio handler
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
        last_event = struct('x', 0, 'y', 0);
        slow_txt_vis = false;
        hold_time = 0
        vis_time = 0
        targ_dist_px = 0
        feedback_dur = 0
        post_dur = 0
        target_on_time = 0
        coarse_rt = 0
        coarse_mv_start = 0
        coarse_mt = 0
        debounce = true
        too_slow = 0
        starting_pos
        delayed_pos
        summary_data
    end

    methods

        function sm = StateMachine(path, tgt, win_info, unit)
            sm.w = win_info;
            sm.tgt = tgt;
            sm.un = unit;
            sm.audio = AudioManager();
            sm.audio.add(fullfile(path, 'media', 'speed_up.wav'), 'speed_up');
            % keep track of trial summary data here, and write out later
            % sm.summary_data(1:length(tgt.trial)) = struct(...
            %   'ep_angle_deg', 0, ... % angle of endpoint feedback in degrees, relative to target
            %   'cur_angle_deg', 0, ... % angle of cursor in degrees, relative to target (will ~= ep_angle_deg if clamp)

            % );
        end

        function update(sm, evts, last_vbl)
            % NB: evt might be empty
            % This function only runs once a frame on the latest input event

            % one thing to think about-- should we allow this sort of "fall through", or
            % should each state exist for at least one frame? If we have drawing tied to
            % state, it suggests the latter (as we can't undo draw calls)
            % the other thing to keep in mind is that drawing is more "immediate" than what I tend to do
            sm.within_trial_frame_count = sm.within_trial_frame_count + 1;
            w = sm.w;
            tgt = sm.tgt;
            trial = tgt.trial(sm.trial_count);
            if ~isempty(evts) % non-empty event
                sm.cursor.x = evts(end).x;
                sm.cursor.y = evts(end).y;
                sm.last_event.x = sm.cursor.x;
                sm.last_event.y = sm.cursor.y;
            else
                sm.cursor.x = sm.last_event.x;
                sm.cursor.y = sm.last_event.y;
            end

            est_next_vbl = last_vbl + w.ifi;
            if sm.state == states.RETURN_TO_CENTER
                if sm.entering()
                    % set the state you want, not the one you expect
                    sm.cursor.vis = false;
                    sm.center.vis = true;
                    sm.ep_feedback.vis = false;
                    sm.target.vis = false;
                    sm.center.x = w.center(1) + sm.un.x_mm2px(tgt.block.center.offset.x);
                    sm.center.y = w.center(2) + sm.un.y_mm2px(tgt.block.center.offset.y);
                    sm.hold_time = est_next_vbl + 0.2;
                    sm.vis_time = est_next_vbl + 0.5;
                    sm.trial_start_time = est_next_vbl;
                    sm.debounce = true;
                    sm.too_slow = 0;
                end
                % stuff that runs every frame
                if point_in_circle([sm.cursor.x sm.cursor.y], [sm.center.x sm.center.y], ...
                                   sm.un.x_mm2px(tgt.block.target.distance * 0.25))
                    sm.cursor.vis = true;
                else
                    sm.cursor.vis = false;
                end
                % transition conditions
                % hold in center for 200 ms
                % this was a good example of mm<->px conversion woes, is there a more intuitive way
                % (have *everything* be in mm until draw time??)
                if point_in_circle([sm.cursor.x sm.cursor.y], [sm.center.x sm.center.y], ...
                                   sm.un.x_mm2px(tgt.block.center.size - tgt.block.cursor.size) * 0.5)
                    if ~sm.debounce && est_next_vbl >= sm.hold_time
                        sm.state = states.REACH;
                    end
                else
                    sm.hold_time = est_next_vbl + 0.2; % 200 ms in the future
                    sm.debounce = false;
                end
            end

            if sm.state == states.REACH

                if sm.entering()
                    sm.target.vis = true;
                    t = trial.target;
                    sm.target.x = sm.un.x_mm2px(t.x) + sm.center.x;
                    sm.target.y = sm.un.y_mm2px(t.y) + sm.center.y;
                    sm.target_on_time = est_next_vbl;
                    sm.coarse_rt = 0;
                    sm.coarse_mv_start = 0;
                    sm.coarse_mt = 0;
                    sm.targ_dist_px = distance(sm.target.x, sm.center.x, sm.target.y, sm.center.y);
                    sm.cursor.vis = trial.online_feedback;
                    sm.starting_pos = sm.cursor;
                    if trial.delay > 0
                        % initialize a FIFO with max length corresponding to specified delay
                        % given seconds, how many frames?
                        sz = floor(1/w.ifi * trial.delay);
                        sm.delayed_pos = nan(sz, 2);
                    end
                end

                if trial.delay > 0
                    % TODO: double check we're not accidentally a frame early?
                    % NB: this is also not robust to frame drops. Should we do timestamp-based instead?
                    sm.delayed_pos(1:end-1, :) = sm.delayed_pos(2:end, :);
                    sm.delayed_pos(end, 1) = sm.cursor.x;
                    sm.delayed_pos(end, 2) = sm.cursor.y;
                    if ~isnan(sm.delayed_pos(1, 1))
                        sm.cursor.x = sm.delayed_pos(1, 1);
                        sm.cursor.y = sm.delayed_pos(1, 2);
                    else
                        % lock in place if we haven't moved yet
                        sm.cursor.x = sm.starting_pos.x;
                        sm.cursor.y = sm.starting_pos.y;
                    end

                end

                cur_dist = distance(sm.cursor.x, sm.center.x, sm.cursor.y, sm.center.y);

                if trial.online_feedback
                    cur_theta = atan2(sm.cursor.y - sm.center.y, sm.cursor.x - sm.center.x);
                    if trial.is_manipulated
                        %TODO: implement rotation
                        % get angle of target in deg, add clamp offset, then to rad
                        target_angle = atan2d(sm.target.y - sm.center.y, sm.target.x - sm.center.x);
                        theta = deg2rad(target_angle + trial.manipulation_angle);
                    else
                        theta = cur_theta;
                    end
                    sm.cursor.x = cur_dist * cos(theta) + sm.center.x;
                    sm.cursor.y = cur_dist * sin(theta) + sm.center.y;
                end

                if ~sm.coarse_rt && cur_dist >= sm.un.x_mm2px(tgt.block.center.size * 0.5)
                    % this is not a good RT to use for analysis, only for feedback purposes
                    % note that it's framerate-dependent, and only indirectly involves the current
                    % state of the input device
                    sm.coarse_rt = est_next_vbl - sm.target_on_time;
                    sm.coarse_mv_start = est_next_vbl;
                    % add trial delay here, so that they're not penalized by lagged cursor
                    if sm.coarse_rt > (tgt.block.max_rt + trial.delay)
                        sm.state = states.BAD_MOVEMENT;
                    end
                end

                if cur_dist >= sm.targ_dist_px
                    % same goes for MT-- do analysis on something thoughtful
                    sm.coarse_mt = est_next_vbl - sm.coarse_mv_start;
                    if sm.coarse_mt > (tgt.block.max_mt + trial.delay)
                        sm.state = states.BAD_MOVEMENT;
                    else
                        sm.state = states.DIST_EXCEEDED;
                    end
                end

                if (est_next_vbl - sm.target_on_time) > tgt.block.max_rt
                    sm.state = states.BAD_MOVEMENT;
                end

            end

            if sm.state == states.DIST_EXCEEDED
                if sm.entering()
                    sm.cursor.vis = false;
                    sm.feedback_dur = tgt.block.feedback_duration + est_next_vbl;
                    if trial.endpoint_feedback
                        sm.ep_feedback.vis = true;
                        cur_theta = atan2(sm.cursor.y - sm.center.y, sm.cursor.x - sm.center.x);
                        if trial.is_manipulated
                            %TODO: implement rotation
                            %TODO: implement delay
                            % get angle of target in deg, add clamp offset, then to rad
                            target_angle = atan2d(sm.target.y - sm.center.y, sm.target.x - sm.center.x);
                            theta = deg2rad(target_angle + trial.manipulation_angle);
                        else
                            theta = cur_theta;
                        end
                        % use earlier sm.targ_dist_px for extent
                        sm.ep_feedback.x = sm.targ_dist_px * cos(theta) + sm.center.x;
                        sm.ep_feedback.y = sm.targ_dist_px * sin(theta) + sm.center.y;
                    end
                end
                % transition?
                sm.state = states.FEEDBACK;
            end

            if sm.state == states.BAD_MOVEMENT
                if sm.entering()
                    sm.audio.play('speed_up'); %TODO: any need to actually synchronize with screen?
                    sm.cursor.vis = false;
                    sm.ep_feedback.vis = false;
                    sm.target.vis = false;
                    sm.center.vis = false;
                    sm.feedback_dur = tgt.block.feedback_duration + est_next_vbl;
                    sm.slow_txt_vis = true;
                    sm.too_slow = 1;
                end
                sm.state = states.FEEDBACK;
            end

            if sm.state == states.FEEDBACK
                if est_next_vbl >= sm.feedback_dur
                    sm.target.vis = false;
                    sm.slow_txt_vis = false;
                    % wait another chunk to even out iti between groups
                    sm.post_dur = est_next_vbl + tgt.block.extra_delay;
                    % end of the trial, are we done?
                    if est_next_vbl >= sm.post_dur
                        if (sm.trial_count + 1) > length(tgt.trial)
                            sm.state = states.END;
                        else
                            sm.state = states.RETURN_TO_CENTER;
                            sm.trial_count = sm.trial_count + 1;
                            sm.within_trial_frame_count = 1;
                        end
                    end
                end
            end

            % process delayed events
        end

        function draw(sm)
            % drawing; keep order in mind?
            MAX_NUM_CIRCLES = 4; % max 4 circles ever
            xys = zeros(2, MAX_NUM_CIRCLES);
            sizes = zeros(1, MAX_NUM_CIRCLES);
            colors = zeros(3, MAX_NUM_CIRCLES, 'uint8'); % rgb255
            counter = 1;
            blk = sm.tgt.block;
            w = sm.w;
            % TODO: stick with integer versions of CenterRectOnPoint*?
            if sm.target.vis
                xys(:, counter) = [sm.target.x sm.target.y];
                sizes(counter) = sm.un.x_mm2px(blk.target.size);
                if sm.state == states.FEEDBACK
                    colors(:, counter) = 127; %TODO: don't do this, set it from elsewhere
                else
                    colors(:, counter) = blk.target.color;
                end
                counter = counter + 1;
            end

            if sm.center.vis
                xys(:, counter) = [sm.center.x sm.center.y];
                sizes(counter) = sm.un.x_mm2px(blk.center.size);
                colors(:, counter) = blk.center.color;
                counter = counter + 1;
            end

            if sm.ep_feedback.vis
                xys(:, counter) = [sm.ep_feedback.x sm.ep_feedback.y];
                sizes(counter) = sm.un.x_mm2px(blk.cursor.size);
                colors(:, counter) = blk.cursor.color;
                counter = counter + 1;
            end

            if sm.cursor.vis
                xys(:, counter) = [sm.cursor.x sm.cursor.y];
                sizes(counter) = sm.un.x_mm2px(blk.cursor.size);
                colors(:, counter) = blk.cursor.color;
                counter = counter + 1;
            end

            if sm.slow_txt_vis
                DrawFormattedText(w.w, 'Please reach sooner and/or faster.', 'center', 0.4 * w.rect(4), [222, 75, 75]);
            end
            % draw all circles together; never any huge circles, so we only need nice-looking up to a point
            %Screen('FillOval', w.w, colors, rects, floor(w.rect(4) * 0.25));
            Screen('DrawDots', w.w, xys(:, 1:counter), sizes(1:counter), colors(:, 1:counter), [], 3, 1);
            % draw trial counter in corner
            Screen('DrawText', w.w, sprintf('%i/%i', sm.trial_count, length(sm.tgt.trial)), 10, 10, 128);
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

        % compute where cursor & target are in mm relative to center (which is assumed to be fixed)
        function cur = get_cursor_state(sm)
            cur = sm.center_and_mm(sm.cursor, sm.center);
        end

        function tar = get_target_state(sm)
            tar = sm.center_and_mm(sm.target, sm.center);
        end

        function ep = get_ep_state(sm)
            ep = sm.center_and_mm(sm.ep_feedback, sm.center);
        end

        function restart_trial(sm)
            % restart the current trial
            sm.state = states.RETURN_TO_CENTER;
            sm.within_trial_frame_count = 1;
            sm.trial_start_time = 9e99; % single-frame escape hatch
        end

        function val = was_too_slow(sm)
            val = sm.too_slow;
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

        function v1 = center_and_mm(sm, v1, v2)
            v1.x = sm.un.x_px2mm(v1.x - v2.x);
            v1.y = sm.un.y_px2mm(v1.y - v2.y);
        end
    end
end
