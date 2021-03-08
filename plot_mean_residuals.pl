#======================================================================
#                    P L O T _ M E A N _ R E S I D U A L S . P L 
#                    doc: Tue Jul 28 13:21:09 2015
#                    dlm: Fri May 15 19:06:51 2020
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 122 47 NIL 0 0 72 2 2 4 NIL ofnI
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
#   May 18, 2016: - added version
#	May 15, 2020: - adapted to bin-residuals separate per beam pair
#				  - added orange range
#				  - slightly relaxed green range

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

	GMT_psxy('-W2,coral,8_2:0');
		for (my($bin)=$LADCP_firstBin; $bin<@dc_bres12; $bin++) {			
			next if ($bin+1<$outGrid_firstBin || $bin+1>$outGrid_lastBin);
			next unless ($dc_bres12_nsamp[$bin] >= $dc_bres12_max_nsamp/3);
			printf(GMT "%f %d\n",$dc_avg_bres12[$bin],$bin+1);
        }
	GMT_psxy('-W2,coral,1_1:0');
		for (my($bin)=$LADCP_firstBin; $bin<@dc_bres34; $bin++) {			
			next if ($bin+1<$outGrid_firstBin || $bin+1>$outGrid_lastBin);
			next unless ($dc_bres34_nsamp[$bin] >= $dc_bres34_max_nsamp/3);
			printf(GMT "%f %d\n",$dc_avg_bres34[$bin],$bin+1);
        }
	GMT_psxy('-Ex0.2/2,coral');
		for (my($bin)=$LADCP_firstBin-1; $bin<@dc_bres12; $bin++) {
			printf(GMT "%f %d %f\n",
							$dc_avg_bres12[$bin],
							$bin+1,
							($dc_bres12_nsamp[$bin] > 1) ?
								$dc_sig_bres12[$bin]/sqrt($dc_bres12_nsamp[$bin]-1) : 0);
		}
		for (my($bin)=$LADCP_firstBin-1; $bin<@dc_bres34; $bin++) {
			printf(GMT "%f %d %f\n",
							$dc_avg_bres34[$bin],
							$bin+1,
							($dc_bres34_nsamp[$bin] > 1) ?
								$dc_sig_bres34[$bin]/sqrt($dc_bres34_nsamp[$bin]-1) : 0);
        }
	GMT_psxy('-W2,SeaGreen,8_2:0');
		for (my($bin)=$LADCP_firstBin; $bin<@uc_bres12; $bin++) {			
			next if ($bin+1<$outGrid_firstBin || $bin+1>$outGrid_lastBin);
			next unless ($uc_bres12_nsamp[$bin] >= $uc_bres12_max_nsamp/3);
			printf(GMT "%f %d\n",$uc_avg_bres12[$bin],$bin+1);
        }
	GMT_psxy('-W2,SeaGreen,1_1:0');
		for (my($bin)=$LADCP_firstBin; $bin<@uc_bres34; $bin++) {			
			next if ($bin+1<$outGrid_firstBin || $bin+1>$outGrid_lastBin);
			next unless ($uc_bres34_nsamp[$bin] >= $uc_bres34_max_nsamp/3);
			printf(GMT "%f %d\n",$uc_avg_bres34[$bin],$bin+1);
        }
	GMT_psxy('-Ex0.2/2,SeaGreen');
		for (my($bin)=$LADCP_firstBin-1; $bin<@uc_bres12; $bin++) {
			printf(GMT "%f %d %f\n",
							$uc_avg_bres12[$bin],
							$bin+1,
							($uc_bres12_nsamp[$bin] > 1) ?
								$uc_sig_bres12[$bin]/sqrt($uc_bres12_nsamp[$bin]-1) : 0);
		}
		for (my($bin)=$LADCP_firstBin-1; $bin<@uc_bres34; $bin++) {
			printf(GMT "%f %d %f\n",
							$uc_avg_bres34[$bin],
							$bin+1,
							($uc_bres34_nsamp[$bin] > 1) ?
								$uc_sig_bres34[$bin]/sqrt($uc_bres34_nsamp[$bin]-1) : 0);
        }

	GMT_unitcoords();																	# LABELS
	GMT_pstext('-F+f9,Helvetica,orange+jTR -N -Gwhite');
        print(GMT "0.99 0.01 V$VERSION\n");
        
	GMT_pstext('-F+f14,Helvetica,blue+jBL -N');											# profile id
		print(GMT "0.0 -0.03 $P{out_basename} $P{run_label}\n");

	GMT_pstext('-F+f12,Helvetica-Bold,black+jBL -Gwhite'); 							# rms residuals
		print(GMT "0.1 0.88 beams <1,2>\n");
	GMT_pstext('-F+f12,Helvetica-Bold,black+jBL -Gwhite');
		print(GMT "0.7 0.88 beams <3,4>\n");

	GMT_pstext('-F+f12,Helvetica,coral+jBL');											# rms residuals
		print(GMT "0.01 0.93 dc\n");
	if ($dc_bres12_rms >= 0.005) { 		GMT_pstext('-F+f12,Helvetica,white+jBL -Gred'); }
	elsif ($dc_bres12_rms >= 0.003) { 	GMT_pstext('-F+f12,Helvetica,black+jBL -Gorange'); }
	elsif ($dc_bres12_rms >= 0.0015) { 	GMT_pstext('-F+f12,Helvetica,black+jBL -Gyellow'); }
	else {								GMT_pstext('-F+f12,Helvetica,black+jBL -Ggreen'); }
		printf(GMT "0.10 0.93 %.1f mm/s rms\n",1000*$dc_bres12_rms);

	if ($dc_bres34_rms >= 0.005) { 		GMT_pstext('-F+f12,Helvetica,white+jBL -Gred'); }
	elsif ($dc_bres34_rms >= 0.003) { 	GMT_pstext('-F+f12,Helvetica,black+jBL -Gorange'); }
	elsif ($dc_bres34_rms >= 0.0015) { 	GMT_pstext('-F+f12,Helvetica,black+jBL -Gyellow'); }
	else {								GMT_pstext('-F+f12,Helvetica,black+jBL -Ggreen'); }
		printf(GMT "0.70 0.93 %.1f mm/s rms\n",1000*$dc_bres34_rms);

	GMT_pstext('-F+f12,Helvetica,SeaGreen+jBL');
		print(GMT "0.01 0.98 uc\n");
	if ($uc_bres12_rms >= 0.005) { 		GMT_pstext('-F+f12,Helvetica,white+jBL -Gred'); }
	elsif ($uc_bres12_rms >= 0.003) { 	GMT_pstext('-F+f12,Helvetica,black+jBL -Gorange'); }
	elsif ($uc_bres12_rms >= 0.0015) { 	GMT_pstext('-F+f12,Helvetica,black+jBL -Gyellow'); }
	else {								GMT_pstext('-F+f12,Helvetica,black+jBL -Ggreen'); }
		printf(GMT "0.10 0.98 %.1f mm/s rms\n",1000*$uc_bres12_rms);
	if ($uc_bres34_rms >= 0.005) { 		GMT_pstext('-F+f12,Helvetica,white+jBL -Gred'); }
	elsif ($uc_bres34_rms >= 0.003) { 	GMT_pstext('-F+f12,Helvetica,black+jBL -Gorange'); }
	elsif ($uc_bres34_rms >= 0.0015) { 	GMT_pstext('-F+f12,Helvetica,black+jBL -Gyellow'); }
	else {								GMT_pstext('-F+f12,Helvetica,black+jBL -Ggreen'); }
		printf(GMT "0.70 0.98 %.1f mm/s rms\n",1000*$uc_bres34_rms);

	my($bin_tics) = ($ymax <= 20) ? 'f1a1' : 'f1a2';
	GMT_setR($R);																		# FINISH PLOT
	GMT_end("-Bf0.005a0.02:'Residual Vertical Velocity [m/s]':/$bin_tics:'Bin [#]':WeSn");
}

1; # return true on require
