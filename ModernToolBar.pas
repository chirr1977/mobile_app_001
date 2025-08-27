unit ModernToolBar;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ImageList, ImgList, Generics.Collections, Types, Math,
  ExtCtrls, Buttons, ToolWin, CommCtrl, Themes, UxTheme;

type
  // Підтримувані формати іконок
  TIconFormat = (ifPNG, ifSVG, ifICO, ifBMP);
  
  // Стилі сучасних іконок
  TModernIconStyle = (misFlat, misFilled, misOutlined, misRounded, misTwoTone);
  
  // Розміри іконок
  TIconSize = (is16, is20, is24, is32, is48, is64);
  
  // Кольорова тема
  TIconTheme = (itLight, itDark, itAuto);

  // Клас для зберігання інформації про іконку
  TModernIcon = class
  private
    FName: string;
    FFormat: TIconFormat;
    FData: TMemoryStream;
    FStyle: TModernIconStyle;
    FSize: TIconSize;
    FColor: TColor;
    FTheme: TIconTheme;
  public
    constructor Create;
    destructor Destroy; override;
    
    property Name: string read FName write FName;
    property Format: TIconFormat read FFormat write FFormat;
    property Data: TMemoryStream read FData;
    property Style: TModernIconStyle read FStyle write FStyle;
    property Size: TIconSize read FSize write FSize;
    property Color: TColor read FColor write FColor;
    property Theme: TIconTheme read FTheme write FTheme;
  end;

  // Менеджер іконок
  TModernIconManager = class
  private
    FIcons: TObjectDictionary<string, TModernIcon>;
    FCurrentTheme: TIconTheme;
    FDPIScale: Single;
    function GetSizeInPixels(ASize: TIconSize): Integer;
    function GetThemedColor(AColor: TColor): TColor;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure LoadIconFromFile(const AName, AFileName: string; AFormat: TIconFormat = ifPNG);
    procedure LoadIconFromResource(const AName, AResourceName: string; AFormat: TIconFormat = ifPNG);
    procedure LoadSVGIcon(const AName, ASVGData: string);
    
    function GetIcon(const AName: string; ASize: TIconSize; ATheme: TIconTheme = itAuto): TBitmap;
    function RenderSVG(const ASVGData: string; AWidth, AHeight: Integer; AColor: TColor = clDefault): TBitmap;
    
    property CurrentTheme: TIconTheme read FCurrentTheme write FCurrentTheme;
    property DPIScale: Single read FDPIScale write FDPIScale;
  end;

  // Сучасний ToolBar
  TModernToolBar = class(TToolBar)
  private
    FIconManager: TModernIconManager;
    FIconSize: TIconSize;
    FIconTheme: TIconTheme;
    FIconStyle: TModernIconStyle;
    FAutoTheme: Boolean;
    FHighDPIAware: Boolean;
    FSmoothIcons: Boolean;
    FHoverEffect: Boolean;
    FAnimateButtons: Boolean;
    
    procedure UpdateIconSize;
    procedure UpdateTheme;
    procedure CreateModernImageList;
    function GetScaledSize(ASize: Integer): Integer;
    procedure WMDpiChanged(var Message: TWMDpi); message WM_DPICHANGED;
    procedure CMStyleChanged(var Message: TMessage); message CM_STYLECHANGED;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Resize; override;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure AddButton(const ACaption, AIconName: string; AOnClick: TNotifyEvent = nil);
    procedure AddSeparator;
    procedure SetButtonIcon(AButtonIndex: Integer; const AIconName: string);
    procedure RefreshIcons;
    procedure LoadIconSet(const ASetName: string);
    
    property IconManager: TModernIconManager read FIconManager;
  published
    property IconSize: TIconSize read FIconSize write FIconSize default is24;
    property IconTheme: TIconTheme read FIconTheme write FIconTheme default itAuto;
    property IconStyle: TModernIconStyle read FIconStyle write FIconStyle default misFlat;
    property AutoTheme: Boolean read FAutoTheme write FAutoTheme default True;
    property HighDPIAware: Boolean read FHighDPIAware write FHighDPIAware default True;
    property SmoothIcons: Boolean read FSmoothIcons write FSmoothIcons default True;
    property HoverEffect: Boolean read FHoverEffect write FHoverEffect default True;
    property AnimateButtons: Boolean read FAnimateButtons write FAnimateButtons default False;
  end;

  // Кастомна кнопка тулбара з ефектами
  TModernToolButton = class(TToolButton)
  private
    FIconName: string;
    FModernToolBar: TModernToolBar;
    FIsHovering: Boolean;
    
    procedure WMMouseMove(var Message: TWMMouseMove); message WM_MOUSEMOVE;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    
    property IconName: string read FIconName write FIconName;
    property ModernToolBar: TModernToolBar read FModernToolBar write FModernToolBar;
  end;

