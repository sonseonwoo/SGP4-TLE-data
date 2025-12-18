% -------------------------------------------------------------------------
% MAIN SGP4 Propagation Script - Part 1: Data Loading & Inspection
% -------------------------------------------------------------------------
% 이 섹션은 TLE 텍스트 파일을 읽어와 데이터 개수와 Epoch 기간을 확인하고,
% 추후 전파(Propagation)를 위해 데이터를 구조체에 저장합니다.
% -------------------------------------------------------------------------

clear; clc; close all;

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

%% 1. 파일 설정 (File Configuration)
% 분석할 TLE 파일명 목록
file_list = {'BEE1000_TLE.txt', 'COSMIC_TLE.txt'};
num_files = length(file_list);

% 데이터를 저장할 구조체 초기화
% 구조: TLE_DB(1).name, TLE_DB(1).line1, TLE_DB(1).line2 등
TLE_DB = struct('filename', {}, 'count', {}, 'data', {});

fprintf('================================================================\n');
fprintf('                TLE DATA LOADING & INSPECTION                   \n');
fprintf('================================================================\n');

%% 2. 데이터 로드 및 분석 루프
for k = 1:num_files
    filename = file_list{k};
    fprintf('\n[Target File %d]: %s\n', k, filename);

    % 2-1. 파일 읽기
    try
        fid = fopen(filename, 'r');
        if fid == -1
            error('파일을 찾을 수 없습니다: %s', filename);
        end

        % 텍스트 전체를 읽어서 라인별로 분리 (Cell Array)
        raw_text = textscan(fid, '%s', 'Delimiter', '\n');
        fclose(fid);
        lines = raw_text{1};

    catch ME
        fprintf('Error reading file: %s\n', ME.message);
        continue;
    end

    % 2-2. TLE 라인 추출 (Line 1과 Line 2 분리)
    % "1 "로 시작하는 줄과 "2 "로 시작하는 줄을 찾음
    idx_l1 = find(startsWith(lines, '1 '));
    idx_l2 = find(startsWith(lines, '2 '));

    count = length(idx_l1);

    % 데이터 무결성 체크 (Line 1과 Line 2 개수 일치 여부)
    if length(idx_l1) ~= length(idx_l2)
        warning('Line 1과 Line 2의 개수가 일치하지 않습니다. 데이터 확인 필요.');
    end

    % 2-3. 시작 및 종료 Epoch 파싱
    if count > 0
        % 첫 번째 TLE의 Epoch (Line 1, col 19-32)
        first_line1 = lines{idx_l1(1)};
        start_epoch_str = first_line1(19:32); % YYDDD.DDDDDDDD 형식

        % 마지막 TLE의 Epoch
        last_line1 = lines{idx_l1(end)};
        end_epoch_str = last_line1(19:32);

        % (선택사항) Epoch 문자열을 보기 좋게 변환 (YY년 DDD일)
        start_yr = str2double(start_epoch_str(1:2));
        start_doy = str2double(start_epoch_str(3:end));
        end_yr = str2double(end_epoch_str(1:2));
        end_doy = str2double(end_epoch_str(3:end));

        % 2000년대 보정 (57보다 작으면 2000년대, 크면 1900년대 - NORAD 표준)
        start_full_yr = (start_yr < 57) * 2000 + start_yr + (start_yr >= 57) * 1900;
        end_full_yr   = (end_yr < 57) * 2000 + end_yr + (end_yr >= 57) * 1900;

        % 2-4. 결과 출력
        fprintf('  - Total TLE Sets : %d sets\n', count);
        fprintf('  - Start Epoch    : Year %d, DOY %.4f (Raw: %s)\n', ...
            start_full_yr, start_doy, start_epoch_str);
        fprintf('  - End Epoch      : Year %d, DOY %.4f (Raw: %s)\n', ...
            end_full_yr, end_doy, end_epoch_str);

        % 2-5. 추후 처리를 위해 데이터 저장
        TLE_DB(k).filename = filename;
        TLE_DB(k).count = count;
        % 해당 파일의 Line 1, Line 2 전체 저장
        TLE_DB(k).line1 = lines(idx_l1);
        TLE_DB(k).line2 = lines(idx_l2);

    else
        fprintf('  - No valid TLE data found.\n');
    end
    fprintf('----------------------------------------------------------------\n');
end

fprintf('\nData loading complete. Ready for SGP4 propagation.\n');

% TLE_DB 구조체에는 이제 다음과 같은 정보가 들어있습니다.
%
% -------------------------------------------------------------------------
% MAIN SGP4 Propagation Script - Part 2: Propagation using SGP4
% -------------------------------------------------------------------------
% Part 1에서 생성된 TLE_DB를 사용하여, 첫 번째 TLE를 초기값으로 설정하고
% 마지막 TLE 시점까지 전파를 수행합니다.
% -------------------------------------------------------------------------

fprintf('\n================================================================\n');
fprintf('                SGP4 PROPAGATION EXECUTION                      \n');
fprintf('================================================================\n');

