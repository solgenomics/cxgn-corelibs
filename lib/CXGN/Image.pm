
=head1 NAME

Image.pm - a class for accessing the md_metadata.image table.


=head1 DESCRIPTION

This class provides database access and store functions
and functions to associate tags with the image.

Image uploads are handled by the SGN::Image subclass.

The implementation how images are stored has been changed. Whereas the
images were stored in the image root dir keyed to the image_id, it is
now keyed to the md5sum of the original image, with the md5sum stemmed
into two byte directories. The constructor now takes a hash instead of
positional arguments.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)
Naama Menda (nm249@cornell.edu)

=head1 VERSION

0.02, Dec 15, 2009.

=head1 MEMBER FUNCTIONS

The following functions are provided in this class:

=cut


use strict;

package CXGN::Image;

use Carp;
use Digest::MD5;
use File::Path 'make_path';
use File::Spec;
use File::Temp 'tempdir';
use File::Copy qw| copy move |;
use CXGN::Tag;

use base qw | CXGN::DB::ModifiableI |;


# some pseudo constant definitions
#
our $LARGE_IMAGE_SIZE     = 800;
our $MEDIUM_IMAGE_SIZE    = 400;
our $SMALL_IMAGE_SIZE     = 200;
our $THUMBNAIL_IMAGE_SIZE = 100;


=head2 new

 Usage:        my $image = CXGN::Image->new(dbh=>$dbh, image_id=>23423
               image_dir => $image_dir)
 Desc:         constructor
 Ret:
 Args:         a hash of a database handle, optional identifier, and the
               path to the root image_dir, with keys dbh, image_id and image_dir.
 Side Effects: if an identifier is specified, the image object
               will be populated from the database, otherwise
               an empty object is returned.
               Either way, a database connection is established.
 Example:

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new($args{dbh}, $args{image_id});

    unless( exists $args{dbh} && exists $args{image_dir} ) {
	die "Required arguments: dbh, image_dir";
    }
    $self->set_image_dir($args{image_dir});
    $self->set_dbh($args{dbh});

    if( exists $args{image_id} ) {
	$self->set_image_id($args{image_id});
	$self->_fetch_image() if $args{image_id};
    }
    return $self;
}

sub _fetch_image {
    my $self = shift;
    my $query = "SELECT image_id,
                        name,
                        description,
                        original_filename,
                        file_ext,
                        sp_person_id,
                        modified_date,
                        create_date,
                        md5sum
                 FROM   metadata.md_image
                 WHERE  image_id=?
                        and obsolete != 't' ";

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_image_id()) ;

    my ( $image_id, $name, $description, $original_filename, $file_ext, $sp_person_id, $modified_date, $create_date, $md5sum) =
	$sth->fetchrow_array();


    $self->set_name($name);
    $self->set_description($description);
    $self->set_original_filename($original_filename);
    $self->set_file_ext($file_ext);
    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
    $self->set_image_id($image_id);
    $self->set_md5sum($md5sum);# we do this that if is an image that has been deleted,
                                    # the object will get the NULL from the database and not
                                    # the image_id that was fed into the object.

    #print STDERR  "Loaded image $image_id, $md5sum, $name, $original_filename, $file_ext\n";

}

=head2 store

 Usage:        $image->store()
 Desc:         will store the data in the image object to the database
               if the image has an associated image_id, an update will
               occur. if the image does not have an associated image_id,
               an insert into the database will occur.
 Ret:          the image_id of the updated or inserted object.
 Args:
 Side Effects: database update or insert. Note that the image itself is
               stored on the file system and that it is not affected by
               this operation, unless the filename property is changed.
 Example:

=cut

