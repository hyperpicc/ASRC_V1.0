library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divider_top is 
	generic (
		DIV_WIDTH	: natural := 26
	);
	port (
		clk			: in  std_logic;
		rst			: in  std_logic;
		
		i_en			: in  std_logic;
		i_divisor	: in  unsigned( DIV_WIDTH-1 downto 0 );
		i_dividend	: in  unsigned( DIV_WIDTH-1 downto 0 );
		
		o_fin			: out std_logic := '0';
		o_remainder	: out unsigned( DIV_WIDTH-1 downto 0 ) := ( others => '0' )
	);
end entity divider_top;

architecture rtl of divider_top is
	constant R_COUNT_MAX : unsigned( 5 downto 0 ) := to_unsigned( DIV_WIDTH + 2, 6 );

	signal a				 : unsigned( DIV_WIDTH   downto 0 ) := ( others => '0' );
	signal acc			 : unsigned( DIV_WIDTH   downto 0 ) := ( others => '0' );
	signal add_op_r	 : unsigned( DIV_WIDTH   downto 0 ) := ( others => '0' );
	signal add_op_u	 : unsigned(  0 downto 0 ) := ( others => '0' );
	alias  add_op		 : std_logic is add_op_u( 0 );
	signal en			 : std_logic := '0';
	signal sum			 : unsigned( DIV_WIDTH   downto 0 ) := ( others => '0' );
	signal count		 : unsigned( 4 downto 0 ) := ( others => '0' );
	signal result		 : unsigned( DIV_WIDTH   downto 0 ) := ( others => '0' );
begin

	add_op_r <= ( others => NOT add_op );

	sum <= acc + ( a XOR add_op_r ) + not( add_op_u );

	process( clk )
	begin
		if rising_edge( clk ) then
			if (rst = '1') then
				a <= ( others => '0' );
			elsif (i_en = '1') then
				if i_divisor = 0 then
					a <= ( others => '1' );
				else 
					a <= '0' & i_divisor;
				end if;
			end if;
		end if;
	end process;

	process( clk )
	begin
		if rising_edge( clk ) then
			if ( rst or i_en ) = '1' then
				acc <= '0' & i_dividend;
			else
				acc <= sum( sum'high-1 downto 0 ) & '0';
			end if;
		end if;
	end process;

	process( clk )
	begin
		if rising_edge( clk ) then
			if rst = '1' then
				add_op <= '0';
			elsif i_en = '1' then
				add_op <= '0';
			else
				add_op <= sum( sum'left );
			end if;
		end if;
	end process;

	process( clk )
	begin
		if rising_edge( clk ) then
			en <= i_en;
		end if;
	end process;

	process( clk )
	begin
		if rising_edge( clk ) then
			if ( i_en or rst ) = '1' then
				count <= ( others => '0' );
			elsif count /= ( R_COUNT_MAX + 1 ) then
				count <= count + 1;
			end if;	  
		end if;
	end process;

	process( clk )
	begin
		if rising_edge( clk ) then
			if ( en or rst ) = '1' then
				result <=  ( others => '0' );
			else
				result <= result( result'length-2 downto 0 ) & not( sum( sum'left ) );
			end if;
		end if;
	end process;

	process( clk )
	begin
		if rising_edge( clk ) then
			o_fin <= '0';
			if rst = '1' then
				o_remainder <= ( others => '0' );
			elsif count = R_COUNT_MAX then
				o_fin <= '1';
				o_remainder <= result( result'length-1 downto 1 );
			end if;
		end if;
	end process;

end architecture rtl;
