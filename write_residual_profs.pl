#======================================================================
#                    W R I T E _ R E S I D U A L _ P R O F S . P L 
#                    doc: Fri May 15 20:22:54 2020
#                    dlm: Fri May 15 20:56:06 2020
#                    (c) 2020 A.M. Thurnherr
#                    uE-Info: 21 53 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#   May 25, 2020: - created from [plot_residual_profs.pl]

sub write_residual_profs($)
{
	my($ofn) = @_;

	@antsNewLayout = ('depth','dc_residual12','dc_residual34','uc_residual12','uc_residual34');

	open(STDOUT,">$ofn") || error("$ofn: $!\n");
	undef($antsActiveHeader) unless ($ANTS_TOOLS_AVAILABLE);

	for (my($bi)=0; $bi<=$#{$DNCAST{MEAN_RESIDUAL12}}; $bi++) {
		my(@out);
		push(@out,($bi+0.5) * $opt_o);									# depth
		push(@out,(numberp($DNCAST{MEAN_RESIDUAL12}[$bi]) && $DNCAST{N_SAMP}[$bi]>=$minsamp) ?
				  	$DNCAST{MEAN_RESIDUAL12}[$bi] : nan);
		push(@out,(numberp($DNCAST{MEAN_RESIDUAL34}[$bi]) && $DNCAST{N_SAMP}[$bi]>=$minsamp) ?
				  	$DNCAST{MEAN_RESIDUAL34}[$bi] : nan);
		push(@out,(numberp($UPCAST{MEAN_RESIDUAL12}[$bi]) && $UPCAST{N_SAMP}[$bi]>=$minsamp) ?
				  	$UPCAST{MEAN_RESIDUAL12}[$bi] : nan);
		push(@out,(numberp($UPCAST{MEAN_RESIDUAL34}[$bi]) && $UPCAST{N_SAMP}[$bi]>=$minsamp) ?
				  	$UPCAST{MEAN_RESIDUAL34}[$bi] : nan);
		&antsOut(@out);
	}
    &antsOut('EOF'); open(STDOUT,'>&2');
}

1; # return true on require
