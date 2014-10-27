#======================================================================
#                    D E F A U L T S . P L 
#                    doc: Tue Oct 11 17:11:21 2011
#                    dlm: Wed Oct 15 23:21:48 2014
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 39 68 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Oct 11, 2011: - created
#	Oct 12, 2011: - added $processing_param_file
#	Oct 13, 2011: - added $out_basename, $TL_out, $TL_hist_out
#	Oct 14, 2011: - added $w_out, $profile_out
#				  - renamed _out to out_; out_basename to out_basename
#	Oct 17, 2011: - added {data,plot,log}_subdir
#				  - added $out_BR
#				  - adapted to new filter-plot scripts
#				  - changed -v default to 2
#	Oct 19, 2011: - added SS_max_allowed_range & renamed _min_
#	Oct 20, 2011: - added $out_timeseries default
#				  - added $per_bin_valid_frac_lim
#	Oct 26, 2011: - added $first_guess_timelag
#	Oct 27, 2011: - modified ProcessingParam file loading
#				  - added ${pitch,roll,heading}_bias
#	Oct 11, 2012: - added .TL output to defaults
#	Oct 15, 2012: - removed support for TLhist
#	Apr 22, 2013: - removed option variable aliases
#	May 14, 2013: - opt_m => w_max_lim
#				  - BUG: default processing params file was still .default
#	May 15, 2013: - changed default profile plot to show 2-beam solutions
#				  - BUG: out_TLhist entry was still there
#	May 16, 2013: - -a => -d
#	Jun  5, 2013: - renamed $discard_data_from_beam to $bad_beam
#	Jun  5, 2013: - made ProcessingParams (without .profiles) default file
#	Sep  5, 2013: - also allow ProcessingParams.default
#				  - added LWplot_spec to default output
#	May 20, 2014: - added support for $PPI_editing
#	May 21, 2014: - added $PPI_extend_upper_limit
#	Oct 15, 2014: - investigated, modified and documented -t default

# Variable Names:
#	- variables that are only used in a particular library are
#	  prefixed with a 2-caps code

#======================================================================
# Data Input 
#======================================================================

# File to load cruise/cast-specific processing parameters from

if (-r "ProcessingParams.$RUN") {
	$processing_param_file = "ProcessingParams.$RUN";
} elsif (-r "ProcessingParams.default") {
	$processing_param_file = "ProcessingParams.default";
} elsif (-r "ProcessingParams") {
	$processing_param_file = "ProcessingParams";
} else {
	croak("$0: cannot find either <ProcessingParams.$RUN> or <ProcessingParams[.default]>\n");
}

# CTD depth adjustment
#	- set with -d (-a up to 2013/05/16)
#	- value is added to CTD pressure
#	- use when CTD has -ve pressures

&antsFloatOpt(\$opt_d,0);

# suppress 3-beam LADCP solutions

#$opt_4 = 1;


# correct attiude sensors

$pitch_bias = $roll_bias = $heading_bias = 0;


# bins to use in w calculations
#	- set with -b
#	- defaults to 2-last

$opt_b = '2,*' unless defined($opt_b);

#======================================================================
# Logging and Output
#======================================================================

#	- there are 4 verbosity levels, selected by -v
#		0:	only print errors
#		1:	UNIX-like (warnings and info messages that are not produced for every cast)
#		2:	(default) progress messages and useful information
#		>2:	debug messges
#	- the most useful ones of these are 1 & 2

&antsCardOpt(\$opt_v,2);


# output bin size in meters

&antsFloatOpt(\$opt_o,10);


# min w samples required for each vertical-velocity bin

&antsCardOpt(\$opt_k,20);


# output base name

$out_basename = sprintf('%03d',$STN);


# output subdirectories

croak("$RUN: no such directory\n") unless (-d $RUN);
$data_subdir = $plot_subdir = $log_subdir = $RUN;


# main w output and all its plots:
#	_w.eps			vertical velocities
#	_residuals.eps	residual vertical velocities
#	_Sv.eps			volume scattering coefficient after Deimes (1999)
#	_corr.eps		correlation [DISABLED 2013/05/16]

$out_w = "| LWplot_residuals $plot_subdir/${out_basename}_residuals.eps" .
		 "| LWplot_Sv $plot_subdir/${out_basename}_Sv.eps" .
#		 "| LWplot_corr $plot_subdir/${out_basename}_corr.eps" .
		 "| LWplot_w $plot_subdir/${out_basename}_w.eps" .
		 "> $data_subdir/$out_basename.w";


# w profile output

$out_profile = "| LWplot_prof_2beam $plot_subdir/${out_basename}_prof.eps" .
			   "| LWplot_spec $plot_subdir/${out_basename}_spec.eps" .
			   "> $data_subdir/$out_basename.prof";

# log output

