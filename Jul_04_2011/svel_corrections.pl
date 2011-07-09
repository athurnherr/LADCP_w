#======================================================================
#                    S V E L _ C O R R E C T I O N S . P L 
#                    doc: Thu Dec 30 01:35:18 2010
#                    dlm: Thu Dec 30 01:40:13 2010
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 86 20 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

sub sscorr_w($$$$)												# sound-speed correction for w
{																# see RDI Coord. Trans. manual sec. 4.1, ...
	my($wObs,$wCTD,$dADCP,$dBin) = @_;							# but there is an error: the ^2 applies to the []
	my($tanSqBeamAngle) = tan(rad($LADCP{BEAM_ANGLE}))**2;

	$dADCP = int($dADCP);										# @sVelProf is binned to 1m
	$dBin = int($dBin);

	while (!numberp($sVelProf[$dADCP])) { $dADCP--; }			# skip gaps & bottom of profile
	while (!numberp($sVelProf[$dBin ])) { $dBin--;  }

	my($Kn) = sqrt(1 + (1 - $sVelProf[$dBin]/$sVelProf[$dADCP])**2 * $tanSqBeamAngle);
	return ($wObs*$sVelProf[$dBin]/1500 - $wCTD) / $Kn;
}

sub calc_binDepths($)											# see RDI Coord Trans manual sec. 4.2
{
	my($ens) = @_;
	my(@bindz);

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
