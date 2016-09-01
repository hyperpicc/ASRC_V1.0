library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;

library std;
use std.textio.all;

library work;
use work.src_pkg.all;
use work.sig_gen_pkg.all;
 
ENTITY ramp_filter_tb IS
END ramp_filter_tb;
 
ARCHITECTURE behavior OF ramp_filter_tb IS
	
	constant	FRQ_O		: real := 44.1;
	constant	FRQ_I		: real := 192.0;
	
	signal re_ptr		: real := 0.0;
	signal uf_ptr		: ufixed( 7 downto -20 ) := ( others => '0' );
	signal ptr_int		: unsigned(  8 downto 0 ) := ( others => '0' );
	signal ptr_frc		: unsigned( 19 downto 0 ) := ( others => '0' );
	signal ptr			: unsigned( 28 downto 0 ) := ( others => '0' );
	
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
   
	signal clk			: std_logic := '0';
   signal fs_i_en		: std_logic := '0';
   signal fs_o_en 	: std_logic := '0';
	
	constant m_cnt_init : std_logic := '0';
	signal m_cnt		: unsigned( 14 downto 0 ) := ( 0 => m_cnt_init, others => '0' );

	signal f_input_sub	: unsigned( 30 downto 0 ) := ( others => '0' );
	signal f_strip			: unsigned( 28 downto 0 ) := ( others => '0' );
	signal f_sreg			: unsigned( 28 downto 0 ) := ( others => '0' );
	signal f_latch_in		: unsigned( 28 downto 0 ) := ( others => '0' );
	signal f_latch_out	: unsigned( 28 downto 0 ) := ( others => '0' );
	signal f_output_sub	: unsigned( 28 downto 0 ) := ( others => '0' );

	signal ramp_en			: std_logic := '0';
	signal ramp_c0			: unsigned( 28 downto 0 ) := ( others => '0' );
	signal ramp_d0			: unsigned( 28 downto 0 ) := ( others => '0' );
	signal ramp_abs0		: unsigned( 28 downto 0 ) := ( others => '0' );
	signal ramp_d0_en		: std_logic := '0';
	
	signal ramp_d1			: unsigned( 28 downto 0 ) := ( others => '0' );
	signal ramp_abs1		: unsigned( 28 downto 0 ) := ( others => '0' );
BEGIN

	-- general counters
	ptr <= ptr_int & ptr_frc;
	uf_ptr <= to_ufixed( re_ptr, uf_ptr );
	ptr_frc <= unsigned( std_logic_vector( uf_ptr( -1 downto -20 ) ) );

	count_proc : process( clk )
	begin
		if rising_edge( clk ) then
			
			m_cnt <= m_cnt + 1;
			if fs_i_en = '1' then
				i_cnt <= m_cnt;
				ptr_int <= ptr_int + 1;
				m_cnt <= ( 0 => m_cnt_init, others => '0' );
			end if;
			
			ramp_en <= fs_o_en;
			if fs_o_en = '1' then
				re_ptr <= real( to_integer( m_cnt ) ) / real( to_integer( i_cnt ) );
			end if;
			
		end if;
	end process count_proc;
	
	-- ramp filter
	f_input_sub <= ( "00" & ptr ) - ( "00" & f_latch_out );
	
	f_strip <= f_input_sub( f_strip'range );
	
	f_sreg <= SHIFT_RIGHT( f_strip, 11 ) + 1;
	
	f_latch_in <= f_sreg + f_latch_out;
	
	f_output_sub <= f_latch_out; -- - LPF FEED FORWARD
	
	latch_proc : process( clk )
	begin
		if rising_edge( clk ) then
			
			if ramp_en = '1' then
				
				f_latch_out <= f_latch_in;
			
			end if;
			
		end if;
	end process latch_proc;
	
	-- derivative
	ramp_c0 <= f_output_sub;
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
			
		end if;
	end process;
	
	o_process : process( clk )
		file		outfile0	: text is out "test/ramp_filter.txt";
		variable outline0	: line;
	begin
		if rising_edge( clk ) then
			if ramp_d0_en = '1' then
				write( outline0, to_integer( ramp_abs1 ) );
				writeline( outfile0, outline0 );
			end if;
		end if;
	end process;
	
	-- clock generators
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

END;
