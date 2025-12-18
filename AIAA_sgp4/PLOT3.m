% -------------------------------------------------------------------------
% PLOT_ORBITAL_ELEMENTS.m (Modified for Argument of Latitude)
% -------------------------------------------------------------------------
% 기능:
%   1. MAIN2 코드로 생성된 SGP4 전파 결과(txt) 로드
%   2. 위치/속도 벡터(RV)를 궤도요소(COE)로 변환
%   3. 6개 궤도요소 변화 그래프 생성 (w 대신 u = w+M 사용)
% -------------------------------------------------------------------------
clear; clc; close all;

%% 1. 분석할 파일 선택
% -------------------------------------------------------------------------
% target_file = 'Result_BEE1000_TLE.txt'; 
target_file = 'Result_COSMIC_TLE.txt'; 
% -------------------------------------------------------------------------

fprintf('================================================================\n');
fprintf('             ORBITAL ELEMENT ANALYSIS & PLOTTING                \n');
fprintf('================================================================\n');
fprintf('Target File: %s\n', target_file);

%% 2. 데이터 로드
try
    data_struct = importdata(target_file);
    raw_data = data_struct.data; % [Time, Rx, Ry, Rz, Vx, Vy, Vz]
catch
    error('파일을 읽을 수 없습니다. MAIN2 코드가 먼저 실행되었는지 확인하세요.');
end

t_min = raw_data(:, 1);              % 시간 (분)
t_days = t_min / 1440.0;             % 시간 (일)
R_vec = raw_data(:, 2:4);            % 위치 벡터
V_vec = raw_data(:, 5:7);            % 속도 벡터
num_steps = length(t_min);

fprintf('  - Data Loaded: %d steps (Duration: %.2f days)\n', num_steps, t_days(end));

%% 3. RV -> COE 변환
coe_results = zeros(num_steps, 6);
mu = 398600.8; 

fprintf('  - Converting RV to Keplerian Elements...\n');
for k = 1:num_steps
    r = R_vec(k, :);
    v = V_vec(k, :);
    [~, a, ecc, incl, raan, argp, ~, m, ~, ~, ~] = rv2coe(r, v, mu);
    
    rad2deg = 180/pi;
    coe_results(k, 1) = a;                  
    coe_results(k, 2) = ecc;                
    coe_results(k, 3) = incl * rad2deg;     
    coe_results(k, 4) = raan * rad2deg;     
    coe_results(k, 5) = argp * rad2deg;     % omega
    coe_results(k, 6) = m    * rad2deg;     % M
end

% Mean Motion (n) 계산
n_rad_sec = sqrt(mu ./ (coe_results(:,1).^3));
n_rev_day = n_rad_sec * (86400 / (2*pi));

% [중요] 위도 인수 (Argument of Latitude, u) 계산
% u = omega + Mean Anomaly (mod 360)
arg_lat = mod(coe_results(:, 5) + coe_results(:, 6), 360);

fprintf('  - Conversion Complete (Calculated Arg of Latitude).\n');

%% 4. 그래프 그리기 (Days 단위 - 장기 변화)
figure('Name', ['Orbital Elements: ' target_file], 'Color', 'w', 'Position', [100 100 1200 800]);

% (1) Semi-major Axis (a)
subplot(2, 3, 1);
plot(t_days, coe_results(:, 1), 'b-', 'LineWidth', 1.5);
title('Semi-major Axis (a)'); xlabel('Time (Days)'); ylabel('a (km)'); grid on;

% (2) Eccentricity (e)
subplot(2, 3, 2);
plot(t_days, coe_results(:, 2), 'r-', 'LineWidth', 1.5);
title('Eccentricity (e)'); xlabel('Time (Days)'); ylabel('Eccentricity'); grid on;

% (3) Inclination (i)
subplot(2, 3, 3);
plot(t_days, coe_results(:, 3), 'k-', 'LineWidth', 1.5);
title('Inclination (i)'); xlabel('Time (Days)'); ylabel('i (deg)'); grid on;

% (4) RAAN (Omega)
subplot(2, 3, 4);
plot(t_days, coe_results(:, 4), 'm-', 'LineWidth', 1.5);
title('RAAN (\Omega)'); xlabel('Time (Days)'); ylabel('\Omega (deg)'); grid on;

% (5) Argument of Latitude (u) [수정됨]
subplot(2, 3, 5);
plot(t_days, arg_lat, 'g-', 'LineWidth', 1.5);
title('Arg of Latitude (u = \omega + M)'); % 제목 변경
xlabel('Time (Days)'); ylabel('u (deg)');
grid on; ylim([0 360]); % 0~360도 범위 고정

% (6) Mean Motion (n)
subplot(2, 3, 6);
plot(t_days, n_rev_day, 'c-', 'LineWidth', 1.5);
title('Mean Motion (n)'); xlabel('Time (Days)'); ylabel('n (rev/day)'); grid on;

sgtitle(['Evolution of Orbital Elements: ' strrep(target_file, '_', '\_')], 'FontSize', 16, 'FontWeight', 'bold');

%% 5. 그래프 그리기 (Hours 단위 - 단주기 분석)
t_hours = t_min / 60.0;
figure('Name', ['Short-Period Analysis: ' target_file], 'Color', 'w', 'Position', [150 150 1200 800]);

