.\" -*- nroff -*-
.\"
.\" opt_depot
.\"
.\" Copyright (C) 1993-2003 The University of Texas at Austin.
.\"
.\" Contact information
.\"
.\" Author Email: opt-depot@arlut.utexas.edu
.\" Email mailing list: opt-depot-users@arlut.utexas.edu
.\"
.\" US Mail:
.\"
.\" Computer Science Division
.\" Applied Research Laboratories
.\" The University of Texas at Austin
.\" PO Box 8029, Austin TX 78713-8029
.\"
.\" This program is free software; you can redistribute it and/or modify
.\" it under the terms of the GNU General Public License as published by
.\" the Free Software Foundation; either version 2 of the License, or
.\" (at your option) any later version.
.\"
.\" This program is distributed in the hope that it will be useful,
.\" but WITHOUT ANY WARRANTY; without even the implied warranty of
.\" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
.\" GNU General Public License for more details.
.\"
.\" You should have received a copy of the GNU General Public License
.\" along with this program; if not, write to the Free Software
.\" Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
.\" 02111-1307, USA
.\"
.\" Written by: Computer Science Division, Applied Research Laboratories,
.\" University of Texas at Austin  opt-depot@arlut.utexas.edu
.\"
.\" Release: $Name:  $
.\" Version: $Revision: 1.1 $
.\" Last Mod Date: $Date: 2003/09/23 04:29:59 $
.TH OPT.CONFIG l "22 September 2003" "ARL:UT/CSD"
.SH NAME
opt.config \- Configuration file for the \fBopt_depot\fR software management suite
.SH SYNOPSIS
__INSTALLDIR__/etc/opt.config
.SH DESCRIPTION
All of the \fBopt_depot\fR scripts support the use of an
\fBopt.config\fR file for loading configuration parameters.  By
default, the scripts will look for the \fBopt.config\fR file in
\fI__INSTALLDIR__/etc/opt.config\fR, as part of the \fBopt_depot\fR
installation directory.  In addition, the scripts will look in
\fI__BASEDIR__/opt.config\fR to allow for a per-system override in the
event that the \fBopt_depot\fR software is installed on a shared NFS volume.
.P
Finally, all of the \fBopt_depot\fR scripts support the use of a
\fB\-f\fR command line argument for specifying the location of the
\fBopt.config\fR file.
.TP
\fBBase:\fP
This keyword should be followed by the name of the base directory to
be managed by \fBopt_depot\fP and \fBopt_clean\fP.  This base
directory will contain subdirectories (like \fBbin\fP) that
\fBopt_depot\fP will create links in.
.P
Default value: \fI__BASEDIR__\fP
.TP
\fBDepot:\fP
This keyword should be followed by the location of the depot
directory, which \fBopt_depot\fP and \fBopt_clean\fP will scan for
packages and which \fBopt_link\fP, if used, will create symbolic links to any
defined site volumes.  All software to be managed with the \fBopt_depot\fP
scripts should be configured and installed under this directory.
.P
Default value: \fI__BASEDIR__/depot\fP
.TP
\fBLog:\fP
This keyword should be followed by the filename of the log file for the
\fBopt_depot\fP scripts, if logging is desired.
.P
Default value: \fI/var/log/opt_depot.log\fP
.TP
\fBSiteFile:\fP
This keyword should be followed the filename of the sites file.  The sites file
specifies a list of labeled paths to possibly remote package archives.  The \fBopt_link\fP
script consults this file to create new links from the depot directory to newly
added package directories in the listed site directories.  This feature is used to
allow creation of links from a workstation's depot directory to newly created packages
on locally mounted NFS server directories.
.P
Default value: \fI__INSTALLDIR__/etc/sites\fP
.TP
\fBSubdirs:\fP
This keyword should be followed by a comma separated list of
subdirectories for \fBopt_depot\fP and \fBopt_clean\fP to manage under
the base directory.  Subdirectories listed here will examined under
each package directory under depot, and links will be managed for each
under the base directory.  An individual subdirectory name may be placed between
quotation marks if necessary to provide proper guidance for whitespace and
commas in individual subdirectory names.
.TP
\fBAlwaysRecurse:\fP
This keyword should be followed by 'Yes' or 'No'.  If set to 'Yes',
the \fBopt_depot\fP and \fBopt_clean\fP scripts will perform recursive
directory unification whenever possible.  Recursive directory
unification refers to the creation of new ephemeral subdirectories
under the \fBopt_depot\fP managed subdirectories which can in turn
contain symbolic links to files located in the packages in the depot
directory.  If this is set to false and the \fBRecurse:\fP option is
not set, the \fBopt_depot\fP script will never create deeper
subdirectories under the managed base subdirectories.  See the \fBopt_depot\fP
man page for more details.
.TP
\fBRecurse:\fP
This keyword is only effective if \fBAlwaysRecurse:\fP is set to 'No'.
If \fBAlwaysRecurse:\fP is not enabled, this keyword is consulted to
determine what subset of the subdirectories specified by the
\fBSubdirs:\fP keyword should be treated with recursive directory unification.
.TP
\fBGetMostRecent:\fP
This keyword should be followed by 'Yes' or 'No'.  If set to 'Yes',
the \fBopt_link\fP script will allow packages from any site volume to
exclude packages from any other, regardless of the comparative
priority of the site volumes in the \fBSiteFile:\fR file.  This should
be enabled if you want to get the most recent version of a package, no
matter what site volume it is located on.
.SH SEE ALSO
opt_clean(l), opt_nuke(l), opt_setup(l), opt_link(l), opt.config(l)
