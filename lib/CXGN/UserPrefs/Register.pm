package CXGN::UserPrefs::Register;

=head1 NAME

CXGN::UserPrefs::Register

=cut

=head1 Synopsis

A very simple singleton class which holds a hash of registered user_prefs 
string id's.  In order to create a new user preference id, you must first 
put the Id in this registry.  CXGN::UserPrefs will die if an unregistered 
preference-setting is attempted.

The purpose of the registry is to prevent clobbering of preferences 
between site developers.  Please include a description of your preference 
id in the hash.

=cut

# This is the most important part, enter your keys here, or use propose()
# to generate the new hash.  There is a helper script (propose.pl) in 
# core/sgn-tools/userprefs that is very useful in generating this hash.

our %REGISTER = (
	"cdsSeqDisp" => "Display boolean",
	"cdsSpaceSwap" => "Swaps spaces vs no spaces in CDS sequence in Secretary geneview",
	"genomicSeqDisp" => "",
	"GOcollapse" => "",
	"propertiesCollapse" => "",
	"proteinInfoCollapse" => "",
	"protSeqDisp" => "",
	"searchHighlight" => "Highlighting of search keywords on Secretary",
	"sp_person_id" => "The owner of the cookie string",
	"TAIRannotationCollapse" => "",
	"timestamp" => "Keeps track of preference string age for a user"
);

=head2 verify()

Given an Id, checks to see if it's in the register, dies otherwise

=cut

sub verify {
	my $id = shift;
	unless(exists $REGISTER{$id}) { 
		die "UserPref ID: '$id' does not exist in the Register.  You must enter the key in the \%REGISTER hash of CXGN::UserPrefs::Register.";
	}
}

=head2 propose()

Given a quoted word list, this will return the text necessary to 
replace the register hash definition.  Conflicts will result in 
death, with descriptive notices.

=cut

sub propose {
	my @proposed = @_;
	my @exists = ();
	my @bad_key = ();
	foreach (@proposed) {
		if(exists $REGISTER{$_}) { push(@exists, $_) }
		unless(/^[a-zA-Z]\w+$/) { push(@bad_key, $_) }
	}
	if(@exists or @bad_key) {
		$failstring = "\nProposal failed.\n";
		$failstring .= "The key(s) " . join(", ", map { "'$_'" } @exists) . " already exist in the register.\n" if (@exists);
		$failstring .= "The key(s) " . join(", ", map { "'$_'" } @bad_key) . " are malformed, failed to match /^[a-zA-Z]\\w+\$/" if (@bad_key);
		$failstring .= "\n\n";
		die $failstring;
	}
	my @newkeys = keys %REGISTER;
	push(@newkeys, @proposed);
	@newkeys = sort {lc($a) cmp lc($b) } @newkeys;
	my $newtext = "our \%REGISTER = (\n";
	
	foreach my $key (@newkeys) {
		if(exists $REGISTER{$key}){
			$newtext .= "\t\"$key\" => \"$REGISTER{$key}\",\n";
		}
		else {
			$newtext .= "\t\"$key\" => \"\",\n"; 
		}
	}
	chomp($newtext);
	chop($newtext);	
	return ($newtext .= "\n);\n");
}	

sub get_ids {
	return keys %REGISTER; 
}
	
sub get_register {
	return \%REGISTER;
}
	

