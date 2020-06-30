#!/bin/bash
flex lexer.l
bison -vd parser.y
g++ -std=c++17 -g -O0 lex.yy.c parser.tab.c -o parser.out
