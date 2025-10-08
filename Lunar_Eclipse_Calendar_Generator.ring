# Lunar Eclipse Calendar Generator
#
# Purpose:
#   Compute and list lunar eclipses (total, partial, penumbral) within a year range.
#   For each eclipse the program attempts to find the instant near greatest eclipse
#   by minimizing the Moon–shadow-axis separation, then prints date/time (UT),
#   classification, angular separation (rho), node separation, lunar latitude,
#   lunar radius and dynamic shadow radii, and lunar distance.
#
# Usage:
#   Run the script and enter a start year and end year when prompted.
#   Year range supported by the model: -4000 .. 4000
#
# Notes & limitations:
#   - Uses a compact set of periodic terms for the Moon and a simple Sun model.
#   - Times are located by searching around mean full moon instants and reported
#     as UT after a simple TT→UT conversion using a delta-T estimate.
#   - Intended for calendar/educational purposes; not authoritative for navigation
#     or precise observatory planning. Use high-precision ephemerides for critical needs.
#   - No warranty; use at your own risk.
#
# References:
#   - Fundamental argument series and periodic terms inspired by standard
#     lunar theory (Meeus-style formulations) and simple shadow geometry.
#
# Author: Mounir Idrassi with AI assistance (GPT-5 High)
# Date: October 8th 2025

# -----------------------------
# Constants
# -----------------------------
PI  = 3.141592653589793
J2000 = 2451545.0
NEWMOON_JDE0 = 2451550.09765
SYNODIC_MONTH = 29.530588853
AU_KM = 149597870.700
EARTH_EQUAT_RADIUS_KM = 6378.1366
MOON_RADIUS_KM = 1737.4
ECLIPSE_EPSILON = 0.015

# -----------------------------
# Main
# -----------------------------
see "Lunar Eclipse Calendar Generator" + nl
see "Enter start year: "
give startYear
see "Enter end year: "
give endYear

startYear = number(startYear)
endYear   = number(endYear)

if (startYear < -4000) or (endYear > 4000)
    see "Year range out of supported scope for this model (-4000..4000)." + nl
    bye
ok

generate_calendar(startYear, endYear)
bye

# -----------------------------
# Math helpers
# -----------------------------
func deg2rad(d)
    return d * (PI / 180.0)

func rad2deg(r)
    return r * (180.0 / PI)

func fmodd(a,b)
    # floating modulus a - b*floor(a/b)
    return a - b * floor(a / b)

func norm360(a)
    x = fmodd(a, 360.0)
    if x < 0 x = x + 360.0 ok
    return x

func norm180(a)
    x = fmodd(a, 360.0)
    if x > 180.0 x = x - 360.0 ok
    if x <= -180.0 x = x + 360.0 ok
    return x

func abs(x)
    if x < 0 return -x ok
    return x

func clamp(x, lo, hi)
    if x < lo return lo ok
    if x > hi return hi ok
    return x

func iif(condition, trueValue, falseValue)
    if condition
        return trueValue
    else
        return falseValue
    ok

func round_int(x)
    if x >= 0
        return floor(x + 0.5)
    else
        return -floor(-x + 0.5)
    ok

func round_to(x, decimals)
    scale = pow(10.0, decimals)
    return round_int(x * scale) / scale

# -----------------------------
# Time and calendar helpers
# -----------------------------
func deltaT_seconds(year)
    t = year - 2000.0
    if (year >= 2000) and (year <= 2100)
        return 62.92 + 0.32217 * t + 0.005589 * t * t
    ok
    return 69.0

func jd_from_ymd_utc(year, month, day, hour)
    a = floor((14 - month) / 12)
    y = year + 4800 - a
    m = month + 12 * a - 3
    JDN = day + floor((153 * m + 2) / 5) + 365 * y + floor(y/4) - floor(y/100) + floor(y/400) - 32045
    fracDay = hour / 24.0
    return JDN - 0.5 + fracDay

