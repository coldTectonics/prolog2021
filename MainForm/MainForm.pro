% Copyright

implement mainForm inherits formWindow
    open core, vpiDomains, ribbonControl, testdb

clauses
    display(Parent) = Form :-
        Form = new(Parent),
        Form:show().

constructors
    new : (window Parent).
clauses
    new(Parent) :-
        formWindow::new(Parent),
        generatedInitialize(),
        stdio::outputStream := messageControl_ctl:outputStream,
        createCommands(),
        ribbonControl_ctl:layout := layout,
        setGetNavigationPointsResponder(ribbonControl_ctl:getNavigationPoints),
        navigationOverlay::registerSDI(This),
        textStatusCell := statusBarCell::new(statusBarControl_ctl, 30),
        statusBarControl_ctl:cells := [textStatusCell].

facts
    textStatusCell : statusBarCell.
    db : testdb := erroneous.
    questionlist : integer* := [].
    n : positive := 0.
    indexCurrentQuestion : positive := 0.
    tuplelist : tuple{integer, radioButton}* := [].
    currentType : positive := openType.
    currentAnswer : integer := 0.
    counter : positive := 0.

predicates
    onDocumentNew : (command Cmd).
clauses
    onDocumentNew(Cmd) :-
        mainExe::getFilename(StartPath, _),
        Filename = vpiCommonDialogs::getFileName("*.txt", ["Текстовый файл txt", "*.txt"], "Открыть базу данных", [], StartPath, _, _),
        !,
        db := testdb::new(Filename),
        db:load(),
        Cmd:enabled := false,
        List = list::removeDuplicates([ I || db:question_nd(I, _, _) ]),
        questionlist := shuffle(List),
        n := list::length(questionlist),
        indexCurrentQuestion := 0,
        currentType := openType,
        askCurrentQuestion(openType),
        fillAnswerList().

    onDocumentNew(_Cmd).

predicates
    fillAnswerList : ().
clauses
    fillAnswerList() :-
        List = shuffle(list::removeDuplicates([ Text || db:answer_nd(_, _, Text, _) ])),
        answerlist_ctl:addList(List).

predicates
    shuffle : (A*) -> A*.
    % список случайных номеров элементов
    shuffle : (positive N, positive Boundary, positive* StartList) -> positive* RandomIndexList.

clauses
    shuffle(0, _, L) = L :-
        !.
    shuffle(C, N, L) = shuffle(C - 1, N, [X | L]) :-
        X = math::random(N),
        not(X in L),
        !.
    shuffle(C, N, L) = shuffle(C, N, L).

    shuffle(L) = list::map(RandomIndexList, { (Index) = list::nth(Index, L) }) :-
        N = list::length(L),
        RandomIndexList = shuffle(N, N, []).

predicates
    askCurrentQuestion : (positive Type).
    doSettings : (positive Type).
    doAnswerVariants : ().
    askNextQuestion : ().
    result : (positive ClosedType).

