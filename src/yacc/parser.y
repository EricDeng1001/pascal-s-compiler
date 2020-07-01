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
void syntax_err_suply(const string &err_msg);
string toLower(const string &str);
#define YYERROR_VERBOSE 1
extern int yylineno;


#ifndef NDEBUG
void debugInfo(const string &info) 
{
	cout << "!DEBUG!(" << yylineno << "): " << info << endl;
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

static int total_error_count;
static string final_code;
static int latest_error_lineno;
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
	} expStruct;

	struct
	{
		vector<pair<Type, string>> *vars;
	} varListStruct;
}

%token <targetCode> TOK_PROGRAM TOK_VAR TOK_ARRAY TOK_OF TOK_INTEGER TOK_REAL TOK_BOOLEAN TOK_FUNCTION TOK_PROCEDURE TOK_DO
					TOK_CHAR_LIT TOK_CHAR TOK_FOR TOK_TO TOK_BEGIN TOK_IF TOK_THEN TOK_END TOK_NOT TOK_WHILE TOK_READ TOK_WRITE TOK_ELSE TOK_TRUE TOK_FALSE TOK_CONST

%token <targetCode> TOK_RELOP TOK_ADDOP TOK_MULOP TOK_ASSIGNOP

%token <targetCode>	TOK_ID

%token <targetDigitCode> TOK_NUM const_value

%type <targetCode>  program program_head subprogram_head program_body declarations declaration
					subprogram_declarations subprogram_declaration statement compound_statement
					optional_statements procedure_call_statement statement_list sign 
					var_declarations var_declaration const_declarations const_declaration

%type <idList> identifier_list

%type <exprList> expr_list

%type <typeStruct> type standard_type

%type <expStruct> variable expression simple_expr term factor

%type <varListStruct> variable_list

%type <parameterStruct> parameter_list parameter_lists arguments
%%

program: program_head program_body '.'
				{
					debugInfo("进入产生式 program: program_head program_body '.'"); 
					final_code = *($1) + *($2);
					debugInfoBreak();
				}
        | program_head program_body error
				{
					debugInfo("进入产生式 program: program_head program_body error"); 
					final_code = *($1) + *($2);
					syntax_err_suply("程序定义末尾遗失 . 符号");
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
						yyerror("program 后的参数列表必须为input, output");
					}
					$$ = new string("#include <iostream>\nusing namespace std;\n"); //填写C++程序首部
					debugInfoBreak();
				}
			  | TOK_PROGRAM TOK_ID '(' identifier_list ')' error
			  	{
					debugInfo("进入产生式 program_head: TOK_PROGRAM TOK_ID '(' identifier_list ')' error");
					debugInfo("TOK_PROGRAM = " + *($1) + ", TOK_ID = " + *($2));
					const auto &names = *($4.names);
					syntax_err_suply("program 定义末尾缺少分号");
					yyerrok;
					if (names.size() != 2 || (names.size() == 2 && (toLower(names[0]) != "input" || toLower(names[1]) != "output")))
					{
						yyerror("program 后的参数列表必须为input, output");
					}	
					$$ = new string("#include <iostream>\nusing namespace std;\n"); //填写C++程序首部
			  	}
			  | TOK_PROGRAM TOK_ID error identifier_list error ';'
			  	{
					debugInfo("进入产生式 program_head: TOK_PROGRAM TOK_ID error identifier_list ')' ';'");
					debugInfo("TOK_PROGRAM = " + *($1) + ", TOK_ID = " + *($2));
					const auto &names = *($4.names);
					syntax_err_suply("program 定义中标识符列表缺少括号包围");
					yyerrok;
					if (names.size() != 2 || (names.size() == 2 && (toLower(names[0]) != "input" || toLower(names[1]) != "output")))
						yyerror("program 后的参数列表必须为input, output");
					$$ = new string("#include <iostream>\nusing namespace std;\n"); //填写C++程序首部
			  	}
			  | TOK_PROGRAM TOK_ID ';'
			  	{
					debugInfo("进入产生式 TOK_PROGRAM TOK_ID ';'");
					debugInfo("TOK_PROGRAM = " + *($1) + ", TOK_ID = " + *($2));
					$$ = new string("#include <iostream>\nusing namespace std;\n"); //填写C++程序首部
			  		debugInfoBreak();
				};
			  | TOK_PROGRAM TOK_ID error
			  	{
					debugInfo("进入产生式 TOK_PROGRAM TOK_ID error");
					debugInfo("TOK_PROGRAM = " + *($1) + ", TOK_ID = " + *($2));
					$$ = new string("#include <iostream>\nusing namespace std;\n"); //填写C++程序首部
					syntax_err_suply("program 定义末尾缺少分号");
					yyerrok;
			  		debugInfoBreak();
			  	}

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
				| identifier_list error TOK_ID
				{
					debugInfo("进入产生式 identifier_list: identifier_list error TOK_ID");
					debugInfo("TOK_ID = " + *($3));
					// 记录已经录入的参数
					$$.names = new vector<string>(*($1.names));
					// 记录新的id
					($$.names)->push_back(*($3));
					syntax_err_suply("标识符间缺少逗号分隔");
					yyerrok;
					debugInfoBreak();
				}
				| identifier_list ',' error
				{
					debugInfo("进入产生式 identifier_list ',' error");
					syntax_err_suply("标识符列表里的逗号分隔符后应该接标识符");
					yyerrok;
					$$.names = new vector<string>(*($1.names));
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

declarations: var_declarations const_declarations
				{
					debugInfo("进入产生式 declarations: var_declarations const_declarations");
					$$ = new string(*($1) + *($2));
					debugInfoBreak();
				};

var_declarations: TOK_VAR var_declaration ';'
				{
					debugInfo("进入产生式 var_declarations: TOK_VAR var_declaration ';'");
					$$ = new string(*($2));
					debugInfoBreak();
				}
			    | TOK_VAR var_declaration error
				{
					debugInfo("进入产生式 var_declarations: TOK_VAR var_declaration error");
					syntax_err_suply("变量声明末尾缺少分号");
					yyerrok;
					$$ = new string(*($2));
					debugInfoBreak();
				}
				| error var_declaration ';'
				{
					// WARNING: CAUSES SR CONFLICT
					debugInfo("进入产生式 var_declarations: TOK_VAR var_declaration ';'");
					syntax_err_suply("声明前缺少 VAR");
					yyerrok;
					$$ = new string(*($2));
					debugInfoBreak();
				}
				|
				{
					debugInfo("进入产生式 var_declarations: ");
					$$ = new string("");
					debugInfoBreak();
				};

var_declaration: var_declaration ';' identifier_list ':' type
				{
					debugInfo("进入产生式 var_declaration: var_declaration ';' identifier_list ':' type");
					debugInfo("type = " + *($5.targetCode));
					//使用dimension来判断是否为数组
					if(($5.type)->dimension == 0) 
					{
						string tmp_target = *($5.targetCode);
						for(int i = 0; i < ($3.names)->size(); i++)
						{
							Symbol sym((*($3.names))[i], *($5.type));
							if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									if(i != ($3.names)->size() - 1)
										tmp_target += " " + (*($3.names))[i] + ",";
									else
										tmp_target += " " + (*($3.names))[i] + ";\n";
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									if(i != ($3.names)->size() - 1)
										tmp_target += " " + (*($3.names))[i] + ",";
									else
										tmp_target += " " + (*($3.names))[i] + ";\n";
								}
							}
						}
						$$ = new string(*($1) + tmp_target);
					}
					else if(($5.type)->dimension > 0)
					{
						string tmp_target = *($5.targetCode);
						for(int i = 0; i < ($3.names)->size(); i++) 
						{
							Symbol sym((*($3.names))[i], *($5.type));
							if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									string target = to_string($5.arrayTop - $5.arrayBottom + 1);
									if(i != ($3.names)->size() - 1)
										tmp_target += " " + (*($3.names))[i] + "[" + target + "],";
									else
										tmp_target += " " + (*($3.names))[i] + "[" + target + "];\n";
								}
							}
							else
							{
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								debugInfo("插入符号 " + sym.toString());
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
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
						}
						$$ = new string(*($1) + tmp_target);
					}
					debugInfoBreak();
				}
				| var_declaration error identifier_list ':' type
				{
					debugInfo("进入产生式 var_declaration: var_declaration error identifier_list ':' type");
					debugInfo("type = " + *($5.targetCode));
					syntax_err_suply("变量声明间使用分号隔开");
					yyerrok;

					//使用dimension来判断是否为数组
					if(($5.type)->dimension == 0) 
					{
						string tmp_target = *($5.targetCode);
						for(int i = 0; i < ($3.names)->size(); i++)
						{
							Symbol sym((*($3.names))[i], *($5.type));
							if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									if(i != ($3.names)->size() - 1)
										tmp_target += " " + (*($3.names))[i] + ",";
									else
										tmp_target += " " + (*($3.names))[i] + ";\n";
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									if(i != ($3.names)->size() - 1)
										tmp_target += " " + (*($3.names))[i] + ",";
									else
										tmp_target += " " + (*($3.names))[i] + ";\n";
								}
							}
						}
						$$ = new string(*($1) + tmp_target);
					}
					else if(($5.type)->dimension > 0)
					{
						string tmp_target = *($5.targetCode);
						for(int i = 0; i < ($3.names)->size(); i++) 
						{
							Symbol sym((*($3.names))[i], *($5.type));
							if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									string target = to_string($5.arrayTop - $5.arrayBottom + 1);
									if(i != ($3.names)->size() - 1)
										tmp_target += " " + (*($3.names))[i] + "[" + target + "],";
									else
										tmp_target += " " + (*($3.names))[i] + "[" + target + "];\n";
								}
							}
							else
							{
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								debugInfo("插入符号 " + sym.toString());
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
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
						}
						$$ = new string(*($1) + tmp_target);
					}
					debugInfoBreak();
				}
				| var_declaration ';' identifier_list error type
				{
					debugInfo("进入产生式 var_declaration: var_declaration error identifier_list ':' type");
					debugInfo("type = " + *($5.targetCode));
					syntax_err_suply("变量声明的类型前缺少冒号");
					yyerrok;
					//使用dimension来判断是否为数组
					if(($5.type)->dimension == 0) 
					{
						string tmp_target = *($5.targetCode);
						for(int i = 0; i < ($3.names)->size(); i++)
						{
							Symbol sym((*($3.names))[i], *($5.type));
							if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									if(i != ($3.names)->size() - 1)
										tmp_target += " " + (*($3.names))[i] + ",";
									else
										tmp_target += " " + (*($3.names))[i] + ";\n";
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									if(i != ($3.names)->size() - 1)
										tmp_target += " " + (*($3.names))[i] + ",";
									else
										tmp_target += " " + (*($3.names))[i] + ";\n";
								}
							}
						}
						$$ = new string(*($1) + tmp_target);
					}
					else if(($5.type)->dimension > 0)
					{
						string tmp_target = *($5.targetCode);
						for(int i = 0; i < ($3.names)->size(); i++) 
						{
							Symbol sym((*($3.names))[i], *($5.type));
							if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									string target = to_string($5.arrayTop - $5.arrayBottom + 1);
									if(i != ($3.names)->size() - 1)
										tmp_target += " " + (*($3.names))[i] + "[" + target + "],";
									else
										tmp_target += " " + (*($3.names))[i] + "[" + target + "];\n";
								}
							}
							else
							{
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								debugInfo("插入符号 " + sym.toString());
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
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
						}
						$$ = new string(*($1) + tmp_target);
					}
					debugInfoBreak();
				}
				| identifier_list ':' type
				{
					debugInfo("进入产生式 var_declaration: identifier_list ':' type");
					debugInfo("type = " + $3.type->toString());
					//使用dimension来判断是否为数组
					string tmp_target = *($3.targetCode);
					if(($3.type)->dimension == 0) 
					{
						for(int i = 0; i < ($1.names)->size(); i++) 
						{
							Symbol sym((*($1.names))[i], *($3.type));
							// 插入到符号表
							if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									if(i != ($1.names)->size() - 1)
										tmp_target += " " + (*($1.names))[i] + ",";
									else
										tmp_target += " " + (*($1.names))[i] + ";\n";
								}
							}
							else
							{
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									if(i != ($1.names)->size() - 1)
										tmp_target += " " + (*($1.names))[i] + ",";
									else
										tmp_target += " " + (*($1.names))[i] + ";\n";
								}
							}
						}
					}
					else if(($3.type)->dimension > 0)
					{
						for(int i = 0; i < ($1.names)->size(); i++) 
						{
							Symbol sym((*($1.names))[i], *($3.type));
							if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									string target = to_string($3.arrayTop - $3.arrayBottom  + 1);
									if(i != ($1.names)->size() - 1)
										tmp_target += " " + (*($1.names))[i] + "[" + target + "],";
									else
										tmp_target += " " + (*($1.names))[i] + "[" + target + "];\n";
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
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
						}
					}
					$$ = new string(tmp_target);
					debugInfoBreak();
				}
				| identifier_list error type
				{
					debugInfo("进入产生式 var_declaration: identifier_list ':' type");
					debugInfo("type = " + $3.type->toString());
					syntax_err_suply("变量声明的类型前缺少冒号");
					yyerrok;
					//使用dimension来判断是否为数组
					string tmp_target = *($3.targetCode);
					if(($3.type)->dimension == 0) 
					{
						for(int i = 0; i < ($1.names)->size(); i++) 
						{
							Symbol sym((*($1.names))[i], *($3.type));
							// 插入到符号表
							if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									if(i != ($1.names)->size() - 1)
										tmp_target += " " + (*($1.names))[i] + ",";
									else
										tmp_target += " " + (*($1.names))[i] + ";\n";
								}
							}
							else
							{
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									if(i != ($1.names)->size() - 1)
										tmp_target += " " + (*($1.names))[i] + ",";
									else
										tmp_target += " " + (*($1.names))[i] + ";\n";
								}
							}
						}
					}
					else if(($3.type)->dimension > 0)
					{
						for(int i = 0; i < ($1.names)->size(); i++) 
						{
							Symbol sym((*($1.names))[i], *($3.type));
							if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									string target = to_string($3.arrayTop - $3.arrayBottom  + 1);
									if(i != ($1.names)->size() - 1)
										tmp_target += " " + (*($1.names))[i] + "[" + target + "],";
									else
										tmp_target += " " + (*($1.names))[i] + "[" + target + "];\n";
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
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
						}
					}
					$$ = new string(tmp_target);
					debugInfoBreak();
				};

