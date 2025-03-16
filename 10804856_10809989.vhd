-------------------------------------------------------------------------------
--  Author       : Mario Capodanno 10804856, Michele Dussin 10809989
--  Project      : Reti Logiche 23-24
--  Prof         : William Fornaciari
--  Description  : Implementation of a Finite State Machine (FSM) for memory
--                 read/write operations on a RAM memory.
--  Date         : September 2024
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.numeric_std.all;

-----------------------START-ENTITY----------------------------------------
    --  Interface of the component from specification
entity project_reti_logiche is
    port(
        i_clk       : in std_logic;
        i_rst       : in std_logic;
        i_start     : in std_logic;
        i_add       : in std_logic_vector(15 downto 0);
        i_k         : in std_logic_vector(9 downto 0);

        o_done      : out std_logic;
        
        o_mem_addr  : out std_logic_vector(15 downto 0);
        i_mem_data  : in std_logic_vector(7 downto 0);
        o_mem_data  : out std_logic_vector(7 downto 0);
        o_mem_we    : out std_logic;
        o_mem_en    : out std_logic
    );
end project_reti_logiche;
-------------------------END-ENTITY-----------------------------------------


architecture Behavioral of project_reti_logiche is

    ----------------------------------------------------------------------------
    --  Internal Signals:
    --  saved_W      : Temporarily stores the data read from RAM.
    --  counter_K    : Tracks the number of memory read cycles (it will be the stop condition of the fsm)
    --  counter_Add  : Stores the current memory address being accessed.
    --  counter_31   : 5-bit counter to control memory write operations (used to write the credibility value C, see the specification)
    --  end_sng      : Indicates the completion of the data sequence (stop condition reached).
    --  lsb          : Represents the least significant bit of the current
    --                 memory address.
    ----------------------------------------------------------------------------
    
    TYPE states IS (IDLE, FETCH_INITIAL_DATA, ASK_READ_RAM, WAIT_READ_RAM, READ_W_RAM, WRITE_RAM, DONE);
    signal curr_state : states := IDLE;

    signal saved_W     : std_logic_vector(7 downto 0) := (others => '0');
    signal counter_K   : std_logic_vector(15 downto 0) := (others => '0');
    signal counter_Add : std_logic_vector(15 downto 0) := (others => '0');
    signal counter_31  : std_logic_vector(4 downto 0) := "11111";
    signal end_sng     : std_logic := '0';
    signal lsb         : std_logic := '0';

