library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity reg_file is
	port(
		rd_addr1_in  : in  regfile_adr_t;
		rd_addr2_in  : in  regfile_adr_t;

		rd_data1_out : out word_t;
		rd_data2_out : out word_t;

		wr_addr_in   : in  regfile_adr_t;
		wr_data_in   : in  word_t;

		wr_in        : in  std_logic;

		clk          : in  std_logic;
		rst          : in  std_logic
	);
end entity reg_file;

architecture RTL of reg_file is
	type regfile_t is array (31 downto 0) of word_t;
	signal reg_reg, reg_next : regfile_t;
begin

	-- Sinhroni deo, menjanje registarskog fajla na takt
	-- i generisanje reg_next

	process(clk, rst) is
	begin
		if rst = '1' then
			for i in 0 to 31 loop
				-- Ovako treba
				reg_reg(i) <= ZERO_WORD;

				-- Samo za testiranje
				-- reg_reg(i) <= word_t(to_unsigned(i, WORD_SIZE));
			end loop;
		elsif rising_edge(clk) then
			reg_reg <= reg_next;
		end if;
	end process;

	process(wr_in, reg_reg, wr_addr_in, wr_data_in) is
	begin
		reg_next <= reg_reg;
		if (wr_in = '1') then
			reg_next(to_integer(unsigned(wr_addr_in))) <= wr_data_in;
		end if;
	end process;

	-- Citanje iz registarskog fajla na osnovu adresa sa ulaza

	rd_data1_out <= reg_reg(to_integer(unsigned(rd_addr1_in)));
	rd_data2_out <= reg_reg(to_integer(unsigned(rd_addr2_in)));

end architecture RTL;
