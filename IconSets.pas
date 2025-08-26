unit IconSets;

interface

uses
  Windows, Classes, Graphics, SysUtils, Types, Generics.Collections, 
  Generics.Defaults, IniFiles, Registry, SVGRenderer;

type
  // Типи іконок
  TIconSetType = (istMaterial, istFeather, istFontAwesome, istBootstrap, istTabler, 
                  istHeroicons, istPhosphor, istLucide, istCustom);
  
  // Стилі іконок для кожного набору
  TIconStyle = (isOutlined, isFilled, isRounded, isSharp, isTwoTone, isLight, isRegular, isBold);
  
  // Категорії іконок
  TIconCategory = (icAction, icAlert, icAV, icCommunication, icContent, icDevice, 
                   icEditor, icFile, icHardware, icImage, icMaps, icNavigation,
                   icNotification, icSocial, icToggle, icInterface, icArrows, icBrands);

  // Інформація про іконку
  TIconInfo = record
    Name: string;
    DisplayName: string;
    Description: string;
    Category: TIconCategory;
    Tags: TArray<string>;
    SVGData: string;
    Available: Boolean;
    IsPremium: Boolean;
    Version: string;
  end;

  // Набір іконок
  TIconSet = class
  private
    FName: string;
    FDisplayName: string;
    FDescription: string;
    FVersion: string;
    FSetType: TIconSetType;
    FAuthor: string;
    FWebsite: string;
    FLicense: string;
    FSupportedStyles: TArray<TIconStyle>;
    FIcons: TDictionary<string, TIconInfo>;
    FCategories: TDictionary<TIconCategory, TStringList>;
    FDefaultStyle: TIconStyle;
    FBasePath: string;
    
    procedure LoadIconsFromDirectory(const Directory: string);
    procedure LoadIconsFromResource(const ResourceName: string);
    procedure IndexIconsByCategory;
    function GetIconCount: Integer;
  public
    constructor Create(const AName: string; ASetType: TIconSetType);
    destructor Destroy; override;
    
    procedure LoadFromDirectory(const Directory: string);
    procedure LoadFromResource(const ResourceName: string);
    procedure LoadFromConfig(const ConfigFile: string);
    
    function GetIcon(const IconName: string; Style: TIconStyle = isOutlined): TIconInfo;
    function HasIcon(const IconName: string): Boolean;
    function GetIconsByCategory(Category: TIconCategory): TStringList;
    function SearchIcons(const SearchTerm: string): TArray<TIconInfo>;
    function GetIconSVG(const IconName: string; Style: TIconStyle = isOutlined): string;
    
    procedure AddIcon(const IconInfo: TIconInfo);
    procedure RemoveIcon(const IconName: string);
    procedure UpdateIcon(const IconName: string; const IconInfo: TIconInfo);
    
    // Властивості
    property Name: string read FName;
    property DisplayName: string read FDisplayName write FDisplayName;
    property Description: string read FDescription write FDescription;
    property Version: string read FVersion write FVersion;
    property SetType: TIconSetType read FSetType;
    property Author: string read FAuthor write FAuthor;
    property Website: string read FWebsite write FWebsite;
    property License: string read FLicense write FLicense;
    property SupportedStyles: TArray<TIconStyle> read FSupportedStyles write FSupportedStyles;
    property DefaultStyle: TIconStyle read FDefaultStyle write FDefaultStyle;
    property IconCount: Integer read GetIconCount;
    property BasePath: string read FBasePath write FBasePath;
  end;

  // Менеджер наборів іконок
  TIconSetsManager = class
  private
    class var FInstance: TIconSetsManager;
    FIconSets: TObjectDictionary<string, TIconSet>;
    FActiveSet: string;
    FTheme: string; // 'light', 'dark', 'auto'
    FConfigPath: string;
    FDefaultSize: Integer;
    FOnIconSetChanged: TNotifyEvent;
    
    procedure LoadBuiltInIconSets;
    procedure LoadUserIconSets;
    procedure SaveConfiguration;
    procedure LoadConfiguration;
  public
    constructor Create;
    destructor Destroy; override;
    
    class function GetInstance: TIconSetsManager;
    class procedure ReleaseInstance;
    
    // Управління наборами іконок
    procedure RegisterIconSet(IconSet: TIconSet);
    procedure UnregisterIconSet(const SetName: string);
    function GetIconSet(const SetName: string): TIconSet;
    function GetAvailableIconSets: TArray<string>;
    
    // Активний набір іконок
    procedure SetActiveIconSet(const SetName: string);
    function GetActiveIconSet: TIconSet;
    
    // Отримання іконок
    function GetIcon(const IconName: string; Style: TIconStyle = isOutlined): TIconInfo; overload;
    function GetIcon(const IconName: string; const SetName: string; Style: TIconStyle = isOutlined): TIconInfo; overload;
    function GetIconSVG(const IconName: string; Size: Integer = 0; Theme: string = ''): string; overload;
    function GetIconSVG(const IconName: string; const SetName: string; Size: Integer = 0; Theme: string = ''): string; overload;
    function GetIconBitmap(const IconName: string; Size: Integer; Theme: string = ''): TBitmap;
    
    // Пошук іконок
    function SearchIcons(const SearchTerm: string): TArray<TIconInfo>; overload;
    function SearchIcons(const SearchTerm: string; const SetName: string): TArray<TIconInfo>; overload;
    function GetIconsByCategory(Category: TIconCategory): TArray<TIconInfo>;
    
    // Завантаження іконок з різних джерел
    procedure LoadIconSetFromDirectory(const SetName, Directory: string; SetType: TIconSetType);
    procedure LoadIconSetFromResource(const SetName, ResourceName: string; SetType: TIconSetType);
    procedure LoadIconSetFromURL(const SetName, URL: string; SetType: TIconSetType);
    
    // Налаштування
    procedure SetTheme(const Theme: string);
    procedure SetDefaultSize(Size: Integer);
    
    // Властивості
    property ActiveSet: string read FActiveSet write SetActiveIconSet;
    property Theme: string read FTheme write SetTheme;
    property DefaultSize: Integer read FDefaultSize write SetDefaultSize;
    property ConfigPath: string read FConfigPath write FConfigPath;
    property OnIconSetChanged: TNotifyEvent read FOnIconSetChanged write FOnIconSetChanged;
  end;

  // Фабрика наборів іконок
  TIconSetFactory = class
  public
    class function CreateMaterialIconSet: TIconSet;
    class function CreateFeatherIconSet: TIconSet;
    class function CreateFontAwesomeIconSet: TIconSet;
    class function CreateBootstrapIconSet: TIconSet;
    class function CreateTablerIconSet: TIconSet;
    class function CreateHeroiconsIconSet: TIconSet;
    class function CreatePhosphorIconSet: TIconSet;
    class function CreateLucideIconSet: TIconSet;
    class function CreateCustomIconSet(const Name, ConfigFile: string): TIconSet;
  end;

  // Утилітарні функції
  TIconUtils = class
  public
    class function CategoryToString(Category: TIconCategory): string;
    class function StringToCategory(const CategoryName: string): TIconCategory;
    class function StyleToString(Style: TIconStyle): string;
    class function StringToStyle(const StyleName: string): TIconStyle;
    class function SetTypeToString(SetType: TIconSetType): string;
    class function StringToSetType(const TypeName: string): TIconSetType;
    class function GetIconFileName(const IconName: string; Style: TIconStyle; SetType: TIconSetType): string;
    class function ApplyThemeToSVG(const SVGData: string; const Theme: string): string;
    class function ResizeSVGIcon(const SVGData: string; NewSize: Integer): string;
  end;

