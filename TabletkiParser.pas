unit TabletkiParser;

{
  Парсер сайту tabletki.ua для Delphi
  Збір даних: аптека, адреса, товар, ціна
  
  Автор: [Ваше ім'я]
  Дата: 2025
}

interface

uses
  Classes, SysUtils, IdHTTP, IdSSLOpenSSL, IdGlobal, 
  RegularExpressions, JSON, DateUtils, Math, Dialogs,
  IdComponent, IdTCPConnection, IdTCPClient, IdHTTPHeaderInfo;

type
  // Запис для даних аптеки
  TPharmacyData = record
    PharmacyName: string;     // Назва аптеки
    Address: string;          // Адреса
    ProductName: string;      // Назва товару
    Price: string;            // Ціна
    Availability: string;     // Наявність
    Phone: string;            // Телефон
    URL: string;              // Посилання
    City: string;             // Місто
  end;

  // Динамічний масив даних аптек
  TPharmacyDataArray = array of TPharmacyData;

  // Подія для повідомлення про прогрес
  TProgressEvent = procedure(const Message: string; Progress: Integer) of object;
  
  // Подія для додавання нових даних
  TDataFoundEvent = procedure(const Data: TPharmacyData) of object;

  // Основний клас парсера
  TTabletkiParser = class
  private
    FHTTPClient: TIdHTTP;
    FSSLHandler: TIdSSLIOHandlerSocketOpenSSL;
    FData: TPharmacyDataArray;
    FBaseURL: string;
    FDelayMin: Integer;
    FDelayMax: Integer;
    FOnProgress: TProgressEvent;
    FOnDataFound: TDataFoundEvent;
    FUserAgent: string;
    FLastRequestTime: TDateTime;
    
    procedure InitializeHTTPClient;
    procedure DoProgress(const Message: string; Progress: Integer = 0);
    procedure DoDataFound(const Data: TPharmacyData);
    procedure ApplyDelay;
    function ExtractBetween(const Source, StartTag, EndTag: string): string;
    function CleanText(const Text: string): string;
    function ExtractPrice(const Text: string): string;
    function MakeHTTPRequest(const URL: string): string;
    function ParseSearchResults(const HTML: string): TPharmacyDataArray;
    function ExtractPharmacyData(const HTML: string): TPharmacyDataArray;
    function GenerateDemoData: TPharmacyDataArray;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // Властивості
    property BaseURL: string read FBaseURL write FBaseURL;
    property DelayMin: Integer read FDelayMin write FDelayMin;
    property DelayMax: Integer read FDelayMax write FDelayMax;
    property UserAgent: string read FUserAgent write FUserAgent;
    property Data: TPharmacyDataArray read FData;
    
    // Події
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    property OnDataFound: TDataFoundEvent read FOnDataFound write FOnDataFound;
    
    // Основні методи
    function SearchProduct(const ProductName, City: string): TPharmacyDataArray;
    function GetPopularProducts: TPharmacyDataArray;
    function GetDemoData: TPharmacyDataArray;
    
    // Експорт даних
    function SaveToCSV(const FileName: string): Boolean;
    function SaveToJSON(const FileName: string): Boolean;
    
    // Допоміжні методи
    procedure ClearData;
    function GetDataCount: Integer;
    function GetStatistics: string;
    function AnalyzePrices(const ProductName: string): string;
  end;

implementation

{ TTabletkiParser }

constructor TTabletkiParser.Create;
begin
  inherited Create;
  
  FBaseURL := 'https://tabletki.ua';
  FDelayMin := 1000;  // 1 секунда
  FDelayMax := 3000;  // 3 секунди
  FUserAgent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  FLastRequestTime := 0;
  
  SetLength(FData, 0);
  InitializeHTTPClient;
end;

destructor TTabletkiParser.Destroy;
begin
  if Assigned(FHTTPClient) then
    FHTTPClient.Free;
  if Assigned(FSSLHandler) then
    FSSLHandler.Free;
    
  SetLength(FData, 0);
  inherited Destroy;
end;

procedure TTabletkiParser.InitializeHTTPClient;
begin
  // Створення SSL обробника
  FSSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  FSSLHandler.SSLOptions.Method := sslvTLSv1_2;
  FSSLHandler.SSLOptions.SSLVersions := [sslvTLSv1_2];
  
  // Створення HTTP клієнта
  FHTTPClient := TIdHTTP.Create(nil);
  FHTTPClient.IOHandler := FSSLHandler;
  FHTTPClient.HandleRedirects := True;
  FHTTPClient.ConnectTimeout := 30000;  // 30 секунд
  FHTTPClient.ReadTimeout := 30000;
  
  // Встановлення заголовків
  FHTTPClient.Request.UserAgent := FUserAgent;
  FHTTPClient.Request.Accept := 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8';
  FHTTPClient.Request.AcceptLanguage := 'uk-UA,uk;q=0.9,en;q=0.8,ru;q=0.7';
  FHTTPClient.Request.AcceptEncoding := 'gzip, deflate, br';
  FHTTPClient.Request.Connection := 'keep-alive';
end;

procedure TTabletkiParser.DoProgress(const Message: string; Progress: Integer);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Message, Progress);
end;

