use v6.d.PREVIEW;

unit class LinkedHash:ver<0.1>:auth<github:smls> is Cool does Associative does Iterable;

class Entry {...}

has Entry %!entries;
has Entry $!first;
has Entry $!last;


#---- Constructing ----

method new (*@pairs) {
    self.bless: :@pairs;
}

submethod BUILD (:@pairs) {
    for normalize-pairs @pairs {
        self!assign: .key, .value;
    }
}

#| Called when a % variable bound to a LinkedHash is assigned to.
multi method STORE(LinkedHash:D: *@pairs --> LinkedHash:D) {
    %!entries = ();
    $!first = Nil;
    $!last = Nil;
    for normalize-pairs @pairs {
        self!assign: .key, .value;
    }
    self
}

multi method clone(LinkedHash:D: --> LinkedHash:D) {
    self.new(self.pairs);
}


#---- Coercing ----

multi method Bool    (LinkedHash:D: --> Bool:D)    { ?%!entries }
multi method Numeric (LinkedHash:D: --> Int:D)     { %!entries.elems }
multi method List    (LinkedHash:D: --> List:D)    { self.list.List }
multi method Capture (LinkedHash:D: --> Capture:D) { self.pairs.Capture }

# Coercers already provided by class Any:
#   .Seq, .Array, .Hash, .hash,
#   .Set, .SetHash, .Bag, .BagHash, .Mix, .MixHash
# Coercers already provided by role Cool:
#   .Int .UInt .Rat .FatRat .Complex .Real .Num


#---- Serializing ----

multi method Str (LinkedHash:D: --> Str) {
    self.pairs.map({ .key ~ "\t" ~ .value }).join("\n")
}

multi method gist (LinkedHash:D: --> Str) {
    '{' ~ self.pairs.map(*.gist).head(100).join(', ')
        ~ (', ...' if .elems > 100) ~ '}'
}

multi method perl (LinkedHash:D: --> Str) {
    'LinkedHash.new((' ~ self.pairs.map(*.perl).join(', ') ~ '))'
}

multi method fmt (LinkedHash:D: Cool $format = "%s\t%s", $sep = "\n" --> Str) {
    return self.pairs.map({ sprintf $format, .key, .value }).join($sep);

    # A bit of a hack, but less error-prone than manually parsing $format to
    # find the number of sprintf-style format tokens...
    CATCH {
        when X::Str::Sprintf::Directives::Count {
            return self.keys.map({ sprintf $format, $_ }).join($sep);
        }
    }
}


#---- Iterating ----

method elems (LinkedHash:D: --> Int:D) {
  %!entries.elems
}
method iterator (LinkedHash:D: --> Iterator) {
  self!pairs-from($!first).iterator
}

multi method list      (LinkedHash:D: --> Seq) { self!pairs-from($!first) }
multi method pairs     (LinkedHash:D: --> Seq) { self!pairs-from($!first) }
multi method antipairs (LinkedHash:D: --> Seq) { self!antipairs-from($!first) }
multi method keys      (LinkedHash:D: --> Seq) { self!keys-from($!first) }
multi method values    (LinkedHash:D: --> Seq) { self!values-from($!first) }
multi method kv        (LinkedHash:D: --> Seq) { self!kv-from($!first) }


#---- Signature slipping ----

# No way to do this yet without NPQ; see https://github.com/rakudo/rakudo/issues/1966
# So, simply throw an Exception for now.
method FLATTENABLE_LIST {
    X::NYI.new( feature => "Slipping a LinkedHash into an argument list",
                workaround => "use |%foo.Hash" ).throw;
}
method FLATTENABLE_HASH {
    X::NYI.new( feature => "Slipping a LinkedHash into an argument list",
                workaround => "use |%foo.Hash" ).throw;
}


#---- Subscripting ----

multi method EXISTS-KEY(LinkedHash:D: $key) {
    %!entries{$key}:exists;
}

