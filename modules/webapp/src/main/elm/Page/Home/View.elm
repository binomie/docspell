module Page.Home.View exposing (view)

import Api.Model.ItemSearch
import Comp.FixedDropdown
import Comp.ItemCardList
import Comp.ItemDetail.MultiEditMenu
import Comp.SearchMenu
import Comp.SearchStatsView
import Comp.YesNoDimmer
import Data.Flags exposing (Flags)
import Data.ItemSelection
import Data.UiSettings exposing (UiSettings)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Page exposing (Page(..))
import Page.Home.Data exposing (..)
import Set
import Util.Html


view : Flags -> UiSettings -> Model -> Html Msg
view flags settings model =
    let
        itemViewCfg =
            case model.viewMode of
                SelectView svm ->
                    Comp.ItemCardList.ViewConfig
                        model.scrollToCard
                        (Data.ItemSelection.Active svm.ids)

                _ ->
                    Comp.ItemCardList.ViewConfig
                        model.scrollToCard
                        Data.ItemSelection.Inactive

        selectAction =
            case model.viewMode of
                SelectView svm ->
                    svm.action

                _ ->
                    NoneAction
    in
    div [ class "home-page ui padded grid" ]
        [ div
            [ classList
                [ ( "sixteen wide mobile six wide tablet four wide computer search-menu column"
                  , True
                  )
                , ( "invisible hidden", menuCollapsed model )
                ]
            ]
            [ div
                [ class "ui ablue-comp icon menu"
                ]
                [ a
                    [ class "borderless item"
                    , href "#"
                    , onClick ToggleSearchMenu
                    , title "Hide menu"
                    ]
                    [ i [ class "chevron left icon" ] []
                    ]
                , div [ class "right floated menu" ]
                    [ a
                        [ classList
                            [ ( "borderless item", True )
                            , ( "active", selectActive model )
                            ]
                        , href "#"
                        , title "Toggle select items"
                        , onClick ToggleSelectView
                        ]
                        [ i [ class "tasks icon" ] []
                        ]
                    , a
                        [ class "borderless item"
                        , onClick ResetSearch
                        , title "Reset form"
                        , href "#"
                        ]
                        [ i [ class "undo icon" ] []
                        ]
                    , a
                        [ class "borderless item"
                        , onClick (DoSearch BasicSearch)
                        , title "Run search query"
                        , href "#"
                        , disabled model.searchInProgress
                        ]
                        [ i
                            [ classList
                                [ ( "search icon", not model.searchInProgress )
                                , ( "loading spinner icon", model.searchInProgress )
                                ]
                            ]
                            []
                        ]
                    ]
                ]
            , div [ class "" ]
                (viewLeftMenu flags settings model)
            ]
        , div
            [ classList
                [ ( "sixteen wide mobile ten wide tablet twelve wide computer column"
                  , not (menuCollapsed model)
                  )
                , ( "sixteen wide column", menuCollapsed model )
                , ( "item-card-list", True )
                ]
            , id "item-card-list"
            ]
            (List.concat
                [ viewBar flags model
                , case model.viewMode of
                    SelectView svm ->
                        [ Html.map DeleteSelectedConfirmMsg
                            (Comp.YesNoDimmer.view2 (selectAction == DeleteSelected)
                                deleteAllDimmer
                                svm.deleteAllConfirm
                            )
                        ]

                    _ ->
                        []
                , viewStats flags settings model
                , [ Html.map ItemCardListMsg
                        (Comp.ItemCardList.view itemViewCfg settings model.itemListModel)
                  ]
                ]
            )
        , div
            [ classList
                [ ( "sixteen wide column", True )
                , ( "hidden invisible", resultsBelowLimit settings model )
                ]
            ]
            [ div [ class "ui basic center aligned segment" ]
                [ button
                    [ classList
                        [ ( "ui basic tiny button", True )
                        , ( "disabled", not model.moreAvailable )
                        ]
                    , disabled (not model.moreAvailable || model.moreInProgress || model.searchInProgress)
                    , title "Load more items"
                    , href "#"
                    , onClick LoadMore
                    ]
                    [ if model.moreInProgress then
                        i [ class "loading spinner icon" ] []

                      else
                        i [ class "angle double down icon" ] []
                    , if model.moreAvailable then
                        text "Load more…"

                      else
                        text "That's all"
                    ]
                ]
            ]
        ]


viewStats : Flags -> UiSettings -> Model -> List (Html Msg)
viewStats _ settings model =
    if settings.searchStatsVisible then
        Comp.SearchStatsView.view model.searchStats

    else
        []


viewLeftMenu : Flags -> UiSettings -> Model -> List (Html Msg)
viewLeftMenu flags settings model =
    let
        searchMenu =
            [ Html.map SearchMenuMsg
                (Comp.SearchMenu.viewDrop model.dragDropData
                    flags
                    settings
                    model.searchMenuModel
                )
            ]
    in
    case model.viewMode of
        SelectView svm ->
            case svm.action of
                EditSelected ->
                    let
                        cfg_ =
                            Comp.ItemDetail.MultiEditMenu.defaultViewConfig

                        cfg =
                            { cfg_
                                | nameState = svm.saveNameState
                                , customFieldState =
                                    \fId ->
                                        if Set.member fId svm.saveCustomFieldState then
                                            Comp.ItemDetail.MultiEditMenu.Saving

                                        else
                                            Comp.ItemDetail.MultiEditMenu.SaveSuccess
                            }
                    in
                    [ div [ class "ui dividing header" ]
                        [ text "Multi-Edit"
                        ]
                    , div [ class "ui info message" ]
                        [ text "Note that a change here immediatly affects all selected items on the right!"
                        ]
                    , Html.map EditMenuMsg
                        (Comp.ItemDetail.MultiEditMenu.view cfg settings svm.editModel)
                    ]

                _ ->
                    searchMenu

        _ ->
            searchMenu


