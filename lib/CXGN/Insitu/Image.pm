package CXGN::Insitu::Image;

=head1 NAME

Image.pm - a class to deal with insitu images.

=head1 DESCRIPTION

This class provides database access and store functions as well as image upload and certain image manipulation functions, such as image file type conversion and image resizing; and functions to associate tags with the image.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 MEMBER FUNCTIONS

The following functions are provided in this class:

=cut


use strict;
use warnings;
use CXGN::Insitu::DB;
use CXGN::Insitu::Tag;
use SGN::Context;

use base qw / CXGN::Insitu::DB / ;


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
    my $dbh=shift;
    my $id = shift;
    my $self = $class ->SUPER::new($dbh);
    
    $self->set_configuration_object(SGN::Context->new());

    if ($id) { 
	$self->set_image_id($id);
	$self->fetch_image();
    }
    return $self;
}

sub fetch_image { 
    my $self = shift;
    my $query = "SELECT experiment_id,
                        name, 
                        description,
                        filename,
                        file_ext,
                        user_id
                 FROM   insitu.image
                 WHERE  insitu.image.image_id=?";

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_image_id()) ;

    my ($experiment_id, $name, $description, $filename, $file_ext, $user_id) =
	$sth->fetchrow_array();

    #print STDERR "fetched image: image_id ".($self->get_image_id())." experiment_id = $experiment_id.\n";

    $self->set_experiment_id($experiment_id);
    $self->set_name($name);
    $self->set_description($description);
    $self->set_filename($filename);
    $self->set_file_ext($file_ext);
    $self->set_user_id($user_id);

}

sub store { 
    my $self = shift;
    if ($self->get_image_id()) { 
	
	# it's an update
	#
	my $query = "UPDATE insitu.image SET 
                            experiment_id=?,
                            name=?,
                            description=?,
                            filename=?,
                            file_ext=?,
                            user_id =?
                      WHERE insitu.image.image_id=?";

	my $sth = $self->get_dbh()->prepare($query);

	$sth->execute(
		      $self->get_experiment_id(),
		      $self->get_name(),
		      $self->get_description(),
		      $self->get_filename(),
		      $self->get_file_ext(),
		      $self->get_user_id(),
		      $self->get_image_id()
		      );
	return $self->get_image_id();
    }
    else { 
	
	# it is an insert
	#
	my $query = "INSERT INTO insitu.image (
                            experiment_id,
                            name,
                            description,
                            filename,
                            file_ext,
                            user_id)
                     VALUES (?, ?, ?, ?, ?, ?)";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute( 
		       $self->get_experiment_id(),
		       $self->get_name(),
		       $self->get_description(),
		       $self->get_filename(),
		       $self->get_file_ext(),
		       $self->get_user_id()
		       );

	$self->set_image_id($self->get_dbh()->last_insert_id("image"));
	return $self->get_image_id();
    }
}

=head2 delete

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub delete {
    my $self = shift;
    if ($self->get_image_id()) { 
	my $query = "UPDATE insitu.image set obsolete='t' WHERE image_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_image_id());
    }
    else { 
	print STDERR "Image.pm: Trying to delete an image from the db that has not yet been stored.";
    }
    
}




=head2 get_image_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_image_id {
  my $self=shift;
  return $self->{image_id};

}

=head2 set_image_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_image_id {
  my $self=shift;
  $self->{image_id}=shift;
}

=head2 get_experiment_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_experiment_id {
  my $self=shift;
  return $self->{experiment_id};

}

