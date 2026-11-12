library IEEE;
use IEEE.std_logic_1164.all;

package ExponentialSearch_pkg is

    -- Sinais de controle do ControlPath para o DataPath 
    type Command is record
        ld_base     : std_logic;
        ld_len      : std_logic;
        ld_key      : std_logic;
        ld_i        : std_logic;
        ld_addr     : std_logic;
        ld_left     : std_logic;
        ld_right    : std_logic;
        ld_mid      : std_logic;
        ld_pos      : std_logic;
        sel_pos     : std_logic;
        mem         : std_logic;
        done        : std_logic;
        sel_i       : std_logic;
        sel_left    : std_logic;
        sel_right   : std_logic;
        sx1_0       : std_logic;
        sx1_1       : std_logic;
        sx1_2       : std_logic;
        sy1_0       : std_logic;
        sy1_1       : std_logic;
        sub1        : std_logic;
        sx2         : std_logic;
        sy2_0       : std_logic;
        sy2_1       : std_logic;
    end record;

   
    type Status is record
        zero        : std_logic; 
        neg         : std_logic; 
    end record;

end ExponentialSearch_pkg;