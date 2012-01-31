.TH OPT_NUKE l "10 July 1997" "ARL:UT/CSD"
.SH NAME
opt_nuke 2.01 \- removes all links under the software base directory
.SH SYNOPSIS
.B opt_nuke
[
.B -vq
] [
.BI -d directory
] [
.BI -l directory
] [
.BI -b directory
] 
.RS
.SH DESCRIPTION
opt_nuke is a companion to the opt_depot script and will remove all links 
to files under the depot directory.  This will allow the user to clean
out all the links created by opt_depot and start all over again. 
.SH ARGUMENTS
.TP
.B -v
verbose mode
.TP
.B -q
quiet mode (no logging)
.TP
.BI -d directory
sets the depot depot directory
.TP
.BI -l directory
sets the log directory
.TP
.BI -b directory
sets the software base directory
.SH NOTE
All directory names should be absolute path names.  Relative path names will not be accepted.
.SH SEE ALSO
opt_depot(l), opt_clean(l), opt_setup(l)