const
  // Стандартні розміри іконок
  ICON_SIZE_SMALL = 16;
  ICON_SIZE_MEDIUM = 24;
  ICON_SIZE_LARGE = 32;
  ICON_SIZE_XLARGE = 48;

implementation

uses
  StrUtils, IOUtils, JSON, NetHTTPClient, NetHTTPClientComponent, XMLDoc, XMLIntf;

{ TIconSet }

constructor TIconSet.Create(const AName: string; ASetType: TIconSetType);
begin
  inherited Create;
  
  FName := AName;
  FSetType := ASetType;
  FIcons := TDictionary<string, TIconInfo>.Create;
  FCategories := TDictionary<TIconCategory, TStringList>.Create;
  FDefaultStyle := isOutlined;
  
  // Ініціалізуємо категорії
  var Category: TIconCategory;
  for Category := Low(TIconCategory) to High(TIconCategory) do
    FCategories.Add(Category, TStringList.Create);
end;

destructor TIconSet.Destroy;
var
  CategoryList: TStringList;
begin
  FIcons.Free;
  
  for CategoryList in FCategories.Values do
    CategoryList.Free;
  FCategories.Free;
  
  inherited;
end;

procedure TIconSet.LoadFromDirectory(const Directory: string);
begin
  FBasePath := Directory;
  LoadIconsFromDirectory(Directory);
  IndexIconsByCategory;
end;

procedure TIconSet.LoadFromResource(const ResourceName: string);
begin
  LoadIconsFromResource(ResourceName);
  IndexIconsByCategory;
end;

procedure TIconSet.LoadFromConfig(const ConfigFile: string);
var
  IniFile: TIniFile;
  Sections: TStringList;
  I: Integer;
  IconInfo: TIconInfo;
  IconName: string;
begin
  if not FileExists(ConfigFile) then
    Exit;
    
  IniFile := TIniFile.Create(ConfigFile);
  Sections := TStringList.Create;
  try
    // Загальна інформація про набір
    FDisplayName := IniFile.ReadString('General', 'DisplayName', FName);
    FDescription := IniFile.ReadString('General', 'Description', '');
    FVersion := IniFile.ReadString('General', 'Version', '1.0');
    FAuthor := IniFile.ReadString('General', 'Author', '');
    FWebsite := IniFile.ReadString('General', 'Website', '');
    FLicense := IniFile.ReadString('General', 'License', '');
    
    // Завантажуємо іконки
    IniFile.ReadSections(Sections);
    for I := 0 to Sections.Count - 1 do
    begin
      IconName := Sections[I];
      if IconName = 'General' then
        Continue;
        
      IconInfo.Name := IconName;
      IconInfo.DisplayName := IniFile.ReadString(IconName, 'DisplayName', IconName);
      IconInfo.Description := IniFile.ReadString(IconName, 'Description', '');
      IconInfo.Category := TIconUtils.StringToCategory(IniFile.ReadString(IconName, 'Category', 'Interface'));
      IconInfo.SVGData := IniFile.ReadString(IconName, 'SVG', '');
      IconInfo.Available := IniFile.ReadBool(IconName, 'Available', True);
      IconInfo.IsPremium := IniFile.ReadBool(IconName, 'Premium', False);
      IconInfo.Version := IniFile.ReadString(IconName, 'Version', FVersion);
      
      // Завантажуємо теги
      var TagsStr := IniFile.ReadString(IconName, 'Tags', '');
      if TagsStr <> '' then
        IconInfo.Tags := TagsStr.Split([',', ';'])
      else
        IconInfo.Tags := [];
        
      AddIcon(IconInfo);
    end;
  finally
    Sections.Free;
    IniFile.Free;
  end;
  
  IndexIconsByCategory;
