function hf = filter_calc_int( fs_i, fs_o, phase )

	% compressed coefficient and difference arrays
	[ hc, hd ] = filter_calc;
	hc = int32( hc.int );
	hd = int32( hd.int );
	
	% quantised sample rate ratio calculation
	sr = sample_rate( fs_i, fs_o );

	% set the phase, 0 ... 63.99999999
	% 6 bits integer, 10 bits fraction
	phase = fi( phase, 0, 16, 10 );
	phase = int32( phase.int );

	% to store outputs
	hf = [];
	
	% use this loop to test the complete range of the filter
	% and the quality of the interpolator
	%for i = 0 : 2^7 : 2^22

	% increment by the sample rate ratio, start at phase
	for i = phase : sr : 2^22
		
		% get the difference index, interpolation factor, and centre select
		[ dif_idx, intrp, cntr ] = pla_sim( i );
		
		% coefficient index is difference index right shifted by one
		coe_idx = bitshift( dif_idx, -1 );
		
		% zero referenced
		coe = hc( coe_idx + 1 );
		dif = hd( dif_idx + 1 );

		if cntr == 1
			% take centre tap, difference is zero
			coe = hc( end );
			dif = 0;
		else
			% interpolate the difference, cast to int
			dif = dif * intrp;
		end;

		% append to coefficient array
		hf( end + 1 ) = coe + bitshift( dif, -0 );

	end

	% normalise
	%hf = hf / sum( hf );

end
