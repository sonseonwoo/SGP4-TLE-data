% demo_sv2tle1.m        December 27, 2022

% convert eci state vector to two line element set
% (TLE) using SGP4 algorithm and fsolve

% Orbital Mechanics with MATLAB

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;

global dtr rtd req mu

global e6a qo so tothrd x3pio2 j2 j3 j4 xke

global xkmper xmnpda ae ck2 ck4 ssgp qoms2t

global ri vi

global xmo xnodeo omegao eo xincl

global xno xndt2o xndd6o bstar

% SGP4 utility constants

e6a = 0.000001;
qo = 120.0;
so = 78.0;
tothrd = 2.0 / 3.0;
x3pio2 = 3.0 * pi / 2.0;
j2 = 0.0010826158;
j3 = -0.00000253881;
j4 = -0.00000165597;
xke = 0.0743669161;
xkmper = 6378.135;
xmnpda = 1440.0;
ae = 1.0;
ck2 = 0.5 * j2 * ae * ae;
ck4 = -0.375 * j4 * ae * ae * ae * ae;
ssgp = ae * (1.0 + so / xkmper);
qoms2t = ((qo - so) * ae / xkmper) ^ 4;

% astrodynamic and utility constants

req = 6378.14;

mu = 398600.5;

omega = 7.2921151467e-5;

dtr = pi / 180.0;

rtd = 180.0 / pi;

pi2 = 2.0 * pi;

x = zeros(6, 1);

% begin simulation

clc; home;

fprintf('\ndemo_sv2tle1 - convert state vector to TLE \n');

fprintf('\nplease input the name of this satellite\n');

satname = input('? ', 's');

fprintf('\nTLE calendar date and universal time\n');

[mtle, dtle, ytle] = getdate;

[tlehr, tlemin, tlesec] = gettime;

% julian date of tle

jdtle = julian(mtle, dtle, ytle) ...
    + tlehr / 24.0 + tlemin / 1440.0 + tlesec / 86400.0;

% tle day-of-year

tledoy = jdtle - julian(1, 0, ytle);

while (1)
    
    fprintf('\n        user input menu\n');

    fprintf('\n <1> user input of state vector\n');

    fprintf('\n <2> user input of orbital elements\n\n');

    slct = input('? ');

    if (slct == 1 || slct == 2)
        
        break;
        
    end
    
end

if (slct == 1)
    
    % request state vector
    
    [ri, vi] = getsv;

    oev = eci2orb1(mu, ri, vi);
    
else
    
    % request classical orbiutal elements
    
    oev = getoe([1;1;1;1;1;1]);

    [ri, vi] = orb2eci(mu, oev);
    
end

% load initial orbital elements

sma = oev(1);
ecc = oev(2);
xinc = oev(3);
argper = oev(4);
raan = oev(5);
tanom = oev(6);

if (ecc == 0.0)
    
    ecc = 1.0e-8;
    
    oev(2) = ecc;
    
end

% compute mean anomaly (radians)

a = sqrt(1.0 - oev(2) * oev(2)) * sin(oev(6));

b = cos(oev(6)) + oev(2);

eanom = atan3(a, b);

manom = mod(eanom - oev(2) * sin(eanom), pi2);

% compute mean motion

xmm = sqrt(mu / sma^3);

% initial guess for norad mean elements

xincl = xinc;
omegao = argper;
xnodeo = raan;
eo = ecc;
xmo = manom;
xno = xmm * 86400.0 / pi2;

temp = pi2 / xmnpda / xmnpda;

xno = xno * temp * xmnpda;

bstar = 0.0;

xndt2o = 0.0;

xndd6o = 0.0;

% load initial guess vector

x(1) = xincl;
x(2) = omegao;
x(3) = xnodeo;
x(4) = eo;
x(5) = xmo;
x(6) = xno;

% solve system of nonlinear equations

[xf] = fsolve('tlefunc', x);

% load "solved-for" norad elements

xincl = xf(1) * rtd;
omegao = mod(xf(2), pi2) * rtd;
xnodeo = mod(xf(3), pi2) * rtd;
eo = xf(4);
eo = abs(eo);
xmo = mod(xf(5), pi2) * rtd;
xno = xf(6);

% print tle

fprintf('\nosculating state vector \n');

svprint(ri, vi);

fprintf('\nosculating orbital elements \n');

oeprint1(mu, oev, 1);

fprintf('\n\nTwo Line Element set \n\n');

% display line 0

disp(upper(satname));

% display line 1

fprintf('1 XXXXXU XXXXXXXX %g%012.8f .00000000   00000-0  00000-0 \n', ...
    (ytle - 1900), tledoy);

% display line 2

fprintf('2 XXXXX %8.4f %8.4f %07.0f %8.4f %8.4f %11.8f \n\n', ...
    xincl, xnodeo, eo * 10000000, omegao, xmo, xno / (temp * xmnpda));



