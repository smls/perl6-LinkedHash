# NAME

LinkedHash - A Hash map with insertion-order iteration and navigation.

# SYNOPSIS

``` Perl 6
use v6;
use LinkedHash:auth<github:smls>;

my %steps is LinkedHash =
    add  => "Add all cookie ingredients.",
    mix  => "Mix until your hands hurt.",
    roll => "Roll out the dough into small balls."
;

%steps<mix> = "Mix until smooth.";    # updated but not moved
%steps<bake> = "Bake until golden.";  # inserted at the end

# Iterating:

say %steps.keys;       # (add mix roll bake)
say %steps.values;     # ..same order..
say %steps.kv;         # ..same order..
for %steps -> $pair {  # ..same order..
    ...
}
```

# DESCRIPTION

This module provides a hash map type for Perl 6 which behaves the same as the
built-in [Hash](https://docs.perl6.org/type/Hash) type, except that it:

* Makes sure that iterating over the entries returns them in the order in
  which they were inserted, rather than in a randomized order.
* Has some limitations (see [#LIMITATIONS](#limitations)).
* Will hopefully expose some kind of "linked list" navigation API in the
  future (see [#TODO](#todo)).

It's implemented by internally keeping a linked list between hash entries, where
each entry knows the ones inserted directly before and after it.

## Performance characteristics

The `LinkedHash` type makes the following computational complexity guarantees:

| operation                            | time complexity class                |
|--------------------------------------|--------------------------------------|
| looking up an entry by key           | same as `Hash`                       |
| inserting/removing an entry          | same as `Hash`                       |
| iterating over all entries           | O(n)                                 |
| starting iteration at a specific key | like lookup, but API not exposed yet |
| navigating to a neighboring entry    | O(1), but API not exposed yet        |

It has the following memory characteristics:

* Requires more memory than a Hash.
* When an entry is deleted with the `:delete` adverb, none of it is retained 
(to the extent that Hash doesn't either), so you don't have to worry about 
memory leaks or slow-downs when adding and removing entries frequently.

# API

## Constructing

The assignment operator works the same as for the built-in Hash type, accepting
`Pair`s and/or alternating keys and values:

``` Perl 6
my %fruit is LinkedHash =
    'kiwi' => 'green',
    'lemon' => 'yellow',
    'cherry' => 'red',
;

my %fruit is LinkedHash =
    'kiwi', 'green', 'lemon', 'yellow', 'cherry', 'red';
```

Same for the `.new` constructor:

``` Perl 6
my %fruit := LinkedHash.new(
    'kiwi', 'green', 'lemon' => 'yellow', 'cherry', 'red');
```

## Subscripting

Same as for [Hash](https://docs.perl6.org/type/Hash) - refer to the Perl 6
[Subscripts](https://docs.perl6.org/language/subscripts) documentation page.

All the adverbs (`:k`, `:v`, `:kv`, `:p`, `:exists`, `:delete`) are supported.

## Filling

Values can be added to a `LinkedHash` in the same ways as to a
[`Hash`](https://docs.perl6.org/type/Hash):

* By assigning to a `%`-sigiled variable bound to the `LinkedHash` *(see
  [#Constructing](#constructing))*.
* By assigning to a subscript *(see [#Subscripting](#subscripting))*.
* Using one of the four entry-adding methods &ndash; refer to their description
  in the Perl 6 `Hash` documentation:
  * [`.push`](https://docs.perl6.org/type/Hash#method_push)
  * [`.append`](https://docs.perl6.org/type/Hash#method_append)
  * [`.classify-list`](https://docs.perl6.org/type/Hash#method_classify-list)
  * [`.categorize-list`](https://docs.perl6.org/type/Hash#method_categorize-list)

## Iterating

Same as with [`Hash`](https://docs.perl6.org/type/Hash), except that entries are
returned in insertion order.

Insertion order is defined as follows:

* When a new hash entry is created (i.e. for a key that does not yet exist in
  the hash, as reported by the `:exists` adverb), then it is placed at the
  *end*.
* When the value of an *existing* hash entry is assigned to or otherwise
  modified, its place in the iteration order does *not* change.
* When a hash entry is *deleted* (with the `:delete` adverb), it is as if it
  was never there, and re-adding the same key adds it to the end again.

Refer to the description of the respective methods in the Perl 6
[`Hash`](https://docs.perl6.org/type/Hash) documentation:

 * [`.elems`](https://docs.perl6.org/type/Hash#method_elems)
 * [`.keys`](https://docs.perl6.org/type/Hash#method_keys)
 * [`.values`](https://docs.perl6.org/type/Hash#method_values)
 * [`.kv`](https://docs.perl6.org/type/Hash#method_kv)
 * [`.pairs`](https://docs.perl6.org/type/Hash#method_pairs)
 * [`.antipairs`](https://docs.perl6.org/type/Hash#method_antipairs)
 * [`.invert`](https://docs.perl6.org/type/Hash#method_invert)
 * [`.iterator`](https://docs.perl6.org/type/Hash#method_invert)

## Nagivating

Not yet implemented, see [#TODO](#todo).

## Serializing

Same as with [`Hash`](https://docs.perl6.org/type/Hash); Refer to the
description of the respective methods in the Perl 6 documentation:

 * `.Str`
 * [`.gist`](https://docs.perl6.org/type/Hash#method_gist)
 * `.perl`
 * [`.fmt`](https://docs.perl6.org/type/Hash#%28Cool%29_method_fmt)

## Coercing

The following coercion method are available on `LinkedHash` instances, with the
same behavior as on a [`Hash`](https://docs.perl6.org/type/Hash) (except that
insertion order is preserved when coercing to list-like types):

    .Array .Bag .BagHash .Bool .Capture .Complex .FatRat .Hash .hash .Int .List
    .list .Mix .MixHash .Num .Numeric .Rat .Real .Seq .Set .SetHash .Str .UInt

# LIMITATIONS

* Slower than a normal Hash for things which they both support.

* Does not support direct slipping into argument lists like a normal Hash
  does (e.g. `some-function |%foo`) &ndash; Rakudo issue
  [#1966](https://github.com/rakudo/rakudo/issues/1966) will need to be
  resolved first. As a work-around, use `some-function |%foo.Hash` for now.

* Does not support default values like a normal Hash does (e.g.
  `my %foo is default(42)`).

* Does not support parameterization like a normal Hash does (e.g.
  `Hash[Int, Any]`).

* There are no coercion methods *from* other built-in types, like are
  available for a normal Hash (e.g. `@pairs.Hash`).

Some of these may change in future releases.

# THREAD-SAFETY

Same as [`Hash`](https://docs.perl6.org/type/Hash), which is to say:

* It is *not* safe to simultaneously modify the same LinkedHash object on 
different threads, or to read from it on one thread while another modifies it.

* It *is* safe to simultaneously read from the same LinkedHash object on 
different threads, or to read/modify *different*  LinkedHash objects on 
different threads.

# TODO

For this first alpha release, the "Linked" part is merely an implementation
detail. In future releases, I'd like to expose some of the O(1) navigation
features that the underlying doubly linked list makes possible, for example:

``` Perl 6
# Looking up neighboring entries (conjectural):

say %steps<mix>:pred;    # Add all cookie ingredients.
say %steps<mix>:pred:k;  # add
say %steps<mix>:succ:k;  # roll

# Starting iteration at specific entries (conjectural):

say %steps<mix>:to-end:k;    # (mix roll bake)
say %steps<mix>:to-start:k;  # (mix add)
```

...but I'm not yet sure how practical it really is to add adverbs to the `.{ }`
postcircumfix operator, or if there's a better way to design this API.

Furthermore, I'd like to eventually figure out if it would be both sensible and
feasible to:

* Let `LinkedHash` inherit from `Hash` (or maybe `Map`).
* Let `.hash` return `self` instead of `.Hash`.
* Let nested Hashes created by auto-vivification be `LinkedHash`es themselves.
* Let nested Hashes created by `.push`, `.append`, `.classify-list`, and
  `.categorize-list` be `LinkedHash`es themselves.
* Use a custom implementation for the `Seq`s (or associated `Iterator`s) which
  are returned from the iteration methods, so as to improve the performance of
  things like:  
  ``` Perl 6
  %h.values.tail   # Could immediately return the last element!
  %h.keys.reverse  # Could immediately go backwards from the last element!
  ```

* Implement the missing features listed under [#LIMITATIONS](#limitations).

# CONTRIBUTING

If you find bugs (including any undocumented discrepancies in behavior between
this type and the built-in Hash type), or want to help with implementing more
features, please file an
[issue](https://github.com/smls/perl6-LinkedHash/issues) or send a
[pull request](https://github.com/smls/perl6-LinkedHash).

# SEE ALSO

This module was inspired by Java's 
[`LinkedHashMap`](https://docs.oracle.com/javase/8/docs/api/java/util/LinkedHashMap.html).

Similar Perl 6 modules:

* [`OrderedHash` by FCO](https://github.com/FCO/OrderedHash)
* [`ArrayHash` by zostay](https://github.com/zostay/perl6-ArrayHash)

# AUTHOR

Sam S. (smls), smls75@gmail.com

# VERSION

0.1

(Note: this is alpha-stage software; the API may still change.)

# LICENSE

This is free software; you can redistribute it and/or modify it under the terms 
of the Artistic License 2.0 (see the accompanying LICENSE file).
