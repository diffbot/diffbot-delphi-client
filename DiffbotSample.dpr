program TestDiffbot;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,
  WinInet,
  DiffbotIntf,
  TypInfo;

function iif(cond: bool; const s1, s2: string): string;
begin
  if (cond) then Result:= s1 else Result:= s2;
end;

procedure Test();
var
  i: Integer;
  typ: TDiffbotAPI;
  analyzeBot: IDiffbotAnalyze;
  analyzeResponse: IDiffbotAnalyzeResponse;
  articleBot: IDiffbotArticle;
  response: IDiffbotArticleResponse;
begin
  // ---------------------------  Test Article API  --------------------------------------

  articleBot:= GetDiffbotArticle('653b629953577c7e4832fbc06bfe0e6e');
  articleBot.Timeout:= 10000; // Set a timeout in 10 seconds

//  articleBot.Fields:= [dbaAll];
  articleBot.Fields:= dfDefaultArticle + [dfTags, dfLinks, dfLanguage] + dfImagesAll;

  response:= articleBot.Load('http://www.diffbot.com/our-apis/article');
//  response:= articleBot.Load('http://bash.org');
//  response:= articleBot.Load('http://microsoft.com');
//  response:= articleBot.Load('http://www.xconomy.com/san-francisco/2012/07/25/diffbot-is-using-computer-vision-to-reinvent-the-semantic-web/');

  Writeln('Url:           ', response.Url);
  Writeln('ResolvedUrl:   ', response.ResolvedUrl);
  Writeln('IconUrl:       ', response.IconUrl);
  Writeln('Title:         ', response.Title);
  Writeln('Author:        ', response.Author);
  Writeln('Creation Date: ', DateTimeToStr(response.DateCreated));
  Writeln('Date:          ', DateTimeToStr(response.Date));
  Writeln('Language:      ', response.Language);

  Write('Tags: ');
  for i:= Low(response.Tags) to High(response.Tags) do
    Write(response.Tags[i], ', ');
  Writeln;
  Writeln('Links: ');
  for i:= Low(response.Links) to High(response.Links) do
  begin
    WriteLn('    ' + response.Links[i]);
  end;
  Writeln;
  Writeln('Media: ');
  for i:= Low(response.Media) to High(response.Media) do
  begin
    WriteLn('    Type:      ' + iif(response.Media[i].MediaType = dbmtImage, 'Image', 'Video'));
    WriteLn('    IsPrimary: ' + iif(response.Media[i].IsPrimary, 'true', 'false'));
    WriteLn('    Url:       ' + response.Media[i].UrlLink);
    WriteLn('    Width:     ', response.Media[i].Size.cx);
    WriteLn('    Height:    ', response.Media[i].Size.cy);
    WriteLn('    Caption:   ' + response.Media[i].Caption);
    WriteLn('    ------------------------------------------');
  end;
  Writeln;
//  Writeln(response.Text);
  ReadLn;

  // ---------------------------  Test Analyze API  --------------------------------------

  analyzeBot:= GetDiffbotAnalyze('653b629953577c7e4832fbc06bfe0e6e');
  analyzeResponse:= analyzeBot.Load('http://www.diffbot.com/our-apis/article', True);

  Writeln('Type:          ', DiffbotAPIToString(analyzeResponse.API));
  Writeln('Url:           ', analyzeResponse.Url);
  Writeln('ResolvedUrl:   ', analyzeResponse.ResolvedUrl);
  Writeln('Title:         ', analyzeResponse.Title);
  Writeln('Language:      ', analyzeResponse.Language);

  Writeln('Stats: ');
  Writeln('Parse Time:      ', analyzeResponse.AsObject('stats').AsObject('times').AsInt('docParseTime'));
  for typ:= Low(analyzeResponse.Stats) to High(analyzeResponse.Stats) do
    Writeln(DiffbotAPIToString(typ), ' = ', analyzeResponse.Stats[typ]);
  Writeln;

  ReadLn;

end;

begin
  Test();
end.
