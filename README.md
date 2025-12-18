# SGP4-TLE-data

This repository contains MATLAB codes for handling **TLE (Two-Line Element) data** and performing
**orbit propagation using the SGP4 model**, with validation and comparison workflows.

The repository includes two main folders that use **different implementations of SGP4**, while
sharing common TLE datasets.

---

## TLE Data

Both folders (`demo_sv2tle1`, `AIAA_sgp4`) contain TLE set text files for the following satellites:

* **BEE1000**
* **COSMIC**

These TLE datasets are used as reference data for orbit propagation, validation, and error analysis.

---

## Folder Structure Overview

```
SGP4-TLE-data/
├── demo_sv2tle1/
└── AIAA_sgp4/
```

---

## demo_sv2tle1 Folder

This folder contains utilities for **TLE generation, SGP4 propagation, comparison, and visualization**
using the `sgp4.m` implementation located **within this folder**.

### Key Files

#### `demo_sv2tle1.m`

* Converts a satellite **ECI position and velocity vector** into a corresponding **TLE set**.
* Used when SGP4 propagation results need to be converted back into TLE format.
* **Important dependency** for comparison and error-analysis workflows.

---

#### `MAIN.m`

* Reads TLE data from a text file.
* Uses the local `sgp4.m` to propagate the orbit to a **specific target epoch**.
* Returns the propagated **position and velocity vectors**.

---

#### `MAIN2.m`

* Reads TLE data and propagates the orbit **until a final epoch**.
* Generates a **trajectory by propagating at fixed time intervals**.
* The saved trajectory is later used for plotting and orbital-element analysis.

---

#### `MAIN_COMPARE.m` (renamed from `COMPARE.m`)

* Compares:

  1. **Original TLE data**, and
  2. **SGP4-propagated results converted back into TLE format**.
* Workflow:

  * SGP4 propagation result → converted to TLE
    (using `demo_sv2tle1.m`)
  * Comparison is performed in **two ways**:

    * TLE-to-TLE comparison
    * RV (TEME) comparison after converting both TLEs to state vectors
* Since `demo_sv2tle1.m` is located in a different file set, **users must be careful about file dependencies**.

---

#### `MAIN_error.m`

* Performs an **end-to-end error analysis** over the entire propagation interval.
* Key difference from `MAIN_COMPARE.m`:

  * Converts both:

    * Actual TLE data → RV (TEME)
    * SGP4-predicted TLE → RV (TEME)
  * **Only one comparison is performed**:

    * RV (TEME) vs RV (TEME)
* No direct TLE-level comparison is conducted in this file.

---

### Plotting Utilities

#### `PLOT.m`

* Plots the orbit trajectory saved by `MAIN2.m`.

#### `PLOT2.m`

* Compares **TEME and ECI results** obtained from `MAIN.m`.
* State vectors are **hard-coded** for direct comparison.

#### `PLOT3.m`

* Converts the **TEME RV trajectory** from `MAIN2.m` into **orbital elements**.
* Plots the time history of the orbital elements.

#### `PLOT4.m`

* Computes and plots the **mean orbital elements**.
* These are obtained by removing short-period oscillations observed in `PLOT3.m`.

---

## AIAA_sgp4 Folder

This folder contains an **alternative SGP4 implementation**, following formulations commonly used in
**AIAA-related references**.

### Characteristics

* File names (`MAIN.m`, `MAIN2.m`) and functionality are **identical** to those in `demo_sv2tle1`.
* The only difference is that propagation is performed using the **SGP4 version located in the `AIAA_sgp4` folder**.
* This structure allows **direct comparison between different SGP4 implementations** under the same TLE conditions.

---

## Notes

* Care must be taken when converting SGP4 propagation results back into TLE format.
* In particular, `demo_sv2tle1.m` must be used explicitly, as it is required by comparison workflows but
  resides in a different file group.
* All comparisons are ultimately performed in the **TEME frame**, unless otherwise stated.

---

## Environment

* MATLAB (tested on R2023b)
* TLE-based propagation using SGP4
* Coordinates: ECI / TEME
