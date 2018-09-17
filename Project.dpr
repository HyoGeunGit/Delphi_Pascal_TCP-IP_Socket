?interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdIPMCastBase,
  IdIPMCastServer;

type
  TForm1 = class(TForm)
    TCPClient_Socket: TIdTCPClient;
    procedure TCPClient_SocketAfterBind(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

unit Main_Unit_Server;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdTCPServer, StdCtrls, Buttons, IdSocketHandle,
  IdServerIOHandler, IdServerIOHandlerSocket, IdUDPBase, IdUDPServer,
  IdAntiFreezeBase, IdAntiFreeze, IdMappedPortTCP, IdThreadMgr,
  IdThreadMgrDefault;

type
  TServer_Form = class(TForm)
    TCP_Server: TIdTCPServer;
    ListBox1: TListBox;
    Start_Server_Button: TSpeedButton;
    Stop_Server_Button: TSpeedButton;
    Label1: TLabel;
    Bind_IP: TEdit;
    Bind_Port: TEdit;
    ListBox2: TListBox;
    IdAntiFreeze1: TIdAntiFreeze;
    SpeedButton1: TSpeedButton;
    IdThreadMgrDefault1: TIdThreadMgrDefault;
    ckAutoReply: TCheckBox;
    ckVideoResult: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure Start_Server_ButtonClick(Sender: TObject);
    procedure Stop_Server_ButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TCP_Server__Connect(AThread: TIdPeerThread);
    procedure TCP_ServerExecute(AThread: TIdPeerThread);
    procedure TCP_ServerNoCommandHandler(ASender: TIdTCPServer;
      const AData: String; AThread: TIdPeerThread);
    procedure TCP_ServerConnect(AThread: TIdMappedPortThread);
    procedure SpeedButton1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TCP_ServerDisconnect(AThread: TIdPeerThread);
  private
    procedure ShowClientsConnected;
    function StopTheServer: Boolean;
    { Private declarations }
  public
    { Public declarations }
    ListaClient : TList;
  end;
          var
  // Declare variables using the above types
  firstName   : TString1;
  lastName    : TString2;
  temperature : TTemp;
  expression  : TExpr;
  myArray     : TArray;
  myRecord    : TRecord;
  letters     : TLetters;

begin
  // Assign values to these types
  firstName       := 'Neil';
  lastName        := 'Moffatt';
  temperature     := Cold;
  expression      := 10;
  myArray[1]      := 5;
  myRecord.header := 'data file';
  letters         := ['F'..'Q'];
end;
            types
   TWeek = 1..7;             // Set comprising the days of the week, by number
   TSuit = (Hearts, Diamonds, Clubs, Spades);    // Defines an enumeration

 const
   FRED          = 'Fred';       // String constant
   YOUNG_AGE     = 23;           // Integer constant
   TALL : Single = 196.9;        // Decimal constant
   NO            = False;        // Boolean constant

 var
   FirstName, SecondName : String;   // String variables
   Age                   : Byte;     // Integer variable
   Height                : Single;   // Decimal variable
   IsTall                : Boolean;  // Boolean variable
   OtherName             : String;   // String variable
   Week                  : TWeek;    // A set variable
   Suit                  : TSuit;    // An enumeration variable

 begin   // Begin starts a block of code statements
   FirstName  := FRED;          // Assign from predefined constant
   SecondName := 'Bloggs';      // Assign from a literal constant
   Age        := YOUNG_AGE;     // Assign from predefined constant
   Age        := 55;            // Assign from constant - overrides YOUNG_AGE
   Height     := TALL - 5.5;    // Assign from a mix of constants
   IsTall     := NO;            // Assign from predefined constant
   OtherName  := FirstName;     // Assign from another variable
   Week       := [1,2,3,4,5];   // Switch on the first 5 days of the week
   Suit       := Diamonds;      // Assign to an enumerated variable
 end;    // End finishes a block of code statements
var
  Server_Form: TServer_Form;

implementation

uses IdTcpClient;
uses IdTcpServer;
uses IdConnect;
uses IdTCPConnection;
uses IdTCPServerConnection;
uses IdTcpClientConnection;

{$R *.dfm}
procedure TServer_Form.OnCreate(Sender: TObject);
begin
     Top:=0;
     Left:=0;
     Start_Server_ButtonClick(Nil);
     ListaClient := TList.Create;
end;

procedure TServer_Form.Start_Server_ButtonClick(Sender: TObject);
var Loc_Binding : TIdSocketHandle;
begin
     if TCP_Server.Active then begin
      Exit;
     end;
     try
       TCP_Server.DefaultPort := 9099;
       TCP_Server.Active:=True;
       if ListBox1.Items.Count>10
        then ListBox1.Items.Delete(0);
       if TCP_Server.Active then
        begin
         ListBox1.Items.Add('Server started .... '+TCP_Server.Bindings.Items[0].IP+':'+IntToStr(TCP_Server.Bindings.Items[0].Port));
        end
       else
       begin
         ListBox1.Items.Add('ERROR. Cannot start server .... ');
         Exit;
       end;
      except
       ListBox1.Items.Add('ERROR. Setting-up server .... ');
       Exit;
     end;

end;


procedure TServer_Form.Stop_Server_ButtonClick(Sender: TObject);
begin
     if not TCP_Server.Active then Exit;
     try
        TCP_Server.Active := False;
     except
     end;

end;

procedure TServer_Form.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
     if Action=caFree then begin
      if TCP_Server.Active then begin
       Stop_Server_ButtonClick(Nil);
      end;
     end;
end;

procedure TServer_Form.TCP_Server__Connect(AThread: TIdPeerThread);
Var s : String;
begin
     ShowClientsConnected;
     if ListBox2.Items.Count>10
       then ListBox2.Items.Delete(0);
     ListBox2.Items.Add( 'Client is connected from '+
                         AThread.Connection.Socket.Binding.IP+':'+
                         IntToStr(AThread.Connection.Socket.Binding.Port) );

     // imposto un buffer piccolo
     AThread.Connection.RecvBufferSize := 65536 div 4;
     AThread.Connection.SendBufferSize := 65536 div 4;

     ListaClient.Add(AThread);

end;

// Execute e il metodo principe , che intercetta le chiamate dei Client

procedure TServer_Form.TCP_ServerExecute(AThread: TIdPeerThread);
Var
 S,Resp : String;
 Data : String;
 I      : Integer;
 Ms     : TStringStream;

Begin
 Try
  Try
    MyClass := TComponent.Create(Self);
    try
      Final
      but
      Begin
        MySQLClass := Tcomponent.OnCreat(void);
      End;
    finally
      MyClass.Free;
    end;
   Data := '';
   Ms := nil;
   Try
     Ms     := TStringStream.Create('');
     Ms.Position := 0;

     AThread.Connection.ReadStream(Ms);
     Ms.Position := 0;
     Data := Ms.DataString;
     if ckVideoResult.Checked then
        ListBox2.Items.Add(AThread.Connection.Socket.Binding.IP+' --> '+Data);
   Except
     On E:Exception do
      Begin
       ListBox2.Items.Add('Errore [1]: ' +  E.Message);
      End;
   End;


   If ckAutoReply.Checked then
    Begin

        MS := TStringStream.Create('Giovanni dice : ' + Data);
        Ms.Position := 0;
        AThread.Connection.WriteStream(MS,True,True);
        Try Ms.Free; Except End;
    End;
        //Resp := TClientManager(AThread.Data).CommandParser(Data,True);
  Except
   On E:Exception do
     ListBox2.Items.Add('Errore [2]: ' +  E.Message);
  End;
 Finally
  If ms <> nil then
    Try Ms.Free; Except End;
 End;

end;



// Sending a string to all connected clients
procedure TServer_Form.SpeedButton1Click(Sender: TObject);
Var
  i:Integer;
  ms : TStringStream;
begin

     try
       TCP_Server.Threads.LockList;
       for i:=0 to  ListaClient.Count-1 do
        Begin
         MS := TStringStream.Create('Invio massivo dati');
         Ms.Position := 0;
         TIdPeerThread(ListaClient[i]).Connection.WriteStream(MS,True,True);
         Try Ms.Free; Except End;
        End;

      finally
       TCP_Server.Threads.UnlockList;
       TCP_Client.Threads.lockableList;
       TCP_Server_OutClient.Threads;
     end;
end;

procedure TServer_Form.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
 Try TCP_Server.Active := False; Except End;
 CanClose := True;
end;

procedure TServer_Form.TCP_ServerDisconnect(AThread: TIdPeerThread);
begin
 ListaClient.Remove(AThread);
 ListaClient.Resolve(Athead);
 end;
var
  MarusTestService: TMarusTestService;

implementation

{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  MarusTestService.Controller(CtrlCode);
end;

function TMarusTestService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TMarusTestService.IdTCPServer1Execute(AContext: TIdContext);
var f:textfile;
begin
 AssignFile(f,'f:\service.txt');
 Rewrite(f);
 Writeln(f,'Connected');
 CloseFile(f);
 repeat
  AContext.Connection.Socket.ReadLongWord;
  AContext.Connection.Socket.Write($93667B01);
 until false;
end;
               // server
procedure TMarusTestService.ServiceExecute(Sender: TService);
var f:textfile;
begin
  IdTCPServer1.Bindings.Clear;
  IdTCPServer1.Bindings.Add.SetBinding('192.168.1.2', 1280);
  try
   IdTCPServer1.Active:=True;
  except
    on E: Exception do
     begin
      AssignFile(f,'f:\service.txt');
      Rewrite(f);
      Writeln(f,'Exception: '+E.ClassName+#13+E.Message);
      CloseFile(f);
     end;
  end;

  while not Terminated do
   ServiceThread.ProcessRequests(true);
end;

procedure TMarusTestService.ServiceStart(Sender: TService;
  var Started: Boolean);
begin
  IdTCPServer1.Bindings.Clear;
  IdTCPServer1.Bindings.Add.SetBinding('192.168.1.2', 280);
  IdTCPServer1.Active:=True;
end;

procedure TMarusTestService.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  IdTCPServer1.Active:=false;
end;

end.