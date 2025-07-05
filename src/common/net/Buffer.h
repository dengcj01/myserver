#pragma once

#include <stddef.h>
#include <string.h>
#include <stdint.h>

class Buffer
{
public:
	Buffer();
	~Buffer();

	bool expand();
	void moveBuff();
	inline char *getHeadPos()
	{
		return data_ + wPos_;
	}

	bool mallocOk();

	inline void reset()
	{
		rPos_ = 0;
		wPos_ = 0;
	}
	inline size_t size()
	{
		return len_;
	}
	inline size_t writePos()
	{
		return wPos_;
	}
	inline size_t readPos()
	{
		return rPos_;
	}
	inline size_t leftSpace()
	{
		return len_ - rPos_;
	}
	inline size_t validWriteLen()
	{
		return rPos_ - wPos_;
	}
	inline void updateReadPos(size_t len)
	{
		rPos_ += len;
	}
	inline void updateWritePos(size_t len)
	{
		wPos_ += len;
	}
	inline char *readData()
	{
		return data_ + rPos_;
	}
	inline char *writeData()
	{
		return data_ + wPos_;
	}
	inline char *data()
	{
		return data_;
	}
	inline uint32_t getVal(uint32_t pos, uint32_t offset = 0)
	{
		char *p = data_ + offset;
		return p[pos];
	}
	inline void setVal(uint32_t pos, uint32_t val) { data_[pos] = val; }

	inline void cleanMem()
	{
		memset(data_, 0, len_);
		rPos_ = wPos_ = 0;
	}
	void copyData(const char *dst, size_t lens);


private:
	char *data_ = 0;
	size_t wPos_ = 0;
	size_t rPos_ = 0;
	size_t len_ = 0;
};
