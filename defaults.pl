#======================================================================
#                    D E F A U L T S . P L 
#                    doc: Tue Oct 11 17:11:21 2011
#                    dlm: Sat Oct 15 21:01:56 2011
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 144 26 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Oct 11, 2011: - created
#	Oct 12, 2011: - added $processing_param_file
#	Oct 13, 2011: - added $out_basename, $TL_out, $TL_hist_out
#	Oct 14, 2011: - added $w_out, $profile_out
#				  - renamed _out to out_; out_basename to out_basename

# Variable Names:
#	- variables that are only used in a particular library are
#	  prefixed with a 2-caps code

#======================================================================
# Data Input 
#======================================================================

# File to load cruise/cast-specific processing parameters from

$processing_param_file = './ProcessingParams.pl';

# CTD depth adjustment
#	- set with -a
#	- value is added to CTD pressure
#	- use when CTD has -ve pressures

$CTD_neg_press_offset = &antsFloatOpt($opt_a,0);


# suppress 3-beam LADCP solutions

$RDI_Coords::minValidVels = 4 if ($opt_4);							


# bins to use in w calculations
#	- set with -b
#	- defaults to 2-last

$opt_b = '2,*' unless defined($opt_b);
($LADCP_firstBin,$LADCP_lastBin) = split(',',$opt_b);
croak("$0: cannot decode -b $opt_b\n")
    unless (numberp($LADCP_firstBin) &&
            ($LADCP_lastBin eq '*' || numberp($LADCP_lastBin)));

#======================================================================
# Logging and Output
#======================================================================

#	- there are 4 verbosity levels, selected by -v
#		0:	only print errors
#		1:	default, UNIX-like (warnings and info messages that are not produced for every cast)
#		2:	progress messages and useful information
#		>2:	debug messges
#	- the most useful ones of these are 1 & 2

$verbosity_level = &antsCardOpt($opt_v,1);

# output base name

$out_basename = sprintf('%03d%s',$STN,$RUN);


# main w output

$out_w = "| LWplot_w -s $out_basename.w > ${out_basename}_w.eps";


# w profile output

$out_profile = "| LWplot_prof -s $out_basename.prof > ${out_basename}_prof.eps";


# output bin size in meters

$output_bin_size = &antsFloatOpt($opt_o,10);


# min w samples required for each vertical-velocity bin

$min_w_nsamp = &antsCardOpt($opt_k,20);


# diagnostic plots

$out_TL 	= "| LWplot_TL     > ${out_basename}_TL.eps";
$out_TLhist = "| LWplot_TLhist > ${out_basename}_TLhist.eps";


#======================================================================
# Data Editing
#======================================================================

# min correlation

$min_correlation = &antsFloatOpt($opt_c,70);


# max tilt (pitch/roll)

$max_tilt = &antsFloatOpt($opt_t,15);


# max err vel

$max_allowed_errvel = &antsFloatOpt($opt_e,0.1);


# truncate farthest valid velocities

$truncate_farthest_valid_bins = 0;


# discard velocities from chosen beam (1-4)

$discard_velocities_from_beam = 0;


# max LADCP gap length in seconds

$max_LADCP_reflr_vel_gap = &antsFloatOpt($opt_g,60);


# max allowed vertical velocity in m/s

$max_allowed_w = &antsFloatOpt($opt_m,1);


# all apparently valid velocities after a gap of at least this length
# are deleted

$DE_falsepositives_max_gap = 3;


# in each ensemble, vertical velocities differing more than $DE_... times
# mean absolute deviation from median, are considered outliers and
# removed

$DE_outliers_mad_limit = 2;


# ensembles when instrument is shallower than 
# $surface_layer_depth in meters are removed.
# possible contamination: ship's hull, thrusters, bubble clouds
# Inspired by 2011_IWISE station 8

$surface_layer_depth = 25;

#======================================================================
# Time Lagging
#======================================================================

# reference layer bins for w for time matching

($refLr_firstBin,$refLr_lastBin) = (2,6);


# number of time lags during each of 2 lagging steps

$opt_n = '10,100' unless defined($opt_n);
@number_of_timelag_windows = split(',',$opt_n);
croak("$0: cannot decode -n $opt_n\n")
	unless numberp($number_of_timelag_windows[0]) && numberp($number_of_timelag_windows[1]);


# time lag search window widths for each of 2 lagging steps
#	- full width in seconds

$opt_w = '240,20' unless defined($opt_w);
@length_of_timelag_windows = split(',',$opt_w);
croak("$0: cannot decode -w $opt_w\n")
	unless numberp($length_of_timelag_windows[0]) && numberp($length_of_timelag_windows[1]);


# if top 3 lags have spread greater than $TL_max_allowed_three_lag_spread
# (in CTD scans) they must account for at least $TL_required_timelag_top_three_fraction
# or there is an error
#	- $TL_max_allowed_three_lag_spread default was initially set to 2 but found to be 
#	  violated quite often during 2011_IWISE
# 	- large spread may indicate dropped CTD scans
# 	- the optimum value of $TL_max_allowed_three_lag_spread may be cast-duration dependent

$TL_max_allowed_three_lag_spread = 3;
$TL_required_top_three_fraction = &antsFloatOpt($opt_3,0.6);


#======================================================================
# Seabed Search
#======================================================================

# # of ensembles around bottom to search

$SS_search_window_halfwidth = 200;	 


# max allowed distance of seabed from mode of distribution

$SS_max_allowed_depth_range = 10;


# min allowed LADCP distance from seabed for good data

$SS_min_allowed_hab = 20;


#======================================================================
# Bottom Tracking
#======================================================================

# Don't look for BT-referenced velocities if package is more than $BT_max_range
# above seabed. This parameter is frequency dependent and the current value is
# appropriate (if rather high) for 300kHz Workhorse intruments.

$BT_max_range = 300;


# The code only tries to bin BT-referenced velocities if a consistent bottom
# is available in all 4 beams. Ensembles where the range of bin numbers where
# the maximum echo is found is greater than $max_BIT_bin_range_diff are rejected.
# In addition to flukes this also rejects ensembles collected with large
# instrument tilts. The value of 3 is a first guess that has not been explored.

$BT_max_bin_range_diff = 3;


# If the difference between measured vertical velocity of the seabed (i.e.
# the package vertical velocity referenced by the seabed) and the vertical
# velocity of the CTD (from dp/dt) si greater than $BT_max_w_error the current
# ensemble is ignored and $nBTwFlag is increased. The value of
# 3cm/s is taken from listBT developed on A0304 cruise.

$BT_max_w_error = 0.03;

#======================================================================

1;	# return true
