# Lunar Eclipse Calendar Generator (Ring)

A comprehensive lunar eclipse calculator written in the [Ring programming language](https://ring-lang.github.io/) that computes and lists all lunar eclipses (total, partial, and penumbral) within a specified year range.

## Overview

This program calculates lunar eclipses by minimizing the Moon–shadow-axis separation to find the instant near greatest eclipse. For each eclipse, it reports:

- Date and time (in Universal Time)
- Classification (Total, Partial, or Penumbral)
- Angular separation from shadow axis (ρ)
- Node separation
- Lunar latitude
- Lunar radius and dynamic shadow radii (umbra and penumbra)
- Lunar distance from Earth

## Features

- **Wide Historical Range**: Supports calculations from year -4000 to +4000
- **Three Eclipse Types**: Identifies total, partial, and penumbral lunar eclipses
- **Dynamic Shadow Calculation**: Computes umbra and penumbra radii based on actual Sun-Earth-Moon geometry
- **High-Resolution Search**: Uses iterative refinement to locate eclipse maxima
- **Detailed Output**: Provides comprehensive geometric parameters for each eclipse
- **Delta-T Correction**: Automatically converts between Terrestrial Time (TT) and Universal Time (UT)

## Requirements

- [Ring programming language](https://ring-lang.github.io/) (version 1.22 or higher)

## Installation

1. Ensure Ring is installed on your system
2. Clone this repository:
   ```bash
   git clone https://github.com/idrassi/LunarEclipseCalendarGenerator-Ring.git
   cd LunarEclipseCalendarGenerator-Ring
   ```

## Usage

Run the program using the Ring interpreter:

```bash
ring Lunar_Eclipse_Calendar_Generator.ring
```

When prompted, enter the start and end years for your desired range:

```
Lunar Eclipse Calendar Generator
Enter start year: 2022
Enter end year: 2030
```

### Example Output

```
Lunar Eclipse Calendar Generator
Enter start year: 2022
Enter end year: 2030
Lunar Eclipse Calendar Generator
----------------------------------------------------------------------------------------------------------------------------------------
Range: 2022 to 2030
Classification uses dynamic shadow sizes and center-axis separation Rho (deg).
----------------------------------------------------------------------------------------------------------------------------------------
#     Date        Time   Type          Rho (deg)  NodeSep_deg   Lat_deg  LunarRadius_deg   Umbra_deg  Penumbral_deg     Dist_km
----------------------------------------------------------------------------------------------------------------------------------------
1     2022-05-16  04:11  Total             0.260        5.999    -0.258            0.275       0.746         1.273      362095
2     2022-11-08  11:00  Total             0.243        1.884     0.241            0.255       0.666         1.205      390649
3     2023-05-05  17:24  Penumbral         0.996       16.466    -0.991            0.262       0.697         1.226      380196
4     2023-10-28  20:14  Partial           0.937        6.400     0.931            0.269       0.720         1.257      369685
5     2024-03-25  07:14  Penumbral         0.955        9.598     0.951            0.246       0.634         1.169      405420
6     2024-09-18  02:44  Partial           1.004       10.483    -1.001            0.278       0.757         1.288      357459
7     2025-03-14  06:59  Total             0.317        6.539     0.317            0.248       0.642         1.178      401495
8     2025-09-07  18:13  Total             0.274        1.241    -0.272            0.269       0.724         1.253      369678
9     2026-03-03  11:34  Total             0.361        0.821    -0.359            0.260       0.686         1.224      382603
10    2026-08-28  04:13  Partial           0.463        9.949     0.460            0.255       0.672         1.200      390371
11    2027-02-20  23:14  Penumbral         1.055        8.799    -1.052            0.274       0.736         1.275      363335
12    2027-07-18  16:05  Penumbral         1.420       17.200    -1.412            0.245       0.638         1.162      406025
13    2027-08-17  07:18  Penumbral         1.155       14.833     1.151            0.246       0.639         1.165      405112
14    2028-01-12  04:13  Partial           0.997        8.918     0.993            0.276       0.743         1.285      360295
15    2028-07-06  18:22  Partial           0.732       12.753    -0.728            0.253       0.665         1.190      393944
16    2028-12-31  16:54  Total             0.319        1.258     0.315            0.264       0.697         1.239      377631
17    2029-06-26  03:24  Total             0.015        4.588     0.012            0.267       0.717         1.241      373264
18    2029-12-20  22:41  Total             0.348        7.638    -0.345            0.250       0.647         1.189      398133
19    2030-06-15  18:34  Partial           0.767        6.964     0.763            0.277       0.756         1.281      358754
20    2030-12-09  22:26  Penumbral         0.963       10.696    -0.957            0.245       0.629         1.170      406344
----------------------------------------------------------------------------------------------------------------------------------------
Summary:  Total     : 8  Partial   : 6  Penumbral : 6  All       : 20
----------------------------------------------------------------------------------------------------------------------------------------
Note: Times are near greatest eclipse by minimizing Moon-shadow-axis separation.
```

## Output Columns

| Column | Description |
|--------|-------------|
| # | Sequential eclipse number |
| Date | Date of greatest eclipse (YYYY-MM-DD) |
| Time | Time of greatest eclipse in UT (HH:MM) |
| Type | Eclipse classification (Total, Partial, or Penumbral) |
| Rho (deg) | Angular separation between Moon center and shadow axis |
| NodeSep_deg | Separation from lunar node |
| Lat_deg | Geocentric latitude of the Moon |
| LunarRadius_deg | Angular radius of the Moon |
| Umbra_deg | Angular radius of Earth's umbral shadow |
| Penumbral_deg | Angular radius of Earth's penumbral shadow |
| Dist_km | Geocentric distance to the Moon in kilometers |

## Technical Details

### Algorithm

The program uses:
- **Lunar Theory**: Compact periodic terms based on Meeus-style formulations with fundamental arguments (D, M, M', F)
- **Solar Position**: Simplified analytical model for Sun's ecliptic longitude and distance
- **Shadow Geometry**: Dynamic calculation of umbral and penumbral shadow cones
- **Eclipse Search**: Two-stage search (coarse + refinement) around mean full moon times

### Eclipse Classification

Eclipses are classified based on the angular separation (ρ) between the Moon's center and the shadow axis:

- **Total**: ρ ≤ R_umbra - R_moon (+ tolerance)
- **Partial**: R_umbra - R_moon < ρ ≤ R_umbra + R_moon (+ tolerance)
- **Penumbral**: R_umbra + R_moon < ρ ≤ R_penumbra + R_moon (+ tolerance)

## Limitations and Disclaimers

⚠️ **Important**: This program is intended for **calendar and educational purposes only**.

- **Not for Navigation**: Do not use for precise observatory planning or navigation
- **Simplified Model**: Uses compact periodic terms rather than full JPL ephemerides
- **Accuracy**: Times and circumstances may differ from authoritative sources by several minutes
- **Delta-T**: Uses an approximate polynomial fit for the TT-UT time difference
- **No Warranty**: Use at your own risk

For critical applications requiring high precision, consult:
- NASA Eclipse Website
- JPL HORIZONS System
- USNO Astronomical Almanac

## References

The astronomical algorithms are inspired by:
- Jean Meeus, *Astronomical Algorithms* (2nd Edition)
- Standard lunar theory periodic terms
- Fundamental argument formulations from modern ephemerides

## Author

**Mounir IDRASSI** with AI assistance (GPT-5 High)  
Date: October 8, 2025

## License

This project is provided as-is for educational and calendar purposes.
This is free and unencumbered software released into the public domain.
Please check the [LICENSE](LICENSE) file for more details.

## Contributing

Contributions, bug reports, and suggestions are welcome! Please open an issue or submit a pull request on GitHub.

## See Also

- [Ring Programming Language](https://ring-lang.github.io/)
- [NASA Eclipse Website](https://eclipse.gsfc.nasa.gov/lunar.html)
- [Five Millennium Canon of Lunar Eclipses](https://eclipse.gsfc.nasa.gov/LEcat5/LE2001-2100.html)
