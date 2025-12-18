% -------------------------------------------------------------------------
% MAIN SGP4 Propagation Script (Vallado & Beck Version)
% -------------------------------------------------------------------------
% 기능: 
%   1. BEE1000 및 COSMIC TLE 파일을 로드
%   2. 데이터 개수 및 기간(Epoch) 확인
%   3. 각 파일의 첫 번째 TLE를 초기값으로, 마지막 TLE 시점까지 SGP4 전파 수행
% -------------------------------------------------------------------------

clear; clc; close all;

%% 1. 파일 설정 (File Configuration)
file_list = {'BEE1000_TLE.txt', 'COSMIC_TLE.txt'};
num_files = length(file_list);

% 데이터를 저장할 구조체 초기화
TLE_DB = struct('filename', {}, 'count', {}, 'data', {});

fprintf('================================================================\n');
fprintf('                TLE DATA LOADING & INSPECTION                   \n');
fprintf('================================================================\n');

%% 2. 데이터 로드 및 분석 루프 (Part 1)
for k = 1:num_files
    filename = file_list{k};
    fprintf('\n[Target File %d]: %s\n', k, filename);

    % 2-1. 파일 읽기
    try
        fid = fopen(filename, 'r');
        if fid == -1
            error('파일을 찾을 수 없습니다: %s', filename);
        end
        raw_text = textscan(fid, '%s', 'Delimiter', '\n');
        fclose(fid);
        lines = raw_text{1};
    catch ME
        fprintf('Error reading file: %s\n', ME.message);
        continue;
    end

    % 2-2. TLE 라인 추출
    idx_l1 = find(startsWith(lines, '1 '));
    idx_l2 = find(startsWith(lines, '2 '));
    count = length(idx_l1);

    if length(idx_l1) ~= length(idx_l2)
        warning('Line 1과 Line 2의 개수가 일치하지 않습니다.');
    end

    % 2-3. 기간 확인 (단순 문자열 파싱)
    if count > 0
        % Start Epoch
        first_line1 = lines{idx_l1(1)};
        start_epoch_str = first_line1(19:32);

        % End Epoch
        last_line1 = lines{idx_l1(end)};
        end_epoch_str = last_line1(19:32);

        fprintf('  - Total TLE Sets : %d sets\n', count);
        fprintf('  - Range          : %s ~ %s (YYDDD.DDDD)\n', start_epoch_str, end_epoch_str);

        % 데이터 구조체 저장
        TLE_DB(k).filename = filename;
        TLE_DB(k).count = count;
        TLE_DB(k).line1 = lines(idx_l1);
        TLE_DB(k).line2 = lines(idx_l2);
    else
        fprintf('  - No valid TLE data found.\n');
    end
    fprintf('----------------------------------------------------------------\n');
end

fprintf('\nData loading complete. Starting SGP4 (Vallado) propagation...\n');


%% 3. SGP4 전파 실행 (Part 2: Vallado Logic 적용)
fprintf('\n================================================================\n');
fprintf('                SGP4 PROPAGATION EXECUTION                      \n');
fprintf('================================================================\n');

% Vallado SGP4 설정 상수
whichconst = 72;       % WGS-72 중력 모델 사용
opsmode    = 'a';      % 'a': AFSPC mode (표준), 'i': Improved mode
typerun    = 'c';      % Catalog run (기본값)
typeinput  = 'e';      % Epoch based (기본값)

