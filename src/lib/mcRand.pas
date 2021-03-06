(* === mcRand ===
 * Ver: 1.0.2
 *  By: Igor Nunes
 * Random Generator for Mini Calc 4. *)

{$unitpath /wingraph}
{$mode objfpc}
unit mcRand;

interface
uses crt, sysutils, math, types, classes, wingraph,
     UNavigation, UWinBMP;

const RAND_MAXTRIES = 400000000;  // 400 million, LongWord range = 0..4294967295

type TRandRange  = array of string;
     TRandResult = array of LongWord;
     TRandTries  = LongWord;
     
     TRandGen = class(TObject)
        private
           var vRange  : TRandRange;
               vResult : TRandResult;
               vTries  : TRandTries;
               vDone   : boolean;

        public
           procedure Execute;
           function SaveWindow : boolean;

           constructor Create;
           property Range  : TRandRange  read vRange write vRange;
           property Tries  : TRandTries  read vTries write vTries;
           property Result : TRandResult read vResult;
           property Done   : boolean     read vDone;
           
           procedure ShowGraphic(const SIZE : TSize);
     end;



implementation

constructor TRandGen.Create;
begin
   self.vRange  := nil;
   self.vResult := nil;
   self.vTries  := 0;
   self.vDone   := false;
   inherited Create;
end;


procedure TRandGen.Execute;
var i : LongWord = 1;
begin
   SetLength(self.vResult, Length(self.vRange));
   
   Randomize;
   while (i <= self.vTries) do begin
      Inc(self.vResult[Random(Length(self.vRange))]);
      Inc(i);
   end;

   self.vDone := true;
end;


procedure TRandGen.ShowGraphic(const SIZE : TSize);
type TArrLInt = array of LongInt;

   function NextColor(var c : byte) : LongWord;
   const
      MIN = 1;
      MAX = 4;
   
   begin
      Inc(c);
      if c > MAX then
         c := MIN;
      case c of
         1 : NextColor := OrangeRed;
         2 : NextColor := Cobalt;
         3 : NextColor := Green;
         4 : NextColor := Sangria;
      end;
   end;

const SCALE = 1.2;

var driver, mode : SmallInt;
    width, height : word;
    barlength : word;
    i : word;
    maxres : LongInt;
    cl : byte = 0;
    key : char;

begin
   try
      height := Trunc(SIZE.cy * SCALE);
      width := Trunc(SIZE.cx * SCALE);
      barlength := SIZE.cx div (Length(self.vRange) + 2);
      maxres := MaxValue(TArrLInt(self.vResult));
      
      // Initialize graphic window
      DetectGraph(driver, mode);
      mode := mCustom;
      SetWindowSize(width, height);
      InitGraph(driver, mode, 'Mini Calc - Random');
      
      // Put graphic in place
      SetColor(White);
      SetTextStyle(0, VertDir, 2);
      
      Line((width - SIZE.cx) div 2, height - (height - SIZE.cy) div 2,
           (width - SIZE.cx) div 2, (height - SIZE.cy) div 2);
      Line((width - SIZE.cx) div 2, height - (height - SIZE.cy) div 2,
           width - (width - SIZE.cx) div 2, height - (height - SIZE.cy) div 2);
      
      for i := Low(self.vRange) to High(self.vRange) do begin
         SetFillStyle(SolidFill, NextColor(cl));
         FillRect((width - SIZE.cx) div 2 + (i + 1) * barlength, Trunc(SIZE.cy * (1 - self.vResult[i] / maxres)) + (height - SIZE.cy) div 2,
                  (width - SIZE.cx) div 2 + (i + 2) * barlength, height - (height - SIZE.cy) div 2);
         OutTextXY((width - SIZE.cx) div 2 + (i + 1) * barlength, height - (height - SIZE.cy) div 2,
                   self.vRange[i] + ' = ' + IntToStr(self.vResult[i]) + '(' + FloatToStrF(100 * self.vResult[i] / self.vTries, ffGeneral, 5, 1) + '%)');
      end;
      
      
      
      Pause('- Press Enter to close;' + #13+#10 +
            '- Press "S" to save graphic image and close.', [#13, 'S'], key);
      if key = 'S' then
         if not self.SaveWindow then begin
            TextColor(12);
            Pause(#13+#10 + 'Error while saving image.');
            TextColor(7);
         end;
   finally
      CloseGraph;
   end;
end;


function TRandGen.SaveWindow : boolean;
var FNAME : AnsiString;
begin
   DateTimeToString(FNAME, 'ddmmyyhhnnsszzz', Now);
   FNAME := 'mcRand_' + FNAME;
   SaveWindow := SaveBMP(FNAME);
end;

end.