use v5.20;

package Tie::String::Redactable;
use experimental qw(signatures);
use parent qw(String::Redactable);

our $VERSION = '1.087';

sub TIESCALAR ($class, $string) {
	local $SIG{__WARN__} = sub {};
	my $self = bless String::Redactable->new($string), __PACKAGE__;
	}

sub FETCH ($self) {
	$self->placeholder;
	}

sub STORE {
	return;
	}

=encoding utf8

=pod

=head1 NAME

Tie::String::Redactable - work even harder to redact a string

=head1 SYNOPSIS

	use Tie::String::Redactable;

	my $object = tie my $string, 'Tie::String::Redactable', $password;

	# None of these return $password


	#
	$object->to_str_unsafe;
	(tied $string)->to_str_unsafe;

=head1 DESCRIPTION

=cut

__PACKAGE__
