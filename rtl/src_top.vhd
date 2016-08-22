library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.src_pkg.all;
use work.src_rom_pkg.all;

entity src_top is
	port (
		clk			: in  std_logic;
		rst			: in  std_logic;
		
		-- control lines
		ctrl_lock	: out std_logic := '0';
		ctrl_offset	: in  std_logic;
		
		-- data in
		fs_i_en		: in  std_logic;
		fs_i_lr		: in  std_logic;
		fs_i_dat		: in  signed( 23 downto 0 );
		
		-- data out
		fs_o_req		: in  std_logic;
		fs_o_en		: out std_logic := '0';
		fs_o_clk		: in  std_logic;
		fs_o_lr		: out std_logic := '0';
		fs_o_dat		: out signed( 23 downto 0 ) := ( others => '0' )
	);
end src_top;

architecture rtl of src_top is
	signal lock		: std_logic := '0';
	signal ratio	: unsigned( 19 downto 0 ) := ( others => '0' );
	
	signal wr_int	: unsigned(  9 downto 0 ) := ( others => '0' );
	signal rd_en	: std_logic := '0';
	signal rd_int	: unsigned(  9 downto 0 ) := ( others => '0' );
	signal rd_frc	: unsigned( 19 downto 0 ) := ( others => '0' );
begin
	ctrl_lock <= lock;

	INST_RATIO : ratio_gen
		port map (
			clk				=> clk,
			rst				=> rst,
			lock				=> lock,
			
			fs_i_en			=> fs_i_lr,
			fs_o_clk			=> fs_o_clk,
			fs_o_en			=> fs_o_req,
			
			ratio				=> ratio
		);
	
	INST_RAMP : ramp_gen
		port map (
			clk				=> clk,
			rst				=> rst,
			lock				=> lock,
			
			fs_i_en			=> fs_i_lr,
			fs_i_addr		=> wr_int,
			fs_o_en			=> fs_o_req,
			
			ramp_en			=> rd_en,
			ramp_int			=> rd_int,
			ramp_frc			=> rd_frc
		);
	
	INST_SRC : src_engine
		generic map (
			COE_WIDTH		=> COE_WIDTH
		)
		port map (
			clk				=> clk,
			rst				=> rst,
			
			ctrl_lock		=> lock,
			ctrl_offset		=> ctrl_offset,
			
			ratio				=> ratio,
			
			rd_addr_int		=> rd_int,
			rd_addr_frc		=> rd_frc,
			rd_req			=> rd_en,
			
			i_wr_data		=> fs_i_dat,
			i_wr_addr		=> wr_int,
			i_wr_en			=> fs_i_en,
			i_wr_lr			=> fs_i_lr,
			
			o_data			=> fs_o_dat,
			o_data_en		=> fs_o_en,
			o_data_lr		=> fs_o_lr
		);
	
--	ratio <= ( 19 => '1', others => '0' );
--	
--	tst_process : process( clk )
--		variable ramp : unsigned( 29 downto 0 ) := ( 17 => '1', others => '0' );
--	begin
--		if rising_edge( clk ) then
--			rd_en <= fs_o_req;
--			if fs_o_req = '1' then
--				rd_int <= ramp( 29 downto 20 );
--				rd_frc <= ramp( 19 downto  0 );
--				ramp := ramp + ratio;
--				
--			end if;
--		end if;
--	end process;

end rtl;

