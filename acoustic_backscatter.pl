#======================================================================
#                    A C O U S T I C _ B A C K S C A T T E R . P L 
#                    doc: Wed Oct 20 13:02:27 2010
#                    dlm: Fri Nov  7 14:45:44 2014
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 80 0 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Oct 20, 2010: - created
#	Dec 10, 2010: - BUG: backscatter above sea surface made code bomb
#						 when run with uplooker data
#	Dec 30, 2010: - adapted for use with [LADCP_w]
#	Oct 19, 2011: - added support for $SS_{min,max}_allowed_range
#				  - BUG: acoustic-backscatter assumed 0 deg C
#				  - SV now saved in ensemble
#	Oct 21, 2011: - BUG: made code work for uplooker again
#	Mar  4, 2014: - added support for missing PITCH/ROLL (TILT)
#	Apr 17, 2014: - BUG: missing ;
#	Nov  7, 2014: - BUG: calc_binDepths() was called without valid CTD depth

#----------------------------------------------------------------------
# Volume Scattering Coefficient, following Deines (IEEE 1999)
# NOTES:
#	- instrument specific! (300kHz Workhorse)
#   - no sound-speed correction applied
#   - R in bin center, instead of last quarter
#   - transmit power assumes 33V batteries
#----------------------------------------------------------------------

# NB:
#	- correction seems to work for a subset of bins (~bins 3-9 for 
#	  2010 P403 station 46) 
#	- this may imply that noise level depends on bin
# 	- far bins are important for seabed detection, i.e. cannot simply
#	  be discarded at this stage

sub Sv($$$$$)
{
    my($temp,$PL,$Er,$R,$EA) = @_;
    my($C)      = -143;                 # RDI Workhorse monitor
    my($Ldbm)   = 10 * log10($PL);
    my($PdbW)   = 14.0;
    my($alpha)  = 0.069;
    my($Kc)     = 0.45;
    
    return $C + 10*log10(($temp+273)*$R**2) - $Ldbm - $PdbW
              + 2*$alpha*$R + $Kc*($EA-$Er);
}

#----------------------------------------------------------------------
# Calculate per-bin backscatter profiles
#	input: 	first and last valid LADCP ensemble
#	output:	sSv[$depth][$bin]	sum of volume scattering coefficients
#			nSv[$depth][$bin]	number of samples in bin
#----------------------------------------------------------------------

my(@sSv,@nSv);

sub calc_backscatter_profs($$)
{
	my($LADCP_start,$LADCP_end) = @_;
	
	my(@Er) = (1e99,1e99,1e99,1e99);						# echo intensity reference level
	for (my($ens)=$LADCP_start; $ens<=$LADCP_end; $ens++) {
		$Er[0] = $LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$LADCP{N_BINS}-1][0]
			if ($LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$LADCP{N_BINS}-1][0] < $Er[0]);
		$Er[1] = $LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$LADCP{N_BINS}-1][1]
			if ($LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$LADCP{N_BINS}-1][1] < $Er[1]);
		$Er[2] = $LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$LADCP{N_BINS}-1][2]
			if ($LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$LADCP{N_BINS}-1][2] < $Er[2]);
		$Er[3] = $LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$LADCP{N_BINS}-1][3]
			if ($LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$LADCP{N_BINS}-1][3] < $Er[3]);
    }
	debugmsg("per-beam noise levels = @Er\n");

	my($cosBeamAngle) = cos(rad($LADCP{BEAM_ANGLE}));
	for (my($ens)=$LADCP_start; $ens<=$LADCP_end; $ens++) {
		next unless numberp($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH});
		my(@bd) = calc_binDepths($ens);
		for (my($bin)=$LADCP_firstBin-1; $bin<=$LADCP_lastBin-1; $bin++) {
			my($depth) = int($bd[$bin]);
			next if ($depth<0 || !defined($LADCP{ENSEMBLE}[$ens]->{TILT}));
			my($range_to_bin) = abs($bd[$bin] - $LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH})
									/ cos(rad($LADCP{ENSEMBLE}[$ens]->{TILT}))
									/ $cosBeamAngle;
			next
				if ($range_to_bin < $SS_min_allowed_range ||
					$range_to_bin > $SS_max_allowed_range);
			my($temp) = defined($CTD_temp)
					  ? $CTD{TEMP}[$LADCP{ENSEMBLE}[$ens]->{CTD_SCAN}]
					  : $LADCP{ENSEMBLE}[$ens]->{TEMPERATURE};
			$LADCP{ENSEMBLE}[$ens]->{SV}[$bin] =
				median(
					Sv($temp,$LADCP{TRANSMITTED_PULSE_LENGTH},$Er[0],$range_to_bin,
					   $LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$bin][0]
				    ),
				    Sv($temp,$LADCP{TRANSMITTED_PULSE_LENGTH},$Er[1],$range_to_bin,
					   $LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$bin][1]
					),
					Sv($temp,$LADCP{TRANSMITTED_PULSE_LENGTH},$Er[2],$range_to_bin,
					   $LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$bin][2]
					),
					Sv($temp,$LADCP{TRANSMITTED_PULSE_LENGTH},$Er[3],$range_to_bin,
	     			   $LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$bin][3]
					)
				);
    		$sSv[$depth][$bin] += $LADCP{ENSEMBLE}[$ens]->{SV}[$bin];
			$nSv[$depth][$bin]++;
		}
	}
}

#----------------------------------------------------------------------
# determine location of seabed from backscatter profiles
#	input:	depth below seabed can possibly be (e.g. max CTD depth)
#	output:	median/mad of estimated water depth
#----------------------------------------------------------------------

sub find_backscatter_seabed($)
{
	my($search_below) = int($_[0]);								# grid index to begin search
	my(@wdepth);												# list of water_depth indices

	for (my($bin)=$LADCP_firstBin-1; $bin<=$LADCP_lastBin-1; $bin++) { 	# find backscatter min/max below $search_below in each bin
		my($minSv,$maxSv,$depthmaxSv,$lastvalid) = (1e99,-1e99,-1,-1);
		for (my($depth)=$search_below; $depth<@nSv; $depth++) {
			next unless ($nSv[$depth][$bin] > 0);
			my($Sv) = $sSv[$depth][$bin] / $nSv[$depth][$bin];
			$lastvalid = $depth;
			$minSv = $Sv if ($Sv < $minSv);
			$maxSv = $Sv, $depthmaxSv = $depth if ($Sv > $maxSv);
		}
		if ($maxSv-$minSv>10 && $depthmax!=$lastvalid) { 		# ignore boundary maxima & scatter
			push(@wdepth,$depthmaxSv);
		}
	}
	
	my($wd) = median(@wdepth);
	return ($wd,mad2($wd,@wdepth));

}

1;
