package App::Oozie::Types::Common;

use 5.010;
use strict;
use warnings;

use Type::Library -base;
use Type::Tiny;
use Type::Utils -all;
use Sub::Quote qw( quote_sub );

BEGIN {
    extends 'Types::Standard';
}

use constant {
    RE_OOZIE_ID => qr{
        [0-9]+     -
        [0-9]+     -
        oozie-oozi -
    }xms,
    VALID_JOB_TYPES => [qw(
        bundle
        coord
        wf
    )],
};

# Oozie

declare IsCOORDID => as Str,
    constraint => quote_sub(
        q{
            my $input = shift;
            $input && $input =~ m{ $RE_OOZIE_ID [C] }xms
        },
        {
            '$RE_OOZIE_ID' => RE_OOZIE_ID,
        },
    ),
;

declare IsWFID => as Str,
    constraint => quote_sub(
        q{
            my $input = shift;
            $input && $input =~ m{ $RE_OOZIE_ID [W] }xms
        },
        {
            '$RE_OOZIE_ID' => RE_OOZIE_ID,
        },
    ),
;

declare IsBUNDLEID => as Str,
    constraint => quote_sub(
        q{
            my $input = shift;
            $input && $input =~ m{ $RE_OOZIE_ID [B] }xms
        },
        {
            '$RE_OOZIE_ID' => RE_OOZIE_ID,
        },
    ),
;

declare IsJobType => as Enum[ @{ +VALID_JOB_TYPES } ];

# User
declare IsUserName => as Str,
    constraint => quote_sub q{
        my $val = shift;
        $val && getpwnam $val;
    },
;

declare IsUserId => as Int,
    constraint => quote_sub q{
        my $val = shift;
        defined $val && getpwuid $val;
    },
;

# File system

declare IsExecutable => as Str,
    constraint => quote_sub q{
        my $val = shift;
        return ! $val || ! -e $val || ! -x _ ? 0 : 1;
    },
;

declare IsDir => as Str,
    constraint => quote_sub q{
        my $val = shift;
        return ! $val || ! -d $val ? 0 : 1;
    },
;

declare IsFile => as Str,
    constraint => quote_sub q{
        my $val = shift;
        my $rv = ! $val || ! -e $val || ! -f _ ? 0 : 1;
        if ( ! $rv ) {
            warn sprintf "type error: %s is not a file!", $val // '[undefined]';
        }
        $rv;
    },
;

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Types::Common - Internal types.

=head1 SYNOPSIS

     use App::Oozie::Types::Common qw( IsCOORDID );

=head1 DESCRIPTION

Internal types.

=head1 Types

=head2 IsBUNDLEID

=head2 IsCOORDID

=head2 IsDir

=head2 IsExecutable

=head2 IsFile

=head2 IsJobType

=head2 IsUserId

=head2 IsUserName

=head2 IsWFID

=head1 SEE ALSO

L<App::Oozie>.

=cut
