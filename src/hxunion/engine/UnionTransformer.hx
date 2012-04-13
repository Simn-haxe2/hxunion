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
			getMembers(ctx.cls.superClass.t.get(), env);
			
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
					var UnionInfos:Array<UnionInfo> = [];
					var funcCtx = [];
					
					var tfArgs = [];
					for (arg in func.args)
					{
						if (arg.type != null)
							switch(arg.type)
							{
								case TPath(p):
									if (p.name == "Union")
									{
										var UnionInfo = UnionBuilder.buildUnion(p, field.pos);
										arg.type = UnionInfo.cType;
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
								if (p.name == "Union")
								{
									var UnionInfo = UnionBuilder.buildUnion(p, field.pos);
									func.ret = UnionInfo.cType;
									UnionInfos.push(UnionInfo);
								}
							default:
								continue;
						}
						
					if (func.ret != null)
						env.push( { name:field.name, type:TFunction(tfArgs, func.ret), expr:null } );
						
					fieldData.set(field.name, {UnionInfos: UnionInfos, ctx: funcCtx });
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
					if (fieldInfo.UnionInfos.length > 0)
					{
						func.expr = replaceCalls(func.expr, fieldInfo.UnionInfos, innerCtx);
						func.expr = replaceReturns(func.expr, fieldInfo.UnionInfos, innerCtx);
					}
				default:
			}
		}
	}

	static function replaceCalls(expr:Expr, UnionInfos:Array<UnionInfo>, ctx):Expr
	{
		return expr.map(function(e:Expr, ctx)
		{
			return switch(e.expr)
			{
				case ECall(target, params):
					var e = switch(target.getIdent())
					{
						case Success(i):
							switch(UnionBuilder.findUnion(i, UnionInfos))
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
	
	static function replaceReturns(expr:Expr, UnionInfos:Array<UnionInfo>, ctx):Expr
	{
		return expr.map(function(expr, ctx)
		{
			return switch(expr.expr)
			{
				case EReturn(ret):
					if (ret != null)
						expr.expr = EReturn(ret.map(callback(makeReturn, UnionInfos), ctx));
					expr;
				default:
					expr;
			}
		}, ctx);
	}

	static function makeReturn(UnionInfos:Array<UnionInfo>, expr:Expr, ctx):Expr
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
						for (UnionInfo in UnionInfos)
							for (type in UnionInfo.types)
							{
								switch(t.isSubTypeOf(type))
								{
									case Success(t):
										return ["hxunion", "types", "Union" + UnionInfo.id, UnionBuilder.getName(t)].drill().call([expr]);
									case Failure(_):
								}
							}
					case Failure(_):
				}
				// make a copy to stop map from traversing any further
				{ expr: expr.expr, pos: expr.pos }
		}
	}
	
	static function getMembers(cls:ClassType, ctx:Array<tink.macro.tools.ExprTools.VarDecl>)
	{
		for (field in cls.fields.get())
			ctx.push( { name:field.name, type:null, expr: null } );
		if (cls.superClass != null)
			getMembers(cls.superClass.t.get(), ctx);
	}
		
	#end
}