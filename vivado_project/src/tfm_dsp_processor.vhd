----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Rodrigo Espejo López de los Mozos
-- 
-- Create Date: 23.04.2024 21:04:30
-- Design Name: 
-- Module Name: tfm_dsp_processor - Behavioral
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
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


-- Instance template
--    tfm_dsp_processor : entity WORK.tfm_dsp_processor
--        generic map(
--            bits => 2,
--            d_width => 24,
--            ir_d_width => 16,
--            n_rams => 2
--        )
--        port map(
--            sysclk => sysclk,
--            reset => reset,
--            start_tick => start_tick,
--            shift_tick => shift_tick,
--            done_tick => done_tick,
--            ramID => ramID,
--            samplein => samplein,
--            coeffin => coeffin,
--            dout => dout
--        );

entity tfm_dsp_processor is
    Generic (
        bits : INTEGER := 10;
        d_width : INTEGER := 24;
        ir_d_width : INTEGER := 16;
        n_rams : INTEGER := 2
    );
    Port ( sysclk : in STD_LOGIC;
           reset : in STD_LOGIC;
           start_tick : in STD_LOGIC;
           shift_tick : in STD_LOGIC;
           done_tick : in STD_LOGIC;
           ramID : in NATURAL range 0 to n_rams-1;
           samplein : in STD_LOGIC_VECTOR ((d_width*n_rams)-1 downto 0);
           coeffin : in STD_LOGIC_VECTOR ((ir_d_width*n_rams)-1 downto 0);
           dout : out STD_LOGIC_VECTOR (d_width - 1 downto 0)
           );
end tfm_dsp_processor;

architecture Behavioral of tfm_dsp_processor is
    type sample_array_t is array(n_rams-1 downto 0) of signed(d_width-1 downto 0);
    type coeff_array_t is array (n_rams-1 downto 0) of signed(ir_d_width-1 downto 0);
    type sum_v_array is array (n_rams-1 downto 0) of signed(d_width + ir_d_width - 1 downto 0);
    type accumulator_array_t is array (n_rams-1 downto 0) of signed(d_width + ir_d_width + bits - 1 downto 0);
    
    signal samples : sample_array_t;
    signal coeffs : coeff_array_t;
    
    -- DSP signals
    signal accumulator_reg,  accumulator_next : accumulator_array_t;
    signal dsp_output_reg, dsp_output_next : signed(d_width + ir_d_width + bits - 1 downto 0) := (others=>'0');
    
    -- FSM states
    type state_type is (idle, wait_data, convolution, shifted_convolution, output);
    signal state_reg, state_next : state_type;
    
begin  
    -- Divide samplein into different signed vectors 
    process (samplein)
    begin
        for i in 0 to n_rams-1 loop
            samples(i) <= signed(samplein(((i+1)*d_width)-1 downto (i*d_width)));
        end loop;
    end process;
    
    -- Divide coeffin into different vectors
    process (coeffin)
    begin
        for i in 0 to n_rams-1 loop
            coeffs(i) <= signed(coeffin(((i+1)*ir_d_width)-1 downto (i*ir_d_width)));
        end loop;
    end process;
    
    -- FSM
    -- Status register
    FSM_Status : process(sysclk)
    begin
        if rising_edge(sysclk) then
            if(reset = '1') then
                state_reg <= idle;
                for i in 0 to n_rams-1 loop
                    accumulator_reg(i) <= (others => '0');
                end loop;
                dsp_output_reg <= (others => '0');
            else
                state_reg <= state_next;
                accumulator_reg <= accumulator_next;
                dsp_output_reg <= dsp_output_next;
            end if;
        end if;
    end process;
    
    -- Next state logic
    FSM_Next_state : process(state_reg, start_tick, shift_tick, done_tick)
    begin
        state_next <= state_reg;
        case state_reg is
            when idle =>
                if (start_tick = '1') then
                    state_next <= wait_data;
                end if;
            when wait_data =>
                state_next <= convolution;
            when convolution =>
                if (shift_tick = '1') then
                    state_next <= shifted_convolution;   
                end if;
                if (done_tick = '1') then
                    state_next <= output;
                end if;
            when shifted_convolution =>
                if (done_tick = '1') then
                    state_next <= output;
                end if;
            when output =>
                state_next <= idle;
        end case;
    end process;
    
    -- Processing logic
    FSM_output : process(state_reg, samples, coeffs, accumulator_reg, dsp_output_reg)
    variable sum_v : sum_v_array := (others => (others=>'0'));
    variable temp_output : signed(d_width + ir_d_width + bits - 1 downto 0);
    begin
    temp_output := (others => '0');
    accumulator_next <= accumulator_reg;
    dsp_output_next <= dsp_output_reg;
        case state_reg is
            when idle =>
                for i in 0 to n_rams-1 loop
                    accumulator_next(i) <= (others => '0');
                end loop;
            when wait_data =>
            when convolution =>
                for i in 0 to n_rams-1 loop
                    if((ramID - i) >= 0) then 
                        sum_v(i) := samples(i) * coeffs(ramID - i);
                    else
                        sum_v(i) := samples(i) * coeffs(ramID - i + n_rams);
                    end if;
                    accumulator_next(i) <= accumulator_reg(i) + sum_v(i);
                end loop;
            when shifted_convolution =>
                for i in 0 to n_rams-1 loop
                    if((ramID - i - 1) >= 0) then 
                        sum_v(i) := samples(i) * coeffs(ramID - i - 1);
                    else
                        sum_v(i) := samples(i) * coeffs(ramID - i - 1 + n_rams);
                    end if;
                    accumulator_next(i) <= accumulator_reg(i) + sum_v(i);
                end loop;
            when output =>
                for i in 0 to n_rams-1 loop
                    temp_output := temp_output + accumulator_reg(i);
                end loop;
--                dsp_output_next <= resize(temp_output, d_width + ir_d_width);
                dsp_output_next <= shift_right(temp_output, 15);
        end case;
    end process;
    
    dout <= std_logic_vector(dsp_output_reg((ir_d_width - 1 + (d_width/2)) downto (ir_d_width - 1 - ((d_width/2)-1))));
--    dout <= std_logic_vector(dsp_output_reg(27 downto 4));
    
end Behavioral;
