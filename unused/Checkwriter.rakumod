unit module Checkwriter;

use Bin::Utils;
use Font::Utils;
use Lingua::EN::Numbers;
use JSON::Class:auth<zef:jonathanstowe>;
use JSON::Hjson;
use PDF::API6;
use PDF::Page;
use PDF::Content::Page :PageSizes;
use PDF::Content::Font::CoreFont;
constant CoreFont = PDF::Content::Font::CoreFont;

use Text::Utils :commify;

use Checkwriter::Resources;
use Checkwriter::Data;
use Checkwriter::Handlers;
use Checkwriter::Utils;

role Hdr {
    # common attributes for fields
    has $.id is required;       # must be unique
    has $.descrip;
}

class Field does Hdr does JSON::Class {
    has $.type is required;     # recognized: text, line, svg, png, box
    # geometry
    has $.llx = 0;
    has $.lly = 0;
    # characteristics
    has $.font-name;
    has $.font-weight;
    has $.font-size;
    has $.font-style;
    # payloads
    has $.text;
    has $.svg;
    has $.png;

    submethod TWEAK {
    }
}

class Line does Hdr does JSON::Class {
    has $.type is required;     # recognized: text, line, svg, png, box
    # geometry
    has $.llx = 0;
    has $.lly = 0;
    has $.length;
    has $.angle;
    # characteristics
    has $.linewidth;

    submethod TWEAK {
    }
}

class Amount is export {
    has Real $.amount = 0;
    method amount {
        sprintf '%0.2f', $!amount;
    }
}

class Check {
    has %.fields;

    submethod TWEAK {
    }
}

class Register {
    has %.checks;

    submethod TWEAK {
    }
}

sub amount2words($amt, :$debug) is export {
    my ($dollars, $cents);
    if $amt ~~ /^ (\d+) '.'? [(\d+)]? $/ {
        $dollars = ~$0;
        if $1.defined {
            my $s = ~$1;
            if $s ~~ /^0$/ {
                $cents = "no/100";
            }
            elsif $s ~~ /^00$/ {
                $cents = "no/100";
            }
            elsif $s ~~ /^(\d)$/ {
                my $t = ~$0;
                $cents = $t ~ "0/100";
            }
            elsif $s ~~ /^0(\d)$/ {
                my $t = ~$0;
                $cents = "$t/100";
            }
            elsif $s ~~ /^(\d\d)$/ {
                my $t = ~$0;
                $cents = $t ~ "/100";
            }
            elsif $s ~~ /^\d\d\d/ {
                die "FATAL: Unrecognized money amount: '$amt'";
            }
        }
        else {
            $cents = "NO/100";
        }
    }
    else {
        die "FATAL: Unrecognized money amount: '$amt'";
    }
    my $dwords = cardinal($dollars).uc;
    "$dwords AND $cents"
}

sub write-check($cwd, :$pfil, :$ufil, :$cfil, :$debug) is export {
    my $r      = Register.new;
    my $number = $r.next-number;

    my $c = Check.new: :$number;

    my $pdf = 0;
    return $pdf;
}

sub list-resources(:$debug --> List) is export {
    get-resources-paths;
}

=begin comment

The Office Depot single-check paper is US Letter size
and has the single-check area at the top of the page
spanning the width and one-third of the vertical
space. The resulting area is 8 1/2 by 3 2/3 inches.

The default check will have the following areas defined
for printing and customization:

+ account holder information (upper left corner):

+ payee

+ date

+ amount-numbers

+ amount-words

+ memo

+ ...

=end comment

sub print-text(Field $f, :$page, :$debug) is export {
    # Field has position, font data, data, etc.
    unless $f.type eq 'text' {
        die "FATAL: Field type is not 'text'";
    }

    # font info is from FontFactory::Type1
    # Add some text to the page
    =begin comment
    $page.text: {
        .font = $font, 9;
        .text-position = 38, $ty;
        .print("$nsh");
    }
    =end comment
}

sub draw-line(Line $f, :$page, :$debug) is export {
    # Line position, angle, length, strokewidth, etc.
    unless $f.type eq 'line' {
        die "FATAL: Field type is not 'line'";
    }
    # Draw the line on the page
    =begin comment
    $page.graphics: {
        .LineWidth = 0.2; # set stroking line-width
        .MoveTo( 37.5, $y); .LineTo(303.5, $y); .Stroke;
    }
    =end comment
}

sub print-check(Check $c, :$debug) is export {
    my $pdf = PDF::Lite.new;
    my $page = $pdf.add-page;
    # Set the default page size for all pages
    $pdf.media-box = Letter;

    for $c.fields -> $field {
        my $typ = $field.type;
        if $typ eq 'text' {
            print-text $field, :$page;
        }
        elsif $typ eq 'line' {
            draw-line $field, :$page;
        }
        else {
            die "FATAL: Unhandled field type '$typ'";
        }
    }
    $pdf.save-as: $c.pdf-name;
}

