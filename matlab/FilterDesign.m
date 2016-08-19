clear;

Hf = FIR;
Hf = downsample( Hf, 4 );
Hf_coe = Hf( 1:4097 );

Hf_coe = fi( Hf_coe, 1, 26, 25 );
f_hf_coe = fopen('~/projects/LAGRANGE/rom/ba_rom_coe_26.txt', 'wt');
for i = 1:length(Hf_coe)
	fprintf(f_hf_coe, '%s\n', hex(Hf_coe(i)));
end;
fclose(f_hf_coe);

