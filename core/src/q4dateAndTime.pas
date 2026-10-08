unit q4dateAndTime;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

{
q4dateAndTime
version du 2026/04/18-17:58

Mapping 4D → q4dateAndTime -> statut
Command Number 4D,   4D Command,                       q4 API,                           Statut
------------------------------------------------------------------------------------------------
393,                 Add to date,                      addToDate,                        OK,
33,                  Current date,                     currentDate,                      OK,
178,                 Current time,                     currentTime,                      OK,
102,                 Date,                             date,                             OK,
114,                 Day number,                       dayNumber,                        OK,
23,                  Day of,                           dayOf,                            OK,
459,                 Milliseconds,                     milliseconds,                     OK,
24,                  Month of,                         monthOf,                          OK,
392,                 SET DEFAULT CENTURY,              setDefaultCentury,                OK,
458,                 Tickcount,                        tickcount,                        OK,
179,                 Time,                             time,                             OK,
180,                 Time string,                      timeString,                       OK,
1445,                Timestamp,                        timestamp,                        OK,
25,                  Year of,                          yearOf,                           OK,

Doc: https://developer.4d.com/docs/21/commands/theme/Date-and-Time
}


function addToDate(_1_d_date: string; _2_e_years: Int64; _3_e_months: Int64; _4_e_days: Int64): string;

function currentDate(_1_t_star: string = ''): string;
function currentTime(_1_t_star: string = ''): string;

function date(_1_t_expression: string): string;

function dayNumber(_1_d_date: string): Int64;
function dayOf(_1_d_date: string): Int64;
function monthOf(_1_d_date: string): Int64;
function yearOf(_1_d_date: string): Int64;

function milliseconds: Int64;
function ticksToMilliseconds(_1_r_ticks: Double): Cardinal;

procedure setDefaultCentury(_1_e_century: Int64; _2_e_pivotYear: Int64 = 0);

function tickcount: Int64;

function time(_1_t_value: string): string;
function timeString(_1_e_seconds: Int64): string;

function timestamp: string;

function normalizeDate(const _1_t_s: string): string; overload;
function normalizeDate(const _1_t_s: string; out _2_t_error: string): string; overload;

function normalizeTime(const _1_t_s: string): string; overload;
function normalizeTime(const _1_t_s: string; out _2_t_error: string): string; overload;

implementation

uses
  q4interruptions;

var
  g_century: Int64 = 2000;
  g_pivot: Int64 = 30;

{----------------------------------}
{ INTERNAL DATE ENGINE }
{----------------------------------}

function InternalIsLeapYear(_1_e_year: Int64): Boolean;
begin
  Result :=
    ((_1_e_year mod 4 = 0) and (_1_e_year mod 100 <> 0))
    or (_1_e_year mod 400 = 0);
end;

function InternalDaysInMonth(_1_e_year: Int64; _2_e_month: Int64): Int64;
begin
  case _2_e_month of
    1,3,5,7,8,10,12 : Result := 31;
    4,6,9,11        : Result := 30;
    2 :
      if (InternalIsLeapYear(_1_e_year)) then
        Result := 29
      else
        Result := 28;
  else
    Result := 30;
  end;
end;

function InternalDateToDays(_1_d_date: string): Int64;
var
  _e_year: Int64;
  _e_month: Int64;
  _e_day: Int64;
  _e_i: Int64;
begin

  if (_1_d_date = '0000-00-00') then
  begin
    Result := 0;
    Exit;
  end;

  _e_year  := SysUtils.StrToInt(System.Copy(_1_d_date,1,4));
  _e_month := SysUtils.StrToInt(System.Copy(_1_d_date,6,2));
  _e_day   := SysUtils.StrToInt(System.Copy(_1_d_date,9,2));

  Result := 0;

  for _e_i := 0 to _e_year-1 do
  begin
    if (InternalIsLeapYear(_e_i)) then
      Result := Result + 366
    else
      Result := Result + 365;
  end;

  for _e_i := 1 to _e_month-1 do
    Result := Result + InternalDaysInMonth(_e_year,_e_i);

  Result := Result + (_e_day-1);

end;

