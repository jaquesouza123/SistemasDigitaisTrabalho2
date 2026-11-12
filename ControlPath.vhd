library IEEE;
use IEEE.std_logic_1164.all;
use work.ExponentialSearch_pkg.all;

entity ControlPath is
    port (
        clk     : in std_logic;
        rst     : in std_logic;
        data_av : in std_logic; -- pino 'd' no NextState
        sts     : in Status;    -- sts.neg ('n') e sts.zero ('z')
        cmd     : out Command;
        sel     : out std_logic; -- pino 'mem' no Logisim
        ld      : out std_logic; -- constante '0' no Logisim
        done    : out std_logic
    );
end ControlPath;

architecture behavioral of ControlPath is

    signal q : std_logic_vector(4 downto 0); -- q(4)=q4, q(3)=q3, q(2)=q2, q(1)=q1, q(0)=q0
    signal d : std_logic_vector(4 downto 0); -- D4..D0
    signal n, z, av : std_logic;

begin

    n  <= sts.neg;
    z  <= sts.zero;
    av <= data_av;

    -- Registrador de Estados (5 Flip-Flops D)
    process(clk, rst)
    begin
        if rst = '1' then
            q <= "00000";
        elsif rising_edge(clk) then
            q <= d;
        end if;
    end process;

    -- Lógica de Próximo Estado (NextState do Logisim)
    d(4) <= q(4) and q(0) and n;

    d(3) <= (q(3) and not q(2)) or
            (not q(3) and q(2) and q(1) and q(0)) or
            (q(3) and not q(1) and not q(0)) or
            (q(3) and q(1) and q(0) and not n);

    d(2) <= (not q(3) and not q(2) and q(1) and q(0)) or
            (not q(3) and q(2) and not q(1) and not q(0)) or
            (not q(3) and q(2) and not q(1) and q(0) and not z and n) or
            (not q(3) and q(2) and q(1) and not q(0) and z) or
            (q(3) and not q(2) and not q(1) and q(0) and not z) or
            (q(3) and not q(2) and q(1) and not q(0)) or
            (q(3) and not q(2) and q(1) and q(0) and n);

    d(1) <= (not q(4) and not q(3) and not q(2) and not q(1) and q(0)) or
            (not q(3) and not q(2) and q(1) and not q(0)) or
            (not q(3) and q(2) and not q(1) and q(0) and z) or
            (not q(3) and q(2) and not q(1) and q(0) and not n) or
            (not q(3) and q(2) and q(1) and not q(0) and not z) or
            (q(3) and not q(2) and not q(1) and q(0) and z) or
            (q(3) and not q(2) and q(1) and not q(0)) or
            (q(3) and q(2) and not q(1) and not q(0)) or
            (q(3) and q(2) and not q(1) and q(0) and not z and not n);

    d(0) <= (not q(4) and not q(3) and not q(2) and not q(1) and not q(0) and av) or
            (not q(3) and not q(2) and q(1) and not q(0)) or
            (not q(3) and q(2) and not q(1) and not q(0)) or
            (not q(3) and q(2) and q(1) and not q(0) and not z) or
            (q(3) and not q(2) and not q(1) and not q(0)) or
            (q(3) and q(2) and not q(1) and not q(0)) or
            (q(3) and q(2) and not q(1) and q(0) and n) or
            (q(3) and q(2) and q(1) and not q(0)) or
            (q(3) and q(2) and q(1) and q(0));

    -- Saídas de Carga dos Registradores e Memória (Output_Registers do Logisim)
    cmd.ld_base  <= (not q(4)) and (not q(3)) and (not q(2)) and (not q(1)) and q(0);
    cmd.ld_len   <= (not q(3)) and (not q(2)) and q(1) and (not q(0));
    cmd.ld_key   <= (not q(3)) and (not q(2)) and q(1) and q(0);

    cmd.ld_i     <= ((not q(3)) and q(2) and (not q(1)) and (not q(0))) or
                    (q(3) and (not q(2)) and (not q(1)) and (not q(0)));

    cmd.ld_addr  <= ((not q(3)) and q(2) and (not q(1)) and q(0)) or
                    (q(3) and q(2) and (not q(1)) and (not q(0)));

    cmd.ld_left  <= ((not q(3)) and q(2) and q(1) and q(0)) or
                    (q(3) and q(2) and q(1) and (not q(0)));

    cmd.ld_right <= ((not q(3)) and q(2) and q(1) and q(0)) or
                    (q(3) and (not q(2)) and q(1) and (not q(0))) or
                    (q(3) and q(2) and q(1) and q(0));

    cmd.ld_mid   <= q(3) and q(2) and (not q(1)) and q(0);

    cmd.ld_pos   <= ((not q(3)) and q(2) and q(1) and (not q(0)) and z) or
                    (q(3) and (not q(2)) and (not q(1)) and q(0) and z) or
                    (q(3) and q(2) and (not q(1)) and q(0) and z) or
                    (q(3) and q(2) and q(1) and (not q(0)) and (not n));

    cmd.sel_pos  <= q(3) and q(2) and (not q(1)) and q(0);

    sel          <= ((not q(3)) and q(2) and q(1) and (not q(0))) or
                    (q(3) and (not q(2)) and (not q(1)) and q(0)) or
                    (q(3) and q(2) and (not q(1)) and q(0));

    done         <= q(4) and (not q(3)) and (not q(2)) and (not q(1)) and (not q(0));
    ld           <= '0'; -- No seu circuito ExponentialSearch, ld é ligado na constante 0

    -- Saídas de Seleção dos Multiplexadores (Output_Muxes do Logisim)
    cmd.sel_i     <= q(3) and (not q(2));
    cmd.sel_left  <= q(3) and q(2);
    cmd.sel_right <= q(3) and q(2);

    cmd.sx1_0     <= ((not q(3)) and q(2)) or (q(3) and q(2));
    cmd.sx1_1     <= (q(3) and (not q(2)) and (not q(1))) or (q(3) and q(2) and q(1));
    cmd.sx1_2     <= q(3) and (not q(2)) and q(1);

    cmd.sy1_0     <= ((not q(3)) and q(2) and (not q(1))) or (q(3) and q(2) and (not q(1)));
    cmd.sy1_1     <= ((not q(3)) and q(2) and q(1)) or (q(3) and (not q(2)) and (not q(1)));

    cmd.sub1      <= ((not q(3)) and q(2)) or (q(3) and (not q(2)) and (not q(1))) or (q(3) and q(2) and q(1));
    cmd.sx2       <= q(3) and q(2) and (not q(1));
    cmd.sy2_0     <= q(3) and q(2) and (not q(1));
    cmd.sy2_1     <= q(3) and (not q(2)) and q(1);

end behavioral;