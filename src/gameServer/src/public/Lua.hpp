
#pragma once

#include <stdio.h>
#include <vector>
#include <map>
#include <string>
#include <unordered_map>
#include <stdint.h>

#include "../../../../libs/google/protobuf/dynamic_message.h"

#include "../../../../libs/jemalloc/jemalloc.h"
#include "../../../../libs/lua/lua.hpp"
#include "../codec/Codec.h"
#include "../../../common/log/Log.h"
#include "../../../common/net/Data.h"
class Player;

namespace LuaBind
{

	inline void show(lua_State *l)
	{
		int i;
		int top = lua_gettop(l);
		printf("stackDump(num=%d):\n", top);
		for (i = 1; i <= top; i++)
		{
			int t = lua_type(l, i);
			switch (t)
			{
			case LUA_TSTRING:
				printf("`%s'", lua_tostring(l, i));
				break;
			case LUA_TBOOLEAN:
				printf(lua_toboolean(l, i) ? "true" : "false");
				break;
			case LUA_TNUMBER:
				printf("%g", lua_tonumber(l, i));
				break;
			default:
				printf("%s", lua_typename(l, t));
				break;
			}
			printf("  ");
		}
		printf("\n");
	}

	struct BaseFunc
	{
		BaseFunc()
		{
		}
		~BaseFunc()
		{
			// logInfo("		~BaseFunc()");
		}
		virtual int call(lua_State *L) { return 0; }
	};

	inline const char *errName(const char *val)
	{
		if (!val)
		{
			return "unknown";
		}
		return val;
	}

	inline void showStack(int deep, lua_State *l)
	{
		lua_Debug debug;
		if (lua_getstack(l, deep, &debug))
		{
			lua_getinfo(l, "nSl", &debug);
			if (debug.name)
			{
				logInfo("file=%s, line = %d, errName = %s, errMess = %s, line = %d", debug.source, debug.currentline, errName(debug.name), debug.short_src, debug.linedefined);
			}
			showStack(deep + 1, l);
		}
	}

	inline int errFunc(lua_State *l)
	{
		logInfo("error : %s", lua_tostring(l, -1));
		showStack(0, l);
		return 0;
	}

	template <typename T>
	struct GlobalName
	{
		static const char *clsName;
		static inline void setName(const char *name) { clsName = name; }
		static inline const char *getName() { return clsName; }
	};

	template <typename T>
	const char *GlobalName<T>::clsName = nullptr;

	template <typename T>
	struct ObjData
	{
		ObjData(T *obj) { this->obj = obj; }
		~ObjData()
		{
			obj = nullptr;
		}
		T *obj;
	};

	template <typename T>
	struct GetCppObj
	{
		inline static T getCppObj(int idx, lua_State *l)
		{
			ObjData<T> **od = (ObjData<T> **)lua_touserdata(l, idx);
			return *((*od)->obj);
		}
	};

	template <typename T>
	struct GetCppObj<T &>
	{
		inline static T &getCppObj(int idx, lua_State *l)
		{
			ObjData<T> **od = (ObjData<T> **)(lua_touserdata(l, idx));
			return *((*od)->obj);
		}
	};

	template <typename T>
	struct GetCppObj<T *>
	{
		inline static T *getCppObj(int idx, lua_State *l)
		{
			ObjData<T> **od = (ObjData<T> **)(lua_touserdata(l, idx));
			return (*od)->obj;
		}
	};

	template <typename T>
	inline T getLuaVal(int idx, lua_State *l)
	{
		// show(l);
		if (!lua_isuserdata(l, idx))
		{
			// lua_pushfstring(l, "%d pos agr no userdata", idx);
			return nullptr;
		}
		return GetCppObj<T>::getCppObj(idx, l);
	}

	template <typename T>
	inline std::vector<T> getVevtor(int idx, lua_State *l)
	{
		std::vector<T> vec;
		int cnt = (int)luaL_len(l, idx);
		for (int i = 1; i <= cnt; ++i)
		{
			lua_rawgeti(l, idx, i);
			T t = getLuaVal<T>(-1, l);
			vec.emplace_back(t);
		}
		return vec;
	}

	template <typename K, typename V>
	inline std::map<K, V> getMapVal(int idx, lua_State *l)
	{
		lua_pushnil(l);
		std::map<K, V> tab;
		// show(l);
		while (lua_next(l, idx) != 0)
		{ //-1=val, -2=k
			lua_pushvalue(l, -2);
			K k = getLuaVal<K>(-1, l);
			V v = getLuaVal<V>(-2, l);
			tab.emplace(k, v);
			lua_pop(l, 2);
		}
		return tab;
	}

	template <typename K, typename V>
	inline std::unordered_map<K, V> getMapVal1(int idx, lua_State *l)
	{
		lua_pushnil(l);
		std::unordered_map<K, V> tab;
		// show(l);
		while (lua_next(l, idx) != 0)
		{ //-1=val, -2=k
			lua_pushvalue(l, -2);
			K k = getLuaVal<K>(-1, l);
			V v = getLuaVal<V>(-2, l);
			tab.emplace(k, v);
			lua_pop(l, 2);
		}
		return tab;
	}

