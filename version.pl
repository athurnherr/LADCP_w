#======================================================================
#                    V E R S I O N . P L 
#                    doc: Tue Oct 13 10:40:57 2015
#                    dlm: Sat Jul 24 09:55:02 2021
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 32 68 NIL 0 0 72 0 2 4 NIL ofnI
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
#	Mar 12, 2017: - updated ANTS lib to V6.8
#	Mar 15, 2017: - V1.3
#	Nov 28, 2017: - V1.4 (perl-tools 2.0; ANTSlib 6.9)
#	Sep 13, 2018: - added '.' to library path to allow do without full pathname
#				  - added 1; to the end
#	Nov 27, 2018: - updated ANTS lib to V7.1
#			      - updated ADCP tools to V2.2
#	Sep 12, 2019: - updated to V1.5 because of CTD gap correction
#	Mar 23, 2021: - updated ADCP_tools to V2.4
#	Jun 29, 2021: - updated ANTSlib to V7.2
#	Jul  1, 2021: - updated ANTSlib to V7.3
#	Jul 24, 2021: - updated to V2.0 (major improvements) for release

#$VERSION = '1.1';				# Jan  4, 2016
#$VERSION = '1.2';				# May 12, 2016
#$VERSION = '1.3';				# Mar 15, 2017
#$VERSION = '1.4';				# Nov 28, 2017
$VERSION = '1.5';				# Sep 12, 2018

$antsMinLibVersion 		= 7.3;
$ADCP_tools_minVersion 	= 2.4;

use lib '.';

1;
