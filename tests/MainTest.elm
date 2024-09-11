module MainTest exposing (..)

import Array
import Dict
import Expect
import Fuzz exposing (Fuzzer, string)
import Json.Decode
import Json.Encode
import Main
    exposing
        ( Choice
        , FormField
        , InputField(..)
        , Presence(..)
        , ViewMode(..)
        , allInputField
        , decodeChoice
        , decodeFormFields
        , decodeShortTextTypeList
        , encodeChoice
        , encodeFormFields
        , stringFromViewMode
        , viewModeFromString
        )
import Test exposing (..)


suite : Test
suite =
    describe "Main"
        [ Test.fuzz (Fuzz.intRange 0 100) "{encode,decode}InputField is reversible" <|
            \size ->
                let
                    formFields =
                        Fuzz.examples size fuzzFormField
                            |> Array.fromList
                in
                formFields
                    |> encodeFormFields
                    |> Json.Encode.encode 0
                    |> Json.Decode.decodeString decodeFormFields
                    |> Expect.equal (Ok formFields)
        , Test.fuzz viewModeFuzzer "stringFromViewMode,viewModeFromString is reversible" <|
            \mode ->
                mode
                    |> stringFromViewMode
                    |> viewModeFromString
                    |> Expect.equal (Just mode)
        , test "decodeShortTextTypeList" <|
            \_ ->
                """
                [
                    { "Text": { "type": "text" } },
                    { "Text": { "type": "text", "maxlength": "10", "multiple": "true" } },
                    { "Email": { "type": "email" } },
                    { "Emails": { "type": "email" , "multiple": "true" } },
                    { "Digits": { "type": "text", "pattern": "^[0-9]+$" } },
                    { "Nric": { "type": "text", "pattern": "^[STGM][0-9]{7}[ABCDEFGHIZJ]$" } }
                ]
                """
                    |> Json.Decode.decodeString decodeShortTextTypeList
                    |> Expect.equal
                        (Ok
                            [ ( "Text", Dict.fromList [ ( "type", "text" ) ] )
                            , ( "Text", Dict.fromList [ ( "type", "text" ), ( "maxlength", "10" ), ( "multiple", "true" ) ] )
                            , ( "Email", Dict.fromList [ ( "type", "email" ) ] )
                            , ( "Emails", Dict.fromList [ ( "type", "email" ), ( "multiple", "true" ) ] )
                            , ( "Digits", Dict.fromList [ ( "pattern", "^[0-9]+$" ), ( "type", "text" ) ] )
                            , ( "Nric", Dict.fromList [ ( "pattern", "^[STGM][0-9]{7}[ABCDEFGHIZJ]$" ), ( "type", "text" ) ] )
                            ]
                        )
        , Test.fuzz choiceStringFuzzer "choiceStringToChoice,choiceStringFromString is reversible" <|
            \choice ->
                choice
                    |> encodeChoice
                    |> Json.Encode.encode 0
                    |> Json.Decode.decodeString decodeChoice
                    |> Expect.equal (Ok choice)
        ]



--


viewModeFuzzer : Fuzzer ViewMode
viewModeFuzzer =
    Fuzz.oneOf
        [ -- Fuzz.constant (Editor { maybeAnimate = Nothing })
          -- we don't encode/decode `maybeHighlight` because it is transient value
          -- maybeHighlight is always Nothing
          Fuzz.constant (Editor { maybeAnimate = Nothing })
        , Fuzz.constant Preview
        , Fuzz.constant CollectData
        ]


inputFieldFuzzer : Fuzzer InputField
inputFieldFuzzer =
    allInputField
        ++ moreTestInputFields
        |> List.map Fuzz.constant
        |> Fuzz.oneOf


moreTestInputFields : List InputField
moreTestInputFields =
    [ ShortText "Email" [ ( "type", "email" ) ]

    -- , ShortText "Emails" [ ( "type", "email" ), ( "multiple", "true" ) ]
    -- , ShortText "Emails with maxlength" [ ( "type", "email" ), ( "multiple", "true" ), ( "maxlength", "20" ) ]
    ]


presenceFuzzer : Fuzzer Presence
presenceFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Required
        , Fuzz.constant Optional
        , Fuzz.map2 (\name description -> SystemRequired { name = name, description = description })
            Fuzz.string
            Fuzz.string
        , Fuzz.map2 (\name description -> SystemOptional { name = name, description = description })
            Fuzz.string
            Fuzz.string
        ]


fuzzFormField : Fuzzer FormField
fuzzFormField =
    Fuzz.map4 FormField
        string
        presenceFuzzer
        string
        inputFieldFuzzer


choiceStringFuzzer : Fuzzer Choice
choiceStringFuzzer =
    Fuzz.oneOf
        [ Fuzz.map2 Choice
            Fuzz.string
            Fuzz.string
        , Fuzz.string
            |> Fuzz.map (\s -> Choice s s)
        ]
