# VO2 Threshold Analyzer

A comprehensive R-based tool for automated analysis of cardiopulmonary exercise test (CPET) data, featuring advanced ventilatory threshold detection and metabolic profiling for exercise physiology laboratories.

## Overview

VO2 Threshold Analyzer is designed for exercise physiology labs, clinical settings, and research facilities conducting VO2 max testing. The software provides automated detection of ventilatory thresholds (VT1/VT2) using multiple analytical approaches and generates comprehensive PDF reports with metabolic and cardiovascular analysis.

### Key Features

- **Automated Ventilatory Threshold Detection**: Multiple methods for VT1 and VT2 identification
- **Substrate Utilization Analysis**: CHO and FAT oxidation rate calculations
- **Comprehensive Reporting**: Professional PDF reports with 18+ analytical plots
- **Interactive Data Input**: Guided prompts for athlete/subject information
- **Multiple Threshold Methods**: 
  - VO2 vs VCO2 inflection analysis
  - VCO2 vs VE breakpoint detection
  - Ve/VO2 and Ve/VCO2 ratio analysis
- **Power-Based Analysis**: Heart rate, substrate utilization vs power output

## Methodology

The analysis employs established exercise physiology principles:

- **VT1 Detection**: VO2-VCO2 relationship inflection point using dual linear regression
- **VT2 Detection**: VCO2-VE relationship breakpoint analysis
- **Alternative Thresholds**: Ve/VO2 and Ve/VCO2 ratio inflection points
- **Substrate Analysis**: Respiratory exchange ratio (RER) based CHO/FAT calculations
- **Stage-Based Averaging**: Last 4 data points per stage for steady-state analysis

## Input Data Format

The program expects CSV files with a specific 3-row header format commonly output by metabolic analyzers:

```
Row 1: Parameter names (TIME, VO2, VO2/kg, METS, VCO2, VE, RER, RR, Vt, FEO2, FECO2, HR, LOAD, BIKE, AcKcal, %CHO, CHO, %FAT, FAT)
Row 2: Units/conditions (STPD, BTPS, etc.)
Row 3: Specific units (min, L/min, ml/kg/m, BPM, etc.)
Row 4: Data separator line
Row 5+: Actual data values
```

**Required CSV filename**: `Test VO2.csv` (must be in working directory)

### Expected Columns:
- **TIME**: Time in minutes
- **VO2**: Oxygen uptake (L/min, STPD)
- **VO2/kg**: Relative VO2 (ml/kg/min)
- **VCO2**: Carbon dioxide production (L/min, STPD)
- **VE**: Minute ventilation (L/min, BTPS)
- **HR**: Heart rate (bpm)
- **RER**: Respiratory exchange ratio
- **CHO/FAT**: Substrate utilization rates (g/min)
- **Power measurements**: LOAD_PROG and BIKE_MEAS (Watts)

## Installation

### Prerequisites

- **R Version**: 4.0.0 or higher
- **Operating System**: Windows, macOS, or Linux
- **Memory**: Minimum 4GB RAM recommended

### Required R Packages

```r
install.packages(c(
  "dplyr",
  "ggplot2", 
  "segmented",
  "grid",
  "gridExtra",
  "gtable"
))
```