=head2 set_experiment_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_experiment_id {
  my $self=shift;
  $self->{experiment_id}=shift;
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

=head2 get_description

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_description {
  my $self=shift;
  return $self->{description};

}

=head2 set_description

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_description {
  my $self=shift;
  $self->{description}=shift;
}


=head2 get_user_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_user_id {
    my $self=shift;
    return $self->{user_id};

}

=head2 set_user_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_user_id {
    my $self=shift;
    $self->{user_id}=shift;
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
  my $self=shift;
  return $self->{filename};
}

=head2 set_filename

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_filename {
  my $self=shift;
  $self->{filename}=shift;
}

=head2 get_file_ext

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_file_ext {
  my $self=shift;
  return $self->{file_ext};

}

=head2 set_file_ext

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_file_ext {
  my $self=shift;
  $self->{file_ext}=shift;
}

=head2 add_tag

 Usage:
 Desc:         adds a tag to the image
 Ret:          nothing
 Args:         a tag object (CXGN::Insitu::Tag).
 Side Effects: the tag is immediately store in the database.
               there is no need to call store() on the image object.
 Example:

=cut

sub add_tag { 
    my $self = shift;
    my $tag = shift;

    my $query = "INSERT INTO insitu.image_tag (tag_id, image_id) values (?, ?)";
    
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($tag->get_tag_id(), $self->get_image_id());
    
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
    
    my $query = "SELECT tag_id FROM insitu.image_tag WHERE image_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_image_id());
    my @tags = ();
    while (my ($tag_id) = $sth->fetchrow_array()) { 
	push @tags, CXGN::Insitu::Tag->new($self->get_dbh(), $tag_id);
    }
    return @tags;
}

=head2 remove_tag

 Usage:
 Desc:
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
    my $query = "DELETE FROM insitu.image_tag WHERE tag_id=? and image_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($tag->get_tag_id(), $self->get_image_id());
}

=head2 get_large_suffix

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_large_suffix { 
    my $self = shift;
    return "_mid";
}

=head2 get_thumb_suffix

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_thumb_suffix {
    my $self = shift;
    return "_thumb";
}



=head2 get_large_size

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_large_size {
    my $self = shift;
    return 600;
}

=head2 get_thumb_size

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_thumb_size {
    my $self=shift;
    return 200;
}



=head2 get_fullsize_dir

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_fullsize_dir { 
    my $self = shift;
    my $fullsize_dir = $self->get_configuration_object()->get_conf("insitu_fullsize_dir");
    $fullsize_dir =~ s|/+$||;
    return $fullsize_dir."/".$self->get_experiment_id();
}


=head2 get_display_dir

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:
 To do:        should get info through conf object

=cut

sub get_display_dir { 
    my $self = shift;
    # directory this script will move  shrunken images to
    my $display_dir = SGN::Context->new->get_conf("insitu_display_dir");
    $display_dir =~ s|/+$||;
    return $display_dir."/".$self->get_experiment_id();
}

=head2 get_input_dir

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:
 To do:        should get info through conf object
=cut

sub get_input_dir { 
    my $self = shift;
    my $input_dir = SGN::Context->new->get_conf("insitu_input_dir");
    $input_dir =~ s|/+$||;
    return $input_dir;
}


=head2 get_thumbnail_url

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_thumbnail_url { 
    my $self = shift;
    return $self->get_configuration_object()->get_conf("insitu_display_url")."/".$self->get_experiment_id()."/".$self->get_filename()."_".$self->get_large_suffix().".jpg";
}


=head2 get_fullsize_url

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_fullsize_url { 
    my $self = shift;
    return $self->get_configuration_object()->get_conf("insitu_fullsize_url")."/".$self->get_experiment_id()."/".$self->get_filename().$self->get_file_ext();
}


=head2 get_configuration_object

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_configuration_object {
  my $self=shift;
  return $self->{configuration_object};
}

=head2 set_configuration_object

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_configuration_object {
  my $self=shift;
  $self->{configuration_object}=shift;
}



=head2 get_img_src_tag

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_img_src_tag { 
    my $self = shift;
    return "<img src=\"".$self->get_thumbnail_url()."\" border=\"0\" width=".$self->get_thumb_size()." /> ";
}

=head2 get_temp_filename

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_temp_filename {
  my $self=shift;
  return $self->{temp_filename};

}

=head2 set_temp_filename

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_temp_filename {
  my $self=shift;
  $self->{temp_filename}=shift;
}

