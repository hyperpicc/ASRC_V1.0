library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity src_ring_buffer is
	port (
		clk			: in  std_logic;
		rst			: in  std_logic;
		
		i_wr_data	: in  signed( 23 downto 0 );
		i_wr_addr	: in  unsigned( 8 downto 0 );
		i_wr_en		: in  std_logic;
		i_wr_lr		: in  std_logic;
		
		o_rd_data	: out signed( 23 downto 0 ) := ( others => '0' );
		i_rd_addr	: in  unsigned( 8 downto 0 );
		i_rd_offset	: in  std_logic;
		i_rd_preset	: in  std_logic;
		i_rd_step	: in  std_logic
	);
end src_ring_buffer;

architecture rtl of src_ring_buffer is
	constant OS_ENABLE	: unsigned( 6 downto 0 ) := to_unsigned( 64, 7 );
	constant OS_NENABLE	: unsigned( 6 downto 0 ) := to_unsigned( 16, 7 );

	type RBUF_RAM_TYPE is array( 1023 downto 0 ) of signed( 23 downto 0 );
	signal ram	: RBUF_RAM_TYPE 	:= ( others => ( others => '0' ) );
	
	signal rd_addr		: unsigned( 9 downto 0 ) := ( others => '0' );
	alias  rd_count	: unsigned( 8 downto 0 ) is rd_addr( 9 downto 1 );
	alias  rd_lr		: std_logic is rd_addr( 0 );
	signal rd_latch	: unsigned( 8 downto 0 ) := ( others => '0' );
	signal rd_offset	: unsigned( 6 downto 0 ) := to_unsigned( 16, 7 );
begin

	write_process : process( clk )
	begin
		if rising_edge( clk ) then
			if i_wr_en = '1' then
				ram( TO_INTEGER( i_wr_addr & i_wr_lr ) ) <= i_wr_data;
			end if;
		end if;
	end process write_process;
	
	rd_offset <= ( 6 => i_rd_offset, 4 => not( i_rd_offset ), others => '0' );
	
	rd_latch <= i_rd_addr - TO_INTEGER( rd_offset );
	
	rd_lr <= i_rd_step;
	
	read_process : process( clk )
	begin
		if rising_edge( clk ) then
			if rst = '1' then
				rd_count <= ( others => '0' );
			elsif i_rd_preset = '1' then
				rd_count <= rd_latch;
			elsif i_rd_step = '1' then
				rd_count <= rd_count - 1;
			end if;
			
			o_rd_data <= ram( TO_INTEGER( rd_addr ) );
		end if;
	end process read_process;

end rtl;
