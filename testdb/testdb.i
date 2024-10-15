% Copyright

interface testdb
    open core

predicates
    load : ().
    question_nd : (integer N, positive Type, string Text) nondeterm (o,o,o) (i,o,o) (i,i,o).
    answer_nd : (integer NQuestion, integer NAnswer, string Text, integer) nondeterm (o,o,o,o) (i,o,o,o) (i,i,o,o).
    point_nd : (integer QuestionType, integer Point) nondeterm (o,o) (i,o) (o,i) (i,i).

end interface testdb