sub upload_image { 
    my $self = shift;
    my $experiment = shift;
    my $uploaded_filename=shift;
    my $uploaded_filehandle = shift;
    
    my $error = 0;
    
    # if an image file has been uploaded, copy it to a temporary
    # location    
    # get remote file name, make it safe, keep it sane
    #
    $uploaded_filename =~ s/.*[\/\\](.*)/$1/;
    
    # generate local file name, including IP and time, to make sure
    # multiple uploads don't clobber each other
    #
    #my $date = `strftime "\%Y-\%m-\%d", gmtime`;
    my $create_time = time();
    $uploaded_filename = $self->get_input_dir()."/" . $ENV{REMOTE_ADDR} . "_${create_time}_${uploaded_filename}";
    warn "Uploaded_filename=$uploaded_filename\n";
    
    $self->set_temp_filename($uploaded_filename);

    #my $uploaded_filehandle = $query->upload('e_file');
    
    # only copy file if it doesn't already exist
    #
    if (!-e $uploaded_filename) {
	
	# open a filehandle for the uploaded file
	#
	if (!$uploaded_filehandle) {
	    return 1;
	}
	else {	
	    # copy said file to destination, line by line
	    warn "Now uploading file...\n";
	    open UPLOADFILE, ">$uploaded_filename" or die "Could not write to ${uploaded_filename}: $!\n";
	    warn "could open filename...\n";
	    binmode UPLOADFILE;
	    while (<$uploaded_filehandle>) {
		#warn "Read another chunk...\n";
		print UPLOADFILE;
	    }
	    close UPLOADFILE;
	    warn "Done uploading...\n";
	}
    }
    else {
	print STDERR "$uploaded_filename exists, not overwriting...\n";
    }   
}

=head2 process_image

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub process_image { 
    my $self = shift;
    my $file_name = shift;
    my $experiment = shift;
    
    my $experiment_id=$experiment->get_experiment_id();
    if (!$experiment_id) { die "Need an experiment id!\n"; }

    # create subdirectories for these images to live in
    #
    my $fullsize_dir = $self->get_fullsize_dir();
    my $display_dir = $self->get_display_dir();
    
    # these commands shouldn't do any harm if these directories already exist
    #
    if (! -d '$fullsize_dir' ) { 
	system("mkdir '$fullsize_dir'" );
	system("chmod 775 '$fullsize_dir'");
    }

    if (! -d '$display_dir') { 
	system("mkdir '$display_dir'");
	system("chmod 775 '$display_dir'");
    }

    
    # process image
    #
    my ($safe_file, $safe_ext, $unix_file);
    $safe_file = $file_name;
    $safe_file =~ m/(.*)(\.[a-zA-Z0-9]{3,4})$/i;
    $safe_file = $1;
    $safe_ext = $2;
    $unix_file = $safe_file;
    $unix_file =~ s/\s/_/g;
    
    my $input_dir = $self->get_input_dir();
    my $large_suffix = $self->get_large_suffix();
    my $thumb_suffix = $self->get_thumb_suffix();
    my $large_size = $self->get_large_size();
    my $thumb_size = $self->get_thumb_size();
    # copy unmodified image to be fullsize image
    #
    my $temp_filename = $self->get_temp_filename();
    my $mv = "mv '$temp_filename' '${fullsize_dir}/${unix_file}${safe_ext}'";
    print STDERR "MOVING FILE $mv\n";
    system($mv);
    my $chmod = "chmod 664 '${fullsize_dir}/${unix_file}${safe_ext}'";
    print STDERR "CHMODing FILE: $chmod\n";
    system($chmod);
    
    # convert to jpg if format is different
    if ($safe_ext !~ /jpg|jpeg/i) {
	system("convert ${fullsize_dir}/${unix_file}${safe_ext} ${fullsize_dir}/${unix_file}.jpg");
	$safe_ext = ".jpg";
    }
    
    # create small thumbnail for each image
    $self->copy_image_resize("${fullsize_dir}/${unix_file}${safe_ext}", "${display_dir}/${unix_file}_${thumb_suffix}.jpg", "$thumb_size");
    
    # create midsize image for each image
    $self->copy_image_resize("${fullsize_dir}/${unix_file}${safe_ext}", "${display_dir}/${unix_file}_${large_suffix}.jpg", "$large_size");
    
    # enter preliminary image data into database
    #$tag_table->insert_image($experiment_id, $unix_file, ${safe_ext});	
    $self -> set_filename($unix_file);
    $self -> set_file_ext($safe_ext);
    $self -> store();
    
}