### Installation Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/VO2-Threshold-Analyzer.git
   cd VO2-Threshold-Analyzer
   ```

2. **Install dependencies**:
   ```r
   source("install_packages.R")  # If provided
   # OR manually install packages listed above
   ```

3. **Prepare your data**:
   - Place your VO2 test CSV file in the working directory
   - Rename it to `Test VO2.csv`

## 📈 Usage

### Basic Usage

1. **Start R/RStudio** and set working directory to the project folder
2. **Load the script**:
   ```r
   source("VO2_Analysis.R")
   ```
3. **Run the analysis** (use Ctrl+Shift+Enter in RStudio):
   - Follow interactive prompts for athlete information
   - Enter test parameters (stages, duration, power levels)
   - Review generated tables and plots

### Interactive Prompts

The program will request:
- **Athlete Information**: Name, height, weight, age, sport
- **Test Details**: Date, number of stages, stage duration
- **Power Levels**: Watts for each completed stage

### Input Validation

- **Automatic validation** for all numeric inputs
- **Maximum 3 attempts** per input field
- **Error handling** for missing or invalid data

## Outputs

### Generated Files

1. **`Athlete_Report.pdf`**: Comprehensive analysis report containing:
   - Athlete demographics and test parameters
   - Stage-by-stage summary table
   - Ventilatory threshold identification table
   - 18 analytical plots including:
     - Power vs HR, CHO, FAT relationships
     - Time-series plots (VO2, HR, VE, RER)
     - Threshold detection plots with inflection points
     - Substrate utilization profiles

### Console Output

- **Summary tables** displayed during analysis
- **Threshold coordinates** (VT1, VT2 values)
- **Progress indicators** and validation messages

### Plot Categories

1. **Performance Plots**: Power vs HR/CHO/FAT
2. **Time Series**: VO2, HR, VE, RER progression
3. **Threshold Analysis**: VO2-VCO2, VCO2-VE relationships
4. **Ventilatory Efficiency**: Ve/VO2, Ve/VCO2 ratios
5. **Metabolic Analysis**: RER and substrate utilization

## Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| **File not found error** | Ensure `Test VO2.csv` is in working directory |
| **Package loading errors** | Install missing packages: `install.packages("package_name")` |
| **Invalid input errors** | Check CSV format matches expected 3-row header structure |
| **Empty stage data** | Verify stage times align with actual test data |
| **PDF generation fails** | Ensure write permissions in working directory |

### Data Quality Checks

- **Missing values**: Program handles NA values gracefully
- **Stage alignment**: Warns if no data found for specified stage times
- **Threshold detection**: May fail if insufficient data or unusual patterns

## Scientific Background

### Ventilatory Threshold Concepts

- **VT1 (Aerobic Threshold)**: First ventilatory threshold, typically 65-75% VO2max
- **VT2 (Anaerobic Threshold)**: Second ventilatory threshold, typically 80-90% VO2max
- **Gas Exchange Threshold**: Inflection in VO2-VCO2 relationship
- **Ventilatory Equivalent**: Changes in Ve/VO2 and Ve/VCO2 ratios

### Applications

- **Athletic Performance**: Training zone determination
- **Clinical Assessment**: Cardiovascular and pulmonary function
- **Research**: Metabolic profiling and intervention studies
- **Return-to-Play**: Fitness assessment protocols

## Contributing

We welcome contributions from the exercise physiology and research communities:

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/new-analysis`
3. **Commit changes**: `git commit -am 'Add new threshold method'`
4. **Push to branch**: `git push origin feature/new-analysis`
5. **Submit Pull Request**

### Development Guidelines

- **Code Style**: Follow R style guidelines
- **Documentation**: Comment complex algorithms
- **Testing**: Validate with known datasets
- **Peer Review**: Exercise physiology expertise preferred

## Support & Contact

**Tim Curry, MS ACSM-CEP, EIM**
- **Email**: curry.mtb@gmail.com
- **Phone**: 928-421-2544

For technical support, bug reports, or feature requests, please open an issue on GitHub or contact directly.

## License

This project is licensed under the MIT License 

## Acknowledgments

- **ACSM Guidelines**: Methodology based on ACSM's Guidelines for Exercise Testing and Prescription
- **Exercise Physiology Community**: For established threshold detection methods
- **R Community**: For excellent visualization and analysis packages

## Version History

- **v1.0.0**: Initial release with core threshold detection
- **Future**: Planned enhancements for additional threshold methods and export formats. If you have ideas for future versions please add them in the discussion area!

---

**Disclaimer**: This software is for research and clinical use. Always validate results with established protocols and clinical judgment. Not intended for diagnostic purposes without proper medical oversight.