clauses
    askNextQuestion() :-
        indexCurrentQuestion := indexCurrentQuestion + 1,
        indexCurrentQuestion < n,
        !,
        currentType := openType,
        answer_ctl:setReadOnly(false),
        answer_ctl:setText(""),
        askCurrentQuestion(currentType).
    askNextQuestion() :-
        result(openType).

    result(openType) :-
        pictControl_ctl:drawPicture("ok.bmp"),
        fail.
    result(closedType) :-
        pictControl_ctl:drawPicture("failed.bmp"),
        fail.

    result(_) :-
        listbox_ctl:setVisible(true),
        result_ctl:setVisible(true),
        text_ctl:setVisible(true),
        groupBox_ctl:setEnabled(false),
        result_ctl:setInteger(points),
        listbox_ctl:setTabStops([10, 15]),
        counter := 0,
        List =
            [ string::format("%3. \t%3 \t%", counter, Score, Text) ||
                score(I, Score),
                counter := counter + 1,
                db:question_nd(I, openType, Text)
            ],
        listbox_ctl:addList(List).

    askCurrentQuestion(Type) :-
        currentType := Type,
        fail.
    askCurrentQuestion(Type) :-
        N = list::tryGetnth(indexCurrentQuestion, questionlist),
        db:question_nd(N, Type, Text),
        !,
        question_ctl:setText(Text),
        doSettings(Type).
    askCurrentQuestion(_Type).

    doAnswerVariants() :-
        N = list::tryGetnth(indexCurrentQuestion, questionlist),
        !,
        List = shuffle([ NAns || db:answer_nd(N, NAns, _, _) ]),
        ControlList = [one_ctl, two_ctl, three_ctl],
        list::forAll(ControlList, { (Ctrl) :- Ctrl:setVisible(true) }),
        ZipList = [ T || T = list::zipHead_nd(List, ControlList) ],
        tuplelist := ZipList,
        foreach tuple(NA, Control) in tuplelist and db:answer_nd(N, NA, Text, _) do
            Control:setText(Text)
        end foreach,
        %%%%%%%%%% Добавить
        foreach Ctl in ControlList and not(tuple(_, Ctl) in ZipList) do
            Ctl:setVisible(false)
        end foreach.
    doAnswerVariants().

    doSettings(openType) :-
        !,
        onevariant_ctl:setVisible(false),
        yesText_ctl:setVisible(false),
        yes_ctl:setVisible(false).
    doSettings(limitedType) :-
        !,
        onevariant_ctl:setVisible(true),
        onevariant_ctl:setEnabled(true),
        one_ctl:setRadioState(radioButton::checked),
        doAnswerVariants(),
        yesText_ctl:setVisible(false),
        yes_ctl:setVisible(false),
        answer_ctl:setReadOnly(true).
    doSettings(closedType) :-
        yes_ctl:setChecked(false),
        N = list::tryGetnth(indexCurrentQuestion, questionlist),
        NumberList = [ No || db:answer_nd(N, No, _, _) ],
        Len = list::length(NumberList),
        RandomIndex = math::random(Len),
        NAnswer = list::nth(RandomIndex, NumberList),
        db:answer_nd(N, NAnswer, Text, _),
        !,
        AllText = question_ctl:getText(),
        question_ctl:setText(string::format("% - %?", AllText, Text)),
        currentAnswer := NAnswer,
        onevariant_ctl:setEnabled(false),
        answer_ctl:setReadOnly(true),
        yesText_ctl:setVisible(true),
        yes_ctl:setVisible(true).
    doSettings(_).

class predicates
    onDocumentSave : (command Cmd).
clauses
    onDocumentSave(Cmd) :-
        logCommand(Cmd).

class predicates
    onDocumentSaveAs : (command Cmd).
clauses
    onDocumentSaveAs(Cmd) :-
        logCommand(Cmd).

class predicates
    onDocumentOpen : (command Cmd).
clauses
    onDocumentOpen(Cmd) :-
        logCommand(Cmd).

class predicates
    onClipboardCut : (command Cmd).
clauses
    onClipboardCut(Cmd) :-
        logCommand(Cmd).

class predicates
    onClipboardCopy : (command Cmd).
clauses
    onClipboardCopy(Cmd) :-
        logCommand(Cmd).

class predicates
    onClipboardPaste : (command Cmd).
clauses
    onClipboardPaste(Cmd) :-
        logCommand(Cmd).

class predicates
    onEditDelete : (command Cmd).
clauses
    onEditDelete(Cmd) :-
        logCommand(Cmd).

class predicates
    onEditUndo : (command Cmd).
clauses
    onEditUndo(Cmd) :-
        logCommand(Cmd).

class predicates
    onEditRedo : (command Cmd).
clauses
    onEditRedo(Cmd) :-
        logCommand(Cmd).

class predicates
    onHelp : (command Cmd).
clauses
    onHelp(Cmd) :-
        logCommand(Cmd).

predicates
    onAbout : (command Cmd).
clauses
    onAbout(_Cmd) :-
        _ = aboutDialog::display(This).

class predicates
    logCommand : (command Cmd).
clauses
    logCommand(Cmd) :-
        stdio::writef("Command %s\n", Cmd:id).

predicates
    onDesign : (command Cmd).
clauses
    onDesign(_Cmd) :-
        DesignerDlg = ribbonDesignerDlg::new(This),
        DesignerDlg:cmdHost := This,
        DesignerDlg:designLayout := ribbonControl_ctl:layout,
        DesignerDlg:predefinedSections := ribbonControl_ctl:layout,
        DesignerDlg:show(),
        if DesignerDlg:isOk() then
            ribbonControl_ctl:layout := DesignerDlg:designLayout
        end if.

