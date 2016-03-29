#======================================================================
#                    D E F A U L T S . P L 
#                    doc: Tue Oct 11 17:11:21 2011
#                    dlm: Tue Mar 29 07:23:24 2016
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 74 39 NIL 0 0 72 0 2 4 NIL ofnI
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
#	Oct 27, 2014: - removed CTD-acceleration-effects and w spectral plots
#				  - removed time-lagging stats output file by default
#	Oct 31, 2014: - re-arranged order of things
#				  - .w => .samp output
#	Nov  4, 2014: - BUG: PPI_editing did not work as advertised
#   Apr 16, 2015: - turned output specifies into lists (re-design of
#                   plotting sub-system)
#				  - croak -> error
#				  - added $SS_use_BT, $SS_min_signal, $SS_min_samp
#	Apr 20, 2015: - reduced value of $SS_min_allowed_range
#				  - added $Sv_ref_bin
#	Apr 21: 2015: - BUG: typo in $Sv_ref_bin
#				  - decreased default verbosity
#   May 15, 2015: - added $min_valid_vels
#	May 20, 2015: - STN -> PROF
#	Jul 26, 2015: - began adaptation to libGMT.pl
#				  - changed .prof output .wprof
#				  - -v docu was wrong
#				  - added $outGrid_firstBin, $outGrid_lastBin
#	Jul 28, 2015: - implemented new plotting system
#	Jul 29, 2015: - implemented new plotting system
#	Sep  3, 2015: - renamed wsamp output and plot
#   			  - changed out_w to out_wsamp
#	Sep 26, 2015: - added sidelobe editing params
#	Oct 13, 2015: - addded support for $ENV{VERB}
#	Jan  4, 2016: - decreased default vertical resolution to 20m
#	Jan 22, 2016: - changed outGrid_firstBin default to 1
#	Jan 26, 2016: - removed -d
#				  - changed outGrid_firstBin default to '*', also lastBin
#	Jan 27, 2016: - added documentation
#	Mar 16, 2016: - added auto creation of output directory
#	Mar 18, 2016: - added comments about -l
#	Mar 19, 2016: - improved docu
#	Mar 29, 2016: - moved out dir creation to [LADCP_w_ocean]
#				  - added opt_r support

#======================================================================
# Output Log Files
#	- there are 4 verbosity levels, selected by -v
#		0 :	errors
#		1*:	UNIX-like (warnings and info messages that are not produced for every cast; *DEFAULT)
#		2 :	progress messages and useful information
#		>2:	debug messges
#	- the most useful ones of these are 1 & 2
#	- verbosity level can be set with the VERB shell variable
#======================================================================

&antsCardOpt(\$opt_v,$ENV{VERB});
$opt_v = 1 unless numberp($opt_v);


#======================================================================
# Data Input 
#======================================================================

# Set $opt_4 to 1 (or use the -4 option) to suppress 3-beam LADCP 
# solutions

#$opt_4 = 1;


# The following variables allow bias-correcting the attiude 
# sensors.
# NB: heading is not used for vertical-velocity processing!

$pitch_bias 	= 0;
$roll_bias 		= 0;
$heading_bias 	= 0;


# The following variable defines the minimum valid velocities 
# required in a LADCP file. If there are fewer data, an
# error is produced

$min_valid_vels = 50;


# The -b option defines the range of bins to use in w calculations.
# The '*' indicates the last bin in the ADCP file. For data
# collected with non-zero blanking distance, -b '1,*' should 
# likely be used.

$opt_b = '2,*' unless defined($opt_b);

#======================================================================
# Data Editing
#======================================================================

# The following sets the max allowable rms residual w per ensemble; 
# data from ensembles with larger rms residuals are discarded.

&antsFloatOpt(\$opt_r,0.04);


# By default, ensembles with uncertain time-lagging are discarded.
# This allows profiles with dropped CTD scans to be processed without
# manual intervention. For profiles collected in very calm conditions
# (e.g. near the ice off Antarctica) time lagging is highly uncertain
# most of the time --- setting $opt_l = 1 disables the lime-lagging
# filter for those cases.

