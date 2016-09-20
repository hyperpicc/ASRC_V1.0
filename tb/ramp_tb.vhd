library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library work;
use work.src_pkg.all;
use work.sig_gen_pkg.all;
 
ENTITY ramp_tb IS
END ramp_tb;
 
ARCHITECTURE behavior OF ramp_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
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
	constant	FRQ_I		: real := 192.0;
   
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal ratio_lock : std_logic := '0';
   signal ramp_lock : std_logic := '0';
   signal fs_i_en : std_logic := '0';
   signal fs_i_clk : std_logic := '0';
   signal fs_o_en : std_logic := '0';
   signal fs_o_clk : std_logic := '0';

 	--Outputs
   signal fs_i_addr : unsigned(8 downto 0);
   signal ramp_en : std_logic;
   signal ramp_int : unsigned(8 downto 0);
   signal ramp_frc : unsigned(19 downto 0);
   signal ramp_dx : unsigned(8 downto 0);
   signal ratio : unsigned(19 downto 0);

	signal o_dif : unsigned( fs_i_addr'range );
BEGIN
	
	INST_TIME_I : time_util
		generic map (
			frq		=> FRQ_I
		)
		port map (
			clk_m		=> clk,
			clk		=> fs_i_clk,
			clk_en	=> open,
			clk_lr	=> fs_i_en
		);
	
	INST_TIME_O : time_util
		generic map (
			frq		=> FRQ_O
		)
		port map (
			clk_m		=> open,
			clk		=> fs_o_clk,
			clk_en	=> open,
			clk_lr	=> fs_o_en
		);
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ramp_gen PORT MAP (
          clk => clk,
          rst => rst,
          ratio_lock => ratio_lock,
			 ramp_lock => ramp_lock,
          fs_i_en => fs_i_en,
          fs_i_addr => fs_i_addr,
          fs_o_en => fs_o_en,
          ramp_en => ramp_en,
          ramp_int => ramp_int,
          ramp_frc => ramp_frc,
          ramp_dx => ramp_dx
        );
		  
	rtu: ratio_gen 
		port map (
			clk				=> clk,
			rst				=> rst,
			ratio_lock		=> ratio_lock,
			
			fs_i_clk		   => fs_i_clk,
			fs_i_en			=> fs_i_en,
			fs_o_clk			=> fs_o_clk,
			fs_o_en			=> fs_o_en,
			
			ratio				=> ratio
		);
		
	o_process : process( clk )
		variable dif : unsigned( fs_i_addr'range );
		file		outfile0	: text is out "test/ramp_fsi.txt";
		variable outline0	: line;
	begin
		if rising_edge( clk ) then
			if ramp_en = '1' then
				dif := fs_i_addr - ramp_int;
				o_dif <= dif;
				write( outline0, to_integer( dif ) );
				writeline( outfile0, outline0 );
			end if;
		end if;
	end process;

END;