constants
    itv : ribbonControl::cmdStyle = imageAndText(vertical).
    t : ribbonControl::cmdStyle = textOnly.
    layout : ribbonControl::layout =
        [
            section("document", "&Document", toolTip::noTip, core::none,
                [
                    block(
                        [
                            [
                                cmd("document/new", itv) /*, cmd("document/open", itv), cmd("document/save", itv), cmd("document/saveAs", itv)*/
                            ]
                        ])
                ]),
            /*section("edit", "&Edit", toolTip::noTip, core::none, [block([[cmd("edit/undo", itv)], [cmd("edit/redo", itv)]])]),
            section("clipboard", "&Clipboard", toolTip::noTip, core::none,
                [block([[cmd("clipboard/cut", itv)], [cmd("clipboard/copy", itv)], [cmd("clipboard/paste", itv)]])]),
            */
            section("design", "Desi&gn", toolTip::noTip, core::none, [block([[cmd("ribbon.design", itv)]])]),
            section("help", "&Help", toolTip::noTip, core::none, [block([[cmd("help.help", t)], [cmd("help.about", t)]])])
        ].

predicates
    createCommands : ().
clauses
    createCommands() :-
        DocumentNewCmd = command::new(This, "document/new"),
        DocumentNewCmd:category := ["document/new"],
        DocumentNewCmd:menuLabel := "&New",
        % DocumentNewCmd:icon := some(icon::createFromBinary(#bininclude(@".\my.ico"))),
        DocumentNewCmd:icon := some(icon::createFromBinary(#bininclude(@"icons\actions\document-new.ico"))),
        DocumentNewCmd:tipTitle := tooltip::tip("New"),
        DocumentNewCmd:run := onDocumentNew,
        DocumentNewCmd:mnemonics := [tuple(10, "N"), tuple(15, "N1"), tuple(20, "N2"), tuple(25, "N3"), tuple(30, "N4")],
        DocumentNewCmd:acceleratorKey := key(k_f7, c_Nothing),
        %
        DocumentOpenCmd = command::new(This, "document/open"),
        DocumentOpenCmd:menuLabel := "&Open",
        DocumentOpenCmd:category := ["document/open"],
        DocumentOpenCmd:icon := some(icon::createFromBinary(#bininclude(@"icons\actions\document-open.ico"))),
        DocumentOpenCmd:tipTitle := tooltip::tip("Open"),
        DocumentOpenCmd:run := onDocumentOpen,
        DocumentOpenCmd:mnemonics := [tuple(10, "O"), tuple(15, "O1"), tuple(20, "O2"), tuple(25, "O3"), tuple(30, "O4")],
        %
        DocumentSaveCmd = command::new(This, "document/save"),
        DocumentSaveCmd:category := ["document/save"],
        DocumentSaveCmd:menuLabel := "&Save",
        DocumentSaveCmd:icon := some(icon::createFromBinary(#bininclude(@"icons\actions\document-save.ico"))),
        DocumentSaveCmd:run := onDocumentSave,
        DocumentSaveCmd:mnemonics := [tuple(10, "S"), tuple(20, "S1")],
        DocumentSaveCmd:enabled := false,
        %
        DocumentSaveAsCmd = command::new(This, "document/saveAs"),
        DocumentSaveAsCmd:category := ["document/saveAs"],
        DocumentSaveAsCmd:menuLabel := "Save &As...",
        DocumentSaveAsCmd:ribbonLabel := "Save As",
        DocumentSaveAsCmd:icon := some(icon::createFromBinary(#bininclude(@"icons\actions\document-save-as.ico"))),
        DocumentSaveAsCmd:run := onDocumentSaveAs,
        DocumentSaveAsCmd:mnemonics := [tuple(10, "A"), tuple(20, "A1")],
        DocumentSaveAsCmd:enabled := false,
        %
        ClipboardCutCommand = command::new(This, "clipboard/cut"),
        ClipboardCutCommand:category := ["clipboard/cut"],
        ClipboardCutCommand:menuLabel := "&Cut",
        ClipboardCutCommand:icon := some(icon::createFromBinary(#bininclude(@"icons\actions\edit-cut.ico"))),
        ClipboardCutCommand:run := onClipboardCut,
        ClipboardCutCommand:mnemonics := [tuple(15, "X"), tuple(20, "X1"), tuple(30, "X2")],
        ClipboardCutCommand:enabled := false,
        ClipboardCutCommand:acceleratorKey := key(k_x, c_Control),
        %
        ClipboardCopyCommand = command::new(This, "clipboard/copy"),
        ClipboardCopyCommand:category := ["clipboard/copy"],
        ClipboardCopyCommand:menuLabel := "&Copy",
        ClipboardCopyCommand:icon := some(icon::createFromBinary(#bininclude(@"icons\actions\edit-copy.ico"))),
        ClipboardCopyCommand:run := onClipboardCopy,
        ClipboardCopyCommand:mnemonics := [tuple(10, "C"), tuple(30, "C1")],
        ClipboardCopyCommand:enabled := false,
        ClipboardCopyCommand:acceleratorKey := key(k_c, c_Control),
        %
        ClipboardPasteCommand = command::new(This, "clipboard/paste"),
        ClipboardPasteCommand:category := ["clipboard/paste"],
        ClipboardPasteCommand:menuLabel := "&Paste",
        ClipboardPasteCommand:icon := some(icon::createFromBinary(#bininclude(@"icons\actions\edit-paste.ico"))),
        ClipboardPasteCommand:run := onClipboardPaste,
        ClipboardPasteCommand:mnemonics := [tuple(10, "V"), tuple(30, "V1")],
        ClipboardPasteCommand:enabled := false,
        ClipboardPasteCommand:acceleratorKey := key(k_v, c_Control),
        %
        EditDeleteCommand = command::new(This, "edit/delete"),
        EditDeleteCommand:category := ["edit/delete"],
        EditDeleteCommand:menuLabel := "&Delete",
        EditDeleteCommand:icon := some(icon::createFromBinary(#bininclude(@"icons\actions\edit-delete.ico"))),
        EditDeleteCommand:run := onEditDelete,
        EditDeleteCommand:mnemonics := [tuple(10, "D"), tuple(30, "D1")],
        EditDeleteCommand:enabled := false,
        EditDeleteCommand:acceleratorKey := key(k_del, c_Nothing),
        %
        EditUndoCommand = command::new(This, "edit/undo"),
        EditUndoCommand:category := ["edit/undo"],
        EditUndoCommand:menuLabel := "&Undo",
        EditUndoCommand:icon := some(icon::createFromBinary(#bininclude(@"icons\actions\edit-undo.ico"))),
        EditUndoCommand:run := onEditUndo,
        EditUndoCommand:mnemonics := [tuple(10, "U"), tuple(30, "U1")],
        EditUndoCommand:enabled := false,
        EditUndoCommand:acceleratorKey := key(k_z, c_Control),
        %
        EditRedoCommand = command::new(This, "edit/redo"),
        EditRedoCommand:category := ["edit/redo"],
        EditRedoCommand:menuLabel := "&Redo",
        EditRedoCommand:icon := some(icon::createFromBinary(#bininclude(@"icons\actions\edit-redo.ico"))),
        EditRedoCommand:run := onEditRedo,
        EditRedoCommand:mnemonics := [tuple(10, "R"), tuple(30, "R1")],
        EditRedoCommand:enabled := false,
        EditRedoCommand:acceleratorKey := key(k_y, c_Control),
        %
        DesignCmd = command::new(This, "ribbon.design"),
        DesignCmd:tipTitle := toolTip::tip("Design ribbon, sections and commands."),
        DesignCmd:menuLabel := "&Design",
        DesignCmd:icon := some(icon::createFromBinary(#bininclude(@"icons\actions\tools.ico"))),
        DesignCmd:run := onDesign,
        DesignCmd:mnemonics := [tuple(10, "D"), tuple(30, "D1")],
        %
        HelpCmd = command::new(This, "help.help"),
        HelpCmd:tipTitle := toolTip::tip("Help"),
        HelpCmd:menuLabel := "&Help",
        HelpCmd:run := onHelp,
        HelpCmd:mnemonics := [tuple(10, "H"), tuple(30, "H1")],
        %
        AboutCmd = command::new(This, "help.about"),
        AboutCmd:tipTitle := toolTip::tip("About"),
        AboutCmd:menuLabel := "&About",
        AboutCmd:run := onAbout,
        AboutCmd:mnemonics := [tuple(10, "B")].

facts
    score : (integer NQuestion, integer Point).

facts
    % n : integer := 0.
    points : integer := 0.

predicates
    onGoClick : button::clickResponder.
clauses
    onGoClick(_Source) = button::defaultAction :-
        opentype = currentType,
        Answer = string::trim(answer_ctl:getText()),
        N = list::tryGetNth(indexCurrentQuestion, questionlist),
        db:point_nd(openType, Points),
        if db:answer_nd(N, _, Text, Truth) and string::equalIgnoreCase(Answer, Text) then
            retractAll(score(N, _)),
            assert(score(N, Points * Truth)),
            points := Points * Truth + points,
            if Truth = 1 then
                askNextQuestion()
            else
                askCurrentQuestion(limitedType)
            end if
        else
            askCurrentQuestion(limitedType)
        end if,
        !.
    onGoClick(_Source) = button::defaultAction :-
        limitedtype = currentType,
        N = list::tryGetNth(indexCurrentQuestion, questionlist),
        db:point_nd(limitedType, Points),
        %%%%% Внести под if
        if tuple(NA, Control) in tuplelist and Control:getRadioState() = radioButton::checked() and db:answer_nd(N, NA, _Text, Truth) then
            retractAll(score(N, _)),
            assert(score(N, Points * Truth)),
            points := Points * Truth + points,
            if Truth = 1 then
                askNextQuestion()
            else
                askCurrentQuestion(closedType)
            end if
        else
            askCurrentQuestion(closedType)
        end if,
        !.
    onGoClick(_Source) = button::defaultAction :-
        closedtype = currentType,
        N = list::tryGetNth(indexCurrentQuestion, questionlist),
        db:point_nd(closedType, Points),
        State = yes_ctl:getChecked(),
        db:answer_nd(N, currentAnswer, _Text, Truth),
        %%%%% Дополнить
        if Truth = 1 and State = true or Truth = 0 and State = false then
            retractAll(score(N, _)),
            assert(score(N, Points)),
            points := Points + points,
            askNextQuestion()
        else
            result(closedType)
        end if,
        !.
    onGoClick(_Source) = button::defaultAction.

predicates
    onShow : window::showListener.
clauses
    onShow(_Source, _Data) :-
        pictControl_ctl:drawPicture("bg.bmp"),
        listbox_ctl:setVisible(false),
        result_ctl:setVisible(false),
        text_ctl:setVisible(false).
% This code is maintained automatically, do not update it manually.
%  16:32:48-27.4.2020

facts
    ribbonControl_ctl : ribboncontrol.
    statusBarControl_ctl : statusbarcontrol.
    messageControl_ctl : messagecontrol.
    groupBox_ctl : groupBox.
    question_ctl : editControl.
    onevariant_ctl : groupBox.
    one_ctl : radioButton.
    two_ctl : radioButton.
    three_ctl : radioButton.
    answer_ctl : editControl.
    go_ctl : button.
    answerlist_ctl : listButton.
    yes_ctl : checkButton.
    yesText_ctl : textControl.
    zero_ctl : textControl.
    pictControl_ctl : pictcontrol.
    text_ctl : textControl.
    result_ctl : integercontrol.
    listbox_ctl : listBox.

predicates
    generatedInitialize : ().
clauses
    generatedInitialize() :-
        setFont(vpi::fontCreateByName("Tahoma", 8)),
        setText("testsystem"),
        setRect(rct(50, 40, 674, 394)),
        setDecoration(titlebar([closeButton, maximizeButton, minimizeButton])),
        setBorder(sizeBorder()),
        setState([wsf_ClipSiblings, wsf_ClipChildren]),
        menuSet(noMenu),
        addShowListener(onShow),
        ribbonControl_ctl := ribboncontrol::new(This),
        ribbonControl_ctl:setPosition(12, 20),
        ribbonControl_ctl:setSize(604, 20),
        ribbonControl_ctl:dockStyle := control::dockTop,
        statusBarControl_ctl := statusbarcontrol::new(This),
        statusBarControl_ctl:setPosition(8, 416),
        statusBarControl_ctl:setSize(608, 14),
        messageControl_ctl := messagecontrol::new(This),
        messageControl_ctl:setPosition(12, 286),
        messageControl_ctl:setSize(604, 54),
        messageControl_ctl:setBorder(true),
        messageControl_ctl:dockStyle := control::dockBottom,
        groupBox_ctl := groupBox::new(This),
        groupBox_ctl:setText(""),
        groupBox_ctl:setPosition(12, 44),
        groupBox_ctl:setSize(356, 236),
        question_ctl := editControl::new(groupBox_ctl),
        question_ctl:setText(""),
        question_ctl:setPosition(7, 2),
        question_ctl:setWidth(340),
        question_ctl:setHeight(50),
        question_ctl:setMultiLine(),
        question_ctl:setReadOnly(),
        onevariant_ctl := groupBox::new(groupBox_ctl),
        onevariant_ctl:setText("Укажите один вариант ответа"),
        onevariant_ctl:setPosition(7, 66),
        onevariant_ctl:setSize(180, 136),
        onevariant_ctl:setVisible(false),
        one_ctl := radioButton::new(onevariant_ctl),
        one_ctl:setText(""),
        one_ctl:setPosition(11, 30),
        one_ctl:setWidth(156),
        two_ctl := radioButton::new(onevariant_ctl),
        two_ctl:setText(""),
        two_ctl:setPosition(11, 60),
        two_ctl:setWidth(156),
        three_ctl := radioButton::new(onevariant_ctl),
        three_ctl:setText(""),
        three_ctl:setPosition(11, 90),
        three_ctl:setWidth(156),
        answer_ctl := editControl::new(groupBox_ctl),
        answer_ctl:setText(""),
        answer_ctl:setPosition(195, 112),
        answer_ctl:setWidth(100),
        answer_ctl:setHeight(44),
        answer_ctl:setAutoHScroll(false),
        answer_ctl:setMultiLine(),
        answer_ctl:setVScroll(),
        answer_ctl:setAutoVScroll(true),
        go_ctl := button::new(groupBox_ctl),
        go_ctl:setText("Ответить"),
        go_ctl:setPosition(303, 120),
        go_ctl:setSize(44, 26),
        go_ctl:defaultHeight := false,
        go_ctl:setClickResponder(onGoClick),
        answerlist_ctl := listButton::new(groupBox_ctl),
        answerlist_ctl:setPosition(123, 208),
        answerlist_ctl:setWidth(224),
        yes_ctl := checkButton::new(groupBox_ctl),
        yes_ctl:setText("Да"),
        yes_ctl:setPosition(243, 190),
        yes_ctl:setWidth(52),
        yes_ctl:setVisible(false),
        yesText_ctl := textControl::new(groupBox_ctl),
        yesText_ctl:setText("Поставьте флажок, если да"),
        yesText_ctl:setPosition(219, 168),
        yesText_ctl:setSize(100, 14),
        yesText_ctl:setVisible(false),
        zero_ctl := textControl::new(groupBox_ctl),
        zero_ctl:setText("Напишите правильный ответ"),
        zero_ctl:setPosition(195, 82),
        zero_ctl:setSize(152, 12),
        StaticText1_ctl = textControl::new(groupBox_ctl),
        StaticText1_ctl:setText("Посмотреть, как пишется ответ"),
        StaticText1_ctl:setPosition(7, 208),
        StaticText1_ctl:setSize(112, 12),
        pictControl_ctl := pictcontrol::new(This),
        pictControl_ctl:setPosition(376, 46),
        pictControl_ctl:setSize(240, 126),
        pictControl_ctl:setAnchors([control::left, control::top, control::right, control::bottom]),
        text_ctl := textControl::new(This),
        text_ctl:setText("Результаты          Число баллов"),
        text_ctl:setPosition(444, 178),
        text_ctl:setSize(116, 14),
        result_ctl := integercontrol::new(This),
        result_ctl:setPosition(560, 178),
        result_ctl:setWidth(36),
        result_ctl:setAutoHScroll(false),
        result_ctl:setAlignBaseline(false),
        result_ctl:setAnchors([control::left]),
        listbox_ctl := listBox::new(This),
        listbox_ctl:setPosition(376, 198),
        listbox_ctl:setSize(240, 82),
        listbox_ctl:setSort(false),
        listbox_ctl:setAnchors([control::left, control::top, control::right, control::bottom]),
        listbox_ctl:setUseTabStops(),
        listbox_ctl:setUseTabStops(true).
% end of automatic code

end implement mainForm
