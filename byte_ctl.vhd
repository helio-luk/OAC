LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use work.mips_pkg.all;

entity byte_ctl is
  port (
    store_ctl : in std_logic_vector(1 downto 0);
    a1a0      : in std_logic_vector(1 downto 0);
    byteena   : out STD_LOGIC_VECTOR (3 DOWNTO 0)
  );
end byte_ctl ;

architecture rtl of byte_ctl is

begin
    process(a1a0, store_ctl)
    begin
        if store_ctl = "10" then
            case(a1a0) is
                when "00" => byteena <= "0001";
                when "01" => byteena <= "0010";
                when "10" => byteena <= "0100";
                when "11" => byteena <= "1000";
                when others => byteena <= "1111";
            end case ;
        elsif store_ctl = "01" then
            case(a1a0) is
                when "00" | "01" => byteena <= "0011";
                when "10" | "11" => byteena <= "1100";
                when others => byteena <= "1111";
            end case ;
        else
            byteena <= "1111";
        end if ;
    end process ;
end architecture ;
