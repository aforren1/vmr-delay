screens = Screen('Screens');
max_scr = max(screens);

w = struct();
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'UseDisplayRotation', 180);
[w.w, w.rect] = PsychImaging('OpenWindow', max_scr, 0);

[w.center(1), w.center(2)] = RectCenter(w.rect);

# draw a 1cm square at center of screen
# pixel pitch (center of one px to next) is 0.2832 mm x 0.2802 mm
# screen is 1920x1080 (16:9 aspect), w=543.7mm, h=302.6mm
# according to mechanical drawing
# 

x_mm2px = @(mm) (mm / 0.2832);
y_mm2px = @(mm) (mm / 0.2802);
mm2px = @(mm) (mm ./ [0.2832, 0.2802]);
# draw a 10cm^2 square to measure
rct = [0 0 mm2px([100 100])];
Screen('FillRect', w.w, [255 255 255], CenterRectOnPoint(rct, w.center(1), w.center(2)));

Screen('Flip', w.w);

WaitSecs(20);
sca;
