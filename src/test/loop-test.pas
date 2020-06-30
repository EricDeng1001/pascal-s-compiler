program Loop;
var
   a, number, sum: integer;
   
begin
   for a := 10  to 20 do
   
   begin
      write('value of a: ', a, '\n')
   end;
   number := 10;
   sum := 0;
   while number>0 do
      begin
       sum := sum + number;
       number := number - 2
      end
end.
