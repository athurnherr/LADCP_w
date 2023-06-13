#======================================================================
#                    T I M E _ L A G . P L 
#                    doc: Fri Dec 17 21:59:07 2010
#                    dlm: Mon May  8 21:25:02 2023
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 85 102 NIL 0 0 72 2 2 4 NIL ofnI
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
#	Oct 12, 2011: - moved defaults to [defaults.pl]
#				  - BUG: code did not work correctly when there were less than 3
#						 valid offsets
#				  - BUG: code did not work correctly unless all windows
#						 returned valid offsets
#	Oct 13, 2011: - added $TL_out and $TL_hist_out
#				  - restricted 2nd-pass to time lags +-1.5s
#				  - tightened allowed spread for weighted-average calc
#				  - BUG: $le in &bestLag() could be > $lastGoodEns
#				  - disabled weighted-average offset calculation
#	Oct 14, 2011: - improved handling of %PARAMs
#				  - BUG: last ens of window estimation was off, probably accounting
#						 for Oct 13 BUG (fix disabled)
#				  - renamed _out to out_
#	Oct 17, 2011: - BUG: closed STDOUT caused problems with tee in plotting scripts
#	Oct 19, 2011: - BUG: windowing did not work correctly for short casts
#				  - BUG: search restarting did not work correctly
#				  - modified edge-of-window heuristics
#				  - added step to remove all lags with mad > median(mads)
#	Oct 20, 2011: - losened too-restrictive last step
#	Oct 21, 2011: - BUG: forgot to update $n_valid_windows while removing outlier lags
#	Oct 15, 2012: - added $cast_type to &calc_lag()
#				  - removed support for TLhist
#	Oct 16, 2012: - renamed field elapsed to elapsed.LADCP for clarity
#				  - made failure "soft"
#	Mar 23, 2012: - adapted to piece-wise time lagging
#	Apr 22, 2013: - replaced $max_allowed_w by $opt_m, $TL_required_top_three_fraction by $opt_3
#	May 14, 2013: - opt_m => w_max_lim
#	Mar  3, 2014: - BUG: var-name typo
#	May 23, 2014: - BUG: $s range check required in mad_w()
#   Apr 16, 2015: - turned output specifies into lists (re-design of
#                   plotting sub-system)
#				  - BUG: executable flag was not set on file output
#				  - disabled active output when ANTS are not available
#				  - croak -> error
#	May 15, 2015: - fiddled with assertions
#	Jun 19, 2015: - disabled L2 warning on partial-depth time-lagging failures
#	Jul 29, 2015: - support for new plotting system
#	Jan 22, 2016: - started adding support for timelag-filtering
#	Jan 23, 2016: - continued
#	Jan 24, 2016: - made it work
#				  - BUG: time-lag plot was not produced when final lag piece had problems
#	Jan 25, 2016: - search-radius-doubling heuristic had typo
#				  - added %PARAMs
#	Feb 19, 2016: - added support for -l
#				  - added warning
#	Mar  7, 2016: - BUG: editing did not work correctly in all cases
#	Mar  6, 2017: - BUG: assertion in mad_w failed with 2017 P18 DL#206
#	Mar  9, 2017: - tightened timelag editing (good_diff: 2->1)
#	Mar 22, 2018: - re-wrote heuristics to remove lags with large mads
#				  - BUG: bestLag with 1 valid sample returned 0 mad
#				  - BUG: timelag editing did not work correctly when there was not a sufficiently long valid lag
#	Mar 27, 2018: - BUG: re-written heuristic could fail when there was a valid but unpopular lag with very low mad.
#						 Solution: remove very unpopular lags first
#	Oct  4, 2018: - added timelagging debug code
#	Oct 16, 2018: - removed debug code
#	Jul  1, 2021: - made %PARAMs more standard
#	Aug  8, 2021: - BUG: empty upcast made time-lagging bomb
#	May  8, 2023: - added detection/mitigation of no-overlap initial guesses
#				  - added best_lag initialization
#				  - BUG: -3 L3 warning was not produced due to erroneous string equality check with ==
# HISTORY END

# DIFFICULT STATIONS:
#	NBP0901#131		this requires the search-radius doubling heuristic

