function [r, v] = sgp4 (tsince)

% SGP4 orbit propagation

% input

%  tsince = time since initialization (minutes)

% output

%  r = position vector (kilometers)
%  v = velocity vector (km/sec)

% Orbital Mechanics with MATLAB

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% global constants

global e6a qo so tothrd x3pio2 j2 j3 j4 xke

global xkmper xmnpda ae ck2 ck4 ssgp

% initial condition globals

global xjdtle xmo xnodeo omegao eo xincl

global xno xndt2o xndd6o bstar qoms2t

% initialization globals

global xmdot omgdot xnodot xlcof aycof cosio sinio

global aodp xnodp sinmo delmo eta omgcof xmcof xnodcf isimp

global c1 c4 c5 d2 d3 d4 t2cof t3cof t4cof t5cof

global x1mth2 x3thm1 x7thm1 iflag

if (iflag == 1)
    % initialization

    a1 = (xke / xno) ^ tothrd;

    cosio = cos(xincl);

    theta2 = cosio * cosio;

    x3thm1 = 3 * theta2 - 1;

    eosq = eo * eo;

    betao2 = 1 - eosq;
    betao = sqrt(betao2);

    del1 = 1.5 * ck2 * x3thm1 / (a1 * a1 * betao * betao2);

    ao = a1 * (1 - del1 * (.5 * tothrd + del1 * (1 + 134 / 81 * del1)));
    delo = 1.5 * ck2 * x3thm1 / (ao * ao * betao * betao2);

    xnodp = xno / (1 + delo);
    aodp = ao / (1 - delo);

    isimp = 0;

    if ((aodp * (1 - eo) / ae) < (220 / xkmper + ae))
        isimp = 1;
    end

    s4 = ssgp;

    qoms24 = qoms2t;

    perige = (aodp * (1 - eo) - ae) * xkmper;

    if (perige >= 156)
        % null
    else
        s4 = perige - 78;

        if (perige > 98)
            % null
        else
            s4 = 20;
        end
        qoms24 = ((120 - s4) * ae / xkmper) ^ 4;
        s4 = s4 / xkmper + ae;
    end

    pinvsq = 1 / (aodp * aodp * betao2 * betao2);

    tsi = 1 / (aodp - s4);

    eta = aodp * eo * tsi;
    etasq = eta * eta;
    eeta = eo * eta;

    psisq = abs(1 - etasq);

    coef = qoms24 * tsi ^ 4;
    coef1 = coef / psisq ^ 3.5;

    c2 = coef1 * xnodp * (aodp * (1 + 1.5 * etasq + eeta * (4 + etasq))...
        + .75 * ck2 * tsi / psisq * x3thm1 * (8 + 3 * etasq * (8 + etasq)));

    c1 = bstar * c2;

    sinio = sin(xincl);

    a3ovk2 = -j3 / ck2 * ae ^ 3;

    c3 = coef * tsi * a3ovk2 * xnodp * ae * sinio / eo;

    x1mth2 = 1 - theta2;

    c4 = 2 * xnodp * coef1 * aodp * betao2;

    c4 = c4 * (eta * (2 + .5 * etasq) + eo * (.5 + 2 * etasq) ...
        - 2 * ck2 * tsi / (aodp * psisq) * (-3 * x3thm1 ...
        * (1 - 2 * eeta + etasq * (1.5 - .5 * eeta)) ...
        + .75 * x1mth2 * (2 * etasq - eeta * (1 + etasq)) ...
        * cos(2 * omegao)));

    c5 = 2 * coef1 * aodp * betao2 * (1 + 2.75 * (etasq + eeta) ...
        + eeta * etasq);

    theta4 = theta2 * theta2;

    temp1 = 3 * ck2 * pinvsq * xnodp;
    temp2 = temp1 * ck2 * pinvsq;
    temp3 = 1.25 * ck4 * pinvsq * pinvsq * xnodp;

    xmdot = xnodp + .5 * temp1 * betao * x3thm1 + .0625 * temp2 ...
        * betao * (13 - 78 * theta2 + 137 * theta4);

    x1m5th = 1 - 5 * theta2;

    omgdot = -.5 * temp1 * x1m5th + .0625 * temp2 ...
        * (7 - 114 * theta2 + 395 * theta4) + temp3 ...
        * (3 - 36 * theta2 + 49 * theta4);

    xhdot1 = -temp1 * cosio;

    xnodot = xhdot1 + (.5 * temp2 * (4 - 19 * theta2) ...
        + 2 * temp3 * (3 - 7 * theta2)) * cosio;

    omgcof = bstar * c3 * cos(omegao);
    xmcof = -tothrd * coef * bstar * ae / eeta;
    xnodcf = 3.5 * betao2 * xhdot1 * c1;

    t2cof = 1.5 * c1;

    xlcof = .125 * a3ovk2 * sinio * (3 + 5 * cosio) / (1 + cosio);
    aycof = .25 * a3ovk2 * sinio;

    delmo = (1 + eta * cos(xmo)) ^ 3;
    sinmo = sin(xmo);

    x7thm1 = 7 * theta2 - 1;

    if (isimp == 1)
        % null
    else
        c1sq = c1 * c1;

        d2 = 4 * aodp * tsi * c1sq;

        temp = d2 * tsi * c1 / 3;

        d3 = (17 * aodp + s4) * temp;
        d4 = .5 * temp * aodp * tsi * (221 * aodp + 31 * s4) * c1;

        t3cof = d2 + 2 * c1sq;
        t4cof = .25 * (3 * d3 + c1 * (12 * d2 + 10 * c1sq));
        t5cof = .2 * (3 * d4 + 12 * c1 * d3 + 6 * d2 * d2 ...
            + 15 * c1sq * (2 * d2 + c1sq));
    end
