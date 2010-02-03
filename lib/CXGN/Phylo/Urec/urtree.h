
/************************************************************************
   Unrooted REConciliation version 1.00 
   (c) Copyright 2005-2006 by Pawel Gorecki
   Written by P.Gorecki.
   Permission is granted to copy and use this program provided no fee is
   charged for it and provided that this copyright notice is not removed. 
*************************************************************************/

#ifndef _UNROOTED__
#define _UNROOTED__
#include <iostream>
#include <map>
#include <set>
#include <list>

using namespace std;

#include "rtree.h"

#define C_MAP 1
#define C_SC 2
#define C_COST 4

class UNode;
typedef set<UNode*> nodset;

extern int detailed_costs;
int lossprim(RNode *s,RNode *s1,RNode *s2);
void dlcostdet(RNode *s,RNode *s1,RNode *s2);
#define dupprim(s,s1,s2) (( (s==s1) || (s==s2))?1:0)

class UNode // unrooted node, I guess
{
 protected:
	UNode *pn;
	RNode *Mn;    
	DlCost scn;
	DlCost costn;
	int computed;
	int ismarked;
	char* complete_label;
 public:
		UNode(UNode *p_=NULL, char* s=NULL, int len=0) : pn(p_), Mn(NULL), computed(0), ismarked(0), complete_label("") {
			if(s != NULL  && len > 0){	complete_label = xstrndup(s, len); }
} 
    virtual ~UNode() {}
    void reset() { computed=0; Mn=NULL; ismarked=0; }
    void mark(int m=1) { ismarked|=m; }
    int marked() { return ismarked; }
    virtual int leaf()=0;
    virtual void clear()=0;
    virtual UNode *p() { return pn; }
    void p(UNode *p_) { pn=p_; }
    DlCost &cost(SpeciesTree *st)
			{
				if (!pn) return costn;
				if (!(computed & C_COST)) 
					{
						RNode *s = st->lca(M(st),pn->M(st));
						costn.loss=sc(st).loss+pn->sc(st).loss+lossprim(s,M(st),pn->M(st));
						costn.dup=sc(st).dup+pn->sc(st).dup+dupprim(s,M(st),pn->M(st));	
						computed|=C_COST;
					}
				return costn; 
			}
    void costdet(SpeciesTree *st)
	{
	    if (!pn) return; // nothing to compute (a leaf)
	    RNode *s = st->lca(M(st),pn->M(st));
	    dlcostdet(s,M(st),pn->M(st));
	    costdetsubtree(st);
	    pn->costdetsubtree(st);
	}
    virtual void costdetsubtree(SpeciesTree *st) {}
    virtual ostream& ppsmprooted(ostream&s)=0;
    virtual RNode *smprooted()=0;
    virtual RNode *M(SpeciesTree *st)=0;
    virtual ostream& pprooted(ostream&s, int from) {
	if (pn) 
	{	    
	    s << "(";
	    ppsmprooted(s) << ",";
	    return pn->ppsmprooted(s) << ")" << endl;
	}
	return ppsmprooted(s);
    }

    virtual RNode* rooted() {  
	if (pn) return new RInt(smprooted(), pn->smprooted()); 
	return smprooted();
    }

    virtual nodset* insert(nodset *n)=0;
    virtual DlCost &sc(SpeciesTree *st) { return scn; }
    virtual ostream& pf(ostream& s, double c, SpeciesTree *st) {
        if (pn) {
            s << "(" ;
            smppf(s,c,st) << ",";
            return pn->smppf(s,c,st) << ")";
        }
        return smppf(s,c,st);
    }
    virtual ostream& smppf(ostream &s,double, SpeciesTree*)=0;
    void pcosts(ostream &s,double c,SpeciesTree *st)
        {
            s << " totalc({" << cost(st).dup << "," << cost(st).loss << "})"
              << " treec({" << sc(st).dup << "," << sc(st).loss << "}) " ;

	    if (ismarked & 1) s << " mark(1)";
	    if (ismarked & 2) s << " markopt(1)";
	    if (ismarked & 4) s << " markstart(1)";
	    if (ismarked & 8) s << " markoptm(1)";
		
//            if (c==cost(st).mut()) s << " minc(1) ";
            if (M(st)->p()) s << " destn(\"" << *M(st) << "\") ";
            else s << " destn(\"\") ";
        }
    virtual UNode* subtreecost(SpeciesTree *st)=0;
    virtual UNode* mincost(SpeciesTree *st)=0;
};

