#======================================================================
#                    P L O T _ W P R O F . P L 
#                    doc: Sun Jul 26 11:08:50 2015
#                    dlm: Tue Jul 13 12:51:25 2021
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 126 0 NIL 0 0 72 0 2 4 NIL ofnI
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
#	Mar 20, 2018: - BUG: units of vertical package acceleration were wrong
#				  - added blue background for likely in-ice package accelerations
#	May 16, 2020: - added residual profile data to background
#	May 23, 2020: - BUG: windows without samples made program bomb
#	Mar 23, 2021: - BUG: instrument frequency was rounded to 100kHz
#	Jun 30, 2021: - improved quality semaphore
#	Jul  1, 2021: - replaced bin setup by <w> in legend
#	Jul  7, 2021: - added colored background to <w>
#	Jul  9, 2021: - adapted to new residual editing (calculation in LADCP_w_ocean)
# HISTORY END

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

sub plotRes_V1()
{
	my($last_depth,$dc_sumsq_res,$dc_n,$uc_sumsq_res,$uc_n);
	for (my($bi)=0; $bi<=$#{$DNCAST{MEDIAN_W}}; $bi++) {
		my($depth) = ($bi+0.5) * $opt_o;
		if ($depth > $last_depth+100 || $bi == $#{$DNCAST{MEDIAN_W}}) {
			if ($dc_n==0 || sqrt($dc_sumsq_res/$dc_n) > 0.002) {
				my($green) = $dc_n ? round(100*max(0.01-max(sqrt($dc_sumsq_res/$dc_n)-0.002,0),0) * 255) : 0;
				GMT_psxy("-Gp300/12:F255/$green/${green}B-");
				printf(GMT "%g %g\n%g %g\n%g %g\n%g %g\n",
								-0.1,$last_depth,0,$last_depth,
								0,$depth,-0.1,$depth);
			}
			if ($uc_n==0 || sqrt($uc_sumsq_res/$uc_n) > 0.002) {
				my($green) = $uc_n ? round(100*max(0.01-max(sqrt($uc_sumsq_res/$uc_n)-0.002,0),0) * 255) : 0;
				GMT_psxy("-Gp300/9:F255/$green/${green}B-");
				printf(GMT "%g %g\n%g %g\n%g %g\n%g %g\n",
								0,$last_depth,0.07,$last_depth,
								0.07,$depth,0,$depth);
			}
			$dc_sumsq_res = $dc_n = $uc_sumsq_res = $uc_n = 0;
			$last_depth = $depth;
		}
		if (numberp($DNCAST{MEAN_RESIDUAL12}[$bi])) {
			$dc_sumsq_res += $DNCAST{MEAN_RESIDUAL12}[$bi]**2;
			$dc_n++;
		}
		if (numberp($UPCAST{MEAN_RESIDUAL12}[$bi])) {
			$uc_sumsq_res += $UPCAST{MEAN_RESIDUAL12}[$bi]**2;
			$uc_n++;
		}
		if (numberp($DNCAST{MEAN_RESIDUAL34}[$bi])) {
			$dc_sumsq_res += $DNCAST{MEAN_RESIDUAL34}[$bi]**2;
			$dc_n++;
		}
		if (numberp($UPCAST{MEAN_RESIDUAL34}[$bi])) {
			$uc_sumsq_res += $UPCAST{MEAN_RESIDUAL34}[$bi]**2;
			$uc_n++;
		}
	}
}

sub plotRes()
{
	for (my($bi)=0; $bi<=$#{$DNCAST{MEDIAN_W}}; $bi++) {
		if ($DNCAST{LR_RMS_BP_RESIDUAL}[$bi] > 0.002) {
			my($sat) = round(100*max(0.01-max($DNCAST{LR_RMS_BP_RESIDUAL}[$bi]-0.002,0),0) * 255);
			GMT_psxy("-Gp300/12:F255/$sat/${sat}B-");
			printf(GMT "%g %g\n%g %g\n%g %g\n%g %g\n",
							-0.1,$bi*$opt_o,0,$bi*$opt_o,
							0,($bi+1)*$opt_o,-0.1,($bi+1)*$opt_o);
		}
		if ($UPCAST{LR_RMS_BP_RESIDUAL}[$bi] > 0.002) {
			my($sat) = round(100*max(0.01-max($UPCAST{LR_RMS_BP_RESIDUAL}[$bi]-0.002,0),0) * 255);
			GMT_psxy("-Gp300/9:F255/$sat/${sat}B-");
			printf(GMT "%g %g\n%g %g\n%g %g\n%g %g\n",
							0,$bi*$opt_o,0.07,$bi*$opt_o,
							0.07,($bi+1)*$opt_o,0,($bi+1)*$opt_o);
		}
	}
}

