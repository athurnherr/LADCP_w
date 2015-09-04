#======================================================================
#                    P L O T _ W P R O F . P L 
#                    doc: Sun Jul 26 11:08:50 2015
#                    dlm: Thu Jul 30 09:50:03 2015
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 11 54 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Jul 26, 2015: - created from LWplot_prof_2beam
#	Jul 30, 2015: - moved main label outside plot area

# Tweakables:
#
# $plot_wprof_xmin = -0.27;
# $plot_wprof_ymax = 5000;
# $plot_wprof_xtics = "-0.25 -0.15 -0.05 0.05";

require "$ANTS/libGMT.pl";

sub setR1() { GMT_setR("-R$plot_wprof_xmin/0.35/0/$plot_wprof_ymax"); }
sub setR2() { GMT_setR("-R-200/200/0/$plot_wprof_ymax"); }

sub plotDC($)
{
	my($f) = @_;
	for (my($bi)=0; $bi<=$#{$DNCAST{$f}}; $bi++) {
		printf(GMT (numberp($DNCAST{$f}[$bi]) ? "%g %g\n" : "nan nan\n"),
				    $DNCAST{$f}[$bi],($bi+0.5)*$opt_o)
			if ($DNCAST{N_SAMP}[$bi] >= $opt_k);
	}
}

sub plotUC($)
{
	my($f) = @_;
	for (my($bi)=0; $bi<=$#{$UPCAST{$f}}; $bi++) {
		printf(GMT (numberp($UPCAST{$f}[$bi]) ? "%g %g\n" : "nan nan\n"),
					$UPCAST{$f}[$bi],($bi+0.5)*$opt_o)
			if ($UPCAST{N_SAMP}[$bi] >= $opt_k);
	}
}

sub plotBT($)
{
	my($f) = @_;
	for (my($bi)=0; $bi<=$#{$BT{$f}}; $bi++) {
		printf(GMT (numberp($BT{$f}[$bi]) ? "%g %g\n" : "nan nan\n"),
					$BT{$f}[$bi],($bi+0.5)*$opt_o)
			if ($BT{N_SAMP}[$bi] >= $opt_k);
	}
}


sub plot_wprof($)
{
	my($pfn) = @_;

	$plot_wprof_xmin = -0.1
		unless defined($plot_wprof_xmin);		
	$plot_wprof_ymax = ($P{water_depth} > 0) ?
					   round($P{water_depth} + 25) :
					   round($P{max_depth} 	 + 25)
		unless defined($plot_wprof_ymax);					  	
	$plot_wprof_xtics = "-0.05 0.05 0.15"
		unless defined($plot_wprof_xtics);

	GMT_begin($pfn,'-JX10/-10',"-R$plot_wprof_xmin/0.35/0/$plot_wprof_ymax",'-P');		# START PLOT

	GMT_psxy('-G200'); 																	# MAD background
		print(GMT "0.07 0\n 0.07 $plot_wprof_ymax\n0.18 $plot_wprof_ymax\n0.18 0\n");

	if ($P{water_depth} > 0) {															# SEABED
		GMT_psxy('-G204/153/102');
		print(GMT "$plot_wprof_xmin $plot_wprof_ymax\n0.35 $plot_wprof_ymax\n0.35 $P{water_depth}\n $plot_wprof_xmin $P{water_depth}\n");
	}

	setR1();																			# FRAME
	GMT_psxy('-W1');
		print(GMT "0 0\n 0 $plot_wprof_ymax\n");
	setR2();
	GMT_psxy('-W1 -M');
		print(GMT ">\n50 0\n 50 $plot_wprof_ymax\n");
		print(GMT ">\n100 0\n 100 $plot_wprof_ymax\n");
		print(GMT ">\n150 0\n 150 $plot_wprof_ymax\n");

	setR1();																			# VERTICAL VELOCITIES
	GMT_psxy('-Mn -W4,coral,6_2:0'); 		plotDC('MEDIAN_W12');
	GMT_psxy('-Mn -W4,coral,4_6:0'); 		plotDC('MEDIAN_W34');
	GMT_psxy('-Mn -W4,SeaGreen,6_2:0'); 	plotUC('MEDIAN_W12');
	GMT_psxy('-Mn -W4,SeaGreen,4_6:0'); 	plotUC('MEDIAN_W34');
	GMT_psxy('-Mn -W4,black'); 				plotBT('MEDIAN_W');

	GMT_psxy('-Sc0.1c -Gcoral');			plotDC('MAD_W');							# MEAN ABSOLUTE DEVIATIONS
	GMT_psxy('-Sc0.1c -GSeaGreen');			plotUC('MAD_W');	
	GMT_psxy('-Sc0.1c -Gblack');			plotBT('MAD_W');	

	setR2();																			# SAMPLES
	GMT_psxy('-Mn -W1/coral');				plotDC('N_SAMP');
	GMT_psxy('-Mn -W1/SeaGreen');			plotUC('N_SAMP');	
	GMT_psxy('-Mn -W1/black');				plotBT('N_SAMP');	
	
	GMT_unitcoords();																	# LABELS
	GMT_pstext('-Gblue -N');
		print(GMT "0.01 -0.06 14 0 0 TL $P{out_basename} $P{run_label}\n");
	GMT_pstext();
		print(GMT "0.6 0.98 12 0 0 BR m.a.d.\n");

	my($depth_tics) = ($plot_wprof_ymax < 1000 ) ? 'f10a100' : 'f100a500';				# AXES
	setR1();
	GMT_psbasemap("-Bf0.01:'Vertical Velocity [m/s]                               ':/$depth_tics:'Depth [m]':WeS");
	foreach my $t (split('\s+',$plot_wprof_xtics)) {
		GMT_psbasemap(sprintf('-Ba10-%fS',10-$t));
	}
	setR2();
	GMT_psbasemap('-Bf10a1000-950:"                                     # of Samples":N');
	GMT_psbasemap('-Ba1000-900N');
	GMT_psbasemap('-Ba1000-850N');
		 
	GMT_end();																			# FINISH PLOT
}

1; # return true on require
