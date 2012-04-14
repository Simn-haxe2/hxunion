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
using Lambda;
using hxunion.engine.MacroHelper;
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
					
					var monos = func.params.map(function(p) return p.name).makeMonoHash();

					for (arg in func.args)
					{
						if (arg.type != null)
							switch(arg.type)
							{
								case TPath(p):
									arg.type = MacroHelper.monofy(arg.type, monos);
									if (p.name == "Tuple")
										arg.type = TPath(TupleBuilder.buildFromTypePath(p, monos, field.pos));
								default:
									trace(arg.type);
							}
						tfArgs.push(arg.type);
					}
					
					var ret = func.ret == null ? null :			
						switch(func.ret)
						{
							case TPath(p):
								func.ret = MacroHelper.monofy(func.ret, monos);
								if (p.name == "Tuple")
									func.ret = TPath(TupleBuilder.buildFromTypePath(p, monos, field.pos));
								func.ret;
							default: func.ret;
						};
						
					env.push( { name:field.name, type:ret != null ? TFunction(tfArgs, ret) : null, expr:null } );
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
								case Failure(f): MacroHelper.makeMono();
							};
							types.push(t);
						}
						TupleBuilder.buildFromTypes(types, expr.pos);
						var args = [];
						for (i in 0...exprs.length)
							args.push( { field: "val" +(i + 1), expr: exprs[i] } );
						EObjectDecl(args).at(expr.pos);
					default: expr;
				}
			default: expr;
		}	
	}
}