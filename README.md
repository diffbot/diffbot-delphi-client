# Diffbot API Delphi Client Library


## Installation

The `Diffbot API Delphi Client Library` can be delivered in several ways:

1. Source files `*.pas`.
2. Precompiled unit files `*.dcu`.
3. Precompiled run-time package files `Diffbot.dcp` and `Diffbot.bpl`.

*If you have source files all you need to put all the source files to one of the project source paths.* 

*If you have precompiled unit files you have to put all the unit files of the matching Delphi version to one of the project library paths.*

*If you have precompiled run-time package files put `Diffbot.dcp` the matching Delphi version to one of the project library paths or project DCP directory. `Diffbot.bpl` must be in the same folder as a executable project file (or in one of the PATH directories).*     


Add the unit `DiffbotIntf` to the **uses section** of the modules where you work with the library.

## Configuration

Obtaining `Delphi Diffbot Client` is simple as that:

```pascal
uses DiffbotIntf;

var
  analyzeBot: IDiffbotAnalyze;
  articleBot: IDiffbotArticle;
begin
  analyzeBot:= GetDiffbotAnalyze('...token...');
  articleBot:= GetDiffbotArticle('...token...');
end;
```

This gives you an interface to one of the `Diffbot` API'es for further working with it. 

Notify that you have to pass your developer [token](http://diffbot.com/pricing/) as a parameter of the factory function.


### Middleware

The present version of the `Diffbot API Delphi Client Library` doesn't use any third-party libraries.


## Usage

### Common API interfaces

All the `Diffbot API` interfaces are inherited from the common base interface [`IDiffbotBase`]() and have the common properties to setup.

You must set this properties *before* processing a page URL.

After processing a page URL you will get an appropriate strong-typed `Response API` interface according to the used API. However, you can get access to the response data directly with common [`IDiffbotResponse`]() interface methods:

See samples below.




----------

### Article API

To process the `Article API` you have to call the factory function `GetDiffbotArticle()`. It returns [`IDiffbotArticle`]() interface and after loading a page you will get [`IDiffbotArticleResponse`](). 

```pascal
uses DiffbotIntf;

var
  article: IDiffbotArticle;
  response: IDiffbotArticleResponse;
begin
  article:= GetDiffbotArticle('...token...');
  
  // Set a timeout in 10 seconds
  article.Timeout:= 10000;
  // Add Tags and Links to the response fields.   
  article.Fields:= dfDefaultArticle + [dfTags, dfLinks, dfMedia] + dfImagesAll;
  
  // Loading a page
  response:= article.Load('http://www.diffbot.com/our-apis/article');

  // Processing result

  // Sample to access with common IDiffbotResponse interface methods
  Writeln('Url:           ', response.AsString('url'));
  Writeln('Date:          ', DateTimeToStr(response.AsDateTime('date')));

  // Sample to access with strong-typed IDiffbotArticleResponse interface methods
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
```

----------

### Analyze API

To process the `Analyze API` you have to call the factory function `GetDiffbotAnalyze()`. It returns [`IDiffbotAnalyze`]() interface and after loading a page you will get [`IDiffbotAnalyzeResponse`](). 

```pascal
uses DiffbotIntf;

var
  analyze: IDiffbotAnalyze;
  response: IDiffbotAnalyzeResponse;
  typ: TDiffbotAPI; 
begin
  analyze:= GetDiffbotAnalyze('...token...');
  
  // Set a timeout in 10 seconds
  analyze.Timeout:= 10000;
  // Add Tags and Links to the response fields.   
  analyze.Fields:= [dfTitle, dfLanguage];
  
  // Loading a page
  response:= analyze.Load('http://www.diffbot.com/our-apis/article', True);

  // Processing result

  Writeln('Type:          ', DiffbotAPIToString(response.API));
  Writeln('Title:         ', response.Title);
  Writeln('Language:      ', response.Language);

  Writeln('Stats: ');
  Writeln('Parse Time:      ', response.AsObject('stats').AsObject('times').AsString('docParseTime'));
  for typ:= Low(response.Stats) to High(response.Stats) do
    Writeln(DiffbotAPIToString(typ), ' = ', response.Stats[typ]);
  Writeln;
```

-Initial commit by Yevgen Leybov-