class ULeaf : public UNode  // unrooted leaf node
{
 protected:
	char *lab; // this is used for the species
	char* gene_id; // another label, use for e.g. sequence id
	//	char* complete_label; // something like At435[species=Arabidopsis_thaliana]:0.1
 public:
	ULeaf(char *lab_, UNode *p_=NULL) : UNode(p_), lab(lab_) {
		// if   for example lab_  is "gene43[species=wombat]"   then copy "wombat" into lab, "gene43" into gene_id,
		// else just copy lab_  into both lab, gene_id
	
		char* label_copy = xstrndup(lab_,0);
		complete_label = xstrndup(lab_,0);
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
		//  ULeaf(char* lab_, char* gene_id_, UNode *p_=NULL) : UNode(p_), lab(lab_), gene_id(gene_id_) {} // constructor which takes care of gene_id too.
			virtual ~ULeaf() {}
			virtual int leaf() { return 1; }
			char* label() { return lab; }
			virtual void clear() { reset(); }
			virtual ostream& ppsmprooted(ostream&s)  { return s << OUT_LABEL; }
			virtual RNode *smprooted()  { return new RLeaf(complete_label); }
			virtual nodset* insert(nodset *n) { n->insert(this); return n; }
			virtual RNode *M(SpeciesTree *st) { 
				if (!(computed & C_MAP)) 
					{
						Mn=st->getLeaf(lab);
						if (!Mn) { 
							cerr << "Mapping of " << lab << " not found in the species tree." <<endl;
							exit(-1);
						}			 
						computed|=C_MAP;
					}
				return Mn; 	
			}
    virtual ostream& smppf(ostream& s,double c,SpeciesTree *st) { 
			s << OUT_LABEL;
			pcosts(s,c,st);
			return s;
    }
    virtual UNode* subtreecost(SpeciesTree *st)
	{
	    cost(st);
	    return this;
	}
    virtual UNode* mincost(SpeciesTree *st)
	{
	    cost(st);
	    if (!pn) return this;
	    if (pn->leaf()) return this;
	    return pn->subtreecost(st);
	}
};

class UNode3 : public UNode // aha! internal node. "3" because connects to 3 other nodes ???
							 // so UNode3, ULeaf are both derived from UNode
{
 protected:
	UNode3 *ln; // left and
	UNode3 *rn; // right neighbor nodes (which together with pn inherited from UNode are the 3 neighbor nodes ?
    void connect(UNode3 *a, UNode3 *b);
 public:
		//  UNode3(UNode *p_=NULL) : UNode(p_) {}
			UNode3(UNode *p_=NULL, char* s=NULL, int len=0) : UNode(p_, s, len) {}
    ~UNode3() {}
    virtual int leaf() { return 0; }
    UNode3 *l() { return ln; }    
    UNode3 *r() { return rn; }
    virtual void clear() { 
	reset(); 
	ln->reset();
	rn->reset();
	ln->p()->clear();
	rn->p()->clear();
    }
    void l(UNode3 *l_) { ln=l_; }
    void r(UNode3 *r_) { rn=r_; }    
    virtual RNode *M(SpeciesTree *st) { 
	if (!(computed & C_MAP)) 
	{
	    Mn=st->lca(ln->p()->M(st),rn->p()->M(st));
	    computed|=C_MAP;
	}
	return Mn; 	
    }  
    virtual void costdetsubtree(SpeciesTree *st)
	{
	    dlcostdet(M(st),ln->p()->M(st),rn->p()->M(st));
	    ln->p()->costdetsubtree(st);
	    rn->p()->costdetsubtree(st);
	}
    virtual DlCost& sc(SpeciesTree *st) { 
	if (!(computed & C_SC)) 
	{
	    scn.loss=ln->p()->sc(st).loss+rn->p()->sc(st).loss
		+lossprim(M(st),ln->p()->M(st),rn->p()->M(st));
	    scn.dup=ln->p()->sc(st).dup+rn->p()->sc(st).dup
		+dupprim(M(st),ln->p()->M(st),rn->p()->M(st));
	    computed|=C_SC;
	}
	return scn; 	
    }      
    virtual ostream& pprooted(ostream&s,int from=0);
    virtual ostream& ppsmprooted(ostream&s) {  
	s << "(";
	ln->p()->ppsmprooted(s) << ","; 
	rn->p()->ppsmprooted(s) << ")";
	if(SHOW_INTERIOR_LABELS){ s << complete_label; } // Can show label (e.g. branch length) for interior nodes, but at present the branch length will
	// be wrong for nodes whose parent has changed due to rerooting, since in that case the branch length will refer to a branch which no longer goes to
	// the node's parent.
	return s;
    }
    virtual nodset* insert(nodset *n) { 
	n->insert(this); n->insert(ln); n->insert(rn); 
	ln->p()->insert(n); rn->p()->insert(n); return n; 
    } 
    virtual RNode* smprooted() { return new RInt(ln->p()->smprooted(), rn->p()->smprooted(), complete_label, strlen(complete_label)); }    
    virtual ostream& smppf(ostream& s, double c, SpeciesTree *st) {
        s << "( (";
        ln->p()->smppf(s,c,st) << ") ";
        ln->pcosts(s,c,st);
        s << ", ( ";
        rn->p()->smppf(s,c,st) << " ) " ;
        rn->pcosts(s,c,st);
        s << " )";
        pcosts(s,c,st);
        return s;
    }
    virtual UNode* subtreecost(SpeciesTree *st)
	{
	    UNode *res=ln->p()->subtreecost(st);	    
	    UNode *res1=rn->p()->subtreecost(st);	    	    
	    if (res->cost(st).mut()>res1->cost(st).mut()) res=res1;
	    if (res->cost(st).mut()>cost(st).mut()) return this;
	    return res;
	}

    virtual UNode* mincost(SpeciesTree *st)
	{
	    UNode *res=pn->subtreecost(st);
	    UNode *res1=ln->p()->subtreecost(st);
	    if (res->cost(st).mut()>res1->cost(st).mut()) res=res1;
	    res1=rn->p()->subtreecost(st);
	    if (res->cost(st).mut()>res1->cost(st).mut()) return res1;
	    return res;
	}
};

class UTree;
class iterator_utree
{
 protected:
    nodset::iterator nit;
    nodset* nodes;
    UNode *c;
    int flag;
 public:
    iterator_utree(UTree *t, int flag_=F_ALL);
    UNode *operator()();
};

class UTree 
{
 protected:
    UNode *start;
    UNode *toUNodes(RNode *t);
    UNode3* connect(UNode3 *a, UNode3 *b, UNode3 *c, UNode *u1, UNode *u2);
    virtual UNode *createLeaf(char *s, int len=0) { return new ULeaf(xstrndup(s,len)); } 
    virtual UNode *createNode3(UNode *u1, UNode *u2) { 
			return connect(new UNode3(),new UNode3(),new UNode3(),u1,u2);  }

