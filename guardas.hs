{-
nombre_funcion parametro
    | condicion = resultado
    | otherwis = otro_resultado
-}

evaluar x
    | x > 0     = "positivo"
    | x == 0    = "Cero"
    | otherwise = "Negativo"