library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

package src_pkg is

	impure function U_ABS( i : unsigned ) return unsigned;
	impure function U_XOR( i : unsigned ) return unsigned;
	impure function U_HALF_ADDER( i : unsigned ) return unsigned;
	
	component src_engine is
		generic (
			COE_WIDTH		: integer := 24
		);
		port (
			clk				: in  std_logic;
			rst				: in  std_logic;
			
			ctrl_lock		: in  std_logic;
			ctrl_offset		: in  std_logic;
			
			ratio				: in  unsigned( 19 downto 0 );
			
			rd_addr_int		: in  unsigned(  9 downto 0 );
			rd_addr_frc		: in  unsigned( 19 downto 0 );
			rd_req			: in  std_logic;
			
			i_wr_data		: in  signed( 23 downto 0 );
			i_wr_addr		: in  unsigned( 9 downto 0 );
			i_wr_en			: in  std_logic;
			i_wr_lr			: in  std_logic;
			
			o_data			: out signed( 23 downto 0 ) := ( others => '0' );
			o_data_en		: out std_logic := '0';
			o_data_lr		: out std_logic := '0';
			
			o_coe				: out signed( 25 downto 0 ) := ( others => '0' );
			o_coe_en			: out std_logic := '0'
		);
	end component src_engine;
	
	component ramp_gen is
		port (
			clk			: in  std_logic;
			rst			: in  std_logic;
			lock			: in  std_logic;
			
			fs_i_en		: in  std_logic;
			fs_i_addr	: out unsigned(  9 downto 0 );
			fs_o_en		: in  std_logic;
			
			ramp_en		: out std_logic;
			ramp_int		: out unsigned(  9 downto 0 );
			ramp_frc		: out unsigned( 19 downto 0 )
		);
	end component ramp_gen;
	
	component ratio_gen is
		port (
			clk				: in  std_logic;
			rst				: in  std_logic;
			lock				: out std_logic;
			
			fs_i_en			: in  std_logic;
			fs_o_clk			: in  std_logic;
			fs_o_en			: in  std_logic;
			
			ratio				: out unsigned( 19 downto 0 )
		);
	end component ratio_gen;
	
	component src_interpolator is
		generic (
			COE_WIDTH		: integer := 24
		);
		port (
			clk				: in  std_logic;
			rst				: in  std_logic;
			
			i_ratio			: in  unsigned( 17 downto 0 );
			i_ratio_init	: in  unsigned( 16 downto 0 );
			i_en				: in  std_logic;
			
			o_coe				: out signed( COE_WIDTH-1 downto 0 );
			o_fin				: out std_logic;
			o_en				: out std_logic;
			o_acc				: out std_logic;
			o_lr				: out std_logic;
			o_norm			: out std_logic
		);
	end component src_interpolator;
	
	component src_mac is
		generic (
			COE_WIDTH		: integer := 24
		);
		port (
			clk			: in  std_logic;
			rst			: in  std_logic;
			
			i_ratio		: in  unsigned( 19 downto 0 );
			i_coe			: in	signed( COE_WIDTH-1 downto 0 );
			i_data		: in  signed( 23 downto 0 );
			
			i_ctrl_norm	: in  std_logic;
			i_ctrl_en	: in  std_logic;
			i_ctrl_acc	: in  std_logic;
			i_ctrl_lr	: in  std_logic;
			
			o_data		: out signed( 23 downto 0 );
			o_data_en	: out std_logic;
			o_data_lr	: out std_logic
		);
	end component src_mac;
	
	component src_ring_buffer is
		port (
			clk			: in  std_logic;
			rst			: in  std_logic;
			
			i_wr_data	: in  signed( 23 downto 0 );
			i_wr_addr	: in  unsigned( 9 downto 0 );
			i_wr_en		: in  std_logic;
			i_wr_lr		: in  std_logic;
			
			o_rd_data	: out signed( 23 downto 0 );
			i_rd_addr	: in  unsigned( 9 downto 0 );
			i_rd_offset	: in  std_logic;
			i_rd_preset	: in  std_logic;
			i_rd_step	: in  std_logic
		);
	end component src_ring_buffer;
	
	component divider_top is 
		generic (
			DIV_WIDTH	: natural := 26
		);
		port (
			clk			: in  std_logic;
			rst			: in  std_logic;
			
			i_en			: in  std_logic;
			i_divisor	: in  unsigned( DIV_WIDTH-1 downto 0 );
			i_dividend	: in  unsigned( DIV_WIDTH-1 downto 0 );
			
			o_fin			: out std_logic := '0';
			o_remainder	: out unsigned( DIV_WIDTH-1 downto 0 )
		);
	end component divider_top;
	
	component lpf_top is
		generic (
			LPF_WIDTH		: natural range 8 to 64 := 16
		);
		port (
			clk			: in  std_logic;
			rst			: in  std_logic;
			
			lpf_in		: in  signed( LPF_WIDTH - 1 downto 0 );
			lpf_in_en	: in  std_logic;
			
			lpf_out		: out signed( LPF_WIDTH - 1 downto 0 )
		);
	end component lpf_top;

end src_pkg;

package body src_pkg is
	
	impure function U_ABS( i : unsigned ) return unsigned is
	begin
		return unsigned( abs( signed( i ) ) );
	end function U_ABS;

	impure function U_XOR( i : unsigned ) return unsigned is
		variable mask : unsigned( i'high - 1 downto 0 );
	begin
		mask := ( others => i( i'high ) );
		return mask xor i( i'high - 1 downto 0 );
	end function U_XOR;
	
	impure function U_HALF_ADDER( i : unsigned ) return unsigned is
		variable o		: unsigned( i'high - 1 downto 0 );
		variable x 		: unsigned( i'high - 1 downto 0 );
		variable carry	: std_logic;
	begin
		x := U_XOR( i );
		
		carry := i( i'high );
		for i in 0 to o'high loop
			o( i ) := x( i ) xor carry;
			carry := carry and x( i );
		end loop;
		
		return carry & o;
	end function U_HALF_ADDER;

end src_pkg;
