----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.04.2024 18:51:41
-- Design Name: 
-- Module Name: main - Behavioral
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
use IEEE.std_logic_unsigned.all;
use ieee.NUMERIC_STD.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main is
    Port ( clk : in STD_LOGIC;
           j4 : in STD_LOGIC_VECTOR (1 downto 0);
           LED_out : out STD_LOGIC_VECTOR (7 downto 0);
           Anode_Activate : out STD_LOGIC_VECTOR (7 downto 0);
           LED_rgb : out STD_LOGIC_VECTOR (3 downto 0);
           reset : in STD_LOGIC
         );
end main;

architecture Behavioral of main is
component xadc_wiz_0 is
   port
   (
       daddr_in        : in  STD_LOGIC_VECTOR (6 downto 0);     -- Address bus for the dynamic reconfiguration port
       den_in          : in  STD_LOGIC;                         -- Enable Signal for the dynamic reconfiguration port
       di_in           : in  STD_LOGIC_VECTOR (15 downto 0);    -- Input data bus for the dynamic reconfiguration port
       dwe_in          : in  STD_LOGIC;                         -- Write Enable for the dynamic reconfiguration port
       do_out          : out  STD_LOGIC_VECTOR (15 downto 0);   -- Output data bus for dynamic reconfiguration port
       drdy_out        : out  STD_LOGIC;                        -- Data ready signal for the dynamic reconfiguration port
       dclk_in         : in  STD_LOGIC;                         -- Clock input for the dynamic reconfiguration port
       reset_in        : in  STD_LOGIC;                         -- Reset signal for the System Monitor control logic
       vauxp10         : in  STD_LOGIC;                         -- Auxiliary Channel 10
       vauxn10         : in  STD_LOGIC;
       busy_out        : out  STD_LOGIC;                        -- ADC Busy signal
       channel_out     : out  STD_LOGIC_VECTOR (4 downto 0);    -- Channel Selection Outputs
       eoc_out         : out  STD_LOGIC;                        -- End of Conversion Signal
       eos_out         : out  STD_LOGIC;                        -- End of Sequence Signal
       alarm_out       : out STD_LOGIC;                         -- OR'ed output of all the Alarms
       vp_in           : in  STD_LOGIC;                         -- Dedicated Analog Input Pair
       vn_in           : in  STD_LOGIC
   );
end component;

component binary_to_bcd is
    generic(N: positive := 12);
    port(
        clk, reset: in std_logic;
        binary_in: in std_logic_vector(N-1 downto 0);
        bcd_output: out std_logic_vector(15 downto 0)
    );
end component;

signal ADCValidData : std_logic_vector(11 downto 0);
signal ADCValidData_divided : std_logic_vector(11 downto 0);
signal bcd_output : std_logic_vector(15 downto 0);
signal ADCNonValidData : std_logic_vector(3 downto 0);
signal EnableInt : std_logic := '1';
signal noise : std_logic := '1';
signal LED_BCD: STD_LOGIC_VECTOR (4 downto 0);
signal refresh_counter: STD_LOGIC_VECTOR (23 downto 0):="000000000000000000000000";
signal LED_activating_counter: std_logic_vector(2 downto 0);
signal eight: STD_LOGIC_VECTOR (11 downto 0):= "000000000100";
begin

print_bcd: process(LED_BCD)
            begin
                case LED_BCD is
                when "00000" => LED_out <= "11000000"; -- "0"     
                when "00001" => LED_out <= "11111001"; -- "1" 
                when "00010" => LED_out <= "10100100"; -- "2" 
                when "00011" => LED_out <= "10110000"; -- "3" 
                when "00100" => LED_out <= "10011001"; -- "4" 
                when "00101" => LED_out <= "10010010"; -- "5" 
                when "00110" => LED_out <= "10000010"; -- "6" 
                when "00111" => LED_out <= "11111000"; -- "7" 
                when "01000" => LED_out <= "10000000"; -- "8"     
                when "01001" => LED_out <= "10010000"; -- "9" 
                when "01010" => LED_out <= "10001000"; -- "A"
                when "01011" => LED_out <= "01000000"; -- "Q"
                when "01100" => LED_out <= "11111001"; -- "I"
                when "01101" => LED_out <= "10111111"; -- "-"
                when others => LED_out <= "11111111";  --null "LED_BCD whose MSB is 1 will be printed as null"
                end case;
            end process;