function InternalDaysToDate(_1_e_days: Int64): string;
var
  _e_year: Int64;
  _e_month: Int64;
  _e_day: Int64;
  _e_daysYear: Int64;
begin

  if (_1_e_days = 0) then
  begin
    Result := '0000-01-01';
    Exit;
  end;

  _e_year := 0;

  while (True) do
  begin
    if (InternalIsLeapYear(_e_year)) then
      _e_daysYear := 366
    else
      _e_daysYear := 365;

    if (_1_e_days >= _e_daysYear) then
    begin
      _1_e_days := _1_e_days - _e_daysYear;
      Inc(_e_year);
    end
    else
      Break;
  end;

  _e_month := 1;

  while (_1_e_days >= InternalDaysInMonth(_e_year,_e_month)) do
  begin
    _1_e_days := _1_e_days - InternalDaysInMonth(_e_year,_e_month);
    Inc(_e_month);
  end;

  _e_day := _1_e_days + 1;

  Result := SysUtils.Format('%.4d-%.2d-%.2d',[_e_year,_e_month,_e_day]);

end;


  {----------------------------------}
  { INTERNAL TIME ENGINE }
  {----------------------------------}

function InternalTimeToSeconds(_1_h_time: string): Int64;
var
  _e_p1,_e_p2:Integer;
  _e_h,_e_m,_e_s:Int64;
  _t_tmp:string;

begin

  _e_p1 := System.Pos(':',_1_h_time);
  _t_tmp := System.Copy(_1_h_time,_e_p1+1,Length(_1_h_time));
  _e_p2 := System.Pos(':',_t_tmp);
  _e_p2 := _e_p2 + _e_p1;

  _e_h := SysUtils.StrToInt(System.Copy(_1_h_time,1,_e_p1-1));
  _e_m := SysUtils.StrToInt(System.Copy(_1_h_time,_e_p1+1,_e_p2-_e_p1-1));
  _e_s := SysUtils.StrToInt(System.Copy(_1_h_time,_e_p2+1,Length(_1_h_time)));

  Result := _e_h*3600 + _e_m*60 + _e_s;

end;


function InternalSecondsToTime(_1_e_sec:Int64):string;
var
  _e_h,_e_m,_e_s:Int64;
begin

  _e_h := _1_e_sec div 3600;
  _1_e_sec := _1_e_sec mod 3600;

  _e_m := _1_e_sec div 60;
  _e_s := _1_e_sec mod 60;

  Result := SysUtils.Format('%d:%.2d:%.2d',[_e_h,_e_m,_e_s]);

end;

function InternalTimeToNumber(_1_h_time:string):Int64;
var
  sign:Int64;
  p1,p2:integer;
  h,m,s:Int64;
begin

  sign := 1;

  if (_1_h_time[1] = '-') then
  begin
    sign := -1;
    Delete(_1_h_time,1,1);
  end;

  p1 := Pos(':',_1_h_time);
  p2 := Pos(':',Copy(_1_h_time,p1+1,Length(_1_h_time))) + p1;

  h := StrToInt(Copy(_1_h_time,1,p1-1));
  m := StrToInt(Copy(_1_h_time,p1+1,p2-p1-1));
  s := StrToInt(Copy(_1_h_time,p2+1,Length(_1_h_time)));

  Result := sign*(h*10000 + m*100 + s);

end;

function InternalNumberToTime(_1_e_v:Int64):string;
var
  sign:string;
  h,m,s:Int64;
begin

  if (_1_e_v < 0) then
  begin
    sign := '-';
    _1_e_v := -_1_e_v;
  end
  else
    sign := '';

  h := _1_e_v div 10000;
  m := (_1_e_v div 100) mod 100;
  s := _1_e_v mod 100;

  Result := sign + Format('%d:%.2d:%.2d',[h,m,s]);

end;

{----------------------------------}
{ API PUBLIQUE }
{----------------------------------}

function addToDate(_1_d_date: string; _2_e_years: Int64; _3_e_months: Int64; _4_e_days: Int64): string;
var
  _e_year: Int64;
  _e_month: Int64;
  _e_day: Int64;
  _e_daysInMonth: Int64;
