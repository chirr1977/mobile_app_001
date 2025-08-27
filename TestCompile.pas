program TestCompile;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  ModernToolBar in 'ModernToolBar.pas',
  SVGRenderer in 'SVGRenderer.pas',
  HighDPISupport in 'HighDPISupport.pas',
  IconSets in 'IconSets.pas';

begin
  try
    Writeln('Modern ToolBar компоненти успішно скомпільовані!');
    Writeln('Усі модулі підключені правильно.');
    Writeln('Натисніть Enter для виходу...');
    Readln;
  except
    on E: Exception do
    begin
      Writeln('Помилка: ', E.ClassName, ': ', E.Message);
      Readln;
    end;
  end;
end.