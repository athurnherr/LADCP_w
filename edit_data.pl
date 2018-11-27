#======================================================================
#                    / D A T A / S R C / O C E A N O G R A P H Y / L A D C P _ V E R T I C A L _ V E L O C I T Y / E D I T _ D A T A . P L 
#                    doc: Sat May 22 21:35:55 2010
#                    dlm: Tue Nov 27 11:07:33 2018
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 46 71 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	May 22, 2010: - created
#	May 24, 2010: - added editSideLobesFromSeabed()
#	Oct 29, 2010: - added editCorr_Earthcoords
#	Dec 20, 2010: - BUG: DISTANCE_TO_BIN1_CENTER & BIN_LENGTH had been
#						 interpreted as along-beam, rather than vertical
#				  - replaced editPitchRoll by editTilt
#	Dec 25, 2010: - adapted to changes in [LADCP_w]
#	Aug  3, 2011: - added editTruncRange()
#	Oct 10, 2011: - added editFalsePositives()
#				  - BUG: when earth velocities were edited, all were
#						 counted, not just those between first and lastBin
#	Oct 11, 2011: - moved defaults to [defaults.pl]
#	Oct 12, 2011: - added &editSurfLayer()
#				  - BUG: editSideLobes() was slightly loose
#	Oct 15, 2011: - added editWOutliers()
#	Oct 20, 2011: - added editFarBins()
#	Oct 27, 2011: - adapted editTilt() to new call location
#				  - added correctAttitude()
#	Oct 15, 2012: - BUG: editSurfLayer() counted also ensembles without CTD depth
#	Nov 12, 2013: - added comments on editCorr_Earthcoords()
#	Mar  4, 2013: - added support for missing PITCH/ROLL (TILT) & HEADING
#	May 20, 2014: - added editPPI()
#	May 21, 2014: - got it to work correctly
#				  - croak -> error
#	Sep 26, 2015: - added $vessel_draft to editSideLobes
#	Jan 23, 2016: - added &editBadTimeLagging()
#	May 18, 2016: - removed assumption of 1500m/s soundspeed setting
#   May 24, 2016: - calc_binDepths() -> binDepths()
#	May 28, 2016: - added editResiduals_rmsMax, editResiduals_deltaMax
#	Jun  2, 2016: - added applyTiltCorrection()
#				  - maded editCorr_Earthcoords() less conservative
#				  - verified that removed velocities are counted correctly
#	Jun  3, 2016: - BUG: applyTiltCorrection() did not use gimbal_pitch
#	Jun  6, 2016: - removed applyTiltCorrection()
#	Oct 13, 2017: - BUG: editPPI() only allowed for nominal transducer frequencies
#	May  1, 2018: - added editLargeHSpeeds()
#	Nov 17, 2018: - BUG: spurious letter "z" had crept in at some stage

# NOTES:
#	- all bins must be edited (not just the ones between $LADCP_firstBin
#	  and $LADCP_lastBin to allow reflr calculations to use bins outside
#	  this range (ONLY FOR BEAM-COORD EDITS)
#	- however, to make the stats work, only the edited velocities
#	  inside the bin range are counted for those edit functions that
#	  report their stats wrt $nvw (for those which use $nvv,
#	  all velocities must be counted)

#======================================================================
# correctAttitude($ens,$pitch_bias,$roll_bias,$heading_bias)
#	- attitude bias correction
#	- this is called before gimbal_pitch is calculated
#======================================================================

sub correctAttitude($$$$)
{
	my($ens,$pitch_bias,$roll_bias,$heading_bias) = @_;
	$LADCP{ENSEMBLE}[$ens]->{PITCH}   -= $pitch_bias 	if defined($LADCP{ENSEMBLE}[$ens]->{PITCH});
	$LADCP{ENSEMBLE}[$ens]->{ROLL}    -= $roll_bias		if defined($LADCP{ENSEMBLE}[$ens]->{ROLL});
	$LADCP{ENSEMBLE}[$ens]->{HEADING} -= $heading_bias	if defined($LADCP{ENSEMBLE}[$ens]->{HEADING});
}

