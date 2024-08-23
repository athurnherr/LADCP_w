#======================================================================
#                    T I M E _ S E R I E S . P L 
#                    doc: Sun May 23 16:40:53 2010
#                    dlm: Thu Aug 31 11:21:47 2023
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 35 64 NIL 0 0 72 2 2 4 NIL ofnI
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
#	Oct 12, 2011: - re-worked ref_lr_w()
#				  - stopped depth integration across gaps >= 5s
#	Apr 17, 2013: - improved gap message (added ensemble range)
#	Nov 27, 2017: - BUG: gap heuristic could not deal with P06#001
#				  - BUG: gap heuristic could not deal with P06#025
#	May  1, 2018: - added reflr u and v calculations
#				  - BUG: reflr u and v calcs did not work
#	Apr 21, 2019: - improved surface gap warning message
#	Apr 24, 2021: - output cosmetics
#	Jul 12, 2022: - BUG: negative dt (garbage in PD0 file) was
#						 not handled correctly
#	Aug 24, 2023: - BUG: surface gap treated negative depth wrongly
#				  - added depth info to gap warnings
#				  - improved profile-end detection to allow it anytime
#				    during second half of profile, rather than only
#					during last quartile
#	Aug 31, 2023: - BUG: surface-gap detection did not deal correctly
#						 with consistently -ve in-air velocities
# HISTORY END

# NOTES:
#	- resulting DEPTH field based on integrated w without any sound speed correction
#	- single-ping ensembles assumed, i.e. no percent-good tests applied
#	- specified bin numbers are 1-relative

#----------------------------------------------------------------------
# Reference-Layer Velocities
#----------------------------------------------------------------------

sub ref_lr_w($$$$)										# calc ref-layer vert vels
{
	my($dta,$ens,$rl_b0,$rl_b1) = @_;
	my(@w);

	for (my($bin)=$rl_b0-1; $bin<=$rl_b1-1; $bin++) {
		push(@w,$dta->{ENSEMBLE}[$ens]->{W}[$bin])
			if defined($dta->{ENSEMBLE}[$ens]->{W}[$bin]);
	}
	return unless (@w);
	$dta->{ENSEMBLE}[$ens]->{REFLR_W} = avg(@w);
	$dta->{ENSEMBLE}[$ens]->{REFLR_W_STDDEV} = stddev2($dta->{ENSEMBLE}[$ens]->{REFLR_W},@w);
	$dta->{ENSEMBLE}[$ens]->{REFLR_W_NSAMP} = @w;
}

