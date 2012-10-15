#======================================================================
#                    E D I T _ D A T A . P L 
#                    doc: Sat May 22 21:35:55 2010
#                    dlm: Mon Oct 15 10:03:13 2012
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 28 81 NIL 0 0 72 2 2 4 NIL ofnI
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

# NOTES:
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
	$LADCP{ENSEMBLE}[$ens]->{PITCH}   -= $pitch_bias;
	$LADCP{ENSEMBLE}[$ens]->{ROLL}    -= $roll_bias;
	$LADCP{ENSEMBLE}[$ens]->{HEADING} -= $heading_bias;
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

	return 0 if ($LADCP{ENSEMBLE}[$ens]->{TILT} <= $lim);

	my($nrm) = 0;
	for (my($bin)=0; $bin<$LADCP{N_BINS}; $bin++) {
		next unless defined($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		undef($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		$nrm++;
#		for (my($beam)=0; $beam<4; $beam++) {
#			next unless defined($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][$beam]);
#			undef($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][$beam]);
#			$nrm++;
#		}
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
# ($nvrm,$nerm) = editSideLobes($fromEns,$toEns,$range)
#
# NOTES:
#	1) When this code is executed the sound speed is known. No attempt is made to correct for
#	   along-beam soundspeed variation, but the soundspeed at the transducer is accounted for.
#======================================================================

sub editSideLobes($$$)
{
	my($fe,$te,$wd) = @_;	# first & last ens to process, water depth for downlooker
	my($nvrm) = 0;			# of velocities removed
	my($nerm) = 0;			# of ensembles affected
	for (my($e)=$fe; $e<=$te; $e++) {
		next unless numberp($LADCP{ENSEMBLE}[$e]->{CTD_DEPTH});
		my($range) = $LADCP{ENSEMBLE}[$e]->{XDUCER_FACING_UP}
				   ? $LADCP{ENSEMBLE}[$e]->{CTD_DEPTH}
				   : $wd - $LADCP{ENSEMBLE}[$e]->{CTD_DEPTH};
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