end;

procedure TIconSet.LoadIconsFromDirectory(const Directory: string);
var
  Files: TArray<string>;
  FileName, IconName, SVGContent: string;
  IconInfo: TIconInfo;
  FileStream: TFileStream;
  StringStream: TStringStream;
begin
  if not TDirectory.Exists(Directory) then
    Exit;
    
  Files := TDirectory.GetFiles(Directory, '*.svg', TSearchOption.soAllDirectories);
  
  for FileName in Files do
  begin
    IconName := TPath.GetFileNameWithoutExtension(FileName);
    IconName := StringReplace(IconName, '_', '-', [rfReplaceAll]);
    
    // Читаємо SVG файл
    FileStream := TFileStream.Create(FileName, fmOpenRead);
    try
      StringStream := TStringStream.Create('', TEncoding.UTF8);
      try
        StringStream.CopyFrom(FileStream, FileStream.Size);
        SVGContent := StringStream.DataString;
      finally
        StringStream.Free;
      end;
    finally
      FileStream.Free;
    end;
    
    // Створюємо інформацію про іконку
    IconInfo.Name := IconName;
    IconInfo.DisplayName := IconName;
    IconInfo.Description := '';
    IconInfo.Category := icInterface; // За замовчуванням
    IconInfo.Tags := [IconName];
    IconInfo.SVGData := SVGContent;
    IconInfo.Available := True;
    IconInfo.IsPremium := False;
    IconInfo.Version := FVersion;
    
    AddIcon(IconInfo);
  end;
end;

procedure TIconSet.LoadIconsFromResource(const ResourceName: string);
var
  ResourceStream: TResourceStream;
  StringStream: TStringStream;
  JSONValue: TJSONValue;
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
  I: Integer;
  IconInfo: TIconInfo;
begin
  try
    ResourceStream := TResourceStream.Create(HInstance, ResourceName, RT_RCDATA);
    try
      StringStream := TStringStream.Create('', TEncoding.UTF8);
      try
        StringStream.CopyFrom(ResourceStream, ResourceStream.Size);
        
        JSONValue := TJSONObject.ParseJSONValue(StringStream.DataString);
        try
          if JSONValue is TJSONArray then
          begin
            JSONArray := TJSONArray(JSONValue);
            for I := 0 to JSONArray.Count - 1 do
            begin
              if JSONArray.Items[I] is TJSONObject then
              begin
                JSONObject := TJSONObject(JSONArray.Items[I]);
                
                IconInfo.Name := JSONObject.GetValue('name').Value;
                IconInfo.DisplayName := JSONObject.GetValue('displayName').Value;
                IconInfo.Description := JSONObject.GetValue('description').Value;
                IconInfo.Category := TIconUtils.StringToCategory(JSONObject.GetValue('category').Value);
                IconInfo.SVGData := JSONObject.GetValue('svg').Value;
                IconInfo.Available := JSONObject.GetValue('available').Value = 'true';
                IconInfo.IsPremium := JSONObject.GetValue('premium').Value = 'true';
                IconInfo.Version := JSONObject.GetValue('version').Value;
                
                // Теги
                var TagsArray := JSONObject.GetValue('tags') as TJSONArray;
                if Assigned(TagsArray) then
                begin
                  SetLength(IconInfo.Tags, TagsArray.Count);
                  for var J := 0 to TagsArray.Count - 1 do
                    IconInfo.Tags[J] := TagsArray.Items[J].Value;
                end
                else
                  IconInfo.Tags := [];
                
                AddIcon(IconInfo);
              end;
            end;
          end;
        finally
          JSONValue.Free;
        end;
      finally
        StringStream.Free;
      end;
    finally
      ResourceStream.Free;
    end;
  except
    // Ігноруємо помилки завантаження ресурсів
  end;
end;

procedure TIconSet.IndexIconsByCategory;
var
  IconInfo: TIconInfo;
  CategoryList: TStringList;
begin
  // Очищуємо існуючі індекси
  for CategoryList in FCategories.Values do
    CategoryList.Clear;
    
  // Індексуємо всі іконки за категоріями
  for IconInfo in FIcons.Values do
  begin
    if FCategories.TryGetValue(IconInfo.Category, CategoryList) then
      CategoryList.Add(IconInfo.Name);
  end;
end;

function TIconSet.GetIconCount: Integer;
begin
  Result := FIcons.Count;
end;

function TIconSet.GetIcon(const IconName: string; Style: TIconStyle): TIconInfo;
begin
  if not FIcons.TryGetValue(IconName, Result) then
  begin
    // Повертаємо порожню іконку
    FillChar(Result, SizeOf(Result), 0);
    Result.Available := False;
  end;
end;

function TIconSet.HasIcon(const IconName: string): Boolean;
begin
  Result := FIcons.ContainsKey(IconName);
end;

function TIconSet.GetIconsByCategory(Category: TIconCategory): TStringList;
begin
  if FCategories.TryGetValue(Category, Result) then
    Result := TStringList(Result.Clone)
  else
    Result := TStringList.Create;
end;

function TIconSet.SearchIcons(const SearchTerm: string): TArray<TIconInfo>;
var
  IconInfo: TIconInfo;
  Results: TList<TIconInfo>;
  SearchLower: string;
  Tag: string;
