function analysis( h, Fs )

	hw = fdesign.audioweighting( 'WT,Class', 'A', 1, Fs );
	w = design( hw );

	h = h/2^22;
	%h = filter( w, h );

	[r,harmpow,harmfreq] = thd( h, Fs, 20 );
	[harmpow,harmfreq]
	
	figure; thd( h, Fs, 20 ); 
	figure; sfdr( h, Fs, 2048 );
	x = snr( h, Fs )

end