sub store {
    my $self = shift;
    if ($self->get_image_id()) {

	# it's an update
	#
	my $query = "UPDATE metadata.md_image SET
                            name=?,
                            description=?,
                            original_filename=?,
                            file_ext=?,
                            sp_person_id =?,
                            modified_date = now(),
                            md5sum =?
                      WHERE md_image.image_id=?";

	my $sth = $self->get_dbh()->prepare($query);

	$sth->execute(
	    $self->get_name(),
	    $self->get_description(),
	    $self->get_original_filename(),
	    $self->get_file_ext(),
	    $self->get_sp_person_id(),
	    $self->get_md5sum(),
	    $self->get_image_id(),

	    );
	return $self->get_image_id();
    }
    else {

	# it is an insert
	#
	my $query = "INSERT INTO metadata.md_image
                            (name,
                            description,
                            original_filename,
                            file_ext,
                            sp_person_id,
                            obsolete,
                            modified_date,
                            md5sum)
                     VALUES (?, ?, ?, ?, ?, ?, now(), ?)";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		       $self->get_name(),
		       $self->get_description(),
		       $self->get_original_filename(),
		       $self->get_file_ext(),
		       $self->get_sp_person_id(),
		       $self->get_obsolete(),
	               $self->get_md5sum(),
		       );
	my $image_id= $self->get_currval("metadata.md_image_image_id_seq");
	$self->set_image_id($image_id);
	return $self->get_image_id();
    }
}

=head2 delete

 Usage:  $self->delete()
 Desc:   set the image status to obsolete='t'
 Ret:    nothing
 Args:  none
 Side Effects: set to obsolete='t' in individual_image, and locus_image
 Example:

=cut

sub delete {
    my $self = shift;
    if ($self->get_image_id()) {
	my $query = "UPDATE metadata.md_image set obsolete='t' WHERE image_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_image_id());
	$self->set_obsolete(1);
	#delete image-individual associations
	my $query2 = "UPDATE phenome.individual_image set obsolete = 't' WHERE image_id = ?";
	my $sth2 = $self->get_dbh()->prepare($query2);
	$sth2->execute($self->get_image_id() );
        #deanx - nov.14 2007 remove from locus_image too
	my $query3 = "UPDATE phenome.locus_image set obsolete = 't', modified_date = now() WHERE image_id = ?";
      	my $sth3 = $self->get_dbh()->prepare($query3);
	$sth3->execute($self->get_image_id() );

    }
    else {
	warn("Image.pm: Trying to delete an image from the db that has not yet been stored.");
    }

}

=head2 get_image_id, set_image_id

 Usage:        accessor for the image_id property.
 Desc:
 Ret:
 Args:
 Side Effects: if the image_id is not set, the store() function
               will insert a new row and set the image_id to
               the inserted row. Otherwise, store() performs
               an update.
 Example:

=cut

sub get_image_id {
    my $self=shift;
    return $self->{image_id};

}

sub set_image_id {
    my $self=shift;
    $self->{image_id}=shift;
}


=head2 get_name, set_name

 Usage:
 Desc:         gets/sets the name of the image
 Ret:
 Args:
 Side Effects: will be stored in db
 Example:

=cut

sub get_name {
    my $self=shift;
    return $self->{name};

}

sub set_name {
    my $self=shift;
    $self->{name}=shift;
}

=head2 get_description, set_description

 Usage:
 Desc:         accessor for the description property
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_description {
    my $self=shift;
    return $self->{description};

}

sub set_description {
    my $self=shift;
    $self->{description}=shift;
}


=head2 get_original_filename, set_original_filename

 Usage:
 Desc:         accessor for the original_filename property
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_original_filename {
    my $self=shift;
    return $self->{original_filename};
}

sub set_original_filename {
    my $self=shift;
    $self->{original_filename}=shift;
}

=head2 get_file_ext, set_file_ext

 Usage:
 Desc:         accessor for the file_ext property
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_file_ext {
  my $self=shift;
  return $self->{file_ext};

}

sub set_file_ext {
    my $self=shift;
    $self->{file_ext}=shift;
}

=head2 accessors get_image_dir(), set_image_dir()

 Usage:        returns the image dir
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_image_dir {
    my $self  = shift;
    return $self->{image_dir};
}

sub set_image_dir {
    my $self = shift;
    $self->{image_dir} = shift;
}


=head2 process_image

 Usage:        $return_code = $image -> process_image($filename);
 Desc:         processes the image that has been uploaded with the upload command.
 Ret:          the image id of the image in the database as a positive number,
               error conditions as negative numbers.
 Args:         the filename of the file (complete path)
 Side Effects: generates a new subdirectory in the image_dir for the image files,
               copies the image file to a temp dir directory where it is processed
               (resized thumnbnails and other views for the image). After that
               is done, the image object is stored in the database, and the
               image files are moved to the final location in the filesystem.
 Example:

