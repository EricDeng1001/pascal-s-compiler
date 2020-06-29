%{
#include <string>
#include <vector>
#include <map>
#include <utility>
#include <iostream>
#include <fstream>

using namespace std;

%}


white_space       [ \t\n]+
digit             [0-9]
digits		      [0-9]+
fraction          (\.{digits})?
exponent          (\(E\([-+]?\){digits}\))?
num               {digits}{fraction}{exponent}

letter            [A-Za-z]
id                {letter}({letter}|{digit})*

block_annotation  \{\*[.\n]*\*\}
line_annotation   \{[.]*\}
annotation        {block_annotation}|{line_annotation}

%%


program                           {yylval.targetCode = new string(yytext); Type return PROGRAM;}
var								  {yylval.targetCode = new string(yytext); Type return VAR;}
array                             {yylval.targetCode = new string(yytext); Type return ARRAY;}
of                                {yylval.targetCode = new string(yytext); Type return OF;}
record                            {yylval.targetCode = new string(yytext); Type return RECORD;}
integer                           {yylval.targetCode = new string(yytext); Type return INTEGER;}
real                              {yylval.targetCode = new string(yytext); Type return REAL;}
boolean                           {yylval.targetCode = new string(yytext); Type return BOOLEAN;}
function                          {yylval.targetCode = new string(yytext); Type return FUNCTION;}
procedure                         {yylval.targetCode = new string(yytext); Type return PROCEDURE;}
begin                             {yylval.targetCode = new string(yytext); Type return BEGIN;}
end                               {yylval.targetCode = new string(yytext); Type return END;}
if                                {yylval.targetCode = new string(yytext); Type return IF;}
then                              {yylval.targetCode = new string(yytext); Type return THEN;}
else                              {yylval.targetCode = new string(yytext); Type return ELSE;}
while                             {yylval.targetCode = new string(yytext); Type return WHILE;}
do                                {yylval.targetCode = new string(yytext); Type return DO;}
read                              {yylval.targetCode = new string(yytext); Type return READ;}
write                             {yylval.targetCode = new string(yytext); Type return WRITE;}
not                               {yylval.targetCode = new string(yytext); Type return NOT;}
true                              {yylval.targetCode = new string(yytext); Type return TRUE;}
false                             {yylval.targetCode = new string(yytext); Type return FALSE;}

("="|"<>"|"<"|"<="|">"|">=")      {yylval.targetCode = new string(yytext); Type return RELOP;}
("+"|"-"|"div")                   {yylval.targetCode = new string(yytext); Type return ADDOP;}
("*"|"/"|"div"|"mod"|"and")       {yylval.targetCode = new string(yytext); Type return MULOP;}
":="                              {yylval.targetCode = new string(yytext); Type return ASSIGNOP;}

("."|";"|","|":"|"["|"]"|"("|")") { yylval.targetCode = new string(yytext); Type return *yytext;}

{id}                              {yylval.targetCode = new string(yytext);  Type return ID;}

{digits}                          {yylval.targetDigitCode.targetCode = new string(yytext);yylval.targetDigitCode.num = atof(yytext);yylval.targetDigitCode.dataType = INT_T; Type return NUM;}
{num}                             {yylval.targetDigitCode.targetCode = new string(yytext);yylval.targetDigitCode.num = atof(yytext);yylval.targetDigitCode.dataType = REAL_T;Type return NUM;}

{annotation}                      {}
{white_space}                     {}

.                                 {cout<<yylineno<<"行：词法错误--非法字符"<<endl;}


%%

int yywrap(void)
{
	return 1;
}