LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

LIBRARY work;
use work.src_pkg.all;
use work.src_rom_pkg.all;
use work.sig_gen_pkg.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;

ENTITY src_interpolator_v2_tb IS
END src_interpolator_v2_tb;

ARCHITECTURE behavior OF src_interpolator_v2_tb IS 
	
	component time_util is
		generic (
			frq_m		: real :=  24576.0 * 4.0;
			frq		: real
		);
		port (
			clk_m		: out std_logic;
			clk		: out std_logic;
			clk_en	: out std_logic;
			clk_lr	: out std_logic
		);
	end component time_util;

	signal clk				: std_logic := '0';
	signal rst				: std_logic := '0';

	signal ctrl_lock		: std_logic := '1';
	signal ctrl_offset	: std_logic := '0';

	signal ratio			: unsigned( 21 downto 0 );

	signal rd_addr			: unsigned( 31 downto 0 ) := ( others => '0' );
	signal rd_addr_int	: unsigned( 8 downto 0 ) := ( others => '0' );
	signal rd_addr_frc	: unsigned( 21 downto 0 );
	signal rd_req			: std_logic := '0';

	signal i_wr_data		: signed( 23 downto 0 ) := ( 23 => '0', others => '1' );
	signal i_wr_addr		: unsigned( 8 downto 0 ) := to_unsigned( 16, 9 );
	signal i_wr_en			: std_logic := '0';
	signal i_wr_lr			: std_logic := '0';

	signal o_data			: signed( 23 downto 0 ) := ( others => '0' );
	signal o_data_en		: std_logic := '0';
	signal o_data_lr		: std_logic := '0';
	
	signal o_coe			: signed( COE_WIDTH-1 downto 0 ) := ( others => '0' );
	signal o_coe_en		: std_logic := '0';
	

	signal rd_run			: std_logic := '0';
	
	 -- Clock period definitions
	 constant clk_period : time := 10 ns;
	 
	constant	FRQ_O		: real := 44.1;
	constant	FRQ_I		: real := 192.0;
	constant IFREQ		: real := 20.0;

	constant ratio_real	: real := FRQ_O / FRQ_I;
	signal   ratio_sfixed: sfixed( 3 downto -21 );
	signal   ratio_limit	: sfixed( 0 downto -21 );
	
	
	constant iratio_real	: real := FRQ_I / FRQ_O;
	signal   iratio_sfixed: sfixed( 3 downto -22 );
	signal	ratio_inc	: unsigned( 25 downto 0 );
	
	shared variable sig0	: SIG_TYPE := sig_type_init;
	impure function gen_sig0 return signed is
	begin
		fetch_sample( sig0 );
		return sig0.sig( 34 downto 11 );
	end function;
	
BEGIN
 
	ratio_sfixed <= to_sfixed( ratio_real, ratio_sfixed );
	ratio_limit <= ( 0 => '1', others => '0' ) when ratio_sfixed( 3 downto 0 ) > 0 else ratio_sfixed( ratio_limit'range );
	ratio <= unsigned( std_logic_vector( ratio_limit ) );
	
	iratio_sfixed <= to_sfixed( iratio_real, iratio_sfixed );
	ratio_inc <= SHIFT_LEFT( unsigned( std_logic_vector( iratio_sfixed ) ), 0 );

	rd_addr_int <= rd_addr( 30 downto 22 );
	rd_addr_frc <= rd_addr( 21 downto  0 );
	
	INST_SRC : src_engine
		generic map (
			COE_WIDTH		=> COE_WIDTH
		)
		port map (
			clk				=> clk,
			rst				=> rst,
			
			ctrl_offset		=> ctrl_offset,
			ctrl_lock		=> '1',
			
			ratio				=> ratio,
			
			rd_addr_int		=> rd_addr_int,
			rd_addr_frc		=> rd_addr_frc,
			rd_req			=> rd_req,
			
			i_wr_data		=> i_wr_data,
			i_wr_addr		=> i_wr_addr,
			i_wr_en			=> i_wr_en,
			i_wr_lr			=> i_wr_lr,
			
			o_data			=> o_data,
			o_data_en		=> o_data_en,
			o_data_lr		=> o_data_lr,
			
			o_coe				=> o_coe,
			o_coe_en			=> o_coe_en
		);
	
	INST_TIME_I : time_util
		generic map (
			frq_m		=> 24576.0 * 4.0,
			frq		=> FRQ_I
		)
		port map (
			clk_m		=> clk,
			clk		=> open,
			clk_en	=> i_wr_en,
			clk_lr	=> i_wr_lr
		);
	
	INST_TIME_O : time_util
		generic map (
			frq_m		=> 24576.0 * 4.0,
			frq		=> FRQ_O
		)
		port map (
			clk_m		=> open,
			clk		=> open,
			clk_en	=> open,
			clk_lr	=> rd_req
		);
	
	i_process : process( clk )
		variable sample	: signed( 23 downto 0 ) := ( others => '0' );
	begin
		if rising_edge( clk ) then
			if i_wr_lr = '1' then
				sample := gen_sig0;
				i_wr_addr <= i_wr_addr + 1;
				i_wr_data <= sample;
			end if;
			
		end if;
	end process;
	
	stim_proc : process( clk )
	begin
		if rising_edge( clk ) then
			if rd_req = '1' then
				rd_addr <= rd_addr + ratio_inc;
			end if;
		end if;
	end process;
	
	read_process : process( clk )
		file		outfile_r	: text is out "test/src_interpolate_r.txt";
		variable outline		: line;
	begin
		if rising_edge( clk ) then
			if o_data_en = '1' then
				if o_data_lr = '1' then
					write( outline, to_integer( o_data ) );
					writeline( outfile_r, outline );
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
