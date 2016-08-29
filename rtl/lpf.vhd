library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lpf_top is
	generic (
		LPF_WIDTH		: natural range 8 to 64 := 16;
		LPF_PAD			: natural range 5 to 15 :=  9
	);
	port (
		clk				: in  std_logic;
		rst				: in  std_logic;
		
		lpf_in			: in  signed( LPF_WIDTH - 1 downto 0 );
		lpf_in_en		: in  std_logic;
		
		lpf_out			: out signed( LPF_WIDTH - 1 downto 0 ) := ( others => '0' )
	);
end lpf_top;

architecture rtl of lpf_top is
	constant ZERO		: signed( LPF_PAD - 1 downto 0 ) := ( others => '0' );

	signal reg_add		: signed( LPF_WIDTH + LPF_PAD downto 0 ) := ( others => '0' );
	signal reg_shift	: signed( LPF_WIDTH + LPF_PAD downto 0 ) := ( others => '0' );
	signal reg_out		: signed( LPF_WIDTH + LPF_PAD downto 0 ) := ( others => '0' );
	
	signal rst_buf		: std_logic := '0';
	signal rst_stb		: std_logic := '0';
begin
	-- reset strobe - assume synchronous
	rst_stb <= ( rst xor rst_buf ) and not( rst_buf );
	
	reset_process : process( clk )
	begin
		if rising_edge( clk ) then
			rst_buf <= rst;
		end if;
	end process reset_process;
	
	-- lpf function
	lpf_out <= reg_out( reg_out'left - 1 downto reg_out'left - LPF_WIDTH );
	reg_add <= ( '0' & lpf_in & ZERO ) - reg_out;
	reg_shift <= shift_right( reg_add, LPF_PAD );
	
	integrator_process : process( clk )
	begin
		if rising_edge( clk ) then
			if rst_stb = '1' then
				reg_out <= ( others => '0' );
			elsif lpf_in_en = '1' then
				reg_out <= reg_out + reg_shift + 1;
			end if;
		end if;
	end process integrator_process;

end rtl;
