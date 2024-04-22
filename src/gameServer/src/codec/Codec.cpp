#include "Codec.h"

#include <type_traits>
#include <memory>
#include "../../../common/log/Log.h"
#include "../../../../libs/lua/lua.hpp"

// using namespace google::protobuf;
// using namespace google::protobuf::compiler;

class ProtoErrorCollector : public google::protobuf::compiler::MultiFileErrorCollector
{
	virtual void AddError(const std::string &filename, int line, int column, const std::string &message)
	{
		printf("%s line %d, column %d : %s", filename.c_str(), line, column, message.c_str());
	}
};

ProtoErrorCollector g_errorCollector;
google::protobuf::compiler::DiskSourceTree g_sourceTree;
google::protobuf::compiler::Importer g_importer(&g_sourceTree, &g_errorCollector);
google::protobuf::DynamicMessageFactory g_factory;

const char* luaErrName[] = { "nil", "bool", "lightuserdata", "number", "string", "table", "function", "userdata", "thread" };



void Codec::ps(lua_State *L)
{
	int i;
	int top = lua_gettop(L);
	printf("stackDump(num=%d):\n", top);
	for (i = 1; i <= top; i++)
	{ /* repeat for each level */
		int t = lua_type(L, i);
		switch (t)
		{
		case LUA_TSTRING: /* strings */
			printf("`%s'", lua_tostring(L, i));
			break;
		case LUA_TBOOLEAN: /* booleans */
			printf(lua_toboolean(L, i) ? "true" : "false");
			break;
		case LUA_TNUMBER: /* numbers */
			printf("%g", lua_tonumber(L, i));
			break;
		default: /* other values */
			printf("%s", lua_typename(L, t));
			break;
		}
		printf("  ");
		/* put a separator */
	}
	printf("\n");
	/* end the listing */
}




bool Codec::decodeRepeated(const google::protobuf::Message *mess, const google::protobuf::FieldDescriptor *fieldDesc, lua_State *l)
{
	const google::protobuf::Reflection *reftion = mess->GetReflection();
	int cnt = reftion->FieldSize(*mess, fieldDesc);
	lua_createtable(l, cnt, 0);
	for (int i = 0; i < cnt; ++i)
	{
		if (!decoderRepeatedField(mess, fieldDesc, l, i))
		{
			return false;
		}
		lua_seti(l, -2, (int)(i + 1)); // 把decoderRepeatedField插件的tal写入 {[i+1]={}}
	}
	return true;
}

bool Codec::decodeOptional(const google::protobuf::Message *mess, const google::protobuf::FieldDescriptor *fieldDesc, lua_State *l)
{
	const google::protobuf::Reflection *reftion = mess->GetReflection();
	// if (!reftion->HasField(*mess, fieldDesc))
	// {
	// 	logInfo("decodeOptional no find field, fieldname = %s", fieldDesc->full_name().c_str());
	// 	// return false;
	// }

	switch (fieldDesc->cpp_type())
	{
	case google::protobuf::FieldDescriptor::CPPTYPE_DOUBLE:
		lua_pushnumber(l, reftion->GetDouble(*mess, fieldDesc));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_FLOAT:
		lua_pushnumber(l, reftion->GetFloat(*mess, fieldDesc));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_INT32:
		//printf("%d\n", reftion->GetInt32(*mess, fieldDesc));
		lua_pushinteger(l, reftion->GetInt32(*mess, fieldDesc));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_UINT32:
		lua_pushinteger(l, reftion->GetUInt32(*mess, fieldDesc));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_INT64:
		lua_pushinteger(l, reftion->GetInt64(*mess, fieldDesc));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_UINT64:
		lua_pushinteger(l, reftion->GetUInt64(*mess, fieldDesc));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_ENUM:
		lua_pushinteger(l, reftion->GetEnumValue(*mess, fieldDesc));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_BOOL:
		lua_pushboolean(l, reftion->GetBool(*mess, fieldDesc));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_STRING:
	{
		const std::string &str = reftion->GetString(*mess, fieldDesc);
		lua_pushlstring(l, str.c_str(), str.size());
		return true;
	}
	case google::protobuf::FieldDescriptor::CPPTYPE_MESSAGE:
	{
		const google::protobuf::Message *subMess = &reftion->GetMessage(*mess, fieldDesc);
		return decodeMessage(subMess, fieldDesc->message_type(), l);
	}
	default:
		logInfo("decodeOptional no find type, fieldname = %s", fieldDesc->full_name().c_str());
		return false;
	}
}