const_declarations: TOK_CONST const_declaration ';'
				{
					debugInfo("进入产生式 const_declarations: TOK_CONST const_declaration ';'");
					$$ = new string(*($2));
					debugInfoBreak();
				}
			    | TOK_CONST const_declaration error
				{
					debugInfo("进入产生式 const_declarations: TOK_CONST const_declaration error");
					syntax_err_suply("变量声明末尾缺少分号");
					yyerrok;
					$$ = new string(*($2));
					debugInfoBreak();
				}
				| error const_declaration ';'
				{
					// WARNING: CAUSES SR CONFLICT
					debugInfo("进入产生式 const__declarations: TOK_CONST const_declaration ';'");
					syntax_err_suply("声明前缺少 CONST");
					yyerrok;
					$$ = new string(*($2));
					debugInfoBreak();
				}
				|
				{
					debugInfo("进入产生式 const_declarations: ");
					$$ = new string("");
					debugInfoBreak();
				};

const_declaration: const_declaration ';' ID '=' const_value
				{
					debugInfo("进入产生式 const_declaration: const_declaration ; ID = const_value");
					string tmp_target = *($1.targetCode);
					Type t{};
					if($5.isReal)
					{
						t.type = BasicType::REAL;
						t.is_constant = true;
						Symbol sym(*($3.names), t);
						if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									tmp_target = tmp_target + 
												"const double " + sym.name + " = " + *($5.targetCode) + ';';
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									tmp_target = tmp_target + 
												"const double " + sym.name + " = " + *($5.targetCode) + ';';
								}
							}
					}else
					{
						t.type = BasicType::INTEGER;
						t.is_constant = true;
						Symbol sym(*($3.names), t);
						if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									tmp_target = tmp_target + 
												"const int " + sym.name + " = " + *($5.targetCode) + ';';
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									tmp_target = tmp_target + 
												"const int " + sym.name + " = " + *($5.targetCode) + ';';
								}
							}
					}
					$$.targetCode = new string(tmp_target);
					debugInfoBreak();
				}
				| const_declaration error ID '=' const_value
				{
					debugInfo("进入产生式 const_declaration: const_declaration error ID = const_value");
					syntax_err_suply("两个常量定义语句间缺少分号");
					string tmp_target = *($1.targetCode);
					Type t{};
					if($5.isReal)
					{
						t.type = BasicType::REAL;
						t.is_constant = true;
						Symbol sym(*($3.names), t);
						if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									tmp_target = tmp_target + 
												"const double " + sym.name + " = " + *($5.targetCode) + ';';
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									tmp_target = tmp_target + 
												"const double " + sym.name + " = " + *($5.targetCode) + ';';
								}
							}
					}else
					{
						t.type = BasicType::INTEGER;
						t.is_constant = true;
						Symbol sym(*($3.names), t);
						if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									tmp_target = tmp_target + 
												"const int " + sym.name + " = " + *($5.targetCode) + ';';
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									tmp_target = tmp_target + 
												"const int " + sym.name + " = " + *($5.targetCode) + ';';
								}
							}
					}
					$$.targetCode = new string(tmp_target);
					debugInfoBreak();
				}
				| const_declaration ';' ID error const_value
				{
					debugInfo("进入产生式 const_declaration: const_declaration ; ID error const_value");
					syntax_err_suply("常量定义语句中缺少等号");
					string tmp_target = *($1.targetCode);
					Type t{};
					if($5.isReal)
					{
						t.type = BasicType::REAL;
						t.is_constant = true;
						Symbol sym(*($3.names), t);
						if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									tmp_target = tmp_target + 
												"const double " + sym.name + " = " + *($5.targetCode) + ';';
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									tmp_target = tmp_target + 
												"const double " + sym.name + " = " + *($5.targetCode) + ';';
								}
							}
					}else
					{
						t.type = BasicType::INTEGER;
						t.is_constant = true;
						Symbol sym(*($3.names), t);
						if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									tmp_target = tmp_target + 
												"const int " + sym.name + " = " + *($5.targetCode) + ';';
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									tmp_target = tmp_target + 
												"const int " + sym.name + " = " + *($5.targetCode) + ';';
								}
							}
					}
					$$.targetCode = new string(tmp_target);
					debugInfoBreak();
				}
				| ID '=' const_value
				{
					debugInfo("进入产生式 const_declaration: ID = const_value");
					string tmp_target;
					Type t{};
					if($3.isReal)
					{
						t.type = BasicType::REAL;
						t.is_constant = true;
						Symbol sym(*($1.names), t);
						if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									tmp_target = "const double " + sym.name + " = " + *($3.targetCode) + ';';
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									tmp_target = "const double " + sym.name + " = " + *($3.targetCode) + ';';
								}
							}
					}else
					{
						t.type = BasicType::INTEGER;
						t.is_constant = true;
						Symbol sym(*($1.names), t);
						if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									tmp_target = "const int " + sym.name + " = " + *($3.targetCode) + ';';
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									tmp_target = "const int " + sym.name + " = " + *($3.targetCode) + ';';
								}
							}
					}
					$$.targetCode = new string(tmp_target);
					debugInfoBreak();
				}
				| ID error const_value
				{
					debugInfo("进入产生式 const_declaration: ID error const_value");
					syntax_err_suply("常量定义语句中缺少等号");
					string tmp_target;
					Type t{};
					if($3.isReal)
					{
						t.type = BasicType::REAL;
						t.is_constant = true;
						Symbol sym(*($1.names), t);
						if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									tmp_target = "const double " + sym.name + " = " + *($3.targetCode) + ';';
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									tmp_target = "const double " + sym.name + " = " + *($3.targetCode) + ';';
								}
							}
					}else
					{
						t.type = BasicType::INTEGER;
						t.is_constant = true;
						Symbol sym(*($1.names), t);
						if (!sym_table.isInGlobalScope())
							{
								const Symbol *const parent = sym_table.getParentSymbol();
								if (parent->name == sym.name || sym_table.isInScope(sym.name))
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else
								{
									sym_table.InsertSymbol(sym);
									tmp_target = "const int " + sym.name + " = " + *($3.targetCode) + ';';
								}
							}
							else
							{
								// 插入到符号表
								debugInfo("插入符号 " + sym.toString());
								pair<bool, int> res = sym_table.InsertSymbol(sym);
								if(res.first == false) 
								{
									yyerror("符号 " + sym.name + " 重复定义");
								}
								else 
								{	// 生成目标代码
									tmp_target = "const int " + sym.name + " = " + *($3.targetCode) + ';';
								}
							}
					}
					$$.targetCode = new string(tmp_target);
					debugInfoBreak();
				};

