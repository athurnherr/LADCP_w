#======================================================================
#                    D E F A U L T _ O U T P U T . P L 
#                    doc: Wed Jun  1 19:21:19 2016
#                    dlm: Sat May 16 12:19:26 2020
#                    (c) 2016 A.M. Thurnherr
#                    uE-Info: 71 0 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# NOTES:
#  - as this file is executed after ProcessingParams, only undefined
#	 variables are set

# HISTORY:
#	Jun  1, 2016: - created from [default_paths.pl]
#	May 15, 2020: - removed a couple of time-depth plots from level 1
#				  - changed semmantics so that pushing to plot adds,
#				    instead of overwwriting
#				  - BUG: one of the plots did not repect plotting level

#----------------------------------------------------------------------
# Processing log (diagnostic messages) output
#----------------------------------------------------------------------

$out_log = "$log_dir/$out_basename.log"
	unless defined($out_log);

#----------------------------------------------------------------------
# Vertical-velocity profile output and plots:
#
# Data:
#	*.wprof				vertical velocity profiles
#
# Plots:
# 	*_wprof.ps			vertical velocity profiles (main output plot)
#----------------------------------------------------------------------

push(@out_profile,"$data_dir/$out_basename.wprof");
push(@out_profile,"plot_wprof($plot_dir/${out_basename}_wprof.ps)")
	if ($plotting_level > 0);

#--------------------------------------------------------------------------------------------------
# Vertical-velocity sample data output and plots:
#
# Data (in $data_dir):
#	*.wsamp							w sample data
#	residuals/<prof>/<ens>.rprof	OPTIONAL: per-ensemble residuals
#						
# Plots (in $plot_dir):				plotting level: contents
#	*_wprof.ps						1: summary plot
#	*_bin_residuals.ps				1: residuals binned wrt bin number
#	*_residual_profs.ps				1: residuals binned in depth
#	*_wsamp.ps						2: vertical velocity time-depth plot
#	*_residuals.ps					2: residual vertical velocity time-depth plot
#	*_backscatter.ps				2: volume scattering coefficient time-depth plot
#	*_attitude_res.ps				3: residuals binned wrt. pitch/roll
#	*_residuals12.ps				3: beampair <1,2> residual vertical velocity time-depth plot
#	*_residuals34.ps				3: beampair <3,4> residual vertical velocity time-depth plot
#	*_attitude_res.ps				3: residuals binned wrt. package attitude
#	*_acceleration_res.ps			3: residuals binned wrt. package acceleration derivative
#	*_correlation.ps				4: correlation time-depth plot
#--------------------------------------------------------------------------------------------------

push(@out_wsamp,"$data_dir/$out_basename.wsamp");

#push(@out_wsamp,sprintf('dump_residual_profiles(%s/residuals/%03d)',$data_dir,$PROF));
#push(@out_wsamp,"write_residual_profs('$data_dir/$out_basename.resprof')");

if ($plotting_level > 0) {
	push(@out_wsamp,"plot_residual_profs($plot_dir/${out_basename}_residual_profs.ps)");
	if ($plotting_level > 1) {
		push(@out_wsamp,"plot_wsamp($plot_dir/${out_basename}_wsamp.ps)");
		push(@out_wsamp,"plot_residuals($plot_dir/${out_basename}_residuals.ps)");
		push(@out_wsamp,"plot_backscatter($plot_dir/${out_basename}_backscatter.ps)");
		if ($plotting_level > 2) {
			push(@out_wsamp,"plot_residuals12($plot_dir/${out_basename}_residuals12.ps)");
			push(@out_wsamp,"plot_residuals34($plot_dir/${out_basename}_residuals34.ps)");
			push(@out_wsamp,"plot_attitude_residuals($plot_dir/${out_basename}_attitude_res.ps)");
			push(@out_wsamp,"plot_acceleration_residuals($plot_dir/${out_basename}_acceleration_res.ps)");
			if ($plotting_level > 3) {
				push(@out_wsamp,"plot_correlation($plot_dir/${out_basename}_correlation.ps)");
			}
		}
	}
}

#----------------------------------------------------------------------
# Time-series output
#
#	*.tis			combined CTD/LADCP time-series data, including 
#					package- and LADCP reference layer w
#----------------------------------------------------------------------

push(@out_timeseries,"$data_dir/$out_basename.tis");

#----------------------------------------------------------------------
# Per-bin vertical-velocity residuals (plot only)
#----------------------------------------------------------------------

push(@out_BR,"plot_mean_residuals($plot_dir/${out_basename}_bin_residuals.ps)")
	if ($plotting_level > 0);

#----------------------------------------------------------------------
# Time-lagging correlation statistics (plot only)
#----------------------------------------------------------------------

unless (@out_TL) {
	push(@out_TL,"plot_time_lags($plot_dir/${out_basename}_time_lags.ps)")
		if ($plotting_level > 0);
}

#----------------------------------------------------------------------

1;	# return true

