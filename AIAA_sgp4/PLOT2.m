% -------------------------------------------------------------------------
% PLOT_COORD_DIFF.m
% -------------------------------------------------------------------------
% 기능: 
%   1. 사용자가 제공한 BEE1000 위성의 TEME 및 ECI 위치 벡터를 정의
%   2. 두 벡터를 3차원 공간(ECI J2000 프레임)에 도시
%   3. 지구 전체 뷰와 위성 주변 확대 뷰를 통해 좌표계 차이(세차운동 효과) 시각화
% -------------------------------------------------------------------------

clear; clc; close all;

%% 1. 데이터 정의 (BEE1000 결과값)
% 단위: km
% r_teme: SGP4 출력 (True Equator, Mean Equinox)
r_teme = [978.651836; -6906.322766; -160.312883];

% r_eci: J2000 변환 결과 (Mean Equator, Mean Equinox J2000)
r_eci  = [938.135633; -6911.886552; -162.725571];

% 차이 벡터 계산 (Displacement due to frame rotation)
diff_vec = r_eci - r_teme;
dist_err = norm(diff_vec);

fprintf('======================================================\n');
fprintf('         TEME vs ECI Vector Comparison                \n');
fprintf('======================================================\n');
fprintf('TEME Vector : [%.4f, %.4f, %.4f] km\n', r_teme);
fprintf('ECI  Vector : [%.4f, %.4f, %.4f] km\n', r_eci);
fprintf('Difference  : %.4f km\n', dist_err);
fprintf('======================================================\n');

%% 2. 시각화 설정
% Figure 생성 (1920x900 와이드)
figure('Name', 'TEME vs ECI Coordinate Difference', 'Color', 'w', 'Position', [100 100 1400 600]);
t = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% -------------------------------------------------------------------------
% [왼쪽 그림] Global View: 지구와 위성
% -------------------------------------------------------------------------
nexttile;
hold on; grid on; axis equal;
title('1. Global View (Earth & Satellite)', 'FontSize', 12);

% 1) 지구 그리기 (반투명 구)
R_earth = 6378.137;
[sx, sy, sz] = sphere(50);
surf(sx*R_earth, sy*R_earth, sz*R_earth, 'FaceColor', [0.9 0.9 0.95], ...
     'EdgeColor', 'none', 'FaceAlpha', 0.6, 'DisplayName', 'Earth');

% 2) ECI 축 표시 (J2000 Frame)
L_axis = 8000;
plot3([0 L_axis], [0 0], [0 0], 'r-', 'LineWidth', 2, 'DisplayName', 'X (J2000 Equinox)');
plot3([0 0], [0 L_axis], [0 0], 'g-', 'LineWidth', 1.5, 'DisplayName', 'Y (J2000)');
plot3([0 0], [0 0], [0 L_axis], 'b-', 'LineWidth', 1.5, 'DisplayName', 'Z (J2000 Pole)');

% 3) 벡터 그리기 (원점 -> 위성)
% 두 선이 겹쳐 보일 것이므로 굵기와 스타일을 다르게 함
plot3([0 r_teme(1)], [0 r_teme(2)], [0 r_teme(3)], 'c--', 'LineWidth', 2, 'DisplayName', 'TEME Vector (Apparent)');
plot3([0 r_eci(1)],  [0 r_eci(2)],  [0 r_eci(3)],  'm-',  'LineWidth', 1.5, 'DisplayName', 'ECI Vector (True J2000)');

xlabel('X (km)'); ylabel('Y (km)'); zlabel('Z (km)');
legend('Location', 'best');
view(130, 20); % 적절한 뷰 포인트

% -------------------------------------------------------------------------
% [오른쪽 그림] Zoomed View: 위성 위치 확대 (차이 강조)
% -------------------------------------------------------------------------
nexttile;
hold on; grid on; axis equal;
title(sprintf('2. Zoomed View (Difference: %.2f km)', dist_err), 'FontSize', 12, 'FontWeight', 'bold');

% 1) 위치 포인트 찍기
p1 = plot3(r_teme(1), r_teme(2), r_teme(3), 'co', 'MarkerFaceColor', 'c', 'MarkerSize', 8, 'DisplayName', 'TEME Pos');
p2 = plot3(r_eci(1),  r_eci(2),  r_eci(3),  'ms', 'MarkerFaceColor', 'm', 'MarkerSize', 8, 'DisplayName', 'ECI Pos');

% 2) 원점으로부터 오는 선 (일부만 그림)
quiver3(0, 0, 0, r_teme(1), r_teme(2), r_teme(3), 'Off', 'c--', 'LineWidth', 1, 'DisplayName', 'TEME Ray');
quiver3(0, 0, 0, r_eci(1),  r_eci(2),  r_eci(3),  'Off', 'm-',  'LineWidth', 1, 'DisplayName', 'ECI Ray');

% 3) 차이 벡터 그리기 (TEME -> ECI)
% 이것이 바로 세차/장동에 의한 "좌표 이동량"입니다.
quiver3(r_teme(1), r_teme(2), r_teme(3), ...
        diff_vec(1), diff_vec(2), diff_vec(3), ...
        'Off', 'k-', 'LineWidth', 2, 'MaxHeadSize', 0.5, 'DisplayName', 'Difference (Shift)');

% 4) 텍스트 라벨링 (좌표 차이 표시)
mid_pt = (r_teme + r_eci) / 2;
text(mid_pt(1), mid_pt(2), mid_pt(3) + 2, ...
     sprintf('\\Delta = %.1f km', dist_err), ...
     'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% 5) 뷰 설정 (확대)
% 위성 주변 +/- 50km 박스 설정
center = r_eci;
range = 40; % 줌 범위 (km)
% xlim([center(1)-range, center(1)+range]);
% ylim([center(2)-range, center(2)+range]);
% zlim([center(3)-range, center(3)+range]);

xlabel('X (km)'); ylabel('Y (km)'); zlabel('Z (km)');
legend([p1, p2], 'Location', 'best');
view(3); % 3D View

%% 3. 설명 출력
fprintf('\n[Interpretation]\n');
fprintf('1. Global View에서는 두 벡터가 지구 반지름(~6400km)에 비해\n');
fprintf('   차이가 작아(40km) 거의 하나의 선처럼 보입니다.\n');
fprintf('2. Zoomed View를 보면 두 점이 떨어져 있음을 알 수 있습니다.\n');
fprintf('3. 검은색 화살표는 좌표계 회전(세차/장동)으로 인해 발생한\n');
fprintf('   "좌표 값의 이동(Shift)"을 나타냅니다.\n');