TITLE
=====

Usage

Quick Start
===========

    zef install PDF::Lite JSON::Fast
    export CHECKWRITER_ASSETS=$PWD
    raku bin/make-fidelity-check.raku
    raku bin/make-hancock-check.raku

Output
======

* output/fidelity-sample.pdf * output/hancock-sample.pdf

Tweaks
======

Adjust coordinates in the bank JSON and re-run the CLI. Common nudges:

* positions.payee_line (x, y, w) * positions.amount_box (x, y, w, h) * positions.legal_line, positions.memo_line, positions.signature_line * positions.micr.baseline_from_bottom

