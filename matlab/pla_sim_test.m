
idx = [];
interp = [];
cntr = [];
phase = [];

for i = 0*2^11:128 * 2^8:2^22
	[ l_idx, l_interp, l_cntr, l_phase ] = pla_sim( i );
	idx( end + 1 ) = l_idx;
	interp( end + 1 ) = l_interp;
	cntr( end + 1 ) = l_cntr;
	phase( end + 1 ) = l_phase;
end

idx;
