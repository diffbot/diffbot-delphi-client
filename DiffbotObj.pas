unit DiffbotObj;

interface
uses DiffbotIntf;

type
  { TDiffbotBase }
  TDiffbotBase = class(TInterfacedObject, IDiffbotBase)
  private
    FTimeout: Integer;
    FCallback: string;
    FToken: string;
    FVersion: Integer;
    FFields: TDiffbotFields;
    function FieldsToQueryString(): string;
  protected
    // IDiffbotBase
    function AcceptedFields: TDiffbotFields; virtual; abstract;
    function DefaultFields: TDiffbotFields; virtual; abstract;

    // Request params

    function GetFields: TDiffbotFields;
    procedure SetFields(value: TDiffbotFields);

    function GetTimeout: Integer;
    procedure SetTimeout(value: Integer);

    function GetCallback: string;
    procedure SetCallback(const value: string);

    /// <summary>
    /// Used to control which fields are returned by the API. See the Response section below.
    /// </summary>
    property Fields: TDiffbotFields read GetFields write SetFields;

    /// <summary>
    /// Gets or sets a value in milliseconds to terminate the response. By default the Product API has no timeout.
    /// </summary>
    property Timeout: Integer read GetTimeout write SetTimeout;
    /// <summary>
    /// Use for jsonp requests. Needed for cross-domain ajax.
    /// </summary>
    property Callback: string read GetCallback write SetCallback;

    /// <summary>
    /// Performs loading from the defined url according preset request params
    /// </summary>
    function Load(const url: string): IDiffbotResponse;
  protected
    function APIName: string; virtual; abstract;
    function GetRequestUrl(const url: string): string; virtual;
    function CreateResponse(const jsonResult: string): IDiffbotResponse; virtual; abstract;
  public
    constructor Create(const token: string; version: Integer);
    property Token: string read FToken;
    property Version: Integer read FVersion;
  end;

  { TDiffbotArticle }
  TDiffbotArticle = class(TDiffbotBase, IDiffbotArticle)
  protected
    // IDiffbotArticle
    function AcceptedFields: TDiffbotFields; override;
    function DefaultFields: TDiffbotFields; override;
    /// <summary>
    /// Performs loading from the defined url according preset request params
    /// </summary>
    function LoadArticle(const url: string): IDiffbotArticleResponse;
    function IDiffbotArticle.Load = LoadArticle;
  protected
    function APIName: string; override;
    function CreateResponse(const jsonResult: string): IDiffbotResponse; override;
  end;

  { TDiffbotAnalize }
  TDiffbotAnalyze = class(TDiffbotBase, IDiffbotAnalyze)
  private
    FMode: TDiffbotAPI;
    FGetStats: Boolean;
  protected
    // IDiffbotArticle
    function AcceptedFields: TDiffbotFields; override;
    function DefaultFields: TDiffbotFields; override;
    /// <summary>
    /// Performs loading from the defined url according preset request params
    /// </summary>
    function LoadArticle(const url: string; getStats: Boolean; mode: TDiffbotAPI): IDiffbotAnalyzeResponse;
    function IDiffbotAnalyze.Load = LoadArticle;
  protected
    function APIName: string; override;
    function CreateResponse(const jsonResult: string): IDiffbotResponse; override;
    function GetRequestUrl(const url: string): string; override;
  end;

implementation
uses Classes, SysUtils, DiffbotNetUtils, DiffbotResponse;

{ TDiffbotBase }

constructor TDiffbotBase.Create(const token: string; version: Integer);
begin
  FToken:= token;
  FVersion:= version;
end;

function TDiffbotBase.GetCallback: string;
begin
  Result:= FCallback;
end;

function TDiffbotBase.GetTimeout: Integer;
begin
  Result:= FTimeout;
end;

procedure TDiffbotBase.SetCallback(const value: string);
begin
  FCallback:= value;
end;

procedure TDiffbotBase.SetTimeout(value: Integer);
begin
  FTimeout:= value;
end;

function TDiffbotBase.GetFields: TDiffbotFields;
begin
  Result:= FFields * AcceptedFields;
end;

procedure TDiffbotBase.SetFields(value: TDiffbotFields);
begin
  FFields:= value;
end;

function TDiffbotBase.Load(const url: string): IDiffbotResponse;
var
  DiffbotRequest, jsonResult: string;
begin
  DiffbotRequest:= GetRequestUrl(url);
  jsonResult:= GetUrlContent(DiffbotRequest);
//  with TFileStream.Create('C:\temp\jsonRes.json', fmCreate) do
//  begin
//    Write(jsonResult[1], Length(jsonResult));
//    Free;
//  end;
  Result:= CreateResponse(jsonResult);
end;