$out_log = "$log_subdir/$out_basename.log";


# time-series output (CTD acceleration effect)

$out_timeseries = "| LWplot_CAE $plot_subdir/${out_basename}_CAE.eps" .
				  "> $data_subdir/$out_basename.tis";


# per-bin residual output (plot only)

$out_BR		= "| LWplot_BR $plot_subdir/${out_basename}_BR.eps";


# time-lagging output

$out_TL 	= "| LWplot_TL $plot_subdir/${out_basename}_TL.eps" .
			  "> $data_subdir/$out_basename.TL";

#======================================================================
# Data Editing
#======================================================================

# min correlation

&antsFloatOpt(\$opt_c,70);


# max tilt (pitch/roll) 
# 
# The default value was established with IWISE profiles 004, 005, 045
# and 049, which all show considerabe tilt-related discrepancies between
# the corresponding 2-beam solutions. The first and second pair of
# profiles were collected with 8 and 6m bins, respectively, without
# bin re-mapping. The original default of 15 degrees led to large
# beam-pair differences. Based on diagnostic plots it appears that
# only tilt angles smaller than 9 degrees or so are satisfactory. 
# In case of the IWISE data set, such a tight constraint causes
# too many data gaps. The compromise of 12 degrees seems to work
# quite well, based on the p0 vs epsilon correlation across 5
# data sets.
#
# NB: if this default is changed, the usage message in [LADCP_w]
#	  needs to be updated as well.

&antsFloatOpt(\$opt_t,12);


# max err vel

&antsFloatOpt(\$opt_e,0.1);


# truncate farthest valid velocities

$truncate_farthest_valid_bins = 0;


# discard velocities from chosen beam (1-4)

$bad_beam = 0;


# max LADCP gap length in seconds

&antsFloatOpt(\$opt_g,60);


# max allowed vertical velocity in m/s

$w_max_lim = 1;


# in each ensemble, vertical velocities differing more than this
# parameter times mean absolute deviation from median, are considered 
# outliers and removed

$per_ens_outliers_mad_limit = 2;


# data from bins with less valid velocities than the following parameter
# are considered bad and removed

$per_bin_valid_frac_lim = 0.15;


# ensembles when instrument is shallower than 
# $surface_layer_depth in meters are removed.
# possible contamination: ship's hull, thrusters, bubble clouds
# Inspired by 2011_IWISE station 8

$surface_layer_depth = 25;


# PPI editing as described in [edit_data.pl]
#	- enabled by default for WH150 data
#	- 2014 CLIVAR P16 #47 has a slight discontinuity at 4000m; this
#	  discontinuity is there without PPI filtering but gets slightly
#	  worse with PPI filtering. Setting $PPI_extend_upper_limit to 
#	  1.03-1.05 partially removes the discontinuity but the profile
#	  never gets better than the profile wihtout PPI editing. Note
#	  the only reason why the upper PPI should be extended is if the
#	  recorded ping intervals are inaccurate as the upper limit is
#	  set by the shortest acoustic path between the ADCP and the 
#	  seabed.

$PPI_editing = ($LADCP{BEAM_FREQUENCY} < 300);

#$PPI_extend_upper_limit = 1.03;		# arbitrarily increase calculated max dist from seabed by 3%

#======================================================================
# Time Lagging
#======================================================================

# externally supplied lag

# $opt_i = 567;


# reference layer bins for w for time matching

($refLr_firstBin,$refLr_lastBin) = (2,6);


# number of time lags during each of 2 lagging steps

$opt_n = '10,100' unless defined($opt_n);


# time lag search window widths for each of 2 lagging steps
#	- full width in seconds

$opt_w = '240,20' unless defined($opt_w);


# if top 3 lags have spread greater than $TL_max_allowed_three_lag_spread
# (in CTD scans) they must account for at least $TL_required_timelag_top_three_fraction
# or there is an error
#	- $TL_max_allowed_three_lag_spread default was initially set to 2 but found to be 
#	  violated quite often during 2011_IWISE
# 	- large spread may indicate dropped CTD scans
# 	- the optimum value of $TL_max_allowed_three_lag_spread may be cast-duration dependent

$TL_max_allowed_three_lag_spread = 3;
&antsFloatOpt(\$opt_3,0.6);


#======================================================================
# Seabed Search
#======================================================================

# # of ensembles around bottom to search

$SS_search_window_halfwidth = 200;	 


# max allowed distance of seabed from mode of distribution

$SS_max_allowed_depth_range = 10;


# The following numbers define the valid range of height-above bottom
# for seabed detection. If the the mean BT_RANGE of a given ens
# falls outside this range, the ensemble is ignored during seabed detection.
# Also, bins falling outside this range are not considered during 
# construction of accoustic backscatter profiles.

$SS_min_allowed_range = 20;
$SS_max_allowed_range = 150;


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
