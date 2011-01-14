#======================================================================
#                    E D I T _ L A D C P _ D A T A . P L 
#                    doc: Sat May 22 21:35:55 2010
#                    dlm: Sat Dec 25 21:59:38 2010
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 16 51 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	May 22, 2010: - created
#	May 24, 2010: - added editSideLobesFromSeabed()
#	Oct 29, 2010: - added editCorr_Earthcoords
#	Dec 20, 2010: - BUG: DISTANCE_TO_BIN1_CENTER & BIN_LENGTH had been
#						 interpreted as along-beam, rather than vertical
#				  - replaced editPitchRoll by editTilt
#	Dec 25, 2010: - adapted to changes in [LADCP_w]

# NOTES:
#	- all bins must be edited (not just valid ones), to allow
#	  reflr calculations to use invalid bins

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
#======================================================================

sub editErrVel($$)
{
	my($ens,$lim) = @_;

	my($nrm) = 0;
	for (my($bin)=0; $bin<$LADCP{N_BINS}; $bin++) {
		next if (abs($LADCP{ENSEMBLE}[$ens]->{ERRVEL}[$bin]) <= $lim);
		undef($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		$nrm++
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
