{ ####################################################################################### }
{ ##                                                                                   ## }
{ ## ADS1262_Unit                                                                      ## }
{ ##                                                                                   ## }
{ ## Library for ADS1262                                                               ## }
{ ## Based on:                                                                         ## }
{ ## - Timm Thaler: http://wiki.lazarus.freepascal.org/index.php?title=<br>            ## }
{ ##        Raspberry_Pi_-_SPI/de&oldid=113577,                                        ## }
{ ## - Professor Plate: http://www.netzmafia.de/skripten/hardware/RasPi/RasPi_SPI.html,## }
{ ## - Blake Felt library: https://github.com/Molorius/ADS126X and                     ## }
{ ## - ProtoCentral library: https://github.com/Protocentral/ProtoCentral_ads1262.     ## }
{ ## - pascalio library: https://github.com/SAmeis/pascalio                            ## }
{ ##                                                                                   ## }
{ ## Copyright (C) 2018-2019  : Dr. Jürgen Abel                                        ## }
{ ## Email                    : juergen@mve.info                                       ## }
{ ## Internet                 : www.seismometer.info                                   ## }
{ ##                                                                                   ## }
{ ## This program is free software: you can redistribute it and/or modify              ## }
{ ## it under the terms of the GNU Lesser General Public License as published by       ## }
{ ## the Free Software Foundation, either version 3 of the License, or                 ## }
{ ## (at your option) any later version with the following modification:               ## }
{ ##                                                                                   ## }
{ ## As a special exception, the copyright holders of this library give you            ## }
{ ## permission to link this library with independent modules to produce an            ## }
{ ## executable, regardless of the license terms of these independent modules, and     ## }
{ ## to copy and distribute the resulting executable under terms of your choice,       ## }
{ ## provided that you also meet, for each linked independent module, the terms        ## }
{ ## and conditions of the license of that module. An independent module is a          ## }
{ ## module which is not derived from or based on this library. If you modify          ## }
{ ## this library, you may extend this exception to your version of the library,       ## }
{ ## but you are not obligated to do so. If you do not wish to do so, delete this      ## }
{ ## exception statement from your version.                                            ## }
{ ##                                                                                   ## }
{ ## This program is distributed in the hope that it will be useful,                   ## }
{ ## but WITHOUT ANY WARRANTY; without even the implied warranty of                    ## }
{ ## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                     ## }
{ ## GNU General Public License for more details.                                      ## }
{ ##                                                                                   ## }
{ ## You should have received a copy of the GNU Lesser General Public License          ## }
{ ## COPYING.LGPL.txt along with this program.                                         ## }
{ ## If not, see <https://www.gnu.org/licenses/>.                                      ## }
{ ##                                                                                   ## }
{ ####################################################################################### }

Unit ADS1262_Unit;

{$mode objfpc}{$H+}

{$INCLUDE project_defines.inc}

Interface

Uses
  CThreads,
  BaseUnix,
  Classes;

Const
  ADS1262_REGISTER_N = $15;

Type
  { ####################################################################################### }
  { ## Number types                                                                      ## }
  { ####################################################################################### }
  Int_8     = Int8;
  P_Int_8   = ^Int_8;
  U_Int_8   = UInt8;
  P_U_Int_8 = ^U_Int_8;
  Char      = Int_8;
  P_Char    = ^Char;
  U_Char    = U_Int_8;
  P_U_Char  = ^U_Char;

  Int_16     = Int16;
  P_Int_16   = ^Int_16;
  U_Int_16   = UInt16;
  P_U_Int_16 = ^U_Int_16;

  Int_32     = Int32;
  P_Int_32   = ^Int_32;
  U_Int_32   = UInt32;
  P_U_Int_32 = ^U_Int_32;

  Int_64     = Int64;
  P_Int_64   = ^Int_64;
  U_Int_64   = UInt64;
  P_U_Int_64 = ^U_Int_64;

  Bool   = Bytebool;
  P_Bool = ^Bool;

  T_GPIO_Direction = (GPIO_DIRECTION_IN, GPIO_DIRECTION_OUT);

  T_Buffer_A = Array Of U_Int_8;

  T_SPI_Transfer_R = Record
      tx_buf :        U_Int_64;
      rx_buf :        U_Int_64;
      len :           U_Int_32;
      speed_hz :      U_Int_32;
      delay_usecs :   U_Int_16;
      bits_per_word : U_Int_8;
      cs_change :     U_Int_8;
      pad :           U_Int_32;
  End; { T_SPI_Transfer_R }

  T_Register_Block = Array [0 .. ADS1262_REGISTER_N - 1] Of U_Int_8;

Const
  { ####################################################################################### }
  { ## GPIO data                                                                         ## }
  { ####################################################################################### }
  GPIO_LINUX_BASE_DIR       = '/sys/class/gpio/';
  GPIO_LINUX_GPIOPIN_DIR    = GPIO_LINUX_BASE_DIR + 'gpio%d/';
  GPIO_LINUX_EXPORT_FILE    = GPIO_LINUX_BASE_DIR + 'export';
  GPIO_LINUX_UNEXPORT_FILE  = GPIO_LINUX_BASE_DIR + 'unexport';
  GPIO_DRDY_PIN             = 25;
  GPIO_WAIT_TIME_MS_EXPORT  = 100;
  GPIO_WAIT_TIME_MS_COMMAND = 10;

  { ####################################################################################### }
  { ## SPI general data                                                                  ## }
  { ####################################################################################### }
  SPI_IOC_DEVICE               = '/dev/spidev0.0';
  SPI_IOC_WAIT_TIME_MS_OPEN    = 100;
  SPI_IOC_WAIT_TIME_MS_COMMAND = 10;

  { ####################################################################################### }
  { ## SPI request commands                                                              ## }
  { ####################################################################################### }
  SPI_IOC_MODE_READ  = $80;
  SPI_IOC_MODE_WRITE = $40;
  SPI_IOC_MODE_CTRL  = $6B;

  SPI_IOC_RD_MODE : U_Int_32          = (SPI_IOC_MODE_READ shl $18) or ($01 shl $10) or (SPI_IOC_MODE_CTRL shl $08) or ($01);  { $80016B01; }
  SPI_IOC_WR_MODE : U_Int_32          = (SPI_IOC_MODE_WRITE shl $18) or ($01 shl $10) or (SPI_IOC_MODE_CTRL shl $08) or ($01);  { $40016B01; }
  SPI_IOC_RD_BITS_PER_WORD : U_Int_32 = (SPI_IOC_MODE_READ shl $18) or ($01 shl $10) or (SPI_IOC_MODE_CTRL shl $08) or ($03);  { $80016B03; }
  SPI_IOC_WR_BITS_PER_WORD : U_Int_32 = (SPI_IOC_MODE_WRITE shl $18) or ($01 shl $10) or (SPI_IOC_MODE_CTRL shl $08) or ($03);  { $40016B03; }
  SPI_IOC_RD_LSB_FIRST : U_Int_32     = (SPI_IOC_MODE_READ shl $18) or ($01 shl $10) or (SPI_IOC_MODE_CTRL shl $08) or ($02);  { $80016B02; }
  SPI_IOC_WR_LSB_FIRST : U_Int_32     = (SPI_IOC_MODE_WRITE shl $18) or ($01 shl $10) or (SPI_IOC_MODE_CTRL shl $08) or ($02);  { $40016B02; }
  SPI_IOC_RD_MAX_SPEED_HZ : U_Int_32  = (SPI_IOC_MODE_READ shl $18) or ($04 shl $10) or (SPI_IOC_MODE_CTRL shl $08) or ($04);  { $80046B04; }
  SPI_IOC_WR_MAX_SPEED_HZ : U_Int_32  = (SPI_IOC_MODE_WRITE shl $18) or ($04 shl $10) or (SPI_IOC_MODE_CTRL shl $08) or ($04);  { $40046B04; }
  SPI_IOC_WR_TRANSFER : U_Int_32      = (SPI_IOC_MODE_WRITE shl $18) or ($20 shl $10) or (SPI_IOC_MODE_CTRL shl $08) or ($00);  { $40206B00; }
  SPI_IOC_RD_MODE32 : U_Int_32        = (SPI_IOC_MODE_READ shl $18) or ($04 shl $10) or (SPI_IOC_MODE_CTRL shl $08) or ($05);  { $80046B05; }
  SPI_IOC_WR_MODE32 : U_Int_32        = (SPI_IOC_MODE_WRITE shl $18) or ($04 shl $10) or (SPI_IOC_MODE_CTRL shl $08) or ($05);  { $40046B05; }

  { ####################################################################################### }
  { ## SPI modes                                                                         ## }
  { ####################################################################################### }
  SPI_IOC_CPHA      = $01;  { Clock phase }
  SPI_IOC_CPOL      = $02;  { Clock polarity }
  SPI_IOC_CS_HIGH   = $04;  { Chip Select active high }
  SPI_IOC_LSB_FIRST = $08;  { Least significant bit first }
  SPI_IOC_3WIRE     = $10;  { SI/SO signals shared }
  SPI_IOC_LOOP      = $20;  { Loopback }
  SPI_IOC_NO_CS     = $40;  { no Chip Select }
  SPI_IOC_READY     = $80;  { Slave pulls low to pause }

  SPI_IOC_MODE_0 = (0 * SPI_IOC_CPOL) or (0 * SPI_IOC_CPHA);  { Clock idle low, data is clocked in on rising edge, output data change on falling edge }
  SPI_IOC_MODE_1 = (0 * SPI_IOC_CPOL) or (1 * SPI_IOC_CPHA);  { Clock idle low, data is clocked in on falling edge, output data change on rising edge }
  SPI_IOC_MODE_2 = (1 * SPI_IOC_CPOL) or (0 * SPI_IOC_CPHA);  { Clock idle high, data is clocked in on falling edge, output data change on rising edge }
  SPI_IOC_MODE_3 = (1 * SPI_IOC_CPOL) or (1 * SPI_IOC_CPHA);  { Clock idle high, data is clocked in on rising, edge output data change on falling edge }

  { ####################################################################################### }
  { ## SPI settings                                                                      ## }
  { ####################################################################################### }
  SPI_IOC_DEFAULT_MODE          = SPI_IOC_MODE_1;
  SPI_IOC_DEFAULT_BITS_PER_WORD = 8;
  SPI_IOC_DEFAULT_LSB_FIRST     = FALSE;
  SPI_IOC_DEFAULT_SPEED         = 8 * 1000 * 1000;

  { ####################################################################################### }
  { ## ADS1262 registers                                                                 ## }
  { ####################################################################################### }
  ADS1262_REGISTER_ID        = $00;
  ADS1262_REGISTER_POWER     = $01;
  ADS1262_REGISTER_INTERFACE = $02;
  ADS1262_REGISTER_MODE0     = $03;
  ADS1262_REGISTER_MODE1     = $04;
  ADS1262_REGISTER_MODE2     = $05;
  ADS1262_REGISTER_INPMUX    = $06;
  ADS1262_REGISTER_OFCAL0    = $07;
  ADS1262_REGISTER_OFCAL1    = $08;
  ADS1262_REGISTER_OFCAL2    = $09;
  ADS1262_REGISTER_FSCAL0    = $0A;
  ADS1262_REGISTER_FSCAL1    = $0B;
  ADS1262_REGISTER_FSCAL2    = $0C;
  ADS1262_REGISTER_IDACMUX   = $0D;
  ADS1262_REGISTER_IDACMAG   = $0E;
  ADS1262_REGISTER_REFMUX    = $0F;
  ADS1262_REGISTER_TDACP     = $10;
  ADS1262_REGISTER_TDACN     = $11;
  ADS1262_REGISTER_GPIOCON   = $12;
  ADS1262_REGISTER_GPIODIR   = $13;
  ADS1262_REGISTER_GPIODAT   = $14;

  { ####################################################################################### }
  { ## ADS1262 commands                                                                  ## }
  { ####################################################################################### }
  ADS1262_COMMAND_NOP     = $00;
  ADS1262_COMMAND_RESET   = $06;
  ADS1262_COMMAND_START1  = $08;
  ADS1262_COMMAND_STOP1   = $0A;
  ADS1262_COMMAND_RDATA1  = $12;
  ADS1262_COMMAND_SYOCAL1 = $16;
  ADS1262_COMMAND_SYGCAL1 = $17;
  ADS1262_COMMAND_SFOCAL1 = $19;
  ADS1262_COMMAND_RREG    = $20;
  ADS1262_COMMAND_WREG    = $40;

  { ####################################################################################### }
  { ## ADS1262 POWER bits                                                                ## }
  { ####################################################################################### }
  ADS1262_POWER_RESET_MASK        = $10;
  ADS1262_POWER_VBIAS_MASK        = $02;
  ADS1262_POWER_INTREF_MASK       = $01;
  ADS1262_POWER_RESET_HAS_OCCURED = $10;
  ADS1262_POWER_VBIAS_ENABLED     = $02;
  ADS1262_POWER_VBIAS_DISABLED    = $00;
  ADS1262_POWER_INTREF_ENABLED    = $01;
  ADS1262_POWER_INTREF_DISABLED   = $00;

  { ####################################################################################### }
  { ## ADS1262 MODE0 bits                                                                ## }
  { ####################################################################################### }
  ADS1262_MODE0_REFREV_MASK                                    = $80;
  ADS1262_MODE0_RUNMODE_MASK                                   = $40;
  ADS1262_MODE0_CHOP_MASK                                      = $30;
  ADS1262_MODE0_DELAY_MASK                                     = $0F;
  ADS1262_MODE0_REFREV_NORMAL_POLARITY                         = $00;
  ADS1262_MODE0_RUNMODE_CONTINUOUS_CONVERSION                  = $00;
  ADS1262_MODE0_CHOP_INPUT_CHOP_AND_IDAC_ROTATION_DISABLED     = $00;
  ADS1262_MODE0_CHOP_INPUT_CHOP_ENABLED_IDAC_ROTATION_DISABLED = $10;
  ADS1262_MODE0_DELAY_NO_DELAY                                 = $00;

  { ####################################################################################### }
  { ## ADS1262 MODE1 bits                                                                ## }
  { ####################################################################################### }
  ADS1262_MODE1_FILTER_MASK       = $E0;
  ADS1262_MODE1_SBADC_MASK        = $10;
  ADS1262_MODE1_SBPOL_MASK        = $08;
  ADS1262_MODE1_SBMAG_MASK        = $07;
  ADS1262_MODE1_FILTER_SINC1_MODE = $00;
  ADS1262_MODE1_FILTER_SINC2_MODE = $20;
  ADS1262_MODE1_FILTER_SINC3_MODE = $40;
  ADS1262_MODE1_FILTER_SINC4_MODE = $60;
  ADS1262_MODE1_FILTER_FIR_MODE   = $80;

  { ####################################################################################### }
  { ## ADS1262 MODE2 bits                                                                ## }
  { ####################################################################################### }
  ADS1262_MODE2_BYPASS_MASK         = $80;
  ADS1262_MODE2_GAIN_MASK           = $70;
  ADS1262_MODE2_DR_MASK             = $0F;
  ADS1262_MODE2_BYPASS_PGA_BYPASSED = $80;
  ADS1262_MODE2_BYPASS_PGA_ENABLED  = $00;
  ADS1262_MODE2_GAIN_01             = $00;
  ADS1262_MODE2_GAIN_02             = $10;
  ADS1262_MODE2_GAIN_04             = $20;
  ADS1262_MODE2_GAIN_08             = $30;
  ADS1262_MODE2_GAIN_16             = $40;
  ADS1262_MODE2_GAIN_32             = $50;
  ADS1262_MODE2_DR_2_5_SPS          = $00;  { Data rate : 2.5 SPS }
  ADS1262_MODE2_DR_5_SPS            = $01;  { Data rate : 5 SPS }
  ADS1262_MODE2_DR_10_SPS           = $02;  { Data rate : 10 SPS }
  ADS1262_MODE2_DR_16_6_SPS         = $03;  { Data rate : 16.6 SPS }
  ADS1262_MODE2_DR_20_SPS           = $04;  { Data rate : 20 SPS (old default) }
  ADS1262_MODE2_DR_50_SPS           = $05;  { Data rate : 50 SPS }
  ADS1262_MODE2_DR_60_SPS           = $06;  { Data rate : 60 SPS }
  ADS1262_MODE2_DR_100_SPS          = $07;  { Data rate : 100 SPS }
  ADS1262_MODE2_DR_400_SPS          = $08;  { Data rate : 400 SPS }
  ADS1262_MODE2_DR_1200_SPS         = $09;  { Data rate : 1,200 SPS }
  ADS1262_MODE2_DR_2400_SPS         = $0A;  { Data rate : 2,400 SPS }
  ADS1262_MODE2_DR_4800_SPS         = $0B;  { Data rate : 4,800 SPS }
  ADS1262_MODE2_DR_7200_SPS         = $0C;  { Data rate : 7,200 SPS }
  ADS1262_MODE2_DR_14400_SPS        = $0D;  { Data rate : 14,400 SPS }
  ADS1262_MODE2_DR_19200_SPS        = $0E;  { Data rate : 19,200 SPS }
  ADS1262_MODE2_DR_38400_SPS        = $0F;  { Data rate : 38,400 SPS }

  { ####################################################################################### }
  { ## ADS1262 INPMUX bits                                                               ## }
  { ####################################################################################### }
  ADS1262_INPMUX_MUXP_MASK       = $F0;
  ADS1262_INPMUX_MUXN_MASK       = $0F;
  ADS1262_INPMUX_MUXP_AIN0       = $00;  { Default }
  ADS1262_INPMUX_MUXP_AIN1       = $10;
  ADS1262_INPMUX_MUXP_AIN2       = $20;
  ADS1262_INPMUX_MUXP_AIN3       = $30;
  ADS1262_INPMUX_MUXP_AIN4       = $40;
  ADS1262_INPMUX_MUXP_AIN5       = $50;
  ADS1262_INPMUX_MUXP_AIN6       = $60;
  ADS1262_INPMUX_MUXP_AIN7       = $70;
  ADS1262_INPMUX_MUXP_AIN8       = $80;
  ADS1262_INPMUX_MUXP_AIN9       = $90;
  ADS1262_INPMUX_MUXP_AINCOM     = $A0;
  ADS1262_INPMUX_MUXP_TEMP_M_POS = $B0;
  ADS1262_INPMUX_MUXP_APS_M_POS  = $C0;
  ADS1262_INPMUX_MUXP_DPS_M_POS  = $D0;
  ADS1262_INPMUX_MUXP_TDAC_POS   = $E0;
  ADS1262_INPMUX_MUXP_FLOAT      = $F0;
  ADS1262_INPMUX_MUXN_AIN0       = $00;
  ADS1262_INPMUX_MUXN_AIN1       = $01;  { Old Default }
  ADS1262_INPMUX_MUXN_AIN2       = $02;
  ADS1262_INPMUX_MUXN_AIN3       = $03;
  ADS1262_INPMUX_MUXN_AIN4       = $04;
  ADS1262_INPMUX_MUXN_AIN5       = $05;
  ADS1262_INPMUX_MUXN_AIN6       = $06;
  ADS1262_INPMUX_MUXN_AIN7       = $07;
  ADS1262_INPMUX_MUXN_AIN8       = $08;
  ADS1262_INPMUX_MUXN_AIN9       = $09;
  ADS1262_INPMUX_MUXN_AINCOM     = $0A;  { New Default }
  ADS1262_INPMUX_MUXN_TEMP_M_POS = $0B;
  ADS1262_INPMUX_MUXN_APS_M_POS  = $0C;
  ADS1262_INPMUX_MUXN_DPS_M_POS  = $0D;
  ADS1262_INPMUX_MUXN_TDAC_POS   = $0E;
  ADS1262_INPMUX_MUXN_FLOAT      = $0F;

  { ####################################################################################### }
  { ## ADS1262 initial data                                                              ## }
  { ####################################################################################### }
  ADS1262_REGISTER_OFCAL_LENGTH                = 3;
  ADS1262_WAIT_TIME_MS_COMMAND                 = 100;
  ADS1262_WAIT_TIME_MS_SELF_CALIBRATION_BEFORE = 2000;
  ADS1262_WAIT_TIME_MS_SELF_CALIBRATION_AFTER  = 500;
  ADS1262_WAIT_TIME_MS_READ_REGISTER           = 0;
  ADS1262_WAIT_TIME_MS_WRITE_REGISTER          = 10;
  ADS1262_WAIT_TIME_MS_READ_ADC1               = 0;
  ADS1262_CRC_MAGIC_BYTE                       = $9B;
  ADS1262_EMA_SPAN                             = 100;
  ADS1262_VBIAS_MODE                           = ADS1262_POWER_VBIAS_ENABLED;
  ADS1262_PGA_MODE                             = ADS1262_MODE2_BYPASS_PGA_ENABLED;
  ADS1262_DATA_RATE                            = ADS1262_MODE2_DR_1200_SPS;
  ADS1262_FILTER_MODE                          = ADS1262_MODE1_FILTER_SINC1_MODE;
  ADS1262_CHOP_MODE                            = ADS1262_MODE0_CHOP_INPUT_CHOP_AND_IDAC_ROTATION_DISABLED;
  ADS1262_GAIN                                 = ADS1262_MODE2_GAIN_32;

Type
  { ####################################################################################### }
  { ## T_GPIO_Pin                                                                        ## }
  { ####################################################################################### }
  T_GPIO_Pin = Class(TObject)
  Protected
      M_GPIO_Pin : U_Int_32;
      Procedure GPIO_Write_File (Const F_Filename : String; Const F_Output_Buffer_A : T_Buffer_A; F_Length : U_Int_32);
      Function GPIO_Read_File (Const F_Filename : String; F_Length : U_Int_32) : String;
      Procedure Set_Export (F_Export_F : Boolean);
      Function Get_Direction () : T_GPIO_Direction;
      Procedure Set_Direction (F_GPIO_Direction : T_GPIO_Direction);
      Function Get_Value () : Boolean;
      Procedure Set_Value (F_Value : Boolean);
  Public
      Constructor Create (F_GPIO_Pin : U_Int_32);
      Destructor Destroy; Override;
  Published
      Property Direction : T_GPIO_Direction Read Get_Direction Write Set_Direction;
      Property Value : Boolean Read Get_Value Write Set_Value;
  End; { T_SPI_DEVICE }

  { ####################################################################################### }
  { ## T_SPI_Device                                                                      ## }
  { ####################################################################################### }
  T_SPI_Device = Class(TObject)
  Protected
      M_SPI_File_Handle :   Int_32;
      M_SPI_Mode :          U_Int_8;
      M_SPI_Bits_per_Word : U_Int_8;
      M_SPI_LSB_First :     Boolean;
      M_SPI_Max_Speed :     U_Int_32;
      Function Get_SPI_Mode : U_Int_8;
      Procedure Set_SPI_Mode (F_Mode : U_Int_8);
      Function Get_SPI_Bits_per_Word : U_Int_8;
      Procedure Set_SPI_Bits_per_Word (F_Bits_per_Word : U_Int_8);
      Function Get_SPI_LSB_First : Boolean;
      Procedure Set_SPI_LSB_First (F_LSB_First : Boolean);
      Function Get_SPI_Max_Speed : U_Int_32;
      Procedure Set_SPI_Max_Speed (F_Max_Speed : U_Int_32);
      Function SPI_Write_Read_Buffer (Var F_Output_Buffer_A : T_Buffer_A; Var F_Input_Buffer_A : T_Buffer_A; F_Length : U_Int_8) : Int_32;
  Public
      Constructor Create ();
      Destructor Destroy; Override;
  Published
      Property SPI_Mode : U_Int_8 Read Get_SPI_Mode Write Set_SPI_Mode;
      Property SPI_Bits_per_Word : U_Int_8 Read Get_SPI_Bits_per_Word Write Set_SPI_Bits_per_Word;
      Property SPI_LSB_First : Boolean Read Get_SPI_LSB_First Write Set_SPI_LSB_First;
      Property SPI_Max_Speed : U_Int_32 Read Get_SPI_Max_Speed Write Set_SPI_Max_Speed;
  End; { T_SPI_Device }


  { ####################################################################################### }
  { ## T_ADS1262                                                                         ## }
  { ####################################################################################### }
  T_ADS1262 = Class(T_SPI_Device)
  Protected
      M_I2C_Address : U_Int_8;
      M_Gain :        U_Int_16;
      M_Count :       UInt64;
      M_Bit_N :       Integer;
      M_EMA_Bit_N :   Double;
      M_DRDY_Pin :    T_GPIO_Pin;
  Public
      Constructor Create ();
      Destructor Destroy (); Override;
      Procedure Reset_and_Init ();
      Procedure Execute_Command (F_Command : U_Int_8);
      Function Read_Register (F_Register_Adress : U_Int_8) : U_Int_8;
      Procedure Write_Register (F_Register_Adress : U_Int_8; F_Data : U_Int_8);
      Procedure System_Offset_Self_Calibration ();
      Procedure Start_Continuous_Conversion ();
      Procedure Stop_Continuous_Conversion ();
      Procedure Set_POWER (F_VBIAS_Mode : U_Int_8; F_INTREF_Mode : U_Int_8);
      Function Get_INPMUX () : U_Int_8;
      Procedure Set_INPMUX (F_MUXP : U_Int_8; F_MUXN : U_Int_8);
      Procedure Set_PGA (F_Bypass_Mode : U_Int_8; F_Gain_Mode : U_Int_8);
      Procedure Set_Data_Rate (F_Rate_Mode : U_Int_8);
      Procedure Set_Filter_Mode (F_Filter_Mode : U_Int_8);
      Procedure Set_Chop_Mode (F_Chop_Mode : U_Int_8);
      Procedure Set_OFCAL (F_OFCAL : Int_32);
      Function Read_ADC1_Data (Var F_Status : U_Int_8; Var F_CRC : U_Int_8) : Int_32;
      Function Read_ADC1_Data : Int_32;
      Procedure Read_All_Registers (Var F_Register_Block : T_Register_Block);
      Function Calculate_Voltage (F_Data : Int_32) : Double;
      Function Get_Voltage () : Double;
  Published
      Property DRDY_Pin : T_GPIO_Pin Read M_DRDY_Pin;
      Property ADC1_Data : Int_32 Read Read_ADC1_Data;
      Property Voltage : Double Read Get_Voltage;
      Property EMA_Bit_N : Double Read M_EMA_Bit_N;
  End; { T_ADS1262 }


Implementation

Uses
  SysUtils,
  Dialogs,
  Math;


{ ####################################################################################### }
{ ## T_GPIO_Pin                                                                        ## }
{ ####################################################################################### }

{ --------------------------------------------------------------------------------------- }
Constructor T_GPIO_Pin.Create (F_GPIO_Pin : U_Int_32);
{ Initialization of the object                                                            }
{ --------------------------------------------------------------------------------------- }
Begin { T_GPIO_Pin.Create }
  Inherited Create ();

  {$IFDEF DEBUG_GPIO_OUTPUT}
  WriteLn ('Begin of: T_GPIO_Pin.Create');
  {$ENDIF}

  M_GPIO_Pin := F_GPIO_Pin;
  Set_Export (TRUE);
End; { T_GPIO_Pin.Create }


{ --------------------------------------------------------------------------------------- }
Destructor T_GPIO_Pin.Destroy ();
{ Free data                                                                               }
{ --------------------------------------------------------------------------------------- }
Begin { T_GPIO_Pin.Destroy }
  {$IFDEF DEBUG_GPIO_OUTPUT}
  WriteLn ('Begin of: T_GPIO_Pin.Destroy');
  {$ENDIF}

  Set_Export (FALSE);

  Inherited Destroy;
End; { T_GPIO_Pin.Destroy }


{ --------------------------------------------------------------------------------------- }
Procedure T_GPIO_Pin.GPIO_Write_File (Const F_Filename : String; Const F_Output_Buffer_A : T_Buffer_A; F_Length : U_Int_32);
{ Write data to file                                                                      }
{ --------------------------------------------------------------------------------------- }
Var
  GPIO_File_Handle : Int_32;

Begin { T_GPIO_Pin.GPIO_Write_File }
  {$IFDEF DEBUG_GPIO_OUTPUT}
  WriteLn ('Begin of: T_GPIO_Pin.GPIO_Write_File');
  {$ENDIF}

  GPIO_File_Handle := FpOpen (F_Filename, O_WRONLY);
  If GPIO_File_Handle < 0 Then
    Begin { then }
      ShowMessage ('Error T_GPIO_Pin.GPIO_Write_File:' + IntToStr (GPIO_File_Handle));
      Exit;
    End; { then }

  FpWrite (GPIO_File_Handle, F_Output_Buffer_A [0], F_Length);

  FpClose (GPIO_File_Handle);
End; { T_GPIO_Pin.GPIO_Write_File }


{ --------------------------------------------------------------------------------------- }
Function T_GPIO_Pin.GPIO_Read_File (Const F_Filename : String; F_Length : U_Int_32) : String;
{ Read data from file                                                                     }
{ --------------------------------------------------------------------------------------- }
Var
  GPIO_File_Handle : Int_32;
  Read_N :           U_Int_32;

Begin { T_GPIO_Pin.GPIO_Read_File }
  {$IFDEF DEBUG_GPIO_OUTPUT}
  WriteLn ('Begin of: T_GPIO_Pin.GPIO_Read_File');
  {$ENDIF}

  Result := '';

  If F_Length <= 0 Then
    Begin { then }
      Exit;
    End; { then }

  SetLength (Result, F_Length);

  GPIO_File_Handle := FpOpen (F_Filename, O_RDONLY);
  If GPIO_File_Handle < 0 Then
    Begin { then }
      ShowMessage ('Error T_GPIO_Pin.GPIO_Read_File:' + IntToStr (GPIO_File_Handle));
      Exit;
    End; { then }

  Read_N := FpRead (GPIO_File_Handle, Result [1], F_Length);

  FpClose (GPIO_File_Handle);

  SetLength (Result, Read_N);
  Result := Trim (Result);
End; { T_GPIO_Pin.GPIO_Read_File }


{ --------------------------------------------------------------------------------------- }
Procedure T_GPIO_Pin.Set_Export (F_Export_F : Boolean);
{ Set export                                                                              }
{ --------------------------------------------------------------------------------------- }
Var
  S : String;

Begin { T_GPIO_Pin.Set_Export }
  {$IFDEF DEBUG_GPIO_OUTPUT}
  WriteLn ('Begin of: T_GPIO_Pin.Set_Export');
  {$ENDIF}

  S := IntToStr (M_GPIO_Pin);

  If F_Export_F = TRUE Then
    Begin { then }
      GPIO_Write_File (GPIO_LINUX_EXPORT_FILE, @S [1], Length (S));
    End { then }
  Else
    Begin { else  }
      GPIO_Write_File (GPIO_LINUX_UNEXPORT_FILE, @S [1], Length (S));
    End; { else  }

  Sleep (GPIO_WAIT_TIME_MS_EXPORT);
End; { T_GPIO_Pin.Set_Export }


{ --------------------------------------------------------------------------------------- }
Function T_GPIO_Pin.Get_Direction () : T_GPIO_Direction;
{ Get direction of pin                                                                    }
{ --------------------------------------------------------------------------------------- }
Var
  Format_S : String;
  S :        String;

Begin { T_GPIO_Pin.Get_Direction }
  {$IFDEF DEBUG_GPIO_OUTPUT}
  WriteLn ('Begin of: T_GPIO_Pin.Get_Direction');
  {$ENDIF}

  Format_S := Format (GPIO_LINUX_GPIOPIN_DIR + 'direction', [M_GPIO_Pin]);
  S        := GPIO_Read_File (Format_S, 3);
  Case S Of
      'in' :
        Begin { 'in' }
          Result := GPIO_DIRECTION_IN;
        End; { 'in' }
      'out' :
        Begin { 'out' }
          Result := GPIO_DIRECTION_OUT;
        End; { 'out' }
      Else
        Begin { else }
          Result := GPIO_DIRECTION_IN;
        End; { else }
    End; { Case }
End; { T_GPIO_Pin.Get_Direction }


{ --------------------------------------------------------------------------------------- }
Procedure T_GPIO_Pin.Set_Direction (F_GPIO_Direction : T_GPIO_Direction);
{ Get direction of pin                                                                    }
{ --------------------------------------------------------------------------------------- }
Var
  Format_S : String;
  S :        String;

Begin { T_GPIO_Pin.Set_Direction }
  {$IFDEF DEBUG_GPIO_OUTPUT}
  WriteLn ('Begin of: T_GPIO_Pin.Set_Direction');
  {$ENDIF}

  Format_S := Format (GPIO_LINUX_GPIOPIN_DIR + 'direction', [M_GPIO_Pin]);
  Case F_GPIO_Direction Of
      GPIO_DIRECTION_IN :
        Begin { GPIO_DIRECTION_IN }
          S := 'in';
        End; { GPIO_DIRECTION_IN }
      GPIO_DIRECTION_OUT :
        Begin { GPIO_DIRECTION_OUT }
          S := 'out';
        End; { GPIO_DIRECTION_OUT }
      Else
        Begin { else }
          S := 'in';
        End; { else }
    End; { Case }

  GPIO_Write_File (Format_S, @S [1], Length (S));

  Sleep (GPIO_WAIT_TIME_MS_COMMAND);
End; { T_GPIO_Pin.Set_Direction }


{ --------------------------------------------------------------------------------------- }
Function T_GPIO_Pin.Get_Value () : Boolean;
{ Get value of pin                                                                        }
{ --------------------------------------------------------------------------------------- }
Var
  Format_S : String;
  S :        String;

Begin { T_GPIO_Pin.Get_Value }
  {$IFDEF DEBUG_GPIO_OUTPUT}
  WriteLn ('Begin of: T_GPIO_Pin.Get_Value');
  {$ENDIF}

  Format_S := Format (GPIO_LINUX_GPIOPIN_DIR + 'value', [M_GPIO_Pin]);
  S        := GPIO_Read_File (Format_S, 1);
  Case S Of
      '0' :
        Begin { '0' }
          Result := FALSE;
        End; { '0' }
      '1' :
        Begin { '1' }
          Result := TRUE;
        End; { '1' }
      Else
        Begin { else }
          Result := FALSE;
        End; { else }
    End; { Case }
End; { T_GPIO_Pin.Get_Value }


{ --------------------------------------------------------------------------------------- }
Procedure T_GPIO_Pin.Set_Value (F_Value : Boolean);
{ Get value of pin                                                                        }
{ --------------------------------------------------------------------------------------- }
Var
  Format_S : String;
  S :        String;

Begin { T_GPIO_Pin.Set_Value }
  {$IFDEF DEBUG_GPIO_OUTPUT}
  WriteLn ('Begin of: T_GPIO_Pin.Set_Value');
  {$ENDIF}

  Format_S := Format (GPIO_LINUX_GPIOPIN_DIR + 'value', [M_GPIO_Pin]);
  If F_Value = TRUE Then
    Begin { then }
      S := '1';
    End { then }
  Else
    Begin { else  }
      S := '0';
    End; { else  }
  GPIO_Write_File (Format_S, @S [1], Length (S));
End; { T_GPIO_Pin.Set_Value }


{ ####################################################################################### }
{ ## T_SPI_Device                                                                      ## }
{ ####################################################################################### }

{ --------------------------------------------------------------------------------------- }
Constructor T_SPI_Device.Create ();
{ Initialization of the object                                                            }
{ --------------------------------------------------------------------------------------- }
Begin { T_SPI_Device.Create }
  Inherited Create ();

  {$IFDEF DEBUG_SPI_OUTPUT}
  WriteLn ('Begin of  : T_SPI_Device.Create');
  {$ENDIF}

  M_SPI_File_Handle := FpOpen (SPI_IOC_DEVICE, O_RDWR);
  If M_SPI_File_Handle < 0 Then
    Begin { then }
      ShowMessage ('Error open SPI bus:' + IntToStr (M_SPI_File_Handle));
      Exit;
    End; { then }

  Sleep (SPI_IOC_WAIT_TIME_MS_OPEN);

  SPI_Mode          := SPI_IOC_DEFAULT_MODE;
  SPI_Bits_per_Word := SPI_IOC_DEFAULT_BITS_PER_WORD;
  SPI_LSB_First     := SPI_IOC_DEFAULT_LSB_FIRST;
  SPI_Max_Speed     := SPI_IOC_DEFAULT_SPEED;
End; { T_SPI_Device.Create }


{ --------------------------------------------------------------------------------------- }
Destructor T_SPI_Device.Destroy ();
{ Free data                                                                               }
{ --------------------------------------------------------------------------------------- }
Begin { T_SPI_Device.Destroy }
  {$IFDEF DEBUG_SPI_OUTPUT}
  WriteLn ('Begin of  : T_SPI_Device.Destroy');
  {$ENDIF}

  FpClose (M_SPI_File_Handle);

  Inherited Destroy;
End; { T_SPI_Device.Destroy }


{ --------------------------------------------------------------------------------------- }
Function T_SPI_Device.Get_SPI_Mode () : U_Int_8;
{ Get SPI mode                                                                            }
{ --------------------------------------------------------------------------------------- }
Var
  Return_Value : Int_32;

Begin { T_SPI_Device.Get_SPI_Mode }
  {$IFDEF DEBUG_SPI_OUTPUT}
  WriteLn ('Begin of  : T_SPI_Device.Get_SPI_Mode');
  {$ENDIF}

  Return_Value := FpIOCtl (M_SPI_File_Handle, SPI_IOC_RD_MODE, @Result);

  If Return_Value < 0 Then
    Begin { then }
      ShowMessage ('Error read SPI mode: ' + IntToStr (Return_Value));
    End; { then }

  M_SPI_Mode := Result;
End; { T_SPI_Device.Get_SPI_Mode }


{ --------------------------------------------------------------------------------------- }
Procedure T_SPI_Device.Set_SPI_Mode (F_Mode : U_Int_8);
{ Set SPI mode                                                                            }
{ --------------------------------------------------------------------------------------- }
Var
  Return_Value : Int_32;

Begin { T_SPI_Device.Set_SPI_Mode }
  {$IFDEF DEBUG_SPI_OUTPUT}
  WriteLn ('Begin of  : T_SPI_Device.Set_SPI_Mode');
  {$ENDIF}

  M_SPI_Mode := F_Mode;

  Return_Value := FpIOCtl (M_SPI_File_Handle, SPI_IOC_WR_MODE, @F_Mode);

  If Return_Value < 0 Then
    Begin { then }
      ShowMessage ('Error set SPI mode: ' + IntToStr (Return_Value));
    End; { then }

  Sleep (SPI_IOC_WAIT_TIME_MS_COMMAND);
End; { T_SPI_Device.Set_SPI_Mode }


{ --------------------------------------------------------------------------------------- }
Function T_SPI_Device.Get_SPI_Bits_per_Word : U_Int_8;
{ Get bits per word                                                                       }
{ --------------------------------------------------------------------------------------- }
Var
  Return_Value : Int_32;

Begin { T_SPI_Device.Get_SPI_Bits_per_Word }
  {$IFDEF DEBUG_SPI_OUTPUT}
  WriteLn ('Begin of  : T_SPI_Device.Get_SPI_Bits_per_Word');
  {$ENDIF}

  Return_Value := FpIOCtl (M_SPI_File_Handle, SPI_IOC_RD_BITS_PER_WORD, @Result);

  If Return_Value < 0 Then
    Begin { then }
      ShowMessage ('Error read bits per word: ' + IntToStr (Return_Value));
    End; { then }

  M_SPI_Bits_per_Word := Result;
End; { T_SPI_Device.Get_SPI_Bits_per_Word }


{ --------------------------------------------------------------------------------------- }
Procedure T_SPI_Device.Set_SPI_Bits_per_Word (F_Bits_per_Word : U_Int_8);
{ Set bits per word                                                                       }
{ --------------------------------------------------------------------------------------- }
Var
  Return_Value : Int_32;

Begin { T_SPI_Device.Set_SPI_Bits_per_Word }
  {$IFDEF DEBUG_SPI_OUTPUT}
  WriteLn ('Begin of  : T_SPI_Device.Set_SPI_Bits_per_Word');
  {$ENDIF}

  M_SPI_Bits_per_Word := F_Bits_per_Word;

  Return_Value := FpIOCtl (M_SPI_File_Handle, SPI_IOC_WR_BITS_PER_WORD, @F_Bits_per_Word);

  If Return_Value < 0 Then
    Begin { then }
      ShowMessage ('Error set bits per word: ' + IntToStr (Return_Value));
    End; { then }

  Sleep (SPI_IOC_WAIT_TIME_MS_COMMAND);
End; { T_SPI_Device.Set_SPI_Bits_per_Word }


{ --------------------------------------------------------------------------------------- }
Function T_SPI_Device.Get_SPI_LSB_First : Boolean;
{ Get bits per word                                                                       }
{ --------------------------------------------------------------------------------------- }
Var
  Return_Value : Int_32;

Begin { T_SPI_Device.Get_SPI_LSB_First }
  {$IFDEF DEBUG_SPI_OUTPUT}
  WriteLn ('Begin of  : T_SPI_Device.Get_SPI_LSB_First');
  {$ENDIF}

  Return_Value := FpIOCtl (M_SPI_File_Handle, SPI_IOC_RD_LSB_FIRST, @Result);

  If Return_Value < 0 Then
    Begin { then }
      ShowMessage ('Error read LSB_first: ' + IntToStr (Return_Value));
    End; { then }

  M_SPI_LSB_First := Result;
End; { T_SPI_Device.Get_SPI_LSB_First }


{ --------------------------------------------------------------------------------------- }
Procedure T_SPI_Device.Set_SPI_LSB_First (F_LSB_First : Boolean);
{ Set LSB_First; F_LSB_First=$00 or F_LSB_First=$FF                                       }
{ --------------------------------------------------------------------------------------- }
Var
  Value :        U_Int_16;
  Return_Value : Int_32;

Begin { T_SPI_Device.Set_SPI_LSB_First }
  {$IFDEF DEBUG_SPI_OUTPUT}
  WriteLn ('Begin of  : T_SPI_Device.Set_SPI_LSB_First');
  {$ENDIF}

  M_SPI_LSB_First := F_LSB_First;

  If F_LSB_First = TRUE Then
    Begin { then }
      Value := $0001;
    End { then }
  Else
    Begin { else  }
      Value := $0000;
    End; { else  }

  Return_Value := FpIOCtl (M_SPI_File_Handle, SPI_IOC_WR_LSB_FIRST, @Value);

  If Return_Value < 0 Then
    Begin { then }
      ShowMessage ('Error set LSB_first: ' + IntToStr (Return_Value));
    End; { then }

  Sleep (SPI_IOC_WAIT_TIME_MS_COMMAND);
End; { T_SPI_Device.Set_SPI_LSB_First }


{ --------------------------------------------------------------------------------------- }
Function T_SPI_Device.Get_SPI_Max_Speed : U_Int_32;
{ Get bits per word                                                                       }
{ --------------------------------------------------------------------------------------- }
Var
  Return_Value : Int_32;

Begin { T_SPI_Device.Get_SPI_Max_Speed }
  {$IFDEF DEBUG_SPI_OUTPUT}
  WriteLn ('Begin of  : T_SPI_Device.Get_SPI_Max_Speed');
  {$ENDIF}

  Return_Value := FpIOCtl (M_SPI_File_Handle, SPI_IOC_RD_MAX_SPEED_HZ, @Result);

  If Return_Value < 0 Then
    Begin { then }
      ShowMessage ('Error read max speed: ' + IntToStr (Return_Value));
    End; { then }

  M_SPI_Max_Speed := Result;
End; { T_SPI_Device.Get_SPI_Max_Speed }


{ --------------------------------------------------------------------------------------- }
Procedure T_SPI_Device.Set_SPI_Max_Speed (F_Max_Speed : U_Int_32);
{ Set bits per word                                                                       }
{ --------------------------------------------------------------------------------------- }
Var
  Return_Value : Int_32;

Begin { T_SPI_Device.Set_SPI_Max_Speed }
  {$IFDEF DEBUG_SPI_OUTPUT}
  WriteLn ('Begin of  : T_SPI_Device.Set_SPI_Max_Speed');
  {$ENDIF}

  M_SPI_Max_Speed := F_Max_Speed;

  Return_Value := FpIOCtl (M_SPI_File_Handle, SPI_IOC_WR_MAX_SPEED_HZ, @F_Max_Speed);

  If Return_Value < 0 Then
    Begin { then }
      ShowMessage ('Error set max speed: ' + IntToStr (Return_Value));
    End; { then }

  Sleep (SPI_IOC_WAIT_TIME_MS_COMMAND);
End; { T_SPI_Device.Set_SPI_Max_Speed }


{ --------------------------------------------------------------------------------------- }
Function T_SPI_Device.SPI_Write_Read_Buffer (Var F_Output_Buffer_A : T_Buffer_A; Var F_Input_Buffer_A : T_Buffer_A; F_Length : U_Int_8) : Int_32;
{ Write and read buffer                                                                   }
{ --------------------------------------------------------------------------------------- }
Var
  Transfer_R : T_SPI_Transfer_R;

Begin { T_SPI_Device.SPI_Write_Read_Buffer }
  {$IFDEF DEBUG_SPI_OUTPUT}
  WriteLn ('Begin of  : T_SPI_Device.SPI_Write_Read_Buffer');
  {$ENDIF}

  If F_Length <= 0 Then
    Begin { then }
      ShowMessage ('Error T_SPI_Device.SPI_Write_Read_Buffer: F_Length <= 0');
      Exit;
    End; { then }

  {$WARNINGS OFF}
  Transfer_R.tx_buf        := U_Int_64 (@(F_Output_Buffer_A [0]));
  Transfer_R.rx_buf        := U_Int_64 (@(F_Input_Buffer_A [0]));
  {$WARNINGS ON}
  Transfer_R.len           := F_Length;
  Transfer_R.speed_hz      := SPI_IOC_DEFAULT_SPEED;
  Transfer_R.delay_usecs   := 0;
  Transfer_R.bits_per_word := SPI_IOC_DEFAULT_BITS_PER_WORD;
  Transfer_R.cs_change     := 0;
  Transfer_R.pad           := 0;

  Result := FpIOCtl (M_SPI_File_Handle, SPI_IOC_WR_TRANSFER, @Transfer_R);

  If Result < 0 Then
    Begin { then }
      ShowMessage ('Error write and read buffer: ' + IntToStr (Result));
    End; { then }
End; { T_SPI_Device.SPI_Write_Read_Buffer }


{ ####################################################################################### }
{ ## T_ADS1262                                                                         ## }
{ ####################################################################################### }

{ --------------------------------------------------------------------------------------- }
Constructor T_ADS1262.Create ();
{ Initialization of the object                                                            }
{ --------------------------------------------------------------------------------------- }
Begin { T_ADS1262.Create }
  Inherited Create ();

  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Create');
  {$ENDIF}

  M_DRDY_Pin           := T_GPIO_Pin.Create (GPIO_DRDY_PIN);
  M_DRDY_Pin.Direction := GPIO_DIRECTION_IN;

  M_Count := 0;

  Reset_and_Init ();
End; { T_ADS1262.Create }


{ --------------------------------------------------------------------------------------- }
Destructor T_ADS1262.Destroy ();
{ Free data                                                                               }
{ --------------------------------------------------------------------------------------- }
Begin { T_ADS1262.Destroy }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Destroy');
  {$ENDIF}

  M_DRDY_Pin.Free;

  Stop_Continuous_Conversion ();
  Execute_Command (ADS1262_COMMAND_RESET);

  Inherited Destroy ();
End; { T_ADS1262.Destroy }


{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.Reset_and_Init ();
{ Init ADC                                                                                }
{ --------------------------------------------------------------------------------------- }
Var
  Register_Block : T_Register_Block;
  I :              Integer;

Begin { T_ADS1262.Reset_and_Init }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Init');
  {$ENDIF}

  M_EMA_Bit_N := 0;

  Execute_Command (ADS1262_COMMAND_RESET);

  Read_All_Registers (Register_Block);

  Stop_Continuous_Conversion ();
  Set_POWER (ADS1262_VBIAS_MODE, ADS1262_POWER_INTREF_ENABLED);
  Set_INPMUX (ADS1262_INPMUX_MUXP_AIN0, ADS1262_INPMUX_MUXN_AINCOM);
  Set_PGA (ADS1262_PGA_MODE, ADS1262_GAIN);
  Set_Data_Rate (ADS1262_DATA_RATE);
  Set_Filter_Mode (ADS1262_FILTER_MODE);
  Set_Chop_Mode (ADS1262_CHOP_MODE);
  System_Offset_Self_Calibration ();

  Read_All_Registers (Register_Block);
End; { T_ADS1262.Reset_and_Init }


{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.Execute_Command (F_Command : U_Int_8);
{ Execute a one byte command                                                              }
{ --------------------------------------------------------------------------------------- }
Var
  Length :          U_Int_8;
  Output_Buffer_A : T_Buffer_A;
  Input_Buffer_A :  T_Buffer_A;

Begin { T_ADS1262.Execute_Command }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Execute_Command');
  {$ENDIF}

  Length := 1;
  SetLength (Output_Buffer_A, Length);
  SetLength (Input_Buffer_A, Length);

  Output_Buffer_A[0] := F_Command;

  SPI_Write_Read_Buffer (Output_Buffer_A, Input_Buffer_A, Length);

  {$IF ADS1262_WAIT_TIME_MS_COMMAND > 0 }
  Sleep (ADS1262_WAIT_TIME_MS_COMMAND);
  {$ENDIF}
End; { T_ADS1262.Execute_Command }


{ --------------------------------------------------------------------------------------- }
Function T_ADS1262.Read_Register (F_Register_Adress : U_Int_8) : U_Int_8;
{ Read data from register                                                                 }
{ --------------------------------------------------------------------------------------- }
Var
  Length :          U_Int_8;
  Output_Buffer_A : T_Buffer_A;
  Input_Buffer_A :  T_Buffer_A;

Begin { T_ADS1262.Read_Register }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Read_Register');
  {$ENDIF}

  Length := 3;
  SetLength (Output_Buffer_A, Length);
  SetLength (Input_Buffer_A, Length);

  Output_Buffer_A[0] := ADS1262_COMMAND_RREG or F_Register_Adress;
  Output_Buffer_A[1] := $00;

  SPI_Write_Read_Buffer (Output_Buffer_A, Input_Buffer_A, Length);

  Result := Input_Buffer_A [2];

  {$IF ADS1262_WAIT_TIME_MS_READ_REGISTER > 0 }
  Sleep (ADS1262_WAIT_TIME_MS_READ_REGISTER);
  {$ENDIF}
End; { T_ADS1262.Read_Register }


{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.Write_Register (F_Register_Adress : U_Int_8; F_Data : U_Int_8);
{ Write data into register                                                                }
{ --------------------------------------------------------------------------------------- }
Var
  Length :          U_Int_8;
  Output_Buffer_A : T_Buffer_A;
  Input_Buffer_A :  T_Buffer_A;

Begin { T_ADS1262.Write_Register }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Write_Register');
  {$ENDIF}

  Length := 3;
  SetLength (Output_Buffer_A, Length);
  SetLength (Input_Buffer_A, Length);

  Output_Buffer_A[0] := ADS1262_COMMAND_WREG or F_Register_Adress;
  Output_Buffer_A[1] := $00;
  Output_Buffer_A[2] := F_Data;

  SPI_Write_Read_Buffer (Output_Buffer_A, Input_Buffer_A, Length);

  {$IF ADS1262_WAIT_TIME_MS_WRITE_REGISTER > 0 }
  Sleep (ADS1262_WAIT_TIME_MS_WRITE_REGISTER);
  {$ENDIF}
End; { T_ADS1262.Write_Register }


{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.System_Offset_Self_Calibration ();
{ ADC1 self offset calibration SFOCAL1                                                    }
{ --------------------------------------------------------------------------------------- }
Var
  Old_INPMUX : U_Int_8;

Begin { T_ADS1262.System_Offset_Self_Calibration }
  {$IF DEFINED (DEBUG_ADS1262_OUTPUT) or DEFINED (DEBUG_OFFSET_SELF_CALIBRATION)}
  WriteLn ('Begin of    : T_ADS1262.System_Offset_Self_Calibration');
  {$ENDIF}

  { Save old values of INPMUX }
  Old_INPMUX := Get_INPMUX ();

  { Float all inputs }
  Set_INPMUX (ADS1262_INPMUX_MUXP_FLOAT, ADS1262_INPMUX_MUXN_FLOAT);

  {$IF ADS1262_WAIT_TIME_MS_SELF_CALIBRATION_BEFORE > 0 }
  Sleep (ADS1262_WAIT_TIME_MS_SELF_CALIBRATION_BEFORE);
  {$ENDIF}

  { ADC1 self offset calibration SFOCAL1 }
  Execute_Command (ADS1262_COMMAND_SFOCAL1);

  {$IF ADS1262_WAIT_TIME_MS_SELF_CALIBRATION_AFTER > 0 }
  Sleep (ADS1262_WAIT_TIME_MS_SELF_CALIBRATION_AFTER);
  {$ENDIF}

  { Reset inputs }
  Set_INPMUX ((Old_INPMUX and $F0), (Old_INPMUX and $0F));
End; { T_ADS1262.System_Offset_Self_Calibration }


{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.Start_Continuous_Conversion ();
{ Start continuous conversion                                                             }
{ --------------------------------------------------------------------------------------- }
Var
  Register_Value : U_Int_8;

Begin { T_ADS1262.Start_Continuous_Conversion }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Start_Continuous_Conversion');
  {$ENDIF}

  { Set continuous conversion }
  Register_Value := Read_Register (ADS1262_REGISTER_MODE0) and (ADS1262_MODE0_REFREV_MASK or ADS1262_MODE0_CHOP_MASK or ADS1262_MODE0_DELAY_MASK);  { Mask the rest of the old register bits not involved }
  Register_Value := Register_Value or ADS1262_MODE0_RUNMODE_CONTINUOUS_CONVERSION;
  Write_Register (ADS1262_REGISTER_MODE0, Register_Value);

  { Start continuous conversion }
  Execute_Command (ADS1262_COMMAND_START1);
End; { T_ADS1262.Start_Continuous_Conversion }


{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.Stop_Continuous_Conversion ();
{ Stop continuous conversion                                                              }
{ --------------------------------------------------------------------------------------- }
Begin { T_ADS1262.Stop_Continuous_Conversion }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Stop_Continuous_Conversion');
  {$ENDIF}

  { Stop continuous conversion }
  Execute_Command (ADS1262_COMMAND_STOP1);
End; { T_ADS1262.Stop_Continuous_Conversion }


{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.Set_POWER (F_VBIAS_Mode : U_Int_8; F_INTREF_Mode : U_Int_8);
{ Set POWER mode                                                                          }
{ --------------------------------------------------------------------------------------- }
Var
  Register_Value : U_Int_8;

Begin { T_ADS1262.Set_POWER }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Set_POWER');
  {$ENDIF}

  { Set VBIAS and INTREF }
  Register_Value := Read_Register (ADS1262_REGISTER_POWER) and (ADS1262_POWER_RESET_MASK);  { Mask the rest of the old register bits not involved }
  Register_Value := Register_Value or F_VBIAS_Mode or F_INTREF_Mode;
  Write_Register (ADS1262_REGISTER_POWER, Register_Value);
End; { T_ADS1262.Set_POWER }


{ --------------------------------------------------------------------------------------- }
Function T_ADS1262.Get_INPMUX () : U_Int_8;
{ Get INPMUX                                                                              }
{ --------------------------------------------------------------------------------------- }
Begin { T_ADS1262.Get_INPMUX }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Get_INPMUX');
  {$ENDIF}

  { Get INPMUX }
  Result := Read_Register (ADS1262_REGISTER_INPMUX);
End; { T_ADS1262.Get_INPMUX }


{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.Set_INPMUX (F_MUXP : U_Int_8; F_MUXN : U_Int_8);
{ Set INPMUX                                                                              }
{ --------------------------------------------------------------------------------------- }
Var
  Register_Value : U_Int_8;

Begin { T_ADS1262.Set_INPMUX }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Set_INPMUX');
  {$ENDIF}

  { Set INPMUX }
  Register_Value := F_MUXP or F_MUXN;
  Write_Register (ADS1262_REGISTER_INPMUX, Register_Value);
End; { T_ADS1262.Set_INPMUX }


{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.Set_PGA (F_Bypass_Mode : U_Int_8; F_Gain_Mode : U_Int_8);
{ Set PGA mode                                                                            }
{ --------------------------------------------------------------------------------------- }
Var
  Register_Value : U_Int_8;

Begin { T_ADS1262.Set_PGA }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Set_PGA');
  {$ENDIF}

  { Set BYPASS and GAIN }
  Register_Value := Read_Register (ADS1262_REGISTER_MODE2) and (ADS1262_MODE2_DR_MASK);  { Mask the rest of the old register bits not involved }
  Register_Value := Register_Value or F_Bypass_Mode or F_Gain_Mode;
  Write_Register (ADS1262_REGISTER_MODE2, Register_Value);
End; { T_ADS1262.Set_PGA }


{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.Set_Data_Rate (F_Rate_Mode : U_Int_8);
{ Set data rate                                                                           }
{ --------------------------------------------------------------------------------------- }
Var
  Register_Value : U_Int_8;

Begin { T_ADS1262.Set_Data_Rate }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Set_Data_Rate');
  {$ENDIF}

  { Set data rate }
  Register_Value := Read_Register (ADS1262_REGISTER_MODE2) and (ADS1262_MODE2_BYPASS_MASK or ADS1262_MODE2_BYPASS_MASK);  { Mask the rest of the old register bits not involved }
  Register_Value := Register_Value or F_Rate_Mode;
  Write_Register (ADS1262_REGISTER_MODE2, Register_Value);
End; { T_ADS1262.Set_Data_Rate }

{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.Set_Filter_Mode (F_Filter_Mode : U_Int_8);
{ Set filter mode                                                                         }
{ --------------------------------------------------------------------------------------- }
Var
  Register_Value : U_Int_8;

Begin { T_ADS1262.Set_Filter_Mode }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Set_Filter_Mode');
  {$ENDIF}

  { Set filter mode }
  Register_Value := Read_Register (ADS1262_REGISTER_MODE1) and (ADS1262_MODE1_SBADC_MASK or ADS1262_MODE1_SBPOL_MASK or ADS1262_MODE1_SBMAG_MASK);  { Mask the rest of the old register bits not involved }
  Register_Value := Register_Value or F_Filter_Mode;
  Write_Register (ADS1262_REGISTER_MODE1, Register_Value);
End; { T_ADS1262.Set_Filter_Mode }


{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.Set_Chop_Mode (F_Chop_Mode : U_Int_8);
{ Set chop mode                                                                           }
{ --------------------------------------------------------------------------------------- }
Var
  Register_Value : U_Int_8;

Begin { T_ADS1262.Set_Chop_Mode }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Set_Chop_Mode');
  {$ENDIF}

  { Set chope mode }
  Register_Value := Read_Register (ADS1262_REGISTER_MODE0) and (ADS1262_MODE0_REFREV_MASK or ADS1262_MODE0_RUNMODE_MASK or ADS1262_MODE0_DELAY_MASK);  { Mask the rest of the old register bits not involved }
  Register_Value := Register_Value or F_Chop_Mode;
  Write_Register (ADS1262_REGISTER_MODE0, Register_Value);
End; { T_ADS1262.Set_Chop_Mode }


{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.Set_OFCAL (F_OFCAL : Int_32);
{ Set offset calibration registers                                                        }
{ --------------------------------------------------------------------------------------- }
Var
  Length :          U_Int_8;
  Output_Buffer_A : T_Buffer_A;
  Input_Buffer_A :  T_Buffer_A;

Begin { T_ADS1262.Set_OFCAL }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Set_OFCAL');
  {$ENDIF}

  { Set offset calibration registers }
  Length := ADS1262_REGISTER_OFCAL_LENGTH + 2;
  SetLength (Output_Buffer_A, Length);
  SetLength (Input_Buffer_A, Length);

  Output_Buffer_A[0] := ADS1262_COMMAND_WREG or ADS1262_REGISTER_OFCAL0;
  Output_Buffer_A[1] := ADS1262_REGISTER_OFCAL_LENGTH - 1;
  Output_Buffer_A[2] := F_OFCAL and $FF;
  Output_Buffer_A[3] := (F_OFCAL shr $08) and $FF;
  Output_Buffer_A[4] := (F_OFCAL shr $10) and $FF;

  SPI_Write_Read_Buffer (Output_Buffer_A, Input_Buffer_A, Length);
End; { T_ADS1262.Set_OFCAL }


{ --------------------------------------------------------------------------------------- }
Function T_ADS1262.Read_ADC1_Data (Var F_Status : U_Int_8; Var F_CRC : U_Int_8) : Int_32;
{ Read ADC1 data                                                                          }
{ --------------------------------------------------------------------------------------- }
Var
  Length :          U_Int_8;
  Output_Buffer_A : T_Buffer_A;
  Input_Buffer_A :  T_Buffer_A;
  CRC_Calculated :  U_Int_8;
  I :               Integer;
  EMA_Factor :      Double;

Begin { T_ADS1262.Read_ADC1_Data }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Read_ADC1_Data');
  {$ENDIF}

  { Check for recalibration }
  Inc (M_Count);

  { Read ADC1 data }
  Length := 7;
  SetLength (Output_Buffer_A, Length);
  SetLength (Input_Buffer_A, Length);

  Output_Buffer_A[0] := ADS1262_COMMAND_RDATA1;
  Output_Buffer_A[1] := $00;
  Output_Buffer_A[2] := $00;
  Output_Buffer_A[3] := $00;
  Output_Buffer_A[4] := $00;
  Output_Buffer_A[5] := $00;
  Output_Buffer_A[6] := $00;

  SPI_Write_Read_Buffer (Output_Buffer_A, Input_Buffer_A, Length);

  F_Status := Input_Buffer_A [1];

  Result := (Input_Buffer_A [2] shl $18) or (Input_Buffer_A [3] shl $10) or (Input_Buffer_A [4] shl $08) or (Input_Buffer_A [5]);

  F_CRC          := Input_Buffer_A [6];
  CRC_Calculated := (Input_Buffer_A [2] + Input_Buffer_A [3] + Input_Buffer_A [4] + Input_Buffer_A [5] + ADS1262_CRC_MAGIC_BYTE) and $FF;
  If CRC_Calculated <> F_CRC Then
    Begin { then }
      WriteLn ('CRC error : ' + IntToHex (F_CRC, 2) + ' - ' + IntToHex (CRC_Calculated, 2));
    End; { then }

  EMA_Factor  := 2 / (ADS1262_EMA_SPAN + 1);
  M_Bit_N     := Round (Int (Log2 (Max (Abs (Result), 1))));
  M_EMA_Bit_N := (EMA_Factor * M_Bit_N) + ((1 - EMA_Factor) * M_EMA_Bit_N);

  {$IFDEF DEBUG_ADC1_DATA}
  WriteLn ('Count : ', IntToHex (M_Count, 8), ' - ADC1 data : ', IntToHex (Result, 8), ' - V : ', FormatFloat (' #,##0.00000000;-#,##0.00000000; #,##0.00000000', Double (Result) * 2.5 / $7FFFFFFF), ' - Bits : ', FormatFloat ('#,#00', M_Bit_N), ' - EMA Bits : ', FormatFloat ('#,##0.0', M_EMA_Bit_N), ' - Status : ', IntToHex (F_Status, 2));
  {$ENDIF}

  {$IF ADS1262_WAIT_TIME_MS_READ_ADC1 > 0 }
  Sleep (ADS1262_WAIT_TIME_MS_READ_ADC1);
  {$ENDIF}
End; { T_ADS1262.Read_ADC1_Data }


{ --------------------------------------------------------------------------------------- }
Function T_ADS1262.Read_ADC1_Data : Int_32;
{ Read ADC1 data                                                                          }
{ --------------------------------------------------------------------------------------- }
Var
  Status : U_Int_8;
  CRC :    U_Int_8;

Begin { T_ADS1262.Read_ADC1_Data }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Read_ADC1_Data');
  {$ENDIF}

  { Check for recalibration }
  Result := Read_ADC1_Data (Status, CRC);
End; { T_ADS1262.Read_ADC1_Data }


{ --------------------------------------------------------------------------------------- }
Procedure T_ADS1262.Read_All_Registers (Var F_Register_Block : T_Register_Block);
{ Read all registers into register array                                                  }
{ --------------------------------------------------------------------------------------- }
Var
  Length :          U_Int_8;
  Output_Buffer_A : T_Buffer_A;
  Input_Buffer_A :  T_Buffer_A;
  {$IF DEFINED (DEBUG_ADS1262_OUTPUT) or DEFINED (DEBUG_ADC1_DATA)}
  I :               Integer;
  S :               String;
  {$ENDIF}

Begin { T_ADS1262.Read_All_Registers }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Read_All_Registers');
  {$ENDIF}

  { Read ADC1 data }
  Length := ADS1262_REGISTER_N + 2;
  SetLength (Output_Buffer_A, Length);
  SetLength (Input_Buffer_A, Length);

  FillByte (Output_Buffer_A [0], Length, 0);
  FillByte (Input_Buffer_A [0], Length, 0);

  Output_Buffer_A[0] := ADS1262_COMMAND_RREG or ADS1262_REGISTER_ID;
  Output_Buffer_A[1] := ADS1262_REGISTER_N - 1;

  SPI_Write_Read_Buffer (Output_Buffer_A, Input_Buffer_A, Length);

  Move (Input_Buffer_A [2], F_Register_Block [0], ADS1262_REGISTER_N);

  {$IF DEFINED (DEBUG_ADS1262_OUTPUT) or DEFINED (DEBUG_ADC1_DATA)}
  S := '';
  For I := 0 To ADS1262_REGISTER_N - 1 Do
    Begin { For }
      S := S + IntToHex (F_Register_Block [I], 2) + ' ';
    End; { For }

  WriteLn ('Registerblock: ' + S);
  {$ENDIF}

  {$IF ADS1262_WAIT_TIME_MS_READ_REGISTER > 0 }
  Sleep (ADS1262_WAIT_TIME_MS_READ_REGISTER);
  {$ENDIF}
End; { T_ADS1262.Read_All_Registers }


{ --------------------------------------------------------------------------------------- }
Function T_ADS1262.Calculate_Voltage (F_Data : Int_32) : Double;
{ Calculate voltage                                                                       }
{ --------------------------------------------------------------------------------------- }
Begin { T_ADS1262.Calculate_Voltage }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Calculate_Voltage');
  {$ENDIF}

  { Calculate voltage }
  Result := F_Data * 2.5 / $7FFFFFFF;
End; { T_ADS1262.Calculate_Voltage }


{ --------------------------------------------------------------------------------------- }
Function T_ADS1262.Get_Voltage () : Double;
{ Read voltage from ADC                                                                   }
{ --------------------------------------------------------------------------------------- }
Begin { T_ADS1262.Get_Voltage }
  {$IFDEF DEBUG_ADS1262_OUTPUT}
  WriteLn ('Begin of    : T_ADS1262.Get_Voltage');
  {$ENDIF}

  { Calculate voltage }
  Result := Calculate_Voltage (Read_ADC1_Data);
End; { T_ADS1262.Get_Voltage }


End.
