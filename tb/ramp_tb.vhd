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
	
	constant	FRQ_I		: real := 44.1;
	constant	FRQ_O		: real := 192.0;
   
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal lock : std_logic := '0';
   signal fs_i_en : std_logic := '0';
   signal fs_o_en : std_logic := '0';

 	--Outputs
   signal fs_i_addr : unsigned(8 downto 0);
   signal ramp_en : std_logic;
   signal ramp_int : unsigned(8 downto 0);
   signal ramp_frc : unsigned(19 downto 0);

	signal ramp_c0			: unsigned( 28 downto 0 ) := ( others => '0' );
	signal ramp_d0			: unsigned( 28 downto 0 ) := ( others => '0' );
	signal abs0				: unsigned( 29 downto 0 ) := ( others => '0' );
	signal ramp_abs0		: unsigned( 28 downto 0 ) := ( others => '0' );
	signal ramp_d0_en		: std_logic := '0';
	
	signal ramp_d1			: unsigned( 28 downto 0 ) := ( others => '0' );
	signal ramp_abs1		: unsigned( 28 downto 0 ) := ( others => '0' );
	
	signal mclk_cnt		: unsigned( 12 downto 0 ) := ( others => '0' );
	signal mclk_cnt_trm	: std_logic := '0';
	signal lock_fs_i		: std_logic := '0';
	signal lock_fs_o		: std_logic := '0';
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
	
	ramp_c0 <= ramp_int & ramp_frc;
	ramp_abs1 <= unsigned( abs( signed( ramp_abs0 ) - signed( ramp_d1 ) ) );
	
	ramp_derivative : process( clk )
	begin
		if rising_edge( clk ) then
			ramp_d0_en <= ramp_en;
			
			if ramp_en = '1' then
				ramp_d0 <= ramp_c0;
				ramp_abs0 <= unsigned( abs( signed( ramp_d0 ) - signed( ramp_c0 ) ) );
				ramp_d1 <= ramp_abs0;
			end if;
			
			if ramp_abs1 < 8  and ramp_abs0 > 16385 then
				lock <= '1';
			end if;
			
		end if;
	end process;
	
	mclk_cnt_trm <= '1' when mclk_cnt = 8191 else '0';
	
	count_process : process( clk )
	begin
		if rising_edge( clk ) then
			mclk_cnt <= mclk_cnt + 1;
			
			if mclk_cnt_trm = '1' then
				lock_fs_i <= '0';
				lock_fs_o <= '0';
			else
				if fs_i_en = '1' then
					lock_fs_i <= '1';
				end if;
				if fs_o_en = '1' then
					lock_fs_o <= '1';
				end if;
			end if;
		end if;
	end process;
	
	o_process : process( clk )
		file		outfile0	: text is out "test/ramp.txt";
		variable outline0	: line;
	begin
		if rising_edge( clk ) then
			if ramp_d0_en = '1' then
				write( outline0, to_integer( ramp_abs1 ) );
				writeline( outfile0, outline0 );
			end if;
		end if;
	end process;
 

   -- Stimulus process
   stim_proc: process
   begin
      wait;
   end process;

END;
