#======================================================================
#                    P L O T _ W S A M P . P L 
#                    doc: Tue Jul 28 13:21:09 2015
#                    dlm: Tue Oct 29 13:15:41 2019
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 17 0 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Jul 28, 2015: - created from [LWplot_w]
#	Jul 30, 2015: - added support for outGrid_*
#	Sep 21, 2015: - BUG: function was still called plot_w()
#	Oct 12, 2015: - move main label outside plot area
#   Jan 26, 2016: - added return on no data to plot
#	Mar 16, 2016: - adapted to gmt5
#   May 18, 2016: - added version
#                 - expunged $realLastGoodEns
#   May 24, 2016: - calc_binDepths() -> binDepths()
#				  - fixed for partial-depth profiles
#	Oct 29, 2019: - updated psscale -B to gmt5 syntax

require "$ANTS/libGMT.pl";

sub plot_wsamp($)
{
	my($pfn) = @_;

	return unless ($P{max_depth});

	my($xmin) = $P{min_ens}-0.5;
	my($xmax) = $P{max_ens}+0.5;
	my($ymin) = round(antsParam('min_depth')-25,50);
	my($ymax) = ($P{water_depth} > 0) ?
				round($P{water_depth}+25,50) :
				round($P{max_depth}+$P{ADCP_bin_length}+25,50);


	my($ens_width) = 10 / ($P{max_ens} - $P{min_ens} + 1);
	my($bin_length) = 10 * $P{ADCP_bin_length} / 
						($P{max_depth}-$P{min_depth}+$P{ADCP_bin_length});

	my($R) = "-R$xmin/$xmax/$ymin/$ymax";
	GMT_begin($pfn,'-JX10/-10',$R,'-P');

	my($C) = "-C$WCALC/w.cpt";
	GMT_psxy("$C -Sr");
		for ($ens=$firstGoodEns; $ens<=$lastGoodEns; $ens++) {
		  next unless numberp($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH});
		  my(@bindepth) = binDepths($ens);
		  for ($bin=$LADCP_firstBin-1; $bin<=$LADCP_lastBin-1; $bin++) {
			  next unless ($bin+1>=$outGrid_firstBin && $bin+1<=$outGrid_lastBin);
			  next unless numberp($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
			  my($bi) = $bindepth[$bin]/$opt_o;
			  printf(GMT "%d %f %f $ens_width $bin_length\n",
				$LADCP{ENSEMBLE}[$ens]->{NUMBER},
				$bindepth[$bin],
				$LADCP{ENSEMBLE}[$ens]->{SSCORRECTED_OCEAN_W}[$bin]);
          }
        }

	if ($P{water_depth} > 0) {															# SEABED
		GMT_psxy('-G204/153/102');
		print(GMT "$xmin $ymax\n$xmax $ymax\n$xmax $P{water_depth}\n $xmin $P{water_depth}\n");
	}

	GMT_unitcoords();																	# LABELS
	GMT_pstext('-F+f9,Helvetica,orange+jTR -N -Gwhite');
        print(GMT "0.99 0.01 V$VERSION\n");

	GMT_pstext('-F+f14,Helvetica,blue+jTL -N');
		print(GMT "0.01 -0.06 $P{out_basename} [$P{run_label}]\n");

	my($depth_tics) = ($ymax-$ymin < 1000) ? 'f10a100' : 'f100a500';					# AXES
	my($ens_tics) =   ($xmax-$xmin < 4000) ? 'f50a500' : 'f500a2000';
	GMT_setR($R);
	GMT_psbasemap("-B$ens_tics:'Ensemble [#]':/$depth_tics:'Depth [m]':WeSn");
		 
	GMT_setAnnotFontSize(7);															# SCALE BAR
#	GMT_psscale("-Dn0.85/0.1+w3/0.4+e $C -B/:w\@-ocean\@-:");
	GMT_psscale("-Dn0.85/0.1+w3/0.4+e $C -By+lw\@-ocean\@-");

	GMT_end();																			# FINISH PLOT
}

1; # return true on require