begin
    ----------------------------------------------------------------------------
    --  FSM: Finite State Machine
    ----------------------------------------------------------------------------
    fsm: process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            curr_state <= IDLE;

            
            --  Reset all outputs and internal signals to their default values.
            saved_W <= (others => '0');
            counter_K <= (others => '0');
            counter_Add <= (others => '0');
            counter_31 <= "11111";
            end_sng <= '0';
            lsb <= '0';
            o_done <= '0';
            o_mem_addr <= (others => '0');
            o_mem_data <= (others => '0');
            o_mem_we <= '0';
            o_mem_en <= '0';
            
        elsif rising_edge(i_clk) then
            case curr_state is
            
                ----------------------------------------------------------------------------
                --  FSM STATES:
                --  
                --  IDLE: 
                --  The initial state where the FSM waits for the start signal. 
                --  Once the start signal is set to '1', the FSM transitions to the 
                --  FETCH_INITIAL_DATA state.
                ----------------------------------------------------------------------------
                when IDLE =>
                    if i_start = '1' then
                        curr_state <= FETCH_INITIAL_DATA;
                    elsif i_start = '0' then
                        curr_state <= IDLE;
                    end if;
                
                ----------------------------------------------------------------------------
                --  FETCH_INITIAL_DATA: 
                --  In this state, the FSM receive from the input the initial memory address 
                --  from i_add and the number of word W from i_k.  
                --  If counter_K equals the value of i_k *2 (the number of step required to 
                --  reach the final address) the FSM transitions to  the DONE state.
                --  Otherwise, it proceeds to ask the RAM the value stored in the current 
                --  address.
                ----------------------------------------------------------------------------
                when FETCH_INITIAL_DATA =>
                    o_mem_addr <= i_add + counter_K;
                    counter_Add <= i_add + counter_K;
                    
                    -- Needed i_k*2 so it's shifted to the left by 1 bit
                    if counter_K  = (i_k & "0") then
                        end_sng <= '1';
                        o_done <= '1';
                        counter_31 <= "11111";
                        curr_state <= DONE;
                    else
                        end_sng <= '0';
                        o_done <= '0';
                        -- Increment the counter to calculate the next address
                        counter_K <= counter_K + "0000000000000001";
                        curr_state <= ASK_READ_RAM;
                    end if;
                    
                ----------------------------------------------------------------------------
                --  ASK_READ_RAM: 
                --  Enables the read flag of the RAM and sets the FSM up for a read operation. 
                --  It also checks if the least significant bit (LSB) of the 
                --  current memory address matches that of the input address to see if it's 
                --  reading the word W (ADD + 2*(k-1)) or the next value (ADD + 2*(k-1) + 1).
                ----------------------------------------------------------------------------
                when ASK_READ_RAM =>
                    o_mem_en <= '1';
                    o_mem_we <= '0';
                    -- If the last bit is equal then the current address has type ADD+2
                    if counter_Add(0) = i_add(0) then
                        lsb <= '1';
                    else
                        lsb <= '0';
                    end if;
                    curr_state <= WAIT_READ_RAM;
                    
                ----------------------------------------------------------------------------
                --  WAIT_READ_RAM: 
                --  Waits for the RAM to complete the read operation.
                ----------------------------------------------------------------------------
                when WAIT_READ_RAM =>
                    curr_state <= READ_W_RAM;
                    
                ----------------------------------------------------------------------------
                --  READ_W_RAM: 
                --  Handles the data read from RAM. Depending on the value of 
                --  LSB and the read data, it update the memory with new 
                --  data or leave it unchanged.
                ----------------------------------------------------------------------------
                when READ_W_RAM =>
                    if lsb = '1' then
                        if i_mem_data = 0 then
                            if saved_W = 0 then
                                o_mem_en <= '0';
                                o_mem_we <= '0';
                                -- Crededibility value counter reset
                                counter_31 <= "11111";
                            else
                                -- Enable r/w in the RAM memory
                                o_mem_en <= '1';
                                o_mem_we <= '1';
                                o_mem_data <= saved_W;
                                -- Handle the case where is reached the counter value 0
                                if(counter_31 = "00000") then 
                                    counter_31 <= "00000";
                                else
                                    -- Crededibility value counter decrement
                                    counter_31 <= counter_31 - "00001";
                                end if;
                            end if;
                        else
                            saved_W <= i_mem_data;
                            o_mem_en <= '0';
                            o_mem_we <= '0';
                            counter_31 <= "11111";
                        end if;
                    else
                        if saved_W = 0 then
                            o_mem_en <= '0';
                            o_mem_we <= '0';
                        else
                            -- Enable r/w in the RAM memory
                            o_mem_en <= '1';
                            o_mem_we <= '1';
                            -- The value to be writtend in the memory is extended by 3 bit (value of the counter is 5 bit)
                            o_mem_data <= "000" & counter_31;
                        end if;
                    end if;
                    curr_state <= WRITE_RAM;
                    
                ----------------------------------------------------------------------------
                --  WRITE_RAM: 
                --  Completes the write operation to RAM and then returns to 
                --  fetch the next piece of data.
                ----------------------------------------------------------------------------
                when WRITE_RAM =>
                    -- Disable the r/w on the RAM
                    o_mem_we <= '0';
                    o_mem_en <= '0';
                    curr_state <= FETCH_INITIAL_DATA;
                    
                ----------------------------------------------------------------------------
                --  DONE: 
                --  Indicates that the FSM has completed its operation. The 
                --  FSM waits for the start signal to be '0' before turning to '0' the value
                --  of the signal o_done and transitioning back to the IDLE state.
                ----------------------------------------------------------------------------
                when DONE =>
                    if i_start = '0' then
                        o_done <= '0';
                        curr_state <= IDLE;
                    else
                        saved_W <= (others => '0');
                        counter_K <= (others => '0');
                        counter_Add <= (others => '0');
                        counter_31 <= "11111";                    
                        o_mem_we <= '0';
                        o_mem_en <= '0';
                        curr_state <= DONE;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;
