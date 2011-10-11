#======================================================================
#                    T I M E _ S E R I E S . P L 
#                    doc: Sun May 23 16:40:53 2010
#                    dlm: Tue Oct 11 14:08:55 2011
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 17 69 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	May 23, 2010: - created from [perl-tools/RDI_Utils.pl]
#	Oct 20, 2010: - disabled max_gap profile-restarting code
#	Dec 17, 2010: - re-added {DEPTH} field to ensembles
#	Dec 18, 2010: - max gap re-enabled
#	Dec 20, 2010: - cosmetics
#	Jul  2, 2011: - tightened gap-detection code
#	Jul  4, 2011: - added support for $skip_ens
#	Oct 11, 2011: - BUG: {DEPTH} had not been set at start of profile

# NOTES:
#	- resulting DEPTH field based on integrated w without any sound speed correction
#	- single-ping ensembles assumed, i.e. no percent-good tests applied
#	- specified bin numbers are 1-relative

sub ref_lr_w($$$$)										# calc ref-layer vert vels
{
	my($dta,$ens,$rl_b0,$rl_b1) = @_;
	my($i,@n,@bn,@v,@vel,@bv,@w);

	for ($i=$rl_b0-1; $i<=$rl_b1-1; $i++) {
		if (defined($dta->{ENSEMBLE}[$ens]->{W}[$i])) {							# valid w
			$vel[2] += $dta->{ENSEMBLE}[$ens]->{W}[$i]; $n[2]++;
			$vel[3] += $dta->{ENSEMBLE}[$ens]->{ERRVEL}[$i], $n[3]++ if defined($dta->{ENSEMBLE}[$ens]->{ERRVEL}[$i]);
			push(@w,$dta->{ENSEMBLE}[$ens]->{W}[$i]); 							# for stderr test
		}
	}

	my($w) = $n[2] ? $vel[2]/$n[2] : undef;				# w uncertainty
	my($sumsq) = 0;
	for ($i=0; $i<=$#w; $i++) {
		$sumsq += ($w-$w[$i])**2;
	}
	my($stderr) = $n[2]>=2 ? sqrt($sumsq)/($n[2]-1) : undef;

	if (defined($w)) {									# valid w
		$dta->{ENSEMBLE}[$ens]->{REFLR_W} = $w;
		$dta->{ENSEMBLE}[$ens]->{REFLR_W_ERR} = $stderr;
	}
}

#======================================================================
# ($firstgood,$lastgood,$atbottom,$w_gap_time) =
#	calcLADCPts($dta,$skip_ens,$lr_b0,$lr_b1,$min_corr,$max_e,$max_gap);
#======================================================================

sub calcLADCPts($$$$)
{
	my($dta,$skip_ens,$rl_b0,$rl_b1,$max_gap) = @_;
	my($firstgood,$lastgood,$atbottom,$w_gap_time,$max_depth);

	for (my($depth)=0,my($e)=$skip_ens; $e<=$#{$dta->{ENSEMBLE}}; $e++) {

		ref_lr_w($dta,$e,$rl_b0,$rl_b1);
	
		if (defined($firstgood)) {
			$dta->{ENSEMBLE}[$e]->{ELAPSED} =				# time since start
				$dta->{ENSEMBLE}[$e]->{UNIX_TIME} -
				$dta->{ENSEMBLE}[$firstgood]->{UNIX_TIME};
		} else {
			if (defined($dta->{ENSEMBLE}[$e]->{REFLR_W})) {		# start of prof.
				$firstgood = $lastgood = $e;		    
				$dta->{ENSEMBLE}[$e]->{ELAPSED} = 0;
				$dta->{ENSEMBLE}[$e]->{DEPTH} = $depth;
			}
			next;
		}
	
		unless (defined($dta->{ENSEMBLE}[$e]->{REFLR_W})) {				# gap
			$w_gap_time += $dta->{ENSEMBLE}[$e]->{UNIX_TIME} -
						   $dta->{ENSEMBLE}[$e-1]->{UNIX_TIME};
			next;
		}
	
		my($dt) = $dta->{ENSEMBLE}[$e]->{UNIX_TIME} -		# time step since
				  $dta->{ENSEMBLE}[$lastgood]->{UNIX_TIME}; # ... last good ens
	
		if ($dt > $max_gap) {
			if ($max_depth>50 && $depth<0.1*$max_depth) {
				warning(1,"long gap (%ds) near end of profile --- terminated at ensemble #$dta->{ENSEMBLE}[$e]->{NUMBER}\n",$dt);
				last;				
            }
            if ($depth < 10) {
				warning(1,"long gap (%ds) near beginning of profile --- restarted at ensemble #$dta->{ENSEMBLE}[$e]->{NUMBER}\n",$dt);
				$firstgood = $lastgood = $e;
				undef($atbottom); undef($max_depth);
				$depth = 0;
				$dta->{ENSEMBLE}[$e]->{ELAPSED} = 0;
				$dta->{ENSEMBLE}[$e]->{DEPTH} = $depth;
				$w_gap_time = 0;
				next;
			}
			if ($dta->{ENSEMBLE}[$e]->{ELAPSED} < 200) {
				warning(1,"long gap (%ds) at ensemble #$dta->{ENSEMBLE}[$e]->{NUMBER}, %ds into the profile\n",
					$dt,$dta->{ENSEMBLE}[$e]->{ELAPSED});
			} else {
				warning(1,"long gap (%ds) at ensemble #$dta->{ENSEMBLE}[$e]->{NUMBER}, %.1fmin into the profile\n",
					$dt,$dta->{ENSEMBLE}[$e]->{ELAPSED}/60);
			}
		}
	
		$depth += $dta->{ENSEMBLE}[$lastgood]->{REFLR_W} * $dt;			# integrate
		$dta->{ENSEMBLE}[$e]->{DEPTH} = $depth;
	
		$atbottom = $e, $max_depth = $depth if ($depth > $max_depth); 
		$lastgood = $e;
	}
	
	return ($firstgood,$lastgood,$atbottom,$w_gap_time);
}

1;
