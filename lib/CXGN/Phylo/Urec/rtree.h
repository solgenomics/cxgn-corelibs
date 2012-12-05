
/************************************************************************
  Unrooted REConciliation version 1.00 
  (c) Copyright 2005-2006 by Pawel Gorecki
  Written by P.Gorecki.
  Permission is granted to copy and use this program provided no fee is
  charged for it and provided that this copyright notice is not removed. 
 *************************************************************************/


#ifndef _ROOTED__
#define _ROOTED__

#define OUT_LABEL complete_label
#define SHOW_INTERIOR_LABELS 0

#include <iostream>
#include <cstring>
#include <cstdlib>
#include <cstdio>

#include <map>
using namespace std;

char* getTok(char *s,int &p);
char* xstrndup(const char *s,int len);

extern double weight_loss;
extern double weight_dup;

typedef struct DlCost 
{
	int dup;
	int loss;
	DlCost(int dl=0,int ls=0) : dup(dl), loss(ls) {}
	friend ostream& operator<<(ostream&s, DlCost p)  
	{ return s << "(" << p.dup << "," << p.loss << ")"; } 
	friend DlCost operator+(DlCost s1,DlCost s)  
	{ return DlCost(s1.dup+s.dup,s1.loss+s.loss); }
	double mut() { return weight_dup*dup+weight_loss*loss; }
} DlCost;

class RInt;

class RNode // rooted node, I guess
{
	protected:
		RInt *pn;
		int depthn;
		DlCost dc;
		char* complete_label; 
	public:
		RNode() { pn=NULL; }
		virtual ~RNode() {}
		virtual int leaf() { return 0; }
		//		virtual ostream& print(ostream&s)  { return s; }
		int depth() { return depthn; }
		virtual void depth(int d) { depthn=d; }
		friend ostream& operator<<(ostream&s, RNode &p)  { return p.print(s); }  
		virtual RInt *p() { return pn; }
		virtual void p(RInt *p) { pn=p; }
		RNode *isParentOf(RNode *c);
		DlCost &costdet() { return dc; }

	virtual ostream& print(ostream&s)  { 
			return s << OUT_LABEL << "\n";
		}    
		virtual void showcostdet(ostream&s) { s << dc << " : "; print(s); s << endl; }
		virtual DlCost subtreecost()=0; 
		virtual void pfcostdet(ostream&s) {  
			s << " dup(" << dc.dup << ")" << " loss(" << dc.loss <<")"; };
};

class RInt : public RNode // rooted internal node?
{
	protected:
		RNode *ln; // left child node?
		RNode *rn; // right child node?

 public:
		RInt(RNode *_l,RNode *_r) : RNode(), ln(_l), rn(_r) 
			{ ln->p(this); rn->p(this);  complete_label = "";   }
			RInt(RNode *_l,RNode *_r, char* s, int len) : RNode(), ln(_l), rn(_r)
				{ ln->p(this); rn->p(this); 
					if(s != NULL && len > 0){ complete_label = xstrndup(s,len); }				 
					else{ complete_label = ""; }
				}
				virtual void depth(int d) { depthn=d; ln->depth(d+1); rn->depth(d+1); }
				~RInt() {}
				RNode *r() { return rn; }    
				RNode *l() { return ln; }
				virtual ostream& print(ostream&s)  {  
					s << "(" << *ln << "," << *rn << ")";
					if(SHOW_INTERIOR_LABELS){ s << OUT_LABEL; }
					return s; 
				}      
				virtual void showcostdet(ostream&s) { 
			RNode::showcostdet(s);
			ln->showcostdet(s);
			rn->showcostdet(s);
		}
		virtual DlCost subtreecost() { return ln->subtreecost() + dc + rn->subtreecost(); }
		virtual void pfcostdet(ostream&s) { 
			s << "(";  
			ln->pfcostdet(s);   	
			s << ",";  
			rn->pfcostdet(s);   	
			s << ")";
			RNode::pfcostdet(s); 
		} 
};


class RLeaf : public RNode
{
	protected:
		// RInt* pn - parent node is data member of RNode
		char* lab; // this is used for species.
		char* gene_id; // 
		//	char* complete_label; // something like At435[species=Arabidopsis_thaliana]:0.1 in RNode
	public:
		RLeaf(char*l) : RNode(), lab(l) {
			char* label_copy = xstrndup(l,0);
			complete_label = xstrndup(l,0);
			char* label = strtok(label_copy, " [:"); // everything up to first space : or [
			gene_id = xstrndup(label, 0); 
			char* attrib_name = strtok(NULL, " [="); 
			char* attrib_value;
			if((attrib_name == NULL) ||  (strcmp(attrib_name, "species") != 0)  ||	( (attrib_value = strtok(NULL, " =]")) == NULL) ){
				lab = xstrndup(label, 0);
			}
			else{ // [species=something] present. use it.		
				lab = xstrndup(attrib_value, 0);
			}
			free(label_copy);
		}
		~RLeaf() {}
		virtual int leaf() { return 1; }
		char* label() { return lab; }
		virtual ostream& print(ostream&s)  { 
			return s << OUT_LABEL; // 
		}    
		virtual DlCost subtreecost() { return dc; }
		virtual void pfcostdet(ostream&s) { 
			s << OUT_LABEL ;
			RNode::pfcostdet(s); 
		}

};

class RTree;

#define F_INTERNAL 1
#define F_LEAVES 2
#define F_ALL 4

class iterator_tree 
{
	RTree *t;
	RNode *c;
	int flag;
	RNode *step();
	public:
	iterator_tree(RTree *tr, int flag_=F_ALL);
	RNode *operator()();
};

class RTree
{
	protected:
		RNode *rootn;
		virtual RNode *parseNode(char *s, int &p);
		virtual RNode *createLeaf(const char *s, int len=0) { 
			return new RLeaf(xstrndup(s,len)); 
		} 
		virtual RNode *createInt(RNode *a, RNode *b) { return new RInt(a,b); } 
		virtual RNode *createInt(RNode *a, RNode *b, char* s, int len) { return new RInt(a,b,s,len); } 
	public:
		RTree(RNode *_root=NULL) : rootn(_root) { rootn->depth(0); }
		RTree(char *fromstr);
		virtual ~RTree() {}
		void str2tree(char *s) { int p=0; rootn=parseNode(s,p); }
		RNode *root() { return rootn; } 
		virtual ostream& print(ostream&s)  { return s << *rootn; }
		friend ostream& operator<<(ostream&s, RTree &p)  { return p.print(s); }   
};


typedef map<string,RNode*> lab2leaves;

class SpeciesTree : public RTree
{
	protected:
		lab2leaves lmap;
		void takeLeaves(RNode *r) { 
			if (r->leaf()) lmap[((RLeaf*)r)->label()]=r; 
			else { takeLeaves(((RInt*)r)->l()); takeLeaves(((RInt*)r)->r()); }    
		}
	public:
		SpeciesTree(char *s) : RTree(s) { takeLeaves(rootn); }  
		virtual ~SpeciesTree() {} 
		RLeaf *getLeaf(char *s) {  return (RLeaf*)lmap[s]; }
		int lsize() { return lmap.size(); }
		RNode *lca(RNode *a, RNode *b);    
		void showcostdet(ostream&s) { rootn->showcostdet(s); } 
		DlCost totalcost() { return rootn->subtreecost(); } 
		void pfcostdet(ostream&s) { cout << "[ "; rootn->pfcostdet(s); cout << "]" << endl; }
};

#endif
