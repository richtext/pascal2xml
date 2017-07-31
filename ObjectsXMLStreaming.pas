program ObjectsXMLStreaming;

{$ASSERTIONS ON}

uses
  SysUtils,
  Classes,
  Dialogs,
  TypInfo,
  DOM,
  XMLWrite,
  XMLRead,
  mmObjectToXML,
  mmXMLToObject,
  Variants;

type

  { TCostumer }

  TCustomer = class(TObject)
  private
    FId: Cardinal;
    FName: WideString;
  published
    property Id: Cardinal read FId write FId;
    property Name: WideString read FName write FName;
  end;

  { TOrder }

  TOrder = class(TPersistent)
  private
    FCustomer: TCustomer;
    FId: Cardinal;
    FItems: TList;
  public
    constructor Create;
  published
    property Customer: TCustomer read FCustomer write FCustomer;
    property Id: Cardinal read FId write FId;
    property Items: TList read FItems write FItems;
  end;

  { TItem }

  TItem = class(TObject)
  private
    FComment: TStringList;
    FId: Cardinal;
    FName: WideString;
    FPrice: Currency;
    FQuantity: Double;
  published
    property Id: Cardinal read FId write FId;
    property Name: WideString read FName write FName;
    property Quantity: Double read FQuantity write FQuantity;
    property Price: Currency read FPrice write FPrice;
    property Comment: TStringList read FComment write FComment;
  end;

  {TTestStreaming}

  TTestStreaming = class(TPersistent)
  private
    FOrderFrom: TOrder;
    FOrderTo: TOrder;
    FXML: WideString;
    procedure CreateOrderFrom;
  public
    constructor Create;
    destructor Destroy; override;
    procedure CreateObject(AOwner: TObject; var ANewObject: TObject;
      AClassName: AnsiString);
    procedure TestXMLToObject;
    procedure TestObjectToXML;
    property XML: WideString read FXML;
    property OrderFrom: TOrder read FOrderFrom;
    property OrderTo: TOrder read FOrderTo;
  end;

constructor TOrder.Create;
begin
  inherited;
  FItems := TList.Create;
  FCustomer := TCustomer.Create;
end;

procedure TTestStreaming.CreateOrderFrom;
var
  XItem: TItem;
begin
  FOrderFrom := TOrder.Create;
  FOrderFrom.Id := 10;
  FOrderFrom.Customer.Id := 99;
  FOrderFrom.Customer.Name :=
    UTF8Decode('WCRM 世界餐福事工 - 餐廳員工沒精打采? 老是打盤');
  XItem := TItem.Create;
  // Add item 1
  XItem.Id:=1;
  XItem.Name:='Hat';
  XItem.Quantity:=2;
  XItem.Price:=98.37;
  FOrderFrom.Items.Add(XItem);
  // Add item 2
  XItem.Id:=1;
  XItem.Name:='Diamond ring';
  XItem.Quantity:=1;
  XItem.Price:=3457.34;
  FOrderFrom.Items.Add(XItem);
end;

constructor TTestStreaming.Create;
begin
  inherited;
end;

destructor TTestStreaming.Destroy;
begin
  inherited Destroy;
end;

procedure TTestStreaming.CreateObject(AOwner: TObject; var ANewObject: TObject;
  AClassName: AnsiString);
begin
  if (AClassName = 'TOrder') then
  begin
    ANewObject := (TOrder.Create as TObject);
  end
  else
  if (AClassName = 'TList') then
  begin
    ANewObject := (TList.Create as TObject);
  end
  else
  if (AClassName = 'TCustomer') then
  begin
    ANewObject := (TCustomer.Create as TObject);
  end
  else
  if (AClassName = 'TItem') then
  begin
    ANewObject := (TItem.Create as TObject);
  end
  else
  if (AClassName = 'TCollectionItem') then
  begin
    ANewObject := (TCollectionItem.Create(AOwner as TCollection) as TObject);
  end
  else
  if (AClassName = 'TStringList') then
  begin
    ANewObject := (TStringList.Create as TObject);
  end;
