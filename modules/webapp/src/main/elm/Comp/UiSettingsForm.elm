module Comp.UiSettingsForm exposing
    ( Model
    , Msg
    , init
    , update
    , view
    , view2
    )

import Api
import Api.Model.TagList exposing (TagList)
import Comp.BasicSizeField
import Comp.ColorTagger
import Comp.FieldListSelect
import Comp.IntField
import Comp.MenuBar as MB
import Comp.Tabs
import Data.BasicSize exposing (BasicSize)
import Data.Color exposing (Color)
import Data.Fields exposing (Field)
import Data.Flags exposing (Flags)
import Data.ItemTemplate as IT exposing (ItemTemplate)
import Data.UiSettings exposing (ItemPattern, Pos(..), UiSettings)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Markdown
import Set exposing (Set)
import Styles as S
import Util.Maybe
import Util.Tag


type alias Model =
    { itemSearchPageSize : Maybe Int
    , searchPageSizeModel : Comp.IntField.Model
    , tagColors : Dict String Color
    , tagColorModel : Comp.ColorTagger.Model
    , nativePdfPreview : Bool
    , itemSearchNoteLength : Maybe Int
    , searchNoteLengthModel : Comp.IntField.Model
    , itemDetailNotesPosition : Pos
    , searchMenuFolderCount : Maybe Int
    , searchMenuFolderCountModel : Comp.IntField.Model
    , searchMenuTagCount : Maybe Int
    , searchMenuTagCountModel : Comp.IntField.Model
    , searchMenuTagCatCount : Maybe Int
    , searchMenuTagCatCountModel : Comp.IntField.Model
    , formFields : List Field
    , itemDetailShortcuts : Bool
    , searchMenuVisible : Bool
    , editMenuVisible : Bool
    , cardPreviewSize : BasicSize
    , cardTitlePattern : PatternModel
    , cardSubtitlePattern : PatternModel
    , showPatternHelp : Bool
    , searchStatsVisible : Bool
    , sideMenuVisible : Bool
    , powerSearchEnabled : Bool
    , openTabs : Set String
    }


type alias PatternModel =
    { pattern : Maybe String
    , current : ItemTemplate
    , result : Result String ItemTemplate
    }


initPatternModel : ItemPattern -> PatternModel
initPatternModel ip =
    { pattern = Just ip.pattern
    , current = ip.template
    , result = Ok ip.template
    }


updatePatternModel : PatternModel -> String -> PatternModel
updatePatternModel pm str =
    let
        result =
            case IT.readTemplate str of
                Just t ->
                    Ok t

                Nothing ->
                    Err "Template invalid, check for unclosed variables."

        p =
            Util.Maybe.fromString str
    in
    { pattern = p
    , current = Result.withDefault pm.current result
    , result = result
    }


init : Flags -> UiSettings -> ( Model, Cmd Msg )
init flags settings =
    ( { itemSearchPageSize = Just settings.itemSearchPageSize
      , searchPageSizeModel =
            Comp.IntField.init
                (Just 10)
                (Just flags.config.maxPageSize)
                False
                "Page size"
      , tagColors = settings.tagCategoryColors
      , tagColorModel =
            Comp.ColorTagger.init
                []
                Data.Color.all
      , nativePdfPreview = settings.nativePdfPreview
      , itemSearchNoteLength = Just settings.itemSearchNoteLength
      , searchNoteLengthModel =
            Comp.IntField.init
                (Just 0)
                (Just flags.config.maxNoteLength)
                False
                "Max. Note Length"
      , itemDetailNotesPosition = settings.itemDetailNotesPosition
      , searchMenuFolderCount = Just settings.searchMenuFolderCount
      , searchMenuFolderCountModel =
            Comp.IntField.init
                (Just 0)
                (Just 2000)
                False
                "Number of folders in search menu"
      , searchMenuTagCount = Just settings.searchMenuTagCount
      , searchMenuTagCountModel =
            Comp.IntField.init
                (Just 0)
                (Just 2000)
                False
                "Number of tags in search menu"
      , searchMenuTagCatCount = Just settings.searchMenuTagCatCount
      , searchMenuTagCatCountModel =
            Comp.IntField.init
                (Just 0)
                (Just 2000)
                False
                "Number of categories in search menu"
      , formFields = settings.formFields
      , itemDetailShortcuts = settings.itemDetailShortcuts
      , searchMenuVisible = settings.searchMenuVisible
      , editMenuVisible = settings.editMenuVisible
      , cardPreviewSize = settings.cardPreviewSize
      , cardTitlePattern = initPatternModel settings.cardTitleTemplate
      , cardSubtitlePattern = initPatternModel settings.cardSubtitleTemplate
      , showPatternHelp = False
      , searchStatsVisible = settings.searchStatsVisible
      , sideMenuVisible = settings.sideMenuVisible
      , powerSearchEnabled = settings.powerSearchEnabled
      , openTabs = Set.empty
      }
    , Api.getTags flags "" GetTagsResp
    )


