% -------------------------------------------------------------------------
% PLOT_RESULTS.m
% -------------------------------------------------------------------------
% 기능:
%   1. 현재 폴더에서 'Result_*.txt' 패턴의 파일을 모두 찾습니다.
%   2. 각 위성별로 3D 궤도, 위치(Pos), 속도(Vel) 그래프를 생성합니다.
%   3. 그래프를 보기 좋게 포매팅합니다.
% -------------------------------------------------------------------------

clear; clc; close all;

%% 1. 결과 파일 검색
% MAIN2에서 저장한 파일 형식: Result_파일명.txt
file_list = dir('Result_*.txt');

if isempty(file_list)
    error('결과 파일을 찾을 수 없습니다. MAIN2.m을 먼저 실행해주세요.');
end

num_files =2;
fprintf('Found %d result files.\n', num_files);

% 색상 설정 (파일별로 다른 색상 사용)
colors = lines(num_files); 

%% 2. Figure 초기화
% Fig 1: 3D Orbit Trajectory
figure('Name', '3D Orbit Trajectory', 'NumberTitle', 'off', 'Color', 'w');
hold on; grid on; axis equal;
xlabel('X (km)'); ylabel('Y (km)'); zlabel('Z (km)');
title('SGP4 Propagation: 3D Orbit');
view(3); % 3D View

% Fig 2: Position Time Series
fig_pos = figure('Name', 'Position Time Series', 'NumberTitle', 'off', 'Color', 'w');
tiledlayout(3,1, 'Padding', 'compact', 'TileSpacing', 'compact');

% Fig 3: Velocity Time Series
fig_vel = figure('Name', 'Velocity Time Series', 'NumberTitle', 'off', 'Color', 'w');
tiledlayout(3,1, 'Padding', 'compact', 'TileSpacing', 'compact');

legend_str = {};

%% 3. 데이터 로드 및 플로팅 루프
for k = 1
    filename = file_list(k).name;
    sat_name = strrep(filename, 'Result_', ''); % 파일명에서 접두어 제거
    sat_name = strrep(sat_name, '.txt', '');    % 확장자 제거
    sat_name = strrep(sat_name, '_', ' ');      % 언더바를 공백으로
    
    fprintf('Plotting: %s ...\n', filename);
    
    % 데이터 로드 (텍스트 파일 읽기)
    % Columns: [Time(min), Rx, Ry, Rz, Vx, Vy, Vz]
    try
        data = readmatrix(filename); 
    catch
        % 구버전 MATLAB 호환용
        data = load(filename); 
    end
    
    % 데이터 분리
    time_min = data(:, 1);
    time_hr  = time_min / 60.0; % 시간 단위로 변환 (보기 편함)
    r_vec    = data(:, 2:4);    % Position [Rx Ry Rz]
    v_vec    = data(:, 5:7);    % Velocity [Vx Vy Vz]
    
    % --- Plot 1: 3D Orbit ---
    figure(1);
    plot3(r_vec(:,1), r_vec(:,2), r_vec(:,3), 'LineWidth', 1.5, 'Color', colors(k,:));
    % 시작점(Start)과 끝점(End) 표시
    plot3(r_vec(1,1), r_vec(1,2), r_vec(1,3), 'o', 'MarkerFaceColor', colors(k,:), 'MarkerSize', 8);
    plot3(r_vec(end,1), r_vec(end,2), r_vec(end,3), 's', 'MarkerFaceColor', colors(k,:), 'MarkerSize', 8);
    
    % --- Plot 2: Position (Rx, Ry, Rz) ---
    figure(fig_pos);
    
    nexttile(1); hold on; grid on;
    plot(time_hr, r_vec(:,1), 'LineWidth', 1.2, 'Color', colors(k,:));
    ylabel('Rx (km)'); title('Position Vector');
    
    nexttile(2); hold on; grid on;
    plot(time_hr, r_vec(:,2), 'LineWidth', 1.2, 'Color', colors(k,:));
    ylabel('Ry (km)');
    
    nexttile(3); hold on; grid on;
    plot(time_hr, r_vec(:,3), 'LineWidth', 1.2, 'Color', colors(k,:));
    ylabel('Rz (km)'); xlabel('Time (hours)');
    
    % --- Plot 3: Velocity (Vx, Vy, Vz) ---
    figure(fig_vel);
    
    nexttile(1); hold on; grid on;
    plot(time_hr, v_vec(:,1), 'LineWidth', 1.2, 'Color', colors(k,:));
    ylabel('Vx (km/s)'); title('Velocity Vector');
    
    nexttile(2); hold on; grid on;
    plot(time_hr, v_vec(:,2), 'LineWidth', 1.2, 'Color', colors(k,:));
    ylabel('Vy (km/s)');
    
    nexttile(3); hold on; grid on;
    plot(time_hr, v_vec(:,3), 'LineWidth', 1.2, 'Color', colors(k,:));
    ylabel('Vz (km/s)'); xlabel('Time (hours)');
    
    legend_str{end+1} = sat_name;
end

%% 4. 범례 및 지구 표시 (꾸미기)

% 3D Orbit에 지구(구) 그리기
figure(1);
[x, y, z] = sphere(50);
R_earth = 6378.135; % Earth Radius (km)
surf(x*R_earth, y*R_earth, z*R_earth, 'FaceColor', [0.8 0.9 1.0], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
legend([legend_str, {'Start', 'End', 'Earth'}], 'Location', 'best');

% Position Plot 범례
figure(fig_pos);
nexttile(1); legend(legend_str, 'Location', 'best');

% Velocity Plot 범례
figure(fig_vel);
nexttile(1); legend(legend_str, 'Location', 'best');

fprintf('All plots generated.\n');