func ymdhm_from_jd(jd)
    Z = floor(jd + 0.5)
    F = (jd + 0.5) - Z
    A = Z
    alpha = floor((A - 1867216.25) / 36524.25)
    B = A + 1 + alpha - floor(alpha / 4)
    C = B + 1524
    D = floor((C - 122.1) / 365.25)
    E = floor(365.25 * D)
    G = floor((C - E) / 30.6001)

    dayf = C - E - floor(30.6001 * G) + F
    dayInt = floor(dayf)
    frac = dayf - dayInt

    month = iif(G < 14, G - 1, G - 13)
    year  = iif(month > 2, D - 4716, D - 4715)

    totalMinutes = floor(frac * 24.0 * 60.0 + 0.5)

    if totalMinutes >= 1440
        totalMinutes = totalMinutes - 1440
        dayInt = dayInt + 1
        # Recompute with minute carryover to stay consistent
        jd2 = jd + (1.0 / 1440.0)
        return ymdhm_from_jd(jd2)
    ok

    hh = floor(totalMinutes / 60)
    mm = totalMinutes % 60

    return [year, month, dayInt, hh, mm]

# -----------------------------
# Fundamental arguments (deg)
# -----------------------------
func fundamental_args_deg(jde)
    T = (jde - J2000) / 36525.0

    Dd  = 297.8501921 + 445267.1114034 * T - 0.0018819 * T*T + T*T*T/545868.0 - T*T*T*T/113065000.0
    Mm  = 357.5291092 + 35999.0502909 * T - 0.0001536 * T*T + T*T*T/24490000.0
    Mpv = 134.9633964 + 477198.8675055 * T + 0.0087414 * T*T + T*T*T/69699.0 - T*T*T*T/14712000.0
    Fv  = 93.2720950  + 483202.0175233 * T - 0.0036539 * T*T - T*T*T/3526000.0 + T*T*T*T/863310000.0

    D  = norm360(Dd)
    M  = norm360(Mm)
    Mp = norm360(Mpv)
    F  = norm360(Fv)

    return [D, M, Mp, F]

# -----------------------------
# Sun position (longitude, distance in AU, apparent semidiameter in degrees)
# -----------------------------
func sun_longitude_radius(jde)
    T = (jde - J2000) / 36525.0

    L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T*T
    M  = 357.52911 + 35999.05029 * T - 0.0001537 * T*T + 0.00000048 * T*T*T
    Mr = deg2rad(norm360(M))

    C = (1.914602 - 0.004817 * T - 0.000014 * T*T) * sin(Mr) + 
        (0.019993 - 0.000101 * T) * sin(2*Mr) + 
         0.000289 * sin(3*Mr)

    true_long = norm360(L0 + C)
    e = 0.016708634 - 0.000042037 * T - 0.0000001267 * T*T
    v = norm360(M + C)
    vr = deg2rad(v)
    r = (1.000001018 * (1 - e*e)) / (1 + e * cos(vr))
    sd = (959.63 / 3600.0) / r

    return [true_long, r, sd]

func moon_mean_longitude_deg(jde)
    T = (jde - J2000) / 36525.0
    Lp = 218.3164477 + 481267.88123421 * T - 0.0015786 * T*T + T*T*T / 538841.0 - T*T*T*T / 65194000.0
    return norm360(Lp)

