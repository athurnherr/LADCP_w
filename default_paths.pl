#======================================================================
#                    D E F A U L T _ P A T H S . P L 
#                    doc: Tue Mar 29 07:09:52 2016
#                    dlm: Wed May 18 20:23:32 2016
#                    (c) 2016 A.M. Thurnherr
#                    uE-Info: 13 44 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Mar 29, 2016: - split from [defaults.pl]
#	May 18, 2016: - added new attitude and acceleration residuals plots
#				  - renamed mean_residual to bin_residuals plots
#				  - added new residual_profs plot

#======================================================================
# ProcessingParams file selection
#======================================================================

if (-r "ProcessingParams.$RUN") {
	$processing_param_file = "ProcessingParams.$RUN";
} elsif (-r "ProcessingParams.default") {
	$processing_param_file = "ProcessingParams.default";
} elsif (-r "ProcessingParams") {
	$processing_param_file = "ProcessingParams";
} else {
	error("$0: cannot find either <ProcessingParams.$RUN> or <ProcessingParams[.default]>\n");
}

#======================================================================
# Output
#======================================================================

# The "base name" of all output files (usually 0-padded 3-digits)

$out_basename = sprintf('%03d',$PROF);


# Output subdirectories
#	these are automatically created as long as they don't contain a "/"

$data_dir = $plot_dir = $log_dir = $RUN;
unless (-d $data_dir) {
	unless ($data_dir =~ m{/}) {
		warning(0,"Creating data sub-directory ./$data_dir\n");
		mkdir($data_dir);
	}
	error("$data_dir: no such directory\n") unless (-d $data_dir);
}
unless (-d $plot_dir) { 										    
	unless ($plot_dir =~ m{/}) {
		warning(0,"Creating plot sub-directory ./$plot_dir\n");
		mkdir($plot_dir);
	}
	error("$plot_dir: no such directory\n") unless (-d $plot_dir);
}
unless (-d $log_dir) {
	unless ($log_dir =~ m{/}) {
		warning(0,"Creating log-file sub-directory ./$log_dir\n");
		mkdir($log_dir);
	}
	error("$log_dir: no such directory\n") unless (-d $log_dir);
}
           

#----------------------------------------------------------------------
# Processing log (diagnostic messages) output
#----------------------------------------------------------------------

$out_log = "$log_dir/$out_basename.log";


#----------------------------------------------------------------------
# Vertical-velocity profile output and plots:
#
# Data:
#	*.wprof				vertical velocity profiles
#
# Plots:
# 	*_wprof.ps			vertical velocity profiles (main output plot)
#----------------------------------------------------------------------

@out_profile = ("plot_wprof($plot_dir/${out_basename}_wprof.ps)",
			    "$data_dir/$out_basename.wprof");


#--------------------------------------------------------------------------------------------------
# Vertical-velocity sample data output and plots:
#
# Data (in $data_dir):
#	*.wsamp							w sample data
#	residuals/<prof>/<ens>.rprof	OPTIONAL: per-ensemble residuals
#						
# Plots (in $plot_dir):
#	*_wsamp.ps						vertical velocity time-depth plot
#	*_residuals.ps					residual vertical velocity time-depth plot
#	*_backscatter.ps				volume scattering coefficient time-depth plot
#	*_attitude_res.ps				residuals binned wrt. pitch/roll
#	*_res_profs.ps					residuals binned in depth
#	*_acceleration_res.ps			OPTIONAL: residuals binned wrt. package acceleration derivative
#	*_correlation.ps				OPTIONAL: correlation time-depth plot
#--------------------------------------------------------------------------------------------------

push(@out_wsamp,"$data_dir/$out_basename.wsamp");
#push(@out_wsamp,sprintf('dump_residual_profiles(%s/residuals/%03d)',$data_dir,$PROF));

push(@out_wsamp,"plot_residuals($plot_dir/${out_basename}_residuals.ps)");
push(@out_wsamp,"plot_backscatter($plot_dir/${out_basename}_backscatter.ps)");
push(@out_wsamp,"plot_wsamp($plot_dir/${out_basename}_wsamp.ps)");
push(@out_wsamp,"plot_attitude_residuals($plot_dir/${out_basename}_attitude_res.ps)");
push(@out_wsamp,"plot_residual_profs($plot_dir/${out_basename}_residual_profs.ps)");
#push(@out_wsamp,"plot_acceleration_residuals($plot_dir/${out_basename}_acceleration_res.ps)");
#push(@out_wsamp,"plot_correlation($plot_dir/${out_basename}_correlation.ps)");

#----------------------------------------------------------------------
# Time-series output
#
#	*.tis			combined CTD/LADCP time-series data, including 
#					package- and LADCP reference layer w
#----------------------------------------------------------------------

@out_timeseries = ("$data_dir/$out_basename.tis");

#----------------------------------------------------------------------
# Per-bin vertical-velocity residuals (plot only)
#----------------------------------------------------------------------

@out_BR	= ("plot_mean_residuals($plot_dir/${out_basename}_bin_residuals.ps)");


#----------------------------------------------------------------------
# Time-lagging correlation statistics (plot only)
#----------------------------------------------------------------------

@out_TL = ("plot_time_lags($plot_dir/${out_basename}_time_lags.ps)");

1;	# return true

