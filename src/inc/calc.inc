(* Functions for calculation. *)

   procedure ParseFilter(var s : string);
   begin
      // replace float constants
      s := AnsiReplaceText(s, '$pi', 'pi');
      s := AnsiReplaceText(s, '$e', 'euler$');
      s := AnsiReplaceText(s, ')(', ')*(');
   end;


   procedure SetVar(id : ShortString; v : Float);
   var p : TFPExprIdentifierDef;
   begin
      p := mcParser.Identifiers.IdentifierByName(id);
      p.AsFloat := v;
   end;


   function GetVar(id : ShortString) : Float;
   var p : TFPExprIdentifierDef;
   begin
      p := mcParser.Identifiers.IdentifierByName(id);
      GetVar := p.AsFloat;
   end;


   function GetVarStr(id : ShortString) : string;
   var p : TFPExprIdentifierDef;
   begin
      p := mcParser.Identifiers.IdentifierByName(id);
      GetVarStr := p.AsString;
   end;


   procedure SetVarStr(id : ShortString; v : string);
   var p : TFPExprIdentifierDef;
   begin
      p := mcParser.Identifiers.IdentifierByName(id);
      p.AsString := v;
   end;

(* -------------------------- *)


function ComputeF(s : string; out answer : float) : boolean;
begin
   ParseFilter(s);
   
   try
      mcParser.Expression := s;
      mcResult := mcParser.Evaluate;
      
      ComputeF := mcResult.ResultType in [rtFloat, rtInteger];
      if ComputeF then
         answer := ArgToFloat(mcResult)
      else
         answer := 0.0;
         
   except
      ComputeF := false;
      answer := 0.0;
   end;
end;


procedure calc_prompt;
var
   toSave : record
      flag : boolean;
      id   : ShortString;
   end = (flag : false; id : '');

   procedure CheckSave(var s : string);
   var p : integer;
   begin
      // save onto variable?
      if AnsiStartsText('save.', s) then begin
         Delete(s, 1, 5);
         toSave.flag := true;
         toSave.id := '';
         p := 1;
         toSave.id := LowerCase(ExtractSubstr(s, p, [' ']));
         Delete(s, 1, p-1);
         case toSave.id of
            'pi'     : toSave.flag := false;
            'euler$' : toSave.flag := false;
         end;
      end;
   end;

var
   s : string;       // expression to be evaluated
   errmsg : string;  // error message
   i : word;         // generic indexer and iterator

begin
   clrscr;
   TextColor(15);
   write(' MC Calculator    ');
   TextColor(8);
   writeln('|  cancel = go back  |  exit = exit application  |'); writeln;
   
   
   repeat
      toSave.flag := false;
      
      TextColor(15);
      write(' MC> ');
      TextColor(7);
      readln(s);
      s := LowerCase(s);
      ParseFilter(s);
      CheckSave(s);
      
      if IsCommand(s) then begin
         case s of
            'help' : ;
            'exit' : _EXITING := true;
         end;
         
      end else begin
         try
            mcParser.Expression := s;
            mcResult := mcParser.Evaluate;
            
            TextColor(11);
            case mcResult.ResultType of
               rtBoolean  : writeln(PadLeft(Bool2Str[mcResult.ResBoolean], SCREENWIDTH-1));
               
               rtInteger  :
                  begin
                     SetVar('ans', mcResult.ResInteger);
                     if toSave.flag then
                        SetVar(toSave.id, mcResult.ResInteger);
                     writeln(PadLeft(Real2Str(mcResult.ResInteger), SCREENWIDTH-1));
                  end;
               
               rtFloat    :
                  begin
                     SetVar('ans', mcResult.ResFloat);
                     if toSave.flag then
                        SetVar(toSave.id, mcResult.ResFloat);
                     writeln(PadLeft(Real2Str(mcResult.ResFloat), SCREENWIDTH-1));
                  end;
               
               rtString   : writeln(PadLeft(mcResult.ResString, SCREENWIDTH-1));
               
               rtDateTime : writeln(PadLeft(FormatDateTime('ddd dd-mmm-yyyy hh:nn:ss:zzz', mcResult.ResDateTime), SCREENWIDTH-1));
            end;
            
            if toSave.flag and (toSave.id <> 'ans') then begin
               TextColor(15);
               writeln(PadLeft('Saved in "' + toSave.id + '"', SCREENWIDTH-1));
            end;
            
         except
            on ex : Exception do begin
               errmsg := PadLeft('[ERR] ' + ex.message, SCREENWIDTH-1);
               i := Pos('[ERR]', errmsg);
               TextColor(12);
               write(errmsg[1..i+5]);  // 5 = length of errmsg
               TextColor(14);
               writeln(errmsg[i+6..length(errmsg)]);
            end;
         end;
      end;
      
      TextColor(7);
      writeln(' ', DupeString('_', SCREENWIDTH-2));
      memory.SaveToFile(MEM_PAR, mcParser);
      
   until (LowerCase(s) = 'cancel') or _EXITING;
   TextColor(7);
end;