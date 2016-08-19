clear;

Hf = FIRL;
%Hf = FIR; % needs to work at 64 tap filter

yc = [   16     8     4     2  1 ];
y  = [ 8192 10240 12288 14848 16384 ];

i = 1;
idx = 1;

Hf_coe = [];
Hf_dif = [];
while ( i < 16385 )
	Hf_coe( end + 1 ) = Hf( i );

	if i > y( idx )
		idx = idx + 1;
	end;
	if idx == 6
		idx = 5;
	end;
	i = i + yc( idx );
end;
clear idx y yc;

Hf_coe( end + 1 ) = Hf( 16385 );
Hf_dif = diff(Hf_coe);

idx = [];
idx_n = [];

Hf_coe = fi( Hf_coe, 1, 26, 25 );
Hf_dif = fi( Hf_dif, 1, 26, 25 );
Hf_coe = Hf_coe.int;

log( double( max( Hf_dif.int ) ) )/log( 2 )

for i = 0:256:2^14
    idx( end + 1 ) = i/4;
    
    top = bitshift(i, -9);
    
    if top < 16
        bot = bitshift( i, -4 );  % shift
        
        idx_n( end + 1 ) = bot;
    elseif top < 20
        mask = bitshift( 5, 7 );
        if top < 18
            mask = bitshift( 4, 7 );
        end;
        
        bot = bitor( bitand( bitshift( i, -3 ), 127 ), mask );
        
        idx_n( end + 1 ) = bot;
    elseif top < 24
        if top == 20
            mask = 6;
        elseif top == 21
            mask = 7;
        elseif top == 22
            mask = 8;
        elseif top == 23
            mask = 9;
        end;
        mask = bitshift( mask, 7 );
        
        bot = bitor( bitand( bitshift( i, -2 ), 127 ), mask );
        
        idx_n( end + 1 ) = bot;
    elseif top < 29
        if top == 24
            mask = 5;
        elseif top == 25
            mask = 6;
        elseif top == 26
            mask = 7;
        elseif top == 27
            mask = 8;
        elseif top == 28
            mask = 9;
        end;
        mask = bitshift( mask, 8 );
        
        bot = bitor( bitand( bitshift( i, -1 ), 255 ), mask );
        
        idx_n( end + 1 ) = bot;
    elseif top < 32
        if top == 29
            mask = 5;
        elseif top == 30
            mask = 6;
        elseif top == 31
            mask = 7;
        end;
        mask = bitshift( mask, 9 );
        
        bot = bitor( bitand( bitshift( i,  0 ), 511 ), mask );
        
        idx_n( end + 1 ) = bot;
    else
        idx_n( end + 1 ) = 4096;
    end
    
end

idx_n = [ idx_n fliplr( idx_n( 1:length( idx_n )-1 ) ) ];

idx_n = idx_n + 1;
filt_exp = [];

for i = 1:1:length( idx_n )
    filt_exp( end + 1 ) = Hf_coe( idx_n( i ) );
end;

fvtool( filt_exp/sum(filt_exp) );
clear bot top i mask idx;
