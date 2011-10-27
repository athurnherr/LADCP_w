#!/bin/sh
#======================================================================
#                    P O S T P R O C E S S . S H 
#                    doc: Mon Oct 17 16:42:08 2011
#                    dlm: Fri Oct 21 11:03:29 2011
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 12 0 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Oct 17, 2011: - created
#	Oct 21, 2011: - made user friendly

[ $# -gt 0 ] || {
	echo "Usage: $0 <out-basename> [<run-label> [<data-subdir> [<plot-subdir> [<log-subdir>]]]]" >&2
	exit 1
}

OBN=$1
[ -n "$2" ] && RUN=$2 		|| RUN=default
[ -n "$3" ] && D_SUBDIR=$3 	|| D_SUBDIR=$RUN
[ -n "$4" ] && P_SUBDIR=$4	|| P_SUBDIR=$RUN
[ -n "$5" ] && L_SUBDIR=$5	|| L_SUBDIR=$RUN

chmod +x $D_SUBDIR/$OBN.prof $D_SUBDIR/$OBN.w

tile -s 1.3 -y -90 $P_SUBDIR/${OBN}_prof.eps $P_SUBDIR/${OBN}_w.eps \
				   $P_SUBDIR/${OBN}_BR.eps $P_SUBDIR/${OBN}_residuals.eps \
				   $P_SUBDIR/${OBN}_TL.eps $P_SUBDIR/${OBN}_Sv.eps \
	> $P_SUBDIR/$OBN.ps


