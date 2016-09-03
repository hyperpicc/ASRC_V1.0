library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.src_pkg.all;
use work.src_rom_pkg.all;

entity src_engine is
	generic (
		COE_WIDTH		: integer := COE_WIDTH
	);
	port (
		clk				: in  std_logic;
		rst				: in  std_logic;
		
		ctrl_offset		: in  std_logic;
		ctrl_lock		: in  std_logic;
		
		ratio				: in  unsigned( 19 downto 0 );
		
		rd_addr_int		: in  unsigned( 8 downto 0 );
		rd_addr_frc		: in  unsigned( 19 downto 0 );
		rd_req			: in  std_logic;
		
		i_wr_data		: in  signed( 23 downto 0 );
		i_wr_addr		: in  unsigned( 8 downto 0 );
		i_wr_en			: in  std_logic;
		i_wr_lr			: in  std_logic;
		
		o_data			: out signed( 23 downto 0 ) := ( others => '0' );
		o_data_en		: out std_logic := '0';
		o_data_lr		: out std_logic := '0';
		
		o_coe				: out signed( COE_WIDTH-1 downto 0 ) := ( others => '0' );
		o_coe_en			: out std_logic := '0'
	);
end src_engine;

architecture rtl of src_engine is
	type STATE_TYPE is ( S0_WAIT, S1_MULTIPLY, S2_ADDR_LOAD );
	signal state		: STATE_TYPE := S0_WAIT;
	
	signal interp_en	: std_logic := '0';
	signal interp_fin	: std_logic := '0';
	
	signal mul_i0		: unsigned( 19 downto 0 ) := ( others => '0' );
	signal mul_i1		: unsigned( 16 downto 0 ) := ( others => '0' );
	signal mul_o		: unsigned( 18 downto 0 ) := ( others => '0' );

	signal mac_coe		: signed( COE_WIDTH-1 downto 0 ) := ( others => '0' );
	signal mac_en		: std_logic := '0';
	signal mac_acc		: std_logic := '0';
	signal mac_lr		: std_logic := '0';
	signal mac_norm	: std_logic := '0';
	
	signal rbuf_data	: signed( 23 downto 0 ) := ( others => '0' );
	signal rbuf_lr		: std_logic := '0';
begin
	
	mul_i0 <= rd_addr_frc;
	mul_i1 <= ratio( 19 downto 3 );
	
	o_coe <= mac_coe;
	o_coe_en <= mac_lr and mac_en;
	
	state_process : process( clk )
	begin
		if rising_edge( clk ) then
			if rst = '1' then
				state <= S0_WAIT;
				interp_en <= '0';
			else
				interp_en <= '0';
				case state is
					when S0_WAIT =>
						if ( ctrl_lock and rd_req ) = '1' and ratio( 19 downto 15 ) /= 0 then
							state <= S1_MULTIPLY;
						end if;
						
					when S1_MULTIPLY =>
						state <= S2_ADDR_LOAD;
						interp_en <= '1';
					
					when S2_ADDR_LOAD =>
						if interp_fin = '1' then
							state <= S0_WAIT;
						end if;
						
				end case;
			end if;
		end if;
	end process state_process;

	INST_INTERPOLATOR : src_interpolator
		generic map (
			COE_WIDTH		=> COE_WIDTH
		)
		port map (
			clk				=> clk,
			rst				=> rst,
			
			i_ratio			=> ratio,
			i_ratio_init	=> mul_o,
			i_en				=> interp_en,
			
			o_coe				=> mac_coe,
			o_fin				=> interp_fin,
			o_en				=> mac_en,
			o_acc				=> mac_acc,
			o_lr				=> mac_lr,
			o_norm			=> mac_norm
		);
	
	INST_RING_BUFFER : src_ring_buffer
		port map(
			clk				=> clk,
			rst				=> rst,
			
			i_wr_data		=> i_wr_data,
			i_wr_addr		=> i_wr_addr,
			i_wr_en			=> i_wr_en,
			i_wr_lr			=> i_wr_lr,
			
			o_rd_data		=> rbuf_data,
			i_rd_addr		=> rd_addr_int,
			i_rd_offset		=> ctrl_offset,
			i_rd_preset		=> rd_req,
			i_rd_step		=> mac_lr
		);
	
	INST_MAC : src_mac
		generic map (
			COE_WIDTH		=> COE_WIDTH
		)
		port map (
			clk				=> clk,
			rst				=> rst,
			
			i_ratio			=> ratio,
			i_coe				=> mac_coe,
			i_data			=> rbuf_data,
			
			i_ctrl_norm		=> mac_norm,
			i_ctrl_en		=> mac_en,
			i_ctrl_acc		=> mac_acc,
			i_ctrl_lr		=> mac_lr,
			
			o_data			=> o_data,
			o_data_en		=> o_data_en,
			o_data_lr		=> o_data_lr
		);
	
	BLOCK_MUL : block
		signal mi_0		: unsigned( 16 downto 0 ) := ( others => '0' );
		signal mi_1		: unsigned( 16 downto 0 ) := ( others => '0' );
		
		signal m_en		: std_logic := '0';
		signal m_en_d	: std_logic := '0';
		signal m_o		: unsigned( 33 downto 0 ) := ( others => '0' );
		signal m_cry	: unsigned( 16 downto 0 ) := ( others => '0' );
	begin

		mi_0 <= mul_i0( 16 downto 0 ) when m_en = '1' else RESIZE( mul_i0( 19 downto 17 ), 17 );
		mi_1 <= mul_i1;
		
		m_o <= mi_0 * mi_1 + m_cry;

		m_en <= rd_req;

		process( clk )
		begin
			if rising_edge( clk ) then
				m_en_d <= m_en;
				
				-- Least significant bits are available on rd_req
				if m_en = '1' then
					m_cry <= m_o( 33 downto 17 );
				end if;
				
				if m_en_d = '1' then
					mul_o <= m_o( 18 downto 0 );
				end if;
			
			end if;
		end process;

	end block BLOCK_MUL;
	
end rtl;

