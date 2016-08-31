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
	signal wr_addr		: unsigned(  8 downto 0 ) := ( others => '0' );
		
	signal interp_en	: std_logic := '0';
	signal interp_i	: unsigned( 28 downto 0 ) := ( others => '0' );
	signal interp_o	: unsigned( 28 downto 0 ) := ( others => '0' );
	
	signal ramp_en_d0	: std_logic := '0';
	signal ramp_en_d1	: std_logic := '0';
begin
		
	fs_i_addr <= wr_addr;
	
	ramp_int  <= interp_o( 28 downto 20 );
	ramp_frc  <= interp_o( 19 downto  0 );

	BLOCK_GENERATE : block
		signal fs_cnt		: unsigned( 14 downto 0 ) := ( others => '0' );
		signal fs_cnt_i	: unsigned( 14 downto 0 ) := ( others => '0' );
		signal fs_cnt_i_d	: unsigned( 14 downto 0 ) := ( others => '0' );
		signal fs_cnt_o	: unsigned( 14 downto 0 ) := ( others => '0' );
		
		signal div_fin		: std_logic := '0';
		signal dividend	: unsigned( 19  downto 0 ) := ( others => '0' );
		signal divisor		: unsigned( 19  downto 0 ) := ( others => '0' );
		signal remainder	: unsigned( 19  downto 0 ) := ( others => '0' );
	begin
		
		interp_i <= wr_addr & remainder;
		
		ramp_en_d0 <= div_fin;
		
		dividend <= RESIZE( fs_cnt, 20 );
		divisor <= RESIZE( fs_cnt_i, 20 );
		
		enable_process : process( clk )
		begin
			if rising_edge( clk ) then
				ramp_en_d1 <= ramp_en_d0;
				ramp_en <= ramp_en_d1;
			end if;
		end process enable_process;
		
		count_process : process( clk )
		begin
			if rising_edge( clk ) then
				if ( rst or fs_i_en ) = '1' then
					fs_cnt <= ( 0 => '1', others => '0' );
					fs_cnt_i <= fs_cnt;
				else
					fs_cnt <= fs_cnt + 1;
				end if;
			end if;
		end process count_process;
		
		output_process : process( clk )
		begin
			if rising_edge( clk ) then
				if rst = '1' then
					wr_addr <= ( others => '0' );
				else
					if fs_i_en = '1' then
						wr_addr <= wr_addr + 1;
					end if;
				end if;
			end if;
		end process output_process;
		
		INST_DIVIDER : divider_top
			generic map (
				DIV_WIDTH	=> 20
			)
			port map (
				clk			=> clk,
				rst			=> rst,
				
				i_en			=> fs_o_en,
				i_divisor	=> divisor,
				i_dividend	=> dividend,
				
				o_fin			=> div_fin,
				o_remainder	=> remainder
			);
		
	end block BLOCK_GENERATE;
	
	BLOCK_INTERPOLATE : block
	
		-- internal signals
		-- first adder
		signal adder		: unsigned( 28 downto 0 ) := ( others => '0' );
		signal shift_reg	: unsigned( 28 downto 0 ) := ( others => '0' );
		signal shift_ctrl	: unsigned(  3 downto 0 ) := ( others => '0' );
		signal latch_out	: unsigned( 28 downto 0 ) := ( others => '0' );
		
		-- output from leaky integrater
		signal lpf_out		:   signed( 28 downto 0 ) := ( others => '0' );	
	begin
		
		adder <= interp_i - latch_out;
		
		shift_ctrl <= TO_UNSIGNED( RAMP_LOCKED, 4 ) when lock = '1' else TO_UNSIGNED( RAMP_UNLOCKED, 4 );
		
		shift_reg <= SHIFT_RIGHT( adder, TO_INTEGER( shift_ctrl ) ) + 1;
		
		latch_process : process( clk )
		begin
			if rising_edge( clk ) then
				if ramp_en_d0 = '1' then
					latch_out <= shift_reg + latch_out;
				end if;
				if ramp_en_d1 = '1' then
					interp_o	<= latch_out - unsigned( lpf_out );
				end if;
			end if;
		end process latch_process;
		
		INST_LPF : lpf_top
			generic map (
				LPF_WIDTH		=> 29
			)
			port map (
				clk			=> clk,
				rst			=> rst,
				lock			=> lock,
				
				lpf_in		=> signed( adder ),
				lpf_in_en	=> ramp_en_d0,
				
				lpf_out		=> lpf_out
			);
		
	end block BLOCK_INTERPOLATE;
		
end rtl;
