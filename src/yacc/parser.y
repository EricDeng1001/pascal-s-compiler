%{
#include <vector>
#include <map>
#include <utility>
#include <iostream>
#include <cstdio>
#include <fstream>
#include <sstream>
#include <optional>
#include <string>
#include "../symbol_table/symbol_table.h"

using namespace std;
using namespace PascalSToCPP;

SymbolTable sym_table;
int yylex(void);
void yyerror(const string &err_msg);
void yyerror(const string &err_msg, int line_no);
string toLower(const string &str);
#define YYERROR_VERBOSE

#ifndef NDEBUG
void debugInfo(const string &info) 
{
	cout << "!DEBUG!: " << info << endl;
}

void debugInfoBreak() { cout << endl; }
#else
void debugInfo(const string &info) {}
void debugInfoBreak() {}
#endif
%}

%code requires {
#include <string>
#include "../symbol_table/symbol_table.h"

using namespace std;
using namespace PascalSToCPP;

}

%union
{
	string *targetCode;

	struct
	{
		int isReal;
	    string* targetCode;
	} targetDigitCode;

	struct
	{
		vector<string> *names;
	} idList;

	struct
	{
		vector<string>* names;
	    vector<Type>* types;
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

%token <targetCode> TOK_PROGRAM TOK_VAR TOK_ARRAY TOK_OF TOK_RECORD TOK_INTEGER TOK_REAL TOK_BOOLEAN TOK_FUNCTION TOK_PROCEDURE TOK_DO
					TOK_FOR TOK_TO TOK_BEGIN TOK_IF TOK_THEN TOK_END TOK_NOT TOK_WHILE TOK_READ TOK_WRITE TOK_ELSE TOK_TRUE TOK_FALSE TOK_INPUT TOK_OUTPUT

%token <targetCode> TOK_RELOP TOK_ADDOP TOK_MULOP TOK_ASSIGNOP

%token <targetCode>	TOK_ID

%token <targetDigitCode> TOK_NUM

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
					debugInfo("进入产生式 program: program_head program_body '.'"); 
					string tmp_target = *($1) + *($2);
					$$ = new string(tmp_target);
					cout << *($$);
					debugInfoBreak();
				}
        | program_head program_body error
				{
					debugInfo("进入产生式 program: program_head program_body error"); 
					string tmp_target = *($1) + *($2);
					$$ = new string(tmp_target);
					cout << *($$);
					yyerror("program -> program_head program_body . : missing '.'at the end of the program.", @$.first_line);
					yyerrok;
					debugInfoBreak();
				};

program_head: TOK_PROGRAM TOK_ID '(' identifier_list ')' ';'
				{
					debugInfo("进入产生式 program_head: TOK_PROGRAM TOK_ID '(' identifier_list ')' ';'");
					debugInfo("TOK_PROGRAM = " + *($1) + ", TOK_ID = " + *($2));
					const auto &names = *($4.names);
					if (names.size() != 2 || (names.size() == 2 && (toLower(names[0]) != "input" || toLower(names[1]) != "output")))
					{
						yyerror("program 后的参数列表必须为input, output", @$.first_line);
						yyerrok;
					}
					$$ = new string("#include <iostream>\n#include <cmath>\nusing namespace std;\n"); //填写C++程序首部
					debugInfoBreak();
				}
			  | TOK_PROGRAM TOK_ID ';'
			  	{
					debugInfo("进入产生式 TOK_PROGRAM TOK_ID ';'");
					debugInfo("TOK_PROGRAM = " + *($1) + ", TOK_ID = " + *($2));
					$$ = new string("#include <iostream>\n#include <cmath>\nusing namespace std;\n"); //填写C++程序首部
			  		debugInfoBreak();
				};

identifier_list: identifier_list ',' TOK_ID
				{
					debugInfo("进入产生式 identifier_list: identifier_list ',' TOK_ID");
					debugInfo("TOK_ID = " + *($3));
					// 记录已经录入的参数
					$$.names = new vector<string>(*($1.names));
					// 记录新的id
					($$.names)->push_back(*($3));
					debugInfoBreak();
				}
				| TOK_ID
				{
					debugInfo("进入产生式 identifier_list: TOK_ID");
					debugInfo("TOK_ID = " + *($1));
					$$.names = new vector<string>();
					($$.names)->push_back(*($1));
					debugInfoBreak();
				};

program_body: declarations subprogram_declarations compound_statement
				{
					debugInfo("进入产生式 program_body: declarations subprogram_declarations compound_statement");
					string tmp_target = *($1) + "\n" +
										*($2) + "\n" +
										"int main()\n{\n" +
										*($3) + "\n" +
										"return 0;\n}\n";
					$$ = new string(tmp_target);
					debugInfoBreak();
				};

declarations: TOK_VAR declaration ';'
				{
					$$ = new string(*($2));
				}
				|
				{
					$$ = new string("");
				};

declaration: declaration ';' identifier_list ':' type
				{
					debugInfo("进入产生式 declaration: declaration ';' identifier_list ':' type");
					debugInfo("type = " + *($5.targetCode));
					//使用dimension来判断是否为数组
					if(($5.type)->dimension == 0) 
					{
						string tmp_target = *($5.targetCode);
						for(int i = 0; i < ($3.names)->size(); i++)
						{

							Symbol sym((*($3.names))[i], *($5.type), @$.first_line);
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) 
							{
								yyerror("declaration -> declaration ; identifier_list : type : redefined varible Identifier in identifier_list!", @$.first_line);
								yyerrok;
							}
							else 
							{	// 生成目标代码
								if(i != ($3.names)->size() - 1)
									tmp_target += " " + (*($3.names))[i] + ",";
								else
									tmp_target += " " + (*($3.names))[i] + ";\n";
							}
						}
						$$ = new string(*$1 + tmp_target);
					}
					else if(($5.type)->dimension > 0)
					{
						string tmp_target = *($5.targetCode);
						for(int i = 0; i < ($3.names)->size(); i++) 
						{
							Symbol sym((*($3.names))[i], *($5.type), @$.first_line);
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) 
							{
								yyerror("declaration -> declaration ; identifier_list : type : redefined array Identifier in identifier_list!", @$.first_line);
								yyerrok;
							}
							else 
							{	// 生成目标代码
								string target = to_string($5.arrayTop - $5.arrayBottom + 1);
								if(i != ($3.names)->size() - 1)
									tmp_target += " " + (*($3.names))[i] + "[" + target + "],";
								else
									tmp_target += " " + (*($3.names))[i] + "[" + target + "];\n";
							}
						}
						$$ = new string(*($1) + tmp_target);
					}
					debugInfoBreak();
				}
				| identifier_list ':' type
				{
					debugInfo("进入产生式 declaration: identifier_list ':' type");
					debugInfo("type = " + *($3.targetCode));
					//使用dimension来判断是否为数组
					if(($3.type)->dimension == 0) 
					{
						string tmp_target = *($3.targetCode);
						for(int i = 0; i < ($1.names)->size(); i++) 
						{
							Symbol sym((*($1.names))[i], *($3.type), @$.first_line);
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) 
							{
								yyerror("declaration -> declaration ; identifier_list : type : redefined varible Identifier in identifier_list!", @$.first_line);
								yyerrok;
							}
							else 
							{	// 生成目标代码
								if(i != ($1.names)->size() - 1)
									tmp_target += " " + (*($1.names))[i] + ",";
								else
									tmp_target += " " + (*($1.names))[i] + ";\n";
							}
						}
						$$ = new string(tmp_target);
						debugInfoBreak();
					}
					else if(($3.type)->dimension > 0)
					{
						string tmp_target = string(($3.targetCode)->data());
						for(int i = 0; i < ($1.names)->size(); i++) 
						{
							Symbol sym((*($1.names))[i], *($3.type), @$.first_line);
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) 
							{
								yyerror("declaration -> declaration ; identifier_list : type : redefined array Identifier in identifier_list!", @$.first_line);
								yyerrok;
							}
							else 
							{	// 生成目标代码
								string target = to_string($3.arrayTop - $3.arrayBottom  + 1);
								if(i != ($1.names)->size() - 1)
									tmp_target += " " + (*($1.names))[i] + "[" + target + "],";
								else
									tmp_target += " " + (*($1.names))[i] + "[" + target + "];\n";
							}
						}
						$$ = new string(tmp_target);
						debugInfoBreak();
					}
				};

