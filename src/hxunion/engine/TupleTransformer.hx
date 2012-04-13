package hxunion.engine;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.tools.AST;

import tink.macro.build.MemberTransformer;

import hxunion.engine.Types;

using tink.macro.tools.ExprTools;
using tink.macro.tools.TypeTools;
using tink.core.types.Outcome;

#end

class TupleTransformer
{
	@:macro static public function build():Array<Field>
	{
		return new MemberTransformer().build([findTuples]);
	}
	
	static function findTuples(ctx:ClassBuildContext)
	{
		var env = [];
		
		if (ctx.cls.superClass != null)
			MacroHelper.getMembers(ctx.cls.superClass.t.get(), env);
			
		for (field in ctx.members)
		{
			switch (field.kind)
			{
				case FVar(t, e):
					env.push( { name:field.name, type:t, expr:null } );
				case FProp(g, s, t, e):
					env.push( { name:field.name, type:t, expr:null } );				
				case FFun(func):
					var tfArgs = [];
					for (arg in func.args)
					{
						if (arg.type != null)
							switch(arg.type)
							{
								case TPath(p):
									if (p.name == "Tuple")
										arg.type = TPath(TupleBuilder.buildFromTypePath(p, field.pos));
								default:
							}
						tfArgs.push(arg.type);
					}
					
					if (func.ret != null)			
						switch(func.ret)
						{
							case TPath(p):
								if (p.name == "Tuple")
									func.ret = TPath(TupleBuilder.buildFromTypePath(p, field.pos));
							default:
						}
						
					env.push( { name:field.name, type:func.ret != null ? TFunction(tfArgs, func.ret) : null, expr:null } );	
			}
		}
		
		for (field in ctx.members)
		{
			switch(field.getFunction())
			{
				case Success(func):
					var innerCtx = env.copy();
					for (arg in func.args)
						innerCtx.push( { name:arg.name, type:arg.type, expr: null } );
					if (func.expr != null)
						func.expr = func.expr.map(replaceTuples, innerCtx, field.pos);
				case Failure(_):
			}
		}
	}
	
	static function replaceTuples(expr:Expr, ctx):Expr
	{
		return switch(expr.expr)
		{
			case EParenthesis(e):
				switch(e.expr)
				{
					case EArrayDecl(exprs):
						var types = [];
						for (e in exprs)
						{
							var t = switch(e.typeof(ctx))
							{
								case Success(t): t;
								case Failure(f): Context.getType("Dynamic");
							};
							types.push(t);
						}
						var t = TupleBuilder.buildFromTypes(types, expr.pos);
						t.instantiate(exprs);
					default: expr;
				}
			default: expr;
		}	
	}
}