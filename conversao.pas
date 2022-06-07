unit Conversao;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Variants, DB, Forms, Controls, Graphics, Dialogs, DBGrids, StdCtrls,
  ZDataset;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnTodos: TButton;
    btnUnico: TButton;
    Button1: TButton;
    grdTabelas: TDBGrid;
    grdProcessados: TDBGrid;
    Memo1: TMemo;
    procedure btnTodosClick(Sender: TObject);
    procedure btnUnicoClick(Sender: TObject);
    procedure grdTabelasDblClick(Sender: TObject);
  private
    function f_PreparaTabelaDest(aNomeTabela: string): boolean;
    procedure p_prepara_tabela_src(aNomeTabela: String);
    function  f_prepara_dest(aValor: TStringList): Boolean;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}
uses dtSQL;

{ TForm1 }

procedure TForm1.btnTodosClick(Sender: TObject);
var i: Integer;
    a: String;
begin
    // Abre o arquivo de tabelas
    with dtmSQL do
    begin
        dtsTabelas.DataSet.Active := False;
        dtsTabelas.DataSet.Active := True;
    end;
    Memo1.Lines.Clear;
    // Processa as tabels
    with dtmSQL do
    begin
        while not dtsTabelas.DataSet.EOF do
        begin
            Application.ProcessMessages;
            //
            Memo1.Lines.Add('--***** TABELAS PROCESSADAS');
            Memo1.Lines.Add('DELETE FROM ' + trim(qryTabela.FieldByName('TABELA').AsString) + ';');
            Memo1.Lines.Add('go');
            //
            f_PreparaTabelaDest(qryTabela.FieldByName('TABELA').AsString);
            //
            dtsTabelas.DataSet.Next;;
        end;
    end;
end;

procedure TForm1.btnUnicoClick(Sender: TObject);
begin
    // Abre o arquivo de tabelas
    with dtmSQL do
    begin
        dtsTabelas.DataSet.Active := False;
        dtsTabelas.DataSet.Active := True;
    end;
    Memo1.Lines.Clear;
    Memo1.Lines.Add('--*****************************************************************************************');
    Memo1.Lines.Add('--********************************** TABELAS PROCESSADAS **********************************');
    Memo1.Lines.Add('--*****************************************************************************************');
end;

procedure TForm1.grdTabelasDblClick(Sender: TObject);
var i: Integer;
    a: String;
begin
    // Processa as tabels
    with dtmSQL do
    begin
        Memo1.Lines.Add('--***** TABELAS PROCESSADAS');
        Memo1.Lines.Add('DELETE FROM ' + trim(qryTabela.FieldByName('TABELA').AsString) + ';');
        Memo1.Lines.Add('go');
        f_PreparaTabelaDest(qryTabela.FieldByName('TABELA').AsString);
    end;
end;

procedure TForm1.p_prepara_tabela_src(aNomeTabela: String);
begin
    with dtmSQL do
    begin
        qrySource.Active := False;
        qrySource.SQL.Clear;
        qrySource.SQL.Add('SELECT * FROM ' + aNomeTabela);
        qrySource.Active := True;
    end;
end;

function TForm1.f_PreparaTabelaDest(aNomeTabela: string): boolean;
var i, x: integer;
    fSeparador: string;
    FScript,
    FValues,
    Fvalor: TStringList;
