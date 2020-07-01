program example(input,output);
var x,y:integer;
function gcd (a,b:integer): integer;
	begin
		if b=0 then
			gcd :=a
		else
			gcd := gcd (b, a mod b)
	end;
begin
	write('输入两个数字, 以空格分隔\n');
	read(x, y);
	write(x, ' 和 ', y, ' 的最大公约数为 ', gcd (x,y), '\n')
end.