adcImp : xadc_wiz_0 port map
        (
            daddr_in        => "0011010",               -- 10th drp port address is 0x1A
            den_in          => EnableInt,               -- set enable drp port
            di_in           => (others => '0'),         -- set input data as 0 
            dwe_in          => '0',                     -- disable write to drp
            do_out(15 downto 4)    => ADCValidData,     -- because we use unipolar xadc
            do_out(3 downto 0)    => ADCNonValidData,   -- non valid data with dummy vector
            drdy_out        => open,                    
            dclk_in         => clk,                     -- 125 Mhz system clock wires to drp
            reset_in        => '0',
            vauxp10         => j4(0),                   -- xadc positive pin                                      
            vauxn10         => j4(1),                   -- xadc negative pin
            busy_out        => open,                   
            channel_out    => open,    
            eoc_out         => EnableInt,               -- enable int                   
            eos_out         => open,                      
            alarm_out       => open,                         
            vp_in           => '0',                        
            vn_in           => '0'
        );

BINtoBCD : entity work.binary_to_bcd(rtl)
            generic map(
                N => 12
            )
            port map(
                clk => clk,
                reset => reset,
                binary_in => ADCValidData_divided,
                bcd_output => bcd_output
            );    

Intialize_Clock: process(clk,reset)
        begin 
            if(reset='1') then
                refresh_counter <= (others => '0');
            elsif(rising_edge(clk)) then
                refresh_counter <= refresh_counter + 1;
            end if;
        end process;

LED_activating_counter <= refresh_counter(17 downto 15);       --13.1082ms

Turn_on_SS: process(LED_activating_counter,bcd_output)
            begin
                case LED_activating_counter is
                when "000" =>
                    Anode_Activate <= "11111111";
                    LED_BCD <= "10000";
                when "001" =>
                    Anode_Activate <= "11111110";
                    LED_BCD <= ("0" & bcd_output(3 downto 0)); -- "0 &"  means this output will be printed
                when "010" =>
                    Anode_Activate <= "11111101";
                    LED_BCD <= ("0" & bcd_output(7 downto 4)); 
                when "011" =>
                    Anode_Activate <= "11111011";
                    LED_BCD <= ("0" & bcd_output(11 downto 8)); 
                when "100" =>
                    Anode_Activate <= "11101111";
                    LED_BCD <= ("0" & "1101");                 -- "1 &"  means null will be printed 
                when "101" =>
                    Anode_Activate <= "01111111";
                    LED_BCD <= ("0" & "1010"); 
                when "110" =>
                    Anode_Activate <= "10111111";
                    LED_BCD <= ("0" & "1011"); 
                when "111" =>
                    Anode_Activate <= "11011111";
                    LED_BCD <= ("0" & "1100"); 
                when others =>
                    Anode_Activate <= "11011111";
                    LED_BCD <= ("1" & "1100"); 
                end case;
                for p in 0 to 30 loop
                    for k in 0 to 64000 loop
                        noise<=noise;
                    end loop;
                end loop;
            end process;

Divide_by_8: process(ADCValidData)
            begin
            ADCValidData_divided <=std_logic_vector(to_unsigned(to_integer(unsigned(ADCValidData)) / to_integer(unsigned(eight)),12));
            
            end process;

RGB_LED: process(bcd_output)
            begin
            if(bcd_output(11 downto 8)="0000") then
                LED_rgb<="0001";
            elsif (bcd_output(11 downto 8)="0001") then
                LED_rgb<="0010";
            elsif (bcd_output(11 downto 8)="0010") then
                LED_rgb<="0100";
            else
                LED_rgb<="1000";
            end if;
            end process;
end Behavioral;
