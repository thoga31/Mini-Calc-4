(* === mcStat ===
 * Ver: 1.1.1
 *  By: Igor Nunes
 * Statistical analysis. *)

{$unitpath /wingraph}
{$mode objfpc}
unit mcStat;

interface
uses crt, sysutils, math, mcVLM, UNavigation, types, wingraph, UWinBMP;

type
   TListElements = array of Extended;
   TKurtosis = record
      m1, m2, m3, m4 : Extended;
      skew : Extended;
      kurtosis : Extended;
   end;
   TLinReg = record
      a, b  : Extended;
      r, r2 : Extended;
   end;
   TGraphHandler = procedure;

procedure ExtractElements(vlm : TListMgr; const ID : string; out elements : TListElements);
procedure CumSum(const a : TListElements; out r : TListElements);
procedure AddToManager(vlm : TListMgr; const ID : string; elements : TListElements);
procedure SimpleLinearRegression(x, y : TListElements; out reg : TLinReg);

function mean2(xi, fi : TListElements) : Extended;
function stddev2(xi, fi : TListElements) : Extended;

procedure ShowBarGraph(proc : TGraphHandler; xi, fri, frac : TListElements; const SIZE : TSize; const WITHFRAC : boolean = true);
procedure ShowBarGraph(proc : TGraphHandler; xi, fri : TListElements; const SIZE : TSize); overload;

operator * (a : TListElements; b : TListElements) r : TListElements;
operator / (a : TListElements; b : Extended) r : TListElements;


implementation

function mean2(xi, fi : TListElements) : Extended;
var
   i : word;
   n : Extended = 0.0;
begin
   mean2 := 0;
   for i := Low(xi) to High(xi) do begin
      n := n + fi[i];
      mean2 := mean2 + xi[i] * fi[i];
   end;
   if n <> 0 then
      mean2 := mean2 / n;
end;


function stddev2(xi, fi : TListElements) : Extended;
var
   xifi : TListElements;
   mean_xifi : Extended;
   n : Extended = 0.0;
   i : word;
begin
   xifi := xi * fi;
   mean_xifi := mean2(xi, fi);
   stddev2 := 0.0;
   for i := Low(xi) to High(xi) do begin
      stddev2 := stddev2 + (xifi[i] - mean_xifi);
      n := n + fi[i];
   end;
   if n <> 0 then
      stddev2 := sqrt(stddev2 / n);
end;


procedure ExtractElements(vlm : TListMgr; const ID : string; out elements : TListElements);
var
   i : word;

begin
   SetLength(elements, vlm[ID].count);
   for i := 0 to Pred(vlm[ID].count) do
      elements[i] := vlm.Elements[ID, Succ(i)];
end;


procedure CumSum(const a : TListElements; out r : TListElements);
var
   i : word;

begin
   SetLength(r, Pred(Length(a)));
   
   if Length(a) >= 2 then begin
      r[0] := a[0] + a[1];
      for i := 1 to Pred(High(a)) do
         r[i] := r[Pred(i)] + a[Succ(i)];
   end else
      r[0] := a[0];
end;


procedure AddToManager(vlm : TListMgr; const ID : string; elements : TListElements);
var
   elem : Extended;

begin
   if not vlm.IDExists(ID) then
      vlm.CreateNewList(ID)
   else begin
      vlm.DeleteList(ID);
      vlm.CreateNewList(ID);
   end;
   
   for elem in elements do
      vlm.AppendToList(ID, elem);
end;


operator * (a : TListElements; b : TListElements) r : TListElements;
// a and b must have the same length!
var
   i : word;
begin
   SetLength(r, Length(a));
   for i := Low(r) to High(r) do
      r[i] := a[i] * b[i];
end;


operator / (a : TListElements; b : Extended) r : TListElements;
var
   i : word;

begin
   SetLength(r, Length(a));
   for i := Low(a) to High(a) do
      r[i] := a[i] / b;
end;


procedure SimpleLinearRegression(x, y : TListElements; out reg : TLinReg);
var
   sx, sy : Extended;
   mean_x, mean_y : Extended;
   xy : TListElements;
   mean_xy : Extended;
   sqr_x, sqr_y : TListElements;
   mean_sqr_x, mean_sqr_y : Extended;

