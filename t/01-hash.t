#!/usr/bin/env perl6

use v6.d.PREVIEW;
use Test;
plan 131;

# Hash API conformance tests.

use lib 'lib';
use LinkedHash:auth<github:smls>;

use lib $*PROGRAM.parent.child('lib');
use Test::TypeComparer;

constant T = LinkedHash;


#------ Construction ------

given TypeComparer[T,Hash].new(
  { my % is T },
  { my % },
) {
    .eqv-ok: *.elems, "empty construction - .elems";
    .eqv-ok: *.pairs, "empty construction - .pairs";
}

given TypeComparer[T,Hash].new(
  { my %a is T = () },
  { my %a      = () },
) {
    .eqv-ok: *.elems, "construction with assignment, empty list - .elems";
    .eqv-ok: *.pairs, "construction with assignment, empty list - .pairs";
}

given TypeComparer[T,Hash].new(
  { my %a is T = 'kiwi' => 'green' },
  { my %a      = 'kiwi' => 'green' },
) {
    .eqv-ok: *.elems, "construction with assignment, 1 pair - .elems";
    .eqv-ok: *.pairs, "construction with assignment, 1 pair - .pairs";
}

given TypeComparer[T,Hash].new(
  { my %a is LinkedHash = 'kiwi' => 'green', 'lemon', 'yellow', 'cherry' => 'red', 'lemon' => 'green' },
  { my %a               = 'kiwi' => 'green', 'lemon', 'yellow', 'cherry' => 'red', 'lemon' => 'green' },
) {
    .eqv-ok: *.elems, "construction with assignment, 4 mixed entries - .elems";
    .eqv-ok: *.pairs.sort, "construction with assignment, 4 entries - .pairs";
}

given TypeComparer[T,Hash].new(
  { my %a is LinkedHash = 1, 2, 1 => 2, 3 },
  { my %a               = 1, 2, 1 => 2, 3 },
) {
    .eqv-ok: "construction with assignment, odd number of elements";
}

given TypeComparer[T,Hash].new() {
    .eqv-ok: *.elems, "construction with .new, no arguments - .elems";
    .eqv-ok: *.pairs, "construction with .new, no arguments - .pairs";
}

given TypeComparer[T,Hash].new(()) {
    .eqv-ok: *.elems, "construction with .new, empty list - .elems";
    .eqv-ok: *.pairs, "construction with .new, empty list - .pairs";
}

given TypeComparer[T,Hash].new('kiwi' => 'green') {
    .eqv-ok: *.elems, "construction with .new, 1 pair - .elems";
    .eqv-ok: *.pairs, "construction with .new, 1 pair - .pairs";
}

given TypeComparer[T,Hash].new('kiwi' => 'green', 'lemon', 'yellow', 'cherry' => 'red', 'lemon' => 'green') {
    .eqv-ok: *.elems, "construction with .new, 4 mixed entries - .elems";
    .eqv-ok: *.pairs.sort, "construction with .new, 4 entries - .pairs";
}

given TypeComparer[T,Hash].new(1, 2, 1 => 2, 3) {
    .eqv-ok: "construction with .new, odd number of elements";
}


# ------ Lookup ------

given TypeComparer[T,Hash].new((:kiwi<green>, :lemon<yellow>, :cherry<red>)) {
    .eqv-ok: *<kiwi>, "lookup 1";
    .eqv-ok: *<lemon>, "lookup 2";

    .eqv-ok: *<apple>, "lookup, non-existent";

    .eqv-ok: *<lemon kiwi cherry>, "slice lookup";
    .eqv-ok: *<lemon apple cherry>, "slice lookup, nonexistent";
    .eqv-ok: {.<lemon apple cherry>:v}, "slice lookup, nonexistent, :v";
}


# ------ Assignment ------

given TypeComparer[T,Hash].new {
    .do: { .<kiwi> = 'green'; }
    .eqv-ok: *<kiwi>, "element assignment";
    
    .do: { .<lemon cherry> = <yellow red>; }
    .eqv-ok: *<lemon>, "slice assignment - value 1";
    .eqv-ok: *<cherry>, "slice assignment - value 2";
    .eqv-ok: *.elems, "slice assignment - .elems";
    
    .do: { %^a = :apple<red>, :plum<purple> }
    .eqv-ok: *<apple>, "list assignment - value 1";
    .eqv-ok: *<plum>, "list assignment - value 2";
    .eqv-ok: *<lemon>, "list assignment - value 3";
    .eqv-ok: *.elems, "list assignment - .elems";
}


