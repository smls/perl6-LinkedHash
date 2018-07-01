use v6.d.PREVIEW;
use Test;

unit role TypeComparer[::T1, ::T2];

has T1 $!object1;
has T2 $!object2;
has Exception $!error1;
has Exception $!error2;

multi method new (&factory1, &factory2) {
    self.bless: :&factory1, :&factory2
}
multi method new (**@args, *%args) {
#     dd @args;
#     dd deepclone @args;
    
    self.bless:
        factory1 => { T1.new: |(deepclone @args), |(deepclone %args) },
        factory2 => { T2.new: |(deepclone @args), |(deepclone %args) },
}
submethod BUILD (:&factory1, :&factory2) {
    $!object1 = try factory1;
    $!error1 = $! if $!;
    
    $!object2 = try factory2;
    $!error2 = $! if $!;
}

multi method do (&op) {
    try op $!object1;
    $!error1 = $! if $!;
    
    try op $!object2;
    $!error2 = $! if $!;
}

multi method eqv-ok ($description) {
    my \got = ($!error1 // $!object1);
    my \expected = ($!error2 // $!object2);
    expected.cache;
    
    my $ok = my-cmp-ok got, expected, "$description = {expected.perl}", :died($!error1.so);
#     diag "(at {$caller.file} line {$caller.line})" if !$ok;
    
    $ok
}
multi method eqv-ok (&op, $description) {
    my $caller = callframe(1);
    my \result1 = try-or-exception &op, $!object1<>;
    my \result2 = try-or-exception &op, $!object2<>;
    
    my \got = ($!error1 // result1);
    my \expected = ($!error2 // result2);
    got.cache;
    expected.cache;
    
    my-cmp-ok got, expected, "$description = {expected.perl}", :died($!error1.so);
}

sub my-cmp-ok (\got, \expected, $message, Bool :$died = False) {
    if got eqv expected {
        pass $message;
        True
    }
    else {
        flunk $message;
        my $caller = caller;
        diag "at {$caller.file} line {$caller.line}";
        diag "expected: {expected.perl}";
        diag "     got: {got.perl}";
        diag "{got.Str}\n{got.backtrace}".chomp.indent(10) if $died;
        False
    }
}

sub try-or-exception (&op, |c) {
    my \result = try op |c;
#     dd $!;
    $! // result
}

sub caller {
    my $file = callframe(0).file;
    (1..*).map(&callframe).first({ !.file.match(/^ 'SETTING::' | ^ $file $ /) });
}

sub deepclone ($_) {
#     when Pair     { say "deepclone P: {.perl}"; (deepclone .key) => (deepclone .value) }
#     when Iterable { say "deepclone I: {.perl}"; .new: |.map(&deepclone) }
#     default       { say "deepclone D: {.perl}"; $_ }
    when Pair     { (deepclone .key) => (deepclone .value) }
    when Iterable { .new: |.map(&deepclone) }
    default       { $_ }
}
