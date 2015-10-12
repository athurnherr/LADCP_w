#======================================================================
#                    E D I T _ D A T A . P L 
#                    doc: Sat May 22 21:35:55 2010
#                    dlm: Sat Sep 26 12:58:46 2015
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 34 56 NIL 0 0 72 2 2 4 NIL ofnI
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

# NOTES:
#	- editCorr_Earthcoords() is overly conservative and removed most
#	  or all 3-beam solutions
#	- all bins must be edited (not just the ones between $LADCP_firstBin
#	  and $LADCP_lastBin to allow reflr calculations to use bins outside
#	  this range (ONLY FOR BEAM-COORD EDITS)
#	- however, to make the stats work, only the edited velocities
#	  inside the bin range are counted

#======================================================================
# correctAttitude($ens,$pitch_bias,$roll_bias,$heading_bias)
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
#	- called before Earth vels have been calculated
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
#	- if any of the 4 beam correlations is below the threshold,
#	  the entire velocity is removed
#	- this implies that (most? all?) three-beam solutions will
#	  be edited out, which is overly conserative
#	- a potentially better algorithm (used in LADCPproc) ignores the
#	  lowest correlation in all 3-beam solutions
#======================================================================

sub editCorr_Earthcoords($$)
{
	my($ens,$lim) = @_;

	my($nrm) = 0;
	for (my($bin)=0; $bin<$LADCP{N_BINS}; $bin++) {
		my($beam);
		for ($beam=0; $beam<4; $beam++) {
			last unless ($LADCP{ENSEMBLE}[$ens]->{CORRELATION}[$bin][$beam] >= $lim);
		}
		if ($beam < 4) {
			for (my($c)=0; $c<4; $c++) {
				next unless defined($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][$c]);
				undef($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][$c]);
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
		my($sscorr) = $CTD{SVEL}[$LADCP{ENSEMBLE}[$e]->{CTD_SCAN}] / 1500;
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
		if    ($LADCP{BEAM_FREQUENCY} == 1200) { $bha = 2.4; }
		elsif ($LADCP{BEAM_FREQUENCY} ==  600) { $bha = 2.5; }
		elsif ($LADCP{BEAM_FREQUENCY} ==  300) { $bha = 3.7; }
		elsif ($LADCP{BEAM_FREQUENCY} ==  150) { $bha = 6.7; }
		elsif ($LADCP{BEAM_FREQUENCY} ==   75) { $bha = 8.4; }
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
		my(@bd) = calc_binDepths($e);

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

1;
