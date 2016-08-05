#======================================================================
#                    P L O T _ W P R O F . P L 
#                    doc: Sun Jul 26 11:08:50 2015
#                    dlm: Thu May 26 11:29:32 2016
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 20 0 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Jul 26, 2015: - created from LWplot_prof_2beam
#	Jul 30, 2015: - moved main label outside plot area
#	Oct 12, 2015: - BUG: gaps were not plotted as such
#	Mar 16, 2016: - adapted to gmt5
#	Mar 17, 2016: - improved
#	May 18, 2016: - replaced rms tilt by mean tilt with traffic background
#				  - added plot_wprof_ymin tweakable
#	May 24, 2016: - BUG: ymin did not work for nsamp
#				  - fixed for partial-depth profiles
#				  - suppress plotting of nsamp == 0
#	May 26, 2016: - added instrument coord system to plot labels

# Tweakables:
#
# $plot_wprof_xmin = -0.27;
# $plot_wprof_ymin = 3600;
# $plot_wprof_ymax = 5000;
# $plot_wprof_xtics = "-0.25 -0.15 -0.05 0.05";

require "$ANTS/libGMT.pl";

sub setR1() { GMT_setR("-R$plot_wprof_xmin/0.35/$plot_wprof_ymin/$plot_wprof_ymax"); }
sub setR2() { GMT_setR("-R-450/350/$plot_wprof_ymin/$plot_wprof_ymax"); }

sub plotDC($$)
{
	my($f,$minsamp) = @_;
	for (my($bi)=0; $bi<=$#{$DNCAST{$f}}; $bi++) {
		if (numberp($DNCAST{$f}[$bi]) && $DNCAST{N_SAMP}[$bi]>=$minsamp) {
			printf(GMT "%g %g\n",$DNCAST{$f}[$bi],($bi+0.5)*$opt_o);
		} else {
			print(GMT "nan nan\n");
		}
	}
}

sub plotUC($$)
{
	my($f,$minsamp) = @_;
	for (my($bi)=0; $bi<=$#{$UPCAST{$f}}; $bi++) {
		if (numberp($UPCAST{$f}[$bi]) && $UPCAST{N_SAMP}[$bi]>=$minsamp) {
			printf(GMT "%g %g\n",$UPCAST{$f}[$bi],($bi+0.5)*$opt_o);
		} else {
			print(GMT "nan nan\n");
		}
	}
}

sub plotBT($$)
{
	my($f,$minsamp) = @_;
	for (my($bi)=0; $bi<=$#{$BT{$f}}; $bi++) {
		if (numberp($BT{$f}[$bi]) && $BT{N_SAMP}[$bi]>=$minsamp) {
			$have_BT = 1;
			printf(GMT "%g %g\n",$BT{$f}[$bi],($bi+0.5)*$opt_o);
		} else {
			print(GMT "nan nan\n");
		}
    }
}


