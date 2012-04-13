package hxunion.engine;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.build.MemberTransformer;

using tink.macro.tools.ExprTools;
using tink.macro.tools.TypeTools;
using tink.core.types.Outcome;

#end

using Lambda;

class UnionTransformer
{
	@:macro static public function build():Array<Field>
	{
		return new MemberTransformer().build([checkReturns]);
	}
	
	#if macro
	
	static var count = 0;
	static var cache = new Hash<EnumInfo>();
	
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
					var enumInfos:Array<EnumInfo> = [];
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
										var enumInfo = buildEnum(p, field.pos);
										arg.type = enumInfo.cType;
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
									var enumInfo = buildEnum(p, field.pos);
									func.ret = enumInfo.cType;
									enumInfos.push(enumInfo);
								}
							default:
								continue;
						}
						
					if (func.ret != null)
						env.push( { name:field.name, type:TFunction(tfArgs, func.ret), expr:null } );
						
					fieldData.set(field.name, {enumInfos: enumInfos, ctx: funcCtx });
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
					if (fieldInfo.enumInfos.length > 0)
					{
						func.expr = replaceCalls(func.expr, fieldInfo.enumInfos, innerCtx);
						func.expr = replaceReturns(func.expr, fieldInfo.enumInfos, innerCtx);
					}
				default:
			}
		}
	}

	static function replaceCalls(expr:Expr, enumInfos:Array<EnumInfo>, ctx):Expr
	{
		return expr.map(function(e:Expr, ctx)
		{
			return switch(e.expr)
			{
				case ECall(target, params):
					var e = switch(target.getIdent())
					{
						case Success(i):
							switch(findEnumPath(i, enumInfos))
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
	
	static function replaceReturns(expr:Expr, enumInfos:Array<EnumInfo>, ctx):Expr
	{
		return expr.map(function(expr, ctx)
		{
			return switch(expr.expr)
			{
				case EReturn(ret):
					if (ret != null)
						expr.expr = EReturn(ret.map(callback(makeReturn, enumInfos), ctx));
					expr;
				default:
					expr;
			}
		}, ctx);
	}

	static function makeReturn(enumInfos:Array<EnumInfo>, expr:Expr, ctx):Expr
	{
		return switch(expr.expr)
		{
			case ESwitch(_), EParenthesis(_), EBlock(_), EIf(_), ETernary(_):
				expr;
			default:
				var t = expr.typeof(ctx);
				switch(t)
				{
					case Success(t):
						for (enumInfo in enumInfos)
							for (type in enumInfo.types)
							{
								switch(t.isSubTypeOf(type))
								{
									case Success(t):
										return ["hxunion", "types", "Union" + enumInfo.id, getName(t)].drill().call([expr]);
									case Failure(_):
								}
							}
					case Failure(_):
				}
				{ expr: expr.expr, pos: expr.pos }
		}
	}
	
	static function buildEnum(tp:TypePath, pos):EnumInfo
	{
		if (tp.params.length != 1)
			Context.error(MULTI_ENUM_EXPECTS_TYPE_LIST, pos);

		var types = switch(tp.params[0])
		{
			case TPExpr(e):
				switch(e.expr)
				{
					case EArrayDecl(exprs):
						var ret = [];
						for (expr in exprs)
						{
							var type = switch(expr.typeof())
							{
								case Success(t):
									switch(t)
									{
										case TEnum(_, _): t;
										case TType(tt, _): Context.getType(toName(tt.get().pack, tt.get().name.substr(1)));
										default: Context.error("Could not find type: " +t, pos);
									}
								case Failure (e): Context.error("Could not find type: " +e, pos);
							}
							ret.push(type);
						}
						ret;
					default:
						Context.error(MULTI_ENUM_EXPECTS_TYPE_LIST, pos);
				}
			default: Context.error(MULTI_ENUM_EXPECTS_TYPE_LIST, pos);
		}
		return define(types, pos);
	}
	
	static function define(types:Array<Type>, pos)
	{
		types.sort(function (t1, t2)
		{
			var n1 = getName(t1);
			var n2 = getName(t2);
			if (n1 == n2)
				Context.error("Duplicate type name: " +n1, pos);
			return n1 < n2 ? -1 : 1;
		});	

		var signature = Lambda.fold(types, function(type, r) return r + "$" +type.getID(), "Union");
		if (cache.exists(signature))
			return cache.get(signature);
		var id = count++;
		var name = "Union" +id;
		
		var fields = [];
		var params = [];
		var params2 = [];
		
		for (type in types)
		{
			var complexType = type.toComplex(true);
			fields.push(makeField(getName(type), complexType, pos));
			params.push({name:getName(type), constraints:[]});
			params2.push(TPType(complexType));
		}
		
		Context.defineType( {
			pack: ["hxunion", "types"],
			name: name,
			pos: pos,
			meta: [],
			params: params,
			isExtern: false,
			kind: TDEnum,
			fields: fields
		});

		var cType = TPath({
			name: name,
			pack: ["hxunion", "types"],
			params: params2,
			sub: null
		});

		var typeInfo = { cType: cType, id: id, types: types };
		cache.set(signature, typeInfo);
		return typeInfo;
	}
	
	static function makeField(name:String, type:ComplexType, pos)
	{
		return {
			name: name,
			doc: null,
			access: [APublic, AStatic],
			meta: [],
			pos: pos,
			kind: 
				FFun( {
					ret: null,
					params: [],
					expr: null,
					args: [{
						name: "_",
						opt: false,
						value: null,
						type: type
					}]
				})
		};
	}
	
	static function getMembers(cls:ClassType, ctx:Array<tink.macro.tools.ExprTools.VarDecl>)
	{
		for (field in cls.fields.get())
			ctx.push( { name:field.name, type:null, expr: null } ); // TODO: this might be dirty
		if (cls.superClass != null)
			getMembers(cls.superClass.t.get(), ctx);
	}
	
	static function findEnumPath(name:String, enums:Array<EnumInfo>)
	{
		for (enumInfo in enums)
		{
			switch(enumInfo.cType)
			{
				case TPath(p):
					for (param in p.params)
					{
						switch(param)
						{
							case TPType(p2):
								switch(p2)
								{
									case TPath(p3):
										if (p3.sub == name || p3.sub == null && p3.name == name)
											return toName(p.pack, p.name).asSuccess();
									default:
								}
							default:
						}
					}
				default:
			}
		}
		return "No enum found.".asFailure();
	}
	
	static function toName(pack:Array<String>, name:String)
		return pack.length == 0 ? name : pack.join(".") + "." + name
		
	static function getName(t:Type)
		return switch(t)
		{
			case TInst(i, _): i.get().name;
			case TEnum(i, _): i.get().name;
			case TType(i, _): i.get().name;
			default: Context.error("Could not determine name of " +t, Context.currentPos());
		}
		
	static var MULTI_ENUM_EXPECTS_TYPE_LIST = "Union expects one argument of type [type list].";
	
	#end
}

#if macro

typedef EnumInfo =
{
	cType: ComplexType,
	types: Array<Type>,
	id: Int
}

#end