Hf = FIR;

Hf_coe = Hf( 1:4097 );
Hf_dif = diff( Hf_coe );

Hf_coe2 = [];
for i = 2:2:length(Hf_coe)
	Hf_coe2( end + 1 ) = Hf_coe( i );
end;
Hf_coe2( end + 1 ) = Hf_coe( 4097 );

Hf_coe = Hf_coe2;
clear Hf_coe2;

Hf_coe = fi( Hf_coe, 1, 24, 23 );
Hf_dif = fi( Hf_dif, 1, 24, 23 );

hc = hf_coe.int;
hd = hf_dif.int;

clear hf_coe hf_dif;
