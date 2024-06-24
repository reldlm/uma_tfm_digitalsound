# Code: Rodrigo Espejo López de los Mozos

import csv

# Input parameters
input_csv_file = './files/csv/ir_stairwell_44k.csv'
output_vhd_file = './files/vhd/tfm_ir_coeff_buffer.vhd'
n_rams = 32
bits = 10
values_per_line = 4
ir_d_width = 16
fractional_bits = 15

def float_to_hex(float_):
    # Turns the provided floating-point number into a fixed-point
    # hex representation with "ir_d_width - fractional_bits" bit for the integer component and
    # "fractional_bits" bits for the fractional component.

    # Scale the number up.
    temp = float_ * 2**fractional_bits
    # Turn it into an integer.
    temp = int(temp)

    if temp < 0:
        temp += 2**ir_d_width

    # The 0 means "pad the number with zeros".
    # The "ir_d_width" means to pad to a width of "ir_d_width" characters
    # The b means to use binary.
    hex_width = ir_d_width // 4
    return '{:0{}x}'.format(temp, hex_width)


def complement_to_a2(decimal):
    if decimal >= 0:
        # If the number is positive, simply convert it to binary and return
        # binary = bin(int(decimal * (2**16)))[2:]  # Convert to binary and remove the '0b' prefix
        hexadecimal = hex(int(decimal * (2**ir_d_width)))[2:] # Convert to hex and remove the '0b' prefix
        return hexadecimal.zfill(int(ir_d_width/4))
        # return binary.zfill(16)  # Ensure the string has 16 bits
    else:
        # If the number is negative, calculate the two's complement
        abs_decimal = abs(decimal)
        binary = bin(int(abs_decimal * (2**ir_d_width)))[2:]  # Convert absolute value to binary
        inverted_binary = ''.join('1' if bit == '0' else '0' for bit in binary)  # Invert the bits
        complemented_binary = bin(int(inverted_binary, 2) + 1)[2:]  # Add 1 to the inverted number
        hexadecimal = hex(int(inverted_binary, 2) + 1)[2:]
        return hexadecimal.zfill(int(ir_d_width/4))
        return complemented_binary.zfill(16)  # Ensure the string has 16 bits

def fill_list_to_power_of_two(decimal_list):
    # Calculate the size of the list
    size = len(decimal_list)
        
    # Fill the list with zeros until increasing the size to the one set in the parameters
    zeros_to_add = n_rams * 2**bits - size
    filled_list = [0] * zeros_to_add + decimal_list
    return filled_list

def write_vhd(hex_values):
    line_counter = 0
    ram_counter = 0
    values_counter = 0
    with open(output_vhd_file, 'w') as vhd_file:
        vhd_file.write(initial_code)
        vhd_file.write('    -- Memory\n')
        vhd_file.write('    type memory_block is array ((2**bits-1) downto 0) of STD_LOGIC_VECTOR (ir_d_width-1 downto 0);  -- Array type for the memory\n')
        vhd_file.write('    type ir_buffer is array ((n_rams-1) downto 0) of memory_block;\n')
        vhd_file.write('    signal coeff_s : ir_buffer := (\n')
        vhd_file.write(f'        -- Block {n_rams-ram_counter-1}\n')
        ram_counter = ram_counter + 1
        vhd_file.write('        (\n')
        for value in hex_values:
            values_counter = values_counter + 1
            if line_counter == 0:
                if values_counter != 2**bits:
                    vhd_file.write(f'            x"{value}", ')
                else:
                    vhd_file.write(f'            x"{value}"')
                line_counter = line_counter + 1
                if values_per_line == 1:
                    line_counter = 0
                    vhd_file.write(f'\n')
            else:
                if line_counter != values_per_line:
                    if values_counter != 2**bits:
                        vhd_file.write(f'x"{value}", ')
                    else:
                        vhd_file.write(f'x"{value}"')
                    line_counter = line_counter + 1
                    if line_counter == values_per_line:
                        vhd_file.write(f'\n')
                        line_counter = 0
            if(values_counter == 2**bits):
                if ram_counter != n_rams:
                    vhd_file.write(f'        ),\n')
                    vhd_file.write(f'        -- Block {n_rams-ram_counter-1}\n')
                    vhd_file.write(f'        (\n')
                    values_counter = 0
                    ram_counter = ram_counter + 1
        vhd_file.write('        )\n')  
        vhd_file.write('    );\n')
        vhd_file.write(final_code)