sub plot_wprof($)
{
	my($pfn) = @_;

	$plot_wprof_xmin = -0.1
		unless defined($plot_wprof_xmin);		
	$plot_wprof_ymin = round(antsParam('depth.min')-25,50)
		unless defined($plot_wprof_ymin);		
	$plot_wprof_ymax = ($P{water_depth} > 0) ?
					   round($P{water_depth}+25,50) :
					   round($P{'depth.max'}+25,50)
		unless defined($plot_wprof_ymax);					  	
	$plot_wprof_xtics = "-0.05 0.05 0.15"
		unless defined($plot_wprof_xtics);

	GMT_begin($pfn,'-JX10/-10',"-R$plot_wprof_xmin/0.35/$plot_wprof_ymin/$plot_wprof_ymax",'-P');		# START PLOT

	GMT_psxy('-G200'); 																	# MAD background
		print(GMT "0.07 $plot_wprof_ymin\n 0.07 $plot_wprof_ymax\n0.18 $plot_wprof_ymax\n0.18 $plot_wprof_ymin\n");

	if ($P{water_depth} > 0) {															# SEABED
		GMT_psxy('-G204/153/102');
		print(GMT "$plot_wprof_xmin $plot_wprof_ymax\n0.07 $plot_wprof_ymax\n0.07 $P{water_depth}\n $plot_wprof_xmin $P{water_depth}\n");
	}

	setR1();	
	plotRes();																			# RESIDUAL PROFILES
	GMT_psxy('-W0.5');																	# FRAME
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

	GMT_psxy('-Sc0.1c -Gcoral');		plotDC('MAD_W',1);								# MEAN ABSOLUTE DEVIATIONS
	GMT_psxy('-Sc0.1c -GSeaGreen');		plotUC('MAD_W',1);	
	GMT_psxy('-Sc0.1c -Gblack');		plotBT('MAD_W',1);	

	setR2();																			# SAMPLES
	GMT_psxy('-W0.7,coral');			plotDC('N_SAMP',1);
	GMT_psxy('-W0.7,SeaGreen');			plotUC('N_SAMP',1);	
	GMT_psxy('-W0.7,black');			plotBT('N_SAMP',1);

	GMT_unitcoords();																	# QUALITY SEMAPHORE
	GMT_psxy('-Ggray90');
	print(GMT "0.895 0.895\n0.985 0.895\n0.985 0.985\n0.895 0.985\n");
	if ($dc_bres12_rms >= 0.005) { 		GMT_psxy('-W1,coral,8_2:0 -Gred -N'); }
	elsif ($dc_bres12_rms >= 0.003) { 	GMT_psxy('-W1,coral,8_2:0 -Gorange -N'); }
	elsif ($dc_bres12_rms >= 0.0015) { 	GMT_psxy('-W1,coral,8_2:0 -Gyellow -N'); }
	else {								GMT_psxy('-W1,coral,8_2:0 -Ggreen -N'); }
#		print(GMT "0.90 0.90\n0.935 0.90\n0.935 0.935\n");							
		print(GMT "0.90 0.90\n0.935 0.90\n0.935 0.935\n0.90 0.935\n");							
	if ($dc_bres34_rms >= 0.005) { 		GMT_psxy('-W1,coral,1_1:0 -Gred -N'); }
	elsif ($dc_bres34_rms >= 0.003) { 	GMT_psxy('-W1,coral,1_1:0 -Gorange -N'); }
	elsif ($dc_bres34_rms >= 0.0015) { 	GMT_psxy('-W1,coral,1_1:0 -Gyellow -N'); }
	else {								GMT_psxy('-W1,coral,1_1:0 -Ggreen -N'); }
#		print(GMT "0.945 0.90\n0.98 0.90\n0.945 0.935\n");							
		print(GMT "0.945 0.90\n0.98 0.90\n0.98  0.935\n0.945 0.935\n");							
	if ($uc_bres12_rms >= 0.005) { 		GMT_psxy('-W1,SeaGreen,8_2:0 -Gred -N'); }
	elsif ($uc_bres12_rms >= 0.003) { 	GMT_psxy('-W1,SeaGreen,8_2:0 -Gorange -N'); }
	elsif ($uc_bres12_rms >= 0.0015) { 	GMT_psxy('-W1,SeaGreen,8_2:0 -Gyellow -N'); }
	else {								GMT_psxy('-W1,SeaGreen,8_2:0 -Ggreen -N'); }
#		print(GMT "0.90 0.98\n0.935 0.98\n0.935 0.945\n");							
		print(GMT "0.90 0.98\n0.935 0.98\n0.935 0.945\n0.90 0.945\n");							
	if ($uc_bres34_rms >= 0.005) { 		GMT_psxy('-W1,SeaGreen,1_1:0 -Gred -N'); }
	elsif ($uc_bres34_rms >= 0.003) { 	GMT_psxy('-W1,SeaGreen,1_1:0 -Gorange -N'); }
	elsif ($uc_bres34_rms >= 0.0015) { 	GMT_psxy('-W1,SeaGreen,1_1:0 -Gyellow -N'); }
	else {								GMT_psxy('-W1,SeaGreen,1_1:0 -Ggreen -N'); }
#		print(GMT "0.945 0.98\n0.98 0.98\n0.945 0.945\n");							
		print(GMT "0.945 0.98\n0.98 0.98\n0.98 0.945\n0.945 0.945\n");							
	
	GMT_pstext('-F+f14,Helvetica,blue+jTL -N');											# LABELS
		print(GMT "0.01 -0.06 $P{out_basename} [$P{run_label}]\n");
	GMT_pstext('-F+f12,Helvetica+jTR');
		print(GMT "0.61 0.02 m.abs.dev.\n");
	GMT_pstext('-F -N');
		print(GMT "0.32 1.12 Vertical Velocity [m/s]\n");
	GMT_pstext('-F+f9,Helvetica,LightSkyBlue+jTR -N -Gwhite');
		print(GMT "0.99 0.01 V$VERSION\n");

	GMT_pstext('-F+f12,Helvetica,coral+jTL -Gwhite');
		print(GMT "0.02 0.02 downcast\n");
	GMT_pstext('-F+f12,Helvetica,SeaGreen+jTL -Gwhite');
		print(GMT "0.24 0.02 upcast\n");
	if ($have_BT) {
		GMT_pstext('-F+f12,Helvetica,black+jBL -Gwhite');
			print(GMT "0.02 0.98 b.track\n");
	}

# The following values were established manually in July 2021 with
# a GMT version that does not seem to respect y, maybe because of
# super-/subscripts.
#	my(@y) = (1.020,1.056,1.090,1.135);	# 0.036, 0.034, 0.035
#	my(@y) = (1.020,1.056,1.088,1.131);
	my(@y) = (1.020,1.060,1.088,1.127);

	GMT_pstext('-F+f9,Helvetica,CornFlowerBlue+jTL -N');
		printf(GMT "0.64 $y[0] %d kHz $LADCP{INSTRUMENT_TYPE} $P{ADCP_orientation}\n",
					round($LADCP{BEAM_FREQUENCY},50));

#		printf(GMT "0.64 1.055 %s [%.1fm/%1.fm/%1.fm]\n",
#			$LADCP{BEAM_COORDINATES} ? 'beam vels' : 'Earth vels',
#			$LADCP{BLANKING_DISTANCE},$LADCP{TRANSMITTED_PULSE_LENGTH},$LADCP{BIN_LENGTH});

		print( GMT "0.64 $y[1] mean w\n			0.77 $y[1] :\n");
		printf(GMT "0.64 $y[2] mean tilt\n 		0.77 %f :\n",$y[2]+0.007);
		print( GMT "0.64 $y[3] rms a\@-pkg\@-\n	0.77 $y[3] :\n");

	if (abs($P{'dc_w.mu'} - $P{'uc_w.mu'}) < 0.005) {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -N');
	} elsif (abs($P{'dc_w.mu'} - $P{'uc_w.mu'}) < 0.01) {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -Gyellow -N');
    } else {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -Gred -N');
    }
	printf(GMT "0.78 %f %dmm/s\n",$y[1]-0.006,round($P{'dc_w.mu'}*1000));

	if (abs($P{'dc_w.mu'} - $P{'uc_w.mu'}) < 0.005) {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -N');
	} elsif (abs($P{'dc_w.mu'} - $P{'uc_w.mu'}) < 0.01) {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -Gyellow -N');
    } else {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -Gred -N');
    }
	printf(GMT "0.89 %f %dmm/s\n",$y[1]-0.006,round($P{'uc_w.mu'}*1000));


	if ($P{'dc_tilt.mu'} < 4) {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -N');
	} elsif ($P{'dc_tilt.mu'} < 8) {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -Gyellow -N');
	} else {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -Gred -N');
	}
	printf(GMT "0.808 $y[2] %.1f\\260\n",$P{'dc_tilt.mu'});

	if ($P{'uc_tilt.mu'} < 4) {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -N');
	} elsif ($P{'uc_tilt.mu'} < 8) {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -Gyellow -N');
	} else {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -Gred -N');
	}
	printf(GMT "0.91 $y[2] %.1f\\260\n",$P{'uc_tilt.mu'});

	if ($P{'dc_accel_pkg.rms'} < 0.1) {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -Gblue -N');
	} elsif ($P{'dc_accel_pkg.rms'} < 0.7) {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -N');
	} else {
		GMT_pstext('-F+f9,Helvetica,coral+jTL -Gyellow -N');
	}
	printf(GMT "0.78 %f %.1fm/s\@+2\@+\n",$y[3]-0.01,$P{'dc_accel_pkg.rms'});
		
	if ($P{'uc_accel_pkg.rms'} < 0.1) {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -Gblue -N');
	} elsif ($P{'uc_accel_pkg.rms'} < 0.7) {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -N');
	} else {
		GMT_pstext('-F+f9,Helvetica,SeaGreen+jTL -Gyellow -N');
	}
	printf(GMT "0.89 %f %.1fm/s\@+2\@+\n",$y[3]-0.01,$P{'uc_accel_pkg.rms'});
		
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