=cut



sub process_image {
    my $self      = shift;
    my $file_name = shift;
    my $type      = shift;
    my $type_id   = shift;

    if ( my $id = $self->get_image_id() ) {
        warn
"process_image: The image object ($id) should already have an associated image. The old image will be overwritten with the new image provided!\n";
        die "I'm dying now. Ouch!\n";
    }

    my ($processing_dir) =
      File::Temp::tempdir( "process_XXXXXX",
        DIR => $self->get_image_dir() );
    system("chmod 775 $processing_dir");
    $self->set_processing_dir($processing_dir);

    # process image
    #
    $processing_dir = $self->get_processing_dir();

    # copy unmodified image to be fullsize image
    #
    my ($basename, $directories, $file_ext) = File::Basename::fileparse($file_name, qr/\..+/);
    #print STDERR "BASENAME $basename, DIR $directories, EXT: $file_ext\n";
    # deanx - preserver original filename
    my $original_filename = $basename;
    my $original_file_ext = $file_ext;

    my $dest_name = $self->get_processing_dir() . "/" . $basename.$file_ext;
    #print STDERR "Copying $file_name to $dest_name...\n";

    #    eval {
    File::Copy::copy( $file_name, $dest_name )
      || die "Can't copy file $file_name to $dest_name";
    my $chmod = "chmod 664 '$dest_name'";

    ### Multi Page Document Support
    #    deanx - nov. 16 2007
    #   PDF, PS, EPS documents are now supported by ImageMagick/Ghostscript
    #   A primary impact is these types can multipage.  'mogrify' produces
    #   one image per page, labelled filename-0.jpg, filename-1.jpg ...
    #   This code detects multipage documents and copies the first page for
    #   thumbnail processing

    my @image_pages = `/usr/bin/identify "$dest_name"`;

    if ( $#image_pages > 0 ) {    # multipage, pdf, ps or eps

#	eval  {
# note mogrify used since 'convert' will not correctly reformat (convert makes blank images)
# if  (! (`mogrify -format jpg '$dest_name'`)) {die "Sorry, can't convert image $basename";}
# if ( system("/usr/bin/mogrify -format jpg","$upload_dir/$basename") != 0) {die "Sorry, can't convert image $basename";}
# my $chmod = "chmod 664 '$upload_dir/$basename'";
# Convert and mogrify both dislike the format of our filenames intensely if ghostscript
#   is envoked ... change filename to something beign like temp.<ext>

        my $newname;
        #if ( $basename =~ /(.*)\.(.{1,4})$/ )
	if ($file_ext) {
            #note; mogrify will create files name
            # basename-0.jpg, basename-1.jpg
            my $mogrified_first_image = $processing_dir . "/temp-0.jpg";
            my $tempname =
              $processing_dir . "/temp" . $file_ext;    # retrieve file extension
            $newname = $basename . ".jpg";    #
            my $new_dest = $processing_dir . "/" . $newname;

            # use temp name for mogrify/ghostscript
            File::Copy::copy( $dest_name, $tempname )
              || die "Can't copy file $basename to $tempname";

            if ( (`mogrify -format jpg '$tempname'`) ) {
                die "Sorry, can't convert image $basename";
            }

            File::Copy::copy( $mogrified_first_image, $new_dest )
              || die "Can't copy file $mogrified_first_image to $newname";

        }
        #print STDERR "Successfully converted $basename to $newname\n";
        $basename = $newname;

        #	};

        #	  if ($@) {
        #	      return -2;
        #	  }

    }         #Multi-page non-image file eg: pdf, ps, eps
    else {    # appears to be a regular simple image

        #	eval {
        my $newname = "";

        if ( !(`mogrify -format jpg '$dest_name'`) ) {
            # has no jpg extension
	    if ($file_ext !~ /jpg|jpeg/i) {
                $newname = $original_filename . ".JPG";    # convert it to extention .JPG
		#print STDERR "NEWNAME = $newname\n\n";
            }
            # has no extension at all
	    elsif (!$file_ext) {
                $newname = $original_filename . ".JPG";         # add an extension .JPG
            }
            else {
                $newname = $original_filename.".JPG"; # add standard JPG file extension.
            }

	    #print STDERR "converting $processing_dir/$basename to $processing_dir/$newname...\n";
            if (

                system(
                    "/usr/bin/convert", "$processing_dir/$basename$file_ext",
                    "$processing_dir/$newname"
                ) != 0
              )
            {
                die "Sorry, can't convert image $basename$file_ext to $newname";
            }

            #print STDERR "Successfully converted $basename to $newname\n";
            $original_filename = $newname;
            $basename          = $newname;
        }
    }

    # create large image
    $self->copy_image_resize(
        "$processing_dir/$basename",
        $self->get_processing_dir() . "/large.jpg",
        $self->get_image_size("large")
    );

    # create midsize images
    $self->copy_image_resize(
        "$processing_dir/$basename",
        $self->get_processing_dir() . "/medium.jpg",
        $self->get_image_size("medium")
    );

    # create small image
    $self->copy_image_resize(
        "$processing_dir/$basename",
        $self->get_processing_dir() . "/small.jpg",
        $self->get_image_size("small")
    );

    # create thumbnail
    $self->copy_image_resize(
        "$processing_dir/$basename",
        $self->get_processing_dir() . "/thumbnail.jpg",
        $self->get_image_size("thumbnail")
    );

    # enter preliminary image data into database
    #$tag_table->insert_image($experiment_id, $unix_file, ${safe_ext});
    #
    my $ext = "";
    if ( $original_filename =~ /(.*)(\.\S{1,4})$/ ) {
        $original_filename = $1;
        $ext               = $2;
    }

    $self->set_original_filename($original_filename);
    $self->set_file_ext($file_ext); # this is the original file

    # start transaction, store the image object, and associate it to
    # the given type and type_id.
    my $image_id = 0;

    # move the image into the md5sum subdirectory
    #
    my $original_file_path = $self->get_processing_dir()."/".$self->get_original_filename().$self->get_file_ext();


    my $md5sum = $self->calculate_md5sum($original_file_path);
    $self->set_md5sum($md5sum);

    $self->make_dirs();

    $self->finalize_location($processing_dir);

    $self->set_image_id($image_id);

    $self->store();

    return $image_id;

}

