#======================================================================
#                    P L O T _ B A C K S C A T T E R . P L 
#                    doc: Tue Jul 28 13:21:09 2015
#                    dlm: Tue Jan 26 20:46:11 2016
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 19 31 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Jul 28, 2015: - created from [LWplot_Sv]
#	Jan 26, 2016: - added return on no data to plot

require "$ANTS/libGMT.pl";

sub plot_backscatter($)
{
	my($pfn) = @_;

	return unless ($P{max_depth});

	my($xmin) = $P{min_ens}-0.5;
	my($xmax) = $P{max_ens}+0.5;
	my($ymin) = 0;
	my($ymax) = ($P{water_depth} > 0) ?
				round($P{water_depth} + 25) :
				round($P{max_depth} + $P{ADCP_bin_length});

	my($ens_width) = 10 / ($P{max_ens} - $P{min_ens} + 1);
	my($bin_length) = 10 * $P{ADCP_bin_length} / 
						($P{max_depth}-$P{min_depth}+$P{ADCP_bin_length});

	my($R) = "-R$xmin/$xmax/$ymin/$ymax";
	GMT_begin($pfn,'-JX10/-10',$R,'-P');

	my($C) = "-C$WCALC/Sv.cpt";
	GMT_psxy("$C -Sr");
		for ($ens=$firstGoodEns; $ens<=$realLastGoodEns; $ens++) {
		  next unless numberp($LADCP{ENSEMBLE}[$ens]->{CTD_DEPTH});
		  my(@bindepth) = calc_binDepths($ens);
		  for ($bin=$LADCP_firstBin-1; $bin<=$LADCP_lastBin-1; $bin++) {
			  next unless numberp($LADCP{ENSEMBLE}[$ens]->{W}[$bin]);
			  my($bi) = $bindepth[$bin]/$opt_o;
			  printf(GMT "%d %f %f $ens_width $bin_length\n",
				$LADCP{ENSEMBLE}[$ens]->{NUMBER},
				$bindepth[$bin],
				$LADCP{ENSEMBLE}[$ens]->{SV}[$bin]);
          }
        }

	if ($P{water_depth} > 0) {															# SEABED
		GMT_psxy('-G204/153/102');
		print(GMT "$xmin $ymax\n$xmax $ymax\n$xmax $P{water_depth}\n $xmin $P{water_depth}\n");
	}

	GMT_unitcoords();																	# LABELS
	GMT_pstext(-Gblue);
		print(GMT "0.02 0.98 12 0 0 BL $P{out_basename} $P{run_label}\n");

	my($depth_tics) = ($ymax < 1000 ) ? 'f10a100' : 'f100a500';							# AXES
	my($ens_tics) =   ($ymax < 1000 ) ? 'f50a500' : 'f500a2000';
	GMT_setR($R);
	GMT_psbasemap("-B$ens_tics:'Ensemble [#]':/$depth_tics:'Depth [m]':WeSn");
		 
	GMT_setAnnotFontSize(7);															# SCALE BAR
	GMT_psscale("-E -D8/2/3/0.4 $C -B/:S\@-v\@-:");

	GMT_end();																			# FINISH PLOT
}

1; # return true on require
