# mini-pascal-parser
A parser written in Perl that reads in a file of source code and then tells the user if it's syntactically correct in accordance with the Mini Pascal language. 

Specify in terminal the filename of the source code for the parser to analyze. 
Enter 'perl parser.pl sourcecode.txt' to test the validity of the example sourecode text file.

Here is the grammar for the modified Mini Pascal language:

  \<program> ::= program \<progname> \<compound stmt>

  \<compound stmt> ::= begin \<stmt> {; \<stmt>} end

  \<stmt> ::= \<simple stmt> | \<structured stmt>

  \<simple stmt> ::= \<assignment stmt> | \<read stmt> | \<write stmt>

  \<assignment stmt> ::= \<variable> := \<expression>

  \<read stmt> ::= read ( \<variable> { , \<variable> } )

  \<write stmt> ::= write ( \<expression> { , \<expression> } )

  \<structured stmt> ::=	\<compound stmt> | \<if stmt> | \<while stmt>

  \<if stmt> ::= if \<expression> then \<stmt> | 
                if \<expression> then \<stmt> else \<stmt>

  \<while stmt> ::= while \<expression> do \<stmt>

  \<expression> ::=  \<simple expr> | 
                    \<simple expr> \<relational_operator> \<simple expr>

  \<simple expr> ::= [ \<sign> ] \<term> { \<adding_operator> \<term> }

  \<term> ::= \<factor> { \<multiplying_operator> \<factor> }

  \<factor> ::= \<variable> | \<constant> | ( \<expression> )

  \<sign> ::= + | -

  \<adding_operator> ::= + | -

  \<multiplying_operator> ::= * | /

  \<relational_operator> ::= = | \<> | \< | \<= | >= | >

  \<variable> ::= \<letter> { \<letter> | \<digit> }

  \<constant> ::= \<digit>  { \<digit> }

  \<progname> ::= \<capital_letter> { \<letter> | \<digit> }
 
  \<capital_letter> ::= A | B | C | ... | Z

  \<letter> ::= a | b | c | ... | z | \<capital_letter>

  \<digit> ::= 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
