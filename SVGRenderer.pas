unit SVGRenderer;

interface

uses
  Windows, Classes, Graphics, SysUtils, Types, Math, RegularExpressions,
  Generics.Collections, XMLDoc, XMLIntf;

type
  // SVG елементи
  TSVGElementType = (etPath, etCircle, etRect, etLine, etPolygon, etPolyline, etText, etGroup);
  
  // SVG трансформації
  TSVGTransform = record
    TranslateX, TranslateY: Single;
    ScaleX, ScaleY: Single;
    Rotation: Single;
    SkewX, SkewY: Single;
  end;
  
  // SVG стилі
  TSVGStyle = record
    Fill: TColor;
    Stroke: TColor;
    StrokeWidth: Single;
    Opacity: Single;
    FillOpacity: Single;
    StrokeOpacity: Single;
    HasFill: Boolean;
    HasStroke: Boolean;
  end;

  // Базовий SVG елемент
  TSVGElement = class
  private
    FElementType: TSVGElementType;
    FStyle: TSVGStyle;
    FTransform: TSVGTransform;
    FID: string;
    FClass: string;
  public
    constructor Create(AElementType: TSVGElementType);
    virtual procedure Render(Canvas: TCanvas; const ViewBox: TRectF; ScaleX, ScaleY: Single); virtual; abstract;
    
    property ElementType: TSVGElementType read FElementType;
    property Style: TSVGStyle read FStyle write FStyle;
    property Transform: TSVGTransform read FTransform write FTransform;
    property ID: string read FID write FID;
    property ElementClass: string read FClass write FClass;
  end;

  // SVG Path елемент
  TSVGPath = class(TSVGElement)
  private
    FPathData: string;
    FPoints: TArray<TPointF>;
    procedure ParsePathData;
    function ParseNumber(const S: string; var Pos: Integer): Single;
    procedure AddPoint(X, Y: Single);
  public
    constructor Create(const APathData: string);
    procedure Render(Canvas: TCanvas; const ViewBox: TRectF; ScaleX, ScaleY: Single); override;
    
    property PathData: string read FPathData write FPathData;
  end;

  // SVG Circle елемент
  TSVGCircle = class(TSVGElement)
  private
    FCenterX, FCenterY: Single;
    FRadius: Single;
  public
    constructor Create(ACX, ACY, ARadius: Single);
    procedure Render(Canvas: TCanvas; const ViewBox: TRectF; ScaleX, ScaleY: Single); override;
    
    property CenterX: Single read FCenterX write FCenterX;
    property CenterY: Single read FCenterY write FCenterY;
    property Radius: Single read FRadius write FRadius;
  end;

  // SVG Rectangle елемент
  TSVGRect = class(TSVGElement)
  private
    FX, FY, FWidth, FHeight: Single;
    FRX, FRY: Single; // округлені кути
  public
    constructor Create(AX, AY, AWidth, AHeight: Single; ARX: Single = 0; ARY: Single = 0);
    procedure Render(Canvas: TCanvas; const ViewBox: TRectF; ScaleX, ScaleY: Single); override;
    
    property X: Single read FX write FX;
    property Y: Single read FY write FY;
    property Width: Single read FWidth write FWidth;
    property Height: Single read FHeight write FHeight;
    property RX: Single read FRX write FRX;
    property RY: Single read FRY write FRY;
  end;

  // SVG Group елемент
  TSVGGroup = class(TSVGElement)
  private
    FElements: TObjectList<TSVGElement>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddElement(AElement: TSVGElement);
    procedure Render(Canvas: TCanvas; const ViewBox: TRectF; ScaleX, ScaleY: Single); override;
    
    property Elements: TObjectList<TSVGElement> read FElements;
  end;

  // Основний SVG рендерер
  TSVGRenderer = class
  private
    FElements: TObjectList<TSVGElement>;
    FViewBox: TRectF;
    FWidth, FHeight: Single;
    FDefaultStyle: TSVGStyle;
    
    procedure ParseSVGDocument(const AXML: string);
    procedure ParseElement(XMLNode: IXMLNode; ParentGroup: TSVGGroup = nil);
    function ParseStyle(const StyleStr: string): TSVGStyle;
    function ParseTransform(const TransformStr: string): TSVGTransform;
    function ParseColor(const ColorStr: string): TColor;
    function ScalePoint(const Point: TPointF; const ViewBox: TRectF; ScaleX, ScaleY: Single): TPoint;
    procedure ApplyTransform(Canvas: TCanvas; const Transform: TSVGTransform; ScaleX, ScaleY: Single);
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure LoadFromString(const ASVG: string);
    procedure LoadFromFile(const AFileName: string);
    procedure RenderToBitmap(Bitmap: TBitmap; AWidth, AHeight: Integer; ABackgroundColor: TColor = clWhite);
    procedure Clear;
    
    property ViewBox: TRectF read FViewBox;
    property Width: Single read FWidth;
    property Height: Single read FHeight;
    property Elements: TObjectList<TSVGElement> read FElements;
  end;

  // Утилітарні функції для сучасних іконок
  TSVGIconUtils = class
  public
    class function CreateMaterialIcon(const IconName: string; Size: Integer = 24): string;
    class function CreateFeatherIcon(const IconName: string; Size: Integer = 24): string;
    class function CreateFontAwesomeIcon(const IconName: string; Size: Integer = 24): string;
    class function RecolorSVG(const ASVG: string; NewColor: TColor): string;
    class function ResizeSVG(const ASVG: string; NewWidth, NewHeight: Integer): string;
    class function ApplyTheme(const ASVG: string; IsDarkTheme: Boolean): string;
  end;

