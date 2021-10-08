# Testdata syntax

| ------------------ | ------------------------------------------------------- |
Structure            | `testdata: {datatype1: {...}, datatype2: {...}, ...}`
Tests for a datatype | `datatype1: {valid: ..., invalid: ...}`
-> decoded as string | `valid ["1", "2", "3"], invalid: [1, "x"]`
-> other kind of values | `valid: {"1": 1, "2": 2}, invalid: ["", true]`
-> non-canonical repr. | `datatype1: {valid: ..., oneway: ..., invalid: ...}`
                       | e.g. `valid: [1], oneway: {"+1": 1}`

