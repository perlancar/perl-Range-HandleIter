package Range::HandleIter;

# DATE
# VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(range_handleiter);

sub range_handleiter($$;$) {
    my ($start, $end, $step) = @_;

    tie *FH, 'Range::HandleIter::Tie', $start, $end, $step;
    \*FH;
}

package # hide from PAUSE
    Range::HandleIter::Tie;

use Scalar::Util qw(looks_like_number);

sub TIEHANDLE {
    my $class = shift;
    my ($start, $end, $step) = @_;
    $step //= 1;

    my $self = {
        start => $start,
        end   => $end,
        step  => $step,

        _ended => 0,
        _len   => 0,
        _cur   => $start,
        _buf   => [],
    };

    if (looks_like_number($start) && looks_like_number($end)) {
        $self->{_num}   = 1;
        $self->{_ended}++ if $start > $end;
    } else {
        die "Cannot specify step != 1 for non-numeric range" if $step != 1;
        $self->{_ended}++ if $start gt $end;
    }
    bless $self, $class;
}

sub _next {
    my $self = shift;

    if ($self->{_num}) {
        $self->{_ended}++ if $self->{_cur} > $self->{end};
        return if $self->{_ended};
        push @{ $self->{_buf} }, $self->{_cur};
        $self->{_cur} += $self->{step};
    } else {
        return if $self->{_ended};
        $self->{_ended}++ if $self->{_cur} ge $self->{end};
        push @{ $self->{_buf} }, $self->{_cur}++;
    }
}

sub READLINE {
    my $self = shift;
    $self->_next;
    if (@{ $self->{_buf} }) {
        $self->{_len}++;
        shift @{ $self->{_buf} };
    } else {
        undef;
    }
}

1;
#ABSTRACT: Generate a tied-handle iterator for range

=for Pod::Coverage .+

=head1 SYNOPSIS

  use Range::HandleIter qw(range_handleiter);

  my $iter = range_handleiter(1, 10);
  while (<$iter>) { ... } # 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

You can add step:

 my $iter = range_handleiter(1, 10, 2); # 1, 3, 5, 7, 9

You can use alphanumeric strings too since C<++> has some extra builtin magic
(see L<perlop>):

 $iter = range_handleiter("zx", "aab"); # zx, zy, zz, aaa, aab

Infinite list:

 $iter = range_handleiter(1, Inf); # 1, 2, 3, ...


=head1 DESCRIPTION

B<PROOF OF CONCEPT.>

This module offers a tied-handle-based iterator that you can use using while()
and the diamond operator. It's most probably useful as a proof of concept only.


=head1 FUNCTIONS

=head2 range_handleiter($start, $end [ , $step ]) => filehandle


=head1 SEE ALSO

L<Range::Iter>

L<Range::Iterator>

L<Range::ScalarIter>, L<Range::ArrayIter>, L<Range::HashIter>

=cut
