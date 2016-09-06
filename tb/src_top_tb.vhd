LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library std;
use std.textio.all;

library work;
use work.sig_gen_pkg.all;

ENTITY src_top_tb IS
END src_top_tb;

ARCHITECTURE behavior OF src_top_tb IS
	constant MCLK		: real := 24576.0;
	constant	FRQ_I		: real := 44.1;
	constant	FRQ_O		: real := 96.0;
	constant IFREQ		: real := 1.0;

	component src_top is
		port (
			clk			: in  std_logic;
			rst			: in  std_logic;
			
			ctrl_lock	: out std_logic := '0';
			ctrl_offset	: in  std_logic := '0';
			
			fs_i_en		: in  std_logic;
			fs_i_clk		: in  std_logic;
			fs_i_lr		: in  std_logic;
			fs_i_dat		: in  signed( 23 downto 0 );
			
			fs_o_req		: in  std_logic;
			fs_o_en		: out std_logic := '0';
			fs_o_clk		: in  std_logic;
			fs_o_lr		: out std_logic := '0';
			fs_o_dat		: out signed( 23 downto 0 ) := ( others => '0' )
		);
	end component src_top;
	
	component time_util is
		generic (
			frq_m		: real :=  MCLK * 4.0;
			frq		: real :=  44.1
		);
		port (
			clk_m		: out std_logic;
			clk		: out std_logic;
			clk_en	: out std_logic;
			clk_lr	: out std_logic
		);
	end component time_util;
	
	shared variable sig0	: SIG_TYPE := sig_type_init;
	
	impure function gen_sig0 return signed is
	begin
		fetch_sample( sig0 );
		return sig0.sig( 34 downto 11 );
	end function;
	
	signal clk				: std_logic := '0';
	signal rst				: std_logic := '0';
	
	signal ctrl_lock		: std_logic := '0';
	signal ctrl_offset	: std_logic := '0';
		
	signal fs_i_clk		: std_logic := '0';
	signal fs_i_en			: std_logic := '0';
	signal fs_i_lr			: std_logic := '0';
	signal fs_i_dat		: signed( 23 downto 0 ) := ( others => '0' );
	
	signal fs_o_req		: std_logic := '0';
	signal fs_o_en			: std_logic := '0';
	signal fs_o_clk		: std_logic := '0';
	signal fs_o_lr			: std_logic := '0';
	signal fs_o_dat		: signed( 23 downto 0 ) := ( others => '0' );
BEGIN
	INST_ASRC : src_top
		port map (
			clk			=> clk,
			rst			=> rst,
			
			ctrl_lock	=> ctrl_lock,
			ctrl_offset	=> ctrl_offset,
			
			fs_i_en		=> fs_i_en,
			fs_i_clk		=> fs_i_clk,
			fs_i_lr		=> fs_i_lr,
			fs_i_dat		=> fs_i_dat,
			
			fs_o_req		=> fs_o_req,
			fs_o_en		=> fs_o_en,
			fs_o_clk		=> fs_o_clk,
			fs_o_lr		=> fs_o_lr,
			fs_o_dat		=> fs_o_dat
		);
	
	INST_TIME_I : time_util
		generic map (
			frq		=> FRQ_I
		)
		port map (
			clk_m		=> clk,
			clk		=> fs_i_clk,
			clk_en	=> fs_i_en,
			clk_lr	=> fs_i_lr
		);
	
	INST_TIME_O : time_util
		generic map (
			frq		=> FRQ_O
		)
		port map (
			clk_m		=> open,
			clk		=> fs_o_clk,
			clk_en	=> open,
			clk_lr	=> fs_o_req
		);

	i_process : process( clk )
		variable sample	: signed( 23 downto 0 ) := ( others => '0' );
	begin
		if rising_edge( clk ) then
			if fs_i_en = '1' then
				if fs_i_lr = '1' then
					sample := gen_sig0;
					fs_i_dat <= sample;
				else
					fs_i_dat <= SHIFT_RIGHT( sample, 16 );
				end if;
			end if;
		end if;
	end process;
	
	o_process : process( clk )
		file		outfilel	: text is out "test/src_l.txt";
		file		outfiler	: text is out "test/src_r.txt";
		variable outline0	: line;
	begin
		if rising_edge( clk ) then
			if fs_o_en = '1' then
				write( outline0, to_integer( fs_o_dat ) );
				if fs_o_lr = '1' then
					writeline( outfiler, outline0 );
				else
					writeline( outfilel, outline0 );
				end if;
			end if;
		end if;
	end process;
	
	config_process : process
	begin
		sig0.freq := IFREQ;
		set_rate( FRQ_I );
		wait;
	end process;
	
END;
