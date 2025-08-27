unit HighDPISupport;

interface

uses
  Windows, Messages, Classes, Graphics, Controls, Forms, SysUtils, Types, Math;

type
  // DPI усвідомленість
  TDPIAwareness = (daUnaware, daSystemAware, daPerMonitorAware, daPerMonitorV2Aware);
  
  // Режими масштабування
  TScalingMode = (smNone, smLinear, smSmooth, smSharp);
  
  // Інформація про DPI
  TDPIInfo = record
    DPIValue: Integer;
    ScaleFactor: Single;
    ScaleFactorX: Single;
    ScaleFactorY: Single;
    IsHighDPI: Boolean;
    MonitorHandle: HMONITOR;
  end;

  // Менеджер високої роздільності
  THighDPIManager = class
  private
    class var FInstance: THighDPIManager;
    class var FCurrentDPI: Integer;
    class var FBaseDPI: Integer;
    class var FAwareness: TDPIAwareness;
    class var FScalingMode: TScalingMode;
    class var FAutoScale: Boolean;
    class var FCallbacks: TList<TNotifyEvent>;
    
    class procedure InitializeDPIAwareness;
    class function GetSystemDPI: Integer;
    class function GetMonitorDPI(Monitor: HMONITOR): Integer;
    class procedure NotifyDPIChange;
    
  public
    class constructor Create;
    class destructor Destroy;
    
    class function GetInstance: THighDPIManager;
    class procedure SetDPIAwareness(AAwareness: TDPIAwareness);
    class function GetCurrentDPI: Integer;
    class function GetDPIForMonitor(Monitor: HMONITOR): TDPIInfo;
    class function GetDPIForWindow(Window: HWND): TDPIInfo;
    class function GetDPIForForm(Form: TForm): TDPIInfo;
    
    // Масштабування
    class function ScaleValue(Value: Integer; TargetDPI: Integer = 0): Integer; overload;
    class function ScaleValue(Value: Single; TargetDPI: Integer = 0): Single; overload;
    class function ScaleSize(const Size: TSize; TargetDPI: Integer = 0): TSize;
    class function ScaleRect(const Rect: TRect; TargetDPI: Integer = 0): TRect;
    class function ScalePoint(const Point: TPoint; TargetDPI: Integer = 0): TPoint;
    
    // Зворотне масштабування
    class function UnscaleValue(Value: Integer; SourceDPI: Integer = 0): Integer; overload;
    class function UnscaleValue(Value: Single; SourceDPI: Integer = 0): Single; overload;
    class function UnscaleSize(const Size: TSize; SourceDPI: Integer = 0): TSize;
    class function UnscaleRect(const Rect: TRect; SourceDPI: Integer = 0): TRect;
    
    // Бітмапи та зображення
    class procedure ScaleBitmap(Source, Target: TBitmap; NewWidth, NewHeight: Integer; Mode: TScalingMode = smSmooth);
    class function CreateScaledBitmap(Source: TBitmap; ScaleFactor: Single; Mode: TScalingMode = smSmooth): TBitmap;
    class function CreateDPIAwareBitmap(Source: TBitmap; TargetDPI: Integer; Mode: TScalingMode = smSmooth): TBitmap;
    
    // Шрифти
    class function ScaleFont(Font: TFont; TargetDPI: Integer = 0): TFont;
    class procedure ApplyDPIToFont(Font: TFont; TargetDPI: Integer = 0);
    
    // Подписка на зміни DPI
    class procedure RegisterDPIChangeCallback(Callback: TNotifyEvent);
    class procedure UnregisterDPIChangeCallback(Callback: TNotifyEvent);
    
    // Властивості
    class property CurrentDPI: Integer read GetCurrentDPI;
    class property BaseDPI: Integer read FBaseDPI;
    class property Awareness: TDPIAwareness read FAwareness write SetDPIAwareness;
    class property ScalingMode: TScalingMode read FScalingMode write FScalingMode;
    class property AutoScale: Boolean read FAutoScale write FAutoScale;
  end;

  // Базовий клас для DPI-свідомих компонентів
  TDPIAwareComponent = class(TComponent)
  private
    FCurrentDPI: Integer;
    FBaseDPI: Integer;
    FAutoScaleDPI: Boolean;
    FScalingMode: TScalingMode;
    FOnDPIChanged: TNotifyEvent;
    
    procedure HandleDPIChange(Sender: TObject);
  protected
    procedure SetParent(AParent: TComponent); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    virtual procedure DPIChanged(NewDPI: Integer); virtual;
    virtual procedure ScaleForDPI(NewDPI: Integer); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure UpdateDPI;
    function GetEffectiveDPI: Integer;
    function GetScaleFactor: Single;
    
    property CurrentDPI: Integer read FCurrentDPI;
    property BaseDPI: Integer read FBaseDPI write FBaseDPI;
    property AutoScaleDPI: Boolean read FAutoScaleDPI write FAutoScaleDPI;
    property ScalingMode: TScalingMode read FScalingMode write FScalingMode;
    property OnDPIChanged: TNotifyEvent read FOnDPIChanged write FOnDPIChanged;
  end;

  // DPI-свідомий контрол
  TDPIAwareControl = class(TCustomControl)
  private
    FCurrentDPI: Integer;
    FBaseDPI: Integer;
    FAutoScaleDPI: Boolean;
    FScalingMode: TScalingMode;
    FOnDPIChanged: TNotifyEvent;
    
    procedure HandleDPIChange(Sender: TObject);
    procedure WMDPIChanged(var Message: TWMDpi); message WM_DPICHANGED;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure SetParent(AParent: TWinControl); override;
    virtual procedure DPIChanged(NewDPI: Integer); virtual;
    virtual procedure ScaleForDPI(NewDPI: Integer); virtual;
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure UpdateDPI;
    function GetEffectiveDPI: Integer;
    function GetScaleFactor: Single;
    
    property CurrentDPI: Integer read FCurrentDPI;
    property BaseDPI: Integer read FBaseDPI write FBaseDPI;
    property AutoScaleDPI: Boolean read FAutoScaleDPI write FAutoScaleDPI;
    property ScalingMode: TScalingMode read FScalingMode write FScalingMode;
    property OnDPIChanged: TNotifyEvent read FOnDPIChanged write FOnDPIChanged;
  end;

  // Утилітарні функції
  THiDPIUtils = class
  public
    class function GetSystemMetricsForDPI(nIndex: Integer; dpi: UINT): Integer;
    class function AdjustWindowRectExForDPI(var lpRect: TRect; dwStyle: DWORD; bMenu: BOOL; dwExStyle: DWORD; dpi: UINT): BOOL;
    class function SystemParametersInfoForDPI(uiAction, uiParam: UINT; pvParam: Pointer; fWinIni: UINT; dpi: UINT): BOOL;
    class function GetDPIForWindow(hwnd: HWND): UINT;
    class function GetDPIForMonitor(hmonitor: HMONITOR; dpiType: Integer; out dpiX, dpiY: UINT): HRESULT;
    class function SetProcessDPIAware: BOOL;
    class function SetProcessDpiAwareness(value: Integer): HRESULT;
    class function SetProcessDpiAwarenessContext(value: Pointer): BOOL;
    
    // Перевірка підтримки API
    class function IsWindows8Point1OrGreater: Boolean;
    class function IsWindows10OrGreater: Boolean;
    class function IsPerMonitorDPIAware: Boolean;
  end;

  // Константи для DPI API
