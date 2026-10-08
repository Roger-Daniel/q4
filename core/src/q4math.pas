Unit q4math;

{$mode objfpc}{$H+}

{
q4math
version du 2026/04/19-18:57

Mapping 4D → q4math -> statut
Command Number 4D,    4D Command,                      q4 API,                           Statut
------------------------------------------------------------------------------------------------
99,                  Abs,                              abs,                              OK,
20,                  Arctan,                           arctan,                           OK,
18,                  Cos,                              cos,                              OK,
9,                   Dec,                              dec,                              OK,
676,                 Euro converter,                   euroConverter,                    OK,
21,                  Exp,                              exp,                              OK,
8,                   Int,                              int,                              OK,
22,                  Log,                              log,                              OK,
98,                  Mod,                              modulo,                           OK,
100,                 Random,                           random,                           OK,
94,                  Round,                            round,                            OK,
623,                 SET REAL COMPARISON LEVEL,        setRealComparisonLevel,           OK,
17,                  Sin,                              sin,                              OK,
539,                 Square root,                      squareRoot,                       OK,
19,                  Tan,                              tan,                              OK,
95,                  Trunc,                            trunc,                            OK,

Doc: https://developer.4d.com/docs/21/commands/theme/Math
}

Interface

Uses
  SysUtils;

Const
  EURO_CURRENCY_ATS = 'ATS';
  EURO_CURRENCY_BEF = 'BEF';
  EURO_CURRENCY_DEM = 'DEM';
  EURO_CURRENCY_EUR = 'EUR';
  EURO_CURRENCY_FIM = 'FIM';
  EURO_CURRENCY_FRF = 'FRF';
  EURO_CURRENCY_GRD = 'GRD';
  EURO_CURRENCY_IEP = 'IEP';
  EURO_CURRENCY_ITL = 'ITL';
  EURO_CURRENCY_LUF = 'LUF';
  EURO_CURRENCY_NLG = 'NLG';
  EURO_CURRENCY_PTE = 'PTE';
  EURO_CURRENCY_ESP = 'ESP';

  DEFAULT_REAL_COMPARISON_EPSILON = 1E-6;

Type
  Tq4EuroRate = Record
    t_code: string;
    r_rateForOneEuro: double;
    e_decimals: int64;
  End;

Function abs( Const _1_r_number: double): double;
Function arctan( Const _1_r_number: double): double;
Function cos( Const _1_r_number: double): double;
Function Dec( Const _1_r_number: double): double;
Function euroConverter( Const _1_r_value: double; Const _2_t_fromCurrency: string; Const _3_t_toCurrency: string): double;
Function exp( Const _1_r_number: double): double;
Function int( Const _1_r_number: double): double;
Function log( Const _1_r_number: double): double;
Function modulo( Const _1_r_number1: double; Const _2_r_number2: double): double;
Function random: int64;
Function round( Const _1_r_round: double; Const _2_e_places: int64): double;
Procedure setRealComparisonLevel( Const _1_r_epsilon: double);
Function sin( Const _1_r_number: double): double;
Function squareRoot( Const _1_r_number: double): double;
Function tan( Const _1_r_number: double): double;
Function trunc( Const _1_r_number: double; Const _2_e_places: int64): double;
Function realEquals( Const _1_r_number1: double; Const _2_r_number2: double): boolean;
Function getRealComparisonLevel: double;

Implementation

Uses
  Math,
  q4interruptions;

Threadvar
  r_realComparisonEpsilon: double;