type Msg
    = SearchPageSizeMsg Comp.IntField.Msg
    | TagColorMsg Comp.ColorTagger.Msg
    | GetTagsResp (Result Http.Error TagList)
    | TogglePdfPreview
    | NoteLengthMsg Comp.IntField.Msg
    | SetNotesPosition Pos
    | SearchMenuFolderMsg Comp.IntField.Msg
    | SearchMenuTagMsg Comp.IntField.Msg
    | SearchMenuTagCatMsg Comp.IntField.Msg
    | FieldListMsg Comp.FieldListSelect.Msg
    | ToggleItemDetailShortcuts
    | ToggleSearchMenuVisible
    | ToggleEditMenuVisible
    | CardPreviewSizeMsg Comp.BasicSizeField.Msg
    | SetCardTitlePattern String
    | SetCardSubtitlePattern String
    | TogglePatternHelpMsg
    | ToggleSearchStatsVisible
    | ToggleAkkordionTab String
    | ToggleSideMenuVisible
    | TogglePowerSearch



--- Update


update : UiSettings -> Msg -> Model -> ( Model, Maybe UiSettings )
update sett msg model =
    case msg of
        SearchPageSizeMsg lm ->
            let
                ( m, n ) =
                    Comp.IntField.update lm model.searchPageSizeModel

                nextSettings =
                    Maybe.map (\sz -> { sett | itemSearchPageSize = sz }) n

                model_ =
                    { model
                        | searchPageSizeModel = m
                        , itemSearchPageSize = n
                    }
            in
            ( model_, nextSettings )

        NoteLengthMsg lm ->
            let
                ( m, n ) =
                    Comp.IntField.update lm model.searchNoteLengthModel

                nextSettings =
                    Maybe.map (\len -> { sett | itemSearchNoteLength = len }) n

                model_ =
                    { model
                        | searchNoteLengthModel = m
                        , itemSearchNoteLength = n
                    }
            in
            ( model_, nextSettings )

        SearchMenuFolderMsg lm ->
            let
                ( m, n ) =
                    Comp.IntField.update lm model.searchMenuFolderCountModel

                nextSettings =
                    Maybe.map (\len -> { sett | searchMenuFolderCount = len }) n

                model_ =
                    { model
                        | searchMenuFolderCountModel = m
                        , searchMenuFolderCount = n
                    }
            in
            ( model_, nextSettings )

        SearchMenuTagMsg lm ->
            let
                ( m, n ) =
                    Comp.IntField.update lm model.searchMenuTagCountModel

                nextSettings =
                    Maybe.map (\len -> { sett | searchMenuTagCount = len }) n

                model_ =
                    { model
                        | searchMenuTagCountModel = m
                        , searchMenuTagCount = n
                    }
            in
            ( model_, nextSettings )

        SearchMenuTagCatMsg lm ->
            let
                ( m, n ) =
                    Comp.IntField.update lm model.searchMenuTagCatCountModel

                nextSettings =
                    Maybe.map (\len -> { sett | searchMenuTagCatCount = len }) n

                model_ =
                    { model
                        | searchMenuTagCatCountModel = m
                        , searchMenuTagCatCount = n
                    }
            in
            ( model_, nextSettings )

        SetNotesPosition pos ->
            let
                model_ =
                    { model | itemDetailNotesPosition = pos }
            in
            if model_.itemDetailNotesPosition == sett.itemDetailNotesPosition then
                ( model_, Nothing )

            else
                ( model_, Just { sett | itemDetailNotesPosition = model_.itemDetailNotesPosition } )

        TagColorMsg lm ->
            let
                ( m_, d_ ) =
                    Comp.ColorTagger.update lm model.tagColorModel

                nextSettings =
                    Maybe.map (\tc -> { sett | tagCategoryColors = tc }) d_

                model_ =
                    { model
                        | tagColorModel = m_
                        , tagColors = Maybe.withDefault model.tagColors d_
                    }
            in
            ( model_, nextSettings )

        TogglePdfPreview ->
            let
                flag =
                    not model.nativePdfPreview
            in
            ( { model | nativePdfPreview = flag }
            , Just { sett | nativePdfPreview = flag }
            )

        GetTagsResp (Ok tl) ->
            let
                categories =
                    Util.Tag.getCategories tl.items
            in
            ( { model
                | tagColorModel =
                    Comp.ColorTagger.init
                        categories
                        Data.Color.all
              }
            , Nothing
            )

        GetTagsResp (Err _) ->
            ( model, Nothing )

        FieldListMsg lm ->
            let
                selected =
                    Comp.FieldListSelect.update lm model.formFields

                newSettings =
                    { sett | formFields = selected }
            in
            ( { model | formFields = selected }
            , if selected /= model.formFields then
                Just newSettings

              else
                Nothing
            )

        ToggleItemDetailShortcuts ->
            let
                flag =
                    not model.itemDetailShortcuts
            in
            ( { model | itemDetailShortcuts = flag }
            , Just { sett | itemDetailShortcuts = flag }
            )

        ToggleSearchMenuVisible ->
            let
                flag =
                    not model.searchMenuVisible
            in
            ( { model | searchMenuVisible = flag }
            , Just { sett | searchMenuVisible = flag }
            )

        ToggleEditMenuVisible ->
            let
                flag =
                    not model.editMenuVisible
            in
            ( { model | editMenuVisible = flag }
            , Just { sett | editMenuVisible = flag }
            )

        CardPreviewSizeMsg lm ->
            let
                next =
                    Comp.BasicSizeField.update lm
                        |> Maybe.withDefault model.cardPreviewSize

                newSettings =
                    if next /= model.cardPreviewSize then
                        Just { sett | cardPreviewSize = next }

                    else
                        Nothing
            in
            ( { model | cardPreviewSize = next }
            , newSettings
            )

        SetCardTitlePattern str ->
            let
                pm =
                    model.cardTitlePattern

                pm_ =
                    updatePatternModel pm str

                newSettings =
                    if pm_.pattern /= Just sett.cardTitleTemplate.pattern then
                        Just
                            { sett
                                | cardTitleTemplate =
                                    ItemPattern
                                        (Maybe.withDefault "" pm_.pattern)
                                        pm_.current
                            }

                    else
                        Nothing
            in
            ( { model | cardTitlePattern = pm_ }, newSettings )

        SetCardSubtitlePattern str ->
            let
                pm =
                    model.cardSubtitlePattern

                pm_ =
                    updatePatternModel pm str

                newSettings =
                    if pm_.pattern /= Just sett.cardSubtitleTemplate.pattern then
                        Just
                            { sett
                                | cardSubtitleTemplate =
                                    ItemPattern
                                        (Maybe.withDefault "" pm_.pattern)
                                        pm_.current
                            }

                    else
                        Nothing
            in
            ( { model | cardSubtitlePattern = pm_ }, newSettings )

        TogglePatternHelpMsg ->
            ( { model | showPatternHelp = not model.showPatternHelp }, Nothing )

        ToggleSearchStatsVisible ->
            let
                flag =
                    not model.searchStatsVisible
            in
            ( { model | searchStatsVisible = flag }
            , Just { sett | searchStatsVisible = flag }
            )

        ToggleAkkordionTab title ->
            let
                tabs =
                    if Set.member title model.openTabs then
                        Set.remove title model.openTabs

                    else
                        Set.insert title model.openTabs
            in
            ( { model | openTabs = tabs }
            , Nothing
            )

        ToggleSideMenuVisible ->
            let
                next =
                    not model.sideMenuVisible
            in
            ( { model | sideMenuVisible = next }
            , Just { sett | sideMenuVisible = next }
            )

        TogglePowerSearch ->
            let
                next =
                    not model.powerSearchEnabled
            in
            ( { model | powerSearchEnabled = next }
            , Just { sett | powerSearchEnabled = next }
            )



