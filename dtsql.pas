unit dtSQL;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, BufDataset, IBConnection, SQLDB, MSSQLConn,
  ZConnection, ZDataset, ZIBEventAlerter, ZSqlUpdate, ZSqlMetadata, rxmemds,
  DBLib;

type

  { TdtmSQL }

  TdtmSQL = class(TDataModule)
    bdtTabelasID: TLongintField;
    bdtTabelasnometabela: TStringField;
    bdtTabelasprocessada: TStringField;
    bdtTabelastabela: TStringField;
    cdsTabelasid: TLongintField;
    cdsTabelasnometabela: TStringField;
    cdsTabelasnometabela_fk: TStringField;
    cdsTabelasprocessada: TStringField;
    dtsTabelas: TDataSource;
    dtsSource: TDataSource;
    IBConn: TIBConnection;
    qryms_Aux: TZQuery;
    qryTabela: TSQLQuery;
    IBTrans: TSQLTransaction;
    qrySource: TSQLQuery;
    MSConn: TZConnection;
    qryDestino: TZQuery;
    SQLTransaction1: TSQLTransaction;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private

  public

  end;

var
  dtmSQL: TdtmSQL;

implementation

{$R *.lfm}

{ TdtmSQL }

procedure TdtmSQL.DataModuleCreate(Sender: TObject);
begin
    InitialiseDBLib('C:\NB-Documentos\Clientes\Cato\Conversao\Lazarus\ntwdblib.dll');
    if IBConn.Connected then
    begin
        IBConn.Connected := False;
        IBTrans.Active   := False;
    end;
    //
    if MSConn.Connected then
    begin
        MSConn.Connected := False;
    end;
    //
    IBConn.Connected := True;
    IBTrans.Active   := True;
    //
    MSConn.Connected := True;

end;

procedure TdtmSQL.DataModuleDestroy(Sender: TObject);
begin
    if IBConn.Connected then
    begin
        IBConn.Connected := False;
        MSConn.Connected := False;
        //
        IBTrans.Active := False;
    end;
end;

end.