#======================================================================
# $vv = countValidVels($ens)
#
# NOTES:
#	- in case of Earth coords, this counts the velocity components
#	  (including errvel)
#======================================================================

sub countValidBeamVels($)
{
	my($ens) = @_;

	my($vv) = 0;
	for (my($bin)=0; $bin<$LADCP{N_BINS}; $bin++) {
		$vv += defined($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][0]);
		$vv += defined($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][1]);
		$vv += defined($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][2]);
		$vv += defined($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][3]);
	}
	return $vv;
}

#======================================================================
# $removed = editCorr($ens,$threshold)
#
# NOTES:
#	- called before Earth vels are calculated
#	- count removed velocities in all bins
#======================================================================

sub editCorr($$)
{
	my($ens,$lim) = @_;

	my($nrm) = 0;
	for (my($bin)=0; $bin<$LADCP{N_BINS}; $bin++) {
		for (my($beam)=0; $beam<4; $beam++) {
			next if ($LADCP{ENSEMBLE}[$ens]->{CORRELATION}[$bin][$beam] >= $lim ||
					 !defined($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][$beam]));
			undef($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][$beam]);
			$nrm++;
		}
	}
	return $nrm;
}

#======================================================================
# $removed = editCorr_Earthcoords($ens,$threshold)
#
# NOTES:
#	- if any of the used correlations is below the threshold,
#	  the entire velocity is removed
#	- for three-beam solutions two correlations must fail the
#	  test
#	- count velocities in all bins
#======================================================================

sub editCorr_Earthcoords($$)
{
	my($ens,$lim) = @_;

	my($nrm) = 0;
	for (my($bin)=0; $bin<$LADCP{N_BINS}; $bin++) {
		my($nBad) = 0;
		for (my($beam)=0; $beam<4; $beam++) {
			$nBad++ unless ($LADCP{ENSEMBLE}[$ens]->{CORRELATION}[$bin][$beam] > $lim);
		}
		if ($nBad-$LADCP{ENSEMBLE}[$ens]->{THREE_BEAM}[$bin] > 0) {
			for (my($beam)=0; $beam<4; $beam++) {
				next unless defined($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][$beam]);
				undef($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][$beam]);
				$nrm++;
			}
		}
	}
	return $nrm;
}

#======================================================================
# $removed = editTilt($ens,$threshold)
#
# NOTES:
#	- called after Earth vels have been calculated
#	- sets TILT field for each ensemble as a side-effect
#	- count all removed velocities
#======================================================================