# ------ Existence and deletion ------

given TypeComparer[T,Hash].new {
    .eqv-ok: {.<kiwi>:exists}, ":exists, non-existent - return value";
    .eqv-ok: *.pairs.sort,     ":exists, non-existent - content";
    .do:     { .<kiwi> = 'green'; }
    .eqv-ok: {.<kiwi>:exists}, ":exists, existent";
    
    .eqv-ok: {.<kiwi>:delete}, ":delete, existent - return value";
    .eqv-ok: *.pairs.sort,     ":delete, existent - content";
    
    
    .eqv-ok: {.<kiwi>:delete}, ":delete, non-existent - return value";
    .eqv-ok: *.pairs.sort,     ":delete, non-existent - content";
}


# ------ Containerization and auto-vivification ------

given TypeComparer[T,Hash].new('Alice' => 'A') {
    .do: { my $alice := .<Alice>;  $alice = 'B'; }
    .eqv-ok: *<Alice>, "lookup returns item container of existing entry";
    
    .do: { my $bob := .<Bob>;  $bob = 'C'; }
    .eqv-ok: *<Bob>, "lookup returns item container that auto-vivifies entry on assignment";
    
    .do: { my $carol := .<Carol>;  $carol[0] = 'A';  $carol[1] = 'D'; }
    .eqv-ok: *<Carol>, "lookup returns item container that auto-vivifies Array entry on subscripting";
    
    .do: { my $dan := .<Dan>;  $dan<A> = '+'; }
    .eqv-ok: *<Dan>, "lookup returns item container that auto-vivifies Hash entry on subscripting";
    
    .do: { my $eve := .<Eve>;  $eve.push: 'B'; }
    .eqv-ok: *<Eve>, "lookup returns item container that auto-vivifies Array entry on .push";
    
    .do: {
        my $frank := .<Frank>;
        my $temp;
        $temp = $frank.defined;
        $temp = $frank.Bool;
        $temp = $frank.List;
        $temp = $frank.elems;
    }
    .eqv-ok: {.<Frank>:!exists}, "lookup returns item container that does not auto-vivify *prematurely*";
}

given TypeComparer[T,Hash].new {
    .eqv-ok: {
        my $x := (.<x> = 5);
        $x++;
        .<x>
    }, "assignment returns item container of newly assigned entry";
    
    .eqv-ok: {
        my $x2 := (.<x> = 10);
        $x2++;
        .<x>
    }, "assignment returns item container of existing entry";
}


# ------ Binding ------

given TypeComparer[T,Hash].new {
    .eqv-ok: {
        my $item;
        %^a<foo> := $item;
        %a<foo> =:= $item
    }, "binding - hash entry and RHS become same container";
}


# ------ Iteration ------

# See 02-insertion-order.t


# ------ .push ------

given TypeComparer[T,Hash].new((:kiwi<green>, :lemon<yellow>, :cherry<red>)) {
    .eqv-ok: {.push((:plum<purple>)) === $_}, ".push, new entry - returns self";
    .eqv-ok: *.pairs.sort,                    ".push, new entry - content";
}

given TypeComparer[T,Hash].new((:kiwi<green>, :lemon<yellow>, :cherry<red>)) {
    .do: { .push((:lemon<green>)); }
    .eqv-ok: *.pairs.sort, ".push, existing entry - content";
}

given TypeComparer[T,Hash].new((:kiwi<green>, :lemon<yellow>, :cherry<red>)) {
    .do: { .push((:plum<purple>, :lemon<green>)); }
    .eqv-ok: *.pairs.sort, ".push, new and existing entry - content";
}

given TypeComparer[T,Hash].new((:apple<red>)) {
    .do: { .push('apple' => <green yellow>); }
    .eqv-ok: *.pairs.sort, ".push, existing entry, List";
}

# ------ .append ------

given TypeComparer[T,Hash].new((:kiwi<green>, :lemon<yellow>, :cherry<red>)) {
    .eqv-ok: {.append((:plum<purple>)) === $_}, ".append, new entry - returns self";
    .eqv-ok: *.pairs.sort,                    ".append, new entry - content";
}

given TypeComparer[T,Hash].new((:kiwi<green>, :lemon<yellow>, :cherry<red>)) {
    .do: { .append((:lemon<green>)); }
    .eqv-ok: *.pairs.sort, ".append, existing entry - content";
}

