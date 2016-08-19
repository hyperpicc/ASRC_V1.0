-- lock
-- try for 64 stable output requests before letting lock assert

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.src_pkg.all;

entity ratio_gen is
	port (
		clk				: in  std_logic;
		rst				: in  std_logic;
		lock				: out std_logic := '0';
		
		fs_i_en			: in  std_logic;
		fs_o_clk			: in  std_logic;
		
		ratio				: out unsigned( 19 downto 0 ) := ( others => '0' )
	);
end ratio_gen;

architecture rtl of ratio_gen is
	signal fs_i_cnt	: unsigned(  3 downto 0 ) := ( others => '0' );
	signal fs_i_trm	: std_logic := '0';
	
	type FS_O_CNT_TYPE is array (  2 downto 0 ) of unsigned( 13 downto 0 );
	signal fs_o_cnt	: unsigned( 13 downto 0 ) := ( others => '0' );
	signal fs_o_cnt_d	: FS_O_CNT_TYPE := ( others => ( others => '0' ) );
	signal fs_o_abs	: std_logic := '0';
	signal fs_o_latch	: std_logic := '0';
	
	signal lpf_in		: signed( 22 downto 0 ) := ( others => '0' );
	signal lpf_out		: signed( 22 downto 0 ) := ( others => '0' );
begin
	
	fs_o_latch <= fs_i_trm and fs_i_en;
	fs_i_trm <= '1' when fs_i_cnt = ( 2**fs_i_cnt'high - 1 ) else '0';
	fs_o_abs <= '1' when U_ABS( fs_o_cnt_d( 0 ) - fs_o_cnt_d( 1 ) ) > 2 else '0';
	
	ratio <= ( ratio'high => '1', others => '0' ) when lpf_out( 22 downto 19 ) > 0 else
				unsigned( lpf_out( 19 downto 0 ) );
	
	count_process : process( clk )
	begin
		if rising_edge( clk ) then
			if fs_i_en = '1' then
				fs_i_cnt <= fs_i_cnt + 1;
			end if;
			
			if fs_i_trm = '1' then
				fs_o_cnt <= ( others => '0' );
			elsif fs_o_clk = '1' then
				fs_o_cnt <= fs_o_cnt + 1;
			end if;
		end if;
	end process count_process;
	
	latch_process : process( clk )
	begin
		if rising_edge( clk ) then
			if fs_o_latch = '1' then
				fs_o_cnt_d( 0 ) <= fs_o_cnt;
			end if;
			
			if ( fs_o_abs and fs_i_trm ) = '1' then
				fs_o_cnt_d( 1 ) <= fs_o_cnt_d( 0 );
			end if;
			
			if fs_o_clk = '1' then
				fs_o_cnt_d( 2 ) <= fs_o_cnt_d( 1 );
			end if;
		end if;
	end process latch_process;
	
	lpf_in <= signed( fs_o_cnt_d( 2 ) ) & o"000";
	
	INST_LPF : lpf_top
		generic map (
			LPF_WIDTH	=> 23
		)
		port map (
			clk			=> clk,
			rst			=> rst,
			
			lpf_in		=> lpf_in,
			lpf_in_en	=> fs_o_clk,
			
			lpf_out		=> lpf_out
		);
	
	LOCK_BLOCK : block
		signal mclk_cnt		: unsigned( 7 downto 0 ) := ( others => '0' );
		signal mclk_cnt_trm	: std_logic := '0';
		
		signal lim_abs			: std_logic := '0';
		signal lock_cnt		: unsigned( 4 downto 0 ) := ( others => '0' );
		signal lock_trm		: std_logic := '0';
		
		signal lock_ratio		: std_logic := '0';
		signal lock_fs_i		: std_logic := '0';
		signal lock_fs_o		: std_logic := '0';
	begin
	
		lim_abs <= '1' when ABS( lpf_in - lpf_out ) > 16 else '0';
		mclk_cnt_trm <= '1' when mclk_cnt = 255 else '0';
		lock_trm     <= '1' when lock_cnt =  31 else '0';
	
		count_process : process( clk )
		begin
			if rising_edge( clk ) then
				mclk_cnt <= mclk_cnt + 1;
				
				if mclk_cnt_trm = '1' then
					lock_fs_i <= '0';
					lock_fs_o <= '0';
					lock <= lock_fs_i and lock_fs_o and lock_trm;
				else
					if fs_i_en = '1' then
						lock_fs_i <= '1';
					end if;
					if fs_o_clk = '1' then
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
