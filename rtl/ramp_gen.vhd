library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.src_pkg.all;

entity ramp_gen is
	port (
		clk			: in  std_logic;
		rst			: in  std_logic;
		lock			: in  std_logic;
		
		fs_i_en		: in  std_logic;
		fs_i_addr	: out unsigned( 8 downto 0 ) := ( others => '0' );
		fs_o_en		: in  std_logic;
		
		ramp_en		: out std_logic := '0';
		ramp_int		: out unsigned( 8 downto 0 ) := ( others => '0' );
		ramp_frc		: out unsigned( 19 downto 0 ) := ( others => '0' )
	);
end ramp_gen;

architecture rtl of ramp_gen is
	signal wr_addr		: unsigned(  9 downto 0 ) := ( others => '0' );
	
	signal rf_en		: std_logic := '0';
	signal rf_input	: unsigned( 29 downto 0 ) := ( others => '0' );
	signal rf_output	: unsigned( 29 downto 0 ) := ( others => '0' );
begin
		
	fs_i_addr <= wr_addr( 8 downto 0 );
	
	ramp_int  <= rf_output( 28 downto 20 );
	ramp_frc  <= rf_output( 19 downto  0 );

	BLOCK_GENERATE : block
		signal m_cnt		: unsigned( 14 downto 0 ) := ( others => '0' );
		signal i_cnt		: unsigned( 14 downto 0 ) := ( others => '0' );
		
		signal wr_addr_d	: unsigned(  9 downto 0 ) := ( others => '0' );
		
		signal dividend	: unsigned( 19  downto 0 ) := ( others => '0' );
		signal divisor		: unsigned( 19  downto 0 ) := ( others => '0' );
		signal remainder	: unsigned( 19  downto 0 ) := ( others => '0' );
	begin
		
		dividend <= RESIZE( m_cnt, 20 );
		divisor  <= RESIZE( i_cnt, 20 );
		
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
				DIV_WIDTH	=> 20
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
		
		signal f_input_sub	: unsigned( 30 downto 0 ) := ( others => '0' );
		signal f_strip			: unsigned( 29 downto 0 ) := ( others => '0' );
		signal f_sreg			: unsigned( 29 downto 0 ) := ( others => '0' );
		signal f_sreg_ctrl	: unsigned(  3 downto 0 ) := ( others => '0' );
		signal f_latch_in		: unsigned( 29 downto 0 ) := ( others => '0' );
		signal f_latch_out	: unsigned( 29 downto 0 ) := ( others => '0' );
		signal f_lpf_out		: unsigned( 29 downto 0 ) := ( others => '0' );
		signal f_output_sub	: unsigned( 29 downto 0 ) := ( others => '0' );
	begin
	
		f_input_sub <= RESIZE( rf_input, f_input_sub'length ) - f_latch_out;
		
		f_strip <= f_input_sub( f_strip'range );
		
		f_sreg_ctrl <= to_unsigned( RAMP_LOCKED, f_sreg_ctrl'length ) when lock = '1' else
							to_unsigned( RAMP_UNLOCKED, f_sreg_ctrl'length );
		
		f_sreg <= SHIFT_RIGHT( f_strip, to_integer( f_sreg_ctrl ) ) + 1;
		
		f_latch_in <= f_sreg + f_latch_out;
		
		f_output_sub <= f_latch_out;-- - f_lpf_out;
	
		latch_proc : process( clk )
		begin
			if rising_edge( clk ) then
				rf_en_d <= rf_en;
				ramp_en <= rf_en_d;
				
				if rf_en = '1' then
					f_latch_out <= f_latch_in;
				end if;
				
				if rf_en_d = '1' then
					rf_output <= f_output_sub( rf_output'range );
				end if;
			end if;
		end process latch_proc;
		
		INST_LPF : lpf_top
			generic map (
				LPF_WIDTH		=> 30
			)
			port map (
				clk			=> clk,
				rst			=> rst,
				lock			=> lock,
				
				lpf_in		=> f_strip,
				lpf_in_en	=> rf_en,
				
				lpf_out		=> f_lpf_out
			);
		
	end block BLOCK_INTERPOLATE;
		
end rtl;
