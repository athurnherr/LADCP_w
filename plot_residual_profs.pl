#======================================================================
#                    P L O T _ R E S I D U A L _ P R O F S . P L 
#                    doc: Wed May 18 18:43:33 2016
#                    dlm: Tue May 24 22:02:28 2016
#                    (c) 2016 A.M. Thurnherr
#                    uE-Info: 77 0 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#   May 18, 2016: - created from [plot_mean_residuals.pl]
#	May 24, 2016: - improved

require "$ANTS/libGMT.pl";

sub plotDC($$)
{
	my($f,$minsamp) = @_;
	my($sum,$n);
	for (my($bi)=0; $bi<=$#{$DNCAST{$f}}; $bi++) {
		if (numberp($DNCAST{$f}[$bi]) && $DNCAST{N_SAMP}[$bi]>=$minsamp) {
			$sum += $DNCAST{$f}[$bi]**2; $n++;
			printf(GMT "%g %g\n",$DNCAST{$f}[$bi],($bi+0.5)*$opt_o);
		} else {
			print(GMT "nan nan\n");
		}
	}
	return $n ? sqrt($sum/$n) : nan;
}

sub plotUC($$)																		# from [plot_wprofs.pl]
{
	my($f,$minsamp) = @_;
	my($sum,$n);
	for (my($bi)=0; $bi<=$#{$UPCAST{$f}}; $bi++) {
		if (numberp($UPCAST{$f}[$bi]) && $UPCAST{N_SAMP}[$bi]>=$minsamp) {
			$sum += $UPCAST{$f}[$bi]**2; $n++;
			printf(GMT "%g %g\n",$UPCAST{$f}[$bi],($bi+0.5)*$opt_o);
		} else {
			print(GMT "nan nan\n");
		}
	}
	return $n ? sqrt($sum/$n) : nan;
}

sub plot_residual_profs($)
{
	my($pfn) = @_;

	my($yellow_light) = 0.004;
	my($red_light)	  = 0.01;

	my($xmin) = -0.05;
	my($xmax) =  0.05;
	my($ymin) = round(antsParam('min_depth')-25,50);
	my($ymax) = ($P{water_depth} > 0) ?
				round($P{water_depth}+25,50) :
				round($P{max_depth}+$P{ADCP_bin_length}+25,50);
	                                              
	my($R) = "-R$xmin/$xmax/$ymin/$ymax";
	my($depth_tics) = ($ymax < 1000 ) ? 'f10a100g100' : 'f100a500g500';
	GMT_begin($pfn,'-JX10/-10',$R,"-P -Bf0.005a0.02g0.01:'Residual Vertical Velocity [m/s]':/$depth_tics:'Depth [m]':WeSn");

	GMT_psxy('-W2,CornflowerBlue');													# zero line
		printf(GMT "0 $ymin\n0 $ymax\n");

	GMT_psxy('-W1,coral,8_2:0'); my($r12DC) = plotDC('MEAN_RESIDUAL12',$opt_k);		# dc residual12 (pitch plane)
	GMT_psxy('-W1,coral,1_1:0'); my($r34DC) = plotDC('MEAN_RESIDUAL34',$opt_k);		# dc residual34 (roll plane)
	GMT_psxy('-W1,SeaGreen,8_2:0'); my($r12UC) = plotUC('MEAN_RESIDUAL12',$opt_k);	# uc residual12 (pitch plane)
	GMT_psxy('-W1,SeaGreen,1_1:0'); my($r34UC) = plotUC('MEAN_RESIDUAL34',$opt_k);	# uc residual34 (roll plane)

	GMT_unitcoords();																# LABELS
	GMT_pstext('-F+f9,Helvetica,orange+jTR -N -Gwhite');
        print(GMT "0.99 0.01 V$VERSION\n");
	GMT_pstext('-F+f14,Helvetica,blue+jBL -N');										# profile id
		print(GMT "0.0 -0.03 $P{out_basename} $P{run_label}\n");

	GMT_pstext('-F+f12,Helvetica-Bold,black+jBL -Gwhite'); 							# rms residuals
		print(GMT "0.01 0.89 beams <1,2>\n");
	if ($r12DC >= $red_light) { 		GMT_pstext('-F+f12,Helvetica-Bold,coral+jBL -Gred'); }	
	elsif ($r12DC >= $yellow_light) { 	GMT_pstext('-F+f12,Helvetica-Bold,coral+jBL -Gyellow'); }
	else {								GMT_pstext('-F+f12,Helvetica-Bold,coral+jBL -Gwhite'); }
		printf(GMT "0.01 0.935 %.1f mm/s rms\n",1000*$r12DC);
	if ($r12UC >= $red_light) { 		GMT_pstext('-F+f12,Helvetica-Bold,SeaGreen+jBL -Gred'); }
	elsif ($r12UC >= $yellow_light) { 	GMT_pstext('-F+f12,Helvetica-Bold,SeaGreen+jBL -Gyellow'); }
	else {								GMT_pstext('-F+f12,Helvetica-Bold,SeaGreen+jBL -Gwhite'); }
		printf(GMT "0.01 0.98 %.1f mm/s rms\n",1000*$r12UC);
	GMT_pstext('-F+f12,Helvetica-Bold,black+jBR -Gwhite');
		print(GMT "0.99 0.89 beams <3,4>\n");
	if ($r34DC >= $red_light) { 		GMT_pstext('-F+f12,Helvetica-Bold,coral+jBR -Gred'); }
	elsif ($r34DC >= $yellow_light) { 	GMT_pstext('-F+f12,Helvetica-Bold,coral+jBR -Gyellow'); }
	else {								GMT_pstext('-F+f12,Helvetica-Bold,coral+jBR -Gwhite'); }
		printf(GMT "0.99 0.935 %.1f mm/s rms\n",1000*$r34DC);
	if ($r34UC >= $red_light) { 		GMT_pstext('-F+f12,Helvetica-Bold,SeaGreen+jBR -Gred'); }
	elsif ($r34UC >= $yellow_light) { 	GMT_pstext('-F+f12,Helvetica-Bold,SeaGreen+jBR -Gyellow'); }
	else {								GMT_pstext('-F+f12,Helvetica-Bold,SeaGreen+jBR -Gwhite'); }
		printf(GMT "0.99 0.98 %.1f mm/s rms\n",1000*$r34UC);

	GMT_end();
}

1; # return true on require
