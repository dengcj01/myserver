#pragma once
#include "Singleton.h"
#include <unordered_map>
#include <string>
#include <queue>
#include <map>
#include <stdio.h>
#include "Tools.hpp"


struct Node
{
	Node()
	{
	}
	Node *father_ = 0;
	Node *fail_ = 0;
	bool isEnd_ = false;
	std::wstring txt_;
	std::unordered_map<std::wstring, Node *> next_;
};

class Filter : public Singleton<Filter>
{
	Node *root_;

	struct ResNode
	{
		void add(uint16_t k, uint16_t v)
		{
			m_.emplace(k, v);
		}
		bool opt_ = false;
		std::map<uint16_t, uint16_t> m_;
	};

public:
	void init()
	{
		root_ = new Node();
	}

	void add(const char *val)
	{
		std::wstring word = gTools.changeStr(val);
		if (word.length() == 0)
		{
			return;
		}

		Node *node = root_;
		size_t len = word.length();
		Node *eno = 0;

		for (size_t i = 0; i < len; i++)
		{
			std::wstring s = word.substr(i, 1);
			auto it = node->next_.find(s);
			if (it == node->next_.end())
			{
				Node *n = new Node();
				n->txt_ = s;
				node->next_.emplace(s, n);
				n->father_ = node;
				node = n;
				eno = n;
			}
			else
			{
				node = it->second;
				eno = node;
			}
		}

		if (eno)
		{
			eno->isEnd_ = true;
		}
	}

	Node *findFailNode(const std::wstring &str, Node *n)
	{
		if (!n || !n->father_ || !n->father_->fail_)
		{
			return 0;
		}
		Node *node = n->father_->fail_;
		auto it = node->next_.find(str);
		if (it == node->next_.end())
		{
			return root_;
		}

		return it->second;
	}

	void __initFailPoint(std::queue<Node *> que)
	{
		std::queue<Node *> nextQue;

		while (!que.empty())
		{
			Node *node = que.front();

			for (auto &e : node->next_)
			{
				Node *cur = e.second;
				cur->fail_ = findFailNode(e.first, cur);

				nextQue.push(cur);
			}
			que.pop();
		}

		if (nextQue.empty())
		{
			return;
		}

		__initFailPoint(nextQue);
	}

	void initFailPoint()
	{
		root_->fail_ = root_;
		std::queue<Node *> que;
		for (auto &e : root_->next_)
		{

			e.second->fail_ = root_;
			que.push(e.second);
		}

		__initFailPoint(que);
	}

	Node *findFilterWord(Node *n, std::wstring &str, bool fail)
	{
		if (!n)
		{
			return 0;
		}
		auto it = n->next_.find(str);
		if (it == n->next_.end())
		{
			if (fail)
			{
				return 0;
			}
			return findFilterWord(n->fail_, str, true);
		}

		return it->second;
	}

	int filterWord(std::wstring &word)
	{

		if (word.length() == 0)
		{
			return 0;
		}

		Node *node = root_;
		size_t len = word.length();
		std::unordered_multimap<std::wstring, ResNode> re;
		Node *f = 0;

		for (size_t i = 0; i < len; i++)
		{
			std::wstring s = word.substr(i, 1);
			Node *n = findFilterWord(node, s, false);
			if (!n)
			{
				node = root_;
			}
			else
			{
				node = n;
				ResNode rn;
				rn.opt_ = false;
				rn.add(i, 1);
				re.emplace(s, std::move(rn));

				if (node->isEnd_)
				{
					f = node;
				}
			}
		}

		int ret = 0;
		std::unordered_map<std::string, uint8_t> his;
		while (f && f->father_)
		{
			for (auto it = re.begin(); it != re.end(); it++)
			{
				if (it->first == f->txt_)
				{
					ResNode &rn = it->second;
					if (rn.opt_ == false)
					{
						auto &m = rn.m_;
						rn.opt_ = true;
						for (auto it1 = m.begin(); it1 != m.end(); it1++)
						{
							word.replace(it1->first, it1->second, it1->second, '*');
						}
					}
				}
			}
			f = f->father_;
			ret = 1;
		}

		return ret;
	}

	std::map<uint8_t, const char *> filter(const char *word)
	{
		std::wstring s = gTools.changeStr(word);
		uint8_t ret = filterWord(s);
		std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
		std::string tmp = converter.to_bytes(s);
		std::map<uint8_t, const char *> m;
		m.emplace(ret, tmp.c_str());
		return m;
	}
};

#define gFilter Filter::instance()