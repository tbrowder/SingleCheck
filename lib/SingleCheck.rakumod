unit module SingleCheck;

use PDF::API6;
use PDF::Page;
use PDF::Font::Loader :load-font;
use PDF::Content::FontObj;
use JSON::Fast;
use Text::Utils :strip-comment;
use SingleCheck::FontUtils;

# adjust vertical setting by using
# origin at top-left corner of
# the page and positive y down
sub _pdf-y($page, $y) { 
    $page.height - $y 
}

sub _hline($page, :$x!, :$y!, :$w!, :$stroke = 0.5) {
    $page.graphics: {
        .LineWidth = $stroke; 
        .MoveTo($x, _pdf-y($page, $y)); .LineTo($x + $w, _pdf-y($page, $y));
        .Stroke;
    }
}

sub _rect($page, :$x!, :$y!, :$w!, :$h!, :$stroke = 0.5) {
    $page.graphics: {
        .LineWidth = $stroke;
        .Rectangle($x, _pdf-y($page, $y) - $h, $w, $h);
        .Stroke;
    }
}

sub _text(
    $pdf,
    $page, 
    Str $txt, 
    :$x!, :$y!, 
    :$core-font = 'Helvetica', 
    :$size = 10,
) {
    my $f = get-font($pdf, :$core-font);
    $page.text: {
        .font = $f, $size;

        .text-position = $x, _pdf-y($page, $y);

        .say: $txt;
    }
}

sub load-layout(Str $path --> Hash:D) is export(:load-layout) {
    from-json $path.IO.slurp;
}

