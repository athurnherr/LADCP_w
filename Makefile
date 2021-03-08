#======================================================================
#                    L A D C P _ W _ S O F T W A R E / M A K E F I L E 
#                    doc: Mon Oct 17 13:29:27 2011
#                    dlm: Wed Jul  1 14:30:06 2020
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 9 0 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

MAKE_DIR = /Data/Makefiles
include ${MAKE_DIR}/Makefile.GMT5

w.cpt:
	mkCPT -oc polar -- -0.07 -0.05 -0.04 -0.03 -0.02 -0.01 0.01 0.02 0.03 0.04 0.05 0.07 > $@

residuals.cpt:
	mkCPT -oc polar -- -0.03 -0.02 -0.01 -0.005 0.005 0.01 0.02 0.03 > $@

Sv.cpt:
	mkCPT -m255/255/255 -o -- \#-90--60:2 > $@
#	mkCPT -m255/255/255 -o -- \#-100--60:2 > $@

corr.cpt:
	mkCPT -no -- \#70-120:5 \#120-130:0.5 > $@