begin

  _e_year  := SysUtils.StrToInt(System.Copy(_1_d_date,1,4));
  _e_month := SysUtils.StrToInt(System.Copy(_1_d_date,6,2));
  _e_day   := SysUtils.StrToInt(System.Copy(_1_d_date,9,2));

  { ajout années }
  _e_year := _e_year + _2_e_years;

  { ajout mois }
  _e_month := _e_month + _3_e_months;

  while (_e_month > 12) do
  begin
    _e_month := _e_month - 12;
    Inc(_e_year);
  end;

  while (_e_month < 1) do
  begin
    _e_month := _e_month + 12;
    Dec(_e_year);
  end;

  { ajustement jour }
  _e_daysInMonth := InternalDaysInMonth(_e_year,_e_month);

  if (_e_day > _e_daysInMonth) then
    _e_day := _e_daysInMonth;

  { conversion vers jours }
  Result := InternalDaysToDate(
    InternalDateToDays(
      SysUtils.Format('%.4d-%.2d-%.2d',[_e_year,_e_month,_e_day])
    ) + _4_e_days
  );

end;

function currentDate(_1_t_star: string = ''): string;
begin
  //https://developer.4d.com/docs/21/commands/current-date

  Result := SysUtils.FormatDateTime('yyyy-mm-dd',SysUtils.Now);
end;

function currentTime(_1_t_star: string = ''): string;
begin
  //https://developer.4d.com/docs/21/commands/current-time

  Result := SysUtils.FormatDateTime('hh:nn:ss',SysUtils.Now);
end;

function date(_1_t_expression: string): string;
begin
  //https://developer.4d.com/docs/21/commands/date

  Result := _1_t_expression;
end;

function dayNumber(_1_d_date: string): Int64;
begin
  //https://developer.4d.com/docs/21/commands/day-number

  Result := InternalDateToDays(_1_d_date);
end;

function dayOf(_1_d_date: string): Int64;
var
  _e_days: Int64;
begin
  //https://developer.4d.com/docs/21/commands/day-of

  _e_days := InternalDateToDays(_1_d_date);

  Result := (_e_days mod 7) + 1;
end;

function monthOf(_1_d_date: string): Int64;
begin
  //https://developer.4d.com/docs/21/commands/month-of

  Result := SysUtils.StrToInt(System.Copy(_1_d_date,6,2));
end;

function yearOf(_1_d_date: string): Int64;
begin
  //https://developer.4d.com/docs/21/commands/year-of

  Result := SysUtils.StrToInt(System.Copy(_1_d_date,1,4));
end;

function milliseconds: Int64;
begin
  Result := Integer(DWord(SysUtils.GetTickCount64 and $FFFFFFFF));
end;

function ticksToMilliseconds(_1_r_ticks: Double): Cardinal;
var
  LMs: Double;
begin
  if (_1_r_ticks <= 0) then
    Exit(0);

  LMs := _1_r_ticks * (1000.0 / 60.0);
  Result := Cardinal(Round(LMs));

  if (Result = 0) then
    Result := 1;
end;

procedure setDefaultCentury(_1_e_century: Int64; _2_e_pivotYear: Int64 = 0);
begin
  //https://developer.4d.com/docs/21/commands/set-default-century

  g_century := _1_e_century;

  if (_2_e_pivotYear <> 0) then
    g_pivot := _2_e_pivotYear;
end;

function tickcount: Int64;
begin
  //https://developer.4d.com/docs/21/commands/tickcount

  Result := SysUtils.GetTickCount64;
end;

function time(_1_t_value: string): string;
var
  _e_value:Int64;
begin
  //https://developer.4d.com/docs/21/commands/time

  _e_value := InternalTimeToNumber(_1_t_value);

  Result := InternalNumberToTime(_e_value);
end;

function timeString(_1_e_seconds: Int64): string;
var
  _e_value:Int64;
begin
  //https://developer.4d.com/docs/21/commands/time-string

  _e_value := (_1_e_seconds div 3600) * 10000 +
             ((_1_e_seconds mod 3600) div 60) * 100 +
             (_1_e_seconds mod 60);

  Result := InternalNumberToTime(_e_value);
end;

