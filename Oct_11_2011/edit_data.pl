#======================================================================
#                    E D I T _ D A T A . P L 
#                    doc: Sat May 22 21:35:55 2010
#                    dlm: Tue Oct 11 13:48:21 2011
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 173 0 NIL 0 0 72 2 2 4 NIL ofnI
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

# NOTES:
#	- all bins must be edited (not just the ones between $LADCP_firstBin
#	  and $LADCP_lastBin to allow reflr calculations to use bins outside
#	  this range
#	- however, to make the stats work, only the edited velocities
#	  inside the bin range are counted

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
# $edited = editCorr($ens,$threshold)
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
# $edited = editTilt($ens,$threshold)
#
# NOTES:
#	- called before Earth vels have been calculated
#	- sets TILT field for each ensemble as a side-effect
#	- for consistency with editCorr() the individual velocities are counted
#======================================================================

sub editTilt($$)
{
	my($ens,$lim) = @_;

	$LADCP{ENSEMBLE}[$ens]->{TILT} =
		&angle_from_vertical($LADCP{ENSEMBLE}[$ens]->{PITCH},$LADCP{ENSEMBLE}[$ens]->{ROLL});

	return 0 if ($LADCP{ENSEMBLE}[$ens]->{TILT} <= $lim);

	my($nrm) = 0;
	for (my($bin)=0; $bin<$LADCP{N_BINS}; $bin++) {
		for (my($beam)=0; $beam<4; $beam++) {
			next unless defined($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][$beam]);
			undef($LADCP{ENSEMBLE}[$ens]->{VELOCITY}[$bin][$beam]);
			$nrm++;
		}
	}
	return $nrm;
}

#======================================================================
# $edited = editErrVel($ens,$threshold)
#
# NOTES:
#	- call after Earth vels have been calculated
#	- count only edited vels in selected bin range
#======================================================================

sub editErrVel($$)
{
	my($ens,$lim) = @_;

	my($nrm) = 0;
	for (my($bin)=0; $bin<$LADCP{N_BINS}; $bin++) {
		next if (abs($LADCP{ENSEMBLE}[$ens]->{ERRVEL}[$bin]) <= $lim);
		undef($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		$nrm++ if ($bin>=$LADCP_firstBin-1 && $bin<=$LADCP_lastBin-1);
	}
	return $nrm;
}

#======================================================================
# $edited = editTruncRange($ens,$nbins)
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
# $edited = editFalsePositives($ens,$nbins)
#
# NOTES:
#	- call after Earth vels have been calculated
#	- "false positives" are filtered in 2 stages:
#		1) invalidate any valid velocity bracketed by invalid ones
#		2) invalidate any remaining valid velocity following gap of
#		   length >= $FP_BAD_GAP; initial gap is not counted as such
#======================================================================

my($FP_BAD_GAP) = 3;

sub editFalsePositives($)
{
	my($ens) = @_;

	my($nrm) = 0;
	for (my($bin)=1; $bin<$LADCP{N_BINS}; $bin++) {
		next if defined($LADCP{ENSEMBLE}[$ens]->{W}[$bin-1])
			 || !defined($LADCP{ENSEMBLE}[$ens]->{W}[$bin])
			 || defined($LADCP{ENSEMBLE}[$ens]->{W}[$bin+1]);
		undef($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		$nrm++ if ($bin>=$LADCP_firstBin-1 && $bin<=$LADCP_lastBin-1);
	}
	my($s) = 9;  														# FINITE STATE MACHINE
	for (my($bin)=0; $bin<$LADCP{N_BINS}; $bin++) {
		if ($s == 9) {													# skip initial gap
			$s = 0 if defined($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		} elsif ($s == $FP_BAD_GAP) {									# gap too long => delete
			next unless defined($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
			undef($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
			$nrm++ if ($bin>=$LADCP_firstBin-1 && $bin<=$LADCP_lastBin-1);
        } else {														# short-enough gap
			$s = defined($LADCP{ENSEMBLE}[$ens]->{W}[$bin]) ? 0 : $s+1;
		}
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
		my($goodBins) =   ($range - $sscorr*$LADCP{DISTANCE_TO_BIN1_CENTER})
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

1;
