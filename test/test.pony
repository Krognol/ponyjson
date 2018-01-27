use "package:../ponyjson"
use "ponytest"

actor Main is TestList
    new create(env: Env) =>
        PonyTest(env, this)

    new make() =>
        None
    
    fun tag tests(test: PonyTest) =>
        test(_TestJSONBool)
        test(_TestJSONString)
        test(_TestJSONNull)
        test(_TestJSONArray)
        test(_TestJSONObjectPairs)


class _TestJSONBool is UnitTest 
    fun name(): String => "JSONBool"
    fun apply(h: TestHelper) =>
        let json = JSON.from_string(
            """
                {
                    "foo_bool_true": true,
                    "foo_bool_false": false
                }
            """
        )
        
        match json
            | let obj: JSONObject => 
                match obj("foo_bool_true")
                    | let b: Bool box => h.assert_true((b == true))
                    else h.fail("foo_bool_true != true")
                end

                match obj("foo_bool_false")
                    | let b: Bool box => h.assert_true((b == false))
                    else h.fail("foo_bool_false != false")
                end
            else h.fail()
        end

class _TestJSONString is UnitTest
    fun name(): String => "JSONString"
    fun apply(h: TestHelper) =>
        let json = JSON.from_string(
            """
                {
                    "foo_str": "this is a string",
                    "foo_str_unicode": "this is a string with unicode characters in it: 子馬 \n\u0444",
                    "foo_str_escaped": "this is a string\nwith escaped\ncharacters\""
                }
            """
        )

        match json
            | let obj: JSONObject =>
                match obj("foo_str")
                    | let s: String box => h.assert_true((s != "")); h.log(recover s.clone() end)
                    else h.fail()
                end

                match obj("foo_str_unicode")
                    | let s: String box => h.assert_true((s != "")); h.log(recover s.clone() end)
                    else h.fail()
                end

                match obj("foo_str_escaped")
                    | let s: String box => h.assert_true((s != "")); h.log(recover s.clone() end)
                    else h.fail()
                end
            else h.fail()
        end

class _TestJSONNull is UnitTest 
    fun name(): String => "JSONNull"
    fun apply(h: TestHelper) =>
        let json = JSON.from_string(
            """
                {
                    "some_null_value": null
                }
            """
        )

        match json
            | let obj: JSONObject =>
                match obj("some_null_value")
                    | let _: None box => h.log("Is None")
                    else h.fail()
                end
            else h.fail()
        end

class _TestJSONArray is UnitTest
    fun name(): String => "JSONArray"
    fun apply(h: TestHelper) =>
        let json = JSON.from_string(
            """
                [
                    {
                        "foo": "bar"
                    },
                    {
                        "foo2": "bar2",
                        "foo3": [
                            1, 2, 3
                        ]
                    }
                ]
            """
        )
        
        match json
            | let arr: JSONArray =>
                match arr(0)
                    | let obj: JSONObject box =>
                        match obj("foo")
                            | let _: None box => h.fail()
                        end
                    else h.fail()
                end

                match arr(1)
                    | let obj: JSONObject box =>
                        match obj("foo2")
                            | let _: None box => h.fail()
                        end

                        match obj("foo3")
                            | let objarr: JSONArray box =>
                                match objarr(0)
                                    | let _: None box => h.fail()
                                end
                            else h.fail()
                        end
                    else h.fail()
                end
            else h.fail()
        end

class _TestJSONObjectPairs is UnitTest 
    fun name(): String => "JSONObject Pairs"
    fun apply(h: TestHelper) =>
        let json = JSON.from_string(
            """
                {
                    "a": "b",
                    "c": 2,
                    "d": 1.34
                }
            """
        )

        match json
            | let obj: JSONObject =>
                let pairs = obj.pairs()
                while pairs.has_next() do
                    try
                        let pair = pairs.next()?
                        match pair._2
                            | let s: String => h.log("'"+pair._1+"' has "+s)
                            | let i: I64 => h.log("'"+pair._1+"' has " + i.string())
                            | let f: F64 => h.log("'"+pair._1+"' has " + f.string())
                        end
                    end
                end
            else h.fail()
        end