end;

procedure TTestStreaming.TestXMLToObject;
var
  XXMLToObject: TXMLToObject;
begin
  XXMLToObject := TXMLToObject.Create(FXML);
  try
    XXMLToObject.OnCreateObject := CreateObject;
    FOrderTo := XXMLToObject.Obj as TOrder;
  finally
    XXMLToObject.Free;
  end;
end;

procedure TTestStreaming.TestObjectToXML;
var
  XObjectToXML: TObjectToXML;

begin
  XObjectToXML:=TObjectToXML.Create(FOrderFrom);
  try
    FXML:=XObjectToXML.XML;
  finally
    XObjectToXML.Free;
  end;
end;

var
  XTest: TTestStreaming;
begin
  XTest := TTestStreaming.Create;
  try
    XTest.CreateOrderFrom;
    XTest.TestObjectToXML;
    XTest.TestXMLToObject;
    Assert((XTest.OrderFrom.Id = XTest.OrderTo.Id),
      'XOrderFrom.Id <> XOrderTo.Id');
    Assert((XTest.OrderFrom.Customer.Id = XTest.OrderTo.Customer.Id),
      'XOrderFrom.Customer.Id <> XTest.OrderTo.Customer.Id');
    Assert((XTest.OrderFrom.Customer.Name = XTest.OrderTo.Customer.Name),
      'XOrderFrom.Customer.Name <> XTest.OrderTo.Customer.Name');
    Assert((XTest.OrderFrom.Items.Count = XTest.OrderTo.Items.Count),
      'XTest.OrderFrom.Items.Count = XTest.OrderTo.Items.Count');
    Assert((TItem(XTest.OrderFrom.Items[0]).Id = TItem(XTest.OrderTo.Items[0]).Id),
      'TItem(XTest.OrderFrom.Items[0]).Id <> TItem(XTest.OrderTo.Items[0]).Id');
    Assert((TItem(XTest.OrderFrom.Items[0]).Name = TItem(XTest.OrderTo.Items[0]).Name),
      'TItem(XTest.OrderFrom.Items[0]).Name <> TItem(XTest.OrderTo.Items[0]).Name');
    Assert((TItem(XTest.OrderFrom.Items[0]).Quantity = TItem(XTest.OrderTo.Items[0]).Quantity),
      'TItem(XTest.OrderFrom.Items[0]).Quantity <> TItem(XTest.OrderTo.Items[0]).Quantity');
    Assert((TItem(XTest.OrderFrom.Items[0]).Price = TItem(XTest.OrderTo.Items[0]).Price),
      'TItem(XTest.OrderFrom.Items[0]).Price <> TItem(XTest.OrderTo.Items[0]).Price');
    Assert((TItem(XTest.OrderFrom.Items[1]).Id = TItem(XTest.OrderTo.Items[1]).Id),
      'TItem(XTest.OrderFrom.Items[1]).Id <> TItem(XTest.OrderTo.Items[1]).Id');
    Assert((TItem(XTest.OrderFrom.Items[1]).Name = TItem(XTest.OrderTo.Items[1]).Name),
      'TItem(XTest.OrderFrom.Items[1]).Name <> TItem(XTest.OrderTo.Items[1]).Name');
    Assert((TItem(XTest.OrderFrom.Items[1]).Quantity = TItem(XTest.OrderTo.Items[1]).Quantity),
      'TItem(XTest.OrderFrom.Items[1]).Quantity <> TItem(XTest.OrderTo.Items[1]).Quantity');
    Assert((TItem(XTest.OrderFrom.Items[1]).Price = TItem(XTest.OrderTo.Items[1]).Price),
      'TItem(XTest.OrderFrom.Items[1]).Price <> TItem(XTest.OrderTo.Items[1]).Price');
  finally
    XTest.Free;
  end;
end.

