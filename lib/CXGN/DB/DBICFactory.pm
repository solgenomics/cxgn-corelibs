package CXGN::DB::DBICFactory;
use Moose;

use English;
use Carp;

use CXGN::DB::Connection;

=head1 NAME

CXGN::DB::DBICFactory - thin wrapper to instantiate L<DBIx::Class> schemas
using connection params from L<CXGN::DB::Connection>

=head1 SYNOPSIS

  my $s = CXGN::DB::DBICFactory
            ->open_schema( 'Bio::Chado::Schema',
                           search_path => ['public','sgn'],
                         );


  my $m = CXGN::DB::DBICFactory
            ->merge_schemas( schema_classes =>
                              [ 'Bio::Chado::Schema',
                                'SGN::Schema',
                              ],
                             search_path => ['public','sgn'],
                           );

=head1 CLASS METHODS

=head2 open_schema

  Status  : public
  Usage   : my $schema = CXGN::DB::DBICFactory
                            ->open_schema( $schema_classname,
                                           %options
                                         );
  Returns : a DBIx::Class::Schema object
  Args    : schema class name, hash-style list of options as:

              search_path => arrayref of schema names to set
                             as the search path
              dbconn_args => hashref of args passed directly to
                             CXGN::DB::Connection->new_no_connect

  Side Eff: dies on error

=cut

sub open_schema {
    my ($class, $package_name, %options) = @_;

    my @params = CXGN::DB::Connection
        ->new_no_connect( $options{dbconn_args} || () )
        ->get_connection_parameters;

    $params[-1]->{AutoCommit} = 1; #< override autocommit, which
                                   #  should be on by default for
                                   #  DBIC, which does its own
                                   #  transaction control

    # make sure the schema class is loaded
    { no strict 'refs';
      unless( @{$package_name.'::ISA'} ) {
          eval "require $package_name"; #< load the package name if we need to
          die "could not require $package_name: $EVAL_ERROR" if $EVAL_ERROR;
      }
    }

    return $package_name
             ->connect( @params,
                        {
                         ( $options{search_path}
                             ? (on_connect_do => ['SET search_path TO '.join(',',@{$options{search_path}})])
                             : ()
                         )
                        },
                      );

}


=head2 merge_schemas

  Usage   : my $s = CXGN::DB::DBICFactory
                      ->merge_schemas( schema_classes =>
                                        [ 'Foo', 'Bar', 'Baz' ],
                                       search_path => ...
                                     )
  Returns : a L<DBIx::Class::Schema>-based object,
            containing all the ResultSource objects from the
            listed schema classes

  Args : same as open_schema above, except
         schema_class is replaced with schema_classes:

              schema_classes => arrayref of schema class names,

  Merges multiple DBIC Schema namespaces into a single schema.

=cut

my $merge_increment = 0;
sub merge_schemas {
    # get args and validate
    my $class = shift;
    my %args = @_;
    my $schema_classes = delete $args{schema_classes};
    $schema_classes && ref $schema_classes eq 'ARRAY'
        or croak 'must pass a schema_classes arrayref';


    #### make a new schema class on the fly

    # make a unique package name for the merged schema
    my $merged_package = $class.'::auto_merged::'.++$merge_increment;

    # create the merged schema package, with the proper base class
    {
      require DBIx::Class::Schema;
      no strict 'refs';
      @{$merged_package.'::ISA'} = qw( DBIx::Class::Schema );
    }

    # load the sources for each of the given schemas into the new
    # package, checking for collisions in monikers or table names
    my %used_monikers;
    my %used_table_names;
    for my $schema_class (@$schema_classes) {
        for my $source_moniker ( $schema_class->sources ) {
            my $source_obj = $schema_class->source( $source_moniker );

            # croak for any collisions in source monikers
            $used_monikers{$source_moniker}
                and croak "both $schema_class and $used_monikers{$source_moniker} "
                        . "have moniker $source_moniker, cannot merge";
            $used_monikers{$source_moniker} = $schema_class;

            # warn about any collisions in table names
            if( $source_obj->isa('DBIx::Class::ResultSource::Table') ) {
                my $table_name = $source_obj->from;

                my $result_class = $source_obj->result_class;
                $used_table_names{$table_name}
                    and carp "WARNING: both $result_class and "
                           . "$used_table_names{$table_name} use table/view "
                           . "$table_name";
                $used_table_names{$table_name} = $result_class;
            }

            # finally, register the resultsource with the target schema
            $merged_package->register_source( $source_moniker, $source_obj );
        }
    }

    ### and use open_schema to open it with the given connection
    ### arguments
    return $class->open_schema( $merged_package, %args );
}


=head1 MAINTAINER

Robert Buels

=head1 AUTHOR

Robert Buels, E<lt>rmb32@cornell.eduE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

####
1;
###