const_value: '+' TOK_NUM
				{
					$$.targetCode = new string('+' + *($2.targetCode));
					$$.isReal = $2.isReal;
				}
				| '-' TOK_NUM
				{
					$$.targetCode = new string('-' + *($2.targetCode));
					$$.isReal = $2.isReal;
				}
				| TOK_NUM
				{
					$$.targetCode = new string(*($1.targetCode));
					$$.isReal = $1.isReal;
				};

type: standard_type
				{
					debugInfo("进入产生式 type: standard_type");
					debugInfo("standard_type = " + *($1.targetCode));
					$$.type = new Type(*($1.type));
					$$.targetCode = new string(*($1.targetCode));
					debugInfoBreak();
				}
				| error
				{
					debugInfo("进入产生式 standard_type: error");
					$$.type = new Type();
					$$.type->type = BasicType::INVALID;
					$$.targetCode = new string("invalid");
					syntax_err_suply("无效的基本类型");
					debugInfoBreak();
				}
				| TOK_ARRAY '[' TOK_NUM '.' '.' TOK_NUM ']' TOK_OF standard_type
				{
					debugInfo("进入产生式 type: TOK_ARRAY '[' TOK_NUM '.' '.' TOK_NUM ']' TOK_OF standard_type");
					debugInfo("TOK_NUM1 = " + *($3.targetCode) + ", TOK_NUM2 = " + *($6.targetCode) + 
						      ", standard_type = " + *($9.targetCode));
					if($3.isReal || $6.isReal) 
					{
						yyerror("数组参数NUM类型不为整型");
					}
					$$.type = new Type(*($9.type));
					$$.arrayTop = (int)(atoi($6.targetCode->c_str()));
					$$.arrayBottom = (int)(atoi($3.targetCode->c_str()));
					$$.type->dimension = 1;
					$$.type->periods.push_back({$$.arrayBottom, $$.arrayTop});
					if ($$.arrayTop - $$.arrayBottom < 0) 
					{
						yyerror("数组下界小于上界");
					}
					$$.targetCode = new string(*($9.targetCode));
					debugInfoBreak();
				}
				| TOK_ARRAY error TOK_NUM '.' '.' TOK_NUM error TOK_OF standard_type
				{
					debugInfo("进入产生式 type: TOK_ARRAY '[' TOK_NUM '.' '.' TOK_NUM ']' TOK_OF standard_type");
					debugInfo("TOK_NUM1 = " + *($3.targetCode) + ", TOK_NUM2 = " + *($6.targetCode) + 
						      ", standard_type = " + *($9.targetCode));
					syntax_err_suply("数组声明缺少中括号包围");
					if ($3.isReal || $6.isReal) 
					{
						yyerror("数组参数NUM类型不为整型");
					}
					$$.type = new Type(*($9.type));
					$$.arrayTop = (int)(atoi($6.targetCode->c_str()));
					$$.arrayBottom = (int)(atoi($3.targetCode->c_str()));
					$$.type->dimension = 1;
					$$.type->periods.push_back({$$.arrayBottom, $$.arrayTop});
					if($$.arrayTop - $$.arrayBottom < 0) 
					{
						yyerror("数组下界小于上界");
					}
					$$.targetCode = new string(*($9.targetCode));
					debugInfoBreak();
				}
				| TOK_ARRAY '[' TOK_NUM error TOK_NUM ']' TOK_OF standard_type
				{
					debugInfo("进入产生式 type: TOK_ARRAY '[' TOK_NUM '.' '.' TOK_NUM ']' TOK_OF standard_type");
					debugInfo("TOK_NUM1 = " + *($3.targetCode) + ", TOK_NUM2 = " + *($5.targetCode) + 
						      ", standard_type = " + *($8.targetCode));
					syntax_err_suply("数组声明缺少 ..");
					yyerrok;
					if ($3.isReal || $5.isReal) 
					{
						yyerror("数组参数NUM类型不为整型");
					}
					$$.type = new Type(*($8.type));
					$$.arrayTop = (int)(atoi($5.targetCode->c_str()));
					$$.arrayBottom = (int)(atoi($3.targetCode->c_str()));
					$$.type->dimension = 1;
					$$.type->periods.push_back({$$.arrayBottom, $$.arrayTop});
					if($$.arrayTop - $$.arrayBottom < 0) 
					{
						yyerror("数组下界小于上界");
					}
					$$.targetCode = new string(*($8.targetCode));
					debugInfoBreak();
				}
				| TOK_ARRAY '[' TOK_NUM '.' error TOK_NUM ']' TOK_OF standard_type
				{
					debugInfo("进入产生式 type: TOK_ARRAY '[' TOK_NUM '.' '.' TOK_NUM ']' TOK_OF standard_type");
					debugInfo("TOK_NUM1 = " + *($3.targetCode) + ", TOK_NUM2 = " + *($6.targetCode) + 
						      ", standard_type = " + *($9.targetCode));
					syntax_err_suply("数组声明缺少 ..");
					yyerrok;
					if ($3.isReal || $6.isReal) 
					{
						yyerror("数组参数NUM类型不为整型");
					}
					$$.type = new Type(*($9.type));
					$$.arrayTop = (int)(atoi($6.targetCode->c_str()));
					$$.arrayBottom = (int)(atoi($3.targetCode->c_str()));
					$$.type->dimension = 1;
					$$.type->periods.push_back({$$.arrayBottom, $$.arrayTop});
					if($$.arrayTop - $$.arrayBottom < 0) 
					{
						yyerror("数组下界小于上界");
					}
					$$.targetCode = new string(*($9.targetCode));
					debugInfoBreak();
				}
				| TOK_ARRAY '[' TOK_NUM error '.' TOK_NUM ']' TOK_OF standard_type
				{
					debugInfo("进入产生式 type: TOK_ARRAY '[' TOK_NUM '.' '.' TOK_NUM ']' TOK_OF standard_type");
					debugInfo("TOK_NUM1 = " + *($3.targetCode) + ", TOK_NUM2 = " + *($6.targetCode) + 
						      ", standard_type = " + *($9.targetCode));
					syntax_err_suply("数组声明缺少 ..");
					yyerrok;
					if ($3.isReal || $6.isReal) 
					{
						yyerror("数组参数NUM类型不为整型");
					}
					$$.type = new Type(*($9.type));
					$$.arrayTop = (int)(atoi($6.targetCode->c_str()));
					$$.arrayBottom = (int)(atoi($3.targetCode->c_str()));
					$$.type->dimension = 1;
					$$.type->periods.push_back({$$.arrayBottom, $$.arrayTop});
					if($$.arrayTop - $$.arrayBottom < 0) 
					{
						yyerror("数组下界小于上界");
					}
					$$.targetCode = new string(*($9.targetCode));
					debugInfoBreak();
				}
				;