begin
  Results := TList<TIconInfo>.Create;
  try
    SearchLower := LowerCase(SearchTerm);
    
    for IconInfo in FIcons.Values do
    begin
      // Пошук в назві
      if Pos(SearchLower, LowerCase(IconInfo.Name)) > 0 then
      begin
        Results.Add(IconInfo);
        Continue;
      end;
      
      // Пошук в описі
      if Pos(SearchLower, LowerCase(IconInfo.Description)) > 0 then
      begin
        Results.Add(IconInfo);
        Continue;
      end;
      
      // Пошук в тегах
      for Tag in IconInfo.Tags do
      begin
        if Pos(SearchLower, LowerCase(Tag)) > 0 then
        begin
          Results.Add(IconInfo);
          Break;
        end;
      end;
    end;
    
    Result := Results.ToArray;
  finally
    Results.Free;
  end;
end;

function TIconSet.GetIconSVG(const IconName: string; Style: TIconStyle): string;
var
  IconInfo: TIconInfo;
begin
  IconInfo := GetIcon(IconName, Style);
  Result := IconInfo.SVGData;
end;

procedure TIconSet.AddIcon(const IconInfo: TIconInfo);
begin
  FIcons.AddOrSetValue(IconInfo.Name, IconInfo);
end;

procedure TIconSet.RemoveIcon(const IconName: string);
begin
  FIcons.Remove(IconName);
end;

procedure TIconSet.UpdateIcon(const IconName: string; const IconInfo: TIconInfo);
begin
  if FIcons.ContainsKey(IconName) then
    FIcons.AddOrSetValue(IconName, IconInfo);
end;

{ TIconSetsManager }

constructor TIconSetsManager.Create;
begin
  inherited;
  
  FIconSets := TObjectDictionary<string, TIconSet>.Create([doOwnsValues]);
  FActiveSet := 'material';
  FTheme := 'auto';
  FDefaultSize := ICON_SIZE_MEDIUM;
  FConfigPath := TPath.Combine(TPath.GetDocumentsPath, 'IconSets');
  
  LoadBuiltInIconSets;
  LoadUserIconSets;
  LoadConfiguration;
end;

destructor TIconSetsManager.Destroy;
begin
  SaveConfiguration;
  FIconSets.Free;
  inherited;
end;

class function TIconSetsManager.GetInstance: TIconSetsManager;
begin
  if not Assigned(FInstance) then
    FInstance := TIconSetsManager.Create;
  Result := FInstance;
end;

class procedure TIconSetsManager.ReleaseInstance;
begin
  if Assigned(FInstance) then
  begin
    FInstance.Free;
    FInstance := nil;
  end;
end;

procedure TIconSetsManager.LoadBuiltInIconSets;
begin
  RegisterIconSet(TIconSetFactory.CreateMaterialIconSet);
  RegisterIconSet(TIconSetFactory.CreateFeatherIconSet);
  RegisterIconSet(TIconSetFactory.CreateFontAwesomeIconSet);
  RegisterIconSet(TIconSetFactory.CreateBootstrapIconSet);
  RegisterIconSet(TIconSetFactory.CreateTablerIconSet);
  RegisterIconSet(TIconSetFactory.CreateHeroiconsIconSet);
  RegisterIconSet(TIconSetFactory.CreatePhosphorIconSet);
  RegisterIconSet(TIconSetFactory.CreateLucideIconSet);
end;

procedure TIconSetsManager.LoadUserIconSets;
var
  ConfigFiles: TArray<string>;
  ConfigFile: string;
  IconSet: TIconSet;
begin
  if not TDirectory.Exists(FConfigPath) then
    TDirectory.CreateDirectory(FConfigPath);
    
  ConfigFiles := TDirectory.GetFiles(FConfigPath, '*.ini');
  
  for ConfigFile in ConfigFiles do
  begin
    try
      IconSet := TIconSetFactory.CreateCustomIconSet(
        TPath.GetFileNameWithoutExtension(ConfigFile), 
        ConfigFile
      );
      RegisterIconSet(IconSet);
    except
      // Ігноруємо помилки завантаження
    end;
  end;
end;

procedure TIconSetsManager.SaveConfiguration;
var
  IniFile: TIniFile;
  ConfigFile: string;
begin
  ConfigFile := TPath.Combine(FConfigPath, 'settings.ini');
  IniFile := TIniFile.Create(ConfigFile);
  try
    IniFile.WriteString('General', 'ActiveSet', FActiveSet);
    IniFile.WriteString('General', 'Theme', FTheme);
    IniFile.WriteInteger('General', 'DefaultSize', FDefaultSize);
  finally
    IniFile.Free;
  end;
end;

procedure TIconSetsManager.LoadConfiguration;
var
  IniFile: TIniFile;
  ConfigFile: string;
begin
  ConfigFile := TPath.Combine(FConfigPath, 'settings.ini');
  
  if FileExists(ConfigFile) then
  begin
    IniFile := TIniFile.Create(ConfigFile);
    try
      FActiveSet := IniFile.ReadString('General', 'ActiveSet', 'material');
      FTheme := IniFile.ReadString('General', 'Theme', 'auto');
      FDefaultSize := IniFile.ReadInteger('General', 'DefaultSize', ICON_SIZE_MEDIUM);
    finally
      IniFile.Free;
    end;
  end;
end;

procedure TIconSetsManager.RegisterIconSet(IconSet: TIconSet);
begin
  if Assigned(IconSet) then
    FIconSets.AddOrSetValue(IconSet.Name, IconSet);
