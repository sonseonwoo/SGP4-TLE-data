% -------------------------------------------------------------------------
% COMPARE_TLE_ERROR.m
% -------------------------------------------------------------------------
% 기능:
%   1. BEE-1000 및 COSMIC 위성의 '실측 TLE'와 '예측 TLE'를 하드코딩으로 입력
%   2. SGP4 모델을 사용하여 각 TLE를 ECI 위치/속도 벡터로 변환 (Epoch 시점)
%   3. 두 벡터 간의 거리 오차(Position Error) 계산
%   4. 3차원 그래프로 두 벡터와 차이 벡터 시각화
%
% 필요 파일: sgp4.m, twoline2rv.m 등 Vallado 라이브러리 (같은 폴더에 위치)
% -------------------------------------------------------------------------

clear; clc; close all;

% 전역 변수 설정 (SGP4용)
global tothrd xkmper
tothrd = 2.0 / 3.0;
xkmper = 6378.135; % Earth radius parameter

fprintf('================================================================\n');
fprintf('             TLE ACCURACY ASSESSMENT (REAL vs PRED)             \n');
fprintf('================================================================\n');

%% 1. TLE 데이터 하드코딩 (Hard-coding)
% -------------------------------------------------------------------------
% NOTE: 예측 TLE의 연도가 125로 잘못된 부분은 25로 수정하여 입력함.
% -------------------------------------------------------------------------

% [1] BEE-1000
% Real TLE (from Image)
bee_tle_real = { ...
    '1 66650U 25274A   25350.77725991  .00001368  00000-0  14147-3 0  9993'; ...
    '2 66650  97.7395 277.8907 0010570 236.5050 123.5160 14.91675800  3001'};

% Predicted TLE (from Image, ECI2TLE Result)
bee_tle_pred = { ...
    '1 99999U 99999A   25350.77725995  .00000000  00000-0  00000-0 0  0000'; ...
    '2 99999  97.5945 277.5511 0010730  65.1830 293.4781 14.91641785  0000'};

% [2] COSMIC
% Real TLE (from Image)
cosmic_tle_real = { ...
    '1 66658U 25274J   25350.76462765  .00002388  00000-0  23698-3 0  9991'; ...
    '2 66658  97.7393 277.9063 0011144 263.8551  96.1399 14.92650133  3000'};

% Predicted TLE (from Image, ECI2TLE Result)
% Note: The predicted elements were identical to BEE-1000 in the provided image
cosmic_tle_pred = { ...
    '1 99999U 99999A   25350.76462766  .00000000  00000-0  00000-0 0  0000'; ...
    '2 99999  97.5935 277.5648 0012256 270.5777  86.9836 14.92584323  0000'};


%% 2. 오차 계산 및 시각화 함수 호출
analyze_satellite('BEE-1000', bee_tle_real, bee_tle_pred);
analyze_satellite('COSMIC', cosmic_tle_real, cosmic_tle_pred);


