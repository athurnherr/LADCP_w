#======================================================================
#                    P O S T _ M E R G E _ D W D Z _ F I L T . P L 
#                    doc: Thu Mar 26 16:02:09 2015
#                    dlm: Thu Mar 26 17:11:24 2015
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 10 25 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# Try to improve 2010 GoM data set by filtering ensembles with large dwdz
#	- no apparent benefit

# HISTORY:
#	Mar 26, 2015: - created

$post_merge_hook = sub {							# arguments: firstGoodEns, lastGoodEns
	my($fe,$le) = @_;

	progress("\tediting ensembles with large dw/dz...\n");
	my($nedt) = 0;

	@antsNewLayout = ('ensemble','dwdz');
	open(STDOUT,">$data_subdir/$out_basename.dwdz")
		|| croak("$data_subdir/$out_basename.dwdz: $!\n");

	for (my($ens)=$fe; $ens<=$le; $ens++) {
		next unless numberp($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH});					# skip non-valid

		my($w1,$w2,$w3,$w4);
		my($b1,$b2,$b3,$b4);
		for (my($bin)=$LADCP_firstBin-1; $bin<=$LADCP_lastBin-1; $bin++) {
			next unless numberp($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
			if (defined($w1) && defined($w2)) {										# find last two
				$w3 = $w4; $b3 = $b4;
				$w4 = $LADCP{ENSEMBLE}[$ens]->{W}[$bin]; $b4 = $bin;
			} else {																# find first two
				if (defined($w1)) { $w2 = $LADCP{ENSEMBLE}[$ens]->{W}[$bin]; $b2 = $bin; }
				else 			  { $w1 = $LADCP{ENSEMBLE}[$ens]->{W}[$bin]; $b1 = $bin; }
			}
		}

		$nedt++,undef($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH}),next						# require at least 4 samples
			unless defined($w1) && defined($w2) && defined($w3) && defined($w4);

		my($dwdz) = (($w1+$w2)/2 - ($w3+$w4)/2) / (($b1+$b2)/2 - ($b3+$b4)/2)*$LADCP{BIN_LENGTH};
		&antsOut($ens,$dwdz);
		if (abs($dwdz) > 0.05) {		# TWEAKABLE PARAMETER
			undef($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH});
			$nedt++,
			next;
		}
			
	}
				
	&antsOut('EOF'); open(STDOUT,'>&2');
	progress("\t\t$nedt ensembles removed (%d%% of total)...\n",100*$nedt/($le-$fe+1));
};

1;
