%{
#include <string.h>
#include "symbol_table.h"
%}

%union{
    struct PascalSToCPP::symbol *sym;//标识符
}

//LEX得到的token
%token <sym> SYMBOL
%token PROGRAM
%token INPUT
%token OUTPUT
%token CONST
%token CONSTANT
%token VAR
%token TYPE
%token BTYPE
%token PROCEDURE
%token FUNCTION

//规则段
%%

program: program_head code_block ;

program_head: PROGRAM SYMBOL '(' INPUT ',' OUTPUT ')' ';' {
    // TODO 输出头文件链接语句
};

code_block: constant_part variable_part function_part main_part;

constant_part: CONST constant_list
    |   ;
constant_list: constant
    |   constant_list constant;
constant: SYMBOL '=' CONSTANT ';'{
    // TODO 记录该常量至符号表，并输出翻译语句
};

variable_part: VAR variable_list 
    |   ;
variable_list: variable ';'{
    // TODO 对该行变量定义语句进行处理
}   |   variable_list variable ';'{
    // TODO 对该行变量定义语句进行处理
};
variable: SYMBOL ',' variable{
    // TODO 将SYMBOL压入堆栈
}   |   SYMBOL ':' TYPE{
    // TODO 输出：初始化TYPE堆栈
}   |   SYMBOL ':' BTYPE{
    // TODO 输出：初始化BTYPE堆栈
};

function_part: procedure_head process_body ';'
    |   function_head process_body ';';
procedure_head: PROCEDURE process_name ';'{
    // TODO 输出：void 函数名 参数表
    // TODO 修改返回值类型
};
function_head: FUNCTION process_name ':' BTYPE ';'{
    // TODO 输出：基本类型 函数名 参数表
    // TODO 修改返回值类型
};
process_name: SYMBOL parameter_table{
    // TODO 将该函数的标识符加入符号表，并记录参数表
};
parameter_table: '(' parameter_list ')'{
    // TODO 将parameter的值传给parameter_table
};
parameter_list: parameter{
    // TODO 初始化参数表
}   |   parameter_list parameter{
    // TODO 将下一列参数加入参数表
}   |   {
    // TODO 参数表为空的情况
};
parameter: variable{
    // TODO 记录非引用的参数至parameter
}   |   VAR variable{
    // TODO 记录引用的参数至parameter
};
process_body: constant_part variable_part code_block;

code_block: begin statement_list END{
    // TODO 输出'}'
};
begin: BEGIN{
    // TODO 输出'{'
};
statement_list: statement
   |   statement_list ';' statement;
statement: 

%%

