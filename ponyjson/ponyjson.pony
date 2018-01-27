use "collections"
type JSONType is (JSONObject | JSONArray | String | F64 | I64 | None | Bool)

class JSONArray
    var _values: Array[JSONType] = Array[JSONType](0)
    new create() => None
    new create_with_parser(p: _Parser ref) => _with_parser(p)

    fun ref _with_parser(p: _Parser ref) =>
        p._get_next() // '['
        while true do
            match p.cur
                | '{' => _values.push(JSONObject.create_with_parser(p)); p._expect('}', "JSON: Array: expected object delimiter\n")
                | '[' => _values.push(JSONArray.create_with_parser(p)); p._expect(']', "JSON: Array: expected array delimiter\n")
                | '"' => _values.push(p._parse_string())
                | 't' => 
                    try
                        let t: Bool = p._get_t()?
                        _values.push(t)
                    end
                | 'f' =>
                    try
                        let f: Bool = p._get_f()?
                        _values.push(f)
                    end
                | 'n' =>
                    try
                        let n: None = p._get_n()?
                        _values.push(n)
                    end
                else
                    if p._is_digit(p.cur) then
                        let n = p._parse_num()
                        _values.push(n)
                    end
            end
            
            if p.cur == ']' then
                break
            end
            
            if not p._expect(',', "JSON: Array: expected ','\n") then
                break
            end
        end

    fun apply(idx: USize): JSONType box^ => try _values(idx)? end

    fun values(): ArrayValues[JSONType, this->Array[JSONType]]^ => ArrayValues[JSONType, this->Array[JSONType]](_values)
    fun keys(): ArrayKeys[JSONType, this->Array[JSONType]]^ => ArrayKeys[JSONType, this->Array[JSONType]](_values)
    fun pairs(): ArrayPairs[JSONType, this->Array[JSONType]]^ => ArrayPairs[JSONType, this->Array[JSONType]](_values)


class JSONObject
    var _values: Map[String, JSONType] = Map[String, JSONType]()
    new create() => None
    new create_with_parser(p: _Parser ref) => _with_parser(p)
    

    fun ref _insert_val(key: String, jval: JSONType) =>
        try _values.insert(key, jval)? end

    fun ref _with_parser(p: _Parser ref) =>
        p._get_next() // '{'
        while true do
            if p.cur != '"' then
                p._err("JSON: Object: expected '\"'\n")
                return
            end

            let val_key: String = p._parse_string()

            if not p._expect(':', "JSON: Object: expected ':'\n") then
                return
            end

            var val_val: JSONType = None

            match p.cur
                | '{' => 
                    val_val = JSONObject.create_with_parser(p)
                    p._expect('}', "JSON: Object: expected '}'\n")
                | '[' => 
                    val_val = JSONArray.create_with_parser(p) 
                    p._expect(']', "JSON: Object: expected ']'\n")
                | '"' => val_val = p._parse_string()
                | 'n' => val_val = try p._get_n()? end // null?
                | 't' => val_val = try p._get_t()? end // true?
                | 'f' => val_val = try p._get_f()? end // false?
                | let ch: U32 => 
                    if (p._is_digit(ch)) or (ch == '.') then
                        val_val = p._parse_num()
                    else
                        p._err("invalid value\n")
                        return
                    end
            end

            _insert_val(val_key, val_val)
            if p.cur == '}' then
                break
            end

            if not p._expect(',', "JSON: Object: expected ','\n") then
                @printf[I32]("failed at: %s\n".cstring(), val_key.cstring())
            end
        end

    fun apply(key: String): JSONType box^ => try _values(key)? end

    fun keys(): MapKeys[String, JSONType, HashEq[String], this->Map[String, JSONType]]^ =>
        MapKeys[String, JSONType, HashEq[String], this->Map[String, JSONType]](_values)

    fun values(): MapValues[String, JSONType, HashEq[String], this->Map[String, JSONType]]^ =>
        MapValues[String, JSONType, HashEq[String], this->Map[String, JSONType]](_values)

    fun pairs(): MapPairs[String, JSONType, HashEq[String], this->Map[String, JSONType]]^ =>
        MapPairs[String, JSONType, HashEq[String], this->Map[String, JSONType]](_values)
        
class JSON
    fun from_string(str: String): JSONType =>
        let parser = _Parser(str)
        match parser._get_next()
            | '{' => JSONObject.create_with_parser(parser)
            | '[' => JSONArray.create_with_parser(parser)
            else
                None
        end