#sub populate(IO::Path $dir, :$debug) is export {
sub populate($dir, :$debug) is export {
    unless $dir.IO.d {
        die qq:to/HERE/;
        FATAL: Unable to populate directory '$dir'.
           Please file an issue with details.
        HERE
    }

    # TODO check and ask the user to add private account info.
    #   The default zero values must be filled before and personal
    #   can be written!! Note there will be some exceptions:
    #     + second name
    #     + third address line

    # copy the files from dir 'resources' into the dir.
    # do NOT overwrite existing files
    # remember to add the config.yml file, too (don't 
    # forget its contents)
    if $debug {
        say "DEBUG: filling dir '$dir' with config files";
    }
} # sub populate

=finish

# shows how to use an existing pdf doc and add
# to it


my $ifil = "form-8949-blank.pdf";
my $debug = 0;
my @ofils;

my @datalines = [
# each line has 5 fields of text and numbers
# num shares and description | date acquired | date sold     | sales price | cost
(100, "sh", "Foo Industries, Inc.",                 "10/11/2010",   "01/03/2019",   "2000",    "1500"),
];

#my @data = @datalines.shift.flat;
#dd @data;
#exit;

for 1..1 -> $n {
    my $ofil = "form-8949-page-$n.pdf";
    @ofils.push: $ofil;

    my $pdf = PDF::API6.new;
    # Open an existing PDF file
    $pdf .= open($ifil);
    # Retrieve an existing page
    my $page = $pdf.page(1);

    # Set the default page size for all pages
    $pdf.media-box = Letter;
    # Use a standard PDF core font
    my $font = $pdf.core-font: :family<Courier>; #, :weight<Bold>;
    # Add some text to the page

    # one line of form data
    my $y = 660; # starting y distance for the first line
    my $text-dy = 3.0; # distance of text baseline above each line

    # there are 35 data lines in all spanning 627.5 points
    my $dy = 627.5 / 35; # distance between lines

    # 35 lines on a page
    for 1..35 -> $n {
        $y -= $dy if $n > 1;
        my $ty = $y +  $text-dy;

        # add lines for all

        # add the text lines until consumed
        if @datalines.elems {
            my @data = @datalines.shift.flat;
            # the first field id the number of shares: nnn.nnn
            my $nsh = @data.shift;
            $nsh = sprintf '%7.3f', $nsh;
            # remove decimals if all zeroes
            $nsh ~~ s/'.000'$/    /;

            my $sh = @data.shift;

            # the last two fields are whole dollars and need to be
            # sprintf'd to look nice (add commas but no dollar symbol)
            my $cost = @data.pop;
            note "DEBUG: cost             = '$cost'" if $debug;
            $cost = commify $cost;
            note "DEBUG: commified cost   = '$cost'" if $debug;
            $cost = sprintf '%9.9s', $cost;
            note "DEBUG: \$ commified cost = '$cost'" if $debug;

            my $saleprice = @data.pop;
            $saleprice = commify $saleprice;
            $saleprice = sprintf '%9.9s', $saleprice;

            $page.text: {
                .font = $font, 9;
                # field 0
                # description of property (include number of shares)
                .text-position = 38, $ty;
                .print("$nsh");

                .text-position = 80, $ty;
                .print("$sh");
                .text-position = 97, $ty;
                .print("{@data[0]}");

                # field 1
                # date acquired
                .text-position = 315, $ty;
                .print("{@data[1]}");

                # field 2
                # date sold
                .text-position = 378, $ty;
                .print("{@data[2]}");

                # field 3
                # sale price
                .text-position = 499, $ty;
                .print("$saleprice", :align<right>);

                # field 4
                # cost
                .text-position = 563, $ty;
                .print("$cost", :align<right>);
            }
        }

        # add the lines
        $page.graphics: {
            # five separate lines with minimum linewidth
            .LineWidth = 0.2; # set stroking line-width

            # field 0
            .MoveTo( 37.5, $y); .LineTo(303.5, $y); .Stroke;
            # field 1
            .MoveTo(313.0, $y); .LineTo(372.0, $y); .Stroke;
            # field 2
            .MoveTo(375.5, $y); .LineTo(434.5, $y); .Stroke;
            # field 3
            .MoveTo(444.5, $y); .LineTo(503.5, $y); .Stroke;
            # field 4
            .MoveTo(507.5, $y); .LineTo(566.5, $y); .Stroke;
        }
    }


    # Save the new PDF
    $pdf.save-as: $ofil;
}

say "Normal end.";
if @ofils.elems {
    say "Files generated:";
    say "  $_" for @ofils;
}
else {
    say "No files were generated:";
}