function timestamp: string;
begin
  //https://developer.4d.com/docs/21/commands/timestamp

  Result := SysUtils.FormatDateTime('yyyy-mm-dd"T"hh:nn:ss',SysUtils.Now);
end;

function normalizeDate(const _1_t_s: string; out _2_t_error: string): string;
var
  t: string;
  y, m, d: Int64;
begin
  Result := '';
  _2_t_error := '';
  t := Trim(_1_t_s);

  if (t = '') then
    Exit('');

  if (Length(t) <> 10) then
  begin
    _2_t_error := 'Date invalide, longueur attendue yyyy-mm-dd : [' + t + ']';
    Exit;
  end;

  if ((t[5] <> '-') or (t[8] <> '-')) then
  begin
    _2_t_error := 'Date invalide, format attendu yyyy-mm-dd : [' + t + ']';
    Exit;
  end;

  if (not TryStrToInt64(Copy(t, 1, 4), y)) then
  begin
    _2_t_error := 'Date invalide, année incorrecte : [' + t + ']';
    Exit;
  end;

  if (not TryStrToInt64(Copy(t, 6, 2), m)) then
  begin
    _2_t_error := 'Date invalide, mois incorrect : [' + t + ']';
    Exit;
  end;

  if (not TryStrToInt64(Copy(t, 9, 2), d)) then
  begin
    _2_t_error := 'Date invalide, jour incorrect : [' + t + ']';
    Exit;
  end;

  if ((m < 1) or (m > 12)) then
  begin
    _2_t_error := 'Date invalide, mois hors borne : [' + t + ']';
    Exit;
  end;

  if ((d < 1) or (d > InternalDaysInMonth(y, m))) then
  begin
    _2_t_error := 'Date invalide, jour hors borne : [' + t + ']';
    Exit;
  end;

  Result := Format('%.4d-%.2d-%.2d', [y, m, d]);
end;

function normalizeDate(const _1_t_s: string): string;
var
  err: string;
begin
  Result := normalizeDate(_1_t_s, err);
  q4interruptions.assertRaise(err = '', err);
end;

function normalizeTime(const _1_t_s: string): string;
var
  err: string;
begin
  Result := normalizeTime(_1_t_s, err);
  q4interruptions.assertRaise(err = '', err);
end;

function normalizeTime(const _1_t_s: string; out _2_t_error: string): string;
var
  t: string;
  h, n, sec: Int64;
begin
  Result := '';
  _2_t_error := '';
  t := Trim(_1_t_s);

  if (t = '') then
    Exit('');

  if (Length(t) = 5) then
    t := t + ':00';

  if (Length(t) <> 8) then
  begin
    _2_t_error := 'Heure invalide, format attendu hh:nn ou hh:nn:ss : [' + t + ']';
    Exit;
  end;

  if ((t[3] <> ':') or (t[6] <> ':')) then
  begin
    _2_t_error := 'Heure invalide, format attendu hh:nn:ss : [' + t + ']';
    Exit;
  end;

  if (not TryStrToInt64(Copy(t, 1, 2), h)) then
  begin
    _2_t_error := 'Heure invalide, heure incorrecte : [' + t + ']';
    Exit;
  end;

  if (not TryStrToInt64(Copy(t, 4, 2), n)) then
  begin
    _2_t_error := 'Heure invalide, minute incorrecte : [' + t + ']';
    Exit;
  end;

  if (not TryStrToInt64(Copy(t, 7, 2), sec)) then
  begin
    _2_t_error := 'Heure invalide, seconde incorrecte : [' + t + ']';
    Exit;
  end;

  if ((h < 0) or (h > 23)) then
  begin
    _2_t_error := 'Heure invalide, heure hors borne : [' + t + ']';
    Exit;
  end;

  if ((n < 0) or (n > 59)) then
  begin
    _2_t_error := 'Heure invalide, minute hors borne : [' + t + ']';
    Exit;
  end;

  if ((sec < 0) or (sec > 59)) then
  begin
    _2_t_error := 'Heure invalide, seconde hors borne : [' + t + ']';
    Exit;
  end;

  Result := Format('%.2d:%.2d:%.2d', [h, n, sec]);
end;



end.
