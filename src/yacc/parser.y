%{

#include <string>
#include <vector>
#include <map>
#include <utility>
#include <iostream>
#include <cstdio>
#include <fstream>
#include <sstream>
#include <optional>

#include "../symbol_table/symbol_table.h"

using namespace std;
using namespace PascalSToCPP;

SymbolTable sym_table;
%}

%union
{
	string *targetCode;

	struct
	{
		double num;
		Type type;
	    string *targetCode;
	} targetDigitCode;

	struct
	{
		vector<string> *names;
	} idList;

	struct
	{
		vector<string> *names;
	    vector<Type> *types;
	    string *targetCode;
	} exprList;

	struct
	{
		Type type;
		int arrayTop;
		int arrayBottom;
		string *targetCode;
	} typeStruct;

	struct
	{
		vector<pair<Type, vector<string>>> *paraTypeAndNames;
		string *targetCode;
	} parameterStruct;

	struct
	{
		Type type;
		string *targetCode;
	}expStruct;
}

%token <targetCode> PROGRAM VAR ARRAY OF RECORD INTEGER REAL BOOLEAN FUNCTION PROCEDURE  DO
					BEGIN IF THEN END NOT WHILE READ WRITE ELSE TRUE FALSE

%token <targetCode> RELOP ADDOP MULOP ASSIGNOP

%token <targetCode>	ID

%token <targetDigitCode> NUM

%type <targetCode>  program program_head subprogram_head program_body declarations declaration
					subprogram_declarations subprogram_declaration statement compound_statement
					optional_statements procedure_call_statement statement_list sign

%type <idList> identifier_list

%type <exprList> expr_list

%type <typeStruct> type standard_type

%type <expStruct> variable expression simple_expr term factor

%type <parameterStruct> parameter_list parameter_lists arguments
%%

program : program_head program_body '.'
				{

				}
        | program_head program_body error
				{

				};

program_head : PROGRAM ID '(' identifier_list ')' ';'
				{


				};

identifier_list : identifier_list ',' ID
				{

				}
				| ID
				{

				};

program_body : declarations subprogram_declarations compound_statement
				{

				};

declarations : VAR declaration ';'
				{

				}
				|
				{

				};

declaration : declaration ';' identifier_list ':' type
				{

				}
				| identifier_list ':' type
				{

				};

type : standard_type
				{

				}
				| ARRAY '[' NUM '.' '.' NUM ']' OF standard_type
				{

				}
				| RECORD declaration END
				{

				};

standard_type : INTEGER
				{

				}
				| REAL
				{

				}
				| BOOLEAN
				{

				};

subprogram_declarations : subprogram_declarations subprogram_declaration ';'
				{
					string temp = string($1->data()) + "\n" + string($2->data());
					$$ = new string(temp);
				}
				|
				{
					$$ = new string("");
				};

subprogram_declaration : subprogram_head declarations compound_statement
				{
					string temp = string($1->data()) + "\n" + string($2->data()) + "\n" + string($3->data()) + "\n}\n";
					$$ = new string(temp);
					//TODO重定向
				};

subprogram_head : FUNCTION ID arguments ':' standard_type ';'
				{


				}
				| FUNCTION ID arguments error
				{
				}
				| PROCEDURE ID arguments ';'
				{

				}
				| PROCEDURE ID arguments error ';'
				{

				};


arguments : '(' parameter_lists ')'
				{
					$$.paraType = new vector <DATA_TYPE>;
					for(int i = 0; i < ($2.paraType)->size(); i++)
					{
						($$.paraType)->push_back((*($2.paraType))[i]);
					}
					string temp = "(" + string(($2.targetCode)->data()) + ")";
					$$.targetCode = new string(temp);
				}
				|
				{
					string temp = "()";
					$$.targetCode = new string(temp);
				};

parameter_lists : parameter_lists ';' parameter_list
				{
					// TODO 检查顺序是否正确
					$$.targetCode = new string($1.targetCode);
					$$.targetCode.push_back(','); // 分隔两个参数列表
					$$.targetCode.append(*($3.targetCode));
					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>($1.paraTypeAndNames);
					$$.paraTypeAndNames.push_back($3.parameter_list->front());
				}
				| parameter_list
				{
					$$.targetCode = new string($1.targetCode);
					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>($1.paraTypeAndNames);
				};

