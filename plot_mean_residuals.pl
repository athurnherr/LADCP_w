#======================================================================
#                    P L O T _ M E A N _ R E S I D U A L S . P L 
#                    doc: Tue Jul 28 13:21:09 2015
#                    dlm: Thu Jul 30 12:38:12 2015
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 39 36 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Jul 28, 2015: - created from [LWplot_BR]
#	Jul 29, 2015: - finished
#	Jul 30, 2015: - added bin_tics
#				  - added outGrid_* support

require "$ANTS/libGMT.pl";

sub plot_mean_residuals($)
{
	my($pfn) = @_;

	my($xmin) = -0.05;
	my($xmax) =  0.05;
	my($ymin) =  0.5;
	my($ymax) = $P{BR_max_bin} + 0.5;

	my($R) = "-R$xmin/$xmax/$ymin/$ymax";
	GMT_begin($pfn,'-JX10/-10',$R,'-P');

	if ($outGrid_firstBin>$LADCP_firstBin || $outGrid_lastBin<$LADCP_lastBin) {
		GMT_psxy('-G200 -M -L');
		printf(GMT ">\n%f %f\n%f %f\n%f %f\n%f %f\n",
			$xmin,$LADCP_firstBin-0.5,
			$xmax,$LADCP_firstBin-0.5,
			$xmax,$outGrid_firstBin-0.5,
			$xmin,$outGrid_firstBin-0.5)
				if ($outGrid_firstBin>$LADCP_firstBin);
		printf(GMT ">\n%f %f\n%f %f\n%f %f\n%f %f\n",
			$xmin,$LADCP_lastBin+0.5,
			$xmax,$LADCP_lastBin+0.5,
			$xmax,$outGrid_lastBin+0.5,
			$xmin,$outGrid_lastBin+0.5)
				if ($outGrid_lastBin<$LADCP_lastBin);
	}

	GMT_psxy('-W1');
	printf(GMT "0 $ymin\n0 $ymax\n");

	GMT_psxy('-Mn -W4/coral');
		for (my($bin)=0; $bin<scalar(@dc_bres); $bin++) {
			printf(GMT "%f %d\n",$dc_avg_bres[$bin],$bin+1);
        }
	GMT_psxy('-Mn -Ex0.2/4/coral');
		for (my($bin)=0; $bin<scalar(@dc_bres); $bin++) {
			printf(GMT "%f %d %f\n",
							$dc_avg_bres[$bin],
							$bin+1,
							(scalar(@{$dc_bres[$bin]}) > 1) ?
								$dc_sig_bres[$bin]/sqrt(scalar(@{$dc_bres[$bin]})-1) : 0);
        }
	GMT_psxy('-Mn -W4/SeaGreen');
		for (my($bin)=0; $bin<scalar(@uc_bres); $bin++) {
			printf(GMT "%f %d\n",$uc_avg_bres[$bin],$bin+1);
        }
	GMT_psxy('-Mn -Ex0.2/4/SeaGreen');
		for (my($bin)=0; $bin<scalar(@uc_bres); $bin++) {
			printf(GMT "%f %d %f\n",
							$uc_avg_bres[$bin],
							$bin+1,
							(scalar(@{$uc_bres[$bin]}) > 1) ?
								$uc_sig_bres[$bin]/sqrt(scalar(@{$uc_bres[$bin]})-1) : 0);
        }

	GMT_unitcoords();																	# LABELS
	GMT_pstext(-Gblue);
		print(GMT "0.02 0.98 12 0 0 BL $P{out_basename} $P{run_label}\n");

	my($bin_tics) = ($ymax <= 20) ? 'f1a1' : 'f1a2';
	GMT_setR($R);																		# FINISH PLOT
	GMT_end("-Bf0.005a0.02:'Residual Vertical Velocity [m/s]':/$bin_tics:'Bin [#]':WeSn");
}

1; # return true on require