multi method AT-KEY(LinkedHash:D: $key) is rw {
    my \slot = %!entries{$key};
    
    if slot.defined {
        slot.value
    }
    else {
        self!autovivifying-proxy(slot, $key)
    }
}

multi method ASSIGN-KEY(LinkedHash:D: $key, $value) is rw {
    self!assign: $key, $value
}

multi method BIND-KEY(LinkedHash:D: $key, $container is rw) is rw {
    my $entry = self!entry($key);
    $entry.bind-value($container);
    $container
}

multi method DELETE-KEY(LinkedHash:D: $key) {
    my $entry = %!entries{$key}:delete;
    
    if $entry.defined {
        self!detach-from-list($entry);
        $entry.value
    }
    else {
        Any
    }
}


#---- Filling ----

multi method push(LinkedHash:D: +@pairs --> LinkedHash:D) {
    for normalize-pairs @pairs {
        self!push: .key, .value;
    }
    self
}
multi method append(LinkedHash:D: +@pairs --> LinkedHash:D) {
    for normalize-pairs @pairs {
        self!push: .key, .value, True;
    }
    self
}

multi method classify-list(LinkedHash:D: &mapper, *@list, :&as --> LinkedHash:D) {
    if @list.is-lazy {
        X::Cannot::Lazy.new(action => "classify", what => Any).throw
    }
    for @list {
        my \category = mapper $_;
        my $value = &as ?? (as $_) !! $_;
        self!strict-deep-push: category, $value;
    }
    self
}
multi method classify-list(LinkedHash:D: %mapper, *@list, :&as --> LinkedHash:D) {
    self.classify-list: { %mapper{$_}<> }, @list, :&as
}
multi method classify-list(LinkedHash:D: @mapper, *@list, :&as --> LinkedHash:D) {
    self.classify-list: { @mapper[$_]<> }, @list, :&as
}

multi method categorize-list(LinkedHash:D: &mapper, *@list, :&as --> LinkedHash:D) {
    if @list.is-lazy {
        X::Cannot::Lazy.new(action => "categorize", what => Any).throw
    }
    for @list {
        my \categories = mapper $_;
        my $value = &as ?? (as $_) !! $_;
        for categories -> \category {
            self!strict-deep-push: category, $value;
        }
    }
    self
}
multi method categorize-list(LinkedHash:D: %mapper, *@list, :&as --> LinkedHash:D) {
    self.classify-list: { %mapper{$_}<> }, @list, :&as
}
multi method categorize-list(LinkedHash:D: @mapper, *@list, :&as --> LinkedHash:D) {
    self.categorize-list: { @mapper[$_]<> }, @list, :&as
}


#===============================================================================

#---- Private methods - Subscripting and modifying ----

#| Add an entry; If it already exists, overwrite its value.
#| Return the value container.
method !assign(LinkedHash:D: $key, $value) is rw {
    my \slot = %!entries{$key};
    
    if slot.defined {
        slot.value = $value;
    }
    else {
        slot = self!new-entry($key, $value);
    }
    slot.value
}

#| Add an entry; If it already exists, promote its value to an Array and push
#| the new value to it.
method !push(LinkedHash:D: $key, \value, Bool $slip = False) {
    my \slot = %!entries{$key};
    if slot.defined {
        given slot.value {
            when Array {
                if $slip { .append: value; }
                else     { .push: value; }
            }
            default {
                if $slip { $_ = [$_<>, |value]; }
                else     { $_ = [$_<>, value]; }
            }
                
        }
    }
    else {
        slot = self!new-entry($key, value);
    }
    Nil
}

#| Add an entry using a potentially multi-level key, creating `Hash`es for the
#| intermediate levels and an `Array` at the deepest level (if they don't
#| already exist), and push the value onto the array.
#| Do *not* promote existing values to Hash/Array.
method !strict-deep-push(\path, $value) {
    my $container := self!entry(path[0]).value;
    for path[1..*] {
        $container := $container{$_};
    }
    $container.push: $value;
}