standard_type: TOK_INTEGER
				{
					debugInfo("进入产生式 standard_type: TOK_INTEGER");
					$$.type = new Type();
					$$.type->type = BasicType::INTEGER;
					$$.targetCode = new string("int");
					debugInfoBreak();
				}
				| TOK_REAL
				{
					debugInfo("进入产生式 standard_type: TOK_REAL");
					$$.type = new Type();
					$$.type->type = BasicType::REAL;
					$$.targetCode = new string("double");
					debugInfoBreak();
				}
				| TOK_BOOLEAN
				{
					debugInfo("进入产生式 standard_type: TOK_BOOLEAN");
					$$.type = new Type();
					$$.type->type = BasicType::BOOLEAN;
					$$.targetCode = new string("bool");
					debugInfoBreak();
				}
				| TOK_CHAR
				{
					debugInfo("进入产生式 standard_type: TOK_CHAR");
					$$.type = new Type();
					$$.type->type = BasicType::CHAR;
					$$.targetCode = new string("char");
					debugInfoBreak();
				};
				

subprogram_declarations: subprogram_declarations subprogram_declaration ';'
				{
					debugInfo("进入产生式 subprogram_declarations: subprogram_declarations subprogram_declaration ';'");
					string temp = *($1) + "\n" + *($2);
					$$ = new string(temp);
					debugInfoBreak();
				}
				| subprogram_declarations subprogram_declaration error
				{
					debugInfo("进入产生式 subprogram_declarations: subprogram_declarations subprogram_declaration error");
					syntax_err_suply("子程序声明后缺少分号");
					yyerrok;
					string temp = *($1) + "\n" + *($2);
					$$ = new string(temp);
					debugInfoBreak();
				}
				|
				{
					debugInfo("进入产生式 subprogram_declarations: ");
					$$ = new string("");
					debugInfoBreak();
				};

subprogram_declaration: subprogram_head declarations compound_statement
				{
					debugInfo("进入产生式 subprogram_declaration: subprogram_head declarations compound_statement");
					string temp = *($1) + "{\n" +
								  *($2) + "\n" +
								  *($3) + "\n}\n";
					$$ = new string(temp);
					if (!sym_table.ExitScope())
					{
						// TODO 错误处理, 退出作用域失败TODO
					}
					debugInfo("退出作用域");
					debugInfoBreak();
				};

