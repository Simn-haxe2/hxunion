package hxmr.engine;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import tink.macro.build.MemberTransformer;
using tink.macro.tools.ExprTools;
using tink.macro.tools.TypeTools;
using tink.core.types.Outcome;
#end

class MultiReturnTransformer
{
	@:macro static public function build():Array<Field>
	{
		return new MemberTransformer().build([checkReturns]);
	}
	
	#if macro
	
	static var count = 0;
	static var cache = new Hash<ComplexType>();
	
	static function checkReturns(ctx:ClassBuildContext)
	{
		var env = [];
		for (field in ctx.members)
		{
			switch (field.kind)
			{
				case FFun(func):
					if (func.ret == null || func.expr == null)
						continue;
					switch(func.ret)
					{
						case TPath(p):
							if (p.name == "MultiReturn" && p.pack.length == 1 && p.pack[0] == "hxmr")
							{
								var innerCtx = env.copy();
								for (arg in func.args)
									innerCtx.push( { name:arg.name, type:arg.type, expr: null } );	
								var multiEnum = buildEnum(p, field.pos);
								func.ret = multiEnum.cType;
								func.expr = transform(func.expr, multiEnum, innerCtx);
							}
						default:
							continue;
					}
				default:
			}
		}
	}

	static function transform(expr:Expr, multiEnum:EnumInfo, ctx):Expr
	{
		return expr.map(function(e:Expr, ctx)
		{
			return switch(e.expr)
			{
				case EReturn(ret):
					if (ret == null) e;
					else
					{
						var retT = transform(ret, multiEnum, ctx);
						var t = retT.typeof(ctx).sure();
						var filter = Lambda.filter(multiEnum.types, function(type) return type.getID() == t.getID());
						if (filter.length == 1)
							EReturn(["hxmr", "types", "MultiReturn" + (count - 1), getName(filter.first())].drill().call([ret])).at();
						else
							e;
					}
				default: e;
			}
		}, ctx);		
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

		return { cType: define(types, pos), types: types };
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
		
		var signature = Context.signature(types);
		if (cache.exists(signature))
			return cache.get(signature);
			
		var name = "MultiReturn" +count++;
		
		var fields = [];
		var params = [];
		var params2 = [];
		
		for (type in types)
		{
			var complexType = type.toComplex();
			fields.push(makeField(getName(type), complexType, pos));
			params.push({name:getName(type), constraints:[]});
			params2.push(TPType(complexType));
		}
		
		Context.defineType( {
			pack: ["hxmr", "types"],
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
			pack: ["hxmr", "types"],
			params: params2,
			sub: null
		});

		cache.set(signature, cType);
		return cType;
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
	static var MULTI_ENUM_EXPECTS_TYPE_LIST = "MultiReturn expects one argument of type [type list].";
	
	#end
}

typedef EnumInfo =
{
	cType: ComplexType,
	types: Array<Type>
}