procedure TTabletkiParser.DoDataFound(const Data: TPharmacyData);
begin
  if Assigned(FOnDataFound) then
    FOnDataFound(Data);
end;

procedure TTabletkiParser.ApplyDelay;
var
  DelayMS: Integer;
  TimeSinceLastRequest: Int64;
begin
  // Розрахунок часу з останнього запиту
  TimeSinceLastRequest := MilliSecondsBetween(Now, FLastRequestTime);
  
  // Випадкова затримка між мін і макс
  DelayMS := FDelayMin + Random(FDelayMax - FDelayMin);
  
  // Якщо пройшло менше часу ніж потрібно - чекаємо
  if TimeSinceLastRequest < DelayMS then
  begin
    DoProgress(Format('Затримка %d мс...', [DelayMS - TimeSinceLastRequest]));
    Sleep(DelayMS - TimeSinceLastRequest);
  end;
  
  FLastRequestTime := Now;
end;

function TTabletkiParser.ExtractBetween(const Source, StartTag, EndTag: string): string;
var
  StartPos, EndPos: Integer;
begin
  Result := '';
  StartPos := Pos(StartTag, Source);
  if StartPos > 0 then
  begin
    StartPos := StartPos + Length(StartTag);
    EndPos := PosEx(EndTag, Source, StartPos);
    if EndPos > StartPos then
      Result := Copy(Source, StartPos, EndPos - StartPos);
  end;
end;

function TTabletkiParser.CleanText(const Text: string): string;
begin
  Result := Trim(Text);
  // Видалення зайвих пробілів та переносів рядків
  Result := TRegEx.Replace(Result, '\s+', ' ');
  // Видалення HTML тегів
  Result := TRegEx.Replace(Result, '<[^>]*>', '');
  // Декодування HTML сутностей
  Result := StringReplace(Result, '&nbsp;', ' ', [rfReplaceAll]);
  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '&amp;', '&', [rfReplaceAll]);
  Result := StringReplace(Result, '&lt;', '<', [rfReplaceAll]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll]);
  Result := Trim(Result);
end;

function TTabletkiParser.ExtractPrice(const Text: string): string;
var
  Match: TMatch;
begin
  Result := '';
  // Пошук ціни в форматі число + грн
  Match := TRegEx.Match(Text, '(\d+[,.]?\d*)\s*(грн|₴)');
  if Match.Success then
    Result := Match.Value;
end;

function TTabletkiParser.MakeHTTPRequest(const URL: string): string;
begin
  Result := '';
  try
    ApplyDelay;
    DoProgress('Запит до: ' + URL);
    
    Result := FHTTPClient.Get(URL);
    DoProgress('Отримано відповідь, розмір: ' + IntToStr(Length(Result)) + ' символів');
    
  except
    on E: Exception do
    begin
      DoProgress('Помилка HTTP запиту: ' + E.Message);
      raise;
    end;
  end;
end;

function TTabletkiParser.ParseSearchResults(const HTML: string): TPharmacyDataArray;
var
  ProductBlocks: TStringList;
  i: Integer;
  ProductHTML: string;
  Data: TPharmacyData;
  Regex: TRegEx;
  Matches: TMatchCollection;
  Match: TMatch;