bool Codec::decoderRepeatedField(const google::protobuf::Message *mess, const google::protobuf::FieldDescriptor *fieldDesc, lua_State *l, int index)
{
	const google::protobuf::Reflection *reftion = mess->GetReflection();
	switch (fieldDesc->cpp_type())
	{
	case google::protobuf::FieldDescriptor::CPPTYPE_DOUBLE:
		lua_pushnumber(l, (double)reftion->GetRepeatedDouble(*mess, fieldDesc, index));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_FLOAT:
		lua_pushnumber(l, (float)reftion->GetRepeatedFloat(*mess, fieldDesc, index));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_INT32:
		lua_pushinteger(l, (int)reftion->GetRepeatedInt32(*mess, fieldDesc, index));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_INT64:
		lua_pushinteger(l, (google::protobuf::int64)reftion->GetRepeatedInt64(*mess, fieldDesc, index));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_UINT32:
		lua_pushinteger(l, (google::protobuf::uint32)reftion->GetRepeatedUInt32(*mess, fieldDesc, index));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_UINT64:
		lua_pushinteger(l, (google::protobuf::uint64)reftion->GetRepeatedUInt64(*mess, fieldDesc, index));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_ENUM:
		lua_pushinteger(l, reftion->GetRepeatedEnumValue(*mess, fieldDesc, index));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_BOOL:
		lua_pushboolean(l, reftion->GetRepeatedBool(*mess, fieldDesc, index));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_STRING:
	{
		const std::string &str = reftion->GetRepeatedString(*mess, fieldDesc, index);
		lua_pushlstring(l, str.c_str(), str.length());
		return true;
	}
	case google::protobuf::FieldDescriptor::CPPTYPE_MESSAGE:
	{
		const google::protobuf::Message *subMess = &reftion->GetRepeatedMessage(*mess, fieldDesc, index);
		return decodeMessage(subMess, fieldDesc->message_type(), l);
	}
	default:
		logInfo("decoderRepeatedField err, no find type, name = %s", fieldDesc->full_name().c_str());
		return false;
	}
}

bool Codec::decodeMap(const google::protobuf::Message *mess, const google::protobuf::FieldDescriptor *fieldDesc, lua_State *l)
{
	const google::protobuf::Reflection *reftion = mess->GetReflection();
	const google::protobuf::Descriptor *desc = fieldDesc->message_type();
	if (desc->field_count() != 2)
	{
		logInfo("decodeMap err desc->field_count() != 2, name = %s", desc->full_name().c_str());
		return false;
	}

	const google::protobuf::FieldDescriptor *key = desc->field(0);
	const google::protobuf::FieldDescriptor *val = desc->field(1);
	int cnt = reftion->FieldSize(*mess, fieldDesc);
	lua_createtable(l, 0, cnt);

	for (int i = 0; i < cnt; ++i)
	{
		const google::protobuf::Message *subMess = &reftion->GetRepeatedMessage(*mess, fieldDesc, i);
		if (!decodeField(subMess, key, l))
		{
			return false;
		}
		if (!decodeField(subMess, val, l))
		{
			return false;
		}
		lua_rawset(l, -3);
	}
	return true;
}


bool Codec::decodeField(const google::protobuf::Message *mess, const google::protobuf::FieldDescriptor *fieldDesc, lua_State *l)
{
	if (fieldDesc->is_map())
	{
		return decodeMap(mess, fieldDesc, l);
	}
	else if (fieldDesc->is_repeated())
	{
		return decodeRepeated(mess, fieldDesc, l);
	}
	else if (fieldDesc->is_optional() || fieldDesc->is_required())
	{
		return decodeOptional(mess, fieldDesc, l);
	}

	return false;
}


