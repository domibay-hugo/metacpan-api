use strict;
use warnings;

BEGIN
{
  use FindBin;
  use lib $FindBin::Bin . '/../../lib';
  use lib $FindBin::Bin . '/../lib';
} #BEGIN

use MetaCPAN::DarkPAN ();
use Path::Tiny qw( path );
use Test::More;
use Test::Mojo;

my $t   = Test::Mojo->new('MetaCPAN::API');


# invalid JSON Query
# should return valid JSON Response
$t->post_ok('/file/_search' => => {Accept => 'application/json'} => 'some content as invalid JSON')
  ->status_is(400);
#  ->json_like('/results/7/title' => qr/some content/);


my $tx = $t->tx;

print "Status Code: [", $tx->res->code, "]\n";
print "Content-Type: '", $tx->res->headers->content_type , "'\n";

if ( length($tx->res->body) < 1000 ) {
    print "Response Body (max 1000): '", $tx->res->body, "'\n";
}


done_testing();
