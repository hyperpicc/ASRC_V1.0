library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.src_pkg.all;

entity ramp_gen is
	port (
		clk			: in  std_logic;
		rst			: in  std_logic;
		ramp_lock	: out std_logic := '0';
		
		ratio			: in unsigned( 19 downto 0 );
		ratio_lock	: in  std_logic;
		
		fs_i_en		: in  std_logic;
		fs_i_addr	: out unsigned(  8 downto 0 ) := ( others => '0' );
		fs_o_en		: in  std_logic;
		
		ramp_en		: out std_logic := '0';
		ramp_int		: out unsigned(  8 downto 0 ) := ( others => '0' );
		ramp_frc		: out unsigned( 19 downto 0 ) := ( others => '0' );
		ramp_dx		: out unsigned(  8 downto 0 ) := ( others => '0' )
	);
end ramp_gen;

architecture rtl of ramp_gen is
	signal wr_addr		: unsigned( 14 downto 0 ) := ( others => '0' );
	
	signal rf_en		: std_logic := '0';
	signal lock_en		: std_logic := '0';
	signal rf_input	: unsigned( 34 downto 0 ) := ( others => '0' );
	signal rf_output	: unsigned( 28 downto 0 ) := ( others => '0' );
	
	signal ramp_dx_o	: unsigned( ramp_dx'range ) := ( others => '0' );
begin
		
	fs_i_addr <= wr_addr( fs_i_addr'range );
	
	ramp_int  <= rf_output( 28 downto 20 );
	ramp_frc  <= rf_output( 19 downto  0 );
	
	ramp_en <= lock_en;
	ramp_dx <= ramp_dx_o;

	BLOCK_GENERATE : block
		signal m_cnt		: unsigned( 14 downto 0 ) := ( others => '0' );
		signal i_cnt		: unsigned( 14 downto 0 ) := ( others => '0' );
		
		signal wr_addr_d	: unsigned( 14 downto 0 ) := ( others => '0' );
		
		signal remainder	: unsigned( 19 downto 0 ) := ( others => '0' );
		signal dividend	: unsigned( remainder'range ) := ( others => '0' );
		signal divisor		: unsigned( remainder'range ) := ( others => '0' );
	begin
		
		dividend <= RESIZE( m_cnt, dividend'length );
		divisor  <= RESIZE( i_cnt, divisor'length  );
		
		rf_input <= wr_addr_d & remainder;
		
		count_proc : process( clk )
		begin
			if rising_edge( clk ) then
				m_cnt <= m_cnt + 1;
				if fs_i_en = '1' then
					i_cnt <= m_cnt;
					wr_addr <= wr_addr + 1;
					m_cnt <= ( others => '0' );
				end if;
				
				if fs_o_en = '1' then
					wr_addr_d <= wr_addr;
				end if;
			end if;
		end process count_proc;
		
		INST_DIVIDER : divider_top
			generic map (
				DIV_WIDTH	=> dividend'length
			)
			port map (
				clk			=> clk,
				rst			=> rst,
				
				i_en			=> fs_o_en,
				i_dividend	=> dividend,
				i_divisor	=> divisor,
				
				o_fin			=> rf_en,
				o_remainder	=> remainder
			);
		
	end block BLOCK_GENERATE;
	
	BLOCK_INTERPOLATE : block
		signal rf_en_d			: std_logic := '0';
		
		signal f_input_sub	: unsigned( rf_input'length downto 0 ) := ( others => '0' );
		signal f_strip			: unsigned( rf_input'range ) := ( others => '0' );
		signal f_sreg			: unsigned( rf_input'range ) := ( others => '0' );
		signal f_latch_in		: unsigned( rf_input'range ) := ( others => '0' );
		signal f_latch_out	: unsigned( rf_input'range ) := ( others => '0' );
		signal f_lpf_out		:   signed( rf_input'range ) := ( others => '0' );
		signal f_output_sub	: unsigned( rf_input'range ) := ( others => '0' );
		
		signal f_rat_ext		: unsigned( 3 downto 0 );
		signal f_rat			: unsigned( 9 downto 0 );
		signal f_test_1		: unsigned( 7 downto 0 );
		signal f_test_2		: unsigned( 8 downto 0 );
	begin
	
		f_input_sub <= RESIZE( rf_input, f_input_sub'length ) - f_latch_out;
		
		f_strip <= f_input_sub( f_strip'range );
		
		f_latch_in <= SHIFT_RIGHT( f_strip, GAIN_RAMP ) + f_latch_out;
		
		f_output_sub <= f_latch_out - unsigned( f_lpf_out );
		
		
		f_rat_ext <= ratio( 19 downto 16 ) + 1;
		
		f_rat <= SHIFT_LEFT( ratio( 14 downto 5 ), TO_INTEGER( f_rat_ext( 1 downto 0 ) ) );
		
		f_test_1 <= f_rat( 9 downto 2 );
		
		f_test_2 <= GET_ABS( ramp_dx_o - f_test_1, 9 );
		
		latch_proc : process( clk )
		begin
			if rising_edge( clk ) then
				rf_en_d <= rf_en;
				lock_en <= rf_en_d;
				
				if rf_en = '1' then
					f_latch_out <= f_latch_in;
				end if;
				
				if rf_en_d = '1' then
					--rf_output( 28 downto 20 ) <= f_output_sub( 28 downto 20 ) + unsigned( f_lpf_out( 27 downto 20 ) & '0' );
					rf_output <= f_output_sub( 28 downto  0 );
				end if;
			end if;
		end process latch_proc;
		
		INST_LPF : lpf_top
			generic map (
				LPF_WIDTH	=> rf_input'length
			)
			port map (
				clk			=> clk,
				rst			=> rst,
				
				lpf_in		=> signed( f_strip ),
				lpf_in_en	=> rf_en,
				
				lpf_out		=> f_lpf_out
			);
		
	end block BLOCK_INTERPOLATE;
	
	BLOCK_LOCK : block
		signal d0_abs		: unsigned( 8 downto 0 ) := ( others => '0' );
		
		signal lock_evt_p	: std_logic := '0';
		signal lock_evt_n	: std_logic := '0';
		signal lock_pipe	: std_logic_vector( 3 downto 0 ) := ( others => '0' );
	begin
	
		ramp_dx_o <= d0_abs;
		
		latch_process : process( clk )
		begin
			if rising_edge( clk ) then
				if lock_en = '1' then
					d0_abs <= GET_ABS( wr_addr( 8 downto 0 ) - rf_output( 28 downto 20 ), 9 );
					
					lock_pipe <= lock_pipe( 2 downto 0 ) & '0';
					if ratio_lock = '1' and d0_abs < THRESH_LOCK then
						lock_pipe <= lock_pipe( 2 downto 0 ) & '1';
					end if;
				end if;
			end if;
		end process latch_process;
		
		lock_evt_p <= '1' when ratio_lock = '1' and lock_pipe = x"F" else '0';
		lock_evt_n <= not( ratio_lock );
		
		lock_process : process( clk )
		begin
			if rising_edge( clk ) then
				if lock_evt_n = '1' then
					ramp_lock <= '0';
				elsif lock_evt_p = '1' then
					ramp_lock <= '1';
				end if;
			end if;
		end process lock_process;
		
	end block BLOCK_LOCK;
	
end rtl;