begin
  SetLength(Result, 0);
  ProductBlocks := TStringList.Create;
  try
    // Пошук блоків товарів
    // Це спрощений варіант - в реальності потрібно адаптувати під структуру сайту
    Regex := TRegEx.Create('<div[^>]*class="[^"]*product[^"]*"[^>]*>.*?</div>', [roIgnoreCase, roSingleLine]);
    Matches := Regex.Matches(HTML);
    
    DoProgress(Format('Знайдено %d потенційних товарів', [Matches.Count]));
    
    for Match in Matches do
    begin
      ProductHTML := Match.Value;
      
      // Ініціалізація структури даних
      FillChar(Data, SizeOf(Data), 0);
      
      // Назва товару
      Data.ProductName := CleanText(ExtractBetween(ProductHTML, 'product-name">', '</'));
      if Data.ProductName = '' then
        Data.ProductName := CleanText(ExtractBetween(ProductHTML, '<h3>', '</h3>'));
      
      // Ціна
      Data.Price := ExtractPrice(ProductHTML);
      
      // Наявність
      if Pos('в наявності', LowerCase(ProductHTML)) > 0 then
        Data.Availability := 'В наявності'
      else if Pos('під замовлення', LowerCase(ProductHTML)) > 0 then
        Data.Availability := 'Під замовлення'
      else
        Data.Availability := 'Уточнити';
      
      // URL товару
      Data.URL := ExtractBetween(ProductHTML, 'href="', '"');
      if (Data.URL <> '') and (Pos('http', Data.URL) = 0) then
        Data.URL := FBaseURL + Data.URL;
      
      // Додаємо до результату якщо є основні дані
      if (Data.ProductName <> '') and (Data.Price <> '') then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := Data;
        DoDataFound(Data);
      end;
    end;
    
  finally
    ProductBlocks.Free;
  end;
end;

function TTabletkiParser.ExtractPharmacyData(const HTML: string): TPharmacyDataArray;
var
  PharmacyBlocks: TStringList;
  i: Integer;
  PharmacyHTML: string;
  Data: TPharmacyData;
  Regex: TRegEx;
  Matches: TMatchCollection;
  Match: TMatch;
begin
  SetLength(Result, 0);
  PharmacyBlocks := TStringList.Create;
  try
    // Пошук блоків аптек
    Regex := TRegEx.Create('<tr[^>]*>.*?</tr>|<div[^>]*class="[^"]*pharmacy[^"]*"[^>]*>.*?</div>', [roIgnoreCase, roSingleLine]);
    Matches := Regex.Matches(HTML);
    
    DoProgress(Format('Знайдено %d потенційних аптек', [Matches.Count]));
    
    for Match in Matches do
    begin
      PharmacyHTML := Match.Value;
      
      // Ініціалізація структури даних
      FillChar(Data, SizeOf(Data), 0);
      
      // Назва аптеки
      Data.PharmacyName := CleanText(ExtractBetween(PharmacyHTML, '<td>', '</td>'));
      if Data.PharmacyName = '' then
        Data.PharmacyName := CleanText(ExtractBetween(PharmacyHTML, 'pharmacy-name">', '</'));
      
      // Адреса
      Data.Address := CleanText(ExtractBetween(PharmacyHTML, 'address">', '</'));
      if Data.Address = '' then
      begin
        // Альтернативний пошук адреси
        if Pos('вул.', PharmacyHTML) > 0 then
          Data.Address := CleanText(ExtractBetween(PharmacyHTML, 'вул.', '<'));
      end;
      
      // Ціна
      Data.Price := ExtractPrice(PharmacyHTML);
      
      // Телефон
      Data.Phone := CleanText(ExtractBetween(PharmacyHTML, 'phone">', '</'));
      
      // Наявність
      if Pos('в наявності', LowerCase(PharmacyHTML)) > 0 then
        Data.Availability := 'В наявності'
      else if Pos('під замовлення', LowerCase(PharmacyHTML)) > 0 then
        Data.Availability := 'Під замовлення'
      else
        Data.Availability := 'Уточнити';
      
      // Додаємо до результату якщо є основні дані
      if (Data.PharmacyName <> '') and ((Data.Address <> '') or (Data.Price <> '')) then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := Data;
        DoDataFound(Data);
      end;
    end;
    
  finally
    PharmacyBlocks.Free;
  end;
end;