# TODO:
#	- better seabed code (from LADCPproc)

my($TINY) = 1e-6;

sub mad_w($$$)																# mean absolute deviation
{
	my($fe,$le,$so) = @_;													# first/last LADCP ens, CTD scan offset

	my($LADCP_mean_w,$CTD_mean_w,$nsamp) = (0,0,0);
	for (my($e)=$fe; $e<=$le; $e++) {										# first, calculate mean w in window
		my($s) = int(($LADCP{ENSEMBLE}[$e]->{ELAPSED} + $CTD{TIME_LAG} - $CTD{ELAPSED}[0]) / $CTD{DT} + 0.5);

#	THE FOLLOWING LINE CAUSES AN ASSERTION FAILURE WITH 2017 P08 DL#206. I AM NOT SURE WHETHER MY
#	FIX SOLVES THE UNDERLYING PROBLEM OR ONLY THIS SPECIAL CASE.
#		next unless ($s>=0 && $s<=$#{$CTD{ELAPSED}});

		next unless ($s>0 && $s<=$#{$CTD{ELAPSED}});
		die("assertion failed\n" .
			"\ttest: abs($LADCP{ENSEMBLE}[$e]->{ELAPSED} + $CTD{TIME_LAG} - $CTD{ELAPSED}[$s]) <= $CTD{DT}/2\n" .
			"\te = $e, s = $s, ensemble = $LADCP{ENSEMBLE}[$e]->{NUMBER}"
		) unless (abs($LADCP{ENSEMBLE}[$e]->{ELAPSED} + $CTD{TIME_LAG} - $CTD{ELAPSED}[$s]) <= $CTD{DT}/2+$TINY);
		next unless numberp($LADCP{ENSEMBLE}[$e]->{REFLR_W});
		$LADCP_mean_w += $LADCP{ENSEMBLE}[$e]->{REFLR_W};
		$CTD_mean_w   += $CTD{W}[$s+$so];
		$nsamp++;
	}
	return 9e99 unless ($nsamp > 1);
	$LADCP_mean_w /= $nsamp;
	$CTD_mean_w /= $nsamp;

	my($sad) = $nsamp = 0;													# now, calculate mad
	for (my($e)=$fe; $e<=$le; $e++) {			
		my($s) = int(($LADCP{ENSEMBLE}[$e]->{ELAPSED} + $CTD{TIME_LAG} - $CTD{ELAPSED}[0]) / $CTD{DT} + 0.5);
		next unless ($s>=0 && $s<=$#{$CTD{ELAPSED}});
		next unless numberp($LADCP{ENSEMBLE}[$e]->{REFLR_W});
		my($dw) = $LADCP{ENSEMBLE}[$e]->{REFLR_W}-$LADCP_mean_w - ($CTD{W}[$s+$so]-$CTD_mean_w);
#		print(STDERR "dw = $dw ($LADCP{ENSEMBLE}[$e]->{REFLR_W}-$LADCP_mean_w - ($CTD{W}[$s+$so]-$CTD_mean_w)\n");
		next unless (abs($dw) <= $w_max_lim);
		$sad += abs($dw); $nsamp++;
	}
	return $nsamp ? $sad/$nsamp : 9e99;
}


sub bestLag($$$$)								# find best lag in window
{
	my($fe,$le,$ww,$soi) = @_;					# first/last LADCP ens, window width, scan-offset increment
	my($bestso) = 0;							# error at first-guess offset
	my($bestmad) = mad_w($fe,$le,0);

#	print(STDERR "bestLag($fe,$le,$ww,$soi)\n");
	for (my($dso) = 1; $dso <= int($ww/2/$CTD{DT} + 0.5); $dso+=$soi) {
		my($mad) = mad_w($fe,$le,-$dso);
#		print(STDERR "-$dso $mad\n");
		$bestmad=$mad,$bestso=-$dso if ($mad < $bestmad);
		$mad = mad_w($fe,$le,$dso);
#		print(STDERR " $dso $mad\n");
		$bestmad=$mad,$bestso=$dso if ($mad < $bestmad);
	}
#	print(STDERR "-> $bestso $bestmad\n");
	return ($bestso,$bestmad);
}

#----------------------------------------------------------------------
# carry out lag correlations and keep tally of the results
#----------------------------------------------------------------------

{ # STATIC SCOPE

local(@elapsed_buf,@so_buf,@mad_buf,@bmo_buf,@fg_buf,$lg_buf,$elapsed_min_buf);		# available to plot routines

sub calc_lag($$$$$)
{
	my($n_windows,$w_size,$scan_increment,$first_ens,$last_ens) = @_;
	my($search_radius) = $scan_increment==1 ? 3 : $w_size;

	&antsAddParams('TL_allowed_three_lag_spread.max',$TL_max_allowed_three_lag_spread);

	my($ctmsg);
	if ($first_ens==$firstGoodEns && $last_ens==$lastGoodEns) 	{ $ctmsg = "full-cast"; }
	else														{ $ctmsg = "partial-cast"; }

	my($last_lag_piece) = ($last_ens == $lastGoodEns);								# none is following

RETRY:
	my($failed) = undef;
	progress("Calculating $n_windows $ctmsg time lags from ${w_size}s-long windows at %dHz resolution...\n",
		int(1/$scan_increment/$CTD{DT}+0.5));

	my($approx_CTD_profile_start_ens) =
		$firstGoodEns + int(($CTD{ELAPSED}[0] - $CTD{TIME_LAG}) / $LADCP{MEAN_DT});
	my($approx_CTD_profile_end_ens) =
		$firstGoodEns + int(($CTD{ELAPSED}[$#{$CTD{ELAPSED}}] + $CTD{ELAPSED}[0] - $CTD{TIME_LAG}) / $LADCP{MEAN_DT});

	my($approx_joint_profile_start_ens) = max($firstGoodEns,$approx_CTD_profile_start_ens) + 10;
	my($approx_joint_profile_end_ens) 	= min($lastGoodEns,$approx_CTD_profile_end_ens) - 10;
	debugmsg("profile start: $firstGoodEns -> $approx_joint_profile_start_ens\n");
	debugmsg("profile end  : $lastGoodEns -> $approx_joint_profile_end_ens\n");

	my($window_ens) = int($w_size/$LADCP{MEAN_DT}+0.5);

	my(@elapsed,@so,@mad,%nBest,%madBest);
	my($n_valid_windows) = 0;

	$first_ens = $approx_joint_profile_start_ens
		if ($first_ens < $approx_joint_profile_start_ens);
	$last_ens = $approx_joint_profile_end_ens
		if ($last_ens > $approx_joint_profile_end_ens);

	for (my($wi)=0; $wi<$n_windows; $wi++) {									# use bestLag() in each window
		my($fe) = $first_ens + int(($last_ens-$first_ens-$window_ens)*$wi/($n_windows-1)+0.5);
		die("assertion failed\n\tfe = $fe, first_ens = $first_ens, last_ens = $last_ens, window_ens = $window_ens, firstGoodEns = $firstGoodEns, lastGoodEns = $lastGoodEns")
			unless ($fe>=$firstGoodEns && $fe+$window_ens<=$lastGoodEns);
		my($so,$mad) = bestLag($fe,$fe+$window_ens,$search_radius,$scan_increment);
		debugmsg("($so,$mad) = bestLag($fe,$fe+$window_ens,$search_radius,$scan_increment);\n");
		$elapsed[$wi] = $LADCP{ENSEMBLE}[$fe+int($w_size/2/$LADCP{MEAN_DT}+0.5)]->{ELAPSED};
		die("assertion failed\nfe=$fe, lastGoodEns=$lastGoodEns, w_size=$w_size") unless ($elapsed[$wi]);
		next unless ($mad < 9e99);
		$so[$wi] = $so; $mad[$wi] = $mad;
		$n_valid_windows++;
		$nBest{$so}++; $madBest{$so} += $mad;
	}

	unless ($n_valid_windows) {
		$failed = 1;
		goto CONTINUE;
    }

	my($maxN) = 0;
	foreach my $i (keys(%nBest)) {
		$maxN = $nBest{$i} if ($nBest{$i} > $maxN);
		$madBest{$i} /= $nBest{$i};
	}
	my($hint);
	unless ($maxN > 1) {
		error("$0: no overlap between time series; need valid -i to proceed\n")
			if ($hint > 8e99);
		warning(1,"poor guestimate -- no overlap between time series -- trying neigboring window\n");
		if (defined($hint)) {
			$CTD{TIME_LAG} = $hint;
			$hint = 9e99;
		} else {
			$CTD{TIME_LAG} += $search_radius/2;
			$hint = $CTD{TIME_LAG} - $search_radius/2;
		}
		undef(%nBest); undef(%madBest); undef(@best_lag);
		goto RETRY;
	}
	
	foreach my $lag (keys(%nBest)) {										# remove unpopular lags
		next if ($nBest{$lag} >= $maxN/10);
		$n_valid_windows -= $nBest{$lag};
		$nBest{$lag} = 0; $madBest{$lag} = 9e99;
	}
	
	my($min_mad) = min(values(%madBest));									# remove lags with large mads
	foreach my $lag (keys(%nBest)) {
		next if ($madBest{$lag} <= 3*$min_mad);
		$n_valid_windows -= $nBest{$lag};
		$nBest{$lag} = 0;
	}


	my(@best_lag) = (0,0,0);												# find 3 most popular lags
	foreach my $lag (keys(%nBest)) {
		$best_lag[0] = $lag if ($nBest{$lag} > $nBest{$best_lag[0]});
	}
	foreach my $lag (keys(%nBest)) {
		next if ($lag == $best_lag[0]);
		$best_lag[1] = $lag if ($nBest{$lag} > $nBest{$best_lag[1]});
	}
	foreach my $lag (keys(%nBest)) {
		next if ($lag == $best_lag[0] || $lag == $best_lag[1]);
		$best_lag[2] = $lag if ($nBest{$lag} > $nBest{$best_lag[2]});
	}
	if ($nBest{$best_lag[2]}) {												# there are at least 3 lags
		progress("\t3 most popular offsets: %d (%d%% %.1fcm/s mad), %d (%d%% %.1fcm/s mad), %d (%d%% %.1fcm/s mad)\n",
			$best_lag[0],int(($nBest{$best_lag[0]}/$n_valid_windows)*100+0.5),100*$madBest{$best_lag[0]},
			$best_lag[1],int(($nBest{$best_lag[1]}/$n_valid_windows)*100+0.5),100*$madBest{$best_lag[1]},
	        $best_lag[2],int(($nBest{$best_lag[2]}/$n_valid_windows)*100+0.5),100*$madBest{$best_lag[2]});
	} elsif ($nBest{$best_lag[1]}) {										# there are only 2 lags
		progress("\toffsets: %d (%d%% %.1fcm/s mad), %d (%d%% %.1fcm/s mad)\n",
			$best_lag[0],int(($nBest{$best_lag[0]}/$n_valid_windows)*100+0.5),100*$madBest{$best_lag[0]},
			$best_lag[1],int(($nBest{$best_lag[1]}/$n_valid_windows)*100+0.5),100*$madBest{$best_lag[1]});
	} else {																# there is only 1 lag
		progress("\toffset: %d (%d%% %.1fcm/s mad)\n",
			$best_lag[0],int(($nBest{$best_lag[0]}/$n_valid_windows)*100+0.5),100*$madBest{$best_lag[0]});
	}

	unless ($nBest{$best_lag[0]}+$nBest{$best_lag[1]}+$nBest{$best_lag[2]}	# require quorum
				>= $opt_3*$n_valid_windows) {
		if (max(@best_lag)-min(@best_lag) > $TL_max_allowed_three_lag_spread) {
			warning(2,"cannot determine a valid $ctmsg lag; top 3 tags account for %d%% of total (use -3 to relax criterion)\n",
				int(100*($nBest{$best_lag[0]}+$nBest{$best_lag[1]}+$nBest{$best_lag[2]})/$n_valid_windows+0.5))
					unless ($ctmsg eq 'partial-cast');
			$failed = 1;				
		} else {
			warning(1,"top 3 tags account for only %d%% of total\n",
				int(100*($nBest{$best_lag[0]}+$nBest{$best_lag[1]}+$nBest{$best_lag[2]})/$n_valid_windows+0.5));
		}
	}

	my($bmo) = $best_lag[0];												# best mean offset
	if ($bmo > 0.9*$search_radius/2/$CTD{DT}) { 							# cannot be near edge of window
		if ($search_radius == $w_size) {
			warning(0,"lag too close to edge of search --- trying again after shifting the initial offset\n");
			$CTD{TIME_LAG} += $search_radius/2;
		} else {
			warning(0,"lag too close to edge of search --- trying again after doubling the search radius\n");
			$search_radius *= 2;
			$search_radius = $w_size if ($search_radius > $w_size);
		}
		undef(%nBest); undef(%madBest); undef(@best_lag);
		goto RETRY;
	}
	if (-$bmo > 0.9*$search_radius/2/$CTD{DT}) {
		if ($search_radius == $w_size) {
			warning(0,"lag too close to edge of search --- trying again after shifting the initial offset\n");
			$CTD{TIME_LAG} -= $search_radius/2;
		} else {
			warning(0,"lag too close to edge of search --- trying again after doubling the search radius\n");
			$search_radius *= 2;
			$search_radius = $w_size if ($search_radius > $w_size);
		}
		undef(%nBest); undef(%madBest); undef(@best_lag);
		goto RETRY;
    }

	#----------------------------------------------------
	# Here, either $failed is set, or we have a valid lag.
	#----------------------------------------------------

CONTINUE:

#	if ($failed) {
#		for (my($wi)=0; $wi<$n_windows; $wi++) {
#			print(STDERR "$wi $so[$wi] $mad[$wi]\n");
#		}
#	}

	#----------------------------------------------------
	# Here, either $failed is set, or we have a valid lag.
	# If we have a valid lag, a continuous range of good 
	# lags is determined using a finite-state machine.
	# 	state == 0		no good run found yet
	# 	state == 1		good run found, $fg is set
	# A good run is at least $min_runlength long,
	# and every $scan_runlength-long sequence contains at
	# least $min_good scan offsets that
	# agree with the median offset within +/- $good_diff.
	#----------------------------------------------------

	my(@fg,@lg);
	my($min_runlength) = 7; my($scan_runlength) = 7; my($min_good) = 4; my($good_diff) = 1;
	unless ($failed || $scan_increment>1) {
		my($state) = 0; 
		for (my($i)=0; 1; $i++) {
#			printf(STDERR "$i: state = $state\n");
			if ($state == 0) {
				last if ($i >= @elapsed-$scan_runlength);
				my($ngood) = 0;
				for (my($j)=0; $j<$scan_runlength; $j++) {
					$ngood += (abs($bmo-$so[$i+$j]) <= $good_diff);
				}
#				printf(STDERR "$i: ngood = $ngood\n");
				if ($ngood >= $min_good) {							# we want at least 3 out of 5
					$state = 1;
					if ($i == 0) {									# run begins at start
						push(@fg,0);
					} else {										# run begins at first matching offset
						my($fg);
						for (my($j)=0; $j<$scan_runlength; $j++) {
							$fg = $i+$scan_runlength-1-$j
								if (abs($bmo-$so[$i+$scan_runlength-1-$j]) <= $good_diff);
						}
						push(@fg,$fg);
					}
				}
			} elsif ($state == 1) {									# growing run
				die("assertion failed (i = $i)")
					if ($i > @elapsed-$scan_runlength);
				if ($i == @elapsed-$scan_runlength) {				# run extends to end
					push(@lg,$#elapsed);
					last;
				}
				my($ngood) = 0;
				for (my($j)=0; $j<$scan_runlength; $j++) {
					$ngood += (abs($bmo-$so[$i+$j]) <= $good_diff);
				}
#				printf(STDERR "$i: ngood = $ngood\n");
				if ($ngood < $min_good) {							# run ended
					my($lg);
					for (my($j)=0; $j<$scan_runlength; $j++) {
						$lg = $i if (abs($bmo-$so[$i+$j]) <= 1);
					}
					push(@lg,$lg);
					$state = 0;
				}
			} # if state == 1
		} # for i
#		printf(STDERR "%d runs found\n",scalar(@lg));
	} # unless $failed || scan_increment > 1

	#--------------------------------------------------
	# Filter LADCP data for measurements during times
	# of uncertain time lags
	#--------------------------------------------------

	if ($scan_increment == 1 && !$opt_l) {
		progress("\tEditing data with unknown time-lags...\n");
		my(@elim);
#		print(STDERR "fg = @fg; lg = @lg\n");
		for (my($i)=0; $i<@fg; $i++) {
			next if ($lg[$i]-$fg[$i] < $min_runlength);
			push(@elim,($fg[$i] == 0) 			 ? $LADCP{ENSEMBLE}[$firstGoodEns]->{ELAPSED} : $elapsed[$fg[$i]],
					   ($lg[$i] == $n_windows-1) ? $LADCP{ENSEMBLE}[$lastGoodEns]->{ELAPSED}  : $elapsed[$lg[$i]]);
		}
#		print(STDERR "elim = @elim\n");
		$failed = 1 unless (@elim);
		$nerm = $failed
			  ? editBadTimeLagging($first_ens,$last_ens,-1)
			  : editBadTimeLagging($first_ens,$last_ens,@elim);
		my($pct) = round(100*$nerm/($last_ens-$first_ens+1));
	    progress("\t\t$nerm ensembles removed ($pct%% of total), leaving %d run(s)\n",scalar(@elim)/2);
		warning(1,"time-lag editing removed large fraction of samples (%d%% of total)\n",$pct)
			if ($pct > 30);
	}

	#------------------------------------------------------
	# Produce plot on fine-grained time-lagging
	#	- accumulate data into plot buffer
	#	- on last lag piece (usually upcast), plot is drawn
	#------------------------------------------------------

	if (@out_TL && $scan_increment==1) {
		push(@elapsed_buf,@elapsed);								# buffer elapsed data in static scope
		push(@so_buf,@so);											# scan offset
		push(@mad_buf,@mad);										# mean absolute deviation

		for (my($i)=0; $i<@fg; $i++) {
			next if ($lg[$i]-$fg[$i] < $min_runlength);
			push(@bmo_buf,$bmo);									# best median offset (copy for each run)
			push(@fg_buf,$elapsed[$fg[$i]]);						# first good so in lag-piece
			push(@lg_buf,$elapsed[$lg[$i]]);						# last good so in lag-piece
		}
		$elapsed_min_buf = $elapsed[0]								# min of valid elapsed (for plotting)
			unless defined($elapsed_min_buf);

		if ($last_lag_piece) {										
			progress("\tWriting time-lagging time series to ");		# output all data
			my($saveParams) = $antsCurParams;
			@antsNewLayout = ('elapsed.LADCP','scan_offset','mad','downcast');
	
			&antsAddParams('best_scan_offsets',"@bmo_buf");
#			&antsAddParams('to_elapsed_limits',"@te_buf");
			&antsAddParams('elapsed.min',$elapsed_min_buf);
			&antsAddParams('elapsed.max',$elapsed_buf[$#elapsed_buf]);
			&antsAddParams('elapsed.bot',$LADCP{ENSEMBLE}[$LADCP_atbottom]->{ELAPSED});

			foreach my $of (@out_TL) {
				progress("<$of> ");
				my($plot,$out) = ($of =~ /^([^\(]+)\(([^\)]+)\)$/); 					# plot_sub(out_file)
				if (defined($out)) {
					require "$WCALC/${plot}.pl";
					&{$plot}($out);
					next;
		        }
				$of = ">$of" unless ($of =~ /^$|^\s*\|/);
		        open(STDOUT,$of) || error("$of: $!\n");
				undef($antsActiveHeader) unless ($ANTS_TOOLS_AVAILABLE);

				for (my($wi)=0; $wi<@elapsed_buf; $wi++) {
					&antsOut($elapsed_buf[$wi],$so_buf[$wi],$mad_buf[$wi],
								($elapsed_buf[$wi]<$LADCP{ENSEMBLE}[$LADCP_atbottom]->{ELAPSED}));
				}
	    
	            &antsOut('EOF'); open(STDOUT,">&2");
            }
	        $antsCurParams = $saveParams;
			progress("\n");
		}
	}

	return defined($failed) ? undef : $CTD{TIME_LAG}+$bmo*$CTD{DT};
}

} # STATIC SCOPE


1;
