
maxval = 10000;

disp('rev');
tic;

for i = maxval:-1:1
    y(i).x = 0;
    y(i).y = 0;
end
toc;
disp(sizeof(y));


disp('forward');
tic;
x = struct('x', 0, 'y', 0);
for i = 2:maxval
    x(i).x = 0;
    x(i).y = 0;
end
toc;
disp(sizeof(x));

disp('struct of arrays');
tic;
w = struct('x', zeros(maxval, 1), 'y', zeros(maxval, 1));
toc;

disp('copy');
tic;
z = x(1:maxval*0.5);
toc;

disp(sizeof(z));
% prove to myself a copy is made
z(5).x = 3;
disp(x(5).x == z(5).x);

% huh, I thought this would be a cache thing but
% struct of arrays even wins here
disp('access array of structs');
tic;
for i = 1:maxval
    y(i).x = i;
    y(i).y = i+1;
end
toc;

disp('access struct of arrays');
tic;
for i = 1:maxval
    w.x(i) = i;
    w.y(i) = i+1;
end
toc;
