package MetaCPAN::Server::Action::Deserialize;
use Moose;
extends 'Catalyst::Action::Deserialize';
use Cpanel::JSON::XS qw(encode_json);

around serialize_bad_request => sub {
    my $orig = shift;
    my $self = shift;
    my ($c, $content_type, $error) = @_;

    $c->res->status(400);
    $c->stash({
        rest => {
            error =>
                "Content-Type " . $content_type . " had a problem with your request.\r\n***ERROR***\r\n$error",
        },
    });

    $c->detach;

    return $self->$orig(@_);
};

1;
