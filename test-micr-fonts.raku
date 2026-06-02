#!/usr/bin/env raku

use PDF::Lite;
use PDF::Font::Loader :load-font;
use PDF::Content::FontObj;

constant MICR-TRANSIT = chr(0x2446);
constant MICR-ON-US   = chr(0x2447);
constant MICR-AMOUNT  = chr(0x2448);
constant MICR-DASH    = chr(0x2449);

my $mpath = "/home/tbrowde/mydata/tbrowde-home/Monotype-MyFonts/MICR/MICRStd.otf";

sub print-micre-line(
    # the defaults for the prefix and suffix characters are for one known use case
    # for a personal checking account
    # the defaults for the enclosed numbers are place holders for testing
    #                           prefix                suffix
    :$routing = "123456789",    :$rp = MICR-TRANSIT, :$rs = MICR-TRANSIT,
    :$account = "000123456789", :$ap = "",           :$as = MICR-AMOUNT,
    :$number  = "1234",         :$np = "",           :$ns = "",

    :$pdf!, :$page!,
    :$font-path!, 
    :$font-size = 12, 
    :$x!, :$y!, # starting point for the text line
                #   where y is the distance from the TOP of the page
    :$d1 = 36,   # distance between routing and account
    :$d2 = 42,  # distance between account and check number
    :$box = False, # if True, put a box around the text line

) is export {
    # given a path to a micre font, a font size, and other info, print 
    # a micr check line

    my $micr-font = load-font(:file($font-path));
    # build the micre line
    my $micr-line = 
       $rp ~ $routing ~ $rs ~ $d1 ~ $ap ~ $account ~ $as ~ $d2 ~ $np ~ $number ~ $ns;

    $page.text: {
        .font = $micr-font, $font-size;
        .text-position = 72, $y;
        .say: $micr-line;
    }
}

#my PDF::Content::FontObj $micr-font = load-font(:file($mpath));

my $pdf = PDF::Lite.new;
my $page = $pdf.add-page;

# desired positions
my $y = 700;
my $x = 40;

print-micre-line :$pdf, :$page, :$x, :$y, :font-path($mpath);;

=begin comment
my $y = 700;

$y -= 36;

$y -= 36;
for @tests -> $text {
    $page.text: {
        .font = [ $micr-font, 12 ];
        .text-position = [ 72, $y ];
        .say($text);
    };
    $y -= 36;
}
=end comment

say "Writing a personal check micre line: ";
my $mtest = "micr-font-test.pdf";
$pdf.save-as($mtest);
say "See file $mtest";
