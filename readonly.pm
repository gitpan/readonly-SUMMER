package readonly ;    # Documented at the __END__.

# $Id: readonly.pm,v 1.4 2000/05/21 15:49:07 root Exp root $

use strict ;

use Carp qw( croak carp ) ;

use vars qw( $VERSION ) ;
$VERSION = '1.05' ;

my %unwise = map { $_ => undef } qw(
                    BEGIN INIT CHECK END DESTROY AUTOLOAD 
                    STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG
                    ) ;

*new = \&import ; # Deprecated; kept for backward compatibility

sub import {
    return $VERSION if @_ == 1 ;

    croak "usage: use readonly '\$SCALAR'=>value; # remember to single quote the scalar name" 
    if @_ < 3 or not defined $_[1] or not defined $_[2] ;

    shift ; # Get rid of the 'class'.

    my $pkg = caller ;

    while( defined( my $name = shift ) ) {

        croak "readonly: scalar `$name' has no value" unless @_ ;

        my( $uname ) = $name =~ /^\$?(_?[^\W_0-9]\w*)$/o ; # Untaint name

        croak "readonly: cannot make `\$$name' readonly"      
        if not defined $uname or exists $unwise{$uname} ;

        my $val = shift ;
        # No need to check for undef "can't" arise at this point.

        unless( $val =~ /^\d+$/o                 or
                $val =~ /^0b[01]+$/o             or
                $val =~ /^0x[\dAaBbCcDdEeFf]+$/o or
                ( $val =~ /^[\d.eE]+$/o and 
                  $val =~ tr/\././ <= 1 and $val =~ tr/[eE]/e/ <= 1 ) ) {
            $val = "'$val'" ; # String, e.g. hash key
        }
        
        # We now untaint $val.
        # If it was a number, i.e. matched any of the patterns above then it
        # is safe to untaint; if it was a string, well, we've enclosed it in
        # non-interpolating single quotes so again it is safe. (If a string
        # ends in a \ the readonly scalar will not be created.)
        my( $uval ) = $val =~ /^(.*)$/o ; # Untaint val 

        if( eval "exists \$${pkg}::{$uname}" ) { 
            carp "readonly: cannot change readonly scalar `\$$name'" ;
        }
        else {
            eval "*${pkg}::$uname=\\$uval" ;
            croak "readonly: failed to create readonly scalar `\$$name'" 
            unless eval "exists \$${pkg}::{$uname}" ; 
        }
    }
}


sub set {
    croak "usage: readonly->set '\$SCALAR'; # remember to single quote the scalar name" 
    if @_ < 2 or not defined $_[1] ;

    shift ; # Get rid of the 'class'.

    my $pkg = caller ;

    while( defined( my $name = shift ) ) {
        my( $uname ) = $name =~ /^\$?(_?[^\W_0-9]\w*)$/o ; # Untaint name

        croak "readonly: cannot make `\$$name' readonly" 
        if exists $unwise{$uname} ;

        croak "readonly: cannot set non-existent scalar `\$$uname' readonly"
        unless eval "exists \$${pkg}::{$uname}" ; 

        my $val = eval "\$${pkg}::$uname" ;
        unless( $val =~ /^\d+$/o                 or
                $val =~ /^0b[01]+$/o             or
                $val =~ /^0x[\dAaBbCcDdEeFf]+$/o or
                ( $val =~ /^[\d.eE]+$/o and 
                  $val =~ tr/\././ <= 1 and $val =~ tr/[eE]/e/ <= 1 ) ) {
            $val = "'$val'" ; # String, e.g. hash key
        }
        my( $uval ) = $val =~ /^(.*)$/o ; # Untaint val 

        eval "*${pkg}::$uname=\\$uval" ;
    }
}


sub unimport {

    if( @_ == 1 ) {
        carp "readonly: noop" ;
    }
    else {
        my $s = @_ > 2 ? 's' : '' ;
        carp "readonly: cannot undefine readonly scalar$s" ;
    }
}


1 ;


__END__

=head1 NAME

readonly - Perl pragma and function module to create readonly scalars 

=head1 SYNOPSIS

    ##### Compile time -- create, assign & set readonly in one step

    use readonly 
            '$MAX_LINES' => 70,
            '$TOPIC'     => 'computing',
            '$TRUE'      => 1,
            '$FALSE'     => 0,
            '$PI'        => 4 * atan2( 1, 1 ),

            '$ALPHA'     => 1.761,
            '$BETA'      => 2.814,
            '$GAMMA'     => 4.012,
            '$PATH'      => '/usr/local/lib/project/include',
            '$EXE'       => '/usr/local/bin/project',
            ;

    # Have to use a separate readonly if we refer back.
    use readonly '$RC'  => "$EXE/config" ;

    $RC = '/new/path' ; # eval trappable error

    ##### Run time -- set readonly

    use readonly () ; # If no previous pragma calls.

    use vars qw( $BACKGROUND $FOREGROUND $HIGHLIGHT ) ; # Predeclare.

    $BACKGROUND = param( 'green' ) ;    # Pre-assign
    $FOREGROUND = param( 'blue' ) ;
    $HIGHLIGHT  = param( 'yellow' ) ;

    readonly->set( '$BACKGROUND', '$FOREGROUND', '$HIGHLIGHT' ) ;

    $BACKGROUND = 'red' ; # eval trappable error

