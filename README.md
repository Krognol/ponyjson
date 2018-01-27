# JSON

## Install

### With stable

`stable add github Krognol/ponyjson`

### Git

`git clone https://github.com/Krognol/ponyjson`

### Usage

```pony
use "ponyjson"

actor Main
    new create(env: Env) =>
        let json = JSON.from_string(
            """
                {
                    "some key": "some value",
                    "other key": [
                        1.34, 123,
                        true, false,
                        null
                    ]
                }
            """
        )

        match json
            | let obj: JSONObject =>
                match obj("some key")
                    | let s: String box => // do something with string
                    else // it was someting else
                end
            else // it wasn't an object
        end
```

### Tests and benchmarks

`cd test && ponyc && ./test`

`cd bench && ponyc && ./bench`

Benchmarks on my machine (Win10, i7-6700K)

```
json object various types          1000000            1818 ns/op
json array various types           1000000            2142 ns/op
json object, long values            200000            9860 ns/op
```