--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:32:44 08/26/2016
-- Design Name:   
-- Module Name:   /home/charlie/work/ASRC_V1.0/ASRC_V1.0/tb/mul_tb.vhd
-- Project Name:  XST
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: mul_20x17
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
 
ENTITY mul_tb IS
END mul_tb;
 
ARCHITECTURE behavior OF mul_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mul_20x17
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         mul_i0 : IN  unsigned(19 downto 0);
         mul_i1 : IN  unsigned(16 downto 0);
         mul_i_en : IN  std_logic;
         mul_o : OUT  unsigned(35 downto 0);
         mul_o_en : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal mul_i0 : unsigned(19 downto 0) := x"AAAAB";
   signal mul_i1 : unsigned(16 downto 0) := (16 => '1', others => '0');
   signal mul_i_en : std_logic := '0';

 	--Outputs
   signal mul_o : unsigned(35 downto 0);
   signal mul_o_en : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mul_20x17 PORT MAP (
          clk => clk,
          rst => rst,
          mul_i0 => mul_i0,
          mul_i1 => mul_i1,
          mul_i_en => mul_i_en,
          mul_o => mul_o,
          mul_o_en => mul_o_en
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
      -- hold reset state for 100 ns.
		wait until rising_edge( clk );
		mul_i_en <= '1';
		wait until rising_edge( clk );
		mul_i_en <= '0';

      -- insert stimulus here 

      wait;
   end process;

END;