const
  DPI_AWARENESS_INVALID = -1;
  DPI_AWARENESS_UNAWARE = 0;
  DPI_AWARENESS_SYSTEM_AWARE = 1;
  DPI_AWARENESS_PER_MONITOR_AWARE = 2;
  
  DPI_AWARENESS_CONTEXT_UNAWARE = Pointer(-1);
  DPI_AWARENESS_CONTEXT_SYSTEM_AWARE = Pointer(-2);
  DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE = Pointer(-3);
  DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = Pointer(-4);
  
  MDT_EFFECTIVE_DPI = 0;
  MDT_ANGULAR_DPI = 1;
  MDT_RAW_DPI = 2;
  MDT_DEFAULT = MDT_EFFECTIVE_DPI;

implementation

uses
  MultiMon, UxTheme, GraphUtil;

var
  // Динамічно завантажені функції
  SetProcessDPIAware: function: BOOL; stdcall;
  SetProcessDpiAwareness: function(value: Integer): HRESULT; stdcall;
  SetProcessDpiAwarenessContext: function(value: Pointer): BOOL; stdcall;
  GetDPIForWindow: function(hwnd: HWND): UINT; stdcall;
  GetDPIForMonitor: function(hmonitor: HMONITOR; dpiType: Integer; out dpiX, dpiY: UINT): HRESULT; stdcall;
  GetSystemMetricsForDPI: function(nIndex: Integer; dpi: UINT): Integer; stdcall;
  AdjustWindowRectExForDPI: function(var lpRect: TRect; dwStyle: DWORD; bMenu: BOOL; dwExStyle: DWORD; dpi: UINT): BOOL; stdcall;
  SystemParametersInfoForDPI: function(uiAction, uiParam: UINT; pvParam: Pointer; fWinIni: UINT; dpi: UINT): BOOL; stdcall;

