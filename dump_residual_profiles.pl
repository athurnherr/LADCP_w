#======================================================================
#                    D U M P _ R E S I D U A L _ P R O F I L E S . P L 
#                    doc: Thu Mar 24 07:55:07 2016
#                    dlm: Tue Mar 29 13:43:56 2016
#                    (c) 2016 A.M. Thurnherr
#                    uE-Info: 11 30 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Mar 24, 2016: - created from [plot_residuals.pl]
#	Mar 29, 2016: - cleaned up

sub dump_residual_profiles($)
{
	my($odir) = @_;

	unless (-d $odir) {
		warning(0,"Creating residual-profile output directory ./$odir\n");
		my(@dirs) = split('/',$odir);
		my($path) = '.';
		foreach my $d (@dirs) {
			$path .= "/$d";
			mkdir($path);
		}
    }
	
	return unless ($P{max_depth});

	@antsNewLayout = ('bin','depth','residual');

	for ($ens=$firstGoodEns; $ens<=$lastGoodEns; $ens++) {
		next unless numberp($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH});

		my($of) = sprintf('>%s/%04d.rprof',$odir,$LADCP{ENSEMBLE}[$ens]->{NUMBER});
		open(STDOUT,$of) || error("$of: $!\n");
		undef($antsActiveHeader) unless ($ANTS_TOOLS_AVAILABLE);

		&antsAddParams('ensemble',	$LADCP{ENSEMBLE}[$ens]->{NUMBER},
					   'elapsed',	$LADCP{ENSEMBLE}[$ens]->{ELAPSED},
					   'CTD_depth',	$LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH},
					   'CTD_w',		$CTD{W}[$LADCP{ENSEMBLE}[$ens]->{CTD_SCAN}],
					   'CTD_accel',	$CTD{W_t}[$LADCP{ENSEMBLE}[$ens]->{CTD_SCAN}],
					   'ADCP_tilt',	$LADCP{ENSEMBLE}[$ens]->{TILT});

	  	my(@bindepth) = calc_binDepths($ens);
		for ($bin=$LADCP_firstBin-1; $bin<=$LADCP_lastBin-1; $bin++) {
			next unless ($bin+1>=$outGrid_firstBin && $bin+1<=$outGrid_lastBin);
		  	next unless numberp($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
		  	my($bi) = $bindepth[$bin]/$opt_o;
			my($res) = ($ens < $LADCP_atbottom) ? 
						$LADCP{ENSEMBLE}[$ens]->{SSCORRECTED_OCEAN_W}[$bin] - $DNCAST{MEDIAN_W}[$bi] :
						$LADCP{ENSEMBLE}[$ens]->{SSCORRECTED_OCEAN_W}[$bin] - $UPCAST{MEDIAN_W}[$bi];
			&antsOut($bin,$bindepth[$bin],$res);
	    			 
        }
	    &antsOut('EOF'); open(STDOUT,'>&2');
    }
}

1; # return true on require