=head2 make_dirs

 Usage:
 Desc:         creates the directory structure for image from
               image_dir onwards (a split md5sum)
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub make_dirs {
    my $self = shift;
    my $image_sub_path = $self->image_subpath();

    my $path = File::Spec->catdir( $self->get_image_dir(), $image_sub_path );
    if (my $dirs = make_path($path) ) {
	#print STDERR  "Created $dirs Dirs (should be 4)\n";
    }
}


=head2 finalize_location

 Usage:
 Desc:
 Ret:
 Args:          the source location as a path to a dir
 Side Effects:
 Example:

=cut

sub finalize_location {
    my $self = shift;
    my $processing_dir = shift;

    my $image_dir = File::Spec->catdir( $self->get_image_dir, $self->image_subpath );
    foreach my $f (glob($processing_dir."/*")) {

	File::Copy::move( $f, $image_dir )
	    || die "Couldn't move temp dir to image dir ($f, $image_dir)";
	#print STDERR "Moved image file $f to final location $image_dir...\n";

    }

    rmdir $processing_dir;

}

# used for migration

sub copy_location {
    my $self = shift;
    my $source_dir = shift;

    my $image_dir = $self->get_image_dir() ."/".$self->image_subpath();
    foreach my $f (glob($source_dir."/*")) {
	if (! -e $f) {
	    print STDERR "$f does not exist... moving on...\n";
	    return;
	}
	File::Copy::copy( "$f", "$image_dir/" )
	    || die "Couldn't move temp dir to image dir ($f, $image_dir). $!";
	#print STDERR "Moved image file $f to final location $image_dir...\n";

    }

}


=head2 image_subpath

 Usage:
 Desc:          returns the image subpath, which is a md5sum on an image file,
                divided into 16 directory levels at 2 bytes length each.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub image_subpath {
    my $self = shift;

    my $md5sum = $self->get_md5sum
        or confess 'cannot calculate image_subpath, no md5sum!';

    return join '/', $md5sum =~ /^(..)(..)(..)(..)(.+)$/;
}

