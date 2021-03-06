procedure mem_screen;
var
   key  : char = #0;
   item : integer = 0;
   subitem : integer;
   i : word;
   selind : LongInt = 0;

begin
   clrscr;
   DrawSeparator(20, 1, SCREENHEIGHT-3);
   
   WriteXY(2, 17, '  INSTRUCTIONS  ', 0, 7);
   WriteXY(2, 18, ' <-  Reset value', 8);
   WriteXY(2, 19, '     Delete list', 8);
   WriteXY(2, 20, 'ESC  go back', 8);
   
   repeat
      key := mem_submenu.GetChoice(2, 2, item);
      
      case key of
         '1' : memory.ShowVars(22, 2, 19, mcParser, [rtFloat, rtInteger], '$');
         '2' : memory.ShowListsInfo(22, 2, 19, listmgr, selind);
         '3' : memory.ShowVars(22, 2, 19, mcParser, [rtString]);
         
         { 'S' :  // Settings
            begin
               
            end; }
         
         // PLOTTER
         
         'R' :  // reset all
            begin
               WriteXY(22, 2, 'THIS WILL ERASE ALL MEMORY!', 12);
               yesnomenu.Title := 'Are you sure you want to reset?';
               subitem := 1;
               if 'Y' = yesnomenu.GetChoice(22, 4, subitem) then begin
                  memory.ResetVars(mcParser, [rtInteger, rtFloat, rtString], '$');
                  if listmgr.ListCount > 0 then
                     listmgr.ClearAll;
                  // FUNCTIONS AND PLOTTER
                  GotoXY(22, 7);
                  Pause('Memory reset complete.');
               end;
               
               for i := 2 to 7 do begin
                  GotoXY(22, i); clreol;
               end;
            end;
      end;
   until key = OPTION_EXIT;
end;