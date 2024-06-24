----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Rodrigo Espejo López de los Mozos
-- 
-- Create Date: 26.02.2024 19:03:31
-- Design Name: 
-- Module Name: tfm_ring_fifo_buffer - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- Instance template
--    tfm_ring_fifo_buffer : entity WORK.tfm_ring_fifo_buffer
--        generic map (
--            bits => bits,
--            d_width => d_width,
--            n_rams => n_rams
--        )
--        port map (
--            sysclk => sysclk,
--            reset => reset,
--            din => sample_input,
--            push => start_tick,
--            read_done_tick => sample_done_tick,
--            shift_tick => shift_tick,
--            ramID => ramID,
--            dout => sample_ouput    
--        );


entity tfm_ring_fifo_buffer is
    Generic (
        bits : INTEGER := 2;
        d_width : INTEGER := 24;
        n_rams : INTEGER := 2
    );
    Port ( sysclk : in STD_LOGIC;
           reset : in STD_LOGIC;
           din : in STD_LOGIC_VECTOR (d_width-1 downto 0);
           push : in STD_LOGIC;
           read_done_tick : out STD_LOGIC;
           shift_tick : out STD_LOGIC;
           ramID : out NATURAL range 0 to n_rams-1;
           dout : out STD_LOGIC_VECTOR ((d_width*n_rams)-1 downto 0)
           );
end tfm_ring_fifo_buffer;

architecture Behavioral of tfm_ring_fifo_buffer is
    -- Memory
    type memory_block is array ((2**bits-1) downto 0) of STD_LOGIC_VECTOR (d_width-1 downto 0);  -- Array type for the memory
    type ring_buffer is array ((n_rams-1) downto 0) of memory_block;
    signal fifo_buffer : ring_buffer;
    
    -- Write enable signal
    signal ramID_signal : NATURAL; -- Identifier of the bram where should be written   
    signal write_enable : STD_LOGIC_VECTOR(n_rams-1 downto 0);  -- Signal to enable the writing in the correspondant bram
    
    -- FIFO control pointers
    signal global_write_p_reg, global_write_p_next : NATURAL;   -- Global write pointer
    signal write_p_reg, write_p_next : NATURAL;                 -- Write pointer
    signal read_p_reg, read_p_next : NATURAL;                   -- Read pointer
    signal read_count_reg, read_count_next : NATURAL;           -- Read counter
    signal shift_tick_reg, shift_tick_next : STD_LOGIC;         -- Shift tick
    
    -- FSM states
    type state_type is (idle, output, update);
    signal state_reg, state_next : state_type;
    
begin
    -- BRAM synth
    process(sysclk)
    begin
        if rising_edge(sysclk) then
            for i in 0 to n_rams-1 loop
                if (write_enable(i) = '1' and push = '1') then
                    fifo_buffer(i)(write_p_reg) <= din;        
                end if;
                dout(((d_width-1)+(d_width*i)) downto (d_width*i)) <= fifo_buffer(i)(read_p_reg);     
            end loop;
        end if;
    end process;
        
    
    -- Write enable generation with one hot code
    -- Check in which ram block the value should be written into
    ramID_signal <= (global_write_p_reg/2**bits);
    ramID <= ramID_signal;
    onehot_encoder : entity WORK.one_hot_encoder
    generic map(
        n_rams => n_rams
    )
    port map(
        ramID =>ramID_signal,
        write_enable =>write_enable
    );
    
    
    -- FSM
    -- Status register
    FSM_Status : process(sysclk)
    begin
        if rising_edge(sysclk) then
            if(reset = '1') then
                state_reg <= idle;
                global_write_p_reg <= 0;
                write_p_reg <= 0;
                read_p_reg <= 0;
                read_count_reg <= 0;
                shift_tick_reg <= '0';
            else
                state_reg <= state_next;
                global_write_p_reg <= global_write_p_next;
                write_p_reg <= write_p_next;
                read_p_reg <= read_p_next;
                read_count_reg <= read_count_next;
                shift_tick_reg <= shift_tick_next;
            end if;
        end if;
    end process;
    
    -- Next state logic
    FSM_Next_state : process(state_reg, push, global_write_p_reg, write_p_reg, read_p_reg, read_count_reg, shift_tick_reg)
    begin
        state_next <= state_reg;
        case state_reg is
            when idle =>
                if (push = '1') then
                    state_next <= output;
                end if;
            when output =>
                if(read_count_reg = 2**bits-1) then
                    state_next <= update;
                end if;
            when update =>
                state_next <= idle;    
        end case;
    end process;
    
    -- Output logic
    FSM_output : process(state_reg, push, global_write_p_reg, write_p_reg, read_p_reg, read_count_reg, shift_tick_reg)
    begin
        global_write_p_next <= global_write_p_reg;
        write_p_next <= write_p_reg;
        read_p_next <= read_p_reg;
        read_count_next <= read_count_reg;
        shift_tick_next <= shift_tick_reg;
        case state_reg is
            when idle =>
                shift_tick_next <= '0';
                if (push = '1') then
                    read_p_next <= write_p_reg;
                end if;
            when output =>
                shift_tick_next <= '0';
                if(read_count_reg = 2**bits-1) then
                else
                    --Read counter update
                    read_count_next <= read_count_reg + 1;
                    
                    -- Read pointer
                    if(read_p_reg = 0) then
                        read_p_next <= 2**bits-1;
                        -- Shift tick
                        shift_tick_next <= '1';
                    else
                        read_p_next <= read_p_reg - 1;
                    end if;
                end if;    
            when update =>
                -- Global write pointer
                if(global_write_p_reg = (2**bits*n_rams)-1) then
                    global_write_p_next <= 0;
                else
                    global_write_p_next <= global_write_p_reg + 1;
                end if;
                
                -- Local write pointer
                if(write_p_reg = 2**bits-1) then
                    write_p_next <= 0;
                else
                    write_p_next <= write_p_reg + 1;
                end if;
                
                -- Read counter reset
                read_count_next <= 0;
        end case;
    end process;
    
    read_done_tick <= '1' when (state_reg = update) else '0';
    shift_tick <= shift_tick_reg;
end Behavioral;
