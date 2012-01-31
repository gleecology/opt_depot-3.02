.TH OPT_CLEAN l "09 July 2003" "ARL:UT/CSD"
.SH NAME
opt_clean 3.0 \- removes bad links to files under a depot directory
.SH SYNOPSIS
.B opt_clean
[
.B -svqrR
] [
.BI -d directory
] [
.BI -l directory
] 
.RS
[
.BI -b directory
]
.SH DESCRIPTION
opt_clean is a companion to the opt_depot script that will find all
links to non-existant files under the depot directory or files or
packages excluded by the .exclude configuration file.  This will
ensure the integrity of all the links in the destination directory
that point to files under the depot directory.
.sp
opt_clean will collapse any directories found that contain links to a 
single package and replace it with a symbolic link to that package. Also,
any empty directories will be removed. These features are disabled with the -r option.
.sp
Ideally opt_clean should be run immediately before or after opt_depot is run.
If this is not done, links to files that are either not there or are not
desired may remain in place and garbage links will continue to collect as the 
depot directory and the configuration files change.
.sp
See opt_depot man page for more details on the configuration files.   
.SH ARGUMENTS
.TP
.B -s
inhibits locking, used when opt_clean is run by opt_setup
.TP
.B -v
verbose mode
.TP
.B -q
quiet mode (no logging)
.TP
.B -r
recursive unification. opt_clean will unify directories containing links to a single package into a single link to that package, and will remove empty subdirectories under the software base.
.TP
.BI -d directory
sets the depot directory
.TP
.BI -l directory
sets the log directory
.TP
.BI -b directory
sets the software base directory
.SH NOTE
All directory names should be absolute path names.  Relative path names will not be accepted.
.SH SEE ALSO
opt_depot(l), opt_nuke(l), opt_setup(l)