--- View


tagColorViewOpts : Comp.ColorTagger.ViewOpts
tagColorViewOpts =
    { renderItem =
        \( k, v ) ->
            span [ class ("ui label " ++ Data.Color.toString v) ]
                [ text k ]
    , label = "Choose color for tag categories"
    , description = Just "Tags can be represented differently based on their category."
    }


view : Flags -> UiSettings -> Model -> Html Msg
view flags _ model =
    div [ class "ui form" ]
        [ div [ class "ui dividing header" ]
            [ text "Item Search"
            ]
        , Html.map SearchPageSizeMsg
            (Comp.IntField.viewWithInfo
                ("Maximum results in one page when searching items. At most "
                    ++ String.fromInt flags.config.maxPageSize
                    ++ "."
                )
                model.itemSearchPageSize
                "field"
                model.searchPageSizeModel
            )
        , div [ class "field" ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> ToggleSearchStatsVisible)
                    , checked model.searchStatsVisible
                    ]
                    []
                , label []
                    [ text "Show basic search statistics by default"
                    ]
                ]
            ]
        , div [ class "ui dividing header" ]
            [ text "Item Cards"
            ]
        , Html.map NoteLengthMsg
            (Comp.IntField.viewWithInfo
                ("Maximum size of the item notes to display in card view. Between 0 - "
                    ++ String.fromInt flags.config.maxNoteLength
                    ++ "."
                )
                model.itemSearchNoteLength
                "field"
                model.searchNoteLengthModel
            )
        , Html.map CardPreviewSizeMsg
            (Comp.BasicSizeField.view
                "Size of item preview"
                model.cardPreviewSize
            )
        , div [ class "field" ]
            [ label []
                [ text "Card Title Pattern"
                , a
                    [ class "right-float"
                    , title "Toggle pattern help text"
                    , href "#"
                    , onClick TogglePatternHelpMsg
                    ]
                    [ i [ class "help link icon" ] []
                    ]
                ]
            , input
                [ type_ "text"
                , Maybe.withDefault "" model.cardTitlePattern.pattern |> value
                , onInput SetCardTitlePattern
                ]
                []
            ]
        , div [ class "field" ]
            [ label []
                [ text "Card Subtitle Pattern"
                , a
                    [ class "right-float"
                    , title "Toggle pattern help text"
                    , href "#"
                    , onClick TogglePatternHelpMsg
                    ]
                    [ i [ class "help link icon" ] []
                    ]
                ]
            , input
                [ type_ "text"
                , Maybe.withDefault "" model.cardSubtitlePattern.pattern |> value
                , onInput SetCardSubtitlePattern
                ]
                []
            ]
        , Markdown.toHtml
            [ classList
                [ ( "ui message", True )
                , ( "hidden", not model.showPatternHelp )
                ]
            ]
            IT.helpMessage
        , div [ class "ui dividing header" ]
            [ text "Search Menu" ]
        , div [ class "field" ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> ToggleSearchMenuVisible)
                    , checked model.searchMenuVisible
                    ]
                    []
                , label []
                    [ text "Show search side menu by default"
                    ]
                ]
            ]
        , Html.map SearchMenuTagMsg
            (Comp.IntField.viewWithInfo
                "How many tags to display in search menu at once. Others can be expanded. Use 0 to always show all."
                model.searchMenuTagCount
                "field"
                model.searchMenuTagCountModel
            )
        , Html.map SearchMenuTagCatMsg
            (Comp.IntField.viewWithInfo
                "How many categories to display in search menu at once. Others can be expanded. Use 0 to always show all."
                model.searchMenuTagCatCount
                "field"
                model.searchMenuTagCatCountModel
            )
        , Html.map SearchMenuFolderMsg
            (Comp.IntField.viewWithInfo
                "How many folders to display in search menu at once. Other folders can be expanded. Use 0 to always show all."
                model.searchMenuFolderCount
                "field"
                model.searchMenuFolderCountModel
            )
        , div [ class "ui dividing header" ]
            [ text "Item Detail"
            ]
        , div [ class "field" ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> TogglePdfPreview)
                    , checked model.nativePdfPreview
                    ]
                    []
                , label []
                    [ text "Browser-native PDF preview"
                    ]
                ]
            ]
        , div [ class "field" ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> ToggleItemDetailShortcuts)
                    , checked model.itemDetailShortcuts
                    ]
                    []
                , label []
                    [ text "Use keyboard shortcuts for navigation and confirm/unconfirm with open edit menu."
                    ]
                ]
            ]
        , div [ class "field" ]
            [ div [ class "ui checkbox" ]
                [ input
                    [ type_ "checkbox"
                    , onCheck (\_ -> ToggleEditMenuVisible)
                    , checked model.editMenuVisible
                    ]
                    []
                , label []
                    [ text "Show edit side menu by default"
                    ]
                ]
            ]
        , div [ class "grouped fields" ]
            [ label [] [ text "Position of item notes" ]
            , div [ class "field" ]
                [ div [ class "ui radio checkbox" ]
                    [ input
                        [ type_ "radio"
                        , checked (model.itemDetailNotesPosition == Top)
                        , onCheck (\_ -> SetNotesPosition Top)
                        ]
                        []
                    , label [] [ text "Top" ]
                    ]
                ]
            , div [ class "field" ]
                [ div [ class "ui radio checkbox" ]
                    [ input
                        [ type_ "radio"
                        , checked (model.itemDetailNotesPosition == Bottom)
                        , onCheck (\_ -> SetNotesPosition Bottom)
                        ]
                        []
                    , label [] [ text "Bottom" ]
                    ]
                ]
            ]
        , div [ class "ui dividing header" ]
            [ text "Tag Category Colors"
            ]
        , Html.map TagColorMsg
            (Comp.ColorTagger.view
                model.tagColors
                tagColorViewOpts
                model.tagColorModel
            )
        , div [ class "ui dividing header" ]
            [ text "Fields"
            ]
        , span [ class "small-info" ]
            [ text "Choose which fields to display in search and edit menus."
            ]
        , Html.map FieldListMsg (Comp.FieldListSelect.view model.formFields)
        ]