%% 3. SGP4 전파 루프 (파일별 수행)
for k = 1:num_files
    % 현재 처리 중인 파일 정보
    current_file = TLE_DB(k).filename;
    count = TLE_DB(k).count;
    
    if count < 2
        fprintf('[%s]: 데이터가 충분하지 않아 전파를 건너뜁니다.\n', current_file);
        continue;
    end
    
    fprintf('\n[Target File %d]: %s\n', k, current_file);
    
    % ---------------------------------------------------------------------
    % 3-1. 초기 TLE (First Set) 파싱 및 전역 변수 설정
    % ---------------------------------------------------------------------
    line1_first = TLE_DB(k).line1{1};
    line2_first = TLE_DB(k).line2{1};
    
    % TLE 파싱 (SGP4 입력 변수 추출)
    % Line 1 Parsing
    epoch_str   = line1_first(19:32);
    epoch_yr    = str2double(epoch_str(1:2));
    epoch_days  = str2double(epoch_str(3:end));
    
    % Epoch Julian Date 계산 (시간차 계산용)
    if epoch_yr < 57
        year = 2000 + epoch_yr;
    else
        year = 1900 + epoch_yr;
    end
    [mon, day, hr, minute, sec] = days2mdh(year, epoch_days);
    jd_start = jday(year, mon, day, hr, minute, sec);
    
    % Bstar 항력 계수 (지수 표기법 변환 필요: 12345-6 -> 0.12345e-6)
    bstar_str = line1_first(54:61);
    if ~isempty(strfind(bstar_str, '-')) || ~isempty(strfind(bstar_str, '+'))
         % 지수 부호가 있는 경우 (표준 포맷)
         % 보통 TLE는 12345-6 형태로 오므로 'E'를 넣어줘야 함
         % 예: " 12345-5" -> "0.12345E-5" 로 변환 로직 필요
         % 간단한 파싱: (가수) * 10^(지수)
         mantissa = str2double(bstar_str(1:end-2)); 
         exponent = str2double(bstar_str(end-1:end));
         bstar = mantissa * 1e-5 * 10^exponent; 
    else
         bstar = 0; % 예외 처리
    end

    % Line 2 Parsing (SGP4 핵심 궤도 요소)
    xincl   = str2double(line2_first(9:16)) * (pi / 180); % deg -> rad
    xnodeo  = str2double(line2_first(18:25)) * (pi / 180);
    eo      = str2double(['0.' line2_first(27:33)]);      % 0. 생략됨
    omegao  = str2double(line2_first(35:42)) * (pi / 180);
    xmo     = str2double(line2_first(44:51)) * (pi / 180);
    xno     = str2double(line2_first(53:63));             % rev/day
    xno     = xno * (2 * pi / 1440.0);                    % rev/day -> rad/min
    
    % ---------------------------------------------------------------------
    % 3-2. 목표 시간 (Last Set) 설정
    % ---------------------------------------------------------------------
    line1_last = TLE_DB(k).line1{end};
    end_epoch_str = line1_last(19:32);
    end_epoch_yr  = str2double(end_epoch_str(1:2));
    end_epoch_days = str2double(end_epoch_str(3:end));
    
    if end_epoch_yr < 57
        end_year = 2000 + end_epoch_yr;
    else
        end_year = 1900 + end_epoch_yr;
    end
    [em, ed, eh, emi, es] = days2mdh(end_year, end_epoch_days);
    jd_end = jday(end_year, em, ed, eh, emi, es);
    
    % 전파 시간 계산 (분 단위)
    tsince_target = (jd_end - jd_start) * 1440.0; 
    
    fprintf('  - Initial Epoch : %d-%.4f (JD: %.4f)\n', year, epoch_days, jd_start);
    fprintf('  - Target  Epoch : %d-%.4f (JD: %.4f)\n', end_year, end_epoch_days, jd_end);
    fprintf('  - Prop. Time    : %.4f minutes (%.4f days)\n', tsince_target, tsince_target/1440);
    
    % ---------------------------------------------------------------------
    % 3-3. SGP4 전파 수행
    % ---------------------------------------------------------------------
    iflag = 1; % 초기화 모드 설정
    
    % (1) t = 0 (Initial State Check)
    [r0, v0] = sgp4(0);
    
    % (2) t = Target (Propagation)
    iflag = 0; % 전파 모드
    [r_final, v_final] = sgp4(tsince_target);
    
    % ---------------------------------------------------------------------
    % 3-4. 결과 출력
    % ---------------------------------------------------------------------
    fprintf('  --------------------------------------------------------------\n');
    fprintf('  [Propagation Result]\n');
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







% -------------------------------------------------------------------------
% Helper Functions (MATLAB 내장 함수가 없는 경우를 대비해 하단에 추가 필요)
% -------------------------------------------------------------------------
function [mon, day, hr, minute, sec] = days2mdh(year, days)
    % Day of Year를 월, 일, 시, 분, 초로 변환
    lmonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (mod(year, 4) == 0 && mod(year, 100) ~= 0) || mod(year, 400) == 0
        lmonth(2) = 29;
    end
    day_int = floor(days);
    i = 1;
    while day_int > lmonth(i)
        day_int = day_int - lmonth(i);
        i = i + 1;
    end
    mon = i;
    day = day_int;
    temp = (days - floor(days)) * 24.0;
    hr = floor(temp);
    temp = (temp - hr) * 60.0;
    minute = floor(temp);
    sec = (temp - minute) * 60.0;
end

function jd = jday(yr, mon, day, hr, min, sec)
    % Gregorian 날짜를 Julian Date로 변환
    jd = 367.0 * yr - floor((7 * (yr + floor((mon + 9) / 12.0))) * 0.25) ...
        + floor(275 * mon / 9.0) + day + 1721013.5 ...
        + ((sec / 60.0 + min) / 60.0 + hr) / 24.0;
end