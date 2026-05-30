TITLE
=====

JSON Configuration

Coordinates & Units
===================

All positions are in points (72 pt = 1 inch) measured from the top-left corner. Internally they are converted to PDF's bottom-left origin.

Watermark
=========

```json
"watermark": {"text":"FIDELITY INVESTMENTS","angle":30,"opacity":0.15,"size":24,"x":100,"y":110}
```

Overlays (Logo / Signature)
===========================

```json
"overlays": {
  "logo":      {"enabled": true,  "path": "assets/fidelity-logo.png", "x": 22,  "y": 52,  "w": 40,  "h": 20},
  "signature": {"enabled": true,  "path": "assets/signature.png",     "x": 290, "y": 148, "w": 120, "h": 18}
}
```

MICR Baseline
=============

```json
"positions": { "micr": { "baseline_from_bottom": 16 } }
```

