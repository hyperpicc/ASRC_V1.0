--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:48:29 08/03/2016
-- Design Name:   
-- Module Name:   /home/charlie/projects/ASRC_V1.0/tb/src_mac_tb.vhd
-- Project Name:  ASRC_V1.0
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: src_mac
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY src_mac_tb IS
END src_mac_tb;
 
ARCHITECTURE behavior OF src_mac_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT src_mac
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         i_ratio : IN  unsigned(19 downto 0);
         i_coe : IN  signed(25 downto 0);
         i_data : IN  signed(23 downto 0);
         i_ctrl_norm : IN  std_logic;
         i_ctrl_en : IN  std_logic;
         i_ctrl_acc : IN  std_logic;
         i_ctrl_lr : IN  std_logic;
         o_data : OUT  signed(23 downto 0);
         o_data_en : OUT  std_logic;
         o_data_lr : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal i_ratio : unsigned(19 downto 0) := (others => '0');
   signal i_coe : signed(25 downto 0) := (others => '0');
   signal i_data : signed(23 downto 0) := (others => '0');
   signal i_ctrl_norm : std_logic := '0';
   signal i_ctrl_en : std_logic := '0';
   signal i_ctrl_acc : std_logic := '0';
   signal i_ctrl_lr : std_logic := '0';

 	--Outputs
   signal o_data : signed(23 downto 0);
   signal o_data_en : std_logic;
   signal o_data_lr : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: src_mac PORT MAP (
          clk => clk,
          rst => rst,
          i_ratio => i_ratio,
          i_coe => i_coe,
          i_data => i_data,
          i_ctrl_norm => i_ctrl_norm,
          i_ctrl_en => i_ctrl_en,
          i_ctrl_acc => i_ctrl_acc,
          i_ctrl_lr => i_ctrl_lr,
          o_data => o_data,
          o_data_en => o_data_en,
          o_data_lr => o_data_lr
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
		i_ratio		<= ( others => '0' );
		i_coe			<= ( others => '0' );
		i_data		<= ( others => '0' );
		i_ctrl_norm	<= '0';
		i_ctrl_en	<= '0';
		i_ctrl_acc	<= '0';
		i_ctrl_lr	<= '0';

		wait until rising_edge( clk );
		i_data		<= ( 0 => '1', others => '0' );
		i_coe			<= ( 0 => '1', others => '0' );
		i_ctrl_en	<= '1';

		wait until rising_edge( clk );
		i_ctrl_en	<= '0';
		
		wait;

   end process;

END;
