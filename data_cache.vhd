library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

use std.textio.all;

entity data_cache is
	port(
		mem_dcache_in : in  mem_dcache_t;
		dcache_wb_out : out dcache_wb_t;

		clk           : in  std_logic
	);
end entity data_cache;

architecture RTL of data_cache is
	type mem_t is array ((MEM_SIZE - 1) downto 0) of word_t;

	signal mem_reg, mem_next   : mem_t;
	signal addr_reg, addr_next : addr_t;

	alias wr      : std_logic is mem_dcache_in.wr;
	alias data_in : word_t is mem_dcache_in.data_in;
	alias addr_in : addr_t is mem_dcache_in.addr_in;

	alias data_out : word_t is dcache_wb_out.data_out;
begin
	process is
		file input : text is FILE_DATA;
		variable line      : line;
		variable adr_temp  : word_t;
		variable word_temp : word_t;
		variable read_ok   : boolean;
	begin
		while not endfile(input) loop
			readline(input, line);

			-- Citanje heksadecimalnih brojeva u std_logic_vector
			hread(line, adr_temp, read_ok);
			if not read_ok then
				exit;
			end if;

			read(line, word_temp, read_ok);
			if not read_ok then
				exit;
			end if;

			mem_reg(to_integer(unsigned(adr_temp))) <= word_temp;
		end loop;
		addr_reg <= ZERO_ADDR;

		while true loop
			wait until rising_edge(clk);

			mem_reg  <= mem_next;
			addr_reg <= addr_next;
		end loop;

	end process;

	addr_next <= addr_in;

	data_out <= mem_reg(to_integer(unsigned(addr_reg)));

	upis : process(mem_reg, addr_in, data_in, wr) is
	begin
		mem_next <= mem_reg;
		if (wr = '1') then
			mem_next(to_integer(unsigned(addr_in))) <= data_in;
		end if;
	end process upis;

end architecture RTL;
