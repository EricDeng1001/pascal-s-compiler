program test(input, output);
var x,y : integer;
function exchange(x, y:integer):integer;
var tmp : integer;
begin
    tmp := x;
    x := y;
    y := tmp
end;
begin
    write('函数参数为传值时: ', 'exchange(x, y:integer)', '\n');
    write('输入两个数字, 以空格分隔', '\n');
    write('x = ');
    read(x);
    write('y = ');
    read(y);
    exchange(x, y);
    write('交换后 x = ', x, ', y = ', y, '\n')
end.

