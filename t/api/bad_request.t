use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::DarkPAN ();
use Path::Tiny qw( path );
use Test::More;
use Test::Mojo;

my $t   = Test::Mojo->new('MetaCPAN::API');


# invalid JSON Query
# should return valid JSON Response
$t->post_ok('/file/_search' => => {Accept => 'application/json'} => 'some content as invalid JSON')
  ->status_is(400)
  ->json_like('/results/7/title' => qr/some content/);


done_testing();
