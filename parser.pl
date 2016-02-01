#!/usr/bin/perl
#Recursive Decent Parser - By Nicholas Cleves
#11/3/15

open (INF, "<", $ARGV[0]) or die "couldn't open sourcecode\n";
# these lines of code slurp the whole file into one scalar $in_buffer
{
	local $/;
	$in_buffer = <INF>;
}

chomp($in_buffer);


# MAIN PROGRAM, start by calling the lex and program subroutines
&lex();
&program();


if ($nextToken eq ""){ #it's a valid program once there is nothing to match, but the empty string

	print "Valid Program\n";		

}else{

	&error("extra stuff after a valid sentence");

}

sub lex{ 
	if($in_buffer =~ m/^\s*(program|begin|\;|end|:=|read|\(|\,|\)|write|if|then|else|while|do|\+|\-|\*|\/|\=|<>|<=|<|>=|>)/){ 
		#the match for all reserved words, symbols, operators etc.
		
		$nextToken = $1;
		$in_buffer = $';
	
	}elsif($in_buffer =~ m/^\s*\d+/){ #the match for any constants (0-9)

		$nextToken = "CONSTANT"; #set nextToken to be "CONSTANT" (this makes it easier when checking nextToken)
		$in_buffer = $';

	}elsif($in_buffer =~ m/^\s*[A-Z][A-Za-z0-9]*/){ #matches a progname

		$nextToken = "PROGNAME_OR_VAR"; #set nextToken to be "PROGNAME_OR_VAR" (a variable can match a progname in some cases)
		$in_buffer = $';

	}elsif($in_buffer =~ m/^\s*[A-Za-z][A-Za-z0-9]*/){ #matches a variable

		$nextToken = "VARIABLE";
		$in_buffer = $';

	}elsif($in_buffer =~ m/^\s*$/){ #once we've matched nothing but whitespace before and after $nextToken is set to the empty string

		$nextToken = "";

	}else{
		&error("$in_buffer is invalid"); #if nothing is matched then there is an error (program can't be valid if doesn't meet these rules)
	}

}

# Within each subroutine I have attempted at being as consistent with my ordering of lex BEFORE any other subroutine call 
# in some cases where subroutines simply acted as routes to other subroutines I wouldn't call lex for this purpose alone.
# The overarching principle is that each subroutine "will handle it" i.e. if consistent there should be no problem getting the correct
# lexeme from the previous subroutine before the current one was called.
# Errors are called in every possible subroutine in which an error can occur. &error simply kills the program and the parameter string gets printed.

sub program{ #  <program> ::= program <progname> <compound stmt>
	if($nextToken eq "program"){ 
		&lex();
		if ($nextToken eq "PROGNAME_OR_VAR"){ # must have a progname
			&lex();
			&compoundstmt();
		}else{
			&error("Expected a Program Name, but saw $nextToken");	
		}
	}else{
		&error("Expected 'program', but saw $nextToken");
	}
}

sub compoundstmt{ #  <compound stmt> ::= begin <stmt> {; <stmt>} end
	if($nextToken eq "begin"){ # lex isn't called in the beginning because we trust that lex was called prior to the call of compoundstmt
		&lex();
		&stmt();
		while($nextToken eq ";"){ # since this called be called 0 or more times a while is used
			&lex();
			&stmt();
		}
		if($nextToken eq "end"){ # we end by calling lex (to clear 'end')
			&lex();
		}else{
			&error("Expected 'end' or ';', but saw $nextToken");
		}
	}else{
		&error("Expected 'begin', but saw $nextToken");
	}
}


sub stmt{ #  <stmt> ::= <simple stmt> | <structured stmt>
	if($nextToken eq "begin" || $nextToken eq "if" || $nextToken eq "while"){ # looking ahead we know that structstmt leads to subroutines 
		&structstmt();												# that must start with these three terminals so we route to it (this is a case of where we don't want to call lex
	}else{															# because we don't know which one to route to yet
		&simplestmt(); #otherwise go to simplestmt
	}	
}

sub structstmt{ # <structured stmt> ::=	<compound stmt> | <if stmt> | <while stmt>
	if($nextToken eq "begin"){ # another form of routing, this time we don't want them all or'd because they don't all go to the same thing
		&compoundstmt();
	}else{
		if($nextToken eq "if"){ # if not 'begin', maybe if 
			&ifstmt();
		}else{
			if($nextToken eq "while"){ # if not 'begin' or 'if' it must be while
				&whilestmt();
			}else{ #if none of them we exit with an error
				&error("Expected 'begin' or 'if', or, 'while'  but saw $nextToken");
			}
		}
	}
}

sub simplestmt{ # <simplestmt> ::= <assignment stmt> | <read stmt> | <write stmt>
	if($nextToken eq "VARIABLE" || $nextToken eq "PROGNAME_OR_VAR"){ # coming from stmt we have to route similarly to structstmt
		&assignmentstmt(); # an assignmentstmt starts with a variable
	}else{
		if($nextToken eq "read"){ # if not a variable, maybe 'read'
			&readstmt();
		}else{
			if($nextToken eq "write"){ # if not a variable or 'read', it must be write
				&writestmt();
			}else{ #if none of them we exit with an error
				&error("Expected a variable or 'read', or, 'write' but saw $nextToken");
			}
		}
	}
}

