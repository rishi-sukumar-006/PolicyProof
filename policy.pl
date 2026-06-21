:- dynamic role/2.
:- dynamic clearance/2.
:- dynamic transaction/3.
:- dynamic fraud_flag/1.
:- dynamic manager_signoff/1.
:- dynamic senior_cleared/1.

allowed(X, read, Y) :- 
    role(X, employee), 
    clearance(Y, public).

approved(Txn) :-
    transaction(Txn, Amount, _),
    Amount < 50000,
    \+ fraud_flag(Txn).

approved(Txn) :-
    transaction(Txn, Amount, _),
    Amount >= 50000,
    Amount =< 500000,
    manager_signoff(Txn),
    \+ fraud_flag(Txn).

approved(Txn) :-
    transaction(Txn, Amount, _),
    Amount > 500000,
    manager_signoff(Txn),
    \+ fraud_flag(Txn).

approved(Txn) :-
    fraud_flag(Txn),
    senior_cleared(Txn).