Const
  C_Q4_EURO_RATES: Array[0..12] Of Tq4EuroRate = (
    ( t_code: EURO_CURRENCY_ATS; r_rateForOneEuro: 13.7603; e_decimals: 2),
    ( t_code: EURO_CURRENCY_BEF; r_rateForOneEuro: 40.3399; e_decimals: 0),
    ( t_code: EURO_CURRENCY_DEM; r_rateForOneEuro: 1.95583; e_decimals: 2),
    ( t_code: EURO_CURRENCY_EUR; r_rateForOneEuro: 1.0; e_decimals: 2),
    ( t_code: EURO_CURRENCY_FIM; r_rateForOneEuro: 5.94573; e_decimals: 2),
    ( t_code: EURO_CURRENCY_FRF; r_rateForOneEuro: 6.55957; e_decimals: 2),
    ( t_code: EURO_CURRENCY_GRD; r_rateForOneEuro: 340.750; e_decimals: 2),
    ( t_code: EURO_CURRENCY_IEP; r_rateForOneEuro: 0.787564; e_decimals: 2),
    ( t_code: EURO_CURRENCY_ITL; r_rateForOneEuro: 1936.27; e_decimals: 0),
    ( t_code: EURO_CURRENCY_LUF; r_rateForOneEuro: 40.3399; e_decimals: 0),
    ( t_code: EURO_CURRENCY_NLG; r_rateForOneEuro: 2.20371; e_decimals: 2),
    ( t_code: EURO_CURRENCY_PTE; r_rateForOneEuro: 200.482; e_decimals: 2),
    ( t_code: EURO_CURRENCY_ESP; r_rateForOneEuro: 166.386; e_decimals: 0)
    );

Function InternalGetRealComparisonLevel: double;
  Begin
    If ( r_realComparisonEpsilon <= 0) Then r_realComparisonEpsilon := DEFAULT_REAL_COMPARISON_EPSILON;

    Result := r_realComparisonEpsilon;
  End;

Function InternalPower10( Const _1_e_places: int64): double;
  Begin
    Result := Math.IntPower( 10.0, _1_e_places);
  End;

Function InternalFindEuroRate( Const _1_t_currencyCode: string; out _2_y_rate: Tq4EuroRate): boolean;
  Var
    _e_index: int64;
    _t_currencyCodeUpper: string;
  Begin
    Result := False;
    _t_currencyCodeUpper := SysUtils.UpperCase( SysUtils.Trim( _1_t_currencyCode));

    For _e_index := Low( C_Q4_EURO_RATES) To High( C_Q4_EURO_RATES) Do If ( C_Q4_EURO_RATES[_e_index].t_code = _t_currencyCodeUpper) Then Begin
        _2_y_rate := C_Q4_EURO_RATES[_e_index];
        Result := True;
        Exit;
      End;
  End;

Function InternalAbs( Const _1_r_number: double): double;
  Begin
    q4interruptions.assertRaise( not Math.IsNan( _1_r_number), 'q4math.InternalAbs: number must not be NaN');
    Result := System.Abs( _1_r_number);
  End;

Function InternalArctan( Const _1_r_number: double): double;
  Begin
    q4interruptions.assertRaise( not Math.IsNan( _1_r_number), 'q4math.InternalArctan: number must not be NaN');
    Result := System.ArcTan( _1_r_number);
  End;

Function InternalCos( Const _1_r_number: double): double;
  Begin
    q4interruptions.assertRaise( not Math.IsNan( _1_r_number), 'q4math.InternalCos: number must not be NaN');
    Result := System.Cos( _1_r_number);
  End;

Function InternalDec( Const _1_r_number: double): double;
  Var
    _r_integerPart: double;
  Begin
    q4interruptions.assertRaise( not Math.IsNan( _1_r_number), 'q4math.InternalDec: number must not be NaN');
    _r_integerPart := q4math.int( _1_r_number);
    Result := System.Abs( _1_r_number - _r_integerPart);
  End;

Function InternalEuroConverter( Const _1_r_value: double; Const _2_t_fromCurrency: string; Const _3_t_toCurrency: string): double;
  Var
    _y_fromRate:    Tq4EuroRate;
    _y_toRate:      Tq4EuroRate;
    _r_valueInEuro: double;
    _r_convertedValue: double;
  Begin
    q4interruptions.assertRaise( InternalFindEuroRate( _2_t_fromCurrency, _y_fromRate), 'q4math.InternalEuroConverter: unsupported source currency');
    q4interruptions.assertRaise( InternalFindEuroRate( _3_t_toCurrency, _y_toRate), 'q4math.InternalEuroConverter: unsupported target currency');

    _r_valueInEuro := _1_r_value / _y_fromRate.r_rateForOneEuro;
    _r_convertedValue := _r_valueInEuro * _y_toRate.r_rateForOneEuro;
    Result := q4math.round( _r_convertedValue, _y_toRate.e_decimals);
  End;