%% ------------------------------------------------------------------------
%  Helper Function: 위성별 분석 및 Plot
% -------------------------------------------------------------------------
function analyze_satellite(sat_name, tle_real, tle_pred)
    % 1. SGP4 초기화 및 상태 벡터 추출 (Epoch 시점, tsince=0)
    [r_real, v_real] = get_state_from_tle(tle_real);
    [r_pred, v_pred] = get_state_from_tle(tle_pred);
    
    % 2. 오차 계산
    diff_vec = r_pred - r_real;
    dist_err = norm(diff_vec);
    
    % 3. 결과 출력
    fprintf('\n[Target: %s]\n', sat_name);
    fprintf('  - Real Pos (km): [%10.4f, %10.4f, %10.4f]\n', r_real);
    fprintf('  - Pred Pos (km): [%10.4f, %10.4f, %10.4f]\n', r_pred);
    fprintf('  - Diff Vec (km): [%10.4f, %10.4f, %10.4f]\n', diff_vec);
    fprintf('  >> Position Error Magnitude: %.4f km\n', dist_err);

    % 4. Plot 생성
    figure('Name', ['Comparison: ' sat_name], 'Color', 'w', 'Position', [100 100 1000 500]);
    t = tiledlayout(1, 2, 'TileSpacing', 'compact');
    
    % (1) Global View
    nexttile;
    hold on; grid on; axis equal;
    title(['Global View - ' sat_name]);
    
    % 지구 그리기
    R_earth = 6378.137;
    [sx, sy, sz] = sphere(30);
    surf(sx*R_earth, sy*R_earth, sz*R_earth, 'FaceColor', [0.9 0.9 1.0], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    
    % 벡터 그리기
    plot3([0 r_real(1)], [0 r_real(2)], [0 r_real(3)], 'b-', 'LineWidth', 2, 'DisplayName', 'Real TLE');
    plot3([0 r_pred(1)], [0 r_pred(2)], [0 r_pred(3)], 'r--', 'LineWidth', 2, 'DisplayName', 'Pred TLE');
    
    legend('Location', 'best');
    xlabel('X (km)'); ylabel('Y (km)'); zlabel('Z (km)');
    view(3);
    
    % (2) Zoomed View (Error Vector)
    nexttile;
    hold on; grid on; axis equal;
    title(['Zoomed View (Error: ' sprintf('%.2f', dist_err) ' km)']);
    
    % 점 찍기
    plot3(r_real(1), r_real(2), r_real(3), 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', 'Real');
    plot3(r_pred(1), r_pred(2), r_pred(3), 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Pred');
    
    % 오차 벡터 화살표 (Real -> Pred)
    quiver3(r_real(1), r_real(2), r_real(3), ...
            diff_vec(1), diff_vec(2), diff_vec(3), ...
            'k-', 'LineWidth', 2, 'MaxHeadSize', 0.5, 'AutoScale', 'off', 'DisplayName', 'Error Vector');
    
    % 텍스트 표시
    mid_pt = (r_real + r_pred) / 2;
    text(mid_pt(1), mid_pt(2), mid_pt(3), sprintf('\\Delta = %.1f km', dist_err), ...
        'VerticalAlignment', 'bottom', 'FontSize', 10, 'FontWeight', 'bold');
    
    % 뷰 설정 (확대)
    margin = max(dist_err, 10) * 1.5; % 최소 15km 범위 확보
    xlim([mid_pt(1)-margin, mid_pt(1)+margin]);
    ylim([mid_pt(2)-margin, mid_pt(2)+margin]);
    zlim([mid_pt(3)-margin, mid_pt(3)+margin]);
    
    xlabel('X (km)'); ylabel('Y (km)'); zlabel('Z (km)');
    legend('Location', 'best');
    view(3);
end

% -------------------------------------------------------------------------
%  Helper Function: TLE -> State Vector 변환 (SGP4 wrapper)
% -------------------------------------------------------------------------
function [r, v] = get_state_from_tle(tle_cell)
    % Vallado 라이브러리의 twoline2rv 함수 사용 가정
    % (없을 경우 에러 발생하므로 경로 확인 필요)
    
    line1 = tle_cell{1};
    line2 = tle_cell{2};
    
    whichconst = 72;       % WGS-72 중력 모델 사용
    opsmode    = 'a';      % 'a': AFSPC mode (표준), 'i': Improved mode
    typerun    = 'c';      % Catalog run (기본값)
    typeinput  = 'e';      % Epoch based (기본값)
    % Try-Catch for SGP4 availability
    try
        [~, ~, ~, satrec]= twoline2rv(line1, line2, ...
        typerun, typeinput, opsmode, whichconst);
        % Propagate to t=0 (Epoch time)
        [~, r, v] = sgp4(satrec, 0.0);
        
        % r is in km, v is in km/s
        % SGP4 output might be row or column vector depending on implementation. 
        % Force to row vector for plotting
        r = r(:)';
        v = v(:)';
        
    catch ME
        error('SGP4 함수 실행 실패. twoline2rv.m 및 sgp4.m 파일이 경로에 있는지 확인하세요.\n에러 메시지: %s', ME.message);
    end
end