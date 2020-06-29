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
		Type *type;
	    string* targetCode;
	} targetDigitCode;

	struct
	{
		vector<string> *names;
	} idList;

	struct
	{
		vector <string>* names;
	    vector <Type>* types;
	    string* targetCode;
	} exprList;

	struct
	{
		Type *type;
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
		Type *type;
		string* targetCode;
	}expStruct;
}

%token <targetCode> PROGRAM VAR ARRAY OF RECORD INTEGER REAL BOOLEAN FUNCTION PROCEDURE  DO
					BEGIN IF THEN END NOT WHILE READ WRITE ELSE TRUE FALSE INPUT OUTPUT

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
					}else if(($5.type)->dimension > 0)
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
								int array_range = $5.array_top - $5.array_bottom  + 1;
								stringstream ss; 
								string target;
								ss << array_range;
								ss >> target;
								if(i != ($3.idNameList)->size() - 1)
									tmp_target += " " + (*($3.names))[i] + "[" + target + "],";
								else
									tmp_target += " " + (*($3.names))[i] + "[" + target + "];\n";
							}
						}
						$$ = new string(string(($1)->data()) + tmp_target);
					}
				}
				| identifier_list ':' type
				{
					//使用dimension来判断是否为数组
					if(($3.type)->dimension == 0) {
						string tmp_target = string(($3.targetCode)->data());
						for(int i = 0; i < ($1.names)->size(); i++) {

							struct Symbol sym;
							sym.type = $3->type;
							sym.name = (*($1.names))[i];
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) {
								yyerror("declaration -> declaration ; identifier_list : type : redefined varible Identifier in identifier_list!");
								yyerrok();
							}
							else {	// 生成目标代码
								if(i != ($1.names)->size() - 1)
									tmp_target += " " + (*($1.names))[i] + ",";
								else
									tmp_target += " " + (*($1.names))[i] + ";\n";
							}
						}
						$$ = new string(tmp_target);
					}else if(($3.type)->dimension > 0)
					{
						string tmp_target = string(($3.targetCode)->data());
						for(int i = 0; i < ($1.names)->size(); i++) {
							struct Symbol sym;
							sym.type = $3->type;
							sym.name = (*($1.names))[i];
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) {
								parser.yyerror("declaration -> declaration ; identifier_list : type : redefined array Identifier in identifier_list!");
								parser.yyerrok();
							}
							else {	// 生成目标代码
								int array_range = $3.array_top - $3.array_bottom  + 1;
								stringstream ss; 
								string target;
								ss << array_range;
								ss >> target;
								if(i != ($1.idNameList)->size() - 1)
									tmp_target += " " + (*($1.names))[i] + "[" + target + "],";
								else
									tmp_target += " " + (*($1.names))[i] + "[" + target + "];\n";
							}
						}
						$$ = new string(tmp_target);	
					}
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

subprogram_declarations: subprogram_declarations subprogram_declaration ';'
				{
					string temp = string($1->data()) + "\n" + string($2->data());
					$$ = new string(temp);
				}
				|
				{
					$$ = new string("");
				};

subprogram_declaration: subprogram_head declarations compound_statement
				{
					string temp = string($1->data()) + "\n" + string($2->data()) + "\n" + string($3->data()) + "\n}\n";
					$$ = new string(temp);
					//TODO重定向
				};

subprogram_head: FUNCTION ID arguments ':' standard_type ';'
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


arguments: '(' parameter_lists ')'
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

