library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.src_pkg.all;
use work.src_rom_pkg.all;

entity src_interpolator is
	generic (
		COE_WIDTH		: integer := COE_WIDTH
	);
	port (
		clk				: in  std_logic;
		rst				: in  std_logic;
		
		i_ratio			: in  unsigned( 19 downto 0 );
		i_ratio_init	: in  unsigned( 19 downto 0 );
		i_en				: in  std_logic;
		
		o_coe				: out signed( COE_WIDTH-1 downto 0 ) := ( others => '0' );
		o_fin				: out std_logic := '0';
		o_en				: out std_logic := '0';
		o_acc				: out std_logic := '0';
		o_lr				: out std_logic := '0';
		o_norm			: out std_logic := '0'
	);
end src_interpolator;

architecture rtl of src_interpolator is
	signal latch_pipeline	: std_logic_vector( 10 downto 0 ) := ( others => '0' );
	signal latch_init_delay	: std_logic_vector( 10 downto 0 ) := ( others => '0' );
	
	signal addr_gen_en		: std_logic := '0';
	signal addr_gen_fin		: std_logic := '0';
	
	signal fold_int			: unsigned( 11 downto 0 ) := ( others => '0' );
	signal fold_frc			: unsigned( 11 downto 0 ) := ( others => '0' );
	signal fold_centre		: std_logic := '0';
	
	signal rom_coe				: signed( COE_WIDTH-1 downto 0 ) := ( others => '0' );
	signal dx					: signed( 23 downto 0 ) := ( others => '0' );
