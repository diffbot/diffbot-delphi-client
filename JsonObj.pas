unit JsonObj;

interface
uses uJSON, Classes, DiffbotIntf;

type
  TJsonObject = class(TInterfacedObject, IJsonObject)
  private
    FDontFreeSource: Boolean;
    FJson: uJSON.TJSONObject;
    constructor Create(jsonObject: uJSON.TJSONObject); overload;
  public
    // IJsonObject
    function Has(const name: string): Boolean;
    function AsBool(const name: string; defValue: Boolean = False): Boolean;
    function AsDouble(const name: string; defValue: Double = 0): Double;
    function AsInt(const name: string; defValue: Integer = 0): Integer;
    function AsString(const name: string; const defValue: string = ''): string;
    function AsDateTime(const name: string; defValue: TDateTime = 0): TDateTime;
    function AsObject(const name: string): IJsonObject;
    function AsArray(const name: string): IJsonArray;
    function AsVariant(const name: string): Variant;
  public
    constructor Create(const jsonString: string); overload;
    destructor Destroy; override;
  end;

  TJsonArray = class(TInterfacedObject, IJsonArray)
  private
    FDontFreeSource: Boolean;
    FJson: uJSON.TJSONArray;
    constructor Create(jsonObject: uJSON.TJSONArray); overload;
  public
    // IJsonArray
    function Length: Integer;
    function AsBool(index: Integer): Boolean;
    function AsDouble(index: Integer): Double;
    function AsInt(index: Integer): Integer;
    function AsString(index: Integer): string;
    function AsDateTime(index: Integer): TDateTime;
    function AsVariant(index: Integer): Variant;
    function AsObject(index: Integer): IJsonObject;
    function AsArray(index: Integer): IJsonArray;
  public
    constructor Create(const jsonString: string); overload;
    destructor Destroy; override;
  end;

implementation
uses SysUtils, Variants, DiffbotNetUtils;

function AbstractObjectToVariant(res: TZAbstractObject): Variant;
begin
  if (res is uJSON.NULL) then
    Result:= Variants.Null
  else if (res.equals(_Boolean._FALSE)) then
    Result:= False
  else if (res.equals(_Boolean._TRUE)) then
    Result:= True
  else if (res is _Integer) then
    Result:= _Integer(res).intValue
  else if (res is _Double) then
    Result:= _Double(res).doubleValue
  else if (res is _String) then
    Result:= _String(res).toString
  else
    Result:= Unassigned;
end;

function VarToDateTime(const res: Variant; defValue: TDateTime): TDateTime;
begin
  if (VarType(res) in [varInteger, varDouble]) then
    Result:= TDateTime(res)
  else if (VarType(res) = varString) then
  begin
    Result:= RFC822DateToDateTime(res);
  end
  else
    Result:= defValue;
end;

{ TJsonObject }

constructor TJsonObject.Create(const jsonString: string);
begin
  FJson:= uJSON.TJSONObject.create(jsonString);
end;

constructor TJsonObject.Create(jsonObject: uJSON.TJSONObject);
begin
  FJson:= jsonObject;
  FDontFreeSource:= True;
end;

destructor TJsonObject.Destroy;
begin
  if not FDontFreeSource then
    FreeAndNil(FJson);
  inherited;
end;

function TJsonObject.Has(const name: string): Boolean;
begin
  Result:= FJson.has(name);
end;

function TJsonObject.AsArray(const name: string): IJsonArray;
begin
  if Has(name) then
    Result:= TJsonArray.Create(FJson.getJSONArray(name))
  else
    Result:= nil;
end;

function TJsonObject.AsBool(const name: string; defValue: Boolean): Boolean;
begin
  if Has(name) then
    Result:= FJson.getBoolean(name)
  else
    Result:= defValue;
end;

function TJsonObject.AsDateTime(const name: string; defValue: TDateTime): TDateTime;
begin
  if Has(name) then
    Result:= VarToDateTime(AsVariant(name), defValue)
  else
    Result:= defValue;
end;

function TJsonObject.AsDouble(const name: string; defValue: Double): Double;
begin
  if Has(name) then
    Result:= FJson.getDouble(name)
  else
    Result:= defValue;
end;

function TJsonObject.AsInt(const name: string; defValue: Integer): Integer;
begin
  if Has(name) then
    Result:= FJson.getInt(name)
  else
    Result:= defValue;
end;

function TJsonObject.AsObject(const name: string): IJsonObject;
begin
  if Has(name) then
    Result:= TJsonObject.Create(FJson.getJSONObject(name))
  else
    Result:= nil;
end;

function TJsonObject.AsString(const name, defValue: string): string;
begin
  if Has(name) then
    Result:= FJson.getString(name)
  else
    Result:= defValue;
end;

function TJsonObject.AsVariant(const name: string): Variant;
begin
  if Has(name) then
    Result:= AbstractObjectToVariant(FJson.get(name))
  else
    Result:= Unassigned;
end;


{ TJsonArray }

constructor TJsonArray.Create(const jsonString: string);
begin
  FJson:= uJSON.TJSONArray.create(jsonString);
end;

constructor TJsonArray.Create(jsonObject: uJSON.TJSONArray);
begin
  FJson:= jsonObject;
  FDontFreeSource:= True;
end;

destructor TJsonArray.Destroy;
begin
  if not FDontFreeSource then
    FreeAndNil(FJson);
  inherited;
end;

function TJsonArray.Length: Integer;
begin
  Result:= FJson.length;
end;

function TJsonArray.AsArray(index: Integer): IJsonArray;
begin
  Result:= TJsonArray.Create(FJson.getJSONArray(index));
end;

function TJsonArray.AsBool(index: Integer): Boolean;
begin
  Result:= FJson.getBoolean(index);
end;

function TJsonArray.AsDateTime(index: Integer): TDateTime;
begin
  Result:= VarToDateTime(AsVariant(index), 0);
end;

function TJsonArray.AsDouble(index: Integer): Double;
begin
  Result:= FJson.getDouble(index);
end;

function TJsonArray.AsInt(index: Integer): Integer;
begin
  Result:= FJson.getInt(index);
end;

function TJsonArray.AsObject(index: Integer): IJsonObject;
begin
  Result:= TJsonObject.Create(FJson.getJSONObject(index));
end;

function TJsonArray.AsString(index: Integer): string;
begin
  Result:= FJson.getString(index);
end;

function TJsonArray.AsVariant(index: Integer): Variant;
begin
  Result:= AbstractObjectToVariant(FJson.get(index));
end;

end.
