library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;

use work.cpu_types.all;

entity instr_cache is
	port(
		--clk      : in  std_logic;
		--rst      : in  std_logic;

		addr_in  : in  addr_t;
		data_out : out icache_id_t
	);
end entity instr_cache;

architecture RTL of instr_cache is
	type mem_t is array ((MEM_SIZE - 1) downto 0) of word_t;

	signal memory : mem_t;

begin

	init : process is
		file input : text is FILE_INSTR;
		variable line      : line;
		variable adr_temp  : word_t;
		variable word_temp : word_t;
		variable read_ok   : boolean;
		variable first     : boolean := true;

	begin
		while not endfile(input) loop
			readline(input, line);

			-- Ne citaj prvu liniju, pocetna vrednost PC-a
			if first then
				first := false;
				next;
			end if;

			hread(line, adr_temp, read_ok);
			if not read_ok then
				exit;
			end if;

			read(line, word_temp, read_ok);
			if not read_ok then
				exit;
			end if;

			memory(to_integer(unsigned(adr_temp))) <= word_temp;
		end loop;
		wait;
	end process init;

	data_out.instr <= memory(to_integer(unsigned(addr_in)));
	
end architecture RTL;
