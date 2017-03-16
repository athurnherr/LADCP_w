#======================================================================
#                    V E R S I O N . P L 
#                    doc: Tue Oct 13 10:40:57 2015
#                    dlm: Sun Mar 12 12:11:05 2017
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 26 15 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Oct 13, 2015: - created
#	Jan  4, 2016: - added $ADCP_tools_minVersion
#	Mar  8, 2016: - updated antsMinLibVersion to 6.3
#	Mar 16, 2016: - updated antsMinLibVersion to 6.4 (gmt5)
#	Mar 29, 2016: - updated antsMinLibVersion to 6.6 (libSBE bugs)
#				  - update tools to 1.5 (obsolete getopts)
#	Mar 30, 2016: - V1.2beta7
#	Apr 16, 2016: - V1.2beta8
#	May 12, 2016: - V1.2
#	May 19, 2016: - updated ADCP tools to V1.6
#	Aug  5, 2017: - updated ANTS lib to V6.7
#	Mar 12, 2017: - updated ANTS lit to V6.8

#$VERSION = '1.1';				# Jan  4, 2016
#$VERSION = '1.2';				# May 12, 2016

$VERSION = '1.3';

$antsMinLibVersion 		= 6.8;		# Feb 2017: - .lsfit.poly, .nminterp.linear added
$ADCP_tools_minVersion 	= 1.9;		# Feb 2017: - round() namespace clash resolved

