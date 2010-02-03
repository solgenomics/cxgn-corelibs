

/************************************************************************
  Unrooted REConciliation version 1.00 
  (c) Copyright 2005-2006 by Pawel Gorecki
  Written by P.Gorecki.
  Permission is granted to copy and use this program provided no fee is
  charged for it and provided that this copyright notice is not removed. 
 *************************************************************************/

#include <ctype.h>
#include <iostream>

using namespace std;

#include "rtree.h"

double weight_loss=1.0;
double weight_dup=1.0;

char* getTok(char *s,int &p) // skip spaces, return next char (if alphabetic or (),) then 
{
	// return pointer to pth char of s, i.e. s+p, and also p is reset s.t. s+p is the char after the (),  or after a string of other chars
#define inctok p++  // inctok increments p
	while ((isspace(s[p])) ||( s[p] == '\n') || (s[p] == '\t')){ inctok; } // skip over spaces, and newlines
	char *cur = s+p; // cur points to first non-space char encountered.
	if (isalpha(s[p]) or (s[p] == ':')) // if s[p] is alphabetic
		{
			while( !( (s[p]=='(')  || (s[p]==')') || (s[p]==',') ) ) inctok; // sets p s.t. s+p points to next )( or ,
			return cur; // cur points to an alphabetic char
		}
	if ((s[p]=='(')  || (s[p]==')') || (s[p]==','))
		{
			inctok;
			return cur; // cur points to a )( or ,  ; s+p points to next char
		}
	cerr << "Parse error...s[p]: [" << s[p] << "]"<< endl;
	exit(-1);
}

iterator_tree::iterator_tree(RTree *tr, int flag_) 
{ 
	t=tr; 
	c=tr->root(); 
	flag=flag_;
}

RNode *RTree::parseNode(char *s,int &p)
{
	// 
	char *cur = getTok(s,p);
	if (cur[0]=='(')
		{
			RNode *a = parseNode(s,p);
			cur = getTok(s,p);
			RNode *b = parseNode(s,p);
			cur = getTok(s,p);
			if(s[p]==':'){ 
				int start = p; getTok(s,p); 
				return createInt(a,b,s+start,p-start) ; 
			}
			else{ 
				RNode* c = createInt(a,b);
				return c;
			}
		}
	return createLeaf(cur,s+p-cur);
}


RTree::RTree(char *fs)
{
	int px=0;
	rootn=parseNode(fs,px);
	rootn->depth(0);
}

RNode *iterator_tree::operator()()
{
	RNode *res = step();
	while (res)
	{
		if (flag & F_ALL) break;
		if ((flag & F_INTERNAL) && (!res->leaf())) break;
		if ((flag & F_LEAVES) && (res->leaf())) break;
		res=step();
	}
	return res;
}

RNode *iterator_tree::step()
{
	RNode *res=c;
	if (!c) return c;  // finished
	if (!c->leaf()) c=((RInt*)c)->l();
	else
	{
		while (c)	    
		{
			RNode *prev=c;
			c=c->p();
			if (!c) break; // last
			if ((((RInt*)c)->l())==prev) { 
				c=((RInt*)c)->r();
				break;
			}
		}
	}
	return res;
}


RNode *SpeciesTree::lca(RNode *a, RNode *b) { 
	if (b->isParentOf(a)) return b;
	while (a) 
	{
		if (a->isParentOf(b)) return a;
		a=a->p();
	}
	return NULL;
}

RNode *RNode::isParentOf(RNode *c) 
{ 
	while (c) { 
		if (c==this) return c; 
		c=c->p();
	} 
	return 0;
}

char* xstrndup(const char *s,int len)
{
	if (len==0) return strdup(s);
	char *b = new char[len+1];
	strncpy(b,s,len);
	b[len]=0;
	return b;
}
