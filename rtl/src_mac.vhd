library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.src_rom_pkg.all;

entity src_mac is
	generic (
		COE_WIDTH		: integer := COE_WIDTH
	);
	port (
		clk			: in  std_logic;
		rst			: in  std_logic;
		
		i_ratio		: in  unsigned( 19 downto 0 );
		i_coe			: in	signed( COE_WIDTH - 1 downto 0 );
		i_data		: in  signed( 23 downto 0 );
		
		i_ctrl_norm	: in  std_logic;
		i_ctrl_en	: in  std_logic;
		i_ctrl_acc	: in  std_logic;
		i_ctrl_lr	: in  std_logic;
		
		o_data		: out signed( 23 downto 0 ) := ( others => '0' );
		o_data_en	: out std_logic := '0';
		o_data_lr	: out std_logic := '0'
	);
end src_mac;

architecture rtl of src_mac is
	
	constant PIPELINE_WIDTH		: integer := i_data'length + COE_WIDTH - 1;
	constant PIPELINE_LENGTH	: integer := 5;
	signal pipe_norm	: std_logic_vector( PIPELINE_LENGTH-2 downto 0 ) := ( others => '0' );
	signal pipe_acc	: std_logic_vector( PIPELINE_LENGTH-2 downto 0 ) := ( others => '0' );
	signal pipe_en		: std_logic_vector( PIPELINE_LENGTH-2 downto 0 ) := ( others => '0' );
	signal pipe_lr		: std_logic_vector( PIPELINE_LENGTH-2 downto 0 ) := ( others => '0' );
	
	constant ACC_ROUND_BIT		: integer := PIPELINE_WIDTH - COE_WIDTH + 2;
	constant mac_acc_rnd			: signed( PIPELINE_WIDTH + 3 downto 0 ) := ( ACC_ROUND_BIT => '1', others => '0' );
	signal mac_acc_sel: signed( PIPELINE_WIDTH + 3 downto 0 ) := ( others => '0' );
	
	type PIPELINE_MAC	is array( PIPELINE_LENGTH-2 downto 0 ) of signed( COE_WIDTH + 23 downto 0 );
	signal pipe_mac	: PIPELINE_MAC := ( others => ( others => '0' ) );
	signal mac_acc_l	: signed( PIPELINE_WIDTH + 3 downto 0 ) := ( others => '0' );
	signal mac_o_l		: signed( 23 downto 0 ) := ( others => '0' );
	signal mac_n_l		: signed( COE_WIDTH - 1 downto 0 ) := ( others => '0' );
	signal mac_acc_r	: signed( PIPELINE_WIDTH + 3 downto 0 ) := ( others => '0' );
	signal mac_o_r		: signed( 23 downto 0 ) := ( others => '0' );
	signal mac_n_r		: signed( COE_WIDTH - 1 downto 0 ) := ( others => '0' );
	
	signal mac_i0		: signed( 23 downto 0 ) := ( others => '0' );
	signal mac_i1		: signed( COE_WIDTH - 1 downto 0 ) := ( others => '0' );
begin
	
	-- mappings
	mac_o_l <= pipe_mac( pipe_mac'high )( COE_WIDTH + 16 downto COE_WIDTH - 7 );
	mac_o_r <= pipe_mac( pipe_mac'high )( COE_WIDTH + 16 downto COE_WIDTH - 7 );
	
	mac_n_l <= mac_acc_l( mac_acc_l'high - 1 downto mac_acc_l'high - COE_WIDTH );
	mac_n_r <= mac_acc_l( mac_acc_l'high - 1 downto mac_acc_l'high - COE_WIDTH );
	
	-- MAC input muxes
	mac_i0	 <= i_data when i_ctrl_norm = '0' else 
					 SIGNED( "0" & i_ratio & o"0" );
	mac_i1	 <= i_coe   when i_ctrl_norm = '0' else 
					 mac_n_l when pipe_lr( pipe_lr'high ) = '0' else
					 mac_n_r;
	
	mac_acc_sel <= mac_acc_l when pipe_acc( pipe_acc'high ) = '1' and pipe_lr( pipe_lr'high ) = '0' else
						mac_acc_r when pipe_acc( pipe_acc'high ) = '1' and pipe_lr( pipe_lr'high ) = '1' else 
						mac_acc_rnd;

	pipeline_process : process( clk )
	begin
		if rising_edge( clk ) then
			if rst = '1' then
				pipe_norm <= ( others => '0' );
				pipe_acc  <= ( others => '0' );
				pipe_en	 <= ( others => '0' );
				pipe_lr	 <= ( others => '0' );
			else
				pipe_norm <= pipe_norm( pipe_norm'high-1 downto 0 ) & i_ctrl_norm;
				pipe_acc  <= pipe_acc(  pipe_acc'high -1 downto 0 ) & i_ctrl_acc;
				pipe_en	 <= pipe_en(   pipe_en'high  -1 downto 0 ) & i_ctrl_en;
				pipe_lr	 <= pipe_lr(   pipe_lr'high  -1 downto 0 ) & i_ctrl_lr;
			end if;
		end if;
	end process pipeline_process;

	muliply_process : process( clk )
	begin
		if rising_edge( clk ) then
			pipe_mac <= pipe_mac( pipe_mac'high-1 downto 0 ) & ( mac_i0 * mac_i1 );
			if rst = '1' then
				pipe_mac <= ( others => ( others => '0' ) );
			end if;
		end if;
	end process muliply_process;
	
	accumulator_process : process( clk )
	begin
		if rising_edge( clk ) then
			if rst = '1' then
				mac_acc_l <= ( others => '0' );
				mac_acc_r <= ( others => '0' );
				
			elsif pipe_en( pipe_en'high ) = '1' then
			
				-- if directed to accumulate
				if pipe_lr( pipe_lr'high ) = '0' then
					mac_acc_l <= mac_acc_sel + pipe_mac( pipe_mac'high );
				else
					mac_acc_r <= mac_acc_sel + pipe_mac( pipe_mac'high );
				end if;
				
			end if;
		end if;
	end process accumulator_process;
	
	output_process : process( clk )
	begin
		if rising_edge( clk ) then
			o_data_en <= pipe_norm( pipe_norm'high );
			o_data_lr <= pipe_lr( pipe_lr'high ) and pipe_norm( pipe_norm'high );
			
			if rst = '1' then
				o_data	 <= ( others => '0' );
				o_data_en <= '0';
				o_data_lr <= '0';
			elsif pipe_norm( pipe_norm'high ) = '1' then
				o_data <= mac_o_r;
				if pipe_lr( pipe_lr'high ) = '0' then
					o_data <= mac_o_l;
				end if;
			end if;
		end if;
	end process output_process;
	
end rtl;