=head1 DESCRIPTION

The readonly module can be used either as a compile-time pragma or a run-time
class module.

When used as a pragma it creates readonly scalars in the current namespace.
When used as a function module it marks scalars as readonly. Only package
scalars may be made readonly, I<not> C<my> scalars. C<readonly> scalars may be
used in all contexts where read/write scalars would be used with the exception
that you will get an C<eval> trappable run-time error "Modification of a
read-only value attempted..." if you try to assign to a readonly scalar.

The pragma, C<constant>, provides apparently similar functionality (and more,
since C<constant> also handles arrays, hashes etc). However C<constant>s are
I<not> readonly scalars, but rather subroutines which behave like them and
which must be used with different syntaxes in different contexts. C<readonly>s
can be used with the same consistent scalar syntax throughout. Also
C<readonly>s may be set either at compile-time I<or> at run-time.

=head2 String Interpolation

    use readonly '$PI' => 4 * atan2 1, 1 ; # Compile time
    use constant PI    => 4 * atan2 1, 1 ; # Compile time

We can print C<readonly>s directly:

    print "The value of pi is $PI\n" ;

but for C<constant>s we must do this:

    print "The value of pi is ", PI, "\n" ;
    
or this:

    print "The value of pi is @{[PI]}\n" ;


=head2 Hash Keys

    use readonly '$TOPIC' => 'geology' ;
    use constant TOPIC    => 'geology' ;

    my %topic = (
            geology   => 5,
            computing => 7,
            biology   => 9,
        ) ;

Using a C<readonly> scalar we can simply write:

    my $value = $topic{$TOPIC}

however, if we try to access one of the hash elements using the C<constant>:

    my $value = $topic{TOPIC} ;

we get an unwelcome surprise: C<$value> is set to C<undef> because perl will
take TOPIC to be the literal string 'TOPIC' and since no hash element has that
key the result is undef. Thus in this situation we would have to write:

    my $value = $topic{TOPIC()} ;

or perhaps:

    my $value = $topic{&TOPIC} ;

=head2 Runtime readonly's

Sometimes we only know what the readonly value will be after performing some
of our execution; in such cases we can use C<readonly-E<gt>set> to make an
existing scalar readonly: 

    use readonly () ; # If not already use'd
    use vars qw( $RED $GREEN $BLUE $YELLOW ) ; # Predeclare

    $RED    = '#FF0000' ; # Pre-assign
    $GREEN  = '#00FF00' ;
    $BLUE   = '#0000FF' ;
    $YELLOW = '#FFFF00' ;

    readonly->set( '$RED', '$GREEN', '$BLUE', '$YELLOW' ) ;

=head1 BUGS

Only copes with scalars.

In some tests with 5.004 C<readonly-E<gt>set> gives spurious warnings.

Sometimes with 5.004 when using eval exception handling you get "Use of
uninitialized value at..." errors; the cure is to write:

    eval {
        $@ = undef ;
        # rest as normal

=head1 AUTHOR

Mark Summerfield. I can be contacted as <summer@perlpress.com> -
please include the word 'readonly' in the subject line.

I copied some ideas from C<constant.pm>.

=head1 COPYRIGHT

Copyright (c) Mark Summerfield 2000. All Rights Reserved.

This module may be used/distributed/modified under the same terms as perl
itself. 

=head1 SEE ALSO

Constant or readonly scalars, arrays and hashes are available through other
mechanisms:

=over 4

=item *

Tom Phoenix's standard module C<constant>. This has the cons described above,
but the pros that it can provide readonly arrays and may be faster than other
approaches because the perl compiler cooperates with it behind the scenes.

=item *

Graham Barr's tie-based code archived at
http://www.xray.mpe.mpg.de/mailing-lists/modules/1999-02/msg00090.html

=item *

Mark-Jason Dominus' tie-based code at http://www.plover.com/~mjd/perl/Locked/

=item *

My own tie-based code at http://www.perlpress.com/perl/antiques.html
Tie::Const.

=back

Tie-based implementations should be able to offer readonly scalars, arrays and
hashes, but these implementations are likely to have a performance overhead
compared with C<readonly> or C<constant>.

=cut
