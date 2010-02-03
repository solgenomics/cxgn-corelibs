use strict;
use CXGN::Scrap;
use CXGN::Page;

package CXGN::Tools::Onto;

sub new { 
    my $class = shift;
    my $ajax = shift;
    my $self = bless {}, $class;
    
#    my $ajax = CXGN::Page->new();
    
    $ajax->jsan_use('MochiKit.DOM');
    $ajax->jsan_use('MochiKit.Visual');
    $ajax->jsan_use('MochiKit.Async');
    $ajax->jsan_use('Prototype');
    $ajax->jsan_use('MochiKit.Logging');
    $ajax->jsan_use('CXGN.Onto.Browser');
        
    return $self;
}


sub browse { 
    my $self = shift;

    
    #$self->jsan_includes();
    
   
# 	    <div id="ontology_browser_input" >    
#     </div>
# 	    <div id="ontology_term_input" >    
#      </div>
#     <div id="ontology_browser" >
# 	&nbsp;
    
#     </div>
	
 print <<HTML;
	<script language="javascript" type="text/javascript"  >
	<!-- 
	

	//JSAN.use('CXGN.Onto.Browser');

    var o;

	o = new CXGN.Onto.Browser();
        o.setUpBrowser();
	o.initializeBrowser();
	o.renderSearchById();
	o.renderSearchByName();
	o.render();


    
    
    -->
	</script>
	
	
HTML

}
    
=head2 get_parentage_string

 Usage: $self->get_parentage_string($accession)
 Desc:  get an ontology browser as a string with $accession highlighted
 Ret:   a string
 Args:  ontology accession e.g. 'GO:0000022'
 Side Effects: initialize a new ontology browser. See jslib/CXGN/Onto/Browser.js
 Example:

=cut

sub get_parentage_string {
    my $self = shift;
    my $accession= shift;
    my $print = 
<<HTML;	
	<Script language="javascript" type="text/javascript"  >
	<!-- 
		JSAN.use('CXGN.Onto.Browser');
    var o = new CXGN.Onto.Browser();
   
    o.setUpBrowser();
   
    o.initializeBrowser();
     // hide some unused elements
    document.getElementById('ontology_browser_input').style.display='none';
    document.getElementById('ontology_term_input').style.display='none';
    document.getElementById('hide_link').style.display='none';
    document.getElementById('search_results').style.display='none';
    o.showParentage('$accession');
    
    -->
	</script>
HTML

    
return $print;
}

=head2 get_parentage

 Usage: $self->get_parentage
 Desc:  print an ontology browser  with $accession highlighted
 Ret:   nothing
 Args:  ontology accession e.g. 'GO:0000022'
 Side Effects: initialize and print a new ontology browser. See jslib/CXGN/Onto/Browser.js
 Example:

=cut

sub get_parentage {
    my $self = shift;
    my $accession= shift;
    my $print = $self->get_parentage_string($accession);
    print $print;
}

sub term_selection_browse { 
    my $self = shift;
    my $link_to_textfield = shift;
    
    #$self->jsan_includes();
    
#     print <<HTML;
# 	    <div id="ontology_browser_input" >    
#     </div>
# 	    <div id="ontology_term_input" >    
#      </div>
#     <div id="ontology_browser" >
# 	&nbsp;
    
#     </div>

    print <<HTML;

	<script language="javascript" type="text/javascript"  >
	<!-- 
	

	JSAN.use('CXGN.Onto.Browser');

    var o = new Browser();
    o.setUpBrowser();
    o.initializeBrowser();
    o.renderSearchById();
    o.renderSearchByName();
    o.setLinkToTextField($link_to_textfield);
    o.setShowSelectTermButtons(true);
    o.render();
    
    -->
	</script>

HTML

}

return 1;
