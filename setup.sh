#!/bin/sh
#
# This is the bootstrapping configuration script for opt_depot. The
# only thing we count on to run this script is that /bin/sh works.
#
# Get enough information from the user to be able to find Perl 5
#
# ############################################################
#
# opt_depot
#
# Copyright (C) 1993-2009 The University of Texas at Austin.
#
# Contact information
#
# Author Email: opt-depot@arlut.utexas.edu
# Email mailing list: opt-depot-users@arlut.utexas.edu
#
# US Mail:
#
# Computer Science Division
# Applied Research Laboratories
# The University of Texas at Austin
# PO Box 8029, Austin TX 78713-8029
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
# 02111-1307, USA
#
# Written by: Computer Science Division, Applied Research Laboratories,
# University of Texas at Austin  opt-depot@arlut.utexas.edu
#
# v3.0
# Rewrote setup.sh to provide a clean, consistent interface on various
# UNIX systems.
#
# Jonathan Abbey 8 August 2003
#
# Release: $Name:  $
# Version: $Revision: 1.17 $
# Last Mod Date: $Date: 2009/12/09 00:33:12 $
#
###############################################################################

depot_version="3.02"

#
# subroutine to do an echo without trailing newline
#
prompt ()
{
  if [ `echo "Z\c"` = "Z" ] > /dev/null 2>&1; then
    # System V style echo
    echo "$@\c"
  else
    # BSD style echo
    echo -n "$@"
  fi
}

verify_perl ()
{
  _perl_loc=$1

  $_perl_loc > /dev/null 2>&1 <<EOF
# this Perl script is used to validate that we have a new enough version of perl
die if $] < 5.000;
exit 0;
EOF

  if [ $? = 0 ]; then
    echo "Perl has been located as $_perl_loc"
    echo
    echo "###########################################################"
    $_perl_loc -v   # this call to perl prints out the version info needed
    echo "###########################################################"
    echo
    echo "Do you wish to use $_perl_loc?"
    prompt "[Yes]> "
    read _answer
    echo

    if [ "$_answer" = "" ]; then
      perlok="y"
    else
      case $_answer in
        y|Y|yes|Yes) perlok="y"
          ;;
        *) perlok="n"
           perl_loc=""
          ;;
      esac
    fi
  else
    echo "Perl has been located as $_perl_loc"
    echo
    echo "###########################################################"
    $_perl_loc -v   # this call to perl prints out the version info needed
    echo "###########################################################"
    echo
    echo "$_perl_loc is too old, we require Perl 5.0"
    echo "or later for opt_depot"
    echo
    perlok="n"
    perl_loc=""
  fi

  return 0
}

#
# Let the games begin
#

echo
echo "## opt_depot setup version $depot_version ##"
echo
echo "Searching for 'perl'..."
echo

# Find perl (GPERL)

perl_loc=`which perl5 2> /dev/null`

if [ ! -r "$perl_loc" ]; then
  perl_loc=`which perl 2> /dev/null`
fi

if [ ! -r "$perl_loc" ]; then
  perl_loc=""
fi

perlok="n"

while [ "$perlok" = "n" ]; do
  if [ "$perl_loc" = "" ]; then
    echo "Please enter the name of the Perl 5 version you want to use"
    echo "and its location" 
    prompt "> "
    read perl_loc
    echo

    if [ ! -r "$perl_loc" ]; then
      if [ "$perl_loc" != "" ]; then
        echo "Could not find $perl_loc"
	echo
      fi
      perl_loc=""
      continue
    fi
  fi

  verify_perl $perl_loc
done

echo "The following line will be added to the opt_depot scripts:"
echo "#!$perl_loc"
echo

base_loc=`dirname $0`
$perl_loc "$base_loc/scripts/opt_install" $perl_loc