sub assignmentstmt{ # <assignment stmt> ::= <variable> := <expression>
	&lex(); # since we already checked to see if it was a variable, we can get the nextToken
	if($nextToken eq ":="){ 
		&lex(); # get rid of ':=' and go to expression
		&expression();
	}else{
		&error("Expected ':=', but saw $nextToken");
	}

}

sub ifstmt{ 	# <if stmt> ::= if <expression> then <stmt> | if <expression> then <stmt> else <stmt>
	&lex(); # get rid of 'if' since that's how we got here
	&expression(); # immediately go to expression
	if($nextToken eq "then"){ # nextToken has to be 'then' 
		&lex(); # get rid of 'then' and go to stmt
		&stmt(); 

		if($nextToken eq "else"){ # we can optionally go to else
			&lex();
			&stmt();
		} # there is no else/error here because 'else' is optional (we'd always run into an error if nextToken wasn't 'else')

	}else{
		&error("Expected 'then', but saw $nextToken");
	}
}

sub readstmt{ # <read stmt> ::= read ( <variable> { , <variable> } )
	&lex(); # get rid of 'read'
	if($nextToken eq "("){  # must start with a '('
		&lex(); # get rid of '('
		if($nextToken eq "VARIABLE" || $nextToken eq "PROGNAME_OR_VAR"){ # must be a variable
			&lex(); # get rid of the variable and get nextToken

			while($nextToken eq ","){ # optionally we can write an additional 0 or more variables seperated by ','
				&lex();
				if($nextToken eq "VARIABLE" || $nextToken eq "PROGNAME_OR_VAR"){
					&lex();
				}else{
					&error("Expected a ',' or a variable, but saw $nextToken");
				}
			}

			if($nextToken eq ")"){ # we must have a ')' to close the readstmt
				&lex();
			}else{
				&error("Expected ')', but saw $nextToken"); 
			}

		}else{
			&error("Expected a variable, but saw $nextToken"); 
		}

	}else{
		&error("Expected '(', but saw $nextToken"); 
	}

}

sub writestmt{ # <write stmt> ::= write ( <expression> { , <expression> } )
	&lex(); # get rid of 'write'
	if($nextToken eq "("){ # must start with a '('
		&lex();
		&expression();

		while($nextToken eq ","){  # optionally we can write an additional 0 or more expressions seperated by ','
			&lex();
			&expression();
		}

		if($nextToken eq ")"){ # we must have a ')' to close the writestmt
			&lex();
		}else{
			&error("Expected ')', but saw $nextToken");
		}

	}else{
		&error("Expected '(', but saw $nextToken");
	}

}

sub whilestmt{  # <while stmt> ::= while <expression> do <stmt>
	&lex(); # get rid of 'while'
	&expression(); # immediately go to expression
	if($nextToken eq "do"){ # must have a 'do', after coming back from expression
		&lex();
		&stmt(); # go to stmt after getting rid of 'do'
	}else{
		&error("Expected 'do', but saw $nextToken");
	}
}

sub expression{		# <expression> ::=  <simple expr> | <simple expr> <relational_operator> <simple expr>
	&simpleexpr(); # expression goes straight to simple expr
	if($nextToken eq "=" || $nextToken eq "<>" || $nextToken eq "<=" || $nextToken eq ">=" || $nextToken eq ">" || $nextToken eq "<"){
		# optionally we can have a simple expr followed by a relational operator 
		&lex();
		&simpleexpr(); # followed by another simple expr
	}	
}


sub simpleexpr{ # <simple expr> ::= [ <sign> ] <term> { <adding_operator> <term> }
	if($nextToken eq "-" || $nextToken eq "+"){ # check if there is an optional sign ('-' or '+') in front of term
		&lex();
	}

	&term(); # go to term, (simple expr must go to term)

	while($nextToken eq "+" || $nextToken eq "-"){ # optionally we can have 0 or more terms after '+'' or '-'
		&lex();
		&term();
	}	 

	
}

sub term{ # <term> ::= <factor> { <multiplying_operator> <factor> }
	&factor(); # go straight to factor
	while($nextToken eq "*" || $nextToken eq "/"){ # optionally we can have 0 or more factors after '*'' or '/' 
		&lex();
		&factor();
	}
}

sub factor{ #  <factor> ::= <variable> | <constant> | ( <expression> )
	if($nextToken eq "CONSTANT" || $nextToken eq "VARIABLE" || $nextToken eq "PROGNAME_OR_VAR"){ # since factor can be one of these things we can test them together
		&lex();
	}else{
		if($nextToken eq "("){ # factor can also be expression, but it must start with a '('
			&lex();
			&expression();

			if($nextToken eq ")"){ # if the option is taken it must be ended with a ')'
				&lex();
			}else{
				&error("Expected ')', but saw $nextToken");
			}

		}else{
			&error("Expected a constant or variable or '(', but saw $nextToken");
		}
	}
}

sub error{
	die ($_[0]);
}






