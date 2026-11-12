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
        pos         : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        done        : out std_logic;

        -- Memory interface
        addr        : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
        data_in     : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        data_out    : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        sel         : out std_logic;
        ld          : out std_logic
    );
end ExponentialSearch;

-- =========================================================================
-- ARCHITECTURE 1: ESTRUTURAL + COMPORTAMENTAL (ControlPath + DataPath)
-- =========================================================================
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

-- =========================================================================
-- ARCHITECTURE 2: TOTALMENTE COMPORTAMENTAL (FSMD Ciclo-a-Ciclo Idêntica)
-- =========================================================================
architecture behavioral of ExponentialSearch is

    type State is (
        S0,  -- 00000: Idle
        S1,  -- 00001: ld_base
        S2,  -- 00010: ld_len
        S3,  -- 00011: ld_key
        S4,  -- 00100: i = 1
        S5,  -- 00101: addr = base + i
        S6,  -- 00110: mem read (i < len && A < key?)
        S7,  -- 00111: init left = i>>1, right = i
        S8,  -- 01000: i = i << 1
        S9,  -- 01001: mem read check
        S10, -- 01010: right = len - 1
        S12, -- 01100: addr = left + mid (calc)
        S13, -- 01101: ld_mid & mem read
        S14, -- 01110: left = mid + 1
        S15, -- 01111: right = mid - 1
        S16  -- 10000: Done
    );
    signal currentState : State;

    signal regBase, regLen, regKey, regI : unsigned(DATA_WIDTH - 1 downto 0);
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
                        currentState <= S1;
                    else
                        currentState <= S0;
                    end if;

                when S1 =>
                    regBase <= unsigned(data);
                    currentState <= S2;

                when S2 =>
                    regLen <= unsigned(data);
                    currentState <= S3;

                when S3 =>
                    regKey <= unsigned(data);
                    currentState <= S4;

                when S4 =>
                    regI <= to_unsigned(1, DATA_WIDTH);
                    currentState <= S5;

                when S5 =>
                    regAddr <= regBase + regI;
                    diff := regLen - regI;
                    if diff = 0 then
                        currentState <= S7;
                    elsif diff(DATA_WIDTH - 1) = '1' then -- n = 1
                        currentState <= S6;
                    else
                        currentState <= S7;
                    end if;

                when S6 =>
                    diff := unsigned(data_in) - regKey;
                    if diff = 0 then
                        regPos <= regMid; -- sel_pos = 0 -> 0xFF no hardware
                        regPos <= x"FF";
                        currentState <= S16;
                    elsif diff(DATA_WIDTH - 1) = '1' then
                        currentState <= S8;
                    else
                        currentState <= S7;
                    end if;

                when S7 =>
                    regLeft  <= shift_right(regI, 1);
                    regRight <= regI;
                    currentState <= S12;

                when S8 =>
                    regI <= shift_left(regI, 1);
                    currentState <= S9;

                when S9 =>
                    diff := unsigned(data_in) - regKey;
                    if diff = 0 then
                        regPos <= x"FF";
                        currentState <= S16;
                    elsif diff(DATA_WIDTH - 1) = '1' then
                        currentState <= S10;
                    else
                        currentState <= S5;
                    end if;

                when S10 =>
                    regRight <= regLen - 1;
                    currentState <= S7;

                when S12 =>
                    regAddr <= regLeft + regRight;
                    diff := regRight - regLeft;
                    if diff(DATA_WIDTH - 1) = '1' then
                        currentState <= S16;
                    else
                        currentState <= S13;
                    end if;

                when S13 =>
                    mid_calc := shift_right(regLeft + regRight, 1);
                    regMid <= mid_calc;
                    diff := unsigned(data_in) - regKey;
                    if diff = 0 then
                        regPos <= mid_calc;
                        currentState <= S16;
                    elsif diff(DATA_WIDTH - 1) = '1' then
                        currentState <= S14;
                    else
                        currentState <= S15;
                    end if;

                when S14 =>
                    regLeft <= regMid + 1;
                    currentState <= S12;

                when S15 =>
                    regRight <= regMid - 1;
                    currentState <= S12;

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

    -- Saídas combinacionais concorrentes
    sel      <= '1' when (currentState = S6 or currentState = S9 or currentState = S13) else '0';
    ld       <= '0';
    done     <= '1' when currentState = S16 else '0';
    addr     <= std_logic_vector(regAddr);
    pos      <= std_logic_vector(regPos);
    data_out <= (others => '0');

end behavioral;