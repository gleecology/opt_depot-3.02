#
# Opt_depot::Common.pm
#
# Perl module to provide common functionality used by the various
# opt_depot scripts, including link handling logic, directory filename
# operations, and configuration file parsing.
#
#************************************************************************
#
# Copyright (C) 2003-2009
# The University of Texas at Austin.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
#    02111-1307, USA
#
#    Written by: Computer Science Division, Applied Research Laboratories,
#    University of Texas at Austin  opt-depot@arlut.utexas.edu
#
#***********************************************************************
# Written by Jonathan Abbey
# 23 July 2003
#
# Release: $Name:  $
# Version: $Revision: 1.43 $
# Last Mod Date: $Date: 2009/12/09 00:26:36 $
#
#####################################################################

package Opt_depot::Common;

# pull in a couple of packages we'll use.. first a CSV parsing module

use Text::ParseWords qw(quotewords);

# and now a word wrapping module.  Let's set our word wrap limit at 70
# characters per line while we're at it.

use Text::Wrap qw($columns &wrap);
$columns = 70;

# and a module for recursive file operations

use File::Path qw(&rmtree);

# and get everything set up for export

use vars qw($VERSION @ISA @EXPORT $PERL_SINGLE_QUOTE);
$VERSION="3.02";

require 5.000;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($dest $depot $logdir $logfile $sitefile $alwaysrecurse $config_file %switches @subdirs @unify_list
	     *LOG
	     &askyn &askstring &printwrap
	     &parsequoted &safifystring
	     &init_log &close_log &logprint &printparams
	     &check_lock &clear_lock
	     &create_dir &testmakedir &dircheck &extractdir &killdir
	     &touch
	     &first_path_element
	     &removelastslash &resolve &make_absolute &swap_prefixes
	     &pathcheck &subpathcheck &totalpriority
	     &read_prefs
	    );
@EXPORT_OK = qw();

# declare our package globals that we're not exporting

#our $usage_string;
#our $log_init;
#our $lockset = 0;
#our $debug = 1;
#our $logdebug = 1;

#########################################################################
#
#                                                                   askyn
# input: $question - question to print to the user
#        $default - optional, if "y" or "n", that value will
#                   be provided if the user hits return to the question
#
# output: returns 1 on true, 0 on false
#
#
#########################################################################
sub askyn {
  my($question, $default) = @_;
  my($answer);

  if ($default eq "") {
    $default = "No";
  }

  $answer = askstring($question, $default);

  if ($answer =~ /^y/i) {
    return 1;
  } else {
    return 0;
  }
}

#########################################################################
#
#                                                               askstring
# input: $question - question to print to the user
#        $default - optional, if not equal to "", that value will
#                   be provided if the user hits return to the question
#
# output: returns 1 on true, 0 on false
#
#
#########################################################################
sub askstring {
  my($question, $default) = @_;
  my($answer);

  $question =~ s/\s+$//;	# cut off trailing whitespace

  print wrap("","",("$question",));
  if (defined $default) {
    print "\n[$default]> ";
  } else {
    print "\n> ";
  }

  $answer = <STDIN>;
  chomp $answer;

  if ($answer =~ /^$/) {
    if (defined $default) {
      $answer = $default;
    }
  }

  return $answer;
}


#########################################################################
#
#                                                               printwrap
#
# This subroutine prints any and all input strings in the argument
# array in a word-wrapped form, followed by a newline.
#
#########################################################################
sub printwrap {
  print wrap("","",@_) . "\n";
}

