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
%token PROCEDURE
%token FUNCTION

//规则段
%%

program: program_head ';' program_body ;

program_head: PROGRAM SYMBOL '(' INPUT ',' OUTPUT ')' {
    // TODO 输出头文件链接语句
}   |   PROGRAM SYMBOL {
    // TODO 同上
};

program_body: global_define_part code_block;

global_define_part: constant_define_part variable_define_part function_define_part {
    // TODO 全局变量及函数定义翻译完毕，输出void main()
};

constant_define_part: CONST constant_define_list
    |   ;
constant_define_list: constant_define
    |   constant_define_list constant_define;
constant_define: SYMBOL '=' CONSTANT ';' {
    // TODO 记录该常量至符号表，并输出翻译语句
};

variable_define_part: VAR variable_define_list
    |   ;
variable_define_list: variable_define ';' {
    // TODO 从栈顶标识符开始，对该行变量定义语句进行处理
}   |   variable_define_list variable_define ';' {
    // TODO 同上
};
variable_define: SYMBOL ',' variable_define {
    // TODO 将SYMBOL压入堆栈
}   |   SYMBOL ':' type {
    // TODO 初始化堆栈
};
type: TYPE {
    // TODO 定义基本类型
}   |   ARRAY '[' index_list ']' OF TYPE {
    // TODO 定义数组类型
};
index_list: DIGITS DDOT DIGITS {
    // TODO 一维下标
}   |   index_list ',' DIGITS DDOT DIGITS {
    // TODO 多维下标
};

function_define_part: procedure_head process_body ';'
    |   function_head process_body ';';
procedure_head: PROCEDURE process_name ';' {
    // TODO 输出：void 函数名 参数表
    // TODO 修改返回值类型
};
function_head: FUNCTION process_name ':' TYPE ';' {
    // TODO 输出：基本类型 函数名 参数表
    // TODO 修改返回值类型
};
process_name: SYMBOL parameter_table {
    // TODO 将该函数的标识符加入符号表，并记录参数表
};
parameter_table: '(' parameter_list ')' {
    // TODO 将parameter的值传给parameter_table
};
parameter_list: parameter {
    // TODO 初始化参数表
}   |   parameter_list parameter {
    // TODO 将下一列参数加入参数表
}   |   {
    // TODO 参数表为空的情况
};
parameter: variable_define {
    // TODO 记录非引用的参数至parameter
}   |   VAR variable_define {
    // TODO 记录引用的参数至parameter
};
process_body: constant_define_part variable_define_part code_block;

code_block: begin statement_list END {
    // TODO 输出'}'
};
begin: BEGIN {
    // TODO 输出'{'
};

statement_list: statement
    |   statement_list ';' statement;
statement: SYMBOL ASSIGNOP expression {
    // TODO 函数定义中的return
}   |   variable ASSIGNOP expression {
    // TODO 普通赋值语句
}   |   procedure_call {
    // TODO 过程调用
}   |   code_block
    |   statement_if statement else_part
    |   statement_for statement
    |   READ '(' variable_list ')' {
    // TODO std::cin >> variable_list ;
}   |   WRITE '(' expression_list ')' {
    // TODO std::cout << expression_list << endl;
}   |   ;

statement_if: IF expression THEN {
    // TODO if(expression)
};
else_part: else statement
    |   ;
else: ELSE {
    // TODO else
};

statement_for: FOR SYMBOL ASSIGNOP expression TO expression DO {
    // TODO for(int sym = exp1; sym < exp2; sym++)
};

expression_list: expression {
    // TODO 单表达式
}   |   expression_list ',' expression {
    // TODO 多个表达式
};
expression: simple_expression {
    // TODO 表达式->简单表达式
}   |   simple_expression COMPAREOP simple_expression {
    // TODO 表达式->简单表达式 比较运算符 简单表达式
};
simple_expression: item {
    // TODO 简单表达式->项
}   |   simple_expression OPLV1 item {
    // TODO 简单表达式->简单表达式 (+,-,or) 项
};
item: factor {
    // TODO 项->因子
}   |   item OPLV2 factor {
    // TODO 项->项 (*,/,div,mod,and) 因子   注意div和mod的翻译
};
factor: CONSTANT {
    // TODO 常量
}   |   variable {
    // TODO 变量
}   |   SYMBOL '(' expression_list ')' {
    // TODO 函数名(参数列表)
}   |   '(' expression ')' {
    // TODO (表达式)
}   |   NOT factor {
    // TODO !factor
}   |   NEG factor {
    // TODO -factor
};

variable_list: variable {
    // TODO 单个变量
}   |   variable_list ',' variable {
    // TODO 多个变量
};
variable: SYMBOL array_index {
    // TODO 根据array_index是否为空来决定是否翻译为数组
};
array_index: '[' expression_list ']' {
    // TODO [expression_list]
}   |   {
    // TODO 非数组变量
}

%%

