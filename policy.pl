:- dynamic role/2.
:- dynamic clearance/2.

allowed(X, read, Y) :- 
    role(X, employee), 
    clearance(Y, public).
