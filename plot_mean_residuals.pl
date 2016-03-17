#======================================================================
#                    P L O T _ M E A N _ R E S I D U A L S . P L 
#                    doc: Tue Jul 28 13:21:09 2015
#                    dlm: Wed Mar 16 15:55:14 2016
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 96 29 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Jul 28, 2015: - created from [LWplot_BR]
#	Jul 29, 2015: - finished
#	Jul 30, 2015: - added bin_tics
#				  - added outGrid_* support
#	Jan 22, 2015: - many changes
#				  - added quality assessment label
#	Jan 25, 2016: - added return on no data
#	Mar 16, 2016: - adapted to gmt5

require "$ANTS/libGMT.pl";

sub plot_mean_residuals($)
{
	my($pfn) = @_;

	return unless ($P{BR_max_bin});

	my($xmin) = -0.05;
	my($xmax) =  0.05;
	my($ymin) =  0.5;
	my($ymax) = $P{BR_max_bin} + 0.5;

	my($R) = "-R$xmin/$xmax/$ymin/$ymax";
	GMT_begin($pfn,'-JX10/-10',$R,'-P');

	if ($outGrid_firstBin>$LADCP_firstBin || $outGrid_lastBin<$LADCP_lastBin) {		# mark used bins
		GMT_psxy('-G200 -L');
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

	GMT_psxy('-W1');																# plot zero line
	printf(GMT "0 $ymin\n0 $ymax\n");

	GMT_psxy('-W2,coral');
		for (my($bin)=$LADCP_firstBin; $bin<@dc_bres; $bin++) {						# SKIP FIRST BIN
			next if ($bin+1<$outGrid_firstBin || $bin+1>$outGrid_lastBin);
			next unless ($dc_bres_nsamp[$bin] >= $dc_bres_max_nsamp/3);
			printf(GMT "%f %d\n",$dc_avg_bres[$bin],$bin+1);
        }
	GMT_psxy('-Ex0.2/2,coral');
		for (my($bin)=$LADCP_firstBin-1; $bin<@dc_bres; $bin++) {
			printf(GMT "%f %d %f\n",
							$dc_avg_bres[$bin],
							$bin+1,
							($dc_bres_nsamp[$bin] > 1) ?
								$dc_sig_bres[$bin]/sqrt($dc_bres_nsamp[$bin]-1) : 0);
        }
	GMT_psxy('-W2,SeaGreen');
		for (my($bin)=$LADCP_firstBin; $bin<@uc_bres; $bin++) {						# SKIP FIRST BIN
			next if ($bin+1<$outGrid_firstBin || $bin+1>$outGrid_lastBin);
			next unless ($uc_bres_nsamp[$bin] >= $uc_bres_max_nsamp/3);
			printf(GMT "%f %d\n",$uc_avg_bres[$bin],$bin+1);
        }
	GMT_psxy('-Ex0.2/2,SeaGreen');
		for (my($bin)=$LADCP_firstBin-1; $bin<@uc_bres; $bin++) {
			printf(GMT "%f %d %f\n",
							$uc_avg_bres[$bin],
							$bin+1,
							($uc_bres_nsamp[$bin] > 1) ?
								$uc_sig_bres[$bin]/sqrt($uc_bres_nsamp[$bin]-1) : 0);
        }

	GMT_unitcoords();																	# LABELS

	GMT_pstext('-F+f14,Helvetica,blue+jBL -N');											# profile id
		print(GMT "0.0 -0.03 $P{out_basename} $P{run_label}\n");

	GMT_pstext('-F+f12,Helvetica,coral+jBL');											# rms residuals
		print(GMT "0.01 0.93 dc\n");
	if ($dc_bres_rms >= 0.005) { 		GMT_pstext('-F+f12,Helvetica,white+jBL -Gred'); }
	elsif ($dc_bres_rms >= 0.001) { 	GMT_pstext('-F+f12,Helvetica,black+jBL -Gyellow'); }
	else {								GMT_pstext('-F+f12,Helvetica,black+jBL -Ggreen'); }
		printf(GMT "0.10 0.93 %.1f mm/s rms\n",1000*$dc_bres_rms);

	GMT_pstext('-F+f12,Helvetica,SeaGreen+jBL');
		print(GMT "0.01 0.98 uc\n");
	if ($uc_bres_rms >= 0.005) { 		GMT_pstext('-F+f12,Helvetica,white+jBL -Gred'); }
	elsif ($uc_bres_rms >= 0.001) { 	GMT_pstext('-F+f12,Helvetica,black+jBL -Gyellow'); }
	else {								GMT_pstext('-F+f12,Helvetica,black+jBL -Ggreen'); }
		printf(GMT "0.10 0.98 %.1f mm/s rms\n",1000*$uc_bres_rms);

	my($bin_tics) = ($ymax <= 20) ? 'f1a1' : 'f1a2';
	GMT_setR($R);																		# FINISH PLOT
	GMT_end("-Bf0.005a0.02:'Residual Vertical Velocity [m/s]':/$bin_tics:'Bin [#]':WeSn");
}

1; # return true on require
