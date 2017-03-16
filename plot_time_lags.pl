#======================================================================
#                    P L O T _ T I M E _ L A G S . P L 
#                    doc: Tue Jul 28 13:21:09 2015
#                    dlm: Tue Mar  7 12:04:21 2017
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 35 0 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Jul 29, 2015: - created from [LWplot_TL]
#   Jan 26, 2016: - added return on no data to plot
#	Mar 16, 2016: - adapted to gmt5
#   May 18, 2016: - added version
#	May 24, 2016: - fixed for partial-depth casts
#	mar  7, 2017: - added time lines for -p

require "$ANTS/libGMT.pl";

sub plot_time_lags($)
{
	my($pfn) = @_;

	return unless ($P{'elapsed.min'});

	my($xmin) = $P{'elapsed.min'}/60;
	my($xmax) = $P{'elapsed.max'}/60;
	my($ymin) = -24;
	my($ymax) =  24;

	my($R) = "-R$xmin/$xmax/$ymin/$ymax";
	GMT_begin($pfn,'-JX10',$R,'-P');

	GMT_psxy('-W1,grey30');											# time lines
	for (my($x)=round($xmin,10); $x<=$xmax; $x+=10) {
		printf(GMT "%f $ymin\n%f $ymax\n>\n",$x,$x);
	}

	GMT_psxy('-W8,yellow');											# offset runs
	for (my($i)=0; $i<@bmo_buf; $i++) {
		printf(GMT ">\n%f %f\n%f %f\n",
			$fg_buf[$i]/60-0.5,$bmo_buf[$i],
			$lg_buf[$i]/60+0.5,$bmo_buf[$i]);
	}

	GMT_psxy('-Sc0.1 -Gcoral');										# individual offsets
		for (my($wi)=0; $wi<@elapsed_buf; $wi++) {
			last unless ($elapsed_buf[$wi]<$LADCP{ENSEMBLE}[$LADCP_atbottom]->{ELAPSED});
			printf(GMT "%f %f\n",$elapsed_buf[$wi]/60,$so_buf[$wi]);
        }
	GMT_psxy('-Sc0.1 -GSeaGreen');
		for (my($wi)=0; $wi<@elapsed_buf; $wi++) {
			next if ($elapsed_buf[$wi]<$LADCP{ENSEMBLE}[$LADCP_atbottom]->{ELAPSED});
			printf(GMT "%f %f\n",$elapsed_buf[$wi]/60,$so_buf[$wi]);
        }

	GMT_unitcoords();												# labels
	GMT_pstext('-F+f9,Helvetica,orange+jTR -N -Gwhite');
        print(GMT "0.99 0.99 V$VERSION\n");
	GMT_pstext('-F+f14,Helvetica,blue+jTL -N');
		print(GMT "0.01 1.06 $P{out_basename} $P{run_label}\n");

	GMT_setR($R);
	my($elapsed_tics) = ($xmax-$xmin < 45) ? 'f1a5' : 'f1a30';
	GMT_end("-B$elapsed_tics:'Elapsed Time [min]':/f1a5:'Best Offset [CTD records]':WeSn");	# FINISH PLOT
}

1; # return true on require
