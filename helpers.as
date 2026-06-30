enum TokenType {
    CurlyBracketL,
    CurlyBracketR,
    String,
    Number,
    SquareBracketL,
    SquareBracketR,
    Comma,
    Colon,
    EOF
}

class Token {
    TokenType tokentype;
    int int_value;
    string str_value;

    Token() {
        this.tokentype = TokenType::EOF;
        this.int_value = 0;
        this.str_value = "";
    }

    Token(TokenType type) {
        this.tokentype = type;
    }

    Token(TokenType type, int value) {
        this.tokentype = type;
        this.int_value = value;
    }

    Token(TokenType type, string value) {
        this.tokentype = type;
        this.str_value = value;
    }
}

enum KWType {
    KW_String,
    KW_Number,
    KW_Array
}
// I meant to call this KV for key value, but accidently wrote KW, so now it is what it is
class KW {
    string key;
    KWType type;
    string svalue;
    int ivalue;
    array<KW> children;

    KW() {
        this.key = "";
        this.svalue = "";
        this.ivalue = 0;
    }

    KW(string&in key, string&in value) {
        this.key = key;
        this.type = KWType::KW_String;
        this.svalue = value;
    }

    KW(string&in key, int value) {
        this.key = key;
        this.type = KWType::KW_Number;
        this.ivalue = value;
    }

    KW(string&in key, array<KW>&in children) {
        this.key = key;
        this.type = KWType::KW_Array;
        this.children = children;
    }
}
// Doing recursive descent
class Parser {
    array<Token> token_list;
    uint current_index = 0;
    Token peek;

    Parser(array<Token>&in token_list) {
        this.token_list = token_list;
        this.current_index = 0;
        if (token_list.get_Length() > 0) {
            this.peek = token_list[0];
        } else {
            this.peek = Token();
        }
    }

    void consume() {
        current_index += 1;
        if (current_index < token_list.get_Length()) {
            peek = token_list[current_index];
        } else {
            peek = Token();
        }
    }

    bool match(TokenType type) {
        if (peek.tokentype == type) {
            consume();
            return true;
        }
        return false;
    }

    void assign_to_dict(dictionary& dict, KW kw_pair) {
        if (kw_pair.key == "") return;

        if (kw_pair.type == KWType::KW_Number) {
            dict[kw_pair.key] = kw_pair.ivalue;
        } 
        else if (kw_pair.type == KWType::KW_String) {
            dict[kw_pair.key] = kw_pair.svalue;
        } 
        else if (kw_pair.type == KWType::KW_Array) {
            // Determine array type by checking its first element
            if (kw_pair.children.get_Length() > 0) {
                if (kw_pair.children[0].type == KWType::KW_String) {
                    array<string> str_arr;
                    for (uint j = 0; j < kw_pair.children.get_Length(); j++) {
                        str_arr.Add(kw_pair.children[j].svalue);
                    }
                    dict[kw_pair.key] = str_arr; // Store as native array of strings
                } 
                else if (kw_pair.children[0].type == KWType::KW_Number) {
                    array<int> int_arr;
                    for (uint j = 0; j < kw_pair.children.get_Length(); j++) {
                        int_arr.Add(kw_pair.children[j].ivalue);
                    }
                    dict[kw_pair.key] = int_arr; // Store as native array of ints
                }
            } else {
                dict[kw_pair.key] = array<string>(); // Empty array fallback
            }
        }
    }

    dictionary parse_json() {
        dictionary result;
        if (!match(TokenType::CurlyBracketL)) {
            log("Expected { at the beginning of json");
            return result;
        }
        
        if (peek.tokentype == TokenType::CurlyBracketR) {
            consume();
            return result;
        }

        KW kw_pair = parse_pair();
        assign_to_dict(result, kw_pair);

        while (match(TokenType::Comma)) {
            kw_pair = parse_pair(); 
            assign_to_dict(result, kw_pair); // Properly assigns subsequent keys
        }
        
        if (!match(TokenType::CurlyBracketR)) {
            log("Expected } at the end of json");
        }
        return result;
    }

    KW parse_pair() {
        if (peek.tokentype != TokenType::String) {
            log("Expected string for key in pair");
            return KW();
        }
        
        string key = peek.str_value;
        consume();

        if (!match(TokenType::Colon)) {
            log("Expected : after key in pair");
            return KW();
        }
        
        KW value = parse_value();
        value.key = key; 
        return value;
    }

    KW parse_value() {
        if (peek.tokentype == TokenType::String) {
            string value = peek.str_value;
            consume();
            return KW("", value);
        } else if (peek.tokentype == TokenType::Number) {
            int value = peek.int_value;
            consume();
            return KW("", value);
        } else if (peek.tokentype == TokenType::SquareBracketL) {
            array<KW> children = parse_array();
            return KW("", children);
        } else {
            log("Expected value, but got: " + peek.tokentype);
            return KW();
        }
    }