# -----------------------------
# Moon geocentric longitude (deg), latitude (deg), distance (km)
# -----------------------------
func moon_llb_distance(jde)
	args = fundamental_args_deg(jde)
    D = args[1]
	M = args[2]
	Mp = args[3]
	F = args[4]
    Dr = deg2rad(D) ; Mr = deg2rad(M) ; Mpr = deg2rad(Mp) ; Fr = deg2rad(F)

    T = (jde - J2000) / 36525.0
    E = 1.0 - 0.002516 * T - 0.0000074 * T * T
    E2 = E * E

    # Longitude correction (enhanced)
    l_corr = 0.0
    l_corr += 6.288774 * sin(Mpr)
    l_corr += 1.274027 * sin(2*Dr - Mpr)
    l_corr += 0.658314 * sin(2*Dr)
    l_corr += 0.213618 * sin(2*Mpr)
    l_corr += -0.185116 * E * sin(Mr)
    l_corr += -0.114332 * sin(2*Fr)
    l_corr += 0.058793 * sin(2*Dr - 2*Mpr)
    l_corr += 0.057066 * E * sin(2*Dr - Mr - Mpr)
    l_corr += 0.053322 * sin(2*Dr + Mpr)
    l_corr += 0.045758 * E * sin(2*Dr - Mr)
    l_corr += -0.040923 * E * sin(Mr - Mpr)
    l_corr += -0.034720 * sin(Dr)
    l_corr += -0.030383 * E * sin(Mr + Mpr)
    l_corr += 0.015327 * sin(2*Dr - 2*Fr)
    l_corr += -0.012528 * sin(Mpr + 2*Fr)
    l_corr += 0.010980 * sin(Mpr - 2*Fr)
    l_corr += 0.010675 * sin(4*Dr - Mpr)
    l_corr += 0.010034 * sin(3*Mpr)
    l_corr += 0.008548 * sin(4*Dr - 2*Mpr)
    l_corr += -0.007888 * E * sin(2*Dr + Mr - Mpr)
    l_corr += -0.006766 * E * sin(2*Dr + Mr)
    l_corr += -0.005163 * sin(Dr - Mpr)
    l_corr += 0.004987 * E * sin(Dr + Mr)
    l_corr += 0.004036 * E * sin(2*Dr - Mr + Mpr)
    l_corr += 0.003994 * E * sin(2*Dr + 2*Mr - Mpr)
    l_corr += 0.003861 * sin(4*Dr)
    l_corr += 0.003665 * sin(2*Dr - 3*Mpr)
    l_corr += -0.002689 * E * sin(Mr - 2*Mpr)
    l_corr += -0.002602 * sin(2*Dr - Mpr + 2*Fr)
    l_corr += 0.002390 * E * sin(2*Dr - Mr - 2*Mpr)
    l_corr += -0.002348 * E * sin(Dr + Mr - Mpr)
    l_corr += 0.002236 * E2 * sin(2*Dr - 2*Mr)
    l_corr += -0.002120 * E * sin(Mr + 2*Mpr)
    l_corr += -0.002069 * E2 * sin(2*Mr)
    l_corr += 0.002048 * E2 * sin(2*Dr - 2*Mr - Mpr)
    l_corr += -0.001773 * sin(2*Dr + Mpr - 2*Fr)
    l_corr += -0.001595 * sin(2*Dr + 2*Fr)

    Lp = moon_mean_longitude_deg(jde)
    lambda = norm360(Lp + l_corr)

    # Latitude (enhanced)
    beta = 0.0
    beta += 5.128122  * sin(Fr)
    beta += 0.280602  * sin(Mpr + Fr)
    beta += 0.277693  * sin(Mpr - Fr)
    beta += 0.173237  * sin(2*Dr - Fr)
    beta += 0.055413  * sin(2*Dr - Mpr + Fr)
    beta += 0.046271  * sin(2*Dr - Mpr - Fr)
    beta += 0.032573  * sin(2*Dr + Fr)
    beta += 0.017198  * sin(2*Mpr + Fr)
    beta += 0.009266  * sin(2*Dr + Mpr - Fr)
    beta += 0.008822  * sin(2*Mpr - Fr)
    beta += 0.008216 * E * sin(2*Dr - Mr - Fr)
    beta += 0.004324  * sin(2*Dr - 2*Mpr - Fr)
    beta += 0.004200  * sin(2*Dr + Mpr + Fr)
    beta += -0.003359 * E * sin(2*Dr + Mr - Fr)
    beta += 0.002463 * E * sin(2*Dr - Mr - Mpr + Fr)
    beta += 0.002211 * E * sin(2*Dr - Mr + Fr)
    beta += 0.002065 * E * sin(2*Dr - Mr - Mpr - Fr)
    beta += -0.001870 * E * sin(Mr - Mpr - Fr)
    beta += 0.001828  * sin(4*Dr - Mpr - Fr)
    beta += -0.001794 * E * sin(Mr + Fr)
    beta += -0.001749  * sin(3*Fr)
    beta += -0.001565 * E * sin(Mr - Mpr + Fr)
    beta += -0.001491  * sin(Dr + Fr)
    beta += -0.001475 * E * sin(Mr + Mpr + Fr)
    beta += -0.001410 * E * sin(Mr + Mpr - Fr)
    beta += -0.001344 * E * sin(Mr - Fr)
    beta += -0.001335  * sin(Dr - Fr)

    # Distance (enhanced)
    delta = 385000.56
    delta += - 20905.355 * cos(Mpr)
    delta += -  3699.111 * cos(2*Dr - Mpr)
    delta += -  2955.968 * cos(2*Dr)
    delta += -   569.925 * cos(2*Mpr)
    delta += +    48.888 * E * cos(Mr)
    delta += -     3.149 * cos(2*Fr)
    delta += +   246.158 * cos(2*Dr - 2*Mpr)
    delta += -   152.138 * E * cos(2*Dr - Mr - Mpr)
    delta += -   170.733 * cos(2*Dr + Mpr)
    delta += -   204.586 * E * cos(2*Dr - Mr)
    delta += -   129.620 * E * cos(Mr - Mpr)
    delta += +   108.743 * cos(Dr)
    delta += +   104.755 * E * cos(Mr + Mpr)
    delta += +    79.661 * cos(Mpr - 2*Fr)
    delta += +    48.888 * E * cos(Mr)
    delta += -    34.782 * cos(4*Dr - Mpr)
    delta += -    30.862 * cos(3*Mpr)
    delta += -    24.208 * cos(4*Dr - 2*Mpr)
    delta += +    22.439 * E * cos(2*Dr + Mr - Mpr)
    delta += +    19.004 * E * cos(2*Dr + Mr)

    return [lambda, beta, delta]

