#!/usr/bin/perl -w

# $Id$

# Copyright (c) 2000 Mark Summerfield. All Rights Reserved.
# May be used/distributed under the same terms as Perl itself.

# Lots more tests possible -- if you write 'em I'll add 'em!

use strict ;

use vars qw( $Count ) ;
$Count = 0 ;

BEGIN { $| = 1 ; print "1..16\n" ; }

use vars qw( $DEBUG $TRIMWIDTH ) ;
$DEBUG     = shift || 0 ;
$TRIMWIDTH = shift || 250 ;

eval {
    $@ = undef ;
    use readonly 1.02 ; # Version check.
} ;
report( 'version', 0, $@, __LINE__ ) ;


my @a = qw( a b c d e f g ) ;
my %h = ( fred => 'flintstone', barney => 'rubble' ) ;

eval {
    use readonly '$X' => 5 ;
    $X += 1 ;
} ;
report( '+=', 1, $@, __LINE__ ) ;
eval {
    die "$X != 5" if $X != 5 ;
} ;
report( 'readonly', 0, $@, __LINE__ ) ;

eval {
    use readonly '$Y' => 'fred' ;
    $Y = 'barney' ;
} ;
report( '=', 1, $@, __LINE__ ) ;
eval {
    die "$Y ne fred" if $Y ne 'fred' ;
} ;
report( 'readonly', 0, $@, __LINE__ ) ;

eval {
    use readonly '$PI' => 3.142 ;
    $PI = 4 ;
} ;
report( '=', 1, $@, __LINE__ ) ;
eval {
    die "$PI != 3.142" if $PI != 3.142 ;
} ;
report( 'readonly', 0, $@, __LINE__ ) ;

use readonly
        '$A' => 'A',
        '$B' => 'B',
        '$C' => 3,
        '$D' => 4,
        ;

eval {
    $A = 0 ;
} ;
report( '=', 1, $@, __LINE__ ) ;
eval {
    $B = 0 ;
} ;
report( '=', 1, $@, __LINE__ ) ;
eval {
    $C = 0 ;
} ;
report( '=', 1, $@, __LINE__ ) ;

eval {
    $D = 0 ;
} ;
report( '=', 1, $@, __LINE__ ) ;

eval {
    die "$A ne A" if $A ne 'A' ;
} ;
report( 'readonly', 0, $@, __LINE__ ) ;
eval {
    die "$B ne B" if $B ne 'B' ;
} ;
report( 'readonly', 0, $@, __LINE__ ) ;

eval {
    die "$C != 3" if $C != 3 ;
} ;
report( 'readonly', 0, $@, __LINE__ ) ;

eval {
    die "$D != 4" if $D != 4 ;
} ;
report( 'readonly', 0, $@, __LINE__ ) ;


eval {
    $@ = undef ;
    use readonly '$PATH' => '/usr/opt' ;
    use readonly '$EXE'  => "$PATH/bin" ;
    die "\$PATH ne '/usr/opt'"    if $PATH ne '/usr/opt' ;
    die "\$EXE ne '/usr/opt/bin'" if $EXE ne '/usr/opt/bin' ;
} ;
report( 'readonly', 0, $@, __LINE__ ) ;



#eval {
#    use readonly 
#            '$A1' => 'A1',
#            '$M1' => 'M1',
#            '$M4' => 'M4',
#            '$M5'
#            ;
#} ;
#report( 'readonly', 1, $@, __LINE__ ) ;


#eval {
#    $@ = undef ;
#    use readonly '$QQ' => 'abc\\' ; 
#    # $QQ is NOT created.
#} ;
#report( 'readonly', 0, $@, __LINE__ ) ;

#eval {
#    $@ = undef ;
#    use readonly '$EXE'  => "/usr/bin" ;
#} ;
#report( 'redefinition', 1, $@, __LINE__ ) ;

#eval {
#    use readonly '$R' ;
#} ;
#report( 'novalue', 1, $@, __LINE__ ) ;

#eval {
#    $@ = undef ;
#    use readonly 'R' => 99 ;
#} ;
#report( 'no dollar', 1, $@, __LINE__ ) ;

#eval {
#    use readonly '$ARGV' => 99 ;
#} ;
#report( '$ARGV', 1, $@, __LINE__ ) ;




sub report {
    my $test = shift ;
    my $flag = shift ;
    my $e    = shift ;
    my $line = shift ;

    ++$Count ;
    printf "[%03d~%04d] $test(): ", $Count, $line if $DEBUG ;

    if( $flag == 0 and not $e ) {
        print "ok $Count\n" ;
    }
    elsif( $flag == 0 and $e ) {
        $e =~ tr/\n/ / ;
        if( length $e > $TRIMWIDTH ) { $e = substr( $e, 0, $TRIMWIDTH ) . '...' } 
        print "not ok $Count" ;
        print " \a($e)" if $DEBUG ;
        print "\n" ;
    }
    elsif( $flag ==1 and not $e ) {
        print "not ok $Count" ;
        print " \a(error undetected)" if $DEBUG ;
        print "\n" ;
    }
    elsif( $flag ==1 and $e ) {
        $e =~ tr/\n/ / ;
        if( length $e > $TRIMWIDTH ) { $e = substr( $e, 0, $TRIMWIDTH ) . '...' } 
        print "ok $Count" ;
        print " ($e)" if $DEBUG ;
        print "\n" ;
    }
}