#| Look up an entry; If it doesn't exist yet, create it.
method !entry(LinkedHash:D: $key --> Entry:D) {
    my \slot = %!entries{$key};
    slot = self!new-entry($key, Nil) if !slot.defined;
    slot
}

#| Create a new entry at then end of the doubly linked list, and return its
#| Entry object. (It is, at that point, not yet present in the hash table.)
method !new-entry($key, $value) {
    my $entry = Entry.new(:$key, :$value);
    
    if ($!last.defined) {
        $entry.pred = $!last;
        $!last.succ = $entry;
        $!last = $entry;
    }
    else {
        $!first = $entry;
        $!last = $entry;
    }
    $entry
}

method !detach-from-list ($entry) {
    if ($entry.pred.defined) {
        $entry.pred.succ = $entry.succ;
    }
    else {
        $!first = $entry.succ;
    }
    
    if ($entry.succ.defined) {
        $entry.succ.pred = $entry.pred;
    }
    else {
        $!last = $entry.pred;
    }
    
    Nil
}

#| Create an item container that automatically creates a hash entry when
#| assigned to, and a hash entry of type `Hash` or `Array` when subscripted or
#| pushed to like an Array or Hash, respectively.
method !autovivifying-proxy(\slot, $key) is rw {
    my $self = self;
    my Bool $stored = False;
    
    # FETCH may get called many times (much more than one would expect), so
    # it needs to be fast. A closed-over lexical variable is probably the
    # best we can do - and it also gives us Array/Hash auto-vivification
    # for free.
    my $container;
    
    Proxy.new:
        FETCH => method () {
            $container
        },
        STORE => method ($value) {
            if !$stored {  # Not thread-safe, but that's OK.
                $stored = True;
                slot = $self!new-entry($key, Nil);
                slot.bind-value: $container;
            }
            $container = $value;
        },
}


#---- Private methods - Iterating ----

method !keys-from (Entry $entry is copy) {
    gather {
        while $entry.defined {
            take $entry.key;
            $entry = $entry.succ;
        }
    }
}

method !values-from (Entry $entry is copy) {
    gather {
        while $entry.defined {
            take-rw $entry.value;
            $entry = $entry.succ;
        }
    }
}

method !kv-from (Entry $entry is copy) {
    gather {
        while $entry.defined {
            take $entry.key;
            take-rw $entry.value;
            $entry = $entry.succ;
        }
    }
}

method !pairs-from (Entry $entry is copy) {
    gather {
        while $entry.defined {
            take ($entry.key => $entry.value);
            $entry = $entry.succ;
        }
    }
}

method !antipairs-from (Entry $entry is copy) {
    gather {
        while $entry.defined {
            take ($entry.value => $entry.key);
            $entry = $entry.succ;
        }
    }
}


#---- Private functions ----

#| Take a list of Pair elements and/or consecutive key and value elements,
#| and pair up the latter so as to return a list of Pair elements.
sub normalize-pairs (@values --> Seq) {
    gather {
        my Bool $found-key = False;
        my $key;
        my $pair-count = 0;
        
        for @values -> $value {
            if $found-key {
                take $key => $value;
                $found-key = False;
            }
            elsif $value ~~ Pair {
                take $value;
                $pair-count++;
            }
            else {
                $key = $value;
                $found-key = True;
            }
        }
        if $found-key {
            X::Hash::Store::OddNumber.new(
                found => (@values + 1 + $pair-count) div 2,
                last => $key
            ).throw;
        }
    }
}


#---- Private classes ----

#| Represents a LinkedHash entry
class Entry {
    has Entry $.pred is rw;
    has Entry $.succ is rw;
    
    has $.key;
    has $.value is rw;
    
    method bind-value ($value is rw) {
        $!value := $value;
    }
}