Function InternalExp( Const _1_r_number: double): double;
  Begin
    q4interruptions.assertRaise( not Math.IsNan( _1_r_number), 'q4math.InternalExp: number must not be NaN');
    Result := System.Exp( _1_r_number);
  End;

Function InternalInt( Const _1_r_number: double): double;
  Begin
    q4interruptions.assertRaise( not Math.IsNan( _1_r_number), 'q4math.InternalInt: number must not be NaN');
    Result := Math.Floor( _1_r_number);
  End;

Function InternalLog( Const _1_r_number: double): double;
  Begin
    q4interruptions.assertRaise( _1_r_number > 0, 'q4math.InternalLog: number must be > 0');
    Result := System.Ln( _1_r_number);
  End;

Function InternalModulo( Const _1_r_number1: double; Const _2_r_number2: double): double;
  Var
    _e_number1:   int64;
    _e_number2:   int64;
    _e_remainder: int64;
  Begin
    _e_number1 := System.Round( _1_r_number1);
    _e_number2 := System.Round( _2_r_number2);
    q4interruptions.assertRaise( _e_number2 <> 0, 'q4math.InternalModulo: divisor must not be 0');
    _e_remainder := _e_number1 mod _e_number2;
    Result := _e_remainder;
  End;

Function InternalRandom: int64;
  Begin
    Result := System.Random( 32768);
  End;

Function InternalRound( Const _1_r_number: double; Const _2_e_places: int64): double;
  Var
    _r_scale: double;
    _r_scaledValue: double;
  Begin
    q4interruptions.assertRaise( not Math.IsNan( _1_r_number), 'q4math.InternalRound: number must not be NaN');
    q4interruptions.assertRaise( ( _2_e_places >= -18) and ( _2_e_places <= 18), 'q4math.InternalRound: places out of supported range');

    _r_scale := InternalPower10( System.Abs( _2_e_places));

    If ( _2_e_places >= 0) Then Begin
      _r_scaledValue := _1_r_number * _r_scale;
      Result := Math.SimpleRoundTo( _r_scaledValue, 0) / _r_scale;
    End Else Begin
      _r_scaledValue := _1_r_number / _r_scale;
      Result := Math.SimpleRoundTo( _r_scaledValue, 0) * _r_scale;
    End;
  End;

Procedure InternalSetRealComparisonLevel( Const _1_r_epsilon: double);
  Begin
    q4interruptions.assertRaise( _1_r_epsilon > 0, 'q4math.InternalSetRealComparisonLevel: epsilon must be > 0');
    r_realComparisonEpsilon := _1_r_epsilon;
  End;

Function InternalSin( Const _1_r_number: double): double;
  Begin
    q4interruptions.assertRaise( not Math.IsNan( _1_r_number), 'q4math.InternalSin: number must not be NaN');
    Result := System.Sin( _1_r_number);
  End;

Function InternalSquareRoot( Const _1_r_number: double): double;
  Begin
    q4interruptions.assertRaise( _1_r_number >= 0, 'q4math.InternalSquareRoot: number must be >= 0');
    Result := System.Sqrt( _1_r_number);
  End;

Function InternalTan( Const _1_r_number: double): double;
  Begin
    q4interruptions.assertRaise( not Math.IsNan( _1_r_number), 'q4math.InternalTan: number must not be NaN');
    Result := Math.Tan( _1_r_number);
  End;

Function InternalTrunc( Const _1_r_number: double; Const _2_e_places: int64): double;
  Var
    _r_scale: double;
    _r_scaledValue: double;
  Begin
    q4interruptions.assertRaise( not Math.IsNan( _1_r_number), 'q4math.InternalTrunc: number must not be NaN');
    q4interruptions.assertRaise( ( _2_e_places >= -18) and ( _2_e_places <= 18), 'q4math.InternalTrunc: places out of supported range');

    _r_scale := InternalPower10( System.Abs( _2_e_places));

    If ( _2_e_places >= 0) Then Begin
      _r_scaledValue := _1_r_number * _r_scale;
      Result := Math.Floor( _r_scaledValue) / _r_scale;
    End Else Begin
      _r_scaledValue := _1_r_number / _r_scale;
      Result := Math.Floor( _r_scaledValue) * _r_scale;
    End;
  End;

