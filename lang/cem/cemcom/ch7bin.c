/* $Header$ */
/* SEMANTIC ANALYSIS (CHAPTER 7RM)  --  BINARY OPERATORS */

#include	"botch_free.h"	/* UF */
#include	"idf.h"
#include	"arith.h"
#include	"type.h"
#include	"struct.h"
#include	"label.h"
#include	"expr.h"
#include	"Lpars.h"
#include	"storage.h"

extern char options[];
extern char *symbol2str();

/*	This chapter asks for the repeated application of code to handle
	an operation that may be executed at compile time or at run time,
	depending on the constancy of the operands.
*/

ch7bin(expp, oper, expr)
	register struct expr **expp;
	struct expr *expr;
{
	/*	apply binary operator oper between *expp and expr.
		NB: don't swap operands if op is one of the op= operators!!!
	*/
	any2opnd(expp, oper);
	any2opnd(&expr, oper);
	switch (oper)	{
		int fund;
	case '[':				/* RM 7.1 */
		/* RM 14.3 states that indexing follows the commutative laws */
		switch ((*expp)->ex_type->tp_fund)	{
		case POINTER:
		case ARRAY:
			break;
		case ERRONEOUS:
			return;
		default:		/* unindexable */
			switch (expr->ex_type->tp_fund)	{
			case POINTER:
			case ARRAY:
				break;
			case ERRONEOUS:
				return;
			default:
				expr_error(*expp,
					"indexing an object of type %s",
					symbol2str((*expp)->ex_type->tp_fund));
				return;
			}
			break;
		}
		ch7bin(expp, '+', expr);
		ch7mon('*', expp);
		break;
	case '(':				/* RM 7.1 */
		if (	(*expp)->ex_type->tp_fund == POINTER &&
			(*expp)->ex_type->tp_up->tp_fund == FUNCTION
		)	{
			if (options['R'])
				warning("function pointer called");
			ch7mon('*', expp);
		}
		if ((*expp)->ex_type->tp_fund != FUNCTION)	{
			expr_error(*expp, "call of non-function (%s)",
				symbol2str((*expp)->ex_type->tp_fund));
			/* leave the expression; it may still serve */
			free_expression(expr);	/* there go the parameters */
		}
		else
			*expp = new_oper((*expp)->ex_type->tp_up,
					*expp, '(', expr);
		break;
	case PARCOMMA:				/* RM 7.1 */
		if ((*expp)->ex_type->tp_fund == FUNCTION)
			function2pointer(expp);
		*expp = new_oper(expr->ex_type, *expp, PARCOMMA, expr);
		break;
	case '%':
	case MODAB:
/*** NB  "not float" means "integral" !!!
		fund = arithbalance(expp, oper, &expr);
		if (fund == DOUBLE)	{
			expr_error(*expp, "floating operand to %s", 
				symbol2str(oper));
			erroneous2int(expp);
		}
		else
			non_commutative_binop(expp, oper, expr);
***/
		opnd2integral(expp, oper);
		opnd2integral(&expr, oper);
		fund = arithbalance(expp, oper, &expr);
		non_commutative_binop(expp, oper, expr);
		break;
	case '/':
	case DIVAB:
		fund = arithbalance(expp, oper, &expr);
		non_commutative_binop(expp, oper, expr);
		break;
	case '*':
		fund = arithbalance(expp, oper, &expr);
		commutative_binop(expp, oper, expr);
		break;
	case TIMESAB:
		fund = arithbalance(expp, oper, &expr);
		non_commutative_binop(expp, oper, expr);
		break;
	case '+':
		if (expr->ex_type->tp_fund == POINTER)	{
			/* swap operands */
			struct expr *etmp = expr;
			expr = *expp;
			*expp = etmp;
		}
		/*FALLTHROUGH*/
	case PLUSAB:
		if ((*expp)->ex_type->tp_fund == POINTER)	{
			pointer_arithmetic(expp, oper, &expr);
			if (	expr->ex_type->tp_size !=
				(*expp)->ex_type->tp_size
			)	{
				ch7cast(&expr, CAST, (*expp)->ex_type);
			}
			pointer_binary(expp, oper, expr);
		}
		else	{
			fund = arithbalance(expp, oper, &expr);
			if (oper == '+')
				commutative_binop(expp, oper, expr);
			else
				non_commutative_binop(expp, oper, expr);
		}
		break;
	case '-':
	case MINAB:
		if ((*expp)->ex_type->tp_fund == POINTER)	{
			if (expr->ex_type->tp_fund == POINTER)
				pntminuspnt(expp, oper, expr);
			else {
				pointer_arithmetic(expp, oper, &expr);
				pointer_binary(expp, oper, expr);
			}
		}
		else	{
			fund = arithbalance(expp, oper, &expr);
			non_commutative_binop(expp, oper, expr);
		}
		break;
	case LEFT:
	case LEFTAB:
	case RIGHT:
	case RIGHTAB:
		opnd2integral(expp, oper);
		opnd2integral(&expr, oper);
		ch7cast(&expr, oper, int_type); /* leftop should be int	*/
		non_commutative_binop(expp, oper, expr);
		break;
	case '<':
	case '>':
	case LESSEQ:
	case GREATEREQ:
	case EQUAL:
	case NOTEQUAL:
		relbalance(expp, oper, &expr);
		non_commutative_binop(expp, oper, expr);
		(*expp)->ex_type = int_type;
		break;
	case '&':
	case '^':
	case '|':
		opnd2integral(expp, oper);
		opnd2integral(&expr, oper);
		fund = arithbalance(expp, oper, &expr);
		commutative_binop(expp, oper, expr);
		break;
	case ANDAB:
	case XORAB:
	case ORAB:
		opnd2integral(expp, oper);
		opnd2integral(&expr, oper);
		fund = arithbalance(expp, oper, &expr);
		non_commutative_binop(expp, oper, expr);
		break;
	case AND:
	case OR:
		opnd2test(expp, oper);
		opnd2test(&expr, oper);
		if (is_cp_cst(*expp))	{
			struct expr *ex = *expp;

			/* the following condition is a short-hand for
				((oper == AND) && o1) || ((oper == OR) && !o1)
				where o1 == (*expp)->VL_VALUE;
				and ((oper == AND) || (oper == OR))
			*/
			if ((oper == AND) == ((*expp)->VL_VALUE != (arith)0))
				*expp = expr;
			else {
				free_expression(expr);
				*expp = intexpr((arith)((oper == AND) ? 0 : 1),
						INT);
			}
			free_expression(ex);
		}
		else
		if (is_cp_cst(expr))	{
			/* Note!!!: the following condition is a short-hand for
				((oper == AND) && o2) || ((oper == OR) && !o2)
				where o2 == expr->VL_VALUE
				and ((oper == AND) || (oper == OR))
			*/
			if ((oper == AND) == (expr->VL_VALUE != (arith)0))
				free_expression(expr);
			else {
				if (oper == OR)
					expr->VL_VALUE = (arith)1;
				ch7bin(expp, ',', expr);
			}
		}
		else
			*expp = new_oper(int_type, *expp, oper, expr);
		(*expp)->ex_flags |= EX_LOGICAL;
		break;
	case ':':
		if (	is_struct_or_union((*expp)->ex_type->tp_fund)
		||	is_struct_or_union(expr->ex_type->tp_fund)
		)	{
			if ((*expp)->ex_type != expr->ex_type)	{
				expr_error(*expp, "illegal balance");
			}
		}
		else	{
			relbalance(expp, oper, &expr);
		}
		*expp = new_oper((*expp)->ex_type, *expp, oper, expr);
		break;
	case '?':
		opnd2logical(expp, oper);
		if (is_cp_cst(*expp))
			*expp = (*expp)->VL_VALUE ?
				expr->OP_LEFT : expr->OP_RIGHT;
		else
			*expp = new_oper(expr->ex_type, *expp, oper, expr);
		break;
	case ',':
		if (is_cp_cst(*expp))
			*expp = expr;
		else
			*expp = new_oper(expr->ex_type, *expp, oper, expr);
		(*expp)->ex_flags |= EX_COMMA;
		break;
	}
}