implementation

uses
  StrUtils, Variants;

{ TSVGElement }

constructor TSVGElement.Create(AElementType: TSVGElementType);
begin
  inherited Create;
  FElementType := AElementType;
  
  // Ініціалізуємо стиль за замовчуванням
  FillChar(FStyle, SizeOf(FStyle), 0);
  FStyle.Fill := clBlack;
  FStyle.Stroke := clNone;
  FStyle.StrokeWidth := 1.0;
  FStyle.Opacity := 1.0;
  FStyle.FillOpacity := 1.0;
  FStyle.StrokeOpacity := 1.0;
  FStyle.HasFill := True;
  FStyle.HasStroke := False;
  
  // Ініціалізуємо трансформацію
  FillChar(FTransform, SizeOf(FTransform), 0);
  FTransform.ScaleX := 1.0;
  FTransform.ScaleY := 1.0;
end;

{ TSVGPath }

constructor TSVGPath.Create(const APathData: string);
begin
  inherited Create(etPath);
  FPathData := APathData;
  ParsePathData;
end;

procedure TSVGPath.ParsePathData;
var
  I: Integer;
  CurrentPos: TPointF;
  Command: Char;
  Pos: Integer;
  X, Y: Single;
begin
  SetLength(FPoints, 0);
  CurrentPos := PointF(0, 0);
  Pos := 1;
  
  while Pos <= Length(FPathData) do
  begin
    // Пропускаємо пробіли
    while (Pos <= Length(FPathData)) and CharInSet(FPathData[Pos], [' ', #9, #10, #13]) do
      Inc(Pos);
      
    if Pos > Length(FPathData) then
      Break;
      
    Command := FPathData[Pos];
    Inc(Pos);
    
    case Command of
      'M', 'm': // MoveTo
      begin
        X := ParseNumber(FPathData, Pos);
        Y := ParseNumber(FPathData, Pos);
        
        if Command = 'm' then
        begin
          CurrentPos.X := CurrentPos.X + X;
          CurrentPos.Y := CurrentPos.Y + Y;
        end
        else
        begin
          CurrentPos.X := X;
          CurrentPos.Y := Y;
        end;
        
        AddPoint(CurrentPos.X, CurrentPos.Y);
      end;
      
      'L', 'l': // LineTo
      begin
        X := ParseNumber(FPathData, Pos);
        Y := ParseNumber(FPathData, Pos);
        
        if Command = 'l' then
        begin
          CurrentPos.X := CurrentPos.X + X;
          CurrentPos.Y := CurrentPos.Y + Y;
        end
        else
        begin
          CurrentPos.X := X;
          CurrentPos.Y := Y;
        end;
        
        AddPoint(CurrentPos.X, CurrentPos.Y);
      end;
      
      'H', 'h': // Horizontal LineTo
      begin
        X := ParseNumber(FPathData, Pos);
        
        if Command = 'h' then
          CurrentPos.X := CurrentPos.X + X
        else
          CurrentPos.X := X;
          
        AddPoint(CurrentPos.X, CurrentPos.Y);
      end;
      
      'V', 'v': // Vertical LineTo
      begin
        Y := ParseNumber(FPathData, Pos);
        
        if Command = 'v' then
          CurrentPos.Y := CurrentPos.Y + Y
        else
          CurrentPos.Y := Y;
          
        AddPoint(CurrentPos.X, CurrentPos.Y);
      end;
      
      'Z', 'z': // ClosePath
      begin
        // Замикаємо шлях
        if Length(FPoints) > 0 then
          AddPoint(FPoints[0].X, FPoints[0].Y);
      end;
    end;
  end;
end;

function TSVGPath.ParseNumber(const S: string; var Pos: Integer): Single;
var
  StartPos: Integer;
  NumStr: string;
begin
  // Пропускаємо пробіли та коми
  while (Pos <= Length(S)) and CharInSet(S[Pos], [' ', ',', #9, #10, #13]) do
    Inc(Pos);
    
  StartPos := Pos;
  
  // Читаємо число (включаючи знак та десяткову крапку)
  while (Pos <= Length(S)) and CharInSet(S[Pos], ['0'..'9', '+', '-', '.', 'e', 'E']) do
    Inc(Pos);
    
  NumStr := Copy(S, StartPos, Pos - StartPos);
  
  try
    Result := StrToFloat(NumStr);
  except
    Result := 0;
  end;
end;

procedure TSVGPath.AddPoint(X, Y: Single);
begin
  SetLength(FPoints, Length(FPoints) + 1);
  FPoints[High(FPoints)] := PointF(X, Y);
end;

procedure TSVGPath.Render(Canvas: TCanvas; const ViewBox: TRectF; ScaleX, ScaleY: Single);
var
  I: Integer;
  Points: TArray<TPoint>;
begin
  if Length(FPoints) = 0 then
    Exit;
    
  SetLength(Points, Length(FPoints));
  
  for I := 0 to High(FPoints) do
    Points[I] := Point(Round(FPoints[I].X * ScaleX), Round(FPoints[I].Y * ScaleY));
    
  if FStyle.HasFill then
  begin
    Canvas.Brush.Color := FStyle.Fill;
    Canvas.Brush.Style := bsSolid;
    Canvas.Polygon(Points);
  end;
  
  if FStyle.HasStroke then
  begin
    Canvas.Pen.Color := FStyle.Stroke;
    Canvas.Pen.Width := Round(FStyle.StrokeWidth * Min(ScaleX, ScaleY));
    Canvas.Pen.Style := psSolid;
    Canvas.Polyline(Points);
  end;
end;

{ TSVGCircle }

constructor TSVGCircle.Create(ACX, ACY, ARadius: Single);
begin
  inherited Create(etCircle);
  FCenterX := ACX;
  FCenterY := ACY;
  FRadius := ARadius;
end;

procedure TSVGCircle.Render(Canvas: TCanvas; const ViewBox: TRectF; ScaleX, ScaleY: Single);
var
  X, Y, R: Integer;
begin
  X := Round(FCenterX * ScaleX);
  Y := Round(FCenterY * ScaleY);
  R := Round(FRadius * Min(ScaleX, ScaleY));
  
  if FStyle.HasFill then
  begin
    Canvas.Brush.Color := FStyle.Fill;
    Canvas.Brush.Style := bsSolid;
  end
  else
    Canvas.Brush.Style := bsClear;
    
  if FStyle.HasStroke then
  begin
    Canvas.Pen.Color := FStyle.Stroke;
    Canvas.Pen.Width := Round(FStyle.StrokeWidth * Min(ScaleX, ScaleY));
    Canvas.Pen.Style := psSolid;
  end
  else
    Canvas.Pen.Style := psClear;
    
  Canvas.Ellipse(X - R, Y - R, X + R, Y + R);
end;

{ TSVGRect }

constructor TSVGRect.Create(AX, AY, AWidth, AHeight: Single; ARX: Single = 0; ARY: Single = 0);
begin
  inherited Create(etRect);
  FX := AX;
  FY := AY;
  FWidth := AWidth;
  FHeight := AHeight;
  FRX := ARX;
  FRY := ARY;
end;

procedure TSVGRect.Render(Canvas: TCanvas; const ViewBox: TRectF; ScaleX, ScaleY: Single);
var
  Rect: TRect;
begin
  Rect.Left := Round(FX * ScaleX);
  Rect.Top := Round(FY * ScaleY);
  Rect.Right := Round((FX + FWidth) * ScaleX);
  Rect.Bottom := Round((FY + FHeight) * ScaleY);
  
  if FStyle.HasFill then
  begin
    Canvas.Brush.Color := FStyle.Fill;
    Canvas.Brush.Style := bsSolid;
  end
  else
    Canvas.Brush.Style := bsClear;
    
  if FStyle.HasStroke then
  begin
    Canvas.Pen.Color := FStyle.Stroke;
    Canvas.Pen.Width := Round(FStyle.StrokeWidth * Min(ScaleX, ScaleY));
    Canvas.Pen.Style := psSolid;
  end
  else
    Canvas.Pen.Style := psClear;
    
  if (FRX > 0) or (FRY > 0) then
    Canvas.RoundRect(Rect, Round(FRX * ScaleX), Round(FRY * ScaleY))
  else
    Canvas.Rectangle(Rect);
end;

{ TSVGGroup }

constructor TSVGGroup.Create;
begin
  inherited Create(etGroup);
  FElements := TObjectList<TSVGElement>.Create(True);
end;

destructor TSVGGroup.Destroy;
begin
  FElements.Free;
  inherited;
end;

procedure TSVGGroup.AddElement(AElement: TSVGElement);
begin
  FElements.Add(AElement);
end;

procedure TSVGGroup.Render(Canvas: TCanvas; const ViewBox: TRectF; ScaleX, ScaleY: Single);
var
  Element: TSVGElement;
begin
  for Element in FElements do
    Element.Render(Canvas, ViewBox, ScaleX, ScaleY);
end;

{ TSVGRenderer }

constructor TSVGRenderer.Create;
begin
  inherited;
  FElements := TObjectList<TSVGElement>.Create(True);
  
  // Стиль за замовчуванням
  FillChar(FDefaultStyle, SizeOf(FDefaultStyle), 0);
  FDefaultStyle.Fill := clBlack;
  FDefaultStyle.Stroke := clNone;
  FDefaultStyle.StrokeWidth := 1.0;
  FDefaultStyle.Opacity := 1.0;
  FDefaultStyle.FillOpacity := 1.0;
  FDefaultStyle.StrokeOpacity := 1.0;
  FDefaultStyle.HasFill := True;
  FDefaultStyle.HasStroke := False;
end;

destructor TSVGRenderer.Destroy;
begin
  FElements.Free;
  inherited;
end;

procedure TSVGRenderer.LoadFromString(const ASVG: string);
begin
  Clear;
  ParseSVGDocument(ASVG);
end;

procedure TSVGRenderer.LoadFromFile(const AFileName: string);
var
  SVGContent: string;
  FileStream: TFileStream;
  StringStream: TStringStream;
begin
  FileStream := TFileStream.Create(AFileName, fmOpenRead);
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
  
  LoadFromString(SVGContent);
end;

procedure TSVGRenderer.ParseSVGDocument(const AXML: string);
var
  XMLDoc: IXMLDocument;
  RootNode: IXMLNode;
  ViewBoxStr: string;
  ViewBoxParts: TArray<string>;
begin
  try
    XMLDoc := NewXMLDocument;
    XMLDoc.LoadFromXML(AXML);
    XMLDoc.Active := True;
    
    RootNode := XMLDoc.DocumentElement;
    
    if RootNode.NodeName = 'svg' then
    begin
      // Отримуємо розміри
      if RootNode.HasAttribute('width') then
        FWidth := StrToFloatDef(RootNode.Attributes['width'], 24);
      if RootNode.HasAttribute('height') then
        FHeight := StrToFloatDef(RootNode.Attributes['height'], 24);
        
      // Отримуємо viewBox
      if RootNode.HasAttribute('viewBox') then
      begin
        ViewBoxStr := RootNode.Attributes['viewBox'];
        ViewBoxParts := ViewBoxStr.Split([' ', ',']);
        if Length(ViewBoxParts) >= 4 then
        begin
          FViewBox.Left := StrToFloatDef(ViewBoxParts[0], 0);
          FViewBox.Top := StrToFloatDef(ViewBoxParts[1], 0);
          FViewBox.Width := StrToFloatDef(ViewBoxParts[2], FWidth);
          FViewBox.Height := StrToFloatDef(ViewBoxParts[3], FHeight);
        end;
      end
      else
      begin
        FViewBox := RectF(0, 0, FWidth, FHeight);
      end;
      
      // Парсимо дочірні елементи
      ParseElement(RootNode);
    end;
  except
    // Ігноруємо помилки парсингу
  end;
end;

procedure TSVGRenderer.ParseElement(XMLNode: IXMLNode; ParentGroup: TSVGGroup);
var
  I: Integer;
  ChildNode: IXMLNode;
  Element: TSVGElement;
  Group: TSVGGroup;
  Path: TSVGPath;
  Circle: TSVGCircle;
  Rect: TSVGRect;
  Style: TSVGStyle;
  Transform: TSVGTransform;
begin
  for I := 0 to XMLNode.ChildNodes.Count - 1 do
  begin
    ChildNode := XMLNode.ChildNodes[I];
    Element := nil;
    
    if ChildNode.NodeName = 'path' then
    begin
      if ChildNode.HasAttribute('d') then
      begin
        Path := TSVGPath.Create(ChildNode.Attributes['d']);
        Element := Path;
      end;
    end
    else if ChildNode.NodeName = 'circle' then
    begin
      Circle := TSVGCircle.Create(
        StrToFloatDef(ChildNode.Attributes['cx'], 0),
        StrToFloatDef(ChildNode.Attributes['cy'], 0),
        StrToFloatDef(ChildNode.Attributes['r'], 0)
      );
      Element := Circle;
    end
    else if ChildNode.NodeName = 'rect' then
    begin
      Rect := TSVGRect.Create(
        StrToFloatDef(ChildNode.Attributes['x'], 0),
        StrToFloatDef(ChildNode.Attributes['y'], 0),
        StrToFloatDef(ChildNode.Attributes['width'], 0),
        StrToFloatDef(ChildNode.Attributes['height'], 0),
        StrToFloatDef(ChildNode.Attributes['rx'], 0),
        StrToFloatDef(ChildNode.Attributes['ry'], 0)
      );
      Element := Rect;
    end
    else if ChildNode.NodeName = 'g' then
    begin
      Group := TSVGGroup.Create;
      Element := Group;
      ParseElement(ChildNode, Group);
    end;
    
    if Element <> nil then
    begin
      // Парсимо стилі
      if ChildNode.HasAttribute('style') then
        Style := ParseStyle(ChildNode.Attributes['style'])
      else
        Style := FDefaultStyle;
        
      // Парсимо окремі атрибути стилю
      if ChildNode.HasAttribute('fill') then
      begin
        Style.Fill := ParseColor(ChildNode.Attributes['fill']);
        Style.HasFill := True;
      end;
      
      if ChildNode.HasAttribute('stroke') then
      begin
        Style.Stroke := ParseColor(ChildNode.Attributes['stroke']);
        Style.HasStroke := True;
      end;
      
      if ChildNode.HasAttribute('stroke-width') then
        Style.StrokeWidth := StrToFloatDef(ChildNode.Attributes['stroke-width'], 1);
        
      Element.Style := Style;
      
      // Парсимо трансформації
      if ChildNode.HasAttribute('transform') then
      begin
        Transform := ParseTransform(ChildNode.Attributes['transform']);
        Element.Transform := Transform;
      end;
      
      // Додаємо елемент
      if ParentGroup <> nil then
        ParentGroup.AddElement(Element)
      else
        FElements.Add(Element);
    end;
  end;
end;

function TSVGRenderer.ParseStyle(const StyleStr: string): TSVGStyle;
var
  Styles: TArray<string>;
  Style: string;
  Parts: TArray<string>;
begin
  Result := FDefaultStyle;
  
  Styles := StyleStr.Split([';']);
  
  for Style in Styles do
  begin
    Parts := Style.Split([':']);
    if Length(Parts) = 2 then
    begin
      Parts[0] := Trim(Parts[0]);
      Parts[1] := Trim(Parts[1]);
      
      if Parts[0] = 'fill' then
      begin
        Result.Fill := ParseColor(Parts[1]);
        Result.HasFill := True;
      end
      else if Parts[0] = 'stroke' then
      begin
        Result.Stroke := ParseColor(Parts[1]);
        Result.HasStroke := True;
      end
      else if Parts[0] = 'stroke-width' then
        Result.StrokeWidth := StrToFloatDef(Parts[1], 1);
    end;
  end;
end;

function TSVGRenderer.ParseTransform(const TransformStr: string): TSVGTransform;
begin
  // Спрощена реалізація парсингу трансформацій
  FillChar(Result, SizeOf(Result), 0);
  Result.ScaleX := 1.0;
  Result.ScaleY := 1.0;
  
  // Тут має бути повний парсинг SVG трансформацій
end;

function TSVGRenderer.ParseColor(const ColorStr: string): TColor;
begin
  if ColorStr = 'none' then
    Result := clNone
  else if ColorStr.StartsWith('#') then
  begin
    try
      Result := TColor(StrToInt('$' + Copy(ColorStr, 2, Length(ColorStr))));
    except
      Result := clBlack;
    end;
  end
  else if ColorStr = 'black' then
    Result := clBlack
  else if ColorStr = 'white' then
    Result := clWhite
  else if ColorStr = 'red' then
    Result := clRed
  else if ColorStr = 'green' then
    Result := clGreen
  else if ColorStr = 'blue' then
    Result := clBlue
  else
    Result := clBlack;
end;

function TSVGRenderer.ScalePoint(const Point: TPointF; const ViewBox: TRectF; ScaleX, ScaleY: Single): TPoint;
begin
  Result.X := Round((Point.X - ViewBox.Left) * ScaleX);
  Result.Y := Round((Point.Y - ViewBox.Top) * ScaleY);
end;

procedure TSVGRenderer.ApplyTransform(Canvas: TCanvas; const Transform: TSVGTransform; ScaleX, ScaleY: Single);
begin
  // Тут має бути застосування трансформацій до Canvas
end;

procedure TSVGRenderer.RenderToBitmap(Bitmap: TBitmap; AWidth, AHeight: Integer; ABackgroundColor: TColor);
var
  Element: TSVGElement;
  ScaleX, ScaleY: Single;
begin
  Bitmap.Width := AWidth;
  Bitmap.Height := AHeight;
  Bitmap.PixelFormat := pf32bit;
  
  // Очищуємо фон
  Bitmap.Canvas.Brush.Color := ABackgroundColor;
  Bitmap.Canvas.FillRect(Rect(0, 0, AWidth, AHeight));
  
  // Розраховуємо масштаб
  if (FViewBox.Width > 0) and (FViewBox.Height > 0) then
  begin
    ScaleX := AWidth / FViewBox.Width;
    ScaleY := AHeight / FViewBox.Height;
  end
  else
  begin
    ScaleX := 1.0;
    ScaleY := 1.0;
  end;
  
  // Рендеримо всі елементи
  for Element in FElements do
    Element.Render(Bitmap.Canvas, FViewBox, ScaleX, ScaleY);
end;

procedure TSVGRenderer.Clear;
begin
  FElements.Clear;
  FViewBox := RectF(0, 0, 24, 24);
  FWidth := 24;
  FHeight := 24;
end;

{ TSVGIconUtils }

class function TSVGIconUtils.CreateMaterialIcon(const IconName: string; Size: Integer): string;
begin
  // Тут мають бути шаблони Material Design іконок
  if IconName = 'home' then
    Result := Format('<svg width="%d" height="%d" viewBox="0 0 24 24"><path d="M10,20V14H14V20H19V12H22L12,3L2,12H5V20H10Z"/></svg>', [Size, Size])
  else if IconName = 'settings' then
    Result := Format('<svg width="%d" height="%d" viewBox="0 0 24 24"><path d="M12,15.5A3.5,3.5 0 0,1 8.5,12A3.5,3.5 0 0,1 12,8.5A3.5,3.5 0 0,1 15.5,12A3.5,3.5 0 0,1 12,15.5M19.43,12.97C19.47,12.65 19.5,12.33 19.5,12C19.5,11.67 19.47,11.34 19.43,11L21.54,9.37C21.73,9.22 21.78,8.95 21.66,8.73L19.66,5.27C19.54,5.05 19.27,4.96 19.05,5.05L16.56,6.05C16.04,5.66 15.5,5.32 14.87,5.07L14.5,2.42C14.46,2.18 14.25,2 14,2H10C9.75,2 9.54,2.18 9.5,2.42L9.13,5.07C8.5,5.32 7.96,5.66 7.44,6.05L4.95,5.05C4.73,4.96 4.46,5.05 4.34,5.27L2.34,8.73C2.22,8.95 2.27,9.22 2.46,9.37L4.57,11C4.53,11.34 4.5,11.67 4.5,12C4.5,12.33 4.53,12.65 4.57,12.97L2.46,14.63C2.27,14.78 2.22,15.05 2.34,15.27L4.34,18.73C4.46,18.95 4.73,19.03 4.95,18.95L7.44,17.94C7.96,18.34 8.5,18.68 9.13,18.93L9.5,21.58C9.54,21.82 9.75,22 10,22H14C14.25,22 14.46,21.82 14.5,21.58L14.87,18.93C15.5,18.68 16.04,18.34 16.56,17.94L19.05,18.95C19.27,19.03 19.54,18.95 19.66,18.73L21.66,15.27C21.78,15.05 21.73,14.78 21.54,14.63L19.43,12.97Z"/></svg>', [Size, Size])
  else
    Result := Format('<svg width="%d" height="%d" viewBox="0 0 24 24"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/></svg>', [Size, Size]);
end;

class function TSVGIconUtils.CreateFeatherIcon(const IconName: string; Size: Integer): string;
begin
  // Шаблони Feather іконок
  if IconName = 'menu' then
    Result := Format('<svg width="%d" height="%d" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>', [Size, Size])
  else
    Result := Format('<svg width="%d" height="%d" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/></svg>', [Size, Size]);
end;

class function TSVGIconUtils.CreateFontAwesomeIcon(const IconName: string; Size: Integer): string;
begin
  // Базові FontAwesome іконки
  Result := Format('<svg width="%d" height="%d" viewBox="0 0 24 24"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/></svg>', [Size, Size]);
end;

class function TSVGIconUtils.RecolorSVG(const ASVG: string; NewColor: TColor): string;
var
  ColorHex: string;
begin
  ColorHex := Format('#%s', [IntToHex(ColorToRGB(NewColor), 6)]);
  
  Result := ASVG;
  Result := StringReplace(Result, 'fill="black"', 'fill="' + ColorHex + '"', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'fill="#000000"', 'fill="' + ColorHex + '"', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'stroke="black"', 'stroke="' + ColorHex + '"', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, 'stroke="#000000"', 'stroke="' + ColorHex + '"', [rfReplaceAll, rfIgnoreCase]);
end;

class function TSVGIconUtils.ResizeSVG(const ASVG: string; NewWidth, NewHeight: Integer): string;
begin
  Result := ASVG;
  // Простий пошук і заміна розмірів
  Result := TRegEx.Replace(Result, 'width="\d+"', 'width="' + IntToStr(NewWidth) + '"');
  Result := TRegEx.Replace(Result, 'height="\d+"', 'height="' + IntToStr(NewHeight) + '"');
end;

class function TSVGIconUtils.ApplyTheme(const ASVG: string; IsDarkTheme: Boolean): string;
begin
  Result := ASVG;
  
  if IsDarkTheme then
  begin
    // Темна тема - використовуємо світлі кольори
    Result := RecolorSVG(Result, clWhite);
  end
  else
  begin
    // Світла тема - використовуємо темні кольори
    Result := RecolorSVG(Result, clBlack);
  end;
end;

end.