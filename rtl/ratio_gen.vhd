library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.src_pkg.all;

entity ratio_gen is
	port (
		clk				: in  std_logic;
		rst				: in  std_logic;
		ratio_lock		: out std_logic := '0';
		
		fs_i_clk			: in  std_logic;
		fs_i_en			: in  std_logic;
		fs_o_clk			: in  std_logic;
		fs_o_en			: in  std_logic;
		
		ratio				: out unsigned( 19 downto 0 ) := ( others => '0' )
	);
end ratio_gen;

architecture rtl of ratio_gen is
	signal fs_i_cnt	: unsigned( 10 downto 0 ) := ( others => '0' );
	signal fs_i_sel	: std_logic := '0';
	signal fs_i_trm	: std_logic := '0';
	
	signal fs_o_cnt	: unsigned( 14 downto 0 ) := ( others => '0' );
	signal fs_o_d0		: unsigned( 14 downto 0 ) := ( others => '0' );
	signal fs_o_d1		: unsigned( 14 downto 0 ) := ( others => '0' );
	signal fs_o_d2		: unsigned( 14 downto 0 ) := ( others => '0' );
	signal fs_o_abs	: std_logic := '0';
	signal fs_o_latch	: std_logic := '0';
	
	signal lpf_in		: unsigned( 22 downto 0 ) := ( others => '0' );
	signal lpf_out		: unsigned( 22 downto 0 ) := ( others => '0' );
	
	signal o_lock		: std_logic := '0';
	signal o_ratio		: unsigned( 19 downto 0 ) := ( others => '0' );
begin
	
	FSI_CLK_GEN : if RATIO_FSI_CLK generate
	begin
		fs_i_sel <= fs_i_clk;
		fs_i_trm <= '1' when fs_i_cnt = 2**fs_i_cnt'length - 1 and fs_i_sel = '1' else '0';
	end generate FSI_CLK_GEN;
	
	FSI_CLK_GEN_N : if not RATIO_FSI_CLK generate
	begin
		fs_i_sel <= fs_i_en;
		fs_i_trm <= '1' when fs_i_cnt( 4 downto 0 ) =   31 and fs_i_sel = '1' else '0';
	end generate FSI_CLK_GEN_N;
	
	fs_o_latch <= fs_i_sel and fs_o_abs;
	fs_o_abs <= '1' when U_ABS( fs_o_d0 - fs_o_d1 ) > 2 else '0';
	
	ratio_lock <= o_lock;
	ratio <= o_ratio;
	o_ratio <= ( ratio'high => '1', others => '0' ) when lpf_out( 22 downto 19 ) > 0 else
				  unsigned( lpf_out( 19 downto 0 ) );
	
	fs_o_cnt_process : process( clk )
	begin
		if rising_edge( clk ) then
			if fs_i_sel = '1' then
				fs_i_cnt <= fs_i_cnt + 1;
			end if;
			
			if fs_i_trm = '1' then
				fs_o_cnt <= ( others => '0' );
			elsif fs_o_clk = '1' then
				fs_o_cnt <= fs_o_cnt + 1;
			end if;
		end if;
	end process fs_o_cnt_process;
	
	latch_process : process( clk )
	begin
		if rising_edge( clk ) then
			if fs_i_trm = '1' then
				fs_o_d0 <= fs_o_cnt;
			end if;
			
			if fs_o_latch = '1' then
				fs_o_d1 <= fs_o_d0;
			end if;
			
			if fs_o_clk = '1' then
				fs_o_d2 <= fs_o_d1;
			end if;
		end if;
	end process latch_process;
	
	lpf_in <= fs_o_d2 & TO_UNSIGNED( 0, 23 - fs_o_d2'length );
	
	INST_LPF : lpf_top
		generic map (
			LPF_WIDTH	=> 23
		)
		port map (
			clk			=> clk,
			rst			=> rst,
			lock			=> o_lock,
			
			lpf_in		=> lpf_in,
			lpf_in_en	=> fs_o_en,
			
			lpf_out		=> lpf_out
		);
	
	LOCK_BLOCK : block
		signal mclk_cnt		: unsigned( 12 downto 0 ) := ( others => '0' );
		signal mclk_cnt_trm	: std_logic := '0';
		
		signal lim_abs			: std_logic := '0';
		signal lock_cnt		: unsigned( 1 downto 0 ) := ( others => '0' );
		signal lock_trm		: std_logic := '0';
		signal lock_en			: std_logic := '0';
		
		signal lock_ratio		: std_logic := '0';
		signal lock_fs_i		: std_logic := '0';
		signal lock_fs_o		: std_logic := '0';
		signal lock_zero		: std_logic := '0';
	begin
	
		lim_abs <= '1' when ABS( signed( lpf_in ) - signed( lpf_out ) ) > 15 else '0';
		mclk_cnt_trm <= '1' when mclk_cnt = 8191 else '0';
		lock_trm <= '1' when lock_cnt = 2**lock_cnt'length - 1 else '0';
		lock_zero <= '1' when o_ratio < 1023 else '0';
	
		count_process : process( clk )
		begin
			if rising_edge( clk ) then
				mclk_cnt <= mclk_cnt + 1;
				
				if mclk_cnt_trm = '1' then
					lock_fs_i <= '0';
					lock_fs_o <= '0';
					o_lock <= lock_fs_i and lock_fs_o and lock_trm and not( lock_zero );
				else
					if fs_i_en = '1' then
						lock_fs_i <= '1';
					end if;
					if fs_o_en = '1' then
						lock_fs_o <= '1';
					end if;
				end if;
				
				if lim_abs = '1' then
					lock_cnt <= ( others => '0' );
				elsif mclk_cnt_trm = '1' then
					if lock_trm = '0' then
						lock_cnt <= lock_cnt + 1;
					end if;
				end if;
			end if;
		end process count_process;
		
	end block LOCK_BLOCK;
	
end rtl;
