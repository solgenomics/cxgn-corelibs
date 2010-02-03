=head1 NAME

CXGN::TomatoGenome::Config - config object for the tomato genome.  See L<CXGN::Config>.

=head1 SYNOPSIS

  my $cfg = CXGN::TomatoGenome::Config->load;

  # loads:
  #  - defaults in CXGN::Config
  #  - defaults in CXGN::TomatoGenome::Config
  #  - conf in /etc/cxgn/Global.conf
  #  - conf in /etc/cxgn/TomatoGenome.conf
  # with later sources overriding previous ones


=cut

package CXGN::TomatoGenome::Config;
use base qw/CXGN::Genomic::Config/;

# use TomatoGenome.conf instead of CXGN.conf, which would be the
# default
sub _conf_name { 'TomatoGenome' }

my $defaults =
  {

   dbsearchpath             => [qw[
                                   public
                                   genomic
                                   sgn
                                   metadata
                                   sgn_people
                               ]],

   # bac pipeline variables
   # bac_publish_subdir is relative to ftpsite_root
   bac_publish_subdir       => 'tomato_genome/bacs',
   country_uploads_path     => '/data/shared/tomato_genome/country_uploads',
   bac_pipeline_dir         => '/data/shared/tomato_genome/bacpipeline',
   bac_validation_cache     => 'validation_cache', #< dirname relative to bac_pipeline_dir
   bac_job_logs_dir         => 'job_logs', #< dirname relative to bac pipeline dir
   bac_genbank_dir          => 'genbank_submit', #< dirname relative to bac pipeline dir

   # contact information for the tomato genome project
   bac_contacts_chr_1       => ['Robert Buels <rmb32@cornell.edu>'],
   bac_contacts_chr_2       => ['JungEun Kim <jekim@kribb.re.kr>'],
   bac_contacts_chr_3       => ['Gong Xiao <gongxiaobio@gmail.com>',
                                'Jianfeng Ren <renjianfeng@genetics.ac.cn>',
                                'Li Chuanyou <cyli@genetics.ac.cn>',
                               ],
   bac_contacts_chr_4       => 'James Abbott <j.abbott@imperial.ac.uk>',
   bac_contacts_chr_5       => ['Saloni Mathur <saloni@genomeindia.org>',
                                'Ajay Kumar Mahato <ajay@nrcpb.org>',
                               ],
   bac_contacts_chr_6       => 'Erwin Datema <Erwin.Datema@wur.nl>',
   bac_contacts_chr_7       => ['Mohamed Zouine <mohamed.zouine@ensat.fr>',
                                'Tomato Team <tomatok7@ensat.fr>',
                               ],
   bac_contacts_chr_8       => 'Shusei Sato <ssato@kazusa.or.jp>',
   bac_contacts_chr_9       => 'Francisco Camara <FCamara@imim.es>',
   bac_contacts_chr_10      => 'Robert Buels <rmb32@cornell.edu>',
   bac_contacts_chr_11      => 'Zhonghua Zhang <zhangzhonghua.caas@gmail.com>',
   bac_contacts_chr_12      => 'Alessandro Vezzi <sandrin@cribi.unipd.it>',
   # unmapped chromosome
   bac_contacts_chr_0       => 'Robert Buels <rmb32@cornell.edu>',

   # agp_publish_subdir is relative to ftpsite_root
   agp_publish_subdir       => 'tomato_genome/agp',
   contigs_publish_subdir   => 'tomato_genome/contigs',
   bac_processing_log       => 'cxgn_bac_pipeline_processing_log', #< this is a database table
   bac_loading_log          => 'cxgn_bac_pipeline_loading_log', #< this is a database table
   genbank_upload_log       => 'cxgn_bac_pipeline_genbank_log', #< this is a database table

   #gbrowse stuff
   bacs_bio_db_gff_dbname   => 'bio_db_gff',
  };

sub defaults { shift->SUPER::defaults( $defaults, @_ )}
1;

