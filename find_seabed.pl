#======================================================================
#                    F I N D _ S E A B E D . P L 
#                    doc: Sun May 23 20:26:11 2010
#                    dlm: Tue Oct 11 18:09:06 2011
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 13 48 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	May 23, 2010: - adapted from [perl-tools/RDI_Utils.pl]
#	Dec 25, 2010: - adapted to changes in [LADCP_w]
#	Oct 11, 2011: - moved defaults to [defaults.pl]
#				  - increased z_offset from 10km to 15km

# NOTES:
#	1) BT range is corrected for sound speed at the transducer. This is not
#	   accurate, but unlikely to be very wrong, at least for deep casts, 
#	   because the vertical sound speed variability near the seabed tends
#	   to be small. The seabed depth is only used for sidelobe editing,
#	   which is done with a generous safety margin (from the UH shear
#	   method implementation).
#	2) Acquisition sound speed of 1500m/s assumed.
#	3) To be reasonably accurate, DEPTH must be from the CTD at this stage.

#======================================================================
# (seabed median depth, mad) = find_seabed(dta ptr, btm ensno, coord flag)
#======================================================================

my($z_offset) = 15000;		# shift z to ensure +ve array indices

sub find_seabed($$$)
{
	my($d,$be,$beamCoords) = @_;
	my($i,$dd,$sd,$nd);
	my(@guesses);

	return undef unless ($be-$SS_search_window_halfwidth >= 0 &&
						 $be+$SS_search_window_halfwidth <= $#{$d->{ENSEMBLE}});
	for ($i=$be-$SS_search_window_halfwidth; $i<=$be+$SS_search_window_halfwidth; $i++) {
		next unless (defined($d->{ENSEMBLE}[$i]->{CTD_DEPTH}) &&
					 defined($d->{ENSEMBLE}[$i]->{BT_RANGE}[0]) &&
					 defined($d->{ENSEMBLE}[$i]->{BT_RANGE}[1]) &&
					 defined($d->{ENSEMBLE}[$i]->{BT_RANGE}[2]) &&
					 defined($d->{ENSEMBLE}[$i]->{BT_RANGE}[3]));
		my(@BT) = $beamCoords
				? velInstrumentToEarth($d,$i,
					velBeamToInstrument($d,
						@{$d->{ENSEMBLE}[$i]->{BT_VELOCITY}}))
				: velApplyHdgBias($d,$i,@{$d->{ENSEMBLE}[$i]->{BT_VELOCITY}});
		next unless (abs($BT[3]) < 0.05);
		$d->{ENSEMBLE}[$i]->{DEPTH_BT} =
			 $d->{ENSEMBLE}[$i]->{BT_RANGE}[0]/4 +
			 $d->{ENSEMBLE}[$i]->{BT_RANGE}[1]/4 +
 			 $d->{ENSEMBLE}[$i]->{BT_RANGE}[2]/4 +
			 $d->{ENSEMBLE}[$i]->{BT_RANGE}[3]/4;
		$d->{ENSEMBLE}[$i]->{DEPTH_BT} *= cos(rad($d->{BEAM_ANGLE}));
		$d->{ENSEMBLE}[$i]->{DEPTH_BT} *= $CTD{SVEL}[$d->{ENSEMBLE}[$i]->{CTD_SCAN}]/1500;
		next unless ($d->{ENSEMBLE}[$i]->{DEPTH_BT} >= $SS_min_allowed_hab);
		$d->{ENSEMBLE}[$i]->{DEPTH_BT} *= -1
			if ($d->{ENSEMBLE}[$i]->{XDUCER_FACING_UP});
		$d->{ENSEMBLE}[$i]->{DEPTH_BT} += $d->{ENSEMBLE}[$i]->{CTD_DEPTH};
		if ($d->{ENSEMBLE}[$i]->{DEPTH_BT} > $d->{ENSEMBLE}[$be]->{CTD_DEPTH}) {
			$guesses[int($d->{ENSEMBLE}[$i]->{DEPTH_BT})+$z_offset]++;
			$nd++;
		} else {
			undef($d->{ENSEMBLE}[$i]->{DEPTH_BT});
		}
	}
	return undef unless ($nd>5);

	my($mode,$nmax);
	for ($i=0; $i<=$#guesses; $i++) {			# find mode
		$nmax=$guesses[$i],$mode=$i-$z_offset
			if ($guesses[$i] > $nmax);
	}

	$nd = 0;
	for ($i=$be-$SS_search_window_halfwidth; $i<=$be+$SS_search_window_halfwidth; $i++) {
		next unless defined($d->{ENSEMBLE}[$i]->{DEPTH_BT});
		if (abs($d->{ENSEMBLE}[$i]->{DEPTH_BT}-$mode) <= $SS_max_allowed_depth_range) {
			$dd += $d->{ENSEMBLE}[$i]->{DEPTH_BT};
			$nd++;
		} else {
			undef($d->{ENSEMBLE}[$i]->{DEPTH_BT});
		}
	}
	return undef unless ($nd >= 2);

	$dd /= $nd;
	for ($i=$be-$SS_search_window_halfwidth; $i<=$be+$SS_search_window_halfwidth; $i++) {
		next unless defined($d->{ENSEMBLE}[$i]->{DEPTH_BT});
		$sd += ($d->{ENSEMBLE}[$i]->{DEPTH_BT}-$dd)**2;
	}

	return ($dd, sqrt($sd/($nd-1)));
}

