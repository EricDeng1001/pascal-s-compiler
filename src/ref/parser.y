%{
/****************************************************************************
parser.y
ParserWizard generated YACC file.

Date: 2014年12月6日
****************************************************************************/
#include <string>
#include <vector>
#include <map>
#include <utility>
#include <iostream>
#include <cstdio>
#include <fstream>
#include <sstream>

#include "tableStructs.h"
#include "symbolTable.h"
#include "lexer.h"
#include "parser.h"


using namespace std;

Lexer lexer;    //词法分析器

Parser parser;  //语法分析器

SymbolTable sym_table;	// 符号表

vector <string> argv;	// 主函数输入参数

ifstream in_stream;//读入文件

ofstream out_stream;//输出文件

fstream debug_stream; // 调试信息输出流

fstream error_stream; // 目标代码输出流


//表达式列表
typedef struct
{
	vector <string> idNameList;
	vector <DATA_TYPE> dataTypeList;
	vector <TABLE_TYPE> tableTypeList;
}parameteList;

//表达式列表
typedef struct
{
	vector <int> lowList;
	vector <int> highList;
}paraArrayList;

parameteList paraList;
paraArrayList arrayList;
string currentFunction = "";
bool needReturn = false;


%}

/////////////////////////////////////////////////////////////////////////////
// declarations section
%union
{
	//目标代码
	string* targetCode;

	//数字转化后的目标代码
	struct
	{
		double num;
		DATA_TYPE dataType;
	    string* targetCode;
	}targetDigitCode;

	//标识符
	struct
	{
		vector <string>* idNameList;
	   // vector <string>* idValueList;
	}idList;

	//表达式列表
	struct
	{
		vector <string>* idNameList;
	    vector <DATA_TYPE>*dataTypeList;
	    vector <TABLE_TYPE>* tableTypeList;
	    string* targetCode;
	}exprList;

	// 变量类型
	struct
	{
		DATA_TYPE id_type;
		TABLE_TYPE table_type;
		int array_top;
		int array_bottom;
		string* targetCode;
	}typeStruct;

	struct
	{
		vector <DATA_TYPE>* paraType;
		string* targetCode;
	}parameterStruct;

	// 变量类型
	struct
	{
		DATA_TYPE value_type;
		TABLE_TYPE table_type;
		string* targetCode;
	}expStruct;

}

// parser name
%name Parser

// class definition
{
	// place any extra class members here
	virtual void yyerror(const char*s);  //yyerror（）用于报错，提示代码中的错误。
}

// constructor
{
	// place any extra initialisation code here
}

// destructor
{
	// place any extra cleanup code here
}

// attribute type
%include {
#ifndef YYSTYPE
#define YYSTYPE int
#endif
}
// place any declarations here

//关键字
%token <targetCode> PROGRAM  VAR  ARRAY  OF  RECORD  INTEGER
								 REAL  BOOLEAN  FUNCTION  PROCEDURE  DO
								 BEGIN  IF  THEN  END  NOT  WHILE  READ
								 WRITE  ELSE  TRUE  FALSE

//关系运算符，运算符(+,-,or)，运算符(*,/,div,mod,and),赋值运算符
%token <targetCode> RELOP  ADDOP  MULOP  ASSIGNOP
//标识符
%token <targetCode>	ID
//数字
%token <targetDigitCode> NUM

//非终结符
%type <targetCode>  program  program_head  subprogram_head   program_body declarations  declaration
					subprogram_declarations  subprogram_declaration statement    compound_statement
					optional_statements  procedure_call_statement statement_list  sign

// 变量列表
%type <idList> identifier_list

//表达式列表
%type <exprList> expr_list

// 变量类型
%type <typeStruct> type  standard_type

%type <expStruct> variable expression  simple_expr  term factor

// 函数参数列表
%type <parameterStruct> parameter_list  parameter_lists  arguments

%%

/////////////////////////////////////////////////////////////////////////////
// rules section

// place your YACC rules here (there must be at least one)

program : program_head program_body '.'
				{
					debug_stream<<"	YACC--program : program_head program_body ." << endl;
					string tmp_target = string($1->data()) + string($2->data());
					$$ = new string(tmp_target);
					out_stream << string($$->data());
					cout << endl << string($$->data());
					debug_stream<<string($$->data());
				}
                | program_head program_body error
				{
				    debug_stream<<"	YACC--program : program_head program_body error" << endl;
					string tmp_target = string($1->data()) + string($2->data());
					$$ = new string(tmp_target);
					out_stream << string($$->data());
					parser.yyerror("program -> program_head program_body . : missing '.'at the end of the program.");
					parser.yyerrok();
				};

program_head : PROGRAM ID '(' identifier_list ')' ';'
				{
					debug_stream<<"	YACC--program_head->PROGRAM ID ( identifier_list ) ;" << endl;

					$$ = new string("#include <iostream>\nusing namespace std;\n");	// 填写C++程序首部
					debug_stream << "	data() = " << $$->data();

					// 新块定向操作
					sym_table.locate();

					// 写入程序ID
					functionInfo proID_In;
					proID_In.declareRow = lexer.yylineno;
					if(sym_table.insert(string($2->data()), proID_In) == NULL) {		// sym_table.insert(...)的参数类型是string吗
						parser.yyerror("program_head -> PROGRAM ID ( identifier_list ) ; : redefined program ID !");
						parser.yyerrok();
					}

					// 记录程序输入参数
					for(int i = 0; i < ($4.idNameList)->size(); i++) {
						// 将identifier_list写入符号表
						varInfo argvIn;
						argvIn.declareRow = lexer.yylineno;

						if(sym_table.insert((*($4.idNameList))[i], argvIn) == NULL) {
							parser.yyerror("program_head -> PROGRAM ID ( identifier_list ) ; : redefined input identifiers!");
							parser.yyerrok();
						}
					}

				};

identifier_list : identifier_list ',' ID
				{
					debug_stream << "	YACC--identifier_list->identifier_list , ID" << endl;
					// 记录已经录入的参数
					$$.idNameList = new vector <string>;
					for(int i = 0; i < ($1.idNameList)->size(); i++) {
						($$.idNameList)->push_back((*($1.idNameList))[i]);
					}
					// 记录新的id
					($$.idNameList)->push_back(string($3->data()));
				}
				| ID
				{
					debug_stream << "	YACC--identifier_list->ID" << endl;
					$$.idNameList = new vector <string>;
					($$.idNameList)->push_back(string($1->data()));
				};

program_body : declarations subprogram_declarations compound_statement
				{
					debug_stream << "	YACC--program_body->declarations subprogram_declarations compound_statement" << endl;
					string tmp_target = string($1->data()) + string($2->data()) + "\n" + "int main()\n{\n" + string($3->data()) + "\nreturn 0;\n}\n";
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << $$->data() << endl;
				};