function TDiffbotBase.FieldsToQueryString(): string;
begin
  if (Fields = DefaultFields) then
  begin
    Result:= '';
    Exit;
  end;
  Result:= 'type';
  if dfAll in Fields then
    Result:= '*'
  else
  begin
    if dfUrl in Fields  then Result:= Result + ',url';
    if dfResolvedUrl in Fields then Result:= Result + ',resolved_url';
    if dfIcon in Fields then Result:= Result + ',icon';
    if dfMeta in Fields then Result:= Result + ',meta';
    if dfQueryString in Fields then Result:= Result + ',querystring';
    if dfLinks in Fields then Result:= Result + ',links';
    if dfTitle in Fields then Result:= Result + ',title';
    if dfText in Fields then Result:= Result + ',text';
    if dfHtml in Fields then Result:= Result + ',html';
    if dfNumPages in Fields then Result:= Result + ',numPages';
    if dfDate in Fields then Result:= Result + ',date';
    if dfAuthor in Fields then Result:= Result + ',author';
    if dfTags in Fields then Result:= Result + ',tags';
    if dfLanguage in Fields then Result:= Result + ',humanLanguage';

    if Fields*([dfImages] + dfImagesAll) <> [] then
    begin
      Result:= Result + ',images';
      if Fields*dfImagesAll <> [] then
      begin
        if Fields*dfImagesAll = dfImagesAll then
          Result:= Result + '(*)'
        else
        begin
          Result:= Result + '(';
          if dfImagesUrl in Fields then Result:= Result + ',url';
          if dfImagesWidth in Fields then Result:= Result + ',pixelWidth';
          if dfImagesHeight in Fields then Result:= Result + ',pixelHeight';
          if dfImagesCaption in Fields then Result:= Result + ',caption';
          if dfImagesPrimary in Fields then Result:= Result + ',primary';
          Result:= Result + ')';
        end;
      end;
    end;

    if Fields*([dfVideos] + dfVideosAll) <> [] then
    begin
      Result:= Result + ',videos';
      if Fields*dfVideosAll <> [] then
      begin
        if Fields*dfVideosAll = dfVideosAll then
          Result:= Result + '(*)'
        else
        begin
          Result:= Result + '(';
          if dfVideosUrl in Fields then Result:= Result + ',url';
          if dfVideosWidth in Fields then Result:= Result + ',pixelWidth';
          if dfVideosHeight in Fields then Result:= Result + ',pixelHeight';
          if dfVideosCaption in Fields then Result:= Result + ',caption';
          if dfVideosPrimary in Fields then Result:= Result + ',primary';
          Result:= Result + ')';
        end;
      end;
    end;
  end;
end;

function EncodeUrl(const source: string): string;
var
  i: integer;
begin
  result:= '';
  for i:= 1 to length(source) do
    if not (source[i] in ['A'..'Z','a'..'z','0','1'..'9','-','_','~','.']) then
      result:= result + '%' + IntToHex(ord(source[i]), 2) else result:= result + source[i];
end;

function TDiffbotBase.GetRequestUrl(const url: string): string;
var
  fields: string;
begin
  Result:= Format('http://api.diffbot.com/v%d/%s?token=%s&url=%s',
    [Version, APIName, Token, EncodeUrl(url)]);
  fields:= FieldsToQueryString();
  if (fields <> '') then Result:= Result + '&fields=' + fields;
  if (Timeout <> 0) then Result:= Result + '&timeout=' + IntToStr(Timeout);
  if (Callback <> '') then Result:= Result + '&callback=' + Callback;
end;




{ TDiffbotArticle }

function TDiffbotArticle.APIName: string;
begin
  Result:= 'article';
end;

function TDiffbotArticle.AcceptedFields: TDiffbotFields;
begin
  Result:= dfDefaultArticle + dfImagesAll + dfVideosAll +
    [dfMeta, dfQueryString, dfLinks, dfNumPages, dfTags, dfLanguage];
end;

function TDiffbotArticle.DefaultFields: TDiffbotFields;
begin
  Result:= dfDefaultArticle;
end;

function TDiffbotArticle.LoadArticle(const url: string): IDiffbotArticleResponse;
begin
  Result:= inherited Load(url) as IDiffbotArticleResponse;
end;

function TDiffbotArticle.CreateResponse(const jsonResult: string): IDiffbotResponse;
begin
  Result:= TDiffbotArticleResponse.Create(jsonResult);
end;



{ TDiffbotAnalyze }

function TDiffbotAnalyze.APIName: string;
begin
  Result:= 'analyze';
end;

function TDiffbotAnalyze.AcceptedFields: TDiffbotFields;
begin
  Result:= dfDefaultAnalyze;
end;

function TDiffbotAnalyze.DefaultFields: TDiffbotFields;
begin
  Result:= dfDefaultAnalyze;
end;

function TDiffbotAnalyze.LoadArticle(const url: string; getStats: Boolean; mode: TDiffbotAPI): IDiffbotAnalyzeResponse;
begin
  FMode:= mode;
  FGetStats:= getStats;
  Result:= inherited Load(url) as IDiffbotAnalyzeResponse;
end;

function TDiffbotAnalyze.CreateResponse(const jsonResult: string): IDiffbotResponse;
begin
  Result:= TDiffbotAnalyzeResponse.Create(jsonResult);
end;


function TDiffbotAnalyze.GetRequestUrl(const url: string): string;
begin
  Result:= inherited GetRequestUrl(url);
  if (FGetStats) then
    Result:= Result + '&stats';
  if (FMode <> daUndefined) then
    Result:= Result + '&mode=' + DiffbotApiToString(FMode);
end;

end.