end;

procedure TIconSetsManager.UnregisterIconSet(const SetName: string);
begin
  FIconSets.Remove(SetName);
end;

function TIconSetsManager.GetIconSet(const SetName: string): TIconSet;
begin
  if not FIconSets.TryGetValue(SetName, Result) then
    Result := nil;
end;

function TIconSetsManager.GetAvailableIconSets: TArray<string>;
begin
  Result := FIconSets.Keys.ToArray;
end;

procedure TIconSetsManager.SetActiveIconSet(const SetName: string);
begin
  if FIconSets.ContainsKey(SetName) then
  begin
    FActiveSet := SetName;
    if Assigned(FOnIconSetChanged) then
      FOnIconSetChanged(Self);
  end;
end;

function TIconSetsManager.GetActiveIconSet: TIconSet;
begin
  Result := GetIconSet(FActiveSet);
end;

function TIconSetsManager.GetIcon(const IconName: string; Style: TIconStyle): TIconInfo;
var
  ActiveIconSet: TIconSet;
begin
  ActiveIconSet := GetActiveIconSet;
  if Assigned(ActiveIconSet) then
    Result := ActiveIconSet.GetIcon(IconName, Style)
  else
  begin
    FillChar(Result, SizeOf(Result), 0);
    Result.Available := False;
  end;
end;

function TIconSetsManager.GetIcon(const IconName: string; const SetName: string; Style: TIconStyle): TIconInfo;
var
  IconSet: TIconSet;
begin
  IconSet := GetIconSet(SetName);
  if Assigned(IconSet) then
    Result := IconSet.GetIcon(IconName, Style)
  else
  begin
    FillChar(Result, SizeOf(Result), 0);
    Result.Available := False;
  end;
end;

function TIconSetsManager.GetIconSVG(const IconName: string; Size: Integer; Theme: string): string;
var
  Icon: TIconInfo;
  EffectiveTheme: string;
  EffectiveSize: Integer;
begin
  Icon := GetIcon(IconName);
  
  if not Icon.Available then
  begin
    Result := '';
    Exit;
  end;
  
  Result := Icon.SVGData;
  
  // Застосовуємо тему
  EffectiveTheme := Theme;
  if EffectiveTheme = '' then
    EffectiveTheme := FTheme;
    
  Result := TIconUtils.ApplyThemeToSVG(Result, EffectiveTheme);
  
  // Застосовуємо розмір
  EffectiveSize := Size;
  if EffectiveSize = 0 then
    EffectiveSize := FDefaultSize;
    
  Result := TIconUtils.ResizeSVGIcon(Result, EffectiveSize);
end;

function TIconSetsManager.GetIconSVG(const IconName: string; const SetName: string; Size: Integer; Theme: string): string;
var
  Icon: TIconInfo;
  EffectiveTheme: string;
  EffectiveSize: Integer;
begin
  Icon := GetIcon(IconName, SetName);
  
  if not Icon.Available then
  begin
    Result := '';
    Exit;
  end;
  
  Result := Icon.SVGData;
  
  // Застосовуємо тему
  EffectiveTheme := Theme;
  if EffectiveTheme = '' then
    EffectiveTheme := FTheme;
    
  Result := TIconUtils.ApplyThemeToSVG(Result, EffectiveTheme);
  
  // Застосовуємо розмір
  EffectiveSize := Size;
  if EffectiveSize = 0 then
    EffectiveSize := FDefaultSize;
    
  Result := TIconUtils.ResizeSVGIcon(Result, EffectiveSize);
end;

function TIconSetsManager.GetIconBitmap(const IconName: string; Size: Integer; Theme: string): TBitmap;
var
  SVGData: string;
  SVGRenderer: TSVGRenderer;
begin
  SVGData := GetIconSVG(IconName, Size, Theme);
  
  if SVGData = '' then
  begin
    Result := nil;
    Exit;
  end;
  
  SVGRenderer := TSVGRenderer.Create;
  try
    SVGRenderer.LoadFromString(SVGData);
    
    Result := TBitmap.Create;
    SVGRenderer.RenderToBitmap(Result, Size, Size, clWhite);
  finally
    SVGRenderer.Free;
  end;
end;

function TIconSetsManager.SearchIcons(const SearchTerm: string): TArray<TIconInfo>;
var
  ActiveIconSet: TIconSet;
begin
  ActiveIconSet := GetActiveIconSet;
  if Assigned(ActiveIconSet) then
    Result := ActiveIconSet.SearchIcons(SearchTerm)
  else
    Result := [];
end;

function TIconSetsManager.SearchIcons(const SearchTerm: string; const SetName: string): TArray<TIconInfo>;
var
  IconSet: TIconSet;
begin
  IconSet := GetIconSet(SetName);
  if Assigned(IconSet) then
    Result := IconSet.SearchIcons(SearchTerm)
  else
    Result := [];
end;

function TIconSetsManager.GetIconsByCategory(Category: TIconCategory): TArray<TIconInfo>;
var
  ActiveIconSet: TIconSet;
  IconNames: TStringList;
  IconName: string;
  Results: TList<TIconInfo>;
begin
  ActiveIconSet := GetActiveIconSet;
  if not Assigned(ActiveIconSet) then
  begin
    Result := [];
    Exit;
  end;
  
  IconNames := ActiveIconSet.GetIconsByCategory(Category);
  Results := TList<TIconInfo>.Create;
  try
    for IconName in IconNames do
      Results.Add(ActiveIconSet.GetIcon(IconName));
      
    Result := Results.ToArray;
  finally
    Results.Free;
    IconNames.Free;
  end;
