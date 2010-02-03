
=head1 NAME

CXGN::Form.pm -- classes to deal with user-modifiable web forms

=head1 DESCRIPTION

The classes F

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=cut


use strict;

package CXGN::Insitu::Form;

=head2 new

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new { 
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

=head2 add_field

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_field { 
    my $self = shift;
    my $screen_name = shift;
    my $field_name = shift;
    my $contents = shift;
    my $length = shift;
    my $object = shift;
    my $getter = shift;
    my $setter = shift;
    my $field = CXGN::Insitu::Field->new($screen_name, $field_name, $contents, $length, $object, $getter, $setter);
    $self->add_field_obj($field);
}

=head2 add_field_obj

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_field_obj { 
    my $self = shift;
    my $field = shift;
    if (!exists($self->{fields})) { $self->{fields}=(); }
    push @{$self->{fields}}, $field;
}   

=head2 add_selection

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_selection { 
    my $self = shift;
}

=head2 set_action

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_action { 
    my $self = shift;
    $self->{action}=shift;
}

=head2 get_action

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_action { 
    my $self = shift;
    return $self->{action};
}

=head2 get_fields

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_fields { 
    my $self = shift;
    return @{$self->{fields}};
}

=head2 get_form_start

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub get_form_start { 
    my $self = shift;
    return "";
}

=head2 get_form_end

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub get_form_end { 
    my $self = shift;
    return "";
}

=head2 get_field_hash

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_field_hash { 
    my $self = shift;
    my %hash = ();
    foreach my $f ($self->get_fields()) { 
	$hash{$f->get_field_name()} = $f->render();
    }
    
    $hash{FORM_START}=$self->get_form_start();
    $hash{FORM_END} = $self->get_form_end();
    
    return %hash;
}

=head2 store

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub store { 
    my $self = shift;
    my $args = shift;
    foreach my $f ($self->get_fields()) { 
	my $setter = $f->get_setter();
	$f->get_object()->$setter($$args{$k});
    }
    $f->get_object->store();

}

package CXGN::Insitu::EditableForm;

use base qw / CXGN::Insitu::Form /;

sub new { 
    my $class = shift;
    return $class->SUPER::new(@_);
}

sub add_field { 
    my $self = shift;
    my $screen_name = shift;
    my $field_name = shift;
    my $contents = shift;
    my $length = shift;
    my $object = shift;
    my $getter = shift;
    my $setter = shift;
    my $field = CXGN::Insitu::EditableField->new($screen_name, $field_name, $contents, $length, $object, $getter, $setter);
    if (!exists($self->{fields})) { $self->{fields}=(); }
    push @{$self->{fields}}, $field;
}

sub get_form_start { 
    my $self = shift;
    return "<form>";
}

sub get_form_end { 
    my $self = shift;
    return "<input type=\"submit\" value=\"Store\" /> 
            <input type=\"reset\" value=\"Reset form\" />
            </form>";
}

=head1 NAME 

CXGN::Insitu::Field

=head1 DESCRIPTION

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=cut


package CXGN::Insitu::Field;

=head2 new

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $screen_name = shift;
    my $field_name = shift;
    my $contents = shift;
    my $length = shift;
    my $object = shift;
    my $getter = shift;
    my $setter = shift;

    my $self = bless {}, $class;
    print "HELLO!\n";
    
	print "Setting contents from object to ".$object->$getter."\n";
	$self->set_contents($object->$getter); 
    $self->set_name($screen_name);
   
    $self->set_field_name($field_name);
    if ($contents) { $self->set_contents($contents); }
    $self->set_length($length);
    
    return $self;
}

=head2 get_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_name {
  my $self=shift;
  return $self->{name};

}

=head2 set_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_name {
  my $self=shift;
  $self->{name}=shift;
}

=head2 get_field_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_field_name {
  my $self=shift;
  return $self->{field_name};

}

=head2 set_field_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_field_name {
  my $self=shift;
  $self->{field_name}=shift;
}

=head2 get_length

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_length {
  my $self=shift;
  return $self->{length};

}

=head2 set_length

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_length {
  my $self=shift;
  $self->{length}=shift;
}

=head2 get_contents

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_contents {
  my $self=shift;
  return $self->{contents};

}

=head2 set_contents

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_contents {
  my $self=shift;
  $self->{contents}=shift;
}

=head2 get_object

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_object {
  my $self=shift;
  return $self->{object};

}

=head2 set_object

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_object {
  my $self=shift;
  $self->{object}=shift;
}

=head2 get_object_setter

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_object_setter {
  my $self=shift;
  return $self->{object_setter};

}

=head2 set_object_setter

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_object_setter {
  my $self=shift;
  $self->{object_setter}=shift;
}

=head2 get_object_getter

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_object_getter {
  my $self=shift;
  return $self->{object_getter};

}

=head2 set_object_getter

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_object_getter {
  my $self=shift;
  $self->{object_getter}=shift;
}



=head2 render

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub render { 
    my $self = shift;
    return $self->get_contents()."\n";
}



package CXGN::Insitu::EditableField;

use base qw / CXGN::Insitu::Field /;

sub new { 
    my $class = shift;
    return $class->SUPER::new(@_);
}

sub render { 
    my $self = shift;
    return " <input name=\"".$self->get_field_name()."\" value=\"".$self->get_contents()."\" size=\"".$self->get_length()."\" />\n";
}



return 1;
