library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Adder_nbits is
    generic (
        WIDTH : integer := 8 -- parametrização
    );
    port (
        a       : in std_logic_vector(WIDTH - 1 downto 0);
        b       : in std_logic_vector(WIDTH - 1 downto 0);
        sum     : out std_logic_vector(WIDTH - 1 downto 0);
        cin     : in std_logic;
        cout    : out std_logic
    );
end Adder_nbits;

architecture behavioral of Adder_nbits is
    signal res : unsigned(WIDTH downto 0);
begin
    res  <= ('0' & unsigned(a)) + ('0' & unsigned(b)) + ("0" & cin);
    sum  <= std_logic_vector(res(WIDTH - 1 downto 0));
    cout <= res(WIDTH);
end behavioral;