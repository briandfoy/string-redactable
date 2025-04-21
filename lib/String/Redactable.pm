use v5.20;
use utf8;

package String::Redactable;
use experimental qw(signatures);

use Encode ();

our $VERSION = '0.001_01';

=encoding utf8

=head1 NAME

String::Redactable - A string that automatically redacts itself

=head1 SYNOPSIS

	use String::Redactable;

	my $string = String::Redactable->new( $sensitive_text );

	say $string;                 # '<redacted string>'
	say $string->to_str_unsafe;  # unredacted text

=head1 DESCRIPTION

C<String::Redactable> tries to prevent you from accidentally exposing
a sensitive string, such as a password, in a larger string, such as a
log message or data dump.

When you carelessy use this as a simple string, you get back the
literal string C<*redacted data*>. To get the actual string, you call
C<to_str_unsafe>:

	$password->to_str_unsafe;

This is not designed to completely protect the sensitive data from
prying eyes. This is simply the UTF-8 encoded version of the value that
is XOR-ed by an object-specific key that is not stored with the object.
All of that is undone by C<to_str_unsafe>.

Beyond that, this module uses L<overload> and other tricks to prevent
the actual string from showing up in output and other strings.

=head2 Notes on serializers

C<String::Redactable> objects resist serialization to the best of
their ability. At worst, the serialization shows the internal string
for the object, which does not expose the key used to XOR the UTF-8
encoded string.

Since the XOR keys are not stored in the object (and those keys are
removed when the object goes out of scope), these values cannot be
serialized and re-inflated. But, that's what you want.

=over 4

=item * L<Data::Dumper> - cannot use C<$Data::Dump::Freezer> because that
requires the

=item * L<Storable> -

=item * JSON modules - this supports C<TO_JSON>

=item * YAML -


=back

=head2 Methods

=over 4

=item new

=cut

use overload
	q("") => sub { $_[0]->placeholder },
	'0+'  => sub { 0 },
	'-X'  => sub { () },
	map { $_ => sub { () } } qw(
		<=> cmp
		lt le gt ge eq ne
		~~
		)
	;

my %keys = ();

=item key

Returns the XOR key. This is not meant to be cryptographically
secure. It's merely here so that the redacted string does not show
up in the object dump.

=cut

my $new_key = sub ($class, $length = 512) {
	state $rc = require List::Util;
	substr(
		join( '',
			List::Util::shuffle(
				map { List::Util::shuffle( 'A' .. 'Z', 'a' .. 'z', qw(= ! : ;) ) } 1 .. 25
				)
			),
		0, $length
		)
	;
	};

=item new

=cut

sub new ($class, $string, $opts={}) {
	my $key = $opts->{key} // $new_key->( 5 * length $string );
	my $encoded = Encode::encode( 'UTF-8', $string );
	my $hidden = ($encoded ^ $key);
	my $self = bless \$hidden, $class;
	$keys{$self} = $key;
	$self;
	}

sub DESTROY ($self) {
	delete $keys{$self};
	}

=item placeholder

The value that is substituted for the

=cut

sub placeholder ( $class ) {
	state $rc = require Carp;
	Carp::carp "Possible unintended interpolation of a redactable string";
	'<redacted data>'
	}

=item STORABLE_freeze

=cut

sub STORABLE_freeze ($self, $cloning) {
	$_[0]->placeholder;
	}

=item TO_JSON

=cut

sub TO_JSON {
	$_[0]->placeholder;
	}

=item to_str_unsafe

=cut

sub to_str_unsafe ($self) {
	my $encoded = ($$self ^ $keys{$self}) =~ s/\000+\z//r;
	Encode::decode( 'UTF-8', $encoded );
	}

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/string-redactable

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2025, brian d foy, All Rights Reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
