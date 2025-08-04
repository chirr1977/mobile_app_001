unit MainForm;

{
  Головна форма парсера tabletki.ua
  GUI інтерфейс для керування парсингом
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, 
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.ComCtrls, Vcl.Buttons,
  Vcl.Menus, Vcl.ImgList, System.ImageList, System.Actions, Vcl.ActnList,
  TabletkiParser, System.Threading, Vcl.ToolWin;

type
  TfrmMain = class(TForm)
    // Панелі
    pnlTop: TPanel;
    pnlCenter: TPanel;
    pnlBottom: TPanel;
    pnlLeft: TPanel;
    pnlProgress: TPanel;
    
    // Елементи управління пошуком
    gbSearch: TGroupBox;
    lblProduct: TLabel;
    edtProduct: TEdit;
    lblCity: TLabel;
    cmbCity: TComboBox;
    btnSearch: TButton;
    btnDemo: TButton;
    btnPopular: TButton;
    btnClear: TButton;
    
    // Елементи налаштувань
    gbSettings: TGroupBox;
    lblDelayMin: TLabel;
    edtDelayMin: TEdit;
    lblDelayMax: TLabel;
    edtDelayMax: TEdit;
    lblDelayMS: TLabel;
    chkAutoSave: TCheckBox;
    
    // Грід для відображення результатів
    sgResults: TStringGrid;
    
    // Панель прогресу та логів
    pbProgress: TProgressBar;
    lblStatus: TLabel;
    memoLog: TMemo;
    
    // Кнопки експорту
    btnSaveCSV: TButton;
    btnSaveJSON: TButton;
    btnAnalyze: TButton;
    
    // Статистика
    gbStats: TGroupBox;
    lblTotalRecords: TLabel;
    lblPharmacies: TLabel;
    lblProducts: TLabel;
    memoStats: TMemo;
    
    // Меню
    MainMenu: TMainMenu;
    miFile: TMenuItem;
    miFileExit: TMenuItem;
    miFileSeparator1: TMenuItem;
    miFileExportCSV: TMenuItem;
    miFileExportJSON: TMenuItem;
    miHelp: TMenuItem;
    miHelpAbout: TMenuItem;
    miEdit: TMenuItem;
    miEditClear: TMenuItem;
    miEditSelectAll: TMenuItem;
    miView: TMenuItem;
    miViewDemo: TMenuItem;
    miViewPopular: TMenuItem;
    
    // Діалоги
    SaveDialog: TSaveDialog;
    
    // Таймер для автооновлення інтерфейсу
    tmrUpdate: TTimer;
    
    // Дії
    ActionList: TActionList;
    actSearch: TAction;
    actDemo: TAction;
    actPopular: TAction;
    actClear: TAction;
    actSaveCSV: TAction;
    actSaveJSON: TAction;
    actAnalyze: TAction;
    actExit: TAction;
    actAbout: TAction;
    
    // Зображення
    ImageList: TImageList;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    
    // Обробники подій пошуку
    procedure actSearchExecute(Sender: TObject);
    procedure actDemoExecute(Sender: TObject);
    procedure actPopularExecute(Sender: TObject);
    procedure actClearExecute(Sender: TObject);
    
    // Обробники експорту
    procedure actSaveCSVExecute(Sender: TObject);
    procedure actSaveJSONExecute(Sender: TObject);
    procedure actAnalyzeExecute(Sender: TObject);
    
    // Обробники меню
    procedure actExitExecute(Sender: TObject);
    procedure actAboutExecute(Sender: TObject);
    
    // Обробники налаштувань
    procedure edtDelayMinChange(Sender: TObject);
    procedure edtDelayMaxChange(Sender: TObject);
    procedure chkAutoSaveClick(Sender: TObject);
    
    // Обробники гріда
    procedure sgResultsDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure sgResultsDblClick(Sender: TObject);
    
    // Обробники таймера
    procedure tmrUpdateTimer(Sender: TObject);
    
  private
    FParser: TTabletkiParser;
    FCurrentTask: ITask;
    FIsSearching: Boolean;
    FTotalFound: Integer;
    
    // Методи роботи з парсером
    procedure InitializeParser;
    procedure OnParserProgress(const Message: string; Progress: Integer);
    procedure OnParserDataFound(const Data: TPharmacyData);
    
    // Методи інтерфейсу
    procedure UpdateUI;
    procedure UpdateGrid;
    procedure UpdateStatistics;
    procedure EnableControls(Enabled: Boolean);
    procedure AddLogMessage(const Message: string);
    procedure SetStatus(const Status: string);
    
    // Методи валідації
    function ValidateInput: Boolean;
    function GetSelectedCity: string;
    
    // Методи роботи з даними
    procedure LoadDemoData;
    procedure SearchProducts(const ProductName, City: string);
    procedure GetPopularProducts;
    
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  System.UITypes, Vcl.Clipbrd, DateUtils, StrUtils;

{$R *.dfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Ініціалізація форми
  Caption := 'Парсер tabletki.ua v1.0';
  
  // Ініціалізація змінних
  FIsSearching := False;
  FTotalFound := 0;
  
  // Налаштування інтерфейсу
  sgResults.ColCount := 8;
  sgResults.RowCount := 1;
  sgResults.FixedRows := 1;
  
  // Заголовки колонок
  sgResults.Cells[0, 0] := 'Аптека';
  sgResults.Cells[1, 0] := 'Адреса';
  sgResults.Cells[2, 0] := 'Товар';
  sgResults.Cells[3, 0] := 'Ціна';
  sgResults.Cells[4, 0] := 'Наявність';
  sgResults.Cells[5, 0] := 'Телефон';
  sgResults.Cells[6, 0] := 'Місто';
  sgResults.Cells[7, 0] := 'URL';
  
  // Ширина колонок
  sgResults.ColWidths[0] := 150;  // Аптека
  sgResults.ColWidths[1] := 200;  // Адреса
  sgResults.ColWidths[2] := 250;  // Товар
  sgResults.ColWidths[3] := 80;   // Ціна
  sgResults.ColWidths[4] := 100;  // Наявність
  sgResults.ColWidths[5] := 120;  // Телефон
  sgResults.ColWidths[6] := 80;   // Місто
  sgResults.ColWidths[7] := 200;  // URL
  
  // Налаштування міст
  cmbCity.Items.Clear;
  cmbCity.Items.Add('Київ');
  cmbCity.Items.Add('Харків');
  cmbCity.Items.Add('Одеса');
  cmbCity.Items.Add('Дніпро');
  cmbCity.Items.Add('Львів');
  cmbCity.Items.Add('Запоріжжя');
  cmbCity.Items.Add('Кривий Ріг');
  cmbCity.Items.Add('Миколаїв');
  cmbCity.Items.Add('Маріуполь');
  cmbCity.Items.Add('Вінниця');
  cmbCity.ItemIndex := 0;  // Київ за замовчуванням
  
  // Налаштування затримок
  edtDelayMin.Text := '1000';
  edtDelayMax.Text := '3000';
  
  // Ініціалізація парсера
  InitializeParser;
  
  // Початковий стан інтерфейсу
  UpdateUI;
  SetStatus('Готово до роботи');
  AddLogMessage('Програма запущена');
  
  // Запуск таймера оновлення
  tmrUpdate.Enabled := True;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  tmrUpdate.Enabled := False;
  
  // Зупинка поточного завдання
  if Assigned(FCurrentTask) then
  begin
    FCurrentTask.Cancel;
    FCurrentTask := nil;
  end;
  
  // Звільнення парсера
  if Assigned(FParser) then
    FParser.Free;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // Підтвердження закриття якщо йде пошук
  if FIsSearching then
  begin
    if MessageDlg('Йде пошук даних. Все одно закрити програму?', 
                  mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    begin
      Action := caNone;
      Exit;
    end;
  end;
  
  Action := caFree;
end;

procedure TfrmMain.InitializeParser;
begin
  FParser := TTabletkiParser.Create;
  FParser.OnProgress := OnParserProgress;
  FParser.OnDataFound := OnParserDataFound;
  
  // Застосування налаштувань
  FParser.DelayMin := StrToIntDef(edtDelayMin.Text, 1000);
  FParser.DelayMax := StrToIntDef(edtDelayMax.Text, 3000);
end;

procedure TfrmMain.OnParserProgress(const Message: string; Progress: Integer);
begin
  // Оновлення інтерфейсу з основного потоку
  TThread.Synchronize(nil, 
    procedure
    begin
      SetStatus(Message);
      AddLogMessage(Message);
      
      if Progress > 0 then
        pbProgress.Position := Progress;
        
      Application.ProcessMessages;
    end);
end;

procedure TfrmMain.OnParserDataFound(const Data: TPharmacyData);
begin
  // Додавання нових даних в грід
  TThread.Synchronize(nil, 
    procedure
    begin
      Inc(FTotalFound);
      
      // Додавання рядка в грід
      sgResults.RowCount := sgResults.RowCount + 1;
      
      with sgResults do
      begin
        Cells[0, RowCount - 1] := Data.PharmacyName;
        Cells[1, RowCount - 1] := Data.Address;
        Cells[2, RowCount - 1] := Data.ProductName;
        Cells[3, RowCount - 1] := Data.Price;
        Cells[4, RowCount - 1] := Data.Availability;
        Cells[5, RowCount - 1] := Data.Phone;
        Cells[6, RowCount - 1] := Data.City;
        Cells[7, RowCount - 1] := Data.URL;
      end;
      
      UpdateStatistics;
      
      // Автозбереження якщо увімкнено
      if chkAutoSave.Checked and (FTotalFound mod 10 = 0) then
      begin
        FParser.SaveToCSV(Format('auto_save_%s.csv', [FormatDateTime('yyyymmdd_hhnnss', Now)]));
      end;
    end);
end;

procedure TfrmMain.actSearchExecute(Sender: TObject);
begin
  if FIsSearching then
  begin
    // Зупинка пошуку
    if Assigned(FCurrentTask) then
    begin
      FCurrentTask.Cancel;
      FCurrentTask := nil;
    end;
    FIsSearching := False;
    UpdateUI;
    SetStatus('Пошук зупинено');
    Exit;
  end;
  
  if not ValidateInput then
    Exit;
    
  // Очищення попередніх результатів
  actClear.Execute;
  
  // Запуск пошуку в окремому потоці
  SearchProducts(Trim(edtProduct.Text), GetSelectedCity);
end;

procedure TfrmMain.actDemoExecute(Sender: TObject);
begin
  if FIsSearching then
  begin
    ShowMessage('Зупиніть поточний пошук перед запуском демо');
    Exit;
  end;
  
  LoadDemoData;
end;

procedure TfrmMain.actPopularExecute(Sender: TObject);
begin
  if FIsSearching then
  begin
    ShowMessage('Зупиніть поточний пошук перед отриманням популярних товарів');
    Exit;
  end;
  
  GetPopularProducts;
end;

procedure TfrmMain.actClearExecute(Sender: TObject);
begin
  sgResults.RowCount := 1;
  FTotalFound := 0;
  FParser.ClearData;
  memoLog.Clear;
  UpdateStatistics;
  SetStatus('Дані очищено');
end;

procedure TfrmMain.actSaveCSVExecute(Sender: TObject);
begin
  if FParser.GetDataCount = 0 then
  begin
    ShowMessage('Немає даних для збереження');
    Exit;
  end;
  
  SaveDialog.Filter := 'CSV файли (*.csv)|*.csv|Всі файли (*.*)|*.*';
  SaveDialog.DefaultExt := 'csv';
  SaveDialog.FileName := Format('tabletki_data_%s.csv', [FormatDateTime('yyyymmdd_hhnnss', Now)]);
  
  if SaveDialog.Execute then
  begin
    if FParser.SaveToCSV(SaveDialog.FileName) then
      ShowMessage(Format('Дані збережено у файл:%s%s', [sLineBreak, SaveDialog.FileName]))
    else
      ShowMessage('Помилка збереження файлу');
  end;
end;

procedure TfrmMain.actSaveJSONExecute(Sender: TObject);
begin
  if FParser.GetDataCount = 0 then
  begin
    ShowMessage('Немає даних для збереження');
    Exit;
  end;
  
  SaveDialog.Filter := 'JSON файли (*.json)|*.json|Всі файли (*.*)|*.*';
  SaveDialog.DefaultExt := 'json';
  SaveDialog.FileName := Format('tabletki_data_%s.json', [FormatDateTime('yyyymmdd_hhnnss', Now)]);
  
  if SaveDialog.Execute then
  begin
    if FParser.SaveToJSON(SaveDialog.FileName) then
      ShowMessage(Format('Дані збережено у файл:%s%s', [sLineBreak, SaveDialog.FileName]))
    else
      ShowMessage('Помилка збереження файлу');
  end;
end;

procedure TfrmMain.actAnalyzeExecute(Sender: TObject);
var
  ProductName: string;
  Analysis: string;
begin
  if FParser.GetDataCount = 0 then
  begin
    ShowMessage('Немає даних для аналізу');
    Exit;
  end;
  
  ProductName := Trim(edtProduct.Text);
  if ProductName = '' then
  begin
    if InputQuery('Аналіз цін', 'Введіть назву товару для аналізу:', ProductName) then
    begin
      if ProductName = '' then
      begin
        ShowMessage('Назва товару не може бути порожньою');
        Exit;
      end;
    end
    else
      Exit;
  end;
  
  Analysis := FParser.AnalyzePrices(ProductName);
  
  if Analysis <> '' then
    ShowMessage(Analysis)
  else
    ShowMessage('Не знайдено даних для аналізу');
end;

procedure TfrmMain.actExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.actAboutExecute(Sender: TObject);
begin
  ShowMessage('Парсер tabletki.ua v1.0' + sLineBreak + sLineBreak +
              'Програма для збору даних про ліки та аптеки з сайту tabletki.ua' + sLineBreak +
              'Збирає інформацію: назва аптеки, адреса, товар, ціна' + sLineBreak + sLineBreak +
              'Експорт даних: CSV, JSON' + sLineBreak +
              'Аналіз цін: мін/макс/середня' + sLineBreak + sLineBreak +
              'Розроблено на Delphi' + sLineBreak +
              '© 2025');
end;

procedure TfrmMain.edtDelayMinChange(Sender: TObject);
begin
  if Assigned(FParser) then
    FParser.DelayMin := StrToIntDef(edtDelayMin.Text, 1000);
end;

procedure TfrmMain.edtDelayMaxChange(Sender: TObject);
begin
  if Assigned(FParser) then
    FParser.DelayMax := StrToIntDef(edtDelayMax.Text, 3000);
end;

procedure TfrmMain.chkAutoSaveClick(Sender: TObject);
begin
  if chkAutoSave.Checked then
    AddLogMessage('Автозбереження увімкнено (кожні 10 записів)')
  else
    AddLogMessage('Автозбереження вимкнено');
end;

procedure TfrmMain.sgResultsDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
begin
  // Альтернативне забарвлення рядків
  if (ARow > 0) and not (gdSelected in State) then
  begin
    if ARow mod 2 = 0 then
      sgResults.Canvas.Brush.Color := clWindow
    else
      sgResults.Canvas.Canvas.Brush.Color := RGB(248, 248, 255);
      
    sgResults.Canvas.FillRect(Rect);
  end;
  
  // Стандартне відображення тексту
  sgResults.Canvas.TextRect(Rect, Rect.Left + 2, Rect.Top + 2, sgResults.Cells[ACol, ARow]);
end;

procedure TfrmMain.sgResultsDblClick(Sender: TObject);
var
  URL: string;
begin
  if (sgResults.Row > 0) and (sgResults.Row < sgResults.RowCount) then
  begin
    URL := sgResults.Cells[7, sgResults.Row];  // Колонка URL
    if URL <> '' then
    begin
      // Копіювання URL в буфер обміну
      Clipboard.AsText := URL;
      ShowMessage('URL скопійовано в буфер обміну:' + sLineBreak + URL);
    end;
  end;
end;

procedure TfrmMain.tmrUpdateTimer(Sender: TObject);
begin
  UpdateUI;
end;

procedure TfrmMain.UpdateUI;
begin
  // Оновлення стану кнопок
  actSearch.Caption := IfThen(FIsSearching, 'Зупинити пошук', 'Пошук товару');
  actSearch.ImageIndex := IfThen(FIsSearching, 1, 0);
  
  actDemo.Enabled := not FIsSearching;
  actPopular.Enabled := not FIsSearching;
  actClear.Enabled := not FIsSearching;
  
  actSaveCSV.Enabled := (FParser.GetDataCount > 0) and not FIsSearching;
  actSaveJSON.Enabled := (FParser.GetDataCount > 0) and not FIsSearching;
  actAnalyze.Enabled := (FParser.GetDataCount > 0) and not FIsSearching;
  
  // Оновлення полів вводу
  edtProduct.Enabled := not FIsSearching;
  cmbCity.Enabled := not FIsSearching;
  edtDelayMin.Enabled := not FIsSearching;
  edtDelayMax.Enabled := not FIsSearching;
  
  // Оновлення прогрес-бару
  pbProgress.Visible := FIsSearching;
  
  Application.ProcessMessages;
end;

procedure TfrmMain.UpdateGrid;
var
  i: Integer;
  Data: TPharmacyDataArray;
begin
  Data := FParser.Data;
  
  sgResults.RowCount := Length(Data) + 1;
  
  for i := 0 to High(Data) do
  begin
    sgResults.Cells[0, i + 1] := Data[i].PharmacyName;
    sgResults.Cells[1, i + 1] := Data[i].Address;
    sgResults.Cells[2, i + 1] := Data[i].ProductName;
    sgResults.Cells[3, i + 1] := Data[i].Price;
    sgResults.Cells[4, i + 1] := Data[i].Availability;
    sgResults.Cells[5, i + 1] := Data[i].Phone;
    sgResults.Cells[6, i + 1] := Data[i].City;
    sgResults.Cells[7, i + 1] := Data[i].URL;
  end;
  
  FTotalFound := Length(Data);
  UpdateStatistics;
end;

procedure TfrmMain.UpdateStatistics;
var
  Stats: string;
begin
  Stats := FParser.GetStatistics;
  memoStats.Text := Stats;
  
  lblTotalRecords.Caption := Format('Загалом записів: %d', [FParser.GetDataCount]);
end;

procedure TfrmMain.EnableControls(Enabled: Boolean);
begin
  gbSearch.Enabled := Enabled;
  gbSettings.Enabled := Enabled;
end;

procedure TfrmMain.AddLogMessage(const Message: string);
begin
  memoLog.Lines.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss', Now), Message]));
  
  // Автопрокрутка до останнього повідомлення
  memoLog.SelStart := Length(memoLog.Text);
  memoLog.Perform(EM_SCROLLCARET, 0, 0);
end;

procedure TfrmMain.SetStatus(const Status: string);
begin
  lblStatus.Caption := Status;
end;

function TfrmMain.ValidateInput: Boolean;
begin
  Result := False;
  
  if Trim(edtProduct.Text) = '' then
  begin
    ShowMessage('Введіть назву товару для пошуку');
    edtProduct.SetFocus;
    Exit;
  end;
  
  if cmbCity.ItemIndex < 0 then
  begin
    ShowMessage('Виберіть місто для пошуку');
    cmbCity.SetFocus;
    Exit;
  end;
  
  Result := True;
end;

function TfrmMain.GetSelectedCity: string;
begin
  if cmbCity.ItemIndex >= 0 then
    Result := cmbCity.Text
  else
    Result := 'Київ';
end;

procedure TfrmMain.LoadDemoData;
begin
  FIsSearching := True;
  UpdateUI;
  SetStatus('Завантаження демонстраційних даних...');
  
  FCurrentTask := TTask.Create(
    procedure
    begin
      try
        FParser.GetDemoData;
        
        TThread.Synchronize(nil,
          procedure
          begin
            UpdateGrid;
            FIsSearching := False;
            UpdateUI;
            SetStatus('Демо дані завантажено');
            AddLogMessage('Демонстраційні дані успішно завантажено');
          end);
          
      except
        on E: Exception do
        begin
          TThread.Synchronize(nil,
            procedure
            begin
              FIsSearching := False;
              UpdateUI;
              SetStatus('Помилка завантаження демо даних');
              AddLogMessage('Помилка: ' + E.Message);
              ShowMessage('Помилка завантаження демо даних: ' + E.Message);
            end);
        end;
      end;
    end);
    
  FCurrentTask.Start;
end;

procedure TfrmMain.SearchProducts(const ProductName, City: string);
begin
  FIsSearching := True;
  UpdateUI;
  SetStatus('Пошук товарів...');
  
  FCurrentTask := TTask.Create(
    procedure
    begin
      try
        FParser.SearchProduct(ProductName, City);
        
        TThread.Synchronize(nil,
          procedure
          begin
            FIsSearching := False;
            UpdateUI;
            SetStatus(Format('Пошук завершено. Знайдено %d записів', [FParser.GetDataCount]));
            AddLogMessage('Пошук успішно завершено');
          end);
          
      except
        on E: Exception do
        begin
          TThread.Synchronize(nil,
            procedure
            begin
              FIsSearching := False;
              UpdateUI;
              SetStatus('Помилка пошуку');
              AddLogMessage('Помилка: ' + E.Message);
              ShowMessage('Помилка пошуку: ' + E.Message);
            end);
        end;
      end;
    end);
    
  FCurrentTask.Start;
end;

procedure TfrmMain.GetPopularProducts;
begin
  FIsSearching := True;
  UpdateUI;
  SetStatus('Отримання популярних товарів...');
  
  FCurrentTask := TTask.Create(
    procedure
    begin
      try
        FParser.GetPopularProducts;
        
        TThread.Synchronize(nil,
          procedure
          begin
            UpdateGrid;
            FIsSearching := False;
            UpdateUI;
            SetStatus('Популярні товари отримано');
            AddLogMessage('Популярні товари успішно отримано');
          end);
          
      except
        on E: Exception do
        begin
          TThread.Synchronize(nil,
            procedure
            begin
              FIsSearching := False;
              UpdateUI;
              SetStatus('Помилка отримання популярних товарів');
              AddLogMessage('Помилка: ' + E.Message);
              ShowMessage('Помилка отримання популярних товарів: ' + E.Message);
            end);
        end;
      end;
    end);
    
  FCurrentTask.Start;
end;

end.