end

xmdf = xmo + xmdot * tsince;

omgadf = omegao + omgdot * tsince;

xnoddf = xnodeo + xnodot * tsince;

omega = omgadf;

xmp = xmdf;

tsq = tsince * tsince;

xnode = xnoddf + xnodcf * tsq;

tempa = 1 - c1 * tsince;
tempe = bstar * c4 * tsince;
templ = t2cof * tsq;

if (isimp == 1)
    % null
else
    delomg = omgcof * tsince;
    delm = xmcof * ((1 + eta * cos(xmdf)) ^ 3 - delmo);
    temp = delomg + delm;
    xmp = xmdf + temp;
    omega = omgadf - temp;
    tcube = tsq * tsince;
    tfour = tsince * tcube;
    tempa = tempa - d2 * tsq - d3 * tcube - d4 * tfour;
    tempe = tempe + bstar * c5 * (sin(xmp) - sinmo);
    templ = templ + t3cof * tcube + tfour * (t4cof + tsince * t5cof);
end

a = aodp * tempa ^ 2;

e = eo - tempe;

xl = xmp + omega + xnode + xnodp * templ;

beta = sqrt(1 - e * e);

xn = xke / a ^ 1.5;

axn = e * cos(omega);

temp = 1 / (a * beta * beta);

xll = temp * xlcof * axn;

aynl = temp * aycof;

xlt = xl + xll;

ayn = e * sin(omega) + aynl;

capu = mod(xlt - xnode, 2.0 * pi);

temp2 = capu;

% solve Kepler's equation

for i = 1:1:10
    sinepw = sin(temp2);
    cosepw = cos(temp2);

    temp3 = axn * sinepw;
    temp4 = ayn * cosepw;
    temp5 = axn * cosepw;
    temp6 = ayn * sinepw;

    epw = (capu - temp4 + temp3 - temp2) / (1 - temp5 - temp6) + temp2;

    % check for convergence

    if (abs(epw - temp2) <= e6a)
        break;
    end

    temp2 = epw;
end

ecose = temp5 + temp6;
esine = temp3 - temp4;

elsq = axn * axn + ayn * ayn;

temp = 1 - elsq;

pl = a * temp;

r = a * (1 - ecose);

temp1 = 1 / r;

rdot = xke * sqrt(a) * esine * temp1;

rfdot = xke * sqrt(pl) * temp1;

temp2 = a * temp1;

betal = sqrt(temp);

temp3 = 1 / (1 + betal);

cosu = temp2 * (cosepw - axn + ayn * esine * temp3);
sinu = temp2 * (sinepw - ayn - axn * esine * temp3);

u = atan3(sinu, cosu);

sin2u = 2 * sinu * cosu;
cos2u = 2 * cosu * cosu - 1;

temp = 1 / pl;
temp1 = ck2 * temp;
temp2 = temp1 * temp;

rk = r * (1 - 1.5 * temp2 * betal * x3thm1) ...
    + .5 * temp1 * x1mth2 * cos2u;

uk = u - .25 * temp2 * x7thm1 * sin2u;

xnodek = xnode + 1.5 * temp2 * cosio * sin2u;

xinck = xincl + 1.5 * temp2 * cosio * sinio * cos2u;

rdotk = rdot - xn * temp1 * x1mth2 * sin2u;

rfdotk = rfdot + xn * temp1 * (x1mth2 * cos2u + 1.5 * x3thm1);

sinuk = sin(uk);
cosuk = cos(uk);

sinik = sin(xinck);
cosik = cos(xinck);

sinnok = sin(xnodek);
cosnok = cos(xnodek);

xmx = -sinnok * cosik;
xmy = cosnok * cosik;

ux = xmx * sinuk + cosnok * cosuk;
uy = xmy * sinuk + sinnok * cosuk;
uz = sinik * sinuk;

vx = xmx * cosuk - cosnok * sinuk;
vy = xmy * cosuk - sinnok * sinuk;
vz = sinik * cosuk;

% position vector

r(1) = rk * ux * xkmper;
r(2) = rk * uy * xkmper;
r(3) = rk * uz * xkmper;

% velocity vector

const = xkmper / ae * xmnpda / 86400;

v(1) = const * (rdotk * ux + rfdotk * vx);
v(2) = const * (rdotk * uy + rfdotk * vy);
v(3) = const * (rdotk * uz + rfdotk * vz);


