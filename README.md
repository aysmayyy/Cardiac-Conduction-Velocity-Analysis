# Cardiac Conduction Velocity & Dispersion Analysis

## Overview
This MATLAB repository provides a specialized pipeline for analyzing 3D electroanatomical mapping data. It is designed to process electrode data from cardiac mapping systems to quantify the heart's electrical health and identify potential arrhythmic substrates.

> **Compatibility:** This pipeline is specifically designed for processing 3D electroanatomical mapping data exported from the **Boston Scientific Rhythmia HDx™** system using the **MATLAB Map Data (.mat)** export format.

## Key Features
* **3D Spatial Mapping:** Reconstructs the cardiac surface using XYZ coordinates and identifies regional point concentrations.
* **Automated Tissue Classification:** Categorizes tissue health based on voltage thresholds:
    * **Red (<0.5mV):** Dense Scar / Arrhythmic zone.
    * **Yellow (0.5mV - 1.5mV):** Border zone.
    * **Green (>1.5mV):** Healthy myocardium.
* **Conduction Velocity (CV) Calculation:** Calculates the speed of electrical propagation ($m/s$) across specific Regions of Interest (ROI).
* **Dispersion Analysis:** Measures the **Coefficient of Variation (CoV)** across different cardiac regions to identify abnormal electrical heterogeneity.
* **Advanced Visualization:** Generates 3D Activation Time maps, Voltage scatter plots, and Dispersion heatmaps.

## How it Works
1. **Outlier Filtering:** Uses `filloutliers` to remove signal noise from the voltage data before classification.
2. **Vectorized Math:** Employs `vecnorm` and matrix indexing for high-speed calculation of electrode distances.
3. **Region of Interest (ROI):** The script automatically identifies regions with high point density and low average voltage to prioritize velocity calculations in potential arrhythmic zones.
4. **Automated Visualization:** * **Figure 1:** 3D Activation Map using `trisurf` and `boundary` functions.
    * **Figure 2:** 3D Voltage Scatter Plot.
    * **Figure 3:** Regional Dispersion Bar Chart with automated "Abnormal" highlighting.
  
## Configuration
The script features a **Parameters & Configuration** section at the top, allowing you to customize the analysis for different datasets:

| Parameter | Default | Description |
| :--- | :--- | :--- |
| `FILE_NAME` | '21P70 Post Sinus.mat' | The name of the input data file. |
| `VOLT_SCAR_THRESHOLD` | 0.5 | Voltage (mV) below which tissue is classified as scar (Red). |
| `VOLT_HEALTHY_THRESHOLD` | 1.5 | Voltage (mV) above which tissue is considered healthy (Green). |
| `NUM_REGIONS` | 10 | Number of geographic slices for density and dispersion analysis. |
| `COV_STDEV_MULTIPLIER` | 1.5 | Sensitivity for flagging abnormal velocity dispersion. |

## Technical Improvements
The current version of this code has been optimized for:
* **Performance:** Uses pre-allocation and vectorized matrix operations (e.g., `vecnorm`) to ensure high-speed processing of large datasets.
* **Readability:** Modular structure using MATLAB sections (`%%`) and descriptive parameter definitions.
* **Robustness:** Includes outlier detection and automated handling of non-finite velocity values.

## Requirements
* **MATLAB** (or **GNU Octave** for open-source use).
* Input data should be a `.mat` file containing a `surfaceElectrodes` structure with `surfaceLocation_mm`, `activation`, and `voltage` fields.

## How to Use
1. Place your `.mat` data file in the project directory.
2. Update the `FILE_NAME` parameter in the script configuration section.
3. Run the script to generate the 3D maps and velocity statistics.


