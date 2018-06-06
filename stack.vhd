library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity stack is
	port(
		push        : in  std_logic;
		input_data  : in  word_t;

		pop         : in  std_logic;
		output_data : out word_t;

		clk         : in  std_logic;
		rst         : in  std_logic
	);
end entity stack;

architecture RTL of stack is

	-- Za sad nek bude 32 reci, mislim da je dovoljno
	type stack_t is array (63 downto 0) of word_t;
	signal mem_reg, mem_next : stack_t;

	-- Stack Pointer
	signal sp_reg, sp_next : std_logic_vector(5 downto 0);
begin

	-- Sinhroni deo, klasika
	process(clk, rst) is
	begin
		if rst = '1' then
			for i in 0 to 31 loop
				mem_reg(i) <= (others => '1');
			end loop;
			sp_reg <= (others => '0');
		elsif rising_edge(clk) then
			mem_reg <= mem_next;
			sp_reg  <= sp_next;
		end if;
	end process;

	ulaz_izlaz : process(input_data, mem_reg, pop, push, sp_reg) is
	begin
		mem_next <= mem_reg;
		sp_next  <= sp_reg;

		if push then
			mem_next(to_integer(unsigned(sp_reg) + 1)) <= input_data;
			sp_next                                    <= std_logic_vector(unsigned(sp_reg) + 1);
		elsif pop then
			sp_next <= std_logic_vector(unsigned(sp_reg) - 1);
		end if;

	end process ulaz_izlaz;

	output_data <= mem_reg(to_integer(unsigned(sp_reg)));

end architecture RTL;