=head2 calculate_md5sum

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub calculate_md5sum {
    my $self = shift;
    my $file = shift;

    open (my $F, "<", $file) || confess "Can't open $file ";
    binmode($F);
    my $md5 = Digest::MD5->new();
    $md5->addfile($F);
    close($F);

    my $md5sum = $md5->hexdigest();
    $md5->reset();

    return $md5sum;
}

sub copy_image_resize {
    my $self = shift;
    my ( $original_image, $new_image, $width ) = @_;

    # first copy the file
    my $copy = "cp '$original_image' '$new_image'";

    #print STDERR "COPYING: $copy\n";
    #system($copy);
    File::Copy::copy( $original_image, $new_image );
    my $chmod = "chmod 664 '$new_image'";

    #    print STDERR "CHMODing: $chmod\n";
    #system($chmod);
    #my $chown = "chown www-data:www-data '$new_image'";

    #   print STDERR "CHOWNing: $chown\n";
    #system($chown);

    # now resize the new file, and ensure it is a jpeg
    my $resize = `mogrify -format jpg -geometry $width '$new_image'`;

}


=head2 get_image_size_hash

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_image_size_hash {
    my $self = shift;
    return my %hash = (
        large     => $LARGE_IMAGE_SIZE,
        medium    => $MEDIUM_IMAGE_SIZE,
        small     => $SMALL_IMAGE_SIZE,
        thumbnail => $THUMBNAIL_IMAGE_SIZE,
    );
}

=head2 get_image_size

 Usage:
 Desc:
 Ret:
 Args:         "large" | "medium" | "small" | "thumbnail"
               default is medium
 Side Effects:
 Example:

=cut

sub get_image_size {
    my $self = shift;
    my $size = shift;
    my %hash = $self->get_image_size_hash();
    if ( exists( $hash{$size} ) ) {
        return $hash{$size};
    }

    # default
    #
    return $MEDIUM_IMAGE_SIZE;
}


=head2 get_filename

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_filename {
    my $self = shift;
    my $size = shift;
    my $type = shift || ''; # full or partial

    my $image_dir = "";
    if ($type eq 'partial') {
	$image_dir = $self->image_subpath();
    }
    else {
	$image_dir = $self->get_image_dir()."/".$self->image_subpath();
    }
    if ($size eq "thumbnail") {
	return File::Spec->catfile($image_dir, 'thumbnail.jpg');
    }
    if ($size eq "small") {
	return File::Spec->catfile($image_dir, 'small.jpg');
    }
    if ($size eq "large") {
	return File::Spec->catfile($image_dir, 'large.jpg');
    }
    if ($size eq "original") {
	return File::Spec->catfile($image_dir, $self->get_original_filename().$self->get_file_ext());
    }
    if ($size eq "original_converted") {
	return File::Spec->catfile($image_dir, $self->get_original_filename().".JPG");
    }
    return File::Spec->catfile($image_dir, 'medium.jpg');
}



=head2 get_processing_dir

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_processing_dir {
    my $self = shift;
    return $self->{processing_dir};

}

sub set_processing_dir {
    my $self = shift;
    $self->{processing_dir} = shift;
}


=head2 function get_copyright, set_copyright

  Synopsis:	$copyright = $image->get_copyright();
                $image->set_copyright("Copyright (c) 2001 by Picasso");
  Arguments:	getter: the copyright information string
  Returns:	setter: the copyright information string
  Side effects:	will be stored in the database in the copyright column.
  Description:

=cut

sub get_copyright {
    my $self = shift;
    return $self->{copyright};
}

sub set_copyright {
    my $self = shift;
    $self->{copyright} = shift;
}

=head2 accessors get_md5sum, set_md5sum

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_md5sum {
  my $self = shift;
  return $self->{md5sum};
}

sub set_md5sum {
  my $self = shift;
  $self->{md5sum} = shift;
}


=head2 iconify_file

Usage:   Iconify_file ($filename)
Desc:    This is used only for PDF, PS and EPS files during Upload processing to produce a thumbnail image
         for these filetypes for the CONFIRM screen.  Results end up on disk but are not used other than to t
	 produce the thumbnail
Ret:
Args:    Full Filename of PDF file
Side Effects:
Example:

=cut

