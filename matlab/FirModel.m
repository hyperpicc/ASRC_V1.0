function h = FirModel( phase, interp_factor, step_sz )
	% so far forward interpolation is modelled 
	% and working reasonably well

	% get filter coefficients
	hf = fi(FIR, 1, 32, 31); 
	hf = hf.int;
	
	% derivative of filter elements	
	hd = diff(hf);
	hd = hd( 1:4096 );

	% Take every second coefficient
	hf_cnt = hf( 4097 );
	hf = hf( 1:4097 );
	
	hf_tmp = [];
	for i = 2:2:length(hf)
		hf_tmp( end + 1 ) = hf( i );
	end;
	hf = hf_tmp;

	h = [];
	for i = phase + 1 + interp_factor : step_sz * 128 : 8193
		
		
		% calculate index for coefficient array
		idx = i;
		if idx >= 4097
			idx = 4097 - ( i - 4097 );
		end
		[dif_idx, dif_frc] = deal(fix(idx), idx-fix(idx) );
	
		m = mod( fix( dif_idx ), 2 );
		if m == 1
			dif_frc = dif_frc - 1;
		end
	
		coe_idx = bitshift( int32( dif_idx ), -1 ) + m;

		if coe_idx == 2049
			h( end + 1 ) = hf_cnt;
		else
			delta0 =  dif_frc * hd( dif_idx );
			h( end + 1 ) = hf( coe_idx ) + delta0;
		end
	end
	h = h / sum(h);

end

