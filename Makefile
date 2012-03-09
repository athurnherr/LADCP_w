#======================================================================
#                    M A K E F I L E 
#                    doc: Mon Oct 17 13:29:27 2011
#                    dlm: Sun Feb 19 13:12:09 2012
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 10 19 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

MAKE_DIR = /Data/Makefiles
include ${MAKE_DIR}/Makefile.GMT

w.cpt:
	mkCPT -oc polar -- -0.07 -0.05 -0.04 -0.03 -0.02 -0.01 0.01 0.02 0.03 0.04 0.05 0.07 > $@

residuals.cpt:
	mkCPT -oc polar -- -0.03 -0.02 -0.01 -0.005 0.005 0.01 0.02 0.03 > $@

Sv.cpt:
	mkCPT -o -- \#-90--60:2 > $@

corr.cpt:
	mkCPT -no -- \#70-120:5 \#120-130:0.5 > $@

%_scale.skel: %.cpt
	gmtset ANNOT_FONT_SIZE_PRIMARY 7
	psscale -O -K -E -D8/2/3/0.4 -C$< -B/:"`echo $@ | sed s/_scale.skel//`": > $@
