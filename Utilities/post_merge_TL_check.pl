#======================================================================
#                    U T I L I T I E S / P O S T _ M E R G E _ T L _ C H E C K . P L 
#                    doc: Wed Oct 12 10:23:58 2011
#                    dlm: Wed Oct 17 12:06:02 2012
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 33 15 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Oct 12, 2012: - created as an experimental time-lagging filter
#	Oct 17, 2012: - turned into this utility

#----------------------------------------------------------------------
# This code is used to verify (or improve) time lagging
#	- for each ensemble, a "narrow-band" time lagging is performed
#	  to determine the optimal scan offset
#	- time-lag window is taken from 2nd value of -w
#	- max search radius is hard-coded in $scan_offset_search_window
#----------------------------------------------------------------------

$post_merge_hook = sub {							# arguments: firstGoodEns, lastGoodEns
	my($fe,$le) = @_;

	progress("Writing optimal lags for all ensembles to $data_subdir/$out_basename.TLcheck...\n");

	my($scan_offset_search_window) = 10;
	my($ew_hwidth) =								# window half-width in ensembles
		int($length_of_timelag_windows[1]/2 / $LADCP{MEAN_DT} + 0.5);

	my(@mad,$nsamp);

	@antsNewLayout = ('ensemble','best_scan_offset','mad');
	open(STDOUT,">$data_subdir/$out_basename.TLcheck")
		|| croak("$data_subdir/$out_basename.TLcheck: $!\n");

	for (my($e)=$fe; $e<=$le; $e++) {
		next unless numberp($LADCP{ENSEMBLE}[$e]->{CTD_DEPTH});						# skip non-valid
		
		for (my($so)=-$scan_offset_search_window; $so<=$scan_offset_search_window; $so++) {			# find narrowband best lag
			$mad[$so + $scan_offset_search_window] = $nsamp = 0;
			for (my($i)=max($fe,$e-$ew_hwidth); $i<=min($le,$e+$ew_hwidth); $i++) {	# calc mad in window
				next unless numberp($LADCP{ENSEMBLE}[$i]->{CTD_DEPTH});
				$mad[$so + $scan_offset_search_window] +=
					abs($LADCP{ENSEMBLE}[$i]->{REFLR_W} - $CTD{W}[$LADCP{ENSEMBLE}[$i]->{CTD_SCAN}+$so]);
				$nsamp++;					
			} # for $i
			if ($nsamp > 0) {
				$mad[$so + $scan_offset_search_window] /= $nsamp;
			} else {
				$mad[$so + $scan_offset_search_window] = 9e99;
			}
		} # for $so

		my($best_so) = min_i(@mad) - $scan_offset_search_window;		
		&antsOut($e,$best_so,$mad[$best_so + $scan_offset_search_window]);

	}

	&antsOut('EOF'); open(STDOUT,'>&2');

};

1;