    array<KW> parse_array() {
        array<KW> result;
        if (!match(TokenType::SquareBracketL)) {
            log("Expected [ at the beginning of array");
            return result;
        }
        
        // Handle empty arrays
        if (peek.tokentype == TokenType::SquareBracketR) {
            consume();
            return result;
        }

        KW value = parse_value();
        result.Add(value);

        while (match(TokenType::Comma)) {
            value = parse_value();
            result.Add(value);
        }

        if (!match(TokenType::SquareBracketR)) {
            log("Expected ] at the end of array");
        }
        return result;
    }

    dictionary parse() {
        return parse_json();
    }
}

// A partial json parser
dictionary parseJson(string&in input_string) {
    uint current_index = 0;
    array<Token> token_list;
    bool has_error = false;
    
    
    while (current_index < input_string.get_Length()) {
        if (input_string[current_index] == ' ' || input_string[current_index] == '\n' || input_string[current_index] == '\t' || input_string[current_index] == '\r') {
            current_index += 1;
            continue;
        }

        if (input_string[current_index] == '"') {
            current_index += 1;
            array<string> word;
            
            while (current_index < input_string.get_Length() && input_string[current_index] != '"') {
                word.Add(input_string.Substr(current_index, 1));
                current_index += 1; 
            }
            current_index += 1; // Also consume the ending quote
            token_list.Add(Token(TokenType::String, Text::Join(word, "")));
            continue;
        }
        
        if (input_string[current_index] == '{') { token_list.Add(Token(TokenType::CurlyBracketL)); current_index += 1; continue; }
        if (input_string[current_index] == '}') { token_list.Add(Token(TokenType::CurlyBracketR)); current_index += 1; continue; }
        if (input_string[current_index] == '[') { token_list.Add(Token(TokenType::SquareBracketL)); current_index += 1; continue; }
        if (input_string[current_index] == ']') { token_list.Add(Token(TokenType::SquareBracketR)); current_index += 1; continue; }
        if (input_string[current_index] == ',') { token_list.Add(Token(TokenType::Comma)); current_index += 1; continue; }
        if (input_string[current_index] == ':') { token_list.Add(Token(TokenType::Colon)); current_index += 1; continue; }

        if (input_string[current_index] >= '0' && input_string[current_index] <= '9') {
            array<string> number;
            while (current_index < input_string.get_Length() && input_string[current_index] >= '0' && input_string[current_index] <= '9') {
                number.Add(input_string.Substr(current_index, 1));
                current_index += 1;
            }
            token_list.Add(Token(TokenType::Number, Text::ParseInt(Text::Join(number, ""))));
            continue;
        }

        log("Unexpected character: " + input_string.Substr(current_index, 1));
        has_error = true;
        break;
    }

    if (has_error) {
        log("Error while parsing json string");
        return dictionary();
    }

    Parser parser(token_list);
    dictionary result = parser.parse();

    return result;
}



string toJson(dictionary&in dict) {
    array<string> parts;
    array<string> keys = dict.GetKeys();
    
    for (uint i = 0; i < keys.get_Length(); i++) {
        string key = keys[i];
        string formatted_value = "";
        
        int int_val = 0;
        string str_val = "";
        array<int>@ int_arr;
        array<string>@ str_arr;
        
        // Int check
        if (dict.Get(key, int_val)) {
            formatted_value = "" + int_val;
        } 
        // String chefck
        else if (dict.Get(key, str_val)) {
            formatted_value = "\"" + str_val + "\"";
        } 
        // Arrawy of ints check
        else if (dict.Get(key, @int_arr) && int_arr !is null) {
            array<string> arr_parts;
            for (uint j = 0; j < int_arr.get_Length(); j++) {
                arr_parts.Add("" + int_arr[j]);
            }
            formatted_value = "[" + Text::Join(arr_parts, ", ") + "]";
        } 
        // Array of strings check
        else if (dict.Get(key, @str_arr) && str_arr !is null) {
            array<string> arr_parts;
            for (uint j = 0; j < str_arr.get_Length(); j++) {
                arr_parts.Add("\"" + str_arr[j] + "\"");
            }
            formatted_value = "[" + Text::Join(arr_parts, ", ") + "]";
        }
        // Idk check
        else {
            formatted_value = "\"null\"";
        }
        
        parts.Add("\"" + key + "\": " + formatted_value);
    }
    
    return "{" + Text::Join(parts, ", ") + "}";
}