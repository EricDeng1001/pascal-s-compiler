program QuickSort;
var arr: array[1..10] of integer;

    procedure ReadArray;
    var i: integer;
    begin
        for i := 1 to 10 do read(arr[i])
    end;

    procedure OutputArray;
    var i: integer;
    begin
        for i := 1 to 10 do write(arr[i], ' ');
        write('\n') {\n}
    end;

    function GetPivotIndex(l, r: integer) : integer;
    var mid: integer;
    begin
        mid := (l + r) div 2;
        if ((arr[l] <= arr[mid]) and (arr[mid] <= arr[r])) or 
           ((arr[r] <= arr[mid]) and (arr[mid] <= arr[l])) then 
            GetPivotIndex := mid
        else 
            if ((arr[mid] <= arr[l]) and (arr[l] <= arr[r])) or
                ((arr[r] <= arr[l]) and (arr[l] <= arr[mid])) then
                GetPivotIndex := l
            else
                GetPivotIndex := r
    end;

    procedure Swap(var a, b: integer);
    var temp: integer;
    begin
        temp := a;
        a := b;
        b := temp
    end;

    procedure QuickSortImpl(l, r: integer);
    var pivotind, pivot, i, j: integer;
    begin
        if l < r then
        begin
            pivotind := GetPivotIndex(l, r);
            pivot := arr[pivotind];
            Swap(arr[l], arr[pivotind]);

            i := l;
            for j := l + 1 to r do
            begin
                if arr[j] <= pivot then
                begin
                   i := i + 1;
                   Swap(arr[i], arr[j])
                end
            end;

            Swap(arr[i], arr[l]);

            QuickSortImpl(l, i - 1);
            QuickSortImpl(i + 1, r)
        end
    end;

begin
    ReadArray;
    QuickSortImpl(1, 10);
    OutputArray
end.