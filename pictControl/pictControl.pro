% Copyright

implement pictControl inherits userControlSupport
    open core, vpiDomains

clauses
    new(Parent) :-
        new(),
        setContainer(Parent).

clauses
    new() :-
        userControlSupport::new(),
        generatedInitialize().

facts
    pict : picture := erroneous.
    rect : rct := rct(0, 0, 1, 1).

clauses
    drawPicture(File) :-
        try
            Pict = vpi::pictLoad(File)
        catch Error do
            stdio::writef("Error %. Unable to load a picture from %\n", Error, File),
            fail
        end try,
        !,
        pict := Pict,
        vpi::pictGetSize(Pict, W, H, _),
        rect := rct(0, 0, W, H),
        invalidate().
    drawPicture(_) :-
        clear().

    clear() :-
        pict := erroneous,
        invalidate().

predicates
    onSize : window::sizeListener.
clauses
    onSize(_Source) :-
        invalidate().

predicates
    onEraseBackground : window::eraseBackgroundResponder.
clauses
    onEraseBackground(_Source, _GDI) = noEraseBackground.

predicates
    onPaint : window::paintResponder.
clauses
    onPaint(_Source, Rectangle, GDI) :-
        not(isErroneous(pict)),
        !,
        GDI:pictDraw(pict, Rectangle, rect, rop_srcCopy).
    onPaint(_Source, _Rectangle, GDI) :-
        GDI:clear(color_lavender).

% This code is maintained automatically, do not update it manually.
%  12:00:16-6.4.2020

predicates
    generatedInitialize : ().
clauses
    generatedInitialize() :-
        setText("pictControl"),
        This:setSize(240, 120),
        addSizeListener(onSize),
        setEraseBackgroundResponder(onEraseBackground),
        setPaintResponder(onPaint).
% end of automatic code

end implement pictControl
