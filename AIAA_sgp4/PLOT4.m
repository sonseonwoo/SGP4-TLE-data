% -------------------------------------------------------------------------
% PLOT_ORBITAL_TRENDS.m (Modified for Argument of Latitude)
% -------------------------------------------------------------------------
% 기능:
%   1. MAIN2 결과 파일(*.txt) 로드
%   2. Osculating Elements(단주기 포함)로 변환 -> [회색 그래프]
%   3. Moving Average를 통해 Mean Elements(추세) 추출 -> [빨간색 그래프]
%   4. w(튀는 값) 대신 u = w+M (안정적인 값)을 사용하여 시각화
% -------------------------------------------------------------------------
clear; clc; close all;

%% 1. 분석할 파일 선택
% -------------------------------------------------------------------------
% target_file = 'Result_BEE1000_TLE.txt'; 
target_file = 'Result_COSMIC_TLE.txt'; 
% -------------------------------------------------------------------------

fprintf('================================================================\n');
fprintf('             ORBITAL TREND ANALYSIS (Gray vs Red)               \n');
fprintf('================================================================\n');
fprintf('Target File: %s\n', target_file);

%% 2. 데이터 로드
try
    data_struct = importdata(target_file);
    raw_data = data_struct.data; 
catch
    error('파일을 읽을 수 없습니다. MAIN2 코드가 먼저 실행되었는지 확인하세요.');
end

t_min = raw_data(:, 1);
t_days = t_min / 1440.0;
R_vec = raw_data(:, 2:4);
V_vec = raw_data(:, 5:7);
num_steps = length(t_min);

fprintf('  - Data Loaded: %d steps (Duration: %.2f days)\n', num_steps, t_days(end));

%% 3. RV -> Osculating COE 변환
osc_results = zeros(num_steps, 6); % [a, e, i, RAAN, w, M]
mu = 398600.8; 

for k = 1:num_steps
    [~, a, ecc, incl, raan, argp, ~, m, ~, ~, ~] = rv2coe(R_vec(k,:), V_vec(k,:), mu);
    osc_results(k, :) = [a, ecc, rad2deg(incl), rad2deg(raan), rad2deg(argp), rad2deg(m)];
end

% Mean Motion (n) 계산
n_osc = sqrt(mu ./ (osc_results(:,1).^3)) * (86400 / (2*pi)); % rev/day

% [중요] Osculating Argument of Latitude (u) 계산
% u = omega + M (Raw Data)
u_osc_raw = osc_results(:, 5) + osc_results(:, 6); 

fprintf('  - Osculating Elements Calculated.\n');

%% 4. 추세(Trend) 추출: 이동 평균 (Moving Average)
window_size = 100; % 약 100분 (SGP4 dt=1분 기준)

fprintf('  - Extracting Secular Trends (Moving Average, Window=%d)...\n', window_size);

mean_results = zeros(size(osc_results));
mean_n = zeros(size(n_osc));
mean_u = zeros(size(u_osc_raw)); % u에 대한 추세 저장 변수

% (A) 기본 6요소 추세 추출
for i = 1:6
    data = osc_results(:, i);
    if i >= 3 
        data_rad = deg2rad(data);
        data_unwrap = unwrap(data_rad);
        trend_unwrap = movmean(data_unwrap, window_size);
        mean_results(:, i) = rad2deg(trend_unwrap); 
    else
        mean_results(:, i) = movmean(data, window_size);
    end
end
mean_n = movmean(n_osc, window_size);

% (B) [중요] Argument of Latitude (u) 추세 추출
% u는 360도를 계속 넘어가며 증가하므로 Unwrap -> Avg -> Wrap 과정 필요
u_rad = deg2rad(u_osc_raw);
u_unwrap = unwrap(u_rad);           % 점프 제거
u_mean_unwrap = movmean(u_unwrap, window_size); % 이동 평균
mean_u = rad2deg(u_mean_unwrap);    % 결과 저장 (Unwrapped 상태)

%% 5. 시각화 (Trend Analysis Plot)
col_osc = [0.6 0.6 0.6]; % 진한 회색
col_trend = [0.8 0 0];   % 빨간색
lw_trend = 1.5;          % 추세선 두께

figure('Name', ['Trend Analysis: ' target_file], 'Color', 'w', 'Position', [100 100 1200 800]);

% (1) Semi-major Axis (a)
subplot(2, 3, 1); hold on; grid on;
plot(t_days, osc_results(:, 1), 'Color', col_osc, 'LineWidth', 0.5);
plot(t_days, mean_results(:, 1), 'Color', col_trend, 'LineWidth', lw_trend);
title('Semi-major Axis (a)'); xlabel('Time (Days)'); ylabel('a (km)');
legend('Osculating', 'Mean Trend', 'Location', 'best');

% (2) Eccentricity (e)
subplot(2, 3, 2); hold on; grid on;
plot(t_days, osc_results(:, 2), 'Color', col_osc, 'LineWidth', 0.5);
plot(t_days, mean_results(:, 2), 'Color', col_trend, 'LineWidth', lw_trend);
title('Eccentricity (e)'); xlabel('Time (Days)'); ylabel('Eccentricity');

% (3) Inclination (i)
subplot(2, 3, 3); hold on; grid on;
plot(t_days, osc_results(:, 3), 'Color', col_osc, 'LineWidth', 0.5);
plot(t_days, mean_results(:, 3), 'Color', col_trend, 'LineWidth', lw_trend);
title('Inclination (i)'); xlabel('Time (Days)'); ylabel('i (deg)');

% (4) RAAN (Omega)
subplot(2, 3, 4); hold on; grid on;
plot(t_days, mod(osc_results(:, 4), 360), 'Color', col_osc, 'LineWidth', 0.5, 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 1);
plot(t_days, mod(mean_results(:, 4), 360), 'Color', col_trend, 'LineWidth', lw_trend, 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 2);
title('RAAN (\Omega)'); xlabel('Time (Days)'); ylabel('\Omega (deg)');
ylim([0 360]);

% (5) Argument of Latitude (u) [수정됨]
subplot(2, 3, 5); hold on; grid on;
% Osculating u (Gray)
plot(t_days, mod(u_osc_raw, 360), 'Color', col_osc, 'LineWidth', 0.5, 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 1);
% Mean Trend u (Red)
plot(t_days, mod(mean_u, 360), 'Color', col_trend, 'LineWidth', lw_trend, 'LineStyle', 'none', 'Marker', '.', 'MarkerSize', 2);
title('Arg of Latitude (u = \omega + M)'); % 제목 변경
xlabel('Time (Days)'); ylabel('u (deg)');
ylim([0 360]);

% (6) Mean Motion (n)
subplot(2, 3, 6); hold on; grid on;
plot(t_days, n_osc, 'Color', col_osc, 'LineWidth', 0.5);
plot(t_days, mean_n, 'Color', col_trend, 'LineWidth', lw_trend);
title('Mean Motion (n)'); xlabel('Time (Days)'); ylabel('n (rev/day)');

sgtitle(['[Trend Analysis] Osculating vs Mean: ' strrep(target_file, '_', '\_')], 'FontSize', 16, 'FontWeight', 'bold');

fprintf('\nTrend Plot Generation Completed (with Arg of Latitude).\n');

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