subprogram_head: TOK_FUNCTION TOK_ID arguments ':' standard_type ';'
				{
					debugInfo("进入产生式 subprogram_head: TOK_FUNCTION TOK_ID arguments ':' standard_type ';'");
					debugInfo("TOK_ID = " + *($2) + ", arguments = " + *($3.targetCode) + ", ret_type = " + *($5.targetCode));
					// 检查函数名是否重复
					if (sym_table.getSymbol(*($2)))
					{
						yyerror("重复的标识符 " + *($2));
					}
					else
					{
						SymbolBuilder func_builder = Symbol::getSymbolBuilder();
						func_builder.addName(*($2))
									.setBasicType(BasicType::CALLABLE)
							   		.setRetType($5.type->type)
									.setDefAt(@$.first_line);

						int dimension = 0;
						for (const auto &[type, names] : *($3.paraTypeAndNames))
						{
							for (int i = 0; i < names.size(); i++)
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
									yyerror("重复的标识符 " + name);
								}
								else
								{
									auto temp_builder = params_builder;
									temp_builder.addName(name);
									sym_table.InsertSymbol(temp_builder.Build());
									debugInfo("插入参数符号 " + temp_builder.Build().toString());
								}
							}
						}
					}

					string temp_code = *($5.targetCode) + " " + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| TOK_FUNCTION TOK_ID arguments ':' standard_type error
				{
					debugInfo("进入产生式 subprogram_head: TOK_FUNCTION TOK_ID arguments ':' standard_type ';'");
					debugInfo("TOK_ID = " + *($2) + ", arguments = " + *($3.targetCode) + ", ret_type = " + *($5.targetCode));
					// 检查函数名是否重复
					syntax_err_suply("函数声明末尾缺少分号");
					yyerrok;
					if (sym_table.getSymbol(*($2)))
					{
						yyerror("重复的标识符 " + *($2));
					}
					else
					{
						SymbolBuilder func_builder = Symbol::getSymbolBuilder();
						func_builder.addName(*($2))
									.setBasicType(BasicType::CALLABLE)
							   		.setRetType($5.type->type)
									.setDefAt(@$.first_line);

						int dimension = 0;
						for (const auto &[type, names] : *($3.paraTypeAndNames))
						{
							for (int i = 0; i < names.size(); i++)
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
									yyerror("重复的标识符 " + name);
								}
								else
								{
									auto temp_builder = params_builder;
									temp_builder.addName(name);
									sym_table.InsertSymbol(temp_builder.Build());
									debugInfo("插入参数符号 " + temp_builder.Build().toString());
								}
							}
						}
					}

					string temp_code = *($5.targetCode) + " " + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| TOK_FUNCTION TOK_ID arguments error standard_type ';'
				{
					debugInfo("进入产生式 subprogram_head: TOK_FUNCTION TOK_ID arguments ':' standard_type ';'");
					debugInfo("TOK_ID = " + *($2) + ", arguments = " + *($3.targetCode) + ", ret_type = " + *($5.targetCode));
					// 检查函数名是否重复
					syntax_err_suply("函数声明中参数列表和返回类型间缺少冒号分隔");
					yyerrok;
					if (sym_table.getSymbol(*($2)))
					{
						yyerror("重复的标识符 " + *($2));
					}
					else
					{
						SymbolBuilder func_builder = Symbol::getSymbolBuilder();
						func_builder.addName(*($2))
									.setBasicType(BasicType::CALLABLE)
							   		.setRetType($5.type->type)
									.setDefAt(@$.first_line);

						int dimension = 0;
						for (const auto &[type, names] : *($3.paraTypeAndNames))
						{
							for (int i = 0; i < names.size(); i++)
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
									yyerror("重复的标识符 " + name);
								}
								else
								{
									auto temp_builder = params_builder;
									temp_builder.addName(name);
									sym_table.InsertSymbol(temp_builder.Build());
									debugInfo("插入参数符号 " + temp_builder.Build().toString());
								}
							}
						}
					}

					string temp_code = *($5.targetCode) + " " + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| TOK_FUNCTION TOK_ID arguments error ';'
				{
					debugInfo("进入产生式 subprogram_head: TOK_FUNCTION TOK_ID arguments ':' standard_type ';'");
					debugInfo("TOK_ID = " + *($2) + ", arguments = " + *($3.targetCode) + ", ret_type = void");
					// 检查函数名是否重复
					syntax_err_suply("函数声明缺少返回类型");
					yyerrok;
					if (sym_table.getSymbol(*($2)))
					{
						yyerror("重复的标识符 " + *($2));
					}
					else
					{
						SymbolBuilder func_builder = Symbol::getSymbolBuilder();
						func_builder.addName(*($2))
									.setBasicType(BasicType::CALLABLE)
									.setDefAt(@$.first_line);

						int dimension = 0;
						for (const auto &[type, names] : *($3.paraTypeAndNames))
						{
							for (int i = 0; i < names.size(); i++)
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
									yyerror("重复的标识符 " + name);
								}
								else
								{
									auto temp_builder = params_builder;
									temp_builder.addName(name);
									sym_table.InsertSymbol(temp_builder.Build());
									debugInfo("插入参数符号 " + temp_builder.Build().toString());
								}
							}
						}
					}

					string temp_code = "void " + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| TOK_FUNCTION error arguments standard_type ';'
				{
					debugInfo("进入产生式 subprogram_head: TOK_FUNCTION TOK_ID arguments ':' standard_type ';'");
					debugInfo(string("TOK_ID = ?") + ", arguments = " + *($3.targetCode) + ", ret_type = void");
					// 检查函数名是否重复
					syntax_err_suply("函数声明缺少标识符");
					yyerrok;
					$$ = new string("");
					debugInfoBreak();
				}
				| TOK_FUNCTION TOK_ID arguments error
				{
					yyerror("函数 " + *($2) + " 没有返回值");
					yyerrok;
					string temp_code = string("void ") + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
				}
				| TOK_PROCEDURE TOK_ID arguments ';'
				{
					debugInfo("进入产生式 subprogram_head: TOK_PROCEDURE TOK_ID arguments ';'");
					debugInfo("TOK_ID = " + *($2) + ", arguments = " + *($3.targetCode));
					// 检查函数名是否重复
					if (sym_table.getSymbol(*($2)))
					{
						yyerror("重复的标识符 " + *($2));
						yyerrok;
					}
					else 
					{
						SymbolBuilder func_builder = Symbol::getSymbolBuilder();
						func_builder.addName(*($2))
									.setBasicType(BasicType::CALLABLE)
									.setDefAt(@$.first_line);

						int dimension = 0;
						for (const auto &[type, names] : *($3.paraTypeAndNames))
						{
							for (int i = 0; i < names.size(); i++)
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
									yyerror("重复的标识符 " + name);
									yyerrok;
								}
								else
								{
									auto temp_builder = params_builder;
									temp_builder.addName(name);
									sym_table.InsertSymbol(temp_builder.Build());
									debugInfo("插入参数符号 " + temp_builder.Build().toString());
								}
							}
						}
					}
					
					string temp_code = "void " + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| TOK_PROCEDURE TOK_ID arguments error
				{
					debugInfo("进入产生式 subprogram_head: TOK_PROCEDURE TOK_ID arguments ';'");
					debugInfo("TOK_ID = " + *($2) + ", arguments = " + *($3.targetCode));
					// 检查函数名是否重复
					syntax_err_suply("过程体声明末尾缺少分号");
					yyerrok;
					if (sym_table.getSymbol(*($2)))
					{
						yyerror("重复的标识符 " + *($2));
					}
					else 
					{
						SymbolBuilder func_builder = Symbol::getSymbolBuilder();
						func_builder.addName(*($2))
									.setBasicType(BasicType::CALLABLE)
									.setDefAt(@$.first_line);

						int dimension = 0;
						for (const auto &[type, names] : *($3.paraTypeAndNames))
						{
							for (int i = 0; i < names.size(); i++)
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
									yyerror("重复的标识符 " + name);
								}
								else
								{
									auto temp_builder = params_builder;
									temp_builder.addName(name);
									sym_table.InsertSymbol(temp_builder.Build());
									debugInfo("插入参数符号 " + temp_builder.Build().toString());
								}
							}
						}
					}
					
					string temp_code = "void " + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| TOK_PROCEDURE TOK_ID arguments error ';'
				{
					yyerror("过程 " + *($2) + " 不能有返回值");
					yyerrok;
					string temp_code = string("void ") + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
				}
				| TOK_PROCEDURE error arguments ';'
				{
					syntax_err_suply("过程缺少标识符");
					yyerrok;
					$$ = new string("");
				};


arguments: '(' parameter_lists ')'
				{
					debugInfo("进入产生式 arguments: '(' parameter_lists ')'");
					$$.paraTypeAndNames =
						new vector<pair<Type, vector<string>>>(*($2.paraTypeAndNames));
					$$.targetCode = new string("(");
					$$.targetCode->append(*($2.targetCode))
								 .append(")");
					debugInfoBreak();
				}
				|
				{
					debugInfo("进入产生式 arguments: ");
					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>();
					$$.targetCode = new string("()");
					debugInfoBreak();
				};

