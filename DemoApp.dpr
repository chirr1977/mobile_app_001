program DemoApp;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {frmMain},
  ModernToolBar in 'ModernToolBar.pas',
  SVGRenderer in 'SVGRenderer.pas',
  HighDPISupport in 'HighDPISupport.pas',
  IconSets in 'IconSets.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Modern ToolBar Demo';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.