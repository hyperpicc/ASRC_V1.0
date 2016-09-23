library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity integrator is
	generic (
		INT_WIDTH	: natural range 8 to 64 := 16;
		INT_GAIN		: natural range 7 to 12 :=  8
	);
	port (
		clk			: in  std_logic;
		
		lock			: in  std_logic;
		lock_evt		: in  std_logic;
		
		i				: in  signed( INT_WIDTH-1 downto 0 );
		i_en			: in  std_logic;
		
		o				: out signed( INT_WIDTH-1 downto 0 ) := ( others => '0' );
		o_fb			: out signed( INT_WIDTH-1 downto 0 ) := ( others => '0' );
		o_en			: out std_logic := '0'
		
	);
end integrator;

architecture rtl of integrator is
	constant WIDTH		: natural := INT_WIDTH + INT_GAIN + 3;
	
	-- input adder
	signal i_adder		: signed( WIDTH   downto 0 ) := ( others => '0' );
	
	-- gain
	signal reg_gain	: unsigned( 3 downto 0 ) := ( others => '0' );
	
	-- latch i/o and quantiser
	signal latch_i0	: signed( WIDTH-1 downto 0 ) := ( others => '0' );
	signal latch_i		: signed( WIDTH-1 downto 0 ) := ( others => '0' );
	signal latch_o		: signed( WIDTH-1 downto 0 ) := ( others => '0' );
begin

	-- input adder - pad inputs
	i_adder <= ( '0' & i & to_signed( 0, INT_GAIN+3 ) ) - ( '0' & latch_o );
	
	-- gain
	reg_gain <= to_unsigned( INT_GAIN, 4 ) when lock = '0' else to_unsigned( INT_GAIN+3, 4 );
	
	-- output MSB of input adder to feedback output
	o_fb <= i_adder( WIDTH-1 downto INT_GAIN+3 );
	
	-- output
	o <= latch_o( WIDTH-1 downto INT_GAIN+3 );
	
	-- add gain output to integrator output
	latch_i0 <= SHIFT_RIGHT( i_adder( WIDTH-1 downto 0 ), to_integer( reg_gain ) ) + latch_o;
	latch_i( WIDTH-1 downto INT_GAIN+3 ) <= latch_i0( WIDTH-1 downto INT_GAIN+3 );
	latch_i( INT_GAIN+2 downto 0 ) <= latch_i0( INT_GAIN+2 downto 0 );
	
	latch_proc : process( clk )
	begin
		if rising_edge( clk ) then
			o_en <= i_en;
			
			if lock_evt = '1' then
				latch_o <= SHIFT_RIGHT( latch_i, 2 );
			elsif i_en = '1' then
				latch_o <= latch_i;
			end if;
		end if;
	end process latch_proc;
	
end rtl;