# $opt_l = 1;


# The following sets the default correlation limit; measurements with
# correlations below this limit are discarded.

&antsFloatOpt(\$opt_c,70);


# The following sets the default limit for instrument attitude 
# (pitch/roll).
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


# The following sets the default error velocity limit; measurements 
# with error velocities below this limit are discarded.

&antsFloatOpt(\$opt_e,0.1);


# The following variable allows editing the velocities farthest
# from the transducer. It defines how many velocities are to be
# removed from each ensemble. 

$truncate_farthest_valid_bins = 0;


# The following variable allows editing all data from a given
# beam. Set to 1-4 to enable.

$bad_beam = 0;


# The following sets the maximum gap length in the w time series that
# is simply ignored.

&antsFloatOpt(\$opt_g,60);


# The following variable sets the max allowed vertical ocean velocity 
# in m/s. Measurements with |w| this limit are discarded.

$w_max_lim = 1;


# In each ensemble, vertical velocities differing more than this
# parameter times the mean absolute deviation from the median, are 
# considered outliers and removed.

$per_ens_outliers_mad_limit = 2;


# Data from bins with less valid velocities than the following parameter
# are considered bad and removed. It is not clear whether this really
# makes sense, but this editing is likely safe because it only affects
# ensebles with the largest ranges.

$per_bin_valid_frac_lim = 0.15;


# All ensembles recorded when the CTD is shallower than 
# the following parameter (depth in meters) are discarded.
# Possible contamination: ship's hull, thrusters, bubble clouds
# Inspired by 2011_IWISE station 8.

$surface_layer_depth = 25;


# Previous Ping Interference editing as described in [edit_data.pl]
#	- enabled by default for WH150 data
#	- the variable defines a string with a perl expression, which is
#	  evaluated once the data are loaded
#	- 2014 CLIVAR P16 #47 has a slight discontinuity at 4000m; this
#	  discontinuity is there without PPI filtering but gets slightly
#	  worse with PPI filtering. Setting $PPI_extend_upper_limit to 
#	  1.03-1.05 partially removes the discontinuity but the profile
#	  never gets better than the profile wihtout PPI editing. Note
#	  the only reason why the upper PPI should be extended is if the
#	  recorded ping intervals are inaccurate as the upper limit is
#	  set by the shortest acoustic path between the ADCP and the 
#	  seabed.

$PPI_editing_required = '($LADCP{BEAM_FREQUENCY} < 300)';

#$PPI_extend_upper_limit = 1.03;		# see comments above


# The following variables control the "non-obvious" sidelobe editing for
# contamination from the seabed for the UL and from the sea surface for the
# DL. Tests with DoMORE-2 data (WH150 DL, WH300 UL) strongly suggest that
# it is not necessary to edit DL data for surface contamination. However,
# at least for that instrument combination, UL (WH300) contamination from the
# seabed should clearly be removed.

$sidelobe_editing_DL_surface	= 0;
$sidelobe_editing_UL_seabed		= 1;

# The following variable sets the depth for sidelobe contamination
# from the surface. 

$vessel_draft					= 6;		# in meters


#======================================================================
# Time Lagging
#======================================================================

# The -i option allows defining an initial guess for the time lag between
# the LADCP and the CTD data.

# $opt_i = 567;


# The following variables define the bins used to calculate the reference-
# layer velocities used for time lagging.

($refLr_firstBin,$refLr_lastBin) = (2,6);


# The -n option defines the number of windows used to calculate
# the optimal time lag. There's one value for each time-lagging step.

$opt_n = '10,100' unless defined($opt_n);


# The -w option defines the width of the window (in seconds) used
# to calculate the optimal time lag. There's one value for each 
# time-lagging step.

$opt_w = '240,20' unless defined($opt_w);