sub editTilt($$)
{
	my($ens,$lim) = @_;

	$LADCP{ENSEMBLE}[$ens]->{TILT} =
		&angle_from_vertical($LADCP{ENSEMBLE}[$ens]->{PITCH},$LADCP{ENSEMBLE}[$ens]->{ROLL});

	return 0 unless ($LADCP{ENSEMBLE}[$ens]->{TILT} > $lim);

	my($nrm) = 0;
	for (my($bin)=0; $bin<$LADCP{N_BINS}; $bin++) {
		next unless defined($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		undef($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		$nrm++;
	}
	return $nrm;
}

#======================================================================
# $removed = editErrVel($ens,$threshold)
#
# NOTES:
#	- call after Earth vels have been calculated
#	- count only removed vels in selected bin range
#======================================================================

sub editErrVel($$)
{
	my($ens,$lim) = @_;

	my($nrm) = 0;
	for (my($bin)=0; $bin<$LADCP{N_BINS}; $bin++) {
		next unless defined($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		next if (abs($LADCP{ENSEMBLE}[$ens]->{ERRVEL}[$bin]) <= $lim);
		undef($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		$nrm++ if ($bin>=$LADCP_firstBin-1 && $bin<=$LADCP_lastBin-1);
	}
	return $nrm;
}

#======================================================================
# $removed = editWOutliers($ens,$lim)
#
# NOTES:
#	- call after Earth vels have been calculated
#	- count only removed vels in selected bin range
#	- lim determines how many times the mad an outlier has to be from median
#======================================================================

sub editWOutliers($$)
{
	my($ens,$lim) = @_;
	my($medw) = median(@{$LADCP{ENSEMBLE}[$ens]->{W}});
	my($madw) = mad2($medw,@{$LADCP{ENSEMBLE}[$ens]->{W}});
	
	my($nrm) = 0;
	for (my($bin)=0; $bin<$LADCP{N_BINS}; $bin++) {
		next unless defined($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		next if (abs($LADCP{ENSEMBLE}[$ens]->{W}[$bin]-$medw) <= $lim*$madw);
		undef($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		$nrm++ if ($bin>=$LADCP_firstBin-1 && $bin<=$LADCP_lastBin-1);
	}
	return $nrm;
}

#======================================================================
# $removed = editTruncRange($ens,$nbins)
#
# NOTES:
#	- call after Earth vels have been calculated
#	- count only removed vels in selected bin range
#======================================================================

sub editTruncRange($$)
{
	my($ens,$nbins) = @_;

	my($nrm) = 0;
	for (my($bin)=$LADCP{N_BINS}-1; $bin>=0 && $nrm<$nbins; $bin--) {
		next unless defined($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		undef($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		$nrm++ if ($bin>=$LADCP_firstBin-1 && $bin<=$LADCP_lastBin-1);
	}
	return $nrm;
}

#======================================================================
# $removed = editFarBins($ens,$first_bad_bin)
#
# NOTES:
#	- call after Earth vels have been calculated
#	- remove data from far bins
#	- only bins in valid range are considered here, because
#	  $per_bin_nsamp is only defined for those
#	- only velocities from bins in valid range are counted
#======================================================================

sub editFarBins($$)
{
	my($ens,$first_bad_bin) = @_;

	my($nrm) = 0;
	for (my($bin)=$first_bad_bin; $bin<=$LADCP_lastBin-1; $bin++) {
		next unless defined($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		undef($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		$nrm++;
	}
	return $nrm;
}

#======================================================================
# ($nvrm,$nerm) = editSideLobes($fromEns,$toEns,$water_depth)
#
# NOTES:
#	1) When this code is executed the sound speed is known. No attempt is made to correct for
#	   along-beam soundspeed variation, but the soundspeed at the transducer is accounted for.
#	2) for surface sidelobes, water_depth == undef; surface sidelobes include the
#	   vessel draft
#	- all velocities are counted, even those outside valid bin range,
#	  because the %age is not reported
#======================================================================

sub editSideLobes($$$)
{
	my($fe,$te,$wd) = @_;	# first & last ens to process, water depth for sidelobes near seabed
	my($nvrm) = 0;			# of velocities removed
	my($nerm) = 0;			# of ensembles affected
	for (my($e)=$fe; $e<=$te; $e++) {
		next unless numberp($LADCP{ENSEMBLE}[$e]->{CTD_DEPTH});
		my($range) = defined($wd) ? $wd - $LADCP{ENSEMBLE}[$e]->{CTD_DEPTH} 
								  : $LADCP{ENSEMBLE}[$e]->{CTD_DEPTH} - $vessel_draft;
		$range = 0 if ($range < 0);								  
		my($sscorr) = $CTD{SVEL}[$LADCP{ENSEMBLE}[$e]->{CTD_SCAN}] / $LADCP{ENSEMBLE}[$e]->{SPEED_OF_SOUND};
		my($goodBins) =   ($range - $sscorr*$LADCP{DISTANCE_TO_BIN1_CENTER}) * cos(rad($LADCP{BEAM_ANGLE}))
						/ ($sscorr*$LADCP{BIN_LENGTH})
						- 1.5;

		my($dirty) = 0;
		for (my($bin)=int($goodBins); $bin<$LADCP{N_BINS}; $bin++) { 	# NB: 2 good bins implies that bin 2 is bad
			next unless ($bin>=0 && defined($LADCP{ENSEMBLE}[$e]->{W}[$bin]));
			$dirty = 1;
			$nvrm++;
			undef($LADCP{ENSEMBLE}[$e]->{W}[$bin]);
		}

		$nerm += $dirty;
	}
	return ($nvrm,$nerm);
}


#======================================================================
# ($nvrm,$nerm) = editPPI($fromEns,$toEns,$water_depth)
#
# NOTES:
#	- only velocities in good bin range are removed/counted
#	- for UL, water_depth == undef; for DL water_depth is always defined,
#	  or else editPPI is not called
#	- when this code is executed a suitable UL or DL depth-average-soundspeed
#	  profile (@DASSprof at 1m resolution) is available
#	- PPI layer is defined by the shortest and longest acoustic paths
#	  between transducer and seabed that contribute significantly to the
#	  backscatter
#		- shortest path (shallow limit):
#			- distance to seabed => sidelobe
#			- min_lim = water_depth - DASSprof[CTD_depth]*DeltaT/2
#		- longest path (deep limit):
#			- outer edge of main lobe of one of the beams (depending on 
#			  instrument tilt)
#			- nominal half-beam apertures at half peak signal strength
#			  (-3dB), RDI BB Primer, pp. 35f (2ND COLUMN)
#				WH1200	1.4		2.4
#				WH600	1.5		2.5
#				WH300	2.2		3.7
#				WH150	4.0		6.7
#				WH75	5.0	    8.4
#			- for WH150, Fig. 23 indicates that half-beam-width 
#			  at -5dB (<1% peak signal strength) is about 5/3 of same
#			  at -3dB => PPI limit choice (3rd column above)
#		- [Plots/2014_P16_043.eps]:
#			- mean tilt of 2 degrees included in effects
#			- finite pulse length means that there actually
#			  is less elapsed time between the end of the sending
#			  and the beginning of the reception than the ping
#			  interval suggests; without it, the PPI peak depth
#			  does not agree with the prediction
#			- note that there is no PPI effect possible above
#			  the dark blue line --- this is a hard limit
#			  (I checked ping interval to within 0.001,
#			  water depth is known better than 2m, sound
#			  speed is accurately accounted for (as indicated
#			  by the cyan line), so the variability above
#			  is due to background variability, which is
#			  consistent with the shape of the curve outside
#			  the PPI layer
#		  	=> PPI peak can be tightly bracketed but care has to
#			   be taken to account for finite beam width & 
#			   instrument beam_tilt = max(|pitch|,|roll|)
#	- while the upper limit of the PPI layer is unambiguous, this
#	  is only true if the recorded ping intervals are accurate
#		- 2014 CLIVAR P16 #47 shows a slight discontinuity in dc_w near
#		  the middle of the upper PPI layer (4000m)
#		- the discontinuity is slightly more pronounced with PPI editing
#	      enabled
#		- setting $PPI_extend_upper_limit = 1.03 (or 1.04, 1.05, 1.1)
#		  reduces the discontinuity to the level without PPI filtering, but
#		  not any better
#		- overall I am not convinced that the discontinuity is related
#		  to PPI; therefore, $PPI_extend_upper_limit is not set by default
#======================================================================

{ my($bha);					# beam half aperture (static scope)

sub editPPI($$$)
{
	my($fe,$te,$wd) = @_;	# first & last ens to process, water depth for downlooker
	my($nvrm) = 0;			# of velocities removed
	my($nerm) = 0;			# of ensembles affected

	unless (defined($bha)) {
		if    (abs($LADCP{BEAM_FREQUENCY}-1200)/1200 <= 0.1) { $bha = 2.4; }
		elsif (abs($LADCP{BEAM_FREQUENCY}-600) / 600 <= 0.1) { $bha = 2.5; }
		elsif (abs($LADCP{BEAM_FREQUENCY}-300) / 300 <= 0.1) { $bha = 3.7; }
		elsif (abs($LADCP{BEAM_FREQUENCY}-150) / 150 <= 0.1) { $bha = 6.7; }
		elsif (abs($LADCP{BEAM_FREQUENCY}-75)  /  75 <= 0.1) { $bha = 8.4; }
		else { error("$0: unexpected transducer frequency $LADCP{BEAM_FREQUENCY}\n"); }
	}
	
	for (my($e)=$fe; $e<=$te; $e++) {
		next unless numberp($LADCP{ENSEMBLE}[$e]->{CTD_DEPTH});
		next unless ($e > 0);
		
		my($delta_t)   = $LADCP{ENSEMBLE}[$e]->{UNIX_TIME} - $LADCP{ENSEMBLE}[$e-1]->{UNIX_TIME};
		my($dz_max)    = $DASSprof[int($LADCP{ENSEMBLE}[$e]->{CTD_DEPTH})]*$delta_t / 2;
		my($beam_tilt) = max(abs($LADCP{ENSEMBLE}[$e]->{GIMBAL_PITCH}),
							 abs($LADCP{ENSEMBLE}[$e]->{ROLL}));
		my($dz_min)    = $dz_max * cos(rad($LADCP{BEAM_ANGLE} + $beam_tilt + $bha));
		my(@bd) = binDepths($e);

		$dz_max *= $PPI_extend_upper_limit
			if numberp($PPI_extend_upper_limit);

		my($dirty) = 0;
		for (my($bin)=$LADCP_firstBin-1; $bin<$LADCP_lastBin; $bin++) {
			next unless (defined($LADCP{ENSEMBLE}[$e]->{W}[$bin]));
			if (defined($wd)) {															# DL
				next unless ($bd[$bin] >= $wd-$dz_max && $bd[$bin] <= $wd-$dz_min);
			} else {																	# UL
				next unless ($bd[$bin] <= $dz_max && $bd[$bin] >= $dz_min);
			}
			$dirty = 1;
			$nvrm++;
			undef($LADCP{ENSEMBLE}[$e]->{W}[$bin]);
		}

		$nerm += $dirty;
	}
	return ($nvrm,$nerm);
}

} # static scope for $bha


#======================================================================
# $nerm = editSurfLayer($fromEns,$toEns,$surface_layer_depth)
#
# NOTES:
#	1) When this code is executed the fully corrected instrument and
#	   bin depths are known
#	2) This code was inspired by 2011_IWISE station 8
#	3) No point in counting the deleted velocities
#======================================================================

sub editSurfLayer($$$)
{
	my($fe,$te,$sld) = @_;		# first & last ens to process
	my($nerm) = 0;				# of ensembles affected
	for (my($e)=$fe; $e<=$te; $e++) {
		next unless numberp($LADCP{ENSEMBLE}[$e]->{CTD_DEPTH});
		undef($LADCP{ENSEMBLE}[$e]->{CTD_DEPTH}),$nerm++
			if ($LADCP{ENSEMBLE}[$e]->{CTD_DEPTH} <= $sld);
	}
	return $nerm;
}


#===============================================================================
# $nerm = editBadTimeLagging($fromEns,$toEns,$good_from_elapsed1,$good_to_elapsed1,...)
#
# NOTES:
#	- deleted velocities are not counted
#===============================================================================

sub editBadTimeLagging($$@)
{
	my($fe,$te,@elim) = @_;

	my($nerm) = 0;													# of ensembles removed
	my($i) = 0;

	if ($elim[0] < 0) {												# entire piece is bad
		for (my($e)=$fe; $e<=$te; $e++) {
			undef($LADCP{ENSEMBLE}[$e]->{REFLR_W});
			$nerm++;
		}
	} elsif (defined($elim[1])) {									# limits in elim
		my($e);
		for ($e=$fe; @elim; shift(@elim),shift(@elim)) {
#			print(STDERR "deleting to $elim[0]\n");
			while ($LADCP{ENSEMBLE}[$e]->{ELAPSED} < $elim[0]) {
				undef($LADCP{ENSEMBLE}[$e]->{REFLR_W});
				$nerm++;
				$e++;
			}
#			print(STDERR "keeping to $elim[1]\n");
			while ($LADCP{ENSEMBLE}[$e]->{ELAPSED} < $elim[1]) { $e++; }
	    }
#		print(STDERR "deleting to $LADCP{ENSEMBLE}[$te]->{ELAPSED}\n");
		while ($e <= $te) {
			undef($LADCP{ENSEMBLE}[$e]->{REFLR_W});
			$nerm++;
			$e++;
		}
	}
	return $nerm;
}

#======================================================================
# $nerm = editResiduals_rmsMax($fe,$te,$max_val)
#
# NOTES:
#	- removed velocities are not counted
#======================================================================

sub editResiduals_rmsMax($$$)
{
	my($fe,$te,$limit) = @_;
	my($nerm) = 0;
	for (my($ens)=$fe; $ens<=$te; $ens++) {
		next unless numberp($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH});
		my($sum) = my($n) = 0;														# calculate rms residual
		my(@bindepth) = binDepths($ens);
		for ($bin=$LADCP_firstBin-1; $bin<=$LADCP_lastBin-1; $bin++) {
			next unless ($bin+1>=$outGrid_firstBin && $bin+1<=$outGrid_lastBin);
		  	next unless numberp($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		  	my($bi) = $bindepth[$bin]/$opt_o;
			my($res) = ($ens < $LADCP_atbottom) ? 
						$LADCP{ENSEMBLE}[$ens]->{SSCORRECTED_OCEAN_W}[$bin] - $DNCAST{MEDIAN_W}[$bi] :
						$LADCP{ENSEMBLE}[$ens]->{SSCORRECTED_OCEAN_W}[$bin] - $UPCAST{MEDIAN_W}[$bi];
			$sum += &SQR($res); $n++;						
		}
		if ($n == 0 || sqrt($sum/$n) > $limit) {									# ensemble is bad
			undef($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH});
			$nerm++;
		}
	}
	return $nerm;
}

#======================================================================
# $nerm = editResiduals_deltaMax($fe,$te,$max_val)
#	- delta residual = delta beampair w => equal to scaled error velocity?
#	- sharp cutoff near 5cm/s for std parameters (0.1 m/s error velocity
#	  filter) in several data sets
#	- samples with large residuals differences are clear outliers in
# 	  the residuals vs tilt plots => obvious to remove
#	- how are large delta res possible given the errvel limit???
#	- only valid bin range is edited/counted
#======================================================================

sub editResiduals_deltaMax($$$)
{
	my($fe,$te,$limit) = @_;
	my($nvrm) = 0;
	for (my($ens)=$fe; $ens<=$te; $ens++) {
		next unless numberp($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH});
		for ($bin=$LADCP_firstBin-1; $bin<=$LADCP_lastBin-1; $bin++) {
			next unless ($bin+1>=$outGrid_firstBin && $bin+1<=$outGrid_lastBin);
			next unless numberp($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
			my($Dr) = abs($LADCP{ENSEMBLE}[$ens]->{SSCORRECTED_OCEAN_W12}[$bin] -
						  $LADCP{ENSEMBLE}[$ens]->{SSCORRECTED_OCEAN_W34}[$bin]);
			if ($Dr > $limit) {
				undef($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
				$nvrm++;
			}
		}
    }
    return $nvrm;
}

#======================================================================
# $nerm = editLargeHSpeeds($fe,$te,$max_hspeed)
#	- filter based on 2018 GO-SHIP LADCP profile #106, where UL 
#	  velocities become bad when ship starts dragging rosette
#	- only valid bin range is edited/counted
#======================================================================

sub editLargeHSpeeds($$$)
{
	my($fe,$te,$limit) = @_;
	my($nerm) = 0;
	for (my($ens)=$fe; $ens<=$te; $ens++) {
		next unless numberp($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH});
		next unless (vel_speed($LADCP{ENSEMBLE}[$ens]->{REFLR_U},
							   $LADCP{ENSEMBLE}[$ens]->{REFLR_U}) > $limit);
		undef($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH});
		$nerm++;
	}
    return $nerm;
}

#======================================================================

1;
