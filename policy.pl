:- dynamic role/2.
:- dynamic clearance/2.
:- dynamic transaction/3.
:- dynamic fraud_flag/1.
:- dynamic manager_signoff/1.
:- dynamic senior_cleared/1.
:- dynamic allowed/3.

allowed(X, read, Y) :- 
    role(X, employee), 
    clearance(Y, public).

% Each approval tier is its own named predicate so the application layer
% can query exactly which one fired (or failed) and build an explanation
% from real query results — instead of re-implementing this logic by hand
% in Python, where it can silently drift out of sync with these rules.

auto_approved(Txn) :-
    transaction(Txn, Amount, _),
    Amount < 50000,
    \+ fraud_flag(Txn).

midtier_approved(Txn) :-
    transaction(Txn, Amount, _),
    Amount >= 50000,
    Amount =< 500000,
    manager_signoff(Txn),
    \+ fraud_flag(Txn).

highvalue_approved(Txn) :-
    transaction(Txn, Amount, _),
    Amount > 500000,
    manager_signoff(Txn),
    \+ fraud_flag(Txn).

fraud_override_approved(Txn) :-
    fraud_flag(Txn),
    senior_cleared(Txn).

approved(Txn) :- auto_approved(Txn).
approved(Txn) :- midtier_approved(Txn).
approved(Txn) :- highvalue_approved(Txn).
approved(Txn) :- fraud_override_approved(Txn).
