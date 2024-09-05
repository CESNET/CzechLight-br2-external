# https://stackoverflow.com/a/53666584/2245623
# Recursively meld a and b, concatenating arrays and favoring b when there is a conflict
def meld(a; b):
  a as $a | b as $b
  | if ($a|type) == "object" and ($b|type) == "object"
    then reduce ([$a,$b]|add|keys_unsorted[]) as $k ({};
      .[$k] = meld( $a[$k]; $b[$k]) )
    elif ($a|type) == "array" and ($b|type) == "array"
    then $a+$b
    elif $b == null then $a
    else $b
    end;

reduce inputs as $i (.; meld(.; $i))
