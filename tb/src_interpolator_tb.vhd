LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

LIBRARY work;
use work.src_pkg.all;
use work.src_rom_pkg.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;
 
ENTITY src_interpolator_tb IS
END src_interpolator_tb;
 
ARCHITECTURE behavior OF src_interpolator_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT src_interpolator
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         i_ratio : IN  unsigned(17 downto 0);
         i_ratio_init : IN  unsigned(17 downto 0);
         i_en : IN  std_logic;
         o_coe : OUT  signed(COE_WIDTH-1 downto 0);
         o_fin : OUT  std_logic;
         o_en : OUT  std_logic;
         o_acc : OUT  std_logic;
         o_lr : OUT  std_logic;
         o_norm : OUT  std_logic
        );
    END COMPONENT;
    
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal i_ratio : unsigned(17 downto 0) := ( 17 => '1', others => '0' );
   signal i_ratio_init : unsigned(17 downto 0) := (others => '0');
   signal i_en : std_logic := '0';

 	--Outputs
   signal o_coe : signed(COE_WIDTH-1 downto 0);
   signal o_fin : std_logic;
   signal o_en : std_logic;
   signal o_acc : std_logic;
   signal o_lr : std_logic;
   signal o_norm : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
	constant	FRQ_O			: real := 44.1;
	constant	FRQ_I			: real := 245.349867349862;
	
	constant ratio_real	: real := FRQ_O / FRQ_I;
	signal   ratio_sfixed: sfixed( 3 downto -17 );
	signal   ratio_limit	: sfixed( 0 downto -17 );
BEGIN
 
	ratio_sfixed <= to_sfixed( ratio_real, ratio_sfixed );
	ratio_limit <= ( 0 => '1', others => '0' ) when ratio_sfixed( 3 downto 0 ) > 0 else ratio_sfixed( ratio_limit'range );
	i_ratio <= unsigned( std_logic_vector( ratio_limit ) );
	i_ratio_init <= "000000000000000011";

	-- Instantiate the Unit Under Test (UUT)
   uut: src_interpolator PORT MAP (
          clk => clk,
          rst => rst,
          i_ratio => i_ratio,
          i_ratio_init => i_ratio_init,
          i_en => i_en,
          o_coe => o_coe,
          o_fin => o_fin,
          o_en => o_en,
          o_acc => o_acc,
          o_lr => o_lr,
          o_norm => o_norm
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;

	read_process : process( clk )
		file		outfile	: text is out "test/src_engine.txt";
		variable outline	: line;
	begin
		if rising_edge( clk ) then
			if ( o_en and o_lr ) = '1' then
				write( outline, to_integer( o_coe ) );
				writeline( outfile, outline );
			end if;
		end if;
	end process;

   -- Stimulus process
   stim_proc: process
   begin
      wait until rising_edge( clk );
		
		i_en <= '0';
      wait until rising_edge( clk );
		
		i_en <= '1';
      wait until rising_edge( clk );
		
		i_en <= '0';
      wait until rising_edge( clk );
		
      wait;
   end process;

END;