##########################################################################
#
#                                                              parsequoted
#
# input: $str, $remove_escapes
#
# This subroutine is designed to process a string that is surrounded by
# quotation marks, with proper escape handling.
#
# output: the quoted string, minus the surrounding quotes.  Any
# backslash (\) escapes are preserved in the returned string, for later
# processing.
#
##########################################################################
sub parsequoted {
  my ($str, $remove_escapes) = @_;

  my $quoted = "";
  my $strcopy = $str;

  $strcopy =~ s/^\s+//;		# trim leading whitespace

  if ($strcopy =~ m/^(["'])((?:\\.|(?!\1)[^\\])*)\1/) {
    $quoted = $2;

    if ($remove_escapes) {
      $quoted =~ s/\\(.)/$1/g;
    }
  }

  return $quoted;
}

#########################################################################
#
#                                                            safifystring
#
# Safe-ify-String
#
# This subroutine takes an string input string, and if it contains any
# white space, quotation marks, or backslashes, we generate a double-quote
# delimited, escaped string suitable for parsing with parsequoted
#
# If the string appears not to need quoting and escaping, the original
# form of the input string is returned.
#
#########################################################################
sub safifystring {
  my ($input) = @_;

  my $output;

  if ($input !~ /\s/ &&
      $input !~ /\"/ &&
      $input !~ /\\/ &&
      $input !~ /\'/) {
    return $input;
  } else {
    # need to generate a quoted string

    $output = $input;
    $output =~ s/\\/\\\\/g;
    $output =~ s/\"/\\\"/g;
    $output =~ s/\'/\\\'/g;
    $output = "\"$output\"";

    return $output;
  }
}

#########################################################################
#
#                                                                init_log
#
# input: $appname, $version, $dodebug
#
# uses: $logdir $dest %switches package globals
#
# This function handles initialization of the log file if the %switches
# hash doesn't contain q.
#
# Note that because this function depends on a bunch of package globals,
# it needs to be called after read_prefs().
#
#########################################################################
sub init_log {
  my ($appname, $version, $dodebug) = @_;

  my ($buf, @dest, $temphandle);

  if ($dodebug) {
    $debug = 1;
  }

  # name log file, with colons separating the path of the log target

  if ($logfile eq "") {
    @dest= split (/\//, $dest);
    shift(@dest);
    $logfile = "$logdir/" . join(':',@dest);
  }

  # open log file and time stamp entry

  if (!$switches{'q'}) {
    open (LOG, ">> $logfile") || die "Could not open $logfile";

    # don't do command buffering on LOG

    $temphandle = select(LOG);
    $| = 1;
    select($temphandle);
    $log_init = 1;
  }

  logprint("\n\n**$appname $version **  ", 0);

  ($sec, $min, $hour, $mday, $mon, $year)= localtime(time);
  $mon=$mon + 1;
  $year = $year + 1900;	# y2k ok!

  if ($min < 10) {
    $min = "0" . $min;
  }

  if ($sec < 10) {
    $sec = "0" . $sec;
  }

  logprint("$hour:$min:$sec  $mon\/$mday\/$year\n\n", 0);
  printparams();
}

#########################################################################
#
#                                                               close_log
#
#
# This function closes the log file if the %switches hash doesn't
# contain q.
#
#########################################################################
sub close_log {
  if ($log_init) {
    close(LOG);
    $log_init = 0;
  }
}

##########################################################################
#
#                                                                 logprint
#
# input: $str - A string to print and/or log
#        $level - A numeric value.. if 0, print to stdout only on
#                 -v being set.  If less than 0, print to stdout only
#                 if $debug is set.
#
#                 If $level is less than 0, the string will only be logged
#                 if $logdebug is set.
#
##########################################################################
sub logprint {
  my ($str,$level) = @_;

  if ($level > 0 || ($level == 0 && $switches{'v'}) || ($level < 0 && $debug)) {
    print $str;
  }

  if (($level >= 0 || $logdebug) && $log_init) {
    print LOG $str;
  }
}

##########################################################################
#
#                                                              printparams
#
# This subroutine logprints the command line flags and configuration
# data loaded from the opt.config file.
#
##########################################################################
sub printparams {
  my ($key, $switch_string, $file_string, $first);

  foreach $key (keys %switches) {
    $switch_string .= "$switches{$key} ";
  }

  logprint("Params: ", -1);
  logprint("$switch_string\n",-1);
  logprint("        dest: " . safifystring($dest) . "\n", -1);
  logprint("        depot: " . safifystring($depot) . "\n", -1);
  logprint("        config: " . safifystring($config_file) . "\n", -1);
  logprint("        sitefile: " . safifystring($sitefile) . "\n", -1);
  logprint("        logfile: " . safifystring($logfile) . "\n", -1);

  logprint("        subdirs: ", -1);

  $first = 1;
  foreach (@subdirs) {
    if (!$first) {
      logprint(", ", -1);
    }
    logprint(safifystring($_), -1);
    $first = 0;
  }

  logprint("\n", -1);

  if (!defined $switches{'R'} && defined $switches{'r'}) {
    logprint("        recurse: ", -1);

    $first = 1;
    foreach (@unify_list) {
      if (!$first) {
	logprint(", ", -1);
      }
      logprint(safifystring($_), -1);
      $first = 0;
    }
  }

  logprint("\n\n", -1);
}

#########################################################################
#
#                                                              check_lock
#
# input: $application, the name of the program being locked
#
# check_lock is a test-and-set routine for checking whether a lock can
# be established.  If a lock already exists and the user declines to
# break the lock, or if the user doesn't have permission to create a new
# lock file, check_lock will return 0.
#
# If the lock file can be created under $dest, check_lock returns 1.
#
# NOTE: check_lock consults the package global %switches hash to see
# if -s was specified on the command line.  If so, the lock will not be
# created or checked.  This is to allow opt_setup to set up an umbrella
# lock when running the other opt_depot scripts.
#
#########################################################################
sub check_lock {
  my ($application) = @_;

  my ($user, $software, $lock, $mins_ago);
  local *LOCK;

  if (defined $switches{'s'}) {
    return 1;
  }

  $lock = "$dest/lock.optdepot";

  # read lock and die if found

  if (open (LOCK, "<$lock")) {
    $user = <LOCK>;
    $software = <LOCK>;
    close(LOCK);

    chomp $user;
    chomp $software;

    print "\"$user\" may still be using $software.\n";
    $mins_ago= (-M $lock) * 24 * 60;
    printf ("The lock was created %3.1f minutes ago.\n", $mins_ago);

    print "\n";
    if (askyn("Would you like to override?", "Yes")) {
      unlink($lock);
    } else {
      $lockset = 0;
      return 0;
    }
  }

  # create a lock

  if (!open LOCK, ">$lock") {
    logprint("Could not create lockfile ($lock)", 1);
    $lockset = 0;
    return 0;
  } else {
    print LOCK "$ENV{'USER'}\n";
    print LOCK "$application\n";
    close (LOCK);
    $lockset = 1;
  }

  return 1;
}

#########################################################################
#
#                                                              clear_lock
#
# input: none
#
# uses: $log LOCK $dest %switches
#
# output: clears the lock file established by check_lock()
#
#########################################################################
sub clear_lock {
  if ($lockset) {
    unlink("$dest/lock.optdepot") || logprint("Could not remove lock!", 1);
  }
}

#########################################################################
#
#                                                              create_dir
# input: a pathname
#
# output: makes sure the specified directory exists. If it doesn't
#         then check_dirs makes it (along with any super-directories)
#
#
#########################################################################
sub create_dir {
  my ($file) = @_;
  my ($temp, @components);

  $file =~ s/\/\//\//g;		# get rid of any slash bounces

  @components = split(/\//, $file);

  foreach $comp (@components) {
    $temp .= "$comp";

    if (! -d $temp && ($temp ne "")) {
      if (!mkdir($temp, 0777)) {
	print "Could not make dir $temp\n";
	return 0;
      }
    }

    $temp .= "/";  # add trailing /
  }

  return 1;
}

#########################################################################
#
#                                                              testmakedir
#
# input: a pathname to test, default
#
# this directory will insure that the given path exists as a directory,
# or it will die.  If the path doesn't already exist, the user will
# be asked as to whether they want to create it.. if not, we die.
#
#########################################################################
sub testmakedir {
  my($dir,$default)= @_;
  my($ans);

  if (-f $dir) {
    die "Couldn't create a directory $dir.. a file by that name exists.";
  }

  if (!(-d $dir)) {
    print "\n";
    unless (askyn("$dir does not exist. Do you wish to create it?",
		  $default)) {
      die "Installation process aborted\n";
    }
    create_dir($dir);
  }
}

#########################################################################
#
#                                                                dircheck
#
# input: a pathname to test
#
# this function will trigger an exit if the parameter is not
# a directory.
#
#########################################################################
sub dircheck {
  my ($dir, $explain) = @_;

  if (!(-d $dir)){
    if ($explain ne "") {
      logprint("$explain ($dir) doesn't exist\n", 1);
    } else {
      logprint("$dir is not a directory\n", 1);
    }
    clear_lock();
    exit(0);
  }
}

#########################################################################
#
#                                                              extractdir
#
# input: $filepath, a string containing a fully qualified path, terminating
#        in a filename
#
# output: a string containing just the directory from $filepath
#
#########################################################################
sub extractdir {
  my ($filepath) = @_;

  my (@comps);

  @comps =split(/\//, $filepath);
  pop @comps;

  return removelastslash(join('/', @comps));
}

#########################################################################
#
#                                                                 killdir
#
# input: $filepath, a string containing a directory to be deleted
#
# returns 0 on failure, or a positive value on success
#
#########################################################################
sub killdir {
  my ($filepath) = @_;

  my $errcount = 0;

  local $SIG{__WARN__} = sub {$errcount++};	# have to use local for dynamic scope

  rmtree($filepath, {verbose=>0, safe=>0, keep_root=>0, error=> \my $err});

  $returncode = 1;

  if (defined $err) {
      for $error (@$err) {
	  print $error;
	  $returncode = 0;
      }
  }

  return $returncode;
}

#########################################################################
#
#                                                                   touch
#
# input: a pathname
#
# this function implements a standard unix touch.. touching a file causes
# it to be created as a zero length file if it does not exist, or to
# update its access and modification times if it does.
#
# Returns 1 on success, 0 on failure.
#
#########################################################################

sub touch {
  my ($touchpath) = @_;

  my ($now);

  local(*TEMP);

  $now = time();

  if (-e $touchpath) {
    utime $now, $now, $touchpath;
    return 1;
  }

  open(TEMP, ">>$touchpath") || return 0;
  close(TEMP);

  return 1;
}

#########################################################################
#
#                                                      first_path_element
#
# input: a pathname
#
# this function will return the first element of the path.. if the
# pathname provided is absolute (begins with /), / will be returned.
#
#########################################################################
sub first_path_element {
  my ($pathname) = @_;

  my @list = split /\//, $pathname;

  if ($list[0] eq "") {
    return "/";
  } else {
    return $list[0];
  }
}

#########################################################################
#
#                                                         removelastslash
#
# input: a pathname to test
#
# This function will remove trailing slashes from the directory name
# input, with the exception that if the pathname is '/', the single
# slash will not be removed.
#
# This function no longer modifies its input parameter.. you need to
# use the result returned by this function if you want the modified string
#
#########################################################################
sub removelastslash {
  my ($param) = @_;
  $param =~ s/([^\/])\/+$/$1/;
  return $param;
}

#########################################################################
#
#                                                               pathcheck
#
# This function is used to determine if $file is contained under any
# directory listed in the keys of %assoc.  The keys of %assoc should
# map to integer values, in which the highest positive number is taken
# to be the best priority, if we're dealing with a priority hash.  If
# we're dealing with an exclusion hash, then all values in the exclusion
# hash will be positive numbers, so if we find any of them we'll wind
# up returning a positive (true) integer value.
#
# In other words, when used on the global %priority hash, we'll return an
# integer that can be compared to determine relative priority.  When
# used on the global %exclude hash, we'll effectively return a boolean
# value.
#
# input: $file - a fully qualified filepath
#        $assoc_ref - a reference to an associative array (exclude or priority)
#
# Note that we're using perl prototypes for this subroutine definition, so
# a naked %hash passed in for the second parameter will be converted to a
# hash reference within this subroutine.
#
# output: as above.
#
#########################################################################
sub pathcheck ($\%) {
  my ($file, $assoc_ref) = @_;

  my %assoc = %{$assoc_ref};

  if ($file !~ /^\//) {
    logprint("Pathcheck ASSERT ERROR: $file must be an absolute path\n", 1);
    exit(1);
  }

  @components = split(/\//, $file);

  my ($t_pri, $temp, $hi_pri);

  # we want to find the best (highest numerical value) priority
  # that pertains to $file

  $hi_pri = 0;
  $temp = "";

  # now loop over the path, from top down.  Since we're splitting on
  # /, if $file began with a slash, our first component will be the
  # empty string, and we'll start adding non-empty strings after we've
  # appended the first slash in the second clause of the loop

  foreach $comp (@components) {
    $temp .= "$comp";

    if (defined $assoc{$temp}) {
      $t_pri = $assoc{$temp};

      if ($t_pri == 0) {
	logprint("Pathcheck ASSERT ERROR: 0 value item $temp in hash\n", 1);
	exit(1);
      }

      if ($t_pri > $hi_pri) {
	$hi_pri = $t_pri;
      }
    }

    # add a trailing /, in case the trailing slash was present in the
    # hash, and check again.  Adding the trailing slash here will
    # also prep us to add the next component.

    $temp .= "/";

    if (defined $assoc{$temp}) {
      $t_pri = $assoc{$temp};

      if ($t_pri == 0) {
	logprint("Pathcheck ASSERT ERROR: 0 value item $temp in hash\n", 1);
	exit(1);
      }

      if ($t_pri > $hi_pri) {
	$hi_pri = $t_pri;
      }
    }
  }

  return $hi_pri;
}

#########################################################################
#
#                                                            subpathcheck
#
# This function is used to provide the calculated priority of a directory
# path element, based on any and all elements contained under that path
# element.  This is the inverse of pathcheck, which is used to determine
# whether an element has priority from a container.
#
# Like pathcheck, subpathcheck uses the %assoc hash to look up
# priority values, if $path is a superdirectory of any path elements
# contained in the keys of %assoc.  The keys of %assoc should map to
# integer values, in which the highest positive number is taken to be
# the best priority, if we're dealing with a priority hash.
#
# And, really, this subroutine's function only makes sense with the
# global %priority hash, as we wouldn't necessarily want to exclude
# something because a subcomponent has been excluded
#
# In other words, when used on the global %priority hash, we'll return an
# integer that can be compared to determine relative priority.  When
# used on the global %exclude hash, we'll effectively return a boolean
# value.
#
# input: $path - a fully qualified directory path
#        $assoc_ref - a reference to an associative array (exclude or priority)
#
# Note that we're using perl prototypes for this subroutine definition, so
# a naked %hash passed in for the second parameter will be converted to a
# hash reference within this subroutine.
#
# output: as above.
#
#########################################################################
sub subpathcheck ($\%) {
  my ($path, $assoc_ref) = @_;
  my %assoc = %$assoc_ref;
  my ($t_pri, $hi_pri);
  my ($pathregexp);

  # we only work if we're given a directory element, of course,
  # otherwise there's no point trying to imagine subcomponent
  # priorities

  $path = removelastslash($path);

  $pathregexp = $path;
  $pathregexp =~ s/(\W)/\\$1/g;	# backslash escape any special chars

  if (!-d $path) {
    logprint("Subpathcheck ASSERT ERROR: non-directory item $path submitted\n", 1);
    exit(1);
  }

  # if we have the directory name itself in the %assoc, start things
  # off with its priority.. we'll check for it both with a trailing
  # slash and without.  Here we prime the pump by looking for it
  # without the trailing slash.. the next thing we'll do will be to
  # loop over all keys in the hash and see if any of them start with
  # $path/.

  $hi_pri = 0;

  if (defined $assoc{$path}) {
    $hi_pri = $assoc{$path};

    if ($hi_pri == 0) {
      logprint("Subpathcheck ASSERT ERROR: 0 value item $path in hash\n", 1);
      exit(1);
    }
  }

  # we want to find the best (lowest numerical value) priority
  # that pertains to $file.. all the values in %assoc should
  # be greater than zero, so we just look for the lowest

  foreach $key (keys %assoc) {
    if ($key =~ /^$pathregexp\//) {

      # you only get counted for priority if you exist

      if (-e $key) {
	$t_pri = $assoc{$key};

	if ($t_pri == 0) {
	  logprint("Subpathcheck ASSERT ERROR: 0 value item $key in hash\n", 1);
	  exit(1);
	}

	if ($t_pri > $hi_pri) {
	  $hi_pri = $t_pri;
	}
      }
    }
  }

  return $hi_pri;
}

#########################################################################
#
#                                                           totalpriority
#
# This function is used to provide the calculated priority of a
# directory path element, based on any and all elements contained
# under or over that path element.  This is the effective union of
# pathcheck and subpathcheck.
#
# Like pathcheck and subpathcheck, totalpriority uses the %assoc hash
# to look up priority values, if $path is a superdirectory of any path
# elements contained in the keys of %assoc.  The keys of %assoc should
# map to integer values, in which the highest positive number is taken
# to be the best priority.
#
# Note that the subpathcheck algorithm really only applies to priority
# checks, as excluding a subcomponent should have no necessary effect on
# exclusion of the container.
#
# input: $path - a fully qualified directory path
#        $assoc_ref - a reference to an associative array (priority)
#
# Note that we're using perl prototypes for this subroutine definition, so
# a naked %hash passed in for the second parameter will be converted to a
# hash reference within this subroutine.
#
# output: as above.
#
#########################################################################
sub totalpriority ($\%) {
  my ($path, $assoc_ref) = @_;

  my ($pri1, $pri2);

  $pri1 = pathcheck($path, %{$assoc_ref});

  $path = removelastslash($path);

  if (!-d $path) {
    return $pri1;
  }

  $pri2 = subpathcheck($path, %{$assoc_ref});

  if ($pri1 > $pri2) {
    return $pri1;
  } else {
    return $pri2;
  }
}

#########################################################################
#
#                                                                 resolve
#
# input: $dir - absolute pathname of current directory
#        $link - string containing the readlink() results for a
#                symbolic link in $dir to be processed
#
# This function takes the current directory and the string
# obtained from a readlink() call and calculates and returns the
# absolute path to the target of the readlink, resolving any relative
# path elements along the way.
#
#########################################################################
sub resolve {
  my($dir, $link) = @_;

  my(@alinkp, $d, $alinkp);

  # make array representations of
  # the current directory and symbolic link

  # if we have a leading / in our $dir or $link,
  # we'll need to shift to get rid of the leading
  # empty array element

  @dirp=split(/\//, $dir);
  shift(@dirp) if (!($dirp[0]));

  @linkp=split(/\//, $link);
  shift(@linkp) if (!($linkp[0]));

  # @alinkp is an array that we will build to contain the absolute
  # link target pathname.  If the link does not begin with a /, it is
  # a relative link, and we need to place our current directory into
  # the @alinkp array.

  if ($link !~ /^\//) {
    @alinkp=@dirp;
  }

  # modify the @alinkp array according
  # to each path component of the @linkp array
  # (an array representation of the symbolic link
  # given to us), to arrive at the ultimate absolute
  # pathname of the symbolic link

  $d = shift(@linkp);

  while ($d) {
    if ($d eq "..") {
      pop(@alinkp);
    } elsif ($d ne ".") {
      push(@alinkp, $d);
    }

    $d=shift(@linkp);
  }

  $alinkp = "/".join('/',@alinkp);

  return $alinkp;
}

#########################################################################
#
#                                                           make_absolute
#
# input: a pathname
#
# output: if the pathname does not begin with a leading slash, then
#         the current working directory is pre-pended to the input dir
#
########################################################################
sub make_absolute {
  my($dir) = @_;

  return resolve($ENV{'PWD'}, $dir);
}

#########################################################################
#
#                                                           swap_prefixes
#
# input: a pathname, an old prefix, and a new prefix
#
# output: If the pathname begins with the old prefix, we return an
#         equivalent pathname with the old prefix substituted for
#         the new.  If the pathname does not begin with the old
#         prefix, we'll return an empty string.
#
########################################################################
sub swap_prefixes {
  my($path, $oldprefix, $newprefix) = @_;

  my($temp, $temp2, $result);

  $temp = $oldprefix;
  $temp =~ s/(\W)/\\$1/g;	# backslash escape any special chars

  $temp2 = $newprefix;
  $temp2 =~ s/(\W)/\\$1/g;	# backslash escape any special chars

  if ($path !~ /^$temp/) {
    logprint("Error, swap_prefixes called with a path ($path) that doesn't begin with the oldprefix ($oldprefix)\n", 1);
    return "";
  }

  $result = $path;
  $result =~ s/^$temp/$temp2/;

  # undo our backslashing

  $result =~ s/\\(.)/$1/g;

  return $result;
}

##########################################################################
#
#                                                               read_prefs
#
# The idea of read_prefs is to create a single function which can be called
# by the various opt scripts which would process command line arguments
# and the configure file.. ?
#
# input: $usage_str, $default_config_file, $switchlist, @ARGV
#
# $usage_str is a textual message describing the proper command line
# parameters we're expecting.  The $default_config_file should be the
# initial location to look in for the opt.config file.  The
# $switchlist string should be a concatenation of the permissible
# single-character command line flags.  %prefs should be a hash to
# load preference data into, and @ARGV should be the command line
# argument vector.
#
# output: the exported $dest, $depot, $logdir, %switches, @subdirs, $config_file,
# and @unify_list variables are loaded from the given configuration file (or
# whatever configuration file is specified using the -f argument in @ARGV)
#
##########################################################################

sub read_prefs ($$$\@) {
  my ($usage_str, $default_config_file, $switchlist, $ARGV_ref) = @_;

  my ($cmd_config_file, $cmd_depot, $cmd_dest, $cmd_logdir);

  $usage_string = $usage_str;

  # first see if we have a config file override on the command line

  $cmd_config_file = find_arg('f', @$ARGV_ref);

  if ($cmd_config_file) {
    if (-r $cmd_config_file) {
      $config_file = $cmd_config_file;
    } else {
      die "Can't find/read $cmd_config_file";
    }
  } else {
    $config_file = $default_config_file;
  }

  # read the config file

  $logdir = undef;
  $alwaysrecurse = undef;
  $sitefile = undef;
  $get_most_recent = undef;

  read_config($config_file);

  # if we didn't get an explicit -f config file specifier on the
  # command line, look to see if we have an auxiliary config file
  # located under $dest

  if (!$cmd_config_file && -e "$dest/opt.config") {
    read_config("$dest/opt.config");
  }

  # now for final after-the-fact command line overrides

  $cmd_depot = find_arg('d',@$ARGV_ref);

  if ($cmd_depot ne "") {
    $depot = $cmd_depot;
  }

  $cmd_dest = find_arg('b', @$ARGV_ref);

  if ($cmd_dest ne "") {
    $dest = $cmd_dest;
  }

  $cmd_logdir = find_arg('l', @$ARGV_ref);

  if ($cmd_logdir ne "") {
    $logdir = $cmd_logdir;

    if (-d $logdir) {
      $logfile = "";
    } else {
      $logfile = $logdir;
    }
  }

  read_switches($switchlist, @$ARGV_ref);

  # if we didn't find a Log: directive in the configuration file or
  # the command line, assert -q to turn off logging

  if (!defined $logdir || $logdir eq "") {
    $switches{'q'} = '-q';
  }

  # If the Alwaysrecurse directive was set in the config file, mark
  # total Recursion on with the -R flag.  Else, if we had a non-empty
  # recursion list in our config file, set the -r flag on.

  if (defined $alwaysrecurse && $alwaysrecurse =~ /^y/i) {
    $switches{'R'} = '-R';
  } elsif ($#unify_list >= 0) {
    $switches{'r'} = '-r';
  }

  # If GetMostRecent was set in our config file, assert the -g switch
  # for opt_link's sake

  if (defined $get_most_recent && $get_most_recent =~ /^y/i) {
    $switches{'g'} = '-g';
  }

  check_args($switchlist, @$ARGV_ref);

  $depot = removelastslash($depot);
  dircheck($depot, "The specified depot directory");

  if (defined $logdir && $logdir ne "") {
    if ($logfile ne "") {
      $logdir = extractdir($logfile);
    }

    $logdir = removelastslash($logdir);
    dircheck($logdir, "The specified log directory");
  }

  $dest = removelastslash($dest);
  dircheck($dest, "The specified link target directory");
}

##########################################################################
#
#                                                              read_config
# input: $default_config_file, $switchlist
#
# output:
#
# This function reads the configuration file for the opt_depot scripts
# and sets global variables $dest, $depot, $logdir, @subdirs, @unify_list
# that are exported by this module.
#
##########################################################################
sub read_config {
  my ($file, $switchlist) = @_;

  my ($temp);
  local(*CONFIG);

  open(CONFIG, "$config_file") || die "Could not open $config_file\n";

  while (<CONFIG>){
    if (/^Base:\s*(.*)/i) {
      $temp = $1;

      if (($temp =~ /^\s*\"/) ||
	  ($temp =~ /^\s*\'/)) {
	$temp = parsequoted($temp, 1);
      } else {
	$temp =~ s/#.*$//;	# cut off comments
	$temp =~ s/\s+.*$//;	# use whitespace as the delimiter
      }

      if ($temp eq "") {
	next;
      } else {
	$dest = $temp;
      }
    }

    if (/^Depot:\s*(.*)/i) {
      $temp = $1;

      if (($temp =~ /^\s*\"/) ||
	  ($temp =~ /^\s*\'/)) {
	$temp = parsequoted($temp, 1);
      } else {
	$temp =~ s/#.*$//;	# cut off comments
	$temp =~ s/\s+.*$//;	# use whitespace as the delimiter
      }

      if ($temp eq "") {
	next;
      } else {
	$depot = $temp;
      }
    }

    if (/^Log:\s*(.*)/i) {
      $temp = $1;

      if (($temp =~ /^\s*\"/) ||
	  ($temp =~ /^\s*\'/)) {
	$temp = parsequoted($temp, 1);
      } else {
	$temp =~ s/#.*$//;	# cut off comments
	$temp =~ s/\s+.*$//;	# use whitespace as the delimiter
      }

      if ($temp eq "") {
	next;
      } else {
	$logdir = $temp;

	# if our logdir is a directory, clear logfile, else assume
	# that we're actually being given a log file name

	if (-d $logdir) {
	  $logfile = "";
	} else {
	  $logfile = $temp;
	}
      }
    }

    if (/^SiteFile:\s*(.*)/i) {
      $temp = $1;

      if (($temp =~ /^\s*\"/) ||
	  ($temp =~ /^\s*\'/)) {
	$temp = parsequoted($temp, 1);
      } else {
	$temp =~ s/#.*$//;	# cut off comments
	$temp =~ s/\s+.*$//;	# use whitespace as the delimiter
      }

      if ($temp eq "") {
	next;
      } else {
	$sitefile = $temp;
      }
    }

    if (/^AlwaysRecurse:\s*(.*)/i) {
      $temp = $1;

      if (($temp =~ /^\s*\"/) ||
	  ($temp =~ /^\s*\'/)) {
	$temp = parsequoted($temp, 1);
      } else {
	$temp =~ s/#.*$//;	# cut off comments
	$temp =~ s/\s+.*$//;	# use whitespace as the delimiter
      }

      if ($temp eq "") {
	next;
      } else {
	$alwaysrecurse = $temp;
      }
    }

    if (/^GetMostRecent:\s*(.*)/i) {
      $temp = $1;

      if (($temp =~ /^\s*\"/) ||
	  ($temp =~ /^\s*\'/)) {
	$temp = parsequoted($temp, 1);
      } else {
	$temp =~ s/#.*$//;	# cut off comments
	$temp =~ s/\s+.*$//;	# use whitespace as the delimiter
      }

      if ($temp eq "") {
	next;
      } else {
	$get_most_recent = $temp;
      }
    }

    if (/^Subdirs:\s*(.*)/i) {
      $dirs = $1;
      $dirs =~ s/^\s+//;
      $dirs =~ s/\s+$//;

      if ($dirs ne "") {
	@subdirs = quotewords('\s+|,',0,$dirs); # from Text::ParseWords
      }
    }

    if (/^Recurse:\s*(.*)/i) {
      $rdirs = $1;
      $rdirs =~ s/^\s+//;
      $rdirs =~ s/\s+$//;

      if ($rdirs ne "") {
	@unify_list = quotewords('\s+|,',0,$rdirs); # from Text::ParseWords
      }
    }
  }

  close(CONFIG);
}

##########################################################################
#
#                                                                 find_arg
# input: $token, @args
#
# output: the string argument following the single character
# $token.. for instance, if $token is 'f', find_arg will return the
# string following -f in the @args list, if it can be found.
#
# if the token can't be found following a dash character, an empty string
# will be returned.
#
#
##########################################################################

sub find_arg {
  my ($token, @args) = @_;

  my ($i, $word, $localword, $tokenregexp);

  $i = 0;
  $localword = "";

  $tokenregexp = $token;
  $tokenregexp =~ s/(\W)/\\$1/g;	# backslash escape any special chars

  while ($i <= $#args && $args[$i] =~ /^-(.*)$/) {
    $word=$1;
    $i++;

    if ($word =~ /^$tokenregexp/) {
      # redefine config file location

      if (length($word)==1) {
	$localword = $args[$i];
      } else {
	$word =~ /^$tokenregexp(.*)$/;
	$localword = $1;
      }

      last;
    }
  }

  return $localword;
}

##########################################################################
#
#                                                            read_switches
# input: $switchlist, @args
#
# The $switchlist string should be a concatenation of the
# permissible single-character command line flags.
#
# output: sets flags in the global %switches hash
#
##########################################################################

sub read_switches {
  my ($switchlist, @args) = @_;

  my ($i, $word, @switches);

  $i = 0;
  $localword = "";

  while ($i <= $#args && $args[$i] =~ /^-(.*)$/) {
    $word=$1;
    $i++;

    if ($word =~ /^[fdlb]/) {
      if (length($word)==1) {
	$i++;
      }
      next;
    }

    if ($word =~ /(^[$switchlist]+)$/) {
      @switches= split (//, $1);
      for $switch (@switches) {
	$switches{$switch}="-$switch";
      }	
    } else {
      print "\"$word\" is an invalid command entry!\n\n";
      print $usage_string;
      exit 0;
    }
  }
}

##########################################################################
#
#                                                               check_args
# input: $switchlist, @args
#
# check_args runs through the argument array and makes sure that no
# parameters were given which shouldn't be there
#
##########################################################################

sub check_args {
  my ($switchlist, @args) = @_;

  my ($i, $word);

  if ($switchlist =~ /\W/) {
    logprint("ASSERT: check_args received special characters in switchlist\n", 1);
    exit(1);
  }

  $i = 0;

  while ($i <= $#args) {
    if ($args[$i] =~ /^-(.*)$/) {
      $word=$1;
      $i++;

      if ($word =~ /^[fdbl]/) {
	# we've got one of the standard tokens which may permissibly
	# be followed by an argument string

	if (length($word)==1) {
	  # single char flag.. skip the next param, which is the
	  # argument for the flag
	  $i++;
	}
      } elsif ($word =~ /^[$switchlist]+$/) {
	# just a set of switch flags, no big deal either
      } else {
	print "\"$word\" is an unrecognized command line flag!\n\n";
	print $usage_string;
	exit 0;
      }
    } else {
      print "\"$word\" is an unrecognized command line flag!\n\n";
      print $usage_string;
      exit 0;
    }
  }
}

1;