for k = 1:num_files
    current_file = TLE_DB(k).filename;
    count = TLE_DB(k).count;
    
    if count < 2
        continue;
    end
    
    fprintf('\n[Target File %d]: %s\n', k, current_file);
    
    % ---------------------------------------------------------------------
    % 3-1. 초기 상태 설정 (첫 번째 TLE 파싱 및 초기화)
    % ---------------------------------------------------------------------
    line1_start = TLE_DB(k).line1{1};
    line2_start = TLE_DB(k).line2{1};
    
    % twoline2rv 함수를 사용하여 TLE를 파싱하고 satrec 구조체를 초기화
    % (내부적으로 sgp4init을 호출하여 물리 상수 계산 수행)
    [~, ~, ~, satrec_start] = twoline2rv(line1_start, line2_start, ...
                                         typerun, typeinput, opsmode, whichconst);
                                     
    % ---------------------------------------------------------------------
    % 3-2. 목표 시간 설정 (마지막 TLE 파싱)
    % ---------------------------------------------------------------------
    line1_end = TLE_DB(k).line1{end};
    line2_end = TLE_DB(k).line2{end};
    
    % 마지막 TLE의 Epoch 시간을 얻기 위해 파싱 수행
    [~, ~, ~, satrec_end] = twoline2rv(line1_end, line2_end, ...
                                       typerun, typeinput, opsmode, whichconst);
    
    % Julian Date를 이용한 정확한 시간 차이(tsince) 계산
    % satrec 구조체에는 jdsatepoch(정수부)와 jdsatepochf(소수부)가 분리되어 있음
    jd_start = satrec_start.jdsatepoch + satrec_start.jdsatepochf;
    jd_end   = satrec_end.jdsatepoch   + satrec_end.jdsatepochf;
    
    % 전파 시간 (분 단위)
    tsince_target = (jd_end - jd_start) * 1440.0;
    
    fprintf('  - Initial Epoch (JD) : %.5f\n', jd_start);
    fprintf('  - Target Epoch (JD)  : %.5f\n', jd_end);
    fprintf('  - Propagation Time   : %.4f minutes (%.4f days)\n', tsince_target, tsince_target/1440);
    
    % ---------------------------------------------------------------------
    % 3-3. SGP4 전파 수행 (Propagation)
    % ---------------------------------------------------------------------
    % 초기 상태 (t=0) 확인
    [satrec_start, r0, v0] = sgp4(satrec_start, 0.0);
    
    % 목표 시간 (t=tsince) 전파 수행
    [satrec_final, r_final, v_final] = sgp4(satrec_start, tsince_target);
    
    % 에러 체크
    if satrec_final.error > 0
        fprintf('  *** Error: SGP4 propagation failed with code %d ***\n', satrec_final.error);
    end

    % ---------------------------------------------------------------------
    % 3-4. 결과 출력
    % ---------------------------------------------------------------------
    fprintf('  --------------------------------------------------------------\n');
    fprintf('  [Propagation Result - TEME Frame]\n');
    fprintf('  Pos (km) : [%12.6f, %12.6f, %12.6f]\n', r_final(1), r_final(2), r_final(3));
    fprintf('  Vel (k/s): [%12.6f, %12.6f, %12.6f]\n', v_final(1), v_final(2), v_final(3));
    fprintf('  --------------------------------------------------------------\n');

    % ---------------------------------------------------------------------
    % 3-5 TEME -> ECI (J2000) 좌표 변환 및 출력
    % ---------------------------------------------------------------------
    
    % 1. Julian Centuries (TTT) 계산
    % J2000 epoch (2451545.0) 로부터 흐른 세기(Century) 단위 시간
    % (엄밀히는 TT 시간이 필요하나, 여기서는 jd_end(UT1 근사)를 사용)
    ttt = (jd_end - 2451545.0) / 36525.0;
    
    % 2. 입력 벡터 준비
    % sgp4 출력은 행 벡터(1x3)일 수 있으므로 열 벡터(3x1)로 변환
    r_col = r_final(:);
    v_col = v_final(:);
    a_col = [0; 0; 0]; % 가속도는 SGP4에서 계산되지 않으므로 0으로 가정
    
    % 3. teme2eci 함수 호출
    % 인자: r, v, a, ttt, order, eqeterms, opt
    % order=2, eqeterms=2, opt='a' (Vallado 표준 설정)
    try
        [r_eci, v_eci, ~] = teme2eci(r_col, v_col, a_col, ttt, 2, 2, 'a');
        
        fprintf('  --------------------------------------------------------------\n');
        fprintf('  [Propagation Result - ECI J2000 Frame]\n');
        fprintf('  Pos (km) : [%12.6f, %12.6f, %12.6f]\n', r_eci(1), r_eci(2), r_eci(3));
        fprintf('  Vel (k/s): [%12.6f, %12.6f, %12.6f]\n', v_eci(1), v_eci(2), v_eci(3));
    catch ME
        fprintf('  *** TEME -> ECI conversion failed: %s\n', ME.message);
        fprintf('  (teme2eci.m 또는 관련 함수가 경로에 있는지 확인하세요)\n');
    end
    
    fprintf('  --------------------------------------------------------------\n');
    


end

fprintf('\nAll propagations completed.\n');