		virtual UNode *createNode3(UNode *u1, UNode *u2, char* s, int len) { 
			return connect(new UNode3(NULL, s, len),new UNode3(NULL, s, len),new UNode3(NULL, s, len),u1,u2);  }

    UNode *parseNode(char *s, int &p, int fromroot=0);
    void initrand(int len,double pint, double dec, char **t, int splen);
 public:
    UTree(char *t) { int p=0; parseNode(t,p,1); }  
    UTree() { start=NULL; }
    UTree(int len,double pint, double dec, SpeciesTree *sp);
    UTree(int len,double pint, double dec, int numlv, int uniquelv, char *t);
    virtual ~UTree() {}    
    friend class iterator_utree;    
    virtual ostream& pprooted(ostream&s);    
    nodset* nodes() { return start->insert(start->p()->insert(new nodset)); } 
    UNode *findoptimaledge(SpeciesTree *st); 
    void clear() { start->clear(); if (start->p()) start->p()->clear(); } 
    void pf(ostream &s,SpeciesTree *st) { s << "[" ; start->pf(s,0,st); s << "]" << endl; } 
    UNode* mincost(SpeciesTree *st) { return start->mincost(st); }
    UNode *genRand(double pint, double dec, char **t, int s);
    virtual ostream& print(ostream&s) { return cout  << *start->rooted(); };    

};

#endif
