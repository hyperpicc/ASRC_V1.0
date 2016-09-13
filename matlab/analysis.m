function analysis( h, fs )

	[r,harmpow,harmfreq] = thd( h, fs, 20 );
	[harmpow,harmfreq]
	
	h = h/2^23;
	figure; thd( h, fs, 20 ); 
	figure; sfdr( h, fs, 512 );
	
end

