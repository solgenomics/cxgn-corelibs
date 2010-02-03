
/************************************************************************
   Unrooted REConciliation version 1.00 
   (c) Copyright 2005-2006 by Pawel Gorecki
   Written by P.Gorecki. 
   Permission is granted to copy and use this program provided no fee is
   charged for it and provided that this copyright notice is not removed. 
*************************************************************************/

#include <set>
using namespace std;
#include <stdlib.h>
#include <unistd.h>
#include "rtree.h"
#include "urtree.h"

#define OPT_RECDETAILS 1
#define OPT_RECINFO 2
#define OPT_PRINTROOTED 4 
#define OPT_RECMINROOTING 8
#define OPT_RECTREECOSTDETAILS 16
#define OPT_PRINTGENE 32
#define OPT_PRINTSPECIES 64
#define OPT_RECMINCOST 128
#define OPT_SUMMARYTOTAL 256
#define OPT_SUMMARYDISTRIBUTIONS 512
#define OPT_SUMMARYDLTOTAL (1<<12)
#define OPT_TREEDISTRIBUTIONS (1<<13)
#define OPT_VOTING (1<<14)
#define OPT_BYCOST (1<<15)
#define OPT_RANDUNIQUE (1<<16)

int usage(int argc, char **argv)
{
    cout << " Unrooted REConciliation v1.01. (C) P.Gorecki 2005-2006" << endl;
    cout << " Usage: " << argv[0] << " [options]"<< endl;
    cout << " -g gene tree "  << endl;
    cout << " -s species tree"  << endl;
    cout << " -G filename - defines a set of gene trees"  << endl;
    cout << " -S filename - defines a set of species trees"  << endl;
    cout << " -R - show rootings for every gene tree"  << endl;
    cout << " -p - print a gene tree"  << endl;
    cout << " -P - print a species tree"  << endl;
    cout << " -D dupweight  - set weight of gene duplications" << endl;
    cout << " -L lossweight - set weight of gene losses" << endl;
    cout << " -r leaves - random unrooted gene trees"  << endl;
    cout << "   -n num - length for random gene tree"  << endl;	
    cout << "   -i rnum - prob. of internal node"  << endl;	
    cout << "   -e rnum - decreased prob. of internal node"  << endl;
    cout << "   -l num - number of random gene trees"  << endl;
    cout << "   -u - unique leaves (a species tree)" << endl;
    cout << "   -E num - number of leaves" << endl;
    cout << " -b - computing costs"  << endl;
    cout << " For every reconciliation of an unrooted gene tree with a species tree (details of costs):" << endl;
    cout << "   -o - show an optimal cost"  << endl;
    cout << "   -O - show an optimal rooting"  << endl;
    cout << "   -a - show attributes and mappings" << endl;
    cout << "   -A - show detailed attributes"<< endl;
    cout << " For every species tree, i.e., summary of costs when reconciling a species tree with a set of gene trees):" << endl; 
    cout << "   -c - print total mutation cost"  << endl;
    cout << "   -C - print total dl-cost (dup,loss)"  << endl;
    cout << "   -d - print detailed total cost (distributions)" << endl;
    cout << "   -x - print species tree with detailed total costs (nested parenthesis notation with attributes)" << endl;

    exit(-1);
}

#define BUFSIZE 10000    
void readgtree(char *fn, set<UTree*> &gtset)
{
    FILE *f;
    f= fopen(fn,"r");
    if (!f)
    {
	cerr << "Cannot open file " << fn << endl;
	exit(-1);
    }
    while (1)
    {
	char buf[BUFSIZE];
	if (!fgets(buf,BUFSIZE,f)) break;
	gtset.insert(new UTree(buf));	    
    }
    fclose(f);
}

void readstree(char *fn,set<SpeciesTree*> &stset)
{
    FILE *f;
    f= fopen(fn,"r");
    if (!f)
    {
	cerr << "Cannot open file " << fn << endl;
	exit(-1);
    }
    while (1)
    {
	char buf[BUFSIZE];
	if (!fgets(buf,BUFSIZE,f)) break;
	stset.insert(new SpeciesTree(buf));	    
    }
    fclose(f);
}