initial_code = """
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.03.2024 19:08:22
-- Design Name: 
-- Module Name: tfm_ir_coeff_buffer - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tfm_ir_coeff_buffer is
    Generic (
        bits : INTEGER := 2;
        ir_d_width : INTEGER := 16;
        n_rams : INTEGER := 2
    );
    Port ( 
        sysclk : in STD_LOGIC;
        reset : in STD_LOGIC;
        start_tick : in STD_LOGIC;
        done_tick : out STD_LOGIC;
        dout : out STD_LOGIC_VECTOR ((ir_d_width*n_rams)-1 downto 0)
        );
end tfm_ir_coeff_buffer;

architecture Behavioral of tfm_ir_coeff_buffer is
"""

final_code = """
    -- FIFO control pointers
    signal read_p_reg, read_p_next : NATURAL;                   -- Read pointer
    
    -- Done tick
    signal done_tick_reg, done_tick_next : STD_LOGIC;
    
    -- FSM states
    type state_type is (idle, output);
    signal state_reg, state_next : state_type;
begin
    process(sysclk)
    begin
        if rising_edge(sysclk) then
            for i in 0 to n_rams-1 loop
                dout(((ir_d_width-1)+(ir_d_width*i)) downto (ir_d_width*i)) <= coeff_s(i)(read_p_reg);
            end loop;
        end if;        
    end process;
    
    -- FSM
    -- Status register
    FSM_Status : process(sysclk)
    begin
        if rising_edge(sysclk) then
            if(reset = '1') then
                state_reg <= idle;
                read_p_reg <= 0;
                done_tick_reg <= '0';
            else
                state_reg <= state_next;
                read_p_reg <= read_p_next;
                done_tick_reg <= done_tick_next;
            end if;
        end if;
    end process;
    
    -- Next state logic
    FSM_Next_state : process(state_reg, read_p_reg, start_tick)
    begin
        state_next <= state_reg;
        case state_reg is
            when idle =>
                if (start_tick = '1') then
                    state_next <= output;
                end if;
            when output =>
                if (read_p_reg = 2**bits-1) then
                    state_next <= idle;   
                end if;    
        end case;
    end process;
    
    -- Output logic
    FSM_output : process(state_reg, read_p_reg, start_tick, done_tick_reg)
    begin
        read_p_next <= read_p_reg;
        done_tick_next <= done_tick_reg;
        case state_reg is
            when idle =>
                done_tick_next <= '0';
                if (start_tick = '1') then
                    read_p_next <= 0;
                end if;
            when output =>
                if (read_p_reg = 2**bits-1) then
                    done_tick_next <= '1';
                else
                    read_p_next <= read_p_reg + 1;       
                end if;    
        end case;
    end process;
    
    -- Done tick
    done_tick <= done_tick_reg;
end Behavioral;
"""


if __name__ == "__main__":
    # Read decimal values from a CSV file
    decimal_values  = []
    with open(input_csv_file, newline='') as csvfile:
        reader = csv.reader(csvfile)
        for row in reader:
            for value in row:
                decimal_values.append(float(value))

    #Check if the parameters are ok with the len of the list
    if len(decimal_values) > (2**bits)*n_rams:
        print("ERROR. Wrong value of parameters.")
        exit()

    # Reverse the order of the list
    decimal_values = decimal_values[::-1]

    # Fill the list with zeros if neccesary
    decimal_values = fill_list_to_power_of_two(decimal_values)

    # Convert decimal to hex values
    # hex_values = []
    # for decimal in decimal_values:
    #     hex_values.append(complement_to_a2(decimal))
    hex_values = []
    for decimal in decimal_values:
        hex_values.append(float_to_hex(decimal))

    # Write VHDL code
    write_vhd(hex_values)

