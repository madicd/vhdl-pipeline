library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity comparator is
	generic(
		SIZE : natural
	);
	port(
		-- ulazni signali
		a  : in  std_logic_vector(SIZE - 1 downto 0);
		b  : in  std_logic_vector(SIZE - 1 downto 0);
		op : in  cmp_op_t;

		-- izlazni signali
		ok : out std_logic
	);
end entity comparator;

architecture RTL of comparator is
begin
	main : process(a, b, op) is
	begin
		ok <= '0';

		case op is
			when CMP_EQ =>
				if a = b then
					ok <= '1';
				end if;
			when CMP_NQ =>
				if a /= b then
					ok <= '1';
				end if;

			when CMP_GE =>
				if a >= b then
					ok <= '1';
				end if;

			when CMP_LE =>
				if a <= b then
					ok <= '1';
				end if;

			when CMP_LT =>
				if a < b then
					ok <= '1';
				end if;

			when CMP_GT =>
				if a > b then
					ok <= '1';
				end if;

			when CMP_ALWAYS_TRUE =>
				ok <= '1';

			when others => null;
		end case;

	end process main;

end architecture RTL;
