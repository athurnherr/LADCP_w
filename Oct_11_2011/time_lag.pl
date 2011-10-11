#======================================================================
#                    T I M E _ L A G . P L 
#                    doc: Fri Dec 17 21:59:07 2010
#                    dlm: Fri Sep 23 21:08:01 2011
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 101 42 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Dec 17, 2010: - created
#	Dec 18, 2010: - adapted for multi-pass lagging
#	Dec 20: 2010: - added code to adjust start and end of profile ens
#				    based on extent of CTD profile and guestimated time
#				    ofset
#	Jun 26, 2010: - added heuristic to chose between weighted-mean and
#					unambiguously best offsets
#				  - turned -3 criterion into warning when 3 lags are consecutive
#	Jul  4, 2011: - increased MAX_ALLOWED_THREE_LAG_SPREAD from 2 to 3
#	Jul  7, 2011: - removed window-mean w before time lagging to allow lagging
#				    of casts with large w
#	Aug  4, 2011: - made code use weighted average unless best lag accounts for
#				    more than 2/3 of lags (instead of 50%)
#	Sep 23, 2011: - added mad info to best lag guesses
#				  - removed window-doubling heuristics

# DIFFICULT STATIONS:
#	NBP0901#005

# TODO:
#	- better seabed code (from LADCPproc)
#	- intermediate-step timelagging guess
#	- flip aliased ensembles

my($MAX_ALLOWED_THREE_LAG_SPREAD) = 3;			# this was initially set to 2 but found to be
												# violated quite often during 2011_IWISE. A
												# large spread may indicate dropped CTD scans.
												# The optimum value may be cast-duration dependent.

sub mad_w($$$)									# mean absolute deviation
{
	my($fe,$le,$so) = @_;						# first/last LADCP ens, CTD scan offset
	my($sad) = my($n) = 0;

	my($LADCP_mean_w,$CTD_mean_w,$nsamp) = (0,0,0);
	for (my($e)=$fe; $e<=$le; $e++) {			# first, calculate mean w in window
		my($s) = int(($LADCP{ENSEMBLE}[$e]->{ELAPSED} + $CTD{TIME_LAG} - $CTD{ELAPSED}[0]) / $CTD{DT} + 0.5);
		die("assertion failed\n" .
			"\ttest: abs($LADCP{ENSEMBLE}[$e]->{ELAPSED} + $CTD{TIME_LAG} - $CTD{ELAPSED}[$s]) <= $CTD{DT}/2\n" .
			"\te = $e, s = $s, ensemble = $LADCP{ENSEMBLE}[$e]->{NUMBER}"
		) unless (abs($LADCP{ENSEMBLE}[$e]->{ELAPSED} + $CTD{TIME_LAG} - $CTD{ELAPSED}[$s]) <= $CTD{DT}/2);
		next unless numberp($LADCP{ENSEMBLE}[$e]->{REFLR_W});
		my($dw) = $LADCP{ENSEMBLE}[$e]->{REFLR_W}-$LADCP_mean_w - ($CTD{W}[$s+$so]-$CTD_mean_w);
		next unless (abs($dw) <= $opt_m);

		$LADCP_mean_w += $LADCP{ENSEMBLE}[$e]->{REFLR_W};
		$CTD_mean_w   += $CTD{W}[$s+$so];
		$nsamp++;
	}
	return 9e99 unless ($nsamp);
	$LADCP_mean_w /= $nsamp;
	$CTD_mean_w /= $nsamp;

	for (my($e)=$fe; $e<=$le; $e++) {			# now, calculate mad
		my($s) = int(($LADCP{ENSEMBLE}[$e]->{ELAPSED} + $CTD{TIME_LAG} - $CTD{ELAPSED}[0]) / $CTD{DT} + 0.5);
		my($dw) = $LADCP{ENSEMBLE}[$e]->{REFLR_W}-$LADCP_mean_w - ($CTD{W}[$s+$so]-$CTD_mean_w);
		next unless numberp($LADCP{ENSEMBLE}[$e]->{REFLR_W});
		next unless (abs($dw) <= $opt_m);
		$sad += abs($dw);
		$n++;
	}
	return ($n>0) ? $sad/$n : 9e99;				# n == 0, e.g. in bottom gap
}


sub bestLag($$$$)								# find best lag in window
{
	my($fe,$le,$ww,$soi) = @_;					# first/last LADCP ens, window width, scan-offset increment

	my($bestso) = 0;							# error at first-guess offset
	my($bestmad) = mad_w($fe,$le,0);

	for (my($dso) = 1; $dso <= int($ww/2/$CTD{DT} + 0.5); $dso+=$soi) {
		my($mad) = mad_w($fe,$le,-$dso);
		$bestmad=$mad,$bestso=-$dso if ($mad < $bestmad);
		$mad = mad_w($fe,$le,$dso);
		$bestmad=$mad,$bestso=$dso if ($mad < $bestmad);
	}
	return ($bestso,$bestmad);
}

#----------------------------------------------------------------------
# carry out lag correlations and keep tally of the results
#	- fist and last 10% of LADCP profile ignored
#----------------------------------------------------------------------