function TTabletkiParser.GenerateDemoData: TPharmacyDataArray;
const
  DemoPharmacies: array[0..3] of string = (
    'Аптека АНЦ', 'Аптека Копійка', 'Фармація', 'Біла Ромашка'
  );
  DemoAddresses: array[0..11] of string = (
    'вул. Хрещатик, 1', 'вул. Володимирська, 15', 'просп. Перемоги, 25',
    'вул. Саксаганського, 33', 'бул. Лесі Українки, 7', 'вул. Велика Васильківська, 12',
    'вул. Горького, 8', 'просп. Науки, 45', 'вул. Антоновича, 18',
    'вул. Бориспільська, 5', 'просп. Оболонський, 22', 'вул. Ревуцького, 9'
  );
  DemoProducts: array[0..7] of record
    Name: string;
    BasePrice: Double;
  end = (
    (Name: 'Парацетамол таблетки 500мг №10'; BasePrice: 15.50),
    (Name: 'Ібупрофен капсули 200мг №20'; BasePrice: 28.75),
    (Name: 'Аспірин таблетки 325мг №30'; BasePrice: 22.30),
    (Name: 'Нурофен сироп 100мл'; BasePrice: 87.60),
    (Name: 'Цитрамон таблетки №6'; BasePrice: 8.90),
    (Name: 'Анальгін таблетки 500мг №10'; BasePrice: 12.45),
    (Name: 'Амоксицилін капсули 250мг №16'; BasePrice: 45.20),
    (Name: 'Лоратадин таблетки 10мг №10'; BasePrice: 19.80)
  );
  DemoAvailability: array[0..2] of string = (
    'В наявності', 'Закінчується', 'Під замовлення'
  );
var
  i, j, k, DataIndex: Integer;
  Data: TPharmacyData;
  PriceVariation: Double;
  FinalPrice: Double;
begin
  SetLength(Result, Length(DemoPharmacies) * 3 * Length(DemoProducts));
  DataIndex := 0;
  
  for i := 0 to High(DemoPharmacies) do
  begin
    for j := 0 to 2 do  // 3 адреси на аптеку
    begin
      for k := 0 to High(DemoProducts) do
      begin
        FillChar(Data, SizeOf(Data), 0);
        
        Data.PharmacyName := DemoPharmacies[i];
        Data.Address := DemoAddresses[i * 3 + j];
        Data.ProductName := DemoProducts[k].Name;
        
        // Варіація ціни ±20%
        PriceVariation := 0.8 + Random * 0.4;  // 0.8 до 1.2
        FinalPrice := DemoProducts[k].BasePrice * PriceVariation;
        Data.Price := Format('%.2f грн', [FinalPrice]);
        
        Data.Availability := DemoAvailability[Random(3)];
        Data.Phone := Format('+380%d', [441234567 + Random(60000000)]);
        Data.URL := Format('%s/product/%s', [FBaseURL, StringReplace(LowerCase(DemoProducts[k].Name), ' ', '-', [rfReplaceAll])]);
        Data.City := 'Київ';
        
        Result[DataIndex] := Data;
        Inc(DataIndex);
      end;
    end;
  end;
  
  SetLength(Result, DataIndex);
end;

function TTabletkiParser.SearchProduct(const ProductName, City: string): TPharmacyDataArray;
var
  SearchURL: string;
  HTML: string;
  Products: TPharmacyDataArray;
  i: Integer;
  ProductHTML: string;
  Pharmacies: TPharmacyDataArray;
  j: Integer;
begin
  SetLength(Result, 0);
  DoProgress(Format('Пошук товару: %s у місті %s', [ProductName, City]));
  
  try
    // Формування URL для пошуку
    SearchURL := Format('%s/search?q=%s', [FBaseURL, TIdURI.URLEncode(ProductName)]);
    
    // Отримання HTML сторінки пошуку
    HTML := MakeHTTPRequest(SearchURL);
    
    if HTML = '' then
    begin
      DoProgress('Помилка: порожня відповідь від сервера');
      Exit;
    end;
    
    // Парсинг результатів пошуку
    Products := ParseSearchResults(HTML);
    DoProgress(Format('Знайдено %d товарів', [Length(Products)]));
    
    // Для кожного товару отримуємо інформацію про аптеки
    for i := 0 to Min(High(Products), 4) do  // Обмежуємо 5 товарами
    begin
      if Products[i].URL <> '' then
      begin
        DoProgress(Format('Отримання даних аптек для: %s', [Products[i].ProductName]));
        
        try
          ProductHTML := MakeHTTPRequest(Products[i].URL);
          Pharmacies := ExtractPharmacyData(ProductHTML);
          
          // Додаємо назву товару до кожної аптеки
          for j := 0 to High(Pharmacies) do
          begin
            Pharmacies[j].ProductName := Products[i].ProductName;
            Pharmacies[j].City := City;
          end;
          
          // Об'єднуємо результати
          SetLength(Result, Length(Result) + Length(Pharmacies));
          for j := 0 to High(Pharmacies) do
            Result[Length(Result) - Length(Pharmacies) + j] := Pharmacies[j];
            
        except
          on E: Exception do
            DoProgress('Помилка отримання даних товару: ' + E.Message);
        end;
      end;
    end;
    
    // Копіюємо дані в внутрішній масив
    SetLength(FData, Length(Result));
    for i := 0 to High(Result) do
      FData[i] := Result[i];
      
    DoProgress(Format('Пошук завершено. Знайдено %d аптек', [Length(Result)]));
    
  except
    on E: Exception do
    begin
      DoProgress('Критична помилка пошуку: ' + E.Message);
      raise;
    end;
  end;
