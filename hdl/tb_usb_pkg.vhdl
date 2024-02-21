library vunit_lib;
    context vunit_lib.vunit_context;

library osvvm;
    context osvvm.osvvmcontext;

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use work.usb_pkg.all;
    use work.ulpi_pkg.all;

package tb_usb_pkg is

    constant LINESTATE_SQUELCH  : std_logic_vector(1 downto 0) := "00";
    constant LINESTATE_NSQUELCH : std_logic_vector(1 downto 0) := "01";
    constant LINESTATE_SE0      : std_logic_vector(1 downto 0) := "00";
    constant LINESTATE_K        : std_logic_vector(1 downto 0) := "01";
    constant LINESTATE_J        : std_logic_vector(1 downto 0) := "10";

    constant VBUS_SESSEND : std_logic_vector(1 downto 0) := "00";
    constant VBUS_NOSESS  : std_logic_vector(1 downto 0) := "01";
    constant VBUS_SESSVLD : std_logic_vector(1 downto 0) := "10";
    constant VBUS_VBUSVLD : std_logic_vector(1 downto 0) := "11";

    constant RXEVENT_IDLE           : std_logic_vector(1 downto 0) := "00";
    constant RXEVENT_RXACTIVE       : std_logic_vector(1 downto 0) := "01";
    constant RXEVENT_RXERROR        : std_logic_vector(1 downto 0) := "11";
    constant RXEVENT_HOSTDISCONNECT : std_logic_vector(1 downto 0) := "10";

    constant OTG_A : std_logic := '0';
    constant OTG_B : std_logic := '1';

    constant ALT_INT_USB    : std_logic := '0';
    constant ALT_INT_CARKIT : std_logic := '1';

    constant TX_END_DELAY       : natural := 9;
    constant RX_CMD_DELAY       : natural := 8;
    constant LINK_DECISION_TIME : natural := 14;

    procedure host_send (
        signal ulpi_clock : in std_logic;
        signal i_ulpi     : inout t_from_ulpi;
        signal o_ulpi     : in t_to_ulpi;

        constant PID  : in std_logic_vector(3 downto 0);
        constant data : in std_logic_vector;

        constant NXT_EVERY : in natural := 3
    );

    procedure rx_cmd_transaction (
        signal ulpi_clock : in std_logic;
        signal i_ulpi     : inout t_from_ulpi;
        signal o_ulpi     : in t_to_ulpi;

        constant linestate  : in std_logic_vector(1 downto 0);
        constant vbus_state : in std_logic_vector(1 downto 0);
        constant rx_event   : in std_logic_vector(1 downto 0);
        constant id         : in std_logic;
        constant alt_int    : in std_logic
    );

    procedure sess_vld_interrupt (
        signal ulpi_clock : in std_logic;
        signal i_ulpi     : inout t_from_ulpi;
        signal o_ulpi     : in t_to_ulpi
    );

    procedure host_receive (
        signal ulpi_clock : in std_logic;
        signal i_ulpi     : inout t_from_ulpi;
        signal o_ulpi     : in t_to_ulpi
    );

    procedure ulpi_reg_receive (
        signal ulpi_clock : in std_logic;
        signal i_ulpi     : inout t_from_ulpi;
        signal o_ulpi     : in t_to_ulpi
    );

end package tb_usb_pkg;