begin
	
	latch_pipeline_process : process( clk )
	begin
		if rising_edge( clk ) then
			if rst = '1' then
				latch_pipeline <= ( others => '0' );
			else
				latch_pipeline <= latch_pipeline( latch_pipeline'high - 1 downto 0 ) & addr_gen_en;
			end if;
			
			latch_init_delay <= latch_init_delay( latch_init_delay'high - 1 downto 0 ) & '0';
			if rst = '1' then
				latch_init_delay	<= ( others => '0' );
			elsif i_en = '1' then
				latch_init_delay( 0 ) <= '1';
			end if;
		end if;
	end process latch_pipeline_process;
	
	CTRL_BLOCK : block
		constant EN_REG			: integer := 9;
		
		alias  mac_en				: std_logic is latch_pipeline( EN_REG );
		alias  mac_en_d			: std_logic is latch_init_delay( EN_REG );
		alias  mac_lr				: std_logic is latch_pipeline( EN_REG + 1 );
		alias  mac_lr_d			: std_logic is latch_init_delay( EN_REG + 1 );
		
		signal norm_edge			: std_logic := '0';
		signal norm_edge_pipe	: std_logic_vector( 15 downto 0 ) := ( others => '0' );
		constant NORM_EN_REG		: integer := norm_edge_pipe'high - 1;
		alias	 norm_en				: std_logic is norm_edge_pipe( NORM_EN_REG );
		alias	 norm_lr				: std_logic is norm_edge_pipe( NORM_EN_REG + 1 );
	begin
		
		norm_ctrl_process : process( clk )
		begin
			if rising_edge( clk ) then
				if rst = '1' then
					norm_edge <= '0';
					norm_edge_pipe <= ( others => '0' );
					o_norm <= '0';
				else
					norm_edge <= addr_gen_fin;
					norm_edge_pipe <= norm_edge_pipe( norm_edge_pipe'high - 1 downto 0 ) &
											( ( addr_gen_fin xor norm_edge ) and addr_gen_fin );
					o_norm <= norm_en or norm_lr;
				end if;
			end if;
		end process norm_ctrl_process;
		
		mac_ctrl_process : process( clk )
		begin
			if rising_edge( clk ) then
				if rst = '1' then
					o_en <= '0';
					o_acc <= '0';
					o_lr <= '0';
				else
					o_en <= mac_en or mac_lr;
					o_acc <= ( mac_en xor mac_en_d ) or ( mac_lr xor mac_lr_d );
					o_lr <= mac_en or norm_lr;
				end if;
			end if;
		end process mac_ctrl_process;
		
	end block CTRL_BLOCK;
	
	ADDR_GEN_BLOCK : block
		constant ADDR_FB_REG		: integer := 2;
		
		signal addr_gen			: unsigned( 24 downto 0 ) := ( others => '0' );
		signal addr_offset		: unsigned(  1 downto 0 ) := ( others => '0' );
		signal addr_adder			: unsigned( 12 downto 0 ) := ( others => '0' );
		alias  addr_gen_int		: unsigned( 12 downto 0 ) is addr_gen( 24 downto 12 );
		alias  addr_gen_frc		: unsigned( 11 downto 0 ) is addr_gen( 11 downto  0 );
		
		signal addr_next			: unsigned( 25 downto 0 ) := ( others => '0' );
		signal addr_fold			: unsigned( 12 downto 0 ) := ( others => '0' );
		
		signal addr_gen_term		: std_logic := '0';
		signal addr_ratio			: unsigned( i_ratio'range ) := ( i_ratio'high => '1', others => '0' );
	begin
		addr_gen_en <= ( i_en or ( not( addr_gen_fin ) and latch_pipeline( ADDR_FB_REG ) ) );
		
		addr_gen_fin <= addr_next( addr_next'high );
		
		addr_fold <= U_HALF_ADDER( addr_adder );
		
		addr_adder <= addr_gen_int + addr_offset;
		
		addr_next <= RESIZE( addr_gen, addr_next'length ) + addr_ratio;
		
		enable_process : process( clk )
		begin
			if rising_edge( clk ) then
				o_fin <= addr_gen_fin;
				if rst = '1' then
					addr_gen <= ( others => '0' );
					addr_ratio <= ( addr_ratio'high => '1', others => '0' );
				elsif i_en = '1' then
					addr_gen <= RESIZE( i_ratio_init, addr_gen'length );
					addr_ratio <= i_ratio;
					addr_offset <= ( others => '0' );
				elsif addr_gen_fin = '0' then
					addr_offset <= addr_offset + 1;
					if addr_gen_en = '1' then
						addr_gen <= addr_next( addr_gen'range );
						addr_offset <= ( others => '0' );
					end if;
				end if;
				
			end if; -- clock
		end process enable_process;
		
		fold_process : process( clk )
		begin
			if rising_edge( clk ) then
				fold_centre <= addr_fold( addr_fold'high );
				fold_int <= addr_fold( addr_fold'high-1 downto 0 );
				fold_frc <= addr_gen_frc;
			end if;
		end process fold_process;
	end block ADDR_GEN_BLOCK;
	
	ROM_BLOCK : block
	begin
		rom_process : process( clk )
		begin
			if rising_edge( clk ) then
				rom_coe <= COE_ROM( TO_INTEGER( fold_int ) );
				if fold_centre = '1' then
					rom_coe <= COE_CENTRE;
				end if;
			end if;
		end process rom_process;
	end block ROM_BLOCK;
	
	DX_BLOCK : block
		constant DX_MUX0_REG	: integer := 2;
		constant DX_MUX1_REG	: integer := 3;
		
		alias  mul_mux0	: std_logic is latch_pipeline( DX_MUX0_REG );
		alias  mul_mux1	: std_logic is latch_pipeline( DX_MUX1_REG );
		
		signal DX0			: signed( 14 downto 0 ) := ( others => '0' );
		signal DX1			: signed( 14 downto 0 ) := ( others => '0' );
		signal DX2			: signed( 14 downto 0 ) := ( others => '0' );
		
		signal mul_i0		: signed( 14 downto 0 ) := ( others => '0' );
		signal mul_mux_i0	: signed( 14 downto 0 ) := ( others => '0' );
		signal mul_i1		: signed( 14 downto 0 ) := ( others => '0' );
		signal mul_mux_i1	: signed( 14 downto 0 ) := ( others => '0' );
		
		signal mul_o		: signed( 29 downto 0 ) := ( others => '0' );
	begin
		DX0 <=              b"000" & SIGNED( fold_frc );
		DX1 <= SHIFT_RIGHT( b"111" & SIGNED( fold_frc ), 1 );
		DX2 <=              b"110" & SIGNED( fold_frc );
		
		mul_i0 <= DX1 when mul_mux0 = '0' else -DX0;
		mul_i1 <= DX0 when mul_mux1 = '1' else  DX2;
		
		dx <= mul_o( 25 downto 2 );
		
		muliplier_process : process( clk )
		begin
			if rising_edge( clk ) then
				if rst = '1' then
					mul_o <= ( others => '0' );
				else
					mul_o <= mul_i0 * mul_i1;
				end if;
			end if;
		end process muliplier_process;
	end block DX_BLOCK;
	
	COE_BLOCK : block
		constant MUL_PIPE_DEPTH	: integer := 5;
		constant COE_ACC_REG		: integer := 7;
		
		constant MUL_PIPE_WIDTH : integer := dx'length + COE_WIDTH - 1;
		constant COE_ACC_ROUND	: integer := MUL_PIPE_WIDTH - COE_WIDTH - 2;
		constant mul_acc_rnd		: signed( MUL_PIPE_WIDTH - 2 downto 0 ) := ( COE_ACC_ROUND => '1', others => '0' );
		
		alias  mul_acc0		: std_logic is latch_pipeline( COE_ACC_REG );
		alias  mul_acc1		: std_logic is latch_pipeline( COE_ACC_REG + 1 );
		alias  mul_out_en		: std_logic is latch_pipeline( COE_ACC_REG + 2 );
		
		type MUL_PIPE_TYPE is array( MUL_PIPE_DEPTH-2 downto 0 ) of signed( MUL_PIPE_WIDTH - 2 downto 0 );
		signal mul				: signed( MUL_PIPE_WIDTH downto 0 ) := ( others => '0' );
		signal mul_pipe		: MUL_PIPE_TYPE := ( others => ( others => '0' ) );
		signal mul_acc			: signed( MUL_PIPE_WIDTH - 2 downto 0 ) := ( others => '0' );
		signal mul_acc_en		: std_logic := '0';
		signal mul_acc_sel	: signed( MUL_PIPE_WIDTH - 2 downto 0 ) := ( others => '0' );
	begin
	
		mul <= ( dx * rom_coe );
	
		mul_acc_en <= mul_acc0 or mul_acc1;
		
		mul_acc_sel <= mul_acc when mul_acc_en = '1' else mul_acc_rnd;
		
		muliplier_process : process( clk )
		begin
			if rising_edge( clk ) then
				mul_pipe <= mul_pipe( mul_pipe'high - 1 downto 0 ) & mul( MUL_PIPE_WIDTH - 2 downto 0 );
				
				if rst = '1' then
					mul_acc <= ( others => '0' );
				else
					mul_acc <= mul_acc_sel + mul_pipe( mul_pipe'high );
				end if;
			end if;
		end process muliplier_process;
		
		output_process : process( clk )
		begin
			if rising_edge( clk ) then
				if rst = '1' then
					o_coe <= ( others => '0' );
				elsif mul_out_en = '1' then
					o_coe <= mul_acc( MUL_PIPE_WIDTH - 2 downto MUL_PIPE_WIDTH - COE_WIDTH - 1 );
				end if;
			end if;
		end process output_process;
		
	end block COE_BLOCK;

end rtl;
