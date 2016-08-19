function sr = sample_rate( fs_i, fs_o )
	
	% rample rate ratio as a double
	sr = fs_i/fs_o;
	
	% apply limiter
	if sr >= 1
		sr = 1;
	end

	sr = sr * 2^16;
	
	% scale and quantise
	sr = fi( sr, 0, 16, 0 );

	% return integer
	sr = int32( sr.int );

end