end;

procedure TIconSetsManager.LoadIconSetFromDirectory(const SetName, Directory: string; SetType: TIconSetType);
var
  IconSet: TIconSet;
begin
  IconSet := TIconSet.Create(SetName, SetType);
  IconSet.LoadFromDirectory(Directory);
  RegisterIconSet(IconSet);
end;

procedure TIconSetsManager.LoadIconSetFromResource(const SetName, ResourceName: string; SetType: TIconSetType);
var
  IconSet: TIconSet;
begin
  IconSet := TIconSet.Create(SetName, SetType);
  IconSet.LoadFromResource(ResourceName);
  RegisterIconSet(IconSet);
end;

procedure TIconSetsManager.LoadIconSetFromURL(const SetName, URL: string; SetType: TIconSetType);
// Завантаження іконок з URL (для майбутнього розширення)
begin
  // TODO: Реалізувати завантаження з URL
end;

procedure TIconSetsManager.SetTheme(const Theme: string);
begin
  FTheme := Theme;
  if Assigned(FOnIconSetChanged) then
    FOnIconSetChanged(Self);
end;

procedure TIconSetsManager.SetDefaultSize(Size: Integer);
begin
  FDefaultSize := Size;
end;

{ TIconSetFactory }

class function TIconSetFactory.CreateMaterialIconSet: TIconSet;
begin
  Result := TIconSet.Create('material', istMaterial);
  Result.DisplayName := 'Material Design Icons';
  Result.Description := 'Google''s Material Design icon set';
  Result.Version := '1.0';
  Result.Author := 'Google';
  Result.Website := 'https://material.io/icons/';
  Result.License := 'Apache License 2.0';
  Result.SupportedStyles := [isOutlined, isFilled, isRounded, isSharp, isTwoTone];
  Result.DefaultStyle := isOutlined;
  
  // Додаємо базові іконки Material Design
  var IconInfo: TIconInfo;
  
  IconInfo.Name := 'home';
  IconInfo.DisplayName := 'Home';
  IconInfo.Description := 'Home icon';
  IconInfo.Category := icNavigation;
  IconInfo.Tags := ['home', 'house', 'main'];
  IconInfo.SVGData := '<svg width="24" height="24" viewBox="0 0 24 24"><path d="M10,20V14H14V20H19V12H22L12,3L2,12H5V20H10Z"/></svg>';
  IconInfo.Available := True;
  IconInfo.IsPremium := False;
  IconInfo.Version := '1.0';
  Result.AddIcon(IconInfo);
  
  IconInfo.Name := 'settings';
  IconInfo.DisplayName := 'Settings';
  IconInfo.Description := 'Settings/configuration icon';
  IconInfo.Category := icAction;
  IconInfo.Tags := ['settings', 'config', 'preferences'];
  IconInfo.SVGData := '<svg width="24" height="24" viewBox="0 0 24 24"><path d="M12,15.5A3.5,3.5 0 0,1 8.5,12A3.5,3.5 0 0,1 12,8.5A3.5,3.5 0 0,1 15.5,12A3.5,3.5 0 0,1 12,15.5M19.43,12.97C19.47,12.65 19.5,12.33 19.5,12C19.5,11.67 19.47,11.34 19.43,11L21.54,9.37C21.73,9.22 21.78,8.95 21.66,8.73L19.66,5.27C19.54,5.05 19.27,4.96 19.05,5.05L16.56,6.05C16.04,5.66 15.5,5.32 14.87,5.07L14.5,2.42C14.46,2.18 14.25,2 14,2H10C9.75,2 9.54,2.18 9.5,2.42L9.13,5.07C8.5,5.32 7.96,5.66 7.44,6.05L4.95,5.05C4.73,4.96 4.46,5.05 4.34,5.27L2.34,8.73C2.22,8.95 2.27,9.22 2.46,9.37L4.57,11C4.53,11.34 4.5,11.67 4.5,12C4.5,12.33 4.53,12.65 4.57,12.97L2.46,14.63C2.27,14.78 2.22,15.05 2.34,15.27L4.34,18.73C4.46,18.95 4.73,19.03 4.95,18.95L7.44,17.94C7.96,18.34 8.5,18.68 9.13,18.93L9.5,21.58C9.54,21.82 9.75,22 10,22H14C14.25,22 14.46,21.82 14.5,21.58L14.87,18.93C15.5,18.68 16.04,18.34 16.56,17.94L19.05,18.95C19.27,19.03 19.54,18.95 19.66,18.73L21.66,15.27C21.78,15.05 21.73,14.78 21.54,14.63L19.43,12.97Z"/></svg>';
  IconInfo.Available := True;
  IconInfo.IsPremium := False;
  IconInfo.Version := '1.0';
  Result.AddIcon(IconInfo);
end;

class function TIconSetFactory.CreateFeatherIconSet: TIconSet;
begin
  Result := TIconSet.Create('feather', istFeather);
  Result.DisplayName := 'Feather Icons';
  Result.Description := 'Beautiful open source icons';
  Result.Version := '4.29.0';
  Result.Author := 'Cole Bemis';
  Result.Website := 'https://feathericons.com/';
  Result.License := 'MIT License';
  Result.SupportedStyles := [isOutlined];
  Result.DefaultStyle := isOutlined;
end;

