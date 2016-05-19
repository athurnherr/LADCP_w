#======================================================================
#                    P L O T _ A C C E L E R A T I O N _ R E S I D U A L S . P L 
#                    doc: Tue May 17 21:40:08 2016
#                    dlm: Wed May 18 19:43:18 2016
#                    (c) 2016 A.M. Thurnherr
#                    uE-Info: 46 37 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	May 17, 2016: - created from [plot_attitude_biases.pl]
#	May 18, 2016: - made work

require "$ANTS/libGMT.pl";

sub plot_acceleration_residuals($)
{
	my($pfn) = @_;																	# plot file name

	my($xmin) =  -1.5;
	my($xmax) =   1.5;
	my($ymin) = -0.03;
	my($ymax) =  0.03;
	my($bin_size) = 0.1; # m/s^3

	my($min_thin) = 200;
	my($min_fat)  = 500;
	my($btstrp_ndraw) = 20;
	my($excluded_surf_layer) = 150;
	my($hist_height)  = 0.015;

	my($xo1) = -0.03;
	my($xo2) = -0.01;
	my($xo3) =  0.01;
	my($xo4) =  0.03;

	#-------------------------------------------------------
	# Bin-Average & Create Histogram from Beampair Residuals 
	#	- use 0.1 m/s^3
	#	- also calculate mean/rms pitch
	#-------------------------------------------------------

	my(@pHistDC,@rHistDC,@pSumDC,@rSumDC,$pHistDC,$rHistDC,$pSumDC,$rSumDC);
	my(@pHistUC,@rHistUC,@pSumUC,@rSumUC,$pHistUC,$rHistUC,$pSumUC,$rSumUC);
	my(@pValsDC,@rValsDC,@pValsUC,@rValsUC,$mode);
	my(@w_ttSumDC,@w_ttSumUC);
	for (my($e)=$firstGoodEns; $e<=$lastGoodEns; $e++) {
		next unless numberp($LADCP{ENSEMBLE}[$e]->{CTD_DEPTH});
		my(@bindepth) = calc_binDepths($e);

		for (my($bin)=$LADCP_firstBin-1; $bin<=$LADCP_lastBin-1; $bin++) {
			next if ($bindepth[$bin] <= $excluded_surf_layer);
			next unless ($bin+1>=$outGrid_firstBin && $bin+1<=$outGrid_lastBin);
			next unless numberp($LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin]) &&
						numberp($LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin]);

			my($hi) = int(($CTD{W_tt}[$LADCP{ENSEMBLE}[$e]->{CTD_SCAN}]-$xmin)/$bin_size);
			next unless ($hi >= 0);
			my($bi) = $bindepth[$bin]/$opt_o;

			if ($e < $LADCP_atbottom) {												# DOWNCAST
				$w_ttSumDC += $CTD{W_tt}[$LADCP{ENSEMBLE}[$e]->{CTD_SCAN}];	$pHistDC++; $rHistDC++;
				$pSumDC += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin] - $DNCAST{MEDIAN_W}[$bi]; 
				$rSumDC += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin] - $DNCAST{MEDIAN_W}[$bi]; 
			 	push(@{$pValsDC[$hi]},$LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin] - $DNCAST{MEDIAN_W}[$bi]);
			 	push(@{$rValsDC[$hi]},$LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin] - $DNCAST{MEDIAN_W}[$bi]);
				$pSumDC[$hi] += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin] - $DNCAST{MEDIAN_W}[$bi]; $pHistDC[$hi]++; 
				$rSumDC[$hi] += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin] - $DNCAST{MEDIAN_W}[$bi]; $rHistDC[$hi]++;
				$mode = $pHistDC[$hi] if ($pHistDC[$hi] > $mode);
				$mode = $rHistDC[$hi] if ($rHistDC[$hi] > $mode);
			} else { 																# UPCAST
				$w_ttSumUC += $CTD{W_tt}[$LADCP{ENSEMBLE}[$e]->{CTD_SCAN}];	$pHistUC++; $rHistUC++;
				$pSumUC += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin] - $UPCAST{MEDIAN_W}[$bi]; 
				$rSumUC += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin] - $UPCAST{MEDIAN_W}[$bi];
			 	push(@{$pValsUC[$hi]},$LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin] - $UPCAST{MEDIAN_W}[$bi]);
			 	push(@{$rValsUC[$hi]},$LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin] - $UPCAST{MEDIAN_W}[$bi]);
				$pSumUC[$hi] += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin] - $UPCAST{MEDIAN_W}[$bi]; $pHistUC[$hi]++; 
				$rSumUC[$hi] += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin] - $UPCAST{MEDIAN_W}[$bi]; $rHistUC[$hi]++;
				$mode = $pHistUC[$hi] if ($pHistUC[$hi] > $mode);
				$mode = $rHistUC[$hi] if ($rHistUC[$hi] > $mode);
			}
		}
	}

	#----------
	# Plot Data
	#----------

	my($R) = "-R$xmin/$xmax/$ymin/$ymax";														# plot frame
	GMT_begin($pfn,'-JX10/10',$R,"-P -Bg0.5f0.1a0.5:'Acceleration Derivative (w\@-tt\@-) [m s\@+-3\@+]':/g0.01f0.001a0.01:'Beam-Plane Residual Vertical Velocity [m/s]':WeSn");

	# ZERO LINE
	GMT_psxy('-W4,CornflowerBlue');
		print(GMT "$xmin 0\n$xmax 0\n");

	# HISTOGRAMS
	GMT_psxy('-W2,coral');
		for (my($i)=0; $i<@pHistDC; $i++) {
			next unless ($pHistDC[$i] >= $min_thin);
			printf(GMT ">\n%f %f\n%f %f\n%f %f\n>\n%f %f\n%f %f\n",
					$i*$bin_size+$xmin+$xo2-($bin_size/2),$ymin,
					$i*$bin_size+$xmin+$xo2-($bin_size/2),$ymin+$hist_height*$pHistDC[$i]/$mode,
					$i*$bin_size+$xmin+$xo2+($bin_size/2),$ymin+$hist_height*$pHistDC[$i]/$mode,
					$i*$bin_size+$xmin+$xo2+($bin_size/2),$ymin,
					$i*$bin_size+$xmin+$xo2+($bin_size/2),$ymin+$hist_height*$pHistDC[$i]/$mode);
		}
	GMT_psxy('-W2,SeaGreen');
		for (my($i)=0; $i<@pHistUC; $i++) {
			next unless ($pHistUC[$i] >= $min_thin);
			printf(GMT ">\n%f %f\n%f %f\n%f %f\n>\n%f %f\n%f %f\n",
					$i*$bin_size+$xmin+$xo3-($bin_size/2),$ymin,
					$i*$bin_size+$xmin+$xo3-($bin_size/2),$ymin+$hist_height*$pHistUC[$i]/$mode,
					$i*$bin_size+$xmin+$xo3+($bin_size/2),$ymin+$hist_height*$pHistUC[$i]/$mode,
					$i*$bin_size+$xmin+$xo3+($bin_size/2),$ymin,
					$i*$bin_size+$xmin+$xo3+($bin_size/2),$ymin+$hist_height*$pHistUC[$i]/$mode);
		}

	# DC PITCH
	GMT_psxy('-Ey0.2/2,coral');
		for (my($i)=0; $i<@pHistDC; $i++) {
			next unless ($pHistDC[$i] >= $min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$pValsDC[$i]});			# 95% bootstrap conf limits
			printf(GMT "%f %f %f\n",$i*$bin_size+$xmin+$xo1,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Ey0.2/1,coral');																	# dc pitch
		for (my($i)=0; $i<@pHistDC; $i++) {
			next unless ($pHistDC[$i]>=$min_thin && $pHistDC[$i]<$min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$pValsDC[$i]});			# 95% bootstrap conf limits
			printf(GMT "%f %f %f\n",$i*$bin_size+$xmin+$xo1,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Sc0.15 -Gcoral');
		for (my($i)=0; $i<@pHistDC; $i++) {
			next unless ($pHistDC[$i] >= $min_thin);
			printf(GMT "%f %f\n",$i*$bin_size+$xmin+$xo1,$pSumDC[$i]/$pHistDC[$i]);				# errorbar center symbol 
		}
	if ($pHistDC) {
		GMT_psxy('-W1,coral,8_2:0');															# averages (lines)
			printf(GMT ">\n%f %f\n%f %f\n",$xmin,$pSumDC/$pHistDC,$xmax,$pSumDC/$pHistDC);		# 	bias
	}

	# DC ROLL
	GMT_psxy('-Ey0.2/2,coral');															
		for (my($i)=0; $i<@rHistDC; $i++) {
			next unless ($rHistDC[$i] >= $min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$rValsDC[$i]});
			printf(GMT "%f %f %f\n",$i*$bin_size+$xmin+$xo2,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Ey0.2/1,coral');
		for (my($i)=0; $i<@rHistDC; $i++) {
			next unless ($rHistDC[$i]>=$min_thin && $rHistDC[$i]<$min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$rValsDC[$i]});
			printf(GMT "%f %f %f\n",$i*$bin_size+$xmin+$xo2,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Sx0.25 -W2,coral');
		for (my($i)=0; $i<@rHistDC; $i++) {
			next unless ($rHistDC[$i] >= $min_thin);
			printf(GMT "%f %f\n",$i*$bin_size+$xmin+$xo2,$rSumDC[$i]/$rHistDC[$i]);
		}
	if ($rHistDC) {
		GMT_psxy('-W1,coral,2_2:0');
			printf(GMT ">\n%f %f\n%f %f\n",$xmin,$rSumDC/$rHistDC,$xmax,$rSumDC/$rHistDC);
	}

	# UC PITCH
	GMT_psxy('-Ey0.2/2,SeaGreen');													
		for (my($i)=0; $i<@pHistUC; $i++) {
			next unless ($pHistUC[$i] >= $min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$pValsUC[$i]});
			printf(GMT "%f %f %f\n",$i*$bin_size+$xmin+$xo3,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Ey0.2/1,SeaGreen');
		for (my($i)=0; $i<@pHistUC; $i++) {
			next unless ($pHistUC[$i]>=$min_thin && $pHistUC[$i]<$min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$pValsUC[$i]});
			printf(GMT "%f %f %f\n",$i*$bin_size+$xmin+$xo3,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Sc0.15 -GSeaGreen');
		for (my($i)=0; $i<@pHistUC; $i++) {
			next unless ($pHistUC[$i] >= $min_thin);
			printf(GMT "%f %f\n",$i*$bin_size+$xmin+$xo3,$pSumUC[$i]/$pHistUC[$i]);
		}
	if ($pHistUC) {
		GMT_psxy('-W1,SeaGreen,8_2:0');
			printf(GMT ">\n%f %f\n%f %f\n",$xmin,$pSumUC/$pHistUC,$xmax,$pSumUC/$pHistUC);
	}

	# UC ROLL
	GMT_psxy('-Ey0.2/2,SeaGreen');													
		for (my($i)=0; $i<@rHistUC; $i++) {
			next unless ($rHistUC[$i] >= $min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$rValsUC[$i]});
			printf(GMT "%f %f %f\n",$i*$bin_size+$xmin+$xo4,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Ey0.2/1,SeaGreen');													
		for (my($i)=0; $i<@rHistUC; $i++) {
			next unless ($rHistUC[$i]>=$min_thin && $rHistUC[$i]<$min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$rValsUC[$i]});
			printf(GMT "%f %f %f\n",$i*$bin_size+$xmin+$xo4,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Sx0.25 -W2,SeaGreen');
		for (my($i)=0; $i<@rHistUC; $i++) {
			next unless ($rHistUC[$i] >= $min_thin);
			printf(GMT "%f %f\n",$i*$bin_size+$xmin+$xo4,$rSumUC[$i]/$rHistUC[$i]);
		}
	if ($rHistUC) {
		GMT_psxy('-W1,SeaGreen,2_2:0');
			printf(GMT ">\n%f %f\n%f %f\n",$xmin,$rSumUC/$rHistUC,$xmax,$rSumUC/$rHistUC);
	}

	# ANNOTATIONS
	GMT_unitcoords();																	# LABELS
	GMT_pstext('-F+f9,Helvetica,orange+jTR -N -Gwhite');
        print(GMT "0.99 0.99 V$VERSION\n");
	GMT_pstext('-F+f14,Helvetica,blue+jBL -N');											# profile id
		print(GMT "0.0 1.03 $P{out_basename} $P{run_label}\n");

	GMT_setR($R);																		# FINISH PLOT
	GMT_end();
}

1; # return true on require