parameter_lists: parameter_lists ';' parameter_list
				{
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

parameter_list: VAR identifier_list ':' type
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

compound_statement: BEGIN optional_statements END
				{
					string temp_code;
					temp_code.append("{\n")
							 .append(*($2))
							 .append("\n}\n");
					// $$ = new string(move(temp_code));
					$$ = new string(temp_code);
				};

optional_statements: statement_list
				{
					$$ = new string(*($1));
				}
				|
				{
					$$ = new string("");
				};

statement_list: statement_list ';' statement
				{
					$$ = new string(*($1));
					$$->append(*($2) + "\n");
				}
				| statement
				{
					$$ = new string(*($1) + "\n");
				};

statement: variable ASSIGNOP expression
				{
					Type lhs_type, rhs_type;
					bool is_return{false};
					if ($1.type->type == BasicType::CALLABLE)
					{
						lhs_type = $1.type->ret_type;
						is_return = true;
					}
					else
						lhs_type = $1.type->type;
					rhs_type = $3.type->type;
					
					if (lhs_type != rhs_type)
					{
						yyerror("赋值语句两边的类型不相等");
						yyerrok;
					}

					string temp_code;
					if (is_return)
					{
						temp_code.append("return ")
								 .append(*($3.targetCode))
								 .append(";");
					}
					else
					{
						temp_code.append(*($1.targetCode))
								 .append(" = ")
								 .append(*($3.targetCode));
					}

					// $$ = new string(move(temp_code));
					$$ = new string(temp_code);
				}
				| procedure_call_statement
				{
					$$ = new string(*($1) + ";");
				}
				| compound_statement
				{
					$$ = new string(*($1) + ";");
				}
				| IF expression THEN statement
				{
					Type expr_type = $2.type->type;
					if (expr_type.type != BasicType::BOOLEAN)
					{
						yyerror("if 后的表达式必须为布尔表达式");
						yyerrok;
					}

					string temp_code;
					temp_code.append(string("if (") + *($2.targetCode) + ") ")
							 .append("{\n")
							 .append(*($4))
							 .append("\n}\n");
				}
				| IF expression THEN statement ELSE statement
				{
					Type expr_type = $2.type->type;
					if (expr_type.type != BasicType::BOOLEAN)
					{
						yyerror("if 后的表达式必须为布尔表达式");
						yyerrok;
					}

					string temp_code;
					temp_code.append(string("if (") + *($2.targetCode) + ") ")
							 .append("{\n")
							 .append(*($4) + "\n")
							 .append("}\n")
							 .append("else {\n")
							 .append(*($6) + "\n")
							 .append("}\n");
				}
				| WHILE expression DO statement
				{
					Type expr_type = $2.type->type;
					if (expr_type.type != BasicType::BOOLEAN)
					{
						yyerror("while 后的表达式必须为布尔表达式");
						yyerrok;
					}

					string temp_code;
					temp_code.append(string("while (") + *($2.targetCode) + ") ")
							 .append("{\n")
							 .append(*($4) + "\n")
							 .append("}\n");
				}
				| READ '(' identifier_list ')'
				{
					string temp_code("cin");
					for (const auto &name : *($3.names))
						temp_code.append(" >> ")
								 .append(name);
					$$ = new string(temp_code);
				}
				| WRITE '(' expr_list ')'
				{
					string temp_code("cout");
					for (int i = 0; i < $3.types->size(); i++)
					{
						if ($3.types[i] == BasicType::VOID)
						{
							yyerror("write 中的表达式的值不能为空");
							yyerrok;
							// TODO 错误处理, 表达式不能为空
						}
					}

					for (const auto &name : *($3.names))
						temp_code.append(" >> ")
								 .append(name);
				};

variable: ID
				{

				}
				| ID '[' expression ']'
				{

				};

procedure_call_statement: ID
				{

				}
				| ID '(' expr_list ')'
				{

				};

expr_list: expr_list ',' expression
				{

				}
				| expression
				{

				};

expression: simple_expr RELOP simple_expr
				{

				}
				| simple_expr
				{

				};

simple_expr: simple_expr ADDOP term
				{

				}
				| term
				{

				}
				| sign term
				{

				};

term: term MULOP factor
				{

				}
				| factor
				{

				};

factor: ID
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

sign: '+'
				{

				}
				| '-'
				{

				};

%%

int main(void) {
	return yyparse();
}