class function TIconSetFactory.CreateFontAwesomeIconSet: TIconSet;
begin
  Result := TIconSet.Create('fontawesome', istFontAwesome);
  Result.DisplayName := 'Font Awesome';
  Result.Description := 'The world''s most popular icon set';
  Result.Version := '6.0';
  Result.Author := 'Fonticons';
  Result.Website := 'https://fontawesome.com/';
  Result.License := 'Font Awesome Free License';
  Result.SupportedStyles := [isLight, isRegular, isBold];
  Result.DefaultStyle := isRegular;
end;

class function TIconSetFactory.CreateBootstrapIconSet: TIconSet;
begin
  Result := TIconSet.Create('bootstrap', istBootstrap);
  Result.DisplayName := 'Bootstrap Icons';
  Result.Description := 'Official open source SVG icon library for Bootstrap';
  Result.Version := '1.8.0';
  Result.Author := 'Bootstrap Team';
  Result.Website := 'https://icons.getbootstrap.com/';
  Result.License := 'MIT License';
  Result.SupportedStyles := [isFilled];
  Result.DefaultStyle := isFilled;
end;

class function TIconSetFactory.CreateTablerIconSet: TIconSet;
begin
  Result := TIconSet.Create('tabler', istTabler);
  Result.DisplayName := 'Tabler Icons';
  Result.Description := 'Over 3000 free SVG icons';
  Result.Version := '2.0';
  Result.Author := 'Tabler';
  Result.Website := 'https://tabler-icons.io/';
  Result.License := 'MIT License';
  Result.SupportedStyles := [isOutlined, isFilled];
  Result.DefaultStyle := isOutlined;
end;

class function TIconSetFactory.CreateHeroiconsIconSet: TIconSet;
begin
  Result := TIconSet.Create('heroicons', istHeroicons);
  Result.DisplayName := 'Heroicons';
  Result.Description := 'Beautiful hand-crafted SVG icons by Tailwind CSS';
  Result.Version := '2.0';
  Result.Author := 'Tailwind CSS';
  Result.Website := 'https://heroicons.com/';
  Result.License := 'MIT License';
  Result.SupportedStyles := [isOutlined, isFilled];
  Result.DefaultStyle := isOutlined;
end;

class function TIconSetFactory.CreatePhosphorIconSet: TIconSet;
begin
  Result := TIconSet.Create('phosphor', istPhosphor);
  Result.DisplayName := 'Phosphor Icons';
  Result.Description := 'A flexible icon family for interfaces, diagrams, presentations';
  Result.Version := '2.0';
  Result.Author := 'Phosphor Icons';
  Result.Website := 'https://phosphoricons.com/';
  Result.License := 'MIT License';
  Result.SupportedStyles := [isLight, isRegular, isBold];
  Result.DefaultStyle := isRegular;
end;

class function TIconSetFactory.CreateLucideIconSet: TIconSet;
begin
  Result := TIconSet.Create('lucide', istLucide);
  Result.DisplayName := 'Lucide Icons';
  Result.Description := 'Beautiful & consistent icon toolkit made by the community';
  Result.Version := '0.260.0';
  Result.Author := 'Lucide Community';
  Result.Website := 'https://lucide.dev/';
  Result.License := 'ISC License';
  Result.SupportedStyles := [isOutlined];
  Result.DefaultStyle := isOutlined;
end;

class function TIconSetFactory.CreateCustomIconSet(const Name, ConfigFile: string): TIconSet;
begin
  Result := TIconSet.Create(Name, istCustom);
  Result.LoadFromConfig(ConfigFile);
end;

{ TIconUtils }

class function TIconUtils.CategoryToString(Category: TIconCategory): string;
begin
  case Category of
    icAction: Result := 'Action';
    icAlert: Result := 'Alert';
    icAV: Result := 'Audio & Video';
    icCommunication: Result := 'Communication';
    icContent: Result := 'Content';
    icDevice: Result := 'Device';
    icEditor: Result := 'Editor';
    icFile: Result := 'File';
    icHardware: Result := 'Hardware';
    icImage: Result := 'Image';
    icMaps: Result := 'Maps';
    icNavigation: Result := 'Navigation';
    icNotification: Result := 'Notification';
    icSocial: Result := 'Social';
    icToggle: Result := 'Toggle';
    icInterface: Result := 'Interface';
    icArrows: Result := 'Arrows';
    icBrands: Result := 'Brands';
  else
    Result := 'Interface';
  end;
end;

class function TIconUtils.StringToCategory(const CategoryName: string): TIconCategory;
begin
  if SameText(CategoryName, 'Action') then Result := icAction
  else if SameText(CategoryName, 'Alert') then Result := icAlert
  else if SameText(CategoryName, 'Audio & Video') then Result := icAV
  else if SameText(CategoryName, 'Communication') then Result := icCommunication
  else if SameText(CategoryName, 'Content') then Result := icContent
  else if SameText(CategoryName, 'Device') then Result := icDevice
  else if SameText(CategoryName, 'Editor') then Result := icEditor
  else if SameText(CategoryName, 'File') then Result := icFile
  else if SameText(CategoryName, 'Hardware') then Result := icHardware
  else if SameText(CategoryName, 'Image') then Result := icImage
  else if SameText(CategoryName, 'Maps') then Result := icMaps
  else if SameText(CategoryName, 'Navigation') then Result := icNavigation
  else if SameText(CategoryName, 'Notification') then Result := icNotification
  else if SameText(CategoryName, 'Social') then Result := icSocial
  else if SameText(CategoryName, 'Toggle') then Result := icToggle
  else if SameText(CategoryName, 'Interface') then Result := icInterface
  else if SameText(CategoryName, 'Arrows') then Result := icArrows
  else if SameText(CategoryName, 'Brands') then Result := icBrands
  else Result := icInterface;
