program test(input, output);
var x,y: integer;
c: char;
d: real;
z, z1, z2, z3, z4: array[1..9] of integer;
function gcd(a,b: integer):integer;
begin
    if b = 0 then	gcd := a
    else	gcd := gcd(b, a mod b)
end;
begin
    write('输入两个数字, 以空格分隔\n');
	read(x, y);
	write(x, ' 和 ', y, ' 的最大公约数为 ', gcd (x,y), '\n')
end.