Function InternalRealEquals( Const _1_r_number1: double; Const _2_r_number2: double): boolean;
  Begin
    Result := q4math.abs( _1_r_number1 - _2_r_number2) <= InternalGetRealComparisonLevel;
  End;

Function abs( Const _1_r_number: double): double;
  Begin
    //https://developer.4d.com/docs/21/commands/abs
    Result := InternalAbs( _1_r_number);
  End;

Function arctan( Const _1_r_number: double): double;
  Begin
    //https://developer.4d.com/docs/21/commands/arctan
    Result := InternalArctan( _1_r_number);
  End;

Function cos( Const _1_r_number: double): double;
  Begin
    //https://developer.4d.com/docs/21/commands/cos
    Result := InternalCos( _1_r_number);
  End;

Function Dec( Const _1_r_number: double): double;
  Begin
    //https://developer.4d.com/docs/21/commands/dec
    Result := InternalDec( _1_r_number);
  End;

Function euroConverter( Const _1_r_value: double; Const _2_t_fromCurrency: string; Const _3_t_toCurrency: string): double;
  Begin
    //https://developer.4d.com/docs/21/commands/euro-converter
    Result := InternalEuroConverter( _1_r_value, _2_t_fromCurrency, _3_t_toCurrency);
  End;

Function exp( Const _1_r_number: double): double;
  Begin
    //https://developer.4d.com/docs/21/commands/exp
    Result := InternalExp( _1_r_number);
  End;

Function int( Const _1_r_number: double): double;
  Begin
    //https://developer.4d.com/docs/21/commands/int
    Result := InternalInt( _1_r_number);
  End;

Function log( Const _1_r_number: double): double;
  Begin
    //https://developer.4d.com/docs/21/commands/log
    Result := InternalLog( _1_r_number);
  End;

Function modulo( Const _1_r_number1: double; Const _2_r_number2: double): double;
  Begin
    //https://developer.4d.com/docs/21/commands/mod
    Result := InternalModulo( _1_r_number1, _2_r_number2);
  End;

Function random: int64;
  Begin
    //https://developer.4d.com/docs/21/commands/random
    Result := InternalRandom;
  End;

Function round( Const _1_r_round: double; Const _2_e_places: int64): double;
  Begin
    //https://developer.4d.com/docs/21/commands/round
    Result := InternalRound( _1_r_round, _2_e_places);
  End;

Procedure setRealComparisonLevel( Const _1_r_epsilon: double);
  Begin
    //https://developer.4d.com/docs/21/commands/set-real-comparison-level
    InternalSetRealComparisonLevel( _1_r_epsilon);
  End;

Function sin( Const _1_r_number: double): double;
  Begin
    //https://developer.4d.com/docs/21/commands/sin
    Result := InternalSin( _1_r_number);
  End;

Function squareRoot( Const _1_r_number: double): double;
  Begin
    //https://developer.4d.com/docs/21/commands/square-root
    Result := InternalSquareRoot( _1_r_number);
  End;

Function tan( Const _1_r_number: double): double;
  Begin
    //https://developer.4d.com/docs/21/commands/tan
    Result := InternalTan( _1_r_number);
  End;

Function trunc( Const _1_r_number: double; Const _2_e_places: int64): double;
  Begin
    //https://developer.4d.com/docs/21/commands/trunc
    Result := InternalTrunc( _1_r_number, _2_e_places);
  End;

Function realEquals( Const _1_r_number1: double; Const _2_r_number2: double): boolean;
  Begin
    Result := InternalRealEquals( _1_r_number1, _2_r_number2);
  End;

Function getRealComparisonLevel: double;
  Begin
    Result := InternalGetRealComparisonLevel;
  End;

Initialization
  r_realComparisonEpsilon := DEFAULT_REAL_COMPARISON_EPSILON;
  System.Randomize;

End.