end;

class function TIconUtils.StyleToString(Style: TIconStyle): string;
begin
  case Style of
    isOutlined: Result := 'Outlined';
    isFilled: Result := 'Filled';
    isRounded: Result := 'Rounded';
    isSharp: Result := 'Sharp';
    isTwoTone: Result := 'Two Tone';
    isLight: Result := 'Light';
    isRegular: Result := 'Regular';
    isBold: Result := 'Bold';
  else
    Result := 'Outlined';
  end;
end;

class function TIconUtils.StringToStyle(const StyleName: string): TIconStyle;
begin
  if SameText(StyleName, 'Outlined') then Result := isOutlined
  else if SameText(StyleName, 'Filled') then Result := isFilled
  else if SameText(StyleName, 'Rounded') then Result := isRounded
  else if SameText(StyleName, 'Sharp') then Result := isSharp
  else if SameText(StyleName, 'Two Tone') then Result := isTwoTone
  else if SameText(StyleName, 'Light') then Result := isLight
  else if SameText(StyleName, 'Regular') then Result := isRegular
  else if SameText(StyleName, 'Bold') then Result := isBold
  else Result := isOutlined;
end;

class function TIconUtils.SetTypeToString(SetType: TIconSetType): string;
begin
  case SetType of
    istMaterial: Result := 'Material Design';
    istFeather: Result := 'Feather';
    istFontAwesome: Result := 'Font Awesome';
    istBootstrap: Result := 'Bootstrap';
    istTabler: Result := 'Tabler';
    istHeroicons: Result := 'Heroicons';
    istPhosphor: Result := 'Phosphor';
    istLucide: Result := 'Lucide';
    istCustom: Result := 'Custom';
  else
    Result := 'Unknown';
  end;
end;

class function TIconUtils.StringToSetType(const TypeName: string): TIconSetType;
begin
  if SameText(TypeName, 'Material Design') then Result := istMaterial
  else if SameText(TypeName, 'Feather') then Result := istFeather
  else if SameText(TypeName, 'Font Awesome') then Result := istFontAwesome
  else if SameText(TypeName, 'Bootstrap') then Result := istBootstrap
  else if SameText(TypeName, 'Tabler') then Result := istTabler
  else if SameText(TypeName, 'Heroicons') then Result := istHeroicons
  else if SameText(TypeName, 'Phosphor') then Result := istPhosphor
  else if SameText(TypeName, 'Lucide') then Result := istLucide
  else if SameText(TypeName, 'Custom') then Result := istCustom
  else Result := istCustom;
end;

class function TIconUtils.GetIconFileName(const IconName: string; Style: TIconStyle; SetType: TIconSetType): string;
var
  StyleSuffix: string;
begin
  case Style of
    isOutlined: StyleSuffix := '_outlined';
    isFilled: StyleSuffix := '_filled';
    isRounded: StyleSuffix := '_rounded';
    isSharp: StyleSuffix := '_sharp';
    isTwoTone: StyleSuffix := '_twotone';
    isLight: StyleSuffix := '_light';
    isRegular: StyleSuffix := '';
    isBold: StyleSuffix := '_bold';
  else
    StyleSuffix := '';
  end;
  
  Result := IconName + StyleSuffix + '.svg';
end;

class function TIconUtils.ApplyThemeToSVG(const SVGData: string; const Theme: string): string;
begin
  Result := SVGData;
  
  if SameText(Theme, 'dark') then
  begin
    // Темна тема - замінюємо чорні кольори на білі
    Result := StringReplace(Result, 'fill="black"', 'fill="white"', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, 'fill="#000000"', 'fill="#ffffff"', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, 'stroke="black"', 'stroke="white"', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, 'stroke="#000000"', 'stroke="#ffffff"', [rfReplaceAll, rfIgnoreCase]);
  end
  else if SameText(Theme, 'light') then
  begin
    // Світла тема - замінюємо білі кольори на чорні
    Result := StringReplace(Result, 'fill="white"', 'fill="black"', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, 'fill="#ffffff"', 'fill="#000000"', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, 'stroke="white"', 'stroke="black"', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, 'stroke="#ffffff"', 'stroke="#000000"', [rfReplaceAll, rfIgnoreCase]);
  end;
  // Для 'auto' залишаємо як є
end;

class function TIconUtils.ResizeSVGIcon(const SVGData: string; NewSize: Integer): string;
begin
  Result := SVGData;
  
  // Простий пошук і заміна розмірів
  Result := StringReplace(Result, 'width="24"', 'width="' + IntToStr(NewSize) + '"', [rfReplaceAll]);
  Result := StringReplace(Result, 'height="24"', 'height="' + IntToStr(NewSize) + '"', [rfReplaceAll]);
  Result := StringReplace(Result, 'width="20"', 'width="' + IntToStr(NewSize) + '"', [rfReplaceAll]);
  Result := StringReplace(Result, 'height="20"', 'height="' + IntToStr(NewSize) + '"', [rfReplaceAll]);
  Result := StringReplace(Result, 'width="16"', 'width="' + IntToStr(NewSize) + '"', [rfReplaceAll]);
  Result := StringReplace(Result, 'height="16"', 'height="' + IntToStr(NewSize) + '"', [rfReplaceAll]);
end;

initialization
  // Автоматично створюємо глобальний менеджер іконок
  TIconSetsManager.GetInstance;

finalization
  TIconSetsManager.ReleaseInstance;

end.