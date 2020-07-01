%{
#include <string>
#include <vector>
#include <map>
#include <utility>
#include <iostream>
#include <fstream>
#include "parser.tab.h"
#define YY_USER_ACTION yylloc.first_line = yylloc.last_line = yylineno;
using namespace std;
%}

%option yylineno caseless

white_space       [ \t\n\r]+
digit             [0-9]
digits		      [0-9]+
fraction          (\.{digits})?
exponent          (\(E\([-+]?\){digits}\))?
num               {digits}{fraction}{exponent}

letter            [A-Za-z]
id                {letter}({letter}|{digit})*
charliteral       '([A-Za-z :,\.]|(\\n)|(\\t))+'
block_annotation  \{\*.*\*\}
line_annotation   \{.*\}
annotation        {block_annotation}|{line_annotation}

%%


program                           {yylval.targetCode = new string(yytext); return TOK_PROGRAM;}
const							  {yylval.targetCode = new string(yytext); return TOK_CONST;}
var								  {yylval.targetCode = new string(yytext); return TOK_VAR;}
array                             {yylval.targetCode = new string(yytext); return TOK_ARRAY;}
of                                {yylval.targetCode = new string(yytext); return TOK_OF;}
record                            {yylval.targetCode = new string(yytext); return TOK_RECORD;}
integer                           {yylval.targetCode = new string(yytext); return TOK_INTEGER;}
real                              {yylval.targetCode = new string(yytext); return TOK_REAL;}
boolean                           {yylval.targetCode = new string(yytext); return TOK_BOOLEAN;}
char 							  {yylval.targetCode = new string(yytext); return TOK_CHAR;}
function                          {yylval.targetCode = new string(yytext); return TOK_FUNCTION;}
procedure                         {yylval.targetCode = new string(yytext); return TOK_PROCEDURE;}
begin                             {yylval.targetCode = new string(yytext); return TOK_BEGIN;}
end                               {yylval.targetCode = new string(yytext); return TOK_END;}
if                                {yylval.targetCode = new string(yytext); return TOK_IF;}
to 								  {yylval.targetCode = new string(yytext); return TOK_TO;}
for 							  {yylval.targetCode = new string(yytext); return TOK_FOR;}
then                              {yylval.targetCode = new string(yytext); return TOK_THEN;}
else                              {yylval.targetCode = new string(yytext); return TOK_ELSE;}
while                             {yylval.targetCode = new string(yytext); return TOK_WHILE;}
do                                {yylval.targetCode = new string(yytext); return TOK_DO;}
read                              {yylval.targetCode = new string(yytext); return TOK_READ;}
write                             {yylval.targetCode = new string(yytext); return TOK_WRITE;}
not                               {yylval.targetCode = new string(yytext); return TOK_NOT;}
true                              {yylval.targetCode = new string(yytext); return TOK_TRUE;}
false                             {yylval.targetCode = new string(yytext); return TOK_FALSE;}

("="|"<>"|"<"|"<="|">"|">=")      {yylval.targetCode = new string(yytext); return TOK_RELOP;}
("+"|"-"|"or")                    {yylval.targetCode = new string(yytext); return TOK_ADDOP;}
("*"|"/"|"div"|"mod"|"and")       {yylval.targetCode = new string(yytext); return TOK_MULOP;}
":="                              {yylval.targetCode = new string(yytext); return TOK_ASSIGNOP;}

("."|";"|","|":"|"["|"]"|"("|")") { yylval.targetCode = new string(yytext); return *yytext;}

{id}                              {yylval.targetCode = new string(yytext);  return TOK_ID;}

{digits}                          {yylval.targetDigitCode.targetCode = new string(yytext);yylval.targetDigitCode.isReal = 0; return TOK_NUM;}
{num}                             {yylval.targetDigitCode.targetCode = new string(yytext);yylval.targetDigitCode.isReal = 1; return TOK_NUM;}
{charliteral}					  {yylval.targetCode = new string(yytext); return TOK_CHAR_LIT;}

{annotation}                      {}
{white_space}                     {}
.                                 {cerr << "!ERROR!(" << yylineno << ")：词法错误--非法字符: " << yytext << endl;}


%%

int yywrap(void)
{
	return 1;
}