# -----------------------------
# Geometry and shadow sizes
# -----------------------------
func separation_axis_deg(lambda_m, beta_m, lambda_s)
    beta_r = deg2rad(beta_m)
    axis_lambda = norm360(lambda_s + 180.0)
    dlam = deg2rad(norm180(lambda_m - axis_lambda))
    cos_rho = cos(beta_r) * cos(dlam)
    cos_rho = clamp(cos_rho, -1.0, 1.0)
    rho = acos(cos_rho)
    return rad2deg(rho)

func shadow_radii_deg(sun_dist_AU, moon_dist_km)
    thetaE = rad2deg(asin(clamp(EARTH_EQUAT_RADIUS_KM / moon_dist_km, -1.0, 1.0)))
    thetaS = (959.63 / 3600.0) / sun_dist_AU
    thetaM = rad2deg(asin(clamp(MOON_RADIUS_KM / moon_dist_km, -1.0, 1.0)))
    Ru = thetaE - thetaS
    Rp = thetaE + thetaS
    return [Ru, Rp, thetaM, thetaS]  # [Umbra, Penumbra, LunarRadius, SunSD]

# -----------------------------
# Eclipse classification at a time
# -----------------------------
func classify_at_time(jde_tt)
	vals = sun_longitude_radius(jde_tt)
    lamS = vals[1]
	rAU = vals[2]
	sunSD = vals[3]
	vals = moon_llb_distance(jde_tt)
    lamM = vals[1]
	betaM = vals[2]
	distKM = vals[3]
    sep = separation_axis_deg(lamM, betaM, lamS)
	vals = shadow_radii_deg(rAU, distKM)
    Ru = vals[1]
	Rp = vals[2]
	Rm = vals[3]
	Rs = vals[4] 

    typ = ""
    if sep <= (Ru - Rm + ECLIPSE_EPSILON)
        typ = "Total"
    else
        if sep <= (Ru + Rm + ECLIPSE_EPSILON)
            typ = "Partial"
        else
            if sep <= (Rp + Rm + ECLIPSE_EPSILON)
                typ = "Penumbral"
            ok
        ok
    ok
    return [typ != "", sep, typ]

# -----------------------------
# Search around mean full moon for eclipse
# -----------------------------
func full_moon_jde_mean(kFull)
    T = kFull / 1236.85
    T2 = T*T ; T3 = T2*T ; T4 = T3*T
    jde = NEWMOON_JDE0 + SYNODIC_MONTH * kFull + 0.0001337 * T2 - 0.000000150 * T3 + 0.00000000073 * T4
    return jde

