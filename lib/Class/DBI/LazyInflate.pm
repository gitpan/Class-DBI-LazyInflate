# $Id: LazyInflate.pm 5 2005-02-25 07:54:31Z daisuke $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Class::DBI::LazyInflate;
use strict;
use Data::Lazy;
use vars qw($VERSION);
$VERSION = '0.02';

sub import
{
    my $class = shift;
    my($caller) = caller();
    {
        no strict 'refs';
        *{ "${caller}::has_lazy" } = \&has_lazy;
    }
}

sub has_lazy
{
    my($class, $column, $colclass, %args) = @_;

    my $inflate      = $args{inflate} || 
        ($colclass->isa('Class::DBI') ? '_simple_bless' : 'new');
    my $lazy_inflate = sub {
        my $value = shift;
        tie $value, 'Data::Lazy', sub { ref($inflate) eq 'CODE' ? $inflate->($value) : $colclass->$inflate($value) }, LAZY_STOREVALUE;
        $value;
    };
    $class->has_a(
        $column, $colclass,
        inflate => $lazy_inflate, deflate => $args{deflate}
    );
}

1;

__END__

=head1 NAME

Class::DBI::LazyInflate - Defer Inflating Of Columns Until They Are Used

=head1 SYNOPSIS

  package MyData;
  use base qw(Class::DBI);
  use Class::DBI::LazyInflate;
  use DateTime;
  use DateTime::Format::MySQL;

  __PACKAGE__->has_lazy(
    'lastmod', 'DateTime',
    inflate => sub { DateTime::Format::MySQL->parse_datetime(shift) },
    deflate => sub { DateTime::Format::MySQL->format_datetime(shift) },
  );

  my $obj = MyData->retrieve($key); # lastmod is not inflated yet
  $obj->lastmod()->year();          # now it is.

  $obj->lastmod(DateTime->now());

  # Specify another Class::DBI type as a column:
  __PACKAGE__->has_lazy(cdbi_field => 'MyData');

=head1 DESCRIPTION

Class::DBI::LazyInflate is a utility class that allows you to create DBI
columns that only inflate to an object when it is required. When a row is
fetched, columns specified via has_lazy() is wrapped by Data::Lazy, such that
it is inflated only when the column is actually used.

As seen in the SYNOPSIS section, one application of this class is for columns
that inflate to objects that are costly to create, such as DateTime.
Class::DBI::LazyInflate allows you defer materialization of such objects
until when you really need it

=head1 METHODS

=head2 has_lazy($col, $class, inflate => ..., deflate => ...)

has_lazy() declares that column is to be inflated lazily, and is installed
to the calling package's namespace upon call to "use Class::DBI::LazyInflate".
The arguments are exactly the same as has_a().

If inflate is not specified, it will lazily perform the default inflate
procedure that Class::DBI uses.

=head1 AUTHOR

Daisuke Maki E<lt>dmaki@cpan.orgE<gt>

=head1 SEE ALSO

L<Class::DBI|Class::DBI>
L<Data::Lazy|Data::Lazy>


=cut