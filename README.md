# Sekvens

A drum machine/step sequencer for Playdate.

## Development

Everything in `Views` should be considered deprecated. Rewrites of these classes are moved to `CoracleViews` once they're properly written. 

## Playdate API issues

* The sequence object won't loop if there's no note in the final step
* LowPass filter kills all audio if adding without a frequency set (even with mix at 0), HighPass doesn't do the same.