bool Codec::decodeMessage(const google::protobuf::Message *mess, const google::protobuf::Descriptor *desc, lua_State *l)
{
	//ps(l);
	int cnt = desc->field_count();
	lua_createtable(l, 0, cnt);
	for (int i = 0; i < cnt; ++i)
	{
		const google::protobuf::FieldDescriptor *fieledDesc = desc->field(i);
		bool ok = decodeField(mess, fieledDesc, l);
		if (!ok)
		{
			return false;
		}
		lua_setfield(l, -2, fieledDesc->name().c_str()); // key写入tab {proto中的字段={}}
	}
	return true;
}

bool Codec::decode(const char *name, char *data, size_t lens, lua_State *l)
{
	const google::protobuf::Descriptor *desc = g_importer.pool()->FindMessageTypeByName(name);
	if (!desc)
	{
		logInfo("decode no find name = %s", name);
		return false;
	}

	const google::protobuf::Message *mess = g_factory.GetPrototype(desc);
	if (!mess)
	{
		logInfo("decode no find mess");
		return false;
	}

	std::unique_ptr<google::protobuf::Message> message(mess->New());
	message->ParseFromArray(data, (int)lens);
	decodeMessage(message.get(), desc, l);
	return true;
}



































bool Codec::encoderMessage(google::protobuf::Message *mess, const google::protobuf::Descriptor *desc, lua_State *l, int idx)
{
	//ps(l);
	int fieldCnt = desc->field_count();
	for (int i = 0; i < fieldCnt; ++i)
	{
		const google::protobuf::FieldDescriptor *fieldDesc = desc->field(i);
		//logInfo("xxxxxxxxxxxx %s", fieldDesc->name().c_str());
		lua_getfield(l, idx, fieldDesc->name().c_str()); // proto字段的值压入栈顶
		//ps(l);
		bool ok = encoderField(mess, fieldDesc, l, lua_absindex(l, -1));
		lua_pop(l, 1);
		if (!ok)
		{
			return false;
		}
	}
	return true;
}

bool Codec::encoderField(google::protobuf::Message *mess, const google::protobuf::FieldDescriptor *fieldDesc, lua_State *l, int idx)
{
	// cout << "fieldname = " << fieldDesc->name() << endl;
	// cout << " is_repeated " << fieldDesc->is_repeated() << " is_map " << fieldDesc->is_map() << " is_optional " << fieldDesc->is_optional() << " is_required " << fieldDesc->is_required() << endl;
	// cout << fieldDesc->type() << endl;
	if (fieldDesc->is_map())
	{
		return encoderMap(mess, fieldDesc, l, idx);
	}
	else if (fieldDesc->is_repeated())
	{
		return encoderRepeated(mess, fieldDesc, l, idx);
	}
	else if (fieldDesc->is_optional())
	{
		return encoderOptional(mess, fieldDesc, l, idx);
	}
	else
	{
		logInfo("encoderField no reg field");
		return false;
	}
	return true;
}

