function dist = distance(x, x0, y, y0)
    dx = x - x0;
    dy = y - y0;
    dist = sqrt(dx*dx + dy*dy);
end