pntminuspnt(expp, oper, expr)
	register struct expr **expp, *expr;
{
	/*	Subtracting two pointers is so complicated it merits a
		routine of its own.
	*/
	struct type *up_type = (*expp)->ex_type->tp_up;

	if (up_type != expr->ex_type->tp_up)	{
		expr_error(*expp, "subtracting incompatible pointers");
		free_expression(expr);
		erroneous2int(expp);
		return;
	}
	/*	we hope the optimizer will eliminate the load-time
		pointer subtraction
	*/
	*expp = new_oper((*expp)->ex_type, *expp, oper, expr);
	ch7cast(expp, CAST, pa_type);	/* ptr-ptr: result has pa_type	*/
	ch7bin(expp, '/',
		intexpr(size_of_type(up_type, "object"), pa_type->tp_fund));
	ch7cast(expp, CAST, int_type);	/* result will be an integer expr */
}

non_commutative_binop(expp, oper, expr)
	register struct expr **expp, *expr;
{
	/*	Constructs in *expp the operation indicated by the operands.
		"oper" is a non-commutative operator
	*/
	if (is_cp_cst(expr) && is_cp_cst(*expp))
		cstbin(expp, oper, expr);
	else
		*expp = new_oper((*expp)->ex_type, *expp, oper, expr);
}

commutative_binop(expp, oper, expr)
	register struct expr **expp, *expr;
{
	/*	Constructs in *expp the operation indicated by the operands.
		"oper" is a commutative operator
	*/
	if (is_cp_cst(expr) && is_cp_cst(*expp))
		cstbin(expp, oper, expr);
	else
	if ((*expp)->ex_depth > expr->ex_depth)
		*expp = new_oper((*expp)->ex_type, *expp, oper, expr);
	else
		*expp = new_oper((*expp)->ex_type, expr, oper, *expp);
}

pointer_arithmetic(expp1, oper, expp2)
	register struct expr **expp1, **expp2;
{
	/*	prepares the integral expression expp2 in order to
		apply it to the pointer expression expp1
	*/
	if (any2arith(expp2, oper) == DOUBLE)	{
		expr_error(*expp2,
			"illegal combination of float and pointer");
		erroneous2int(expp2);
	}
	ch7bin( expp2, '*',
		intexpr(size_of_type((*expp1)->ex_type->tp_up, "object"),
			pa_type->tp_fund)
	);
}

pointer_binary(expp, oper, expr)
	register struct expr **expp, *expr;
{
	/*	constructs the pointer arithmetic expression out of
		a pointer expression, a binary operator and an integral
		expression.
	*/
	if (is_ld_cst(expr) && is_ld_cst(*expp))
		cstbin(expp, oper, expr);
	else
		*expp = new_oper((*expp)->ex_type, *expp, oper, expr);
}