sub plot_wprof($)
{
	my($pfn) = @_;

	$plot_wprof_xmin = -0.1
		unless defined($plot_wprof_xmin);		
	$plot_wprof_ymin = round(antsParam('min_depth')-25,50)
		unless defined($plot_wprof_ymin);		
	$plot_wprof_ymax = ($P{water_depth} > 0) ?
					   round($P{water_depth}+25,50) :
					   round($P{max_depth}+25,50)
		unless defined($plot_wprof_ymax);					  	
	$plot_wprof_xtics = "-0.05 0.05 0.15"
		unless defined($plot_wprof_xtics);

	GMT_begin($pfn,'-JX10/-10',"-R$plot_wprof_xmin/0.35/$plot_wprof_ymin/$plot_wprof_ymax",'-P');		# START PLOT

	GMT_psxy('-G200'); 																	# MAD background
		print(GMT "0.07 $plot_wprof_ymin\n 0.07 $plot_wprof_ymax\n0.18 $plot_wprof_ymax\n0.18 $plot_wprof_ymin\n");

	if ($P{water_depth} > 0) {															# SEABED
		GMT_psxy('-G204/153/102');
		print(GMT "$plot_wprof_xmin $plot_wprof_ymax\n0.35 $plot_wprof_ymax\n0.35 $P{water_depth}\n $plot_wprof_xmin $P{water_depth}\n");
	}

	setR1();																			# FRAME
	GMT_psxy('-W0.5');
		print(GMT "0 0\n 0 $plot_wprof_ymax\n");
	setR2();
	GMT_psxy('-W0.5');
		print(GMT ">\n50 0\n 50 $plot_wprof_ymax\n");
		print(GMT ">\n150 0\n 150 $plot_wprof_ymax\n");
		print(GMT ">\n250 0\n 250 $plot_wprof_ymax\n");

	setR1();																			# VERTICAL VELOCITIES
	GMT_psxy('-W1,coral,8_2:0');		plotDC('MEDIAN_W12',$opt_k);
	GMT_psxy('-W1,coral,1_1:0');		plotDC('MEDIAN_W34',$opt_k);
	GMT_psxy('-W1,SeaGreen,8_2:0'); 	plotUC('MEDIAN_W12',$opt_k);
	GMT_psxy('-W1,SeaGreen,1_1:0'); 	plotUC('MEDIAN_W34',$opt_k);
	GMT_psxy('-W1,black');				plotBT('MEDIAN_W',$opt_k);

	GMT_psxy('-Sc0.1c -Gcoral');		plotDC('MAD_W',0);								# MEAN ABSOLUTE DEVIATIONS
	GMT_psxy('-Sc0.1c -GSeaGreen');		plotUC('MAD_W',0);	
	GMT_psxy('-Sc0.1c -Gblack');		plotBT('MAD_W',0);	

	setR2();																			# SAMPLES
	GMT_psxy('-W0.7,coral');			plotDC('N_SAMP',1);
	GMT_psxy('-W0.7,SeaGreen');			plotUC('N_SAMP',1);	
	GMT_psxy('-W0.7,black');			plotBT('N_SAMP',1);	
	
	GMT_unitcoords();																	# LABELS
	GMT_pstext('-F+f14,Helvetica,blue+jTL -N');
		print(GMT "0.01 -0.06 $P{out_basename} [$P{run_label}]\n");
	GMT_pstext('-F+f12,Helvetica+jBR');
		print(GMT "0.6 0.98 m.a.d.\n");
	GMT_pstext('-F -N');
		print(GMT "0.32 1.12 Vertical Velocity [m/s]\n");
	GMT_pstext('-F+f9,Helvetica,orange+jTR -N -Gwhite');
		print(GMT "0.99 0.01 V$VERSION\n");

	GMT_pstext('-F+f12,Helvetica,coral+jTL -Gwhite');
		print(GMT "0.02 0.01 dc\n");
	GMT_pstext('-F+f12,Helvetica,SeaGreen+jTL -Gwhite');
		print(GMT "0.02 0.06 uc\n");
	if ($have_BT) {
		GMT_pstext('-F+f12,Helvetica,black+jTL -Gwhite');
			print(GMT "0.02 0.10 BT\n");
	}

	GMT_pstext('-F+f9,Helvetica,CornFlowerBlue+jTL -N');
		printf(GMT "0.64 1.020 $LADCP{BEAM_FREQUENCY}kHz $LADCP{INSTRUMENT_TYPE} $P{ADCP_orientation}\n");
#		printf(GMT "0.64 1.055 %s\n		0.77 1.055 : %.1fm/%1.fm/%1.fm\n",
		printf(GMT "0.64 1.055 %s [%.1fm/%1.fm/%1.fm]\n",
			$LADCP{BEAM_COORDINATES} ? 'beam vels' : 'Earth vels',
			$LADCP{BLANKING_DISTANCE},$LADCP{TRANSMITTED_PULSE_LENGTH},$LADCP{BIN_LENGTH});
		print(GMT "0.64 1.090 mean tilt\n 		0.77 1.096 :\n");
		print(GMT "0.64 1.130 rms a\@-pkg\@-\n	0.77 1.1315 :\n");

	if ($P{dc_mean_tilt} < 4) {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -N');
	} elsif ($P{dc_mean_tilt} < 8) {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -Gyellow -N');
	} else {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -Gred -N');
	}
			printf(GMT "0.808 1.090 %.1f\\260\n",$P{dc_mean_tilt});
	if ($P{uc_mean_tilt} < 4) {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -N');
	} elsif ($P{uc_mean_tilt} < 8) {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -Gyellow -N');
	} else {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -Gred -N');
	}
			printf(GMT "0.91 1.090 %.1f\\260\n",$P{uc_mean_tilt});

	if ($P{dc_rms_accel_pkg} < 0.7) {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -N');
	} else {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -Gyellow -N');
	}
		printf(GMT "0.78 1.125 %.1fm\@+2\@+/s\n",$P{dc_rms_accel_pkg});
		
	if ($P{uc_rms_accel_pkg} < 0.7) {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -N');
	} else {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -Gyellow -N');
	}
		printf(GMT "0.89 1.125 %.1fm\@+2\@+/s\n",$P{uc_rms_accel_pkg});
		
	my($depth_tics) = ($plot_wprof_ymax-$plot_prof_ymin < 1000 ) ? 'f10a100' : 'f100a500';				# AXES
	setR1();
	GMT_psbasemap("-Bf0.01:'':/$depth_tics:'Depth [m]':WeS");
	foreach my $t (split('\s+',$plot_wprof_xtics)) {
		GMT_psbasemap(sprintf('-Ba10-%fS',10-$t));
	}
	setR2();
	GMT_psbasemap('-Bf10a1000-950:"                                     # of Samples":N');
	GMT_psbasemap('-Ba1000-850N');
	GMT_psbasemap('-Ba1000-750N');
		 
	GMT_end();																			# FINISH PLOT
}

1; # return true on require
