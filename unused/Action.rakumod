unit module SingleCheck::Action;

=finish

use JSON::Hjson;
use PDF::Lite;
use Text::Utils;
use PDF::Font::Loader;
use FontFactory::Type1;
use Checkwriter;
use Checkwriter::Resources;
use Checkwriter::PayTo;

#use Checkwriter::Help;

sub action(@args, :$debug) is export {

    my $resdir = $*CWD;
    # options
    my $afil;
    my $cfil;

    my @opts;
    # modes
    my $write  = 0;
    my $show   = 0;
    my $down   = 0;
    my $help   = 0;

    for @args {
        #=== options
        when /^D/ {
            $debug = 1;
        }
        when /^h/ {
            ++$help;
        }
        when /^'a=' (\S+) / {
            $afil = ~$0;
        }
        when /^'c=' (\S+) / {
            $cfil = ~$0;
        }

        #=== modes
        when /^w/ {
            $write = 1
        }
        when /^s/ {
            $show  = 1
        }
        when /^d ['=' (\S+)]? / {
            $down = 1;
            if $0.defined {
                $resdir = ~$0;
            }
        }
        default {
            say "FATAL: Unknown arg '$_'";
            exit;
        }
    }

    if $help {
        &help();
    }
    elsif $write {
        note "DEBUG: write check..." if $debug;
        # need to get the three input files located
        my $curdir = $*CWD;
        my $pdf = pay-to $curdir, :$afil, :$cfil, :$debug;
        say "See check file: $pdf";
    }
    elsif $show {
        say "Resources available for download:";
        my @res = get-resources-paths;
        for @res -> $path {
            say "  $path";
        }
    }
    elsif $down {
        say "Downloading resources into dir '$resdir'...";
        unless $resdir.IO.d {
            mkdir $resdir
        }
        unless $resdir.IO.d {
            die "FATAL: Cannot create directory '$resdir'";
        }
        my @res = get-resources-paths;
        for @res -> $path {
            note "DEBUG: $path" if $debug;
            #my $path = "resources/$subpath";
            # get the file contents
            my $str = get-content $path;
            if not $str {
                note "ERROR: Unexpected empty string for '$path'";
                next
            }
            else {
                say $str if $debug
            }

            # get the required dir for output
            my $fil = $path.IO.basename;
            note "DEBUG: fil = '$fil'" if $debug;
            #my $dir = $subpath.IO.dirname;
            my $odir = "$resdir"; #/$dir";
            note "DEBUG: odir = '$odir'" if $debug;
            unless $odir.IO.d {
                mkdir $odir;
            }

            # create the output file
            my $fnam = "$odir/$fil";
            spurt $fnam, $str;
        }
    }
}

### subroutines ###
sub help(:$debug) is export {
    print qq:to/HERE/;
    Usage: {$*PROGRAM.basename} mode [options...][help]

        Modes
          d        - write a 'draft' check (register will not be affected
                      and the check will have a VOID overlay)
          p        - write a check to a payee (register WILL be affected;
                      you will have a chance to manually enter the amount
                      in words in your native language)
          d        - delete a check from the register (sets its amount to zero
                      and adds a dated note to the 'memo' record; offers to
                      add user comments)
          s        - write a sample check with default dummy values (used to
                      fine tune the check's appearance)
          r        - shows a list of the module's resources
          t        - shows the balance in the register
          do[=DIR] - downloads the module's resources to the current directory
                      in a 'resources' subdirectory or the DIR directory
        Options
          -a=A     - use the A file (in Hjson format) to define the user's bank 
                      account information (default: data/account.yml)
          -c=C     - use the C file (in Hjson format) to define the user's check
                      information (default: data/check.hjson)
          -lang=XX - request use of language XX (NYI)
          -d       - debug

        Note: If the 'user*' and 'payee*' files don't exist the default files are:
                resources/example-payee.hjson
                resources/example-user-acct.hjson
                resources/example-user-check.hjson

    HERE
}
