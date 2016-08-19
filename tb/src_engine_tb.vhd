LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

library work;
use work.src_pkg.all;
 
ENTITY src_engine_tb IS
END src_engine_tb;
 
ARCHITECTURE behavior OF src_engine_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT src_engine
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         ratio : IN  unsigned(19 downto 0);
         rd_addr : IN  unsigned(19 downto 0);
         rd_init : IN  std_logic;
         o_coe : OUT  signed(23 downto 0);
         o_en : OUT  std_logic;
         o_lr : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal ratio : unsigned(19 downto 0) := (17 => '1', others => '0');
   signal rd_addr : unsigned(19 downto 0) := (others => '0');
   signal rd_init : std_logic := '0';

 	--Outputs
   signal o_coe : signed(23 downto 0);
   signal o_en : std_logic;
   signal o_lr : std_logic;
	
	
   signal rd_coe : signed(23 downto 0) := (others => '0');

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: src_engine PORT MAP (
          clk => clk,
          rst => rst,
          ratio => ratio,
          rd_addr => rd_addr,
          rd_init => rd_init,
          o_coe => o_coe,
          o_en => o_en,
          o_lr => o_lr
        );
		  
	read_process : process( clk )
		file		outfile	: text is out "test/src_engine_tb.txt";
		variable outline	: line;
	begin
		if rising_edge( clk ) then
			if ( o_en and o_lr ) = '1' then
				rd_coe <= o_coe;
				write( outline, to_integer( o_coe ) );
				writeline( outfile, outline );
			end if;
		end if;
	end process;

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      
		wait until rising_edge( clk );
		wait until rising_edge( clk );
		
		rd_init <= '1';
		wait until rising_edge( clk );
		
		rd_init <= '0';
		wait until rising_edge( clk );
		
      wait;
   end process;

END;