% (1) ~ (4) 동일
subplot(2, 3, 1); plot(t_hours, coe_results(:, 1), 'b-'); title('Semi-major Axis (a)'); xlabel('Hours'); grid on; xlim([0, 24]);
subplot(2, 3, 2); plot(t_hours, coe_results(:, 2), 'r-'); title('Eccentricity (e)'); xlabel('Hours'); grid on; xlim([0, 24]);
subplot(2, 3, 3); plot(t_hours, coe_results(:, 3), 'k-'); title('Inclination (i)'); xlabel('Hours'); grid on; xlim([0, 24]);
subplot(2, 3, 4); plot(t_hours, coe_results(:, 4), 'm-'); title('RAAN (\Omega)'); xlabel('Hours'); grid on; xlim([0, 24]);

% (5) Argument of Latitude (u) [수정됨]
subplot(2, 3, 5);
plot(t_hours, arg_lat, 'g-', 'LineWidth', 1.5);
title('Arg of Latitude (u)'); 
xlabel('Time (Hours)'); ylabel('u (deg)');
grid on; xlim([0, 24]); ylim([0 360]);

% (6) Mean Motion
subplot(2, 3, 6); plot(t_hours, n_rev_day, 'c-'); title('Mean Motion (n)'); xlabel('Hours'); grid on; xlim([0, 24]);

sgtitle(['Short-Period Variations (24 Hours): ' strrep(target_file, '_', '\_')], 'FontSize', 16, 'FontWeight', 'bold');

%% 6. 초단기 정밀 분석 (1시간 확대)
idx_1hr = find(t_min <= 60); 
if isempty(idx_1hr), idx_1hr = 1:length(t_min); end

t_1hr_min = t_min(idx_1hr);
coe_1hr   = coe_results(idx_1hr, :);
n_1hr     = n_rev_day(idx_1hr);
u_1hr     = arg_lat(idx_1hr); % 위도 인수 슬라이싱

figure('Name', ['Detailed Analysis (1 Hour): ' target_file], 'Color', 'w', 'Position', [200 200 1200 800]);

subplot(2, 3, 1); plot(t_1hr_min, coe_1hr(:, 1), 'b.-'); title('Semi-major Axis (a)'); xlabel('Min'); grid on; xlim([0, 60]);
subplot(2, 3, 2); plot(t_1hr_min, coe_1hr(:, 2), 'r.-'); title('Eccentricity (e)'); xlabel('Min'); grid on; xlim([0, 60]);
subplot(2, 3, 3); plot(t_1hr_min, coe_1hr(:, 3), 'k.-'); title('Inclination (i)'); xlabel('Min'); grid on; xlim([0, 60]);
subplot(2, 3, 4); plot(t_1hr_min, coe_1hr(:, 4), 'm.-'); title('RAAN (\Omega)'); xlabel('Min'); grid on; xlim([0, 60]);

% (5) Argument of Latitude (u) [수정됨]
subplot(2, 3, 5);
plot(t_1hr_min, u_1hr, 'g.-', 'LineWidth', 1.0, 'MarkerSize', 8);
title('Arg of Latitude (u)');
xlabel('Time (Minutes)'); ylabel('u (deg)');
grid on; xlim([0, 60]); ylim([0 360]);

subplot(2, 3, 6); plot(t_1hr_min, n_1hr, 'c.-'); title('Mean Motion (n)'); xlabel('Min'); grid on; xlim([0, 60]);

sgtitle(['Detailed Short-Period (First 60 Mins): ' strrep(target_file, '_', '\_')], 'FontSize', 16, 'FontWeight', 'bold');

fprintf('\nAll Plots Updated with Argument of Latitude (u).\n');

%% Helper Function
function [p, a, ecc, incl, omega, argp, nu, m, arglat, truelon, lonper] = rv2coe(rvec, vvec, mu)
    r = norm(rvec); v = norm(vvec);
    hvec = cross(rvec, vvec); h = norm(hvec);
    nvec = cross([0 0 1], hvec); n = norm(nvec);
    evec = (1/mu)*((v^2 - mu/r)*rvec - dot(rvec, vvec)*vvec);
    ecc = norm(evec);
    xi = v^2/2 - mu/r;
    if abs(ecc - 1.0) > 1e-10, a = -mu / (2*xi); p = a * (1 - ecc^2);
    else, a = Inf; p = h^2/mu; end
    incl = acos(hvec(3)/h);
    if n ~= 0
        omega = acos(nvec(1)/n);
        if nvec(2) < 0, omega = 2*pi - omega; end
    else, omega = 0; end
    if n ~= 0
        if ecc > 1e-10
            argp = acos(dot(nvec, evec) / (n*ecc));
            if evec(3) < 0, argp = 2*pi - argp; end
        else, argp = 0; end
    else
        if ecc > 1e-10
            argp = acos(evec(1)/ecc);
            if evec(2) < 0, argp = 2*pi - argp; end
        else, argp = 0; end
    end
    if ecc > 1e-10
        nu = acos(dot(evec, rvec) / (ecc*r));
        if dot(rvec, vvec) < 0, nu = 2*pi - nu; end
    else
        if n ~= 0
             angle = acos(dot(nvec, rvec)/(n*r));
             if rvec(3) < 0, angle = 2*pi - angle; end
             nu = angle - argp; 
        else
             nu = acos(rvec(1)/r);
             if rvec(2) < 0, nu = 2*pi - nu; end
        end
    end
    if ecc < 1.0
        sine = (sqrt(1-ecc^2)*sin(nu)) / (1+ecc*cos(nu));
        cose = (ecc + cos(nu)) / (1+ecc*cos(nu));
        E = atan2(sine, cose);
        m = E - ecc*sin(E);
    else, m = 0; end
    if m < 0, m = m + 2*pi; end
    arglat = 0; truelon = 0; lonper = 0;
end