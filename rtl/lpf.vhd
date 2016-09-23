library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lpf_top is
	generic (
		LPF_WIDTH	: natural range 8 to 64 := 16;
		LPF_GAIN		: natural range 5 to 12 :=  8
	);
	port (
		clk			: in  std_logic;
		
		lock			: in  std_logic;
		lock_evt		: in  std_logic;
		
		lpf_in		: in  signed( LPF_WIDTH - 1 downto 0 );
		lpf_in_en	: in  std_logic;
		
		lpf_out		: out signed( LPF_WIDTH - 1 downto 0 ) := ( others => '0' )
	);
end lpf_top;

architecture rtl of lpf_top is
	constant WIDTH		: natural := LPF_WIDTH + LPF_GAIN + 3;
	constant ZERO		: signed( LPF_GAIN + 2 downto 0 ) := ( others => '0' );
	
	-- lock gate
	signal lock_en		: std_logic := '0';

	signal reg_add		: signed( WIDTH downto 0 ) := ( others => '0' );
	signal reg_shift	: signed( WIDTH downto 0 ) := ( others => '0' );
	signal reg_in		: signed( WIDTH downto 0 ) := ( others => '0' );
	signal reg_out		: signed( WIDTH downto 0 ) := ( others => '0' );
	signal reg_gain	: unsigned( 3 downto 0 ) := ( others => '0' );
begin
	-- lock gating
	lock_en <= ( lock xor lock_evt ) and lock;
	
	-- lpf function
	lpf_out <= reg_out( reg_out'left - 1 downto reg_out'left - LPF_WIDTH );
	reg_add <= signed( '0' & lpf_in & ZERO ) - reg_out;
	reg_shift <= SHIFT_RIGHT( reg_add, to_integer( reg_gain ) );
	
	reg_gain <= to_unsigned( LPF_GAIN, 4 ) when lock_en = '0' else to_unsigned( LPF_GAIN + 3, 4 );
	reg_in <= reg_out + reg_shift + 1;
	
	integrator_process : process( clk )
	begin
		if rising_edge( clk ) then
			if lock_evt = '1' then
				reg_out <= SHIFT_LEFT( reg_in, 3 );
			elsif lpf_in_en = '1' then
				reg_out <= reg_in;
			end if;
		end if;
	end process integrator_process;

end rtl;