given TypeComparer[T,Hash].new((:kiwi<green>, :lemon<yellow>, :cherry<red>)) {
    .do: { .append((:plum<purple>, :lemon<green>)); };
    .eqv-ok: *.pairs.sort, ".append, new and existing entry - content";
}

given TypeComparer[T,Hash].new((:apple<red>)) {
    .do: { .append('apple' => <green yellow>); }
    .eqv-ok: *.pairs.sort, ".append, existing entry, List";
}


# ------ .classify-list ------

given TypeComparer[T,Hash].new {
    .eqv-ok: { .classify-list({ <odd even>[$_ %% 2] }, 1..10) === $_ },
        ".classify-list(Block, Range) - returns self";
    .eqv-ok: *.pairs.sort, ".classify-list(Block, Range)";
}

given TypeComparer[T,Hash].new('Sun' => [-1]) {
    my @days = <Mon Tue Wen Thu Fri Sat Sun>;
    .do: *.classify-list(@days, 6, 5, '6');
    .eqv-ok: *.pairs.sort, ".classify-list(Block, Range), existing Array entry";
}

given TypeComparer[T,Hash].new('Sun' => -1) {
    my @days = <Mon Tue Wen Thu Fri Sat Sun>;
    .do: *.classify-list(@days, 6, 5, '6');
    .eqv-ok: *.pairs.sort, ".classify-list(Block, Range), existing non-Array entry";
}

given TypeComparer[T,Hash].new {
    .do: { .classify-list: *.comb, <yet you yen eye>, :as(*.tc); }
    .eqv-ok: *.pairs.sort, ".classify-list(WhateverCode, List, :as), multi-level";
}

given TypeComparer[T,Hash].new {
    .eqv-ok: { .classify-list: { <odd even>[$_ %% 2] }, (1...10).lazy },
        ".classify-list, lazy list";
}

#------ .categorize-list ------

given TypeComparer[T,Hash].new {
    .eqv-ok: {.categorize-list(*.comb, <yet you yen eye>, :as(*.tc)) === $_},
        ".categorize-list(WhateverCode, List, :as) - returns self";
    .eqv-ok: *.pairs.sort, ".categorize-list(WhateverCode, List, :as)";
}

given TypeComparer[T,Hash].new {
  .eqv-ok: { .categorize-list: { <odd even>[$_ %% 2] }, (1...10).lazy },
      ".categorize-list, lazy list";
}

given TypeComparer[T,Hash].new {
    .do: { .categorize-list: *.comb.map({ .uniprop, $_ }), 'A1', 'A2', '123'; }
    .eqv-ok: *.pairs.sort, ".categorize-list(WhateverCode, List), multi-level";
}

#------ .clone ------

given TypeComparer[T,Hash].new((:kiwi<green>, :lemon([<yellow green>]), :cherry<red>)) {
    .eqv-ok: { my %clone := .clone; %clone.^name eqv .^name }, ".clone - same type";
    .eqv-ok: { my %clone := .clone; %clone.pairs.sort }, ".clone - same content";
    .eqv-ok: { my %clone := .clone; %clone !=== $_ }, ".clone - different object";
    todo 'Rakudo bug', 1; # https://github.com/rakudo/rakudo/issues/1997
    .eqv-ok: { my %clone := .clone; %clone<lemon> !=:= .<lemon> }, ".clone - different item containers";
    .eqv-ok: { my %clone := .clone; %clone<lemon> === .<lemon> }, ".clone - same child objects";
    .eqv-ok: { my %clone := .clone; .<kiwi>:delete; %clone<kiwi> }, ".clone - different entry hash";
    .eqv-ok: { my %clone := .clone; .<kiwi>:delete; .<plum> = 'purple'; %clone.pairs.sort }, ".clone - different entry list";
}


#------ methods from Any due to Iterable ------

given TypeComparer[T,Hash].new((:kiwi<green>, :lemon<yellow>, :cherry<red>)) {
    .eqv-ok: *.sort, ".sort";
    .eqv-ok: *.pick(*).sort, ".pick(*)";
    
    my $any-pair = any (:kiwi<green>, :lemon<yellow>, :cherry<red>);
    .eqv-ok: {so .pick eqv $any-pair}, ".pick";
    .eqv-ok: {so .roll eqv $any-pair}, ".roll";
}


#------ Coercion ------