sub render-check(
    Str :$outfile!, # = "output/sample-check.pdf",
    Hash :$layout!,
         :%data!,
         :$debug,

=begin comment
    :%data = Hash[Str,Str].new(
        addr1 => "JOHN G. AND SALLY D. JOHNSON",
        addr2 => "123 MAIN STREET",
        addr3 => "ANYTOWN, USA 99999",
        check_number => "1001",
        date => "____/____/______",
        payee => "________________________________",
        amount_num => "",
        amount_words => "______________________________________________",
        memo => "",
        bank_info => "LOCAL BANK, ANYTOWN, USA",
        micr_routing => "000000000",
        micr_account => "0000000000",
        micr_checkno => "1001"
    ),
=end comment
) is export(:render-check) {

    my $dir = $outfile.IO.dirname;
    $dir.IO.mkdir unless $dir.IO.e;

    my $w = $layout<page><width>;
    my $h = $layout<page><height>;
    my $pdf = PDF::Lite.new(:page-size($w, $h));

    my $page = $pdf.add-page;

    my %p  = $layout<positions>;
    my %f  = $layout<fonts>;
    my %ln = $layout<lines> // {};
    my %wm = $layout<watermark> // {};
    my %ov = $layout<overlays>  // {};

=begin comment
# TODO no such ops!!
    # light background
    $page.graphics: {
        #.fill-color(0.98, 0.99, 1.0);
        .Rectangle(0, 0, $page.width, $page.height);
        .fill;
    }
=end comment

    # watermark
    if %wm && (%wm<text> // '').chars {
        my $rad = +(%wm<angle> // 30) * pi / 180;
        my $size = +(%wm<size> // (%f<watermark> // 22));
        my $x = +(%wm<x> // 100);
        my $y = +(%wm<y> // 110);
        my $opacity = +(%wm<opacity> // 0.15);
        my $wfont = get-font $pdf, :core-font('Helvetica-Bold');

        $page.gfx.graphics: -> $gfx {
            $gfx.graphics: {
                #.fill-alpha($opacity);
                .transform: :rotate($rad), :translate($x, _pdf-y($page, $y));
                .text: {
                    .font = $wfont, $size;
                    .text-position = 0, 0;
                    .say: %wm<text>;
                }
            }
        }

        =begin comment
        $page.graphics: {
            .save;
            .fill-alpha($opacity);
            .transform: :rotate($rad), :translate($x, _pdf-y($page, $y));
        }
        $page.text: {
            .font($wfont, $size);
            .move-text-position(0, 0);
            .show-text(%wm<text>);
        }
        $page.graphics: { .restore; }
        =end comment
    }

    # address block
    my $ax = %p<addr_block><x>;
    my $ay = %p<addr_block><y>;
    my $leading = %p<addr_block><leading> // 11;
    for ($%data<addr1>, $%data<addr2>, $%data<addr3>).grep(*.so).kv -> $i, $line {
        _text($pdf, $page, $line, 
              :x($ax), :y($ay + $i * $leading), :core-font('Helvetica'), :size(%f<info>)
             );
    }

    # headings and lines
    _text($pdf, $page, $%data<check_number>, :x(%p<check_number><x>), :y(%p<check_number><y>), 
          :core-font('Helvetica'), :size(%f<field>));
    _text($pdf, $page, "Date:", :x(%p<date_label><x>), :y(%p<date_label><y>), 
          :core-font('Times-Roman'), :size(%f<label>));
    _hline($page, :x(%p<date_line><x>), :y(%p<date_line><y>), :w(%p<date_line><w>), 
           :stroke(%ln<stroke> // 0.5));

    _text($pdf, $page, "Pay to the Order of", :x(%p<payee_label><x>), :y(%p<payee_label><y>), 
          :core-font('Times-Roman'), :size(%f<label>));
    _hline($page, :x(%p<payee_line><x>), :y(%p<payee_line><y>), :w(%p<payee_line><w>), 
           :stroke(%ln<stroke> // 0.5));

    _rect($page, :x(%p<amount_box><x>), :y(%p<amount_box><y>), :w(%p<amount_box><w>), 
          :h(%p<amount_box><h>), :stroke(%ln<stroke> // 0.5));

    _hline($page, :x(%p<legal_line><x>), :y(%p<legal_line><y>), :w(%p<legal_line><w>), 
           :stroke(%ln<stroke> // 0.5));
    _text($pdf, $page, "Dollars", :x(%p<dollars_word><x>), :y(%p<dollars_word><y>), 
          :core-font('Times-Roman'), :size(%f<label>));

    _text($pdf, $page, $%data<bank_info>, :x(%p<bank_info><x>), :y(%p<bank_info><y>), 
          :core-font('Helvetica'), :size(%f<info>));

    _text($pdf, $page, "For", :x(%p<memo_label><x>), :y(%p<memo_label><y>), 
          :core-font('Times-Roman'), :size(%f<label>));
    _hline($page, :x(%p<memo_line><x>), :y(%p<memo_line><y>), :w(%p<memo_line><w>), 
           :stroke(%ln<stroke> // 0.5));
    _hline($page, :x(%p<signature_line><x>), :y(%p<signature_line><y>), 
           :w(%p<signature_line><w>), :stroke(%ln<stroke> // 0.5));

    _text($pdf, $page, $%data<payee>, :x(%p<payee_line><x> + 2), :y(%p<payee_line><y> - 2), 
          :core-font('Helvetica'), :size(%f<field>));
    _text($pdf, $page, $%data<amount_num>, :x(%p<amount_box><x> + 4), :y(%p<amount_box><y> - 2),
           :core-font('Helvetica-Bold'), :size(%f<amount_box>));
    _text($pdf, $page, $%data<amount_words>, :x(%p<legal_line><x> + 2), 
          :y(%p<legal_line><y> - 2), :core-font('Helvetica'), :size(%f<field>));
    _text($pdf, $page, $%data<memo>, :x(%p<memo_line><x> + 2), :y(%p<memo_line><y> - 2), 
          :core-font('Helvetica'), :size(%f<field>));
    _text($pdf, $page, $%data<date>, :x(%p<date_line><x> + 2), :y(%p<date_line><y> - 2), 
          :core-font('Helvetica'), :size(%f<field>));

    # overlays: draw image if available, else a labeled guide box
    for <logo signature> -> $k {
        my %cfg = %ov{$k} // next;
        next unless %cfg<enabled>;
        my $path = %cfg<path> // "";
        my $x = +(%cfg<x> // 0);
        my $y = +(%cfg<y> // 0);
        my $w = +(%cfg<w> // 40);
        my $h = +(%cfg<h> // 20);

        my $drawn = False;
        if $path.chars and $path.IO.e {
            try {
                my $img = $page.image($path);
                $page.graphics: {
                    .save;
                    .translate($x, _pdf-y($page, $y) - $h);
                    .image($img, :$w, :$h);
                    .restore;
                }
                $drawn = True;
            }
            CATCH { default { $drawn = False } }
        }

        if !$drawn {
            _rect($page, :x($x), :y($y), :w($w), :h($h));
            _text($pdf, $page, uc($k) ~ " HERE", :x($x + 2), :y($y + $h - 4), 
                  :core-font('Helvetica'), :size(6));
        }
    }

    # MICR placeholder (Courier). Adjust baseline with positions.micr.baseline_from_bottom
    my $micr = ":{$%data<micr_routing>}:{$%data<micr_account>} {$%data<micr_checkno>}";
    my $baseline = %p<micr><baseline_from_bottom> // 16;
    
    # check for access to micre fonts
    my ($mfont, $mfil);
    my $ffil = "$*HOME/\.SingleCheck/font-files\.list".IO // '';
    if $ffil.IO.e {
        # read to find the mfont path
        if 1 or $debug {
            say "DEBUG: found user's list of font files: '$ffil'";
        }
        my ($code);
        for $ffil.IO.lines -> $line is copy {
            $line = strip-comment $line;
            next unless $line ~~ /\S/;
            # two parts
            # code font-file-path
            my @words = $line.words;
            $code = @words.head;
            $mfil = @words.tail;
            
        }
        if 1 or $debug {
            say "DEBUG: found micre font file: '$mfil'";
        }
        $mfont = get-font $pdf, :font-file($mfil);
    }
    else {
        if 1 or $debug {
            say "DEBUG: did not find micre font file";
        }
        # alternate font
        $mfont = get-font $pdf, :core-font('Courier');
    }

    if 1 or $debug {
        say "DEBUG: \$micr text: '$micr'";
    }

    $page.text: {
        .font = $mfont, %f<micr>;
        .text-position = 16, $baseline;
        .say: $micr;
    }

    $pdf.save-as($outfile);
}
