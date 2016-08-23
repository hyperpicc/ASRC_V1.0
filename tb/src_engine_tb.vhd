LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

LIBRARY work;
use work.src_pkg.all;
use work.src_rom_pkg.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;

ENTITY src_engine_tb IS
END src_engine_tb;

ARCHITECTURE behavior OF src_engine_tb IS 

	signal clk				: std_logic := '0';
	signal rst				: std_logic := '0';

	signal ctrl_lock		: std_logic := '1';
	signal ctrl_offset	: std_logic := '0';

	signal ratio			: unsigned( 19 downto 0 );

	signal rd_addr_int	: unsigned(  9 downto 0 ) := ( others => '0' );
	signal rd_addr_frc	: unsigned( 19 downto 0 );
	signal rd_req			: std_logic := '0';

	signal i_wr_data		: signed( 23 downto 0 ) := ( 23 => '0', others => '1' );
	signal i_wr_addr		: unsigned( 9 downto 0 ) := to_unsigned( 16, 10 );
	signal i_wr_en			: std_logic := '0';
	signal i_wr_lr			: std_logic := '0';

	signal o_data			: signed( 23 downto 0 ) := ( others => '0' );
	signal o_data_en		: std_logic := '0';
	signal o_data_lr		: std_logic := '0';
	
	signal o_coe			: signed( 25 downto 0 ) := ( others => '0' );
	signal o_coe_en		: std_logic := '0';

	signal rd_run			: std_logic := '0';
	
	 -- Clock period definitions
	 constant clk_period : time := 10 ns;

	constant	FRQ_O			: real := 192.0;
	constant	FRQ_I			: real := 96.0;

	constant ratio_real	: real := FRQ_O / FRQ_I;
	signal   ratio_sfixed: sfixed( 3 downto -19 );
	signal   ratio_limit	: sfixed( 0 downto -19 );
	
	shared variable rd_cnt			: integer := 0;
	shared variable rd_term			: integer := 0;--356;
	shared variable rd_norm			: std_logic := '0';

BEGIN
	
	INST_SRC : src_engine
		generic map (
			COE_WIDTH		=> COE_WIDTH
		)
		port map (
			clk				=> clk,
			rst				=> rst,
			
			ctrl_lock		=> ctrl_lock,
			ctrl_offset		=> ctrl_offset,
			
			ratio				=> ratio,
			
			rd_addr_int		=> rd_addr_int,
			rd_addr_frc		=> rd_addr_frc,
			rd_req			=> rd_req,
			
			i_wr_data		=> i_wr_data,
			i_wr_addr		=> i_wr_addr,
			i_wr_en			=> i_wr_en,
			i_wr_lr			=> i_wr_lr,
			
			o_data			=> o_data,
			o_data_en		=> o_data_en,
			o_data_lr		=> o_data_lr,
			
			o_coe				=> o_coe,
			o_coe_en			=> o_coe_en
		);
 
	ratio_sfixed <= to_sfixed( ratio_real, ratio_sfixed );
	ratio_limit <= ( 0 => '1', others => '0' ) when ratio_sfixed( 3 downto 0 ) > 0 else ratio_sfixed( ratio_limit'range );
	ratio <= unsigned( std_logic_vector( ratio_limit ) );
	rd_addr_frc <= ( 18 => '1', others => '0' );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
	
	stim_proc : process( clk )
	begin
		if rising_edge( clk ) then
			if rd_run = '1' then
				rd_req <= '0';
				
				if rd_cnt <= rd_term then
					if rd_norm = '0' then
						rd_req <= '1';
						rd_cnt := rd_cnt + 1;
					elsif o_data_en = '1' and o_data_lr = '1' then
						rd_req <= '1';
						rd_cnt := rd_cnt + 1;
					end if;
				end if;
				if rd_req = '1' then
					rd_addr_int <= rd_addr_int + 1;
				end if;
				rd_norm := '1';
			end if;
		end if;
	end process;
	
--	read_process : process( clk )
--		file		outfile	: text is out "test/src_impulse.txt";
--		variable outline	: line;
--	begin
--		if rising_edge( clk ) then
--			if ( o_data_en and o_data_lr ) = '1' then
--				write( outline, to_integer( o_data ) );
--				writeline( outfile, outline );
--			end if;
--		end if;
--	end process;
	
	coe_process : process( clk )
		file		outfile	: text is out "test/src_impulse_coe.txt";
		variable outline	: line;
	begin
		if rising_edge( clk ) then
			if o_coe_en= '1' then
				write( outline, to_integer( o_coe ) );
				writeline( outfile, outline );
			end if;
		end if;
	end process;

	tb : PROCESS
	BEGIN
		wait until rising_edge( clk );
		i_wr_en <= '1';
		i_wr_lr <= '0';
		wait until rising_edge( clk );
		i_wr_en <= '1';
		i_wr_lr <= '1';
		wait until rising_edge( clk );
		i_wr_en <= '0';
		i_wr_lr <= '0';
		
		wait until rising_edge( clk );
		rd_run <= '1';
		
		wait;
	END PROCESS tb;

END;
