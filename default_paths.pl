#======================================================================
#                    D E F A U L T _ P A T H S . P L 
#                    doc: Tue Mar 29 07:09:52 2016
#                    dlm: Tue Jun 13 15:10:28 2023
#                    (c) 2016 A.M. Thurnherr
#                    uE-Info: 41 53 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Mar 29, 2016: - split from [defaults.pl]
#	May 18, 2016: - added new attitude and acceleration residuals plots
#				  - renamed mean_residual to bin_residuals plots
#				  - added new residual_profs plot
#	Jun  1, 2016: - added residuals12 plots
#				  - added support for $plotting_level
#				  - exported stuff to [default_output.pl]

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


# Output subdirectories for data, plots and log files
#	these are automatically created as long as they don't contain a "/"

$data_dir = $plot_dir = $log_dir = $RUN;
unless (-d $data_dir) {
	unless ($data_dir =~ m{/}) {
		warning(0,"Creating data sub-directory ./$data_dir\n");
		mkdir($data_dir);
	}
	error("$data_dir: no such directory\n") unless (-d $data_dir);
}
unless (-d $log_dir) {
	unless ($log_dir =~ m{/}) {
		warning(0,"Creating log-file sub-directory ./$log_dir\n");
		mkdir($log_dir);
	}
	error("$log_dir: no such directory\n") unless (-d $log_dir);
}
if ($plotting_level > 0) {
	unless (-d $plot_dir) { 										    
		unless ($plot_dir =~ m{/}) {
			warning(0,"Creating plot sub-directory ./$plot_dir\n");
			mkdir($plot_dir);
		}
		error("$plot_dir: no such directory\n") unless (-d $plot_dir);
	}
}

#----------------------------------------------------------------------

1;	# return true

