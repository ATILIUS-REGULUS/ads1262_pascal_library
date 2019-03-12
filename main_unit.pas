 { ####################################################################################### }
 { ##                                                                                   ## }
 { ## Main_Unit                                                                         ## }
 { ##                                                                                   ## }
 { ## Main form for ADS1115                                                             ## }
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


Unit Main_Unit;

{$mode objfpc}{$H+}

{$INCLUDE project_defines.inc}

Interface

Uses
  CThreads,
  Classes,
  SysUtils,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  StdCtrls,
  ExtCtrls,
  TAGraph,
  TASeries,
  ADS1262_Unit,
  TACustomSeries;

Const
  DATA_INTERVAL_MS  = 2;
  CHART_INTERVAL_MS = 1000;
  CHART_STEP_SIZE   = 3;
  CHART_SIZE        = 5000;
  DATA_ARRY_SIZE    = 100000;
  CHART_START_Y     = 0;

Type
  T_Data_X_A = Array [0 .. DATA_ARRY_SIZE - 1] Of TDateTime;
  T_Data_Y_A = Array [0 .. DATA_ARRY_SIZE - 1] Of Int_32;


  { ####################################################################################### }
  { ## T_Timer_Thread                                                                    ## }
  { ####################################################################################### }
  T_Timer_Thread = Class(TThread)
  Private
      M_ADS1262 :      T_ADS1262;
      M_Data_X_A :     T_Data_X_A;
      M_Data_Y_A :     T_Data_Y_A;
      M_Data_A_Index : Integer;
      M_Count :        Integer;
  Public
      Property Data_X_A : T_Data_X_A Read M_Data_X_A;
      Property Data_Y_A : T_Data_Y_A Read M_Data_Y_A;
      Property Data_A_Index : Integer Read M_Data_A_Index;
      Property Count : Integer Read M_Count;
      Property ADS1262 : T_ADS1262 Read M_ADS1262;
      Constructor Create (F_Suspended : Boolean);
      Destructor Destroy; Override;
      Procedure Execute; Override;
  End; { T_Timer_Thread }

  { ####################################################################################### }
  { ## TMain_F                                                                           ## }
  { ####################################################################################### }
  TMain_F = Class(TForm)
      ADC_C :          TChart;
      Label4 :         TLabel;
      Output_V_E :     TEdit;
      Start_Stop_B :   TButton;
      ConstantLine :   TConstantLine;
      Chart_S :        TLineSeries;
      Close_B :        TButton;
      Label3 :         TLabel;
      Output_NPS_E :   TEdit;
      Output_EPanel1 : TPanel;
      Chart_T :        TTimer;
      Procedure Chart_TTimer (Sender : TObject);
      Procedure Close_BClick (Sender : TObject);
      Procedure FormCreate (Sender : TObject);
      Procedure FormDestroy (Sender : TObject);
      Procedure FormShow (Sender : TObject);
      Procedure Start_Stop_BClick (Sender : TObject);
  Protected
      M_Timer_Thread :   T_Timer_Thread;
      M_Data_A_Index_0 : Integer;
      M_Data_A_Index_1 : Integer;
      M_Start_Time :     TDateTime;
      M_End_Time :       TDateTime;
  Public
  End; { TMain_F }

Var
  Main_F : TMain_F;

Implementation

{$R *.frm}

Uses
  DateUtils;

 { ####################################################################################### }
 { ## T_Timer_Thread                                                                    ## }
 { ####################################################################################### }

{ --------------------------------------------------------------------------------------- }
Constructor T_Timer_Thread.Create (F_Suspended : Boolean);
{ Create timer thread                                                                     }
{ --------------------------------------------------------------------------------------- }
{$IFDEF DEBUG_ERROR}
Var
  Register_Block : T_Register_Block;
{$ENDIF}

Begin { T_Timer_Thread.Create }
  Inherited Create (F_Suspended);

  FreeOnTerminate := FALSE;

  M_ADS1262 := T_ADS1262.Create ();
  M_ADS1262.Start_Continuous_Conversion ();
  {$IFDEF DEBUG_ERROR}
  M_ADS1262.Read_All_Registers (Register_Block);
  {$ENDIF}

  FillByte (M_Data_X_A [0], DATA_ARRY_SIZE * SizeOf (TDateTime), $00);
  FillByte (M_Data_Y_A [0], DATA_ARRY_SIZE * SizeOf (Int_32), $00);

  M_Data_A_Index := 0;
  M_Count        := 0;
End; { T_Timer_Thread.Create }


{ --------------------------------------------------------------------------------------- }
Destructor T_Timer_Thread.Destroy;
{ Free data                                                                               }
{ --------------------------------------------------------------------------------------- }
Begin { T_Timer_Thread.Destroy }
  M_ADS1262.Free;

  Inherited Destroy;
End; { T_Timer_Thread.Destroy }


{ --------------------------------------------------------------------------------------- }
Procedure T_Timer_Thread.Execute;
{ Execute thread                                                                          }
{ --------------------------------------------------------------------------------------- }
Begin { T_Timer_Thread.Execute }
  While (Terminated = FALSE) Do
    Begin { While }
      Sleep (DATA_INTERVAL_MS);

      M_Data_X_A[M_Data_A_Index] := M_Count;
      M_Data_Y_A[M_Data_A_Index] := M_ADS1262.ADC1_Data;

      Inc (M_Count);
      Inc (M_Data_A_Index);
      If M_Data_A_Index >= DATA_ARRY_SIZE Then
        Begin { then }
          M_Data_A_Index := 0;
        End; { then }
    End;   { While }
End; { T_Timer_Thread.Execute }


 { ####################################################################################### }
 { ## TMain_F                                                                           ## }
 { ####################################################################################### }

{ --------------------------------------------------------------------------------------- }
Procedure TMain_F.FormCreate (Sender : TObject);
{ Create main from                                                                        }
{ --------------------------------------------------------------------------------------- }
Begin { TMain_F.FormCreate }
  Chart_S.Clear;
  ADC_C.Extent.YMax := CHART_START_Y;
  ADC_C.Extent.YMin := -CHART_START_Y;

  M_Timer_Thread := T_Timer_Thread.Create (TRUE);
End; { TMain_F.FormCreate }


{ --------------------------------------------------------------------------------------- }
Procedure TMain_F.FormDestroy (Sender : TObject);
{ Free data                                                                               }
{ --------------------------------------------------------------------------------------- }
Begin { TMain_F.FormDestroy }
  Chart_T.Enabled := FALSE;

  M_Timer_Thread.Terminate;
  Sleep (100);
  M_Timer_Thread.Free;
End; { TMain_F.FormDestroy }


{ --------------------------------------------------------------------------------------- }
Procedure TMain_F.FormShow (Sender : TObject);
{ Show main form                                                                          }
{ --------------------------------------------------------------------------------------- }
Begin { TMain_F.FormShow }
  Chart_T.Interval := CHART_INTERVAL_MS;
  Chart_T.Enabled  := TRUE;

  M_Data_A_Index_0 := 0;
  M_Data_A_Index_1 := 0;
  M_Start_Time     := Now;
  M_End_Time       := Now;

  M_Timer_Thread.Start;
End; { TMain_F.FormShow }


{ --------------------------------------------------------------------------------------- }
Procedure TMain_F.Close_BClick (Sender : TObject);
{ Close button pressed                                                                    }
{ --------------------------------------------------------------------------------------- }
Begin { TMain_F.Close_BClick }
  Close;
End; { TMain_F.Close_BClick }


{ --------------------------------------------------------------------------------------- }
Procedure TMain_F.Start_Stop_BClick (Sender : TObject);
{ Start/Stop button pressed                                                               }
{ --------------------------------------------------------------------------------------- }
Begin { TMain_F.Start_Stop_BClick }
  Chart_T.Enabled := not Chart_T.Enabled;
End; { TMain_F.Start_Stop_BClick }


{ --------------------------------------------------------------------------------------- }
Procedure TMain_F.Chart_TTimer (Sender : TObject);
{ Repaint chart                                                                           }
{ --------------------------------------------------------------------------------------- }
Var
  I :           Integer;
  Start_Index : Integer;
  End_Index :   Integer;
  Time_Value :  Integer;
  Voltage :     Double;

Begin { TMain_F.Chart_TTimer }
  Chart_S.BeginUpdate;

  M_Data_A_Index_1 := M_Timer_Thread.Data_A_Index;

  If M_Data_A_Index_1 < M_Data_A_Index_0 Then
    Begin { then }
      Start_Index := M_Data_A_Index_0;
      End_Index   := DATA_ARRY_SIZE - 1;
      I           := Start_Index;
      While I <= End_Index Do
        Begin { While }
          Time_Value := Round (M_Timer_Thread.Data_X_A [I]);
          Voltage    := M_Timer_Thread.ADS1262.Calculate_Voltage (M_Timer_Thread.Data_Y_A [I]);
          Chart_S.AddXY (Time_Value, Voltage);

          Inc (I, CHART_STEP_SIZE);
        End; { While }
      M_Data_A_Index_0 := 0;
    End; { then }

  Start_Index := M_Data_A_Index_0;
  End_Index   := M_Data_A_Index_1 - 1;
  I           := Start_Index;
  While I <= End_Index Do
    Begin { While }
      Time_Value := Round (M_Timer_Thread.Data_X_A [I]);
      Voltage    := M_Timer_Thread.ADS1262.Calculate_Voltage (M_Timer_Thread.Data_Y_A [I]);
      Chart_S.AddXY (Time_Value, Voltage);

      Inc (I, CHART_STEP_SIZE);
    End; { While }

  M_End_Time        := Now;
  Output_NPS_E.Text := FormatFloat ('#.##0.000', Double (M_Data_A_Index_1 - M_Data_A_Index_0) / (Double (MilliSecondSpan (M_Start_Time, M_End_Time)) / 1000));
  Output_V_E.Text   := FormatFloat ('#.##0.000', M_Timer_Thread.ADS1262.EMA_Bit_N);

  ADC_C.Extent.XMin := M_Timer_Thread.Count - CHART_SIZE;
  ADC_C.Extent.XMax := M_Timer_Thread.Count;
  Chart_S.EndUpdate;

  M_Data_A_Index_0 := M_Data_A_Index_1;
  M_Start_Time     := M_End_Time;

  Application.ProcessMessages;
End; { TMain_F.Chart_TTimer }


End.
