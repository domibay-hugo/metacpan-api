package Catalyst::Action::Deserialize::MetaCPANSanitizedJSON;

use Moose;
use namespace::autoclean;
use Try::Tiny qw( catch try );
use Cpanel::JSON::XS                 ();
use MetaCPAN::Server::QuerySanitizer ();

use Data::Dump qw(dump);

extends 'Catalyst::Action::Deserialize::JSON';

around execute => sub {
    my ( $orig, $self, $controller, $c ) = @_;
    my $result;

    try {
        $result = $self->$orig( $controller, $c );

        # if sucessfully serialized
        if ( $result eq '1' ) {

            # if we got something
            if ( my $data = $c->req->data ) {

                # clean it
                $c->req->data(
                    MetaCPAN::Server::QuerySanitizer->new( query => $data, )
                        ->query );
            }
        }
        else {  #JSON Decode failed
            if ( ref $result ne '' ) {
                if ( defined $result->{'message'} ) {
                    my @arrdescription = ( $result->{'message'} =~ m/^(.*) at ([^\s]+) (line .*)$/mi );


                    print "arr desc dmp:\n", dump @arrdescription ;
                    print "\n";

                    $c->detach( '/bad_request_json'
                        , [ { 'exception_type' => ref($result), 'description' => $arrdescription[0]
                            , 'file' => $arrdescription[1], 'lines' => $arrdescription[2] } ] );
                }
                else {  #The Result has no "message" Field
                    $c->detach( '/bad_request_json'
                        , [ { 'exception' => $result } ] );
                }
            }
            else {  #The Result is not a Reference
                $c->detach( '/bad_request_json'
                    , [ { 'description' => $result } ] );
            } #if ( ref $result ne '' )
        } #if ( $result eq '1' )

        foreach my $attr (qw( query_parameters parameters )) {

            # there's probably a more appropriate place for this
            # but it's the same concept and we can reuse the error handling
            if ( my $params = $c->req->$attr ) {

                # ES also accepts the content in the querystring
                if ( exists $params->{source} ) {
                    if ( my $source = delete $params->{source} ) {

                   # NOTE: merge $controller->{json_options} if we ever use it
                        my $json = Cpanel::JSON::XS->new->utf8;

                        # if it decodes
                        if ( try { $source = $json->decode($source); } ) {

                            # clean it
                            $source = MetaCPAN::Server::QuerySanitizer->new(
                                query => $source, )->query;

                            # update the $req
                            $params->{source} = $json->encode($source);
                            $c->req->$attr($params);
                        }
                    }
                }
            }
        }
    }
    catch {
        my $e = $_[0];
        if ( try { $e->isa('MetaCPAN::Server::QuerySanitizer::Error') } ) {

            my @arrdescription = ($e->message =~ m/^(.*) at ([^\s]+) (line .*)$/mi);

            # this will return a 400 (text) through Catalyst::Action::Deserialize
            #$result = $e->message;
            $result = $arrdescription[0];

            $c->detach( '/bad_request_json'
                , [ { 'description' => $arrdescription[0]
                    , 'file' => $arrdescription[1], 'lines' => $arrdescription[2] } ] );


            # this is our custom version (403) that returns json
            $c->detach( "/not_allowed", [ $e->message ] );
        }
        else {
            $result = $e;
        }
    };

    return $result;
};

after 'execute' => sub {
    my ( $self, $controller, $c ) = @_;

    print "'" . (caller(1))[3] . "' : Signal to '" . (caller(0))[3] . "'\n";

    print "Status Code [", $c->res->code, "]\n";
    print "Content-Type: '", $c->res->content_type ,"'\n" ;
    print "Response Body: '", $c->res->body ,"'\n" ;

    if ( $c->has_errors ) {
        print "execute finished with errors!";
        print "arr err dmp:\n", dump $c->errors ;
        print "\n";

        #$c->clear_errors;
    }
    else {
        print "execute finished - no errors.";
    }
};


__PACKAGE__->meta->make_immutable;

1;
