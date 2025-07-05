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

public:
	Node *root_;

	struct ResNode
	{
		void add(uint16_t k, uint16_t v)
		{
			m_.emplace(k, v);
		}
		std::map<uint16_t, uint16_t> m_;
	};

public:
	void init()
	{
		root_ = new Node();
	}
	std::string getStr(std::wstring &str)
	{
		std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
		std::string tmp = converter.to_bytes(str);
		return tmp;
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
			if(node)
			{
				node->fail_ = findFailNode(node->txt_, node);
				for (auto &e : node->next_)
				{
					nextQue.push(e.second);
				}
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
			Node* n = e.second;
			n->fail_ = root_;

			for(auto & me:n->next_)
			{
				que.push(me.second);
			}
		}

		__initFailPoint(que);
	}


	Node *findFilterWord(Node *n, std::wstring &str, bool fail, bool isFull = false)
	{;
		if (!n)
		{
			return 0;
		}


		auto it = n->next_.find(str);
		if (it == n->next_.end())
		{
			if(isFull)
			{
				return 0;

			}
			else
			{	
				if(n == n->fail_)
				{
					return 0;
				}
				return findFilterWord(n->fail_, str, true, isFull);
			}

		}

		return it->second;
	}

	int filterWord(std::wstring &word, bool isFull = false)
	{
		if (word.length() == 0)
		{
			return 1;
		}

		Node *node = root_;
		size_t len = word.length();
		std::unordered_multimap<std::wstring, ResNode> re;
        uint8_t flen = 0;
		Node *f = 0;
		std::vector<Node*> vn;
		for (size_t i = 0; i < len; i++)
		{
			std::wstring s = word.substr(i, 1);
			Node *n = findFilterWord(node, s, false, isFull);
			if (!n)
			{
				if(isFull)
				{
					flen = 0;
					if(root_ != node)
					{
						n = findFilterWord(root_, s, false, isFull);
						if(n)
						{
							node = n;
						}
					}					
				}
				else
				{
					node = root_;
				}
			}
			else
			{
                if(isFull)
                {   
                    flen += 1;
                    if(flen >= 2)
                    {
                        return 0;
                    }
                    node = n;
                }
                else
                {
                    node = n;
                    ResNode rn;
                    rn.add(i, 1);
                    re.emplace(s, std::move(rn));
					if (node->isEnd_)
					{
						vn.emplace_back(node);
					}
                }

			}
		}

        if(isFull && flen != 2)
        {
            return 1;
        }

		int ret = 0;

		for(auto nowNode:vn)
		{
			f = nowNode;
			ret = 1;
			while(f && f->father_)
			{
				auto rg = re.equal_range(f->txt_);
				for (auto it = rg.first; it != rg.second; ++it) 
				{
					auto &m = it->second.m_;
					for (auto it1 = m.begin(); it1 != m.end(); it1++)
					{
						uint16_t cnt = it1->second;
						word.replace(it1->first, cnt, cnt, '*');
					}	
				}
				f = f->father_;
			}

			
		}


		return ret;
	}



	std::string filterChat(const char *word)
	{
		if(!word || strlen(word) == 0)
		{
			return "";
		}

		std::wstring s = gTools.changeStr(word);
		filterWord(s);
		std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;
		std::string tmp = converter.to_bytes(s);
		return tmp;
	}



    std::string filterName(const char *word)
	{
		if(!word || strlen(word) == 0)
		{
			return "";
		}
		
		std::wstring s = gTools.changeStr(word);
		uint8_t ret = filterWord(s, true);
		if(ret == 1)
		{
			return word;
		}
		else
		{

			return "";
		}
	}
};


#define gFilter Filter::instance()