package body tb_usb_pkg is

    procedure rx_cmd_end (
        signal ulpi_clock : in std_logic;
        signal i_ulpi     : out t_from_ulpi;
        signal o_ulpi     : in t_to_ulpi
    ) is
    begin

        i_ulpi.dir  <= '0';
        i_ulpi.nxt  <= '0';
        i_ulpi.data <= (others => 'Z');
        WaitForClock(ulpi_clock); -- turnaround

    end procedure;

    procedure rx_cmd (
        signal ulpi_clock : in std_logic;
        signal i_ulpi     : inout t_from_ulpi;
        signal o_ulpi     : in t_to_ulpi;

        constant linestate  : in std_logic_vector(1 downto 0);
        constant vbus_state : in std_logic_vector(1 downto 0);
        constant rx_event   : in std_logic_vector(1 downto 0);
        constant id         : in std_logic;
        constant alt_int    : in std_logic
    ) is
    begin

        i_ulpi.nxt <= '0';

        if (i_ulpi.dir = '0') then
            i_ulpi.dir <= '1';
            WaitForClock(ulpi_clock, 1); -- turnaround
        end if;

        i_ulpi.data <= linestate & vbus_state & rx_event & id & alt_int;
        WaitForClock(ulpi_clock);

    end procedure;

    procedure rx_cmd_transaction (
        signal ulpi_clock : in std_logic;
        signal i_ulpi     : inout t_from_ulpi;
        signal o_ulpi     : in t_to_ulpi;

        constant linestate  : in std_logic_vector(1 downto 0);
        constant vbus_state : in std_logic_vector(1 downto 0);
        constant rx_event   : in std_logic_vector(1 downto 0);
        constant id         : in std_logic;
        constant alt_int    : in std_logic
    ) is
    begin

        rx_cmd(ulpi_clock, i_ulpi, o_ulpi, linestate, vbus_state, rx_event, id, alt_int);
        rx_cmd_end(ulpi_clock, i_ulpi, o_ulpi);

    end procedure;

    procedure sess_vld_interrupt (
        signal ulpi_clock : in std_logic;
        signal i_ulpi     : inout t_from_ulpi;
        signal o_ulpi     : in t_to_ulpi
    ) is
    begin

        rx_cmd_transaction(ulpi_clock, i_ulpi, o_ulpi, LINESTATE_SQUELCH, VBUS_SESSVLD, RXEVENT_IDLE, OTG_A, ALT_INT_USB);

    end procedure;

    procedure data_send (
        signal ulpi_clock : in std_logic;
        signal i_ulpi     : out t_from_ulpi;

        constant data : in std_logic_vector(7 downto 0)
    ) is
    begin

        i_ulpi.nxt  <= '1';
        i_ulpi.data <= data;
        WaitForClock(ulpi_clock);

    end procedure;

    procedure host_send (
        signal ulpi_clock : in std_logic;
        signal i_ulpi     : inout t_from_ulpi;
        signal o_ulpi     : in t_to_ulpi; -- DELETE

        constant PID  : in std_logic_vector(3 downto 0);
        constant DATA : in std_logic_vector;

        constant NXT_EVERY : in natural := 3
    ) is

        variable current_byte : std_logic_vector(7 downto 0);
    -- variable byte_count : std_logic_vector(7 downto 0);

    begin

        report "SENDING: " & to_string(DATA) & " OF LEN: " & to_string(DATA'length);

        if (i_ulpi.dir = '0') then
            i_ulpi.nxt <= '1';
            i_ulpi.dir <= '1';
            WaitForClock(ulpi_clock, 1); -- turnaround

            report "SENDING1: nxt: " & to_string(i_ulpi.nxt) & " dir: " & to_string(i_ulpi.dir);

        else
            rx_cmd_transaction(ulpi_clock, i_ulpi, o_ulpi, LINESTATE_SQUELCH, VBUS_SESSVLD, RXEVENT_RXACTIVE, OTG_A, ALT_INT_USB);
            report "SENDING1: nxt: " & to_string(i_ulpi.nxt) & " dir: " & to_string(i_ulpi.dir);

        end if;

        rx_cmd(ulpi_clock, i_ulpi, o_ulpi, LINESTATE_SQUELCH, VBUS_SESSVLD, RXEVENT_RXACTIVE, OTG_A, ALT_INT_USB);
        report "SENDING1: nxt: " & to_string(i_ulpi.nxt) & " dir: " & to_string(i_ulpi.dir);


        data_send(ulpi_clock, i_ulpi, pid & not pid);
        report "SENDING1: nxt: " & to_string(i_ulpi.nxt) & " dir: " & to_string(i_ulpi.dir);


        for i in 0 to DATA'length / 8 - 1 loop

            if (i mod NXT_EVERY = 1) then -- add NXT throttling
                rx_cmd(ulpi_clock, i_ulpi, o_ulpi, LINESTATE_SQUELCH, VBUS_SESSVLD, RXEVENT_RXACTIVE, OTG_A, ALT_INT_USB);
            end if;

            current_byte := DATA(i * 8 to (i + 1) * 8 - 1);

            data_send(ulpi_clock, i_ulpi, current_byte);

        end loop;

        rx_cmd_end(ulpi_clock, i_ulpi, o_ulpi);

    end procedure;

    procedure host_receive (
        signal ulpi_clock : in std_logic;
        signal i_ulpi     : inout t_from_ulpi;
        signal o_ulpi     : in t_to_ulpi
    ) is

        variable cmd   : std_logic_vector(1 downto 0);
        variable pid   : std_logic_vector(3 downto 0);
        variable vvvvv : boolean;

    begin

        cmd := o_ulpi.data(7 downto 6);
        pid := o_ulpi.data(3 downto 0);

        -- vvvvv := cmd = ULPI_CMD_HEAD_TRANSMIT;

        -- report "CMD :" & to_string(cmd);
        -- report "vvvvv :" & to_string(vvvvv);

        -- wait until vvvvv; -- TODO: not work((
        report "RX PID :" & to_string(pid);
        WaitForClock(ulpi_clock);

        i_ulpi.nxt <= '1'; -- READY
        WaitForClock(ulpi_clock);

        while o_ulpi.stp = '0' loop

            report "RECEIVED DATA BYTE:" & to_string(o_ulpi.data);

            -- use i_ulpi.nxt <= '0';to pause
            WaitForClock(ulpi_clock);

        end loop;

        i_ulpi.nxt <= '0';
        WaitForClock(ulpi_clock);

        WaitForClock(ulpi_clock, TX_END_DELAY);

        rx_cmd_transaction(ulpi_clock, i_ulpi, o_ulpi, LINESTATE_SQUELCH, VBUS_SESSVLD, RXEVENT_IDLE, OTG_A, ALT_INT_USB);

    end procedure;

    procedure ulpi_reg_receive (
        signal ulpi_clock : in std_logic;
        signal i_ulpi     : inout t_from_ulpi;
        signal o_ulpi     : in t_to_ulpi
    ) is

        variable cmd   : std_logic_vector(1 downto 0);
        variable pid   : std_logic_vector(3 downto 0);

    begin

        cmd := o_ulpi.data(7 downto 6);
        pid := o_ulpi.data(3 downto 0);

        -- vvvvv := cmd = ULPI_CMD_HEAD_TRANSMIT;

        -- report "CMD :" & to_string(cmd);
        -- report "vvvvv :" & to_string(vvvvv);

        -- wait until vvvvv; -- TODO: not work((
        report "RX PID :" & to_string(pid);
        WaitForClock(ulpi_clock);

        i_ulpi.nxt <= '1'; -- READY
        WaitForClock(ulpi_clock);

        while o_ulpi.stp = '0' loop

            report "RECEIVED DATA BYTE:" & to_string(o_ulpi.data);

            -- use i_ulpi.nxt <= '0';to pause
            WaitForClock(ulpi_clock);

        end loop;

        i_ulpi.nxt <= '0';
        WaitForClock(ulpi_clock);

        WaitForClock(ulpi_clock, TX_END_DELAY);

        -- rx_cmd_transaction(ulpi_clock, i_ulpi, o_ulpi, LINESTATE_SQUELCH, VBUS_SESSVLD, RXEVENT_IDLE, OTG_A, ALT_INT_USB);

    end procedure;

end package body tb_usb_pkg;
