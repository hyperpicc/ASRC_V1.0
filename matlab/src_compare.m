function h = src_compare( fs_i, fs_o, phase )

cw = 26;

Hf1 = FD1;

% 32768 element filter

% 4096 element filter
Hf1 = fi( Hf1, 1, cw, cw-1 ); Hf1 = Hf1.double;

sr = sample_rate( fs_i, fs_o );

phase = fi( phase, 0, 16, 9 );
phase = int32( phase.int );

h1 = [];
ih = [];

for i = phase : sr : 2^22

	% 3pt interpolate 4k el filter
	idx = bitshift( i, -9 ); ih( end+1) = idx;
	fct = double( bitand( i, 2^9 - 1 ) ) / 2^9;
	
	d0 = interp_mul(0.5, ( fct - 1 ), ( fct - 2 )) * filter_lookup( Hf1, idx );
	d1 = interp_mul(-1, fct, ( fct - 2 )) * filter_lookup( Hf1, idx + 1 );
	d2 = interp_mul(0.5, fct, ( fct - 1 )) * filter_lookup( Hf1, idx + 2 );
	
	d3 = fi(d0 + d1 + d2, 1, 26, 25 );
	h1( end + 1 ) = d3.int;
	
end

fvtool( dfilt.dffir( h1 ) )

h = ih;
