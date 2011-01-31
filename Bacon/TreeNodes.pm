package Bacon::TreeNodes;
use warnings FATAL => 'all';
use strict;

# This package just uses all the different AstNode subclasses.
use Bacon::AstNode;
use Bacon::Program;
use Bacon::Function;
use Bacon::Kernel;
use Bacon::Variable;

use Bacon::Stmt;
use Bacon::Stmt::Block;
use Bacon::Stmt::DoWhile;
use Bacon::Stmt::Expr;
use Bacon::Stmt::For;
use Bacon::Stmt::IfElse;
use Bacon::Stmt::Return;
use Bacon::Stmt::Switch;
use Bacon::Stmt::VarDecl;
use Bacon::Stmt::While;
use Bacon::Stmt::WithLabel;
use Bacon::Stmt::Error;

use Bacon::Expr;
use Bacon::Expr::ArrayIndex;
use Bacon::Expr::BinaryOp;
use Bacon::Expr::Conditional;
use Bacon::Expr::FieldAccess;
use Bacon::Expr::FunCall;
use Bacon::Expr::Identifier;
use Bacon::Expr::Literal;
use Bacon::Expr::String;
use Bacon::Expr::UnaryOp;

1;
