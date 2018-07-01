#!/usr/bin/env perl6

use v6.d.PREVIEW;
use Test;
plan 18;

# Tests to validate that `LinkedHash` preserves insertion order.

use lib 'lib';
use LinkedHash:auth<github:smls>;


#------ Iteration ------

subtest {
    plan 21;
    my %fruit is LinkedHash;
    
    %fruit<kiwi>   = "green";
    %fruit<banana> = "yellow";
    %fruit<cherry> = "red";
    %fruit<plum>   = "purple";
    %fruit<lemon>  = "yellow";
    
    is-deeply %fruit.keys,      <kiwi banana cherry plum lemon>, ".keys";
    is-deeply %fruit.values,    <green yellow red purple yellow>, ".values";
    is-deeply %fruit{*},        <green yellow red purple yellow>, ".\{*} slice";
    is-deeply %fruit.kv,        <kiwi green banana yellow cherry red plum purple lemon yellow>, ".kv";
    is-deeply %fruit.pairs,     (:kiwi<green>, :banana<yellow>, :cherry<red>, :plum<purple>, :lemon<yellow>), ".pairs";
    is-deeply %fruit.antipairs, (:green<kiwi>, :yellow<banana>, :red<cherry>, :purple<plum>, :yellow<lemon>), ".antipairs";
    is-deeply %fruit.invert,    (:green<kiwi>, :yellow<banana>, :red<cherry>, :purple<plum>, :yellow<lemon>), ".invert";
    is-deeply %fruit.list,      (:kiwi<green>, :banana<yellow>, :cherry<red>, :plum<purple>, :lemon<yellow>), ".list";
    is-deeply %fruit.flat,      (:kiwi<green>, :banana<yellow>, :cherry<red>, :plum<purple>, :lemon<yellow>), ".flat";
    is-deeply %fruit.List,      (:kiwi<green>, :banana<yellow>, :cherry<red>, :plum<purple>, :lemon<yellow>), ".List";
    is-deeply %fruit.Array,     [:kiwi<green>, :banana<yellow>, :cherry<red>, :plum<purple>, :lemon<yellow>], ".Array";
    
    is-deeply %fruit.head,      (:kiwi<green>), ".head";
    is-deeply %fruit.head(2),   (:kiwi<green>, :banana<yellow>), ".head(2)";
    is-deeply %fruit.tail,      (:lemon<yellow>), ".tail";
    is-deeply %fruit.tail(2),   (:plum<purple>, :lemon<yellow>), ".tail(2)";
    is-deeply %fruit.skip,      (:banana<yellow>, :cherry<red>, :plum<purple>, :lemon<yellow>), ".skip";
    is-deeply %fruit.skip(2),   (:cherry<red>, :plum<purple>, :lemon<yellow>), ".skip(2)";
    
    is-deeply %fruit.fmt, "kiwi\tgreen\nbanana\tyellow\ncherry\tred\nplum\tpurple\nlemon\tyellow", ".fmt";
    is-deeply %fruit.fmt("«%s»", ' '), '«kiwi» «banana» «cherry» «plum» «lemon»', ".fmt - one format token, custom separator";
    is-deeply %fruit.fmt('| %2$6s %-6s |'), q:to[END].chomp, ".fmt - two format tokens";  # :
        |  green kiwi   |
        | yellow banana |
        |    red cherry |
        | purple plum   |
        | yellow lemon  |
        END
    
    my @keys;
    @keys.push($_) for %fruit;
    is-deeply @keys, [:kiwi<green>, :banana<yellow>, :cherry<red>, :plum<purple>, :lemon<yellow>], "for loop";
}, "with 5 values";


subtest {
    plan 21;
    my %fruit is LinkedHash;
    
    is-deeply %fruit.keys,      (), ".keys";
    is-deeply %fruit.values,    (), ".values";
    is-deeply %fruit{*},        (), ".\{*} slice";
    is-deeply %fruit.kv,        (), ".kv";
    is-deeply %fruit.pairs,     (), ".pairs";
    is-deeply %fruit.antipairs, (), ".antipairs";
    is-deeply %fruit.invert,    (), ".invert";
    is-deeply %fruit.list,      (), ".list";
    is-deeply %fruit.flat,      (), ".flat";
    is-deeply %fruit.List,      (), ".List";
    is-deeply %fruit.Array,     [], ".Array";
    
    is-deeply %fruit.head,      Nil, ".head";
    is-deeply %fruit.head(2),   (), ".head(2)";
    is-deeply %fruit.tail,      Nil, ".tail";
    is-deeply %fruit.tail(2),   (), ".tail(2)";
    is-deeply %fruit.skip,      (), ".skip";
    is-deeply %fruit.skip(2),   (), ".skip(2)";
    
    is-deeply %fruit.fmt,                   '', ".fmt";
    is-deeply %fruit.fmt("«%s»", ' '),      '', ".fmt - one format token, custom separator";
    is-deeply %fruit.fmt('| %2$6s %-6s |'), '', ".fmt - two format tokens";  # :
    
    my @keys;
    @keys.push($_) for %fruit;
    is-deeply @keys, [], "for loop";
}, "with 0 values";


#------ Deletion ------

