program test(input, output);
var x, y : integer;
function exchange(var x, y:integer):integer;
var tmp : integer;
begin
    tmp := x;
    x := y;
    y := tmp
end;
begin
    read(x, y);
    exchange(x, y);
    write(x, ' ', y, '\n')
end.