int  main(int argc, char **argv)
{
    int opt;
    int rt_len=2;
    int rt_numlv=-1;
    int loop=10;
    double rt_pint=0.5;
    double rt_dec=0.75;

    if (argc<2) usage(argc,argv);
    set<SpeciesTree*> stset;
    set<UTree*> gtset;

    srand (time (0));

    int genopt=0;
    while ((opt = getopt (argc, argv, "bvg:s:pPE:uaAr:Rl:i:e:n:OoG:XcCdxL:D:S:")) != -1)
	switch (opt)
	{
	    case 'g':
		gtset.insert(new UTree(optarg));
		break;
	    case 's':
		stset.insert(new SpeciesTree(optarg));
		break;
	    case 'S':
		readstree(optarg,stset);
		break;
	    case 'G':
		readgtree(optarg,gtset);
		break;
	    case 'p':
		genopt|=OPT_PRINTGENE;
		break;
	    case 'v':
		genopt|=OPT_VOTING;
		break;
	    case 'P':
		genopt|=OPT_PRINTSPECIES;
		break;
	    case 'l':
		if (sscanf(optarg,"%d",&loop)!=1) 
		{
		    cerr << "Number expected in -l" << endl;
		    exit(-1);
		}
		break;
	    case 'r':
		for (int i=0; i<loop; i++)
		    gtset.insert(new UTree(rt_len,rt_pint,rt_dec,rt_numlv,(genopt&OPT_RANDUNIQUE), optarg));	 
		break;
	    case 'n':
		if (sscanf(optarg,"%d",&rt_len)!=1) 
		{
		    cerr << "Number expected in -l" << endl;
		    exit(-1);
		}
		break;

	    case 'i':
		if (sscanf(optarg,"%lf",&rt_pint)!=1) 
		{
		    cerr << "Number expected in -i" << endl;
		    exit(-1);
		}
		break;
	    case 'e':
		if (sscanf(optarg,"%lf",&rt_dec)!=1) 
		{
		    cerr << "Number expected in -e" << endl;
		    exit(-1);
		}
		break;
	    case 'E':
		if (sscanf(optarg,"%d",&rt_numlv)!=1) 
		{
		    cerr << "Number expected in -E" << endl;
		    exit(-1);
		}
		break;
	case 'u':
	  genopt|=OPT_RANDUNIQUE;
	  break;
	case 'b':
		genopt|=OPT_BYCOST;
		break;
	    case 'a':
		genopt|=OPT_RECINFO;
		break;
	    case 'A':
		genopt|=OPT_RECDETAILS|OPT_RECINFO;
		break;

	    case 'L':
		if (sscanf(optarg,"%lf",&weight_loss)!=1) 
		{
		    cerr << "Number expected in -L" << endl;
		    exit(-1);
		}
		break;
	    case 'D':
		if (sscanf(optarg,"%lf",&weight_dup)!=1) 
		{
		    cerr << "Number expected in -D" << endl;
		    exit(-1);
		}
		break;
	    case 'R':
		genopt|=OPT_PRINTROOTED;
		break;
		
	    case 'o':
		genopt|=OPT_RECMINCOST;
		break;

	    case 'O':
		genopt|=OPT_RECMINROOTING;
		break;

	    case 'X':
		genopt|=OPT_RECTREECOSTDETAILS;
		break;

	    case 'c': 
		genopt|=OPT_SUMMARYTOTAL;
		break;

	    case 'C': 
		genopt|=OPT_SUMMARYDLTOTAL;
		break;

	    case 'd': 
		genopt|=OPT_SUMMARYDISTRIBUTIONS;
		break;

	    case 'x': 
		genopt|=OPT_TREEDISTRIBUTIONS;
		break;

	    default:
		cerr << "Unknown option: " << ((char)opt) << endl;
		exit(-1);
	}

    set<SpeciesTree*>::iterator stpos;
    set<UTree*>::iterator gtpos;

    if (genopt & OPT_PRINTGENE)
    {
	for (gtpos=gtset.begin(); gtpos !=gtset.end(); ++gtpos)
	    (*gtpos)->print(cout) << endl;
    }

    if (genopt & OPT_PRINTSPECIES)
			{
				for (stpos=stset.begin(); stpos !=stset.end(); ++stpos){				
					(*stpos)->print(cout) << endl;
				}
			}

    if (genopt & OPT_PRINTROOTED) 
    { 
	for (gtpos=gtset.begin(); gtpos !=gtset.end(); ++gtpos)
	    (*gtpos)->pprooted(cout);   
    }

    if (genopt & OPT_VOTING)
    {

	int trnum = stset.size();
	double mincnts[trnum];
	int i;

	for (i=0; i<trnum; i++) mincnts[i]=0;

	int j=0;
	for (gtpos=gtset.begin(); gtpos !=gtset.end(); ++gtpos)
	{
	    j++;
	    double min=0;
	    int minc=0;
	    UTree *g=*gtpos;
	    i=0;
	    for (stpos=stset.begin(); stpos !=stset.end(); ++stpos)
	    {
		g->clear();
		UNode *un=g->findoptimaledge(*stpos);		
		double m=(un->cost(*stpos)).mut();
		if (i==0) { min=m; minc=1; }
		else 
		    if (min>m) { min=m; minc=1; }
		    else if (min==m) minc++;
		i++;
	    }
	    i=0;
 	    for (stpos=stset.begin(); stpos !=stset.end(); ++stpos)
 	    {		
		g->clear();
 		UNode *un=g->findoptimaledge(*stpos);		
 		if ((un->cost(*stpos)).mut()==min)
		    mincnts[i]+=1.0/minc;
 		i++;
 	    }
	    
	}
	i=0;
	for (stpos=stset.begin(); stpos !=stset.end(); ++stpos)
	    cout << **stpos << " " << mincnts[i++] << endl;   
    }

    if (genopt & OPT_BYCOST)
    {
	for (stpos=stset.begin(); stpos !=stset.end(); ++stpos)
	{		
	    SpeciesTree *s = *stpos;
	    if (genopt & OPT_RECINFO) 
		cout << " SPECIES TREE: " << endl << *s << endl;

	    DlCost total;
		    
	    for (gtpos=gtset.begin(); gtpos !=gtset.end(); ++gtpos)
	    {
		UTree *g=*gtpos;
		g->clear();

		if (genopt & OPT_RECINFO) 
		{ 
		    cout << " GENE TREE: " << endl;
		    iterator_utree itu(g);
		    UNode *ur;
		    while ((ur=itu())!=0)
		    {
			if (ur->leaf())
			    cout << "** leaf " << ((ULeaf*)ur)->label();
			else {
			    cout << "** int  " ;
			    if (genopt & OPT_RECDETAILS) cout << "  " << *ur->smprooted() 
						       << endl;		    		
			}
			if (genopt & OPT_RECDETAILS) cout << "  p=" << *ur->p()->smprooted() << endl;
			cout << "\t sc=" << ur->sc(s);
			cout << "\t cost=" << ur->cost(s) << "\t ";
			cout << *ur->smprooted() << " ==> " << *ur->M(s) << endl;
		    }
		}
		
		UNode *un = NULL;

		if (genopt & (OPT_RECMINROOTING|OPT_RECMINCOST|OPT_RECTREECOSTDETAILS|OPT_SUMMARYTOTAL|OPT_SUMMARYDLTOTAL| OPT_SUMMARYDISTRIBUTIONS|OPT_TREEDISTRIBUTIONS))
		    un=g->findoptimaledge(s);
		  
		if (genopt & OPT_RECMINROOTING) cout <<  *un->rooted() << endl;

		if (genopt & OPT_RECMINCOST) cout << un->cost(s) << endl;
		
		if (genopt & OPT_RECTREECOSTDETAILS)
		{
		    if (un->p()) un->p()->mark(2|8);
		    un->mark(2);
		    g->pf(cout,s);
		}
		
		if ((genopt & OPT_SUMMARYTOTAL)||(genopt & OPT_SUMMARYDLTOTAL))
		{
		    DlCost s1 = un->cost(s);
		    total.loss+=s1.loss;
		    total.dup+=s1.dup;
		}
 
		if ((genopt & OPT_SUMMARYDISTRIBUTIONS) || (genopt & OPT_TREEDISTRIBUTIONS)) un->costdet(s);
	    } // gt-loop		

	    if (genopt & (OPT_SUMMARYTOTAL|OPT_SUMMARYDLTOTAL|OPT_SUMMARYDISTRIBUTIONS))
		cout << *s << "\t";

	    if (genopt & OPT_SUMMARYTOTAL) cout << total.mut() << "\t";
	    if (genopt & OPT_SUMMARYDLTOTAL) cout << total << "\t";

	    if (genopt & (OPT_SUMMARYTOTAL|OPT_SUMMARYDLTOTAL|OPT_SUMMARYDISTRIBUTIONS))
		cout << endl;
	    
	    if (genopt & OPT_SUMMARYDISTRIBUTIONS) s->showcostdet(cout);
	    if (genopt & OPT_TREEDISTRIBUTIONS) s->pfcostdet(cout);
	    
	} // st-loop
    } // (OPT_BYCOST)

}
