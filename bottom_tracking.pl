#======================================================================
#                    B O T T O M _ T R A C K I N G . P L 
#                    doc: Wed Oct 20 21:05:37 2010
#                    dlm: Mon Oct 24 10:10:09 2011
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 144 0 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Oct 20, 2010: - created
#	Dec 30, 2010: - adapted for use with LADCP_w
#	Oct 11, 2011: - moved defaults to [defaults.pl]
#	Oct 24, 2011: - disabled not-very-useful %BT-params

# This code is essentially identical to the one used in LADCPproc. Differences:
#	1) velocity editing is simpler: no wake editing, no PPI editing, no shear
#	   editing, no w outlier
#	2) median/mad calculated instead of mean/stddev
#	3) u,v not calculated

#----------------------------------------------------------------------
# bin valid BT-referenced velocities
#	input:	ensemble number, water depth (with uncertainty)
#	output:	@BTu,@BTv,@BTw				main result
#			editflags 					for information
#			@BTbtmu, @BTbtmv, @BTtilt 	stats to find reasons for quality differences
#----------------------------------------------------------------------

my($nBTfound,$nBTdepthFlag,$nBTvalidVelFlag,$nBTwFlag) = (0,0,0,0);
my(@BTu,@BTv,@BTw);

sub binBTprof($$$)
{
	my($ens,$wd,$sig_wd) = @_;

	my(@ea_max) = (0,0,0,0); my(@ea_max_bin) = (nan,nan,nan,nan);
	for (my($bin)=$LADCP_firstBin-1; $bin<=$LADCP_lastBin-1; $bin++) {
		$ea_max[0] = $LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$bin][0],
		$ea_max_bin[0] = $bin
			if ($LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$bin][0] > $ea_max[0]);
		$ea_max[1] = $LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$bin][1],
		$ea_max_bin[1] = $bin
			if ($LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$bin][1] > $ea_max[1]);
		$ea_max[2] = $LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$bin][2],
		$ea_max_bin[2] = $bin
			if ($LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$bin][2] > $ea_max[2]);
		$ea_max[3] = $LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$bin][3],
		$ea_max_bin[3] = $bin
			if ($LADCP{ENSEMBLE}[$ens]->{ECHO_AMPLITUDE}[$bin][3] > $ea_max[3]);
	}

	return													# disregard boundary maxima
		unless (min(@ea_max_bin) > $LADCP_firstBin-1) && 
			   (max(@ea_max_bin) < $LADCP_lastBin-1);
	return													# inconsistent range to seabed
		unless (max(@ea_max_bin)-min(@ea_max_bin) <= $BT_max_bin_range_diff);
		
	$nBTfound++;
	my($seafloor_bin) = round(avg(@ea_max_bin));

	my(@bd) = calc_binDepths($ens);
	$nBTdepthFlag++,return									# BT range inconsistent with water depth
		unless (abs($wd-$bd[$seafloor_bin]) < max($sig_wd,$LADCP{BIN_LENGTH}));

	# try vertical velocities at seabed bin plus one above and below
	# this does not really work because, often, only one of the bins has valid velocities
	my($w1) = $LADCP{ENSEMBLE}[$ens]->{W_UNEDITED}[$seafloor_bin-1];
	my($w2) = $LADCP{ENSEMBLE}[$ens]->{W_UNEDITED}[$seafloor_bin  ];
	my($w3) = $LADCP{ENSEMBLE}[$ens]->{W_UNEDITED}[$seafloor_bin+1];

	$w1 = 9e99 unless numberp($w1);							# invalid velocity sentinels
	$w2 = 9e99 unless numberp($w1);
	$w3 = 9e99 unless numberp($w1);

	my($seafloor_u,$seafloor_v,$seafloor_w);

	# determine which of the three trial bins is most consistent with reflr vertical velocities
	die("assertion failed") unless numberp($LADCP{ENSEMBLE}[$ens]->{REFLR_W});
	if (abs($LADCP{ENSEMBLE}[$ens]->{REFLR_W}-$w1) < abs($LADCP{ENSEMBLE}[$ens]->{REFLR_W}-$w2) &&
		abs($LADCP{ENSEMBLE}[$ens]->{REFLR_W}-$w1) < abs($LADCP{ENSEMBLE}[$ens]->{REFLR_W}-$w3)) {
			$seafloor_u = $LADCP{ENSEMBLE}[$ens]->{U_UNEDITED}[$seafloor_bin-1];
			$seafloor_v = $LADCP{ENSEMBLE}[$ens]->{V_UNEDITED}[$seafloor_bin-1];
			$seafloor_w = $LADCP{ENSEMBLE}[$ens]->{W_UNEDITED}[$seafloor_bin-1];
	} elsif (abs($LADCP{ENSEMBLE}[$ens]->{REFLR_W}-$w1) < abs($LADCP{ENSEMBLE}[$ens]->{REFLR_W}-$w2)) {
			$seafloor_u = $LADCP{ENSEMBLE}[$ens]->{U_UNEDITED}[$seafloor_bin+1];
			$seafloor_v = $LADCP{ENSEMBLE}[$ens]->{V_UNEDITED}[$seafloor_bin+1];
			$seafloor_w = $LADCP{ENSEMBLE}[$ens]->{W_UNEDITED}[$seafloor_bin+1];
	} else {
			$nBTvalidVelFlag++,return						# none of 3 trial bins has valid velocity
				if ($w2 == 9e99);
			$seafloor_u = $LADCP{ENSEMBLE}[$ens]->{U_UNEDITED}[$seafloor_bin];
			$seafloor_v = $LADCP{ENSEMBLE}[$ens]->{V_UNEDITED}[$seafloor_bin];
			$seafloor_w = $LADCP{ENSEMBLE}[$ens]->{W_UNEDITED}[$seafloor_bin];
	}

	$nBTwFlag++,return										# velocity error is too great
		if (abs($seafloor_w-$LADCP{ENSEMBLE}[$ens]->{REFLR_W}) > $BT_max_w_error);

	push(@BTbtmu,$seafloor_u);								# calc stats to try to find reasons for quality
	push(@BTbtmv,$seafloor_v);
	push(@BTbtmw,$seafloor_w);
	push(@BTtilt,$LADCP{ENSEMBLE}[$ens]->{TILT});

	for (my($bin)=$LADCP_firstBin-1; $bin<=$LADCP_lastBin-1; $bin++) {
		next unless defined($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		my($gi) = int($bd[$bin]) / $output_bin_size;
		push(@{$BTw[$gi]},$LADCP{ENSEMBLE}[$ens]->{W}[$bin]-$seafloor_w);
	}
}

