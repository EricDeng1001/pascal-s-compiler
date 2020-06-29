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
					string tmp_target = *($1) + *($2);
					$$ = new string(tmp_target);
					cout << *($$);
				}
        | program_head program_body error
				{
					string tmp_target = *($1) + *($2);
					$$ = new string(tmp_target);
					cout << *($$);
					yyerror("program -> program_head program_body . : missing '.'at the end of the program.");
					yyerrok;
				};

program_head: PROGRAM ID '(' INPUT ',' OUTPUT ')' ';'
				{
					$$ = new string("#include <iostream>\n#include <cmath>\nusing namespace std;\n"); //填写C++程序首部
				};

identifier_list: identifier_list ',' ID
				{
					// 记录已经录入的参数
					$$.names = new vector<string>(*($1.names));
					// 记录新的id
					($$.names)->push_back(*($3));
				}
				| ID
				{
					$$.names = new vector<string>();
					($$.names)->push_back(*($1));
				};

program_body: declarations subprogram_declarations compound_statement
				{
					string tmp_target = *($1) + "\n" +
										*($2) + "\n" +
										"int main()\n{\n" +
										*($3) + "\n" +
										"return 0;\n}\n";
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

							Symbol sym((*($3.names))[i], *($5.type), yylineno);
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) {
								yyerror("declaration -> declaration ; identifier_list : type : redefined varible Identifier in identifier_list!");
								yyerrok;
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
							Symbol sym((*($3.names))[i], *($5.type), yylineno);
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) {
								yyerror("declaration -> declaration ; identifier_list : type : redefined array Identifier in identifier_list!");
								yyerrok;
							}
							else {	// 生成目标代码
								string target = to_string($5.array_top - $5.array_bottom  + 1);
								if(i != ($3.names)->size() - 1)
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
							Symbol sym((*($1.names))[i], *($3.type), yylineno);
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) {
								yyerror("declaration -> declaration ; identifier_list : type : redefined varible Identifier in identifier_list!");
								yyerrok;
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
							Symbol sym((*($1.names))[i], *($3.type), yylineno);
							// 插入到符号表
							pair<bool, int> res = sym_table.InsertSymbol(sym);
							if(res.first == false) {
								parser.yyerror("declaration -> declaration ; identifier_list : type : redefined array Identifier in identifier_list!");
								parser.yyerrok;
							}
							else {	// 生成目标代码
								string target = to_string($3.array_top - $3.array_bottom  + 1);
								if(i != ($1.names)->size() - 1)
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
					$$.type = $1.type;
					$$.targetCode = $1.targetCode;
				}
				| ARRAY '[' NUM '.' '.' NUM ']' OF standard_type
				{
					if($3.type != BasicType::INTEGER || $6.type != BasicType::INTEGER) {
						yyerror("type -> ARRAY [ NUM . . NUM ] OF standard_type : 数组参数NUM类型错误!");		/////////////////////////////////////////////////////// 现在
						yyerrok;
					}
					$$.type = $9.type;
					$$.array_top = (int)($6.num);
					$$.array_bottom = (int)($3.num);
					if($$.array_top - $$.array_bottom < 0) {
						parser.yyerror("type -> ARRAY [ NUM . . NUM ] OF standard_type : 数组下界不可小于上界!");
						parser.yyerrok;
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
								  *($3) + "\n" +
								  "}\n";
					$$ = new string(temp);
					if (!symbol_table.ExitScope())
					{
						// TODO 错误处理, 退出作用域失败
					}
				};

subprogram_head: FUNCTION ID arguments ':' standard_type ';'
				{
					// 检查函数名是否重复
					if (sym_table.isInScope(*($2)))
					{
						yyerror("重复的标识符 " + *($2));
						yyerrok;
					}

					SymbolBuilder func_builder = Symbol.getSymbolBuilder();
					func_builder.addName(*($2))
						   		.setRetType($5.type->type)
								.setDefAt(yylineno)

					int dimension = 0;
					for (const auto &[type, names] : *($3.paraTypeAndNames))
					{
						func_builder.addArg(type);
						dimension += names.size();
					}
					func_builder.setDimension(dimension);
					Symbol func_symbol;
					if (!sym_table.InsertSymbol(func_symbol).first)
					{
						// TODO 错误处理, 插入失败
					}

					// 向符号表中添加参数
					if (!sym_table.EnterScope(func_symbol.name))
					{
						// TODO 错误处理, 进入子作用域失败
					}

					for (const auto &[type, names] : *($3.paraTypeAndNames))
					{
						// 检查名字是否冲突
						SymbolBuilder params_builder = Symbol.getSymbolBuilder();
						params_builder.addType(type).setDefAt(yylineno);
						for (const auto &name : names)
						{
							if (sym_table.isInScope() || name == func_symbol.name)
							{
								yyerror("重复的标识符 " + name);
								yyerrok;
							}
							auto temp_builder = params_builder;
							temp_builder.addName(name);
							sym_table.InsertSymbol(temp_builder.build());
						}
					}

					string temp_code = *($5.targetCode) + " " + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
				}
				| FUNCTION ID arguments error
				{
					yyerror("函数 " + *($2) + " 没有返回值");
					yyerrok;
					string temp_code = string("void ") + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
				}
				| PROCEDURE ID arguments ';'
				{
					// 检查函数名是否重复
					if (sym_table.isInScope(*($2)))
					{
						yyerror("重复的标识符 " + *($2));
						yyerrok;
					}

					SymbolBuilder func_builder = Symbol.getSymbolBuilder();
					func_builder.addName(*($2))
								.setDefAt(yylineno)

					int dimension = 0;
					for (const auto &[type, names] : *($3.paraTypeAndNames))
					{
						func_builder.addArg(type);
						dimension += names.size();
					}
					func_builder.setDimension(dimension);
					Symbol func_symbol;
					if (!sym_table.InsertSymbol(func_symbol).first)
					{
						// TODO 错误处理, 插入失败
					}

					// 向符号表中添加参数
					if (!sym_table.EnterScope(func_symbol.name))
					{
						// TODO 错误处理, 进入子作用域失败
					}

					for (const auto &[type, names] : *($3.paraTypeAndNames))
					{
						// 检查名字是否冲突
						SymbolBuilder params_builder = Symbol.getSymbolBuilder();
						params_builder.addType(type).setDefAt(yylineno);
						for (const auto &name : names)
						{
							if (sym_table.isInScope() || name == func_symbol.name)
							{
								yyerror("重复的标识符 " + name);
								yyerrok;
							}
							auto temp_builder = params_builder;
							temp_builder.addName(name);
							sym_table.InsertSymbol(temp_builder.build());
						}
					}

					string temp_code = "void " + *($2) + *($3.targetCode);
					$$ = new string(temp_code);
				}
				| PROCEDURE ID arguments error ';'
				{
					yyerror("过程 " + *($2) + " 不能有返回值");
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
								 ->append(")");
				}
				|
				{
					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>();
					$$.targetCode = new string("()");
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

					for (int i = 0; i < $2.names->size(); i++)
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
					Type &temp_type = *($3.type);
					temp_type.is_ref = false;

					$$.paraTypeAndNames = new vector<pair<Type, vector<string>>>();
				    $$.paraTypeAndNames->push_back({temp_type, *($1.names)});

					$$.targetCode = new string();

					for (int i = 0; i < $1.names->size(); i++)
					{
						$$.targetCode->append(*($3.targetCode) + " ")
									 ->append($1.names[i]);
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
					$$->append(*($3) + "\n");
				}
				| statement
				{
					$$ = new string(*($1) + ";\n");
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

					if (lhs_type.isArray())
					{
						yyerror("赋值语句不直接应用于数组");
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
						}
					}

					for (const auto &name : *($3.names))
						temp_code.append(" >> ")
								 .append(name);
				};

variable: ID
				{
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (symbol == nullptr) {
          			  yyerror("id not defined!");
          			  yyerrok;
          			} else if (symbol->type.isCallable()) {
          			  if (*($1) == sym_table.getParentSymbol()->name) {
          			    if (symbol->type.ret_type == BasicType::VOID) {
          			      yyerror("could not return");
          			      yyerrok;
          			    } else {
          			      $$.type = new Type(symbol->type);
          			    }
          			  } else {
          			      yyerror("return id wrong");
          			      yyerrok;
          			  }
          			} else if (symbol->type.isArray()) {
          			  yyerror("can not assign array");
          			  yyerrok;
          			}
          			else {
          			  $$.type = new Type(symbol->type);
          			  $$.targetCode = new string(*($1));
          			}
				}
				| ID '[' expression ']'
				{
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (symbol == nullptr) {
          			  yyerror("id not defined");
          			  yyerrok;
          			} else if (!symbol->type.isArray()) {
          			  yyerror("id must be an array");
          			  yyerrok;
          			} else {
          			  if ($3.type->type != BasicType::INTEGER) {
          			    yyerror("引用必须是整数");
          			    yyerrok;
          			  } else {
          			    $$.type = new Type(symbol->type);
          			    $$.targetCode = new string(*($1) + "[" +  *($3.targetCode) + "]");
          			  }
          			}
				};

procedure_call_statement: ID
				{
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (symbol == nullptr) {
          			  yyerror("id not defined");
          			  yyerrok;
          			} else {
          			  if (symbol->type.isCallable()) {
          			    $$ = new string(*($1) + "();\n");
          			  } else {
          			    yyerror("id is not callable");
          			    yyerrok;
          			  }
          			}
				}
				| ID '(' expr_list ')'
				{
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (symbol == nullptr) {
          			  yyerror("id not defined");
          			  yyerrok;
          			} else {
          			  if (!symbol->type.isCallable()) {
          			    yyerror("id is not callable");
          			    yyerrok;
          			  } else {
          			    if (symbol->type.dimension != $3.names->size()) {
          			      yyerror("参数个数不匹配");
          			      yyerrok;
          			    } else {
          			      for (int i = 0; i < $3.types->size(); i++) {
          			        if ((*($3.types))[i] != symbol->args[i]) {
          			          yyerror(string("第") + string(i) + "个参数类型不匹配");
          			          yyerrok;
          			        }
          			      }
          			      $$ = new string(*($1) + "(" + *($3.targetCode) + ");\n");
          			    }
          			  }
          			}
				};

expr_list: expr_list ',' expression
				{
          			$$.names = new vector<string>();
          			$$.types = new vector<Type>();
          			for (int i = 0; i < $1.names->size(); i++) {
          			  $$.names->push_back((*($1.names))[i]);
          			  $$.types->push_back((*($1.types))[i]);
          			}
          			$$.names->push_back(string($3.targetCode->data()));
          			$$.types->push_back($3.type);
          			$$.targetCode = new string(*($1.targetCode) + ", " + *($3.targetCode));
				}
				| expression
				{
          			$$.names = new vector<string>();
          			$$.types = new vector<Type>();
          			$$.names->push_back(string($1.targetCode->data()));
          			$$.types->push_back($1.type);
          			$$.targetCode = new string(*($1.targetCode));
				};

expression: simple_expr RELOP simple_expr
				{
          			string relop;
          			if (!($1.type->isCallable()) && !($1.type->isArray())
          			&& !($3.type->isCallable()) && !($3.type->isArray())) {
          			  if (*($2) == "<>") {
          			    relop = "!=";
          			  } else if (*($2) == "=") {
          			    relop = "==";
          			  } else {
          			    relop = string(*($2));
          			  }
          			  $$.type = new Type();
          			  $$.type->type = BasicType::BOOLEAN;
          			  $$.targetCode = new string(*($1.targetCode) + relop + *($3.targetCode));
          			} else {
          			  yyerror("关系表达式，类型不正确");
          			  yyerrok;
          			}
				}
				| simple_expr
				{
          			$$.type = new Type($1.type);
          			$$.targetCode = new string(*($1));
				};

simple_expr: simple_expr ADDOP term
				{
          			if ($1.type->isCallable() || $1.type->isArray()
          			|| $3.type->isCallable() || $3.type->isArray()) {
          			  yyerror("运算类型不正确");
          			  yyerrok;
          			} else {
          			  if (*($2) == "or") {
          			    if ($1.type->type != BasicType::BOOLEAN || $3.type->type != BasicType::BOOLEAN) {
          			      yyerror("运算类型不正确");
          			      yyerrok;
          			    } else {
          			      $$.targetCode = new string(*($1.targetCode) + "||" + *($3.targetCode));
          			      $$.type = new Type();
          			      $$.type->type = BasicType::BOOLEAN;
          			    }
          			  } else {
          			    if (($1.type == BasicType::INTEGER || $1.type == BasicType::REAL)
          			    && ($3.type == BasicType::INTEGER || $3.type == BasicType::REAL)) {
          			       $$.type = new Type();
          			      if ($1.type == BasicType::REAL || $3.type == BasicType::REAL) {
          			        $$.type->type = BasicType::REAL;
          			      } else {
          			        $$.type->type = BasicType::INTEGER;
          			      }
          			      $$.targetCode = new string(*($1.targetCode) + *($2) + *($3.targetCode));
          			    } else {
          			      yyerror("运算类型不正确");
          			      yyerrok;
          			    }
          			  }
          			}
				}
				| term
				{
          			$$.type = new Type($1.type);
          			$$.targetCode = new string(*($1.targetCode));
				}
				| sign term
				{
         			$$.type = new Type($2.type);
         			$$.targetCode = new string(*($1) + *($2.targetCode));
				};

term: term MULOP factor
				{
          			if ($1.type->isCallable() || $1.type->isArray() ||
					    $3.type->isCallable() || $3.type->isArray()) {
          			  	yyerror("运算类型不正确");
          			  	yyerrok;
          			} else {
          			  	if (*($2) == "and") {
          			  	  if ($1.type->type != BasicType::BOOLEAN || $3.type->type != BasicType::BOOLEAN) {
          			  	    yyerror("运算类型不正确");
          			  	    yyerrok;
          			  	  } else {
          			  	    $$.targetCode = new string(*($1.targetCode) + "&&" + *($3.targetCode));
          			  	    $$.type = new Type();
          			  	    $$.type->type = BasicType::BOOLEAN;
          			  	  }
          			  	} else if (*($2) == "div") {
          			  	  if ($1.type->type != BasicType::INTEGER || $3.type->type != BasicType::INTEGER) {
          			  	    yyerror("运算类型不正确");
          			  	    yyerrok;
          			  	  } else {
          			  	    $$.targetCode = new string(*($1.targetCode) + " / " + *($3.targetCode));
          			  	    $$.type = new Type();
          			  	    $$.type->type = BasicType.INTEGER;
          			  	  }
          			  	} else if ( *($2) == "mod") {
          			  	  if ($1.type->type != BasicType::INTEGER || $3.type->type != BasicType::INTEGER) {
          			  	    yyerror("运算类型不正确");
          			  	    yyerrok;
          			  	  } else {
          			  	    $$.targetCode = new string(*($1.targetCode) + " % " + *($3.targetCode));
          			  	    $$.type = new Type();
          			  	    $$.type->type = BasicType.INTEGER;
          			  	  }
          			  } else {
          			    	if (($1.type == BasicType::INTEGER || $1.type == BasicType::REAL)
          			    	&& ($3.type == BasicType::INTEGER || $3.type == BasicType::REAL)) {
          			    	   $$.type = new Type();
          			    	  if ($1.type == BasicType::REAL || $3.type == BasicType::REAL) {
          			    	    $$.type->type = BasicType::REAL;
          			    	  } else {
          			    	    $$.type->type = BasicType::INTEGER;
          			    	  }
          			    	  $$.targetCode = new string(*($1.targetCode) + *($2) + *($3.targetCode));
          			    	} else {
          			    	  yyerror("运算类型不正确");
          			    	  yyerrok;
          			    	}
          			  }
          			}
				}
				| factor
				{
          			$$.type = new Type($1.type);
          			$$.targetCode = new string(*($1));
				};

factor: ID
				{
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (symbol == nullptr) {
          			  	yyerror("id not defined");
          			  	yyerrok;
          			} else {
          			  	if (symbol->type.isCallable()) {
          			  	  	if (symbol->ret_type == BasicType::VOID) {
          			  	  	  	yyerror("id不能是一个void类型的函数或过程");
          			  	  	  	yyerrok;
          			  	  	} else {
          			  	  	  	if (symbol->dimension != 0) {
          			  	  	  	  	yyerror("函数不能无参调用");
          			  	  	  	  	yyerrok;
          			  	  	  	} else {
          			  	  	  	  	$$.type = new Type();
          			  	  	  	  	$$.type->type = symbol->ret_type;
          			  	  	  	  	$$.targetCode = *($1) + "()";
          			  	  	  	}
          			  	  	}
          			  	} else {
          			  	  	$$.type = new Type(symbol->type);
          			  	  	$$.targetCode = new string(*($1));
          			  	}
          			}
				}
				| ID '(' expr_list ')'
				{
          			Symbol* symbol = sym_table.getSymbol(*($1));
          			if (symbol == nullptr) {
          			  yyerror("id not defined");
          			  yyerrok;
          			} else {
          			  	if (!symbol->type.isCallable()) {
          			  	  yyerror("id必须是一个可以调用");
          			  	  yyerrok;
          			  	} else {
          			  	  	if (symbol->ret_type == BasicType.VOID) {
          			  	  	  yyerror("被调用的函数必须有返回值");
          			  	  	  yyerrok;
          			  	  	} else {
          			  	  	  	if ($3.names->size() != symbol->dimension) {
          			  	  	  	  yyerror("被调用函数的参数个数不匹配");
          			  	  	  	  yyerrok;
          			  	  	  	} else {
          			  	  	  	  	for (int i = 0; i < $3.types->size(); i++) {
          			  	  	  	  	  	if ((*($3.types))[i] != symbol->args[i]) {
          			  	  	  	  	  	  	yyerror(string("第") + string(i) + "个参数类型不匹配");
          			  	  	  	  	  	  	yyerrok;
          			  	  	  	  	  	}
          			  	  	  	  	}
          			  	  	  	  $$ = new string(*($1) + "(" + *($3.targetCode) + ")");
          			  	  	  	}
          			  	  	}
          			  	}
          			}
				}
				| ID '[' expression ']'
				{
					if ($3.type->type != BasicType::INTEGER)
					{
						yyerror("数组下标访问必须使用整数");
						yyerrok;
					}

					if (!sym_table.isInScope(*($1)))
					{
						yyerror(*($1) + " 未定义");
						yyerrok;
					}
					Symbol *const sym_ptr = sym_table.getSymbol(*($1))
					if (sym_ptr && !sym_ptr->type.isArray())
					{
						yyerror(*($1) + "不是数组类型");
						yyerrok;
					}

					int lb = sym_ptr->type.period[0].front;

					$$.type = new Type();
					$$.type->type = sym_ptr->type.type;
					
					string temp_code = *($1) + "[" + *($3.targetCode) + "-" + to_string(lb) + "]";
					$$.targetCode = new string(temp_code);
				}
				| NUM
				{
					$$.type = new Type();
					$$.targetCode = new string(*($1.targetCode));
					if (isReal)
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
				| NOT factor
				{
					if ($2.type->type != BasicType::BOOLEAN)
					{
						yyerror("NOT 后面必须为布尔表达式");
						yyerrok;
					}
					$$.type = new Type();
					$$.targetCode = new string("!");
					$$.targetCode->append(*($2.targetCode));
					$$.type->type = BasicType::BOOLEAN;
				}
				| TRUE
				{
					$$.type = new Type();
					$$.targetCode = new string("true");
					$$.type->type = BasicType::BOOLEAN;
				}
				| FALSE
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

int main(void) {
	return yyparse();
}