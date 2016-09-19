clear;

CW = 26;

Hf = FD1;
%Hf = downsample( Hf, 4 );
Hf_coe = Hf( 1:4097 );

Hf_coe = fi( Hf_coe, 1, CW, CW-1 );
f_hf_coe = fopen('../../ASRC_V1.0/rtl/src_rom_pkg.vhd', 'wt');

% print header information
fprintf( f_hf_coe, 'library ieee;\n' );
fprintf( f_hf_coe, 'use ieee.std_logic_1164.all;\n' );
fprintf( f_hf_coe, 'use ieee.numeric_std.all;\n\n' );

fprintf( f_hf_coe, 'package src_rom_pkg is\n\n' );
fprintf( f_hf_coe, '\tconstant COE_WIDTH\t: integer := %i;\n', CW );

coe = Hf_coe( 4097 );
fprintf( f_hf_coe, '\tconstant COE_CENTRE\t: signed( %i downto 0 ) := b"%s";\n\n', CW-1, coe.bin );
fprintf( f_hf_coe, '\ttype COE_ROM_TYPE is array( 4095 downto 0 ) of signed( %i downto 0 );\n', CW-1 );

fprintf( f_hf_coe, '\tconstant COE_ROM\t : COE_ROM_TYPE := (\n' );

for i = 4096:-1:1
	coe = Hf_coe( i );
	fprintf(f_hf_coe, '\t\tb"%s"', coe.bin );
	if i > 1
		fprintf(f_hf_coe, ',' );
	end
	fprintf(f_hf_coe, '\n' );
end;

fprintf( f_hf_coe, '\t);\n\n' );

fprintf( f_hf_coe, 'end src_rom_pkg;' );
fclose(f_hf_coe);

