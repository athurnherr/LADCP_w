#======================================================================
#                    P L O T _ A T T I T U D E _ B I A S E S _ W . P L 
#                    doc: Sun May 15 16:08:59 2016
#                    dlm: Wed May 18 19:43:55 2016
#                    (c) 2016 A.M. Thurnherr
#                    uE-Info: 41 37 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	May 15, 2016: - created from [plot_mean_residuals.pl]
#	May 16, 2016: - continued
#	May 17, 2016: - renamed from [plot_attitude_biases.pl]
#   May 18, 2016: - added version
#				  - expunged $realLastGoodEns

require "$ANTS/libGMT.pl";

sub plot_attitude_biases_w($)
{
	my($pfn) = @_;																	# plot file name

	my($xmin) = -round($opt_t);														# full pitch range 
	my($xmax) =  round($opt_t);
	my($ymin) =  -0.05;
	my($ymax) =   0.05;

	my($min_thin) = 200;
	my($min_fat)  = 500;
	my($btstrp_ndraw) = 20;
	my($excluded_surf_layer) = 150;

	#--------------------------------------------------------
	# Bin-Average & Create Histogram from Beampair Velocities
	#	- use 1-degree bins for simplicity
	#	- use gimbal pitch (not measured pitch)
	#--------------------------------------------------------

	my(@pHistDC,@rHistDC,@pSumDC,@rSumDC,$pHistDC,$rHistDC,$pSumDC,$rSumDC);
	my(@pHistUC,@rHistUC,@pSumUC,@rSumUC,$pHistUC,$rHistUC,$pSumUC,$rSumUC);
	my(@pValsDC,@rValsDC,@pValsUC,@rValsUC,$mode);
	for (my($e)=$firstGoodEns; $e<=$lastGoodEns; $e++) {
		next unless numberp($LADCP{ENSEMBLE}[$e]->{CTD_DEPTH});
		my(@bindepth) = calc_binDepths($e);
		for (my($bin)=$LADCP_firstBin-1; $bin<=$LADCP_lastBin-1; $bin++) {
			next if ($bindepth[$bin] <= $excluded_surf_layer);
			next unless ($bin+1>=$outGrid_firstBin && $bin+1<=$outGrid_lastBin);
			next unless numberp($LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin]) &&
						numberp($LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin]);
			my($pi) = int($LADCP{ENSEMBLE}[$e]->{GIMBAL_PITCH}+$opt_t);			# pitch/roll indices
			my($ri) = int($LADCP{ENSEMBLE}[$e]->{ROLL}+$opt_t);
			if ($e < $LADCP_atbottom) {											# downcast
			 	push(@{$pValsDC[$pi]},$LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin]);
			 	push(@{$rValsDC[$ri]},$LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin]);
				$pSumDC += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin]; $pHistDC++; 
				$rSumDC += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin]; $rHistDC++;
				$pSumDC[$pi] += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin]; $pHistDC[$pi]++; 
				$rSumDC[$ri] += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin]; $rHistDC[$ri]++;
				$mode = $pHistDC[$pi] if ($pHistDC[$pi] > $mode);
				$mode = $rHistDC[$ri] if ($rHistDC[$ri] > $mode);
			} else { 																# upcast
			 	push(@{$pValsUC[$pi]},$LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin]);
			 	push(@{$rValsUC[$ri]},$LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin]);
				$pSumUC += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin]; $pHistUC++; 
				$rSumUC += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin]; $rHistUC++;
				$pSumUC[$pi] += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W12}[$bin]; $pHistUC[$pi]++; 
				$rSumUC[$ri] += $LADCP{ENSEMBLE}[$e]->{SSCORRECTED_OCEAN_W34}[$bin]; $rHistUC[$ri]++;
				$mode = $pHistUC[$pi] if ($pHistUC[$pi] > $mode);
				$mode = $rHistUC[$ri] if ($rHistUC[$ri] > $mode);
			}
		}
	}

	#----------
	# Plot Data
	#----------

	my($R) = "-R$xmin/$xmax/$ymin/$ymax";												# begin plot
	GMT_begin($pfn,'-JX10/10',$R,"-P -Bg5f1a5:'Pitch/Roll [\260]':/g0.01f0.001a0.01:'Beam-Plane Vertical Velocity [m/s]':WeSn");

	# ZERO LINE
	GMT_psxy('-W4,CornflowerBlue');
		print(GMT "$xmin 0\n$xmax 0\n");

	# DC PITCH
	GMT_psxy('-Ey0.2/2,coral');
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($pHistDC[$i] >= $min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$pValsDC[$i]});	# 95% bootstrap conf limits
			printf(GMT "%f %f %f\n",$i-round($opt_t)-0.3,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Ey0.2/1,coral');															# dc pitch
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($pHistDC[$i]>=$min_thin && $pHistDC[$i]<$min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$pValsDC[$i]});	# 95% bootstrap conf limits
			printf(GMT "%f %f %f\n",$i-round($opt_t)-0.3,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Sc0.15 -Gcoral');
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($pHistDC[$i] >= $min_thin);
			printf(GMT "%f %f\n",$i-round($opt_t)-0.3,$pSumDC[$i]/$pHistDC[$i]);		# errorbar center symbol 
			printf(GMT "%f %f\n",$i-round($opt_t)-0.3,$ymin+0.03*$pHistDC[$i]/$mode);	# histogram symbol
		}
	if ($pHistDC) {
		GMT_psxy('-W1,coral,8_2:0');													# average bias (horizontal line);
			printf(GMT ">\n%f %f\n%f %f\n",-$opt_t,$pSumDC/$pHistDC,$opt_t,$pSumDC/$pHistDC)
	}
	GMT_psxy('-W2,coral,8_2:0');
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($pHistDC[$i] >= $min_thin);
			printf(GMT ">\n%f %f\n%f %f\n%f %f\n>\n%f %f\n%f %f\n",						# histogram bar
					$i-round($opt_t)-0.3-0.5,$ymin,
					$i-round($opt_t)-0.3-0.5,$ymin+0.03*$pHistDC[$i]/$mode,
					$i-round($opt_t)-0.3+0.5,$ymin+0.03*$pHistDC[$i]/$mode,
					$i-round($opt_t)-0.3+0.5,$ymin,
					$i-round($opt_t)-0.3+0.5,$ymin+0.03*$pHistDC[$i]/$mode);
		}

	GMT_psxy('-Ey0.2/2,coral');															# dc roll
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($rHistDC[$i] >= $min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$rValsDC[$i]});
			printf(GMT "%f %f %f\n",$i-round($opt_t)-0.1,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Ey0.2/1,coral');
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($rHistDC[$i]>=$min_thin && $rHistDC[$i]<$min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$rValsDC[$i]});
			printf(GMT "%f %f %f\n",$i-round($opt_t)-0.1,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Sx0.25 -W2,coral');
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($rHistDC[$i] >= $min_thin);
			printf(GMT "%f %f\n",$i-round($opt_t)-0.1,$rSumDC[$i]/$rHistDC[$i]);
			printf(GMT "%f %f\n",$i-round($opt_t)-0.1,$ymin+0.03*$rHistDC[$i]/$mode);
		}
	if ($rHistDC) {
		GMT_psxy('-W1,coral,2_2:0');
			printf(GMT ">\n%f %f\n%f %f\n",-$opt_t,$rSumDC/$rHistDC,$opt_t,$rSumDC/$rHistDC);
	}
	GMT_psxy('-W2,coral,2_2:0');
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($rHistDC[$i] >= $min_thin);
			printf(GMT ">\n%f %f\n%f %f\n%f %f\n>\n%f %f\n%f %f\n",
					$i-round($opt_t)-0.1-0.5,$ymin,
					$i-round($opt_t)-0.1-0.5,$ymin+0.03*$rHistDC[$i]/$mode,
					$i-round($opt_t)-0.1+0.5,$ymin+0.03*$rHistDC[$i]/$mode,
					$i-round($opt_t)-0.1+0.5,$ymin,
					$i-round($opt_t)-0.1+0.5,$ymin+0.03*$rHistDC[$i]/$mode);
		}

	GMT_psxy('-Ey0.2/2,SeaGreen');													# uc pitch
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($pHistUC[$i] >= $min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$pValsUC[$i]});
			printf(GMT "%f %f %f\n",$i-round($opt_t)+0.1,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Ey0.2/1,SeaGreen');
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($pHistUC[$i]>=$min_thin && $pHistUC[$i]<$min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$pValsUC[$i]});
			printf(GMT "%f %f %f\n",$i-round($opt_t)+0.1,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Sc0.15 -GSeaGreen');
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($pHistUC[$i] >= $min_thin);
			printf(GMT "%f %f\n",$i-round($opt_t)+0.1,$pSumUC[$i]/$pHistUC[$i]);
			printf(GMT "%f %f\n",$i-round($opt_t)+0.1,$ymin+0.03*$pHistUC[$i]/$mode);
		}
	if ($pHistUC) {
		GMT_psxy('-W1,SeaGreen,8_2:0');
			printf(GMT ">\n%f %f\n%f %f\n",-$opt_t,$pSumUC/$pHistUC,$opt_t,$pSumUC/$pHistUC);
	}
	GMT_psxy('-W2,SeaGreen,8_2:0');
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($pHistUC[$i] >= $min_thin);
			printf(GMT ">\n%f %f\n%f %f\n%f %f\n>\n%f %f\n%f %f\n",
					$i-round($opt_t)+0.1-0.5,$ymin,
					$i-round($opt_t)+0.1-0.5,$ymin+0.03*$pHistUC[$i]/$mode,
					$i-round($opt_t)+0.1+0.5,$ymin+0.03*$pHistUC[$i]/$mode,
					$i-round($opt_t)+0.1+0.5,$ymin,
					$i-round($opt_t)+0.1+0.5,$ymin+0.03*$pHistUC[$i]/$mode);
		}

	GMT_psxy('-Ey0.2/2,SeaGreen');													# uc roll
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($rHistUC[$i] >= $min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$rValsUC[$i]});
			printf(GMT "%f %f %f\n",$i-round($opt_t)+0.3,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Ey0.2/1,SeaGreen');													
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($rHistUC[$i]>=$min_thin && $rHistUC[$i]<$min_fat);
			my($minLim,$maxLim) = &bootstrap($btstrp_ndraw,0.95,\&avg,@{$rValsUC[$i]});
			printf(GMT "%f %f %f\n",$i-round($opt_t)+0.3,($maxLim+$minLim)/2,($maxLim-$minLim)/2);
		}
	GMT_psxy('-Sx0.25 -W2,SeaGreen');
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($rHistUC[$i] >= $min_thin);
			printf(GMT "%f %f\n",$i-round($opt_t)+0.3,$rSumUC[$i]/$rHistUC[$i]);
			printf(GMT "%f %f\n",$i-round($opt_t)+0.3,$ymin+0.03*$rHistUC[$i]/$mode);
		}
	if ($rHistUC) {
		GMT_psxy('-W1,SeaGreen,2_2:0');
			printf(GMT ">\n%f %f\n%f %f\n",-$opt_t,$rSumUC/$rHistUC,$opt_t,$rSumUC/$rHistUC);
	}
	GMT_psxy('-W2,SeaGreen,2_2:0');
		for (my($i)=0; $i<2*round($opt_t); $i++) {
			next unless ($rHistUC[$i] >= $min_thin);
			printf(GMT ">\n%f %f\n%f %f\n%f %f\n>\n%f %f\n%f %f\n",
					$i-round($opt_t)+0.3-0.5,$ymin,
					$i-round($opt_t)+0.3-0.5,$ymin+0.03*$rHistUC[$i]/$mode,
					$i-round($opt_t)+0.3+0.5,$ymin+0.03*$rHistUC[$i]/$mode,
					$i-round($opt_t)+0.3+0.5,$ymin,
					$i-round($opt_t)+0.3+0.5,$ymin+0.03*$rHistUC[$i]/$mode);
		}

	GMT_unitcoords();																	# LABELS
	GMT_pstext('-F+f9,Helvetica,orange+jTR -N -Gwhite');
        print(GMT "0.99 0.01 V$VERSION\n");
        
	GMT_pstext('-F+f14,Helvetica,blue+jBL -N');											# profile id
		print(GMT "0.0 1.03 $P{out_basename} $P{run_label}\n");

	GMT_setR($R);																		# FINISH PLOT
	GMT_end();
}

1; # return true on require
