function [ oindex, ointrp, ocntr ] = pla_sim( index )
	
	% set maximum value for the index
	init = uint32( index );
	if index > 2^22
		init = 2^22;
	end
	
	% fold address if greater than centre address
	if init > 2^21
		init = 2^21 - ( init - 2^21 );
	end
	
	% most significant bits of address folder determine
	% how much compression is applied
	phase = bitshift( init, -16 );
	
	% simulate the address folder
	% centre coefficient flag
	ocntr = 0;
	if init == 2^21
		ocntr = 1;
		oindex = 0;
		ointrp = 0;
		return
	end

	if phase < 16
		shift_cnt = 4;
		shift_pla = bitshift( phase, -2 );
	
	elseif phase < 24
		shift_cnt = 2;
		
		shift_pla = 4 + bitand( phase, 7 );
		
	elseif phase < 30
		shift_cnt = 1;

		shift_pla = 12 + 2*( phase - 24 );
		shift_pla = bitor( shift_pla, bitand( bitshift( init, -15 ), 1 ) );

	elseif phase == 30
		shift_cnt = 0;
		shift_pla = 6 * 4;
		shift_pla = bitor( shift_pla, bitand( bitshift( init, -14 ), 3 ) );

	elseif phase == 31
		shift_cnt = 0;
		shift_pla = 7 * 4;
		shift_pla = bitor( shift_pla, bitand( bitshift( init, -14 ), 3 ) );

	end
	
	shift_reg = init * 16;
	shift_reg = bitand( bitshift( shift_reg, -shift_cnt ), 2^18 - 1 );
	
	oindex = bitshift( shift_pla, 7 );
	oindex = bitor( oindex, bitshift( shift_reg, -11 ) );

	ointrp = double( bitshift( bitand( shift_reg, 2^11 - 1 ), 0 ) );
	ointrp = ointrp/2^11;

	bget = bitget( oindex, 1 );
	if bget == 0
		ointrp = ointrp - 1;
	end