procedure InitializeDPIAPI;
var
  User32Handle, SHCoreHandle: THandle;
begin
  // Завантажуємо User32.dll
  User32Handle := GetModuleHandle('user32.dll');
  if User32Handle <> 0 then
  begin
    @SetProcessDPIAware := GetProcAddress(User32Handle, 'SetProcessDPIAware');
    @SetProcessDpiAwarenessContext := GetProcAddress(User32Handle, 'SetProcessDpiAwarenessContext');
    @GetDPIForWindow := GetProcAddress(User32Handle, 'GetDpiForWindow');
    @GetSystemMetricsForDPI := GetProcAddress(User32Handle, 'GetSystemMetricsForDpi');
    @AdjustWindowRectExForDPI := GetProcAddress(User32Handle, 'AdjustWindowRectExForDpi');
    @SystemParametersInfoForDPI := GetProcAddress(User32Handle, 'SystemParametersInfoForDpi');
  end;
  
  // Завантажуємо SHCore.dll
  SHCoreHandle := LoadLibrary('SHCore.dll');
  if SHCoreHandle <> 0 then
  begin
    @SetProcessDpiAwareness := GetProcAddress(SHCoreHandle, 'SetProcessDpiAwareness');
    @GetDPIForMonitor := GetProcAddress(SHCoreHandle, 'GetDpiForMonitor');
  end;
end;

{ THighDPIManager }

class constructor THighDPIManager.Create;
begin
  FInstance := nil;
  FBaseDPI := 96;
  FCurrentDPI := 96;
  FAwareness := daUnaware;
  FScalingMode := smSmooth;
  FAutoScale := True;
  FCallbacks := TList<TNotifyEvent>.Create;
  
  InitializeDPIAPI;
  InitializeDPIAwareness;
end;

class destructor THighDPIManager.Destroy;
begin
  if Assigned(FCallbacks) then
    FCallbacks.Free;
    
  if Assigned(FInstance) then
    FInstance.Free;
end;

class function THighDPIManager.GetInstance: THighDPIManager;
begin
  if not Assigned(FInstance) then
    FInstance := THighDPIManager.Create;
  Result := FInstance;
end;

class procedure THighDPIManager.InitializeDPIAwareness;
begin
  FCurrentDPI := GetSystemDPI;
  
  // Автоматично встановлюємо DPI awareness
  if THiDPIUtils.IsWindows10OrGreater then
  begin
    if Assigned(SetProcessDpiAwarenessContext) then
    begin
      SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
      FAwareness := daPerMonitorV2Aware;
    end;
  end
  else if THiDPIUtils.IsWindows8Point1OrGreater then
  begin
    if Assigned(SetProcessDpiAwareness) then
    begin
      SetProcessDpiAwareness(DPI_AWARENESS_PER_MONITOR_AWARE);
      FAwareness := daPerMonitorAware;
    end;
  end
  else
  begin
    if Assigned(SetProcessDPIAware) then
    begin
      SetProcessDPIAware;
      FAwareness := daSystemAware;
    end;
  end;
end;

class function THighDPIManager.GetSystemDPI: Integer;
var
  DC: HDC;
begin
  DC := GetDC(0);
  try
    Result := GetDeviceCaps(DC, LOGPIXELSX);
  finally
    ReleaseDC(0, DC);
  end;
end;

class function THighDPIManager.GetMonitorDPI(Monitor: HMONITOR): Integer;
var
  DpiX, DpiY: UINT;
begin
  Result := FBaseDPI;
  
  if Assigned(GetDPIForMonitor) then
  begin
    if GetDPIForMonitor(Monitor, MDT_EFFECTIVE_DPI, DpiX, DpiY) = S_OK then
      Result := DpiX;
  end;
end;

