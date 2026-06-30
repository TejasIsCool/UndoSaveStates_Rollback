#set text(size: 20pt)
- So we will tokenize it first
- Numbers will be a single token, strings will be their own token

#text("Partial Grammar", size: 32pt)
$
  bold("json") -> "{" (bold("pair") ("," bold("pair"))^*)?  }\
  bold("pair") -> bold("string") ":" bold("value")\
  bold("value") -> bold("string") | bold("number") | bold("array")\
  bold("array") -> "[" (bold("value") ("," bold("value"))^*)? "]"\
$

I suppose we should make the array be homogeneous, but oh well