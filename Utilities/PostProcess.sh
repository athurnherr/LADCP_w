#!/bin/sh
#======================================================================
#                    P O S T P R O C E S S . S H 
#                    doc: Mon Oct 17 16:42:08 2011
#                    dlm: Tue Dec 22 11:13:51 2015
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 15 69 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Oct 17, 2011: - created
#	Oct 21, 2011: - made user friendly
#	Oct 11, 2012: - added support for TL output
#	Nov  5, 2014: - changed extension of w samples output file
#	Dec 22, 2015: - modified plot filenames for consistency with V1.1

[ $# -gt 0 ] || {
	echo "Usage: $0 <out-basename> [<run-label> [<data-subdir> [<plot-subdir> [<log-subdir>]]]]" >&2
	exit 1
}

OBN=$1
[ -n "$2" ] && RUN=$2 		|| RUN=default
[ -n "$3" ] && D_SUBDIR=$3 	|| D_SUBDIR=$RUN
[ -n "$4" ] && P_SUBDIR=$4	|| P_SUBDIR=$RUN
[ -n "$5" ] && L_SUBDIR=$5	|| L_SUBDIR=$RUN

tile -s 1.3 -y -90 $P_SUBDIR/${OBN}_wprof.ps $P_SUBDIR/${OBN}_wsamp.ps \
				   $P_SUBDIR/${OBN}_mean_residuals.ps $P_SUBDIR/${OBN}_residuals.ps \
				   $P_SUBDIR/${OBN}_time_lags.ps $P_SUBDIR/${OBN}_backscatter.ps \
	> $P_SUBDIR/$OBN.ps


