function [ hf, hd ] = filter_calc
	
	Hf = FIRL;

	yc = [   16     4     2     1 ];
	y  = [ 8192 12288 15360 16384 ];

	%yc = [   16     8     4     2     1 ];
	%y  = [ 8192 10240 12288 14848 16384 ];

	i = 1;
	idx = 1;

	Hf_coe = [];
	Hf_dif = [];
	while ( i < 16385 )
		Hf_coe( end + 1 ) = Hf( i );

		if i > y( idx )
			idx = idx + 1;
		end;
		if idx > length( yc )
			idx = length( yc );
		end;
		i = i + yc( idx );
	end;

	Hf_coe( end + 1 ) = Hf( 16385 );
	
	Hf_coe2 = [];
	for i = 2:2:length(Hf_coe)
		Hf_coe2( end + 1 ) = Hf_coe( i );
	end;
	Hf_coe2( end + 1 ) = Hf_coe( 4097 );
	Hf_dif = diff(Hf_coe);
	Hf_coe = Hf_coe2;

	Hf_coe = fi( Hf_coe, 1, 24, 23 );
	Hf_dif = fi( Hf_dif, 1, 24, 23 );
	
	log( double( max( abs( Hf_dif.int ) ) ) )/log( 2 );
	
	hf = Hf_coe;
	hd = Hf_dif;
	
end
