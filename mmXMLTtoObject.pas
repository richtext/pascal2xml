unit mmXMLTtoObject;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  Classes,
  TypInfo,
  laz2_DOM,
  laz2_XMLRead,
  Variants;

type

  TXMLToObjectCreateObjectEvent = procedure (AOwner: TObject; var ANewObject:
    TObject; AClassName: AnsiString) of object;
  TXMLToObject = class(TObject)
  private
    FDoc: TXMLDocument;
    FObject: TObject;
    FOnCreateObject: TXMLToObjectCreateObjectEvent;
    FStream: TMemoryStream;
    FXML: WideString;
    procedure CreateObject(AClassName: AnsiString; var AObject: TObject);
    function GetObject: TObject;
    procedure ReadListItems(AList: TList; ANode: TDomNode);
    procedure ReadProperties(ANode: TDomNode; AObject: TObject);
    procedure ReadProperty(APropInfo: PPropInfo; ANode: TDomNode; AObject:
      TObject);
    procedure ReadXML;
  public
    constructor Create(AXML: WideString);
    destructor Destroy; override;
    property Obj: TObject read GetObject;
    property XML: WideString read FXML write FXML;
    property OnCreateObject: TXMLToObjectCreateObjectEvent read FOnCreateObject
      write FOnCreateObject;
  end;

  { TXMLToObject }

implementation

{
********************************* TXMLToObject *********************************
}
constructor TXMLToObject.Create(AXML: WideString);
begin
  inherited Create;
  FXML:=AXML;
  FDoc:=TXMLDocument.Create;
  FStream:=TMemoryStream.Create;
end;

destructor TXMLToObject.Destroy;
begin
  FDoc.Free;
  FStream.Free;
  inherited Destroy;
end;

procedure TXMLToObject.CreateObject(AClassName: AnsiString; var AObject:
  TObject);
begin
  Assert((Assigned(FOnCreateObject)),
    'TXMLToObject.OnCreateObject not assigned.');
  AObject:=nil;
  FOnCreateObject(FObject, AObject, AClassName);
  Assert((Assigned(AObject) and (AObject <> nil)),
    Format('Class %s not implemented in TXMLToObject.OnCreateObject event.',
      [AClassName]));
end;

function TXMLToObject.GetObject: TObject;
var
  XClassName: AnsiString;
  XNodeName: WideString;
begin
  Result:=nil;
  FObject:=nil;
  ReadXML;
  XNodeName:=UTF8Decode(FDoc.DocumentElement.GetAttribute('ClassName'));
  XClassName:=UTF8Encode(XNodeName);
  CreateObject(XClassName, FObject);
  ReadProperties(FDoc.DocumentElement, FObject);
  Result:=FObject;
  Assert((FObject <> nil), 'FObject = nil.');
end;

procedure TXMLToObject.ReadListItems(AList: TList; ANode: TDomNode);
var
  X: Cardinal;
  XNodeItem: TDomNode;
  XClassName: AnsiString;
  XNodeName: WideString;
  XItem: TObject;
  XCount: Integer;
begin
  Assert((AList <> nil), 'AList = nil.');
  Assert((ANode <> nil), 'ANode = nil.');
  XItem:=nil;
  XCount:=ANode.ChildNodes.Count;
  if (XCount > 0) then
  begin
    for X:=0 to XCount - 1 do
    begin
      XNodeItem:=ANode.ChildNodes[X];
      if (XNodeItem.HasAttributes) then
      begin
        XNodeName:=UTF8Decode(XNodeItem.Attributes[0].NodeValue);
        XClassName:=UTF8Encode(XNodeName);
        CreateObject(XClassName, XItem);
        ReadProperties(XNodeItem, XItem);
        AList.Add(XItem);
      end;
    end;
  end;
end;

procedure TXMLToObject.ReadProperties(ANode: TDomNode; AObject: TObject);
var
  XCount: Integer;
  XSize: Integer;
  XList: PPropList;
  XPropInfo: PPropInfo;
  XNode: TDomNode;
  X: Integer;
  XPropertyName: AnsiString;
  XNodeName: WideString;
  XListNode: TDomNode;
begin
  Assert((ANode <> nil), 'ANode = nil.');
  Assert((AObject <> nil), 'AObject = nil.');
  XCount:=GetPropList(AObject.ClassInfo, tkAny, nil);
  XSize :=XCount * SizeOf(Pointer);
  GetMem(XList, XSize);
  try
    XCount:=GetPropList(AObject.ClassInfo, tkAny, XList);
//    if (XCount > 0) then
//    begin
      for X:=0 to XCount - 1 do
      begin
        XPropInfo:=XList^[X];
        XPropertyName:=XPropInfo^.Name;
        XNodeName:=UTF8Decode(XPropertyName);
        XNode:=ANode.FindNode(UTF8Encode(XNodeName));
        if (XNode <> nil) then
        begin
          ReadProperty(XPropInfo, XNode, AObject);
        end;
      end;
//    end;
    if (AObject.InheritsFrom(TList)) then
    begin
      XListNode:=ANode.FindNode('Items');
      ReadListItems(AObject as TList, XListNode);
    end;
  finally
    FreeMem(XList);
  end;
end;

procedure TXMLToObject.ReadProperty(APropInfo: PPropInfo; ANode: TDomNode;
  AObject: TObject);
var
  XObject: TObject;
  XClassName: AnsiString;
  XPropertyName: AnsiString;
  XNodeName: WideString;
  XPropertyValue: WideString;
begin
  Assert((ANode <> nil), 'ANode = nil.');
  Assert((AObject <> nil), 'AObject = nil.');
  Assert((APropInfo <> nil), 'APropInfo = nil');
  Assert((APropInfo^.PropType^.Kind <> tkArray),
    'Property type tkArray not implemented.');
  Assert((APropInfo^.PropType^.Kind <> tkRecord),
    'Property type tkRecord not implemented.');
  Assert((APropInfo^.PropType^.Kind <> tkDynArray),
    'Property type tkDynArray not implemented.');
  XObject:=nil;
  if (APropInfo^.PropType^.Kind = tkClass) then
  begin
    XObject:=GetObjectProp(AObject, APropinfo);
    if (not Assigned(XObject)) then
    begin
      XNodeName:=UTF8Decode(ANode.Attributes[0].NodeValue);
      XClassName:=UTF8Encode(XNodeName);
      CreateObject(XClassName, XObject);
      SetObjectProp(AObject, APropInfo, XObject);
    end;
    ReadProperties(ANode, XObject);
  end
  else
  begin
    XNodeName:=UTF8Decode(ANode.NodeName);
    XPropertyName:=UTF8Encode(XNodeName);
    if  (ANode.ChildNodes.Count = 1)
    and (ANode.ChildNodes[0].NodeValue <> '') then
    begin
      XPropertyValue:=UTF8Decode(ANode.ChildNodes[0].NodeValue);
    end;
    SetPropValue(AObject, XPropertyName,  XPropertyValue);
  end;
end;

procedure TXMLToObject.ReadXML;
var
  XSize: Cardinal;
  XString: string;
begin
  XString:='';
  FXML:=Trim(FXML);
  XString:=UTF8Encode(FXML);
  XSize:=Length(XString);
  FStream.Clear;
  FStream.Write(XString[1], XSize * SizeOf(XString[1]));
  FStream.Seek(0, soFromBeginning);
  FStream.Position:=0;
  ReadXMLFile(FDoc, FStream);
end;


{$ASSERTIONS ON}
{ TXMLToObject }

end.
