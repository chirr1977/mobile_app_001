object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Парсер tabletki.ua v1.0'
  ClientHeight = 700
  ClientWidth = 1200
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  WindowState = wsMaximized
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1200
    Height = 120
    Align = alTop
    TabOrder = 0
    
    object gbSearch: TGroupBox
      Left = 8
      Top = 8
      Width = 400
      Height = 104
      Caption = 'Пошук товарів'
      TabOrder = 0
      
      object lblProduct: TLabel
        Left = 8
        Top = 20
        Width = 65
        Height = 13
        Caption = 'Назва товару:'
      end
      
      object lblCity: TLabel
        Left = 200
        Top = 20
        Width = 33
        Height = 13
        Caption = 'Місто:'
      end
      
      object edtProduct: TEdit
        Left = 8
        Top = 36
        Width = 180
        Height = 21
        TabOrder = 0
        Text = 'Парацетамол'
      end
      
      object cmbCity: TComboBox
        Left = 200
        Top = 36
        Width = 100
        Height = 21
        Style = csDropDownList
        TabOrder = 1
      end
      
      object btnSearch: TButton
        Left = 8
        Top = 68
        Width = 90
        Height = 25
        Action = actSearch
        TabOrder = 2
      end
      
      object btnDemo: TButton
        Left = 104
        Top = 68
        Width = 90
        Height = 25
        Action = actDemo
        TabOrder = 3
      end
      
      object btnPopular: TButton
        Left = 200
        Top = 68
        Width = 90
        Height = 25
        Action = actPopular
        TabOrder = 4
      end
      
      object btnClear: TButton
        Left = 296
        Top = 68
        Width = 90
        Height = 25
        Action = actClear
        TabOrder = 5
      end
    end
    
    object gbSettings: TGroupBox
      Left = 420
      Top = 8
      Width = 200
      Height = 104
      Caption = 'Налаштування'
      TabOrder = 1
      
      object lblDelayMin: TLabel
        Left = 8
        Top = 20
        Width = 60
        Height = 13
        Caption = 'Затримка від:'
      end
      
      object lblDelayMax: TLabel
        Left = 8
        Top = 48
        Width = 55
        Height = 13
        Caption = 'Затримка до:'
      end
      
      object lblDelayMS: TLabel
        Left = 160
        Top = 36
        Width = 13
        Height = 13
        Caption = 'мс'
      end
      
      object edtDelayMin: TEdit
        Left = 80
        Top = 16
        Width = 60
        Height = 21
        TabOrder = 0
        Text = '1000'
        OnChange = edtDelayMinChange
      end
      
      object edtDelayMax: TEdit
        Left = 80
        Top = 44
        Width = 60
        Height = 21
        TabOrder = 1
        Text = '3000'
        OnChange = edtDelayMaxChange
      end
      
      object chkAutoSave: TCheckBox
        Left = 8
        Top = 76
        Width = 120
        Height = 17
        Caption = 'Автозбереження'
        TabOrder = 2
        OnClick = chkAutoSaveClick
      end
    end
  end
  
  object pnlCenter: TPanel
    Left = 0
    Top = 120
    Width = 900
    Height = 580
    Align = alClient
    TabOrder = 1
    
    object sgResults: TStringGrid
      Left = 1
      Top = 1
      Width = 898
      Height = 578
      Align = alClient
      ColCount = 8
      FixedCols = 0
      RowCount = 1
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
      TabOrder = 0
      OnDblClick = sgResultsDblClick
      OnDrawCell = sgResultsDrawCell
    end
  end
  
  object pnlLeft: TPanel
    Left = 900
    Top = 120
    Width = 300
    Height = 580
    Align = alRight
    TabOrder = 2
    
    object gbStats: TGroupBox
      Left = 8
      Top = 8
      Width = 284
      Height = 200
      Caption = 'Статистика'
      TabOrder = 0
      
      object lblTotalRecords: TLabel
        Left = 8
        Top = 20
        Width = 84
        Height = 13
        Caption = 'Загалом записів: 0'
      end
      
      object memoStats: TMemo
        Left = 8
        Top = 40
        Width = 268
        Height = 152
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
    
    object btnSaveCSV: TButton
      Left = 8
      Top = 220
      Width = 90
      Height = 30
      Action = actSaveCSV
      TabOrder = 1
    end
    
    object btnSaveJSON: TButton
      Left = 104
      Top = 220
      Width = 90
      Height = 30
      Action = actSaveJSON
      TabOrder = 2
    end
    
    object btnAnalyze: TButton
      Left = 200
      Top = 220
      Width = 90
      Height = 30
      Action = actAnalyze
      TabOrder = 3
    end
    
    object memoLog: TMemo
      Left = 8
      Top = 260
      Width = 284
      Height = 312
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 4
    end
  end
  
  object pnlBottom: TPanel
    Left = 0
    Top = 700
    Width = 1200
    Height = 0
    Align = alBottom
    TabOrder = 3
    Visible = False
    
    object pbProgress: TProgressBar
      Left = 1
      Top = 1
      Width = 1198
      Height = 17
      Align = alClient
      TabOrder = 0
    end
    
    object lblStatus: TLabel
      Left = 8
      Top = 24
      Width = 56
      Height = 13
      Caption = 'Готово до роботи'
    end
  end
  
  object MainMenu: TMainMenu
    object miFile: TMenuItem
      Caption = 'Файл'
      object miFileExportCSV: TMenuItem
        Action = actSaveCSV
      end
      object miFileExportJSON: TMenuItem
        Action = actSaveJSON
      end
      object miFileSeparator1: TMenuItem
        Caption = '-'
      end
      object miFileExit: TMenuItem
        Action = actExit
      end
    end
    object miEdit: TMenuItem
      Caption = 'Правка'
      object miEditClear: TMenuItem
        Action = actClear
      end
    end
    object miView: TMenuItem
      Caption = 'Перегляд'
      object miViewDemo: TMenuItem
        Action = actDemo
      end
      object miViewPopular: TMenuItem
        Action = actPopular
      end
    end
    object miHelp: TMenuItem
      Caption = 'Довідка'
      object miHelpAbout: TMenuItem
        Action = actAbout
      end
    end
  end
  
  object SaveDialog: TSaveDialog
    DefaultExt = 'csv'
    Filter = 'CSV файли (*.csv)|*.csv|JSON файли (*.json)|*.json|Всі файли (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
  end
  
  object tmrUpdate: TTimer
    Interval = 500
    OnTimer = tmrUpdateTimer
  end
  
  object ActionList: TActionList
    object actSearch: TAction
      Caption = 'Пошук товару'
      Hint = 'Пошук товару на сайті'
      OnExecute = actSearchExecute
    end
    object actDemo: TAction
      Caption = 'Демо дані'
      Hint = 'Завантажити демонстраційні дані'
      OnExecute = actDemoExecute
    end
    object actPopular: TAction
      Caption = 'Популярні'
      Hint = 'Отримати популярні товари'
      OnExecute = actPopularExecute
    end
    object actClear: TAction
      Caption = 'Очистити'
      Hint = 'Очистити всі дані'
      OnExecute = actClearExecute
    end
    object actSaveCSV: TAction
      Caption = 'Зберегти CSV'
      Hint = 'Зберегти дані у CSV файл'
      OnExecute = actSaveCSVExecute
    end
    object actSaveJSON: TAction
      Caption = 'Зберегти JSON'
      Hint = 'Зберегти дані у JSON файл'
      OnExecute = actSaveJSONExecute
    end
    object actAnalyze: TAction
      Caption = 'Аналіз цін'
      Hint = 'Проаналізувати ціни на товар'
      OnExecute = actAnalyzeExecute
    end
    object actExit: TAction
      Caption = 'Вихід'
      Hint = 'Закрити програму'
      OnExecute = actExitExecute
    end
    object actAbout: TAction
      Caption = 'Про програму'
      Hint = 'Інформація про програму'
      OnExecute = actAboutExecute
    end
  end
end