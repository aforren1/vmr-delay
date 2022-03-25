function is_inside = point_in_circle(pt_xy, circle_xy, circle_rad)
    % https://math.stackexchange.com/a/198769
    %is_inside = ((pt_xy(1) - circle_xy(1))^2 + (pt_xy(2) - circle_xy(2))^2) < (circle_rad^2);
    dx = abs(pt_xy(1) - circle_xy(1));
    dy = abs(pt_xy(2) - circle_xy(2));
    is_inside = (dx*dx + dy*dy) < circle_rad*circle_rad;
end
