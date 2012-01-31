.\" -*- nroff -*-
.\"
.\" opt_link
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
.\" Version: $Revision: 1.8 $
.\" Last Mod Date: $Date: 2003/10/23 06:48:26 $
.TH OPT_LINK l "22 October 2003" "ARL:UT/CSD"
.SH NAME
opt_link 3.0 \- creates and manages links from a system depot directory to packages located in one or more central package archive directories.
.SH SYNOPSIS
\fBopt_link\fR [\fB-asqvng\fR] [\fB-f\f(BI config file\fR] [\fB-d\f(BI directory\fR] [\fB-l\f(BI path\fR] [\fB-b\f(BI directory\fR]
.SH ARGUMENTS
.TP
\fB-a\fR add only mode.
If set, \fBopt_link\fR will only add, not remove, links from the depot directory to site volume packages.
.TP
\fB-s\fR inhibits lock creation.
Used to allow \fBopt_setup\fR to handle locking when running several scripts in sequence.
.TP
\fB-q\fR quiet mode.
Disables logging to disk.  Only necessary if a log file/directory is specified in the configuration file.
.TP
\fB-v\fR verbose mode.
.TP
\fB-n\fR test mode.
When \fB-n\fR is set, \fBopt_link\fR will print out a list of actions that it would take if \fB-n\fR had not been set, without actually performing them.
.TP
\fB-g\fR get_most_recent mode.
When this option is selected, \fBopt_link\fR will allow exclusions to
occur regardless of the priority of the archive where a package is
located. For example, a version of emacs-19.33 which excludes
emacs-19.30 would be installed even if it resided on a lower priority
site volume than emacs-19.30.
.TP
\fB-f\f(BI config file\fR sets the location of the "\fIopt.config\fR" configuration file
.TP
\fB-d\f(BI directory\fR sets the "depot" directory (i.e. the directory to be searched for packages)
.TP
\fB-l\f(BI path\fR set the location of the log directory/file
.TP
\fB-b\f(BI directory\fR sets the Base directory for \fBopt_link\fR
.SH DESCRIPTION
\fBopt_link\fR is a companion to the \fBopt_depot\fR script.  While
the \fBopt_depot\fR and \fBopt_clean\fR scripts are concerned with the
creation and deletion of symbolic links under a set of deployment
directories (\fI__BASEDIR__/bin\fR, \fI__BASEDIR__/lib\fR, and etc.),
\fBopt_link\fR is responsible for linking packages into the system
\fBdepot\fR directory (\fI__DEPOTDIR__\fR) from one or more potentially
remote package archives.
.sp
\fBopt_link\fR makes it possible for a set of client systems to
automatically update themselves with new packages published on one or
more centralized NFS file servers.  When \fBopt_link\fR runs, it
consults a \fBsites\fR file which provides an ordered list of package
archives and the filesystem path where each is located.
\fBopt_link\fR then scans the archives for package directories and
links them into the system \fBdepot\fR directory, making the contents
of the packages available for the \fBopt_depot\fR script to link.
.sp
The key to this process is that all packages compiled for use with the
\fBopt_depot\fR suite are configured to be installed under a
\fBdepot\fR directory.  If a package in a package archive directory is named
\fIemacs-19.35\fR, for instance, it should have been configured to run
under the standard \fBdepot\fR directory (\fI__DEPOTDIR__/emacs-19.35\fR).  This
property of the package makes it position indepdent, so long as a symlink
exists from the canonical location to the physical location of the package.
Managing those symlinks is what \fBopt_link\fR is for.
.sp
As always with the \fBopt_depot\fR software suite, \fBopt_link\fR is designed
not to interfere with local choices or with physically installed software
packages.
As such, \fBopt_link\fR will never attempt to remove or replace
package directories that have been physically installed under the
configured \fBdepot\fR directory.
Nor will \fBopt_link\fR ever attempt to remove or replace symbolic
links from the configured \fBdepot\fR directory to extent packages or files
not located in a site volume defined in the \fBsites\fR file.
.SH SITES DEFINITIONS
\fBopt_link\fR uses a file called 'sites' to determine the directories
that will serve as the archive directories.
The file is in a plain text format, with each line containing a
central package archive listing, in the form of: \fI<label> <directory>\fR.
The directory portion of the entry is the absolute pathname of the
archive (i.e. \fI/v/site/packages\fR) and the label portion is the
name that will be associated with the archive (i.e. \fIGLOBAL\fR,
\fILocal_packs\fR, \fIfred\fR, etc.).
.sp
The order in which the package archives are listed in the sites file
determines the priority of each package archive, with the archives
listed first being given priority over the others. 
Normally, a package cannot exclude another package that is contained
in a higher priority archive, although if the \fIget_most_recent\fR
option is selected (either in the \fIopt.config\fR file or with the
\fB-g\fR command line flag) then any package can exclude any other
package, regardless of the priority of the archive where it resides.
.sp
Sample \fIsites\fR file:
.RS
# This is a sites file for opt_link
.br
# Comments and blank lines are fine
.br
.sp
local  /local/packages
.br
GLOBAL "/v/site/my packages"
.RE
.sp
This \fIsites\fR file defines two site volumes, labeled \fIlocal\fR
and \fIGLOBAL\fR, and the local paths to the directories.
Volume path names which incorporate white space must be surrounded by
double or single quotation marks, as with the '\fImy packages\fR' path
under '\fI/v/site\fR'.
As is traditional in the Perl and C languages, you can incorporate
single or double quotation marks in a quoted path, as long as you
use a backslash to escape quotation marks matching the surrounding
quotation characters.
Volume labels, on the other hand, may not include white space or
colons, and may not contain or be enclosed by quotation marks.
.sp
With this \fIsites\fR file, packages on the \fIlocal\fR volume,
because it comes first in the file, will be given priority over
packages on the \fIGLOBAL\fR volume unless \fBopt_link\fR is run
in \fIget_most_recent\fR mode.
.sp
The location of the \fIsites\fR file is specified in the \fIopt.config\fR
file, generally located at \fI__INSTALLDIR__/etc/opt.config\fR.
A \fIsites\fR file placed under the system's local base directory
(\fI__BASEDIR__/sites\fR) will always override the \fIsites\fR file
specified in the \fIopt.config\fR file, however.
This is to allow local customization of a client system when the
\fBopt_depot\fR software is being shared by an NFS server.
.SH MANUAL EXCLUSIONS
Local administrators can control remote package linkage on client
workstations using the same \fI.exclude\fR file (by default
\fI__BASEDIR__/.exclude\fR) that the \fBopt_depot\fR and
\fBopt_clean\fR scripts use.
The \fI__BASEDIR/.exclude\fR file simply consists of a set of file
or package names to be excluded, one per line, with empty lines and
pound comments ignored.
Any line that does not contain embedded slashes is taken to be a package
name, and all packages of that name will be excluded from being linked
into the depot directory.
In addition, the \fI__BASEDIR__/.exclude\fR file may be used to
exclude packages from a particular site volume, by prepending the
package name with the site volume label (as specified in the
\fIsites\fR file) followed by a colon.
.sp
For example:
.RS
# __BASEDIR__/.exclude example
.br
emacs-19.27
.br
CSDSITE:netscape-4.78
.br
CSDSITE:"a package"
.br
"package\\: with a colon and whitespace"
.RE
.sp
This configuration file will cause \fBopt_link\fR to remove, or fail
to create, any links called '\fIemacs-19.27\fR' that point to any of the
site volumes designated in the \fIsites\fR file.
In addition, the '\fInetscape-4.78\fR' and '\fIa package\fR' packages
will not be linked from the site volume designated '\fICSDSITE\fR' in
the \fIsites\fR file.  
Finally, the last line shows how to exclude a package that contains
both a colon and whitespace, from any site volume listed in the
\fIsites\fR file.
.sp
Note that \fBopt_link\fR will never remove (or replace) symbolic links
from the \fI__DEPOTDIR__\fR directory to extent directories (or files)
that are not located immediately under a volume defined in the
\fIsites\fR file, whatever any \fI.exclude\fR file says.
As with the \fBopt_depot\fR and \fBopt_clean\fR scripts,
\fBopt_link\fR is designed not to interfere with any symbolic links
you may have created that point outside of the zone of
\fBopt_link\fR's control.
Do be aware that \fBopt_link\fR will feel free to remove or replace a
symbolic link under the \fIdepot\fR directory which points to a
non-existent target, however.
.SH INTER\-PACKAGE EXCLUSIONS
.sp
.SH NOTE
All directory names should be absolute path names.
.SH SEE ALSO
opt_depot(l) opt_setup(l)
