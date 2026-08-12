{-
PARA USAR LA TERMINAL
>ghci
>:l <name_file>.hs
> <function name> action 

ejemplo 

>:l expresion.hs
factorial 5
evaluar 5
evaluar (-2)



Estas son expresiones: es una combinacion para dar un dicho resultado de funciones,valores y acciones 
una expresión aritmetica 
+ - / *
2+3 = 5
5+5 = 10
-}

doble x = x * 2

{-llamamos la función doble que nos da un doble que es una expesiones con funciones-}

factorial 0 = 1
factorial n = n * factorial(n-1)

evaluar x
    | x > 0     = "positivo"
    | x == 0    = "Cero"
    | otherwise = "Negativo"
