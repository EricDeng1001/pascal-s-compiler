program test(input, output);
var x,y : integer;
function exchange(var x,y:integer):integer;
var tmp : integer;
begin
    tmp := x;
    x := y;
    y := tmp;
    if x = y then
      while x < 0 do
          for y := -2 to 10 do
             x := y
end;
begin
    read(x, y);
    exchange(x, y);
    write(x, ' ', y, '\n')
end.

