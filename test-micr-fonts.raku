#!/usr/bin/env raku

use PDF::Lite;
use PDF::Font::Loader :load-font;
use PDF::Content::FontObj;

constant MICR-TRANSIT = chr(0x2446);
constant MICR-ON-US   = chr(0x2447);
constant MICR-AMOUNT  = chr(0x2448);
constant MICR-DASH    = chr(0x2449);

sub put-micre-line(
    # the defaults for the prefix and suffix characters are for one known use case
    # for a personal checking account
    # the defaults for the enclosed numbers are place holders for testing
    #                           prefix                suffix
    :$routing = "123456789",    :$rp = MICR-TRANSIT, :$rs = MICR-TRANSIT,
    :$account = "000123456789", :$ap = "",           :$as = MICR-AMOUNT,
    :$number  = "1234",         :$np = "",           :$ns = "",

    :$pdf!, :$page!,
    :$font-path!, 
    :$font-size!, 
    :$x!, :$y!, # starting point for the text line
                #   where y is the distance from the TOP of the page
    :$d1!,      # distance between routing and account
    :$d2!,      # distance between account and check number
    :$box = False, # if True, put a box around the text line

) is export {
    # given a path to a micre font, a font size, and other info, print 
    # a micr check line
}

my $mpath = "/home/tbrowde/mydata/tbrowde-home/Monotype-MyFonts/MICR/MICRStd.otf";
my PDF::Content::FontObj $micr-font = load-font(:file($mpath));

my @tests;

@tests.push('0123456789');

@tests.push(chr(0x2446));
@tests.push(chr(0x2447));
@tests.push(chr(0x2448));
@tests.push(chr(0x2449));


my $y = 700;

my $routing = "123456789";
my $account = "000123456789";
my $number  = "1234";

# Hancock Whitney personal check MICR format
my $micr-line = "Hancock Whitney example:    " ~  MICR-TRANSIT ~ $routing ~ MICR-TRANSIT ~ $account ~ MICR-AMOUNT ~ " " ~ $number;

my $pdf = PDF::Lite.new;
my $page = $pdf.add-page;

$page.text: {
    .font = $micr-font, 12;
    .text-position = 72, $y;
    .say: $micr-line;
}

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

say "Writing a Hancock Whitney micre line: ";
$y -= 36;
constant TRANSIT = chr(0x2446);
constant ON-US   = chr(0x2447);
constant AMOUNT  = chr(0x2448);
constant DASH    = chr(0x2449);


my $mtest = "micr-font-test.pdf";
$pdf.save-as($mtest);
say "See file $mtest";
