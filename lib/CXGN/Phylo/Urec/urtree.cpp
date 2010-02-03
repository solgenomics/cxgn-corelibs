
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

#include "urtree.h"

iterator_utree::iterator_utree(UTree *t, int flag_) : flag(flag_)
{
    nodes=t->nodes();
    nit=nodes->begin();
}

UNode *iterator_utree::operator()()
{
    UNode *un;
    while (1)
    {
        if (nit==nodes->end()) return NULL;
        un = *nit;
        if (flag & F_ALL) break;
        if ((flag & F_INTERNAL) && !un->leaf()) break;
        if ((flag & F_LEAVES) && un->leaf()) break;
        nit++;
    }
    nit++;
    return un;
}

ostream& UNode3::pprooted(ostream&s,int from)
{
    if (!from)
    {
        pn->pprooted(s,1);
        rn->p()->pprooted(s,1);
        ln->p()->pprooted(s,1);
        return s;
    }
    UNode::pprooted(s,from);
    ln->p()->pprooted(s,from);
    rn->p()->pprooted(s,from);
    return s;
}

ostream& UTree::pprooted(ostream&s)
{
    return start->pprooted(s,0);
}

UNode *UTree::parseNode(char *s, int &p, int fromroot)
{
	char *cur = getTok(s,p);
	if (cur[0]=='(')
    {
			UNode *a = parseNode(s,p,0);
			getTok(s,p); // this should return a comma
			UNode *b = parseNode(s,p,0);
			cur=getTok(s,p); // this should return a )
			if (fromroot) 
				{
					if (cur[0]==',')
						{
							a=createNode3(a,b);
							b=parseNode(s,p,0);
							getTok(s,p);
						}
					// join a<->b
					a->p(b);
					b->p(a);
					return start=b;
				}	
			if(s[p]==':'){ 
				int start = p; 
				getTok(s,p); 	
				return createNode3(a,b,s+start,p-start) ; 
			}
			else{ return createNode3(a,b); }		
    }        
	return start=createLeaf(cur,s+p-cur);
}


UNode3* UTree::connect(UNode3 *a, UNode3 *b, UNode3 *c, UNode *u1, UNode *u2)
{
    a->l(b);
    b->l(c);
    c->l(a);
    a->r(c);
    b->r(a);
    c->r(b);
    u1->p(a);
    u2->p(b);
    a->p(u1);
    b->p(u2);
    return c;
}

UNode *UTree::findoptimaledge(SpeciesTree *st)
{
#define shw(k) 
    UNode *cur = start;
    shw("start");
    cur->mark(4|1);
    if (!cur->p()) return cur;
    if (cur->leaf() && cur->p()->leaf()) return cur;
    if (cur->leaf()) cur=cur->p();

    shw("init");
    // cur - internal
    int i;
    int found=0;     
    RNode *MG = st->lca(cur->M(st),cur->p()->M(st));
    if (MG->leaf()) return cur; // |L(G)|=1
    for (i=0; i<3; i++, cur=((UNode3*)cur)->l()) 
	if (cur->M(st)!=MG) { found=1; break; }
    cur->mark();
    shw("ins");
    if (found)
    {
	while (!cur->p()->leaf())
	{
	    shw("wh");
	    UNode3 *cur3p = (UNode3*)cur->p();
	    if (cur3p->l()->M(st)!=MG) cur=cur3p->l();
	    else
		if (cur3p->r()->M(st)!=MG) cur=cur3p->r();	    
		else { cur=cur3p; break; }
	    cur->mark();
	}
	if (cur->M(st)!=MG) return cur;
    }
    cur->mark();
    for (i=0; i<3; i++, cur=((UNode3*)cur)->l()) 
	if (cur->p()->M(st)==MG) return cur;
    return cur;     
}

int lossprim(RNode *s,RNode *s1,RNode *s2)
{
    if ((s!=s1) && (s!=s2)) return s1->depth()+s2->depth()-2*s->depth()-2;
    if (s!=s1) return s1->depth()-s->depth();
    return s2->depth()-s->depth();
}

void dlcostdetintermediates(RNode *child, RNode *cur,RNode *last, int skiplast=1)
{
    while (1) 
    {
	if ((cur==last) && (skiplast)) return;
	if (child==((RInt*)cur)->l()) ((RInt*)cur)->r()->costdet().loss++;
	else ((RInt*)cur)->l()->costdet().loss++;
	if (cur==last) return;
	cur=cur->p();
	child=child->p();
    }
}

