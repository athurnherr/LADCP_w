#======================================================================
#                    S V E L _ C O R R E C T I O N S . P L 
#                    doc: Thu Dec 30 01:35:18 2010
#                    dlm: Thu Apr 17 09:02:29 2014
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 49 24 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Dec 30, 2010: - created
#	Oct  5, 2011: - sscorr_w temporarily disabled
#				  - re-enabled
#	Oct 26, 2011: - BUG? in calc_binDepth() on very shallow station 38 in
#					2010 Gom Spill data set the uplooker code did not stop
#				 	at the surface, requiring additon of another test
#	Mar  4, 2014: - added support for missing TILT (PITCH/ROLL)

# NOTES:
#	In an effort to track down the scale bias, NBP0901 stn 160 was reprocessed with various
#   simplified soundspeed correction methods:
#		1) no sscorr: bias is depth dependent and disappears btw 2500 and 3000m
#		2) simplified (dBin/dADCP): very similar to full correction, esp. when dBin is used
#		3) hacked correction (1450m/s vs 1500m/s assumed soundspeed) => bias largely disappears

sub sscorr_w($$$$)												# sound-speed correction for w
{																# see RDI Coord. Trans. manual sec. 4.1, ...
	my($wObs,$wCTD,$dADCP,$dBin) = @_;							# but there is an error: the ^2 applies to the []
	my($tanSqBeamAngle) = tan(rad($LADCP{BEAM_ANGLE}))**2;

	$dADCP = int($dADCP);										# @sVelProf is binned to 1m
	$dBin = int($dBin);

	while (!numberp($sVelProf[$dADCP])) { $dADCP--; }			# skip gaps & bottom of profile
	while (!numberp($sVelProf[$dBin ])) { $dBin--;  }

	my($Kn) = sqrt(1 + (1 - $sVelProf[$dBin]/$sVelProf[$dADCP])**2 * $tanSqBeamAngle);
###	return $wObs - $wCTD;								# no correction
###	return ($wObs*$sVelProf[$dBin]/1500 - $wCTD);		# simplified correction; dADCP instead of dBin similar
	return ($wObs*$sVelProf[$dBin]/1500 - $wCTD) / $Kn;	# full correction
}

sub calc_binDepths($)											# see RDI Coord Trans manual sec. 4.2
{
	my($ens) = @_;
	my(@bindz);

	# if the following assertion fails, the entire code needs to be searched for
	# each call of calc_binDepths() needs to be protected by a test
	die("ensemble $ens") unless defined($LADCP{ENSEMBLE}[$ens]->{TILT});

	my($tanSqBeamAngle) = tan(rad($LADCP{BEAM_ANGLE}))**2;
	my($curdz) = 0;												# calc avg sndspeed btw transducer & 1st bin
	$curdz-- until numberp($sVelProf[int($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH}+$curdz)]);
	my($avgss) = my($ADCPss) = $sVelProf[int($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH}+$curdz)];
	
	my($sumss) = my($nss) = 0;
	if ($LADCP{ENSEMBLE}[$ens]->{XDUCER_FACING_UP}) {
		while ($curdz >= -$LADCP{DISTANCE_TO_BIN1_CENTER}*cos(rad($LADCP{ENSEMBLE}[$ens]->{TILT}))) {
			if (numberp($sVelProf[int($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH}+$curdz)])) {
				$sumss += $sVelProf[int($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH}+$curdz)]; $nss++;
			}
			$curdz--;
		}
	} else {
		while ($curdz <= $LADCP{DISTANCE_TO_BIN1_CENTER}*cos(rad($LADCP{ENSEMBLE}[$ens]->{TILT}))) {
			if (numberp($sVelProf[int($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH}+$curdz)])) {
				$sumss += $sVelProf[int($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH}+$curdz)]; $nss++;
			}
			$curdz++;
		}
	}
	$avgss = $sumss/$nss if ($nss>0);
	
	my($Kn) = sqrt(1 + (1 - $avgss/$ADCPss)**2 * $tanSqBeamAngle);
	$bindz[0] = $LADCP{ENSEMBLE}[$ens]->{XDUCER_FACING_UP} ?
					- $LADCP{DISTANCE_TO_BIN1_CENTER}*$Kn*$avgss/1500*cos(rad($LADCP{ENSEMBLE}[$ens]->{TILT})) :
					+ $LADCP{DISTANCE_TO_BIN1_CENTER}*$Kn*$avgss/1500*cos(rad($LADCP{ENSEMBLE}[$ens]->{TILT}));

	for (my($bin)=1; $bin<=$LADCP_lastBin-1; $bin++) {
		$sumss = $nss = 0;
		if ($LADCP{ENSEMBLE}[$ens]->{XDUCER_FACING_UP}) {
			while ($curdz >= $bindz[$bin-1]-$LADCP{BIN_LENGTH}*cos(rad($LADCP{ENSEMBLE}[$ens]->{TILT}))) {
				last unless (int($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH}+$curdz) >= 0);
				if (numberp($sVelProf[int($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH}+$curdz)])) {
					$sumss += $sVelProf[int($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH}+$curdz)]; $nss++;
				}
				$curdz--;
			}
		} else {
			while ($curdz <= $bindz[$bin-1]+$LADCP{BIN_LENGTH}*cos(rad($LADCP{ENSEMBLE}[$ens]->{TILT}))) {
				if (numberp($sVelProf[int($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH}+$curdz)])) {
					$sumss += $sVelProf[int($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH}+$curdz)]; $nss++;
				}
				$curdz++;
			}
		}
		$avgss = $sumss/$nss if ($nss > 0);			# otherwise, leave avgss as is
		
		$Kn = sqrt(1 + (1 - $avgss/$ADCPss)**2 * $tanSqBeamAngle);
		$bindz[$bin] = $LADCP{ENSEMBLE}[$ens]->{XDUCER_FACING_UP} ?
						$bindz[$bin-1] - $LADCP{BIN_LENGTH}*$Kn*$avgss/1500*cos(rad($LADCP{ENSEMBLE}[$ens]->{TILT})) :
	                    $bindz[$bin-1] + $LADCP{BIN_LENGTH}*$Kn*$avgss/1500*cos(rad($LADCP{ENSEMBLE}[$ens]->{TILT}));
    }

    my(@bindepth);
    for (my($i)=0; $i<@bindz; $i++) {
    	$bindepth[$i] = $LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH} + $bindz[$i];
    }
	return @bindepth;
}

1;
