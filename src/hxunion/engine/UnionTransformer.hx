package hxunion.engine;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import tink.macro.build.MemberTransformer;

import hxunion.engine.Types;

using tink.macro.tools.ExprTools;
using tink.macro.tools.TypeTools;
using tink.core.types.Outcome;
using Lambda;
using hxunion.engine.MacroHelper;
#end

class UnionTransformer
{
	@:macro static public function build():Array<Field>
	{
		return new MemberTransformer().build([checkReturns]);
	}
	
	#if macro
	
	static function checkReturns(ctx:ClassBuildContext)
	{
		var env = [];
		
		if (ctx.cls.superClass != null)
			MacroHelper.getMembers(ctx.cls.superClass.t.get(), env);

		var fieldData = new Hash();
		
		for (field in ctx.members)
		{
			switch (field.kind)
			{
				case FVar(t, e):
					env.push( { name:field.name, type:t, expr:null } );
				case FProp(g, s, t, e):
					env.push( { name:field.name, type:t, expr:null } );				
				case FFun(func):
					var unionInfos:Array<UnionInfo> = [];
					var funcCtx = [];
					var monos = func.params.map(function(p) return p.name).makeMonoHash();
					var tfArgs = [];
					for (arg in func.args)
					{
						if (arg.type != null)
							switch(arg.type)
							{
								case TPath(p):
									arg.type = MacroHelper.monofy(arg.type, monos);
									if (p.name == "Union")
									{
										var unionInfo = UnionBuilder.buildUnion(p, monos, field.pos);
										arg.type = unionInfo.cType;
									}
								default:
							}
						tfArgs.push(arg.type);
						funcCtx.push( { name:arg.name, type:arg.type, expr: null } );
					}
					
					if (func.ret != null)			
						switch(func.ret)
						{
							case TPath(p):
								func.ret = MacroHelper.monofy(func.ret, monos);
								if (p.name == "Union")
								{
									var unionInfo = UnionBuilder.buildUnion(p, monos, field.pos);
									func.ret = unionInfo.cType;
									unionInfos.push(unionInfo);
								}
							default:
						}
						
					if (func.ret != null)
						env.push( { name:field.name, type:func.ret != null ? TFunction(tfArgs, func.ret) : null, expr:null } );
						
					fieldData.set(field.name, {unionInfos: unionInfos, ctx: funcCtx });
				default:
			}
		}

		for (field in ctx.members)
		{
			switch(field.getFunction())
			{
				case Success(func):
					var fieldInfo = fieldData.get(field.name);
					var innerCtx = env.concat(fieldInfo.ctx);
					if (fieldInfo.unionInfos.length > 0)
					{
						func.expr = replaceCalls(func.expr, fieldInfo.unionInfos, innerCtx);
						func.expr = replaceReturns(func.expr, fieldInfo.unionInfos, innerCtx);
					}
				default:
			}
		}
	}

	static function replaceCalls(expr:Expr, unionInfos:Array<UnionInfo>, ctx):Expr
	{
		return expr.map(function(e:Expr, ctx)
		{
			return switch(e.expr)
			{
				case ECall(target, params):
					var e = switch(target.getIdent())
					{
						case Success(i):
							switch(UnionBuilder.findUnion(i, unionInfos))
							{
								case Success(e): (e + "." +i).resolve().call(params);
								case Failure(_): e;
							}
						case Failure(_): e;
					}
					e;
				default: e;
			}
		}, ctx);		
	}
	
	static function replaceReturns(expr:Expr, unionInfos:Array<UnionInfo>, ctx):Expr
	{
		return expr.map(function(expr, ctx)
		{
			return switch(expr.expr)
			{
				case EReturn(ret):
					if (ret != null)
						expr.expr = EReturn(ret.map(callback(makeReturn, unionInfos), ctx));
					expr;
				default:
					expr;
			}
		}, ctx);
	}

	static function makeReturn(unionInfos:Array<UnionInfo>, expr:Expr, ctx):Expr
	{
		return switch(expr.expr)
		{
			case ESwitch(_), EParenthesis(_), EBlock(_), EIf(_), ETernary(_):
				// this will trigger map to traverse the AST one more level
				expr;
			default:
				var t = expr.typeof(ctx);
				switch(t)
				{
					case Success(t):
						for (unionInfo in unionInfos)
							for (type in unionInfo.types)
							{
								switch(t.isSubTypeOf(type))
								{
									case Success(t):
										return ["hxunion", "types", "Union" + unionInfo.id, MacroHelper.getName(t)].drill().call([expr]);
									case Failure(_):
								}
							}
					case Failure(_):
				}
				// make a copy to stop map from traversing any further
				{ expr: expr.expr, pos: expr.pos }
		}
	}

	#end
}