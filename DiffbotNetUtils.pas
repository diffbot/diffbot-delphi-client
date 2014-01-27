unit DiffbotNetUtils;

interface

function GetUrlContent(const Url: string): string;

function RFC822DateToDateTime(RFC822DateTime: string): TDateTime;

implementation
uses Windows, WinInet, SysUtils, Classes, DateUtils;

function GetUrlContent(const Url: string): string;
var
  NetHandle: HINTERNET;
  UrlHandle: HINTERNET;
  Buffer: array[0..1024] of Char;
  BytesRead: DWORD;
begin
  Result := '';
  NetHandle := InternetOpen('Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);

  if Assigned(NetHandle) then
  begin
    UrlHandle := InternetOpenUrl(NetHandle, PChar(Url), nil, 0, INTERNET_FLAG_RELOAD, 0);

    if Assigned(UrlHandle) then
      { UrlHandle valid? Proceed with download }
    begin
      FillChar(Buffer, SizeOf(Buffer), 0);
      repeat
        Result := Result + Buffer;
        FillChar(Buffer, SizeOf(Buffer), 0);
        InternetReadFile(UrlHandle, @Buffer, SizeOf(Buffer), BytesRead);
      until BytesRead = 0;
      InternetCloseHandle(UrlHandle);
    end
    else
      { UrlHandle is not valid. Raise an exception. }
      raise Exception.CreateFmt('Cannot open URL %s', [Url]);

    InternetCloseHandle(NetHandle);
  end
  else
    { NetHandle is not valid. Raise an exception }
    raise Exception.Create('Unable to initialize Wininet');
end;



function RFC822DateToDateTime(RFC822DateTime: string): TDateTime;
resourcestring
  RFC822ConvertDateTimeConvertError = '"%s" ist keine gu"ltige RFC822-Datums-/' + 'Zeitangabe';
const
  DayArray: array[0..6] of string = ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun');
  MonthArray: array[0..11] of string = ('Jan', 'Feb', 'Mar', 'Apr', 'May',
    'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
  ZoneArray: array[0..14] of string = ('UT', 'GMT', 'EST', 'EDT', 'CST', 'CDT',
    'MST', 'MDT', 'PST', 'PDT', 'Z', 'A', 'M', 'N', 'Y');
var
  lString: string;
  lDayName: string;
  lMonthName: string;
  I: Integer;
  lProceed: Boolean;
  lDay: Integer;
  lMonth: Integer;
  lYear: Integer;
  lTmp: Integer;
  lHours: Integer;
  lMinutes: Integer;
  lSeconds: Integer;
  lTimeZone: TTimeZoneInformation;
  lLocalStringTime: TDateTime;
  lTimeZoneName: string;
  lTimeZoneIndex: Integer;
  lLocalDiffHours: Integer;
  lLocalDiffMinutes: Integer;
  lAddLocalDiff: Boolean;
begin
  lTimeZoneIndex := -1;
  lAddLocalDiff := False;
  lMonth := -1;
  lTmp := 0;
  lString := RFC822DateTime;
  lProceed := False;
  if Pos(',', lString) > 0 then
  begin
    // Includes DayName
    lDayName := Copy(lString, 1, 3);
    for I := 0 to Length(DayArray) - 1 do
    begin
      if lDayName = DayArray[I] then
      begin
        // Found
        lProceed := True;
        Break;
      end;
    end;
    Delete(lString, 1, 5);
  end;

  if lProceed then
  begin
    // Day
    if not TryStrToInt(Copy(lString, 1, 2), lDay) then
    begin
      // might be only 1 characters long
      if not TryStrToInt(Copy(lString, 1, 1), lDay) then
      begin
        lProceed := False;
      end
      else
        Delete(lString, 1, 2);
    end
    else
      Delete(lString, 1, 3);
  end;
  // MonthName
  if lProceed then
  begin
    lMonthName := Copy(lString, 1, 3);
    lProceed := False;
    for I := 0 to Length(MonthArray) - 1 do
    begin
      if lMonthName = MonthArray[I] then
      begin
        // Found
        lProceed := True;
        // Month
        lMonth := Succ(I);
        Break;
      end;
    end;
  end;
  // Year
  if lProceed then
  begin
    if not TryStrToInt(Copy(lString, 5, 4), lYear) then
    begin
      // might be only 2 characters long
      if not TryStrToInt(Copy(lString, 5, 2), lYear) then
      begin
        lProceed := False;
      end
      else
      begin
        lTmp := 2;
      end;
    end
    else
    begin
      lTmp := 4;
    end;
  end;
  // Hours
  if lProceed then
  begin
    lTmp := 5 + Succ(lTmp);
    if not TryStrToInt(Copy(lString, lTmp, 2), lHours) then
    begin
      lProceed := False;
    end;
  end;
  // Minutes
  if lProceed then
  begin
    Inc(lTmp, 3);
    if not TryStrToInt(Copy(lString, lTmp, 2), lMinutes) then
    begin
      lProceed := False;
    end;
  end;
  // Seconds
  if lProceed then
  begin
    Inc(lTmp, 3);
    if not TryStrToInt(Copy(lString, lTmp, 2), lSeconds) then
    begin
      // Just proceed, seconds are optional.
      lSeconds := 0;
    end;
  end;
  if lProceed then
  begin
    // Get TimeZone
    Inc(lTmp, 3); // Start of TimeZone
    lTimeZoneName := Copy(lString, lTmp, 3); // e.g. "GMT"
    if (Copy(lTimeZoneName, 1, 1) = '-') or (Copy(lTimeZoneName, 1, 1) = '+') or
      (Length(lTimeZoneName) = 0) then
    begin
      // Assume UTC
      lTimeZoneIndex := 0;
    end
    else
    begin
      lProceed := False;
      if Length(lTimeZoneName) = 3 then
      begin
        for I := 0 to Length(ZoneArray) - 1 do
        begin
          if ZoneArray[I] = lTimeZoneName then
          begin
            // Found
            lTimeZoneIndex := I;
            lProceed := True;
            Break;
          end;
        end;
      end;
      if not lProceed then
      begin
        // Try the ones with only 2 letters
        for I := 0 to Length(ZoneArray) - 1 do
        begin
          if ZoneArray[I] = Copy(lTimeZoneName, 1, 2) then
          begin
            // Found
            lTimeZoneIndex := I;
            lProceed := True;
            Break;
          end;
        end;
      end;
      if not lProceed then
      begin
        // Try the ones with only 1 letter
        for I := 0 to Length(ZoneArray) - 1 do
        begin
          if ZoneArray[I] = lTimeZoneName[1] then
          begin
            // Found
            lTimeZoneIndex := I;
            lProceed := True;
            Break;
          end;
        end;
      end;
      Inc(lTmp, Length(ZoneArray[lTimeZoneIndex])); // Begin of + / -
    end;
  end;
  if lProceed then
  begin
    // Get local differential hours
    lAddLocalDiff := Copy(lString, lTmp, 1) = '+';
    Inc(lTmp, 1); // Begin of local diff hours
    if lTmp < Length(lString) then
    begin
      // Has local differential hours
      if not TryStrToInt(Copy(lString, lTmp, 2), lLocalDiffHours) then
      begin
        lProceed := False;
      end;
    end
    else
    begin
      // No local diff time
      lLocalDiffHours := -1;
      lLocalDiffMinutes := -1;
    end;
  end;
  if (lProceed) and (lLocalDiffHours <> -1) then
  begin
    // Get local differential minutes
    Inc(lTmp, 2); // Begin of local diff minutes
    if not TryStrToInt(Copy(lString, lTmp, 2), lLocalDiffMinutes) then
    begin
      lProceed := False;
    end;
  end;
  if lProceed then
  begin
    // Create current local time of string as TDateTime
    lLocalStringTime := EncodeDate(lYear, lMonth, lDay) +
      EncodeTime(lHours, lMinutes, lSeconds, 0);
    case lTimeZoneIndex of
      0, 1, 10: lTmp := 0; // UT, GMT, Z
      2: lTmp := 5; // EST, - 5
      3: lTmp := 4; // EDT, - 4
      4: lTmp := 6; // CST, - 6
      5: lTmp := 5; // CDT, - 5
      6: lTmp := 7; // MST, - 7
      7: lTmp := 6; // MDT, - 6
      8: lTmp := 8; // PST, - 8
      9: lTmp := 7; // PDT, - 7
      11: lTmp := 1; // A, - 1
      12: lTmp := 12; // M, - 12
      13: lTmp := -1; // N, + 1
      14: lTmp := -12; // Y, + 12
    end;
    // Calculate the UTC-Time of the given string
    lLocalStringTime := lLocalStringTime + (lTmp * OneHour);
    if lLocalDiffHours <> -1 then
    begin
      if lAddLocalDiff then
      begin
        lLocalStringTime := lLocalStringTime - (lLocalDiffHours * OneHour) -
          (lLocalDiffMinutes * OneMinute);
      end
      else
      begin
        lLocalStringTime := lLocalStringTime + (lLocalDiffHours * OneHour) +
          (lLocalDiffMinutes * OneMinute);
      end;
    end;
    // Now calculate the time in local format
    if GetTimeZoneInformation(lTimeZone) = TIME_ZONE_ID_DAYLIGHT then
    begin
      Result := lLocalStringTime - ((lTimeZone.Bias + lTimeZone.DaylightBias)
        * OneMinute);
    end
    else
    begin
      Result := lLocalStringTime - ((lTimeZone.Bias + lTimeZone.StandardBias)
        * OneMinute);
    end;
  end
  else
  begin
    raise EConvertError.Create(Format(RFC822ConvertDateTimeConvertError,
      [RFC822DateTime]));
  end;
end;

end.

