use strict;
use warnings;

BEGIN
{
  use FindBin;
  use lib $FindBin::Bin . '/../../lib';
  use lib $FindBin::Bin . '/../lib';
} #BEGIN

use MetaCPAN::DarkPAN ();
use Path::Tiny;
use YAML::XS;
use JSON::XS;
use Test::More;
use Test::Mojo;

my $t   = Test::Mojo->new('MetaCPAN::API');


# invalid JSON Query
# should return valid JSON Response
$t->post_ok('/file/_search' => => {Accept => 'application/json'} => 'some content as invalid JSON')
  ->status_is(400)
  ->json_like('/error' => qr/problem with your request/);


my $tx = $t->tx;

print "Status Code: [", $tx->res->code, "]\n";
print "Content-Type: '", $tx->res->headers->content_type , "'\n";

if ( length($tx->res->body) < 1000 ) {
    print "Response Body (max 1000): '", $tx->res->body, "'\n";
}
else {
    print "Response Body (> 1000): too big!\n";
}


my $bigquery = YAML::XS::LoadFile($FindBin::Bin . '/../../test-data/big-query.yml');


# Big Search Query
# should return a Query Limit Error
$t->post_ok('/file/_search' => => {Accept => 'application/json'} => JSON::XS::json_encode($bigquery))
  ->status_is(416)
  ->json_like('/error' => qr/exceeds maximum/);


$tx = $t->tx;

print "Status Code: [", $tx->res->code, "]\n";
print "Content-Type: '", $tx->res->headers->content_type , "'\n";

if ( length($tx->res->body) < 1000 ) {
    print "Response Body (max 1000): '", $tx->res->body, "'\n";
}
else {
    print "Response Body (> 1000): too big!\n";
}




done_testing();