sub copy_image_resize {
    my $self=shift;
    my ($original_image, $new_image, $width) = @_;
    
    #$debug and warn "\tCopying $original_image to $new_image and resizing it to $width px wide\n";
    
    # first copy the file
    my $copy = "cp '$original_image' '$new_image'";
    print STDERR "COPYING: $copy\n";
    system($copy);
    my $chmod = "chmod 664 '$new_image'";
    print STDERR "CHMODing: $chmod\n";
    system($chmod);
    
    # now resize the new file, and ensure it is a jpeg
    my $resize = `mogrify -geometry $width '$new_image'`;
    my $jpeg = `mogrify -format jpg '$new_image'`;
    
    if ($resize || $jpeg) {
	return 0;
    }
    else {
	return 1;
    }
    
}



# sub as_html { 
#     my $self = shift;
#     my $image_id = $self->get_image_id();
#     my $experiment_id = $self->get_experiment_id();
#     my $filename = $self->get_filename();
#     my $description = $self->get_description();
#     my $name = $self->get_name();
#     my $file_ext= $self->get_file_ext();
#     my $large_suffix = $self->get_large_suffix();
#     my $large_size = $self->get_large_size();
#     my @tags = $self->get_tags();
#     my $categories = "CATEGORIES GO HERE";
#     my $output = "";

#     my $thumbnail = $self->get_display_dir()."/thumbnail_images/$experiment_id/$filename.jpg";
#     my $fullsize = $self->get_fullsize_dir()."/fullsize_images/$experiment_id/$filename$file_ext";

#     print <<HTML;

# <center>
# <a href="/thumbnail_images/$experiment_id/$filename.jpg" onclick="javascript: window.open('/fullsize_images/$experiment_id/$filename$file_ext', 'blank', 'toolbar=no'); return false;"><img src="/thumbnail_images/$experiment_id/$filename\_$large_suffix.jpg" border="0" width="$large_size" alt="image id: $image_id" /></a><br /><em>$filename</em></center>

# HTML
    
#     #print $thumbnail;
#     #print $fullsize;
    
#    $output .= "<hr noshade=\"noshade\" />\n\n";
    
#     # generate table showing additional information for this image
#     if ($name || $description || @tags>0) {
# 	$output .= <<IMAGE_INFO;
# 	<center><table border="0" cellpadding="0" cellspacing="0" width="90%">
# 	    <tr>
# 	    <th class="fielddef" style="text-align:center" colspan="2">Image Info</td>
# 	    </tr>
# IMAGE_INFO
# 	    if ($name) {
# 		$output .= <<IMAGE_NAME;
# 		<tr>
# 		    <td class="fielddef">Name</td>
# 		    <td class="fieldinput">$name</td>
# 		    </tr>
# IMAGE_NAME
# 		}
# 	if ($description) {
# 	    $output .= <<IMAGE_DESC;
# 	    <tr>
# 		<td class="fielddef">Description</td>
# 		<td class="fieldinput">$description</td>
# 		</td>
# IMAGE_DESC
# 	    }
# 	if (@tags>0) {
	    # first make sure to kill any redundancy with the experiment tags
	    # 	my %expr_tags = $tag_table->return_relevant_tags("ex", $image{experiment_id});
# 			my %new_image_tags = ();
# 			foreach my $img_tag (keys %{$image{tags}}) {
# 				if (!$expr_tags{$img_tag}) {
# 					($debug>1) and warn "setting tag $img_tag for image\n";
# 					$new_image_tags{$img_tag} = $image{tags}{$img_tag};
# 				}
# 				else {
# 					($debug>1) and warn "tag $img_tag is set for both experiment and image!\n";
# 				}	
# 			}
# 			my $categories = get_tag_links(\%new_image_tags);
# 			(keys(%new_image_tags)>0) and $output .= <<IMAGE_TAGS;
	    
	    
# <tr>
# 	<td class="fielddef">Categories</td>
# 	<td class="fieldinput">$categories</td>
# </tr>
# IMAGE_TAGS
# 		}
# 		$output .= "</table></center>\n";
# 		$output .= "<hr noshade=\"noshade\" />\n\n";
# 	}
	    
# 	# generate table showing information about this experiment
# 	#$output .= get_experiment_string($image{experiment_id});
	    
# 	    print $output;
# 	}
#     }
# }


return 1;