declarations : VAR declaration ';'
				{
					debug_stream << "	YACC--declarations->VAR declaration ;" << endl;
					string tmp_target = string($2->data());
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << $$->data() << endl;
				}
				|
				{
					debug_stream << "	YACC--declarations->NULL" << endl;
					$$ = new string("");
					debug_stream << "	data() = " << $$->data() << endl;
					// do nothing
				};

declaration : declaration ';' identifier_list ':' type
				{
					debug_stream << "	YACC--declaration->declaration ; identifier_list : type" << endl;
					if($5.table_type == VARIBLE_T) {
						string tmp_target = string(($5.targetCode)->data());
						for(int i = 0; i < ($3.idNameList)->size(); i++) {
							varInfo declare_In;
							declare_In.type = $5.id_type;
							declare_In.declareRow = lexer.yylineno;
							// 插入到符号表
							if(sym_table.insert((*($3.idNameList))[i], declare_In) == NULL) {
								parser.yyerror("declaration -> declaration ; identifier_list : type : redefined varible Identifier in identifier_list!");
								parser.yyerrok();
							}
							else {	// 生成目标代码
								if(i != ($3.idNameList)->size() - 1)
									tmp_target += " " + (*($3.idNameList))[i] + ",";
								else
									tmp_target += " " + (*($3.idNameList))[i] + ";\n";
							}
						}
						$$ = new string(string(($1)->data()) + tmp_target);
						debug_stream << "	data() = " << $$->data() << endl;
					}
					else if($5.table_type == ARRAY_T) {
						string tmp_target = string(($5.targetCode)->data());
						for(int i = 0; i < ($3.idNameList)->size(); i++) {
							arrayInfo declare_In;
							declare_In.type = $5.id_type;
							declare_In.low = $5.array_bottom;
							declare_In.high = $5.array_top;
							declare_In.declareRow = lexer.yylineno;
							// 插入到符号表
							if(sym_table.insert((*($3.idNameList))[i], declare_In) == NULL) {
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
									tmp_target += " " + (*($3.idNameList))[i] + "[" + target + "],";
								else
									tmp_target += " " + (*($3.idNameList))[i] + "[" + target + "];\n";
							}
						}
						$$ = new string(string(($1)->data()) + tmp_target);
						debug_stream << "	data() = " << $$->data() << endl;
					}
				}
				| identifier_list ':' type
				{
					debug_stream << "	YACC--declaration->identifier_list : type" << endl;
					if($3.table_type == VARIBLE_T) {
						string tmp_target = string(($3.targetCode)->data());
						for(int i = 0; i < ($1.idNameList)->size(); i++) {
							varInfo declare_In;
							declare_In.type = $3.id_type;
							declare_In.declareRow = lexer.yylineno;
							// 插入到符号表
							if(sym_table.insert((*($1.idNameList))[i], declare_In) == NULL) {
								parser.yyerror("declaration -> identifier_list : type : redefined varible Identifier in identifier_list!");
								parser.yyerrok();
							}
							else {	// 生成目标代码
								if(i != ($1.idNameList)->size() - 1)
									tmp_target += " " + (*($1.idNameList))[i] + ",";
								else
									tmp_target += " " + (*($1.idNameList))[i] + ";\n";
							}
						}
						$$ = new string(tmp_target);
						debug_stream << "	data() = " << $$->data() << endl;
					}
					else if($3.table_type == ARRAY_T) {
						string tmp_target = string(($3.targetCode)->data());
						for(int i = 0; i < ($1.idNameList)->size(); i++) {
							arrayInfo declare_In;
							declare_In.type = $3.id_type;
							declare_In.low = $3.array_bottom;
							declare_In.high = $3.array_top;
							declare_In.declareRow = lexer.yylineno;
							// 插入到符号表
							if(sym_table.insert((*($1.idNameList))[i], declare_In) == NULL) {
								parser.yyerror("declaration -> identifier_list : type : redefined array Identifier in identifier_list!");
								parser.yyerrok();
							}
							else {	// 生成目标代码
								int array_range = $3.array_top - $3.array_bottom  + 1;
								stringstream ss;
								string target;
								ss << array_range;
								ss >> target;
								if(i != ($1.idNameList)->size() - 1)
									tmp_target += " " + (*($1.idNameList))[i] + "[" + target + "],";
								else
									tmp_target += " " + (*($1.idNameList))[i] + "[" + target + "];\n";
							}
						}
						$$ = new string(tmp_target);
						debug_stream << "	data() = " << $$->data() << endl;
					}
				};

