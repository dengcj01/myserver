#include "Buffer.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
////#include "../../../libs/jemalloc/jemalloc.h"
#include "../ParseConfig.hpp"

constexpr size_t defaultLen = 61440;
constexpr size_t defaultDbLen = 1024*1024*10;
Buffer::Buffer()
{
	size_t lens = defaultLen;
	if(gParseConfig.isDbServer())
	{
		lens = defaultDbLen;
	}

	data_ = (char*)malloc(lens);

	len_ = lens;
	memset(data_, 0, len_);
}

Buffer::~Buffer()
{
	if (data_)
	{
		free(data_);
		data_ = nullptr;
		rPos_ = 0;
		wPos_ = 0;
	}
}

bool Buffer::mallocOk()
{
	if(!data_)
	{
		return false;
	}

	return true;
}

bool Buffer::expand()
{
	if (leftSpace() == 0) // len -r
	{
		size_t len = len_ * 2;
		char *data = (char *)malloc(len);
		memset(data, 0, len);

		size_t pos = rPos_ - wPos_;
		memcpy(data, data_ + wPos_, pos);
		len_ = len;

		free(data_);
		data_ = data;
		wPos_ = 0;
		rPos_ = pos;
		return true;
	}
	return false;
}


void Buffer::moveBuff()
{

	size_t pos = rPos_ - wPos_;
	memcpy(data_, data_ + wPos_, pos);

	wPos_ = 0;
	rPos_ = pos;
}

void Buffer::copyData(const char *src, size_t lens)
{
	if (leftSpace() < lens) // len -r
	{
		size_t len = len_ * 2 + lens;
		char *data = (char *)malloc(len);
		memset(data, 0, len);

		size_t pos = rPos_ - wPos_;
		memcpy(data, data_ + wPos_, pos);

		len_ = len;
		free(data_);
		data_ = data;
		wPos_ = 0;
		rPos_ = pos;
	}

	memcpy(data_ + rPos_, src, lens);
	rPos_ += lens;
}
