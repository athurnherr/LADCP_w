#======================================================================
#                    S M A L L _ T I L T _ C O R R E C T I O N . P L 
#                    doc: Thu Mar 21 16:10:06 2024
#                    dlm: Thu Mar 21 16:30:34 2024
#                    (c) 2024 A.M. Thurnherr
#                    uE-Info: 16 70 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Mar 21, 2024: - created

# NOTES:
#	- applies a small-tilt correction derived from the 2019 EPR test mooring
#	  data
#	- tried out with a couple of profiles from 2016 Maren Walters Arctic data
#	=> no visual effect but statistics get slightly worse => don't use

#----------------------------------------------------------------------

$post_merge_hook = sub {							# arguments: firstGoodEns, lastGoodEns
	my($fe,$le) = @_;

	progress("\tsmall-tilt correction...\n");

	for (my($e)=$fe; $e<=$te; $e++) {
		next unless numberp($LADCP{ENSEMBLE}[$e]->{CTD_DEPTH});
		die unless numberp($LADCP{ENSEMBLE}[$e]->{TILT});
		my($stc) = ($LADCP{ENSEMBLE}[$e]->{TILT} < 1.75)
				 ? 0.001 * $LADCP{ENSEMBLE}[$e]->{TILT}**2
				 : 0.003;
		for (my($bin)=0; $bin<$LADCP{N_BINS}; $bin++) {
			next unless numberp($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
			$LADCP{ENSEMBLE}[$ens]->{W}[$bin] + $stc;
		}
	}
};

1;
