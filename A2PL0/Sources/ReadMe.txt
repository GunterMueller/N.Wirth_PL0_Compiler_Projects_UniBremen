This archive contains a A2 port of the exercises and
sample solutions which have been in use until 2005.
In that time the software was implemented in the 
ETH-Oberon system.

The students got a compiler for the languge PL0 and their
task was to enhance the identifier table and object table
and to extend the language in steps to PL1, PL2, PL3, PL4
and PL5.

The compiler uses the technics for delayed code emission 
and short circuit evaluation of boolen expressions
explained in N. Wirth's book 'Grundlagen und Techniken des
Compilerbaus'.

The target processor RISC is emulated by Wirth's
module RISC.Mod. The tiny target system (RISCSystem)
contains an decoder for displaying the generated code
and has rudimentary debug facilities.

In contrast to the single-pass compiler in Wirth's book this
one is multi-pass, very modular and supports block scope
visibility (as of PL3). 

To use the software:
   
   tar -zxf PL0.tgz
   cd PL0
   aos
   (in aos open PL0.Tool)


-- Guenter