--- View2


tagColorViewOpts2 : Comp.ColorTagger.ViewOpts
tagColorViewOpts2 =
    { renderItem =
        \( k, v ) ->
            span [ class (" label " ++ Data.Color.toString2 v) ]
                [ text k ]
    , label = "Choose color for tag categories"
    , description = Just "Tags can be represented differently based on their category."
    }


view2 : Flags -> UiSettings -> Model -> Html Msg
view2 flags settings model =
    let
        state tab =
            if Set.member tab.title model.openTabs then
                Comp.Tabs.Open

            else
                Comp.Tabs.Closed
    in
    div [ class "flex flex-col" ]
        [ Comp.Tabs.akkordion
            Comp.Tabs.defaultStyle
            (\t -> ( state t, ToggleAkkordionTab t.title ))
            (settingFormTabs flags settings model)
        ]


settingFormTabs : Flags -> UiSettings -> Model -> List (Comp.Tabs.Tab Msg)
settingFormTabs flags _ model =
    [ { title = "General"
      , titleRight = []
      , info = Nothing
      , body =
            [ div [ class "mb-4 " ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { id = "uisetting-sidemenu-visible"
                        , label = "Show side menu by default"
                        , tagger = \_ -> ToggleSideMenuVisible
                        , value = model.sideMenuVisible
                        }
                ]
            ]
      }
    , { title = "Item Search"
      , titleRight = []
      , info = Nothing
      , body =
            [ Html.map SearchPageSizeMsg
                (Comp.IntField.viewWithInfo2
                    ("Maximum results in one page when searching items. At most "
                        ++ String.fromInt flags.config.maxPageSize
                        ++ "."
                    )
                    model.itemSearchPageSize
                    "mb-4"
                    model.searchPageSizeModel
                )
            , div [ class "mb-4" ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { id = "uisetting-searchstats-visible"
                        , value = model.searchStatsVisible
                        , tagger = \_ -> ToggleSearchStatsVisible
                        , label = "Show basic search statistics by default"
                        }
                ]
            , div [ class "mb-4" ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { id = "uisetting-powersearch-enabled"
                        , value = model.powerSearchEnabled
                        , tagger = \_ -> TogglePowerSearch
                        , label = "Enable power-user search bar"
                        }
                ]
            ]
      }
    , { title = "Item Cards"
      , titleRight = []
      , info = Nothing
      , body =
            [ Html.map NoteLengthMsg
                (Comp.IntField.viewWithInfo2
                    ("Maximum size of the item notes to display in card view. Between 0 - "
                        ++ String.fromInt flags.config.maxNoteLength
                        ++ "."
                    )
                    model.itemSearchNoteLength
                    "mb-4"
                    model.searchNoteLengthModel
                )
            , Html.map CardPreviewSizeMsg
                (Comp.BasicSizeField.view2
                    "mb-4"
                    "Size of item preview"
                    model.cardPreviewSize
                )
            , div [ class "mb-4" ]
                [ label [ class S.inputLabel ]
                    [ text "Card Title Pattern"
                    , a
                        [ class "float-right"
                        , class S.link
                        , title "Toggle pattern help text"
                        , href "#"
                        , onClick TogglePatternHelpMsg
                        ]
                        [ i [ class "fa fa-question" ] []
                        ]
                    ]
                , input
                    [ type_ "text"
                    , Maybe.withDefault "" model.cardTitlePattern.pattern |> value
                    , onInput SetCardTitlePattern
                    , class S.textInput
                    ]
                    []
                ]
            , div [ class "mb-4" ]
                [ label [ class S.inputLabel ]
                    [ text "Card Subtitle Pattern"
                    , a
                        [ class "float-right"
                        , class S.link
                        , title "Toggle pattern help text"
                        , href "#"
                        , onClick TogglePatternHelpMsg
                        ]
                        [ i [ class "fa fa-question" ] []
                        ]
                    ]
                , input
                    [ type_ "text"
                    , Maybe.withDefault "" model.cardSubtitlePattern.pattern |> value
                    , onInput SetCardSubtitlePattern
                    , class S.textInput
                    ]
                    []
                ]
            , Markdown.toHtml
                [ classList
                    [ ( S.message, True )
                    , ( "hidden", not model.showPatternHelp )
                    ]
                ]
                IT.helpMessage
            ]
      }
    , { title = "Search Menu"
      , titleRight = []
      , info = Nothing
      , body =
            [ Html.map SearchMenuTagMsg
                (Comp.IntField.viewWithInfo2
                    "How many tags to display in search menu at once. Others can be expanded. Use 0 to always show all."
                    model.searchMenuTagCount
                    "mb-4"
                    model.searchMenuTagCountModel
                )
            , Html.map SearchMenuTagCatMsg
                (Comp.IntField.viewWithInfo2
                    "How many categories to display in search menu at once. Others can be expanded. Use 0 to always show all."
                    model.searchMenuTagCatCount
                    "mb-4"
                    model.searchMenuTagCatCountModel
                )
            , Html.map SearchMenuFolderMsg
                (Comp.IntField.viewWithInfo2
                    "How many folders to display in search menu at once. Other folders can be expanded. Use 0 to always show all."
                    model.searchMenuFolderCount
                    "mb-4"
                    model.searchMenuFolderCountModel
                )
            ]
      }
    , { title = "Item Detail"
      , titleRight = []
      , info = Nothing
      , body =
            [ div [ class "mb-4" ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { tagger = \_ -> TogglePdfPreview
                        , label = "Browser-native PDF preview"
                        , value = model.nativePdfPreview
                        , id = "uisetting-pdfpreview-toggle"
                        }
                ]
            , div [ class "mb-4" ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { tagger = \_ -> ToggleItemDetailShortcuts
                        , label = "Use keyboard shortcuts for navigation and confirm/unconfirm with open edit menu."
                        , value = model.itemDetailShortcuts
                        , id = "uisetting-itemdetailshortcuts-toggle"
                        }
                ]
            , div [ class "mb-4 hidden" ]
                [ MB.viewItem <|
                    MB.Checkbox
                        { id = "uisetting-editmenu-visible"
                        , value = model.editMenuVisible
                        , tagger = \_ -> ToggleEditMenuVisible
                        , label = "Show edit side menu by default"
                        }
                ]
            ]
      }
    , { title = "Tag Category Colors"
      , titleRight = []
      , info = Nothing
      , body =
            [ Html.map TagColorMsg
                (Comp.ColorTagger.view2
                    model.tagColors
                    tagColorViewOpts2
                    model.tagColorModel
                )
            ]
      }
    , { title = "Fields"
      , titleRight = []
      , info = Nothing
      , body =
            [ span [ class "opacity-50 text-sm" ]
                [ text "Choose which fields to display in search and edit menus."
                ]
            , Html.map FieldListMsg
                (Comp.FieldListSelect.view2
                    "px-2"
                    model.formFields
                )
            ]
      }
    ]
