program test(input, output);
var a: array[1..101] of integer; 
k,m,tempOut: integer;
function partition(low,high: integer): integer;
var i, j, temp: integer;
begin
    i := low - 1;
    j := low;
    while j < high do 
    begin
        if a[j] <= a[high] then
           begin
	   	 i := i + 1;
	   	 temp := a[i];
	    	 a[i] := a[j];
	         a[j] := temp
	   end;
	j := j + 1
    end ;
    i := i + 1;
    temp := a[i];
    a[i] := a[high];
    a[high] := temp;
    partition := i
end;

procedure qs(low,high: integer);
var pivot: integer;
begin
    pivot:=0;
    if low <= high then 
       begin
             pivot := partition(low, high);
	     qs(low, pivot - 1);
	     qs(pivot + 1, high)
       end
end;
begin
    m := 1000;
    
    while (m <= 0) or (m > (101 - 1)) do
    begin
        write('输入待排序的数的个数: ');
        read(m);
        if (m <= 0) or (m > (101 - 1)) then
            write('数字太小或者太大, 请重新输入', '\n')
    end;

    k := 1;
    write('输入 ', m , ' 个数字, 以空格分隔', '\n');
    while(k <= m) do 
    begin
		
         read(tempOut);
		 a[k] := tempOut;
         k := k+1
    end;
    qs(1, m);
    k := 1;
    while k <= m do 
    begin
        write(a[k], ' ');
	k := k + 1
    end;
    write('\n')
end.
