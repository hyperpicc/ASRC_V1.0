library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity integrator is
	generic (
		INT_WIDTH	: natural range 8 to 64 := 16;
		INT_GAIN		: natural range 7 to 16 :=  8
	);
	port (
		clk			: in  std_logic;
		
		i				: in  signed( INT_WIDTH-1 downto 0 );
		i_fb			: in  signed( INT_WIDTH-1 downto 0 );
		i_en			: in  std_logic;
		
		o				: out signed( INT_WIDTH-1 downto 0 ) := ( others => '0' );
		o_fb			: out signed( INT_WIDTH-1 downto 0 ) := ( others => '0' );
		o_en			: out std_logic := '0'
		
	);
end integrator;

architecture rtl of integrator is
	constant WIDTH		: natural := INT_WIDTH + INT_GAIN;
	
	-- input adder
	signal i_adder		: signed( WIDTH   downto 0 ) := ( others => '0' );
	
	-- latch i/o and quantiser
	signal latch_i0	: signed( WIDTH-1 downto 0 ) := ( others => '0' );
	signal latch_i		: signed( WIDTH-1 downto 0 ) := ( others => '0' );
	signal latch_o		: signed( WIDTH-1 downto 0 ) := ( others => '0' );
begin

	-- input adder - pad inputs
	i_adder <= ( '0' & i    & to_signed( 0, INT_GAIN ) )	- 
				  ( '0' & latch_o ) + 
				  ( '0' & i_fb & to_signed( 0, INT_GAIN ) );
	
	-- output MSB of input adder to feedback output
	o_fb <= i_adder( WIDTH-1 downto INT_GAIN );
	
	-- output
	o <= latch_o( WIDTH-1 downto INT_GAIN );
	
	-- add gain output to integrator output
	latch_i0 <= SHIFT_RIGHT( i_adder( WIDTH-1 downto 0 ), INT_GAIN ) + latch_o;
	latch_i( WIDTH-1 downto INT_GAIN ) <= latch_i0( WIDTH-1 downto INT_GAIN ) + 1;
	latch_i( INT_GAIN-1 downto 0 ) <= latch_i0( INT_GAIN-1 downto 0 );
	
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
