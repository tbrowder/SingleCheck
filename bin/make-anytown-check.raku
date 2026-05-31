#!/usr/bin/env raku

use JSON::Fast;

use SingleCheck :render-check, :load-layout;

my %layout = load-layout("config/banks/check-layout-anytown.json");
my %data = %(
        # constant data per account
        addr1 => "JOHN G. AND SALLY D. JOHNSON",
        addr2 => "123 MAIN STREET",
        addr3 => "ANYTOWN, USA 99999",
        micr_routing => "000000000",
        micr_account => "000000000000",
        bank_info => "ANYTOWN CITY BANK",
        
        # data varying per check
        check_number => "2042",
        date => "08/19/2025",
        payee => "Water Works",
        amount_num => "\$ 88.20",

        amount_words => "Eighty-eight and 20/100", # should use the lingua module
        memo => "Acct 778899",
        micr_checkno => "2042" # for real checks this must be unique
);

render-check(
    :outfile("output/anytown-sample.pdf"),
    :layout(%layout),
    :%data,
);

say "Wrote output/anytown-sample-check.pdf";
