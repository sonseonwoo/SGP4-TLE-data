% -------------------------------------------------------------------------
% MAIN_ERROR_ANALYSIS_V2.m
% -------------------------------------------------------------------------
% 기능:
%   1. TLE 파일을 읽어 모든 TLE 세트를 파싱
%   2. 첫 번째 TLE(Day 0)를 기준으로 SGP4 전파 수행
%   3. 파일 내 존재하는 이후 모든 TLE를 '참값'으로 가정하여 비교
%   4. [위치 오차(km)]와 [시간 오차(sec)]를 동시에 계산 및 시각화
% -------------------------------------------------------------------------
clear; clc; close all;

% SGP4 전역 변수 설정
global tothrd xkmper
tothrd = 2.0 / 3.0;
xkmper = 6378.135;

%% 1. 파일 설정
file_list = {'BEE1000_TLE.txt', 'COSMIC_TLE.txt'};
num_files = length(file_list);

fprintf('================================================================\n');
fprintf('       SGP4 ERROR ANALYSIS (POSITION & TIME)                    \n');
fprintf('================================================================\n');

% Vallado SGP4 옵션
whichconst = 72; opsmode = 'a'; typerun = 'c'; typeinput = 'e';

%% 2. 위성별 분석 루프
for k = 1:num_files
    filename = file_list{k};
    fprintf('\n[Target File %d]: %s\n', k, filename);
    
    % 2-1. 파일 읽기 및 TLE 파싱
    try
        fid = fopen(filename, 'r');
        if fid == -1, error('File not found'); end
        raw_text = textscan(fid, '%s', 'Delimiter', '\n');
        fclose(fid);
        lines = raw_text{1};
    catch ME
        fprintf('  Error: %s\n', ME.message);
        continue;
    end
    
    idx_l1 = find(startsWith(lines, '1 '));
    idx_l2 = find(startsWith(lines, '2 '));
    num_tle = length(idx_l1);
    
    if num_tle < 2
        fprintf('  - 데이터가 충분하지 않습니다 (최소 2개 필요). Skip.\n');
        continue;
    end
    
    fprintf('  - Total TLE Sets found: %d\n', num_tle);
    
    % 2-2. 첫 번째 TLE (Propagator 초기화 - 예측 모델)
    line1_first = lines{idx_l1(1)};
    line2_first = lines{idx_l2(1)};
    [~, ~, ~, satrec_prop] = twoline2rv(line1_first, line2_first, typerun, typeinput, opsmode, whichconst);
    
    % 초기 Epoch (JD)
    jd_start = satrec_prop.jdsatepoch + satrec_prop.jdsatepochf;
    
    % 결과 저장용 배열 [Time_days, Pos_Error_km, Time_Error_sec]
    error_history = zeros(num_tle, 3);
    
    % 2-3. 모든 TLE에 대해 루프를 돌며 오차 계산
    fprintf('  - Calculating Position & Time errors over time...\n');
    
    for i = 1:num_tle
        % (1) 비교 대상 TLE (Truth) 파싱
        l1 = lines{idx_l1(i)};
        l2 = lines{idx_l2(i)};
        [~, ~, ~, satrec_truth] = twoline2rv(l1, l2, typerun, typeinput, opsmode, whichconst);
        
        % Truth의 Epoch 및 위치/속도 (SGP4로 0분 전파하여 Osculating State 획득)
        % r_truth: km, v_truth: km/s
        [~, r_truth, v_truth] = sgp4(satrec_truth, 0.0);
        
        % Truth Epoch (JD)
        jd_current = satrec_truth.jdsatepoch + satrec_truth.jdsatepochf;
        
        % (2) 전파 시간 계산 (분 단위)
        tsince = (jd_current - jd_start) * 1440.0;
        
        % (3) 첫 번째 TLE를 해당 시점까지 전파 (Prediction)
        [~, r_pred, v_pred] = sgp4(satrec_prop, tsince);
        
        % (4) 위치 오차(Distance Error) 계산
        diff_vec = r_pred(:) - r_truth(:);
        dist_err = norm(diff_vec); % km
        
        % (5) 시간 오차(Time Error) 계산
        % 논리: Distance = Velocity * Time  =>  Time = Distance / Velocity
        % 위성의 현재 속도 크기 (Speed)
        v_mag = norm(v_truth); % km/s (실측 속도 기준)
        
        if v_mag > 0
            time_err = dist_err / v_mag; % seconds
        else
            time_err = 0;
        end
        
        % (6) 저장 (시간축은 '일(Day)' 단위로 변환)
        error_history(i, :) = [tsince / 1440.0, dist_err, time_err];
    end
    
    % 2-4. 그래프 그리기 (Dual Y-Axis)
    figure('Name', ['Error Analysis: ' filename], 'Color', 'w', 'Position', [100, 100, 800, 500]);
    
    % 왼쪽 축: 위치 오차 (km)
    yyaxis left
    plot(error_history(:,1), error_history(:,2), 'b-o', 'LineWidth', 1.5, 'MarkerFaceColor', 'b');
    ylabel('Position Error (km)', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Time since Epoch (Days)', 'FontSize', 12);
    set(gca, 'YColor', 'b');
    
    % 오른쪽 축: 시간 오차 (sec)
    yyaxis right
    plot(error_history(:,1), error_history(:,3), 'r-s', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
    ylabel('Time Error (seconds)', 'FontSize', 12, 'FontWeight', 'bold');
    set(gca, 'YColor', 'r');
    
    grid on;
    title(['Propagation Error Growth: ' strrep(filename, '_', '\_')], 'FontSize', 14);
    
    % 범례 추가
    legend('Position Error (km)', 'Time Error (sec)', 'Location', 'best');
    
    % 결과 요약 출력
    final_day = error_history(end, 1);
    final_pos_err = error_history(end, 2);
    final_time_err = error_history(end, 3);
    
    fprintf('  -> [Result at Day %.2f]\n', final_day);
    fprintf('     Position Error : %.4f km\n', final_pos_err);
    fprintf('     Time Error     : %.4f sec\n', final_time_err);
    fprintf('  --------------------------------------------------------------\n');
end
fprintf('\nAnalysis Completed.\n');

% -------------------------------------------------------------------------
% Helper Functions 
% (get_state_from_tle 등의 별도 함수 없이, SGP4 라이브러리 직접 호출 방식 사용)
% -------------------------------------------------------------------------