# The following parameters control whether the top three time lags 
# are accepted or not.
# If the top 3 lags have spread greater than $TL_max_allowed_three_lag_spread
# (in CTD scans) they must account for at least $TL_required_timelag_top_three_fraction
# or an error is generated.
# Notes:
#	- $TL_max_allowed_three_lag_spread default was initially set to 2 but found to be 
#	  violated quite often during 2011_IWISE
# 	- large spread may indicate dropped CTD scans
# 	- the optimum value of $TL_max_allowed_three_lag_spread may be 
#	  cast-duration dependent

$TL_max_allowed_three_lag_spread = 3;
&antsFloatOpt(\$opt_3,0.6);


#======================================================================
# Acoustic Backscatter and Seabed Search
#======================================================================

# After applying the method of Deines (1999), an empirical correction
# for Sv is applied to the data. The following variable determines which
# bin is chosen to construct a reference profile for Sv. The bin number
# is automatically increased if the selected bin does not contain valid
# data, i.e. the default value of 1 ensures that the closest valid bin
# is used to construct the reference profile.

$Sv_ref_bin = 1; 


# Set to folloing variable to 1 to use ADCP BT data to detect seabed 
# instead of default code based on Sv (echo amplitude). I do not know
# which code is better.

$SS_use_BT = 0;


# The following variable defines the minimum Sv signal in a bin (max - min)
# required for reliable seabed detection FROM ECHO AMPLITUDES. A limit of 40dB is
# indicated based on GoM#13, where the seabed is only visible in the last 
# bin (#25). 30dB is chosen as the default to allow for variability. 
# This value may need to be changed for data not collected with WH300
# instruments with 8m bins, and perhaps also for different types of
# seafloor (soft sediments). To do this, set $SS_min_signal to a small value
# (e.g. 10) and inspect the \@SV_rng values reported in the log files.
# This parameter is only used when $SS_use_BT == 0.

$SS_min_signal = 30;


# Require at minimum nubmer of valid samples for seabed detection FROM ECHO
# AMPLITUDES. Each sample is a bin with a clear seabed maximum. With a proper 
# setting of $SS_min_signal, the algorithm is stable even with only a single
# sample (GoM#13). However, a default of 3 required samples is chosen
# to make seabed detection less sensitive to $SS_min_signal. 
# This parameter is only used when $SS_use_BT == 0.

$SS_min_samp = 3;


# The following numbers define the valid range of height-above bottom
# for seabed detection FROM ECHO AMPLITUDE. For data collected with WH300 
# instruments and 8m bins, the maximum range needs to be greater than 250m 
# (based on # GoM#13).

$SS_min_allowed_range = 0;
$SS_max_allowed_range = 350;


# Number of ensembles around bottom to search sabed IN BT DATA. 
# Only used with $SS_use_BT == 1.

$SS_search_window_halfwidth = 200;	 


# Maximum allowed distance of seabed from mode of distribution. 
# Only used with $SS_use_BT == 1.

$SS_max_allowed_depth_range = 10;


#======================================================================
# Bottom Tracking
#	- at present, the ADCP BT data are ignored, i.e. "post-processed"
#	  BT data are used.
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
# Gridded Velocity Profile Output
#======================================================================


# The -k option defines the minimum number of w samples required in each 
# vertical-velocity bin. The following sets the default value.

&antsCardOpt(\$opt_k,20);


# The -o option sets the output grid resolution in meters. The following
# sets the default value.

&antsFloatOpt(\$opt_o,20);


# The following variables limit the bins used to grid w_oean
#	- in contrast to -b, the other bins are still used e.g. for BT 
#	- values recorded in %outgrid_firstbin, %outgrid_lastbin
#	- values beyond range are:
#		- greyed out in *_mean_residuals.ps
#		- not used in *_w.ps, *_residuals.ps

$outGrid_firstBin = '*';			# use $LADCP_firstBin (-b)
$outGrid_lastBin  = '*';			# use $LADCP_lastBin (-b)




1;	# return true