procedure Register;

implementation

uses
  PngImage, GDIPAPI, GDIPOBJ, GDIPUTIL;

{ TModernIcon }

constructor TModernIcon.Create;
begin
  inherited;
  FData := TMemoryStream.Create;
  FFormat := ifPNG;
  FStyle := misFlat;
  FSize := is24;
  FColor := clBlack;
  FTheme := itAuto;
end;

destructor TModernIcon.Destroy;
begin
  FData.Free;
  inherited;
end;

{ TModernIconManager }

constructor TModernIconManager.Create;
begin
  inherited;
  FIcons := TObjectDictionary<string, TModernIcon>.Create([doOwnsValues]);
  FCurrentTheme := itAuto;
  FDPIScale := 1.0;
end;

destructor TModernIconManager.Destroy;
begin
  FIcons.Free;
  inherited;
end;

function TModernIconManager.GetSizeInPixels(ASize: TIconSize): Integer;
begin
  case ASize of
    is16: Result := Round(16 * FDPIScale);
    is20: Result := Round(20 * FDPIScale);
    is24: Result := Round(24 * FDPIScale);
    is32: Result := Round(32 * FDPIScale);
    is48: Result := Round(48 * FDPIScale);
    is64: Result := Round(64 * FDPIScale);
  else
    Result := Round(24 * FDPIScale);
  end;
end;

function TModernIconManager.GetThemedColor(AColor: TColor): TColor;
begin
  Result := AColor;
  
  if FCurrentTheme = itAuto then
  begin
    // Автоматичне визначення теми на основі системних налаштувань
    if IsAppThemed and IsThemeActive then
    begin
      // Використовуємо системну тему
      if GetSysColor(COLOR_WINDOW) < $808080 then
        Result := clWhite
      else
        Result := clBlack;
    end;
  end
  else if FCurrentTheme = itDark then
    Result := clWhite
  else if FCurrentTheme = itLight then
    Result := clBlack;
end;

procedure TModernIconManager.LoadIconFromFile(const AName, AFileName: string; AFormat: TIconFormat);
var
  Icon: TModernIcon;
begin
  Icon := TModernIcon.Create;
  try
    Icon.Name := AName;
    Icon.Format := AFormat;
    Icon.Data.LoadFromFile(AFileName);
    
    FIcons.AddOrSetValue(AName, Icon);
  except
    Icon.Free;
    raise;
  end;
end;

procedure TModernIconManager.LoadIconFromResource(const AName, AResourceName: string; AFormat: TIconFormat);
var
  Icon: TModernIcon;
  Stream: TResourceStream;
begin
  Icon := TModernIcon.Create;
  try
    Icon.Name := AName;
    Icon.Format := AFormat;
    
    Stream := TResourceStream.Create(HInstance, AResourceName, RT_RCDATA);
    try
      Icon.Data.CopyFrom(Stream, Stream.Size);
    finally
      Stream.Free;
    end;
    
    FIcons.AddOrSetValue(AName, Icon);
  except
    Icon.Free;
    raise;
  end;
end;

procedure TModernIconManager.LoadSVGIcon(const AName, ASVGData: string);
var
  Icon: TModernIcon;
  StringStream: TStringStream;
begin
  Icon := TModernIcon.Create;
  try
    Icon.Name := AName;
    Icon.Format := ifSVG;
    
    StringStream := TStringStream.Create(ASVGData, TEncoding.UTF8);
    try
      Icon.Data.CopyFrom(StringStream, StringStream.Size);
    finally
      StringStream.Free;
    end;
    
    FIcons.AddOrSetValue(AName, Icon);
  except
    Icon.Free;
    raise;
  end;
