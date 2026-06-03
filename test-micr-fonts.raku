#!/usr/bin/env raku

use PDF::Lite;
use PDF::Font::Loader :load-font;
use PDF::Content::FontObj;

my $mpath = "/home/tbrowde/mydata/tbrowde-home/Monotype-MyFonts/MICR/MICRStd.otf";

use SingleCheck;

#my PDF::Content::FontObj $micr-font = load-font(:file($mpath));

my $pdf = PDF::Lite.new;
my $page = $pdf.add-page;

# desired starting positions
my $y = 700;
my $x = 40;

print-micre-line-style1 :$pdf, :$page, :$x, :$y, :font-path($mpath);

say "Writing a personal check micre line: ";
my $mtest = "micr-font-test.pdf";
$pdf.save-as($mtest);
say "See file $mtest";
