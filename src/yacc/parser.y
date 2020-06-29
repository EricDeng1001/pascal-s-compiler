%{

#include <string>
#include <vector>
#include <map>
#include <utility>
#include <iostream>
#include <cstdio>
#include <fstream>
#include <sstream>
#include <pair>

#include "../symbol_table/symbol_table.h"

#define struct Type* Typeptr;

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
		Typeptr type;
	    string* targetCode;
	} targetDigitCode;

	struct
	{
		vector<string> *names;
	} idList;

	struct
	{
		vector <string>* names;
	    vector <struct Type>* types;
	    string* targetCode;
	} exprList;

	struct
	{
		Typeptr type;
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
		Typeptr type;
		string* targetCode;
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

program: program_head program_body '.'
				{
					string tmp_target = string($1->data()) + string($2->data());
					$$ = new string(tmp_target);
					cout << string($$->data());
				}
        | program_head program_body error
				{
					string tmp_target = string($1->data()) + string($2->data());
					$$ = new string(tmp_target);
					cout << string($$->data());
					yyerror("program -> program_head program_body . : missing '.'at the end of the program.");
					yyerrok();
				};

program_head: PROGRAM ID '(' INPUT ',' OUTPUT ')' ';'
				{
					$$ = new string("#include <iostream>\n#include <cmath>\nusing namespace std;\n"); //填写C++程序首部
				};

identifier_list: identifier_list ',' ID
				{
					// 记录已经录入的参数
					$$.names = new vector <string>;
					for(int i = 0; i < ($1.names)->size(); i++) {
						($$.names)->push_back((*($1.names))[i]);
					}
					// 记录新的id
					($$.names)->push_back(string($3->data()));
				}
				| ID
				{
					$$.names = new vector <string>;
					($$.names)->push_back(string($1->data()));
				};

program_body: declarations subprogram_declarations compound_statement
				{
					string tmp_target = string($1->data()) + string($2->data()) + "\n" + "int main()\n{\n" + string($3->data()) + "\nreturn 0;\n}\n";
					$$ = new string(tmp_target);
				};

declarations: VAR declaration ';'
				{
					string tmp_target = string($2->data());
					$$ = new string(tmp_target);
				}
				|
				{
					$$ = new string("");
				};

declaration: declaration ';' identifier_list ':' type
				{
					//使用dimension来判断是否为数组
					if(($5.type)->dimension == 0) {
						string tmp_target = string(($5.targetCode)->data());
						for(int i = 0; i < ($3.names)->size(); i++) {

							struct Symbol sym;
							sym.type = $5->type;
							sym.name = (*($3.names))[i];
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) {
								yyerror("declaration -> declaration ; identifier_list : type : redefined varible Identifier in identifier_list!");
								yyerrok();
							}
							else {	// 生成目标代码
								if(i != ($3.names)->size() - 1)
									tmp_target += " " + (*($3.names))[i] + ",";
								else
									tmp_target += " " + (*($3.names))[i] + ";\n";
							}
						}
						$$ = new string(string(($1)->data()) + tmp_target);
					}else
					{
						string tmp_target = string(($5.targetCode)->data());
						for(int i = 0; i < ($3.names)->size(); i++) {
							struct Symbol sym;
							sym.type = $5->type;
							sym.name = (*($3.names))[i];
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) {
								parser.yyerror("declaration -> declaration ; identifier_list : type : redefined array Identifier in identifier_list!");
								parser.yyerrok();
							}
							else {	// 生成目标代码

							}
						}
						$$ = new string(string(($1)->data()) + tmp_target);
					}
				}
				| identifier_list ':' type
				{

				};

type: standard_type
				{

				}
				| ARRAY '[' NUM '.' '.' NUM ']' OF standard_type
				{

				}
				| RECORD declaration END
				{

				};

standard_type: INTEGER
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

				}
				| parameter_list
				{

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
						if (temp_type.type != BasicType::CALLABLE && temp_type.dimension)
						$$.targetCode->append(" &")
									 ->append($2.names[i])
									 ->append(", ");
					}
					$$.targetCode->pop_back();
				}
				|  identifier_list ':' type
				{
				    // 填写参数表
					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>();
				    $$.paraTypeAndNames->push_back({$4.type, *($2.names)});

					$$.targetCode = new string();

					for (int i = 0; i < $2->size(); i++)
					{
						$$.targetCode->append(*($4.targetCode))
									 ->append(" &")
									 ->append($2.names[i])
									 ->append(", ");
					}
					$$.targetCode->pop_back();
				};

compound_statement : BEGIN optional_statements END
				{

				};

optional_statements : statement_list
				{

				}
				|
				{

				};

statement_list : statement_list ';' statement
				{

				}
				| statement
				{

				};

statement : variable ASSIGNOP expression
				{

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