class _Parser
    var _pos: ISize = 0
    var cur: U32 = ' '
    var _next: U32 = ' '
    let _buf: String

    fun _is_space(c: U32): Bool => (c == ' ') or ((c >= '\t') and (c <= '\r'))

    fun _is_delim(c: U32): Bool => 
        (c == ',') or (c == '}') or (c == ':') or (c == ']') or (_is_space(c)) or (c == 0)
    
    fun _is_digit(c: U32): Bool => (c >= '0') and (c <= '9')
    
    fun _err(msg: String) => @printf[I32](msg.cstring())
    
    new create(src: String) => _buf = src
    
    fun ref _get_next_raw(): U32 =>
        try
            _inc_pos()
            let chr: (U32, U8) = _buf.utf32(_pos-1)?
            cur = _next = chr._1
        else
            cur = _next = 0
        end

    fun ref _get_next(): U32 =>
        try
            repeat
                _inc_pos()
                let chr: (U32, U8) = _buf.utf32(_pos-1)?
                cur = _next = chr._1
            until not _is_space(cur) end
            cur
        else
            cur = _next = 0
        end
    

    fun ref _expect(chr: U32, msg: String): Bool =>
        if cur == chr then
            _get_next()
            true
        else
            _err(msg)
            false
        end


    fun ref _inc_pos(i: ISize = 1) => _pos = _pos.add(i)

    fun ref _parse_utf16(): I32 =>
        var result: I32 = 0
        var count: U8 = 0
        repeat
            _get_next_raw()
            if _is_digit(cur) then
                result = ((result << 4) or (cur - '0').i32())
            elseif (cur >= 'a') and (cur <= 'f') then
                result = ((result << 4) or ((cur - 'a').i32() + 10))
            elseif (cur >= 'A') and (cur <= 'F') then
                result = ((result << 4) or ((cur - 'A').i32() + 10))
            end
        count = count+1
        until count == 4 end
        result

    fun ref _parse_string(): String =>
        let result = recover String end
        while true do
            _get_next_raw()
            match cur
                | 0 => _err("JSON: _parse_string: expected '\"'\n"); return ""
                | '"' => _get_next(); break
                | '\\' => 
                    match _next
                        | '\\' => result.push('\\'); _get_next_raw()
                        | '"' => result.push('"'); _get_next_raw()
                        | '\'' => result.push('\''); _get_next_raw()
                        | '/' => result.push('/'); _get_next_raw()
                        | 'b' => result.push('\b'); _get_next_raw()
                        | 'f' => result.push('\f'); _get_next_raw()
                        | 'n' => result.push('\n'); _get_next_raw()
                        | 'r' => result.push('\r'); _get_next_raw()
                        | 't' => result.push('\t'); _get_next_raw()
                        | 'u' => 
                            _get_next_raw()
                            var ures = _parse_utf16()
                            if ures < 0 then
                                _err("invalid utf escape\n")
                                break
                            end
                            result.push_utf32(ures.u32())
                    end
                else
                    result.push_utf32(cur.u32())
            end
        end
        result

    fun ref _parse_num(): (I64 | F64) =>
        var result = recover String end
        var is_float = false

        if cur == '-' then
            result.push('-')
            _get_next_raw()
        end

        if cur == '.' then
            result.push('0')
            result.push('.')
            is_float = true
            _get_next_raw()
        else
            while _is_digit(cur) do
                result.push(cur.u8())
                _get_next_raw()
            end
            
            if cur == '.' then
                result.push('.')
                _get_next_raw()
            end
        end

        while _is_digit(cur) do
            result.push(cur.u8())
            _get_next_raw()
        end

        if match cur
            | 'e' => result.push('e'); _get_next_raw(); true
            | 'E' => result.push('E'); _get_next_raw(); true
            else false
            end
        then
            if match cur
                | '+' => result.push('+'); _get_next_raw(); true
                | '-' => result.push('-'); _get_next_raw(); true
                else false
                end
            then
                while _is_digit(cur) do
                    result.push(cur.u8())
                    _get_next_raw()
                end
            end
        end
        var res: (I64 | F64) = I64(0)
        try
            if is_float then
                res = result.f64()
            else
                res = result.i64()?
            end
        end

        if _is_space(cur) then _get_next() end // skip to the next non-whitespace character
        res

    fun ref _get_n(): None? =>
        _get_next_raw() 
        if cur == 'u' then
            _get_nu()?
        else
            error
        end

    fun ref _get_nu(): None? =>
        _get_next_raw()
        if cur == 'l' then
            _get_nul()?
        else
            error
        end
    
    fun ref _get_nul(): None? =>
        _get_next_raw()
        if cur == 'l' then
            _get_next()
            None
        else
            error
        end

    fun ref _get_t(): Bool? =>
        _get_next_raw()
        if cur == 'r' then
            _get_tr()?
        else
            error
        end

    fun ref _get_tr(): Bool? =>
        _get_next_raw()
        if cur == 'u' then
            _get_tru()?
        else 
            error
        end

    fun ref _get_tru(): Bool? =>
        _get_next_raw()
        if cur == 'e' then
            _get_next()
            true
        else
            error
        end

    fun ref _get_f(): Bool? => 
        _get_next_raw()
        if cur == 'a' then
            _get_fa()?
        else
            error
        end

    fun ref _get_fa(): Bool? =>
        _get_next_raw()
        if cur == 'l' then
            _get_fal()?
        else
            error
        end

    fun ref _get_fal(): Bool? =>
        _get_next_raw()
        if cur == 's' then
            _get_fals()?
        else
            error
        end

    fun ref _get_fals(): Bool? =>
        _get_next_raw()
        if cur == 'e' then
            _get_next()
            false
        else
            error
        end
