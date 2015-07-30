#======================================================================
#                    P L O T _ T I M E _ L A G S . P L 
#                    doc: Tue Jul 28 13:21:09 2015
#                    dlm: Wed Jul 29 14:47:57 2015
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 39 30 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Jul 29, 2015: - created from [LWplot_TL]

require "$ANTS/libGMT.pl";

sub plot_time_lags($)
{
	my($pfn) = @_;

	my($xmin) = $P{'elapsed.min'}/60;
	my($xmax) = $P{'elapsed.max'}/60;
	my($ymin) = -24;
	my($ymax) =  24;

	my($R) = "-R$xmin/$xmax/$ymin/$ymax";
	GMT_begin($pfn,'-JX10',$R,'-P');

	GMT_psxy('-Sc0.1 -Gcoral');
		for (my($wi)=0; $wi<@elapsed_buf; $wi++) {
			last unless ($elapsed_buf[$wi]<$LADCP{ENSEMBLE}[$LADCP_atbottom]->{ELAPSED});
			printf(GMT "%f %f\n",$elapsed_buf[$wi]/60,$so_buf[$wi]);
        }
	GMT_psxy('-Sc0.1 -GSeaGreen');
		for (my($wi)=0; $wi<@elapsed_buf; $wi++) {
			next if ($elapsed_buf[$wi]<$LADCP{ENSEMBLE}[$LADCP_atbottom]->{ELAPSED});
			printf(GMT "%f %f\n",$elapsed_buf[$wi]/60,$so_buf[$wi]);
        }

	my($fel) = $P{min_elapsed};									# from-elapsed limit
	GMT_psxy('-W4/grey20 -M');
	for (my($i)=0; $i<@bmo_buf; $i++) {
		printf(GMT ">\n%f %f\n%f %f\n",
			$fel/60,		 $bmo_buf[$i],
			$te_buf[$i]/60+1,$bmo_buf[$i]);
			$fel = $te_buf[$i];
	}

	GMT_unitcoords();																	# LABELS
	GMT_pstext(-Gblue);
		print(GMT "0.02 0.02 12 0 0 BL $P{out_basename} $P{run_label}\n");

	GMT_setR($R);
	GMT_end('-Bf1a30:"Elapsed Time [min]":/f1a5:"Best Offset [scans]":WeSn');			# FINISH PLOT
}

1; # return true on require