bool Codec::encoderRepeatedField(google::protobuf::Message *mess, const google::protobuf::FieldDescriptor *fieldDesc, lua_State *l, int idx)
{
	const google::protobuf::Reflection *reftion = mess->GetReflection();
	int valueType = lua_type(l, idx);
	if(valueType == LUA_TNIL or
	valueType == LUA_TLIGHTUSERDATA or
	valueType == LUA_TFUNCTION or
	valueType == LUA_TUSERDATA or
	valueType == LUA_TTHREAD) 
	{
		logInfo("encoderRepeatedField valueType err field name:%s valuetype:%s", fieldDesc->full_name().c_str(), luaErrName[valueType]);
		return false;
	}

	switch (fieldDesc->cpp_type())
	{
	case google::protobuf::FieldDescriptor::CPPTYPE_DOUBLE:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("encoderRepeatedField valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "double", luaErrName[valueType]);
			return false;
		}

		reftion->AddDouble(mess, fieldDesc, (double)lua_tonumber(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_FLOAT:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("encoderRepeatedField valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "float", luaErrName[valueType]);
			return false;
		}

		reftion->AddFloat(mess, fieldDesc, (float)lua_tonumber(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_INT32:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("encoderRepeatedField valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "int32", luaErrName[valueType]);
			return false;
		}

		reftion->AddInt32(mess, fieldDesc, (google::protobuf::int32)lua_tointeger(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_UINT32:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("encoderRepeatedField valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "uint32", luaErrName[valueType]);
			return false;
		}

		reftion->AddUInt32(mess, fieldDesc, (google::protobuf::uint32)lua_tointeger(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_INT64:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("encoderRepeatedField valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "int64", luaErrName[valueType]);
			return false;
		}

		reftion->AddInt64(mess, fieldDesc, (google::protobuf::int64)lua_tointeger(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_UINT64:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("encoderRepeatedField valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "uint64", luaErrName[valueType]);
			return false;
		}

		reftion->AddUInt64(mess, fieldDesc, (google::protobuf::uint64)lua_tointeger(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_ENUM:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("encoderRepeatedField valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "enum", luaErrName[valueType]);
			return false;
		}

		reftion->AddEnumValue(mess, fieldDesc, (int)lua_tointeger(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_BOOL:
		if(valueType != LUA_TBOOLEAN)
		{
			logInfo("encoderRepeatedField valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "bool", luaErrName[valueType]);
			return false;
		}

		reftion->AddBool(mess, fieldDesc, lua_toboolean(l, idx) != 0);
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_STRING:
	{
		if(valueType != LUA_TSTRING)
		{
			logInfo("encoderRepeatedField valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "string", luaErrName[valueType]);
			return false;
		}

		size_t dataLen = 0;
		const char *data = lua_tolstring(l, idx, &dataLen);
		reftion->AddString(mess, fieldDesc, std::string(data, dataLen));
		return true;
	}
	case google::protobuf::FieldDescriptor::CPPTYPE_MESSAGE:
	{
		google::protobuf::Message *submessage = reftion->AddMessage(mess, fieldDesc);
		return encoderMessage(submessage, fieldDesc->message_type(), l, idx);;
	}
	default:
		logInfo("encoderRepeatedField err, field = %s", fieldDesc->full_name().c_str());
		return false;
	}
}

bool Codec::encoderMap(google::protobuf::Message *mess, const google::protobuf::FieldDescriptor *fieldDesc, lua_State *l, int idx)
{
	if (lua_isnil(l, idx))
	{
		logInfo("encoderMap err nil val, field name = %s", fieldDesc->full_name().c_str());
		return false;
	}
	if (!lua_istable(l, idx))
	{
		logInfo("encoderMap err nil val, field name = %s", fieldDesc->full_name().c_str());
		return false;
	}
	const google::protobuf::Reflection *reftion = mess->GetReflection();
	const google::protobuf::Descriptor *desc = fieldDesc->message_type();
	if (desc->field_count() != 2)
	{
		logInfo("encoderMap err desc->field_count() != 2, name = %s, cnt = %d", fieldDesc->full_name().c_str(), desc->field_count());
		return false;
	}
	const google::protobuf::FieldDescriptor *key = desc->field(0);
	const google::protobuf::FieldDescriptor *val = desc->field(1);
	lua_pushnil(l);
	while (lua_next(l, idx))
	{
		google::protobuf::Message *submess = reftion->AddMessage(mess, fieldDesc);

		bool ok = encoderField(submess, key, l, lua_absindex(l, -2));
		if (!ok)
		{
			lua_pop(l, 2);
			return false;
		}
		ok = encoderField(submess, val, l, lua_absindex(l, -1));
		if (!ok)
		{
			lua_pop(l, 2);
			return false;
		}
		lua_pop(l, 1);
	}
	return true;
}

bool Codec::encoderRepeated(google::protobuf::Message *mess, const google::protobuf::FieldDescriptor *fieldDesc, lua_State *l, int idx)
{
	//ps(l);
	if (!lua_istable(l, idx))
	{
		logInfo("not a table name:%s", fieldDesc->full_name().c_str());
		return false;
	}

	int cnt = (int)luaL_len(l, idx);
	for (int i = 1; i <= cnt; ++i)
	{
		lua_geti(l, idx, i); // 当前lua数组的第i个数据放到栈顶
		//ps(l);
		bool ok = encoderRepeatedField(mess, fieldDesc, l, lua_absindex(l, -1));
		lua_pop(l, 1);
		if (!ok)
		{
			return false;
		}
	}
	return true;
}



bool Codec::encoderOptional(google::protobuf::Message *mess, const google::protobuf::FieldDescriptor *fieldDesc, lua_State *l, int idx)
{
	//ps(l);
	int valueType = lua_type(l, idx);
	if(valueType == LUA_TNIL or
	valueType == LUA_TLIGHTUSERDATA or
	valueType == LUA_TFUNCTION or
	valueType == LUA_TUSERDATA or
	valueType == LUA_TTHREAD) 
	{
		logInfo("valueType err field name:%s valuetype:%s", fieldDesc->full_name().c_str(), luaErrName[valueType]);
		return false;
	}

	const google::protobuf::Reflection *reftion = mess->GetReflection();
	switch (fieldDesc->cpp_type())
	{
	case google::protobuf::FieldDescriptor::CPPTYPE_DOUBLE:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "double", luaErrName[valueType]);
			return false;
		}

		reftion->SetDouble(mess, fieldDesc, (double)lua_tonumber(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_FLOAT:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "float", luaErrName[valueType]);
			return false;
		}

		reftion->SetFloat(mess, fieldDesc, (float)lua_tonumber(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_INT32:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "int32", luaErrName[valueType]);
			return false;
		}

		reftion->SetInt32(mess, fieldDesc, (google::protobuf::int32)lua_tointeger(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_INT64:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "int64", luaErrName[valueType]);
			return false;
		}

		reftion->SetInt64(mess, fieldDesc, (google::protobuf::int64)lua_tointeger(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_UINT32:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "uint32", luaErrName[valueType]);
			return false;
		}

		reftion->SetUInt32(mess, fieldDesc, (google::protobuf::uint32)lua_tointeger(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_UINT64:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "uint64", luaErrName[valueType]);
			return false;
		}

		reftion->SetUInt64(mess, fieldDesc, (google::protobuf::uint64)lua_tointeger(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_ENUM:
		if(valueType != LUA_TNUMBER)
		{
			logInfo("valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "enum", luaErrName[valueType]);
			return false;
		}

		reftion->SetEnumValue(mess, fieldDesc, (int)lua_tointeger(l, idx));
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_BOOL:
		if(valueType != LUA_TBOOLEAN)
		{
			logInfo("valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "bool", luaErrName[valueType]);
			return false;
		}

		reftion->SetBool(mess, fieldDesc, lua_toboolean(l, idx) != 0);
		return true;
	case google::protobuf::FieldDescriptor::CPPTYPE_STRING:
	{
		if(valueType != LUA_TSTRING)
		{
			logInfo("valueType no matching field name:%s needType:%s giveType:%s", fieldDesc->full_name().c_str(), "string", luaErrName[valueType]);
			return false;
		}

		size_t len = 0;
		const char *data = lua_tolstring(l, idx, &len);
		reftion->SetString(mess, fieldDesc, std::string(data, len));
		return true;
	}
	case google::protobuf::FieldDescriptor::CPPTYPE_MESSAGE:
	{
		google::protobuf::Message *subMess = reftion->MutableMessage(mess, fieldDesc);
		return encoderMessage(subMess, fieldDesc->message_type(), l, idx);
	}
	default:
		logInfo("no support type, name:%s", fieldDesc->full_name().c_str());
		return false;
	}
}

std::unique_ptr<google::protobuf::Message> Codec::encoder(const char *name, lua_State *l, int idx)
{
	const google::protobuf::Descriptor *desc = g_importer.pool()->FindMessageTypeByName(name);
	if (!desc)
	{
		logInfo("no find desc, name:%s", name);
		return nullptr;
	}
	const google::protobuf::Message *mess = g_factory.GetPrototype(desc);
	if (!mess)
	{
		logInfo("no find mess, name:%s", name);
		return nullptr;
	}

	
	std::unique_ptr<google::protobuf::Message> message(mess->New());
	
	if (!encoderMessage(message.get(), desc, l, idx))
	{
		return nullptr;
	}
	return message;
}