sub iconify_file {
    my $file_name = shift;

    my $basename = File::Basename::basename($file_name);

    my $self = SGN::Context->new()
      ;    # merely used to retrieve correct temp dir on this host
    my $temp_dir =
        $self->get_conf("basepath") . "/"
      . $self->get_conf("tempfiles_subdir")
      . "/temp_images";

    my @image_pages = `/usr/bin/identify $file_name`;

    my $mogrified_image;
    my $newname;
    if ( $basename =~ /(.*)\.(.{1,4})$/ )
    {      #note; mogrify will create files name
            # basename-0.jpg, basename-1.jpg
        if ( $#image_pages > 0 ) {    # multipage, pdf, ps or eps
            $mogrified_image = $temp_dir . "/temp-0.jpg";
        }
        else {
            $mogrified_image = $temp_dir . "/temp.jpg";
        }
        my $tempname = $temp_dir . "/temp." . $2;    # retrieve file extension
        $newname = $basename . ".jpg";               #
        my $new_dest = $temp_dir . "/" . $newname;

        # use temp name for mogrify/ghostscript
        File::Copy::copy( $file_name, $tempname )
          || die "Can't copy file $basename to $tempname";

        if ( (`mogrify -format jpg '$tempname'`) ) {
            die "Sorry, can't convert image $basename";
        }

        File::Copy::copy( $mogrified_image, $new_dest )
          || die "Can't copy file $mogrified_image to $newname";

    }
    return;
}


=head2 hard_delete

 Usage:        $image->hard_delete()
 Desc:         "hard" deletes the image.
               NEVER USE THIS FUNCTION!
 Ret:          nothing
 Args:         none
 Side Effects: completely removes all the traces of this image.
 Example:      to be used in testing scripts only. Deletion should be
               implemented using the 'obsolete' flag.

=cut

sub hard_delete {
    my $self = shift;

    if ($self->pointer_count() < 2) {
	foreach my $size ('original', 'thumbnail', 'small', 'medium', 'large') {
	    my $filename = $self->get_filename($size);
	    unlink $filename;
	}
    }

    eval {

        $self->get_dbh->do( <<'', undef, $self->get_image_id );
DELETE from md_image WHERE image_id = ?

    };
    if ($@) {
	warn "Probably insufficient privileges to remove images from db table.";
    }


}

=head2 pointer_count

 Usage: print $image->pointer_count." db rows reference this image"
 Desc: get a count of how many rows in the db refer to the same image file
 Ret: integer number
 Args: none
 Side Effects: queries the db

=cut

sub pointer_count {
    my ($self) = @_;

    return $self->get_dbh->selectrow_array( <<'', undef, $self->get_md5sum );
SELECT count( distinct( image_id ) ) from md_image WHERE md5sum=?

}


=head2 add_tag

 Usage:        $self->add_tag($tag)
 Desc:         adds a tag to the image
 Ret:          database id
 Args:         a tag object (CXGN::Tag).
 Side Effects: the tag is immediately store in the database.
               there is no need to call store() on the image object.
 Example:

=cut

sub add_tag {
    my $self = shift;
    my $tag = shift;

    my $query = "INSERT INTO metadata.md_tag_image (tag_id, image_id) values (?, ?)";

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($tag->get_tag_id(), $self->get_image_id());
    my $id= $self->get_currval("metadata.md_tag_image_tag_image_id_seq");
    return $id;
}

=head2 get_tags

 Usage:        my @tags = $image->get_tags();
 Desc:         gets all the tags associated with this image object
 Ret:
 Args:
 Side Effects: the tags are being fetched from the database. The image
               object does not 'buffer' tag associations (see also add_tag()).
 Example:

=cut

sub get_tags {
    my $self  = shift;

    my $query = "SELECT tag_id FROM metadata.md_tag_image WHERE image_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_image_id());
    my @tags;
    while (my ($tag_id) = $sth->fetchrow_array()) {
	push @tags, CXGN::Tag->new($self->get_dbh(), $tag_id);
    }
    return @tags;
}

=head2 remove_tag

 Usage:        $self->remove_tag($tag)
 Desc:         Delete a tag_image association
 Ret:          nothing
 Args:         a tag object.
 Side Effects: the association to the tag object will be removed
               directly accessing the database backstore. There is no
               need to call store() after remove_tag(). The tag itself
               is not affected.
 Example:

=cut

