#======================================================================
#                    S V E L _ C O R R E C T I O N S . P L 
#                    doc: Thu Dec 30 01:35:18 2010
#                    dlm: Thu May 19 00:51:30 2016
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 19 65 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Dec 30, 2010: - created
#	Oct  5, 2011: - sscorr_w temporarily disabled
#				  - re-enabled
#	Oct 26, 2011: - BUG? in calc_binDepth() on very shallow station 38 in
#					2010 Gom Spill data set the uplooker code did not stop
#				 	at the surface, requiring additon of another test
#	Mar  4, 2014: - added support for missing TILT (PITCH/ROLL)
#	May 12, 2016: - removed unused lines of code
#	May 18, 2016: - removed assumption of 1500m/s soundspeed setting
#				  - made sscorr_w return nan on undef'd input vel

# NOTES:
#	In an effort to track down the scale bias, NBP0901 stn 160 was reprocessed with various
#   simplified soundspeed correction methods:
#		1) no sscorr: bias is depth dependent and disappears btw 2500 and 3000m
#		2) simplified (dBin/dADCP): very similar to full correction, esp. when dBin is used
#		3) hacked correction (1450m/s vs 1500m/s assumed soundspeed) => bias largely disappears

sub sscorr_w($$$$$)												# sound-speed correction for w
{																# see RDI Coord. Trans. manual sec. 4.1, ...
	my($wObs,$wCTD,$ssADCP,$dADCP,$dBin) = @_;					# but there is an error: the ^2 applies to the []
	return nan unless numberp($wObs);
	my($tanSqBeamAngle) = tan(rad($LADCP{BEAM_ANGLE}))**2;

	$dADCP = int($dADCP);										# @sVelProf is binned to 1m
	$dBin = int($dBin);

	while (!numberp($sVelProf[$dADCP])) { $dADCP--; }			# skip gaps & bottom of profile
	while (!numberp($sVelProf[$dBin ])) { $dBin--;  }

	my($Kn) = sqrt(1 + (1 - $sVelProf[$dBin]/$sVelProf[$dADCP])**2 * $tanSqBeamAngle);
	return ($wObs*$sVelProf[$dBin]/$ssADCP - $wCTD) / $Kn;		# full correction
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
					- $LADCP{DISTANCE_TO_BIN1_CENTER}*$Kn*$avgss/$LADCP{ENSEMBLE}[$ens]->{SPEED_OF_SOUND}*cos(rad($LADCP{ENSEMBLE}[$ens]->{TILT})) :
					+ $LADCP{DISTANCE_TO_BIN1_CENTER}*$Kn*$avgss/$LADCP{ENSEMBLE}[$ens]->{SPEED_OF_SOUND}*cos(rad($LADCP{ENSEMBLE}[$ens]->{TILT}));

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
						$bindz[$bin-1] - $LADCP{BIN_LENGTH}*$Kn*$avgss/$LADCP{ENSEMBLE}[$ens]->{SPEED_OF_SOUND}*cos(rad($LADCP{ENSEMBLE}[$ens]->{TILT})) :
	                    $bindz[$bin-1] + $LADCP{BIN_LENGTH}*$Kn*$avgss/$LADCP{ENSEMBLE}[$ens]->{SPEED_OF_SOUND}*cos(rad($LADCP{ENSEMBLE}[$ens]->{TILT}));
    }

    my(@bindepth);
    for (my($i)=0; $i<@bindz; $i++) {
    	$bindepth[$i] = $LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH} + $bindz[$i];
    }
	return @bindepth;
}

1;