parameter_lists: parameter_lists ';' parameter_list
				{
					debugInfo("进入产生式 parameter_lists: parameter_lists ';' parameter_list");
					$$.targetCode = new string(*($1.targetCode));
					$$.targetCode->push_back(','); // 分隔两个参数列表
					$$.targetCode->append(*($3.targetCode));
					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>(*($1.paraTypeAndNames));
					$$.paraTypeAndNames->push_back($3.paraTypeAndNames->front());
					debugInfoBreak();
				}
				| parameter_lists error parameter_list
				{
					debugInfo("进入产生式 parameter_lists: parameter_lists ';' parameter_list");
					syntax_err_suply("参数列表间缺少分号分隔");
					yyerrok;
					$$.targetCode = new string(*($1.targetCode));
					$$.targetCode->push_back(','); // 分隔两个参数列表
					$$.targetCode->append(*($3.targetCode));
					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>(*($1.paraTypeAndNames));
					$$.paraTypeAndNames->push_back($3.paraTypeAndNames->front());
					debugInfoBreak();
				}
				| parameter_list
				{
					debugInfo("进入产生式 parameter_lists: parameter_list");
					$$.targetCode = new string(*($1.targetCode));
					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>(*($1.paraTypeAndNames));
					debugInfoBreak();
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
				| TOK_VAR identifier_list error type
				{
					syntax_err_suply("参数列表中标识符和类型间缺少冒号");
					yyerrok;
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
				}
				| identifier_list error type
				{
					syntax_err_suply("参数列表中标识符和类型间缺少冒号");
					yyerrok;
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
				}
				| error optional_statements TOK_END
				{
					syntax_err_suply("复合语句缺少 BEGIN");
					yyerrok;
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
				| statement_list error statement
				{
					syntax_err_suply("语句后缺少分号");
					yyerrok;
					$$ = new string(*($1));
					$$->append(*($3) + "\n");
				}
				| statement_list ';' statement error
				{
					// WARNING: CAUSES SR CONFLICT
					syntax_err_suply("最后一条语句后有分号");
					yyerrok;
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
						yyerror("赋值语句两边的类型不相等");
					}
					else if ($1.type->isArray())
					{
						yyerror("赋值语句不直接应用于数组");
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
						yyerror("if 后的表达式必须为布尔表达式");
						yyerrok;
					}

					string temp_code;
					temp_code.append(string("if (") + *($2.targetCode) + ") ")
							 .append("{\n")
							 .append(*($4))
							 .append("\n}\n");
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| TOK_IF expression error statement
				{
					debugInfo("进入产生式 statement: TOK_IF expression TOK_THEN statement");
					debugInfo("expression.type=" + $2.type->toString() + ", expression.targetCode=" + *($2.targetCode) +
							  ", statement.targetCode=" + *($4));
					syntax_err_suply("if 语句缺少 then");
					yyerrok;
					Type expr_type = *($2.type);
					if (expr_type.type != BasicType::BOOLEAN)
					{
						yyerror("if 后的表达式必须为布尔表达式");
					}

					string temp_code;
					temp_code.append(string("if (") + *($2.targetCode) + ") ")
							 .append("{\n")
							 .append(*($4))
							 .append("\n}\n");
					$$ = new string(temp_code);
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
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| TOK_WHILE expression TOK_DO statement
				{
					debugInfo("进入产生式 statement: TOK_WHILE expression TOK_DO statement");
					debugInfo("expression.type=" + $2.type->toString() + ", statement=" + *($4));
					Type expr_type = *($2.type);
					if (expr_type.type != BasicType::BOOLEAN)
					{
						yyerror("while 后的表达式必须为布尔表达式");
						yyerrok;
					}

					string temp_code;
					temp_code.append("while (" + *($2.targetCode) + ") ")
							 .append("{\n")
							 .append(*($4) + "\n")
							 .append("}\n");
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| TOK_WHILE expression error statement
				{
					debugInfo("进入产生式 statement: TOK_WHILE expression TOK_DO statement");
					debugInfo("expression.type=" + $2.type->toString() + ", statement=" + *($4));
					syntax_err_suply("while 语句缺少 do");
					yyerrok;
					Type expr_type = *($2.type);
					if (expr_type.type != BasicType::BOOLEAN)
					{
						yyerror("while 后的表达式必须为布尔表达式");
						yyerrok;
					}

					string temp_code;
					temp_code.append("while (" + *($2.targetCode) + ") ")
							 .append("{\n")
							 .append(*($4) + "\n")
							 .append("}\n");
					$$ = new string(temp_code);
					debugInfoBreak();
				}
				| TOK_READ '(' variable_list ')'
				{
					debugInfo("进入产生式 statement: TOK_READ '(' variable_list ')'");
					string temp_code("cin");
					for (const auto &[type, name] : *($3.vars))
						temp_code.append(" >> ")
								 .append(name);
					$$ = new string(temp_code + ";");
					debugInfoBreak();
				}
				| TOK_WRITE '(' expr_list ')'
				{
					debugInfo("进入产生式 statement: TOK_WRITE '(' expr_list ')'");
					debugInfo("expr_list.targetCode=" + *($3.targetCode));
					string temp_code("cout");
					for (int i = 0; i < $3.types->size(); i++)
					{
						if ($3.types->at(i).type == BasicType::VOID)
						{
							yyerror("write 中的表达式的值不能为空");
							break;
						}
					}

					for (const auto &name : *($3.names))
						temp_code.append(" << ")
								 .append(name);
					$$ = new string(temp_code + ";");
					debugInfoBreak();
				}
				| TOK_FOR TOK_ID TOK_ASSIGNOP expression TOK_TO expression TOK_DO statement
				{
					Symbol *id_sym = sym_table.getSymbol(*($2));
					if (!id_sym)
					{
						yyerror("标识符 " + *($2) + " 未定义");
					}
					else if (id_sym->type.type != BasicType::INTEGER)
					{
						yyerror("循环变量" + *($2) + "类型不为整数, 实际类型为: " + id_sym->type.toString());
					}
					else if ($4.type->type != BasicType::INTEGER || $6.type->type != BasicType::INTEGER)
					{
						yyerror("循环界限类型不为整数");
					}

					string temp_code = "for (";
					temp_code.append(*($2) + " = " + *($4.targetCode) + "; ")
							 .append(*($2) + " <= " + *($6.targetCode) + "; ")
							 .append(*($2) + "++)\n")
							 .append("{\n")
							 .append(*($8) + "\n")
							 .append("}\n");
					$$ = new string(temp_code);
				}
				| TOK_FOR TOK_ID TOK_ASSIGNOP expression error expression TOK_DO statement
				{
					syntax_err_suply("for to do 语句缺少 to");
					yyerrok;
					Symbol *id_sym = sym_table.getSymbol(*($2));
					if (!id_sym)
					{
						yyerror("标识符 " + *($2) + " 未定义");
					}
					else if (id_sym->type.type != BasicType::INTEGER)
					{
						yyerror("循环变量" + *($2) + "类型不为整数, 实际类型为: " + id_sym->type.toString());
					}
					else if ($4.type->type != BasicType::INTEGER || $6.type->type != BasicType::INTEGER)
					{
						yyerror("循环界限类型不为整数");
					}

					string temp_code = "for (";
					temp_code.append(*($2) + " = " + *($4.targetCode) + "; ")
							 .append(*($2) + " <= " + *($6.targetCode) + "; ")
							 .append(*($2) + "++)\n")
							 .append("{\n")
							 .append(*($8) + "\n")
							 .append("}\n");
					$$ = new string(temp_code);
				}
				| TOK_FOR TOK_ID TOK_ASSIGNOP expression TOK_TO expression error statement
				{
					syntax_err_suply("for to do 语句缺少 do");
					yyerrok;
					Symbol *id_sym = sym_table.getSymbol(*($2));
					if (!id_sym)
					{
						yyerror("标识符 " + *($2) + " 未定义");
					}
					else if (id_sym->type.type != BasicType::INTEGER)
					{
						yyerror("循环变量" + *($2) + "类型不为整数, 实际类型为: " + id_sym->type.toString());
					}
					else if ($4.type->type != BasicType::INTEGER || $6.type->type != BasicType::INTEGER)
					{
						yyerror("循环界限类型不为整数");
					}

					string temp_code = "for (";
					temp_code.append(*($2) + " = " + *($4.targetCode) + "; ")
							 .append(*($2) + " <= " + *($6.targetCode) + "; ")
							 .append(*($2) + "++)\n")
							 .append("{\n")
							 .append(*($8) + "\n")
							 .append("}\n");
					$$ = new string(temp_code);
				}
				| TOK_FOR TOK_ID error expression TOK_TO expression error statement
				{
					syntax_err_suply("for to do 语句缺少赋值符号");
					yyerrok;
					Symbol *id_sym = sym_table.getSymbol(*($2));
					if (!id_sym)
					{
						yyerror("标识符 " + *($2) + " 未定义");
					}
					else if (id_sym->type.type != BasicType::INTEGER)
					{
						yyerror("循环变量" + *($2) + "类型不为整数, 实际类型为: " + id_sym->type.toString());
					}
					else if ($4.type->type != BasicType::INTEGER || $6.type->type != BasicType::INTEGER)
					{
						yyerror("循环界限类型不为整数");
					}

					string temp_code = "for (";
					temp_code.append(*($2) + " = " + *($4.targetCode) + "; ")
							 .append(*($2) + " <= " + *($6.targetCode) + "; ")
							 .append(*($2) + "++)\n")
							 .append("{\n")
							 .append(*($8) + "\n")
							 .append("}\n");
					$$ = new string(temp_code);
				}
				;

variable_list: variable_list ',' variable
				{
					$$.vars = new vector<pair<Type, string>>(*($1.vars));
					$$.vars->push_back({*($3.type), *($3.targetCode)});
				}
			  | variable_list error variable
				{
					syntax_err_suply("变量列表缺少逗号分隔");
					yyerrok;
					$$.vars = new vector<pair<Type, string>>(*($1.vars));
					$$.vars->push_back({*($3.type), *($3.targetCode)});
				}
			  | variable
			  	{
					$$.vars = new vector<pair<Type, string>>();
					$$.vars->push_back({*($1.type), *($1.targetCode)});
				}

variable: TOK_ID
				{
					debugInfo("进入产生式 variable: TOK_ID");
					debugInfo("TOK_ID=" + *($1));
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (!symbol) 
					{
          				yyerror("标识符 " + *($1) + " 未定义");
          			  	$$.type = new Type();
          			  	$$.type->type = BasicType::INVALID;
          			  	$$.targetCode = new string("");
						yyerrok;
          			} 
					else if (symbol->type.isCallable()) 
					{
          			  	if (*($1) == sym_table.getParentSymbol()->name) 
						{
          			    	if (symbol->type.ret_type == BasicType::VOID) 
							{
          			      		yyerror("函数 " + *($1) + " 没有返回值");
          			      		$$.type = new Type();
          			  			$$.type->type = BasicType::INVALID;
          			  			$$.targetCode = new string("");
								yyerrok;
          			    	} 
							else 
							{
          			      		$$.type = new Type(symbol->type);
								$$.targetCode = new string(*($1));
          			    	}
          			  	} 
						else
						{
          			    	yyerror("函数 " + *($1) + "不应在赋值符号的左侧");
          			      	$$.type = new Type();
          			  		$$.type->type = BasicType::INVALID;
          			  		$$.targetCode = new string("");
							yyerrok;
          			  	}
          			} 
					else if (symbol->type.isArray()) 
					{
          			  	yyerror("不允许对数组进行赋值");
						$$.type = new Type();
          			  	$$.type->type = BasicType::INVALID;
          			  	$$.targetCode = new string("");
          			  	yyerrok;
          			}
          			else 
					{
          			  	$$.type = new Type(symbol->type);
          			  	$$.targetCode = new string(*($1));
          			}
					debugInfoBreak();
				}
				| TOK_ID '[' expression ']'
				{
					debugInfo("进入产生式 variable: TOK_ID '[' expression ']'");
					debugInfo("TOK_ID=" + *($1) + ", expression.type=" + $3.type->toString() +
							  ", expression.targetCode=" + *($3.targetCode));
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (!symbol) 
					{
          			  	yyerror("标识符 " + *($1) + " 未定义");
          			  	$$.type = new Type();
          			  	$$.type->type = BasicType::INVALID;
          			  	$$.targetCode = new string("");
						yyerrok;
          			} 
					else if (!symbol->type.isArray()) 
					{
          			  	yyerror("标识符 " + *($1) + "不为数组类型");
          			  	$$.type = new Type();
          			  	$$.type->type = BasicType::INVALID;
          			  	$$.targetCode = new string("");
						yyerrok;
          			} 
					else 
					{
          			  	if ($3.type->type != BasicType::INTEGER) 
						{
          			    	yyerror("数组下标引用必须是整数");
          			    	$$.type = new Type();
          			  		$$.type->type = BasicType::INVALID;
          			  		$$.targetCode = new string("");
							yyerrok;
          			  	}
						else
						{
          			    	$$.type = new Type();
							$$.type->type = symbol->type.type;
          			    	$$.targetCode = new string(*($1) + "[" +  *($3.targetCode) + "-" + to_string(symbol->type.periods[0].first) + "]");
          			  	}
          			}
					debugInfoBreak();
				};

procedure_call_statement: TOK_ID
				{
					debugInfo("进入产生式 procedure_call_statement: TOK_ID");
					debugInfo("TOK_ID = " + *($1));
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (!symbol) 
					{
          			  	yyerror("标识符 " + *($1) + " 未定义");
          			  	$$ = new string(*($1) + "()");
						yyerrok;
          			} 
					else 
					{
          			  	if (symbol->type.isCallable()) 
						{
          			    	$$ = new string(*($1) + "()");
          			  	} 
						else
						{
          			    	yyerror("对象 " + *($1) + " 不可调用");
          			    	$$ = new string(*($1) + "()");
							yyerrok;
          			  	}
          			}
					debugInfoBreak();
				}
				| TOK_ID '(' expr_list ')'
				{
					debugInfo("进入产生式 procedure_call_statement: TOK_ID '(' expr_list ')'");
					debugInfo("TOK_ID = " + *($1) + ", expr_list = " + *($3.targetCode));
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (!symbol) 
					{
          			  	yyerror("标识符 " + *($1) + " 未定义");
          			  	$$ = new string(*($1) + "(" + *($3.targetCode) + ")");
						yyerrok;
          			} 
					else 
					{
          			  	if (!symbol->type.isCallable()) 
						{
          			    	yyerror("对象 " + *($1) + " 不可调用");
          			    	$$ = new string(*($1) + "(" + *($3.targetCode) + ")");
							yyerrok;
          			  	}
						else 
						{
          			    	if (symbol->type.dimension != $3.names->size()) 
							{
          			      		yyerror("参数个数不匹配, 期望参数个数: " + to_string(symbol->type.dimension) + 
										", 实际参数个数: " + to_string($3.names->size()));
          			      		$$ = new string(*($1) + "(" + *($3.targetCode) + ")");
								yyerrok;
          			    	} 
							else 
							{
          			      		for (int i = 0; i < $3.types->size(); i++) 
								{
          			        		if ((*($3.types))[i].type != symbol->type.args[i].type) 
									{
          			          			yyerror("第 " + to_string(i+1) + " 个参数类型不匹配, 期望类型: " + symbol->type.args[i].toString() +
												", 实际传入类型: " + (*($3.types))[i].toString() );
          			          			yyerrok;
									}
								}
          			      		$$ = new string(*($1) + "(" + *($3.targetCode) + ")");
							}
						}
          			}
					debugInfoBreak();
				};

expr_list: expr_list ',' expression
				{
					debugInfo("进入产生式 expr_list: expr_list ',' expression");
					debugInfo("expression.targetCode = " + *($3.targetCode) + ", expression.type = " + $3.type->toString());
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
				| expr_list error expression
				{
					debugInfo("进入产生式 expr_list: expr_list ',' expression");
					debugInfo("expression.targetCode = " + *($3.targetCode) + ", expression.type = " + $3.type->toString());
					syntax_err_suply("表达式间缺少逗号分隔");
					yyerrok;
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
					debugInfo("expression.targetCode = " + *($1.targetCode) + ", expression.type = " + $1.type->toString());
          			$$.names = new vector<string>();
          			$$.types = new vector<Type>();
          			$$.names->push_back(*($1.targetCode));
          			$$.types->push_back(*($1.type));
          			$$.targetCode = new string(*($1.targetCode));
					debugInfoBreak();
				};

expression: simple_expr TOK_RELOP simple_expr
				{
					debugInfo("进入产生式 expression: simple_expr TOK_RELOP simple_expr");
					debugInfo("TOK_RELOP=" + *($2) + ", simple_expr1.type=" + $1.type->toString() + 
							  ", simple_expr1.targetCode=" + *($1.targetCode) + 
							  ", simple_expr2.type=" + $3.type->toString() + 
							  ", simple_expr2.targetCode=" + *($3.targetCode));
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
          			} 
					else 
					{
          			  	yyerror("关系表达式，类型不正确");
          			  	yyerrok;
          			}
					$$.type = new Type();
          			$$.type->type = BasicType::BOOLEAN;
          			$$.targetCode = new string(*($1.targetCode) + relop + *($3.targetCode));
					debugInfoBreak();
				}
				| simple_expr
				{
					debugInfo("进入产生式 expression: simple_expr");
					debugInfo("simple_expr.type=" + $1.type->toString() + 
							  ", simple_expr.targetCode=" + *($1.targetCode));
          			$$.type = new Type(*($1.type));
          			$$.targetCode = new string(*($1.targetCode));
					debugInfoBreak();
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
          			  	yyerror("运算类型不正确");
						$$.targetCode = new string(*($1.targetCode) + *($2) + *($3.targetCode));
          			    $$.type = new Type();
          			    $$.type->type = BasicType::INVALID;
          			  	yyerrok;
          			} 
					else 
					{
          			  	if (*($2) == "or") 
						{
          			    	if ($1.type->type != BasicType::BOOLEAN || $3.type->type != BasicType::BOOLEAN) 
							{
          			      		yyerror("or 运算符两侧必须为布尔类型");
          			      		yyerrok;
							} 
          			      	$$.targetCode = new string(*($1.targetCode) + "||" + *($3.targetCode));
          			      	$$.type = new Type();
          			      	$$.type->type = BasicType::BOOLEAN;
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
          			      		yyerror(*($2) + " 运算符两侧类型无效");
								$$.type = new Type();
								$$.type->type = BasicType::INVALID;
								$$.targetCode = new string(*($1.targetCode) + *($2) + *($3.targetCode));
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
          			  	yyerror("运算类型不正确");
						$$.targetCode = new string(*($1.targetCode) + "&&" + *($3.targetCode));
          			  	$$.type = new Type();
          			  	$$.type->type = BasicType::BOOLEAN;
          			  	yyerrok;
          			} 
					else 
					{
          			  	if (*($2) == "and") 
						{
          			  	  	if ($1.type->type != BasicType::BOOLEAN || $3.type->type != BasicType::BOOLEAN) 
						  	{
          			  	    	yyerror("and 运算符两侧必须为布尔类型");
          			  	    	yyerrok;
          			  	  	}
          			  	    $$.targetCode = new string(*($1.targetCode) + *($2) + *($3.targetCode));
          			  	    $$.type = new Type();
          			  	    $$.type->type = BasicType::BOOLEAN;
          			  	} 
						else if (*($2) == "div") 
						{
          			  	  	if ($1.type->type != BasicType::INTEGER || $3.type->type != BasicType::INTEGER) 
							{
          			  	    	yyerror("div 运算符两侧类型必须为整数");
          			  	    	yyerrok;
          			  	  	} 
          			  	    $$.targetCode = new string(*($1.targetCode) + " / " + *($3.targetCode));
          			  	    $$.type = new Type();
          			  	    $$.type->type = BasicType::INTEGER;
          			  	} 
						else if ( *($2) == "mod") 
						{
          			  	  	if ($1.type->type != BasicType::INTEGER || $3.type->type != BasicType::INTEGER) 
							{
          			  	    	yyerror("mod 运算符两侧类型必须为整数");
          			  	    	yyerrok;
          			  	  	}
          			  	    $$.targetCode = new string(*($1.targetCode) + " % " + *($3.targetCode));
          			  	    $$.type = new Type();
          			  	    $$.type->type = BasicType::INTEGER;
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
          			    	  	yyerror("运算类型不正确");
								$$.type = new Type();
								$$.type->type = BasicType::INVALID;
								$$.targetCode = new string(*($1.targetCode) + *($2) + *($3.targetCode));
          			    	  	yyerrok;
          			    	}
          			  	}
          			}
					debugInfoBreak();
				}
				| factor
				{
					debugInfo("进入产生式 term: factor");
					debugInfo("factor.type = " + $1.type->toString() + ", factor.targetCode=" + *($1.targetCode));
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
          			  	yyerror("标识符 " + *($1) + " 未定义");
						$$.type = new Type();
          			  	$$.type->type = BasicType::INVALID;
          			  	$$.targetCode = new string("");
						yyerrok;
          			} 
					else 
					{
          			  	if (symbol->type.isCallable()) 
						{
          			  	  	if (symbol->type.ret_type == BasicType::VOID) 
							{
          			  	  	  	yyerror("标识符 " + *($1) + " 不能是一个void类型的函数或过程");
          			  	  	  	$$.type = new Type();
          			  			$$.type->type = symbol->type.ret_type;
          			  			$$.targetCode = new string(*($1) + "()");
								yyerrok;
          			  	  	} 
							else 
							{
          			  	  	  	if (symbol->type.dimension != 0) 
								{
          			  	  	  		yyerror("函数 " + *($1) + " 不能无参调用, 期待参数个数: " + to_string(symbol->type.dimension));
									yyerrok;
          			  	  	  	} 
          			  	  	  	$$.type = new Type();
          			  	  	  	$$.type->type = symbol->type.ret_type;
          			  	  	  	$$.targetCode = new string(*($1) + "()");
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
          			  	yyerror("标识符 " + *($1) + " 未定义");
          			  	$$.type = new Type();
          			  	$$.type->type = BasicType::INVALID;
          			  	$$.targetCode = new string("");
						yyerrok;
          			} 
					else 
					{
          			  	if (!symbol->type.isCallable()) 
						{
          			  	  	yyerror("对象" + *($1) + "不是一个可以调用的对象, 实际类型为: " + symbol->type.toString());
          			  	  	$$.type = new Type();
          			  		$$.type->type = BasicType::INVALID;
          			  		$$.targetCode = new string("");
							yyerrok;
          			  	} 
						else 
						{
          			  	  	if (symbol->type.ret_type == BasicType::VOID) 
							{
          			  	  	  	yyerror("函数 " + *($1) + " 被调用但是没有返回值");
          			  	  	  	$$.type = new Type();
          			  			$$.type->type = BasicType::INVALID;
          			  			$$.targetCode = new string(*($1) + "(" + *($3.targetCode) + ")");
								yyerrok;
          			  	  	} 
							else 
							{
          			  	  	  	if ($3.names->size() != symbol->type.dimension) 
								{
          			  	  	  	  	yyerror("参数个数不匹配, 期望参数个数: " + to_string(symbol->type.dimension) + 
											", 实际参数个数: " + to_string($3.names->size()));
          			  	  	  	  	$$.targetCode = new string(*($1) + "(" + *($3.targetCode) + ")");
									$$.type = new Type();
									$$.type->type = symbol->type.ret_type;
									yyerrok;
          			  	  	  	} 
								else 
								{
          			  	  	  	  	for (int i = 0; i < $3.types->size(); i++) 
									{
          			  	  	  	  	  	if ((*($3.types))[i].type != symbol->type.args[i].type) 
										{
          			  	  	  	  	  	  	yyerror("第 " + to_string(i+1) + " 个参数类型不匹配, 期望类型: " + symbol->type.args[i].toString() +
												", 实际传入类型: " + (*($3.types))[i].toString() );	
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
					debugInfo("进入产生式 factor: TOK_ID '[' expression ']'");
					debugInfo("TOK_ID = " + *($1) + ", expression.type=" + $3.type->toString() +  ", expression.targetCode=" + *($3.targetCode));
					Symbol *const sym_ptr = sym_table.getSymbol(*($1));
					if (!sym_ptr)
					{
						yyerror(*($1) + " 未定义");
						$$.type = new Type();
          			  	$$.type->type = BasicType::INVALID;
          			  	$$.targetCode = new string("");
						yyerrok;
					}
					else if ($3.type->type != BasicType::INTEGER)
					{
						yyerror("数组下标访问必须使用整数");
						$$.type = new Type();
          			  	$$.type->type = sym_ptr->type.type;
          			  	$$.targetCode = new string("");
						yyerrok;
					}
					else
					{
						if (sym_ptr && !sym_ptr->type.isArray())
						{
							yyerror(*($1) + "不是数组类型");
							$$.type = new Type();
          				  	$$.type->type = sym_ptr->type.type;
          				  	$$.targetCode = new string("");
							yyerrok;
						}
						else
						{
							int lb = sym_ptr->type.periods[0].first;

							$$.type = new Type();
							$$.type->type = sym_ptr->type.type;

							string temp_code = *($1) + "[" + *($3.targetCode) + "-" + to_string(lb) + "]";
							$$.targetCode = new string(temp_code);
							debugInfoBreak();
						}
					}
				}
				| TOK_NUM
				{
					debugInfo("进入产生式 factor: TOK_NUM");
					debugInfo("TOK_NUM.isReal=" + to_string($1.isReal) + ", TOK_NUM.targetCode=" + *($1.targetCode));

					$$.type = new Type();
					$$.targetCode = new string(*($1.targetCode));
					if ($1.isReal)
						$$.type->type = BasicType::REAL;
					else
						$$.type->type = BasicType::INTEGER;
					debugInfoBreak();
				}
				| '(' expression ')'
				{
					debugInfo("进入产生式 factor: '(' expression ')'");
					debugInfo("expression.type=" + $2.type->toString() + 
							  ", expression.targetCode=" + *($2.targetCode));
					$$.type = new Type(*($2.type));
					$$.targetCode = new string();
					*($$.targetCode) = "(" + *($2.targetCode) + ")";
					debugInfoBreak();
				}
				| TOK_NOT factor
				{
					debugInfo("进入产生式 factor: TOK_NOT factor");
					debugInfo("factor.type=" + $2.type->toString() + 
							  ", factor.targetCode=" + *($2.targetCode));
					if ($2.type->type != BasicType::BOOLEAN)
					{
						yyerror("NOT 后面必须为布尔表达式");
						yyerrok;
					}
					$$.type = new Type();
					$$.targetCode = new string("!");
					$$.targetCode->append(*($2.targetCode));
					$$.type->type = BasicType::BOOLEAN;
					debugInfoBreak();
				}
				| TOK_TRUE
				{
					debugInfo("进入产生式 factor: TOK_TRUE");
					$$.type = new Type();
					$$.targetCode = new string("true");
					$$.type->type = BasicType::BOOLEAN;
					debugInfoBreak();
				}
				| TOK_FALSE
				{
					debugInfo("进入产生式 factor: TOK_FALSE");
				 	$$.type = new Type();
					$$.targetCode = new string("false");
					$$.type->type = BasicType::BOOLEAN;
					debugInfoBreak();
				}
				| TOK_CHAR_LIT
				{
					debugInfo("进入产生式 factor: TOK_CHAR_LIT");
					debugInfo("TOK_CHAR_LIT=" + *($1));
					$$.type = new Type();
					$$.type->type = BasicType::CHAR;
					$$.type->is_constant = true;


					// TODO 改进字符串
					string temp_string;
					int size = $1->size();
					if (size == 3 || (size == 4 && $1->at(1) == '\\' )) // 是字符
					{
						temp_string = *($1);
					}
					else
					{
						temp_string.push_back('"');
						for (int i = 1; i < size; i++)
						{
							if ($1->at(i) == '"')
								temp_string.append("\\\"");
							else
								temp_string.push_back($1->at(i));
						}
						temp_string.pop_back(); // 弹出单引号
						temp_string.push_back('"');
					}
					$$.targetCode = new string(temp_string);
					debugInfoBreak();
				};

sign: TOK_ADDOP
	  {
		debugInfo("进入产生式 sign: TOK_ADDOP");
		if (*($1) == "or")
		{
			yyerror("符号必须为加号或者减号");
			$$ = new string("");
			yyerrok;
		}
		else
	  		$$ = new string(*($1));
		debugInfoBreak();
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
	total_error_count++;
	cerr << "!ERROR!(" << yylineno << "): " << err_msg << endl;
}

void syntax_err_suply(const string &err_msg)
{
	cerr << "!ERROR_NOTE!(" << yylineno << "): " << err_msg << endl << endl;
}

int main(void) {
	int res = yyparse();
	if (!res && !total_error_count)
		cout << final_code << endl;
	else
		cout << "编译失败, 共出现 " << total_error_count << " 个错误" << endl;
 	return 0;
}