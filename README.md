# ASRC_V1.0

TODO:

Divider - Reduce to remainder calculation only (remove 
quotient calculation portion), should reduce calculation 
time by 50%

ROM Coefficient x Lagrange Coefficient Multiplier -
Currently a 35x35 multiplier, but might be achievable in 
a 35x18 multiplier. This would use 2 less DSP slices,
and then should be able to be implemented in an XC6SL4
without multipliers in fabric.