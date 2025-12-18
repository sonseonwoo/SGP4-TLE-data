% -------------------------------------------------------------------------
% MAIN2 SGP4 Propagation Script (Time-Series)
% -------------------------------------------------------------------------
% 기능:
%   1. TLE 파일을 읽어 초기 궤도 정보 로드
%   2. 초기 시점(First TLE)부터 종료 시점(Last TLE)까지 "1시간 간격"으로 전파
%   3. 종료 시점이 1시간 단위가 아니더라도 반드시 포함
%   4. 결과를 텍스트 파일과 변수에 저장
% -------------------------------------------------------------------------

clear; clc; close all;

global dtr rtd req mu

global e6a qo so tothrd x3pio2 j2 j3 j4 xke

global xkmper xmnpda ae ck2 ck4 ssgp qoms2t

global ri vi

global xmo xnodeo omegao eo xincl

global xno xndt2o xndd6o bstar

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
file_list = {'BEE1000_TLE.txt', 'COSMIC_TLE.txt'};
num_files = length(file_list);

% 데이터를 저장할 구조체 초기화
TLE_DB = struct('filename', {}, 'count', {}, 'data', {});
% 전파 결과를 저장할 셀 배열 (파일별로 저장)
Propagation_Results = cell(num_files, 1);

fprintf('================================================================\n');
fprintf('           SGP4 TIME-SERIES PROPAGATION START                   \n');
fprintf('================================================================\n');

%% 2. 데이터 로드 및 전파 루프
for k = 1:num_files
    filename = file_list{k};
    fprintf('\n[Processing File %d]: %s\n', k, filename);
    
    % ---------------------------------------------------------------------
    % 2-1. 파일 읽기 및 TLE 추출
    % ---------------------------------------------------------------------
    try
        fid = fopen(filename, 'r');
        if fid == -1, error('파일 없음: %s', filename); end
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
        fprintf('  - 데이터 부족 (최소 2세트 필요). Skip.\n');
        continue;
    end
    
    % 데이터 구조체 백업
    TLE_DB(k).filename = filename;
    TLE_DB(k).count = count;
    TLE_DB(k).line1 = lines(idx_l1);
    TLE_DB(k).line2 = lines(idx_l2);

    % ---------------------------------------------------------------------
    % 2-2. 초기 TLE (First Set) 파싱 -> Global 변수 입력
    % ---------------------------------------------------------------------
    line1_first = lines{idx_l1(1)};
    line2_first = lines{idx_l2(1)};
    
    % [Line 1 파싱]
    epoch_str   = line1_first(19:32);
    epoch_yr    = str2double(epoch_str(1:2));
    epoch_days  = str2double(epoch_str(3:end));
    
    % Bstar 파싱
    bstar_str = line1_first(54:61);
    if ~isempty(strfind(bstar_str, '-')) || ~isempty(strfind(bstar_str, '+'))
         mantissa = str2double(bstar_str(1:end-2)); 
         exponent = str2double(bstar_str(end-1:end));
         bstar = mantissa * 1e-5 * 10^exponent; 
    else
         bstar = 0; 
    end
    
    % [Line 2 파싱] -> Global 변수에 대입
    xincl   = str2double(line2_first(9:16)) * (pi / 180); % deg -> rad
    xnodeo  = str2double(line2_first(18:25)) * (pi / 180);
    eo      = str2double(['0.' line2_first(27:33)]);
    omegao  = str2double(line2_first(35:42)) * (pi / 180);
    xmo     = str2double(line2_first(44:51)) * (pi / 180);
    xno_rev = str2double(line2_first(53:63));             % rev/day
    xno     = xno_rev * (2 * pi / 1440.0);                % rad/min (Global)
    
    % Julian Date Start 계산
    start_year = (epoch_yr < 57) * 2000 + epoch_yr + (epoch_yr >= 57) * 1900;
    [mon, day, hr, minute, sec] = days2mdh(start_year, epoch_days);
    jd_start = jday(start_year, mon, day, hr, minute, sec);

    % ---------------------------------------------------------------------
    % 2-3. 목표 시간 (Last Set) 설정 및 시간 배열 생성
    % ---------------------------------------------------------------------
    line1_last = lines{idx_l1(end)};
    end_epoch_str = line1_last(19:32);
    end_yr  = str2double(end_epoch_str(1:2));
    end_days = str2double(end_epoch_str(3:end));
    end_year = (end_yr < 57) * 2000 + end_yr + (end_yr >= 57) * 1900;
    
    [em, ed, eh, emi, es] = days2mdh(end_year, end_days);
    jd_end = jday(end_year, em, ed, eh, emi, es);
    
    % 총 전파 시간 (분)
    tsince_total = (jd_end - jd_start) * 1440.0;
    
    % [시간 배열 생성] 0부터 tsince_total까지 60분 간격
    dt = 1.0; % 1시간 간격
    time_steps = 0:dt:tsince_total;
    
    % [중요] 마지막 시점이 1시간 단위로 딱 떨어지지 않으면 강제 추가
    if abs(time_steps(end) - tsince_total) > 1e-6
        time_steps = [time_steps, tsince_total];
    end
    
    num_steps = length(time_steps);
    
    fprintf('  - Start Epoch    : %d-%.4f\n', start_year, epoch_days);
    fprintf('  - End Epoch      : %d-%.4f\n', end_year, end_days);
    fprintf('  - Duration       : %.2f mins (%.2f hours)\n', tsince_total, tsince_total/60);
    fprintf('  - Simulation Steps: %d steps (include final epoch)\n', num_steps);

    % ---------------------------------------------------------------------
    % 2-4. SGP4 전파 수행 (Time Loop)
    % ---------------------------------------------------------------------
    
    % 결과 저장용 행렬: [Time(min), rx, ry, rz, vx, vy, vz]
    result_matrix = zeros(num_steps, 7);
    
    iflag = 1; % 초기화 플래그 (첫 호출 시 1, 이후 0)
    
    for t_idx = 1:num_steps
        tsince = time_steps(t_idx);
        
        % SGP4 호출 (Global 변수 사용)
        [r, v] = sgp4(tsince);
        
        % 첫 번째 호출(초기화) 후에는 전파 모드로 변경
        if iflag == 1
            iflag = 0; 
        end
        
        % 결과 저장
        result_matrix(t_idx, :) = [tsince, r(1), r(2), r(3), v(1), v(2), v(3)];
    end
    
    Propagation_Results{k} = result_matrix;
    
    % ---------------------------------------------------------------------
    % 2-5. 결과 파일 저장 (.txt)
    % ---------------------------------------------------------------------
    out_name = ['Result_' strrep(filename, '.txt', '') '.txt'];
    fid_out = fopen(out_name, 'w');
    fprintf(fid_out, '%% Time(min)      Rx(km)        Ry(km)        Rz(km)        Vx(km/s)      Vy(km/s)      Vz(km/s)\n');
    fprintf(fid_out, '%12.4f %14.6f %14.6f %14.6f %14.9f %14.9f %14.9f\n', result_matrix');
    fclose(fid_out);
    
    fprintf('  -> Result saved to: %s\n', out_name);
end

fprintf('\nAll Process Completed.\n');


%% -------------------------------------------------------------------------
% Helper Functions
% -------------------------------------------------------------------------
function [mon, day, hr, minute, sec] = days2mdh(year, days)
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
    jd = 367.0 * yr - floor((7 * (yr + floor((mon + 9) / 12.0))) * 0.25) ...
        + floor(275 * mon / 9.0) + day + 1721013.5 ...
        + ((sec / 60.0 + min) / 60.0 + hr) / 24.0;
end