--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:57:23 08/30/2016
-- Design Name:   
-- Module Name:   /home/charlie/work/ASRC_V1.0/ASRC_V1.0/tb/ramp_tb.vhd
-- Project Name:  XST
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ramp_gen
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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY ramp_tb IS
END ramp_tb;
 
ARCHITECTURE behavior OF ramp_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ramp_gen
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         lock : IN  std_logic;
         fs_i_en : IN  std_logic;
         fs_i_addr : OUT  unsigned(8 downto 0);
         fs_o_en : IN  std_logic;
         ramp_en : OUT  std_logic;
         ramp_int : OUT  unsigned(8 downto 0);
         ramp_frc : OUT  unsigned(19 downto 0)
        );
    END COMPONENT;
	
	component time_util is
		generic (
			frq_m		: real :=  24576.0 * 4.0;
			frq		: real :=  192.0
		);
		port (
			clk_m		: out std_logic;
			clk		: out std_logic;
			clk_en	: out std_logic;
			clk_lr	: out std_logic
		);
	end component time_util;
	
	constant	FRQ_O		: real := 192.0;
	constant	FRQ_I		: real := 44.1;
   
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal lock : std_logic := '1';
   signal fs_i_en : std_logic := '0';
   signal fs_o_en : std_logic := '0';

 	--Outputs
   signal fs_i_addr : unsigned(8 downto 0);
   signal ramp_en : std_logic;
   signal ramp_int : unsigned(8 downto 0);
   signal ramp_frc : unsigned(19 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
	
	INST_TIME_I : time_util
		generic map (
			frq		=> FRQ_I
		)
		port map (
			clk_m		=> clk,
			clk		=> open,
			clk_en	=> open,
			clk_lr	=> fs_i_en
		);
	
	INST_TIME_O : time_util
		generic map (
			frq		=> FRQ_O
		)
		port map (
			clk_m		=> open,
			clk		=> open,
			clk_en	=> open,
			clk_lr	=> fs_o_en
		);
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ramp_gen PORT MAP (
          clk => clk,
          rst => rst,
          lock => lock,
          fs_i_en => fs_i_en,
          fs_i_addr => fs_i_addr,
          fs_o_en => fs_o_en,
          ramp_en => ramp_en,
          ramp_int => ramp_int,
          ramp_frc => ramp_frc
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
      wait for 100 ns;	

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