void dlcostdet(RNode *s,RNode *s1,RNode *s2)
{
    //loss
    if ((s!=s1) && (s!=s2)) 
	{
	    dlcostdetintermediates(s1,s1->p(),s);
	    dlcostdetintermediates(s2,s2->p(),s);
	}
    else
    {
	if (s!=s1) 
	    dlcostdetintermediates(s1,s1->p(),s,0);
	else
	    if (s!=s2) 
		dlcostdetintermediates(s2,s2->p(),s,0);    
	s->costdet().dup++;
    }
}

UNode *UTree::genRand(double pint, double dec, char **t, int s)
{
    if ((1.0*rand()/RAND_MAX)<pint)
    {
        UNode *a = genRand(pint*dec,dec,t,s);
        UNode *b = genRand(pint*dec,dec,t,s);
        return createNode3(a,b);
    }
    return createLeaf(strdup(t[rand()%s]));
}

void UTree::initrand(int len,double pint, double dec, char **t, int splen)
{
    UNode *cur = genRand(pint,dec,t,splen);
    UNode *cur2 = genRand(pint,dec,t,splen);
    for (int i=0; i<len-2; i++)
    {
	cur=createNode3(cur,cur2);
	cur2=genRand(pint,dec,t,splen);
    }
    cur->p(cur2);
    cur2->p(cur);
    start=cur;
}

UTree::UTree(int len,double pint, double dec, int numlv, int uniquelv, char *src)
{
  int splen=strlen(src);
    if ((numlv<0) && (!uniquelv))
      {
	int i=0;
	char *t[splen];
	char buf[2];
	buf[1]=0;
	for (i=0; i<splen; i++) 
	  {
	    buf[0]=src[i];
	    t[i]=strdup(buf);
	  }
	initrand(len,pint,dec,t,splen);
      }
    else
      {

	int lf = numlv;
	if (numlv>0) 
	  if (uniquelv) 
	    if (splen<numlv) lf=splen; // no more
	    else;
	  else;
	else  
	  if (uniquelv) 
	    if (splen>1) lf=1+(rand()%(splen));
	    else lf=1;
	
	// only 2 parameters: lf - number of leaves to generate
	// uniquelv - are they unique?
    

	// Generating tree
	
	UNode *tb[lf];
	char lfusage[splen];

	// Usage of unique leaves
	int i;
	if (uniquelv)
	  for (i=0;i<splen;i++) lfusage[i]=0;

	for (i=0;i<lf;i++)
	  {
	    // get a leaf (can be more efficient...)
	    int pos=-1;
	    while (1)
	      {
		pos=rand()%splen;
		if (!uniquelv) break;
		if (!lfusage[pos])
		  {
		    // ok found
		    lfusage[pos]=1;
		    break;
		  }
	      }
	    char bf[2];
	    bf[1]=0;
	    bf[0]=src[pos];
	    tb[i]=createLeaf(strdup(bf));
	  }
	
	
	if (lf==1) 
	  {
	    start = tb[0];
	    return;
	  }

	for (i=0;i<lf-2;i++)
	  {
// 	    cout << "lf-i=" << lf -i;
// 	    cout << "  i=" << i << endl;
	    int p = rand()%(lf-i);	    
	    int q;
	    do q = rand()%(lf-i);
	    while (p==q);
// 	    cout << " " << p << " " << q << endl;
// 	    cout << "joining:" ;
// 	    tb[p]->ppsmprooted(cout);
// 	    cout << " with: ";
// 	    tb[q]->ppsmprooted(cout);
// 	    cout << endl;
	    
	    // join the trees
	    tb[p] = createNode3(tb[p],tb[q]);
	    
	    int j;
	    for (j=q+1;j<lf-i;j++) tb[j-1]=tb[j];
	    	    
	  }

	tb[0]->p(tb[1]);
	tb[1]->p(tb[0]);
	start=tb[0];
    	
// 	cout << " " << lf << " " << uniquelv << endl;
// 	start->ppsmprooted(cout); cout << endl;
// 	print(cout); cout << endl;
	
//	cout << "=============================================" << endl;
    
      }
    
}

UTree::UTree(int len,double pint, double dec, SpeciesTree *sp) 
{
    int i=0;
    char *t[sp->lsize()+1];
    iterator_tree it(sp,F_LEAVES);
    RLeaf *r;
    while ((r=(RLeaf*)it())!=0) t[i++]=r->label();
    t[sp->lsize()]=0;
    initrand(len,pint,dec,(char**)t,sp->lsize());
}