viewBar : Flags -> Model -> List (Html Msg)
viewBar flags model =
    case model.viewMode of
        SimpleView ->
            [ viewSearchBar flags model ]

        SearchView ->
            []

        SelectView svm ->
            [ viewActionBar flags svm model ]


viewActionBar : Flags -> SelectViewModel -> Model -> Html Msg
viewActionBar _ svm _ =
    let
        selectCount =
            Set.size svm.ids |> String.fromInt
    in
    div
        [ class "ui ablue-comp icon menu"
        ]
        [ a
            [ classList
                [ ( "borderless item", True )
                , ( "active", svm.action == EditSelected )
                ]
            , href "#"
            , title <| "Edit " ++ selectCount ++ " selected items"
            , onClick EditSelectedItems
            ]
            [ i [ class "ui edit icon" ] []
            ]
        , a
            [ classList
                [ ( "borderless item", True )
                , ( "active", svm.action == DeleteSelected )
                ]
            , href "#"
            , title <| "Delete " ++ selectCount ++ " selected items"
            , onClick RequestDeleteSelected
            ]
            [ i [ class "trash icon" ] []
            ]
        , div [ class "right menu" ]
            [ a
                [ class "item"
                , href "#"
                , onClick SelectAllItems
                , title "Select all"
                ]
                [ i [ class "check square outline icon" ] []
                ]
            , a
                [ class "borderless item"
                , href "#"
                , title "Select none"
                , onClick SelectNoItems
                ]
                [ i [ class "square outline icon" ] []
                ]
            , div [ class "borderless label item" ]
                [ div [ class "ui circular purple icon label" ]
                    [ text selectCount
                    ]
                ]
            ]
        ]


viewSearchBar : Flags -> Model -> Html Msg
viewSearchBar flags model =
    let
        searchTypeItem =
            Comp.FixedDropdown.Item
                model.searchTypeDropdownValue
                (searchTypeString model.searchTypeDropdownValue)

        searchInput =
            Comp.SearchMenu.textSearchString
                model.searchMenuModel.textSearchModel

        searchTypeClass =
            if flags.config.fullTextSearchEnabled then
                "compact"

            else
                "hidden invisible"
    in
    div
        [ classList
            [ ( "invisible hidden", not (menuCollapsed model) )
            , ( "ui secondary stackable menu container", True )
            ]
        ]
        [ a
            [ classList
                [ ( "search-menu-toggle ui icon button", True )

                -- , ( "primary", not (searchMenuFilled model) )
                -- , ( "secondary", searchMenuFilled model )
                ]
            , onClick ToggleSearchMenu
            , href "#"
            , title "Open search menu"
            ]
            [ i [ class "filter icon" ] []
            ]
        , div [ class "right menu" ]
            [ div [ class "fitted item" ]
                [ div [ class "ui left icon right action input" ]
                    [ -- i
                      --    [ classList
                      --        [ ( "search link icon", not model.searchInProgress )
                      --        , ( "loading spinner icon", model.searchInProgress )
                      --        ]
                      --    , href "#"
                      --    , onClick (DoSearch model.searchTypeDropdownValue)
                      --    ]
                      --    (if hasMoreSearch model then
                      --        [ i [ class "icons search-corner-icons" ]
                      --            [ i [ class "tiny blue circle icon" ] []
                      --            ]
                      --        ]
                      --     else
                      --        []
                      --    )
                      input
                        [ type_ "text"
                        , placeholder
                            (case model.searchTypeDropdownValue of
                                ContentOnlySearch ->
                                    "Content search…"

                                BasicSearch ->
                                    "Search in names…"
                            )
                        , onInput SetBasicSearch
                        , Util.Html.onKeyUpCode KeyUpSearchbarMsg
                        , Maybe.map value searchInput
                            |> Maybe.withDefault (value "")
                        ]
                        []
                    , Html.map SearchTypeMsg
                        (Comp.FixedDropdown.viewStyled searchTypeClass
                            (Just searchTypeItem)
                            model.searchTypeDropdown
                        )
                    , a
                        [ class "ui icon basic button"
                        , href "#"
                        , onClick ResetSearch
                        , title "Reset search form"
                        ]
                        [ i [ class "undo icon" ] []
                        ]
                    ]
                ]
            ]
        ]


deleteAllDimmer : Comp.YesNoDimmer.Settings
deleteAllDimmer =
    { message = "Really delete all selected items?"
    , headerIcon = "exclamation icon"
    , headerClass = "ui inverted icon header"
    , confirmButton = "Yes"
    , cancelButton = "No"
    , extraClass = "top aligned"
    }
