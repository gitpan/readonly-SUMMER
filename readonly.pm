package readonly ;    # Documented at the __END__.

# $Id: readonly.pm,v 1.5 2000/04/16 15:55:11 root Exp root $

use strict ;

use Carp qw( croak carp ) ;

use vars qw( $VERSION ) ;
$VERSION = '1.02' ;

my %unwise = map { $_ => undef } qw(
                    BEGIN INIT CHECK END DESTROY AUTOLOAD 
                    STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG
                    ) ;

sub import {
    return $VERSION if @_ == 1 ;

    croak "usage: use readonly '\$SCALAR' => value ; " . 
          "# Don't forget to single quote the scalar" 
    if @_ < 3 or not defined $_[1] or not defined $_[2] ;

    shift ; # Get rid of the 'class'.

    my $pkg = caller ;

    while( defined( my $name = shift ) ) {

        croak "Readonly scalar `$name' has no value" unless @_ ;

        if( substr( $name, 0, 1 ) eq '$' ) {
            $name = substr( $name, 1 ) ;
        }
        else {
            carp "Using readonly scalar `\$$name' instead of bare `$name'" ;
        }

        my( $uname ) = $name =~ /^(_?[^\W_0-9]\w*)$/o ; # Untaint name

        croak "Cannot make `\$$name' readonly"      
        if not defined $uname or exists $unwise{$uname} or $uname =~ /^__/o ;

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
        # which ends in a \ the readonly scalar will not be created.)
        my( $uval ) = $val =~ /^(.*)$/o ; # Untaint val 

        if( eval "defined \$${pkg}::$uname" ) { 
            carp "Cannot change readonly scalar `\$$name'" ;
        }
        else {
            no strict 'vars' ;
            eval "*${pkg}::$uname=\\$uval" ;
            carp "Failed to create readonly scalar `\$$name'" 
            unless eval "defined \$${pkg}::$uname" ; 
        }
    }
}


1 ;


__END__

=head1 NAME

readonly - Perl pragma to declare readonly scalars

=head1 SYNOPSIS

    use readonly 
            '$READONLY' => 57,
            '$TOPIC'    => 'computing',
            '$TRUE'     => 1,
            '$FALSE'    => 0,
            '$PI'       => 4 * atan2( 1, 1 ),

            '$ALPHA'    => 1.761,
            '$BETA'     => 2.814,
            '$GAMMA'    => 4.012,
            '$PATH'     => '/usr/local/lib/lout/include',
            '$EXE'      => '/usr/local/bin/lout',
            ;

    # Have to use a separate readonly if we refer back.
    use readonly
            '$RC'   => "$EXE/config",
            ;

=head1 DESCRIPTION

This pragma creates readonly scalars in the current namespace. The scalars
thus created may be used in all contexts where read/write scalars would be
used with the exception that you will get an C<eval> trappable run-time error
"Modification of a read-only value attempted..." if you try to assign to a
readonly scalar.

Of course there is already a pragma, C<constant>, which provides this kind of
functionality (and more, since C<constant> also handles arrays, hashes etc).
However C<constant>s must be used with different syntax in different contexts,
whereas C<readonly>s can be used with the same consistent scalar syntax
throughout.

=head2 String Interpolation

    use constant PI    => 4 * atan2 1, 1 ;
    use readonly '$PI' => 4 * atan2 1, 1 ;

We can print C<readonly>s directly:

    print "The value of pi is $PI\n" ;

But for C<constant>s we must do this:

    print "The value of pi is ", PI, "\n" ;
    
or this:

    print "The value of pi is @{[PI]}\n" ;


=head2 Hash Keys

    use constant TOPIC    => 'geology' ;
    use readonly '$TOPIC' => 'geology' ;

    my %topic = (
            geology   => 5,
            computing => 7,
            biology   => 9,
        ) ;

Using a C<readonly> scalar we can simply write:

    my $value = $topic{$TOPIC}

However, if we try to access one of the hash elements using the C<constant>:

    my $value = $topic{TOPIC} ;

we get an unwelcome surprise: C<$value> is set to C<undef> because perl will
take TOPIC to be the literal string 'TOPIC' and since no hash element has that
key the result is undef. Thus in this situation we would have to write:

    my $value = $topic{TOPIC()} ;

or perhaps:

    my $value = $topic{&TOPIC} ;

=head2 Error Messages 

=over

=item C<Modification of a read-only value attempted>

Eval trappable fatal error. The reason for this pragma's existence. This will
occur if you try to assign to a readonly scalar, e.g. C<$PI = 3>, or C<$PI++>.

=item C<Using readonly scalar `$SCALAR' instead of bare `SCALAR'>

Warning. The scalar name should begin with a $. (This is to allow the
possibility of supporting readonly arrays and hashes in the future - if I can
ever figure out how - suggestions welcome.)

=item C<Cannot change readonly scalar `$SCALAR'>

Warning. This is why we use this pragma in the first place. If you write
C<use readonly '$SOMESCALAR' =E<gt> 42 ;> somewhere and elsewhere write C<use
readonly '$SOMESCALAR' =E<gt> 'benji' ;> you will get this warning.

=item C<usage: use readonly '$SCALAR' => value ; # Don't forget to single quote the
scalar>

Fatal syntax error. The name of the scalar must be in single quotes, and you
must separate it from the value with either => or a comma. 

=item C<Readonly scalar `$SCALAR' has no value>

Fatal error. Every scalar must be set to a defined scalar value.

=item C<Cannot make `$SCALAR' readonly>

Fatal error. The name being used contains "illegal" characters or begins with
two leading underscores or is in this list: 

    BEGIN INIT CHECK END DESTROY AUTOLOAD STDIN STDOUT STDERR ARGV ARGVOUT ENV INC SIG

=item C<Failed to create readonly scalar `$SCALAR'>

Warning. This will occur for example if you try to set the value to be
C<'abc\'> whose last character, C<\> might be problematic. 

=back

=head2 Do We Need It? 

You can achieve the same effect as:

    use readonly '$WEB_ADDRESS' => 'www.perlpress.com' ;

by coding:

    use vars '$WEB_ADDRESS' ; *WEB_ADDRESS = \'www.perlpress.com' ;

Similarly:

    use constant WEB_ADDRESS => 'www.perlpress.com' ;

can be coded as:

    sub WEB_ADDRESS() { 'www.perlpress.com' } # No semi-colon.

However, C<readonly> allows us to create many readonly scalars in one go with
a compact syntax:

    use readonly
            '$HOME' => '/home/summer',
            '$ROOT' => '/root',
            '$PERL' => '/usr/lib/perl',
            ;

=head1 BUGS

Only copes with scalars.

Sometimes with 5.004 when using eval exception handling you get "Use of
uninitialized value at..." errors; the cure is to write:

    eval {
        $@ = undef ;
        # rest as normal

=head1 AUTHOR

I copied some ideas from C<constant.pm>.

Mark Summerfield. I can be contacted as <summer@perlpress.com> -
please include the word 'readonly' in the subject line.

=head1 COPYRIGHT

Copyright (c) Mark Summerfield 2000. All Rights Reserved.

This module may be used/distributed/modified under the same terms as perl
itself. 

=cut