sub ref_lr_uv($$$$)										# calc ref-layer horiz vels
{
	my($dta,$ens,$rl_b0,$rl_b1) = @_;
	my(@u,@v);

	for (my($bin)=$rl_b0-1; $bin<=$rl_b1-1; $bin++) {
		next unless defined($dta->{ENSEMBLE}[$ens]->{U}[$bin]);
		die unless numbersp($dta->{ENSEMBLE}[$ens]->{U}[$bin],$dta->{ENSEMBLE}[$ens]->{V}[$bin]);
		push(@u,$dta->{ENSEMBLE}[$ens]->{U}[$bin]);
		push(@v,$dta->{ENSEMBLE}[$ens]->{V}[$bin]);
	}
	return unless (@u);
	$dta->{ENSEMBLE}[$ens]->{REFLR_U} = avg(@u); $dta->{ENSEMBLE}[$ens]->{REFLR_V} = avg(@v);
	$dta->{ENSEMBLE}[$ens]->{REFLR_UV_NSAMP} = @u;
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
			$dta->{ENSEMBLE}[$e]->{ELAPSED} =										# time since start
				$dta->{ENSEMBLE}[$e]->{UNIX_TIME} -
				$dta->{ENSEMBLE}[$firstgood]->{UNIX_TIME};
		} else {
			if (defined($dta->{ENSEMBLE}[$e]->{REFLR_W})) {							# start of prof.
				$firstgood = $lastgood = $e;		    
				$dta->{ENSEMBLE}[$e]->{ELAPSED} = 0;
				$dta->{ENSEMBLE}[$e]->{DEPTH} = $depth;
			}
			next;
		}
	
		unless (defined($dta->{ENSEMBLE}[$e]->{REFLR_W})) {							# gap
			$w_gap_time += $dta->{ENSEMBLE}[$e]->{UNIX_TIME} -
						   $dta->{ENSEMBLE}[$e-1]->{UNIX_TIME};
			next;
		}
	
		my($dt) = $dta->{ENSEMBLE}[$e]->{UNIX_TIME} -								# time step since
				  $dta->{ENSEMBLE}[$lastgood]->{UNIX_TIME}; 						# ... last good ens

		if ($dt < 0) {
			warning(1,"negative dt; ensemble #%d ignored\n",
							$dta->{ENSEMBLE}[$e]->{NUMBER});
			next;
		}
		
	
		if ($dt > $max_gap) {
			if (($max_depth>50 && $depth<0.1*$max_depth) &&							# looks like a profile
				(@{$dta->{ENSEMBLE}}-$e < 0.5*@{$dta->{ENSEMBLE}})) {				# in the final quartile of the data
					warning(1,"long gap (%ds) after likely profile (0->%d->%dm) --- finishing at ens#$dta->{ENSEMBLE}[$e]->{NUMBER}\n",
						$dt,$max_depth,$depth);
					last;				
            } elsif (!defined($max_depth) ||					# no +ve velocities measured (only in-air negative)
            		 ($depth == $max_depth) ||					# no -ve velocities measured (only in-air positive)
					 (($depth < 10) && ($max_depth < 10))) {	# just bobbing at the surface
            		 	my($md) = defined($max_depth) ? sprintf('%d',$max_depth) : 'undefined';
						warning(1,"long surface gap (%ds) --- restarting at ens#$dta->{ENSEMBLE}[$e]->{NUMBER} " .
								  "[depth = %d m; max_depth = $md m]\n",$dt,$depth);
						$firstgood = $lastgood = $e;
						undef($atbottom); undef($max_depth);
						$depth = 0;
						$dta->{ENSEMBLE}[$e]->{ELAPSED} = 0;
						$dta->{ENSEMBLE}[$e]->{DEPTH} = $depth;
						$w_gap_time = 0;
						next;
			}
			if ($dta->{ENSEMBLE}[$lastgood]->{ELAPSED} < 200) {
				warning(1,"long gap (%ds) at ensembles #$dta->{ENSEMBLE}[$lastgood]->{NUMBER}-$dta->{ENSEMBLE}[$e]->{NUMBER}, %ds into the profile at %dm depth [max_depth = $max_depth]\n",
					$dt,$dta->{ENSEMBLE}[$lastgood]->{ELAPSED},$depth);
			} else {
				warning(1,"long gap (%ds) at ensembles #$dta->{ENSEMBLE}[$lastgood]->{NUMBER}-$dta->{ENSEMBLE}[$e]->{NUMBER}, %.1fmin into the profile at %dm depth [max_depth = $max_depth]\n",
					$dt,$dta->{ENSEMBLE}[$lastgood]->{ELAPSED}/60,$depth);
			}
		}
	
		$depth += $dta->{ENSEMBLE}[$lastgood]->{REFLR_W} * $dt			# integrate
			if ($dt < 5);
		$dta->{ENSEMBLE}[$e]->{DEPTH} = $depth;
	
		$atbottom = $e, $max_depth = $depth if ($depth > $max_depth); 
		$lastgood = $e;
	}

	for (my($e)=$firstgood; $e<=$lastgood; $e++) {						# calculate u and v
		ref_lr_uv($dta,$e,$rl_b0,$rl_b1);
	}

	return ($firstgood,$lastgood,$atbottom,$w_gap_time);
}

#----------------------------------------------------------------------

1;