#----------------------------------------------------------------------
# calculate BT-referenced velocity profile
#	input:	start,end LADCP ensembles, water depth with uncertainty
#	output: %BT{MEDIAN_W,MAD_W,N_SAMP}
#----------------------------------------------------------------------

sub calc_BTprof($$$$)
{
	my($LADCP_start,$LADCP_end,$wd,$sig_wd) = @_;

	for (my($ens)=$LADCP_start; $ens<=$LADCP_end; $ens++) {
		next unless ($wd-$LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH} < $BT_max_range);
		binBTprof($ens,$wd,$sig_wd);
	}

	progress("\t$nBTfound BT ensembles found\n");
	progress("\t$nBTdepthFlag flagged bad because of wrong bottom depth\n");
	progress("\t$nBTvalidVelFlag flagged bad because of no valid velocities\n");
	progress("\t$nBTwFlag flagged bad because of incorrect vertical velocity\n");

	for (my($gi)=0; $gi<@BTw; $gi++) {						# calc grid medians & mads
		$BT{N_SAMP}[$gi] = @{$BTw[$gi]};
		$BT{MEDIAN_W}[$gi] = median(@{$BTw[$gi]});
        $BT{MAD_W}[$gi] = mad2($BT{W}[$gi],@{$BTw[$gi]});
	}

#	&antsAddParams('BT_rms_seafloor_u',round(rms(@BTbtmu),0.01),
#				   'BT_rms_seafloor_v',round(rms(@BTbtmv),0.01),
#				   'BT_rms_seafloor_w',round(rms(@BTbtmw),0.01),
#				   'BT_avg_seafloor_u',round(avg(@BTbtmu),0.01),
#				   'BT_avg_seafloor_v',round(avg(@BTbtmv),0.01),
#				   'BT_avg_seafloor_w',round(avg(@BTbtmw),0.01),
#				   'BT_rms_tilt',round(rms(@BTtilt),0.1));
}

1;