type : standard_type
				{
					debug_stream << "	YACC--type->standard_type" << endl;
					$$.id_type = $1.id_type;
					$$.table_type = $1.table_type;
					$$.targetCode = new string(($1.targetCode)->data());
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| ARRAY '[' NUM '.' '.' NUM ']' OF standard_type
				{
					debug_stream<<"	YACC--type->ARRAY [ NUM . . NUM ] OF standard_type" << endl;
					if($3.dataType != INT_T || $6.dataType != INT_T) {
						parser.yyerror("type -> ARRAY [ NUM . . NUM ] OF standard_type : 数组参数NUM类型错误!");		/////////////////////////////////////////////////////// 现在
						parser.yyerrok();
					}
					$$.id_type = $9.id_type;
					$$.table_type = ARRAY_T;
					$$.array_top = (int)($6.num);
					$$.array_bottom = (int)($3.num);
					if($$.array_top - $$.array_bottom < 0) {
						parser.yyerror("type -> ARRAY [ NUM . . NUM ] OF standard_type : 数组下界不可小于上界!");
						parser.yyerrok();
					}
					$$.targetCode = new string(($9.targetCode)->data());
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| RECORD declaration END
				{
					debug_stream<<"	YACC--type->RECORD declaration END" << endl;
					$$.id_type = RECORD_T;
					$$.table_type = VARIBLE_T;
					string tmp_target = "struct {\n" + string($2->data()) + "\n} ";
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				};

standard_type : INTEGER
				{
					debug_stream<<"	YACC--standard_type->INTEGER" << endl;
					$$.id_type = INT_T;
					$$.table_type = VARIBLE_T;
					$$.targetCode = new string("int");
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| REAL
				{
					debug_stream<<"	YACC--standard_type->REAL" << endl;
					$$.id_type = REAL_T;
					$$.table_type = VARIBLE_T;
					$$.targetCode = new string("double ");
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| BOOLEAN
				{
					debug_stream<<"	YACC--standard_type->BOOLEAN" << endl;
					$$.id_type = BOOL_T;
					$$.table_type = VARIBLE_T;
					$$.targetCode = new string("bool ");
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				};

subprogram_declarations : subprogram_declarations subprogram_declaration ';'
				{
					debug_stream << "	YACC--subprogram_declarations->subprogram_declarations subprogram_declaration ;" << endl;
					string tmp_target = string($1->data()) + "\n" +  string($2->data());
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				|
				{
					debug_stream << "	YACC--subprogram_declarations->NULL"<<endl;
					$$ = new string("");
					debug_stream << "	data() = " << ($$)->data() << endl;
					 // do nothing
				};

subprogram_declaration : subprogram_head declarations compound_statement
				{
					debug_stream << "	YACC--subprogram_declaration->subprogram_head declarations compound_statement" << endl;
					string tmp_target =  string($1->data()) + "\n" +  string($2->data()) + "\n" +  string($3->data()) + "\n}";
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
					// 在这里重定向
					sym_table.relocate();
					currentFunction = "";
				};

subprogram_head : FUNCTION ID arguments ':' standard_type ';'
				{
					debug_stream << "	YACC--subprogram_head->FUNCTION ID arguments : standard_type ;" << endl;

					// 更新functionTable
					functionInfo funcID_In;
					funcID_In.declareRow = lexer.yylineno;
					funcID_In.retType = $5.id_type;
					funcID_In.paraNum = paraList.idNameList.size();

					int i;
					for(i = 0; i < ($3.paraType)->size(); i++)	{
						funcID_In.paraType.push_back(paraList.dataTypeList[i]);
						funcID_In.tableType.push_back(paraList.tableTypeList[i]);
					}

					if(sym_table.insert(string($2->data()), funcID_In) == NULL) {
						parser.yyerror("subprogram_head -> FUNCTION ID arguments : standard_type ; : redefined function id!");
						parser.yyerrok();
					}
					//定向
					sym_table.locate();
					//更新当前函数名
					currentFunction = string($2->data());

					//更新符号表，将参数列表插入到符号表中
					int j = 0;
					for(i = 0;i < paraList.idNameList.size();i++){
						if(paraList.tableTypeList[i] == VARIBLE_T){
							varInfo varTemp;
							varTemp.type = paraList.dataTypeList[i];
							varTemp.declareRow = lexer.yylineno;
							// 插入到符号表
							if(sym_table.insert(paraList.idNameList[i], varTemp) == NULL) {
								parser.yyerror("parameter_list -> VAR identifier_list : type : redefined variable id in identifier_list!");
								parser.yyerrok();
							}

						}
						else if(paraList.tableTypeList[i] == ARRAY_T){
							arrayInfo declare_In;
							declare_In.type = paraList.dataTypeList[i];
							declare_In.low = arrayList.lowList[j];
							declare_In.high = arrayList.highList[j];
							j++;
							declare_In.declareRow = lexer.yylineno;

							// 插入到符号表
							if(sym_table.insert(paraList.idNameList[i], declare_In) == NULL) {
								parser.yyerror("parameter_list -> VAR identifier_list : type : redefined array id in identifier_list!");
								parser.yyerrok();
							}

						}
					}

					//清空缓存
					paraList.idNameList.clear();
					paraList.dataTypeList.clear();
					paraList.tableTypeList.clear();
					arrayList.lowList.clear();
					arrayList.highList.clear();

					// 生成目标代码
					string tmp_target =  string(($5.targetCode)->data()) + " " +  string($2->data()) +  string(($3.targetCode)->data()) + " {";
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				| FUNCTION ID arguments error
				{
					debug_stream << "	YACC--subprogram_head->FUNCTION ID arguments error" << endl;
					parser.yyerror("subprogram_head -> FUNCTION ID arguments error : function without a return type!");
					parser.yyerrok();
					string tmp_target = "void " +  string($2->data()) +  string(($3.targetCode)->data()) + " {";
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				| PROCEDURE ID arguments ';'
				{
					debug_stream << "	YACC--subprogram_head->PROCEDURE ID arguments" << endl;

					// 写入程序ID
					procedureInfo porcID_In;
					porcID_In.declareRow = lexer.yylineno;
					porcID_In.paraNum = ($3.paraType)->size();
					int i;
					for(i = 0; i < ($3.paraType)->size(); i++)	{
						porcID_In.paraType.push_back((*($3.paraType))[i]);
					}

					if(sym_table.insert(string($2->data()), porcID_In) == NULL) {
						parser.yyerror("subprogram_head -> PROCEDURE ID arguments : redefined procedure id!");
						parser.yyerrok();
					}

					// 新块，定向
					sym_table.locate();

					//更新符号表，将参数列表插入到符号表中
					int j = 0;
					for(i = 0;i < paraList.idNameList.size();i++){
						if(paraList.tableTypeList[i] == VARIBLE_T){
							varInfo varTemp;
							varTemp.type = paraList.dataTypeList[i];
							varTemp.declareRow = lexer.yylineno;
							// 插入到符号表
							if(sym_table.insert(paraList.idNameList[i], varTemp) == NULL) {
								parser.yyerror("parameter_list -> VAR identifier_list : type : redefined variable id in identifier_list!");
								parser.yyerrok();
							}
						}
						else if(paraList.tableTypeList[i] == ARRAY_T){
							arrayInfo declare_In;
							declare_In.type = paraList.dataTypeList[i];
							declare_In.low = arrayList.lowList[j];
							declare_In.high = arrayList.highList[j];
							j++;
							declare_In.declareRow = lexer.yylineno;

							// 插入到符号表
							if(sym_table.insert(paraList.idNameList[i], declare_In) == NULL) {
								parser.yyerror("parameter_list -> VAR identifier_list : type : redefined array id in identifier_list!");
								parser.yyerrok();
							}

						}
					}
					//清空缓存
					paraList.idNameList.clear();
					paraList.dataTypeList.clear();
					paraList.tableTypeList.clear();
					arrayList.lowList.clear();
					arrayList.highList.clear();

					// 生成目标代码
					string tmp_target = "void " +  string($2->data()) +  string(($3.targetCode)->data()) + "{";
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				| PROCEDURE ID arguments error ';'
				{
					debug_stream << "	YACC--subprogram_head->PROCEDURE ID arguments error" << endl;
					// 报错
					parser.yyerror("subprogram_head -> PROCEDURE ID arguments error:  procedure cannot have a return type!");
					parser.yyerrok();

					// 新块，定向
					sym_table.locate();

					// 写入程序ID
					procedureInfo porcID_In;
					porcID_In.declareRow = lexer.yylineno;
					porcID_In.paraNum = ($3.paraType)->size();
					for(int i = 0; i < ($3.paraType)->size(); i++)	{
						porcID_In.paraType.push_back((*($3.paraType))[i]);
					}

					if(sym_table.insert(string($2->data()), porcID_In) == NULL) {
						parser.yyerror("subprogram_head -> PROCEDURE ID arguments : redefined procedure id!");
						parser.yyerrok();
					}

					// 生成目标代码
					string tmp_target = "void " +  string($2->data()) +  string(($3.targetCode)->data()) + "{";
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				};


arguments : '(' parameter_lists ')'
				{
					debug_stream << "	YACC--arguments->( parameter_lists )" << endl;
					// 传值
					$$.paraType = new vector <DATA_TYPE>;
					for(int i = 0; i < ($2.paraType)->size(); i++)
					{
						($$.paraType)->push_back((*($2.paraType))[i]);
					}

					// check paraType number of parameter_lists
					debug_stream << "paraType number of parameter_lists is " << ($2.paraType)->size() << endl;

					// target code
					string tmp_code = "(" + string(($2.targetCode)->data()) + ")";
					$$.targetCode = new string(tmp_code);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				|
				{
					debug_stream << "	YACC--arguments->NULL" << endl;
					string tmp_code = "()";
					$$.targetCode = new string(tmp_code);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				};

parameter_lists : parameter_lists ';' parameter_list
				{
					debug_stream << "	YACC--parameter_lists->parameter_lists ; parameter_list" << endl;
					// 传值
					$$.paraType = new vector <DATA_TYPE>;
					int i;
					for(i = 0; i < ($1.paraType)->size(); i++) {
						($$.paraType)->push_back((*($1.paraType))[i]);
					}
					for(i = 0; i < ($3.paraType)->size(); i++) {
						($$.paraType)->push_back((*($3.paraType))[i]);
					}

					// 目标代码
					string tmp_target =  string(($1.targetCode)->data()) + ", " +  string(($3.targetCode)->data());
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| parameter_list
				{
					debug_stream << "	YACC--parameter_lists->parameter_list" << endl;
					// 传值
					$$.paraType = new vector <DATA_TYPE>;
					for(int i = 0; i < ($1.paraType)->size(); i++) {
						($$.paraType)->push_back((*($1.paraType))[i]);
					}
					// check paraType number of parameter_list
					debug_stream << "paraType number of parameter_list is " << ($1.paraType)->size() << endl;
					// 目标代码
					string tmp_target =  string(($1.targetCode)->data()) ;
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				};

parameter_list : VAR identifier_list ':' type
				{
					debug_stream << "	YACC--parameter_list->VAR identifier_list : type" << endl;
					$$.paraType = new vector<DATA_TYPE>;

					if($4.table_type == VARIBLE_T) {
						string tmp_target =  string("");
						for(int i = 0; i < ($2.idNameList)->size(); i++) {
							//更新参数表：
							paraList.idNameList.push_back((*($2.idNameList))[i]);
							paraList.dataTypeList.push_back($4.id_type);
							paraList.tableTypeList.push_back($4.table_type);

							// 生成目标代码
							if(i != ($2.idNameList)->size() - 1)
								tmp_target += string(($4.targetCode)->data()) + " &" + (*($2.idNameList))[i] + ",";
							else
								tmp_target += string(($4.targetCode)->data()) + " &" + (*($2.idNameList))[i];

							// 将identifier_list类型写入到parameter_list中
							$$.paraType->push_back($4.id_type);
						}
						$$.targetCode = new string( tmp_target);
						debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
					}
					else if($4.table_type == ARRAY_T) {
						string tmp_target =  string("");
						for(int i = 0; i < ($2.idNameList)->size(); i++) {

							//更新参数表：
							paraList.idNameList.push_back((*($2.idNameList))[i]);
							paraList.dataTypeList.push_back($4.id_type);
							paraList.tableTypeList.push_back($4.table_type);
							arrayList.lowList.push_back($4.array_bottom);
							arrayList.highList.push_back($4.array_top);

							// 生成目标代码
							if(i != ($2.idNameList)->size() - 1)
								tmp_target += string(($4.targetCode)->data()) + " &" + (*($2.idNameList))[i] + "[],";
							else
								tmp_target += string(($4.targetCode)->data()) + " &" + (*($2.idNameList))[i] + "[]";

							// 将identifier_list类型写入到parameter_list中
							$$.paraType->push_back($4.id_type);
						}
						$$.targetCode = new string(tmp_target);
						debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
					}
				}
				|  identifier_list ':' type
				{
					debug_stream << "	YACC--parameter_list->identifier_list : type" << endl;
					$$.paraType = new vector<DATA_TYPE>;

					if($3.table_type == VARIBLE_T) {
						string tmp_target =  string("");
						for(int i = 0; i < ($1.idNameList)->size(); i++) {
							//更新参数表：
							paraList.idNameList.push_back((*($1.idNameList))[i]);
							paraList.dataTypeList.push_back($3.id_type);
							paraList.tableTypeList.push_back($3.table_type);

							// 生成目标代码
							if(i != ($1.idNameList)->size() - 1)
								tmp_target += string(($3.targetCode)->data()) + " " + (*($1.idNameList))[i] + ",";
							else
								tmp_target += string(($3.targetCode)->data()) + " " + (*($1.idNameList))[i];

							// 将identifier_list类型写入到parameter_list中
							$$.paraType->push_back($3.id_type);
						}
						$$.targetCode = new string( tmp_target);
						debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
					}
					else if($3.table_type == ARRAY_T) {
						string tmp_target =  string("");
						for(int i = 0; i < ($1.idNameList)->size(); i++) {
							//更新参数表：
							paraList.idNameList.push_back((*($1.idNameList))[i]);
							paraList.dataTypeList.push_back($3.id_type);
							paraList.tableTypeList.push_back($3.table_type);
							arrayList.lowList.push_back($3.array_bottom);
							arrayList.highList.push_back($3.array_top);

							// 生成目标代码
							if(i != ($1.idNameList)->size() - 1)
								tmp_target += string(($3.targetCode)->data()) + " " + (*($1.idNameList))[i] + "[],";
							else
								tmp_target += string(($3.targetCode)->data()) + " " + (*($1.idNameList))[i] + "[]";

							// 将identifier_list类型写入到parameter_list中
							$$.paraType->push_back($3.id_type);
						}
						$$.targetCode = new string(tmp_target);
						debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
					}
				};

compound_statement : BEGIN optional_statements END
				{
					debug_stream<<"	YACC--compound_statement->BEGIN optional_statements END"<<endl;
					// begin ... end 如果是function或者procedure的一部分的话不需要加"{"。("{"在function或者procedure那写)
					string tmp_target = "";
					tmp_target = tmp_target + "{\n";
					tmp_target = tmp_target + string($2->data()) + "\n}// translate from END";

					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				};

optional_statements : statement_list
				{
					debug_stream<<"	YACC--optional_statements->statement_list"<<endl;
					string tmp_target =  string($1->data());
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				|
				{
					debug_stream<<"	YACC-optional_statements->NULL"<<endl;
					$$ = new string("");
					debug_stream << "	data() = " << ($$)->data() << endl;
				};

statement_list : statement_list ';' statement
				{
					debug_stream << "	YACC--statement_list->statement_list ; statement"<<endl;
					string tmp_target =  string($1->data()) + "\n" +  string($3->data());
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				| statement
				{
					debug_stream << "	YACC--statement_list->statement"<<endl;
					string tmp_target =  string($1->data());
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				};

statement : variable ASSIGNOP expression
				{
					debug_stream<<"	YACC--statement->variable ASSIGNOP expression"<<endl;
					if(($1.value_type != $3.value_type) && !($1.value_type == REAL_T && $3.value_type == INT_T))
					{
						// 报错
						parser.yyerror("statement -> variable ASSIGNOP expression : 赋值类型不匹配。");
						parser.yyerrok();
					}
					// target code
					string tmp_target;
					if(needReturn == true){
						tmp_target =  string(($1.targetCode)->data())  + " " + string(($3.targetCode)->data()) + ";";
						needReturn = false;
					}
					else{
						tmp_target =  string(($1.targetCode)->data()) + " = " +  string(($3.targetCode)->data()) + ";";
					}

					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				| procedure_call_statement
				{
					debug_stream<<"	YACC--statement->procedure_call_statement"<<endl;
					// target code
					string tmp_target =  string(($1)->data()) + ";";
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				| compound_statement
				{
					debug_stream<<"	YACC--statement->compound_statement"<<endl;
					// target code
					string tmp_target =  string(($1)->data());
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				| IF expression THEN statement
				{
					debug_stream<<"	YACC--statement->IF expression THEN statement ELSE statement"<<endl;
					// value_type check
					if($2.value_type != BOOL_T && $2.value_type != INT_T)
					{
						// 报错
						parser.yyerror("if 语句条件只能是int 或者bool类型哦亲");
						parser.yyerrok();
					}
					// target code
					string tmp_target = "if(" +  string(($2.targetCode)->data()) + ")\n	" +  string(($4)->data()) + "\n";
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				| IF expression THEN statement ELSE statement
				{
					debug_stream<<"	YACC--statement->IF expression THEN statement ELSE statement"<<endl;
					// value_type check
					if($2.value_type != BOOL_T && $2.value_type != INT_T)
					{
						// 报错
						parser.yyerror("if 语句条件只能是int 或者bool类型哦亲");
						parser.yyerrok();
					}
					// target code
					string tmp_target = "if(" +  string(($2.targetCode)->data()) + ")\n	" +  string(($4)->data()) + "\n";
					tmp_target += "else\n{\n	" + string(($6)->data()) + "\n}\n";
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				| WHILE expression DO statement
				{
					debug_stream<<"	YACC--statement->WHILE expression DO statement"<<endl;
					// value_type check
					if($2.value_type != BOOL_T && $2.value_type != INT_T)
					{
						// 报错
						parser.yyerror("while 语句条件只能是int 或者bool类型哦亲");
						parser.yyerrok();
					}
					// target code
					string tmp_target = "while(" +  string(($2.targetCode)->data()) + ")\n	" +  string(($4)->data()) + "\n";
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				| READ '(' identifier_list ')'
				{
					debug_stream<<"	YACC--statement->READ ( identifier_list )"<<endl;
				    // target code
					string tmp_target = "cin";

					// 检查读入变量是否已经定义
					for(int i = 0; i < ($3.idNameList)->size(); i++) {
						symbolTableItem* check = sym_table.get((*($3.idNameList))[i]);
						if(check == NULL ) {
							parser.yyerror("statement -> READ ( identifier_list ) : undefined identifiers in identifier_list!");
							parser.yyerrok();
						}
						else if(check->type != VARIBLE_T){
							parser.yyerror("statement -> READ ( identifier_list ) : identifiers type is not right!");
							parser.yyerrok();
						}

						//更新targetcode
						tmp_target += " >> " + (*($3.idNameList))[i];
					}
					if(($3.idNameList)->size() == 0){
						parser.yyerror(" -> READ ( identifier_list ) : identifier_list cannot be empty!");
						parser.yyerrok();
					}
					tmp_target += ";\n";
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				| WRITE '(' expr_list ')'
				{
					debug_stream<<"	YACC--statement->WRITE ( expr_list )"<<endl;
					// target code
					string tmp_target = "cout ";

					//检查表达式的合法性以及生成目标代码
					for(int i = 0; i < ($3.idNameList)->size(); i++) {
						//write参数不可以有数组类型
						if((*($3.tableTypeList))[i] == ARRAY_T ) {
							parser.yyerror("write函数参数不能有数组！");
						    parser.yyerrok();
						}
						else{
							//更新targetcode
						   tmp_target += "<<" + (*($3.idNameList))[i];
						}
					}

					if(($3.idNameList)->size() == 0){
						parser.yyerror("statement -> WRITE ( identifier_list ) : identifier_list cannot be empty!");
						parser.yyerrok();
					}

					tmp_target += ";\n";
					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				};

variable : ID
				{
					debug_stream<<"	YACC--variable->ID "<<endl;
					// 检查读入变量是否已经定义
					symbolTableItem* check = sym_table.get(string($1->data()));
				    $$.targetCode = new string("");
				    //符号表中不存在或标识符不是变量
					if(check == NULL) {
						parser.yyerror("variable -> ID : ID not defined!");
						parser.yyerrok();
					}
					else if(check->type == VARIBLE_T){
						$$.value_type = sym_table.getVariableType(check->address);
						$$.targetCode = new string($1->data());
					}
					else if(check->type == FUNCTION_T){
						if(currentFunction == string($1->data())){
							functionInfo* funcInfo = sym_table.getFunction(check->address);
							if(funcInfo->retType == VOID){
								parser.yyerror("variable -> ID : this function don't have return vaule!");
								parser.yyerrok();
							}
							else{
								//函数返回
								$$.value_type = funcInfo->retType;
								$$.targetCode = new string("return");
								needReturn = true;
							}

						}
						else{
							parser.yyerror("variable -> ID : return ID is wrong!");
							parser.yyerrok();
						}
					}
					else{
						parser.yyerror("variable -> ID : ID here can only be VARIBLE_T or FUNCTION_T!");
						parser.yyerrok();
					}
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| ID '[' expression ']'
				{
					debug_stream<<"	YACC--variable->ID [ expression ]"<<endl;
					// 检查是否已经定义
					symbolTableItem* check = sym_table.get(string($1->data()));
				    //符号表中不存在或标识符不是数组
					if(check == NULL || check->type != ARRAY_T ) {
							parser.yyerror("variable -> ID [ expression ] : id can only be an array!");
							parser.yyerrok();
					}
					else{
						arrayInfo* arrInfo = sym_table.getArray(check->address);
						$$.value_type = arrInfo->type;
					}
					// 检查expression类型是不是int
					if($3.value_type != INT_T)
					{
						parser.yyerror("variable -> ID [ expression ] : expression needs to be of integer type!");
						parser.yyerrok();
					}
					// target code
					string tmp_target =  string($1->data()) + "[" +  string($3.targetCode->data()) + "]";
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				};

procedure_call_statement : ID
				{
					debug_stream<<"	YACC--procedure_call_statement->ID"<<endl;
					symbolTableItem* check = sym_table.get(string($1->data()));
					// target code
					string tmp_target = "";
				    // 检查是否已经定义
					if(check == NULL) {
							parser.yyerror("procedure_call_statement -> ID : id not defined !");
							parser.yyerrok();
					}
					else {
						if(check->type == PROCEDURE_T || check->type == FUNCTION_T) {
							tmp_target =  string($1->data()) + "();\n";
						}
						else {
							tmp_target =  string($1->data()) + ";\n";
						}
					}

					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				| ID '(' expr_list ')'
				{
					debug_stream<<"	YACC--procedure_call_statement->ID ( expr_list )"<<endl;
					string tmp_target =  string("");
					symbolTableItem* check = sym_table.get(string($1->data()));
				    // 检查是否已经定义
					if(check == NULL) {
						parser.yyerror("procedure_call_statement -> ID ( expr_list ): id not defined!");
						parser.yyerrok();
					}
					else if(check->type == PROCEDURE_T) {
						procedureInfo* proceInfo = sym_table.getProcedure(check->address);
						if(($3.idNameList)->size() != proceInfo->paraNum) {

						}
						else {
							for(int i = 0; i < ($3.idNameList)->size(); i++)
							{
								if((*($3.dataTypeList))[i] != (proceInfo->paraType)[i]) {
									parser.yyerror("procedure_call_statement -> ID ( expr_list ) : 过程参数类型不匹配。");
									parser.yyerrok();
								}
							} // end of for

							tmp_target = string($1->data()) + "(" + string(($3.targetCode)->data()) + ");\n";

						} // end of else
					} // end of outer if
					else if(check->type == FUNCTION_T) {
						functionInfo* funcInfo = sym_table.getFunction(check->address);
						if(($3.idNameList)->size() != funcInfo->paraNum) {
							parser.yyerror("procedure_call_statement -> ID ( expr_list ) : 子程序参数个数不匹配。");
							parser.yyerrok();
						}
						else {
							for(int i = 0; i < ($3.idNameList)->size(); i++)
							{
								if((*($3.dataTypeList))[i] != (funcInfo->paraType)[i]) {
									parser.yyerror("procedure_call_statement -> ID ( expr_list ) : 子程序参数类型不匹配。");
									parser.yyerrok();
								}
							} // end of for

							tmp_target = string($1->data()) + "(" + string(($3.targetCode)->data()) + ");\n";

						} // end of else
					} // end of else if
					else{
						parser.yyerror("procedure_call_statement -> ID ( expr_list ) : 过程参数个数不匹配!");
						parser.yyerrok();
					}

					$$ = new string(tmp_target);
					debug_stream << "	data() = " << ($$)->data() << endl;
				};

expr_list : expr_list ',' expression
				{
					debug_stream<<"	YACC--expr_list->expr_list , expression"<<endl;
					$$.idNameList = new vector <string>;
					$$.dataTypeList = new vector <DATA_TYPE>;
					$$.tableTypeList = new vector <TABLE_TYPE>;
					// 记录已经存入的值
					for(int i = 0; i < ($1.idNameList)->size(); i++) {
						($$.idNameList)->push_back((*($1.idNameList))[i]);
						($$.dataTypeList)->push_back((*($1.dataTypeList))[i]);
						($$.tableTypeList)->push_back((*($1.tableTypeList))[i]);
					} // end of for
					// 写入新值
					($$.idNameList)->push_back(string(($3.targetCode)->data()));
					($$.dataTypeList)->push_back($3.value_type);
					($$.tableTypeList)->push_back($3.table_type);
					// target code
					string tmp_target =  string(($1.targetCode)->data()) + ", " +  string(($3.targetCode)->data());
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| expression
				{
					debug_stream<<"	YACC--expr_list->expression"<<endl;
					$$.idNameList = new vector <string>;
					$$.dataTypeList = new vector <DATA_TYPE>;
					$$.tableTypeList = new vector <TABLE_TYPE>;
					// 写入新值
					($$.idNameList)->push_back(string(($1.targetCode)->data()));
					($$.dataTypeList)->push_back($1.value_type);
					($$.tableTypeList)->push_back($1.table_type);
					// target code
					string tmp_target =  string(($1.targetCode)->data());
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				};

expression : simple_expr RELOP simple_expr
				{
					debug_stream<<"	YACC--expression->simple_expr RELOP simple_expr"<<endl;
					$$.value_type = BOOL_T;
					$$.table_type = VARIBLE_T;
					string tmp_target =  string("");

					if($1.table_type != VARIBLE_T || $3.table_type != VARIBLE_T) {
						parser.yyerror("expression -> simple_expr RELOP simple_expr : simple_expr can only be int, real or bool!");
						parser.yyerrok();
					}
					if($1.value_type == BOOL_T && $3.value_type == BOOL_T) {
						if(string($2->data()) == "<>") {
							$2 = new string("!=");
						}
					}
					else if(($1.value_type == INT_T || $1.value_type == REAL_T) && ($3.value_type == INT_T || $3.value_type == REAL_T)) {
						if(string($2->data()) == "<>") {
							$2 = new string("!=");
						}
						if(string($2->data()) == "=") {
							$2 = new string("==");
						}
					}
					else {
							parser.yyerror("expression -> simple_expr RELOP simple_expr : 关系运算类型匹配出错！");
							parser.yyerrok();
					}
					tmp_target = string(($1.targetCode)->data()) + string(($2)->data()) + string(($3.targetCode)->data());
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| simple_expr
				{
					debug_stream<<"	YACC--expression->simple_expr"<<endl;
					$$.value_type = $1.value_type;
					$$.table_type = $1.table_type;
					$$.targetCode = new string(($1.targetCode)->data());
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				};

simple_expr : simple_expr ADDOP term
				{
					string tmp_target = string("");
					$$.table_type = VARIBLE_T;
					if($1.table_type != VARIBLE_T || $3.table_type != VARIBLE_T) {
						parser.yyerror("simple_expr -> simple_expr ADDOP simple_expr : simple_expr can only be int, real or bool!");
						parser.yyerrok();
					}
					if(string($2->data()) == "or") {
						$$.value_type = BOOL_T;
						if($1.value_type != BOOL_T || $3.value_type != BOOL_T) {
							parser.yyerror("simple_expr -> simple_expr ADDOP simple_expr : 或运算类型匹配出错！");
							parser.yyerrok();
						}
						else {
							// target code
							tmp_target = string(($1.targetCode)->data()) + " || " + string(($3.targetCode)->data());
						}
					} // end of if
					else {
						if(($1.value_type == INT_T || $1.value_type == REAL_T) && ($3.value_type == INT_T || $3.value_type == REAL_T)) {
							if( $1.value_type == REAL_T ||  $3.value_type == REAL_T) {
								$$.value_type = REAL_T;
							}
							else {
								$$.value_type = INT_T;
							}
						}
						else {
							parser.yyerror("simple_expr -> simple_expr ADDOP simple_expr : ADDOP运算类型匹配出错！");
							parser.yyerrok();
						}
						// target code
						tmp_target = string(($1.targetCode)->data()) + string($2->data()) + string(($3.targetCode)->data());
					} // end of else
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| term
				{
					debug_stream<<"	YACC--expression->term"<<endl;
					$$.value_type = $1.value_type;
					$$.table_type = $1.table_type;
					$$.targetCode = new string( ($1.targetCode)->data());
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| sign term
				{
					debug_stream<<"	YACC--expression->sign term"<<endl;
					$$.value_type = $2.value_type;
					$$.table_type = $2.table_type;
					$$.targetCode = new string(string($1->data()) +string(($2.targetCode)->data()));
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				};

term : term MULOP factor
				{
					debug_stream<<"	YACC--term->term MULOP factor"<<endl;
					string tmp_target = string("");
					$$.table_type = VARIBLE_T;
					if($1.table_type != VARIBLE_T || $3.table_type != VARIBLE_T) {
						parser.yyerror("expression -> simple_expr MULOP simple_expr : simple_expr can only be int, real or bool!!");
						parser.yyerrok();
					}
					if(string($2->data()) == "and") {
						$$.value_type = BOOL_T;
						if($1.value_type != BOOL_T || $3.value_type != BOOL_T) {
							parser.yyerror("expression -> simple_expr MULOP simple_expr : 与运算类型匹配出错！");
							parser.yyerrok();
						}
						else {
							// target code
							tmp_target = string(($1.targetCode)->data()) + " && " + string(($3.targetCode)->data());
						}
					} // end of if
					else if(string($2->data()) == "div") {
						$$.value_type = INT_T;
						if($1.value_type != INT_T || $3.value_type != INT_T) {
							parser.yyerror("expression -> simple_expr MULOP simple_expr : div运算类型匹配出错！");
							parser.yyerrok();
						}
						else {
							// target code
							tmp_target = string(($1.targetCode)->data()) + " / " + string(($3.targetCode)->data());
						}
					} // end of else if
					else if(string($2->data()) == "mod") {
						$$.value_type = INT_T;
						if($1.value_type != INT_T || $3.value_type != INT_T) {
							parser.yyerror("expression -> simple_expr MULOP simple_expr : mod运算类型匹配出错！");
							parser.yyerrok();
						}
						else {
							// target code
							tmp_target = string(($1.targetCode)->data()) + " % " + string(($3.targetCode)->data());
						}
					} // end of if
					else {
						if(($1.value_type == INT_T || $1.value_type == REAL_T) && ($3.value_type == INT_T || $3.value_type == REAL_T)) {
							if( $1.value_type == REAL_T ||  $3.value_type == REAL_T) {
								$$.value_type = REAL_T;
							}
							else {
								$$.value_type = INT_T;
							}
						}
						else {
							parser.yyerror("expression -> simple_expr MULOP simple_expr : MULOP运算类型匹配出错！");
							parser.yyerrok();
						}
						// target code
						tmp_target = string(($1.targetCode)->data()) + string($2->data()) + string(($3.targetCode)->data());
					} // end of else
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| factor
				{
					debug_stream<<"	YACC--term->factor"<<endl;
					$$.value_type = $1.value_type;
					$$.table_type = $1.table_type;
					$$.targetCode = new string(($1.targetCode)->data());
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				};

factor : ID
				{
					debug_stream<<"	YACC--factor->ID"<<endl;
					string tmp_target = string("");
					symbolTableItem* check = sym_table.get(string($1->data()));
					if(check == NULL) {
						parser.yyerror("factor -> ID : ID not defined 或者是 参数为过程");
						parser.yyerrok();
					}
					else if(check->type == PROCEDURE_T) {
						parser.yyerror("factor -> ID : ID cannot be a procedure!");
						parser.yyerrok();
					}
					else{
						if(check->type == FUNCTION_T) {
							functionInfo* funcInfo = sym_table.getFunction(check->address);
							if( funcInfo->paraNum > 0) {
								parser.yyerror("factor -> ID : 子函数参数个数不匹配!");
								parser.yyerrok();
							}
						else {
								tmp_target = string($1->data()) + "()";
								$$.value_type = funcInfo->retType;
								$$.table_type = VARIBLE_T;
							} // end of else
						} // end of else if
						else if(check->type == ARRAY_T) {
							arrayInfo* arraInfo = sym_table.getArray(check->address);
							tmp_target = string($1->data());
							$$.value_type = arraInfo->type;
							$$.table_type = ARRAY_T;
						} // end of else if
						else if(check->type == VARIBLE_T) {
							tmp_target = string($1->data());
							$$.value_type = sym_table.getVariableType(check->address);
							$$.table_type = VARIBLE_T;
						} // end of else if
					}
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| ID '(' expr_list ')'
				{
					debug_stream<<"	YACC--factor->ID ( expr_list )"<<endl;
					string tmp_target =  string("");
					symbolTableItem* check = sym_table.get(string($1->data()));
				    // 检查是否已经定义
					if(check == NULL) {
							parser.yyerror("factor -> ID ( expr_list ) : ID not defined!");
							cout << "		ID = " << string($1->data()) << endl;
							parser.yyerrok();
					}
					else if(check->type != FUNCTION_T) {
							parser.yyerror("factor -> ID ( expr_list ) : ID is not a function!");
							parser.yyerrok();
					}
					else{
						if(check->type == FUNCTION_T) {
							functionInfo* funcInfo = sym_table.getFunction(check->address);
							if(($3.idNameList)->size() != funcInfo->paraNum) {
								parser.yyerror("factor -> ID ( expr_list ) : 子函数参数个数不匹配!");
								cout << "		should have: " << funcInfo->paraNum << ", now have: " << ($3.idNameList)->size() << endl;
								// for(int i = 0; i < funcInfo->paraNum; i++)
								// {
									// cout << funcInfo->paraType[i] << ", ";
								// }
								// cout << endl;
								parser.yyerrok();
							}
							else {
								for(int i = 0; i < ($3.idNameList)->size(); i++)
								{
									if((*($3.tableTypeList))[i] != (funcInfo->tableType)[i]) {
										parser.yyerror("factor -> ID ( expr_list ) : 子函数参数类型不匹配!（如：数组变量传递给基本类型变量）");
										parser.yyerrok();
									}

									if((*($3.dataTypeList))[i] != (funcInfo->paraType)[i]) {
										parser.yyerror("factor -> ID ( expr_list ) : 子函数参数数据类型不匹配!（如int变量传递给bool变量）");
										parser.yyerrok();
									}
								} // end of for
								$$.value_type = funcInfo->retType;
								$$.table_type = VARIBLE_T;
								tmp_target = string($1->data()) + "(" + string(($3.targetCode)->data()) + ")";

							} // end of else
						} // end of if
						else if(check->type == PROCEDURE_T) {
							procedureInfo* procInfo = sym_table.getProcedure(check->address);
							if(($3.idNameList)->size() != procInfo->paraNum) {
								parser.yyerror("factor -> ID ( expr_list ) : 子函数参数个数不匹配!");
								parser.yyerrok();
							}
							else {
								for(int i = 0; i < ($3.idNameList)->size(); i++)
								{
									if((*($3.dataTypeList))[i] != (procInfo->paraType)[i]) {
										parser.yyerror("factor -> ID ( expr_list ) : 子函数参数类型不匹配!");
										parser.yyerrok();
									}
								} // end of for
								$$.value_type = VOID;
								$$.table_type = PROCEDURE_T;
								tmp_target = string($1->data()) + "(" + string(($3.targetCode)->data()) + ")";

							} // end of else
						}
					}
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| ID '[' expression ']'
				{
					debug_stream<<"	YACC--factor->ID [ expr_list ]"<<endl;
					string tmp_target =  string("");
					// 查询符号表
					symbolTableItem* check = sym_table.get(string($1->data()));
					// 检查是否已经定义
					if(check == NULL) {
							parser.yyerror("factor -> ID ( expr_list ) : ID not defined!");
							parser.yyerrok();
					}
					else {
						// 检查id是否数组类型
						if(check->type != ARRAY_T) {
							parser.yyerror("factor -> id [ expression ] : id is not an array!");
							parser.yyerrok();
						}
						// 检查expr_list是否整类型
						if( ($3.table_type != VARIBLE_T) || ($3.value_type != INT_T) ) {
							parser.yyerror("factor -> id [ expression ] : expression not of integer type!");
							parser.yyerrok();
						}
						// 记录factor类型
						arrayInfo* arrayInfo = sym_table.getArray(check->address);
						$$.value_type = arrayInfo->type;
						$$.table_type = VARIBLE_T;
						tmp_target = string($1->data()) + "[" + string(($3.targetCode)->data()) + "]";
					} // end of else
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| NUM
				{
					debug_stream<<"	YACC--factor->NUM"<<endl;
					$$.value_type = $1.dataType; //////////////////////////////////////////////////////////这里有问题，按照现在这样处理，这个num总是real类型，但实际上num可能是int型
					$$.table_type = VARIBLE_T;
					$$.targetCode = new string(($1.targetCode)->data());
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| '(' expression ')'
				{
					debug_stream<<"	YACC--factor->( expression )"<<endl;
					$$.value_type = $2.value_type;
					$$.table_type = $2.table_type;
					string tmp_target = "(" + string(($2.targetCode)->data()) + ")";
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| NOT factor
				{
					debug_stream<<"	YACC--factor->NOT factor"<<endl;
					// 检查factor类型
					if($2.value_type != BOOL_T || $2.table_type != VARIBLE_T) {
						parser.yyerror("factor -> NOT factor : rear factor has to be bool");
						parser.yyerrok();
					}
					$$.value_type = $2.value_type;
					$$.table_type = $2.table_type;
					string tmp_target = "!(" + string(($2.targetCode)->data()) + ")";
					$$.targetCode = new string(tmp_target);
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| TRUE
				{
					debug_stream<<"	YACC--factor->TRUE"<<endl;
					$$.value_type = BOOL_T;
					$$.table_type = VARIBLE_T;
					$$.targetCode = new string("true");
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				}
				| FALSE
				{
					debug_stream<<"	YACC--factor->TRUE"<<endl;
					$$.value_type = BOOL_T;
					$$.table_type = VARIBLE_T;
					$$.targetCode = new string("false");
					debug_stream << "	data() = " << ($$.targetCode)->data() << endl;
				};

sign : '+'
				{
					debug_stream<<"	YACC--sign->+"<<endl;
					$$ = new string("+");
					debug_stream << "	data() = " << ($$)->data() << endl;
				}
				| '-'
				{
					debug_stream<<"	YACC--sign->-"<<endl;
					$$ = new string("-");
					debug_stream << "	data() = " << ($$)->data() << endl;
				};

%%

/////////////////////////////////////////////////////////////////////////////
// programs section

int main(void)
{

	int n = 1;
	/*
	string sourceFile;
	string targetFile;

	// 读入PASCAL源文件
	cout<<"请输入pascal的源文件名:";
	cin>>sourceFile;
	in_stream.open(sourceFile.data());
	lexer.yyin=&in_stream;//把读入文件名赋予词法分析
	if(!in_stream)
	{
		printf("pascal的源文件打开失败！\n");
	    return 0;
	}
	if(lexer.yyin==NULL)
	{
	    printf("pascal的源文件打开失败！\n");
	    return 0;
	}
	// 确认输出目标文件
	cout<<"请输入cpp文件名:";
	cin>>targetFile;
	out_stream.open(targetFile.data());
	lexer.yyout=&out_stream;
	if(!out_stream)
	{
	    printf("生成目标文件失败！\n");
	    return 0;
	}
	if(lexer.yyout==NULL)
	{
	    printf("生成目标文件失败！\n");
	    return 0;
	}
	*/

	in_stream.open("E:/pascal/source_code.txt");
	lexer.yyin=&in_stream;//把读入文件名赋予词法分析

	out_stream.open("E:/pascal/target_code.txt", ios::out);
	lexer.yyout=&out_stream;

	// 打开错误信息输出流
	error_stream.open("E:/pascal/pascal error.txt", ios::out);
	if(error_stream.fail())
	{
		printf("failed to open debug_stream.\n");
	    return 0;
	}

	// 打开调试输出流
	debug_stream.open("E:/pascal/pascal debug.txt", ios::out);
	if(debug_stream.fail())
	{
		printf("failed to open debug_stream.\n");
	    return 0;
	}

	// 开始分析
	if (parser.yycreate(&lexer)) {//分析程序
		if (lexer.yycreate(&parser)) {
			n = parser.yyparse();
		}
	}
	in_stream.close();
	out_stream.close();
	return n;
}

void Parser::yyerror(const char *s)
{
	cerr<<"ERROR - line "<<lexer.yylineno<<": "<<s<<endl;
	error_stream << "ERROR - line " << lexer.yylineno << ": " << s << endl;
}