func find_eclipse_near(jde_full_mean)
    best_t = jde_full_mean
    best_sep = 1_000_000_000
    found_any = false

    # coarse scan
    for dt = -1.8 to 1.8 step 0.02
        t = jde_full_mean + dt
        vals = classify_at_time(t)
        found = vals[1]
        sep = vals[2]
        typ = vals[3]
        # even if not found, sep is valid
        if sep < best_sep
            best_sep = sep
            best_t = t
            found_any = true
        ok
    next

    if not found_any
        return [false, 0, 0, ""]
    ok

    # refinement
    ref_best_t = best_t
    ref_best_sep = best_sep
    for dt = -0.1 to 0.1 step 0.003
        t = best_t + dt
        vals = classify_at_time(t)
        found = vals[1]
        sep = vals[2]
        typ = vals[3]
        if sep < ref_best_sep
            ref_best_sep = sep
            ref_best_t = t
        ok
    next

    # final classification
    vals = classify_at_time(ref_best_t)
    found = vals[1]
    final_sep = vals[2]
    final_type = vals[3]
    if not found
        return [false, 0, 0, ""]
    ok

    return [true, ref_best_t, final_sep, final_type]

# -----------------------------
# Node separation (deg) using argument of latitude F
# -----------------------------
func node_separation_deg(jde_tt)
    args = fundamental_args_deg(jde_tt)
    D = args[1]
    M = args[2]
    Mp = args[3]
    F = args[4]
    f0 = abs(norm180(F))
    f1 = abs(norm180(F - 180.0))
    return iif(f0 < f1, f0, f1)

# -----------------------------
# Printing helpers
# -----------------------------
func repeatChar(ch, n)
    s = ""
    for i = 1 to n
        s += ch
    next
    return s

func zeroPad(n, width)
    s = string(abs(n))
    if len(s) < width
        s = repeatChar("0", width - len(s)) + s
    ok
    if n < 0 s = "-" + s ok
    return s

func toFixed(x, decimals)
    if decimals < 0 decimals = 0 ok
    if decimals = 0
        return string(round_int(x))
    ok
    scale = pow(10.0, decimals)
    i = round_int(x * scale)
    sign = ""
    if i < 0
        sign = "-"
        i = -i
    ok
    s = string(i)
    if len(s) <= decimals
        s = repeatChar("0", decimals - len(s) + 1) + s
    ok
    intpart = left(s, len(s) - decimals)
    fracpart = right(s, decimals)
    return sign + intpart + "." + fracpart

func padLeft(s, width)
    if len(s) < width
        return repeatChar(" ", width - len(s)) + s
    else
        return s
    ok

func padRight(s, width)
    if len(s) < width
        return s + repeatChar(" ", width - len(s))
    else
        return s
    ok

func fmtRNum(x, width, decimals)
    return padLeft(toFixed(x, decimals), width)

func fmtLStr(s, width)
    return padRight(s, width)

func print_rule(width)
    see repeatChar("-", width) + nl

func print_header(startYear, endYear)
    see "Lunar Eclipse Calendar Generator" + nl
    print_rule(136)
    see "Range: " + string(startYear) + " to " + string(endYear) + nl
    see "Classification uses dynamic shadow sizes and center-axis separation Rho (deg)." + nl
    print_rule(136)
    # Columns:
    # #, Date, Time, Type, Rho (deg), NodeSep_deg, Lat_deg, LunarRadius_deg, Umbra_deg, Penumbra_deg, Dist_km
    see fmtLStr("#",4) + "  " + fmtLStr("Date",10) + "  " + fmtLStr("Time",5) + "  " + 
        fmtLStr("Type",10) + "  " + padLeft("Rho (deg)",11) + "  " + padLeft("NodeSep_deg",11) + "  " + 
        padLeft("Lat_deg",8) + "  " + padLeft("LunarRadius_deg",15) + "  " + padLeft("Umbra_deg",10) + "  " + 
        padLeft("Penumbral_deg",12) + "  " + padLeft("Dist_km",10) + nl
    print_rule(136)

