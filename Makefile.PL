use ExtUtils::MakeMaker ;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 'readonly',
    'VERSION_FROM' => 'readonly.pm', # finds $VERSION
    'DISTNAME'     => 'readonly',
    ($] >= 5.005 ?
        (
            ABSTRACT => 'Pragma & function module to create readonly scalars',
            AUTHOR   => 'Mark Summerfield <summer@perlpress.com>',
        ) : () ),
    'LIBS'         => [''],   # e.g., '-lm'
    'DEFINE'       => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'          => '',     # e.g., '-I/usr/include/other'
    'dist'         => { COMPRESS => "gzip -9", SUFFIX => "gz" }
) ;