sub calc_lag($$$)
{
	my($n_windows,$w_size,$scan_increment) = @_;

RETRY:
	progress("Calculating $n_windows time lags from ${w_size}s-long windows at %dHz resolution...\n",
		int(1/$scan_increment/$CTD{DT}+0.5));

	my($approx_CTD_profile_start_ens) =
		$firstGoodEns + int(($CTD{ELAPSED}[0] - $CTD{TIME_LAG}) / $LADCP{MEAN_DT});
	my($approx_CTD_profile_end_ens) =
		$firstGoodEns + int(($CTD{ELAPSED}[$#{$CTD{ELAPSED}}] + $CTD{ELAPSED}[0] - $CTD{TIME_LAG}) / $LADCP{MEAN_DT});

	my($approx_joint_profile_start_ens) = max($firstGoodEns,$approx_CTD_profile_start_ens);
	my($approx_joint_profile_end_ens) 	= min($lastGoodEns,$approx_CTD_profile_end_ens);
	debugmsg("profile start: $firstGoodEns -> $approx_joint_profile_start_ens\n");
	debugmsg("profile end  : $lastGoodEns -> $approx_joint_profile_end_ens\n");

	my($skip_ens) = int(($approx_joint_profile_end_ens - $approx_joint_profile_start_ens) / 10 + 0.5);

	my(%nBest,%madBest);
	for (my($wi)=0; $wi<$n_windows; $wi++) {
		my($fe) = $approx_joint_profile_start_ens + $skip_ens + $wi*int(($approx_joint_profile_end_ens-$approx_joint_profile_start_ens-2*$skip_ens)/$n_windows+0.5);
		my($so,$mad) = bestLag($fe,$fe+int($w_size/$LADCP{MEAN_DT}+0.5),$w_size,$scan_increment);
		debugmsg("%.1f cm/s mad(w) at %3d scans offset\n",100*$mad,$so);
		$nBest{$so}++; $madBest{$so} += $mad;
	}
	
	my(@best_lag);
	foreach my $i (keys(%nBest)) {
		$madBest{$i} /= $nBest{$i};
		$best_lag[0] = $i if ($nBest{$i} > $nBest{$best_lag[0]});
	}
	foreach my $i (keys(%nBest)) {
		next if ($i == $best_lag[0]);
		$best_lag[1] = $i if ($nBest{$i} > $nBest{$best_lag[1]});
	}
	foreach my $i (keys(%nBest)) {
		next if ($i == $best_lag[0] || $i == $best_lag[1]);
		$best_lag[2] = $i if ($nBest{$i} > $nBest{$best_lag[2]});
	}
	progress("\t3 most popular offsets: %d (%d%% %.1fcm/s mad), %d (%d%% %.1fcm/s mad), %d (%d%% %.1fcm/s mad)\n",
		$best_lag[0],int(($nBest{$best_lag[0]}/$n_windows)*100+0.5),100*$madBest{$best_lag[0]},
		$best_lag[1],int(($nBest{$best_lag[1]}/$n_windows)*100+0.5),100*$madBest{$best_lag[1]},
		$best_lag[2],int(($nBest{$best_lag[2]}/$n_windows)*100+0.5),100*$madBest{$best_lag[2]});

# BETTER HEURISTIC NEEDED!
###	if ($nBest{$best_lag[0]}+$nBest{$best_lag[1]}+$nBest{$best_lag[2]} <= 6) {
###		warning(0,"cannot determine valid lag => trying again with doubled window size\n");
###		undef(%nBest); undef(%madBest);
###		$w_size *= 2;
###		goto RETRY;
###	}
	
	unless ($nBest{$best_lag[0]}+$nBest{$best_lag[1]}+$nBest{$best_lag[2]} >= $opt_3*$n_windows) {
		if (max(@best_lag)-min(@best_lag) > $MAX_ALLOWED_THREE_LAG_SPREAD) {
			croak(sprintf("$0: cannot determine a valid lag; top 3 tags account for %d%% of total (use -3 to relax criterion)\n",
				int(100*($nBest{$best_lag[0]}+$nBest{$best_lag[1]}+$nBest{$best_lag[2]})/$n_windows+0.5)))
		} else {
			warning(1,"top 3 tags account for only %d%% of total\n",
				int(100*($nBest{$best_lag[0]}+$nBest{$best_lag[1]}+$nBest{$best_lag[2]})/$n_windows+0.5));
		}
	}

	my($bmo);
	if (max(@best_lag)-min(@best_lag) > 5 || $nBest{$best_lag[0]}/$n_windows >= 2/3) {
		$bmo = $best_lag[0];
		progress("\tunambiguously best offset = %d scans\n",$bmo);
	} else {
		$bmo = ($nBest{$best_lag[0]}*$best_lag[0] +
				$nBest{$best_lag[1]}*$best_lag[1] +
				$nBest{$best_lag[2]}*$best_lag[2]) / ($nBest{$best_lag[0]} +
													  $nBest{$best_lag[1]} +
													  $nBest{$best_lag[2]});
		progress("\tweighted-mean offset = %.1f scans\n",$bmo);
	}

	if ($bmo > 0.9*$w_size/2/$CTD{DT}) {
		warning(0,"lag too close to the edge of the window --- trying again after adjusting the guestimated offset\n");
		$CTD{TIME_LAG} += $w_size/2;
		undef(%nBest);
		goto RETRY;
	}
	if (-$bmo > 0.9*$w_size/2/$CTD{DT}) {
		warning(0,"lag too close to the edge of the window --- trying again after adjusting the guestimated offset\n");
		$CTD{TIME_LAG} -= $w_size/2;
		undef(%nBest);
		goto RETRY;
	}

	return $CTD{TIME_LAG}+$bmo*$CTD{DT};
}


1;