	template <>
	inline std::string getLuaVal(int idx, lua_State *l)
	{
		size_t len;
		const char *s = (const char *)lua_tolstring(l, idx, &len);
		return std::string(s, len);
	}
	template <>
	inline const std::string getLuaVal(int idx, lua_State *l)
	{
		size_t len;
		const char *s = (const char *)lua_tolstring(l, idx, &len);
		return std::string(s, len);
	}
	template <>
	inline bool getLuaVal(int idx, lua_State *l) { return lua_toboolean(l, idx) ? true : false; }
	template <>
	inline char *getLuaVal(int idx, lua_State *l) { return (char *)lua_tostring(l, idx); }
	template <>
	inline const char *getLuaVal(int idx, lua_State *l) { return (const char *)lua_tostring(l, idx); }
	template <>
	inline char getLuaVal(int idx, lua_State *l) { return (char)lua_tonumber(l, idx); }
	template <>
	inline unsigned char getLuaVal(int idx, lua_State *l) { return (unsigned char)lua_tonumber(l, idx); }
	template <>
	inline short getLuaVal(int idx, lua_State *l) { return (short)lua_tonumber(l, idx); }
	template <>
	inline unsigned short getLuaVal(int idx, lua_State *l) { return (unsigned short)lua_tonumber(l, idx); }
	template <>
	inline long getLuaVal(int idx, lua_State *l) { return (long)lua_tonumber(l, idx); }
	template <>
	inline unsigned long getLuaVal(int idx, lua_State *l) { return (unsigned long)lua_tonumber(l, idx); }
	template <>
	inline int getLuaVal(int idx, lua_State *l) { return (int)lua_tonumber(l, idx); }
	template <>
	inline unsigned int getLuaVal(int idx, lua_State *l) { return (unsigned int)lua_tonumber(l, idx); }
	template <>
	inline long long getLuaVal(int idx, lua_State *l) { return (long long)lua_tonumber(l, idx); }
	template <>
	inline unsigned long long getLuaVal(int idx, lua_State *l) { return (unsigned long long)lua_tonumber(l, idx); }
	template <>
	inline float getLuaVal(int idx, lua_State *l) { return (float)lua_tonumber(l, idx); }
	template <>
	inline double getLuaVal(int idx, lua_State *l) { return (double)lua_tonumber(l, idx); }
	template <>
	inline std::vector<bool> getLuaVal(int idx, lua_State *l) { return getVevtor<bool>(idx, l); }
	template <>
	inline std::vector<char> getLuaVal(int idx, lua_State *l) { return getVevtor<char>(idx, l); }
	template <>
	inline std::vector<char *> getLuaVal(int idx, lua_State *l) { return getVevtor<char *>(idx, l); }
	template <>
	inline std::vector<const char *> getLuaVal(int idx, lua_State *l) { return getVevtor<const char *>(idx, l); }
	template <>
	inline std::vector<unsigned char> getLuaVal(int idx, lua_State *l) { return getVevtor<unsigned char>(idx, l); }
	template <>
	inline std::vector<short> getLuaVal(int idx, lua_State *l) { return getVevtor<short>(idx, l); }
	template <>
	inline std::vector<unsigned short> getLuaVal(int idx, lua_State *l) { return getVevtor<unsigned short>(idx, l); }
	template <>
	inline std::vector<float> getLuaVal(int idx, lua_State *l) { return getVevtor<float>(idx, l); }
	template <>
	inline std::vector<double> getLuaVal(int idx, lua_State *l) { return getVevtor<double>(idx, l); }
	template <>
	inline std::vector<int> getLuaVal(int idx, lua_State *l) { return getVevtor<int>(idx, l); }
	template <>
	inline std::vector<unsigned int> getLuaVal(int idx, lua_State *l) { return getVevtor<unsigned int>(idx, l); }
	template <>
	inline std::vector<long> getLuaVal(int idx, lua_State *l) { return getVevtor<long>(idx, l); }
	template <>
	inline std::vector<unsigned long> getLuaVal(int idx, lua_State *l) { return getVevtor<unsigned long>(idx, l); }
	template <>
	inline std::vector<long long> getLuaVal(int idx, lua_State *l) { return getVevtor<long long>(idx, l); }
	template <>
	inline std::vector<unsigned long long> getLuaVal(int idx, lua_State *l) { return getVevtor<unsigned long long>(idx, l); }
	template <>
	inline std::map<bool, bool> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, bool>(idx, l); }
	template <>
	inline std::map<bool, char> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, char>(idx, l); }
	template <>
	inline std::map<bool, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, char *>(idx, l); }
	template <>
	inline std::map<bool, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, const char *>(idx, l); }
	template <>
	inline std::map<bool, float> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, float>(idx, l); }
	template <>
	inline std::map<bool, double> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, double>(idx, l); }
	template <>
	inline std::map<bool, short> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, short>(idx, l); }
	template <>
	inline std::map<bool, int> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, int>(idx, l); }
	template <>
	inline std::map<bool, long> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, long>(idx, l); }
	template <>
	inline std::map<bool, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, long long>(idx, l); }
	template <>
	inline std::map<bool, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, unsigned char>(idx, l); }
	template <>
	inline std::map<bool, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, unsigned short>(idx, l); }
	template <>
	inline std::map<bool, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, unsigned int>(idx, l); }
	template <>
	inline std::map<bool, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, unsigned long>(idx, l); }
	template <>
	inline std::map<bool, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<bool, unsigned long long>(idx, l); }
	template <>
	inline std::map<char, char> getLuaVal(int idx, lua_State *l) { return getMapVal<char, char>(idx, l); }
	template <>
	inline std::map<char, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<char, char *>(idx, l); }
	template <>
	inline std::map<char, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<char, const char *>(idx, l); }
	template <>
	inline std::map<char, float> getLuaVal(int idx, lua_State *l) { return getMapVal<char, float>(idx, l); }
	template <>
	inline std::map<char, double> getLuaVal(int idx, lua_State *l) { return getMapVal<char, double>(idx, l); }
	template <>
	inline std::map<char, short> getLuaVal(int idx, lua_State *l) { return getMapVal<char, short>(idx, l); }
	template <>
	inline std::map<char, int> getLuaVal(int idx, lua_State *l) { return getMapVal<char, int>(idx, l); }
	template <>
	inline std::map<char, long> getLuaVal(int idx, lua_State *l) { return getMapVal<char, long>(idx, l); }
	template <>
	inline std::map<char, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<char, long long>(idx, l); }
	template <>
	inline std::map<char, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<char, unsigned char>(idx, l); }
	template <>
	inline std::map<char, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<char, unsigned short>(idx, l); }
	template <>
	inline std::map<char, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<char, unsigned int>(idx, l); }
	template <>
	inline std::map<char, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<char, unsigned long>(idx, l); }
	template <>
	inline std::map<char, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<char, unsigned long long>(idx, l); }
	template <>
	inline std::map<char *, char> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, char>(idx, l); }
	template <>
	inline std::map<char *, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, char *>(idx, l); }
	template <>
	inline std::map<char *, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, const char *>(idx, l); }
	template <>
	inline std::map<char *, float> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, float>(idx, l); }
	template <>
	inline std::map<char *, double> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, double>(idx, l); }
	template <>
	inline std::map<char *, short> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, short>(idx, l); }
	template <>
	inline std::map<char *, int> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, int>(idx, l); }
	template <>
	inline std::map<char *, long> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, long>(idx, l); }
	template <>
	inline std::map<char *, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, long long>(idx, l); }
	template <>
	inline std::map<char *, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, unsigned char>(idx, l); }
	template <>
	inline std::map<char *, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, unsigned short>(idx, l); }
	template <>
	inline std::map<char *, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, unsigned int>(idx, l); }
	template <>
	inline std::map<char *, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, unsigned long>(idx, l); }
	template <>
	inline std::map<char *, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<char *, unsigned long long>(idx, l); }
	template <>
	inline std::map<const char *, char> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, char>(idx, l); }
	template <>
	inline std::map<const char *, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, char *>(idx, l); }
	template <>
	inline std::map<const char *, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, const char *>(idx, l); }
	template <>
	inline std::map<const char *, float> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, float>(idx, l); }
	template <>
	inline std::map<const char *, double> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, double>(idx, l); }
	template <>
	inline std::map<const char *, short> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, short>(idx, l); }
	template <>
	inline std::map<const char *, int> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, int>(idx, l); }
	template <>
	inline std::map<const char *, long> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, long>(idx, l); }
	template <>
	inline std::map<const char *, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, long long>(idx, l); }
	template <>
	inline std::map<const char *, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, unsigned char>(idx, l); }
	template <>
	inline std::map<const char *, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, unsigned short>(idx, l); }
	template <>
	inline std::map<const char *, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, unsigned int>(idx, l); }
	template <>
	inline std::map<const char *, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, unsigned long>(idx, l); }
	template <>
	inline std::map<const char *, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<const char *, unsigned long long>(idx, l); }
	template <>
	inline std::map<unsigned char, char> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, char>(idx, l); }
	template <>
	inline std::map<unsigned char, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, char *>(idx, l); }
	template <>
	inline std::map<unsigned char, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, const char *>(idx, l); }
	template <>
	inline std::map<unsigned char, float> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, float>(idx, l); }
	template <>
	inline std::map<unsigned char, double> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, double>(idx, l); }
	template <>
	inline std::map<unsigned char, short> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, short>(idx, l); }
	template <>
	inline std::map<unsigned char, int> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, int>(idx, l); }
	template <>
	inline std::map<unsigned char, long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, long>(idx, l); }
	template <>
	inline std::map<unsigned char, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, long long>(idx, l); }
	template <>
	inline std::map<unsigned char, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, unsigned char>(idx, l); }
	template <>
	inline std::map<unsigned char, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, unsigned short>(idx, l); }
	template <>
	inline std::map<unsigned char, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, unsigned int>(idx, l); }
	template <>
	inline std::map<unsigned char, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, unsigned long>(idx, l); }
	template <>
	inline std::map<unsigned char, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned char, unsigned long long>(idx, l); }
	template <>
	inline std::map<float, char> getLuaVal(int idx, lua_State *l) { return getMapVal<float, char>(idx, l); }
	template <>
	inline std::map<float, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<float, char *>(idx, l); }
	template <>
	inline std::map<float, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<float, const char *>(idx, l); }
	template <>
	inline std::map<float, float> getLuaVal(int idx, lua_State *l) { return getMapVal<float, float>(idx, l); }
	template <>
	inline std::map<float, double> getLuaVal(int idx, lua_State *l) { return getMapVal<float, double>(idx, l); }
	template <>
	inline std::map<float, short> getLuaVal(int idx, lua_State *l) { return getMapVal<float, short>(idx, l); }
	template <>
	inline std::map<float, int> getLuaVal(int idx, lua_State *l) { return getMapVal<float, int>(idx, l); }
	template <>
	inline std::map<float, long> getLuaVal(int idx, lua_State *l) { return getMapVal<float, long>(idx, l); }
	template <>
	inline std::map<float, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<float, long long>(idx, l); }
	template <>
	inline std::map<float, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<float, unsigned char>(idx, l); }
	template <>
	inline std::map<float, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<float, unsigned short>(idx, l); }
	template <>
	inline std::map<float, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<float, unsigned int>(idx, l); }
	template <>
	inline std::map<float, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<float, unsigned long>(idx, l); }
	template <>
	inline std::map<float, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<float, unsigned long long>(idx, l); }
	template <>
	inline std::map<double, char> getLuaVal(int idx, lua_State *l) { return getMapVal<double, char>(idx, l); }
	template <>
	inline std::map<double, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<double, char *>(idx, l); }
	template <>
	inline std::map<double, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<double, const char *>(idx, l); }
	template <>
	inline std::map<double, float> getLuaVal(int idx, lua_State *l) { return getMapVal<double, float>(idx, l); }
	template <>
	inline std::map<double, double> getLuaVal(int idx, lua_State *l) { return getMapVal<double, double>(idx, l); }
	template <>
	inline std::map<double, short> getLuaVal(int idx, lua_State *l) { return getMapVal<double, short>(idx, l); }
	template <>
	inline std::map<double, int> getLuaVal(int idx, lua_State *l) { return getMapVal<double, int>(idx, l); }
	template <>
	inline std::map<double, long> getLuaVal(int idx, lua_State *l) { return getMapVal<double, long>(idx, l); }
	template <>
	inline std::map<double, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<double, long long>(idx, l); }
	template <>
	inline std::map<double, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<double, unsigned char>(idx, l); }
	template <>
	inline std::map<double, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<double, unsigned short>(idx, l); }
	template <>
	inline std::map<double, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<double, unsigned int>(idx, l); }
	template <>
	inline std::map<double, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<double, unsigned long>(idx, l); }
	template <>
	inline std::map<double, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<double, unsigned long long>(idx, l); }
	template <>
	inline std::map<short, char> getLuaVal(int idx, lua_State *l) { return getMapVal<short, char>(idx, l); }
	template <>
	inline std::map<short, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<short, char *>(idx, l); }
	template <>
	inline std::map<short, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<short, const char *>(idx, l); }
	template <>
	inline std::map<short, float> getLuaVal(int idx, lua_State *l) { return getMapVal<short, float>(idx, l); }
	template <>
	inline std::map<short, double> getLuaVal(int idx, lua_State *l) { return getMapVal<short, double>(idx, l); }
	template <>
	inline std::map<short, short> getLuaVal(int idx, lua_State *l) { return getMapVal<short, short>(idx, l); }
	template <>
	inline std::map<short, int> getLuaVal(int idx, lua_State *l) { return getMapVal<short, int>(idx, l); }
	template <>
	inline std::map<short, long> getLuaVal(int idx, lua_State *l) { return getMapVal<short, long>(idx, l); }
	template <>
	inline std::map<short, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<short, long long>(idx, l); }
	template <>
	inline std::map<short, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<short, unsigned char>(idx, l); }
	template <>
	inline std::map<short, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<short, unsigned short>(idx, l); }
	template <>
	inline std::map<short, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<short, unsigned int>(idx, l); }
	template <>
	inline std::map<short, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<short, unsigned long>(idx, l); }
	template <>
	inline std::map<short, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<short, unsigned long long>(idx, l); }
	template <>
	inline std::map<unsigned short, char> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, char>(idx, l); }
	template <>
	inline std::map<unsigned short, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, char *>(idx, l); }
	template <>
	inline std::map<unsigned short, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, const char *>(idx, l); }
	template <>
	inline std::map<unsigned short, float> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, float>(idx, l); }
	template <>
	inline std::map<unsigned short, double> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, double>(idx, l); }
	template <>
	inline std::map<unsigned short, short> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, short>(idx, l); }
	template <>
	inline std::map<unsigned short, int> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, int>(idx, l); }
	template <>
	inline std::map<unsigned short, long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, long>(idx, l); }
	template <>
	inline std::map<unsigned short, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, long long>(idx, l); }
	template <>
	inline std::map<unsigned short, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, unsigned char>(idx, l); }
	template <>
	inline std::map<unsigned short, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, unsigned short>(idx, l); }
	template <>
	inline std::map<unsigned short, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, unsigned int>(idx, l); }
	template <>
	inline std::map<unsigned short, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, unsigned long>(idx, l); }
	template <>
	inline std::map<unsigned short, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned short, unsigned long long>(idx, l); }
	template <>
	inline std::map<int, std::string> getLuaVal(int idx, lua_State *l) { return getMapVal<int, std::string>(idx, l); }
	template <>
	inline std::map<int, char> getLuaVal(int idx, lua_State *l) { return getMapVal<int, char>(idx, l); }
	template <>
	inline std::map<int, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<int, char *>(idx, l); }
	template <>
	inline std::map<int, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<int, const char *>(idx, l); }
	template <>
	inline std::map<int, float> getLuaVal(int idx, lua_State *l) { return getMapVal<int, float>(idx, l); }
	template <>
	inline std::map<int, double> getLuaVal(int idx, lua_State *l) { return getMapVal<int, double>(idx, l); }
	template <>
	inline std::map<int, short> getLuaVal(int idx, lua_State *l) { return getMapVal<int, short>(idx, l); }
	template <>
	inline std::map<int, int> getLuaVal(int idx, lua_State *l) { return getMapVal<int, int>(idx, l); }
	template <>
	inline std::map<int, long> getLuaVal(int idx, lua_State *l) { return getMapVal<int, long>(idx, l); }
	template <>
	inline std::map<int, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<int, long long>(idx, l); }
	template <>
	inline std::map<int, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<int, unsigned char>(idx, l); }
	template <>
	inline std::map<int, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<int, unsigned short>(idx, l); }
	template <>
	inline std::map<int, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<int, unsigned int>(idx, l); }
	template <>
	inline std::map<int, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<int, unsigned long>(idx, l); }
	template <>
	inline std::map<int, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<int, unsigned long long>(idx, l); }
	template <>
	inline std::map<unsigned int, char> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, char>(idx, l); }
	template <>
	inline std::map<unsigned int, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, char *>(idx, l); }
	template <>
	inline std::map<unsigned int, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, const char *>(idx, l); }
	template <>
	inline std::map<unsigned int, float> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, float>(idx, l); }
	template <>
	inline std::map<unsigned int, double> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, double>(idx, l); }
	template <>
	inline std::map<unsigned int, short> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, short>(idx, l); }
	template <>
	inline std::map<unsigned int, int> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, int>(idx, l); }
	template <>
	inline std::map<unsigned int, long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, long>(idx, l); }
	template <>
	inline std::map<unsigned int, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, long long>(idx, l); }
	template <>
	inline std::map<unsigned int, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, unsigned char>(idx, l); }
	template <>
	inline std::map<unsigned int, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, unsigned short>(idx, l); }
	template <>
	inline std::map<unsigned int, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, unsigned int>(idx, l); }
	template <>
	inline std::map<unsigned int, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, unsigned long>(idx, l); }
	template <>
	inline std::map<unsigned int, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned int, unsigned long long>(idx, l); }
	template <>
	inline std::map<long, char> getLuaVal(int idx, lua_State *l) { return getMapVal<long, char>(idx, l); }
	template <>
	inline std::map<long, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<long, char *>(idx, l); }
	template <>
	inline std::map<long, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<long, const char *>(idx, l); }
	template <>
	inline std::map<long, float> getLuaVal(int idx, lua_State *l) { return getMapVal<long, float>(idx, l); }
	template <>
	inline std::map<long, double> getLuaVal(int idx, lua_State *l) { return getMapVal<long, double>(idx, l); }
	template <>
	inline std::map<long, short> getLuaVal(int idx, lua_State *l) { return getMapVal<long, short>(idx, l); }
	template <>
	inline std::map<long, int> getLuaVal(int idx, lua_State *l) { return getMapVal<long, int>(idx, l); }
	template <>
	inline std::map<long, long> getLuaVal(int idx, lua_State *l) { return getMapVal<long, long>(idx, l); }
	template <>
	inline std::map<long, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<long, long long>(idx, l); }
	template <>
	inline std::map<long, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<long, unsigned char>(idx, l); }
	template <>
	inline std::map<long, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<long, unsigned short>(idx, l); }
	template <>
	inline std::map<long, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<long, unsigned int>(idx, l); }
	template <>
	inline std::map<long, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<long, unsigned long>(idx, l); }
	template <>
	inline std::map<long, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<long, unsigned long long>(idx, l); }
	template <>
	inline std::map<unsigned long, char> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, char>(idx, l); }
	template <>
	inline std::map<unsigned long, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, char *>(idx, l); }
	template <>
	inline std::map<unsigned long, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, const char *>(idx, l); }
	template <>
	inline std::map<unsigned long, float> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, float>(idx, l); }
	template <>
	inline std::map<unsigned long, double> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, double>(idx, l); }
	template <>
	inline std::map<unsigned long, short> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, short>(idx, l); }
	template <>
	inline std::map<unsigned long, int> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, int>(idx, l); }
	template <>
	inline std::map<unsigned long, long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, long>(idx, l); }
	template <>
	inline std::map<unsigned long, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, long long>(idx, l); }
	template <>
	inline std::map<unsigned long, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, unsigned char>(idx, l); }
	template <>
	inline std::map<unsigned long, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, unsigned short>(idx, l); }
	template <>
	inline std::map<unsigned long, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, unsigned int>(idx, l); }
	template <>
	inline std::map<unsigned long, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, unsigned long>(idx, l); }
	template <>
	inline std::map<unsigned long, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long, unsigned long long>(idx, l); }
	template <>
	inline std::map<long long, char> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, char>(idx, l); }
	template <>
	inline std::map<long long, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, char *>(idx, l); }
	template <>
	inline std::map<long long, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, const char *>(idx, l); }
	template <>
	inline std::map<long long, float> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, float>(idx, l); }
	template <>
	inline std::map<long long, double> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, double>(idx, l); }
	template <>
	inline std::map<long long, short> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, short>(idx, l); }
	template <>
	inline std::map<long long, int> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, int>(idx, l); }
	template <>
	inline std::map<long long, long> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, long>(idx, l); }
	template <>
	inline std::map<long long, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, long long>(idx, l); }
	template <>
	inline std::map<long long, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, unsigned char>(idx, l); }
	template <>
	inline std::map<long long, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, unsigned short>(idx, l); }
	template <>
	inline std::map<long long, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, unsigned int>(idx, l); }
	template <>
	inline std::map<long long, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, unsigned long>(idx, l); }
	template <>
	inline std::map<long long, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<long long, unsigned long long>(idx, l); }
	template <>
	inline std::map<unsigned long long, char> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, char>(idx, l); }
	template <>
	inline std::map<unsigned long long, char *> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, char *>(idx, l); }
	template <>
	inline std::map<unsigned long long, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, const char *>(idx, l); }
	template <>
	inline std::map<unsigned long long, float> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, float>(idx, l); }
	template <>
	inline std::map<unsigned long long, double> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, double>(idx, l); }
	template <>
	inline std::map<unsigned long long, short> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, short>(idx, l); }
	template <>
	inline std::map<unsigned long long, int> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, int>(idx, l); }
	template <>
	inline std::map<unsigned long long, long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, long>(idx, l); }
	template <>
	inline std::map<unsigned long long, long long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, long long>(idx, l); }
	template <>
	inline std::map<unsigned long long, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, unsigned char>(idx, l); }
	template <>
	inline std::map<unsigned long long, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, unsigned short>(idx, l); }
	template <>
	inline std::map<unsigned long long, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, unsigned int>(idx, l); }
	template <>
	inline std::map<unsigned long long, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, unsigned long>(idx, l); }
	template <>
	inline std::map<unsigned long long, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal<unsigned long long, unsigned long long>(idx, l); }

	template <>
	inline std::unordered_map<bool, bool> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, bool>(idx, l); }
	template <>
	inline std::unordered_map<bool, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, char>(idx, l); }
	template <>
	inline std::unordered_map<bool, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, char *>(idx, l); }
	template <>
	inline std::unordered_map<bool, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, const char *>(idx, l); }
	template <>
	inline std::unordered_map<bool, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, float>(idx, l); }
	template <>
	inline std::unordered_map<bool, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, double>(idx, l); }
	template <>
	inline std::unordered_map<bool, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, short>(idx, l); }
	template <>
	inline std::unordered_map<bool, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, int>(idx, l); }
	template <>
	inline std::unordered_map<bool, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, long>(idx, l); }
	template <>
	inline std::unordered_map<bool, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, long long>(idx, l); }
	template <>
	inline std::unordered_map<bool, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<bool, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<bool, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<bool, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<bool, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<bool, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<char, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, char>(idx, l); }
	template <>
	inline std::unordered_map<char, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, char *>(idx, l); }
	template <>
	inline std::unordered_map<char, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, const char *>(idx, l); }
	template <>
	inline std::unordered_map<char, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, float>(idx, l); }
	template <>
	inline std::unordered_map<char, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, double>(idx, l); }
	template <>
	inline std::unordered_map<char, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, short>(idx, l); }
	template <>
	inline std::unordered_map<char, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, int>(idx, l); }
	template <>
	inline std::unordered_map<char, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, long>(idx, l); }
	template <>
	inline std::unordered_map<char, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, long long>(idx, l); }
	template <>
	inline std::unordered_map<char, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<char, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<char, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<char, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<char, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<char, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<char *, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, char>(idx, l); }
	template <>
	inline std::unordered_map<char *, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, char *>(idx, l); }
	template <>
	inline std::unordered_map<char *, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, const char *>(idx, l); }
	template <>
	inline std::unordered_map<char *, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, float>(idx, l); }
	template <>
	inline std::unordered_map<char *, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, double>(idx, l); }
	template <>
	inline std::unordered_map<char *, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, short>(idx, l); }
	template <>
	inline std::unordered_map<char *, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, int>(idx, l); }
	template <>
	inline std::unordered_map<char *, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, long>(idx, l); }
	template <>
	inline std::unordered_map<char *, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, long long>(idx, l); }
	template <>
	inline std::unordered_map<char *, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<char *, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<char *, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<char *, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<char *, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<char *, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<const char *, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, char>(idx, l); }
	template <>
	inline std::unordered_map<const char *, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, char *>(idx, l); }
	template <>
	inline std::unordered_map<const char *, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, const char *>(idx, l); }
	template <>
	inline std::unordered_map<const char *, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, float>(idx, l); }
	template <>
	inline std::unordered_map<const char *, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, double>(idx, l); }
	template <>
	inline std::unordered_map<const char *, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, short>(idx, l); }
	template <>
	inline std::unordered_map<const char *, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, int>(idx, l); }
	template <>
	inline std::unordered_map<const char *, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, long>(idx, l); }
	template <>
	inline std::unordered_map<const char *, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, long long>(idx, l); }
	template <>
	inline std::unordered_map<const char *, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<const char *, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<const char *, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<const char *, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<const char *, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<const char *, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, char>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, char *>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, const char *>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, float>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, double>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, short>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, int>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, long long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned char, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned char, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<float, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, char>(idx, l); }
	template <>
	inline std::unordered_map<float, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, char *>(idx, l); }
	template <>
	inline std::unordered_map<float, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, const char *>(idx, l); }
	template <>
	inline std::unordered_map<float, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, float>(idx, l); }
	template <>
	inline std::unordered_map<float, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, double>(idx, l); }
	template <>
	inline std::unordered_map<float, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, short>(idx, l); }
	template <>
	inline std::unordered_map<float, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, int>(idx, l); }
	template <>
	inline std::unordered_map<float, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, long>(idx, l); }
	template <>
	inline std::unordered_map<float, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, long long>(idx, l); }
	template <>
	inline std::unordered_map<float, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<float, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<float, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<float, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<float, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<float, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<double, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, char>(idx, l); }
	template <>
	inline std::unordered_map<double, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, char *>(idx, l); }
	template <>
	inline std::unordered_map<double, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, const char *>(idx, l); }
	template <>
	inline std::unordered_map<double, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, float>(idx, l); }
	template <>
	inline std::unordered_map<double, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, double>(idx, l); }
	template <>
	inline std::unordered_map<double, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, short>(idx, l); }
	template <>
	inline std::unordered_map<double, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, int>(idx, l); }
	template <>
	inline std::unordered_map<double, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, long>(idx, l); }
	template <>
	inline std::unordered_map<double, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, long long>(idx, l); }
	template <>
	inline std::unordered_map<double, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<double, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<double, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<double, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<double, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<double, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<short, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, char>(idx, l); }
	template <>
	inline std::unordered_map<short, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, char *>(idx, l); }
	template <>
	inline std::unordered_map<short, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, const char *>(idx, l); }
	template <>
	inline std::unordered_map<short, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, float>(idx, l); }
	template <>
	inline std::unordered_map<short, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, double>(idx, l); }
	template <>
	inline std::unordered_map<short, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, short>(idx, l); }
	template <>
	inline std::unordered_map<short, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, int>(idx, l); }
	template <>
	inline std::unordered_map<short, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, long>(idx, l); }
	template <>
	inline std::unordered_map<short, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, long long>(idx, l); }
	template <>
	inline std::unordered_map<short, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<short, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<short, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<short, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<short, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<short, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, char>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, char *>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, const char *>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, float>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, double>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, short>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, int>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, long long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned short, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned short, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<int, std::string> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, std::string>(idx, l); }
	template <>
	inline std::unordered_map<int, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, char>(idx, l); }
	template <>
	inline std::unordered_map<int, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, char *>(idx, l); }
	template <>
	inline std::unordered_map<int, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, const char *>(idx, l); }
	template <>
	inline std::unordered_map<int, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, float>(idx, l); }
	template <>
	inline std::unordered_map<int, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, double>(idx, l); }
	template <>
	inline std::unordered_map<int, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, short>(idx, l); }
	template <>
	inline std::unordered_map<int, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, int>(idx, l); }
	template <>
	inline std::unordered_map<int, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, long>(idx, l); }
	template <>
	inline std::unordered_map<int, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, long long>(idx, l); }
	template <>
	inline std::unordered_map<int, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<int, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<int, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<int, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<int, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<int, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, char>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, char *>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, const char *>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, float>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, double>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, short>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, int>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, long long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned int, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned int, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<long, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, char>(idx, l); }
	template <>
	inline std::unordered_map<long, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, char *>(idx, l); }
	template <>
	inline std::unordered_map<long, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, const char *>(idx, l); }
	template <>
	inline std::unordered_map<long, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, float>(idx, l); }
	template <>
	inline std::unordered_map<long, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, double>(idx, l); }
	template <>
	inline std::unordered_map<long, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, short>(idx, l); }
	template <>
	inline std::unordered_map<long, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, int>(idx, l); }
	template <>
	inline std::unordered_map<long, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, long>(idx, l); }
	template <>
	inline std::unordered_map<long, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, long long>(idx, l); }
	template <>
	inline std::unordered_map<long, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<long, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<long, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<long, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<long, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<long, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, char>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, char *>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, const char *>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, float>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, double>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, short>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, int>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, long long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<long long, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, char>(idx, l); }
	template <>
	inline std::unordered_map<long long, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, char *>(idx, l); }
	template <>
	inline std::unordered_map<long long, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, const char *>(idx, l); }
	template <>
	inline std::unordered_map<long long, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, float>(idx, l); }
	template <>
	inline std::unordered_map<long long, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, double>(idx, l); }
	template <>
	inline std::unordered_map<long long, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, short>(idx, l); }
	template <>
	inline std::unordered_map<long long, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, int>(idx, l); }
	template <>
	inline std::unordered_map<long long, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, long>(idx, l); }
	template <>
	inline std::unordered_map<long long, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, long long>(idx, l); }
	template <>
	inline std::unordered_map<long long, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<long long, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<long long, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<long long, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<long long, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<long long, unsigned long long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, char> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, char>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, char *>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, const char *> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, const char *>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, float> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, float>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, double> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, double>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, short> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, short>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, int> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, int>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, long long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, unsigned char> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, unsigned char>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, unsigned short> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, unsigned short>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, unsigned int> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, unsigned int>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, unsigned long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, unsigned long>(idx, l); }
	template <>
	inline std::unordered_map<unsigned long long, unsigned long long> getLuaVal(int idx, lua_State *l) { return getMapVal1<unsigned long long, unsigned long long>(idx, l); }

	template <typename T>
	struct SetUserData
	{
		inline static void setUserData(T t) {}
	};

	template <typename T>
	struct SetUserData<T *>
	{
		inline static void setUserData(T *t, lua_State *l)
		{
			const char *name = GlobalName<T>::getName();
			if (!t || !name)
			{
				lua_pushnil(l);
				// logInfo("----------- no find this obj");
				return;
			}

			ObjData<T> **od = (ObjData<T> **)lua_newuserdata(l, sizeof(ObjData<T> *));
			*od = new ObjData<T>(t);

			luaL_getmetatable(l, name);

			lua_setmetatable(l, -2);
		}
	};

	template <typename T>
	inline void setLuaVal(T t, lua_State *l) { SetUserData<T>::setUserData(t, l); }
	template <>
	inline void setLuaVal(bool val, lua_State *l) { lua_pushboolean(l, val); }
	template <>
	inline void setLuaVal(char val, lua_State *l) { lua_pushinteger(l, val); }
	template <>
	inline void setLuaVal(unsigned char val, lua_State *l) { lua_pushinteger(l, val); }
	template <>
	inline void setLuaVal(short val, lua_State *l) { lua_pushinteger(l, val); }
	template <>
	inline void setLuaVal(unsigned short val, lua_State *l) { lua_pushinteger(l, val); }
	template <>
	inline void setLuaVal(long val, lua_State *l) { lua_pushinteger(l, val); }
	template <>
	inline void setLuaVal(unsigned long val, lua_State *l) { lua_pushinteger(l, val); }
	template <>
	inline void setLuaVal(int val, lua_State *l) { lua_pushinteger(l, val); }
	template <>
	inline void setLuaVal(unsigned int val, lua_State *l) { lua_pushinteger(l, val); }
	template <>
	inline void setLuaVal(long long val, lua_State *l) { lua_pushinteger(l, val); }
	template <>
	inline void setLuaVal(unsigned long long val, lua_State *l) { lua_pushinteger(l, val); }
	template <>
	inline void setLuaVal(float val, lua_State *l) { lua_pushnumber(l, val); }
	template <>
	inline void setLuaVal(double val, lua_State *l) { lua_pushnumber(l, val); }
	template <>
	inline void setLuaVal(char *val, lua_State *l) { lua_pushstring(l, val); }
	template <>
	inline void setLuaVal(const char *val, lua_State *l) { lua_pushstring(l, val); }
	template <>
	inline void setLuaVal(std::string val, lua_State *l) { lua_pushlstring(l, val.c_str(), val.size()); }
	template <>
	inline void setLuaVal(std::string &val, lua_State *l) { lua_pushlstring(l, val.c_str(), val.size()); }
	template <>
	inline void setLuaVal(const std::string &val, lua_State *l) { lua_pushlstring(l, val.c_str(), val.size()); }

	template <typename T>
	inline void setVectorVal(const std::vector<T> &vec, lua_State *l)
	{
		lua_newtable(l);
		//  show(l);
		int cnt = vec.size();
		for (int i = 0; i < cnt; i++)
		{
			setLuaVal(vec[i], l);
			lua_rawseti(l, -2, i + 1); // 把vec中的元素循序写入lua tab t[n]=v,t是第二个参数的索引的tbl,n是i + 1处的值既栈顶的值
		}
	}
	template <typename T>
	inline void setLuaVal(std::vector<T> vec, lua_State *l)
	{
		setVectorVal(vec, l);
	}

	template <typename K, typename V>
	inline void setMapVal(const std::unordered_map<K, V> &tab, lua_State *l)
	{
		// show(l);
		lua_newtable(l);
		// show(l);
		for (auto &e : tab)
		{
			setLuaVal(e.first, l);
			setLuaVal(e.second, l);
			// show(l);
			lua_rawset(l, -3);
		}
		// show(l);
		// lua_pushvalue(l, -1);
		// show(l);
	}

	template <typename K, typename V>
	inline void setMapVal(const std::map<K, V> &tab, lua_State *l)
	{
		// show(l);
		lua_newtable(l);
		// show(l);
		for (auto &e : tab)
		{
			setLuaVal(e.first, l);
			setLuaVal(e.second, l);
			// show(l);
			lua_rawset(l, -3);
		}
		// show(l);
		// lua_pushvalue(l, -1);
		// show(l);
	}

	template <typename K, typename V>
	inline void setLuaVal(const std::map<K, V> &tab, lua_State *l)
	{
		setMapVal(tab, l);
	}

	template <typename K, typename V>
	inline void setLuaVal(const std::unordered_map<K, V> &tab, lua_State *l)
	{
		setMapVal(tab, l);
	}

	//-----------------objfunc----------------------------------------
	template <typename R, typename T>
	struct ObjectFunction_0 : public BaseFunc
	{
		typedef R (T::*Func)();
		Func func;
		ObjectFunction_0(Func func) { this->func = func; }
		int call(lua_State *l)
		{
			T *obj = getLuaVal<T *>(1, l);
			if (obj == 0)
			{
				logInfo("----------------no exists obj------------------");
				return 1;
			}

			if constexpr (std::is_same<void, R>::value)
			{
				(obj->*func)();
			}
			else
			{
				setLuaVal((obj->*func)(), l);
			}
			return 1;
		}
		~ObjectFunction_0()
		{
		}
	};

	template <typename R, typename T, typename Arg1>
	struct ObjectFunction_1 : public BaseFunc
	{
		typedef R (T::*Func)(Arg1);
		Func func;
		ObjectFunction_1(Func func) { this->func = func; }
		int call(lua_State *l)
		{
			T *obj = getLuaVal<T *>(1, l);
			if (obj == 0)
			{
				// logInfo("----------------no exists obj------------------");
				return 1;
			}

			if constexpr (std::is_same<void, R>::value)
			{
				(obj->*func)(getLuaVal<Arg1>(2, l));
			}
			else
			{
				setLuaVal((obj->*func)(getLuaVal<Arg1>(2, l)), l);
			}
			return 1;
		}
	};

	template <typename R, typename T, typename Arg1, typename Arg2>
	struct ObjectFunction_2 : public BaseFunc
	{
		typedef R (T::*Func)(Arg1, Arg2);
		Func func;
		ObjectFunction_2(Func func) { this->func = func; }
		int call(lua_State *l)
		{
			T *obj = getLuaVal<T *>(1, l);
			if (obj == 0)
			{
				// logInfo("----------------no exists obj------------------");
				// show(l);
				return 1;
			}

			if constexpr (std::is_same<void, R>::value)
			{
				(obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l));
			}
			else
			{
				setLuaVal((obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l)), l);
			}
			return 1;
		}
	};

	template <typename R, typename T, typename Arg1, typename Arg2, typename Arg3>
	struct ObjectFunction_3 : public BaseFunc
	{
		typedef R (T::*Func)(Arg1, Arg2, Arg3);
		Func func;
		ObjectFunction_3(Func func) { this->func = func; }
		int call(lua_State *l)
		{
			T *obj = getLuaVal<T *>(1, l);
			if (obj == 0)
			{
				// logInfo("----------------no exists obj------------------");
				return 1;
			}

			if constexpr (std::is_same<void, R>::value)
			{
				(obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l), getLuaVal<Arg3>(4, l));
			}
			else
			{
				setLuaVal((obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l), getLuaVal<Arg3>(4, l)), l);
			}
			return 1;
		}
	};

	template <typename R, typename T, typename Arg1, typename Arg2, typename Arg3, typename Arg4>
	struct ObjectFunction_4 : public BaseFunc
	{
		typedef R (T::*Func)(Arg1, Arg2, Arg3, Arg4);
		Func func;
		ObjectFunction_4(Func func) { this->func = func; }

		typedef void (*PF)(Args *);

		int call(lua_State *l)
		{
			// show(l);
			T *obj = getLuaVal<T *>(1, l);
			if (obj == 0)
			{
				// logInfo("----------------no exists obj------------------");
				return 1;
			}

			if constexpr (std::is_same<void, R>::value)
			{
				if constexpr (std::is_same<Arg3, std::unique_ptr<google::protobuf::Message>>::value)
				{
					const char *name = getLuaVal<Arg2>(3, l);
					std::unique_ptr<google::protobuf::Message> mess = Codec::encoder(name, l, 4);
					if (mess)
					{
						(obj->*func)(getLuaVal<Arg1>(2, l), name, std::move(mess), getLuaVal<Arg4>(5, l));
					}
				}
				else
				{
					(obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l), getLuaVal<Arg3>(4, l), getLuaVal<Arg4>(5, l));
				}
			}
			else
			{
				if constexpr (std::is_same<Arg2, PF>::value && std::is_same<Arg3, Args *>::value)
				{
					// show(l);
					const char *luaName = getLuaVal<const char *>(3, l);
					uint64_t pid = getLuaVal<uint64_t>(4, l);
					Args *args = (Args *)je_malloc(sizeof(Args));
					args->lua_ = true;
					memset(args->luaFunc_, 0, 15);
					strncpy(args->luaFunc_, luaName, strlen(luaName));
					args->pid_ = pid;
					setLuaVal((obj->*func)(getLuaVal<Arg1>(2, l), nullptr, args, getLuaVal<Arg4>(5, l)), l);
				}
				else
				{
					setLuaVal((obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l), getLuaVal<Arg3>(4, l), getLuaVal<Arg4>(5, l)), l);
				}
			}
			return 1;
		}
	};

	template <typename R, typename T, typename Arg1, typename Arg2, typename Arg3, typename Arg4, typename Arg5>
	struct ObjectFunction_5 : public BaseFunc
	{
		typedef R (T::*Func)(Arg1, Arg2, Arg3, Arg4, Arg5);
		Func func;
		ObjectFunction_5(Func func) { this->func = func; }
		int call(lua_State *l)
		{
			T *obj = getLuaVal<T *>(1, l);
			if (obj == 0)
			{
				// logInfo("----------------no exists obj------------------");
				return 1;
			}

			if constexpr (std::is_same<void, R>::value)
			{
				if constexpr (std::is_same<Arg4, std::unique_ptr<google::protobuf::Message>>::value)
				{
					const char *name = getLuaVal<Arg3>(4, l);
					std::unique_ptr<google::protobuf::Message> mess = Codec::encoder(name, l, 5);
					if (mess)
					{
						(obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l), name, std::move(mess), getLuaVal<Arg5>(6, l));
					}
				}
				else
				{
					(obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l), getLuaVal<Arg3>(4, l), getLuaVal<Arg4>(5, l), getLuaVal<Arg5>(6, l));
				}

				//(obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l), getLuaVal<Arg3>(4, l), getLuaVal<Arg4>(5, l), getLuaVal<Arg5>(6, l));
			}
			else
			{
				setLuaVal((obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l), getLuaVal<Arg3>(4, l), getLuaVal<Arg4>(5, l), getLuaVal<Arg5>(6, l)), l);
			}
			return 1;
		}
	};

	template <typename R, typename T, typename Arg1, typename Arg2, typename Arg3, typename Arg4, typename Arg5, typename Arg6>
	struct ObjectFunction_6 : public BaseFunc
	{
		typedef R (T::*Func)(Arg1, Arg2, Arg3, Arg4, Arg5, Arg6);
		Func func;
		ObjectFunction_6(Func func) { this->func = func; }
		int call(lua_State *l)
		{
			T *obj = getLuaVal<T *>(1, l);
			if (obj == 0)
			{
				// logInfo("----------------no exists obj------------------");
				return 1;
			}

			if constexpr (std::is_same<void, R>::value)
			{
				(obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l), getLuaVal<Arg3>(4, l), getLuaVal<Arg4>(5, l), getLuaVal<Arg5>(6, l), getLuaVal<Arg6>(7, l));
			}
			else
			{
				setLuaVal((obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l), getLuaVal<Arg3>(4, l), getLuaVal<Arg4>(5, l), getLuaVal<Arg5>(6, l), getLuaVal<Arg6>(7, l)), l);
			}
			return 1;
		}
	};

	template <typename R, typename T, typename Arg1, typename Arg2, typename Arg3, typename Arg4, typename Arg5, typename Arg6, typename Arg7>
	struct ObjectFunction_7 : public BaseFunc
	{
		typedef R (T::*Func)(Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7);
		Func func;
		ObjectFunction_7(Func func) { this->func = func; }
		int call(lua_State *l)
		{
			T *obj = getLuaVal<T *>(1, l);
			if (obj == 0)
			{
				// logInfo("----------------no exists obj------------------");
				return 1;
			}

			if constexpr (std::is_same<void, R>::value)
			{
				(obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l), getLuaVal<Arg3>(4, l), getLuaVal<Arg4>(5, l), getLuaVal<Arg5>(6, l), getLuaVal<Arg6>(7, l), getLuaVal<Arg7>(8, l));
			}
			else
			{
				setLuaVal((obj->*func)(getLuaVal<Arg1>(2, l), getLuaVal<Arg2>(3, l), getLuaVal<Arg3>(4, l), getLuaVal<Arg4>(5, l), getLuaVal<Arg5>(6, l), getLuaVal<Arg6>(7, l), getLuaVal<Arg7>(8, l)), l);
			}
			return 1;
		}
	};

	//--------------------------------------func
	template <typename R>
	struct Function_0 : public BaseFunc
	{
		typedef R (*Func)();
		Func func;
		Function_0(Func func) { this->func = func; }
		int call(lua_State *l)
		{
			if constexpr (std::is_same<void, R>::value)
			{
				(*func)();
			}
			else
			{
				setLuaVal((*func)(), l);
			}

			return 1;
		}
		~Function_0()
		{
			// logInfo("~Function_0(");
		}
	};

	template <typename R, typename Arg1>
	struct Function_1 : public BaseFunc
	{
		typedef R (*Func)(Arg1);
		Func func;
		Function_1(Func func) { this->func = func; }
		int call(lua_State *l)
		{
			if constexpr (std::is_same<void, R>::value)
			{
				(*func)(getLuaVal<Arg1>(1, l));
			}
			else
			{
				setLuaVal((*func)(getLuaVal<Arg1>(1, l)), l);
			}
			return 1;
		}
	};

	template <typename R, typename Arg1, typename Arg2>
	struct Function_2 : public BaseFunc
	{
		typedef R (*Func)(Arg1, Arg2);
		Func func;
		Function_2(Func func) { this->func = func; }
		int call(lua_State *l)
		{
			if constexpr (std::is_same<void, R>::value)
			{
				(*func)(getLuaVal<Arg1>(1, l), getLuaVal<Arg2>(2, l));
			}
			else
			{
				setLuaVal((*func)(getLuaVal<Arg1>(1, l), getLuaVal<Arg2>(2, l)));
			}
			return 1;
		}
	};

	template <typename R, typename Arg1, typename Arg2, typename Arg3>
	struct Function_3 : public BaseFunc
	{
		typedef R (*Func)(Arg1, Arg2, Arg3);
		Func func;
		Function_3(Func func) { this->func = func; }
		int call(lua_State *l)
		{
			if constexpr (std::is_same<void, R>::value)
			{
				(*func)(getLuaVal<Arg1>(1, l), getLuaVal<Arg2>(2, l), getLuaVal<Arg2>(3, l));
			}
			else
			{
				setLuaVal((*func)(getLuaVal<Arg1>(1, l), getLuaVal<Arg2>(2, l), getLuaVal<Arg3>(3, l)), l);
			}
			return 1;
		}
	};

	template <typename R, typename Arg1, typename Arg2, typename Arg3, typename Arg4>
	struct Function_4 : public BaseFunc
	{
		typedef R (*Func)(Arg1, Arg2, Arg3, Arg4);
		Func func;
		Function_4(Func func) { this->func = func; }
		int call(lua_State *l)
		{
			if constexpr (std::is_same<void, R>::value)
			{
				(*func)(getLuaVal<Arg1>(1, l), getLuaVal<Arg2>(2, l), getLuaVal<Arg2>(3, l), getLuaVal<Arg2>(4, l));
			}
			else
			{
				setLuaVal((*func)(getLuaVal<Arg1>(1, l), getLuaVal<Arg2>(2, l), getLuaVal<Arg3>(3, l), getLuaVal<Arg4>(4, l)), l);
			}
			return 1;
		}
	};

	template <typename R, typename Arg1, typename Arg2, typename Arg3, typename Arg4, typename Arg5>
	struct Function_5 : public BaseFunc
	{
		typedef R (*Func)(Arg1, Arg2, Arg3, Arg4, Arg5);
		Func func;
		Function_5(Func func) { this->func = func; }
		int call(lua_State *l)
		{
			if constexpr (std::is_same<void, R>::value)
			{
				(*func)(getLuaVal<Arg1>(1, l), getLuaVal<Arg2>(2, l), getLuaVal<Arg3>(3, l), getLuaVal<Arg4>(4, l), getLuaVal<Arg5>(5, l));
			}
			else
			{
				setLuaVal((*func)(getLuaVal<Arg1>(1, l), getLuaVal<Arg2>(2, l), getLuaVal<Arg3>(3, l), getLuaVal<Arg4>(4, l), getLuaVal<Arg5>(5, l)), l);
			}
			return 1;
		}
	};

	// ---------------------------------------------calllua
	inline int luaCall(lua_State *l)
	{
		BaseFunc *func = (BaseFunc *)lua_touserdata(l, lua_upvalueindex(1));
		return func->call(l);
	}

	template <typename T>
	inline int luaGc(lua_State *l)
	{
		ObjData<T> **ud = (ObjData<T> **)luaL_checkudata(l, -1, GlobalName<T>::getName());
		//logInfo("---------------luaGc %s", typeid(*ud).name());
		//   showst();
		//   // std::cout << typeid(*ud).name() << std::endl;
		delete (*ud);
		*ud = nullptr;
		return 0;
	}

	template <typename T>
	inline void regClass(const char *name, lua_State *l)
	{
		GlobalName<T>::setName(name);

		luaL_newmetatable(l, name);

		lua_pushstring(l, "__gc");
		lua_pushcfunction(l, &luaGc<T>);
		lua_rawset(l, -3);

		lua_pushstring(l, "__index");
		lua_pushvalue(l, -2);
		lua_rawset(l, -3);

		lua_pushstring(l, "__newindex");
		lua_pushvalue(l, -2);
		lua_rawset(l, -3);

		lua_settop(l, 0);
	}

	template <typename T>
	inline void regGlobalVar(const char *name, T t, lua_State *l)
	{
		// LuaBind::show(l);
		setLuaVal(t, l);
		// LuaBind::show(l);
		lua_setglobal(l, name);
	}

	// ------------------------------------------------------------------regobjfunc
	template <typename T, typename R>
	inline void regClassFunc(const char *name, R (T::*func)(), lua_State *l)
	{
		luaL_getmetatable(l, GlobalName<T>::getName());
		if (lua_istable(l, -1))
		{
			ObjectFunction_0<R, T> *funcs = new ObjectFunction_0<R, T>(func);
			lua_pushstring(l, name);
			lua_pushlightuserdata(l, funcs);
			lua_pushcclosure(l, &luaCall, 1);
			lua_rawset(l, -3);
		}
		else
		{
			logInfo("no reg class = %s", GlobalName<T>::getName());
		}
		lua_settop(l, 0);
	}

	template <typename T, typename R, typename Arg1>
	inline void regClassFunc(const char *name, R (T::*func)(Arg1), lua_State *l)
	{
		luaL_getmetatable(l, GlobalName<T>::getName());
		if (lua_istable(l, -1))
		{
			ObjectFunction_1<R, T, Arg1> *funcs = new ObjectFunction_1<R, T, Arg1>(func);
			lua_pushstring(l, name);
			lua_pushlightuserdata(l, funcs);
			lua_pushcclosure(l, &luaCall, 1);
			lua_rawset(l, -3);
		}
		else
		{
			logInfo("no reg class = %s", GlobalName<T>::getName());
		}
		lua_settop(l, 0);
	}

	template <typename T, typename R, typename Arg1, typename Arg2>
	inline void regClassFunc(const char *name, R (T::*func)(Arg1, Arg2), lua_State *l)
	{
		luaL_getmetatable(l, GlobalName<T>::getName());
		if (lua_istable(l, -1))
		{
			ObjectFunction_2<R, T, Arg1, Arg2> *funcs = new ObjectFunction_2<R, T, Arg1, Arg2>(func);
			lua_pushstring(l, name);
			lua_pushlightuserdata(l, funcs);
			lua_pushcclosure(l, &luaCall, 1);
			lua_rawset(l, -3);
		}
		else
		{
			logInfo("no reg class = %s", GlobalName<T>::getName());
		}
		lua_settop(l, 0);
	}

	template <typename T, typename R, typename Arg1, typename Arg2, typename Arg3>
	inline void regClassFunc(const char *name, R (T::*func)(Arg1, Arg2, Arg3), lua_State *l)
	{
		luaL_getmetatable(l, GlobalName<T>::getName());
		if (lua_istable(l, -1))
		{
			ObjectFunction_3<R, T, Arg1, Arg2, Arg3> *funcs = new ObjectFunction_3<R, T, Arg1, Arg2, Arg3>(func);
			lua_pushstring(l, name);
			lua_pushlightuserdata(l, funcs);
			lua_pushcclosure(l, &luaCall, 1);
			lua_rawset(l, -3);
		}
		else
		{
			logInfo("no reg class = %s", GlobalName<T>::getName());
		}

		lua_settop(l, 0);
	}

	template <typename T, typename R, typename Arg1, typename Arg2, typename Arg3, typename Arg4>
	inline void regClassFunc(const char *name, R (T::*func)(Arg1, Arg2, Arg3, Arg4), lua_State *l)
	{
		luaL_getmetatable(l, GlobalName<T>::getName());
		if (lua_istable(l, -1))
		{
			ObjectFunction_4<R, T, Arg1, Arg2, Arg3, Arg4> *funcs = new ObjectFunction_4<R, T, Arg1, Arg2, Arg3, Arg4>(func);
			lua_pushstring(l, name);
			lua_pushlightuserdata(l, funcs);
			lua_pushcclosure(l, &luaCall, 1);
			lua_rawset(l, -3);
		}
		else
		{
			logInfo("no reg class = %s", GlobalName<T>::getName());
		}
		lua_settop(l, 0);
	}

	template <typename T, typename R, typename Arg1, typename Arg2, typename Arg3, typename Arg4, typename Arg5>
	inline void regClassFunc(const char *name, R (T::*func)(Arg1, Arg2, Arg3, Arg4, Arg5), lua_State *l)
	{
		luaL_getmetatable(l, GlobalName<T>::getName());
		if (lua_istable(l, -1))
		{
			ObjectFunction_5<R, T, Arg1, Arg2, Arg3, Arg4, Arg5> *funcs = new ObjectFunction_5<R, T, Arg1, Arg2, Arg3, Arg4, Arg5>(func);
			lua_pushstring(l, name);
			lua_pushlightuserdata(l, funcs);
			lua_pushcclosure(l, &luaCall, 1);
			lua_rawset(l, -3);
		}
		else
		{
			logInfo("no reg class = %s", GlobalName<T>::getName());
		}
		lua_settop(l, 0);
	}

	template <typename T, typename R, typename Arg1, typename Arg2, typename Arg3, typename Arg4, typename Arg5, typename Arg6>
	inline void regClassFunc(const char *name, R (T::*func)(Arg1, Arg2, Arg3, Arg4, Arg5, Arg6), lua_State *l)
	{
		luaL_getmetatable(l, GlobalName<T>::getName());
		if (lua_istable(l, -1))
		{
			ObjectFunction_6<R, T, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6> *funcs = new ObjectFunction_6<R, T, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(func);
			lua_pushstring(l, name);
			lua_pushlightuserdata(l, funcs);
			lua_pushcclosure(l, &luaCall, 1);
			lua_rawset(l, -3);
		}
		else
		{
			logInfo("no reg class = %s", GlobalName<T>::getName());
		}
		lua_settop(l, 0);
	}

	template <typename T, typename R, typename Arg1, typename Arg2, typename Arg3, typename Arg4, typename Arg5, typename Arg6, typename Arg7>
	inline void regClassFunc(const char *name, R (T::*func)(Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7), lua_State *l)
	{
		luaL_getmetatable(l, GlobalName<T>::getName());
		if (lua_istable(l, -1))
		{
			ObjectFunction_7<R, T, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7> *funcs = new ObjectFunction_7<R, T, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7>(func);
			lua_pushstring(l, name);
			lua_pushlightuserdata(l, funcs);
			lua_pushcclosure(l, &luaCall, 1);
			lua_rawset(l, -3);
		}
		else
		{
			logInfo("no reg class = %s", GlobalName<T>::getName());
		}
		lua_settop(l, 0);
	}

	// reg lobal func
	template <typename R>
	inline void regGloablFunc(const char *name, R (*func)(), lua_State *l)
	{
		Function_0<R> *funcs = new Function_0<R>(func);
		lua_pushlightuserdata(l, funcs);
		lua_pushcclosure(l, luaCall, 1);
		lua_setglobal(l, name);
	}

	template <typename R, typename Arg1>
	inline void regGloablFunc(const char *name, R (*func)(Arg1), lua_State *l)
	{
		Function_1<R, Arg1> *funcs = new Function_1<R, Arg1>(func);
		lua_pushlightuserdata(l, funcs);
		lua_pushcclosure(l, luaCall, 1);
		lua_setglobal(l, name);
	}

	template <typename R, typename Arg1, typename Arg2>
	inline void regGloablFunc(const char *name, R (*func)(Arg1, Arg2), lua_State *l)
	{
		Function_2<R, Arg1, Arg2> *funcs = new Function_2<R, Arg1, Arg2>(func);
		lua_pushlightuserdata(l, funcs);
		lua_pushcclosure(l, luaCall, 1);
		lua_setglobal(l, name);
	}

	template <typename R, typename Arg1, typename Arg2, typename Arg3>
	inline void regGloablFunc(const char *name, R (*func)(Arg1, Arg2, Arg3), lua_State *l)
	{
		Function_3<R, Arg1, Arg2, Arg3> *funcs = new Function_3<R, Arg1, Arg2, Arg3>(func);
		lua_pushlightuserdata(l, funcs);
		lua_pushcclosure(l, luaCall, 1);
		lua_setglobal(l, name);
	}

	template <typename R, typename Arg1, typename Arg2, typename Arg3, typename Arg4>
	inline void regGloablFunc(const char *name, R (*func)(Arg1, Arg2, Arg3, Arg4), lua_State *l)
	{
		Function_4<R, Arg1, Arg2, Arg3, Arg4> *funcs = new Function_4<R, Arg1, Arg2, Arg3, Arg4>(func);
		lua_pushlightuserdata(l, funcs);
		lua_pushcclosure(l, luaCall, 1);
		lua_setglobal(l, name);
	}

	template <typename R, typename Arg1, typename Arg2, typename Arg3, typename Arg4, typename Arg5>
	inline void regGloablFunc(const char *name, R (*func)(Arg1, Arg2, Arg3, Arg4, Arg5), lua_State *l)
	{
		Function_5<R, Arg1, Arg2, Arg3, Arg4, Arg5> *funcs = new Function_5<R, Arg1, Arg2, Arg3, Arg4, Arg5>(func);
		lua_pushlightuserdata(l, funcs);
		lua_pushcclosure(l, luaCall, 1);
		lua_setglobal(l, name);
	}

	//-----------------------------------------------------------------------------------
	struct CallLua
	{
		int index = 0;
		bool exist = false;
		lua_State *l = 0;

		bool existFunc() { return exist; }
		~CallLua()
		{
			if (exist)
				luaL_unref(l, LUA_REGISTRYINDEX, index);
		}
		CallLua(lua_State *l, const char *func, const char *moduleName = nullptr)
		{
			// LuaBind::show(l);
			if (!func)
			{
				logInfo("CallLua no func");
				return;
			}
			this->l = l;
			if (moduleName)
			{
				lua_getglobal(l, moduleName);
				if (!lua_istable(l, -1))
				{
					logInfo("no find this module = %s", moduleName);
					return;
				}
				lua_getfield(l, -1, func);
				if (!lua_isfunction(l, -1))
				{
					logInfo("no find shis func = %s!", func);
					return;
				}
			}
			else
			{
				lua_getglobal(l, func);
				if (!lua_isfunction(l, -1))
				{
					logInfo("no find global func %s", func);
					return;
				}
				// LuaBind::show(l);
			}
			// LuaBind::show(l);
			index = luaL_ref(l, LUA_REGISTRYINDEX);
			exist = true;
			// LuaBind::show(l);
		}

		template <size_t I = 0, typename FuncT, typename... Tp>
		inline typename std::enable_if_t<I == sizeof...(Tp)> for_each(std::tuple<Tp...> &, FuncT)
		{
		}

		template <size_t I = 0, typename FuncT, typename... Tp>
			inline typename std::enable_if_t < I<sizeof...(Tp)> for_each(std::tuple<Tp...> &t, FuncT f)
		{
			f(std::get<I>(t));
			for_each<I + 1, FuncT, Tp...>(t, f);
		}

		template <typename R, typename S, typename... Args>
		R call(Args... args)
		{
			lua_pushcclosure(l, errFunc, 0);
			// show(l);
			lua_rawgeti(l, LUA_REGISTRYINDEX, index);
			// show(l);
			auto valList = std::forward_as_tuple(args...);

			if constexpr (std::is_same<S, void *>::value)
			{
				setLuaVal(std::get<0>(valList), l);
				setLuaVal(std::get<1>(valList), l);
				if (Codec::decode(std::get<2>(valList), std::get<3>(valList), std::get<4>(valList), l))
				{
					setLuaVal(std::get<5>(valList), l);
					lua_pcall(l, 4, 1, 1);
				}
				lua_settop(l, 0);
			}
			else
			{
				// show(l);
				for_each(valList, [&](auto &e)
						 { setLuaVal(e, l); });
				// show(l);
				uint8_t nargs = (uint8_t)sizeof...(args);
				lua_pcall(l, nargs, 1, 1);
				if constexpr (!std::is_same<void, R>::value)
				{
					R result = getLuaVal<R>(lua_gettop(l), l);
					lua_settop(l, 0);
					return result;
				}
				else
				{
					lua_settop(l, 0);
				}
			}
		}
	};
}

#define regClass(cls, l) LuaBind::regClass<cls>(#cls, l)
#define regClassFunc(cls, func, l) LuaBind::regClassFunc<cls>(#func, &cls::func, l)
#define regGloablFunc(func, l) LuaBind::regGloablFunc(#func, &func, l)
#define regGlobalVarSame(var, l) LuaBind::regGlobalVar(#var, var, l)
#define regGlobalVarNoSame(var, name, l) LuaBind::regGlobalVar(name, var, l)
