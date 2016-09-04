library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
ENTITY divider_tb IS
END divider_tb;
 
ARCHITECTURE behavior OF divider_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT divider_top
	 GENERIC (
		DIV_WIDTH	: natural := 20
	 );
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         i_en : IN  std_logic;
         i_divisor : IN  unsigned(19 downto 0);
         i_dividend : IN  unsigned(19 downto 0);
         o_fin : OUT  std_logic;
         o_remainder : OUT  unsigned(19 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal i_en : std_logic := '0';
   signal i_divisor : unsigned(19 downto 0) := (others => '0');
   signal i_dividend : unsigned(19 downto 0) := (others => '0');

 	--Outputs
   signal o_fin : std_logic;
   signal o_remainder : unsigned(19 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: divider_top
	PORT MAP (
          clk => clk,
          rst => rst,
          i_en => i_en,
          i_dividend => i_dividend,
          i_divisor => i_divisor,
          o_fin => o_fin,
          o_remainder => o_remainder
        );

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
		i_dividend <= x"0000A";
		i_divisor  <= x"0000F";
		i_en		  <= '1';
		
		wait until rising_edge( clk );
		i_en		  <= '0';
		
      wait;
   end process;

END;
