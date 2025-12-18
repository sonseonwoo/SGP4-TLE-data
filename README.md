# SGP4-TLE-data

이 레포지토리는 MATLAB 기반으로 **TLE(Two-Line Element) 데이터 처리**,  
**SGP4 궤도 전파**, **비교 및 오차 분석**, **시각화(플로팅)**를 수행하는 코드 모음이다.

---

## TLE 데이터

- `AIAA_sgp4`, `demo_sv2tle1` 폴더 모두 아래 위성의 **TLE set (.txt)**을 포함한다.
  - **BEE1000**
  - **COSMIC**

---

- **AIAA_sgp4 폴더**에 전반적인 기능 파일(비교, 오차분석, 플롯 등)이 모두 포함되어 있다.
- **demo_sv2tle1 폴더**에는 `demo_sv2tle1.m`과 `MAIN.m`, `MAIN2.m`만 포함되어 있다.
- `demo_sv2tle1/MAIN`, `demo_sv2tle1/MAIN2`의 기능은  
  `AIAA_sgp4/MAIN`, `AIAA_sgp4/MAIN2`와 **동일**하며,  
  **차이점은 사용하는 `sgp4.m`의 버전**이다.

---

## demo_sv2tle1 폴더 설명

### demo_sv2tle1.m
- 위성의 **ECI 위치·속도 벡터 (r, v)**를 입력으로 받아 **TLE 데이터로 변환**하는 파일
- SGP4 전파 결과를 다시 TLE로 바꿀 때 사용됨
- 비교 및 오차 분석 과정에서 **중요한 의존 파일**

---

### MAIN.m
- TLE 데이터를 읽어와 폴더 내 `sgp4.m`을 사용하여
  **특정 시점(epoch)까지 궤도 전파**
- 전파 결과 **위치·속도 벡터 (r, v)**를 반환

---

### MAIN2.m
- 종료 시점까지 **일정 시간 간격**으로 전파하여 **궤적(trajectory)** 생성
- 생성된 궤적은 이후 플로팅 및 궤도요소 분석에 사용됨

---

## AIAA_sgp4 폴더 설명

AIAA_sgp4 폴더에는 레포지토리의 **주요 기능 파일 대부분**이 포함되어 있다.

### MAIN.m, MAIN2.m
- 기능은 `demo_sv2tle1` 폴더의 `MAIN.m`, `MAIN2.m`와 **동일**
- 단, **AIAA_sgp4 폴더 내부의 다른 sgp4.m 버전**을 사용하여 전파 수행
- 동일한 TLE 조건에서 **SGP4 구현 버전 차이에 따른 결과 비교**가 가능함

---

## 비교 및 오차 분석 파일 (AIAA_sgp4)

### MAIN_COMPARE.m  
*(이전 파일명: COMPARE.m)*

- **실제 TLE 데이터**와  
  **SGP4 전파 결과를 다시 TLE로 변환한 값**을 비교하는 파일
- 사용 시 주의사항:
  - SGP4 전파 결과(r, v)를 **TLE로 변환**해야 함
  - 이때 **demo_sv2tle1 폴더의 `demo_sv2tle1.m`을 사용**
  - 관련 파일이 서로 다른 폴더에 있어 혼동 가능

#### 수행하는 비교 (2가지)
1. **TLE 정보 자체 비교** (TLE vs TLE)
2. 두 TLE를 각각 **RV로 변환 후(TEME)** 비교 (TEME 좌표계)

---

### MAIN_error.m

- 비교 동작을 **전체 전파 구간에 대해 수행**하는 오차 분석 파일
- `MAIN_COMPARE.m`과의 차이점:
  - TLE → RV(TEME) 변환 후
  - **RV(TEME)끼리의 비교만 수행**

정리하면:
- `MAIN_COMPARE.m`  
  → TLE 비교 + TLE→RV 변환 후 TEME 비교
- `MAIN_error.m`  
  → TLE→RV 변환 후 TEME 비교 **1가지만 수행**

---

## 플로팅(시각화) 파일 (AIAA_sgp4)

### PLOT.m
- `MAIN2.m`에서 저장한 **궤도 전파 궤적**을 시각화

---

### PLOT2.m
- `MAIN.m`에서 수행한 **TEME 결과와 ECI 결과**를 비교
- 비교를 위해 결과 벡터가 **하드코딩**되어 있음

---

### PLOT3.m
- `MAIN2.m` 예측 궤적의 **TEME 좌표계 r,v**를
  **궤도요소(orbital elements)**로 변환하여 플롯

---

### PLOT4.m
- `PLOT3.m`에서 나타나는 궤도요소의 **진동(단주기 성분)**을 보정
- 보정 후 **평균 궤도요소(mean values)**를 나타냄

---

## 사용 시 주의사항

- SGP4 전파 결과를 **TLE로 재생성해야 하는 경우**
  → 반드시 `demo_sv2tle1.m` 사용
- 폴더별로 사용하는 `sgp4.m`이 다르므로,
  **어느 폴더의 MAIN/MAIN2를 실행했는지 혼동하지 않도록 주의**

