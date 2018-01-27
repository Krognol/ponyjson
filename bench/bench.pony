use "ponybench"
use "package:../ponyjson"

actor Main
    new create(env: Env) =>
        let bench = PonyBench(env)

        bench[None]("json object various types", {
            () => 
                JSON.from_string(
                    """
                        {
                            "a": "b",
                            "b": 2,
                            "c": 1.34,
                            "d": true,
                            "null value": null
                        }
                    """
                )
        })

        bench[None]("json array various types", {
            () =>
                JSON.from_string(
                    """
                        [
                            1, 2,
                            {
                                "a": "b",
                                "b": 2,
                                "c": 1.34,
                                "d": true,
                                "really_long key": null
                            },
                            null,
                            false
                        ]
                    """
                )
        })

        bench[None]("json object, long values", {
            () =>
                JSON.from_string(
                    """
                    {
                        "lorem ipsum": "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut in vehicula ipsum. Fusce at risus ut nisi sodales mollis. Integer suscipit porttitor eros accumsan feugiat. Quisque rhoncus lectus sem, at aliquet dolor vehicula nec. Fusce gravida urna a facilisis posuere. Fusce eu fringilla arcu. Vestibulum nec ligula sed justo aliquam tincidunt a in sem. Sed facilisis dapibus nibh, non ultricies ligula tristique ornare.
                        
                        Sed at pharetra nisi. Duis consectetur massa eu erat efficitur egestas. Integer non commodo leo. Fusce eget ultricies nunc, eu mollis magna. Donec maximus magna vel tortor tincidunt, a malesuada est bibendum. Curabitur semper quis lectus eget tempus. Donec nec sem ut turpis iaculis fringilla sed non turpis. Pellentesque id finibus eros, eget ullamcorper dui. Pellentesque ante odio, semper vel orci a, varius tempus ligula. Suspendisse potenti. Aliquam vulputate mi enim, rhoncus consectetur lorem dictum eu. Proin ut risus eu diam pellentesque eleifend.",
                        "pi": 3.141592653589793238462643383279502884197169399375105820974944592307816406286,
                        "various array": [
                            true, true, true,
                            false, false, null,
                            null, "abcd", 1.23,
                            true, false, null
                        ]
                    }
                    """
                )
        })