for TypeComparer[T,Hash].new() {
    .eqv-ok: *.Seq,     "empty coercion to .Seq";
    .eqv-ok: *.List,    "empty coercion to .List";
    .eqv-ok: *.Array,   "empty coercion to .Array";
    .eqv-ok: *.Capture, "empty coercion to .Capture";
    .eqv-ok: *.Map,     "empty coercion to .Map";
    .eqv-ok: *.Hash,    "empty coercion to .Hash";
    .eqv-ok: *.Set,     "empty coercion to .Set";
    .eqv-ok: *.SetHash, "empty coercion to .SetHash";
    .eqv-ok: *.Bag,     "empty coercion to .Bag";
    .eqv-ok: *.BagHash, "empty coercion to .BagHash";
    .eqv-ok: *.Mix,     "empty coercion to .Mix";
    .eqv-ok: *.MixHash, "empty coercion to .MixHash";
    .eqv-ok: *.Numeric, "empty coercion to .Numeric";
    .eqv-ok: *.Bool,    "empty coercion to .Bool";
    .eqv-ok: *.Int,     "empty coercion to .Int";
    .eqv-ok: *.UInt,    "coercion to .UInt";
    .eqv-ok: *.Rat,     "coercion to .Rat";
    .eqv-ok: *.FatRat,  "coercion to .FatRat";
    .eqv-ok: *.Complex, "coercion to .Complex";
    .eqv-ok: *.Real,    "coercion to .Real";
    .eqv-ok: *.Num,     "coercion to .Num";
}

for TypeComparer[T,Hash].new((zero => 0, one => 1, two => 2)) {
    .eqv-ok: *.Seq.sort,    "coercion to .Seq";
    .eqv-ok: *.Seq.^name,   "coercion to .Seq - type";
    .eqv-ok: *.List.sort,   "coercion to .List";
    .eqv-ok: *.List.^name,  "coercion to .List - type";
    .eqv-ok: *.Array.sort,  "coercion to .Array";
    .eqv-ok: *.Array.^name, "coercion to .Array - type";
    .eqv-ok: *.Capture,     "coercion to .Capture";
    .eqv-ok: *.Map,         "coercion to .Map";
    .eqv-ok: *.Hash,        "coercion to .Hash";
    .eqv-ok: *.Set,         "coercion to .Set";
    .eqv-ok: *.SetHash,     "coercion to .SetHash";
    .eqv-ok: *.Bag,         "coercion to .Bag";
    .eqv-ok: *.BagHash,     "coercion to .BagHash";
    .eqv-ok: *.Mix,         "coercion to .Mix";
    .eqv-ok: *.MixHash,     "coercion to .MixHash";
    .eqv-ok: *.Numeric,     "coercion to .Numeric";
    .eqv-ok: *.Bool,        "coercion to .Bool";
    .eqv-ok: *.Int,         "coercion to .Int";
    .eqv-ok: *.UInt,        "coercion to .UInt";
    .eqv-ok: *.Rat,         "coercion to .Rat";
    .eqv-ok: *.FatRat,      "coercion to .FatRat";
    .eqv-ok: *.Complex,     "coercion to .Complex";
    .eqv-ok: *.Real,        "coercion to .Real";
    .eqv-ok: *.Num,         "coercion to .Num";
}


#------ Signature binding ------

given TypeComparer[T,Hash].new((zero => 0, one => 1, two => 2)) {
    # This uses .Capture:
    .eqv-ok: { my @pos;    :(*@pos, *%)   := $_;  @pos },
        "Signature binding - positional args";
    .eqv-ok: { my %named;  :(*@, *%named) := $_;  %named },
        "Signature binding - named args";
   
    # This also uses .Capture:
    .eqv-ok: { given $_ -> % (*@pos, *%named) { @pos } },
        "Subsignature binding - positional args";
    .eqv-ok: { given $_ -> % (*@pos, *%named) { %named } },
        "Subsignature binding - named args";
    
    # This currently uses the internal .FLATTENABLE_LIST and .FLATTENABLE_HASH
    # with nqp return values - see https://github.com/rakudo/rakudo/issues/1966:
    todo 'NYI', 3;
    .eqv-ok: { pos-args |$_ }, "Signature slipping - positional args";
    .eqv-ok: { named-args |$_ }, "Signature slipping - named args";
    .eqv-ok: { named-args-unpack |$_ }, "Signature slipping, destructuring - named args";
    
    sub pos-args (*@a, *%) { @a }
    sub named-args (*@, *%a) { %a }
    sub named-args-unpack (:$two, :$zero, *%) { $two, $zero }
}
