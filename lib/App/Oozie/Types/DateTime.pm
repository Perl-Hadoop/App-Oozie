package App::Oozie::Types::DateTime;

use 5.014;
use strict;
use warnings;

# VERSION

use App::Oozie::Date;
use App::Oozie::Constants qw(
    SHORTCUT_METHODS
);
use Date::Parse ();
use DateTime    ();

use Type::Library -base;
use Type::Tiny;
use Type::Utils -all;
use Sub::Quote qw( quote_sub );

BEGIN {
    extends 'Types::Standard';
}

declare IsHour => as Int,
    constraint => quote_sub q{
        my $val = shift;
        return if  $val !~ /^[0-9]+$/
                    || $val < 0
                    || $val > 23;
        return 1;
    },
;

declare IsMinute => as Int,
    constraint => quote_sub q{
        my $val = shift;
        return if  $val !~ /^[0-9]+$/
                    || $val < 0
                    || $val > 59;
        return 1;
    },
;

declare IsDate => as Str,
    constraint => quote_sub q{
        my $val = shift;
        # The TZ values doesn't matter in here as this is only
        # doing a syntactical check
        state $date     = App::Oozie::Date->new( timezone => 'UTC' );
        state $is_short = { map { $val => 1 } SHORTCUT_METHODS };
        return if ! $val;
        return 1 if $is_short->{ $val };
        return if ! $date->is_valid( $val );
        return 1;
    },
;

declare IsDateStr => as Str,
    constraint => quote_sub q{
        my $val = shift;
        return if ! $val;
        return Date::Parse::str2time $val;
    },
;

declare IsTZ => as Str,
    constraint => quote_sub q{
        my $val = shift || return;
        eval {
            DateTime->now( time_zone => $val );
            1;
        };
    },
;

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Oozie::Types::DateTime - Internal types.

=head1 SYNOPSIS

    use  App::Oozie::Types::DateTime qw( IsDate );

=head1 DESCRIPTION

Internal types.

=head1 Types

=head2 IsDate

=head2 IsDateStr

=head2 IsHour

=head2 IsMinute

=head2 IsTZ

=head1 SEE ALSO

L<App::Oozie>.

=cut