end;

function TTabletkiParser.GetPopularProducts: TPharmacyDataArray;
var
  HTML: string;
begin
  SetLength(Result, 0);
  DoProgress('Отримання популярних товарів');
  
  try
    HTML := MakeHTTPRequest(FBaseURL);
    
    if HTML <> '' then
    begin
      Result := ParseSearchResults(HTML);
      
      // Копіюємо дані в внутрішній масив
      SetLength(FData, Length(Result));
      for var i := 0 to High(Result) do
        FData[i] := Result[i];
        
      DoProgress(Format('Знайдено %d популярних товарів', [Length(Result)]));
    end;
    
  except
    on E: Exception do
    begin
      DoProgress('Помилка отримання популярних товарів: ' + E.Message);
      raise;
    end;
  end;
end;

function TTabletkiParser.GetDemoData: TPharmacyDataArray;
begin
  DoProgress('Генерація демонстраційних даних');
  
  Result := GenerateDemoData;
  
  // Копіюємо дані в внутрішній масив
  SetLength(FData, Length(Result));
  for var i := 0 to High(Result) do
    FData[i] := Result[i];
    
  DoProgress(Format('Згенеровано %d демонстраційних записів', [Length(Result)]));
end;

function TTabletkiParser.SaveToCSV(const FileName: string): Boolean;
var
  CSV: TStringList;
  i: Integer;
  Line: string;
begin
  Result := False;
  CSV := TStringList.Create;
  try
    // Заголовок CSV
    CSV.Add('pharmacy_name,address,product_name,price,availability,phone,url,city');
    
    // Дані
    for i := 0 to High(FData) do
    begin
      Line := Format('"%s","%s","%s","%s","%s","%s","%s","%s"', [
        StringReplace(FData[i].PharmacyName, '"', '""', [rfReplaceAll]),
        StringReplace(FData[i].Address, '"', '""', [rfReplaceAll]),
        StringReplace(FData[i].ProductName, '"', '""', [rfReplaceAll]),
        StringReplace(FData[i].Price, '"', '""', [rfReplaceAll]),
        StringReplace(FData[i].Availability, '"', '""', [rfReplaceAll]),
        StringReplace(FData[i].Phone, '"', '""', [rfReplaceAll]),
        StringReplace(FData[i].URL, '"', '""', [rfReplaceAll]),
        StringReplace(FData[i].City, '"', '""', [rfReplaceAll])
      ]);
      CSV.Add(Line);
    end;
    
    CSV.SaveToFile(FileName, TEncoding.UTF8);
    Result := True;
    DoProgress(Format('Дані збережено у файл: %s', [FileName]));
    
  except
    on E: Exception do
    begin
      DoProgress('Помилка збереження CSV: ' + E.Message);
      Result := False;
    end;
  end;
  
  CSV.Free;
end;

function TTabletkiParser.SaveToJSON(const FileName: string): Boolean;
var
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
  i: Integer;
  JSONString: string;
  FileStream: TFileStream;
  UTF8Bytes: TBytes;
begin
  Result := False;
  JSONArray := TJSONArray.Create;
  try
    // Створення JSON об'єктів
    for i := 0 to High(FData) do
    begin
      JSONObject := TJSONObject.Create;
      JSONObject.AddPair('pharmacy_name', FData[i].PharmacyName);
      JSONObject.AddPair('address', FData[i].Address);
      JSONObject.AddPair('product_name', FData[i].ProductName);
      JSONObject.AddPair('price', FData[i].Price);
      JSONObject.AddPair('availability', FData[i].Availability);
      JSONObject.AddPair('phone', FData[i].Phone);
      JSONObject.AddPair('url', FData[i].URL);
      JSONObject.AddPair('city', FData[i].City);
      
      JSONArray.AddElement(JSONObject);
    end;
    
    // Збереження у файл
    JSONString := JSONArray.Format(2);  // Форматований JSON з відступами
    UTF8Bytes := TEncoding.UTF8.GetBytes(JSONString);
    
    FileStream := TFileStream.Create(FileName, fmCreate);
    try
      FileStream.WriteBuffer(UTF8Bytes, Length(UTF8Bytes));
      Result := True;
      DoProgress(Format('Дані збережено у файл: %s', [FileName]));
    finally
      FileStream.Free;
    end;
    
  except
    on E: Exception do
    begin
      DoProgress('Помилка збереження JSON: ' + E.Message);
      Result := False;
    end;
  end;
  
  JSONArray.Free;
