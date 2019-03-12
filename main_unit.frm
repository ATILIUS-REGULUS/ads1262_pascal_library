object Main_F: TMain_F
  Left = 879
  Height = 773
  Top = 218
  Width = 1016
  Caption = 'ads1262_project'
  ClientHeight = 773
  ClientWidth = 1016
  DesignTimePPI = 137
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  Position = poDesktopCenter
  LCLVersion = '6.3'
  object ADC_C: TChart
    Left = 0
    Height = 716
    Top = 0
    Width = 1016
    AxisList = <    
      item
        Minors = <>
        Title.LabelFont.Orientation = 900
      end    
      item
        Alignment = calBottom
        AtDataOnly = True
        Minors = <>
      end>
    Extent.UseXMax = True
    Extent.UseXMin = True
    Extent.XMax = 10
    Extent.YMax = 100
    Extent.YMin = -100
    Foot.Brush.Color = clBtnFace
    Foot.Font.Color = clBlue
    Title.Brush.Color = clBtnFace
    Title.Font.Color = clBlue
    Title.Text.Strings = (
      'TAChart'
    )
    Align = alClient
    DoubleBuffered = True
    Enabled = False
    object Chart_S: TLineSeries
      Marks.Visible = False
      LinePen.Color = clRed
    end
    object ConstantLine: TConstantLine
      Pen.Color = clNavy
      Pen.Width = 3
      Position = 0
    end
  end
  object Output_EPanel1: TPanel
    Left = 0
    Height = 57
    Top = 716
    Width = 1016
    Align = alBottom
    ChildSizing.EnlargeHorizontal = crsHomogenousSpaceResize
    ChildSizing.EnlargeVertical = crsHomogenousSpaceResize
    ChildSizing.Layout = cclLeftToRightThenTopToBottom
    ChildSizing.ControlsPerLine = 7
    ClientHeight = 57
    ClientWidth = 1016
    ParentFont = False
    TabOrder = 0
    object Close_B: TButton
      Left = 16
      Height = 32
      Top = 13
      Width = 56
      Cancel = True
      Caption = 'Close'
      OnClick = Close_BClick
      ParentFont = False
      TabOrder = 1
    end
    object Label3: TLabel
      Left = 88
      Height = 32
      Top = 13
      Width = 271
      Alignment = taRightJustify
      Caption = 'Number of measurements/second'
      Layout = tlCenter
      ParentColor = False
      ParentFont = False
    end
    object Output_NPS_E: TEdit
      Left = 375
      Height = 32
      Top = 13
      Width = 228
      Constraints.MinWidth = 228
      ParentFont = False
      TabOrder = 2
    end
    object Start_Stop_B: TButton
      Left = 619
      Height = 32
      Top = 13
      Width = 94
      Caption = 'Start/Stop'
      OnClick = Start_Stop_BClick
      ParentFont = False
      TabOrder = 0
    end
    object Label4: TLabel
      Left = 729
      Height = 32
      Top = 13
      Width = 30
      Alignment = taRightJustify
      Caption = 'Bits'
      Layout = tlCenter
      ParentColor = False
      ParentFont = False
    end
    object Output_V_E: TEdit
      Left = 775
      Height = 32
      Top = 13
      Width = 228
      Constraints.MinWidth = 228
      ParentFont = False
      TabOrder = 3
    end
  end
  object Chart_T: TTimer
    Enabled = False
    OnTimer = Chart_TTimer
    Left = 91
    Top = 80
  end
end
