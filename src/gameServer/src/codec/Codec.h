#pragma once

#include <string>


#include "../../../../libs/google/protobuf/dynamic_message.h"
#include "../../../../libs/google/protobuf/compiler/importer.h"

struct lua_State;
class Descriptor;
class Message;
class FieldDescriptor;






struct Codec
{

	inline static void ps(lua_State* L);
	static bool decode(const char* name, char* data, size_t lens, lua_State* l); // c++消息转为lua table
	static bool decodeMessage(const google::protobuf::Message* mess, const google::protobuf::Descriptor* desc, lua_State* l);
	static bool decodeField(const google::protobuf::Message* mess, const google::protobuf::FieldDescriptor* fieldDesc, lua_State* l);
	static bool decodeMap(const google::protobuf::Message* mess, const google::protobuf::FieldDescriptor* fieldDesc, lua_State* l);
	static bool decodeRepeated(const google::protobuf::Message* mess, const google::protobuf::FieldDescriptor* fieldDesc, lua_State* l);
	static bool decodeOptional(const google::protobuf::Message* mess, const google::protobuf::FieldDescriptor* fieldDesc, lua_State* l);
	static bool decoderRepeatedField(const google::protobuf::Message* mess, const google::protobuf::FieldDescriptor* fieldDesc, lua_State* l, int index);

	static bool encoderMessage(google::protobuf::Message* mess, const google::protobuf::Descriptor* desc, lua_State* l, int idx);
	static bool encoderField(google::protobuf::Message* mess, const google::protobuf::FieldDescriptor* fieldDesc, lua_State* l, int idx);
	static bool encoderRepeatedField(google::protobuf::Message* mess, const google::protobuf::FieldDescriptor* fieldDesc, lua_State* l, int idx);
	static bool encoderMap(google::protobuf::Message* mess, const google::protobuf::FieldDescriptor* fieldDesc, lua_State* l, int idx);
	static bool encoderRepeated(google::protobuf::Message* mess, const google::protobuf::FieldDescriptor* fieldDesc, lua_State* l, int idx);
	static bool encoderOptional(google::protobuf::Message* mess, const google::protobuf::FieldDescriptor* fieldDesc, lua_State* l, int idx);
	static std::unique_ptr<google::protobuf::Message> encoder(const char* name, lua_State* l, int idx); // lua消息转换为c++
};
