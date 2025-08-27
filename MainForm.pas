unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, 
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Menus, ModernToolBar, IconSets, SVGRenderer, HighDPISupport,
  Vcl.CheckLst, Vcl.Grids, Vcl.ValEdit;

type
  TfrmMain = class(TForm)
    pnlMain: TPanel;
    pnlToolbar: TPanel;
    pnlContent: TPanel;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    Splitter1: TSplitter;
    pnlSettings: TPanel;
    grpIconSet: TGroupBox;
    cmbIconSet: TComboBox;
    grpTheme: TGroupBox;
    rbLightTheme: TRadioButton;
    rbDarkTheme: TRadioButton;
    rbAutoTheme: TRadioButton;
    grpIconSize: TGroupBox;
    cmbIconSize: TComboBox;
    grpFeatures: TGroupBox;
    chkHighDPI: TCheckBox;
    chkSmoothIcons: TCheckBox;
    chkHoverEffect: TCheckBox;
    chkAnimateButtons: TCheckBox;
    chkShowCaptions: TCheckBox;
    pnlDemo: TPanel;
    lblDemo: TLabel;
    memoDemo: TMemo;
    grpIconBrowser: TGroupBox;
    cmbCategory: TComboBox;
    lstIcons: TListBox;
    edtSearch: TEdit;
    btnSearch: TButton;
    pnlIconPreview: TPanel;
    imgIconPreview: TImage;
    lblIconName: TLabel;
    lblIconDescription: TLabel;
    grpDPIInfo: TGroupBox;
    vleDPIInfo: TValueListEditor;
    btnRefreshDPI: TButton;
    MainMenu1: TMainMenu;
    mnuFile: TMenuItem;
    mnuNew: TMenuItem;
    mnuOpen: TMenuItem;
    mnuSave: TMenuItem;
    mnuSaveAs: TMenuItem;
    N1: TMenuItem;
    mnuExit: TMenuItem;
    mnuEdit: TMenuItem;
    mnuCut: TMenuItem;
    mnuCopy: TMenuItem;
    mnuPaste: TMenuItem;
    N2: TMenuItem;
    mnuSelectAll: TMenuItem;
    mnuView: TMenuItem;
    mnuToolbar: TMenuItem;
    mnuStatusBar: TMenuItem;
    mnuHelp: TMenuItem;
    mnuAbout: TMenuItem;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure cmbIconSetChange(Sender: TObject);
    procedure rbThemeClick(Sender: TObject);
    procedure cmbIconSizeChange(Sender: TObject);
    procedure chkFeatureClick(Sender: TObject);
    procedure cmbCategoryChange(Sender: TObject);
    procedure lstIconsClick(Sender: TObject);
    procedure edtSearchChange(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure btnRefreshDPIClick(Sender: TObject);
    procedure mnuNewClick(Sender: TObject);
    procedure mnuOpenClick(Sender: TObject);
    procedure mnuSaveClick(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure mnuCutClick(Sender: TObject);
    procedure mnuCopyClick(Sender: TObject);
    procedure mnuPasteClick(Sender: TObject);
    procedure mnuAboutClick(Sender: TObject);
    
  private
    FModernToolBar: TModernToolBar;
    FIconManager: TIconSetsManager;
    FSVGRenderer: TSVGRenderer;
    FCurrentIconInfo: TIconInfo;
    
    procedure InitializeComponents;
    procedure SetupModernToolBar;
    procedure LoadIconSets;
    procedure LoadIconCategories;
    procedure LoadIconsForCategory(Category: TIconCategory);
    procedure LoadAllIcons;
    procedure SearchIcons(const SearchTerm: string);
    procedure ShowIconPreview(const IconInfo: TIconInfo);
    procedure UpdateDPIInfo;
    procedure UpdateToolbarSettings;
    procedure LogAction(const Action: string);
    
    // ToolBar button handlers
    procedure OnNewClick(Sender: TObject);
    procedure OnOpenClick(Sender: TObject);
    procedure OnSaveClick(Sender: TObject);
    procedure OnCutClick(Sender: TObject);
    procedure OnCopyClick(Sender: TObject);
    procedure OnPasteClick(Sender: TObject);
    procedure OnUndoClick(Sender: TObject);
    procedure OnRedoClick(Sender: TObject);
    procedure OnSearchClick(Sender: TObject);
    procedure OnSettingsClick(Sender: TObject);
    procedure OnHelpClick(Sender: TObject);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  System.Types, System.UITypes, Vcl.Imaging.pngimage;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Ініціалізуємо компоненти
  FIconManager := TIconSetsManager.GetInstance;
  FSVGRenderer := TSVGRenderer.Create;
  
  // Налаштовуємо форму
  Caption := 'Modern ToolBar Demo - Сучасна панель інструментів для Delphi';
  Position := poScreenCenter;
  WindowState := wsMaximized;
  
  // Ініціалізуємо інтерфейс
  InitializeComponents;
  SetupModernToolBar;
  LoadIconSets;
  LoadIconCategories;
  UpdateDPIInfo;
  
  LogAction('Програма запущена');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FSVGRenderer.Free;
  // FIconManager звільняється автоматично (singleton)
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  UpdateDPIInfo;
end;

procedure TfrmMain.InitializeComponents;
begin
  // Налаштовуємо панелі
  pnlMain.Align := alClient;
  pnlToolbar.Align := alTop;
  pnlToolbar.Height := 50;
  pnlSettings.Align := alRight;
  pnlSettings.Width := 300;
  pnlContent.Align := alClient;
  pnlStatus.Align := alBottom;
  pnlStatus.Height := 25;
  
  // Налаштовуємо сплітер
  Splitter1.Align := alRight;
  Splitter1.Width := 4;
  
  // Налаштовуємо комбобокси
  cmbIconSize.Items.Clear;
  cmbIconSize.Items.Add('16px');
  cmbIconSize.Items.Add('20px');  
  cmbIconSize.Items.Add('24px');
  cmbIconSize.Items.Add('32px');
  cmbIconSize.Items.Add('48px');
  cmbIconSize.Items.Add('64px');
  cmbIconSize.ItemIndex := 2; // 24px за замовчуванням
  
  // Налаштовуємо теми
  rbAutoTheme.Checked := True;
  
  // Налаштовуємо функції
  chkHighDPI.Checked := True;
  chkSmoothIcons.Checked := True;
  chkHoverEffect.Checked := True;
  chkAnimateButtons.Checked := False;
  chkShowCaptions.Checked := True;
  
  // Налаштовуємо демо-область
  memoDemo.Lines.Clear;
  memoDemo.Lines.Add('Ласкаво просимо до демонстрації сучасної панелі інструментів!');
  memoDemo.Lines.Add('');
  memoDemo.Lines.Add('Особливості:');
  memoDemo.Lines.Add('• Підтримка SVG іконок');
  memoDemo.Lines.Add('• High DPI масштабування');
  memoDemo.Lines.Add('• Різні набори іконок (Material Design, Feather, тощо)');
  memoDemo.Lines.Add('• Світла/темна тема');
  memoDemo.Lines.Add('• Анімовані ефекти наведення');
  memoDemo.Lines.Add('• Сучасний дизайн');
  memoDemo.Lines.Add('');
  memoDemo.Lines.Add('Спробуйте різні налаштування і подивіться на результат!');
  
  // Налаштовуємо DPI інформацію
  vleDPIInfo.Strings.Clear;
  vleDPIInfo.InsertRow('Current DPI', '', True);
  vleDPIInfo.InsertRow('Scale Factor', '', True);
  vleDPIInfo.InsertRow('Screen Size', '', True);
  vleDPIInfo.InsertRow('Form Size', '', True);
  vleDPIInfo.InsertRow('DPI Awareness', '', True);
  
  // Налаштовуємо попередній перегляд іконок
  imgIconPreview.Stretch := True;
  imgIconPreview.Proportional := True;
  imgIconPreview.Center := True;
end;

procedure TfrmMain.SetupModernToolBar;
begin
  // Створюємо сучасну панель інструментів
  FModernToolBar := TModernToolBar.Create(Self);
  FModernToolBar.Parent := pnlToolbar;
  FModernToolBar.Align := alClient;
  FModernToolBar.EdgeBorders := [];
  FModernToolBar.Flat := True;
  FModernToolBar.ShowCaptions := True;
  FModernToolBar.List := True;
  FModernToolBar.ButtonHeight := 40;
  FModernToolBar.ButtonWidth := 80;
  
  // Налаштовуємо властивості
  FModernToolBar.IconSize := is24;
  FModernToolBar.IconTheme := itAuto;
  FModernToolBar.IconStyle := misFlat;
  FModernToolBar.HighDPIAware := True;
  FModernToolBar.SmoothIcons := True;
  FModernToolBar.HoverEffect := True;
  FModernToolBar.AnimateButtons := False;
  
  // Додаємо кнопки
  FModernToolBar.AddButton('Новий', 'document-plus', OnNewClick);
  FModernToolBar.AddButton('Відкрити', 'folder-open', OnOpenClick);
  FModernToolBar.AddButton('Зберегти', 'save', OnSaveClick);
  
  FModernToolBar.AddSeparator;
  
  FModernToolBar.AddButton('Вирізати', 'scissors', OnCutClick);
  FModernToolBar.AddButton('Копіювати', 'copy', OnCopyClick);
  FModernToolBar.AddButton('Вставити', 'clipboard', OnPasteClick);
  
  FModernToolBar.AddSeparator;
  
  FModernToolBar.AddButton('Скасувати', 'undo', OnUndoClick);
  FModernToolBar.AddButton('Повторити', 'redo', OnRedoClick);
  
  FModernToolBar.AddSeparator;
  
  FModernToolBar.AddButton('Пошук', 'search', OnSearchClick);
  FModernToolBar.AddButton('Налаштування', 'settings', OnSettingsClick);
  FModernToolBar.AddButton('Довідка', 'help-circle', OnHelpClick);
end;

procedure TfrmMain.LoadIconSets;
var
  IconSets: TArray<string>;
  SetName: string;
begin
  cmbIconSet.Items.Clear;
  
  IconSets := FIconManager.GetAvailableIconSets;
  for SetName in IconSets do
    cmbIconSet.Items.Add(SetName);
    
  // Встановлюємо активний набір
  cmbIconSet.ItemIndex := cmbIconSet.Items.IndexOf(FIconManager.ActiveSet);
  if cmbIconSet.ItemIndex = -1 then
    cmbIconSet.ItemIndex := 0;
end;

procedure TfrmMain.LoadIconCategories;
var
  Category: TIconCategory;
begin
  cmbCategory.Items.Clear;
  cmbCategory.Items.Add('Всі категорії');
  
  for Category := Low(TIconCategory) to High(TIconCategory) do
    cmbCategory.Items.Add(TIconUtils.CategoryToString(Category));
    
  cmbCategory.ItemIndex := 0;
end;

procedure TfrmMain.LoadIconsForCategory(Category: TIconCategory);
var
  Icons: TArray<TIconInfo>;
  IconInfo: TIconInfo;
begin
  lstIcons.Items.Clear;
  
  Icons := FIconManager.GetIconsByCategory(Category);
  for IconInfo in Icons do
  begin
    if IconInfo.Available then
      lstIcons.Items.AddObject(IconInfo.DisplayName, TObject(lstIcons.Items.Count));
  end;
end;

procedure TfrmMain.LoadAllIcons;
var
  IconSet: TIconSet;
  IconNames: TStringList;
  IconName: string;
  IconInfo: TIconInfo;
  Category: TIconCategory;
begin
  lstIcons.Items.Clear;
  
  IconSet := FIconManager.GetActiveIconSet;
  if not Assigned(IconSet) then
    Exit;
    
  // Завантажуємо іконки з усіх категорій
  for Category := Low(TIconCategory) to High(TIconCategory) do
  begin
    IconNames := IconSet.GetIconsByCategory(Category);
    try
      for IconName in IconNames do
      begin
        IconInfo := IconSet.GetIcon(IconName);
        if IconInfo.Available then
          lstIcons.Items.AddObject(IconInfo.DisplayName, TObject(lstIcons.Items.Count));
      end;
    finally
      IconNames.Free;
    end;
  end;
end;

procedure TfrmMain.SearchIcons(const SearchTerm: string);
var
  Icons: TArray<TIconInfo>;
  IconInfo: TIconInfo;
begin
  lstIcons.Items.Clear;
  
  Icons := FIconManager.SearchIcons(SearchTerm);
  for IconInfo in Icons do
  begin
    if IconInfo.Available then
      lstIcons.Items.AddObject(IconInfo.DisplayName, TObject(lstIcons.Items.Count));
  end;
end;

procedure TfrmMain.ShowIconPreview(const IconInfo: TIconInfo);
var
  SVGData: string;
  IconBitmap: TBitmap;
  Size: Integer;
begin
  FCurrentIconInfo := IconInfo;
  
  lblIconName.Caption := IconInfo.DisplayName;
  lblIconDescription.Caption := IconInfo.Description;
  
  // Отримуємо SVG даних
  SVGData := FIconManager.GetIconSVG(IconInfo.Name, 48);
  
  if SVGData <> '' then
  begin
    try
      // Рендеримо SVG в bitmap
      FSVGRenderer.LoadFromString(SVGData);
      
      IconBitmap := TBitmap.Create;
      try
        Size := 48;
        FSVGRenderer.RenderToBitmap(IconBitmap, Size, Size, clWhite);
        imgIconPreview.Picture.Assign(IconBitmap);
      finally
        IconBitmap.Free;
      end;
    except
      // Якщо не вдалося рендерити, показуємо заглушку
      imgIconPreview.Picture := nil;
    end;
  end
  else
    imgIconPreview.Picture := nil;
end;

procedure TfrmMain.UpdateDPIInfo;
var
  DPIInfo: TDPIInfo;
begin
  DPIInfo := THighDPIManager.GetDPIForForm(Self);
  
  vleDPIInfo.Values['Current DPI'] := IntToStr(DPIInfo.DPIValue);
  vleDPIInfo.Values['Scale Factor'] := Format('%.2f', [DPIInfo.ScaleFactor]);
  vleDPIInfo.Values['Screen Size'] := Format('%dx%d', [Screen.Width, Screen.Height]);
  vleDPIInfo.Values['Form Size'] := Format('%dx%d', [Width, Height]);
  
  case THighDPIManager.Awareness of
    daUnaware: vleDPIInfo.Values['DPI Awareness'] := 'Unaware';
    daSystemAware: vleDPIInfo.Values['DPI Awareness'] := 'System Aware';
    daPerMonitorAware: vleDPIInfo.Values['DPI Awareness'] := 'Per-Monitor Aware';
    daPerMonitorV2Aware: vleDPIInfo.Values['DPI Awareness'] := 'Per-Monitor V2 Aware';
  end;
end;

procedure TfrmMain.UpdateToolbarSettings;
var
  Theme: string;
  Size: TIconSize;
begin
  if not Assigned(FModernToolBar) then
    Exit;
    
  // Оновлюємо тему
  if rbLightTheme.Checked then
    Theme := 'light'
  else if rbDarkTheme.Checked then
    Theme := 'dark'
  else
    Theme := 'auto';
    
  FIconManager.SetTheme(Theme);
  FModernToolBar.IconTheme := itAuto;
  
  // Оновлюємо розмір іконок
  case cmbIconSize.ItemIndex of
    0: Size := is16;
    1: Size := is20;
    2: Size := is24;
    3: Size := is32;
    4: Size := is48;
    5: Size := is64;
  else
    Size := is24;
  end;
  
  FModernToolBar.IconSize := Size;
  
  // Оновлюємо функції
  FModernToolBar.HighDPIAware := chkHighDPI.Checked;
  FModernToolBar.SmoothIcons := chkSmoothIcons.Checked;
  FModernToolBar.HoverEffect := chkHoverEffect.Checked;
  FModernToolBar.AnimateButtons := chkAnimateButtons.Checked;
  FModernToolBar.ShowCaptions := chkShowCaptions.Checked;
  
  // Оновлюємо панель інструментів
  FModernToolBar.RefreshIcons;
  
  LogAction('Налаштування панелі оновлено');
end;

procedure TfrmMain.LogAction(const Action: string);
begin
  lblStatus.Caption := Format('%s - %s', [TimeToStr(Now), Action]);
  
  memoDemo.Lines.Insert(0, Format('[%s] %s', [TimeToStr(Now), Action]));
  if memoDemo.Lines.Count > 100 then
    memoDemo.Lines.Delete(memoDemo.Lines.Count - 1);
end;

// Event handlers

procedure TfrmMain.cmbIconSetChange(Sender: TObject);
begin
  if cmbIconSet.ItemIndex >= 0 then
  begin
    FIconManager.SetActiveIconSet(cmbIconSet.Items[cmbIconSet.ItemIndex]);
    LoadAllIcons;
    UpdateToolbarSettings;
    LogAction('Набір іконок змінено на: ' + cmbIconSet.Text);
  end;
end;

procedure TfrmMain.rbThemeClick(Sender: TObject);
begin
  UpdateToolbarSettings;
  
  if rbLightTheme.Checked then
    LogAction('Встановлено світлу тему')
  else if rbDarkTheme.Checked then
    LogAction('Встановлено темну тему')
  else
    LogAction('Встановлено автоматичну тему');
end;

procedure TfrmMain.cmbIconSizeChange(Sender: TObject);
begin
  UpdateToolbarSettings;
  LogAction('Розмір іконок змінено на: ' + cmbIconSize.Text);
end;

procedure TfrmMain.chkFeatureClick(Sender: TObject);
begin
  UpdateToolbarSettings;
  
  if Sender = chkHighDPI then
    LogAction('High DPI підтримка: ' + BoolToStr(chkHighDPI.Checked, True))
  else if Sender = chkSmoothIcons then
    LogAction('Згладжування іконок: ' + BoolToStr(chkSmoothIcons.Checked, True))
  else if Sender = chkHoverEffect then
    LogAction('Ефект наведення: ' + BoolToStr(chkHoverEffect.Checked, True))
  else if Sender = chkAnimateButtons then
    LogAction('Анімація кнопок: ' + BoolToStr(chkAnimateButtons.Checked, True))
  else if Sender = chkShowCaptions then
    LogAction('Показувати підписи: ' + BoolToStr(chkShowCaptions.Checked, True));
end;

procedure TfrmMain.cmbCategoryChange(Sender: TObject);
begin
  if cmbCategory.ItemIndex = 0 then
    LoadAllIcons
  else
    LoadIconsForCategory(TIconCategory(cmbCategory.ItemIndex - 1));
    
  LogAction('Категорія змінена на: ' + cmbCategory.Text);
end;

procedure TfrmMain.lstIconsClick(Sender: TObject);
var
  IconSet: TIconSet;
  IconInfo: TIconInfo;
  SelectedIndex: Integer;
begin
  if lstIcons.ItemIndex >= 0 then
  begin
    IconSet := FIconManager.GetActiveIconSet;
    if Assigned(IconSet) then
    begin
      SelectedIndex := Integer(lstIcons.Items.Objects[lstIcons.ItemIndex]);
      // Тут треба отримати іконку за індексом або назвою
      // Спрощена реалізація:
      IconInfo := FIconManager.GetIcon('home'); // Заглушка
      ShowIconPreview(IconInfo);
    end;
  end;
end;

procedure TfrmMain.edtSearchChange(Sender: TObject);
begin
  if edtSearch.Text = '' then
    LoadAllIcons
  else
    SearchIcons(edtSearch.Text);
end;

procedure TfrmMain.btnSearchClick(Sender: TObject);
begin
  SearchIcons(edtSearch.Text);
  LogAction('Пошук: ' + edtSearch.Text);
end;

procedure TfrmMain.btnRefreshDPIClick(Sender: TObject);
begin
  UpdateDPIInfo;
  LogAction('DPI інформацію оновлено');
end;

// Menu handlers

procedure TfrmMain.mnuNewClick(Sender: TObject);
begin
  OnNewClick(Sender);
end;

procedure TfrmMain.mnuOpenClick(Sender: TObject);
begin
  OnOpenClick(Sender);
end;

procedure TfrmMain.mnuSaveClick(Sender: TObject);
begin
  OnSaveClick(Sender);
end;

procedure TfrmMain.mnuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.mnuCutClick(Sender: TObject);
begin
  OnCutClick(Sender);
end;

procedure TfrmMain.mnuCopyClick(Sender: TObject);
begin
  OnCopyClick(Sender);
end;

procedure TfrmMain.mnuPasteClick(Sender: TObject);
begin
  OnPasteClick(Sender);
end;

procedure TfrmMain.mnuAboutClick(Sender: TObject);
begin
  ShowMessage('Modern ToolBar Demo' + #13#10 + 
              'Демонстрація сучасної панелі інструментів для Delphi' + #13#10#13#10 +
              'Особливості:' + #13#10 +
              '• SVG іконки з різних наборів' + #13#10 +
              '• High DPI підтримка' + #13#10 +
              '• Сучасні теми (світла/темна)' + #13#10 +
              '• Анімовані ефекти' + #13#10 +
              '• Гнучкі налаштування');
end;

// ToolBar button handlers

procedure TfrmMain.OnNewClick(Sender: TObject);
begin
  LogAction('Натиснуто кнопку "Новий"');
  memoDemo.Lines.Clear;
  memoDemo.Lines.Add('Створено новий документ');
end;

procedure TfrmMain.OnOpenClick(Sender: TObject);
begin
  LogAction('Натиснуто кнопку "Відкрити"');
  memoDemo.Lines.Add('Відкриття файлу...');
end;

procedure TfrmMain.OnSaveClick(Sender: TObject);
begin
  LogAction('Натиснуто кнопку "Зберегти"');
  memoDemo.Lines.Add('Збереження файлу...');
end;

procedure TfrmMain.OnCutClick(Sender: TObject);
begin
  LogAction('Натиснуто кнопку "Вирізати"');
  if memoDemo.Focused and (memoDemo.SelLength > 0) then
    memoDemo.CutToClipboard;
end;

procedure TfrmMain.OnCopyClick(Sender: TObject);
begin
  LogAction('Натиснуто кнопку "Копіювати"');
  if memoDemo.Focused and (memoDemo.SelLength > 0) then
    memoDemo.CopyToClipboard;
end;

procedure TfrmMain.OnPasteClick(Sender: TObject);
begin
  LogAction('Натиснуто кнопку "Вставити"');
  if memoDemo.Focused then
    memoDemo.PasteFromClipboard;
end;

procedure TfrmMain.OnUndoClick(Sender: TObject);
begin
  LogAction('Натиснуто кнопку "Скасувати"');
  if memoDemo.Focused then
    memoDemo.Undo;
end;

procedure TfrmMain.OnRedoClick(Sender: TObject);
begin
  LogAction('Натиснуто кнопку "Повторити"');
  memoDemo.Lines.Add('Повтор дії...');
end;

procedure TfrmMain.OnSearchClick(Sender: TObject);
begin
  LogAction('Натиснуто кнопку "Пошук"');
  edtSearch.SetFocus;
end;

procedure TfrmMain.OnSettingsClick(Sender: TObject);
begin
  LogAction('Натиснуто кнопку "Налаштування"');
  if pnlSettings.Visible then
    pnlSettings.Hide
  else
    pnlSettings.Show;
end;

procedure TfrmMain.OnHelpClick(Sender: TObject);
begin
  LogAction('Натиснуто кнопку "Довідка"');
  mnuAboutClick(Sender);
end;

end.