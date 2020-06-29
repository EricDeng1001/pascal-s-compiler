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
					$$ = new string(*$1 + *$2);
					cout << *$$;
				}
        | program_head program_body error
				{
					$$ = new string(*$1 + *$2);
					cout << *$$;
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
					$$ = $2;
				}
				|
				{
					$$ = new string("");
				};

declaration: declaration ';' identifier_list ':' type
				{
					//使用dimension来判断是否为数组
					if(($5.type)->dimension == 0) {
						string tmp_target = $5->targetCode;
						for(int i = 0; i < ($3.names)->size(); i++) {

							Symbol sym((*($3.names))[i], $5->type, yylineno);
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
						$$ = new string(*$1 + tmp_target);
					}else if(($5.type)->dimension > 0)
					{
						string tmp_target = $5->targetCode;
						for(int i = 0; i < ($3.names)->size(); i++) {
							Symbol sym((*($3.names))[i], $5->type, yylineno);
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) {
								parser.yyerror("declaration -> declaration ; identifier_list : type : redefined array Identifier in identifier_list!");
								parser.yyerrok();
							}
							else {	// 生成目标代码
								string target = to_string($5.array_top - $5.array_bottom  + 1);
								if(i != ($3.idNameList)->size() - 1)
									tmp_target += " " + (*($3.names))[i] + "[" + target + "],";
								else
									tmp_target += " " + (*($3.names))[i] + "[" + target + "];\n";
							}
						}
						$$ = new string(*$1 + tmp_target);
					}
				}
				| identifier_list ':' type
				{
					//使用dimension来判断是否为数组
					if(($3.type)->dimension == 0) {
						string tmp_target = string(($3.targetCode)->data());
						for(int i = 0; i < ($1.names)->size(); i++) {
							Symbol sym((*($1.names))[i], $3->type, yylineno);
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
							Symbol sym((*($1.names))[i], $3->type, yylineno);
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) {
								parser.yyerror("declaration -> declaration ; identifier_list : type : redefined array Identifier in identifier_list!");
								parser.yyerrok();
							}
							else {	// 生成目标代码
								string target = to_string($5.array_top - $5.array_bottom  + 1);
								if(i != ($1.idNameList)->size() - 1)
									tmp_target += " " + (*($1.names))[i] + "[" + target + "],";
								else
									tmp_target += " " + (*($1.names))[i] + "[" + target + "];\n";
							}
						}
						$$ = new string(tmp_target);	
					}
				};
struct
	{
		Type *type;
		int arrayTop;
		int arrayBottom;
		string *targetCode;
	} typeStruct;
type: standard_type
				{
					$$.type = $1.type;
					$$.targetCode = $1.targetCode;
				}
				| ARRAY '[' NUM '.' '.' NUM ']' OF standard_type
				{
					if($3.type != BasicType::INTEGER || $6.type != BasicType::INTEGER) {
						parser.yyerror("type -> ARRAY [ NUM . . NUM ] OF standard_type : 数组参数NUM类型错误!");		/////////////////////////////////////////////////////// 现在
						parser.yyerrok();
					} 
					$$.type = $9.type;
					$$.array_top = (int)($6.num);
					$$.array_bottom = (int)($3.num);
					if($$.array_top - $$.array_bottom < 0) {
						parser.yyerror("type -> ARRAY [ NUM . . NUM ] OF standard_type : 数组下界不可小于上界!");
						parser.yyerrok();
					}
					$$.targetCode = $9.targetCode;
				};

standard_type: INTEGER
				{
					$$.type = new Type;
					$$->type.type = BasicType::INTEGER;
					$$.targetCode = new string("int");
				}
				| REAL
				{
					$$.type = new Type;
					$$->type.type = BasicType::REAL;
					$$.targetCode = new string("double");
				}
				| BOOLEAN
				{
					$$.type = new Type;
					$$->type.type = BasicType::BOOLEAN;
					$$.targetCode = new string("bool");
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

statement : variable ASSIGNOP expression
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
						// TODO 类型错误处理
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

					// $$.targetCode = new string(move(temp_code));
					$$.targetCode = new string(temp_code);
				}
				| procedure_call_statement
				{
					$$.targetCode = new string(*($1.targetCode) + ";");
				}
				| compound_statement
				{
					$$.targetCode = new string(*($1.targetCode) + ";");
				}
					struct
	{
		Type *type;
		string* targetCode;
	}expStruct;
				| IF expression THEN statement
				{
					Type expr_type = $2.type->type;
					if (expr_type.type != BasicType::BOOLEAN)
					
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