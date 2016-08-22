LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY time_util IS
	generic (
		frq_m		: real :=  24576.0 * 4.0;
		frq		: real :=  44.1
	);
	port (
		clk_m		: out std_logic := '0';
		clk		: out std_logic := '0';
		clk_en	: out std_logic := '0';
		clk_lr	: out std_logic := '0'
	);
END time_util;
 
ARCHITECTURE behavior OF time_util IS 
	constant clk_period	: time := ( 1.0 / ( 64.0 * frq ) ) * 1 ms;

	signal	clk_o			: std_logic := '0';
	signal   clk_sig		: std_logic := '1';
	signal   clk_buf		: std_logic := '0';
	signal   clk_stb		: std_logic := '0';
	
	component time_util_top IS
		generic (
			frq		: real := frq_m
		);
		port (
			clk_m		: out	std_logic
		);
	END component time_util_top;
BEGIN
	clk_m <= clk_o;

	inst_top : time_util_top
		generic map (
			frq		=> frq_m
		)
		port map (
			clk_m		=> clk_o
		);

	clk_gen : process
	begin
		clk_sig <= '0';
		wait for clk_period/2;
		clk_sig <= '1';
		wait for clk_period/2;
	end process;
	
	clk_stb_process : process( clk_o )
	begin
		if rising_edge( clk_o ) then
			clk_buf <= clk_sig;
			clk_stb <= ( clk_buf xor clk_sig ) and clk_sig;
		end if;
	end process;
	
	clk_out_process : process( clk_o )
		variable clk_cnt : unsigned( 5 downto 0 ) := ( others => '0' );
	begin
		if rising_edge( clk_o ) then
			clk <= clk_stb;
			clk_en <= '0';
			clk_lr <= '0';
			if clk_stb = '1' then
				if clk_cnt = 31 or clk_cnt = 63 then
					clk_en <= '1';
				end if;
				if clk_cnt = 63 then
					clk_lr <= '1';
				end if;
				clk_cnt :=  clk_cnt + 1;
			end if;
		end if;
	end process;
END;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY time_util_top IS
	generic (
		frq		: real :=  24576.0 * 6.0
	);
	port (
		clk_m		: out	std_logic
	);
END time_util_top;
 
ARCHITECTURE behavior OF time_util_top IS 
	constant clk_period	: time := ( 1.0 / frq ) * 1 ms;
BEGIN

	clk_gen : process
	begin
		clk_m <= '0';
		wait for clk_period/2;
		clk_m <= '1';
		wait for clk_period/2;
	end process;
END;
