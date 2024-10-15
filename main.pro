% Copyright

implement main

clauses
    run() :-
        _ = mainForm::display(gui::getScreenWindow()),
        messageLoop::run().

end implement main

goal
    formWindow::run(main::run).