class procedure THighDPIManager.SetDPIAwareness(AAwareness: TDPIAwareness);
begin
  if FAwareness = AAwareness then
    Exit;
    
  FAwareness := AAwareness;
  
  case AAwareness of
    daUnaware: ;
    daSystemAware:
      if Assigned(SetProcessDPIAware) then
        SetProcessDPIAware;
    daPerMonitorAware:
      if Assigned(SetProcessDpiAwareness) then
        SetProcessDpiAwareness(DPI_AWARENESS_PER_MONITOR_AWARE);
    daPerMonitorV2Aware:
      if Assigned(SetProcessDpiAwarenessContext) then
        SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  end;
end;

class function THighDPIManager.GetCurrentDPI: Integer;
begin
  Result := FCurrentDPI;
end;

class function THighDPIManager.GetDPIForMonitor(Monitor: HMONITOR): TDPIInfo;
begin
  Result.MonitorHandle := Monitor;
  Result.DPIValue := GetMonitorDPI(Monitor);
  Result.ScaleFactor := Result.DPIValue / FBaseDPI;
  Result.ScaleFactorX := Result.ScaleFactor;
  Result.ScaleFactorY := Result.ScaleFactor;
  Result.IsHighDPI := Result.DPIValue > FBaseDPI;
end;

class function THighDPIManager.GetDPIForWindow(Window: HWND): TDPIInfo;
var
  Monitor: HMONITOR;
  DPI: UINT;
begin
  if Assigned(GetDPIForWindow) then
  begin
    DPI := GetDPIForWindow(Window);
    Result.DPIValue := DPI;
  end
  else
  begin
    Monitor := MonitorFromWindow(Window, MONITOR_DEFAULTTONEAREST);
    Result := GetDPIForMonitor(Monitor);
  end;
  
  Result.ScaleFactor := Result.DPIValue / FBaseDPI;
  Result.ScaleFactorX := Result.ScaleFactor;
  Result.ScaleFactorY := Result.ScaleFactor;
  Result.IsHighDPI := Result.DPIValue > FBaseDPI;
end;

class function THighDPIManager.GetDPIForForm(Form: TForm): TDPIInfo;
begin
  if Assigned(Form) and Form.HandleAllocated then
    Result := GetDPIForWindow(Form.Handle)
  else
  begin
    Result.DPIValue := FCurrentDPI;
    Result.ScaleFactor := FCurrentDPI / FBaseDPI;
    Result.ScaleFactorX := Result.ScaleFactor;
    Result.ScaleFactorY := Result.ScaleFactor;
    Result.IsHighDPI := FCurrentDPI > FBaseDPI;
    Result.MonitorHandle := 0;
  end;
end;

class function THighDPIManager.ScaleValue(Value: Integer; TargetDPI: Integer): Integer;
var
  DPI: Integer;
begin
  if TargetDPI = 0 then
    DPI := FCurrentDPI
  else
    DPI := TargetDPI;
    
  Result := MulDiv(Value, DPI, FBaseDPI);
end;

class function THighDPIManager.ScaleValue(Value: Single; TargetDPI: Integer): Single;
var
  DPI: Integer;
begin
  if TargetDPI = 0 then
    DPI := FCurrentDPI
  else
    DPI := TargetDPI;
    
  Result := Value * (DPI / FBaseDPI);
end;

class function THighDPIManager.ScaleSize(const Size: TSize; TargetDPI: Integer): TSize;
begin
  Result.cx := ScaleValue(Size.cx, TargetDPI);
  Result.cy := ScaleValue(Size.cy, TargetDPI);
end;

class function THighDPIManager.ScaleRect(const Rect: TRect; TargetDPI: Integer): TRect;
begin
  Result.Left := ScaleValue(Rect.Left, TargetDPI);
  Result.Top := ScaleValue(Rect.Top, TargetDPI);
  Result.Right := ScaleValue(Rect.Right, TargetDPI);
  Result.Bottom := ScaleValue(Rect.Bottom, TargetDPI);
end;

class function THighDPIManager.ScalePoint(const Point: TPoint; TargetDPI: Integer): TPoint;
begin
  Result.X := ScaleValue(Point.X, TargetDPI);
  Result.Y := ScaleValue(Point.Y, TargetDPI);
end;

class function THighDPIManager.UnscaleValue(Value: Integer; SourceDPI: Integer): Integer;
var
  DPI: Integer;