begin
   // Auxiliar calculations
   mean_x := mean(x);
   mean_y := mean(y);
   sx := stddev(x);
   sy := stddev(y);
   xy := x * y;
   mean_xy := mean(xy);
   sqr_x := x*x;
   sqr_y := y*y;
   mean_sqr_x := mean(sqr_x);
   mean_sqr_y := mean(sqr_y);
   
   // Final calculations
   reg.r := (mean_xy - mean_x * mean_y) / sqrt((mean_sqr_x - sqr(mean_x)) * (mean_sqr_y - sqr(mean_y)));
   reg.r2 := sqr(reg.r);
   
   // f = AX+B
   reg.a := reg.r*(sy/sx);
   reg.b := mean_y - reg.a * mean_x;
end;


procedure ShowBarGraph(proc : TGraphHandler; xi, fri, frac : TListElements; const SIZE : TSize; const WITHFRAC : boolean = true);

   function NextColor(const WG : boolean; var c : byte) : LongWord;
   const
      MIN = 1;
      MAX = 4;
      { COLORCODE : array [MIN..MAX] of LongWord = (OrangeRed, Cobalt, Green, Sangria); }  // Illegal expression in FPC??
   begin
      if not WG then begin
         Inc(c);
         if c > MAX then
            c := MIN;
         // NextColor := COLORCODE[c];
         case c of
            1 : NextColor := OrangeRed;
            2 : NextColor := Cobalt;
            3 : NextColor := Green;
            4 : NextColor := Sangria;
         end;
      end else
         NextColor := OrangeRed;
   end;

const
   SCALE = 1.2;

var
   driver, mode : SmallInt;
   width, height : word;
   barlength : word;
   maxres, maxres_ac : Extended;
   i, ii : word;
   cl : byte = 0;
   { key : char = #0;
   filename : AnsiString = ''; }

begin
   try
      width := trunc(SIZE.cx * SCALE);
      height := trunc(SIZE.cy * SCALE);
      if WITHFRAC then
         barlength := SIZE.cx div (2*Length(xi) + 2)
      else
         barlength := SIZE.cx div (Length(xi) + 2);
      maxres := MaxValue(fri);
      maxres_ac := MaxValue(frac);
      
      DetectGraph(driver, mode);
      mode := mCustom;
      SetWindowSize(width, height);
      InitGraph(driver, mode, 'Mini Calc - Statistics - Bar Graph');
      
      // Put graphic in place
      SetColor(White);
      SetTextStyle(0, VertDir, 2);
      
      Line((width - SIZE.cx) div 2, height - (height - SIZE.cy) div 2,
           (width - SIZE.cx) div 2, (height - SIZE.cy) div 2);
      Line((width - SIZE.cx) div 2, height - (height - SIZE.cy) div 2,
           width - (width - SIZE.cx) div 2, height - (height - SIZE.cy) div 2);
      
      ii := 0;
      for i := Low(xi) to High(xi) do begin
         SetFillStyle(SolidFill, NextColor(WITHFRAC, cl));
         FillRect((width - SIZE.cx) div 2 + (ii + 1) * barlength, Trunc(SIZE.cy * (1 - fri[i] / maxres)) + (height - SIZE.cy) div 2,
                  (width - SIZE.cx) div 2 + (ii + 2) * barlength, height - (height - SIZE.cy) div 2);
         
         OutTextXY((width - SIZE.cx) div 2 + (ii + 1) * barlength, height - (height - SIZE.cy) div 2,
                   LeftStr(FloatToStrF(xi[i], ffGeneral, 10, 1), 10) + ' = ' + LeftStr(FloatToStrF(100 * fri[i], ffGeneral, 5, 1) + '%)', 7));
         
         if WITHFRAC and (i < High(xi)) then begin
            SetFillStyle(SolidFill, Cobalt);
            FillRect((width - SIZE.cx) div 2 + (ii + 2) * barlength, Trunc(SIZE.cy * (1 - frac[i] / maxres_ac)) + (height - SIZE.cy) div 2,
                     (width - SIZE.cx) div 2 + (ii + 3) * barlength, height - (height - SIZE.cy) div 2);
            
            OutTextXY((width - SIZE.cx) div 2 + (ii + 2) * barlength, height - (height - SIZE.cy) div 2,
                     LeftStr(FloatToStrF(100 * frac[i], ffGeneral, 5, 1) + '%', 7));
         end;
         
         if WITHFRAC then
            Inc(ii, 2)
         else
            Inc(ii, 1);
      end;
      
      proc;
      
   finally
      CloseGraph;
   end;
end;


procedure ShowBarGraph(proc : TGraphHandler; xi, fri : TListElements; const SIZE : TSize); overload;
begin
   ShowBarGraph(proc, xi, fri, nil, SIZE, false);
end;

end.