sub remove_tag {
    my $self = shift;
    my $tag = shift;
    my $query = "DELETE FROM metadata.md_tag_image WHERE tag_id=? and image_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($tag->get_tag_id(), $self->get_image_id());
}


=head2 exists_tag_image_named

 Usage: CXGN::Image::exists_tag_image_named($dbh, $tag_id, $image_id)
 Desc:  Check if a tag is already associated with an image
 Ret:   a database id or undef
 Args:  dbh, tag_id, image_id
 Side Effects: none
 Example:

=cut

sub exists_tag_image_named {
    my $dbh = shift;
    my $tag_id = shift;
    my $image_id=shift;
    my $query = "SELECT tag_image_id
                   FROM metadata.md_tag_image
                  WHERE tag_id= ? AND image_id= ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($tag_id, $image_id);
    if (my ($id)=$sth->fetchrow_array()) {
	return $id;
    }
    else {
	return 0;
    }
}




=head2 create_schema

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut



sub create_schema {
    my $self = shift;

    $self->get_dbh()->do(
                     "CREATE table metadata.md_image (
                                                image_id serial primary key,
                                                name varchar(100),
                                                description text,
                                                original_filename varchar(100),
                                                file_ext varchar(20),
                                                sp_person_id bigint REFERENCES sgn_people.sp_person,
                                                modified_date timestamp with time zone,
                                                create_date timestamp with time zone,
                                                md5sum text,
                                                obsolete boolean default false
                                                )");

    $self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT, DELETE ON metadata.md_image TO web_usr");
    $self->get_dbh()->do("GRANT select, update ON metadata.md_image_image_id_seq TO web_usr");

    $self->get_dbh()->do(
                     "CREATE table phenome.individual_image (
                                                individual_image_id serial primary key,
                                                image_id bigint references metadata.md_image,
                                                individual_id bigint references phenome.individual,
                                                obsolete boolean DEFAULT 'false',
                                                sp_person_id integer REFERENCES sgn_people.sp_person(sp_person_id),
                                                create_date timestamp with time zone DEFAULT now(),
                                                modified_date timestamp with time zone
                   )");

    $self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON phenome.individual_image TO web_usr");
    $self->get_dbh()->do("GRANT select, update ON phenome.individual_image_individual_image_id_seq TO web_usr");

    $self->get_dbh()->do(
        "CREATE table phenome.locus_image (
                                                locus_image_id serial primary key,
                                                image_id bigint references metadata.md_image,
                                                locus_id bigint references phenome.locus,
                                                obsolete boolean DEFAULT 'false',
                                                sp_person_id integer REFERENCES sgn_people.sp_person(sp_person_id),
                                                create_date timestamp with time zone DEFAULT now(),
                                                modified_date timestamp with time zone
                   )");

    $self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON phenome.locus_image TO web_usr");
    $self->get_dbh()->do("GRANT select, update ON phenome.locus_image_locus_image_id_seq TO web_usr");


    $self->get_dbh()->do(
                     "CREATE table insitu.experiment_image (
                                                 experiment_image_id serial primary key,
                                                 image_id bigint references metadata.md_image,
                                                 experiment_id bigint references insitu.experiment,
                                                  obsolete boolean DEFAULT 'false',
                                                sp_person_id integer REFERENCES sgn_people.sp_person(sp_person_id),
                                                create_date timestamp with time zone DEFAULT now(),
                                                modified_date timestamp with time zone
                  )");

    $self->get_dbh()->do ("GRANT SELECT, UPDATE, INSERT ON insitu.experiment_image TO web_usr");
    $self->get_dbh()->do ("GRANT select, update ON insitu.experiment_image_experiment_image_id_seq TO web_usr");

    $self->get_dbh()->do ("CREATE table sgn.fish_result_image (
                                                  fish_result_image_id serial primary key,
                                                  image_id bigint references metadata.md_image,
                                                  fish_result_id bigint references sgn.fish_result
                    )");
    $self->get_dbh()->do ("GRANT SELECT ON sgn.fish_result_image TO web_usr");
    $self->get_dbh()->do ("GRANT select ON sgn.fish_result_image_fish_result_image_id_seq TO web_usr");
    # we don't grant access to webusr for image_fish_result because as of now users cannot submit
    # these image directly themselves.

    print STDERR "Schemas created.\n";
}

###########
1;#########
###########