begin
  if SourceDPI = 0 then
    DPI := FCurrentDPI
  else
    DPI := SourceDPI;
    
  Result := MulDiv(Value, FBaseDPI, DPI);
end;

class function THighDPIManager.UnscaleValue(Value: Single; SourceDPI: Integer): Single;
var
  DPI: Integer;
begin
  if SourceDPI = 0 then
    DPI := FCurrentDPI
  else
    DPI := SourceDPI;
    
  Result := Value * (FBaseDPI / DPI);
end;

class function THighDPIManager.UnscaleSize(const Size: TSize; SourceDPI: Integer): TSize;
begin
  Result.cx := UnscaleValue(Size.cx, SourceDPI);
  Result.cy := UnscaleValue(Size.cy, SourceDPI);
end;

class function THighDPIManager.UnscaleRect(const Rect: TRect; SourceDPI: Integer): TRect;
begin
  Result.Left := UnscaleValue(Rect.Left, SourceDPI);
  Result.Top := UnscaleValue(Rect.Top, SourceDPI);
  Result.Right := UnscaleValue(Rect.Right, SourceDPI);
  Result.Bottom := UnscaleValue(Rect.Bottom, SourceDPI);
end;

class procedure THighDPIManager.ScaleBitmap(Source, Target: TBitmap; NewWidth, NewHeight: Integer; Mode: TScalingMode);
begin
  Target.Width := NewWidth;
  Target.Height := NewHeight;
  Target.PixelFormat := Source.PixelFormat;
  
  case Mode of
    smNone:
      Target.Canvas.Draw(0, 0, Source);
    smLinear, smSmooth:
    begin
      SetStretchBltMode(Target.Canvas.Handle, HALFTONE);
      Target.Canvas.StretchDraw(Rect(0, 0, NewWidth, NewHeight), Source);
    end;
    smSharp:
    begin
      SetStretchBltMode(Target.Canvas.Handle, COLORONCOLOR);
      Target.Canvas.StretchDraw(Rect(0, 0, NewWidth, NewHeight), Source);
    end;
  end;
end;

class function THighDPIManager.CreateScaledBitmap(Source: TBitmap; ScaleFactor: Single; Mode: TScalingMode): TBitmap;
var
  NewWidth, NewHeight: Integer;
begin
  NewWidth := Round(Source.Width * ScaleFactor);
  NewHeight := Round(Source.Height * ScaleFactor);
  
  Result := TBitmap.Create;
  try
    ScaleBitmap(Source, Result, NewWidth, NewHeight, Mode);
  except
    Result.Free;
    raise;
  end;
end;

class function THighDPIManager.CreateDPIAwareBitmap(Source: TBitmap; TargetDPI: Integer; Mode: TScalingMode): TBitmap;
var
  ScaleFactor: Single;
begin
  ScaleFactor := TargetDPI / FBaseDPI;
  Result := CreateScaledBitmap(Source, ScaleFactor, Mode);
end;

class function THighDPIManager.ScaleFont(Font: TFont; TargetDPI: Integer): TFont;
begin
  Result := TFont.Create;
  Result.Assign(Font);
  ApplyDPIToFont(Result, TargetDPI);
end;

class procedure THighDPIManager.ApplyDPIToFont(Font: TFont; TargetDPI: Integer);
var
  LogFont: TLogFont;
  DPI: Integer;
begin
  if TargetDPI = 0 then
    DPI := FCurrentDPI
  else
    DPI := TargetDPI;
    
  if GetObject(Font.Handle, SizeOf(LogFont), @LogFont) <> 0 then
  begin
    LogFont.lfHeight := MulDiv(LogFont.lfHeight, DPI, FBaseDPI);
    Font.Handle := CreateFontIndirect(LogFont);
  end;
end;

class procedure THighDPIManager.RegisterDPIChangeCallback(Callback: TNotifyEvent);
begin
  if FCallbacks.IndexOf(TMethod(Callback)) = -1 then
    FCallbacks.Add(Callback);
end;

class procedure THighDPIManager.UnregisterDPIChangeCallback(Callback: TNotifyEvent);
begin
  FCallbacks.Remove(Callback);
end;

class procedure THighDPIManager.NotifyDPIChange;
var
  Callback: TNotifyEvent;
begin
  for Callback in FCallbacks do
  begin
    try
      Callback(nil);
    except
      // Ігноруємо помилки в callback'ах
    end;
  end;
end;

{ TDPIAwareComponent }