end;

function TModernIconManager.GetIcon(const AName: string; ASize: TIconSize; ATheme: TIconTheme): TBitmap;
var
  Icon: TModernIcon;
  Size: Integer;
  PngImage: TPngImage;
  MemStream: TMemoryStream;
begin
  Result := nil;
  
  if not FIcons.TryGetValue(AName, Icon) then
    Exit;
    
  Size := GetSizeInPixels(ASize);
  Result := TBitmap.Create;
  Result.Width := Size;
  Result.Height := Size;
  Result.PixelFormat := pf32bit;
  
  try
    case Icon.Format of
      ifPNG:
      begin
        PngImage := TPngImage.Create;
        try
          Icon.Data.Position := 0;
          PngImage.LoadFromStream(Icon.Data);
          
          // Масштабування з згладжуванням
          Result.Canvas.StretchDraw(Rect(0, 0, Size, Size), PngImage);
        finally
          PngImage.Free;
        end;
      end;
      
      ifSVG:
      begin
        Icon.Data.Position := 0;
        MemStream := TMemoryStream.Create;
        try
          MemStream.CopyFrom(Icon.Data, Icon.Data.Size);
          Result.Free;
          Result := RenderSVG(TEncoding.UTF8.GetString(MemStream.Memory, MemStream.Size), 
                            Size, Size, GetThemedColor(Icon.Color));
        finally
          MemStream.Free;
        end;
      end;
      
      ifICO, ifBMP:
      begin
        Icon.Data.Position := 0;
        Result.LoadFromStream(Icon.Data);
        
        // Масштабування якщо потрібно
        if (Result.Width <> Size) or (Result.Height <> Size) then
        begin
          Result.SetSize(Size, Size);
        end;
      end;
    end;
  except
    Result.Free;
    Result := nil;
  end;
end;

function TModernIconManager.RenderSVG(const ASVGData: string; AWidth, AHeight: Integer; AColor: TColor): TBitmap;
// Спрощена реалізація SVG рендерингу
// У реальному проекті варто використовувати спеціалізовану SVG бібліотеку
begin
  Result := TBitmap.Create;
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.PixelFormat := pf32bit;
  
  // Тут має бути код для парсингу та рендерингу SVG
  // Для простоти створюємо заглушку з кольоровим квадратом
  Result.Canvas.Brush.Color := AColor;
  Result.Canvas.FillRect(Rect(2, 2, AWidth-2, AHeight-2));
end;

{ TModernToolBar }

constructor TModernToolBar.Create(AOwner: TComponent);
begin
  inherited;
  
  FIconManager := TModernIconManager.Create;
  FIconSize := is24;
  FIconTheme := itAuto;
  FIconStyle := misFlat;
  FAutoTheme := True;
  FHighDPIAware := True;
  FSmoothIcons := True;
  FHoverEffect := True;
  FAnimateButtons := False;
  
  // Встановлюємо сучасний стиль
  Flat := True;
  ShowCaptions := True;
  List := True;
  
  CreateModernImageList;
  LoadIconSet('default');
end;

destructor TModernToolBar.Destroy;
begin
  FIconManager.Free;
  inherited;
end;

procedure TModernToolBar.CreateParams(var Params: TCreateParams);
begin
  inherited;
  
  if FHighDPIAware then
  begin
    // Встановлюємо DPI awareness
    Params.Style := Params.Style or TBSTYLE_FLAT or CCS_ADJUSTABLE or CCS_NODIVIDER;
  end;
end;

procedure TModernToolBar.CreateModernImageList;
var
  Size: Integer;
begin
  if Images <> nil then
    Images.Free;
    
  Size := FIconManager.GetSizeInPixels(FIconSize);
  
  Images := TImageList.Create(Self);
  Images.Width := Size;
  Images.Height := Size;
  Images.ColorDepth := cd32Bit;
  
  if FSmoothIcons then
    Images.DrawingStyle := dsTransparent;
end;