type: standard_type
				{
					debugInfo("进入产生式 type: standard_type");
					debugInfo("standard_type = " + *($1.targetCode));
					$$.type = new Type(*($1.type));
					$$.targetCode = new string(*($1.targetCode));
					debugInfoBreak();
				}
				| TOK_ARRAY '[' TOK_NUM '.' '.' TOK_NUM ']' TOK_OF standard_type
				{
					debugInfo("进入产生式 type: TOK_ARRAY '[' TOK_NUM '.' '.' TOK_NUM ']' TOK_OF standard_type");
					debugInfo("TOK_NUM1 = " + *($3.targetCode) + ", TOK_NUM2 = " + *($6.targetCode) + 
						      ", standard_type = " + *($9.targetCode));
					if($3.isReal || $6.isReal) {
						yyerror("type -> ARRAY [ NUM . . NUM ] OF standard_type : 数组参数NUM类型错误!", @$.first_line);
						yyerrok;
					}
					$$.type = new Type(*($9.type));
					$$.arrayTop = (int)(atoi($6.targetCode->c_str()));
					$$.arrayBottom = (int)(atoi($3.targetCode->c_str()));
					if($$.arrayTop - $$.arrayBottom < 0) {
						yyerror("type -> ARRAY [ NUM . . NUM ] OF standard_type : 数组下界不可小于上界!", @$.first_line);
						yyerrok;
					}
					$$.targetCode = new string(*($9.targetCode));
					debugInfoBreak();
				};

standard_type: TOK_INTEGER
				{
					$$.type = new Type();
					$$.type->type = BasicType::INTEGER;
					$$.targetCode = new string("int");
				}
				| TOK_REAL
				{
					$$.type = new Type();
					$$.type->type = BasicType::REAL;
					$$.targetCode = new string("double");
				}
				| TOK_BOOLEAN
				{
					$$.type = new Type();
					$$.type->type = BasicType::BOOLEAN;
					$$.targetCode = new string("bool");
				};

