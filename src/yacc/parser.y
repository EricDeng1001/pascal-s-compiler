%{

#include <string>
#include <vector>
#include <map>
#include <utility>
#include <iostream>
#include <cstdio>
#include <fstream>
#include <sstream>

#include "../symbol_table/symbol_table.h"

using namespace std;
using namespace PascalSToCPP;

SymbolTable sym_table;
%}

%union
{
	string targetCode;

	struct
	{
		double num;
		Type type;
	  string targetCode;
	} targetDigitCode;

	struct
	{
		vector <string> names;
	} idList;

	struct
	{
		vector <string> names;
	  vector <Type> types;
	  string targetCode;
	} exprList;

	struct
	{
		Type type;
		int arrayTop;
		int arrayBottom;
		string targetCode;
	} typeStruct;

	struct
	{
		vector <Type> paraType;
		string targetCode;
	} parameterStruct;

	struct
	{
		Type type;
		string targetCode;
	}expStruct;

}

%token <targetCode> PROGRAM  VAR  ARRAY  OF  RECORD  INTEGER
								 REAL  BOOLEAN  FUNCTION  PROCEDURE  DO
								 BEGIN  IF  THEN  END  NOT  WHILE  READ
								 WRITE  ELSE  TRUE  FALSE

%token <targetCode> RELOP  ADDOP  MULOP  ASSIGNOP

%token <targetCode>	ID

%token <targetDigitCode> NUM

%type <targetCode>  program  program_head  subprogram_head   program_body declarations  declaration
					subprogram_declarations  subprogram_declaration statement    compound_statement
					optional_statements  procedure_call_statement statement_list  sign

%type <idList> identifier_list

%type <exprList> expr_list

%type <typeStruct> type  standard_type

%type <expStruct> variable expression  simple_expr  term factor

%type <parameterStruct> parameter_list  parameter_lists  arguments

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

				}
				|
				{

				};

subprogram_declaration : subprogram_head declarations compound_statement
				{

				};

subprogram_head : FUNCTION ID arguments ':' standard_type ';'
				{

				}
				| FUNCTION ID arguments error
				{

				| PROCEDURE ID arguments ';'
				{

				}
				| PROCEDURE ID arguments error ';'
				{

				};


arguments : '(' parameter_lists ')'
				{

				}
				|
				{

				};

parameter_lists : parameter_lists ';' parameter_list
				{

				}
				| parameter_list
				{

				};

parameter_list : VAR identifier_list ':' type
				{

				}
				|  identifier_list ':' type
				{

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