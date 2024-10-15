% Copyright

implement testdb
    open core

facts
    filename : string := "".

facts - dbtest
    question : (integer N, positive Type, string Text).
    answer : (integer NQuestion, integer NAnswer, string Text, integer).
    point : (integer QuestionType, integer Point).

clauses
    new(Filename) :-
        filename := Filename.

    question_nd(A, B, C) :-
        question(A, B, C).

    answer_nd(A, B, C, D) :-
        answer(A, B, C, D).

    point_nd(A, B) :-
        point(A, B).

    load() :-
        try
            file::reconsult(filename, dbtest)
        catch Error do
            stdio::writef("Error %. Unable to load a database from %", Error, filename),
            fail
        end try,
        !.
    load().

end implement testdb
