#!/usr/bin/perl
use strict;
use warnings;
use English;
use FindBin;

use Data::Dumper;

use Test::More tests => 3;

use Bio::FeatureIO;

BEGIN {
  use_ok(  'CXGN::TomatoGenome::ChromosomeAssemblies', qw/  named_contigs contig_features /  )
    or BAIL_OUT('could not include the module being tested');
}

my %parsed_contigs =
        (
          'C04.3_contig26' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 9973171,
                                  'cend' => 130660,
                                  'oend' => 10103830,
                                  'ident' => 'C04SLm0096K04.1',
                                  'length' => 130660,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '152',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 151
                                },
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 10103831,
                                  'cend' => 89292,
                                  'oend' => 10191122,
                                  'ident' => 'C04HBa0106F07.1',
                                  'length' => 87292,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '153',
                                  'cstart' => 2001,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 152
                                },
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 10191123,
                                  'cend' => 51696,
                                  'oend' => 10240818,
                                  'ident' => 'C04HBa0068N05.1',
                                  'length' => 49696,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '154',
                                  'cstart' => 2001,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 153
                                }
                              ],
          'C04.3_contig5' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1013674,
                                 'cend' => 124444,
                                 'oend' => 1138117,
                                 'ident' => 'C04SLm0132C12.1',
                                 'length' => 124444,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '17',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 16
                               }
                             ],
          'C04.3_contig19' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 6336490,
                                  'cend' => 88559,
                                  'oend' => 6423048,
                                  'ident' => 'C04HBa0080D03.1',
                                  'length' => 86559,
                                  'typedesc' => 'finished',
                                  'orient' => '-',
                                  'linenum' => '89',
                                  'cstart' => 2001,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 88
                                },
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 6423049,
                                  'cend' => 125450,
                                  'oend' => 6548498,
                                  'ident' => 'C04HBa0078E04.1',
                                  'length' => 125450,
                                  'typedesc' => 'finished',
                                  'orient' => '-',
                                  'linenum' => '90',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 89
                                }
                              ],
          'C04.2_contig6' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 3904294,
                                 'cend' => 125450,
                                 'oend' => 4029743,
                                 'ident' => 'C04HBa0078E04.1',
                                 'length' => 125450,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '66',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 66
                               },
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 4029744,
                                 'cend' => 88559,
                                 'oend' => 4116302,
                                 'ident' => 'C04HBa0080D03.1',
                                 'length' => 86559,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '67',
                                 'cstart' => 2001,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 67
                               }
                             ],
          'C04.3_contig17' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 5398452,
                                  'cend' => 118288,
                                  'oend' => 5516739,
                                  'ident' => 'C04HBa0029F16.1',
                                  'length' => 118288,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '74',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 73
                                }
                              ],
          'C04.3_contig21' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 7098171,
                                  'cend' => 117561,
                                  'oend' => 7215731,
                                  'ident' => 'C04HBa0132O11.1',
                                  'length' => 117561,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '100',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 99
                                }
                              ],
          'C04.3_contig9' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 2119131,
                                 'cend' => 85242,
                                 'oend' => 2204372,
                                 'ident' => 'C04HBa0024G05.1',
                                 'length' => 85242,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '31',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 30
                               },
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 2204373,
                                 'cend' => 128461,
                                 'oend' => 2330833,
                                 'ident' => 'C04HBa0020F17.1',
                                 'length' => 126461,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '32',
                                 'cstart' => 2001,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 31
                               }
                             ],
          'C04.3_contig2' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 226392,
                                 'cend' => 130732,
                                 'oend' => 357123,
                                 'ident' => 'C04HBa0190C13.1',
                                 'length' => 130732,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '4',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 4
                               }
                             ],
          'C04.2_contig8' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 4933864,
                                 'cend' => 129590,
                                 'oend' => 5063453,
                                 'ident' => 'C04SLm0129D14.1',
                                 'length' => 129590,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '83',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 83
                               }
                             ],
          'C04.1_contig6' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 2409441,
                                 'cend' => 125450,
                                 'oend' => 2534890,
                                 'ident' => 'C04HBa0078E04.1',
                                 'length' => 125450,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '38',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 38
                               }
                             ],
          'C04.2_contig3' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 2237497,
                                 'cend' => 141443,
                                 'oend' => 2378939,
                                 'ident' => 'C04HBa0308B07.2',
                                 'length' => 141443,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '41',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 41
                               }
                             ],
          'C04.3_contig10' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 2480834,
                                  'cend' => 153195,
                                  'oend' => 2634028,
                                  'ident' => 'C04HBa0203L19.1',
                                  'length' => 153195,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '36',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 35
                                }
                              ],
          'C04.2_contig9' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 5713454,
                                 'cend' => 130660,
                                 'oend' => 5844113,
                                 'ident' => 'C04SLm0096K04.1',
                                 'length' => 130660,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '97',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 97
                               }
                             ],
          'C04.3_contig11' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 2884029,
                                  'cend' => 117225,
                                  'oend' => 3001253,
                                  'ident' => 'C04HBa0114C15.1',
                                  'length' => 117225,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '42',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 41
                                },
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 3001254,
                                  'cend' => 128234,
                                  'oend' => 3127487,
                                  'ident' => 'C04SLm0143K21.1',
                                  'length' => 126234,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '43',
                                  'cstart' => 2001,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 42
                                }
                              ],
          'C04.1_contig3' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1342614,
                                 'cend' => 141473,
                                 'oend' => 1484086,
                                 'ident' => 'C04HBa0308B07.1',
                                 'length' => 141473,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '25',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 25
                               }
                             ],
          'C04.3_contig24' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 8400137,
                                  'cend' => 72462,
                                  'oend' => 8472598,
                                  'ident' => 'C04HBa0110L05.1',
                                  'length' => 72462,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '122',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 121
                                }
                              ],
          'C04.3_contig8' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1737070,
                                 'cend' => 28696,
                                 'oend' => 1765765,
                                 'ident' => 'C04HBa0114G11.1',
                                 'length' => 28696,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '26',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 25
                               },
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1765766,
                                 'cend' => 113641,
                                 'oend' => 1877406,
                                 'ident' => 'C04HBa0050I18.1',
                                 'length' => 111641,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '27',
                                 'cstart' => 2001,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 26
                               },
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1877407,
                                 'cend' => 114152,
                                 'oend' => 1989558,
                                 'ident' => 'C04HBa0036C23.1',
                                 'length' => 112152,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '28',
                                 'cstart' => 2001,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 27
                               },
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1989559,
                                 'cend' => 81572,
                                 'oend' => 2069130,
                                 'ident' => 'C04HBa0008H22.1',
                                 'length' => 79572,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '29',
                                 'cstart' => 2001,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 28
                               }
                             ],
          'C04.2_contig4' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 2428940,
                                 'cend' => 125040,
                                 'oend' => 2553979,
                                 'ident' => 'C04HBa0027G19.1',
                                 'length' => 125040,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '43',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 43
                               },
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 2553980,
                                 'cend' => 160432,
                                 'oend' => 2712411,
                                 'ident' => 'C04HBa0198L24.1',
                                 'length' => 158432,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '44',
                                 'cstart' => 2001,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 44
                               },
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 2712412,
                                 'cend' => 11681,
                                 'oend' => 2722092,
                                 'ident' => 'C04HBa0119A16.1',
                                 'length' => 9681,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '45',
                                 'cstart' => 2001,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 45
                               },
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 2722093,
                                 'cend' => 164164,
                                 'oend' => 2884256,
                                 'ident' => 'C04HBa0031H05.1',
                                 'length' => 162164,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '46',
                                 'cstart' => 2001,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 46
                               }
                             ],
          'C04.3_contig25' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 9622599,
                                  'cend' => 100572,
                                  'oend' => 9723170,
                                  'ident' => 'C04HBa0331L22.1',
                                  'length' => 100572,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '146',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 145
                                }
                              ],
          'C04.3_contig16' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 4670760,
                                  'cend' => 76058,
                                  'oend' => 4746817,
                                  'ident' => 'C04HBa0134D05.1',
                                  'length' => 76058,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '62',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 61
                                },
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 4746818,
                                  'cend' => 153634,
                                  'oend' => 4898451,
                                  'ident' => 'C04HBa0128G23.1',
                                  'length' => 151634,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '63',
                                  'cstart' => 2001,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 62
                                }
                              ],
          'C04.1_contig2' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 714153,
                                 'cend' => 128461,
                                 'oend' => 842613,
                                 'ident' => 'C04HBa0020F17.1',
                                 'length' => 128461,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '14',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 14
                               }
                             ],
          'C04.3_contig15' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 4384883,
                                  'cend' => 121324,
                                  'oend' => 4506206,
                                  'ident' => 'C04SLm0033N19.1',
                                  'length' => 121324,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '59',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 58
                                },
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 4506207,
                                  'cend' => 116553,
                                  'oend' => 4620759,
                                  'ident' => 'C04HBa0107M13.1',
                                  'length' => 114553,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '60',
                                  'cstart' => 2001,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 59
                                }
                              ],
          'C04.2_contig5' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 3584257,
                                 'cend' => 120037,
                                 'oend' => 3704293,
                                 'ident' => 'C04HBa0006E18.1',
                                 'length' => 120037,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '61',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 61
                               }
                             ],
          'C04.3_contig14' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 3829566,
                                  'cend' => 125040,
                                  'oend' => 3954605,
                                  'ident' => 'C04HBa0027G19.1',
                                  'length' => 125040,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '53',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 52
                                },
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 3954606,
                                  'cend' => 160432,
                                  'oend' => 4113037,
                                  'ident' => 'C04HBa0198L24.1',
                                  'length' => 158432,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '54',
                                  'cstart' => 2001,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 53
                                },
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 4113038,
                                  'cend' => 11681,
                                  'oend' => 4122718,
                                  'ident' => 'C04HBa0119A16.1',
                                  'length' => 9681,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '55',
                                  'cstart' => 2001,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 54
                                },
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 4122719,
                                  'cend' => 164164,
                                  'oend' => 4284882,
                                  'ident' => 'C04HBa0031H05.1',
                                  'length' => 162164,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '56',
                                  'cstart' => 2001,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 55
                                }
                              ],
          'C04.3_contig23' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 7972095,
                                  'cend' => 100452,
                                  'oend' => 8072546,
                                  'ident' => 'C04HBa0053M02.1',
                                  'length' => 100452,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '116',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 115
                                },
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 8072547,
                                  'cend' => 129590,
                                  'oend' => 8200136,
                                  'ident' => 'C04SLm0129D14.1',
                                  'length' => 127590,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '117',
                                  'cstart' => 2001,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 116
                                }
                              ],
          'C04.3_contig6' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1238118,
                                 'cend' => 169445,
                                 'oend' => 1407562,
                                 'ident' => 'C04HBa0049A17.1',
                                 'length' => 169445,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '20',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 19
                               }
                             ],
          'C04.2_contig1' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1000001,
                                 'cend' => 113641,
                                 'oend' => 1113641,
                                 'ident' => 'C04HBa0050I18.1',
                                 'length' => 113641,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '21',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 21
                               },
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1113642,
                                 'cend' => 114152,
                                 'oend' => 1225793,
                                 'ident' => 'C04HBa0036C23.1',
                                 'length' => 112152,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '22',
                                 'cstart' => 2001,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 22
                               }
                             ],
          'C04.2_contig2' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1325794,
                                 'cend' => 85242,
                                 'oend' => 1411035,
                                 'ident' => 'C04HBa0024G05.1',
                                 'length' => 85242,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '25',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 25
                               },
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1411036,
                                 'cend' => 128461,
                                 'oend' => 1537496,
                                 'ident' => 'C04HBa0020F17.1',
                                 'length' => 126461,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '26',
                                 'cstart' => 2001,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 26
                               }
                             ],
          'C04.3_contig13' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 3472176,
                                  'cend' => 117947,
                                  'oend' => 3590122,
                                  'ident' => 'C04HBa0147F16.1',
                                  'length' => 117947,
                                  'typedesc' => 'finished',
                                  'orient' => '-',
                                  'linenum' => '49',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 48
                                },
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 3590123,
                                  'cend' => 139443,
                                  'oend' => 3729565,
                                  'ident' => 'C04HBa0308B07.2',
                                  'length' => 139443,
                                  'typedesc' => 'finished',
                                  'orient' => '-',
                                  'linenum' => '50',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 49
                                }
                              ],
          'C04.3_contig28' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 10522295,
                                  'cend' => 78552,
                                  'oend' => 10600846,
                                  'ident' => 'C04HBa0219H08.1',
                                  'length' => 78552,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '159',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 158
                                }
                              ],
          'C04.3_contig7' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1557563,
                                 'cend' => 174507,
                                 'oend' => 1732069,
                                 'ident' => 'C04SLm0030C09.1',
                                 'length' => 174507,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '24',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 23
                               }
                             ],
          'C04.3_contig4' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 610051,
                                 'cend' => 153623,
                                 'oend' => 763673,
                                 'ident' => 'C04HBa0082D04.1',
                                 'length' => 153623,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '11',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 10
                               }
                             ],
          'C04.3_contig20' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 6648499,
                                  'cend' => 149672,
                                  'oend' => 6798170,
                                  'ident' => 'C04HBa0291F09.1',
                                  'length' => 149672,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '93',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 92
                                }
                              ],
          'C04.3_contig22' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 7615732,
                                  'cend' => 56363,
                                  'oend' => 7672094,
                                  'ident' => 'C04HBa0255I02.1',
                                  'length' => 56363,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '109',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 108
                                }
                              ],
          'C04.1_contig1' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 450001,
                                 'cend' => 114152,
                                 'oend' => 564152,
                                 'ident' => 'C04HBa0036C23.1',
                                 'length' => 114152,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '10',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 10
                               }
                             ],
          'C04.2_contig7' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 4266303,
                                 'cend' => 117561,
                                 'oend' => 4383863,
                                 'ident' => 'C04HBa0132O11.1',
                                 'length' => 117561,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '71',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 71
                               }
                             ],
          'C04.3_contig27' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 10340819,
                                  'cend' => 131476,
                                  'oend' => 10472294,
                                  'ident' => 'C04SLm0059M16.1',
                                  'length' => 131476,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '157',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 156
                                }
                              ],
          'C04.1_contig5' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 2139404,
                                 'cend' => 120037,
                                 'oend' => 2259440,
                                 'ident' => 'C04HBa0006E18.1',
                                 'length' => 120037,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '34',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 34
                               }
                             ],
          'C04.1_contig4' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1534087,
                                 'cend' => 125040,
                                 'oend' => 1659126,
                                 'ident' => 'C04HBa0027G19.1',
                                 'length' => 125040,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '27',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 27
                               },
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1659127,
                                 'cend' => 160432,
                                 'oend' => 1817558,
                                 'ident' => 'C04HBa0198L24.1',
                                 'length' => 158432,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '28',
                                 'cstart' => 2001,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 28
                               },
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1817559,
                                 'cend' => 11681,
                                 'oend' => 1827239,
                                 'ident' => 'C04HBa0119A16.1',
                                 'length' => 9681,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '29',
                                 'cstart' => 2001,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 29
                               },
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 1827240,
                                 'cend' => 164164,
                                 'oend' => 1989403,
                                 'ident' => 'C04HBa0031H05.1',
                                 'length' => 162164,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '30',
                                 'cstart' => 2001,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 30
                               }
                             ],
          'C04.3_contig12' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 3177488,
                                  'cend' => 144688,
                                  'oend' => 3322175,
                                  'ident' => 'C04HBa0311A10.1',
                                  'length' => 144688,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '45',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 44
                                }
                              ],
          'C04.3_contig1' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 50001,
                                 'cend' => 126391,
                                 'oend' => 176391,
                                 'ident' => 'C04SLm0098C07.1',
                                 'length' => 126391,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '2',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 2
                               }
                             ],
          'C04.3_contig3' => [
                               {
                                 'objname' => 'S.lycopersicum-chr4',
                                 'ostart' => 507124,
                                 'cend' => 52927,
                                 'oend' => 560050,
                                 'ident' => 'C04HBa0078J04.1',
                                 'length' => 52927,
                                 'typedesc' => 'finished',
                                 'orient' => '+',
                                 'linenum' => '9',
                                 'cstart' => 1,
                                 'type' => 'F',
                                 'is_gap' => 0,
                                 'partnum' => 8
                               }
                             ],
          'C04.3_contig18' => [
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 5716740,
                                  'cend' => 120037,
                                  'oend' => 5836776,
                                  'ident' => 'C04HBa0006E18.1',
                                  'length' => 120037,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '79',
                                  'cstart' => 1,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 78
                                },
                                {
                                  'objname' => 'S.lycopersicum-chr4',
                                  'ostart' => 5836777,
                                  'cend' => 101713,
                                  'oend' => 5936489,
                                  'ident' => 'C04HBa0158A08.1',
                                  'length' => 99713,
                                  'typedesc' => 'finished',
                                  'orient' => '+',
                                  'linenum' => '80',
                                  'cstart' => 2001,
                                  'type' => 'F',
                                  'is_gap' => 0,
                                  'partnum' => 79
                                }
                              ]
        );

my %contigs = named_contigs(4, agp_file => "$FindBin::RealBin/data/chr04.v3.agp", include_old => 1);
is_deeply( \%contigs, \%parsed_contigs, 'contigs parsed OK')
  or diag Dumper \%contigs;


my @features = contig_features( named_contigs(4, agp_file => "$FindBin::RealBin/data/chr04.v3.agp" ) );
isa_ok( $features[0], 'Bio::SeqFeatureI' );

my $g = Bio::FeatureIO->new( -format => 'gff', -version => 3, -fh => \*STDOUT );
$g->write_feature($_) foreach @features;