func print_event_row(idx, jd_ut, type, sepDeg, nodeSepDeg, latDeg, rmDeg, ruDeg, rpDeg, distKm)
    ymd = ymdhm_from_jd(jd_ut)
    y = ymd[1] ; m = ymd[2] ; d = ymd[3] ; hh = ymd[4] ; mm = ymd[5]

    sIdx = fmtLStr(string(idx),4)
    sDate = zeroPad(y,4) + "-" + zeroPad(m,2) + "-" + zeroPad(d,2)
    sTime = zeroPad(hh,2) + ":" + zeroPad(mm,2)
    sType = fmtLStr(type, 10)

    sSep = fmtRNum(sepDeg, 11, 3)
    sNode = fmtRNum(nodeSepDeg, 11, 3)
    sLat = fmtRNum(latDeg, 8, 3)
    sRm = fmtRNum(rmDeg, 15, 3)
    sRu = fmtRNum(ruDeg, 10, 3)
    sRp = fmtRNum(rpDeg, 12, 3)
    sDist = fmtRNum(distKm, 10, 0)

    see sIdx + "  " + sDate + "  " + sTime + "  " + sType + "  " + sSep + "  " + sNode + "  " + sLat + "  " + 
        sRm + "  " + sRu + "  " + sRp + "  " + sDist + nl

func print_footer(total, partial, penumbral, all)
    print_rule(136)
    see "Summary:  Total     : " + string(total)
    see "  Partial   : " + string(partial)
    see "  Penumbral : " + string(penumbral)
    see "  All       : " + string(all) + nl
    print_rule(136)
    see "Note: Times are near greatest eclipse by minimizing Moon-shadow-axis separation." + nl

# -----------------------------
# Driver
# -----------------------------
func generate_calendar(startYear, endYear)
    if endYear < startYear
        tmp = startYear
        startYear = endYear
        endYear = tmp
    ok

    jd_start = jd_from_ymd_utc(startYear, 1, 1, 0.0)
    jd_end   = jd_from_ymd_utc(endYear, 12, 31, 23.9999)

    print_header(startYear, endYear)

    k0 = floor((jd_start - NEWMOON_JDE0) / SYNODIC_MONTH) - 3.0

    countTotal = 0
    countPartial = 0
    countPenum = 0
    countAll = 0
    row = 0

    k = k0
    while true
        kFull = k + 0.5
        jde_full_mean = full_moon_jde_mean(kFull)

        if jde_full_mean > jd_end + 2.0 * SYNODIC_MONTH
            exit
        ok
        if jde_full_mean < jd_start - 2.0 * SYNODIC_MONTH
            k = k + 1.0
            loop
        ok

        vals = find_eclipse_near(jde_full_mean)
        found = vals[1]
        jde_tt = vals[2]
        sep_deg = vals[3]
        etype = vals[4] 
        if not found
            k = k + 1.0
            loop
        ok

        # Convert TT to UT using deltaT based on year at event time
        ymdtmp = ymdhm_from_jd(jde_tt)
        yTmp = ymdtmp[1]
        dTsec = deltaT_seconds(yTmp)
        jd_ut = jde_tt - dTsec / 86400.0

        if (jd_ut < jd_start) or (jd_ut > jd_end)
            k = k + 1.0
            loop
        ok

        # Compute fields at event TT instant
        vals = sun_longitude_radius(jde_tt)
        lamS = vals[1]
        rAU = vals[2]
        sunSD = vals[3]
        vals = moon_llb_distance(jde_tt)
        lamM = vals[1]
        betaM = vals[2]
        distKM = vals[3]
        nodeSep = node_separation_deg(jde_tt)
        vals = shadow_radii_deg(rAU, distKM)
        ru = vals[1]
        rp = vals[2]
        rm = vals[3]
        rs = vals[4]

        row = row + 1
        print_event_row(row, jd_ut, etype, sep_deg, nodeSep, betaM, rm, ru, rp, distKM)

        countAll = countAll + 1
        if etype = "Total"
            countTotal = countTotal + 1
        else
            if etype = "Partial"
                countPartial = countPartial + 1
            else
                if etype = "Penumbral"
                    countPenum = countPenum + 1
                ok
            ok
        ok

        k = k + 1.0
    end

    if countAll = 0
        see "(No eclipses found in this range by this model.)" + nl
    ok

    print_footer(countTotal, countPartial, countPenum, countAll)