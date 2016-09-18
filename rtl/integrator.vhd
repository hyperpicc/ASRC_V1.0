library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity integrator is
	generic (
		INT_WIDTH	: natural range 8 to 64 := 16;
		INT_GAIN		: natural range 5 to 11 :=  8
	);
	port (
		clk			: in  std_logic;
		
		i				: in  signed( INT_WIDTH-1 downto 0 );
		i_os			: in  signed( INT_WIDTH-1 downto 0 );
		i_fb			: in  signed( INT_WIDTH-1 downto 0 );
		i_en			: in  std_logic;
		
		o				: out signed( INT_WIDTH-1 downto 0 ) := ( others => '0' );
		o_fb			: out signed( INT_WIDTH-1 downto 0 ) := ( others => '0' );
		o_en			: out std_logic := '0'
		
	);
end integrator;

architecture rtl of integrator is
	signal i_sub		: signed( INT_WIDTH   downto 0 ) := ( others => '0' );
	signal strip		: signed( INT_WIDTH-1 downto 0 ) := ( others => '0' );
	signal sreg			: signed( INT_WIDTH-1 downto 0 ) := ( others => '0' );
	signal latch_i		: signed( INT_WIDTH-1 downto 0 ) := ( others => '0' );
	signal latch_o		: signed( INT_WIDTH-1 downto 0 ) := ( others => '0' );
begin

	i_sub <= ( '0' & i ) + ( '0' & latch_o ) + ( '0' & i_fb );
	
	strip <= i_sub( INT_WIDTH-1 downto 0 );
	
	latch_i <= -SHIFT_RIGHT( strip, INT_GAIN ) + latch_o + i_os;
	
	o <= latch_o;
	
	o_fb <= strip;
	
	latch_proc : process( clk )
	begin
		if rising_edge( clk ) then
			o_en <= i_en;
			
			if i_en = '1' then
				latch_o <= latch_i;
			end if;
		end if;
	end process latch_proc;
	
end rtl;

