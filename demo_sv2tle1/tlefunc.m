function y = tlefunc(x)

% TLE objective function

% required by sv2tle.m

% input

%  x = vector of current dependent variables

% output

%  y = function value vector evaluated at x

% Orbital Mechanics with MATLAB

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global iflag ri vi

global xmo xnodeo omegao eo xincl

global xno xndt2o xndd6o bstar

pi2 = 2.0 * pi;

y = zeros(6, 1);

% "unload" current orbital elements

xincl = x(1);
omegao = mod(x(2), pi2);
xnodeo = mod(x(3), pi2);
eo = x(4);
xmo = mod(x(5), pi2);
xno = x(6);

% zero "unknown" tle elements

bstar = 0;

xndt2o = 0;

xndd6o = 0;

% call sgp4 algorithm and compute state vector

iflag = 1;

tsince = 0;

[rtmp, vtmp] = sgp4(tsince);

% define system of nonlinear equations

y(1) = ri(1) - rtmp(1);
y(2) = ri(2) - rtmp(2);
y(3) = ri(3) - rtmp(3);

y(4) = vi(1) - vtmp(1);
y(5) = vi(2) - vtmp(2);
y(6) = vi(3) - vtmp(3);




