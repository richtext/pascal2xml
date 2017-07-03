unit mmObjectToXML;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Classes,
  TypInfo,
  DOM,
  XMLWrite,
  XMLRead,
  Variants;

type
  TObjectToXML = class(TObject)
  private
    FDoc: TXMLDocument;
    FObject: TObject;
    FStream: TMemoryStream;
    FXML: WideString;
    procedure FormatXML;
    function GetXML: WideString;
    procedure WriteListItems(AList: TList);
    procedure WriteObject(AProperty: string; AObject: TObject);
    procedure WriteProperty(AProperty, AValue: string);
  public
    constructor Create(AObject: TObject);
    destructor Destroy; override;
    property Obj: TObject read FObject write FObject;
    property XML: WideString read GetXML;
  end;


  { TObjectToXML }

implementation

{
********************************* TObjectToXML *********************************
}
constructor TObjectToXML.Create(AObject: TObject);
begin
  inherited Create;
  FDoc:=TXMLDocument.Create;
  FObject := AObject;
  FStream := TMemoryStream.Create;
end;

destructor TObjectToXML.Destroy;
begin
  FDoc.Free;
  FStream.Free;
  inherited;
end;

procedure TObjectToXML.FormatXML;
var
  XSize: Cardinal;
  XString: string;
begin
  XString := UTF8Encode(FXML);
  XSize := Length(XString);
  FStream.Clear;
  FStream.Write(XString[1], XSize * SizeOf(XString[1]));
  FStream.Seek(0, soFromBeginning);
  XSize := FStream.Size;
  FStream.Seek(0, soFromBeginning);
  ReadXMLFile(FDoc, FStream);
  FDoc.XMLVersion := '1.0';
  FStream.Seek(0, soFromBeginning);
  WriteXML(FDoc.DocumentElement, FStream);
  FStream.Seek(0, soFromBeginning);
  FStream.Write(FXML, FStream.Size);
end;

function TObjectToXML.GetXML: WideString;
begin
  FXML := '';
  if (FObject <> nil) then
  begin
    WriteObject('Object', FObject);
    FormatXML;
  end;
  Result := FXML;
end;

procedure TObjectToXML.WriteListItems(AList: TList);
var
  X: Cardinal;
begin
  FXML := UTF8Decode(Format('%s<%s>', [FXML, 'Items']));
  if (AList.Count > 0) then
  begin
    for X := 0 to AList.Count - 1 do
    begin
      WriteObject('Item', TObject(AList[X]));
    end;
  end;
  FXML := UTF8Decode(Format('%s</%s>', [FXML, 'Items']));
end;

procedure TObjectToXML.WriteObject(AProperty: string; AObject: TObject);
var
  XCount: Integer;
  XSize: Integer;
  X: Integer;
  XList: PPropList;
  XPropInfo: PPropInfo;
  XPropValue: string;
  XObject: TObject;
begin
  FXML := UTF8Decode(Format('%s<%s %s="%s">',
    [FXML, AProperty, 'ClassName', AObject.ClassName]));
  XCount := GetPropList(AObject.ClassInfo, tkAny, nil);
  XSize  := XCount * SizeOf(Pointer);
  GetMem(XList, XSize);
  try
    XCount := GetPropList(AObject.ClassInfo, tkAny, XList);
    if (XCount > 0) then
    begin
      for X := 0 to XCount - 1 do
      begin
        XPropInfo := XList^[X];
        case XPropInfo^.PropType^.Kind of
          tkClass:
            begin
              XObject := GetObjectProp(AObject, XPropInfo);
              if (Assigned(XObject)) then
              begin
                WriteObject(XPropInfo^.Name, XObject);
              end;
            end;
          tkArray:
            XPropValue := GetPropValue(AObject, XPropInfo^.Name);

          tkRecord:
            XPropValue := GetPropValue(AObject, XPropInfo^.Name);

          tkDynArray:
            XPropValue := GetPropValue(AObject, XPropInfo^.Name);

        else
          begin
            XPropValue := GetPropValue(AObject, XPropInfo^.Name);
            WriteProperty(XPropInfo^.Name, XPropValue);
          end
        end;
      end;
    end;
  {  if (AObject.InheritsFrom(TCollection)) then
    begin
      WriteCollectionItems(AObject as TCollection);
    end;       }
    if (AObject.InheritsFrom(TList)) then
    begin
      WriteListItems(AObject as TList);
    end;
  finally
    FreeMem(XList);
  end;
  FXML := UTF8Decode(Format('%s</%s>', [FXML, AProperty]));
end;

procedure TObjectToXML.WriteProperty(AProperty, AValue: string);
begin
  FXML := UTF8Decode(Format('%s<%s>%s</%s>', [FXML, AProperty, AValue,
    AProperty]));
end;


{
procedure TObjectToXML.WriteCollectionItems(ACollection: TCollection);
var
  X: Cardinal;
begin
  FXML := Format('%s<%s>', [FXML, 'Items']);
  if (ACollection.Count > 0) then
  begin
    for X := 0 to ACollection.Count - 1 do
    begin
      WriteObject('Item', ACollection.Items[X]);
    end;
  end;
  FXML := Format('%s</%s>', [FXML, 'Items']);
end;
}
end.
