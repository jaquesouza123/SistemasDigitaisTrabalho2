library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.ExponentialSearch_pkg.all;

entity ExponentialSearch is
    generic (
        ADDR_WIDTH  : integer := 8;
        DATA_WIDTH  : integer := 8
    );
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        data_av     : in std_logic;
        data        : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        pos        : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        done        : out std_logic;

        addr        : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
        data_in     : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        data_out    : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        sel         : out std_logic;
        ld          : out std_logic
    );
end ExponentialSearch;

--- Comportamental + estrutural
architecture structural of ExponentialSearch is
    signal cmd : Command;
    signal sts : Status;
begin

    CONTROL_PATH: entity work.ControlPath
        port map (
            clk     => clk,
            rst     => rst,
            data_av => data_av,
            sts     => sts,
            cmd     => cmd,
            sel     => sel,
            ld      => ld,
            done    => done
        );

    DATA_PATH: entity work.DataPath
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk     => clk,
            rst     => rst,
            data    => data,
            A       => data_in,
            cmd     => cmd,
            sts     => sts,
            addr    => addr,
            pos     => pos  
);

    data_out <= (others => '0');

end structural;

---  comportamental 
architecture behavioral of ExponentialSearch is

    type State is (
        S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16
    );
    signal currentState : State;

    signal regBase, regLen, regKey, regI     : unsigned(DATA_WIDTH - 1 downto 0);
    signal regLeft, regRight, regMid     : unsigned(DATA_WIDTH - 1 downto 0);
    signal regAddr, regPos               : unsigned(DATA_WIDTH - 1 downto 0);

begin

    process(clk, rst)
        variable diff : unsigned(DATA_WIDTH - 1 downto 0);
        variable mid_calc : unsigned(DATA_WIDTH - 1 downto 0);
    begin
        if rst = '1' then
            currentState <= S0;
            regBase  <= (others => '0');
            regLen   <= (others => '0');
            regKey   <= (others => '0');
            regI     <= (others => '0');
            regLeft  <= (others => '0');
            regRight <= (others => '0');
            regMid   <= (others => '0');
            regAddr  <= (others => '0');
            regPos   <= (others => '0');

        elsif rising_edge(clk) then
            case currentState is
                when S0 =>
                    if data_av = '1' then
                        regBase <= unsigned(data);
                        currentState <= S1;
                    else
                        currentState <= S0;
                    end if;

                when S1 =>
                    if data_av = '1' then
                        regLen <= unsigned(data);
                        currentState <= S2;
                    else
                        currentState <= S1;
                    end if;

                when S2 =>
                    if data_av = '1' then
                        regKey <= unsigned(data);
                        if unsigned(data) = 0 then
                            regPos <= x"FF";
                            currentState <= S16;
                        else
                            currentState <= S3;
                        end if;
                    else
                        currentState <= S2;
                    end if;

                when S3 =>
                    regI <= to_unsigned(1, DATA_WIDTH);
                    currentState <= S4;

                when S4 =>
                    regAddr <= regBase + regI;
                    diff := regLen - regI;
                    if diff(DATA_WIDTH - 1) = '1' then
                        currentState <= S7;
                    else
                        currentState <= S5;
                    end if;

                when S5 =>
                    diff := unsigned(data_in) - regKey;
                    if diff = 0 then
                        regPos <= regI;
                        currentState <= S16;
                    elsif diff(DATA_WIDTH - 1) = '1' then
                        currentState <= S6;
                    else
                        currentState <= S8;
                    end if;

                when S6 =>
                    regI <= shift_left(regI, 1);
                    currentState <= S4;

                when S7 =>
                    regLeft <= shift_right(regI, 1);
                    regRight <= regLen - 1;
                    currentState <= S9;

                when S8 =>
                    regLeft <= shift_right(regI, 1);
                    regRight <= regI;
                    currentState <= S9;

                when S9 =>
                    diff := regRight - regLeft;
                    if diff(DATA_WIDTH - 1) = '1' then
                        regPos <= x"FF";
                        currentState <= S16;
                    else
                        mid_calc := shift_right(regLeft + regRight, 1);
                        regMid <= mid_calc;
                        currentState <= S10;
                    end if;

                when S10 =>
                    regAddr <= regBase + regMid;
                    currentState <= S11;

                when S11 =>
                    diff := unsigned(data_in) - regKey;
                    if diff = 0 then
                        currentState <= S14;
                    elsif diff(DATA_WIDTH - 1) = '1' then
                        currentState <= S12;
                    else
                        currentState <= S13;
                    end if;

                when S12 =>
                    regLeft <= regMid + 1;
                    currentState <= S9;

                when S13 =>
                    regRight <= regMid - 1;
                    currentState <= S9;

                when S14 =>
                    regPos <= regMid;
                    currentState <= S16;

                when S15 =>
                    regPos <= x"FF";
                    currentState <= S16;

                when S16 =>
                    if data_av = '1' then
                        currentState <= S16;
                    else
                        currentState <= S0;
                    end if;

                when others =>
                    currentState <= S0;
            end case;
        end if;
    end process;

    sel  <= '1' when (currentState = S4 or currentState = S10) else '0';
    ld   <= '0';
    done <= '1' when currentState = S16 else '0';
    addr <= std_logic_vector(regAddr);
    pos <= std_logic_vector(regPos);
    data_out <= (others => '0');

end behavioral;