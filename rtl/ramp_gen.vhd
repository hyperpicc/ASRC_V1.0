library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.src_pkg.all;

entity ramp_gen is
	port (
		clk			: in  std_logic;
		rst			: in  std_logic;
		ratio_lock	: in  std_logic;
		ramp_lock	: out std_logic := '0';
		
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
	signal wr_addr		: unsigned( GAIN_RAMP + 6 downto 0 ) := ( others => '0' );
	
	signal rf_en		: std_logic := '0';
	signal lock_en		: std_logic := '0';
	signal rf_input	: unsigned( GAIN_RAMP + 26 downto 0 ) := ( others => '0' );
	signal rf_out_int	: unsigned(  8 downto 0 ) := ( others => '0' );
	signal rf_out_frc	: unsigned( 19 downto 0 ) := ( others => '0' );
	
	signal ramp_dx_o	: unsigned( ramp_dx'range ) := ( others => '0' );
begin
		
	fs_i_addr <= wr_addr( fs_i_addr'range );
	
	ramp_int  <= rf_out_int;
	ramp_frc  <= rf_out_frc;
	
	ramp_en <= lock_en;
	ramp_dx <= ramp_dx_o;

	BLOCK_GENERATE : block
		signal m_cnt		: unsigned( 14 downto 0 ) := ( others => '0' );
		signal i_cnt		: unsigned( 14 downto 0 ) := ( others => '0' );
		signal i_cnt_buf	: unsigned(  3 downto 0 ) := ( others => '0' );
		
		signal wr_addr_d	: unsigned( GAIN_RAMP + 6 downto 0 ) := ( others => '0' );
		
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
					m_cnt <= ( 0 => '1', others => '0' );
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
		signal rf_en_d				: std_logic := '0';
		signal f_fb					: signed( rf_input'range ) := ( others => '0' );
		signal f_latch_out0		: signed( rf_input'range ) := ( others => '0' );
		signal f_latch_out1		: signed( rf_input'range ) := ( others => '0' );
		signal f_out				: signed( rf_input'range ) := ( others => '0' );
	begin
		
		f_out <= f_latch_out0 - f_latch_out1;
		
		latch_proc : process( clk )
		begin
			if rising_edge( clk ) then
				lock_en <= rf_en_d;
				
				if rf_en_d = '1' then
					rf_out_int <= unsigned( f_out( 28 downto 20 ) - not( f_latch_out1( 27 downto 20 ) & '0' ) );
					rf_out_frc <= unsigned( f_out( 19 downto  0 ) );
				end if;
			end if;
		end process latch_proc;
		
		INST_INTEGRATOR_0 : integrator
			generic map (
				INT_WIDTH	=> rf_input'length,
				INT_GAIN		=> GAIN_RAMP
			)
			port map (
				clk			=> clk,
				lock			=> ratio_lock,
		
				i				=> signed( rf_input ),
				i_en			=> rf_en,
				
				o				=> f_latch_out0,
				o_fb			=> f_fb,
				o_en			=> rf_en_d
			);
		
		INST_INTEGRATOR_1 : lpf_top
			generic map (
				LPF_WIDTH	=> rf_input'length,
				LPF_GAIN		=> GAIN_RAMP
			)
			port map (
				clk			=> clk,
				lock			=> ratio_lock,
		
				lpf_in		=> f_fb,
				lpf_in_en	=> rf_en,
				
				lpf_out		=> f_latch_out1
			);
		
	end block BLOCK_INTERPOLATE;
	
	BLOCK_LOCK : block
		signal d0_abs		: unsigned( 8 downto 0 ) := ( others => '0' );
		signal d0_lock		: std_logic := '0';
		
		signal lock_evt_p	: std_logic := '0';
		signal lock_evt_n	: std_logic := '0';
		signal lock_pipe	: unsigned( 8 downto 0 ) := ( others => '0' );
	begin
	
		ramp_dx_o <= d0_abs;
		
		d0_lock <= '1' when ratio_lock = '1' and d0_abs < THRESH_LOCK else '0';
		
		lock_evt_p <= '1' when lock_pipe = 2**lock_pipe'length - 1 else '0';
		lock_evt_n <= not( d0_lock );
		
		latch_process : process( clk )
		begin
			if rising_edge( clk ) then
				if lock_en = '1' then
					d0_abs <= GET_ABS( wr_addr( 8 downto 0 ) - rf_out_int, 9 );
					
					lock_pipe <= ( others => '0' );
					if d0_lock = '1' then
						lock_pipe <= lock_pipe + 1;
					end if;
				end if;
			end if;
		end process latch_process;
		
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
