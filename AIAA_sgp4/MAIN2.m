% -------------------------------------------------------------------------
% MAIN2 SGP4 Propagation Script (Vallado & Beck Version) - Time Series
% -------------------------------------------------------------------------
% 기능:
%   1. Vallado SGP4 패키지(twoline2rv, sgp4 등)를 사용
%   2. BEE1000 및 COSMIC TLE 로드
%   3. 각 파일의 첫 번째 TLE를 기준으로 마지막 TLE 시점까지 "1분 간격" 전파
%   4. 결과를 txt 파일로 저장 (Time, Rx, Ry, Rz, Vx, Vy, Vz)
% -------------------------------------------------------------------------

clear; clc; close all;

%% 1. 파일 설정 (File Configuration)
file_list = {'BEE1000_TLE.txt', 'COSMIC_TLE.txt'};
num_files = length(file_list);

% 데이터를 저장할 구조체 초기화
TLE_DB = struct('filename', {}, 'count', {}, 'data', {});
Propagation_Results = cell(num_files, 1);

fprintf('================================================================\n');
fprintf('       AIAA SGP4 (VALLADO) TIME-SERIES PROPAGATION START        \n');
fprintf('================================================================\n');

%% 2. 데이터 로드 및 분석 루프 (Part 1)
for k = 1:num_files
    filename = file_list{k};
    fprintf('\n[Target File %d]: %s\n', k, filename);
    
    % 2-1. 파일 읽기
    try
        fid = fopen(filename, 'r');
        if fid == -1, error('파일을 찾을 수 없습니다: %s', filename); end
        raw_text = textscan(fid, '%s', 'Delimiter', '\n');
        fclose(fid);
        lines = raw_text{1};
    catch ME
        fprintf('Error reading file: %s\n', ME.message);
        continue;
    end
    
    idx_l1 = find(startsWith(lines, '1 '));
    idx_l2 = find(startsWith(lines, '2 '));
    count = length(idx_l1);
    
    if count < 2
        fprintf('  - 데이터 부족. Skip.\n');
        continue;
    end
    
    % 데이터 구조체 저장
    TLE_DB(k).filename = filename;
    TLE_DB(k).count = count;
    TLE_DB(k).line1 = lines(idx_l1);
    TLE_DB(k).line2 = lines(idx_l2);
    
    fprintf('  - Total TLE Sets : %d sets loaded.\n', count);
end
fprintf('\nData loading complete. Starting SGP4 (Vallado) propagation...\n');


%% 3. SGP4 전파 실행 (Part 2: Time-Series Propagation)
fprintf('\n================================================================\n');
fprintf('                SGP4 PROPAGATION EXECUTION                      \n');
fprintf('================================================================\n');

% Vallado SGP4 설정 상수
whichconst = 72;       % WGS-72
opsmode    = 'a';      % AFSPC mode
typerun    = 'c';      % Catalog run ('c'로 수정된 twoline2rv 사용 전제)
typeinput  = 'e';      % Epoch based

% [중요] 시간 간격 설정 (분 단위)
dt = 1; % 1분 간격

for k = 1:num_files
    current_file = TLE_DB(k).filename;
    count = TLE_DB(k).count;
    
    if count < 2, continue; end
    
    fprintf('\n[Processing File %d]: %s\n', k, current_file);
    
    % ---------------------------------------------------------------------
    % 3-1. 초기 상태 설정 (첫 번째 TLE)
    % ---------------------------------------------------------------------
    line1_start = TLE_DB(k).line1{1};
    line2_start = TLE_DB(k).line2{1};
    
    % twoline2rv 호출 (주의: 사용자 환경에 따라 인자 순서 확인 필요)
    % [~, ~, ~, satrec_start] = twoline2rv(line1_start, line2_start, typerun, typeinput, opsmode, whichconst);
    % 사용자님의 수정된 twoline2rv 인자 순서에 맞춤:
    [~, ~, ~, satrec_start] = twoline2rv(line1_start, line2_start, ...
                                         typerun, typeinput, opsmode, whichconst);
                                     
    % ---------------------------------------------------------------------
    % 3-2. 목표 시간 설정 (마지막 TLE)
    % ---------------------------------------------------------------------
    line1_end = TLE_DB(k).line1{end};
    line2_end = TLE_DB(k).line2{end};
    
    % 마지막 TLE의 Epoch만 추출하기 위해 임시 호출
    [~, ~, ~, satrec_end] = twoline2rv(line1_end, line2_end, ...
                                       typerun, typeinput, opsmode, whichconst);
    
    % Julian Date를 이용한 정확한 시간 차이(tsince) 계산
    jd_start = satrec_start.jdsatepoch + satrec_start.jdsatepochf;
    jd_end   = satrec_end.jdsatepoch   + satrec_end.jdsatepochf;
    
    % 총 전파 시간 (분 단위)
    tsince_total = (jd_end - jd_start) * 1440.0;
    
    % 시간 배열 생성 (0 ~ Total, dt 간격)
    time_steps = 0:dt:tsince_total;
    
    % 마지막 시점이 dt로 안 떨어지면 강제 추가
    if abs(time_steps(end) - tsince_total) > 1e-6
        time_steps = [time_steps, tsince_total];
    end
    num_steps = length(time_steps);
    
    fprintf('  - Initial Epoch (JD) : %.5f\n', jd_start);
    fprintf('  - Target Epoch (JD)  : %.5f\n', jd_end);
    fprintf('  - Duration           : %.2f mins (%.2f hours)\n', tsince_total, tsince_total/60);
    fprintf('  - Simulation Steps   : %d steps (dt = %.1f min)\n', num_steps, dt);
    
    % ---------------------------------------------------------------------
    % 3-3. SGP4 전파 수행 (Time Loop)
    % ---------------------------------------------------------------------
    
    % 결과 행렬: [Time(min), Rx, Ry, Rz, Vx, Vy, Vz]
    result_matrix = zeros(num_steps, 7);
    
    for t_idx = 1:num_steps
        tsince = time_steps(t_idx);
        
        % Vallado SGP4 호출 (구조체 방식)
        [satrec_current, r_teme, v_teme] = sgp4(satrec_start, tsince);
        
        % 에러 체크 (에러 발생 시 콘솔 출력 후 계속 진행하거나 중단)
        if satrec_current.error > 0
           % fprintf('    Warning: SGP4 Error Code %d at t=%.2f\n', satrec_current.error, tsince);
           % 에러 발생 시 0 또는 NaN 처리 등을 할 수 있음
        end
        
        % 결과 저장 (TEME 좌표계)
        result_matrix(t_idx, :) = [tsince, r_teme(1), r_teme(2), r_teme(3), ...
                                           v_teme(1), v_teme(2), v_teme(3)];
    end
    
    Propagation_Results{k} = result_matrix;

    % ---------------------------------------------------------------------
    % 3-4. 결과 파일 저장
    % ---------------------------------------------------------------------
    out_name = ['Result_' strrep(current_file, '.txt', '') '.txt'];
    fid_out = fopen(out_name, 'w');
    fprintf(fid_out, '%% Vallado SGP4 Result (TEME Frame)\n');
    fprintf(fid_out, '%% Time(min)      Rx(km)        Ry(km)        Rz(km)        Vx(km/s)      Vy(km/s)      Vz(km/s)\n');
    fprintf(fid_out, '%12.4f %14.6f %14.6f %14.6f %14.9f %14.9f %14.9f\n', result_matrix');
    fclose(fid_out);
    
    fprintf('  -> Result saved to: %s\n', out_name);
    
end

fprintf('\nAll propagations completed.\n');