#pragma once
#include <type_traits>
#include <utility>
template <typename T>
class Singleton
{
public:
	template<typename... Args>
	static T& instance(Args&&... args)
	{
		static T t(std::forward<Args>(args)...);
		return t;
	}

    Singleton(const Singleton&) = delete;
	Singleton& operator = (const Singleton&) = delete;
protected:    
	Singleton() = default;
	~Singleton() = default;

};