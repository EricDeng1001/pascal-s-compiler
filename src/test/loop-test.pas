program Loop;
var a, number, sum: integer;
ub, lb, step: integer;
begin
   for a := 10 to 20 do
   begin
      write('value of a: ', a, '\n')
   end;
   ub := 10;
   step := -2;
   number := ub;
   sum := 0;
   while number > lb do
   begin
      sum := sum + number;
      number := number + step
   end;
   write('sum of 2 + 4 + ... + 10 is ', sum, '\n')
end.
