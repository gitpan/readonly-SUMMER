package readonly ;    # Documented at the __END__.

# $Id: readonly.pm,v 1.3 2000/04/16 07:33:19 root Exp root $

use strict ;

use Carp qw( croak carp ) ;

use vars qw( $VERSION ) ;
$VERSION = '1.01' ;

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

        if( substr( $name, 0, 1 ) eq '$' ) {
            $name = substr( $name, 1 ) ;
        }
        else {
            carp "Scalar `$name' should begin with \$" ;
        }

        my( $uname ) = $name =~ /^(_?[^\W_0-9]\w*)$/o ; # Untaint name

        croak "Cannot make $name readonly"      
        if not defined $uname or exists $unwise{$uname} or $uname =~ /^__/o ;

        my $val = shift ;

        if( $val =~ /^\d+$/o                 or
            $val =~ /^0b[01]+$/o             or
            $val =~ /^0x[\dAaBbCcDdEeFf]+$/o or
            ( $val =~ /^[\d.eE]+$/o and 
              $val =~ tr/\././ <= 1 and $val =~ tr/[eE]/e/ <= 1 ) ) {
            $val = "$val" ;   # Number, e.g. array index
            # $val is safe to untaint here because it can only match the
            # numeric patterns listed above.
        } 
        else {
            $val =~ tr,\\,, ;
            $val = "'$val'" ; # String, e.g. hash key
            # $val is safe to untaint here because it is enclosed in
            # non-interpolating single quotes and we have taken the paranoid
            # approach and removed any backslashes from the string.
        }

        my( $uval ) = $val =~ /^(.*)$/o ; # Untaint val 
        croak "Value `$val' cannot be made readonly" unless defined $uval ;

        {
            no strict 'vars' ;
            eval "*${pkg}::$uname=\\$uval" ;
        }
    }
}


1 ;


__END__

=head1 NAME

readonly - Perl pragma to declare readonly scalars

=head1 SYNOPSIS

    use readonly '$READONLY' => 57 ;
    use readonly '$TOPIC'    => 'computing' ;
    use readonly '$TRUE'     => 1 ;
    use readonly '$FALSE'    => 0 ;
    use readonly '$PI'       => 4 * atan2 1, 1 ;

    use readonly
            '$ALPHA'    => 1.761,
            '$BETA'     => 2.814,
            '$GAMMA'    => 4.012,
            '$PATH'     => '/usr/local/lib/lout/include',
            '$EXE'      => '/usr/local/bin/lout',
            ;

    use readonly '$BASE' => '/usr/opt/mozilla' ;
    # Have to use a separate readonly if we refer back.
    use readonly
            '$RC'   => "$BASE/config",
            '$EXE'  => "$BASE/bin",
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

=head2 String interpolation

    use constant PI    => 4 * atan2 1, 1 ;
    use readonly '$PI' => 4 * atan2 1, 1 ;

We cannot print C<constant>s directly so we must do this:

    print "The value of pi is ", PI, "\n" ;
    
or this:

    print "The value of pi is @{[PI]}\n" ;

but we can print C<readonly>s directly:

    print "The value of pi is $PI\n" ;

=head2 Hash keys

    use constant TOPIC    => 'geology' ;
    use readonly '$TOPIC' => 'geology' ;

    my %topic = (
            geology   => 5,
            computing => 7,
            biology   => 9,
        ) ;

If we try to access one of the hash elements using the C<constant>:

    my $value = $topic{TOPIC} ;

we get an unwelcome surprise: C<$value> is set to C<undef> because perl will
take TOPIC to be the literal string 'TOPIC' and since no hash element has that
key the result is undef. Thus in this situation we would have to write:

    my $value = $topic{TOPIC()} ;

or perhaps:

    my $value = $topic{&TOPIC} ;

On the other hand if we use a C<readonly> scalar we can simply write:

    my $value = $topic{$TOPIC}

with no problems.

=head2 Error reporting

    PI = 3 ;

will lead to a compile-time error, "Can't modify constant item in scalar
assignment...", whereas

    $PI = 3 ;

will lead to a run-time error, "Modification of a read-only value
attempted...". 

=head2 Is it necessary?

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

Strings which contain \'s will have them removed.

Silently ignores attempted redeclarations, e.g.

    use readonly '$READONLY' => 5 ;
    ...
    use readonly '$READONLY' => 9 ;

C<$READONLY> is I<still> 5, but no error message is given.

=head1 AUTHOR

I copied some ideas from C<constant.pm>.

Mark Summerfield. I can be contacted as <summer@perlpress.com> -
please include the word 'readonly' in the subject line.

=head1 COPYRIGHT

Copyright (c) Mark Summerfield 2000. All Rights Reserved.

This module may be used/distributed/modified under the same terms as perl
itself. 

=cut
