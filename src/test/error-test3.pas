program test
var x,y: integer;
c: char;
d: real;
z, z1, z2, z3, z4: array[1..9] of integer;
function gcd(a b: integer):integer;
var f:integer;
begin
    if b = 0 then	gcd := a
    else	gcd := gcd(b, a mod b)
end;
begin
    read(x, y);
    write(gcd(x, y))
end

