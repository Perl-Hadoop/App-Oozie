package App::Oozie::Serializer::YAML;

use 5.014;
use strict;
use warnings;

# VERSION

use YAML::XS ();
use Moo;

sub encode {
    my $self = shift;
    my $data = shift;
    YAML::XS::Dump( $data );
}

sub decode {
    my $self = shift;
    my $data = shift;
    YAML::XS::Load( $data );
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Serializer::YAML - YAML encoder/decoder.

=head1 SYNOPSIS

    use App::Oozie::Serializer;
    my $s = App::Oozie::Serializer->new(
        # ...
        format => 'yaml',
    );
    my $d = $s->decode( $input );

=head1 DESCRIPTION

YAML encoder/decoder.

=head1 Methods

=head2 encode

=head2 decode

=head1 SEE ALSO

L<App::Oozie>. L<App::Oozie::Serializer>.

=cut
