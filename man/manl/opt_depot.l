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
.\" Version: $Revision: 1.5 $
.\" Last Mod Date: $Date: 2003/10/06 22:06:41 $
.TH OPT_DEPOT l "24 September 2003" "ARL:UT/CSD"
.SH NAME
opt_depot 3.0 \- creates a directory structure with links to packages under a "depot" directory
.SH SYNOPSIS
\fBopt_depot\fR [\fB-svnqmR\fR] [\fB-f\f(BI config file\fR] [\fB-d\f(BI directory\fR] [\fB-l\f(BI path\fR] [\fB-b\f(BI directory\fR]
.SH DESCRIPTION
\fBopt_depot\fR manages the creation of a symbolic link farm under a
targeted Base directory.
The Base directory (\fI__BASEDIR__\fR)
contains a set of Deployment directories (\fI__BASEDIR__/bin\fR, \fI__BASEDIR__/lib\fR,
\fI__BASEDIR__/include\fR, \fI__BASEDIR__/man\fR, by default).
\fBopt_depot\fR creates symbolic links from these directories to the
matching subdirectories of packages contained under a Depot directory.
Typically the Depot directory (\fI__DEPOTDIR__\fR) is contained under the Base directory
but in principle it can be placed anywhere in the file system.
.P
The point of the symbolic link farm created by \fBopt_depot\fR is that
the user need only have a single directory added to their \fBPATH\fR,
\fBMANPATH\fR, and \fBLD_LIBRARY_PATH\fR environment variables in
order to gain access to all installed \fIdepot-ized\fR packages, yet
there is no confusion as to which file goes with which package, and
de-installing packages is as easy as installing them.
.P
\fBopt_depot\fR does nothing but create symbolic links from the
Deployment directories to the depot package subdirectories.
\fBopt_depot\fR can overwrite old links if it determines that a
different package has been given priority (see the \fIpriority\fR
section, below), but otherwise is dependent on \fBopt_clean\fR to take care
of removing old and unneeded links.
.P
.SH ARGUMENTS
.TP
\fB-s\fR inhibits lock creation.  used when \fBopt_setup\fR handles locking.
.TP
\fB-v\fR verbose mode.
.TP
\fB-n\fR test mode.
When \fB-n\fR is set, \fBopt_depot\fR will print out a list of actions that it would take if \fB-n\fR had not been set.
.TP
\fB-q\fR quiet mode.
Logging will be turned off.
.TP
\fB-m\fR rebuild manpage index
If any man page links are created, the catman program will be run to
update the system's manpage index.  The command to run catman is
defined inside the \fBopt_depot\fR script and may be changed there.
.TP 
\fB-R\fR enable full recursion.
When \fB-R\fR is set, \fBopt_depot\fR will perform recursive
unification of package subdirectories whenever possible.  Otherwise, \fBopt_depot\fR will
perform recursive unification of whatever subdirectories are specified in the \fIopt.config\fR
configuration file.
.TP
\fB-f\f(BI config file\fR sets the location of the "\fIopt.config\fR" configuration file
.TP
\fB-d\f(BI directory\fR sets the "depot" directory (i.e. the directory to be searched for packages)
.TP
\fB-l\f(BI directory\fR set the location of the log directory/file
.TP
\fB-b\f(BI directory\fR sets the Base directory for opt_depot
.SH CONFIGURATION FILE
\fBopt_depot\fR uses a configuration file, \fIopt.config\fR, to
set a number of configuration options, including many that are not
supported by \fBopt_depot\fR's command line arguments.
These include options to fine tune the list of Deployment directories
to be managed, the list of subdirectories requiring recursive
directory unification and so on.
.P
\fBopt_depot\fR looks for the \fIopt.config\fR file by examining
the contents of the \fB-f\fR flag on the \fBopt_depot\fR command
line, if provided.
If no \fB-f\fR flag is specfied on the \fBopt_depot\fR command line,
\fBopt_depot\fR will look for the \fIopt.config\fR file first under
the installation directory at \fI__INSTALLDIR__/etc/opt.config\fR, 
and second under the Base directory at \fI__BASEDIR__/opt.config\fR.
\fBopt_depot\fR in this case will take configuration information from
both locations in turn, with the configuration settings in \fI__BASEDIR__/opt.config\fR
overriding those set in \fI__INSTALLDIR__/etc/opt.config\fR.
.P
See the \fIopt.config\fR man page for more details.
.SH LOCK FILE
\fBopt_depot\fR employs a lock file (\fIlock.opt_depot\fR) located under
the Base directory (\fI__BASEDIR__/lock.opt_depot\fR) to make sure that
only one instance of any of the \fBopt_depot\fR scripts is running at
any given time.
If an \fBopt_depot\fR script is terminated abnormally, the user will
be asked to approve overriding the old lock file the next time any of
the \fBopt_depot\fR scripts are run.
.P
The \fB-s\fR command line flag inhibits this locking by the
\fBopt_depot\fR scripts, and is intended to allow \fBopt_setup\fR to
handle locking across the several scripts that it runs.
.P
.SH .PRIORITY AND .EXCLUDE
The \fBopt_depot\fR scripts use two configuration files,
\fI__BASEDIR__/.priority\fR and \fI__BASEDIR__/.exclude\fR, to
help decide which files are linked into the Deployment directories.
The \fI__BASEDIR__/.priority\fR file is used to decide between competing
choices when depot packages have conflicting file or directory names.
The \fI__BASEDIR__/.exclude\fR file lists directories and
files which are not to be linked into the Deployment directories.
.P
.SH \f(BI.priority\fR
The \fI__BASEDIR__/.priority\fR file contains a list of packages and
package files, in order of decreasing priority, one per line.
Files or directories listed at the top of the
\fI__BASEDIR__/.priority\fR file have higher priority than files or
directories listed towards the end of the \fI.priority\fR file.
All files or directories listed anywhere in the \fI.priority\fR file
have priority over any files or directories not listed in the \
\fI.priority\fR file.
.P
When \fBopt_depot\fR tries to resolve a conflict through the use of
the \fI.priority\fR file, it first checks to see if any of the
files involved in the conflict are explicitly listed in the \
\fI.priority\fR file.
If so, the priority of the file or files in the \fI.priority\fR file
are used to determine which individual file should be linked.
If none of the files at issue are listed in the \fI.priority\fR
file, \fBopt_depot\fR will give preference to whichever file is listed
in a package or subdirectory of the highest priority.
That is, if the file in question is \fI__DEPOTDIR__/test/bin/file\fR,
and a link to \fI__DEPOTDIR__/old/bin/file\fR is already in place at \fI__BASEDIR__/bin/file\fR,
the old link will be removed if:
.P
.RS
1) \fItest/bin/file\fR or \fI__DEPOTDIR__/test/bin/file\fR is in the \
\fI__BASEDIR__/.priority\fR file ahead of an entry for \fIold/bin/file\fR or
\fI__DEPOTDIR__/old/bin/file\fR, if such exists
.RE
.P
or
.P
.RS
2) any directory in the tree containing \fI__DEPOTDIR__/test/bin/file\fR has a higher priority in the \fI.priority\fR file than all directories which contain \fI/__DEPOTDIR__/old/bin/file\fR
.RE
.P
The individual files' relative priorities, if listed, are considered before the priority of any containing directory or package.  
.P
For example:
.RS
#this is a priority list
.br
__DEPOTDIR__/opt_depot/bin/opt_depot
.br
idl/bin/lmstat
.br
X11R6/man
.br
X11R5/man
.br
X11R5/man/manl/xterm.l
.br
gnuemacs-19.23
.br
gnuemacs-18.57
.RE
.P
In the above example, X11R5/man/manl/xterm.l would be given preference
in linking, because it is a specific file.
In all other cases, the X11R6 man pages would be given preference,
because they are not specifically enumerated, and X11R6/man, which
contains the man pages, has a higher preference than X11R5/man.
.P
If X11R5 had been listed above X11R6/man in the .priority file, then
X11R5's man pages would be linked.  \fBopt_depot\fR only looks at the
containing directory with the highest priority when deciding linkage
based on containing directories.
.P
.SH \f(BI.exclude\fR
\fI__BASEDIR__/.exclude\fR is a list of packages and package files that should not
be linked to the software Base directory structure.  
The format is the same as that for \fI__BASEDIR__/.priority\fR, with
one package, directory, or file name per line.
.P
In addition to the primary \fI__BASEDIR__/.exclude\fR file,
\fBopt_depot\fR will scan all directories under the Depot directory
(\fI__DEPOTDIR__\fR) for \fI.exclude\fR files.  Any \fI.exclude\fR
files found in a depot package will be combined with the contents of
the \fI__BASEDIR__/.exclude\fR file to produce the complete list of
files to exclude from the Deployment directories.
.P
Note that the per-package \fI.exclude\fR files have a special and
expanded role to play when it comes to the \fBopt_link\fR script's
management of symbolic links from the Depot directory to remote
package archives.
See that manpage for details.
.SH CONFLICT HANDLING RULES
If \fBopt_depot\fR finds that a link to be made conflicts with an
already existing link, it will follow some simple rules for resolving
conflicts.
.P
First, the \fI__BASEDIR__/.priority\fR file is consulted to see which of the two
possible targets has higher priority.  If one has higher priority than
the other, then the other link will be removed (if it had already been
established), and replaced with the one with higher priority.
.P
Second, if neither of the link targets has any priority set in the
\fI__BASEDIR__/.priority\fR file, \fBopt_depot\fR will simply keep the
older link.
.P
This is generally the appropriate behavior, but there are times when a
single symbolic link placed in the Deployment directories is not
adequate.
Take the case where two packages each contain an \fIinclude\fR
directory, and both of those \fIinclude\fR directories contain a
common subdirectory, such as \fIperl\fR.
If \fBopt_depot\fR just followed the logic above,
\fI__BASEDIR__/include/perl\fR would point to one of the two
\fIinclude/perl\fR subdirectories.
There would be no effective unification of the files contained under
those two subdirectories.
.P
The \fBopt_depot\fR (and \fBopt_clean\fR) scripts deal with this by
supporting a recursive directory unification process, if enabled in
the \fIopt.config\fR file or on the command line.
In our example, \fBopt_depot\fR would create a
\fI__BASEDIR__/include/perl\fR directory, recurse down into it, and
create symbolic links to lower level files or directories in the two
source packages.
If a lower-level directory was also present in both packages'
\fIinclude/perl\fR subdirectories, opt_depot would create yet another
common subdirectory, and recurse down to link files from both
subdirectory trees.
.P
Note that \fBopt_depot\fR will only ever attempt to perform recursive
unification in cases where an existing link does not have priority
over new files or directories to be linked.
.P
The \fBopt_depot\fR and \fBopt_clean\fR scripts will always perform
recursive directory unification if the \fB-R\fR command line flag is
supplied, or if the \fIopt.config\fR file has the \fBAlwaysRecurse:\fR
option turned on.  Otherwise, recursive directory unification will only
take place in those Deployment directories listed in the \fIopt.config\fR
file's \fBRecurse:\fR directive.
.P
.SH LOGGING
By default, \fBopt_depot\fR will log the run in the file specified in the
\f(BILog:\fR directive specified in the \fIopt.config\fR file.  See
the \fIopt.config\fR man page for more details on configuring the log
file location.
.P
Logging can be turned off using the \fB-q\fR (for quiet) switch.  The log
file location can be changed using the \fB-l\fR "path" option.
.SH NOTE
All directory names should be absolute path names
.SH SEE ALSO
opt_clean(l), opt_nuke(l), opt_setup(l), opt_link(l), opt.config(l)