begin
    DecimalSeparator := '.';
    ShortDateFormat  := 'yyyy/mm/dd';

    FScript := TStringList.Create;
    FScript.Clear;
    Fscript.Add('INSERT INTO ' + trim(aNomeTabela) + '(');
    //
    FValues := TStringList.Create;
    FValues.Clear;
    FValues.Add(' VALUES (');
    //
    Fvalor := TStringList.Create;
    Fvalor.Clear;
    // Monta o Script de inclusão
    with dtmSQL do
    begin
        qryms_Aux.Active := False;
        qryms_Aux.SQL.Clear;
        qryms_Aux.SQL.Add('SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE,');
        qryms_Aux.SQL.Add('ISNULL((select COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where (COLUMNPROPERTY(object_id(TABLE_SCHEMA+''.''+TABLE_NAME), COLUMN_NAME, ''IsIdentity'') = 1) AND TABLE_NAME = :TABLE_NAME ),'''') AS COLUMN_AUTO ');
        qryms_Aux.SQL.Add('FROM INFORMATION_SCHEMA.COLUMNS');
        qryms_Aux.SQL.Add('WHERE TABLE_NAME = :TABLE_NAME');
        qryms_Aux.ParamByName('TABLE_NAME').AsString := aNomeTabela;
        qryms_Aux.Active := True;
        //
        qryms_Aux.First;
        fSeparador := '';
        while not qryms_Aux.EOF do
        begin
            Application.ProcessMessages;
            //
            if qryms_Aux.FieldByName('COLUMN_AUTO').AsString <> qryms_Aux.FieldByName('COLUMN_NAME').AsString then
            begin
                FScript.Add(fSeparador + qryms_Aux.FieldByName('COLUMN_NAME').AsString);
                FValues.Add(fSeparador + ':' + qryms_Aux.FieldByName('COLUMN_NAME').AsString);
                //
                fSeparador := ', ';
            end;
            qryms_Aux.Next;
        end;
        //
        FScript.Add(')');
        FValues.Add(')');
        //
        qryDestino.Active := False;
        qryDestino.SQL.Clear;
        qryDestino.SQL.Add(FScript.Text + FValues.Text);
        // Prepara a tabela de destino com os campos Originais.
        qryms_Aux.First;
        while not qryms_Aux.EOF do
        begin
            Application.ProcessMessages;
            //
            if qryms_Aux.FieldByName('COLUMN_AUTO').AsString <> qryms_Aux.FieldByName('COLUMN_NAME').AsString then
            begin
                if (qryms_Aux.FieldByName('DATA_TYPE').AsString = 'char') or
                   (qryms_Aux.FieldByName('DATA_TYPE').AsString = 'varchar') or
                   (qryms_Aux.FieldByName('DATA_TYPE').AsString = 'text') then
                begin
                    qryDestino.Params.CreateParam(ftString, qryms_Aux.FieldByName('COLUMN_NAME').AsString,ptInput);
                    if qryms_Aux.FieldByName('IS_NULLABLE').AsString = 'NO' then
                    begin
                        qryDestino.ParamByName(qryms_Aux.FieldByName('COLUMN_NAME').AsString).AsString := '.';
                        Fvalor.AddPair(qryms_Aux.FieldByName('COLUMN_NAME').AsString,'.');
                    end
                    else
                    begin
                        qryDestino.ParamByName(qryms_Aux.FieldByName('COLUMN_NAME').AsString).AsString := EmptyStr;
                        Fvalor.AddPair(qryms_Aux.FieldByName('COLUMN_NAME').AsString, EmptyStr);
                    end;
                end
                else if (qryms_Aux.FieldByName('DATA_TYPE').AsString = 'datetime') or
                   (qryms_Aux.FieldByName('DATA_TYPE').AsString = 'int') or
                   (qryms_Aux.FieldByName('DATA_TYPE').AsString = 'smallint') or
                   (qryms_Aux.FieldByName('DATA_TYPE').AsString = 'numeric') then
                begin
                    if uppercase(qryms_Aux.FieldByName('COLUMN_NAME').AsString) = 'EMPRESA_ID' Then
                    begin
                       qryDestino.ParamByName(qryms_Aux.FieldByName('COLUMN_NAME').AsString).AsString := '1';
                       Fvalor.AddPair(qryms_Aux.FieldByName('COLUMN_NAME').AsString, '1');
                    end
                    else
                    begin
                       qryDestino.ParamByName(qryms_Aux.FieldByName('COLUMN_NAME').AsString).AsString := '0';
                       Fvalor.AddPair(qryms_Aux.FieldByName('COLUMN_NAME').AsString, '0');
                    end;
                end;
            end;
            qryms_Aux.next;
        end;
        // Abre a tabela Source
        p_prepara_tabela_src(aNomeTabela);
        //
        while not qrySource.EOF do
        begin
            Application.ProcessMessages;
            //
            for i := 0 to Fvalor.Count -1 do
            begin
                Application.ProcessMessages;
                //
                for x := 0 to qrySource.Fields.Count -1 do
                begin
                    if (Fvalor.Names[i] = qrySource.Fields[x].FieldName)  then
                    begin
                        if qrySource.Fields[x].DataType in [ftString, ftFmtMemo, ftFixedChar, ftBlob, ftMemo] then
                        begin
                            if (qrySource.Fields[x].IsNull) or
                               (qrySource.Fields[x].AsString = EmptyStr)then
                            begin
                                Fvalor.Values[Fvalor.Names[i]] := EmptyStr;
                            end
                            else
                            begin
                                Fvalor.Values[Fvalor.Names[i]] := qrySource.FieldByName(Fvalor.Names[i]).AsString;
                            end;
                        end
                        else if qrySource.Fields[x].DataType in [ftDateTime, ftDate, ftTime, ftTimeStamp] then
                        begin
                            if (qrySource.Fields[x].IsNull) or
                               (qrySource.Fields[x].AsString = EmptyStr)then
                            begin
                                Fvalor.Values[Fvalor.Names[i]] := 'datetime';
                            end
                            else
                            begin
                                Fvalor.Values[Fvalor.Names[i]] := DateTimeToStr(qrySource.FieldByName(Fvalor.Names[i]).AsDateTime);
                            end;
                        end
                        else if qrySource.Fields[x].DataType in [ftInteger, ftLargeint, ftSmallint, ftWord] then
                        begin
                            if (qrySource.Fields[x].IsNull) or
                               (qrySource.Fields[x].AsString = EmptyStr)then
                            begin
                                Fvalor.Values[Fvalor.Names[i]] := '0';
                            end
                            else
                            begin
                                Fvalor.Values[Fvalor.Names[i]] := qrySource.FieldByName(Fvalor.Names[i]).AsString;
                            end;
                        end
                        else if qrySource.Fields[x].DataType in [ftBCD, ftCurrency, ftFloat] then
                        begin
                            if (qrySource.Fields[x].IsNull) or
                               (qrySource.Fields[x].AsString = EmptyStr)then
                            begin
                                Fvalor.Values[Fvalor.Names[i]] := '0';
                            end
                            else
                            begin
                                Fvalor.Values[Fvalor.Names[i]] := FormatFloat('0.00', qrySource.FieldByName(Fvalor.Names[i]).AsFloat);
                            end;
                        end;
                    end;
                end;
            End;
            // Processar a tabela de destino
            f_prepara_dest(Fvalor);
            qrySource.Next;
        end;
        //
    end;
    FScript.Free;
    FValues.Free;
    Fvalor.Free;
end;

function TForm1.f_prepara_dest(aValor: TStringList): Boolean;
var i: integer;
begin
    with dtmSQL do
    begin
        // Memo1.lines.Add('***** OUTRO REGISTRO *****');
        for i := 0 to aValor.Count -1 do
        begin
            aValor.Names[i]; // Traz o campo
//            ShowMessage(aValor.Strings[i]); // Campo = valor
            aValor.Text; // Traz todos os campos = valor
            aValor.ValueFromIndex[i];  // Traz o valor
            aValor.Values[aValor.Names[i]];  // Traz o valor
            if  trim(aValor.Values[aValor.Names[i]]) = EmptyStr then
            begin
                qryDestino.ParamByName(aValor.Names[i]).AsString := '';
            end
            else if aValor.Values[aValor.Names[i]] = 'datetime' then
                qryDestino.ParamByName(aValor.Names[i]).clear
            else
               qryDestino.ParamByName(aValor.Names[i]).AsString := aValor.Values[aValor.Names[i]];
//            Memo1.lines.Add(aValor.Strings[i]);
        end;
        qryDestino.Prepare;
        qryDestino.ExecSQL;
    end;
end;

end.

