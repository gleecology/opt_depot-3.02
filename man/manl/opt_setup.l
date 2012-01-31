.TH OPT_SETUP l "09 July 2003" "ARL:UT/CSD"
.SH NAME
opt_setup 2.02 \- runs opt_link, opt_clean and opt_depot in succession to update the software base and depot directories. 
.SH SYNOPSIS
.B opt_setup
[
.B -vqmrRg
] [
.BI -d directory
] 
.RS
[
.BI -l directory
] [
.BI -b directory
]
.SH ARGUMENTS
.B -v
verbose mode
.TP
.B -q
quiet mode (no logging)
.B -m
rebuild manpage index after making any changes to the man subdirectory,
using the catman program.  The command to run catman is defined inside
the opt_depot script and may be changed there.
.TP
.B -r
recursive unification. opt_depot and opt_clean will merge directories recursively, based on the list of subdirectories contained in the opt.config file's Recurse: directive.
.TP
.B -R
universal recursive unification. opt_depot and opt_clean will merge directories recursively whenever the opportunity arises.
.TP
.B -g
get_most_recent.  When this option is selected, opt_link will allow exclusions to occur regardless of the priority of the archive where a package is located. For example, a version of emacs-19.33 which excludes emacs-19.30 would be installed even if it resided on a lower priority site volume than emacs-19.30.
.TP
.BI -b directory
sets the software base directory
.TP
.BI -d directory
sets the depot directory
.TP
.BI -l directory
sets the log directory
.SH DESCRIPTION
opt_setup sets up a package depot linked to a separate site.  First it will run
.B
opt_link
, which will create all the links from packages in the the central package archives to the depot directory and remove any
links to those packages that are no longer needed (i.e. the package has been removed).
Then it will run
.B
opt_clean
which will clean out any bad links within the software base 
directory (i.e. the directory containing the "bin", "lib", "man", etc. directories containing
links to all the files within the packages needed by the user).  Finally 
.B
opt_depot
will run and create the new links from the software base directory to the depot directory.
.sp
For a more detailed description of the process see the individual scripts.
.SH NOTE
All directory names should be absolute path names. Relative path names will not be accepted.
.SH SEE ALSO
opt_depot(l), opt_clean(l), opt_link(l)
