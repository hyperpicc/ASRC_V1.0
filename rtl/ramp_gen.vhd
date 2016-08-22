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
		fs_i_addr	: out unsigned(  9 downto 0 ) := ( others => '0' );
		fs_o_en		: in  std_logic;
		
		ramp_en		: out std_logic := '0';
		ramp_int		: out unsigned(  9 downto 0 ) := ( others => '0' );
		ramp_frc		: out unsigned( 19 downto 0 ) := ( others => '0' )
	);
end ramp_gen;

architecture rtl of ramp_gen is
	
	-- write address counter
	signal wr_addr	: unsigned( 9 downto 0 ) := ( others => '0' );
	
	-- i/o from interpolator
	signal interp_en		: std_logic := '0';
	signal interp_i		: unsigned( 29 downto 0 ) := ( others => '0' );
	signal interp_o		: unsigned( 29 downto 0 ) := ( others => '0' );
begin
		
	fs_i_addr <= wr_addr;
	
	ramp_int  <= interp_o( 29 downto 20 );
	ramp_frc  <= interp_o( 19 downto  0 );

	BLOCK_GENERATE : block
		-- these go to divider
		signal fs_cnt_a0	: unsigned( 14 downto 0 ) := ( others => '0' );
		signal fs_cnt_a1	: unsigned( 14 downto 0 ) := ( others => '0' );
		signal fs_cnt_b	: unsigned( 14 downto 0 ) := ( others => '0' );
		signal fs_cnt		: unsigned( 14 downto 0 ) := ( others => '0' );
		
		signal div_en		: std_logic := '0';
		signal div_fin		: std_logic := '0';
		signal divisor		: unsigned( 19 downto 0 ) := ( others => '0' );
		signal dividend	: unsigned( 19 downto 0 ) := ( others => '0' );
		signal remainder	: unsigned( 19 downto 0 ) := ( others => '0' );
	begin
		
		dividend <= RESIZE( fs_cnt_b, dividend'length );
		divisor  <= RESIZE( fs_cnt_a1, divisor'length );
		
		interp_i( 19 downto 0 ) <= remainder;
		
		count_process : process( clk )
		begin
			if rising_edge( clk ) then
				if rst = '1' then
					div_en	 <= '0';
					fs_cnt	 <= ( others => '0' );
					fs_cnt_a0 <= ( others => '0' );
					fs_cnt_a1 <= ( others => '0' );
					fs_cnt_b  <= ( others => '0' );
				else
					fs_cnt <= fs_cnt + 1;
					
					if fs_i_en = '1' then
						fs_cnt_a0 <= fs_cnt;
						fs_cnt    <= ( others => '0' );
					end if;
					
					div_en <= fs_o_en;
					if fs_o_en = '1' then
						fs_cnt_a1 <= fs_cnt_a0;
						fs_cnt_b  <= fs_cnt;
					end if;
					
				end if;
			end if;
		end process count_process;
		
		output_process : process( clk )
		begin
			if rising_edge( clk ) then
				if rst = '1' then
					wr_addr <= ( others => '0' );
					interp_i( 29 downto 20 ) <= ( others => '0' );
				else
					if fs_i_en = '1' then
						wr_addr <= wr_addr + 1;
					end if;
					
					-- this is double flopping
					ramp_en <= div_fin;
					if div_fin = '1' then
						interp_i( 29 downto 20 ) <= wr_addr;
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
				
				i_en			=> div_en,
				i_divisor	=> divisor,
				i_dividend	=> dividend,
				
				o_fin			=> div_fin,
				o_remainder	=> remainder
			);
		
	end block BLOCK_GENERATE;
	
	BLOCK_INTERPOLATE : block
		constant RAMP_LOCKED		: integer := 5;
		constant RAMP_UNLOCKED	: integer := 5;
	
		-- internal signals
		-- first adder
		signal adder		: unsigned( 30 downto 0 ) := ( others => '0' );
		signal shift_reg	: unsigned( 29 downto 0 ) := ( others => '0' );
		signal shift_ctrl	: unsigned(  3 downto 0 ) := ( others => '0' );
		signal latch_out	: unsigned( 29 downto 0 ) := ( others => '0' );
		
		-- output from leaky integrater
		signal lpf_out		:   signed( 29 downto 0 ) := ( others => '0' );	
	begin
		
		adder		  <= RESIZE( interp_i, 31 ) - RESIZE( latch_out, 31 );
		shift_ctrl <= TO_UNSIGNED( RAMP_LOCKED, 4 ) when lock = '1' else TO_UNSIGNED( RAMP_UNLOCKED, 4 );
		shift_reg  <= SHIFT_RIGHT( adder( 29 downto 0 ), TO_INTEGER( shift_ctrl ) );
		
		latch_process : process( clk )
		begin
			if rising_edge( clk ) then
				interp_o	  <= latch_out - unsigned( lpf_out );
				if fs_o_en = '1' then
					latch_out <= shift_reg + latch_out + 1;
				end if;
			end if;
		end process latch_process;
		
		INST_LPF : lpf_top
			generic map (
				LPF_WIDTH		=> 30
			)
			port map (
				clk			=> clk,
				rst			=> rst,
				lock			=> lock,
				
				lpf_in		=> signed( adder( 29 downto 0 ) ),
				lpf_in_en	=> fs_o_en,
				
				lpf_out		=> lpf_out
			);
		
	end block BLOCK_INTERPOLATE;
		
end rtl;
