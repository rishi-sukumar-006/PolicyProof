:- dynamic role/2.
:- dynamic clearance/2.
:- dynamic transaction/3.
:- dynamic fraud_flag/1.
:- dynamic manager_signoff/1.
:- dynamic senior_cleared/1.

% Original document access rule
allowed(X, read, Y) :- 
    role(X, employee), 
    clearance(Y, public).

% Financial transaction approval rules

% Small transactions auto-approved if no fraud flag
approved(Txn) :-
    transaction(Txn, Amount, _),
    Amount < 50000,
    \+ fraud_flag(Txn).

% Medium transactions need manager signoff
approved(Txn) :-
    transaction(Txn, Amount, _),
    Amount >= 50000,
    Amount =< 500000,
    manager_signoff(Txn),
    \+ fraud_flag(Txn).

% Large transactions need signoff AND no fraud
approved(Txn) :-
    transaction(Txn, Amount, _),
    Amount > 500000,
    manager_signoff(Txn),
    \+ fraud_flag(Txn).

% Fraud-flagged transactions can still be approved if senior-cleared
approved(Txn) :-
    fraud_flag(Txn),
    senior_cleared(Txn).:- dynamic role/2.
:- dynamic clearance/2.

allowed(X, read, Y) :- 
    role(X, employee), 
    clearance(Y, public).