subprogram_declarations: subprogram_declarations subprogram_declaration ';'
				{
					string temp = *($1) + "\n" + *($2);
					$$ = new string(temp);
				}
				|
				{
					$$ = new string("");
				};

subprogram_declaration: subprogram_head declarations compound_statement
				{
					string temp = *($1) + "\n" +
								  *($2) + "\n" +
								  *($3) + "\n";
					$$ = new string(temp);
					if (!sym_table.ExitScope())
					{
						// TODO 错误处理, 退出作用域失败
					}
					debugInfo("退出作用域");
					debugInfoBreak();
				};

subprogram_head: TOK_FUNCTION TOK_ID arguments ':' standard_type ';'
				{
					debugInfo("进入产生式 subprogram_head: TOK_FUNCTION TOK_ID arguments ':' standard_type ';'");
					debugInfo("TOK_ID = " + *($2) + ", arguments = " + *($3.targetCode) + ", ret_type = " + *($5.targetCode));
					// 检查函数名是否重复
					if (sym_table.isInScope(*($2)))
					{
						yyerror("重复的标识符 " + *($2), @$.first_line);
						yyerrok;
					}

					SymbolBuilder func_builder = Symbol::getSymbolBuilder();
					func_builder.addName(*($2))
								.setBasicType(BasicType::CALLABLE)
						   		.setRetType($5.type->type)
								.setDefAt(@$.first_line);

					int dimension = 0;
					for (const auto &[type, names] : *($3.paraTypeAndNames))
					{
						func_builder.addArg(type);
						dimension += names.size();
					}
					func_builder.setDimension(dimension);
					Symbol func_symbol = func_builder.Build();
					debugInfo("插入符号 " + func_symbol.toString());
					if (!sym_table.InsertSymbol(func_symbol).first)
					{
						// TODO 错误处理, 插入失败
					}

					// 向符号表中添加参数
					if (!sym_table.EnterScope(func_symbol.name))
					{
						// TODO 错误处理, 进入子作用域失败
					}
					debugInfo("进入作用域 " + func_symbol.name);

					for (const auto &[type, names] : *($3.paraTypeAndNames))
					{
						// 检查名字是否冲突
						SymbolBuilder params_builder = Symbol::getSymbolBuilder();
						params_builder.setType(type).setDefAt(@$.first_line);
						for (const auto &name : names)
						{
							if (sym_table.isInScope(name) || name == func_symbol.name)
							{
								yyerror("重复的标识符 " + name, @$.first_line);
								yyerrok;
							}
							auto temp_builder = params_builder;
							temp_builder.addName(name);
							sym_table.InsertSymbol(temp_builder.Build());
							debugInfo("插入参数符号 " + temp_builder.Build().toString());
						}
					}

					string temp_code = *($5.targetCode) + " " + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| TOK_FUNCTION TOK_ID arguments error
				{
					yyerror("函数 " + *($2) + " 没有返回值", @$.first_line);
					yyerrok;
					string temp_code = string("void ") + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
				}
				| TOK_PROCEDURE TOK_ID arguments ';'
				{
					debugInfo("进入产生式 subprogram_head: TOK_PROCEDURE TOK_ID arguments ';'");
					debugInfo("TOK_ID = " + *($2) + ", arguments = " + *($3.targetCode));
					// 检查函数名是否重复
					if (sym_table.isInScope(*($2)))
					{
						yyerror("重复的标识符 " + *($2), @$.first_line);
						yyerrok;
					}

					SymbolBuilder func_builder = Symbol::getSymbolBuilder();
					func_builder.addName(*($2))
								.setBasicType(BasicType::CALLABLE)
								.setDefAt(@$.first_line);

					int dimension = 0;
					for (const auto &[type, names] : *($3.paraTypeAndNames))
					{
						func_builder.addArg(type);
						dimension += names.size();
					}
					func_builder.setDimension(dimension);
					Symbol func_symbol = func_builder.Build();
					debugInfo("插入符号 " + func_symbol.toString());
					if (!sym_table.InsertSymbol(func_symbol).first)
					{
						// TODO 错误处理, 插入失败
					}

					// 向符号表中添加参数
					if (!sym_table.EnterScope(func_symbol.name))
					{
						// TODO 错误处理, 进入子作用域失败
					}
					debugInfo("进入作用域 " + func_symbol.name);

					for (const auto &[type, names] : *($3.paraTypeAndNames))
					{
						// 检查名字是否冲突
						SymbolBuilder params_builder = Symbol::getSymbolBuilder();
						params_builder.setType(type).setDefAt(@$.first_line);
						for (const auto &name : names)
						{
							if (sym_table.isInScope(name) || name == func_symbol.name)
							{
								yyerror("重复的标识符 " + name, @$.first_line);
								yyerrok;
							}
							auto temp_builder = params_builder;
							temp_builder.addName(name);
							sym_table.InsertSymbol(temp_builder.Build());
							debugInfo("插入参数符号 " + temp_builder.Build().toString());
						}
					}

					string temp_code = "void " + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| TOK_PROCEDURE TOK_ID arguments error ';'
				{
					yyerror("过程 " + *($2) + " 不能有返回值", @$.first_line);
					yyerrok;
					string temp_code = string("void ") + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
				};


arguments: '(' parameter_lists ')'
				{
					$$.paraTypeAndNames =
						new vector<pair<Type, vector<string>>>(*($2.paraTypeAndNames));
					$$.targetCode = new string("(");
					$$.targetCode->append(*($2.targetCode))
								 .append(")");
				}
				|
				{
					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>();
					$$.targetCode = new string("()");
				};

parameter_lists: parameter_lists ';' parameter_list
				{
					$$.targetCode = new string(*($1.targetCode));
					$$.targetCode->push_back(','); // 分隔两个参数列表
					$$.targetCode->append(*($3.targetCode));
					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>(*($1.paraTypeAndNames));
					$$.paraTypeAndNames->push_back($3.paraTypeAndNames->front());
				}
				| parameter_list
				{
					$$.targetCode = new string(*($1.targetCode));
					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>(*($1.paraTypeAndNames));
				};

parameter_list: TOK_VAR identifier_list ':' type
				{
					// 填写参数表
					Type &temp_type = *($4.type);
					temp_type.is_ref = true;

					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>();
				    $$.paraTypeAndNames->push_back({temp_type, *($2.names)});

					$$.targetCode = new string();

					for (int i = 0; i < $2.names->size(); i++)
					{
						$$.targetCode->append(*($4.targetCode));
						if (temp_type.isArray()) // 数组的引用区别对待
						{
							$$.targetCode->append(" (&")
										  .append($2.names->at(i))
										  .append(")")
										  .append(temp_type.getArrayPeriodsString())
										  .append(",");
						}
						else
						{
							$$.targetCode->append(" &")
									 	  .append($2.names->at(i))
									 	  .append(",");
						}
					}
					$$.targetCode->pop_back(); // 将最后一个逗号弹出
				}
				|  identifier_list ':' type
				{
				    // 填写参数表
					Type &temp_type = *($3.type);
					temp_type.is_ref = false;

					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>();
				    $$.paraTypeAndNames->push_back({temp_type, *($1.names)});

					$$.targetCode = new string();

					for (int i = 0; i < $1.names->size(); i++)
					{
						$$.targetCode->append(*($3.targetCode) + " ")
									  .append($1.names->at(i));
						if (temp_type.isArray())
							$$.targetCode->append(temp_type.getArrayPeriodsString());
						$$.targetCode->push_back(',');
					}
					$$.targetCode->pop_back(); // 将最后一个逗号弹出
				};

compound_statement: TOK_BEGIN optional_statements TOK_END
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
					$$->append(*($3) + "\n");
				}
				| statement
				{
					$$ = new string(*($1) + "\n");
				};

statement: variable TOK_ASSIGNOP expression
				{
					debugInfo("进入产生式 statement: variable TOK_ASSIGNOP expression");
					debugInfo("variable.type = " + $1.type->toString() + ", variable.targetCode = " + *($1.targetCode) +
							  ", expression.type = " + $3.type->toString() + ", expression.targetCode = " + *($3.targetCode));
					BasicType lhs_type, rhs_type;
					bool is_return{false};
					if ($1.type->type == BasicType::CALLABLE)
					{
						lhs_type = $1.type->ret_type;
						is_return = true;
					}
					else
						lhs_type = $1.type->type;
					rhs_type = $3.type->type;
					debugInfo("lhs_type = " + BasicTypeStr(lhs_type) + ", rhs_type = " + BasicTypeStr(rhs_type));

					if (lhs_type != rhs_type)
					{
						yyerror("赋值语句两边的类型不相等", @$.first_line);
						yyerrok;
					}

					if ($1.type->isArray())
					{
						yyerror("赋值语句不直接应用于数组", @$.first_line);
						yyerrok;
					}

					string temp_code;
					if (is_return)
					{
						temp_code.append("return ")
								 .append(*($3.targetCode) + ";");
					}
					else
					{
						temp_code.append(*($1.targetCode))
								 .append(" = ")
								 .append(*($3.targetCode) + ";");
					}

					// $$ = new string(move(temp_code));
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| procedure_call_statement
				{
				    debugInfo("进入产生式 statement: procedure_call_statement");
					debugInfo("pcs = " + *($1));
					$$ = new string(*($1) + ";");
					debugInfoBreak();
				}
				| compound_statement
				{
					$$ = new string(*($1));
				}
				| TOK_IF expression TOK_THEN statement
				{
					debugInfo("进入产生式 statement: TOK_IF expression TOK_THEN statement");
					debugInfo("expression.type=" + $2.type->toString() + ", expression.targetCode=" + *($2.targetCode) +
							  ", statement.targetCode=" + *($4));
					Type expr_type = *($2.type);
					if (expr_type.type != BasicType::BOOLEAN)
					{
						yyerror("if 后的表达式必须为布尔表达式", @$.first_line);
						yyerrok;
					}

					string temp_code;
					temp_code.append(string("if (") + *($2.targetCode) + ") ")
							 .append("{\n")
							 .append(*($4))
							 .append("\n}\n");
					debugInfoBreak();
				}
				| TOK_IF expression TOK_THEN statement TOK_ELSE statement
				{
					debugInfo("进入产生式 statement: TOK_IF expression TOK_THEN statement");
					debugInfo("expression.type=" + $2.type->toString() + ", expression.targetCode=" + *($2.targetCode) +
							  ", statement1.targetCode=" + *($4) + ", statement2.targetCode=" + *($6));
					Type expr_type = *($2.type);
					if (expr_type.type != BasicType::BOOLEAN)
					{
						yyerror("if 后的表达式必须为布尔表达式", @$.first_line);
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
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| TOK_WHILE expression TOK_DO statement
				{
					Type expr_type = *($2.type);
					if (expr_type.type != BasicType::BOOLEAN)
					{
						yyerror("while 后的表达式必须为布尔表达式", @$.first_line);
						yyerrok;
					}

					string temp_code;
					temp_code.append(string("while (") + *($2.targetCode) + ") ")
							 .append("{\n")
							 .append(*($4) + "\n")
							 .append("}\n");
				}
				| TOK_READ '(' identifier_list ')'
				{
					string temp_code("cin");
					for (const auto &name : *($3.names))
						temp_code.append(" >> ")
								 .append(name);
					$$ = new string(temp_code + ";");
				}
				| TOK_WRITE '(' expr_list ')'
				{
					string temp_code("cout");
					for (int i = 0; i < $3.types->size(); i++)
					{
						if ($3.types->at(i).type == BasicType::VOID)
						{
							yyerror("write 中的表达式的值不能为空", @$.first_line);
							yyerrok;
						}
					}

					for (const auto &name : *($3.names))
						temp_code.append(" >> ")
								 .append(name);
					$$ = new string(temp_code + ";");
				}
				| TOK_FOR TOK_ID TOK_ASSIGNOP expression TOK_TO expression TOK_DO statement
				{

				};

variable: TOK_ID
				{
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (!symbol) 
					{
          				yyerror("标识符 " + *($1) + " 未定义", @$.first_line);
          			  	yyerrok;
          			} 
					else if (symbol->type.isCallable()) 
					{
          			  	if (*($1) == sym_table.getParentSymbol()->name) 
						{
          			    	if (symbol->type.ret_type == BasicType::VOID) 
							{
          			      		yyerror("函数 " + *($1) + " 没有返回值", @$.first_line);
          			      		yyerrok;
          			    	} 
							else 
							{
          			      		$$.type = new Type(symbol->type);
          			    	}
          			  	} 
						else
						{
          			    	yyerror("函数 " + *($1) + "不应在赋值符号的左侧", @$.first_line);
          			      	yyerrok;
          			  	}
          			} 
					else if (symbol->type.isArray()) 
					{
          			  	yyerror("不允许对数组进行赋值", @$.first_line);
          			  	yyerrok;
          			}
          			else 
					{
          			  	$$.type = new Type(symbol->type);
          			  	$$.targetCode = new string(*($1));
          			}
				}
				| TOK_ID '[' expression ']'
				{
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (!symbol) 
					{
          			  	yyerror("标识符 " + *($1) + " 未定义", @$.first_line);
          			  	yyerrok;
          			} 
					else if (!symbol->type.isArray()) 
					{
          			  	yyerror("标识符 " + *($1) + "不为数组类型", @$.first_line);
          			  	yyerrok;
          			} 
					else 
					{
          			  	if ($3.type->type != BasicType::INTEGER) 
						{
          			    	yyerror("数组下标引用必须是整数", @$.first_line);
          			    	yyerrok;
          			  	}
						else
						{
          			    	$$.type = new Type(symbol->type);
          			    	$$.targetCode = new string(*($1) + "[" +  *($3.targetCode) + "]");
          			  	}
          			}
				};

procedure_call_statement: TOK_ID
				{
					debugInfo("进入产生式 procedure_call_statement: TOK_ID");
					debugInfo("TOK_ID = " + *($1));
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (!symbol) 
					{
          			  	yyerror("标识符 " + *($1) + " 未定义", @$.first_line);
          			  	yyerrok;
          			} 
					else 
					{
          			  	if (symbol->type.isCallable()) 
						{
          			    	$$ = new string(*($1) + "();\n");
          			  	} 
						else
						{
          			    	yyerror("对象 " + *($1) + " 不可调用", @$.first_line);
          			    	yyerrok;
          			  	}
          			}
					debugInfoBreak();
				}
				| TOK_ID '(' expr_list ')'
				{
					debugInfo("进入产生式 procedure_call_statement: TOK_ID '(' expr_list ')'");
					debugInfo("TOK_ID = " + *($1) + "expr_list = " + *($3.targetCode));
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (!symbol) 
					{
          			  	yyerror("标识符 " + *($1) + " 未定义", @$.first_line);
          			  	yyerrok;
          			} 
					else 
					{
          			  	if (!symbol->type.isCallable()) 
						{
          			    	yyerror("对象 " + *($1) + " 不可调用", @$.first_line);
          			    	yyerrok;
          			  	}
						else 
						{
          			    	if (symbol->type.dimension != $3.names->size()) 
							{
          			      		yyerror("参数个数不匹配, 期望参数个数: " + to_string(symbol->type.dimension) + 
										", 实际参数个数: " + to_string($3.names->size()), @$.first_line);
          			      		yyerrok;
          			    	} 
							else 
							{
          			      		for (int i = 0; i < $3.types->size(); i++) 
								{
          			        		if ((*($3.types))[i] != symbol->type.args[i]) 
									{
          			          			yyerror("第 " + to_string(i) + " 个参数类型不匹配, 期望类型: " + symbol->type.args[i].toString() +
												", 实际传入类型: " + (*($3.types))[i].toString() , @$.first_line);
          			          			yyerrok;
									}
								}
          			      		$$ = new string(*($1) + "(" + *($3.targetCode) + ");\n");
							}
						}
          			}
					debugInfoBreak();
				};

expr_list: expr_list ',' expression
				{
					debugInfo("进入产生式 expr_list: expr_list ',' expression");
					debugInfo("expression.targetCode = " + *($3.targetCode) + "expression.type = " + $3.type->toString());
          			$$.names = new vector<string>();
          			$$.types = new vector<Type>();
          			for (int i = 0; i < $1.names->size(); i++) 
					{
          			  	$$.names->push_back((*($1.names))[i]);
          			  	$$.types->push_back((*($1.types))[i]);
          			}
          			$$.names->push_back(*($3.targetCode));
          			$$.types->push_back(*($3.type));
          			$$.targetCode = new string(*($1.targetCode) + ", " + *($3.targetCode));
					debugInfoBreak();
				}
				| expression
				{
					debugInfo("进入产生式 expr_list: expr_list ',' expression");
					debugInfo("expression.targetCode = " + *($1.targetCode) + "expression.type = " + $1.type->toString());
          			$$.names = new vector<string>();
          			$$.types = new vector<Type>();
          			$$.names->push_back(*($1.targetCode));
          			$$.types->push_back(*($1.type));
          			$$.targetCode = new string(*($1.targetCode));
					debugInfoBreak();
				};

expression: simple_expr TOK_RELOP simple_expr
				{
          			string relop;
          			if (!($1.type->isCallable()) && !($1.type->isArray())
          			&& !($3.type->isCallable()) && !($3.type->isArray())) 
					{
          			  	if (*($2) == "<>") 
						{
          			    	relop = "!=";
          			  	} 
						else if (*($2) == "=") 
						{
          			    	relop = "==";
          			  	} 
						else 
						{
          			    	relop = string(*($2));
          			  	}
          			  	$$.type = new Type();
          			  	$$.type->type = BasicType::BOOLEAN;
          			  	$$.targetCode = new string(*($1.targetCode) + relop + *($3.targetCode));
          			} 
					else 
					{
          			  	yyerror("关系表达式，类型不正确", @$.first_line);
          			  	yyerrok;
          			}
				}
				| simple_expr
				{
          			$$.type = new Type(*($1.type));
          			$$.targetCode = new string(*($1.targetCode));
				};

simple_expr: simple_expr TOK_ADDOP term
				{
					debugInfo("进入产生式 simple_expr: simple_expr TOK_ADDOP term");
					debugInfo("simple_expr.type = " + $1.type->toString() + ", simple_expr.targetCode = " + *($1.targetCode) +
							  ", TOK_ADDOP = " + *($2) + ", term.type = " + $3.type->toString() + 
							  ", term.targetCode = " + *($3.targetCode));
          			if ($1.type->isCallable() || $1.type->isArray()
          			|| $3.type->isCallable() || $3.type->isArray()) 
					{
          			  	yyerror("运算类型不正确", @$.first_line);
          			  	yyerrok;
          			} 
					else 
					{
          			  	if (*($2) == "or") 
						{
          			    	if ($1.type->type != BasicType::BOOLEAN || $3.type->type != BasicType::BOOLEAN) 
							{
          			      		yyerror("or 运算符两侧必须为布尔类型", @$.first_line);
          			      		yyerrok;
							} 
							else 
							{
          			      		$$.targetCode = new string(*($1.targetCode) + "||" + *($3.targetCode));
          			      		$$.type = new Type();
          			      		$$.type->type = BasicType::BOOLEAN;
							}
          			  	} 
						else 
						{
          			    	if (($1.type->type == BasicType::INTEGER || $1.type->type == BasicType::REAL)
          			    	&& ($3.type->type == BasicType::INTEGER || $3.type->type == BasicType::REAL)) 
							{
          			    	   	$$.type = new Type();
          			    	  	if ($1.type->type == BasicType::REAL || $3.type->type == BasicType::REAL) 
								{
          			    	    	$$.type->type = BasicType::REAL;
          			    	  	} 
								else 
								{
          			    	    	$$.type->type = BasicType::INTEGER;
          			    	  	}
          			    	  	$$.targetCode = new string(*($1.targetCode) + *($2) + *($3.targetCode));
          			    	} 
							else 
							{
          			      		yyerror(*($2) + " 运算符两侧类型无效", @$.first_line);
          			      		yyerrok;
          			    	}
          			  	}
          			}
					debugInfoBreak();
				}
				| term
				{
					debugInfo("进入产生式 simple_expr: term");
					debugInfo("term.type = " + $1.type->toString() + ", term.targetCode = " + *($1.targetCode));
          			
					if ($1.type->isCallable())
					{
						$$.type = new Type();
						$$.type->type = $1.type->ret_type;
					}	
					else
						$$.type = new Type(*($1.type));
          			$$.targetCode = new string(*($1.targetCode));
					debugInfoBreak();
				}
				| sign term
				{
					debugInfo("进入产生式 simple_expr: sign term");
					debugInfo("sign = " + *($1) + ", term.type = " + $2.type->toString() +
							  ", term.targetCode = " + *($2.targetCode));
         			$$.type = new Type(*($2.type));
         			$$.targetCode = new string(*($1) + *($2.targetCode));
					debugInfoBreak();
				};

term: term TOK_MULOP factor
				{
					debugInfo("进入产生式 term: term TOK_MULOP factor");
					debugInfo("term.type = " + $1.type->toString() + ", term.targetCode = " + *($1.targetCode) +
							  ", TOK_MULOP = " + *($2) + ", factor.type = " + $3.type->toString() + 
							  ", factor.targetCode = " + *($3.targetCode));
          			if ($1.type->isCallable() || $1.type->isArray() ||
					    $3.type->isCallable() || $3.type->isArray()) 
					{
          			  	yyerror("运算类型不正确", @$.first_line);
          			  	yyerrok;
          			} 
					else 
					{
          			  	if (*($2) == "and") 
						{
          			  	  	if ($1.type->type != BasicType::BOOLEAN || $3.type->type != BasicType::BOOLEAN) 
						  	{
          			  	    	yyerror("and 运算符两侧必须为布尔类型", @$.first_line);
          			  	    	yyerrok;
          			  	  	}
							else 
							{
          			  	    	$$.targetCode = new string(*($1.targetCode) + "&&" + *($3.targetCode));
          			  	    	$$.type = new Type();
          			  	    	$$.type->type = BasicType::BOOLEAN;
          			  	  	}
          			  	} 
						else if (*($2) == "div") 
						{
          			  	  	if ($1.type->type != BasicType::INTEGER || $3.type->type != BasicType::INTEGER) 
							{
          			  	    	yyerror("div 运算符两侧类型必须为整数", @$.first_line);
          			  	    	yyerrok;
          			  	  	} 
							else 
							{
          			  	    	$$.targetCode = new string(*($1.targetCode) + " / " + *($3.targetCode));
          			  	    	$$.type = new Type();
          			  	    	$$.type->type = BasicType::INTEGER;
          			  	  	}
          			  	} 
						else if ( *($2) == "mod") 
						{
          			  	  	if ($1.type->type != BasicType::INTEGER || $3.type->type != BasicType::INTEGER) 
							{
          			  	    	yyerror("mod 运算符两侧类型必须为整数", @$.first_line);
          			  	    	yyerrok;
          			  	  	}
							else 
							{
          			  	    	$$.targetCode = new string(*($1.targetCode) + " % " + *($3.targetCode));
          			  	    	$$.type = new Type();
          			  	    	$$.type->type = BasicType::INTEGER;
          			  	  	}
          			  	} 
						else 
						{
          			    	if (($1.type->type == BasicType::INTEGER || $1.type->type == BasicType::REAL)
          			    	&& ($3.type->type == BasicType::INTEGER || $3.type->type == BasicType::REAL)) 
							{
          			    		$$.type = new Type();
          			    	  	if ($1.type->type == BasicType::REAL || $3.type->type == BasicType::REAL) 
								{
          			    	    	$$.type->type = BasicType::REAL;
          			    	  	} 
								else 
								{
          			    	    	$$.type->type = BasicType::INTEGER;
          			    	  	}
          			    	  	$$.targetCode = new string(*($1.targetCode) + *($2) + *($3.targetCode));
          			    	} 
							else 
							{
          			    	  	yyerror("运算类型不正确", @$.first_line);
          			    	  	yyerrok;
          			    	}
          			  	}
          			}
					debugInfoBreak();
				}
				| factor
				{
					debugInfo("进入产生式 term: factor");
					debugInfo("factor.type = " + $1.type->toString() + ", factor.targetCode = " + *($1.targetCode));
          			$$.type = new Type(*($1.type));
          			$$.targetCode = new string(*($1.targetCode));
					debugInfoBreak();
				};

factor: TOK_ID
				{
					debugInfo("进入产生式 factor: TOK_ID");
					debugInfo("TOK_ID = " + *($1));
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (!symbol) 
					{
          			  	yyerror("标识符 " + *($1) + " 未定义", @$.first_line);
          			  	yyerrok;
          			} 
					else 
					{
          			  	if (symbol->type.isCallable()) 
						{
          			  	  	if (symbol->type.ret_type == BasicType::VOID) 
							{
          			  	  	  	yyerror("标识符 " + *($1) + " 不能是一个void类型的函数或过程", @$.first_line);
          			  	  	  	yyerrok;
          			  	  	} 
							else 
							{
          			  	  	  	if (symbol->type.dimension != 0) 
								{
          			  	  	  		yyerror("函数 " + *($1) + " 不能无参调用, 期待参数个数: " + to_string(symbol->type.dimension), @$.first_line);
          			  	  	  	  	yyerrok;
          			  	  	  	} 
								else 
								{
          			  	  	  	  	$$.type = new Type();
          			  	  	  	  	$$.type->type = symbol->type.ret_type;
          			  	  	  	  	$$.targetCode = new string(*($1) + "()");
          			  	  	  	}
          			  	  	}
          			  	} 
						else 
						{
          			  	  	$$.type = new Type(symbol->type);
          			  	  	$$.targetCode = new string(*($1));
          			  	}
          			}
					debugInfoBreak();
				}
				| TOK_ID '(' expr_list ')'
				{
					debugInfo("进入产生式 factor: TOK_ID '(' expr_list ')'");
					debugInfo("TOK_ID = " + *($1) + ", expr_list.targetCode=" + *($3.targetCode));
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (symbol == nullptr) 
					{
          			  	yyerror("标识符 " + *($1) + " 未定义", @$.first_line);
          			  	yyerrok;
          			} 
					else 
					{
          			  	if (!symbol->type.isCallable()) 
						{
          			  	  	yyerror("对象" + *($1) + "不是一个可以调用的对象, 实际类型为: " + symbol->type.toString(), @$.first_line);
          			  	  	yyerrok;
          			  	} 
						else 
						{
          			  	  	if (symbol->type.ret_type == BasicType::VOID) 
							{
          			  	  	  	yyerror("函数 " + *($1) + " 被调用但是没有返回值", @$.first_line);
          			  	  	  	yyerrok;
          			  	  	} 
							else 
							{
          			  	  	  	if ($3.names->size() != symbol->type.dimension) 
								{
          			  	  	  	  	yyerror("参数个数不匹配, 期望参数个数: " + to_string(symbol->type.dimension) + 
											", 实际参数个数: " + to_string($3.names->size()), @$.first_line);
          			  	  	  	  	yyerrok;
          			  	  	  	} 
								else 
								{
          			  	  	  	  	for (int i = 0; i < $3.types->size(); i++) 
									{
          			  	  	  	  	  	if ((*($3.types))[i].type != symbol->type.args[i].type) 
										{
          			  	  	  	  	  	  	yyerror("第 " + to_string(i) + " 个参数类型不匹配, 期望类型: " + symbol->type.args[i].toString() +
												", 实际传入类型: " + (*($3.types))[i].toString() , @$.first_line);
          			  	  	  	  	  		yyerrok;
										}
          			  	  	  	  	}
          			  	  	  	  	$$.targetCode = new string(*($1) + "(" + *($3.targetCode) + ")");
									$$.type = new Type();
									$$.type->type = symbol->type.ret_type;
          			  	  	  	}
          			  	  	}
          			  	}
          			}
					debugInfoBreak();
				}
				| TOK_ID '[' expression ']'
				{
					if ($3.type->type != BasicType::INTEGER)
					{
						yyerror("数组下标访问必须使用整数", @$.first_line);
						yyerrok;
					}

					if (!sym_table.isInScope(*($1)))
					{
						yyerror(*($1) + " 未定义", @$.first_line);
						yyerrok;
					}
					Symbol *const sym_ptr = sym_table.getSymbol(*($1));
					if (sym_ptr && !sym_ptr->type.isArray())
					{
						yyerror(*($1) + "不是数组类型", @$.first_line);
						yyerrok;
					}

					int lb = sym_ptr->type.periods[0].first;

					$$.type = new Type();
					$$.type->type = sym_ptr->type.type;
					
					string temp_code = *($1) + "[" + *($3.targetCode) + "-" + to_string(lb) + "]";
					$$.targetCode = new string(temp_code);
				}
				| TOK_NUM
				{
					$$.type = new Type();
					$$.targetCode = new string(*($1.targetCode));
					if ($1.isReal)
						$$.type->type = BasicType::INTEGER;
					else
						$$.type->type = BasicType::REAL;
				}
				| '(' expression ')'
				{
					$$.type = new Type(*($2.type));
					$$.targetCode = new string();
					*($$.targetCode) = "(" + *($2.targetCode) + ")";
				}
				| TOK_NOT factor
				{
					if ($2.type->type != BasicType::BOOLEAN)
					{
						yyerror("NOT 后面必须为布尔表达式", @$.first_line);
						yyerrok;
					}
					$$.type = new Type();
					$$.targetCode = new string("!");
					$$.targetCode->append(*($2.targetCode));
					$$.type->type = BasicType::BOOLEAN;
				}
				| TOK_TRUE
				{
					$$.type = new Type();
					$$.targetCode = new string("true");
					$$.type->type = BasicType::BOOLEAN;
				}
				| TOK_FALSE
				{
				 	$$.type = new Type();
					$$.targetCode = new string("false");
					$$.type->type = BasicType::BOOLEAN;
				};

sign: '+'
				{
					$$ = new string("+");
				}
				| '-'
				{
					$$ = new string("-");
				};

%%

string toLower(const string &str)
{
	string res = str;
	for (int i = 0; i < res.size(); i++)
		res[i] = tolower(res[i]);
	return res;
}

void yyerror(const string &err_msg)
{
	cerr << "!ERROR!: " << err_msg << endl;
}

void yyerror(const string &err_msg, int line_no)
{
	cerr << "!ERROR!(" << line_no << "): " << err_msg << endl;
}

int main(void) {
	return yyparse();
}