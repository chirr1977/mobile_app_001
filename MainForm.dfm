object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Modern ToolBar Demo - '#1057#1091#1095#1072#1089#1085#1072' '#1087#1072#1085#1077#1083#1100' '#1110#1085#1089#1090#1088#1091#1084#1077#1085#1090#1110#1074' '#1076#1083#1103' Delphi'
  ClientHeight = 720
  ClientWidth = 1280
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poScreenCenter
  WindowState = wsMaximized
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 1280
    Height = 720
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object Splitter1: TSplitter
      Left = 980
      Top = 50
      Width = 4
      Height = 645
      Align = alRight
      ExplicitLeft = 976
      ExplicitTop = 46
      ExplicitHeight = 649
    end
    object pnlToolbar: TPanel
      Left = 0
      Top = 0
      Width = 1280
      Height = 50
      Align = alTop
      BevelOuter = bvLowered
      TabOrder = 0
    end
    object pnlContent: TPanel
      Left = 0
      Top = 50
      Width = 980
      Height = 645
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      object pnlDemo: TPanel
        Left = 0
        Top = 0
        Width = 980
        Height = 645
        Align = alClient
        BevelOuter = bvLowered
        TabOrder = 0
        object lblDemo: TLabel
          Left = 8
          Top = 8
          Width = 200
          Height = 16
          Caption = #1044#1077#1084#1086#1085#1089#1090#1088#1072#1094#1110#1081#1085#1072' '#1086#1073#1083#1072#1089#1090#1100':'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object memoDemo: TMemo
          Left = 8
          Top = 30
          Width = 964
          Height = 607
          Anchors = [akLeft, akTop, akRight, akBottom]
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
    end
    object pnlSettings: TPanel
      Left = 984
      Top = 50
      Width = 296
      Height = 645
      Align = alRight
      BevelOuter = bvLowered
      TabOrder = 2
      object grpIconSet: TGroupBox
        Left = 8
        Top = 8
        Width = 280
        Height = 65
        Caption = #1053#1072#1073#1110#1088' '#1110#1082#1086#1085#1086#1082
        TabOrder = 0
        object cmbIconSet: TComboBox
          Left = 8
          Top = 24
          Width = 264
          Height = 21
          Style = csDropDownList
          TabOrder = 0
          OnChange = cmbIconSetChange
        end
      end
      object grpTheme: TGroupBox
        Left = 8
        Top = 79
        Width = 280
        Height = 89
        Caption = #1058#1077#1084#1072
        TabOrder = 1
        object rbLightTheme: TRadioButton
          Left = 8
          Top = 20
          Width = 113
          Height = 17
          Caption = #1057#1074#1110#1090#1083#1072' '#1090#1077#1084#1072
          TabOrder = 0
          OnClick = rbThemeClick
        end
        object rbDarkTheme: TRadioButton
          Left = 8
          Top = 43
          Width = 113
          Height = 17
          Caption = #1058#1077#1084#1085#1072' '#1090#1077#1084#1072
          TabOrder = 1
          OnClick = rbThemeClick
        end
        object rbAutoTheme: TRadioButton
          Left = 8
          Top = 66
          Width = 113
          Height = 17
          Caption = #1040#1074#1090#1086#1084#1072#1090#1080#1095#1085#1086
          Checked = True
          TabOrder = 2
          TabStop = True
          OnClick = rbThemeClick
        end
      end
      object grpIconSize: TGroupBox
        Left = 8
        Top = 174
        Width = 280
        Height = 65
        Caption = #1056#1086#1079#1084#1110#1088' '#1110#1082#1086#1085#1086#1082
        TabOrder = 2
        object cmbIconSize: TComboBox
          Left = 8
          Top = 24
          Width = 264
          Height = 21
          Style = csDropDownList
          TabOrder = 0
          OnChange = cmbIconSizeChange
        end
      end
      object grpFeatures: TGroupBox
        Left = 8
        Top = 245
        Width = 280
        Height = 137
        Caption = #1054#1089#1086#1073#1083#1080#1074#1086#1089#1090#1110
        TabOrder = 3
        object chkHighDPI: TCheckBox
          Left = 8
          Top = 20
          Width = 150
          Height = 17
          Caption = 'High DPI '#1087#1110#1076#1090#1088#1080#1084#1082#1072
          Checked = True
          State = cbChecked
          TabOrder = 0
          OnClick = chkFeatureClick
        end
        object chkSmoothIcons: TCheckBox
          Left = 8
          Top = 43
          Width = 150
          Height = 17
          Caption = #1047#1075#1083#1072#1076#1078#1091#1074#1072#1085#1085#1103' '#1110#1082#1086#1085#1086#1082
          Checked = True
          State = cbChecked
          TabOrder = 1
          OnClick = chkFeatureClick
        end
        object chkHoverEffect: TCheckBox
          Left = 8
          Top = 66
          Width = 150
          Height = 17
          Caption = #1045#1092#1077#1082#1090' '#1085#1072#1074#1077#1076#1077#1085#1085#1103
          Checked = True
          State = cbChecked
          TabOrder = 2
          OnClick = chkFeatureClick
        end
        object chkAnimateButtons: TCheckBox
          Left = 8
          Top = 89
          Width = 150
          Height = 17
          Caption = #1040#1085#1110#1084#1072#1094#1110#1103' '#1082#1085#1086#1087#1086#1082
          TabOrder = 3
          OnClick = chkFeatureClick
        end
        object chkShowCaptions: TCheckBox
          Left = 8
          Top = 112
          Width = 150
          Height = 17
          Caption = #1055#1086#1082#1072#1079#1091#1074#1072#1090#1080' '#1087#1110#1076#1087#1080#1089#1080
          Checked = True
          State = cbChecked
          TabOrder = 4
          OnClick = chkFeatureClick
        end
      end
      object grpIconBrowser: TGroupBox
        Left = 8
        Top = 388
        Width = 280
        Height = 165
        Caption = #1041#1088#1072#1091#1079#1077#1088' '#1110#1082#1086#1085#1086#1082
        TabOrder = 4
        object edtSearch: TEdit
          Left = 8
          Top = 20
          Width = 200
          Height = 21
          TabOrder = 0
          OnChange = edtSearchChange
        end
        object btnSearch: TButton
          Left = 214
          Top = 18
          Width = 58
          Height = 25
          Caption = #1055#1086#1096#1091#1082
          TabOrder = 1
          OnClick = btnSearchClick
        end
        object cmbCategory: TComboBox
          Left = 8
          Top = 47
          Width = 264
          Height = 21
          Style = csDropDownList
          TabOrder = 2
          OnChange = cmbCategoryChange
        end
        object lstIcons: TListBox
          Left = 8
          Top = 74
          Width = 135
          Height = 83
          TabOrder = 3
          OnClick = lstIconsClick
        end
        object pnlIconPreview: TPanel
          Left = 149
          Top = 74
          Width = 123
          Height = 83
          BevelOuter = bvLowered
          TabOrder = 4
          object imgIconPreview: TImage
            Left = 8
            Top = 8
            Width = 48
            Height = 48
            Center = True
            Proportional = True
            Stretch = True
          end
          object lblIconName: TLabel
            Left = 8
            Top = 62
            Width = 107
            Height = 13
            Caption = 'Icon Name'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object lblIconDescription: TLabel
            Left = 8
            Top = 75
            Width = 107
            Height = 13
            Caption = 'Description'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGray
            Font.Height = -9
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentFont = False
          end
        end
      end
      object grpDPIInfo: TGroupBox
        Left = 8
        Top = 559
        Width = 280
        Height = 78
        Caption = 'DPI '#1110#1085#1092#1086#1088#1084#1072#1094#1110#1103
        TabOrder = 5
        object vleDPIInfo: TValueListEditor
          Left = 8
          Top = 20
          Width = 200
          Height = 50
          KeyOptions = [keyEdit, keyAdd, keyDelete, keyUnique]
          TabOrder = 0
          ColWidths = (
            100
            96)
        end
        object btnRefreshDPI: TButton
          Left = 214
          Top = 20
          Width = 58
          Height = 50
          Caption = #1054#1085#1086#1074#1080#1090#1080
          TabOrder = 1
          OnClick = btnRefreshDPIClick
        end
      end
    end
    object pnlStatus: TPanel
      Left = 0
      Top = 695
      Width = 1280
      Height = 25
      Align = alBottom
      BevelOuter = bvLowered
      TabOrder = 3
      object lblStatus: TLabel
        Left = 8
        Top = 6
        Width = 86
        Height = 13
        Caption = #1043#1086#1090#1086#1074#1086' '#1076#1086' '#1088#1086#1073#1086#1090#1080'...'
      end
    end
  end
  object MainMenu1: TMainMenu
    Left = 48
    Top = 64
    object mnuFile: TMenuItem
      Caption = #1060#1072#1081#1083
      object mnuNew: TMenuItem
        Caption = #1053#1086#1074#1080#1081
        ShortCut = 16462
        OnClick = mnuNewClick
      end
      object mnuOpen: TMenuItem
        Caption = #1042#1110#1076#1082#1088#1080#1090#1080'...'
        ShortCut = 16463
        OnClick = mnuOpenClick
      end
      object mnuSave: TMenuItem
        Caption = #1047#1073#1077#1088#1077#1075#1090#1080
        ShortCut = 16467
        OnClick = mnuSaveClick
      end
      object mnuSaveAs: TMenuItem
        Caption = #1047#1073#1077#1088#1077#1075#1090#1080' '#1103#1082'...'
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object mnuExit: TMenuItem
        Caption = #1042#1080#1093#1110#1076
        OnClick = mnuExitClick
      end
    end
    object mnuEdit: TMenuItem
      Caption = #1056#1077#1076#1072#1075#1091#1074#1072#1085#1085#1103
      object mnuCut: TMenuItem
        Caption = #1042#1080#1088#1110#1079#1072#1090#1080
        ShortCut = 16472
        OnClick = mnuCutClick
      end
      object mnuCopy: TMenuItem
        Caption = #1050#1086#1087#1110#1102#1074#1072#1090#1080
        ShortCut = 16451
        OnClick = mnuCopyClick
      end
      object mnuPaste: TMenuItem
        Caption = #1042#1089#1090#1072#1074#1080#1090#1080
        ShortCut = 16470
        OnClick = mnuPasteClick
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object mnuSelectAll: TMenuItem
        Caption = #1042#1080#1076#1110#1083#1080#1090#1080' '#1074#1089#1077
        ShortCut = 16449
      end
    end
    object mnuView: TMenuItem
      Caption = #1042#1080#1075#1083#1103#1076
      object mnuToolbar: TMenuItem
        Caption = #1055#1072#1085#1077#1083#1100' '#1110#1085#1089#1090#1088#1091#1084#1077#1085#1090#1110#1074
        Checked = True
      end
      object mnuStatusBar: TMenuItem
        Caption = #1056#1103#1076#1086#1082' '#1089#1090#1072#1090#1091#1089#1091
        Checked = True
      end
    end
    object mnuHelp: TMenuItem
      Caption = #1044#1086#1074#1110#1076#1082#1072
      object mnuAbout: TMenuItem
        Caption = #1055#1088#1086' '#1087#1088#1086#1075#1088#1072#1084#1091'...'
        OnClick = mnuAboutClick
      end
    end
  end
end