constructor TDPIAwareComponent.Create(AOwner: TComponent);
begin
  inherited;
  
  FBaseDPI := 96;
  FCurrentDPI := THighDPIManager.CurrentDPI;
  FAutoScaleDPI := True;
  FScalingMode := smSmooth;
  
  THighDPIManager.RegisterDPIChangeCallback(HandleDPIChange);
end;

destructor TDPIAwareComponent.Destroy;
begin
  THighDPIManager.UnregisterDPIChangeCallback(HandleDPIChange);
  inherited;
end;

procedure TDPIAwareComponent.SetParent(AParent: TComponent);
begin
  inherited;
  
  if FAutoScaleDPI then
    UpdateDPI;
end;

procedure TDPIAwareComponent.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  
  if (Operation = opRemove) and (AComponent = Owner) and FAutoScaleDPI then
    UpdateDPI;
end;

procedure TDPIAwareComponent.HandleDPIChange(Sender: TObject);
begin
  if FAutoScaleDPI then
    UpdateDPI;
end;

procedure TDPIAwareComponent.DPIChanged(NewDPI: Integer);
begin
  FCurrentDPI := NewDPI;
  ScaleForDPI(NewDPI);
  
  if Assigned(FOnDPIChanged) then
    FOnDPIChanged(Self);
end;

procedure TDPIAwareComponent.ScaleForDPI(NewDPI: Integer);
begin
  // Базова реалізація - переопределити в нащадках
end;

procedure TDPIAwareComponent.UpdateDPI;
var
  NewDPI: Integer;
  Form: TForm;
begin
  NewDPI := THighDPIManager.CurrentDPI;
  
  // Спробуємо отримати DPI з форми-власника
  if Owner is TForm then
  begin
    Form := TForm(Owner);
    if Form.HandleAllocated then
      NewDPI := THighDPIManager.GetDPIForForm(Form).DPIValue;
  end;
  
  if NewDPI <> FCurrentDPI then
    DPIChanged(NewDPI);
end;

function TDPIAwareComponent.GetEffectiveDPI: Integer;
begin
  Result := FCurrentDPI;
end;

function TDPIAwareComponent.GetScaleFactor: Single;
begin
  Result := FCurrentDPI / FBaseDPI;
end;

{ TDPIAwareControl }

constructor TDPIAwareControl.Create(AOwner: TComponent);
begin
  inherited;
  
  FBaseDPI := 96;
  FCurrentDPI := THighDPIManager.CurrentDPI;
  FAutoScaleDPI := True;
  FScalingMode := smSmooth;
  
  THighDPIManager.RegisterDPIChangeCallback(HandleDPIChange);
end;

destructor TDPIAwareControl.Destroy;
begin
  THighDPIManager.UnregisterDPIChangeCallback(HandleDPIChange);
  inherited;
end;

procedure TDPIAwareControl.CreateParams(var Params: TCreateParams);
begin
  inherited;
  
  // Додаємо DPI awareness до параметрів вікна
  if THighDPIManager.Awareness in [daPerMonitorAware, daPerMonitorV2Aware] then
  begin
    Params.ExStyle := Params.ExStyle or WS_EX_TOPMOST;
  end;
end;

procedure TDPIAwareControl.SetParent(AParent: TWinControl);
begin
  inherited;
  
  if FAutoScaleDPI then
    UpdateDPI;
end;

procedure TDPIAwareControl.HandleDPIChange(Sender: TObject);
begin
  if FAutoScaleDPI then
    UpdateDPI;
end;

procedure TDPIAwareControl.WMDPIChanged(var Message: TWMDpi);
begin
  if FAutoScaleDPI then
    DPIChanged(Message.XDpi);
    
  inherited;
end;

procedure TDPIAwareControl.DPIChanged(NewDPI: Integer);
begin
  FCurrentDPI := NewDPI;
  ScaleForDPI(NewDPI);
  
  if Assigned(FOnDPIChanged) then
    FOnDPIChanged(Self);
end;

procedure TDPIAwareControl.ScaleForDPI(NewDPI: Integer);
begin
  // Базова реалізація - переопределити в нащадках
end;

procedure TDPIAwareControl.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited;
  
  if isDpiChange then
  begin
    FCurrentDPI := MulDiv(FCurrentDPI, M, D);
    if Assigned(FOnDPIChanged) then
      FOnDPIChanged(Self);
  end;