function TModernToolBar.GetScaledSize(ASize: Integer): Integer;
begin
  if FHighDPIAware then
    Result := MulDiv(ASize, Screen.PixelsPerInch, 96)
  else
    Result := ASize;
end;

procedure TModernToolBar.UpdateIconSize;
begin
  CreateModernImageList;
  RefreshIcons;
  Invalidate;
end;

procedure TModernToolBar.UpdateTheme;
begin
  if FAutoTheme then
  begin
    // Автоматичне визначення теми
    if IsAppThemed and IsThemeActive then
      FIconManager.CurrentTheme := itAuto
    else
      FIconManager.CurrentTheme := itLight;
  end
  else
    FIconManager.CurrentTheme := FIconTheme;
    
  RefreshIcons;
end;

procedure TModernToolBar.AddButton(const ACaption, AIconName: string; AOnClick: TNotifyEvent);
var
  Button: TModernToolButton;
  IconBitmap: TBitmap;
  ImageIndex: Integer;
begin
  Button := TModernToolButton.Create(Self);
  Button.Parent := Self;
  Button.Caption := ACaption;
  Button.IconName := AIconName;
  Button.ModernToolBar := Self;
  Button.AutoSize := True;
  
  if AOnClick <> nil then
    Button.OnClick := AOnClick;
    
  // Додаємо іконку до ImageList
  IconBitmap := FIconManager.GetIcon(AIconName, FIconSize, FIconTheme);
  if IconBitmap <> nil then
  begin
    try
      ImageIndex := Images.Add(IconBitmap, nil);
      Button.ImageIndex := ImageIndex;
    finally
      IconBitmap.Free;
    end;
  end;
end;

procedure TModernToolBar.AddSeparator;
var
  Button: TToolButton;
begin
  Button := TToolButton.Create(Self);
  Button.Parent := Self;
  Button.Style := tbsSeparator;
  Button.Width := 8;
end;

procedure TModernToolBar.SetButtonIcon(AButtonIndex: Integer; const AIconName: string);
var
  Button: TToolButton;
  IconBitmap: TBitmap;
begin
  if (AButtonIndex >= 0) and (AButtonIndex < ButtonCount) then
  begin
    Button := Buttons[AButtonIndex];
    
    if Button is TModernToolButton then
      TModernToolButton(Button).IconName := AIconName;
      
    IconBitmap := FIconManager.GetIcon(AIconName, FIconSize, FIconTheme);
    if IconBitmap <> nil then
    begin
      try
        if Button.ImageIndex >= 0 then
          Images.Replace(Button.ImageIndex, IconBitmap, nil)
        else
          Button.ImageIndex := Images.Add(IconBitmap, nil);
      finally
        IconBitmap.Free;
      end;
    end;
  end;
end;

procedure TModernToolBar.RefreshIcons;
var
  I: Integer;
  Button: TToolButton;
  ModernButton: TModernToolButton;
  IconBitmap: TBitmap;
begin
  Images.Clear;
  
  for I := 0 to ButtonCount - 1 do
  begin
    Button := Buttons[I];
    if Button is TModernToolButton then
    begin
      ModernButton := TModernToolButton(Button);
      if ModernButton.IconName <> '' then
      begin
        IconBitmap := FIconManager.GetIcon(ModernButton.IconName, FIconSize, FIconTheme);
        if IconBitmap <> nil then
        begin
          try
            Button.ImageIndex := Images.Add(IconBitmap, nil);
          finally
            IconBitmap.Free;
          end;
        end;
      end;
    end;
  end;
  
  Invalidate;
end;

