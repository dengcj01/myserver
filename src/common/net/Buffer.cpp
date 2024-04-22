#include "Buffer.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "../../../libs/jemalloc/jemalloc.h"

constexpr size_t defaultLen = 1024;

Buffer::Buffer() : data_((char *)je_malloc(defaultLen))
{
	len_ = defaultLen;
	memset(data_, 0, len_);
}

Buffer::~Buffer()
{
	if (data_)
	{
		je_free(data_);
		data_ = nullptr;
		rPos_ = 0;
		wPos_ = 0;
	}
}


void Buffer::expand()
{
	if (leftSpace() == 0) // len -r
	{
		size_t len = len_ * 2;
		char *data = (char *)je_malloc(len);
		memset(data, 0, len);

		size_t pos = rPos_ - wPos_;
		memcpy(data, data_ + wPos_, pos);
		len_ = len;

		je_free(data_);
		data_ = data;
		wPos_ = 0;
		rPos_ = pos;
	}
}


void Buffer::moveBuff()
{

	size_t pos = rPos_ - wPos_;
	memcpy(data_, data_ + wPos_, pos);

	wPos_ = 0;
	rPos_ = pos;
}

void Buffer::copyData(char *src, size_t lens)
{
	if (leftSpace() < lens) // len -r
	{
		size_t len = len_ * 2 + lens;
		char *data = (char *)je_malloc(len);
		memset(data, 0, len);

		size_t pos = rPos_ - wPos_;
		memcpy(data, data_ + wPos_, pos);

		len_ = len;
		je_free(data_);
		data_ = data;
		wPos_ = 0;
		rPos_ = pos;
	}

	memcpy(data_ + rPos_, src, lens);
	rPos_ += lens;
}