parameter_list : VAR identifier_list ':' type
				{
					// 填写参数表
					Type &temp_type = *($4.type);
					temp_type.is_ref = true;

					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>();
				    $$.paraTypeAndNames->push_back({temp_type, *($2.names)});
					
					$$.targetCode = new string();

					for (int i = 0; i < $2->size(); i++)
					{
						$$.targetCode->append(*($4.targetCode));
						if (temp_type.isArray()) // 数组的引用区别对待
						{
							$$.targetCode->append(" (&")
										 ->append($2.names[i])
										 ->append(")");
										 ->append(temp_type.getArrayPeriodsString())
										 ->append(",");
						}
						else 
						{
							$$.targetCode->append(" &")
									 	 ->append($2.names[i])
									 	 ->append(",");
						}
					}
					$$.targetCode->pop_back(); // 将最后一个逗号弹出
				}
				|  identifier_list ':' type
				{
				    // 填写参数表
					Type &temp_type = *($4.type);
					temp_type.is_ref = false;

					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>();
				    $$.paraTypeAndNames->push_back({temp_type, *($2.names)});
					
					$$.targetCode = new string();

					for (int i = 0; i < $2->size(); i++)
					{
						$$.targetCode->append(*($4.targetCode) + " ")
									 ->append($2.names[i]);
						if (temp_type.isArray())
							$$.targetCode->append(temp_type.getArrayPeriodsString());
						$$.targetCode->push_back(',');
					}
					$$.targetCode->pop_back(); // 将最后一个逗号弹出
				};

compound_statement : BEGIN optional_statements END
				{
					string temp_code;
					temp_code.append("{\n")
							 .append(*($2.targetCode))
							 .append("\n}\n");
					// $$.targetCode = new string(move(temp_code));
					$$.targetCode = new string(temp_code);
				};

optional_statements : statement_list
				{
					$$.targetCode = new string(*($1.targetCode));
				}
				|
				{
					$$.targetCode = new string("");
				};

statement_list : statement_list ';' statement
				{
					$$.targetCode = new string(*($1.targetCode));
					$$.targetCode->append(*($2.targetCode) + "\n");
				}
				| statement
				{
					$$.targetCode = new string(*($1.targetCode) + "\n");
				};

	struct
	{
		Type type;
		string *targetCode;
	}expStruct;
statement : variable ASSIGNOP expression
				{
					// expression.type 已经是表达式运算最终的结果
					optional<Type> lhs_type{nullopt};
					Type rhs_type = $3.type->type;

					if ($1.type->type == BasicType::CALLABLE)
						lhs_type = $1.type->ret_type;
					else
						lhs_type = $1.type->type;

					

				}
				| procedure_call_statement
				{

				}
				| compound_statement
				{

				}
				| IF expression THEN statement
				{

				}
				| IF expression THEN statement ELSE statement
				{

				}
				| WHILE expression DO statement
				{

				}
				| READ '(' identifier_list ')'
				{

				}
				| WRITE '(' expr_list ')'
				{

				};

variable : ID
				{

				}
				| ID '[' expression ']'
				{

				};

procedure_call_statement : ID
				{

				}
				| ID '(' expr_list ')'
				{

				};

expr_list : expr_list ',' expression
				{

				}
				| expression
				{

				};

expression : simple_expr RELOP simple_expr
				{

				}
				| simple_expr
				{

				};

simple_expr : simple_expr ADDOP term
				{

				}
				| term
				{

				}
				| sign term
				{

				};

term : term MULOP factor
				{

				}
				| factor
				{

				};

factor : ID
				{

				}
				| ID '(' expr_list ')'
				{

				}
				| ID '[' expression ']'
				{

				}
				| NUM
				{

				}
				| '(' expression ')'
				{

				}
				| NOT factor
				{

				}
				| TRUE
				{

				}
				| FALSE
				{

				};

sign : '+'
				{

				}
				| '-'
				{

				};

%%

int main(void) {
	return yyparse();
}