procedure TModernToolBar.LoadIconSet(const ASetName: string);
begin
  // Завантажуємо набір іконок за замовчуванням
  // У реальному проекті тут має бути завантаження з файлів або ресурсів
  
  // Приклади сучасних іконок (Material Design icons)
  FIconManager.LoadSVGIcon('save', 
    '<svg width="24" height="24" viewBox="0 0 24 24"><path d="M17,3H5C3.89,3 3,3.9 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V7L17,3M19,19H5V5H16.17L19,7.83V19Z"/></svg>');
    
  FIconManager.LoadSVGIcon('open', 
    '<svg width="24" height="24" viewBox="0 0 24 24"><path d="M10,4H4C2.89,4 2,4.89 2,6V18A2,2 0 0,0 4,20H20A2,2 0 0,0 22,18V8C22,6.89 21.1,6 20,6H12L10,4Z"/></svg>');
    
  FIconManager.LoadSVGIcon('cut', 
    '<svg width="24" height="24" viewBox="0 0 24 24"><path d="M9.64,7.64C10.37,6.91 10.37,5.73 9.64,5C8.91,4.27 7.73,4.27 7,5C6.27,5.73 6.27,6.91 7,7.64C7.73,8.37 8.91,8.37 9.64,7.64M21,12L13,20H17V22H7V20H11L19,12L11,4H7V2H17V4H13L21,12Z"/></svg>');
    
  FIconManager.LoadSVGIcon('copy', 
    '<svg width="24" height="24" viewBox="0 0 24 24"><path d="M19,21H8V7H19M19,5H8A2,2 0 0,0 6,7V21A2,2 0 0,0 8,23H19A2,2 0 0,0 21,21V7A2,2 0 0,0 19,5M16,1H4A2,2 0 0,0 2,3V17H4V3H16V1Z"/></svg>');
    
  FIconManager.LoadSVGIcon('paste', 
    '<svg width="24" height="24" viewBox="0 0 24 24"><path d="M19,20H5V4H7V7H17V4H19M12,2A1,1 0 0,1 13,3A1,1 0 0,1 12,4A1,1 0 0,1 11,3A1,1 0 0,1 12,2M19,2H14.82C14.4,0.84 13.3,0 12,0C10.7,0 9.6,0.84 9.18,2H5A2,2 0 0,0 3,4V20A2,2 0 0,0 5,22H19A2,2 0 0,0 21,20V4A2,2 0 0,0 19,2Z"/></svg>');
end;



procedure TModernToolBar.Resize;
begin
  inherited;
  
  if FHighDPIAware then
  begin
    FIconManager.DPIScale := Screen.PixelsPerInch / 96;
    UpdateIconSize;
  end;
end;

procedure TModernToolBar.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
begin
  inherited;
  // Тут можна додати контекстне меню для налаштування тулбара
end;

procedure TModernToolBar.WMDpiChanged(var Message: TWMDpi);
begin
  inherited;
  
  if FHighDPIAware then
  begin
    FIconManager.DPIScale := Message.XDpi / 96;
    UpdateIconSize;
  end;
end;

procedure TModernToolBar.CMStyleChanged(var Message: TMessage);
begin
  inherited;
  UpdateTheme;
end;

{ TModernToolButton }

constructor TModernToolButton.Create(AOwner: TComponent);
begin
  inherited;
  
  FIsHovering := False;
  FIconName := '';
end;

procedure TModernToolButton.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  
  if (FModernToolBar <> nil) and FModernToolBar.HoverEffect then
  begin
    FIsHovering := True;
    Invalidate;
  end;
end;

procedure TModernToolButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  
  if (FModernToolBar <> nil) and FModernToolBar.HoverEffect then
  begin
    FIsHovering := False;
    Invalidate;
  end;
end;

procedure TModernToolButton.WMMouseMove(var Message: TWMMouseMove);
begin
  inherited;
  // Простий обробник руху миші
end;

procedure TModernToolButton.Paint;
var
  R: TRect;
  OldBrushColor: TColor;
  OldBrushStyle: TBrushStyle;
begin
  inherited;
  
  // Малюємо ефект наведення
  if FIsHovering and (FModernToolBar <> nil) and FModernToolBar.HoverEffect then
  begin
    R := ClientRect;
    OldBrushColor := Canvas.Brush.Color;
    OldBrushStyle := Canvas.Brush.Style;
    
    Canvas.Brush.Color := RGB(200, 200, 200);
    Canvas.Brush.Style := bsSolid;
    Canvas.FillRect(R);
    
    Canvas.Brush.Color := OldBrushColor;
    Canvas.Brush.Style := OldBrushStyle;
  end;
end;

procedure Register;
begin
  RegisterComponents('Modern Controls', [TModernToolBar]);
end;

end.