end;

procedure TTabletkiParser.ClearData;
begin
  SetLength(FData, 0);
  DoProgress('Дані очищено');
end;

function TTabletkiParser.GetDataCount: Integer;
begin
  Result := Length(FData);
end;

function TTabletkiParser.GetStatistics: string;
var
  i: Integer;
  Pharmacies, Products: TStringList;
begin
  Pharmacies := TStringList.Create;
  Products := TStringList.Create;
  try
    Pharmacies.Duplicates := dupIgnore;
    Products.Duplicates := dupIgnore;
    Pharmacies.Sorted := True;
    Products.Sorted := True;
    
    for i := 0 to High(FData) do
    begin
      if FData[i].PharmacyName <> '' then
        Pharmacies.Add(FData[i].PharmacyName);
      if FData[i].ProductName <> '' then
        Products.Add(FData[i].ProductName);
    end;
    
    Result := Format('Загалом записів: %d'#13#10+
                     'Унікальних аптек: %d'#13#10+
                     'Унікальних товарів: %d', [
                     Length(FData), Pharmacies.Count, Products.Count]);
    
  finally
    Pharmacies.Free;
    Products.Free;
  end;
end;

function TTabletkiParser.AnalyzePrices(const ProductName: string): string;
var
  i: Integer;
  Prices: array of Double;
  PriceCount: Integer;
  MinPrice, MaxPrice, AvgPrice, TotalPrice: Double;
  PriceStr: string;
  PharmacyCount: Integer;
  Pharmacies: TStringList;
begin
  Result := '';
  SetLength(Prices, 0);
  PriceCount := 0;
  TotalPrice := 0;
  
  Pharmacies := TStringList.Create;
  try
    Pharmacies.Duplicates := dupIgnore;
    Pharmacies.Sorted := True;
    
    // Збір цін для вказаного товару
    for i := 0 to High(FData) do
    begin
      if (Pos(LowerCase(ProductName), LowerCase(FData[i].ProductName)) > 0) and 
         (FData[i].Price <> '') then
      begin
        // Витягуємо числове значення ціни
        PriceStr := TRegEx.Replace(FData[i].Price, '[^\d,.]', '');
        PriceStr := StringReplace(PriceStr, ',', '.', [rfReplaceAll]);
        
        if TryStrToFloat(PriceStr, MinPrice) then
        begin
          SetLength(Prices, PriceCount + 1);
          Prices[PriceCount] := MinPrice;
          TotalPrice := TotalPrice + MinPrice;
          Inc(PriceCount);
          
          if FData[i].PharmacyName <> '' then
            Pharmacies.Add(FData[i].PharmacyName);
        end;
      end;
    end;
    
    if PriceCount > 0 then
    begin
      MinPrice := Prices[0];
      MaxPrice := Prices[0];
      
      for i := 1 to PriceCount - 1 do
      begin
        if Prices[i] < MinPrice then
          MinPrice := Prices[i];
        if Prices[i] > MaxPrice then
          MaxPrice := Prices[i];
      end;
      
      AvgPrice := TotalPrice / PriceCount;
      PharmacyCount := Pharmacies.Count;
      
      Result := Format('Аналіз цін на "%s":'#13#10+
                       'Мінімальна ціна: %.2f грн'#13#10+
                       'Максимальна ціна: %.2f грн'#13#10+
                       'Середня ціна: %.2f грн'#13#10+
                       'Різниця цін: %.2f грн'#13#10+
                       'Кількість пропозицій: %d'#13#10+
                       'Кількість аптек: %d', [
                       ProductName, MinPrice, MaxPrice, AvgPrice, 
                       MaxPrice - MinPrice, PriceCount, PharmacyCount]);
    end
    else
      Result := Format('Не знайдено цінових даних для "%s"', [ProductName]);
      
  finally
    Pharmacies.Free;
  end;
end;

end.