subtest {
    plan 3;
    # Integers from 1 to 100, but in a weird order.
    my @numbers = (61 * $_ mod 101 for 1..100);
    my @pairs = @numbers Z=> 1..*;
    my %hash is LinkedHash = @pairs;
    
    is-deeply %hash.pairs, @pairs.List, ".pairs before deletions";
    
    my @even;
    for @pairs {
        if .key %% 2 { @even.push: $_ }
        else         { %hash{.key}:delete }
    }
    
    is-deeply %hash.pairs, @even.List, ".pairs after deletions";
    is-deeply %hash.elems, @even.elems, ".elems";
    
}, "with 100 values and 50 deletions";


#------ .push ------

{
    my %fruit is LinkedHash = :kiwi<green>, :lemon<yellow>, :cherry<red>;
    
    my \ret = %fruit.push: (:plum<purple>);
    is-deeply
        %fruit.pairs.sort,
        (:kiwi<green>, :lemon<yellow>, :plum<purple>, :cherry<red>).sort,
        ".push - new entry";
    cmp-ok ret, '===', %fruit, ".push - new entry - return value";
}

{
    my %fruit is LinkedHash = :kiwi<green>, :lemon<yellow>, :cherry<red>;
    
    my \ret = %fruit.push: (:lemon<green>);
    is-deeply
        %fruit.pairs.sort,
        (:cherry<red>, :kiwi<green>, :lemon($[<yellow green>])),
        ".push - existing entry";
    cmp-ok ret, '===', %fruit, ".push - existing entry - return value";
}

{
    my %fruit is LinkedHash = :kiwi<green>, :lemon<yellow>, :cherry<red>;
    
    my \ret = %fruit.push: (:plum<purple>, :lemon<green>);
    is-deeply
        %fruit.pairs,
        (:kiwi<green>, :lemon($[<yellow green>]), :cherry<red>, :plum<purple>),
        ".push - new and existing entry";
    cmp-ok ret, '===', %fruit, ".push - new and existing entry - return value";
}

{
    my %fruit is LinkedHash = :apple<red>;
    %fruit.push: 'apple' => <green yellow>;
    is-deeply %fruit.pairs, (:apple($['red', <green yellow>]),), ".push, existing entry, List";
}


#------ .append ------

{
    my %fruit is LinkedHash = :kiwi<green>, :lemon<yellow>, :cherry<red>;
    
    my \ret = %fruit.append;
    is-deeply
        %fruit.pairs,
        (:kiwi<green>, :lemon<yellow>, :cherry<red>),
        ".append - no arguments";
}

{
    my %fruit is LinkedHash = :kiwi<green>, :lemon<yellow>, :cherry<red>;
    
    my \ret = %fruit.append: (:plum<purple>, :lemon<green>);
    is-deeply
        %fruit.pairs,
        (:kiwi<green>, :lemon($[<yellow green>]), :cherry<red>, :plum<purple>),
        ".append - new and existing entry";
}

{
    my %fruit is LinkedHash = :apple<red>;
    %fruit.append: 'apple' => <green yellow>;
    is-deeply %fruit.pairs, (:apple($[<red green yellow>]),), ".append, existing entry, List";
}


#------ .classify-list ------

{
    my %n is LinkedHash;
    %n.classify-list: { <odd even>[$_ %% 2] }, 1..10;
    is-deeply
        %n.pairs,
        (odd => [1, 3, 5, 7, 9], even => [2, 4, 6, 8, 10]),
        ".classify-list(Block, Range)";
}

{
    my @days = <Mon Tue Wen Thu Fri Sat Sun>;
    my %days is LinkedHash = Sun => [-1];
    %days.classify-list: @days, 6, 5, <6>;
    is-deeply
        %days.pairs,
        (Sun => $[-1, 6, <6>], Sat => $[5]),
        ".classify-list(Array, Range)";
}

{
    my %trie is LinkedHash;
    %trie.classify-list: *.comb, <yet you yen eye>, :as(*.tc);
    is-deeply %trie.pairs, (
        y => ${
            e => { t => ['Yet'],
                   n => ['Yen'], },
            o => { u => ['You'], },
        },
        e => ${
            y => { e => ['Eye'], },
        },
    ), ".classify-list(WhateverCode, List, :as) - multi-level";
}


#------ .categorize-list ------

{
    my %trie is LinkedHash;
    %trie.categorize-list: *.comb, <yet you yen eye>, :as(*.tc);
    is-deeply %trie.pairs, (
        y => $[<Yet You Yen Eye>],
        e => $[<Yet Yen Eye Eye>],
        t => $[<Yet>],
        o => $[<You>],
        u => $[<You>],
        n => $[<Yen>],
    ), ".categorize-list(WhateverCode, List, :as)";
}

# X::Invalid::ComputedValue.new(method => "categorize-list", name => "mapper", value => "an item with different number of elements in it than previous items", reason => "all values need to have the same number of elements. Mixed-level classification is not supported.")

#------ .clone ------

{
    my %fruit is LinkedHash = :kiwi<green>, :lemon([<yellow green>]), :cherry<red>;
    my %fruit2 := %fruit.clone;
    is-deeply %fruit2.pairs, (:kiwi<green>, :lemon([<yellow green>]), :cherry<red>), ".clone - same content";
}
