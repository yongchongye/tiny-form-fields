module MainTest exposing (..)

import Array
import Dict
import Expect
import Fuzz exposing (Fuzzer, string)
import Json.Decode
import Json.Encode
import Main exposing (choiceToString)
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
                    |> Main.encodeFormFields
                    |> Json.Encode.encode 0
                    |> Json.Decode.decodeString Main.decodeFormFields
                    |> Expect.equal (Ok formFields)
        , Test.fuzz viewModeFuzzer "stringFromViewMode,viewModeFromString is reversible" <|
            \mode ->
                mode
                    |> Main.stringFromViewMode
                    |> Main.viewModeFromString
                    |> Expect.equal (Just mode)
        , test "decodeShortTextTypeList" <|
            \_ ->
                """
                [
                    { "Text": { "type": "text" } },
                    { "Email": { "type": "email" } },
                    { "Digits": { "type": "text", "pattern": "^[0-9]+$" } },
                    { "Nric": { "type": "text", "pattern": "^[STGM][0-9]{7}[ABCDEFGHIZJ]$" } }
                ]
                """
                    |> Json.Decode.decodeString Main.decodeShortTextTypeList
                    |> Expect.equal
                        (Ok
                            [ ( "Text", Dict.fromList [ ( "type", "text" ) ] )
                            , ( "Email", Dict.fromList [ ( "type", "email" ) ] )
                            , ( "Digits", Dict.fromList [ ( "pattern", "^[0-9]+$" ), ( "type", "text" ) ] )
                            , ( "Nric", Dict.fromList [ ( "pattern", "^[STGM][0-9]{7}[ABCDEFGHIZJ]$" ), ( "type", "text" ) ] )
                            ]
                        )
        , Test.fuzz choiceStringFuzzer "choiceStringToChoice,choiceStringFromString is reversible" <|
            \choice ->
                choice
                    |> Main.encodeChoice
                    |> Json.Encode.encode 0
                    |> Json.Decode.decodeString Main.decodeChoice
                    |> Expect.equal (Ok choice)
        ]



--


viewModeFuzzer : Fuzzer Main.ViewMode
viewModeFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Main.Editor
        , Fuzz.constant Main.Preview
        , Fuzz.constant Main.CollectData
        ]


inputFieldFuzzer : Fuzzer Main.InputField
inputFieldFuzzer =
    Main.allInputField
        |> List.map Fuzz.constant
        |> Fuzz.oneOf


presenceFuzzer : Fuzzer Main.Presence
presenceFuzzer =
    Fuzz.oneOf
        [ Fuzz.constant Main.Required
        , Fuzz.constant Main.Optional
        , Fuzz.map2 (\name description -> Main.System { name = name, description = description })
            Fuzz.string
            Fuzz.string
        ]


fuzzFormField : Fuzzer Main.FormField
fuzzFormField =
    Fuzz.map4 Main.FormField
        string
        presenceFuzzer
        string
        inputFieldFuzzer


choiceStringFuzzer : Fuzzer Main.Choice
choiceStringFuzzer =
    Fuzz.oneOf
        [ Fuzz.map2 Main.Choice
            Fuzz.string
            Fuzz.string
        , Fuzz.string
            |> Fuzz.map (\s -> Main.Choice s s)
        ]
