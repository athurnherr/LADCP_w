#!/bin/sh
#======================================================================
#                    P O S T P R O C E S S . S H 
#                    doc: Mon Oct 17 16:42:08 2011
#                    dlm: Wed Nov  5 10:39:37 2014
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 14 62 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Oct 17, 2011: - created
#	Oct 21, 2011: - made user friendly
#	Oct 11, 2012: - added support for TL output
#	Nov  5, 2014: - changed extension of w samples output file

[ $# -gt 0 ] || {
	echo "Usage: $0 <out-basename> [<run-label> [<data-subdir> [<plot-subdir> [<log-subdir>]]]]" >&2
	exit 1
}

OBN=$1
[ -n "$2" ] && RUN=$2 		|| RUN=default
[ -n "$3" ] && D_SUBDIR=$3 	|| D_SUBDIR=$RUN
[ -n "$4" ] && P_SUBDIR=$4	|| P_SUBDIR=$RUN
[ -n "$5" ] && L_SUBDIR=$5	|| L_SUBDIR=$RUN

chmod +x $D_SUBDIR/$OBN.prof $D_SUBDIR/$OBN.samp $D_SUBDIR/$OBN.TL

tile -s 1.3 -y -90 $P_SUBDIR/${OBN}_prof.eps $P_SUBDIR/${OBN}_w.eps \
				   $P_SUBDIR/${OBN}_BR.eps $P_SUBDIR/${OBN}_residuals.eps \
				   $P_SUBDIR/${OBN}_TL.eps $P_SUBDIR/${OBN}_Sv.eps \
	> $P_SUBDIR/$OBN.ps