end;

procedure TDPIAwareControl.UpdateDPI;
var
  NewDPI: Integer;
  DPIInfo: TDPIInfo;
begin
  if HandleAllocated then
  begin
    DPIInfo := THighDPIManager.GetDPIForWindow(Handle);
    NewDPI := DPIInfo.DPIValue;
  end
  else
    NewDPI := THighDPIManager.CurrentDPI;
    
  if NewDPI <> FCurrentDPI then
    DPIChanged(NewDPI);
end;

function TDPIAwareControl.GetEffectiveDPI: Integer;
begin
  Result := FCurrentDPI;
end;

function TDPIAwareControl.GetScaleFactor: Single;
begin
  Result := FCurrentDPI / FBaseDPI;
end;

{ THiDPIUtils }

class function THiDPIUtils.GetSystemMetricsForDPI(nIndex: Integer; dpi: UINT): Integer;
begin
  if Assigned(HighDPISupport.GetSystemMetricsForDPI) then
    Result := HighDPISupport.GetSystemMetricsForDPI(nIndex, dpi)
  else
    Result := GetSystemMetrics(nIndex);
end;

class function THiDPIUtils.AdjustWindowRectExForDPI(var lpRect: TRect; dwStyle: DWORD; bMenu: BOOL; dwExStyle: DWORD; dpi: UINT): BOOL;
begin
  if Assigned(HighDPISupport.AdjustWindowRectExForDPI) then
    Result := HighDPISupport.AdjustWindowRectExForDPI(lpRect, dwStyle, bMenu, dwExStyle, dpi)
  else
    Result := AdjustWindowRectEx(lpRect, dwStyle, bMenu, dwExStyle);
end;

class function THiDPIUtils.SystemParametersInfoForDPI(uiAction, uiParam: UINT; pvParam: Pointer; fWinIni: UINT; dpi: UINT): BOOL;
begin
  if Assigned(HighDPISupport.SystemParametersInfoForDPI) then
    Result := HighDPISupport.SystemParametersInfoForDPI(uiAction, uiParam, pvParam, fWinIni, dpi)
  else
    Result := SystemParametersInfo(uiAction, uiParam, pvParam, fWinIni);
end;

class function THiDPIUtils.GetDPIForWindow(hwnd: HWND): UINT;
begin
  if Assigned(HighDPISupport.GetDPIForWindow) then
    Result := HighDPISupport.GetDPIForWindow(hwnd)
  else
    Result := 96;
end;

class function THiDPIUtils.GetDPIForMonitor(hmonitor: HMONITOR; dpiType: Integer; out dpiX, dpiY: UINT): HRESULT;
begin
  if Assigned(HighDPISupport.GetDPIForMonitor) then
    Result := HighDPISupport.GetDPIForMonitor(hmonitor, dpiType, dpiX, dpiY)
  else
  begin
    dpiX := 96;
    dpiY := 96;
    Result := S_OK;
  end;
end;

class function THiDPIUtils.SetProcessDPIAware: BOOL;
begin
  if Assigned(HighDPISupport.SetProcessDPIAware) then
    Result := HighDPISupport.SetProcessDPIAware
  else
    Result := False;
end;

class function THiDPIUtils.SetProcessDpiAwareness(value: Integer): HRESULT;
begin
  if Assigned(HighDPISupport.SetProcessDpiAwareness) then
    Result := HighDPISupport.SetProcessDpiAwareness(value)
  else
    Result := E_NOTIMPL;
end;

class function THiDPIUtils.SetProcessDpiAwarenessContext(value: Pointer): BOOL;
begin
  if Assigned(HighDPISupport.SetProcessDpiAwarenessContext) then
    Result := HighDPISupport.SetProcessDpiAwarenessContext(value)
  else
    Result := False;
end;

class function THiDPIUtils.IsWindows8Point1OrGreater: Boolean;
begin
  Result := (Win32MajorVersion > 6) or 
           ((Win32MajorVersion = 6) and (Win32MinorVersion >= 3));
end;

class function THiDPIUtils.IsWindows10OrGreater: Boolean;
begin
  Result := Win32MajorVersion >= 10;
end;

class function THiDPIUtils.IsPerMonitorDPIAware: Boolean;
begin
  Result := THighDPIManager.Awareness in [daPerMonitorAware, daPerMonitorV2Aware];
end;

initialization
  InitializeDPIAPI;

end.